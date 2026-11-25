package com.edde746.plezy.jellyfin

import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.model.MediaBrowserDialect
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpTimeout
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.Url
import io.ktor.http.content.TextContent
import io.ktor.http.headersOf
import io.ktor.util.CaseInsensitiveMap
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers

/** One request the fake server saw. [query] decoded; [body] the raw text sent. */
data class RecordedRequest(val method: String, val url: Url, val headers: Map<String, String>, val body: String) {
    val path: String get() = url.encodedPath
    val query: Map<String, String> get() = url.parameters.entries().associate { it.key to it.value.first() }
}

/** A canned answer: status and JSON text, or raw [bytes] when set. */
class FakeResponse(val status: Int = 200, val body: String = "{}", val bytes: ByteArray? = null)

/**
 * A MockEngine-backed server for client tests: records every request and answers through [handler]
 * (default: `{}` with 200).
 */
class JellyfinTestServer(
    /** `StandardTestDispatcher(testScheduler)` runs requests on the test scheduler, so deadlines see virtual time. */
    dispatcher: CoroutineDispatcher? = null,
    var handler: suspend (RecordedRequest) -> FakeResponse = { FakeResponse() },
) {
    val requests = mutableListOf<RecordedRequest>()

    val engine = MockEngine(MockEngineConfig().apply {
        // Inline by default: an engine on another dispatcher lets runTest's virtual clock run the client's deadlines out.
        this.dispatcher = dispatcher ?: Dispatchers.Unconfined
        addHandler { data ->
        val body = (data.body as? TextContent)?.text ?: ""
        // Header names are case-insensitive on the wire; the client sends them lowercased.
        val headers = CaseInsensitiveMap<String>().apply {
            data.headers.entries().forEach { put(it.key, it.value.first()) }
            data.body.contentType?.let { put("Content-Type", it.toString()) }
        }
        val recorded = RecordedRequest(data.method.value, data.url, headers, body)
        requests += recorded
        val answer = handler(recorded)
        val bytes = answer.bytes
        if (bytes != null) {
            respond(bytes, HttpStatusCode.fromValue(answer.status), headersOf(HttpHeaders.ContentType, "application/octet-stream"))
        } else {
            respond(answer.body, HttpStatusCode.fromValue(answer.status), headersOf(HttpHeaders.ContentType, "application/json"))
        }
        }
    })

    val http = HttpClient(engine) {
        install(HttpTimeout)
        expectSuccess = false
    }

    fun connection(dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN, baseUrls: List<String> = emptyList()) = JellyfinConnection(
        id = "machine-1/user-1",
        baseUrl = "http://jf.local:8096",
        baseUrls = baseUrls,
        serverName = "Home",
        serverMachineId = "machine-1",
        userId = "user-1",
        userName = "edde",
        accessToken = "tok-abc",
        deviceId = "dev-1",
        dialect = dialect,
        createdAt = 0,
    )

    val store = InMemoryApiCacheStore()

    fun core(dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN) =
        JellyfinCore(connection(dialect), http, JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", "dev-1"), store = store)

    /** The Live TV adapter over one core of [dialect]; favourites go through [readFavorites] and [writeFavorites]. */
    internal fun liveTv(
        scope: CoroutineScope,
        dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
        readFavorites: suspend (String) -> List<FavoriteChannel> = { emptyList() },
        writeFavorites: suspend (String, List<FavoriteChannel>) -> Unit = { _, _ -> },
    ): JellyfinLiveTvSupport {
        val core = core(dialect)
        val playback = JellyfinPlayback(core, fetchItem = { null }, fetchItemFreshCacheFirst = { null }, cachedItem = { null })
        return JellyfinLiveTvSupport(core, playback, JellyfinWatchState(core)::setItemFavorite, readFavorites, writeFavorites, scope)
    }

    /** The single request to [path] (fails when there are none or several). */
    fun single(path: String): RecordedRequest = requests.single { it.path == path }
}
