package com.edde746.plezy.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.layout.densityFactor
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.adaptive.WindowLayout

/**
 * Size tokens for the window at hand ([com.edde746.plezy.ui.adaptive.AdaptiveLayout] provides them): dense on
 * phones, a step roomier on tablets and desktop, larger on TV (10-foot viewing) where focused elements also grow.
 *
 * @param screenPadding the horizontal inset of screen content (TV: overscan-safe).
 * @param gutter the gap between items in a row or grid.
 * @param sectionSpacing the gap between shelves and between groups of a page.
 * @param shelfHeaderGap the gap between a shelf's heading and its cards, well under [sectionSpacing]: the heading
 *   belongs to the row under it.
 * @param posterWidth the width of a portrait poster; landscape and square posters derive from it.
 * @param sectionTitleSize a shelf's or group's heading.
 * @param chipHeight a chip's height.
 * @param controlHeight a button's height.
 * @param iconButtonSize a round icon button's diameter.
 * @param controlFocusScale how much a focused button, chip or row grows (TV only; 1 elsewhere).
 * @param posterFocusScale how much a focused poster or thumbnail grows (TV only; 1 elsewhere).
 * @param focusRing the width of the focus ring.
 * @param contentMaxWidth lists and text columns stay this narrow on wide windows, centred
 *   ([com.edde746.plezy.ui.components.contentColumn]).
 * @param gridPosterMaxWidth on TV, the widest a grid's poster is at the middle density (null elsewhere): TV grids round
 *   their columns up under a most width ([gridCardMaxWidth]) instead of fitting cards of at least [gridCardWidth].
 */
@Immutable
data class PlezyDimens(
    val screenPadding: Dp,
    val gutter: Dp,
    val sectionSpacing: Dp,
    val shelfHeaderGap: Dp,
    val posterWidth: Dp,
    val sectionTitleSize: TextUnit,
    val chipHeight: Dp,
    val controlHeight: Dp,
    val iconButtonSize: Dp,
    val controlFocusScale: Float,
    val posterFocusScale: Float,
    val focusRing: Dp,
    val contentMaxWidth: Dp,
    val gridPosterMaxWidth: Dp? = null,
) {
    /** Whether focused elements grow (TV). */
    val focusGrows: Boolean get() = controlFocusScale > 1f

    /** The width of a card in a row for [shape]: wide and square cards are wider so rows keep a similar height. */
    fun cardWidth(shape: CardShape): Dp = when (shape) {
        CardShape.POSTER -> posterWidth
        CardShape.SQUARE -> posterWidth * 1.2f
        CardShape.WIDE -> posterWidth * 1.9f
    }

    /**
     * A grid's least column width for [shape] at the library density setting ([density], 1 most compact to 5 most
     * comfortable): [cardWidth] at the middle setting, from 20 % narrower to 20 % wider. The grid fits as many columns
     * of at least this width as the window holds.
     */
    fun gridCardWidth(shape: CardShape, density: Int): Dp = cardWidth(shape) * (0.8f + 0.4f * densityFactor(density).toFloat())

    /**
     * On TV, a grid's most column width for [shape] at the library density setting ([density]): [gridPosterMaxWidth]
     * at the middle setting, from a third narrower to a third wider; a square card as wide as a poster, an episode
     * thumbnail 1.9 times. Null elsewhere.
     */
    fun gridCardMaxWidth(shape: CardShape, density: Int): Dp? = gridPosterMaxWidth?.let { poster ->
        val width = poster * (2f / 3f + 2f / 3f * densityFactor(density).toFloat())
        if (shape == CardShape.WIDE) width * 1.9f else width
    }

    companion object {
        fun of(layout: WindowLayout): PlezyDimens = when {
            layout.formFactor == FormFactor.TV -> PlezyDimens(
                screenPadding = 48.dp, gutter = 16.dp, sectionSpacing = 24.dp, shelfHeaderGap = 6.dp, posterWidth = 150.dp,
                sectionTitleSize = 22.sp, chipHeight = 40.dp, controlHeight = 48.dp, iconButtonSize = 48.dp,
                controlFocusScale = 1.05f, posterFocusScale = 1.06f, focusRing = 2.dp, contentMaxWidth = 1100.dp,
                gridPosterMaxWidth = 105.dp,
            )
            layout.widthClass == WidthClass.COMPACT -> PlezyDimens(
                screenPadding = 16.dp, gutter = 10.dp, sectionSpacing = 16.dp, shelfHeaderGap = 4.dp, posterWidth = 104.dp,
                sectionTitleSize = 18.sp, chipHeight = 32.dp, controlHeight = 40.dp, iconButtonSize = 40.dp,
                controlFocusScale = 1f, posterFocusScale = 1f, focusRing = 2.dp, contentMaxWidth = 600.dp,
            )
            layout.formFactor == FormFactor.DESKTOP -> PlezyDimens(
                screenPadding = 24.dp, gutter = 12.dp, sectionSpacing = 20.dp, shelfHeaderGap = 4.dp, posterWidth = 132.dp,
                sectionTitleSize = 18.sp, chipHeight = 32.dp, controlHeight = 40.dp, iconButtonSize = 40.dp,
                controlFocusScale = 1f, posterFocusScale = 1f, focusRing = 2.dp, contentMaxWidth = 960.dp,
            )
            else -> PlezyDimens(
                screenPadding = 24.dp, gutter = 12.dp, sectionSpacing = 16.dp, shelfHeaderGap = 4.dp, posterWidth = 120.dp,
                sectionTitleSize = 18.sp, chipHeight = 32.dp, controlHeight = 40.dp, iconButtonSize = 40.dp,
                controlFocusScale = 1f, posterFocusScale = 1f, focusRing = 2.dp, contentMaxWidth = 760.dp,
            )
        }
    }
}

val LocalPlezyDimens = staticCompositionLocalOf { PlezyDimens.of(WindowLayout(FormFactor.DESKTOP, WidthClass.EXPANDED)) }
