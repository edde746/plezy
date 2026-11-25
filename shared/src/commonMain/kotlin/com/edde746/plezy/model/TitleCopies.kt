package com.edde746.plezy.model

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.SeasonEpisodePaging
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlin.math.abs

private const val TAG = "TitleCopies"

/** Title-search hits checked against the query's ids when nothing matched by id. */
private const val TITLE_FALLBACK_LIMIT = 5

/** Hits a title search asks for. */
private const val TITLE_SEARCH_LIMIT = 50

/** Episodes per page when paging a season. */
private const val SEASON_PAGE_SIZE = 200

/**
 * A movie or an episode to find in the user's libraries by catalog identity, as another app describes it. An episode
 * is found through its show (by the show's ids, else its title) and its season and episode numbers.
 */
data class TitleQuery(
    val kind: MediaKind,
    /** The movie's title, or the episode's own (unused for lookups). */
    val title: String,
    val year: Int? = null,
    /** The movie's ids, or the episode's own. */
    val ids: ExternalIds = ExternalIds(),
    val plexGuid: String? = null,
    val showTitle: String? = null,
    val showYear: Int? = null,
    val showIds: ExternalIds = ExternalIds(),
    val showPlexGuid: String? = null,
    val season: Int? = null,
    val episode: Int? = null,
) {
    companion object {
        fun movie(title: String, year: Int? = null, ids: ExternalIds = ExternalIds(), plexGuid: String? = null) =
            TitleQuery(MediaKind.MOVIE, title, year, ids, plexGuid)

        fun episode(
            showTitle: String,
            season: Int,
            episode: Int,
            showYear: Int? = null,
            showIds: ExternalIds = ExternalIds(),
            showPlexGuid: String? = null,
            ids: ExternalIds = ExternalIds(),
            title: String = "",
        ) = TitleQuery(
            kind = MediaKind.EPISODE,
            title = title,
            ids = ids,
            showTitle = showTitle,
            showYear = showYear,
            showIds = showIds,
            showPlexGuid = showPlexGuid,
            season = season,
            episode = episode,
        )
    }
}

/**
 * Every copy of [query] on this server, each with its versions.
 *
 * Movies and shows come from [MediaBackend.findByExternalIds]. Only when that finds nothing does a title search run:
 * same [foldTitle], years at most one apart, and (with query ids) no catalog id contradicting the query's among the
 * first few hits. An episode is then the show's episode with the query's season and episode numbers, dropped when its
 * own ids contradict the query's. Failures throw, so the caller can tell "not on this server" from "couldn't ask".
 */
suspend fun MediaBackend.findTitleCopies(query: TitleQuery): List<MediaItem> {
    val found = if (query.kind == MediaKind.MOVIE) {
        titleItems(MediaKind.MOVIE, query.title, query.year, query.ids, query.plexGuid)
    } else {
        val season = requireNotNull(query.season) { "an episode query needs a season" }
        val episode = requireNotNull(query.episode) { "an episode query needs an episode" }
        val shows = titleItems(MediaKind.SHOW, query.showTitle.orEmpty(), query.showYear, query.showIds, query.showPlexGuid)
        val episodes = mutableListOf<MediaItem>()
        for (show in shows) {
            currentCoroutineContext().ensureActive()
            episodes += episodesOf(show, season, episode)
        }
        if (query.ids.hasAny) withoutContradictions(episodes, query.ids) else episodes
    }
    return withVersions(found)
}

private suspend fun MediaBackend.titleItems(kind: MediaKind, title: String, year: Int?, ids: ExternalIds, plexGuid: String?): List<MediaItem> {
    val wanted = title.trim()
    if (ids.hasAny || plexGuid != null) {
        val byId = findByExternalIds(ids, kind, titles = listOfNotNull(wanted.ifEmpty { null }), year = year, plexGuid = plexGuid)
        currentCoroutineContext().ensureActive()
        if (!byId.isNullOrEmpty()) return byId
    }
    if (wanted.isEmpty()) return emptyList()
    val hits = searchItems(wanted, limit = TITLE_SEARCH_LIMIT)
    currentCoroutineContext().ensureActive()
    val folded = foldTitle(wanted)
    val sameTitle = hits.filter { it.kind == kind && foldTitle(it.title.orEmpty()) == folded && yearsAgree(year, it.year) }
    if (!ids.hasAny) return sameTitle
    return withoutContradictions(sameTitle.take(TITLE_FALLBACK_LIMIT), ids)
}

/** [items] minus those whose catalog ids name another title than [ids]. An item whose ids can't be read stays. */
private suspend fun MediaBackend.withoutContradictions(items: List<MediaItem>, ids: ExternalIds): List<MediaItem> =
    items.filter { item ->
        currentCoroutineContext().ensureActive()
        val own = try {
            fetchExternalIds(item.id)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            if (error is MediaServerHttpException && error.isCancellation) throw error
            Log.w(TAG, error) { "Could not read the external ids of ${item.id}" }
            ExternalIds()
        }
        !contradicts(own, ids)
    }

/** The episodes of [show] numbered [season]x[episode]. A Plex show whose seasons are hidden lists its episodes directly. */
private suspend fun MediaBackend.episodesOf(show: MediaItem, season: Int, episode: Int): List<MediaItem> {
    fun isTarget(item: MediaItem) = item.kind == MediaKind.EPISODE && item.index == episode && (item.parentIndex ?: season) == season
    val children = fetchChildren(show.id)
    currentCoroutineContext().ensureActive()
    val matches = children.filter(::isTarget).toMutableList()
    for (seasonItem in children) {
        if (seasonItem.kind != MediaKind.SEASON || seasonItem.index != season) continue
        matches += seasonEpisodes(show, seasonItem).filter(::isTarget)
        currentCoroutineContext().ensureActive()
    }
    return matches
}

private suspend fun MediaBackend.seasonEpisodes(show: MediaItem, season: MediaItem): List<MediaItem> {
    val paging = this as? SeasonEpisodePaging ?: return fetchChildren(season.id)
    val items = mutableListOf<MediaItem>()
    while (true) {
        val page = paging.fetchSeasonEpisodesPage(show.id, season.id, start = items.size, size = SEASON_PAGE_SIZE)
        items += page.items
        if (page.items.size < SEASON_PAGE_SIZE || items.size >= page.totalCount) return items
    }
}

/** [items] with their versions: rows without them are fetched; a row whose fetch fails stays as it is. */
private suspend fun MediaBackend.withVersions(items: List<MediaItem>): List<MediaItem> = items.map { item ->
    if (!item.mediaVersions.isNullOrEmpty()) return@map item
    currentCoroutineContext().ensureActive()
    try {
        fetchItem(item.id) ?: item
    } catch (error: CancellationException) {
        throw error
    } catch (error: Exception) {
        if (error is MediaServerHttpException && error.isCancellation) throw error
        Log.w(TAG, error) { "Could not read the versions of ${item.id}" }
        item
    }
}

private fun yearsAgree(wanted: Int?, found: Int?): Boolean = wanted == null || found == null || abs(wanted - found) <= 1

private val NON_LETTER_OR_DIGIT = Regex("""[^\p{L}\p{N}]+""")

/** [title] lower-cased with everything but letters and digits removed, so punctuation, spacing and case don't count. */
fun foldTitle(title: String): String = title.lowercase().replace(NON_LETTER_OR_DIGIT, "")

/** Whether a catalog holds different ids in [a] and [b]: then they name different titles whatever else they share. */
fun contradicts(a: ExternalIds, b: ExternalIds): Boolean =
    (a.imdb != null && b.imdb != null && a.imdb != b.imdb) ||
        (a.tmdb != null && b.tmdb != null && a.tmdb != b.tmdb) ||
        (a.tvdb != null && b.tvdb != null && a.tvdb != b.tvdb) ||
        (a.anidb != null && b.anidb != null && a.anidb != b.anidb)
