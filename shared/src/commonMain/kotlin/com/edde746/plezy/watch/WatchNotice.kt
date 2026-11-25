package com.edde746.plezy.watch

import party.openwatch.EndReason

/** Something the room or the session tells the user once, as a snackbar ([WatchLabels.noticeText]). */
sealed interface WatchNotice {
    /**
     * Another participant's (or the room's, without [name]) action of [kind] (`play`, `pause`, `seek`, `rate`, `media`,
     * `stall`, `ended`, `host`): a seek with its [positionMs] (the room's position plus this user's offset), a rate
     * change with its [rate].
     */
    data class Action(val kind: String, val name: String? = null, val positionMs: Long? = null, val rate: Double? = null) : WatchNotice

    data class Joined(val name: String) : WatchNotice

    data class Left(val name: String) : WatchNotice

    /** The relay or the SDK refused a command with error [code]. */
    data class Refused(val code: String) : WatchNotice

    /** A guest pressed a control while only the host controls playback. */
    data object ControlRefused : WatchNotice

    /** Some servers couldn't be searched for the room's media. */
    data object SearchFailed : WatchNotice

    /** The platform refused to start playback without a user gesture. */
    data object PlayBlocked : WatchNotice

    data class Ended(val reason: EndReason) : WatchNotice

    /** The host's file could not be shared with the room. */
    data object ShareFailed : WatchNotice

    /** A download whose server is offline is not shared with the room. */
    data object NotShared : WatchNotice

    /** The room's file could not be opened. */
    data object OpenFailed : WatchNotice

    /** The file a guest's player opened could not be picked for the room's media; the player plays it on its own. */
    data object ChoiceFailed : WatchNotice
}
