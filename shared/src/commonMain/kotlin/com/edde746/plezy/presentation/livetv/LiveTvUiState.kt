package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram

/** A snackbar a Live TV store shows once: the UI shows it, then tells the store it was shown. */
data class LiveTvMessage(val text: String, val isError: Boolean = false)

/**
 * The Live TV screen around its tabs.
 *
 * @param tabs the tab chips in order: Guide always, What's On when a server has hubs, Scheduled ([LiveTvTab.RECORDINGS]:
 *   the scheduled recordings and the rules) when one records.
 * @param actions the app bar's buttons for [selectedTab], in order.
 * @param guideEmpty the Guide tab's centred text when no channel loaded but the Recordings tab is there.
 * @param favoritesEmpty the Guide tab's empty state when the favourites filter hides every loaded channel; the Guide
 *   tab shows the grid otherwise.
 * @param channels every loaded channel, across servers and DVRs, sorted by number.
 * @param favoriteChannelKeys the [com.edde746.plezy.livetv.scopeKey]s of the favourite channels, for their star.
 * @param search the guide search sheet while it is open.
 * @param reorder the reorder favourites sheet while it is open.
 * @param focus where D-pad focus goes next; the UI moves it, then calls `focusHandled`.
 */
data class LiveTvUiState(
    val title: String,
    val tabs: List<LiveTvTabUi>,
    val selectedTab: LiveTvTab,
    val actions: List<LiveTvActionUi>,
    val body: LiveTvBody,
    val guideEmpty: String?,
    val favoritesEmpty: LiveTvFavoritesEmptyUi?,
    val favoritesOnly: Boolean,
    val channels: List<LiveTvChannel>,
    val favoriteChannelKeys: Set<String>,
    val search: GuideSearchUiState?,
    val reorder: ReorderFavoritesUiState?,
    val message: LiveTvMessage?,
    val focus: LiveTvFocusTarget?,
)

data class LiveTvTabUi(val tab: LiveTvTab, val label: String)

/** What the screen shows under its app bar. */
sealed interface LiveTvBody {
    /** A spinner: channels are loading. */
    data object Loading : LiveTvBody

    /** Loading failed with nothing to show: [message] and a Retry button ([retryLabel]) that takes focus. */
    data class Failed(val message: String, val retryLabel: String) : LiveTvBody

    /** No channels and no Recordings tab: centred [message]. */
    data class Empty(val message: String) : LiveTvBody

    /** The tab chips and the selected tab. */
    data object Tabs : LiveTvBody
}

/** The Guide tab when the favourites filter leaves nothing: a star, [title], [hint] and the [actionLabel] button. */
data class LiveTvFavoritesEmptyUi(val title: String, val hint: String, val actionLabel: String)

enum class LiveTvAction { SEARCH, FAVORITES_FILTER, REORDER_FAVORITES, PROCESS_RULES, REFRESH }

/** An app bar button: its [label] is the tooltip; [active] fills the favourites star while the filter is on. */
data class LiveTvActionUi(val action: LiveTvAction, val label: String, val active: Boolean = false)

enum class LiveTvFocusTarget {
    /** The selected tab's content (or the favourites empty state's button). */
    CONTENT,

    /** The tab chips. */
    TAB_BAR,

    /** The app bar's first button. */
    ACTIONS,

    /** The guide search's first result. */
    SEARCH_RESULT,
}

/**
 * The guide search sheet: [query] as typed. Channels match on title, call sign or number; programs (the next day's
 * airings) on title or series name once the query has two characters.
 *
 * @param showsPrograms whether the programs section shows (two characters typed and programs loading or found).
 * @param noResults the centred text when nothing matches (and nothing is loading).
 */
data class GuideSearchUiState(
    val title: String,
    val hint: String,
    val query: String,
    val channelsLabel: String,
    val channels: List<GuideSearchChannelRow>,
    val programsLabel: String,
    val showsPrograms: Boolean,
    val programsLoading: Boolean,
    val programs: List<GuideSearchProgramRow>,
    val noResults: String?,
) {
    val hasResults: Boolean get() = channels.isNotEmpty() || programs.isNotEmpty()
}

/** A channel result: [title] its name, [subtitle] "Channel {number}". */
data class GuideSearchChannelRow(val channel: LiveTvChannel, val title: String, val subtitle: String?)

/** A program result: [title] its display title, [subtitle] "{channel} · {day} {time}". */
data class GuideSearchProgramRow(val channel: LiveTvChannel, val program: LiveTvProgram, val title: String, val subtitle: String)

/** The reorder favourites sheet: the favourites in their order. */
data class ReorderFavoritesUiState(val title: String, val rows: List<ReorderFavoriteRow>)

/**
 * A favourite's row: [title] the channel's name (else the favourite's title, else its id), [number] the channel's
 * number, [thumb] the channel's logo on [serverId]'s server (an icon when null).
 */
data class ReorderFavoriteRow(val key: String, val title: String, val number: String?, val thumb: String?, val serverId: String?)
