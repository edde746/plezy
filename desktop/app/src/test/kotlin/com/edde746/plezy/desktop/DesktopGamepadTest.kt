package com.edde746.plezy.desktop

import androidx.compose.ui.input.key.Key
import com.edde746.plezy.input.GamepadAction
import com.edde746.plezy.input.InputKey
import java.awt.event.KeyEvent
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DesktopGamepadTest {
    @Test
    fun aIsEnterDownWhileHeld() {
        assertEquals(listOf(GamepadKeyStroke(KeyEvent.KEY_PRESSED, KeyEvent.VK_ENTER, '\n')), gamepadKeyStrokes(GamepadAction.KeyDown(InputKey.SELECT)))
        assertEquals(listOf(GamepadKeyStroke(KeyEvent.KEY_RELEASED, KeyEvent.VK_ENTER, '\n')), gamepadKeyStrokes(GamepadAction.KeyUp(InputKey.SELECT)))
    }

    @Test
    fun theDirectionsAreArrowsAndXIsTheContextMenuKey() {
        val down = listOf(InputKey.UP, InputKey.DOWN, InputKey.LEFT, InputKey.RIGHT, InputKey.MENU).map { gamepadKeyStrokes(GamepadAction.KeyDown(it, repeat = true)).single() }
        assertEquals(listOf(KeyEvent.VK_UP, KeyEvent.VK_DOWN, KeyEvent.VK_LEFT, KeyEvent.VK_RIGHT, KeyEvent.VK_CONTEXT_MENU), down.map { it.code })
        assertEquals(setOf(KeyEvent.KEY_PRESSED), down.map { it.id }.toSet())
    }

    @Test
    fun bIsComposesBackKeyNotEscape() {
        val strokes = gamepadKeyStrokes(GamepadAction.Back)
        assertEquals(listOf(KeyEvent.KEY_PRESSED, KeyEvent.KEY_RELEASED), strokes.map { it.id })
        assertEquals(setOf(Key.Back), strokes.map { Key(it.code) }.toSet())
    }

    @Test
    fun theShouldersAreComposesL1AndR1() {
        assertEquals(setOf(Key.ButtonL1), gamepadKeyStrokes(GamepadAction.Tab(next = false)).map { Key(it.code) }.toSet())
        assertEquals(setOf(Key.ButtonR1), gamepadKeyStrokes(GamepadAction.Tab(next = true)).map { Key(it.code) }.toSet())
        assertEquals(2, gamepadKeyStrokes(GamepadAction.Tab(next = true)).size)
    }

    @Test
    fun showingFocusIsNoKey() {
        assertEquals(emptyList(), gamepadKeyStrokes(GamepadAction.NonPointerInput))
    }

    @Test
    fun theSystemsArrowsEnterEscapeAndMenuKeyGoToTheDuplicateGuard() {
        assertEquals(InputKey.UP, guardedKey(KeyEvent.VK_KP_UP))
        assertEquals(InputKey.RIGHT, guardedKey(KeyEvent.VK_RIGHT))
        assertEquals(InputKey.SELECT, guardedKey(KeyEvent.VK_ENTER))
        assertEquals(InputKey.ESCAPE, guardedKey(KeyEvent.VK_ESCAPE))
        assertEquals(InputKey.MENU, guardedKey(KeyEvent.VK_CONTEXT_MENU))
        assertNull(guardedKey(KeyEvent.VK_SPACE))
    }
}
