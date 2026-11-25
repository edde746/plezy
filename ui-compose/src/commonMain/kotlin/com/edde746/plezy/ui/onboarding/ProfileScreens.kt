package com.edde746.plezy.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.onboarding.AddConnectionOption
import com.edde746.plezy.presentation.onboarding.AddProfileStore
import com.edde746.plezy.presentation.onboarding.BorrowStore
import com.edde746.plezy.presentation.onboarding.ConfirmToggle
import com.edde746.plezy.presentation.onboarding.ConnectionChip
import com.edde746.plezy.presentation.onboarding.ProfileAction
import com.edde746.plezy.presentation.onboarding.ProfileConnectionUi
import com.edde746.plezy.presentation.onboarding.ProfileDetailStore
import com.edde746.plezy.presentation.onboarding.ProfilePickerStore
import com.edde746.plezy.presentation.onboarding.ProfilePickerUiState
import com.edde746.plezy.presentation.onboarding.ProfileTileUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.BusyOverlay
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.LocalPaneRoot
import com.edde746.plezy.ui.components.LinkDialog
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.contentColumn
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.overlayOpener
import com.edde746.plezy.ui.focus.FocusInto
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.focusEntry
import com.edde746.plezy.ui.focus.focusRing
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/** What the picker reports; each maps to the [ProfilePickerStore] intent of the same name. */
class ProfilePickerIntents(
    val select: (id: String) -> Unit,
    val act: (id: String, action: ProfileAction) -> Unit,
    val addProfile: () -> Unit,
    val back: () -> Unit,
    val messageShown: () -> Unit,
    val confirm: () -> Unit,
    val dismissConfirm: () -> Unit,
    val setConfirmToggle: (Boolean) -> Unit,
    val linkCopied: () -> Unit,
    val dismissLink: () -> Unit,
)

/** The profile picker of [store]. */
@Composable
fun ProfilePickerScreen(store: ProfilePickerStore, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    ProfilePickerScreen(
        state,
        ProfilePickerIntents(
            select = store::select,
            act = store::act,
            addProfile = store::addProfile,
            back = store::back,
            messageShown = store::messageShown,
            confirm = store::confirm,
            dismissConfirm = store::dismissConfirm,
            setConfirmToggle = store::setConfirmToggle,
            linkCopied = store::linkCopied,
            dismissLink = store::dismissLink,
        ),
        modifier,
    )
}

/**
 * The profile picker: a required pick (the app's start) asks "Who's watching?" over the tiles; one opened later has a
 * page header titled for the entry that opened it (Manage profiles from Manage profiles, else Switch Profile) with the
 * back button (none where the picker is a pane beside Settings' list,
 * [LocalPaneRoot]). The profiles are avatar tiles ([ProfileTileItem]: a tap switches to it; Manage under it; a long
 * press, a held Select, the Menu key or a right click open Show link, Delete, Sign out), then an Add profile tile; "No
 * profiles available" when there are none, a loader until they are read. Once a switch is past its PIN the screen is
 * covered by "Switching profile…". Back leaves (a required pick: the app, [ProfilePickerStore.back]). The tiles are one
 * focus group: a move into it lands on the tile that had focus last, else the first, which takes focus as the tiles
 * show.
 *
 * Harness names: `picker`, `picker.header`, `picker.tile.<i>` with `.menu` and `.manage`, `picker.menu.<i>`,
 * `picker.add`, `picker.switching`, `picker.toast`, `picker.confirm…`, `picker.link`.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ProfilePickerScreen(state: ProfilePickerUiState, intents: ProfilePickerIntents, modifier: Modifier = Modifier) {
    val dimens = LocalPlezyDimens.current
    val first = remember { FocusRequester() }
    SystemBackHandler(onBack = intents.back)
    Box(modifier.fillMaxSize().background(PlezyColors.Background).layoutProbe("picker", reportsFocus = false)) {
        Column(Modifier.fillMaxSize()) {
            val scroll = rememberScrollState()
            if (!state.required) ScreenHeader(state.title, Modifier.layoutProbe("picker.header", reportsFocus = false), onBack = intents.back, scrolled = { scroll.canScrollBackward })
            BoxWithConstraints(Modifier.weight(1f).fillMaxWidth()) {
                if (state.tiles.isEmpty() && state.loading) {
                    LoadingState()
                    return@BoxWithConstraints
                }
                val minHeight = maxHeight
                Column(
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(scroll)
                        .heightIn(min = minHeight)
                        .padding(horizontal = dimens.screenPadding, vertical = dimens.sectionSpacing),
                    verticalArrangement = Arrangement.spacedBy(dimens.sectionSpacing, Alignment.CenterVertically),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    if (state.required) {
                        Text(state.title, Modifier.semantics { heading() }, style = MaterialTheme.typography.headlineLarge, textAlign = TextAlign.Center)
                    }
                    if (state.tiles.isEmpty()) Text(T.messages.noProfilesAvailable, style = MaterialTheme.typography.bodyLarge, color = PlezyColors.TextMuted)
                    FlowRow(
                        Modifier.widthIn(max = 960.dp).focusEntry(first),
                        horizontalArrangement = Arrangement.spacedBy(dimens.gutter * 2, Alignment.CenterHorizontally),
                        verticalArrangement = Arrangement.spacedBy(dimens.gutter * 2),
                    ) {
                        state.tiles.forEachIndexed { index, tile ->
                            // Keyed by the profile: a re-sort after the first paint keeps focus on the same tile.
                            key(tile.id) {
                                ProfileTileItem(
                                    tile,
                                    index,
                                    enabled = !state.switching,
                                    onSelect = { intents.select(tile.id) },
                                    onAction = { intents.act(tile.id, it) },
                                    modifier = if (index == 0) Modifier.focusRequester(first) else Modifier,
                                )
                            }
                        }
                        AddTile(intents.addProfile, enabled = !state.switching, modifier = if (state.tiles.isEmpty()) Modifier.focusRequester(first) else Modifier)
                    }
                }
            }
        }
        if (state.switching) BusyOverlay(T.profiles.switchingProfile, null, "picker.switching")
        state.message?.let { TimedToast(it, "picker.toast", intents.messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = dimens.sectionSpacing)) }
    }
    state.confirm?.let { confirm ->
        ConfirmDialog(
            confirm.title,
            confirm.message,
            confirm.confirmLabel,
            onConfirm = intents.confirm,
            onCancel = intents.dismissConfirm,
            probe = "picker.confirm",
            modifier = Modifier.layoutProbe("picker.confirm", reportsFocus = false),
            content = confirm.toggle?.let { toggle -> { ConfirmToggleRow(toggle, intents.setConfirmToggle, "picker.confirm.toggle") } },
        )
    }
    state.link?.let { LinkDialog(it.url, it.hint, "picker.link", onCopied = intents.linkCopied, onDismiss = intents.dismissLink) }
    // Keyboards and remotes start on the first tile once the tiles are there.
    FocusInto(first, key = state.tiles.isNotEmpty())
}

/** The avatar size of the picker's tiles: larger on TV (10-foot viewing). */
@Composable
private fun tileAvatarSize(): Dp = if (LocalWindowLayout.current.formFactor == FormFactor.TV) 120.dp else 96.dp

/**
 * A profile: its avatar (a check on the current one, a lock when a PIN guards it) over its name, and its connections a
 * line each (each backend's mark and label) or "No connections" in the error colour; the whole tile is the
 * button (choosing the current one does nothing). Focus rings the avatar. Manage shows under it where the profile can be
 * managed; its other actions are its menu, which a long press, a held Select, the Menu key or a right click open, and
 * screen readers offer them on the tile itself.
 */
@Composable
private fun ProfileTileItem(
    tile: ProfileTileUi,
    index: Int,
    enabled: Boolean,
    onSelect: () -> Unit,
    onAction: (ProfileAction) -> Unit,
    modifier: Modifier = Modifier,
) {
    var menu by remember { mutableStateOf(false) }
    val menuActions = tile.actions - ProfileAction.MANAGE
    val hasMenu = menuActions.isNotEmpty() && enabled
    val open = { menu = true }
    val size = tileAvatarSize()
    val labels = menuActions.associateWith { it.label() }
    Box {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Tile(
                label = tile.name,
                onClick = { if (!tile.active) onSelect() },
                enabled = enabled,
                onLongClick = if (hasMenu) open else null,
                onLongClickLabel = T.libraries.moreActionsNamed(tile.name),
                modifier = modifier
                    .then(if (hasMenu) Modifier.menuGestures(open) else Modifier)
                    .semantics {
                        if (tile.active) {
                            selected = true
                            stateDescription = T.profiles.active
                        }
                        if (hasMenu) customActions = menuActions.map { action -> CustomAccessibilityAction(labels.getValue(action)) { onAction(action); true } }
                    }
                    .layoutProbe("picker.tile.$index"),
                detail = {
                    if (!tile.hasConnections) {
                        Text(T.profiles.noConnections, style = MaterialTheme.typography.bodySmall, color = PlezyColors.Error, textAlign = TextAlign.Center)
                    } else if (tile.chips.isNotEmpty()) {
                        ConnectionChipLines(tile.chips)
                    }
                },
            ) {
                ProfileAvatar(tile.name, tile.avatarUrl, size, tile.locked, current = tile.active, imageModifier = it)
            }
            if (ProfileAction.MANAGE in tile.actions) {
                PlezyButton(
                    T.profiles.manage,
                    { onAction(ProfileAction.MANAGE) },
                    Modifier.layoutProbe("picker.tile.$index.manage"),
                    style = ButtonStyle.TEXT,
                    icon = PlezyIcons.Edit,
                    enabled = enabled,
                )
            }
        }
        ItemMenu(
            expanded = menu,
            onDismiss = { menu = false },
            entries = menuActions.map { action ->
                ItemMenuEntry(
                    label = labels.getValue(action),
                    probe = action.name.lowercase(),
                    destructive = action == ProfileAction.DELETE || action == ProfileAction.SIGN_OUT,
                    onClick = { onAction(action) },
                )
            },
            probe = "picker.menu",
            title = tile.name,
        )
    }
}

private fun ProfileAction.label(): String = when (this) {
    ProfileAction.MANAGE -> T.profiles.manage
    ProfileAction.SHOW_LINK -> T.deepLinks.showProfileLink
    ProfileAction.DELETE -> T.profiles.delete
    ProfileAction.SIGN_OUT -> T.profiles.signOut
}

/** "Add profile": an empty avatar with a plus. */
@Composable
private fun AddTile(onClick: () -> Unit, enabled: Boolean, modifier: Modifier) {
    val size = tileAvatarSize()
    Tile(T.profiles.addProfile, onClick, enabled, modifier = modifier.layoutProbe("picker.add")) {
        Box(it.size(size).background(PlezyColors.SurfaceHigh, CircleShape), contentAlignment = Alignment.Center) {
            Icon(OnboardingMarks.PersonAdd, contentDescription = null, Modifier.size(40.dp))
        }
    }
}

/**
 * A picker tile: [avatar] over [label] and its [detail] line; focus (keyboard, remote) rings the avatar's circle, the
 * modifier [avatar] is given, under its badge. [onLongClick] (named [onLongClickLabel]) is a long press or, on TV, a
 * held Select.
 */
@Composable
private fun Tile(
    label: String,
    onClick: () -> Unit,
    enabled: Boolean,
    modifier: Modifier = Modifier,
    onLongClick: (() -> Unit)? = null,
    onLongClickLabel: String? = null,
    detail: (@Composable () -> Unit)? = null,
    avatar: @Composable (ring: Modifier) -> Unit,
) {
    val size = tileAvatarSize()
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    Column(
        modifier
            .overlayOpener()
            .combinedClickable(
                interactionSource = interactions,
                indication = null,
                enabled = enabled,
                role = Role.Button,
                onLongClickLabel = if (onLongClick != null) onLongClickLabel else null,
                onLongClick = onLongClick,
                onClick = onClick,
            )
            .padding(12.dp)
            .width(size + 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        avatar(Modifier.focusRing(CircleShape, focused))
        Text(
            label,
            Modifier.padding(top = 12.dp),
            style = MaterialTheme.typography.titleMedium,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
        if (detail != null) Box(Modifier.padding(top = 2.dp)) { detail() }
    }
}

/**
 * A profile's connections, muted, a line each: its backend's mark (12) and its label, cut short alone, so a long server
 * name never hides the connection after it.
 */
@Composable
private fun ConnectionChipLines(chips: List<ConnectionChip>) {
    val muted = PlezyColors.TextMuted
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        for (chip in chips) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(OnboardingMarks.backend(chip.backend), contentDescription = null, Modifier.size(12.dp), tint = muted)
                Text(
                    chip.label,
                    Modifier.padding(start = 5.dp),
                    style = MaterialTheme.typography.labelSmall,
                    color = muted,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

/** A confirmation's switch ([ConfirmToggle]): its title over its description, beside the switch. Harness name [probe]. */
@Composable
private fun ConfirmToggleRow(toggle: ConfirmToggle, onToggle: (Boolean) -> Unit, probe: String) {
    PlezyToggleSurface(toggle.checked, onToggle, Modifier.fillMaxWidth().layoutProbe(probe), shape = RoundedCornerShape(12.dp)) {
        Row(Modifier.heightIn(min = 56.dp).padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(toggle.title, style = MaterialTheme.typography.bodyLarge)
                Text(toggle.description, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
            }
            RowSwitch(toggle.checked)
        }
    }
}

/**
 * A new local profile ([AddProfileStore]): its name, PIN protection (optional: Set PIN, or "PIN set" with Change and
 * Remove), then Continue (which stores it and opens its Add connection) and Cancel.
 *
 * Harness names: `addprofile.name`, `addprofile.pin`, `addprofile.pin.change`, `addprofile.pin.remove`,
 * `addprofile.continue`, `addprofile.cancel`, `addprofile.toast`.
 */
@Composable
fun AddProfileScreen(store: AddProfileStore, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val dimens = LocalPlezyDimens.current
    val name = remember { FocusRequester() }
    Box(modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            val scroll = rememberScrollState()
            ScreenHeader(T.profiles.newProfile, onBack = onBack, scrolled = { scroll.canScrollBackward })
            Column(
                Modifier.contentColumn().fillMaxSize().focusGroup().verticalScroll(scroll).padding(horizontal = dimens.screenPadding, vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                AccountField(
                    value = state.name,
                    onValueChange = store::setName,
                    label = T.profiles.profileNameLabel,
                    probe = "addprofile.name",
                    modifier = Modifier.focusRequester(name),
                    placeholder = T.profiles.profileNameHint,
                    error = if (state.nameRequired) T.addServer.required else null,
                    enabled = !state.busy,
                    imeAction = ImeAction.Done,
                    capitalization = KeyboardCapitalization.Words,
                    onSubmit = store::save,
                )
                Text(T.profiles.pinProtectionOptional, style = MaterialTheme.typography.labelLarge)
                Text(T.profiles.pinExplain, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
                PinStatus(state.pinSet, "addprofile.pin", onSet = store::setPin, onClear = store::clearPin)
                PlezyButton(
                    T.profiles.continueButton,
                    store::save,
                    Modifier.padding(top = 12.dp).layoutProbe("addprofile.continue"),
                    style = ButtonStyle.PRIMARY,
                    enabled = !state.busy && state.name.isNotBlank(),
                    fill = true,
                )
                PlezyButton(T.common.cancel, store::cancel, Modifier.layoutProbe("addprofile.cancel"), style = ButtonStyle.TEXT, fill = true)
            }
        }
        state.message?.let { TimedToast(it, "addprofile.toast", store::messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = dimens.sectionSpacing)) }
    }
    FocusInto(name, key = Unit)
}

/**
 * A profile's PIN: Set PIN, or a "PIN set" badge with Change and Remove. Set PIN and Change are one button, which
 * keeps focus as the PIN is set (the PIN pad it opened gives focus back to it) and Remove hands focus to it before the
 * PIN goes: a focused control that leaves has Android hand focus to the screen's first control, its header's Back.
 * Harness names `<probe>`, `<probe>.change`, `<probe>.remove`.
 */
@Composable
internal fun PinStatus(pinSet: Boolean, probe: String, onSet: () -> Unit, onClear: () -> Unit) {
    val pinButton = remember { FocusRequester() }
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        if (pinSet) {
            Row(
                Modifier.background(PlezyColors.SurfaceHighest, MaterialTheme.shapes.small).padding(horizontal = 12.dp, vertical = 8.dp).layoutProbe(probe, reportsFocus = false),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Icon(PlezyIcons.Lock, contentDescription = null, Modifier.size(18.dp))
                Text(T.profiles.pinSet, style = MaterialTheme.typography.labelMedium)
            }
        }
        PlezyButton(
            if (pinSet) T.profiles.changePin else T.profiles.setPin,
            onSet,
            Modifier.focusRequester(pinButton).layoutProbe(if (pinSet) "$probe.change" else probe),
            style = if (pinSet) ButtonStyle.TEXT else ButtonStyle.SECONDARY,
            icon = if (pinSet) null else PlezyIcons.Lock,
            fill = !pinSet,
        )
        if (pinSet) {
            PlezyButton(
                T.profiles.removePin,
                {
                    pinButton.requestFocus()
                    onClear()
                },
                Modifier.layoutProbe("$probe.remove"),
                style = ButtonStyle.TEXT,
            )
        }
    }
}

/**
 * A profile's detail ([ProfileDetailStore]): a local profile's name (Save once changed) and PIN, a Plex Home user's PIN
 * note; its connections (each with its menu: Make default, Edit, Remove, or the Plex Home account's Sign out) with Add;
 * a local profile's Delete profile. It closes ([onGone]) once the profile is gone.
 *
 * Harness names: `profile.name`, `profile.name.save`, `profile.pin…`, `profile.add`, `profile.connection.<i>` with
 * `.menu`, `profile.connection.menu.<i>`, `profile.delete`, `profile.confirm…`, `profile.toast`.
 */
@Composable
fun ProfileDetailScreen(store: ProfileDetailStore, onBack: () -> Unit, onGone: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val dimens = LocalPlezyDimens.current
    val top = remember { FocusRequester() }
    LaunchedEffect(state.gone) { if (state.gone) onGone() }
    Box(modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            val scroll = rememberScrollState()
            ScreenHeader(state.title, onBack = onBack, contentTitle = true, scrolled = { scroll.canScrollBackward })
            Column(
                Modifier.contentColumn().fillMaxSize().focusGroup().focusRequester(top).verticalScroll(scroll)
                    .padding(horizontal = dimens.screenPadding, vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                if (state.local) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Box(Modifier.weight(1f)) {
                            AccountField(
                                value = state.name,
                                onValueChange = store::setName,
                                label = T.profiles.profileNameLabel,
                                probe = "profile.name",
                                imeAction = ImeAction.Done,
                                capitalization = KeyboardCapitalization.Words,
                                onSubmit = store::saveName,
                            )
                        }
                        val trimmed = state.name.trim()
                        PlezyButton(
                            T.common.save,
                            store::saveName,
                            Modifier.layoutProbe("profile.name.save"),
                            style = ButtonStyle.PRIMARY,
                            enabled = trimmed.isNotEmpty() && trimmed != state.title,
                        )
                    }
                }
                Text(T.profiles.pinProtectionLabel, Modifier.padding(top = 12.dp), style = MaterialTheme.typography.labelLarge)
                val note = state.pinNote
                if (note != null) {
                    Text(note, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
                } else {
                    PinStatus(state.pinSet, "profile.pin", onSet = store::setPin, onClear = store::clearPin)
                }
                Row(Modifier.padding(top = 20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(T.profiles.connectionsLabel, Modifier.weight(1f), style = MaterialTheme.typography.labelLarge)
                    PlezyButton(T.profiles.add, store::addConnection, Modifier.layoutProbe("profile.add"), style = ButtonStyle.TEXT, icon = PlezyIcons.Add)
                }
                if (state.connections.isEmpty()) {
                    Text(T.profiles.noConnectionsHint, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
                } else {
                    RowGroup {
                        state.connections.forEachIndexed { index, connection ->
                            ConnectionRow(connection, index, state.connections.size, store)
                        }
                    }
                }
                if (state.local) {
                    PlezyButton(
                        T.profiles.deleteProfileButton,
                        store::delete,
                        Modifier.padding(top = 12.dp).layoutProbe("profile.delete"),
                        style = ButtonStyle.DESTRUCTIVE,
                        icon = PlezyIcons.Delete,
                        fill = true,
                    )
                }
            }
        }
        state.message?.let { TimedToast(it, "profile.toast", store::messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = dimens.sectionSpacing)) }
    }
    state.confirm?.let { confirm ->
        ConfirmDialog(
            confirm.title,
            confirm.message,
            confirm.confirmLabel,
            onConfirm = store::confirm,
            onCancel = store::dismissConfirm,
            probe = "profile.confirm",
            modifier = Modifier.layoutProbe("profile.confirm", reportsFocus = false),
            content = confirm.toggle?.let { toggle -> { ConfirmToggleRow(toggle, store::setConfirmToggle, "profile.confirm.toggle") } },
        )
    }
    FocusInto(top, key = Unit)
}

/** A connection of the profile: its mark, label and subtitle, and ⋮ with what can be done to it. */
@Composable
private fun ConnectionRow(connection: ProfileConnectionUi, index: Int, count: Int, store: ProfileDetailStore) {
    var menu by remember { mutableStateOf(false) }
    val entries = buildList {
        if (connection.plexHomeAccount) {
            add(ItemMenuEntry(T.profiles.signOut, probe = "signout", destructive = true) { store.signOut(connection.connectionId) })
        } else {
            if (!connection.isDefault) add(ItemMenuEntry(T.profiles.makeDefault, probe = "default") { store.makeDefault(connection.connectionId) })
            if (connection.editable) add(ItemMenuEntry(T.common.edit, probe = "edit") { store.edit(connection.connectionId) })
            add(ItemMenuEntry(T.profiles.removeConnection, probe = "remove", destructive = true) { store.remove(connection.connectionId) })
        }
    }
    Box {
        GroupRow(
            connection.label,
            onClick = { menu = true },
            modifier = Modifier.layoutProbe("profile.connection.$index"),
            shape = groupShape(index, count),
            subtitle = if (connection.plexHomeAccount) T.profiles.plexHomeAccount else connection.subtitle,
            icon = OnboardingMarks.backend(connection.backend),
            trailing = { Icon(PlezyIcons.MoreVert, contentDescription = T.profiles.manage) },
        )
        ItemMenu(expanded = menu, onDismiss = { menu = false }, entries = entries, probe = "profile.connection.menu", title = connection.label)
    }
}

/**
 * The ways to add a connection ([AddConnectionOption]s, from [Route.AddConnection]'s store): a card each, its backend's
 * mark (Borrow's share icon), title and subtitle; choosing one opens its screen ([onOpen]). Focus starts on the first;
 * Back from an option's screen finds it on that option.
 *
 * Harness names: `addconnection.<i>`.
 */
@Composable
fun AddConnectionScreen(title: String, options: List<AddConnectionOption>, onOpen: (Route) -> Unit, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val dimens = LocalPlezyDimens.current
    val memory = rememberFocusMemory()
    Column(modifier.fillMaxSize()) {
        val scroll = rememberScrollState()
        ScreenHeader(title, onBack = onBack, scrolled = { scroll.canScrollBackward })
        Column(
            Modifier.contentColumn().fillMaxSize().focusGroup().verticalScroll(scroll).padding(horizontal = dimens.screenPadding, vertical = 8.dp),
        ) {
            RowGroup {
                options.forEachIndexed { index, option ->
                    GroupRow(
                        option.title,
                        onClick = { onOpen(option.route) },
                        modifier = Modifier.rememberFocus(memory, "option.$index").layoutProbe("addconnection.$index"),
                        shape = groupShape(index, options.size),
                        subtitle = option.subtitle,
                        icon = option.backend?.let(OnboardingMarks::backend) ?: PlezyIcons.Share,
                        trailing = { Chevron() },
                    )
                }
            }
        }
    }
    RestoreFocus(memory, ready = options.isNotEmpty(), fallback = "option.0".takeIf { options.isNotEmpty() })
}

/**
 * Borrowing another profile's connection ([BorrowStore]): what it does, then a row per connection (its mark and label,
 * the profile lending it, a lock when that profile's PIN is asked), a loader while they are read, Try again when that
 * failed, "Nothing to borrow" when there are none.
 *
 * Harness names: `borrow.<i>`, `borrow.toast`.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun BorrowConnectionScreen(store: BorrowStore, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val dimens = LocalPlezyDimens.current
    val first = remember { FocusRequester() }
    Box(modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            val scroll = rememberScrollState()
            ScreenHeader(state.title, onBack = onBack, contentTitle = true, scrolled = { scroll.canScrollBackward })
            when {
                state.loading -> LoadingState()
                state.failed -> ErrorState(T.profiles.borrowLoadFailed, onRetry = store::retry)
                state.candidates.isEmpty() -> EmptyState(T.profiles.borrowEmptySubtitle, title = T.profiles.borrowEmpty, icon = PlezyIcons.Share)
                else -> Column(
                    Modifier.contentColumn().fillMaxSize().focusGroup().verticalScroll(scroll).padding(horizontal = dimens.screenPadding, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text(T.profiles.borrowExplain, Modifier.padding(horizontal = 4.dp), style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
                    RowGroup {
                        state.candidates.forEachIndexed { index, candidate ->
                            GroupRow(
                                candidate.label,
                                onClick = { store.borrow(candidate.index) },
                                modifier = Modifier.layoutProbe("borrow.$index").then(if (index == 0) Modifier.focusRequester(first) else Modifier),
                                shape = groupShape(index, state.candidates.size),
                                subtitle = candidate.from,
                                icon = OnboardingMarks.backend(candidate.backend),
                                enabled = !state.busy,
                                trailing = if (candidate.locked) ({ Icon(PlezyIcons.Lock, contentDescription = null, Modifier.size(18.dp)) }) else null,
                            )
                        }
                    }
                    if (state.busy) LoadingIndicator(Modifier.size(40.dp).align(Alignment.CenterHorizontally))
                }
            }
        }
        state.message?.let { TimedToast(it, "borrow.toast", store::messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = dimens.sectionSpacing)) }
    }
    FocusInto(first, key = state.candidates.size)
}
