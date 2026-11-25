package com.edde746.plezy.presentation.player

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.session.PlayerSession
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * What the OS media controls show for the current playback (the platform only renders it): Android's
 * media session and its notification, Windows' SMTC, Apple's `MPNowPlayingInfoCenter`, Linux's MPRIS; and, on the
 * desktop and the Mac, Discord's Rich Presence ([DiscordActivity]).
 *
 * Published on the changes that matter to those controls, never per frame ([MediaControls]): while [status] is
 * [NowPlayingStatus.PLAYING] the OS advances the position itself from [positionSeconds] at [rate], counting from when
 * it received this value; a seek or a drift publishes again.
 *
 * @param subtitle the secondary line: the episode (`S1E2 · Pilot`), or null for a movie.
 * @param artworkUrl an absolute http(s) image: the episode's thumbnail, else the backdrop, else the poster; or null.
 * @param durationSeconds 0 while unknown.
 * @param rate the playback speed (1.0 is normal speed).
 * @param canSeek the OS may offer a seek bar ([MediaCommand.SeekTo]): the file is open, its duration known, it isn't
 *   live, and this device may control playback.
 * @param canSkipNext the OS may offer next ([MediaCommand.Next]), exactly while there is an entry after the one playing
 *   that this device may start: a video's next button ([PlayerUiState.episodes]), live the next channel, music the
 *   queue's next track (the first under repeat-all).
 * @param canSkipPrevious the OS may offer previous ([MediaCommand.Previous]), as [canSkipNext] for the entry before.
 * @param live the playback is live, with a rewind window or without ([PlayerUiState.mode]): the OS shows a live stream,
 *   with no seek bar.
 * @param posterUrl an absolute http(s) image of the title's poster (an episode's series poster), or null: the image
 *   Discord shows.
 * @param kind video or a music track: music shows [album] and square artwork (never in-track skip on Apple), and is a
 *   music session to the OS (Windows' SMTC playback type).
 * @param album the track's album, for [NowPlayingKind.MUSIC]; [subtitle] is then the artist.
 * @param backgroundPlayback the playback goes on while the app is in the background: Android keeps its foreground
 *   service up while playing. Music sets it (on a car only when the vehicle reports restrictions).
 * @param canPlayPause the OS may offer play and pause: this device may control playback.
 * @param canSkip the OS may offer in-track skips ([MediaCommand.SeekBy]: Apple's skip buttons, which a video shows in
 *   place of next and previous, and Android's fast forward and rewind; a video's are of the player's seek step): this
 *   device may control playback, and it isn't live without a rewind window.
 * @param skipSeconds a video's in-track skip step, the player's small seek step ([PlayerUiState.seekSeconds]): the
 *   interval the OS's skip buttons show; 0 for music.
 * @param canSetSpeed the OS may change the speed ([MediaCommand.SetSpeed]): not live, and this device may control
 *   playback.
 */
data class NowPlaying(
    val title: String,
    val subtitle: String?,
    val artworkUrl: String?,
    val durationSeconds: Double,
    val positionSeconds: Double,
    val rate: Double,
    val status: NowPlayingStatus,
    val canSeek: Boolean,
    val canSkipNext: Boolean,
    val canSkipPrevious: Boolean,
    val live: Boolean,
    val posterUrl: String? = null,
    val kind: NowPlayingKind = NowPlayingKind.VIDEO,
    val album: String? = null,
    val backgroundPlayback: Boolean = false,
    /** The server's item playing (its kind, titles, numbers, artwork paths): Discord's lines and poster; null for a URL. */
    val item: MediaItem? = null,
    val canPlayPause: Boolean = true,
    val canSkip: Boolean = false,
    val canSetSpeed: Boolean = false,
    val skipSeconds: Double = 0.0,
) {
    /** The playback plays, or plays as soon as it has the data: the OS shows a pause button. */
    val playing: Boolean get() = status == NowPlayingStatus.PLAYING || status == NowPlayingStatus.BUFFERING

    companion object {
        /**
         * The media controls' view of the player: [ui] (the store's state: title, status, live, what this device may
         * do), [timeline] (the position and duration), the session's [info] (the artwork, the episodes, channels and
         * queue around the video) and [engine] (the speed).
         */
        fun of(ui: PlayerUiState, timeline: TimelineState, info: SessionInfo, engine: EngineState): NowPlaying {
            val live = ui.mode != PlaybackMode.VIDEO
            val navigates = ui.watch?.canChangeEpisode != false
            return NowPlaying(
                title = ui.title,
                subtitle = ui.subtitle,
                artworkUrl = info.artworkUrl?.webImage(),
                durationSeconds = timeline.durationSeconds.coerceAtLeast(0.0),
                positionSeconds = timeline.positionSeconds.coerceAtLeast(0.0),
                rate = engine.speed,
                status = when (ui.status) {
                    PlaybackStatus.RESOLVING, PlaybackStatus.OPENING, PlaybackStatus.BUFFERING -> NowPlayingStatus.BUFFERING
                    PlaybackStatus.PLAYING -> NowPlayingStatus.PLAYING
                    PlaybackStatus.PAUSED -> NowPlayingStatus.PAUSED
                    PlaybackStatus.ENDED, PlaybackStatus.FAILED -> NowPlayingStatus.STOPPED
                },
                canSeek = !live && ui.seekable && ui.canControl,
                canSkipNext = if (live) navigates && info.nextEpisode != null else ui.episodes?.next == true,
                canSkipPrevious = if (live) navigates && info.hasPreviousEpisode else ui.episodes?.previous == true,
                live = live,
                posterUrl = info.posterUrl?.webImage(),
                item = info.item,
                canPlayPause = ui.canControl,
                canSkip = ui.canControl && ui.mode != PlaybackMode.LIVE,
                canSetSpeed = !live && ui.canControl,
                skipSeconds = ui.seekSeconds.toDouble(),
            )
        }

        private fun String.webImage(): String? = takeIf { it.startsWith("https://") || it.startsWith("http://") }
    }
}

enum class NowPlayingKind { VIDEO, MUSIC }

enum class NowPlayingStatus {
    /** Waiting for data (the stream resolves, the file opens, the cache refills); it plays once it has it. */
    BUFFERING,
    PLAYING,
    PAUSED,

    /** The video ended or failed: nothing plays until the user acts in the app. */
    STOPPED,
}

/**
 * What the OS media controls can ask of the playback: their buttons, media keys, headsets, the lock screen; and the
 * system's own stops of the playback ([SystemPause], [SystemResume]).
 */
sealed interface MediaCommand {
    data object Play : MediaCommand
    data object Pause : MediaCommand
    data object TogglePause : MediaCommand

    /** The system stopped the playback: Android's audio focus lost, the audio output gone ([PlayerCommand.SystemPause]). */
    data object SystemPause : MediaCommand

    /** Android's audio focus back after a transient loss ([PlayerCommand.SystemResume]). */
    data object SystemResume : MediaCommand

    /** Seek to [seconds] from the start (the OS's seek bar). */
    data class SeekTo(val seconds: Double) : MediaCommand

    /**
     * Seek by [seconds] from the shown position; negative goes back (skip buttons, fast forward and rewind). A video
     * moves by its player's own seek step in that direction, whatever interval the OS gives ([PlayerCommand.Skip]).
     */
    data class SeekBy(val seconds: Double) : MediaCommand

    /** Play at [speed] (the OS's playback rate control), when [NowPlaying.canSetSpeed]. */
    data class SetSpeed(val speed: Double) : MediaCommand

    /** Play the next episode, when [NowPlaying.canSkipNext]. */
    data object Next : MediaCommand

    /** Play the previous episode, when [NowPlaying.canSkipPrevious]. */
    data object Previous : MediaCommand

    /** Leave the player. */
    data object Stop : MediaCommand
}

/** Takes the OS's [MediaCommand]s for one playback ([MediaControls]). Main thread. */
interface MediaCommandHandler {
    fun perform(command: MediaCommand)
}

/**
 * The OS media controls, implemented once per app by each platform (Android media session, SMTC,
 * `MPNowPlayingInfoCenter` with `MPRemoteCommandCenter`, MPRIS). One playback at a time uses it ([MediaControls]).
 * Called on the main thread.
 */
interface MediaControlsHost {
    /**
     * Shows [nowPlaying]: the first call of a playback puts the controls up, the next ones update them. Until [hide],
     * the OS's commands go to [commands] (the same handler for every call of one playback).
     */
    fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler)

    /** The playback ended: the controls go away and take no more commands. */
    fun hide()

    /**
     * The viewer paused (the player's own controls, keys or the OS's; never the system's [MediaCommand.SystemPause]):
     * Android's audio focus no longer resumes a transient loss on the gain.
     */
    fun userPaused() {}
}

/**
 * One playback's link to the OS media controls: publishes [NowPlaying] from the player [store] and the [session] to
 * the [host], and turns the OS's commands into the store's [PlayerCommand]s, so they act exactly like the player's
 * own buttons (pending pause, seek clamping, up-next).
 *
 * Throttled: a new value goes out when anything but the position changes, or when the position leaves where the OS
 * extrapolates it (a seek, a stall) by more than [DRIFT_SECONDS]; normal playback publishes nothing.
 *
 * Main thread; [release] hides the controls, [suspend] hides them while the app is away ([PlayerLifecycle]).
 */
class MediaControls internal constructor(
    private val store: PlayerStore,
    private val session: PlayerSession,
    private val host: MediaControlsHost,
    parentScope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) : MediaCommandHandler {
    private val scope = parentScope.childScope()

    /** What the controls show now: the last value published, or null before the first. */
    var nowPlaying: NowPlaying? = null
        private set
    private var publishedAt: TimeMark? = null
    private var released = false
    private var suspended = false

    /** The latest value, published or not (held while [suspend]ed). */
    private var latest: NowPlaying? = null

    init {
        scope.launch {
            combine(store.state, store.timeline, session.info, session.engineState) { ui, timeline, info, engine -> NowPlaying.of(ui, timeline, info, engine) }
                .collect(::onNowPlaying)
        }
        scope.launch { store.userPauses.collect { host.userPaused() } }
    }

    override fun perform(command: MediaCommand) {
        // While suspended only the system's stops come through (the app swiped away, the output gone).
        if (released || suspended && command != MediaCommand.Stop && command != MediaCommand.SystemPause) return
        store.dispatch(
            when (command) {
                MediaCommand.Play -> PlayerCommand.Play
                MediaCommand.Pause -> PlayerCommand.Pause
                MediaCommand.TogglePause -> PlayerCommand.TogglePause
                MediaCommand.SystemPause -> PlayerCommand.SystemPause
                MediaCommand.SystemResume -> PlayerCommand.SystemResume
                is MediaCommand.SeekTo -> PlayerCommand.SeekTo(command.seconds)
                is MediaCommand.SeekBy -> PlayerCommand.Skip(forward = command.seconds >= 0)
                // A live stream's speed doesn't change, nor a guest's: a stray request does nothing.
                is MediaCommand.SetSpeed -> if (nowPlaying?.canSetSpeed == true) PlayerCommand.SetSpeed(command.speed) else return
                MediaCommand.Next -> PlayerCommand.NextEpisode
                MediaCommand.Previous -> PlayerCommand.PreviousEpisode
                MediaCommand.Stop -> PlayerCommand.Close
            },
        )
    }

    /** The playback ended: the controls go away. */
    fun release() {
        if (released) return
        released = true
        scope.cancel()
        if (nowPlaying != null) host.hide()
        nowPlaying = null
    }

    /** The app went to the background: the controls go, and a command that still arrives is ignored, until [resume]. */
    fun suspend() {
        if (released || suspended) return
        suspended = true
        if (nowPlaying != null) host.hide()
        nowPlaying = null
    }

    /** The app is back: the controls show what plays now and take commands again. */
    fun resume() {
        if (released || !suspended) return
        suspended = false
        latest?.let(::onNowPlaying)
    }

    private fun onNowPlaying(next: NowPlaying) {
        latest = next
        if (suspended) return
        val last = nowPlaying
        val elapsed = publishedAt?.elapsedNow()?.inWholeMilliseconds?.div(1000.0) ?: 0.0
        if (last != null && !changed(last, elapsed, next)) return
        nowPlaying = next
        publishedAt = timeSource.markNow()
        host.show(next, this)
    }

    internal companion object {
        /** How far the position may stray from the OS's extrapolation before it is published again. */
        const val DRIFT_SECONDS = 1.0

        /** Whether [next] differs from [last], published [elapsedSeconds] ago, in anything the OS can't work out itself. */
        fun changed(last: NowPlaying, elapsedSeconds: Double, next: NowPlaying): Boolean {
            if (last.copy(positionSeconds = next.positionSeconds) != next) return true
            val advanced = if (last.status == NowPlayingStatus.PLAYING) elapsedSeconds * last.rate else 0.0
            return abs(next.positionSeconds - (last.positionSeconds + advanced)) > DRIFT_SECONDS
        }
    }
}
