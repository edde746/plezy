package com.edde746.plezy.ui.focus

import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.click
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Focus shows (keyboard mode) only for a key that asks to move by focus, and hides again for the mouse: a keyboard's
 * Enter and Escape act on what has focus without showing it, and the video's own arrows don't show it either.
 */
@OptIn(ExperimentalTestApi::class)
class InputModeTest {
    private val visibility = FocusVisibility(false)
    private val first = FocusRequester()
    private val video = FocusRequester()
    private var clicks = 0

    @Test
    fun aPhysicalKeyboardEnterOrEscapeDoesNotShowFocus() = runComposeUiTest {
        app()
        onRoot().performKeyInput { pressKey(Key.Enter) }
        onRoot().performKeyInput { pressKey(Key.NumPadEnter) }
        onRoot().performKeyInput { pressKey(Key.Escape) }
        assertFalse(visibility.visible)
    }

    @Test
    fun anArrowKeyStillShowsFocus() = runComposeUiTest {
        app()
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        assertTrue(visibility.visible)
    }

    @Test
    fun tabStillShowsFocus() = runComposeUiTest {
        app()
        onRoot().performKeyInput { pressKey(Key.Tab) }
        assertTrue(visibility.visible)
    }

    @Test
    fun aKeyboardEnterOnTvShowsFocus() = runComposeUiTest {
        app(tv = true)
        onRoot().performKeyInput { pressKey(Key.Enter) }
        assertTrue(visibility.visible)
    }

    @Test
    fun onlyKeyDownCounts() = runComposeUiTest {
        app()
        onRoot().performKeyInput { keyDown(Key.DirectionDown) }
        assertTrue(visibility.visible)
        onRoot().performMouseInput { click(Offset(40f, 40f)) }
        onRoot().performKeyInput { keyUp(Key.DirectionDown) }
        assertFalse(visibility.visible)
    }

    @Test
    fun anElementThatOwnsTheArrowsKeepsThemFromShowingFocus() = runComposeUiTest {
        app()
        runOnIdle { video.requestFocus() }
        onRoot().performKeyInput { pressKey(Key.DirectionLeft) }
        onRoot().performKeyInput { pressKey(Key.DirectionUp) }
        assertFalse(visibility.visible)
    }

    @Test
    fun anElementCanOwnOneAxisAndLeaveTheOtherToFocus() = runComposeUiTest {
        app(ownsVertical = false)
        runOnIdle { video.requestFocus() }
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        assertFalse(visibility.visible)
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        assertTrue(visibility.visible)
    }

    @Test
    fun theMouseMovingOrPressingHidesFocusAgain() = runComposeUiTest {
        app()
        onRoot().performMouseInput { moveTo(Offset(5f, 5f)) }
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        assertTrue(visibility.visible)
        onRoot().performMouseInput { moveTo(Offset(40f, 40f)) }
        assertFalse(visibility.visible)
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        assertTrue(visibility.visible)
        onRoot().performMouseInput { click(Offset(40f, 40f)) }
        assertFalse(visibility.visible)
    }

    /** The press that hides focus still clicks once let go, frames later: the cursor's change doesn't cancel it. */
    @Test
    fun aPressThatHidesFocusStillClicks() = runComposeUiTest {
        app()
        onRoot().performMouseInput { moveTo(Offset(20f, 20f)) }
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        assertTrue(visibility.visible)
        onRoot().performMouseInput { press() }
        waitForIdle()
        assertFalse(visibility.visible)
        onRoot().performMouseInput { release() }
        waitForIdle()
        assertEquals(1, clicks)
    }

    @Test
    fun inputTheAppReadsItselfShowsFocus() = runComposeUiTest {
        app()
        runOnIdle { visibility.reportNonPointerInput() }
        assertTrue(visibility.visible)
    }

    private fun ComposeUiTest.app(tv: Boolean = false, ownsVertical: Boolean = true) {
        setContent {
            PlezyTheme {
                CompositionLocalProvider(LocalFocusVisibility provides visibility) {
                    Column(Modifier.size(400.dp).trackFocusVisibility(visibility, tv)) {
                        PlezyButton("First", { clicks++ }, Modifier.focusRequester(first))
                        // The player's video: the element itself takes focus.
                        Box(
                            Modifier.size(40.dp)
                                .ownsArrows { it == Key.DirectionLeft || it == Key.DirectionRight || (ownsVertical && (it == Key.DirectionUp || it == Key.DirectionDown)) }
                                .focusRequester(video)
                                .focusable(),
                        )
                    }
                }
            }
        }
        runOnIdle { first.requestFocus() }
    }
}
