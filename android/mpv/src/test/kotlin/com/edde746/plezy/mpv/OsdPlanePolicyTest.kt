package com.edde746.plezy.mpv

import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertNull

class OsdPlanePolicyTest {
    @Test
    fun fullResolutionLeavesThePlaneFollowingItsView() {
        assertNull(OsdPlanePolicy.fixedSizeFor(1920, 1080, 1.0))
    }

    @Test
    fun aFractionShrinksBothSidesByTheSameScale() {
        assertEquals(OsdPlanePolicy.Size(1440, 810), OsdPlanePolicy.fixedSizeFor(1920, 1080, 0.75))
        assertEquals(OsdPlanePolicy.Size(960, 540), OsdPlanePolicy.fixedSizeFor(1920, 1080, 0.5))
        assertEquals(OsdPlanePolicy.Size(480, 270), OsdPlanePolicy.fixedSizeFor(1920, 1080, 0.25))
    }

    @Test
    fun anOddSideRoundsDownToEvenAndNeverBelowTwo() {
        assertEquals(OsdPlanePolicy.Size(332, 250), OsdPlanePolicy.fixedSizeFor(1000, 750, 1.0 / 3))
        assertEquals(OsdPlanePolicy.Size(2, 2), OsdPlanePolicy.fixedSizeFor(3, 3, 0.25))
    }

    @Test
    fun aViewNotLaidOutOrAScaleOutOfRangeKeepsTheView() {
        assertNull(OsdPlanePolicy.fixedSizeFor(0, 0, 0.5))
        assertNull(OsdPlanePolicy.fixedSizeFor(1920, 1080, 0.0))
        assertNull(OsdPlanePolicy.fixedSizeFor(1920, 1080, 1.5))
    }

    @Test
    fun amlogicAndMediatekTvBoxesPresentTheSubtitlePlaneARefreshLate() {
        val delay = "vo-mediacodec-osd-vsync-delay" to "1"
        // A SEI Box R 4K Plus (S905X4) and a Google TV Streamer (MT8696) report these vendors.
        assertContains(OsdPlanePolicy.socOptions("Amlogic", "SEI", tv = true), delay)
        assertEquals(listOf(delay), OsdPlanePolicy.socOptions("Mediatek", "Google", tv = true))
        assertEquals(listOf(delay), OsdPlanePolicy.socOptions("MediaTek", "Amazon", tv = true))
    }

    @Test
    fun phonesOtherSocsAndUnreportedVendorsKeepThePlaneOnTheVideoTimestamp() {
        // The Shield (Tegra, API 28) reports no vendor and shows both planes on one refresh.
        assertEquals(emptyList(), OsdPlanePolicy.socOptions(null, "NVIDIA", tv = true))
        assertEquals(emptyList(), OsdPlanePolicy.socOptions("NVIDIA", "NVIDIA", tv = true))
        assertEquals(emptyList(), OsdPlanePolicy.socOptions("Realtek", "Xiaomi", tv = true))
        assertEquals(emptyList(), OsdPlanePolicy.socOptions("Mediatek", "Xiaomi", tv = false))
        assertEquals(listOf("vo-mediacodec-letterbox-fill" to "no"), OsdPlanePolicy.socOptions("Amlogic", "Xiaomi", tv = false))
    }

    @Test
    fun amlogicDevicesButAmazonsLeaveTheLetterboxTransparent() {
        val noFill = "vo-mediacodec-letterbox-fill" to "no"
        assertContains(OsdPlanePolicy.socOptions("Amlogic", "Xiaomi", tv = true), noFill)
        assertContains(OsdPlanePolicy.socOptions("amlogic", "onn.", tv = true), noFill)
        // The Amlogic Fire TV Cube needs the opaque fill, as MediaTek boxes do.
        assertEquals(listOf("vo-mediacodec-osd-vsync-delay" to "1"), OsdPlanePolicy.socOptions("Amlogic", "Amazon", tv = true))
        assertEquals(emptyList(), OsdPlanePolicy.socOptions(null, "Xiaomi", tv = false))
    }
}
