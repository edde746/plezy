package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.strings.Locales
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** Up next's prompt button before the end of an episode (the credits' start: SkipTest). */
class UpNextTest {
    private val next = NextEpisode(title = "Chapter Two", subtitle = "S1E2")

    private fun upNext(progress: Float?, secondsLeft: Int? = null, withControls: Boolean = false) =
        PlayerPrompt(PromptKind.UP_NEXT, "S1E2 · ", "Chapter Two", progress, secondsLeft, PlayerCommand.NextEpisode, withControls)

    @Test
    fun itComesUpTheCountdownBeforeTheEndAndCountsDownPlayedTime() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next) }
        playing(position = 589.0, duration = 600.0)
        assertNull(state.prompt)
        assertEquals(EpisodeButtons(previous = true, next = true, previousRestarts = true), state.episodes)

        position(590.0)
        assertEquals(upNext(progress = 0f, secondsLeft = 10), state.prompt)
        assertEquals(EpisodeButtons(previous = true, next = true, previousRestarts = true), state.episodes, "the controls' next stays beside it")
        advance(5.seconds)
        assertEquals(0.5f, state.prompt?.progress)

        // Paused by something else than the viewer (the room's host, the system): the countdown waits.
        engineState { it.copy(paused = true) }
        advance(60.seconds)
        assertEquals(0.5f, state.prompt?.progress)
        engineState { it.copy(paused = false) }
        advance(4900.milliseconds)
        assertEquals(0, session.nextEpisodes)
        advance(100.milliseconds)
        assertEquals(1, session.nextEpisodes)
        assertNull(state.prompt)
        advance(60.seconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun showingTheControlsNeverStopsTheCountdown() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        playing(position = 590.0, duration = 600.0)
        advance(2.seconds)
        input(InputEvent.PointerMove)
        assertTrue(state.controlsVisible)
        assertEquals(upNext(progress = 0.2f, secondsLeft = 8), state.prompt, "the mouse moving brings the controls up beside it")
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        dispatch(PlayerCommand.CloseMenu)
        advance(7900.milliseconds)
        assertEquals(0, session.nextEpisodes)
        advance(100.milliseconds)
        assertEquals(1, session.nextEpisodes, "it played the next episode on time")
    }

    @Test
    fun withAutoPlayTheEndOfTheFileAlwaysMovesOn() = playerTest {
        sessionInfo { it.copy(nextEpisode = next.copy(countdownSeconds = 30)) }
        playing(position = 590.0, duration = 600.0)
        input(InputEvent.PointerMove)
        dispatch(PlayerCommand.TogglePause)
        dispatch(PlayerCommand.TogglePause)
        engineState { it.copy(positionSeconds = 600.0, eof = true) }
        assertEquals(1, session.nextEpisodes, "the countdown's 30 s outlast the file: its end plays the next episode")
    }

    @Test
    fun aTapNeverStopsItOnATouchScreen() = playerTest(InputProfile.TOUCH) {
        sessionInfo { it.copy(nextEpisode = next) }
        playing(position = 590.0, duration = 600.0)
        tap(CENTRE)
        assertEquals(0f, state.prompt?.progress)
        advance(10.seconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun onTvRemotePressesAndFocusLeaveItCountingAndSelectPlaysTheNextEpisode() = playerTest(InputProfile.TV) {
        sessionInfo { it.copy(nextEpisode = next.copy(countdownSeconds = 30)) }
        playing(position = 575.0, duration = 600.0)
        advance(5.seconds)
        assertTrue(!state.controlsVisible)
        assertTrue(press(InputKey.UP), "Up brings the controls up")
        input(InputEvent.FocusMove)
        assertEquals(upNext(progress = 0.2f, secondsLeft = 20), state.prompt, "25 s, what was left to play")
        dispatch(PlayerCommand.HideControls)
        assertTrue(press(InputKey.SELECT))
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun dismissedItStaysAwayAndTheEndStopsOnThePlainButton() = playerTest {
        sessionInfo { it.copy(nextEpisode = next.copy(countdownSeconds = 30)) }
        playing(position = 575.0, duration = 600.0)
        advance(5.seconds)
        dispatch(PlayerCommand.Back)
        assertNull(state.prompt)
        assertEquals(0, host.closed, "Back doesn't leave the player while the button shows")
        dispatch(PlayerCommand.ShowControls)
        assertNull(state.prompt, "dismissed: not even with the controls")
        advance(60.seconds)
        engineState { it.copy(positionSeconds = 600.0, eof = true) }
        assertEquals(0, session.nextEpisodes, "dismissed, the end doesn't move on")
        assertEquals(PlaybackStatus.ENDED, state.status)
        assertEquals(upNext(progress = null), state.prompt, "the end stops on the plain button")
        advance(60.seconds)
        assertEquals(0, session.nextEpisodes)
        assertEquals(upNext(progress = null, withControls = true), state.prompt)

        // Back before its start and through it again, in the same file: plain.
        engineState { it.copy(positionSeconds = 300.0, eof = false) }
        assertNull(state.prompt)
        position(580.0)
        assertEquals(upNext(progress = null), state.prompt)
        dispatch(state.prompt!!.command)
        assertEquals(1, session.nextEpisodes, "pressed, the plain button plays the next episode")
    }

    @Test
    fun theNextFileCountsDownAgain() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        playing(position = 590.0, duration = 600.0)
        dispatch(PlayerCommand.Back)
        assertNull(state.prompt)
        // The next file: unloaded, then playing to its end.
        engineState { it.copy(loaded = false, positionSeconds = 0.0) }
        playing(position = 590.0, duration = 600.0)
        assertEquals(0f, state.prompt?.progress)
    }

    /** At the end of the file up next stands for the finished video: one Back leaves the player. */
    @Test
    fun onTvOneBackLeavesThePlayerFromUpNextAtTheEnd() = playerTest(InputProfile.TV) {
        sessionInfo { it.copy(nextEpisode = next.copy(autoplay = false)) }
        playing(position = 575.0, duration = 600.0)
        engineState { it.copy(positionSeconds = 600.0, eof = true) }
        assertEquals(PlaybackStatus.ENDED, state.status)
        assertNotNull(state.prompt)
        press(InputKey.BACK)
        assertEquals(1, host.closed)
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun theEndOfTheFilePlaysTheNextEpisodeAtOnce() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        playing(position = 595.0, duration = 600.0)
        assertNotNull(state.prompt?.progress)
        engineState { it.copy(eof = true) }
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun pressingItPlaysTheNextEpisode() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        playing(position = 595.0, duration = 600.0)
        dispatch(state.prompt!!.command)
        assertEquals(1, session.nextEpisodes)
        assertNull(state.prompt)
    }

    @Test
    fun enterPressesItOnTheDesktop() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        playing(position = 595.0, duration = 600.0)
        assertTrue(press(InputKey.SELECT))
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun theCountdownIsTheProfilesSetting() = playerTest {
        sessionInfo { it.copy(nextEpisode = next.copy(countdownSeconds = 30)) }
        playing(position = 569.0, duration = 600.0)
        assertNull(state.prompt)
        position(570.0)
        assertEquals(0f, state.prompt?.progress)
        advance(15.seconds)
        assertEquals(0.5f, state.prompt?.progress)
        advance(15.seconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun startedLateItCountsDownNoLongerThanWhatIsLeft() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        playing(position = 597.0, duration = 600.0)
        advance(2900.milliseconds)
        assertEquals(0, session.nextEpisodes)
        advance(100.milliseconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun aZeroCountdownPlaysTheNextEpisodeWhenTheVideoEnds() = playerTest {
        sessionInfo { it.copy(nextEpisode = next.copy(countdownSeconds = 0)) }
        playing(position = 599.5, duration = 600.0)
        assertNull(state.prompt)
        assertEquals(0, session.nextEpisodes)
        engineState { it.copy(eof = true) }
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun withoutANextEpisodeThereIsNoPrompt() = playerTest {
        playing(position = 590.0, duration = 600.0)
        assertNull(state.prompt)
        engineState { it.copy(eof = true) }
        assertEquals(0, session.nextEpisodes)
        assertEquals(PlaybackStatus.ENDED, state.status)
    }

    @Test
    fun playAtTheEndStartsTheVideoOver() = playerTest {
        playing(position = 590.0, duration = 600.0)
        // mpv reports only when the test says: at the end it keeps the last frame, paused, and ignores a bare unpause.
        engine.echo = false
        engineState { it.copy(positionSeconds = 600.0, paused = true, eof = true) }
        assertEquals(PlaybackStatus.ENDED, state.status)

        dispatch(PlayerCommand.TogglePause)
        assertEquals(0.0 to true, engine.seeks.last())
        assertEquals(false, engine.paused.last())
        engineState { it.copy(positionSeconds = 0.0, paused = false, eof = false) }
        assertEquals(PlaybackStatus.PLAYING, state.status)

        engineState { it.copy(positionSeconds = 600.0, paused = true, eof = true) }
        dispatch(PlayerCommand.Play)
        assertEquals(2, engine.seeks.count { it == 0.0 to true }, "Play (also the OS's) starts it over too")
    }

    @Test
    fun withoutAutoplayTheEndOffersTheNextEpisodeWithoutACountdown() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(autoplay = false)) }
        playing(position = 590.0, duration = 600.0)
        assertNull(state.prompt)
        engineState { it.copy(positionSeconds = 600.0, eof = true) }
        assertNotNull(state.prompt, "the end offers the next episode")
        advance(60.seconds)
        assertEquals(0, session.nextEpisodes, "it waits to be asked")
        assertEquals(PlaybackStatus.ENDED, state.status)
        assertEquals(true, state.episodes?.next)
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun upNextWaitsWhileTheSleepTimerAsks() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(autoplay = false)) }
        playing(position = 100.0, duration = 600.0)
        dispatch(PlayerCommand.SetSleepTimer(5))
        advance(5.minutes)
        assertNotNull(state.stillWatching)
        engineState { it.copy(positionSeconds = 600.0, eof = true) }
        assertNull(state.prompt, "still watching is up")
    }

    // The label

    @Test
    fun theLabelSaysItPlaysTheNextEpisodeWithItsCodeAndNameOrTheCodeAlone() {
        val named = PlayerStates.upNext(next, progress = null, secondsLeft = null, withControls = false)
        assertEquals("S1E2 · ", named.lead, "the code and the separator, nothing isolated")
        assertEquals("Chapter Two", named.text)
        assertEquals("Play the next episode: S1E2 · \u2068Chapter Two\u2069", named.label, "the name isolated after the lead")
        // The session gives an episode without a name its code as the title, and no subtitle.
        val unnamed = PlayerStates.upNext(NextEpisode(title = "S1E2"), progress = null, secondsLeft = null, withControls = false)
        assertNull(unnamed.lead)
        assertEquals("Play the next episode: S1E2", unnamed.label)
    }

    @Test
    fun theCountdownSaysTheSecondsLeftUntilTheViewerActs() = playerTest {
        sessionInfo { it.copy(nextEpisode = next) }
        playing(position = 590.0, duration = 600.0)
        assertEquals("Automatically in 10 seconds", state.prompt?.countdown)
        advance(8500.milliseconds)
        assertEquals("Automatically in 2 seconds", state.prompt?.countdown, "rounded up")
        advance(500.milliseconds)
        assertEquals("Automatically in 1 second", state.prompt?.countdown)
    }

    @Test
    fun inEveryLanguageTheCodeLeadsSoCuttingTheNameShortNeverCutsIt() {
        try {
            for (locale in Locales.available) {
                T.locale = locale
                val prompt = PlayerStates.upNext(next, progress = null, secondsLeft = null, withControls = false)
                assertTrue(prompt.label.contains(T.session.episodeTitle("S1E2", isolate("Chapter Two"))), locale)
                // Arabic's template starts with a right-to-left mark, which anchors the line's direction.
                assertTrue(prompt.lead.orEmpty().removePrefix("\u200F").startsWith("S1E2"), locale)
            }
        } finally {
            T.locale = "en"
        }
    }
}
