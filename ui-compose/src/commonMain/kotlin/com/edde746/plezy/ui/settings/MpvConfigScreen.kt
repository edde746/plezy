package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.input.setTextAndPlaceCursorAtEnd
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
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
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.MpvConfigStore
import com.edde746.plezy.presentation.settings.SettingIcon
import com.edde746.plezy.presentation.settings.SettingTextRow
import com.edde746.plezy.presentation.settings.SettingsEvent
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.launch

/**
 * mpv.conf: the one document, as a monospace text area (touch, keyboard) or, on TV, one field per line with Add line;
 * the Linux note; then the presets card (Save as Preset..., each preset loading on a click, with Delete). Edits save
 * on their own, debounced by the store; leaving waits for the last one and stays, saying so, when it failed.
 * Harness names: `settings.mpv.<text|line.i|line.i.remove|addLine|savePreset|preset.i|preset.i.delete>`.
 */
@Composable
internal fun MpvConfigScreen(app: AppSession, route: Route) {
    val store = retainedStore(app, route, "settings.mpv", { app.settings.mpvConfig() }, MpvConfigStore::release) ?: return
    val state by store.state.collectAsState()
    val toasts = remember { SettingsToasts() }
    val scope = rememberCoroutineScope()
    var naming by remember { mutableStateOf(false) }
    var deleting by remember { mutableStateOf<String?>(null) }
    val addedLine = remember { mutableStateOf<Int?>(null) }
    LaunchedEffect(store) { store.messages.collect(toasts::show) }
    val leave: () -> Unit = {
        scope.launch {
            if (store.flush()) app.navigator.back() else toasts.show(SettingsEvent.Message(T.settings.saveFailed, error = true))
        }
    }
    SystemBackHandler(onBack = leave)
    val list = rememberLazyListState()
    SettingsPageFrame(T.mpvConfig.title, app, hub = false, toasts, onBack = leave, scrolled = { list.canScrollBackward }) {
        SettingsList(state = list) {
            if (state.lineEditor) {
                configLines(state.lines, store, addedLine)
            } else {
                item(key = "text") { ConfigText(state.text, store) }
            }
            state.linuxNote?.let { note -> item(key = "linuxNote") { SettingsNote(note) } }
            val presets = state.presets.mapIndexed { index, name ->
                SettingsItem("preset.$name") { shape ->
                    GroupRow(
                        name,
                        onClick = { store.loadPreset(name) },
                        modifier = Modifier.layoutProbe("settings.mpv.preset.$index"),
                        shape = shape,
                        icon = SettingIcon.FOLDER.vector,
                        trailing = {
                            PlezyIconButton(
                                SettingSymbols.Delete,
                                T.mpvConfig.deletePreset,
                                { deleting = name },
                                Modifier.layoutProbe("settings.mpv.preset.$index.delete"),
                                style = IconButtonStyle.PLAIN,
                            )
                        },
                    )
                }
            }
            val save = SettingsItem("savePreset") { shape ->
                GroupRow(
                    T.mpvConfig.saveAsPreset,
                    onClick = { naming = true },
                    modifier = Modifier.layoutProbe("settings.mpv.savePreset"),
                    shape = shape,
                    icon = SettingIcon.SAVE.vector,
                    enabled = state.canSavePreset,
                )
            }
            settingsGroup("presets", T.mpvConfig.presets, listOf(save) + presets)
            if (state.presets.isEmpty()) item(key = "noPresets") { SettingsNote(T.mpvConfig.noPresets) }
        }
    }
    if (naming) {
        TextOverlay(
            SettingTextRow("presetName", T.mpvConfig.presetName, null, "", T.mpvConfig.presetName, T.mpvConfig.presetNameHint, resetLabel = null),
            onSave = { name ->
                if (name.isNotBlank()) {
                    scope.launch {
                        if (store.flush()) store.savePreset(name.trim()) else toasts.show(SettingsEvent.Message(T.settings.saveFailed, error = true))
                    }
                }
                null
            },
            onReset = { "" },
            onDismiss = { naming = false },
        )
    }
    deleting?.let { name ->
        ConfirmDialog(
            T.mpvConfig.deletePreset,
            T.mpvConfig.confirmDeletePreset,
            T.mpvConfig.deletePreset,
            onConfirm = {
                deleting = null
                store.deletePreset(name)
            },
            onCancel = { deleting = null },
            probe = "settings.confirm",
            confirmProbe = "settings.confirm.ok",
        )
    }
}

/**
 * The TV line editor: a row per line, then Add line, which puts focus in the new line's field with its keyboard up.
 * [added] holds the line Add line asked for until the store has added it and it took focus.
 */
internal fun LazyListScope.configLines(lines: List<String>, store: MpvConfigStore, added: MutableState<Int?>) {
    items(lines.size, key = { "line.$it" }) { index ->
        ConfigLine(index, lines[index], store, focusNow = added.value == index, onFocused = { added.value = null })
    }
    item(key = "addLine") {
        val add = {
            added.value = lines.size
            store.addLine()
        }
        PlezyButton(T.mpvConfig.addLine, add, Modifier.layoutProbe("settings.mpv.addLine"), icon = PlezyIcons.Add)
    }
}

/**
 * The document as one monospace text area of at least 12 lines. Down on its last line moves focus on (to the presets).
 * A change from elsewhere (a preset loaded) replaces the text.
 */
@Composable
private fun ConfigText(text: String, store: MpvConfigStore) {
    val field = remember { TextFieldState(text) }
    val focusManager = LocalFocusManager.current
    LaunchedEffect(text) { if (field.text.toString() != text) field.setTextAndPlaceCursorAtEnd(text) }
    OnTextChange(field) { if (it != text) store.edit(it) }
    OutlinedTextField(
        state = field,
        lineLimits = TextFieldLineLimits.MultiLine(minHeightInLines = 12),
        placeholder = { Text(T.mpvConfig.configPlaceholder, fontFamily = FontFamily.Monospace, fontSize = 13.sp) },
        textStyle = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace, fontSize = 13.sp),
        keyboardOptions = KeyboardOptions(autoCorrectEnabled = false),
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp)
            .onPreviewKeyEvent { event ->
                val onLastLine = '\n' !in field.text.substring(field.selection.end.coerceAtMost(field.text.length))
                if (event.type == KeyEventType.KeyDown && event.key == Key.DirectionDown && onLastLine) focusManager.moveFocus(FocusDirection.Down) else false
            }
            .inViewAboveKeyboard()
            .layoutProbe("settings.mpv.text"),
    )
}

/**
 * One line of the TV line editor: its number in a 32 dp gutter, the line in a single-line field (the keyboard waits for
 * Select; a pasted text's lines become rows) and Remove line. [focusNow] (the row Add line added) takes focus with the
 * keyboard up, then calls [onFocused].
 */
@Composable
private fun ConfigLine(index: Int, line: String, store: MpvConfigStore, focusNow: Boolean, onFocused: () -> Unit) {
    val keyboard = rememberKeyboardOnSelect()
    val field = remember { TextFieldState(line) }
    val focus = remember { FocusRequester() }
    LaunchedEffect(focusNow) {
        if (!focusNow) return@LaunchedEffect
        keyboard.startTyping()
        focus.requestFocus()
        onFocused()
    }
    LaunchedEffect(line) { if (field.text.toString() != line) field.setTextAndPlaceCursorAtEnd(line) }
    OnTextChange(field) { if (it != line) store.editLine(index, it) }
    Row(Modifier.fillMaxWidth().padding(vertical = 2.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("${index + 1}", Modifier.width(32.dp), style = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace), color = PlezyColors.TextMuted, textAlign = TextAlign.End)
        OutlinedTextField(
            state = field,
            lineLimits = TextFieldLineLimits.SingleLine,
            readOnly = keyboard.readOnly,
            placeholder = { Text(T.mpvConfig.lineHint, fontFamily = FontFamily.Monospace) },
            textStyle = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace),
            keyboardOptions = KeyboardOptions(autoCorrectEnabled = false),
            modifier = Modifier.weight(1f).focusRequester(focus).then(keyboard.modifier).remoteLeavesField(field).inViewAboveKeyboard().layoutProbe("settings.mpv.line.$index"),
        )
        PlezyIconButton(PlezyIcons.Close, T.mpvConfig.removeLine, { store.removeLine(index) }, Modifier.layoutProbe("settings.mpv.line.$index.remove"), style = IconButtonStyle.PLAIN)
    }
}
