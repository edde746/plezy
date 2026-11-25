package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaBrowserDialect

import com.edde746.plezy.backend.net.canonicalizeBaseUrl
import com.edde746.plezy.log.Log
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

data class DiscoveredJellyfinServer(val address: String, val id: String, val name: String, val dialect: MediaBrowserDialect)

/**
 * Finds MediaBrowser servers on the LAN: the dialect's payload broadcast to UDP 7359 twice, 350 ms apart, then the
 * replies of [responseWindowMillis]. Jellyfin and Emby each answer only their own payload, with the same reply shape,
 * so the dialect comes from what was sent. Socket errors are logged and what was found is returned.
 */
object JellyfinLanDiscovery {
    const val LIMITED_BROADCAST = "255.255.255.255"
    const val DEFAULT_RESPONSE_WINDOW_MILLIS = 2_000L
    private const val REPEAT_DELAY_MILLIS = 350L

    suspend fun discover(
        dialect: MediaBrowserDialect,
        responseWindowMillis: Long = DEFAULT_RESPONSE_WINDOW_MILLIS,
        broadcastAddress: String = LIMITED_BROADCAST,
    ): List<DiscoveredJellyfinServer> {
        val found = LinkedHashMap<String, DiscoveredJellyfinServer>()
        try {
            udpBroadcastExchange(
                payload = dialect.lanDiscoveryMessage.encodeToByteArray(),
                host = broadcastAddress,
                port = MediaBrowserDialect.LAN_DISCOVERY_PORT,
                repeatDelayMillis = REPEAT_DELAY_MILLIS,
                listenMillis = responseWindowMillis,
            ) { datagram ->
                val server = parseResponse(datagram, dialect) ?: return@udpBroadcastExchange
                if (server.id !in found) found[server.id] = server
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "${dialect.productName} LAN discovery failed" }
        }
        return sort(found.values)
    }

    fun sort(servers: Collection<DiscoveredJellyfinServer>): List<DiscoveredJellyfinServer> = servers.sortedWith(
        compareBy<DiscoveredJellyfinServer> { it.name.lowercase() }.thenBy { it.address }.thenBy { it.id }.thenBy { it.dialect.id },
    )

    fun parseResponse(data: ByteArray, dialect: MediaBrowserDialect): DiscoveredJellyfinServer? {
        val json = runCatching { Json.parseToJsonElement(data.decodeToString()) }.getOrNull() as? JsonObject ?: return null
        fun string(key: String) = (json[key] as? JsonPrimitive)?.takeIf { it.isString }?.content?.trim()?.ifEmpty { null }
        val address = string("Address") ?: string("address") ?: return null
        val id = string("Id") ?: string("id") ?: return null
        val name = string("Name") ?: string("name") ?: return null
        val normalized = canonicalizeBaseUrl(address).ifEmpty { return null }
        return DiscoveredJellyfinServer(normalized, id, name, dialect)
    }

    private const val TAG = "JellyfinLanDiscovery"
}

/**
 * Sends [payload] to [host]:[port] from a broadcast-enabled UDP socket per local IPv4 interface, again after
 * [repeatDelayMillis], then hands every datagram received within [listenMillis] of the second send to [onDatagram].
 * Send failures of one socket are logged and skipped.
 */
internal expect suspend fun udpBroadcastExchange(
    payload: ByteArray,
    host: String,
    port: Int,
    repeatDelayMillis: Long,
    listenMillis: Long,
    onDatagram: (ByteArray) -> Unit,
)
