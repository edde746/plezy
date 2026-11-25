package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.FocusVisibility
import com.edde746.plezy.ui.focus.LocalFocusVisibility
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.Oled
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * Over a picture or the video a control that rests transparent or translucent (an icon button, the player's buttons,
 * the watch-together indicator) stays see-through under the pointer and pressed: a translucent tint over the picture,
 * never a solid surface. Over the black page that tint is the grey a hovered transparent control always had; a filled
 * control keeps its solid step.
 */
@OptIn(ExperimentalTestApi::class)
class OverlayHoverTest {
    /** A bright frame. */
    private val picture = Color(0xFFE0D8C8)
    private val translucent = Color.Black.copy(alpha = 0.45f)

    @Test
    fun aTransparentControlOverAPictureLetsItThroughHoveredAndPressed() = runComposeUiTest {
        buttons(picture)
        assertFill("plain", picture, "at rest")
        hover("plain")
        assertFill("plain", Oled.hoverTint.compositeOver(picture), "hovered")
        onNodeWithTag("plain").performMouseInput { press() }
        assertFill("plain", Oled.hoverTint.compositeOver(picture), "pressed")
        onNodeWithTag("plain").performMouseInput { release() }

        hover("translucent")
        assertFill("translucent", Oled.hoverTint.compositeOver(translucent).compositeOver(picture), "translucent, hovered")
    }

    @Test
    fun overThePageTheTintIsTheGreyItWasAndAFilledButtonKeepsItsStep() = runComposeUiTest {
        buttons(Oled.background)
        hover("plain")
        assertFill("plain", Oled.surfaceHigh, "hovered over the page")
        hover("filled")
        assertFill("filled", Oled.surfaceHighest, "a filled button, hovered")
    }

    private fun ComposeUiTest.hover(tag: String) {
        onNodeWithTag(tag).performMouseInput { moveTo(center) }
        waitForIdle()
    }

    /** The control's fill 15 % down its middle: inside the circle, clear of the icon. */
    private fun ComposeUiTest.fill(tag: String): Color {
        waitForIdle()
        val bounds = onNodeWithTag(tag).getBoundsInRoot()
        val pixels = onRoot().captureToImage().toPixelMap()
        return with(density) {
            pixels[((bounds.left + bounds.right) / 2).toPx().roundToInt(), (bounds.top + (bounds.bottom - bounds.top) * 0.15f).toPx().roundToInt()]
        }
    }

    private fun ComposeUiTest.assertFill(tag: String, expected: Color, what: String) {
        val actual = fill(tag)
        val off = listOf(actual.red - expected.red, actual.green - expected.green, actual.blue - expected.blue).maxOf { abs(it) }
        assertTrue(off <= 2f / 255, "$tag $what: $actual, expected $expected")
    }

    /** On [under], as the desktop app with the mouse in hand: focus hidden (a press may focus a control). */
    private fun ComposeUiTest.buttons(under: Color) = setContent {
        PlezyTheme {
            CompositionLocalProvider(LocalFocusVisibility provides FocusVisibility(false)) {
                Box(Modifier.size(640.dp, 360.dp).background(under)) {
                    AdaptiveLayout(FormFactor.DESKTOP) {
                        Row(Modifier.padding(48.dp), horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                            PlezyIconButton(PlezyIcons.ArrowBack, "Back", {}, Modifier.testTag("plain"), style = IconButtonStyle.PLAIN)
                            PlezyIconButton(PlezyIcons.Share, "Share", {}, Modifier.testTag("filled"))
                            PlezySurface({}, Modifier.size(48.dp).testTag("translucent"), shape = CircleShape, color = translucent) {}
                        }
                    }
                }
            }
        }
    }
}
