package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.net.FailoverHttpClient
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.fallbackPageTotal
import com.edde746.plezy.net.UriComponent
import io.ktor.client.HttpClient
import io.ktor.http.HttpMethod
import kotlin.concurrent.Volatile
import kotlin.time.Duration.Companion.milliseconds
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/** A server answer: the status and the body parsed as JSON (null when empty or not JSON). */
class JellyfinResponse(val status: Int, val data: JsonElement?, val text: String) {
    val isSuccess: Boolean get() = status in 200..299

    /** Non-2xx as [MediaServerHttpException] carrying the status. */
    fun throwIfError(): JellyfinResponse {
        if (!isSuccess) throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "HTTP $status", statusCode = status, responseData = data)
        return this
    }

    val obj: JsonObject? get() = data as? JsonObject
}

/**
 * What every part of the client shares: the connection, the dialect's routes and field sets, the authenticated HTTP
 * transport, item mapping and token-in-URL handling.
 */
class JellyfinCore(
    connection: JellyfinConnection,
    http: HttpClient,
    val identity: JellyfinDeviceIdentity,
    val codecs: VideoCodecSupport = VideoCodecSupport(),
    /** The persisted response cache, keyed by [cacheServerId] and the endpoint; null keeps nothing. */
    val store: ApiCacheStore? = null,
    /** A switch to another of the connection's URLs; persisted ones are for the caller to store. */
    private val onConnectionUpdated: suspend (JellyfinConnection) -> Unit = {},
    onAllEndpointsExhausted: (() -> Unit)? = null,
) {
    /**
     * Replaced on endpoint switch and when the health check refreshes admin status or the avatar tag. Volatile: a
     * failover switches it on the thread of the request that failed over, while others read it.
     */
    @Volatile
    var connection: JellyfinConnection = connection
        internal set

    init {
        // Before any request: the first probe's URL and token never reach a log line verbatim.
        LogRedaction.registerToken(connection.accessToken)
        connection.baseUrls.forEach(LogRedaction::registerServerUrl)
    }

    /**
     * The authenticated transport over the connection's URLs, active first. Another URL is only taken when its public
     * info reports this server's machine id.
     */
    internal val transport = FailoverHttpClient(
        http = http,
        baseUrl = connection.baseUrl,
        defaultHeaders = defaultHeadersFor(connection, identity),
        logLabel = "Jellyfin",
        prioritizedEndpoints = connection.baseUrls,
        onEndpointSwitch = { url, persist -> switchEndpoint(url, persist) },
        onAllEndpointsExhausted = onAllEndpointsExhausted,
        validateCandidate = { url -> JellyfinEndpointDiscovery(http, connection.dialect).probe(url).machineId == connection.serverMachineId },
    )

    private suspend fun switchEndpoint(url: String, persist: Boolean) {
        if (connection.baseUrl != url) {
            Log.i(TAG) { "Applying Jellyfin endpoint switch" }
            transport.baseUrl = url
            connection = connection.copy(baseUrl = url)
        }
        if (persist) onConnectionUpdated(connection)
    }

    /** Health-check refresh of admin status or avatar tag: kept and handed to the caller. */
    internal suspend fun updateConnection(updated: JellyfinConnection) {
        connection = updated
        onConnectionUpdated(updated)
    }

    val dialect: MediaBrowserDialect get() = connection.dialect
    val paths = MediaBrowserPaths(connection.dialect, connection.userId)
    val userId: String get() = connection.userId
    val serverId: String get() = connection.serverMachineId

    /** Cache namespace: `{machineId}/{userId}`, so per-user data never mixes. */
    val cacheServerId: String get() = connection.id

    var offlineMode: Boolean = false

    /** The account's DisplayPreferences switch; only Jellyfin understands `EnableRewatching`. */
    var rewatchingInNextUp: Boolean = false

    /** Reads the switch from the server; the first Next Up request runs it once and every request waits for it. */
    @Volatile
    var loadRewatchingInNextUp: (suspend () -> Unit)? = null
    private val rewatchingLoad = Mutex()

    suspend fun sendNextUpRewatching(): Boolean {
        if (!dialect.supportsNextUpRewatching) return false
        if (loadRewatchingInNextUp != null) {
            rewatchingLoad.withLock {
                loadRewatchingInNextUp?.let { load ->
                    load()
                    loadRewatchingInNextUp = null
                }
            }
        }
        return rewatchingInNextUp
    }

    /** Sent on every request; see [defaultHeadersFor]. */
    val defaultHeaders: Map<String, String> get() = transport.defaultHeaders

    suspend fun request(
        method: HttpMethod,
        path: String,
        query: List<Pair<String, String?>> = emptyList(),
        body: JsonElement? = null,
        timeoutMillis: Long? = null,
        allowEndpointFailover: Boolean = true,
        rawBody: Pair<String, String>? = null,
    ): JellyfinResponse {
        val params = query.mapNotNull { (k, v) -> v?.let { k to it } }.toMap(LinkedHashMap<String, Any?>()).ifEmpty { null }
        val timeout = timeoutMillis?.milliseconds
        val response = when (method) {
            HttpMethod.Get -> transport.get(path, params, timeout = timeout, allowEndpointFailover = allowEndpointFailover)
            HttpMethod.Post -> if (rawBody != null) {
                transport.post(path, params, headers = mapOf("Content-Type" to rawBody.second), body = rawBody.first, timeout = timeout)
            } else {
                transport.post(path, params, body = body, timeout = timeout)
            }
            HttpMethod.Delete -> transport.delete(path, params, timeout = timeout)
            else -> throw IllegalArgumentException("Unsupported method $method")
        }
        return JellyfinResponse(response.statusCode, response.data, response.text.orEmpty())
    }

    suspend fun get(path: String, query: List<Pair<String, String?>> = emptyList(), timeoutMillis: Long? = null, allowEndpointFailover: Boolean = true) =
        request(HttpMethod.Get, path, query, null, timeoutMillis, allowEndpointFailover)

    suspend fun post(path: String, query: List<Pair<String, String?>> = emptyList(), body: JsonElement? = null, timeoutMillis: Long? = null) =
        request(HttpMethod.Post, path, query, body, timeoutMillis)

    /** GETs [path] as bytes, at most [maxBytes]; non-2xx and an oversized body are [MediaServerHttpException]s. */
    suspend fun getBytes(path: String, timeoutMillis: Long? = null, maxBytes: Long): ByteArray =
        transport.getBytes(connection.baseUrl + path, headers = transport.defaultHeaders, timeout = timeoutMillis?.milliseconds, maxBytes = maxBytes)

    /** POSTs [text] verbatim as [contentType]: image uploads take base64 text typed as the image. */
    suspend fun postText(path: String, text: String, contentType: String) = request(HttpMethod.Post, path, rawBody = text to contentType)

    suspend fun delete(path: String, query: List<Pair<String, String?>> = emptyList()) = request(HttpMethod.Delete, path, query)

    /** The `Items` array of an object body, or a bare array; anything else is empty. */
    fun itemsArray(data: JsonElement?): List<JsonObject> = when (data) {
        is JsonObject -> (data["Items"] as? JsonArray)?.filterIsInstance<JsonObject>().orEmpty()
        is JsonArray -> data.filterIsInstance<JsonObject>()
        else -> emptyList()
    }

    /**
     * A page of [data]'s items. The total is an int `TotalRecordCount`, else a sentinel that keeps paging while pages
     * come back full; a [singlePage] endpoint returns everything, so its full page is the end.
     */
    fun <T> pagedItems(data: JsonElement?, offset: Int, requestedSize: Int?, singlePage: Boolean = false, map: (List<JsonObject>) -> List<T>): LibraryPage<T> {
        val raw = itemsArray(data)
        val total = (data as? JsonObject)?.int("TotalRecordCount")
            ?: if (singlePage) offset + raw.size else fallbackPageTotal(offset, raw.size, requestedSize)
        return LibraryPage(map(raw), total, offset)
    }

    val absolutizer: JellyfinImageAbsolutizer get() = JellyfinImageAbsolutizer(connection.baseUrl)

    fun mapItem(json: JsonObject): MediaItem? = JellyfinMappers.mediaItem(json, serverId, connection.serverName, absolutizer, dialect)

    fun mapItems(items: Iterable<JsonObject>): List<MediaItem> = items.mapNotNull(::mapItem)

    /**
     * [urlOrPath] joined to the server, with the dialect's token parameter added only when the URL's origin is the
     * server's own: a server can hand out URLs of remote subtitle providers or tuners, which must never see the token.
     */
    fun withApiKey(urlOrPath: String): String {
        val url = JellyfinImageAbsolutizer.joinUrl(connection.baseUrl, urlOrPath)
        return if (origin(url) == origin(connection.baseUrl)) {
            JellyfinImageAbsolutizer.setQueryParam(url, dialect.tokenQueryParam, connection.accessToken)
        } else {
            url
        }
    }

    // Field sets. Emby withholds year, rating, dates and the played date on list rows unless named.
    val browseFields get() = withDialectRowFields(BROWSE_FIELDS)
    val hubRowFields get() = withDialectRowFields(HUB_ROW_FIELDS)
    val episodeRowFields get() = withDialectRowFields(EPISODE_ROW_FIELDS)
    val folderBrowseFields get() = withDialectRowFields(FOLDER_BROWSE_FIELDS)
    val folderRowFields get() = withDialectRowFields(FOLDER_ROW_FIELDS)
    val musicAlbumRowFields get() = withDialectRowFields(MUSIC_ALBUM_ROW_FIELDS)
    val musicTrackRowFields get() = withDialectRowFields(MUSIC_TRACK_ROW_FIELDS)
    val queueFields get() = withDialectRowFields(QUEUE_FIELDS)

    /**
     * On Emby, appends the row fields it withholds (`UserDataLastPlayedDate` is the only way to get a row's played
     * date), plus `AlternateMediaSources` next to `MediaSources` (else merged versions collapse to one). Jellyfin
     * strings stay byte-identical.
     */
    fun withDialectRowFields(fields: String): String {
        if (dialect != MediaBrowserDialect.EMBY) return fields
        val present = fields.split(',').map { it.trim() }.toSet()
        val missing = EMBY_WITHHELD_ROW_FIELDS.filter { it !in present } +
            listOfNotNull("AlternateMediaSources".takeIf { "MediaSources" in present && it !in present })
        return if (missing.isEmpty()) fields else fields + "," + missing.joinToString(",")
    }

    companion object {
        private const val TAG = "JellyfinCore"

        /**
         * Both the MediaBrowser header (reverse proxies reject token-only requests) and `X-Emby-Token` (old servers).
         * `Content-Type` exactly `application/json`: Jellyfin answers 415 on `/Sessions/Playing*` with a charset suffix.
         */
        fun defaultHeadersFor(connection: JellyfinConnection, identity: JellyfinDeviceIdentity): Map<String, String> = mapOf(
            "Authorization" to identity.authorization(connection.accessToken),
            "X-Emby-Token" to connection.accessToken,
            "Accept" to "application/json",
            "Content-Type" to "application/json",
        )

        /** CanDelete on the rows a menu opens from: whether it offers Delete, without a request per item. */
        const val BROWSE_FIELDS = "RecursiveItemCount,ChildCount,OriginalTitle,SortName,Overview,DateCreated,CanDelete"
        /** No count fields: Latest returns Series folders and counts cost a DB query per row. */
        const val HUB_ROW_FIELDS = "Overview,DateCreated,CanDelete"
        const val EPISODE_ROW_FIELDS = "$BROWSE_FIELDS,MediaSources"
        const val FOLDER_BROWSE_FIELDS = "UserData,PremiereDate,OriginalTitle,SortName,CanDelete"
        const val FOLDER_ROW_FIELDS = "SortName"
        const val MUSIC_ALBUM_ROW_FIELDS = "PremiereDate,OriginalTitle,SortName,DateCreated"
        const val MUSIC_TRACK_ROW_FIELDS = "UserData,PremiereDate,OriginalTitle,SortName"
        const val QUEUE_FIELDS = "UserData,PremiereDate"
        const val DETAIL_FIELDS = "Overview,Genres,People,Studios,ProductionLocations,Tags,Taglines,DateCreated,DateLastSaved," +
            "PremiereDate,RecursiveItemCount,ChildCount,UserData,MediaSources,OriginalTitle,SortName,Chapters,Trickplay,ProviderIds,CanDelete"
        val EMBY_WITHHELD_ROW_FIELDS = listOf("ProductionYear", "OfficialRating", "PremiereDate", "DateCreated", "UserDataLastPlayedDate")

        /** Image params on list requests. */
        val IMAGE_PARAMS = listOf("EnableImageTypes" to "Primary,Backdrop,Logo", "ImageTypeLimit" to "3")

        fun segment(value: String) = UriComponent.encode(value)

        /** `?a=b&c=d` with values form-encoded; null values dropped; empty when nothing remains. */
        fun queryString(query: List<Pair<String, String?>>): String {
            val present = query.mapNotNull { (k, v) -> v?.let { k to it } }
            return if (present.isEmpty()) "" else "?" + JellyfinUrls.query(present)
        }

        private val ORIGIN = Regex("^([A-Za-z][A-Za-z0-9+.\\-]*)://([^/?#]*)")
        private val PORT_SUFFIX = Regex(":\\d+$")

        /** `scheme://host:port` with the default port made explicit, lowercased; null for a relative URL. */
        internal fun origin(url: String): String? {
            val m = ORIGIN.find(url) ?: return null
            val scheme = m.groupValues[1].lowercase()
            val authority = m.groupValues[2].substringAfterLast('@').lowercase()
            val hasPort = PORT_SUFFIX.containsMatchIn(authority) && !authority.endsWith("]")
            val host = if (hasPort) authority.substringBeforeLast(':') else authority
            val port = if (hasPort) authority.substringAfterLast(':') else when (scheme) { "https" -> "443"; "http" -> "80"; else -> "" }
            return "$scheme://$host:$port"
        }
    }
}
