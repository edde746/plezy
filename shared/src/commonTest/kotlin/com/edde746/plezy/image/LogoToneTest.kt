package com.edde746.plezy.image

import com.edde746.plezy.presentation.theme.Palette
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LogoToneTest {
    @Test
    fun `classifies white wordmarks accented and mixed marks discs and chips`() {
        assertEquals(LogoTone.LIGHT_MONOCHROME, tone(whiteWordmark()))
        assertEquals(LogoTone.LIGHT_ACCENTED, tone(accentedMark()))
        assertEquals(LogoTone.LIGHT_MIXED, tone(mixedMark()))
        assertEquals(LogoTone.BACKED, tone(selfBackedDisc()))
        assertEquals(LogoTone.BACKED, tone(coloredChip()))
    }

    @Test
    fun `a neutral enclosed by the opposite one is backed whatever the light majority`() {
        assertEquals(LogoTone.BACKED, tone(backedPlate()))
        assertEquals(LogoTone.BACKED, tone(outlinedWordmark()))
    }

    @Test
    fun `dark ink that only touches the light mark keeps the recolour`() {
        assertEquals(LogoTone.LIGHT_ACCENTED, tone(touchingUnderlineMark()))
    }

    @Test
    fun `a near empty frame is unknown`() {
        assertEquals(LogoTone.UNKNOWN, tone(raster { rect(0.0, 0.0, 8.0, 8.0, WHITE) }))
    }

    @Test
    fun `sparse sampling agrees with every pixel on each mark`() {
        listOf(
            whiteWordmark(), accentedMark(), mixedMark(), selfBackedDisc(), coloredChip(), backedPlate(),
            outlinedWordmark(), touchingUnderlineMark(),
        ).forEach { assertEquals(tone(it), analyzeLogoTone(it, W, H, stride = 4)) }
    }

    @Test
    fun `recolours white to the ink and keeps coloured pixels`() {
        val source = mixedMark()
        val out = remapLightNeutral(source, INK)
        val wordmark = 75 * W + 165
        assertEquals(255, out[wordmark] ushr 24)
        assertTrue(luma(out[wordmark]) < 32)
        val feather = source.indexOfFirst { it ushr 24 == 255 && it shr 16 and 0xFF > 200 && it shr 8 and 0xFF < 80 && it and 0xFF < 80 }
        assertNotEquals(-1, feather)
        assertEquals(source[feather], out[feather])
    }

    @Test
    fun `antialiased edges darken instead of leaving a light fringe`() {
        val out = remapLightNeutral(whiteWordmark(), INK)
        val partials = out.filter { it ushr 24 in 16..240 }
        assertTrue(partials.isNotEmpty())
        partials.forEach { assertTrue(luma(it) <= 96, "edge pixel stayed light: ${it.toUInt().toString(16)}") }
    }

    @Test
    fun `only light themes recolour and mixed marks only where asked`() {
        assertNull(logoInk(Palette.OLED))
        assertEquals(Palette.LIGHT.text, logoInk(Palette.LIGHT))
        assertTrue(LogoTone.LIGHT_ACCENTED.recolours(remapMixed = false))
        assertTrue(!LogoTone.LIGHT_MIXED.recolours(remapMixed = false))
        assertTrue(LogoTone.LIGHT_MIXED.recolours(remapMixed = true))
        assertTrue(!LogoTone.BACKED.recolours(remapMixed = true))
    }

    private fun tone(pixels: IntArray) = analyzeLogoTone(pixels, W, H)

    private fun luma(pixel: Int) = ((pixel shr 16 and 0xFF) * 77 + (pixel shr 8 and 0xFF) * 150 + (pixel and 0xFF) * 29) shr 8

    private fun whiteWordmark() = raster { repeat(4) { rect(30.5 + it * 65, 40.5, 45.0, 70.0, WHITE) } }

    private fun mixedMark() = raster {
        val colors = listOf(0xFF9C27B0, 0xFF2196F3, 0xFF4CAF50, 0xFFFFEB3B, 0xFFFF9800, 0xFFF44336)
        colors.forEachIndexed { i, color ->
            val angle = PI + i * PI / colors.size
            circle(75 + 35 * cos(angle), 85 + 35 * sin(angle), 14.0, color.toInt())
        }
        repeat(3) { rect(150.0 + it * 50, 50.0, 35.0, 50.0, WHITE) }
    }

    private fun accentedMark() = raster {
        repeat(4) { rect(30.5 + it * 65, 40.5, 45.0, 70.0, WHITE) }
        rect(30.5, 118.5, 260.0, 12.0, 0xFF303030.toInt())
        circle(285.0, 55.0, 12.0, RED)
    }

    private fun selfBackedDisc() = raster {
        circle(150.0, 75.0, 65.0, 0xFF0F0F0F.toInt())
        rect(115.0, 60.0, 70.0, 30.0, WHITE)
    }

    private fun coloredChip() = raster {
        circle(150.0, 75.0, 70.0, 0xFF2638C4.toInt())
        rect(110.0, 55.0, 80.0, 40.0, 0xFF8EC63F.toInt())
    }

    private fun backedPlate() = raster {
        rect(20.0, 25.0, 260.0, 100.0, WHITE)
        repeat(5) { rect(45.0 + it * 48, 50.0, 24.0, 50.0, 0xFF1A1A1A.toInt()) }
    }

    private fun outlinedWordmark() = raster {
        repeat(4) {
            rect(24.5 + it * 65, 34.5, 57.0, 82.0, 0xFF202020.toInt())
            rect(30.5 + it * 65, 40.5, 45.0, 70.0, WHITE)
        }
    }

    private fun touchingUnderlineMark() = raster {
        repeat(4) { rect(30.5 + it * 65, 40.5, 45.0, 70.0, WHITE) }
        rect(30.5, 110.5, 260.0, 12.0, 0xFF303030.toInt())
        circle(285.0, 55.0, 12.0, RED)
    }

    /** A [W] × [H] transparent frame with shapes painted over it in order, edges antialiased by 4 × 4 coverage. */
    private fun raster(draw: Canvas.() -> Unit): IntArray = Canvas().apply(draw).pixels

    private class Canvas {
        val pixels = IntArray(W * H)

        fun rect(left: Double, top: Double, width: Double, height: Double, color: Int) =
            fill(color) { x, y -> x >= left && x < left + width && y >= top && y < top + height }

        fun circle(cx: Double, cy: Double, radius: Double, color: Int) =
            fill(color) { x, y -> (x - cx) * (x - cx) + (y - cy) * (y - cy) <= radius * radius }

        private fun fill(color: Int, inside: (Double, Double) -> Boolean) {
            for (py in 0 until H) for (px in 0 until W) {
                var hits = 0
                for (sy in 0 until 4) for (sx in 0 until 4) if (inside(px + (sx + 0.5) / 4, py + (sy + 0.5) / 4)) hits++
                if (hits == 0) continue
                pixels[py * W + px] = over(color, hits * 255 / 16, pixels[py * W + px])
            }
        }

        /** [color] at [alpha] over the straight-alpha [below]. */
        private fun over(color: Int, alpha: Int, below: Int): Int {
            val belowAlpha = below ushr 24
            val outAlpha = alpha + belowAlpha * (255 - alpha) / 255
            if (outAlpha == 0) return 0
            fun channel(shift: Int): Int {
                val top = color shr shift and 0xFF
                val bottom = below shr shift and 0xFF
                return (top * alpha + bottom * belowAlpha * (255 - alpha) / 255) / outAlpha
            }
            return (outAlpha shl 24) or (channel(16) shl 16) or (channel(8) shl 8) or channel(0)
        }
    }

    private companion object {
        const val W = 300
        const val H = 150
        const val WHITE = -1
        val RED = 0xFFF44336.toInt()
        const val INK = 0xFF111111
    }
}
