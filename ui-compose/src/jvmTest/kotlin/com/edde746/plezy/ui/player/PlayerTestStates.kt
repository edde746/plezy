package com.edde746.plezy.ui.player

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.presentation.player.DelayState
import com.edde746.plezy.presentation.player.EpisodeButtons
import com.edde746.plezy.presentation.player.ErrorAction
import com.edde746.plezy.presentation.player.ErrorButton
import com.edde746.plezy.presentation.player.ErrorState
import com.edde746.plezy.presentation.player.OptionChoice
import com.edde746.plezy.presentation.player.InfoSection
import com.edde746.plezy.presentation.player.PlaybackMode
import com.edde746.plezy.presentation.player.PlaybackStatus
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.player.PlayerOption
import com.edde746.plezy.presentation.player.PlayerOptionId
import com.edde746.plezy.presentation.player.PlayerPrompt
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.player.SpeedControl
import com.edde746.plezy.presentation.player.StillWatchingState
import com.edde746.plezy.presentation.player.TimelineState
import com.edde746.plezy.presentation.player.VolumeState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.app.PlezyPlatform
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlin.math.max
import kotlin.math.roundToLong
import kotlin.test.assertTrue

internal val testPlayerConfig = PlayerConfig(InputProfile.DESKTOP, doubleClickIntervalMillis = 300)

/**
 * The options as the store lists them for an episode with a next one: the picture filled (adjusted), no zoom, the sleep
 * timer off, auto-play next on.
 */
internal val testPlayerOptions: List<PlayerOption> = run {
    val text = T.player.options
    fun fit(fit: VideoFit, label: String) = OptionChoice(label, null, selected = fit == VideoFit.COVER, PlayerCommand.SetVideoFit(fit))
    listOf(
        PlayerOption(
            PlayerOptionId.VIDEO_FIT, text.videoFit, text.fit.cover, adjusted = true, PlayerMenu.VIDEO_FIT,
            listOf(fit(VideoFit.CONTAIN, text.fit.contain), fit(VideoFit.COVER, text.fit.cover), fit(VideoFit.FILL, text.fit.fill)),
            on = null, toggle = null,
        ),
        PlayerOption(
            PlayerOptionId.ZOOM, text.zoom, "100%", adjusted = false, PlayerMenu.ZOOM,
            listOf(
                OptionChoice(text.resetZoom, null, selected = false, PlayerCommand.ResetZoom),
                OptionChoice("100%", null, selected = true, PlayerCommand.SetZoom(1.0)),
                OptionChoice("150%", null, selected = false, PlayerCommand.SetZoom(1.5)),
            ),
            on = null, toggle = null,
        ),
        PlayerOption(
            PlayerOptionId.SLEEP_TIMER, text.sleepTimer, text.off, adjusted = false, PlayerMenu.SLEEP_TIMER,
            listOf(
                OptionChoice(text.off, null, selected = true, PlayerCommand.CancelSleepTimer),
                OptionChoice(text.sleepEndOfVideo, null, selected = false, PlayerCommand.SleepAtEndOfVideo),
            ),
            on = null, toggle = null,
        ),
        PlayerOption(
            PlayerOptionId.AUTO_PLAY_NEXT, text.autoPlayNext, text.on, adjusted = false, page = null, choices = emptyList(),
            on = true, toggle = PlayerCommand.SetAutoPlayNext(false),
        ),
    )
}

/** The audio menu's settings as the store lists them: normalization off, the audio mixed down to stereo (adjusted). */
internal val testAudioOptions: List<PlayerOption> = run {
    val text = T.player.options
    val limits = T.settings
    fun channels(channels: AudioChannels, label: String, detail: String) =
        OptionChoice(label, detail, selected = channels == AudioChannels.STEREO, PlayerCommand.SetAudioChannels(channels))
    listOf(
        PlayerOption(
            PlayerOptionId.AUDIO_NORMALIZATION, text.audioNormalization, text.off, adjusted = false, page = null, choices = emptyList(),
            on = false, toggle = PlayerCommand.SetAudioNormalization(true),
        ),
        PlayerOption(
            PlayerOptionId.AUDIO_CHANNELS, text.audioChannels, limits.audioChannelLimitStereo, adjusted = true, PlayerMenu.AUDIO_CHANNELS,
            listOf(
                channels(AudioChannels.ORIGINAL, limits.audioChannelLimitOriginal, limits.audioChannelLimitOriginalDescription),
                channels(AudioChannels.SURROUND_51, limits.audioChannelLimitSurround51, limits.audioChannelLimitSurround51Description),
                channels(AudioChannels.STEREO, limits.audioChannelLimitStereo, limits.audioChannelLimitStereoDescription),
            ),
            on = null, toggle = null,
        ),
    )
}

/** [testPlayerState]'s timeline: 15 s into a 20 s episode, all of it buffered. */
internal val testTimeline = TimelineState("0:15", "0:20", "−0:05", "0:15 / 0:20", 0.75f, 1f, emptyList(), positionSeconds = 15.0, durationSeconds = 20.0, liveLabel = "")

/** An error card as the store builds it: Retry (primary, filled and focused) and Close. */
internal fun testError(
    title: String = "Can't play this stream",
    message: String = "The stream is no longer available.",
) = ErrorState(
    title,
    message,
    buttons = listOf(
        ErrorButton(ErrorAction.RETRY, T.player.error.retry, PlayerCommand.Retry, primary = true),
        ErrorButton(ErrorAction.CLOSE, T.player.error.close, PlayerCommand.Close, primary = false),
    ),
)

/** The subtitle (else the audio) delay's control as the store builds it: at zero, else moved a step later ([moved]). */
internal fun testDelay(subtitles: Boolean, moved: Boolean = false): DelayState {
    val text = T.player.menu
    val step = testPlayerConfig.steps.delaySeconds
    return DelayState(
        menu = if (subtitles) PlayerMenu.SUBTITLE_DELAY else PlayerMenu.AUDIO_DELAY,
        title = if (subtitles) text.subtitleDelay else text.audioDelay,
        label = if (moved) "+0.1 s" else "0.0 s",
        decreaseLabel = if (subtitles) text.subtitleDelayEarlier else text.audioDelayEarlier,
        increaseLabel = if (subtitles) text.subtitleDelayLater else text.audioDelayLater,
        decrease = if (subtitles) PlayerCommand.AdjustSubtitleDelay(-step) else PlayerCommand.AdjustAudioDelay(-step),
        increase = if (subtitles) PlayerCommand.AdjustSubtitleDelay(step) else PlayerCommand.AdjustAudioDelay(step),
        reset = if (subtitles) PlayerCommand.SetSubtitleDelay(0.0) else PlayerCommand.SetAudioDelay(0.0),
        canDecrease = true,
        canIncrease = true,
        canReset = moved,
    )
}

/** The speed as the menus write it: "Normal" at 1×, else "1.25×". */
internal fun testSpeedLabel(speed: Double) = if (speed == 1.0) T.player.speed.normal else T.player.speed.value(speed.toString().removeSuffix(".0"))

/** The custom speed's control as the store builds it at [speed]: [label] ("2.4×"), a twentieth either way, Normal. */
internal fun testCustomSpeed(speed: Double, label: String) = SpeedControl(
    speed = speed,
    label = label,
    decreaseLabel = T.player.speed.slower,
    increaseLabel = T.player.speed.faster,
    decrease = PlayerCommand.SetSpeed(((speed - PlayerConfig.CUSTOM_SPEED_STEP) * 100).roundToLong() / 100.0),
    increase = PlayerCommand.SetSpeed(((speed + PlayerConfig.CUSTOM_SPEED_STEP) * 100).roundToLong() / 100.0),
    reset = PlayerCommand.SetSpeed(1.0),
    canDecrease = speed > PlayerConfig.MIN_SPEED,
    canIncrease = speed < PlayerConfig.MAX_SPEED,
    canReset = speed != 1.0,
    min = PlayerConfig.MIN_SPEED,
    max = PlayerConfig.MAX_SPEED,
    step = PlayerConfig.CUSTOM_SPEED_STEP,
)

/** The speed option as the store lists it at [speed]: the presets, then Custom, which shows [speed] when it is none of them. */
internal fun testSpeedOption(speed: Double): PlayerOption {
    val presets = PlayerConfig.DEFAULT_SPEEDS
    val custom = speed !in presets
    val choices = presets.map { OptionChoice(testSpeedLabel(it), null, selected = it == speed, PlayerCommand.SetSpeed(it)) } +
        OptionChoice(
            if (custom) T.player.speed.customValue(testSpeedLabel(speed)) else T.player.speed.custom,
            null,
            selected = custom,
            PlayerCommand.OpenMenu(PlayerMenu.CUSTOM_SPEED),
        )
    return PlayerOption(PlayerOptionId.SPEED, T.videoSettings.playbackSpeed, testSpeedLabel(speed), speed != 1.0, PlayerMenu.SPEED, choices, on = null, toggle = null)
}

/**
 * An episode playing with the controls up (one before it and one after, both buttons on unless [episodes] says
 * otherwise; null: a movie), the prompt button, the sleep timer's question, a menu or an error as given.
 */
internal fun testPlayerState(
    prompt: PlayerPrompt? = null,
    error: ErrorState? = null,
    menu: PlayerMenu? = null,
    stillWatching: StillWatchingState? = null,
    episodes: EpisodeButtons? = EpisodeButtons(previous = true, next = true),
) = PlayerUiState(
    title = "Chernobyl",
    subtitle = "S1E1 · 1:23:45",
    status = if (error != null) PlaybackStatus.FAILED else PlaybackStatus.PLAYING,
    loadingText = null,
    paused = false,
    playPauseLabel = "Pause",
    controlsVisible = true,
    mode = PlaybackMode.VIDEO,
    seekable = true,
    scrubbing = false,
    menu = menu,
    audioTracks = emptyList(),
    subtitleTracks = emptyList(),
    customSpeed = testCustomSpeed(1.0, "1×"),
    speedLabel = "Normal",
    subtitleDelay = testDelay(subtitles = true),
    audioDelay = testDelay(subtitles = false),
    volume = VolumeState(100, 1f, muted = false, label = "100%"),
    episodes = episodes,
    options = testPlayerOptions,
    audioOptions = testAudioOptions,
    prompt = prompt,
    stillWatching = stillWatching,
    error = error,
    osd = null,
    fullscreen = false,
    keepAwake = error == null,
)

/** The whole player on a 960 × 540 dp TV, showing [state] and [timeline]; [probe] sees its named elements' bounds. */
@OptIn(ExperimentalTestApi::class)
internal fun ComposeUiTest.tvPlayer(
    probe: LayoutProbe? = null,
    timeline: StateFlow<TimelineState> = MutableStateFlow(testTimeline),
    state: () -> PlayerUiState,
) = player(FormFactor.TV, probe = probe, timeline = timeline, state = state)

/**
 * The whole player on a [size] window (960 × 540 dp) of [formFactor] with the app's overlay host (sheets drawn over
 * it, as in the app) and its arrow-key focus moves, showing [state] and [timeline]: [onCommand] gets what its controls
 * send, [onInput] its keys and pointer events (none taken by default), [dispatcher] carries the system's back, [probe]
 * sees its named elements' bounds, [platform] (where given) is the app's platform the player reaches (its file dialogs),
 * [playbackInfo] the playback info's sections, whose shown card's frames go to [onPlaybackInfoFrame], and how much of the
 * video the bottom controls cover to [onControlsHeightChanged].
 */
@OptIn(ExperimentalTestApi::class)
internal fun ComposeUiTest.player(
    formFactor: FormFactor,
    dispatcher: NavigationEventDispatcher? = null,
    probe: LayoutProbe? = null,
    onCommand: (PlayerCommand) -> Unit = {},
    onInput: (InputEvent) -> Boolean = { false },
    size: DpSize = DpSize(960.dp, 540.dp),
    timeline: StateFlow<TimelineState> = MutableStateFlow(testTimeline),
    platform: PlezyPlatform? = null,
    playbackInfo: StateFlow<List<InfoSection>>? = null,
    onPlaybackInfoFrame: (Long) -> Unit = {},
    onControlsHeightChanged: (Double) -> Unit = {},
    state: () -> PlayerUiState,
) = setContent {
    val owner = remember {
        object : NavigationEventDispatcherOwner {
            override val navigationEventDispatcher = dispatcher ?: NavigationEventDispatcher()
        }
    }
    val locals = listOfNotNull(
        LocalNavigationEventDispatcherOwner provides owner,
        LocalLayoutProbe provides probe,
        platform?.let { LocalPlezyPlatform provides it },
    )
    CompositionLocalProvider(*locals.toTypedArray()) {
        PlezyTheme {
            Box(Modifier.size(size)) {
                AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) {
                    OverlayHostBox {
                        PlayerScreen(
                            state(), timeline, testPlayerConfig, onCommand = onCommand, onInput = onInput, onTimelineFocusChanged = {},
                            onControlsHeightChanged = onControlsHeightChanged, playbackInfo = playbackInfo, onPlaybackInfoFrame = onPlaybackInfoFrame,
                        ) {}
                    }
                }
            }
        }
    }
}

/** Presses [key] (down and up) where focus is, and waits for the UI to settle. */
@OptIn(ExperimentalTestApi::class)
internal fun ComposeUiTest.press(key: Key) {
    onRoot().performKeyInput { pressKey(key) }
    waitForIdle()
}

/** The harness names' bounds (window pixels) and the one holding focus, as the layout probes report them. */
internal class PlayerProbe : LayoutProbe {
    val bounds = HashMap<String, Rect>()
    var focused: String? = null

    override fun place(name: String, bounds: Rect?) {
        if (bounds != null) this.bounds[name] = bounds else this.bounds.remove(name)
    }

    override fun focus(name: String, focused: Boolean) {
        if (focused) this.focused = name else if (this.focused == name) this.focused = null
    }
}

/**
 * Fails where [what], at [bounds], comes nearer than [gap] pixels (less one for rounding) to any of [controls], each
 * compared on its own (not a bar's frame), or where one of them isn't on screen.
 */
internal fun PlayerProbe.requireClear(what: String, bounds: Rect, controls: List<String>, gap: Float) {
    val missing = controls.filter { it !in this.bounds }
    assertTrue(missing.isEmpty(), "$what: $missing not on screen")
    val near = controls.map { it to this.bounds.getValue(it) }.filter { (_, control) ->
        // Their distance along the axis they're apart on; negative where they overlap.
        val apart = max(max(bounds.left - control.right, control.left - bounds.right), max(bounds.top - control.bottom, control.top - bounds.bottom))
        apart < gap - 1f
    }
    assertTrue(near.isEmpty(), "$what ($bounds) less than $gap px from ${near.joinToString { (name, control) -> "$name $control" }}")
}
