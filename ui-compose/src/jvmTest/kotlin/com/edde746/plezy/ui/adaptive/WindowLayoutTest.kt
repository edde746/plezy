package com.edde746.plezy.ui.adaptive

import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import kotlin.test.Test
import kotlin.test.assertEquals

/** How the destinations are offered: the TV's column on any TV window, else the window's width decides. */
class WindowLayoutTest {
    @Test
    fun aTvAlwaysGetsItsColumnAndOtherWindowsABarOnlyWhenCompact() {
        for (width in WidthClass.entries) assertEquals(NavigationKind.TV_SIDE, WindowLayout(FormFactor.TV, width).navigation)
        assertEquals(NavigationKind.BAR, WindowLayout(FormFactor.HANDHELD, WidthClass.of(412.dp)).navigation)
        assertEquals(NavigationKind.RAIL, WindowLayout(FormFactor.HANDHELD, WidthClass.of(600.dp)).navigation)
        assertEquals(NavigationKind.RAIL, WindowLayout(FormFactor.DESKTOP, WidthClass.of(1280.dp)).navigation)
        assertEquals(NavigationKind.BAR, WindowLayout(FormFactor.DESKTOP, WidthClass.of(599.dp)).navigation)
    }
}
