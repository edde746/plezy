package com.edde746.plezy.ui.explore

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.explore.ExploreRowBody
import com.edde746.plezy.presentation.explore.toCatalogCard
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.catalog.CatalogMenuHost
import com.edde746.plezy.ui.catalog.CatalogMenuState
import com.edde746.plezy.ui.catalog.catalogItemOf
import com.edde746.plezy.ui.catalog.rememberCatalogCardActions
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.MediaGrid
import com.edde746.plezy.ui.home.ViewAllSort
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.gridTop
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import kotlin.time.Clock

/**
 * An Explore shelf's View All ([route]): its title, with its Sort as a hub's View all has it, over every item of the
 * shelf as a grid, the shelf's own items while the rest load; the failure with Retry, or the empty state. A card opens
 * its title's detail, a long press its menu. Harness names: `exploreRow.*`.
 */
@Composable
fun ExploreRowScreen(app: AppSession, route: Route.ExploreRow, modifier: Modifier = Modifier) {
    val store = remember(app, route) { app.exploreRow(route) } ?: return
    val state by store.state.collectAsState()
    val appearance = LocalAppearance.current
    val actions = rememberCatalogCardActions(app)
    val menu = remember { CatalogMenuState() }
    var message by remember { mutableStateOf<String?>(null) }
    val posterPx = with(LocalDensity.current) { POSTER_WIDTH.roundToPx() }
    val memory = rememberFocusMemory()
    val touch = LocalInputModeManager.current.inputMode == InputMode.Touch
    CatalogMenuHost(menu, actions, onMessage = { message = it }, modifier.fillMaxSize().layoutProbe("exploreRow", reportsFocus = false)) {
        val grid = rememberLazyGridState()
        Column(Modifier.fillMaxSize().padding(top = statusBarOverlap)) {
            ScreenHeader(state.title, onBack = if (appearance.tv) null else ({ app.navigator.back() }), contentTitle = true, titleLines = 2, scrolled = { grid.canScrollBackward }) {
                ViewAllSort(state.sortChoices, state.sort, state.descending, store::pickSort, "exploreRow.sort")
            }
            Box(Modifier.fillMaxSize()) {
                when (val body = state.body) {
                    is ExploreRowBody.Failed -> ErrorState(body.text, onRetry = store::retry)
                    is ExploreRowBody.Empty -> EmptyState(body.text, icon = PlezyIcons.Explore)
                    // The page shows once every item is in, not the shelf's few first and the rest after.
                    is ExploreRowBody.Items -> if (body.loading) {
                        LoadingState()
                    } else {
                        val now = remember(body) { Clock.System.now() }
                        val cards = remember(body, posterPx) { body.items.mapNotNull { it.toCatalogCard(now, posterPx, 0) } }
                        val dimens = LocalPlezyDimens.current
                        MediaGrid(
                            cards.size,
                            cards::getOrNull,
                            CardShape.POSTER,
                            PaddingValues(start = dimens.screenPadding, end = dimens.screenPadding, top = dimens.gridTop, bottom = dimens.sectionSpacing),
                            state = grid,
                            onClick = { card -> body.items.catalogItemOf(card.id)?.let(actions.open) },
                            cardModifier = { _, card -> Modifier.rememberFocus(memory, card.id).then(menu.cardModifier(card.id)) },
                            onLongClick = { card -> body.items.catalogItemOf(card.id)?.let { menu.open(it, card.id) } },
                        )
                        // On TV, or once keys are in use, focus starts on the first card (as Discover's grid).
                        RestoreFocus(memory, ready = true, fallback = cards.firstOrNull()?.id?.takeIf { appearance.tv || !touch })
                    }
                }
            }
        }
        message?.let { text ->
            TimedToast(text, "exploreRow.message", onShown = { message = null }, Modifier.align(Alignment.BottomCenter).padding(bottom = 24.dp))
        }
    }
}
