@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.servers

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.testTimeSource
import kotlin.coroutines.ContinuationInterceptor

fun localEndpoint(label: String) = "https://$label.invalid:32400"

fun remoteEndpoint(label: String) = "https://$label-wan.invalid:32400"

fun relayEndpoint(label: String) = "https://$label.invalid:8443"

/**
 * A Plex server whose endpoints are [connections] (URL to class). Each race takes the next of [races], the last one
 * repeating; no races: every race finds nothing.
 */
class FakePlexServer(
    id: String,
    private val connections: Map<String, EndpointNetworkClass>,
    private val races: List<() -> Flow<RacedEndpoint>> = emptyList(),
    override val accessToken: String = "token-$id",
    override val owned: Boolean = true,
) : PlexServerEntry {
    override val serverId = ServerId(id)
    override val name = id
    var raceCalls = 0
        private set

    override val publishesLocalDirectConnection: Boolean get() = EndpointNetworkClass.LOCAL in connections.values

    override fun networkClassForUrl(url: String): EndpointNetworkClass = connections[url] ?: EndpointNetworkClass.REMOTE

    override fun prioritizedEndpointUrls(preferredFirst: String): List<String> = listOf(preferredFirst) + (connections.keys - preferredFirst)

    fun race(): Flow<RacedEndpoint> {
        val index = raceCalls++
        if (races.isEmpty()) return emptyFlow()
        return races[index.coerceAtMost(races.size - 1)]()
    }
}

/** A race that answers [urls] in order, each probe reporting transcoder support. */
fun raceOf(vararg urls: String): () -> Flow<RacedEndpoint> = { flowOf(*urls.map { RacedEndpoint(it, transcoderVideo = true) }.toTypedArray()) }

class FakePlexAccount(
    override val accountId: String,
    override val servers: List<PlexServerEntry>,
    override val clientIdentifier: String = "test-client",
    override val accountToken: String = "account-token",
) : PlexAccountServers

class FakePlexClient(
    serverId: String,
    var scope: PlexProfileScopeId,
    override var baseUrl: String,
    override var token: String = "token",
) : FakeMediaBackend(serverId, BackendKind.PLEX),
    PlexServerClient {
    var endpoints: List<String> = emptyList()
    var language: String? = null
    var accountId: String? = null

    /** Commits by default: the new token and scope, a new authentication session. */
    var profileUpdate: suspend (token: String, scope: PlexProfileScopeId) -> Boolean = { newToken, newScope -> commit(newToken, newScope) }

    override val cacheServerId: String get() = scope.value

    fun commit(newToken: String, newScope: PlexProfileScopeId): Boolean {
        token = newToken
        scope = newScope
        authenticationSessionId = Any()
        return true
    }

    override suspend fun applyProfileUpdate(token: String, profileScopeId: PlexProfileScopeId): Boolean {
        calls += "applyProfileUpdate"
        return profileUpdate(token, profileScopeId)
    }

    override suspend fun updateEndpointPreferences(endpoints: List<String>, switchToFirst: Boolean) {
        this.endpoints = endpoints
        if (switchToFirst) baseUrl = endpoints.first()
    }

    override fun applyLanguage(languageCode: String) {
        language = languageCode
    }

    override fun bindAccount(accountId: String, accountToken: String) {
        this.accountId = accountId
    }
}

data class PlexCreateCall(
    val serverId: ServerId,
    val endpoint: RacedEndpoint,
    val failoverEndpoints: List<String>,
    val profileScopeId: PlexProfileScopeId,
    val events: PlexClientEvents,
)

/** Builds [FakePlexClient]s; races come from the [FakePlexServer]. */
class FakePlexConnector : PlexConnector {
    val calls = mutableListOf<PlexCreateCall>()
    val clients = LinkedHashMap<ServerId, FakePlexClient>()
    val serverListRefreshes = mutableListOf<String>()
    var failingServerIds: Set<ServerId> = emptySet()
    var createGate: CompletableDeferred<Unit>? = null

    /** Applied to each client right after it is built. */
    var configure: (FakePlexClient) -> Unit = {}

    override fun raceEndpoints(server: PlexServerEntry, preferredUrl: String?, clientIdentifier: String?): Flow<RacedEndpoint> =
        (server as FakePlexServer).race()

    override suspend fun createClient(
        server: PlexServerEntry,
        endpoint: RacedEndpoint,
        failoverEndpoints: List<String>,
        clientIdentifier: String,
        profileScopeId: PlexProfileScopeId,
        events: PlexClientEvents,
    ): PlexServerClient {
        calls += PlexCreateCall(server.serverId, endpoint, failoverEndpoints, profileScopeId, events)
        createGate?.await()
        if (server.serverId in failingServerIds) throw IllegalStateException("injected client creation failure")
        val client = FakePlexClient(server.serverId.value, profileScopeId, endpoint.url, server.accessToken)
        configure(client)
        clients[server.serverId] = client
        return client
    }

    override suspend fun refreshServerList(accountId: String) {
        serverListRefreshes += accountId
    }
}

class MemoryPreferredEndpoints : PreferredEndpointStore {
    val saved = HashMap<ServerId, String>()
    val writes = mutableListOf<Pair<ServerId, String>>()

    /** The dispatcher each write ran on. */
    val writeDispatchers = mutableListOf<ContinuationInterceptor?>()

    override suspend fun read(serverId: ServerId): String? = saved[serverId]

    override suspend fun save(serverId: ServerId, url: String) {
        saved[serverId] = url
        writes += serverId to url
        writeDispatchers += currentCoroutineContext()[ContinuationInterceptor]
    }

    override suspend fun clear(serverId: ServerId) {
        saved.remove(serverId)
    }
}

data class FakeMediaBrowserConnection(
    val machineId: String,
    val userId: String,
    override val isAdministrator: Boolean = false,
    val accessToken: String = "token-$userId",
    override val serverName: String = "Shared JF",
) : MediaBrowserConnection {
    override val id: String get() = mediaBrowserScopeId(serverId, userId)
    override val serverId: ServerId get() = ServerId(machineId)
}

class FakeMediaBrowserClient(
    override var connection: MediaBrowserConnection,
    val events: MediaBrowserClientEvents,
) : FakeMediaBackend(connection.serverId.value, BackendKind.JELLYFIN, scopeId = connection.id),
    MediaBrowserServerClient

/** Builds [FakeMediaBrowserClient]s; reuse is "same access token". */
class FakeMediaBrowserConnector : MediaBrowserConnector {
    val clients = mutableListOf<FakeMediaBrowserClient>()
    val persisted = mutableListOf<MediaBrowserConnection>()
    var persist: suspend (MediaBrowserConnection) -> Unit = { persisted += it }

    /** Applied to each client right after it is built. */
    var configure: (FakeMediaBrowserClient) -> Unit = {}

    override fun canReuse(live: MediaBrowserConnection, incoming: MediaBrowserConnection): Boolean =
        (live as FakeMediaBrowserConnection).accessToken == (incoming as FakeMediaBrowserConnection).accessToken

    override suspend fun createClient(connection: MediaBrowserConnection, events: MediaBrowserClientEvents): MediaBrowserServerClient =
        FakeMediaBrowserClient(connection, events).also {
            configure(it)
            clients += it
        }

    override suspend fun persistConnection(connection: MediaBrowserConnection) = persist(connection)

    fun client(connectionId: String): FakeMediaBrowserClient = clients.last { it.connection.id == connectionId }
}

/** A manager over fakes, its work in [scope]'s scheduler. */
class ManagerHarness(scope: TestScope, val workScope: CoroutineScope = scope.backgroundScope) {
    val plex = FakePlexConnector()
    val mediaBrowser = FakeMediaBrowserConnector()
    val endpoints = MemoryPreferredEndpoints()
    val connectivity = MutableSharedFlow<Connectivity>(extraBufferCapacity = 16)
    val manager = MultiServerManager(
        plexConnector = plex,
        mediaBrowserConnector = mediaBrowser,
        preferredEndpoints = endpoints,
        connectivityChanges = connectivity,
        scope = workScope,
        resumeProbeCooldown = MultiServerManager.RESUME_PROBE_COOLDOWN_MOBILE,
        timeSource = scope.testTimeSource,
    )

    /** Adds a Jellyfin user whose health probe answers [health]. */
    suspend fun addJellyfin(
        userId: String,
        machineId: String = "jf-machine",
        health: HealthStatus = HealthStatus.ONLINE,
        accessToken: String = "token-$userId",
    ): FakeMediaBrowserClient {
        val previous = mediaBrowser.configure
        mediaBrowser.configure = { it.health = { health } }
        manager.addMediaBrowserConnection(FakeMediaBrowserConnection(machineId, userId, accessToken = accessToken))
        mediaBrowser.configure = previous
        return mediaBrowser.client(mediaBrowserScopeId(ServerId(machineId), userId))
    }
}
