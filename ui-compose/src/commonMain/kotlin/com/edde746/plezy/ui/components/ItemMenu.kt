package com.edde746.plezy.ui.components

import androidx.collection.intListOf
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.DropdownMenuPopup
import androidx.compose.material3.DropdownMenuPopupPositionProvider
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorPosition
import androidx.compose.material3.MenuDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.KeyInputModifierNode
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.SuspendingPointerInputModifierNode
import androidx.compose.ui.input.pointer.isSecondaryPressed
import androidx.compose.ui.layout.layout
import androidx.compose.ui.node.CompositionLocalConsumerModifierNode
import androidx.compose.ui.node.DelegatingNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.ObserverModifierNode
import androidx.compose.ui.node.currentValueOf
import androidx.compose.ui.node.observeReads
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.platform.WindowInfo
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntRect
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.focus.StayInViewSpec
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import kotlinx.coroutines.flow.first

/**
 * Opens an item's menu the way each input asks for one: a secondary (right) click on the element, or the Menu key (a
 * keyboard's context-menu key, a remote's menu button, a gamepad's X or Y) or Shift+F10 while it or something in it has
 * focus. A long press on touch and, on TV, holding Select for 500 ms (`AdaptiveLayout`'s long-press timeout) belong to
 * the element's own click handling (`combinedClickable`'s `onLongClick`, [PosterCard]'s `onLongClick`), which every
 * element with a menu on TV needs: a remote may have no Menu key, and the SHIELD's system keeps it from apps. Place it
 * before the element's focus target, so the target's key events reach it.
 */
fun Modifier.menuGestures(onMenu: () -> Unit): Modifier = this then MenuGesturesElement(onMenu)

private data class MenuGesturesElement(val onMenu: () -> Unit) : ModifierNodeElement<MenuGesturesNode>() {
    override fun create() = MenuGesturesNode(onMenu)

    override fun update(node: MenuGesturesNode) {
        node.onMenu = onMenu
    }
}

private class MenuGesturesNode(var onMenu: () -> Unit) : DelegatingNode(), KeyInputModifierNode {
    init {
        delegate(
            SuspendingPointerInputModifierNode {
                awaitPointerEventScope {
                    while (true) {
                        // The initial pass, so the element's own click handling never sees the secondary press.
                        val event = awaitPointerEvent(PointerEventPass.Initial)
                        if (event.type == PointerEventType.Press && event.buttons.isSecondaryPressed) {
                            event.changes.forEach { it.consume() }
                            onMenu()
                        }
                    }
                }
            },
        )
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.type != KeyEventType.KeyDown) return false
        val menu = event.isContextMenuKey || (event.key == Key.F10 && event.isShiftPressed)
        if (menu) onMenu()
        return menu
    }

    override fun onPreKeyEvent(event: KeyEvent): Boolean = false
}

/**
 * On TV, the remote's Play/Pause and Play keys do what Select does on the element ([onPlay]): the elements Select
 * plays, a Continue Watching card and an episode, take it; on any other element the keys go on unhandled, as off TV.
 * The press and its release are both taken, so neither reaches the system's media keys. Place it before the element's
 * focus target, as [menuGestures].
 */
fun Modifier.playKey(onPlay: () -> Unit): Modifier = this then PlayKeyElement(onPlay)

private data class PlayKeyElement(val onPlay: () -> Unit) : ModifierNodeElement<PlayKeyNode>() {
    override fun create() = PlayKeyNode(onPlay)

    override fun update(node: PlayKeyNode) {
        node.onPlay = onPlay
    }
}

private class PlayKeyNode(var onPlay: () -> Unit) : Modifier.Node(), KeyInputModifierNode, CompositionLocalConsumerModifierNode {
    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.key != Key.MediaPlayPause && event.key != Key.MediaPlay) return false
        if (currentValueOf(LocalWindowLayout).formFactor != FormFactor.TV) return false
        if (event.type == KeyEventType.KeyDown) onPlay()
        return true
    }

    override fun onPreKeyEvent(event: KeyEvent): Boolean = false
}

/**
 * The key that asks for a context menu: a keyboard's context-menu key on desktop (which Compose reports by its AWT
 * code, not as `Key.Menu`); a remote's or keyboard's menu key, or a gamepad's X or Y, on Android.
 */
internal expect val KeyEvent.isContextMenuKey: Boolean

/**
 * The key that presses a focused element (Compose's: Select, Enter, the keypad's Enter, Space) held down now, as the app
 * sees it: [OverlayHostBox] watches every key before a screen takes it. A menu that opens while it is down was opened
 * by holding it ([ignoreHeldSelect]).
 */
internal class HeldSelect {
    var key: Key? = null
        private set

    /** Notes a press key's [event] going down or up. It only watches: the event goes on. */
    fun watch(event: KeyEvent): Boolean {
        if (event.isPressKey) {
            when (event.type) {
                KeyEventType.KeyDown -> key = event.key
                KeyEventType.KeyUp -> release(event.key)
            }
        }
        return false
    }

    /** [released] is up: its release went to a menu's own window (a dropdown), where the app's content never sees it. */
    fun release(released: Key) {
        if (key == released) key = null
    }
}

/** The window's [HeldSelect], one per [OverlayHostBox]. */
internal val LocalHeldSelect = staticCompositionLocalOf { HeldSelect() }

private val KeyEvent.isPressKey: Boolean
    get() = key == Key.DirectionCenter || key == Key.Enter || key == Key.NumPadEnter || key == Key.Spacebar

/**
 * Drops the press key ([HeldSelect]) held down as a menu opens, until it is let go: holding Select or Enter on an item
 * opens its menu ([menuGestures]), and the key, still down, repeats into the entry that takes focus, where its release
 * would press the entry. Android counts a key's repeats; desktop doesn't (AWT reports each as a new press), so the
 * menu goes by what was down as it opened. A press that starts in the menu picks its entry as usual.
 */
internal fun Modifier.ignoreHeldSelect(): Modifier = this then IgnoreHeldSelectElement

private data object IgnoreHeldSelectElement : ModifierNodeElement<IgnoreHeldSelectNode>() {
    override fun create() = IgnoreHeldSelectNode()

    override fun update(node: IgnoreHeldSelectNode) = Unit
}

private class IgnoreHeldSelectNode :
    Modifier.Node(),
    KeyInputModifierNode,
    CompositionLocalConsumerModifierNode,
    ObserverModifierNode {
    private var ignored: Key? = null

    override fun onAttach() = onObservedReadsChanged()

    override fun onObservedReadsChanged() = observeReads { ignored = currentValueOf(LocalHeldSelect).key }

    override fun onPreKeyEvent(event: KeyEvent): Boolean {
        val held = ignored ?: return false
        if (event.key != held) return false
        if (event.type == KeyEventType.KeyUp) {
            ignored = null
            currentValueOf(LocalHeldSelect).release(held)
        }
        return true
    }

    override fun onKeyEvent(event: KeyEvent): Boolean = false
}

/**
 * One entry of an [ItemMenu]: its [label] from the screen's store and the intent it sends; [probe] names it for the
 * harness where the entries vary from item to item (else its index does). [selected] marks the choice in effect with
 * a check; [destructive] entries (delete, cancel) read in the error colour; [icon] leads the label in the dropdown (the
 * action a button stands for, as in Detail's ⋯) and in a media item's TV panel, not in TV's other side panels.
 * [detail] is a line under the label (a library's server). [contentLabel]: whether [label] and [detail] are content
 * text (an addon's or a person's), which takes its direction from its first letter ([contentDirection]). [leading] (a
 * profile's avatar) takes the icon's place everywhere; [trailing] follows the label (a lock). An entry with [children]
 * is a submenu: picking it shows them in its place, under a row back to the menu it is in (on TV the sheet's title and
 * Back); [onClick] is not called. A [keepsOpen] entry (a switch's) leaves the menu open when picked.
 */
@Immutable
class ItemMenuEntry(
    val label: String,
    val probe: String? = null,
    val selected: Boolean = false,
    val destructive: Boolean = false,
    val icon: ImageVector? = null,
    val contentLabel: Boolean = false,
    val detail: String? = null,
    val leading: (@Composable () -> Unit)? = null,
    val trailing: (@Composable () -> Unit)? = null,
    val children: List<ItemMenuEntry> = emptyList(),
    val keepsOpen: Boolean = false,
    val onClick: () -> Unit = {},
)

/** A group of a [SectionedItemMenu]'s entries under an optional [title] ("Keep synced"). */
@Immutable
class ItemMenuSection(val title: String?, val entries: List<ItemMenuEntry>)

/**
 * An item's menu (mark as watched, remove, …): on TV a [PlezySheet] (a panel along the right edge, [title] at its
 * top), on phones, tablets and desktop a [PlezyDropdownMenu] opened at the element it belongs to (place it next to that
 * element in a Box around both). The first entry takes focus when it opens, so a keyboard or remote user can act at once; picking an
 * entry closes the menu, then acts. [probe] names the entries `<probe>.0`, `<probe>.1`, … (or `<probe>.<entry's probe>`) for the
 * harness. A [media] item's menu (a poster, a Continue Watching card, a library item, an episode: [MediaMenu],
 * [itemEntry]) shows each entry's icon before its label on TV too.
 * [contentTitle]: whether [title] is content text (an addon's or a person's), which takes its direction from its first
 * letter ([contentDirection]).
 */
@Composable
fun ItemMenu(
    expanded: Boolean,
    onDismiss: () -> Unit,
    entries: List<ItemMenuEntry>,
    probe: String,
    title: String? = null,
    media: Boolean = false,
    contentTitle: Boolean = false,
) {
    // Destructive entries at the end (Delete from server) sit apart, under a divider.
    val trailing = entries.takeLastWhile { it.destructive }.size
    val sections = if (trailing == 0 || trailing == entries.size) {
        listOf(ItemMenuSection(null, entries))
    } else {
        listOf(ItemMenuSection(null, entries.dropLast(trailing)), ItemMenuSection(null, entries.takeLast(trailing)))
    }
    SectionedItemMenu(expanded, onDismiss, sections, probe, title, media, contentTitle)
}

/**
 * An [ItemMenu] in [sections]: each section's title over its entries, a divider between sections in the dropdown.
 * Entries are counted across the sections for their harness names; a submenu's entries are named under its entry's
 * name (`<probe>.<entry>.<child>`), its row back `<probe>.back`. The selected entry of the page shown takes focus, else
 * its first.
 */
@Composable
fun SectionedItemMenu(
    expanded: Boolean,
    onDismiss: () -> Unit,
    sections: List<ItemMenuSection>,
    probe: String,
    title: String? = null,
    media: Boolean = false,
    contentTitle: Boolean = false,
) {
    val pages = remember { MenuPages() }
    // Each opening starts at the top level.
    if (expanded && !pages.open) pages.reset()
    pages.open = expanded
    val page = pages.resolve(sections, probe)
    // A pick closes the menu first and acts (then dismisses, as a pick does) once it has gone: in the dropdown, once its
    // popup has gone, as an entry that swaps the screen (a library picked, a show opened) would otherwise take the
    // popup's owner away while the popup still draws its exit; on TV, once the panel has given focus back to its
    // opener, so an overlay the entry opens (a channel's View details) opens from there and gives focus back there.
    val picked = remember { PendingPick() }
    val pick = { entry: ItemMenuEntry, index: Int ->
        when {
            entry.children.isNotEmpty() -> pages.enter(index)
            entry.keepsOpen -> entry.onClick()
            else -> picked.close {
                entry.onClick()
                onDismiss()
            }
        }
    }
    val back = pages::leave
    val target = remember { FocusRequester() }
    // Back from a submenu: its entry; else the page's selected entry, else its first.
    val focusIndex = pages.left ?: page.sections.flatMap { it.entries }.indexOfFirst { it.selected }.coerceAtLeast(0)
    if (!menusAnchored()) {
        PlezySheet(
            onDismiss = onDismiss,
            title = page.parent?.label ?: title,
            visible = expanded && !picked.closing,
            initialFocus = target,
            probe = "$probe.sheet",
            onBack = if (page.parent != null) back else onDismiss,
            contentTitle = if (page.parent != null) page.parent.contentLabel else contentTitle,
        ) {
            // A long menu (a series' download choices) scrolls; focus brings the entry it moves to into view.
            Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                var index = 0
                page.sections.forEachIndexed { sectionIndex, section ->
                    if (sectionIndex > 0) HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
                    section.title?.let { GroupHeader(it) }
                    for (entry in section.entries) {
                        val at = index
                        SheetOption(
                            label = entry.label,
                            onClick = { pick(entry, at) },
                            modifier = Modifier
                                .layoutProbe("${page.probe}.${entry.probe ?: index}")
                                .then(if (at == focusIndex) Modifier.focusRequester(target) else Modifier),
                            selected = entry.selected,
                            choice = false,
                            destructive = entry.destructive,
                            icon = if (media) entry.icon else null,
                            contentLabel = entry.contentLabel,
                            detail = entry.detail,
                            contentDetail = entry.contentLabel,
                            leading = entry.leading,
                            badge = entry.submenuMark() ?: entry.trailing,
                        )
                        index++
                    }
                }
            }
            // A page opened or left inside the open sheet: focus to its entry (the sheet's own focus does it as it opens).
            LaunchedEffect(pages.path) { if (pages.moved) target.requestFocus() }
        }
        // After the sheet's own closing effect, which gives focus back to its opener.
        if (picked.closing) SideEffect { picked.run() }
        return
    }
    PlezyDropdownMenu(expanded = expanded && !picked.closing, onDismiss = onDismiss) {
        DisposableEffect(Unit) { onDispose { picked.run() } }
        page.parent?.let { parent ->
            PlezyMenuItem(
                label = parent.label,
                onClick = back,
                modifier = Modifier.layoutProbe("$probe.back"),
                icon = PlezyIcons.ArrowBack,
                contentLabel = parent.contentLabel,
            )
            HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
        }
        var index = 0
        page.sections.forEachIndexed { sectionIndex, section ->
            if (sectionIndex > 0) HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
            section.title?.let { MenuSectionTitle(it) }
            for (entry in section.entries) {
                val at = index
                PlezyMenuItem(
                    label = entry.label,
                    onClick = { pick(entry, at) },
                    modifier = Modifier
                        .layoutProbe("${page.probe}.${entry.probe ?: index}")
                        .then(if (at == focusIndex) Modifier.focusRequester(target) else Modifier),
                    selected = entry.selected,
                    destructive = entry.destructive,
                    icon = entry.icon,
                    contentLabel = entry.contentLabel,
                    detail = entry.detail,
                    contentDetail = entry.contentLabel,
                    leading = entry.leading,
                    trailing = entry.submenuMark() ?: entry.trailing,
                )
                index++
            }
        }
        // The menu's content is composed each time it opens, and again on each page.
        if (index > 0) LaunchedEffect(pages.path) { target.requestFocus() }
    }
}

/**
 * Whether a menu or a choice opens at the control it belongs to (a dropdown, on phones, tablets and desktop) rather
 * than as a side panel (TV, where focus moves through a list better than through a popup): the one rule every menu,
 * choice and options popup of the app follows.
 */
@Composable
fun menusAnchored(): Boolean = LocalWindowLayout.current.formFactor != FormFactor.TV

/** A submenu's mark after its entry's label, the way it opens. */
private fun ItemMenuEntry.submenuMark(): (@Composable () -> Unit)? =
    if (children.isEmpty()) null else ({ Icon(PlezyIcons.ChevronRight, contentDescription = null) })

/** The page of a [SectionedItemMenu] shown: its [parent] entry (null at the top), [sections] and harness name [probe]. */
private class MenuPage(val parent: ItemMenuEntry?, val sections: List<ItemMenuSection>, val probe: String)

/**
 * Which page of a [SectionedItemMenu] is shown: the [path] of entry indexes from the top level down, while it is
 * [open]; whether it [moved] to another page since it opened, and the submenu entry it [left] last (focus goes back to
 * it). A path the entries no longer have (they changed while it was open) shows the top level.
 */
private class MenuPages {
    var open = false
    var path by mutableStateOf(emptyList<Int>())
        private set
    var moved = false
        private set
    var left: Int? = null
        private set

    fun reset() {
        path = emptyList()
        moved = false
        left = null
    }

    fun enter(index: Int) {
        path = path + index
        moved = true
        left = null
    }

    fun leave() {
        left = path.lastOrNull()
        path = path.dropLast(1)
        moved = true
    }

    fun resolve(sections: List<ItemMenuSection>, probe: String): MenuPage {
        var page = MenuPage(null, sections, probe)
        for (index in path) {
            val entry = page.sections.flatMap { it.entries }.getOrNull(index)?.takeIf { it.children.isNotEmpty() } ?: return MenuPage(null, sections, probe)
            page = MenuPage(entry, listOf(ItemMenuSection(null, entry.children)), "${page.probe}.${entry.probe ?: index}")
        }
        return page
    }
}

/** A section's title in a [PlezyDropdownMenu], lined up with its entries' labels. */
@Composable
internal fun MenuSectionTitle(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp).semantics { heading() },
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
    )
}

/**
 * A dropdown menu in the app's look: a [PlezyColors.SurfaceHighest] card with rounded corners and Material's menu
 * shadow, a step above the rows and sheets it opens over, no tonal tint. It opens at its anchor, the layout it is placed
 * in ([MenuAtAnchor]), inside the window's safe area ([InSafeArea]: clear of the status and navigation bars, a display
 * cutout and the keyboard) and [MenuMargin] clear of that area's top and bottom; a longer menu scrolls inside that
 * height, with a thumb down its end that says so ([scrollThumb]), and the arrow keys walk its entries. Closed while it
 * has focus (Esc, an entry picked), it gives focus back to the control that had it as it opened ([OverlayHost.closed]),
 * as a sheet does.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun PlezyDropdownMenu(expanded: Boolean, onDismiss: () -> Unit, modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    val window = LocalWindowSize.current
    val host = LocalOverlayHost.current
    val focus = remember { MenuFocus() }
    // Opening: the control that has focus now, before an entry takes it, is where it goes back to.
    if (expanded && !focus.open) {
        focus.opener = host?.opener()
        focus.pin.reset()
    }
    val closing = !expanded && focus.open
    focus.open = expanded
    // Closing with focus: back to the opener now, while the menu's window still has it; once that window has gone, the
    // app's window would be left with no focused control.
    if (closing && focus.held && host != null) SideEffect { host.closed(focus.opener, held = true) }
    DropdownMenuPopup(
        expanded = expanded,
        onDismissRequest = onDismiss,
        popupPositionProvider = rememberInSafeArea(MenuDefaults.rememberDropdownMenuPopupPositionProvider(MenuAtAnchor), focus.pin),
    ) {
        Surface(shape = MaterialTheme.shapes.medium, color = PlezyColors.SurfaceHighest, shadowElevation = MenuDefaults.ShadowElevation) {
            val scroll = rememberScrollState()
            Column(
                modifier
                    .maxHeightOf(window, focus.pin)
                    .onFocusChanged { focus.held = it.hasFocus }
                    .ignoreHeldSelect()
                    .arrowKeyFocus()
                    .padding(vertical = 8.dp)
                    .widthIn(min = MenuMinWidth)
                    .width(IntrinsicSize.Max)
                    .scrollThumb(scroll, MaterialTheme.colorScheme.onSurfaceVariant)
                    .verticalScroll(scroll),
                content = content,
            )
        }
    }
}

/**
 * While the content scrolled by [scroll] runs past its height, a thin [color] thumb down the end edge, as long as the
 * shown part is of the whole and as far down as it is: a menu that stops on a whole row otherwise reads as complete.
 * Content past it by less than a dp (rows' heights rounded to pixels) fits: no thumb.
 */
private fun Modifier.scrollThumb(scroll: ScrollState, color: Color): Modifier = drawWithContent {
    drawContent()
    val max = scroll.maxValue
    if (max < 1.dp.toPx() || max == Int.MAX_VALUE) return@drawWithContent
    val viewport = size.height
    val length = maxOf(viewport * viewport / (viewport + max), ThumbMinLength.toPx())
    val top = (viewport - length) * scroll.value / max
    val width = ThumbWidth.toPx()
    val inset = ThumbInset.toPx()
    val x = if (layoutDirection == LayoutDirection.Ltr) size.width - inset - width else inset
    drawRoundRect(color, Offset(x, top), Size(width, length), CornerRadius(width / 2))
}

private val ThumbWidth = 4.dp
private val ThumbInset = 4.dp
private val ThumbMinLength = 24.dp

/** A [PlezyDropdownMenu]'s focus: whether it is [open], the [opener] focus goes back to, whether it [held] focus; its [pin]. */
private class MenuFocus {
    var open = false
    var opener: FocusOpener? = null
    var held = false
    val pin = MenuPin()
}

/**
 * Where an open [PlezyDropdownMenu] first opened, in window pixels: its [x], and the edge it grew from, [bottom] when it
 * opened above its anchor, else [top]. A later page (a submenu, taller or wider) keeps that place and scrolls inside
 * the room it leaves, rather than jumping over its anchor.
 */
private class MenuPin {
    var x: Int? = null
    var top: Int? = null
    var bottom: Int? = null
    var windowHeight = 0

    fun reset() {
        x = null
        top = null
        bottom = null
    }
}

/** The narrowest a [PlezyDropdownMenu] is. */
private val MenuMinWidth = 220.dp

/**
 * At most [window]'s height less [MenuMargin] above and below, read as it lays out (the window resizes under it); once
 * [pin]ned, at most the room from its pinned edge to the margin.
 */
private fun Modifier.maxHeightOf(window: State<DpSize>, pin: MenuPin): Modifier = layout { measurable, constraints ->
    val margin = MenuMargin.roundToPx()
    val room = pin.top?.let { pin.windowHeight - it - margin } ?: pin.bottom?.let { it - margin }
    val max = minOf((window.value.height - MenuMargin * 2).roundToPx(), room ?: Int.MAX_VALUE).coerceAtLeast(0)
    val placeable = measurable.measure(
        constraints.copy(minHeight = constraints.minHeight.coerceAtMost(max), maxHeight = constraints.maxHeight.coerceAtMost(max)),
    )
    layout(placeable.width, placeable.height) { placeable.place(0, 0) }
}

/**
 * Where a [PlezyDropdownMenu] opens: the candidates Material tries in turn, the first that fits inside the safe area's
 * margins (the last one moved inside them when none does). The window here is the safe area ([InSafeArea]).
 *
 * From a row, an anchor wider than the menu (a setting, a stream, an ordered row, an episode), the menu opens over the
 * row's end, where its value, ⋮ or button is: its end at the row's end, its top at the row's top, else (a sheet's last
 * rows have no room below them) its bottom at the row's bottom. It never opens off at the row's start or beside the
 * row, over the row before or after it, where it would read as that row's. From anything smaller (a chip, a button) it
 * is Material's dropdown: its start at the anchor's start, else its end at the anchor's end; below the anchor, else
 * above it, else centred on its top edge, else at the window's edge nearer to it.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
private val MenuAtAnchor = MenuAnchorPosition.Custom(
    xCandidates = {
        val ltr = layoutDirection == LayoutDirection.Ltr
        val start = if (ltr) anchorBounds.left else anchorBounds.right - menuSize.width
        val end = if (ltr) anchorBounds.right - menuSize.width else anchorBounds.left
        when {
            anchorBounds.width > menuSize.width -> intListOf(end)
            anchorBounds.center.x < windowSize.width / 2 -> intListOf(start, end, 0)
            else -> intListOf(start, end, windowSize.width - menuSize.width)
        }
    },
    yCandidates = {
        if (anchorBounds.width > menuSize.width) {
            intListOf(anchorBounds.top, anchorBounds.bottom - menuSize.height)
        } else {
            val edge = if (anchorBounds.center.y < windowSize.height / 2) 0 else windowSize.height - menuSize.height
            intListOf(anchorBounds.bottom, anchorBounds.top - menuSize.height, anchorBounds.top - menuSize.height / 2, edge)
        }
    },
)

/**
 * Material's margin between a menu and the window's top and bottom edges (its `MenuVerticalMargin`): a menu that fits
 * inside it opens at its anchor, one taller than the window without it is centred over the whole window.
 */
private val MenuMargin = 48.dp

@Composable
private fun rememberInSafeArea(material: DropdownMenuPopupPositionProvider, pin: MenuPin): DropdownMenuPopupPositionProvider {
    val insets = WindowInsets.safeDrawing
    val density = LocalDensity.current
    val window = LocalWindowInfo.current
    return remember(material, insets, density, window, pin) { InSafeArea(material, insets, density, window, pin) }
}

/**
 * [material]'s placement inside the window's safe area: the window ([WindowInfo.containerSize]) less
 * [WindowInsets.safeDrawing], given to Material as its window, the anchor and the menu moved into its coordinates and
 * back. Material checks a menu against a window of the size it is given from that window's origin; on Android the popup
 * gives it the visible display frame's size (the window less the system bars and the keyboard) but the anchor in the
 * window's coordinates, which start at the screen's top, behind the status bar. Material's limits then lay a status
 * bar's height too high: a menu with room below its row opened upward (Into in Export and import's sheet), and one could
 * open under the status bar. Once the menu has opened, its [pin] holds that place for its later pages.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
private class InSafeArea(
    private val material: DropdownMenuPopupPositionProvider,
    private val insets: WindowInsets,
    private val density: Density,
    private val window: WindowInfo,
    private val pin: MenuPin,
) : DropdownMenuPopupPositionProvider {
    override val transformOrigin: TransformOrigin get() = material.transformOrigin

    override fun calculatePosition(anchorBounds: IntRect, windowSize: IntSize, layoutDirection: LayoutDirection, popupContentSize: IntSize): IntOffset {
        val left = insets.getLeft(density, layoutDirection)
        val top = insets.getTop(density)
        val container = window.containerSize
        val area = IntSize(
            (container.width - left - insets.getRight(density, layoutDirection)).coerceAtLeast(0),
            (container.height - top - insets.getBottom(density)).coerceAtLeast(0),
        )
        val pinnedX = pin.x
        if (pinnedX != null) {
            val x = pinnedX.coerceAtMost(left + area.width - popupContentSize.width).coerceAtLeast(left)
            val y = pin.top ?: ((pin.bottom ?: 0) - popupContentSize.height)
            return IntOffset(x, y)
        }
        val origin = IntOffset(left, top)
        val placed = material.calculatePosition(anchorBounds.translate(-origin), area, layoutDirection, popupContentSize) + origin
        if (popupContentSize.height > 0) {
            pin.x = placed.x
            pin.windowHeight = container.height
            if (placed.y + popupContentSize.height <= anchorBounds.top) pin.bottom = placed.y + popupContentSize.height else pin.top = placed.y
        }
        return placed
    }
}

/**
 * An entry of a [PlezyDropdownMenu]: [label] (two lines at most: the menu is at most 280 dp wide, so a long option
 * wraps rather than losing its end), its [detail] line under it, its [icon] (or [leading]) before it, a check when [selected]
 * (else [trailing] after it);
 * [destructive] in the error colour. A screen reader hears an action, and "selected" on the one in effect; a [choice]
 * (one of a [ChoiceMenu]'s) as a radio button, selected or not. [contentLabel], [contentDetail]: whether [label],
 * [detail] is content text (an addon's or a person's), which takes its direction from its first letter
 * ([contentDirection]).
 */
@Composable
fun PlezyMenuItem(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    selected: Boolean = false,
    detail: String? = null,
    destructive: Boolean = false,
    icon: ImageVector? = null,
    choice: Boolean = false,
    contentLabel: Boolean = false,
    contentDetail: Boolean = false,
    leading: (@Composable () -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    val text = if (destructive) PlezyColors.Error else MaterialTheme.colorScheme.onSurface
    DropdownMenuItem(
        text = {
            Column {
                val labelStyle = LocalTextStyle.current
                Text(label, style = if (contentLabel) labelStyle.contentDirection() else labelStyle, maxLines = 2, overflow = TextOverflow.Ellipsis)
                if (detail != null) {
                    val detailStyle = MaterialTheme.typography.bodySmall
                    Text(
                        detail,
                        style = if (contentDetail) detailStyle.contentDirection() else detailStyle,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        },
        onClick = onClick,
        leadingIcon = leading ?: icon?.let { { Icon(it, contentDescription = null) } },
        trailingIcon = if (selected) ({ Icon(PlezyIcons.Check, contentDescription = null) }) else trailing,
        // Over the item's own role: semantics outside the click handling are applied last.
        modifier = modifier.semantics {
            if (choice) role = Role.RadioButton
            if (choice || selected) this.selected = selected
        },
        colors = MenuDefaults.itemColors(textColor = text, leadingIconColor = text, trailingIconColor = text),
    )
}

/**
 * The least height of a [SheetOption]: a control's ([controlHeight]), and in a car ([automotive]) at least a standard
 * list row's 56 dp, the compact rows of phones and desktops being hard to hit on a head unit's touch screen.
 */
internal fun sheetOptionMinHeight(automotive: Boolean, controlHeight: Dp): Dp =
    if (automotive) maxOf(controlHeight, 56.dp) else controlHeight

/**
 * One option in a [PlezySheet]'s list: a full-width row, no fill until hovered or focused (then the primary fill,
 * which alone shows focus: a row doesn't grow), [icon] (or [leading]) before [label] with its [detail] line, then [badge], and a check
 * when [selected]; [destructive] in the error colour while not focused. A screen reader hears a [choice] as a radio
 * button, selected or not; an action (an item's menu on TV) as a button, "selected" on the one in effect.
 * [onLongClick] is the row's second action ([PlezySurface]'s, named [onLongClickLabel]). [contentLabel],
 * [contentDetail]: whether [label], [detail] is content text (an addon's or a person's), which takes its direction
 * from its first letter ([contentDirection]).
 */
@Composable
fun SheetOption(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    selected: Boolean = false,
    detail: String? = null,
    destructive: Boolean = false,
    icon: ImageVector? = null,
    choice: Boolean = true,
    contentLabel: Boolean = false,
    contentDetail: Boolean = false,
    onLongClick: (() -> Unit)? = null,
    onLongClickLabel: String? = null,
    badge: (@Composable () -> Unit)? = null,
    leading: (@Composable () -> Unit)? = null,
) {
    PlezySurface(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().heightIn(min = sheetOptionMinHeight(LocalAppearance.current.automotive, LocalPlezyDimens.current.controlHeight)),
        shape = MaterialTheme.shapes.medium,
        color = Color.Transparent,
        contentColor = if (destructive) PlezyColors.Error else MaterialTheme.colorScheme.onSurface,
        selected = if (choice || selected) selected else null,
        role = if (choice) Role.RadioButton else Role.Button,
        onLongClick = onLongClick,
        onLongClickLabel = onLongClickLabel,
        contentAlignment = Alignment.CenterStart,
        grows = false,
    ) {
        Row(
            Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (leading != null) leading() else if (icon != null) Icon(icon, contentDescription = null, Modifier.size(24.dp))
            Column(Modifier.weight(1f)) {
                val labelStyle = MaterialTheme.typography.bodyLarge
                Text(label, style = if (contentLabel) labelStyle.contentDirection() else labelStyle, maxLines = 2, overflow = TextOverflow.Ellipsis)
                if (detail != null) {
                    val detailStyle = MaterialTheme.typography.bodySmall
                    Text(
                        detail,
                        style = if (contentDetail) detailStyle.contentDirection() else detailStyle,
                        color = PlezyColors.MutedContent,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            badge?.invoke()
            if (selected) Icon(PlezyIcons.Check, contentDescription = null, Modifier.size(20.dp))
        }
    }
}

/**
 * One option of a [ChoiceMenu]: its [label], a [detail] line (a catalog's addon), and whether it is [selected];
 * [leading] goes before the label (a catalog source's logo), else its [icon]. [heading]: the heading of the group it
 * starts, after a divider (a sort's fields under Sort By, after its directions; empty: the divider alone). [contentLabel], [contentDetail]:
 * whether [label], [detail] is content text (an addon's or a person's), which takes its direction from its first
 * letter ([contentDirection]).
 */
@Immutable
class MenuChoice(
    val label: String,
    val selected: Boolean,
    val detail: String? = null,
    val contentLabel: Boolean = false,
    val contentDetail: Boolean = false,
    val leading: (@Composable () -> Unit)? = null,
    val icon: ImageVector? = null,
    val heading: String? = null,
)

/**
 * The options of a choice (a sort order, a catalog, a genre, a setting's value), opened from an anchor: a
 * [PlezyDropdownMenu] at it (place both in a Box), on TV a [PlezySheet] titled [title] with the selected option
 * focused (in options that come in groups, the last group's: a sort's field under its directions), which a remote moves
 * through; a focused option already on screen and clear of the fades doesn't scroll it ([StayInViewSpec]), and it opens
 * at its top, scrolled to the selected option only when that is off screen. Fades over its top and bottom while it holds
 * more there ([scrollEdgeFades]), which a focused option is kept clear of. Picking an option calls [onPick] and closes
 * it, unless [closeOnPick] is false (a multi-select filter's
 * options are toggled). Harness names: `[probe].option.<i>`. [contentTitle]: whether [title] is content text (an
 * addon's or a person's), which takes its direction from its first letter ([contentDirection]).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ChoiceMenu(
    expanded: Boolean,
    onDismiss: () -> Unit,
    title: String,
    choices: List<MenuChoice>,
    onPick: (Int) -> Unit,
    probe: String,
    closeOnPick: Boolean = true,
    contentTitle: Boolean = false,
) {
    val pick = { index: Int ->
        onPick(index)
        if (closeOnPick) onDismiss()
    }
    val lastGroup = choices.indexOfLast { it.heading != null }.coerceAtLeast(0)
    val selectedIndex = (lastGroup until choices.size).firstOrNull { choices[it].selected } ?: choices.indexOfFirst { it.selected }.coerceAtLeast(0)
    if (!menusAnchored()) {
        val initial = remember { FocusRequester() }
        PlezySheet(onDismiss = onDismiss, title = title, visible = expanded, initialFocus = initial, probe = "$probe.sheet", contentTitle = contentTitle) {
            val list = rememberLazyListState()
            // The first layout shows the list from its top: the sheet focuses the selected option if it is on screen,
            // else this scrolls to it and focuses it.
            LaunchedEffect(Unit) {
                val shown = snapshotFlow { list.layoutInfo }.first { it.totalItemsCount > 0 }
                val row = shown.visibleItemsInfo.firstOrNull { it.index == selectedIndex }
                if (row == null || row.offset < shown.viewportStartOffset || row.offset + row.size > shown.viewportEndOffset) {
                    list.scrollToItem(selectedIndex)
                    initial.requestFocus()
                }
            }
            val platformScroll = LocalBringIntoViewSpec.current
            val fade = with(LocalDensity.current) { SCROLL_EDGE_FADE.toPx() }
            val stayInView = remember(platformScroll, fade) { StayInViewSpec(platformScroll, before = fade, after = fade) }
            CompositionLocalProvider(LocalBringIntoViewSpec provides stayInView) {
                LazyColumn(
                    Modifier.weight(1f, fill = false).scrollEdgeFades({ list.hidesRowsAbove() }, { list.hidesRowsBelow() }),
                    state = list,
                    contentPadding = PaddingValues(vertical = LocalPlezyDimens.current.focusReach),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    itemsIndexed(choices) { index, choice ->
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            choice.heading?.let { heading ->
                                if (index > 0) HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
                                if (heading.isNotEmpty()) GroupHeader(heading)
                            }
                            SheetOption(
                                choice.label,
                                onClick = { pick(index) },
                                selected = choice.selected,
                                detail = choice.detail,
                                icon = choice.icon,
                                contentLabel = choice.contentLabel,
                                contentDetail = choice.contentDetail,
                                leading = choice.leading,
                                modifier = Modifier
                                    .then(if (index == selectedIndex) Modifier.focusRequester(initial) else Modifier)
                                    .layoutProbe("$probe.option.$index"),
                            )
                        }
                    }
                }
            }
        }
        return
    }
    // A pick that closes the dropdown closes it first and acts once its popup has gone, as an item menu's does
    // ([SectionedItemMenu]).
    val picked = remember { PendingPick() }
    PlezyDropdownMenu(expanded = expanded && !picked.closing, onDismiss = onDismiss) {
        DisposableEffect(Unit) { onDispose { picked.run() } }
        val initial = remember { FocusRequester() }
        choices.forEachIndexed { index, choice ->
            choice.heading?.let { heading ->
                if (index > 0) HorizontalDivider(Modifier.padding(vertical = 4.dp), color = PlezyColors.Hairline)
                if (heading.isNotEmpty()) MenuSectionTitle(heading)
            }
            PlezyMenuItem(
                choice.label,
                onClick = { if (closeOnPick) picked.close { pick(index) } else onPick(index) },
                selected = choice.selected,
                choice = true,
                detail = choice.detail,
                icon = choice.icon,
                contentLabel = choice.contentLabel,
                contentDetail = choice.contentDetail,
                leading = choice.leading,
                modifier = Modifier
                    .then(if (index == selectedIndex) Modifier.focusRequester(initial) else Modifier)
                    .layoutProbe("$probe.option.$index"),
            )
        }
        // The menu's content is composed each time it opens: focus on the selected option, for keyboards.
        if (choices.isNotEmpty()) LaunchedEffect(Unit) { initial.requestFocus() }
    }
}

/**
 * A menu's pick waiting for the menu to go: [close] hides the menu ([closing]) and keeps the pick, which [run] calls
 * once the dropdown's popup is gone or the TV panel has given focus back.
 */
private class PendingPick {
    var closing by mutableStateOf(false)
        private set
    private var action: (() -> Unit)? = null

    fun close(pick: () -> Unit) {
        action = pick
        closing = true
    }

    fun run() {
        val pending = action ?: return
        action = null
        pending()
        closing = false
    }
}
