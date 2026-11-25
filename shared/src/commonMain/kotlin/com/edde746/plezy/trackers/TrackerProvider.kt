package com.edde746.plezy.trackers

/**
 * One tracker service's implementation, as the account store and the coordinator use it. Each service
 * (`trackers/<service>/`) provides one; [TrackerConfig] decides which are available.
 */
interface TrackerProvider {
    val service: TrackerService

    val signIn: TrackerSignIn

    /** `null` when the service's tokens don't refresh (AniList's last a year, then the user signs in again). */
    val refresher: TokenRefresher?

    /** The write side of the account behind [credentials]. A new instance per connection (see [Tracker]). */
    fun tracker(credentials: TrackerCredentials): Tracker

    /**
     * Revokes [session] at the service on disconnect, where the service has a revocation endpoint. Best effort:
     * failures are logged, never thrown.
     */
    suspend fun revoke(session: TrackerSession)

    /**
     * [session] comes from a sign-in method the service is retiring (Simkl's AUTH V1): it keeps working, and the
     * account's settings offer to sign in again.
     */
    fun isLegacy(session: TrackerSession): Boolean = false
}

/**
 * This build's client registrations. A blank value makes the services that need it unavailable, so a
 * build without registrations offers no tracker at all. Client ids (and Trakt's secret, which Trakt's device flow
 * needs) ship in the binary, as for every native client of these services; MyAnimeList's and AniList's secrets stay on
 * the relay.
 *
 * @param simklLegacyClientId the Simkl registration of sessions signed in before AUTH V2, which only work with it.
 * @param relayBaseUrl the OAuth relay's base URL (MyAnimeList, AniList).
 */
data class TrackerConfig(
    val traktClientId: String = "",
    val traktClientSecret: String = "",
    val simklClientId: String = "",
    val simklLegacyClientId: String = "",
    val mdblistClientId: String = "",
    val malClientId: String = "",
    val relayBaseUrl: String = "",
) {
    override fun toString(): String = "TrackerConfig(relayBaseUrl=$relayBaseUrl)"
}
