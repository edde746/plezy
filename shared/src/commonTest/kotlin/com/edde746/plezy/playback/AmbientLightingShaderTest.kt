package com.edde746.plezy.playback

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AmbientLightingShaderTest {
    private val passes = AmbientLightingShader.source.split("//!HOOK MAIN").drop(1)

    private fun pass(desc: String) = passes.single { "//!DESC Ambient Lighting $desc\n" in it }

    @Test
    fun itKeepsThePictureThenBlursItsCentreAtAnEighthAndASixtyFourthThenComposites() {
        assertEquals(
            listOf("Save", "Downscale", "Blur1", "Blur2", "Blur3", "Downscale2", "Blur4", "Blur5", "Composite"),
            passes.map { Regex("//!DESC Ambient Lighting (\\w+)").find(it)!!.groupValues[1] },
        )
        assertTrue("//!SAVE ORIGINAL" in pass("Save"))
        val downscale = pass("Downscale")
        assertTrue("//!WIDTH ORIGINAL.w 8 /" in downscale && "//!HEIGHT ORIGINAL.h 8 /" in downscale)
        assertTrue("ORIGINAL_pos * 0.6 + 0.2" in downscale, "the centre 60%")
        assertTrue("//!WIDTH BLUR8C.w 8 /" in pass("Downscale2"))
        assertTrue("//!SAVE" !in pass("Composite"), "the composite replaces the picture")
    }

    @Test
    fun theKawaseBlursSampleTheirOffsetsDiagonally() {
        for ((desc, input, offset) in listOf(
            Triple("Blur1", "SMALL", "2.0"), Triple("Blur2", "BLUR8A", "6.0"), Triple("Blur3", "BLUR8B", "12.0"),
            Triple("Blur4", "TINY", "3.0"), Triple("Blur5", "GLOW1", "6.0"),
        )) {
            val pass = pass(desc)
            assertTrue("//!BIND $input\n" in pass, desc)
            assertTrue("vec2( $offset,  $offset)" in pass && "vec2(-$offset, -$offset)" in pass, desc)
            assertTrue("return s * 0.25;" in pass, desc)
        }
    }

    @Test
    fun theCompositeLetterboxesThePictureAtItsAspectAndTheGlowAtHalfBrightness() {
        val composite = pass("Composite")
        assertTrue("input_size.x / input_size.y" in composite && "target_size.x / target_size.y" in composite)
        assertTrue("return ORIGINAL_tex(vid_pos);" in composite)
        assertTrue("return GLOW_tex(ORIGINAL_pos) * 0.50;" in composite)
    }
}
