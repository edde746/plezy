package com.edde746.plezy.ui.livetv

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.ui.image.LogoRecolour
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import com.edde746.plezy.ui.focus.focusReach
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.input.rememberTextFieldState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.presentation.livetv.GuideSearchUiState
import com.edde746.plezy.presentation.livetv.LiveTvStore
import com.edde746.plezy.presentation.livetv.ReorderFavoritesUiState
import com.edde746.plezy.presentation.livetv.details.ProgramActionKind
import com.edde746.plezy.presentation.livetv.details.ProgramDetailsStore
import com.edde746.plezy.presentation.livetv.recordings.RecordOptionsStore
import com.edde746.plezy.presentation.livetv.recordings.RecordSettingRow
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.cast.CastButton
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ChoiceMenu
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.TextAndTrailing
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.settings.DragHandleIcon
import com.edde746.plezy.ui.settings.RowText
import com.edde746.plezy.ui.components.rememberReorderState
import com.edde746.plezy.ui.components.reorderHandle
import com.edde746.plezy.ui.components.reorderItem
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * A program's details ([ProgramDetailsStore]): its poster beside the title with its NEW and LIVE pills, the channel and
 * times, the summary (four lines until tapped), then its actions (Play or Watch channel, Record or Manage recording).
 * Over it the Record Options sheet and the delete-rule question. Harness names `liveTv.details`,
 * `liveTv.details.<play|watch|record|manage>`.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun ProgramDetailsSheet(store: ProgramDetailsStore, onDismiss: () -> Unit) {
    val state by store.state.collectAsState()
    // The first action takes focus as the sheet opens: the summary is no stop for a remote.
    val firstAction = remember { FocusRequester() }
    PlezySheet(onDismiss = onDismiss, probe = "liveTv.details", label = state.title, initialFocus = firstAction) {
        // At the sheet's own edge, as every sheet's title and an item menu's rows are.
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            state.poster?.let {
                RemoteImage(it, contentDescription = null, Modifier.width(80.dp).height(120.dp).clip(MaterialTheme.shapes.small), blank = PlezyColors.SurfaceHigh)
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp), itemVerticalAlignment = Alignment.CenterVertically) {
                    Text(state.title, style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold))
                    state.premiereBadge?.let { StatusPill(it, MaterialTheme.colorScheme.primary) }
                    state.liveBadge?.let { StatusPill(it, PlezyColors.Live) }
                    state.endedBadge?.let { StatusPill(it, PlezyColors.TextMuted) }
                }
                if (state.info.isNotEmpty()) Text(state.info, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
                state.summary?.let { summary ->
                    var expanded by remember(summary) { mutableStateOf(false) }
                    Text(
                        summary,
                        Modifier.pointerInput(Unit) { detectTapGestures { expanded = !expanded } },
                        style = MaterialTheme.typography.bodyLarge,
                        maxLines = if (expanded) Int.MAX_VALUE else 4,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
        if (state.actions.isNotEmpty()) {
            FlowRow(
                Modifier.fillMaxWidth().padding(vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                val castAfter = state.actions.indexOfFirst { it.kind == ProgramActionKind.PLAY || it.kind == ProgramActionKind.WATCH_CHANNEL }
                state.actions.forEachIndexed { index, action ->
                    val (icon, probe) = when (action.kind) {
                        ProgramActionKind.PLAY -> PlezyIcons.PlayArrow to "play"
                        ProgramActionKind.WATCH_CHANNEL -> PlezyIcons.LiveTv to "watch"
                        ProgramActionKind.RECORD -> PlezyIcons.Record to "record"
                        ProgramActionKind.MANAGE -> PlezyIcons.Record to "manage"
                    }
                    PlezyButton(
                        action.label,
                        { store.act(action.kind) },
                        Modifier.then(if (index == 0) Modifier.focusRequester(firstAction) else Modifier).layoutProbe("liveTv.details.$probe"),
                        style = if (action.filled) ButtonStyle.PRIMARY else ButtonStyle.SECONDARY,
                        icon = icon,
                    )
                    // The cast button beside what plays.
                    if (index == castAfter) CastButton()
                }
            }
        }
    }
    state.recordOptions?.let { RecordOptionsSheet(it) }
    state.confirmation?.let {
        ConfirmDialog(it.title, it.message, it.confirmText, store::confirm, store::dismissConfirmation, "liveTv.details.confirm")
    }
}

/**
 * Record Options or Edit rule ([RecordOptionsStore]): the template's entries as chips when there are several, the
 * library it saves to, one row per setting (a switch, a picker or a field), then Cancel and Save (disabled while
 * saving). Back cancels. Harness names `liveTv.recordOptions`, `.entry.<i>`, `.target`, `.setting.<id>`, `.cancel`,
 * `.save`.
 */
@Composable
internal fun RecordOptionsSheet(store: RecordOptionsStore) {
    val state by store.state.collectAsState()
    PlezySheet(onDismiss = store::cancel, title = state.title, probe = "liveTv.recordOptions") {
        Text(state.subtitle, Modifier.padding(horizontal = 8.dp), style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(vertical = LocalPlezyDimens.current.focusReach),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (state.entries.size > 1) {
                Row(Modifier.padding(horizontal = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    state.entries.forEachIndexed { index, entry ->
                        PlezyChip(entry.title, entry.selected, { store.selectEntry(index) }, Modifier.layoutProbe("liveTv.recordOptions.entry.$index"), enabled = !state.saving, tab = true)
                    }
                }
            }
            val rows = (if (state.target != null) 1 else 0) + state.settings.size
            if (rows > 0) {
                RowGroup {
                    var at = 0
                    state.target?.let { target ->
                        val shape = groupShape(at++, rows)
                        if (target.options.isEmpty()) {
                            GroupRow(target.label, onClick = null, shape = shape, value = target.value)
                        } else {
                            Picker(
                                title = target.label,
                                value = target.value,
                                choices = target.options.map { MenuChoice(it.title, it.selected) },
                                onPick = { store.selectTarget(target.options[it].sectionId) },
                                probe = "liveTv.recordOptions.target",
                                shape = shape,
                            )
                        }
                    }
                    for (setting in state.settings) {
                        SettingRow(setting, store, groupShape(at++, rows))
                    }
                }
            }
            state.emptyText?.let { Text(it, Modifier.padding(horizontal = 8.dp), style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted) }
        }
        val save = remember { FocusRequester() }
        OverlayActions(Modifier.padding(top = 8.dp), primary = save) {
            PlezyButton(state.cancelLabel, store::cancel, Modifier.layoutProbe("liveTv.recordOptions.cancel"), style = ButtonStyle.TEXT, enabled = !state.saving)
            PlezyButton(
                state.saveLabel,
                store::save,
                Modifier.focusRequester(save).layoutProbe("liveTv.recordOptions.save"),
                style = ButtonStyle.PRIMARY,
                enabled = !state.saving,
            )
        }
    }
}

@Composable
private fun SettingRow(setting: RecordSettingRow, store: RecordOptionsStore, shape: androidx.compose.ui.graphics.Shape) {
    val probe = "liveTv.recordOptions.setting.${setting.id}"
    when (setting) {
        is RecordSettingRow.Toggle -> PlezyToggleSurface(
            setting.checked,
            { store.setToggle(setting.id, it) },
            Modifier.fillMaxWidth().layoutProbe(probe),
            shape = shape,
        ) {
            TextAndTrailing(
                text = { RowText(setting.label, setting.summary) },
                trailing = { RowSwitch(setting.checked) },
                modifier = Modifier.heightIn(min = 56.dp).padding(start = 16.dp, end = 12.dp, top = 10.dp, bottom = 10.dp),
            )
        }
        is RecordSettingRow.Choice -> Picker(
            title = setting.label,
            value = setting.value,
            choices = setting.options.map { MenuChoice(it.label, it.selected) },
            onPick = { store.setChoice(setting.id, setting.options[it].value) },
            probe = probe,
            shape = shape,
            subtitle = setting.summary,
        )
        is RecordSettingRow.Field -> Column(
            Modifier.fillMaxWidth().background(PlezyColors.SurfaceHigh, shape).padding(horizontal = 16.dp, vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            RowText(setting.label, setting.summary)
            val text = remember(setting.id) { TextFieldState(setting.text) }
            OnTextChange(text) { store.setText(setting.id, it) }
            // The store refuses what a number can't hold: the field shows what it kept.
            LaunchedEffect(setting.text) { if (text.text.toString() != setting.text) text.edit { replace(0, length, setting.text) } }
            LiveTvTextField(
                text,
                hint = null,
                modifier = Modifier.layoutProbe(probe),
                keyboardType = if (setting.numeric) KeyboardType.Number else KeyboardType.Text,
                imeAction = ImeAction.Done,
            )
        }
    }
}

/** A row showing a choice's [value], opening its options ([ChoiceMenu]). */
@Composable
private fun Picker(title: String, value: String, choices: List<MenuChoice>, onPick: (Int) -> Unit, probe: String, shape: androidx.compose.ui.graphics.Shape, subtitle: String? = null) {
    var open by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxWidth()) {
        GroupRow(
            title,
            onClick = { open = true },
            modifier = Modifier.layoutProbe(probe),
            shape = shape,
            subtitle = subtitle,
            value = value,
            trailing = { Icon(PlezyIcons.ArrowDropDown, contentDescription = null, tint = PlezyColors.MutedContent) },
        )
        ChoiceMenu(expanded = open, onDismiss = { open = false }, title = title, choices = choices, onPick = onPick, probe = probe)
    }
}

/**
 * A filled single-line field in the app's input look (no border), [hint] while empty, a leading [icon]: Select starts
 * typing on TV, a remote can always leave it. [onSubmit] runs on the keyboard's action and a hardware Enter.
 */
@Composable
internal fun LiveTvTextField(
    state: TextFieldState,
    hint: String?,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    keyboardType: KeyboardType = KeyboardType.Text,
    imeAction: ImeAction = ImeAction.Search,
    onSubmit: () -> Unit = {},
) {
    val keyboard = rememberKeyboardOnSelect()
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    val text = PlezyColors.Text
    BasicTextField(
        state = state,
        modifier = modifier
            .fillMaxWidth()
            .then(keyboard.modifier)
            .onPreviewKeyEvent { event ->
                if (event.type != KeyEventType.KeyDown || (event.key != Key.Enter && event.key != Key.NumPadEnter) || keyboard.readOnly) return@onPreviewKeyEvent false
                onSubmit()
                true
            }
            .remoteLeavesField(state)
            .inViewAboveKeyboard(),
        readOnly = keyboard.readOnly,
        textStyle = MaterialTheme.typography.bodyLarge.copy(color = text),
        cursorBrush = SolidColor(PlezyColors.Primary),
        interactionSource = interactions,
        lineLimits = TextFieldLineLimits.SingleLine,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType, imeAction = imeAction),
        onKeyboardAction = { onSubmit() },
        decorator = { field ->
            Row(
                Modifier
                    .background(
                        if (focused) PlezyColors.SurfaceHighest else PlezyColors.SurfaceHigh,
                        MaterialTheme.shapes.medium,
                    )
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (icon != null) {
                    Icon(icon, contentDescription = null, Modifier.size(20.dp), tint = PlezyColors.TextMuted)
                    Spacer(Modifier.width(12.dp))
                }
                Box(Modifier.weight(1f)) {
                    if (hint != null && state.text.isEmpty()) Text(hint, style = MaterialTheme.typography.bodyLarge, color = PlezyColors.TextMuted, maxLines = 1)
                    field()
                }
            }
        },
    )
}

/**
 * The guide search: the field, then the matching channels and (two characters typed) programs, each a row that closes
 * the search and shows it in the guide. [firstResult] takes focus once a query is submitted. Harness names
 * `liveTv.search`, `liveTv.search.field`, `liveTv.search.channel.<i>`, `liveTv.search.program.<i>`.
 *
 * @param logo a channel's logo.
 */
@Composable
internal fun GuideSearchSheet(search: GuideSearchUiState, store: LiveTvStore, firstResult: FocusRequester, logo: (serverId: String?, thumb: String?) -> Artwork?) {
    val field = remember { FocusRequester() }
    val text = rememberTextFieldState(search.query)
    OnTextChange(text) { store.setSearchQuery(it) }
    PlezySheet(onDismiss = store::closeSearch, title = search.title, initialFocus = field, probe = "liveTv.search") {
        LiveTvTextField(
            text,
            hint = search.hint,
            modifier = Modifier.padding(horizontal = 8.dp).focusRequester(field).layoutProbe("liveTv.search.field"),
            icon = PlezyIcons.Search,
            onSubmit = store::submitSearch,
        )
        Spacer(Modifier.height(8.dp))
        LazyColumn(
            Modifier.weight(1f, fill = false).heightIn(min = 120.dp),
            contentPadding = PaddingValues(vertical = LocalPlezyDimens.current.focusReach),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            if (search.channels.isNotEmpty()) {
                item(key = "channels") { SectionLabel(search.channelsLabel) }
                itemsIndexed(search.channels, key = { _, row -> "channel:${row.channel.serverId}:${row.channel.key}" }) { index, row ->
                    ResultRow(
                        title = row.title,
                        subtitle = row.subtitle,
                        logo = logo(row.channel.serverId, row.channel.thumb),
                        onClick = { store.selectSearchChannel(row.channel) },
                        modifier = Modifier.then(if (index == 0) Modifier.focusRequester(firstResult) else Modifier).layoutProbe("liveTv.search.channel.$index"),
                    )
                }
            }
            if (search.showsPrograms) {
                item(key = "programs") { SectionLabel(search.programsLabel) }
                if (search.programsLoading) {
                    item(key = "programsLoading") {
                        Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 3.dp) }
                    }
                }
                itemsIndexed(search.programs, key = { index, _ -> "program:$index" }) { index, row ->
                    ResultRow(
                        title = row.title,
                        subtitle = row.subtitle,
                        logo = null,
                        onClick = { store.selectSearchProgram(row.channel, row.program) },
                        modifier = Modifier
                            .then(if (index == 0 && search.channels.isEmpty()) Modifier.focusRequester(firstResult) else Modifier)
                            .layoutProbe("liveTv.search.program.$index"),
                    )
                }
            }
            search.noResults?.let { message ->
                item(key = "none") {
                    Text(
                        message,
                        Modifier.fillMaxWidth().padding(24.dp),
                        style = MaterialTheme.typography.bodyLarge,
                        color = PlezyColors.TextMuted,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text,
        Modifier.padding(start = 16.dp, top = 12.dp, bottom = 4.dp),
        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

/** A search result: the channel's logo (or the Live TV icon), its title and subtitle; focus fills it. */
@Composable
private fun ResultRow(title: String, subtitle: String?, logo: Artwork?, onClick: () -> Unit, modifier: Modifier) {
    PlezySurface(onClick = onClick, modifier = modifier.fillMaxWidth(), color = androidx.compose.ui.graphics.Color.Transparent, grows = false) {
        Row(Modifier.padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            ChannelLogo(logo, Modifier.size(LOGO_SIZE.dp))
            RowText(title, subtitle, Modifier.weight(1f))
        }
    }
}

/** A channel's logo fitted in [modifier]'s box, a light mark recoloured on a light theme; without one, its placeholder. */
@Composable
internal fun ChannelLogo(logo: Artwork?, modifier: Modifier) {
    RemoteImage(
        logo,
        contentDescription = null,
        modifier.clip(MaterialTheme.shapes.small),
        contentScale = ContentScale.Fit,
        logo = LogoRecolour.CELL,
        error = { ArtworkPlaceholder(PlaceholderKind.CHANNEL) },
    )
}

/** A search row's and a favourite's logo, in dp. */
internal const val LOGO_SIZE = 40

/**
 * Reorder favourites: the favourites in order, each with its drag handle (mouse, touch), logo, name and number, and a
 * remove button; removing the last closes it. With a remote or the keyboard, Select picks a row up, Up and Down move it,
 * Select (or Back) puts it down. Harness names `liveTv.reorder`, `liveTv.reorder.<i>`, `liveTv.reorder.<i>.remove`.
 */
@Composable
internal fun ReorderFavoritesSheet(reorder: ReorderFavoritesUiState, store: LiveTvStore, logo: (serverId: String?, thumb: String?) -> Artwork?) {
    val drag = rememberReorderState(2.dp)
    var moving by remember { mutableStateOf<String?>(null) }
    val requesters = remember { HashMap<String, FocusRequester>() }
    val focusManager = LocalFocusManager.current
    PlezySheet(
        onDismiss = store::closeReorder,
        title = reorder.title,
        probe = "liveTv.reorder",
        onBack = { if (moving != null) moving = null else store.closeReorder() },
    ) {
        LazyColumn(
            Modifier.weight(1f, fill = false),
            contentPadding = PaddingValues(vertical = LocalPlezyDimens.current.focusReach),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            itemsIndexed(reorder.rows, key = { _, row -> row.key }) { index, row ->
                val requester = remember(row.key) { requesters.getOrPut(row.key) { FocusRequester() } }
                val isMoving = moving == row.key
                Row(
                    Modifier.fillMaxWidth().reorderItem(drag, row.key, index).layoutProbe("liveTv.reorder.$index", reportsFocus = false),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    DragHandleIcon(
                        T.liveTv.reorderFavorites,
                        Modifier.reorderHandle(drag, row.key, index, reorder.rows.size) { key, to ->
                            reorder.rows.indexOfFirst { it.key == key }.takeIf { it >= 0 }?.let { store.moveFavorite(it, to) }
                        },
                    )
                    PlezySurface(
                        onClick = { moving = if (isMoving) null else row.key },
                        modifier = Modifier
                            .weight(1f)
                            .focusRequester(requester)
                            .onFocusChanged { if (!it.isFocused && moving == row.key) moving = null }
                            .onKeyEvent { event ->
                                if (!isMoving || event.type != KeyEventType.KeyDown) return@onKeyEvent false
                                val to = when (event.key) {
                                    Key.DirectionUp -> index - 1
                                    Key.DirectionDown -> index + 1
                                    else -> return@onKeyEvent false
                                }
                                if (to in reorder.rows.indices) store.moveFavorite(index, to)
                                true
                            },
                        color = if (isMoving) PlezyColors.SurfaceHighest else androidx.compose.ui.graphics.Color.Transparent,
                        grows = false,
                    ) {
                        Row(Modifier.padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            ChannelLogo(logo(row.serverId, row.thumb), Modifier.size(LOGO_SIZE.dp))
                            RowText(row.title, row.number, Modifier.weight(1f))
                            if (isMoving) Icon(PlezyIcons.SwapVert, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        }
                    }
                    PlezyIconButton(
                        PlezyIcons.Close,
                        T.common.delete,
                        {
                            if (reorder.rows.size > 1) focusManager.moveFocus(if (index == reorder.rows.lastIndex) FocusDirection.Up else FocusDirection.Down)
                            store.removeFavorite(index)
                        },
                        Modifier.layoutProbe("liveTv.reorder.$index.remove"),
                        style = IconButtonStyle.PLAIN,
                    )
                }
            }
        }
    }
    // A moved row keeps focus at its new place.
    LaunchedEffect(reorder.rows) { moving?.let { requesters[it]?.requestFocus() } }
}
