package com.edde746.plezy.music

import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaItem
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlin.time.Duration

/** Repeat behaviour of the music queue. [id] is the persisted value. */
enum class MusicRepeatMode(val id: String) { OFF("off"), ALL("all"), ONE("one") }

/** Coarse state of the music session. */
enum class MusicPlaybackStatus { IDLE, LOADING, PLAYING, PAUSED, ERROR }

/**
 * Where the queue came from. Artist, playlist, mix and library keep their title as the "Playing from" line; album and
 * ad-hoc queues show the current track's album instead. [id] is the persisted value.
 */
enum class MusicPlayContextKind(val id: String) { ALBUM("album"), ARTIST("artist"), PLAYLIST("playlist"), MIX("mix"), TRACKS("tracks"), LIBRARY("library") }

data class MusicPlayContext(val title: String, val kind: MusicPlayContextKind)

/**
 * [MusicPlayback.playInstantMix]'s answer. A failed fetch throws instead; [SUPERSEDED]: a newer play request took the
 * session while the mix loaded, and the caller stays silent.
 */
enum class InstantMixOutcome { STARTED, EMPTY, SUPERSEDED }

/**
 * Everything the music session shows except the playhead, which moves on [MusicPlayback.position]. A new value comes
 * only on discrete changes: track, status, queue shape, modes, sleep timer, volume.
 *
 * @param queue the queue in playback order (shuffle applied), played tracks included.
 * @param currentIndex [currentTrack]'s index in [queue]; −1 when idle.
 * @param duration the current track's, null while unknown.
 * @param sleepTimerDuration the timed sleep timer's armed length (to mark the chosen preset); null when off or in
 *   end-of-track mode.
 * @param canGoPrevious the queue has an entry before the current one, or the last under repeat-all (Previous is
 *   enabled only then).
 * @param canGoNext a manual next exists: an entry after the current one, or the first under repeat-all (Next is enabled
 *   only then).
 * @param volume 0–100, the music volume, independent of the video player's.
 */
data class MusicState(
    val status: MusicPlaybackStatus = MusicPlaybackStatus.IDLE,
    val currentTrack: MediaItem? = null,
    val queue: List<MediaItem> = emptyList(),
    val currentIndex: Int = -1,
    val playContext: MusicPlayContext? = null,
    val shuffled: Boolean = false,
    val repeatMode: MusicRepeatMode = MusicRepeatMode.OFF,
    val duration: Duration? = null,
    val sleepTimerActive: Boolean = false,
    val sleepTimerDuration: Duration? = null,
    val sleepTimerEndOfTrack: Boolean = false,
    val canGoPrevious: Boolean = false,
    val canGoNext: Boolean = false,
    val volume: Double = 100.0,
) {
    val isPlaying: Boolean get() = status == MusicPlaybackStatus.PLAYING
}

/**
 * The profile's music session: an audio-only player separate from the video player, the queue with shuffle and repeat,
 * gapless advance, the OS media session, progress reports, the sleep timer, and the last session kept per profile and
 * restored paused on the next launch. One per profile session; a profile switch ends it.
 *
 * Commands are called from the main thread.
 */
interface MusicPlayback {
    val state: StateFlow<MusicState>

    /** The playhead of the current track. */
    val position: StateFlow<Duration>

    /**
     * Something moves the playhead discontinuously: to this position, or to somewhere only the engine knows when null.
     * The request, not its landing. A screen coalescing its own relative seeks drops a pending target this supersedes.
     */
    val playheadJumps: Flow<Duration?>

    /**
     * Failures mid-playback the screen shows (a snackbar); the session already recovered (skipped or stopped). Never
     * Instant Mix failures, which [playInstantMix] throws.
     */
    val errors: Flow<Throwable>

    /** Volume while a slider drags, before [setVolume] persists it; [MusicState.volume] follows only persisted changes. */
    val volumePreview: StateFlow<Double>

    /**
     * Claims the latest intent to replace playback before fetching its tracks; commit only while [isPlayIntentCurrent].
     */
    fun beginPlayIntent(): Int

    fun isPlayIntentCurrent(intent: Int): Boolean

    /** Changes whenever a queue session starts or stops: an enqueue whose fetch spans a change is dropped. */
    val queueSessionRevision: Int

    /**
     * Starts a queue from [tracks] at [startTrack] (matched by global key; one not in the list is ignored). [shuffle]
     * plays [startTrack] first and shuffles the rest after it; without one the whole list shuffles. Empty: nothing.
     * [offline] plays downloaded copies only.
     */
    suspend fun playFromList(
        tracks: List<MediaItem>,
        startTrack: MediaItem? = null,
        playContext: MusicPlayContext,
        shuffle: Boolean = false,
        initialPosition: Duration? = null,
        offline: Boolean = false,
    )

    /** Fetches up to 100 tracks seeded from [seed] on its server and plays them (context [MusicPlayContextKind.MIX]). */
    suspend fun playInstantMix(seed: MediaItem): InstantMixOutcome

    suspend fun play()
    suspend fun pause()
    suspend fun togglePlayPause()

    /** The next entry (repeat-one still steps; wraps only under repeat-all). */
    suspend fun next()

    /** Past 3 s into the track: back to its start; otherwise the previous entry. */
    suspend fun previous()

    suspend fun seek(position: Duration)

    /** [persist] false: a slider drag, only [volumePreview] moves. */
    suspend fun setVolume(volume: Double, persist: Boolean = true)

    fun setRepeatMode(mode: MusicRepeatMode)
    fun toggleShuffle()

    /** Plays the entry at [index] of [MusicState.queue]. */
    suspend fun jumpTo(index: Int)
    fun removeAt(index: Int)
    fun reorder(from: Int, to: Int)

    /** Inserts after the current entry; while idle, starts a session parked paused on the first track. */
    fun addNext(tracks: List<MediaItem>)

    /** Appends; while idle, starts a session parked paused on the first track. */
    fun addToEnd(tracks: List<MediaItem>)

    /** Drops every entry after the current one. */
    fun clearUpcoming()

    /** Ends the session: the queue, the mini-player and the persisted session go. */
    suspend fun stop()

    /** A timed sleep timer ([duration]), or [endOfTrack]; null and false cancel it. It pauses; the session stays. */
    fun setSleepTimer(duration: Duration?, endOfTrack: Boolean = false)

    /** [track]'s lyrics from its server; null: none. */
    suspend fun fetchLyrics(track: MediaItem): Lyrics?
}
