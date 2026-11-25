package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.format.formatTimecode
import com.edde746.plezy.input.InputContext
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.Hotkeys
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.KeySource
import com.edde746.plezy.input.Keymap
import com.edde746.plezy.input.NavigationKey
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerKeys
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.input.RoomControl
import com.edde746.plezy.input.ShortcutAction
import com.edde746.plezy.input.VideoClickAction
import com.edde746.plezy.input.roomControl
import com.edde746.plezy.input.seeks
import com.edde746.plezy.input.seeksLive
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.formatMediaTargetLabel
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.AmbientLightingController
import com.edde746.plezy.playback.CustomShader
import com.edde746.plezy.playback.Downmix
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.ShaderFile
import com.edde746.plezy.playback.ShaderFiles
import com.edde746.plezy.playback.ShaderPreset
import com.edde746.plezy.playback.files
import com.edde746.plezy.playback.runsCustomShaders
import com.edde746.plezy.playback.runsOn
import com.edde746.plezy.playback.SkipSegment
import com.edde746.plezy.playback.SkipSegments
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.playback.VideoLayout
import com.edde746.plezy.playback.queue.shouldRestartBeforePreviousItem
import com.edde746.plezy.playback.session.ExternalSubtitle
import com.edde746.plezy.playback.session.LiveWindow
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.PlayNextRetry
import com.edde746.plezy.playback.session.PlayerSession
import com.edde746.plezy.playback.session.playNextRetryPresentation
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.playback.session.SubtitleDownloadOutcome
import com.edde746.plezy.playback.session.SubtitleSearchHit
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import com.edde746.plezy.watch.RoomPlayer
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.roundToInt
import kotlin.math.roundToLong
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Clock
import kotlin.time.TimeSource

/**
 * The player screen's store: its [state], and apart from it the [timeline], which moves with the position several
 * times a second while the video plays, so that only the views drawing it follow it; both driven by the [session]'s
 * engine state and info, and intents from the views ([dispatch]) and the platform ([onInput],
 * [onTimelineFocusChanged], [onFullscreenChanged]).
 *
 * - The controls hide by themselves as [PlayerChrome] has it: 5 s after the last input on a touch screen and with a
 *   remote driving the player ([PlayerChoices.playerNavigation], on for TV), 3 s with a mouse; while paused too, but
 *   with a remote. Picture in picture, a menu or the content strip, a scrub, a pointer pressed on them, a failure,
 *   loading (no first frame) and an assistive technology that moves through them one at a time
 *   ([onAssistiveTechnologyChanged]) keep them up; the end of the file shows them.
 * - Keys ([onKey]): Back, Escape and Backspace act as they come up; a remote's left and right seek with the controls
 *   down and on a focused timeline, accelerating while held, one seek per press or hold ([SeekBurst]), up and down
 *   bring the controls up; Select presses the skip button while the controls are down, else shows them and toggles
 *   pause; the media keys play, pause and skip chapters; the rest are the keyboard shortcuts ([Hotkeys]).
 * - Scrubbing moves a preview, the video seeking along at most every 200 ms (not live, not in a watch-together room);
 *   releasing it (or Select, for a remote's touch surface) commits it with one exact seek, unless the last one along
 *   went there; Back or a cancelled drag returns the video where the scrub started.
 * - A click acts at once; a second one within the double-click interval toggles fullscreen alone when the keymap
 *   gives double clicks a meaning, so a double click pauses once and goes fullscreen. With a mouse a click pauses or
 *   shows and hides the controls, as the profile has it ([SessionInfo.videoClick]).
 * - On a touch screen the store tells the fingers on the video apart ([TouchGestures]): skip zones at the sides, where
 *   a double tap seeks by the seek step, a tap in the middle (with the controls down, it pauses where the profile's
 *   [SessionInfo.videoClick] says so), two-finger taps that toggle playback, pinches that zoom while this device has
 *   pinch to zoom on, a finger held on the video that plays at 2× until it lifts, which gives back the speed it had
 *   ([holdSpeed]: not live, and in a room only where this device controls playback, the room's speed changing for
 *   everyone meanwhile), and swipes up and down the left and right edges that set the screen's brightness and the
 *   system's volume through [PlayerHost.levels], shown on their side ([PlayerUiState.level]), while this device has them
 *   on. A brightness swipe's level is kept for the next playback to open at while the profile remembers it
 *   ([PlayerChoices.rememberBrightness]); the screen's own brightness comes back as the player closes ([release]).
 *   None of these act in picture in picture or with the content strip open.
 * - On a touch screen the lock button ([PlayerCommand.LockScreen]) locks the screen against stray touches
 *   ([PlayerUiState.screenLock]): a menu and the controls hide and stay hidden, and no touch on the video acts. A tap
 *   shows the unlock button for [UNLOCK_PROMPT], or hides it; a finger held on it ([PlayerCommand.UnlockHold]) for
 *   [UnlockButton.HOLD_MILLIS] unlocks and shows the controls, and one lifted sooner, moved or joined by a second
 *   finger leaves the button up for [UNLOCK_PROMPT] again (a second finger hides it); a screen reader's press unlocks
 *   at once ([PlayerCommand.UnlockPress]). Keys, the system's media controls and picture in picture work as ever, Back
 *   leaves the player, and the lock lasts through the next episodes until the player closes.
 * - Up next ([UpNextPrompt]) comes up where the video's credits start (from its chapters, [SkipSegments]) and otherwise
 *   the profile's countdown ([NextEpisode.countdownSeconds]) before the end, as one button with the next episode's code
 *   and name; with the session's [NextEpisode.autoplay] on it counts down played time and then plays the next episode,
 *   and it only offers it otherwise.
 * - An episode of a series has previous and next episode buttons ([PlayerUiState.episodes]), both always there, each
 *   disabled without an episode that way; in a room only the host changes the episode.
 * - Intros, recaps and credits from the chapters get a skip button ([SkipPrompt]) as the profile has them
 *   ([SessionInfo.skipping]): shown for a few seconds as they start and with the controls, or counting down to an
 *   automatic skip, at most once per segment and playback. The skip seeks exactly to the segment's end. Credits to the
 *   end of an episode with a next one are up next's button: counting down the skip's 3 s when they skip automatically
 *   (with auto-play on), else as up next does. In a room, only those who may control the playback see the skip button,
 *   and only the host skips on its own.
 * - The skip button and up next are one prompt button ([PromptButton], [PlayerUiState.prompt]), one at a time. Any input
 *   on the player stops its countdown and leaves the plain button: every [onInput] event (touches, clicks, pointer
 *   moves, wheel, keys, a remote's presses, focus moves) and every command from the views but [PlayerCommand.CloseMenu]
 *   ([dispatch]: buttons, menus, the seek bar's scrubs, the system's media controls). For up next, and for credits
 *   counting down to the next episode, that cancels the auto-play for the rest of the file.
 * - Play at the end of the file (ended, or the end of the video reached by the sleep timer) starts it over.
 * - Failures come from the session; the error card offers Retry and Close ([PlayerStates.error]).
 *   Over it the controls are the title and Back alone ([PlayerUiState.showsPlaybackControls]): a failure closes the
 *   menu and the info, and neither opens again until a retry takes the error away.
 * - While the controls show, subtitles sit above them: the view reports how much of the player they cover
 *   ([onControlsHeightChanged]) and the engine lifts subtitles by as much.
 * - The options ([PlayerUiState.options]): the picture's fit and zoom ([VideoLayout]; a pinch zooms on touch screens,
 *   and a picture-in-picture window always shows the whole picture,
 *   [onPictureInPictureChanged]), the shaders ([ShaderPreset], where the platform has [shaderFiles]), the sleep timer
 *   ([SleepTimer]), auto-play of the next episode, the audio output, loudness normalization and the audio channels.
 *   The fit, the zoom and the shader preset are the title's ([PlayerPreferences.picture]: kept per library or title as
 *   their scopes say), applied as a title opens where they differ from the previous title's, so a change kept nowhere
 *   lasts into the next episode; a fit picked, a zoom stepped or pinched and a preset picked or toggled on are kept
 *   for the title playing. The imported shaders, normalization and channels are this device's [preferences] and carry
 *   over to the next video; the sleep timer and the shader toggle's off ([PlayerCommand.ToggleShaders]) last as long
 *   as the player, through its next episodes. NVScaler doesn't run on HDR video ([files]).
 * - The display stays awake ([PlayerUiState.keepAwake]) while the video plays, or opens or buffers unpaused, on screen
 *   or in picture in picture ([onVisibleChanged], [onPictureInPictureChanged]). Pausing, the end, a failure and
 *   closing let it sleep at once: the OS's idle timer counts from the viewer's last input, so a pause by hand doesn't
 *   darken the screen before the OS's usual delay.
 * - Fullscreen (desktop windows): the window's ([PlayerUiState.fullscreen]: as the player opens, then as the player or
 *   the platform changes it, [onFullscreenChanged]), and whether it is the player's own ([ownsFullscreen]): fullscreen
 *   that came on while the player was open, or with the playback this one replaced (the next episode). Fullscreen from
 *   before the player (Start in fullscreen, a toggle at a screen) is the window's: Escape is Back over it, and leaving
 *   the player keeps it.
 *
 * Engine commands go straight to [engine] (the session's engine; the store never loads or releases it). The timers run
 * on the scope's dispatcher and measure time with the time source, so tests drive them with virtual time. Call
 * everything on the main thread.
 */
class PlayerStore(
    private val engine: PlayerEngine,
    private val session: PlayerSession,
    private val host: PlayerHost,
    private val preferences: PlayerPreferences,
    private val config: PlayerConfig,
    parentScope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
    /** The shaders' files on this device; null where the player offers no shaders. */
    private val shaderFiles: ShaderFiles? = null,
    /** The Shaders page imports a shader through the system's open dialog ([PlayerOption.importLabel]). */
    private val importsShaders: Boolean = false,
    /** The wall clock, for the time the video ends ([TimelineState.endsAt]) and a live window's clock times. */
    private val clock: Clock = Clock.System,
    /** Ambient lighting, where this device's player runs it (mpv's GPU outputs); null hides its switch. */
    private val ambientLighting: AmbientLightingController? = null,
    /** The window is fullscreen as the player opens. */
    fullscreen: Boolean = false,
    /** That fullscreen is the player's: the playback this one replaced (the next episode) owned it. */
    ownsFullscreen: Boolean = false,
) {
    private val scope = parentScope.childScope()
    private val keymap = Keymap.forProfile(config.profile)

    private var engineState: EngineState = session.engineState.value
    private var info: SessionInfo = session.info.value

    /**
     * The controls ([PlayerChrome]); on TV they start hidden ([PlayerUiState.chromeHiddenAtStart]): the loading doesn't
     * raise them until something shows them. The content strip is part of them: it goes with them when they hide past
     * its hold (the pointer leaving the player). The skip button goes with them as they hide, except their timer's hide
     * in its first seconds.
     */
    private val chrome: PlayerChrome = PlayerChrome(scope, timeSource, initiallyVisible = config.profile != InputProfile.TV, onChange = {
        val hid = chromeWasVisible && !chrome.visible
        chromeWasVisible = chrome.visible
        update {
            if (hid) skip.controlsHid(automatic = chrome.hidByTimer)
            if (!chrome.visible && menu == PlayerMenu.CONTENT_STRIP) menu = null
        }
    })
    private var chromeWasVisible = config.profile != InputProfile.TV
    /** An assistive technology that moves through the controls one at a time runs ([onAssistiveTechnologyChanged]). */
    private var assistiveTechnology = false
    private var menu: PlayerMenu? = null
    /** [PlayerMenu.WATCH_TOGETHER] was opened from [PlayerMenu.OPTIONS]: Back returns there rather than closing it. */
    private var watchFromOptions = false
    /** The language of [PlayerMenu.SUBTITLE_LANGUAGE]'s page ([SubtitleLanguage.key]). */
    private var subtitleLanguage: String? = null

    // The subtitle search ([PlayerMenu.SUBTITLE_SEARCH]).
    /** The language searched (ISO 639-1) since the sheet opened; null before. */
    private var searchLanguage: String? = null
    /** [PlayerChoices.subtitleSearchLanguage]. */
    private var storedSearchLanguage: String? = null
    /** The title typed; null searches the video's own. */
    private var searchTitle: String? = null
    private var searching = false
    private var searchHits: List<SubtitleSearchHit> = emptyList()
    private var searchMessage: String? = null
    /** The result downloading: one at a time. */
    private var downloadingSubtitle: String? = null
    /** The search running: a newer one cancels it, so its answer never replaces the session's later results. */
    private var searchJob: Job? = null
    private var searchDebounce: Job? = null

    /** The file info page ([PlayerMenu.FILE_INFO]) since it was opened. */
    private var fileInfo: FileInfoState? = null
    /** The file info load running: reopening the page cancels it, so an earlier episode's info never lands. */
    private var fileInfoJob: Job? = null
    private var timelineFocused = false
    /** A control has focus (not the player itself): Select and the directions are its own ([InputEvent.ControlFocus]). */
    private var controlFocused = false
    private var fullscreen = fullscreen

    /**
     * The fullscreen on now is the player's own: it came on while the player was open (the player's toggle, the
     * window's own controls), or with the playback this one replaced. Leaving the player ends it; fullscreen from before
     * the player, the window's, stays, and Escape is Back over it.
     */
    var ownsFullscreen = ownsFullscreen
        private set

    /** How much of the player's height the bottom controls cover (the view measures it), and the lift last applied. */
    private var controlsHeight = 0.0
    private var subtitleLift = 0.0

    // The video seeks along a drag ([Scrubber]) as it would with a release there, but tells nothing: no progress report,
    // no room; the release's seek does.
    private val scrubber = Scrubber(scope, seek = { engine.seek(it, exact = true) }, commit = ::onScrubCommitted)
    /** Where a mouse rests over the seek bar, a fraction of its length ([PlayerCommand.HoverTimeline]); null off it. */
    private var hoverFraction: Double? = null
    /** The hover's tooltip, made once for each second it rests over: a move within it shows the very same. */
    private var hoverPreview: ScrubState? = null
    /** The platform's 12/24-hour setting ([setUse24HourClock]), for the end time and a live window's clock times. */
    private var use24HourClock = true

    private var pendingSeek: Double? = null
    private var pendingSeekJob: Job? = null
    /** A burst of key seeks gathered into one ([SeekBurst]): its target is the position the timeline shows meanwhile. */
    private val burst = SeekBurst(scope) { target -> seekFromControls(target, showControls = false) }
    /** The navigation each held Back, Escape or Backspace stands for: it acts as the key comes up. */
    private val navigationKeys = mutableMapOf<InputKey, NavigationKey>()
    /** The play/pause focus requests so far ([PlayerUiState.playPauseFocus]). */
    private var playPauseFocusSerial = 0
    /** The file had ended when [syncChrome] last ran. */
    private var wasEnded = false
    /** The loaded file was paused when [syncChrome] last ran. */
    private var wasPaused = false
    /** The subtitle track the subtitle shortcut hid ([toggleSubtitles]), while hidden. */
    private var hiddenSubtitle: Long? = null
    /** The keys' settings ([PlayerChoices]). */
    private var seekSeconds = 10.0
    private var longSeekSeconds = 30.0
    private var playerNavigation: Boolean? = null
    private var hotkeys = Hotkeys.DEFAULT
    /** The timeline's [TimelineState.motion], and the position it moves on from ([playheadMotion]). */
    private var motion: PlayheadMotion? = null
    private var motionFrom = 0.0
    private val paused = Pending<Boolean>()
    private val muted = Pending<Boolean>()
    private val volume = Pending.ofDouble()
    private val speed = Pending.ofDouble()
    private val subtitleDelay = Pending.ofDouble()
    private val audioDelay = Pending.ofDouble()
    private val audioTrack = Pending<TrackChoice>()
    private val subtitleTrack = Pending<TrackChoice>()
    private val secondSubtitleTrack = Pending<TrackChoice>()
    private val audioDevice = Pending<String>()

    /** The audio output picked last ([PlayerChoices.audioOutputDevice]; null until the choices came), which the engine is put on once it lists it. */
    private var keptOutput: String? = null
    private var keptOutputTried = false
    /** An output picked here, kept once the engine plays to it; dropped when the engine plays to another instead. */
    private var pickedOutput: String? = null

    /** HDR output as stored ([PlayerChoices.hdr]); [hdrRequest] the switch's state while the output plan takes a flip. */
    private var hdr = true
    private var hdrRequest: Boolean? = null

    /** The playback output's HDR input ([followOutput]); null without an output, and then no HDR switch. */
    private var hdrOutput: (suspend (Boolean) -> Boolean)? = null

    /** The playback output's Dolby Vision conversion input ([followOutput]); null without an output, and then no page. */
    private var dvConversionOutput: ((DolbyVisionConversion) -> Unit)? = null
    /** The sleep timer's configured minutes ([PlayerChoices.sleepTimerMinutes]). */
    private var sleepDefaultMinutes = 30
    /** What Dolby Vision Profile 7 becomes in this player (a development build's page); null until the choices came. */
    private var dolbyVisionConversion: DolbyVisionConversion? = null

    // The options. The engine starts at the defaults; [applyOptions] sends what differs from what it has.
    private var fit = VideoFit.CONTAIN
    private var zoom = 1.0
    private val mutablePictureInPicture = MutableStateFlow(false)
    private val pictureInPicture: Boolean get() = mutablePictureInPicture.value
    /** The player is on screen: not minimized, hidden or in the background ([onVisibleChanged]). */
    private var visible = true
    private var appliedLayout = VideoLayout.DEFAULT
    private var normalization = false
    private var appliedNormalization = false
    private var channels = AudioChannels.ORIGINAL
    private var appliedChannels = AudioChannels.ORIGINAL
    private var downmix = Downmix()
    private var appliedDownmix = Downmix()
    /** The title's shader preset as kept (opened with it, or picked since), the imported shaders, and the preset running. */
    private var savedShader = ShaderPreset.Off.id
    private var customShaders = emptyList<CustomShader>()
    private var shader: ShaderPreset = ShaderPreset.Off
    /** The files the engine was last given, and the job resolving their paths. */
    private var appliedShaderFiles = emptyList<ShaderFile>()
    private var shaderJob: Job? = null
    /** Whether the engine reads its stats ([PlayerEngine.setStatsWanted]): while the playback info reads them. */
    private var statsWanted = false
    /** The playback info is on ([PlayerChoices.showPlaybackInfo], [PlayerCommand.ToggleInfo]) and its auto-hide. */
    private var infoShown = false
    private var infoAutoHide = true

    /**
     * The playback info's sections for the view ([PlaybackInfoReader.sections]), which counts its frames into it
     * ([PlaybackInfoReader.onFrame]); [PlayerUiState.playbackInfo] says whether and how it shows.
     */
    val playbackInfo = PlaybackInfoReader(scope, { memory, uiFps ->
        PlaybackInfo.sections(engineState, info.local, info.transcoding.takeUnless { info.live || info.local }, memory, uiFps, T.locale)
    })

    /** The zoom a pinch started from, while one lasts; it zooms once it has clearly moved ([onPinch]). */
    private var pinchStart: Double? = null
    private var pinchMoves = 0
    private var pinchZooming = false
    /** Swipes up and down the left edge change the brightness ([PlayerChoices.brightnessSwipe]). */
    private var brightnessSwipe = true
    /** Swipes up and down the right edge change the volume ([PlayerChoices.volumeSwipe]). */
    private var volumeSwipe = true
    /** Two fingers pinching the video zoom it ([PlayerChoices.pinchToZoom]). */
    private var pinchToZoom = true
    /** The volume's top, in percent ([PlayerChoices.maxVolume]). */
    private var maxVolume = 100
    /** The rotation lock ([PlayerChoices.rotationLocked]); the platform's player follows the setting. */
    private var rotationLocked = true
    /** Always on top ([PlayerChoices.alwaysOnTop]); null until the stored value came, then as the host was last told. */
    private var alwaysOnTop: Boolean? = null
    /** Playback opens at the brightness a swipe last settled on ([PlayerChoices.rememberBrightness]), null for none. */
    private var rememberBrightness = false
    private var rememberedBrightness: Double? = null
    /** The device's choices arrived once: the player has opened ([onChoices]). */
    private var choicesSeen = false

    /** The speed a finger held on the video replaced with [HOLD_SPEED], while it is held ([holdSpeed]). */
    private var heldSpeedFrom: Double? = null

    /** The screen lock's unlock button while the lock is on ([lockScreen]); null unlocked. */
    private var lock: UnlockStage? = null
    /** Hides the unlock button [UNLOCK_PROMPT] after it showed or a finger left it. */
    private var lockJob: Job? = null
    /** Unlocks once the finger on the unlock button has held it [UnlockButton.HOLD_MILLIS]; null while none holds it. */
    private var unlockHold: Job? = null
    /** A finger, not a pointer, holds the unlock button: its touches can let go of it. */
    private var unlockHeldByFinger = false

    private val sleep = SleepTimer(scope, timeSource, config.sleepTimerMinuteSeconds, ::onSleepSecond)

    private val clicks = ClickArbiter(timeSource, config.doubleClickInterval, ::execute)

    private val touch = TouchGestures(scope, timeSource, TouchHooks())

    /** Keys whose key-down the store handled: their key-up is consumed too. */
    private val consumedKeys = mutableSetOf<InputKey>()

    private val upNext = UpNextPrompt(scope, timeSource, onTimer = { update {} }, onStep = ::onUpNextStep)

    /** The retries of up next's countdown spent on a next episode that failed to start ([offerNextAgain]). */
    private var nextRetries = 0

    /** The sleep timer stopped the video at its end: nothing moves on from it. */
    private var stoppedAtEnd = false

    /** The player is leaving at the end ([followEnd]). */
    private var leavingAtEnd = false

    /** The app is in the background where video pauses ([pauseForBackground]): up next's countdown holds. */
    private var backgrounded = false

    /** The file ([EngineState.loadId]) whose end played the next episode in picture in picture. */
    private var advancedInPictureInPicture: Long? = null
    private val skip = SkipPrompt(scope, timeSource, onTimer = { update {} }, onTick = ::onSkipTick)

    /** Rebuilds the timeline every [LIVE_TICK] while a live window shows ([rewindWindow]): the edge moves on. */
    private var liveTick: Job? = null

    /** The seek badge ([registerSkipBadge]): showing, its direction and the seconds summed, its restarts so far. */
    private var badgeShown = false
    private var badgeForward = true
    private var badgeTotal = 0.0
    private var badgeSerial = 0
    private var badgeJob: Job? = null

    private var osd: String? = null
    /** The level an edge swipe changes, shown while it does and a moment after ([TouchGestures]). */
    private var level: LevelIndicator? = null
    private var osdJob: Job? = null
    private var osdIcon: OsdIcon? = null

    /** The volume the viewer set and [preferences] doesn't keep yet: it keeps the last of a run of changes ([VOLUME_SAVE_DELAY]). */
    private var unsavedVolume: Double? = null
    private var volumeSave: Job? = null

    /** The engine's wait has lasted [BUFFERING_GRACE] ([followBuffering]): [status] tells it from then on. */
    private var bufferingTold = false
    private var bufferingJob: Job? = null

    /** The middle play/pause flash ([PlayerUiState.transportFlash]) while it shows, and the flashes so far. */
    private var transportFlash: TransportFlash? = null
    private var flashSerial = 0
    private var flashJob: Job? = null

    /** The command running came in through [onInput] (a key, a click, a gesture), not a view's button. */
    private var fromInput = false

    // Watch together ([attachWatch]).
    private var watch: PlayerWatch? = null
    private var watchUi: PlayerWatchUi? = null
    private var watchJobs: List<Job> = emptyList()

    /** The speed the room plays at while the room nudges the player's own ([RoomPlayer.setRate]). */
    private var roomSpeed: Double? = null
    private var released = false
    /** The display is negotiated for the current item's first frame ([followOutput]). */
    private var displayNegotiating = false

    /**
     * The player as a watch-together room drives it (the Open Watch Party SDK's adapter): the store's own commands,
     * without the OSD.
     */
    internal val watchPlayer: RoomPlayer get() = watchAdapter
    private val watchAdapter = StoreAdapter()

    /** The player shows in a picture-in-picture window ([onPictureInPictureChanged]): a watch-together room's player stays in the room. */
    internal val inPictureInPicture: StateFlow<Boolean> = mutablePictureInPicture.asStateFlow()

    private val audioItems = Memo<TrackKey, List<TrackItem>> { TrackLabels.items(it.tracks, TrackKind.AUDIO, it.selected, it.second, it.locale) }
    private val subtitleItems = Memo<TrackKey, List<TrackItem>> { TrackLabels.items(it.tracks, TrackKind.SUBTITLE, it.selected, it.second, it.locale) }
    private val moreSubtitles = Memo<MoreKey, List<SubtitleLanguage>> { MoreSubtitles.languages(it.subtitles, it.tracks, it.locale) }
    private val customSpeed = Memo<Pair<Double, String>, SpeedControl> { PlayerStates.customSpeed(it.first) }
    private val chapterMarks = Memo<Pair<List<Chapter>, Double>, List<Float>> { PlayerStates.chapterMarks(it.first, it.second) }
    private val skipSegments = Memo<Pair<List<Chapter>, Double>, List<SkipSegment>> { SkipSegments.of(it.first, it.second) }
    private val options = Memo<PlayerOptions.Values, List<PlayerOption>> { PlayerOptions.build(it) }
    private val audioOptions = Memo<PlayerOptions.AudioValues, List<PlayerOption>> { PlayerOptions.audio(it) }

    private val chapterItems = Memo<ChapterKey, List<ChapterItem>> { PlayerStates.chapters(it.chapters, it.images, it.current, it.canSeek) }

    private val searchLanguages = Memo<Triple<String, String, String?>, List<OptionChoice>> { (code, locale, title) ->
        SubtitleSearch.languages(code, locale) { PlayerCommand.SearchSubtitles(it, title, now = true) }
    }

    private val mutableState = MutableStateFlow(buildState())
    val state: StateFlow<PlayerUiState> = mutableState.asStateFlow()

    private val mutableTimeline = MutableStateFlow(buildTimeline())

    /**
     * The timeline as the controls draw it, a scrub's preview included: a new value each time the engine reports the
     * position or the cache moved, several times a second while the video plays, where [state] stays as it is.
     */
    val timeline: StateFlow<TimelineState> = mutableTimeline.asStateFlow()

    private val mutableUserPauses = MutableSharedFlow<Unit>(extraBufferCapacity = 1, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    /**
     * Each pause the viewer gives (Pause, a TogglePause that pauses: the player's buttons, keys and the OS's controls),
     * never the system's ([PlayerCommand.SystemPause]): the OS media controls hear them ([MediaControlsHost.userPaused]).
     */
    internal val userPauses: SharedFlow<Unit> = mutableUserPauses.asSharedFlow()

    init {
        scope.launch { session.engineState.collect(::onEngineState) }
        scope.launch { session.info.collect(::onSessionInfo) }
        scope.launch { preferences.choices.collect(::onChoices) }
        scope.launch { followPicture() }
        update { syncChrome() }
        // "Ends at" moves on with the clock while the position stands (paused).
        scope.launch {
            while (true) {
                delay((MINUTE_MILLIS - clock.now().toEpochMilliseconds() % MINUTE_MILLIS).milliseconds)
                mutableTimeline.value = buildTimeline()
            }
        }
    }

    /**
     * Follows the playback's output (`PlaybackOutput`): its display [negotiating] (while the display switches for an
     * item's first frame, the player shows the item as opening, its first frame behind the loading state), its HDR
     * input, which the HDR switch sets ([setHdr], `PlaybackOutput.setHdr`: true once the engine took the plan's HDR
     * output), and its Dolby Vision conversion input, which a development build's page sets for this playback
     * ([setDolbyVisionConversion]). Without an output the player offers neither.
     */
    fun followOutput(
        negotiating: StateFlow<Boolean>,
        setHdr: suspend (enabled: Boolean) -> Boolean,
        setDolbyVisionConversion: (DolbyVisionConversion) -> Unit,
    ) {
        hdrOutput = setHdr
        dvConversionOutput = setDolbyVisionConversion
        scope.launch { negotiating.collect { update { displayNegotiating = it } } }
    }

    /**
     * Shows watch together ([PlayerWatch]): its state in [PlayerUiState.watch], its toasts as the OSD; the viewer's
     * seeks and speed changes go to it, and while it says the viewer may not control playback (a guest in a host-only
     * room) play, pause, every seek and the speed are refused, as is the next episode for anyone but the host
     * ([allowedInRoom]); a scrub or a held seek under way when it stops letting the viewer control playback ends without
     * seeking. A stop on this device rather than the viewer's ([PlayerCommand.SystemPause], the sleep timer) pauses the
     * room for whoever controls playback, and for anyone else pauses this device alone, its player out of the room's
     * playback, which plays on ([PlayerWatch.stopHere]), until its Play or the system's resume catches it up
     * ([PlayerWatch.resumeHere]). Null detaches it.
     */
    fun attachWatch(watch: PlayerWatch?) {
        watchJobs.forEach(Job::cancel)
        this.watch = watch
        update { onWatchUi(watch?.state?.value) }
        watchJobs = if (watch == null) {
            emptyList()
        } else {
            listOf(
                scope.launch { watch.state.collect { ui -> update { onWatchUi(ui) } } },
                scope.launch { watch.notices.collect { text -> update { showOsd(text) } } },
            )
        }
    }

    /**
     * Runs a command from the views: buttons, menus, sliders, the prompt button, the error screen, the system's media
     * controls. Each is the viewer's doing and stops a prompt's countdown, but for [PlayerCommand.CloseMenu], which views
     * also send when a menu goes by itself (a room that ended takes its panel along).
     */
    fun dispatch(command: PlayerCommand) {
        if (command != PlayerCommand.CloseMenu) interruptPrompt()
        execute(command)
    }

    /**
     * Handles a key or pointer event from the player surface through the platform's keymap. False means the store
     * left it alone and the platform should handle it (focus navigation, activating the focused control).
     */
    fun onInput(event: InputEvent): Boolean {
        // A finger still on the glass after the player went: nothing is left to drive.
        if (released) return false
        if (lock != null && event.touchesVideo()) return onLockedTouch(event)
        // Focus moving by itself (to a prompt as it shows) is no input of the viewer's.
        if (event !is InputEvent.ControlFocus) interruptPrompt()
        fromInput = true
        try {
            return handleInput(event)
        } finally {
            fromInput = false
        }
    }

    /** The pointer and touch events: the ones a locked screen shields ([onLockedTouch]). Keys and focus moves pass. */
    private fun InputEvent.touchesVideo(): Boolean = when (this) {
        is InputEvent.KeyDown, is InputEvent.KeyUp, InputEvent.FocusMove, is InputEvent.ControlFocus -> false
        is InputEvent.Click, is InputEvent.Hold, InputEvent.PointerMove, InputEvent.PointerExit, is InputEvent.PointerDown,
        is InputEvent.PointerUp, is InputEvent.Wheel, is InputEvent.Touch -> true
    }

    /**
     * A touch on the locked screen: a tap shows or hides the unlock button and a second finger hides it
     * ([TouchGestures]); a finger holding the unlock button that moves, lifts or gets a second finger lets go of it.
     * Nothing else acts, nor stops a prompt's countdown.
     */
    private fun onLockedTouch(event: InputEvent): Boolean {
        when (event) {
            is InputEvent.Touch -> {
                touch.on(event)
                if (unlockHeldByFinger && !touch.unlockHoldIntact()) holdUnlock(false)
            }
            is InputEvent.Click -> setUnlock(if (lock == UnlockStage.HIDDEN) UnlockStage.SHOWN else UnlockStage.HIDDEN)
            else -> Unit
        }
        return true
    }

    private fun lockScreen() {
        if (config.profile != InputProfile.TOUCH || lock != null) return
        touch.stop()
        update {
            menu = null
            scrubber.end()
            chrome.hide(ignoreHolds = true)
        }
        setUnlock(UnlockStage.SHOWN)
    }

    /**
     * A finger or pointer down on the shown unlock button ([held]) starts the hold, which unlocks after
     * [UnlockButton.HOLD_MILLIS]; let go sooner, the button stays up for [UNLOCK_PROMPT] again.
     */
    private fun holdUnlock(held: Boolean) {
        if (!held) {
            val hold = unlockHold ?: return
            hold.cancel()
            unlockHold = null
            unlockHeldByFinger = false
            if (lock == UnlockStage.SHOWN) setUnlock(UnlockStage.SHOWN) else update {}
            return
        }
        if (lock != UnlockStage.SHOWN || unlockHold != null) return
        val byFinger = touch.fingerDown
        if (!touch.takeUnlockHold()) return
        update {
            lockJob?.cancel()
            lockJob = null
            unlockHeldByFinger = byFinger
            unlockHold = scope.launch {
                delay(UnlockButton.HOLD_MILLIS.milliseconds)
                unlockHold = null
                unlockHeldByFinger = false
                unlock()
            }
        }
    }

    /** A screen reader pressed the shown unlock button: it has no finger to hold it with. */
    private fun unlockPress() {
        if (lock == UnlockStage.SHOWN) unlock()
    }

    private fun unlock() = update {
        lockJob?.cancel()
        lockJob = null
        unlockHold?.cancel()
        unlockHold = null
        unlockHeldByFinger = false
        lock = null
        show()
    }

    private fun setUnlock(stage: UnlockStage) = update {
        lock = stage
        lockJob?.cancel()
        if (stage == UnlockStage.HIDDEN) {
            unlockHold?.cancel()
            unlockHold = null
            unlockHeldByFinger = false
        }
        lockJob = if (stage == UnlockStage.HIDDEN) {
            null
        } else {
            scope.launch {
                delay(UNLOCK_PROMPT)
                update { if (lock != null) lock = UnlockStage.HIDDEN }
            }
        }
    }

    /**
     * Anything the viewer does on the player stops an automatic skip's countdown, but never one to the next episode (up
     * next's, or credits counting down to it in its place): only dismissing it does ([dismissPrompt]).
     */
    private fun interruptPrompt() {
        if (!skip.counting || skip.segment?.let(::playsNextEpisode) == true) return
        update { skip.interrupt() }
    }

    private fun handleInput(event: InputEvent): Boolean = when (event) {
        is InputEvent.KeyDown -> onKeyDown(event)
        is InputEvent.KeyUp -> onKeyUp(event)
        is InputEvent.Click -> clicks.onClick(event, keymap, inputContext())
        is InputEvent.Hold -> {
            holdOnVideo(event.held)
            true
        }
        InputEvent.PointerMove -> {
            chrome.pointerEnter()
            chrome.recordPointerActivity()
            true
        }
        InputEvent.PointerExit -> {
            if (config.profile == InputProfile.DESKTOP) chrome.pointerExit()
            true
        }
        is InputEvent.PointerDown -> {
            chrome.pointerDown(event.pointer)
            false
        }
        is InputEvent.PointerUp -> {
            chrome.pointerUp(event.pointer)
            false
        }
        is InputEvent.Wheel -> onWheel(event.deltaY)
        is InputEvent.Touch -> {
            touch.on(event)
            true
        }
        InputEvent.FocusMove -> {
            if (controlsVisible()) chrome.restartAutoHide()
            true
        }
        is InputEvent.ControlFocus -> {
            controlFocused = event.onControl
            true
        }
    }

    /** The seek bar gained or lost focus: left/right seek while it has it, one seek per press or hold ([SeekBurst]). */
    fun onTimelineFocusChanged(focused: Boolean) {
        if (!focused && timelineFocused) burst.flush()
        timelineFocused = focused
    }

    /**
     * The window entered or left fullscreen, whoever asked: a change while the player is open makes it the player's
     * ([ownsFullscreen]) or ends it.
     */
    fun onFullscreenChanged(fullscreen: Boolean) = update { fullscreenChanged(fullscreen) }

    /**
     * The bottom controls (seek bar and buttons) cover [fraction] of the player's height, from its bottom edge, as the
     * view lays them out; 0 while it shows none (picture-in-picture). While the controls show, subtitles move up by as
     * much ([PlayerEngine.setSubtitleLift]), so they never sit under them.
     */
    fun onControlsHeightChanged(fraction: Double) {
        if (!fraction.isFinite()) return
        // To a thousandth: sub-pixel layout changes don't reach the engine.
        val height = (fraction.coerceIn(0.0, MAX_SUBTITLE_LIFT) * 1000).roundToLong() / 1000.0
        if (height != controlsHeight) update { controlsHeight = height }
    }

    /**
     * The player went into a picture-in-picture window, or came back from it: the window shows the whole picture
     * ([VideoLayout.DEFAULT]), and the fit and zoom come back with the player.
     */
    fun onPictureInPictureChanged(active: Boolean) {
        if (active != pictureInPicture) {
            update {
                mutablePictureInPicture.value = active
                // Picture in picture shows no bars: ambient lighting waits outside it.
                if (active) ambientLighting?.enterPictureInPicture() else if (ambientLighting?.exitPictureInPicture() == true) onAmbientLightingOn()
            }
        }
    }

    /** A picture-in-picture start failed: [text] says why, as the transient message ([PlayerUiState.osd]). */
    fun onPictureInPictureFailed(text: String) {
        update { showOsd(text) }
    }

    /**
     * The player's window went out of sight (minimized, hidden, the app in the background) or came back. Out of sight,
     * the display may sleep unless the player is in picture in picture ([PlayerUiState.keepAwake]).
     */
    fun onVisibleChanged(visible: Boolean) {
        if (visible == this.visible) return
        update { this.visible = visible }
        if (visible && choicesSeen) touch.refresh(rememberedLevel())
    }

    /**
     * The app went to the background where video pauses there ([PlayerLifecycle]): a video that plays pauses here
     * alone (a room this device is in stops waiting for it rather than pausing for everyone), and up next's countdown
     * holds until [resumeAfterBackground]: nobody is there to answer it. True when it played.
     */
    internal fun pauseForBackground(): Boolean {
        if (released) return false
        update { backgrounded = true }
        if (!engineState.loaded || engineState.eof || paused.resolve(engineState.paused)) return false
        setPaused(true)
        return true
    }

    /**
     * Back from [pauseForBackground]: up next counts again, and with [play] (it paused a video that played) the video
     * plays again, back by the profile's rewind on resume first ([SessionInfo.rewindOnResumeSeconds]), unless the car
     * forbids it now.
     */
    internal fun resumeAfterBackground(play: Boolean) {
        if (released) return
        update {
            backgrounded = false
            if (play && host.playbackAllowed) {
                val rewind = info.rewindOnResumeSeconds
                if (rewind > 0 && !info.live && engineState.loaded && !engineState.eof) seekTo(displayPosition() - rewind)
                setPaused(false)
            }
        }
    }

    /**
     * Whether video may play changed ([PlayerHost.playbackAllowed]: a car that forbids video while its driver drives,
     * the profile picker over the player). Forbidden, the video pauses; a room that drives this player pauses it here
     * alone itself, without pausing anyone else ([PlayerWatch]'s own view). Up next's countdown holds until allowed
     * again; then nothing plays by itself.
     */
    internal fun onPlaybackAllowedChanged() {
        if (released) return
        update {}
        if (!host.playbackAllowed && watch?.routesControls != true) setPaused(true)
    }

    /**
     * An assistive technology that moves through the controls one at a time started or stopped: VoiceOver or Switch
     * Control on Apple's platforms, TalkBack's touch exploration on Android. While one runs the controls stay up, and
     * the prompt button with them past its first seconds: no timer takes away the control the viewer is reaching.
     */
    fun onAssistiveTechnologyChanged(running: Boolean) {
        if (running != assistiveTechnology) update { assistiveTechnology = running }
    }

    /**
     * The platform's clock is on 24 hours ([use24HourClock]) or 12: the UI passes it as the player shows and again when
     * it changes. The end time ([TimelineState.endsAt]) and a live window's clock times follow at once.
     */
    fun setUse24HourClock(value: Boolean) {
        if (value != use24HourClock) update { use24HourClock = value }
    }

    /**
     * Stops the store's timers and collection; the sync player stops taking commands, the engine reading stats. The
     * last state lets the display sleep.
     */
    fun release() {
        released = true
        watchAdapter.onChanged = null
        touch.release()
        saveVolume()
        scope.cancel()
        host.levels?.restoreBrightness()
        if (statsWanted) engine.setStatsWanted(false)
        mutableState.value = mutableState.value.copy(keepAwake = false)
    }

    // Input

    /**
     * A key went down ([InputEvent.KeyDown]). True when the store took it; false leaves it to the platform: focus
     * navigation among the controls, the focused control's own Select, Home.
     */
    private fun onKeyDown(event: InputEvent.KeyDown): Boolean {
        val key = event.key
        when (PlayerKeys.navigation(key, event.modifiers, event.source)) {
            NavigationKey.NONE -> Unit
            NavigationKey.HOME -> return false
            // Back acts as it comes up: its press is the player's, so the release doesn't reach the screen beneath.
            else -> {
                if (!event.repeat) navigationKeys[key] = PlayerKeys.navigation(key, event.modifiers, event.source)
                return true
            }
        }
        val visible = controlsVisible()
        PlayerKeys.skipDirection(key)?.let { forward ->
            // Consumed whole, repeats and all: one press is one step however long it is held.
            if (visible) chrome.restartAutoHide()
            if (!event.repeat) if (canControl()) skipChapter(forward) else refuse()
            consumedKeys += key
            return true
        }
        if (visible) chrome.restartAutoHide()
        PlayerKeys.transport(key)?.let { command ->
            if (!event.repeat) execute(command)
            consumedKeys += key
            return true
        }
        // The sleep timer's question and the error card hold buttons of their own.
        if ((sleep.asking != null || info.failure != null) && (PlayerKeys.isDirection(key) || key == InputKey.SELECT)) return false
        zapDirection(key, visible)?.let { up ->
            if (!event.repeat) zap(up)
            consumedKeys += key
            return true
        }
        val surface = !visible || !controlFocused
        if (key == InputKey.SELECT && scrubber.active) {
            // A remote's touch-surface scrub commits on Select.
            if (!event.repeat) execute(PlayerCommand.CommitScrub)
            consumedKeys += key
            return true
        }
        when {
            key == InputKey.SELECT && surface -> {
                if (!event.repeat) surfaceSelect(event, visible)
                consumedKeys += key
                return true
            }
            key == InputKey.TAB && !visible -> {
                if (!event.repeat) update { chrome.show(focusPlayPause = true) }
                consumedKeys += key
                return true
            }
            PlayerKeys.isDirection(key) && directional() && config.profile != InputProfile.TOUCH -> {
                val horizontal = key == InputKey.LEFT || key == InputKey.RIGHT
                when {
                    !visible -> if (horizontal) {
                        hiddenSeek(forward = key == InputKey.RIGHT, repeat = event.repeat)
                    } else {
                        burst.flush()
                        update { chrome.show(focusPlayPause = true) }
                    }
                    horizontal && timelineFocused -> timelineSeek(forward = key == InputKey.RIGHT, repeat = event.repeat)
                    // Nothing has focus yet: the key that brought the remote in lands it on Play/Pause.
                    !controlFocused -> update { chrome.show(focusPlayPause = true) }
                    else -> return false
                }
                consumedKeys += key
                return true
            }
        }
        if (visible && controlFocused && PlayerKeys.isReserved(key)) return false
        hotkeys.actionFor(key, event.modifiers)?.let { action ->
            consumedKeys += key
            if (event.repeat && !action.repeatable) return true
            if (action.requiresPlayback && !canControl() || action.requiresMediaNavigation && watchUi?.canChangeEpisode == false) {
                refuse()
                return true
            }
            shortcut(action)
            return true
        }
        if (hotkeys.isUnknown(key, event.modifiers)) {
            consumedKeys += key
            return true
        }
        val command = when (key) {
            InputKey.CAPTIONS -> PlayerCommand.CycleSubtitles
            InputKey.AUDIO_TRACK -> PlayerCommand.CycleAudio
            InputKey.INFO -> PlayerCommand.ToggleInfo
            InputKey.MEDIA_STOP -> PlayerCommand.Close
            else -> null
        }
        if (command != null) {
            if (!event.repeat) execute(command)
        } else if (!PlayerKeys.isReserved(key)) {
            return false
        }
        // A reserved key nothing took stays the player's, so it never moves focus on the screen beneath.
        consumedKeys += key
        return true
    }

    private fun onKeyUp(event: InputEvent.KeyUp): Boolean {
        navigationKeys.remove(event.key)?.let { navigation ->
            when {
                navigation == NavigationKey.PHYSICAL_ESCAPE && config.escapeLeavesFullscreen && ownsFullscreen && menu == null && !directional() ->
                    execute(PlayerCommand.ExitFullscreen)
                else -> execute(PlayerCommand.Back)
            }
            return true
        }
        // A released key ends its burst: the held arrow's seek goes now, and the next press starts at the slowest tier.
        if (burst.target != null || event.key == InputKey.LEFT || event.key == InputKey.RIGHT) burst.flush()
        return consumedKeys.remove(event.key)
    }

    /**
     * The channel a key zaps to while live: up (true) or down. A remote's channel keys always; on a TV, the D-pad's Up
     * and Down with the controls down too, as a TV's live channels do (with the controls up they move between them).
     * Null for any other key, or off live.
     */
    private fun zapDirection(key: InputKey, visible: Boolean): Boolean? = when {
        !info.live -> null
        key == InputKey.CHANNEL_UP -> true
        key == InputKey.CHANNEL_DOWN -> false
        config.profile != InputProfile.TV || visible -> null
        key == InputKey.UP -> true
        key == InputKey.DOWN -> false
        else -> null
    }

    /** The next channel ([up]) or the one before, the controls up to name it as it tunes. */
    private fun zap(up: Boolean) {
        execute(if (up) PlayerCommand.NextEpisode else PlayerCommand.PreviousEpisode)
        update { chrome.show() }
    }

    /**
     * Select on the player itself: the prompt button (skip, up next) while it is the only thing on screen (the controls
     * down) or the key is the skip shortcut's; else a remote's first press with the controls down only shows them, focus
     * on Play/Pause, as Android TV's players do (on Apple TV, [PlayerConfig.remoteSelectPauses], it pauses too, as the
     * system player does); otherwise the controls show and pause toggles.
     */
    private fun surfaceSelect(event: InputEvent.KeyDown, visible: Boolean) {
        val focus = event.source == KeySource.REMOTE
        if (!canControl()) {
            update { chrome.show(focusPlayPause = focus) }
            return refuse()
        }
        val prompt = prompt()
        if (prompt != null && (!visible || hotkeys.isBound(ShortcutAction.SKIP_MARKER, event.key, event.modifiers))) {
            execute(prompt.command)
            return
        }
        update { chrome.show(focusPlayPause = focus) }
        if (focus && !visible && !config.remoteSelectPauses) return
        execute(PlayerCommand.TogglePause)
    }

    /** A keyboard shortcut's action ([Hotkeys]). */
    private fun shortcut(action: ShortcutAction) {
        when (action) {
            ShortcutAction.PLAY_PAUSE -> execute(PlayerCommand.TogglePause)
            ShortcutAction.VOLUME_UP -> execute(PlayerCommand.AdjustVolume(SHORTCUT_VOLUME_STEP))
            ShortcutAction.VOLUME_DOWN -> execute(PlayerCommand.AdjustVolume(-SHORTCUT_VOLUME_STEP))
            ShortcutAction.SEEK_FORWARD -> keySeek(seekSeconds)
            ShortcutAction.SEEK_BACKWARD -> keySeek(-seekSeconds)
            ShortcutAction.SEEK_FORWARD_LARGE -> keySeek(longSeekSeconds)
            ShortcutAction.SEEK_BACKWARD_LARGE -> keySeek(-longSeekSeconds)
            ShortcutAction.FULLSCREEN_TOGGLE -> if (config.profile != InputProfile.TOUCH) execute(PlayerCommand.ToggleFullscreen)
            ShortcutAction.MUTE_TOGGLE -> execute(PlayerCommand.ToggleMute)
            ShortcutAction.SUBTITLE_TOGGLE -> execute(PlayerCommand.ToggleSubtitles)
            ShortcutAction.AUDIO_TRACK_NEXT -> execute(PlayerCommand.CycleAudio)
            ShortcutAction.SUBTITLE_TRACK_NEXT -> execute(PlayerCommand.CycleSubtitles)
            ShortcutAction.CHAPTER_NEXT -> execute(PlayerCommand.NextChapter)
            ShortcutAction.CHAPTER_PREVIOUS -> execute(PlayerCommand.PreviousChapter)
            ShortcutAction.EPISODE_NEXT -> execute(PlayerCommand.NextEpisode)
            ShortcutAction.EPISODE_PREVIOUS -> execute(PlayerCommand.PreviousEpisode)
            ShortcutAction.SPEED_INCREASE -> execute(PlayerCommand.SpeedUp)
            ShortcutAction.SPEED_DECREASE -> execute(PlayerCommand.SpeedDown)
            ShortcutAction.SPEED_RESET -> execute(PlayerCommand.ResetSpeed)
            ShortcutAction.ZOOM_IN -> execute(PlayerCommand.ZoomIn)
            ShortcutAction.ZOOM_OUT -> execute(PlayerCommand.ZoomOut)
            ShortcutAction.ZOOM_RESET -> execute(PlayerCommand.ResetZoom)
            ShortcutAction.SUB_SEEK_NEXT -> execute(PlayerCommand.SubtitleSeek(forward = true))
            ShortcutAction.SUB_SEEK_PREV -> execute(PlayerCommand.SubtitleSeek(forward = false))
            ShortcutAction.SHADER_TOGGLE -> execute(PlayerCommand.ToggleShaders)
            ShortcutAction.SKIP_MARKER -> prompt()?.let { execute(it.command) }
            ShortcutAction.SCREENSHOT -> execute(PlayerCommand.Screenshot)
        }
    }

    /** The D-pad drives the player: the setting, on by default on TV. */
    private fun directional(): Boolean = playerNavigation ?: (config.profile == InputProfile.TV)

    private fun canControl(): Boolean = watchUi?.canControl != false

    /** A key a watch-together room doesn't let this device use: the room's reason shows. */
    private fun refuse() {
        watchUi?.controlsLocked?.let { text -> update { showOsd(text) } }
    }

    /** A live playback without a window has nothing to seek in. */
    private fun keySeekable(): Boolean = engineState.loaded && (!info.live || rewindWindow() != null)

    /** A direction key with the controls down: a step of the burst, the badge showing what it moved. */
    private fun hiddenSeek(forward: Boolean, repeat: Boolean) {
        if (!canControl()) return refuse()
        if (!keySeekable()) return
        val moved = burst.step(forward, repeat, seekSeconds, displayPosition(), seekDuration(), live = rewindWindow() != null)
        update { registerSkipBadge(forward, abs(moved)) }
    }

    /** A direction key on the focused timeline: a step of the burst, which the timeline shows. */
    private fun timelineSeek(forward: Boolean, repeat: Boolean) {
        if (!canControl()) return refuse()
        if (!keySeekable()) return
        update { burst.step(forward, repeat, seekSeconds, displayPosition(), seekDuration(), live = rewindWindow() != null) }
    }

    /** A seek shortcut: [seconds] onto the burst, the badge showing what it moved. */
    private fun keySeek(seconds: Double) {
        if (!keySeekable()) return
        val step = if (rewindWindow() != null) {
            (abs(seconds).roundToLong().toDouble()).coerceIn(SeekBurst.MIN_LIVE_STEP_SECONDS, SeekBurst.MAX_LIVE_STEP_SECONDS)
        } else {
            abs(seconds)
        }
        val moved = burst.seekBy(if (seconds < 0) -step else step, displayPosition(), seekDuration())
        update { registerSkipBadge(seconds >= 0, abs(moved)) }
    }

    /**
     * A remote's or keyboard's fast forward, rewind, next or previous track: the next or previous chapter, named in
     * the OSD, without the controls; without chapters a seek step with the badge. Nothing at the start going back,
     * or past the last chapter going forward.
     */
    private fun skipChapter(forward: Boolean) {
        val chapters = engineState.chapters
        if (chapters.isEmpty()) return keySeek(if (forward) seekSeconds else -seekSeconds)
        val position = displayPosition()
        val index = if (forward) {
            chapters.indexOfFirst { it.startSeconds > position + CHAPTER_TOLERANCE_SECONDS }.takeIf { it >= 0 } ?: return
        } else {
            if (position <= START_TOLERANCE_SECONDS) return
            val current = chapters.indexOfLast { it.startSeconds <= position + CHAPTER_TOLERANCE_SECONDS }
            when {
                current < 0 -> return seekFromControls(0.0, showControls = false)
                current > 0 && position - chapters[current].startSeconds < PREVIOUS_CHAPTER_GRACE_SECONDS -> current - 1
                else -> current
            }
        }
        seekToChapter(index, showControls = false)
    }

    /** The wheel over the player (desktop): the volume by `-deltaY / 20` points, and the controls show. */
    private fun onWheel(deltaY: Double): Boolean {
        if (config.profile != InputProfile.DESKTOP || deltaY == 0.0 || !deltaY.isFinite()) return false
        setVolume(volume.resolve(engineState.volume) - deltaY / WHEEL_PIXELS_PER_POINT)
        chrome.recordPointerActivity()
        return true
    }

    /**
     * A pinch zooms from the zoom it started at by its [scale]; only once it has clearly moved
     * ([PINCH_THRESHOLD] for [PINCH_MOVES] changes in a row), so two fingers resting on the video change nothing, and
     * snapping to 100 % within [PINCH_SNAP_PERCENT], so pinching back undoes a zoom exactly. The zoom shows once it
     * ends.
     */
    private fun onPinch(scale: Double) {
        if (!scale.isFinite()) return
        val start = pinchStart ?: zoom.also {
            pinchStart = it
            pinchMoves = 0
            pinchZooming = false
        }
        val target = VideoLayout.normalizeZoom(snapPinch(start * scale))
        if (!pinchZooming) {
            if (abs(scale - 1.0) <= PINCH_THRESHOLD) {
                pinchMoves = 0
                return
            }
            pinchMoves += 1
            if (pinchMoves < PINCH_MOVES || target == zoom) return
            pinchZooming = true
        }
        if (target != zoom) {
            update {
                ambientLighting?.suspend()
                zoom = target
            }
        }
    }

    private fun onPinchEnd() {
        if (pinchZooming) {
            preferences.setVideoZoom(info.item, zoom)
            update { showOsd(T.player.osd.zoom(PlayerOptions.zoomLabel(zoom))) }
        }
        pinchStart = null
        pinchMoves = 0
        pinchZooming = false
    }

    private fun snapPinch(zoom: Double): Double =
        if (abs(VideoLayout.percent(zoom) - 100) <= PINCH_SNAP_PERCENT) 1.0 else zoom

    private fun inputContext() = InputContext(
        controlsVisible = controlsVisible(),
        menuOpen = menu != null,
        errorShown = info.failure != null,
        videoClick = info.videoClick,
        live = info.live,
        canControl = watchUi?.canControl != false,
    )

    // Commands

    /**
     * Runs a command from the views, the system's controls, the keys or the keymap: the one way the viewer's commands reach the engine. One a watch-together
     * room doesn't let this device give ([allowedInRoom]) goes no further, and the room's reason shows. [system] is a
     * pause the system gave ([PlayerCommand.SystemPause]) rather than the viewer.
     */
    private fun execute(command: PlayerCommand, system: Boolean = false) {
        if (!allowedInRoom(command)) {
            watchUi?.controlsLocked?.let { text -> update { showOsd(text) } }
            return
        }
        if (info.live && command.seeks && (rewindWindow() == null || !command.seeksLive)) return
        // A car that forbids video while driving: a play goes nowhere, and Play/Pause pauses.
        if (!host.playbackAllowed && command.resumes()) {
            setPaused(true)
            return
        }
        val wasPaused = engineState.eof || paused.resolve(engineState.paused)
        val pausing = command == PlayerCommand.Pause || command == PlayerCommand.TogglePause && !wasPaused
        if (pausing && !system) mutableUserPauses.tryEmit(Unit)
        val resuming = command == PlayerCommand.Play || command == PlayerCommand.TogglePause && wasPaused
        if (!system && (pausing || resuming)) onUserTransport(play = resuming)
        // A stop on this device for one who doesn't control the room's playback is this device's alone, and so is the
        // Play that ends it.
        val stopped = watch?.takeIf { it.stoppedHere }
        if (stopped != null && command.resumes()) return resumeHere(stopped)
        if (stopsHereAlone() && command.stopsHere()) return stopHere()
        // Play and pause in a room go to the room, which commands this player ([watchPlayer]).
        val room = watch?.takeIf { it.routesControls }
        if (room != null) {
            when (command) {
                PlayerCommand.TogglePause ->
                    if (engineState.eof || paused.resolve(engineState.paused)) {
                        if (playInRoom(room)) return
                    } else {
                        return room.pause()
                    }
                PlayerCommand.Play -> if (playInRoom(room)) return
                PlayerCommand.Pause -> return room.pause()
                else -> Unit
            }
        }
        when (command) {
            PlayerCommand.TogglePause -> if (engineState.eof || paused.resolve(engineState.paused)) playOrStartOver() else setPaused(true)
            PlayerCommand.Play -> playOrStartOver()
            PlayerCommand.Pause -> setPaused(true)
            // Whoever controls the room's playback, or anyone outside a room: the system's pause is Pause, its resume
            // Play.
            PlayerCommand.SystemPause -> execute(PlayerCommand.Pause, system = true)
            PlayerCommand.SystemResume -> if (!stopsHereAlone()) execute(PlayerCommand.Play, system = true)
            is PlayerCommand.SeekBy -> seekBy(command.seconds, badge = fromInput || !controlsVisible())
            is PlayerCommand.Skip -> keySeek(if (command.forward) seekSeconds else -seekSeconds)
            is PlayerCommand.SeekTo -> seekFromControls(command.seconds)
            is PlayerCommand.SeekToFraction ->
                if (seekDuration() > 0) seekFromControls(command.fraction.coerceIn(0.0, 1.0) * seekDuration())
            is PlayerCommand.ScrubTo -> scrubTo(command.fraction)
            PlayerCommand.CommitScrub -> commitScrub()
            PlayerCommand.CancelScrub -> update { scrubber.cancel() }
            is PlayerCommand.HoverTimeline -> update {
                hoverFraction = command.fraction?.coerceIn(0.0, 1.0)
                if (hoverFraction == null) hoverPreview = null
            }
            is PlayerCommand.AdjustVolume -> setVolume(volume.resolve(engineState.volume) + command.delta)
            is PlayerCommand.SetVolume -> setVolume(command.percent)
            PlayerCommand.ToggleMute -> toggleMute()
            PlayerCommand.ToggleFullscreen -> setFullscreen(!fullscreen)
            PlayerCommand.ExitFullscreen -> if (fullscreen) setFullscreen(false)
            is PlayerCommand.SelectTrack -> selectTrack(command.kind, command.id, announce = false)
            is PlayerCommand.ToggleSecondSubtitle -> toggleSecondSubtitle(command.id)
            is PlayerCommand.OpenSubtitleLanguage -> if (info.failure == null) update {
                subtitleLanguage = command.key
                menu = PlayerMenu.SUBTITLE_LANGUAGE
                show()
            }
            is PlayerCommand.AddSubtitle -> update {
                session.addSubtitle(command.url)
                if (menu?.parent == PlayerMenu.SUBTITLES) menu = null
            }
            PlayerCommand.CycleAudio -> cycleAudio()
            PlayerCommand.CycleSubtitles -> cycleSubtitles()
            PlayerCommand.ToggleSubtitles -> toggleSubtitles()
            is PlayerCommand.SubtitleSeek -> if (engineState.loaded) engine.subtitleSeek(command.forward)
            PlayerCommand.Screenshot -> if (engineState.loaded) engine.screenshot { saved ->
                scope.launch { update { if (saved) showOsd(T.player.osd.screenshotSaved, OsdIcon.SCREENSHOT) else showOsd(T.player.osd.screenshotFailed) } }
            }
            is PlayerCommand.SetSpeed -> update {
                applySpeed(command.speed)
                if (menu == PlayerMenu.SPEED) menu = null
            }
            PlayerCommand.SpeedUp -> stepSpeed(up = true)
            PlayerCommand.SpeedDown -> stepSpeed(up = false)
            PlayerCommand.ResetSpeed -> update { applySpeed(1.0) }
            PlayerCommand.HoldSpeed -> holdSpeed()
            PlayerCommand.ReleaseSpeed -> releaseSpeed()
            is PlayerCommand.AdjustSubtitleDelay ->
                setDelay(TrackKind.SUBTITLE, subtitleDelay.resolve(engineState.subtitleDelaySeconds) + command.deltaSeconds)
            is PlayerCommand.SetSubtitleDelay -> setDelay(TrackKind.SUBTITLE, command.seconds)
            is PlayerCommand.AdjustAudioDelay ->
                setDelay(TrackKind.AUDIO, audioDelay.resolve(engineState.audioDelaySeconds) + command.deltaSeconds)
            is PlayerCommand.SetAudioDelay -> setDelay(TrackKind.AUDIO, command.seconds)
            PlayerCommand.NextChapter -> nextChapter()
            PlayerCommand.PreviousChapter -> previousChapter()
            // While an item opens the session takes no other one: both buttons are off then too (PlayerStates.episodeButtons).
            PlayerCommand.NextEpisode -> if (!info.resolving && (info.nextEpisode != null || PlayerStates.entryAfter(info) != null)) update {
                dismissSkipBadge()
                playNextEpisode()
            }
            // Off live, previous always has a target: the episode before, or the start of this video. Live, the channel
            // before. Only where this device may change what plays.
            PlayerCommand.PreviousEpisode -> if (!info.resolving && (info.hasPreviousEpisode || !info.live) && watchUi?.canChangeEpisode != false) update {
                dismissSkipBadge()
                playPreviousEpisode()
            }
            PlayerCommand.SkipSegment -> update { skipSegment() }
            PlayerCommand.GoToLive -> rewindWindow()?.let { window ->
                abandonBurst()
                seekFromControls(window.windowSeconds)
            }
            PlayerCommand.Retry -> if (info.failure != null) update { session.retry() }
            is PlayerCommand.SetVideoFit -> update {
                ambientLighting?.suspend()
                fit = command.fit
                preferences.setVideoFit(info.item, command.fit)
                closePage(PlayerMenu.VIDEO_FIT)
            }
            is PlayerCommand.SetZoom -> setZoom(command.zoom)
            PlayerCommand.ZoomIn -> setZoom(zoom + VideoLayout.ZOOM_STEP)
            PlayerCommand.ZoomOut -> setZoom(zoom - VideoLayout.ZOOM_STEP)
            PlayerCommand.ResetZoom -> setZoom(1.0)
            is PlayerCommand.SetShaderPreset -> if (shaderFiles != null) update {
                shader = runnable(ShaderPreset.of(command.id, customShaders))
                if (shader != ShaderPreset.Off) ambientLighting?.offForShader()
                savedShader = shader.id
                preferences.setShaderPreset(info.item, shader.id)
                closePage(PlayerMenu.SHADERS)
            }
            PlayerCommand.ToggleShaders -> if (shaderFiles != null) update {
                shader = ShaderPreset.toggled(shader, runnable(ShaderPreset.of(savedShader, customShaders)), ShaderPreset.available(shaderFiles.renderer, customShaders))
                if (shader != ShaderPreset.Off) {
                    savedShader = shader.id
                    preferences.setShaderPreset(info.item, shader.id)
                }
                if (shader != ShaderPreset.Off) ambientLighting?.offForShader()
                if (menu == null) {
                    showOsd(if (shader == ShaderPreset.Off) T.player.osd.shadersOff else T.player.osd.shader(PlayerOptions.shaderLabel(shader)))
                }
            }
            is PlayerCommand.ImportShader -> if (shaderFiles != null && importsCustomShaders()) importShader(shaderFiles, command.fileName, command.source)
            PlayerCommand.ShaderImportFailed -> if (shaderFiles != null && importsCustomShaders()) update { showOsd(T.player.options.shader.importFailed) }
            is PlayerCommand.DeleteShader -> if (shaderFiles != null) deleteShader(shaderFiles, command.id)
            PlayerCommand.ToggleAmbientLighting -> ambientLighting?.let { ambient -> update { if (ambient.toggle()) onAmbientLightingOn() } }
            // Set, the timer says so in a message, as the sheet's pick did ("Sleep timer set for 30 minutes").
            is PlayerCommand.SetSleepTimer -> update {
                sleep.set(command.minutes)
                closePage(PlayerMenu.SLEEP_TIMER)
                showOsd(T.messages.sleepTimerSet(label = T.player.options.sleepMinutes(command.minutes)))
            }
            PlayerCommand.SleepAtEndOfVideo -> update {
                sleep.setAtEndOfVideo()
                closePage(PlayerMenu.SLEEP_TIMER)
                showOsd(T.messages.sleepTimerSet(label = T.player.options.sleepEndOfVideo))
            }
            PlayerCommand.CancelSleepTimer -> update {
                sleep.cancel()
                closePage(PlayerMenu.SLEEP_TIMER)
            }
            PlayerCommand.KeepWatching -> update { sleep.keepWatching() }
            is PlayerCommand.SetAutoPlayNext -> if (info.nextEpisode != null) session.setAutoPlayNext(command.enabled)
            is PlayerCommand.SetAudioNormalization -> update {
                normalization = command.enabled
                preferences.setAudioNormalization(command.enabled)
            }
            PlayerCommand.ToggleInfo -> update {
                infoShown = !infoShown
                preferences.setShowPlaybackInfo(infoShown)
            }
            is PlayerCommand.SetAudioChannels -> update {
                channels = command.channels
                preferences.setAudioChannels(command.channels)
                closePage(PlayerMenu.AUDIO_CHANNELS)
            }
            is PlayerCommand.SetAudioDevice -> update {
                audioDevice.request(command.name)
                // Already playing there: nothing will report it, so it is kept now.
                if (command.name == engineState.audioDevice) {
                    keptOutput = command.name
                    preferences.setAudioOutputDevice(command.name)
                } else {
                    pickedOutput = command.name
                }
                engine.setAudioDevice(command.name)
                closePage(PlayerMenu.AUDIO_OUTPUT)
            }
            is PlayerCommand.SetHdr -> {
                val output = hdrOutput
                if (output != null && engine.features.hdrControl && hdrRequest == null) setHdr(command.enabled, output)
            }
            is PlayerCommand.SetDolbyVisionConversion -> {
                val output = dvConversionOutput
                if (config.development && engine.features.dolbyVisionConversion && output != null) update {
                    dolbyVisionConversion = command.mode
                    output(command.mode)
                    closePage(PlayerMenu.DOLBY_VISION_CONVERSION)
                }
            }
            is PlayerCommand.SimulateHttpStatus -> if (config.development) update {
                menu = null
                session.simulateHttpError(command.status)
            }
            PlayerCommand.ShowControls -> update { show() }
            PlayerCommand.HideControls -> hideControls()
            PlayerCommand.ToggleControls -> update { if (controlsVisible()) chrome.hide() else show() }
            PlayerCommand.LockScreen -> lockScreen()
            is PlayerCommand.UnlockHold -> holdUnlock(command.held)
            PlayerCommand.UnlockPress -> unlockPress()
            is PlayerCommand.OpenMenu -> if (info.failure == null && lock == null) update {
                watchFromOptions = command.menu == PlayerMenu.WATCH_TOGETHER && (menu == PlayerMenu.OPTIONS || (menu == PlayerMenu.WATCH_TOGETHER && watchFromOptions))
                menu = command.menu
                show()
                when (command.menu) {
                    PlayerMenu.SUBTITLE_SEARCH -> if (info.subtitleSearch) openSubtitleSearch()
                    PlayerMenu.FILE_INFO -> if (info.fileInfo && !info.live) loadFileInfo()
                    else -> Unit
                }
            }
            PlayerCommand.CloseMenu -> update { menu = null }
            PlayerCommand.Back -> back()
            PlayerCommand.Close -> host.close()
            is PlayerCommand.Watch -> update { watch?.execute(command.command) }
            is PlayerCommand.SelectVersion -> update {
                if (command.index != info.versionIndex) session.selectVersion(command.index)
                closePage(PlayerMenu.VERSIONS)
            }
            is PlayerCommand.SelectQuality -> update {
                if (command.preset != info.quality?.selected) session.selectQuality(command.preset)
                closePage(PlayerMenu.VERSIONS)
            }
            is PlayerCommand.SelectSourceTrack -> update {
                session.selectSourceTrack(command.kind, command.id)
                if (menu == PlayerMenu.TRACKS || menu == PlayerMenu.AUDIO) menu = null
            }
            PlayerCommand.ForceTranscode -> if ((info.failure as? PlaybackFailure.ServerLimit)?.transcodeOffered == true) {
                update { session.forceTranscode() }
            }
            is PlayerCommand.PlayQueueItem -> update {
                abandonBurst()
                session.playQueueItem(command.key)
                menu = null
            }
            is PlayerCommand.SeekToChapter -> if (command.index in chapters().indices) {
                update { closePage(PlayerMenu.CHAPTERS) }
                seekToChapter(command.index)
            }
            is PlayerCommand.AnswerChoice -> if (info.choice != null) session.answerChoice(command.index)
            PlayerCommand.ToggleRotationLock -> if (config.profile == InputProfile.TOUCH) update {
                rotationLocked = !rotationLocked
                preferences.setRotationLocked(rotationLocked)
            }
            PlayerCommand.ToggleAlwaysOnTop -> if (host.keepsOnTop) update {
                val onTop = alwaysOnTop != true
                alwaysOnTop = onTop
                host.setAlwaysOnTop(onTop)
                preferences.setAlwaysOnTop(onTop)
            }
            is PlayerCommand.SearchSubtitles -> if (info.subtitleSearch) searchSubtitles(command)
            is PlayerCommand.DownloadSubtitle -> if (info.subtitleSearch) downloadSubtitle(command.key)
            PlayerCommand.ExtendSleepTimer -> update { sleep.extend() }
        }
    }

    /** The search sheet opened: it searches at once, for the video's title, in the language kept or the viewer's own. */
    private fun openSubtitleSearch() {
        searchDebounce?.cancel()
        searchLanguage = SubtitleSearch.language(storedSearchLanguage, T.locale)
        searchTitle = null
        searchHits = emptyList()
        runSearch()
    }

    /**
     * A new language is kept and searched at once, as is a submitted title ([PlayerCommand.SearchSubtitles.now]); an
     * edit of the title searches once it rests for [SEARCH_DEBOUNCE].
     */
    private fun searchSubtitles(command: PlayerCommand.SearchSubtitles) = update {
        val language = SubtitleSearch.iso6391(command.language) ?: return@update
        searchDebounce?.cancel()
        searchTitle = command.title?.trim()?.takeIf { it.isNotEmpty() }
        when {
            language != searchLanguage -> {
                searchLanguage = language
                preferences.setSubtitleSearchLanguage(language)
                runSearch()
            }
            command.now -> runSearch()
            else -> searchDebounce = scope.launch {
                delay(SEARCH_DEBOUNCE)
                update { runSearch() }
            }
        }
    }

    private fun runSearch() {
        val language = searchLanguage ?: return
        val title = searchTitle
        searching = true
        searchMessage = null
        searchJob?.cancel()
        searchJob = scope.launch {
            val hits = try {
                session.searchSubtitles(language, title)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "The subtitle search failed" }
                update {
                    searching = false
                    searchHits = emptyList()
                    searchMessage = T.errors.searchFailed(localizedErrorReason(e))
                }
                return@launch
            }
            update {
                searching = false
                searchHits = hits
                searchMessage = if (hits.isEmpty()) T.videoControls.noSubtitlesFound else null
            }
        }
    }

    /**
     * Downloads result [key], one at a time; the outcome is the sheet's message, and a subtitle that shows closes the
     * sheet with it as the toast.
     */
    private fun downloadSubtitle(key: String) = update {
        if (downloadingSubtitle != null) return@update
        downloadingSubtitle = key
        scope.launch {
            val outcome = try {
                session.downloadSubtitle(key)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "The subtitle download failed" }
                null
            }
            update {
                downloadingSubtitle = null
                val text = when (outcome) {
                    SubtitleDownloadOutcome.APPLIED -> T.videoControls.subtitleDownloaded
                    SubtitleDownloadOutcome.NOT_APPLIED -> T.videoControls.subtitleDownloadedNotApplied
                    SubtitleDownloadOutcome.TIMED_OUT -> T.videoControls.subtitleDownloadTimedOut
                    null -> T.videoControls.subtitleDownloadFailed
                }
                searchMessage = text
                if (outcome == SubtitleDownloadOutcome.APPLIED) {
                    closePage(PlayerMenu.SUBTITLE_SEARCH)
                    showOsd(text, OsdIcon.SUBTITLES)
                }
            }
        }
    }

    /** The file info page loads each time it opens: every version's info, or why there is none. */
    private fun loadFileInfo() {
        // The episode itself, not its show: "Show · S1 E2 · Title".
        val title = info.item?.let(::formatMediaTargetLabel) ?: info.title
        fileInfo = FileInfoState(loading = true, info = null, title = title, error = null)
        fileInfoJob?.cancel()
        fileInfoJob = scope.launch {
            val loaded = try {
                session.loadFileInfo()
                    ?.let { FileInfoState(loading = false, info = it, title = title, error = null) }
                    ?: FileInfoState(loading = false, info = null, title = title, error = T.messages.fileInfoNotAvailable)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Couldn't load the file info" }
                FileInfoState(loading = false, info = null, title = title, error = T.messages.errorLoadingFileInfo(localizedErrorReason(e)))
            }
            update { fileInfo = loaded }
        }
    }

    /** The search sheet's state, where the server has subtitle search. */
    private fun subtitleSearchState(locale: String): SubtitleSearchState? {
        if (!info.subtitleSearch || info.live) return null
        val code = searchLanguage ?: SubtitleSearch.language(storedSearchLanguage, locale)
        return SubtitleSearchState(
            language = SubtitleSearch.name(code, locale),
            languageCode = code,
            languages = searchLanguages(Triple(code, locale, searchTitle)),
            title = searchTitle ?: info.title,
            searching = searching,
            results = searchHits.map { SubtitleResult(it.key, it.label, it.detail, PlayerCommand.DownloadSubtitle(it.key)) },
            downloading = downloadingSubtitle,
            message = searchMessage,
        )
    }

    /**
     * A play or pause the viewer gave, accepted: while the controls are hidden its glyph flashes in the middle
     * ([PlayerUiState.transportFlash]); a play from a pause first seeks back the profile's rewind on resume
     * ([SessionInfo.rewindOnResumeSeconds]), never live, at the end or in a room the room's player plays.
     */
    private fun onUserTransport(play: Boolean) = update {
        if (!controlsVisible()) {
            flashSerial += 1
            transportFlash = TransportFlash(paused = !play, serial = flashSerial)
            flashJob?.cancel()
            flashJob = scope.launch {
                delay(TRANSPORT_FLASH)
                update { transportFlash = null }
            }
        }
        val rewind = info.rewindOnResumeSeconds
        if (play && rewind > 0 && !info.live && engineState.loaded && !engineState.eof && watch?.routesControls != true) {
            val target = seekTo(displayPosition() - rewind)
            watch?.onLocalSeek(target)
        }
    }

    /**
     * A relative seek of [seconds] from the position shown (a pending seek's target while one is under way, so a burst
     * of skips adds up rather than starting over from where the engine still reports), within the file or the live
     * window. One that has nothing to travel through (at the start, at the end) seeks nowhere. With [badge] the
     * distance travelled goes on the seek badge ([registerSkipBadge]). With the controls hidden it seeks without raising
     * them: the badge tells it, and the picture and its subtitles stay uncovered.
     */
    private fun seekBy(seconds: Double, badge: Boolean) = update {
        if (!engineState.loaded) return@update
        val from = displayPosition()
        val target = seekTarget(from + seconds)
        if (badge) registerSkipBadge(seconds > 0, abs(target - from))
        when {
            target == from -> Unit
            controlsVisible() -> seekFromControls(target)
            else -> {
                val landed = seekTo(target)
                watch?.onLocalSeek(landed)
            }
        }
    }

    /**
     * Puts [travelSeconds] on the seek badge ([PlayerUiState.skipBadge]) for [SKIP_BADGE]: added to the total while the
     * badge shows the same direction ([forward]), the count starting over the other way. Nothing shows for a total
     * that rounds to no second unless a badge that way already shows, which holds its total as a press at the start or
     * the end travels nothing more. Every relative seek reaching the store through [onInput] (keys, a double tap, a
     * remote) comes here, and those from the views' buttons while the controls are hidden.
     */
    private fun registerSkipBadge(forward: Boolean, travelSeconds: Double) {
        val stacking = badgeShown && badgeForward == forward
        val total = if (stacking) badgeTotal + travelSeconds else travelSeconds
        if (!stacking && total.roundToInt() == 0) return
        badgeShown = true
        badgeForward = forward
        badgeTotal = total
        badgeSerial += 1
        badgeJob?.cancel()
        badgeJob = scope.launch {
            delay(SKIP_BADGE)
            update { dismissSkipBadge() }
        }
    }

    /** Takes the seek badge away with the timeline it was about: another episode, a queue's entry, the live edge. */
    private fun dismissSkipBadge() {
        badgeShown = false
        badgeTotal = 0.0
        badgeJob?.cancel()
        badgeJob = null
    }

    /**
     * In a room ([PlayerCommand.roomControl]): play, pause, every seek and the speed when the room lets this device
     * control them; the episode the host's. A guest's player paused here alone ([stopHere]) takes Play, which catches
     * it up with the room; Pause while the sleep timer asks is the timer's stop. The system's pause and resume are
     * always taken: in a room they pause or play this device alone for one who doesn't control playback
     * ([stopsHereAlone]).
     */
    private fun allowedInRoom(command: PlayerCommand): Boolean {
        val ui = watchUi ?: return true
        return when (command.roomControl) {
            RoomControl.EPISODE -> ui.canChangeEpisode
            RoomControl.PLAY -> ui.canControl || watch?.stoppedHere == true
            RoomControl.PAUSE -> ui.canControl || sleep.asking != null
            RoomControl.SPEED, RoomControl.SEEK -> ui.canControl
            RoomControl.FREE -> true
        }
    }

    /** A stop on this device pauses it alone ([stopHere]): in a room whose playback this device doesn't control. */
    private fun stopsHereAlone(): Boolean = watchUi?.canControl == false

    /** The system's pause, and Pause as the answer to the sleep timer's question: a stop on this device. */
    private fun PlayerCommand.stopsHere(): Boolean = this == PlayerCommand.SystemPause || this == PlayerCommand.Pause && sleep.asking != null

    /** The commands that end a stop on this device ([stopHere]): Play (TogglePause, paused as it is) and the system's resume. */
    private fun PlayerCommand.resumes(): Boolean =
        this == PlayerCommand.Play || this == PlayerCommand.TogglePause || this == PlayerCommand.SystemResume

    /**
     * Pauses this device alone, for one who doesn't control the room's playback: its player leaves the room's playback
     * first ([PlayerWatch.stopHere]), so the room neither waits for it nor plays it again, and plays on without it.
     */
    private fun stopHere() {
        watch?.stopHere()
        setPaused(true)
    }

    /**
     * Ends [stopHere]: the player joins the room's playback again, and the room catches it up, playing it if the room
     * plays. Made one who controls playback meanwhile, this device plays the room too.
     */
    private fun resumeHere(watch: PlayerWatch) {
        watch.resumeHere()
        if (watchUi?.canControl == true && watch.routesControls) playInRoom(watch)
    }

    /**
     * Takes the room's [ui]: once it stops letting this device control playback, a scrub or a held seek under way ends
     * without seeking.
     */
    private fun onWatchUi(ui: PlayerWatchUi?) {
        watchUi = ui
        // The room went (left, ended, kicked): its session sheet goes with it.
        if (ui == null && menu == PlayerMenu.WATCH_TOGETHER) menu = null
        if (ui?.canControl == false) {
            scrubber.end()
            burst.cancel()
            // The room's speed is no longer this device's to give back: the hold ends where it is.
            heldSpeedFrom = null
        }
    }

    /**
     * The live window this playback seeks in ([SessionInfo.liveWindow]), unless the player follows a watch-together
     * room ([PlayerWatch.routesControls]: the room's positions are the files'); null plays a live playback without
     * seeking, as layout C.
     */
    private fun rewindWindow(): LiveWindow? =
        info.liveWindow?.takeIf { info.live && watch?.routesControls != true }

    /**
     * Back takes the innermost layer away. Everywhere: the lock leaves the player; a scrub ends; a page goes back to its
     * menu, a menu closes; the session's question is dismissed; the sleep timer's question keeps watching. Up next at
     * the end of the file stands for a finished video: Back leaves the player at once. On a touch screen that is all,
     * and Back leaves the player with the controls up. Elsewhere it then dismisses the skip button while the controls
     * are hidden, up next, then hides the controls once there is a first frame (before it they stand for no
     * stage of their own: Back leaves the opening player at once), and leaves the player last.
     */
    private fun back() {
        val touch = config.profile == InputProfile.TOUCH
        when {
            lock != null -> host.close()
            scrubber.active -> update { scrubber.cancel() }
            menu == PlayerMenu.WATCH_TOGETHER && watchFromOptions -> update { menu = PlayerMenu.OPTIONS }
            menu?.back != null -> update { menu = menu?.back }
            menu != null -> update { menu = null }
            info.choice != null -> session.answerChoice(null)
            sleep.asking != null -> update { sleep.keepWatching() }
            upNext.shown && atItemEnd() -> host.close()
            touch -> host.close()
            skip.segment != null && skipPrompt() != null && !controlsVisible() -> update { dismissPrompt() }
            upNext.shown && upNextPrompt() != null -> update { dismissPrompt() }
            controlsVisible() && engineState.loaded && chrome.hide() -> update {}
            else -> host.close()
        }
    }

    /** A pick on an option's [page] closes the menu, as a pick of a speed does. */
    private fun closePage(page: PlayerMenu) {
        if (menu == page) menu = null
    }

    private fun setPaused(paused: Boolean) = update {
        this.paused.request(paused)
        engine.setPaused(paused)
        // Paused while the sleep timer asks: that is the answer, and the timer is done.
        if (paused && sleep.asking != null) sleep.cancel()
    }

    /**
     * Plays; at the end of the file it starts over. There mpv keeps the last frame and pauses again at once (keep-open),
     * so a bare unpause would leave the request to play pending and the button reading Pause while nothing plays. A live
     * playback paused until its window slid past the position plays from the window's start.
     */
    private fun playOrStartOver() = update {
        // A live playback that ended has nothing to start over: its stream is gone.
        if (engineState.loaded && engineState.eof && !info.live) {
            val target = seekTo(0.0)
            watch?.onLocalSeek(target)
        }
        val window = rewindWindow()
        if (window != null && pendingSeek == null && window.behind(engineState.positionSeconds) > window.windowSeconds) seekTo(0.0)
        setPaused(false)
    }

    /**
     * Plays [room]; at the end of the file or of the room's media it starts the room over, as [playOrStartOver] does
     * alone: the relay ends a room played from its end at once, so a bare play would only show "Finished" again. False
     * when the room left the press to the player (it refused to start in a playing room): the player then starts itself.
     */
    private fun playInRoom(room: PlayerWatch): Boolean {
        if (engineState.loaded && atItemEnd() && !info.live) room.onLocalSeek(0.0)
        return room.play()
    }

    /**
     * Ambient lighting came on: it draws the whole picture letterboxed, with no shader before it, so the shader goes
     * off and the picture back to Fit at its own size, both for this player only.
     */
    private fun onAmbientLightingOn() {
        shader = ShaderPreset.Off
        fit = VideoFit.CONTAIN
        zoom = 1.0
    }

    /**
     * The HDR switch: it shows [enabled] at once while the output plan takes it as its HDR input and the engine follows
     * ([followOutput]), which this device then keeps; refused, the switch goes back, nothing is kept, and the message
     * says the output can't carry HDR.
     */
    private fun setHdr(enabled: Boolean, output: suspend (Boolean) -> Boolean) = update {
        hdrRequest = enabled
        scope.launch {
            val applied = output(enabled)
            update {
                hdrRequest = null
                if (applied) {
                    hdr = enabled
                    preferences.setHdr(enabled)
                } else {
                    showOsd(T.videoSettings.hdrUnsupported)
                }
            }
        }
    }

    /**
     * Puts the engine on the output picked last ([keptOutput]), once, when it first lists its outputs with that one among
     * them. An output that isn't there leaves the engine on the system's choice and the pick kept for when it is back: a
     * forced output that can't open would play silence. An `audio-device` line of the user's mpv.conf wins over it.
     */
    private fun applyKeptOutput() {
        val kept = keptOutput ?: return
        val devices = engineState.audioDevices
        if (keptOutputTried || devices.isEmpty()) return
        keptOutputTried = true
        if (kept == PlayerOptions.AUTO_DEVICE || kept == engineState.audioDevice || devices.none { it.name == kept }) return
        audioDevice.request(kept)
        engine.setAudioDevice(kept)
    }

    /** The zoom, kept for the title, shows as a message when no menu shows it (keys; a pinch shows it once it ends). */
    private fun setZoom(target: Double) = update {
        ambientLighting?.suspend()
        zoom = VideoLayout.normalizeZoom(target)
        preferences.setVideoZoom(info.item, zoom)
        if (menu == null) showOsd(T.player.osd.zoom(PlayerOptions.zoomLabel(zoom)), OsdIcon.ZOOM)
        closePage(PlayerMenu.ZOOM)
    }

    /**
     * Keeps a copy of the `.glsl` file [fileName]'s [source] and runs it, named after the file; anything else, or a
     * copy that fails, says it couldn't import the shader.
     */
    private fun importShader(files: ShaderFiles, fileName: String, source: String) {
        val name = fileName.substringAfterLast('/').substringAfterLast('\\')
        if (!name.endsWith(GLSL, ignoreCase = true) || name.length == GLSL.length) {
            update { showOsd(T.player.options.shader.importFailed) }
            return
        }
        scope.launch {
            val stored = try {
                files.import(source)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Couldn't keep an imported shader" }
                update { showOsd(T.player.options.shader.importFailed) }
                return@launch
            }
            val custom = CustomShader("custom_$stored", name.dropLast(GLSL.length), stored)
            update {
                customShaders = customShaders + custom
                shader = ShaderPreset.Custom(custom)
                ambientLighting?.offForShader()
                savedShader = custom.id
                preferences.addCustomShader(info.item, custom)
                closePage(PlayerMenu.SHADERS)
                showOsd(T.player.options.shader.imported)
            }
        }
    }

    /** [preset], or off where this device's renderer doesn't run it ([ShaderPreset.runsOn]). */
    private fun runnable(preset: ShaderPreset): ShaderPreset {
        val renderer = shaderFiles?.renderer ?: return ShaderPreset.Off
        return if (preset.runsOn(renderer)) preset else ShaderPreset.Off
    }

    /** The Shaders page imports: the device has file dialogs and its renderer runs imported shaders. */
    private fun importsCustomShaders(): Boolean {
        val renderer = shaderFiles?.renderer ?: return false
        return importsShaders && renderer.runsCustomShaders
    }

    /** Forgets the imported shader [id] and deletes its copy; the shaders go off if it was running. */
    private fun deleteShader(files: ShaderFiles, id: String) {
        val custom = customShaders.firstOrNull { it.id == id } ?: return
        update {
            customShaders = customShaders - custom
            if (shader.id == id) shader = ShaderPreset.Off
            preferences.removeCustomShader(custom)
        }
        scope.launch {
            try {
                files.delete(custom.fileName)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Couldn't delete an imported shader's file" }
            }
        }
    }

    /**
     * Every change of the volume by the viewer shows as a toast, with the icon of its level, and is kept for the next
     * playback once the changes stop for [VOLUME_SAVE_DELAY] (a wheel turns it many times a second), or as the player closes.
     */
    private fun setVolume(percent: Double) = update {
        val current = volume.resolve(engineState.volume)
        val target = percent.coerceIn(0.0, maxVolume.toDouble())
        volume.request(target)
        engine.setVolume(target)
        unsavedVolume = target
        volumeSave?.cancel()
        volumeSave = scope.launch {
            delay(VOLUME_SAVE_DELAY)
            saveVolume()
        }
        // Turning the volume up while muted means "I want to hear it".
        if (target > current && muted.resolve(engineState.muted)) {
            muted.request(false)
            engine.setMuted(false)
        }
        showOsd(T.player.osd.volume(PlayerText.volume(target.roundToInt())), volumeIcon(target.roundToInt()))
    }

    private fun saveVolume() {
        unsavedVolume?.let(preferences::setVolume)
        unsavedVolume = null
    }

    private fun toggleMute() = update {
        val mute = !muted.resolve(engineState.muted)
        muted.request(mute)
        engine.setMuted(mute)
        val level = volume.resolve(engineState.volume).roundToInt()
        if (mute) showOsd(T.player.volume.muted, OsdIcon.VOLUME_OFF) else showOsd(T.player.osd.volume(PlayerText.volume(level)), volumeIcon(level))
    }

    /** The volume toast's icon: off at 0, down below half, up from there. */
    private fun volumeIcon(percent: Int): OsdIcon = when {
        percent == 0 -> OsdIcon.VOLUME_OFF
        percent < 50 -> OsdIcon.VOLUME_DOWN
        else -> OsdIcon.VOLUME_UP
    }

    private fun setFullscreen(fullscreen: Boolean) {
        update { fullscreenChanged(fullscreen) }
        host.setFullscreen(fullscreen)
    }

    private fun fullscreenChanged(fullscreen: Boolean) {
        if (fullscreen != this.fullscreen) ownsFullscreen = fullscreen
        this.fullscreen = fullscreen
    }

    /**
     * The viewer's speed: the room's too, in a room; kept for the title ([PlayerSession.onSpeedChanged]). It shows as a
     * toast (fast forward from normal speed up, slow motion below) when no menu shows it and it changed the speed by
     * [PlayerText.SPEED_TOAST_EPSILON] or more, unless a room it follows owns the rate. A held finger's speed and its
     * release ([holdSpeed]) and the room's nudges never come here: they show no toast.
     */
    private fun applySpeed(value: Double) {
        val before = roomSpeed ?: speed.resolve(engineState.speed)
        setSpeed(value)
        session.onSpeedChanged(value)
        if (menu == null && watchUi?.following != true && abs(value - before) >= PlayerText.SPEED_TOAST_EPSILON) {
            showOsd(T.player.osd.speed(PlayerText.speed(value)), if (value >= 1.0) OsdIcon.FAST_FORWARD else OsdIcon.SLOW_MOTION)
        }
    }

    private fun setSpeed(value: Double) {
        speed.request(value)
        roomSpeed = null
        engine.setSpeed(value)
        watch?.onLocalRate(value)
    }

    /**
     * A finger held on the video: [HOLD_SPEED] until it lifts ([releaseSpeed]), which gives back the speed shown before
     * (the room's, in a room, whose speed the hold changes for everyone). The held speed shows instead of the OSD; giving
     * it back shows no speed message.
     */
    private fun holdSpeed() {
        if (heldSpeedFrom != null) return
        update {
            heldSpeedFrom = roomSpeed ?: speed.resolve(engineState.speed)
            setSpeed(HOLD_SPEED)
        }
    }

    private fun releaseSpeed() {
        val from = heldSpeedFrom ?: return
        update {
            heldSpeedFrom = null
            setSpeed(from)
        }
    }

    /** The speed shortcuts: [SPEED_STEP] up or down, within the player's slowest and fastest. */
    private fun stepSpeed(up: Boolean) = update {
        val current = roomSpeed ?: speed.resolve(engineState.speed)
        val next = ((current + if (up) SPEED_STEP else -SPEED_STEP) * 100).roundToLong() / 100.0
        val target = next.coerceIn(PlayerConfig.MIN_SPEED, PlayerConfig.MAX_SPEED)
        if (abs(target - current) > PlayerText.SPEED_EPSILON) applySpeed(target)
    }

    /** The viewer's sync offset of [kind]: kept for the title ([PlayerSession.onSyncOffsetChanged]). */
    private fun setDelay(kind: TrackKind, seconds: Double) = update {
        // Kept to the millisecond, so steps of 0.1 add up to 0.3 and not 0.30000000000000004.
        val target = ((seconds * 1000).roundToLong() / 1000.0).coerceIn(-config.maxDelaySeconds, config.maxDelaySeconds)
        if (kind == TrackKind.SUBTITLE) {
            subtitleDelay.request(target)
            engine.setSubtitleDelay(target)
            session.onSyncOffsetChanged(audio = false, seconds = target)
            if (menu == null) showOsd(T.player.osd.subtitleDelay(PlayerText.delay(target)))
        } else {
            audioDelay.request(target)
            engine.setAudioDelay(target)
            session.onSyncOffsetChanged(audio = true, seconds = target)
            if (menu == null) showOsd(T.player.osd.audioDelay(PlayerText.delay(target)))
        }
    }

    /**
     * Selects a track; [announce] shows the choice as a message (a cycling key: no menu shows it). Subtitles off turn
     * the second subtitle off too, and the second's track becoming the subtitle turns it off first, as mpv shows a
     * track once.
     */
    private fun selectTrack(kind: TrackKind, id: Long?, announce: Boolean) = update {
        val second = selectedSecondSubtitle()
        if (kind == TrackKind.SUBTITLE && second != null && (id == null || id == second)) selectSecondSubtitle(null)
        session.onTrackSelected(kind, id)
        engine.selectTrack(kind, id)
        when (kind) {
            TrackKind.AUDIO -> {
                audioTrack.request(TrackChoice(id))
                if (menu == PlayerMenu.AUDIO) menu = null
            }
            TrackKind.SUBTITLE -> {
                subtitleTrack.request(TrackChoice(id))
                if (menu == PlayerMenu.SUBTITLES) menu = null
            }
            TrackKind.VIDEO -> {}
        }
        if (announce && menu == null) {
            val track = engineState.tracks.firstOrNull { it.kind == kind && it.id == id }
            val locale = T.locale
            showOsd(
                when {
                    kind == TrackKind.AUDIO && track != null -> T.player.osd.audioTrack(TrackLabels.label(track, engineState.tracks, locale))
                    track != null -> T.player.osd.subtitleTrack(TrackLabels.label(track, engineState.tracks, locale))
                    else -> T.player.osd.subtitlesOff
                },
                if (kind == TrackKind.AUDIO) OsdIcon.AUDIO else OsdIcon.SUBTITLES,
            )
        }
    }

    /** [PlayerCommand.ToggleSecondSubtitle]: the menu stays open, its rows showing the change. */
    private fun toggleSecondSubtitle(id: Long?) = update {
        val second = selectedSecondSubtitle()
        when {
            id == null || id == second -> if (second != null) selectSecondSubtitle(null)
            id != selectedTrack(TrackKind.SUBTITLE) -> selectSecondSubtitle(id)
        }
    }

    private fun selectSecondSubtitle(id: Long?) {
        session.onSecondSubtitleSelected(id)
        engine.selectSecondSubtitle(id)
        secondSubtitleTrack.request(TrackChoice(id))
    }

    private fun cycleAudio() {
        val ids = engineState.tracks.filter { it.kind == TrackKind.AUDIO }.map { it.id }
        if (ids.isEmpty()) return
        val current = selectedTrack(TrackKind.AUDIO)
        selectTrack(TrackKind.AUDIO, ids[(ids.indexOf(current) + 1) % ids.size], announce = true)
    }

    /**
     * The subtitle cycle: through the server's subtitles while they are the choice ([SessionInfo.sourceSubtitles]),
     * else through the engine's tracks, picked as the viewer's choice.
     */
    private fun cycleSubtitles() {
        if (info.sourceSubtitles.isNotEmpty()) return session.cycleSourceSubtitles()
        val ids: List<Long?> = engineState.tracks.filter { it.kind == TrackKind.SUBTITLE }.map { it.id } + null
        if (ids.size == 1) return
        val current = selectedTrack(TrackKind.SUBTITLE)
        selectTrack(TrackKind.SUBTITLE, ids[(ids.indexOf(current) + 1) % ids.size], announce = true)
    }

    /**
     * The subtitle shortcut: hides the subtitles shown, keeping their track for the next press, which shows them
     * again; without subtitles it does nothing. Not remembered as a choice of track. Subtitles the server burns into
     * the transcode are pixels, not a track: the message points to the subtitle menu, where changing them is a choice.
     */
    private fun toggleSubtitles() = update {
        val hidden = hiddenSubtitle
        val shown = selectedTrack(TrackKind.SUBTITLE)
        when {
            shown == null && hidden == null && info.transcoding && info.sourceSubtitles.any { it.selected } ->
                showOsd(T.messages.burnedSubtitlesUseMenu)
            shown != null -> {
                hiddenSubtitle = shown
                subtitleTrack.request(TrackChoice(null))
                engine.selectTrack(TrackKind.SUBTITLE, null)
                if (menu == null) showOsd(T.player.osd.subtitlesOff)
            }
            hidden != null && engineState.tracks.any { it.kind == TrackKind.SUBTITLE && it.id == hidden } -> {
                hiddenSubtitle = null
                subtitleTrack.request(TrackChoice(hidden))
                engine.selectTrack(TrackKind.SUBTITLE, hidden)
                val track = engineState.tracks.first { it.kind == TrackKind.SUBTITLE && it.id == hidden }
                if (menu == null) showOsd(T.player.osd.subtitleTrack(isolate(TrackLabels.label(track, engineState.tracks, T.locale))))
            }
        }
    }

    private fun selectedTrack(kind: TrackKind): Long? {
        val reported = TrackChoice(engineState.tracks.firstOrNull { it.kind == kind && it.selected }?.id)
        return (if (kind == TrackKind.AUDIO) audioTrack else subtitleTrack).resolve(reported).id
    }

    private fun selectedSecondSubtitle(): Long? =
        secondSubtitleTrack.resolve(TrackChoice(engineState.tracks.firstOrNull { it.kind == TrackKind.SUBTITLE && it.secondary }?.id)).id

    /** The chapters: the server's ([SessionInfo.chapters]) when it lists them, else the engine's. */
    private fun chapters(): List<Chapter> =
        info.chapters?.map { Chapter(it.title, it.startSeconds) } ?: engineState.chapters

    /** The chapter playing at [position]: the last that starts at or before it, -1 before the first. */
    private fun chapterAt(chapters: List<Chapter>, position: Double): Int =
        chapters.indexOfLast { it.startSeconds <= position + CHAPTER_TOLERANCE_SECONDS }

    /** The chapter Next chapter seeks to from [position]: the first starting after it; null past the last one's start. */
    private fun nextChapterIndex(chapters: List<Chapter>, position: Double): Int? =
        chapters.indexOfFirst { it.startSeconds > position + CHAPTER_TOLERANCE_SECONDS }.takeIf { it >= 0 }

    /**
     * The chapter Previous chapter seeks to from [position]: just past a chapter's start the one before, later this
     * chapter's start; -1 (the start of the video) before the first chapter.
     */
    private fun previousChapterIndex(chapters: List<Chapter>, position: Double): Int {
        val current = chapterAt(chapters, position)
        return when {
            current > 0 && position - chapters[current].startSeconds < PREVIOUS_CHAPTER_GRACE_SECONDS -> current - 1
            else -> current
        }
    }

    private fun nextChapter() {
        nextChapterIndex(chapters(), displayPosition())?.let { seekToChapter(it) }
    }

    private fun previousChapter() {
        val chapters = chapters()
        if (chapters.isEmpty()) return
        val index = previousChapterIndex(chapters, displayPosition())
        if (index < 0) seekFromControls(0.0) else seekToChapter(index)
    }

    private fun seekToChapter(index: Int, showControls: Boolean = true) = update {
        if (!engineState.loaded) return@update
        val chapter = chapters()[index]
        val target = seekTo(chapter.startSeconds)
        watch?.onLocalSeek(target)
        if (showControls) show()
        if (menu == null) {
            val title = chapter.title?.takeIf { it.isNotBlank() }
            showOsd(if (title != null) T.player.osd.chapter(isolate(title)) else T.player.osd.chapterNumbered((index + 1).toString()))
        }
    }

    // Seeking and scrubbing

    /**
     * The position the controls show and seek from: the engine's in the file; live with a window ([rewindWindow]),
     * its place in the window, from 0 at the window's start to [LiveWindow.windowSeconds] at the live edge.
     */
    private fun displayPosition(): Double = burst.target ?: pendingSeek ?: playedPosition()

    private fun playedPosition(): Double {
        val window = rewindWindow() ?: return engineState.positionSeconds
        return (window.windowSeconds - window.behind(engineState.positionSeconds)).coerceIn(0.0, window.windowSeconds)
    }

    /** What the controls seek within ([displayPosition]): the file's duration, or the live window's length. */
    private fun seekDuration(): Double = rewindWindow()?.windowSeconds ?: engineState.durationSeconds

    /** Seeks to [seconds] for the viewer; [showControls] false leaves the controls as they are (a key's seek). */
    private fun seekFromControls(seconds: Double, showControls: Boolean = true) = update {
        if (!engineState.loaded) return@update
        val target = seekTo(seconds)
        watch?.onLocalSeek(target)
        if (showControls) show()
    }

    /**
     * Seeks exactly to [seconds] (within the file) and returns where. mpv lands a keyframe seek on the keyframe at or
     * before its target: with keyframes further apart than the seek step (250 frames, x264's and x265's default, are
     * 10.4 s at 23.976 fps) a step forward would land anywhere from the step on to back where it started, or before.
     * Live with a window, [seconds] is a place in it ([displayPosition]), which the session reaches
     * ([PlayerSession.seekLive]); the live edge itself within [LiveWindow.atEdge].
     */
    private fun seekTo(seconds: Double, engineSeek: Boolean = true): Double {
        val duration = seekDuration()
        val target = seekTarget(seconds)
        // A seek elsewhere supersedes a key burst's target; the burst's own has left it already.
        burst.cancel()
        pendingSeek = target
        pendingSeekJob?.cancel()
        pendingSeekJob = scope.launch {
            delay(SEEK_SETTLE_TIMEOUT)
            update { pendingSeek = null }
        }
        val window = rewindWindow()
        if (window != null) {
            val behind = duration - target
            session.seekLive(if (window.atEdge(behind)) 0.0 else behind)
            return target
        }
        session.onSeek(target)
        if (engineSeek) engine.seek(target, exact = true)
        return target
    }

    /** [seconds] within what the controls seek in ([seekDuration]). */
    private fun seekTarget(seconds: Double): Double {
        val duration = seekDuration()
        return if (duration > 0) seconds.coerceIn(0.0, duration) else seconds.coerceAtLeast(0.0)
    }

    /**
     * Moves the drag's preview to [fraction]. A video seeks along ([Scrubber]); a live window (each seek reopens the
     * stream) and a watch-together room (each seek is the room's) wait for the release.
     */
    private fun scrubTo(fraction: Double) = update {
        val duration = seekDuration()
        if (!engineState.loaded || duration <= 0) return@update
        val follow = rewindWindow() == null && !info.live && watch?.routesControls != true
        scrubber.dragTo(fraction.coerceIn(0.0, 1.0) * duration, from = displayPosition(), follow = follow)
    }

    private fun commitScrub() = update { scrubber.commitNow() }

    /** The release: the seek to [seconds], left out when the drag's last seek went [alreadyThere]. */
    private fun onScrubCommitted(seconds: Double, alreadyThere: Boolean) {
        val target = seekTo(seconds, engineSeek = !alreadyThere)
        watch?.onLocalSeek(target)
        show()
    }

    // Controls visibility

    private fun status(): PlaybackStatus = when {
        info.failure != null -> PlaybackStatus.FAILED
        info.resolving -> PlaybackStatus.RESOLVING
        !engineState.loaded || displayNegotiating -> PlaybackStatus.OPENING
        engineState.eof && !upNext.counting -> PlaybackStatus.ENDED
        paused.resolve(engineState.paused) -> PlaybackStatus.PAUSED
        engineState.buffering && bufferingTold -> PlaybackStatus.BUFFERING
        else -> PlaybackStatus.PLAYING
    }

    /**
     * What [chrome] goes by, from the state: its holds (picture in picture, the content strip, a menu, the sleep
     * timer's question, a failure or an assistive technology, a scrub), the play state, the first frame and the delay.
     * A pause, from here or elsewhere (a media key, the sleep timer, a room, a cast sender), shows the controls, which
     * stay while paused: a frozen picture never shows without its play button. The end of the file shows them too.
     */
    private fun syncChrome() {
        fun holdIf(hold: ChromeHold, on: Boolean) = if (on) chrome.hold(hold) else chrome.release(hold)
        holdIf(ChromeHold.PIP, pictureInPicture)
        holdIf(ChromeHold.CONTENT_STRIP, menu == PlayerMenu.CONTENT_STRIP)
        holdIf(
            ChromeHold.PROMPT_INTERACTION,
            menu != null && menu != PlayerMenu.CONTENT_STRIP || sleep.asking != null || info.failure != null || assistiveTechnology,
        )
        holdIf(ChromeHold.SCRUB, scrubber.active)
        val delay = if (config.profile == InputProfile.TOUCH || directional()) TOUCH_HIDE_DELAY else MOUSE_HIDE_DELAY
        chrome.configure(hideDelay = delay, hasFirstFrame = engineState.loaded)
        val ended = engineState.loaded && engineState.eof
        val pausedNow = engineState.loaded && !ended && paused.resolve(engineState.paused)
        chrome.setPlaying(engineState.loaded && !ended && !pausedNow)
        if (ended && !wasEnded || pausedNow && !wasPaused) chrome.show()
        wasEnded = ended
        wasPaused = pausedNow
    }

    /**
     * A wait the engine reports ([EngineState.buffering]) shows as [PlaybackStatus.BUFFERING] once it has lasted
     * [BUFFERING_GRACE]: one that ends sooner (a seek within what is read ahead) shows nothing.
     */
    private fun followBuffering(buffering: Boolean) {
        bufferingJob?.cancel()
        bufferingTold = false
        bufferingJob = if (buffering) {
            scope.launch {
                delay(BUFFERING_GRACE)
                update { bufferingTold = true }
            }
        } else {
            null
        }
    }

    /** [PlayerUiState.keepAwake]: playing, or on the way to it, unpaused and in sight. */
    private fun keepAwake(status: PlaybackStatus, paused: Boolean): Boolean =
        !released && !paused && (visible || pictureInPicture) && (status == PlaybackStatus.PLAYING || status.isLoading)

    private fun controlsVisible(): Boolean = lock == null && chrome.visible

    /** A new serial each time [chrome] asks for Play/Pause to take focus. */
    private fun playPauseFocus(): Int {
        if (chrome.takePlayPauseFocus()) playPauseFocusSerial += 1
        return playPauseFocusSerial
    }

    /** Shows the controls and restarts the auto-hide timer. */
    private fun show() {
        chrome.show()
    }

    private fun hideControls() = update { chrome.hide() }

    /**
     * Drops a key burst's pending seek and its badge: what plays is about to change (another episode, a queue's entry)
     * or jump to the live edge, and neither describes it any more.
     */
    private fun abandonBurst() {
        burst.cancel()
        dismissSkipBadge()
    }

    private fun showOsd(text: String, icon: OsdIcon? = null) {
        osd = text
        osdIcon = icon
        level = null
        hideOsdLater()
    }

    /** [kind] at [fraction], as an edge swipe leaves it. */
    private fun levelIndicator(kind: LevelKind, fraction: Double): LevelIndicator {
        val shown = fraction.coerceIn(0.0, 1.0)
        val percent = PlayerText.volume((shown * 100).roundToInt())
        val label = when (kind) {
            LevelKind.BRIGHTNESS -> T.player.osd.brightness(percent)
            LevelKind.VOLUME -> T.player.osd.volume(percent)
        }
        return LevelIndicator(kind, shown.toFloat(), percent, label)
    }

    /**
     * A double tap in a skip zone: the seek step that way, as far as the video goes, leaving the controls as they were
     * (the skip badge says it). One that would move nothing (at the start, or at or past the end) seeks nothing; live,
     * within the window, and nothing without one. It replaces a key burst still pending, and the badge then counts the
     * tap's step alone.
     */
    private fun touchSkip(forward: Boolean) {
        if (!canControl()) return refuse()
        if (!keySeekable()) return
        if (burst.target != null) {
            burst.cancel()
            dismissSkipBadge()
        }
        val from = seekTarget(displayPosition())
        val to = seekTarget(from + if (forward) seekSeconds else -seekSeconds)
        update { registerSkipBadge(forward, abs(to - from)) }
        if (to != from) seekFromControls(to, showControls = false)
    }

    /** The brightness the player opens at, while the profile remembers one and brightness swipes are on. */
    private fun rememberedLevel(): Double? = rememberedBrightness?.takeIf { rememberBrightness && brightnessSwipe }

    /** What [touch] ([TouchGestures]) does to the player. */
    internal inner class TouchHooks {
        /** The screen lock is on: a touch only shows or hides the unlock button. */
        val locked: Boolean get() = lock != null

        /** Two-finger taps, pinches and edge swipes act: not locked, not in picture in picture, no content strip open. */
        val gesturesAllowed: Boolean
            get() = lock == null && !pictureInPicture && menu != PlayerMenu.CONTENT_STRIP

        /** A tap goes to the skip zones and a hold plays at 2×: gestures act and no menu or error lies over the video. */
        val zonesActive: Boolean get() = gesturesAllowed && menu == null && info.failure == null

        val levels: DeviceLevels? get() = host.levels

        /** Swipes on [kind]'s edge are on (the device's settings). */
        fun edgeEnabled(kind: LevelKind): Boolean = when (kind) {
            LevelKind.BRIGHTNESS -> brightnessSwipe
            LevelKind.VOLUME -> volumeSwipe
        }

        /** A lone tap: in the middle of the video ([centre]) or in a skip zone, or anywhere while the zones don't act. */
        fun tap(centre: Boolean) = when {
            // The content strip keeps the controls up while it is open; a sheet closes.
            menu == PlayerMenu.CONTENT_STRIP -> Unit
            menu != null -> execute(PlayerCommand.CloseMenu)
            info.failure != null -> Unit
            centre && !controlsVisible() && info.videoClick == VideoClickAction.PAUSE && watchUi?.canControl != false ->
                execute(PlayerCommand.TogglePause)
            else -> execute(PlayerCommand.ToggleControls)
        }

        /** A double tap in a skip zone. */
        fun skip(forward: Boolean) = touchSkip(forward)

        fun twoFingerTap() = execute(PlayerCommand.TogglePause)

        /** A finger held still on the video, or (false) lifted after that. */
        fun hold(held: Boolean) = holdOnVideo(held)

        /** Two fingers apart [scale] times as far as they went down; [pinchEnd] once one lifts. */
        fun pinch(scale: Double) {
            if (pinchToZoom) onPinch(scale)
        }

        fun pinchEnd() = onPinchEnd()

        /** An edge swipe set [kind] to [value]: its indicator shows it. */
        fun level(kind: LevelKind, value: Double) = update {
            osdJob?.cancel()
            osd = null
            level = levelIndicator(kind, value)
        }

        fun hideLevel() = update { level = null }

        /** An edge swipe took over: the controls stay as they are until it ends. */
        fun swipeStarted() = chrome.cancelAutoHide()

        /** The edge swipe ended; [brightness] is the level a brightness swipe settled on, null for the volume. */
        fun swipeEnded(brightness: Double?) {
            if (controlsVisible()) chrome.restartAutoHide()
            if (brightness != null && rememberBrightness) preferences.setRememberedBrightness(brightness)
        }

        /** A tap on the locked screen. */
        fun lockedTap() = setUnlock(if (lock == UnlockStage.HIDDEN) UnlockStage.SHOWN else UnlockStage.HIDDEN)

        /** A second finger on the locked screen. */
        fun lockedMultiTouch() {
            if (lock != UnlockStage.HIDDEN) setUnlock(UnlockStage.HIDDEN)
        }
    }

    /** A finger, or a mouse's press, held on the video ([held]) or lifted: 2× while held, never live. */
    private fun holdOnVideo(held: Boolean) = when {
        !held -> execute(PlayerCommand.ReleaseSpeed)
        info.live -> Unit
        else -> execute(PlayerCommand.HoldSpeed)
    }

    private fun hideOsdLater() {
        osdJob?.cancel()
        osdJob = scope.launch {
            delay(config.osdDuration)
            update {
                osd = null
                osdIcon = null
                level = null
            }
        }
    }

    // The prompt button: skipping and up next

    /**
     * The intros, recaps and credits of the file playing: the server's markers ([SessionInfo.segments]), else the
     * engine's chapters classified; none until it's loaded, so no other file's count, none while the next item
     * resolves (the last file still stands where it was, its segments not the coming item's), and none live.
     */
    private fun segments(): List<SkipSegment> = when {
        !engineState.loaded || info.resolving || info.live -> emptyList()
        else -> info.segments ?: skipSegments(engineState.chapters to engineState.durationSeconds)
    }

    /**
     * Up next may come up: a next episode, a loaded file that didn't fail and isn't live, no sleep timer for the end of
     * the video (it stops there), and in a room only for the host, whose next episode it is.
     */
    private fun upNextEligible(): Boolean = info.nextEpisode != null && !sleep.atEndOfVideo && engineState.loaded &&
        info.failure == null && !info.live &&
        watchUi?.canChangeEpisode != false

    /** Skipping [segment] plays the next episode: credits to the end, with up next in their place. */
    private fun playsNextEpisode(segment: SkipSegment): Boolean = segment.toEnd && upNextEligible()

    /**
     * A segment may skip on its own here: on the room's host only (guests follow its seek), and credits that play the
     * next episode only with auto-play of it on.
     */
    private fun autoSkipAllowed(segment: SkipSegment): Boolean =
        watchUi?.canChangeEpisode != false && (!playsNextEpisode(segment) || info.nextEpisode?.autoplay == true)

    private fun evaluateSkip() {
        // Credits to the end of a room already at its end have nothing left to skip, unless they play the next episode.
        val segments = segments().filterNot { it.toEnd && watchUi?.atMediaEnd == true && !playsNextEpisode(it) }
        skip.follow(displayPosition(), segments, info.skipping, ::autoSkipAllowed)
        skip.tickWhile(playing = !scrubber.active && status() == PlaybackStatus.PLAYING)
    }

    /**
     * The item ended: its file did, or the room that drives this player reached its media's end first (this file can be
     * longer, shifted against the room, or paused a moment short of its end).
     */
    private fun atItemEnd(): Boolean = engineState.eof || watchUi?.atMediaEnd == true

    private fun evaluateUpNext() {
        val next = info.nextEpisode
        val duration = engineState.durationSeconds
        followEnd()
        // In picture in picture nobody answers a countdown: with auto-play on, the end plays the next episode at once,
        // unless the server stopped this playback. Without it, up next waits at the end for the viewer's return.
        if (pictureInPicture && atItemEnd() && next != null && next.autoplay && upNextEligible() && !info.stoppedByServer && !stoppedAtEnd &&
            advancedInPictureInPicture != engineState.loadId
        ) {
            advancedInPictureInPicture = engineState.loadId
            return playNextEpisode()
        }
        // From the credits when the chapters have them (unless the profile turned credits off), else the countdown's
        // length before the end; without auto-play at the end, where it waits to be asked without a countdown.
        val credits = if (info.skipping.credits != SkipMode.OFF) SkipSegments.creditsStart(segments()) else null
        val start = when {
            next == null || !upNextEligible() -> null
            credits != null -> credits
            next.autoplay -> duration - next.countdownSeconds
            else -> duration
        }
        // A server that stopped this playback lets the video play out, but the next one waits for the viewer.
        val countdown = next?.countdownSeconds?.takeIf { next.autoplay && !info.stoppedByServer }
        // While the skip button counts down to the next episode, it is up next; while the sleep timer asks whether
        // anyone is still watching, up next waits for the answer.
        val held = skip.counting && skip.segment?.toEnd == true || sleep.asking != null
        if (upNext.follow(displayPosition(), duration, atItemEnd(), start, countdown, held)) playNextEpisode()
        // A retry's countdown runs at the end, the finished video standing still; in the background, or while video may
        // not play (the profile picker over the player), neither runs.
        upNext.tickWhile(playing = !scrubber.active && !backgrounded && host.playbackAllowed && (status() == PlaybackStatus.PLAYING || upNext.retrying))
    }

    /**
     * The end with nothing after it ([SessionInfo.ended]) leaves the player: not for a guest whom the room keeps, nor
     * where the sleep timer stopped the video at its end.
     */
    private fun followEnd() {
        if (!info.ended || !atItemEnd() || leavingAtEnd || stoppedAtEnd || watchUi?.canChangeEpisode == false) return
        leavingAtEnd = true
        scope.launch { host.close() }
    }

    /**
     * The next episode, started by the end of the video, didn't open for a server that didn't answer
     * ([SessionInfo.nextFailures]): up next comes back, counting [RETRY_COUNTDOWN_SECONDS] down to try again (with
     * auto-play on, outside a room, twice), else waiting for the viewer.
     */
    private fun offerNextAgain() {
        val retry = playNextRetryPresentation(
            wasAtCompletion = true,
            failureReason = PlaybackFailureReason.SERVER_UNAVAILABLE,
            hasNext = info.nextEpisode != null,
            autoPlayEnabled = info.nextEpisode?.autoplay == true,
            inWatchTogether = watchUi != null,
            autoRetriesUsed = nextRetries,
        )
        when (retry) {
            PlayNextRetry.NONE -> Unit
            PlayNextRetry.MANUAL -> upNext.offerAgain(null)
            PlayNextRetry.COUNTDOWN -> {
                nextRetries++
                upNext.offerAgain(RETRY_COUNTDOWN_SECONDS)
            }
        }
    }

    private fun onUpNextStep(): Unit = update { if (upNext.step()) playNextEpisode() }

    private fun onSkipTick(): Unit = update { if (skip.tick()) skipSegment() }

    /** The next episode or queue item; the queue's entry after the one playing while the lookup hasn't named it yet. */
    private fun playNextEpisode() {
        abandonBurst()
        upNext.finish()
        // Moving on answers "Still watching?": the timer starts its minutes again.
        sleep.keepWatching()
        val after = PlayerStates.entryAfter(info)
        if (info.nextEpisode == null && after != null) session.playQueueItem(after.key) else session.playNextEpisode()
    }

    /**
     * Past the first seconds of what plays ([shouldRestartBeforePreviousItem] of the position shown, paused or not),
     * its start, as Previous's name then says ([EpisodeButtons.previousRestarts]); else the episode or entry before (a
     * live channel's, the channel before).
     */
    private fun playPreviousEpisode() {
        val restart = !info.live && shouldRestartBeforePreviousItem(displayPosition())
        abandonBurst()
        upNext.finish()
        if (restart) seekFromControls(0.0, showControls = false) else session.playPreviousEpisode()
    }

    /** The prompt button as it shows ([PlayerUiState.prompt]): the skip button, else up next; null while neither shows. */
    private fun prompt(): PlayerPrompt? = skipPrompt() ?: upNextPrompt()

    /**
     * The skip button as it shows, or null: none in picture in picture (automatic skips still happen), for a guest who
     * may not control the playback, over the error screen, the sleep timer's question or up next. Credits to the end
     * with a next episode are up next's: its button while they count down to it, else up next itself shows. Either
     * says whether it shows only with the controls ([PlayerPrompt.withControls]).
     */
    private fun skipPrompt(): PlayerPrompt? {
        val segment = skip.segment ?: return null
        if (pictureInPicture || watchUi?.canControl == false || info.failure != null || sleep.asking != null || upNext.shown) return null
        if (!skip.visible(controlsVisible())) return null
        val withControls = !skip.visible(controlsVisible = false)
        if (!playsNextEpisode(segment)) return PlayerStates.skip(segment, skip.progress, skip.secondsLeft, withControls)
        val next = info.nextEpisode
        return if (skip.counting && next != null) PlayerStates.upNext(next, skip.progress, skip.secondsLeft, withControls, info.shuffled) else null
    }

    /** Up next as it shows, or null: none over the error screen. */
    private fun upNextPrompt(): PlayerPrompt? {
        val next = info.nextEpisode ?: return null
        if (info.failure != null || !upNext.visible(controlsVisible())) return null
        return PlayerStates.upNext(next, upNext.progress, upNext.secondsLeft, withControls = !upNext.visible(controlsVisible = false), info.shuffled)
    }

    /**
     * Skips the segment playing: seeks exactly to its end (no keyframe landing back inside it, and no message), or plays
     * the next episode when its credits run to the end and up next stands for them. Credits to the end of a room's file
     * end the room's media for everyone instead ([PlayerWatch.endMedia]): this file's end needn't be the room's.
     */
    private fun skipSegment() {
        val segment = skip.segment ?: return
        if (!engineState.loaded) return
        skip.markSkipped(segment)
        if (playsNextEpisode(segment)) {
            playNextEpisode()
            return
        }
        val room = watch?.takeIf { it.routesControls }
        if (segment.toEnd && room != null) {
            room.endMedia()
            return
        }
        val target = seekTo(segment.endSeconds)
        watch?.onLocalSeek(target)
    }

    /**
     * Back on the prompt button: up next goes, its auto-play cancelled for this file (the end then stops on its plain
     * button), a skip button until the playback leaves the segment (for credits to the end, up next with it).
     */
    private fun dismissPrompt() {
        if (upNext.shown) {
            upNext.dismiss()
            return
        }
        val segment = skip.segment ?: return
        skip.dismiss()
        if (segment.toEnd) upNext.dismiss()
    }

    // Sleep timer

    private fun onSleepSecond(): Unit = update {
        if (sleep.tick(mayAsk = !upNext.shown)) pauseForSleep()
    }

    /**
     * The sleep timer stops the playback, a stop on this device as the system's are ([PlayerCommand.SystemPause]): in a
     * room whoever controls playback pauses the room, and anyone else pauses here alone ([stopHere]), the room playing
     * on.
     */
    private fun pauseForSleep() {
        val room = watch?.takeIf { it.routesControls }
        when {
            stopsHereAlone() -> stopHere()
            room != null -> room.pause()
            else -> {
                paused.request(true)
                engine.setPaused(true)
            }
        }
    }

    // Upstream

    private fun onChoices(choices: PlayerChoices) = update {
        ambientLighting?.saved = choices.ambientLighting
        normalization = choices.audioNormalization
        channels = choices.audioChannels
        downmix = choices.downmix
        brightnessSwipe = choices.brightnessSwipe
        volumeSwipe = choices.volumeSwipe
        pinchToZoom = choices.pinchToZoom
        infoShown = choices.showPlaybackInfo
        infoAutoHide = choices.autoHidePlaybackInfo
        rememberBrightness = choices.rememberBrightness
        rememberedBrightness = choices.rememberedBrightness.takeIf { it in 0.0..1.0 }
        hdr = choices.hdr
        sleepDefaultMinutes = choices.sleepTimerMinutes
        keptOutput = choices.audioOutputDevice.takeUnless { choices.configAudioDevice }
        if (dolbyVisionConversion == null) dolbyVisionConversion = choices.dolbyVisionConversion
        applyKeptOutput()
        // The player opened: at the remembered brightness, and the levels a swipe starts from read.
        if (!choicesSeen) {
            choicesSeen = true
            touch.refresh(rememberedLevel())
        }
        seekSeconds = choices.seekSeconds.toDouble()
        longSeekSeconds = choices.longSeekSeconds.toDouble()
        playerNavigation = choices.playerNavigation
        hotkeys = choices.hotkeys
        val shadersBefore = customShaders
        customShaders = choices.customShaders
        // The kept preset is an imported shader heard of only now: it runs.
        if (shader == ShaderPreset.Off && ShaderPreset.of(savedShader, shadersBefore) == ShaderPreset.Off) {
            shader = runnable(ShaderPreset.of(savedShader, customShaders))
        }
        maxVolume = choices.maxVolume
        storedSearchLanguage = choices.subtitleSearchLanguage
        rotationLocked = choices.rotationLocked
        // As the player opens: the window goes on top as it was left (later changes are this player's own).
        if (alwaysOnTop == null && host.keepsOnTop) {
            alwaysOnTop = choices.alwaysOnTop
            if (choices.alwaysOnTop) host.setAlwaysOnTop(true)
        }
    }

    /**
     * As a title opens (once one resolved; with none, the global options), the picture options its scopes keep for it
     * apply where they differ from the previous title's as kept now: a change kept nowhere (the shader toggle's off, a
     * fit while its scope keeps nothing) lasts into the next title, and a title that keeps another one switches.
     */
    private suspend fun followPicture() {
        var opened = false
        var previous: MediaItem? = null
        session.info
            .filter { it.item != null || !it.resolving }
            .map { it.item }
            .distinctUntilChanged { old, new -> new == null || (old?.serverId == new.serverId && old?.id == new.id) }
            .collect { item ->
                val before = if (opened) preferences.picture(previous) else null
                val picture = preferences.picture(item)
                opened = true
                previous = item
                update {
                    savedShader = picture.shaderPreset
                    if (picture.fit != before?.fit) fit = picture.fit
                    if (picture.zoom != before?.zoom) zoom = VideoLayout.normalizeZoom(picture.zoom)
                    if (picture.shaderPreset != before?.shaderPreset) shader = runnable(ShaderPreset.of(picture.shaderPreset, customShaders))
                }
            }
    }

    private fun onEngineState(new: EngineState) {
        val old = engineState
        applyEngineState(old, new)
        // After the state is published: the room may answer with commands.
        watchAdapter.onEngineState(old, new)
    }

    private fun applyEngineState(old: EngineState, new: EngineState) = update {
        engineState = new
        if (new.buffering != old.buffering) followBuffering(new.buffering)
        // A file's first frame: ambient lighting's stored setting comes back at the first one.
        if (old.playbackRestarts == 0 && new.playbackRestarts > 0 && ambientLighting?.onFirstFrame() == true) onAmbientLightingOn()
        paused.onReport(old.paused, new.paused)
        muted.onReport(old.muted, new.muted)
        volume.onReport(old.volume, new.volume)
        speed.onReport(old.speed, new.speed)
        subtitleDelay.onReport(old.subtitleDelaySeconds, new.subtitleDelaySeconds)
        audioDelay.onReport(old.audioDelaySeconds, new.audioDelaySeconds)
        audioTrack.onReport(old.selection(TrackKind.AUDIO), new.selection(TrackKind.AUDIO))
        subtitleTrack.onReport(old.selection(TrackKind.SUBTITLE), new.selection(TrackKind.SUBTITLE))
        secondSubtitleTrack.onReport(old.secondSelection(), new.secondSelection())
        audioDevice.onReport(old.audioDevice, new.audioDevice)
        pickedOutput?.let { picked ->
            when {
                new.audioDevice == picked -> {
                    pickedOutput = null
                    keptOutput = picked
                    preferences.setAudioOutputDevice(picked)
                }
                new.audioDevice != old.audioDevice -> pickedOutput = null
            }
        }
        if (new.audioDevices != old.audioDevices) applyKeptOutput()
        pendingSeek?.let { target ->
            if (abs(playedPosition() - target) < settledSeconds()) clearPendingSeek()
        }
        // A new file: nothing about the old one carries over, not even a track choice still on its way (the new file's
        // ids are other tracks). A live rewind's reopen is the same file, its window kept.
        if (old.loaded && !new.loaded && rewindWindow() == null) {
            scrubber.end()
            hoverPreview = null
            burst.cancel()
            clearPendingSeek()
            audioTrack.clear()
            subtitleTrack.clear()
            secondSubtitleTrack.clear()
            roomSpeed = null
            skip.reset()
            upNext.reset()
            nextRetries = 0
            stoppedAtEnd = false
            dismissSkipBadge()
        }
        if (!old.eof && new.eof && sleep.onVideoEnded()) {
            // The sleep timer was set for the end of this video: it stops here, without moving on.
            stoppedAtEnd = true
            upNext.finish()
            pauseForSleep()
        }
    }

    private fun onSessionInfo(new: SessionInfo) = update {
        val failed = info.failure == null && new.failure != null
        val nextFailed = new.nextFailures > info.nextFailures
        val notice = new.notice
        if (notice != null && notice.serial != info.notice?.serial) showOsd(notice.text)
        // A failure ends the hidden start: its card and the title and Back show. So does another item (Next,
        // Previous, autoplay, a queue's entry): the controls name it for their usual time from its first frame.
        val previous = info.item
        val another = previous != null && new.item != null && new.item.id != previous.id
        if (failed || another) chrome.show()
        info = new
        if (nextFailed) offerNextAgain()
        // The timeline goes while live without a window, its focus with it: Left and Right move focus along the buttons
        // again.
        if (info.live && rewindWindow() == null) {
            timelineFocused = false
            scrubber.end()
            burst.cancel()
        }
        // The edge moves on with the clock, paused or not: the time behind shows it every second.
        if (rewindWindow() == null) {
            liveTick?.cancel()
            liveTick = null
        } else if (liveTick == null) {
            liveTick = scope.launch {
                while (true) {
                    delay(LIVE_TICK)
                    update {}
                }
            }
        }
        if (failed) {
            scrubber.end()
            burst.cancel()
            menu = null
        }
    }

    /**
     * How close the position must come to a seek's target for the seek to count as landed: live with a window, a
     * segment more (a reopen starts at a segment's start, and the edge moves on).
     */
    private fun settledSeconds(): Double = SEEK_SETTLED_SECONDS + (rewindWindow()?.segmentSeconds ?: 0.0)

    private fun clearPendingSeek() {
        pendingSeek = null
        pendingSeekJob?.cancel()
        pendingSeekJob = null
    }

    private fun EngineState.selection(kind: TrackKind) = TrackChoice(tracks.firstOrNull { it.kind == kind && it.selected }?.id)

    private fun EngineState.secondSelection() = TrackChoice(tracks.firstOrNull { it.kind == TrackKind.SUBTITLE && it.secondary }?.id)

    // State

    /**
     * Applies [block] and publishes the new state and timeline. A pin that goes away (resumed, menu closed, loaded)
     * shows the controls with a fresh auto-hide timer, so they don't vanish the moment the user acts.
     */
    private inline fun update(block: () -> Unit) {
        block()
        syncChrome()
        evaluateSkip()
        evaluateUpNext()
        liftSubtitles()
        applyOptions()
        mutableState.value = buildState()
        mutableTimeline.value = buildTimeline()
    }

    /** Subtitles above the bottom controls while they show, back in place once they hide or the error takes them. */
    private fun liftSubtitles() {
        val lift = if (controlsVisible() && info.failure == null) controlsHeight else 0.0
        if (lift == subtitleLift) return
        subtitleLift = lift
        engine.setSubtitleLift(lift)
    }

    /**
     * The picture's layout (the whole picture in a picture-in-picture window), the audio options and whether the engine
     * reads the info's stats, as they change.
     */
    private fun applyOptions() {
        val layout = if (pictureInPicture) VideoLayout.DEFAULT else VideoLayout(fit, zoom)
        if (layout != appliedLayout) {
            appliedLayout = layout
            engine.setVideoLayout(layout)
        }
        if (normalization != appliedNormalization) {
            appliedNormalization = normalization
            engine.setAudioNormalization(normalization)
        }
        if (channels != appliedChannels || downmix != appliedDownmix) {
            appliedChannels = channels
            appliedDownmix = downmix
            engine.setAudioChannels(channels, downmix)
        }
        playbackInfo.update(infoShown, infoAutoHide, controlsVisible(), visible && !pictureInPicture)
        val wanted = playbackInfo.polling
        if (wanted != statsWanted) {
            statsWanted = wanted
            engine.setStatsWanted(wanted)
        }
        applyShaders()
    }

    /**
     * The shader preset's files for the video playing ([files]: NVScaler's goes on HDR video), to the engine once their
     * paths are known, whenever they change. A file that isn't there turns the shaders off for this player.
     */
    private fun applyShaders() {
        val files = shaderFiles ?: return
        val wanted = shader.files(engineState.video?.dynamicRange)
        if (wanted == appliedShaderFiles) return
        appliedShaderFiles = wanted
        shaderJob?.cancel()
        shaderJob = scope.launch {
            val paths = try {
                if (wanted.isEmpty()) emptyList() else files.paths(wanted)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Couldn't find the shader preset ${shader.id}'s files" }
                update { shader = ShaderPreset.Off }
                return@launch
            }
            engine.setShaders(paths)
        }
    }

    private fun buildState(): PlayerUiState {
        val locale = T.locale
        val status = status()
        val duration = engineState.durationSeconds
        val isPaused = paused.resolve(engineState.paused)
        // During a drift nudge the player plays a little off the room's speed; it shows the room's.
        val currentSpeed = roomSpeed ?: speed.resolve(engineState.speed)
        val next = info.nextEpisode
        val more = moreSubtitles(MoreKey(info.moreSubtitles, engineState.tracks, locale))
        val window = rewindWindow()
        val versions = PlayerStates.versions(info)
        val chapterList = chapters()
        val at = displayPosition()
        val chapterItems = chapterItems(
            ChapterKey(chapterList, info.chapters?.map { it.imageUrl }.orEmpty(), chapterAt(chapterList, at), canSeek = watchUi?.canControl != false, locale),
        )
        return PlayerUiState(
            versions = versions,
            title = info.title,
            subtitle = info.subtitle,
            status = status,
            loadingText = when (status) {
                PlaybackStatus.RESOLVING -> T.player.resolving
                PlaybackStatus.OPENING -> T.player.opening
                PlaybackStatus.BUFFERING -> T.player.buffering
                else -> null
            },
            paused = isPaused,
            playPauseLabel = if (isPaused) T.player.play else T.player.pause,
            controlsVisible = controlsVisible(),
            playPauseFocus = playPauseFocus(),
            seekSeconds = seekSeconds.roundToInt(),
            skipBadge = if (badgeShown) SkipBadge(badgeForward, skipBadgeLabel(badgeTotal.roundToInt()), badgeSerial) else null,
            mode = when {
                window != null -> PlaybackMode.LIVE_WINDOW
                info.live -> PlaybackMode.LIVE
                else -> PlaybackMode.VIDEO
            },
            seekable = when {
                window != null -> true
                info.live -> false
                else -> engineState.loaded && duration > 0
            },
            scrubbing = scrubber.preview != null,
            menu = menu,
            audioTracks = audioItems(TrackKey(engineState.tracks, selectedTrack(TrackKind.AUDIO), null, locale)),
            subtitleTracks = subtitleItems(TrackKey(engineState.tracks, selectedTrack(TrackKind.SUBTITLE), selectedSecondSubtitle(), locale)),
            moreSubtitles = more,
            subtitleLanguage = if (menu == PlayerMenu.SUBTITLE_LANGUAGE) more.firstOrNull { it.key == subtitleLanguage } else null,
            customSpeed = customSpeed(currentSpeed to locale),
            speedLabel = PlayerText.speed(currentSpeed),
            subtitleDelay = PlayerStates.delay(TrackKind.SUBTITLE, subtitleDelay.resolve(engineState.subtitleDelaySeconds), config),
            audioDelay = PlayerStates.delay(TrackKind.AUDIO, audioDelay.resolve(engineState.audioDelaySeconds), config),
            volume = PlayerStates.volume(volume.resolve(engineState.volume), muted.resolve(engineState.muted), maxVolume),
            episodes = PlayerStates.episodeButtons(info, canChange = watchUi?.canChangeEpisode != false, positionSeconds = displayPosition()),
            options = options(
                PlayerOptions.Values(
                    fit = fit,
                    zoom = zoom,
                    sleepMinutes = sleep.minutes,
                    sleepAtEndOfVideo = sleep.atEndOfVideo,
                    sleepSecondsLeft = sleep.secondsLeft,
                    sleepDefaultMinutes = sleepDefaultMinutes,
                    autoPlayNext = next?.autoplay,
                    locale = locale,
                    watch = watchUi,
                    shader = shader.takeIf { shaderFiles != null },
                    shaders = shaderFiles?.let { ShaderPreset.available(it.renderer, customShaders) }.orEmpty(),
                    importsShaders = importsCustomShaders(),
                    speed = currentSpeed.takeIf { !info.live && watchUi?.canControl != false },
                    speeds = config.speeds,
                    versions = versions,
                    fileInfo = info.fileInfo && !info.live,
                    playbackInfo = infoShown,
                    ambientLighting = ambientLighting?.enabled,
                    hdr = (hdrRequest ?: hdr).takeIf { engine.features.hdrControl && hdrOutput != null },
                    sdrVideo = engineState.video?.dynamicRange == DynamicRange.SDR,
                    dolbyVisionConversion = dolbyVisionConversion.takeIf {
                        config.development && engine.features.dolbyVisionConversion && dvConversionOutput != null
                    },
                    httpStatus = config.development,
                ),
            ),
            audioOptions = audioOptions(
                PlayerOptions.AudioValues(
                    audioDevices = engineState.audioDevices.takeIf { engine.features.audioDevices },
                    audioDevice = audioDevice.resolve(engineState.audioDevice),
                    audioNormalization = normalization,
                    audioChannels = channels,
                    locale = locale,
                    passthroughSupported = config.audioPassthrough,
                    passthroughOn = config.audioPassthroughOn,
                    audioRendering = engineState.audioRendering,
                ),
            ),
            videoFit = PlayerOptions.videoFit(fit),
            prompt = prompt(),
            stillWatching = sleep.asking?.let(PlayerStates::stillWatching),
            error = info.failure?.let(PlayerStates::error),
            osd = osd,
            osdIcon = osdIcon,
            // With the controls up their Play/Pause already shows the state: a pause brings them up.
            transportFlash = transportFlash.takeUnless { controlsVisible() },
            chromeHiddenAtStart = config.profile == InputProfile.TV,
            rotationLocked = rotationLocked.takeIf { config.profile == InputProfile.TOUCH },
            alwaysOnTop = alwaysOnTop.takeIf { host.keepsOnTop },
            choice = info.choice?.let { choice ->
                ChoiceState(choice.title, choice.options.mapIndexed { index, label -> OptionChoice(label, null, false, PlayerCommand.AnswerChoice(index)) })
            },
            level = level,
            heldSpeed = heldSpeedFrom?.let { PlayerText.speed(HOLD_SPEED) },
            lockLabel = if (config.profile == InputProfile.TOUCH) T.player.lock.button else null,
            screenLock = lock?.let { stage ->
                ScreenLockState(if (stage == UnlockStage.SHOWN) UnlockButton(label = T.player.lock.holdToUnlock, holding = unlockHold != null) else null)
            },
            fullscreen = fullscreen,
            watch = watchUi,
            keepAwake = keepAwake(status, isPaused),
            hdrPicture = engineState.video?.dynamicRange.isHdr() && engineState.outputDynamicRange.isHdr(),
            chapters = chapterItems,
            previousChapterTitle = previousChapterIndex(chapterList, at).takeIf { it >= 0 }?.let { chapterItems.getOrNull(it)?.title },
            nextChapterTitle = nextChapterIndex(chapterList, at)?.let { chapterItems.getOrNull(it)?.title },
            // Hidden by the subtitle shortcut, and not shown again since (the shortcut, a pick in the menu).
            subtitlesHidden = hiddenSubtitle != null && selectedTrack(TrackKind.SUBTITLE) == null,
            queue = info.queue.map { QueueItem(it.key, it.title, it.subtitle, it.imageUrl, it.current, it.spoiler) },
            sourceAudioTracks = info.sourceAudio.takeIf { it.size > 1 }
                ?.map { TrackItem(it.id.toLong(), it.label, it.detail, it.selected) }
                .orEmpty(),
            subtitleSearch = subtitleSearchState(locale),
            fileInfo = fileInfo.takeIf { info.fileInfo && !info.live },
            settingsHighlighted = abs(zoom - 1.0) > ZOOM_HIGHLIGHT_EPSILON || (shaderFiles != null && shader != ShaderPreset.Off),
            sleepTimer = if (sleep.counting || sleep.atEndOfVideo) PlayerStates.sleepBanner(sleep.atEndOfVideo, sleep.secondsLeft) else null,
            playbackInfo = if (infoShown && !pictureInPicture) PlaybackInfoState(PlaybackInfoReader.visible(infoAutoHide, controlsVisible())) else null,
        )
    }

    private fun buildTimeline(): TimelineState {
        val position = displayPosition()
        motion = playheadMotion(position)
        val preview = scrubber.preview
        val window = rewindWindow()
        if (window != null) {
            val now = clock.now().toEpochMilliseconds()
            val scrub = preview?.let { PlayerStates.rewindScrub(it, scrubber.origin, window.windowSeconds, now, use24HourClock) }
            return PlayerStates.rewindTimeline(position, window, scrub, now, use24HourClock)
        }
        if (info.live) return PlayerStates.liveTimeline(position)
        val duration = engineState.durationSeconds
        val chapters = chapters()
        fun previewAt(seconds: Double, origin: Double) =
            PlayerStates.scrub(seconds, origin, duration, chapters.lastOrNull { chapter -> chapter.startSeconds <= seconds })
                .copy(frame = info.scrubPreview?.takeIf { source -> source.isAvailable }?.frameAt(seconds.seconds))
        return PlayerStates.timeline(
            position = position,
            duration = duration,
            cacheEnd = engineState.cacheEndSeconds,
            chapters = if (info.chapterMarks) chapterMarks(chapters to duration) else emptyList(),
            scrub = preview?.let { previewAt(it, scrubber.origin) },
            motion = motion,
        ).copy(hover = hoverFraction?.takeIf { preview == null && duration > 0 }?.let { fraction ->
            // The whole second under the mouse, without an offset (no scrub started): a move within it shows the same tooltip.
            val second = floor(fraction * duration)
            hoverPreview?.takeIf { it.seconds == second } ?: previewAt(second, second).copy(offset = "").also { hoverPreview = it }
        }).withEndsAt(finishClock(position, duration))
    }

    /**
     * The clock time the video ends at ("21:43", "9:43 PM" on a 12-hour clock): now plus the time left at the speed,
     * to the minute; null while nothing remains.
     */
    private fun finishClock(position: Double, duration: Double): String? {
        val currentSpeed = roomSpeed ?: speed.resolve(engineState.speed)
        if (!engineState.loaded || duration <= 0 || currentSpeed <= 0) return null
        val leftMillis = ((duration - position) / currentSpeed * 1000).roundToLong()
        if (leftMillis <= 0) return null
        val finish = clock.now().toEpochMilliseconds() + leftMillis
        return clockTime(finish.floorDiv(1000L), use24HourClock)
    }

    private fun TimelineState.withEndsAt(clockTime: String?): TimelineState =
        if (clockTime == null) this else copy(endsAt = T.videoControls.endsAt(clockTime), finishClock = clockTime)

    /**
     * [TimelineState.motion] at [position]: while the engine plays a video (not live) with no seek or scrub under way,
     * the position moves on from where the engine reported it, timed from when that report came; null while it stands,
     * so the bar shows the position as it is. The engine's own pause and speed count, not ones it hasn't reported yet:
     * the played part stops where the engine did.
     */
    private fun playheadMotion(position: Double): PlayheadMotion? {
        val moving = !info.live && info.failure == null && scrubber.preview == null && burst.target == null && pendingSeek == null &&
            engineState.loaded && !engineState.paused && !engineState.buffering && !engineState.eof && engineState.speed > 0
        if (!moving) return null
        val current = motion
        if (current != null && current.speed == engineState.speed && motionFrom == position) return current
        motionFrom = position
        return PlayheadMotion(engineState.speed, timeSource.markNow())
    }

    /** HDR (HDR10, HLG, Dolby Vision): known and not SDR. */
    private fun DynamicRange?.isHdr(): Boolean = this != null && this != DynamicRange.SDR

    /** The seek badge's seconds: "10s" under a minute, a timecode ("2:55") from there. */
    private fun skipBadgeLabel(seconds: Int): String =
        if (seconds < 60) "$seconds${T.settings.secondsShort}" else formatTimecode(seconds.toDouble())

    private data class TrackKey(val tracks: List<Track>, val selected: Long?, val second: Long?, val locale: String)

    private data class MoreKey(val subtitles: List<ExternalSubtitle>, val tracks: List<Track>, val locale: String)

    private data class ChapterKey(val chapters: List<Chapter>, val images: List<String?>, val current: Int, val canSeek: Boolean, val locale: String)

    /**
     * [watchPlayer]: the engine's state as the room reads it, and the room's play, pause and seek the way the viewer's
     * go (the session saves the seek, the trackers hear it) without the controls or the OSD; play and pause return once
     * the engine reports them done; the speed shows as the room's ([roomSpeed]) while the room nudges it. A seek the
     * viewer just made here (the room repeating it) isn't made twice. The room's adapter waits for seeks to land.
     */
    private inner class StoreAdapter : RoomPlayer {
        override var onChanged: (() -> Unit)? = null

        override val loadId: Long get() = engineState.loadId
        override val positionMs: Long get() = (engineState.positionSeconds * 1000).roundToLong()
        override val durationMs: Long?
            get() = engineState.durationSeconds.takeIf { engineState.loaded && it > 0 }?.let { (it * 1000).roundToLong() }
        override val playing: Boolean get() = !(this@PlayerStore.paused.resolve(engineState.paused) || engineState.eof)
        override val buffering: Boolean get() = engineState.buffering
        override val renderedFrame: Boolean get() = engineState.loaded && engineState.playbackRestarts > 0
        override val seekable: Boolean get() = engineState.seekable
        override val audioPassthrough: Boolean get() = engineState.audioPassthrough
        override val disposed: Boolean get() = released
        override val restarts: Int get() = engineState.playbackRestarts

        override suspend fun play() {
            if (released) return
            // A car that forbids video while driving: the room's start is refused here, and the room shows this
            // player's play as blocked.
            check(host.playbackAllowed) { "playback is restricted while driving" }
            setPaused(false)
            awaitEngine { !it.paused }
        }

        override suspend fun pause() {
            if (released) return
            setPaused(true)
            awaitEngine { it.paused }
        }

        override suspend fun seek(positionMs: Long) {
            if (released || info.live || !engineState.loaded) return
            val target = positionMs / 1000.0
            val pending = pendingSeek
            // The viewer's own seek there, which the room repeats: it lands once.
            if (pending != null && abs(pending - target) <= SAME_SEEK_SECONDS) return
            update { seekTo(target) }
        }

        override suspend fun setRate(rate: Double) {
            if (released) return
            update {
                roomSpeed = watch?.roomRate
                engine.setSpeed(rate)
            }
        }

        fun onEngineState(old: EngineState, new: EngineState) {
            val changed = old.paused != new.paused || old.buffering != new.buffering || old.loaded != new.loaded ||
                old.eof != new.eof || old.durationSeconds != new.durationSeconds || old.playbackRestarts != new.playbackRestarts ||
                old.seekable != new.seekable || old.loadId != new.loadId
            if (changed) onChanged?.invoke()
        }

        private suspend fun awaitEngine(done: (EngineState) -> Boolean) {
            withTimeoutOrNull(COMMAND_TIMEOUT) { session.engineState.first(done) }
        }
    }

    private companion object {
        const val TAG = "PlayerStore"

        /** An imported shader's file ends so: mpv's user shaders are GLSL. */
        const val GLSL = ".glsl"

        /** A seek's target shows until the engine reports a position this close, or [SEEK_SETTLE_TIMEOUT] passes. */
        const val SEEK_SETTLED_SECONDS = 1.0
        val SEEK_SETTLE_TIMEOUT = 1500.milliseconds

        /** The controls hide this long after the last input on a touch screen or with a remote, and with a mouse. */
        val TOUCH_HIDE_DELAY = 5000.milliseconds
        val MOUSE_HIDE_DELAY = 3000.milliseconds

        /** The seek badge shows this long after the last seek it counts. */
        val SKIP_BADGE = 1200.milliseconds

        /** The volume shortcuts' step, in points. */
        const val SHORTCUT_VOLUME_STEP = 10.0

        /** The volume is kept once it stops changing this long ([setVolume]). */
        val VOLUME_SAVE_DELAY = 500.milliseconds

        /** The wheel's pixels per volume point. */
        const val WHEEL_PIXELS_PER_POINT = 20.0

        /** A remote's previous chapter within this of the start has nowhere to go. */
        const val START_TOLERANCE_SECONDS = 0.5

        /** The speed shortcuts' step. */
        const val SPEED_STEP = 0.25

        /** A live window's time behind is a whole-second timecode. */
        val LIVE_TICK = 1000.milliseconds

        /** An engine's wait shows once it lasts this long ([followBuffering]). */
        val BUFFERING_GRACE = 500.milliseconds

        /** How long a room's command waits for the engine to report it done before it returns anyway. */
        val COMMAND_TIMEOUT = 10_000.milliseconds

        /** A room's seek this close to the viewer's own pending one is that seek, not another. */
        const val SAME_SEEK_SECONDS = 0.25

        /** mpv lands a chapter seek a little before the chapter start. */
        const val CHAPTER_TOLERANCE_SECONDS = 0.5
        const val PREVIOUS_CHAPTER_GRACE_SECONDS = 3.0

        /** Subtitles never move up by more than half the player: taller controls would push them off the picture. */
        const val MAX_SUBTITLE_LIFT = 0.5

        /** A finger held on the video plays at this speed ([PlayerCommand.HoldSpeed]). */
        const val HOLD_SPEED = 2.0

        /** The unlock button hides this long after it showed or a finger left it without unlocking. */
        val UNLOCK_PROMPT = 3.seconds

        /** A pinch zooms once its scale has moved this far from 1 on [PINCH_MOVES] changes in a row. */
        const val PINCH_THRESHOLD = 0.06
        const val PINCH_MOVES = 3

        /** A pinch ending this close to 100 % (in whole percent) lands on 100 % exactly. */
        const val PINCH_SNAP_PERCENT = 3

        /** Up next's countdown before it tries a next episode that failed to start again: not the profile's, never 0. */
        const val RETRY_COUNTDOWN_SECONDS = 5

        /** The play/pause flash's whole run: in, held, out. */
        val TRANSPORT_FLASH = 800.milliseconds

        /** A title typed in the subtitle search searches once it rests this long. */
        val SEARCH_DEBOUNCE = 500.milliseconds

        /** The settings button is highlighted while the zoom is off 100 % by more than this. */
        const val ZOOM_HIGHLIGHT_EPSILON = 0.0001

        const val MINUTE_MILLIS = 60_000L
    }
}

/** The screen lock's unlock button ([PlayerStore.lockScreen]): hidden or shown. */
private enum class UnlockStage { HIDDEN, SHOWN }
