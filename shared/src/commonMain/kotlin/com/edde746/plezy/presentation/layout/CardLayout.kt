package com.edde746.plezy.presentation.layout

import com.edde746.plezy.settings.GridSpacing
import kotlin.math.max

/** A media card's artwork shape. */
enum class CardShape(
    /** Width over height. */
    val aspect: Double,
) {
    /** 2:3, a film's or a show's poster. */
    POSTER(2.0 / 3.0),

    /** 16:9, an episode's or a clip's thumbnail. */
    WIDE(16.0 / 9.0),

    /** 1:1, music (an artist's drawn as a circle). */
    SQUARE(1.0),
}

/**
 * The width a layout is sized for, as the library grid's breakpoints see it: [TV] whatever the width, otherwise by the
 * content's width ([of]).
 */
enum class LayoutClass {
    PHONE, TABLET, DESKTOP, TV;

    companion object {
        /** By [width]: under 600 a phone, under 1200 a tablet, a desktop from there; a TV always [TV]. */
        fun of(width: Double, tv: Boolean): LayoutClass = when {
            tv -> TV
            width >= 1200 -> DESKTOP
            width >= 600 -> TABLET
            else -> PHONE
        }
    }
}

/** The library density setting (1 most compact to 5 most comfortable) as a factor from 0 to 1. */
fun densityFactor(density: Int): Double = (density.coerceIn(1, 5) - 1) / 4.0

/** The gap between cards the grid-spacing setting asks for. */
val GridSpacing.gap: Double
    get() = when (this) {
        GridSpacing.TIGHT -> 0.0
        GridSpacing.NORMAL -> 6.0
        GridSpacing.SPACIOUS -> 12.0
    }

/** The gap between a grid card's artwork and its title the grid-spacing setting asks for (a hub row's card: always 2). */
val GridSpacing.titleGap: Double
    get() = when (this) {
        GridSpacing.TIGHT -> 2.0
        GridSpacing.NORMAL -> 4.0
        GridSpacing.SPACIOUS -> 6.0
    }

/** What a media grid's cards share across the UIs: their padding, title lines and spacing. */
object GridLayout {
    /** A captioned card's horizontal padding around its artwork and caption. */
    const val CARD_PADDING_START = 3.0
    const val CARD_PADDING_END = 3.0

    /**
     * The lines a grid card's title takes, every card of the grid reserving them so its rows line up: two at the
     * compact densities (1 and 2), whose narrow cards cut a title to a few characters and so alike titles to the same
     * prefix, one from the default (3) up.
     */
    fun titleLines(density: Int): Int = if (density < 3) 2 else 1

    /** Square (music) grids keep at least this gap. */
    const val SQUARE_MIN_SPACING = 8.0

    /**
     * The gap between cells: a full-bleed (artwork only) TV grid's 12 × [tvScale] within 8–18; otherwise the setting's
     * [GridSpacing.gap], at least [SQUARE_MIN_SPACING] for square cells.
     */
    fun spacing(gridSpacing: GridSpacing, shape: CardShape, fullBleed: Boolean, tvScale: Double = 1.0): Double = when {
        fullBleed -> (12 * tvScale).coerceIn(8.0, 18.0)
        shape == CardShape.SQUARE -> max(SQUARE_MIN_SPACING, gridSpacing.gap)
        else -> gridSpacing.gap
    }
}

/**
 * A list row's artwork in the list view, by density: base width 70 + 50 × [densityFactor]; a poster base × 1.5 tall, a
 * wide thumbnail 1.6 base × 0.9 base, a square base × base. The row is the artwork plus 16 of padding.
 */
data class ListRowLayout(val artworkWidth: Double, val artworkHeight: Double) {
    val rowHeight: Double get() = artworkHeight + 2 * PADDING

    companion object {
        const val PADDING = 8.0
        const val ARTWORK_GAP = 12.0

        fun of(density: Int, shape: CardShape): ListRowLayout {
            val base = 70 + 50 * densityFactor(density)
            return when (shape) {
                CardShape.POSTER -> ListRowLayout(base, base * 1.5)
                CardShape.WIDE -> ListRowLayout(base * 1.6, base * 0.9)
                CardShape.SQUARE -> ListRowLayout(base, base)
            }
        }

        /** Title 13 + 3f (weight 600, 2 lines), metadata 10 + 3f, subtitle 11 + 3f. */
        fun titleSize(density: Int): Double = 13 + 3 * densityFactor(density)
        fun metadataSize(density: Int): Double = 10 + 3 * densityFactor(density)
        fun subtitleSize(density: Int): Double = 11 + 3 * densityFactor(density)

        /** Summary lines by density 1–5: 2, 2, 3, 4, 5. */
        fun summaryLines(density: Int): Int = intArrayOf(2, 2, 3, 4, 5)[density.coerceIn(1, 5) - 1]
    }
}
