package com.edde746.plezy.watch

/**
 * The player screen as a room reads and drives it ([PlezyPlayerAdapter]): the player's state, and the screen's own
 * commands, which act on the player without going back through the room (none of them may be routed to the party).
 */
internal interface RoomPlayer {
    /** The engine's load the player reports ([com.edde746.plezy.playback.EngineState.loadId]). */
    val loadId: Long

    /** The position in the open file. */
    val positionMs: Long

    /** The file's length as the player reports it; null or 0 while it doesn't know it. */
    val durationMs: Long?

    val playing: Boolean

    /** Stalled while trying to play. */
    val buffering: Boolean

    /** A frame of the open file has rendered. */
    val renderedFrame: Boolean

    /** The player takes seeks in the open file. */
    val seekable: Boolean

    /** Audio passes through to the receiver: the rate can't change. */
    val audioPassthrough: Boolean

    /** The player is gone: nothing commands it any more. */
    val disposed: Boolean

    /** The player's restarts in the open file: one per first frame after the open and after each seek. */
    val restarts: Int

    /** Called at once when something the room reads changes (paused, buffering, the file, a seek landing). */
    var onChanged: (() -> Unit)?

    /** Starts playing; throws when the player refuses to. */
    suspend fun play()

    suspend fun pause()

    /** The screen's seek, which also opens another part of a stacked item. Returns once issued. */
    suspend fun seek(positionMs: Long)

    suspend fun setRate(rate: Double)
}
