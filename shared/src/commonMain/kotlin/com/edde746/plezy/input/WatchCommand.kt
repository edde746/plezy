package com.edde746.plezy.input

/**
 * What the room's controls ask: the Watch Together screen's ([com.edde746.plezy.presentation.watch.WatchTogetherStore.execute])
 * and the player's session sheet and prompts ([PlayerCommand.Watch]).
 */
sealed interface WatchCommand {
    /** Opens the room's file for this user ("Join Current Playback"). */
    data object JoinPlayback : WatchCommand

    /** The host stops the media for everyone. */
    data object StopMedia : WatchCommand

    /** Plays the copy [candidateId] for the room's media; a failure shows "Couldn't play this copy for the room". */
    data class ChooseCopy(val candidateId: String) : WatchCommand

    /** Searches the libraries again for the room's media. */
    data object SearchAgain : WatchCommand

    /** Plays the offered copy of another length. */
    data object PlayAnyway : WatchCommand

    /** Doesn't play the offered copy of another length. */
    data object DontPlay : WatchCommand

    /** Sets this user's offset from the room: local = room + [offsetMs]. */
    data class SetOffset(val offsetMs: Long) : WatchCommand

    /** The host lets everyone control playback, or only themselves. */
    data class SetEveryoneControls(val everyone: Boolean) : WatchCommand

    /** The host locks the room to new participants, or opens it again. */
    data class Lock(val locked: Boolean) : WatchCommand

    /** The host hands the room to [peerId]. */
    data class MakeHost(val peerId: String) : WatchCommand

    /** The host removes [peerId] from the room. */
    data class Kick(val peerId: String) : WatchCommand

    /** Leaves the room; it goes on without this user. */
    data object Leave : WatchCommand

    /** The host ends the room for everyone. */
    data object End : WatchCommand

    /** Starts the player that refused to start, from its prompt. */
    data object PlayBlockedPlayer : WatchCommand
}
