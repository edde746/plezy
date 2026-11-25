package com.edde746.plezy.image

import com.edde746.plezy.settings.VisualEffects
import kotlin.test.Test
import kotlin.test.assertEquals

class ArtworkDiagnosticsTest {
    private val weakBox = ArtworkDevice(1920, 1080, is64Bit = false, lowRamDevice = true, totalMemoryBytes = 2040L shl 20)
    private val shield = ArtworkDevice(3840, 2160, totalMemoryBytes = 3006L shl 20)

    private fun effects(setting: VisualEffects, device: ArtworkDevice) =
        describeEffects(setting, device, ArtworkDisplay.of(1.0, tv = true, setting, device))

    @Test
    fun `the tier names the hardware signals that decided it`() {
        assertEquals("reduced (auto: 32-bit, lowRam:true, 2.0GiB)", effects(VisualEffects.AUTO, weakBox))
        assertEquals("full (auto: 64-bit, lowRam:false, 2.9GiB)", effects(VisualEffects.AUTO, shield))
    }

    @Test
    fun `a forced tier still names the hardware`() {
        assertEquals("full (forced; hw: 32-bit, lowRam:true, 2.0GiB)", effects(VisualEffects.FULL, weakBox))
        assertEquals("reduced (forced; hw: 64-bit, lowRam:false, 2.9GiB)", effects(VisualEffects.REDUCED, shield))
    }

    @Test
    fun `a device without hardware signals names only the tier`() {
        assertEquals("full", effects(VisualEffects.AUTO, ArtworkDevice(2560, 1440)))
        assertEquals("reduced (forced)", effects(VisualEffects.REDUCED, ArtworkDevice()))
    }

    @Test
    fun `the display line tells a 1080p surface from the 4K display behind it`() {
        val display = ArtworkDisplay.of(2.0, tv = true, VisualEffects.AUTO, shield)
        assertEquals(
            "3840x2160 physical, 960x540 logical @ 4.00x (budget 2.0x)",
            describeDisplay(3840, 2160, 4.0, shield, display),
        )
        assertEquals(
            "1920x1080 physical, 960x540 logical @ 2.00x, display 3840x2160 (budget 2.0x)",
            describeDisplay(1920, 1080, 2.0, shield, display),
        )
        assertEquals(
            "1280x800 physical, 1280x800 logical @ 1.00x (budget 1.0x)",
            describeDisplay(1280, 800, 1.0, ArtworkDevice(), ArtworkDisplay()),
        )
    }
}
