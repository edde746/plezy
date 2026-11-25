package com.edde746.plezy.ui.settings

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.input.setTextAndPlaceCursorAtEnd
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.CustomThemeEditorPage
import com.edde746.plezy.presentation.settings.CustomThemeEditorUiState
import com.edde746.plezy.presentation.settings.SettingIcon
import com.edde746.plezy.presentation.settings.SettingsPageId
import com.edde746.plezy.presentation.settings.ThemePickerEvent
import com.edde746.plezy.presentation.settings.ThemePickerPage
import com.edde746.plezy.presentation.settings.ThemeRowUi
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.ChoiceMenu
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.contentColumn
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PosterCard
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyTheme

/**
 * The theme picker: the themes in their groups (Built-in; Presets and Custom where the Supporter perks are offered),
 * each a row with its swatch where a row's icon sits, its note, a lock on a locked perk and a check on the theme that
 * paints; Custom, which opens its editor, ends in a chevron. A pick applies at once; a locked one opens the Supporter
 * sheet. The theme that paints is focused in keyboard mode. Harness names: `settings.theme.<mode>`.
 */
@Composable
internal fun ThemePickerScreen(app: AppSession, route: Route) {
    val store = retainedStore(app, route, "settings.theme", { app.settings.themePicker() }, ThemePickerPage::release) ?: return
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    LaunchedEffect(store) {
        store.events.collect { event ->
            when (event) {
                ThemePickerEvent.OpenEditor -> app.navigator.navigate(Route.SettingsPage(SettingsPageId.CUSTOM_THEME))
                ThemePickerEvent.OpenSupporter -> openSupporter { store.supporterClosed(it) }
            }
        }
    }
    val list = rememberLazyListState()
    SettingsPageFrame(T.settings.theme, app, hub = false, toasts = remember { SettingsToasts() }, scrolled = { list.canScrollBackward }) {
        SettingsList(state = list) {
            for (group in state.groups) {
                val rows = group.rows.map { row ->
                    SettingsItem("theme.${row.mode.name}") { shape -> ThemeRow(row, shape, memory) { store.choose(row.mode) } }
                }
                settingsGroup(group.id, group.header, rows)
            }
        }
    }
    RestoreFocus(memory, ready = state.groups.isNotEmpty(), fallback = state.focusedMode.name)
}

/**
 * One theme: its swatch in the icon's place, name and note, its value beside them (Custom: "Not created"), a lock when
 * it is a locked perk, a check when it paints; Custom, which opens its editor, a chevron.
 */
@Composable
private fun ThemeRow(row: ThemeRowUi, shape: androidx.compose.ui.graphics.Shape, memory: FocusMemory, onClick: () -> Unit) {
    GroupRow(
        row.label,
        onClick = onClick,
        modifier = Modifier.rememberFocus(memory, row.mode.name).layoutProbe("settings.theme.${row.mode.name.lowercase()}"),
        shape = shape,
        subtitle = row.note,
        value = row.value,
        leading = { ThemeSwatch(row.palette, row.splitPalette) },
        trailing = {
            if (row.locked) Icon(PlezyIcons.Lock, contentDescription = T.themeEditor.locked, Modifier.size(20.dp), tint = PlezyColors.MutedContent)
            if (row.selected) Icon(PlezyIcons.Check, contentDescription = null, Modifier.size(22.dp))
            if (row.mode == ThemeMode.CUSTOM && !row.locked) Chevron()
        },
    )
}

/**
 * A theme's swatch, 28 dp: its background with its accent in it; with [split] the left half [palette]'s and the right
 * half [split]'s (System: light and dark); without a palette an empty slot with "+" (Custom not created yet).
 */
@Composable
private fun ThemeSwatch(palette: Palette?, split: Palette?) {
    if (palette == null) {
        Box(Modifier.size(28.dp).border(1.5.dp, LocalContentColor.current.copy(alpha = 0.4f), CircleShape), contentAlignment = Alignment.Center) {
            Icon(PlezyIcons.Add, contentDescription = null, Modifier.size(16.dp), tint = PlezyColors.MutedContent)
        }
        return
    }
    Row(Modifier.size(28.dp).clip(CircleShape).border(1.dp, PlezyColors.Hairline, CircleShape)) {
        SwatchHalf(palette, Modifier.weight(1f))
        if (split != null) SwatchHalf(split, Modifier.weight(1f))
    }
}

@Composable
private fun SwatchHalf(palette: Palette, modifier: Modifier) {
    Box(modifier.fillMaxHeight().background(Color(palette.bg)), contentAlignment = Alignment.Center) {
        Box(Modifier.size(10.dp).background(Color(palette.accent), CircleShape))
    }
}

/**
 * The custom theme editor, a pushed section: a live preview of the draft drawn by the app's own card, button and switch
 * in the draft's colours, "Start from" another theme, the six colour slots, and for the selected one its code, hue,
 * saturation, brightness and opacity sliders and "From other themes"; contrast warnings under it (they never block
 * Save). Reset (back to how the editor opened), Cancel and Save at the foot; Save stores the palette, makes Custom the
 * theme and closes. Leaving with unsaved changes (Cancel, back) asks first.
 * Harness names: `settings.custom.<preview|startFrom|slot.i|hex|swatches|reset|cancel|save>`.
 */
@Composable
internal fun CustomThemeEditorScreen(app: AppSession, route: Route) {
    val systemDark = isSystemInDarkTheme()
    val store = retainedStore(app, route, "settings.customTheme", { app.settings.customThemeEditor(systemDark) }, CustomThemeEditorPage::release) ?: return
    val state by store.state.collectAsState()
    val toasts = remember { SettingsToasts() }
    var discard by remember { mutableStateOf(false) }
    val leave: () -> Unit = {
        if (state.dirty) discard = true else app.navigator.back()
    }
    LaunchedEffect(store) { store.messages.collect(toasts::show) }
    LaunchedEffect(state.saved) { if (state.saved) app.navigator.back() }
    SystemBackHandler(enabled = state.dirty && !state.saved) { discard = true }
    val list = rememberLazyListState()
    SettingsPageFrame(T.themeEditor.title, app, hub = false, toasts, onBack = leave, scrolled = { list.canScrollBackward }) {
        SettingsList(Modifier.weight(1f), state = list) {
            item(key = "preview") { ThemePreview(state.draft) }
            settingsGroup(
                "start",
                null,
                listOf(
                    SettingsItem("startFrom") { shape ->
                        MenuRow(
                            T.themeEditor.startFrom,
                            T.themeEditor.startFromDescription,
                            state.startFromOptions.map { MenuChoice(it.label, it.selected) },
                            { store.startFrom(state.startFromOptions[it].id) },
                            shape,
                            "settings.custom.startFrom",
                        )
                    },
                ),
            )
            settingsGroup(
                "slots",
                T.themeEditor.colors,
                state.slots.mapIndexed { index, slot ->
                    SettingsItem("slot.${slot.id}") { shape ->
                        GroupRow(
                            slot.label,
                            onClick = { store.selectSlot(index) },
                            modifier = Modifier.layoutProbe("settings.custom.slot.$index"),
                            shape = shape,
                            value = slot.hex,
                            selected = index == state.selectedSlot,
                            leading = { ColorDot(parseHex(slot.hex), 24) },
                        )
                    }
                },
            )
            item(key = "editor") { SlotEditor(state, store) }
            items(state.warnings.size, key = { "warning.$it" }) { NoteLine(state.warnings[it], SettingsIcons.Warning, Modifier.padding(horizontal = 16.dp)) }
        }
        // The foot's buttons keep to the list's edges (on TV the overscan-safe ones).
        Row(
            Modifier.contentColumn().padding(horizontal = LocalPlezyDimens.current.screenPadding, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.End),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PlezyButton(T.common.reset, store::reset, Modifier.layoutProbe("settings.custom.reset"), style = ButtonStyle.TEXT, enabled = state.dirty && !state.saving)
            Spacer(Modifier.weight(1f))
            PlezyButton(T.common.cancel, leave, Modifier.layoutProbe("settings.custom.cancel"), style = ButtonStyle.TEXT, enabled = !state.saving)
            PlezyButton(T.common.save, store::save, Modifier.layoutProbe("settings.custom.save"), style = ButtonStyle.PRIMARY, enabled = !state.saving)
        }
    }
    if (discard) {
        ConfirmDialog(
            T.themeEditor.discardTitle,
            T.themeEditor.discardMessage,
            T.themeEditor.discard,
            onConfirm = {
                discard = false
                app.navigator.back()
            },
            onCancel = { discard = false },
            probe = "settings.confirm",
            confirmProbe = "settings.confirm.ok",
        )
    }
}

/** A row opening [choices] in a [ChoiceMenu] at it ([probe]); a pick calls [onPick] with its index. */
@Composable
private fun MenuRow(title: String, subtitle: String?, choices: List<MenuChoice>, onPick: (Int) -> Unit, shape: androidx.compose.ui.graphics.Shape, probe: String) {
    var open by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxWidth()) {
        GroupRow(
            title,
            onClick = { open = true },
            modifier = Modifier.layoutProbe(probe),
            shape = shape,
            subtitle = subtitle,
            icon = SettingIcon.PALETTE.vector,
            trailing = { Icon(PlezyIcons.ArrowDropDown, contentDescription = null, tint = PlezyColors.MutedContent) },
        )
        ChoiceMenu(expanded = open, onDismiss = { open = false }, title = title, choices = choices, onPick = onPick, probe = probe)
    }
}

/**
 * The selected slot's editor: its code (`#RRGGBB` or `#AARRGGBB`; an invalid one shows the hint as the error, Enter
 * or Done normalises it), the slider group ([ColorSliders]), and "From other themes": the other themes' colours for
 * this slot in a menu.
 */
@Composable
private fun SlotEditor(state: CustomThemeEditorUiState, store: CustomThemeEditorPage) {
    val keyboard = rememberKeyboardOnSelect()
    val field = remember { TextFieldState(state.hexText) }
    // The store's text replaces the field's when it changes on its own (another slot, a slider, a swatch).
    LaunchedEffect(state.hexText) { if (field.text.toString() != state.hexText) field.setTextAndPlaceCursorAtEnd(state.hexText) }
    OnTextChange(field) { if (it != state.hexText) store.editHex(it) }
    Column(Modifier.fillMaxWidth().padding(top = 12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        OutlinedTextField(
            state = field,
            lineLimits = TextFieldLineLimits.SingleLine,
            readOnly = keyboard.readOnly,
            label = { Text(state.slots.getOrNull(state.selectedSlot)?.label.orEmpty()) },
            isError = state.hexInvalid,
            supportingText = { Text(T.themeEditor.hexHint) },
            textStyle = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.Monospace),
            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Characters, autoCorrectEnabled = false, imeAction = ImeAction.Done),
            onKeyboardAction = { store.submitHex() },
            modifier = Modifier.fillMaxWidth().then(keyboard.modifier).remoteLeavesField(field).inViewAboveKeyboard().layoutProbe("settings.custom.hex"),
        )
        ColorSliders(Hsv(state.hue, state.saturation, state.brightness, state.opacity), onChange = { store.setHsv(it.hue, it.saturation, it.value, it.alpha) }, opacity = true)
        if (state.quickSwatches.isNotEmpty()) {
            MenuRow(
                T.themeEditor.fromOtherThemes,
                null,
                state.quickSwatches.map { hex ->
                    MenuChoice(hex, hex.equals(state.hexText, ignoreCase = true), leading = { ColorDot(parseHex(hex), 20) })
                },
                { store.pickSwatch(state.quickSwatches[it]) },
                MaterialTheme.shapes.large,
                "settings.custom.swatches",
            )
        }
    }
}

/**
 * The draft theme at work, in the app's own components painted in the draft's colours ([PlezyTheme]): two episode
 * cards ([PosterCard], one with its progress), a Play button, a row's switch and a line of secondary text.
 */
@Composable
private fun ThemePreview(palette: Palette) {
    PlezyTheme(palette) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(top = 8.dp)
                .clip(MaterialTheme.shapes.large)
                .background(MaterialTheme.colorScheme.background)
                .border(1.dp, PlezyColors.Hairline, MaterialTheme.shapes.large)
                .padding(16.dp)
                .layoutProbe("settings.custom.preview", reportsFocus = false),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(T.themeEditor.preview, style = MaterialTheme.typography.titleSmall, color = PlezyColors.TextMuted)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                for (number in 1..2) {
                    val card = MediaCardUi(
                        id = "preview.$number",
                        title = T.themeEditor.previewCardTitle("$number"),
                        caption = T.themeEditor.previewCardSubtitle("${number * 12}"),
                        shape = CardShape.WIDE,
                        placeholder = PlaceholderKind.EPISODE,
                        artwork = null,
                        progress = if (number == 1) 0.6 else 0.25,
                    )
                    PosterCard(card, onClick = null, width = 150.dp)
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                PlezyButton(T.common.play, {}, style = ButtonStyle.PRIMARY, icon = PlezyIcons.PlayArrow, grows = false)
                Spacer(Modifier.weight(1f))
                Text(T.themeEditor.previewSwitch, style = MaterialTheme.typography.bodyMedium)
                RowSwitch(checked = true)
            }
            Text(T.themeEditor.previewMutedText, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
        }
    }
}
