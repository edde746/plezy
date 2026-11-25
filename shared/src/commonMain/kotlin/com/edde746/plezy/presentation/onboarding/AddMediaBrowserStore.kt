package com.edde746.plezy.presentation.onboarding

import com.edde746.plezy.backend.MediaServerAuthException
import com.edde746.plezy.backend.MediaServerUrlException
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.jellyfin.DiscoveredJellyfinServer
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.jellyfin.JellyfinEndpointDiscovery
import com.edde746.plezy.jellyfin.JellyfinEndpointRaceResult
import com.edde746.plezy.jellyfin.JellyfinLanDiscovery
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.MediaBrowserAddResult
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileServices
import com.edde746.plezy.profiles.mediaBrowser
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** The server a probe found: its name and version line ("Jellyfin 10.10.7"). */
data class FoundServer(val name: String, val version: String)

/**
 * The Jellyfin/Emby add form ([Route.AddMediaBrowser]). Before a probe: the URL field ([urls]), the servers on the
 * LAN ([discovering] while the 1.3 s broadcast runs, then [localServers], those already added to the app by id in
 * [addedServerIds]) and Find server. After it: the server's card
 * ([server], Change), username and password, Sign in, and Use Quick Connect when the server has it. While Quick Connect
 * waits, [quickConnectCode] replaces the form, with Cancel. [busy] disables the form; [error] shows under it.
 * [focusUsername] / [focusPassword] / [focusCancel] count up when the UI should move focus there (after a probe: the
 * password when signing in again with the user known; Quick Connect's code).
 */
data class AddMediaBrowserUiState(
    val title: String,
    val dialect: MediaBrowserDialect,
    val urls: String = "",
    val discovering: Boolean = true,
    val localServers: List<DiscoveredJellyfinServer> = emptyList(),
    val addedServerIds: Set<String> = emptySet(),
    val server: FoundServer? = null,
    val username: String = "",
    val password: String = "",
    val quickConnectAvailable: Boolean = false,
    val quickConnectCode: String? = null,
    val busy: Boolean = false,
    val error: String? = null,
    val urlRequired: Boolean = false,
    val usernameRequired: Boolean = false,
    val focusUsername: Int = 0,
    val focusPassword: Int = 0,
    val focusCancel: Int = 0,
)

/**
 * Adds a Jellyfin or Emby user: probes the URLs typed (every candidate a host expands to, raced; the reachable one
 * with the lowest latency active), signs in by password or Quick Connect, then stores the connection for the target
 * profile, else the active one, else (first run) a new local profile named after the user. On TV a server with Quick
 * Connect starts it right after the probe. Signing in again ([Route.AddMediaBrowser.url]): the expired server's address
 * and user are filled in and probed at once, without a LAN search, so only the password is left.
 */
class AddMediaBrowserStore(
    private val route: Route.AddMediaBrowser,
    private val profiles: ProfileServices,
    private val connections: ConnectionStore,
    private val host: AccountsHost,
    parentScope: CoroutineScope,
    private val discoverLan: suspend (MediaBrowserDialect) -> List<DiscoveredJellyfinServer> = {
        JellyfinLanDiscovery.discover(it, responseWindowMillis = LAN_WINDOW_MILLIS)
    },
) {
    private val scope = parentScope.childScope()
    private val dialect = route.dialect
    private val mutableState = MutableStateFlow(
        AddMediaBrowserUiState(
            if (route.url != null) T.connections.signInAgain else T.addServer.addMediaBrowserTitle(dialect.productName),
            dialect,
            urls = route.url.orEmpty(),
            username = route.username.orEmpty(),
            discovering = route.url == null,
        ),
    )
    private var endpoint: JellyfinEndpointRaceResult? = null
    private var work: Job? = null
    private var quickConnect: Job? = null

    val state: StateFlow<AddMediaBrowserUiState> = mutableState.asStateFlow()

    init {
        if (route.url != null) findServer() else scope.launch { discover() }
    }

    fun setUrls(text: String) {
        val s = mutableState.value
        if (s.busy) return
        mutableState.value = if (s.server != null) cleared(s).copy(urls = text) else s.copy(urls = text, urlRequired = false)
    }

    fun setUsername(text: String) {
        mutableState.value = mutableState.value.copy(username = text, usernameRequired = false)
    }

    fun setPassword(text: String) {
        mutableState.value = mutableState.value.copy(password = text)
    }

    /** Puts [server]'s address in the field and probes it. */
    fun useLocalServer(server: DiscoveredJellyfinServer) {
        if (mutableState.value.busy) return
        mutableState.value = cleared(mutableState.value).copy(urls = server.address)
        findServer()
    }

    /** Back to editing the URLs. */
    fun changeServer() {
        if (mutableState.value.busy) return
        mutableState.value = cleared(mutableState.value)
    }

    /** Probes the URLs typed. */
    fun findServer() {
        val s = mutableState.value
        if (s.busy) return
        val entered = JellyfinEndpointDiscovery.parseUserEnteredUrls(s.urls)
        if (entered.isEmpty()) {
            mutableState.value = s.copy(urlRequired = true)
            return
        }
        val input = JellyfinEndpointDiscovery.buildUserInputCandidates(entered, dialect)
        if (input.isEmpty) {
            mutableState.value = s.copy(error = T.addServer.enterMediaBrowserUrlError(dialect.productName))
            return
        }
        run(errorText = { e ->
            (e as? MediaServerUrlException)?.display ?: T.addServer.couldNotReachServer(localizedErrorReason(e))
        }) {
            val auth = profiles.jellyfinAuth(dialect)
            val raced = auth.raceUserInput(input)
            val serverDialect = raced.serverInfo.dialect ?: dialect
            val quick = dialect.supportsQuickConnect && serverDialect.supportsQuickConnect && auth.isQuickConnectEnabled(raced.activeBaseUrl)
            endpoint = raced
            val now = mutableState.value
            val toPassword = route.url != null && now.username.isNotEmpty()
            mutableState.value = now.copy(
                urls = raced.baseUrls.joinToString("\n"),
                server = FoundServer(raced.serverInfo.serverName, "${dialect.productName} ${raced.serverInfo.version}"),
                quickConnectAvailable = quick,
                focusUsername = if ((quick && host.tv) || toPassword) now.focusUsername else now.focusUsername + 1,
                focusPassword = if (toPassword && !(quick && host.tv)) now.focusPassword + 1 else now.focusPassword,
            )
            if (quick && host.tv) startQuickConnectNow()
        }
    }

    /** Signs in by username and password (an empty password is allowed). */
    fun signIn() {
        val s = mutableState.value
        if (s.busy) return
        val raced = endpoint ?: return findServer()
        if (s.username.isBlank()) {
            mutableState.value = s.copy(usernameRequired = true)
            return
        }
        run(errorText = { e ->
            (e as? MediaServerAuthException)?.display ?: T.addServer.signInFailed(localizedErrorReason(e))
        }) {
            val connection = profiles.jellyfinAuth(dialect).authenticateByName(
                raced.activeBaseUrl,
                s.username,
                s.password,
                baseUrls = raced.baseUrls,
                serverInfo = raced.serverInfo,
            )
            persist(connection)
        }
    }

    fun startQuickConnect() {
        if (mutableState.value.busy || endpoint == null) return
        run(errorText = ::quickConnectError) { startQuickConnectNow() }
    }

    /** Stops waiting for Quick Connect's approval; the form shows again. */
    fun cancelQuickConnect() {
        quickConnect?.cancel()
        quickConnect = null
        mutableState.value = mutableState.value.copy(quickConnectCode = null, busy = false)
    }

    fun close() = scope.cancel()

    private suspend fun startQuickConnectNow() {
        val raced = endpoint ?: return
        val auth = profiles.jellyfinAuth(dialect)
        val initiation = auth.initiateQuickConnect(raced.activeBaseUrl)
        mutableState.value = mutableState.value.copy(
            quickConnectCode = initiation.code,
            busy = false,
            focusCancel = mutableState.value.focusCancel + 1,
        )
        quickConnect = scope.launch {
            try {
                val connection = auth.authenticateByQuickConnect(
                    raced.activeBaseUrl,
                    initiation.secret,
                    baseUrls = raced.baseUrls,
                    serverInfo = raced.serverInfo,
                )
                if (connection == null) {
                    mutableState.value = mutableState.value.copy(quickConnectCode = null, error = T.auth.quickConnectExpired)
                    return@launch
                }
                mutableState.value = mutableState.value.copy(busy = true)
                persist(connection)
                mutableState.value = mutableState.value.copy(busy = false)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Quick Connect failed" }
                mutableState.value = mutableState.value.copy(quickConnectCode = null, busy = false, error = quickConnectError(e))
            }
        }
    }

    private fun quickConnectError(e: Exception): String =
        (e as? MediaServerAuthException)?.display ?: T.addServer.quickConnectFailed(localizedErrorReason(e))

    /** Stores [connection] for the profile it belongs to; the flow closes once it's bound. */
    private suspend fun persist(connection: JellyfinConnection) {
        val target: Profile? = route.profileId?.let { id -> profiles.profiles.value.firstOrNull { it.id == id } }
        var result = profiles.addMediaBrowserConnection(connection, target)
        if (result == MediaBrowserAddResult.PickProfile) {
            if (!host.pickProfile()) {
                mutableState.value = mutableState.value.copy(error = T.messages.noProfilesAvailable)
                return
            }
            result = profiles.addMediaBrowserConnection(connection, target)
        }
        if (result is MediaBrowserAddResult.Added) host.connectionAdded(route, pickProfile = false)
        else mutableState.value = mutableState.value.copy(error = T.messages.noProfilesAvailable)
    }

    /** Runs [block] with the form busy; a failure shows as [errorText] of it. */
    private fun run(errorText: (Exception) -> String, block: suspend () -> Unit) {
        mutableState.value = mutableState.value.copy(busy = true, error = null)
        work = scope.launch {
            try {
                block()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Adding a ${dialect.productName} server failed" }
                mutableState.value = mutableState.value.copy(quickConnectCode = null, error = errorText(e))
            }
            if (mutableState.value.quickConnectCode == null) mutableState.value = mutableState.value.copy(busy = false)
        }
    }

    /** The stored servers of this dialect first, then the LAN's, one per machine. */
    private suspend fun discover() {
        val stored = try {
            connections.list().mapNotNull { it.mediaBrowser() }.filter { it.dialect == dialect }.map {
                DiscoveredJellyfinServer(it.baseUrl, it.serverMachineId, it.serverName, it.dialect)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Reading the stored servers failed" }
            emptyList()
        }
        val lan = discoverLan(dialect)
        val seen = HashSet<String>()
        val servers = JellyfinLanDiscovery.sort((stored + lan).filter { seen.add(it.id) })
        mutableState.value = mutableState.value.copy(discovering = false, localServers = servers, addedServerIds = stored.mapTo(HashSet()) { it.id })
    }

    private fun cleared(s: AddMediaBrowserUiState): AddMediaBrowserUiState {
        endpoint = null
        return s.copy(server = null, quickConnectAvailable = false, error = null)
    }

    private companion object {
        const val TAG = "AddMediaBrowser"
        const val LAN_WINDOW_MILLIS = 1_300L
    }
}
