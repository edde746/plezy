package com.edde746.plezy.presentation.player

/**
 * A button of a phone's or tablet's top bar that a bar too narrow for it moves into the options sheet, declared in the
 * order they move: the rotation lock first, the screen lock last. Cast, Audio and Subtitles always stay in the bar.
 */
enum class MovableBarButton { ROTATION_LOCK, VIDEO_FIT, PICTURE_IN_PICTURE, SCREEN_LOCK }

/** How the player's top bar shares its width between the title and its buttons, decided by the bar's width alone. */
object TopBarButtons {
    /** The share of the bar the title keeps at the least. */
    const val TITLE_SHARE = 0.4f

    /** The title keeps at the least one readable line of this many characters, where that is wider than its share. */
    const val TITLE_CHARACTERS = 12

    /**
     * Which of the [present] movable buttons a bar [barWidth] wide moves into the options sheet; the bar shows the
     * others. The title keeps the larger of [TITLE_SHARE] of the bar and [lineWidth] (a line of [TITLE_CHARACTERS]
     * characters in its style); what always stays (Back, the live badge, the room pill, Cast, Settings, Audio,
     * Subtitles, the margins) takes [fixedWidth]; the room left keeps as many movable buttons, [buttonWidth] each with
     * [gap] between two, as fit, and the rest move in [MovableBarButton]'s order. Widths in any one unit.
     */
    fun moved(
        present: Set<MovableBarButton>,
        barWidth: Float,
        fixedWidth: Float,
        lineWidth: Float,
        buttonWidth: Float,
        gap: Float,
    ): Set<MovableBarButton> {
        val room = barWidth - fixedWidth - maxOf(barWidth * TITLE_SHARE, lineWidth)
        val fitting = if (room < buttonWidth) 0 else ((room + gap) / (buttonWidth + gap)).toInt()
        return MovableBarButton.entries.filter { it in present }.take((present.size - fitting).coerceAtLeast(0)).toSet()
    }
}
