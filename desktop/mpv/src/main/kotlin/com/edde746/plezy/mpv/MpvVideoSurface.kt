package com.edde746.plezy.mpv

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import java.awt.Window
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.seconds

/** How long the window may take to realize the canvas the video goes into before the playback fails. */
private val ATTACH_TIMEOUT = 5.seconds

/**
 * The video of [engine], filling its bounds. Place it under the player controls (e.g. as `PlayerScreen`'s `video`
 * slot) in [window], the one window the engine plays into:
 *
 * - Windows: transparent; mpv renders into a native child window under the whole Compose layer, so the
 *   video always fills the window's canvas.
 * - Linux under Wayland: transparent; mpv renders into a video plane under the [WaylandWindow], fitted to these
 *   bounds. In an X11 session the playback fails, saying video needs a Wayland session.
 *
 * The engine starts mpv once this has been composed and the window is showing. A window whose canvas doesn't appear
 * within 5 s (its native surface never created) fails the playback with that error.
 */
@Composable
fun MpvVideoSurface(engine: MpvPlayerEngine, window: Window, modifier: Modifier = Modifier) {
    LaunchedEffect(engine, window) {
        // The canvas (and its native handle) appears only once AWT has realized the window.
        withTimeoutOrNull(ATTACH_TIMEOUT) { while (!engine.attach(window)) delay(16) } ?: engine.attachTimedOut(ATTACH_TIMEOUT)
    }
    engine.host.Content(modifier.fillMaxSize())
}
