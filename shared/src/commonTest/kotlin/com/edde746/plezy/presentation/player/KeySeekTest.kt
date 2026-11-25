package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.KeyModifiers
import com.edde746.plezy.input.KeySource
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.session.LiveWindow
import com.edde746.plezy.playback.session.NextEpisode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Seeking with keys: a remote's arrows with the controls down seek without raising them, the seek badge counting what
 * they moved; a held arrow accelerates and seeks once as it comes up; the media keys skip chapters; the keyboard's seek
 * shortcuts badge their steps too.
 */
class KeySeekTest {
    /** On a TV remote, ten minutes into an hour, the controls down. */
    private fun remoteTest(body: PlayerHarness.() -> Unit) = playerTest(InputProfile.TV) {
        playing(position = 600.0, duration = 3600.0)
        advance(5.seconds)
        assertFalse(state.controlsVisible)
        body()
    }

    private fun PlayerHarness.tap(key: InputKey) {
        input(InputEvent.KeyDown(key, source = KeySource.REMOTE))
        input(InputEvent.KeyUp(key))
    }

    private fun PlayerHarness.hold(key: InputKey, repeats: Int) {
        input(InputEvent.KeyDown(key, source = KeySource.REMOTE))
        repeat(repeats) { input(InputEvent.KeyDown(key, repeat = true, source = KeySource.REMOTE)) }
        input(InputEvent.KeyUp(key))
    }

    @Test
    fun aRightArrowTapSeeksWithoutRaisingTheChrome() = remoteTest {
        input(InputEvent.KeyDown(InputKey.RIGHT, source = KeySource.REMOTE))
        assertFalse(state.controlsVisible, "seeking must not cover the picture")
        assertEquals("10s", state.skipBadge?.label)
        assertTrue(state.skipBadge!!.forward)
        input(InputEvent.KeyUp(InputKey.RIGHT))
        assertFalse(state.controlsVisible)
        assertEquals(listOf(610.0), engine.seeks.map { it.first })
    }

    @Test
    fun repeatedTapsInOneDirectionStackIntoARunningTotal() = remoteTest {
        repeat(3) { tap(InputKey.RIGHT) }
        assertEquals("30s", state.skipBadge?.label)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun flippingDirectionRestartsTheBadgeCount() = remoteTest {
        tap(InputKey.RIGHT)
        assertEquals("10s", state.skipBadge?.label)
        tap(InputKey.LEFT)
        assertEquals("10s", state.skipBadge?.label, "the reverse burst is counted on its own")
        assertFalse(state.skipBadge!!.forward)
    }

    @Test
    fun aBurstThatReachesTheStartStopsCountingThere() = remoteTest {
        playing(position = 25.0, duration = 3600.0)
        repeat(5) { tap(InputKey.LEFT) }
        assertEquals("25s", state.skipBadge?.label, "the readout reports the distance travelled, not five steps")
        assertEquals(listOf(15.0, 5.0, 0.0), engine.seeks.map { it.first })
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aPressWithNothingToRewindThroughRaisesNoBadgeAndNoSeek() = remoteTest {
        playing(position = 0.0, duration = 3600.0)
        tap(InputKey.LEFT)
        assertNull(state.skipBadge)
        assertTrue(engine.seeks.isEmpty())
        tap(InputKey.RIGHT)
        assertEquals("10s", state.skipBadge?.label)
        assertEquals(listOf(10.0), engine.seeks.map { it.first })
    }

    @Test
    fun aHeldRewindOfFractionalStepsReadsTheDistanceTravelled() = playerTest(
        InputProfile.TV,
        preferences = PlayerChoices(seekSeconds = 5),
    ) {
        playing(position = 25.0, duration = 3600.0)
        advance(5.seconds)
        hold(InputKey.LEFT, repeats = 3)
        assertEquals("25s", state.skipBadge?.label)
        assertEquals(listOf(0.0), engine.seeks.map { it.first })
    }

    @Test
    fun aHeldArrowAcceleratesAndCommitsExactlyOneSeekOnRelease() = remoteTest {
        input(InputEvent.KeyDown(InputKey.RIGHT, source = KeySource.REMOTE))
        repeat(8) { input(InputEvent.KeyDown(InputKey.RIGHT, repeat = true, source = KeySource.REMOTE)) }
        assertFalse(state.controlsVisible, "a held seek must not escalate to the scrub bar")
        assertTrue(engine.seeks.isEmpty(), "the burst is coalesced, not dispatched per repeat")
        input(InputEvent.KeyUp(InputKey.RIGHT))
        // 10 s, five repeats at 1.5×, three at 3×.
        assertEquals(listOf(775.0), engine.seeks.map { it.first })
    }

    @Test
    fun theTiersAndTheStepClamp() {
        assertEquals(1.5, SeekBurst.steppedMultiplier(1))
        assertEquals(1.5, SeekBurst.steppedMultiplier(5))
        assertEquals(3.0, SeekBurst.steppedMultiplier(6))
        assertEquals(3.0, SeekBurst.steppedMultiplier(15))
        assertEquals(6.0, SeekBurst.steppedMultiplier(16))
        assertEquals(6.0, SeekBurst.steppedMultiplier(30))
        assertEquals(10.0, SeekBurst.steppedMultiplier(31))
    }

    @Test
    fun aStepIsClampedToTwoMinutes() = playerTest(InputProfile.TV, preferences = PlayerChoices(seekSeconds = 60)) {
        playing(position = 600.0, duration = 3600.0)
        advance(5.seconds)
        input(InputEvent.KeyDown(InputKey.RIGHT, source = KeySource.REMOTE))
        repeat(16) { input(InputEvent.KeyDown(InputKey.RIGHT, repeat = true, source = KeySource.REMOTE)) }
        input(InputEvent.KeyUp(InputKey.RIGHT))
        // 60, five at 90, ten at 120 (180 clamped), one at 120 (360 clamped).
        assertEquals(listOf(600.0 + 60 + 5 * 90 + 11 * 120), engine.seeks.map { it.first })
    }

    @Test
    fun upArrowStillRaisesTheChromeAsTheDeliberateEscapeHatch() = remoteTest {
        tap(InputKey.UP)
        assertTrue(state.controlsVisible)
        assertEquals(1, state.playPauseFocus, "Play/Pause takes focus")
    }

    @Test
    fun aMediaFastForwardKeySkipsWithABadgeAndNoChrome() = remoteTest {
        tap(InputKey.MEDIA_FAST_FORWARD)
        assertFalse(state.controlsVisible)
        assertEquals("10s", state.skipBadge?.label)
        assertEquals(listOf(610.0), engine.seeks.map { it.first })
    }

    @Test
    fun aRapidMediaKeyBurstCommitsTheTotalTheBadgeReports() = remoteTest {
        engine.echo = false
        repeat(3) { tap(InputKey.MEDIA_FAST_FORWARD) }
        assertEquals("30s", state.skipBadge?.label)
        assertEquals(listOf(610.0, 620.0, 630.0), engine.seeks.map { it.first })
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aHeldMediaFastForwardIsConsumedWholeAndCommitsOneSkip() = remoteTest {
        assertTrue(input(InputEvent.KeyDown(InputKey.MEDIA_FAST_FORWARD, source = KeySource.REMOTE)), "down")
        repeat(4) { assertTrue(input(InputEvent.KeyDown(InputKey.MEDIA_FAST_FORWARD, repeat = true, source = KeySource.REMOTE)), "repeat $it") }
        assertTrue(engine.seeks.isEmpty(), "the press is coalesced, not dispatched per event")
        assertTrue(input(InputEvent.KeyUp(InputKey.MEDIA_FAST_FORWARD)), "up")
        assertEquals(listOf(610.0), engine.seeks.map { it.first }, "one press is one step, however long it is held")
        assertEquals("10s", state.skipBadge?.label)
    }

    @Test
    fun aRewindBurstMirrorsAFastForwardBurstFromTheSamePosition() = remoteTest {
        tap(InputKey.MEDIA_FAST_FORWARD)
        playing(position = 600.0, duration = 3600.0)
        advance(2.seconds)
        tap(InputKey.MEDIA_REWIND)
        assertEquals(listOf(610.0, 590.0), engine.seeks.map { it.first })
    }

    @Test
    fun aSkipAfterAJumpElsewhereStartsFromWhereTheJumpLanded() = remoteTest {
        tap(InputKey.MEDIA_FAST_FORWARD)
        assertEquals(listOf(610.0), engine.seeks.map { it.first })
        dispatch(PlayerCommand.SeekTo(1800.0))
        tap(InputKey.MEDIA_FAST_FORWARD)
        assertEquals(1810.0, engine.seeks.last().first, "relative to the new position, not to the superseded target")
    }

    @Test
    fun aNewItemDropsThePreviousItemsPendingSkipAndItsBadgeTotal() = remoteTest {
        engine.echo = false
        input(InputEvent.KeyDown(InputKey.MEDIA_FAST_FORWARD, source = KeySource.REMOTE))
        assertEquals("10s", state.skipBadge?.label)
        // The next item opens before the key comes up.
        engineState { it.copy(loaded = false) }
        assertNull(state.skipBadge)
        input(InputEvent.KeyUp(InputKey.MEDIA_FAST_FORWARD))
        assertTrue(engine.seeks.isEmpty(), "the abandoned burst never lands on the new item")
    }

    @Test
    fun aMediaFastForwardKeyAnnouncesTheChapterItLandsOn() = remoteTest {
        engineState { it.copy(chapters = listOf(Chapter("Cold Open", 0.0), Chapter("The Heist", 900.0))) }
        tap(InputKey.MEDIA_FAST_FORWARD)
        assertFalse(state.controlsVisible)
        assertNull(state.skipBadge, "a chapter jump is not an N-second skip")
        assertEquals("Chapter: \u2068The Heist\u2069", state.osd)
        assertEquals(listOf(900.0), engine.seeks.map { it.first })
    }

    @Test
    fun aChapterSeekPastTheLastChapterAnnouncesNothing() = remoteTest {
        engineState { it.copy(chapters = listOf(Chapter("Cold Open", 0.0), Chapter("The Heist", 300.0))) }
        tap(InputKey.MEDIA_FAST_FORWARD)
        assertNull(state.osd)
        assertNull(state.skipBadge)
        assertTrue(engine.seeks.isEmpty())
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aBackwardChapterSeekAtTheVeryStartAnnouncesNothing() = remoteTest {
        playing(position = 0.0, duration = 3600.0)
        engineState { it.copy(chapters = listOf(Chapter("Cold Open", 0.0), Chapter("The Heist", 900.0))) }
        tap(InputKey.MEDIA_REWIND)
        assertNull(state.osd)
        assertTrue(engine.seeks.isEmpty(), "already at the start: nothing to rewind to")
    }

    @Test
    fun theBadgeGoesAfterItsTime() = remoteTest {
        tap(InputKey.RIGHT)
        advance(1199.milliseconds)
        assertEquals("10s", state.skipBadge?.label)
        advance(1.milliseconds)
        assertNull(state.skipBadge)
    }

    @Test
    fun theFocusedTimelineSeeksInBurstsWithoutTheBadge() = playerTest(InputProfile.TV) {
        playing(position = 600.0, duration = 3600.0)
        dispatch(PlayerCommand.ShowControls)
        input(InputEvent.ControlFocus(onControl = true))
        store.onTimelineFocusChanged(true)
        input(InputEvent.KeyDown(InputKey.RIGHT, source = KeySource.REMOTE))
        repeat(2) { input(InputEvent.KeyDown(InputKey.RIGHT, repeat = true, source = KeySource.REMOTE)) }
        assertEquals("10:40", timeline.position, "the timeline shows the target")
        assertTrue(engine.seeks.isEmpty())
        input(InputEvent.KeyUp(InputKey.RIGHT))
        assertEquals(listOf(640.0), engine.seeks.map { it.first })
        assertNull(state.skipBadge)
        assertTrue(state.controlsVisible)
    }

    // The keyboard's seek shortcuts

    @Test
    fun theConfiguredSeekShortcutShowsTheBadgeAndLeavesTheChromeDown() = playerTest {
        playing(position = 600.0, duration = 3600.0)
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        press(InputKey.RIGHT)
        assertEquals("10s", state.skipBadge?.label)
        assertTrue(state.skipBadge!!.forward)
        assertFalse(state.controlsVisible)
        assertEquals(listOf(610.0), engine.seeks.map { it.first })
    }

    @Test
    fun theBackwardShortcutReportsItsOwnDirection() = playerTest {
        playing(position = 600.0, duration = 3600.0)
        press(InputKey.LEFT)
        assertFalse(state.skipBadge!!.forward)
        assertEquals(listOf(590.0), engine.seeks.map { it.first })
    }

    @Test
    fun theLargeSeekShortcutReportsTheLargeAmount() = playerTest(preferences = PlayerChoices(longSeekSeconds = 45)) {
        playing(position = 600.0, duration = 3600.0)
        press(InputKey.RIGHT, KeyModifiers(shift = true))
        assertEquals("45s", state.skipBadge?.label)
        assertEquals(listOf(645.0), engine.seeks.map { it.first })
    }

    @Test
    fun aRapidBurstCommitsTheTotalTheBadgeReportsEvenWhenSeeksLag() = playerTest {
        playing(position = 600.0, duration = 3600.0)
        engine.echo = false
        repeat(4) { press(InputKey.RIGHT) }
        assertEquals("40s", state.skipBadge?.label)
        assertEquals(listOf(610.0, 620.0, 630.0, 640.0), engine.seeks.map { it.first })
    }

    @Test
    fun switchingWhatIsPlayingTakesTheBadgeWithTheOldTimeline() = playerTest {
        sessionInfo { it.copy(nextEpisode = NextEpisode(title = "Next", subtitle = "S1E2")) }
        playing(position = 600.0, duration = 3600.0)
        input(InputEvent.KeyDown(InputKey.RIGHT))
        assertEquals("10s", state.skipBadge?.label)
        press(InputKey.N, KeyModifiers(shift = true))
        assertNull(state.skipBadge)
        input(InputEvent.KeyUp(InputKey.RIGHT))
        assertTrue(engine.seeks.isEmpty(), "the burst is abandoned with the item")
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun aLiveWindowsStepsAreWholeSeconds() = playerTest(InputProfile.TV, preferences = PlayerChoices(seekSeconds = 10)) {
        sessionInfo {
            it.copy(live = true, liveWindow = LiveWindow(600.0, 2.0, joinedBehindSeconds = 100.0, joinedPositionSeconds = 0.0, joinedAt = timeSource.markNow()))
        }
        playing(position = 0.0, duration = 6.0)
        dispatch(PlayerCommand.HideControls)
        hold(InputKey.LEFT, repeats = 1)
        assertEquals(listOf(125.0), session.liveSeeks, "10 s and 15 s behind the joined 100 s")
    }
}
