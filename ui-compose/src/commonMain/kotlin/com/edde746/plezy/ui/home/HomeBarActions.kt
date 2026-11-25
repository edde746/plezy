package com.edde746.plezy.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
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
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntRect
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Popup
import androidx.compose.ui.window.PopupPositionProvider
import androidx.compose.ui.window.PopupProperties
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.home.ServerTasksLoad
import com.edde746.plezy.presentation.home.ServerTasksUiState
import com.edde746.plezy.presentation.home.UserMenuAction
import com.edde746.plezy.presentation.home.UserMenuUiState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.BusyOverlay
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.ItemMenuSection
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.SectionedItemMenu
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.onboarding.ProfileAvatar
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * Home's user menu, a shortcut chip ([AppSession.userMenu]): the active profile's name (none: Profiles) after the
 * account icon, opening the other profiles (avatar, a lock where a PIN guards it), then Manage profiles, Settings and
 * Log out, in a dropdown under it (a side panel on TV, [SectionedItemMenu]). Off while a switch runs. Harness
 * names `home.userMenu`, its entries `home.userMenu.profile.<i>` and `home.userMenu.<manage|settings|logout>`.
 */
@Composable
internal fun UserMenuAction(app: AppSession, modifier: Modifier = Modifier) {
    val store = app.userMenu
    val state by store.state.collectAsState()
    var open by remember { mutableStateOf(false) }
    Box {
        PlezyChip(
            state.active?.name ?: T.profiles.sectionTitle,
            selected = false,
            onClick = { open = true },
            modifier = modifier.layoutProbe("home.userMenu"),
            enabled = !state.switching,
            dropdown = true,
            leadingIcon = PlezyIcons.AccountCircle,
            contentLabel = state.active != null,
        )
        SectionedItemMenu(open, { open = false }, userMenuSections(state, store::switchTo, store::act), "home.userMenu", title = T.profiles.sectionTitle)
    }
}

/** The menu's profiles (a section of their own, when there are any) and its actions. */
@Composable
private fun userMenuSections(state: UserMenuUiState, switchTo: (String) -> Unit, act: (UserMenuAction) -> Unit): List<ItemMenuSection> {
    val muted = MaterialTheme.colorScheme.onSurfaceVariant
    val profiles = state.profiles.mapIndexed { index, profile ->
        ItemMenuEntry(
            profile.name,
            probe = "profile.$index",
            contentLabel = true,
            leading = { ProfileAvatar(profile.name, profile.avatarUrl, 24.dp, locked = false) },
            trailing = if (profile.locked) ({ Icon(PlezyIcons.Lock, contentDescription = null, Modifier.size(14.dp), tint = muted) }) else null,
        ) { switchTo(profile.id) }
    }
    val actions = state.actions.map { action ->
        val (probe, icon) = when (action) {
            UserMenuAction.MANAGE_PROFILES -> "manage" to PlezyIcons.Group
            UserMenuAction.SETTINGS -> "settings" to PlezyIcons.Settings
            UserMenuAction.LOGOUT -> "logout" to PlezyIcons.Logout
        }
        ItemMenuEntry(action.label, probe = probe, icon = icon) { act(action) }
    }
    return listOfNotNull(ItemMenuSection(null, profiles).takeIf { profiles.isNotEmpty() }, ItemMenuSection(null, actions))
}

/**
 * What the user menu shows over Home: "Switching profile…" while a switch runs, Log out's question, a failed switch's
 * message. Harness names `home.switching`, `home.logout` (with `.cancel` and `.confirm`), `home.userMenu.message`.
 */
@Composable
internal fun BoxScope.UserMenuOverlays(app: AppSession) {
    val store = app.userMenu
    val state by store.state.collectAsState()
    if (state.switching) BusyOverlay(T.profiles.switchingProfile, null, "home.switching")
    state.confirm?.let { confirm ->
        ConfirmDialog(
            confirm.title,
            confirm.message,
            confirm.confirmLabel,
            onConfirm = store::confirm,
            onCancel = store::dismissConfirm,
            probe = "home.logout",
            modifier = Modifier.layoutProbe("home.logout", reportsFocus = false),
        )
    }
    // Its only message is a failed switch.
    state.message?.let { TimedToast(it, "home.userMenu.message", store::messageShown, Modifier.align(Alignment.BottomCenter), isError = true) }
}

/**
 * Home's Server Tasks ([AppSession.serverTasks]): off phones and tablets, while a Plex server is online, a shortcut
 * chip that opens the panel of the servers' running tasks under it ([ServerTasksPanel]). Leaving Home closes the
 * panel. Harness name `home.serverTasks`.
 */
@Composable
internal fun ServerTasksAction(app: AppSession, modifier: Modifier = Modifier) {
    val store = app.serverTasks
    val state by store.state.collectAsState()
    if (!state.shown) return
    DisposableEffect(store) { onDispose { store.close() } }
    Box {
        PlezyChip(T.serverTasks.title, selected = false, onClick = store::toggle, modifier = modifier.layoutProbe("home.serverTasks"), leadingIcon = PlezyIcons.MonitorHeart)
        if (state.open) ServerTasksPanel(state, onCancel = store::cancel, onClose = store::close)
    }
}

/**
 * The Server Tasks panel, opened under the button it belongs to (place it next to the button in a Box around both):
 * 320 dp wide, its end at the button's end, 4 dp below it; a card (radius 12, elevation 8) of the title over Loading…,
 * Failed to load tasks, No tasks running, or each server's tasks under its name and their count: a task's title,
 * subtitle and progress, and ✕ where it can be cancelled. The list scrolls past 360 dp. Back, Escape and a click
 * outside close it; the arrows reach the cancel buttons, the first of which takes focus. Harness names
 * `home.serverTasks.panel`, `home.serverTasks.cancel.<uuid>`.
 */
@Composable
internal fun ServerTasksPanel(state: ServerTasksUiState, onCancel: (serverId: String, uuid: String) -> Unit, onClose: () -> Unit) {
    val gap = with(LocalDensity.current) { 4.dp.roundToPx() }
    val position = remember(gap) { BelowAtEnd(gap) }
    Popup(popupPositionProvider = position, onDismissRequest = onClose, properties = PopupProperties(focusable = true)) {
        Surface(
            Modifier
                .width(320.dp)
                .layoutProbe("home.serverTasks.panel", reportsFocus = false)
                // Back and Escape close it wherever focus is in it, as the popup's own dismissal may not see them.
                .onPreviewKeyEvent { event ->
                    val back = event.key == Key.Back || event.key == Key.Escape
                    if (back && event.type == KeyEventType.KeyUp) onClose()
                    back
                },
            shape = MaterialTheme.shapes.medium,
            color = MaterialTheme.colorScheme.surface,
            shadowElevation = 8.dp,
        ) {
            Column {
                Row(Modifier.padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(PlezyIcons.MonitorHeart, contentDescription = null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.onSurface)
                    Spacer(Modifier.width(8.dp))
                    Text(T.serverTasks.title, style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold))
                }
                HorizontalDivider(thickness = 1.dp, color = PlezyColors.Hairline)
                Column(Modifier.heightIn(max = 360.dp).verticalScroll(rememberScrollState())) { ServerTasksBody(state, onCancel) }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ServerTasksBody(state: ServerTasksUiState, onCancel: (String, String) -> Unit) {
    when {
        state.load == ServerTasksLoad.LOADING -> Box(Modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.Center) {
            LoadingIndicator(Modifier.size(24.dp))
        }
        state.load == ServerTasksLoad.ERROR -> ErrorState(T.serverTasks.failedToLoad)
        state.groups.isEmpty() -> EmptyState(T.serverTasks.noTasks, icon = PlezyIcons.MonitorHeart)
        else -> {
            val first = remember { FocusRequester() }
            val firstCancellable = state.groups.firstNotNullOfOrNull { group -> group.tasks.firstOrNull { it.cancellable }?.let { group.serverId to it.uuid } }
            for (group in state.groups) {
                Row(Modifier.padding(start = 16.dp, top = 12.dp, end = 16.dp, bottom = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        group.name.uppercase(),
                        style = MaterialTheme.typography.labelSmall.copy(letterSpacing = 0.8.sp),
                        color = PlezyColors.TextMuted,
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        group.tasks.size.toString(),
                        Modifier.background(PlezyColors.Text, MaterialTheme.shapes.small).padding(horizontal = 6.dp, vertical = 1.dp),
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, letterSpacing = 0.sp),
                        color = PlezyColors.Background,
                    )
                }
                for (task in group.tasks) {
                    Row(Modifier.padding(start = 16.dp, top = 8.dp, end = 8.dp, bottom = 4.dp), verticalAlignment = Alignment.Top) {
                        Column(Modifier.weight(1f)) {
                            val small = MaterialTheme.typography.bodySmall
                            Text(task.title, style = small.copy(fontWeight = FontWeight.Medium), maxLines = 1, overflow = TextOverflow.Ellipsis)
                            task.subtitle?.let {
                                Spacer(Modifier.height(2.dp))
                                Text(it, style = small, color = PlezyColors.TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            }
                            Spacer(Modifier.height(6.dp))
                            LinearProgressIndicator(progress = { task.progress / 100f }, modifier = Modifier.fillMaxWidth().height(4.dp))
                        }
                        if (task.cancellable) {
                            val isFirst = firstCancellable == (group.serverId to task.uuid)
                            PlezyIconButton(
                                PlezyIcons.Close,
                                T.common.cancel,
                                { onCancel(group.serverId, task.uuid) },
                                Modifier.layoutProbe("home.serverTasks.cancel.${task.uuid}").then(if (isFirst) Modifier.focusRequester(first) else Modifier),
                                style = IconButtonStyle.PLAIN,
                                size = 32.dp,
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(8.dp))
            // The arrows walk the cancel buttons from the first, which takes focus once there is one.
            if (firstCancellable != null) LaunchedEffect(Unit) { first.requestFocus() }
        }
    }
}

/** The panel's place: its end at the anchor's end (start in a right-to-left layout), [gap] below it, inside the window. */
private class BelowAtEnd(private val gap: Int) : PopupPositionProvider {
    override fun calculatePosition(anchorBounds: IntRect, windowSize: IntSize, layoutDirection: LayoutDirection, popupContentSize: IntSize): IntOffset {
        val x = if (layoutDirection == LayoutDirection.Ltr) anchorBounds.right - popupContentSize.width else anchorBounds.left
        return IntOffset(
            x.coerceIn(0, (windowSize.width - popupContentSize.width).coerceAtLeast(0)),
            (anchorBounds.bottom + gap).coerceAtMost((windowSize.height - popupContentSize.height).coerceAtLeast(0)),
        )
    }
}
