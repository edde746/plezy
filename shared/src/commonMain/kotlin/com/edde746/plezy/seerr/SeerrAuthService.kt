package com.edde746.plezy.seerr

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.net.BaseUrlGuess
import com.edde746.plezy.backend.net.expandBaseUrlCandidates
import com.edde746.plezy.backend.net.isCertificateFailure
import com.edde746.plezy.backend.net.resolveTypedAddress
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import io.ktor.http.HttpMethod
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlin.time.Duration
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** A reachable, initialized Seerr: the URL that answered and the public settings it reported. */
data class SeerrReachableInstance(val baseUrl: String, val settings: SeerrPublicSettings) {
    /** [signedIn], a session signed in at this instance, named and typed by its settings: what the connect flow keeps. */
    fun complete(signedIn: SeerrSession): SeerrSession =
        signedIn.copy(instanceLabel = settings.instanceLabel, product = settings.product)
}

/**
 * A started Jellyfin Quick Connect: the user approves [code] inside Jellyfin, [secret] drives the poll and the final
 * exchange. [toString] leaves the secret out.
 */
class SeerrQuickConnectInitiation(val code: String, val secret: String) {
    override fun toString(): String = "SeerrQuickConnectInitiation(code=$code)"
}

/**
 * Finds a Seerr instance and signs in to it. Every sign-in ends with a captured `connect.sid` cookie and the Seerr user
 * read back through `GET /auth/me`, packed into a [SeerrSession] (its [SeerrSession.instanceLabel] and
 * [SeerrSession.product] are the caller's to fill from the probe's settings).
 *
 * @param http the app's client; requests go through a copy that doesn't follow redirects ([SeerrHttp]).
 * @param clock stamps [SeerrSession.createdAt].
 */
class SeerrAuthService(http: HttpClient, private val clock: Clock = Clock.System) {
    /** [http] without redirects: every Seerr request goes through it. */
    internal val http: HttpClient = http.config { followRedirects = false }

    /**
     * The Seerr instance [input] leads to: the URL as typed when it has a scheme, else the guess
     * [resolveTypedAddress] accepts (HTTPS first; plain HTTP only when no HTTPS guess could connect at all), because the
     * sign-in that follows posts a password or a Plex token to it. When none answers, a rejected certificate is
     * reported first, then a failure that came back from a server, then the first guess's, so "finish Seerr's setup"
     * isn't hidden behind a guess the user never typed.
     *
     * @throws SeerrException.Url for input with no host (no probe is sent), or the failure described above.
     */
    suspend fun probeFirstReachable(input: String): SeerrReachableInstance {
        val candidates = expandUrlCandidates(input)
        if (candidates.isEmpty()) throw SeerrException.Url("Not a usable Seerr instance URL: \"$input\"", T.seerr.invalidUrl)
        return resolveTypedAddress(candidates) { SeerrReachableInstance(it, probe(it)) }
    }

    /**
     * Checks that [baseUrl] is a running, initialized Seerr (unauthenticated `GET /settings/public`, at most
     * [SeerrConstants.PROBE_TIMEOUT]) and returns what the connect flow needs from it.
     *
     * @throws SeerrException.Url when it can't be reached, isn't a Seerr, isn't set up, or an auth proxy answered.
     */
    suspend fun probe(baseUrl: String): SeerrPublicSettings {
        val client = SeerrHttp(baseUrl, http)
        val res = try {
            client.send(HttpMethod.Get, SETTINGS_PATH, timeout = SeerrConstants.PROBE_TIMEOUT, authenticated = false)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            val failure = MediaServerHttpException.from(e)
            val display = when {
                isCertificateFailure(e) -> T.addServer.untrustedCertificate(url = baseUrl)
                failure.type == MediaServerHttpErrorType.CONNECTION_TIMEOUT || failure.type == MediaServerHttpErrorType.RECEIVE_TIMEOUT ->
                    T.addServer.serverTimedOut
                else -> T.addServer.noReachableServer(product = PRODUCT)
            }
            throw SeerrException.Url("Could not reach $baseUrl: ${e.message ?: e::class.simpleName.orEmpty()}", display, cause = e)
        }
        if (SeerrHttp.classify(res, SETTINGS_PATH) == SeerrRejection.INTERMEDIARY) {
            throw SeerrException.Url("Auth proxy in front of $baseUrl (HTTP ${res.status})", T.seerr.behindAuthProxy, res.status)
        }
        val data = res.data
        if (res.status >= 400 || data !is JsonObject) {
            throw SeerrException.Url(
                "No Seerr instance at $baseUrl (HTTP ${res.status})",
                T.seerr.noInstanceAtUrl(url = baseUrl, status = res.status.toString()),
                res.status,
            )
        }
        val settings = SeerrPublicSettings.fromJson(data)
        if (!settings.initialized) {
            throw SeerrException.Url("Seerr instance has not completed first-run setup", T.seerr.notInitialized, res.status)
        }
        return settings
    }

    /** `POST /auth/plex` with the profile's Plex token, which the session never keeps. */
    suspend fun signInWithPlex(baseUrl: String, plexToken: String): SeerrSession = signIn(
        baseUrl,
        SeerrAuthMethod.PLEX,
        "/auth/plex",
        buildJsonObject { put("authToken", plexToken) },
        identifier = "",
        secret = "",
    )

    /** `POST /auth/jellyfin` with Jellyfin ([emby] false) or Emby credentials. */
    suspend fun signInWithJellyfin(baseUrl: String, username: String, password: String, emby: Boolean = false): SeerrSession = signIn(
        baseUrl,
        if (emby) SeerrAuthMethod.EMBY else SeerrAuthMethod.JELLYFIN,
        "/auth/jellyfin",
        buildJsonObject {
            put("username", username)
            put("password", password)
            put("serverType", if (emby) SeerrMediaServerType.EMBY else SeerrMediaServerType.JELLYFIN)
        },
        identifier = username,
        secret = password,
    )

    /** `POST /auth/local` with a Seerr local account. */
    suspend fun signInWithLocal(baseUrl: String, email: String, password: String): SeerrSession = signIn(
        baseUrl,
        SeerrAuthMethod.LOCAL,
        "/auth/local",
        buildJsonObject {
            put("email", email)
            put("password", password)
        },
        identifier = email,
        secret = password,
    )

    /**
     * `POST /auth/jellyfin/quickconnect/initiate` (Seerr 3.4+), unauthenticated: starts a Jellyfin Quick Connect the
     * instance proxies. The secret is registered with the log redactor (it rides in the poll's query).
     *
     * @throws SeerrException.Proxy when an auth proxy answered.
     * @throws SeerrException.Auth when the instance predates the routes (404), refused (Quick Connect off on its
     *   Jellyfin, an Emby backend), or answered without a code or secret.
     */
    suspend fun initiateQuickConnect(baseUrl: String): SeerrQuickConnectInitiation {
        val res = SeerrHttp(baseUrl, http).send(HttpMethod.Post, QC_INITIATE_PATH, timeout = SeerrConstants.AUTH_TIMEOUT, authenticated = false)
        SeerrHttp.throwIfIntermediary(res, QC_INITIATE_PATH)
        val data = res.data as? JsonObject
        val message = data?.str("message")
        if (res.status == 404) {
            throw SeerrException.Auth("Seerr has no Quick Connect proxy routes (needs 3.4+)", T.seerr.quickConnectUnsupported, res.status)
        }
        if (res.status >= 400) {
            throw SeerrException.Auth(
                message ?: "Quick Connect rejected (HTTP ${res.status})",
                T.addServer.quickConnectFailed(error = message ?: "HTTP ${res.status}"),
                res.status,
            )
        }
        val code = data?.str("code")
        val secret = data?.str("secret")
        if (code.isNullOrEmpty() || secret.isNullOrEmpty()) {
            throw SeerrException.Auth("Quick Connect response is missing a code or secret", T.addServer.quickConnectMissingFields)
        }
        LogRedaction.registerCustomValue(secret)
        return SeerrQuickConnectInitiation(code, secret)
    }

    /**
     * Polls `GET /auth/jellyfin/quickconnect/check` every [SeerrConstants.QUICK_CONNECT_POLL_INTERVAL] until the code
     * is approved inside Jellyfin, then exchanges [secret] through `POST …/authenticate` for a session. Returns null
     * when [timeout] passes or the instance drops the secret mid-poll (404); a transport blip keeps polling. Cancel the
     * caller to give up.
     *
     * @throws SeerrException.Auth when the instance rejects the poll, or the exchange fails as any sign-in can.
     */
    suspend fun signInWithQuickConnect(
        baseUrl: String,
        secret: String,
        timeout: Duration = SeerrConstants.QUICK_CONNECT_WINDOW,
    ): SeerrSession? {
        val client = SeerrHttp(baseUrl, http)
        val approved = withTimeoutOrNull(timeout) { awaitQuickConnectApproval(client, secret) }
        if (approved != true) return null
        return signIn(
            baseUrl,
            SeerrAuthMethod.QUICK_CONNECT,
            "/auth/jellyfin/quickconnect/authenticate",
            buildJsonObject { put("secret", secret) },
            identifier = "",
            secret = "",
        )
    }

    /** Polls until the code is approved (true) or the instance drops the secret (false). */
    private suspend fun awaitQuickConnectApproval(client: SeerrHttp, secret: String): Boolean {
        while (true) {
            when (pollQuickConnect(client, secret)) {
                QuickConnectPoll.APPROVED -> return true
                QuickConnectPoll.EXPIRED -> return false
                QuickConnectPoll.WAITING -> delay(SeerrConstants.QUICK_CONNECT_POLL_INTERVAL)
            }
        }
    }

    private enum class QuickConnectPoll { WAITING, APPROVED, EXPIRED }

    private suspend fun pollQuickConnect(client: SeerrHttp, secret: String): QuickConnectPoll {
        val res = try {
            client.send(HttpMethod.Get, QC_CHECK_PATH, query = mapOf("secret" to secret), timeout = SeerrConstants.AUTH_TIMEOUT, authenticated = false)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "Quick Connect poll blip" }
            return QuickConnectPoll.WAITING
        }
        // The secret expired or was revoked on the server.
        if (res.status == 404) return QuickConnectPoll.EXPIRED
        if (SeerrHttp.classify(res, QC_CHECK_PATH) == SeerrRejection.CREDENTIALS) {
            throw SeerrException.Auth(
                (res.data as? JsonObject)?.str("message") ?: "Quick Connect poll rejected",
                T.addServer.quickConnectPollRejected,
                res.status,
            )
        }
        SeerrHttp.throwForStatus(res, QC_CHECK_PATH)
        return if ((res.data as? JsonObject)?.bool("authenticated") == true) QuickConnectPoll.APPROVED else QuickConnectPoll.WAITING
    }

    /**
     * Signs in again with what [session] keeps ([plexToken] for a Plex session) and returns it with the new cookie,
     * permissions and display name.
     *
     * @throws SeerrException.ReauthUnavailable when there is no Plex token right now (retryable: not an unlink), or
     *   the login resolved to another Seerr user.
     * @throws SeerrException.Auth when nothing is stored to sign in with (Quick Connect, an empty secret), or the
     *   instance rejected the stored credentials: the session is gone for good.
     */
    suspend fun reauth(session: SeerrSession, plexToken: String? = null): SeerrSession {
        val fresh = when {
            session.method == SeerrAuthMethod.PLEX && !plexToken.isNullOrEmpty() -> signInWithPlex(session.baseUrl, plexToken)
            session.method == SeerrAuthMethod.PLEX ->
                throw SeerrException.ReauthUnavailable("No Plex token available for silent re-auth", T.seerr.noPlexTokenForReauth)
            (session.method == SeerrAuthMethod.JELLYFIN || session.method == SeerrAuthMethod.EMBY) && session.secret.isNotEmpty() ->
                signInWithJellyfin(session.baseUrl, session.identifier, session.secret, emby = session.method == SeerrAuthMethod.EMBY)
            session.method == SeerrAuthMethod.LOCAL && session.secret.isNotEmpty() ->
                signInWithLocal(session.baseUrl, session.identifier, session.secret)
            else -> throw SeerrException.Auth("No stored credentials for silent re-auth", T.seerr.noStoredCredentials)
        }
        if (fresh.userId != session.userId) {
            // Never pair another user's cookie with this binding's identity and credentials.
            throw SeerrException.ReauthUnavailable("Silent re-auth returned a different Seerr user", T.seerr.noUserInformation)
        }
        return session.copy(cookie = fresh.cookie, permissions = fresh.permissions, displayName = fresh.displayName)
    }

    /** Best-effort `POST /auth/logout`; a failure is only logged. */
    suspend fun signOut(session: SeerrSession) {
        try {
            SeerrHttp(session.baseUrl, http, session.cookie).send(HttpMethod.Post, "/auth/logout", timeout = SeerrConstants.AUTH_TIMEOUT)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "sign-out failed (best effort)" }
        }
    }

    private suspend fun signIn(
        baseUrl: String,
        method: SeerrAuthMethod,
        path: String,
        body: JsonObject,
        identifier: String,
        secret: String,
    ): SeerrSession {
        val client = SeerrHttp(baseUrl, http)
        val res = client.send(HttpMethod.Post, path, body = body, timeout = SeerrConstants.AUTH_TIMEOUT, authenticated = false)
        if (SeerrHttp.classify(res, path) == SeerrRejection.CREDENTIALS) {
            // The classifier only says CREDENTIALS for an object whose message is a string.
            throw SeerrException.Auth((res.data as JsonObject).str("message")!!, T.seerr.signInRejected, res.status)
        }
        SeerrHttp.throwForStatus(res, path)
        if (!client.captureSessionCookie(res.headers)) {
            throw SeerrException.Auth("Seerr did not issue a session cookie", T.seerr.noSessionCookie)
        }
        val user = fetchUser(client)
        return SeerrSession(
            baseUrl = client.baseUrl,
            method = method,
            identifier = identifier,
            secret = secret,
            cookie = checkNotNull(client.cookie),
            userId = user.id,
            permissions = user.permissions,
            displayName = user.displayName ?: identifier,
            instanceLabel = "",
            createdAt = clock.now().epochSeconds,
        )
    }

    /**
     * The user behind a fresh cookie, from `GET /auth/me`. Never from the login body: each login route returns whatever
     * user entity it built, and `POST /auth/local`'s carries permissions 0 rather than the stored mask.
     */
    private suspend fun fetchUser(client: SeerrHttp): SeerrUser {
        val res = client.send(HttpMethod.Get, ME_PATH, timeout = SeerrConstants.AUTH_TIMEOUT)
        if (SeerrHttp.classify(res, ME_PATH) == SeerrRejection.SESSION) {
            throw SeerrException.Auth("Seerr rejected the fresh session cookie", T.seerr.freshCookieRejected, res.status)
        }
        SeerrHttp.throwForStatus(res, ME_PATH)
        (res.data as? JsonObject)?.let(SeerrUser::fromJson)?.let { return it }
        Log.w(TAG) { "/auth/me returned an unusable user" }
        throw SeerrException.Auth("Seerr did not return user information", T.seerr.noUserInformation)
    }

    companion object {
        private const val TAG = "seerr"
        private const val PRODUCT = "Seerr"
        internal const val ME_PATH = "/auth/me"
        internal const val SETTINGS_PATH = "/settings/public"
        private const val QC_INITIATE_PATH = "/auth/jellyfin/quickconnect/initiate"
        private const val QC_CHECK_PATH = "/auth/jellyfin/quickconnect/check"

        /**
         * Schemeless guesses: a bare host is usually a public instance behind a reverse proxy (TLS), else a LAN install
         * on plain HTTP, at its default port or behind a proxy on port 80.
         */
        private val SCHEMELESS_GUESSES = listOf(
            BaseUrlGuess("https", null),
            BaseUrlGuess("http", null),
            BaseUrlGuess("http", SeerrConstants.DEFAULT_PORT),
        )

        /**
         * The addresses a typed [input] may mean: as typed when it has a scheme; else `https://host`, `http://host` and
         * `http://host:5055`, a typed port replacing every guessed one. Only the candidate that answers is kept.
         */
        fun expandUrlCandidates(input: String): List<String> = expandBaseUrlCandidates(input, SCHEMELESS_GUESSES)
    }
}
