package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/**
 * Watch together as the player store sees it ([PlayerStore.attachWatch]): what the player shows of the room, the
 * room's notices for its OSD, and where the viewer's play, pause, seeks and speed changes go while the room drives this
 * player ([routesControls]).
 */
interface PlayerWatch {
    /** What the player shows: null outside a room. */
    val state: StateFlow<PlayerWatchUi?>

    /** Notices ("Sam paused"), shown as the player's OSD. */
    val notices: Flow<String>

    /** The room drives this player: play and pause go to the room ([play], [pause]), which commands the player. */
    val routesControls: Boolean

    /** The room's speed, which the player shows while the room nudges its own; null outside a room. */
    val roomRate: Double?

    /** This player paused on this device alone ([stopHere]) and stays out of the room's playback until [resumeHere]. */
    val stoppedHere: Boolean

    /**
     * The playback stopped on this device for one who doesn't control the room's playback (a call, the audio output
     * gone, the sleep timer): the room stops waiting for this player, and plays on without it.
     */
    fun stopHere()

    /** Back from [stopHere]: the player joins the room's playback again, and the room catches it up. */
    fun resumeHere()

    /**
     * The viewer pressed play: the room starts everyone together. False when the player refused to start in a playing
     * room: the press then starts the player itself.
     */
    fun play(): Boolean

    /** The viewer pressed pause: the room pauses everyone. */
    fun pause()

    /** The viewer moved the position (a seek, a scrub, a chapter). */
    fun onLocalSeek(seconds: Double)

    /** The viewer changed the speed. */
    fun onLocalRate(rate: Double)

    /**
     * The viewer skipped what runs to the end of the file: the room's media ends for everyone, the room seeking to its
     * end ([PlayerWatchUi.atMediaEnd]); nothing once it is there.
     */
    fun endMedia()

    fun execute(command: WatchCommand)
}
