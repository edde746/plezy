package com.edde746.plezy.ui.search

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import com.edde746.plezy.ui.components.ScrollRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isAltPressed
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isMetaPressed
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.search.SearchPhase
import com.edde746.plezy.presentation.search.SearchResultUi
import com.edde746.plezy.presentation.search.SearchStore
import com.edde746.plezy.presentation.search.SearchUiState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.largeFontScale
import com.edde746.plezy.ui.components.ArtworkRow
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.HeaderScaffold
import com.edde746.plezy.ui.components.MediaRow
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.RowInset
import com.edde746.plezy.ui.components.SearchField
import com.edde746.plezy.ui.components.ScrimWhileScrolled
import com.edde746.plezy.ui.components.SectionTitle
import com.edde746.plezy.ui.components.SourceLine
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.rowArtworkWidth
import com.edde746.plezy.ui.detail.PersonPhoto
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import kotlinx.coroutines.flow.filter

/**
 * Search across the servers ([Route.Search]): its header row ([HeaderScaffold]) holds the search field
 * ([SearchField]: focused as the screen opens, and when asked for:
 * [com.edde746.plezy.presentation.search.SearchStore.focusField]; on TV the keyboard waits for Select, and its Search
 * moves focus to the first result) with Clear once it holds text and the loading indicator while a search runs, and
 * under it the kind chips when the
 * results span several kinds, then the results, under All in groups headed by their kind (Movies, Shows, People…):
 * titles as list rows (selecting one does what selecting the title does
 * anywhere, a long press its menu), people as rows with a round photo (selecting opens their titles). Before a search,
 * what to search for; while one runs with nothing to show, the spinner; then no results, or the failure with Retry.
 * Partial or failed searches say so in a toast. Harness names `search.field`, `search.clear`, `search.filter.<i>`,
 * `search.group.<i>` (a heading), `search.result.<i>` (counted across the groups), `search.retry`.
 */
@Composable
fun SearchScreen(app: AppSession, modifier: Modifier = Modifier) {
    val store = remember(app) { app.search(Route.Search) } ?: return
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    val list = rememberLazyListState()
    var toast by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(store) { store.messages.collect { toast = it } }
    val first by rememberUpdatedState(state.results.firstOrNull()?.let(::resultKey))
    LaunchedEffect(store) {
        store.focusFirstResult.collect {
            list.scrollToItem(0)
            repeat(FIRST_RESULT_FRAMES) {
                withFrameNanos { }
                if (first?.let(memory::focus) == true) return@collect
            }
        }
    }
    // Ctrl+F: the field, once it is composed.
    LaunchedEffect(store) {
        store.fieldFocusRequests.collect {
            repeat(FIRST_RESULT_FRAMES) {
                withFrameNanos { }
                if (memory.focus(FIELD_KEY)) return@collect
            }
        }
    }
    // Search picked again while it shows: the field takes focus.
    LaunchedEffect(app) {
        app.navigator.reselected.filter { it == TopLevelDestination.SEARCH }.collect { memory.focus(FIELD_KEY) }
    }
    val desktop = LocalWindowLayout.current.formFactor == FormFactor.DESKTOP
    // The desktop's refresh chord (Ctrl+R, Cmd+R on a Mac) runs the query on screen again.
    val refreshChord = Modifier.onPreviewKeyEvent { event ->
        val chord = desktop && event.type == KeyEventType.KeyDown && event.key == Key.R && !event.isShiftPressed && !event.isAltPressed &&
            event.isCtrlPressed != event.isMetaPressed
        if (chord) store.refresh()
        chord
    }
    val tv = LocalAppearance.current.tv
    Box(modifier.fillMaxSize().then(refreshChord).layoutProbe("search", reportsFocus = false)) {
        HeaderScaffold(
            filters = { padding, _ ->
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    SearchField(
                        state.query,
                        T.search.hint,
                        onText = store::setQuery,
                        // On TV the keyboard's Search focuses the first result once it shows (`focusFirstResult`).
                        onSubmit = {
                            if (tv) store.submit()
                            false
                        },
                        probe = "search.field",
                        clearProbe = "search.clear",
                        modifier = Modifier.padding(padding),
                        fieldModifier = Modifier.rememberFocus(memory, FIELD_KEY),
                        searching = state.searching,
                    )
                    SearchFilters(state, store, memory, list, padding)
                }
            },
        ) {
            SearchBody(state, store, memory, list, signInAgain = app::signInAgain) { app.navigator.navigate(it) }
        }
        toast?.let { TimedToast(it, "search.toast", onShown = { toast = null }, Modifier.align(Alignment.BottomCenter).padding(bottom = LocalPlezyDimens.current.sectionSpacing)) }
    }
    RestoreFocus(memory, ready = true, fallback = FIELD_KEY)
}

/**
 * The kind chips over the results (All, Movies, People…): picking one shows its results from the top, wherever the list
 * was scrolled to.
 */
@Composable
internal fun SearchFilters(state: SearchUiState, store: SearchStore, memory: FocusMemory, list: LazyListState, padding: PaddingValues) {
    if (state.filters.isEmpty()) return
    ScrollRow(
        Modifier.fillMaxWidth().layoutProbe("search.filters", reportsFocus = false),
        contentPadding = padding,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(state.filters.size) { index ->
            val filter = state.filters[index]
            PlezyChip(
                filter.label,
                selected = filter == state.filter,
                onClick = {
                    store.selectFilter(filter)
                    list.requestScrollToItem(0)
                },
                modifier = Modifier.rememberFocus(memory, "filter/$index").layoutProbe("search.filter.$index"),
                tab = true,
            )
        }
    }
}

private const val FIELD_KEY = "field"

/** How many frames a landed search's first result has to compose and take focus. */
private const val FIRST_RESULT_FRAMES = 30

private fun resultKey(result: SearchResultUi): String = "result/${result.key}"

/**
 * What the screen shows under the field and chips for [state]'s phase (a search running over results shows in the
 * field). A failure while a server's session has expired says so and offers [signInAgain]; any other offers Retry.
 */
@Composable
internal fun SearchBody(state: SearchUiState, store: SearchStore, memory: FocusMemory, list: LazyListState, signInAgain: () -> Unit, open: (Route) -> Unit) {
    val expired = state.sessionExpired
    when {
        state.phase == SearchPhase.IDLE -> EmptyState(T.search.enterTitleActorOrKeyword, title = T.search.searchYourMedia, icon = PlezyIcons.Search)
        state.phase == SearchPhase.FAILED && expired != null -> EmptyState(expired, title = T.search.sessionExpired, icon = PlezyIcons.Lock) {
            PlezyButton(T.connections.signInAgain, signInAgain, Modifier.layoutProbe("search.signInAgain"), style = ButtonStyle.PRIMARY)
        }
        state.phase == SearchPhase.FAILED -> EmptyState(T.explore.searchFailed, icon = PlezyIcons.Error) {
            PlezyButton(T.nav.retry, store::refresh, Modifier.layoutProbe("search.retry"), style = ButtonStyle.PRIMARY, icon = PlezyIcons.Refresh)
        }
        state.phase == SearchPhase.EMPTY -> EmptyState(T.search.tryDifferentTerm, title = T.messages.noResultsFound, icon = PlezyIcons.Search)
        state.results.isEmpty() -> LoadingState()
        else -> {
            val density = LocalAppearance.current.libraryDensity
            ScrimWhileScrolled { list.canScrollBackward }
            LazyColumn(
                Modifier.fillMaxSize().layoutProbe("search.results", reportsFocus = false),
                state = list,
                contentPadding = PaddingValues(
                    start = LocalPlezyDimens.current.screenPadding,
                    end = LocalPlezyDimens.current.screenPadding,
                    top = if (state.filters.isEmpty()) 0.dp else 8.dp,
                    bottom = 16.dp,
                ),
            ) {
                var index = 0
                state.groups.forEachIndexed { groupIndex, group ->
                    group.title?.let { title ->
                        item(key = "group/$title") {
                            SectionTitle(
                                title,
                                Modifier.padding(horizontal = RowInset)
                                    .padding(top = if (groupIndex == 0) 0.dp else LocalPlezyDimens.current.sectionSpacing, bottom = LocalPlezyDimens.current.shelfHeaderGap)
                                    .semantics { heading() }
                                    .layoutProbe("search.group.$groupIndex", reportsFocus = false),
                            )
                        }
                    }
                    val start = index
                    index += group.results.size
                    items(group.results.size, key = { resultKey(group.results[it]) }) { offset ->
                        val result = group.results[offset]
                        val focus = Modifier.rememberFocus(memory, resultKey(result)).layoutProbe("search.result.${start + offset}")
                        when (result) {
                            is SearchResultUi.Media -> MediaRow(
                                result.card,
                                onClick = { store.open(result.key) },
                                modifier = focus,
                                density = density,
                                onLongClick = { store.menu(result.key) },
                                source = result.source,
                                backend = result.backend,
                                label = result.label,
                            )
                            is SearchResultUi.Person -> PersonRow(result, focus) { open(result.route) }
                        }
                    }
                }
            }
        }
    }
}

/**
 * An actor or director among the results: their round photo in the list's artwork column, their name (two lines),
 * "Actor" or "Director", and their server after its backend's mark when there are several ([SourceLine]). Select or a
 * tap opens their titles.
 */
@Composable
private fun PersonRow(person: SearchResultUi.Person, modifier: Modifier, onClick: () -> Unit) {
    PlezySurface(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = listOfNotNull(person.name, person.credit).joinToString(", ") },
        color = Color.Transparent,
        grows = false,
    ) {
        val stacked = largeFontScale()
        val width = rowArtworkWidth(CardShape.POSTER)
        ArtworkRow(
            stacked,
            gap = RowInset,
            artwork = { PersonPhoto(person.image, Modifier.size(width)) },
            modifier = Modifier.padding(RowInset),
            textModifier = Modifier.clearAndSetSemantics {},
        ) {
            val muted = PlezyColors.MutedContent
            val all = if (stacked) Int.MAX_VALUE else null
            Text(
                person.name,
                style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold).contentDirection(),
                maxLines = all ?: 2,
                overflow = TextOverflow.Ellipsis,
            )
            person.credit?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = muted, maxLines = all ?: 1) }
            person.source?.let { SourceLine(person.backend, it) }
        }
    }
}
