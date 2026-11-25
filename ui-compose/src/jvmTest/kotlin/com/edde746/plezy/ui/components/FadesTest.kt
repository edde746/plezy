package com.edde746.plezy.ui.components

import androidx.compose.ui.graphics.Color
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** A backdrop's fade shows no edge: it leaves and reaches its flat ends without a change of slope. */
class FadesTest {
    @Test
    fun aFadeRunsFromItsStartToItsEndInOrder() {
        val stops = fadeStops(Color.Black, 1f, 0.45f, from = 1f, to = 0.2f)
        assertEquals(0.45f, stops.first().first, 0.001f, "the fade's top")
        assertEquals(0.2f, stops.first().second.alpha, 0.01f, "the alpha at the fade's top")
        assertEquals(1f, stops.last().first, 0.001f, "the fade's bottom")
        assertEquals(1f, stops.last().second.alpha, 0.01f, "the alpha at the fade's bottom")
        assertTrue(stops.toList().zipWithNext().all { (a, b) -> a.first < b.first && a.second.alpha <= b.second.alpha }, "out of order: ${stops.toList()}")
    }

    @Test
    fun aFadeIsFlatAtBothEnds() {
        val stops = fadeStops(Color.Black, 0f, 1f, from = 1f)
        val slopes = stops.toList().zipWithNext { a, b -> abs(b.second.alpha - a.second.alpha) / (b.first - a.first) }
        val steepest = slopes.max()
        assertTrue(slopes.first() < steepest / 5, "it leaves its start at ${slopes.first()}, the steepest is $steepest")
        assertTrue(slopes.last() < steepest / 5, "it reaches its end at ${slopes.last()}, the steepest is $steepest")
    }
}
