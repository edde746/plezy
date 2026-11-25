package com.edde746.plezy.ui.app

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.home.UserMenuAction
import com.edde746.plezy.presentation.navigation.AuthErrorBannerUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.onboarding.ProfileAvatar
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.LocalPlezyDimens

/**
 * The running profile's avatar at the foot of the rail and the TV column ([expanded]: its name beside it, the open TV
 * column), with an offline mark on its corner while the device is offline. It opens the profile menu: the other
 * profiles to switch to (a PIN asked where one guards it), Manage profiles, Settings and Log out (asked first). Phones,
 * which have neither, reach profiles from Settings. Harness names: `nav.profile`, `nav.profile.menu.<i>`,
 * `nav.offline`.
 */
@Composable
internal fun ProfileButton(app: AppSession, offline: Boolean, expanded: Boolean) {
    val state by app.userMenu.state.collectAsState()
    var open by remember { mutableStateOf(false) }
    val active = state.active
    Box {
        PlezySurface(
            onClick = { open = true },
            enabled = !state.switching,
            shape = CircleShape,
            color = Color.Transparent,
            modifier = Modifier.layoutProbe("nav.profile").semantics { contentDescription = T.screens.switchProfile },
        ) {
            Row(
                Modifier.padding(AvatarInset).then(if (expanded) Modifier.padding(end = 12.dp) else Modifier),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                if (active != null) {
                    ProfileAvatar(active.name, active.avatarUrl, AvatarSize, locked = false)
                } else {
                    Icon(PlezyIcons.Person, contentDescription = null, Modifier.size(AvatarSize))
                }
                if (expanded && active != null) {
                    Text(active.name, style = MaterialTheme.typography.titleSmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
        if (offline) {
            // Over the avatar's lower trailing corner, outside the button's circle (which would cut it).
            Surface(
                Modifier
                    .padding(start = AvatarInset + AvatarSize - MarkSize + MarkOverhang, top = AvatarInset + AvatarSize - MarkSize + MarkOverhang)
                    .size(MarkSize)
                    .layoutProbe("nav.offline"),
                shape = CircleShape,
                color = PlezyColors.Background,
            ) {
                Box(contentAlignment = Alignment.Center) { Icon(PlezyIcons.CloudOff, contentDescription = null, Modifier.size(14.dp), tint = PlezyColors.TextMuted) }
            }
        }
        val entries = state.profiles.map { profile ->
            ItemMenuEntry(profile.name, probe = "profile.${profile.id}", contentLabel = true, icon = if (profile.locked) PlezyIcons.Lock else null) {
                app.userMenu.switchTo(profile.id)
            }
        } + state.actions.map { action ->
            ItemMenuEntry(action.label, probe = action.name.lowercase(), destructive = action == UserMenuAction.LOGOUT) { app.userMenu.act(action) }
        }
        ItemMenu(open, onDismiss = { open = false }, entries = entries, probe = "nav.profile.menu", title = active?.name)
    }
    UserMenuNotices(app)
}

/**
 * The profile menu's notices: Log out's confirmation and its message. Shown by the profile button, and by Settings
 * where the window has no profile button (a phone's bar) for its own Log out row.
 */
@Composable
internal fun UserMenuNotices(app: AppSession) {
    val state by app.userMenu.state.collectAsState()
    state.confirm?.let { confirm ->
        ConfirmDialog(
            confirm.title,
            confirm.message,
            confirm.confirmLabel,
            onConfirm = app.userMenu::confirm,
            onCancel = app.userMenu::dismissConfirm,
            probe = "nav.profile.logout",
            modifier = Modifier.layoutProbe("nav.profile.logout", reportsFocus = false),
        )
    }
    state.message?.let { TimedToast(it, "nav.profile.message", app.userMenu::messageShown) }
}

private val AvatarSize = 40.dp
private val MarkSize = 20.dp

/** Room round the avatar inside the button's circle. */
private val AvatarInset = 4.dp

/** How far the offline mark reaches past the avatar's edge. */
private val MarkOverhang = 4.dp

/**
 * A line across the top of the screen while something needs the user: offline (the cloud mark and Reconnect, a
 * spinner's text while [reconnecting]), or a server refusing the account ([auth]: its message, with Sign in again for
 * an expired session). Its content keeps to the screens' edges ([com.edde746.plezy.ui.theme.PlezyDimens.screenPadding],
 * on TV the overscan-safe one). Screen readers speak it as it shows and as it changes. Harness names: `nav.sync`,
 * `offline.reconnect`, `auth.signInAgain`.
 */
@Composable
internal fun SyncLine(icon: ImageVector, text: String, modifier: Modifier = Modifier, action: (@Composable () -> Unit)? = null) {
    Surface(color = PlezyColors.SurfaceHigh, modifier = Modifier.fillMaxWidth().layoutProbe("nav.sync")) {
        Row(
            modifier.padding(horizontal = LocalPlezyDimens.current.screenPadding, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(18.dp), tint = PlezyColors.Error)
            Text(
                text,
                Modifier.weight(1f).semantics { liveRegion = LiveRegionMode.Polite },
                style = MaterialTheme.typography.labelLarge,
                color = PlezyColors.Text,
            )
            action?.invoke()
        }
    }
}

/**
 * A [SyncLine]'s action: a quiet text button, on TV the primary's solid tint, as on the line's own surface a remote's
 * button at rest would read as more of the line's text.
 */
@Composable
private fun SyncLineAction(text: String, onClick: () -> Unit, probe: String) {
    PlezyButton(text, onClick, Modifier.layoutProbe(probe), style = if (LocalAppearance.current.tv) ButtonStyle.PRIMARY else ButtonStyle.TEXT)
}

/** [SyncLine] for being offline: Reconnect runs [onReconnect], which says Reconnecting while it runs. */
@Composable
internal fun OfflineLine(reconnecting: Boolean, onReconnect: () -> Unit, modifier: Modifier = Modifier) {
    SyncLine(PlezyIcons.CloudOff, if (reconnecting) T.watchTogether.reconnecting else T.downloads.syncRuleOffline, modifier) {
        if (!reconnecting) SyncLineAction(T.common.reconnect, onReconnect, "offline.reconnect")
    }
}

/**
 * [SyncLine] for servers refusing the account ([AuthErrorBannerUi]); an expired session offers Sign in again. Harness
 * names `app.authBanner`, `app.authBanner.signIn`.
 */
@Composable
internal fun AuthLine(banner: AuthErrorBannerUi, onSignInAgain: () -> Unit, modifier: Modifier = Modifier) {
    val text = listOfNotNull(banner.sessionExpired, banner.accessDenied).joinToString("\n")
    SyncLine(PlezyIcons.SyncProblem, text, modifier.layoutProbe("app.authBanner", reportsFocus = false)) {
        if (banner.signInAgain) SyncLineAction(T.connections.signInAgain, onSignInAgain, "app.authBanner.signIn")
    }
}
