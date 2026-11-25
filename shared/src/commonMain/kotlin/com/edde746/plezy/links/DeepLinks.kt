package com.edde746.plezy.links

import com.edde746.plezy.log.Log
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Switches profiles for links. Outlives the profile session a switch replaces.
 */
interface LinkProfiles {
    val profiles: List<Profile>

    val activeProfileId: String?

    /**
     * Activates [profile], asking for its PIN when it is protected. Whether [profile] is now active: false when the
     * viewer backed out or the switch failed (which the switch reports itself).
     */
    suspend fun switchTo(profile: Profile): Boolean

    /**
     * Returns once the app's screens are [profileId]'s: a switch starts them anew after it returns, which would take
     * off (and end the video of) a link acted on before then.
     */
    suspend fun awaitScreens(profileId: String)
}

/** A profile session that acts on links: the main screen of [profileId]; [launch] acts on a link in it. */
class LinkSession(val profileId: String?, val launch: suspend (DeepLink) -> Unit)

/**
 * Receives `plezy://` links from every platform ([receive]) and hands each to its owner: one queue for all of them.
 *
 * The same URL again within [DUPLICATE_WINDOW] is the same delivery (a platform that hands the launch link over twice).
 * One link is pending at a time; a newer link replaces it. A link that names a profile is applied first: at startup by
 * the profile start, which activates that profile instead of the previous one and the picker
 * ([claimStartupProfile]/[settleStartupProfile]), and later through [host], which switches (a PIN still asked; backing
 * out drops the link). Only then does the attached [LinkSession] of that profile get the link. An unknown profile and
 * an invalid link are reported ([report]). External player return links go straight to [returnFromExternalPlayer].
 *
 * Main thread only.
 */
class DeepLinks(
    private val scope: CoroutineScope,
    private val report: (String) -> Unit,
    private val returnFromExternalPlayer: suspend (String) -> Unit,
    private val time: TimeSource = TimeSource.Monotonic,
) {
    /** Applies a link's profile once startup is over. */
    var host: LinkProfiles? = null
        set(value) {
            field = value
            pump()
        }

    private var pending: PendingLink? = null
    private var startupClaim: PendingLink? = null
    private var session: LinkSession? = null

    /** The attached session's links: cancelled when it detaches, so a link never acts in the next profile. */
    private var sessionJob: Job? = null
    private var switching = false
    private var lastUrl: String? = null
    private var lastUrlAt: TimeMark? = null

    /** Whether a link is about to choose the profile: a profile picker must not ask over it. */
    val selectsProfile: Boolean get() = switching || pending?.awaitsProfile == true

    /** Accepts [url] from any source. */
    fun receive(url: String) {
        val since = lastUrlAt?.elapsedNow()
        if (url == lastUrl && since != null && since < DUPLICATE_WINDOW) return
        lastUrl = url
        lastUrlAt = time.markNow()

        val link = DeepLink.parse(url)
        if (link == null) {
            Log.w(TAG) { "Not a valid Plezy link" }
            report(T.deepLinks.invalid)
            return
        }
        Log.i(TAG) { "Link: ${link::class.simpleName}" }
        if (link is DeepLink.ExternalPlayerReturn) {
            scope.launch {
                try {
                    returnFromExternalPlayer(link.url)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "External player return failed" }
                }
            }
            return
        }
        pending = PendingLink(link)
        pump()
    }

    /**
     * For the profile start, before the first bind: the profile the pending link names, which the start activates in
     * place of the previously active profile and the profile picker, then answers with [settleStartupProfile]. Null
     * when the link names no profile, none that matches (reported once a session is up) or one the start can't
     * activate by itself ([claimable] false: a PIN to ask, which the switch asks once a session is up).
     */
    fun claimStartupProfile(profiles: List<Profile>, claimable: (Profile) -> Boolean = { true }): Profile? {
        val pending = pending ?: return null
        val ref = pending.link.profile
        if (ref == null || !pending.awaitsProfile) return null
        val profile = resolveLinkProfile(profiles, ref)?.takeIf(claimable) ?: return null
        startupClaim = pending
        return profile
    }

    /** The start made the claimed profile active ([applied]), or couldn't (the viewer backed out of its PIN): drops the link. */
    fun settleStartupProfile(applied: Boolean) {
        val claim = startupClaim
        startupClaim = null
        if (claim == null || pending !== claim) return
        if (applied) claim.awaitsProfile = false else pending = null
        pump()
    }

    /** Attaches the session that acts on links until [detach], and delivers a pending link for its profile. */
    fun attach(session: LinkSession) {
        if (this.session !== session) {
            sessionJob?.cancel()
            sessionJob = SupervisorJob(scope.coroutineContext[Job])
        }
        this.session = session
        pump()
    }

    fun detach(session: LinkSession) {
        if (this.session !== session) return
        this.session = null
        sessionJob?.cancel()
        sessionJob = null
    }

    private fun pump() {
        val pending = pending ?: return
        val session = session ?: return
        val host = host ?: return
        if (switching) return

        if (pending.awaitsProfile) {
            val ref = pending.link.profile!!
            val profile = resolveLinkProfile(host.profiles, ref)
            if (profile == null) {
                this.pending = null
                report(T.deepLinks.profileNotFound(profile = ref))
                return
            }
            if (profile.id != host.activeProfileId) {
                switchFor(pending, profile, host)
                return
            }
            pending.awaitsProfile = false
        }

        // A session about to be replaced by a profile switch must not act.
        if (session.profileId != host.activeProfileId) return
        this.pending = null
        scope.launch(sessionJob!!) {
            try {
                session.profileId?.let { host.awaitScreens(it) }
                session.launch(pending.link)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Launching ${pending.link::class.simpleName} failed" }
            }
        }
    }

    private fun switchFor(pending: PendingLink, profile: Profile, host: LinkProfiles) {
        switching = true
        scope.launch {
            var switched = false
            try {
                switched = host.switchTo(profile)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Switching to ${profile.id} failed" }
            } finally {
                switching = false
            }
            if (this@DeepLinks.pending === pending) {
                if (switched) pending.awaitsProfile = false else this@DeepLinks.pending = null
            }
            // A newer link that arrived meanwhile runs now.
            pump()
        }
    }

    private class PendingLink(val link: DeepLink) {
        /** The link names a profile that isn't applied yet. */
        var awaitsProfile: Boolean = link.profile != null
    }

    companion object {
        /** How long an identical URL counts as the same delivery. */
        val DUPLICATE_WINDOW: Duration = 2.seconds
        private const val TAG = "DeepLinks"
    }
}
