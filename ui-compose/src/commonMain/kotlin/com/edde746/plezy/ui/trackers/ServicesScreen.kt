package com.edde746.plezy.ui.trackers

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.seerr.SeerrServiceRow
import com.edde746.plezy.presentation.settings.SettingToggleRow
import com.edde746.plezy.presentation.trackers.ConnectDialogUi
import com.edde746.plezy.presentation.trackers.ServiceRowUi
import com.edde746.plezy.presentation.trackers.TrackerServicesStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.settings.SettingsPageFrame
import com.edde746.plezy.ui.settings.SettingsSplit
import com.edde746.plezy.ui.settings.SettingsToasts
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.QrCodeImage
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.contentColumn
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.CatalogSourceLogo
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.ratings.TrackerLogo
import com.edde746.plezy.ui.settings.RowText
import com.edde746.plezy.ui.settings.SettingToggleItem
import com.edde746.plezy.ui.settings.SettingsItem
import com.edde746.plezy.ui.settings.SettingsList
import com.edde746.plezy.ui.settings.SettingsNote
import com.edde746.plezy.ui.settings.settingsGroup
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The page of a Services [route]: [content] as a settings page titled [title] (beside the hub's list on wide windows:
 * [SettingsSplit]), over the store's message ([TimedToast]) and the connect overlay; it opens the store's sign-in link
 * in the browser when it asks.
 */
@Composable
internal fun ServicesPage(app: AppSession, route: Route, store: TrackerServicesStore, title: String, content: @Composable (LazyListState) -> Unit) {
    val state by store.state.collectAsState()
    val dimens = LocalPlezyDimens.current
    val list = rememberLazyListState()
    LaunchedEffect(state.openUrl) {
        val url = state.openUrl ?: return@LaunchedEffect
        app.openUrl(url)
        store.urlOpened()
    }
    Box(Modifier.fillMaxSize()) {
        SettingsSplit(app, route) {
            SettingsPageFrame(title, app, hub = false, toasts = remember { SettingsToasts() }, scrolled = { list.canScrollBackward }) { content(list) }
        }
        state.message?.let { TimedToast(it, "services.toast", store::messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = dimens.sectionSpacing)) }
    }
    state.dialog?.let { ConnectOverlay(it, onOpen = { app.openUrl(it.url) }, onCancel = store::cancelConnect) }
}

/**
 * Settings > Services: what the services do, then a row per tracker (its mark, name, connection and a chevron, or a
 * spinner while it signs in) and Seerr's. A connected row opens the service's settings; any other starts its sign-in, which opens
 * the link in the browser on touch and pointer input, not on a keyboard or remote (the QR code serves there).
 *
 * Harness names: `services.list` (`settings.list`), `services.<service id>`, `services.toast`.
 */
@Composable
fun ServicesScreen(app: AppSession) {
    val store = remember(app) { app.services(Route.Services) } ?: return
    val state by store.state.collectAsState()
    val seerr = SeerrServiceRow.of(app.seerr.session.collectAsState().value)
    val pointer = !isFocusVisible()
    val memory = rememberFocusMemory()
    ServicesPage(app, Route.Services, store, state.title) { list ->
        SettingsList(state = list) {
            item(key = "note") { SettingsNote(state.subtitle) }
            settingsGroup(
                "trackers",
                null,
                state.rows.map { row ->
                    SettingsItem(row.service.id) { shape ->
                        ServiceRow(row, shape, Modifier.rememberFocus(memory, row.service.id)) {
                            if (row.connected) app.navigator.navigate(Route.TrackerSettings(row.service)) else store.connect(row.service, pointer)
                        }
                    }
                } + SettingsItem("seerr") { shape -> SeerrRow(seerr, shape, Modifier.rememberFocus(memory, "seerr")) {
                    app.navigator.navigate(if (seerr.connected) Route.SeerrSettings else Route.SeerrConnect)
                } },
            )
            state.discordPresence?.let { on ->
                settingsGroup(
                    "integrations",
                    T.services.integrations,
                    listOf(
                        SettingsItem("discord") { shape ->
                            SettingToggleItem(
                                SettingToggleRow("discord", T.settings.discordRichPresence, T.settings.discordRichPresenceDescription, on),
                                store::setDiscordPresence,
                                shape,
                                Modifier.rememberFocus(memory, "discord").layoutProbe("services.discord"),
                            )
                        },
                    ),
                )
            }
        }
    }
    RestoreFocus(memory, ready = state.rows.isNotEmpty(), fallback = state.rows.firstOrNull()?.service?.id)
}

/** A tracker's row: its mark, name and connection, and a chevron, or a spinner while it signs in. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ServiceRow(row: ServiceRowUi, shape: Shape, modifier: Modifier, onClick: () -> Unit) {
    // A busy row stays enabled (focus stays on it); the store ignores a second sign-in.
    GroupRow(
        row.title,
        onClick = onClick,
        modifier = modifier.layoutProbe("services.${row.service.id}"),
        shape = shape,
        subtitle = row.subtitle,
        leading = { TrackerLogo(row.service, size = 24.dp) },
        trailing = { if (row.busy) LoadingIndicator(Modifier.size(24.dp)) else Chevron() },
    )
}

/** Seerr's row: its mark, name and status, as a tracker's; opens its settings once connected, else the connect screen. */
@Composable
private fun SeerrRow(row: SeerrServiceRow, shape: Shape, modifier: Modifier, onClick: () -> Unit) {
    GroupRow(
        row.title,
        onClick = onClick,
        modifier = modifier.layoutProbe("services.seerr"),
        shape = shape,
        subtitle = row.subtitle,
        leading = { CatalogSourceLogo(CatalogSourceId.SEERR, size = 24.dp) },
        trailing = { Chevron() },
    )
}

/**
 * A sign-in waiting for the user, over the screen: the body, the link to type with Copy, a device code's code (large,
 * on the raised fill; a tap copies it), the QR code of the link on its light square, the waiting line, Cancel and Open
 * in the browser (focused). Cancel, Back and the scrim cancel the sign-in. Windows 640 dp wide or more put the QR code
 * beside the text, as large as the card's height allows; narrower ones stack them. The content scrolls, so it fits a
 * 960×540 TV.
 *
 * Harness names: `services.connect.<qr|url|copyUrl|code|open|cancel|waiting|toast>`.
 */
@Suppress("DEPRECATION")
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ConnectOverlay(dialog: ConnectDialogUi, onOpen: () -> Unit, onCancel: () -> Unit) {
    val clipboard = LocalClipboardManager.current
    val windowHeight = with(LocalDensity.current) { LocalWindowInfo.current.containerSize.height.toDp() }
    val open = remember { FocusRequester() }
    var copied by remember { mutableStateOf<String?>(null) }
    val copy = { text: String, done: String ->
        clipboard.setText(AnnotatedString(text))
        copied = done
    }
    ModalOverlay(title = dialog.title, onDismiss = onCancel, initialFocus = open, maxWidth = 900.dp, dismissOnScrim = false) {
        BoxWithConstraints(Modifier.weight(1f, fill = false)) {
            val wide = maxWidth >= 640.dp
            val qr = if (wide) (windowHeight * 0.45f).coerceIn(160.dp, 240.dp) else (maxWidth - 160.dp).coerceIn(140.dp, 200.dp)
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                if (wide) {
                    Row(horizontalArrangement = Arrangement.spacedBy(32.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(16.dp)) { ConnectDetails(dialog, copy) }
                        QrPanel(dialog, qr)
                    }
                } else {
                    ConnectDetails(dialog, copy)
                    QrPanel(dialog, qr, Modifier.align(Alignment.CenterHorizontally))
                }
                Row(Modifier.layoutProbe("services.connect.waiting"), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    LoadingIndicator(Modifier.size(24.dp))
                    Text(dialog.waiting, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
                }
            }
        }
        copied?.let { TimedToast(it, "services.connect.toast", { copied = null }, Modifier.align(Alignment.CenterHorizontally)) }
        OverlayActions(primary = open) {
            PlezyButton(dialog.cancel, onCancel, Modifier.layoutProbe("services.connect.cancel"), style = ButtonStyle.TEXT)
            PlezyButton(
                dialog.openLabel,
                onOpen,
                Modifier.focusRequester(open).layoutProbe("services.connect.open"),
                style = ButtonStyle.PRIMARY,
                icon = PlezyIcons.OpenInNew,
            )
        }
    }
}

/** The dialog's text: the body, the readable link with Copy, and a device code's code. */
@Composable
private fun ConnectDetails(dialog: ConnectDialogUi, copy: (text: String, done: String) -> Unit) {
    Text(dialog.body, style = MaterialTheme.typography.bodyMedium)
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            dialog.readableUrl,
            Modifier.weight(1f, fill = false).layoutProbe("services.connect.url"),
            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
        )
        PlezyIconButton(
            PlezyIcons.ContentCopy,
            dialog.copyUrl,
            { copy(dialog.url, dialog.urlCopied) },
            Modifier.layoutProbe("services.connect.copyUrl"),
            style = IconButtonStyle.PLAIN,
        )
    }
    if (dialog is ConnectDialogUi.DeviceCode) {
        PlezySurface(
            { copy(dialog.userCode, dialog.codeCopied) },
            Modifier.fillMaxWidth().layoutProbe("services.connect.code").semantics {
                contentDescription = dialog.copyCode
                stateDescription = dialog.userCode
            },
            shape = MaterialTheme.shapes.large,
        ) {
            val style = MaterialTheme.typography.displaySmall.copy(fontFamily = FontFamily.Monospace, letterSpacing = 6.sp)
            Text(
                dialog.userCode,
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 20.dp),
                style = style,
                maxLines = 1,
                autoSize = TextAutoSize.StepBased(minFontSize = 16.sp, maxFontSize = style.fontSize, stepSize = 1.sp),
                textAlign = TextAlign.Center,
            )
        }
    }
}

/** The QR code of the dialog's link on its light square, on the raised fill, [size] wide. */
@Composable
private fun QrPanel(dialog: ConnectDialogUi, size: Dp, modifier: Modifier = Modifier) {
    Box(modifier.background(PlezyColors.SurfaceHigh, MaterialTheme.shapes.large)) {
        QrCodeImage(dialog.url, dialog.title, size, Modifier.padding(12.dp).layoutProbe("services.connect.qr"))
    }
}
