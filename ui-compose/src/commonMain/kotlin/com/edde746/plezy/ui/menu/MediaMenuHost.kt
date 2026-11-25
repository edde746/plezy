package com.edde746.plezy.ui.menu

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInWindow
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.toSize
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.browse.MenuEntry
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.browse.MenuOption
import com.edde746.plezy.presentation.browse.MenuPrompt
import com.edde746.plezy.presentation.browse.PickerState
import com.edde746.plezy.presentation.trackers.WatchlistSourceOption
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.BusyOverlay
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.LinkDialog
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.SheetOption
import com.edde746.plezy.ui.components.TextFieldDialog
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.icons.watchedIcon
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.trackers.WatchlistSheet
import kotlin.math.roundToInt

/**
 * Where a pointer last pressed in the window, which a desktop item menu and the download choices open at: the pressed
 * control's [bounds] when it [anchorsMenus] (a button: the menu opens at it, as a dropdown at its control), else the
 * press's point (a right click's); kept by [trackMenuAnchor] on the app's root, given to the app as [LocalMenuAnchor].
 */
class MenuAnchor {
    var bounds by mutableStateOf(Rect.Zero)

    /** The element [trackMenuAnchor] keeps it on, whose coordinates [bounds] are in. */
    internal var root: LayoutCoordinates? = null
}

/** The app's [MenuAnchor]. */
val LocalMenuAnchor = staticCompositionLocalOf<MenuAnchor?> { null }

/** Keeps [anchor] at each pointer press in this element, without taking the press from anything in it. */
fun Modifier.trackMenuAnchor(anchor: MenuAnchor): Modifier = onGloballyPositioned { anchor.root = it }.pointerInput(anchor) {
    awaitPointerEventScope {
        while (true) {
            val event = awaitPointerEvent(PointerEventPass.Initial)
            if (event.type == PointerEventType.Press) event.changes.firstOrNull()?.let { anchor.bounds = Rect(it.position, Size.Zero) }
        }
    }
}

/** A press on this control anchors the menu it opens ([MenuAnchor]) at its bounds rather than at the press's point. */
@Composable
fun Modifier.anchorsMenus(): Modifier {
    val anchor = LocalMenuAnchor.current ?: return this
    val placed = remember { Placed() }
    return onGloballyPositioned { placed.coordinates = it }.pointerInput(anchor) {
        awaitPointerEventScope {
            while (true) {
                // After the root's tracker: a parent sees the Initial pass first.
                if (awaitPointerEvent(PointerEventPass.Initial).type != PointerEventType.Press) continue
                val root = anchor.root
                val own = placed.coordinates
                if (root != null && own != null && root.isAttached && own.isAttached) {
                    anchor.bounds = Rect(root.windowToLocal(own.positionInWindow()), own.size.toSize())
                }
            }
        }
    }
}

private class Placed {
    var coordinates: LayoutCoordinates? = null
}

/** Lays this element out over [anchor]'s bounds, so a menu in it opens there. */
fun Modifier.atMenuAnchor(anchor: MenuAnchor): Modifier = layout { measurable, _ ->
    val bounds = anchor.bounds
    val placeable = measurable.measure(Constraints.fixed(bounds.width.roundToInt(), bounds.height.roundToInt()))
    layout(placeable.width, placeable.height) { placeable.place(bounds.left.roundToInt(), bounds.top.roundToInt()) }
}

/**
 * Items' and playlists' menus ([MediaMenu]) over every screen: the menu itself ([ItemMenu]: a dropdown at the pointer's
 * last press on phones, tablets and desktop, a bottom sheet on TV; an entry's submenu, Add to… or Play Version, as its
 * page), then its action's question or sheet ([MenuPrompt]) and its message (a toast). Harness names: the menu
 * `menu.<entry id>` (a submenu's `menu.<entry id>.<child id>`), `menu.confirm.<ok|cancel>`, `menu.option.<i>`,
 * `menu.text.<field|ok|cancel>`, `menu.picker.<filter|create|<row id>|retry|cancel>`, `menu.fileInfo`, `menu.busy`,
 * `menu.link` (Show link's dialog), `menu.message`.
 */
@Composable
fun MediaMenuHost(menu: MediaMenu, anchor: MenuAnchor, modifier: Modifier = Modifier) {
    val open by menu.menu.collectAsState()
    val prompt by menu.prompt.collectAsState()
    val message by menu.message.collectAsState()
    Box(modifier) {
        Box(Modifier.atMenuAnchor(anchor)) {
            ItemMenu(
                expanded = open != null,
                onDismiss = menu::dismiss,
                entries = open?.entries.orEmpty().map { it.itemEntry(menu) },
                probe = "menu",
                title = open?.title,
                media = true,
                contentTitle = true,
            )
            sourceChoice(prompt)?.let { WatchlistSheet(it, menu::choose, { menu.choose(null) }, "menu.option") }
        }
        when (val current = prompt) {
            is MenuPrompt.Confirm -> ConfirmDialog(
                current.title,
                current.message,
                current.confirmLabel,
                onConfirm = { menu.confirm(true) },
                onCancel = { menu.confirm(false) },
                probe = "menu.confirm",
                destructive = current.destructive,
                confirmProbe = "menu.confirm.ok",
                content = current.warning?.let { warning ->
                    {
                        Text(
                            warning,
                            style = MaterialTheme.typography.bodyMedium,
                            color = PlezyColors.Error,
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(PlezyColors.Error.copy(alpha = 0.12f), RoundedCornerShape(8.dp))
                                .padding(12.dp)
                                .layoutProbe("menu.confirm.warning"),
                        )
                    }
                },
            )
            is MenuPrompt.Options -> if (sourceChoice(current) == null) OptionsPrompt(current, menu)
            is MenuPrompt.TextInput -> TextFieldDialog(
                current.title,
                remember(current) { TextFieldState() },
                onSubmit = { menu.submit(it) },
                onCancel = { menu.submit(null) },
                probe = "menu.text",
                label = current.label,
                hint = current.hint,
                submitProbe = "menu.text.ok",
            )
            is MenuPrompt.Picker -> PickerPrompt(current, menu)
            is MenuPrompt.FileInfo -> FileInfoPrompt(current, menu)
            is MenuPrompt.Busy -> BusyOverlay(current.title, if (current.cancellable) menu::closePrompt else null, "menu.busy")
            is MenuPrompt.Link -> LinkPrompt(current, menu)
            null -> Unit
        }
        message?.let { TimedToast(it.text, "menu.message", menu::messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = 24.dp), it.isError) }
    }
}

/**
 * [prompt] as a watchlist source choice (every option a catalog source's, with its logo), which opens where the menu
 * did; the option's filled bookmark marks a source the item is on.
 */
private fun sourceChoice(prompt: MenuPrompt?): List<WatchlistSourceOption>? {
    val options = (prompt as? MenuPrompt.Options)?.options ?: return null
    return options.map { WatchlistSourceOption(it.logo ?: return null, it.label, it.icon == MenuIcon.BOOKMARK_REMOVE, it.detail.orEmpty()) }
}

/** [this] entry as the menu draws it, its submenu's entries with it; picking one selects its id. */
private fun MenuEntry.itemEntry(menu: MediaMenu): ItemMenuEntry =
    ItemMenuEntry(label, probe = id, selected = selected, destructive = destructive, icon = icon?.vector, children = children.map { it.itemEntry(menu) }) { menu.select(id) }

@Composable
private fun OptionsPrompt(prompt: MenuPrompt.Options, menu: MediaMenu) {
    val first = remember { FocusRequester() }
    PlezySheet(onDismiss = { menu.choose(null) }, title = prompt.title, initialFocus = first, probe = "menu.options") {
        Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            val focused = prompt.options.indexOfFirst { it.selected }.coerceAtLeast(0)
            prompt.options.forEachIndexed { index, option ->
                SheetOption(
                    option.label,
                    onClick = { menu.choose(index) },
                    modifier = (if (index == focused) Modifier.focusRequester(first) else Modifier).layoutProbe("menu.option.$index"),
                    selected = option.selected,
                    detail = option.detail,
                    icon = option.icon?.vector,
                    choice = false,
                )
            }
        }
    }
}

@Composable
private fun PickerPrompt(prompt: MenuPrompt.Picker, menu: MediaMenu) {
    val picker = prompt.picker
    val state by picker.state.collectAsState()
    val keyboard = rememberKeyboardOnSelect()
    val filterFocus = remember { FocusRequester() }
    val createFocus = remember { FocusRequester() }
    val filter = remember { TextFieldState() }
    val list = rememberLazyListState()
    val focusManager = LocalFocusManager.current
    OnTextChange(filter) { picker.filter(filter.text.toString()) }
    // Within a few rows of the end, the next page loads.
    LaunchedEffect(picker, list) {
        snapshotFlow { list.layoutInfo.visibleItemsInfo.lastOrNull()?.index to list.layoutInfo.totalItemsCount }
            .collect { (last, total) -> if (last != null && last >= total - 3) picker.loadMore() }
    }
    ModalOverlay(title = state.title, onDismiss = picker::cancel, initialFocus = if (state.showFilter) filterFocus else createFocus) {
        if (state.showFilter) {
            OutlinedTextField(
                state = filter,
                lineLimits = TextFieldLineLimits.SingleLine,
                readOnly = keyboard.readOnly,
                placeholder = { Text(state.searchHint) },
                leadingIcon = { Icon(PlezyIcons.Search, contentDescription = null) },
                shape = RoundedCornerShape(50),
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(filterFocus)
                    .then(keyboard.modifier)
                    .onPreviewKeyEvent { event ->
                        event.type == KeyEventType.KeyDown && event.key == Key.DirectionDown && focusManager.moveFocus(FocusDirection.Down)
                    }
                    .remoteLeavesField(filter)
                    .layoutProbe("menu.picker.filter"),
            )
        }
        LazyColumn(Modifier.weight(1f, fill = false), state = list, verticalArrangement = Arrangement.spacedBy(2.dp)) {
            item {
                SheetOption(
                    T.common.createNew,
                    onClick = picker::createNew,
                    modifier = Modifier.focusRequester(createFocus).layoutProbe("menu.picker.create"),
                    icon = PlezyIcons.Add,
                    choice = false,
                )
            }
            itemsIndexed(state.rows, key = { _, row -> row.id }) { _, row ->
                SheetOption(
                    row.title,
                    onClick = { if (row.enabled) picker.pick(row.id) },
                    modifier = Modifier.alpha(if (row.enabled) 1f else 0.4f).layoutProbe("menu.picker.${row.id}"),
                    detail = row.subtitle,
                    icon = row.icon.vector,
                    choice = false,
                    contentLabel = true,
                )
            }
            item { PickerStatus(state, picker::retry) }
        }
        OverlayActions {
            PlezyButton(T.common.cancel, picker::cancel, Modifier.layoutProbe("menu.picker.cancel"), style = ButtonStyle.TEXT)
        }
    }
}

@Composable
private fun PickerStatus(state: PickerState, retry: () -> Unit) {
    when {
        state.error != null -> SheetOption(
            state.error.orEmpty(),
            onClick = retry,
            modifier = Modifier.layoutProbe("menu.picker.retry"),
            icon = PlezyIcons.Error,
            choice = false,
        )
        state.loading || state.hasMore -> Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(Modifier.size(24.dp))
        }
        state.rows.isEmpty() -> Text(
            state.emptyMessage,
            Modifier.fillMaxWidth().padding(16.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = PlezyColors.TextMuted,
        )
    }
}

@Composable
private fun FileInfoPrompt(prompt: MenuPrompt.FileInfo, menu: MediaMenu) {
    PlezySheet(onDismiss = menu::closePrompt, title = T.fileInfo.title, probe = "menu.fileInfo") {
        FileInfoContent(prompt.info, prompt.title, "menu.fileInfo", Modifier.weight(1f, fill = false))
    }
}

/**
 * Show link: the item's `plezy://` link ([LinkDialog]) with its kind's hint, and, where the account has several
 * profiles, the "Open as {profile}" switch that shows the link naming the active profile; Copy says so in the menu's
 * message.
 */
@Composable
private fun LinkPrompt(prompt: MenuPrompt.Link, menu: MediaMenu) {
    val hint = when (prompt.kind) {
        MediaKind.SHOW -> T.deepLinks.showHint
        MediaKind.EPISODE -> T.deepLinks.episodeHint
        else -> T.deepLinks.movieHint
    }
    var asProfile by remember(prompt) { mutableStateOf(false) }
    val profileLink = prompt.asProfile
    LinkDialog(
        if (asProfile && profileLink != null) profileLink.link else prompt.link,
        hint,
        "menu.link",
        onCopied = { menu.show(T.deepLinks.copied) },
        onDismiss = menu::closePrompt,
        option = profileLink?.let { option ->
            {
                PlezyToggleSurface(asProfile, { asProfile = it }, Modifier.fillMaxWidth().layoutProbe("menu.link.asProfile"), shape = RoundedCornerShape(12.dp)) {
                    Row(
                        Modifier.heightIn(min = 56.dp).padding(horizontal = 16.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Text(option.label, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
                        RowSwitch(asProfile)
                    }
                }
            }
        },
    )
}

/** The glyph each UI draws for a [MenuIcon], the same thing the Apple app's symbol shows. */
val MenuIcon.vector: ImageVector
    get() = when (this) {
        MenuIcon.PLAY -> PlezyIcons.PlayArrow
        MenuIcon.TRAILER -> PlezyIcons.Trailer
        MenuIcon.SHUFFLE -> PlezyIcons.Shuffle
        MenuIcon.REPLAY -> PlezyIcons.Replay
        MenuIcon.WATCHED -> watchedIcon(watched = false)
        MenuIcon.UNWATCHED -> watchedIcon(watched = true)
        MenuIcon.CLOSE -> PlezyIcons.Close
        MenuIcon.INFO -> PlezyIcons.Info
        MenuIcon.STAR -> PlezyIcons.Star
        MenuIcon.EDIT -> PlezyIcons.Edit
        MenuIcon.LABEL -> PlezyIcons.Label
        MenuIcon.SEARCH -> PlezyIcons.Search
        MenuIcon.LINK_OFF -> PlezyIcons.Block
        MenuIcon.REMOVE -> PlezyIcons.Remove
        MenuIcon.TV -> PlezyIcons.Tv
        MenuIcon.LINK -> PlezyIcons.Link
        MenuIcon.VIDEO_FILE -> PlezyIcons.Description
        MenuIcon.OPEN_IN_NEW -> PlezyIcons.OpenInNew
        MenuIcon.DOWNLOAD -> PlezyIcons.Download
        MenuIcon.SYNC -> PlezyIcons.Sync
        MenuIcon.SYNC_DISABLED -> PlezyIcons.SyncProblem
        MenuIcon.DELETE -> PlezyIcons.Delete
        MenuIcon.DELETE_FOREVER -> PlezyIcons.DeleteForever
        MenuIcon.BOOKMARK_ADD -> PlezyIcons.BookmarkBorder
        MenuIcon.BOOKMARK_REMOVE -> PlezyIcons.Bookmark
        MenuIcon.ADD -> PlezyIcons.Add
        MenuIcon.PLAYLIST -> PlezyIcons.PlaylistPlay
        MenuIcon.COLLECTION -> PlezyIcons.VideoLibrary
        MenuIcon.SMART_PLAYLIST -> PlezyIcons.AutoAwesome
        MenuIcon.PLAY_NEXT -> PlezyIcons.QueuePlayNext
        MenuIcon.QUEUE -> PlezyIcons.PlaylistAdd
        MenuIcon.INSTANT_MIX -> PlezyIcons.AutoFixHigh
        MenuIcon.ALBUM -> PlezyIcons.Album
        MenuIcon.ARTIST -> PlezyIcons.Mic
        MenuIcon.ERROR -> PlezyIcons.ErrorOutline
        MenuIcon.TIMER -> PlezyIcons.Timer
        MenuIcon.ARROW_UP -> PlezyIcons.ArrowUpward
        MenuIcon.ARROW_DOWN -> PlezyIcons.ArrowDownward
    }

/** A shared menu option as a [ChoiceMenu]'s choice: its icon's glyph, its group's heading. */
fun MenuOption.toChoice() = MenuChoice(label, selected, detail = detail, icon = icon?.vector, heading = heading)
