package com.edde746.plezy.trackers

import com.edde746.plezy.trackers.simkl.SimklProvider
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * One tracker account's tokens as the service issued them, kept on this device in its secret store
 * ([TrackerTokenStore]) as JSON with the keys `access_token`, `refresh_token`, `expires_at`, `username` and
 * `created_at`. Never in SQLite or logs, so [toString] leaves the tokens out.
 *
 * @param expiresAt epoch seconds; `null` when the token doesn't expire.
 * @param createdAt epoch seconds.
 * @param username the account's name as the service shows it, for the settings row.
 */
@Serializable
data class TrackerSession(
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String? = null,
    @SerialName("expires_at") val expiresAt: Long? = null,
    @SerialName("username") val username: String? = null,
    @SerialName("created_at") val createdAt: Long,
) {
    /**
     * The access token expires within [REFRESH_WINDOW_SECONDS] of [nowEpochSeconds]: refresh before handing it out.
     * A session without an expiry never refreshes ahead.
     */
    fun needsRefresh(nowEpochSeconds: Long): Boolean = expiresAt != null && nowEpochSeconds >= expiresAt - REFRESH_WINDOW_SECONDS

    /** The access token has expired at [nowEpochSeconds]. */
    fun expired(nowEpochSeconds: Long): Boolean = expiresAt != null && nowEpochSeconds >= expiresAt

    /**
     * Whether a kept session has what [service]'s sessions always have: MyAnimeList, Trakt and MDBList a refresh token
     * and an expiry, AniList an expiry, Simkl's AUTH V2 sessions both and its legacy (V1) ones neither. A session
     * without them could never be renewed, so the store treats it as absent and the user signs in again.
     */
    fun isValidFor(service: TrackerService): Boolean {
        val refreshable = !refreshToken.isNullOrEmpty()
        return when (service) {
            TrackerService.MYANIMELIST, TrackerService.TRAKT, TrackerService.MDBLIST -> refreshable && expiresAt != null
            TrackerService.ANILIST -> expiresAt != null
            TrackerService.SIMKL -> !SimklProvider.isV2AccessToken(accessToken) || (refreshable && expiresAt != null)
        }
    }

    override fun toString(): String =
        "TrackerSession(expiresAt=$expiresAt, username=$username, createdAt=$createdAt, refreshable=${refreshToken != null})"

    companion object {
        const val REFRESH_WINDOW_SECONDS: Long = 300
    }
}

/**
 * Exchanges a session's refresh token for a new session (the service's token endpoint). Services whose tokens don't
 * refresh (AniList) have none.
 */
fun interface TokenRefresher {
    /**
     * The refreshed session; it keeps [session]'s username. Refresh tokens may rotate (Trakt): the old one is spent
     * once this returns.
     *
     * @throws TrackerException.Auth with `permanent = true` when the service refused (400/401/403; a missing refresh
     *   token), `false` when the endpoint misbehaved (5xx); [TrackerException.Network] when unreachable.
     */
    suspend fun refresh(session: TrackerSession): TrackerSession
}

/**
 * The tokens of one connected account, for a tracker's requests. Implemented by the account store, which keeps the
 * session on this device, refreshes it at the service and drops the connection when the service says it is dead.
 */
interface TrackerCredentials {
    val service: TrackerService

    /**
     * The access token for the next request, refreshed first when it expires soon. When that refresh fails for a
     * reason a later try may not have (the service or the network down), a held token that hasn't expired is returned,
     * so the request's own 401 decides.
     *
     * @throws TrackerException.Auth (permanent) when the connection is gone; [TrackerException.SecretStore] when the
     *   secret store can't read or keep the session; the refresh's failure when the held token has expired.
     */
    suspend fun accessToken(): String

    /**
     * A request sent with [rejected] got a 401: refresh once for every caller at a time and return the new token
     * (without refreshing when [rejected] was already replaced). Retry the request once with it.
     *
     * @throws TrackerException.Auth permanent when the connection is gone (the service refused its refresh, or its
     *   tokens don't refresh); the refresh's failure otherwise; [TrackerException.SecretStore] when the secret store
     *   can't keep the new session.
     */
    suspend fun refreshAfterUnauthorized(rejected: String): String

    /**
     * The service declared the session behind [rejected] dead (a 401 where tokens don't refresh, AniList and Simkl's
     * legacy tokens; a 401 again right after a refresh): this device drops the connection.
     */
    suspend fun invalidate(rejected: String)
}
