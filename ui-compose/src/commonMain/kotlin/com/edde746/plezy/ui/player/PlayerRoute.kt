package com.edde746.plezy.ui.player

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.ui.Modifier
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.components.use24HourClock

/**
 * The player route of [app]: its current playback's store ([AppSession.player]), rendered over the platform's video
 * surface. Each playback gets a player of its own: nothing of the last one's (its state, its callbacks, focus, the open
 * menu) carries over, not even for a frame.
 */
@Composable
fun PlayerRoute(app: AppSession) {
    val platform = LocalPlezyPlatform.current
    // Null for the frames the route animates out after its playback ended.
    val playback by app.player.collectAsState()
    val active = playback ?: return
    val stack by app.navigator.backStack.collectAsState()
    val castingFrom = app.castReceiver.state.collectAsState().value.castingFrom
    key(active) {
        val store = active.store
        val state by store.state.collectAsState()
        PlayerScreen(
            state = state,
            timeline = store.timeline,
            config = active.config,
            onCommand = store::dispatch,
            onInput = store::onInput,
            onTimelineFocusChanged = store::onTimelineFocusChanged,
            onControlsHeightChanged = store::onControlsHeightChanged,
            backEnabled = stack.lastOrNull() == Route.Player,
            pictureInPicture = platform.inPictureInPicture,
            onPictureInPictureFailed = store::onPictureInPictureFailed,
            pictureInPictureHost = platform.pictureInPicture,
            playbackInfo = store.playbackInfo.sections,
            onPlaybackInfoFrame = store.playbackInfo::onFrame,
            castingFrom = castingFrom,
        ) {
            platform.VideoSurface(active.engine, Modifier.fillMaxSize())
        }
        // A picture-in-picture window shows the whole picture; the fit and zoom come back with the player.
        LaunchedEffect(platform.inPictureInPicture) { store.onPictureInPictureChanged(platform.inPictureInPicture) }
        // Out of sight (a minimized window) the display may sleep.
        LaunchedEffect(platform.windowVisible) { store.onVisibleChanged(platform.windowVisible) }
        // An assistive technology walking the controls one at a time: they stay up.
        LaunchedEffect(platform.assistiveTechnology) { store.onAssistiveTechnologyChanged(platform.assistiveTechnology) }
        // The end time and a live window's clock times on the platform's 12/24-hour clock.
        val clock24 = use24HourClock()
        LaunchedEffect(clock24) { store.setUse24HourClock(clock24) }
    }
}
