package com.edde746.plezy.ui.libraries

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.widthIn
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.SaveableStateHolder
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.LocalPlatformContext
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.libraries.BrowseGrouping
import com.edde746.plezy.presentation.libraries.BrowseUiState
import com.edde746.plezy.presentation.libraries.FolderRowUi
import com.edde746.plezy.presentation.libraries.GenreTileUi
import com.edde746.plezy.presentation.libraries.LibrariesLoad
import com.edde746.plezy.presentation.libraries.LibrariesScreenStore
import com.edde746.plezy.presentation.libraries.LibrariesUiState
import com.edde746.plezy.presentation.libraries.LibraryBrowseStore
import com.edde746.plezy.presentation.libraries.LibraryPagedTabStore
import com.edde746.plezy.presentation.libraries.LibraryTab
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.SettingsPageId
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.BlankCard
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.FILTER_GAP
import com.edde746.plezy.ui.components.NAME_MIN
import com.edde746.plezy.ui.components.FilterChip
import com.edde746.plezy.ui.components.FittingRow
import com.edde746.plezy.ui.components.HeaderAction
import com.edde746.plezy.ui.components.HeaderScaffold
import com.edde746.plezy.ui.components.GroupGap
import com.edde746.plezy.ui.components.HubRow
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.MediaRow
import com.edde746.plezy.ui.components.MenuChip
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyDropdownMenu
import com.edde746.plezy.ui.components.menusAnchored
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.PosterCard
import com.edde746.plezy.ui.components.RowInset
import com.edde746.plezy.ui.components.TabNavigationEffect
import com.edde746.plezy.ui.components.rememberHeaderGridState
import com.edde746.plezy.ui.components.rememberHeaderListState
import com.edde746.plezy.ui.components.compactFilterRow
import com.edde746.plezy.ui.components.aspectRatio
import com.edde746.plezy.ui.components.dropdownChipWidths
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.rowArtworkWidth
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.LocalArtworkDisplay
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.image.prefetchImage
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filterNotNull
import androidx.compose.foundation.lazy.grid.LazyGridLayoutInfo
import com.edde746.plezy.ui.components.MediaGrid
import com.edde746.plezy.ui.components.gridMotionReach
import com.edde746.plezy.ui.components.TouchPullToRefresh
import kotlinx.coroutines.launch

/**
 * How the screen lays itself out: [mobile] a phone's or tablet's (tabs that swipe), [phone] a phone's (Browse's options
 * as one Library options chip), [tv], and [anchoredMenus] where the Browse options open as menus at their chips
 * ([menusAnchored]: all but TV) rather than sheets.
 */
internal data class LibrariesChrome(val mobile: Boolean, val phone: Boolean, val tv: Boolean, val anchoredMenus: Boolean)

@Composable
private fun librariesChrome(appearance: Appearance): LibrariesChrome {
    val side = LocalWindowLayout.current.formFactor != FormFactor.HANDHELD
    return LibrariesChrome(mobile = !side, phone = compactFilterRow(), tv = appearance.tv, anchoredMenus = menusAnchored())
}

/**
 * The screen's focus: one memory for the tab chips ([chipKey]) and the shown tab's items ([itemKey]), the first item
 * each tab of the library shows ([first]), and the alphabet bar ([alphaBar]), which takes focus back after a jump that
 * reloads the grid ([alphaBarReturns]), and the letter its Up and Down jumped to ([alphaSettled]), which Select keeps.
 */
internal class LibrariesFocus(val memory: FocusMemory) {
    val first = mutableStateMapOf<LibraryTab, String>()
    val alphaBar = FocusRequester()
    var alphaBarReturns = false
    var alphaSettled: String? = null

    /** The tab shows [id] first. */
    fun report(tab: LibraryTab, id: String?) {
        if (id == null) first.remove(tab) else first[tab] = itemKey(id)
    }

    fun firstItem(tab: LibraryTab): Boolean = first[tab]?.let { memory.focus(it) } == true

    fun chip(tab: LibraryTab): Boolean = memory.focus(chipKey(tab))

    /**
     * Where the screen places focus for [state]'s tab ([RestoreFocus]'s fallback): its first item, else (still loading,
     * or empty) its chip; none in touch mode off TV ([placed] false).
     */
    fun fallback(state: LibrariesUiState, placed: Boolean): String? =
        (first[state.tab] ?: chipKey(state.tab).takeIf { state.selected != null })?.takeIf { placed }
}

internal fun chipKey(tab: LibraryTab) = "tab/${tab.key}"

internal fun itemKey(id: String) = "item/$id"

/**
 * Libraries: one header row ([HeaderScaffold]), the screen's only title, over the selected tab. The row starts with the
 * library chip (it picks a library or, where the device keeps downloads, the Downloads section: [onDownloads]), then
 * the tabs; on Browse its filters, sort and grouping. Where they don't fit side by side (phones) the tabs are one
 * dropdown chip naming the shown tab, Browse's filters and sort one Library options chip (filled while filters narrow
 * the grid) on phones, then the grouping's icon chip; the chips turn to their icons before the library's name gives
 * way ([LibrariesBar]). Shuffle and the ⋮ (Manage libraries, Refresh) end the row.
 *
 * Under a keyboard or remote focus goes to the shown tab's first item once it has loaded, until then to its chip (and
 * on from the chip to the item when it lands, unless the user moved it). Down from the row goes into the tab, Up from a
 * tab's first row to its chip. Touch places no focus. On phones and tablets the tabs swipe sideways.
 */
@Composable
fun LibrariesScreen(app: AppSession, onDownloads: (() -> Unit)?, modifier: Modifier = Modifier) {
    val store = remember(app) { app.libraries() } ?: return
    val state by store.state.collectAsState()
    val appearance = LocalAppearance.current
    val chrome = librariesChrome(appearance)
    var sheet by remember { mutableStateOf<LibrarySheet?>(null) }
    val manage = { app.navigator.navigate(Route.SettingsPage(SettingsPageId.MANAGE_LIBRARIES)) }
    // Each library tab's own view state (its scroll position): kept while another tab shows.
    val tabStates = rememberSaveableStateHolder()
    val memory = rememberFocusMemory()
    val focus = remember(memory, state.selected?.globalKey) { LibrariesFocus(memory) }
    val touch = LocalInputModeManager.current.inputMode == InputMode.Touch
    val onTab: (LibraryTab) -> Unit = { tab ->
        store.selectTab(tab)
        // The chip holds focus as the screen's placement, so it moves on to the tab's first item when that lands.
        if (!touch) memory.place(chipKey(tab))
    }
    // L1 and R1: the previous or next tab, focus on its chip (a music library shows its own browse instead of tabs).
    val tabsShown = state.load == LibrariesLoad.CONTENT && state.selected.let { it != null && !(it.kind == MediaKind.ARTIST && it.serverId != null) }
    TabNavigationEffect(state.tabs, state.tab, enabled = tabsShown) { tab ->
        store.selectTab(tab)
        focus.chip(tab)
    }
    // Browse's store, which a library with Browse makes as it shows: its options count on every tab.
    val browse = remember(store, state.selected?.globalKey, state.tabs) { if (LibraryTab.BROWSE in state.tabs) store.browse() else null }
    LibrariesBar(
        tabs = if (state.load == LibrariesLoad.CONTENT) state.tabs else emptyList(),
        tab = state.tab,
        focus = focus,
        onTab = onTab,
        picker = { icon -> LibraryPicker(state, downloads = false, onLibrary = store::selectLibrary, onDownloads = onDownloads, icon = icon) },
        options = browseOptions(state, store, chrome, chrome.phone) { sheet = it },
        name = state.selected?.title ?: T.libraries.title,
        onShuffle = if (state.canShuffle) store::shuffle else null,
        more = { shuffle -> LibrariesMore(state.libraries.isNotEmpty(), onShuffle = shuffle, onManage = manage, onRefresh = store::refresh) },
        modifier = modifier.layoutProbe("libraries", reportsFocus = false),
        optionsRoom = browse?.let { browseOptionsRoom(it, compact = chrome.phone) } ?: OptionsRoom(),
    ) {
        when (state.load) {
            LibrariesLoad.LOADING -> LoadingState()
            LibrariesLoad.ERROR -> ErrorState(state.error ?: T.errors.unableToLoad(T.libraries.title), onRetry = store::refresh)
            LibrariesLoad.NO_LIBRARIES -> EmptyState(T.libraries.noLibrariesFound, icon = PlezyIcons.VideoLibrary)
            LibrariesLoad.ALL_HIDDEN -> EmptyState(T.libraries.allLibrariesHidden, icon = PlezyIcons.VisibilityOff) {
                PlezyButton(T.libraries.manageLibraries, onClick = manage, icon = PlezyIcons.Edit)
            }
            LibrariesLoad.CONTENT -> if (chrome.mobile) {
                key(state.selected?.globalKey) {
                    SwipedTabs(state, store) { tab -> TabContent(state, tab, store, focus, appearance, tabStates) }
                }
            } else {
                TabContent(state, state.tab, store, focus, appearance, tabStates)
            }
        }
    }
    sheet?.let { LibrarySheets(it, store, onDismiss = { sheet = null }) }
    val fallback = focus.fallback(state, placed = appearance.tv || !touch)
    RestoreFocus(memory, ready = state.load == LibrariesLoad.CONTENT && fallback != null, fallback = fallback)
}

/**
 * Browse's options in the filter row: its chips where they fit ([compact] false; the sort and Filters chips with their
 * labels where the row's forms give them: [FittedForms]), else the Library options chip, left out while it would hold
 * nothing (Folders).
 */
private fun browseOptions(
    state: LibrariesUiState,
    store: LibrariesScreenStore,
    chrome: LibrariesChrome,
    compact: Boolean,
    onSheet: (LibrarySheet) -> Unit,
): (@Composable (forms: FittedForms) -> Unit)? {
    if (state.load != LibrariesLoad.CONTENT || state.selected == null || state.tab != LibraryTab.BROWSE) return null
    return { forms ->
        val browse = remember(store, state.selected?.globalKey) { store.browse() }
        if (browse != null) {
            if (compact) {
                val browseState by browse.state.collectAsState()
                if (browseState.showsFilters || browseState.showsSort) {
                    PlezyChip(
                        "",
                        selected = state.filtersActive,
                        onClick = { onSheet(LibrarySheet.Options) },
                        leadingIcon = PlezyIcons.Tune,
                        dropdown = true,
                        modifier = Modifier.semantics { contentDescription = T.libraries.libraryOptions }.layoutProbe("libraries.options"),
                    )
                }
                GroupingChip(browse)
            } else {
                BrowseOptionChips(browse, chrome.anchoredMenus, forms.sortLabel, forms.filtersLabel, onSheet)
            }
        }
    }
}

/**
 * The room (px) Browse's options take in a fitted header row, a gap before each: [narrow] with every chip its round
 * icon, [sortLabel] more with the sort chip labelled at its widest, [filtersLabel] more with the Filters chip labelled.
 * None: a library without Browse.
 */
internal data class OptionsRoom(val narrow: Int = 0, val sortLabel: Int = 0, val filtersLabel: Int = 0)

/** [browse]'s options' room in a fitted header row ([browseOptionsRoom]). */
@Composable
private fun browseOptionsRoom(browse: LibraryBrowseStore, compact: Boolean): OptionsRoom {
    val state by browse.state.collectAsState()
    return browseOptionsRoom(
        compact,
        filtersLabel = state.filtersLabel.takeIf { state.showsFilters },
        sorts = if (state.showsSort) state.sorts.map { it.title } else emptyList(),
    )
}

/**
 * The room Browse's options take in a fitted header row ([OptionsRoom]): on phones ([compact]) the Library options chip
 * and the grouping chip; else the Filters chip (none without [filtersLabel]: no Filters) with its label or its icon,
 * the sort chip (none without [sorts]) at the longest label it shows for the library (each of [sorts], Sort with none
 * shown) or its icon, and the grouping chip.
 */
@Composable
internal fun browseOptionsRoom(compact: Boolean, filtersLabel: String?, sorts: List<String>): OptionsRoom {
    val density = LocalDensity.current
    val gap = with(density) { FILTER_GAP.roundToPx() }
    val round = with(density) { LocalPlezyDimens.current.chipHeight.roundToPx() }
    if (compact) return OptionsRoom(2 * (round + gap))
    val filters = if (filtersLabel == null) 0 else round + gap
    val filtersLabelled = filtersLabel?.let { dropdownChipWidths(listOf(it), icon = true).single() - round } ?: 0
    val sort = if (sorts.isEmpty()) 0 else round + gap
    val sortLabel = if (sorts.isEmpty()) 0 else dropdownChipWidths(sorts + T.libraries.sort, icon = true).max() - round
    return OptionsRoom(filters + sort + round + gap, sortLabel, filtersLabelled)
}

/**
 * A fitted header row's forms ([LibrariesBar]): the library chip's icon ([pickerIcon]), the sort chip's label (else its
 * round icon), the view chip's label (else its round icon), the Filters chip's label (else its round icon), Shuffle in
 * the ⋮.
 */
internal data class FittedForms(
    val pickerIcon: Boolean = true,
    val sortLabel: Boolean = true,
    val viewLabel: Boolean = true,
    val filtersLabel: Boolean = true,
    val shuffleInMenu: Boolean = false,
)

/**
 * The forms of a fitted row [row] px wide with Shuffle's place ([shuffle] px, none without Shuffle), the ⋮'s not. The
 * chips give way before the library's name: the first of everything labelled, the sort chip round, the view chip round
 * too, the Filters chip round too, that leaves the name whole ([nameWhole]) beside the row's widest case ([widest]:
 * what a tab's view chip and options take at most in those forms); else every chip round while that leaves the name
 * its least ([nameLeast]), the name cut short; else Shuffle in the ⋮ too. The picker's icon goes first: it shows only
 * beside every label, where its name stays whole beside it ([iconNeed]). As the row narrows, nothing that gave way
 * comes back.
 */
internal fun fittedForms(row: Int, shuffle: Int, nameWhole: Int, nameLeast: Int, iconNeed: Int, widest: (FittedForms) -> Int): FittedForms {
    val labelled = FittedForms()
    val round = FittedForms(sortLabel = false, viewLabel = false, filtersLabel = false)
    val stages = listOf(
        labelled to nameWhole,
        FittedForms(sortLabel = false) to nameWhole,
        FittedForms(sortLabel = false, viewLabel = false) to nameWhole,
        round to nameLeast,
    )
    val name = { forms: FittedForms -> row - (if (forms.shuffleInMenu) 0 else shuffle) - widest(forms) }
    val forms = stages.firstOrNull { (forms, least) -> name(forms) >= least }?.first ?: round.copy(shuffleInMenu = true)
    return forms.copy(pickerIcon = forms == labelled && name(forms) >= iconNeed)
}

/**
 * The screen's [HeaderScaffold] over [content]: [picker] (the library chip), then [tabs] as chips and [options] after a
 * hairline, where they all fit side by side; else (always on phones) the picker, the tabs as one dropdown chip
 * ([MenuChip]) naming the shown tab, and [options], fitted to the row. [onShuffle] (Shuffle's round button) and [more]
 * (the ⋮) end the row.
 *
 * The row's forms never turn with the tab or the sort, only with its width: whether the chips go side by side, and each
 * part's form in the fitted row ([fittedForms]), are judged on the row's widest case, the tab whose view chip and
 * options (Browse's, [optionsRoom]: its Filters label, its sort chip at the longest label it shows for the library)
 * take the most of it. As the row narrows, its buttons turn to their icons before the library's name gives way: Shuffle
 * and the ⋮, the secondary ones and so the first, show their icons alone in every form; then the picker drops its icon
 * (it shows it only where the row leaves it the room for its icon and whole name: [picker]'s `icon`), then the sort
 * chip shows its round icon (its direction, or the sort icon), then the view chip, then the Filters chip; only once
 * every chip is round is the name cut short, down to a fitted row's least ([NAME_MIN]), never its arrow; then Shuffle
 * moves into the ⋮ (its first entry: [more] is given it). Down from the row goes into the shown tab ([tab]).
 * Harness names: `libraries.bar`, the chips `libraries.tab.<key>`, the view menu `libraries.view`, Shuffle
 * `libraries.shuffle`.
 */
@Composable
internal fun LibrariesBar(
    tabs: List<LibraryTab>,
    tab: LibraryTab,
    focus: LibrariesFocus,
    onTab: (LibraryTab) -> Unit,
    picker: @Composable (icon: Boolean) -> Unit,
    options: (@Composable (forms: FittedForms) -> Unit)?,
    name: String,
    onShuffle: (() -> Unit)?,
    more: @Composable (shuffle: (() -> Unit)?) -> Unit,
    modifier: Modifier = Modifier,
    optionsRoom: OptionsRoom = OptionsRoom(),
    content: @Composable () -> Unit,
) {
    var forms by remember { mutableStateOf(FittedForms()) }
    // The room (px) the library chip has at the row's widest case, which it keeps on every tab.
    var nameRoom by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val iconNeed = dropdownChipWidths(listOf(name), icon = true).single()
    val nameWhole = dropdownChipWidths(listOf(name), icon = false).single()
    val labels = dropdownChipWidths(tabs.map { it.label }, icon = false)
    val density = LocalDensity.current
    val round = with(density) { LocalPlezyDimens.current.chipHeight.roundToPx() }
    val gap = with(density) { FILTER_GAP.roundToPx() }
    val nameLeast = minOf(nameWhole, with(density) { NAME_MIN.roundToPx() })
    // The most a tab's view chip and options take of the row beside the name, each with its gap.
    val widest = { forms: FittedForms ->
        tabs.indices.maxOfOrNull { index ->
            val options = if (tabs[index] != LibraryTab.BROWSE) {
                0
            } else {
                optionsRoom.narrow + (if (forms.sortLabel) optionsRoom.sortLabel else 0) + (if (forms.filtersLabel) optionsRoom.filtersLabel else 0)
            }
            gap + (if (forms.viewLabel) labels[index] else round) + options
        } ?: 0
    }
    val onWidth: (Int) -> Unit = { width ->
        // The row's width with Shuffle's place, whichever forms it shows now.
        val shuffle = if (onShuffle != null) round + gap else 0
        val row = width + if (forms.shuffleInMenu) 0 else shuffle
        val next = fittedForms(row, shuffle, nameWhole, nameLeast, iconNeed, widest)
        forms = next
        nameRoom = maxOf(nameLeast, row - (if (next.shuffleInMenu) 0 else shuffle) - widest(next))
    }
    HeaderScaffold(
        filters = { padding, measuring ->
            Row(
                Modifier.padding(padding).then(if (measuring) Modifier else Modifier.focusGroup()),
                horizontalArrangement = Arrangement.spacedBy(FILTER_GAP),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                picker(true)
                for (each in tabs) {
                    PlezyChip(
                        each.label,
                        selected = each == tab,
                        onClick = { onTab(each) },
                        modifier = if (measuring) Modifier else Modifier.rememberFocus(focus.memory, chipKey(each)).layoutProbe("libraries.tab.${each.key}"),
                        tab = true,
                    )
                }
                if (measuring && optionsRoom.narrow > 0) {
                    // Measured with Browse's options at their widest on every tab, so whether the chips fit side by
                    // side never turns with the tab or the sort.
                    VerticalDivider(Modifier.padding(horizontal = 4.dp).height(20.dp), color = PlezyColors.Hairline)
                    Spacer(Modifier.width(with(density) { (optionsRoom.narrow + optionsRoom.sortLabel + optionsRoom.filtersLabel - gap).toDp() }))
                } else if (options != null) {
                    VerticalDivider(Modifier.padding(horizontal = 4.dp).height(20.dp), color = PlezyColors.Hairline)
                    options(FittedForms())
                }
                // Shuffle, which the side-by-side row shows among the actions, measured here while the fitted row has
                // it in the ⋮: else the room it frees would turn the row back to side by side, and round again.
                if (measuring && onShuffle != null && forms.shuffleInMenu) Spacer(Modifier.width(with(density) { round.toDp() }))
            }
        },
        modifier = modifier,
        headerModifier = Modifier
            .onPreviewKeyEvent { event -> event.type == KeyEventType.KeyDown && event.key == Key.DirectionDown && focus.firstItem(tab) }
            .layoutProbe("libraries.bar", reportsFocus = false),
        fitted = { padding ->
            DisposableEffect(Unit) {
                onDispose {
                    forms = FittedForms()
                    nameRoom = Int.MAX_VALUE
                }
            }
            FittingRow(Modifier.padding(padding).focusGroup(), onWidth = onWidth) {
                // As wide as the row's widest case leaves it, so its name is cut the same on every tab.
                Box(if (nameRoom == Int.MAX_VALUE) Modifier else Modifier.widthIn(max = with(density) { nameRoom.toDp() })) { picker(forms.pickerIcon) }
                if (tabs.isNotEmpty()) {
                    MenuChip(
                        FilterChip(T.libraries.content, tab.label, spoken = "${T.libraries.content}: ${tab.label}"),
                        choices = tabs.map { MenuChoice(it.label, it == tab) },
                        onPick = { onTab(tabs[it]) },
                        probe = "libraries.view",
                        modifier = Modifier.rememberFocus(focus.memory, chipKey(tab)),
                        leadingIcon = PlezyIcons.Dashboard.takeIf { !forms.viewLabel },
                        iconOnly = !forms.viewLabel,
                    )
                }
                options?.invoke(forms)
            }
        },
        actions = {
            if (onShuffle != null && !forms.shuffleInMenu) HeaderAction(PlezyIcons.Shuffle, T.libraries.shuffleLibrary, onShuffle, "libraries.shuffle")
            more(onShuffle.takeIf { forms.shuffleInMenu })
        },
        content = content,
    )
}

/** The ⋮ at the row's end: Shuffle where the row has no room for it ([onShuffle]), Manage libraries ([manage]: where there are libraries) and Refresh. */
@Composable
private fun LibrariesMore(manage: Boolean, onShuffle: (() -> Unit)?, onManage: () -> Unit, onRefresh: () -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box {
        HeaderAction(PlezyIcons.MoreVert, T.common.options, { open = true }, "libraries.more")
        ItemMenu(
            expanded = open,
            onDismiss = { open = false },
            entries = listOfNotNull(
                onShuffle?.let { ItemMenuEntry(T.libraries.shuffleLibrary, "shuffle", icon = PlezyIcons.Shuffle, onClick = it) },
                ItemMenuEntry(T.libraries.manageLibraries, "manage", icon = PlezyIcons.Edit, onClick = onManage).takeIf { manage },
                ItemMenuEntry(T.common.refresh, "refresh", icon = PlezyIcons.Refresh, onClick = onRefresh),
            ),
            probe = "libraries.more",
        )
    }
}

/** The tabs as pages a swipe turns (phones and tablets), following the chips both ways. */
@Composable
private fun SwipedTabs(state: LibrariesUiState, store: LibrariesScreenStore, page: @Composable (LibraryTab) -> Unit) {
    val tabs = state.tabs
    val pager = rememberPagerState(tabs.indexOf(state.tab).coerceAtLeast(0)) { tabs.size }
    val shown by rememberUpdatedState(state.tab)
    LaunchedEffect(state.tab, tabs) {
        val index = tabs.indexOf(state.tab)
        if (index >= 0 && index != pager.currentPage) pager.animateScrollToPage(index)
    }
    LaunchedEffect(pager, tabs) {
        snapshotFlow { pager.settledPage }.collect { index -> tabs.getOrNull(index)?.takeIf { it != shown }?.let(store::selectTab) }
    }
    HorizontalPager(pager, Modifier.fillMaxSize().layoutProbe("libraries.pager", reportsFocus = false), key = { tabs[it].key }) { index -> page(tabs[index]) }
}

/** The kind icon of a library. */
fun libraryIcon(kind: MediaKind) = when (kind) {
    MediaKind.SHOW -> PlezyIcons.Tv
    MediaKind.ARTIST -> PlezyIcons.MusicNote
    MediaKind.PHOTO -> PlezyIcons.VideoLibrary
    else -> PlezyIcons.Movie
}

@Composable
private fun TabContent(
    state: LibrariesUiState,
    tab: LibraryTab,
    store: LibrariesScreenStore,
    focus: LibrariesFocus,
    appearance: Appearance,
    tabStates: SaveableStateHolder,
) {
    val key = state.selected?.globalKey ?: return
    // Each library's tabs are their own stores: a library change drops the last library's. The view state of each
    // (library, tab) stays in [tabStates], so a tab shown again is where it was left.
    key(key, tab) {
        tabStates.SaveableStateProvider("$key/${tab.name}") {
            when (tab) {
                LibraryTab.RECOMMENDED -> RecommendedTab(store, focus, appearance)
                LibraryTab.BROWSE -> store.browse()?.let { BrowseTab(it, store, focus, appearance) }
                LibraryTab.COLLECTIONS -> store.collections()?.let { PagedTab(it, tab, store, focus, appearance, T.libraries.noCollections) }
                LibraryTab.PLAYLISTS -> store.playlists()?.let { PagedTab(it, tab, store, focus, appearance, T.playlists.noPlaylists) }
                LibraryTab.GENRES -> GenresTab(store, focus)
            }
        }
    }
}

/**
 * Recommended: the library's hubs as shelves a pull reloads. A card opens its item, its long press its menu; a hub with
 * more opens its View all. Up from the first shelf goes to the tab's chip; focus in the hubs when a reload leaves none
 * goes back to it too.
 */
@Composable
private fun RecommendedTab(store: LibrariesScreenStore, focus: LibrariesFocus, appearance: Appearance) {
    val recommended = remember(store) { store.recommended() } ?: return
    val state by recommended.state.collectAsState()
    val first = state.items.firstOrNull { it.items.isNotEmpty() }?.takeIf { state.load == LoadState.CONTENT }?.let { "${it.id}/${it.items.first().id}" }
    SideEffect { focus.report(LibraryTab.RECOMMENDED, first) }
    TouchPullToRefresh(refreshing = false, onRefresh = store::refreshTab, modifier = Modifier.handsFocusBack(shown = first != null) { focus.chip(LibraryTab.RECOMMENDED) }.fillMaxSize()) {
        when (state.load) {
            LoadState.LOADING -> LoadingState()
            LoadState.ERROR -> ErrorState(state.error.orEmpty(), onRetry = recommended::reload)
            LoadState.EMPTY -> EmptyState(T.libraries.noRecommendations)
            LoadState.CONTENT -> HubShelves(state.items, appearance, focus, onOpen = { store.open(it.id) }, onMenu = { store.menu(it.id) }, onViewAll = { store.openHub(it.id) })
        }
    }
}

/**
 * Recommended's [hubs], a shelf each; Up from the first goes to the header control right above the card (focus search).
 * A hub's View All card is remembered as its cards are, so Back from its grid comes back to it.
 */
@Composable
internal fun HubShelves(
    hubs: List<HubUi>,
    appearance: Appearance,
    focus: LibrariesFocus,
    onOpen: (MediaCardUi) -> Unit,
    onMenu: (MediaCardUi) -> Unit,
    onViewAll: (HubUi) -> Unit,
) {
    val list = rememberHeaderListState()
    LazyColumn(
        Modifier
            .fillMaxSize()
            .focusGroup()
            .layoutProbe("libraries.recommended", reportsFocus = false),
        state = list,
        contentPadding = PaddingValues(bottom = 8.dp),
    ) {
        items(hubs, key = { it.id }) { hub ->
            HubRow(
                hub,
                appearance,
                Modifier.padding(bottom = 8.dp),
                cardModifier = { Modifier.rememberFocus(focus.memory, itemKey("${hub.id}/${it.id}")) },
                seeAllModifier = Modifier.rememberFocus(focus.memory, "seeAll:${hub.id}"),
                onCardClick = onOpen,
                onCardLongClick = onMenu,
                onViewAll = { onViewAll(hub) },
            )
        }
    }
}

/**
 * Focus inside this content that goes because a reload emptied it (now [shown] false: a live pass left nothing to
 * focus) goes on through [onEmptied] (the tab's chip), rather than dropping out of the screen.
 */
@Composable
internal fun Modifier.handsFocusBack(shown: Boolean, onEmptied: () -> Unit): Modifier {
    val latest by rememberUpdatedState(shown)
    val emptied by rememberUpdatedState(onEmptied)
    val scope = rememberCoroutineScope()
    val had = remember { booleanArrayOf(false) }
    return onFocusChanged { state ->
        if (had[0] && !state.hasFocus && !latest) scope.launch { emptied() }
        had[0] = state.hasFocus
    }
}

/** Browse: the grid (or the folder tree) of the library, as its grouping, filters and sort say. */
@Composable
private fun BrowseTab(browse: LibraryBrowseStore, store: LibrariesScreenStore, focus: LibrariesFocus, appearance: Appearance) {
    val state by browse.state.collectAsState()
    Box(Modifier.fillMaxSize()) {
        when {
            state.load == LoadState.ERROR -> ErrorState(state.error.orEmpty(), onRetry = browse::reload)
            state.grouping == BrowseGrouping.FOLDERS -> FolderTree(browse, store, focus)
            // A letter's reload (Jellyfin, Emby) keeps the bar beside the spinner, so a drag along it carries on.
            state.load == LoadState.LOADING && state.alphaLetters.isEmpty() -> LoadingState()
            state.load == LoadState.EMPTY && state.emptyLetter == null && state.filtersActive -> EmptyState(T.libraries.noItemsMatchFilters, icon = PlezyIcons.FilterAlt) {
                PlezyButton(T.libraries.resetFilters, onClick = { browse.applyFilters(emptyList()) }, icon = PlezyIcons.ClearAll)
            }
            state.load == LoadState.EMPTY && state.emptyLetter == null -> EmptyState(T.libraries.thisLibraryIsEmpty, icon = PlezyIcons.Folder)
            else -> PagedItemsGrid(
                filterLetter = state.filterLetter,
                onClearLetter = browse::clearLetter,
                tab = LibraryTab.BROWSE,
                focus = focus,
                total = state.total,
                card = state::card,
                shape = state.shape,
                appearance = appearance,
                letters = state.alphaLetters,
                currentLetter = state.currentLetter,
                onLetter = browse::selectLetter,
                alphaRows = browse::alphaRows,
                empty = when {
                    state.load == LoadState.LOADING -> ({ LoadingState() })
                    else -> state.emptyLetter?.let { letter -> { EmptyState(T.libraries.noTitlesStartWith(letter), icon = PlezyIcons.SearchOff) } }
                },
                jumps = browse.jumps,
                onLayout = browse::setLayout,
                onVisible = browse::visibleRange,
                onScrolling = browse::setScrolling,
                onMissing = browse::ensureIndexLoaded,
                onClick = { store.open(it.id) },
                onLongClick = { store.menu(it.id) },
            )
        }
    }
}

/**
 * Browse's options as chips (wide windows, TV): Filters and Sort, each a menu at its chip on pointer platforms
 * ([anchored]), else a sheet, then the [GroupingChip]. The sort chip names the field shown after its direction's arrow,
 * or where the row gives it no room for that ([sortLabel] false) is a round chip of the arrow alone (the sort icon while
 * none is shown), named for screen readers; the Filters chip alike shows its icon alone where the row gives it no room
 * for its label ([filtersLabel] false), filled while filters narrow the grid. Harness names:
 * `libraries.chip.<filters|sort>`.
 */
@Composable
private fun BrowseOptionChips(browse: LibraryBrowseStore, anchored: Boolean, sortLabel: Boolean, filtersLabel: Boolean, onSheet: (LibrarySheet) -> Unit) {
    val state by browse.state.collectAsState()
    if (state.showsFilters) {
        AnchoredChip(
            state.filtersLabel,
            PlezyIcons.FilterAlt,
            "libraries.chip.filters",
            anchored,
            narrowed = state.filtersActive,
            onSheet = { onSheet(LibrarySheet.Filters) },
            spoken = state.filtersLabel.takeIf { !filtersLabel },
        ) { close ->
            FiltersMenu(browse, close)
        }
    }
    if (state.showsSort) {
        val shown = state.shownSort
        val sortIcon = shown?.let { if (state.shownDescending) PlezyIcons.ArrowDownward else PlezyIcons.ArrowUpward } ?: PlezyIcons.Sort
        val spoken = shown?.let { "${T.libraries.sortBy}: ${it.title}, ${if (state.shownDescending) T.libraries.descending else T.libraries.ascending}" } ?: T.libraries.sort
        AnchoredChip(
            shown?.title ?: T.libraries.sort,
            sortIcon,
            "libraries.chip.sort",
            anchored,
            narrowed = false,
            onSheet = { onSheet(LibrarySheet.Sort) },
            spoken = spoken.takeIf { !sortLabel },
        ) { close ->
            SortMenu(state, onPick = { browse.pickSort(it); close() }, onDirection = { browse.pickDirection(it); close() }, onClear = { browse.applySort(null, false); close() })
        }
    }
    GroupingChip(browse)
}

/** Browse's grouping, the type control last among the filters: a [MenuChip] of its icon alone, named for screen readers. Harness name `libraries.chip.grouping`. */
@Composable
private fun GroupingChip(browse: LibraryBrowseStore) {
    val state by browse.state.collectAsState()
    MenuChip(
        FilterChip(T.libraries.groupings.title, state.grouping.label, spoken = "${T.libraries.groupings.title}: ${state.grouping.label}"),
        choices = state.groupings.map { MenuChoice(it.label, it == state.grouping) },
        onPick = { browse.setGrouping(state.groupings[it]) },
        probe = "libraries.chip.grouping",
        leadingIcon = PlezyIcons.Category,
        iconOnly = true,
    )
}

/**
 * A Browse option's dropdown chip: [label] after its [icon], opening [menu] at it where [anchored], else [onSheet]. With
 * [spoken] it is a round chip of the icon alone, which a screen reader hears as [spoken] and a pointer resting on it
 * shows as its tooltip.
 */
@Composable
private fun AnchoredChip(
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    probe: String,
    anchored: Boolean,
    narrowed: Boolean,
    onSheet: () -> Unit,
    spoken: String? = null,
    menu: @Composable androidx.compose.foundation.layout.ColumnScope.(close: () -> Unit) -> Unit,
) {
    var open by remember { mutableStateOf(false) }
    Box {
        PlezyChip(
            if (spoken == null) label else "",
            selected = narrowed,
            onClick = { if (anchored) open = true else onSheet() },
            leadingIcon = icon,
            dropdown = true,
            modifier = (if (spoken == null) Modifier else Modifier.semantics { contentDescription = spoken }).layoutProbe(probe),
            tooltip = spoken,
        )
        if (anchored) PlezyDropdownMenu(expanded = open, onDismiss = { open = false }) { menu { open = false } }
    }
}

@Composable
private fun PagedTab(tab: LibraryPagedTabStore<*>, libraryTab: LibraryTab, store: LibrariesScreenStore, focus: LibrariesFocus, appearance: Appearance, empty: String) {
    val state by tab.state.collectAsState()
    when (state.load) {
        LoadState.LOADING -> LoadingState()
        LoadState.ERROR -> ErrorState(state.error.orEmpty(), onRetry = tab::reload)
        LoadState.EMPTY -> EmptyState(empty)
        LoadState.CONTENT -> PagedItemsGrid(
            tab = libraryTab,
            focus = focus,
            total = state.total,
            card = state::card,
            shape = state.shape,
            appearance = appearance,
            onMissing = tab::ensureIndexLoaded,
            onClick = { store.open(it.id) },
            onLongClick = { store.menu(it.id) },
        )
    }
}

/** How long an alphabet jump scrolls (Plex). */
private const val ALPHA_JUMP_MS = 300

/**
 * [total] cells, [card] each (a blank card until it loads, which asks for its page through [onMissing]) as the
 * [MediaGrid] (the grid or the list of the view mode setting, at the density), at the screen's edges; with no cells,
 * [empty] in their place. With [letters] the alphabet bar runs down the end, its lane kept out of the width the columns
 * are counted in. [filterLetter], the letter filtering the list (Jellyfin, Emby), is named over the grid alone by a
 * control that clears it ([onClearLetter]): the bar keeps its height, so its rows never move as it comes or goes. Up
 * from the first row goes to that control where it shows, else to the header's control right above the card (the
 * nearest across), as focus search finds it.
 * [onLayout] has the columns and the rows a screen holds once laid out, and again when they change (never as it
 * scrolls).
 *
 * A letter whose items are in the list ([onLetter] gives their index: Plex) scrolls there over 300 ms; that letter stays
 * the bar's until the user scrolls, a newer jump taking over from one still running. A letter that reloads the list
 * (Jellyfin, Emby: no index) hands focus back to the bar once the grid shows again.
 */
@Composable
internal fun PagedItemsGrid(
    tab: LibraryTab,
    focus: LibrariesFocus,
    total: Int,
    card: (Int) -> MediaCardUi?,
    shape: CardShape,
    appearance: Appearance,
    onMissing: (Int) -> Unit,
    onClick: (MediaCardUi) -> Unit,
    onLongClick: (MediaCardUi) -> Unit,
    letters: List<String> = emptyList(),
    currentLetter: String? = null,
    onLetter: (String) -> Int? = { null },
    alphaRows: (Int) -> List<List<String>> = { letters.map(::listOf) },
    empty: (@Composable () -> Unit)? = null,
    filterLetter: String? = null,
    onClearLetter: () -> Unit = {},
    jumps: Flow<Int>? = null,
    onLayout: (columns: Int, rows: Int) -> Unit = { _, _ -> },
    onVisible: (first: Int, count: Int) -> Unit = { _, _ -> },
    onScrolling: (Boolean) -> Unit = {},
) {
    val firstId = if (total > 0) card(0)?.id else null
    SideEffect { focus.report(tab, firstId) }
    val dimens = LocalPlezyDimens.current
    val bar = letters.isNotEmpty()
    val side = dimens.screenPadding
    val gridState = rememberHeaderGridState()
    val reach = if (appearance.tv && appearance.viewMode != ViewMode.LIST) gridMotionReach() else 0
    val scope = rememberCoroutineScope()
    val jumper = remember(gridState) { AlphaJumper(gridState) }
    val layout by rememberUpdatedState(onLayout)
    val visible by rememberUpdatedState(onVisible)
    val scrolling by rememberUpdatedState(onScrolling)
    val letter by rememberUpdatedState(onLetter)
    LaunchedEffect(gridState, reach) {
        snapshotFlow { gridState.layoutInfo.screenGeometry(reach) }.filterNotNull().distinctUntilChanged().collect { (columns, rows) -> layout(columns, rows) }
    }
    LaunchedEffect(gridState) {
        snapshotFlow { gridState.firstVisibleItemIndex to gridState.layoutInfo.visibleItemsInfo.size }
            .distinctUntilChanged()
            .collect { (first, count) ->
                visible(first, count)
                // The letter jumped to stays the bar's until the user scrolls.
                jumper.pinned?.let(letter)
            }
    }
    LaunchedEffect(gridState) {
        snapshotFlow { gridState.isScrollInProgress }.collect { moving ->
            if (moving && !jumper.animating) jumper.pinned = null
            scrolling(moving)
        }
    }
    LaunchedEffect(jumps) { jumps?.let { gridState.followAnchorJumps(it) } }
    Box(Modifier.fillMaxSize().layoutProbe("libraries.grid", reportsFocus = false)) {
        var barFocused by remember { mutableStateOf(false) }
        val letterFocus = remember { FocusRequester() }
        var letterFocused by remember { mutableStateOf(false) }
        Column(Modifier.fillMaxSize()) {
            if (filterLetter != null) {
                PlezyChip(
                    "${T.libraries.startingWith(filterLetter)} · ${T.common.clear}",
                    selected = true,
                    onClick = {
                        // Cleared under the remote, focus goes to the tab's chip before the control goes (with the
                        // grid, while the list reloads), and from there to the first item once that lands; the bar,
                        // which the letter's pick may have asked to take focus back as it shows again, leaves it.
                        if (letterFocused) {
                            focus.alphaBarReturns = false
                            focus.memory.place(chipKey(tab))
                        }
                        onClearLetter()
                    },
                    leadingIcon = PlezyIcons.Close,
                    modifier = Modifier.padding(start = side, top = 4.dp, bottom = 4.dp)
                        .focusRequester(letterFocus)
                        .onFocusChanged { letterFocused = it.hasFocus }
                        .layoutProbe("libraries.letterFilter"),
                )
            }
            Box(Modifier.weight(1f)) {
                MediaGrid(
                    total,
                    card,
                    shape,
                    PaddingValues(start = side, end = side + if (bar) ALPHA_BAR_WIDTH + 8.dp else 0.dp, top = dimens.focusReach, bottom = dimens.sectionSpacing),
                    onClick = onClick,
                    // Up from the first row goes to the letter control wherever the column, else to what lies above.
                    modifier = Modifier
                        .focusProperties {
                            onExit = {
                                if (requestedFocusDirection == FocusDirection.Up && filterLetter != null) letterFocus.requestFocus()
                            }
                        }
                        .focusGroup(),
                    state = gridState,
                    appearance = appearance,
                    list = appearance.viewMode == ViewMode.LIST,
                    cardModifier = { _, item -> Modifier.rememberFocus(focus.memory, itemKey(item.id)) },
                    onLongClick = onLongClick,
                    onMissing = onMissing,
                    layerMotion = appearance.tv,
                )
                if (total == 0) empty?.invoke()
            }
        }
        if (bar) {
            LaunchedEffect(Unit) {
                if (focus.alphaBarReturns) {
                    focus.alphaBarReturns = false
                    focus.alphaBar.requestFocus()
                }
            }
            val jump = { picked: String ->
                val index = onLetter(picked)
                if (index == null) focus.alphaBarReturns = barFocused
                index?.let { jumper.jump(scope, picked, it) }
            }
            AlphaJumpBar(
                letters,
                currentLetter,
                alphaRows,
                Modifier.align(Alignment.CenterEnd)
                    .padding(end = side, top = dimens.focusReach)
                    .onFocusChanged { barFocused = it.hasFocus }
                    .focusRequester(focus.alphaBar),
                onJump = { picked ->
                    // Select on the letter Up and Down already jumped to keeps it (a second Select picks it again).
                    val settled = picked == focus.alphaSettled
                    focus.alphaSettled = null
                    if (!settled) jump(picked)
                },
                onSettle = { picked ->
                    jump(picked)
                    focus.alphaSettled = picked
                },
                onExit = {
                    focus.alphaSettled = null
                    focusNearRow(gridState, total, card, focus)
                },
            )
        }
    }
}

/**
 * The columns and the rows a screen of the grid holds, once laid out: rows from its first cell's height, in its height
 * less the [reach] it is laid out past each end ([gridMotionReach]).
 */
private fun LazyGridLayoutInfo.screenGeometry(reach: Int): Pair<Int, Int>? {
    val cell = visibleItemsInfo.firstOrNull() ?: return null
    val row = cell.size.height + mainAxisItemSpacing
    return maxSpan.coerceAtLeast(1) to ((viewportSize.height - 2 * reach) / row.coerceAtLeast(1)).coerceAtLeast(1)
}

/**
 * Alphabet jumps of one grid: each scrolls to its letter's row over [ALPHA_JUMP_MS], easing in and out; a newer one
 * cancels one still running. [pinned]: the letter jumped to, until the user scrolls.
 */
private class AlphaJumper(private val grid: LazyGridState) {
    var pinned: String? = null
    var animating = false
        private set
    private var generation = 0
    private var running: Job? = null

    fun jump(scope: CoroutineScope, letter: String, index: Int) {
        val info = grid.layoutInfo
        val columns = info.maxSpan.coerceAtLeast(1)
        val rowPx = (info.visibleItemsInfo.firstOrNull()?.size?.height ?: 0) + info.mainAxisItemSpacing
        val current = ++generation
        pinned = letter
        animating = true
        running?.cancel()
        running = scope.launch {
            try {
                val row = index / columns
                val firstRow = grid.firstVisibleItemIndex / columns
                val distance = (row - firstRow) * rowPx.toFloat() - grid.firstVisibleItemScrollOffset
                grid.animateScrollBy(distance, tween(ALPHA_JUMP_MS, easing = CubicBezierEasing(0.42f, 0f, 0.58f, 1f)))
                if (current == generation) grid.scrollToItem(row * columns)
            } finally {
                if (current == generation) animating = false
            }
        }
    }
}

/** Focus to the last column's item of the first row shown, else the shown item nearest it (leaving the alphabet bar). */
private fun focusNearRow(grid: LazyGridState, total: Int, card: (Int) -> MediaCardUi?, focus: LibrariesFocus) {
    val columns = grid.layoutInfo.maxSpan.coerceAtLeast(1)
    val first = grid.firstVisibleItemIndex
    val target = (first - first % columns + columns - 1).coerceAtMost(total - 1)
    grid.layoutInfo.visibleItemsInfo.map { it.index }.sortedBy { kotlin.math.abs(it - target) }
        .firstOrNull { index -> card(index)?.let { focus.memory.focus(itemKey(it.id)) } == true }
}

/** Folders grouping: the tree, a pull at its top reloading it from the root. */
@Composable
private fun FolderTree(browse: LibraryBrowseStore, store: LibrariesScreenStore, focus: LibrariesFocus) {
    val state by browse.state.collectAsState()
    val tree = state.folders
    SideEffect { focus.report(LibraryTab.BROWSE, tree?.rows?.firstOrNull()?.let { "folder/${it.id}" }) }
    TouchPullToRefresh(refreshing = false, onRefresh = store::refreshTab, modifier = Modifier.fillMaxSize()) {
        when {
            tree == null || tree.load == LoadState.LOADING && tree.rows.isEmpty() -> LoadingState()
            tree.load == LoadState.ERROR -> ErrorState(tree.error.orEmpty(), onRetry = browse::reload)
            tree.rows.isEmpty() -> EmptyState(T.libraries.noFoldersFound, icon = PlezyIcons.Folder)
            else -> {
                val playable = store.canPlayFolders
                val side = LocalPlezyDimens.current.screenPadding
                val list = rememberHeaderListState()
                LazyColumn(
                    Modifier.fillMaxSize().layoutProbe("libraries.folders", reportsFocus = false),
                    state = list,
                    contentPadding = PaddingValues(start = side, end = side, bottom = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    items(tree.rows, key = { it.id }) { row ->
                        FolderRow(
                            row,
                            playable,
                            Modifier.rememberFocus(focus.memory, itemKey("folder/${row.id}")),
                            onClick = { store.open(row.id) },
                            onMenu = { store.menu(row.id) },
                            onPlay = { store.playFolder(row.id, it) },
                        )
                    }
                }
            }
        }
    }
}

/**
 * A row of the folder tree, indented by its depth. A folder that plays ([playable]) ends in Play and Shuffle, and its
 * long press, secondary click or Menu key opens a Play and Shuffle menu; dismissed, focus goes back to the row. An
 * item's long press or secondary click opens its menu ([onMenu]).
 */
@Composable
private fun FolderRow(row: FolderRowUi, playable: Boolean, modifier: Modifier, onClick: () -> Unit, onMenu: () -> Unit, onPlay: (shuffle: Boolean) -> Unit) {
    val folderMenu = row.folder && playable
    var menuOpen by remember { mutableStateOf(false) }
    val self = remember { FocusRequester() }
    val openMenu = { if (folderMenu) menuOpen = true else if (!row.folder) onMenu() }
    Box {
        PlezySurface(
            onClick = onClick,
            modifier = modifier.fillMaxWidth().focusRequester(self).menuGestures(openMenu).layoutProbe("libraries.folder.${row.title}"),
            color = Color.Transparent,
            onLongClick = openMenu.takeIf { folderMenu || !row.folder },
            grows = false,
        ) {
            Row(
                Modifier.padding(start = 8.dp + (row.depth * 24).dp, end = 8.dp, top = 6.dp, bottom = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                if (row.folder || row.expandable) {
                    Box(Modifier.width(24.dp), contentAlignment = Alignment.Center) {
                        if (row.loading) {
                            CircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp)
                        } else {
                            Icon(if (row.expanded) PlezyIcons.ArrowDropDown else PlezyIcons.ChevronRight, contentDescription = null, tint = PlezyColors.MutedContent)
                        }
                    }
                }
                if (row.folder) {
                    Icon(PlezyIcons.Folder, contentDescription = null, Modifier.size(24.dp))
                    Text(row.title, style = MaterialTheme.typography.bodyLarge, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
                    if (playable) {
                        PlezyIconButton(PlezyIcons.PlayArrow, T.common.play, onClick = { onPlay(false) }, style = IconButtonStyle.PLAIN, size = 36.dp)
                        PlezyIconButton(PlezyIcons.Shuffle, T.common.shuffle, onClick = { onPlay(true) }, style = IconButtonStyle.PLAIN, size = 36.dp)
                    }
                } else {
                    val thumb = if (row.wide) Modifier.size(128.dp, 72.dp) else Modifier.size(48.dp, 72.dp)
                    RemoteImage(
                        row.thumb,
                        contentDescription = null,
                        modifier = thumb.clip(MaterialTheme.shapes.small),
                        blank = PlezyColors.SurfaceHigh,
                        blurred = row.blurred,
                        error = { ArtworkPlaceholder(row.placeholder) },
                    )
                    Column(Modifier.weight(1f)) {
                        Text(row.title, style = MaterialTheme.typography.bodyLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        val muted = PlezyColors.MutedContent
                        row.subtitle?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = muted, maxLines = 1) }
                        row.metadata?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = muted, maxLines = 1) }
                    }
                    if (row.watched) Icon(PlezyIcons.CheckCircle, contentDescription = null, Modifier.size(20.dp))
                }
            }
        }
        if (folderMenu) {
            ItemMenu(
                expanded = menuOpen,
                onDismiss = {
                    menuOpen = false
                    self.requestFocus()
                },
                entries = listOf(
                    ItemMenuEntry(T.common.play, probe = "play", icon = PlezyIcons.PlayArrow) { onPlay(false) },
                    ItemMenuEntry(T.common.shuffle, probe = "shuffle", icon = PlezyIcons.Shuffle) { onPlay(true) },
                ),
                probe = "libraries.folderMenu",
                title = row.title,
                contentTitle = true,
            )
        }
    }
}

/** Genres: a tile per genre a pull reloads; focus in the tiles when a reload leaves none goes back to the tab's chip. */
@Composable
private fun GenresTab(store: LibrariesScreenStore, focus: LibrariesFocus) {
    val genres = remember(store) { store.genres() } ?: return
    val state by genres.state.collectAsState()
    val first = state.items.firstOrNull()?.takeIf { state.load == LoadState.CONTENT }?.let { "genre/${it.filterValue}" }
    SideEffect { focus.report(LibraryTab.GENRES, first) }
    TouchPullToRefresh(refreshing = false, onRefresh = store::refreshTab, modifier = Modifier.handsFocusBack(shown = first != null) { focus.chip(LibraryTab.GENRES) }.fillMaxSize()) {
        when (state.load) {
            LoadState.LOADING -> LoadingState()
            LoadState.ERROR -> ErrorState(state.error.orEmpty(), onRetry = genres::reload)
            LoadState.EMPTY -> EmptyState(T.libraries.noGenres, icon = PlezyIcons.TheaterComedy)
            LoadState.CONTENT -> {
                val dimens = LocalPlezyDimens.current
                val grid = rememberHeaderGridState()
                LazyVerticalGrid(
                    state = grid,
                    columns = GridCells.Adaptive(GENRE_TILE_WIDTH),
                    contentPadding = PaddingValues(start = dimens.screenPadding, end = dimens.screenPadding, top = dimens.focusReach, bottom = dimens.sectionSpacing),
                    horizontalArrangement = Arrangement.spacedBy(dimens.gutter),
                    verticalArrangement = Arrangement.spacedBy(dimens.gutter),
                    // Up from the first row goes to the tab's chip, wherever the column.
                    modifier = Modifier
                        .fillMaxSize()
                        .focusProperties { onExit = { if (requestedFocusDirection == FocusDirection.Up) focus.chip(LibraryTab.GENRES) } }
                        .focusGroup()
                        .layoutProbe("libraries.genres", reportsFocus = false),
                ) {
                    items(state.items.size, key = { state.items[it].filterValue }) { index ->
                        val genre = state.items[index]
                        GenreTile(genre, Modifier.rememberFocus(focus.memory, itemKey("genre/${genre.filterValue}"))) { store.openGenre(genre.filterValue) }
                    }
                }
            }
        }
    }
}

private val GENRE_TILE_WIDTH = 160.dp

/** A genre: its art under its accent colour, its name over it. */
@Composable
private fun GenreTile(genre: GenreTileUi, modifier: Modifier, onClick: () -> Unit) {
    val accent = Color(0xFF000000 or genre.accentRgb.toLong())
    PlezySurface(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().aspectRatio(16f / 9f).layoutProbe("libraries.genre.${genre.title}"),
        color = accent,
        contentColor = Color.White,
        contentAlignment = Alignment.Center,
    ) {
        genre.art?.let { RemoteImage(it, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
        Box(Modifier.fillMaxSize().background(accent.copy(alpha = 0.78f)))
        Text(
            genre.title,
            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold, shadow = Shadow(Color.Black.copy(alpha = 0.4f), blurRadius = 6f)),
            color = Color.White,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(12.dp),
        )
    }
}

/**
 * Keeps the anchor (first visible item) still across a live refresh: each index from [jumps] is the anchor's new
 * position, jumped to on the next frame at the same pixel offset. A drag or fling started in between wins, and the
 * jump is dropped.
 */
internal suspend fun LazyGridState.followAnchorJumps(jumps: Flow<Int>) = coroutineScope {
    var scrollStarts = 0
    launch { snapshotFlow { isScrollInProgress }.collect { if (it) scrollStarts++ } }
    jumps.collect { index ->
        val starts = scrollStarts
        val offset = firstVisibleItemScrollOffset
        withFrameNanos { }
        if (scrollStarts == starts && !isScrollInProgress) scrollToItem(index, offset)
    }
}
