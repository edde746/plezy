package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.theme.AppTheme
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.FocusVisibility
import com.edde746.plezy.ui.focus.LocalFocusVisibility
import com.edde746.plezy.ui.theme.Oled
import com.edde746.plezy.ui.theme.PlezyColorSet
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * On TV only the focused control is filled: a primary button, a selected chip and a guide element the store draws
 * focused rest apart from the focus fill, and each takes it when focused. A resting primary reads as primary: its
 * solid tint stands apart from a secondary's fill in every built-in theme, its label readable on it.
 */
@OptIn(ExperimentalTestApi::class)
class TvRestingPrimaryTest {
    private val primary = FocusRequester()
    private val secondary = FocusRequester()
    private val chip = FocusRequester()
    private val text = FocusRequester()

    @Test
    fun onTvOnlyTheFocusedControlHasTheFocusFill() = runComposeUiTest {
        controls()
        runOnIdle { secondary.requestFocus() }
        assertFill("secondary", Oled.focusFill(tv = true), "focused")
        assertFill("primary", Oled.primaryRest, "a primary at rest")
        assertFill("chip", Oled.accentRest, "a selected chip at rest")

        runOnIdle { primary.requestFocus() }
        assertFill("primary", Oled.focusFill(tv = true), "a primary focused")
        assertFill("secondary", Oled.surfaceHigh, "at rest")

        runOnIdle { chip.requestFocus() }
        assertFill("chip", Oled.focusFill(tv = true), "a selected chip focused")
        assertFill("primary", Oled.primaryRest, "a primary at rest")
    }

    @Test
    fun aRestingPrimaryStandsApartFromASecondaryInEveryBuiltInTheme() {
        for (mode in ThemeMode.entries.filter { it != ThemeMode.SYSTEM && it != ThemeMode.CUSTOM }) {
            val colors = PlezyColorSet(assertNotNull(AppTheme.resolve(mode, null, unlocked = true, tv = true).palette, "$mode"))
            val fills = Palette.contrastRatio(colors.primaryRest.argb, colors.surfaceHigh.argb)
            val label = Palette.contrastRatio(colors.text.argb, colors.primaryRest.argb)
            assertTrue(fills >= 1.5, "$mode: the primary and secondary fills $fills:1 apart")
            assertTrue(label >= 4.5, "$mode: the primary's label $label:1 on its fill")
        }
    }

    private val Color.argb: Long get() = toArgb().toLong() and 0xFFFFFFFF

    @Test
    fun aGuideElementTheStoreDrawsFocusedTakesTheFocusFillOnTv() = runComposeUiTest {
        controls()
        assertFill("drawn", Oled.focusFill(tv = true), "drawn focused")
    }

    /** On TV a text button (Cancel) rests as a tonal pill, a secondary's fill, never as plain text; focus fills it. */
    @Test
    fun onTvATextButtonRestsAsATonalPill() = runComposeUiTest {
        controls()
        assertFill("text", Oled.surfaceHigh, "a text button at rest")
        runOnIdle { text.requestFocus() }
        assertFill("text", Oled.focusFill(tv = true), "a text button focused")
    }

    /** The control's fill 12 dp in from its leading edge, half way down: inside its focus ring, before its label. */
    private fun ComposeUiTest.fill(tag: String): Color {
        waitForIdle()
        val bounds = onNodeWithTag(tag).getBoundsInRoot()
        val pixels = onRoot().captureToImage().toPixelMap()
        return with(density) {
            pixels[(bounds.left + 12.dp).toPx().roundToInt(), ((bounds.top + bounds.bottom) / 2).toPx().roundToInt()]
        }
    }

    private fun ComposeUiTest.assertFill(tag: String, expected: Color, what: String) {
        val actual = fill(tag)
        val off = listOf(actual.red - expected.red, actual.green - expected.green, actual.blue - expected.blue).maxOf { abs(it) }
        assertTrue(off <= 2f / 255, "$tag $what: $actual, expected $expected")
    }

    private fun ComposeUiTest.controls() = setContent {
        PlezyTheme {
            CompositionLocalProvider(LocalFocusVisibility provides FocusVisibility(true)) {
                Box(Modifier.size(1280.dp, 360.dp).background(Oled.background)) {
                    AdaptiveLayout(FormFactor.TV) {
                        Row(Modifier.padding(48.dp), horizontalArrangement = Arrangement.spacedBy(32.dp)) {
                            PlezyButton("Play", {}, Modifier.focusRequester(primary).testTag("primary"), style = ButtonStyle.PRIMARY)
                            PlezyButton("Trailer", {}, Modifier.focusRequester(secondary).testTag("secondary"))
                            PlezyChip("Movies", selected = true, onClick = {}, modifier = Modifier.focusRequester(chip).testTag("chip"))
                            PlezyChip("Today", selected = false, onClick = {}, modifier = Modifier.testTag("drawn"), drawnFocused = true)
                            PlezyButton("Cancel", {}, Modifier.focusRequester(text).testTag("text"), style = ButtonStyle.TEXT)
                        }
                    }
                }
            }
        }
    }
}
