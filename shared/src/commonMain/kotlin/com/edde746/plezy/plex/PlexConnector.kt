package com.edde746.plezy.plex

import com.edde746.plezy.servers.PlexClientEvents
import com.edde746.plezy.servers.PlexConnector
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.PlexServerClient
import com.edde746.plezy.servers.PlexServerEntry
import com.edde746.plezy.servers.RacedEndpoint
import io.ktor.client.HttpClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

/**
 * The Plex side of the server manager: endpoint races over a server's published connections, clients that identify as
 * this app ([appVersion], [platform], [device], [deviceName], the current [languageCode]) and run their background work
 * in [scope] (the app's main thread), and plex.tv server-list refreshes through [refreshServers].
 */
class PlexPlatformConnector(
    private val httpClient: HttpClient,
    private val cache: PlexApiCache,
    private val scope: CoroutineScope,
    private val environment: PlexClientEnvironment,
    private val appVersion: String,
    private val platform: String,
    private val device: String?,
    private val deviceName: String?,
    private val languageCode: () -> String?,
    private val refreshServers: suspend (accountId: String) -> Unit,
) : PlexConnector {
    /** The first endpoint carries what its probe read from the root; later, better ones carry nothing. */
    override fun raceEndpoints(server: PlexServerEntry, preferredUrl: String?, clientIdentifier: String?): Flow<RacedEndpoint> = flow {
        var root: ConnectionTestResult? = null
        var first = true
        plexServer(server).findBestWorkingConnection(
            httpClient,
            preferredUri = preferredUrl,
            clientIdentifier = clientIdentifier,
            deviceName = deviceName,
            onFirstSuccess = { root = it },
        ).collect { connection ->
            emit(if (first) RacedEndpoint(connection.uri, root?.transcoderVideo, root?.allowMediaDeletion) else RacedEndpoint(connection.uri))
            first = false
        }
    }

    override suspend fun createClient(
        server: PlexServerEntry,
        endpoint: RacedEndpoint,
        failoverEndpoints: List<String>,
        clientIdentifier: String,
        profileScopeId: PlexProfileScopeId,
        events: PlexClientEvents,
    ): PlexServerClient = PlexClient.create(
        config = PlexConfig(
            baseUrl = endpoint.url,
            token = server.accessToken,
            clientIdentifier = clientIdentifier,
            version = appVersion,
            platform = platform,
            device = device,
            deviceName = deviceName,
            machineIdentifier = server.serverId.value,
            languageCode = languageCode(),
        ),
        serverId = server.serverId,
        profileScopeId = profileScopeId,
        serverName = server.name,
        httpClient = httpClient,
        cache = cache,
        appScope = scope,
        environment = environment,
        prioritizedEndpoints = failoverEndpoints,
        events = events,
        seedTranscoderVideo = endpoint.transcoderVideo,
        seedAllowMediaDeletion = endpoint.allowMediaDeletion,
    )

    override suspend fun refreshServerList(accountId: String) = refreshServers(accountId)

    private fun plexServer(server: PlexServerEntry): PlexServer =
        server as? PlexServer ?: throw IllegalArgumentException("Not a Plex server entry: ${server::class.simpleName}")
}
