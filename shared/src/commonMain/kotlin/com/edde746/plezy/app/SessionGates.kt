package com.edde746.plezy.app

import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * What a return to the foreground asks of the app ([AppGraph.foreground]: the platform reports a real backgrounding
 * only, never a system overlay over the app, so an overlay never counts).
 *
 * - [staleRefresh]: the app was in the background at least [staleAfter] (counted from the first time it went, however
 *   often it went again meanwhile): the content tabs load again, since a TV launcher resumes the resident process hours
 *   later instead of starting it.
 * - [prompt]: it was in the background other than with its video playing on in picture in picture: the "ask for a
 *   profile on open" rule applies again. A video that stayed in sight never needs a profile chosen again.
 *
 * The cold start's first foreground is no return ([resumed] is null).
 */
internal class ResumeGate(private val timeSource: TimeSource = TimeSource.Monotonic, private val staleAfter: Duration = STALE_AFTER) {
    private var backgroundedAt: TimeMark? = null
    private var prompts = false

    /** What the last [resumed] found. */
    data class Resume(val prompt: Boolean, val staleRefresh: Boolean)

    /**
     * The app went to the background, its video playing on in picture in picture or not ([inPictureInPicture]); the
     * earliest time is kept until the next [resumed].
     */
    fun backgrounded(inPictureInPicture: Boolean = false) {
        if (backgroundedAt == null) backgroundedAt = timeSource.markNow()
        if (!inPictureInPicture) prompts = true
    }

    /** The app came back to the foreground: what to do, once per backgrounding; null when it wasn't in the background. */
    fun resumed(): Resume? {
        val at = backgroundedAt ?: return null
        backgroundedAt = null
        val prompt = prompts
        prompts = false
        return Resume(prompt = prompt, staleRefresh = at.elapsedNow() >= staleAfter)
    }

    companion object {
        /** How long in the background makes the shown content stale. */
        val STALE_AFTER: Duration = 5.minutes
    }
}

/**
 * Whether a return from the background ([ResumeGate.Resume.prompt]) shows the required profile picker: on phones,
 * tablets and TV boxes (not desktops), online, the picker not already up, and not while a cast plays here (a sender's
 * cast isn't the profile's). An open player doesn't exempt it: the picker shows over the player, which it holds paused
 * ([PlaybackController.holdForProfilePick]). The caller also asks the "ask on open" setting and that no link is choosing
 * the profile.
 */
internal fun shouldPromptProfileOnResume(
    resumedFromBackground: Boolean,
    offline: Boolean,
    pickerShown: Boolean,
    desktop: Boolean,
    castReceiving: Boolean,
): Boolean = resumedFromBackground && !offline && !pickerShown && !desktop && !castReceiving

/**
 * Whether a bind settling invalidates the screens: a rebind of the profile already bound settling (a borrowed or
 * removed connection rebinds it). The start's bind and the first bind after a switch don't: the screens were made for
 * them ([AppSession.profileSession]). Feed it every (active id, binding) change.
 */
internal class RebindSettles {
    private var settledId: String? = null
    private var wasBinding = false

    /** The active profile is [id] and [binding]; true when this settles a rebind of the profile bound before. */
    fun onState(id: String?, binding: Boolean): Boolean {
        val settled = wasBinding && !binding
        wasBinding = binding
        if (!settled) return false
        val rebind = id != null && id == settledId
        settledId = id
        return rebind
    }
}
