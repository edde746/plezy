package com.edde746.plezy.presentation.player

import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.SkipKind
import com.edde746.plezy.playback.SkipSegment
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.SkipModes
import kotlinx.coroutines.flow.update
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

/** The skip button and up next from the credits, on tools/media's chapters.mkv layout. */
class SkipTest {
    /** Recap 0–4, Opening 4–12, Episode 12–44, Ending 44–54, Preview 54–60. */
    private val clip = listOf(Chapter("Recap", 0.0), Chapter("Opening", 4.0), Chapter("Episode", 12.0), Chapter("Ending", 44.0), Chapter("Preview", 54.0))
    private val next = NextEpisode(title = "Chapter Two", subtitle = "S1E2", autoplay = true, countdownSeconds = 10)

    private fun PlayerHarness.clipAt(position: Double, chapters: List<Chapter> = clip) {
        engineState { it.copy(loaded = true, positionSeconds = position, durationSeconds = 60.0, paused = false, eof = false, chapters = chapters) }
    }

    /** The profile's skip modes, with a 3 s auto-skip delay. */
    private fun PlayerHarness.modes(intros: SkipMode = SkipMode.BUTTON, credits: SkipMode = SkipMode.BUTTON) =
        sessionInfo { it.copy(skipping = SkipModes(intros = intros, credits = credits, autoSkipDelaySeconds = 3)) }

    private fun skip(kind: PromptKind, label: String, progress: Float? = null, secondsLeft: Int? = null, withControls: Boolean = false) =
        PlayerPrompt(kind, null, label, progress, secondsLeft, PlayerCommand.SkipSegment, withControls)

    private fun upNext(progress: Float?, secondsLeft: Int? = null, withControls: Boolean = false) =
        PlayerPrompt(PromptKind.UP_NEXT, "S1E2 · ", "Chapter Two", progress, secondsLeft, PlayerCommand.NextEpisode, withControls)

    // The button

    @Test
    fun theButtonShowsForSevenSecondsThenWithTheControls() = playerTest {
        clipAt(20.0)
        advance(4.seconds)
        assertFalse(state.controlsVisible, "the controls hid after 3 s")
        assertNull(state.prompt)
        position(5.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt, "by itself")
        advance(6900.milliseconds)
        assertNotNull(state.prompt)
        advance(100.milliseconds)
        assertNull(state.prompt, "7 s after the intro started")
        input(InputEvent.PointerMove)
        assertTrue(state.controlsVisible)
        assertEquals(skip(PromptKind.INTRO, "Skip intro", withControls = true), state.prompt, "with the controls, still inside the intro")
        position(12.0)
        assertNull(state.prompt)
    }

    @Test
    fun theControlsHidingInItsFirstSecondsLeaveTheButton() = playerTest {
        clipAt(5.0)
        assertTrue(state.controlsVisible, "the controls come up with the video")
        assertEquals(skip(PromptKind.INTRO, "Skip intro", withControls = false), state.prompt)
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt, "still by itself")
        advance(4.seconds)
        assertNull(state.prompt, "7 s after it came up")
    }

    @Test
    fun anAssistiveTechnologyKeepsTheButtonPastItsSevenSeconds() = playerTest {
        store.onAssistiveTechnologyChanged(true)
        clipAt(20.0)
        position(5.0)
        advance(30.seconds)
        assertEquals(skip(PromptKind.INTRO, "Skip intro", withControls = true), state.prompt, "the controls stay up, and the button with them")
    }

    @Test
    fun eachKindHasItsLabel() = playerTest {
        clipAt(1.0)
        assertEquals(skip(PromptKind.RECAP, "Skip recap"), state.prompt)
        position(4.0)
        assertEquals("Skip intro", state.prompt?.label)
        engineState { it.copy(positionSeconds = 46.0) }
        // Without a next episode the credits skip to the end.
        assertEquals(skip(PromptKind.CREDITS, "Skip credits"), state.prompt)
    }

    @Test
    fun skippingSeeksExactlyToTheEndWithoutAMessage() = playerTest {
        clipAt(6.0)
        dispatch(PlayerCommand.SkipSegment)
        assertEquals(12.0 to true, engine.seeks.last())
        assertEquals(12.0, session.seeks.last())
        assertNull(state.osd)
        assertNull(state.prompt)
        // mpv lands a frame short of the end: still not inside.
        position(11.8)
        assertNull(state.prompt)
    }

    @Test
    fun enterSkipsOnTheDesktopWhileTheButtonShows() = playerTest {
        clipAt(20.0)
        assertTrue(press(InputKey.SELECT), "no button: Enter shows the controls and pauses")
        assertEquals(listOf(true), engine.paused)
        position(6.0)
        assertTrue(state.controlsVisible)
        assertTrue(press(InputKey.SELECT), "Enter is the skip shortcut, over the controls too")
        assertEquals(12.0 to true, engine.seeks.last())
    }

    @Test
    fun theCreditsWithoutANextEpisodeSkipToTheEnd() = playerTest {
        clipAt(45.0)
        assertEquals("Skip credits", state.prompt?.label)
        dispatch(PlayerCommand.SkipSegment)
        assertEquals(60.0 to true, engine.seeks.last())
        engineState { it.copy(positionSeconds = 60.0, eof = true, paused = true) }
        assertEquals(PlaybackStatus.ENDED, state.status)
        assertNull(state.prompt)
    }

    @Test
    fun aSegmentNeverOutlivesItsItem() = playerTest {
        clipAt(45.0)
        assertEquals("Skip credits", state.prompt?.label)
        input(InputEvent.PointerMove)
        // The next item resolves while the last file still stands at its credits.
        sessionInfo { it.copy(resolving = true) }
        assertNull(state.prompt, "nothing of the last item beside Preparing stream")
        engineState { it.copy(loaded = false) }
        sessionInfo { it.copy(resolving = false) }
        clipAt(46.0)
        assertEquals("Skip credits", state.prompt?.label, "the new file's own credits")
    }

    @Test
    fun creditsBeforeAPostCreditsSceneSkipToIt() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        clipAt(42.0, listOf(Chapter("Episode", 0.0), Chapter("End Credits", 40.0), Chapter("Post-credits scene", 52.0)))
        assertEquals(skip(PromptKind.CREDITS, "Skip credits"), state.prompt, "not credits to the end: up next keeps its own start")
        dispatch(PlayerCommand.SkipSegment)
        assertEquals(52.0 to true, engine.seeks.last())
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun aKindTurnedOffHasNoButtonAndTheChangeAppliesAtOnce() = playerTest {
        clipAt(6.0)
        assertNotNull(state.prompt)
        modes(intros = SkipMode.OFF)
        assertNull(state.prompt)
        position(2.0)
        assertNull(state.prompt, "a recap follows the intro setting")
    }

    @Test
    fun backDismissesTheButtonUntilTheSegmentEndsSaveWithTheControls() = playerTest(InputProfile.TV) {
        clipAt(5.0)
        assertNotNull(state.prompt)
        press(InputKey.BACK)
        assertNull(state.prompt)
        assertEquals(0, host.closed, "Back doesn't leave the player while the button shows")
        dispatch(PlayerCommand.ShowControls)
        assertNotNull(state.prompt, "dismissed: it still shows with the controls")
        dispatch(PlayerCommand.HideControls)
        assertNull(state.prompt, "and goes with them")
        position(13.0)
        position(6.0)
        assertNotNull(state.prompt, "back in: it shows again")
    }

    @Test
    fun theButtonGoesWithTheControlsAsTheyHide() = playerTest(InputProfile.TV) {
        clipAt(5.0)
        assertNotNull(state.prompt)
        assertTrue(press(InputKey.UP))
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt, "within its seconds")
        dispatch(PlayerCommand.HideControls)
        assertNull(state.prompt, "at once, not at the end of its seconds")
        dispatch(PlayerCommand.ShowControls)
        assertEquals(skip(PromptKind.INTRO, "Skip intro", withControls = true), state.prompt, "still with the controls")
        dispatch(PlayerCommand.HideControls)
        position(13.0)
        position(45.0)
        assertEquals(skip(PromptKind.CREDITS, "Skip credits"), state.prompt, "the next segment shows by itself again")
    }

    @Test
    fun anAutomaticSkipCountsOnAfterTheControlsHide() = playerTest {
        modes(intros = SkipMode.AUTO)
        clipAt(20.0)
        advance(2.seconds)
        position(4.0)
        assertNotNull(state.prompt?.progress)
        advance(1500.milliseconds)
        assertFalse(state.controlsVisible)
        assertNull(state.prompt, "gone with the controls")
        assertTrue(engine.seeks.isEmpty())
        advance(1500.milliseconds)
        assertEquals(12.0 to true, engine.seeks.single(), "skipped at the end of its countdown all the same")
    }

    @Test
    fun onTvSelectSkipsDownBringsTheControlsAndTheDpadIsTheButtons() = playerTest(InputProfile.TV) {
        clipAt(5.0)
        advance(6.seconds)
        assertFalse(state.controlsVisible)
        assertNotNull(state.prompt)
        assertTrue(press(InputKey.UP), "Up brings the controls up")
        assertTrue(state.controlsVisible)
        dispatch(PlayerCommand.HideControls)
        position(45.0)
        press(InputKey.DOWN)
        assertTrue(state.controlsVisible)
        assertTrue(engine.seeks.isEmpty())
        dispatch(PlayerCommand.HideControls)
        position(13.0)
        position(5.0)
        assertTrue(press(InputKey.SELECT))
        assertEquals(12.0 to true, engine.seeks.last())
    }

    // Skip automatically

    @Test
    fun theAutomaticSkipCountsDownOnTheButtonAndWaitsWhilePaused() = playerTest {
        modes(intros = SkipMode.AUTO)
        clipAt(20.0)
        advance(4.seconds)
        position(4.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro", progress = 0f, secondsLeft = 3), state.prompt)
        advance(1200.milliseconds)
        assertEquals(0.4f, state.prompt?.progress)
        // Paused by something else than the viewer (the room's host, the system): the countdown waits.
        engineState { it.copy(paused = true) }
        advance(10.seconds)
        assertEquals(0.4f, state.prompt?.progress)
        assertTrue(engine.seeks.isEmpty())
        engineState { it.copy(paused = false) }
        advance(1700.milliseconds)
        assertTrue(engine.seeks.isEmpty())
        advance(100.milliseconds)
        assertEquals(12.0 to true, engine.seeks.single())
        assertNull(state.prompt)
    }

    @Test
    fun theCountdownRunsOutOnTimeHoweverLateEachStepWakes() = TestTimeSource().let { clock ->
        playerTest(timeSource = clock) {
            modes(intros = SkipMode.AUTO)
            clipAt(4.0)
            // Each 200 ms step wakes 250 ms later, as on a slow TV: the countdown follows the time measured.
            fun lateStep() {
                clock += 250.milliseconds
                advance(200.milliseconds)
            }
            repeat(9) { lateStep() }
            assertEquals(0.75f, state.prompt?.progress, "2.25 s of the 3 s, not 9 steps of 15")
            repeat(2) { lateStep() }
            assertTrue(engine.seeks.isEmpty(), "2.75 s")
            lateStep()
            assertEquals(12.0 to true, engine.seeks.single(), "skipped at 3 s, after 12 late steps rather than 15")
        }
    }

    @Test
    fun anyInputStopsTheCountdownAndLeavesTheButton() = playerTest {
        modes(intros = SkipMode.AUTO)
        clipAt(4.0)
        advance(1.seconds)
        input(InputEvent.PointerMove)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt)
        advance(5.seconds)
        assertTrue(engine.seeks.isEmpty(), "stopped: it doesn't skip")
        advance(2.seconds)
        dispatch(PlayerCommand.HideControls)
        assertNull(state.prompt, "as in Show button: gone 7 s after the input")
    }

    @Test
    fun aKeyOrATapStopsTheCountdownToo() = playerTest(InputProfile.TOUCH) {
        modes(intros = SkipMode.AUTO)
        clipAt(0.5)
        assertNotNull(state.prompt?.progress)
        tap(CENTRE)
        assertNull(state.prompt?.progress)
        advance(5.seconds)
        assertTrue(engine.seeks.isEmpty())
    }

    @Test
    fun aButtonOfTheControlsStopsTheCountdownToo() = playerTest(InputProfile.TOUCH) {
        modes(intros = SkipMode.AUTO)
        clipAt(0.5)
        dispatch(PlayerCommand.Pause)
        assertEquals(skip(PromptKind.RECAP, "Skip recap"), state.prompt)
        dispatch(PlayerCommand.Play)
        advance(5.seconds)
        assertTrue(engine.seeks.isEmpty())
    }

    @Test
    fun eachSegmentSkipsOnItsOwnOncePerPlayback() = playerTest {
        modes(intros = SkipMode.AUTO)
        clipAt(4.0)
        advance(3.seconds)
        assertEquals(12.0 to true, engine.seeks.single())
        // The viewer goes back into it on purpose: the button, never another automatic skip.
        position(6.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt)
        advance(10.seconds)
        assertEquals(1, engine.seeks.size)
    }

    @Test
    fun aNewFileStartsOver() = playerTest {
        modes(intros = SkipMode.AUTO)
        clipAt(4.0)
        advance(3.seconds)
        assertEquals(1, engine.seeks.size)
        // The next file: unloaded, the last file's chapters still reported until the engine drops them.
        engineState { it.copy(loaded = false, positionSeconds = 6.0) }
        assertNull(state.prompt, "no chapters count before the file loaded")
        advance(5.seconds)
        assertEquals(1, engine.seeks.size)
        clipAt(4.0)
        assertEquals(0f, state.prompt?.progress, "a new playback counts down again")
        advance(3.seconds)
        assertEquals(2, engine.seeks.size)
    }

    @Test
    fun aDurationMpvRefinesKeepsTheSegmentAndItsCountdown() = playerTest {
        modes(credits = SkipMode.AUTO)
        clipAt(45.0)
        advance(1200.milliseconds)
        assertEquals(0.4f, state.prompt?.progress)
        // The credits now end a little later: the same segment, counting on.
        engineState { it.copy(durationSeconds = 60.4) }
        assertEquals(0.4f, state.prompt?.progress)
        advance(1800.milliseconds)
        assertEquals(60.4 to true, engine.seeks.single())
    }

    @Test
    fun pictureInPictureHasNoButtonButStillSkips() = playerTest {
        modes(intros = SkipMode.AUTO)
        store.onPictureInPictureChanged(true)
        clipAt(4.0)
        assertNull(state.prompt)
        advance(3.seconds)
        assertEquals(12.0 to true, engine.seeks.single())
    }

    // Credits and up next

    @Test
    fun theCreditsBringUpNextWithTheProfilesCountdown() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        clipAt(43.0)
        assertNull(state.prompt)
        position(44.0)
        assertEquals(upNext(progress = 0f, secondsLeft = 10), state.prompt, "up next is the credits' skip")
        advance(5.seconds)
        assertEquals(0.5f, state.prompt?.progress)
        advance(5.seconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun withoutAutoPlayTheCreditsOnlyOfferTheNextEpisode() = playerTest {
        sessionInfo { it.copy(nextEpisode = next.copy(autoplay = false)) }
        clipAt(45.0)
        assertEquals(upNext(progress = null), state.prompt)
        advance(20.seconds)
        engineState { it.copy(positionSeconds = 60.0, eof = true, paused = true) }
        assertEquals(0, session.nextEpisodes)
        assertEquals(PlaybackStatus.ENDED, state.status)
        assertEquals(upNext(progress = null, withControls = true), state.prompt, "with the controls at the end")
        dispatch(state.prompt!!.command)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun aZeroCountdownPlaysTheNextEpisodeAtTheCredits() = playerTest {
        sessionInfo { it.copy(nextEpisode = next.copy(countdownSeconds = 0)) }
        clipAt(43.0)
        position(44.0)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun creditsSkippedAutomaticallyCountDownTheSkipsSecondsOnUpNext() = playerTest {
        modes(credits = SkipMode.AUTO)
        sessionInfo { it.copy(nextEpisode = next) }
        clipAt(44.0)
        assertEquals(upNext(progress = 0f, secondsLeft = 3), state.prompt, "one button: up next, filling over the skip's 3 s")
        advance(1200.milliseconds)
        assertEquals(0.4f, state.prompt?.progress)
        advance(1800.milliseconds)
        assertEquals(1, session.nextEpisodes)
        assertTrue(engine.seeks.isEmpty())
    }

    @Test
    fun theCreditsCountdownToTheNextEpisodeKeepsCountingThroughInput() = playerTest {
        modes(credits = SkipMode.AUTO)
        sessionInfo { it.copy(nextEpisode = next) }
        clipAt(44.0)
        advance(1.seconds)
        input(InputEvent.PointerMove)
        assertTrue(state.controlsVisible)
        assertEquals(upNext(progress = 1f / 3, secondsLeft = 2), state.prompt)
        advance(2.seconds)
        assertEquals(1, session.nextEpisodes)
        assertTrue(engine.seeks.isEmpty())
    }

    @Test
    fun creditsSetToSkipAutomaticallyWithoutAutoPlayWaitForTheViewer() = playerTest {
        modes(credits = SkipMode.AUTO)
        sessionInfo { it.copy(nextEpisode = next.copy(autoplay = false)) }
        clipAt(44.0)
        assertEquals(upNext(progress = null), state.prompt)
        advance(20.seconds)
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun backOnTheCreditsCountdownDismissesUpNextToo() = playerTest(InputProfile.TV) {
        modes(credits = SkipMode.AUTO)
        sessionInfo { it.copy(nextEpisode = next) }
        clipAt(44.0)
        press(InputKey.BACK)
        assertNull(state.prompt)
        advance(20.seconds)
        assertEquals(0, session.nextEpisodes)
        assertEquals(0, host.closed)
        engineState { it.copy(positionSeconds = 60.0, eof = true, paused = true) }
        assertEquals(0, session.nextEpisodes, "dismissed, the end doesn't move on")
        assertEquals(upNext(progress = null), state.prompt, "it stops on the plain button")
    }

    @Test
    fun creditsOffKeepUpNextBeforeTheEnd() = playerTest {
        modes(credits = SkipMode.OFF)
        sessionInfo { it.copy(nextEpisode = next) }
        clipAt(45.0)
        assertNull(state.prompt)
        position(50.0)
        assertEquals(upNext(progress = 0f, secondsLeft = 10), state.prompt, "the countdown's length before the end")
        advance(10.seconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun withoutCreditsChaptersUpNextStartsTheCountdownBeforeTheEnd() = playerTest {
        sessionInfo { it.copy(nextEpisode = next.copy(countdownSeconds = 15)) }
        playing(position = 584.0, duration = 600.0)
        assertNull(state.prompt)
        position(585.0)
        assertEquals(0f, state.prompt?.progress)
        advance(7500.milliseconds)
        assertEquals(0.5f, state.prompt?.progress)
    }

    // Watch together

    @Test
    fun aGuestWhoMayNotControlSeesNoButton() = playerTest {
        modes(intros = SkipMode.AUTO)
        store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        clipAt(4.0)
        assertNull(state.prompt)
        advance(5.seconds)
        assertTrue(engine.seeks.isEmpty(), "the host skips; the guest follows its seek")
        dispatch(PlayerCommand.SkipSegment)
        assertTrue(engine.seeks.isEmpty())
        assertEquals("Only the host controls playback", state.osd)
    }

    @Test
    fun aGuestWhoMayControlGetsTheButtonButNoAutomaticSkip() = playerTest {
        modes(intros = SkipMode.AUTO)
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        clipAt(4.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt)
        advance(5.seconds)
        assertTrue(engine.seeks.isEmpty())
        dispatch(PlayerCommand.SkipSegment)
        assertEquals(12.0 to true, engine.seeks.single())
        assertEquals(listOf(12.0), watch.seeks, "the room hears the seek")
    }

    @Test
    fun theHostSkipsOnItsOwnAndTheRoomFollows() = playerTest {
        modes(intros = SkipMode.AUTO)
        val watch = FakeWatch(canControl = true, canChangeEpisode = true)
        store.attachWatch(watch)
        clipAt(4.0)
        advance(3.seconds)
        assertEquals(listOf(12.0), watch.seeks)
    }

    @Test
    fun aGuestSkippingCreditsToTheEndEndsTheRoomsMediaInsteadOfSeekingThisFile() = playerTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = false).also { it.routesControls = true }
        store.attachWatch(watch)
        sessionInfo { it.copy(segments = listOf(SkipSegment(SkipKind.CREDITS, 50.0, 60.0, toEnd = true))) }
        clipAt(52.0)
        assertEquals(skip(PromptKind.CREDITS, "Skip credits"), state.prompt)
        dispatch(PlayerCommand.SkipSegment)
        assertEquals(1, watch.ends, "the room's end, wherever this file's is")
        assertTrue(engine.seeks.isEmpty())
        assertTrue(watch.seeks.isEmpty())
    }

    @Test
    fun creditsToTheEndOfARoomAlreadyAtItsEndShowNoButton() = playerTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = false).also { it.routesControls = true }
        store.attachWatch(watch)
        sessionInfo { it.copy(segments = listOf(SkipSegment(SkipKind.CREDITS, 50.0, 60.0, toEnd = true))) }
        clipAt(52.0)
        assertNotNull(state.prompt)
        watch.state.update { it?.copy(atMediaEnd = true) }
        advance(Duration.ZERO)
        assertNull(state.prompt, "nothing left to skip")
        input(InputEvent.PointerMove)
        assertNull(state.prompt, "not with the controls either")
        dispatch(PlayerCommand.SkipSegment)
        assertEquals(0, watch.ends)
    }

    // The profile's delay and the server's markers

    @Test
    fun theCountdownLastsTheProfilesDelayAndItsFillMovesEvery200ms() = playerTest {
        sessionInfo { it.copy(skipping = SkipModes(intros = SkipMode.AUTO, autoSkipDelaySeconds = 5)) }
        clipAt(4.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro", progress = 0f, secondsLeft = 5), state.prompt)
        advance(100.milliseconds)
        assertEquals(0f, state.prompt?.progress, "no step yet")
        advance(100.milliseconds)
        assertEquals(0.04f, state.prompt?.progress, "one 200 ms step of 5 s")
        advance(4700.milliseconds)
        assertTrue(engine.seeks.isEmpty())
        advance(100.milliseconds)
        assertEquals(12.0 to true, engine.seeks.single())
    }

    @Test
    fun aDelayOfZeroShowsThePlainButtonAndNeverSkips() = playerTest {
        sessionInfo { it.copy(skipping = SkipModes(intros = SkipMode.AUTO, autoSkipDelaySeconds = 0)) }
        clipAt(4.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt)
        advance(30.seconds)
        assertTrue(engine.seeks.isEmpty())
    }

    @Test
    fun theServersMarkersReplaceTheChapters() = playerTest {
        sessionInfo { it.copy(segments = listOf(SkipSegment(SkipKind.INTRO, 20.0, 30.0))) }
        clipAt(6.0)
        assertNull(state.prompt, "the chapters' opening is no marker")
        position(20.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt)
        dispatch(PlayerCommand.SkipSegment)
        assertEquals(30.0 to true, engine.seeks.single())
    }

    @Test
    fun ofSegmentsHoldingThePositionTheFirstWhoseKindIsntOffIsOffered() = playerTest {
        sessionInfo { it.copy(segments = listOf(SkipSegment(SkipKind.INTRO, 10.0, 30.0), SkipSegment(SkipKind.CREDITS, 20.0, 40.0))) }
        clipAt(25.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt, "both hold the position: the first")
        modes(intros = SkipMode.OFF)
        assertEquals(skip(PromptKind.CREDITS, "Skip credits"), state.prompt, "the intro turned off: the next one holding it")
    }

    @Test
    fun noButtonBeforeTheFirstFrame() = playerTest {
        sessionInfo { it.copy(segments = listOf(SkipSegment(SkipKind.INTRO, 0.0, 30.0))) }
        engineState { it.copy(loaded = false, positionSeconds = 5.0, durationSeconds = 60.0, paused = false) }
        assertNull(state.prompt)
        engineState { it.copy(loaded = true) }
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt)
    }

    @Test
    fun upNextTakesThePlaceOfTheSkipButton() = playerTest {
        sessionInfo { it.copy(nextEpisode = next, segments = listOf(SkipSegment(SkipKind.INTRO, 40.0, 58.0))) }
        clipAt(45.0)
        assertEquals(skip(PromptKind.INTRO, "Skip intro"), state.prompt)
        // Up next comes up its countdown's 10 s before the end, still inside the segment.
        position(50.0)
        assertEquals(upNext(progress = 0f, secondsLeft = 10), state.prompt)
    }
}
