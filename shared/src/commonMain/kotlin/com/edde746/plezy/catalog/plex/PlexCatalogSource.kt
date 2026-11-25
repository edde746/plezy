package com.edde746.plezy.catalog.plex

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogCredit
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogHub
import com.edde746.plezy.catalog.CatalogHubSource
import com.edde746.plezy.catalog.CatalogHubStyle
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogNextEpisode
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogWatchlistMachinery
import com.edde746.plezy.catalog.WatchlistKeyPage
import com.edde746.plezy.catalog.catalogEnumOf
import com.edde746.plezy.catalog.parseCatalogInstant
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.CountryCodes
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.plex.flexBoolOrNull
import com.edde746.plezy.plex.flexInt
import com.edde746.plezy.plex.flexLong
import com.edde746.plezy.plex.normalizedPlexRating
import com.edde746.plezy.plex.objectList
import com.edde746.plezy.plex.plexRatingSources
import com.edde746.plezy.plex.stringOrNull
import com.edde746.plezy.plex.trimmedText
import com.edde746.plezy.plex.tv.PlexDiscoverClient
import kotlin.concurrent.Volatile
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Instant
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject

/**
 * The active Plex profile's universal watchlist and Discover's Home shelves (what Plex's own web client shows on its
 * Home ▸ Trending tab).
 *
 * Unlike the tracker-backed sources, this source owns [client]: it is built per Discover session and dropped with the
 * source. [includeImageVariants] asks hub requests for `Image` elements (logos, banners) for surfaces that render them.
 */
class PlexCatalogSource(
    private val client: PlexDiscoverClient,
    private val includeImageVariants: Boolean = false,
) : CatalogWatchlistMachinery(), CatalogHubSource {
    /** Hub id → Discover key, from the last [fetchHubs]. */
    @Volatile
    private var hubKeys: Map<String, String> = emptyMap()

    override val id: CatalogSourceId get() = CatalogSourceId.PLEX

    override val supportedRows: List<CatalogRowId> = listOf(CatalogRowId.WATCHLIST)

    override val watchlistLogLabel: String get() = "Plex: watchlist"

    // Discover validates X-Plex-Container-Size against a cap it changes without notice (500 once became invalid). 100
    // keeps the snapshot at few requests well under the observed cap, the client degrades to 25-item chunks if the cap
    // ever drops below it, and 50 pages keep 5000-entry coverage.
    override val watchlistPageLimit: Int get() = 100

    override val watchlistMaxPages: Int get() = 50

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage {
        require(row == CatalogRowId.WATCHLIST) { "Plex does not serve ${row.id}" }
        val response = client.getWatchlist(page, limit)
        return CatalogPage(fromMetadata(response.items), response.hasMore, response.totalResults)
    }

    override suspend fun fetchHubs(limit: Int): List<CatalogHub> {
        val fetched = client.getHomeHubs(limit = limit, includeImageVariants = includeImageVariants)
        val keys = HashMap<String, String>()
        val result = ArrayList<CatalogHub>()
        for (hub in fetched) {
            val items = fromMetadata(hub.page.items)
            if (items.isEmpty()) continue
            keys[hub.id] = hub.key
            result += CatalogHub(
                id = hub.id,
                title = hub.title,
                page = CatalogPage(items, hub.page.hasMore, hub.page.totalResults),
                style = catalogEnumOf<CatalogHubStyle>(hub.style),
            )
        }
        hubKeys = keys
        return result
    }

    /** Discover serves a hub in one shot (it ignores container offsets), so View All has no second page. */
    override suspend fun fetchHub(id: String, page: Int, limit: Int): CatalogPage {
        val key = hubKeys[id]
        if (key == null || page > 1) return CatalogPage(emptyList())
        val response = client.getHub(key, limit = limit, includeImageVariants = includeImageVariants)
        return CatalogPage(fromMetadata(response.items), hasMore = false, totalResults = response.totalResults)
    }

    override suspend fun search(query: String, limit: Int): List<CatalogItem> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        return fromMetadata(client.search(trimmed, limit).map { it.metadata })
    }

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? {
        // Discover matches on imdb/tmdb/tvdb only; an AniDB-only item has nothing to send.
        if (!external.hasCatalogIds) return null
        val metadata = client.match(external, kind) ?: return null
        if (kindFor(metadata) != kind) return null
        val ids = idsFor(metadata)
        if (ids.plex == null) return null
        return CatalogItemIds(
            plex = ids.plex,
            imdb = ids.imdb ?: external.imdb,
            tmdb = ids.tmdb ?: external.tmdb,
            tvdb = ids.tvdb ?: external.tvdb,
        )
    }

    override suspend fun resolveWatchlistMutationIds(kind: MediaKind, ids: CatalogItemIds): CatalogItemIds {
        if (!ids.plex.isNullOrEmpty()) return ids
        val resolved = resolveItemIds(kind, ids.toExternalIds())
        check(resolved != null && !resolved.plex.isNullOrEmpty()) { "Plex: no rating key for ${ids.canonicalKey ?: "item"}" }
        return resolved
    }

    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail {
        val ratingKey = item.ids.plex
        if (ratingKey.isNullOrEmpty()) return CatalogDetail(item)

        val (metadata, relatedMetadata) = coroutineScope {
            val metadata = async { loadDetailMetadata(ratingKey) }
            val related = async { loadRelatedMetadata(ratingKey) }
            metadata.await() to related.await()
        }
        val detailItem = metadata?.let(::toCatalogItem)
        val cast = metadata?.get("Role").objectList().take(castLimit.coerceAtLeast(0)).mapNotNull { role ->
            val name = role.either("tag", "name").trimmedText() ?: return@mapNotNull null
            CatalogCastMember(name, secondary = role["role"].trimmedText(), imageUrl = role["thumb"].trimmedText())
        }
        return CatalogDetail(
            item = if (detailItem == null) item else item.enrichedWith(detailItem),
            cast = cast,
            related = fromMetadata(relatedMetadata).take(relatedLimit.coerceAtLeast(0)),
        )
    }

    private suspend fun loadDetailMetadata(ratingKey: String): JsonObject? = try {
        client.getMetadata(ratingKey)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Plex: detail metadata failed" }
        null
    }

    private suspend fun loadRelatedMetadata(ratingKey: String): List<JsonObject> = try {
        client.getRelated(ratingKey)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Plex: related metadata failed" }
        emptyList()
    }

    /** One group per watchlist identity: a later entry with the same identity is dropped, never unioned in. */
    override suspend fun fetchWatchlistKeyPage(page: Int, limit: Int): WatchlistKeyPage {
        val response = client.getWatchlist(page, limit)
        val groups = ArrayList<List<String>>()
        val seen = HashSet<String>()
        for (metadata in response.items) {
            val kind = kindFor(metadata) ?: continue
            if (metadata["title"].trimmedText() == null) continue
            val ids = idsFor(metadata)
            if (ids.plex == null) continue
            if (seen.add(ids.identityKeyFor(kind))) groups += membershipKeysFor(kind, ids)
        }
        return WatchlistKeyPage(groups, response.hasMore)
    }

    override suspend fun performWatchlistMutation(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        val ratingKey = ids.plex
        require(!ratingKey.isNullOrEmpty()) { "Plex watchlist mutations require a Plex rating key" }
        client.setWatchlisted(ratingKey, add)
    }

    override fun dispose() {
        disposeWatchlistMachinery()
    }

    /** Mapped items, the first per identity. */
    private fun fromMetadata(metadata: List<JsonObject>): List<CatalogItem> {
        val seen = HashSet<String>()
        return metadata.mapNotNull { value -> toCatalogItem(value)?.takeIf { seen.add(it.identityKey) } }
    }

    private fun toCatalogItem(metadata: JsonObject): CatalogItem? {
        val kind = kindFor(metadata) ?: return null
        val title = metadata["title"].trimmedText() ?: return null
        val ids = idsFor(metadata)
        if (ids.plex == null) return null

        val isShow = kind == MediaKind.SHOW
        val continuing = metadata["isContinuingSeries"].flexBoolOrNull()
        val durationMs = metadata["duration"].flexLong()
        val nextAirDate = if (isShow) {
            dateOf(metadata["nextEpisodeOriginallyAvailableAt"]) ?: dateOf(metadata["nextSeasonOriginallyAvailableAt"])
        } else {
            null
        }

        var coverPoster: String? = null
        var coverArt: String? = null
        var background: String? = null
        var clearLogo: String? = null
        var clearLogoWide: String? = null
        var imageBanner: String? = null
        for (image in metadata["Image"].objectList()) {
            val type = image["type"].trimmedText() ?: continue
            val url = image["url"].trimmedText() ?: continue
            when (type) {
                "coverPoster" -> coverPoster = coverPoster ?: url
                "coverArt" -> coverArt = coverArt ?: url
                "background" -> background = background ?: url
                "clearLogo" -> clearLogo = clearLogo ?: url
                "clearLogoWide" -> clearLogoWide = clearLogoWide ?: url
                "banner" -> imageBanner = imageBanner ?: url
            }
        }

        return CatalogItem(
            source = CatalogSourceId.PLEX,
            kind = kind,
            title = title,
            ids = ids,
            year = metadata["year"].flexInt(),
            overview = overviewFor(metadata),
            runtimeMinutes = durationMs?.let { (it / 60_000).toInt() },
            rating = normalizedPlexRating(metadata["rating"]) ?: normalizedPlexRating(metadata["audienceRating"]),
            genres = tagsFor(metadata["Genre"]),
            certification = metadata["contentRating"].trimmedText(),
            airStatus = if (isShow && continuing != null) {
                if (continuing) CatalogAirStatus.AIRING else CatalogAirStatus.ENDED
            } else {
                null
            },
            episodeCount = if (isShow) metadata["leafCount"].flexInt() else null,
            network = metadata.either("studio", "network").trimmedText(),
            posterUrl = metadata["thumb"].trimmedText() ?: coverPoster ?: coverArt,
            backdropUrl = metadata["art"].trimmedText() ?: background,
            logoUrl = clearLogoWide ?: clearLogo,
            bannerUrl = metadata["banner"].trimmedText() ?: imageBanner,
            ratings = plexRatingSources(metadata),
            nextEpisode = nextAirDate?.let { CatalogNextEpisode(airsAt = it) },
            releaseDate = dateOf(metadata["originallyAvailableAt"]),
            endDate = if (isShow && continuing == false) {
                dateOf(metadata["lastEpisodeOriginallyAvailableAt"]) ?: dateOf(metadata["lastSeasonOriginallyAvailableAt"])
            } else {
                null
            },
            originalTitle = metadata["originalTitle"].trimmedText(),
            tagline = metadata["tagline"].trimmedText(),
            studios = tagsFor(metadata["Studio"]),
            countries = countriesFor(metadata["Country"]),
            credits = creditsFor(metadata),
            contentAdvisory = contentAdvisoryFor(metadata),
            budget = metadata["budget"].flexLong(),
            revenue = metadata["revenue"].flexLong(),
        )
    }

    private companion object {
        const val TAG = "PlexCatalog"

        fun kindFor(metadata: JsonObject): MediaKind? = when (metadata["type"].stringOrNull()) {
            "movie" -> MediaKind.MOVIE
            "show" -> MediaKind.SHOW
            else -> null
        }

        /** The rating key plus imdb/tmdb/tvdb from `guid` and `Guid[].id` (`<provider>://<id>`), first value winning. */
        fun idsFor(metadata: JsonObject): CatalogItemIds {
            var imdb: String? = null
            var tmdb: Int? = null
            var tvdb: Int? = null
            fun consume(value: JsonElement?) {
                val guid = value.trimmedText() ?: return
                val separator = guid.indexOf("://")
                if (separator <= 0) return
                val id = guid.substring(separator + 3)
                when (guid.substring(0, separator).lowercase()) {
                    "imdb" -> imdb = imdb ?: id
                    "tmdb" -> tmdb = tmdb ?: id.toIntOrNull()
                    "tvdb" -> tvdb = tvdb ?: id.toIntOrNull()
                }
            }
            consume(metadata["guid"])
            for (guid in metadata["Guid"].objectList()) consume(guid["id"])
            return CatalogItemIds(plex = metadata["ratingKey"].trimmedText(), imdb = imdb, tmdb = tmdb, tvdb = tvdb)
        }

        fun tagsFor(value: JsonElement?): List<String>? =
            value.objectList().mapNotNull { it.either("tag", "name").trimmedText() }.distinct().ifEmpty { null }

        /** ISO alpha-2 codes; Discover sends country names. */
        fun countriesFor(value: JsonElement?): List<String>? = value.objectList()
            .mapNotNull { entry -> entry.either("tag", "name").trimmedText()?.let(CountryCodes::normalizeCode)?.ifEmpty { null } }
            .distinct()
            .ifEmpty { null }

        fun creditsFor(metadata: JsonObject): List<CatalogCredit>? {
            val credits = ArrayList<CatalogCredit>()
            fun add(value: JsonElement?, role: CatalogCreditRole) {
                for (entry in value.objectList()) {
                    val name = (entry.present("tag") ?: entry.present("name") ?: entry["role"]).trimmedText() ?: continue
                    val credit = CatalogCredit(name, role)
                    if (credit !in credits) credits += credit
                }
            }
            add(metadata["Director"], CatalogCreditRole.DIRECTOR)
            add(metadata["Writer"], CatalogCreditRole.WRITER)
            add(metadata["Producer"], CatalogCreditRole.PRODUCER)
            return credits.ifEmpty { null }
        }

        /** `summary`, or the longest `Summary[]` entry when one is longer. */
        fun overviewFor(metadata: JsonObject): String? {
            var overview = metadata["summary"].trimmedText()
            for (summary in metadata["Summary"].objectList()) {
                val candidate = summary.either("tag", "summary").trimmedText() ?: continue
                if (overview == null || candidate.length > overview.length) overview = candidate
            }
            return overview
        }

        /** Common Sense Media entries as `<age>+ · <one-liner>`, one per line. */
        fun contentAdvisoryFor(metadata: JsonObject): String? = metadata["CommonSenseMedia"].objectList()
            .mapNotNull { commonSense ->
                val age = commonSense["AgeRating"].objectList().firstNotNullOfOrNull { it["age"].flexInt() }
                listOfNotNull(age?.let { "$it+" }, commonSense["oneLiner"].trimmedText()).joinToString(" · ").ifEmpty { null }
            }
            .distinct()
            .ifEmpty { null }
            ?.joinToString("\n")

        fun dateOf(value: JsonElement?): Instant? = parseCatalogInstant(value.stringOrNull())

        /** [first] unless it is absent or JSON null, else [second]: Discover sends either field name. */
        fun JsonObject.either(first: String, second: String): JsonElement? = present(first) ?: this[second]

        fun JsonObject.present(key: String): JsonElement? = this[key]?.takeUnless { it is JsonNull }
    }
}
