package com.edde746.plezy.catalog.anilist

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogAudience
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogCredit
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogFormat
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogLink
import com.edde746.plezy.catalog.CatalogNextEpisode
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRank
import com.edde746.plezy.catalog.CatalogRankScope
import com.edde746.plezy.catalog.CatalogRelation
import com.edde746.plezy.catalog.CatalogRelationType
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSeasonInfo
import com.edde746.plezy.catalog.CatalogSeasonName
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogSourceMaterial
import com.edde746.plezy.catalog.CatalogTag
import com.edde746.plezy.catalog.CatalogWatchlistMachinery
import com.edde746.plezy.catalog.FribbIndexSource
import com.edde746.plezy.catalog.WatchlistKeyPage
import com.edde746.plezy.catalog.pickRow
import com.edde746.plezy.catalog.rowByMal
import com.edde746.plezy.catalog.rowsByMal
import com.edde746.plezy.catalog.seasonRef
import com.edde746.plezy.catalog.tmdbIdFor
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.CountryCodes
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.anilist.AnilistApi
import com.edde746.plezy.trackers.client.flexibleInt
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.string
import com.edde746.plezy.trackers.ids.FribbRow
import kotlin.concurrent.Volatile
import kotlin.time.Clock
import kotlin.time.Instant
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** An AniList broadcast season (`WINTER`, `SPRING`, `SUMMER`, `FALL`) of [year]. */
internal data class AnimeSeason(val season: String, val year: Int)

/** One page of AniList media. */
internal data class AnilistPage(val items: List<AnilistMedia>, val hasMore: Boolean)

/**
 * The Explore catalog of the user's AniList account, over its GraphQL API. Its watchlist is the Planning list. The Fribb
 * mapping ([mappings]) bridges AniList/MAL identities to media-server ids.
 *
 * @param clock today's date for the airing row's broadcast season (UTC).
 */
internal class AnilistCatalogSource(
    private val api: AnilistApi,
    private val mappings: FribbIndexSource,
    private val clock: Clock = Clock.System,
) : CatalogWatchlistMachinery() {
    private val viewerLock = Mutex()

    @Volatile
    private var viewerId: Int? = null

    override val id: CatalogSourceId get() = CatalogSourceId.ANILIST

    override val supportedRows: List<CatalogRowId> = listOf(
        CatalogRowId.WATCHLIST,
        CatalogRowId.TRENDING_ANIME,
        CatalogRowId.AIRING_ANIME,
        CatalogRowId.POPULAR_ANIME,
    )

    override val watchlistLogLabel: String get() = "AniList: Planning"
    override val watchlistPageLimit: Int get() = 500
    override val watchlistMaxPages: Int get() = 4

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage {
        val result = when (row) {
            CatalogRowId.WATCHLIST -> planningPage(viewerId(), page, limit, idsOnly = false)
            CatalogRowId.TRENDING_ANIME -> animePage("TRENDING_DESC", page, limit, includeRowCast = true)
            CatalogRowId.AIRING_ANIME -> {
                val today = CalendarDate.parse(clock.now().toString().take(10))
                    ?: throw IllegalStateException("the clock's date is out of range")
                animePage("POPULARITY_DESC", page, limit, includeRowCast = true, season = currentAnimeSeason(today))
            }
            CatalogRowId.POPULAR_ANIME -> animePage("POPULARITY_DESC", page, limit, includeRowCast = true)
            else -> throw IllegalArgumentException("AniList does not serve ${row.id}")
        }
        return CatalogPage(items = toCatalogItems(result.items), hasMore = result.hasMore)
    }

    override suspend fun search(query: String, limit: Int): List<CatalogItem> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        return toCatalogItems(animePage("SEARCH_MATCH", 1, limit, includeRowCast = false, search = trimmed).items)
    }

    /**
     * One request: the detail fields, recommendations and relations, plus the characters unless the row item already
     * carries its cast.
     */
    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail {
        val anilistId = item.ids.anilist ?: return CatalogDetail(item = item)
        val cachedCast = item.cast
        val includeCharacters = cachedCast == null
        val variables = buildJsonObject {
            put("id", anilistId)
            if (includeCharacters) put("castPerPage", castLimit.coerceIn(1, 50))
            put("relatedPerPage", relatedLimit.coerceIn(1, 50))
            put("staffPerPage", AnilistDocuments.DETAIL_STAFF_LIMIT)
        }
        val media = api.query(AnilistDocuments.detail(includeCharacters), variables)["Media"].obj
            ?: return CatalogDetail(item = item, cast = cachedCast.orEmpty())

        val recommendations = media["recommendations"].obj?.get("nodes").objects
            .mapNotNull { it["mediaRecommendation"].obj?.let(AnilistMedia::fromJson) }
            .filter { !it.isAdult && it.id != null }
        val relations = media["relations"].obj?.get("edges").objects
            .mapNotNull { edge -> edge["node"].obj?.let { edge["relationType"].string to AnilistMedia.fromJson(it) } }
            .filter { (_, node) -> !node.isAdult && node.id != null }
        // One mapping read for both lists.
        val linked = toCatalogItems(recommendations + relations.map { it.second })
        val grouped = LinkedHashMap<CatalogRelationType, MutableList<CatalogItem>>()
        relations.forEachIndexed { i, (type, _) ->
            grouped.getOrPut(relationTypeFor(type)) { ArrayList() } += linked[recommendations.size + i]
        }
        val detailItem = toCatalogItem(AnilistMedia.fromJson(media), null)
        return CatalogDetail(
            item = item.enrichedWith(detailItem),
            cast = cachedCast ?: detailItem.cast.orEmpty(),
            related = linked.subList(0, recommendations.size),
            relations = grouped.map { (type, items) -> CatalogRelation(type, items) },
        )
    }

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? {
        val row = mappings.pickRow(kind, external) { it.anilist != null } ?: return null
        return CatalogItemIds(anilist = row.anilist, mal = row.mal, imdb = external.imdb, tmdb = external.tmdb, tvdb = external.tvdb)
    }

    /** AniList and MAL ids are unique across anime, so membership keys skip the kind namespace. */
    override fun membershipKeysFor(kind: MediaKind, ids: CatalogItemIds): List<String> = identityKeys(ids.anilist, ids.mal)

    override suspend fun fetchWatchlistKeyPage(page: Int, limit: Int): WatchlistKeyPage {
        val result = planningPage(viewerId(), page, limit, idsOnly = true)
        return WatchlistKeyPage(
            groups = result.items.map { identityKeys(it.id, it.idMal) }.filter { it.isNotEmpty() },
            hasMore = result.hasMore,
        )
    }

    override suspend fun resolveWatchlistMutationIds(kind: MediaKind, ids: CatalogItemIds): CatalogItemIds {
        if (ids.anilist != null) return ids
        val malId = ids.mal
        if (malId != null) {
            val anilistId = mappings.rowByMal(malId)?.anilist
            if (anilistId != null) return CatalogItemIds(anilist = anilistId, mal = malId, imdb = ids.imdb, tmdb = ids.tmdb, tvdb = ids.tvdb)
        }
        return resolveItemIds(kind, ids.toExternalIds())?.takeIf { it.anilist != null }
            ?: throw IllegalStateException("AniList: no anime mapping for ${ids.canonicalKey ?: "item"}")
    }

    override suspend fun performWatchlistMutation(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        val anilistId = checkNotNull(ids.anilist)
        if (add) {
            api.query(
                AnilistDocuments.SET_STATUS,
                buildJsonObject {
                    put("mediaId", anilistId)
                    put("status", "PLANNING")
                },
            )
        } else if (!deletePlanningEntry(anilistId)) {
            // Nothing on Planning to remove: the entry moved on or went away since the snapshot loaded, and is already
            // off the watchlist.
            reloadWatchlistSnapshot()
        }
    }

    override fun dispose() {
        disposeWatchlistMachinery()
    }

    /**
     * Deletes the viewer's entry for [mediaId] if it is still on Planning. AniList deletes the whole entry (progress,
     * score, dates, rewatches), so one that moved on to another status is left alone. Whether an entry was deleted.
     */
    private suspend fun deletePlanningEntry(mediaId: Int): Boolean {
        val entry = api.query(AnilistDocuments.LIST_ENTRY, buildJsonObject { put("mediaId", mediaId) })["Media"].obj
            ?.get("mediaListEntry").obj ?: return false
        if (entry["status"].string != "PLANNING") return false
        val entryId = entry["id"].flexibleInt ?: return false
        api.query(AnilistDocuments.DELETE_ENTRY, buildJsonObject { put("id", entryId) })
        return true
    }

    /** The viewer's id, read once; concurrent first callers share the one request. */
    private suspend fun viewerId(): Int {
        viewerId?.let { return it }
        return viewerLock.withLock {
            viewerId ?: run {
                val id = api.query(AnilistDocuments.VIEWER_ID)["Viewer"].obj?.get("id").flexibleInt
                    ?: throw IllegalStateException("AniList: the Viewer answer has no id")
                viewerId = id
                id
            }
        }
    }

    private suspend fun animePage(
        sort: String,
        page: Int,
        limit: Int,
        includeRowCast: Boolean,
        search: String? = null,
        season: AnimeSeason? = null,
    ): AnilistPage {
        val variables = buildJsonObject {
            put("page", page.coerceAtLeast(1))
            put("perPage", limit.coerceIn(1, 50))
            put("sort", JsonArray(listOf(JsonPrimitive(sort))))
            if (search != null) put("search", search)
            if (season != null) {
                put("season", season.season)
                put("seasonYear", season.year)
            }
        }
        val result = api.query(AnilistDocuments.animePage(includeRowCast), variables)["Page"].obj
            ?: return AnilistPage(emptyList(), hasMore = false)
        return AnilistPage(
            items = result["media"].objects.map(AnilistMedia::fromJson),
            hasMore = (result["pageInfo"].obj?.get("hasNextPage") as? JsonPrimitive)?.content == "true",
        )
    }

    /** The viewer's Planning list, custom lists skipped and repeated media kept once. */
    private suspend fun planningPage(userId: Int, chunk: Int, perChunk: Int, idsOnly: Boolean): AnilistPage {
        val variables = buildJsonObject {
            put("userId", userId)
            put("chunk", chunk.coerceAtLeast(1))
            put("perChunk", perChunk.coerceIn(1, 500))
        }
        val collection = api.query(AnilistDocuments.planningList(idsOnly), variables)["MediaListCollection"].obj
            ?: return AnilistPage(emptyList(), hasMore = false)
        val seen = HashSet<Int>()
        val items = collection["lists"].objects
            .filter { (it["isCustomList"] as? JsonPrimitive)?.content != "true" }
            .flatMap { list -> list["entries"].objects.mapNotNull { it["media"].obj?.let(AnilistMedia::fromJson) } }
            .filter { media -> media.id?.let(seen::add) == true }
        return AnilistPage(items, hasMore = (collection["hasNextChunk"] as? JsonPrimitive)?.content == "true")
    }

    /** Items for [anime], enriched from one mapping read; entries without an id are dropped. */
    private suspend fun toCatalogItems(anime: List<AnilistMedia>): List<CatalogItem> {
        val valid = anime.filter { it.id != null }
        val rows = mappings.rowsByMal(valid.map { it.idMal })
        return valid.mapIndexed { i, media -> toCatalogItem(media, rows[i]) }
    }

    private fun toCatalogItem(anime: AnilistMedia, row: FribbRow?): CatalogItem {
        val title = anime.displayTitle
        // Providers repeat titles across fields (AniList lists the English title again under synonyms), and a duplicate
        // costs the reverse library lookup a wasted request.
        val altTitles = (listOf(anime.titleEnglish, anime.titleUserPreferred, anime.titleRomaji, anime.titleNative) + anime.synonyms.orEmpty())
            .filterNotNull()
            .filter { it.isNotEmpty() && it != title }
            .distinct()
        return CatalogItem(
            source = CatalogSourceId.ANILIST,
            kind = if (anime.isMovie) MediaKind.MOVIE else MediaKind.SHOW,
            title = title,
            altTitles = altTitles,
            year = anime.year,
            overview = anime.description,
            runtimeMinutes = anime.runtimeMinutes,
            rating = anime.rating,
            genres = anime.genres,
            trailerUrl = anime.trailerUrl,
            airStatus = airStatusFor(anime),
            episodeCount = if (anime.isMovie || (anime.episodes ?: 0) <= 0) null else anime.episodes,
            network = anime.network,
            ids = CatalogItemIds(
                anilist = anime.id,
                mal = anime.idMal,
                imdb = row?.imdb?.firstOrNull(),
                tmdb = row?.tmdbIdFor(movie = anime.isMovie),
                tvdb = row?.tvdb,
            ),
            season = row?.seasonRef,
            posterUrl = anime.posterUrl,
            backdropUrl = anime.backdropUrl,
            accentColor = anime.coverImageColor?.trim()?.takeIf { ACCENT_COLOR.matches(it) }?.lowercase(),
            ratings = anime.meanRating?.let { listOf(MediaRatingSource(source = "anilist", value = it)) },
            ranks = ranksFor(anime.rankings),
            audience = if (anime.popularity == null && anime.favourites == null && anime.trending == null) {
                null
            } else {
                CatalogAudience(listed = anime.popularity, favorited = anime.favourites, trendingActivity = anime.trending)
            },
            nextEpisode = anime.nextAiringAt?.let { CatalogNextEpisode(airsAt = Instant.fromEpochSeconds(it), episode = anime.nextEpisode) },
            releaseDate = anime.releaseDate,
            endDate = anime.finalEpisodeDate,
            originalTitle = anime.titleNative?.trim()?.takeIf { it.isNotEmpty() && !it.equals(title, ignoreCase = true) },
            broadcastSeason = CatalogSeasonName.parse(anime.season)?.let { CatalogSeasonInfo(it, anime.seasonYear) },
            format = formatFor(anime.format),
            sourceMaterial = sourceMaterialFor(anime.source),
            studios = anime.mainStudios,
            countries = anime.countryOfOrigin?.let(CountryCodes::normalizeCode)?.takeIf { it.isNotEmpty() }?.let { listOf(it) },
            credits = creditsFor(anime.staffCredits),
            tags = anime.tags?.map { CatalogTag(name = it.name, rank = it.rank, isSpoiler = it.isMediaSpoiler) },
            links = linksFor(anime.externalLinks, anime.streamingEpisodes),
            cast = anime.characters?.map { CatalogCastMember(name = it.name, secondary = it.role, imageUrl = it.imageUrl) },
        )
    }

    internal companion object {
        private val ACCENT_COLOR = Regex("^#[0-9a-fA-F]{6}$")

        /** The broadcast season airing on [date]: December already counts as the next year's winter. */
        fun currentAnimeSeason(date: CalendarDate): AnimeSeason = when (date.month) {
            12 -> AnimeSeason("WINTER", date.year + 1)
            1, 2 -> AnimeSeason("WINTER", date.year)
            in 3..5 -> AnimeSeason("SPRING", date.year)
            in 6..8 -> AnimeSeason("SUMMER", date.year)
            else -> AnimeSeason("FALL", date.year)
        }

        fun airStatusFor(anime: AnilistMedia): CatalogAirStatus? = when (anime.status) {
            "RELEASING" -> CatalogAirStatus.AIRING
            "FINISHED" -> if (anime.isMovie) null else CatalogAirStatus.ENDED
            "NOT_YET_RELEASED" -> CatalogAirStatus.UPCOMING
            "CANCELLED" -> CatalogAirStatus.CANCELED
            else -> null
        }

        private fun identityKeys(anilistId: Int?, malId: Int?): List<String> =
            listOfNotNull(anilistId?.let { "anilist:$it" }, malId?.let { "mal:$it" })

        private fun ranksFor(rankings: List<AnilistRanking>?): List<CatalogRank>? = rankings?.mapNotNull { ranking ->
            val scope = when (ranking.type) {
                "POPULAR" -> CatalogRankScope.POPULAR
                "RATED" -> CatalogRankScope.RATED
                else -> return@mapNotNull null
            }
            CatalogRank(
                rank = ranking.rank,
                scope = scope,
                allTime = ranking.allTime,
                year = ranking.year,
                season = CatalogSeasonName.parse(ranking.season),
            )
        }?.ifEmpty { null }

        private fun formatFor(format: String?): CatalogFormat? = when (format) {
            null -> null
            "TV" -> CatalogFormat.TV
            "TV_SHORT" -> CatalogFormat.TV_SHORT
            "MOVIE" -> CatalogFormat.MOVIE
            "SPECIAL" -> CatalogFormat.SPECIAL
            "OVA" -> CatalogFormat.OVA
            "ONA" -> CatalogFormat.ONA
            "MUSIC" -> CatalogFormat.MUSIC
            else -> CatalogFormat.OTHER
        }

        private fun sourceMaterialFor(source: String?): CatalogSourceMaterial? = when (source) {
            null -> null
            "ORIGINAL" -> CatalogSourceMaterial.ORIGINAL
            "MANGA", "COMIC", "DOUJINSHI" -> CatalogSourceMaterial.MANGA
            "LIGHT_NOVEL" -> CatalogSourceMaterial.LIGHT_NOVEL
            "NOVEL", "WEB_NOVEL" -> CatalogSourceMaterial.NOVEL
            "VISUAL_NOVEL" -> CatalogSourceMaterial.VISUAL_NOVEL
            "VIDEO_GAME", "GAME" -> CatalogSourceMaterial.GAME
            "WEB_COMIC" -> CatalogSourceMaterial.WEB_COMIC
            "MUSIC" -> CatalogSourceMaterial.MUSIC_RELEASE
            else -> CatalogSourceMaterial.OTHER_MEDIA
        }

        /** Directors, writers and composers, each person-and-role once; other staff roles are left out. */
        private fun creditsFor(staff: List<AnilistStaffCredit>?): List<CatalogCredit>? = staff
            ?.mapNotNull { member -> creditRoleFor(member.role)?.let { CatalogCredit(member.name, it) } }
            ?.distinct()
            ?.ifEmpty { null }

        private fun creditRoleFor(raw: String): CatalogCreditRole? {
            val role = raw.trim().lowercase()
            return when {
                role == "director" || role == "series director" -> CatalogCreditRole.DIRECTOR
                role == "writer" || role == "series composition" || "script" in role || "screenplay" in role -> CatalogCreditRole.WRITER
                role == "music" || "composer" in role || "music composition" in role -> CatalogCreditRole.COMPOSER
                else -> null
            }
        }

        /** External links, then streaming episodes; a streaming link replaces an external one with the same URL. */
        private fun linksFor(external: List<AnilistLink>?, streaming: List<AnilistLink>?): List<CatalogLink>? {
            val links = external.orEmpty().mapTo(ArrayList()) { CatalogLink(label = it.label, url = it.url) }
            for (link in streaming.orEmpty()) {
                val catalogLink = CatalogLink(label = link.label, url = link.url, isStreaming = true)
                val existing = links.indexOfFirst { it.url == link.url }
                if (existing == -1) links += catalogLink else links[existing] = catalogLink
            }
            return links.ifEmpty { null }
        }

        private fun relationTypeFor(type: String?): CatalogRelationType = when (type) {
            "PREQUEL" -> CatalogRelationType.PREQUEL
            "SEQUEL" -> CatalogRelationType.SEQUEL
            "SIDE_STORY" -> CatalogRelationType.SIDE_STORY
            "SPIN_OFF" -> CatalogRelationType.SPIN_OFF
            "ALTERNATIVE" -> CatalogRelationType.ALTERNATIVE_VERSION
            "SUMMARY" -> CatalogRelationType.SUMMARY
            "PARENT" -> CatalogRelationType.PARENT_STORY
            "ADAPTATION" -> CatalogRelationType.ADAPTATION
            else -> CatalogRelationType.OTHER
        }
    }
}
