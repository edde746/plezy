package com.edde746.plezy.ui.watch

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import com.edde746.plezy.presentation.watch.WatchPillUi
import com.edde746.plezy.presentation.watch.WatchPlayBlockedUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.player.PanelShape
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/** Room actions that send the player's commands, copy with the clipboard and say what they did in [toasts]. */
@Suppress("DEPRECATION")
@Composable
private fun playerRoomActions(onCommand: (PlayerCommand) -> Unit, toasts: WatchToasts): RoomActions {
    val clipboard = LocalClipboardManager.current
    val command by rememberUpdatedState(onCommand)
    return remember(toasts, clipboard) {
        RoomActions(
            execute = { command(PlayerCommand.Watch(it)) },
            copy = { text, done ->
                clipboard.setText(AnnotatedString(text))
                toasts.show(done)
            },
        )
    }
}

/**
 * The session indicator in the player's top bar while this device is in a room: the people icon (sync arrows while
 * the connection isn't up), how many are in the room, the host badge on the host's player and "Reconnecting…" while
 * the connection is down, on black. It opens the room panel ([onClick]). A screen reader hears what it opens and the
 * room's state. Harness name `player.watch`.
 */
@Composable
internal fun RoomPill(pill: WatchPillUi, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    PlezySurface(
        onClick = onClick,
        modifier = modifier
            .semantics {
                contentDescription = pill.label
                stateDescription = pill.value
            }
            .layoutProbe("player.watch"),
        shape = CircleShape,
        color = Color.Black.copy(alpha = 0.45f),
        contentColor = PlezyColors.OnVideo,
        contentAlignment = Alignment.Center,
    ) {
        Row(Modifier.padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(if (pill.connected) PlezyIcons.Groups else PlezyIcons.Sync, contentDescription = null, Modifier.size(20.dp))
            Text(pill.count, style = (if (tv) MaterialTheme.typography.titleMedium else MaterialTheme.typography.titleSmall).copy(fontWeight = FontWeight.Bold))
            if (pill.isHost) HostBadge(T.watchTogether.hostBadge)
            pill.status?.let { Text(it, style = MaterialTheme.typography.labelMedium) }
        }
    }
}

/** "Reconnecting…" over the video while the room's connection is down, on black. Harness name `player.watch.reconnecting`. */
@Composable
internal fun ReconnectingPill(text: String, modifier: Modifier = Modifier) {
    Surface(
        modifier.layoutProbe("player.watch.reconnecting", reportsFocus = false),
        shape = CircleShape,
        color = Color.Black.copy(alpha = 0.6f),
        contentColor = PlezyColors.OnVideo,
    ) {
        Row(Modifier.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(PlezyIcons.Sync, contentDescription = null, Modifier.size(18.dp))
            Text(text, style = MaterialTheme.typography.titleSmall, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
        }
    }
}

/**
 * The player refused to start in a playing room: a card with "Playback didn't start", what to do, and Play ([focus]:
 * the player moves a remote's focus there while it shows), which starts the player ([WatchCommand.PlayBlockedPlayer]).
 * A screen reader speaks the title as it shows. Harness names `player.watch.blocked`, `player.watch.blocked.play`.
 */
@Composable
internal fun PlayBlockedCard(blocked: WatchPlayBlockedUi, focus: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier = Modifier) {
    Surface(
        modifier.widthIn(max = 360.dp).layoutProbe("player.watch.blocked", reportsFocus = false),
        shape = PanelShape,
        color = PlezyColors.Surface,
        contentColor = PlezyColors.OnVideo,
    ) {
        Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(PlezyIcons.Groups, contentDescription = null, Modifier.size(40.dp))
            Text(blocked.title, Modifier.semantics { liveRegion = LiveRegionMode.Polite }, style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
            Text(blocked.description, style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center, color = PlezyColors.OnVideoMuted)
            Spacer(Modifier.size(4.dp))
            PlezyButton(
                blocked.play,
                { onCommand(PlayerCommand.Watch(WatchCommand.PlayBlockedPlayer)) },
                Modifier.focusRequester(focus).layoutProbe("player.watch.blocked.play"),
                style = ButtonStyle.PRIMARY,
                icon = PlezyIcons.PlayArrow,
            )
        }
    }
}

/**
 * The room panel ([com.edde746.plezy.input.PlayerMenu.WATCH_TOGETHER]): its title, then while the room's media plays
 * this user's offset ([OffsetControl]), then the room as the Watch Together screen shows it, stacked
 * ([WatchRoomContent]), Copy Code (on TV, which has none, the room's first control) taking focus ([initial]) as it
 * opens (an offset step taking it would move playback on a stray press). It scrolls where it is taller than the panel;
 * Back closes a question, then Choose a Copy, then the panel. Harness names `player.watch.panel`, `watch.panel.title`,
 * and the room's.
 */
@Composable
internal fun WatchSessionSheet(watch: PlayerWatchUi, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier = Modifier) {
    val room = watch.room
    val toasts = remember { WatchToasts() }
    val actions = playerRoomActions(onCommand, toasts)
    Column(modifier) {
        Text(
            room.title,
            Modifier.padding(horizontal = 8.dp).padding(bottom = 4.dp).layoutProbe("watch.panel.title", reportsFocus = false),
            style = MaterialTheme.typography.titleLarge,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Column(
            Modifier
                .verticalScroll(rememberScrollState())
                .padding(PaddingValues(horizontal = 8.dp, vertical = LocalPlezyDimens.current.focusReach))
                .layoutProbe("player.watch.panel", reportsFocus = false),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (room.media.title != null) OffsetControl(room.offset, actions)
            WatchRoomContent(room, actions, wide = false, qrSize = 160.dp, firstFocus = initial, offset = false)
        }
    }
    toasts.Host()
}

/**
 * The player's question when the room offers a copy of another length ([PlayerWatchUi.mismatch]): a sheet titled with
 * it, the copy, Play Anyway (focused), Choose Another Copy (Choose a Copy over it) and Don't Play. It opens once per
 * mismatch ([com.edde746.plezy.presentation.watch.WatchMismatchUi.key]), when no menu is open ([menuOpen]: it waits
 * for that to close), and closes itself once that mismatch is settled, here or elsewhere. Back (a tap outside) closes
 * it. Harness name `watch.mismatch`.
 */
@Composable
internal fun MismatchPrompt(watch: PlayerWatchUi, menuOpen: Boolean, onCommand: (PlayerCommand) -> Unit) {
    val asked = remember { HashSet<String>() }
    var showing by remember { mutableStateOf<String?>(null) }
    val mismatch = watch.mismatch
    val key = mismatch?.key
    LaunchedEffect(key, menuOpen) {
        if (showing != null && showing != key) showing = null
        if (key != null && showing == null && !menuOpen && asked.add(key)) showing = key
    }
    if (mismatch == null || showing != key) return
    val toasts = remember { WatchToasts() }
    val actions = playerRoomActions(onCommand, toasts)
    val play = remember { FocusRequester() }
    var choosing by remember(key) { mutableStateOf(false) }
    PlezySheet(onDismiss = { showing = null }, title = mismatch.title, initialFocus = play, probe = "watch.mismatch") {
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = LocalPlezyDimens.current.focusReach),
        ) {
            MismatchBlock(mismatch, actions, onChoose = { choosing = true }, showTitle = false, playFocus = play)
        }
    }
    if (choosing) CopiesSheet(watch.room.media.copies, actions, onClose = { choosing = false })
    toasts.Host()
}
