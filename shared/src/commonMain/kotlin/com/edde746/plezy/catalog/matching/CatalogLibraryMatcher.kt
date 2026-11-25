package com.edde746.plezy.catalog.matching

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.stripSeasonSuffix
import com.edde746.plezy.catalog.titleMatchCandidates
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.compareLibraryCopies
import com.edde746.plezy.model.mergeLibraryCopy
import com.edde746.plezy.servers.DataAggregationService
import com.edde746.plezy.servers.LibraryLookupResult
import com.edde746.plezy.servers.MultiServerState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/** One reverse-lookup wave: what [CatalogLibraryMatcher] asks of the servers in [serverIds]. */
data class LibraryCopyQuery(
    val ids: ExternalIds,
    val kind: MediaKind,
    val serverIds: Set<ServerId>,
    val titles: List<String>,
    val year: Int?,
    val plexGuid: String?,
    val season: ExternalSeasonRef?,
)

/** Runs one reverse-lookup wave; in the app, [DataAggregationService.findByExternalIdsAcrossServers]. */
fun interface LibraryCopyLookup {
    suspend fun find(query: LibraryCopyQuery): LibraryLookupResult
}

/** This service's cross-server external-id lookup as a [LibraryCopyLookup]. */
fun DataAggregationService.libraryCopyLookup(): LibraryCopyLookup = LibraryCopyLookup { query ->
    findByExternalIdsAcrossServers(query.ids, query.kind, query.serverIds, query.titles, query.year, query.plexGuid, query.season)
}

/**
 * Matches external catalog items back to the user's libraries: one reverse-lookup wave per [match] over the active
 * profile's expected servers ([servers]' [MultiServerState.expectedServerIds], offline ones included), memoized per
 * server for the session. A server's copies are replaced only by that server's own answer.
 *
 * A wave every expected server answered is kept for the session when it found copies: library membership rarely
 * shrinks mid-session. A miss expires after [NEGATIVE_TTL] so newly added media is picked up, and so does any wave a
 * server sat out: a server that failed, was cancelled, or was never asked because it is offline is no evidence of
 * absence, and the next match after [NEGATIVE_TTL] asks it again while its last-known copies stay in the answer.
 *
 * One matcher per profile session. Every change of the expected servers invalidates the cached waves at once and
 * drops copies of servers that left; a change while a wave is in flight discards that wave and runs the lookup again.
 * [scope] follows [servers] until [dispose].
 */
class CatalogLibraryMatcher(
    private val lookup: LibraryCopyLookup,
    private val servers: StateFlow<MultiServerState>,
    scope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    /**
     * Last-known copies keyed by [MediaItem.serverId], alongside the wave they assemble into. [at] stamps the newest
     * wave for [NEGATIVE_TTL].
     */
    private class Entry(
        val at: TimeMark,
        val scopeGeneration: Int,
        val byServer: MutableMap<String?, MutableList<MediaItem>>,
        val result: LibraryLookupResult,
    )

    private val lock = Mutex()
    private val cache = HashMap<String, Entry>()
    private var serverIds: Set<ServerId> = emptySet()
    private var scopeGeneration = 0

    private val scopeJob: Job = scope.launch(start = CoroutineStart.UNDISPATCHED) {
        servers.collect { state -> lock.withLock { syncServerScope(state.expectedServerIds.toSet()) } }
    }

    /** The servers a lookup asks now: the active profile's expected servers. */
    val expectedServerIds: Set<ServerId> get() = servers.value.expectedServerIds.toSet()

    /** Stops following the expected servers. */
    fun dispose() {
        scopeJob.cancel()
    }

    /** Every verified copy of [item] on the expected servers, best first, with each server's part in the wave. */
    suspend fun match(item: CatalogItem): LibraryLookupResult {
        val titles = lookupTitles(item)
        // Not `identityKey`: its canonical series ids make every MAL/AniList season collide (all five Mushoku Tensei
        // entries share one IMDb id), so the first season-gated answer would poison the rest. Namespaced by source too:
        // MAL and AniList can share a MAL id while carrying different titles. The id forms and title candidates join
        // the key because a detail load can enrich an item with ids or titles its row form lacked (a Plex row carries
        // only a rating key); the richer lookup must not be answered by the poorer form's cached miss.
        val key = "${item.source.id}/${item.entryIdentityKey}/${item.ids.allKeys.joinToString(",")}/${titles.joinToString("\u0000")}"
        val (generation, queried, cached) = lock.withLock {
            syncServerScope(expectedServerIds)
            val known = cache[key]
            if (known != null && known.scopeGeneration == scopeGeneration &&
                (isAuthoritativeHit(known.result) || known.at.elapsedNow() < NEGATIVE_TTL)
            ) {
                return known.result
            }
            Triple(scopeGeneration, serverIds, known)
        }

        // A sequel entry's year is its own season's, not the parent show's, so a ±1 window around it excludes the very
        // show looked for. Not every entry has a mapped season; a strippable season suffix says "sequel" as reliably.
        val isSequel = item.season?.isSequel == true || stripSeasonSuffix(item.title) != null
        val result = lookup.find(
            LibraryCopyQuery(
                ids = item.ids.toExternalIds(),
                kind = item.kind,
                serverIds = queried,
                titles = titles,
                year = if (isSequel) null else item.year,
                plexGuid = plexGuidFor(item),
                season = item.season,
            ),
        )
        val entry = lock.withLock {
            // An expected-server change while the wave was in flight invalidates the wave too.
            syncServerScope(expectedServerIds)
            if (generation != scopeGeneration) return@withLock null
            fold(cached?.byServer, result).also { cache[key] = it }
        }
        return entry?.result ?: match(item)
    }

    /** Called under [lock]. */
    private fun syncServerScope(expected: Set<ServerId>) {
        if (expected == serverIds) return
        serverIds = expected
        scopeGeneration++
        val kept = expected.mapTo(HashSet<String?>()) { it.value }
        for (entry in cache.values) entry.byServer.keys.retainAll { it in kept }
    }

    /**
     * A wave folded into the last-known per-server copies. Only a server that answered replaces its own copies; one
     * that failed, was cancelled or wasn't queried keeps them (a timeout, a client abort and an offline server are no
     * evidence of removal), and its outcome set passes through, so the caller still names it unchecked and the wave is
     * retried after [NEGATIVE_TTL]. A server in none of the four sets has left the account and loses its copies.
     *
     * Each copy a server returns again is folded onto its predecessor by [mergeLibraryCopy]: the library stamp is
     * best-effort, and a retry that lost it must not replace a labelled copy with an unlabelled one for the session.
     * Called under [lock].
     */
    private fun fold(previous: Map<String?, MutableList<MediaItem>>?, result: LibraryLookupResult): Entry {
        fun sawNoAnswerFrom(serverId: String?): Boolean {
            val id = ServerId.tryParse(serverId) ?: return false
            return id in result.failedServerIds || id in result.cancelledServerIds || id in result.unqueriedServerIds
        }
        val byServer = LinkedHashMap<String?, MutableList<MediaItem>>()
        // The copies of servers that just answered, about to be replaced by what they returned this time.
        val replaced = HashMap<String, MediaItem>()
        previous?.forEach { (serverId, copies) ->
            if (sawNoAnswerFrom(serverId)) {
                byServer[serverId] = copies
            } else {
                for (copy in copies) replaced[copy.globalKey] = copy
            }
        }
        for (copy in result.items) {
            val prior = replaced[copy.globalKey]
            byServer.getOrPut(copy.serverId) { ArrayList() }.add(if (prior == null) copy else mergeLibraryCopy(prior, copy))
        }
        // Carried and merged copies aren't in the wave's items, so a wave with a predecessor is rebuilt around them; a
        // first wave already is the whole answer.
        return Entry(
            at = timeSource.markNow(),
            scopeGeneration = scopeGeneration,
            byServer = byServer,
            result = if (previous == null) {
                result
            } else {
                result.copy(items = byServer.values.flatten().sortedWith(Comparator(::compareLibraryCopies)))
            },
        )
    }

    companion object {
        /** How long a miss, or a wave a server sat out, answers before the servers are asked again. */
        val NEGATIVE_TTL: Duration = 10.minutes

        /**
         * The title candidates a lookup for [item] spends its title-search budget on: the source's original title,
         * then its display title and aliases, each followed by its season-stripped form, at most four. Later families
         * are best-effort and may not fit.
         */
        fun lookupTitles(item: CatalogItem): List<String> = titleMatchCandidates(listOf(item.originalTitle, item.title) + item.altTitles)

        /**
         * Whether [detail], the detail load of [opening], widens its lookup: id forms or title candidates [opening]
         * lacked (a Plex row carries only its rating key; a detail body brings the native title). A detail screen then
         * matches again and unions the copies with those already shown.
         */
        fun widensLookup(opening: CatalogItem, detail: CatalogItem): Boolean =
            !opening.ids.allKeys.toSet().containsAll(detail.ids.allKeys) ||
                !lookupTitles(opening).toSet().containsAll(lookupTitles(detail))

        /**
         * Whether [result] may answer for the rest of the session: copies found with every expected server taking part.
         * A wave a server sat out (failed, cancelled, never asked) is incomplete and expires with [NEGATIVE_TTL].
         */
        private fun isAuthoritativeHit(result: LibraryLookupResult): Boolean =
            result.items.isNotEmpty() &&
                result.failedServerIds.isEmpty() &&
                result.cancelledServerIds.isEmpty() &&
                result.unqueriedServerIds.isEmpty()

        /**
         * The exact `plex://` guid of a Plex Discover item, which its rating key already names: no request needed.
         * Other sources get null; a Plex rating key another source carries is no Discover guid.
         */
        private fun plexGuidFor(item: CatalogItem): String? {
            val plexId = item.ids.plex
            if (item.source != CatalogSourceId.PLEX || plexId.isNullOrEmpty()) return null
            return "plex://${if (item.kind == MediaKind.MOVIE) "movie" else "show"}/$plexId"
        }
    }
}

/** The servers [this] wave says nothing about (failed, cancelled, or not asked): a detail screen names them unchecked. */
val LibraryLookupResult.uncheckedServerIds: Set<ServerId>
    get() = failedServerIds + cancelledServerIds + unqueriedServerIds
