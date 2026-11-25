package com.edde746.plezy.music.engine

import kotlinx.coroutines.flow.Flow
import kotlin.time.Duration

/**
 * One track for the audio player: [uri] (http(s), a local file path, or Android's `content://`), the HTTP [headers]
 * that go with every request for this entry only (one server's credentials never ride another's), and where it starts.
 */
data class AudioMedia(val uri: String, val headers: Map<String, String> = emptyMap(), val start: Duration? = null)

/** What the audio player reports, in the order it happened, on one ordered stream ([AudioPlayer.events]). */
sealed interface AudioEvent {
    data class Playing(val playing: Boolean) : AudioEvent
    data class Buffering(val buffering: Boolean) : AudioEvent
    data class Position(val position: Duration) : AudioEvent
    data class DurationChanged(val duration: Duration) : AudioEvent

    /**
     * The engine reached the end of what it plays. mpv pulses it at every gapless boundary too, so it is never acted on
     * raw: a [TrackTransition] may follow.
     */
    data class Completed(val completed: Boolean) : AudioEvent

    /** The playlist advanced gaplessly into the entry armed with [AudioPlayer.setNext], whose [AudioMedia.uri] this is. */
    data class TrackTransition(val uri: String) : AudioEvent

    /** Something moves the playhead discontinuously, to this position, or where only the engine knows when null. */
    data class PlayheadJump(val position: Duration?) : AudioEvent

    /** The current entry failed; [message] is the engine's text, for the log only. */
    data class Error(val message: String) : AudioEvent
}

/** The latest values of [AudioPlayer.events], read synchronously. */
data class AudioPlayerState(
    val playing: Boolean = false,
    val buffering: Boolean = false,
    val completed: Boolean = false,
    val position: Duration = Duration.ZERO,
    val duration: Duration = Duration.ZERO,
) {
    /** Playing or about to: the session counts it as sounding. */
    val isActive: Boolean get() = playing || buffering
}

/**
 * The music session's player: a dedicated audio-only mpv core (`gapless-audio=weak`), never the video player.
 * Gapless advance arms the next entry with [setNext] (`loadfile append`), and the engine announces the advance with
 * [AudioEvent.TrackTransition].
 *
 * Commands suspend until the engine accepted them and throw when it refused; they are serialized in call order.
 * [events] is hot, ordered, and has one collector (the session). After [dispose] every command throws.
 */
interface AudioPlayer {
    val events: Flow<AudioEvent>
    val state: AudioPlayerState

    /**
     * Where the outgoing entry stood when the last [AudioEvent.TrackTransition] took over (its final playhead), or null
     * when unknown; the next [open] or transition replaces it.
     */
    val outgoingSourcePosition: Duration?

    val disposed: Boolean

    /** Replaces the playlist with [media] (dropping any armed entry); [play] false opens it paused. */
    @Throws(Exception::class)
    suspend fun open(media: AudioMedia, play: Boolean = true)

    @Throws(Exception::class)
    suspend fun play()

    @Throws(Exception::class)
    suspend fun pause()

    @Throws(Exception::class)
    suspend fun stop()

    @Throws(Exception::class)
    suspend fun seek(position: Duration)

    /**
     * Arms [media] to follow the playing entry gaplessly, replacing any earlier arm; null clears the arm. Clearing an
     * arm the playlist already advanced into surfaces that [AudioEvent.TrackTransition] instead of removing the playing
     * entry. Throws when the engine refused the arm (nothing is armed then).
     */
    @Throws(Exception::class)
    suspend fun setNext(media: AudioMedia?)

    /** 0–100. */
    @Throws(Exception::class)
    suspend fun setVolume(percent: Double)

    /** The output device's mpv name (`audio-device`), "auto" for the system's; applied before the first open. */
    @Throws(Exception::class)
    suspend fun setAudioDevice(name: String)

    /** Apple outputs only: compressed audio goes to the receiver undecoded. */
    @Throws(Exception::class)
    suspend fun setAudioPassthrough(enabled: Boolean)

    /** Android: the engine's log level per open (`v` with debug logging, else `warn`). */
    @Throws(Exception::class)
    suspend fun setVerboseLogging(verbose: Boolean)

    @Throws(Exception::class)
    suspend fun dispose()
}

/** The dedicated audio core failed to start (mpv refused to create, initialize or observe): thrown by the first open. */
class AudioPlayerInitializationException(message: String) : IllegalStateException(message)
