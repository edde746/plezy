package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LibraryEventConnector
import com.edde746.plezy.servers.LibraryEventSocket
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The MediaBrowser session socket as a library-change channel. Protocol (Jellyfin 10.11, Emby 4.9.5): the server
 * opens with `ForceKeepAlive` carrying its timeout in seconds and drops the session unless `KeepAlive` arrives within
 * it; `LibraryChanged` carries a scan's batched change sets. Emby routes `LibraryChanged` only to sessions that
 * registered capabilities, so that registration precedes every connect.
 */
internal class JellyfinLibraryEvents(
    private val core: JellyfinCore,
    connector: LibraryEventConnector,
    scope: CoroutineScope,
    debounce: Duration = 2.seconds,
) : LibraryEventSocket(ServerId(core.connection.serverMachineId), debounce, connector, scope) {
    private var keepAlive: Job? = null

    /** Read per attempt, so an endpoint failover lands on the next connect. */
    override fun buildUrl(): String = core.connection.let { socketUrl(it.baseUrl, it.dialect, it.accessToken, it.deviceId) }

    /** The same Authorization as every request keeps one dashboard session per device. */
    override fun connectHeaders(): Map<String, String> = mapOf("Authorization" to core.identity.authorization(core.connection.accessToken))

    override suspend fun prepareConnection() {
        if (core.dialect.requiresSessionCapabilitiesForLibraryEvents) {
            core.post("/Sessions/Capabilities/Full", body = SESSION_CAPABILITIES).throwIfError()
        }
    }

    override fun onFrame(frame: String) {
        when (val message = parseFrame(frame)) {
            is SocketMessage.ForceKeepAlive -> {
                keepAlive?.cancel()
                keepAlive = scope.launch {
                    while (isActive) {
                        sendFrame(KEEP_ALIVE)
                        delay(keepAliveInterval(message.timeoutSeconds))
                    }
                }
            }
            is SocketMessage.LibraryChanged -> with(message) {
                scheduleLibraryChange(libraryIds, removedItemIds, added, removed, updated)
            }
            null -> Unit
        }
    }

    override fun onDisconnected() {
        keepAlive?.cancel()
        keepAlive = null
    }

    sealed interface SocketMessage {
        data class ForceKeepAlive(val timeoutSeconds: Int?) : SocketMessage

        /** Empty [libraryIds]: the frame could not say which libraries changed. */
        data class LibraryChanged(
            val libraryIds: Set<String> = emptySet(),
            val removedItemIds: Set<String> = emptySet(),
            val added: Boolean = false,
            val removed: Boolean = false,
            val updated: Boolean = false,
        ) : SocketMessage
    }

    companion object {
        const val KEEP_ALIVE = """{"MessageType":"KeepAlive"}"""

        val SESSION_CAPABILITIES = buildJsonObject {
            put("PlayableMediaTypes", buildJsonArray { add(JsonPrimitive("Video")); add(JsonPrimitive("Audio")) })
            put("SupportedCommands", JsonArray(emptyList()))
            put("SupportsMediaControl", false)
            put("SupportsSync", false)
        }

        /** `ws(s)://{base}{webSocketPath}?{token param}={token}&deviceId={id}`; the base's path prefix is kept. */
        fun socketUrl(baseUrl: String, dialect: MediaBrowserDialect, accessToken: String, deviceId: String): String {
            val base = baseUrl.trimEnd('/')
            val ws = when {
                base.startsWith("https://", ignoreCase = true) -> "wss://" + base.substring(8)
                base.startsWith("http://", ignoreCase = true) -> "ws://" + base.substring(7)
                else -> base
            }
            return ws + dialect.webSocketPath + "?" + JellyfinUrls.query(listOf(dialect.tokenQueryParam to accessToken, "deviceId" to deviceId))
        }

        /** Half the server's timeout (60 s when missing), kept within 10 s–5 min so a bogus value cannot spin. */
        fun keepAliveInterval(timeoutSeconds: Int?): Duration = ((timeoutSeconds ?: 60) / 2).coerceIn(10, 300).seconds

        /** The frames this channel acts on; null for anything else (acks, progress, session traffic, malformed). */
        fun parseFrame(text: String): SocketMessage? {
            val message = runCatching { Json.parseToJsonElement(text) }.getOrNull() as? JsonObject ?: return null
            return when (message.str("MessageType")) {
                "ForceKeepAlive" -> SocketMessage.ForceKeepAlive(message["Data"]?.flexibleLong()?.toInt())
                "LibraryChanged" -> {
                    val data = message.obj("Data") ?: return null
                    fun ids(key: String) = data.array(key).orEmpty().filter { it != JsonNull }.map { (it as? JsonPrimitive)?.content ?: it.toString() }
                    fun nonEmpty(key: String) = data.array(key)?.isNotEmpty() == true
                    SocketMessage.LibraryChanged(
                        libraryIds = ids("CollectionFolders").toSet(),
                        removedItemIds = ids("ItemsRemoved").toSet(),
                        added = nonEmpty("ItemsAdded") || nonEmpty("FoldersAddedTo"),
                        removed = nonEmpty("ItemsRemoved") || nonEmpty("FoldersRemovedFrom"),
                        updated = nonEmpty("ItemsUpdated"),
                    )
                }
                else -> null
            }
        }
    }
}
