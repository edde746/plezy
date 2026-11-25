package com.edde746.plezy.playback.queue

import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LocalPlayQueue
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.playback.session.QueueEntry
import com.edde746.plezy.plex.PlexClientEnvironment
import com.edde746.plezy.plex.TEST_SERVER_ID
import com.edde746.plezy.plex.jsonResponse
import com.edde746.plezy.plex.testPlexClient
import com.edde746.plezy.servers.OnlineServers
import com.edde746.plezy.servers.PlaybackStateStore
import com.edde746.plezy.servers.QueueNavigationStatus
import com.edde746.plezy.servers.ServerPlayQueue
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.runTest

class EpisodeQueueTest {
    private val playback = PlaybackStateStore()

    private fun queue(vararg clients: MediaBackend) = EpisodeQueue(playback, FakeServers(*clients))

    // Adjacency (the online path).

    @Test
    fun returnsUnavailableWhenNoPlayQueueIsActiveForAStandaloneMovie() = runTest {
        val result = queue().loadAdjacent(jfMovie("42"))

        assertEquals(QueueNavigationStatus.UNAVAILABLE, result.nextStatus)
        assertEquals(QueueNavigationStatus.UNAVAILABLE, result.previousStatus)
        assertNull(result.next)
        assertNull(result.previous)
        assertFalse(playback.isQueueActive)
    }

    @Test
    fun preservesAdjacencyForAMovieInAnActiveLocalQueue() = runTest {
        val previous = jfMovie("movie-1")
        val current = jfMovie("movie-2")
        val next = jfMovie("movie-3")
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(previous, current, next), currentIndex = 1), contextKey = "playlist-movies")
        val client = SeriesBackend()

        val result = queue(client).loadAdjacent(current)

        assertTrue(client.seriesQueueCalls.isEmpty())
        assertTrue(playback.isQueueActive)
        assertEquals("playlist-movies", playback.shuffleContextKey)
        assertSame(current, playback.currentQueueItem)
        assertEquals(1, playback.currentPlayQueueItemId)
        assertEquals(listOf(previous, current, next), playback.loadedItems)
        assertEquals(QueueNavigationStatus.FOUND, result.nextStatus)
        assertEquals(QueueNavigationStatus.FOUND, result.previousStatus)
        assertSame(next, result.next)
        assertSame(previous, result.previous)
    }

    @Test
    fun preservesALocalMovieCollectionQueueForACurrentItemClone() = runTest {
        val previous = jfMovie("movie-1")
        val storedCurrent = jfMovie("movie-2")
        val next = jfMovie("movie-3")
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(previous, storedCurrent, next), currentIndex = 1), contextKey = "collection-movies")
        val client = SeriesBackend()

        val result = queue(client).loadAdjacent(storedCurrent.copy(viewOffsetMs = 42))

        assertTrue(client.seriesQueueCalls.isEmpty())
        assertTrue(playback.isQueueActive)
        assertEquals("collection-movies", playback.shuffleContextKey)
        assertSame(storedCurrent, playback.currentQueueItem)
        assertEquals(1, playback.currentPlayQueueItemId)
        assertEquals(listOf(previous, storedCurrent, next), playback.loadedItems)
        assertSame(next, result.next)
        assertSame(previous, result.previous)
    }

    @Test
    fun extendsAPlexMovieQueueWindowForAdjacency() = runTest {
        val previous = plexMovie("movie-1", 1001)
        val current = plexMovie("movie-2", 1002)
        val next = plexMovie("movie-3", 1003)
        playback.setPlaybackFromPlayQueue(ServerPlayQueue(id = 77, selectedItemId = 1002, totalCount = 3, items = listOf(current)), "collection-movies")
        var windowFetches = 0
        var requestedCenter: String? = null
        playback.setPlayQueueWindowFetcher { playQueueId, center, _ ->
            windowFetches++
            requestedCenter = center
            assertEquals(77, playQueueId)
            ServerPlayQueue(id = playQueueId, selectedItemId = 1002, totalCount = 3, items = listOf(previous, current, next))
        }

        val result = queue().loadAdjacent(current)

        assertEquals(1, windowFetches)
        assertEquals("1002", requestedCenter)
        assertTrue(playback.isQueueActive)
        assertEquals(77, playback.playQueueId)
        assertSame(current, playback.currentQueueItem)
        assertEquals(1002, playback.currentPlayQueueItemId)
        assertEquals(listOf(previous, current, next), playback.loadedItems)
        assertEquals(QueueNavigationStatus.FOUND, result.nextStatus)
        assertEquals(QueueNavigationStatus.FOUND, result.previousStatus)
        assertSame(next, result.next)
        assertSame(previous, result.previous)
    }

    @Test
    fun doesNotUseAnUnrelatedActiveQueueForAStandaloneMovie() = runTest {
        val queuedPrevious = jfMovie("queued-1")
        val queuedCurrent = jfMovie("queued-2")
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(queuedPrevious, queuedCurrent), currentIndex = 1), contextKey = "stale-playlist")
        val client = SeriesBackend()

        val result = queue(client).loadAdjacent(jfMovie("unrelated"))

        assertTrue(client.seriesQueueCalls.isEmpty())
        assertTrue(playback.isQueueActive)
        assertEquals("stale-playlist", playback.shuffleContextKey)
        assertSame(queuedCurrent, playback.currentQueueItem)
        assertEquals(1, playback.currentPlayQueueItemId)
        assertEquals(listOf(queuedPrevious, queuedCurrent), playback.loadedItems)
        assertEquals(QueueNavigationStatus.FAILED, result.nextStatus)
        assertEquals(QueueNavigationStatus.FAILED, result.previousStatus)
        assertNull(result.next)
        assertNull(result.previous)
    }

    @Test
    fun catchesDownstreamExceptionsAndReportsFailedAdjacency() = runTest {
        val broken = object : OnlineServers {
            override val visibleOnlineClients: Map<ServerId, MediaBackend> get() = error("servers unavailable")
            override val onlineClients: Map<ServerId, MediaBackend> get() = error("servers unavailable")
            override fun client(serverId: ServerId): MediaBackend? = error("servers unavailable")
            override val changes: Flow<Unit> = emptyFlow()
        }

        val result = EpisodeQueue(playback, broken).loadAdjacent(plexEpisode("42", seriesId = "series-P"))

        assertNull(result.next)
        assertNull(result.previous)
        assertEquals(QueueNavigationStatus.FAILED, result.nextStatus)
    }

    @Test
    fun preservesAnActivePlaylistQueueAgainstSeriesRebuild() = runTest {
        // An episode played from a playlist walks the playlist, not its show.
        val ep1 = jfEpisode("ep1", seriesId = "series-A")
        val ep2 = jfEpisode("ep2", seriesId = "series-B")
        val ep3 = jfEpisode("ep3", seriesId = "series-A")
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(ep1, ep2, ep3), currentIndex = 1), contextKey = "playlist-X")
        val client = SeriesBackend(
            seriesEpisodes = listOf(jfEpisode("sibling-X", seriesId = "series-B"), ep2, jfEpisode("sibling-Y", seriesId = "series-B")),
        )

        val result = queue(client).loadAdjacent(ep2)

        assertTrue(client.seriesQueueCalls.isEmpty())
        assertEquals(listOf("ep1", "ep2", "ep3"), playback.loadedItems.map { it.id })
        assertEquals("ep3", result.next?.id)
        assertEquals("ep1", result.previous?.id)
    }

    @Test
    fun buildsAPlexLocalFallbackQueueWithWatchedEpisodes() = runTest {
        val ep1 = plexEpisode("ep1", seriesId = "series-P", viewCount = 1)
        val ep2 = plexEpisode("ep2", seriesId = "series-P", viewCount = 1)
        val ep3 = plexEpisode("ep3", seriesId = "series-P", viewCount = 1)
        val client = SeriesBackend(serverId = "srv-plex", backend = BackendKind.PLEX, seriesEpisodes = listOf(ep1, ep2, ep3))

        val result = queue(client).loadAdjacent(ep2)

        assertEquals(listOf("series-P"), client.seriesQueueCalls)
        assertEquals(listOf("ep1", "ep2", "ep3"), playback.loadedItems.map { it.id })
        assertEquals(QueueNavigationStatus.FOUND, result.nextStatus)
        assertEquals("ep3", result.next?.id)
        assertEquals("ep1", result.previous?.id)
    }

    @Test
    fun distinguishesAFallbackFetchFailureFromTheEndOfASeries() = runTest {
        val client = SeriesBackend(serverId = "srv-plex", backend = BackendKind.PLEX, fetchError = IllegalStateException("network unavailable"))

        val result = queue(client).loadAdjacent(plexEpisode("ep2", seriesId = "series-P"))

        assertEquals(QueueNavigationStatus.FAILED, result.nextStatus)
        assertFalse(playback.isQueueActive)
    }

    @Test
    fun confirmsTheEndOnlyAfterLoadingAQueueContainingTheCurrentEpisode() = runTest {
        val ep1 = plexEpisode("ep1", seriesId = "series-P", viewCount = 1)
        val ep2 = plexEpisode("ep2", seriesId = "series-P", viewCount = 1)
        val client = SeriesBackend(serverId = "srv-plex", backend = BackendKind.PLEX, seriesEpisodes = listOf(ep1, ep2))

        val result = queue(client).loadAdjacent(ep2)

        assertEquals(QueueNavigationStatus.BOUNDARY, result.nextStatus)
        assertNull(result.next)
    }

    @Test
    fun aSeriesListIsFetchedOncePerSeries() = runTest {
        val ep1 = jfEpisode("ep1", seriesId = "series-A")
        val ep2 = jfEpisode("ep2", seriesId = "series-A")
        val client = SeriesBackend(seriesEpisodes = listOf(ep1, ep2))
        val queue = queue(client)

        queue.loadAdjacent(ep1)
        playback.clearShuffle()
        val result = queue.loadAdjacent(ep2)

        assertEquals(listOf("series-A"), client.seriesQueueCalls)
        assertEquals("ep1", result.previous?.id)
    }

    // A shuffled same-series queue, as a show shuffle publishes it.

    private val ep1 = jfEpisode("ep1", seriesId = "series-A")
    private val ep2 = jfEpisode("ep2", seriesId = "series-A")
    private val ep3 = jfEpisode("ep3", seriesId = "series-A")
    private val ep4 = jfEpisode("ep4", seriesId = "series-A")
    private val ep5 = jfEpisode("ep5", seriesId = "series-A")
    private val shuffledIds = listOf("ep3", "ep1", "ep5", "ep2", "ep4")

    /** The server answers the sequential list, so an unwanted rebuild shows in the calls and the order. */
    private fun shuffledSession(): SeriesBackend {
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(ep3, ep1, ep5, ep2, ep4), currentIndex = 0, shuffled = true), contextKey = "series-A")
        return SeriesBackend(seriesEpisodes = listOf(ep1, ep2, ep3, ep4, ep5))
    }

    @Test
    fun preservesTheShuffledOrderInsteadOfRebuildingSequentially() = runTest {
        val client = shuffledSession()

        val result = queue(client).loadAdjacent(ep3)

        assertTrue(client.seriesQueueCalls.isEmpty())
        assertEquals(shuffledIds, playback.loadedItems.map { it.id })
        assertTrue(playback.isShuffleActive)
        assertEquals("series-A", playback.shuffleContextKey)
        assertEquals("ep1", result.next?.id)
        assertNull(result.previous)
    }

    @Test
    fun continuesTheShuffledOrderAfterAdvancingToTheNextEpisode() = runTest {
        val client = shuffledSession()
        val queue = queue(client)
        queue.onItemChanged(ep1)

        val result = queue.loadAdjacent(ep1)

        assertTrue(client.seriesQueueCalls.isEmpty())
        assertTrue(playback.isShuffleActive)
        assertEquals("ep5", result.next?.id)
        assertEquals("ep3", result.previous?.id)
    }

    @Test
    fun sameEpisodeCloneFromASourceSwitchDoesNotClobberTheQueue() = runTest {
        val client = shuffledSession()

        val result = queue(client).loadAdjacent(ep3.copy(viewOffsetMs = 42))

        assertTrue(client.seriesQueueCalls.isEmpty())
        assertEquals(shuffledIds, playback.loadedItems.map { it.id })
        assertTrue(playback.isShuffleActive)
        assertEquals("ep1", result.next?.id)
    }

    @Test
    fun stillBuildsASequentialSeriesQueueWhenNoQueueIsActive() = runTest {
        val client = SeriesBackend(seriesEpisodes = listOf(ep1, ep2, ep3, ep4, ep5))

        val result = queue(client).loadAdjacent(ep3)

        assertEquals(listOf("series-A"), client.seriesQueueCalls)
        assertEquals(listOf("ep1", "ep2", "ep3", "ep4", "ep5"), playback.loadedItems.map { it.id })
        assertFalse(playback.isShuffleActive)
        assertEquals("ep4", result.next?.id)
        assertEquals("ep2", result.previous?.id)
    }

    // The player opening and moving on.

    @Test
    fun openingAnItemOfTheQueueMovesTheCursorAndAnyOtherClearsTheQueue() {
        val queue = queue()
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(ep1, ep2, ep3), currentIndex = 0), contextKey = "series-A")

        queue.onPlayerOpened(ep2)
        assertEquals(1, playback.currentPlayQueueItemId)

        queue.onPlayerOpened(jfMovie("standalone"))
        assertFalse(playback.isQueueActive)
        assertTrue(playback.loadedItems.isEmpty())
    }

    // The Plex show queue.

    private val showQueueJson =
        """{"MediaContainer":{"playQueueID":42,"playQueueVersion":1,"playQueueSelectedItemID":901,"playQueueTotalCount":4,"Metadata":[""" +
            """{"playQueueItemID":900,"ratingKey":"ep-1","type":"episode"},{"playQueueItemID":901,"ratingKey":"ep-2","type":"episode"},""" +
            """{"playQueueItemID":902,"ratingKey":"ep-3","type":"episode"}]}}"""

    private val windowJson =
        """{"MediaContainer":{"playQueueID":42,"playQueueVersion":1,"playQueueSelectedItemID":901,"playQueueTotalCount":4,"Metadata":[""" +
            """{"playQueueItemID":901,"ratingKey":"ep-2","type":"episode"},{"playQueueItemID":902,"ratingKey":"ep-3","type":"episode"},""" +
            """{"playQueueItemID":903,"ratingKey":"ep-4","type":"episode"}]}}"""

    private fun plexShowEpisode(id: String) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        serverId = TEST_SERVER_ID,
        grandparentId = "show-1",
        libraryId = "2",
        libraryTitle = "TV Shows",
    )

    @Test
    fun aPlexEpisodeGetsItsShowsServerQueueWithWindowsOfFifty() = runTest {
        val requests = mutableListOf<Pair<String, Map<String, String?>>>()
        val client = testPlexClient(
            { request ->
                val params = request.url.parameters.names().associateWith { request.url.parameters[it] }
                requests += "${request.method.value} ${request.url.encodedPath}" to params
                if (request.url.encodedPath == "/playQueues") jsonResponse(showQueueJson) else jsonResponse(windowJson)
            },
            environment = PlexClientEnvironment(specialsOrdering = { SpecialsOrdering.AIR_DATE }),
            machineIdentifier = "machine-1",
        )
        val stale = jfEpisode("other", seriesId = "series-A")
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(stale), currentIndex = 0), contextKey = "series-A")
        val queue = queue(client)

        queue.ensurePlexShowQueue(plexShowEpisode("ep-2"))

        assertEquals(42, playback.playQueueId)
        assertEquals("show-1", playback.shuffleContextKey)
        assertEquals(901, playback.currentPlayQueueItemId)
        val (create, createParams) = requests.single()
        assertEquals("POST /playQueues", create)
        assertEquals("/library/metadata/ep-2", createParams["key"])
        assertEquals("0", createParams["shuffle"])
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/metadata/show-1/allLeaves", createParams["uri"])

        // The queue's windows come from the server, around the playing entry.
        queue.onItemChanged(playback.loadedItems[2])
        val next = playback.getNextEpisode("ep-3")
        assertEquals("ep-4", next.item?.id)
        val (window, windowParams) = requests.last()
        assertEquals("GET /playQueues/42", window)
        assertEquals("50", windowParams["window"])
        assertEquals("902", windowParams["center"])
        assertEquals("2", next.item?.libraryId)
    }

    @Test
    fun aPlexEpisodeKeepsTheActiveQueueThatHoldsIt() = runTest {
        val requests = mutableListOf<String>()
        val client = testPlexClient({ request ->
            requests += request.url.encodedPath
            jsonResponse(showQueueJson)
        })
        val first = plexShowEpisode("ep-1").copy(playQueueItemId = 900)
        val second = plexShowEpisode("ep-2").copy(playQueueItemId = 901)
        playback.setPlaybackFromPlayQueue(ServerPlayQueue(id = 7, selectedItemId = 900, totalCount = 2, items = listOf(first, second)), "playlist-9")

        queue(client).ensurePlexShowQueue(second)

        assertTrue(requests.isEmpty())
        assertEquals(7, playback.playQueueId)
        assertEquals("playlist-9", playback.shuffleContextKey)
        assertEquals(901, playback.currentPlayQueueItemId)
    }

    @Test
    fun aFailedPlexShowQueueClearsTheStaleQueueAndLeavesTheSeriesFallback() = runTest {
        val client = testPlexClient({ jsonResponse("boom", status = 500) }, machineIdentifier = "machine-1")
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(jfEpisode("other", seriesId = "series-A")), currentIndex = 0), contextKey = "series-A")

        queue(client).ensurePlexShowQueue(plexShowEpisode("ep-2"))

        assertFalse(playback.isQueueActive)
    }

    @Test
    fun onlyPlexEpisodesGetAShowQueue() = runTest {
        val requests = mutableListOf<String>()
        val client = testPlexClient({ request ->
            requests += request.url.encodedPath
            jsonResponse(showQueueJson)
        })
        val queue = queue(client)

        queue.ensurePlexShowQueue(plexShowEpisode("ep-2").copy(kind = MediaKind.MOVIE))
        queue.ensurePlexShowQueue(plexShowEpisode("ep-2").copy(backend = BackendKind.JELLYFIN))
        queue.ensurePlexShowQueue(plexShowEpisode("ep-2").copy(grandparentId = null))

        assertTrue(requests.isEmpty())
        assertFalse(playback.isQueueActive)
    }

    // Specials in a Plex show's queue, from a show as a Plex server (1.43) serves it: a Special that aired on Episode
    // 10's day, before Episode 11, and Episodes 13 and 14 without an air date. Every way an episode starts (a show's
    // Play opens its on-deck episode, an episode's Play, Continue Watching) opens it in the player, and Next opens the
    // queue's next item.

    /** The show's episodes as Plex lists them (`/grandchildren`: Specials first), `id/season/episode/air date`. */
    private val recordedEpisodes = listOf(
        "s0e1/0/1/2012-06-08", "s1e1/1/1/2012-04-06", "s1e2/1/2/2012-04-13", "s1e3/1/3/2012-04-20", "s1e4/1/4/2012-04-27",
        "s1e5/1/5/2012-05-04", "s1e6/1/6/2012-05-11", "s1e7/1/7/2012-05-18", "s1e8/1/8/2012-05-25", "s1e9/1/9/2012-06-01",
        "s1e10/1/10/2012-06-08", "s1e11/1/11/2012-06-22", "s1e12/1/12/2012-06-29", "s1e13/1/13/", "s1e14/1/14/",
    ).associate { row ->
        val (id, season, episode, aired) = row.split('/')
        id to """{"ratingKey":"$id","type":"episode","parentIndex":$season,"index":$episode,"parentRatingKey":"season-$season",""" +
            """"grandparentRatingKey":"show-1"${if (aired.isEmpty()) "" else ""","originallyAvailableAt":"$aired""""}}"""
    }

    /** The queues Plex made for the show: Plex Web's request for an episode, by the episode it starts from. */
    private val recordedEpisodeQueues = mapOf(
        "s1e10" to listOf("s1e10", "s0e1", "s1e11", "s1e12", "s1e13", "s1e14"),
        "s0e1" to listOf("s0e1", "s1e11", "s1e12"),
        "s1e13" to listOf("s1e13", "s1e14", "s0e1"),
    )

    /** The queue Plex made from the show's `/allLeaves` with an episode selected. */
    private val recordedAllLeavesQueue = listOf(
        "s1e13", "s1e14", "s1e1", "s1e2", "s1e3", "s1e4", "s1e5", "s1e6", "s1e7", "s1e8", "s1e9", "s0e1", "s1e10", "s1e11", "s1e12",
    )

    private fun container(vararg rows: String) = """{"MediaContainer":{"size":${rows.size},"totalSize":${rows.size},"Metadata":[${rows.joinToString(",")}]}}"""

    /**
     * A Plex server answering with [recordedEpisodes] and the recorded queues, each only to the request it was recorded
     * for: an episode's queue to `continuous=1` seeded at the episode with no `key`, the `/allLeaves` queue to the show's
     * `/allLeaves` with an episode as `key`. Any other request is a 404.
     */
    private fun recordedShowServer(ordering: SpecialsOrdering): MediaBackend {
        val metadata = "server://machine-1/com.plexapp.plugins.library/library/metadata/"
        var queued = emptyList<String>()
        var selected = 0
        fun queueJson() = """{"MediaContainer":{"playQueueID":42,"playQueueVersion":1,"playQueueSelectedItemID":${900 + selected},""" +
            """"playQueueTotalCount":${queued.size},"Metadata":[""" +
            queued.mapIndexed { i, id -> recordedEpisodes.getValue(id).replaceFirst("{", """{"playQueueItemID":${900 + i},""") }.joinToString(",") + "]}}"
        return testPlexClient(
            { request ->
                val params = request.url.parameters
                val seed = params["uri"]?.removePrefix(metadata)
                val key = params["key"]?.removePrefix("/library/metadata/")
                when (request.url.encodedPath) {
                    "/library/metadata/show-1" -> jsonResponse(container("""{"ratingKey":"show-1","type":"show"}"""))
                    "/library/metadata/show-1/grandchildren" -> jsonResponse(container(*recordedEpisodes.values.toTypedArray()))
                    "/playQueues" -> when {
                        params["continuous"] == "1" && key == null && seed in recordedEpisodeQueues -> {
                            queued = recordedEpisodeQueues.getValue(seed!!)
                            selected = 0
                            jsonResponse(queueJson())
                        }
                        params["continuous"] == "0" && seed == "show-1/allLeaves" && key in recordedAllLeavesQueue -> {
                            queued = recordedAllLeavesQueue
                            selected = queued.indexOf(key)
                            jsonResponse(queueJson())
                        }
                        else -> jsonResponse("{}", status = 404)
                    }
                    "/playQueues/42" -> jsonResponse(queueJson())
                    else -> jsonResponse("{}", status = 404)
                }
            },
            environment = PlexClientEnvironment(specialsOrdering = { ordering }),
            machineIdentifier = "machine-1",
        )
    }

    /**
     * What the player does as it plays [item]: the queue follows it, a Plex episode gets its show's queue, then next and
     * previous. [showPlay]: [item] plays as its show's Play.
     */
    private suspend fun EpisodeQueue.play(item: MediaItem, opened: Boolean = true, showPlay: Boolean = false): AdjacentEpisodes {
        if (opened) onPlayerOpened(item) else onItemChanged(item)
        ensurePlexShowQueue(item)
        return loadAdjacent(item, showPlay = showPlay)
    }

    @Test
    fun serverOrderOnPlexPlaysAndListsPlexWebsQueueFromTheEpisodePlayed() = runTest {
        for ((start, order) in recordedEpisodeQueues) {
            // Each start with no queue, as when another show played last.
            playback.clearShuffle()
            val queue = queue(recordedShowServer(SpecialsOrdering.RESPECT_SERVER))
            val (played, last) = queue.playThrough(plexShowEpisode(start))
            assertEquals(order, played, start)
            assertEquals(QueueNavigationStatus.BOUNDARY, last.nextStatus, start)
            assertEquals(order, queue.entries(hideSpoilers = false) { null }.map { it.second.id }, "the queue sheet from $start")
        }
    }

    @Test
    fun serverOrderOnPlexHasNothingBeforeTheEpisodePlayedAndPreviousFollowsTheQueue() = runTest {
        val queue = queue(recordedShowServer(SpecialsOrdering.RESPECT_SERVER))

        val opened = queue.play(plexShowEpisode("s1e10"))
        assertNull(opened.previous)
        assertEquals(QueueNavigationStatus.BOUNDARY, opened.previousStatus)
        assertEquals("s0e1", opened.next?.id)

        val special = queue.play(opened.next!!, opened = false)
        assertEquals("s1e10", special.previous?.id)
        assertEquals("s1e11", special.next?.id)
    }

    @Test
    fun airDateOnPlexPlaysTheShowsAllLeavesQueue() = runTest {
        val queue = queue(recordedShowServer(SpecialsOrdering.AIR_DATE))

        val opened = queue.play(plexShowEpisode("s1e10"))

        assertEquals("s0e1", opened.previous?.id)
        assertEquals("s1e11", opened.next?.id)
        assertEquals(recordedAllLeavesQueue, queue.entries(hideSpoilers = false) { null }.map { it.second.id })
    }

    @Test
    fun specialsLastOnPlexPlaysTheRegularEpisodesAroundAnOpenedEpisode() = runTest {
        val adjacent = queue(recordedShowServer(SpecialsOrdering.SPECIALS_LAST)).play(plexShowEpisode("s1e10"))

        assertEquals("s1e11", adjacent.next?.id)
        assertEquals("s1e9", adjacent.previous?.id)
    }

    @Test
    fun specialsLastOnPlexFromContinueWatchingReplacesAnotherShowsQueue() = runTest {
        val other = plexShowEpisode("other").copy(grandparentId = "show-9", playQueueItemId = 700)
        playback.setPlaybackFromPlayQueue(ServerPlayQueue(id = 7, selectedItemId = 700, totalCount = 1, items = listOf(other)), "show-9")

        val adjacent = queue(recordedShowServer(SpecialsOrdering.SPECIALS_LAST)).play(plexShowEpisode("s1e12"))

        assertEquals("s1e13", adjacent.next?.id)
        assertEquals("s1e11", adjacent.previous?.id)
    }

    @Test
    fun specialsLastOnPlexNextPlaysEveryRegularEpisodeThenTheSpecials() = runTest {
        val queue = queue(recordedShowServer(SpecialsOrdering.SPECIALS_LAST))

        val (played, last) = queue.playThrough(plexShowEpisode("s1e1"))

        assertEquals((1..14).map { "s1e$it" } + "s0e1", played)
        assertEquals(QueueNavigationStatus.BOUNDARY, last.nextStatus)
        assertEquals(played, queue.entries(hideSpoilers = false) { null }.map { it.second.id })
    }

    // Specials in a Jellyfin or Emby show's queue, Maestro Show as the test servers hold it: one Special with no
    // placement, which both servers list first. With the server's order the queue is the one the server's web client
    // plays: Jellyfin's starts at the episode played, whichever way it starts; Emby's holds the whole series around an
    // episode played on its own, and starts a show's Play at the show's next episode.

    /** The ids [item] and Next after Next play from it, and the last item's adjacency. */
    private suspend fun EpisodeQueue.playThrough(item: MediaItem, showPlay: Boolean = false): Pair<List<String>, AdjacentEpisodes> {
        val played = mutableListOf(item.id)
        var adjacent = play(item, showPlay = showPlay)
        while (true) {
            val next = adjacent.next ?: break
            played += next.id
            adjacent = play(next, opened = false)
        }
        return played to adjacent
    }

    @Test
    fun serverOrderOnJellyfinStartsTheQueueAtTheEpisodePlayed() = runTest {
        val server = maestroServer(MediaBrowserDialect.JELLYFIN)
        val episodes = maestroEpisodes(server)
        for (showPlay in listOf(false, true)) {
            // Each start with no queue, as when another show played last.
            playback.clearShuffle()
            val queue = queue(server)
            val opened = queue.play(episodes.getValue("s1e1"), showPlay = showPlay)
            assertNull(opened.previous, "showPlay=$showPlay")
            assertEquals(QueueNavigationStatus.BOUNDARY, opened.previousStatus)
            assertEquals(listOf("s1e1", "s1e2", "s1e3", "s2e1", "s2e2"), playback.loadedItems.map { it.id })
        }

        playback.clearShuffle()
        val queue = queue(server)
        val (played, last) = queue.playThrough(episodes.getValue("s1e2"))
        assertEquals(listOf("s1e2", "s1e3", "s2e1", "s2e2"), played)
        assertEquals(QueueNavigationStatus.BOUNDARY, last.nextStatus)
        assertEquals("s2e1", last.previous?.id)
    }

    @Test
    fun serverOrderOnJellyfinPlaysTheFirstSeasonAfterTheSpecial() = runTest {
        val server = maestroServer(MediaBrowserDialect.JELLYFIN)
        val (played, _) = queue(server).playThrough(maestroEpisodes(server).getValue("s0e1"))
        assertEquals(MAESTRO_SERVER_ORDER, played)
    }

    @Test
    fun serverOrderOnEmbyQueuesTheWholeSeriesAroundAnEpisodePlayedOnItsOwn() = runTest {
        val server = maestroServer(MediaBrowserDialect.EMBY)
        val opened = queue(server).play(maestroEpisodes(server).getValue("s1e1"))
        assertEquals("s0e1", opened.previous?.id)
        assertEquals("s1e2", opened.next?.id)
        assertEquals(MAESTRO_SERVER_ORDER, playback.loadedItems.map { it.id })
    }

    @Test
    fun serverOrderOnEmbyStartsAShowsPlayAtItsNextEpisode() = runTest {
        val server = maestroServer(MediaBrowserDialect.EMBY)
        val queue = queue(server)
        val episodes = maestroEpisodes(server)
        val opened = queue.play(episodes.getValue("s1e1"), showPlay = true)
        assertNull(opened.previous)
        assertEquals(QueueNavigationStatus.BOUNDARY, opened.previousStatus)

        val next = queue.play(opened.next!!, opened = false)
        assertEquals("s1e2", opened.next?.id)
        assertEquals("s1e1", next.previous?.id)
        assertEquals(listOf("s1e1", "s1e2", "s1e3", "s2e1", "s2e2"), playback.loadedItems.map { it.id })
    }

    @Test
    fun otherOrderingsQueueTheWholeSeriesOnJellyfinAndEmby() = runTest {
        for (dialect in listOf(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.EMBY)) {
            playback.clearShuffle()
            val last = maestroServer(dialect, SpecialsOrdering.SPECIALS_LAST)
            val lastQueue = queue(last).play(maestroEpisodes(last).getValue("s1e2"), showPlay = true)
            assertEquals("s1e1", lastQueue.previous?.id, "$dialect")
            assertEquals(listOf("s1e1", "s1e2", "s1e3", "s2e1", "s2e2", "s0e1"), playback.loadedItems.map { it.id })

            playback.clearShuffle()
            val aired = maestroServer(dialect, SpecialsOrdering.AIR_DATE)
            assertEquals("s0e1", queue(aired).play(maestroEpisodes(aired).getValue("s1e1"), showPlay = true).previous?.id, "$dialect")
        }
    }

    // The queue sheet.

    @Test
    fun entriesListTheQueueWithThePlayingOneAndUnwatchedEpisodesAsSpoilers() {
        val watched = MediaItem(
            id = "e1", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, title = "Pilot", grandparentTitle = "Show",
            parentIndex = 1, index = 1, viewCount = 1, thumbPath = "/thumb/e1", serverId = "srv-jf",
        )
        val unwatched = watched.copy(id = "e2", title = "Second", index = 2, viewCount = null, thumbPath = null)
        val movie = MediaItem(id = "m1", backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = "Film", year = 2020, serverId = "srv-jf")
        playback.setPlaybackFromLocalQueue(LocalPlayQueue(listOf(watched, unwatched, movie), currentIndex = 1, shuffled = true), contextKey = "pl")
        val queue = queue()

        assertEquals(
            listOf(
                QueueEntry("0", "Pilot", "Show · S1E1", imageUrl = "img:/thumb/e1"),
                QueueEntry("1", "Second", "Show · S1E2", current = true, spoiler = true),
                QueueEntry("2", "Film", "2020"),
            ),
            queue.entries(hideSpoilers = true) { "img:${it.thumbPath}" }.map { it.first },
        )
        assertFalse(queue.entries(hideSpoilers = false) { null }.any { it.first.spoiler })
        assertTrue(queue.shuffled)
        assertSame(movie, queue.entries(hideSpoilers = false) { null }.single { it.first.key == "2" }.second)
    }

    @Test
    fun serverQueueEntriesAreKeyedByTheirQueueIds() {
        val first = plexMovie("movie-1", 1001)
        val second = plexMovie("movie-2", 1002)
        playback.setPlaybackFromPlayQueue(ServerPlayQueue(id = 77, selectedItemId = 1002, totalCount = 2, items = listOf(first, second)), "c")

        val entries = queue().entries(hideSpoilers = false) { null }

        assertEquals(listOf("1001", "1002"), entries.map { it.first.key })
        assertEquals(listOf(false, true), entries.map { it.first.current })
        assertSame(first, entries.first().second)
    }

    @Test
    fun theNextItemIsPrimedOncePerItem() = runTest {
        val client = SeriesBackend()
        client.items = { null }
        val queue = queue(client)
        val next = jfMovie("next")

        queue.primeNext(next)
        queue.primeNext(next)
        queue.primeNext(jfMovie("other"))

        assertEquals(listOf("fetchItem:next", "fetchItem:other"), client.calls)
    }

    // Downloads (the offline path).

    private fun downloaded(id: String, number: Int, file: String, season: Int = 1) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        parentIndex = season,
        index = number,
        serverId = "s1",
        grandparentId = "show",
        mediaVersions = listOf(MediaVersion("v-$id", parts = listOf(MediaPart("p-$id", file = file)))),
    )

    @Test
    fun offlineAdjacencyFollowsWatchOrderAndSkipsTheSameFile() {
        val e23 = downloaded("e23", 23, "/a.mkv")
        val e24 = downloaded("e24", 24, "/b.mkv")
        val e25 = downloaded("e25", 25, "/b.mkv")
        val e26 = downloaded("e26", 26, "/c.mkv")
        val special = downloaded("s1", 1, "/s.mkv", season = 0)
        val episodes = listOf(e26, special, e25, e23, e24)

        val middle = EpisodeQueue.offlineAdjacent(e25, episodes, SpecialsOrdering.SPECIALS_LAST)
        assertSame(e26, middle.next)
        assertSame(e23, middle.previous)

        val last = EpisodeQueue.offlineAdjacent(special, episodes, SpecialsOrdering.SPECIALS_LAST)
        assertNull(last.next)
        assertEquals(QueueNavigationStatus.BOUNDARY, last.nextStatus)
        assertSame(e26, last.previous)

        assertEquals(AdjacentEpisodes.UNAVAILABLE, EpisodeQueue.offlineAdjacent(jfMovie("m"), episodes, SpecialsOrdering.SPECIALS_LAST))
        assertEquals(AdjacentEpisodes.FAILED, EpisodeQueue.offlineAdjacent(e23, emptyList(), SpecialsOrdering.SPECIALS_LAST))
        assertEquals(AdjacentEpisodes.FAILED, EpisodeQueue.offlineAdjacent(downloaded("gone", 1, "/g.mkv"), episodes, SpecialsOrdering.SPECIALS_LAST))
    }

    // Previous and the carry to another item.

    @Test
    fun previousRestartsOnlyPastThreeSeconds() {
        assertFalse(shouldRestartBeforePreviousItem(0.0))
        assertFalse(shouldRestartBeforePreviousItem(3.0))
        assertTrue(shouldRestartBeforePreviousItem(3.001))
    }

    @Test
    fun theCarryKeepsTheVersionBySignatureAndDropsTracksWhenFollowingTheServer() {
        val versions = listOf(MediaVersion("a", videoResolution = "1080", videoCodec = "h264"), MediaVersion("b", videoResolution = "4k", videoCodec = "hevc"))
        val audio = AudioTrackPreference(language = "ja")
        val subtitle = SubtitlePreference.Off

        val carried = EpisodeCarry.of(versions, 1, TranscodeQualityPreset.entries.last(), audio, subtitle, null, followServerTrackSelections = false)
        assertEquals(versions[1].signature, carried.versionSignature)
        assertEquals(TranscodeQualityPreset.entries.last(), carried.quality)
        assertEquals(audio, carried.audio)
        assertEquals(subtitle, carried.subtitle)

        val following = EpisodeCarry.of(versions, 1, null, audio, subtitle, subtitle, followServerTrackSelections = true)
        assertEquals(versions[1].signature, following.versionSignature)
        assertNull(following.audio)
        assertNull(following.subtitle)
        assertNull(following.secondarySubtitle)

        assertNull(EpisodeCarry.of(versions, 5, null, null, null, null, followServerTrackSelections = false).versionSignature)
    }
}
