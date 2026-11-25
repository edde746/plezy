package com.edde746.plezy.ui.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.layout.onPlaced
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.MenuOption
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.home.HomeStore
import com.edde746.plezy.presentation.layout.hubShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ChoiceMenu
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.MediaGrid
import com.edde746.plezy.ui.components.gridTop
import com.edde746.plezy.ui.menu.toChoice
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.settings.ViewMode
import kotlinx.coroutines.launch

/**
 * A hub's View all ([Route.HubDetail]): its title with Sort, then every item as the library grid lays it out, the rest
 * loading after the preview; a hub that pages lazily loads its next page once its last card is laid out. A failed first
 * load shows the error with Retry, a failed later page a Retry under the grid. Continue Watching's cards play
 * directly. Harness name `hubDetail`. Focus as [HubDetailLayout] moves it.
 */
@Composable
fun HubDetailScreen(app: AppSession, route: Route.HubDetail, modifier: Modifier = Modifier) {
    val store = remember(app, route) { app.hubDetail(route) } ?: return
    val state by store.state.collectAsState()
    val appearance = LocalAppearance.current
    val playDirectly = route.hubId == HomeStore.CONTINUE_WATCHING_ID
    HubDetailLayout(
        state.title,
        state.cards,
        sort = state.sort?.key to state.descending,
        onBack = { app.navigator.back() },
        modifier = modifier,
        actions = { firstAction ->
            ViewAllSort(state.sortChoices, state.sort, state.descending, store::pickSort, "hubDetail.sort", Modifier.focusRequester(firstAction))
        },
    ) { grid, cardFocus ->
        when {
            !state.settled -> LoadingState()
            state.error != null && state.items.isEmpty() -> ErrorState(state.error.orEmpty(), onRetry = store::retry)
            state.items.isEmpty() && state.loading -> LoadingState()
            state.items.isEmpty() -> EmptyState(T.hubDetail.noItemsFound)
            else -> {
                val cards = state.cards
                MediaGrid(
                    cards.size,
                    cards::getOrNull,
                    remember(cards, appearance.episodeThumbnails) { hubShape(cards.map { it.shape }, appearance.episodeThumbnails) },
                    hubGridPadding(),
                    onClick = { card -> store.item(card.id)?.let { app.mediaActions.open(it, playDirectly) } },
                    state = grid,
                    // The library's view mode: its list, else its grid.
                    list = appearance.viewMode == ViewMode.LIST,
                    cardModifier = { _, card -> cardFocus(card) },
                    onLongClick = { card -> store.item(card.id)?.let { app.mediaActions.menu.open(it, MenuPlace(continueWatching = playDirectly)) } },
                    onNearEnd = store::nearEnd,
                    loadingMore = state.pageLoading,
                    moreError = T.errors.unableToLoad(state.title).takeIf { state.pageFailed },
                    onRetryMore = store::retryPage,
                )
            }
        }
    }
    CopyPickerSheet(app)
}

/**
 * The hub grid's padding: the screen's content edge at the sides, room for a focused card's
 * growth (TV) at the top, room under the last row for the page spinner or Retry.
 */
@Composable
internal fun hubGridPadding(): PaddingValues {
    val dimens = LocalPlezyDimens.current
    return PaddingValues(start = dimens.screenPadding, end = dimens.screenPadding, top = dimens.gridTop, bottom = 72.dp)
}

/**
 * A View all's Sort (a hub's, an Explore shelf's) at its header's end: a chip of the header chips' height (Libraries'
 * sort chip's, on every idiom) naming the
 * order in effect after its direction's arrow (Sort and the sort icon while the page keeps its own order), read as
 * "Sort By: <order>". It keeps that form beside any title: a long title wraps instead ([ScreenHeader]'s `titleLines`).
 * It opens [choices] (their icons, their groups' headings), [onPick] taking one's index. Harness name [probe].
 */
@Composable
internal fun ViewAllSort(
    choices: List<MenuOption>,
    sort: MediaSort?,
    descending: Boolean,
    onPick: (Int) -> Unit,
    probe: String,
    modifier: Modifier = Modifier,
) {
    var open by remember { mutableStateOf(false) }
    val icon = when {
        sort == null -> PlezyIcons.Sort
        descending -> PlezyIcons.ArrowDownward
        else -> PlezyIcons.ArrowUpward
    }
    Box {
        PlezyChip(
            sort?.title ?: T.libraries.sort,
            selected = false,
            onClick = { open = true },
            modifier = modifier
                .semantics { contentDescription = sort?.let { "${T.libraries.sortBy}: ${it.title}" } ?: T.libraries.sort }
                .layoutProbe(probe),
            dropdown = true,
            leadingIcon = icon,
        )
        ChoiceMenu(expanded = open, onDismiss = { open = false }, title = T.libraries.sort, choices = choices.map { it.toChoice() }, onPick = onPick, probe = probe)
    }
}

/**
 * The hub detail's frame: the header ([title], the back arrow, [actions], whose first takes `firstAction`'s focus) over
 * [content], which lays [cards] out on the grid state it is given, each card under its `cardFocus`.
 *
 * Focus under a keyboard or remote: it starts on the first card (not in touch mode, as Home). Back with focus in the grid
 * moves it to the first action and the grid to its top; Back again, or the arrow, leaves. Down from the header goes to
 * the card that had focus while it is still laid out, else to the first. A new [sort] brings the grid back to its top.
 */
@Composable
internal fun HubDetailLayout(
    title: String,
    cards: List<MediaCardUi>,
    sort: Any?,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    actions: @Composable RowScope.(firstAction: FocusRequester) -> Unit,
    content: @Composable BoxScope.(grid: LazyGridState, cardFocus: (MediaCardUi) -> Modifier) -> Unit,
) {
    val memory = rememberFocusMemory()
    val grid = rememberLazyGridState()
    val scope = rememberCoroutineScope()
    val firstAction = remember { FocusRequester() }
    val first = cards.firstOrNull()?.id
    var inGrid by remember { mutableStateOf(false) }
    val touch = LocalInputModeManager.current.inputMode == InputMode.Touch
    var shownSort by remember { mutableStateOf(sort) }
    LaunchedEffect(sort) {
        if (sort == shownSort) return@LaunchedEffect
        shownSort = sort
        grid.scrollToItem(0)
    }
    SystemBackHandler(enabled = inGrid && !touch) {
        firstAction.requestFocus()
        scope.launch { grid.scrollToItem(0) }
    }
    Column(modifier.fillMaxSize().layoutProbe("hubDetail", reportsFocus = false)) {
        ScreenHeader(
            title,
            Modifier
                .padding(top = statusBarOverlap)
                .onPreviewKeyEvent { event ->
                    event.type == KeyEventType.KeyDown && event.key == Key.DirectionDown && memory.restore(first)
                },
            onBack = onBack,
            scrolled = { grid.canScrollBackward },
            // A long title wraps beside the Sort chip, which keeps its label.
            titleLines = 2,
        ) { actions(firstAction) }
        Box(Modifier.fillMaxSize().onFocusChanged { inGrid = it.hasFocus }) {
            content(grid) { card -> Modifier.rememberFocus(memory, card.id) }
        }
    }
    RestoreFocus(memory, ready = first != null, fallback = first?.takeIf { !touch })
}
