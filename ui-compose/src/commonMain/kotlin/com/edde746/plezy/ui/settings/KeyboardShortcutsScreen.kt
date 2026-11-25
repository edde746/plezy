package com.edde746.plezy.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isAltPressed
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isMetaPressed
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.KeyboardShortcutsPage
import com.edde746.plezy.presentation.settings.ShortcutRecorder
import com.edde746.plezy.presentation.settings.ShortcutResult
import com.edde746.plezy.presentation.settings.ShortcutRowUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.InlineError
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * Keyboard shortcuts (desktop): one row per player action in default order, its id under its name and its keys in a
 * chip; a click opens the recorder. Reset at the top asks first, then puts back every default.
 * Harness names: `settings.keys.<reset|row.<action>>`.
 */
@Composable
internal fun KeyboardShortcutsScreen(app: AppSession, route: Route) {
    val store = retainedStore(app, route, "settings.keys", { app.settings.keyboardShortcuts() }, KeyboardShortcutsPage::release) ?: return
    val state by store.state.collectAsState()
    val toasts = remember { SettingsToasts() }
    val memory = rememberFocusMemory()
    var recording by remember { mutableStateOf<ShortcutRowUi?>(null) }
    var resetting by remember { mutableStateOf(false) }
    LaunchedEffect(store) { store.messages.collect(toasts::show) }
    val list = rememberLazyListState()
    SettingsPageFrame(T.settings.keyboardShortcuts, app, hub = false, toasts, scrolled = { list.canScrollBackward }, actions = {
        PlezyButton(T.common.reset, { resetting = true }, Modifier.layoutProbe("settings.keys.reset"), style = ButtonStyle.TEXT)
    }) {
        SettingsList(state = list) {
            settingsGroup(
                "shortcuts",
                null,
                state.rows.map { row ->
                    SettingsItem(row.actionId) { shape ->
                        GroupRow(
                            row.title,
                            onClick = { recording = row },
                            modifier = Modifier.rememberFocus(memory, row.actionId).layoutProbe("settings.keys.row.${row.actionId}"),
                            shape = shape,
                            subtitle = row.actionId,
                            trailing = { KeyChip(row.keys, row.unset) },
                        )
                    }
                },
            )
        }
    }
    RestoreFocus(memory, ready = state.rows.isNotEmpty(), fallback = state.rows.firstOrNull()?.actionId)
    recording?.let { row ->
        val recorder = remember(row.actionId) { store.recorder(row.actionId) }
        ShortcutRecorderDialog(row.title, recorder, onDismiss = { recording = null })
    }
    if (resetting) {
        ConfirmDialog(
            T.settings.resetToDefault,
            T.settings.resetShortcutsConfirm,
            T.common.reset,
            onConfirm = {
                resetting = false
                store.resetAll()
            },
            onCancel = { resetting = false },
            probe = "settings.confirm",
            confirmProbe = "settings.confirm.ok",
        )
    }
}

/** A hotkey as it reads ("Ctrl + →"), monospace in a bordered chip; "No shortcut set" dimmed when [unset]. */
@Composable
private fun KeyChip(keys: String, unset: Boolean) {
    Box(
        Modifier.border(1.dp, PlezyColors.Hairline, MaterialTheme.shapes.small).padding(horizontal = 12.dp, vertical = 6.dp),
    ) {
        Text(
            keys,
            style = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace),
            color = LocalContentColor.current.copy(alpha = if (unset) 0.6f else 1f),
        )
    }
}

/**
 * The recorder: "Press the shortcut now" over the shortcut it would save, in a box that takes focus and the next key
 * pressed with its modifiers (a modifier alone waits for the key; Esc closes it, Tab moves on). The key, or Clear
 * shortcut, is only [recorder]'s edit until Save: saved, or taken by another action ("already assigned"), closes the
 * dialog; a failure ("Error") keeps it open to retry. Cancel discards the edit. Harness names:
 * `settings.keys.<capture|clear|save|error>`.
 */
@Composable
internal fun ShortcutRecorderDialog(title: String, recorder: ShortcutRecorder, onDismiss: () -> Unit) {
    val capture = remember { FocusRequester() }
    val scope = rememberCoroutineScope()
    val state by recorder.state.collectAsState()
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    val dismiss = { if (!state.saving) onDismiss() }
    ModalOverlay(T.hotkeys.setShortcutFor(title), dismiss, initialFocus = capture) {
        Box(
            Modifier
                .fillMaxWidth()
                .heightIn(min = 88.dp)
                .focusRequester(capture)
                .onPreviewKeyEvent { event ->
                    if (event.type != KeyEventType.KeyDown || event.key == Key.Escape || event.key == Key.Tab || event.key in ModifierKeys) return@onPreviewKeyEvent false
                    val hid = hidUsage(event.key) ?: return@onPreviewKeyEvent true
                    recorder.capture(hid, event.modifierNames())
                    true
                }
                .focusable(interactionSource = interactions)
                .background(if (focused) PlezyColors.SurfaceHighest else PlezyColors.SurfaceHigh, MaterialTheme.shapes.large)
                .border(2.dp, if (focused) PlezyColors.Primary else PlezyColors.SurfaceHigh, MaterialTheme.shapes.large)
                .padding(16.dp)
                .layoutProbe("settings.keys.capture"),
            contentAlignment = Alignment.Center,
        ) {
            androidx.compose.foundation.layout.Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(T.hotkeys.recordingShortcut, style = MaterialTheme.typography.titleMedium)
                Text("${T.hotkeys.currentShortcut} ${state.keys}", style = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace), color = PlezyColors.TextMuted)
            }
        }
        if (state.failed) InlineError(T.common.error, Modifier.layoutProbe("settings.keys.error"))
        OverlayActions {
            PlezyButton(
                T.hotkeys.clearShortcut,
                recorder::clear,
                Modifier.layoutProbe("settings.keys.clear"),
                style = ButtonStyle.TEXT,
                enabled = !state.unset && !state.saving,
            )
            PlezyButton(T.common.cancel, dismiss, style = ButtonStyle.TEXT, enabled = !state.saving)
            PlezyButton(
                T.common.save,
                { scope.launch { if (recorder.save()?.closesRecorder == true) onDismiss() } },
                Modifier.layoutProbe("settings.keys.save"),
                enabled = state.canSave,
            )
        }
    }
}

/** The modifier keys alone: the recorder waits for the key they go with. */
private val ModifierKeys = setOf(Key.CtrlLeft, Key.CtrlRight, Key.ShiftLeft, Key.ShiftRight, Key.AltLeft, Key.AltRight, Key.MetaLeft, Key.MetaRight)

/** The modifiers held with this key, as the store names them. */
private fun KeyEvent.modifierNames(): Set<String> = buildSet {
    if (isAltPressed) add("alt")
    if (isCtrlPressed) add("control")
    if (isShiftPressed) add("shift")
    if (isMetaPressed) add("meta")
}
