package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.SubcomposeLayout
import androidx.compose.foundation.focusGroup
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.focusProperties
import com.edde746.plezy.ui.navigation.LocalSideNavigation
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.layout.LayoutClass
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.scrollEdge
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow

/**
 * A pushed screen's (or pane's) heading: a round back button when there is somewhere to go back to ([onBack]) and the
 * screen isn't the first page of a pane beside its list ([LocalPaneRoot]), the [title] (on at most [titleLines] lines,
 * then cut short) and an optional [subtitle] line, both from the screen's store, and the screen's [actions] at the end
 * (round icon buttons, as tall as the back button: an addon's "+"). Top-level screens have none: their top is a
 * [HeaderScaffold]'s row. [contentTitle]: whether [title] is content text (an addon's or a person's), which takes its
 * direction from its first letter ([contentDirection]). [scrolled]: whether the content under the heading has left its
 * top; while it has, the page's background lies behind the heading and fades out past its foot ([scrollEdge]), so what
 * scrolls up under it fades away instead of being cut at an invisible line.
 */
@Composable
fun ScreenHeader(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    onBack: (() -> Unit)? = null,
    contentTitle: Boolean = false,
    titleLines: Int = 1,
    scrolled: () -> Boolean = { false },
    actions: (@Composable RowScope.() -> Unit)? = null,
) {
    val dimens = LocalPlezyDimens.current
    Row(
        // Drawn after the content below it, so the scroll edge lies over its top; outside [modifier], so it covers the
        // room a caller's padding leaves (the status bar's) too.
        Modifier
            .zIndex(1f)
            .scrollEdge(scrolled)
            .then(modifier)
            .fillMaxWidth()
            .padding(start = dimens.screenPadding, end = dimens.screenPadding, top = 12.dp, bottom = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (onBack != null && !LocalPaneRoot.current) {
            PlezyIconButton(PlezyIcons.ArrowBack, T.nav.back, onBack, Modifier.layoutProbe("header.back"))
        }
        Column(Modifier.weight(1f)) {
            val titleStyle = MaterialTheme.typography.titleLarge
            Text(
                title,
                style = if (contentTitle) titleStyle.contentDirection() else titleStyle,
                maxLines = titleLines,
                overflow = TextOverflow.Ellipsis,
            )
            if (subtitle != null) {
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        actions?.invoke(this)
    }
}

/**
 * Whether the screen is the first page of a pane beside its list (a Settings section on a wide window): the list beside
 * it is the way to another page, so it shows no back button.
 */
val LocalPaneRoot = compositionLocalOf { false }

/**
 * A top-level screen's header row over its [content]: Home, Libraries, Explore, Live TV, Downloads and Search each build
 * their top with it, and no screen draws a top bar of its own. The row is the top of the screen, under the status bar
 * on a phone ([statusBarOverlap]), and stays there while the content under it scrolls.
 *
 * [filters] lead the row. With [fitted] they show where they all fit side by side (as chips), else [fitted] does
 * (dropdown chips fitted to the row, [FittingRow]), and on phones always ([compactFilterRow]); [filters] is then composed
 * once more to be measured only ([measuring]: never placed, with nothing for screen readers or the harness, so it takes
 * no place in a focus memory). Without [fitted], [filters] is the row as it lays itself out (a line of chips scrolling
 * sideways, Search's field). Both take the row's inset from the screen's edges as `padding`: as padding, or as a
 * scrolling line's content padding, so its chips scroll to the edge. [actions] (round icon buttons as tall as the
 * chips: [HeaderAction]) end the row, at the screen's edge. A top-level screen pushed over another (Live TV over Home)
 * leads the row with a back button running [onBack] (harness name `header.back`).
 *
 * The scroll edge, the same on every top-level screen: while the content has left its top (each of its lists says so
 * through [ScrimWhileScrolled]) the page's background fades in behind the row and on past its bottom, so what scrolls up
 * under the row fades out into the background ([scrollEdge]). Each time [LocalScrollToTop] asks, its lists scroll back
 * to their tops. [headerModifier] goes to the row.
 */
@Composable
fun HeaderScaffold(
    filters: @Composable (padding: PaddingValues, measuring: Boolean) -> Unit,
    modifier: Modifier = Modifier,
    headerModifier: Modifier = Modifier,
    fitted: (@Composable (padding: PaddingValues) -> Unit)? = null,
    actions: (@Composable RowScope.() -> Unit)? = null,
    onBack: (() -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    val dimens = LocalPlezyDimens.current
    val toTop = LocalScrollToTop.current
    val edge = remember(toTop) { ScrollEdge(toTop) }
    val end = if (actions == null) 0.dp else dimens.screenPadding
    val padding = PaddingValues(start = if (onBack == null) dimens.screenPadding else 0.dp, end = dimens.screenPadding - end)
    val compact = compactFilterRow()
    val side = LocalSideNavigation.current != null
    // Beside the rail or the TV column, Up and Down stay in the screen (the navigation is reached sideways): Down from
    // Search's field, with nothing under it yet, went to the column's item below it.
    val vertical = Modifier.focusProperties {
        onExit = { if (side && (requestedFocusDirection == FocusDirection.Up || requestedFocusDirection == FocusDirection.Down)) cancelFocusChange() }
    }
    Column(modifier.fillMaxSize().then(vertical).focusGroup()) {
        Row(
            headerModifier
                // Drawn after the content, so the scroll edge lies over its top.
                .zIndex(1f)
                .scrollEdge { edge.scrolled }
                .fillMaxWidth()
                .padding(top = statusBarOverlap + 8.dp, bottom = 8.dp, end = end),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(FILTER_GAP),
        ) {
            if (onBack != null) HeaderAction(PlezyIcons.ArrowBack, T.nav.back, onBack, "header.back", Modifier.padding(start = dimens.screenPadding))
            Box(Modifier.weight(1f)) {
                when {
                    fitted == null -> filters(padding, false)
                    compact -> fitted(padding)
                    else -> SubcomposeLayout { constraints ->
                        val wanted = subcompose("measure") {
                            CompositionLocalProvider(LocalLayoutProbe provides null) {
                                Box(Modifier.clearAndSetSemantics {}) { filters(padding, true) }
                            }
                        }.single().maxIntrinsicWidth(constraints.maxHeight)
                        val row = subcompose("row") { if (wanted <= constraints.maxWidth) filters(padding, false) else fitted(padding) }
                            .map { it.measure(constraints.copy(minWidth = 0, minHeight = 0)) }
                        layout(constraints.maxWidth, row.maxOfOrNull { it.height } ?: 0) { row.forEach { it.placeRelative(0, 0) } }
                    }
                }
            }
            actions?.invoke(this)
        }
        Box(Modifier.weight(1f).fillMaxWidth()) {
            CompositionLocalProvider(LocalScrollEdge provides edge) { content() }
        }
    }
}

/**
 * A header row's action: a round icon button as tall as the chips beside it, its icon theirs ([CHIP_ICON]), so the row's
 * round buttons and round chips are one size with one icon size. Harness name [probe].
 */
@Composable
fun HeaderAction(icon: ImageVector, label: String, onClick: () -> Unit, probe: String, modifier: Modifier = Modifier, selected: Boolean? = null) {
    PlezyIconButton(icon, label, onClick, modifier.layoutProbe(probe), selected = selected, size = LocalPlezyDimens.current.chipHeight, focusInset = true, iconSize = CHIP_ICON)
}

/**
 * Whether a header row's filters are always the fitted dropdown chips ([HeaderScaffold]): a phone's window, off TV,
 * where chips side by side would leave the row's actions no room.
 */
@Composable
fun compactFilterRow(): Boolean {
    val width = LocalWindowSize.current.value.width.value.toDouble()
    return !LocalAppearance.current.tv && LocalWindowLayout.current.formFactor == FormFactor.HANDHELD && LayoutClass.of(width, false) == LayoutClass.PHONE
}

/**
 * For a list under a [HeaderScaffold]'s row: the row's scroll edge shows while [scrolled] (the list has left its top)
 * or another list under it (a pager's neighbouring page) has; nothing elsewhere.
 */
@Composable
fun ScrimWhileScrolled(scrolled: () -> Boolean) {
    val edge = LocalScrollEdge.current ?: return
    val list = remember { Any() }
    val current by rememberUpdatedState(scrolled)
    LaunchedEffect(edge) { snapshotFlow { current() }.collect { edge.lists[list] = it } }
    DisposableEffect(edge) { onDispose { edge.lists.remove(list) } }
}

/**
 * A list's state under a [HeaderScaffold]'s row: its scrolling shows the row's scroll edge ([ScrimWhileScrolled]), and
 * it goes back to its top as asked ([LocalScrollToTop]).
 */
@Composable
fun rememberHeaderListState(): LazyListState = rememberLazyListState().also { list ->
    ScrimWhileScrolled { list.canScrollBackward }
    ScrollsToTop { list.animateScrollToItem(0) }
}

/**
 * A grid's state under a [HeaderScaffold]'s row: its scrolling shows the row's scroll edge ([ScrimWhileScrolled]), and
 * it goes back to its top as asked ([LocalScrollToTop]).
 */
@Composable
fun rememberHeaderGridState(): LazyGridState = rememberLazyGridState().also { grid ->
    ScrimWhileScrolled { grid.canScrollBackward }
    ScrollsToTop { grid.animateScrollToItem(0) }
}

/** For a list under a [HeaderScaffold]'s row: [toTop] runs each time the row's screen asks ([LocalScrollToTop]). */
@Composable
private fun ScrollsToTop(toTop: suspend () -> Unit) {
    val edge = LocalScrollEdge.current ?: return
    val current by rememberUpdatedState(toTop)
    LaunchedEffect(edge) { edge.toTop.collect { current() } }
}

/**
 * A top-level destination's asks to bring its screen back to its top (the destination reselected in the navigation),
 * which every list under its [HeaderScaffold]s follows; none by default.
 */
val LocalScrollToTop = staticCompositionLocalOf<Flow<Unit>> { emptyFlow() }

/** Whether any list under a header row has left its top ([ScrimWhileScrolled]), and when they go back to it. */
@Stable
private class ScrollEdge(val toTop: Flow<Unit>) {
    val lists = mutableStateMapOf<Any, Boolean>()
    val scrolled: Boolean get() = lists.values.any { it }
}

private val LocalScrollEdge = staticCompositionLocalOf<ScrollEdge?> { null }
