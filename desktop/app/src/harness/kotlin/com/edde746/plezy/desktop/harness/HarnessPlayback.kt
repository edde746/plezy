package com.edde746.plezy.desktop.harness

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.output.OutputPolicy
import com.edde746.plezy.ui.app.PlezyPlatform
import kotlinx.coroutines.async
import kotlinx.coroutines.launch

/**
 * `--play`: [url] through [platform]'s own playback and video surface, filling the window, muted (looping takes the
 * app's `--mpv-opt loop-file=inf`), under a translucent bar whose marker moves every frame, so Compose draws
 * continuously over the video as the player's controls do while they animate. The HDR output is the engine's default
 * (off) unless `--engine-set hdr=yes`. [onFrame] hears each Compose frame.
 *
 * With [matchDisplay] (`--play-match`) the playback's output host gets the shared policy's plan for its first video as
 * a fullscreen desktop playback with frame-rate matching and HDR on, and restores the display when the playback ends.
 */
@Composable
internal fun HarnessPlayback(
    platform: PlezyPlatform,
    url: String,
    matchDisplay: Boolean,
    onFrame: (frameNanos: Long) -> Unit,
) {
    val playback = remember { platform.createPlayback(DeviceSettings.DEFAULT) }
    val scope = rememberCoroutineScope()
    DisposableEffect(playback) {
        val engine = playback.engine
        val host = playback.output?.takeIf { matchDisplay }
        var planned = false
        var applied = false
        if (host != null) {
            val settings = DeviceSettings.DEFAULT.copy(hdr = true, matchRefreshRate = true, matchDynamicRange = true)
            val display = scope.async { host.display() }
            engine.setListener(object : PlayerEngineListener {
                override fun onState(state: EngineState) {
                    val video = state.video?.takeIf { it.fps != null } ?: return
                    if (planned) return
                    planned = true
                    scope.launch {
                        applied = true
                        host.apply(OutputPolicy.plan(video, display.await(), settings, FormFactor.DESKTOP, fullscreen = true))
                    }
                }
            })
        }
        engine.setMuted(true)
        engine.setStatsWanted(true)
        engine.load(LoadRequest(url, PlaybackOptions.of(DeviceSettings.DEFAULT, playback.hardwareDecoder), title = "harness"))
        onDispose {
            if (applied) host?.restore()
            engine.release()
        }
    }
    var phase by remember { mutableFloatStateOf(0f) }
    LaunchedEffect(Unit) {
        while (true) {
            withFrameNanos { now ->
                onFrame(now)
                phase = (now / 1_000_000 % 4000) / 4000f
            }
        }
    }
    Box(Modifier.fillMaxSize()) {
        platform.VideoSurface(playback.engine, Modifier.fillMaxSize())
        Box(Modifier.align(Alignment.BottomCenter).fillMaxSize(fraction = 1f).padding(top = 560.dp).background(Color(0x99000000))) {
            Text("harness overlay", color = Color.White, modifier = Modifier.padding(16.dp))
            Box(Modifier.offset(x = (phase * 1200).dp, y = 72.dp).size(24.dp).background(Color(0xFFE5A00D)))
        }
    }
}
