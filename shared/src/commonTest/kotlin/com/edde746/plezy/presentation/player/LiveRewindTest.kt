package com.edde746.plezy.presentation.player

import com.edde746.plezy.format.clockTime
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.session.LiveWindow
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/**
 * A live playback with a rewind window ([SessionInfo.liveWindow]): its timeline is the window, positions count from the
 * live edge, and it seeks within it.
 */
class LiveRewindTest {
    private fun liveTest(profile: InputProfile = InputProfile.TV, body: PlayerHarness.() -> Unit) =
        playerTest(profile, body = body)

    /** The clock time at [millis] as the player shows it on a 24-hour clock, the store's until the UI says otherwise. */
    private fun aired(millis: Long, use24HourClock: Boolean = true) = clockTime(millis.floorDiv(1000L), use24HourClock)

    /** The engine joined a 90-s window of 2-s segments 6 s behind the edge, now, at [position]; it plays there. */
    private fun PlayerHarness.joined(position: Double = 0.0, windowSeconds: Double = 90.0) {
        sessionInfo {
            it.copy(live = true, liveWindow = LiveWindow(windowSeconds, 2.0, joinedBehindSeconds = 6.0, joinedPositionSeconds = position, joinedAt = timeSource.markNow()))
        }
        playing(position = position, duration = position + 6.0)
        engineState { it.copy(seekable = false) }
    }

    @Test
    fun atTheEdgeItReadsLiveAndBehindItShowsHowFar() = liveTest {
        joined()
        assertEquals(PlaybackMode.LIVE_WINDOW, state.mode)
        assertTrue(state.seekable && state.showsTimeline, "a window to seek in")
        assertFalse(state.showsSeekButtons, "the live label in back and forward's place")
        val edge = timeline
        assertTrue(edge.atLiveEdge, "6 s behind, where a stream opens, is the edge")
        assertEquals(1f, edge.progress, "the bar runs to the edge")
        assertEquals("", edge.behind)
        assertEquals(aired(clock.nowMillis - 6_000), edge.position, "the clock time the edge went out: 6 s ago")
        assertEquals("", edge.remaining)
        assertEquals(T.player.live.atEdge, edge.positionLabel)
        assertEquals(T.player.live.badge, edge.liveLabel, "LIVE alone at the edge: no time played")

        dispatch(PlayerCommand.SeekBy(-30.0))
        assertEquals(listOf(36.0), session.liveSeeks, "30 s further back than it was, counted from the edge")
        assertEquals(emptyList(), engine.seeks, "the session moves the engine")
        assertEquals(emptyList(), session.seeks, "nothing is saved")
        val behind = timeline
        assertFalse(behind.atLiveEdge)
        assertEquals("−0:36", behind.behind)
        assertEquals(T.player.live.behind("0:36"), behind.positionLabel)
        assertEquals(T.detail.infoJoin(T.player.live.badge, "−0:36"), behind.liveLabel, "how far behind")
        assertEquals(54f / 90f, behind.progress, 0.001f)
    }

    @Test
    fun theBarShowsTheClockTimeTheShownPositionWentOutLive() = liveTest {
        joined(windowSeconds = 3600.0)
        dispatch(PlayerCommand.SeekBy(-1200.0))
        assertEquals(listOf(1206.0), session.liveSeeks)
        // The session reopened 1206 s behind: the engine's new file starts at 0 there.
        sessionInfo { it.copy(liveWindow = it.liveWindow!!.copy(joinedBehindSeconds = 1206.0, joinedPositionSeconds = 0.0, joinedAt = timeSource.markNow())) }
        position(0.0)
        assertEquals(aired(clock.nowMillis - 1_206_000), timeline.position, "20 min and 6 s before now")

        clock.nowMillis += 120_000
        advance(120.seconds)
        position(120.0)
        assertEquals(aired(clock.nowMillis - 1_206_000), timeline.position, "it moves on with the clock as it plays")
        assertEquals(aired(1_767_297_600_000L - 1_086_000), timeline.position)

        store.setUse24HourClock(false)
        assertEquals(aired(clock.nowMillis - 1_206_000, use24HourClock = false), timeline.position, "a 12-hour clock as soon as the platform has one")
    }

    @Test
    fun theEdgeMovesOnWithTheClockAndGoToLiveReturnsToIt() = liveTest {
        joined()
        advance(20.seconds)
        position(20.0)
        assertTrue(timeline.atLiveEdge, "playing keeps up with the edge")

        dispatch(PlayerCommand.SeekBy(-40.0))
        // The session reopened 46 s behind: the engine's new file starts at 0, 46 s behind the edge.
        sessionInfo { it.copy(liveWindow = it.liveWindow!!.copy(joinedBehindSeconds = 46.0, joinedPositionSeconds = 0.0, joinedAt = timeSource.markNow())) }
        position(0.0)
        advance(10.seconds)
        position(10.0)
        assertEquals("−0:46", timeline.behind, "behind by as much while it plays")

        dispatch(PlayerCommand.GoToLive)
        assertEquals(listOf(46.0, 0.0), session.liveSeeks, "go to live asks for the edge")
    }

    @Test
    fun aSeekPastEitherEndOfTheWindowStopsThere() = liveTest {
        joined()
        dispatch(PlayerCommand.SeekBy(30.0))
        dispatch(PlayerCommand.SeekBy(-600.0))
        assertEquals(listOf(0.0, 90.0), session.liveSeeks, "the edge, then the window's start")
    }

    @Test
    fun theRemoteScrubsTheWindowAsAVideosTimeline() = liveTest {
        joined()
        dispatch(PlayerCommand.ShowControls)
        store.onTimelineFocusChanged(true)
        input(InputEvent.KeyDown(InputKey.LEFT))
        assertEquals("−0:16", timeline.behind, "the target counts from the edge")
        assertEquals(aired(clock.nowMillis - 16_000), timeline.position, "the target's clock time")
        assertTrue(input(InputEvent.KeyUp(InputKey.LEFT)), "the focused timeline takes Left")
        assertEquals(listOf(16.0), session.liveSeeks, "one seek as the key comes up")

        assertTrue(press(InputKey.RIGHT))
        assertTrue(press(InputKey.RIGHT))
        assertEquals(listOf(16.0, 0.0, 0.0), session.liveSeeks, "past the edge the seek stops at live")
    }

    @Test
    fun aFingerScrubsTheWindowAndAClickSeeksInIt() = liveTest(InputProfile.TOUCH) {
        joined()
        dispatch(PlayerCommand.ShowControls)
        dispatch(PlayerCommand.ScrubTo(0.5))
        assertEquals(aired(clock.nowMillis - 45_000), timeline.scrub?.position, "the preview's clock time")
        dispatch(PlayerCommand.CommitScrub)
        assertEquals(listOf(45.0), session.liveSeeks)

        dispatch(PlayerCommand.SeekToFraction(0.25))
        assertEquals(listOf(45.0, 67.5), session.liveSeeks, "a quarter of the way into the window")
    }

    @Test
    fun theArrowKeysSeekWithinTheWindow() = liveTest(InputProfile.DESKTOP) {
        joined()
        assertTrue(press(InputKey.LEFT))
        assertEquals(listOf(16.0), session.liveSeeks, "10 s further back than the edge's 6")
        assertTrue(press(InputKey.RIGHT))
        assertEquals(listOf(16.0, 0.0), session.liveSeeks, "10 s on is within the edge's slack: live")
    }

    /** Go to live jumps the whole way to the edge: the seek badge a key raised on the way back goes with it. */
    @Test
    fun goToLiveTakesDownTheBadgeOfASkipBack() = liveTest(InputProfile.DESKTOP) {
        joined()
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        press(InputKey.LEFT)
        assertEquals("10s", state.skipBadge?.label)
        dispatch(PlayerCommand.GoToLive)
        assertEquals(null, state.skipBadge)
    }

    @Test
    fun aPausedPositionTheWindowSlidPastPlaysFromTheWindowsStart() = liveTest {
        joined(position = 30.0)
        dispatch(PlayerCommand.Pause)
        advance(60.seconds)
        assertEquals("−1:06", timeline.behind, "paused, it falls behind as the edge moves on")
        dispatch(PlayerCommand.Play)
        assertEquals(emptyList(), session.liveSeeks, "still in the window: it plays on from where it paused")

        dispatch(PlayerCommand.Pause)
        advance(30.seconds)
        dispatch(PlayerCommand.Play)
        assertEquals(listOf(90.0), session.liveSeeks, "the window slid past it: the window's start")
        assertEquals(false, engine.paused.last())
    }

    @Test
    fun aWindowShorterThanTheMinimumOrNoneKeepsTheLiveLabelAlone() = liveTest {
        sessionInfo { it.copy(live = true) }
        playing(position = 30.0, duration = 36.0)
        assertEquals(PlaybackMode.LIVE, state.mode)
        assertFalse(state.seekable)
        dispatch(PlayerCommand.SeekBy(-10.0))
        dispatch(PlayerCommand.GoToLive)
        press(InputKey.LEFT)
        assertFalse(state.scrubbing, "no scrub preview")
        assertEquals(emptyList(), session.liveSeeks)
        assertEquals(emptyList(), engine.seeks)
    }

    /** Every player has watch together attached ([PlayerStore.attachWatch]); only one following a room loses rewind. */
    @Test
    fun aPlayerFollowingARoomKeepsTheLiveLabelAlone() = liveTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = true)
        store.attachWatch(watch)
        joined()
        assertEquals(PlaybackMode.LIVE_WINDOW, state.mode, "outside a room")
        dispatch(PlayerCommand.SeekBy(-30.0))
        assertEquals(listOf(36.0), session.liveSeeks)

        watch.routesControls = true
        dispatch(PlayerCommand.ShowControls)
        assertEquals(PlaybackMode.LIVE, state.mode, "in a room")
        dispatch(PlayerCommand.SeekBy(-10.0))
        assertEquals(listOf(36.0), session.liveSeeks)
    }

    @Test
    fun anEventThatEndedPlaysOnAsLiveWithoutItsWindow() = liveTest {
        joined()
        dispatch(PlayerCommand.ShowControls)
        store.onTimelineFocusChanged(true)
        sessionInfo { it.copy(liveWindow = null) }
        assertEquals(PlaybackMode.LIVE, state.mode)
        input(InputEvent.ControlFocus(onControl = true))
        assertFalse(press(InputKey.LEFT), "the timeline went, and its focus with it")
        dispatch(PlayerCommand.SeekBy(-10.0))
        assertEquals(emptyList(), session.liveSeeks)
    }
}
