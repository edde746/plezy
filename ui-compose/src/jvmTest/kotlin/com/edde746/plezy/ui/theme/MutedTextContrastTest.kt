package com.edde746.plezy.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.graphics.toArgb
import com.edde746.plezy.presentation.theme.AppTheme
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.ThemeMode
import kotlin.test.Test
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Secondary text reads at least 4.5:1 wherever it is drawn in every built-in theme: the theme's muted colour and the
 * muted level of the content colour (also a played queue row's title and a past airing's), on the background, the
 * surface (cards, sheets) and the raised fills (grouped rows, chips, menus, guide cells), and on TV on a focused control's fill.
 */
class MutedTextContrastTest {
    @Test
    fun secondaryTextReadsOnEveryFillInEveryBuiltInTheme() {
        for (mode in ThemeMode.entries.filter { it != ThemeMode.SYSTEM && it != ThemeMode.CUSTOM }) {
            for (tv in listOf(false, true)) {
                val colors = PlezyColorSet(assertNotNull(AppTheme.resolve(mode, null, unlocked = true, tv = tv).palette, "$mode"))
                val fills = mapOf(
                    "background" to colors.background,
                    "surface" to colors.surface,
                    "raised fill" to colors.surfaceHigh,
                    "highest fill" to colors.surfaceHighest,
                )
                for ((name, fill) in fills) {
                    assertReads(colors.textMuted, fill, "$mode: the muted colour on the $name")
                    assertReads(colors.muted(colors.text), fill, "$mode: muted content on the $name")
                }
                val focused = colors.focusFill(tv)
                assertReads(colors.muted(colors.onFocusFill(tv)), focused, "$mode: muted content on a focused control (tv $tv)")
            }
        }
    }

    private fun assertReads(text: Color, fill: Color, what: String) {
        val ratio = Palette.contrastRatio(text.compositeOver(fill).argb, fill.argb)
        assertTrue(ratio >= 4.5, "$what: $ratio:1")
    }

    private val Color.argb: Long get() = toArgb().toLong() and 0xFFFFFFFF
}
