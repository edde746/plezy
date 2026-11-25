package com.edde746.plezy.playback.mpv

import kotlin.test.Test
import kotlin.test.assertEquals

class DecoderOperatingRateTest {
    @Test
    fun aFilmDeclaresTheFloorNotItsOwnRate() {
        assertEquals(60, DecoderOperatingRate.of(23.976, 1.0, codecMaxFps = null))
        assertEquals(60, DecoderOperatingRate.of(null, 1.0, codecMaxFps = null), "no container rate")
    }

    @Test
    fun aFastFileDeclaresTwiceItsRate() {
        assertEquals(120, DecoderOperatingRate.of(59.94, 1.0, codecMaxFps = null))
    }

    @Test
    fun theSpeedScalesTheRate() {
        assertEquals(120, DecoderOperatingRate.of(23.976, 2.0, codecMaxFps = null))
        assertEquals(30, DecoderOperatingRate.of(23.976, 0.5, codecMaxFps = null))
    }

    @Test
    fun theDecodersMaximumAndTheCeilingCapIt() {
        assertEquals(90, DecoderOperatingRate.of(59.94, 1.0, codecMaxFps = 90))
        assertEquals(240, DecoderOperatingRate.of(59.94, 4.0, codecMaxFps = null))
        assertEquals(240, DecoderOperatingRate.of(59.94, 4.0, codecMaxFps = 960))
    }
}
