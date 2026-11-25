package com.edde746.plezy.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.presentation.onboarding.AddPlexAccountStore
import com.edde746.plezy.presentation.onboarding.PlexPinFlow
import com.edde746.plezy.presentation.onboarding.PlexPinPhase
import com.edde746.plezy.presentation.onboarding.PlexPinUiState
import com.edde746.plezy.presentation.onboarding.SignInStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.InlineError
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.QrCodeImage
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.qrSize
import com.edde746.plezy.ui.focus.FocusInto
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The first sign-in ([SignInStore]) as an account page ([AccountPage]): the logo and "Plezy", then Sign in with Plex
 * (the browser) and Show QR Code (on TV the QR code first, focused, and Use browser second), Connect to Jellyfin and
 * Connect to Emby under a divider, and the recovery notice under them. A started Plex sign-in replaces the page
 * ([PlexPinPage]).
 *
 * Harness names: `signin`, `signin.plex`, `signin.qr`, `signin.jellyfin`, `signin.emby`, `signin.notice` and
 * [PlexPinPage]'s.
 */
@Composable
fun SignInScreen(store: SignInStore, modifier: Modifier = Modifier) {
    val pin by store.plex.state.collectAsState()
    val notice by store.notice.collectAsState()
    PlexPinPage(T.app.title, pin, store.plex, modifier.layoutProbe("signin", reportsFocus = false), header = { PlezyLogo(72.dp) }) {
        // Back from a server form: focus on the button that opened it, not on the first.
        val opened = store.opened
        PlexButtons(pin, store.plex, store.tv, focusFirst = opened == null)
        HorizontalDivider(Modifier.fillMaxWidth(), color = PlezyColors.Hairline)
        ConnectButton(MediaBrowserDialect.JELLYFIN, focused = opened == MediaBrowserDialect.JELLYFIN) { store.connect(MediaBrowserDialect.JELLYFIN) }
        ConnectButton(MediaBrowserDialect.EMBY, focused = opened == MediaBrowserDialect.EMBY) { store.connect(MediaBrowserDialect.EMBY) }
        notice?.let { InlineError(it, Modifier.layoutProbe("signin.notice")) }
    }
}

/**
 * Adding a Plex account from inside the app ([AddPlexAccountStore]) as an account page with its back button: Sign in
 * with Plex and Show QR Code; on TV the QR code shows by itself as the sign-in service is ready.
 */
@Composable
fun AddPlexAccountScreen(store: AddPlexAccountStore, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val pin by store.plex.state.collectAsState()
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    var started by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(pin.ready) {
        if (tv && pin.ready && !started && pin.phase == PlexPinPhase.IDLE) {
            started = true
            store.plex.startQr()
        }
    }
    PlexPinPage(T.addServer.addPlexTitle, pin, store.plex, modifier, onBack = onBack) { PlexButtons(pin, store.plex, tv = false, focusFirst = true) }
}

/**
 * Sign in with Plex and Show QR Code, both off until the sign-in service is made; on TV the QR code first (focused, with
 * the Plex mark) and Use browser second. Focus goes to the first as they show (not on a touch screen) when [focusFirst].
 */
@Composable
private fun PlexButtons(pin: PlexPinUiState, flow: PlexPinFlow, tv: Boolean, focusFirst: Boolean) {
    val first = remember { FocusRequester() }
    if (tv) {
        PlezyButton(
            T.auth.signInWithPlex,
            flow::startQr,
            Modifier.focusRequester(first).layoutProbe("signin.qr"),
            style = ButtonStyle.PRIMARY,
            icon = OnboardingMarks.Plex,
            enabled = pin.ready,
            fill = true,
        )
        PlezyButton(T.auth.useBrowser, flow::startBrowser, Modifier.layoutProbe("signin.plex"), enabled = pin.ready, fill = true)
    } else {
        PlezyButton(
            T.auth.signInWithPlex,
            flow::startBrowser,
            Modifier.focusRequester(first).layoutProbe("signin.plex"),
            style = ButtonStyle.PRIMARY,
            icon = OnboardingMarks.Plex,
            enabled = pin.ready,
            fill = true,
        )
        PlezyButton(T.auth.showQRCode, flow::startQr, Modifier.layoutProbe("signin.qr"), icon = OnboardingMarks.QrCode, enabled = pin.ready, fill = true)
    }
    if (focusFirst) FocusInto(first, key = pin.ready)
}

/** Connect to Jellyfin / Emby, with the backend's mark; [focused] takes focus as it shows (not on a touch screen). */
@Composable
private fun ConnectButton(dialect: MediaBrowserDialect, focused: Boolean, onClick: () -> Unit) {
    val focus = remember { FocusRequester() }
    PlezyButton(
        T.auth.connectToMediaBrowser(dialect.productName),
        onClick,
        Modifier.focusRequester(focus).layoutProbe("signin.${dialect.id}"),
        icon = OnboardingMarks.backend(dialect.backend),
        fill = true,
    )
    if (focused) FocusInto(focus, key = Unit)
}

/**
 * A Plex PIN sign-in where it stands, as a whole account page: [idle] (the buttons) before a start, under [title] and
 * [header]; then waiting for the browser ("Waiting for authentication…" and Retry), the QR code (how to sign in, the
 * code on white beside the page on TV and wide landscape windows, under the text otherwise; "plex.tv/link" and the code
 * to enter there, large; the waiting line; the last failure; Retry), or the account being stored. Expired, the QR page
 * keeps only the expiry and Retry under it. Retry takes focus as it shows (not on a touch screen). While it runs the
 * page's back button (and Back) cancels it; before, [onBack] leaves. Elsewhere the last failure shows under it all.
 *
 * Harness names: `signin.waiting`, `signin.qr.code`, `signin.link`, `signin.code`, `signin.retry`, `signin.cancel`
 * (the back button while it runs), `signin.error`.
 */
@Composable
internal fun PlexPinPage(
    title: String,
    pin: PlexPinUiState,
    flow: PlexPinFlow,
    modifier: Modifier = Modifier,
    onBack: (() -> Unit)? = null,
    header: (@Composable () -> Unit)? = null,
    idle: @Composable ColumnScope.() -> Unit,
) {
    val error: @Composable () -> Unit = { pin.error?.let { InlineError(it, Modifier.layoutProbe("signin.error")) } }
    when (pin.phase) {
        PlexPinPhase.IDLE -> AccountPage(title, modifier, onBack = onBack, header = header) {
            idle()
            error()
        }
        PlexPinPhase.BROWSER, PlexPinPhase.REGISTERING -> AccountPage(title, modifier, onBack = flow::cancel, backProbe = "signin.cancel", focusBack = pin.phase == PlexPinPhase.REGISTERING) {
            ProgressLine(T.auth.waitingForAuth, Modifier.layoutProbe("signin.waiting"))
            if (pin.phase == PlexPinPhase.BROWSER) RetryButton(flow)
            error()
        }
        PlexPinPhase.QR -> {
            val beside = qrBeside() && !pin.expired
            val qr: @Composable () -> Unit = { QrTile(pin.qrUrl) }
            AccountPage(title, modifier, onBack = flow::cancel, backProbe = "signin.cancel", aside = if (beside) qr else null) {
                if (!pin.expired) {
                    Text(T.services.deviceCode.instructions, style = MaterialTheme.typography.bodyLarge)
                    if (!beside) qr()
                    pin.code?.let { LinkCode(it) }
                    if (pin.qrUrl != null) ProgressLine(T.services.deviceCode.waitingForAuthorization, Modifier.layoutProbe("signin.waiting"))
                }
                error()
                RetryButton(flow)
            }
        }
    }
}

/** Retry, focused as it shows (not on a touch screen). */
@Composable
private fun RetryButton(flow: PlexPinFlow) {
    val retry = remember { FocusRequester() }
    PlezyButton(T.common.retry, flow::retry, Modifier.focusRequester(retry).layoutProbe("signin.retry"), icon = PlezyIcons.Refresh)
    FocusInto(retry, key = Unit)
}

/** Where to enter the code ("plex.tv/link") and [code] under it, large and monospaced. */
@Composable
private fun LinkCode(code: String) {
    Text(
        PLEX_LINK,
        Modifier.layoutProbe("signin.link"),
        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
    )
    Text(
        code,
        Modifier.layoutProbe("signin.code"),
        style = MaterialTheme.typography.displaySmall.copy(fontFamily = FontFamily.Monospace, letterSpacing = 4.sp),
        maxLines = 1,
    )
}

/** The page where a code of a PIN that isn't strong is entered. */
private const val PLEX_LINK = "plex.tv/link"

/** [payload]'s QR code, dark on white whatever the theme, on a white tile; a loader while the link is made (null). */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun QrTile(payload: String?) {
    val size = qrSize()
    Box(Modifier.background(Color.White, MaterialTheme.shapes.large).padding(12.dp), contentAlignment = Alignment.Center) {
        if (payload == null) {
            Box(Modifier.size(size), contentAlignment = Alignment.Center) { LoadingIndicator(Modifier.size(48.dp)) }
        } else {
            QrCodeImage(payload, T.auth.scanQRToSignIn, size, Modifier.layoutProbe("signin.qr.code"), pureWhite = true)
        }
    }
}

/** Whether a code page stands its QR code beside the rest: on TV and on landscape windows wider than a phone held upright. */
@Composable
private fun qrBeside(): Boolean {
    val window = LocalWindowLayout.current
    if (window.formFactor == FormFactor.TV) return true
    if (window.widthClass == WidthClass.COMPACT) return false
    val size = LocalWindowSize.current
    val landscape by remember(size) { derivedStateOf { size.value.width > size.value.height } }
    return landscape
}

/**
 * The page of an account screen (sign-in, a code page, adding a Plex account): one group in the middle of the window,
 * at most 400 dp wide (TV: 600 dp), [header] and [title], then [content] with 12 dp between its parts. [aside] (a
 * QR code) stands to the right of the group. Scrolls when it doesn't fit; [onBack] adds a back button and takes Back:
 * the page's one way back or out. With [focusBack] the back button takes focus as the page opens: a page whose only
 * control is the way out, so a remote's OK leaves it.
 */
@Composable
internal fun AccountPage(
    title: String,
    modifier: Modifier = Modifier,
    onBack: (() -> Unit)? = null,
    backProbe: String = "account.back",
    focusBack: Boolean = false,
    header: (@Composable () -> Unit)? = null,
    aside: (@Composable () -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    if (onBack != null) SystemBackHandler(onBack = onBack)
    val back = remember { FocusRequester() }
    if (onBack != null && focusBack) LaunchedEffect(Unit) { back.requestFocus() }
    val dimens = LocalPlezyDimens.current
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    BoxWithConstraints(modifier.fillMaxSize().background(PlezyColors.Background)) {
        val minHeight = maxHeight
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .heightIn(min = minHeight)
                .padding(horizontal = dimens.screenPadding, vertical = 24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            val group: @Composable (Modifier) -> Unit = { groupModifier ->
                Column(groupModifier.focusGroup(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (onBack != null) {
                        PlezyIconButton(PlezyIcons.ArrowBack, T.nav.back, onBack, Modifier.focusRequester(back).layoutProbe(backProbe))
                    }
                    header?.invoke()
                    Text(title, style = MaterialTheme.typography.headlineMedium)
                    Spacer(Modifier.height(4.dp))
                    content()
                }
            }
            if (aside == null) {
                group(Modifier.widthIn(max = if (tv) 600.dp else 400.dp).fillMaxWidth())
            } else {
                Row(horizontalArrangement = Arrangement.spacedBy(if (tv) 56.dp else 48.dp), verticalAlignment = Alignment.CenterVertically) {
                    group(Modifier.weight(1f, fill = false).widthIn(max = if (tv) 480.dp else 400.dp).fillMaxWidth())
                    aside()
                }
            }
        }
    }
}

/** Something running: a small loading indicator and what it waits for. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun ProgressLine(text: String?, modifier: Modifier = Modifier) {
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        LoadingIndicator(Modifier.size(32.dp))
        if (text != null) Text(text, style = MaterialTheme.typography.bodyLarge, color = PlezyColors.TextMuted)
    }
}
