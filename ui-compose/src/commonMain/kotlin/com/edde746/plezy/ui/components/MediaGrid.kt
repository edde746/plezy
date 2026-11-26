package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridItemInfo
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.LocalPlatformContext
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.layout.GridLayout
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.LocalArtworkDisplay
import com.edde746.plezy.ui.image.prefetchImage
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.PlezyDimens
import coil3.request.Disposable
import kotlin.math.ceil

/**
 * The app's grid of items; every grid of cards is one. [count] cells, [card] each, as [PosterCard]s of [shape] in the
 * columns [mediaGridCells] gives (the library density setting), the gutter between them, [padding] around the grid,
 * scrolled by [state]. With [list] they are the library's list instead: one column of [MediaRow]s at the density. A cell
 * whose card is null (its page not loaded yet) is a [BlankCard] (a blank row in the list), and [onMissing] comes with its
 * index once it shows. Each card tells screen readers its row and column ("Row 2 of 5, column 3 of 4").
 *
 * [header] goes above the cards; under them, while [loadingMore] the loading indicator, or with [moreError] the error
 * with Retry ([onRetryMore]) ([MoreFooter]). [onNearEnd] comes as the last cards come into view, once for each [count].
 * [cardModifier] goes on each card or row (given its index); [onClick] and [onLongClick] are its press and long press.
 * After each move the posters of the two rows past the last shown cell are fetched at the cells' size.
 */
@Composable
fun MediaGrid(
    count: Int,
    card: (Int) -> MediaCardUi?,
    shape: CardShape,
    padding: PaddingValues,
    onClick: (MediaCardUi) -> Unit,
    modifier: Modifier = Modifier,
    state: LazyGridState = rememberLazyGridState(),
    appearance: Appearance = LocalAppearance.current,
    list: Boolean = false,
    cardModifier: (index: Int, card: MediaCardUi) -> Modifier = { _, _ -> Modifier },
    onLongClick: ((MediaCardUi) -> Unit)? = null,
    onMissing: (Int) -> Unit = {},
    onNearEnd: (() -> Unit)? = null,
    loadingMore: Boolean = false,
    moreError: String? = null,
    onRetryMore: () -> Unit = {},
    header: LazyGridScope.() -> Unit = {},
) {
    val dimens = LocalPlezyDimens.current
    // A plain state set only when the count changes: the items read it, and a read of layoutInfo (or a state derived
    // from it) would schedule every card's composition on each frame the grid scrolls.
    var columns by remember(state) { mutableIntStateOf(1) }
    LaunchedEffect(state) { snapshotFlow { state.layoutInfo.maxSpan.coerceAtLeast(1) }.collect { columns = it } }
    val cardText = rememberCardText()
    LazyVerticalGrid(
        columns = if (list) GridCells.Fixed(1) else mediaGridCells(shape, appearance),
        state = state,
        contentPadding = padding,
        horizontalArrangement = Arrangement.spacedBy(dimens.gutter),
        verticalArrangement = Arrangement.spacedBy(if (list) GroupGap else dimens.gutter),
        modifier = modifier.fillMaxSize(),
    ) {
        header()
        items(
            count,
            key = { index -> card(index)?.let { "${it.id}$CELL$index" } ?: "$SLOT$index" },
            contentType = { index -> if (card(index) == null) BLANK else CARD },
        ) { index ->
            val item = card(index)
            when {
                item == null -> if (list) Box(Modifier.fillMaxWidth().height(rowArtworkWidth(shape) / shape.aspectRatio + RowInset * 2)) else BlankCard(shape, Modifier.fillMaxWidth())
                list -> MediaRow(
                    item,
                    onClick = { onClick(item) },
                    modifier = cardModifier(index, item),
                    shape = shape,
                    density = appearance.libraryDensity,
                    onLongClick = onLongClick?.let { { it(item) } },
                )
                // One text measurer for every card's labels, and their reserved line heights measured once.
                else -> CompositionLocalProvider(LocalCardText provides cardText) {
                    PosterCard(
                        item,
                        onClick = { onClick(item) },
                        modifier = cardModifier(index, item).fillMaxWidth(),
                        shape = shape,
                        onLongClick = onLongClick?.let { { it(item) } },
                        position = position(index, count, columns),
                        titleLines = GridLayout.titleLines(appearance.libraryDensity),
                    )
                }
            }
        }
        if (loadingMore || moreError != null) {
            item(key = "more", span = { GridItemSpan(maxLineSpan) }, contentType = MORE) { MoreFooter(moreError, onRetryMore) }
        }
    }
    val missing by rememberUpdatedState(onMissing)
    LaunchedEffect(state) {
        snapshotFlow { state.layoutInfo.visibleItemsInfo.filter { it.contentType == BLANK }.mapNotNull { it.cell() } }
            .collect { blanks -> blanks.forEach { missing(it) } }
    }
    if (onNearEnd != null) {
        val nearEnd by rememberUpdatedState(onNearEnd)
        LaunchedEffect(state, count) {
            snapshotFlow {
                val info = state.layoutInfo
                (info.visibleItemsInfo.lastOrNull()?.index ?: -1) >= info.totalItemsCount - NEAR_END_CARDS
            }.collect { if (it) nearEnd() }
        }
    }
    if (!list) PrefetchPosters(state, card, shape)
}

/** Under a paged grid: the loading indicator while its next page comes, or why it failed ([error]) with Retry. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun MoreFooter(error: String?, onRetry: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier.fillMaxWidth().padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (error == null) {
            LoadingIndicator(Modifier.size(40.dp))
        } else {
            Text(error, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
            PlezyButton(T.common.retry, onRetry, Modifier.layoutProbe("grid.retry"), style = ButtonStyle.PRIMARY, icon = PlezyIcons.Refresh)
        }
    }
}

/**
 * A media grid's columns at the density setting: as many as fit, each at least its card width for [shape]; on TV as few
 * as keep each at most its card width ([PlezyDimens.gridCardMaxWidth]), which fills a TV screen with more cards.
 */
@Composable
fun mediaGridCells(shape: CardShape, appearance: Appearance): GridCells {
    val dimens = LocalPlezyDimens.current
    val density = appearance.libraryDensity
    return dimens.gridCardMaxWidth(shape, density)?.let(::AtMostCells) ?: GridCells.Adaptive(dimens.gridCardWidth(shape, density))
}

/** Columns at most [width] wide: the grid's width over the width with a gap after it, rounded up. */
private data class AtMostCells(val width: Dp) : GridCells {
    override fun Density.calculateCrossAxisCellSizes(availableSize: Int, spacing: Int): List<Int> {
        val count = ceil(availableSize / (width.toPx() + spacing)).toInt().coerceAtLeast(1)
        val cells = (availableSize - spacing * (count - 1)).coerceAtLeast(0)
        return List(count) { cells / count + if (it < cells % count) 1 else 0 }
    }
}

/** Where cell [index] of [count] sits for screen readers: "Row 2 of 5, column 3 of 4" ("Row 2 of 5" in one column). */
private fun position(index: Int, count: Int, columns: Int): String {
    val rows = ((count + columns - 1) / columns).toString()
    val row = (index / columns + 1).toString()
    return if (columns == 1) T.accessibility.rowPosition(row, rows) else T.accessibility.rowColumnPosition(row, rows, (index % columns + 1).toString(), columns.toString())
}

/** A cell's own index (the grid's counts the header's items too), from its key; null for the header and footer. */
private fun LazyGridItemInfo.cell(): Int? = (key as? String)?.let { key ->
    when {
        key.startsWith(SLOT) -> key.removePrefix(SLOT).toIntOrNull()
        CELL in key -> key.substringAfterLast(CELL).toIntOrNull()
        else -> null
    }
}

/**
 * After each move of [grid] the posters of the two rows past its last shown cell, fetched at a card's artwork size in
 * pixels; the shown cards load their own. A fetch still going when its poster leaves those rows (it shows, or the grid
 * moved past it) or the grid leaves is cancelled, so it never queues ahead of the posters on screen.
 */
@Composable
private fun PrefetchPosters(grid: LazyGridState, card: (Int) -> MediaCardUi?, shape: CardShape) {
    val context = LocalPlatformContext.current
    val display = LocalArtworkDisplay.current
    val density = LocalDensity.current.density
    val cards by rememberUpdatedState(card)
    LaunchedEffect(grid, shape) {
        // The rows ahead's posters asked for, by key, done or not.
        val asked = HashMap<String, Disposable>()
        try {
            snapshotFlow {
                val info = grid.layoutInfo
                val cells = info.visibleItemsInfo.filter { it.contentType == CARD || it.contentType == BLANK }
                val sized = cells.firstOrNull { it.contentType == CARD } ?: return@snapshotFlow null
                val last = cells.last().cell() ?: return@snapshotFlow null
                // The cards too: a page that loads brings posters to fetch without a move.
                Shown(last + 1..last + 2 * info.maxSpan, sized.size.width, (sized.size.width / shape.aspectRatio).toInt(), cards)
            }.collect { shown ->
                if (shown == null || shown.width <= 0 || shown.height <= 0) return@collect
                val ahead = shown.range.mapNotNull { shown.cards(it)?.artwork }.associateBy { it.key }
                asked.entries.removeAll { (key, fetch) -> (key !in ahead).also { gone -> if (gone) fetch.dispose() } }
                for ((key, artwork) in ahead) {
                    if (key !in asked) asked[key] = prefetchImage(context, artwork, display, density, shown.width, shown.height)
                }
            }
        } finally {
            asked.values.forEach { it.dispose() }
        }
    }
}

private class Shown(val range: IntRange, val width: Int, val height: Int, val cards: (Int) -> MediaCardUi?) {
    override fun equals(other: Any?) = other is Shown && range == other.range && width == other.width && height == other.height && cards === other.cards

    override fun hashCode() = range.hashCode()
}

/** How many items from a grid's end [MediaGrid]'s `onNearEnd` comes. */
private const val NEAR_END_CARDS = 12

/** The cells' content types: a card or row, a cell still loading, the footer. */
private const val CARD = 1
private const val BLANK = 0
private const val MORE = 2

/** A cell's key: its card's id and its index (an item may be at two places), or a blank cell's index. */
private const val CELL = "@"
private const val SLOT = "slot-"
