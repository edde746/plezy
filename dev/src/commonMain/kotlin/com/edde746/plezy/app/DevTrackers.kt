package com.edde746.plezy.app

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlin.time.Clock
import kotlin.time.Duration.Companion.days

/**
 * Connects every tracker service this build offers to the session's active profile (once there is one) with a session
 * the fake tracker server takes, without signing in (`--dev-trackers-connected`, beside `--dev-trackers`, which
 * [AppGraph.installDevTrackers] points the trackers at): Simkl's in its current token generation, each valid for a year.
 */
suspend fun AppSession.connectDevTrackers() {
    val profileId = profiles.active.filterNotNull().first().id
    val now = Clock.System.now().epochSeconds
    val accounts = trackers.accounts
    for (service in accounts.services) {
        val prefix = if (service == TrackerService.SIMKL) "simkl_at_" else ""
        val session = TrackerSession(
            accessToken = "${prefix}fake-access-dev-${service.id}",
            refreshToken = "fake-refresh-dev-${service.id}",
            expiresAt = now + 365.days.inWholeSeconds,
            username = DEV_TRACKER_USER,
            createdAt = now,
        )
        accounts.connect(profileId, service, session)
    }
    Log.i(TAG) { "connected ${accounts.services.joinToString { it.id }} to the fake tracker server" }
}

/** The fake tracker server's account name (its `--user` default). */
private const val DEV_TRACKER_USER = "plezy-tester"
private const val TAG = "DevTrackers"
