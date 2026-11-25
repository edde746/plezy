package com.edde746.plezy.presentation.livetv.guide

import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram

/**
 * The Live TV guide: a [GuideLayout.WINDOW_HOURS]-hour window of the channels' airings. Times are epoch seconds;
 * lengths are [GuideLayout]'s points.
 *
 * @param windowStart the window's start; it ends [GuideLayout.WINDOW_SECONDS] later.
 * @param now the guide's now, moved on every minute.
 * @param dayLabel the day picker's pill: "Now" while the live window shows now (it opens on now); else "Today",
 *   "Tomorrow" or the weekday of the half hour the view starts in, and [timeLabel] its time (null with "Now"). The view:
 *   what the UI last said it shows ([GuideStore.setView]), else where the window opens.
 * @param timeMarks the time header: one label per half hour.
 * @param rows the grid's rows in display order: a source header before each source's channels when there are several.
 * @param nowOffset where the now line falls across the grid; null when now is outside the window.
 * @param isLoading a window is loading. Before the first load ends the guide shows a spinner alone
 *   ([showsFullSpinner]); later the grid stays, D-pad focus with it, under a light overlay ([showsReloadOverlay]).
 * @param focus the D-pad focus; drawn only while the guide holds the platform's focus ([hasFocus]).
 * @param menu the day picker's open menu.
 * @param channelMenu the channel (its [GuideRow.Channel.channelIndex]) whose menu is open: Watch Channel, Favorite and
 *   the details of what it airs now ([GuideRow.Channel.airing]).
 * @param scroll the last scroll the guide asked for: the UI performs each [GuideScroll.id] once.
 * @param focusRequest bumped when the guide wants the platform's focus (a search jump, a closed menu); in keyboard or
 *   D-pad mode the UI moves its focus to the guide.
 */
data class GuideUiState(
    val windowStart: Long = 0,
    val now: Long = 0,
    val dayLabel: String = "",
    val timeLabel: String? = null,
    val timeMarks: List<GuideTimeMark> = emptyList(),
    val rows: List<GuideRow> = emptyList(),
    val nowOffset: Double? = null,
    val isLoading: Boolean = true,
    val hasLoadedOnce: Boolean = false,
    val focus: GuideFocus = GuideFocus(),
    val hasFocus: Boolean = false,
    val menu: GuideMenu? = null,
    val channelMenu: Int? = null,
    val scroll: GuideScroll? = null,
    val focusRequest: Int = 0,
) {
    val showsFullSpinner: Boolean get() = isLoading && !hasLoadedOnce
    val showsReloadOverlay: Boolean get() = isLoading && hasLoadedOnce

    /** The rows' total height. */
    val contentHeight: Double get() = rows.sumOf { it.height }

    /** The top of [channelIndex]'s row in the rows' scroll. */
    fun rowTop(channelIndex: Int): Double = guideRowTop(rows, channelIndex)

    /** Whether [row]'s channel cell is drawn focused. */
    fun isFocused(row: GuideRow.Channel): Boolean =
        hasFocus && focus.zone == GuideZone.GRID && focus.column == GuideColumn.CHANNEL && focus.channelIndex == row.channelIndex

    /** Whether [cell] on [row] is drawn focused. */
    fun isFocused(row: GuideRow.Channel, cell: GuideProgramCell): Boolean =
        hasFocus && focus.zone == GuideZone.GRID && focus.column == GuideColumn.PROGRAM && focus.channelIndex == row.channelIndex &&
            focus.program == cell.program

    /** Whether the time navigation's [item] is drawn focused. */
    fun isFocused(item: GuideTimeNavItem): Boolean = hasFocus && focus.zone == GuideZone.TIME_NAV && focus.timeNavItem == item

    /** [cell]'s colours on [row]: inverted when focused, else by its airing time. */
    fun tone(row: GuideRow.Channel, cell: GuideProgramCell): GuideCellTone =
        if (isFocused(row, cell)) GuideCellTone.FOCUSED else cell.timing.tone
}

/** A grid row: [height] high. */
sealed interface GuideRow {
    val height: Double

    /** A source's header ([label]: its server and lineup), whose text stays pinned to the grid's left edge. */
    data class SourceHeader(val label: String) : GuideRow {
        override val height: Double get() = GuideLayout.SOURCE_HEADER_ROW_HEIGHT
    }

    /**
     * A channel: its cell (logo, else number and name; a star when [isFavorite]) and its airings' blocks ([programs],
     * empty: "No programs"). [channelIndex] is its place in the channels shown, which focus and events use.
     */
    data class Channel(
        val channel: LiveTvChannel,
        val channelIndex: Int,
        val isFavorite: Boolean,
        val programs: List<GuideProgramCell>,
    ) : GuideRow {
        override val height: Double get() = GuideLayout.ROW_HEIGHT

        /** What the channel airs now, among [programs]; null when the window doesn't hold now. */
        val airing: LiveTvProgram? get() = programs.firstOrNull { it.timing == GuideTiming.AIRING }?.program
    }
}

/** The top of [channelIndex]'s row among [rows]. */
fun guideRowTop(rows: List<GuideRow>, channelIndex: Int): Double {
    var top = 0.0
    for (row in rows) {
        if (row is GuideRow.Channel && row.channelIndex == channelIndex) return top
        top += row.height
    }
    return channelIndex * GuideLayout.ROW_HEIGHT
}

/**
 * An airing's block: at [left] across the grid, [width] wide (its airing clamped to the window, at least
 * [GuideLayout.MIN_BLOCK_WIDTH]). [title] is the show's title, else the airing's; [subtitle] for an episode
 * "S1E2 · {title}" (or the title alone); [timeText] "{start} · {length}", [startText] the start alone, shown where the
 * block's room can't hold [timeText] whole. A red dot with "Recording scheduled" when [isRecordingScheduled]; a "NEW"
 * pill when [isPremiere].
 */
data class GuideProgramCell(
    val program: LiveTvProgram,
    val left: Double,
    val width: Double,
    val title: String,
    val subtitle: String?,
    val timeText: String?,
    val startText: String?,
    val isRecordingScheduled: Boolean,
    val isPremiere: Boolean,
    val timing: GuideTiming,
)

/** Where an airing stands at the guide's now. */
enum class GuideTiming(val tone: GuideCellTone) {
    PAST(GuideCellTone.PAST),
    AIRING(GuideCellTone.AIRING),
    FUTURE(GuideCellTone.FUTURE),
}

/**
 * A block's colours: [FOCUSED] inverted (the primary colour, its text on primary), whatever its airing time; [PAST] the
 * surface with its title in the secondary strength its times have, so it reads as over and stays readable; [AIRING]
 * the airing tint; [FUTURE] the surface.
 */
enum class GuideCellTone { FOCUSED, PAST, AIRING, FUTURE }

/** The guide's two D-pad zones: the time navigation row above the grid, and the grid. */
enum class GuideZone { TIME_NAV, GRID }

/** The time navigation row: ◀ (two hours back), the day picker, ▶ (two hours on). */
enum class GuideTimeNavItem { EARLIER, DAY, LATER }

/** The grid's two columns: the channel cells and the program blocks. */
enum class GuideColumn { CHANNEL, PROGRAM }

/**
 * Where the D-pad focus is: in [zone]; on [timeNavItem] in the time navigation; on [channelIndex]'s row in the grid,
 * its channel cell or, in the program column, [program]'s block.
 */
data class GuideFocus(
    val zone: GuideZone = GuideZone.TIME_NAV,
    val timeNavItem: GuideTimeNavItem = GuideTimeNavItem.DAY,
    val channelIndex: Int = 0,
    val column: GuideColumn = GuideColumn.CHANNEL,
    val program: LiveTvProgram? = null,
)

/** The day picker's menus, anchored on the day pill. */
sealed interface GuideMenu {
    /** "Now" (back to the live window), then today and the seven days after it, the window's day [GuideDayChoice.selected]. */
    data class Days(val choices: List<GuideDayChoice>) : GuideMenu

    /** The time slots of the day just picked ([header]: its label in capitals, a back entry to [Days]). */
    data class Slots(val epochDay: Long, val header: String, val slots: List<GuideTimeSlot>) : GuideMenu
}

/** A day picker entry: [epochDay] null for "Now". */
data class GuideDayChoice(val label: String, val epochDay: Long?, val selected: Boolean)

/**
 * A scroll the guide asks of the UI, performed once per [id]: vertically to the row at [rowTop] when it is out of view
 * ([guideRowScrollOffset]); horizontally per [horizontal].
 */
data class GuideScroll(val id: Int, val rowTop: Double?, val horizontal: GuideHorizontalScroll?)

sealed interface GuideHorizontalScroll {
    /** Brings the now line ([nowOffset] across the grid) into view at the start of a slot ([guideScrollToNowOffset]). */
    data class ToNow(val nowOffset: Double) : GuideHorizontalScroll

    /** Brings a block starting at [left] into view ([guideProgramScrollOffset]). */
    data class ToProgram(val left: Double) : GuideHorizontalScroll
}

/** What the guide asks of the Live TV screen. */
sealed interface GuideEvent {
    /** Tune [channel]. */
    data class Tune(val channel: LiveTvChannel) : GuideEvent

    /** Open [program]'s details on [channel]. */
    data class ShowDetails(val channel: LiveTvChannel, val program: LiveTvProgram) : GuideEvent

    /** Add [channel] to the favourites, or take it off. */
    data class ToggleFavorite(val channel: LiveTvChannel) : GuideEvent

    /** Left or Back out of the guide: the side navigation. */
    data object Back : GuideEvent

    /** Up out of the guide: the tab bar. */
    data object FocusTabs : GuideEvent
}
