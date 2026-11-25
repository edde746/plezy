package com.edde746.plezy.input

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class KeymapTest {
    private val desktop = Keymap.forProfile(InputProfile.DESKTOP)
    private val tv = Keymap.forProfile(InputProfile.TV)
    private val touch = Keymap.forProfile(InputProfile.TOUCH)

    private val playing = InputContext()

    @Test
    fun desktopPointer() {
        assertEquals(PlayerCommand.TogglePause, desktop.click(0.2f, playing))
        assertEquals(PlayerCommand.ToggleControls, desktop.click(0.2f, InputContext(videoClick = VideoClickAction.CONTROLS)))
        assertEquals(PlayerCommand.CloseMenu, desktop.click(0.2f, InputContext(menuOpen = true)))
        assertNull(desktop.click(0.2f, InputContext(errorShown = true)))
        assertEquals(PlayerCommand.ToggleFullscreen, desktop.doubleClick(0.9f, playing))
    }

    @Test
    fun aRemoteHasNoPointer() {
        assertNull(tv.click(0.5f, playing))
        assertNull(tv.doubleClick(0.5f, playing))
    }

    /** A mouse on a phone or tablet: a click shows or hides the controls; fingers are the store's own. */
    @Test
    fun touchMouseClicks() {
        assertEquals(PlayerCommand.ToggleControls, touch.click(0.5f, playing))
        assertEquals(PlayerCommand.CloseMenu, touch.click(0.5f, InputContext(menuOpen = true)))
        assertNull(touch.doubleClick(0.2f, playing))
    }
}
