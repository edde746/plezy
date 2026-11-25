package com.edde746.plezy.ui.seerr

import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.seerr.SeerrPersonUiState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.detail.PagedGridScreen
import com.edde746.plezy.ui.detail.PersonHeader
import com.edde746.plezy.ui.detail.firstCardKey
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens

/** What the Seerr person page asks of its store and the app. */
class SeerrPersonIntents(
    val back: () -> Unit,
    /** Loads the page again after it failed. */
    val retry: () -> Unit,
    /** Opens a title card's catalog detail. */
    val open: (MediaCardUi) -> Unit,
)

/** A person's Seerr page ([route]) over [app]'s store. */
@Composable
fun SeerrPersonScreen(app: AppSession, route: Route.SeerrPerson, modifier: Modifier = Modifier) {
    val store = remember(app, route) { app.seerrPerson(route) } ?: return
    val state by store.state.collectAsState()
    val intents = remember(store) {
        SeerrPersonIntents(
            back = { app.navigator.back() },
            retry = store::retry,
            open = { card -> store.routeFor(card.id)?.let(app.navigator::navigate) },
        )
    }
    SeerrPersonContent(state, intents, modifier)
}

/**
 * A person's Seerr page as the library's person page ([com.edde746.plezy.ui.detail.PersonScreen]): their name with Back,
 * their photo beside what they are known for and the title count, their facts and biography (four lines, then More),
 * over the grid of their titles as Explore's catalog cards, Seerr's availability among their badges ([PagedGridScreen]).
 * The spinner alone until the first load ends; a failed load shows its error with Retry under the header. Focus starts
 * on the first title; a card opens the title's detail. Harness name `seerrPerson`.
 */
@Composable
fun SeerrPersonContent(state: SeerrPersonUiState, intents: SeerrPersonIntents, modifier: Modifier = Modifier) {
    val memory = rememberFocusMemory()
    val gridState = rememberLazyGridState()
    val posterPx = with(LocalDensity.current) { LocalPlezyDimens.current.cardWidth(CardShape.POSTER).roundToPx() }
    val grid = remember(state, posterPx) { state.grid(posterPx) }
    PagedGridScreen(
        state.name,
        grid,
        state.settled,
        CardShape.POSTER,
        T.discover.noContentAvailable,
        memory,
        gridState,
        onBack = intents.back,
        onEnsureLoaded = {},
        onRetry = intents.retry,
        onOpen = intents.open,
        modifier = modifier.layoutProbe("seerrPerson", reportsFocus = false),
    ) {
        item(key = "header", span = { GridItemSpan(maxLineSpan) }) {
            PersonHeader(state.image, state.department, state.titleCount, state.facts, state.biography, memory)
        }
    }
    RestoreFocus(memory, ready = grid.items.isNotEmpty(), fallback = firstCardKey(grid))
}
