package com.edde746.plezy.watch

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.TitleQuery
import com.edde746.plezy.servers.LibraryLookupResult
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import party.openwatch.Candidate
import party.openwatch.Media
import party.openwatch.MediaKind
import party.openwatch.Resolver
import com.edde746.plezy.model.MediaKind as ItemKind

/**
 * Thrown when no copy was found and some server couldn't be asked: the SDK reports it as `ResolveFailed`, and searching
 * again may still find one.
 */
class LibraryLookupIncomplete(val failedServerIds: Set<ServerId>) : Exception("Library lookup incomplete: $failedServerIds")

/**
 * Finds this user's own copies of another participant's media: every playable version of every copy is a candidate,
 * with its length so the SDK can match it by duration.
 *
 * 1. The `app.plezy` shortcut: when the descriptor names a server this profile reaches ([clientFor]), that item's
 *    versions come first, the shared version leading.
 * 2. Movies and episodes by catalogue identity on every server ([findCopies], 20 s per server): ids first, the title
 *    only when no id matched; episodes through their show and numbers.
 *
 * A `video` has no catalogue identity, so only the shortcut finds it. Cancelling the call (the SDK does when the room's
 * media changes) cancels the search.
 */
internal class RoomTitleResolver(
    private val clientFor: (serverId: String) -> MediaBackend?,
    private val findCopies: suspend (TitleQuery) -> LibraryLookupResult,
) : Resolver<WatchCopy> {
    override suspend fun resolve(media: Media): List<Candidate<WatchCopy>> {
        val candidates = mutableListOf<Candidate<WatchCopy>>()
        val seen = mutableSetOf<WatchCopy>()
        fun addItem(item: MediaItem, firstVersionId: String? = null) {
            if (item.serverId == null || !kindMatches(media.kind, item.kind)) return
            val versions = item.mediaVersions.orEmpty().filter { it.isPlayable }.toMutableList()
            if (firstVersionId != null) {
                val first = versions.indexOfFirst { it.id == firstVersionId }
                if (first > 0) versions.add(0, versions.removeAt(first))
            }
            for (version in versions.ifEmpty { listOf(null) }) {
                val candidate = candidateFor(item, version, clientFor)
                if (seen.add(candidate.ref)) candidates += candidate
            }
        }

        val ref = MediaDescriptor.plezyRef(media)
        val refClient = ref?.let { clientFor(it.server) }
        if (ref != null && refClient != null) {
            try {
                refClient.fetchItem(ref.item)?.let { addItem(it, ref.version) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Shared item is not readable on ${ref.server}" }
            }
            currentCoroutineContext().ensureActive()
        }

        val query = titleQueryFor(media) ?: return candidates
        val result = findCopies(query)
        currentCoroutineContext().ensureActive()
        result.items.forEach { addItem(it) }
        if (candidates.isEmpty() && result.failedServerIds.isNotEmpty()) throw LibraryLookupIncomplete(result.failedServerIds)
        return candidates
    }

    private companion object {
        const val TAG = "WatchTogether"
    }
}

private fun kindMatches(kind: MediaKind, itemKind: ItemKind): Boolean = when (kind) {
    MediaKind.MOVIE -> itemKind == ItemKind.MOVIE
    MediaKind.EPISODE -> itemKind == ItemKind.EPISODE
    MediaKind.VIDEO -> itemKind.isVideo
}

/**
 * The candidate for [version] of [item] (which must carry its server): id `server:item:version`, its length when the
 * server knows it, else a probe that reads the item again for it (when [clientFor] has the server); its total size when
 * every part has one, its file name when it is one file.
 */
internal fun candidateFor(item: MediaItem, version: MediaVersion?, clientFor: ((String) -> MediaBackend?)? = null): Candidate<WatchCopy> {
    val copy = WatchCopy.of(item, version)
    val parts = version?.parts.orEmpty()
    val durationMs = copy.durationMs
    val client = clientFor?.invoke(copy.serverId)
    return Candidate(
        id = "${copy.serverId}:${copy.itemId}:${copy.versionId}",
        ref = copy,
        durationMs = durationMs,
        sizeBytes = if (parts.isNotEmpty() && parts.all { it.sizeBytes != null }) parts.sumOf { it.sizeBytes!! } else null,
        name = if (parts.size == 1) MediaDescriptor.fileBaseName(parts.single().file) else null,
        probe = if (durationMs != null || client == null) {
            null
        } else {
            suspend {
                client.fetchItem(item.id)?.let { fresh ->
                    val versions = fresh.mediaVersions.orEmpty()
                    val match = versions.firstOrNull { it.id == copy.versionId } ?: versions.singleOrNull()
                    versionDurationMs(fresh, match)
                }
            }
        },
    )
}

/** What to look for: a movie by its ids and title, an episode by its show and numbers. Null for a `video`, and for an episode without its numbers. */
internal fun titleQueryFor(media: Media): TitleQuery? = when (media.kind) {
    MediaKind.MOVIE -> TitleQuery.movie(
        title = media.title,
        year = media.year?.toInt(),
        ids = externalIdsOf(media.ids),
        plexGuid = plexGuidOf(media.ids),
    )
    MediaKind.EPISODE -> {
        val series = media.series
        val season = media.season
        val episode = media.episode
        if (series == null || season == null || episode == null) {
            null
        } else {
            TitleQuery.episode(
                showTitle = series.title,
                season = season.toInt(),
                episode = episode.toInt(),
                showYear = series.year?.toInt(),
                showIds = externalIdsOf(series.ids),
                showPlexGuid = plexGuidOf(series.ids),
                ids = externalIdsOf(media.ids),
                title = media.title,
            )
        }
    }
    MediaKind.VIDEO -> null
}

private val IMDB_ID = Regex("^tt[0-9]{1,12}$")
private val NUMERIC_ID = Regex("^[0-9]{1,12}$")
private val PLEX_GUID = Regex("^plex://(movie|show|season|episode)/[A-Za-z0-9]{1,64}$")

/** The descriptor's [ids] Plezy can search by. Untrusted: only well-formed ids pass, and they are only search terms. */
internal fun externalIdsOf(ids: Map<String, String>): ExternalIds {
    fun number(value: String?) = value?.takeIf { NUMERIC_ID.matches(it) }?.toIntOrNull()
    return ExternalIds(
        imdb = ids["imdb"]?.takeIf { IMDB_ID.matches(it) },
        tmdb = number(ids["tmdb"]),
        tvdb = number(ids["tvdb"]),
        anidb = number(ids["anidb"]),
    )
}

private fun plexGuidOf(ids: Map<String, String>): String? = ids["plex"]?.takeIf { PLEX_GUID.matches(it) }
