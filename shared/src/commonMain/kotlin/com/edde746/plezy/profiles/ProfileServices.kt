package com.edde746.plezy.profiles

import com.edde746.plezy.crash.StartupMark
import com.edde746.plezy.crash.StartupMarks
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.jellyfin.JellyfinAuthService
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.plex.tv.PlexAccountConnection
import com.edde746.plezy.plex.tv.PlexAuthService
import com.edde746.plezy.plex.tv.PlexHomeSwitchResult
import com.edde746.plezy.plex.tv.PlexHomeSwitchStatus
import com.edde746.plezy.plex.tv.buildPlexAccountConnection
import com.edde746.plezy.plex.tv.switchPlexHomeUserWithPin
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.MultiServerManager
import com.edde746.plezy.servers.MultiServerStore
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.completeWith
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlin.uuid.Uuid

/** How [ProfileServices.switchProfile] ended. [CANCELLED] (a PIN dialog dismissed, a newer switch) isn't an error. */
enum class ProfileSwitchResult { SWITCHED, CANCELLED, FAILED }

/** Where the app goes once [ProfileServices.start] has settled. */
enum class BootRoute {
    /** No connection, or connections but no profile: sign in. */
    SIGN_IN,

    /** No profile is active, or the user asked to pick one on every start: the picker. */
    PICK_PROFILE,

    /** The active profile is bound (or binding): the main screen. */
    MAIN,
}

/**
 * A Plex account a sign-in stored. [homeUsersFetched] is false when plex.tv's Home users didn't come (not "no users");
 * [existedBefore] whether the account was stored already, so an attach the user cancels knows to remove it again.
 */
data class PlexAccountRegistration(
    val connection: PlexAccountConnection,
    val homeUsersFetched: Boolean,
    val existedBefore: Boolean,
    val username: String,
    val email: String,
)

/** How a first Plex sign-in ([ProfileServices.signInWithPlex]) ended. */
sealed interface PlexSignInResult {
    /** The account has no server: nothing to show. */
    data class NoServers(val username: String, val email: String) : PlexSignInResult

    /** plex.tv's Home users didn't come and none are cached: no profile to use yet; retry. */
    data object HomeUsersUnavailable : PlexSignInResult

    /** Signed in; [pickProfile]: show the picker before the main screen. */
    data class SignedIn(val registration: PlexAccountRegistration, val pickProfile: Boolean) : PlexSignInResult
}

/** How adding a Jellyfin/Emby user ([ProfileServices.addMediaBrowserConnection]) ended. */
sealed interface MediaBrowserAddResult {
    /** Stored and bound to [profile]. */
    data class Added(val profile: Profile) : MediaBrowserAddResult

    /** Profiles exist but none is active: pick one, then add again. */
    data object PickProfile : MediaBrowserAddResult
}

/** A connection another profile ([source]) uses that a profile can borrow, as [binding]'s user. */
data class BorrowCandidate(val source: Profile, val binding: ProfileConnection, val connection: StoredConnection)

enum class BorrowResult { BORROWED, CANCELLED, INCORRECT_PIN, SOURCE_ACCOUNT_MISSING, FAILED }

/**
 * The device's profiles and their connections: the profile list and the active profile ([profiles], [active]), the
 * binding of the active profile's servers ([bindState]), the Plex Home users of each account, and the flows the UI
 * runs on them: switching profile, signing in, adding and borrowing connections, settling after a removal.
 *
 * [plexAuth] and [jellyfinAuth] build the plex.tv and Jellyfin/Emby sign-in services with the device's current
 * identity. Confined to [scope]'s thread, like [manager].
 */
class ProfileServices(
    private val data: LocalData,
    private val connections: ConnectionStore,
    private val bindings: ProfileConnectionRegistry,
    private val identity: ProfileIdentity,
    manager: MultiServerManager,
    servers: MultiServerStore,
    val plexAuth: suspend () -> PlexAuthService,
    val jellyfinAuth: suspend (MediaBrowserDialect) -> JellyfinAuthService,
    scope: CoroutineScope,
    private val clock: Clock,
) {
    private val work = scope.childScope()

    private val plexHome = PlexHomeService(
        connections,
        bindings,
        identity,
        fetchHomeUsers = { token -> plexAuth().getHomeUsers(token).users.map { PlexHomeUser.fromJson(it.toJson()) } },
        scope = scope,
    )
    private val provider = ActiveProfileProvider(data.profiles, connections, identity, plexHome, scope, clock)
    private val binder = ActiveProfileBinder(
        provider,
        connections,
        bindings,
        manager,
        servers,
        plexAuth,
        shouldDeferInitialBind = { !startupClaimed && requiresSelectionOnOpen() },
        scope = scope,
        clock = clock,
    )
    private var starting = false
    private val started = CompletableDeferred<Unit>()

    /** The start activated the profile a launch link named ([start]'s `startupProfile`): no picker asks over it. */
    private var startupClaimed = false

    /** Removing profiles, connections and accounts; follow a removal with [settleAfterRemoval]. */
    val teardown = ProfileTeardown(data, connections, bindings)

    /** The local profiles and one per cached Plex Home user, most recently used first. */
    val profiles: StateFlow<List<Profile>> get() = provider.profiles

    val active: StateFlow<Profile?> get() = provider.active

    /** True once [profiles] and [active] were read. */
    val hydrated: StateFlow<Boolean> get() = provider.hydrated

    val bindState: StateFlow<ProfileBindState> get() = binder.bindState

    private val mutableSwitching = MutableStateFlow(false)
    private var verifiedSwitches = 0

    /**
     * A [switchProfile] is under way past its PIN: from the PIN accepted (or none needed) until the switch has ended,
     * however it ends. A PIN still being asked or checked isn't a switch yet.
     */
    val switching: StateFlow<Boolean> = mutableSwitching.asStateFlow()

    /** The cached Plex Home users by account connection id. */
    val plexHomeUsers: StateFlow<Map<String, List<PlexHomeUser>>> get() = plexHome.users

    /** Asks for a Plex Home PIN when a bind needs one; unset, such a bind fails. */
    var pinPrompt: ProfilePinPrompt?
        get() = binder.pinPrompt
        set(value) {
            binder.pinPrompt = value
        }

    /**
     * Starts the profiles: deletes the tokens a change interrupted by the app's end left, removes the Jellyfin/Emby
     * connections no profile uses, loads the cached Plex Home users and refreshes them now and hourly, reads the
     * profiles, then binds the active one. With [allowInitialPinPrompt] false (no network: plex.tv can't check a PIN)
     * that first bind asks for none. Runs once, before any other change of the profiles or connections; [bootRoute]
     * waits for it.
     *
     * [startupProfile] picks, among the profiles read, one that a launch link names (a `plezy://` link the app was
     * opened with): the start activates it before the first bind, in place of the profile active before and of the
     * picker, and tells [settleStartupProfile] whether it did. A PIN-protected profile is never picked here: its PIN is
     * asked once the app shows.
     */
    fun start(
        allowInitialPinPrompt: Boolean = true,
        startupProfile: (List<Profile>) -> Profile? = { null },
        settleStartupProfile: (applied: Boolean) -> Unit = {},
    ) {
        if (starting) return
        starting = true
        work.launch {
            started.completeWith(
                runCatching {
                    connections.sweepUnreferencedSecrets()
                    val pruned = teardown.pruneUnreferencedJellyfinConnections()
                    if (pruned > 0) Log.i(TAG) { "Removed $pruned Jellyfin/Emby connections no profile uses" }
                    plexHome.start()
                    provider.reloadFromStorage()
                    StartupMarks.mark(StartupMark.CREDENTIALS_LOADED)
                    startupProfile(profiles.value)?.let { claimed ->
                        startupClaimed = active.value?.id == claimed.id || provider.activate(claimed)
                        settleStartupProfile(startupClaimed)
                    }
                    StartupMarks.mark(StartupMark.BINDING_STARTED)
                    binder.start(allowInitialPinPrompt)
                },
            )
        }
    }

    /** Where the app goes once [start] has run (called earlier, it waits for it): sign-in, the picker or the main screen. */
    suspend fun bootRoute(): BootRoute {
        started.await()
        if (connections.list().isEmpty()) return BootRoute.SIGN_IN
        if (active.value == null && profiles.value.isEmpty()) return BootRoute.SIGN_IN
        if (active.value == null || (!startupClaimed && requiresSelectionOnOpen())) return BootRoute.PICK_PROFILE
        return BootRoute.MAIN
    }

    /** "Ask for a profile on app open": on, and there is more than one profile to pick from. */
    suspend fun requiresSelectionOnOpen(): Boolean =
        data.deviceSettings.value(AppSettings.requireProfileSelectionOnOpen) && provider.hasMultipleProfiles

    /** The outcome of the bind running now, or of the last one. */
    suspend fun awaitBindingSettle(): Boolean = binder.awaitBindingSettle()

    suspend fun rebindActive() = binder.rebindActive()

    /** Binds the active profile again when it is [profileId] (its connections changed). */
    suspend fun rebindIfActive(profileId: String) = binder.rebindIfActive(profileId)

    /** Fetches Plex account [accountId]'s server list again and applies it (a server failed to reconnect). */
    suspend fun refreshPlexServers(accountId: String) = binder.refreshPlexServers(accountId)

    /**
     * Switches to [profile] from the UI and waits for its bind. A local profile's PIN is asked through [pinPrompt]
     * until right or cancelled; a protected Plex Home user's is checked with plex.tv before anything changes. When the
     * bind fails only for connectivity and the profile owns downloads, it stays active, offline; otherwise the profile
     * active before comes back (without its PIN) and the switch [ProfileSwitchResult.FAILED]. [switching] holds from
     * the PIN accepted until this returns or is cancelled.
     */
    suspend fun switchProfile(profile: Profile, pinPrompt: ProfilePinPrompt): ProfileSwitchResult {
        // Claimed before the PIN is asked or checked with plex.tv: a switch asked for later supersedes this one while it
        // waits there.
        val request = provider.beginRequest()
        var verified = false
        try {
            return switchAfterPin(profile, pinPrompt, request) {
                verified = true
                mutableSwitching.value = ++verifiedSwitches > 0
            }
        } finally {
            if (verified) mutableSwitching.value = --verifiedSwitches > 0
        }
    }

    private suspend fun switchAfterPin(profile: Profile, pinPrompt: ProfilePinPrompt, request: Int, onVerified: () -> Unit): ProfileSwitchResult {
        val activation = activateWithPin(profile, pinPrompt, request, onVerified)
        if (activation.result != ProfileSwitchResult.SWITCHED) return activation.result
        val previous = activation.rollback
        var generation = activation.generation
        fun isCurrent(profileId: String) = provider.committedGeneration == generation && active.value?.id == profileId

        if (!isCurrent(profile.id)) return ProfileSwitchResult.CANCELLED
        val bound = binder.awaitBindingSettle()
        if (!isCurrent(profile.id)) return ProfileSwitchResult.CANCELLED
        if (bound) return ProfileSwitchResult.SWITCHED

        if (binder.bindState.value.connectivityOnlyFailure) {
            // Identity was checked before activation; the profile before doesn't own these downloads.
            val owned = data.downloadLibrary.getDownloadOwnerKeysForProfile(profile.id)
            if (!isCurrent(profile.id)) return ProfileSwitchResult.CANCELLED
            if (owned.isNotEmpty()) {
                Log.i(TAG) { "Keeping ${profile.displayName} active offline: it owns ${owned.size} downloads" }
                return ProfileSwitchResult.SWITCHED
            }
        }

        if (previous != null && previous.id != profile.id) {
            try {
                // Going back to the profile the user was on isn't a new switch: its kept token is used, no PIN asked.
                binder.markUserInitiatedActivation(previous.id)
                if (previous is PlexHomeProfile) binder.markPlexHomePreVerified(previous.id)
                val restored = provider.restoreAfterFailedActivation(previous, profile.id, generation) ?: return ProfileSwitchResult.CANCELLED
                generation = restored
                if (!binder.bindState.value.binding) binder.rebindActive()
                binder.awaitBindingSettle()
                if (!isCurrent(previous.id)) return ProfileSwitchResult.CANCELLED
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Restoring ${previous.id} after a failed switch failed" }
            }
        }
        return if (provider.committedGeneration == generation) ProfileSwitchResult.FAILED else ProfileSwitchResult.CANCELLED
    }

    /** Clears the active profile so the picker asks for one, and drops the bound servers. */
    suspend fun clearActiveProfile() {
        provider.clearActiveProfile()
        binder.rebindActive()
    }

    /**
     * Stores the Plex account a plex.tv sign-in gave [token] for (its servers listed), folding an earlier row keyed by
     * this device's client identifier into it in the same transaction, and fetches its Home users.
     */
    suspend fun registerPlexAccountFromToken(token: String): PlexAccountRegistration {
        data.acknowledgeRecoveryRequired()
        val auth = plexAuth()
        val build = buildPlexAccountConnection(token, auth.clientIdentifier, now(), auth::getUserInfo, auth::fetchServers)
        val connection = build.connection
        // An earlier sign-in that didn't learn the account's uuid keyed it by this device's client identifier, the same
        // for every account here: its bindings move to this row and it goes.
        val legacyId = "plex.${connection.clientIdentifier}"
        val legacy = if (build.accountUuid.isNotEmpty() && legacyId != connection.id) connections.get(legacyId)?.plexAccount() else null
        val existedBefore = connections.get(connection.id) != null || legacy != null
        val moved = if (legacy == null) emptyList() else bindings.listForConnection(legacyId).map { it.copy(connectionId = connection.id) }
        bindings.commit(
            IdentityChange(
                connections = listOf(connection.stored()),
                bindings = moved,
                removedConnectionIds = listOfNotNull(legacy?.id),
            ),
        )
        if (legacy != null) {
            identity.clearPlexHomeUsers(legacyId)
            Log.i(TAG) { "Folded Plex account $legacyId into ${connection.id}" }
        }
        val homeUsersFetched = plexHome.refresh(connection)
        return PlexAccountRegistration(connection, homeUsersFetched, existedBefore, build.username, build.email)
    }

    /**
     * The first Plex sign-in: [registerPlexAccountFromToken], then the profile to start with. A single Home user
     * without a PIN becomes active; otherwise none is, and the picker asks (a PIN is checked there).
     */
    suspend fun signInWithPlex(token: String): PlexSignInResult {
        val registration = registerPlexAccountFromToken(token)
        val account = registration.connection
        if (account.servers.isEmpty()) return PlexSignInResult.NoServers(registration.username, registration.email)
        val users = plexHome.users.value[account.id]
        if (!registration.homeUsersFetched && users == null) return PlexSignInResult.HomeUsersUnavailable
        provider.initialize()
        val only = users?.singleOrNull()?.takeIf { !it.protected }
        if (only == null) provider.clearActiveProfile() else provider.activate(PlexHomeProfile.virtualPlexHome(account.id, only))
        binder.start()
        val pickProfile = requiresSelectionOnOpen() ||
            (active.value == null && (profiles.value.isNotEmpty() || !users.isNullOrEmpty()))
        return PlexSignInResult.SignedIn(registration, pickProfile)
    }

    /** After adding [connectionId] again (a new sign-in), binds the active profile again when it uses it. */
    suspend fun rebindActiveIfUses(connectionId: String) {
        val current = active.value ?: return
        val uses = current.parentConnectionId == connectionId || bindings.listForProfile(current.id).any { it.connectionId == connectionId }
        if (!uses) return
        // The new account token needs a new switch, which may ask for the PIN: the user just signed in.
        binder.markUserInitiatedActivation(current.id)
        binder.rebindActive()
    }

    /**
     * Stores a signed-in Jellyfin/Emby user ([connection]) for [targetProfile], else the active profile. On the first
     * run (no profile at all) it gets a new local profile named after the user (else the server), made active. The
     * profile, the connection and its binding are stored in one transaction; when that activation fails, one more puts
     * back what was there before and the failure is thrown. Profiles but no active one: [MediaBrowserAddResult.PickProfile].
     */
    suspend fun addMediaBrowserConnection(connection: JellyfinConnection, targetProfile: Profile? = null): MediaBrowserAddResult {
        data.acknowledgeRecoveryRequired()
        provider.initialize()
        val current = active.value
        if (targetProfile == null && current == null && profiles.value.isNotEmpty()) return MediaBrowserAddResult.PickProfile
        val now = now()
        val firstRun = if (targetProfile == null && current == null) {
            LocalProfile(
                id = newLocalProfileId(),
                displayName = connection.userName.ifEmpty { connection.serverName },
                sortOrder = now,
                createdAt = now,
            )
        } else {
            null
        }
        val profile = targetProfile ?: current ?: checkNotNull(firstRun)
        val row = ProfileConnection(profile.id, connection.id, connection.accessToken, connection.userId, tokenAcquiredAt = now)
        val priorActiveId = identity.activeProfileId()
        val priorConnection = connections.get(connection.id)
        bindings.commit(IdentityChange(profiles = listOfNotNull(firstRun), connections = listOf(connection.stored()), bindings = listOf(row)))
        if (firstRun != null) {
            try {
                check(provider.activate(firstRun)) { "The first-run profile could not be activated" }
            } catch (e: Exception) {
                compensate("connection add") {
                    bindings.commit(
                        IdentityChange(
                            connections = listOfNotNull(priorConnection),
                            removedProfileIds = listOf(firstRun.id),
                            removedBindings = listOf(row.profileId to row.connectionId),
                            removedConnectionIds = if (priorConnection == null) listOf(connection.id) else emptyList(),
                        ),
                    )
                }
                compensate("recency") { identity.clearProfileLastUsed(firstRun.id) }
                compensate("active marker") { if (priorActiveId == null) identity.clearActiveProfileId() else identity.setActiveProfileId(priorActiveId) }
                compensate("profiles reload") { provider.reloadFromStorage() }
                throw e
            }
        } else {
            binder.rebindIfActive(profile.id)
        }
        return MediaBrowserAddResult.Added(profile)
    }

    /**
     * Makes a local profile named [displayName] (trimmed; blank throws IllegalArgumentException) with an optional
     * [pin]. It isn't activated: its connections come next.
     */
    suspend fun createLocalProfile(displayName: String, pin: String? = null): LocalProfile {
        val name = displayName.trim()
        require(name.isNotEmpty()) { "A profile needs a name" }
        val now = now()
        val profile = LocalProfile(
            id = newLocalProfileId(),
            displayName = name,
            pinHash = pin?.let(::computePinHash),
            sortOrder = now,
            createdAt = now,
        )
        data.profiles.upsert(profile)
        provider.reloadFromStorage()
        return profile
    }

    /**
     * Renames the local profile [profileId] to [displayName] (trimmed; blank throws IllegalArgumentException), its
     * other columns as they're stored now, and reads the profiles again.
     */
    suspend fun renameLocalProfile(profileId: String, displayName: String) {
        data.profiles.rename(profileId, displayName)
        provider.reloadFromStorage()
    }

    /** Sets the local profile [profileId]'s PIN ([pin] null: none), the rest as it's stored now, and reads the profiles again. */
    suspend fun setLocalProfilePin(profileId: String, pin: String?) {
        data.profiles.setPinHash(profileId, pin?.let(::computePinHash))
        provider.reloadFromStorage()
    }

    /**
     * The connections [target] can borrow from the other profiles, one per connection and user: first each Plex Home
     * profile's own account, then every other profile's bindings. Those [target] already has are left out.
     */
    suspend fun borrowCandidates(target: Profile): List<BorrowCandidate> {
        provider.initialize()
        val rows = bindings.listAll()
        val byId = connections.list().associateBy { it.id }
        val all = profiles.value
        val owned = rows.filter { it.profileId == target.id }.map { it.connectionId }.toMutableSet()
        target.parentConnectionId?.let { owned += it }
        val seen = HashSet<String>()
        val candidates = mutableListOf<BorrowCandidate>()
        for (source in all) {
            if (source.id == target.id || source !is PlexHomeProfile) continue
            val parentId = source.parentConnectionId ?: continue
            val homeUuid = source.plexHomeUserUuid ?: continue
            if (parentId in owned) continue
            val connection = byId[parentId] ?: continue
            if (!seen.add("$parentId/$homeUuid")) continue
            candidates += BorrowCandidate(source, ProfileConnection(source.id, parentId, null, homeUuid), connection)
        }
        for (row in rows) {
            if (row.profileId == target.id || row.connectionId in owned) continue
            val connection = byId[row.connectionId] ?: continue
            val source = all.firstOrNull { it.id == row.profileId } ?: continue
            if (!seen.add("${row.connectionId}/${row.userIdentifier}")) continue
            candidates += BorrowCandidate(source, row, connection)
        }
        return candidates
    }

    /**
     * Gives [target] its own use of [candidate]'s connection, once the source profile's PIN is right ([pinPrompt]
     * asks for it). A Plex account gets a token minted for the source's Home user; a Jellyfin/Emby user is copied.
     */
    suspend fun borrow(target: Profile, candidate: BorrowCandidate, pinPrompt: ProfilePinPrompt): BorrowResult {
        val source = candidate.source
        val account = candidate.connection.plexAccount()
        if (source.isPinProtected) {
            when (source) {
                is LocalProfile -> {
                    val pin = pinPrompt(source, false) ?: return BorrowResult.CANCELLED
                    if (!verifyProfilePin(source, pin)) return BorrowResult.INCORRECT_PIN
                }
                // A Plex borrow asks for the Home user's PIN as it mints; any other is checked with a switch first.
                is PlexHomeProfile -> if (account == null) {
                    val parentId = source.parentConnectionId
                    val homeUuid = source.plexHomeUserUuid
                    if (parentId == null || homeUuid == null) return BorrowResult.FAILED
                    val parent = connections.get(parentId)?.plexAccount() ?: return BorrowResult.SOURCE_ACCOUNT_MISSING
                    val checked = mintPlexHomeUserToken(parent, homeUuid, requiresPin = true, prompt = { pinPrompt(source, it) })
                    if (!checked.succeeded) return checked.borrowFailure()
                }
            }
        }
        if (account != null) {
            val minted = mintPlexHomeUserToken(
                account,
                candidate.binding.userIdentifier,
                requiresPin = (source as? PlexHomeProfile)?.plexProtected == true,
                prompt = { pinPrompt(source, it) },
                persistProfileId = target.id,
            )
            if (!minted.succeeded) return minted.borrowFailure()
        } else {
            val mediaBrowser = checkNotNull(candidate.connection.mediaBrowser())
            bindings.upsert(
                ProfileConnection(
                    profileId = target.id,
                    connectionId = mediaBrowser.id,
                    userToken = if (candidate.binding.hasToken) candidate.binding.userToken else mediaBrowser.accessToken,
                    userIdentifier = candidate.binding.userIdentifier.ifEmpty { mediaBrowser.userId },
                    tokenAcquiredAt = now(),
                ),
            )
        }
        work.launch { binder.rebindIfActive(target.id) }
        return BorrowResult.BORROWED
    }

    /**
     * Settles the session after a profile, connection or account was removed: back to sign-in when nothing is left
     * (the active profile cleared); the active profile kept when it's still there (bound again with
     * [rebindIfActiveKept]); else the most recently used profile without a PIN activated, or none (the picker asks).
     */
    suspend fun settleAfterRemoval(rebindIfActiveKept: Boolean = false): PostRemovalOutcome {
        val outcome = teardown.settleAfterRemoval(plexHome.users.value)
        provider.reloadFromStorage()
        when (outcome) {
            is PostRemovalOutcome.KeepActive -> if (rebindIfActiveKept) binder.rebindActive()
            is PostRemovalOutcome.Activate -> {
                // The removal was the user's: the next profile binds at once.
                binder.markUserInitiatedActivation(outcome.profile.id)
                if (!provider.activate(outcome.profile)) clearActiveProfile()
            }
            PostRemovalOutcome.SignedOut, PostRemovalOutcome.PickProfile -> clearActiveProfile()
        }
        return outcome
    }

    /** Logs out of every profile and account ([ProfileTeardown.logOutAll]); the session goes back to sign-in. */
    suspend fun logOutAll() {
        plexHome.clearAll()
        teardown.logOutAll()
        clearActiveProfile()
    }

    /** Stops the profiles' background work. */
    fun close() {
        binder.close()
        provider.close()
        plexHome.close()
        work.cancel()
    }

    /**
     * Asks for (and checks) [profile]'s PIN, then activates it, as switch [request], calling [onVerified] once the PIN
     * is accepted (or none is needed): once a newer change of the active profile was asked for, it stops wherever it is
     * with [ProfileSwitchResult.CANCELLED], changing nothing.
     */
    private suspend fun activateWithPin(profile: Profile, pinPrompt: ProfilePinPrompt, request: Int, onVerified: () -> Unit): Activation {
        // A PIN typed for a superseded request is a cancelled one.
        val prompt: ProfilePinPrompt = { target, incorrect -> pinPrompt(target, incorrect)?.takeIf { provider.isRequestCurrent(request) } }
        return when (profile) {
            is PlexHomeProfile -> {
                val verified = if (profile.plexProtected) preVerifyPlexHomePin(profile, prompt, request) else PlexHomeSwitchStatus.SUCCESS
                when {
                    !provider.isRequestCurrent(request) -> Activation(ProfileSwitchResult.CANCELLED)
                    verified == PlexHomeSwitchStatus.SUCCESS -> activateVerified(profile, null, request, onVerified)
                    verified == PlexHomeSwitchStatus.CANCELLED -> Activation(ProfileSwitchResult.CANCELLED)
                    else -> Activation(ProfileSwitchResult.FAILED)
                }
            }
            is LocalProfile -> {
                val hash = profile.pinHash
                if (hash.isNullOrEmpty()) {
                    activateVerified(profile, null, request, onVerified)
                } else {
                    var incorrect = false
                    var activation: Activation? = null
                    while (activation == null) {
                        val pin = prompt(profile, incorrect)
                        activation = when {
                            pin == null -> Activation(ProfileSwitchResult.CANCELLED)
                            verifyPin(pin, hash) -> activateVerified(profile, pin, request, onVerified)
                            else -> null.also { incorrect = true }
                        }
                    }
                    activation
                }
            }
        }
    }

    private suspend fun activateVerified(profile: Profile, pin: String?, request: Int, onVerified: () -> Unit): Activation {
        if (!provider.isRequestCurrent(request)) return Activation(ProfileSwitchResult.CANCELLED)
        onVerified()
        // Captured now: while a PIN was checked another profile may have become active.
        val rollback = active.value
        binder.markUserInitiatedActivation(profile.id)
        try {
            if (provider.activate(profile, pin, request)) return Activation(ProfileSwitchResult.SWITCHED, rollback, request)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (provider.isRequestCurrent(request)) Log.w(TAG, e) { "Activating ${profile.id} failed" }
        }
        return Activation(if (provider.isRequestCurrent(request)) ProfileSwitchResult.FAILED else ProfileSwitchResult.CANCELLED)
    }

    /**
     * Checks a protected Home user's PIN with plex.tv before the switch: the minted token is kept and, while [request]
     * is current, the binder uses it once. Without the account or user to check, the binder's own bind decides.
     */
    private suspend fun preVerifyPlexHomePin(profile: PlexHomeProfile, pinPrompt: ProfilePinPrompt, request: Int): PlexHomeSwitchStatus {
        val parentId = profile.parentConnectionId ?: return PlexHomeSwitchStatus.SUCCESS
        val homeUuid = profile.plexHomeUserUuid ?: return PlexHomeSwitchStatus.SUCCESS
        val account = connections.get(parentId)?.plexAccount() ?: return PlexHomeSwitchStatus.SUCCESS
        val result = mintPlexHomeUserToken(account, homeUuid, requiresPin = true, prompt = { pinPrompt(profile, it) }, persistProfileId = profile.id)
        if (result.succeeded && provider.isRequestCurrent(request)) binder.markPlexHomePreVerified(profile.id)
        return result.status
    }

    /** Switches into Home user [homeUuid] of [account]; the token is kept as [persistProfileId]'s binding when given. */
    private suspend fun mintPlexHomeUserToken(
        account: PlexAccountConnection,
        homeUuid: String,
        requiresPin: Boolean,
        prompt: suspend (incorrectPin: Boolean) -> String?,
        persistProfileId: String? = null,
    ): PlexHomeSwitchResult {
        val auth = plexAuth()
        val result = switchPlexHomeUserWithPin(
            requiresPin = requiresPin,
            promptForPin = prompt,
            switchToUser = { pin -> auth.switchToUser(homeUuid, account.accountToken, pin) },
            logLabel = homeUuid,
        )
        val token = result.userToken
        if (result.succeeded && token != null && persistProfileId != null) {
            bindings.upsert(ProfileConnection(persistProfileId, account.id, token, homeUuid, tokenAcquiredAt = now()))
        }
        return result
    }

    private suspend fun compensate(step: String, block: suspend () -> Unit) {
        try {
            block()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Undoing the $step of a failed connection add failed" }
        }
    }

    private fun PlexHomeSwitchResult.borrowFailure(): BorrowResult =
        if (status == PlexHomeSwitchStatus.CANCELLED) BorrowResult.CANCELLED else BorrowResult.FAILED

    private fun now(): Long = clock.now().toEpochMilliseconds()

    private class Activation(val result: ProfileSwitchResult, val rollback: Profile? = null, val generation: Int = 0)

    private companion object {
        const val TAG = "Profiles"
    }
}

/** A new local profile's id: `local-` and a lowercase UUID v4. */
private fun newLocalProfileId(): String = "local-${Uuid.random()}"

/**
 * Whether [pin] unlocks [profile] on this device: a local profile without a PIN always, one with a PIN when it's
 * right; never a Plex Home profile, whose PIN only plex.tv checks.
 */
fun verifyProfilePin(profile: Profile, pin: String): Boolean {
    if (profile !is LocalProfile) return false
    val hash = profile.pinHash
    return hash.isNullOrEmpty() || verifyPin(pin, hash)
}
