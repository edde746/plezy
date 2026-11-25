package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class ErrorFlowTest {
    @Test
    fun theCardOffersRetryThenClose() = playerTest {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO))
        sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("loading failed", httpStatus = 403))) }
        assertEquals(
            ErrorState(
                title = "Can't play this stream",
                message = "The stream link has expired.",
                buttons = listOf(
                    ErrorButton(ErrorAction.RETRY, T.player.error.retry, PlayerCommand.Retry, primary = true),
                    ErrorButton(ErrorAction.CLOSE, T.player.error.close, PlayerCommand.Close, primary = false),
                ),
            ),
            state.error,
        )
        assertEquals(PlaybackStatus.FAILED, state.status)
        assertNull(state.menu)

        dispatch(PlayerCommand.Retry)
        assertEquals(1, session.retries)
        sessionInfo { it.copy(failure = null, resolving = true) }
        assertNull(state.error)
        assertEquals(PlaybackStatus.RESOLVING, state.status)
        assertEquals("Preparing stream…", state.loadingText)

        // The retry failed too: Retry stays the card's primary button.
        sessionInfo { it.copy(resolving = false, failure = PlaybackFailure.Engine(EngineError("loading failed", kind = EngineErrorKind.OPEN))) }
        assertEquals("The stream couldn't be opened.", state.error?.message)
        assertEquals(listOf(ErrorAction.RETRY to true, ErrorAction.CLOSE to false), state.errorButtons)
    }

    /** mpv's error text is English: the player words an engine error in the interface language; mpv's goes to the log. */
    @Test
    fun anEngineErrorIsWordedInTheInterfaceLanguage() = playerTest {
        playing()
        try {
            T.locale = "ru"
            sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("loading failed"))) }
            val message = assertNotNull(state.error).message
            assertFalse(message.contains(Regex("[A-Za-z]")), message)
        } finally {
            T.locale = "en"
        }
    }

    /**
     * Over the error the controls are the title and Back alone: the failure closes the menu, the playback's controls
     * go, and nothing opens them again (the menus' buttons, a remote's Menu) until Retry takes the error away and brings
     * the controls back.
     */
    @Test
    fun theErrorLeavesTheTitleAndBackAloneUntilARetry() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        assertTrue(state.showsPlaybackControls)

        sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("loading failed"))) }
        assertTrue(state.controlsVisible, "the title and Back stay")
        assertFalse(state.showsPlaybackControls)
        assertNull(state.menu)
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        dispatch(PlayerCommand.OpenSubtitleLanguage("en"))
        press(InputKey.MENU)
        advance(30.seconds)
        assertNull(state.menu, "no menu opens over the error")
        assertTrue(state.controlsVisible)
        assertFalse(state.showsPlaybackControls)

        dispatch(PlayerCommand.Retry)
        sessionInfo { it.copy(failure = null, resolving = true) }
        assertTrue(state.controlsVisible)
        assertTrue(state.showsPlaybackControls, "Retry brings the controls back")
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        assertEquals(PlayerMenu.SUBTITLES, state.menu)

        sessionInfo { it.copy(resolving = false, failure = PlaybackFailure.Engine(EngineError("loading failed"))) }
        assertFalse(state.showsPlaybackControls)
        assertNull(state.menu)
        dispatch(PlayerCommand.Retry)
        sessionInfo { it.copy(failure = null) }
        assertTrue(state.showsPlaybackControls, "the next retry brings them back")
        playing()
        advance(5.seconds)
        assertFalse(state.controlsVisible, "and they hide again as it plays")
    }

    /**
     * An error in an episode's credits takes the controls the same way, with what goes beside them: up next's button
     * and the subtitles' lift above the bottom controls.
     */
    @Test
    fun anErrorWhilePlayingTakesThePlaybackControlsAndUpNext() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = NextEpisode(title = "Chapter Two", subtitle = "S1E2")) }
        playing(position = 590.0, duration = 600.0)
        store.onControlsHeightChanged(0.2)
        assertEquals(PromptKind.UP_NEXT, state.prompt?.kind)
        assertEquals(0.2, engine.subtitleLifts.last())

        sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("stream ended", httpStatus = 410))) }
        assertTrue(state.controlsVisible)
        assertFalse(state.showsPlaybackControls)
        assertNull(state.prompt, "no up next over the error")
        assertEquals(0.0, engine.subtitleLifts.last(), "nothing to lift the subtitles over")
    }

    /**
     * A live playback that fails ends the same way: its live label (the red dot, LIVE and the time played) goes with the
     * transport in the bottom bar, and the title and Back stay over the error, which no menu opens over.
     */
    @Test
    fun aLivePlaybackThatFailsLeavesTheTitleAndBackAlone() = playerTest(InputProfile.TV) {
        sessionInfo { it.copy(live = true) }
        playing(position = 30.0, duration = 36.0)
        store.onControlsHeightChanged(0.2)
        dispatch(PlayerCommand.ShowControls)
        assertEquals(PlaybackMode.LIVE, state.mode)
        assertTrue(state.showsPlaybackControls, "the live label beside play/pause")
        assertEquals(0.2, engine.subtitleLifts.last())

        sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("stream ended", httpStatus = 404))) }
        assertEquals(PlaybackStatus.FAILED, state.status)
        assertTrue(state.controlsVisible, "the title and Back stay")
        assertFalse(state.showsPlaybackControls, "no live label, transport or menus")
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        advance(30.seconds)
        assertNull(state.menu, "no menu opens over the error")
        assertTrue(state.controlsVisible)
        assertFalse(state.showsPlaybackControls)
        assertEquals(0.0, engine.subtitleLifts.last(), "nothing to lift the subtitles over")
    }

    @Test
    fun eachFailureIsWordedAndOffersRetry() = playerTest {
        playing()
        sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("HTTP error 404", httpStatus = 404))) }
        assertEquals("The stream is no longer available.", state.error?.message)
        assertEquals(listOf(ErrorAction.RETRY to true, ErrorAction.CLOSE to false), state.errorButtons)
        dispatch(PlayerCommand.Retry)
        sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("HTTP error 502", httpStatus = 502))) }
        assertEquals("The server responded with HTTP 502.", state.error?.message)
        assertEquals(ErrorAction.RETRY, state.error?.primary?.action)
    }

    @Test
    fun retryDoesNothingWithoutAnError() = playerTest {
        playing()
        dispatch(PlayerCommand.Retry)
        assertEquals(0, session.retries)
    }

    @Test
    fun loadingStatesAreTold() = playerTest {
        sessionInfo { it.copy(resolving = true) }
        assertEquals(PlaybackStatus.RESOLVING, state.status)
        assertEquals("Preparing stream…", state.loadingText)
        sessionInfo { it.copy(resolving = false) }
        assertEquals(PlaybackStatus.OPENING, state.status)
        assertEquals("Opening…", state.loadingText)
        playing()
        assertEquals(PlaybackStatus.PLAYING, state.status)
        assertNull(state.loadingText)
        engineState { it.copy(buffering = true) }
        advance(1.seconds)
        assertEquals(PlaybackStatus.BUFFERING, state.status)
        assertEquals("Buffering…", state.loadingText)
        assertTrue(state.status.isLoading)
        dispatch(PlayerCommand.Pause)
        assertEquals(PlaybackStatus.PAUSED, state.status)
        assertNull(state.loadingText)
        assertEquals("Play", state.playPauseLabel)
    }

    /** The card's buttons by action, each with whether it is the primary one. */
    private val PlayerUiState.errorButtons: List<Pair<ErrorAction, Boolean>>?
        get() = error?.buttons?.map { it.action to it.primary }
}
