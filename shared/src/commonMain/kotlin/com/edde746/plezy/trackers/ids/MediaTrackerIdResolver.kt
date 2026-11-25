package com.edde746.plezy.trackers.ids

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.ResolvedIds
import com.edde746.plezy.trackers.TrackerIdResolver
import com.edde746.plezy.trackers.TrackerIdResolverFactory
import com.edde746.plezy.trackers.client.KeyedLoads
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

/** The resolvers of the app's media servers, all over [mappings]. */
internal fun mediaTrackerIdResolvers(mappings: AnimeMappings): TrackerIdResolverFactory =
    TrackerIdResolverFactory { backend, needsAnimeIds -> MediaTrackerIdResolver(backend, needsAnimeIds, mappings, mappings) }

/**
 * Resolves one media server's items to tracker ids: the server's external ids (an episode's are its show's, which is
 * what the mapping datasets know), and, while [needsAnimeIds] says a tracker wants them, the anime-list ids of the
 * Fribb row they map to, with the progress the anime list entry should show.
 *
 * Fribb maps show-level ids, so a split-cour show has several rows; Anime-Lists' episode mappings name the AniDB
 * entry an aired episode belongs to, and Fribb's seasons the rest. A HAMA-matched Plex library supplies an AniDB id
 * alone: Fribb's own key, so it names its row outright, but only where HAMA's plain `anidb` mode numbers the entry
 * (season 1, or no season); a later season means the library is numbered by TVDB and the catalog ids decide.
 *
 * Answers (`null` too) are cached per movie, per aired episode (`{showId}#s{season}#e{episode}`: same-season split
 * cours map different episodes to different entries) and per rating target, and the server's external ids per item,
 * until [clearCache]. Anime progress is read anew each time.
 */
internal class MediaTrackerIdResolver(
    private val backend: MediaBackend,
    private val needsAnimeIds: () -> Boolean,
    private val fribb: FribbLookup,
    private val animeLists: AnimeListsLookup,
    private val animeProgress: AnimeEpisodeProgressLookup = AnimeEpisodeProgressResolver(backend),
) : TrackerIdResolver {
    private val cache = MutableStateFlow<Map<String, Resolution?>>(emptyMap())
    private val externalIdLoads = KeyedLoads<String, ExternalIds>(memoize = true)

    /** What the ids say about an item before its anime progress is read. */
    private class Resolution(
        val ids: ExternalIds,
        val anime: AnimeIds?,
        val scope: AnimeProgressScope? = null,
        val match: AnimeEpisodeMatch? = null,
    )

    override suspend fun resolveForMovie(movie: MediaItem): ResolvedIds? {
        val resolution = cached(movie.id) { build(externalIds(movie.id), season = null, episode = null, isMovie = true) }
        return resolution?.let { ResolvedIds(it.ids, it.anime) }
    }

    override suspend fun resolveForEpisode(episode: MediaItem, includeCurrentEpisode: Boolean): ResolvedIds? =
        resolveEpisode(episode, includeAnimeProgress = true, includeCurrentEpisode = includeCurrentEpisode)

    override suspend fun resolveForRating(item: MediaItem): RatingTarget? = when (item.kind) {
        MediaKind.MOVIE -> resolveForMovie(item)?.let { RatingTarget(RatingKind.MOVIE, it.ids, it.anime) }
        MediaKind.SHOW -> showRating(item.id, season = null)?.let { RatingTarget(RatingKind.SHOW, it.ids, it.anime) }
        MediaKind.SEASON -> {
            val showId = item.parentId?.takeIf { it.isNotEmpty() }
            val season = item.index ?: item.parentIndex
            if (showId == null || season == null) {
                null
            } else {
                showRating(showId, season)?.let { RatingTarget(RatingKind.SEASON, it.ids, it.anime, season = season) }
            }
        }
        MediaKind.EPISODE -> {
            val season = item.parentIndex
            val number = item.index
            if (season == null || number == null) {
                null
            } else {
                resolveEpisode(item, includeAnimeProgress = false, includeCurrentEpisode = true)
                    ?.let { RatingTarget(RatingKind.EPISODE, it.ids, it.anime, season = season, episode = number) }
            }
        }
        else -> null
    }

    override fun clearCache() {
        cache.value = emptyMap()
        externalIdLoads.clear()
        animeProgress.clearCache()
    }

    private suspend fun resolveEpisode(episode: MediaItem, includeAnimeProgress: Boolean, includeCurrentEpisode: Boolean): ResolvedIds? {
        val showId = episode.grandparentId?.takeIf { it.isNotEmpty() } ?: return null
        val season = episode.parentIndex
        val number = episode.index
        val key = if (season != null && number != null) "$showId#s$season#e$number" else showId
        val resolution = cached(key) { build(externalIds(showId), season, number, isMovie = false) } ?: return null
        val progress = resolution.scope?.takeIf { includeAnimeProgress }?.let { scope ->
            val match = resolution.match
            animeProgress.resolve(
                episode,
                scope,
                animeMatch = match,
                episodeMatcher = match?.let { { other: MediaItem -> episodeMatch(resolution.ids, other.parentIndex, other.index) } },
                includeCurrentEpisode = includeCurrentEpisode,
            )
        }
        return ResolvedIds(resolution.ids, resolution.anime, season = season, episode = number, animeProgress = progress)
    }

    /** The cached resolution of [key], else [build]'s, cached (`null` too). */
    private suspend fun cached(key: String, build: suspend () -> Resolution?): Resolution? {
        cache.value.let { if (key in it) return it[key] }
        val resolution = build()
        cache.update { it + (key to resolution) }
        return resolution
    }

    private suspend fun externalIds(itemId: String): ExternalIds = externalIdLoads.run(itemId) { backend.fetchExternalIds(itemId) }

    private suspend fun build(ids: ExternalIds, season: Int?, episode: Int?, isMovie: Boolean): Resolution? {
        if (!ids.hasAny) return null
        if (!needsAnimeIds()) return withoutAnimeIds(ids)
        val anidb = usableAnidb(ids, if (isMovie) null else season)
        val rows = fribb.lookup(isMovie, anidb, ids.tvdb, ids.tmdb, ids.imdb)
        val match = if (isMovie || season == null || episode == null) null else episodeMatch(ids, season, episode)
        // An AniDB special (season 0 on AniDB) sits beside its entry's regular episodes: written as progress, its
        // number would rewind or complete the series. Trackers that take the episode by its external ids still do.
        if (match != null && match.anidbSeason == 0) return withoutAnimeIds(ids)
        val row = if (isMovie) movieRow(rows) else showRow(rows, season, anidb, match)
        return Resolution(ids, row?.animeIds, progressScope(row, rows, season, isMovie, match), match)
    }

    /**
     * The ids without anime ids: for trackers that never use them, and an episode no anime entry counts. `null` for an
     * AniDB-only item: no tracker without anime ids can address an AniDB id.
     */
    private fun withoutAnimeIds(ids: ExternalIds): Resolution? = if (ids.hasCatalogIds) Resolution(ids, anime = null) else null

    /** The AniDB id when it describes what plays: HAMA's plain `anidb` mode numbers its entry as season 1. */
    private fun usableAnidb(ids: ExternalIds, season: Int?): Int? = ids.anidb?.takeIf { season == null || season == 1 }

    private suspend fun showRating(showId: String, season: Int?): Resolution? {
        if (showId.isEmpty()) return null
        val key = if (season != null) "$showId#rating-s$season" else "$showId#rating"
        return cached(key) {
            val ids = externalIds(showId)
            when {
                !ids.hasAny -> null
                !needsAnimeIds() -> withoutAnimeIds(ids)
                else -> {
                    val anidb = usableAnidb(ids, season)
                    val rows = fribb.lookup(false, anidb, ids.tvdb, ids.tmdb, ids.imdb)
                    val entries = if (season == null) animeIdsForShow(ids) else animeIdsForSeason(ids, season)
                    // One Anime-Lists entry names the row; several are ambiguous; none leaves it to Fribb's seasons.
                    val row = when (entries.size) {
                        1 -> rows.firstOrNull { it.anidb == entries.single() }
                        0 -> showRow(rows, season, anidb, match = null)
                        else -> null
                    }
                    Resolution(ids, row?.animeIds)
                }
            }
        }
    }

    private fun movieRow(rows: List<FribbRow>): FribbRow? =
        // The lookup searched film ids only; some rows are untyped and TMDB lists some OVAs and specials as films.
        rows.firstOrNull { it.isMovie } ?: rows.firstOrNull()

    /**
     * The show row for [season]: the matched episode's entry; else the usable AniDB id's; else the row Fribb maps to
     * [season]. A row mapped to a season describes that season alone, so a season Fribb hasn't mapped yet (a new cour)
     * never lands on another one, which would rewrite a finished entry as a rewatch; a row without a season covers the
     * show in absolute numbering and still applies, but never to specials. Among those, a regular series first, then
     * any but a film.
     */
    private fun showRow(rows: List<FribbRow>, season: Int?, anidb: Int?, match: AnimeEpisodeMatch?): FribbRow? {
        if (rows.isEmpty()) return null
        if (match != null) return rows.firstOrNull { it.anidb == match.anidbId }
        if (anidb != null) rows.firstOrNull { it.anidb == anidb }?.let { return it }
        var candidates = rows
        if (season != null) {
            rows.firstOrNull { it.tvdbSeason == season || it.tmdbSeason == season }?.let { return it }
            if (season <= 0) return null
            candidates = rows.filter { !it.hasSeasonMapping }
            if (candidates.isEmpty()) return null
        }
        return candidates.firstOrNull { it.isRegularSeries } ?: candidates.firstOrNull { !it.isMovie } ?: candidates.first()
    }

    /**
     * Where the selected [row]'s progress comes from: the matched episode's own entry ([AnimeProgressScope.MAPPED]),
     * the exact season a regular row maps ([AnimeProgressScope.SEASON]), or the whole show when it is the show's only
     * regular row ([AnimeProgressScope.SHOW]); otherwise none, and the local episode number stands in.
     */
    private fun progressScope(row: FribbRow?, rows: List<FribbRow>, season: Int?, isMovie: Boolean, match: AnimeEpisodeMatch?): AnimeProgressScope? {
        if (isMovie || season == null || season <= 0 || row == null) return null
        if (match != null && row.anidb == match.anidbId) return AnimeProgressScope.MAPPED
        if (row.hasSeasonMapping) {
            val exact = row.tvdbSeason == season || row.tmdbSeason == season
            return AnimeProgressScope.SEASON.takeIf { exact && row.isRegularSeries }
        }
        return AnimeProgressScope.SHOW.takeIf { rows.filter { it.isRegularSeries }.singleOrNull() == row }
    }

    /** The Anime-Lists match of an aired episode; `null` when there is none or the dataset failed. */
    private suspend fun episodeMatch(ids: ExternalIds, season: Int?, episode: Int?): AnimeEpisodeMatch? {
        if (season == null || episode == null) return null
        return lenient(null) { animeLists.lookupEpisode(ids.tvdb, ids.tmdb, season, episode) }
    }

    private suspend fun animeIdsForShow(ids: ExternalIds): Set<Int> = lenient(emptySet()) { animeLists.animeIdsForShow(ids.tvdb, ids.tmdb) }

    private suspend fun animeIdsForSeason(ids: ExternalIds, season: Int): Set<Int> =
        lenient(emptySet()) { animeLists.animeIdsForSeason(ids.tvdb, ids.tmdb, season) }

    /** An Anime-Lists answer, or [fallback] when the dataset failed: Fribb's rows still name an entry without it. */
    private suspend fun <T> lenient(fallback: T, lookup: suspend () -> T): T = try {
        lookup()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "anime ids: the Anime-Lists lookup failed" }
        fallback
    }

    private companion object {
        const val TAG = "trackers"
    }
}
