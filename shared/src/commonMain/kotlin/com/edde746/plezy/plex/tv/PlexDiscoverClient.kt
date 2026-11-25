package com.edde746.plezy.plex.tv

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.plex.PLEX_PRODUCT
import com.edde746.plezy.plex.firstObject
import com.edde746.plezy.plex.flexDouble
import com.edde746.plezy.plex.flexInt
import com.edde746.plezy.plex.objectList
import com.edde746.plezy.plex.scalarString
import io.ktor.client.HttpClient
import io.ktor.client.request.header
import io.ktor.client.request.request
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpMethod
import io.ktor.http.URLBuilder
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** Credentials for Plex's cloud Discover provider. The token is the active Plex or Home user's; never log it. */
data class PlexDiscoverSession(val accessToken: String, val clientIdentifier: String) {
    val isUsable: Boolean get() = accessToken.isNotEmpty() && clientIdentifier.isNotEmpty()

    override fun toString(): String = "PlexDiscoverSession(clientIdentifier=$clientIdentifier)"
}

/** One page of Discover metadata objects. [totalResults] is what Discover reported, when it did. */
data class PlexDiscoverPage(val items: List<JsonObject>, val hasMore: Boolean = false, val totalResults: Int? = null)

data class PlexDiscoverSearchResult(val metadata: JsonObject, val score: Double? = null)

data class PlexDiscoverHub(
    val id: String,
    val key: String,
    val title: String,
    val page: PlexDiscoverPage,
    val type: String? = null,
    val style: String? = null,
)

/** Discover answered [statusCode]; [message] is its `Error.message` (or `Error.error`), else "Request failed". */
class PlexDiscoverException(val statusCode: Int, message: String) : Exception(message) {
    override fun toString(): String = "PlexDiscoverException($statusCode): $message"
}

/**
 * Plex's cloud catalog and watchlist (`https://discover.provider.plex.tv`). Every request carries the session, the
 * product, version `2` and [language] (Discover localizes titles, summaries and shelf names from it; read per request
 * so a language switch applies on the next one), and fails after [requestTimeout] with a timeout
 * [MediaServerHttpException]. A transport failure is a [MediaServerHttpException], a non-2xx answer a
 * [PlexDiscoverException].
 */
class PlexDiscoverClient(
    val session: PlexDiscoverSession,
    private val http: HttpClient,
    private val language: () -> String,
    private val requestTimeout: Duration = 20.seconds,
) {
    /**
     * Page [page] (from 1) of [limit] (1–500) watchlist items, by offset. When Discover rejects the container size
     * (it has: 500 became "Invalid value provided for x-plex-container-size!"), the same range is fetched in chunks of
     * 25, the largest size proven to pass, so the caller's offset math survives.
     */
    suspend fun getWatchlist(page: Int = 1, limit: Int = 25): PlexDiscoverPage {
        val safeLimit = limit.coerceIn(1, 500)
        val offset = (page.coerceAtLeast(1) - 1) * safeLimit
        try {
            return watchlistRange(offset, safeLimit)
        } catch (e: PlexDiscoverException) {
            if (safeLimit <= WATCHLIST_CHUNK_SIZE || !isContainerSizeRejection(e)) throw e
            Log.w(TAG) { "Discover rejected container size $safeLimit, refetching in chunks of $WATCHLIST_CHUNK_SIZE" }
        }
        val items = mutableListOf<JsonObject>()
        var chunk: PlexDiscoverPage
        do {
            chunk = watchlistRange(offset + items.size, minOf(safeLimit - items.size, WATCHLIST_CHUNK_SIZE))
            items += chunk.items
        } while (items.size < safeLimit && chunk.hasMore && chunk.items.isNotEmpty())
        return PlexDiscoverPage(items, chunk.hasMore, chunk.totalResults)
    }

    private suspend fun watchlistRange(offset: Int, size: Int): PlexDiscoverPage {
        val container = request(
            HttpMethod.Get,
            "/library/sections/watchlist/all",
            mapOf("X-Plex-Container-Start" to offset, "X-Plex-Container-Size" to size, "includeGuids" to 1, "includeMeta" to 1),
        )!!.container()
        val items = container["Metadata"].objectList()
        val reportedTotal = container["totalSize"].flexInt()
        val total = reportedTotal ?: container["size"].flexInt() ?: items.size
        return PlexDiscoverPage(items, hasMore = offset + items.size < total, totalResults = reportedTotal)
    }

    /**
     * The shelves of Discover's Home ▸ Trending tab (`/hubs/sections/home`), each with up to [limit] (1–100) items.
     *
     * The listing holds placeholders only, so each shelf costs one [getHub] request, at most [concurrency] at a time.
     * Shelves that can never hold a catalog item (`directory`: browse categories, `clip`: trailers) are dropped before
     * that request, as are shelves without key or title, repeated ids and shelves that come back empty. One failing
     * shelf is dropped; when every shelf fails, the first failure is thrown.
     */
    suspend fun getHomeHubs(limit: Int = 25, concurrency: Int = 6, includeImageVariants: Boolean = false): List<PlexDiscoverHub> {
        val safeLimit = limit.coerceIn(1, 100)
        val container = request(HttpMethod.Get, "/hubs/sections/home", mapOf("includeMeta" to 1))!!.container()
        val seen = HashSet<String>()
        val candidates = container["Hub"].objectList().mapNotNull { hub ->
            val type = nonEmptyString(hub["type"])
            if (type in UNRENDERABLE_HUB_TYPES) return@mapNotNull null
            val key = nonEmptyString(hub["key"] ?: hub["hubKey"]) ?: return@mapNotNull null
            val id = nonEmptyString(hub["hubIdentifier"]) ?: key
            val title = nonEmptyString(hub["title"]) ?: return@mapNotNull null
            if (!seen.add(id)) return@mapNotNull null
            PlexDiscoverHub(id, key, title, PlexDiscoverPage(emptyList()), type, nonEmptyString(hub["style"]))
        }
        if (candidates.isEmpty()) return emptyList()

        val queue = Channel<Int>(Channel.UNLIMITED)
        candidates.indices.forEach { queue.trySend(it) }
        queue.close()
        val outcomes = coroutineScope {
            List(concurrency.coerceIn(1, candidates.size)) {
                async {
                    buildList {
                        for (index in queue) {
                            val candidate = candidates[index]
                            val outcome = try {
                                // One over the shelf size is what tells View All there is more.
                                Result.success(getHub(candidate.key, safeLimit + 1, includeImageVariants))
                            } catch (e: CancellationException) {
                                throw e
                            } catch (e: Exception) {
                                Log.w(TAG, e) { "Discover home hub ${candidate.id} failed" }
                                Result.failure(e)
                            }
                            add(index to outcome)
                        }
                    }
                }
            }.awaitAll().flatten().sortedBy { it.first }.map { it.second }
        }
        if (outcomes.all { it.isFailure }) throw outcomes.first().exceptionOrNull()!!

        return candidates.zip(outcomes).mapNotNull { (candidate, outcome) ->
            val page = outcome.getOrNull()?.takeIf { it.items.isNotEmpty() } ?: return@mapNotNull null
            val total = page.totalResults
            candidate.copy(
                page = PlexDiscoverPage(
                    items = page.items.take(safeLimit),
                    hasMore = page.items.size > safeLimit || (total != null && total > safeLimit),
                    totalResults = total,
                ),
            )
        }
    }

    /**
     * One hub in full, up to [limit] (1–500) items. Discover ignores container offsets on hub keys and truncates with
     * `limit`, so a hub is one page and never has more. Image variants roughly double a hub's size and are left out
     * unless [includeImageVariants].
     */
    suspend fun getHub(key: String, limit: Int = 100, includeImageVariants: Boolean = false): PlexDiscoverPage {
        val safeLimit = limit.coerceIn(1, 500)
        val container = request(
            HttpMethod.Get,
            key,
            mapOf(
                "limit" to safeLimit,
                "includeGuids" to 1,
                "includeMeta" to 1,
                "includeUserState" to 1,
                "excludeElements" to if (includeImageVariants) "Media" else "Media,Image",
            ),
        )!!.container()
        val containerItems = container["Metadata"].objectList()
        val items = containerItems.ifEmpty { container["Hub"].firstObject()?.get("Metadata").objectList() }
        return PlexDiscoverPage(items.take(safeLimit), totalResults = container["totalSize"].flexInt())
    }

    /** Movies and shows matching [query], up to [limit] (1–100), with Discover's score. People are filtered out. */
    suspend fun search(query: String, limit: Int = 30): List<PlexDiscoverSearchResult> {
        val container = request(
            HttpMethod.Get,
            "/library/search",
            mapOf(
                "query" to query,
                "limit" to limit.coerceIn(1, 100),
                "searchTypes" to "movies,tv",
                "searchProviders" to "discover",
                "includeGuids" to 1,
                "includeMetadata" to 1,
                "filterPeople" to 1,
            ),
        )!!.container()
        return container["SearchResults"].objectList().flatMap { group ->
            group["SearchResult"].objectList().mapNotNull { result ->
                result["Metadata"].firstObject()?.let { PlexDiscoverSearchResult(it, result["score"].flexDouble()) }
            }
        }
    }

    /**
     * Discover's metadata for a movie or show known by [ids] (imdb, else tmdb, else tvdb), or null; other kinds and
     * items without those ids never reach the network. Discover answers a guid lookup only with the numeric type
     * (1 movie, 2 show); a bare guid gets an empty container for every item.
     */
    suspend fun match(ids: ExternalIds, kind: MediaKind): JsonObject? {
        val type = when (kind) {
            MediaKind.MOVIE -> 1
            MediaKind.SHOW -> 2
            else -> return null
        }
        val guid = ids.imdb?.let { "imdb://$it" } ?: ids.tmdb?.let { "tmdb://$it" } ?: ids.tvdb?.let { "tvdb://$it" }
            ?: return null
        val data = request(
            HttpMethod.Get,
            "/library/metadata/matches",
            mapOf("type" to type, "guid" to guid, "includeGuids" to 1),
            allowNotFound = true,
        ) ?: return null
        return data.container()["Metadata"].firstObject()
    }

    /** The item's metadata, or null when Discover doesn't know it. */
    suspend fun getMetadata(ratingKey: String): JsonObject? {
        val data = request(
            HttpMethod.Get,
            "/library/metadata/${UriComponent.encode(ratingKey)}",
            mapOf("includeGuids" to 1),
            allowNotFound = true,
        ) ?: return null
        return data.container()["Metadata"].firstObject()
    }

    /** Items related to the item, every related hub flattened; empty when Discover doesn't know it. */
    suspend fun getRelated(ratingKey: String): List<JsonObject> {
        val data = request(HttpMethod.Get, "/library/metadata/${UriComponent.encode(ratingKey)}/related", allowNotFound = true)
            ?: return emptyList()
        val container = data.container()
        val hubs = container["Hub"] ?: return container["Metadata"].objectList()
        return hubs.objectList().flatMap { it["Metadata"].objectList() }
    }

    suspend fun setWatchlisted(ratingKey: String, add: Boolean) {
        request(
            HttpMethod.Put,
            if (add) "/actions/addToWatchlist" else "/actions/removeFromWatchlist",
            mapOf("ratingKey" to ratingKey),
        )
    }

    /**
     * The JSON object Discover answered at [path] (relative, with its own query, which [query] extends): empty for an
     * empty or non-object body, null for a 404 when [allowNotFound].
     */
    private suspend fun request(
        method: HttpMethod,
        path: String,
        query: Map<String, Any> = emptyMap(),
        allowNotFound: Boolean = false,
    ): JsonObject? {
        require(path.startsWith("/") && !path.startsWith("//")) { "Plex Discover paths must stay on the provider host" }
        val url = URLBuilder(BASE_URL + path).apply {
            for ((name, value) in query) parameters[name] = value.toString()
        }.build()
        val started = TimeSource.Monotonic.markNow()
        val (status, body) = try {
            withTimeout(requestTimeout) {
                val response = http.request(url) {
                    this.method = method
                    header("Accept", "application/json")
                    header("X-Plex-Token", session.accessToken)
                    header("X-Plex-Client-Identifier", session.clientIdentifier)
                    header("X-Plex-Product", PLEX_PRODUCT)
                    header("X-Plex-Version", "2")
                    header("X-Plex-Language", language())
                }
                response.status.value to response.bodyAsText()
            }
        } catch (e: TimeoutCancellationException) {
            throw MediaServerHttpException.from(e, url)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            throw MediaServerHttpException.from(e, url)
        }
        Log.d(TAG) { "Discover ${method.value} ${url.encodedPath} → $status (${started.elapsedNow().inWholeMilliseconds}ms)" }
        if (allowNotFound && status == 404) return null
        if (status !in 200..299) throw PlexDiscoverException(status, errorMessage(body))
        if (body.isEmpty()) return JsonObject(emptyMap())
        return Json.parseToJsonElement(body) as? JsonObject ?: JsonObject(emptyMap())
    }

    private companion object {
        const val TAG = "PlexDiscover"
        const val BASE_URL = "https://discover.provider.plex.tv"
        const val WATCHLIST_CHUNK_SIZE = 25
        val UNRENDERABLE_HUB_TYPES = setOf("directory", "clip")

        fun isContainerSizeRejection(e: PlexDiscoverException): Boolean =
            e.statusCode == 400 && e.message.orEmpty().lowercase().contains("container-size")

        fun JsonObject.container(): JsonObject = this["MediaContainer"].firstObject() ?: JsonObject(emptyMap())

        fun nonEmptyString(value: JsonElement?): String? =
            value.scalarString()?.trim()?.ifEmpty { null }

        fun errorMessage(body: String): String {
            val error = runCatching { Json.parseToJsonElement(body) }.getOrNull()
                .let { it as? JsonObject }?.get("Error").firstObject()
            return error?.get("message").scalarString() ?: error?.get("error").scalarString() ?: "Request failed"
        }
    }
}
