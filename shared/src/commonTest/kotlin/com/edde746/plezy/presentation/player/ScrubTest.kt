package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.Chapter
import kotlinx.coroutines.flow.update
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class ScrubTest {
    @Test
    fun draggingMovesThePreviewAndTheVideoFollowsAtMostEveryTwoHundredMilliseconds() = playerTest {
        playing(position = 100.0, duration = 600.0)
        engine.echo = false
        dispatch(PlayerCommand.ScrubTo(0.5))
        assertEquals(ScrubState(seconds = 300.0, progress = 0.5f, position = "5:00", offset = "+3:20", chapter = null), timeline.scrub)
        // The first move seeks at once; the moves within the next 200 ms wait, and the last of them goes as they end.
        assertEquals(listOf(300.0 to true), engine.seeks)
        advance(50.milliseconds)
        dispatch(PlayerCommand.ScrubTo(0.2))
        advance(50.milliseconds)
        dispatch(PlayerCommand.ScrubTo(0.1))
        assertEquals(ScrubState(seconds = 60.0, progress = 0.1f, position = "1:00", offset = "−0:40", chapter = null), timeline.scrub)
        advance(99.milliseconds)
        assertEquals(listOf(300.0 to true), engine.seeks)
        advance(1.milliseconds)
        assertEquals(listOf(300.0 to true, 60.0 to true), engine.seeks)
        // A drag at rest seeks nothing more; the next move after a quiet interval seeks at once again.
        advance(1.seconds)
        dispatch(PlayerCommand.ScrubTo(0.3))
        assertEquals(listOf(300.0 to true, 60.0 to true, 180.0 to true), engine.seeks)
        // The position beside the bar is the engine's until the release.
        assertEquals("1:40", timeline.position)
    }

    @Test
    fun releasingSeeksToThePreviewAndTheBarHoldsTheTargetUntilTheEngineGetsThere() = playerTest {
        playing(position = 100.0, duration = 600.0)
        engine.echo = false
        dispatch(PlayerCommand.ScrubTo(0.25))
        dispatch(PlayerCommand.ScrubTo(0.75))
        dispatch(PlayerCommand.CommitScrub)
        // The move still waiting goes with the release, which seeks there.
        assertEquals(listOf(150.0 to true, 450.0 to true), engine.seeks)
        assertNull(timeline.scrub)
        advance(1.seconds)
        assertEquals(2, engine.seeks.size)
        // The engine still reports the old position: the bar shows the target, not a jump back.
        position(100.3)
        assertEquals("7:30", timeline.position)
        position(450.2)
        assertEquals("7:30", timeline.position)
        position(451.0)
        assertEquals("7:31", timeline.position)
    }

    @Test
    fun aReleaseWhereTheLastSeekAlongWentSeeksNoMore() = playerTest {
        playing(position = 100.0, duration = 600.0)
        engine.echo = false
        dispatch(PlayerCommand.ScrubTo(0.5))
        dispatch(PlayerCommand.CommitScrub)
        assertEquals(listOf(300.0 to true), engine.seeks)
        assertEquals("5:00", timeline.position)
    }

    @Test
    fun aSeekTheEngineNeverConfirmsShowsTheEnginePositionAgainAfterATimeout() = playerTest {
        playing(position = 100.0, duration = 600.0)
        engine.echo = false
        dispatch(PlayerCommand.ScrubTo(0.5))
        dispatch(PlayerCommand.CommitScrub)
        advance(1499.milliseconds)
        assertEquals("5:00", timeline.position)
        advance(1.milliseconds)
        assertEquals("1:40", timeline.position)
    }

    @Test
    fun cancellingDropsThePreviewAndTakesTheVideoBackWhereTheScrubStarted() = playerTest {
        playing(position = 100.0, duration = 600.0)
        dispatch(PlayerCommand.ScrubTo(0.9))
        dispatch(PlayerCommand.ScrubTo(0.8))
        dispatch(PlayerCommand.CancelScrub)
        assertNull(timeline.scrub)
        advance(1.seconds)
        assertEquals(listOf(540.0 to true, 100.0 to true), engine.seeks)
    }

    @Test
    fun inAWatchTogetherRoomOnlyTheReleaseSeeks() = playerTest {
        playing(position = 100.0, duration = 600.0)
        val watch = FakeWatch(canControl = true, canChangeEpisode = true)
        watch.routesControls = true
        store.attachWatch(watch)
        dispatch(PlayerCommand.ScrubTo(0.5))
        advance(1.seconds)
        dispatch(PlayerCommand.ScrubTo(0.6))
        assertTrue(engine.seeks.isEmpty())
        dispatch(PlayerCommand.CommitScrub)
        assertEquals(listOf(360.0), watch.seeks)
    }

    @Test
    fun aScrubTheRoomTakesControlFromEndsAtOnceAndItsReleaseSeeksNothing() = playerTest {
        playing(position = 100.0, duration = 600.0)
        val watch = FakeWatch(canControl = true, canChangeEpisode = true)
        watch.routesControls = true
        store.attachWatch(watch)
        dispatch(PlayerCommand.ScrubTo(0.5))
        assertNotNull(timeline.scrub)
        watch.state.update { it?.copy(canControl = false) }
        advance(Duration.ZERO)
        assertNull(timeline.scrub)
        assertFalse(state.scrubbing)
        dispatch(PlayerCommand.CommitScrub)
        assertTrue(watch.seeks.isEmpty())
        assertTrue(engine.seeks.isEmpty())
    }

    @Test
    fun aScrubEndsWithTheFileUnderIt() = playerTest {
        playing(position = 100.0, duration = 600.0)
        dispatch(PlayerCommand.ScrubTo(0.5))
        engineState { it.copy(loaded = false) }
        assertNull(timeline.scrub)
        assertFalse(state.scrubbing)
        dispatch(PlayerCommand.CommitScrub)
        assertEquals(listOf(300.0 to true), engine.seeks, "only the drag's own seek: the next file isn't seeked")
    }

    @Test
    fun thePreviewNamesTheChapterUnderIt() = playerTest {
        playing(position = 10.0, duration = 600.0)
        engineState { it.copy(chapters = listOf(Chapter("Opening", 0.0), Chapter("Part A", 90.0), Chapter("Credits", 540.0))) }
        dispatch(PlayerCommand.ScrubTo(0.5))
        assertEquals("Part A", timeline.scrub?.chapter)
        assertEquals(listOf(0.15f, 0.9f), timeline.chapters)
    }

    @Test
    fun chapterMarksOffLeavesTheBarUnmarkedAndThePreviewNamed() = playerTest {
        playing(position = 10.0, duration = 600.0)
        engineState { it.copy(chapters = listOf(Chapter("Opening", 0.0), Chapter("Part A", 90.0))) }
        sessionInfo { it.copy(chapterMarks = false) }
        dispatch(PlayerCommand.ScrubTo(0.5))
        assertEquals("Part A", timeline.scrub?.chapter)
        assertEquals(emptyList(), timeline.chapters)
    }

    /**
     * A mouse resting over the bar has the tooltip of the whole second under it, its thumbnail asked once for that
     * second: moves within it keep the very same tooltip; a scrub takes its place, and leaving the bar ends it.
     */
    @Test
    fun hoverShowsTheSecondUnderTheMouseAndMovesWithinItKeepTheSameTooltip() = playerTest {
        playing(position = 100.0, duration = 600.0)
        engineState { it.copy(chapters = listOf(Chapter("Opening", 0.0), Chapter("Part A", 90.0))) }
        val asked = mutableListOf<Duration>()
        sessionInfo {
            it.copy(
                scrubPreview = object : ScrubPreviewSource {
                    override val isAvailable = true
                    override fun frameAt(time: Duration): ScrubFrame {
                        asked += time
                        return ScrubFrame.Bytes(byteArrayOf(1))
                    }
                    override fun dispose() = Unit
                },
            )
        }
        dispatch(PlayerCommand.HoverTimeline(0.5004))
        val hover = assertNotNull(timeline.hover)
        assertEquals(300.0, hover.seconds)
        assertEquals("5:00", hover.position)
        assertEquals("", hover.offset, "the hovered time alone, no offset from itself")
        assertEquals("Part A", hover.chapter)
        assertNotNull(hover.frame)
        dispatch(PlayerCommand.HoverTimeline(0.5012))
        position(100.5)
        assertSame(hover, timeline.hover)
        assertEquals(listOf(300.seconds), asked)
        dispatch(PlayerCommand.HoverTimeline(0.502))
        assertEquals(301.0, timeline.hover?.seconds)
        assertTrue(engine.seeks.isEmpty())

        dispatch(PlayerCommand.ScrubTo(0.25))
        assertNull(timeline.hover)
        dispatch(PlayerCommand.CommitScrub)
        assertEquals(301.0, timeline.hover?.seconds)
        dispatch(PlayerCommand.HoverTimeline(null))
        assertNull(timeline.hover)
    }

    /**
     * The position, the cache and a drag's preview move the timeline alone: the rest of the player's state stays the
     * same value, so the views that don't draw the timeline aren't drawn again as the video plays.
     */
    @Test
    fun playbackAndADragMoveTheTimelineAndLeaveTheRestOfTheStateAsItIs() = playerTest {
        playing(position = 100.0, duration = 600.0)
        val playing = state
        position(100.25)
        engineState { it.copy(cacheEndSeconds = 131.0) }
        position(101.0)
        assertSame(playing, state)
        assertEquals("1:41", timeline.position)
        assertEquals(131f / 600f, timeline.buffered, 0.0001f)

        dispatch(PlayerCommand.ScrubTo(0.5))
        val scrubbing = state
        assertTrue(scrubbing.scrubbing)
        dispatch(PlayerCommand.ScrubTo(0.6))
        position(101.5)
        assertSame(scrubbing, state)
        assertEquals("6:00", timeline.scrub?.position)
    }

    private fun PlayerHarness.preview(): Double = assertNotNull(timeline.scrub).seconds
}
