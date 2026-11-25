package com.edde746.plezy.seerr

import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** Constants of the Seerr (Overseerr, Jellyseerr, Seerr) REST API. */
object SeerrConstants {
    /** Every endpoint lives under this prefix on the instance base URL. */
    const val API_PATH = "/api/v1"

    /** The Express session cookie the auth endpoints issue: Seerr's only session type. */
    const val SESSION_COOKIE_NAME = "connect.sid"

    /** The default port of a Seerr install, tried for schemeless input that names no port of its own. */
    const val DEFAULT_PORT = 5055

    val PROBE_TIMEOUT = 8.seconds
    val AUTH_TIMEOUT = 20.seconds
    val REQUEST_TIMEOUT = 30.seconds

    /** Quick Connect poll cadence, the Seerr web UI's fixed 2 s. */
    val QUICK_CONNECT_POLL_INTERVAL = 2.seconds

    /** How long a Quick Connect code is polled before giving up. */
    val QUICK_CONNECT_WINDOW = 5.minutes

    /** The TMDB keyword Seerr treats as "this series is an anime", routing it to a Sonarr instance's anime defaults. */
    const val ANIME_KEYWORD_ID = 210024
}

/** Seerr's `MediaServerType` values, sent as `serverType` in the `/auth/jellyfin` body. */
object SeerrMediaServerType {
    const val PLEX = 1
    const val JELLYFIN = 2
    const val EMBY = 3
}

/**
 * Seerr's permission bitmask. Only the bits the app checks are named; the session keeps the full mask untouched.
 * `ADMIN` implies everything, otherwise the user needs at least one of the bits a check lists ([has]).
 */
object SeerrPermission {
    const val ADMIN = 2
    const val REQUEST = 32
    const val REQUEST_4K = 1024
    const val REQUEST_4K_MOVIE = 2048
    const val REQUEST_4K_TV = 4096
    const val REQUEST_ADVANCED = 8192
    const val REQUEST_MOVIE = 262144
    const val REQUEST_TV = 524288

    /** Whether [permissions] is an admin's or holds at least one of [anyOf]. */
    fun has(permissions: Int, vararg anyOf: Int): Boolean =
        (permissions and ADMIN) != 0 || anyOf.any { (permissions and it) != 0 }

    /** Whether [permissions] may request a movie ([movie]) or a show: REQUEST, or REQUEST_MOVIE / REQUEST_TV. */
    fun canRequest(permissions: Int, movie: Boolean): Boolean =
        has(permissions, REQUEST, if (movie) REQUEST_MOVIE else REQUEST_TV)
}
