package com.edde746.plezy.plex

import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LibraryEventConnector
import com.edde746.plezy.servers.LibraryEventSocket
import io.ktor.http.URLBuilder
import io.ktor.http.URLProtocol
import io.ktor.http.Url
import io.ktor.http.encodedPath
import kotlinx.coroutines.CoroutineScope
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * Plex realtime notifications: `ws(s)://<server>/:/websockets/notifications`. Every frame is a
 * `NotificationContainer`; a library scan floods the socket with activity, progress and session traffic, so only
 * settled `timeline` entries count:
 *
 * ```json
 * {"NotificationContainer": {"type": "timeline", "TimelineEntry": [
 *   {"identifier": "com.plexapp.plugins.library", "sectionID": "1", "itemID": "10141", "type": 1, "state": 5}]}}
 * ```
 *
 * `state` walks 0→5 while an item is scanned, matched and analyzed; 5 is the settled commit. A deletion is the same
 * entry with `type` -1. Adds and metadata updates look the same once settled, so both flags are set for anything else.
 * [baseUrl] and [token] are read per connect, so an endpoint failover or token change lands on the next attempt.
 */
class PlexLibraryEventSocket(
    serverId: ServerId,
    private val baseUrl: () -> String,
    private val token: () -> String?,
    connector: LibraryEventConnector,
    scope: CoroutineScope,
    timeSource: TimeSource = TimeSource.Monotonic,
    debounce: Duration = 10.seconds,
    retryBaseDelay: Duration = 5.seconds,
    maxConnectAttempts: Int = 5,
) : LibraryEventSocket(serverId, debounce, connector, scope, timeSource, retryBaseDelay, maxConnectAttempts) {
    /** The base URL's websocket twin, its reverse-proxy path prefix kept, with the token as `X-Plex-Token`. */
    public override fun buildUrl(): String {
        val base = Url(baseUrl())
        return URLBuilder(base).apply {
            protocol = if (base.protocol.name == "https") URLProtocol.WSS else URLProtocol.WS
            port = base.port
            encodedPath = base.encodedPath.trimEnd('/') + "/:/websockets/notifications"
            parameters.clear()
            fragment = ""
            token()?.let { parameters.append("X-Plex-Token", it) }
        }.buildString()
    }

    override fun onFrame(frame: String) {
        val container = (Json.parseToJsonElement(frame) as? JsonObject)?.get("NotificationContainer") as? JsonObject ?: return
        if (container["type"].stringOrNull() != "timeline") return
        val entries = container["TimelineEntry"] as? JsonArray ?: return
        for (entry in entries.filterIsInstance<JsonObject>()) {
            if (entry["identifier"].stringOrNull() != PLEX_LIBRARY_IDENTIFIER) continue
            if (entry["state"].flexInt() != STATE_SETTLED) continue
            val sectionId = entry["sectionID"].scalarString()?.takeIf { it.isNotEmpty() }
            val itemId = entry["itemID"].scalarString()?.takeIf { it.isNotEmpty() }
            val removed = entry["type"].flexInt() == TYPE_DELETED
            scheduleLibraryChange(
                libraryIds = listOfNotNull(sectionId),
                removedItemIds = if (removed) listOfNotNull(itemId) else emptyList(),
                added = !removed,
                updated = !removed,
                removed = removed,
            )
        }
    }

    private companion object {
        const val STATE_SETTLED = 5
        const val TYPE_DELETED = -1
    }
}
