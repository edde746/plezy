package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterValue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.downloads.DownloadMenuEntry
import com.edde746.plezy.presentation.downloads.DownloadRowAction
import com.edde746.plezy.presentation.downloads.DownloadTreeNode
import com.edde746.plezy.presentation.downloads.DownloadsContent
import com.edde746.plezy.presentation.downloads.DownloadsGrouping
import com.edde746.plezy.presentation.downloads.DownloadsOptionsState
import com.edde746.plezy.presentation.downloads.DownloadsTabOptions
import com.edde746.plezy.presentation.downloads.DownloadsStore
import com.edde746.plezy.presentation.downloads.DownloadsTab
import com.edde746.plezy.presentation.downloads.DownloadsUiState
import com.edde746.plezy.presentation.downloads.MusicRow
import com.edde746.plezy.presentation.downloads.downloadsFolderMenuEntries
import com.edde746.plezy.presentation.downloads.isDownloadsFolder
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.libraries.BooleanFilterState
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.adaptive.largeFontScale
import com.edde746.plezy.ui.components.BooleanFilterRow
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.FilterFieldRow
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.CardArtwork
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.MediaRow
import com.edde746.plezy.ui.components.PosterCard
import com.edde746.plezy.ui.components.mediaGridCells
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyDropdownMenu
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowCheckbox
import com.edde746.plezy.ui.components.SheetOption
import com.edde746.plezy.ui.components.TabNavigationEffect
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.menusAnchored
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import androidx.compose.material3.VerticalDivider
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import com.edde746.plezy.ui.components.FILTER_GAP
import com.edde746.plezy.ui.components.FilterChip
import com.edde746.plezy.ui.components.FittingRow
import com.edde746.plezy.ui.components.MenuChip
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.HeaderAction
import com.edde746.plezy.ui.components.HeaderScaffold
import com.edde746.plezy.ui.components.rememberHeaderGridState
import com.edde746.plezy.ui.components.rememberHeaderListState

/** What the Downloads screen does with the user's input; the store's intents, and the app's navigation. */
class DownloadsScreenActions(
    val select: (DownloadsTab) -> Unit = {},
    val toggle: (key: String) -> Unit = {},
    val rowAction: (DownloadTreeNode, DownloadRowAction) -> Unit = { _, _ -> },
    val retryFailed: () -> Unit = {},
    val syncRules: () -> Unit = {},
    val open: (MediaItem) -> Unit = {},
    /** A Music tab track tapped: [tracks] (its downloaded siblings) play offline from [index]; [album]: the albums grouping. */
    val playTracks: (tracks: List<MediaItem>, index: Int, album: Boolean) -> Unit = { _, _, _ -> },
    val folderEntry: (MediaItem, DownloadMenuEntry) -> Unit = { _, _ -> },
    val grouping: (DownloadsTab, DownloadsGrouping) -> Unit = { _, _ -> },
    val sort: (DownloadsTab, MediaSort) -> Unit = { _, _ -> },
    val clearSort: (DownloadsTab) -> Unit = {},
    val resetFilters: (DownloadsTab) -> Unit = {},
    val unwatchedFilter: (DownloadsTab, Boolean?) -> Unit = { _, _ -> },
    val toggleLibraryFilter: (DownloadsTab, String) -> Unit = { _, _ -> },
    val libraryFilterExcluded: (DownloadsTab, Boolean) -> Unit = { _, _ -> },
    val clearLibraryFilter: (DownloadsTab) -> Unit = {},
    val bannerAction: () -> Unit = {},
    val messageShown: () -> Unit = {},
)

/**
 * Downloads over [store]: [onSyncRules] opens the active sync rules, [onOpen] a downloaded title or collection (its
 * offline screen or playback), [onPlayTracks] plays a Music tab track among its downloaded siblings.
 */
@Composable
fun DownloadsScreen(
    store: DownloadsStore,
    onSyncRules: () -> Unit,
    onOpen: (MediaItem) -> Unit,
    modifier: Modifier = Modifier,
    onPlayTracks: (tracks: List<MediaItem>, index: Int, album: Boolean) -> Unit = { _, _, _ -> },
) {
    val state by store.state.collectAsState()
    val actions = remember(store) {
        DownloadsScreenActions(
            select = store::select,
            toggle = store::toggle,
            rowAction = store::perform,
            retryFailed = store::retryFailed,
            syncRules = onSyncRules,
            open = onOpen,
            playTracks = onPlayTracks,
            folderEntry = store::performFolder,
            grouping = { tab, grouping -> store.options[tab]?.selectGrouping(grouping) },
            sort = { tab, sort -> store.options[tab]?.selectSort(sort) },
            clearSort = { tab -> store.options[tab]?.clearSort() },
            resetFilters = { tab -> store.options[tab]?.resetFilters() },
            unwatchedFilter = { tab, value -> store.options[tab]?.setUnwatchedFilter(value) },
            toggleLibraryFilter = { tab, value -> store.options[tab]?.toggleLibraryFilterValue(value) },
            libraryFilterExcluded = { tab, excluded -> store.options[tab]?.setLibraryFilterExcluded(excluded) },
            clearLibraryFilter = { tab -> store.options[tab]?.clearLibraryFilter() },
            bannerAction = store::showBackgroundDetails,
            messageShown = store::messageShown,
        )
    }
    DownloadsContentView(state, store::card, store::artworkOf, { tab -> store.options[tab] }, actions, modifier)
}

/**
 * The Downloads page: one header row as Libraries' ([HeaderScaffold]): the page's title, the tabs (Manage, TV Shows,
 * Movies, Music) as chips and, on a titles tab, its sort and filters and its grouping (an icon alone) as dropdown chips
 * where they all fit; else (always on phones) the title, then the tabs and the options as one dropdown chip each,
 * fitted to the row. The row ends in its actions (Retry failed while a download failed,
 * Active sync rules). Then Android's background-download banner, then the selected tab: Manage's tree, or the
 * downloaded titles as the grid or list of the user's view setting, their libraries, collection folders, albums or
 * tracks, the empty state.
 */
@Composable
fun DownloadsContentView(
    state: DownloadsUiState,
    card: (MediaItem) -> MediaCardUi,
    artworkOf: (MediaItem) -> String?,
    optionsOf: (DownloadsTab) -> DownloadsTabOptions?,
    actions: DownloadsScreenActions,
    modifier: Modifier = Modifier,
) {
    var optionsPage by remember { mutableStateOf<OptionsPage?>(null) }
    val tabState = state.tab
    val sorts = tabState?.let { optionsOf(it.tab)?.sortOptions }.orEmpty()
    // A remote or the keys start on the selected tab, and come back to it when what had focus goes.
    val memory = rememberFocusMemory()
    RestoreFocus(memory, ready = true, fallback = tabFocusKey(state.selected))
    // L1 and R1: the previous or next tab, focus on its chip. Asked from outside the chips, focus enters the row at the
    // chip its restorer saw last; asked again from there (a no-op when it is on the chip), it moves to the tab's.
    TabNavigationEffect(DownloadsTab.entries, state.selected) { tab ->
        actions.select(tab)
        val key = tabFocusKey(tab)
        if (memory.focus(key)) memory.focus(key)
    }
    // The bar control that opened the options gets focus back once they close (after the screen's own restore, which
    // would put it on the selected tab).
    var opener by remember { mutableStateOf<String?>(null) }
    var refocus by remember { mutableStateOf<String?>(null) }
    val inputMode = LocalInputModeManager.current
    LaunchedEffect(refocus) {
        val key = refocus ?: return@LaunchedEffect
        repeat(3) { withFrameNanos { } }
        if (inputMode.inputMode == InputMode.Keyboard) memory.focus(key)
        refocus = null
    }
    val open = { page: OptionsPage ->
        opener = memory.focusedKey
        optionsPage = page
    }
    Box(modifier.fillMaxSize()) {
        HeaderScaffold(
            filters = { padding, measuring ->
                TabChips(state.selected, actions.select, memory, Modifier.padding(padding), measuring, { Title(state.title) }) {
                    if (tabState != null) {
                        val tabOptions = optionsOf(tabState.tab)
                        val choices = OptionsChoices(tabOptions?.sortOptions.orEmpty(), tabOptions?.filterDefinitions.orEmpty(), state.libraryFilterValues)
                        OptionChips(tabState.tab, tabState.options, sorts, choices, memory, measuring, actions) { open(OptionsPage.FILTERS) }
                    }
                }
            },
            fitted = { padding ->
                FittingRow(Modifier.padding(padding).focusGroup()) {
                    Title(state.title)
                    MenuChip(
                        FilterChip(state.title, state.selected.label),
                        choices = DownloadsTab.entries.map { MenuChoice(it.label, it == state.selected) },
                        onPick = { actions.select(DownloadsTab.entries[it]) },
                        probe = "downloads.view",
                        modifier = Modifier.rememberFocus(memory, tabFocusKey(state.selected)),
                    )
                    if (tabState != null) {
                        PlezyChip(
                            "",
                            selected = tabState.options.hasActiveFilters,
                            onClick = { open(OptionsPage.ROOT) },
                            leadingIcon = PlezyIcons.Tune,
                            dropdown = true,
                            modifier = Modifier.semantics { contentDescription = state.optionsLabel }.barControl(memory, "options"),
                        )
                    }
                }
            },
            actions = { BarActions(state, actions, memory) },
        ) {
            Column(Modifier.fillMaxSize()) {
                state.banner?.let { banner ->
                    BackgroundBanner(banner.text, banner.actionLabel, banner.blocked, actions.bannerAction)
                }
                Box(Modifier.weight(1f).fillMaxWidth()) {
                    if (tabState == null) {
                        DownloadTreeView(state.tree, actions.toggle, actions.open, actions.rowAction)
                    } else {
                        TabContent(tabState.tab, tabState.content, card, artworkOf, actions)
                    }
                }
            }
        }
        state.message?.let { TimedToast(it.message, "downloads.message", actions.messageShown, Modifier.align(Alignment.BottomCenter), it.isError) }
    }
    val start = optionsPage
    if (start != null && tabState != null) {
        val tabOptions = optionsOf(tabState.tab)
        OptionsSheet(
            tabState.tab,
            tabState.options,
            OptionsChoices(tabOptions?.sortOptions.orEmpty(), tabOptions?.filterDefinitions.orEmpty(), state.libraryFilterValues),
            start,
            actions,
        ) {
            optionsPage = null
            refocus = opener
        }
    }
}

@Composable
private fun BarActions(state: DownloadsUiState, actions: DownloadsScreenActions, memory: FocusMemory) {
    if (state.retryFailed) HeaderAction(PlezyIcons.Refresh, state.retryFailedLabel, actions.retryFailed, "downloads.retryFailed", Modifier.rememberFocus(memory, "retryFailed"))
    HeaderAction(PlezyIcons.Sync, state.syncRulesLabel, actions.syncRules, "downloads.syncRules", Modifier.rememberFocus(memory, "syncRules"))
}

private fun tabFocusKey(tab: DownloadsTab) = "tab/${tab.name}"

/** The page's title, first in its header row. */
@Composable
private fun Title(title: String) {
    Text(title, Modifier.layoutProbe("downloads.title"), style = MaterialTheme.typography.titleLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
}

/**
 * The tabs as chips after [leading], [trailing] after them; [measuring]: composed to be measured only, so the chips
 * take no place in the focus [memory].
 */
@Composable
private fun TabChips(
    selected: DownloadsTab,
    onSelect: (DownloadsTab) -> Unit,
    memory: FocusMemory,
    modifier: Modifier,
    measuring: Boolean,
    leading: @Composable () -> Unit,
    trailing: @Composable () -> Unit,
) {
    Row(
        // Up from the titles, and a sheet a chip opened closing, come back to the chip focused last, else the selected tab.
        if (measuring) modifier else modifier.focusRestorer(memory.requester(tabFocusKey(selected))).focusGroup().layoutProbe("downloads.tabs", reportsFocus = false),
        horizontalArrangement = Arrangement.spacedBy(FILTER_GAP),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        leading()
        DownloadsTab.entries.forEach { tab ->
            PlezyChip(
                tab.label,
                selected = tab == selected,
                onClick = { onSelect(tab) },
                modifier = if (measuring) Modifier else Modifier.rememberFocus(memory, tabFocusKey(tab)).layoutProbe("downloads.tab.${tab.name.lowercase()}"),
                tab = true,
            )
        }
        trailing()
    }
}

/**
 * Wide windows and TV: after a hairline, the tab's sort and filters, then its grouping (its icon alone, named for
 * screen readers) as dropdown chips ([MenuChip]: picking the sort shown again reverses it; Clear ends its list while a
 * sort is set). The filters' chip opens their popup at it where menus open at their control ([menusAnchored]), else
 * their sheet ([openFilters]). [measuring] as [TabChips]'.
 */
@Composable
private fun OptionChips(
    tab: DownloadsTab,
    options: DownloadsOptionsState,
    sorts: List<MediaSort>,
    choices: OptionsChoices,
    memory: FocusMemory,
    measuring: Boolean,
    actions: DownloadsScreenActions,
    openFilters: () -> Unit,
) {
    VerticalDivider(Modifier.padding(horizontal = 4.dp).height(20.dp), color = PlezyColors.Hairline)
    MenuChip(
        FilterChip(T.libraries.sortBy, options.sortLabel, narrowed = options.sort != null),
        choices = sorts.map { MenuChoice(it.title, it.key == options.sort?.key, detail = null) } +
            listOfNotNull(MenuChoice(T.common.clear, selected = false).takeIf { options.sort != null }),
        onPick = { index -> if (index < sorts.size) actions.sort(tab, sorts[index]) else actions.clearSort(tab) },
        probe = "downloads.sort",
        modifier = if (measuring) Modifier else Modifier.rememberFocus(memory, "sort"),
        leadingIcon = PlezyIcons.Sort,
    )
    val anchored = menusAnchored()
    var filtersOpen by remember { mutableStateOf(false) }
    Box {
        PlezyChip(
            options.filtersLabel,
            selected = options.hasActiveFilters,
            onClick = { if (anchored) filtersOpen = true else openFilters() },
            leadingIcon = PlezyIcons.FilterAlt,
            dropdown = true,
            modifier = if (measuring) Modifier else Modifier.barControl(memory, "filters"),
        )
        if (anchored && !measuring) {
            PlezyDropdownMenu(expanded = filtersOpen, onDismiss = { filtersOpen = false }) {
                FiltersMenu(tab, options, choices, actions) { filtersOpen = false }
            }
        }
    }
    MenuChip(
        FilterChip(T.libraries.groupings.title, options.grouping.label, spoken = "${T.libraries.groupings.title}: ${options.grouping.label}"),
        choices = tab.groupings.map { MenuChoice(it.label, it == options.grouping) },
        onPick = { actions.grouping(tab, tab.groupings[it]) },
        probe = "downloads.grouping",
        modifier = if (measuring) Modifier else Modifier.rememberFocus(memory, "grouping"),
        leadingIcon = PlezyIcons.Category,
        iconOnly = true,
    )
}

/**
 * The filters popup at their chip, 380 wide and at most 560 tall as Libraries' ([FiltersPage]; the Library filter's
 * page in its place): its header (Back on the Library page, else the filter icon; the title; Close) over the page.
 */
@Composable
private fun FiltersMenu(tab: DownloadsTab, options: DownloadsOptionsState, choices: OptionsChoices, actions: DownloadsScreenActions, close: () -> Unit) {
    var libraryPage by remember { mutableStateOf(false) }
    val library = choices.filters.firstOrNull { !it.isBoolean }?.takeIf { libraryPage }
    val initial = remember(library) { FocusRequester() }
    Column(Modifier.width(380.dp).heightIn(max = 560.dp).verticalScroll(rememberScrollState())) {
        Row(Modifier.fillMaxWidth().padding(start = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            if (library != null) {
                PlezyIconButton(PlezyIcons.ArrowBack, T.nav.back, { libraryPage = false }, Modifier.layoutProbe("downloads.filters.back"), style = IconButtonStyle.PLAIN)
            } else {
                androidx.compose.material3.Icon(PlezyIcons.FilterAlt, contentDescription = null, Modifier.padding(horizontal = 12.dp).size(20.dp))
            }
            Text(library?.title ?: T.libraries.filters, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
            PlezyIconButton(PlezyIcons.Close, T.common.close, close, Modifier.layoutProbe("downloads.filters.close"), style = IconButtonStyle.PLAIN)
        }
        if (library != null) {
            LibraryFilterPage(tab, options, library, choices.libraryValues, initial, actions)
        } else {
            FiltersPage(tab, options, choices, initial, actions) { libraryPage = true }
        }
    }
    LaunchedEffect(library) { initial.requestFocus() }
}

/** A control of the bar under [name]: focus comes back to it as its sheet or the screen it opened closes. */
private fun Modifier.barControl(memory: FocusMemory, name: String) = rememberFocus(memory, name).layoutProbe("downloads.$name")

/** The pages of a tab's options sheet. */
private enum class OptionsPage { ROOT, FILTERS, LIBRARY }

/** What a tab's options offer: its sorts, its filters, and the Library filter's values. */
private class OptionsChoices(val sorts: List<MediaSort>, val filters: List<MediaFilter>, val libraryValues: List<MediaFilterValue>)

/**
 * A tab's view options, opened on [start]: how its titles are grouped, their order (again to reverse it), and its
 * filters (their own page: Unwatched as Any, Yes or No in place, Library on a page of its own listing each library
 * holding downloads, all of them kept or excluded). Back leaves a page for the one it opened from; touch screens
 * also get a back button beside the page's title.
 */
@Composable
private fun OptionsSheet(
    tab: DownloadsTab,
    options: DownloadsOptionsState,
    choices: OptionsChoices,
    start: OptionsPage,
    actions: DownloadsScreenActions,
    onDismiss: () -> Unit,
) {
    var page by remember { mutableStateOf(start) }
    val back: OptionsPage? = when (page) {
        OptionsPage.LIBRARY -> OptionsPage.FILTERS
        OptionsPage.FILTERS -> OptionsPage.ROOT.takeIf { start == OptionsPage.ROOT }
        OptionsPage.ROOT -> null
    }
    val library = choices.filters.firstOrNull { !it.isBoolean }
    val title = when (page) {
        OptionsPage.ROOT -> T.downloads.options
        OptionsPage.FILTERS -> T.libraries.filters
        OptionsPage.LIBRARY -> library?.title ?: T.libraries.filters
    }
    val initial = remember(page) { FocusRequester() }
    val pageHeader = back != null && LocalWindowLayout.current.formFactor != FormFactor.TV
    PlezySheet(
        onDismiss = onDismiss,
        title = if (pageHeader) null else title,
        initialFocus = initial,
        probe = "downloads.optionsSheet",
        onBack = { if (back != null) page = back else onDismiss() },
        label = title,
        header = if (pageHeader) {
            {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    PlezyIconButton(PlezyIcons.ArrowBack, T.nav.back, { back?.let { page = it } }, style = IconButtonStyle.PLAIN)
                    Text(title, style = MaterialTheme.typography.titleLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        } else {
            null
        },
    ) {
        // The sheet focuses the page it opens on; a page that follows takes focus as it shows.
        FocusOnPage(page, initial)
        Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())) {
            when (page) {
                OptionsPage.ROOT -> RootPage(tab, options, choices.sorts, initial, actions) { page = OptionsPage.FILTERS }
                OptionsPage.FILTERS -> FiltersPage(tab, options, choices, initial, actions) { page = OptionsPage.LIBRARY }
                OptionsPage.LIBRARY -> if (library != null) LibraryFilterPage(tab, options, library, choices.libraryValues, initial, actions)
            }
        }
    }
}

/** Focus to [initial] as [page] replaces another (the page before took the focused row with it). */
@Composable
private fun FocusOnPage(page: OptionsPage, initial: FocusRequester) {
    val shown = remember { arrayOfNulls<OptionsPage>(1) }
    SideEffect {
        if (shown[0] != null && shown[0] != page) initial.requestFocus()
        shown[0] = page
    }
}

@Composable
private fun RootPage(tab: DownloadsTab, options: DownloadsOptionsState, sorts: List<MediaSort>, initial: FocusRequester, actions: DownloadsScreenActions, openFilters: () -> Unit) {
    tab.groupings.forEachIndexed { index, grouping ->
        SheetOption(
            grouping.label,
            onClick = { actions.grouping(tab, grouping) },
            selected = grouping == options.grouping,
            modifier = if (index == 0) Modifier.focusRequester(initial) else Modifier,
        )
    }
    FilterFieldRow(options.filtersLabel, null, onClick = openFilters, modifier = Modifier.layoutProbe("downloads.optionsSheet.filters"))
    GroupHeader(T.libraries.sortBy)
    sorts.forEach { sort ->
        val current = options.sort?.key == sort.key
        SheetOption(
            sort.title,
            onClick = { actions.sort(tab, sort) },
            selected = current,
            icon = if (current) (if (options.sortDescending) PlezyIcons.ArrowDownward else PlezyIcons.ArrowUpward) else null,
        )
    }
    if (options.sort != null) SheetOption(T.common.clear, onClick = { actions.clearSort(tab) }, choice = false)
}

/** Clear all while a filter is on, Unwatched (Any, Yes, No: a click or Left and Right step through them), Library. */
@Composable
private fun FiltersPage(tab: DownloadsTab, options: DownloadsOptionsState, choices: OptionsChoices, initial: FocusRequester, actions: DownloadsScreenActions, openLibrary: () -> Unit) {
    if (options.hasActiveFilters) {
        SheetOption(
            T.libraries.clearAll,
            onClick = { actions.resetFilters(tab) },
            choice = false,
            icon = PlezyIcons.ClearAll,
            modifier = Modifier.focusRequester(initial).layoutProbe("downloads.filters.clearAll"),
        )
    }
    choices.filters.forEachIndexed { index, filter ->
        val first = if (index == 0 && !options.hasActiveFilters) Modifier.focusRequester(initial) else Modifier
        if (filter.isBoolean) {
            BooleanFilterRow(
                filter.title,
                when (options.unwatchedFilter) {
                    null -> BooleanFilterState.ANY
                    true -> BooleanFilterState.YES
                    false -> BooleanFilterState.NO
                },
                supportsExclusion = true,
                onChange = { state ->
                    val value = when (state) {
                        BooleanFilterState.ANY -> null
                        BooleanFilterState.YES -> true
                        BooleanFilterState.NO -> false
                    }
                    actions.unwatchedFilter(tab, value)
                },
                modifier = first.layoutProbe("downloads.filters.${filter.filter}"),
            )
        } else {
            FilterFieldRow(
                filter.title,
                options.filterSummary(filter, choices.libraryValues),
                onClick = openLibrary,
                modifier = first.layoutProbe("downloads.filters.${filter.filter}"),
            )
        }
    }
}

/** All (the filter off), Include or Exclude (a click or Left and Right), then a tick box for each library. */
@Composable
private fun LibraryFilterPage(
    tab: DownloadsTab,
    options: DownloadsOptionsState,
    filter: MediaFilter,
    values: List<MediaFilterValue>,
    initial: FocusRequester,
    actions: DownloadsScreenActions,
) {
    val clause = options.libraryFilter
    val excluded = clause?.op?.isNegated == true
    SheetOption(
        T.libraries.all,
        onClick = { actions.clearLibraryFilter(tab) },
        selected = clause == null,
        modifier = Modifier.focusRequester(initial).layoutProbe("downloads.filters.all"),
    )
    if (filter.supportsExclusion) {
        SheetOption(
            T.libraries.advancedFilters.exclude,
            onClick = { actions.libraryFilterExcluded(tab, !excluded) },
            choice = false,
            modifier = Modifier.layoutProbe("downloads.filters.exclude").onPreviewKeyEvent { event ->
                val exclude = when (event.key) {
                    Key.DirectionLeft -> false
                    Key.DirectionRight -> true
                    else -> return@onPreviewKeyEvent false
                }
                if (event.type == KeyEventType.KeyDown) actions.libraryFilterExcluded(tab, exclude)
                true
            },
            badge = { RowSwitch(excluded) },
        )
    }
    values.forEachIndexed { index, value ->
        val checked = clause?.values?.contains(value.key) == true
        PlezyToggleSurface(
            checked,
            { actions.toggleLibraryFilter(tab, value.key) },
            Modifier.fillMaxWidth().heightIn(min = LocalPlezyDimens.current.controlHeight).layoutProbe("downloads.filters.value.$index"),
            color = Color.Transparent,
            role = Role.Checkbox,
        ) {
            Row(Modifier.padding(start = 16.dp, end = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(value.title, style = MaterialTheme.typography.bodyLarge, maxLines = 2, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
                RowCheckbox(checked)
            }
        }
    }
}

@Composable
private fun BackgroundBanner(text: String, actionLabel: String, blocked: Boolean, onAction: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = LocalPlezyDimens.current.screenPadding, vertical = 4.dp)
            .clip(MaterialTheme.shapes.large)
            .padding(0.dp)
            .layoutProbe("downloads.banner", reportsFocus = false),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        androidx.compose.material3.Icon(
            PlezyIcons.WarningAmber,
            contentDescription = null,
            tint = if (blocked) PlezyColors.Error else LocalContentColor.current,
            modifier = Modifier.size(20.dp),
        )
        Text(text, style = MaterialTheme.typography.bodySmall, modifier = Modifier.weight(1f))
        PlezyButton(actionLabel, onClick = onAction, style = ButtonStyle.TEXT)
    }
}

@Composable
private fun TabContent(tab: DownloadsTab, content: DownloadsContent, card: (MediaItem) -> MediaCardUi, artworkOf: (MediaItem) -> String?, actions: DownloadsScreenActions) {
    val side = sidePadding()
    val padding = PaddingValues(start = side, end = side, top = 4.dp, bottom = 24.dp)
    when (content) {
        is DownloadsContent.Empty -> EmptyState(
            content.description ?: content.title,
            title = content.title.takeIf { content.description != null },
            icon = PlezyIcons.Download,
            modifier = Modifier.layoutProbe("downloads.empty", reportsFocus = false),
            action = content.actionLabel?.let { label -> { PlezyButton(label, onClick = { actions.resetFilters(tab) }) } },
        )
        is DownloadsContent.Grid -> DownloadsGrid(content.items, card, actions, padding)
        is DownloadsContent.Sections -> DownloadsGrid(emptyList(), card, actions, padding) {
            content.sections.forEach { section ->
                item(key = "section.${section.key}", span = { GridItemSpan(maxLineSpan) }) {
                    Column(Modifier.padding(top = 12.dp, bottom = 4.dp)) {
                        Text(section.title, style = MaterialTheme.typography.titleMedium)
                        section.subtitle?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted) }
                    }
                }
                section.items.forEach { item -> cardItem(item, card, actions, section.key) }
            }
        }
        is DownloadsContent.Albums -> LazyColumn(Modifier.fillMaxSize().layoutProbe("downloads.items", reportsFocus = false), rememberHeaderListState(), contentPadding = padding) {
            items(content.rows, key = { row -> if (row is MusicRow.Album) "album.${row.album.globalKey}" else (row as MusicRow.Track).item.globalKey }) { row ->
                when (row) {
                    is MusicRow.Album -> AlbumHeader(row.album, row.artworkPath ?: artworkOf(row.album), actions)
                    is MusicRow.Track -> TrackRow(row.item, { actions.playTracks(row.tracks, row.index, true) })
                }
            }
        }
        is DownloadsContent.Tracks -> LazyColumn(Modifier.fillMaxSize().layoutProbe("downloads.items", reportsFocus = false), rememberHeaderListState(), contentPadding = padding) {
            items(content.tracks.size, key = { content.tracks[it].globalKey }) { index ->
                TrackRow(content.tracks[index], { actions.playTracks(content.tracks, index, false) }, showAlbum = true)
            }
        }
    }
}

/** Titles as the grid (or the list, per the view setting); [extra] adds section headers and their cards. */
@Composable
private fun DownloadsGrid(
    items: List<MediaItem>,
    card: (MediaItem) -> MediaCardUi,
    actions: DownloadsScreenActions,
    padding: PaddingValues,
    extra: (LazyGridScope.() -> Unit)? = null,
) {
    val appearance = LocalAppearance.current
    if (appearance.viewMode == ViewMode.LIST && extra == null) {
        LazyColumn(Modifier.fillMaxSize().layoutProbe("downloads.items", reportsFocus = false), rememberHeaderListState(), contentPadding = padding) {
            items(items, key = { it.globalKey }) { item ->
                MediaRow(card(item), onClick = { actions.open(item) }, modifier = Modifier.layoutProbe("downloads.item.${item.globalKey}"), density = appearance.libraryDensity)
            }
        }
        return
    }
    LazyVerticalGrid(
        columns = mediaGridCells(CardShape.POSTER, appearance),
        state = rememberHeaderGridState(),
        contentPadding = padding,
        horizontalArrangement = Arrangement.spacedBy(LocalPlezyDimens.current.gutter),
        verticalArrangement = Arrangement.spacedBy(LocalPlezyDimens.current.gutter),
        modifier = Modifier.fillMaxSize().layoutProbe("downloads.items", reportsFocus = false),
    ) {
        items.forEach { item -> cardItem(item, card, actions) }
        extra?.invoke(this)
    }
}

private fun LazyGridScope.cardItem(item: MediaItem, card: (MediaItem) -> MediaCardUi, actions: DownloadsScreenActions, keyPrefix: String = "") {
    item(key = "$keyPrefix/${item.globalKey}") {
        DownloadCard(item, card(item), actions)
    }
}

@Composable
private fun DownloadCard(item: MediaItem, ui: MediaCardUi, actions: DownloadsScreenActions) {
    var menu by remember { mutableStateOf(false) }
    val folder = item.isDownloadsFolder
    Box {
        PosterCard(
            ui,
            onClick = { actions.open(item) },
            modifier = Modifier.fillMaxWidth().layoutProbe("downloads.item.${item.globalKey}"),
            onLongClick = if (folder) ({ menu = true }) else null,
        )
        if (folder) {
            ItemMenu(
                menu,
                onDismiss = { menu = false },
                entries = downloadsFolderMenuEntries(item).map { entry ->
                    ItemMenuEntry(entry.label, probe = entry.id, destructive = entry.destructive) { actions.folderEntry(item, entry) }
                },
                probe = "downloads.folderMenu",
                title = item.displayTitle,
                media = true,
                contentTitle = true,
            )
        }
    }
}

@Composable
private fun AlbumHeader(album: MediaItem, artworkPath: String?, actions: DownloadsScreenActions) {
    PlezySurface(
        onClick = { actions.open(album) },
        modifier = Modifier.fillMaxWidth().padding(top = 16.dp, bottom = 4.dp).layoutProbe("downloads.album.${album.globalKey}"),
        shape = RoundedCornerShape(12.dp),
        color = Color.Transparent,
        grows = false,
    ) {
        Row(Modifier.padding(8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            CardArtwork(
                MediaCardUi(album.globalKey, album.displayTitle, null, CardShape.SQUARE, placeholder = PlaceholderKind.ALBUM, artwork = Artwork.fixed(artworkPath)),
                Modifier.size(ALBUM_ART).testTag(ALBUM_ART_TAG).layoutProbe("downloads.album.${album.globalKey}.art", reportsFocus = false),
            )
            Column(Modifier.weight(1f)) {
                Text(album.displayTitle, style = MaterialTheme.typography.titleMedium, maxLines = 2, overflow = TextOverflow.Ellipsis)
                listOfNotNull(album.parentTitle, album.year?.toString()).joinToString(" · ").takeIf { it.isNotEmpty() }?.let {
                    Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, maxLines = 1)
                }
            }
        }
    }
}

/**
 * A downloaded track: its number, its title over its artist (and album), its length. At a large font scale it stays
 * one row, its texts wrapping whole.
 */
@Composable
private fun TrackRow(track: MediaItem, onClick: () -> Unit, showAlbum: Boolean = false) {
    PlezySurface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().layoutProbe("downloads.track.${track.globalKey}"),
        shape = RoundedCornerShape(8.dp),
        color = Color.Transparent,
        grows = false,
    ) {
        val lines = if (largeFontScale()) Int.MAX_VALUE else 1
        Row(Modifier.padding(horizontal = 12.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Text(track.trackNumber?.toString().orEmpty(), style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, maxLines = 1, modifier = Modifier.widthIn(min = 24.dp))
            Column(Modifier.weight(1f)) {
                Text(track.displayTitle, style = MaterialTheme.typography.bodyMedium, maxLines = lines, overflow = TextOverflow.Ellipsis)
                val detail = if (showAlbum) listOfNotNull(track.trackArtistTitle, track.albumTitle).joinToString(" · ") else track.trackArtistTitle
                detail?.takeIf { it.isNotEmpty() }?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, maxLines = lines) }
            }
            track.durationMs?.let { Text(formatDuration(it), style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted) }
        }
    }
}

private fun formatDuration(ms: Long): String {
    val seconds = ms / 1000
    return "${seconds / 60}:${(seconds % 60).toString().padStart(2, '0')}"
}

@Composable
private fun sidePadding(): Dp = LocalPlezyDimens.current.screenPadding

/** A downloaded album's header artwork: 120 dp square, decoded at that size. */
private val ALBUM_ART = 120.dp

/** The album header artwork's test tag. */
internal const val ALBUM_ART_TAG = "downloads.albumArt"
