package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerAuthException
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** `POST /QuickConnect/Initiate`: [code] is shown to the user to approve; [secret] is the polling/exchange handle. */
data class JellyfinQuickConnectInitiation(val code: String, val secret: String)

/**
 * Sign-in for a new Jellyfin/Emby connection: probe the URL, then exchange a password or an approved Quick Connect
 * secret for a token. Every request carries the device identity, never a token. [requestTimeout] bounds each request;
 * Quick Connect deadlines and probe latency run on [timeSource].
 */
class JellyfinAuthService(
    private val http: HttpClient,
    private val identity: JellyfinDeviceIdentity,
    val dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
    private val requestTimeout: Duration = MediaServerTimeouts.JELLYFIN_PROBE,
    private val now: () -> Long = { Clock.System.now().toEpochMilliseconds() },
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    private val discovery = JellyfinEndpointDiscovery(http, dialect, timeSource)

    private class AuthenticationResponse(
        val accessToken: String,
        val userId: String,
        val userName: String,
        val isAdministrator: Boolean,
        val primaryImageTag: String?,
    )

    suspend fun probe(baseUrl: String): JellyfinServerInfo = discovery.probe(baseUrl, requestTimeout)

    suspend fun raceUserInput(input: JellyfinEndpointUserInputCandidates): JellyfinEndpointRaceResult = discovery.raceUserInput(input)

    /** Password sign-in. 401/403 is a [MediaServerAuthException]; other HTTP failures propagate as they are. */
    suspend fun authenticateByName(
        baseUrl: String,
        username: String,
        password: String,
        baseUrls: List<String> = emptyList(),
        serverInfo: JellyfinServerInfo? = null,
    ): JellyfinConnection {
        val authorization = authorization()
        val normalized = JellyfinEndpointDiscovery.normalizeBaseUrl(baseUrl)
        val info = serverInfo ?: probe(normalized)
        val body = buildJsonObject {
            put("Username", username)
            put("Pw", password)
        }
        val auth = readAuthentication(
            send(HttpMethod.Post, normalized, "/Users/AuthenticateByName", authorization, body),
            rejectedStatuses = setOf(401, 403),
            rejection = "Invalid username or password",
            rejectionDisplay = T.addServer.invalidCredentials,
            label = "Authentication response",
            notJsonDisplay = T.addServer.authResponseNotJson,
        )
        return buildConnection(info, normalized, baseUrls, auth)
    }

    /**
     * Whether Quick Connect is on. False without a request for dialects lacking it, and for any failure: Jellyfin
     * before 10.7 answers 404, and an offline server is as unusable as a disabled one.
     */
    suspend fun isQuickConnectEnabled(baseUrl: String): Boolean {
        if (!dialect.supportsQuickConnect) return false
        return try {
            val response = send(HttpMethod.Get, JellyfinEndpointDiscovery.normalizeBaseUrl(baseUrl), "/QuickConnect/Enabled", null)
            // The endpoint answers a bare JSON boolean.
            response.statusCode == 200 && (response.data as? JsonPrimitive)?.takeIf { !it.isString }?.booleanOrNull == true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            false
        }
    }

    /** Starts a Quick Connect session. Current Jellyfin takes GET; older builds only POST, answering GET with 405. */
    suspend fun initiateQuickConnect(baseUrl: String): JellyfinQuickConnectInitiation {
        requireQuickConnect()
        val authorization = authorization()
        val normalized = JellyfinEndpointDiscovery.normalizeBaseUrl(baseUrl)
        var response = send(HttpMethod.Get, normalized, "/QuickConnect/Initiate", authorization)
        if (response.statusCode == 405) response = send(HttpMethod.Post, normalized, "/QuickConnect/Initiate", authorization)
        if (response.statusCode == 401 || response.statusCode == 403) {
            throw MediaServerAuthException("Quick Connect rejected by server", response.statusCode, T.addServer.quickConnectRejected)
        }
        throwIfHttpError(response)
        val data = response.data as? JsonObject
            ?: throw MediaServerAuthException("Quick Connect response was not JSON", display = T.addServer.quickConnectNotJson)
        val code = data.str("Code")
        val secret = data.str("Secret")
        if (code == null || secret == null) {
            throw MediaServerAuthException("Quick Connect response missing Code or Secret", display = T.addServer.quickConnectMissingFields)
        }
        LogRedaction.registerCustomValue(secret)
        return JellyfinQuickConnectInitiation(code, secret)
    }

    /**
     * Polls until the user approves [secret] (backoff 1 s doubling to 5 s), then exchanges it for a token. Null on
     * [shouldCancel], [timeout], or a 404 (the secret expired server-side). 401/403 while polling, and 400/401/403 on
     * exchange, are [MediaServerAuthException]s; other poll failures are retried until the timeout.
     */
    suspend fun authenticateByQuickConnect(
        baseUrl: String,
        secret: String,
        baseUrls: List<String> = emptyList(),
        serverInfo: JellyfinServerInfo? = null,
        timeout: Duration = 5.minutes,
        shouldCancel: () -> Boolean = { false },
    ): JellyfinConnection? {
        requireQuickConnect()
        // Before it is sent: the secret is a credential until it expires.
        LogRedaction.registerCustomValue(secret)
        val authorization = authorization()
        val normalized = JellyfinEndpointDiscovery.normalizeBaseUrl(baseUrl)
        val info = serverInfo ?: probe(normalized)
        if (!pollApproval(normalized, secret, authorization, timeout, shouldCancel)) return null

        val auth = readAuthentication(
            send(HttpMethod.Post, normalized, "/Users/AuthenticateWithQuickConnect", authorization, buildJsonObject { put("Secret", secret) }),
            rejectedStatuses = setOf(400, 401, 403),
            rejection = "Quick Connect exchange rejected by server",
            rejectionDisplay = T.addServer.quickConnectRejected,
            label = "Quick Connect exchange",
            notJsonDisplay = T.addServer.quickConnectNotJson,
        )
        return buildConnection(info, normalized, baseUrls, auth)
    }

    private suspend fun pollApproval(
        baseUrl: String,
        secret: String,
        authorization: String,
        timeout: Duration,
        shouldCancel: () -> Boolean,
    ): Boolean {
        val deadline = timeSource.markNow() + timeout
        var backoff = 1.seconds
        while (deadline.hasNotPassedNow()) {
            if (shouldCancel()) return false
            val status = try {
                val response = send(HttpMethod.Get, baseUrl, "/QuickConnect/Connect", authorization, query = mapOf("secret" to secret))
                if (response.statusCode in 200..299 && (response.data as? JsonObject)?.bool("Authenticated") == true) return true
                response.statusCode
            } catch (e: MediaServerHttpException) {
                // A network blip: the backoff retries and the deadline bounds a durably broken server.
                e.statusCode
            }
            if (status == 404) return false
            if (status == 401 || status == 403) {
                throw MediaServerAuthException("Quick Connect poll rejected by server", status, T.addServer.quickConnectPollRejected)
            }
            delay(backoff)
            backoff = (backoff * 2).coerceAtMost(5.seconds)
        }
        return false
    }

    /** Emby answers 404 on every Quick Connect route, so it is refused without a request. */
    private fun requireQuickConnect() {
        if (!dialect.supportsQuickConnect) {
            throw MediaServerAuthException("Quick Connect rejected by server", display = T.addServer.quickConnectRejected)
        }
    }

    private fun authorization(): String {
        JellyfinAuthHeader.requireDeviceId(identity.deviceId)
        return identity.authorization()
    }

    /**
     * One unauthenticated request; transport failures and timeouts are [MediaServerHttpException]s. An error status
     * with an undecodable body still answers its status: auth rejections are judged by status alone.
     */
    private suspend fun send(
        method: HttpMethod,
        baseUrl: String,
        path: String,
        authorization: String?,
        body: JsonObject? = null,
        query: Map<String, Any?>? = null,
    ): MediaServerResponse {
        LogRedaction.registerServerUrl(baseUrl)
        val client = MediaServerHttpClient(http, baseUrl, listOfNotNull(authorization?.let { HttpHeaders.Authorization to it }).toMap())
        return try {
            when (method) {
                HttpMethod.Post -> client.post(path, query, body = body, timeout = requestTimeout)
                else -> client.get(path, query, timeout = requestTimeout)
            }
        } catch (e: MediaServerHttpException) {
            val status = e.statusCode
            val uri = e.requestUri
            if (status == null || status < 400 || uri == null) throw e
            MediaServerResponse(status, null, emptyMap(), uri)
        }
    }

    private fun readAuthentication(
        response: MediaServerResponse,
        rejectedStatuses: Set<Int>,
        rejection: String,
        rejectionDisplay: String,
        label: String,
        notJsonDisplay: String,
    ): AuthenticationResponse {
        if (response.statusCode in rejectedStatuses) throw MediaServerAuthException(rejection, response.statusCode, rejectionDisplay)
        throwIfHttpError(response)
        val data = response.data as? JsonObject
            ?: throw MediaServerAuthException("$label was not JSON", display = notJsonDisplay)
        val accessToken = data.str("AccessToken")
        val user = data.obj("User")
        if (accessToken == null || user == null) {
            throw MediaServerAuthException("$label missing AccessToken or User", display = T.addServer.authResponseIncomplete)
        }
        val userId = user.str("Id")
        val userName = user.str("Name")
        if (userId == null || userName == null) {
            throw MediaServerAuthException("$label missing User.Id or User.Name", display = T.addServer.authResponseIncomplete)
        }
        return AuthenticationResponse(
            accessToken = accessToken,
            userId = userId,
            userName = userName,
            isAdministrator = user.obj("Policy")?.bool("IsAdministrator") ?: false,
            primaryImageTag = JellyfinConnection.readPrimaryImageTag(user),
        )
    }

    /** One row per user per server: id `{machineId}/{userId}`; a detected dialect beats the one the user picked. */
    private fun buildConnection(
        info: JellyfinServerInfo,
        baseUrl: String,
        baseUrls: List<String>,
        auth: AuthenticationResponse,
    ): JellyfinConnection {
        val at = now()
        return JellyfinConnection(
            id = "${info.machineId}/${auth.userId}",
            baseUrl = baseUrl,
            baseUrls = baseUrls,
            serverName = info.serverName,
            serverMachineId = info.machineId,
            userId = auth.userId,
            userName = auth.userName,
            accessToken = auth.accessToken,
            deviceId = identity.deviceId,
            dialect = info.dialect ?: dialect,
            isAdministrator = auth.isAdministrator,
            primaryImageTag = auth.primaryImageTag,
            createdAt = at,
            lastAuthenticatedAt = at,
        )
    }
}
