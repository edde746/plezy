package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * Stops of the playback on this device rather than the viewer's: the system's (Android's audio focus and noisy audio
 * through the OS media controls' [MediaCommand.SystemPause] and [MediaCommand.SystemResume], Apple's audio session's
 * [PlayerCommand.SystemPause]) and the sleep timer's. In a watch-together room one who controls playback pauses the
 * room, as Pause does; anyone else pauses this device alone, its player out of the room's playback, which plays on,
 * until the system's resume or the viewer's Play joins it again and the room catches it up. A guest's own Pause from
 * the lock screen, a remote or a media key stays refused. Outside a room they are Pause and Play.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class RoomStopTest {
    private object NoControls : MediaControlsHost {
        override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) = Unit

        override fun hide() = Unit
    }

    /**
     * A playback playing at 1:40 with the OS media controls, in a room ([watch]) when given: attached to it, the room
     * playing, so the room plays the player whenever it joins the room's playback again.
     */
    private class Fixture(private val scope: TestScope, val watch: FakeWatch?) {
        val player = PlayerHarness(scope, PlayerConfig.defaults(InputProfile.TOUCH, doubleClickIntervalMillis = 300))
        private val controls = MediaControls(player.store, player.session, NoControls, scope.backgroundScope, scope.testScheduler.timeSource)

        init {
            player.playing(position = 100.0, duration = 600.0)
            if (watch != null) {
                player.store.attachWatch(watch)
                watch.routesControls = true
                watch.onResume = { scope.backgroundScope.launch { player.store.watchPlayer.play() } }
            }
            player.advance(Duration.ZERO)
        }

        /** A command of the OS's, and whatever it sets off. */
        fun os(command: MediaCommand) {
            controls.perform(command)
            scope.runCurrent()
        }

        /** The sleep timer set for a minute, past its question's countdown. */
        fun sleepTimerRunsOut() {
            player.dispatch(PlayerCommand.SetSleepTimer(1))
            player.advance(1.minutes + SleepTimer.STILL_WATCHING_SECONDS.seconds + 1.seconds)
        }
    }

    private fun guest(body: Fixture.(FakeWatch) -> Unit) = runTest {
        val watch = FakeWatch(canControl = false, canChangeEpisode = false)
        Fixture(this, watch).body(watch)
    }

    @Test
    fun aGuestsFocusLossPausesItsEngineAloneAndLeavesTheRoomsPlayback() = guest { watch ->
        os(MediaCommand.SystemPause)
        assertEquals(listOf(true), player.engine.paused, "the engine paused")
        assertEquals(listOf("stop"), watch.here, "the player out of the room's playback")
        assertEquals(emptyList(), watch.presses, "the room plays on")
        assertNull(player.state.osd, "nothing refused")
        assertTrue(player.state.canPlayPause, "Play is the way back")
    }

    @Test
    fun aTransientLossRegainedJoinsTheRoomAgainAndPlays() = guest { watch ->
        os(MediaCommand.SystemPause)
        os(MediaCommand.SystemResume)
        assertEquals(listOf("stop", "resume"), watch.here)
        assertEquals(listOf(true, false), player.engine.paused, "the room played it again")
        assertEquals(PlaybackStatus.PLAYING, player.state.status)
        assertEquals(emptyList(), watch.presses, "the room was asked nothing")
        assertNull(player.state.osd)
    }

    @Test
    fun aPermanentLossStaysPausedUntilTheViewersPlay() = guest { watch ->
        os(MediaCommand.SystemPause)
        player.advance(10.minutes)
        assertEquals(listOf(true), player.engine.paused)
        assertEquals(listOf("stop"), watch.here)
        player.dispatch(PlayerCommand.TogglePause)
        assertEquals(listOf("stop", "resume"), watch.here)
        assertEquals(listOf(true, false), player.engine.paused, "the room played it again")
        assertNull(player.state.osd, "nothing refused")
        assertEquals(emptyList(), watch.presses)
    }

    @Test
    fun theSleepTimerPausesAGuestAlone() {
        guest { watch ->
            sleepTimerRunsOut()
            assertEquals(listOf(true), player.engine.paused, "unanswered")
            assertEquals(listOf("stop"), watch.here)
            assertEquals(emptyList(), watch.presses)
        }
        guest { watch ->
            player.dispatch(PlayerCommand.SetSleepTimer(1))
            player.advance(1.minutes)
            assertNotNull(player.state.stillWatching)
            player.dispatch(PlayerCommand.Pause)
            assertEquals(listOf(true), player.engine.paused, "the question's Pause")
            assertEquals(listOf("stop"), watch.here)
            assertNull(player.state.stillWatching, "the timer is off")
            assertNull(player.state.osd, "nothing refused")
            assertEquals(emptyList(), watch.presses)
        }
    }

    @Test
    fun aGuestsOwnPauseFromTheSystemsControlsStaysRefused() = guest { watch ->
        os(MediaCommand.Pause)
        assertEquals("Only the host controls playback", player.state.osd)
        os(MediaCommand.TogglePause)
        os(MediaCommand.Play)
        // Nothing of this device's to resume.
        os(MediaCommand.SystemResume)
        assertEquals(emptyList(), player.engine.paused)
        assertEquals(emptyList(), watch.here)
        assertEquals(emptyList(), watch.presses)
    }

    @Test
    fun forOneWhoControlsTheRoomTheseStopsPauseTheRoom() = runTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        Fixture(this, watch).run {
            os(MediaCommand.SystemPause)
            os(MediaCommand.SystemResume)
            sleepTimerRunsOut()
        }
        assertEquals(listOf("pause", "play", "pause"), watch.presses)
        assertEquals(emptyList(), watch.here)
    }

    @Test
    fun outsideARoomTheSystemsPauseAndResumeArePauseAndPlay() = runTest {
        Fixture(this, watch = null).run {
            os(MediaCommand.SystemPause)
            assertEquals(listOf(true), player.engine.paused)
            os(MediaCommand.SystemResume)
            assertEquals(listOf(true, false), player.engine.paused)
            sleepTimerRunsOut()
            assertEquals(listOf(true, false, true), player.engine.paused)
        }
    }
}
