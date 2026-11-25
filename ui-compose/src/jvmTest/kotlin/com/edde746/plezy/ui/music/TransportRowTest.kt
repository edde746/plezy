package com.edde746.plezy.ui.music

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.performClick
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyColorSet
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Now Playing's transport in a layout narrower than its row (312 wide in 200), at a car's density: on a car's display
 * the buttons keep their full size (a 32 icon's 56 wide touch target); elsewhere the row scales down to fit.
 */
@OptIn(ExperimentalTestApi::class)
class TransportRowTest {
    /** The Next button's width on screen, in dp at the car's density, with the transport [automotive] or not. */
    private fun ComposeUiTest.nextWidth(automotive: Boolean): Float {
        setContent {
            CompositionLocalProvider(LocalDensity provides Density(0.75f * 1.35f)) {
                Box(Modifier.width(200.dp)) {
                    TransportRow(automotive, Modifier.width(200.dp)) {
                        TransportIcon(PlezyIcons.Shuffle, "Shuffle", false, 22, "shuffle") {}
                        TransportIcon(PlezyIcons.SkipPrevious, "Previous", true, 32, "previous") {}
                        TransportIcon(PlezyIcons.PlayArrow, "Play", true, 32, "play") {}
                        TransportIcon(PlezyIcons.SkipNext, "Next", true, 32, "next") {}
                        TransportIcon(PlezyIcons.Repeat, "Repeat", false, 22, "repeat") {}
                    }
                }
            }
        }
        waitForIdle()
        return onNodeWithContentDescription("Next").fetchSemanticsNode().boundsInRoot.width / (0.75f * 1.35f)
    }

    @Test
    fun shuffleTellsScreenReadersWhetherItIsOn() = runComposeUiTest {
        var on by mutableStateOf(false)
        setContent { TransportIcon(PlezyIcons.Shuffle, "Shuffle", on, 22, "shuffle", toggle = true) { on = !on } }
        onNodeWithContentDescription("Shuffle").assertIsNotSelected().performClick()
        onNodeWithContentDescription("Shuffle").assertIsSelected()
    }

    @Test
    fun aToggleThatIsOnRestsInTheAccentTintAndOffInNone() = runComposeUiTest {
        var on by mutableStateOf(false)
        setContent { TransportIcon(PlezyIcons.Shuffle, "Shuffle", on, 22, "shuffle", toggle = true) {} }
        // Inside the round button, 4 dp under its top edge, clear of the icon.
        fun fill(): Color = onNodeWithContentDescription("Shuffle").captureToImage().toPixelMap()
            .let { it[it.width / 2, (4 * density.density).roundToInt()] }
        assertEquals(0f, fill().alpha, "off, Shuffle rests in no fill")
        // Turned on by the queue (no pointer resting on it, which would draw its hover fill).
        on = true
        waitForIdle()
        val tint = PlezyColorSet(Palette.OLED).accentRest
        val drawn = fill()
        assertTrue(listOf(drawn.red - tint.red, drawn.green - tint.green, drawn.blue - tint.blue, drawn.alpha - 1f).all { abs(it) < 0.02f }, "on, Shuffle rests in the accent tint $tint, not $drawn")
    }

    @Test
    fun onACarTheTransportKeepsItsFullSizeTouchTargets() = runComposeUiTest {
        assertEquals(56f, nextWidth(automotive = true), 0.5f)
    }

    @Test
    fun elsewhereTheTransportScalesDownToFitANarrowLayout() = runComposeUiTest {
        val width = nextWidth(automotive = false)
        assertTrue(width < 40f, "Next is $width wide")
    }
}
