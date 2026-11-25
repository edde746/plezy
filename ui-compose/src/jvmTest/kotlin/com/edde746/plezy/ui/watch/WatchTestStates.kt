package com.edde746.plezy.ui.watch

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.watch.JoinRoomUi
import com.edde746.plezy.presentation.watch.ParticipantActionsUi
import com.edde746.plezy.presentation.watch.ParticipantUi
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import com.edde746.plezy.presentation.watch.RecentRoomActionsUi
import com.edde746.plezy.presentation.watch.RecentRoomUi
import com.edde746.plezy.presentation.watch.WatchActionUi
import com.edde746.plezy.presentation.watch.WatchBannerUi
import com.edde746.plezy.presentation.watch.WatchCandidateUi
import com.edde746.plezy.presentation.watch.WatchConfirmUi
import com.edde746.plezy.presentation.watch.WatchCopiesUi
import com.edde746.plezy.presentation.watch.WatchCopyUi
import com.edde746.plezy.presentation.watch.WatchHeaderUi
import com.edde746.plezy.presentation.watch.WatchHostSettingsUi
import com.edde746.plezy.presentation.watch.WatchLobbyUi
import com.edde746.plezy.presentation.watch.WatchMatchUi
import com.edde746.plezy.presentation.watch.WatchMediaUi
import com.edde746.plezy.presentation.watch.WatchMismatchUi
import com.edde746.plezy.presentation.watch.WatchOffsetStepUi
import com.edde746.plezy.presentation.watch.WatchOffsetUi
import com.edde746.plezy.presentation.watch.WatchPillUi
import com.edde746.plezy.presentation.watch.WatchPlayBlockedUi
import com.edde746.plezy.presentation.watch.WatchRoomUi
import com.edde746.plezy.presentation.watch.WatchScreenContent
import com.edde746.plezy.presentation.watch.WatchToggleUi
import com.edde746.plezy.presentation.watch.WatchTogetherUiState
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import com.edde746.plezy.watch.WatchPartyRelays

/** The room code of the test rooms. */
internal const val TEST_CODE = "K7M-Q2X"

/** The lobby: no attempt running, [recent] rooms, the last attempt's [error]. */
internal fun testLobby(recent: List<RecentRoomUi> = emptyList(), error: String? = null, creating: Boolean = false) = WatchLobbyUi(
    description = "Watch content in sync with friends and family",
    create = if (creating) "Creating room..." else "Create Room",
    creating = creating,
    join = "Join Room",
    busy = creating,
    error = error,
    relay = "Rooms use the public Open Watch Party relays.",
    recentTitle = "Recent Rooms",
    recentRooms = recent,
    recentActions = RecentRoomActionsUi("Room actions", "Rename Room", "Remove", "Rename Room", "Cancel", "Save"),
)

internal fun testRecentRoom(code: String, name: String? = null): RecentRoomUi {
    val formatted = WatchPartyRelays.formatRoomCode(code)
    return RecentRoomUi(code, name ?: formatted, if (name != null) formatted else null, joining = false, name = name.orEmpty(), hint = formatted)
}

internal fun testJoin(text: String = "", error: String? = null, joining: Boolean = false) = JoinRoomUi(
    title = "Join Room",
    prompt = "Enter the 6-character code from the host.",
    fieldLabel = "Room Code",
    hint = "K7M-Q2X",
    text = text,
    caret = text.length,
    error = error,
    joining = joining,
    cancel = "Cancel",
    join = if (joining) "Joining room..." else "Join Room",
)

private fun confirm(label: String, question: String, confirm: String, destructive: Boolean) =
    WatchConfirmUi(label, question, "$question It can't be undone here.", confirm, "Cancel", destructive)

/** A participant: [you] reads "(You)", [host] wears the badge, [actions] the host's page for them. */
internal fun testParticipant(peerId: String, name: String, you: Boolean = false, host: Boolean = false, actions: Boolean = false) = ParticipantUi(
    peerId = peerId,
    name = if (you) "$name (You)" else name,
    isYou = you,
    hostBadge = if (host) "HOST" else null,
    connected = true,
    details = "Plezy · Connected · Idle",
    actions = if (actions) {
        ParticipantActionsUi(
            name,
            confirm("Make host", "Transfer host?", "Transfer", destructive = false),
            confirm("Remove from Room", "Remove $name?", "Remove", destructive = true),
        )
    } else {
        null
    },
)

internal val testCopy = WatchCopyUi(null, "Alien (1979)", "1080p H.264 · Home server · 1h 57m")

internal fun testMismatch(key: String = "1|g-alien") = WatchMismatchUi(
    key = key,
    title = "Your Copy Is a Different Length",
    description = "Your closest copy is 2m longer than the room's video. It may be another cut or version.",
    copy = testCopy,
    playAnyway = "Play Anyway",
    chooseAnother = "Choose Another Copy",
    dontPlay = "Don't Play",
)

/** The room's media: none, else Alien with [match]; [copies] the copies page's rows, [chosen] the copies the room took. */
internal fun testMedia(
    playing: Boolean,
    host: Boolean,
    match: WatchMatchUi? = null,
    joinPlayback: Boolean = false,
    copies: List<WatchCandidateUi> = emptyList(),
    chosen: Int = 0,
) = WatchMediaUi(
    heading = "Now Playing",
    title = if (playing) "Alien (1979)" else null,
    idle = "Nothing playing",
    idleDetail = if (host) "Play something from any library to share it with the room." else "When the host plays something, it opens here.",
    notShareable = null,
    match = match,
    summary = if (playing) "Your copy" else null,
    joinPlayback = if (joinPlayback) WatchActionUi("Join Current Playback", "Jump back into what the host is currently watching") else null,
    stop = if (playing && host) "Stop Video for Everyone" else null,
    copies = WatchCopiesUi(
        "Choose a Copy",
        copies,
        if (copies.isEmpty()) "No copies found in your libraries." else null,
        null,
        "Search Again",
        searchAgainEnabled = true,
        chosen = chosen,
    ),
)

internal fun testOffset(offsetMs: Long = 0) = WatchOffsetUi(
    title = "Sync Offset",
    value = if (offsetMs == 0L) "0ms" else "${if (offsetMs > 0) "+" else ""}${offsetMs}ms",
    description = "Shift your video if it runs ahead of or behind the room.",
    steps = listOf(
        WatchOffsetStepUi("-1 s", offsetMs - 1000),
        WatchOffsetStepUi("-100 ms", offsetMs - 100),
        WatchOffsetStepUi("+100 ms", offsetMs + 100),
        WatchOffsetStepUi("+1 s", offsetMs + 1000),
    ),
    reset = WatchOffsetStepUi("Reset", 0, enabled = offsetMs != 0L),
    hint = null,
    apply = null,
)

/**
 * The room: Anna and Ben in it, [host] the user's view as Anna, the host (Ben's actions on his row), else as Ben, a
 * guest; [media] playing Alien, [reconnecting] while the connection is down.
 */
internal fun testRoom(host: Boolean = true, media: WatchMediaUi = testMedia(playing = false, host = host), reconnecting: Boolean = false) = WatchRoomUi(
    title = "Watch Together",
    reconnecting = if (reconnecting) WatchBannerUi("Reconnecting...", "The connection dropped. You rejoin the room automatically.") else null,
    header = WatchHeaderUi(
        codeLabel = "Room Code",
        code = TEST_CODE,
        copy = "Copy Code",
        copied = "Room code copied",
        share = "Share Invite",
        invite = "Join my Watch Together room in Plezy: open Watch Together, choose Join Room and enter $TEST_CODE.",
        invited = "Invite copied. Paste it into a message.",
        role = if (host) "You are the host" else "Hosted by Anna",
        control = if (host) null else "Host controls playback",
        locked = null,
    ),
    status = "Connected · 2 participants",
    media = media,
    offset = testOffset(),
    participantsTitle = "Participants",
    participantCount = "2 participants",
    participants = listOf(
        testParticipant("anna", "Anna", you = host, host = true),
        testParticipant("ben", "Ben", you = !host, actions = host),
    ),
    settings = if (host) {
        WatchHostSettingsUi(
            "Room Settings",
            WatchToggleUi("Let Everyone Control Playback", "Host controls playback", checked = false),
            WatchToggleUi("Lock Room", "Nobody new can join", checked = false),
        )
    } else {
        null
    },
    leave = confirm("Leave Room", "Leave Room?", "Leave", destructive = false),
    end = if (host) confirm("End Room", "End Room?", "End", destructive = true) else null,
    isHost = host,
)

/** The lobby with the store's join form open, as it opens with the lobby; [join] null before it has. */
internal fun lobbyState(lobby: WatchLobbyUi = testLobby(), join: JoinRoomUi? = testJoin()) =
    WatchTogetherUiState("Watch Together", WatchScreenContent.Lobby(lobby), join)

internal fun roomState(room: WatchRoomUi) = WatchTogetherUiState("Watch Together", WatchScreenContent.Room(room), null)

/** The player's view of [room]: connected, this user in control. */
internal fun testPlayerWatch(
    room: WatchRoomUi = testRoom(),
    mismatch: WatchMismatchUi? = null,
    playBlocked: Boolean = false,
    reconnecting: Boolean = false,
) = PlayerWatchUi(
    pill = WatchPillUi("2", connected = !reconnecting, isHost = room.isHost, status = if (reconnecting) "Reconnecting..." else null, label = "Open Watch Together session controls", value = "2 participants, Connected"),
    reconnecting = if (reconnecting) "Reconnecting..." else null,
    playBlocked = if (playBlocked) WatchPlayBlockedUi("Playback didn't start", "Press play to start watching with the room.", "Play") else null,
    mismatch = mismatch,
    room = room,
    canControl = true,
    canChangeEpisode = true,
    controlsLocked = null,
    following = true,
    roomRate = 1.0,
    pausedHere = false,
    atMediaEnd = false,
)

/** The screen's requests, as they come. */
internal class RecordingActions : WatchScreenActions {
    val calls = mutableListOf<String>()

    override fun create() {
        calls += "create"
    }

    override fun openJoin() {
        calls += "openJoin"
    }

    override fun joinRecent(code: String) {
        calls += "joinRecent:$code"
    }

    override fun renameRecent(code: String, name: String) {
        calls += "rename:$code:$name"
    }

    override fun removeRecent(code: String) {
        calls += "remove:$code"
    }

    override fun cancel() {
        calls += "cancel"
    }

    override fun editJoin(text: String, caret: Int) {
        calls += "edit:$text"
    }

    override fun submitJoin() {
        calls += "submit"
    }

    override fun execute(command: WatchCommand) {
        calls += "execute:$command"
    }
}

/** A clipboard of the test's own. */
@Suppress("DEPRECATION")
internal class TestClipboard(var text: String? = null) : ClipboardManager {
    override fun getText(): AnnotatedString? = text?.let(::AnnotatedString)

    override fun setText(annotatedString: AnnotatedString) {
        text = annotatedString.text
    }
}

/** The system's back (Android's, a remote's) through [dispatcher], as the app's window gets it. */
internal class SystemBack {
    val dispatcher = NavigationEventDispatcher()
    private val input = DirectNavigationEventInput().also { dispatcher.addInput(it) }

    fun press() = input.backCompleted()
}

/**
 * The Watch Together screen on a [formFactor] window (a phone's 411 × 900 dp, else 960 × 540 dp) with the app's overlay
 * host and arrow-key focus, showing [state]; the app's own back under it records "screen back" in [actions], the
 * header's back button "header back".
 */
@OptIn(ExperimentalTestApi::class)
@Suppress("DEPRECATION")
internal fun ComposeUiTest.watchScreen(
    formFactor: FormFactor,
    actions: RecordingActions,
    back: SystemBack = SystemBack(),
    probe: LayoutProbe? = null,
    clipboard: TestClipboard = TestClipboard(),
    state: () -> WatchTogetherUiState,
) = setContent {
    WatchFrame(formFactor, back, probe, clipboard) {
        // The app's own back (the navigation's), registered first: a dialog's or a sheet's comes before it.
        SystemBackHandler { actions.calls += "screen back" }
        val toasts = remember { WatchToasts() }
        WatchTogetherScreen(state(), actions, toasts, onBack = { actions.calls += "header back" })
    }
}

/** The app's frame for a watch view: theme, layout, overlay host, the window's back and the app's own back handler. */
@Suppress("DEPRECATION")
@Composable
internal fun WatchFrame(formFactor: FormFactor, back: SystemBack, probe: LayoutProbe?, clipboard: TestClipboard, content: @Composable () -> Unit) {
    val owner = remember {
        object : NavigationEventDispatcherOwner {
            override val navigationEventDispatcher = back.dispatcher
        }
    }
    val size = if (formFactor == FormFactor.HANDHELD) DpSize(411.dp, 900.dp) else DpSize(960.dp, 540.dp)
    CompositionLocalProvider(
        LocalNavigationEventDispatcherOwner provides owner,
        LocalLayoutProbe provides probe,
        LocalClipboardManager provides clipboard,
    ) {
        PlezyTheme {
            Box(Modifier.size(size)) {
                AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) {
                    OverlayHostBox { content() }
                }
            }
        }
    }
}

/**
 * Runs the control's click as a screen reader's activation does, wherever the page has scrolled it: the control at the
 * foot of a room sits below a test window's fold.
 */
internal fun SemanticsNodeInteraction.choose(): SemanticsNodeInteraction = performSemanticsAction(SemanticsActions.OnClick)
