package com.edde746.plezy.ui.cast

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.cast.CastDevice
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.presentation.cast.CastDeviceRow
import com.edde746.plezy.presentation.cast.CastLinkStatus
import com.edde746.plezy.presentation.cast.CastMediaKind
import com.edde746.plezy.presentation.cast.CastNowPlaying
import com.edde746.plezy.presentation.cast.CastOption
import com.edde746.plezy.presentation.cast.CastSenderUiState
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme

/**
 * The app's frame as casting's overlays need it: the overlays' host in a window of [formFactor]'s size (a phone
 * upright, a TV or a desktop window), the system's Back from [back].
 */
@Composable
internal fun CastFrame(formFactor: FormFactor, back: DirectNavigationEventInput? = null, content: @Composable () -> Unit) {
    val dispatcher = remember { NavigationEventDispatcher().also { dispatcher -> back?.let(dispatcher::addInput) } }
    val owner = remember {
        object : NavigationEventDispatcherOwner {
            override val navigationEventDispatcher = dispatcher
        }
    }
    val size = when (formFactor) {
        FormFactor.HANDHELD -> DpSize(400.dp, 800.dp)
        FormFactor.TV -> DpSize(960.dp, 540.dp)
        FormFactor.DESKTOP -> DpSize(1280.dp, 720.dp)
    }
    CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
        PlezyTheme {
            Box(Modifier.size(size)) {
                AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) {
                    CompositionLocalProvider(LocalAppearance provides Appearance.of(AppearanceSettings(), formFactor, supporterUnlocked = false)) {
                        OverlayHostBox { content() }
                    }
                }
            }
        }
    }
}

/** The intents the cast surfaces sent, in order, each as its name and argument ("choose tv1", "seekBy -10.0"). */
internal class SentIntents {
    val sent = mutableListOf<String>()
    val intents = CastIntents(
        choose = { sent += "choose $it" },
        chooseThisDevice = { sent += "chooseThisDevice" },
        closePicker = { sent += "closePicker" },
        openControls = { sent += "openControls" },
        closeControls = { sent += "closeControls" },
        togglePause = { sent += "togglePause" },
        seekTo = { sent += "seekTo $it" },
        seekBy = { sent += "seekBy $it" },
        selectAudio = { sent += "selectAudio $it" },
        selectSubtitle = { sent += "selectSubtitle $it" },
        selectQuality = { sent += "selectQuality $it" },
        previous = { sent += "previous" },
        next = { sent += "next" },
        stop = { sent += "stop" },
        setVolume = { sent += "setVolume $it" },
        disconnect = { sent += "disconnect" },
    )
}

internal val livingRoom = CastDevice("tv1", "Living Room TV", "Android", CastDeviceKind.TV)
internal val study = CastDevice("pc1", "Study PC", "Windows", CastDeviceKind.DESKTOP)

internal fun row(device: CastDevice, selected: Boolean = false, connecting: Boolean = false, nowPlaying: String? = null) =
    CastDeviceRow(device, selected, connecting, nowPlaying)

/** Maestro Episode 2 at 1:10 of 1:30 on [receiver], paused or not, with [volume]. */
internal fun nowPlaying(receiver: String = livingRoom.name, paused: Boolean = false, volume: Int? = 40, canSeek: Boolean = true) = CastNowPlaying(
    receiverName = receiver,
    kind = CastMediaKind.VIDEO,
    title = "Maestro Episode 2",
    subtitle = "S1 · E2",
    artworkUrl = null,
    paused = paused,
    buffering = false,
    positionSeconds = 70.0,
    durationSeconds = 90.0,
    position = "1:10",
    duration = "1:30",
    progress = 70f / 90f,
    canSeek = canSeek,
    audioTracks = listOf(CastOption("a1", "English", "AAC 2.0", selected = true), CastOption("a2", "German", "AAC 2.0", selected = false)),
    subtitleTracks = listOf(CastOption("off", "Off", null, selected = true), CastOption("s1", "English", "SRT", selected = false)),
    qualities = listOf(CastOption("original", "Original", null, selected = true), CastOption("720", "720p 4 Mbps", null, selected = false)),
    hasPrevious = false,
    hasNext = true,
    volume = volume,
)

/** Connected to [livingRoom], playing [playing]. */
internal fun casting(playing: CastNowPlaying? = nowPlaying()) =
    CastSenderUiState(target = livingRoom, status = CastLinkStatus.CONNECTED, nowPlaying = playing)
