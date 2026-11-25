package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** How the controls start, Back's stages, and the window and rotation buttons. */
class ChromeStagesTest {
    @Test
    fun onTvTheControlsStartHiddenThroughTheLoadingUntilAPressRaisesThem() = playerTest(InputProfile.TV) {
        assertTrue(state.chromeHiddenAtStart)
        assertEquals(PlaybackStatus.OPENING, state.status)
        assertFalse(state.controlsVisible)
        playing()
        assertFalse(state.controlsVisible)
        engineState { it.copy(buffering = true) }
        engineState { it.copy(buffering = false) }
        assertFalse(state.controlsVisible)

        press(InputKey.DOWN)
        assertTrue(state.controlsVisible)
    }

    @Test
    fun withAPointerOrTouchTheControlsStartUp() = playerTest(InputProfile.TOUCH) {
        assertFalse(state.chromeHiddenAtStart)
        assertTrue(state.controlsVisible)
    }

    @Test
    fun aPhonesBackLeavesThePlayerWithTheControlsUp() = playerTest(InputProfile.TOUCH) {
        playing()
        assertTrue(state.controlsVisible)
        dispatch(PlayerCommand.Back)
        assertEquals(1, host.closed)
    }

    @Test
    fun aPhonesBackClosesTheMenuFirst() = playerTest(InputProfile.TOUCH) {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        dispatch(PlayerCommand.Back)
        assertNull(state.menu)
        assertEquals(0, host.closed)
        dispatch(PlayerCommand.Back)
        assertEquals(1, host.closed)
    }

    @Test
    fun elsewhereBackHidesTheControlsBeforeItLeaves() = playerTest {
        playing()
        dispatch(PlayerCommand.Back)
        assertFalse(state.controlsVisible)
        assertEquals(0, host.closed)
        dispatch(PlayerCommand.Back)
        assertEquals(1, host.closed)
    }

    @Test
    fun elsewhereBackLeavesTheOpeningPlayerAtOnceTheControlsUp() = playerTest(InputProfile.DESKTOP) {
        assertEquals(PlaybackStatus.OPENING, state.status)
        assertTrue(state.controlsVisible)
        press(InputKey.ESCAPE)
        assertEquals(1, host.closed)
    }

    @Test
    fun theRotationLockIsAPhoneButtonKeptAsASetting() = playerTest(InputProfile.TOUCH) {
        assertEquals(true, state.rotationLocked)
        dispatch(PlayerCommand.ToggleRotationLock)
        assertEquals(false, state.rotationLocked)
        assertFalse(preferences.choices.value.rotationLocked)
        choices { it.copy(rotationLocked = true) }
        assertEquals(true, state.rotationLocked)
    }

    @Test
    fun noRotationLockWithAMouseOrARemote() = playerTest {
        assertNull(state.rotationLocked)
        dispatch(PlayerCommand.ToggleRotationLock)
        assertTrue(preferences.choices.value.rotationLocked)
    }

    @Test
    fun alwaysOnTopComesBackAsThePlayerOpensAndTogglesWhereWindowsCan() = playerTest {
        assertNull(state.alwaysOnTop)
        host.keepsOnTop = true
        choices { it.copy(alwaysOnTop = true) }
        assertEquals(listOf(true), host.onTopRequests)
        assertEquals(true, state.alwaysOnTop)

        dispatch(PlayerCommand.ToggleAlwaysOnTop)
        assertEquals(listOf(true, false), host.onTopRequests)
        assertEquals(false, state.alwaysOnTop)
        assertFalse(preferences.choices.value.alwaysOnTop)
    }

    @Test
    fun noAlwaysOnTopWhereWindowsCant() = playerTest {
        dispatch(PlayerCommand.ToggleAlwaysOnTop)
        assertNull(state.alwaysOnTop)
        assertTrue(host.onTopRequests.isEmpty())
    }
}
