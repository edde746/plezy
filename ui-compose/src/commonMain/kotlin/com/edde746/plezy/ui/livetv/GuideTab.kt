package com.edde746.plezy.ui.livetv


import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.ScrollableState
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.gestures.scrollable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.livetv.guide.GuideCellTone
import com.edde746.plezy.presentation.livetv.guide.GuideColumn
import com.edde746.plezy.presentation.livetv.guide.GuideHorizontalScroll
import com.edde746.plezy.presentation.livetv.guide.GuideLayout
import com.edde746.plezy.presentation.livetv.guide.GuideMenu
import com.edde746.plezy.presentation.livetv.guide.GuideProgramCell
import com.edde746.plezy.presentation.livetv.guide.GuideRow
import com.edde746.plezy.presentation.livetv.guide.GuideStore
import com.edde746.plezy.presentation.livetv.guide.GuideTiming
import com.edde746.plezy.presentation.livetv.guide.GuideTimeNavItem
import com.edde746.plezy.presentation.livetv.guide.GuideUiState
import com.edde746.plezy.presentation.livetv.guide.GuideZone
import com.edde746.plezy.presentation.livetv.guide.guideBlockTextInset
import com.edde746.plezy.presentation.livetv.guide.guideBlockVisible
import com.edde746.plezy.presentation.livetv.guide.guideProgramScrollOffset
import com.edde746.plezy.presentation.livetv.guide.guideRowScrollOffset
import com.edde746.plezy.presentation.livetv.guide.guideScrollToNowOffset
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.LocalBackPress
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.isContextMenuKey
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.overlayOpener
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.LogoRecolour
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.player.toInputKey
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import kotlin.math.roundToInt

/**
 * How the guide is laid out, by the window: for a remote ([TV], the focused airing's details over the channels); for
 * touch or a pointer on tablets and the desktop ([WIDE]); for a phone's narrow window ([PHONE]: the channel column its
 * logos alone). [channelWidth] is the channel column's width. The time axis is [GuideLayout]'s on every form, a dp a
 * point: half an hour holds a title of a few words on a phone too.
 */
private enum class GuideForm(val channelWidth: Dp) {
    TV(176.dp),
    WIDE(176.dp),
    PHONE(64.dp),
}

/**
 * The Guide tab: the time choices (◀, the day chip with the window's start time, ▶), on TV the focused airing's details,
 * then the time ruler over the channels, each a row of its airings laid out on the window's time, the one on air a step
 * lighter, a line at now. The guide is one focus target: its D-pad focus lives in [GuideStore], which takes the keys
 * (Select held, the context-menu key and Back included) and says what is drawn focused (the focus fill); taps, long
 * presses and secondary clicks go to its pointer methods. The airings scroll sideways under the ruler (a drag, Shift with
 * the wheel, a trackpad's sideways swipe), the rows up and down beside their channels. Only the airings near the view
 * are composed ([guideBlockVisible]), and the D-pad's target. Harness names `guide`, `guide.earlier`, `guide.day`,
 * `guide.later`, `guide.dayMenu.<i>`, `guide.slotMenu.<i>`, `guide.details`, `guide.grid`, `guide.row.<i>`,
 * `guide.channel.<i>`.
 *
 * @param logo a channel's logo; null without one (its name shows).
 * @param thumb an airing's picture for the details; null without one (its channel's logo shows).
 */
@Composable
internal fun GuideTab(
    guide: GuideStore,
    logo: (LiveTvChannel) -> Artwork?,
    thumb: (LiveTvProgram) -> Artwork?,
    modifier: Modifier = Modifier,
    focusRequester: FocusRequester = remember { FocusRequester() },
) {
    val state by guide.state.collectAsState()
    // The store asks for the platform's focus (a search jump, a closed menu, the first load): taken in keyboard or D-pad
    // mode only. Remembered while the spinner shows, so a request the first load answers still reaches the grid.
    var handledRequest by rememberSaveable { mutableIntStateOf(state.focusRequest) }
    if (state.showsFullSpinner) {
        LoadingState(modifier)
        return
    }
    val layout = LocalWindowLayout.current
    val form = when {
        layout.formFactor == FormFactor.TV -> GuideForm.TV
        layout.widthClass == WidthClass.COMPACT -> GuideForm.PHONE
        else -> GuideForm.WIDE
    }
    val inputMode = LocalInputModeManager.current
    val backPress = LocalBackPress.current
    val downKeys = remember { HashMap<Key, InputKey>() }
    val back: () -> Unit = {
        guide.onKeyDown(InputKey.BACK)
        guide.onKeyUp(InputKey.BACK)
    }
    LaunchedEffect(state.focusRequest) {
        if (state.focusRequest == handledRequest) return@LaunchedEffect
        handledRequest = state.focusRequest
        if (inputMode.inputMode != InputMode.Touch) focusRequester.requestFocus()
    }
    // Android 13's predictive back reaches the newest back handler before the key's release.
    SystemBackHandler(enabled = state.hasFocus && state.menu == null) { back() }

    fun onKey(event: KeyEvent): Boolean {
        val key = when (event.type) {
            KeyEventType.KeyDown -> event.guideKey()
            KeyEventType.KeyUp -> downKeys.remove(event.key) ?: event.guideKey()
            else -> null
        } ?: return false
        if (key == InputKey.BACK || key == InputKey.ESCAPE) return backPress.handle(event, back)
        return when (event.type) {
            KeyEventType.KeyDown -> guide.onKeyDown(key, repeat = downKeys.put(event.key, key) != null)
            else -> guide.onKeyUp(key)
        }
    }

    val scroll = remember { GuideScrollState() }
    val list = rememberLazyListState()
    Box(
        modifier
            .fillMaxSize()
            .layoutProbe("guide")
            .focusRequester(focusRequester)
            .onFocusChanged {
                // A key held as focus left (Select held to open a channel's menu) is let go elsewhere: its next press
                // here is a new one, not a repeat.
                if (!it.isFocused) downKeys.clear()
                guide.setFocused(it.isFocused)
            }
            .onKeyEvent(::onKey)
            .overlayOpener()
            .focusable(),
    ) {
        Column(Modifier.fillMaxSize()) {
            TimeChoices(state, guide)
            if (form == GuideForm.TV) Details(state, scroll, logo, thumb)
            GuideGrid(state, guide, form, scroll, list, logo, Modifier.weight(1f))
        }
        if (state.showsReloadOverlay) {
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = GuideLayout.RELOAD_SCRIM_ALPHA.toFloat())), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(Modifier.size(GuideLayout.RELOAD_SPINNER_SIZE.dp), strokeWidth = 3.dp)
            }
        }
    }
}

/** The key the guide takes [this] as: the context-menu key and Shift+F10 are its Menu. */
private fun KeyEvent.guideKey(): InputKey? =
    if (isContextMenuKey || (key == Key.F10 && isShiftPressed)) InputKey.MENU else toInputKey()

/**
 * The airings' sideways scroll in [GuideLayout] points, 0…[max] over a [viewport] as many points wide; [pxPerPoint] px
 * a point (a dp). The ruler, the airings and the now line read it while laying out and drawing.
 */
@Stable
private class GuideScrollState {
    var offset by mutableFloatStateOf(0f)
    var max by mutableFloatStateOf(0f)
    var viewport by mutableFloatStateOf(0f)
    var pxPerPoint = 1f

    val scrollable = ScrollableState { delta ->
        val before = offset
        offset = (offset + delta / pxPerPoint).coerceIn(0f, max)
        (offset - before) * pxPerPoint
    }
}

/**
 * The choices row for the store's time navigation: ◀ (two hours back), the day chip (the day picker) with the
 * window's start time beside it, ▶ (two hours on). They never take the platform's focus (the guide holds it): the
 * store's D-pad focus fills them.
 */
@Composable
private fun TimeChoices(state: GuideUiState, guide: GuideStore) {
    val dimens = LocalPlezyDimens.current
    val unfocusable = Modifier.focusProperties { canFocus = false }
    Row(
        Modifier.fillMaxWidth().padding(start = dimens.screenPadding, end = dimens.screenPadding, bottom = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ShiftButton(state, guide, GuideTimeNavItem.EARLIER, PlezyIcons.ChevronLeft, "−", unfocusable.layoutProbe("guide.earlier", reportsFocus = false))
        Box {
            PlezyChip(
                state.dayLabel,
                selected = false,
                drawnFocused = state.isFocused(GuideTimeNavItem.DAY),
                onClick = { guide.selectTimeNav(GuideTimeNavItem.DAY) },
                modifier = unfocusable.layoutProbe("guide.day", reportsFocus = false),
                dropdown = true,
            )
            DayMenu(state.menu, guide)
        }
        ShiftButton(state, guide, GuideTimeNavItem.LATER, PlezyIcons.ChevronRight, "+", unfocusable.layoutProbe("guide.later", reportsFocus = false))
        state.timeLabel?.let { Text(it, style = MaterialTheme.typography.labelLarge, color = PlezyColors.TextMuted, maxLines = 1) }
    }
}

/** ◀ or ▶ as a round button of a chip's height, filled while the store's focus is on it. */
@Composable
private fun ShiftButton(state: GuideUiState, guide: GuideStore, item: GuideTimeNavItem, icon: androidx.compose.ui.graphics.vector.ImageVector, sign: String, modifier: Modifier) {
    PlezyIconButton(
        icon,
        sign + T.liveTv.durationHours(n = GuideLayout.SHIFT_HOURS.toString()),
        { guide.selectTimeNav(item) },
        modifier,
        drawnFocused = state.isFocused(item),
        size = LocalPlezyDimens.current.chipHeight,
        focusInset = true,
    )
}

/**
 * The day picker: "Now" and the days, then the picked day's time slots under a back entry; the store turns its pages.
 * Harness names `guide.dayMenu.<i>`, `guide.dayMenu.back`, `guide.dayMenu.slot.<i>`.
 */
@Composable
private fun DayMenu(menu: GuideMenu?, guide: GuideStore) {
    val entries = when (menu) {
        // A day applies at once and opens its slots in the menu's place.
        is GuideMenu.Days -> menu.choices.map { choice ->
            ItemMenuEntry(choice.label, selected = choice.selected, keepsOpen = choice.epochDay != null) { guide.pickDay(choice) }
        }
        is GuideMenu.Slots -> listOf(ItemMenuEntry(menu.header, probe = "back", icon = PlezyIcons.ChevronLeft, keepsOpen = true, onClick = guide::backToDays)) +
            menu.slots.mapIndexed { index, slot -> ItemMenuEntry(slot.label, probe = "slot.$index") { guide.pickSlot(slot) } }
        null -> emptyList()
    }
    ItemMenu(menu != null, onDismiss = guide::dismissMenu, entries = entries, probe = "guide.dayMenu", title = (menu as? GuideMenu.Slots)?.header)
}

/**
 * The airing the store's D-pad focus is on; else, with focus on a channel or the time choices, the focused channel's
 * airing in view ([viewStart] to [viewEnd] across the grid): the one on air when it is in view, else the first. The
 * channel alone without one in view. It stays on the last one while focus is elsewhere on the screen.
 */
private fun GuideUiState.shown(viewStart: Float, viewEnd: Float): Pair<GuideRow.Channel, GuideProgramCell?>? {
    val row = rows.firstOrNull { it is GuideRow.Channel && it.channelIndex == focus.channelIndex } as? GuideRow.Channel ?: return null
    if (focus.zone == GuideZone.GRID && focus.column == GuideColumn.PROGRAM) return row to row.programs.firstOrNull { it.program == focus.program }
    // Before the grid's first layout every airing counts as in view.
    val inView = if (viewEnd > viewStart) row.programs.filter { it.left + it.width > viewStart && it.left < viewEnd } else row.programs
    return row to (inView.firstOrNull { it.timing == GuideTiming.AIRING } ?: inView.firstOrNull())
}

/**
 * The shown airing's details beside its picture (TV): its time and channel, the title with its recording dot and NEW
 * pill, the episode line, [SYNOPSIS_LINES] of summary. As tall as those lines at the app's text size, whichever airing
 * they show; [scroll] says which airings are in view.
 */
@Composable
private fun Details(state: GuideUiState, scroll: GuideScrollState, logo: (LiveTvChannel) -> Artwork?, thumb: (LiveTvProgram) -> Artwork?) {
    val type = MaterialTheme.typography
    val height = with(LocalDensity.current) {
        type.labelLarge.lineHeight.toDp() + type.titleLarge.lineHeight.toDp() + type.bodyMedium.lineHeight.toDp() * (1 + SYNOPSIS_LINES) + DETAILS_LINE_GAP * 3
    }
    // Read while scrolling: only a change of airing recomposes the details.
    val shown by remember(state) { derivedStateOf { state.shown(scroll.offset, scroll.offset + scroll.viewport) } }
    Row(
        Modifier.fillMaxWidth().height(height).padding(horizontal = LocalPlezyDimens.current.screenPadding).layoutProbe("guide.details", reportsFocus = false),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        val (row, cell) = shown ?: return@Row
        val picture = cell?.program?.let(thumb)
        RemoteImage(
            picture ?: logo(row.channel),
            contentDescription = null,
            modifier = Modifier.fillMaxHeight().aspectRatio(16f / 9f).clip(MaterialTheme.shapes.medium),
            contentScale = if (picture != null) ContentScale.Crop else ContentScale.Fit,
            blank = PlezyColors.SurfaceHigh,
            error = { ArtworkPlaceholder(PlaceholderKind.CHANNEL) },
        )
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(DETAILS_LINE_GAP)) {
            val muted = PlezyColors.TextMuted
            val headline = listOfNotNull(cell?.timeText, row.channel.displayName).joinToString(" · ")
            Text(headline, style = type.labelLarge, color = muted, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (cell?.isRecordingScheduled == true) RecordingDot()
                Text(cell?.title ?: row.channel.displayName, Modifier.weight(1f, fill = false), style = type.titleLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
                if (cell?.isPremiere == true) StatusPill(T.liveTv.premiereBadge, MaterialTheme.colorScheme.primary)
            }
            if (cell == null) {
                Text(T.liveTv.noPrograms, style = type.bodyMedium, color = muted)
                return@Column
            }
            cell.subtitle?.let { Text(it, style = type.bodyMedium, color = muted, maxLines = 1, overflow = TextOverflow.Ellipsis) }
            cell.program.summary?.let { Text(it, style = type.bodyMedium, maxLines = SYNOPSIS_LINES, overflow = TextOverflow.Ellipsis) }
        }
    }
}

@Composable
private fun GuideGrid(state: GuideUiState, guide: GuideStore, form: GuideForm, scroll: GuideScrollState, list: LazyListState, logo: (LiveTvChannel) -> Artwork?, modifier: Modifier) {
    val dimens = LocalPlezyDimens.current
    val density = LocalDensity.current
    scroll.pxPerPoint = with(density) { 1.dp.toPx() }
    BoxWithConstraints(
        modifier
            .fillMaxWidth()
            .padding(horizontal = dimens.screenPadding)
            .clipToBounds()
            .scrollable(scroll.scrollable, Orientation.Horizontal, reverseDirection = true)
            .layoutProbe("guide.grid", reportsFocus = false),
    ) {
        val viewport = (maxWidth - form.channelWidth).value.coerceAtLeast(0f)
        scroll.viewport = viewport
        scroll.max = (GuideLayout.GRID_WIDTH.toFloat() - viewport).coerceAtLeast(0f)
        if (scroll.offset > scroll.max) scroll.offset = scroll.max
        PerformScroll(state, scroll, list)
        // The store names what is in view (the day pill and the time beside it); after the scroll asked for, so the
        // window's opening scroll is what it hears first.
        LaunchedEffect(guide) {
            snapshotFlow { scroll.offset to scroll.viewport }.collect { (start, width) -> if (width > 0f) guide.setView(start.toDouble(), width.toDouble()) }
        }
        Column(Modifier.fillMaxSize()) {
            Ruler(state, form, scroll)
            LazyColumn(Modifier.fillMaxSize(), state = list, contentPadding = PaddingValues(bottom = dimens.sectionSpacing)) {
                itemsIndexed(state.rows, key = { index, row -> rowKey(index, row) }) { _, row ->
                    when (row) {
                        is GuideRow.SourceHeader -> SourceHeaderRow(row.label)
                        is GuideRow.Channel -> ChannelRow(state, row, guide, form, scroll, logo)
                    }
                }
            }
        }
    }
}

private fun rowKey(index: Int, row: GuideRow): String = when (row) {
    is GuideRow.SourceHeader -> "header:$index"
    is GuideRow.Channel -> "channel:${row.channelIndex}"
}

/** Performs each scroll the store asks for once: the row into view (animated), the window sideways (at once). */
@Composable
private fun PerformScroll(state: GuideUiState, scroll: GuideScrollState, list: LazyListState) {
    val request = state.scroll ?: return
    val density = LocalDensity.current
    val ready = scroll.viewport > 0f
    LaunchedEffect(request.id, ready) {
        if (!ready) return@LaunchedEffect
        when (val horizontal = request.horizontal) {
            is GuideHorizontalScroll.ToNow -> scroll.offset = guideScrollToNowOffset(horizontal.nowOffset, scroll.viewport.toDouble(), scroll.max.toDouble()).toFloat()
            is GuideHorizontalScroll.ToProgram ->
                guideProgramScrollOffset(horizontal.left, scroll.offset.toDouble(), scroll.viewport.toDouble(), scroll.max.toDouble())?.let { scroll.offset = it.toFloat() }
            null -> Unit
        }
        val rowTop = request.rowTop ?: return@LaunchedEffect
        val rows = state.rows
        val info = list.layoutInfo
        val viewportHeight = with(density) { info.viewportSize.height.toDp().value.toDouble() }
        val top = rows.take(list.firstVisibleItemIndex).sumOf { it.height } + with(density) { list.firstVisibleItemScrollOffset.toDp().value.toDouble() }
        val target = guideRowScrollOffset(rowTop, top, viewportHeight, state.contentHeight - viewportHeight) ?: return@LaunchedEffect
        val by = with(density) { (target - top).toFloat().dp.toPx() }
        list.animateScrollBy(by, tween(GuideLayout.VERTICAL_SCROLL_MILLIS, easing = EaseOut))
    }
}

/**
 * The half hours' times over the airings, moving with them. A time whose mark has scrolled past the start stays whole at
 * the start until the next time comes too close, then gives the start up to it: no time is ever drawn cut.
 */
@Composable
private fun Ruler(state: GuideUiState, form: GuideForm, scroll: GuideScrollState) {
    Row(Modifier.fillMaxWidth().height(RULER_HEIGHT)) {
        Spacer(Modifier.width(form.channelWidth))
        Layout(
            content = {
                state.timeMarks.forEach { mark ->
                    Text(mark.label, style = MaterialTheme.typography.labelMedium, color = PlezyColors.TextMuted, maxLines = 1)
                }
            },
            modifier = Modifier.weight(1f).fillMaxHeight().clipToBounds(),
        ) { measurables, constraints ->
            val placeables = measurables.map { it.measure(Constraints()) }
            val gap = RULER_GAP.roundToPx()
            layout(constraints.maxWidth, constraints.maxHeight) {
                val start = scroll.offset
                val marks = state.timeMarks
                fun at(i: Int) = ((marks[i].left - start) * scroll.pxPerPoint).toFloat()
                placeables.forEachIndexed { i, placeable ->
                    val x = rulerLabelX(at(i), if (i < marks.lastIndex) at(i + 1) else Float.MAX_VALUE, placeable.width, gap) ?: return@forEachIndexed
                    if (x < constraints.maxWidth) placeable.place(x.roundToInt(), (constraints.maxHeight - placeable.height) / 2)
                }
            }
        }
    }
}

/**
 * Where a ruler time [width] px wide is drawn, its mark at [mark] px from the ruler's start and the next time's at [next]:
 * at its mark, or, once the mark has scrolled past the start, whole at the start while the next time is more than [gap]
 * away from it; null after, when it would be cut.
 */
internal fun rulerLabelX(mark: Float, next: Float, width: Int, gap: Int): Float? = when {
    mark >= 0f -> mark
    next - width - gap >= 0f -> 0f
    else -> null
}

/** A source's header: its server and lineup across the row. */
@Composable
private fun SourceHeaderRow(label: String) {
    Box(Modifier.fillMaxWidth().height(GuideLayout.SOURCE_HEADER_ROW_HEIGHT.dp), contentAlignment = Alignment.CenterStart) {
        Text(label, style = MaterialTheme.typography.titleSmall, color = PlezyColors.TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

/**
 * A channel: its cell (logo and name, on a phone its logo alone, its name while the logo is missing; a star for a
 * favourite), then its airings near the view placed on the time shown, or one cell saying there are none. A tap on the
 * channel tunes it, a long press (a secondary click) opens its menu ([ChannelCell]).
 */
@Composable
private fun ChannelRow(state: GuideUiState, row: GuideRow.Channel, guide: GuideStore, form: GuideForm, scroll: GuideScrollState, logo: (LiveTvChannel) -> Artwork?) {
    val index = row.channelIndex
    Row(
        Modifier.fillMaxWidth().height(GuideLayout.ROW_HEIGHT.dp).padding(vertical = CELL_GAP / 2).layoutProbe("guide.row.$index", reportsFocus = false),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ChannelCell(row, state.isFocused(row), state.channelMenu == index, logo(row.channel), form, guide)
        if (row.programs.isEmpty()) {
            Box(
                Modifier.weight(1f).fillMaxHeight().clip(MaterialTheme.shapes.small).background(PlezyColors.SurfaceHigh).padding(horizontal = 10.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                Text(T.liveTv.noPrograms, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            return@Row
        }
        // Only the airings near the view (a slot of overscan each side), plus the D-pad's target; a scroll composes the
        // row again only as an airing comes in or leaves.
        val visible by remember(row, state.focus, state.hasFocus) {
            derivedStateOf {
                row.programs.filter { cell ->
                    state.isFocused(row, cell) ||
                        guideBlockVisible(cell.left, cell.width, scroll.offset.toDouble(), scroll.viewport.toDouble())
                }
            }
        }
        val shown = visible
        val nowOffset = state.nowOffset
        val primary = MaterialTheme.colorScheme.primary
        Layout(
            content = {
                for (cell in shown) {
                    key(cell.program) { ProgramCell(row, cell, state.tone(row, cell), guide, scroll, nowOffset) }
                }
            },
            modifier = Modifier.weight(1f).fillMaxHeight().clipToBounds().drawBehind {
                // A line at now behind the airings: it shows between them; the one on air draws its own part.
                val now = nowOffset ?: return@drawBehind
                val x = ((now - scroll.offset) * scroll.pxPerPoint).toFloat()
                if (x in 0f..size.width) drawLine(primary, Offset(x, 0f), Offset(x, size.height), strokeWidth = NOW_LINE.toPx())
            },
        ) { measurables, constraints ->
            val gap = CELL_GAP.roundToPx()
            val placeables = measurables.mapIndexed { n, measurable ->
                val width = (shown[n].width * scroll.pxPerPoint).roundToInt() - gap
                measurable.measure(Constraints.fixed(width.coerceAtLeast(gap), constraints.maxHeight))
            }
            layout(constraints.maxWidth, constraints.maxHeight) {
                val start = scroll.offset
                placeables.forEachIndexed { n, placeable -> placeable.place(((shown[n].left - start) * scroll.pxPerPoint).roundToInt(), 0) }
            }
        }
    }
}

/**
 * A channel's cell: a click tunes to it; a long press, a right click, the Menu key and (TV) holding Select open its
 * menu ([GuideUiState.channelMenu]): Watch Channel, Favorite (checked while it is one) and, while something airs on
 * it, View details, where it can be recorded (harness names `guide.channelMenu.<0|1|2>`). On TV the menu is a side
 * panel titled with the channel.
 */
@Composable
private fun ChannelCell(row: GuideRow.Channel, focused: Boolean, menuOpen: Boolean, logo: Artwork?, form: GuideForm, guide: GuideStore) {
    val index = row.channelIndex
    val channel = row.channel
    Box(Modifier.width(form.channelWidth).fillMaxHeight().padding(end = if (form == GuideForm.PHONE) 6.dp else 10.dp)) {
        PlezySurface(
            onClick = { guide.tapChannel(index) },
            modifier = Modifier
                .fillMaxSize()
                .focusProperties { canFocus = false }
                .menuGestures { guide.openChannelMenu(index) }
                .semantics { contentDescription = channel.displayName }
                .layoutProbe("guide.channel.$index", reportsFocus = false),
            shape = MaterialTheme.shapes.small,
            color = Color.Transparent,
            selected = focused,
            drawnFocused = focused,
            onLongClick = { guide.openChannelMenu(index) },
            contentAlignment = Alignment.CenterStart,
            grows = false,
        ) {
            if (form == GuideForm.PHONE) {
                RemoteImage(logo, contentDescription = null, modifier = Modifier.fillMaxSize().padding(4.dp), contentScale = ContentScale.Fit, logo = LogoRecolour.CELL) {
                    Text(
                        channel.displayName, Modifier.fillMaxSize().wrapContentHeight(), style = MaterialTheme.typography.labelSmall,
                        textAlign = TextAlign.Center, maxLines = 3, overflow = TextOverflow.Ellipsis,
                    )
                }
            } else {
                Row(Modifier.padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ChannelLogo(logo, Modifier.size(LOGO_SIZE.dp))
                    Column(Modifier.weight(1f)) {
                        channel.number?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = PlezyColors.MutedContent, maxLines = 1) }
                        Text(channel.displayName, style = MaterialTheme.typography.titleSmall, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
            if (row.isFavorite) {
                Icon(
                    PlezyIcons.Star,
                    contentDescription = null,
                    Modifier.align(Alignment.TopEnd).padding(4.dp).size(12.dp),
                    tint = if (focused) LocalContentColor.current else MaterialTheme.colorScheme.primary,
                )
            }
        }
        val airing = row.airing
        ItemMenu(
            menuOpen,
            onDismiss = guide::dismissChannelMenu,
            entries = listOfNotNull(
                ItemMenuEntry(T.liveTv.watchChannel, icon = PlezyIcons.PlayArrow) { guide.tapChannel(index) },
                ItemMenuEntry(T.liveTv.favorite, selected = row.isFavorite, icon = PlezyIcons.StarBorder) { guide.toggleFavorite(index) },
                airing?.let { ItemMenuEntry(T.mediaMenu.viewDetails, icon = PlezyIcons.Info) { guide.longPressProgram(index, it) } },
            ),
            probe = "guide.channelMenu",
            title = channel.displayName,
            contentTitle = true,
        )
    }
}

/**
 * An airing, drawn by its [tone]: a plain fill, the one on air a step lighter, a past one's title as muted as its times;
 * focused, the focus fill whatever its time. Its text starts where the view does when the airing began before it, so
 * its title stays in view; an airing with too little room left for its text shows none, not a cut word
 * ([guideBlockTextInset]). Its times are "{start} · {length}", or the start alone where the room can't hold them whole.
 * The airing on air marks how far it has run with a bar near its foot, in its text's colour, inside its fill (so on a
 * focused airing's light fill it reads against the fill, not as a notch into the dark under it), over the line at now,
 * which never crosses its text. A red dot marks a scheduled recording, a
 * NEW pill a premiere. A tap tunes an airing on now on TV and opens the details elsewhere; a long press (a secondary
 * click) opens the details. Harness name `guide.onNow.<channel index>` on the airing on now.
 */
@Composable
private fun ProgramCell(row: GuideRow.Channel, cell: GuideProgramCell, tone: GuideCellTone, guide: GuideStore, scroll: GuideScrollState, nowOffset: Double?) {
    val index = row.channelIndex
    val program = cell.program
    val label = listOfNotNull(cell.title, cell.subtitle, cell.timeText).joinToString(", ")
    val focused = tone == GuideCellTone.FOCUSED
    PlezySurface(
        onClick = { guide.tapProgram(index, program) },
        modifier = Modifier
            .focusProperties { canFocus = false }
            .menuGestures { guide.longPressProgram(index, program) }
            .semantics { contentDescription = label }
            .then(if (cell.timing == GuideTiming.AIRING) Modifier.layoutProbe("guide.onNow.$index", reportsFocus = false) else Modifier),
        shape = MaterialTheme.shapes.small,
        color = if (tone == GuideCellTone.AIRING) PlezyColors.SurfaceHighest else PlezyColors.SurfaceHigh,
        selected = focused,
        drawnFocused = focused,
        onLongClick = { guide.longPressProgram(index, program) },
        grows = false,
    ) {
        val content = LocalContentColor.current
        val muted = PlezyColors.MutedContent
        Column(
            Modifier
                .fillMaxHeight()
                .drawBehind {
                    if (cell.timing != GuideTiming.AIRING) return@drawBehind
                    val run = (((nowOffset ?: return@drawBehind) - cell.left) * scroll.pxPerPoint).toFloat().coerceIn(0f, size.width)
                    val bar = NOW_LINE.toPx()
                    drawRect(content, Offset(0f, size.height - 2 * bar), Size(run, bar))
                }
                .layout { measurable, constraints ->
                    val inset = guideBlockTextInset(cell.left, cell.width, scroll.offset.toDouble(), CELL_GAP.value.toDouble())
                        ?: return@layout layout(constraints.maxWidth, constraints.minHeight) {}
                    val start = (inset * scroll.pxPerPoint).roundToInt()
                    val room = constraints.maxWidth - start - (GuideLayout.TEXT_PADDING * scroll.pxPerPoint).roundToInt()
                    val placeable = measurable.measure(constraints.copy(minWidth = 0, maxWidth = room.coerceAtLeast(0)))
                    layout(constraints.maxWidth, placeable.height) { placeable.place(start, 0) }
                },
            verticalArrangement = Arrangement.Center,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                if (cell.isRecordingScheduled) RecordingDot()
                if (cell.isPremiere) StatusPill(T.liveTv.premiereBadge, content, dense = true)
                Text(
                    cell.title,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (tone == GuideCellTone.PAST) muted else content,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            cell.subtitle?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = muted, maxLines = 1, overflow = TextOverflow.Ellipsis) }
            val times = cell.timeText
            val start = cell.startText
            if (times != null && start != null) Times(times, start, muted)
        }
    }
}

/** An airing's [times] on one line, or its [start] alone where the room can't hold [times] whole. */
@Composable
private fun Times(times: String, start: String, color: Color) {
    val style = MaterialTheme.typography.labelSmall
    Layout(
        content = {
            Text(times, style = style, color = color, maxLines = 1, softWrap = false)
            Text(start, style = style, color = color, maxLines = 1, overflow = TextOverflow.Ellipsis)
        },
    ) { measurables, constraints ->
        val whole = measurables[0].measure(constraints.copy(minWidth = 0, maxWidth = Constraints.Infinity))
        val shown = if (whole.width <= constraints.maxWidth) whole else measurables[1].measure(constraints.copy(minWidth = 0))
        layout(shown.width, shown.height) { shown.place(0, 0) }
    }
}

/** A scheduled recording's red dot, named for screen readers. */
@Composable
private fun RecordingDot() {
    val name = T.liveTv.recordingScheduled
    Box(Modifier.size(8.dp).background(PlezyColors.Live, CircleShape).semantics { contentDescription = name })
}

/** A tinted status pill (NEW, LIVE, Recording now): [color] text on its 15 % tint; [dense] fits a line of body text. */
@Composable
internal fun StatusPill(label: String, color: Color, modifier: Modifier = Modifier, dense: Boolean = false) {
    Text(
        label,
        modifier
            .background(color.copy(alpha = 0.15f), CircleShape)
            .padding(horizontal = if (dense) 5.dp else 8.dp, vertical = if (dense) 1.dp else 4.dp),
        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
        color = color,
        maxLines = 1,
    )
}

private const val SYNOPSIS_LINES = 2
private val DETAILS_LINE_GAP: Dp = 2.dp
private val RULER_HEIGHT: Dp = 28.dp
private val RULER_GAP: Dp = 8.dp
private val CELL_GAP: Dp = 4.dp
private val NOW_LINE: Dp = 2.dp
