package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogHubStyle
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.MediaHub

/**
 * The Explore tab: the active catalog source's shelves, its switcher and its inline search. TV keeps its toolbar (the
 * switcher, Search, Refresh) up in every [body], so a source without rows can still be switched away from.
 *
 * @param title the active source's name; "Explore" when none is connected.
 * @param sources every connected source, in listing order; the switcher shows when there are two or more.
 * @param searchHint the search field's hint, naming the active source.
 * @param searchText the inline field's text.
 * @param search what replaces the shelves while [searchText] holds more than spaces; null otherwise.
 * @param body the shelves, or why there are none.
 * @param refreshing a refresh ([ExploreStore.refresh]) is still loading; [body] keeps what it shows meanwhile.
 */
data class ExploreUiState(
    val title: String,
    val sources: List<ExploreSourceOption>,
    val searchHint: String,
    val searchText: String,
    val search: CatalogSearchBody?,
    val body: ExploreBody,
    val refreshing: Boolean = false,
) {
    val showsSwitcher: Boolean get() = sources.size > 1
}

/** One connected source in the switcher. */
data class ExploreSourceOption(val id: CatalogSourceId, val name: String, val selected: Boolean)

/** What Explore shows below its search field when no query is live, the first that holds. */
sealed interface ExploreBody {
    /** [rows]: the shelves there are, kept on screen while they reload. */
    data class Rows(val rows: List<ExploreRow>) : ExploreBody

    data object Loading : ExploreBody

    /** [text]: why nothing could be loaded; [ExploreStore.retry] tries again. */
    data class Failed(val text: String) : ExploreBody

    /** [text]: the source answered with nothing to show. */
    data class Empty(val text: String) : ExploreBody
}

/**
 * One Explore shelf: a fixed catalog [row], or a provider-defined hub ([providerHubId], with the provider's [style]).
 * [hub] carries the id (`explore:<source>:<row>` or `explore:<source>:hub:<hubId>`), the title, the items as catalog
 * stand-ins, the size (the provider's total when it reports one) and whether View All has more ([MediaHub.more]).
 */
data class ExploreRow(
    val hub: MediaHub,
    val icon: ExploreRowIcon,
    val row: CatalogRowId? = null,
    val providerHubId: String? = null,
    val style: CatalogHubStyle? = null,
    val totalResults: Int? = null,
)

/** The symbol a shelf's header shows. */
enum class ExploreRowIcon {
    /** Bookmark. */
    WATCHLIST,

    /** Thumb up: recommendations, suggestions and provider hubs. */
    RECOMMENDED,

    /** Trending up: trending and airing rows. */
    TRENDING,

    /** Flame: popular rows. */
    POPULAR,

    /** Upcoming event. */
    UPCOMING,
}
