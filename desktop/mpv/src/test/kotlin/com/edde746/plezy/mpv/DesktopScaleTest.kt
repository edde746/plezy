package com.edde746.plezy.mpv

import com.edde746.plezy.mpv.DesktopWindow.Companion.composeScale
import kotlin.test.Test
import kotlin.test.assertEquals

class DesktopScaleTest {
    /** Compose's factor times AWT's scale: what the app draws at in all. */
    private fun total(x11: Boolean, xftDpi: Int?, awtScale: Double): Double =
        composeScale(x11, xftDpi?.let { it / 96.0 }, awtScale) * awtScale

    /** Under X11 with AWT at 1, Compose draws the whole desktop scale `Xft.dpi` sets, fractional ones included. */
    @Test
    fun `x11 takes the whole scale from xft dpi while awt draws at 1`() {
        assertEquals(1f, composeScale(x11 = true, xftScale = 1.0, awtScale = 1.0))
        assertEquals(1.25f, composeScale(x11 = true, xftScale = 120 / 96.0, awtScale = 1.0))
        assertEquals(1.75f, composeScale(x11 = true, xftScale = 168 / 96.0, awtScale = 1.0))
    }

    /**
     * At 200 % KDE sets `Xft.dpi: 192` (with `GDK_SCALE=2` and `GDK_DPI_SCALE=0.5`) and GNOME the same with its scaling
     * factor 2: the runtime draws AWT at 2 itself, so Compose adds nothing, or only the text scaling on top.
     */
    @Test
    fun `x11 never scales twice what awt already scales`() {
        assertEquals(1f, composeScale(x11 = true, xftScale = 2.0, awtScale = 2.0))
        assertEquals(1.25f, composeScale(x11 = true, xftScale = 2.5, awtScale = 2.0))
        assertEquals(1f, composeScale(x11 = true, xftScale = 3.0, awtScale = 3.0))
    }

    /** Whatever AWT scales by itself (GDK_SCALE, sun.java2d.uiScale), the app draws at the scale `Xft.dpi` sets. */
    @Test
    fun `x11 draws at the xft dpi scale whatever awt draws at`() {
        assertEquals(1.5, total(x11 = true, xftDpi = 144, awtScale = 2.0), 1e-6)
        assertEquals(1.75, total(x11 = true, xftDpi = 168, awtScale = 2.0), 1e-6)
        assertEquals(2.5, total(x11 = true, xftDpi = 240, awtScale = 3.0), 1e-6)
        assertEquals(1.0, total(x11 = true, xftDpi = 96, awtScale = 2.0), 1e-6)
    }

    @Test
    fun `x11 without xft dpi draws at the scale awt draws at`() {
        assertEquals(1f, composeScale(x11 = true, xftScale = null, awtScale = 1.0))
        assertEquals(1f, composeScale(x11 = true, xftScale = null, awtScale = 2.0))
    }

    /**
     * Under Wayland AWT draws at each output's scale, which the compositor rounds up at fractional scales (2 at 125 %
     * and 150 %) and scales down to the output's; on Windows at each monitor's. Compose adds nothing there, whatever
     * `Xft.dpi` says for X11 clients.
     */
    @Test
    fun `wayland and windows draw at the scale awt draws at`() {
        for (awt in listOf(1.0, 1.25, 1.5, 2.0, 3.0)) {
            assertEquals(1f, composeScale(x11 = false, xftScale = null, awtScale = awt))
            assertEquals(1f, composeScale(x11 = false, xftScale = 1.25, awtScale = awt))
        }
    }
}
