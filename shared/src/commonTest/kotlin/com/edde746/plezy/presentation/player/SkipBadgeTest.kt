package com.edde746.plezy.presentation.player

import kotlin.test.Test
import kotlin.test.assertEquals

/** Where the seek badge sits, as both UIs draw it. */
class SkipBadgeTest {
    @Test
    fun theInsetIs60AndOnTvFivePercentOfTheWidthWithin60And160() {
        assertEquals(60f, SkipBadge.inset(1280f, tv = false))
        assertEquals(60f, SkipBadge.inset(960f, tv = true), "5 % of 960 is under 60")
        assertEquals(96f, SkipBadge.inset(1920f, tv = true))
        assertEquals(160f, SkipBadge.inset(4000f, tv = true))
    }

    @Test
    fun aNarrowPlayerKeepsRoomForTheReadout() {
        assertEquals(60f, SkipBadge.inset(400f, tv = false))
        assertEquals(50f, SkipBadge.inset(300f, tv = false))
        assertEquals(0f, SkipBadge.inset(150f, tv = false))
    }
}
