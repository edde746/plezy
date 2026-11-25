package com.edde746.plezy.presentation.player

import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.output.DisplayInfo
import com.edde746.plezy.playback.output.OutputPlan
import com.edde746.plezy.playback.output.PlaybackOutput
import com.edde746.plezy.playback.output.PlaybackOutputHost
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.times

/** One playback following the app into the background and back ([PlayerLifecycle]). */
class PlayerLifecycleTest {
    private class ControlsHost : MediaControlsHost {
        var shown = 0
        var hidden = 0
        var commands: MediaCommandHandler? = null

        override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) {
            shown++
            this.commands = commands
        }

        override fun hide() {
            hidden++
        }
    }

    private class DisplayHost : PlaybackOutputHost {
        var restores = 0
        override suspend fun display() = DisplayInfo(modes = emptyList(), current = null, hdrSupported = false, hdrEnabled = false)
        override suspend fun apply(plan: OutputPlan) = true
        override fun restore() {
            restores++
        }
    }

    private class Rig(private val scope: TestScope, policy: BackgroundPolicy) {
        val player = PlayerHarness(scope, PlayerConfig.defaults(InputProfile.TV, doubleClickIntervalMillis = 300))
        val controlsHost = ControlsHost()
        val controls = MediaControls(player.store, player.session, controlsHost, scope.backgroundScope, scope.testScheduler.timeSource)
        val display = DisplayHost()
        val output = PlaybackOutput(player.session.engineState, flowOf(false), FormFactor.TV, flowOf(DeviceSettings.DEFAULT), display, scope.backgroundScope)
        val foreground = MutableStateFlow(true)
        var pictureInPicture = false
        val lifecycle = PlayerLifecycle(player.store, player.session, controls, output, policy, { pictureInPicture }, foreground, scope.backgroundScope)

        init {
            scope.runCurrent()
        }

        fun background() {
            foreground.value = false
            scope.runCurrent()
        }

        fun back() {
            foreground.value = true
            scope.runCurrent()
        }

        fun advance(duration: Duration) {
            scope.advanceTimeBy(duration)
            scope.runCurrent()
        }

        fun perform(command: MediaCommand) {
            controls.perform(command)
            scope.runCurrent()
        }
    }

    private val phone = BackgroundPolicy.of(FormFactor.HANDHELD, appleTv = false, automotive = false)
    private val androidTv = BackgroundPolicy.of(FormFactor.TV, appleTv = false, automotive = false)

    private fun lifecycleTest(policy: BackgroundPolicy, body: Rig.() -> Unit) = runTest { Rig(this, policy).body() }

    @Test
    fun `phones TVs and cars pause in the background and only an android TV suspends`() {
        assertEquals(BackgroundPolicy(pauses = true, tv = false, suspends = false), phone)
        assertEquals(BackgroundPolicy(pauses = true, tv = true, suspends = true), androidTv)
        assertEquals(BackgroundPolicy(pauses = true, tv = true, suspends = false), BackgroundPolicy.of(FormFactor.TV, appleTv = true, automotive = false))
        assertEquals(BackgroundPolicy(pauses = false, tv = false, suspends = false), BackgroundPolicy.of(FormFactor.DESKTOP, appleTv = false, automotive = false))
        assertTrue(BackgroundPolicy.of(FormFactor.DESKTOP, appleTv = false, automotive = true).pauses, "a car pauses whatever it calls itself")
    }

    @Test
    fun `a phone pauses the playing video in the background and plays it again rewound once back`() = lifecycleTest(phone) {
        player.sessionInfo { it.copy(rewindOnResumeSeconds = 5) }
        player.playing(position = 100.0)

        background()
        assertEquals(listOf(true), player.engine.paused)
        assertEquals(1, controlsHost.hidden, "the media controls go")
        val shown = controlsHost.shown
        perform(MediaCommand.Play)
        perform(MediaCommand.TogglePause)
        player.position(120.0)
        assertEquals(listOf(true), player.engine.paused, "nothing the system's controls send starts it")
        assertEquals(shown, controlsHost.shown, "nothing is published while away")
        assertFalse(lifecycle.holdsPlayback, "only a TV holds starts")

        back()
        assertEquals(false, player.engine.paused.last())
        assertEquals(115.0, player.engine.seeks.last().first)
        assertTrue(controlsHost.shown > shown, "the controls are back")
        assertEquals(0, player.session.suspendCalls)
    }

    @Test
    fun `a video paused before the background stays paused once back`() = lifecycleTest(phone) {
        player.playing()
        player.dispatch(com.edde746.plezy.input.PlayerCommand.Pause)
        background()
        back()
        assertEquals(listOf(true), player.engine.paused)
    }

    @Test
    fun `the system stopping playback still reaches it in the background`() = lifecycleTest(phone) {
        player.playing()
        background()
        perform(MediaCommand.Stop)
        assertEquals(1, player.host.closed)
    }

    @Test
    fun `a desktop plays on behind other windows`() = lifecycleTest(BackgroundPolicy.of(FormFactor.DESKTOP, appleTv = false, automotive = false)) {
        player.playing()
        background()
        advance(60.seconds)
        assertEquals(emptyList(), player.engine.paused)
        assertEquals(0, controlsHost.hidden)
    }

    @Test
    fun `picture in picture keeps the video playing`() = lifecycleTest(phone) {
        player.playing()
        pictureInPicture = true
        background()
        assertEquals(emptyList(), player.engine.paused)
        assertEquals(0, controlsHost.hidden)
        back()
        assertEquals(emptyList(), player.engine.paused)
    }

    @Test
    fun `an android TV holds starts and gives the video back after thirty seconds away`() = lifecycleTest(androidTv) {
        player.playing()
        background()
        assertTrue(lifecycle.holdsPlayback)
        advance(PlayerLifecycle.SUSPEND_GRACE - 1.seconds)
        assertEquals(0, player.session.suspendCalls)
        advance(1.seconds)
        assertEquals(1, player.session.suspendCalls)
        assertEquals(1, display.restores, "the display goes back to its own mode")
        advance(5 * PlayerLifecycle.SUSPEND_GRACE)
        assertEquals(1, player.session.suspendCalls, "once")

        back()
        assertFalse(lifecycle.holdsPlayback)
        assertEquals(1, player.session.restores)
        assertEquals(false, player.engine.paused.last(), "it played before: it plays again")
    }

    @Test
    fun `a TV video that cant be given back yet is asked again a grace later`() = lifecycleTest(androidTv) {
        player.playing()
        player.session.suspends = false
        background()
        advance(PlayerLifecycle.SUSPEND_GRACE)
        assertEquals(1, player.session.suspendCalls)
        assertEquals(0, display.restores)
        player.session.suspends = true
        advance(PlayerLifecycle.SUSPEND_GRACE)
        assertEquals(2, player.session.suspendCalls)
        assertEquals(1, display.restores)
    }

    @Test
    fun `back within the grace nothing was given back`() = lifecycleTest(androidTv) {
        player.playing()
        background()
        advance(10.seconds)
        back()
        advance(PlayerLifecycle.SUSPEND_GRACE)
        assertEquals(0, player.session.suspendCalls)
        assertEquals(0, player.session.restores)
    }

    @Test
    fun `live TV pauses in the background keeps its stream and plays again once back`() = lifecycleTest(androidTv) {
        player.sessionInfo { it.copy(live = true) }
        player.playing()
        background()
        assertEquals(listOf(true), player.engine.paused)
        advance(5 * PlayerLifecycle.SUSPEND_GRACE)
        assertEquals(0, player.session.suspendCalls)
        assertTrue(lifecycle.holdsPlayback)
        back()
        assertEquals(false, player.engine.paused.last())
        assertTrue(player.engine.seeks.isEmpty(), "live doesn't rewind")
    }

    @Test
    fun `an apple TV holds starts but never gives the video back`() = lifecycleTest(BackgroundPolicy.of(FormFactor.TV, appleTv = true, automotive = false)) {
        player.playing()
        background()
        assertTrue(lifecycle.holdsPlayback)
        advance(5 * PlayerLifecycle.SUSPEND_GRACE)
        assertEquals(0, player.session.suspendCalls)
    }
}
