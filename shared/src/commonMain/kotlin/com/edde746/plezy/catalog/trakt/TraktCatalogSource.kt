package com.edde746.plezy.catalog.trakt

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogAudience
import com.edde746.plezy.catalog.CatalogBroadcast
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogCredit
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRecommendationReason
import com.edde746.plezy.catalog.CatalogRecommender
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogWatchlistMachinery
import com.edde746.plezy.catalog.WatchlistKeyPage
import com.edde746.plezy.catalog.parseCatalogInstant
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.CountryCodes
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.trakt.TraktApi
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.buildJsonObject

/**
 * The Explore source backed by the Trakt account: its watchlist, personal recommendations, trending and popular rows,
 * search and title detail. Requests go out as the account behind [api], whose session the tracker owns.
 * Watchlist membership matches on every id form, namespaced by kind.
 */
class TraktCatalogSource internal constructor(api: TraktApi) : CatalogWatchlistMachinery() {
    private val client = TraktCatalogClient(api)

    override val id: CatalogSourceId get() = CatalogSourceId.TRAKT

    override val watchlistLogLabel: String get() = "Trakt: watchlist"

    /** 4 × 250 covers 1000 watchlist entries. */
    override val watchlistPageLimit: Int get() = 250
    override val watchlistMaxPages: Int get() = 4

    override val supportedRows: List<CatalogRowId> = listOf(
        CatalogRowId.WATCHLIST,
        CatalogRowId.RECOMMENDED_MOVIES,
        CatalogRowId.RECOMMENDED_SHOWS,
        CatalogRowId.TRENDING_MOVIES,
        CatalogRowId.TRENDING_SHOWS,
        CatalogRowId.POPULAR_MOVIES,
        CatalogRowId.POPULAR_SHOWS,
    )

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage = when (row) {
        CatalogRowId.WATCHLIST -> client.getWatchlist(page, limit).let { CatalogPage(fromEntries(it.items, null), it.hasMore, it.itemCount) }
        CatalogRowId.RECOMMENDED_MOVIES -> CatalogPage(fromMedia(client.getRecommended(TraktCatalogType.MOVIES, limit), MediaKind.MOVIE))
        CatalogRowId.RECOMMENDED_SHOWS -> CatalogPage(fromMedia(client.getRecommended(TraktCatalogType.SHOWS, limit), MediaKind.SHOW))
        CatalogRowId.TRENDING_MOVIES -> client.getTrending(TraktCatalogType.MOVIES, page, limit)
            .let { CatalogPage(fromEntries(it.items, MediaKind.MOVIE), it.hasMore, it.itemCount) }
        CatalogRowId.TRENDING_SHOWS -> client.getTrending(TraktCatalogType.SHOWS, page, limit)
            .let { CatalogPage(fromEntries(it.items, MediaKind.SHOW), it.hasMore, it.itemCount) }
        CatalogRowId.POPULAR_MOVIES -> client.getPopular(TraktCatalogType.MOVIES, page, limit)
            .let { CatalogPage(fromMedia(it.items, MediaKind.MOVIE), it.hasMore, it.itemCount) }
        CatalogRowId.POPULAR_SHOWS -> client.getPopular(TraktCatalogType.SHOWS, page, limit)
            .let { CatalogPage(fromMedia(it.items, MediaKind.SHOW), it.hasMore, it.itemCount) }
        CatalogRowId.TRENDING_ANIME,
        CatalogRowId.SUGGESTED_ANIME,
        CatalogRowId.AIRING_ANIME,
        CatalogRowId.POPULAR_ANIME,
        CatalogRowId.TRENDING,
        CatalogRowId.UPCOMING_MOVIES,
        CatalogRowId.UPCOMING_SHOWS,
        -> throw IllegalArgumentException("Trakt does not serve ${row.id}")
    }

    override suspend fun search(query: String, limit: Int): List<CatalogItem> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        return fromEntries(client.searchCatalog(trimmed, limit = limit).items, null)
    }

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? =
        if (external.hasCatalogIds) CatalogItemIds.fromExternal(external) else null

    /**
     * People and related titles live on separate endpoints, so both requests start before either is awaited, and a
     * failure of one leaves the other's result.
     */
    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail {
        val id = item.ids.trakt?.toString() ?: item.ids.slug ?: item.ids.imdb ?: return CatalogDetail(item)
        val type = if (item.kind == MediaKind.MOVIE) TraktCatalogType.MOVIES else TraktCatalogType.SHOWS
        val (people, related) = coroutineScope {
            val people = async { withoutFailure("people", item) { client.getPeople(type, id) } }
            val related = async { withoutFailure("related", item) { client.getRelated(type, id, relatedLimit) } }
            people.await() to related.await()
        }
        val credits = creditsFrom(people?.crew.orEmpty())
        val enriched = if (credits.isEmpty()) {
            item
        } else {
            item.enrichedWith(CatalogItem(source = CatalogSourceId.TRAKT, kind = item.kind, title = "", ids = CatalogItemIds(), credits = credits))
        }
        return CatalogDetail(
            item = enriched,
            cast = castFrom(people, castLimit),
            related = related?.let { fromMedia(it, item.kind) }.orEmpty(),
        )
    }

    private suspend fun <R> withoutFailure(request: String, item: CatalogItem, block: suspend () -> R): R? = try {
        block()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "Trakt: catalog $request load failed for ${item.identityKey}" }
        null
    }

    override suspend fun fetchWatchlistKeyPage(page: Int, limit: Int): WatchlistKeyPage {
        val result = client.getWatchlist(page, limit)
        val groups = result.items.mapNotNull { entry ->
            val media = entry.media ?: return@mapNotNull null
            val kind = entryKind(entry, null) ?: return@mapNotNull null
            if (!media.ids.hasAny) return@mapNotNull null
            membershipKeysFor(kind, idsFor(media.ids))
        }
        return WatchlistKeyPage(groups, result.hasMore)
    }

    override suspend fun performWatchlistMutation(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        val body = buildJsonObject {
            val traktIds = TraktIds(trakt = ids.trakt, slug = ids.slug, imdb = ids.imdb, tmdb = ids.tmdb, tvdb = ids.tvdb)
            put(if (kind == MediaKind.SHOW) "shows" else "movies", JsonArray(listOf(buildJsonObject { put("ids", traktIds.toJson()) })))
        }
        if (add) client.addToWatchlist(body) else client.removeFromWatchlist(body)
    }

    override fun dispose() = disposeWatchlistMachinery()

    private fun fromEntries(entries: List<TraktCatalogEntry>, fixed: MediaKind?): List<CatalogItem> = entries.mapNotNull { entry ->
        val media = entry.media ?: return@mapNotNull null
        val kind = entryKind(entry, fixed) ?: return@mapNotNull null
        if (!media.ids.hasAny) return@mapNotNull null
        toCatalogItem(media, kind, watchers = entry.watchers, addedAt = entry.listedAt)
    }

    private fun fromMedia(media: List<TraktCatalogMedia>, kind: MediaKind): List<CatalogItem> =
        media.filter { it.ids.hasAny }.map { toCatalogItem(it, kind) }

    private fun toCatalogItem(media: TraktCatalogMedia, kind: MediaKind, watchers: Int? = null, addedAt: String? = null): CatalogItem {
        val audience = CatalogAudience(watchingNow = watchers, comments = media.commentCount)
        val broadcast = CatalogBroadcast(weekday = weekdayFor(media.airs?.day), time = broadcastTime(media.airs?.time), timezone = media.airs?.timezone)
        return CatalogItem(
            source = CatalogSourceId.TRAKT,
            kind = kind,
            title = media.title ?: "",
            ids = idsFor(media.ids),
            year = media.year,
            overview = media.overview,
            runtimeMinutes = media.runtime,
            rating = media.rating,
            votes = media.votes,
            genres = media.genres,
            certification = media.certification,
            trailerUrl = media.trailer,
            airStatus = airStatusFor(media.status),
            episodeCount = media.airedEpisodes,
            network = media.network,
            posterUrl = media.images?.primaryPoster,
            backdropUrl = media.images?.primaryBackdrop,
            logoUrl = media.images?.primaryLogo,
            audience = audience.takeUnless { it.isEmpty },
            broadcast = broadcast.takeUnless { it.isEmpty },
            releaseDate = parseCatalogInstant(media.released ?: media.firstAired),
            addedAt = parseCatalogInstant(addedAt),
            originalTitle = media.originalTitle,
            tagline = media.tagline,
            countries = media.country?.takeIf { it.isNotEmpty() }?.let { listOf(CountryCodes.normalizeCode(it)) },
            languages = languagesFor(media),
            recommenders = recommendersFor(media),
        )
    }

    internal companion object {
        private const val TAG = "catalog"

        /** Normalised Trakt status; a movie's `released` maps to null, since a "Released" chip on every movie is noise. */
        fun airStatusFor(status: String?): CatalogAirStatus? = when (status) {
            "returning series", "continuing" -> CatalogAirStatus.AIRING
            "ended" -> CatalogAirStatus.ENDED
            "canceled" -> CatalogAirStatus.CANCELED
            "in production", "post production", "planned", "upcoming", "pilot", "rumored" -> CatalogAirStatus.UPCOMING
            else -> null
        }

        /** ISO weekday (Monday = 1) of a Trakt day name. */
        fun weekdayFor(day: String?): Int? = when (day?.lowercase()) {
            "monday" -> 1
            "tuesday" -> 2
            "wednesday" -> 3
            "thursday" -> 4
            "friday" -> 5
            "saturday" -> 6
            "sunday" -> 7
            else -> null
        }

        /** `HH:mm` from Trakt's `airs.time`; null unless it starts with a valid 24-hour time. */
        private fun broadcastTime(time: String?): String? {
            if (time == null || time.length < 5 || time[2] != ':') return null
            val hour = time.substring(0, 2).toIntOrNull()
            val minute = time.substring(3, 5).toIntOrNull()
            if (hour == null || hour !in 0..23 || minute == null || minute !in 0..59) return null
            return time.substring(0, 5)
        }

        /**
         * Watchlist and search entries carry a `type` (seasons and episodes are not Explore rows); trending entries are
         * typed by their wrapper key; fixed-kind endpoints pass [fixed].
         */
        private fun entryKind(entry: TraktCatalogEntry, fixed: MediaKind?): MediaKind? = fixed ?: when (entry.type) {
            "movie" -> MediaKind.MOVIE
            "show" -> MediaKind.SHOW
            null -> if (entry.isShow) MediaKind.SHOW else MediaKind.MOVIE
            else -> null
        }

        private fun idsFor(ids: TraktIds) = CatalogItemIds(trakt = ids.trakt, slug = ids.slug, imdb = ids.imdb, tmdb = ids.tmdb, tvdb = ids.tvdb)

        /** The original language first, then spoken languages and translations, lower-cased without repeats. */
        private fun languagesFor(media: TraktCatalogMedia): List<String>? {
            val languages = LinkedHashSet<String>()
            media.language?.takeIf { it.isNotEmpty() }?.let { languages += it.lowercase() }
            media.languages.orEmpty().filter { it.isNotEmpty() }.mapTo(languages) { it.lowercase() }
            media.availableTranslations.orEmpty().filter { it.isNotEmpty() }.mapTo(languages) { it.lowercase() }
            return languages.toList().ifEmpty { null }
        }

        private fun recommendersFor(media: TraktCatalogMedia): List<CatalogRecommender>? {
            fun from(users: List<TraktRecommendationUser>?, reason: CatalogRecommendationReason) = users.orEmpty().mapNotNull { user ->
                val username = user.username?.takeIf { it.isNotEmpty() } ?: return@mapNotNull null
                CatalogRecommender(username = username, reason = reason, name = user.name, note = user.notes)
            }
            return (from(media.favoritedBy, CatalogRecommendationReason.FAVORITED) + from(media.recommendedBy, CatalogRecommendationReason.RECOMMENDED))
                .ifEmpty { null }
        }

        /** Regular cast first, then guest stars (which can run long), at most [limit] together. */
        private fun castFrom(people: TraktPeople?, limit: Int): List<CatalogCastMember> {
            if (people == null || limit <= 0) return emptyList()
            return (people.cast.asSequence() + people.guestStars.asSequence())
                .mapNotNull { entry ->
                    val name = entry.person?.name?.takeIf { it.isNotEmpty() } ?: return@mapNotNull null
                    CatalogCastMember(name = name, secondary = castSecondary(entry), imageUrl = entry.person?.primaryHeadshot)
                }
                .take(limit)
                .toList()
        }

        /** "Walter White, Heisenberg · 62 eps". */
        private fun castSecondary(entry: TraktCastEntry): String? {
            val characters = entry.characters.orEmpty().filter { it.isNotEmpty() }.joinToString(", ")
            val parts = listOfNotNull(
                characters.takeIf { it.isNotEmpty() },
                entry.episodeCount?.let { T.explore.badge.episodesShort(it.toString()) },
            )
            return parts.joinToString(" · ").ifEmpty { null }
        }

        /** Directors, writers and producers in that order, each person once per role. */
        private fun creditsFrom(crew: List<TraktCastEntry>): List<CatalogCredit> {
            val credits = ArrayList<CatalogCredit>()
            val seen = HashSet<String>()
            for (role in listOf(CatalogCreditRole.DIRECTOR, CatalogCreditRole.WRITER, CatalogCreditRole.PRODUCER)) {
                for (entry in crew) {
                    val name = entry.person?.name?.takeIf { it.isNotEmpty() } ?: continue
                    if (!hasCreditRole(entry, role)) continue
                    if (seen.add("${role.id}/${name.lowercase()}")) credits += CatalogCredit(name, role)
                }
            }
            return credits
        }

        private fun hasCreditRole(entry: TraktCastEntry, role: CatalogCreditRole): Boolean {
            val jobs = (listOfNotNull(entry.job) + entry.jobs.orEmpty()).map { it.lowercase() }
            return when (role) {
                CatalogCreditRole.DIRECTOR -> jobs.any { it == "director" || it == "co-director" }
                CatalogCreditRole.WRITER -> jobs.any { it in WRITER_JOBS }
                CatalogCreditRole.PRODUCER -> jobs.any { it == "producer" || it.endsWith(" producer") }
                CatalogCreditRole.CREATOR, CatalogCreditRole.COMPOSER -> false
            }
        }

        private val WRITER_JOBS = setOf("writer", "screenplay", "story", "teleplay")
    }
}
