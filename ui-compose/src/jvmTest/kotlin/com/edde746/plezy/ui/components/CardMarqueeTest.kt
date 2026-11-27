package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.app.LaunchFocusTest
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.app.PlezyPlatform
import com.edde746.plezy.ui.card
import com.edde746.plezy.ui.focus.FocusVisibility
import com.edde746.plezy.ui.focus.LocalFocusVisibility
import com.edde746.plezy.ui.movieCard
import kotlin.math.ceil
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

/**
 * Under a remote or a keyboard, the focused card's title, when cut short, scrolls once it has been focused a second: the
 * other cards' titles hold still, a title that fits holds still, and the title is back at its start, cut short, as soon
 * as the focus leaves. Not with less motion asked for, nor while the focus doesn't show (a pointer's, a touch's).
 */
@OptIn(ExperimentalTestApi::class)
class CardMarqueeTest {
    @Test
    fun onlyTheFocusedCardsLongTitleScrollsAndIsBackAtItsStartWhenFocusLeaves() = runComposeUiTest {
        cards()
        val first = label(FIRST)
        val second = label(SECOND)

        onNode(card(FIRST)).requestFocus()
        mainClock.advanceTimeBy(MARQUEE_DELAY_MILLIS - 200)
        assertEquals(first, label(FIRST), "the focused title holds still for its first second")
        mainClock.advanceTimeBy(1500)
        assertNotEquals(first, label(FIRST), "the focused title scrolls after a second")
        assertEquals(second, label(SECOND), "a title without focus holds still")
        val scrolled = label(FIRST)
        mainClock.advanceTimeBy(500)
        assertNotEquals(scrolled, label(FIRST), "the focused title keeps scrolling")

        onNode(card(SECOND)).requestFocus()
        mainClock.advanceTimeBy(100)
        assertEquals(first, label(FIRST), "the title is back at its start, cut short, once the focus leaves")
        mainClock.advanceTimeBy(MARQUEE_DELAY_MILLIS + 1500)
        assertNotEquals(second, label(SECOND), "the newly focused title scrolls")
        assertEquals(first, label(FIRST), "the title the focus left holds still")
    }

    @Test
    fun aFocusedTitleThatFitsHoldsStill() = runComposeUiTest {
        cards()
        val short = label(SHORT)
        onNode(card(SHORT)).requestFocus()
        mainClock.advanceTimeBy(MARQUEE_DELAY_MILLIS + 1500)
        assertEquals(short, label(SHORT))
    }

    @Test
    fun aLongTitleHoldsStillWithLessMotion() = runComposeUiTest {
        cards(platform = object : PlezyPlatform by LaunchFocusTest.TestPlatform(FormFactor.TV) {
            override val reducedMotion = true
        })
        val first = label(FIRST)
        onNode(card(FIRST)).requestFocus()
        mainClock.advanceTimeBy(MARQUEE_DELAY_MILLIS + 1500)
        assertEquals(first, label(FIRST))
    }

    @Test
    fun aLongTitleHoldsStillWhileTheFocusDoesntShow() = runComposeUiTest {
        cards(visibility = FocusVisibility(false))
        val first = label(FIRST)
        onNode(card(FIRST)).requestFocus()
        mainClock.advanceTimeBy(MARQUEE_DELAY_MILLIS + 1500)
        assertEquals(first, label(FIRST))
    }

    private fun ComposeUiTest.cards(
        platform: PlezyPlatform = LaunchFocusTest.TestPlatform(FormFactor.TV),
        visibility: FocusVisibility = FocusVisibility(true),
    ) {
        setContent {
            TvFrame {
                CompositionLocalProvider(LocalPlezyPlatform provides platform, LocalFocusVisibility provides visibility) {
                    Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                        for (title in listOf(FIRST, SECOND, SHORT)) {
                            PosterCard(movieCard(title), onClick = {}, modifier = Modifier.testTag(title))
                        }
                    }
                }
            }
        }
        waitForIdle()
        mainClock.autoAdvance = false
    }

    /** The pixels of the text under [title]'s card (clear of its artwork as it grows with focus), row by row. */
    private fun ComposeUiTest.label(title: String): List<Int> {
        val whole = onNodeWithTag(title)
        val artwork = onNode(card(title)).fetchSemanticsNode().boundsInRoot
        val gap = with(density) { 10.dp.toPx() }
        val top = ceil(artwork.bottom - whole.fetchSemanticsNode().boundsInRoot.top + gap).toInt()
        val image = whole.captureToImage().toPixelMap()
        return (top until image.height).flatMap { y -> (0 until image.width).map { x -> image[x, y].toArgb() } }
    }

    private companion object {
        const val FIRST = "The Extraordinarily Long Title of an Unremarkable Documentary"
        const val SECOND = "A Second Title Far Too Long to Fit on One Line"
        const val SHORT = "Up"
    }
}
