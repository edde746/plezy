package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.data.livetv.LiveTvFavoriteRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.servers.MediaBrowserClientEvents
import com.edde746.plezy.servers.MediaBrowserConnection
import com.edde746.plezy.servers.MediaBrowserConnector
import io.ktor.client.HttpClient
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope

/**
 * Builds Jellyfin and Emby clients for the server manager. [persist] stores a connection row (token encryption is the
 * store's).
 */
class JellyfinConnector(
    private val http: HttpClient,
    private val identity: (JellyfinConnection) -> JellyfinDeviceIdentity,
    private val cache: BackendCache,
    private val scope: CoroutineScope,
    private val favorites: LiveTvFavoriteRepository,
    private val persist: suspend (JellyfinConnection) -> Unit,
    private val codecs: () -> VideoCodecSupport = { VideoCodecSupport() },
    private val specialsOrdering: () -> SpecialsOrdering = { SpecialsOrdering.RESPECT_SERVER },
    private val warmImage: ((String) -> Unit)? = null,
) : MediaBrowserConnector {
    /**
     * A client is rebuilt only when something baked into it changed: the dialect (routes), the token or device id (auth
     * headers) or the URL set (failover candidates, compared as a set because promotions reorder it). The active URL,
     * admin flag and display fields drift on their own.
     */
    override fun canReuse(live: MediaBrowserConnection, incoming: MediaBrowserConnection): Boolean {
        val a = live as JellyfinConnection
        val b = incoming as JellyfinConnection
        return a.dialect == b.dialect && a.accessToken == b.accessToken && a.deviceId == b.deviceId && a.baseUrls.toSet() == b.baseUrls.toSet()
    }

    /**
     * With several stored URLs the fastest one reporting this server's machine id becomes active; stored URLs that
     * didn't answer stay as fallbacks and a changed list is persisted. When the race fails the stored active URL is
     * used alone (its stored alternates are kept for the next persist).
     */
    override suspend fun createClient(connection: MediaBrowserConnection, events: MediaBrowserClientEvents): JellyfinClient {
        val stored = connection as JellyfinConnection
        var resolved = stored
        var raceValidated = false
        if (stored.baseUrls.size > 1) {
            try {
                val race = JellyfinEndpointDiscovery(http, stored.dialect).raceEndpoints(
                    stored.baseUrls,
                    preferredUrl = stored.baseUrl,
                    expectedMachineId = stored.serverMachineId,
                    // Stored alternates are independent retry candidates, not one user-entered group.
                    baseUrlsToValidate = emptyList(),
                )
                resolved = stored.copy(
                    baseUrl = race.activeBaseUrl,
                    baseUrls = race.reconcilePreviouslyStoredBaseUrls(stored.baseUrls),
                    serverName = race.serverInfo.serverName,
                )
                raceValidated = true
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "${stored.dialect.productName} endpoint race failed; using only the stored active endpoint" }
                resolved = stored.copy(baseUrls = listOf(stored.baseUrl))
            }
        }
        val client = JellyfinClient(
            connection = resolved,
            http = http,
            identity = identity(resolved),
            cache = cache,
            scope = scope,
            favorites = favorites,
            codecs = codecs(),
            specialsOrdering = specialsOrdering,
            warmImage = warmImage,
            // Without a validated race the client runs on the active URL alone; the stored alternates must survive its
            // updates.
            onConnectionUpdated = { updated -> events.onConnectionUpdated(if (raceValidated) updated else updated.copy(baseUrls = stored.baseUrls)) },
            onAllEndpointsExhausted = events::onAllEndpointsExhausted,
        )
        if (raceValidated && (resolved.baseUrl != stored.baseUrl || resolved.baseUrls != stored.baseUrls)) {
            try {
                events.onConnectionUpdated(resolved)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to persist reconciled Jellyfin endpoints" }
            }
        }
        return client
    }

    override suspend fun persistConnection(connection: MediaBrowserConnection) = persist(connection as JellyfinConnection)

    private companion object {
        const val TAG = "JellyfinConnector"
    }
}
