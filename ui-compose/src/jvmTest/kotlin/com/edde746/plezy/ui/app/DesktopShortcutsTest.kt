package com.edde746.plezy.ui.app

import androidx.compose.ui.input.key.Key
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DesktopShortcutsTest {
    private fun shortcut(
        key: Key,
        ctrl: Boolean = false,
        meta: Boolean = false,
        shift: Boolean = false,
        alt: Boolean = false,
        repeat: Boolean = false,
        tv: Boolean = false,
    ) = desktopShortcut(key, ctrl, meta, shift, alt, repeat, tv)

    @Test
    fun `F11 is fullscreen with or without modifiers and in TV mode`() {
        assertEquals(DesktopShortcut.FULLSCREEN, shortcut(Key.F11))
        assertEquals(DesktopShortcut.FULLSCREEN, shortcut(Key.F11, ctrl = true, shift = true))
        assertEquals(DesktopShortcut.FULLSCREEN, shortcut(Key.F11, tv = true))
    }

    @Test
    fun `Ctrl F is search but never with Meta`() {
        assertEquals(DesktopShortcut.SEARCH, shortcut(Key.F, ctrl = true))
        assertEquals(DesktopShortcut.SEARCH, shortcut(Key.F, ctrl = true, tv = true))
        assertNull(shortcut(Key.F))
        assertNull(shortcut(Key.F, ctrl = true, meta = true))
        assertNull(shortcut(Key.F, meta = true))
    }

    @Test
    fun `Ctrl R refreshes only without Shift Alt or Meta and not in TV mode`() {
        assertEquals(DesktopShortcut.REFRESH, shortcut(Key.R, ctrl = true))
        assertNull(shortcut(Key.R, ctrl = true, shift = true))
        assertNull(shortcut(Key.R, ctrl = true, alt = true))
        assertNull(shortcut(Key.R, ctrl = true, meta = true))
        assertNull(shortcut(Key.R, ctrl = true, tv = true))
        assertNull(shortcut(Key.R))
    }

    @Test
    fun `Ctrl comma opens settings but not with Meta or in TV mode`() {
        assertEquals(DesktopShortcut.SETTINGS, shortcut(Key.Comma, ctrl = true))
        assertEquals(DesktopShortcut.SETTINGS, shortcut(Key.Comma, ctrl = true, shift = true))
        assertNull(shortcut(Key.Comma, ctrl = true, meta = true))
        assertNull(shortcut(Key.Comma, ctrl = true, tv = true))
        assertNull(shortcut(Key.Comma))
    }

    @Test
    fun `a key held down repeats no shortcut`() {
        assertNull(shortcut(Key.F11, repeat = true))
        assertNull(shortcut(Key.F, ctrl = true, repeat = true))
        assertNull(shortcut(Key.R, ctrl = true, repeat = true))
        assertNull(shortcut(Key.Comma, ctrl = true, repeat = true))
    }

    @Test
    fun `the mouse back button closes an open dialog or sheet before any screen`() {
        assertEquals(MouseBack.OVERLAY, mouseBack(overlayOpen = true, stackSize = 3))
        assertEquals(MouseBack.OVERLAY, mouseBack(overlayOpen = true, stackSize = 1))
    }

    @Test
    fun `the mouse back button closes the top screen and nothing at a destinations root`() {
        assertEquals(MouseBack.SCREEN, mouseBack(overlayOpen = false, stackSize = 2))
        assertNull(mouseBack(overlayOpen = false, stackSize = 1))
    }
}
