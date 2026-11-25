package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.input.InputContext
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.playback.mpv.MpvLifecycle
import com.edde746.plezy.playback.session.LiveWindow
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlin.time.DurationUnit
import kotlin.time.TimeMark

/**
 * Everything the player screen shows, already formatted (views never format), but the timeline: the position, the
 * times, the bar's fill and a scrub's preview change several times a second as the video plays, so they are a flow of
 * their own ([PlayerStore.timeline], [TimelineState]) that only the views drawing them follow, and this changes only as
 * something happens. Static labels (button names) come from `T.player` directly, a menu's title from [menuTitle].
 *
 * @param status what the playback is doing; [loadingText] is the spinner's text while it is loading.
 * @param paused the play/pause button's state; [playPauseLabel] names its action ("Pause" while playing).
 * @param controlsVisible the controls are up: the title and Back, and with [showsPlaybackControls] the rest of them.
 * @param mode a video, live, or live with a rewind window ([PlaybackMode]): what the timeline and the transport show
 *   ([showsTimeline], [showsSeekButtons]).
 * @param seekable the timeline can scrub and seek: a file whose duration is known, or a live window; [canSeek] where
 *   this device may too.
 * @param scrubbing the viewer scrubs: the timeline shows the preview ([TimelineState.scrub]) in place of the position.
 * @param subtitleTracks starts with the "Off" entry; the subtitle's row is [TrackItem.selected], the second subtitle's
 *   [TrackItem.second] ([PlayerCommand.ToggleSecondSubtitle]).
 * @param moreSubtitles the subtitles found for the file but not added to it, by language ([PlayerMenu.MORE_SUBTITLES]):
 *   the languages the subtitle menu already has first, then the others by name, subtitles without a language code
 *   last. The subtitle menu offers them after its tracks while there are any.
 * @param subtitleLanguage the language whose page is open ([PlayerMenu.SUBTITLE_LANGUAGE]); null on any other menu.
 * @param speedLabel the current speed ("Normal", "1.5×").
 * @param customSpeed the custom speed's control ([PlayerMenu.CUSTOM_SPEED]) at the current speed.
 * @param episodes the controls' previous and next episode buttons, for an episode of a series; null for a movie.
 * @param options the player's options ([PlayerMenu.OPTIONS]), in order: the speed, the zoom, version and quality (with
 *   a choice), the sleep timer, HDR (where the engine controls it), auto-play of the next episode (with one), shaders
 *   (where the platform has them), the playback info, file info (where the server has it) and watch together (where
 *   the app offers it). The fit is [videoFit].
 * @param audioOptions the audio menu's settings ([PlayerMenu.AUDIO]), after its tracks and the audio delay: the audio
 *   output (where the platform offers several), how the system renders the audio (where it says), loudness
 *   normalization and the audio channels.
 * @param prompt the prompt button while it shows: the skip button (an intro, a recap, the credits) or up next, one at a
 *   time ([PlayerPrompt]).
 * @param stillWatching the sleep timer's question, once it ran out.
 * @param error the error screen; the controls stay up under it, as the title and Back alone ([showsPlaybackControls]).
 * @param osd a transient message (volume, speed, delay, zoom, track changes by key, the room's toasts), or null.
 * @param level the level an edge swipe changes (the brightness on the left, the volume on the right), while it does
 *   and a moment after, in the transient message's place: one of the two shows at a time.
 * @param heldSpeed the speed a finger held on the video plays at ("2×"), for as long as it is held.
 * @param lockLabel the top bar's lock button ([PlayerCommand.LockScreen]) on a touch screen; null where the player
 *   offers no screen lock (mouse, remote).
 * @param screenLock the screen lock while it is on; null unlocked.
 * @param watch Watch Together in the player while in a room: the room pill, the session sheet ([PlayerMenu.WATCH_TOGETHER]),
 *   the prompts, whether this device may control playback; null outside a room.
 * @param keepAwake the display stays awake (no dimming, screen saver or lock): while the video plays, or opens or buffers
 *   unpaused, in the window, fullscreen or picture in picture. Not while it is paused, at its end or failed, while the
 *   player is out of sight outside picture in picture (minimized, hidden, the app in the background), nor once the
 *   player closed. Each platform holds one display-sleep assertion while it is true (`PlatformPlayback.keepDisplayAwake`).
 * @param hdrPicture an HDR video goes out as HDR ([com.edde746.plezy.playback.EngineState.outputDynamicRange]; not
 *   one tone-mapped to SDR, nor an SDR video in an HDR output, whose white is SDR white): the video behind the controls
 *   can be several times as bright as their white, so what they draw behind themselves goes through [ControlsScrim].
 * @param sourceAudioTracks the server's audio tracks, the tracks sheet's audio column in place of [audioTracks] while
 *   the server transcodes (or the file's audio comes from the server) and the source has more than one; empty
 *   otherwise ([PlayerCommand.SelectSourceTrack]).
 * @param versions the version and quality sheet ([PlayerMenu.VERSIONS]); null when there is nothing to choose (one
 *   version and no transcoding, live, a download).
 * @param chapters the chapter sheet's and the content strip's chapters, with their thumbnails; empty without chapters.
 * @param previousChapterTitle / [nextChapterTitle] the title of the chapter the previous and next chapter buttons seek
 *   to from the position now (their tooltip); null without one that way (the previous one before the first chapter:
 *   the start of the video).
 * @param subtitlesHidden the subtitle shortcut hid the subtitles: the tracks button shows subtitles off.
 * @param queue the queue sheet's and the content strip's entries (a play queue, the season, a playlist); empty without.
 * @param subtitleSearch the subtitle search sheet ([PlayerMenu.SUBTITLE_SEARCH]); null where the server has none (only
 *   Plex has it).
 * @param fileInfo the file info page ([PlayerMenu.FILE_INFO]) once it was opened; null before, and where the item has
 *   no file info (live).
 * @param osdIcon the icon of [osd]'s toast, when it has one.
 * @param transportFlash the play or pause glyph that flashes in the middle when a play or pause by the viewer lands
 *   while the controls are hidden.
 * @param skipBadge the double-tap or hidden-controls seek's badge: the seconds moved in one direction, summed while it
 *   shows.
 * @param rotationLocked the rotation lock button's state on a phone or tablet (locked to landscape); null elsewhere.
 * @param alwaysOnTop the always-on-top button's state on Windows and Linux; null elsewhere.
 * @param settingsHighlighted the settings button is drawn amber: the picture is zoomed or a shader runs.
 * @param sleepTimer the active sleep timer's banner in its sheet; null while none runs.
 * @param chromeHiddenAtStart the controls start hidden (on TV, the first D-pad press raises them).
 * @param videoFit the aspect button: the picture's fit ([PlayerOption.value] its name) and its choices, which the button
 *   cycles through ([PlayerCommand.SetVideoFit]).
 * @param choice the session's question over the video ([SessionInfo.choice]); null while there is none.
 * @param playbackInfo the playback info while it is on ([PlayerCommand.ToggleInfo], kept for the players to come; not in
 *   picture in picture); its sections come apart ([PlayerStore.playbackInfo]).
 * @param playPauseFocus a new value each time a key brought the controls up for a remote or a keyboard to move through
 *   (up or down with them down, Select, Tab, a direction on the player itself): Play/Pause takes focus then, unless a
 *   menu is open.
 * @param seekSeconds the small seek step in whole seconds (the Small Skip Duration setting): the seek buttons' step,
 *   icon and label, and the system media controls' skip interval.
 */
data class PlayerUiState(
    val title: String,
    val subtitle: String?,
    val status: PlaybackStatus,
    val loadingText: String?,
    val paused: Boolean,
    val playPauseLabel: String,
    val controlsVisible: Boolean,
    val mode: PlaybackMode,
    val seekable: Boolean,
    val scrubbing: Boolean,
    val menu: PlayerMenu?,
    val audioTracks: List<TrackItem>,
    val subtitleTracks: List<TrackItem>,
    val moreSubtitles: List<SubtitleLanguage> = emptyList(),
    val subtitleLanguage: SubtitleLanguage? = null,
    val customSpeed: SpeedControl,
    val speedLabel: String,
    val subtitleDelay: DelayState,
    val audioDelay: DelayState,
    val volume: VolumeState,
    val episodes: EpisodeButtons?,
    val options: List<PlayerOption>,
    val audioOptions: List<PlayerOption> = emptyList(),
    val prompt: PlayerPrompt?,
    val stillWatching: StillWatchingState?,
    val error: ErrorState?,
    val osd: String?,
    val level: LevelIndicator? = null,
    val heldSpeed: String? = null,
    val lockLabel: String? = null,
    val screenLock: ScreenLockState? = null,
    val fullscreen: Boolean,
    val watch: PlayerWatchUi? = null,
    val keepAwake: Boolean,
    val hdrPicture: Boolean = false,
    val sourceAudioTracks: List<TrackItem> = emptyList(),
    val versions: VersionsMenu? = null,
    val chapters: List<ChapterItem> = emptyList(),
    val previousChapterTitle: String? = null,
    val nextChapterTitle: String? = null,
    val subtitlesHidden: Boolean = false,
    val queue: List<QueueItem> = emptyList(),
    val subtitleSearch: SubtitleSearchState? = null,
    val fileInfo: FileInfoState? = null,
    val osdIcon: OsdIcon? = null,
    val transportFlash: TransportFlash? = null,
    val skipBadge: SkipBadge? = null,
    val rotationLocked: Boolean? = null,
    val alwaysOnTop: Boolean? = null,
    val settingsHighlighted: Boolean = false,
    val sleepTimer: SleepTimerBanner? = null,
    val chromeHiddenAtStart: Boolean = false,
    val videoFit: PlayerOption? = null,
    val choice: ChoiceState? = null,
    val playbackInfo: PlaybackInfoState? = null,
    val playPauseFocus: Int = 0,
    val seekSeconds: Int = 10,
) {
    /** The option whose page [menu] is, if it is one: of the options, the audio settings or the fit. */
    val openOption: PlayerOption?
        get() = menu?.let { open ->
            options.firstOrNull { it.page == open } ?: audioOptions.firstOrNull { it.page == open } ?: videoFit?.takeIf { it.page == open }
        }

    /**
     * [menu]'s title, the same in every view: a delay's name ([DelayState.title]), the language of a subtitle
     * language's page ([subtitleLanguage]; More subtitles while none is open), an option page's option's name.
     */
    fun menuTitle(menu: PlayerMenu): String = when (menu) {
        PlayerMenu.AUDIO -> T.player.menu.audio
        PlayerMenu.SUBTITLES -> T.player.menu.subtitles
        PlayerMenu.SPEED -> T.videoSettings.playbackSpeed
        PlayerMenu.CUSTOM_SPEED -> T.player.speed.customTitle
        PlayerMenu.SUBTITLE_DELAY -> subtitleDelay.title
        PlayerMenu.AUDIO_DELAY -> audioDelay.title
        PlayerMenu.MORE_SUBTITLES -> T.player.menu.moreSubtitles
        PlayerMenu.SUBTITLE_LANGUAGE -> subtitleLanguage?.label ?: T.player.menu.moreSubtitles
        PlayerMenu.OPTIONS -> T.videoControls.settingsButton
        PlayerMenu.VIDEO_FIT -> T.player.options.videoFit
        PlayerMenu.ZOOM -> T.player.options.zoom
        PlayerMenu.SHADERS -> T.player.options.shaders
        PlayerMenu.SLEEP_TIMER -> T.player.options.sleepTimer
        PlayerMenu.AUDIO_CHANNELS -> T.player.options.audioChannels
        PlayerMenu.AUDIO_OUTPUT -> T.player.options.audioOutput
        PlayerMenu.WATCH_TOGETHER -> T.watchTogether.title
        PlayerMenu.TRACKS -> when {
            !showsAudioMenu -> T.videoControls.subtitlesLabel
            !showsSubtitleMenu -> T.videoControls.audioLabel
            else -> T.videoControls.tracksButton
        }
        PlayerMenu.SUBTITLE_SEARCH -> T.videoControls.searchSubtitles
        PlayerMenu.VERSIONS -> T.videoControls.versionQualityButton
        PlayerMenu.FILE_INFO -> T.fileInfo.title
        PlayerMenu.CHAPTERS -> T.videoControls.chapters
        PlayerMenu.QUEUE -> T.videoControls.queue
        // The page of both, named for the list it opens on: the queue where there are no chapters.
        PlayerMenu.CONTENT_STRIP -> if (chapters.isEmpty() && queue.isNotEmpty()) T.videoControls.queue else T.videoControls.chapters
        PlayerMenu.DOLBY_VISION_CONVERSION -> T.settings.dvConversionMode
        PlayerMenu.HTTP_STATUS -> PlayerOptions.HTTP_STATUS_LABEL
    }

    /**
     * The entry [menu] opens on, by its index in its list: the selected audio or subtitle track, speed, language
     * page's subtitle or option page's choice; 0 (the first) where none is selected, and in the other menus.
     */
    val selectedEntry: Int
        get() = when (menu) {
            PlayerMenu.AUDIO -> audioTracks.indexOfFirst { it.selected }
            PlayerMenu.SUBTITLES -> subtitleTracks.indexOfFirst { it.selected }
            PlayerMenu.SUBTITLE_LANGUAGE -> subtitleLanguage?.subtitles?.indexOfFirst { it.selected } ?: 0
            else -> openOption?.choices?.indexOfFirst { it.selected } ?: 0
        }.coerceAtLeast(0)

    /** Play, pause, seeking and the speed are this device's to change: not a guest's in a host-only room. */
    val canControl: Boolean get() = watch?.canControl ?: true

    /** The timeline shows: for a video and a live window; live without one, the live label in its place. */
    val showsTimeline: Boolean get() = mode != PlaybackMode.LIVE

    /** Back and forward show beside play/pause: for a video; live, the live label after play/pause in their place. */
    val showsSeekButtons: Boolean get() = mode == PlaybackMode.VIDEO

    /** The timeline scrubs and seeks here: it can ([seekable]) and this device may ([canControl]). */
    val canSeek: Boolean get() = seekable && canControl

    /**
     * Play/pause is this device's to press: where it may control playback, and for a guest whose player paused here
     * alone ([PlayerWatchUi.pausedHere]), whose Play catches up with the room.
     */
    val canPlayPause: Boolean get() = canControl || watch?.pausedHere == true

    /** The audio menu's button shows: the video has an audio track. */
    val showsAudioMenu: Boolean get() = audioTracks.isNotEmpty() || sourceAudioTracks.isNotEmpty()

    /** The subtitle menu's button shows: there is a track besides Off, or a subtitle to add or search for. */
    val showsSubtitleMenu: Boolean get() = subtitleTracks.size > 1 || moreSubtitles.isNotEmpty() || subtitleSearch != null

    /**
     * The controls show more than the title and Back (where the platform's controls have them): the transport, the
     * timeline (live, the live label in its place), the menus, the playback info, picture in picture and a room's
     * indicator. Not over the error: a failed playback has nothing for them to act on, and the error's own buttons are
     * all there is to reach. Retry brings them back.
     */
    val showsPlaybackControls: Boolean get() = error == null

    /** How many subtitles [moreSubtitles] holds in all, for the subtitle menu's More subtitles entry. */
    val moreSubtitlesCount: String get() = moreSubtitles.sumOf { it.subtitles.size }.toString()

    /** What covers the middle of the video ([PlayerCentre]); null while nothing does. */
    val centre: PlayerCentre? = when {
        error != null -> PlayerCentre.Error(error)
        status.isLoading -> PlayerCentre.Loading(loadingText)
        else -> null
    }

    /**
     * Something over the video holds a TV remote, with buttons of its own to focus: the open menu, the error, the prompt
     * button, the sleep timer's question or a room's play prompt ([PlayerWatchUi.playBlocked]). The video takes no press
     * and a swipe on the remote's touch surface neither scrubs nor opens the panel meanwhile.
     */
    val remoteHeld: Boolean
        get() = menu != null || error != null || prompt != null || stillWatching != null || choice != null ||
            watch?.playBlocked != null
}

/**
 * The version and quality sheet: [versions] in the left column (hidden with fewer than two), [qualities] in the right
 * (the original, then the presets from best to worst, each labelled with its resolution and bitrate; hidden where the
 * server can't transcode). A choice not [OptionChoice.selected] reopens the video at the position.
 */
data class VersionsMenu(val versions: List<OptionChoice>, val qualities: List<OptionChoice>) {
    val showsVersions: Boolean get() = versions.size > 1
}

/**
 * A chapter as its sheet and the content strip show it: [title] (else "Chapter 3"), [start] its timecode, [imageUrl] its
 * thumbnail (a download's saved one first) or null, [current] the chapter playing. [command] seeks to it; null where this
 * device may not seek (a guest in a host-only room).
 */
data class ChapterItem(val title: String, val start: String, val imageUrl: String?, val current: Boolean, val command: PlayerCommand?)

/**
 * One entry of the queue: [key] identifies it ([PlayerCommand.PlayQueueItem]); [title] the episode's or movie's name,
 * [subtitle] the episode's code or the series; [imageUrl] the 16:9 thumbnail; [current] what plays (bold, a play icon).
 * [spoiler]: an unwatched episode under the profile's hide-spoilers setting, whose thumbnail the views blur.
 */
data class QueueItem(
    val key: String,
    val title: String,
    val subtitle: String?,
    val imageUrl: String?,
    val current: Boolean,
    val spoiler: Boolean = false,
)

/**
 * The subtitle search sheet: the [language] searched (its name, [languageCode] ISO 639-1; [languages] the choices),
 * the [title] searched, [searching] while a search runs, the [results] once one answered (each with the command that
 * downloads it), [downloading] the result being downloaded (one at a time), [message] the outcome or the failure to
 * show ("No subtitles found", "Search failed: …", "Subtitle downloaded").
 */
data class SubtitleSearchState(
    val language: String,
    val languageCode: String,
    val languages: List<OptionChoice>,
    val title: String,
    val searching: Boolean,
    val results: List<SubtitleResult>,
    val downloading: String?,
    val message: String?,
)

/** One subtitle a provider has: [label] its file name, [detail] the provider, rating and flags (forced, SDH). */
data class SubtitleResult(val key: String, val label: String, val detail: String?, val command: PlayerCommand)

/**
 * The file info page: [loading] while it loads, then the [info] of the item named [title] (the UIs draw
 * [FileInfoSections.page] of it) or the [error] ("File info not available").
 */
data class FileInfoState(val loading: Boolean, val info: MediaFileInfo?, val title: String, val error: String?)

/** The icon of a toast ([PlayerUiState.osdIcon]). */
enum class OsdIcon { FAST_FORWARD, SLOW_MOTION, VOLUME_UP, VOLUME_DOWN, VOLUME_OFF, SCREENSHOT, SUBTITLES, AUDIO, ZOOM }

/** The middle play/pause flash: the glyph of what happened ([paused]: the pause glyph); [serial] tells two flashes apart. */
data class TransportFlash(val paused: Boolean, val serial: Int)

/**
 * The seek badge: [forward] or back, [label] the seconds summed in that direction ("30"), on the side it went; [serial]
 * restarts its fade each time it stacks. Both UIs place it by its companion's [inset].
 */
data class SkipBadge(val forward: Boolean, val label: String, val serial: Int) {
    companion object {
        /** The width the readout keeps for itself: the chevron and a few characters at its largest. */
        private const val MIN_READOUT_WIDTH = 200f

        /**
         * The badge's inset from the side it sits on, for a player [width] wide (dp, points): 60, on TV 5 % of the
         * width from 60 to 160 (inside the overscan), and never so much that a narrow player leaves no room for it.
         */
        fun inset(width: Float, tv: Boolean): Float {
            val overscan = if (tv) (width * 0.05f).coerceIn(60f, 160f) else 60f
            return overscan.coerceIn(0f, ((width - MIN_READOUT_WIDTH) / 2).coerceAtLeast(0f))
        }
    }
}

/**
 * The active sleep timer's banner: [text] "Playback will pause in 12:30" or "… at the end of this video"; [extend]
 * "+15 min" while it counts down ([PlayerCommand.ExtendSleepTimer]), null at the end of the video.
 */
data class SleepTimerBanner(val text: String, val extend: String?)
/**
 * What covers the middle of the video, one at a time, the first that applies: the error panel ([PlayerUiState.error]),
 * the loading spinner with [PlayerUiState.loadingText] while the playback loads ([PlaybackStatus.isLoading]).
 */
sealed interface PlayerCentre {
    data class Error(val error: ErrorState) : PlayerCentre
    data class Loading(val text: String?) : PlayerCentre
}

/**
 * The previous and next buttons beside the transport: both show for every episode of a series and every item of a
 * queue, each enabled while there is an entry that way that this device may start: in the queue shown when there is
 * one, else as the session found it (not at the series' ends, and in a watch-together room the host's only,
 * [PlayerWatchUi.canChangeEpisode]). [PlayerStates.episodeButtons] has the rule.
 * @param previousRestarts Previous starts what plays again rather than the entry before: past the first seconds
 *   ([com.edde746.plezy.playback.queue.RESTART_BEFORE_PREVIOUS_SECONDS]), as every player's Previous does. Its name
 *   ([previousLabel]) says so: "Restart" then.
 * @param episode what plays is an episode: the buttons are named "Previous episode" and "Next episode"; for anything
 *   else (a movie in a shuffled queue, a playlist's video) plain "Previous" and "Next".
 */
data class EpisodeButtons(val previous: Boolean, val next: Boolean, val previousRestarts: Boolean = false, val episode: Boolean = true) {
    val previousLabel: String
        get() = when {
            previousRestarts -> T.videoControls.restartButton
            episode -> T.videoControls.previousButton
            else -> T.videoControls.previousItemButton
        }
    val nextLabel: String get() = if (episode) T.videoControls.nextButton else T.videoControls.nextItemButton
}

/** What plays, as the timeline and the transport show it. */
enum class PlaybackMode {
    /** A file: the timeline with its times, back and forward. */
    VIDEO,

    /** Live ([SessionInfo.live]) without a rewind window: the live label in the timeline's place, nothing to seek. */
    LIVE,

    /**
     * Live with a rewind window ([LiveWindow]): the timeline is the window, from its start to the live edge, and seeks
     * within it; the live label after play/pause goes to live; no back or forward.
     */
    LIVE_WINDOW,
}

enum class PlaybackStatus {
    /** The session is still getting the video's playable URL from its server. */
    RESOLVING,

    /** The engine is opening the file: no frame yet. */
    OPENING,

    /** The engine waits (for data, or a seek's landing) and has for half a second; a shorter wait stays [PLAYING]. */
    BUFFERING,
    PLAYING,
    PAUSED,

    /** The video played to its end and nothing plays next. */
    ENDED,
    FAILED,
    ;

    val isLoading: Boolean get() = this == RESOLVING || this == OPENING || this == BUFFERING
}

/**
 * The timeline as the controls draw it ([PlayerStore.timeline]), for each [PlaybackMode].
 *
 * @param position / [duration] timecodes (`12:34`, `1:02:03`); [remaining] is the time left (`−49:29`).
 * @param positionLabel both together (`12:34 / 1:02:03`); live, the spoken live text (`Live`, `Live · 0:40 behind`).
 * @param progress / [buffered] fractions of the duration (0–1) for the bar and its cache fill: [progress] the position
 *   as last reported, which a bar that moves at each frame draws as [progressNow]; [buffered] where what the engine
 *   read ahead ends, never short of the position, at the end once it read the file's end.
 * @param chapters chapter starts as fractions of the duration, for the bar's marks.
 * @param positionSeconds / [durationSeconds] the raw numbers, for accessibility values and test harnesses.
 * @param liveLabel live, the live label's text: LIVE, with a live window behind its edge how far behind as well
 *   (`LIVE · −0:40`); else empty. Live there is no position, duration or remaining time (empty) and no chapters.
 * @param atLiveEdge with a live window, the position is at the live edge ([LiveWindow.atEdge]): the bar full, the live
 *   label's dot red; else it is grey and the label goes to live. A window's bar runs from its start to the edge, its
 *   [position] the clock time the shown position went out live (`21:43`, now at the edge); [positionSeconds] and
 *   [durationSeconds] are the place in the window and its length, and [remaining] is empty.
 * @param behind with a live window behind the edge, how far (`−0:40`); else empty.
 * @param scrub the preview while the viewer scrubs ([PlayerUiState.scrubbing]): the bar shows it in place of
 *   [progress]; null otherwise.
 * @param hover where a mouse rests over a video's bar, not scrubbing ([PlayerCommand.HoverTimeline]): the whole second
 *   there, its thumbnail and chapter, for the bar's tooltip (its offset none); null otherwise.
 * @param motion while a video plays, how the position moves on from [positionSeconds] until the next report; null while
 *   it stands (paused, loading, at the end, a seek or a scrub under way, live), when the bar shows [progress] as it is.
 * @param endsAt "Ends at 21:43": now plus the time left at the speed, to the minute; empty when nothing remains or live.
 * @param finishClock the clock time of [endsAt] alone ("21:43"); empty with it.
 */
data class TimelineState(
    val position: String,
    val duration: String,
    val remaining: String,
    val positionLabel: String,
    val progress: Float,
    val buffered: Float,
    val chapters: List<Float>,
    val positionSeconds: Double,
    val durationSeconds: Double,
    val liveLabel: String,
    val atLiveEdge: Boolean = false,
    val behind: String = "",
    val scrub: ScrubState? = null,
    val hover: ScrubState? = null,
    val motion: PlayheadMotion? = null,
    val endsAt: String = "",
    val finishClock: String = "",
) {
    /**
     * The played fraction now, for a bar drawn at each frame: [progress] moved on by [motion] from the report to this
     * moment, never past the duration; [progress] while the position stands.
     */
    fun progressNow(): Float {
        val motion = motion ?: return progress
        if (durationSeconds <= 0.0) return progress
        return ((positionSeconds + motion.secondsMoved()) / durationSeconds).coerceIn(0.0, 1.0).toFloat()
    }
}

/**
 * The position moving on between the engine's reports ([TimelineState.motion]), which come every
 * [MpvLifecycle.POSITION_STEP] seconds of video: [speed] seconds of video a second since the report ([since], on the
 * store's clock). It moves on at most [REACH_SECONDS] past the report: a report that late means the playback stalled,
 * and the bar waits for the engine rather than run ahead of it.
 */
class PlayheadMotion internal constructor(val speed: Double, private val since: TimeMark) {
    /** Seconds of video played since the report, as the clock and [speed] say, up to [REACH_SECONDS]. */
    internal fun secondsMoved(): Double = (since.elapsedNow().toDouble(DurationUnit.SECONDS) * speed).coerceIn(0.0, REACH_SECONDS)

    internal companion object {
        /** Two of the engine's reports: one late report still moves smoothly, a stall doesn't run on. */
        const val REACH_SECONDS = 2 * MpvLifecycle.POSITION_STEP
    }
}

/**
 * @param seconds the preview; [progress] the same as a fraction of the duration.
 * @param position the preview's timecode; [offset] its distance from where the scrub started (`+1:20`, `−0:30`), empty
 *   for a hover, which starts none.
 * @param chapter the title of the chapter at the preview, when the video has named chapters.
 * @param frame the preview's thumbnail (the server's BIF or trickplay frames), or null without one.
 */
data class ScrubState(
    val seconds: Double,
    val progress: Float,
    val position: String,
    val offset: String,
    val chapter: String?,
    val frame: ScrubFrame? = null,
)

/**
 * One row of a track menu.
 * @param id the track to select; null for subtitles "Off".
 * @param label the first line: the language, else the track title, else "Track 2".
 * @param detail the second line: the title when the language took the first, flags (Forced, SDH, Default), codec,
 *   channel layout, External; null when there is nothing to add.
 * @param second a subtitle track showing as the second subtitle, at the top of the picture.
 * @param forced a forced track: the views add the Forced badge.
 */
data class TrackItem(
    val id: Long?,
    val label: String,
    val detail: String?,
    val selected: Boolean,
    val second: Boolean = false,
    val forced: Boolean = false,
)

/**
 * One language of [PlayerUiState.moreSubtitles]: its name ([label]; "Other" for subtitles that name no language by
 * code), how many subtitles it has ([count]) and those subtitles, each with the command that adds and selects it
 * ([PlayerCommand.AddSubtitle]). [key] opens its page ([PlayerCommand.OpenSubtitleLanguage]).
 */
data class SubtitleLanguage(val key: String, val label: String, val count: String, val subtitles: List<OptionChoice>)

/**
 * A level a swipe changed ([PlayerUiState.level]): the screen's brightness or the system's volume, at [fraction] (0 to
 * 1), [percent] as it shows ("40%"); [label] says it ("Brightness 40%"), for screen readers. The brightness shows at
 * the player's left edge and the volume at its right, the sides they are swiped on.
 */
data class LevelIndicator(val kind: LevelKind, val fraction: Float, val percent: String, val label: String)

enum class LevelKind { BRIGHTNESS, VOLUME }

/**
 * The locked screen ([PlayerUiState.screenLock]): the controls are hidden and a touch shield covers the player, showing
 * the unlock button at its top centre while [unlock] is not null. A tap on the shield shows or hides the button; a
 * finger or pointer held on the button ([PlayerCommand.UnlockHold]) for [UnlockButton.HOLD_MILLIS] unlocks, and a
 * screen reader's press unlocks at once ([PlayerCommand.UnlockPress]); the button hides again a few seconds after it
 * showed or was let go.
 */
data class ScreenLockState(val unlock: UnlockButton?)

/**
 * The unlock button: [label] "Hold to unlock" (a tap shows how), and while a finger or pointer holds it ([holding]) a
 * fill that grows across it from its leading edge over [HOLD_MILLIS], at whose end it unlocks.
 */
data class UnlockButton(val label: String, val holding: Boolean) {
    companion object {
        /** How long the button is held to unlock. */
        const val HOLD_MILLIS = 1000L
    }
}

/**
 * A subtitle- or audio-delay control: its entry at the end of its track menu ([title] and [label]) and its page
 * ([menu]), which shows − the delay + and Reset.
 * @param menu the page: [PlayerMenu.SUBTITLE_DELAY] or [PlayerMenu.AUDIO_DELAY].
 * @param title the control's name ("Subtitle delay"): its entry's and its page's title.
 * @param label the delay (`+0.3 s`).
 * @param decreaseLabel / [increaseLabel] − and + by the way they move the delay ("Subtitle delay: earlier"), the names
 *   screen readers say.
 * @param decrease / [increase] one step ([com.edde746.plezy.input.InputSteps.delaySeconds]) each way; [canDecrease]
 *   and [canIncrease] are false at the ends of the range.
 * @param reset back to zero. Reset shows at every delay and is enabled while the delay isn't zero ([canReset]): the
 *   control keeps its size as the delay moves, so its first step moves none of its buttons.
 * @param seconds the delay applied; [stepSeconds] one step of the sync bar's slider, its buttons and D-pad (10 ms for
 *   audio, 50 ms for subtitles); the slider runs from −[limitSeconds] to +[limitSeconds].
 */
data class DelayState(
    val menu: PlayerMenu,
    val title: String,
    val label: String,
    val decreaseLabel: String,
    val increaseLabel: String,
    val decrease: PlayerCommand,
    val increase: PlayerCommand,
    val reset: PlayerCommand,
    val canDecrease: Boolean,
    val canIncrease: Boolean,
    val canReset: Boolean,
    val seconds: Double = 0.0,
    val stepSeconds: Double = 0.05,
    val limitSeconds: Double = 10.0,
)

/**
 * The custom speed's control ([PlayerMenu.CUSTOM_SPEED]): − the speed + over a slider of the player's whole range, and
 * Normal. Each change applies at once, as a pick of a preset does.
 * @param speed the speed playing; [label] says it as a number ("2.4×", "1×").
 * @param decreaseLabel / [increaseLabel] − and +'s names, which screen readers say ("Slower", "Faster").
 * @param decrease / [increase] a [step] slower or faster; [canDecrease] and [canIncrease] are false at [min] and [max].
 * @param reset Normal: back to 1×, enabled away from it ([canReset]), so the control keeps its buttons as it moves.
 * @param min / [max] the slider's ends; [step] its grid ([snapped]) and − and +'s step.
 */
data class SpeedControl(
    val speed: Double,
    val label: String,
    val decreaseLabel: String,
    val increaseLabel: String,
    val decrease: PlayerCommand,
    val increase: PlayerCommand,
    val reset: PlayerCommand,
    val canDecrease: Boolean,
    val canIncrease: Boolean,
    val canReset: Boolean,
    val min: Double,
    val max: Double,
    val step: Double,
) {
    /** The speed the slider at [value] sets: the nearest on the [step] grid, within [min] and [max]. */
    fun snapped(value: Double): Double = PlayerStates.customSpeed(value, step, min, max)
}

/**
 * @param fraction the level as a fraction of the slider's top, [maxPercent] (0–1): [PlayerCommand.SetVolume] takes the
 *   slider's fraction times [maxPercent]; above 100 the slider marks 100 %.
 * @param label "80%", or "Muted".
 */
data class VolumeState(
    val percent: Int,
    val fraction: Float,
    val muted: Boolean,
    val label: String,
    val maxPercent: Int = 100,
)

/** Which part of the playback a section of the info is about; the views' identifiers (`player.info.<id>`) go by it. */
enum class InfoSectionId { STREAM, VIDEO, COLOR, HDR, AUDIO, SUBTITLES, PERFORMANCE, APP, BUFFER }

/** One section of the playback info: its heading ([title]) and its rows, in order. */
data class InfoSection(val id: InfoSectionId, val title: String, val rows: List<InfoRow>)

/**
 * One line of the playback info: the label ("Bitrate") and its value ("38.6 Mb/s"). A [freeText] value (a file's name, a
 * track's title, the audio output's device) may end in "…" where it doesn't fit; any other value is data (a bitrate, a
 * codec, a resolution, a size, a timing, a count), shown whole or not at all.
 */
data class InfoRow(val label: String, val value: String, val freeText: Boolean = false)

/**
 * Lays the playback info's sections out in columns, for a view with room for more than one: each section, in order,
 * goes to the column that is shortest so far (by rows, a heading counting as one), so the columns end about level and
 * each keeps its sections in reading order. A section gains its rows as the engine's stats first come; after that only
 * the last section (Buffer) gains or loses a row, and it goes where it goes by the sections before it, so live values
 * move no section to another column.
 */
object InfoColumns {
    fun split(sections: List<InfoSection>, columns: Int): List<List<InfoSection>> {
        val count = columns.coerceIn(1, sections.size.coerceAtLeast(1))
        val placed = List(count) { mutableListOf<InfoSection>() }
        val heights = IntArray(count)
        for (section in sections) {
            val shortest = heights.indices.minBy { heights[it] }
            placed[shortest] += section
            heights[shortest] += section.rows.size + 1
        }
        return placed
    }
}

/** Which of the player's options a [PlayerOption] is: the views' icons and identifiers (`player.option.<id>`) go by it. */
enum class PlayerOptionId {
    WATCH_TOGETHER,
    VIDEO_FIT,
    ZOOM,
    SHADERS,
    SLEEP_TIMER,
    AUTO_PLAY_NEXT,
    AUDIO_OUTPUT,
    AUDIO_NORMALIZATION,
    AUDIO_CHANNELS,
    SPEED,
    VERSIONS,
    HDR,
    HDR_TONE_MAPPING,
    AUDIO_RENDERING,
    AMBIENT_LIGHTING,
    PLAYBACK_INFO,
    FILE_INFO,

    /** A development build's entries ([PlayerConfig.development]). */
    DOLBY_VISION_CONVERSION,
    HTTP_STATUS,
}

/**
 * One of the player's options, as the options menu lists it: an option with a page of [choices] (the picture's fit, the
 * zoom, the shaders, the sleep timer, the audio output and channels) or a switch (auto-play next, loudness
 * normalization).
 * @param label its name ("Zoom"); [value] its state ("120%", "Fill screen", "23:41 left", "On").
 * @param adjusted away from its default (zoomed, a sleep timer set, a shader running), so a view can mark it.
 * @param page the menu its [choices] show in, opened with `OpenMenu`; null for a switch.
 * @param on a switch's state; null for an option with a page.
 * @param toggle the command that flips a switch; null for an option with a page.
 * @param importLabel the label of an entry after the [choices] ("Import shader") that opens the system's open dialog
 *   for a `.glsl` file and sends the file's name and text as [PlayerCommand.ImportShader]; null where the page has none
 *   (every other option, and the shaders on a device without file dialogs).
 */
data class PlayerOption(
    val id: PlayerOptionId,
    val label: String,
    val value: String,
    val adjusted: Boolean,
    val page: PlayerMenu?,
    val choices: List<OptionChoice>,
    val on: Boolean?,
    val toggle: PlayerCommand?,
    val importLabel: String? = null,
    /** A second line under the label: that loudness normalization turns passthrough off, where passthrough is on. */
    val detail: String? = null,
    /** What the page says while it has no [choices] ("No audio devices available"). */
    val empty: String? = null,
    /** False for an option that does nothing for this video (HDR output on an SDR one), drawn dimmed with its [detail]. */
    val enabled: Boolean = true,
    /**
     * Every form [value] can take while the menu stays open, at its widest (the sleep timer: Off, the end of the video,
     * its longest countdown), for a view that sizes the menu to its values without the width following a countdown;
     * empty where [value] changes only by a pick.
     */
    val valueForms: List<String> = emptyList(),
)

/**
 * One entry of an option's page; [command] picks it (and closes the menu).
 * @param detail a second line: what a channel limit does.
 * @param delete the command that deletes it (an imported shader), which a view sends once the viewer confirms
 *   ("Delete “Shader”?"); null for an entry that can't be deleted.
 * @param enabled false for a choice that can't be picked (a quality above the source's), drawn dimmed.
 */
data class OptionChoice(
    val label: String,
    val detail: String?,
    val selected: Boolean,
    val command: PlayerCommand,
    val delete: PlayerCommand? = null,
    val enabled: Boolean = true,
)

/**
 * The session's question over the video ([SessionInfo.choice]), drawn as the sleep timer's question is: [title] and a
 * button per option, each answering with its [OptionChoice.command] ([PlayerCommand.AnswerChoice]); Back dismisses it.
 */
data class ChoiceState(val title: String, val options: List<OptionChoice>)

/**
 * The sleep timer ran out: "Still watching?", with Keep watching and Pause. The playback pauses when the countdown does.
 * @param countdown "Pausing in 25 seconds".
 * @param secondsLeft the countdown's seconds; [progress] goes from 0 to 1 as it runs out.
 */
data class StillWatchingState(
    val countdown: String,
    val secondsLeft: Int,
    val progress: Float,
)

/**
 * The player's prompt button: the skip button or up next, one pill in the bottom trailing corner, above the controls
 * while they show, beneath the sleep timer's question when that shows too. While [progress] is set it counts down to
 * doing [command] on its own and fills from its leading edge as it does, a step every tenth of a second of played time;
 * any input on the player (a tap, a click, a pointer move, a key, a remote's press, a scrub, a menu) stops that and
 * leaves the plain button, which still does [command] when pressed. It shows while it counts down, for 8 seconds as it
 * comes up plain or stops counting, and after that with the controls ([withControls]). Back ([PlayerCommand.Back])
 * hides it: a skip button until the playback leaves the segment, up next until the position is back before where it
 * came up. Select or Enter presses it ([InputContext.prompt]); on TV it takes focus as it comes up by itself, not as it
 * comes back with the controls the viewer brought up.
 * @param kind what it does; the views' icon (fast-forward, skip-next) and identifier (`player.skip`, `player.upNext`)
 *   go by it.
 * @param lead the start of the label that is never cut short: the next episode's code and the separator ("S1E2 · ");
 *   null for the skip button, and for an episode without a name, whose code is the [text].
 * @param text the rest of the label, cut short where the button has no room for it: "Skip intro", the next episode's
 *   name ("Please Remain Calm"), or its code alone ("S1E2").
 * @param progress the countdown, 0 → 1 as it runs out; null while it doesn't count down: a skip in Show button mode,
 *   up next without auto-play, after the viewer did something, or for a segment skipped once already.
 * @param secondsLeft the countdown's whole seconds left, rounded up, while [progress] is set.
 * @param command what pressing it does: [PlayerCommand.SkipSegment] or [PlayerCommand.NextEpisode].
 * @param withControls it shows only because the controls are up: past its 8 seconds and not counting down.
 * @param imageUrl up next's card backdrop: the next episode's still (a download's saved one offline); null otherwise.
 * @param shuffled up next comes from a shuffled queue: the card shows the shuffle icon by "Next episode".
 */
data class PlayerPrompt(
    val kind: PromptKind,
    val lead: String?,
    val text: String,
    val progress: Float?,
    val secondsLeft: Int?,
    val command: PlayerCommand,
    val withControls: Boolean,
    val imageUrl: String? = null,
    val shuffled: Boolean = false,
) {
    /**
     * The button's accessibility label: the skip button's text ("Skip intro"); up next's whole text after what it does
     * ("Play the next episode: S1E2 · Please Remain Calm", the name isolated after the [lead]), which a visible
     * episode title alone doesn't say.
     */
    val label: String get() = when {
        kind != PromptKind.UP_NEXT -> text
        lead != null -> T.player.prompt.playNext(lead + isolate(text))
        else -> T.player.prompt.playNext(text)
    }

    /** The countdown as its accessibility value ("Automatically in 8 seconds"), null while it doesn't count down. */
    val countdown: String? get() = secondsLeft?.let(T.player.prompt::countdown)
}

/**
 * What a [PlayerPrompt] does: skip an intro, a recap or the credits (previews count as credits), or play the next
 * episode ([UP_NEXT]; credits to the end of an episode with a next one too).
 */
enum class PromptKind { INTRO, RECAP, CREDITS, UP_NEXT }

/**
 * The error card ([PlayerStates.error]).
 * @param buttons the card's buttons in order, each UI drawing them all as they come: Retry, Close. Exactly one is
 *   [ErrorButton.primary].
 */
data class ErrorState(
    val title: String,
    val message: String,
    val buttons: List<ErrorButton>,
) {
    /** The button every UI fills and focuses as the card shows. */
    val primary: ErrorButton get() = buttons.single { it.primary }
}

/**
 * One of the error card's buttons: [label], doing [command].
 * @param primary the card's one primary button, filled and focused: Retry.
 */
data class ErrorButton(val action: ErrorAction, val label: String, val command: PlayerCommand, val primary: Boolean)

/** What an [ErrorButton] does; the views' identifiers (`player.error.<action>`) go by it. */
enum class ErrorAction { RETRY, CLOSE, TRANSCODE }
