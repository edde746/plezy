package com.edde746.plezy.trackers

import kotlinx.coroutines.delay
import kotlinx.serialization.json.JsonObject
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * An RFC 8628 device code: the user enters [userCode] at [verificationUrl] (or scans [verificationUrlComplete] as a QR
 * code, where the service offers one); the app polls every [intervalSeconds] until [expiresInSeconds] pass.
 */
data class DeviceCodeGrant(
    val deviceCode: String,
    val userCode: String,
    val verificationUrl: String,
    val verificationUrlComplete: String? = null,
    val expiresInSeconds: Long,
    val intervalSeconds: Long,
) {
    override fun toString(): String = "DeviceCodeGrant(userCode=$userCode, expiresIn=$expiresInSeconds, interval=$intervalSeconds)"
}

/** One poll of a device code's token endpoint. */
sealed interface DevicePoll {
    /** The user hasn't approved yet. */
    data object Pending : DevicePoll

    /** Poll less often: the interval grows by [DeviceCodePoller.SLOW_DOWN_STEP]. */
    data object SlowDown : DevicePoll

    data object Denied : DevicePoll

    data object Expired : DevicePoll

    /** Approved: the token endpoint's answer. */
    class Success(val token: JsonObject) : DevicePoll {
        override fun toString(): String = "Success"
    }
}

/** The RFC 8628 poll loop shared by the device-code services. */
object DeviceCodePoller {
    val SLOW_DOWN_STEP = 5.seconds

    /**
     * Waits [DeviceCodeGrant.intervalSeconds] and asks [probe], until it answers [DevicePoll.Success],
     * [DevicePoll.Denied] or [DevicePoll.Expired], or the code's lifetime is over ([DevicePoll.Expired]).
     * Cancelling the caller stops it.
     */
    suspend fun poll(grant: DeviceCodeGrant, timeSource: TimeSource = TimeSource.Monotonic, probe: suspend () -> DevicePoll): DevicePoll {
        var interval = grant.intervalSeconds.coerceAtLeast(1).seconds
        val deadline = timeSource.markNow() + grant.expiresInSeconds.seconds
        while (deadline.hasNotPassedNow()) {
            delay(interval)
            when (val event = probe()) {
                is DevicePoll.Success, DevicePoll.Denied, DevicePoll.Expired -> return event
                DevicePoll.SlowDown -> interval += SLOW_DOWN_STEP
                DevicePoll.Pending -> {}
            }
        }
        return DevicePoll.Expired
    }
}

/** Where the OAuth relay sends the user: [url], opened here or shown as a QR code and a link for another device. */
data class RelayStart(val session: String, val url: String) {
    override fun toString(): String = "RelayStart"
}

/** The relay's answer once the user authorized. */
data class RelayResult(val accessToken: String, val refreshToken: String? = null, val expiresInSeconds: Long? = null) {
    override fun toString(): String = "RelayResult(expiresIn=$expiresInSeconds)"
}

/**
 * The OAuth relay's client, for MyAnimeList and AniList, whose secrets only the relay holds: the port the account
 * store signs those services in through.
 */
interface OAuthRelay {
    /** Opens a relay session for [service]. @throws TrackerException.SignIn when the relay can't serve it. */
    suspend fun start(service: TrackerService): RelayStart

    /**
     * Long-polls [session] (opened for [service]) until the user authorized (the tokens), declined (`null`), or the
     * session ended ([TrackerException.SignIn]). Transient failures are retried inside; cancelling the caller stops it.
     */
    suspend fun poll(service: TrackerService, session: String): RelayResult?
}

/** The account a session signs in as, as the service names it: its display name and stable id, either unknown. */
data class SignedInAccount(val username: String?, val id: String?)

/** How a service's account connects. */
sealed interface TrackerSignIn {
    /** Device code, direct with the service (Trakt, Simkl, MDBList). */
    interface DeviceCode : TrackerSignIn {
        /** @throws TrackerException.SignIn when the service refused to issue a code (its status only). */
        suspend fun requestCode(): DeviceCodeGrant

        /** One poll of the token endpoint for [grant]; a transport failure is [DevicePoll.Pending]. */
        suspend fun probe(grant: DeviceCodeGrant): DevicePoll

        /**
         * The session from the approved [token] answer, without a username.
         *
         * @throws TrackerException.SignIn when the answer lacks what the session needs (a refresh token).
         */
        suspend fun session(token: JsonObject): TrackerSession

        /**
         * Who [session] signs in as, looked up at the service. Best effort: `null` when the lookup failed, so the
         * sign-in goes on without a name.
         */
        suspend fun account(session: TrackerSession): SignedInAccount?
    }

    /** Through the [OAuthRelay] (MyAnimeList with PKCE, AniList). */
    interface Relay : TrackerSignIn {
        /** The session from the relay's [result], with the account's username looked up. */
        suspend fun session(result: RelayResult): TrackerSession
    }
}
