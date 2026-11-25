package com.edde746.plezy.servers

import com.edde746.plezy.backend.LibraryEventChannel
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.net.Backoff
import io.ktor.client.HttpClient
import io.ktor.client.plugins.websocket.DefaultClientWebSocketSession
import io.ktor.client.plugins.websocket.webSocketSession
import io.ktor.client.request.header
import io.ktor.websocket.Frame
import io.ktor.websocket.close
import io.ktor.websocket.readText
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * App-wide fan-out of server push notifications about library content. [LibraryEventService] publishes one
 * coalesced event per server change burst; profile-scoped stores collect [events] and refetch their own views.
 */
class LibraryContentNotifier {
    private val flow = eventFlow<LibraryChangeEvent>()

    val events: SharedFlow<LibraryChangeEvent> = flow.asSharedFlow()

    fun notifyChanged(event: LibraryChangeEvent) {
        flow.tryEmit(event)
    }
}

/**
 * Runs one [LibraryEventChannel] per visible online server and fans their events out through [notifier].
 *
 * Which channels run follows [OnlineServers.changes] (a server online or offline, its client or committed
 * authentication session replaced, the visible set changed) and the app lifecycle ([suspend], [resume]). Every
 * failure degrades silently: the stale-refresh paths remain the fallback when a socket can't be established.
 *
 * Call from one thread (the main dispatcher).
 */
class LibraryEventService(
    private val servers: OnlineServers,
    private val notifier: LibraryContentNotifier,
    private val deletions: DeletionNotifier,
    private val scope: CoroutineScope,
) {
    private class ManagedChannel(
        val client: MediaBackend,
        val authenticationSessionId: Any,
        val channel: LibraryEventChannel,
        val subscription: Job,
    )

    private val channels = LinkedHashMap<ServerId, ManagedChannel>()
    private var suspended = false
    private var disposed = false
    private val watch: Job = scope.launch(start = CoroutineStart.UNDISPATCHED) { servers.changes.collect { sync() } }

    /**
     * Reconciles the managed channels with the visible online clients. Runs on every [OnlineServers.changes] emission;
     * call it after a registration change that emits nothing.
     */
    fun sync() {
        if (disposed || suspended) return
        val online = servers.visibleOnlineClients

        // A healthy client can commit a new profile or token in place; its open socket still belongs to the old session.
        val stale = channels.filter { (serverId, managed) ->
            online[serverId] !== managed.client || managed.authenticationSessionId !== managed.client.authenticationSessionId
        }.keys
        stale.forEach(::stopChannel)

        for ((serverId, client) in online) {
            val retained = channels[serverId]
            if (retained != null) {
                // Re-arms a channel that ran out of reconnect attempts; a no-op while it runs or backs off.
                retained.channel.start()
                continue
            }
            if (!client.capabilities.libraryChangeEvents) continue
            val authenticationSessionId = client.authenticationSessionId
            val channel = client.createLibraryEventChannel() ?: continue
            val subscription = scope.launch(start = CoroutineStart.UNDISPATCHED) {
                channel.events.collect { event ->
                    if (disposed || suspended || channels[serverId]?.channel !== channel) return@collect
                    // A commit can land before the batched status emission: drop old-session frames and trailing
                    // coalesced events at once, including after a switch A → B → A with the same credential values.
                    if (authenticationSessionId !== client.authenticationSessionId) {
                        stopChannel(serverId)
                        return@collect
                    }
                    handleEvent(event)
                }
            }
            channels[serverId] = ManagedChannel(client, authenticationSessionId, channel, subscription)
            Log.d(TAG) { "Starting push channel for $serverId" }
            channel.start()
        }
    }

    /**
     * Removals name items the app may be showing, so each is dropped in place through [deletions] before the coarse
     * event schedules its refetch. Kind and parent chain are unknown here; consumers match by id and settle cascades
     * with the refetch. Past [MAX_PER_ITEM_REMOVALS] (a whole library or show deleted) the refetch alone owns it.
     */
    private fun handleEvent(event: LibraryChangeEvent) {
        if (event.removedItemIds.isNotEmpty() && event.removedItemIds.size <= MAX_PER_ITEM_REMOVALS) {
            for (itemId in event.removedItemIds) {
                deletions.notify(
                    DeletionEvent(
                        itemId = itemId,
                        serverId = event.serverId,
                        parentChain = emptyList(),
                        kind = MediaKind.UNKNOWN,
                        origin = DeletionOrigin.SERVER_PUSH,
                    ),
                )
            }
        }
        notifier.notifyChanged(event)
    }

    /** Stops every channel; [resume] rebuilds them from the live server state. */
    fun suspend() {
        if (disposed || suspended) return
        suspended = true
        channels.keys.toList().forEach(::stopChannel)
    }

    /** Reconciles on every foreground entry, also where channels were never suspended but ran out of retries. */
    fun resume() {
        if (disposed) return
        suspended = false
        sync()
    }

    fun dispose() {
        if (disposed) return
        suspended = true
        channels.keys.toList().forEach(::stopChannel)
        watch.cancel()
        disposed = true
    }

    private fun stopChannel(serverId: ServerId) {
        val managed = channels.remove(serverId) ?: return
        managed.subscription.cancel()
        managed.channel.dispose()
    }

    private companion object {
        const val TAG = "LibraryEventService"
        const val MAX_PER_ITEM_REMOVALS = 25
    }
}

/** An established push connection. [frames] are the text frames; it completes on close and throws on a failure. */
interface LibraryEventConnection {
    val frames: Flow<String>

    suspend fun send(text: String)

    /** Closes the connection. Idempotent; never throws. */
    fun close()
}

/** Opens push connections. [connect] returns only an established connection, or throws. */
fun interface LibraryEventConnector {
    suspend fun connect(url: String, headers: Map<String, String>): LibraryEventConnection
}

/**
 * Websocket push connections over the app's [HttpClient] (which installs WebSockets). OkHttp pings them at its engine's
 * interval; a session sets none of its own, which OkHttp refuses and after which Ktor's Darwin engine ends a healthy
 * connection at its first ping ("Ping timeout").
 */
class KtorLibraryEventConnector(private val http: HttpClient) : LibraryEventConnector {
    override suspend fun connect(url: String, headers: Map<String, String>): LibraryEventConnection {
        val session = http.webSocketSession(url) { headers.forEach { (name, value) -> header(name, value) } }
        return KtorConnection(session)
    }

    private class KtorConnection(private val session: DefaultClientWebSocketSession) : LibraryEventConnection {
        override val frames: Flow<String> = session.incoming.receiveAsFlow().filterIsInstance<Frame.Text>().map { it.readText() }

        override suspend fun send(text: String) = session.send(Frame.Text(text))

        override fun close() {
            session.launch {
                try {
                    session.close()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.d(TAG, e) { "Websocket close failed" }
                }
            }
        }
    }

    private companion object {
        const val TAG = "LibraryEventConnector"
    }
}

/**
 * A reconnecting push channel for one server's library changes. Owns the connect loop, bounded retry backoff, event
 * coalescing and silent degradation; a subclass owns the wire protocol: [buildUrl] (read the live base URL, so an
 * endpoint failover lands on the next attempt), [connectHeaders], [prepareConnection], [onFrame], and protocol timers
 * on [onConnected]/[onDisconnected].
 *
 * Every failed connect or dropped connection retries after [Backoff.equalJitter] of [retryBaseDelay] × 2^(attempt − 1)
 * (half of it to all of it), capped at two minutes; after [maxConnectAttempts] the channel goes quiet until the next
 * [start]. The attempt count resets on connect. A connect gets [connectTimeout]; a connection that arrives after its
 * attempt was abandoned is closed, not leaked.
 *
 * Events are throttled with a leading edge (Plex Web's per-section repopulate throttle): the first change after a quiet
 * [debounce] window emits at once; changes inside the window build up and flush once at its end. The trailing flush is
 * never pushed back, so a steady stream emits once per window. [events] never fails, and after [dispose] it emits
 * nothing more.
 *
 * Call from one thread (the main dispatcher).
 */
abstract class LibraryEventSocket(
    val serverId: ServerId,
    val debounce: Duration,
    private val connector: LibraryEventConnector,
    protected val scope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
    val retryBaseDelay: Duration = 5.seconds,
    val maxConnectAttempts: Int = 5,
    val connectTimeout: Duration = 10.seconds,
) : LibraryEventChannel {
    private val flow = eventFlow<LibraryChangeEvent>()

    override val events: SharedFlow<LibraryChangeEvent> = flow.asSharedFlow()

    /** The live connection; only ever an established one. */
    private var connection: LibraryEventConnection? = null

    /** The connect attempt and frame loop of the current connection. */
    private var connectJob: Job? = null

    /** Invalidates work of a superseded connection: bumped by every stop and every connect attempt. */
    private var generation = 0
    private var attempts = 0
    private var disposed = false
    private var retryJob: Job? = null
    private var debounceJob: Job? = null

    private var pendingAdded = false
    private var pendingRemoved = false
    private var pendingUpdated = false

    /** A frame in the window couldn't name its libraries: the whole server is pending, and named ids no longer matter. */
    private var pendingWholeServer = false
    private val pendingLibraryIds = LinkedHashSet<String>()
    private val pendingRemovedItemIds = LinkedHashSet<String>()
    private var lastEmitAt: TimeMark? = null

    /** Started and not stopped; the connection may still be connecting or backing off. */
    var isRunning: Boolean = false
        private set

    override fun start() {
        if (disposed || isRunning) return
        isRunning = true
        attempts = 0
        connect()
    }

    override fun stop() {
        // Cleaned even after the retry path gave up: a debounce armed by the last live frame may still be pending.
        debounceJob?.cancel()
        debounceJob = null
        retryJob?.cancel()
        retryJob = null
        clearPending()
        if (!isRunning && connection == null) return
        isRunning = false
        generation++
        teardownConnection()
        onDisconnected()
    }

    override fun dispose() {
        if (disposed) return
        stop()
        disposed = true
    }

    /** The websocket URL of the server's current connection; read per attempt. */
    protected abstract fun buildUrl(): String

    /** Headers sent with every upgrade request. */
    protected open fun connectHeaders(): Map<String, String> = emptyMap()

    /** Runs before each connect attempt (Emby's capabilities registration). A throw fails the attempt into the retry path. */
    protected open suspend fun prepareConnection() {}

    /** One text frame. Parse it and call [scheduleLibraryChange] / [sendFrame]; a throw drops the frame, not the channel. */
    protected abstract fun onFrame(frame: String)

    /** The connection was just established, before any frame. */
    protected open fun onConnected() {}

    /** The connection is gone (stop, failure or remote close); cancel protocol timers. May run without [onConnected]. */
    protected open fun onDisconnected() {}

    /** Sends a text frame when connected; dropped otherwise. */
    protected fun sendFrame(text: String) {
        val live = connection ?: return
        scope.launch {
            try {
                live.send(text)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "[$serverId] frame not sent" }
            }
        }
    }

    /**
     * Merges a change into the pending event and emits under the [debounce] throttle. Empty [libraryIds]: the frame
     * couldn't say which libraries changed, so the flushed event targets the whole server whatever else the window named.
     */
    protected fun scheduleLibraryChange(
        libraryIds: Collection<String> = emptyList(),
        removedItemIds: Collection<String> = emptyList(),
        added: Boolean = false,
        removed: Boolean = false,
        updated: Boolean = false,
    ) {
        if (disposed || !(added || removed || updated)) return
        pendingAdded = pendingAdded || added
        pendingRemoved = pendingRemoved || removed
        pendingUpdated = pendingUpdated || updated
        if (!pendingWholeServer) {
            if (libraryIds.isEmpty()) {
                pendingWholeServer = true
                pendingLibraryIds.clear()
            } else {
                pendingLibraryIds += libraryIds
            }
        }
        pendingRemovedItemIds += removedItemIds
        val sinceEmit = lastEmitAt?.elapsedNow()
        if (sinceEmit == null || sinceEmit >= debounce) {
            flushPending()
            return
        }
        if (debounceJob?.isActive == true) return
        debounceJob = scope.launch {
            delay(debounce - sinceEmit)
            debounceJob = null
            flushPending()
        }
    }

    private fun flushPending() {
        if (disposed) return
        val event = LibraryChangeEvent(
            serverId = serverId,
            libraryIds = if (pendingWholeServer) emptySet() else pendingLibraryIds.toSet(),
            removedItemIds = pendingRemovedItemIds.toSet(),
            itemsAdded = pendingAdded,
            itemsRemoved = pendingRemoved,
            itemsUpdated = pendingUpdated,
        )
        clearPending()
        if (!event.hasChanges) return
        lastEmitAt = timeSource.markNow()
        Log.d(TAG) { "[$serverId] $event" }
        flow.tryEmit(event)
    }

    private fun clearPending() {
        pendingAdded = false
        pendingRemoved = false
        pendingUpdated = false
        pendingWholeServer = false
        pendingLibraryIds.clear()
        pendingRemovedItemIds.clear()
    }

    private fun connect() {
        if (!isRunning || disposed) return
        val attempt = ++generation
        connectJob = scope.launch {
            val established = try {
                prepareConnection()
                if (attempt != generation) return@launch
                open(buildUrl(), connectHeaders())
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (attempt != generation) return@launch
                teardownConnection()
                scheduleRetry(e)
                return@launch
            }
            if (attempt != generation) {
                established.close()
                return@launch
            }
            connection = established
            attempts = 0
            Log.d(TAG) { "[$serverId] connected" }
            onConnected()
            try {
                established.frames.collect { frame ->
                    if (attempt != generation) return@collect
                    try {
                        onFrame(frame)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.d(TAG, e) { "[$serverId] dropped malformed frame" }
                    }
                }
                connectionLost(attempt, null)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                connectionLost(attempt, e)
            }
        }
    }

    /**
     * [connector]'s connection within [connectTimeout]. The connect runs on its own, so a connection that lands after
     * this attempt timed out or was cancelled is closed rather than leaked.
     */
    private suspend fun open(url: String, headers: Map<String, String>): LibraryEventConnection {
        val result = CompletableDeferred<LibraryEventConnection>()
        val pending = scope.launch {
            try {
                val opened = connector.connect(url, headers)
                if (!result.complete(opened)) opened.close()
            } catch (e: Throwable) {
                result.completeExceptionally(e)
            }
        }
        var delivered: LibraryEventConnection? = null
        try {
            delivered = withTimeoutOrNull(connectTimeout) { result.await() }
        } finally {
            if (delivered == null) {
                pending.cancel()
                // Lost the race to a connection completing just now: close it.
                if (!result.completeExceptionally(CancellationException("connect abandoned"))) {
                    withContext(NonCancellable) { runCatching { result.await() }.getOrNull()?.close() }
                }
            }
        }
        return delivered ?: throw MediaServerHttpException(
            MediaServerHttpErrorType.CONNECTION_TIMEOUT,
            "Library event connect exceeded its ${connectTimeout.inWholeSeconds}s budget",
        )
    }

    private fun connectionLost(attempt: Int, error: Throwable?) {
        if (attempt != generation || !isRunning || disposed) return
        teardownConnection()
        onDisconnected()
        scheduleRetry(error)
    }

    private fun scheduleRetry(error: Throwable?) {
        if (!isRunning || disposed) return
        attempts++
        if (attempts > maxConnectAttempts) {
            // Quiet until the next start() (a status change or app resume); stale refresh covers the gap.
            Log.d(TAG, error) { "[$serverId] giving up after $maxConnectAttempts attempts" }
            isRunning = false
            return
        }
        val wait = Backoff.equalJitter(attempts, retryBaseDelay.inWholeMilliseconds, MAX_RETRY_DELAY.inWholeMilliseconds).milliseconds
        Log.d(TAG, error) { "[$serverId] reconnecting in $wait (attempt $attempts)" }
        retryJob?.cancel()
        retryJob = scope.launch {
            delay(wait)
            retryJob = null
            connect()
        }
    }

    private fun teardownConnection() {
        connectJob?.cancel()
        connectJob = null
        connection?.close()
        connection = null
    }

    private companion object {
        const val TAG = "LibraryEventSocket"
        val MAX_RETRY_DELAY = 2.minutes
    }
}
