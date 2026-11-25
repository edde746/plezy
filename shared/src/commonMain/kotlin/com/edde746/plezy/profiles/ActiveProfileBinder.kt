package com.edde746.plezy.profiles

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexServer
import com.edde746.plezy.plex.tv.PlexAccountConnection
import com.edde746.plezy.plex.tv.PlexAuthService
import com.edde746.plezy.plex.tv.PlexHomeSwitchResult
import com.edde746.plezy.plex.tv.PlexHomeSwitchStatus
import com.edde746.plezy.plex.tv.switchPlexHomeUserWithPin
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.MultiServerManager
import com.edde746.plezy.servers.MultiServerStore
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlin.time.Clock

/**
 * How binding the active profile's servers stands. [binding] while a bind runs; [bound] once a bind has finished (false
 * before the binder's first bind, while the servers aren't the profile's yet); then [succeeded] tells whether the
 * profile got what it needs (a local profile without connections succeeds with no servers). A failed bind is
 * [connectivityOnlyFailure] when the profile expected servers, reached none, and none refused it: offline, not
 * signed out.
 */
data class ProfileBindState(
    val binding: Boolean = false,
    val succeeded: Boolean = true,
    val connectivityOnlyFailure: Boolean = false,
    val bound: Boolean = false,
) {
    /** A bind runs or none has finished yet: the servers may still answer as no profile or the previous one. */
    val unsettled: Boolean get() = binding || !bound
}

/** Asks the user for [profile]'s PIN, told whether the last one was wrong; null when the user cancels. */
typealias ProfilePinPrompt = suspend (profile: Profile, incorrectPin: Boolean) -> String?

/**
 * Connects the active profile's servers in [manager] and keeps the active profile's view ([servers]) to them: a Plex
 * Home profile's own account, then every binding of the profile (Plex accounts as a Home user, Jellyfin/Emby users),
 * all in parallel. Servers the profile doesn't reach are dropped, so nothing of another profile shows.
 *
 * Plex tokens: a Home user's token is minted through `/home/users/{uuid}/switch` and kept on the profile's binding. The
 * kept token is used at cold start and once after the activation checked the PIN ([markPlexHomePreVerified]); after the
 * session's first bind every other switch mints again, so plex.tv checks the PIN. Only a bind the user started (or the
 * session's first) may ask for a PIN. A kept token plex.tv refuses (401/403) or that lists no server is dropped and
 * minted again; a fresh token refused marks the account for a new sign-in. Every server list plex.tv answers is stored
 * on the account, unless the account changed meanwhile. At cold start the servers whose kept token is the profile's
 * own connect at once, and plex.tv's answer is applied when it lands.
 *
 * Confined to [scope]'s thread, like the manager.
 */
class ActiveProfileBinder(
    private val provider: ActiveProfileProvider,
    private val connections: ConnectionStore,
    private val bindings: ProfileConnectionRegistry,
    private val manager: MultiServerManager,
    private val servers: MultiServerStore,
    private val plexAuth: suspend () -> PlexAuthService,
    private val shouldDeferInitialBind: suspend (Profile) -> Boolean,
    scope: CoroutineScope,
    private val clock: Clock,
) {
    private val work = scope.childScope()
    private val state = MutableStateFlow(ProfileBindState())
    val bindState: StateFlow<ProfileBindState> = state.asStateFlow()

    /** Asks for a PIN during a bind; null: none can be asked (the bind of a protected user then fails). */
    var pinPrompt: ProfilePinPrompt? = null

    private var started = false
    private var switching = false
    private var lastBoundProfileId: String? = null
    private var bindingProfileId: String? = null

    // The profile whose last bind failed: a passive change never retries it, as that could ask for a PIN unprompted.
    private var lastFailedProfileId: String? = null
    private var lastFailureConnectivityOnly = false
    private var pendingRebind = false
    private var pendingSameIdRebind = false
    private var bindGeneration = 0
    private var hasBoundOnce = false
    private var initialBindMayPromptPin = true
    private val plexHomePreVerified = HashSet<String>()
    private val userInitiatedActivations = HashSet<String>()

    // The token each Plex account was bound with in this bind generation.
    private val plexBindTokens = HashMap<String, PlexBindToken>()

    /** The activation just checked [profileId]'s PIN with plex.tv: its next bind uses the token that check minted. */
    fun markPlexHomePreVerified(profileId: String) {
        plexHomePreVerified += profileId
        if (lastFailedProfileId == profileId) lastFailedProfileId = null
    }

    /** The user chose [profileId]: its next bind may ask for a PIN and isn't deferred. */
    fun markUserInitiatedActivation(profileId: String) {
        userInitiatedActivations += profileId
        if (lastFailedProfileId == profileId) lastFailedProfileId = null
    }

    /**
     * Starts following the active profile and binds it. With [allowInitialPinPrompt] false the session's first bind
     * asks for no PIN (plex.tv can't check one without a network). Runs once.
     */
    fun start(allowInitialPinPrompt: Boolean = true) {
        if (started) return
        started = true
        initialBindMayPromptPin = allowInitialPinPrompt
        markBindingStarted()
        provider.onActiveChanged = ::onActiveChanged
        work.launch { rebind() }
    }

    /** The outcome of the bind running now, or of the last one. */
    suspend fun awaitBindingSettle(): Boolean = state.first { !it.binding }.succeeded

    /** Binds the active profile again (its connections changed), also when its last bind failed. */
    suspend fun rebindActive() {
        lastFailedProfileId = null
        if (switching) {
            pendingSameIdRebind = true
            return
        }
        rebind()
    }

    suspend fun rebindIfActive(profileId: String) {
        if (provider.active.value?.id == profileId) rebindActive()
    }

    /**
     * Fetches the servers of Plex account [accountId] again with the token it was bound with and applies them: a
     * server that failed to reconnect may be back on a new address. Never mints a token, so never asks for a PIN.
     */
    suspend fun refreshPlexServers(accountId: String) {
        val bound = plexBindTokens[accountId] ?: return
        if (!isCurrentBind(bound.profileId, bound.generation)) return
        val stored = connections.get(accountId) ?: return
        val account = stored.plexAccount() ?: return
        if (!isCurrentBind(bound.profileId, bound.generation)) return
        Log.i(TAG) { "Fetching the Plex servers of ${bound.profileLabel} again after a failed reconnect" }
        val outcome = fetchServers(plexAuth(), bound.token, bound.profileLabel)
        awaitBindingSettle()
        applyResourceRefresh(outcome, stored, account, bound.profileId, bound.profileLabel, bound.generation, bound.invalidateCachedToken)
    }

    /** Stops binding; work in flight is dropped. */
    fun close() {
        bindGeneration++
        plexBindTokens.clear()
        provider.onActiveChanged = {}
        started = false
        work.cancel()
    }

    private fun onActiveChanged() {
        val id = provider.active.value?.id
        if (switching) {
            // The id may move away and back during a pass: the pass can't stand as the final bind of that id.
            if (id == bindingProfileId) {
                if (pendingRebind) pendingSameIdRebind = true
                return
            }
            pendingRebind = true
            return
        }
        if (id == lastBoundProfileId) return
        if (id != null && id == lastFailedProfileId) return
        // Undispatched: the bind is marked started before the change's caller goes on.
        work.launch(start = CoroutineStart.UNDISPATCHED) { rebind() }
    }

    private fun markBindingStarted() {
        if (state.value.binding) return
        state.value = ProfileBindState(binding = true, bound = state.value.bound)
    }

    private fun markBindingFinished(success: Boolean) {
        state.value = ProfileBindState(binding = false, succeeded = success, connectivityOnlyFailure = !success && lastFailureConnectivityOnly, bound = true)
    }

    private suspend fun rebind() {
        if (switching) return
        switching = true
        bindingProfileId = provider.active.value?.id
        markBindingStarted()
        var success = false
        try {
            do {
                pendingRebind = false
                pendingSameIdRebind = false
                success = runRebindOnce()
            } while (pendingSameIdRebind || (pendingRebind && provider.active.value?.id != lastBoundProfileId))
        } finally {
            markBindingFinished(success)
            bindingProfileId = null
            switching = false
        }
    }

    private suspend fun runRebindOnce(): Boolean {
        bindingProfileId = provider.active.value?.id
        val generation = ++bindGeneration
        plexBindTokens.clear()
        var success = false
        lastFailureConnectivityOnly = false
        var attemptedProfileId: String? = null
        try {
            val profile = provider.active.value
            if (profile == null) {
                // Nothing chosen yet: a valid quiet state, and no server of the previous profile may stay.
                clearBoundServers()
                success = true
                return true
            }
            attemptedProfileId = profile.id
            val userInitiated = userInitiatedActivations.remove(profile.id)
            if (!userInitiated && !hasBoundOnce && deferInitialBind(profile)) {
                Log.i(TAG) { "Deferring the first bind of ${profile.displayName} until a profile is picked" }
                clearBoundServers()
                attemptedProfileId = null
                success = true
                return true
            }
            Log.i(TAG) { "Binding ${profile.displayName} (${profile.id})" }
            val joinRows = bindings.listForProfile(profile.id)
            val connectionsById = connections.list().associateBy { it.id }
            if (!isCurrentBind(profile.id, generation)) return false

            // Only a bind the user started, or the session's first, may ask for a PIN.
            val allowPinPrompt = userInitiated || (!hasBoundOnce && initialBindMayPromptPin)
            initialBindMayPromptPin = true

            val profileServers = expectedServerIds(profile, joinRows, connectionsById)
            // The servers answer in any order: the profile's order is what lists them, launch after launch.
            manager.setServerOrder(profileServers)
            servers.setExpectedVisibleServerIds(profileServers.toSet())
            val localWithRows = profile is LocalProfile && joinRows.isNotEmpty()

            val results = coroutineScope {
                listOfNotNull(
                    (profile as? PlexHomeProfile)?.let { async { bindPlexHome(it, joinRows, connectionsById, allowPinPrompt, generation) } },
                    async { bindJoinRows(profile, joinRows, connectionsById, allowPinPrompt, generation) },
                ).awaitAll()
            }
            if (!isCurrentBind(profile.id, generation)) return false
            val discovered = results.fold(emptyMap<String, Set<ServerId>>()) { all, result -> all + result.discovered }
            // A fresh server list replaces the stored one: a server plex.tv dropped is no longer expected.
            val expected = expectedServerIds(profile, joinRows, connectionsById, discovered).toMutableSet()
            val visible = HashSet<ServerId>()
            for (result in results) {
                visible += result.visible
                expected += result.expected
            }

            // Read before the sweep: removing a server forgets its refusal.
            val refused = manager.refusedServerIds
            val mediaBrowserIds = joinRows.mapNotNull { connectionsById[it.connectionId]?.mediaBrowser()?.id }.toSet()
            for (serverId in manager.registeredServerIds) {
                val belongs = serverId in visible || serverId in expected
                if (belongs && !manager.isRegisteredForOtherProfile(serverId, profile.id, mediaBrowserIds)) continue
                manager.removeServer(serverId)
            }
            manager.setServerOrder(expected.toList())
            servers.setExpectedVisibleServerIds(expected)
            servers.setVisibleServerIds(visible)
            // A server this pass could not reach may answer seconds later: one that sleeps to save power can be woken
            // by these very probes.
            manager.retryOfflinePlexServers()
            success = (profile is LocalProfile && !localWithRows) || visible.isNotEmpty()
            if (!success) lastFailureConnectivityOnly = expected.isNotEmpty() && expected.none { it in refused }
            if (success) hasBoundOnce = true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Binding the active profile failed" }
            success = false
        } finally {
            if (success) {
                lastBoundProfileId = attemptedProfileId
                lastFailedProfileId = null
            } else {
                if (lastBoundProfileId == attemptedProfileId) lastBoundProfileId = null
                lastFailedProfileId = attemptedProfileId
            }
            Log.i(TAG) { "Bind of $attemptedProfileId settled: success=$success" }
        }
        return success
    }

    /**
     * The servers [profile] should reach, in its order: a Plex Home profile's own account's first, then each binding's
     * (its default binding first). A Plex account in [discovered] counts with that fresh list instead of its stored one.
     */
    private fun expectedServerIds(
        profile: Profile,
        joinRows: List<ProfileConnection>,
        connectionsById: Map<String, StoredConnection>,
        discovered: Map<String, Set<ServerId>> = emptyMap(),
    ): List<ServerId> {
        fun plexMembership(account: PlexAccountConnection) = discovered[account.id] ?: account.servers.map { it.serverId }
        val expected = LinkedHashSet<ServerId>()
        val parentId = profile.parentConnectionId
        if (profile is PlexHomeProfile && parentId != null) {
            connectionsById[parentId]?.plexAccount()?.let { expected += plexMembership(it) }
        }
        for (row in joinRows) {
            if (row.connectionId == parentId) continue
            val connection = connectionsById[row.connectionId] ?: continue
            connection.plexAccount()?.let { expected += plexMembership(it) }
            connection.mediaBrowser()?.let { expected += it.serverId }
        }
        return expected.toList()
    }

    private suspend fun bindPlexHome(
        profile: PlexHomeProfile,
        joinRows: List<ProfileConnection>,
        connectionsById: Map<String, StoredConnection>,
        allowPinPrompt: Boolean,
        generation: Int,
    ): BindResult {
        val parentId = profile.parentConnectionId
        val homeUuid = profile.plexHomeUserUuid
        if (parentId == null || homeUuid == null) {
            Log.w(TAG) { "${profile.displayName} has no account or Home user" }
            return BindResult.EMPTY
        }
        val stored = connectionsById[parentId]
        val account = stored?.plexAccount()
        if (account == null) {
            Log.w(TAG) { "The account $parentId of ${profile.displayName} is gone" }
            return BindResult.EMPTY
        }
        val auth = plexAuth()
        if (!isCurrentBind(profile.id, generation)) return BindResult.EMPTY
        val preVerified = plexHomePreVerified.remove(profile.id)
        val allowPin = allowPinPrompt || preVerified
        val useCache = shouldUsePlexHomeTokenCache(preVerified, hasBoundOnce)
        val cachedToken = if (useCache) joinRows.firstOrNull { it.connectionId == parentId }?.userToken?.ifEmpty { null } else null
        return bindPlexWithTokenPolicy(
            auth = auth,
            stored = stored,
            account = account,
            profileId = profile.id,
            profileLabel = profile.displayName,
            generation = generation,
            cachedToken = cachedToken,
            invalidateCachedToken = { bindings.invalidateToken(profile.id, parentId) },
            mintToken = {
                if (!allowPin && profile.plexProtected) {
                    Log.i(TAG) { "Not switching to protected ${profile.displayName} in a passive bind" }
                    null
                } else {
                    switchPlexHomeUserWithPin(
                        requiresPin = profile.plexProtected,
                        // plex.tv may ask for a PIN unexpectedly (1041): a passive bind answers with a cancel.
                        promptForPin = { incorrect -> if (allowPin) pinPrompt?.invoke(profile, incorrect) else null },
                        switchToUser = { pin -> auth.switchToUser(homeUuid, account.accountToken, pin) },
                        logLabel = profile.displayName,
                    )
                }
            },
            persistMintedToken = { token ->
                // A Home profile's own account has no binding but this one, which only holds the user's token.
                bindings.upsert(ProfileConnection(profile.id, parentId, token, homeUuid, tokenAcquiredAt = now()))
            },
            markUsed = null,
        )
    }

    private suspend fun bindJoinRows(
        profile: Profile,
        joinRows: List<ProfileConnection>,
        connectionsById: Map<String, StoredConnection>,
        allowPinPrompt: Boolean,
        generation: Int,
    ): BindResult {
        if (joinRows.isEmpty()) {
            if (profile is LocalProfile) Log.w(TAG) { "${profile.displayName} has no connections" }
            return BindResult.EMPTY
        }
        val parentId = profile.parentConnectionId
        val expected = HashSet<ServerId>()
        val results = coroutineScope {
            joinRows.mapNotNull { row ->
                if (row.connectionId == parentId) return@mapNotNull null
                val stored = connectionsById[row.connectionId]
                if (stored == null) {
                    Log.w(TAG) { "The connection ${row.connectionId} of ${profile.displayName} is gone" }
                    return@mapNotNull null
                }
                val plex = stored.plexAccount()
                val mediaBrowser = stored.mediaBrowser()
                when {
                    plex != null -> async { bindProfilePlexAccount(profile, stored, plex, row, allowPinPrompt, generation) }
                    mediaBrowser != null -> {
                        expected += mediaBrowser.serverId
                        async { bindMediaBrowser(mediaBrowser, profile.id, generation) }
                    }
                    else -> null
                }
            }.awaitAll()
        }
        return BindResult(
            visible = results.flatMapTo(HashSet()) { it.visible },
            expected = expected + results.flatMap { it.expected },
            discovered = results.fold(emptyMap()) { all, result -> all + result.discovered },
        )
    }

    /** A Plex account bound to [profile] as the Home user of [row]. */
    private suspend fun bindProfilePlexAccount(
        profile: Profile,
        stored: StoredConnection,
        account: PlexAccountConnection,
        row: ProfileConnection,
        allowPinPrompt: Boolean,
        generation: Int,
    ): BindResult {
        val auth = plexAuth()
        if (!isCurrentBind(profile.id, generation)) return BindResult.EMPTY
        return bindPlexWithTokenPolicy(
            auth = auth,
            stored = stored,
            account = account,
            profileId = profile.id,
            profileLabel = profile.displayName,
            generation = generation,
            cachedToken = row.userToken?.ifEmpty { null },
            invalidateCachedToken = { bindings.invalidateToken(profile.id, account.id) },
            mintToken = {
                if (row.userIdentifier.isEmpty()) {
                    Log.w(TAG) { "${profile.displayName} has no Plex Home user on ${account.accountLabel}" }
                    null
                } else {
                    // The binding doesn't know whether the user is protected: plex.tv asks for the PIN if it is.
                    switchPlexHomeUserWithPin(
                        requiresPin = false,
                        promptForPin = { incorrect -> if (allowPinPrompt) pinPrompt?.invoke(profile, incorrect) else null },
                        switchToUser = { pin -> auth.switchToUser(row.userIdentifier, account.accountToken, pin) },
                        logLabel = profile.displayName,
                    )
                }
            },
            persistMintedToken = { token -> bindings.recordToken(profile.id, account.id, token) },
            markUsed = { bindings.markUsed(profile.id, account.id) },
        )
    }

    /** [mintToken] returns null when it didn't try a switch. */
    private suspend fun bindPlexWithTokenPolicy(
        auth: PlexAuthService,
        stored: StoredConnection,
        account: PlexAccountConnection,
        profileId: String,
        profileLabel: String,
        generation: Int,
        cachedToken: String?,
        invalidateCachedToken: suspend () -> Unit,
        mintToken: suspend () -> PlexHomeSwitchResult?,
        persistMintedToken: suspend (String) -> Unit,
        markUsed: (suspend () -> Unit)?,
    ): BindResult {
        var userToken = cachedToken
        var usingCachedToken = !userToken.isNullOrEmpty()
        while (true) {
            if (!isCurrentBind(profileId, generation)) return BindResult.EMPTY
            if (!usingCachedToken) {
                val minted = mintToken()
                if (!isCurrentBind(profileId, generation)) return BindResult.EMPTY
                if (minted?.status == PlexHomeSwitchStatus.AUTH_REJECTED) {
                    // plex.tv refused the account token itself: a new sign-in is needed, not a connectivity failure.
                    Log.w(TAG) { "The account token was refused for $profileLabel" }
                    return flagPlexAuthRejected(account, profileId)
                }
                userToken = minted?.userToken
                if (userToken.isNullOrEmpty()) return BindResult.EMPTY
                persistMintedToken(userToken)
                if (!isCurrentBind(profileId, generation)) return BindResult.EMPTY
            }
            val token = checkNotNull(userToken)
            plexBindTokens[account.id] = PlexBindToken(token, profileId, profileLabel, generation, invalidateCachedToken)
            val fetch = work.async { fetchServers(auth, token, profileLabel) }
            var optimistic: BindResult? = null
            if (usingCachedToken) {
                optimistic = bindOptimisticallyFromCache(account, token, profileId, profileLabel)
                if (!isCurrentBind(profileId, generation)) return BindResult.EMPTY
                if (optimistic != null && optimistic.visible == account.servers.map { it.serverId }.toSet()) {
                    reconcileWhenFetchLands(fetch, stored, account, profileId, profileLabel, generation, invalidateCachedToken)
                    markUsed?.invoke()
                    return optimistic
                }
            }
            val outcome = fetch.await()
            if (!isCurrentBind(profileId, generation)) return BindResult.EMPTY
            when (outcome.status) {
                FetchStatus.SUCCESS -> {
                    val fresh = outcome.servers
                    Log.i(TAG) { "Using the ${if (usingCachedToken) "kept" else "fresh"} token of $profileLabel (${fresh.size} servers)" }
                    work.launch { persistRefreshedServers(stored, account, fresh) }
                    val result = connectFromServers(account, fresh, profileLabel, profileId)
                    if (!isCurrentBind(profileId, generation)) return BindResult.EMPTY
                    markUsed?.invoke()
                    return result.copy(discovered = mapOf(account.id to result.expected))
                }
                FetchStatus.EMPTY -> {
                    if (usingCachedToken) {
                        Log.w(TAG) { "The kept token of $profileLabel lists no server: minting a new one" }
                        invalidateCachedToken()
                        userToken = null
                        usingCachedToken = false
                        continue
                    }
                    Log.w(TAG) { "No servers for $profileLabel on ${account.accountLabel}" }
                    markUsed?.invoke()
                    return BindResult.EMPTY
                }
                FetchStatus.AUTH_REJECTED -> {
                    if (usingCachedToken) {
                        Log.w(TAG) { "The kept token of $profileLabel was refused: minting a new one" }
                        invalidateCachedToken()
                        userToken = null
                        usingCachedToken = false
                        continue
                    }
                    Log.w(TAG, outcome.error) { "The fresh token of $profileLabel was refused" }
                    return flagPlexAuthRejected(account, profileId)
                }
                FetchStatus.TRANSIENT_FAILURE -> {
                    Log.w(TAG, outcome.error) { "plex.tv didn't answer for $profileLabel: using the stored servers" }
                    if (optimistic != null) {
                        if (optimistic.visible.isNotEmpty()) markUsed?.invoke()
                        return optimistic
                    }
                    val compatible = cachedServersCompatibleWith(account, token, profileLabel)
                    val result = connectFromServers(account, compatible, profileLabel, profileId)
                    if (!isCurrentBind(profileId, generation)) return BindResult.EMPTY
                    if (result.visible.isNotEmpty()) markUsed?.invoke()
                    return result
                }
                FetchStatus.CANCELLED -> return BindResult.EMPTY
                FetchStatus.FAILURE -> {
                    Log.w(TAG, outcome.error) { "Fetching the servers of $profileLabel failed" }
                    return BindResult.EMPTY
                }
            }
        }
    }

    /** Every stored server of [account] shows, flagged for a new sign-in. */
    private fun flagPlexAuthRejected(account: PlexAccountConnection, profileId: String): BindResult {
        plexBindTokens.remove(account.id)
        manager.markPlexConnectionAuthError(account, profileId)
        return BindResult.visible(account.servers.map { it.serverId }.toSet())
    }

    /**
     * The stored servers whose own token is [userToken]. A server's token is per user: putting the profile's token on
     * a shared server gets a 401, and a token of another Home user would show that user's access.
     */
    private fun cachedServersCompatibleWith(account: PlexAccountConnection, userToken: String, profileLabel: String): List<PlexServer> {
        val compatible = account.servers.filter { it.accessToken == userToken }
        val deferred = account.servers.size - compatible.size
        if (deferred > 0) Log.i(TAG) { "Waiting for plex.tv's tokens of $deferred stored servers of $profileLabel" }
        return compatible
    }

    private suspend fun connectFromServers(account: PlexAccountConnection, list: List<PlexServer>, profileLabel: String, profileId: String): BindResult {
        if (list.isEmpty()) return BindResult.EMPTY
        val bound = manager.refreshTokensForProfile(account.copy(servers = list), profileId)
        Log.i(TAG) { "Bound ${bound.size}/${list.size} Plex servers of $profileLabel" }
        return BindResult(visible = bound, expected = list.map { it.serverId }.toSet())
    }

    /** Connects the stored servers usable with [userToken] while plex.tv is asked; null when none are stored. */
    private suspend fun bindOptimisticallyFromCache(account: PlexAccountConnection, userToken: String, profileId: String, profileLabel: String): BindResult? {
        if (account.servers.isEmpty()) return null
        val compatible = cachedServersCompatibleWith(account, userToken, profileLabel)
        if (compatible.isEmpty()) return BindResult.EMPTY
        return connectFromServers(account, compatible, profileLabel, profileId)
    }

    private suspend fun fetchServers(auth: PlexAuthService, token: String, profileLabel: String): FetchOutcome = try {
        val list = auth.fetchServers(token)
        FetchOutcome(if (list.isEmpty()) FetchStatus.EMPTY else FetchStatus.SUCCESS, list)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "Fetching the servers of $profileLabel failed" }
        val status = when {
            e is MediaServerHttpException && e.isCancellation -> FetchStatus.CANCELLED
            e is MediaServerHttpException && (e.statusCode == 401 || e.statusCode == 403) -> FetchStatus.AUTH_REJECTED
            e is MediaServerHttpException && e.isTransient -> FetchStatus.TRANSIENT_FAILURE
            else -> FetchStatus.FAILURE
        }
        FetchOutcome(status, emptyList(), e)
    }

    /** Stores [fresh] on the account, unless the account changed or went meanwhile (a sign-out, a new sign-in). */
    private suspend fun persistRefreshedServers(stored: StoredConnection, account: PlexAccountConnection, fresh: List<PlexServer>) {
        try {
            connections.upsert(account.copy(servers = fresh).stored(), expected = stored)
        } catch (e: CancellationException) {
            throw e
        } catch (e: IllegalStateException) {
            Log.d(TAG, e) { "${account.accountLabel} changed or went: its new servers aren't stored" }
        } catch (e: Exception) {
            Log.w(TAG, e) { "Storing the servers of ${account.accountLabel} failed" }
        }
    }

    /** Applies plex.tv's answer after an optimistic bind, once the bind running has settled. */
    private fun reconcileWhenFetchLands(
        fetch: Deferred<FetchOutcome>,
        stored: StoredConnection,
        account: PlexAccountConnection,
        profileId: String,
        profileLabel: String,
        generation: Int,
        onAuthRejected: suspend () -> Unit,
    ) {
        work.launch {
            try {
                val outcome = fetch.await()
                awaitBindingSettle()
                applyResourceRefresh(outcome, stored, account, profileId, profileLabel, generation, onAuthRejected)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Applying plex.tv's servers of $profileLabel failed" }
            }
        }
    }

    /**
     * Applies a server list fetched outside a bind: stores it, then binds again when the servers changed, or moves the
     * bound servers to its tokens and addresses. A refused token is dropped (whatever profile is active now) and, while
     * the profile is active, its account flagged; a failure or an empty answer keeps the stored servers.
     */
    private suspend fun applyResourceRefresh(
        outcome: FetchOutcome,
        stored: StoredConnection,
        account: PlexAccountConnection,
        profileId: String,
        profileLabel: String,
        generation: Int,
        onAuthRejected: suspend () -> Unit,
    ) {
        when (outcome.status) {
            FetchStatus.AUTH_REJECTED -> {
                Log.w(TAG) { "plex.tv refused the token of $profileLabel in the background: flagging a new sign-in" }
                onAuthRejected()
                if (isCurrentBind(profileId, generation)) {
                    plexBindTokens.remove(account.id)
                    manager.markPlexConnectionAuthError(account, profileId)
                }
                return
            }
            FetchStatus.EMPTY -> {
                // An account answering with no server is almost always plex.tv's hiccup; minting here could ask for a PIN.
                Log.w(TAG) { "plex.tv listed no server of $profileLabel: keeping the stored ones" }
                return
            }
            FetchStatus.SUCCESS -> Unit
            else -> {
                Log.w(TAG, outcome.error) { "plex.tv's servers of $profileLabel didn't come: keeping the stored ones" }
                return
            }
        }
        val fresh = outcome.servers
        persistRefreshedServers(stored, account, fresh)
        if (!isCurrentBind(profileId, generation)) return
        if (fresh.map { it.serverId }.toSet() != account.servers.map { it.serverId }.toSet()) {
            Log.i(TAG) { "The servers of $profileLabel changed: binding again" }
            // plex.tv just accepted the token: the new bind may use it without a switch.
            markPlexHomePreVerified(profileId)
            rebindIfActive(profileId)
            return
        }
        manager.refreshTokensForProfile(account.copy(servers = fresh), profileId)
    }

    private suspend fun bindMediaBrowser(connection: JellyfinConnection, profileId: String, generation: Int): BindResult {
        val online = manager.addMediaBrowserConnection(connection)
        val serverId = connection.serverId
        if (!isCurrentBind(profileId, generation)) return BindResult(emptySet(), setOf(serverId))
        // A refusing server stays visible, so its banner shows instead of the server vanishing.
        if (online || serverId in manager.refusedServerIds) return BindResult.visible(setOf(serverId))
        return BindResult(emptySet(), setOf(serverId))
    }

    private fun isCurrentBind(profileId: String, generation: Int): Boolean =
        bindGeneration == generation && provider.active.value?.id == profileId

    private suspend fun deferInitialBind(profile: Profile): Boolean = try {
        shouldDeferInitialBind(profile)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "The profile selection setting didn't read: binding" }
        false
    }

    private fun clearBoundServers() {
        manager.registeredServerIds.forEach(manager::removeServer)
        manager.setServerOrder(emptyList())
        servers.setExpectedVisibleServerIds(emptySet())
        servers.setVisibleServerIds(emptySet())
    }

    private fun now(): Long = clock.now().toEpochMilliseconds()

    private data class BindResult(
        val visible: Set<ServerId>,
        val expected: Set<ServerId>,
        // Fresh server lists by Plex account id, from this bind's plex.tv answers.
        val discovered: Map<String, Set<ServerId>> = emptyMap(),
    ) {
        companion object {
            val EMPTY = BindResult(emptySet(), emptySet())

            fun visible(ids: Set<ServerId>) = BindResult(ids, ids)
        }
    }

    private enum class FetchStatus { SUCCESS, EMPTY, AUTH_REJECTED, TRANSIENT_FAILURE, CANCELLED, FAILURE }

    private class FetchOutcome(val status: FetchStatus, val servers: List<PlexServer>, val error: Exception? = null)

    private class PlexBindToken(
        val token: String,
        val profileId: String,
        val profileLabel: String,
        val generation: Int,
        val invalidateCachedToken: suspend () -> Unit,
    )

    private companion object {
        const val TAG = "ProfileBinder"
    }
}

/** Whether a bind uses a Home user's kept token: once after the activation checked its PIN, else only at cold start. */
fun shouldUsePlexHomeTokenCache(preVerified: Boolean, hasBoundOnce: Boolean): Boolean = preVerified || !hasBoundOnce
