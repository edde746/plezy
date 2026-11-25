package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class JellyfinSequentialLauncherTest {
    private class FakeSource(
        val playable: List<MediaItem> = emptyList(),
        val folder: List<MediaItem> = emptyList(),
        val episodes: List<MediaItem>? = emptyList(),
        val playlist: List<MediaItem> = emptyList(),
        val random: List<MediaItem> = emptyList(),
        val gate: CompletableDeferred<Unit>? = null,
    ) {
        val playableCalls = mutableListOf<String>()
        val folderCalls = mutableListOf<String>()
        val episodeCalls = mutableListOf<String>()
        val playlistOffsets = mutableListOf<Int>()
        val randomCalls = mutableListOf<Pair<String, Int>>()

        fun launcher(seed: Int = 1) = JellyfinSequentialLauncher(
            fetchPlaylistPage = { _, start, size ->
                playlistOffsets += start
                gate?.await()
                LibraryPage(playlist.drop(start).take(size), playlist.size, start)
            },
            fetchPlayableDescendants = { playableCalls += it; gate?.await(); playable },
            fetchPlayableFolderDescendants = { folderCalls += it; gate?.await(); folder },
            fetchClientSideEpisodeQueue = { episodeCalls += it; gate?.await(); episodes },
            fetchRandomLibraryVideos = { id, limit -> randomCalls += id to limit; random },
            random = Random(seed),
        )
    }

    private fun item(id: String, kind: MediaKind, serverId: String? = "srv-jf") = MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, serverId = serverId)
    private fun ep(id: String) = item(id, MediaKind.EPISODE)
    private val collection = item("col-1", MediaKind.COLLECTION)
    private val playlist = MediaPlaylist(id = "pl-1", backend = BackendKind.JELLYFIN, title = "Mix", playlistType = "video", serverId = "srv-jf")

    @Test
    fun rejectsItemsWithoutServerId() = runTest {
        val launcher = FakeSource().launcher()
        val error = assertFailsWith<IllegalArgumentException> { launcher.buildCollectionQueue(item("col", MediaKind.COLLECTION, serverId = null), shuffle = false) }
        assertTrue(error.message!!.contains("serverId"))
        assertFailsWith<IllegalArgumentException> { launcher.buildPlaylistQueue(playlist.copy(serverId = null), shuffle = false) }
        assertFailsWith<IllegalArgumentException> { launcher.buildFolderQueue(item("f", MediaKind.FOLDER, serverId = null), shuffle = false) }
    }

    @Test
    fun collectionExpandsToPlayableItemsInOrder() = runTest {
        val fetched = listOf(ep("e1"), ep("e2"), ep("e3"))
        val source = FakeSource(playable = fetched)
        val launch = source.launcher().buildCollectionQueue(collection, shuffle = false)
        assertEquals(listOf("col-1"), source.playableCalls)
        assertEquals(fetched, launch.queue.items)
        assertEquals(0, launch.queue.currentIndex)
        assertFalse(launch.queue.shuffled)
        assertEquals("jellyfin:col-1", launch.queueId)
    }

    @Test
    fun playlistQueuesEveryPageInPlaylistOrder() = runTest {
        val items = List(JellyfinSequentialLauncher.PLAYLIST_PAGE_SIZE + 1) { ep("p$it") }
        val source = FakeSource(playlist = items)
        val launch = source.launcher().buildPlaylistQueue(playlist, shuffle = false)
        assertEquals(items.map { it.id }, launch.queue.items.map { it.id })
        assertEquals(listOf(0, JellyfinSequentialLauncher.PLAYLIST_PAGE_SIZE), source.playlistOffsets)
        assertTrue(source.playableCalls.isEmpty())
        assertEquals("jellyfin:pl-1", launch.queueId)
    }

    @Test
    fun shuffleReordersTheQueue() = runTest {
        val ids = List(50) { "e$it" }
        val launch = FakeSource(playable = ids.map(::ep)).launcher().buildCollectionQueue(collection, shuffle = true)
        val shuffled = launch.queue.items.map { it.id }
        assertEquals(ids.toSet(), shuffled.toSet())
        assertEquals(ids.size, shuffled.size)
        assertNotEquals(ids, shuffled)
        assertTrue(launch.queue.shuffled)
        assertEquals(0, launch.queue.currentIndex)
    }

    @Test
    fun startItemPositionsTheCursorWithoutReordering() = runTest {
        val fetched = listOf(ep("a"), ep("b"), ep("c"), ep("d"))
        val launch = FakeSource(playable = fetched).launcher().buildCollectionQueue(collection, shuffle = false, startItem = fetched[2])
        assertEquals(listOf("a", "b", "c", "d"), launch.queue.items.map { it.id })
        assertEquals(2, launch.queue.currentIndex)
    }

    @Test
    fun startItemWithNoMatchFallsBackToHead() = runTest {
        val launch = FakeSource(playable = listOf(ep("a"), ep("b"))).launcher().buildCollectionQueue(collection, shuffle = false, startItem = ep("missing"))
        assertEquals(0, launch.queue.currentIndex)
    }

    @Test
    fun folderSeedsVideoOnlyQueueStampedWithFolder() = runTest {
        val source = FakeSource(folder = listOf(item("song", MediaKind.TRACK), item("movie", MediaKind.MOVIE, serverId = null), item("video", MediaKind.CLIP)))
        val folder = item("folder-1", MediaKind.FOLDER).copy(serverName = "Home Jellyfin", libraryId = "lib-1", libraryTitle = "Videos")
        val launch = source.launcher().buildFolderQueue(folder, shuffle = false)
        assertEquals(listOf("folder-1"), source.folderCalls)
        assertTrue(source.playableCalls.isEmpty())
        assertEquals(listOf("movie", "video"), launch.queue.items.map { it.id })
        val first = launch.queue.items.first()
        assertEquals("srv-jf", first.serverId)
        assertEquals("Home Jellyfin", first.serverName)
        assertEquals("lib-1", first.libraryId)
        assertEquals("Videos", first.libraryTitle)
        assertFalse(launch.queue.shuffled)
        assertEquals("jellyfin:folder-1", launch.queueId)
    }

    @Test
    fun folderShuffleReordersTheVideoQueue() = runTest {
        val ids = List(50) { "v$it" }
        val launch = FakeSource(folder = ids.map { item(it, MediaKind.CLIP) }).launcher().buildFolderQueue(item("f", MediaKind.FOLDER), shuffle = true)
        val shuffled = launch.queue.items.map { it.id }
        assertEquals(ids.toSet(), shuffled.toSet())
        assertNotEquals(ids, shuffled)
        assertTrue(launch.queue.shuffled)
    }

    @Test
    fun musicOnlyFolderIsEmpty() = runTest {
        val source = FakeSource(folder = listOf(item("a", MediaKind.TRACK), item("b", MediaKind.TRACK)))
        assertFailsWith<EmptyPlayQueueException> { source.launcher().buildFolderQueue(item("music", MediaKind.FOLDER), shuffle = false) }
    }

    @Test
    fun libraryShuffleQueuesTheRandomSampleStampedWithLibrary() = runTest {
        val source = FakeSource(random = listOf(item("m1", MediaKind.MOVIE, serverId = null), ep("e1"), item("v1", MediaKind.CLIP)))
        val library = MediaLibrary(id = "lib-movies", backend = BackendKind.JELLYFIN, title = "Movies", kind = MediaKind.MOVIE, serverId = "srv-jf", serverName = "Home Jellyfin")
        val launch = source.launcher().buildShuffledLibraryQueue(library)
        assertEquals(listOf("lib-movies" to JellyfinSequentialLauncher.LIBRARY_SHUFFLE_QUEUE_SIZE), source.randomCalls)
        assertEquals(200, JellyfinSequentialLauncher.LIBRARY_SHUFFLE_QUEUE_SIZE)
        assertEquals(setOf("m1", "e1", "v1"), launch.queue.items.map { it.id }.toSet())
        assertTrue(launch.queue.items.all { it.serverId == "srv-jf" && it.libraryId == "lib-movies" && it.libraryTitle == "Movies" })
        assertTrue(launch.queue.shuffled)
        assertEquals("jellyfin:lib-movies", launch.queueId)
    }

    @Test
    fun shuffledShowRejectsOtherKinds() = runTest {
        val error = assertFailsWith<IllegalArgumentException> { FakeSource().launcher().buildShuffledShowQueue(item("m1", MediaKind.MOVIE)) }
        assertTrue(error.message!!.contains("shows and seasons"))
    }

    @Test
    fun shuffledShowRejectsSeasonWithoutParent() = runTest {
        val error = assertFailsWith<IllegalArgumentException> { FakeSource().launcher().buildShuffledShowQueue(item("s1", MediaKind.SEASON)) }
        assertTrue(error.message!!.contains("parentId"))
    }

    @Test
    fun shuffledShowRejectsItemsWithoutServerId() = runTest {
        val error = assertFailsWith<IllegalArgumentException> { FakeSource().launcher().buildShuffledShowQueue(item("show", MediaKind.SHOW, serverId = null)) }
        assertTrue(error.message!!.contains("serverId"))
    }

    @Test
    fun shuffledShowFetchesSeriesEpisodesAndShuffles() = runTest {
        val ids = List(50) { "ep$it" }
        val source = FakeSource(episodes = ids.map { ep(it).copy(serverId = null) })
        val launch = source.launcher().buildShuffledShowQueue(item("show-1", MediaKind.SHOW).copy(serverName = "My Jellyfin"))
        assertEquals(listOf("show-1"), source.episodeCalls)
        val shuffled = launch.queue.items.map { it.id }
        assertEquals(ids.toSet(), shuffled.toSet())
        assertNotEquals(ids, shuffled)
        assertTrue(launch.queue.shuffled)
        assertEquals("srv-jf", launch.queue.items.first().serverId)
        assertEquals("My Jellyfin", launch.queue.items.first().serverName)
        assertEquals("jellyfin:show-1", launch.queueId)
    }

    @Test
    fun shuffledSeasonAnchorsOnItsSeries() = runTest {
        val source = FakeSource(episodes = listOf(ep("a"), ep("b")))
        source.launcher().buildShuffledShowQueue(item("season-2", MediaKind.SEASON).copy(parentId = "show-7"))
        assertEquals(listOf("show-7"), source.episodeCalls)
    }

    @Test
    fun seriesWithoutEpisodesIsEmpty() = runTest {
        assertFailsWith<EmptyPlayQueueException> { FakeSource(episodes = emptyList()).launcher().buildShuffledShowQueue(item("show", MediaKind.SHOW)) }
        assertFailsWith<EmptyPlayQueueException> { FakeSource(episodes = null).launcher().buildShuffledShowQueue(item("show", MediaKind.SHOW)) }
    }

    @Test
    fun emptyCollectionIsEmpty() = runTest {
        assertFailsWith<EmptyPlayQueueException> { FakeSource().launcher().buildCollectionQueue(collection, shuffle = false) }
    }

    @Test
    fun cancellationStopsPlaylistPagingWithoutAQueue() = runTest {
        val source = FakeSource(playlist = List(JellyfinSequentialLauncher.PLAYLIST_PAGE_SIZE + 1) { ep("p$it") }, gate = CompletableDeferred())
        val build = async { source.launcher().buildPlaylistQueue(playlist, shuffle = false) }
        runCurrent()
        assertEquals(listOf(0), source.playlistOffsets)
        build.cancel()
        runCurrent()
        assertTrue(build.isCancelled)
        assertEquals(listOf(0), source.playlistOffsets)
    }

    @Test
    fun cancellationDuringCollectionFolderAndShowFetchesYieldsNoQueue() = runTest {
        val gate = CompletableDeferred<Unit>()
        val source = FakeSource(playable = listOf(ep("a")), folder = listOf(item("v", MediaKind.CLIP)), episodes = listOf(ep("a")), gate = gate)
        val launcher = source.launcher()
        val builds = listOf(
            async { launcher.buildCollectionQueue(collection, shuffle = true) },
            async { launcher.buildFolderQueue(item("folder-cancel", MediaKind.FOLDER), shuffle = true) },
            async { launcher.buildShuffledShowQueue(item("show-cancel", MediaKind.SHOW)) },
        )
        runCurrent()
        builds.forEach { it.cancel() }
        gate.complete(Unit)
        runCurrent()
        assertTrue(builds.all { it.isCancelled })
        assertEquals(listOf("col-1"), source.playableCalls)
        assertEquals(listOf("folder-cancel"), source.folderCalls)
        assertEquals(listOf("show-cancel"), source.episodeCalls)
    }
}
