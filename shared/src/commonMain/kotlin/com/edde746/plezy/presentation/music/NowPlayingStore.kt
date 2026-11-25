package com.edde746.plezy.presentation.music

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.DebouncedSeekAccumulator
import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.steppedSeekMultiplier
import com.edde746.plezy.music.MusicPlaybackStatus
import com.edde746.plezy.music.MusicRepeatMode
import com.edde746.plezy.music.MusicState
import com.edde746.plezy.presentation.player.PlayerText
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * Where the playhead stands in the current track, for a seek bar or a progress fill, and the seek bar's two times: the
 * time played ([positionLabel]) and the time left ([remainingLabel], "−0:23"), as the video player shows them, each
 * in whole seconds so the two add up to the duration.
 */
data class MusicProgress(val position: Duration = Duration.ZERO, val duration: Duration = Duration.ZERO) {
    /** 0–1; 0 while the duration is unknown. */
    val fraction: Float get() = if (duration <= Duration.ZERO) 0f else (position / duration).toFloat().coerceIn(0f, 1f)
    val positionMillis: Long get() = position.inWholeMilliseconds
    val durationMillis: Long get() = duration.inWholeMilliseconds
    val positionLabel: String get() = timestamp(position)
    val remainingLabel: String get() = remaining(position)

    /** The time played at [fraction] of the track: where a drag along the seek bar stands. */
    fun positionAt(fraction: Double): String = timestamp(at(fraction))

    /** The time left from [fraction] of the track: where a drag along the seek bar stands. */
    fun remainingAt(fraction: Double): String = remaining(at(fraction))

    private fun at(fraction: Double): Duration = duration * fraction.coerceIn(0.0, 1.0)

    private fun remaining(from: Duration): String =
        PlayerText.remaining((duration.inWholeSeconds - from.inWholeSeconds).coerceAtLeast(0).toDouble())
}

/** The lyrics pane. */
sealed interface LyricsUi {
    data object Loading : LyricsUi

    /** The track has none: the lyrics icon and "No lyrics available". */
    data object None : LyricsUi

    /** [synced]: lines carry their start, the playing one highlights ([NowPlayingStore.activeLyricLine]) and a tap seeks. */
    data class Lines(val lines: List<String>, val synced: Boolean) : LyricsUi
}

/**
 * The queue, as the sheet and the wide layout's inline panel show it: the whole playback order, played rows dimmed,
 * the current one with the equalizer and a bold title, no album track numbers. Titled [T.music.queue]; empty, it says
 * [T.messages.noItemsAvailable].
 */
data class QueueUi(
    val rows: List<TrackRowUi>,
    /** The playing row; the list opens scrolled to it and follows it. */
    val currentIndex: Int,
    /** "N tracks". */
    val count: String,
    val shuffled: Boolean,
    val repeatMode: MusicRepeatMode,
)

/**
 * Now Playing, while the session has a track. [track] null: the session ended and the screen is leaving.
 *
 * @param playingFrom "Playing from …", null hides the line ([playingFromTitle]).
 * @param canGoPrevious Previous is enabled: the queue has an entry before the current one ([MusicState.canGoPrevious]).
 * @param canGoNext Next is enabled: the queue has an entry after the current one ([MusicState.canGoNext]).
 */
data class NowPlayingUiState(
    val track: MusicTrackUi? = null,
    val playingFrom: String? = null,
    val status: MusicPlaybackStatus = MusicPlaybackStatus.IDLE,
    val shuffled: Boolean = false,
    val repeatMode: MusicRepeatMode = MusicRepeatMode.OFF,
    val canGoPrevious: Boolean = false,
    val canGoNext: Boolean = false,
    val showLyrics: Boolean = false,
    val lyrics: LyricsUi = LyricsUi.Loading,
    val queue: QueueUi = QueueUi(emptyList(), -1, T.music.trackCount(0), shuffled = false, repeatMode = MusicRepeatMode.OFF),
    val sleepTimer: List<SleepTimerOptionUi> = emptyList(),
) {
    val isPlaying: Boolean get() = status == MusicPlaybackStatus.PLAYING

    /** The play button spins. */
    val loading: Boolean get() = status == MusicPlaybackStatus.LOADING
}

/**
 * The Now Playing screen's store: the session's track, transport, queue, lyrics and sleep timer. The playhead moves
 * on [progress] alone, so its ticks never touch [state]. When the session ends the screen closes once, taking only its
 * own route off the stack. Failures mid-playback show as snackbars while it is open. [close] when the screen goes.
 */
class NowPlayingStore internal constructor(private val screens: MusicScreens, parentScope: CoroutineScope) {
    private val playback = screens.playback
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(NowPlayingUiState())
    private val mutableProgress = MutableStateFlow(MusicProgress())
    private val mutableActiveLine = MutableStateFlow(-1)

    val state: StateFlow<NowPlayingUiState> = mutableState.asStateFlow()

    /** The seek bar: the playhead, or where a D-pad seek is heading. */
    val progress: StateFlow<MusicProgress> = mutableProgress.asStateFlow()

    /** The synced lyric line playing now, −1 for none. */
    val activeLyricLine: StateFlow<Int> = mutableActiveLine.asStateFlow()

    /** The volume slider (0–100), following a drag before it persists. */
    val volume: StateFlow<Double> = playback.volumePreview

    private var trackKey: String? = null
    private var currentTrack: MediaItem? = null

    /** The current track: the overflow opens its item menu, the sleep timer last. */
    val item: MediaItem? get() = currentTrack

    private var livePosition = Duration.ZERO
    private var closed = false
    private val lyricsCache = HashMap<String, Deferred<Lyrics?>>()
    private var lyrics: Lyrics? = null
    private var lyricsJob: Job? = null
    private var lyricsKey: String? = null

    private var seekDirection: Boolean? = null
    private var seekRepeats = 0
    private val keySeek = DebouncedSeekAccumulator(
        scope = scope,
        currentPosition = { playback.position.value },
        duration = { playback.state.value.duration ?: Duration.ZERO },
        seek = { target ->
            val key = trackKey
            if (key != null && playback.state.value.currentTrack?.globalKey == key) scope.launch { playback.seek(target) }
        },
        onChanged = { publishProgress() },
        playheadJumps = playback.playheadJumps,
    )

    init {
        scope.launch { playback.state.collect(::onState) }
        scope.launch {
            playback.position.collect {
                livePosition = it
                publishProgress()
            }
        }
        scope.launch { playback.errors.collect { screens.message(musicErrorText(it), error = true) } }
        scope.launch {
            screens.sleepTimerMinutes.collect { mutableState.value = mutableState.value.copy(sleepTimer = sleepTimerOptions(playback.state.value, it)) }
        }
    }

    fun togglePlayPause() {
        scope.launch { playback.togglePlayPause() }
    }

    fun next() {
        scope.launch { playback.next() }
    }

    fun previous() {
        scope.launch { playback.previous() }
    }

    fun toggleShuffle() = playback.toggleShuffle()

    /** Off, all, one, off. */
    fun cycleRepeat() = playback.setRepeatMode(playback.state.value.repeatMode.next)

    /** A seek bar drag let go at [position]. */
    fun seekTo(position: Duration) {
        keySeek.cancel()
        val key = trackKey ?: return
        scope.launch { if (playback.state.value.currentTrack?.globalKey == key) playback.seek(position) }
    }

    /** A seek bar drag let go at [fraction] (0–1) of the track. */
    fun seekToFraction(fraction: Float) {
        val duration = playback.state.value.duration ?: return
        seekTo(duration * fraction.coerceIn(0f, 1f).toDouble())
    }

    /**
     * A D-pad step on the seek bar: 10 s [forward] or back, growing while the key repeats ([steppedSeekMultiplier]).
     * Steps add up and seek once, at [endStepSeek] (the key let go, focus gone) or after a pause.
     */
    fun stepSeek(forward: Boolean, repeat: Boolean) {
        val duration = playback.state.value.duration
        if (duration == null || duration <= Duration.ZERO) return
        if (seekDirection != forward) {
            seekDirection = forward
            seekRepeats = 0
        }
        if (repeat) seekRepeats++
        val step = SEEK_STEP * (if (repeat) steppedSeekMultiplier(seekRepeats) else 1.0)
        keySeek.seekBy(if (forward) step else -step)
    }

    /** The D-pad seek's key was let go, or the seek bar lost focus: the steps so far seek now. */
    fun endStepSeek() {
        keySeek.flush()
        resetStepSeek()
    }

    /** Swaps the artwork for the lyrics and back. */
    fun toggleLyrics() {
        mutableState.value = mutableState.value.copy(showLyrics = !mutableState.value.showLyrics)
        loadLyrics()
    }

    /** A synced line tapped or selected: playback goes to its start. */
    fun seekToLyric(index: Int) {
        val lyrics = lyrics?.takeIf { it.synced } ?: return
        val start = lyrics.lines.getOrNull(index)?.startMs ?: return
        seekTo(start.milliseconds)
    }

    fun setSleepTimer(choice: SleepTimerChoice) = when (choice) {
        SleepTimerChoice.Off -> playback.setSleepTimer(null)
        is SleepTimerChoice.Minutes -> playback.setSleepTimer(choice.minutes.minutes)
        SleepTimerChoice.EndOfTrack -> playback.setSleepTimer(null, endOfTrack = true)
    }

    /** The volume slider moves: heard at once, kept only by [commitVolume]. */
    fun previewVolume(volume: Double) {
        scope.launch { playback.setVolume(volume.coerceIn(0.0, 100.0), persist = false) }
    }

    fun commitVolume(volume: Double) {
        scope.launch { playback.setVolume(volume.coerceIn(0.0, 100.0)) }
    }

    /** A queue row tapped: it plays. */
    fun jumpTo(index: Int) {
        scope.launch { playback.jumpTo(index) }
    }

    fun removeAt(index: Int) = playback.removeAt(index)

    fun reorder(from: Int, to: Int) {
        if (from != to) playback.reorder(from, to)
    }

    fun clearUpcoming() = playback.clearUpcoming()

    /** The artist line: the current track's artist opens. */
    fun openArtist() {
        val track = currentTrack ?: return
        val serverId = track.serverId ?: return
        val artistId = track.grandparentId ?: return
        screens.openArtist(serverId, artistId)
    }

    fun close() {
        keySeek.dispose()
        scope.cancel()
    }

    private fun onState(music: MusicState) {
        val track = music.currentTrack
        if (track == null) {
            mutableState.value = mutableState.value.copy(track = null, status = music.status)
            if (!closed) {
                closed = true
                screens.closeNowPlaying()
            }
            return
        }
        val backend = screens.backend(track.serverId)
        if (track.globalKey != trackKey) {
            // A new track: a pending D-pad seek belonged to the old one, the bar starts from 0 at once.
            keySeek.cancel()
            resetStepSeek()
            trackKey = track.globalKey
            livePosition = Duration.ZERO
            lyrics = null
            lyricsKey = null
            lyricsJob?.cancel()
            mutableState.value = mutableState.value.copy(lyrics = LyricsUi.Loading)
            mutableActiveLine.value = -1
        }
        currentTrack = track
        mutableState.value = mutableState.value.copy(
            track = track.toTrackUi(backend),
            playingFrom = playingFromTitle(track, music.playContext)?.let { T.music.playingFrom(it) },
            status = music.status,
            shuffled = music.shuffled,
            repeatMode = music.repeatMode,
            canGoPrevious = music.canGoPrevious,
            canGoNext = music.canGoNext,
            queue = QueueUi(
                rows = trackRows(music.queue, showArtist = true, showTrackNumber = false, dimmedBefore = music.currentIndex).mapIndexed { index, row ->
                    val item = music.queue[index]
                    row.copy(artwork = screens.backend(item.serverId).squareArtwork(item))
                },
                currentIndex = music.currentIndex,
                count = T.music.trackCount(music.queue.size),
                shuffled = music.shuffled,
                repeatMode = music.repeatMode,
            ),
            sleepTimer = sleepTimerOptions(music, screens.sleepTimerMinutes.value),
        )
        publishProgress()
        loadLyrics()
    }

    /** Loads the current track's lyrics while the pane shows, once per track for the screen's life. */
    private fun loadLyrics() {
        val track = currentTrack ?: return
        if (!mutableState.value.showLyrics || lyricsKey == track.globalKey) return
        lyricsKey = track.globalKey
        lyricsJob?.cancel()
        val pending = lyricsCache.getOrPut(track.globalKey) { scope.async { playback.fetchLyrics(track) } }
        mutableState.value = mutableState.value.copy(lyrics = LyricsUi.Loading)
        lyricsJob = scope.launch {
            val fetched = try {
                pending.await()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Lyrics of ${track.globalKey} failed" }
                null
            }
            if (track.globalKey != trackKey) return@launch
            lyrics = fetched
            mutableState.value = mutableState.value.copy(
                lyrics = if (fetched == null || fetched.isEmpty) LyricsUi.None else LyricsUi.Lines(fetched.lines.map { it.text.ifEmpty { "…" } }, fetched.synced),
            )
            publishProgress()
        }
    }

    private fun publishProgress() {
        val duration = playback.state.value.duration ?: Duration.ZERO
        val position = (keySeek.pendingPosition ?: livePosition).coerceIn(Duration.ZERO, duration.coerceAtLeast(Duration.ZERO))
        mutableProgress.value = MusicProgress(if (duration > Duration.ZERO) position else Duration.ZERO, duration)
        val lines = lyrics?.takeIf { it.synced }?.lines
        mutableActiveLine.value = if (lines == null) -1 else activeLyricLine(lines, livePosition.inWholeMilliseconds)
    }

    private fun resetStepSeek() {
        seekDirection = null
        seekRepeats = 0
    }

    private companion object {
        const val TAG = "NowPlaying"
        val SEEK_STEP = 10.seconds
    }
}
