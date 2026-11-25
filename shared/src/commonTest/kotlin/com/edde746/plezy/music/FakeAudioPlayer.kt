package com.edde746.plezy.music

import com.edde746.plezy.music.engine.AudioEvent
import com.edde746.plezy.music.engine.AudioMedia
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.music.engine.AudioPlayerState
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlin.time.Duration

/** Holds a call until [release]: [entered] completes when the call reached it. */
class CallGate {
    val entered = CompletableDeferred<Unit>()
    private val released = CompletableDeferred<Unit>()

    suspend fun block() {
        entered.complete(Unit)
        released.await()
    }

    fun release() {
        released.complete(Unit)
    }
}

/**
 * An in-memory [AudioPlayer]: records the calls, keeps [state] as the engine would, and lets a test emit what the engine
 * reports ([emitTransition], [emitCompleted], [emitError], [setPosition]) and hold calls ([gateNextOpen], [playGate],
 * [pauseGate]).
 */
class FakeAudioPlayer(private val openDuration: Duration = TRACK_DURATION) : AudioPlayer {
    private val flow = MutableSharedFlow<AudioEvent>(extraBufferCapacity = 256)
    override val events: Flow<AudioEvent> = flow

    override var state = AudioPlayerState()
        private set
    override var outgoingSourcePosition: Duration? = null
    override var disposed = false
        private set

    val openedUris = mutableListOf<String>()

    /** [AudioMedia.start] of each open, aligned with [openedUris]. */
    val openStarts = mutableListOf<Duration?>()
    val openHeaders = mutableListOf<Map<String, String>>()
    val setNextCalls = mutableListOf<AudioMedia?>()
    val seeks = mutableListOf<Duration>()
    val volumes = mutableListOf<Double>()
    val audioDevices = mutableListOf<String>()

    /** Each passthrough write with the number of opens before it. */
    val passthroughWrites = mutableListOf<Pair<Boolean, Int>>()
    /** Each Debug logging write with the number of opens before it. */
    val verboseWrites = mutableListOf<Pair<Boolean, Int>>()
    var playGate: CompletableDeferred<Unit>? = null
    var pauseGate: CompletableDeferred<Unit>? = null
    private val openGates = ArrayDeque<CallGate>()

    /** Arming these URIs throws, as an engine refusing the arm. */
    val failingSetNextUris = mutableSetOf<String>()
    var playCalls = 0
        private set
    var pauseCalls = 0
        private set
    var stopCalls = 0
        private set

    /** The armed entry as the engine's playlist holds it: set by [setNext], consumed by an advance or an open. */
    var armed: AudioMedia? = null
        private set

    fun gateNextOpen(): CallGate = CallGate().also { openGates.addLast(it) }

    private fun emit(event: AudioEvent) {
        check(flow.tryEmit(event)) { "event buffer full" }
    }

    /**
     * A gapless advance. Leaves the playhead alone: when the engine announces it, the state can still carry the
     * finished track's ([setOutgoingPlayhead]).
     */
    fun emitTransition(uri: String) {
        armed = null
        state = state.copy(completed = false)
        emit(AudioEvent.TrackTransition(uri))
    }

    fun setOutgoingPlayhead(position: Duration, duration: Duration) {
        state = state.copy(position = position, duration = duration)
    }

    fun emitCompleted() {
        state = state.copy(completed = true, position = state.duration)
        emit(AudioEvent.Completed(true))
    }

    /** The engine's boundary: completed always pulses; a transition follows only when something is armed. */
    fun emitNaturalBoundary(): Boolean {
        val next = armed
        emitCompleted()
        if (next == null) return false
        emitTransition(next.uri)
        return true
    }

    fun emitError(message: String) = emit(AudioEvent.Error(message))

    fun emitJump(position: Duration?) = emit(AudioEvent.PlayheadJump(position))

    fun setPosition(position: Duration) {
        state = state.copy(position = position)
        emit(AudioEvent.Position(position))
    }

    override suspend fun open(media: AudioMedia, play: Boolean) {
        openGates.removeFirstOrNull()?.block()
        armed = null
        openedUris += media.uri
        openStarts += media.start
        openHeaders += media.headers
        state = state.copy(playing = play, completed = false, position = Duration.ZERO, duration = openDuration)
        if (play) emit(AudioEvent.Playing(true))
    }

    override suspend fun play() {
        playCalls++
        playGate?.await()
        state = state.copy(playing = true, completed = false)
        emit(AudioEvent.Playing(true))
    }

    override suspend fun pause() {
        pauseCalls++
        pauseGate?.await()
        state = state.copy(playing = false)
        emit(AudioEvent.Playing(false))
    }

    override suspend fun stop() {
        stopCalls++
        state = state.copy(playing = false, position = Duration.ZERO)
    }

    override suspend fun seek(position: Duration) {
        seeks += position
        state = state.copy(position = position, completed = false)
    }

    override suspend fun setNext(media: AudioMedia?) {
        setNextCalls += media
        if (media != null && media.uri in failingSetNextUris) error("setNext failed for ${media.uri}")
        armed = media
    }

    override suspend fun setVolume(percent: Double) {
        volumes += percent
    }

    override suspend fun setAudioDevice(name: String) {
        audioDevices += name
    }

    override suspend fun setAudioPassthrough(enabled: Boolean) {
        passthroughWrites += enabled to openedUris.size
    }

    override suspend fun setVerboseLogging(verbose: Boolean) {
        verboseWrites += verbose to openedUris.size
    }

    override suspend fun dispose() {
        disposed = true
    }
}
