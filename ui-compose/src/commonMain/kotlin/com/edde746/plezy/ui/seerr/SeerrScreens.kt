package com.edde746.plezy.ui.seerr

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.seerr.SeerrConnectStep
import com.edde746.plezy.presentation.seerr.SeerrCredentialForm
import com.edde746.plezy.presentation.seerr.SeerrConnectUiState
import com.edde746.plezy.presentation.seerr.SeerrCredentialKind
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.InlineError
import com.edde746.plezy.ui.components.PasswordField
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.contentColumn
import com.edde746.plezy.ui.focus.FocusInto
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.probe.layoutProbe
import androidx.compose.foundation.layout.widthIn
import com.edde746.plezy.ui.settings.SettingsItem
import com.edde746.plezy.ui.settings.SettingsList
import com.edde746.plezy.ui.settings.SettingsPageFrame
import com.edde746.plezy.ui.settings.SettingsSplit
import com.edde746.plezy.ui.settings.SettingsToasts
import com.edde746.plezy.ui.settings.settingsGroup
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/** What the Seerr connect screen asks of its store. */
class SeerrConnectIntents(
    val setUrl: (String) -> Unit,
    val probe: () -> Unit,
    val changeServer: () -> Unit,
    val chooseForm: (SeerrCredentialKind) -> Unit,
    val signInWithPlex: () -> Unit,
    val setIdentifier: (String) -> Unit,
    val setPassword: (String) -> Unit,
    val signIn: () -> Unit,
    val startQuickConnect: () -> Unit,
    val cancelQuickConnect: () -> Unit,
)

/** Connecting the profile's Seerr account ([SeerrConnectContent]); the screen closes once connected. */
@Composable
fun SeerrConnectScreen(app: AppSession, modifier: Modifier = Modifier) {
    val store = remember(app) { app.seerrConnect(Route.SeerrConnect) } ?: return
    val state by store.state.collectAsState()
    LaunchedEffect(state.done) { if (state.done) app.navigator.back() }
    val intents = remember(store) {
        SeerrConnectIntents(
            setUrl = store::setUrl,
            probe = store::probe,
            changeServer = store::changeServer,
            chooseForm = store::chooseForm,
            signInWithPlex = store::signInWithPlex,
            setIdentifier = store::setIdentifier,
            setPassword = store::setPassword,
            signIn = store::signIn,
            startQuickConnect = store::startQuickConnect,
            cancelQuickConnect = store::cancelQuickConnect,
        )
    }
    SettingsSplit(app, Route.SeerrConnect) { SeerrConnectContent(state, intents, onBack = { app.navigator.back() }, modifier) }
}

/**
 * The instance's address and Continue, then signing in by a method the instance offers (Plex, a Jellyfin or Emby
 * account, Jellyfin Quick Connect, a local account), or the Quick Connect code while it waits: one step at a time in a
 * centred column (400 dp, 600 on TV) under the screen's heading, as the app's sign-in. The error shows under the step.
 * Harness names: `seerr.connect.*`.
 */
@Composable
fun SeerrConnectContent(state: SeerrConnectUiState, intents: SeerrConnectIntents, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val tv = LocalAppearance.current.tv
    val first = remember { FocusRequester() }
    Column(modifier.fillMaxSize().layoutProbe("seerr.connect", reportsFocus = false)) {
        val scroll = rememberScrollState()
        ScreenHeader(state.title, onBack = if (tv) null else onBack, scrolled = { scroll.canScrollBackward })
        Column(
            Modifier.fillMaxWidth().verticalScroll(scroll).padding(horizontal = LocalPlezyDimens.current.screenPadding, vertical = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
          Column(Modifier.widthIn(max = if (tv) 600.dp else 400.dp).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            when (val step = state.step) {
                is SeerrConnectStep.Url -> {
                    Field(step.url, step.label, step.hint, intents.setUrl, intents.probe, KeyboardType.Uri, Modifier.focusRequester(first), "seerr.connect.url", enabled = !state.busy)
                    Text(step.helper, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
                    BusyButton(step.continueLabel, intents.probe, state.busy, "seerr.connect.continue")
                }
                is SeerrConnectStep.SignIn -> SignIn(step, intents, state.busy, first)
                is SeerrConnectStep.QuickConnect -> {
                    Text(step.code, style = MaterialTheme.typography.displaySmall, modifier = Modifier.layoutProbe("seerr.connect.code"))
                    PlezyButton(step.cancelLabel, intents.cancelQuickConnect, Modifier.focusRequester(first).layoutProbe("seerr.connect.cancel"))
                }
            }
            state.error?.let { InlineError(it, Modifier.layoutProbe("seerr.connect.error")) }
          }
        }
    }
    FocusInto(first, state.step::class)
}

@Composable
private fun SignIn(step: SeerrConnectStep.SignIn, intents: SeerrConnectIntents, busy: Boolean, first: FocusRequester) {
    RowGroup {
        GroupRow(step.instanceLabel, onClick = null, subtitle = step.baseUrl, trailing = {
            PlezyButton(step.changeLabel, intents.changeServer, Modifier.layoutProbe("seerr.connect.change"), style = ButtonStyle.TEXT, enabled = !busy)
        })
    }
    step.plexLabel?.let {
        BusyButton(it, intents.signInWithPlex, busy, "seerr.connect.plex", Modifier.focusRequester(first))
    }
    step.form?.let { Form(it, intents, busy, if (step.plexLabel == null) first else null) }
    for (method in step.methods) {
        PlezyButton(method.label, { intents.chooseForm(method.kind) }, Modifier.fillMaxWidth().layoutProbe("seerr.connect.method.${method.kind.name.lowercase()}"), enabled = !busy)
    }
    step.noMethodsMessage?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.Error) }
}

/**
 * The open credential form; another form starts with empty fields, its identifier focused, as the store empties them.
 * While [busy] the fields can't be edited or submitted.
 */
@Composable
private fun Form(form: SeerrCredentialForm, intents: SeerrConnectIntents, busy: Boolean, first: FocusRequester?) {
    val identifier = remember { FocusRequester() }
    var shownKind by remember { mutableStateOf(form.kind) }
    LaunchedEffect(form.kind) {
        if (form.kind == shownKind) return@LaunchedEffect
        shownKind = form.kind
        identifier.requestFocus()
    }
    // Keyed by the form: the fields keep their own text, which another form must not inherit.
    key(form.kind) {
        Field(
            form.identifier,
            form.identifierLabel,
            null,
            intents.setIdentifier,
            null,
            if (form.identifierIsEmail) KeyboardType.Email else KeyboardType.Text,
            Modifier.focusRequester(identifier).then(if (first != null) Modifier.focusRequester(first) else Modifier),
            "seerr.connect.identifier",
            form.identifierError,
            enabled = !busy,
        )
        Field(form.password, form.passwordLabel, null, intents.setPassword, intents.signIn, KeyboardType.Password, Modifier, "seerr.connect.password", form.passwordError, secure = true, enabled = !busy)
    }
    BusyButton(form.signInLabel, intents.signIn, busy, "seerr.connect.signIn")
    form.quickConnectLabel?.let {
        PlezyButton(it, intents.startQuickConnect, Modifier.fillMaxWidth().layoutProbe("seerr.connect.quickConnect"), enabled = !busy)
    }
}

/** The step's main button, a spinner in place of its icon while [busy]. */
@Composable
private fun BusyButton(label: String, onClick: () -> Unit, busy: Boolean, probe: String, modifier: Modifier = Modifier) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        PlezyButton(label, onClick, modifier.weight(1f).layoutProbe(probe), style = ButtonStyle.PRIMARY, enabled = !busy)
        if (busy) CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp)
    }
}

/**
 * A single-line field keeping its own text from [text], telling [onText] each change; Enter and the keyboard's action
 * run [onDone], else move focus down, as Down does. [error] shows under it. Not [enabled], it can't be edited and
 * Enter does nothing.
 */
@Composable
private fun Field(
    text: String,
    label: String,
    hint: String?,
    onText: (String) -> Unit,
    onDone: (() -> Unit)?,
    type: KeyboardType,
    modifier: Modifier,
    probe: String,
    error: String? = null,
    secure: Boolean = false,
    enabled: Boolean = true,
) {
    val state = remember { TextFieldState(text) }
    val keyboard = rememberKeyboardOnSelect()
    val focusManager = LocalFocusManager.current
    val done = {
        if (enabled) {
            if (onDone != null) onDone() else focusManager.moveFocus(FocusDirection.Down)
        }
    }
    val fieldModifier = modifier
        .fillMaxWidth()
        .then(keyboard.modifier)
        .onPreviewKeyEvent { event ->
            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
            when (event.key) {
                Key.Enter, Key.NumPadEnter -> {
                    done()
                    true
                }
                Key.DirectionDown -> focusManager.moveFocus(FocusDirection.Down)
                else -> false
            }
        }
        .remoteLeavesField(state)
        .inViewAboveKeyboard()
        .layoutProbe(probe)
    val options = KeyboardOptions(
        capitalization = KeyboardCapitalization.None,
        autoCorrectEnabled = false,
        keyboardType = type,
        imeAction = if (onDone != null) ImeAction.Done else ImeAction.Next,
    )
    if (secure) {
        PasswordField(
            state = state,
            label = label,
            modifier = fieldModifier,
            enabled = enabled,
            readOnly = keyboard.readOnly,
            error = error,
            keyboardOptions = options,
            onKeyboardAction = { done() },
        )
    } else {
        OutlinedTextField(
            state = state,
            modifier = fieldModifier,
            enabled = enabled,
            readOnly = keyboard.readOnly,
            lineLimits = TextFieldLineLimits.SingleLine,
            label = { Text(label) },
            placeholder = hint?.let { { Text(it) } },
            isError = error != null,
            supportingText = error?.let { { Text(it) } },
            keyboardOptions = options,
            onKeyboardAction = { done() },
        )
    }
    OnTextChange(state) { onText(it) }
}

/**
 * The profile's Seerr account: who is signed in and how, the instance, and Disconnect (asked first). The screen closes
 * once there is no account. Harness names: `seerr.settings.*`.
 */
@Composable
fun SeerrSettingsScreen(app: AppSession, modifier: Modifier = Modifier) {
    val store = remember(app) { app.seerrSettings(Route.SeerrSettings) } ?: return
    val state by store.state.collectAsState()
    LaunchedEffect(state.closed) { if (state.closed) app.navigator.back() }
    val first = remember { FocusRequester() }
    val list = rememberLazyListState()
    SettingsSplit(app, Route.SeerrSettings) {
        SettingsPageFrame(state.title, app, hub = false, toasts = remember { SettingsToasts() }, modifier = modifier.layoutProbe("seerr.settings", reportsFocus = false), scrolled = { list.canScrollBackward }) {
            SettingsList(state = list) {
                settingsGroup(
                    "account",
                    null,
                    listOf(
                        SettingsItem("connectedAs") { shape -> GroupRow(state.connectedAs, onClick = null, shape = shape, subtitle = state.method) },
                        SettingsItem("instance") { shape -> GroupRow(state.instanceLabel, onClick = null, shape = shape, subtitle = state.baseUrl) },
                    ),
                )
                settingsGroup(
                    "disconnect",
                    null,
                    listOf(
                        SettingsItem("disconnect") { shape ->
                            GroupRow(
                                state.disconnectLabel,
                                onClick = store::requestDisconnect,
                                modifier = Modifier.focusRequester(first).layoutProbe("seerr.settings.disconnect"),
                                shape = shape,
                                destructive = true,
                            )
                        },
                    ),
                )
            }
        }
    }
    state.confirm?.let { confirm ->
        ConfirmDialog(
            confirm.title,
            confirm.message,
            confirm.confirmLabel,
            onConfirm = store::confirmDisconnect,
            onCancel = store::cancelDisconnect,
            probe = "seerr.settings",
            cancelLabel = confirm.cancelLabel,
        )
    }
    FocusInto(first, Unit)
}
