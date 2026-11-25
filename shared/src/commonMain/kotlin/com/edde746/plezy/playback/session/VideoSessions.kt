package com.edde746.plezy.playback.session

import com.edde746.plezy.log.Log
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope

/**
 * The video playback of the app, one at a time: the session playing registers its [register] owner as it starts, and
 * what must stop video from outside the player (an automation's stop, a sign-out, the app quitting) goes through here.
 * A session that ends hands its retirement ([unregister]: its last reports and the engine's release) over, and every
 * stop waits for those too, failures included, which reach the caller and then are dropped.
 *
 * Registration belongs to an owner: a replaced session's late unregister leaves its successor registered. Music
 * playback stops before video starts through [com.edde746.plezy.music.PlaybackCoordinator.claimVideo]. Call on the
 * main thread.
 */
class VideoSessions {
    private var owner: Any? = null
    private var shutdown: (suspend () -> Unit)? = null
    private var exit: (suspend () -> Boolean)? = null
    private val retirements = LinkedHashSet<Deferred<Unit>>()

    /**
     * [owner] plays video from now on: [shutdown] stops it and waits for its last reports, [stopAndExit] also leaves the
     * player (false: it couldn't). Replaces any registration.
     */
    fun register(owner: Any, shutdown: suspend () -> Unit, stopAndExit: (suspend () -> Boolean)? = null) {
        this.owner = owner
        this.shutdown = shutdown
        exit = stopAndExit
    }

    /**
     * [owner] ended: its registration goes unless another owner registered since. [retirement] (its last reports, the
     * engine's release) is waited for by every stop until it completes, however it does.
     */
    fun unregister(owner: Any, retirement: Deferred<Unit>? = null) {
        if (this.owner === owner) {
            this.owner = null
            shutdown = null
            exit = null
        }
        if (retirement == null || !retirements.add(retirement)) return
        retirement.invokeOnCompletion { failure ->
            retirements -= retirement
            if (failure != null) Log.w(TAG, failure) { "a video session's retirement failed" }
        }
    }

    /** Stops the video and waits for its native stop, last report and every pending retirement. */
    suspend fun shutdownVideo() = coroutineScope {
        val waits = retirements.toList() + listOfNotNull(shutdown?.let { stop -> async { stop() } })
        waits.awaitAll()
        Unit
    }

    /**
     * Stops the video and leaves the player, waiting for every pending retirement: true when the player left, or no
     * session was registered; false when the session couldn't leave.
     */
    suspend fun stopVideoAndExit(): Boolean = coroutineScope {
        var exited = shutdown == null
        val leave = exit?.let { stop -> async { exited = stop() } }
        (retirements.toList() + listOfNotNull(leave)).awaitAll()
        exited
    }

    private companion object {
        const val TAG = "video-sessions"
    }
}
