package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.detail.PagedGridUi
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.MediaGrid
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens

/**
 * A pushed screen of a server's items loaded in pages: [title] with Back ([ScreenHeader])
 * over [header] (spanning the width) and the grid ([grid], a [MediaGrid]: the view mode setting's grid or list), the
 * screen's content edge at the sides. Until [settled] (the page's details and first items are in, or failed) the
 * loading indicator alone under the title; then the page at once, never built up piece by piece. The next page loads as
 * the last cards come into view ([onEnsureLoaded]), the loading indicator under the grid meanwhile; a reload's loading
 * shows there too, the header staying. The first page's error with Retry, a later page's under the loaded cards with
 * Retry ([onRetry] either), [emptyMessage] for an empty grid. A card
 * opens with [onOpen] and its menu with [onMenu]; [memory] keeps each card's focus under `item/<id>`. Up from the first
 * row reaches what [header] holds above it, then Back. Harness names of the cards: `grid.item.<index>`.
 */
@Composable
internal fun PagedGridScreen(
    title: String,
    grid: PagedGridUi,
    settled: Boolean,
    shape: CardShape,
    emptyMessage: String,
    memory: FocusMemory,
    state: LazyGridState,
    onBack: () -> Unit,
    onEnsureLoaded: (Int) -> Unit,
    onRetry: () -> Unit,
    onOpen: (MediaCardUi) -> Unit,
    modifier: Modifier = Modifier,
    onMenu: ((MediaCardUi) -> Unit)? = null,
    header: LazyGridScope.() -> Unit,
) {
    val dimens = LocalPlezyDimens.current
    Column(modifier.fillMaxSize().padding(top = statusBarOverlap)) {
        // The scroll edge once the page's first row has gone under the title: a remote's first focus, which scrolls the
        // header part way to bring the first card in, leaves a collection's backdrop behind the title.
        ScreenHeader(title, onBack = onBack, contentTitle = true, scrolled = { state.firstVisibleItemIndex > 0 })
        if (!settled) return@Column LoadingState()
        val items = grid.items
        MediaGrid(
            items.size,
            items::getOrNull,
            shape,
            PaddingValues(start = dimens.screenPadding, end = dimens.screenPadding, bottom = dimens.sectionSpacing),
            onClick = onOpen,
            state = state,
            list = LocalAppearance.current.viewMode == ViewMode.LIST,
            cardModifier = { index, card -> Modifier.rememberFocus(memory, "item/${card.id}").layoutProbe("grid.item.$index") },
            onLongClick = onMenu,
            onNearEnd = { onEnsureLoaded(items.size) },
            loadingMore = grid.moreError == null && (grid.load == SectionLoad.LOADING || grid.load == SectionLoad.CONTENT && items.size < grid.total),
            moreError = grid.moreError,
            onRetryMore = onRetry,
        ) {
            header()
            when (grid.load) {
                SectionLoad.ERROR -> item(key = "error", span = { GridItemSpan(maxLineSpan) }) {
                    Box(Modifier.fillMaxWidth().height(320.dp)) { ErrorState(grid.error.orEmpty(), onRetry = onRetry) }
                }
                SectionLoad.EMPTY -> item(key = "empty", span = { GridItemSpan(maxLineSpan) }) {
                    Box(Modifier.fillMaxWidth().height(320.dp)) { EmptyState(emptyMessage) }
                }
                SectionLoad.LOADING, SectionLoad.CONTENT -> {}
            }
        }
    }
}

/** The key of the first card of [grid], for focus to fall back on once it has loaded. */
internal fun firstCardKey(grid: PagedGridUi): String? = grid.items.firstOrNull()?.let { "item/${it.id}" }
