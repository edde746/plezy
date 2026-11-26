package com.edde746.plezy.ui.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.gestures.BringIntoViewSpec
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.card
import com.edde746.plezy.ui.movieCard
import kotlin.test.Test
import kotlin.test.assertEquals

/** A grid moved through a layer ([GridMotion]) rests each card focus goes to where the scrolling grid rests it. */
@OptIn(ExperimentalTestApi::class, ExperimentalFoundationApi::class)
class GridMotionTest {
    /** Android TV's scrolling for focus: a card out of view comes to 30 % of the height (whole, if that cuts it off). */
    private val pivot = object : BringIntoViewSpec {
        override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float): Float {
            val lead = 0.3f * containerSize
            return offset - if (size <= containerSize && containerSize - lead < size) containerSize - size else lead
        }
    }

    @Test
    fun downAndUpRestEachCardWhereTheScrollingGridDoes() {
        val keys = List(5) { Key.DirectionDown } + List(5) { Key.DirectionUp }
        assertEquals(stops(layerMotion = false, keys), stops(layerMotion = true, keys))
    }

    /** The focused card and its place in the grid at rest, first and after each of [keys]. */
    private fun stops(layerMotion: Boolean, keys: List<Key>): List<String> {
        val stops = ArrayList<String>()
        runComposeUiTest {
            setContent {
                TvFrame {
                    CompositionLocalProvider(LocalBringIntoViewSpec provides pivot) {
                        Box(Modifier.size(1100.dp, 600.dp)) {
                            MediaGrid(CARDS.size, CARDS::getOrNull, CardShape.POSTER, PaddingValues(top = 12.dp), onClick = {}, layerMotion = layerMotion)
                        }
                    }
                }
            }
            onNode(card(CARDS.first().title)).requestFocus()
            waitForIdle()
            fun stop() {
                val focused = onNode(isFocused()).fetchSemanticsNode()
                stops += "${focused.config.getOrNull(SemanticsProperties.ContentDescription)!!.single()} at ${focused.positionInRoot.y}"
            }
            stop()
            for (key in keys) {
                onRoot().performKeyInput { pressKey(key) }
                waitForIdle()
                stop()
            }
        }
        return stops
    }

    private companion object {
        val CARDS = (1..60).map { movieCard("m$it", "Movie $it") }
    }
}
