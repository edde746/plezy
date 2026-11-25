package com.edde746.plezy.presentation.player

import com.edde746.plezy.crash.Breadcrumb
import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.output.PlaybackOutput
import com.edde746.plezy.playback.session.PlayerSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * What the app leaving the foreground does to the video, by device ([of]): [pauses] it (phones, tablets, TVs, cars; a
 * desktop window plays on behind others), [tv] holds its OS media controls while away, and [suspends] (an Android TV,
 * whose decoders other apps share) gives the engine's decoders back after [PlayerLifecycle.SUSPEND_GRACE].
 */
data class BackgroundPolicy(val pauses: Boolean, val tv: Boolean, val suspends: Boolean) {
    companion object {
        fun of(formFactor: FormFactor, appleTv: Boolean, automotive: Boolean): BackgroundPolicy = BackgroundPolicy(
            pauses = formFactor != FormFactor.DESKTOP || automotive,
            tv = formFactor == FormFactor.TV,
            suspends = formFactor == FormFactor.TV && !appleTv,
        )
    }
}

/**
 * One playback following the app as it leaves the foreground and comes back ([foreground]), a transition at a time,
 * in order:
 *
 * - Leaving, where the [policy] pauses, unless picture in picture takes the video ([skipsForPictureInPicture]: its
 *   window is up or on its way): a video that plays pauses, remembered until it plays again on the way back (a car's
 *   pause and stop both arrive; the first one's playing counts); the OS media controls go until then ([MediaControls.suspend]).
 *   On a TV, nothing starts the video meanwhile ([holdsPlayback]): the session's playback gate pauses any start. On an
 *   Android TV an on-demand video still in the background after [SUSPEND_GRACE] gives the engine's decoders back and
 *   ends its server session ([PlayerSession.suspendInBackground]), the display back in its own mode; while a reload or
 *   the first frame is on its way, it waits another grace.
 * - Back: the grace ends, a suspended video opens again where it was ([PlayerSession.restoreAfterBackground]), the
 *   controls come back as they are now, and a video that played before plays again ([PlayerStore.resumeAfterBackground]:
 *   back by rewind-on-resume first).
 *
 * Main thread.
 */
internal class PlayerLifecycle(
    private val store: PlayerStore,
    private val session: PlayerSession,
    private val controls: MediaControls?,
    private val output: PlaybackOutput?,
    private val policy: BackgroundPolicy,
    private val skipsForPictureInPicture: () -> Boolean,
    foreground: StateFlow<Boolean>,
    private val scope: CoroutineScope,
) {
    /** On a TV in the background: whatever starts the video is paused again at once. */
    var holdsPlayback = false
        private set

    private var away = false
    private var wasPlaying = false
    private var grace: Job? = null
    private var suspended = false

    init {
        scope.launch {
            foreground.drop(1).distinctUntilChanged().collect { inFront -> if (inFront) onForeground() else onBackground() }
        }
    }

    private fun onBackground() {
        if (!policy.pauses) return
        if (skipsForPictureInPicture()) return breadcrumb("hidden", "skipped for picture in picture")
        away = true
        wasPlaying = store.pauseForBackground() || wasPlaying
        controls?.suspend()
        if (policy.tv) holdsPlayback = true
        if (policy.suspends && !session.info.value.live && !suspended) armGrace()
        breadcrumb("hidden", if (grace != null) "paused, suspend armed" else "paused")
    }

    private fun armGrace() {
        grace?.cancel()
        grace = scope.launch {
            delay(SUSPEND_GRACE)
            grace = null
            if (!session.suspendInBackground()) return@launch armGrace()
            suspended = true
            output?.suspend()
            breadcrumb("hidden", "suspended")
        }
    }

    private suspend fun onForeground() {
        grace?.cancel()
        grace = null
        if (!away) return
        away = false
        holdsPlayback = false
        if (suspended) {
            suspended = false
            breadcrumb("resumed", "restoring the suspended video")
            session.restoreAfterBackground()
        }
        controls?.resume()
        val resume = wasPlaying
        wasPlaying = false
        store.resumeAfterBackground(play = resume && session.info.value.failure == null)
        breadcrumb("resumed", if (resume) "playing again" else "complete")
    }

    private fun breadcrumb(state: String, action: String) {
        Log.d(TAG) { "player lifecycle $state: $action" }
        CrashCapture.breadcrumb(Breadcrumb("player.lifecycle", "Player lifecycle $state", mapOf("action" to action)))
    }

    internal companion object {
        private const val TAG = "PlayerLifecycle"

        /** How long a paused video may sit in the background on an Android TV before its decoders go back. */
        val SUSPEND_GRACE: Duration = 30.seconds
    }
}
