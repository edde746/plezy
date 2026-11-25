package com.edde746.plezy.ui.watch

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.focus.focusRequester
import androidx.compose.foundation.focusGroup
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.presentation.watch.ParticipantUi
import com.edde746.plezy.presentation.watch.WatchConfirmUi
import com.edde746.plezy.presentation.watch.WatchCopiesUi
import com.edde746.plezy.presentation.watch.WatchCopyUi
import com.edde746.plezy.presentation.watch.WatchHeaderUi
import com.edde746.plezy.presentation.watch.WatchHostSettingsUi
import com.edde746.plezy.presentation.watch.WatchMatchUi
import com.edde746.plezy.presentation.watch.WatchMediaUi
import com.edde746.plezy.presentation.watch.WatchMismatchUi
import com.edde746.plezy.presentation.watch.WatchOffsetUi
import com.edde746.plezy.presentation.watch.WatchRoomUi
import com.edde746.plezy.presentation.watch.WatchToggleUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.QrCodeImage
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.SheetOption
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.TopOverlay
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.focusEntry
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.focus.scrollPastControls
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection

/**
 * What a room's controls do, on the Watch Together screen and in the player's room panel: [execute] runs the room's
 * commands, [copy] puts text on the clipboard and says what it did ([done]: "Room code copied").
 */
internal class RoomActions(
    val execute: (WatchCommand) -> Unit,
    val copy: (text: String, done: String) -> Unit,
)

/** Work under way: a loading indicator and what runs ("Reconnecting…", "Looking for this video…"). */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun ProgressLine(text: String, modifier: Modifier = Modifier) {
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        LoadingIndicator(Modifier.size(32.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge, color = PlezyColors.TextMuted)
    }
}

/** Muted text: what a title means, a copy's details. */
@Composable
private fun Muted(text: String, modifier: Modifier = Modifier) {
    Text(text, modifier, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
}

/**
 * [room] as the Watch Together screen and the player's room panel lay it out: its code (large, with Copy Code and
 * Share Invite) over the invite's QR code, [qrSize] wide; on TV, where nothing reads a clipboard and a phone joins by
 * typing the code, the code alone, very large beside the details, Leave Room and End Room under it where [wide], so
 * every control of the room is on screen as it opens. Then who hosts and (to a guest) who controls playback, the lock,
 * the connection, what plays and this user's copy of it, the offset ([offset]: the screen's, while something plays;
 * the player shows its own above the room), the host's choice of who controls playback and the lock, the participants
 * (a host badge, each one's app, connection and match, Make host and Remove for the host) and Leave Room, with End Room
 * beside it for the host, each asked first. [wide] puts the code and the QR code beside the rest. [firstFocus] goes on
 * the first control: Copy Code, on TV the details' first (Leave in a guest's room with none). Choose a Copy opens in a
 * sheet of its own.
 *
 * Wide on TV it fills its room and scrolls itself: the code, Leave and End stay put while the details beside them
 * scroll, so the code is never cut; elsewhere the caller scrolls it.
 *
 * Harness names: `watch.code`, `watch.copy`, `watch.share`, `watch.qr`, `watch.role`, `watch.locked`,
 * `watch.reconnecting`, `watch.media`, `watch.control.<host|everyone>`, `watch.lock`, `watch.participant.<peer id>`
 * with `.host`, `.makeHost` and `.kick`, `watch.leave`, `watch.end`, the questions' `<button>.<confirm|cancel>`, and the
 * media's and the offset's ([MediaSection], [OffsetControl]).
 */
@Composable
internal fun WatchRoomContent(
    room: WatchRoomUi,
    actions: RoomActions,
    wide: Boolean,
    qrSize: Dp,
    modifier: Modifier = Modifier,
    firstFocus: FocusRequester? = null,
    offset: Boolean = true,
) {
    // The buttons that ask first: a closing question gives focus back to the one that opened it.
    val focus = rememberFocusMemory()
    var choosing by remember { mutableStateOf(false) }
    val onChoose = { choosing = true }
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    // On TV the invite has no control: the details' first takes the focus.
    val detailsFocus = if (tv && firstFocus != null) Modifier.focusRequester(firstFocus).focusGroup() else Modifier
    val inviteFocus = firstFocus.takeUnless { tv }
    if (wide && tv) {
        val dimens = LocalPlezyDimens.current
        val details = rememberScrollState()
        val detailsEntry = remember { FocusRequester() }
        // The room's first focus goes to the details' first control; where they have none (a guest's room with nothing
        // to act on), to Leave, the first control beside them. Later entries (a question giving focus back to Leave,
        // a move down from the header) go where they ask.
        val entry = remember { FirstEntry() }
        val roomFocus = if (firstFocus != null) {
            Modifier
                .onFocusChanged { if (it.hasFocus) entry.pending = false }
                .focusRequester(firstFocus)
                .focusProperties { onEnter = { if (entry.pending) detailsEntry.requestFocus() } }
                .focusGroup()
        } else {
            Modifier
        }
        Row(modifier.fillMaxSize().then(roomFocus), horizontalArrangement = Arrangement.spacedBy(32.dp)) {
            Column(Modifier.padding(top = dimens.focusReach), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                RoomCode(room.header, large = true)
                RoomExits(room, actions, focus)
            }
            Column(
                Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .focusRequester(detailsEntry)
                    .scrollPastControls(details)
                    .verticalScroll(details)
                    .padding(top = dimens.focusReach, bottom = dimens.sectionSpacing),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                RoomDetails(room, actions, offset, onChoose, focus, exits = false)
            }
        }
    } else if (wide) {
        Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(32.dp)) {
            RoomInvite(room.header, actions, qrSize, inviteFocus, beside = true)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                RoomDetails(room, actions, offset, onChoose, focus, exits = true)
            }
        }
    } else {
        Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            if (tv) RoomCode(room.header, large = false) else RoomInvite(room.header, actions, qrSize, inviteFocus, beside = false)
            Column(detailsFocus, verticalArrangement = Arrangement.spacedBy(16.dp)) { RoomDetails(room, actions, offset, onChoose, focus, exits = true) }
        }
    }
    if (choosing) CopiesSheet(room.media.copies, actions, onClose = { choosing = false })
}

/** Whether focus has yet to enter the TV room for the first time. */
private class FirstEntry {
    var pending = true
}

/** The room code under its label: [large] (88 sp) where it stands beside the details on TV. */
@Composable
private fun RoomCode(header: WatchHeaderUi, large: Boolean) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(header.codeLabel, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(
            header.code,
            Modifier.layoutProbe("watch.code", reportsFocus = false),
            style = (if (large) MaterialTheme.typography.displayLarge.copy(fontSize = 88.sp, lineHeight = 96.sp) else MaterialTheme.typography.displaySmall)
                .copy(fontFamily = FontFamily.Monospace, letterSpacing = 4.sp),
            maxLines = 1,
        )
    }
}

/**
 * The code, Copy Code and Share Invite (each says what it put on the clipboard), and the invite's QR code under them.
 * [beside] the details (wide windows): the arrow towards them from Share goes to their first control in order, not
 * to the one the fonts' widths put nearest Share.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun RoomInvite(header: WatchHeaderUi, actions: RoomActions, qrSize: Dp, copyFocus: FocusRequester?, beside: Boolean) {
    val focusManager = LocalFocusManager.current
    val towardsDetails = if (LocalLayoutDirection.current == LayoutDirection.Rtl) Key.DirectionLeft else Key.DirectionRight
    val shareModifier = if (beside) {
        Modifier.onPreviewKeyEvent { event ->
            event.type == KeyEventType.KeyDown && event.key == towardsDetails && focusManager.moveFocus(FocusDirection.Next)
        }
    } else {
        Modifier
    }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        RoomCode(header, large = false)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            PlezyButton(
                header.copy,
                { actions.copy(header.code, header.copied) },
                (if (copyFocus != null) Modifier.focusRequester(copyFocus) else Modifier).layoutProbe("watch.copy"),
                icon = PlezyIcons.ContentCopy,
            )
            PlezyButton(
                header.share,
                { actions.copy(header.invite, header.invited) },
                shareModifier.layoutProbe("watch.share"),
                icon = PlezyIcons.Share,
            )
        }
        Box(Modifier.background(PlezyColors.SurfaceHigh, MaterialTheme.shapes.large)) {
            QrCodeImage(header.invite, header.invite, qrSize, Modifier.padding(12.dp).layoutProbe("watch.qr", reportsFocus = false))
        }
    }
}

/**
 * Who hosts and (to a guest) who controls playback, the lock and the room's state; the reconnecting line; Now Playing;
 * the offset; the host's settings; the participants; with [exits] Leave, and End for the host.
 */
@Composable
private fun RoomDetails(room: WatchRoomUi, actions: RoomActions, offset: Boolean, onChoose: () -> Unit, focus: FocusMemory, exits: Boolean) {
    val header = room.header
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        if (header.role.isNotEmpty()) Text(header.role, style = MaterialTheme.typography.titleMedium, modifier = Modifier.layoutProbe("watch.role", reportsFocus = false))
        header.control?.let { Muted(it) }
        header.locked?.let { LockedLine(it) }
        Text(room.status, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
    room.reconnecting?.let { banner ->
        Column(Modifier.layoutProbe("watch.reconnecting", reportsFocus = false), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            ProgressLine(banner.title)
            Muted(banner.description)
        }
    }
    Column {
        GroupHeader(room.media.heading)
        MediaSection(room.media, actions, onChoose)
    }
    if (offset && room.media.title != null) OffsetControl(room.offset, actions)
    room.settings?.let { HostSettings(it, actions) }
    Column {
        GroupHeader(room.participantsTitle)
        RowGroup {
            room.participants.forEachIndexed { index, participant ->
                // Keyed by peer: a question asked on a row stays with its participant as others come and go.
                key(participant.peerId) { ParticipantRow(participant, index, room.participants.size, actions, focus) }
            }
        }
    }
    if (exits) RoomExits(room, actions, focus)
}

/** "Room locked", with a lock, under who controls playback, while the room is locked. */
@Composable
private fun LockedLine(text: String) {
    Row(Modifier.layoutProbe("watch.locked", reportsFocus = false), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(PlezyIcons.Lock, contentDescription = null, Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        Muted(text)
    }
}

/**
 * Now Playing: the room's media (or that nothing plays, and what then happens), whether others can find it, this user's
 * copy, Join Current Playback and the host's Stop Video for Everyone. Harness names `watch.media`, `watch.notShareable`,
 * `watch.joinPlayback`, `watch.stop`, and the copy's ([MatchSection]).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun MediaSection(media: WatchMediaUi, actions: RoomActions, onChoose: () -> Unit) {
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        val title = media.title
        Text(title ?: media.idle, style = MaterialTheme.typography.titleMedium, modifier = Modifier.layoutProbe("watch.media", reportsFocus = false))
        if (title == null) {
            Muted(media.idleDetail)
            return@Column
        }
        media.notShareable?.let { note ->
            Row(Modifier.layoutProbe("watch.notShareable", reportsFocus = false), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(PlezyIcons.Info, contentDescription = null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Muted(note)
            }
        }
        media.match?.let { MatchSection(it, actions, onChoose) }
        media.joinPlayback?.let { join ->
            Muted(join.description)
            PlezyButton(join.label, { actions.execute(WatchCommand.JoinPlayback) }, Modifier.layoutProbe("watch.joinPlayback"), style = ButtonStyle.PRIMARY, icon = PlezyIcons.PlayArrow)
        }
        media.stop?.let { stop ->
            PlezyButton(stop, { actions.execute(WatchCommand.StopMedia) }, Modifier.layoutProbe("watch.stop"), icon = PlezyIcons.Stop)
        }
    }
}

/**
 * This user's copy of the room's media: shared, searched for, of another length, playing, or not found. Harness names
 * `watch.searching`, `watch.chooseAnother`, `watch.chooseCopy`, `watch.searchAgain`, and the mismatch's.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun MatchSection(match: WatchMatchUi, actions: RoomActions, onChoose: () -> Unit) {
    when (match) {
        is WatchMatchUi.Sharing -> CopySummary(match.copy)
        is WatchMatchUi.Searching -> ProgressLine(match.text, Modifier.layoutProbe("watch.searching", reportsFocus = false))
        is WatchMatchUi.Mismatch -> MismatchBlock(match.mismatch, actions, onChoose, showTitle = true)
        is WatchMatchUi.Playing -> Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            val copy = match.copy
            if (copy != null) CopySummary(copy, match.label) else Text(match.label, style = MaterialTheme.typography.bodyMedium)
            match.chooseAnother?.let { choose ->
                PlezyButton(choose, onChoose, Modifier.layoutProbe("watch.chooseAnother"), icon = PlezyIcons.SwapHoriz)
            }
        }
        is WatchMatchUi.Unavailable -> Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(match.title, style = MaterialTheme.typography.titleSmall)
            Muted(match.description)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                PlezyButton(match.choose, onChoose, Modifier.layoutProbe("watch.chooseCopy"), icon = PlezyIcons.VideoLibrary)
                PlezyButton(match.searchAgain, { actions.execute(WatchCommand.SearchAgain) }, Modifier.layoutProbe("watch.searchAgain"), icon = PlezyIcons.Refresh)
            }
        }
    }
}

/**
 * The closest copy differs in length: what that means, the copy, then Play Anyway (the primary one, [playFocus]),
 * Choose Another Copy ([onChoose]) and Don't Play, on as many lines as the width needs. [showTitle] off where the
 * sheet's title already says it (the player's prompt). Harness names `watch.playAnyway`, `watch.mismatchChoose`,
 * `watch.dontPlay`.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun MismatchBlock(mismatch: WatchMismatchUi, actions: RoomActions, onChoose: () -> Unit, showTitle: Boolean, playFocus: FocusRequester? = null) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (showTitle) Text(mismatch.title, style = MaterialTheme.typography.titleSmall)
        Muted(mismatch.description)
        CopySummary(mismatch.copy)
        FlowRow(Modifier.focusEntry(playFocus), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            PlezyButton(
                mismatch.playAnyway,
                { actions.execute(WatchCommand.PlayAnyway) },
                (if (playFocus != null) Modifier.focusRequester(playFocus) else Modifier).layoutProbe("watch.playAnyway"),
                style = ButtonStyle.PRIMARY,
                icon = PlezyIcons.PlayArrow,
            )
            PlezyButton(mismatch.chooseAnother, onChoose, Modifier.layoutProbe("watch.mismatchChoose"), icon = PlezyIcons.SwapHoriz)
            PlezyButton(mismatch.dontPlay, { actions.execute(WatchCommand.DontPlay) }, Modifier.layoutProbe("watch.dontPlay"), style = ButtonStyle.TEXT, icon = PlezyIcons.Block)
        }
    }
}

/** A copy: [label] (its own unless given), its title, then version, server and length. */
@Composable
private fun CopySummary(copy: WatchCopyUi, label: String? = copy.label) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        label?.let { Text(it, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant) }
        Text(copy.title, style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium))
        if (copy.details.isNotEmpty()) Text(copy.details, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/**
 * This user's offset from the room: the title with the value at its end (digits of one width, so a step moves only
 * them), what it is for, and its steps (-1 s to +1 s, then Reset, quieter) on as many lines as the width needs; then
 * the copy's length difference offered as the offset. A button keeps focus as it steps, so a remote presses it again.
 * A move into the steps lands on the one that had focus last, else the first ([focusEntry]). Harness names
 * `watch.offset`, `watch.offset.value`, `watch.offset.<i>`, `watch.offset.reset`, `watch.offset.apply`.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun OffsetControl(offset: WatchOffsetUi, actions: RoomActions, modifier: Modifier = Modifier) {
    val first = remember { FocusRequester() }
    Column(modifier.layoutProbe("watch.offset", reportsFocus = false), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(offset.title, style = MaterialTheme.typography.titleSmall, modifier = Modifier.weight(1f))
            Text(
                offset.value,
                style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                maxLines = 1,
                modifier = Modifier.layoutProbe("watch.offset.value", reportsFocus = false),
            )
        }
        Text(offset.description, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        FlowRow(Modifier.focusEntry(first), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            offset.steps.forEachIndexed { index, step ->
                PlezyButton(
                    step.label,
                    { actions.execute(WatchCommand.SetOffset(step.offsetMs)) },
                    (if (index == 0) Modifier.focusRequester(first) else Modifier).layoutProbe("watch.offset.$index"),
                    enabled = step.enabled,
                )
            }
            PlezyButton(
                offset.reset.label,
                { actions.execute(WatchCommand.SetOffset(offset.reset.offsetMs)) },
                Modifier.layoutProbe("watch.offset.reset"),
                style = ButtonStyle.TEXT,
                enabled = offset.reset.enabled,
            )
        }
        val hint = offset.hint
        val apply = offset.apply
        if (hint != null && apply != null) {
            Text(hint, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            PlezyButton(
                apply.label,
                { actions.execute(WatchCommand.SetOffset(apply.offsetMs)) },
                Modifier.layoutProbe("watch.offset.apply"),
                icon = PlezyIcons.Tune,
                enabled = apply.enabled,
            )
        }
    }
}

/** The host's room settings under their title: who controls playback, then the lock. */
@Composable
private fun HostSettings(settings: WatchHostSettingsUi, actions: RoomActions) {
    Column {
        GroupHeader(settings.title)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            ControlModeSelector(settings.everyone) { actions.execute(WatchCommand.SetEveryoneControls(it)) }
            LockSwitch(settings.lock) { actions.execute(WatchCommand.Lock(it)) }
        }
    }
}

/**
 * The host's choice of who controls playback: a chip per way, the room's selected, side by side where they fit.
 * Choosing the room's own way again does nothing.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ControlModeSelector(everyone: WatchToggleUi, onSelect: (everyone: Boolean) -> Unit) {
    val text = T.watchTogether
    FlowRow(Modifier.padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        PlezyChip(
            text.hostControlsPlayback,
            selected = !everyone.checked,
            onClick = { if (everyone.checked) onSelect(false) },
            modifier = Modifier.layoutProbe("watch.control.host"),
            leadingIcon = PlezyIcons.Lock,
            tab = true,
        )
        PlezyChip(
            text.anyoneCanControl,
            selected = everyone.checked,
            onClick = { if (!everyone.checked) onSelect(true) },
            modifier = Modifier.layoutProbe("watch.control.everyone"),
            leadingIcon = PlezyIcons.Groups,
            tab = true,
        )
    }
}

/** The host's lock: a switch row (the whole row is the control) with what locking means. Harness name `watch.lock`. */
@Composable
private fun LockSwitch(lock: WatchToggleUi, onLock: (Boolean) -> Unit) {
    PlezyToggleSurface(lock.checked, onLock, Modifier.fillMaxWidth().layoutProbe("watch.lock"), shape = MaterialTheme.shapes.large) {
        Row(
            Modifier.heightIn(min = 56.dp).padding(start = 16.dp, end = 12.dp, top = 10.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Icon(PlezyIcons.Lock, contentDescription = null, Modifier.size(22.dp), tint = PlezyColors.MutedContent)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(lock.label, style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium))
                Text(lock.detail, style = MaterialTheme.typography.bodySmall, color = PlezyColors.MutedContent)
            }
            RowSwitch(lock.checked)
        }
    }
}

/**
 * A participant: the initial in a round avatar, the name with the host badge (someone else's name reads in the
 * direction of its first letter, the user's own, an app string, in the interface's), and their app, connection,
 * player, match and offset (in the error colour once disconnected); for the host, Make host and Remove, each asked
 * first.
 */
@Composable
private fun ParticipantRow(participant: ParticipantUi, index: Int, count: Int, actions: RoomActions, focus: FocusMemory) {
    val probe = "watch.participant.${participant.peerId}"
    Row(
        Modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .background(PlezyColors.SurfaceHigh, groupShape(index, count))
            .padding(start = 12.dp, end = 8.dp, top = 8.dp, bottom = 8.dp)
            .layoutProbe(probe, reportsFocus = false),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(36.dp).background(PlezyColors.SurfaceHighest, CircleShape), contentAlignment = Alignment.Center) {
            Text(initial(participant.name), style = MaterialTheme.typography.titleMedium)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                val nameStyle = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium)
                Text(
                    participant.name,
                    style = if (participant.isYou) nameStyle else nameStyle.contentDirection(),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
                participant.hostBadge?.let { HostBadge(it, Modifier.layoutProbe("$probe.host", reportsFocus = false)) }
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                val color = if (participant.connected) MaterialTheme.colorScheme.onSurfaceVariant else PlezyColors.Error
                if (!participant.connected) Icon(PlezyIcons.ErrorOutline, contentDescription = null, Modifier.size(16.dp), tint = color)
                Text(participant.details, style = MaterialTheme.typography.bodySmall, color = color)
            }
        }
        participant.actions?.let { hostActions ->
            ConfirmButton(hostActions.makeHost, "$probe.makeHost", focus, onConfirm = { actions.execute(WatchCommand.MakeHost(participant.peerId)) }) { open, modifier ->
                PlezyButton(hostActions.makeHost.label, open, modifier, style = ButtonStyle.TEXT)
            }
            ConfirmButton(hostActions.remove, "$probe.kick", focus, onConfirm = { actions.execute(WatchCommand.Kick(participant.peerId)) }) { open, modifier ->
                PlezyIconButton(PlezyIcons.RemoveCircle, hostActions.remove.label, open, modifier, style = IconButtonStyle.PLAIN)
            }
        }
    }
}

/** A name's first letter (the whole of a letter written with two UTF-16 units), upper case. */
private fun initial(name: String): String {
    if (name.isEmpty()) return ""
    val length = if (name.length > 1 && name[0].isHighSurrogate()) 2 else 1
    return name.substring(0, length).uppercase()
}

/** "HOST": a small label in the primary fill, beside the host's name and on the host's room pill in the player. */
@Composable
internal fun HostBadge(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        modifier = modifier.background(MaterialTheme.colorScheme.primary, MaterialTheme.shapes.extraSmall).padding(horizontal = 6.dp, vertical = 1.dp),
        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
        color = PlezyColors.OnPrimary,
        maxLines = 1,
    )
}

/**
 * Leave Room, and for the host End Room beside it, on as many lines as the width needs. A move into them lands on the
 * one that had focus last, else Leave ([focusEntry]).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun RoomExits(room: WatchRoomUi, actions: RoomActions, focus: FocusMemory) {
    FlowRow(Modifier.focusEntry(focus.requester(LEAVE_PROBE)), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ConfirmButton(room.leave, LEAVE_PROBE, focus, onConfirm = { actions.execute(WatchCommand.Leave) }) { open, modifier ->
            PlezyButton(room.leave.label, open, modifier, style = ButtonStyle.DESTRUCTIVE, icon = PlezyIcons.Logout)
        }
        room.end?.let { end ->
            ConfirmButton(end, "watch.end", focus, onConfirm = { actions.execute(WatchCommand.End) }) { open, modifier ->
                PlezyButton(end.label, open, modifier, style = ButtonStyle.DESTRUCTIVE, icon = PlezyIcons.Close)
            }
        }
    }
}

/** Leave's harness name, also its key in the room's focus memory. */
private const val LEAVE_PROBE = "watch.leave"

/**
 * A control that asks first: [button] draws it (its modifier carries the harness name [probe] and its place in [focus];
 * pressing it opens the question), and [onConfirm] runs once answered yes ([ConfirmDialog]).
 */
@Composable
private fun ConfirmButton(
    confirm: WatchConfirmUi,
    probe: String,
    focus: FocusMemory,
    onConfirm: () -> Unit,
    button: @Composable (open: () -> Unit, modifier: Modifier) -> Unit,
) {
    var asking by remember { mutableStateOf(false) }
    button({ asking = true }, Modifier.rememberFocus(focus, probe).layoutProbe(probe))
    if (asking) {
        ConfirmDialog(
            confirm.question,
            confirm.message,
            confirm.confirm,
            onConfirm = {
                asking = false
                onConfirm()
            },
            onCancel = { asking = false },
            probe = probe,
            destructive = confirm.destructive,
            cancelLabel = confirm.cancel,
        )
    }
}

/**
 * Choose a Copy, a sheet: this user's copies, closest length first (a check on the one playing; the details wrap, the
 * length difference ending them); none found or the search that runs; Search Again. A pick plays it for the room, and
 * the sheet closes ([onClose]) once the room took it ([WatchCopiesUi.chosen] grew); a pick the room refused leaves it
 * open (the store says why). Back and a tap outside close it. Harness names `watch.copies`, `watch.candidate.<i>`,
 * `watch.copies.searchAgain`.
 */
@Composable
internal fun CopiesSheet(copies: WatchCopiesUi, actions: RoomActions, onClose: () -> Unit) {
    // The count of copies taken when this sheet's pick went out; null before one.
    var picked by remember { mutableStateOf<Int?>(null) }
    val chosen = copies.chosen
    LaunchedEffect(chosen) {
        val at = picked ?: return@LaunchedEffect
        if (chosen > at) {
            picked = null
            onClose()
        }
    }
    PlezySheet(onDismiss = onClose, title = copies.title, probe = "watch.copies") {
        Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(vertical = LocalPlezyDimens.current.focusReach)) {
            copies.rows.forEachIndexed { index, row ->
                SheetOption(
                    row.title,
                    {
                        picked = chosen
                        actions.execute(WatchCommand.ChooseCopy(row.id))
                    },
                    Modifier.layoutProbe("watch.candidate.$index"),
                    selected = row.current,
                    detail = row.subtitle,
                    icon = PlezyIcons.Movie,
                    choice = false,
                    contentLabel = true,
                )
            }
            copies.empty?.let { Text(it, Modifier.padding(horizontal = 16.dp, vertical = 8.dp), style = MaterialTheme.typography.bodyMedium) }
            copies.searching?.let { ProgressLine(it, Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) }
            PlezyButton(
                copies.searchAgain,
                { actions.execute(WatchCommand.SearchAgain) },
                Modifier.padding(horizontal = 16.dp, vertical = 8.dp).layoutProbe("watch.copies.searchAgain"),
                icon = PlezyIcons.Refresh,
                enabled = copies.searchAgainEnabled,
            )
        }
    }
}

/** One-off messages ("Room code copied"), one at a time: a new one replaces the one showing. */
@Stable
internal class WatchToasts {
    private class Toast(val text: String, val serial: Int)

    private var current by mutableStateOf<Toast?>(null)
    private var serial = 0

    fun show(text: String) {
        current = Toast(text, ++serial)
    }

    /** Over every sheet and dialog, at the window's foot ([bottom] above it), while one shows. Harness name `watch.toast`. */
    @Composable
    fun Host(bottom: Dp = 88.dp) {
        val toast = current ?: return
        TopOverlay(focus = null, onBack = {}) {
            Box(Modifier.fillMaxSize().padding(bottom = bottom, start = 16.dp, end = 16.dp), contentAlignment = Alignment.BottomCenter) {
                key(toast.serial) { TimedToast(toast.text, "watch.toast", onShown = { if (current === toast) current = null }) }
            }
        }
    }
}
