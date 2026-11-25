package com.edde746.plezy.ui.watch

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.InputTransformation
import androidx.compose.foundation.text.input.TextFieldBuffer
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.rememberTextFieldState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.watch.JoinRoomUi
import com.edde746.plezy.presentation.watch.RecentRoomActionsUi
import com.edde746.plezy.presentation.watch.RecentRoomUi
import com.edde746.plezy.presentation.watch.WatchLobbyUi
import com.edde746.plezy.presentation.watch.WatchRoomUi
import com.edde746.plezy.presentation.watch.WatchScreenContent
import com.edde746.plezy.presentation.watch.WatchTogetherStore
import com.edde746.plezy.presentation.watch.WatchTogetherUiState
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.InlineError
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.TextFieldDialog
import com.edde746.plezy.ui.components.contentColumn
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.components.qrSize
import com.edde746.plezy.ui.focus.FocusInto
import com.edde746.plezy.ui.focus.StayInViewSpec
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.runtime.CompositionLocalProvider
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.focus.scrollPastControls
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.watch.WatchPartyRelays

/** What the Watch Together screen asks of its store ([WatchTogetherStore]). */
internal interface WatchScreenActions {
    fun create()

    fun openJoin()

    fun joinRecent(code: String)

    fun renameRecent(code: String, name: String)

    fun removeRecent(code: String)

    fun cancel()

    fun editJoin(text: String, caret: Int)

    fun submitJoin()

    fun execute(command: WatchCommand)
}

private class StoreActions(private val store: WatchTogetherStore) : WatchScreenActions {
    override fun create() = store.create()

    override fun openJoin() = store.openJoin()

    override fun joinRecent(code: String) = store.joinRecent(code)

    override fun renameRecent(code: String, name: String) = store.renameRecent(code, name)

    override fun removeRecent(code: String) = store.removeRecent(code)

    override fun cancel() = store.cancel()

    override fun editJoin(text: String, caret: Int) = store.editJoin(text, caret)

    override fun submitJoin() = store.submitJoin()

    override fun execute(command: WatchCommand) = store.execute(command)
}

/** The Watch Together screen ([Route.WatchTogether]) over the active profile's store; nothing without a profile. */
@Composable
fun WatchTogetherRoute(app: AppSession) {
    val store = remember(app) { app.watchTogether(Route.WatchTogether) } ?: return
    val state by store.state.collectAsState()
    val toasts = remember { WatchToasts() }
    LaunchedEffect(store) { store.messages.collect(toasts::show) }
    val actions = remember(store) { StoreActions(store) }
    WatchTogetherScreen(state, actions, toasts, onBack = { app.navigator.back() })
}

/**
 * The Watch Together screen, pushed over Home: its title with Back, then in the content column the lobby, the
 * connecting view or the room ([WatchTogetherUiState.content]; the room's code beside its QR code on wide windows, on
 * TV the code alone, very large). Focus starts on the view's first control (Create Room, Cancel, Copy Code; on TV the
 * room's first) and moves there again as the view
 * changes. Back closes a question, then a sheet, then the screen (the room goes on). [toasts] shows what a control did
 * ("Room code copied") and the store's messages, one at a time.
 *
 * The lobby's join field is the store's join form ([JoinRoomUi]), which opens with the lobby ([WatchScreenActions.openJoin]).
 *
 * Harness names: `watch.header`, `watch.screen` (the column under it), the lobby's ([Lobby]), `watch.connecting`,
 * `watch.cancel`, the room's ([WatchRoomContent]) and `watch.toast`.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun WatchTogetherScreen(state: WatchTogetherUiState, actions: WatchScreenActions, toasts: WatchToasts, onBack: () -> Unit) {
    val dimens = LocalPlezyDimens.current
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    val content = state.content
    val scroll = rememberScrollState()
    // Each view's first control: Create Room, Cancel, Copy Code (on TV the room's first).
    val first = remember { FocusRequester() }
    val joinField = remember { FocusRequester() }
    val opensJoin = content is WatchScreenContent.Lobby && state.join == null
    LaunchedEffect(opensJoin) { if (opensJoin) actions.openJoin() }
    Column(Modifier.fillMaxSize().padding(top = statusBarOverlap)) {
        ScreenHeader(state.title, Modifier.contentColumn().layoutProbe("watch.header", reportsFocus = false), onBack = onBack, scrolled = { scroll.canScrollBackward })
        BoxWithConstraints(Modifier.fillMaxSize()) {
            val wide = tv || maxWidth >= 720.dp
            // Focus landing on a control already in view scrolls nothing ([StayInViewSpec]).
            val platformScroll = LocalBringIntoViewSpec.current
            val stayInView = remember(platformScroll) { StayInViewSpec(platformScroll) }
            CompositionLocalProvider(LocalBringIntoViewSpec provides stayInView) {
                // A room on TV scrolls its details itself, its code standing still beside them ([WatchRoomContent]).
                val selfScrolling = tv && content is WatchScreenContent.Room
                Column(
                    Modifier
                        .contentColumn()
                        .fillMaxSize()
                        .layoutProbe("watch.screen", reportsFocus = false)
                        .then(
                            if (selfScrolling) {
                                Modifier.padding(horizontal = dimens.screenPadding)
                            } else {
                                Modifier
                                    .scrollPastControls(scroll)
                                    .verticalScroll(scroll)
                                    .padding(start = dimens.screenPadding, end = dimens.screenPadding, top = dimens.focusReach, bottom = dimens.sectionSpacing)
                            },
                        ),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    when (content) {
                        is WatchScreenContent.Lobby -> Lobby(content.lobby, state.join, actions, first, joinField)
                        is WatchScreenContent.Connecting -> {
                            ProgressLine(content.label, Modifier.layoutProbe("watch.connecting", reportsFocus = false))
                            PlezyButton(content.cancel, actions::cancel, Modifier.focusRequester(first).layoutProbe("watch.cancel"), icon = PlezyIcons.Close)
                        }
                        is WatchScreenContent.Room -> Room(content.room, actions, toasts, wide, first)
                    }
                }
            }
        }
    }
    FocusInto(first, key = content::class)
    // A join the relay refused comes back to the lobby: focus to the field that says why, not to Create Room.
    if (content is WatchScreenContent.Lobby) state.join?.error?.let { FocusInto(joinField, key = it) }
    toasts.Host()
}

/**
 * The lobby: what the screen is for and the relays rooms use; the last create's or recent join's failure; Create Room
 * (off, "Creating room…", while any attempt runs); the room code to join, its field inline ([JoinField]); the profile's
 * recent rooms on these relays. Harness names `watch.relay`, `watch.error`, `watch.create`, `watch.recent.<code>` with
 * `.menu`, and the join field's.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun Lobby(lobby: WatchLobbyUi, join: JoinRoomUi?, actions: WatchScreenActions, first: FocusRequester, joinField: FocusRequester) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(lobby.description, style = MaterialTheme.typography.bodyLarge, color = PlezyColors.TextMuted)
        Text(lobby.relay, Modifier.layoutProbe("watch.relay", reportsFocus = false), style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
    }
    lobby.error?.let { InlineError(it, Modifier.layoutProbe("watch.error", reportsFocus = false)) }
    GroupRow(
        lobby.create,
        onClick = actions::create,
        modifier = Modifier.focusRequester(first).layoutProbe("watch.create"),
        icon = PlezyIcons.Add,
        enabled = !lobby.busy,
        trailing = { if (lobby.creating) LoadingIndicator(Modifier.size(24.dp)) else Chevron() },
    )
    join?.let {
        Column {
            GroupHeader(it.fieldLabel)
            JoinField(it, lobby.busy, actions, joinField)
        }
    }
    if (lobby.recentRooms.isNotEmpty()) {
        Column {
            GroupHeader(lobby.recentTitle)
            RowGroup {
                lobby.recentRooms.forEachIndexed { index, room ->
                    RecentRoomRow(room, lobby.recentActions, index, lobby.recentRooms.size, enabled = !lobby.busy, actions)
                }
            }
        }
    }
}

/** A room code as it is typed: upper case, letters and digits, 6 at most, `K7M-Q2X`, the caret after the same symbols. */
private object RoomCodeInput : InputTransformation {
    override fun TextFieldBuffer.transformInput() {
        val typed = WatchPartyRelays.typedRoomCode(asCharSequence().toString(), selection.end)
        if (typed.text != asCharSequence().toString()) replace(0, length, typed.text)
        selection = TextRange(typed.caret)
    }
}

/**
 * Join a Room inline: what to enter, then the code field ([field], a pill, `K7M-Q2X` as it is typed) and Join beside
 * it, as tall as the field; why it can't join under it. Enter (the keyboard's, or the soft keyboard's Go) joins; Down
 * leaves the field for what is under it, and on TV Right at the text's end goes on to Join ([remoteLeavesField]). The
 * join itself shows as the connecting view, whose Cancel stops it; while it or a create runs the field and Join are
 * off. On TV the keyboard waits for the field to be pressed. Harness names `watch.join.field`, `watch.join`,
 * `watch.join.error`.
 */
@Composable
private fun JoinField(join: JoinRoomUi, busy: Boolean, actions: WatchScreenActions, field: FocusRequester) {
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    val keyboard = rememberKeyboardOnSelect()
    val focusManager = LocalFocusManager.current
    val text = rememberTextFieldState(join.text)
    // The edits sent to the store, its echoes still to come: fast typing runs ahead of them, so an echo is never set
    // back. What the store set itself replaces what is shown.
    val sent = remember { ArrayDeque<String>() }
    LaunchedEffect(join.text) {
        val echo = sent.indexOf(join.text)
        if (echo >= 0) {
            repeat(echo + 1) { sent.removeFirst() }
        } else if (text.text.toString() != join.text) {
            text.edit {
                replace(0, length, join.text)
                selection = TextRange(join.caret.coerceIn(0, join.text.length))
            }
        }
    }
    val current by rememberUpdatedState(actions)
    val shown by rememberUpdatedState(join.text)
    // Each change of the text, not the text it comes back with (after a join the relay refused): that would clear the
    // refusal shown under it.
    OnTextChange(text) { value ->
        if (value != shown) sent.addLast(value)
        current.editJoin(value, text.selection.end)
    }
    val enabled = !join.joining && !busy
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(join.prompt, Modifier.padding(horizontal = 16.dp), style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
        // The row is as tall as the field; Join fills that height, so the two line up top and bottom.
        Row(Modifier.height(IntrinsicSize.Min), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                state = text,
                enabled = enabled,
                readOnly = keyboard.readOnly,
                lineLimits = TextFieldLineLimits.SingleLine,
                isError = join.error != null,
                placeholder = { Text(join.hint, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                inputTransformation = RoomCodeInput,
                shape = CircleShape,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = PlezyColors.Primary,
                    unfocusedBorderColor = PlezyColors.TextFaint,
                    cursorColor = PlezyColors.Primary,
                ),
                // On a touch screen the keyboard comes with a tap: focus that lands on the field (leaving a room puts it
                // on the control nearest Leave) leaves the lobby in view. TV's waits for Select ([rememberKeyboardOnSelect]).
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Characters,
                    autoCorrectEnabled = false,
                    keyboardType = KeyboardType.Ascii,
                    imeAction = ImeAction.Go,
                    showKeyboardOnFocus = tv,
                ),
                onKeyboardAction = { actions.submitJoin() },
                modifier = Modifier
                    .weight(1f)
                    .then(keyboard.modifier)
                    .onPreviewKeyEvent { event ->
                        if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                        when (event.key) {
                            // A hardware Enter joins, as the soft keyboard's Go does.
                            Key.Enter, Key.NumPadEnter -> {
                                actions.submitJoin()
                                true
                            }
                            // A single-line field would move the cursor; Down leaves it for what is under it (D-pad).
                            Key.DirectionDown -> focusManager.moveFocus(FocusDirection.Down)
                            else -> false
                        }
                    }
                    .remoteLeavesField(text)
                    .inViewAboveKeyboard()
                    .focusRequester(field)
                    .layoutProbe("watch.join.field"),
            )
            PlezyButton(join.join, actions::submitJoin, Modifier.fillMaxHeight().layoutProbe("watch.join"), style = ButtonStyle.PRIMARY, enabled = enabled)
        }
        join.error?.let { InlineError(it, Modifier.padding(horizontal = 16.dp).layoutProbe("watch.join.error", reportsFocus = false)) }
    }
}

/**
 * A recent room: its name or code, and the code under a name (choosing it joins it, or makes it again), a loading
 * indicator while that runs, and its actions at its end (Rename Room, Remove), which a long press or a held Select
 * open too; all off while any attempt runs.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun RecentRoomRow(room: RecentRoomUi, labels: RecentRoomActionsUi, index: Int, count: Int, enabled: Boolean, actions: WatchScreenActions) {
    var menu by remember { mutableStateOf(false) }
    var renaming by remember { mutableStateOf(false) }
    val shape = groupShape(index, count)
    val probe = "watch.recent.${room.code}"
    Box {
        Row(
            Modifier.fillMaxWidth().background(PlezyColors.SurfaceHigh, shape).padding(end = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            PlezySurface(
                onClick = { actions.joinRecent(room.code) },
                modifier = Modifier.weight(1f).heightIn(min = 56.dp).layoutProbe(probe),
                shape = shape,
                color = PlezyColors.SurfaceHigh,
                enabled = enabled,
                onLongClick = { menu = true },
                onLongClickLabel = labels.menuLabel,
                contentAlignment = Alignment.CenterStart,
                grows = false,
            ) {
                Column(Modifier.padding(horizontal = 16.dp, vertical = 10.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(room.title, style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium), maxLines = 1, overflow = TextOverflow.Ellipsis)
                    room.subtitle?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.MutedContent) }
                }
            }
            if (room.joining) LoadingIndicator(Modifier.size(24.dp))
            PlezyIconButton(PlezyIcons.MoreVert, labels.menuLabel, { menu = true }, Modifier.layoutProbe("$probe.menu"), style = IconButtonStyle.PLAIN, enabled = enabled)
        }
        ItemMenu(
            expanded = menu,
            onDismiss = { menu = false },
            entries = listOf(
                ItemMenuEntry(labels.rename, probe = "rename", icon = PlezyIcons.Edit) {
                    menu = false
                    renaming = true
                },
                ItemMenuEntry(labels.remove, probe = "remove", destructive = true, icon = PlezyIcons.Delete) {
                    menu = false
                    actions.removeRecent(room.code)
                },
            ),
            probe = "watch.recent.actions",
            title = room.title,
        )
    }
    if (renaming) {
        TextFieldDialog(
            labels.renameTitle,
            rememberTextFieldState(room.name),
            onSubmit = { name ->
                renaming = false
                actions.renameRecent(room.code, name)
            },
            onCancel = { renaming = false },
            probe = "watch.rename",
            hint = room.hint,
            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
            submitLabel = labels.save,
            cancelLabel = labels.cancel,
        )
    }
}

/** The room, laid out by [WatchRoomContent]: its controls copy with the clipboard and say so in [toasts]. */
@Suppress("DEPRECATION")
@Composable
private fun Room(room: WatchRoomUi, actions: WatchScreenActions, toasts: WatchToasts, wide: Boolean, first: FocusRequester) {
    val clipboard = LocalClipboardManager.current
    val current by rememberUpdatedState(actions)
    val roomActions = remember(clipboard, toasts) {
        RoomActions(
            execute = { current.execute(it) },
            copy = { text, done ->
                clipboard.setText(AnnotatedString(text))
                toasts.show(done)
            },
        )
    }
    WatchRoomContent(room, roomActions, wide, qrSize(), firstFocus = first)
}

/**
 * Home's Watch Together shortcut, a chip that opens the Watch Together screen: the group icon, filled while in a room
 * (connecting included), outlined otherwise; with others in the room their count after the label. Harness name
 * `home.watchTogether`.
 */
@Composable
fun WatchTogetherShortcut(app: AppSession, modifier: Modifier = Modifier) {
    val toolbar by app.watchToolbar.collectAsState()
    PlezyChip(
        toolbar.badge?.let { "${toolbar.label} · $it" } ?: toolbar.label,
        selected = false,
        onClick = { app.navigator.navigate(Route.WatchTogether) },
        modifier = modifier.layoutProbe("home.watchTogether"),
        leadingIcon = if (toolbar.inSession) PlezyIcons.Group else PlezyIcons.GroupOutlined,
    )
}

/**
 * The room's notices ("Sam joined"), app-wide: one toast each, the next replacing the one showing, above the navigation
 * bar. Not while the player is on top ([playerOnTop]): it shows them as its own messages.
 */
@Composable
fun WatchNotices(app: AppSession, playerOnTop: Boolean) {
    val toasts = remember { WatchToasts() }
    val hidden by rememberUpdatedState(playerOnTop)
    LaunchedEffect(app) { app.watchNotices.collect { if (!hidden) toasts.show(it) } }
    toasts.Host()
}
