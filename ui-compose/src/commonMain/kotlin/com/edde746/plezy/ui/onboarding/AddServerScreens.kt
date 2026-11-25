package com.edde746.plezy.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.input.setTextAndPlaceCursorAtEnd
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.presentation.onboarding.AddMediaBrowserStore
import com.edde746.plezy.presentation.onboarding.AddMediaBrowserUiState
import com.edde746.plezy.presentation.onboarding.EditConnectionStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.InlineError
import com.edde746.plezy.ui.components.PasswordField
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.contentColumn
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.focus.FocusInto
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * Adding a Jellyfin or Emby user ([AddMediaBrowserStore]). Before a probe: Server URLs (several, one per line or
 * comma-separated; Go finds the server), the servers on the LAN (a line while the search runs, then one row each, which
 * fills in its address and probes it) and Find server. After it: the server's card (its name and version, Change),
 * Username, Password (Done signs in), Sign in and, when the server has it, Use Quick Connect. While Quick Connect waits
 * its code replaces the form ([QuickConnectPanel]). The URL field takes focus as the screen opens (not on a touch
 * screen); Username after a probe (Password when signing in again), Cancel as the code shows
 * ([AddMediaBrowserUiState.focusUsername], [AddMediaBrowserUiState.focusPassword], [AddMediaBrowserUiState.focusCancel]).
 *
 * Harness names: `addserver.url`, `addserver.local.<i>`, `addserver.find`, `addserver.change`, `addserver.username`,
 * `addserver.password`, `addserver.signin`, `addserver.quickconnect`, `addserver.error`, [QuickConnectPanel]'s.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun AddMediaBrowserScreen(store: AddMediaBrowserStore, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val dimens = LocalPlezyDimens.current
    val url = remember { FocusRequester() }
    val username = remember { FocusRequester() }
    val password = remember { FocusRequester() }
    val cancel = remember { FocusRequester() }
    val enabled = !state.busy
    Column(modifier.fillMaxSize()) {
        val quick = rememberScrollState()
        val form = rememberScrollState()
        ScreenHeader(state.title, Modifier.layoutProbe("addserver.header", reportsFocus = false), onBack = onBack, scrolled = { if (state.quickConnectCode != null) quick.canScrollBackward else form.canScrollBackward })
        val code = state.quickConnectCode
        if (code != null) {
            Box(Modifier.fillMaxSize().verticalScroll(quick).padding(24.dp), contentAlignment = Alignment.Center) {
                QuickConnectPanel(code, state.error, store::cancelQuickConnect, cancel)
            }
            LaunchedEffect(state.focusCancel) {
                withFrameNanos { }
                cancel.requestFocus()
            }
            return@Column
        }
        Column(
            Modifier
                .contentColumn()
                .fillMaxSize()
                .focusGroup()
                .verticalScroll(form)
                .padding(horizontal = dimens.screenPadding, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            AccountField(
                value = state.urls,
                onValueChange = store::setUrls,
                label = T.addServer.serverUrls,
                probe = "addserver.url",
                modifier = Modifier.focusRequester(url),
                icon = PlezyIcons.Link,
                placeholder = state.dialect.exampleBaseUrl,
                supporting = if (state.server == null) T.addServer.serverUrlsHelper else null,
                error = if (state.urlRequired) T.addServer.enterMediaBrowserUrlError(state.dialect.productName) else null,
                enabled = enabled,
                keyboardType = KeyboardType.Uri,
                imeAction = ImeAction.Go,
                multiLine = true,
                onSubmit = store::findServer,
            )
            val server = state.server
            if (server == null) {
                LocalServers(state, enabled, store)
                PlezyButton(
                    T.addServer.findServer,
                    store::findServer,
                    Modifier.layoutProbe("addserver.find"),
                    style = ButtonStyle.PRIMARY,
                    icon = PlezyIcons.Search,
                    enabled = enabled,
                    fill = true,
                )
            } else {
                ServerCard(server.name, server.version, enabled, store::changeServer)
                AccountField(
                    value = state.username,
                    onValueChange = store::setUsername,
                    label = T.addServer.username,
                    probe = "addserver.username",
                    modifier = Modifier.focusRequester(username),
                    icon = PlezyIcons.Person,
                    error = if (state.usernameRequired) T.addServer.required else null,
                    enabled = enabled,
                    imeAction = ImeAction.Next,
                )
                AccountField(
                    value = state.password,
                    onValueChange = store::setPassword,
                    label = T.addServer.password,
                    probe = "addserver.password",
                    icon = PlezyIcons.Lock,
                    modifier = Modifier.focusRequester(password),
                    enabled = enabled,
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done,
                    secure = true,
                    onSubmit = store::signIn,
                )
                PlezyButton(
                    T.addServer.signIn,
                    store::signIn,
                    Modifier.layoutProbe("addserver.signin"),
                    style = ButtonStyle.PRIMARY,
                    icon = PlezyIcons.Login,
                    enabled = enabled,
                    fill = true,
                )
                if (state.quickConnectAvailable) {
                    PlezyButton(
                        T.auth.useQuickConnect,
                        store::startQuickConnect,
                        Modifier.layoutProbe("addserver.quickconnect"),
                        icon = PlezyIcons.Devices,
                        enabled = enabled,
                        fill = true,
                    )
                }
            }
            if (state.busy) LoadingIndicator(Modifier.size(40.dp).align(Alignment.CenterHorizontally).layoutProbe("addserver.busy"))
            state.error?.let { InlineError(it, Modifier.layoutProbe("addserver.error")) }
        }
    }
    FocusInto(url, key = Unit)
    // To Username after a probe, and as Quick Connect's code goes (cancelled, expired, failed) with the form back.
    val waiting = state.quickConnectCode != null
    LaunchedEffect(state.focusUsername, waiting) {
        if (waiting || state.server == null) return@LaunchedEffect
        withFrameNanos { }
        username.requestFocus()
    }
    LaunchedEffect(state.focusPassword) {
        if (state.focusPassword == 0) return@LaunchedEffect
        withFrameNanos { }
        password.requestFocus()
    }
}

/** The servers on the LAN: a line while the search runs, then a row each (its name and address) under a title. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun LocalServers(state: AddMediaBrowserUiState, enabled: Boolean, store: AddMediaBrowserStore) {
    val product = state.dialect.productName
    if (state.discovering) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            LoadingIndicator(Modifier.size(20.dp))
            Text(T.addServer.searchingLocalMediaBrowserServers(product), style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
        }
        return
    }
    if (state.localServers.isEmpty()) return
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(T.addServer.localMediaBrowserServers(product), style = MaterialTheme.typography.titleSmall)
        RowGroup {
            state.localServers.forEachIndexed { index, server ->
                GroupRow(
                    server.name,
                    onClick = { store.useLocalServer(server) },
                    modifier = Modifier.layoutProbe("addserver.local.$index"),
                    shape = groupShape(index, state.localServers.size),
                    subtitle = server.address,
                    value = if (server.id in state.addedServerIds) T.addServer.alreadyAdded else null,
                    icon = PlezyIcons.Dns,
                    enabled = enabled,
                    trailing = { Chevron() },
                )
            }
        }
    }
}

/** The server a probe found: a check, its name over its product and version, and Change (back to the URLs). */
@Composable
private fun ServerCard(name: String, version: String, enabled: Boolean, onChange: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(PlezyColors.SurfaceHigh, MaterialTheme.shapes.medium)
            .padding(start = 12.dp, top = 6.dp, bottom = 6.dp, end = 6.dp)
            .layoutProbe("addserver.server", reportsFocus = false),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(PlezyIcons.CloudDone, contentDescription = null)
        Column(Modifier.weight(1f)) {
            Text(name, style = MaterialTheme.typography.titleSmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(version, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
        }
        PlezyButton(T.addServer.change, onChange, Modifier.layoutProbe("addserver.change"), style = ButtonStyle.TEXT, enabled = enabled)
    }
}

/**
 * Quick Connect waiting for approval: how to use it, the code large and monospaced, "Waiting for approval…" with a
 * loader, Cancel ([cancel] focuses it) and the last failure, at most 420 wide.
 *
 * Harness names: `addserver.qc.code`, `addserver.qc.cancel`.
 */
@Composable
private fun QuickConnectPanel(code: String, error: String?, onCancel: () -> Unit, cancel: FocusRequester) {
    Column(Modifier.widthIn(max = 420.dp).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(T.auth.quickConnectInstructions, style = MaterialTheme.typography.bodyLarge)
        Text(
            code,
            Modifier.layoutProbe("addserver.qc.code"),
            style = MaterialTheme.typography.displaySmall.copy(fontFamily = FontFamily.Monospace, letterSpacing = 4.sp),
            maxLines = 1,
        )
        ProgressLine(T.auth.quickConnectWaiting)
        PlezyButton(T.auth.quickConnectCancel, onCancel, Modifier.focusRequester(cancel).layoutProbe("addserver.qc.cancel"), icon = PlezyIcons.Close)
        error?.let { InlineError(it) }
    }
}

/**
 * A Jellyfin or Emby connection's addresses ([EditConnectionStore]): what they are for, the URLs one per line, Save
 * (which races them and keeps those that answer) and why it couldn't.
 *
 * Harness names: `editconnection.urls`, `editconnection.save`, `editconnection.error`.
 */
@Composable
fun EditConnectionScreen(store: EditConnectionStore, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val dimens = LocalPlezyDimens.current
    val field = remember { FocusRequester() }
    Column(modifier.fillMaxSize()) {
        val scroll = rememberScrollState()
        ScreenHeader(state.title, onBack = onBack, scrolled = { scroll.canScrollBackward })
        Column(
            Modifier.contentColumn().fillMaxSize().focusGroup().verticalScroll(scroll).padding(horizontal = dimens.screenPadding, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(state.intro, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
            AccountField(
                value = state.urls,
                onValueChange = store::setUrls,
                label = T.addServer.serverUrls,
                probe = "editconnection.urls",
                modifier = Modifier.focusRequester(field),
                icon = PlezyIcons.Link,
                supporting = T.addServer.serverUrlsHelper,
                enabled = !state.busy,
                keyboardType = KeyboardType.Uri,
                imeAction = ImeAction.Done,
                multiLine = true,
                onSubmit = store::save,
            )
            PlezyButton(T.common.save, store::save, Modifier.layoutProbe("editconnection.save"), style = ButtonStyle.PRIMARY, enabled = !state.busy, fill = true)
            state.error?.let { InlineError(it, Modifier.layoutProbe("editconnection.error")) }
        }
    }
    FocusInto(field, key = state.title)
}

/**
 * A text field of the account screens: [label] over it, [icon] before the text, [placeholder] while empty, [supporting]
 * or [error] under it. It keeps its own text and tells [onValueChange] each edit; a [value] the store sets otherwise
 * (an address filled in, the probe's addresses) replaces it. Enter (the keyboard's, or the soft keyboard's [imeAction])
 * runs [onSubmit], else moves on to the next control; Down leaves a one-line field. [secure] makes it a [PasswordField]. On
 * TV the keyboard waits for Select ([rememberKeyboardOnSelect]) and the arrows leave the field ([remoteLeavesField]).
 */
@Composable
internal fun AccountField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    probe: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    placeholder: String? = null,
    supporting: String? = null,
    error: String? = null,
    enabled: Boolean = true,
    keyboardType: KeyboardType = KeyboardType.Text,
    imeAction: ImeAction = ImeAction.Next,
    secure: Boolean = false,
    multiLine: Boolean = false,
    capitalization: KeyboardCapitalization = KeyboardCapitalization.None,
    onSubmit: (() -> Unit)? = null,
) {
    val keyboard = rememberKeyboardOnSelect()
    val focusManager = LocalFocusManager.current
    val text = remember { TextFieldState(value) }
    // The last text this field told the store, or the store set. A value the store sets otherwise (an address filled
    // in from the LAN, the probe's list) replaces what is shown; its echo of an edit, a frame behind the typing, doesn't.
    val known = remember { arrayOf(value) }
    LaunchedEffect(value) {
        if (value != known[0] && text.text.toString() != value) {
            known[0] = value
            text.setTextAndPlaceCursorAtEnd(value)
        }
    }
    val submit = { if (onSubmit != null) onSubmit() else focusManager.moveFocus(FocusDirection.Next) }
    val options = KeyboardOptions(
        capitalization = capitalization,
        autoCorrectEnabled = false,
        keyboardType = keyboardType,
        imeAction = imeAction,
    )
    val fieldModifier = modifier
        .fillMaxWidth()
        .then(keyboard.modifier)
        .onPreviewKeyEvent { event ->
            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
            when (event.key) {
                // A hardware Enter does what the soft keyboard's action does.
                Key.Enter, Key.NumPadEnter -> {
                    submit()
                    true
                }
                Key.DirectionDown -> !multiLine && focusManager.moveFocus(FocusDirection.Down)
                else -> false
            }
        }
        .remoteLeavesField(text)
        .inViewAboveKeyboard()
        .layoutProbe(probe)
    if (secure) {
        PasswordField(
            state = text,
            label = label,
            modifier = fieldModifier,
            enabled = enabled,
            readOnly = keyboard.readOnly,
            icon = icon,
            supporting = supporting,
            error = error,
            keyboardOptions = options,
            onKeyboardAction = { submit() },
        )
    } else {
        OutlinedTextField(
            state = text,
            enabled = enabled,
            readOnly = keyboard.readOnly,
            lineLimits = if (multiLine) TextFieldLineLimits.MultiLine(1, 4) else TextFieldLineLimits.SingleLine,
            label = { Text(label) },
            placeholder = placeholder?.let { { Text(it, maxLines = 1, overflow = TextOverflow.Ellipsis) } },
            leadingIcon = icon?.let { { Icon(it, contentDescription = null) } },
            supportingText = (error ?: supporting)?.let { { Text(it) } },
            isError = error != null,
            keyboardOptions = options,
            onKeyboardAction = { submit() },
            modifier = fieldModifier,
        )
    }
    OnTextChange(text) {
        known[0] = it
        if (it != value) onValueChange(it)
    }
}
