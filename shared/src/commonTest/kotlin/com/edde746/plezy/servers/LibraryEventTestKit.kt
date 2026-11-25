package com.edde746.plezy.servers

import com.edde746.plezy.backend.LibraryEventChannel
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** A push channel the test drives by hand, counting its lifecycle calls. */
class FakeLibraryEventChannel : LibraryEventChannel {
    private val flow = MutableSharedFlow<LibraryChangeEvent>(extraBufferCapacity = 16)
    var starts = 0
    var stops = 0
    var disposed = false

    override val events: Flow<LibraryChangeEvent> = flow

    override fun start() {
        starts++
    }

    override fun stop() {
        stops++
    }

    override fun dispose() {
        disposed = true
    }

    fun emit(event: LibraryChangeEvent) {
        flow.tryEmit(event)
    }
}

/** A connection whose frames the test pushes; [drop] is the server closing it. */
class FakeLibraryEventConnection : LibraryEventConnection {
    private val channel = Channel<String>(Channel.UNLIMITED)
    var closed = false
        private set

    override val frames: Flow<String> = channel.receiveAsFlow()

    override suspend fun send(text: String) {}

    override fun close() {
        closed = true
        channel.close()
    }

    fun push(frame: String) {
        channel.trySend(frame)
    }

    fun drop() {
        channel.close()
    }
}

/** Hands out [FakeLibraryEventConnection]s, or runs [connect] when a test scripts the attempt. */
class FakeLibraryEventConnector : LibraryEventConnector {
    var attempts = 0
        private set
    val connections = mutableListOf<FakeLibraryEventConnection>()
    var connect: suspend () -> FakeLibraryEventConnection = { FakeLibraryEventConnection() }

    override suspend fun connect(url: String, headers: Map<String, String>): LibraryEventConnection {
        attempts++
        return connect().also { connections += it }
    }

    fun refuse(): Nothing = throw MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "push unavailable")
}

/**
 * A socket speaking a test protocol: `add:<library ids>` (added and updated; no ids = the whole server),
 * `remove:<library id>:<item id>`; anything else is malformed and throws.
 */
class TestLibraryEventSocket(
    connector: LibraryEventConnector,
    scope: CoroutineScope,
    timeSource: TimeSource,
    debounce: Duration = 100.milliseconds,
    retryBaseDelay: Duration = 5.seconds,
    maxConnectAttempts: Int = 5,
    connectTimeout: Duration = 10.seconds,
) : LibraryEventSocket(ServerId("plex_1"), debounce, connector, scope, timeSource, retryBaseDelay, maxConnectAttempts, connectTimeout) {
    override fun buildUrl(): String = "ws://server.invalid/:/websockets/notifications"

    override fun onFrame(frame: String) {
        val parts = frame.split(":")
        when (parts[0]) {
            "add" -> scheduleLibraryChange(libraryIds = parts[1].split(",").filter { it.isNotEmpty() }, added = true, updated = true)
            "remove" -> scheduleLibraryChange(libraryIds = listOf(parts[1]), removedItemIds = listOf(parts[2]), removed = true)
            else -> throw IllegalArgumentException("malformed frame")
        }
    }
}
