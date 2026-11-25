package com.edde746.plezy.image

import com.edde746.plezy.settings.VisualEffects
import kotlin.test.Test
import kotlin.test.assertEquals

class ImageMemoryBudgetTest {
    private val mib = 1L shl 20
    private val full = ArtworkDisplay()
    private val reduced = ArtworkDisplay(reduced = true)

    @Test
    fun `a desktop keeps 1000 images in 150 MiB whatever its tier or layout`() {
        assertEquals(ImageMemoryBudget(1000, 150 * mib), ImageMemoryBudget.of(desktop = true, tv = false, display = full))
        assertEquals(ImageMemoryBudget(1000, 150 * mib), ImageMemoryBudget.of(desktop = true, tv = true, display = reduced))
    }

    @Test
    fun `the reduced tier keeps 400 images in 64 MiB on a TV too`() {
        assertEquals(ImageMemoryBudget(400, 64 * mib), ImageMemoryBudget.of(desktop = false, tv = true, display = reduced))
        assertEquals(ImageMemoryBudget(400, 64 * mib), ImageMemoryBudget.of(desktop = false, tv = false, display = reduced))
    }

    @Test
    fun `a TV keeps 500 images in 64 MiB times its display budget`() {
        assertEquals(ImageMemoryBudget(500, 64 * mib), ImageMemoryBudget.of(desktop = false, tv = true, display = full))
        val uhd = ArtworkDisplay.of(2.0, tv = true, VisualEffects.AUTO, ArtworkDevice(3840, 2160, totalMemoryBytes = 4L shl 30))
        assertEquals(ImageMemoryBudget(500, 128 * mib), ImageMemoryBudget.of(desktop = false, tv = true, display = uhd))
        val midRam = ArtworkDisplay.of(2.0, tv = true, VisualEffects.AUTO, ArtworkDevice(3840, 2160, totalMemoryBytes = 2400L shl 20))
        assertEquals(ImageMemoryBudget(500, 96 * mib), ImageMemoryBudget.of(desktop = false, tv = true, display = midRam))
    }

    @Test
    fun `a phone or tablet keeps 800 images in 100 MiB`() {
        assertEquals(ImageMemoryBudget(800, 100 * mib), ImageMemoryBudget.of(desktop = false, tv = false, display = full))
    }
}
