package com.edde746.plezy.presentation.watch

import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.log.Log
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import com.edde746.plezy.watch.RecentRoom
import com.edde746.plezy.watch.WatchLabels
import com.edde746.plezy.watch.WatchPartyRelays
import com.edde746.plezy.watch.WatchSnapshot
import com.edde746.plezy.watch.WatchTogether
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import party.openwatch.Connection
import party.openwatch.PartyException

/**
 * The Watch Together screen: the lobby (Create Room, Join Room with its dialog, the relay rooms use, recent rooms with
 * rename and remove), the connecting view (Cancel), and the room ([WatchRoomUi], its actions through [execute]).
 *
 * A create, join or recent join runs on [scope] (it goes on if the screen goes, as the room does), and its failure shows
 * in the lobby's error card or the join dialog. [messages] are the screen's own snackbars; the room's notices show
 * app-wide ([com.edde746.plezy.app.AppSession.watchNotices]). Main thread only; [close] when the screen goes.
 */
class WatchTogetherStore internal constructor(
    private val watch: WatchTogether,
    private val scope: CoroutineScope,
) {
    private val jobs = scope.childScope()
    private val mutableMessages = MutableSharedFlow<String>(extraBufferCapacity = MESSAGE_BUFFER)
    private val actions = WatchActions(watch, scope) { mutableMessages.tryEmit(it) }
    private var recent: List<RecentRoom> = emptyList()

    /** What this screen keeps of its own; each change shows at once (a field's text and caret can't lag a frame). */
    private var local = Local()
        set(value) {
            field = value
            rebuild()
        }

    /**
     * The create or join this screen started: null, `""` for a create, or the recent room's code; [error] the lobby's
     * error card; [join] the join dialog while open.
     */
    private data class Local(val attempt: String? = null, val error: String? = null, val join: JoinState? = null)

    private data class JoinState(val text: String = "", val caret: Int = 0, val error: String? = null, val joining: Boolean = false)

    private val mutableState = MutableStateFlow(build(watch.state.value, recent, local))

    val state: StateFlow<WatchTogetherUiState> = mutableState.asStateFlow()

    init {
        jobs.launch(start = CoroutineStart.UNDISPATCHED) { watch.state.collect { rebuild() } }
        jobs.launch(start = CoroutineStart.UNDISPATCHED) {
            watch.observeRecentRooms().collect {
                recent = it
                rebuild()
            }
        }
    }

    private fun rebuild() {
        mutableState.value = build(watch.state.value, recent, local)
    }

    /** Snackbars of the screen's own: a copy that couldn't be chosen. */
    val messages: Flow<String> = mutableMessages.asSharedFlow()

    /** Creates a room and joins it as host. */
    fun create() = run("") { watch.createRoom() }

    /** Joins the recent room [code], or makes it again under its code when nobody is in it. */
    fun joinRecent(code: String) = run(code) { watch.joinRoom(code, create = true) }

    /** Cancels the create or join under way (the connecting view's Cancel). */
    fun cancel() = watch.leave()

    private fun run(attempt: String, action: suspend () -> Unit) {
        if (local.attempt != null) return
        local = local.copy(attempt = attempt, error = null)
        scope.launch {
            val error = try {
                action()
                null
            } catch (e: PartyException) {
                if (e.code == PartyException.CANCELLED) null else WatchLabels.errorText(e.code)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "room attempt failed" }
                T.watchTogether.errors.generic
            }
            local = local.copy(attempt = null, error = error)
        }
    }

    fun renameRecent(code: String, name: String) {
        scope.launch { watch.renameRecentRoom(code, name) }
    }

    fun removeRecent(code: String) {
        scope.launch { watch.removeRecentRoom(code) }
    }

    /** Runs a room control's command. */
    fun execute(command: WatchCommand) = actions.run(command)

    // The join dialog

    /** Opens the join dialog; the lobby's error goes. */
    fun openJoin() {
        local = local.copy(error = null, join = JoinState())
    }

    /**
     * The field after an edit: upper case, letters and digits only, 6 at most, `K7M-Q2X`; [caret] (in [text]) stays
     * after the same number of symbols. Editing clears the error.
     */
    fun editJoin(text: String, caret: Int = text.length) {
        val join = local.join ?: return
        val typed = WatchPartyRelays.typedRoomCode(text, caret)
        local = local.copy(join = join.copy(text = typed.text, caret = typed.caret, error = null))
    }

    /**
     * Joins the room of the field's code: a code that can't be one is refused in the dialog without asking the relay;
     * a typed code never makes a room, so a typo says no room has it. Joined, the dialog closes.
     */
    fun submitJoin() {
        val join = local.join ?: return
        if (join.joining) return
        val code = WatchPartyRelays.normalizeRoomCode(join.text)
        if (code == null) {
            local = local.copy(join = join.copy(error = WatchLabels.errorText(PartyException.INVALID_CODE)))
            return
        }
        local = local.copy(join = join.copy(joining = true, error = null))
        scope.launch {
            try {
                watch.joinRoom(code)
                local = local.copy(join = null)
            } catch (e: PartyException) {
                val open = local.join ?: return@launch
                val error = if (e.code == PartyException.CANCELLED) open.error else WatchLabels.errorText(e.code)
                local = local.copy(join = open.copy(joining = false, error = error))
            }
        }
    }

    /** The dialog went (Cancel, Back, a tap outside): a join under way is cancelled, so the user isn't put in the room. */
    fun closeJoin() {
        val join = local.join ?: return
        local = local.copy(join = null)
        if (join.joining) watch.leave()
    }

    fun close() {
        jobs.cancel()
    }

    private fun build(s: WatchSnapshot, recent: List<RecentRoom>, local: Local): WatchTogetherUiState {
        val text = T.watchTogether
        val content = when (s.connection) {
            Connection.CONNECTED, Connection.RECONNECTING -> WatchScreenContent.Room(WatchRoomText.room(s))
            Connection.CONNECTING -> WatchScreenContent.Connecting(
                label = when (local.attempt) {
                    null -> text.connecting
                    "" -> text.creatingRoom
                    else -> text.joiningRoom
                },
                cancel = T.common.cancel,
            )
            Connection.IDLE, Connection.ENDED -> WatchScreenContent.Lobby(lobby(s, recent, local))
        }
        return WatchTogetherUiState(title = text.title, content = content, join = local.join?.let(::join))
    }

    private fun lobby(s: WatchSnapshot, recent: List<RecentRoom>, local: Local): WatchLobbyUi {
        val text = T.watchTogether
        val creating = local.attempt == ""
        return WatchLobbyUi(
            description = text.description,
            create = if (creating) text.creatingRoom else text.createRoom,
            creating = creating,
            join = text.joinRoom,
            busy = local.attempt != null,
            error = local.error,
            relay = s.relayBaseUrl?.let(text::relayCustom) ?: text.relayPublic,
            recentTitle = text.recentRooms,
            recentRooms = recent.map { room ->
                val code = WatchPartyRelays.formatRoomCode(room.code)
                RecentRoomUi(
                    code = room.code,
                    title = room.name ?: code,
                    subtitle = if (room.name != null) code else null,
                    joining = local.attempt == room.code,
                    name = room.name.orEmpty(),
                    hint = code,
                )
            },
            recentActions = RecentRoomActionsUi(text.roomActions, text.renameRoom, text.removeRoom, text.renameRoom, T.common.cancel, T.common.save),
        )
    }

    private fun join(join: JoinState): JoinRoomUi {
        val text = T.watchTogether
        return JoinRoomUi(
            title = text.joinRoom,
            prompt = text.enterRoomCode,
            fieldLabel = text.roomCode,
            hint = HINT,
            text = join.text,
            caret = join.caret,
            error = join.error,
            joining = join.joining,
            cancel = T.common.cancel,
            join = if (join.joining) text.joiningRoom else text.joinRoom,
        )
    }

    private companion object {
        const val TAG = "WatchTogether"
        const val MESSAGE_BUFFER = 8
        const val HINT = "K7M-Q2X"
    }
}
