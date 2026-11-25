package com.edde746.plezy.trackers.ratings

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerIdResolverFactory
import com.edde746.plezy.trackers.TrackerService
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.runningFold
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.ComparableTimeMark
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.TimeSource

/**
 * The community scores the profile's connected trackers have for a title, for the detail pages' ratings.
 *
 * Every connected tracker is asked at once and the answers come in as they arrive: each flow emits the merged scores
 * ([mergeCommunityRatings]) again every time another tracker adds some, emits nothing when none has a score, and
 * completes once every tracker answered. Answers are kept per tracker, kind and ids for [TTL] (the services refresh
 * their scores daily at most), the [CAPACITY] most recently used; a title a tracker doesn't know is kept as such, a
 * failed request is logged, leaves that tracker out and isn't kept, so the next visit asks again. Concurrent asks for
 * the same tracker and title share one request. The scores are public, so a reconnect keeps them.
 */
class TrackerRatings internal constructor(
    private val sources: (profileId: String) -> Flow<List<TrackerRatingsSource>>,
    private val resolvers: TrackerIdResolverFactory,
    private val timeSource: TimeSource.WithComparableMarks,
) {
    private data class Key(val service: TrackerService, val title: RatingTitle)

    private class Entry(val ratings: List<MediaRatingSource>, val at: ComparableTimeMark)

    /** Guards [cache] and [loads]; never held across a request. */
    private val lock = Mutex()

    /** Least recently used first. */
    private val cache = LinkedHashMap<Key, Entry>()
    private val loads = mutableMapOf<Key, CompletableDeferred<List<MediaRatingSource>>>()

    /**
     * The trackers' scores for a library [item] of [backend]: movies and shows only (the trackers score whole titles).
     * Its ids come from the media server, and its anime ids from the mapping datasets while MyAnimeList or AniList is
     * connected, resolved once for every tracker and only when one is connected. Merge them into the item's own with
     * [withCommunityRatings].
     */
    fun forLibraryItem(profileId: String, item: MediaItem, backend: MediaBackend): Flow<List<MediaRatingSource>> {
        if (item.kind != MediaKind.MOVIE && item.kind != MediaKind.SHOW) return emptyFlow()
        val movie = item.kind == MediaKind.MOVIE
        return flow {
            val connected = sources(profileId).first()
            if (connected.isEmpty()) return@flow
            val resolver = resolvers.create(backend) { connected.any { it.needsAnimeIds } }
            val target = try {
                resolver.resolveForRating(item)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "community ratings left out: the item's ids didn't resolve" }
                return@flow
            } ?: return@flow
            val ids = TitleIds.of(target.ids, target.anime)
            emitAll(
                load(connected) { source ->
                    // Titles outside an anime list aren't asked of it.
                    if (source.needsAnimeIds && ids.mal == null && ids.anilist == null) null else RatingTitle(movie, ids)
                },
            )
        }
    }

    /**
     * The trackers' scores for a catalog title (Explore's detail page) of [kind] known by [ids]: movies and shows only.
     * A tracker with a score of its own ([ownService], the provider the item comes from) isn't asked about its own items,
     * whose detail already shows that score, and another tracker's copy of it (MDBList's Trakt score on a Trakt item) is
     * dropped; MDBList, which has none, is asked about its own items too. [resolveIds] adds what a tracker's catalog
     * knows the title by (`null`: nothing more); a tracker that can't place it still gets [ids].
     */
    fun forCatalogTitle(
        profileId: String,
        kind: MediaKind,
        ids: TitleIds,
        ownService: TrackerService?,
        resolveIds: suspend (TrackerService) -> TitleIds? = { null },
    ): Flow<List<MediaRatingSource>> {
        if (kind != MediaKind.MOVIE && kind != MediaKind.SHOW) return emptyFlow()
        val movie = kind == MediaKind.MOVIE
        val ownKey = ownService?.let(::communityRatingKey)
        return flow {
            val connected = sources(profileId).first().filter { ownKey == null || it.service != ownService }
            emitAll(load(connected) { source -> RatingTitle(movie, ids.mergedWith(resolveIds(source.service) ?: TitleIds())) })
        }.map { ratings -> ratings.filter { it.source != ownKey } }
    }

    /**
     * The merged scores of [sources] for the title [titleFor] names in each one's ids; `null` (or no id at all) leaves
     * that tracker out.
     */
    internal fun load(
        sources: List<TrackerRatingsSource>,
        titleFor: suspend (TrackerRatingsSource) -> RatingTitle?,
    ): Flow<List<MediaRatingSource>> = channelFlow {
        for (source in sources) {
            launch {
                val ratings = answer(source, titleFor)
                if (ratings.isNotEmpty()) send(RatingsAnswer(source.service, ratings))
            }
        }
    }.runningFold(emptyList<RatingsAnswer>()) { answers, answer -> answers + answer }.drop(1).map(::mergeCommunityRatings)

    private suspend fun answer(source: TrackerRatingsSource, titleFor: suspend (TrackerRatingsSource) -> RatingTitle?): List<MediaRatingSource> =
        try {
            val title = titleFor(source)
            if (title == null || !title.ids.hasAny) emptyList() else cached(source, title)
        } catch (e: CancellationException) {
            throw e
        } catch (e: TrackerException) {
            Log.i(TAG) { "community ratings from ${source.service.id} left out: ${e.message}" }
            emptyList()
        } catch (e: Exception) {
            Log.w(TAG, e) { "community ratings from ${source.service.id} left out" }
            emptyList()
        }

    private suspend fun cached(source: TrackerRatingsSource, title: RatingTitle): List<MediaRatingSource> {
        val key = Key(source.service, title)
        while (true) {
            var running: CompletableDeferred<List<MediaRatingSource>>? = null
            val own = CompletableDeferred<List<MediaRatingSource>>()
            lock.withLock {
                cache.remove(key)?.let { entry ->
                    if (entry.at.elapsedNow() < TTL) {
                        cache[key] = entry
                        return entry.ratings
                    }
                }
                running = loads[key]
                if (running == null) loads[key] = own
            }
            val shared = running
            if (shared != null) {
                try {
                    return shared.await()
                } catch (e: CancellationException) {
                    // The load this ask joined was cancelled with its caller: ask again, unless this one was cancelled too.
                    currentCoroutineContext().ensureActive()
                    continue
                }
            }
            try {
                val ratings = source.ratings(title)
                lock.withLock {
                    loads.remove(key)
                    cache[key] = Entry(ratings, timeSource.markNow())
                    while (cache.size > CAPACITY) cache.remove(cache.keys.first())
                }
                own.complete(ratings)
                return ratings
            } catch (e: Throwable) {
                lock.withLock { loads.remove(key) }
                if (e is CancellationException) own.cancel(e) else own.completeExceptionally(e)
                throw e
            }
        }
    }

    internal companion object {
        private const val TAG = "trackers"
        val TTL: Duration = 12.hours
        const val CAPACITY = 300
    }
}
