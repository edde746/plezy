@file:OptIn(ExperimentalFoundationApi::class)

package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.InputTransformation
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.input.clearText
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.model.FilterEditorKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterValue
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.presentation.libraries.BrowseUiState
import com.edde746.plezy.presentation.libraries.LibrariesScreenStore
import com.edde746.plezy.presentation.libraries.LibrariesUiState
import com.edde746.plezy.presentation.libraries.LibraryBrowseStore
import com.edde746.plezy.presentation.libraries.LibraryListEntry
import com.edde746.plezy.presentation.libraries.RELATIVE_DATE_WINDOWS
import com.edde746.plezy.presentation.libraries.booleanFilterState
import com.edde746.plezy.presentation.libraries.filterFieldSummary
import com.edde746.plezy.presentation.libraries.isFilterExcluded
import com.edde746.plezy.presentation.libraries.nextBooleanFilterState
import com.edde746.plezy.presentation.libraries.numberBound
import com.edde746.plezy.presentation.libraries.relativeDateLabel
import com.edde746.plezy.presentation.libraries.selectedFilterValues
import com.edde746.plezy.presentation.libraries.textMatchLabel
import com.edde746.plezy.presentation.libraries.textMatchModes
import com.edde746.plezy.presentation.libraries.toggleFilterValue
import com.edde746.plezy.presentation.libraries.withBooleanFilter
import com.edde746.plezy.presentation.libraries.withDateWindow
import com.edde746.plezy.presentation.libraries.withFilterExcluded
import com.edde746.plezy.presentation.libraries.withNumberRange
import com.edde746.plezy.presentation.libraries.withTextMatch
import com.edde746.plezy.model.clausesFor
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.components.BooleanFilterRow
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.FilterFieldRow
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.ItemMenuSection
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezyMenuItem
import com.edde746.plezy.ui.components.MenuSectionTitle
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.SectionedItemMenu
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.SCROLL_EDGE_FADE
import com.edde746.plezy.ui.components.SheetOption
import com.edde746.plezy.ui.components.directionKey
import com.edde746.plezy.ui.components.hidesRowsAbove
import com.edde746.plezy.ui.components.hidesRowsBelow
import com.edde746.plezy.ui.components.scrollEdgeFades
import com.edde746.plezy.ui.focus.StayInViewSpec
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/** The Libraries screen's sheets: the phone's Library options, or one of Browse's options on TV and touch screens. */
sealed interface LibrarySheet {
    /** The phone's Library options: filters and sort, each a page of the same sheet. */
    data object Options : LibrarySheet

    data object Sort : LibrarySheet

    data object Filters : LibrarySheet
}

@Composable
internal fun LibrarySheets(sheet: LibrarySheet, store: LibrariesScreenStore, onDismiss: () -> Unit) {
    val browse = store.browse() ?: return onDismiss()
    BrowseOptionsSheet(browse, start = sheet, root = sheet == LibrarySheet.Options, onDismiss = onDismiss)
}

/**
 * The library chip, first in the filter row: the selected library's name with its kind's icon where [icon]. It opens the
 * visible libraries under their servers' headers as the setting says, the selected one checked, as a menu
 * ([SectionedItemMenu]). Harness names: the chip `libraries.picker`, its entries `libraries.pick.<title>`.
 */
@Composable
internal fun LibraryPicker(
    state: LibrariesUiState,
    onLibrary: (String) -> Unit,
    icon: Boolean = true,
) {
    val selected = state.selected
    if (state.entries.isEmpty()) return
    var open by remember { mutableStateOf(false) }
    Box {
        PlezyChip(
            selected?.title ?: T.libraries.title,
            selected = false,
            onClick = { open = true },
            leadingIcon = selected?.let { libraryIcon(it.kind) }.takeIf { icon },
            dropdown = true,
            contentLabel = selected != null,
            modifier = Modifier.layoutProbe("libraries.picker"),
        )
        val sections = buildList {
            var title: String? = null
            val rows = mutableListOf<ItemMenuEntry>()
            fun flush() {
                if (rows.isNotEmpty() || title != null) add(ItemMenuSection(title, rows.toList()))
                rows.clear()
            }
            for (entry in state.entries) {
                when (entry) {
                    is LibraryListEntry.Header -> {
                        flush()
                        title = entry.serverName
                    }
                    is LibraryListEntry.Row -> rows += ItemMenuEntry(
                        entry.library.title,
                        probe = entry.library.title,
                        selected = entry.library.globalKey == selected?.globalKey,
                        icon = libraryIcon(entry.library.kind),
                        contentLabel = true,
                        detail = entry.library.serverName.takeIf { entry.showServerName },
                    ) { onLibrary(entry.library.globalKey) }
                }
            }
            flush()
        }
        SectionedItemMenu(open, onDismiss = { open = false }, sections = sections, probe = "libraries.pick", title = T.libraries.selectLibrary)
    }
}

/**
 * The Browse options as sheets: the mobile Library options' list of pages, or one page (sort, filters). Filter edits are
 * staged and committed once as the sheet closes; on touch screens the filters pages end with Cancel, which drops them,
 * and Apply (harness names `libraries.filters.cancel`, `libraries.filters.apply`), a swipe down still committing them.
 * The sort page opens with focus on the shown field. A focused row already on screen and clear of the page's fades
 * doesn't scroll the page ([StayInViewSpec]).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun BrowseOptionsSheet(browse: LibraryBrowseStore, start: LibrarySheet, root: Boolean, onDismiss: () -> Unit) {
    val state by browse.state.collectAsState()
    var page by remember { mutableStateOf(start) }
    var staged by remember { mutableStateOf(state.selectedFilters) }
    var field by remember { mutableStateOf<MediaFilter?>(null) }
    val libraryKey = remember { browse.libraryKey }
    val sortFocus = remember { FocusRequester() }
    val close = {
        browse.applyFilters(staged, libraryKey)
        onDismiss()
    }
    val back: () -> Unit = when {
        field != null -> ({ field = null })
        root && page != LibrarySheet.Options -> ({ page = LibrarySheet.Options })
        else -> close
    }
    val title = when {
        field != null -> field?.title
        page == LibrarySheet.Options -> T.libraries.libraryOptions
        page == LibrarySheet.Sort -> T.libraries.sort
        else -> T.libraries.filters
    }
    val touch = LocalWindowLayout.current.formFactor == FormFactor.HANDHELD
    // The header as one row: Back (on a page under the options) or the options' icon, then the title. A partial sheet
    // closes by its drag handle, a swipe down, the scrim or Back; a docked panel adds its close button to this row.
    PlezySheet(
        onDismiss = close,
        onBack = back,
        label = title,
        probe = "libraries.optionsSheet",
        initialFocus = sortFocus.takeIf { page == LibrarySheet.Sort },
        header = {
            if (back !== close) {
                PlezyIconButton(PlezyIcons.ArrowBack, T.common.back, onClick = back, style = IconButtonStyle.PLAIN, modifier = Modifier.layoutProbe("libraries.sheet.back"))
            } else if (page == LibrarySheet.Options) {
                Icon(PlezyIcons.Tune, contentDescription = null, Modifier.padding(horizontal = 12.dp).size(22.dp))
            }
            Text(title.orEmpty(), style = MaterialTheme.typography.titleLarge, modifier = Modifier.weight(1f))
        },
    ) {
        // Each page scrolls itself: the sheet doesn't. Fades over its top and bottom while it holds more there, past its
        // padding (the sort page, which opens on the shown field below Clear and the directions, and cuts its last rows).
        val scroll = rememberScrollState()
        val reach = LocalPlezyDimens.current.focusReach
        val reachPx = with(LocalDensity.current) { reach.roundToPx() }
        val platformScroll = LocalBringIntoViewSpec.current
        val fade = with(LocalDensity.current) { SCROLL_EDGE_FADE.toPx() }
        val stayInView = remember(platformScroll, fade) { StayInViewSpec(platformScroll, before = fade, after = fade) }
        CompositionLocalProvider(LocalBringIntoViewSpec provides stayInView) {
            Column(
                Modifier
                    .weight(1f, fill = false)
                    .scrollEdgeFades({ scroll.hidesRowsAbove(reachPx) }, { scroll.hidesRowsBelow(reachPx) })
                    .verticalScroll(scroll)
                    .padding(vertical = reach),
            ) {
                when (page) {
                    LibrarySheet.Options -> {
                        if (state.showsFilters) {
                            SheetOption(state.filtersLabel, onClick = { page = LibrarySheet.Filters }, choice = false, icon = PlezyIcons.FilterAlt, modifier = Modifier.layoutProbe("libraries.options.filters"))
                        }
                        if (state.showsSort) {
                            SheetOption(T.libraries.sort, onClick = { page = LibrarySheet.Sort }, detail = state.shownSort?.title, choice = false, icon = PlezyIcons.Sort, modifier = Modifier.layoutProbe("libraries.options.sort"))
                        }
                    }
                    LibrarySheet.Sort -> SortSheetBody(
                        state,
                        onPick = { browse.pickSort(it); close() },
                        onDirection = { browse.pickDirection(it); close() },
                        onClear = { browse.applySort(null, false); close() },
                        initial = sortFocus,
                    )
                    else -> FiltersEditor(browse, state, staged, field, onStaged = { staged = it }, onField = { field = it })
                }
            }
        }
        if (touch && page == LibrarySheet.Filters) {
            OverlayActions {
                PlezyButton(T.common.cancel, onDismiss, Modifier.layoutProbe("libraries.filters.cancel"), style = ButtonStyle.TEXT)
                PlezyButton(T.common.apply, close, Modifier.layoutProbe("libraries.filters.apply"), style = ButtonStyle.PRIMARY)
            }
        }
    }
}

/**
 * The desktop filters popup's content at its chip, 380 wide and at most 560 tall: the header (Back on a field's page,
 * else the filter icon; the title; Close) over the editor. Edits are staged and committed once, as the popup closes
 * by any route.
 */
@Composable
internal fun FiltersMenu(browse: LibraryBrowseStore, close: () -> Unit) {
    val state by browse.state.collectAsState()
    var staged by remember { mutableStateOf(state.selectedFilters) }
    var field by remember { mutableStateOf<MediaFilter?>(null) }
    val libraryKey = remember { browse.libraryKey }
    val latest by rememberUpdatedState(staged)
    DisposableEffect(browse) { onDispose { browse.applyFilters(latest, libraryKey) } }
    Column(Modifier.width(380.dp).heightIn(max = 560.dp).verticalScroll(rememberScrollState())) {
        Row(Modifier.fillMaxWidth().padding(start = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            if (field != null) {
                PlezyIconButton(PlezyIcons.ArrowBack, T.common.back, onClick = { field = null }, style = IconButtonStyle.PLAIN, modifier = Modifier.layoutProbe("libraries.sheet.back"))
            } else {
                Icon(PlezyIcons.FilterAlt, contentDescription = null, Modifier.padding(horizontal = 12.dp).size(20.dp))
            }
            Text(field?.title ?: T.libraries.filters, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
            PlezyIconButton(PlezyIcons.Close, T.common.close, onClick = close, style = IconButtonStyle.PLAIN, modifier = Modifier.layoutProbe("libraries.sheet.close"))
        }
        FiltersEditor(browse, state, staged, field, onStaged = { staged = it }, onField = { field = it })
    }
}

/**
 * The sort menu at its chip: Clear while a sort is set; Ascending and Descending for the field shown (the chosen sort,
 * else the server's own order), its direction checked; then under Sort By one row per field, the shown one checked, a
 * pick taking the field's own direction from the unsorted state, else keeping the direction ([LibraryBrowseStore.pickSort]).
 */
@Composable
internal fun ColumnScope.SortMenu(state: BrowseUiState, onPick: (MediaSort) -> Unit, onDirection: (Boolean) -> Unit, onClear: () -> Unit) {
    if (state.sort != null) {
        PlezyMenuItem(T.common.clear, onClick = onClear, icon = PlezyIcons.Close, modifier = Modifier.layoutProbe("libraries.sort.clear"))
        HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
    }
    if (state.shownSort != null) {
        for (descending in listOf(false, true)) {
            PlezyMenuItem(
                directionLabel(descending),
                onClick = { onDirection(descending) },
                selected = descending == state.shownDescending,
                choice = true,
                icon = directionIcon(descending),
                modifier = Modifier.layoutProbe("libraries.sort.${directionProbe(descending)}"),
            )
        }
        HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
        MenuSectionTitle(T.libraries.sortBy)
    }
    for (sort in state.sorts) {
        PlezyMenuItem(
            sort.title,
            onClick = { onPick(sort) },
            selected = sort.key == state.shownSort?.key,
            choice = true,
            modifier = Modifier.layoutProbe("libraries.sort.${sort.key}"),
        )
    }
}

/**
 * The sort sheet, as the sort menu ([SortMenu]): Clear while a sort is set; Ascending and Descending for the field shown
 * (the chosen sort, else the server's own order), its direction checked; then under Sort By one row per field, the
 * shown one checked, a pick taking the field's own direction from the unsorted state, else keeping the direction
 * ([LibraryBrowseStore.pickSort]). Each pick goes to [onPick],
 * [onDirection] or [onClear] (which close the sheet). The shown field's row (else the first) takes focus ([initial],
 * also the sheet's first focus) as the page shows, and is brought into view.
 */
@Composable
internal fun ColumnScope.SortSheetBody(
    state: BrowseUiState,
    onPick: (MediaSort) -> Unit,
    onDirection: (Boolean) -> Unit,
    onClear: () -> Unit,
    initial: FocusRequester = remember { FocusRequester() },
) {
    if (state.sort != null) {
        SheetOption(T.common.clear, onClick = onClear, choice = false, icon = PlezyIcons.Close, modifier = Modifier.layoutProbe("libraries.sort.clear"))
        HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
    }
    val shown = state.shownSort
    if (shown != null) {
        for (descending in listOf(false, true)) {
            SheetOption(
                directionLabel(descending),
                onClick = { onDirection(descending) },
                selected = descending == state.shownDescending,
                icon = directionIcon(descending),
                modifier = Modifier.layoutProbe("libraries.sort.${directionProbe(descending)}"),
            )
        }
        HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
        GroupHeader(T.libraries.sortBy)
    }
    val focused = state.sorts.indexOfFirst { it.key == shown?.key }.coerceAtLeast(0)
    state.sorts.forEachIndexed { index, sort ->
        SheetOption(
            sort.title,
            onClick = { onPick(sort) },
            selected = sort.key == shown?.key,
            modifier = Modifier
                .then(if (index == focused) Modifier.focusRequester(initial) else Modifier)
                .layoutProbe("libraries.sort.${sort.key}"),
        )
    }
    if (state.sorts.isNotEmpty()) LaunchedEffect(Unit) { initial.requestFocus() }
}

private fun directionLabel(descending: Boolean) = if (descending) T.libraries.descending else T.libraries.ascending

private fun directionIcon(descending: Boolean) = if (descending) PlezyIcons.ArrowDownward else PlezyIcons.ArrowUpward

private fun directionProbe(descending: Boolean) = if (descending) "descending" else "ascending"

/** The filter editor: the fields (yes/no ones as Any/Yes/No in place), each other field a page of its values. */
@Composable
private fun ColumnScope.FiltersEditor(
    browse: LibraryBrowseStore,
    state: BrowseUiState,
    staged: List<LibraryFilter>,
    field: MediaFilter?,
    onStaged: (List<LibraryFilter>) -> Unit,
    onField: (MediaFilter?) -> Unit,
) {
    val serverId = browse.serverId
    if (field == null) {
        if (staged.isNotEmpty()) SheetOption(T.libraries.clearAll, onClick = { onStaged(emptyList()) }, icon = PlezyIcons.ClearAll, choice = false, modifier = Modifier.layoutProbe("libraries.filters.clear"))
        for (filter in state.filters) {
            if (filter.isBoolean) {
                BooleanFilterRow(
                    filter.title,
                    booleanFilterState(staged, filter.filter),
                    filter.supportsExclusion,
                    onChange = { onStaged(withBooleanFilter(staged, filter.filter, it)) },
                    modifier = Modifier.layoutProbe("libraries.filter.${filter.filter}"),
                )
            } else {
                FilterFieldRow(
                    filter.title,
                    filterFieldSummary(filter, staged, serverId, browse.libraryKey),
                    onClick = { onField(filter) },
                    modifier = Modifier.layoutProbe("libraries.filter.${filter.filter}"),
                )
            }
        }
        return
    }
    when (field.editorKind) {
        FilterEditorKind.VALUE_LIST -> ValuePage(browse, field, staged, onStaged)
        FilterEditorKind.NUMBER -> NumberPage(field, staged, onStaged)
        FilterEditorKind.DATE -> DatePage(field, staged, onStaged)
        else -> TextPage(field, staged, onStaged)
    }
}

/** Exclude for a value list: one focus stop with its switch; Select turns it over, Left includes, Right excludes. */
@Composable
internal fun IncludeExcludeRow(excluded: Boolean, onChange: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    SheetOption(
        T.libraries.advancedFilters.exclude,
        onClick = { onChange(!excluded) },
        choice = false,
        badge = { RowSwitch(excluded) },
        modifier = modifier.onPreviewKeyEvent { event -> directionKey(event)?.let { onChange(it); true } ?: false },
    )
}

/** A value list: All, then Include/Exclude where the field can be negated, then the values (a search past 15). */
@Composable
private fun ColumnScope.ValuePage(browse: LibraryBrowseStore, field: MediaFilter, staged: List<LibraryFilter>, onStaged: (List<LibraryFilter>) -> Unit) {
    var values by remember(field) { mutableStateOf<List<MediaFilterValue>?>(null) }
    var failed by remember(field) { mutableStateOf(false) }
    var attempt by remember(field) { mutableIntStateOf(0) }
    val query = remember(field) { TextFieldState() }
    LaunchedEffect(field, attempt) {
        failed = false
        values = runCatching { browse.filterValues(field) }.onFailure { failed = true }.getOrNull()
    }
    val selected = selectedFilterValues(staged, field.filter)
    val excluded = isFilterExcluded(staged, field.filter)
    SheetOption(T.libraries.all, onClick = { onStaged(staged.filterNot { it.field == field.filter }) }, selected = selected.isEmpty())
    if (field.supportsExclusion) {
        IncludeExcludeRow(excluded, onChange = { onStaged(withFilterExcluded(staged, field.filter, it)) }, modifier = Modifier.layoutProbe("libraries.filter.exclude"))
    }
    val loaded = values
    when {
        failed -> SheetOption(T.errors.unableToLoad(field.title), onClick = { attempt++ }, choice = false, icon = PlezyIcons.Refresh)
        loaded == null -> Box(Modifier.fillMaxWidth().height(160.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        else -> {
            if (loaded.size > 15) SearchField(query)
            val typed = query.text.toString()
            val shown = loaded.filter { typed.isEmpty() || it.title.contains(typed, ignoreCase = true) }
            if (shown.isEmpty()) Text(T.libraries.advancedFilters.noValues, color = PlezyColors.TextMuted, modifier = Modifier.padding(16.dp))
            // The page opens at the first selected value.
            val firstSelected = shown.firstOrNull { browse.valueId(field, it) in selected }
            val bring = remember(field) { BringIntoViewRequester() }
            if (firstSelected != null) LaunchedEffect(field) { bring.bringIntoView() }
            for (value in shown) {
                val id = browse.valueId(field, value)
                SheetOption(
                    value.title,
                    onClick = { onStaged(toggleFilterValue(staged, field.filter, id, exclude = excluded)) },
                    selected = id in selected,
                    contentLabel = true,
                    modifier = Modifier
                        .then(if (value == firstSelected) Modifier.bringIntoViewRequester(bring) else Modifier)
                        .layoutProbe("libraries.value.${value.title}"),
                )
            }
        }
    }
}

@Composable
private fun SearchField(query: TextFieldState) {
    Row(
        Modifier.fillMaxWidth().padding(start = 16.dp, top = 4.dp, end = 16.dp, bottom = 8.dp)
            .background(PlezyColors.Text.copy(alpha = 0.08f), RoundedCornerShape(12.dp)).padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(PlezyIcons.Search, contentDescription = null, Modifier.size(20.dp), tint = PlezyColors.TextMuted)
        Spacer(Modifier.width(8.dp))
        Box(Modifier.weight(1f)) {
            if (query.text.isEmpty()) Text(T.libraries.advancedFilters.searchValues, color = PlezyColors.TextMuted)
            FilterTextField(query, Modifier)
        }
    }
}

/** A number range: All, then From and To in the field's unit. */
@Composable
internal fun ColumnScope.NumberPage(field: MediaFilter, staged: List<LibraryFilter>, onStaged: (List<LibraryFilter>) -> Unit) {
    val unit = field.unit
    val from = remember(field) { TextFieldState(numberBound(staged, field.filter, LibraryFilterOperator.AT_LEAST, unit)?.toString().orEmpty()) }
    val to = remember(field) { TextFieldState(numberBound(staged, field.filter, LibraryFilterOperator.AT_MOST, unit)?.toString().orEmpty()) }
    val commit = { onStaged(withNumberRange(staged, field.filter, from.text.toString().toLongOrNull(), to.text.toString().toLongOrNull(), unit)) }
    OnTextChange(from) { commit() }
    OnTextChange(to) { commit() }
    SheetOption(T.libraries.all, onClick = { from.clearText(); to.clearText(); commit() }, selected = staged.clausesFor(field.filter).isEmpty())
    for ((label, value) in listOf(T.libraries.advancedFilters.from to from, T.libraries.advancedFilters.to to to)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(label, color = PlezyColors.Text, modifier = Modifier.width(80.dp))
            FilterTextField(
                value,
                Modifier.weight(1f).background(PlezyColors.Text.copy(alpha = 0.08f), RoundedCornerShape(8.dp)).padding(10.dp),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                inputTransformation = {
                    val digits = asCharSequence().filter(Char::isDigit)
                    if (digits.length != length) replace(0, length, digits)
                },
            )
            unit.suffix?.let { Text(it, color = PlezyColors.TextMuted, modifier = Modifier.padding(start = 8.dp)) }
        }
    }
}

/** A date: All, the last 7/30/90 days and year, then older than each. One clause. */
@Composable
private fun ColumnScope.DatePage(field: MediaFilter, staged: List<LibraryFilter>, onStaged: (List<LibraryFilter>) -> Unit) {
    val clause = staged.clausesFor(field.filter).firstOrNull()
    SheetOption(T.libraries.all, onClick = { onStaged(withDateWindow(staged, field.filter, null, false)) }, selected = clause == null)
    for (older in listOf(false, true)) {
        for (window in RELATIVE_DATE_WINDOWS) {
            val op = if (older) LibraryFilterOperator.AT_MOST else LibraryFilterOperator.AT_LEAST
            SheetOption(
                relativeDateLabel(window, older),
                onClick = { onStaged(withDateWindow(staged, field.filter, window, older)) },
                selected = clause?.op == op && clause.values.firstOrNull() == window,
            )
        }
    }
}

/** Text: All first, the text, then the match modes the field supports. */
@Composable
private fun ColumnScope.TextPage(field: MediaFilter, staged: List<LibraryFilter>, onStaged: (List<LibraryFilter>) -> Unit) {
    val clause = staged.clausesFor(field.filter).firstOrNull()
    val text = remember(field) { TextFieldState(clause?.values?.firstOrNull().orEmpty()) }
    var mode by remember(field) { mutableStateOf(clause?.op ?: LibraryFilterOperator.IS) }
    OnTextChange(text) { onStaged(withTextMatch(staged, field.filter, it, mode)) }
    SheetOption(T.libraries.all, onClick = { text.clearText(); onStaged(withTextMatch(staged, field.filter, "", mode)) }, selected = clause == null)
    Box(Modifier.fillMaxWidth().padding(16.dp, 8.dp, 16.dp, 8.dp).background(PlezyColors.Text.copy(alpha = 0.08f), RoundedCornerShape(12.dp)).padding(12.dp)) {
        if (text.text.isEmpty()) Text(T.libraries.advancedFilters.textHint, color = PlezyColors.TextMuted)
        FilterTextField(text, Modifier.fillMaxWidth())
    }
    for (op in textMatchModes(field)) {
        SheetOption(textMatchLabel(op), onClick = { mode = op; onStaged(withTextMatch(staged, field.filter, text.text.toString(), op)) }, selected = op == mode)
    }
}

/** A filter page's single-line text field: on TV its keyboard waits for Select and the arrows leave it. */
@Composable
private fun FilterTextField(
    state: TextFieldState,
    modifier: Modifier,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    inputTransformation: InputTransformation? = null,
) {
    val keyboard = rememberKeyboardOnSelect()
    BasicTextField(
        state = state,
        modifier = modifier.then(keyboard.modifier).remoteLeavesField(state),
        readOnly = keyboard.readOnly,
        inputTransformation = inputTransformation,
        textStyle = MaterialTheme.typography.bodyLarge.copy(color = PlezyColors.Text),
        keyboardOptions = keyboardOptions,
        lineLimits = TextFieldLineLimits.SingleLine,
        cursorBrush = SolidColor(PlezyColors.Text),
    )
}
