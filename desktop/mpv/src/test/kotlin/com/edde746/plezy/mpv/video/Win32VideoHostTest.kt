package com.edde746.plezy.mpv.video

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class Win32VideoHostTest {
    /**
     * Windows hands mpv the black level the display reports, and libplacebo now renders PQ black at it: a TV that
     * reports a floor above what it shows lifts every video's blacks. The Windows output keeps black absolute, whether
     * or not HDR is on.
     */
    @Test
    fun videoBlackStaysAbsoluteBlack() {
        assertEquals("inf", Win32VideoHost().options(child = 42)["target-contrast"])
    }

    @Test
    fun hdrAndToneMappingOptions() {
        val options = Win32VideoHost().options(child = 42)
        assertEquals("auto", options["target-colorspace-hint"])
        assertEquals("auto", options["tone-mapping"])
        assertEquals("auto", options["hdr-compute-peak"])
        assertNull(options["vf"])
    }

    /** On Adreno both per-frame inputs of the tone-mapping LUT are silenced: peak detection and HDR10+ metadata. */
    @Test
    fun qualcommSilencesDynamicToneMapping() {
        val options = Win32VideoHost().options(child = 42, qualcomm = true)
        assertEquals("no", options["hdr-compute-peak"])
        assertEquals("format:hdr10plus=no", options["vf"])
    }

    /** The System Media Transport Controls own the media keys. */
    @Test
    fun mpvLeavesMediaKeysAlone() {
        assertEquals("no", Win32VideoHost().options(child = 42)["input-media-keys"])
    }
}
