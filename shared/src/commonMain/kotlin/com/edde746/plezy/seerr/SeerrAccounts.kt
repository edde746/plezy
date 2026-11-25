package com.edde746.plezy.seerr

import com.edde746.plezy.log.Log
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.secrets.SecretStore
import io.ktor.client.HttpClient
import kotlin.concurrent.Volatile
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * The active profile's Seerr account: its stored session and the [SeerrClient] bound to it.
 *
 * [onActiveProfileChanged] loads the profile's session, binds a new client and re-reads the user's permissions (a
 * stored session's mask dates from its sign-in). The connect flow signs in through [auth] itself and hands the
 * finished session to [adoptSession]. A client's own changes (a new cookie, a changed permission mask or product) are
 * kept as they happen; a client whose re-auth the server refused unbinds and forgets the session.
 *
 * Each bind, adoption, disconnect, unlink or forgotten scope ([forgetScopes]) starts a new binding: an older binding's
 * late load, refresh or save changes nothing. Everything runs on one dispatcher that runs a coroutine at a time, shared
 * with the clients.
 *
 * @param http the app's client.
 * @param scope where the background work runs: the refresh after a bind, the saves of a client's changes.
 * @param plexToken the active profile's Plex token (its Home user's own, else the account's), for Plex sign-in and
 *   re-auth; null when there is none right now.
 * @param language the app's interface language as Seerr's `language` parameter ([SeerrClient]).
 * @param dispatcher where the account and its clients run, one coroutine at a time.
 */
class SeerrAccounts(
    http: HttpClient,
    secrets: SecretStore,
    private val scope: CoroutineScope,
    private val plexToken: suspend () -> String?,
    private val language: () -> String,
    clock: Clock = Clock.System,
    dispatcher: CoroutineDispatcher = Dispatchers.Default,
) {
    /** Probing and signing in, for the connect flow. */
    val auth = SeerrAuthService(http, clock)

    private val store = SeerrSessionStore(secrets)
    private val serial = dispatcher.limitedParallelism(1)
    private val userRefresh = SerialCoalescer<Unit>()

    private val sessionState = MutableStateFlow<SeerrSession?>(null)
    private val clientState = MutableStateFlow<SeerrClient?>(null)

    /** The active profile's session; null when it has none. */
    val session: StateFlow<SeerrSession?> = sessionState.asStateFlow()

    /** The client for the catalog and request surfaces: a new one for each binding, null when disconnected. */
    val client: StateFlow<SeerrClient?> = clientState.asStateFlow()

    /**
     * The signed-in user's permission mask, null when disconnected. Changes are taken in place (the refresh after a
     * bind, a re-auth, a denied request's `/auth/me` read) without a new client, so request surfaces gate on this.
     */
    val permissions: Flow<Int?> = sessionState.map { it?.permissions }.distinctUntilChanged()

    private var activeProfileId: String? = null
    private var binding = 0

    @Volatile
    private var closed = false

    /** The token "Sign in with Plex" uses, the one a Plex re-auth would; null when there is none (or it failed). */
    suspend fun resolvePlexToken(): String? = try {
        plexToken()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Plex token resolution failed" }
        null
    }

    /**
     * Binds [profileId]'s stored session (none: null), then re-reads its user in the background.
     *
     * @throws Exception the secret store's failure to read the session.
     */
    suspend fun onActiveProfileChanged(profileId: String?) {
        withContext(serial) {
            if (closed) return@withContext
            val generation = ++binding
            activeProfileId = profileId
            rebind(profileId, generation, null)
            if (profileId == null) return@withContext
            val loaded = store.load(profileId)
            rebind(profileId, generation, loaded)
            if (isCurrent(profileId, generation)) {
                scope.launch(serial, CoroutineStart.UNDISPATCHED) { refreshUser() }
            }
        }
    }

    /**
     * Re-reads the bound user and takes a changed permission mask or display name. Best effort: while the instance
     * can't be reached the session goes on with its snapshot; a refused cookie re-auths or unlinks through the client.
     * Concurrent calls share one read.
     */
    suspend fun refreshUser() {
        withContext(serial) {
            userRefresh.run {
                val client = clientState.value
                if (!closed && client != null) {
                    try {
                        client.refreshUser()
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.w(TAG, e) { "user refresh failed" }
                    }
                }
            }
        }
    }

    /**
     * Keeps and binds a session the connect flow signed in, as the active profile's (its [SeerrSession.instanceLabel]
     * and [SeerrSession.product] filled from the probe's settings). The old client is retired first, so its late
     * changes can't be saved after this one.
     *
     * @throws IllegalStateException when no profile is active.
     * @throws Exception the secret store's failure to keep the session; nothing is bound then.
     */
    suspend fun adoptSession(session: SeerrSession) {
        withContext(serial) {
            if (closed) return@withContext
            val profileId = checkNotNull(activeProfileId) { "No active profile to keep a Seerr session for" }
            val generation = ++binding
            rebind(profileId, generation, null)
            store.save(profileId, session)
            rebind(profileId, generation, session)
        }
    }

    /**
     * Forgets the active profile's session: unbinds it, clears it from the secret store, then signs out at the
     * instance (best effort).
     */
    suspend fun disconnect() {
        withContext(serial) {
            if (closed) return@withContext
            val profileId = activeProfileId ?: return@withContext
            val session = sessionState.value
            val generation = ++binding
            rebind(profileId, generation, null)
            store.clear(profileId)
            if (session != null) auth.signOut(session)
        }
    }

    /**
     * Forgets the sessions of the profile [scopes] ([profileUserScope]) a removal took: the active profile's binding
     * ends first when its scope is among them, so no late change of its client keeps the session again, then the
     * scopes' sessions leave the secret store. No sign-out at the instance.
     *
     * @throws Exception the secret store's failure to delete a session.
     */
    suspend fun forgetScopes(scopes: Set<String>) {
        withContext(serial) {
            val active = activeProfileId
            if (!closed && active != null && profileUserScope(active) in scopes) rebind(active, ++binding, null)
            for (scope in scopes) store.clearScope(scope)
        }
    }

    /** Ends the account store: its client is disposed and nothing it started changes state any more. */
    fun close() {
        closed = true
        clientState.value?.dispose()
        clientState.value = null
    }

    private fun rebind(profileId: String?, generation: Int, session: SeerrSession?) {
        if (!isCurrent(profileId, generation)) return
        userRefresh.reset()
        clientState.value?.dispose()
        clientState.value = session?.let { bind(checkNotNull(profileId), generation, it) }
        sessionState.value = session
    }

    private fun bind(profileId: String, generation: Int, session: SeerrSession) = SeerrClient(
        session,
        auth,
        serial,
        plexToken = plexToken,
        language = language,
        onSessionUpdated = { next -> sessionUpdated(profileId, generation, next) },
        onSessionInvalidated = { sessionInvalidated(profileId, generation) },
    )

    private fun isCurrent(profileId: String?, generation: Int): Boolean =
        !closed && profileId == activeProfileId && generation == binding

    /** Keeps a client's changed session; the save is queued at once, so it lands before any later store operation. */
    private fun sessionUpdated(profileId: String, generation: Int, session: SeerrSession) {
        if (!isCurrent(profileId, generation)) return
        sessionState.value = session
        persist("save") { store.save(profileId, session) }
    }

    /** A client's re-auth was refused, or it had nothing to sign in with: forget the session. */
    private fun sessionInvalidated(profileId: String, generation: Int) {
        if (!isCurrent(profileId, generation)) return
        val next = ++binding
        persist("clear") { store.clear(profileId) }
        rebind(profileId, next, null)
    }

    /** Runs [operation] in the background, starting here so it takes its place in the store's queue now. */
    private fun persist(what: String, operation: suspend () -> Unit) {
        scope.launch(serial, CoroutineStart.UNDISPATCHED) {
            try {
                operation()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Seerr session $what failed" }
            }
        }
    }

    private companion object {
        const val TAG = "seerr"
    }
}
