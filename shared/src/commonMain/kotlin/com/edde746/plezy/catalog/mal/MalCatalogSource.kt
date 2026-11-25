package com.edde746.plezy.catalog.mal

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogAudience
import com.edde746.plezy.catalog.CatalogBroadcast
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
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
import com.edde746.plezy.catalog.CatalogWatchlistMachinery
import com.edde746.plezy.catalog.FribbIndexSource
import com.edde746.plezy.catalog.WatchlistKeyPage
import com.edde746.plezy.catalog.pickRow
import com.edde746.plezy.catalog.rowsByMal
import com.edde746.plezy.catalog.seasonRef
import com.edde746.plezy.catalog.tmdbIdFor
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.string
import com.edde746.plezy.trackers.ids.FribbRow
import com.edde746.plezy.trackers.mal.MalApi
import io.ktor.http.Parameters
import io.ktor.http.formUrlEncode
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Instant
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

/**
 * The Explore catalog of the user's MyAnimeList account. MAL is anime-only with no movie/show split, so it serves the
 * anime rows, and its watchlist is the user's Plan to Watch list.
 *
 * MAL entries carry no media-server ids; the Fribb mapping ([mappings]) bridges both directions: catalog items are
 * enriched with tvdb/tmdb/imdb (library matching, cross-source membership), and library items resolve to a MAL id via
 * [resolveItemIds].
 */
internal class MalCatalogSource(
    private val api: MalApi,
    private val mappings: FribbIndexSource,
) : CatalogWatchlistMachinery() {

    override val id: CatalogSourceId get() = CatalogSourceId.MAL

    override val supportedRows: List<CatalogRowId> = listOf(
        CatalogRowId.WATCHLIST,
        CatalogRowId.SUGGESTED_ANIME,
        CatalogRowId.AIRING_ANIME,
        CatalogRowId.POPULAR_ANIME,
    )

    override val watchlistLogLabel: String get() = "MAL: Plan to Watch"

    /** Full-snapshot paging: 4 × 500 covers 2000 Plan to Watch entries. */
    override val watchlistPageLimit: Int get() = 500
    override val watchlistMaxPages: Int get() = 4

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage {
        val result = when (row) {
            CatalogRowId.WATCHLIST -> planToWatch(page, limit)
            CatalogRowId.SUGGESTED_ANIME -> animePage("/anime/suggestions", emptyList(), page, limit)
            CatalogRowId.AIRING_ANIME -> ranking("airing", page, limit)
            CatalogRowId.POPULAR_ANIME -> ranking("bypopularity", page, limit)
            else -> throw IllegalArgumentException("MAL does not serve ${row.id}")
        }
        val rankingScope = when (row) {
            CatalogRowId.AIRING_ANIME -> CatalogRankScope.AIRING
            CatalogRowId.POPULAR_ANIME -> CatalogRankScope.POPULAR
            else -> null
        }
        return CatalogPage(
            items = toCatalogItems(result.items, rankingRanks = result.rankingRanks, rankingScope = rankingScope),
            hasMore = result.hasMore,
        )
    }

    /** MAL rejects queries under 3 characters (`invalid q`): empty instead of a 400 while the user is still typing. */
    override suspend fun search(query: String, limit: Int): List<CatalogItem> {
        val trimmed = query.trim()
        if (trimmed.length < 3) return emptyList()
        return toCatalogItems(animePage("/anime", listOf("q" to trimmed), 1, limit).items)
    }

    /** The detail body and the characters, concurrently, each failing alone. */
    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail {
        val malId = item.ids.mal ?: return CatalogDetail(item = item)
        val (detail, cast) = coroutineScope {
            val detail = async { isolated("anime detail") { animeDetail(malId, relatedLimit) } }
            val cast = async { isolated("character") { characters(malId, castLimit) }.orEmpty() }
            detail.await() to cast.await()
        }
        if (detail == null) return CatalogDetail(item = item, cast = cast)

        val recommendations = detail.recommendations.filter { it.anime.id != null }
        val relations = detail.relations.filter { it.anime.id != null }
        // One mapping read for both lists.
        val linked = toCatalogItems(
            recommendations.map { it.anime } + relations.map { it.anime },
            recommendationCounts = recommendations.map { it.count },
        )
        val related = linked.subList(0, recommendations.size)
        val grouped = LinkedHashMap<CatalogRelationType, MutableList<CatalogItem>>()
        relations.forEachIndexed { i, relation ->
            grouped.getOrPut(relationTypeFor(relation.type)) { ArrayList() } += linked[recommendations.size + i]
        }

        val detailItem = toCatalogItem(detail.anime, null, statistics = detail.statistics, background = detail.background)
        return CatalogDetail(
            item = item.enrichedWith(detailItem),
            cast = cast,
            related = related,
            relations = grouped.map { (type, items) -> CatalogRelation(type, items) },
        )
    }

    /**
     * A library item's MAL entry. A show-level id can resolve to several rows (split-cour anime): season 1 wins, since
     * "add this show" means its first season on MAL. Null (non-anime) hides the watchlist action.
     */
    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? {
        val malId = mappings.pickRow(kind, external) { it.mal != null }?.mal ?: return null
        return CatalogItemIds(mal = malId, imdb = external.imdb, tmdb = external.tmdb, tvdb = external.tvdb)
    }

    /**
     * MAL ids are unique across anime, so membership keys skip the kind namespace: a library movie and a MAL `ova` entry
     * for the same title still agree.
     */
    override fun membershipKeysFor(kind: MediaKind, ids: CatalogItemIds): List<String> = listOfNotNull(ids.mal?.let(::membershipKey))

    override suspend fun fetchWatchlistKeyPage(page: Int, limit: Int): WatchlistKeyPage {
        val result = planToWatch(page, limit)
        return WatchlistKeyPage(groups = result.items.mapNotNull { anime -> anime.id?.let { listOf(membershipKey(it)) } }, hasMore = result.hasMore)
    }

    override suspend fun resolveWatchlistMutationIds(kind: MediaKind, ids: CatalogItemIds): CatalogItemIds {
        val malId = ids.mal ?: resolveItemIds(kind, ids.toExternalIds())?.mal
            ?: throw IllegalStateException("MAL: no anime mapping for ${ids.canonicalKey ?: "item"}")
        return CatalogItemIds(mal = malId, imdb = ids.imdb, tmdb = ids.tmdb, tvdb = ids.tvdb)
    }

    override suspend fun performWatchlistMutation(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        val malId = checkNotNull(ids.mal)
        if (add) {
            api.put("/anime/$malId/my_list_status", listOf("status" to PLAN_TO_WATCH))
            return
        }
        // MAL can only delete the whole list entry (progress, score, dates and rewatches with it), so remove it only
        // while it is still Plan to Watch. One that has moved on is already off the watchlist.
        if (listStatus(malId) != PLAN_TO_WATCH) {
            reloadWatchlistSnapshot()
            return
        }
        try {
            api.delete("/anime/$malId/my_list_status")
        } catch (e: TrackerException.Api) {
            // Already gone is success.
            if (e.status != 404) throw e
        }
    }

    override fun dispose() {
        disposeWatchlistMachinery()
    }

    /** The user's own list, so NSFW entries stay. */
    private suspend fun planToWatch(page: Int, limit: Int): MalPage = animePage(
        "/users/@me/animelist",
        listOf("status" to PLAN_TO_WATCH, "sort" to "list_updated_at", "nsfw" to "true"),
        page,
        limit,
    )

    private suspend fun ranking(type: String, page: Int, limit: Int): MalPage =
        animePage("/anime/ranking", listOf("ranking_type" to type), page, limit)

    /** One offset-paged list of [path]. */
    private suspend fun animePage(path: String, params: List<Pair<String, String>>, page: Int, limit: Int): MalPage {
        val query = Parameters.build {
            for ((name, value) in params) append(name, value)
            append("limit", limit.toString())
            if (page > 1) append("offset", ((page - 1) * limit).toString())
            append("fields", CATALOG_FIELDS)
        }.formUrlEncode()
        return MalPage.fromJson(api.get("$path?$query").jsonObject())
    }

    private suspend fun animeDetail(malId: Int, relatedLimit: Int): MalAnimeDetail =
        MalAnimeDetail.fromJson(api.get("/anime/$malId?fields=$DETAIL_FIELDS").jsonObject(), relatedLimit)

    /** Characters, main roles first; nameless ones dropped. */
    private suspend fun characters(malId: Int, limit: Int): List<CatalogCastMember> =
        api.get("/anime/$malId/characters?limit=$limit&fields=$CHARACTER_FIELDS").jsonObject()["data"].objects
            .map(MalCharacter::fromEntry)
            .filter { it.name.isNotEmpty() }
            .map { CatalogCastMember(name = it.name, secondary = it.role, imageUrl = it.imageUrl) }

    /** The viewer's list status of [malId] (`plan_to_watch`, `watching`, ...), null when it is not on their list. */
    private suspend fun listStatus(malId: Int): String? =
        api.getOrNull("/anime/$malId?fields=my_list_status")?.json().obj?.get("my_list_status").obj?.get("status").string

    private suspend fun <T> isolated(what: String, load: suspend () -> T): T? = try {
        load()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "MAL: $what load failed" }
        null
    }

    /** Items for [anime], enriched from one mapping read; entries without an id are dropped. */
    private suspend fun toCatalogItems(
        anime: List<MalAnime>,
        rankingRanks: List<Int?> = emptyList(),
        rankingScope: CatalogRankScope? = null,
        recommendationCounts: List<Int?> = emptyList(),
    ): List<CatalogItem> {
        val indexes = anime.indices.filter { anime[it].id != null }
        val rows = mappings.rowsByMal(indexes.map { anime[it].id })
        return indexes.mapIndexed { i, index ->
            toCatalogItem(
                anime[index],
                rows[i],
                rankingRank = rankingRanks.getOrNull(index),
                rankingScope = rankingScope,
                recommendationCount = recommendationCounts.getOrNull(index),
            )
        }
    }

    private fun toCatalogItem(
        anime: MalAnime,
        row: FribbRow?,
        rankingRank: Int? = null,
        rankingScope: CatalogRankScope? = null,
        recommendationCount: Int? = null,
        statistics: MalStatistics? = null,
        background: String? = null,
    ): CatalogItem {
        val title = anime.displayTitle
        val nativeTitle = anime.titleJa?.trim()
        val originalTitle = if (!nativeTitle.isNullOrEmpty()) nativeTitle else anime.title
        // Romaji stays even when it is also the display title. MAL repeats these titles in synonyms, so keep the first
        // occurrence of each.
        val altTitles = (listOf(anime.titleEn, anime.title, anime.titleJa) + anime.synonyms.orEmpty())
            .filterNotNull()
            .filter { it.isNotEmpty() && (it != title || it == anime.title) }
            .distinct()
        return CatalogItem(
            source = CatalogSourceId.MAL,
            kind = if (anime.isMovie) MediaKind.MOVIE else MediaKind.SHOW,
            title = title,
            altTitles = altTitles,
            year = anime.year,
            overview = anime.synopsis,
            runtimeMinutes = anime.runtimeMinutes,
            rating = anime.mean,
            votes = anime.numScoringUsers,
            genres = anime.genres,
            certification = anime.certification,
            airStatus = airStatusFor(anime),
            episodeCount = if (anime.isMovie || (anime.numEpisodes ?: 0) <= 0) null else anime.numEpisodes,
            network = anime.primaryStudio,
            ids = CatalogItemIds(
                mal = anime.id,
                anilist = row?.anilist,
                simkl = row?.simkl,
                imdb = row?.imdb?.firstOrNull(),
                tmdb = row?.tmdbIdFor(movie = anime.isMovie),
                tvdb = row?.tvdb,
            ),
            // Which season of the parent series this entry is, for the reverse library lookup; unrelated to the
            // calendar broadcastSeason.
            season = row?.seasonRef,
            posterUrl = anime.posterUrl,
            ranks = ranksFor(anime, rankingRank, rankingScope),
            audience = audienceFor(anime, statistics),
            broadcast = broadcastFor(anime.broadcastDay, anime.broadcastTime),
            endDate = dateFor(anime.endDate),
            originalTitle = originalTitle?.takeIf { it.isNotEmpty() && it != title },
            broadcastSeason = CatalogSeasonName.parse(anime.startSeasonName)?.let { CatalogSeasonInfo(it, anime.startSeasonYear) },
            sourceMaterial = sourceMaterialFor(anime.source),
            isAdult = when (anime.nsfw) {
                "gray", "black" -> true
                "white" -> false
                else -> null
            },
            recommendationCount = recommendationCount,
            background = background,
        )
    }

    internal companion object {
        private const val TAG = "catalog"
        private const val PLAN_TO_WATCH = "plan_to_watch"

        /** Anime summary fields shared by every Explore list and nested detail node. */
        const val CATALOG_FIELDS = "id,title,main_picture,alternative_titles,start_date,synopsis,mean," +
            "genres,media_type,rating,num_episodes,average_episode_duration,start_season," +
            "status,studios,num_scoring_users,broadcast,popularity,num_list_users,rank," +
            "nsfw,source,end_date"

        /** The detail body: the summary fields plus recommendations, relations, status statistics and background. */
        const val DETAIL_FIELDS = "$CATALOG_FIELDS,recommendations%7B$CATALOG_FIELDS%7D," +
            "related_anime%7B$CATALOG_FIELDS%7D,statistics,background"

        private const val CHARACTER_FIELDS = "role,main_picture,first_name,last_name"

        private fun membershipKey(malId: Int) = "mal:$malId"

        /** MAL's status, normalized. `finished_airing` on a movie is null: an "Ended" chip on every movie is noise. */
        fun airStatusFor(anime: MalAnime): CatalogAirStatus? = when (anime.status) {
            "currently_airing" -> CatalogAirStatus.AIRING
            "finished_airing" -> if (anime.isMovie) null else CatalogAirStatus.ENDED
            "not_yet_aired" -> CatalogAirStatus.UPCOMING
            else -> null
        }

        private fun ranksFor(anime: MalAnime, rankingRank: Int?, rankingScope: CatalogRankScope?): List<CatalogRank>? {
            val ranks = ArrayList<CatalogRank>()
            var rowRankIsPopular = false
            if (rankingRank != null && rankingRank > 0 && rankingScope != null) {
                ranks += CatalogRank(rank = rankingRank, scope = rankingScope, allTime = true)
                rowRankIsPopular = rankingScope == CatalogRankScope.POPULAR
            }
            val popularity = anime.popularity
            if (popularity != null && popularity > 0 && !rowRankIsPopular) {
                ranks += CatalogRank(rank = popularity, scope = CatalogRankScope.POPULAR, allTime = true)
            }
            val scoreRank = anime.rank
            if (scoreRank != null && scoreRank > 0) ranks += CatalogRank(rank = scoreRank, scope = CatalogRankScope.RATED, allTime = true)
            return ranks.ifEmpty { null }
        }

        private fun audienceFor(anime: MalAnime, statistics: MalStatistics?): CatalogAudience? = CatalogAudience(
            listed = statistics?.numListUsers ?: anime.numListUsers,
            planning = statistics?.planToWatch,
            watching = statistics?.watching,
            completed = statistics?.completed,
            onHold = statistics?.onHold,
            dropped = statistics?.dropped,
        ).takeUnless { it.isEmpty }

        private val WEEKDAYS = listOf("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday")

        /** MAL's weekly slot, which is Japan time. */
        private fun broadcastFor(day: String?, startTime: String?): CatalogBroadcast? {
            val weekday = WEEKDAYS.indexOf(day?.lowercase()).takeIf { it >= 0 }?.plus(1)
            val time = normalizedTime(startTime)
            if (weekday == null && time == null) return null
            return CatalogBroadcast(weekday = weekday, time = time, timezone = "Asia/Tokyo")
        }

        private fun normalizedTime(value: String?): String? {
            if (value == null || value.length != 5 || value[2] != ':') return null
            val hour = value.substring(0, 2).toIntOrNull()
            val minute = value.substring(3).toIntOrNull()
            if (hour == null || hour !in 0..23 || minute == null || minute !in 0..59) return null
            return value
        }

        private fun sourceMaterialFor(source: String?): CatalogSourceMaterial? = when (source) {
            null, "" -> null
            "original" -> CatalogSourceMaterial.ORIGINAL
            "manga", "4_koma_manga", "digital_manga" -> CatalogSourceMaterial.MANGA
            "light_novel" -> CatalogSourceMaterial.LIGHT_NOVEL
            "novel" -> CatalogSourceMaterial.NOVEL
            "visual_novel" -> CatalogSourceMaterial.VISUAL_NOVEL
            "game", "card_game" -> CatalogSourceMaterial.GAME
            "web_manga" -> CatalogSourceMaterial.WEB_COMIC
            "music" -> CatalogSourceMaterial.MUSIC_RELEASE
            else -> CatalogSourceMaterial.OTHER_MEDIA
        }

        /** A full `YYYY-MM-DD` date as UTC midnight; partial dates (`YYYY-MM`, `YYYY`) are null. */
        private fun dateFor(value: String?): Instant? =
            value?.let(CalendarDate::parse)?.let { Instant.parse("${it}T00:00:00Z") }

        private fun relationTypeFor(type: String?): CatalogRelationType = when (type) {
            "prequel" -> CatalogRelationType.PREQUEL
            "sequel" -> CatalogRelationType.SEQUEL
            "side_story" -> CatalogRelationType.SIDE_STORY
            "spin_off" -> CatalogRelationType.SPIN_OFF
            "alternative_version" -> CatalogRelationType.ALTERNATIVE_VERSION
            "summary" -> CatalogRelationType.SUMMARY
            "parent_story" -> CatalogRelationType.PARENT_STORY
            "adaptation" -> CatalogRelationType.ADAPTATION
            else -> CatalogRelationType.OTHER
        }
    }
}
