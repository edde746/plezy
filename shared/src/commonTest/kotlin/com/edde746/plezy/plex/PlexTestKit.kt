package com.edde746.plezy.plex

import com.edde746.plezy.backend.ApiCacheRow
import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.PlexClientEvents
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.time.Duration

internal const val TEST_SERVER_ID = "server-1"
internal const val TEST_BASE_URL = "https://plex.test:32400"
internal const val TEST_TOKEN = "token-1"
internal const val TEST_PROFILE = "profile-1"

internal val testProfileScope: PlexProfileScopeId get() = PlexProfileScopeId.of(ServerId(TEST_SERVER_ID), TEST_PROFILE)

/** An in-memory [ApiCacheStore]; [now] stamps writes (epoch ms); [beforeGet] runs before every [get] (to hold a read open). */
internal class MemoryApiCacheStore(var now: () -> Long = { 0L }) : ApiCacheStore {
    val rows = linkedMapOf<String, ApiCacheRow>()
    var beforeGet: (suspend () -> Unit)? = null

    private fun key(cacheServerId: String, endpoint: String) = "$cacheServerId:$endpoint"

    override suspend fun get(cacheServerId: String, endpoint: String): JsonObject? {
        beforeGet?.invoke()
        return rows[key(cacheServerId, endpoint)]?.let { Json.parseToJsonElement(it.data).jsonObject }
    }

    override suspend fun getIfFresh(cacheServerId: String, endpoint: String, maxAge: Duration): JsonObject? {
        val row = rows[key(cacheServerId, endpoint)] ?: return null
        if (now() - row.cachedAt > maxAge.inWholeMilliseconds) return null
        return Json.parseToJsonElement(row.data).jsonObject
    }

    override suspend fun put(cacheServerId: String, endpoint: String, data: JsonObject) {
        val k = key(cacheServerId, endpoint)
        rows[k] = ApiCacheRow(k, data.toString(), now(), rows[k]?.pinned ?: false)
    }

    override suspend fun deleteForServer(cacheServerId: String) {
        rows.keys.removeAll { it.startsWith("$cacheServerId:") }
    }

    override suspend fun delete(cacheServerId: String, endpoint: String) {
        rows.remove(key(cacheServerId, endpoint))
    }

    override suspend fun pin(cacheServerId: String, endpoint: String) {
        val k = key(cacheServerId, endpoint)
        rows[k]?.let { rows[k] = it.copy(pinned = true) }
    }

    override suspend fun isPinned(cacheServerId: String, endpoint: String): Boolean = rows[key(cacheServerId, endpoint)]?.pinned == true

    override suspend fun pinnedRows(cacheServerId: String?): List<ApiCacheRow> =
        rows.values.filter { it.pinned && (cacheServerId == null || it.cacheServerId == cacheServerId) }

    override suspend fun clearAll() = rows.clear()

    override suspend fun rowsMatching(keyPrefix: String, keySuffix: String): List<ApiCacheRow> =
        rows.values.filter { it.key.startsWith(keyPrefix) && it.key.endsWith(keySuffix) }.sortedBy { it.key }

    override suspend fun clearVolatile() {
        rows.values.removeAll { !it.pinned }
    }
}

/** A JSON answer. */
internal fun MockRequestHandleScope.jsonResponse(body: String, status: Int = 200, headers: Map<String, String> = emptyMap()): HttpResponseData =
    respond(
        body,
        HttpStatusCode.fromValue(status),
        headersOf(*(mapOf("Content-Type" to "application/json") + headers).map { (k, v) -> k to listOf(v) }.toTypedArray()),
    )

/**
 * A [PlexClient] for [TEST_SERVER_ID] at [baseUrl], scoped to [TEST_PROFILE], answering through [handler], its
 * background work in [scope]. Every request the engine saw is in the returned engine's `requestHistory`.
 */
internal fun testPlexClient(
    handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    store: ApiCacheStore = MemoryApiCacheStore(),
    environment: PlexClientEnvironment = PlexClientEnvironment(),
    baseUrl: String = TEST_BASE_URL,
    token: String? = TEST_TOKEN,
    prioritizedEndpoints: List<String> = emptyList(),
    profileScopeId: PlexProfileScopeId = testProfileScope,
    events: PlexClientEvents? = null,
    machineIdentifier: String? = null,
    languageCode: String? = null,
    scope: CoroutineScope = CoroutineScope(SupervisorJob()),
): PlexClient = PlexClient(
    config = PlexConfig(
        baseUrl = baseUrl, token = token, clientIdentifier = "client-1", version = "1.0", platform = "Linux",
        machineIdentifier = machineIdentifier, languageCode = languageCode,
    ),
    serverId = ServerId(TEST_SERVER_ID),
    profileScopeId = profileScopeId,
    serverName = "Test Server",
    // Unconfined: the handler runs on the caller's test dispatcher, so request timeouts never race virtual time.
    httpClient = HttpClient(
        MockEngine(MockEngineConfig().apply { dispatcher = Dispatchers.Unconfined; addHandler { request -> handler(request) } }),
    ) { install(HttpTimeout) },
    cache = PlexApiCache(store),
    environment = environment,
    prioritizedEndpoints = prioritizedEndpoints,
    events = events,
    appScope = scope,
)

/** [PlexClientEvents] that record what the client reported. */
internal class RecordingPlexClientEvents : PlexClientEvents {
    var exhausted = 0
    val endpointChanges = mutableListOf<String>()

    override fun onAllEndpointsExhausted() {
        exhausted++
    }

    override suspend fun onEndpointChanged(newUrl: String) {
        endpointChanges += newUrl
    }
}
