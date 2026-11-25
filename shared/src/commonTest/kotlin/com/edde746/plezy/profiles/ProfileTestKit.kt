package com.edde746.plezy.profiles

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.jellyfin.JellyfinAuthService
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.jellyfin.JellyfinDeviceIdentity
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.resolve.FakeHttp
import com.edde746.plezy.plex.PlexServer
import com.edde746.plezy.plex.tv.PlexAccountConnection
import com.edde746.plezy.plex.tv.PlexAuthService
import com.edde746.plezy.plex.tv.jsonResponse
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.seerr.SeerrAccounts
import com.edde746.plezy.servers.FakeMediaBrowserClient
import com.edde746.plezy.servers.FakePlexClient
import com.edde746.plezy.servers.MediaBrowserClientEvents
import com.edde746.plezy.servers.MediaBrowserConnection
import com.edde746.plezy.servers.MediaBrowserConnector
import com.edde746.plezy.servers.MediaBrowserServerClient
import com.edde746.plezy.servers.MemoryPreferredEndpoints
import com.edde746.plezy.servers.MultiServerManager
import com.edde746.plezy.servers.MultiServerStore
import com.edde746.plezy.servers.PlexClientEvents
import com.edde746.plezy.servers.PlexConnector
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.PlexServerClient
import com.edde746.plezy.servers.PlexServerEntry
import com.edde746.plezy.servers.RacedEndpoint
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.testTimeSource
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Instant

/** A Plex server as plex.tv's resources list it, one LAN connection. */
internal fun serverJson(id: String = "srv-1", accessToken: String = "server-token", owned: Boolean = true) =
    """{"name":"$id","clientIdentifier":"$id","accessToken":"$accessToken","owned":$owned,"provides":"server",""" +
        """"connections":[{"protocol":"https","address":"192.168.1.3","port":32400,"uri":"https://$id.plex.direct:32400",""" +
        """"local":true,"relay":false,"IPv6":false}]}"""

internal fun plexServer(id: String = "srv-1", accessToken: String = "server-token") =
    PlexServer.fromJson(Json.parseToJsonElement(serverJson(id, accessToken)).jsonObject)

internal fun resources(vararg servers: String) = "[${servers.joinToString(",")}]"

internal fun plexAccount(id: String = "plex.account", token: String = "account-token", servers: List<PlexServer> = listOf(plexServer())) =
    PlexAccountConnection(id, token, "client-id", "Owner", servers = servers, createdAt = 1_000)

internal fun homeUser(uuid: String = "aaaaaaaaaaaaaaaa", protected: Boolean = false, title: String = "Home User") =
    PlexHomeUser(id = 1, uuid = uuid, title = title, thumb = "", protected = protected, admin = true)

internal fun jellyfin(userId: String = "user-a", machineId: String = "jf-machine", token: String = "jf-token-$userId") = JellyfinConnection(
    id = "$machineId/$userId",
    baseUrl = "https://jellyfin.local",
    serverName = "Jellyfin",
    serverMachineId = machineId,
    userId = userId,
    userName = "User $userId",
    accessToken = token,
    deviceId = "device-id",
    createdAt = 1_000,
)

internal fun local(id: String, pin: String? = null, lastUsedAt: Long? = null) =
    LocalProfile(id, "Profile $id", pinHash = pin?.let(::computePinHash), createdAt = 1_000, lastUsedAt = lastUsedAt)

/**
 * Records each release as `delete <profile>` or `release <profile> <servers>`, marked when the profile's identity was
 * already gone ([present] says whether it's there); [failure] makes every call throw instead.
 */
internal class RecordingProfileDownloads(private val present: suspend (String) -> Boolean) : ProfileDownloads {
    val calls = mutableListOf<String>()
    var failure: Exception? = null

    override suspend fun deleteDownloadsForProfile(profileId: String) = record("delete $profileId", profileId)

    override suspend fun releaseDownloadsForProfileServers(profileId: String, serverIds: Set<String>) {
        if (serverIds.isNotEmpty()) record("release $profileId ${serverIds.sorted().joinToString(",")}", profileId)
    }

    private suspend fun record(call: String, profileId: String) {
        failure?.let { throw it }
        calls += if (present(profileId)) call else "$call after its identity went"
    }
}

/** Races a Plex server's first published URI; servers in [offline] answer on none. */
internal class ProfilePlexConnector : PlexConnector {
    val clients = LinkedHashMap<ServerId, FakePlexClient>()
    var created = 0
        private set
    var offline: Set<ServerId> = emptySet()

    override fun raceEndpoints(server: PlexServerEntry, preferredUrl: String?, clientIdentifier: String?): Flow<RacedEndpoint> =
        if (server.serverId in offline) emptyFlow() else flowOf(RacedEndpoint((server as PlexServer).connections.first().uri, transcoderVideo = true))

    override suspend fun createClient(
        server: PlexServerEntry,
        endpoint: RacedEndpoint,
        failoverEndpoints: List<String>,
        clientIdentifier: String,
        profileScopeId: PlexProfileScopeId,
        events: PlexClientEvents,
    ): PlexServerClient {
        created++
        return FakePlexClient(server.serverId.value, profileScopeId, endpoint.url, server.accessToken).also { clients[server.serverId] = it }
    }

    override suspend fun refreshServerList(accountId: String) = Unit
}

/** Jellyfin/Emby clients whose health is [health] by connection id (online by default), answered after [healthDelay]. */
internal class ProfileMediaBrowserConnector : MediaBrowserConnector {
    val health = HashMap<String, HealthStatus>()
    val healthDelay = HashMap<String, Duration>()

    override fun canReuse(live: MediaBrowserConnection, incoming: MediaBrowserConnection): Boolean = live == incoming

    override suspend fun createClient(connection: MediaBrowserConnection, events: MediaBrowserClientEvents): MediaBrowserServerClient =
        FakeMediaBrowserClient(connection, events).also { client ->
            client.health = {
                healthDelay[connection.id]?.let { delay(it) }
                health[connection.id] ?: HealthStatus.ONLINE
            }
        }

    override suspend fun persistConnection(connection: MediaBrowserConnection) = Unit
}

/**
 * The profile services over an in-memory database, a real server manager with fake connectors, and plex.tv answered
 * by [plexTv]. Everything runs on the test's scheduler.
 */
internal class ProfileHarness(val test: TestScope) {
    val clock = TestClock()
    val data = LocalData(inMemoryDatabase(), { clock.now }, StandardTestDispatcher(test.testScheduler))
    val secrets = MemorySecretStore()
    val connections = ConnectionStore(data, secrets)
    val bindings = ProfileConnectionRegistry(data, secrets)
    val identity = ProfileIdentity(data)
    val plex = ProfilePlexConnector()
    val mediaBrowser = ProfileMediaBrowserConnector()
    val manager = MultiServerManager(
        plexConnector = plex,
        mediaBrowserConnector = mediaBrowser,
        preferredEndpoints = MemoryPreferredEndpoints(),
        connectivityChanges = MutableSharedFlow(),
        scope = test.backgroundScope,
        resumeProbeCooldown = MultiServerManager.RESUME_PROBE_COOLDOWN_MOBILE,
        timeSource = test.testTimeSource,
    )
    val servers = MultiServerStore(manager, { emptyList() }, test.backgroundScope)

    /** plex.tv's answers; every request is in [requests]. */
    var plexTv: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData = { error("unexpected plex.tv request ${it.url}") }
    private val http = FakeHttp(test) { request -> plexTv(request) }
    val requests: List<HttpRequestData> get() = http.requests

    /** A Jellyfin/Emby server's answers to the sign-in ([ProfileServices.jellyfinAuth]). */
    var jellyfinServer: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData = { error("unexpected server request ${it.url}") }
    private val jellyfinHttp = FakeHttp(test) { request -> jellyfinServer(request) }

    /** Answers the PIN prompts in order; null cancels. */
    val prompts = mutableListOf<Pair<String, Boolean>>()
    var pins: MutableList<String?> = mutableListOf()
    val pinPrompt: ProfilePinPrompt = { profile, incorrect ->
        prompts += profile.id to incorrect
        if (pins.isEmpty()) null else pins.removeAt(0)
    }

    val services = ProfileServices(
        data,
        connections,
        bindings,
        identity,
        manager,
        servers,
        plexAuth = { PlexAuthService(http.client, "client-id", "1.0", "1", "Test") },
        jellyfinAuth = { dialect -> JellyfinAuthService(jellyfinHttp.client, JellyfinDeviceIdentity("Plezy Test", "Test", "1.0", "device-1"), dialect) },
        scope = test.backgroundScope,
        clock = object : Clock {
            override fun now(): Instant = Instant.fromEpochMilliseconds(clock.now)
        },
    )

    /** The downloads [removal] releases; a profile is present while it has a row or a binding. */
    val downloads = RecordingProfileDownloads { id -> data.profiles.list().any { it.id == id } || bindings.listForProfile(id).isNotEmpty() }

    /** The active profile's Seerr account, never online. */
    val seerr = SeerrAccounts(
        FakeHttp(test) { error("unexpected Seerr request ${it.url}") }.client,
        secrets,
        test.backgroundScope,
        plexToken = { null },
        language = { "en" },
        dispatcher = StandardTestDispatcher(test.testScheduler),
    )

    val removal = ProfileRemoval(services, data, downloads, seerr)

    fun requestsTo(pathSuffix: String): List<HttpRequestData> = requests.filter { it.url.encodedPath.endsWith(pathSuffix) }

    suspend fun store(account: PlexAccountConnection) = connections.upsert(account.stored())

    suspend fun store(connection: StoredConnection) = connections.upsert(connection)

    suspend fun store(connection: JellyfinConnection) = connections.upsert(connection.stored())

    suspend fun cacheHomeUsers(accountId: String, vararg users: PlexHomeUser) = identity.savePlexHomeUsers(accountId, users.toList())

    /** Starts the services and waits for the first bind. */
    suspend fun startAndSettle(): Boolean {
        services.start()
        services.bootRoute()
        return services.awaitBindingSettle()
    }

    suspend fun settled(): ProfileBindState = services.bindState.first { !it.binding }

    fun close() {
        services.close()
        data.close()
    }
}

/** Plex.tv routes: [switchToken] for `/switch` (null: 401), [resourcesBody] for `/resources`. */
internal fun MockRequestHandleScope.plexTvAnswer(request: HttpRequestData, switchToken: String? = null, resourcesBody: String = resources(serverJson())): HttpResponseData {
    val path = request.url.encodedPath
    return when {
        path.endsWith("/switch") -> if (switchToken == null) jsonResponse("""{"errors":[]}""", 401) else jsonResponse("""{"authToken":"$switchToken"}""", 201)
        path.endsWith("/resources") -> jsonResponse(resourcesBody)
        else -> error("unexpected plex.tv request ${request.url}")
    }
}

internal fun profileTest(body: suspend TestScope.(ProfileHarness) -> Unit) = runTest {
    val harness = ProfileHarness(this)
    try {
        body(harness)
    } finally {
        harness.close()
    }
}
