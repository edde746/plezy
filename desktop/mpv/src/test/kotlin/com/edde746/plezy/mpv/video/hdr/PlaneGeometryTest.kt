package com.edde746.plezy.mpv.video.hdr

import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class PlaneGeometryTest {
    /** One axis's buffer, in physical pixels, for the rect [position, position + extent). */
    private fun bufferExtent(position: Int, extent: Int, scale: Double): Int =
        planeRect(position, 0, extent, 1, scale).bufferWidth

    /** One axis's surface position, in logical units. */
    private fun position(position: Int, scale: Double, offset: Int = 0): Int =
        planeRect(position, 0, 1, 1, scale, offsetX = offset).x

    private val integerScales = (1..16).map { it.toDouble() }
    private val fractionalScales = listOf(1.25, 1.5, 1.7, 2.25)

    /** A rect already a whole number of units passes through untouched: rounding a legal size grows the plane. */
    @Test
    fun exactMultiplesAreUnchanged() {
        assertEquals(1920, bufferExtent(0, 1920, 1.0))
        assertEquals(1920, bufferExtent(0, 1920, 2.0))
        assertEquals(1920, bufferExtent(0, 1920, 3.0))
        assertEquals(1080, bufferExtent(0, 1080, 2.0))
        assertEquals(1083, bufferExtent(0, 1083, 3.0))
    }

    /** Sizes round up, never down: a plane smaller than the rect shows what is behind it through the seam. */
    @Test
    fun sizesOnePixelOverRoundUpNeverDown() {
        assertEquals(1922, bufferExtent(0, 1921, 2.0))
        assertEquals(1923, bufferExtent(0, 1921, 3.0))
        assertEquals(1923, bufferExtent(0, 1922, 3.0))
        assertEquals(1920, bufferExtent(0, 1919, 2.0))
        assertEquals(1920, bufferExtent(0, 1919, 3.0))
        assertEquals(1921, bufferExtent(0, 1921, 1.0))
    }

    /** A 0×0 layout, a sliver, or a negative extent from unvalidated input is still one whole unit. */
    @Test
    fun degenerateSizesYieldOneUnit() {
        assertEquals(1, bufferExtent(0, 0, 1.0))
        assertEquals(2, bufferExtent(0, 0, 2.0))
        assertEquals(3, bufferExtent(0, 0, 3.0))
        assertEquals(2, bufferExtent(0, 1, 2.0))
        assertEquals(3, bufferExtent(0, 2, 3.0))
        assertEquals(2, bufferExtent(0, -4096, 2.0))
        val sliver = planeRect(0, 0, 0, -5, 1.5)
        assertEquals(1, sliver.width)
        assertEquals(1, sliver.height)
        assertEquals(2, sliver.bufferWidth)
    }

    @Test
    fun sizesNearIntMaxDoNotOverflow() {
        assertEquals(Int.MAX_VALUE, bufferExtent(0, Int.MAX_VALUE, 1.0))
        assertEquals(Int.MAX_VALUE - 1, bufferExtent(0, Int.MAX_VALUE, 2.0))
        assertEquals(Int.MAX_VALUE - 1, bufferExtent(0, Int.MAX_VALUE, 3.0))
        assertEquals(Int.MAX_VALUE - 1, bufferExtent(0, Int.MAX_VALUE - 1, 3.0))
    }

    /** At an integer scale every buffer is a whole number of units, at least the rect and less than a unit over it. */
    @Test
    fun bufferExtentInvariantsHold() {
        for (scale in integerScales) {
            val unit = scale.toInt()
            for (extent in -8..64) {
                val rounded = bufferExtent(0, extent, scale)
                assertTrue(rounded >= unit)
                assertEquals(0, rounded % unit)
                assertTrue(rounded >= extent)
                assertTrue(extent < unit || rounded - extent < unit)
            }
        }
    }

    /** Wherever the rect sits, the plane covers all of it, tight to within one unit at each edge. */
    @Test
    fun thePlaneAlwaysCoversTheRectAtIntegerScales() {
        for (scale in integerScales) {
            val unit = scale.toLong()
            for (x in -40..40) {
                for (width in 1..80) {
                    val rect = planeRect(x, 0, width, 1, scale)
                    val origin = rect.x.toLong() * unit
                    val extent = rect.bufferWidth.toLong()
                    assertEquals(rect.width.toLong() * unit, extent)
                    assertTrue(origin <= x)
                    assertTrue(origin + extent >= x.toLong() + width)
                    assertEquals(0L, extent % unit)
                    assertTrue(x - origin < unit)
                    assertTrue(origin + extent - (x.toLong() + width) < unit)
                }
            }
        }
    }

    /**
     * At a fractional scale the plane, mapped back to physical pixels, still covers the rect and stays within one
     * unit of it at each edge, and the buffer is the destination's size in physical pixels.
     */
    @Test
    fun thePlaneAlwaysCoversTheRectAtFractionalScales() {
        val epsilon = 1e-6
        for (scale in fractionalScales) {
            for (x in -40..40) {
                for (width in 1..80) {
                    val rect = planeRect(x, 0, width, 1, scale)
                    val start = rect.x * scale
                    val end = (rect.x + rect.width) * scale
                    assertTrue(start <= x + epsilon, "scale $scale x $x width $width")
                    assertTrue(end >= x + width - epsilon, "scale $scale x $x width $width")
                    assertTrue(x - start < scale + epsilon)
                    assertTrue(end - (x + width) < scale + epsilon)
                    assertTrue(abs(rect.bufferWidth - rect.width * scale) < 1.0)
                    assertTrue(rect.bufferWidth >= rect.width * scale - epsilon)
                }
            }
        }
    }

    /** Both axes follow the same rule, each with its own offset. */
    @Test
    fun theVerticalAxisFollowsTheSameRule() {
        for (scale in integerScales + fractionalScales) {
            val rect = planeRect(-3, 7, 101, 55, scale, offsetX = 4, offsetY = 9)
            val swapped = planeRect(7, -3, 55, 101, scale, offsetX = 9, offsetY = 4)
            assertEquals(rect.x, swapped.y)
            assertEquals(rect.y, swapped.x)
            assertEquals(rect.width, swapped.height)
            assertEquals(rect.height, swapped.width)
            assertEquals(rect.bufferWidth, swapped.bufferHeight)
            assertEquals(rect.bufferHeight, swapped.bufferWidth)
        }
    }

    /** Past Int's end the rect cannot be covered; the buffer is the largest whole number of units that fits. */
    @Test
    fun anUnrepresentableRectStaysLegal() {
        for (scale in integerScales) {
            val unit = scale.toInt()
            for (x in listOf(-1, 0, 1, 40)) {
                val extent = bufferExtent(x, Int.MAX_VALUE, scale)
                assertTrue(extent > 0)
                assertEquals(0, extent % unit)
                when (unit) {
                    1 -> assertEquals(2147483647, extent)
                    2 -> assertEquals(2147483646, extent)
                    3 -> assertEquals(2147483646, extent)
                    8 -> assertEquals(2147483640, extent)
                    16 -> assertEquals(2147483632, extent)
                }
            }
        }
        for (scale in fractionalScales) {
            val rect = planeRect(-1, 0, Int.MAX_VALUE, 1, scale)
            assertTrue(rect.width > 0)
            assertTrue(rect.bufferWidth > 0)
        }
    }

    @Test
    fun exactPositionMultiplesConvertExactly() {
        assertEquals(0, position(0, 2.0))
        assertEquals(640, position(640, 1.0))
        assertEquals(320, position(640, 2.0))
        assertEquals(213, position(639, 3.0))
        assertEquals(-320, position(-640, 2.0))
        assertEquals(-213, position(-639, 3.0))
    }

    @Test
    fun positivePositionsFloorDown() {
        assertEquals(320, position(641, 2.0))
        assertEquals(0, position(1, 2.0))
        assertEquals(0, position(2, 3.0))
        assertEquals(213, position(641, 3.0))
        assertEquals(641, position(641, 1.0))
    }

    /** Truncating toward zero would move a rect scrolled off the left or top inward. */
    @Test
    fun negativePositionsFloorAwayFromZero() {
        assertEquals(-1, position(-1, 2.0))
        assertEquals(-2, position(-3, 2.0))
        assertEquals(-1, position(-1, 3.0))
        assertEquals(-2, position(-4, 3.0))
        assertEquals(-321, position(-641, 2.0))
        assertEquals(-641, position(-641, 1.0))
        assertEquals(-1, position(-1, 1.5))
    }

    @Test
    fun thePositionNeverBiasesInward() {
        for (scale in integerScales + fractionalScales) {
            for (physical in -32..32) {
                val local = position(physical, scale)
                assertTrue(local * scale <= physical + 1e-6)
                assertTrue(physical - local * scale < scale)
            }
        }
    }

    /** The offset is already logical, so it is added after the divide rather than scaled with the rect. */
    @Test
    fun theViewOffsetIsAddedInLogicalUnits() {
        assertEquals(357, position(640, 2.0, 37))
        assertEquals(357, position(641, 2.0, 37))
        assertEquals(35, position(-3, 2.0, 37))
        assertEquals(221, position(639, 3.0, 8))
        assertEquals(648, position(640, 1.0, 8))
        assertEquals(549, position(640, 1.25, 37))
    }

    /** A zero offset is indistinguishable from none, and any offset is a plain addition on top. */
    @Test
    fun aZeroViewOffsetChangesNothing() {
        for (scale in integerScales) {
            for (physical in -32..32) {
                val zero = position(physical, scale)
                assertTrue(zero * scale <= physical)
                assertTrue(physical - zero * scale < scale)
                for (offset in listOf(-37, -1, 0, 1, 37)) {
                    assertEquals(zero + offset, position(physical, scale, offset))
                }
            }
        }
    }

    /** The position stays in Int's range when an offset is added to an origin at its end. */
    @Test
    fun theOffsetSumIsClampedToInt() {
        assertEquals(Int.MAX_VALUE, position(Int.MAX_VALUE, 1.0, 37))
        assertEquals(Int.MIN_VALUE, position(Int.MIN_VALUE, 1.0, -37))
    }

    /** Below 1, zero, negative and non-finite scales are not scales; one pixel per unit is the safe identity. */
    @Test
    fun aScaleBelowOneOrNotFiniteIsTreatedAsOne() {
        assertEquals(1921, bufferExtent(0, 1921, 0.0))
        assertEquals(1, bufferExtent(0, 0, -4.0))
        assertEquals(-641, position(-641, 0.0))
        assertEquals(-634, position(-641, -4.0, 7))
        assertEquals(1921, bufferExtent(0, 1921, 0.5))
        assertEquals(1921, bufferExtent(0, 1921, Double.NaN))
        assertEquals(-641, position(-641, Double.POSITIVE_INFINITY))
    }
}
