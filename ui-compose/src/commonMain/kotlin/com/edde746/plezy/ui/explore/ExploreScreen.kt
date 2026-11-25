package com.edde746.plezy.ui.explore

import androidx.compose.foundation.focusGroup
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.focusProperties
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.explore.CatalogSearchBody
import com.edde746.plezy.presentation.explore.ExploreBody
import com.edde746.plezy.presentation.explore.ExploreRow
import com.edde746.plezy.presentation.explore.ExploreUiState
import com.edde746.plezy.presentation.explore.toCatalogCard
import com.edde746.plezy.presentation.explore.toHubUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.catalog.CatalogCardActions
import com.edde746.plezy.ui.catalog.CatalogMenuHost
import com.edde746.plezy.ui.catalog.CatalogMenuState
import com.edde746.plezy.ui.catalog.catalogItemOf
import com.edde746.plezy.ui.catalog.rememberCatalogCardActions
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.FilterChip
import com.edde746.plezy.ui.components.HeaderScaffold
import com.edde746.plezy.ui.components.HubRow
import com.edde746.plezy.ui.components.ScrimWhileScrolled
import com.edde746.plezy.ui.components.SearchField
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.MediaRow
import com.edde746.plezy.ui.components.MenuChip
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.TouchPullToRefresh
import com.edde746.plezy.ui.components.rememberShelfNavigation
import com.edde746.plezy.ui.components.shelfSpacing
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.CatalogSourceLogo
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.clipToNavigation
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import kotlin.time.Clock

/** What the Explore screen asks of its store and the app. */
class ExploreIntents(
    val selectSource: (CatalogSourceId) -> Unit,
    val setSearchText: (String) -> Unit,
    /** The keyboard's search action; true when focus should move to the results shown. */
    val submitSearch: () -> Boolean,
    val refresh: () -> Unit,
    val retry: () -> Unit,
    /** TV's Search: the active source's search screen. */
    val openSearch: (CatalogSourceId) -> Unit,
    val openViewAll: (ExploreRow) -> Unit,
)

/** Explore over [app]'s store: loads what is missing or stale each time it is shown. */
@Composable
fun ExploreScreen(app: AppSession, modifier: Modifier = Modifier) {
    val store = remember(app) { app.explore(Route.Explore) } ?: return
    val state by store.state.collectAsState()
    LaunchedEffect(store) { store.ensureFresh() }
    val intents = remember(store) {
        ExploreIntents(
            selectSource = store::selectSource,
            setSearchText = store::setSearchText,
            submitSearch = store::submitSearch,
            refresh = store::refresh,
            retry = store::retry,
            openSearch = { app.navigator.navigate(Route.CatalogSearch(it)) },
            openViewAll = { app.navigator.navigate(Route.ExploreRow(it.hub.id, it.hub.title)) },
        )
    }
    ExploreContent(state, intents, rememberCatalogCardActions(app), modifier)
}

/**
 * Explore: its header row ([HeaderScaffold]) in every state: one line of chips ([FilterRow]: the
 * source switcher first, then on TV Search and Refresh), off TV the inline search field under it; then the active source's shelves
 * ([HubRow], View All in the heading or as the row's last card for the remote and the keyboard), or the search's
 * results in their place while the field holds text. Loading, the error with Retry or the empty state take the shelves'
 * place. A pull refreshes on a touch screen, Ctrl+R everywhere. A card opens its title's detail; a long press its menu.
 * Harness names: `explore.*`.
 *
 * Focus as Explore comes on view (wherever keys are in use, and on TV): with a search on, its first result, else the
 * field (never the field while results show: the keyboard would rise over them); otherwise the shelf card it had, else
 * the first shelf's first card.
 */
@Composable
fun ExploreContent(state: ExploreUiState, intents: ExploreIntents, actions: CatalogCardActions, modifier: Modifier = Modifier) {
    val appearance = LocalAppearance.current
    val dimens = LocalPlezyDimens.current
    val memory = rememberFocusMemory()
    val menu = remember { CatalogMenuState() }
    var message by remember { mutableStateOf<String?>(null) }
    val density = LocalDensity.current
    val posterPx = with(density) { POSTER_WIDTH.roundToPx() }
    val backdropPx = with(density) { LocalWindowSize.current.value.width.roundToPx() }
    val now = remember(state) { Clock.System.now() }
    val rows = (state.body as? ExploreBody.Rows)?.rows.orEmpty()
    val hubs = remember(rows, posterPx, backdropPx) { rows.map { it.toHubUi(now, posterPx, backdropPx) } }
    val shelfItems = remember(rows) { rows.flatMap { it.hub.items } }
    val open = { items: List<MediaItem>, id: String -> items.catalogItemOf(id)?.let(actions.open) }
    val openMenu = { items: List<MediaItem>, id: String -> items.catalogItemOf(id)?.let { menu.open(it, id) } }
    val list = rememberLazyListState()
    val first = hubs.firstOrNull()?.let { hub -> hub.items.firstOrNull()?.let { cardKey(hub, it.id) } }
    CatalogMenuHost(
        menu,
        actions,
        onMessage = { message = it },
        modifier
            .fillMaxSize()
            .layoutProbe("explore", reportsFocus = false)
            .onPreviewKeyEvent { event ->
                val refresh = event.type == KeyEventType.KeyDown && event.isCtrlPressed && event.key == Key.R
                if (refresh) intents.refresh()
                refresh
            },
    ) {
        // Focus sent into the screen from outside by keys (the navigation opening it) goes to the first card, not the
        // filter row's first chip; while the shelves load it waits for them ([RestoreFocus] brings it). A click or a
        // tap goes where it lands: the field it was on takes the typing.
        val inputModes = LocalInputModeManager.current
        HeaderScaffold(
            filters = { padding, _ ->
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    // Off TV with one source the row would be empty: the field names the source.
                    if (appearance.tv || state.showsSwitcher) FilterRow(state, intents, memory, padding)
                    if (!appearance.tv) {
                        SearchField(
                            state.searchText,
                            state.searchHint,
                            // Typing is the user's: focus Explore placed on the field stays there as results come.
                            onText = {
                                memory.endPlacement()
                                intents.setSearchText(it)
                            },
                            onSubmit = intents.submitSearch,
                            probe = "explore.search",
                            clearProbe = "explore.search.clear",
                            modifier = Modifier.padding(padding),
                            fieldModifier = Modifier.rememberFocus(memory, SEARCH_FIELD_KEY),
                        )
                    }
                }
            },
            modifier = Modifier.focusProperties {
                onEnter = {
                    if (requestedFocusDirection == FocusDirection.Enter && state.search == null && inputModes.inputMode != InputMode.Touch) {
                        if (first != null) memory.focus(first) else if (state.body == ExploreBody.Loading) cancelFocusChange()
                    }
                }
            }.focusGroup(),
        ) {
            // Only while a list shows: a list state left behind keeps its last scroll.
            if (state.search != null || state.body is ExploreBody.Rows) ScrimWhileScrolled { list.canScrollBackward }
            val navigation = rememberShelfNavigation(list)
            TouchPullToRefresh(state.refreshing, intents.refresh, Modifier.fillMaxSize()) {
                val search = state.search
                val body = state.body
                when {
                    search != null -> LazyColumn(Modifier.fillMaxSize().layoutProbe("explore.list", reportsFocus = false), state = list) {
                        searchResults(search, { items, id -> open(items, id) }, { items, id -> openMenu(items, id) }) { Modifier.rememberFocus(memory, resultKey(it)) }
                    }
                    body !is ExploreBody.Rows -> BodyState(body, intents.retry)
                    else -> LazyColumn(
                        Modifier.fillMaxSize().then(navigation.modifier).layoutProbe("explore.list", reportsFocus = false),
                        state = list,
                        contentPadding = PaddingValues(top = 8.dp, bottom = dimens.sectionSpacing),
                        verticalArrangement = Arrangement.spacedBy(dimens.shelfSpacing),
                    ) {
                        itemsIndexed(hubs, key = { _, hub -> hub.id }) { index, hub ->
                            HubRow(
                                hub,
                                appearance,
                                navigation.item(index),
                                cardModifier = { card -> Modifier.rememberFocus(memory, cardKey(hub, card.id)).then(menu.cardModifier(card.id)) },
                                seeAllModifier = Modifier.rememberFocus(memory, "seeAll:${hub.id}"),
                                onCardClick = { open(shelfItems, it.id) },
                                onCardLongClick = { openMenu(shelfItems, it.id) },
                                onViewAll = { rows.firstOrNull { it.hub.id == hub.id }?.let(intents.openViewAll) },
                            )
                        }
                    }
                }
            }
        }
        message?.let { text ->
            TimedToast(text, "explore.message", onShown = { message = null }, Modifier.align(Alignment.BottomCenter).padding(bottom = LocalPlezyDimens.current.sectionSpacing))
        }
    }
    // As Home: in touch mode no focus is placed (a focused card would keep itself in view as the window changes); a
    // key press leaves touch mode and focus comes. The search is the inline one off TV.
    val touch = LocalInputModeManager.current.inputMode == InputMode.Touch
    val search = state.search.takeIf { !appearance.tv }
    val firstResult = (search as? CatalogSearchBody.Results)?.items?.firstOrNull()?.let(::resultKey)
    val fallback = if (search != null) firstResult ?: SEARCH_FIELD_KEY else first
    RestoreFocus(
        memory,
        ready = search != null || first != null,
        fallback = fallback.takeIf { appearance.tv || !touch },
        // A search's results take focus on the first one, the field only while there are none; the shelves from memory.
        remembered = { if (search != null) firstResult == null else it != SEARCH_FIELD_KEY },
    )
}

private fun cardKey(hub: HubUi, id: String) = "${hub.id}/$id"

/** The focus key of a search result's row. */
private fun resultKey(item: MediaItem): String = "result/${item.id}"

/** The focus key of the inline search field. */
private const val SEARCH_FIELD_KEY = "search"

/**
 * Explore's one line of chips, as Discover's filter row: the source switcher ([MenuChip] of the connected sources, each
 * with its logo, the active one selected; its chip names the active source) where two or more are connected, then on
 * TV Search (the active source's search screen) and Refresh. It scrolls sideways when it doesn't fit, from the header
 * row's [padding]. Harness names: `explore.switcher` (its options `explore.switcher.option.<i>`), `explore.openSearch`,
 * `explore.refresh`.
 */
@Composable
private fun FilterRow(state: ExploreUiState, intents: ExploreIntents, memory: FocusMemory, padding: PaddingValues) {
    val tv = LocalAppearance.current.tv
    val active = state.sources.firstOrNull { it.selected }
    LazyRow(
        contentPadding = padding,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().clipToNavigation().focusRestorer().focusGroup().layoutProbe("explore.filters", reportsFocus = false),
    ) {
        if (state.showsSwitcher) {
            item(key = "source") {
                MenuChip(
                    FilterChip(name = T.explore.selectSource, text = active?.name ?: state.title, spoken = "${T.explore.selectSource}: ${active?.name ?: state.title}"),
                    choices = state.sources.map { source ->
                        MenuChoice(source.name, source.selected, leading = { CatalogSourceLogo(source.id, Modifier.testTag("explore.sourceLogo.${source.id.id}"), size = 22.dp) })
                    },
                    onPick = { intents.selectSource(state.sources[it].id) },
                    probe = "explore.switcher",
                    modifier = Modifier.rememberFocus(memory, "filter:source"),
                )
            }
        }
        if (tv && active != null) {
            item(key = "search") {
                PlezyChip(T.common.search, false, { intents.openSearch(active.id) }, Modifier.rememberFocus(memory, "filter:search").layoutProbe("explore.openSearch"), leadingIcon = PlezyIcons.Search)
            }
        }
        if (tv) {
            item(key = "refresh") {
                PlezyChip(T.common.refresh, false, intents.refresh, Modifier.rememberFocus(memory, "filter:refresh").layoutProbe("explore.refresh"), leadingIcon = PlezyIcons.Refresh)
            }
        }
    }
}

/** The inline search's state in place of the shelves: nothing before the first search, then its results as a list. */
private fun LazyListScope.searchResults(
    search: CatalogSearchBody,
    open: (List<MediaItem>, String) -> Unit,
    openMenu: (List<MediaItem>, String) -> Unit,
    result: (MediaItem) -> Modifier,
) {
    when (search) {
        is CatalogSearchBody.Idle -> Unit
        CatalogSearchBody.Loading -> item(key = "searching") { LoadingState(Modifier.fillParentMaxHeight(0.6f)) }
        is CatalogSearchBody.Failed -> item(key = "searchFailed") { EmptyState(search.text, Modifier.fillParentMaxHeight(0.6f), icon = PlezyIcons.ErrorOutline) }
        is CatalogSearchBody.Empty -> item(key = "searchEmpty") { EmptyState(search.text, Modifier.fillParentMaxHeight(0.6f), icon = PlezyIcons.Search) }
        is CatalogSearchBody.Results -> catalogResults(search.items, open, openMenu, result)
    }
}

/**
 * Catalog search results as list rows ([MediaRow]), their fill at the screen's edges as the search field's (Search's
 * rows alike); a row opens its title's detail, a long press its menu. [result] goes on each row (its focus memory).
 */
internal fun LazyListScope.catalogResults(
    items: List<MediaItem>,
    open: (List<MediaItem>, String) -> Unit,
    openMenu: (List<MediaItem>, String) -> Unit,
    result: (MediaItem) -> Modifier = { Modifier },
) {
    items(items, key = { "result/${it.id}" }) { item ->
        val density = LocalDensity.current
        val card = remember(item) { item.toCatalogCard(Clock.System.now(), with(density) { POSTER_WIDTH.roundToPx() }, 0) } ?: return@items
        MediaRow(
            card,
            onClick = { open(items, item.id) },
            modifier = Modifier.padding(horizontal = LocalPlezyDimens.current.screenPadding).then(result(item)),
            shape = CardShape.POSTER,
            density = LocalAppearance.current.libraryDensity,
            onLongClick = { openMenu(items, item.id) },
        )
    }
}

/** Loading, failed (with Retry) or empty: Explore without shelves. */
@Composable
private fun BodyState(body: ExploreBody, onRetry: () -> Unit) {
    when (body) {
        is ExploreBody.Rows -> Unit
        ExploreBody.Loading -> LoadingState()
        is ExploreBody.Failed -> ErrorState(body.text, onRetry = onRetry)
        is ExploreBody.Empty -> EmptyState(body.text, icon = PlezyIcons.Explore)
    }
}

/** The width the cards' posters are asked for. */
internal val POSTER_WIDTH = 200.dp
