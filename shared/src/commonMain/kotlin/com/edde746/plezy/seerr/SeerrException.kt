package com.edde746.plezy.seerr

/**
 * A Seerr failure. [message] is English, for logs; [display] is the localized text a screen shows, when there is one
 * ([text] falls back to [message]).
 */
sealed class SeerrException(override val message: String, cause: Throwable? = null) : Exception(message, cause) {
    abstract val display: String?

    /** What a screen shows: [display], else [message]. */
    val text: String get() = display ?: message

    /**
     * The address doesn't lead to a reachable, initialized Seerr. [statusCode] is the status of the answer that
     * disqualified it; null when nothing answered (DNS, refused, TLS, timeout), which is how the candidate race tells
     * "reached a server that isn't a usable Seerr" from "reached nothing".
     */
    class Url(message: String, override val display: String?, val statusCode: Int? = null, cause: Throwable? = null) :
        SeerrException(message, cause)

    /**
     * A sign-in or session failure: rejected credentials, a revoked session, no stored credentials. During a silent
     * re-auth it means the server rejected the stored credentials, and the session is unlinked.
     */
    class Auth(message: String, override val display: String? = null, val statusCode: Int? = null) : SeerrException(message)

    /**
     * A silent re-auth couldn't restore this account (no live Plex token, a login that resolved to another user). It
     * doesn't prove the stored credentials were rejected, so the session stays linked.
     */
    class ReauthUnavailable(message: String, override val display: String?) : SeerrException(message)

    /**
     * Something in front of Seerr answered instead of Seerr: a forward-auth redirect to an SSO login, an HTTP Basic
     * challenge, an auth wall or gateway's 401/403, JSON or not. Seerr never redirects and rejects in exactly two JSON
     * shapes, so anything else is diagnostic. The stored session may be fine behind the wall: it stays linked.
     */
    class Proxy(message: String, override val display: String, val statusCode: Int) : SeerrException(message)

    /** A failure Seerr answered with its own message (a quota, a duplicate request, a server error). */
    class Api(message: String, val statusCode: Int) : SeerrException(message) {
        override val display: String? get() = null
    }

    /**
     * Seerr's permission middleware refused a live session the action's permission bit. Its answer is the same as a
     * session rejection's; only the `GET /auth/me` probe tells them apart. The session stays linked.
     */
    class Permission(message: String, override val display: String, val statusCode: Int) : SeerrException(message)

    override fun toString(): String = "${this::class.simpleName}: $message"
}
