package com.edde746.plezy.music

import com.edde746.plezy.log.Log
import kotlin.coroutines.cancellation.CancellationException

/**
 * Stops the music session before the video player builds its engine, one per app process. The video session calls
 * [claimVideo] first thing in its initialization, so the music session has reported its final progress, given up
 * audio focus, disposed its audio core and cleared the OS controls before the video core exists.
 *
 * Main thread.
 */
class PlaybackCoordinator {
    private var stopMusicSession: (suspend () -> Unit)? = null

    /**
     * Registers the live music session's teardown, which must stop playback, send the final report and dispose the
     * audio player before it returns. Replaces an earlier registration (one music session per profile session).
     */
    fun registerMusicSession(stopAndDispose: suspend () -> Unit) {
        stopMusicSession = stopAndDispose
    }

    /** Removes [stopAndDispose] when it is still the registration, so a replaced session's late call keeps its successor. */
    fun unregisterMusicSession(stopAndDispose: suspend () -> Unit) {
        if (stopMusicSession === stopAndDispose) stopMusicSession = null
    }

    /** Video is about to build its engine: stops and disposes the music session first; returns once its core is gone. */
    suspend fun claimVideo() {
        val stop = stopMusicSession ?: return
        try {
            stop()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // Video must still start: a wedged audio core is worse than a leaked stop error.
            Log.w(TAG, e) { "Music session teardown failed" }
        }
    }

    private companion object {
        const val TAG = "PlaybackCoordinator"
    }
}
