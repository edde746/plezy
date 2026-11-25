package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.session.LiveWindow
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.QueueEntry
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class MediaControlsTest {
    private class RecordingHost : MediaControlsHost {
        val shown = mutableListOf<NowPlaying>()
        var hidden = 0
        var userPauses = 0

        override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) {
            shown += nowPlaying
        }

        override fun hide() {
            hidden++
        }

        override fun userPaused() {
            userPauses++
        }
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    private class Fixture(private val scope: TestScope) {
        val player = PlayerHarness(scope, PlayerConfig.defaults(InputProfile.TOUCH, doubleClickIntervalMillis = 300))
        val host = RecordingHost()
        val controls = MediaControls(player.store, player.session, host, scope.backgroundScope, scope.testScheduler.timeSource)

        init {
            scope.runCurrent()
        }

        val last: NowPlaying get() = host.shown.last()

        /** An OS command, and whatever it sets off. */
        fun perform(command: MediaCommand) {
            controls.perform(command)
            scope.runCurrent()
        }

        /** A command from the player's own controls, and whatever it sets off. */
        fun dispatch(command: PlayerCommand) {
            player.store.dispatch(command)
            scope.runCurrent()
        }
    }

    private fun controlsTest(body: Fixture.() -> Unit) = runTest { Fixture(this).body() }

    @Test
    fun theControlsFollowThePlayersStatus() = controlsTest {
        assertEquals(NowPlayingStatus.BUFFERING, last.status, "a playback shows up while it opens")
        assertTrue(last.playing)
        assertFalse(last.canSeek)

        player.playing(position = 100.0, duration = 600.0)
        assertEquals(NowPlayingStatus.PLAYING, last.status)
        assertEquals(100.0, last.positionSeconds)
        assertEquals(600.0, last.durationSeconds)
        assertTrue(last.canSeek)

        player.engineState { it.copy(buffering = true) }
        player.advance(1.seconds)
        assertEquals(NowPlayingStatus.BUFFERING, last.status)
        assertTrue(last.playing)

        player.engineState { it.copy(buffering = false, paused = true) }
        assertEquals(NowPlayingStatus.PAUSED, last.status)
        assertFalse(last.playing)

        player.engineState { it.copy(paused = false, eof = true) }
        assertEquals(NowPlayingStatus.STOPPED, last.status)
    }

    @Test
    fun metadataComesFromTheSession() = controlsTest {
        player.sessionInfo {
            it.copy(
                title = "Chernobyl",
                subtitle = "S1E2 · Please Remain Calm",
                artworkUrl = "https://images.example/e2.jpg",
                episode = true,
                nextEpisode = NextEpisode("Open Wide, O Earth", "S1E3"),
                hasPreviousEpisode = true,
            )
        }
        assertEquals("Chernobyl", last.title)
        assertEquals("S1E2 · Please Remain Calm", last.subtitle)
        assertEquals("https://images.example/e2.jpg", last.artworkUrl)

        // The OS loads the artwork itself: only web images qualify.
        player.sessionInfo { it.copy(artworkUrl = "file:///sdcard/poster.jpg") }
        assertNull(last.artworkUrl)
    }

    @Test
    fun offLiveNextAndPreviousAreOfferedAsThePlayersButtonsAre() = controlsTest {
        player.playing(position = 2.0)
        assertFalse(last.canSkipPrevious, "a movie alone has nothing before")
        assertFalse(last.canSkipNext, "nor after")

        player.sessionInfo { it.copy(episode = true) }
        assertFalse(last.canSkipPrevious, "an episode before its neighbours are known")
        assertFalse(last.canSkipNext)

        player.sessionInfo { it.copy(nextEpisode = NextEpisode("Two", null)) }
        assertTrue(last.canSkipNext)
        assertFalse(last.canSkipPrevious, "the first episode")

        player.sessionInfo { it.copy(episode = false, nextEpisode = null, queue = listOf(QueueEntry("1", "One"), QueueEntry("2", "Two", current = true))) }
        assertTrue(last.canSkipPrevious, "a queue's item with one before it")
        assertFalse(last.canSkipNext, "and none after")

        player.sessionInfo { it.copy(queue = emptyList()) }
        perform(MediaCommand.Previous)
        assertEquals(1, player.session.previousEpisodes, "previous with nothing before still goes to the session, which restarts")
    }

    @Test
    fun liveNextAndPreviousFollowTheChannelList() = controlsTest {
        player.sessionInfo { it.copy(live = true, episode = true, nextEpisode = NextEpisode("BBC Two", null, autoplay = false), hasPreviousEpisode = false) }
        assertTrue(last.canSkipNext)
        assertFalse(last.canSkipPrevious, "the first channel has none before it")
        perform(MediaCommand.Previous)
        assertEquals(0, player.session.previousEpisodes)

        player.sessionInfo { it.copy(nextEpisode = null, hasPreviousEpisode = true) }
        assertFalse(last.canSkipNext, "the last channel has none after it")
        assertTrue(last.canSkipPrevious)
    }

    @Test
    fun aVideoOffersPlayPauseSeekSkipsAndTheSpeed() = controlsTest {
        player.playing(position = 100.0, duration = 600.0)
        assertTrue(last.canPlayPause)
        assertTrue(last.canSeek)
        assertTrue(last.canSkip)
        assertTrue(last.canSetSpeed)

        perform(MediaCommand.SetSpeed(1.5))
        assertEquals(listOf(1.5), player.engine.speeds)
    }

    @Test
    fun aVideosSkipsAndSeekButtonsGoByTheSmallSkipDurationAsItChanges() = controlsTest {
        player.preferences.choices.update { it.copy(seekSeconds = 15) }
        player.playing(position = 100.0, duration = 600.0)
        assertEquals(15, player.state.seekSeconds)
        assertEquals(15.0, last.skipSeconds)

        player.preferences.choices.update { it.copy(seekSeconds = 20) }
        player.advance(0.seconds)
        assertEquals(20, player.state.seekSeconds, "a change while the player is open")
        assertEquals(20.0, last.skipSeconds)
    }

    @Test
    fun aGuestsControlsOfferOnlyStop() = controlsTest {
        player.playing()
        player.sessionInfo { it.copy(episode = true, nextEpisode = NextEpisode("Next", null), hasPreviousEpisode = true) }
        player.store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        player.advance(0.seconds)
        assertFalse(last.canPlayPause)
        assertFalse(last.canSeek)
        assertFalse(last.canSkip)
        assertFalse(last.canSetSpeed)
        assertFalse(last.canSkipNext)
        assertFalse(last.canSkipPrevious)

        perform(MediaCommand.Previous)
        perform(MediaCommand.SetSpeed(2.0))
        assertEquals(0, player.session.previousEpisodes)
        assertEquals(emptyList(), player.engine.speeds)
    }

    @Test
    fun aLivePlaybackShowsAsLiveWithNoSeekBarOrSpeedAndSkipsOnlyInItsWindow() = controlsTest {
        player.playing(position = 100.0, duration = 600.0)
        assertFalse(last.live)
        assertTrue(last.canSeek)

        player.sessionInfo { it.copy(live = true) }
        assertTrue(last.live)
        assertFalse(last.canSeek)
        assertFalse(last.canSkip, "no capture buffer to skip through")
        assertFalse(last.canSetSpeed)
        assertTrue(last.canPlayPause)
        perform(MediaCommand.SetSpeed(2.0))
        assertEquals(emptyList(), player.engine.speeds, "a stray speed request does nothing live")

        player.sessionInfo { it.copy(liveWindow = LiveWindow(600.0, 2.0, joinedBehindSeconds = 0.0, joinedPositionSeconds = 0.0, joinedAt = player.timeSource.markNow())) }
        assertFalse(last.canSeek, "the window has no absolute position for the OS")
        assertTrue(last.canSkip, "the window has a capture buffer to skip through")
    }

    @Test
    fun playbackAtNormalPacePublishesNothing() = controlsTest {
        player.playing(position = 100.0, duration = 600.0)
        val published = host.shown.size
        // Thirty seconds of reports a quarter-second apart, as mpv sends them, on the same clock the OS extrapolates by.
        repeat(120) { tick ->
            player.advance(0.25.seconds)
            player.position(100.0 + (tick + 1) * 0.25)
        }
        assertEquals(published, host.shown.size)
        assertEquals(100.0, last.positionSeconds, "the OS carries the position on from the last value")
    }

    @Test
    fun seeksStallsAndSpeedChangesPublish() = controlsTest {
        player.playing(position = 100.0, duration = 600.0)
        player.advance(5.seconds)
        player.position(105.0)
        val published = host.shown.size

        perform(MediaCommand.SeekBy(30.0))
        player.advance(1.seconds)
        assertEquals(published + 1, host.shown.size, "a seek jumps away from the extrapolation")
        assertEquals(115.0, last.positionSeconds, "the player's own step, not the 30 s the OS asked for")

        // A stall: ten seconds pass with the position stuck and the status still PLAYING.
        player.advance(10.seconds)
        player.position(115.5)
        assertEquals(115.5, last.positionSeconds)

        player.dispatch(PlayerCommand.SetSpeed(1.5))
        assertEquals(1.5, last.rate)
    }

    @Test
    fun aSeekWhilePausedPublishes() = controlsTest {
        player.playing(position = 100.0, duration = 600.0)
        perform(MediaCommand.Pause)
        player.advance(20.seconds)
        val published = host.shown.size
        player.position(100.4)
        assertEquals(published, host.shown.size, "paused, the OS holds the position; a small report changes nothing")
        perform(MediaCommand.SeekTo(300.0))
        assertEquals(300.0, last.positionSeconds)
        assertEquals(NowPlayingStatus.PAUSED, last.status)
    }

    @Test
    fun commandsActLikeThePlayersOwnButtons() = controlsTest {
        player.playing(position = 100.0, duration = 600.0)
        player.sessionInfo { it.copy(episode = true, nextEpisode = NextEpisode("Next", null, autoplay = false), hasPreviousEpisode = true) }

        perform(MediaCommand.Pause)
        perform(MediaCommand.TogglePause)
        perform(MediaCommand.Play)
        assertEquals(listOf(true, false, false), player.engine.paused)

        perform(MediaCommand.SeekTo(700.0))
        perform(MediaCommand.SeekBy(-1000.0))
        player.advance(1.seconds)
        assertEquals(listOf(600.0, 590.0), player.engine.seeks.map { it.first }, "seeks clamp to the file; a skip is one step")
        assertEquals(listOf(600.0, 590.0), player.session.seeks, "and the session records them as seeks")

        perform(MediaCommand.Next)
        assertEquals(1, player.session.nextEpisodes)

        perform(MediaCommand.Previous)
        assertEquals(0.0, player.engine.seeks.last().first, "past the first seconds Previous restarts, as the button does")
        assertEquals(0, player.session.previousEpisodes)
        player.playing(position = 2.0, duration = 600.0)
        perform(MediaCommand.Previous)
        assertEquals(1, player.session.previousEpisodes)

        perform(MediaCommand.Stop)
        assertEquals(1, player.host.closed)
    }

    @Test
    fun theHostHearsTheViewersPausesButNotTheSystems() = controlsTest {
        player.playing(position = 100.0, duration = 600.0)

        dispatch(PlayerCommand.Pause)
        assertEquals(1, host.userPauses, "the player's own Pause")

        dispatch(PlayerCommand.TogglePause)
        assertEquals(1, host.userPauses, "a toggle that plays is no pause")

        perform(MediaCommand.SystemPause)
        assertEquals(1, host.userPauses, "the system's pause isn't the viewer's")

        player.engineState { it.copy(paused = false) }
        perform(MediaCommand.Pause)
        assertEquals(2, host.userPauses, "the OS controls' Pause")
    }

    @Test
    fun releaseHidesTheControlsAndIgnoresLateCommands() = controlsTest {
        player.playing()
        controls.release()
        assertEquals(1, host.hidden)
        assertNull(controls.nowPlaying)
        val published = host.shown.size

        perform(MediaCommand.Pause)
        player.engineState { it.copy(paused = true) }
        assertEquals(emptyList(), player.engine.paused)
        assertEquals(published, host.shown.size)
        controls.release()
        assertEquals(1, host.hidden)
    }
}
