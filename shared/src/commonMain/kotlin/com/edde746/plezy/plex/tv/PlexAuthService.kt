package com.edde746.plezy.plex.tv

import com.edde746.plezy.backend.MediaServerAuthException
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerPinExpiredException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.encodeQueryParameters
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesCapabilities
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.AccountPreferencesSource
import com.edde746.plezy.plex.PLEX_PRODUCT
import com.edde746.plezy.plex.PlexHome
import com.edde746.plezy.plex.PlexServer
import com.edde746.plezy.plex.flexInt
import com.edde746.plezy.plex.parsePlexSwitchAuthToken
import com.edde746.plezy.plex.stringOrNull
import io.ktor.client.HttpClient
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** A plex.tv sign-in PIN: [id] to poll, [code] for the auth URL. */
data class PlexPin(val id: Int, val code: String)

/** plex.tv listed servers but none of them parsed; [invalidServers] are the rejected entries, for diagnosis. */
class PlexServerParsingException(message: String, val invalidServers: List<JsonObject>) : Exception(message)

/**
 * plex.tv's account API (v2): PIN sign-in, token checks, the account's servers and Home users, Home user switches and
 * account preferences. Calls go through [http] with plex.tv's time budget (15 s connect, 10 s response and body).
 *
 * Every call names this app: `Accept: application/json`, `X-Plex-Product`, `X-Plex-Client-Identifier`,
 * `X-Plex-Platform`, `X-Plex-Device-Name` (when known, header-sanitized by the caller) and the token when one is
 * given; no `X-Plex-Version`. Reads that plex.tv also serves from `clients.plex.tv` go there first and, on a transient
 * failure only (timeout, connection error), once more to `plex.tv`; an HTTP error is never retried.
 */
class PlexAuthService(
    http: HttpClient,
    val clientIdentifier: String,
    private val appVersion: String,
    /** The OS version string, sent only on Home user switches. */
    private val platformVersion: String,
    private val platform: String,
    private val deviceName: String? = null,
) {
    private val client = MediaServerHttpClient(
        http,
        connectTimeout = MediaServerTimeouts.PLEX_TV_CONNECT,
        responseTimeout = MediaServerTimeouts.PLEX_TV_RECEIVE,
        receiveTimeout = MediaServerTimeouts.PLEX_TV_RECEIVE,
    )

    private fun commonHeaders(authToken: String? = null): Map<String, String> = buildMap {
        put("Accept", "application/json")
        put("X-Plex-Product", PLEX_PRODUCT)
        put("X-Plex-Client-Identifier", clientIdentifier)
        put("X-Plex-Platform", platform)
        deviceName?.let { put("X-Plex-Device-Name", it) }
        authToken?.let { put("X-Plex-Token", it) }
    }

    private suspend fun getUser(authToken: String): MediaServerResponse =
        client.get("$PLEX_API/user", headers = commonHeaders(authToken), timeout = MediaServerTimeouts.PLEX_TV_RECEIVE)

    private suspend fun getClientsApi(path: String, authToken: String): MediaServerResponse {
        val headers = commonHeaders(authToken)
        return try {
            client.get("$CLIENTS_API$path", headers = headers)
        } catch (e: MediaServerHttpException) {
            if (!e.isTransient) throw e
            Log.w(TAG, e) { "Plex clients API $path failed; retrying via plex.tv" }
            client.get("$PLEX_API$path", headers = headers)
        }
    }

    /**
     * A new sign-in PIN. A [strong] one has a long code, for the auth link ([authUrl]); any other has a 4-character
     * code, short enough to type at plex.tv/link ([linkUrl]).
     */
    suspend fun createPin(strong: Boolean): PlexPin {
        val response = client.post("$PLEX_API/pins?strong=$strong", headers = commonHeaders(), timeout = MediaServerTimeouts.PLEX_TV_RECEIVE)
        throwIfHttpError(response)
        val data = response.data as? JsonObject ?: throw IllegalStateException("Plex PIN response is not an object")
        val id = data["id"].flexInt() ?: throw IllegalStateException("Plex PIN response has no id")
        val code = data["code"].stringOrNull() ?: throw IllegalStateException("Plex PIN response has no code")
        return PlexPin(id, code)
    }

    /** The page where the user signs in and claims [pinCode]; its parameters are in the fragment, not the query. */
    fun authUrl(pinCode: String): String = "https://app.plex.tv/auth#?" + encodeQueryParameters(
        mapOf("clientID" to clientIdentifier, "code" to pinCode, "context[device][product]" to PLEX_PRODUCT),
    )

    /**
     * plex.tv/link with [pinCode] filled in: the link plex.tv's own QR code of a PIN carries, where a signed-in user
     * claims it.
     */
    fun linkUrl(pinCode: String): String = "https://www.plex.tv/link/?" + encodeQueryParameters(mapOf("pin" to pinCode))

    /**
     * The account token once PIN [pinId] is claimed, null while it isn't. An expired PIN (404, 410) throws
     * [MediaServerPinExpiredException], a refused check (401, 403) [MediaServerAuthException].
     */
    suspend fun checkPin(pinId: Int): String? {
        val response = client.get("$PLEX_API/pins/$pinId", headers = commonHeaders(), timeout = MediaServerTimeouts.PLEX_TV_RECEIVE)
        when (response.statusCode) {
            404, 410 -> throw MediaServerPinExpiredException()
            401, 403 -> throw MediaServerAuthException("Plex PIN check rejected", statusCode = response.statusCode)
        }
        throwIfHttpError(response)
        return (response.data as? JsonObject)?.get("authToken").stringOrNull()
    }

    /**
     * Polls PIN [pinId] until it is claimed and returns the token, or null after [timeout]. The waits between checks
     * start at [initialBackoff] and double up to [maxBackoff] (1, 2, 4, 5, 5 … s), so a stalled sign-in doesn't hammer
     * plex.tv. A transient failure counts as "not yet": the sign-in in the browser may still be under way. Other
     * failures throw.
     */
    suspend fun pollPinUntilClaimed(
        pinId: Int,
        timeout: Duration = 2.minutes,
        initialBackoff: Duration = 1.seconds,
        maxBackoff: Duration = 5.seconds,
    ): String? = withTimeoutOrNull(timeout) {
        var backoff = initialBackoff
        var token: String? = null
        while (token == null) {
            token = try {
                checkPin(pinId)
            } catch (e: MediaServerHttpException) {
                if (!e.isTransient) throw e
                null
            }
            if (token == null) {
                delay(backoff)
                backoff = minOf(backoff * 2, maxBackoff)
            }
        }
        token
    }

    /**
     * The account's servers (`/resources`, `provides == "server"`). A server that doesn't parse is skipped; when every
     * listed server is malformed, [PlexServerParsingException]. No servers at all is an empty list.
     */
    suspend fun fetchServers(authToken: String): List<PlexServer> {
        val response = getClientsApi("/resources?includeHttps=1&includeRelay=1&includeIPv6=1", authToken)
        throwIfHttpError(response)
        val resources = response.data as? JsonArray ?: throw IllegalStateException("Plex resources response is not a list")
        val servers = mutableListOf<PlexServer>()
        val invalid = mutableListOf<JsonObject>()
        for (resource in resources.filterIsInstance<JsonObject>().filter { it["provides"].stringOrNull() == "server" }) {
            try {
                servers += PlexServer.fromJson(resource)
            } catch (e: IllegalArgumentException) {
                Log.w(TAG, e) { "Skipping a malformed Plex server" }
                invalid += resource
            }
        }
        if (servers.isEmpty() && invalid.isNotEmpty()) {
            throw PlexServerParsingException("No valid servers found. All ${invalid.size} server(s) have malformed data.", invalid)
        }
        return servers
    }

    /** The plex.tv account (`/user`): `username`, `email` and `uuid` among the rest. */
    suspend fun getUserInfo(authToken: String): JsonObject {
        val response = getUser(authToken)
        throwIfHttpError(response)
        return response.data as? JsonObject ?: throw IllegalStateException("Plex user response is not an object")
    }

    /** The account preferences plex.tv stores (`/user/profile`). */
    suspend fun getAccountPreferences(authToken: String): AccountPreferences {
        val response = getClientsApi("/user/profile", authToken)
        throwIfHttpError(response)
        val data = response.data as? JsonObject ?: throw IllegalStateException("Plex profile response is not an object")
        return PlexAccountPreferences.fromProfileJson(data)
    }

    /**
     * Writes [patch] as plex.tv takes it: only the changed keys, as query parameters, with an empty body. Returns the
     * profile plex.tv answers with, or reads it again when the answer is empty.
     */
    suspend fun updateAccountPreferences(authToken: String, patch: AccountPreferencesPatch): AccountPreferences {
        val response = client.put(
            "$CLIENTS_API/user/profile",
            query = PlexAccountPreferences.queryParametersFor(patch),
            headers = commonHeaders(authToken),
        )
        throwIfHttpError(response)
        val data = response.data as? JsonObject
        if (data != null && data.isNotEmpty()) return PlexAccountPreferences.fromProfileJson(data)
        return getAccountPreferences(authToken)
    }

    /** The account's Plex Home and its users. */
    suspend fun getHomeUsers(authToken: String): PlexHome {
        val response = getClientsApi("/home/users", authToken)
        throwIfHttpError(response)
        return PlexHome.fromJson(response.data as? JsonObject ?: throw IllegalStateException("Plex home response is not an object"))
    }

    /**
     * Switches into Home user [userUuid] and returns its freshly minted token. plex.tv takes this call's identity in the
     * query only (the headers carry nothing but `Accept`), [pin] included when given; there is no plex.tv fallback.
     */
    suspend fun switchToUser(userUuid: String, currentToken: String, pin: String? = null): String {
        val query = mapOf(
            "includeSubscriptions" to "1",
            "includeProviders" to "1",
            "includeSettings" to "1",
            "includeSharedSettings" to "1",
            "X-Plex-Product" to PLEX_PRODUCT,
            "X-Plex-Version" to appVersion,
            "X-Plex-Client-Identifier" to clientIdentifier,
            "X-Plex-Platform" to platform,
            "X-Plex-Platform-Version" to platformVersion,
            "X-Plex-Token" to currentToken,
            "X-Plex-Language" to "en",
            "pin" to pin,
        )
        val response = client.post(
            "$CLIENTS_API/home/users/$userUuid/switch",
            query = query,
            headers = mapOf("Accept" to "application/json"),
        )
        throwIfHttpError(response)
        return parsePlexSwitchAuthToken(response.data as? JsonObject ?: throw IllegalArgumentException("Plex /switch response is not an object"))
    }

    private companion object {
        const val TAG = "PlexAuth"
        const val PLEX_API = "https://plex.tv/api/v2"
        const val CLIENTS_API = "https://clients.plex.tv/api/v2"
    }
}

/** One Plex account's (or Home user's) preferences on plex.tv, read and written with [authToken]. */
class PlexAccountPreferencesSource(private val auth: PlexAuthService, private val authToken: String) : AccountPreferencesSource {
    override val capabilities: AccountPreferencesCapabilities get() = AccountPreferencesCapabilities.PLEX

    override suspend fun read(): AccountPreferences = auth.getAccountPreferences(authToken)

    override suspend fun write(patch: AccountPreferencesPatch, checkCurrent: (() -> Unit)?): AccountPreferences {
        capabilities.validate(patch)
        checkCurrent?.invoke()
        return auth.updateAccountPreferences(authToken, patch)
    }
}
