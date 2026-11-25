package com.edde746.plezy.trackers

import com.edde746.plezy.data.tracker.TrackerAccount
import com.edde746.plezy.data.tracker.TrackerAccountRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.trackers.ratings.TrackerRatingsProvider
import com.edde746.plezy.trackers.ratings.TrackerRatingsSource
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.isActive
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlin.time.TimeSource

/** What the user acts on while an account connects: a code to enter (or scan), or a link to open (or scan). */
sealed interface SignInPrompt {
    /** Enter [grant]'s user code at its verification URL, or scan its complete URL. */
    data class DeviceCode(val grant: DeviceCodeGrant) : SignInPrompt

    /** Open (or scan) [start]'s URL and authorize there. */
    data class Link(val start: RelayStart) : SignInPrompt
}

/** The sign-in in flight on this device: one at a time, across every profile and service. */
class TrackerConnecting internal constructor(val profileId: String, val service: TrackerService) {
    internal var work: Deferred<TrackerAccount?>? = null
    internal var cancelled = false

    internal fun cancel() {
        cancelled = true
        work?.cancel()
    }

    override fun toString(): String = "TrackerConnecting(${service.id})"
}

/**
 * One connection's sign-in: its account row and the [credentials] its requests use. The same instance as long as the
 * sign-in lasts; a reconnect or a disconnect ends it (its credentials then fail with a permanent
 * [TrackerException.Auth]).
 */
class TrackerBinding internal constructor(
    val account: TrackerAccount,
    internal val provider: TrackerProvider,
    val credentials: TrackerCredentials,
) {
    val service: TrackerService get() = account.service

    internal val connectedAt: Long get() = account.connectedAt

    internal val tracker: Tracker = provider.tracker(credentials)

    internal val ratings: TrackerRatingsSource? by lazy { (provider as? TrackerRatingsProvider)?.ratings(credentials) }

    override fun toString(): String = "TrackerBinding(${service.id}, connectedAt=$connectedAt)"
}

/**
 * A profile's tracker accounts on this device: sign-in, the connection list and the session behind each connection.
 *
 * This device keeps the connections ([TrackerAccountRepository]) and each one's session, refresh token included
 * ([TrackerTokenStore]), and alone refreshes it at the service ([TrackerProvider.refresher]). Both are kept per profile
 * scope ([profileUserScope]): a Plex Home user's profile on every account shares one connection per service.
 *
 * Each connection is a binding named by [TrackerAccount.connectedAt] (when this device signed it in), published only
 * once its session is loaded ([bindings]). Its [TrackerCredentials] refresh one request at a time, keep the new session
 * before handing its token out (or, when the store fails, hold it and keep it before the next use), and drop the
 * binding when the service declares the session dead. A callback of an ended binding (a late refresh, a late 401)
 * changes nothing.
 *
 * One sign-in runs at a time ([connecting]). It keeps its session only while it is still current: a sign-in cancelled
 * ([cancelConnect], the caller cancelled, the same service disconnected) or overtaken by another connection of the
 * service keeps nothing.
 */
class TrackerAccounts internal constructor(
    private val repository: TrackerAccountRepository,
    private val tokens: TrackerTokenStore,
    providers: List<TrackerProvider>,
    private val relay: OAuthRelay?,
    private val clock: Clock,
    private val timeSource: TimeSource,
    private val onConnected: (profileId: String) -> Unit,
) {
    private val providers: Map<TrackerService, TrackerProvider> = providers.associateBy { it.service }
    private val mutations = Mutex()
    private val bindings = mutableMapOf<Pair<String, TrackerService>, TrackerBinding>()
    private val connectingState = MutableStateFlow<TrackerConnecting?>(null)

    /** The services this build can connect (those with a client registration), in [TrackerService] order. */
    val services: List<TrackerService> = TrackerService.entries.filter { it in this.providers }

    /** The sign-in in flight, or `null`. */
    val connecting: StateFlow<TrackerConnecting?> = connectingState.asStateFlow()

    /** The profile's connections, oldest sign-in first: those with a usable session ([bindings]). */
    fun observe(profileId: String): Flow<List<TrackerAccount>> = bindings(profileId).map { list -> list.map { it.account } }

    suspend fun accounts(profileId: String): List<TrackerAccount> =
        repository.accounts(profileId).mapNotNull { account -> hydrate(profileId, account)?.account }

    /**
     * The profile's connections bound to their sign-ins, oldest first: the same [TrackerBinding] as long as a sign-in
     * lasts, a new one after a reconnect. A binding is published with its session loaded: a connection whose session
     * this device doesn't hold, holds for another sign-in or can't renew is dropped with its queued writes; one whose
     * session the store can't read for now is left out. Connections to services this build has no provider for are
     * left out.
     */
    fun bindings(profileId: String): Flow<List<TrackerBinding>> = repository.observeAccounts(profileId).map { accounts ->
        accounts.mapNotNull { account -> hydrate(profileId, account) }
    }

    /**
     * The profile's connections whose session comes from a sign-in method the service is retiring (Simkl's AUTH V1):
     * the account's settings offer [reconnect].
     */
    fun legacy(profileId: String): Flow<Set<TrackerService>> = observe(profileId).map { accounts ->
        accounts.filter { account -> isLegacy(profileId, account) }.map { it.service }.toSet()
    }

    /**
     * Connects [service] for [profileId]: shows [prompt] (a device code, or the relay's link), waits until the user
     * authorized, looks the account's name up, and keeps the session. Returns `null` when nothing was connected: the
     * user declined or the code expired, the sign-in was cancelled ([cancelConnect], a disconnect of the service) or
     * overtaken by another connection of the service, another sign-in is in flight, or the service is connected
     * already. Cancelling the caller gives up as well.
     *
     * @throws TrackerException the service or the relay failed (a [TrackerException.SignIn] when it refused), or the
     *   secret store couldn't keep the session ([TrackerException.SecretStore]).
     */
    @Throws(TrackerException::class, CancellationException::class)
    suspend fun signIn(profileId: String, service: TrackerService, prompt: (SignInPrompt) -> Unit): TrackerAccount? =
        runConnect(profileId, service, prompt, reconnect = false)

    /**
     * Signs [service] in again for [profileId] while its connection is legacy ([legacy]), replacing that session in
     * place once the new one is approved. Writes queued under the old session are kept only when both sessions are
     * verifiably the same account; otherwise they are dropped, as for a new account. Returns `null` as [signIn] does,
     * also when the connection isn't legacy.
     *
     * @throws TrackerException as [signIn].
     */
    @Throws(TrackerException::class, CancellationException::class)
    suspend fun reconnect(profileId: String, service: TrackerService, prompt: (SignInPrompt) -> Unit): TrackerAccount? =
        runConnect(profileId, service, prompt, reconnect = true)

    /** Cancels the sign-in in flight (it then keeps nothing and answers `null`); nothing when none is. */
    fun cancelConnect() {
        connectingState.value?.cancel()
    }

    /**
     * Keeps a signed-in [session] as the profile's [service] connection, replacing any previous one (whose queued
     * writes are dropped), then replays the profile's queued writes.
     *
     * @throws TrackerException.SecretStore when the secret store couldn't keep the session; nothing is connected then.
     */
    suspend fun connect(profileId: String, service: TrackerService, session: TrackerSession): TrackerAccount {
        val account = mutations.withLock { keep(profileId, service, session, keepQueuedWrites = false) }
        Log.i(TAG) { "${service.id} connected" }
        onConnected(profileId)
        return account
    }

    /**
     * Disconnects [service] from the profile: cancels its sign-in in flight, drops the connection, its queued writes
     * and its session, then revokes the session at the service (best effort, where the service can).
     *
     * @throws TrackerException.SecretStore when the secret store couldn't delete the session: the connection is gone
     *   then, and the cleanup of unused sessions tries again.
     */
    suspend fun disconnect(profileId: String, service: TrackerService) {
        val scope = profileUserScope(profileId)
        connectingState.value?.takeIf { profileUserScope(it.profileId) == scope && it.service == service }?.cancel()
        val stored = mutations.withLock {
            bindings.remove(scope to service)?.let { (it.credentials as AccountCredentials).gone = true }
            repository.disconnect(profileId, service)
            val stored = try {
                tokens.load(scope, service)
            } catch (e: TrackerException.SecretStore) {
                Log.w(TAG) { "${service.id} session unreadable, nothing to revoke" }
                null
            }
            tokens.clear(scope, service)
            stored
        }
        Log.i(TAG) { "${service.id} disconnected" }
        if (stored != null) providers[service]?.revoke(stored.session)
    }

    /** The profile's connections as trackers, each bound to its sign-in (see [bindings]). */
    internal fun bound(profileId: String): Flow<List<BoundTracker>> = bindings(profileId).map { list ->
        list.map { BoundTracker(it.account, it.tracker) }
    }

    /**
     * The public scores the profile's connections read, in [TrackerService] order: one source per connected service
     * that has them, the same instance as long as its sign-in lasts.
     */
    internal fun ratingsSources(profileId: String): Flow<List<TrackerRatingsSource>> = bindings(profileId).map { list ->
        list.sortedBy { it.service.ordinal }.mapNotNull { it.ratings }
    }

    /** Clears the sessions no connection uses any more: a connection gone takes its session with it. */
    internal suspend fun clearUnusedTokens() {
        mutations.withLock {
            val connected = repository.connections()
            for ((scope, service) in tokens.stored() - connected) {
                tokens.clear(scope, service)
                bindings.remove(scope to service)?.let { (it.credentials as AccountCredentials).gone = true }
                Log.i(TAG) { "${service.id} session of a removed connection cleared" }
            }
        }
    }

    /**
     * Moves the connections and sessions earlier builds kept under a Plex Home profile's full id to its scope
     * ([profileUserScope]), where the Home user's profile on every account finds them, with no sign-in again. Per scope
     * and service the newest sign-in with a usable session is kept, the scope's own included; the others go with their
     * queued writes, as do writes left under a full id with no connection. The hub runs it before the trackers' first
     * use and before clearing unused sessions.
     */
    internal suspend fun adoptLegacyScopes() {
        mutations.withLock {
            val legacy = repository.legacyConnections().groupBy { (profileId, account) -> profileUserScope(profileId) to account.service }
            for ((key, connections) in legacy) {
                val (scope, service) = key
                val newest = connections
                    .mapNotNull { (profileId, account) -> tokens.load(profileId, service)?.takeIf { it.connectedAt == account.connectedAt }?.let { profileId to it } }
                    .maxByOrNull { (_, stored) -> stored.connectedAt }
                val own = repository.account(scope, service)?.takeIf { tokens.load(scope, service)?.connectedAt == it.connectedAt }
                val kept = newest?.takeIf { (_, stored) -> own == null || stored.connectedAt > own.connectedAt }
                // The session first: a connection row never exists without it.
                kept?.let { (_, stored) -> tokens.save(scope, service, stored) }
                repository.adoptLegacy(service, connections.map { it.first }, kept?.first)
                for ((profileId, _) in connections) tokens.clear(profileId, service)
                Log.i(TAG) { "${service.id} connection moved to its profile scope" }
            }
            repository.dropLegacyQueuedWrites()
        }
    }

    private suspend fun runConnect(
        profileId: String,
        service: TrackerService,
        prompt: (SignInPrompt) -> Unit,
        reconnect: Boolean,
    ): TrackerAccount? {
        val provider = providers[service] ?: throw TrackerException.SignIn(service, "not available in this build")
        val claim = TrackerConnecting(profileId, service)
        if (!connectingState.compareAndSet(null, claim)) {
            Log.i(TAG) { "${service.id} sign-in refused: another one is in flight" }
            return null
        }
        try {
            val current = repository.account(profileId, service)
            val replaced = if (reconnect) {
                current?.let { tokens.load(profileUserScope(profileId), service) }
                    ?.takeIf { it.connectedAt == current.connectedAt && provider.isLegacy(it.session) }
                    ?: return null
            } else {
                if (current != null) return null
                null
            }
            return coroutineScope {
                val work = async(start = CoroutineStart.LAZY) { authorize(provider, profileId, prompt, replaced) }
                claim.work = work
                if (claim.cancelled) work.cancel()
                try {
                    work.await()
                } catch (e: CancellationException) {
                    if (!isActive) throw e
                    Log.i(TAG) { "${service.id} sign-in cancelled" }
                    null
                }
            }
        } finally {
            connectingState.compareAndSet(claim, null)
        }
    }

    /** The sign-in itself: [replaced] is the legacy session a reconnect replaces. */
    private suspend fun authorize(
        provider: TrackerProvider,
        profileId: String,
        prompt: (SignInPrompt) -> Unit,
        replaced: StoredSession?,
    ): TrackerAccount? {
        val service = provider.service
        when (val signIn = provider.signIn) {
            is TrackerSignIn.DeviceCode -> {
                val grant = signIn.requestCode()
                prompt(SignInPrompt.DeviceCode(grant))
                val answer = DeviceCodePoller.poll(grant, timeSource) { signIn.probe(grant) }
                if (answer !is DevicePoll.Success) {
                    Log.i(TAG) { "${service.id} sign-in ended: $answer" }
                    return null
                }
                val session = signIn.session(answer.token)
                if (replaced == null) {
                    val account = signIn.account(session)
                    return commit(profileId, service, session.copy(username = account?.username), expected = null, keepQueuedWrites = false)
                }
                val (fresh, previous) = coroutineScope {
                    val freshLookup = async { signIn.account(session) }
                    val previousLookup = async { signIn.account(replaced.session) }
                    freshLookup.await() to previousLookup.await()
                }
                val sameAccount = fresh?.id != null && fresh.id == previous?.id
                if (!sameAccount) Log.i(TAG) { "${service.id}: the reconnected account differs or is unknown, dropping its queued writes" }
                return commit(profileId, service, session.copy(username = fresh?.username), replaced.connectedAt, sameAccount)
            }
            is TrackerSignIn.Relay -> {
                val relay = relay ?: throw TrackerException.SignIn(service, "no OAuth relay configured")
                val start = relay.start(service)
                prompt(SignInPrompt.Link(start))
                val result = relay.poll(service, start.session) ?: run {
                    Log.i(TAG) { "${service.id} sign-in declined" }
                    return null
                }
                return commit(profileId, service, signIn.session(result), expected = null, keepQueuedWrites = false)
            }
        }
    }

    /**
     * Keeps [session] when the sign-in is still current: not cancelled, and the service's connection still the one it
     * started from ([expected], `null` for none). Otherwise nothing is kept and the answer is `null`.
     */
    private suspend fun commit(
        profileId: String,
        service: TrackerService,
        session: TrackerSession,
        expected: Long?,
        keepQueuedWrites: Boolean,
    ): TrackerAccount? {
        val account = mutations.withLock {
            currentCoroutineContext().ensureActive()
            if (repository.account(profileId, service)?.connectedAt != expected) {
                Log.i(TAG) { "${service.id} sign-in overtaken by another connection, not kept" }
                return null
            }
            // Past this point the sign-in completes whole: its session and its connection row go together.
            withContext(NonCancellable) { keep(profileId, service, session, keepQueuedWrites) }
        }
        Log.i(TAG) { "${service.id} connected" }
        onConnected(profileId)
        return account
    }

    /** Keeps [session] as a new binding of the profile's [service]. Call with [mutations] held. */
    private suspend fun keep(profileId: String, service: TrackerService, session: TrackerSession, keepQueuedWrites: Boolean): TrackerAccount {
        val scope = profileUserScope(profileId)
        // A new binding, even for a sign-in within the same millisecond as the one it replaces.
        val previous = repository.account(profileId, service)?.connectedAt
        val connectedAt = maxOf(clock.now().toEpochMilliseconds(), (previous ?: 0) + 1)
        // The session first: a connection row never exists without it.
        tokens.save(scope, service, StoredSession(connectedAt, session))
        bindings.remove(scope to service)?.let { (it.credentials as AccountCredentials).gone = true }
        return repository.connect(profileId, service, session.username, connectedAt, keepQueuedWrites)
    }

    private suspend fun isLegacy(profileId: String, account: TrackerAccount): Boolean {
        val provider = providers[account.service] ?: return false
        val stored = try {
            tokens.load(profileUserScope(profileId), account.service)
        } catch (e: TrackerException.SecretStore) {
            Log.w(TAG) { "${account.service.id} session unreadable, not offering a reconnect" }
            return false
        }
        return stored != null && stored.connectedAt == account.connectedAt && provider.isLegacy(stored.session)
    }

    /**
     * [account]'s binding: the one made for its sign-in (whose session the store failed to keep is kept first), or a
     * new one with its session loaded. `null` without a usable session: a connection whose session is missing, another
     * sign-in's or can't renew ([TrackerTokenStore.load]) is dropped with its queued writes, and one whose session the
     * store can't read for now is left out until the next look.
     */
    private suspend fun hydrate(profileId: String, account: TrackerAccount): TrackerBinding? {
        val provider = providers[account.service] ?: return null
        val scope = profileUserScope(profileId)
        val key = scope to account.service
        val binding = mutations.withLock {
            bindings[key]?.takeIf { it.connectedAt == account.connectedAt }?.let { return@withLock it }
            val stored = try {
                tokens.load(scope, account.service)
            } catch (e: TrackerException.SecretStore) {
                Log.w(TAG) { "${account.service.id} session unreadable, not connected for now" }
                return@withLock null
            }
            if (stored == null || stored.connectedAt != account.connectedAt) {
                // Its session, if another sign-in's, goes with it ([clearUnusedTokens]).
                if (repository.disconnect(profileId, account.service, account.connectedAt)) {
                    Log.w(TAG) { "${account.service.id} has no usable session on this device, disconnected" }
                }
                return@withLock null
            }
            val credentials = AccountCredentials(scope, account.service, account.connectedAt, stored.session, provider.refresher)
            TrackerBinding(account, provider, credentials).also { bindings[key] = it }
        } ?: return null
        (binding.credentials as AccountCredentials).keepUnsaved()
        return binding
    }

    private fun nowSeconds(): Long = clock.now().epochSeconds

    private inner class AccountCredentials(
        private val scope: String,
        override val service: TrackerService,
        private val connectedAt: Long,
        /** The sign-in's session, loaded before the binding was published. */
        private var session: TrackerSession,
        private val refresher: TokenRefresher?,
    ) : TrackerCredentials {
        /** One refresh at a time for this connection; also guards [session] and [unsaved]. */
        private val refreshing = Mutex()

        /** [session] was refreshed but the store failed to keep it: kept before the next use or look-up ([keepUnsaved]). */
        private var unsaved = false

        /** The sign-in ended: signed out, reconnected, or its session found dead. */
        var gone = false

        override suspend fun accessToken(): String = refreshing.withLock {
            val held = held()
            if (refresher == null || !held.needsRefresh(nowSeconds())) return@withLock held.accessToken
            try {
                refresh(held, refresher)
            } catch (e: TrackerException) {
                if (e is TrackerException.Auth && e.permanent) {
                    drop()
                    throw e
                }
                // A token that hasn't expired still works; the request's own 401 decides.
                if (held.expired(nowSeconds())) throw e
                Log.d(TAG) { "${service.id} token not renewed (${e.message}), using the one held" }
                held.accessToken
            }
        }

        override suspend fun refreshAfterUnauthorized(rejected: String): String = refreshing.withLock {
            val held = held()
            // Another caller refreshed while this one waited: its token is the answer, and refreshing with the old
            // refresh token again would spend it twice.
            if (held.accessToken != rejected) return@withLock held.accessToken
            if (refresher == null) {
                drop()
                throw TrackerException.Auth(service, "session rejected", status = 401, permanent = true)
            }
            try {
                refresh(held, refresher)
            } catch (e: TrackerException.Auth) {
                if (e.permanent) drop()
                throw e
            }
        }

        override suspend fun invalidate(rejected: String) {
            refreshing.withLock {
                if (!gone && held().accessToken == rejected) drop()
            }
        }

        /** [held] refreshed at the service, kept (see [persist]) before it is returned. Call with [refreshing] held. */
        private suspend fun refresh(held: TrackerSession, refresher: TokenRefresher): String {
            val next = refresher.refresh(held)
            // Held at once: a rotated refresh token is spent, so the next refresh needs this one even if keeping it fails.
            session = next
            persist()
            Log.d(TAG) { "${service.id} token refreshed" }
            return next.accessToken
        }

        /**
         * Keeps [session] in the store unless the sign-in ended (it was replaced or signed out). A store failure leaves
         * it [unsaved]: the session still serves, and keeping it is tried again before its next use. Call with
         * [refreshing] held.
         */
        private suspend fun persist() {
            mutations.withLock {
                unsaved = false
                if (repository.account(scope, service)?.connectedAt != connectedAt) return
                try {
                    tokens.save(scope, service, StoredSession(connectedAt, session))
                } catch (e: TrackerException.SecretStore) {
                    unsaved = true
                    Log.w(TAG) { "${service.id} refreshed session not kept, held until it can be" }
                }
            }
        }

        /** Keeps a refreshed session the store failed to keep; nothing when there is none. */
        suspend fun keepUnsaved() {
            if (!unsaved) return
            refreshing.withLock { if (unsaved && !gone) persist() }
        }

        /**
         * The session held for this sign-in, kept first when the store failed to. Call with [refreshing] held; throws
         * once the sign-in ended.
         */
        private suspend fun held(): TrackerSession {
            if (gone) throw TrackerException.Auth(service, "disconnected", permanent = true)
            if (unsaved) persist()
            return session
        }

        /** The session is dead: drop this sign-in (unless a newer one replaced it). Call with [refreshing] held. */
        private suspend fun drop() {
            gone = true
            unsaved = false
            mutations.withLock {
                if (repository.disconnect(scope, service, connectedAt)) {
                    tokens.clear(scope, service)
                    Log.w(TAG) { "${service.id} session dead, disconnected" }
                }
                val key = scope to service
                if (bindings[key]?.credentials === this) bindings.remove(key)
            }
        }
    }

    private companion object {
        const val TAG = "trackers"
    }
}

/** A connection and the tracker bound to its sign-in. */
internal class BoundTracker(val account: TrackerAccount, val tracker: Tracker) {
    val service: TrackerService get() = account.service
}
