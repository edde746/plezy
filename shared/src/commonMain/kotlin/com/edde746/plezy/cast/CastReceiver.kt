package com.edde746.plezy.cast

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.cast.CastPairingPrompt
import com.edde746.plezy.presentation.cast.CastReceiverUiState
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlin.time.ComparableTimeMark
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeSource
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull

/** The receiver's player side: it plays what senders cast and says what plays. Main thread. */
interface CastPlayback {
    /** What the cast plays now; null when no cast plays (none came, or it ended: Back, Stop, its end, a local play). */
    val state: StateFlow<CastState?>

    /**
     * Plays [item] on [server] as [senderName]'s cast, replacing what plays; returns once it plays ([state] isn't
     * null). Throws [CastLoadException].
     */
    suspend fun load(item: CastItem, server: MediaBackend, senderName: String)

    fun control(command: CastCommand)
}

/** A load that failed, and why. */
internal class CastLoadException(val failure: CastFailure, message: String, cause: Throwable? = null) : Exception(message, cause)

/** Makes a client of a handed-over server, in memory only; throws [CastLoadException] when this device can't reach it. */
internal fun interface CastServerAccess {
    suspend fun connect(access: ServerAccess): MediaBackend
}

/** Where a receiver listens: a socket server ([CastServer]), or a test's own transports. */
internal interface CastEndpoint {
    /** Listens, handing every new connection to [accept]; returns the port. */
    suspend fun open(accept: (FrameTransport) -> Unit): Int

    fun close()
}

/** The bounds a receiver keeps; tests shorten them. */
internal data class ReceiverLimits(
    val maxFailedAttempts: Int = 5,
    val lockoutMs: Long = 30_000,
    val maxLinks: Int = 8,
    /** How long the pairing question waits for the user. */
    val approvalTimeoutMs: Long = 60_000,
    /** How often the state goes out while nothing else changes (the senders' heartbeat too). */
    val stateIntervalMs: Long = 1_000,
    val handshake: HandshakeLimits = HandshakeLimits(),
)

/**
 * This device as a cast receiver: while [allowed] it listens ([endpoint]) and announces itself ([discovery]), lets in
 * the senders it remembers ([senders]) and asks its user about the others ([state]'s prompt, with the code the sender
 * shows), and plays what they hand over through [playback]. The handed-over server access lives in memory only, for
 * that cast: it goes when the cast ends or another replaces it. Every linked sender gets the state on each change and
 * every second, and may control the playback; one leaving changes nothing. Failed handshakes count per address: five
 * lock it out for 30 s. Main thread.
 */
class CastReceiver internal constructor(
    parentScope: CoroutineScope,
    private val me: suspend () -> CastPeerInfo,
    private val senders: CastPeers,
    allowed: Flow<Boolean>,
    internal val playback: CastPlayback,
    private val access: CastServerAccess,
    private val endpoint: CastEndpoint,
    private val discovery: CastDiscovery?,
    private val limits: ReceiverLimits = ReceiverLimits(),
    private val timeSource: TimeSource.WithComparableMarks = TimeSource.Monotonic,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(CastReceiverUiState())

    val state: StateFlow<CastReceiverUiState> = mutableState.asStateFlow()

    private val links = mutableListOf<CastLink>()

    /** The handshakes running: each holds a link's place while it runs (up to the approval's minute). */
    private var handshakes = 0

    private val failures = HashMap<String, Int>()
    private val lockouts = HashMap<String, ComparableTimeMark>()
    private val prompts = Mutex()
    private var decision: CompletableDeferred<Boolean>? = null
    private var loadJob: Job? = null
    private var loading = false

    /** The server access the cast playing now was handed over with; null when none plays. */
    internal var handedOver: MediaBackend? = null
        private set

    init {
        scope.launch { allowed.distinctUntilChanged().collectLatest { if (it) listen() } }
        scope.launch {
            var last: CastState? = null
            playback.state.collect { now ->
                mutableState.update { it.copy(castingFrom = now?.from?.let(T.cast::castingFrom)) }
                if (now == null && !loading && handedOver != null) {
                    handedOver = null
                    broadcast(CastMessage.Ended)
                }
                // Everything but the position goes out at once; the position goes with the heartbeat.
                if (now?.copy(positionMs = 0) != last?.copy(positionMs = 0)) broadcast(CastMessage.State(now))
                last = now
            }
        }
        scope.launch {
            while (true) {
                delay(limits.stateIntervalMs)
                broadcast(CastMessage.State(playback.state.value))
            }
        }
    }

    /** Lists, announces and admits until [allowed] turns off; the links open then close with it. */
    private suspend fun listen() {
        var advert: AutoCloseable? = null
        try {
            val device = me()
            val port = endpoint.open(::accept)
            advert = discovery?.let {
                try {
                    it.advertise(device.name, port, mapOf("id" to device.id, "name" to device.name, "platform" to device.platform, "kind" to device.kind.name))
                } catch (e: Exception) {
                    Log.w(TAG, e) { "Couldn't announce this receiver" }
                    null
                }
            }
            Log.i(TAG) { "Receiving casts on port $port" }
            awaitCancellation()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Couldn't start receiving casts" }
        } finally {
            advert?.close()
            endpoint.close()
            links.toList().forEach { it.close() }
        }
    }

    /** Takes a new connection through its handshake. */
    internal fun accept(transport: FrameTransport) {
        val source = transport.remoteAddress
        if (lockedOut(source) || links.size + handshakes >= limits.maxLinks) return transport.close()
        handshakes++
        scope.launch {
            val admission = try {
                receiverHandshake(transport, me(), senders::get, ::ask, senders::remember, scope, limits.handshake)
            } catch (e: CancellationException) {
                transport.close()
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "A handshake failed" }
                Admission.Rejected(true)
            } finally {
                handshakes--
            }
            when (admission) {
                is Admission.Rejected -> {
                    if (admission.failedAttempt) failed(source)
                    transport.close()
                }
                is Admission.Linked -> {
                    failures.remove(source)
                    serve(admission.link)
                }
            }
        }
    }

    private fun lockedOut(source: String): Boolean {
        val until = lockouts[source] ?: return false
        if (until.hasNotPassedNow()) return true
        lockouts.remove(source)
        failures.remove(source)
        return false
    }

    private fun failed(source: String) {
        val attempts = (failures[source] ?: 0) + 1
        failures[source] = attempts
        if (attempts >= limits.maxFailedAttempts) {
            lockouts[source] = timeSource.markNow() + limits.lockoutMs.milliseconds
            Log.w(TAG) { "$source is locked out for ${limits.lockoutMs / 1000}s" }
        }
    }

    /** Asks the user about [sender], one question at a time; no answer in time is a refusal. */
    private suspend fun ask(sender: CastPeerInfo, code: String): Boolean = prompts.withLock {
        val answer = CompletableDeferred<Boolean>()
        decision = answer
        Log.i(TAG) { "Asking whether ${sender.name} may cast" }
        mutableState.update {
            it.copy(prompt = CastPairingPrompt(sender.name, code, T.cast.pairing.receiverTitle(sender.name), T.cast.pairing.receiverMessage(sender.name)))
        }
        try {
            withTimeoutOrNull(limits.approvalTimeoutMs) { answer.await() } ?: false
        } finally {
            decision = null
            mutableState.update { it.copy(prompt = null) }
        }
    }

    /** Allows the sender [CastReceiverUiState.prompt] names: it is remembered and casts. */
    fun approve() {
        decision?.complete(true)
    }

    /** Refuses it: its sender shows that pairing was refused. */
    fun refuse() {
        decision?.complete(false)
    }

    private suspend fun serve(link: CastLink) {
        links += link
        Log.i(TAG) { "${link.peer.name} linked" }
        link.send(CastMessage.State(playback.state.value))
        try {
            link.incoming.collect { message ->
                when (message) {
                    is CastMessage.Load -> load(link, message)
                    is CastMessage.Control -> playback.control(message.command)
                    else -> Log.d(TAG) { "Ignoring $message from ${link.peer.name}" }
                }
            }
        } finally {
            links -= link
            link.close()
            Log.i(TAG) { "${link.peer.name} left" }
        }
    }

    private fun load(link: CastLink, message: CastMessage.Load) {
        loadJob?.cancel()
        loadJob = scope.launch {
            loading = true
            // The access the cast before was handed over with goes now: this one replaces it.
            handedOver = null
            try {
                val server = access.connect(message.access)
                playback.load(message.item, server, link.peer.name)
                handedOver = server
            } catch (e: CastLoadException) {
                Log.w(TAG, e) { "${link.peer.name}'s cast failed: ${e.failure}" }
                link.send(CastMessage.Failed(e.failure))
            } finally {
                loading = false
            }
            // The playback may have ended while it opened.
            if (playback.state.value == null && handedOver != null) {
                handedOver = null
                broadcast(CastMessage.Ended)
            }
        }
    }

    private fun broadcast(message: CastMessage) {
        links.forEach { it.send(message) }
    }

    internal fun close() = scope.cancel()

    private companion object {
        const val TAG = "CastReceiver"
    }
}
