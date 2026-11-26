package com.edde746.plezy.ui.navigation

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ShortNavigationBar
import androidx.compose.material3.ShortNavigationBarDefaults
import androidx.compose.material3.ShortNavigationBarItem
import androidx.compose.material3.ShortNavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.layout.positionInWindow
import androidx.compose.ui.layout.onPlaced
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableFloatStateOf
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaKind
import androidx.compose.ui.input.key.type
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.constrainWidth
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.probeName
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.adaptive.NavigationKind
import com.edde746.plezy.ui.components.LocalOverlayOpeners
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.appArea
import com.edde746.plezy.ui.components.fadeStops
import com.edde746.plezy.ui.focus.focusEntry
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.libraries.libraryIcon
import com.edde746.plezy.ui.image.effectMillis
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/** The width of the rail on tablets, phones held sideways and desktop. */
private val RailWidth = 80.dp

/** The width of the TV column while it is collapsed (icons only); the screens begin right after it. */
private val TvCollapsedWidth = 72.dp

/** Between the collapsed TV column and the screen's content: room for a focused card's growth. */
private val TvContentGap = 16.dp

/** The width of the TV column while focus is in it (icons and labels, over the screen). */
private val TvExpandedWidth = 248.dp

/** The height of the [NavigationScaffold]'s footer (the profile's avatar in its round 4 dp frame). */
private val FooterHeight = 48.dp

/**
 * The rail's vertical measures: its margin above the destinations and below the footer, the room above each item's
 * pill and below its label, and the gap between items. [ROOMY] on tablets and desktop; [DENSE] where the roomy rail
 * doesn't fit the window's height (a phone in landscape).
 */
private enum class RailSpacing(val margin: Dp, val itemPadding: Dp, val itemGap: Dp) {
    ROOMY(16.dp, 6.dp, 4.dp),
    DENSE(8.dp, 2.dp, 0.dp),
}

/** A rail item's pill (behind its icon), and the gap from it to the label under it. */
private val RailPillHeight = 30.dp
private val RailLabelGap = 4.dp

/** The height a labelled rail item needs (Material 3's labelled destination), for whether a phone's labels fit. */
private val RailLabelledExtent = 72.dp

/** How far a scroll edge reaches below what it lies behind (a header row, a back button), easing out to clear. */
private val ScrimFade = 24.dp

/**
 * The app frame around the current screen: the top-level [destinations] as a bottom bar (`ShortNavigationBar`) in
 * compact windows, an 80 dp rail in wider ones (tablets either way up, phones held sideways, desktop), and on TV a 72 dp
 * column of icons that widens over the screen (which stays where it is, dimmed beside it) to show its labels while it
 * has focus. With [showNavigation] off (the player) the screen gets the whole window. Each item is a layout probe
 * `nav.<destination>` (`nav.home`) for the harness, and the screen's place beside them `nav.content`. Overlays never
 * give focus back to the navigation ([LocalOverlayOpeners]).
 *
 * The rail and the TV column are drawn over the window's start edge with no background of their own (the TV column has
 * one while open): the frame's background is under them, or a screen's backdrop, which runs under them to the window's
 * edge ([NavigationBackdrop]). Left from the screen's start enters the TV column on the destination it left from, else
 * the selected one; Back from the screen on TV goes to the column.
 *
 * On phones a top-level screen is drawn from the window's top edge, under the status bar ([statusBarOverlap] says how
 * far); its header row starts below it.
 *
 * @param selected the destination highlighted: the one the screen on top belongs to
 *   ([TopLevelDestination.Companion.highlightedIn]), which a pick of another goes through as any pick does.
 * @param libraryKind the kind of the library Libraries stands for: its item shows that kind's icon ([libraryIcon]).
 * @param barLabels a phone's bar and rail show their labels under the icons (Show Navigation Bar Labels); without them
 *   the bar is [BarHeightWithoutLabels] high. The rail also drops them where they don't fit ([Rail]).
 * @param footer drawn at the bottom of the rail and the TV column (the running profile's avatar), given whether the TV
 *   column shows its labels; the bar has none (phones switch profiles from Settings).
 * @param railExtra one more item after the first destination in the rail and the TV column (music's Now Playing).
 * @param atRoot the current destination shows its root: Back steps to the navigation only there; on a pushed screen
 *   it pops the screen first.
 * @param bottomAccessory docked at the content's foot, above the bottom bar or beside the rail (the music mini-player).
 */
@Composable
fun NavigationScaffold(
    destinations: List<TopLevelDestination>,
    selected: TopLevelDestination?,
    onSelect: (TopLevelDestination) -> Unit,
    showNavigation: Boolean,
    libraryKind: MediaKind? = null,
    modifier: Modifier = Modifier,
    barLabels: Boolean = true,
    railExtra: RailExtra? = null,
    bottomAccessory: @Composable () -> Unit = {},
    atRoot: Boolean = true,
    footer: (@Composable (expanded: Boolean) -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    // The content keeps one call site whatever the layout, so neither hiding the chrome (entering the player) nor a
    // change of layout (a phone turned to landscape, a window resized across a width class) recreates the screens.
    val show = showNavigation && destinations.isNotEmpty()
    val kind = LocalWindowLayout.current.navigation
    val screenPadding = LocalPlezyDimens.current.screenPadding
    val start = when {
        !show -> 0.dp
        kind == NavigationKind.RAIL -> RailWidth
        // The screens' own (overscan) padding starts under the column: their content begins a gap after it.
        kind == NavigationKind.TV_SIDE -> (TvCollapsedWidth + TvContentGap - screenPadding).coerceAtLeast(0.dp)
        else -> 0.dp
    }
    // How far the rail or the TV column (collapsed) reaches from the window's start edge.
    val sideWidth = when {
        !show -> 0.dp
        kind == NavigationKind.RAIL -> RailWidth
        kind == NavigationKind.TV_SIDE -> TvCollapsedWidth
        else -> 0.dp
    }
    val side = remember(start, sideWidth) { if (sideWidth > 0.dp) SideNavigation(start, sideWidth) else null }
    // A phone's top-level screen reaches up under the status bar (the window pads the app below the system bars, as
    // far whether they show or not: [appArea]).
    val density = LocalDensity.current
    val statusBar = if (show && kind == NavigationKind.BAR) with(density) { WindowInsets.appArea.getTop(this).toDp() } else 0.dp
    val overlap = remember(statusBar) { if (statusBar > 0.dp) StatusBarOverlap(statusBar) else null }
    val nav = remember { SideFocus() }
    val entry = nav.entry
    val tv = side != null && kind == NavigationKind.TV_SIDE
    // Back on the desktop's rail and the TV column (a screen's own Back, a stack's pop, comes first): from the screen it
    // focuses the navigation, on the item focused there last while it is still shown, else the selected one; from the
    // navigation, a destination other than the first shows the first and focuses its item; at the first, the app's Back
    // asks before exiting. Composed once and only switched: the newest back handler takes Back, and the screens' own
    // must stay newer than this one.
    val keyed = side != null && LocalWindowLayout.current.formFactor != FormFactor.HANDHELD
    val first = destinations.firstOrNull()
    SystemBackHandler(enabled = keyed && atRoot && (!nav.focused || (selected != first && first != null))) {
        if (!nav.focused) {
            nav.enter()
        } else if (first != null) {
            onSelect(first)
            nav.refocus++
            nav.held = true
        }
    }
    if (keyed) {
        LaunchedEffect(nav.refocus) {
            if (nav.refocus == 0) return@LaunchedEffect
            // A frame for the first destination's item to take the entry.
            withFrameNanos { }
            entry.requestFocus()
        }
        // The first destination's screen places its focus as its content arrives: until the next key or press, focus
        // stays on its item, where Back put it.
        LaunchedEffect(nav) {
            snapshotFlow { nav.held && !nav.focused }.collect { taken ->
                if (!taken) return@collect
                withFrameNanos { }
                if (nav.held && !nav.focused) entry.requestFocus()
            }
        }
    }
    Box(
        modifier
            .fillMaxSize()
            .onPreviewKeyEvent {
                if (it.type == KeyEventType.KeyDown) nav.held = false
                false
            }
            .pointerInput(nav) {
                awaitPointerEventScope {
                    while (true) {
                        if (awaitPointerEvent(PointerEventPass.Initial).type == PointerEventType.Press) nav.held = false
                    }
                }
            },
    ) {
        // Beside the screen's place, under the navigation: the background, where no backdrop runs.
        if (start > 0.dp) Box(Modifier.width(start).fillMaxHeight().background(PlezyColors.Background))
        Column(Modifier.fillMaxSize().padding(start = start)) {
            Box(Modifier.weight(1f).extendUp(statusBar).then(if (tv) Modifier.towardTvColumn(entry) else Modifier).screenGroup(nav).layoutProbe("nav.content", reportsFocus = false)) {
                CompositionLocalProvider(LocalStatusBarOverlap provides overlap, LocalSideNavigation provides side) { content() }
            }
            bottomAccessory()
            // The keyboard covers the bar, as it does the screen's foot: the screen keeps the room above the keyboard.
            if (show && kind == NavigationKind.BAR && LocalKeyboardHeight.current() == 0) BottomBar(destinations, selected, libraryKind, onSelect, barLabels, Modifier)
        }
        if (side != null) {
            // Focus that sat on the navigation as an overlay opened goes to the screen as it closes.
            CompositionLocalProvider(LocalOverlayOpeners provides false) {
                when (kind) {
                    NavigationKind.RAIL -> Rail(destinations, selected, libraryKind, onSelect, railExtra, footer, nav, barLabels)
                    NavigationKind.TV_SIDE -> TvSideNavigation(destinations, selected, libraryKind, onSelect, railExtra, footer, nav)
                    NavigationKind.BAR -> Unit
                }
            }
        }
    }
}

/** The rail's or TV column's focus: whether it has it, its items, the one focused last, and Back's hold on the first. */
@Stable
private class SideFocus {
    var focused by mutableStateOf(false)
    val entry = FocusRequester()

    /** The screen's place: [screenGroup], left to the navigation and returned to from it. */
    val screen = FocusRequester()
    var refocus by mutableIntStateOf(0)

    /** Back showed the first destination with focus on its item: the screen's own first focus doesn't take it. */
    var held by mutableStateOf(false)

    /** Each destination's item, and the one focused last (a remote walks the column without selecting). */
    private val items = HashMap<TopLevelDestination, FocusRequester>()
    var last: TopLevelDestination? = null

    fun item(destination: TopLevelDestination): FocusRequester = items.getOrPut(destination) { FocusRequester() }

    /** Focus into the navigation: the item focused there last while it is still shown, else [entry] (the selected one). */
    fun enter(): Boolean = last?.let { items[it]?.requestFocus() } == true || entry.requestFocus()

    /** [destination]'s item: its requester, the last focused as it takes focus, and [entry] when it is [entered]. */
    fun itemModifier(destination: TopLevelDestination, entered: TopLevelDestination): Modifier = Modifier
        .focusRequester(item(destination))
        .onFocusChanged { if (it.hasFocus) last = destination }
        .then(if (destination == entered) Modifier.focusRequester(entry) else Modifier)
}

/**
 * An item the rail and the TV column show second, after the first destination (music's Now Playing): its [label],
 * harness name [probe], its [icon] drawn in the tint it is given, and what a pick does.
 */
class RailExtra(val label: String, val probe: String, val icon: @Composable (tint: Color) -> Unit, val onClick: () -> Unit, val subtitle: String? = null)

/** How far the top of a phone's top-level screen lies under the status bar. */
class StatusBarOverlap internal constructor(val height: Dp)

/** The current screen's [StatusBarOverlap]; null where the screen starts below the status bar. */
val LocalStatusBarOverlap = staticCompositionLocalOf<StatusBarOverlap?> { null }

/** How far the top of the current screen lies under the status bar: start its content this much lower. */
val statusBarOverlap: Dp
    @Composable get() = LocalStatusBarOverlap.current?.height ?: 0.dp

/**
 * The rail or the TV column beside the current screen: the screen's place starts [inset] from the window's start edge,
 * and the navigation covers [width] from that edge.
 */
class SideNavigation internal constructor(val inset: Dp, val width: Dp)

/** The rail or the TV column beside the current screen; null without one (phones' bar, the player). */
val LocalSideNavigation = staticCompositionLocalOf<SideNavigation?> { null }

/** How far the current screen's place lies from the window's start edge, under the rail or the TV column. */
val navigationInset: Dp
    @Composable get() = LocalSideNavigation.current?.inset ?: 0.dp

/**
 * How much further in than [start] (from this element's start edge) a row's first card must begin to sit [gap] past the
 * rail's or the TV column's end edge, wherever the row is placed; 0 without side navigation. Give [Modifier] to the row.
 */
@Composable
fun rememberNavigationClearance(start: Dp, gap: Dp): Pair<Modifier, Dp> {
    val edge = LocalSideNavigation.current?.width ?: return Modifier to 0.dp
    val density = LocalDensity.current
    val x = remember { mutableFloatStateOf(Float.NaN) }
    // The row's own place, not its visible part: a shelf placed beyond the screen's edge (focus search lays out the next
    // one there) would read as at the window's edge and get a clearance it drops once on screen, its cards moving.
    val modifier = remember(x) { Modifier.onPlaced { x.floatValue = it.positionInWindow().x } }
    // Read through a derived state: a row's first placement recomposes it only when its clearance changes, not in the
    // frame that scrolls a shelf in.
    val clearance by remember(x, edge, start, gap, density) {
        derivedStateOf {
            // In whole pixels: a fraction of one from the position's rounding is no clearance.
            val needed = with(density) { (edge + gap - start).toPx() } - x.floatValue
            if (needed.isNaN() || needed < 0.5f) 0.dp else with(density) { needed.toDp() }
        }
    }
    return modifier to clearance
}

/**
 * A screen's backdrop: [content] (the picture and the screen's own fades, filling the box) laid out reaching under the
 * rail or the TV column to the window's start edge. [modifier] sizes the box within the screen's place.
 */
@Composable
fun NavigationBackdrop(modifier: Modifier, content: @Composable BoxScope.() -> Unit) {
    // The extension stays in the chain at 0 (no side navigation): see extendUp.
    Box(modifier.extendStart(LocalSideNavigation.current?.inset ?: 0.dp), content = content)
}

/**
 * Clips what is drawn before the rail's or the TV column's end edge ([LocalSideNavigation]'s width from the window's
 * start), wherever this element sits, even drawing before its own start: scrolled-away cards and a focused card's
 * growth end at the navigation's edge, and nothing past it is cut.
 */
@Composable
internal fun Modifier.clipToNavigation(): Modifier {
    val edge = LocalSideNavigation.current?.width ?: return this
    val windowWidth = LocalWindowSize.current.value.width
    var start by remember { mutableStateOf(0f) }
    return onPlaced { coordinates ->
        start = coordinates.positionInWindow().x
    }.drawWithContent {
        val rtl = layoutDirection == LayoutDirection.Rtl
        // The navigation's edge in this element's own coordinates.
        val cut = if (rtl) (windowWidth - edge).toPx() - start else edge.toPx() - start
        // Well past the other edges: a focused card grows beyond the row.
        val left = if (rtl) -size.width else cut
        val right = if (rtl) cut else size.width * 2
        clipRect(left, -size.height, right, size.height * 2) { this@drawWithContent.drawContent() }
    }
}

/**
 * Lays the content out [by] taller, reaching up beyond the top of its place (drawn, not clipped, there). The layout stays
 * in the modifier chain when [by] is 0 (a pushed screen, the bar hidden): with Compose 1.12.1, once a node's outermost
 * layout modifier leaves its chain, `positionInWindow` of everything under it stays off by the offset that modifier gave,
 * and a popup takes its anchor from it, so every menu on a pushed screen opened the status bar's height above its anchor
 * (ExtendUpTest).
 */
internal fun Modifier.extendUp(by: Dp): Modifier = layout { measurable, constraints ->
    val extra = by.roundToPx().coerceAtLeast(0)
    val placeable = measurable.measure(constraints.copy(minHeight = constraints.minHeight + extra, maxHeight = constraints.maxHeight + extra))
    layout(placeable.width, placeable.height - extra) { placeable.place(0, -extra) }
}

/** [extendUp] towards the start: lays the content out [by] wider, reaching beyond the start of its place. */
internal fun Modifier.extendStart(by: Dp): Modifier = layout { measurable, constraints ->
    val extra = by.roundToPx().coerceAtLeast(0)
    val placeable = measurable.measure(constraints.copy(minWidth = constraints.minWidth + extra, maxWidth = constraints.maxWidth + extra))
    layout(placeable.width - extra, placeable.height) { placeable.placeRelative(-extra, 0) }
}

/**
 * A scroll edge, [height] high: the page's background behind what lies over the top of a screen whose content scrolls
 * under it (a back button; with the status bar above it where the screen reaches under that), shown while [shown]
 * ([scrollEdge]).
 */
@Composable
internal fun ScrollEdgeScrim(shown: () -> Boolean, height: Dp, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().height(height).scrollEdge(shown))
}

/**
 * The scroll edge of every screen whose content scrolls up under something at its top (a [HeaderScaffold]'s row, a back
 * button over the page): while [shown] (the content has left its top) the page's background behind this element,
 * opaque, then easing out to clear [ScrimFade] below its bottom, over what lies there (draw this element after it), so
 * the content fades out into the background where it meets the element, with no line. It reaches under the rail or the
 * TV column to the window's start edge, as a backdrop does, and fades in and out.
 */
@Composable
fun Modifier.scrollEdge(shown: () -> Boolean): Modifier {
    val current by rememberUpdatedState(shown)
    val scrolled by remember { derivedStateOf { current() } }
    val alpha by animateFloatAsState(if (scrolled) 1f else 0f, tween(160), label = "scrollEdge")
    val background = PlezyColors.Background
    val inset = LocalSideNavigation.current?.inset ?: 0.dp
    return drawBehind {
        if (alpha == 0f) return@drawBehind
        val height = size.height + ScrimFade.toPx()
        val stops = arrayOf(0f to background) + fadeStops(background, size.height / height, 1f, from = 1f)
        val reach = inset.toPx()
        drawRect(
            Brush.verticalGradient(*stops, startY = 0f, endY = height),
            topLeft = Offset(if (layoutDirection == LayoutDirection.Rtl) 0f else -reach, 0f),
            size = Size(size.width + reach, height),
            alpha = alpha,
        )
    }
}

/** The bottom bar's height (above the system's navigation bar) with its labels hidden. */
internal val BarHeightWithoutLabels = 56.dp

/**
 * The phone's bar: Material 3 Expressive's short navigation bar, icon over label ([labels]; icons alone in a 56 dp bar
 * without), a hairline above it. The labels take one size ([rememberLabelSize]), each item an equal share of the width.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun BottomBar(
    destinations: List<TopLevelDestination>,
    selected: TopLevelDestination?,
    libraryKind: MediaKind?,
    onSelect: (TopLevelDestination) -> Unit,
    labels: Boolean,
    modifier: Modifier,
) {
    val insets = ShortNavigationBarDefaults.windowInsets
    val height = BarHeightWithoutLabels + insets.asPaddingValues().calculateBottomPadding()
    BoxWithConstraints(modifier) {
        val density = LocalDensity.current
        val direction = LocalLayoutDirection.current
        val sides = with(density) { (insets.getLeft(density, direction) + insets.getRight(density, direction)).toDp() }
        val labelSize = rememberLabelSize(destinations.map { it.label }, (maxWidth - sides) / destinations.size)
        Column {
            HorizontalDivider(color = PlezyColors.Hairline)
            ShortNavigationBar(
                modifier = if (labels) Modifier else Modifier.height(height),
                containerColor = PlezyColors.Background,
                contentColor = PlezyColors.Text,
                windowInsets = insets,
            ) {
                val colors = ShortNavigationBarItemDefaults.colors(
                    selectedIconColor = PlezyColors.Text,
                    selectedTextColor = PlezyColors.Text,
                    selectedIndicatorColor = PlezyColors.SurfaceHighest,
                    unselectedIconColor = PlezyColors.TextMuted,
                    unselectedTextColor = PlezyColors.TextMuted,
                )
                for (destination in destinations) {
                    ShortNavigationBarItem(
                        selected = destination == selected,
                        onClick = { onSelect(destination) },
                        modifier = Modifier.layoutProbe("nav.${destination.probeName}"),
                        icon = { Icon(destination.icon(libraryKind), contentDescription = if (labels) null else destination.label) },
                        label = if (labels) {
                            { NavigationLabel(destination.label, LocalTextStyle.current, labelSize) }
                        } else {
                            null
                        },
                        colors = colors,
                    )
                }
            }
        }
    }
}

/** The on-screen keyboard's height in px over the window; the window's IME inset unless provided (tests). */
internal val LocalKeyboardHeight = staticCompositionLocalOf<(@Composable () -> Int)> { { WindowInsets.ime.getBottom(LocalDensity.current) } }

/**
 * The rail: the destinations (and [extra] after the first) as icon and label, centred as a group, and [footer] (the
 * profile's avatar) at the bottom edge. Where the rail is too short for that ([RailSpacing.DENSE]: a phone in landscape)
 * the items sit closer and the group is centred in the space above the footer; a group still taller than its space
 * scrolls there, never under the footer. It never expands and has no background of its own. [nav] holds its focus: the
 * entry on the selected destination, else the first.
 *
 * On a phone the labels follow [labels] (Show Navigation Bar Labels) and show only while every item fits with its label
 * ([RailLabelledExtent] each, plus the footer) in the window's height; without them the icons stand alone, each named
 * for accessibility.
 */
@Composable
private fun Rail(
    destinations: List<TopLevelDestination>,
    selected: TopLevelDestination?,
    libraryKind: MediaKind?,
    onSelect: (TopLevelDestination) -> Unit,
    extra: RailExtra?,
    footer: (@Composable (expanded: Boolean) -> Unit)?,
    nav: SideFocus,
    labels: Boolean,
) {
    // While the keyboard is up the window is short (a fold's inner screen in landscape): the rail drops its footer and
    // packs its items, so the destinations stay in view rather than the footer taking the room.
    val keyboard = LocalKeyboardHeight.current() > 0
    val footerHeight = if (footer != null && !keyboard) FooterHeight else 0.dp
    val label = with(LocalDensity.current) { MaterialTheme.typography.labelMedium.lineHeight.toDp() }
    val count = destinations.size + if (extra != null) 1 else 0
    val window = LocalWindowSize.current
    val phone = LocalWindowLayout.current.formFactor == FormFactor.HANDHELD
    val labelled by remember(window, phone, labels, count, footerHeight) {
        derivedStateOf { !phone || (labels && RailLabelledExtent * count + footerHeight <= window.value.height) }
    }
    val labelHeight = if (labelled) RailLabelGap + label else 0.dp
    // The roomy rail's height: its group centred in the rail, as far from its top as the footer from its bottom.
    val roomy = with(RailSpacing.ROOMY) {
        (margin + footerHeight) * 2 + (itemPadding * 2 + RailPillHeight + labelHeight) * count + itemGap * (count - 1).coerceAtLeast(0)
    }
    // Composed again as the rail turns dense or roomy, not on each frame of a resize.
    val dense by remember(window, roomy) { derivedStateOf { window.value.height < roomy } }
    val spacing = if (dense || keyboard) RailSpacing.DENSE else RailSpacing.ROOMY
    Column(
        Modifier.width(RailWidth).fillMaxHeight().padding(vertical = spacing.margin).onFocusChanged { nav.focused = it.hasFocus }.focusEntry(nav.entry.takeIf { selected != null }).backToScreen(nav),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // As tall as the footer, so the group sits in the middle of the rail.
        if (spacing == RailSpacing.ROOMY) Spacer(Modifier.height(footerHeight))
        // The weight's height is the scroll's minimum: a group that fits is centred in it.
        Column(
            Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(spacing.itemGap, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            val entered = selected ?: destinations.first()
            val labelSize = rememberLabelSize(listOfNotNull(extra?.label) + destinations.map { it.label }, RailWidth)
            for ((index, destination) in destinations.withIndex()) {
                if (index == 1 && extra != null) RailItem(extra.label, labelSize, extra.probe, extra.icon, selected = false, spacing, labelled, Modifier, extra.onClick)
                RailItem(
                    destination.label,
                    labelSize,
                    "nav.${destination.probeName}",
                    { tint -> Icon(destination.icon(libraryKind), contentDescription = null, Modifier.size(22.dp), tint = tint) },
                    destination == selected,
                    spacing,
                    labelled,
                    nav.itemModifier(destination, entered),
                ) { onSelect(destination) }
            }
        }
        if (!keyboard) footer?.invoke(false)
    }
}

/**
 * A rail item: its icon over its label at [labelSize] ([labelled]; else the icon alone, named [label] for
 * accessibility), [spacing]'s room above and below them. The pill behind the icon is the one indication: a tone while
 * [selected], a step lighter under the pointer, the primary fill while it has visible focus (keyboard); the item around
 * it never fills.
 */
@Composable
private fun RailItem(
    label: String,
    labelSize: TextUnit,
    probe: String,
    icon: @Composable (tint: Color) -> Unit,
    selected: Boolean,
    spacing: RailSpacing,
    labelled: Boolean,
    modifier: Modifier,
    onClick: () -> Unit,
) {
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    val hovered by interactions.collectIsHoveredAsState()
    val pressed by interactions.collectIsPressedAsState()
    val showFocus = focused && isFocusVisible()
    val text = PlezyColors.Text
    val pill by animateColorAsState(
        when {
            showFocus -> PlezyColors.Primary
            selected -> text.copy(alpha = if (hovered || pressed) 0.24f else 0.16f)
            hovered || pressed -> text.copy(alpha = 0.08f)
            else -> Color.Transparent
        },
        tween(120),
        label = "railPill",
    )
    val content = if (selected) text else PlezyColors.TextMuted
    Column(
        modifier
            .width(RailWidth)
            .layoutProbe(probe)
            .selectable(selected = selected, interactionSource = interactions, indication = null, role = Role.Tab, onClick = onClick)
            .then(if (labelled) Modifier else Modifier.semantics { contentDescription = label })
            .padding(vertical = spacing.itemPadding),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(RailLabelGap),
    ) {
        Box(Modifier.size(width = 52.dp, height = RailPillHeight).background(pill, CircleShape), contentAlignment = Alignment.Center) {
            icon(if (showFocus) PlezyColors.OnPrimary else content)
        }
        if (labelled) NavigationLabel(label, MaterialTheme.typography.labelMedium, labelSize, content)
    }
}

/** A destination's label in the bar or the rail: one line in [style] at [size] (its set's, [rememberLabelSize]). */
@Composable
private fun NavigationLabel(label: String, style: TextStyle, size: TextUnit, color: Color = Color.Unspecified) {
    Text(label, color = color, style = style.copy(fontSize = size), maxLines = 1, overflow = TextOverflow.Ellipsis)
}

/**
 * The one size of a bar's or a rail's [labels], each [width] wide in Material's label style: the largest from its size
 * down to [NavigationLabelMin], in half points, at which every label fits whole on one line, so a long word
 * ("Einstellungen", "Tənzimləmələr") reads whole and the labels read as one set; at [NavigationLabelMin] one still too
 * long (a large font) ends in "…".
 */
@Composable
private fun rememberLabelSize(labels: List<String>, width: Dp): TextUnit {
    val style = MaterialTheme.typography.labelMedium
    val measurer = rememberTextMeasurer()
    val room = with(LocalDensity.current) { width.roundToPx() }
    return remember(labels, style, room, measurer) {
        var size = style.fontSize.value
        while (size > NavigationLabelMin.value) {
            val sized = style.copy(fontSize = size.sp)
            if (labels.all { measurer.measure(it, sized, maxLines = 1, softWrap = false).size.width <= room }) return@remember size.sp
            size -= 0.5f
        }
        NavigationLabelMin
    }
}

/** The smallest a navigation label steps down to: the size of a tab bar's labels on iOS. */
internal val NavigationLabelMin = 10.sp

/**
 * The TV column (Android TV's navigation drawer pattern): 72 dp of icons, the destinations (and [extra] after the
 * first) centred in the height and [footer] (the avatar) at the bottom. Moving focus into it widens it over the screen
 * to show the labels; focus comes back to the destination it left from, else goes to the [selected] one
 * ([focusEntry]). Collapsed it has no background; open, it has the background and dims the screen beside it, which
 * doesn't move. [nav] holds its focus: the entry on the [selected] destination, else the first.
 */
@Composable
private fun TvSideNavigation(
    destinations: List<TopLevelDestination>,
    selected: TopLevelDestination?,
    libraryKind: MediaKind?,
    onSelect: (TopLevelDestination) -> Unit,
    extra: RailExtra?,
    footer: (@Composable (expanded: Boolean) -> Unit)?,
    nav: SideFocus,
) {
    var open by remember { mutableStateOf(false) }
    // Read while measuring: the widening re-lays the column out on each frame without composing it again.
    val width = animateDpAsState(if (open) TvExpandedWidth else TvCollapsedWidth, tween(effectMillis(180)), label = "tvNav")
    // Read while drawing: the fade redraws the column without composing it again.
    val opacity = animateFloatAsState(if (open) 1f else 0f, tween(effectMillis(180)), label = "tvNavBackground")
    val background = PlezyColors.Background
    // In a texture of its own (the avatar's focus growth stays inside its padding): Android redraws the whole window on
    // each frame the screen beside it scrolls, and the column is then one cached draw.
    Row(Modifier.fillMaxHeight().zIndex(1f).graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }) {
        Column(
            Modifier
                .layout { measurable, constraints ->
                    val px = constraints.constrainWidth(width.value.roundToPx())
                    val placeable = measurable.measure(constraints.copy(minWidth = px, maxWidth = px))
                    layout(placeable.width, placeable.height) { placeable.place(0, 0) }
                }
                .fillMaxHeight()
                .drawBehind { drawRect(background, alpha = opacity.value) }
                .padding(horizontal = 12.dp, vertical = 27.dp)
                .onFocusChanged {
                    open = it.hasFocus
                    nav.focused = it.hasFocus
                }
                .focusEntry(nav.entry.takeIf { selected != null })
                .backToScreen(nav),
        ) {
            Spacer(Modifier.height(if (footer != null) FooterHeight else 0.dp))
            Column(
                Modifier.weight(1f).fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
            ) {
                val entered = selected ?: destinations.first()
                for ((index, destination) in destinations.withIndex()) {
                    if (index == 1 && extra != null) TvItem(extra.label, extra.probe, extra.icon, selected = false, open, Modifier, extra.subtitle, extra.onClick)
                    TvItem(
                        destination.label,
                        "nav.${destination.probeName}",
                        { tint -> Icon(destination.icon(libraryKind), contentDescription = null, Modifier.size(24.dp), tint = tint) },
                        destination == selected,
                        open,
                        nav.itemModifier(destination, entered),
                    ) { onSelect(destination) }
                }
            }
            footer?.invoke(open)
        }
        // The screen under the open column dims towards it, eased so the dim shows no edge.
        AnimatedVisibility(open, enter = fadeIn(tween(effectMillis(180))), exit = fadeOut(tween(effectMillis(180)))) {
            Box(Modifier.width(96.dp).fillMaxHeight().background(Brush.horizontalGradient(*fadeStops(background, 0f, 1f, from = 1f))))
        }
    }
}

/** The screen's place as a focus group whose last focused element [backToScreen] returns to. */
private fun Modifier.screenGroup(nav: SideFocus): Modifier =
    focusRequester(nav.screen).focusProperties { onExit = { nav.screen.saveFocusedChild() } }.focusGroup()

/**
 * Right (Left in a right-to-left layout) from the rail or the TV column goes back to the element of the screen focus left
 * from: the open column covers the screen's start, so a move by geometry finds nothing there.
 */
@Composable
private fun Modifier.backToScreen(nav: SideFocus): Modifier {
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    return onPreviewKeyEvent { event ->
        event.type == KeyEventType.KeyDown && event.key == (if (rtl) Key.DirectionLeft else Key.DirectionRight) &&
            (nav.screen.restoreFocusedChild() || nav.screen.requestFocus(FocusDirection.Enter))
    }
}

/**
 * Left (Right in a right-to-left layout) from the screen beside the TV column where nothing lies further that way goes
 * into the column at [entry].
 */
@Composable
private fun Modifier.towardTvColumn(entry: FocusRequester): Modifier {
    val focusManager = LocalFocusManager.current
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    return onKeyEvent { event ->
        if (event.type != KeyEventType.KeyDown || event.key != (if (rtl) Key.DirectionRight else Key.DirectionLeft)) return@onKeyEvent false
        val direction = if (rtl) FocusDirection.Right else FocusDirection.Left
        focusManager.moveFocus(direction) || entry.requestFocus(direction)
    }
}

/** A TV item: a pill that rests surfaceHigh while [selected] and turns the primary fill with focus (no growth). */
@Composable
private fun TvItem(
    label: String,
    probe: String,
    icon: @Composable (tint: Color) -> Unit,
    selected: Boolean,
    open: Boolean,
    modifier: Modifier,
    subtitle: String? = null,
    onClick: () -> Unit,
) {
    PlezySurface(
        onClick = onClick,
        // Collapsed, the column shows no label: the destination's name is its description.
        modifier = modifier.fillMaxWidth().height(48.dp).layoutProbe(probe).then(if (open) Modifier else Modifier.semantics { contentDescription = label }),
        shape = CircleShape,
        color = if (selected) PlezyColors.SurfaceHigh else Color.Transparent,
        contentColor = if (selected) PlezyColors.Text else PlezyColors.TextMuted,
        role = Role.Tab,
        selected = selected,
        contentAlignment = Alignment.CenterStart,
        grows = false,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            // The icon keeps its place (the middle of the collapsed column) as the column widens.
            Box(Modifier.size(48.dp), contentAlignment = Alignment.Center) { icon(LocalContentColor.current) }
            if (open) {
                Column(Modifier.padding(start = 8.dp, end = 16.dp)) {
                    Text(label, style = MaterialTheme.typography.titleMedium, maxLines = 1, overflow = TextOverflow.Clip)
                    if (subtitle != null) {
                        Text(subtitle, style = MaterialTheme.typography.labelSmall, color = PlezyColors.MutedContent, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
        }
    }
}

/** [this] destination's icon in the bar, the rail and the TV column; Libraries' is its library's kind, [libraryKind]. */
internal fun TopLevelDestination.icon(libraryKind: MediaKind?): ImageVector = when (this) {
    TopLevelDestination.HOME -> PlezyIcons.Home
    TopLevelDestination.LIBRARIES -> libraryKind?.let(::libraryIcon) ?: PlezyIcons.VideoLibrary
    TopLevelDestination.EXPLORE -> PlezyIcons.Explore
    TopLevelDestination.SEARCH -> PlezyIcons.Search
    TopLevelDestination.SETTINGS -> PlezyIcons.Settings
}
