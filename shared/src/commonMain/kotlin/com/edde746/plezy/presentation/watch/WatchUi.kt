// The `copy` properties have other names in Swift, where NSObject's copy() hides them.
@file:OptIn(ExperimentalObjCName::class)

package com.edde746.plezy.presentation.watch

import com.edde746.plezy.input.WatchCommand
import kotlin.experimental.ExperimentalObjCName
import kotlin.native.ObjCName

/**
 * The Watch Together screen ([WatchTogetherStore]): [title] over [content], which follows the connection (idle or ended:
 * the lobby; connecting: the connecting view; connected or reconnecting: the room), and the join dialog while it is
 * open ([join]). Content max width 640.
 */
data class WatchTogetherUiState(
    val title: String,
    val content: WatchScreenContent,
    val join: JoinRoomUi?,
)

/** What the screen shows ([WatchTogetherUiState.content]). */
sealed interface WatchScreenContent {
    data class Lobby(val lobby: WatchLobbyUi) : WatchScreenContent

    /** A create or join under way: [label] ("Creating room…", "Joining room…", "Connecting…") and [cancel] ([WatchTogetherStore.cancel]). */
    data class Connecting(val label: String, val cancel: String) : WatchScreenContent

    data class Room(val room: WatchRoomUi) : WatchScreenContent
}

/**
 * The lobby: [description]; [create] ("Create Room", "Creating room…" with a spinner while [creating]); [join] opens
 * the join dialog ([WatchTogetherStore.openJoin]); both disabled while [busy] (any attempt runs). [error] the last
 * create or recent join's failure, in an error card above the buttons. [relay] names the relays rooms use. [recentRooms]
 * under [recentTitle], shown only when not empty (a profile with rooms on this relay).
 */
data class WatchLobbyUi(
    val description: String,
    val create: String,
    val creating: Boolean,
    val join: String,
    val busy: Boolean,
    val error: String?,
    val relay: String,
    val recentTitle: String,
    val recentRooms: List<RecentRoomUi>,
    val recentActions: RecentRoomActionsUi,
)

/**
 * A recent room: tap joins it ([WatchTogetherStore.joinRecent]), making it again when it ended. [title] its name or the
 * formatted code; [subtitle] the formatted code when it has a name; [joining] while that join runs (a spinner for the
 * icon). [name] prefills the rename field, [hint] (the formatted code) is its placeholder.
 */
data class RecentRoomUi(
    val code: String,
    val title: String,
    val subtitle: String?,
    val joining: Boolean,
    val name: String,
    val hint: String,
)

/**
 * The labels of a recent room's actions (its ⋮ button [menuLabel], a long press, a held Select): [rename] opens the
 * rename dialog ([renameTitle], [save] submits [WatchTogetherStore.renameRecent], a blank name clears it), [remove]
 * (destructive) calls [WatchTogetherStore.removeRecent].
 */
data class RecentRoomActionsUi(
    val menuLabel: String,
    val rename: String,
    val remove: String,
    val renameTitle: String,
    val cancel: String,
    val save: String,
)

/**
 * The join dialog: [title], [prompt], the code field ([fieldLabel], [hint] `K7M-Q2X`, [text] and [caret] as the store
 * formatted them, [WatchTogetherStore.editJoin]); [error] under it; while [joining] the field and [join] are disabled
 * and [join] reads "Joining room…"; the dialog closes itself once joined (the state's join goes null). Cancel or Back
 * while joining cancels the join ([WatchTogetherStore.closeJoin]).
 */
data class JoinRoomUi(
    val title: String,
    val prompt: String,
    val fieldLabel: String,
    val hint: String,
    val text: String,
    val caret: Int,
    val error: String?,
    val joining: Boolean,
    val cancel: String,
    val join: String,
)

/**
 * The room, as the screen stacks it in cards and the player's session sheet gives each part a row or a page.
 *
 * @param reconnecting the banner while the connection is down.
 * @param status the sheet's code row subtitle: "Connected · 3 participants".
 * @param offset the offset card; the screen shows it only with [WatchMediaUi.title] set.
 * @param settings the host's room settings; null for a guest.
 * @param leave Leave Room, asked first; [end] End Room (the host's), asked first.
 */
data class WatchRoomUi(
    val title: String,
    val reconnecting: WatchBannerUi?,
    val header: WatchHeaderUi,
    val status: String,
    val media: WatchMediaUi,
    val offset: WatchOffsetUi,
    val participantsTitle: String,
    val participantCount: String,
    val participants: List<ParticipantUi>,
    val settings: WatchHostSettingsUi?,
    val leave: WatchConfirmUi,
    val end: WatchConfirmUi?,
    val isHost: Boolean,
)

/** "Reconnecting…" with what happens meanwhile. */
data class WatchBannerUi(val title: String, val description: String)

/**
 * The room code ([code], `K7M-Q2X`) under [codeLabel]; [copy] puts [code] on the clipboard and shows [copied]; [share]
 * puts [invite] there and shows [invited]. [role] "You are the host" or "Hosted by Sam" (blank while the host isn't
 * known); [control] who controls playback, for a guest (null for the host, whose setting says it); [locked] "Room
 * locked" while it is.
 */
data class WatchHeaderUi(
    val codeLabel: String,
    val code: String,
    @ObjCName("copyLabel") val copy: String,
    val copied: String,
    val share: String,
    val invite: String,
    val invited: String,
    val role: String,
    val control: String?,
    val locked: String?,
)

/**
 * Now Playing ([heading]): [title] the room's media in one line, null for nothing playing ([idle], [idleDetail] say so).
 * [notShareable] notes a video without catalogue identity. [match] this user's file; [summary] it in one line (the
 * sheet's media row). [joinPlayback] offers the room's file to one not watching it ([WatchCommand.JoinPlayback]); [stop]
 * is the host's Stop Video for Everyone ([WatchCommand.StopMedia]). [copies] the Choose a Copy page.
 */
data class WatchMediaUi(
    val heading: String,
    val title: String?,
    val idle: String,
    val idleDetail: String,
    val notShareable: String?,
    val match: WatchMatchUi?,
    val summary: String?,
    val joinPlayback: WatchActionUi?,
    val stop: String?,
    val copies: WatchCopiesUi,
)

/** A labelled action with what it is for: [label], [description]. */
data class WatchActionUi(val label: String, val description: String)

/** This user's file for the room's media. */
sealed interface WatchMatchUi {
    /** The room plays this user's own shared file. */
    data class Sharing(@ObjCName("copyUi") val copy: WatchCopyUi) : WatchMatchUi

    /** Looking for it in the libraries: a spinner with [text]. */
    data class Searching(val text: String) : WatchMatchUi

    /** The closest copy differs in length: the user decides. */
    data class Mismatch(val mismatch: WatchMismatchUi) : WatchMatchUi

    /**
     * Playing a copy: [label] "Your copy" or "Playing your copy, 2m longer", [copy] its summary when known;
     * [chooseAnother] ("Choose Another Copy") while there is more than one.
     */
    data class Playing(val label: String, @ObjCName("copyUi") val copy: WatchCopyUi?, val chooseAnother: String?) : WatchMatchUi

    /**
     * Nothing found: [title] (or that some server couldn't be searched), [description], [choose] opens the copies page,
     * [searchAgain] ([WatchCommand.SearchAgain]).
     */
    data class Unavailable(val title: String, val description: String, val choose: String, val searchAgain: String) : WatchMatchUi
}

/** A copy: [label] over its [title], then [details] (version · server · length), empty when none is known. */
data class WatchCopyUi(val label: String?, val title: String, val details: String)

/**
 * The closest copy differs in length ([title], [description]), the offered [copy]; Play Anyway ([WatchCommand.PlayAnyway],
 * focused first), Choose Another Copy (the copies page), Don't Play ([WatchCommand.DontPlay]). [key] names this
 * mismatch: the player asks once per key, and its prompt closes once the key changes.
 */
data class WatchMismatchUi(
    val key: String,
    val title: String,
    val description: String,
    @ObjCName("copyUi") val copy: WatchCopyUi,
    val playAnyway: String,
    val chooseAnother: String,
    val dontPlay: String,
)

/**
 * The Choose a Copy page ([title]): [rows] closest length first ([WatchCommand.ChooseCopy]); [empty] when there are none
 * and no search runs; [searching] while one does; [searchAgain] ([WatchCommand.SearchAgain]), enabled unless searching.
 * [chosen] counts the copies the room took from this user's choices: the page closes once it grows past its value at
 * the tap; a choice the room refused leaves it and says so.
 */
data class WatchCopiesUi(
    val title: String,
    val rows: List<WatchCandidateUi>,
    val empty: String?,
    val searching: String?,
    val searchAgain: String,
    val searchAgainEnabled: Boolean,
    val chosen: Int,
)

/** A copy to pick: [title], [subtitle] its details and length difference, [current] the one playing (a check). */
data class WatchCandidateUi(val id: String, val title: String, val subtitle: String, val current: Boolean)

/**
 * Sync Offset ([title]) at [value] ("+200ms"), [description]; [steps] -1 s, -100 ms, +100 ms, +1 s and [reset] each set
 * the offset ([WatchCommand.SetOffset]). [hint] and [apply] offer the copy's length difference as the offset.
 */
data class WatchOffsetUi(
    val title: String,
    val value: String,
    val description: String,
    val steps: List<WatchOffsetStepUi>,
    val reset: WatchOffsetStepUi,
    val hint: String?,
    val apply: WatchOffsetStepUi?,
)

/** An offset button: [label], the offset it sets ([offsetMs]), disabled unless [enabled]. */
data class WatchOffsetStepUi(val label: String, val offsetMs: Long, val enabled: Boolean = true)

/**
 * A participant: [name] ("Sam", "Anna (You)"), [hostBadge] ("HOST") on the host, [connected] (the person icon, or the
 * crossed-out one), [details] app · connection · player · match · offset. [actions] the host's page for them; null for
 * a guest's view and for the host's own row.
 */
data class ParticipantUi(
    val peerId: String,
    val name: String,
    val isYou: Boolean,
    val hostBadge: String?,
    val connected: Boolean,
    val details: String,
    val actions: ParticipantActionsUi?,
)

/** The host's actions on one participant, titled with their name: Make host ([WatchCommand.MakeHost]) and Remove ([WatchCommand.Kick]), each asked first. */
data class ParticipantActionsUi(val title: String, val makeHost: WatchConfirmUi, val remove: WatchConfirmUi)

/** A button that asks first: [label], then [question] and [message] with [confirm] (drawn destructive when [destructive]) and [cancel]. */
data class WatchConfirmUi(
    val label: String,
    val question: String,
    val message: String,
    val confirm: String,
    val cancel: String,
    val destructive: Boolean,
)

/** The host's room settings ([title]): who controls playback ([WatchCommand.SetEveryoneControls]) and the lock ([WatchCommand.Lock]). */
data class WatchHostSettingsUi(val title: String, val everyone: WatchToggleUi, val lock: WatchToggleUi)

/** A switch: [label], [detail], on when [checked]. */
data class WatchToggleUi(val label: String, val detail: String, val checked: Boolean)

/**
 * Watch Together in the player, while in a room.
 *
 * @param pill the header's room pill, which opens the session sheet ([PlayerMenu.WATCH_TOGETHER][com.edde746.plezy.input.PlayerMenu.WATCH_TOGETHER]).
 * @param reconnecting "Reconnecting…" over the video while the connection is down.
 * @param playBlocked the player refused to start in a playing room: its prompt card (hidden in picture in picture).
 * @param mismatch the room offers a copy of another length: the player opens its prompt once per [WatchMismatchUi.key]
 *   when no other sheet is open, and closes it once the key changes.
 * @param room the session sheet and its pages.
 * @param canControl play, pause, seek and speed are this user's to change: false while the room drives this player for
 *   a guest of a host-only room, whose controls show disabled.
 * @param canChangeEpisode another item is this user's to start: the host's only while the room drives the player.
 * @param controlsLocked what a refused press shows: "Only the host can control playback".
 * @param following the room drives this player: the speed shown is the room's ([roomRate]).
 * @param pausedHere the player paused on this device alone, out of the room's playback, which plays on (a guest's call,
 *   its audio output gone, its sleep timer): play/pause stays enabled, and Play catches up with the room.
 * @param atMediaEnd the room drives this player and its media is at its end
 *   ([WatchSnapshot.atMediaEnd][com.edde746.plezy.watch.WatchSnapshot.atMediaEnd]): the item is over here, wherever this
 *   file stands.
 */
data class PlayerWatchUi(
    val pill: WatchPillUi,
    val reconnecting: String?,
    val playBlocked: WatchPlayBlockedUi?,
    val mismatch: WatchMismatchUi?,
    val room: WatchRoomUi,
    val canControl: Boolean,
    val canChangeEpisode: Boolean,
    val controlsLocked: String?,
    val following: Boolean,
    val roomRate: Double?,
    val pausedHere: Boolean,
    val atMediaEnd: Boolean,
)

/**
 * The room pill: [count] participants; the group icon ([isHost] the host's amber) once [connected], else a spinner (a
 * sync icon on TV); [status] "Reconnecting…" beside the count while reconnecting. [label] and [value] are its
 * accessibility label and value ("3 participants, Connected, You are the host").
 */
data class WatchPillUi(
    val count: String,
    val connected: Boolean,
    val isHost: Boolean,
    val status: String?,
    val label: String,
    val value: String,
)

/** "Playback didn't start" ([title], [description]) with [play] ([WatchCommand.PlayBlockedPlayer]). */
data class WatchPlayBlockedUi(val title: String, val description: String, val play: String)

/**
 * Home's toolbar action: "Watch Together" ([label]); filled and primary while [inSession]; [badge] the participant count
 * while in a room with others.
 */
data class WatchToolbarUi(val inSession: Boolean, val participantCount: Int, val label: String) {
    val badge: String? get() = participantCount.takeIf { inSession && it > 1 }?.toString()
}
