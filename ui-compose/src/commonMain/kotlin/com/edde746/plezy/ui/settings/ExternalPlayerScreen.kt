package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.ExternalPlayerPage
import com.edde746.plezy.presentation.settings.ExternalPlayerRowUi
import com.edde746.plezy.presentation.settings.ExternalPlayerUiState
import com.edde746.plezy.presentation.settings.SettingIcon
import com.edde746.plezy.presentation.settings.SettingToggleRow
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * External player: "Use External Player"; while it is on, the players found on this device and the custom ones, each
 * with its radio (a click selects it), a custom one with Delete, and "Add Custom Player". Harness names:
 * `settings.external.<enabled|player.<id>|delete.<id>|add>`.
 */
@Composable
internal fun ExternalPlayerScreen(app: AppSession, route: Route) {
    val store = retainedStore(app, route, "settings.external", { app.settings.externalPlayer() }, ExternalPlayerPage::release) ?: return
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    var adding by remember { mutableStateOf(false) }
    val list = rememberLazyListState()
    SettingsPageFrame(T.externalPlayer.title, app, hub = false, toasts = remember { SettingsToasts() }, scrolled = { list.canScrollBackward }) {
        SettingsList(state = list) {
            val toggle = SettingToggleRow("enabled", T.externalPlayer.useExternalPlayer, T.externalPlayer.useExternalPlayerDescription, state.enabled, icon = SettingIcon.OPEN_IN_NEW)
            settingsGroup(
                "enabled",
                null,
                listOf(SettingsItem("enabled") { shape -> SettingToggleItem(toggle, store::setEnabled, shape, Modifier.rememberFocus(memory, "enabled").layoutProbe("settings.external.enabled")) }),
            )
            if (state.enabled) {
                settingsGroup(
                    "players",
                    T.externalPlayer.selectPlayer,
                    state.players.map { player -> SettingsItem("player.${player.id}") { shape -> PlayerRow(player, shape, store, deletable = false, Modifier.rememberFocus(memory, player.id)) } },
                )
                settingsGroup(
                    "custom",
                    T.externalPlayer.customPlayers,
                    state.custom.map { player -> SettingsItem("custom.${player.id}") { shape -> PlayerRow(player, shape, store, deletable = true, Modifier.rememberFocus(memory, player.id)) } } +
                        SettingsItem("add") { shape ->
                            GroupRow(
                                T.externalPlayer.addCustomPlayer,
                                onClick = { adding = true },
                                modifier = Modifier.rememberFocus(memory, "add").layoutProbe("settings.external.add"),
                                shape = shape,
                                icon = SettingIcon.ADD.vector,
                            )
                        },
                )
            }
        }
    }
    RestoreFocus(memory, ready = true, fallback = "enabled")
    if (adding) AddCustomPlayerDialog(state, onAdd = store::addCustom, onDismiss = { adding = false })
}

/** A player: its icon, name and a check while it is the one used (a click selects it), and with [deletable] a Delete button at its end. */
@Composable
private fun PlayerRow(player: ExternalPlayerRowUi, shape: Shape, store: ExternalPlayerPage, deletable: Boolean, modifier: Modifier) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        PlezySurface(
            onClick = { store.select(player.id) },
            modifier = modifier.weight(1f).heightIn(min = 56.dp).layoutProbe("settings.external.player.${player.id}"),
            shape = shape,
            role = Role.RadioButton,
            selected = player.selected,
            grows = false,
            contentAlignment = Alignment.CenterStart,
        ) {
            Row(Modifier.padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Icon(
                    if (player.systemDefault) PlezyIcons.OpenInNew else SettingIcon.PLAY_CIRCLE.vector,
                    contentDescription = null,
                    Modifier.size(24.dp),
                    tint = PlezyColors.MutedContent,
                )
                RowText(player.name, null, Modifier.weight(1f))
                if (player.selected) Icon(PlezyIcons.Check, contentDescription = null, Modifier.size(22.dp))
            }
        }
        if (deletable) {
            PlezyIconButton(SettingSymbols.Delete, T.common.delete, { store.delete(player.id) }, Modifier.layoutProbe("settings.external.delete.${player.id}"), style = IconButtonStyle.PLAIN)
        }
    }
}

/**
 * Add Custom Player: its name, its type (Command or Package Name, URL Scheme; shown where there are two) and the
 * value, labelled and hinted per type. Save adds it and closes once both fields have text; else nothing happens.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun AddCustomPlayerDialog(state: ExternalPlayerUiState, onAdd: (String, String, String) -> Boolean, onDismiss: () -> Unit) {
    val keyboard = rememberKeyboardOnSelect()
    val name = remember { TextFieldState() }
    val value = remember { TextFieldState() }
    val nameFocus = remember { FocusRequester() }
    val valueFocus = remember { FocusRequester() }
    var type by remember { mutableStateOf(state.customTypes.firstOrNull { it.selected }?.id ?: state.customTypes.firstOrNull()?.id.orEmpty()) }
    val typeLabel = state.customTypes.firstOrNull { it.id == type }?.label.orEmpty()
    ModalOverlay(T.externalPlayer.addCustomPlayer, onDismiss, initialFocus = nameFocus, maxWidth = 360.dp) {
        OutlinedTextField(
            state = name,
            lineLimits = TextFieldLineLimits.SingleLine,
            readOnly = keyboard.readOnly,
            label = { Text(T.externalPlayer.playerName) },
            placeholder = { Text(T.externalPlayer.playerNameHint) },
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
            onKeyboardAction = { valueFocus.requestFocus() },
            modifier = Modifier.fillMaxWidth().focusRequester(nameFocus).then(keyboard.modifier).remoteLeavesField(name).layoutProbe("settings.external.name"),
        )
        if (state.customTypes.size > 1) {
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                state.customTypes.forEach { option ->
                    PlezyChip(option.label, selected = option.id == type, onClick = { type = option.id }, modifier = Modifier.layoutProbe("settings.external.type.${option.id}"), tab = true)
                }
            }
        }
        OutlinedTextField(
            state = value,
            lineLimits = TextFieldLineLimits.SingleLine,
            readOnly = keyboard.readOnly,
            label = { Text(typeLabel) },
            placeholder = { Text(state.customValueHint[type].orEmpty()) },
            keyboardOptions = KeyboardOptions(autoCorrectEnabled = false, imeAction = ImeAction.Done),
            modifier = Modifier.fillMaxWidth().focusRequester(valueFocus).then(keyboard.modifier).remoteLeavesField(value).layoutProbe("settings.external.value"),
        )
        OverlayActions {
            PlezyButton(T.common.cancel, onDismiss, style = ButtonStyle.TEXT)
            PlezyButton(
                T.common.save,
                { if (onAdd(name.text.toString().trim(), type, value.text.toString().trim())) onDismiss() },
                Modifier.layoutProbe("settings.external.save"),
                style = ButtonStyle.PRIMARY,
            )
        }
    }
}
