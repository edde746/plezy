package com.edde746.plezy.catalog.simkl

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogAudience
import com.edde746.plezy.catalog.CatalogAudiencePeriod
import com.edde746.plezy.catalog.CatalogBroadcast
import com.edde746.plezy.catalog.CatalogCredit
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogFormat
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogLink
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRank
import com.edde746.plezy.catalog.CatalogRankScope
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSeasonInfo
import com.edde746.plezy.catalog.CatalogSeasonName
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogWatchlistMachinery
import com.edde746.plezy.catalog.WatchlistKeyPage
import com.edde746.plezy.catalog.parseCatalogInstant
import com.edde746.plezy.catalog.youTubeTrailerUrl
import com.edde746.plezy.model.CountryCodes
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.simkl.SimklApi
import io.ktor.http.encodeURLParameter
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Instant
import kotlin.time.TimeMark
import kotlin.time.TimeSource
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonObjectBuilder
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * [com.edde746.plezy.catalog.CatalogSource] backed by Simkl's REST API and its public discovery CDN.
 *
 * Every row is one unpaginated download, kept in memory for [ROW_CACHE_TTL] and sliced into pages here; the TTL is
 * checked on page 1 only, so paging through a row never swaps the list under the reader. The watchlist row and the
 * membership snapshot share one Plan to Watch download. Simkl takes the media server's external ids directly, so
 * library items resolve without an anime mapping.
 *
 * Simkl asks for visible attribution wherever the CDN trending data is shown; the source switcher's name and logo
 * supply it.
 */
class SimklCatalogSource internal constructor(
    private val api: SimklApi,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) : CatalogWatchlistMachinery() {

    private class CachedRow(val items: List<CatalogItem>, val loadedAt: TimeMark)

    private val lock = Mutex()
    private val rowCache = HashMap<CatalogRowId, CachedRow>()
    private val rowLoads = HashMap<CatalogRowId, CompletableDeferred<List<CatalogItem>>>()
    private val animeIds = HashSet<Int>()
    private var allItemsCache: SimklAllItems? = null
    private var allItemsLoad: CompletableDeferred<SimklAllItems>? = null
    private var allItemsGeneration = 0L

    override val id: CatalogSourceId get() = CatalogSourceId.SIMKL

    override val supportedRows: List<CatalogRowId> = listOf(
        CatalogRowId.WATCHLIST,
        CatalogRowId.TRENDING_MOVIES,
        CatalogRowId.TRENDING_SHOWS,
        CatalogRowId.TRENDING_ANIME,
        CatalogRowId.POPULAR_SHOWS,
        CatalogRowId.POPULAR_ANIME,
    )

    override val watchlistLogLabel: String get() = "Simkl: Plan to Watch"

    /** Simkl's Plan to Watch snapshot is one unpaginated response. */
    override val watchlistPageLimit: Int get() = 1

    override val watchlistMaxPages: Int get() = 1

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage {
        require(row in supportedRows) { "Simkl does not serve ${row.id}" }
        val normalizedPage = page.coerceAtLeast(1)
        val normalizedLimit = limit.coerceAtLeast(1)
        val items = rowItems(row, checkTtl = normalizedPage == 1)
        val start = (normalizedPage - 1).toLong() * normalizedLimit
        if (start >= items.size) return CatalogPage(emptyList())
        val end = minOf(start + normalizedLimit, items.size.toLong()).toInt()
        return CatalogPage(items.subList(start.toInt(), end), hasMore = end < items.size)
    }

    /** The cached row, loaded (once for concurrent callers) when missing or, with [checkTtl], expired. */
    private suspend fun rowItems(row: CatalogRowId, checkTtl: Boolean): List<CatalogItem> {
        var owner = false
        var generation = 0L
        val load = lock.withLock {
            val cached = rowCache[row]
            val expired = cached != null && checkTtl && cached.loadedAt.elapsedNow() >= ROW_CACHE_TTL
            if (cached != null && !expired) return cached.items
            if (row == CatalogRowId.WATCHLIST && expired) invalidateWatchlistCache()
            generation = allItemsGeneration
            rowLoads[row] ?: CompletableDeferred<List<CatalogItem>>().also {
                rowLoads[row] = it
                owner = true
            }
        }
        if (!owner) return load.await()
        try {
            val items = fetchUnpaginatedRow(row)
            lock.withLock {
                // A watchlist download that a mutation outdated serves its callers but is not kept.
                if (row != CatalogRowId.WATCHLIST || generation == allItemsGeneration) rowCache[row] = CachedRow(items, timeSource.markNow())
                if (rowLoads[row] === load) rowLoads.remove(row)
            }
            load.complete(items)
            return items
        } catch (e: Throwable) {
            lock.withLock { if (rowLoads[row] === load) rowLoads.remove(row) }
            load.completeExceptionally(e)
            throw e
        }
    }

    private suspend fun fetchUnpaginatedRow(row: CatalogRowId): List<CatalogItem> = when (row) {
        CatalogRowId.WATCHLIST -> fetchWatchlistRow()
        CatalogRowId.TRENDING_MOVIES -> fetchTrending(SimklCatalogType.MOVIES)
        CatalogRowId.TRENDING_SHOWS -> fetchTrending(SimklCatalogType.TV)
        CatalogRowId.TRENDING_ANIME -> fetchTrending(SimklCatalogType.ANIME)
        CatalogRowId.POPULAR_SHOWS -> fetchBest(SimklCatalogType.TV)
        CatalogRowId.POPULAR_ANIME -> fetchBest(SimklCatalogType.ANIME)
        else -> throw IllegalArgumentException("Simkl does not serve ${row.id}")
    }

    /**
     * The week's top 100 from the public CDN, sent without the account's token: its 401 says nothing about the session
     * and must not sign the account out.
     */
    private suspend fun fetchTrending(type: SimklCatalogType): List<CatalogItem> {
        val response = api.data("/discover/trending/${type.path}/week_100.json")
        val items = response.json().objects.map(SimklTrendingItem::parse).filter { it.ids.hasAny }
        remember(type, items.map { it.ids })
        return items.map { trendingItem(it, type) }
    }

    /** `/{type}/best/watched`: the most watched titles, counted over the past month. */
    private suspend fun fetchBest(type: SimklCatalogType): List<CatalogItem> {
        val items = api.get("/${type.path}/best/watched").json().objects.map(SimklBestItem::parse).filter { it.ids.hasAny }
        remember(type, items.map { it.ids })
        return items.map { bestItem(it, type) }
    }

    private suspend fun fetchWatchlistRow(): List<CatalogItem> {
        val response = watchlistItems()
        val groups = listOf(
            SimklCatalogType.MOVIES to response.movies,
            SimklCatalogType.TV to response.shows,
            SimklCatalogType.ANIME to response.anime,
        )
        val result = ArrayList<CatalogItem>()
        for ((type, entries) in groups) {
            val kept = entries.filter { it.media?.ids?.hasAny == true }
            remember(type, kept.map { it.media!!.ids })
            kept.mapTo(result) { allItemsItem(it, type) }
        }
        return result
    }

    /** Plan to Watch, downloaded once for the watchlist row and the membership snapshot alike. */
    private suspend fun watchlistItems(): SimklAllItems {
        var owner = false
        var generation = 0L
        val load = lock.withLock {
            allItemsCache?.let { return it }
            generation = allItemsGeneration
            allItemsLoad ?: CompletableDeferred<SimklAllItems>().also {
                allItemsLoad = it
                owner = true
            }
        }
        if (!owner) return load.await()
        try {
            val items = SimklAllItems.parse(api.get("/sync/all-items/all/plantowatch", "extended=full").json())
            lock.withLock {
                if (generation == allItemsGeneration) allItemsCache = items
                if (allItemsLoad === load) allItemsLoad = null
            }
            load.complete(items)
            return items
        } catch (e: Throwable) {
            lock.withLock { if (allItemsLoad === load) allItemsLoad = null }
            load.completeExceptionally(e)
            throw e
        }
    }

    override suspend fun search(query: String, limit: Int): List<CatalogItem> {
        val trimmed = query.trim()
        if (trimmed.isEmpty() || limit <= 0) return emptyList()
        val perType = ((limit + 2) / 3).coerceIn(1, 50)
        val types = listOf(SimklCatalogType.MOVIES, SimklCatalogType.TV, SimklCatalogType.ANIME)
        val pages = coroutineScope {
            types.map { type ->
                async {
                    api.get("/search/${type.searchPath}", "q=${trimmed.encodeURLParameter()}&page=1&limit=$perType&extended=full")
                        .json().objects.map(SimklSearchResult::parse).filter { it.ids.hasAny }
                }
            }.awaitAll()
        }
        val result = ArrayList<CatalogItem>()
        for ((type, page) in types.zip(pages)) {
            remember(type, page.map { it.ids })
            page.mapTo(result) { searchItem(it, type) }
        }
        return result.take(limit)
    }

    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail {
        val simklId = item.ids.simkl ?: return CatalogDetail(item)
        val type = detailTypeFor(item, simklId)
        val body = api.record("/${type.detailPath}/$simklId").json() as? JsonObject ?: return CatalogDetail(item)
        val detail = SimklDetail.parse(body)
        val recommendations = if (relatedLimit > 0) detail.recommendations.take(relatedLimit).filter { it.ids.hasAny } else emptyList()
        val related = recommendations.map { recommendation ->
            val recommendationType = recommendationType(recommendation)
            remember(recommendationType, listOf(recommendation.ids))
            recommendationItem(recommendation, recommendationType)
        }
        return CatalogDetail(item = item.enrichedWith(detailItem(detail, type)), related = related)
    }

    private suspend fun detailTypeFor(item: CatalogItem, simklId: Int): SimklCatalogType {
        val knownAnime = lock.withLock { simklId in animeIds }
        return when {
            item.format != null || knownAnime || item.ids.mal != null || item.ids.anilist != null -> SimklCatalogType.ANIME
            item.kind == MediaKind.MOVIE -> SimklCatalogType.MOVIES
            else -> SimklCatalogType.TV
        }
    }

    /** Anime ids seen in any response, so a detail request picks the anime endpoint. */
    private suspend fun remember(type: SimklCatalogType, ids: List<SimklIds>) {
        if (type != SimklCatalogType.ANIME) return
        lock.withLock { ids.mapNotNullTo(animeIds) { it.simkl } }
    }

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? =
        if (external.hasCatalogIds) CatalogItemIds.fromExternal(external) else null

    override suspend fun fetchWatchlistKeyPage(page: Int, limit: Int): WatchlistKeyPage =
        WatchlistKeyPage(watchlistKeyGroups(watchlistItems()), hasMore = false)

    /** One group per entry; an anime entry answers to both kinds, since Simkl's anime catalog holds films and series. */
    private fun watchlistKeyGroups(response: SimklAllItems): List<List<String>> = buildList {
        for (entry in response.movies) entry.media?.let { add(membershipKeysFor(MediaKind.MOVIE, it.ids.toCatalogItemIds())) }
        for (entry in response.shows) entry.media?.let { add(membershipKeysFor(MediaKind.SHOW, it.ids.toCatalogItemIds())) }
        for (entry in response.anime) {
            entry.media?.let {
                val ids = it.ids.toCatalogItemIds()
                add(membershipKeysFor(MediaKind.MOVIE, ids) + membershipKeysFor(MediaKind.SHOW, ids))
            }
        }
    }

    override suspend fun performWatchlistMutation(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        val bucket = if (kind == MediaKind.SHOW) "shows" else "movies"
        val mutationIds = SimklIds.from(ids).toJson()
        if (add) {
            api.post("/sync/add-to-list", mutationBody(bucket) { put("to", "plantowatch"); put("ids", mutationIds) })
        } else {
            // Simkl has no remove-from-list call: a bare-ids history removal drops the title from the library, watch
            // history included, which for a Plan to Watch entry is the documented removal. A title that has moved on
            // to watching or completed since the snapshot loaded is already off the list and would lose its history,
            // so re-read Plan to Watch first.
            lock.withLock { invalidateWatchlistCache() }
            val keys = membershipKeysFor(kind, ids).toSet()
            if (watchlistKeyGroups(watchlistItems()).none { group -> group.any(keys::contains) }) {
                reloadWatchlistSnapshot()
                return
            }
            api.post("/sync/history/remove", mutationBody(bucket) { put("ids", mutationIds) })
        }
        lock.withLock { invalidateWatchlistCache() }
    }

    private fun mutationBody(bucket: String, entry: JsonObjectBuilder.() -> Unit): JsonObject =
        buildJsonObject { put(bucket, buildJsonArray { add(buildJsonObject(entry)) }) }

    /** Drops the Plan to Watch download and the watchlist row; an in-flight download no longer fills the cache. Hold [lock]. */
    private fun invalidateWatchlistCache() {
        allItemsGeneration++
        allItemsCache = null
        allItemsLoad = null
        rowCache.remove(CatalogRowId.WATCHLIST)
        rowLoads.remove(CatalogRowId.WATCHLIST)
    }

    override fun dispose() {
        invalidateWatchlistCache()
        rowCache.clear()
        rowLoads.clear()
        animeIds.clear()
        disposeWatchlistMachinery()
    }

    private fun trendingItem(item: SimklTrendingItem, type: SimklCatalogType): CatalogItem {
        val kind = kindFor(type, item.animeType)
        val rating = item.ratings?.primary
        val title = item.title.orEmpty()
        val originalTitle = originalTitle(title, item.titleRomaji)
        return CatalogItem(
            source = CatalogSourceId.SIMKL,
            kind = kind,
            title = title,
            year = item.year,
            overview = item.overview,
            runtimeMinutes = item.runtimeMinutes,
            rating = rating?.rating,
            votes = rating?.votes,
            genres = item.genres,
            trailerUrl = item.trailerUrl,
            airStatus = airStatusFor(item.status, kind),
            episodeCount = episodes(kind, item.totalEpisodes),
            network = item.network,
            ids = item.ids.toCatalogItemIds(),
            posterUrl = simklPosterUrl(item.poster),
            backdropUrl = simklFanartUrl(item.fanart),
            posterVariants = simklPosterVariants(item.poster),
            backdropVariants = simklFanartVariants(item.fanart),
            ratings = ratingsFor(item.ratings),
            ranks = rankFor(item.rank, CatalogRankScope.TRENDING, allTime = false),
            audience = audienceFor(item.watched, CatalogAudiencePeriod.WEEK, item.planToWatch, item.dropRate),
            releaseDate = date(item.theater ?: item.releaseDate),
            physicalReleaseDate = date(item.dvdDate),
            originalTitle = originalTitle,
            altTitles = alternateTitles(title, item.alternateTitles, originalTitle),
            format = formatFor(type, item.animeType),
            countries = countryFor(item.country),
            languages = languageFor(item.originalLanguage),
            links = linksFor(item.url),
        )
    }

    private fun searchItem(item: SimklSearchResult, type: SimklCatalogType): CatalogItem {
        val kind = kindFor(type, item.type)
        val rating = item.ratings?.primary
        val title = item.title.orEmpty()
        val originalTitle = originalTitle(title, item.titleRomaji)
        return CatalogItem(
            source = CatalogSourceId.SIMKL,
            kind = kind,
            title = title,
            year = item.year,
            rating = rating?.rating,
            votes = rating?.votes,
            airStatus = airStatusFor(item.status, kind),
            episodeCount = episodes(kind, item.episodeCount),
            ids = item.ids.toCatalogItemIds(),
            posterUrl = simklPosterUrl(item.poster),
            posterVariants = simklPosterVariants(item.poster),
            ratings = ratingsFor(item.ratings),
            originalTitle = originalTitle,
            altTitles = alternateTitles(title, item.allTitles, originalTitle, extra = item.titleEn),
            format = formatFor(type, item.type),
            links = linksFor(item.url),
        )
    }

    private fun bestItem(item: SimklBestItem, type: SimklCatalogType): CatalogItem {
        val rating = item.ratings?.primary
        return CatalogItem(
            source = CatalogSourceId.SIMKL,
            kind = kindFor(type, null),
            title = item.title.orEmpty(),
            year = item.year,
            rating = rating?.rating,
            votes = rating?.votes,
            ids = item.ids.toCatalogItemIds(),
            posterUrl = simklPosterUrl(item.poster),
            posterVariants = simklPosterVariants(item.poster),
            ratings = ratingsFor(item.ratings),
            audience = audienceFor(item.watched, CatalogAudiencePeriod.MONTH, null, null),
            format = formatFor(type, null),
            links = linksFor(item.url),
        )
    }

    private fun allItemsItem(entry: SimklAllItemsEntry, type: SimklCatalogType): CatalogItem {
        val media = entry.media!!
        val kind = kindFor(type, entry.animeType)
        return CatalogItem(
            source = CatalogSourceId.SIMKL,
            kind = kind,
            title = media.title.orEmpty(),
            year = media.year,
            overview = media.overview,
            runtimeMinutes = media.runtime,
            genres = media.genres,
            airStatus = airStatusFor(media.status, kind),
            episodeCount = episodes(kind, entry.totalEpisodes),
            network = media.network,
            ids = media.ids.toCatalogItemIds(),
            posterUrl = simklPosterUrl(media.poster),
            backdropUrl = simklFanartUrl(media.fanart),
            posterVariants = simklPosterVariants(media.poster),
            backdropVariants = simklFanartVariants(media.fanart),
            addedAt = date(entry.addedAt),
            userRating = entry.userRating,
            format = formatFor(type, entry.animeType),
            unairedEpisodeCount = episodes(kind, entry.notAiredEpisodes),
        )
    }

    private fun recommendationItem(item: SimklRecommendation, type: SimklCatalogType): CatalogItem {
        val title = item.title.orEmpty()
        return CatalogItem(
            source = CatalogSourceId.SIMKL,
            kind = kindFor(type, item.animeType),
            title = title,
            year = item.year,
            ids = item.ids.toCatalogItemIds(),
            posterUrl = simklPosterUrl(item.poster),
            posterVariants = simklPosterVariants(item.poster),
            altTitles = alternateTitles(title, null, null, extra = item.englishTitle),
            format = formatFor(type, item.animeType),
            recommendationCount = item.usersCount?.takeIf { it >= 0 },
            recommendationPercent = percentFraction(item.usersPercent),
        )
    }

    private fun detailItem(detail: SimklDetail, type: SimklCatalogType): CatalogItem {
        val kind = kindFor(type, detail.animeType)
        val rating = detail.ratings?.primary
        val title = detail.title.orEmpty()
        val originalTitle = originalTitle(title, detail.originalTitle)
        return CatalogItem(
            source = CatalogSourceId.SIMKL,
            kind = kind,
            title = title,
            year = detail.year,
            overview = detail.overview,
            runtimeMinutes = detail.runtime,
            rating = rating?.rating,
            votes = rating?.votes,
            genres = detail.genres,
            certification = detail.certification,
            trailerUrl = youTubeTrailerUrl(detail.trailer),
            airStatus = airStatusFor(detail.status, kind),
            episodeCount = episodes(kind, detail.totalEpisodes),
            network = detail.network,
            ids = detail.ids.toCatalogItemIds(),
            posterUrl = simklPosterUrl(detail.poster),
            backdropUrl = simklFanartUrl(detail.fanart),
            posterVariants = simklPosterVariants(detail.poster),
            backdropVariants = simklFanartVariants(detail.fanart),
            ratings = ratingsFor(detail.ratings),
            ranks = rankFor(detail.rank, CatalogRankScope.POPULAR, allTime = true),
            audience = audienceFor(null, null, null, detail.dropRate),
            broadcast = broadcastFor(detail.airs),
            releaseDate = date(detail.released ?: detail.firstAired),
            physicalReleaseDate = date(detail.physicalRelease),
            endDate = date(detail.lastAired),
            originalTitle = originalTitle,
            altTitles = alternateTitles(title, detail.alternateTitles, originalTitle, extra = detail.englishTitle),
            broadcastSeason = seasonFor(detail.seasonNameYear),
            format = formatFor(type, detail.animeType),
            studios = detail.studios,
            countries = countryFor(detail.country),
            languages = languageFor(detail.language),
            credits = creditsFor(detail.director),
            links = linksFor(detail.url),
            budget = detail.budget,
            revenue = detail.revenue,
        )
    }

    companion object {
        /** How long a downloaded row serves page 1 before it is fetched again. */
        val ROW_CACHE_TTL = 15.minutes

        private const val SITE = "https://simkl.com"

        fun airStatusFor(status: String?, kind: MediaKind): CatalogAirStatus? = when (status?.lowercase()) {
            "airing", "ongoing" -> CatalogAirStatus.AIRING
            "ended" -> if (kind == MediaKind.MOVIE) null else CatalogAirStatus.ENDED
            "premiere", "tba" -> CatalogAirStatus.UPCOMING
            else -> null
        }

        private fun recommendationType(item: SimklRecommendation): SimklCatalogType = when (item.type?.lowercase()) {
            "movie" -> SimklCatalogType.MOVIES
            "anime" -> SimklCatalogType.ANIME
            else -> SimklCatalogType.TV
        }

        private fun kindFor(type: SimklCatalogType, animeType: String?): MediaKind = when {
            type == SimklCatalogType.MOVIES -> MediaKind.MOVIE
            type == SimklCatalogType.ANIME && animeType?.lowercase() == "movie" -> MediaKind.MOVIE
            else -> MediaKind.SHOW
        }

        private fun episodes(kind: MediaKind, count: Int?): Int? = if (kind == MediaKind.MOVIE || count == null || count <= 0) null else count

        private fun formatFor(type: SimklCatalogType, raw: String?): CatalogFormat? {
            if (type != SimklCatalogType.ANIME) return null
            return when (raw?.trim()?.lowercase()) {
                null, "" -> null
                "tv" -> CatalogFormat.TV
                "tv short", "tv_short", "tv-short" -> CatalogFormat.TV_SHORT
                "movie" -> CatalogFormat.MOVIE
                "special" -> CatalogFormat.SPECIAL
                "ova" -> CatalogFormat.OVA
                "ona" -> CatalogFormat.ONA
                "music", "music video" -> CatalogFormat.MUSIC
                else -> CatalogFormat.OTHER
            }
        }

        /** Simkl's own, IMDb's and MAL's scores, each 0–10; out-of-range values and negative vote counts are dropped. */
        private fun ratingsFor(ratings: SimklRatings?): List<MediaRatingSource>? {
            if (ratings == null) return null
            val result = listOf("simkl" to ratings.simkl, "imdb" to ratings.imdb, "mal" to ratings.mal).mapNotNull { (source, rating) ->
                val value = rating?.rating?.takeIf { it in 0.0..10.0 } ?: return@mapNotNull null
                MediaRatingSource(source, value, rating.votes?.takeIf { it >= 0 })
            }
            return result.ifEmpty { null }
        }

        private fun audienceFor(viewers: Int?, viewersPeriod: CatalogAudiencePeriod?, planning: Int?, dropRate: String?): CatalogAudience? {
            val normalizedViewers = viewers?.takeIf { it >= 0 }
            val normalizedPlanning = planning?.takeIf { it >= 0 }
            val normalizedDropRate = percentFraction(dropRate)
            if (normalizedViewers == null && normalizedPlanning == null && normalizedDropRate == null) return null
            return CatalogAudience(
                viewers = normalizedViewers,
                viewersPeriod = if (normalizedViewers == null) null else viewersPeriod,
                planning = normalizedPlanning,
                dropRate = normalizedDropRate,
            )
        }

        /** `2.5%` as 0.025; null outside 0–100. */
        private fun percentFraction(raw: String?): Double? {
            val value = raw?.trim()?.replace("%", "")?.toDoubleOrNull() ?: return null
            return if (value < 0 || value > 100) null else value / 100
        }

        private fun rankFor(rank: Int?, scope: CatalogRankScope, allTime: Boolean): List<CatalogRank>? =
            if (rank == null || rank <= 0) null else listOf(CatalogRank(rank = rank, scope = scope, allTime = allTime))

        private fun originalTitle(title: String, raw: String?): String? {
            val value = raw?.trim()
            if (value.isNullOrEmpty() || value.lowercase() == title.trim().lowercase()) return null
            return value
        }

        /** [raw] then [extra], trimmed, without blanks, [title], [originalTitle] or case-insensitive repeats. */
        private fun alternateTitles(title: String, raw: List<String>?, originalTitle: String?, extra: String? = null): List<String> {
            val seen = hashSetOf(title.trim().lowercase())
            if (originalTitle != null) seen += originalTitle.lowercase()
            return (raw.orEmpty() + listOfNotNull(extra)).mapNotNull { candidate ->
                candidate.trim().takeIf { it.isNotEmpty() && seen.add(it.lowercase()) }
            }
        }

        /** The Simkl page, resolving a site-relative path against simkl.com; only http(s) links. */
        private fun linksFor(raw: String?): List<CatalogLink>? {
            val value = raw?.trim()
            if (value.isNullOrEmpty()) return null
            val scheme = Regex("^([A-Za-z][A-Za-z0-9+.-]*):").find(value)?.groupValues?.get(1)?.lowercase()
            val url = when {
                scheme == null -> if (value.startsWith("/")) "$SITE$value" else "$SITE/$value"
                scheme == "http" || scheme == "https" -> value
                else -> return null
            }
            return listOf(CatalogLink(label = "Simkl", url = url))
        }

        private val US_DATE = Regex("""^(\d{1,2})/(\d{1,2})/(\d{4})$""")

        /** ISO-8601, or the CDN's `M/D/YYYY`. */
        private fun date(raw: String?): Instant? {
            val value = raw?.trim()
            if (value.isNullOrEmpty()) return null
            parseCatalogInstant(value)?.let { return it }
            val match = US_DATE.matchEntire(value) ?: return null
            val (month, day, year) = match.destructured
            return parseCatalogInstant("$year-${month.padStart(2, '0')}-${day.padStart(2, '0')}")
        }

        private fun countryFor(raw: String?): List<String>? = raw?.trim()?.takeIf(String::isNotEmpty)?.let { listOf(CountryCodes.normalizeCode(it)) }

        private fun languageFor(raw: String?): List<String>? = raw?.trim()?.takeIf(String::isNotEmpty)?.let { listOf(it.lowercase()) }

        private fun creditsFor(director: String?): List<CatalogCredit>? =
            director?.trim()?.takeIf(String::isNotEmpty)?.let { listOf(CatalogCredit(it, CatalogCreditRole.DIRECTOR)) }

        private fun broadcastFor(airs: SimklAirs?): CatalogBroadcast? {
            if (airs == null) return null
            val weekday = weekdayFor(airs.day)
            val time = broadcastTime(airs.time)
            if (weekday == null && time == null) return null
            return CatalogBroadcast(weekday = weekday, time = time, timezone = airs.timezone?.trim()?.takeIf(String::isNotEmpty))
        }

        private fun weekdayFor(raw: String?): Int? = when (raw?.trim()?.lowercase()) {
            "monday" -> 1
            "tuesday" -> 2
            "wednesday" -> 3
            "thursday" -> 4
            "friday" -> 5
            "saturday" -> 6
            "sunday" -> 7
            else -> null
        }

        private val BROADCAST_TIME = Regex("""^(\d{1,2}):(\d{2})\s*([AP]M)?$""", RegexOption.IGNORE_CASE)

        /** `11:15 PM` or `23:15` as `HH:mm`; null when out of range. */
        private fun broadcastTime(raw: String?): String? {
            val match = BROADCAST_TIME.matchEntire(raw?.trim().orEmpty()) ?: return null
            var hour = match.groupValues[1].toInt()
            val minute = match.groupValues[2].toInt()
            val period = match.groupValues[3].uppercase().ifEmpty { null }
            if (minute > 59 || (period == null && hour > 23) || (period != null && (hour < 1 || hour > 12))) return null
            if (period != null) {
                hour %= 12
                if (period == "PM") hour += 12
            }
            return "${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}"
        }

        /** `Fall 1999`. */
        private fun seasonFor(raw: String?): CatalogSeasonInfo? {
            val parts = raw?.trim()?.split(Regex("\\s+")) ?: return null
            val name = CatalogSeasonName.parse(parts.first()) ?: return null
            return CatalogSeasonInfo(name, if (parts.size > 1) parts.last().toIntOrNull() else null)
        }
    }
}
