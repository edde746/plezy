package com.edde746.plezy.presentation.livetv.guide

import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram

/** A D-pad direction. */
enum class GuideDirection { UP, DOWN, LEFT, RIGHT }

/**
 * What the D-pad moves over: the [channels] shown, their rows' [displayOrder] (channel indexes as the rows list them,
 * grouped by source), each channel's airings ([programs]), the window's start and the time in view ([viewTime]: now
 * while the view shows it, else the time at the view's start).
 */
class GuideGrid(
    val channels: List<LiveTvChannel>,
    val displayOrder: List<Int>,
    val windowStart: Long,
    val viewTime: Long,
    private val programs: (LiveTvChannel) -> List<LiveTvProgram>,
) {
    fun programs(channelIndex: Int): List<LiveTvProgram> = channels.getOrNull(channelIndex)?.let(programs).orEmpty()
}

/**
 * A D-pad move's outcome: the new [focus]; [exit] when it leaves the guide ([GuideEvent.Back] to the side navigation,
 * [GuideEvent.FocusTabs] to the tab bar); [scrollToRow] when the focused row must come into view, [scrollToProgram] when
 * that block must.
 */
data class GuideMove(
    val focus: GuideFocus,
    val exit: GuideEvent? = null,
    val scrollToRow: Boolean = false,
    val scrollToProgram: LiveTvProgram? = null,
)

/**
 * Moves [focus] one step [direction] over [grid]:
 * - Time navigation: left and right walk ◀, day, ▶ (left past ◀ leaves to the side navigation); up leaves to the tab
 *   bar; down enters the grid on the last focused row's channel cell.
 * - Grid, up and down: rows in display order; up from the first row goes to the day picker. In the program column the
 *   focused time stays (the airing on at the focused block's start, clamped to the window, else the nearest), and a row
 *   without airings lands on its channel cell.
 * - Grid, right: from a channel cell to the airing on at the time in view (else the next, else the first); then airing
 *   by airing.
 * - Grid, left: airing by airing back to the channel cell; from there to the side navigation.
 */
fun guideMove(focus: GuideFocus, direction: GuideDirection, grid: GuideGrid): GuideMove = when (focus.zone) {
    GuideZone.TIME_NAV -> timeNavMove(focus, direction, grid)
    GuideZone.GRID -> when (direction) {
        GuideDirection.UP, GuideDirection.DOWN -> verticalMove(focus, direction == GuideDirection.UP, grid)
        GuideDirection.RIGHT -> rightMove(focus, grid)
        GuideDirection.LEFT -> leftMove(focus, grid)
    }
}

private fun timeNavMove(focus: GuideFocus, direction: GuideDirection, grid: GuideGrid): GuideMove {
    val items = GuideTimeNavItem.entries
    val index = focus.timeNavItem.ordinal
    return when (direction) {
        GuideDirection.LEFT -> if (index > 0) GuideMove(focus.copy(timeNavItem = items[index - 1])) else GuideMove(focus, exit = GuideEvent.Back)
        GuideDirection.RIGHT -> GuideMove(focus.copy(timeNavItem = items[minOf(index + 1, items.lastIndex)]))
        GuideDirection.UP -> GuideMove(focus, exit = GuideEvent.FocusTabs)
        GuideDirection.DOWN -> if (grid.channels.isEmpty()) {
            GuideMove(focus)
        } else {
            GuideMove(focus.copy(zone = GuideZone.GRID, column = GuideColumn.CHANNEL, program = null), scrollToRow = true)
        }
    }
}

private fun verticalMove(focus: GuideFocus, up: Boolean, grid: GuideGrid): GuideMove {
    val order = grid.displayOrder
    val position = order.indexOf(focus.channelIndex)
    if (up && position <= 0) return GuideMove(focus.copy(zone = GuideZone.TIME_NAV, timeNavItem = GuideTimeNavItem.DAY))
    if (!up && (position == -1 || position >= order.lastIndex)) return GuideMove(focus)
    val channelIndex = order[if (up) position - 1 else position + 1]
    if (focus.column == GuideColumn.CHANNEL) return GuideMove(focus.copy(channelIndex = channelIndex), scrollToRow = true)
    val anchor = focus.program
    val programs = grid.programs(channelIndex)
    val program = if (anchor == null) guideCurrentProgram(programs, grid.viewTime) else guideProgramNear(programs, guideAnchorTime(anchor, grid.windowStart))
    if (program == null) return GuideMove(focus.copy(channelIndex = channelIndex, column = GuideColumn.CHANNEL, program = null), scrollToRow = true)
    return GuideMove(focus.copy(channelIndex = channelIndex, program = program), scrollToRow = true, scrollToProgram = program)
}

private fun rightMove(focus: GuideFocus, grid: GuideGrid): GuideMove {
    if (focus.column == GuideColumn.CHANNEL) {
        val program = guideCurrentProgram(grid.programs(focus.channelIndex), grid.viewTime) ?: return GuideMove(focus)
        return GuideMove(focus.copy(column = GuideColumn.PROGRAM, program = program), scrollToProgram = program)
    }
    val next = adjacentProgram(focus, grid, 1) ?: return GuideMove(focus)
    return GuideMove(focus.copy(program = next), scrollToProgram = next)
}

private fun leftMove(focus: GuideFocus, grid: GuideGrid): GuideMove {
    if (focus.column == GuideColumn.CHANNEL) return GuideMove(focus, exit = GuideEvent.Back)
    val previous = adjacentProgram(focus, grid, -1) ?: return GuideMove(focus.copy(column = GuideColumn.CHANNEL, program = null))
    return GuideMove(focus.copy(program = previous), scrollToProgram = previous)
}

private fun adjacentProgram(focus: GuideFocus, grid: GuideGrid, step: Int): LiveTvProgram? {
    val programs = grid.programs(focus.channelIndex)
    val current = programs.indexOf(focus.program ?: return null)
    if (current < 0) return null
    return programs.getOrNull(current + step)
}
