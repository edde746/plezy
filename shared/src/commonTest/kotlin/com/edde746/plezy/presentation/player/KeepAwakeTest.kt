package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.PlaybackFailure
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** When the display stays awake ([PlayerUiState.keepAwake]): the one rule every platform's display-sleep assertion follows. */
class KeepAwakeTest {
    @Test
    fun theDisplayStaysAwakeWhileTheVideoPlaysOrLoadsUnpaused() = playerTest {
        assertTrue(state.keepAwake, "opening")
        sessionInfo { it.copy(resolving = true) }
        assertTrue(state.keepAwake, "resolving")
        sessionInfo { it.copy(resolving = false) }
        playing()
        assertTrue(state.keepAwake, "playing")
        engineState { it.copy(buffering = true) }
        assertTrue(state.keepAwake, "buffering")
        engineState { it.copy(buffering = false) }
        dispatch(PlayerCommand.Pause)
        assertFalse(state.keepAwake, "paused")
        engineState { it.copy(buffering = true) }
        assertFalse(state.keepAwake, "buffering while paused")
        dispatch(PlayerCommand.Play)
        assertTrue(state.keepAwake, "playing again")
    }

    @Test
    fun theDisplayMaySleepAtTheEndOnAFailureAndWhileAFileOpensPaused() = playerTest {
        playing()
        engineState { it.copy(eof = true) }
        assertFalse(state.keepAwake, "ended")
        engineState { it.copy(eof = false) }
        assertTrue(state.keepAwake)
        sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("loading failed", httpStatus = 403))) }
        assertFalse(state.keepAwake, "failed")
        sessionInfo { it.copy(failure = null) }
        engineState { it.copy(loaded = false, paused = true) }
        assertFalse(state.keepAwake, "a file opening paused")
    }

    @Test
    fun outOfSightTheDisplayMaySleepUnlessThePlayerIsInPictureInPicture() = playerTest {
        playing()
        store.onVisibleChanged(false)
        assertFalse(state.keepAwake, "minimized, hidden or in the background")
        store.onPictureInPictureChanged(true)
        assertTrue(state.keepAwake, "in picture in picture")
        store.onPictureInPictureChanged(false)
        assertFalse(state.keepAwake)
        store.onVisibleChanged(true)
        assertTrue(state.keepAwake, "back on screen")
    }

    @Test
    fun closingThePlayerMidPlayLetsTheDisplaySleep() = playerTest {
        playing()
        assertTrue(state.keepAwake)
        store.release()
        assertFalse(state.keepAwake)
    }
}
