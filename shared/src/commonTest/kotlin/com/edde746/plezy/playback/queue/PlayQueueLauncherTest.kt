package com.edde746.plezy.playback.queue

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.jellyfin.JellyfinSequentialLauncher
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.TEST_SERVER_ID
import com.edde746.plezy.plex.jsonResponse
import com.edde746.plezy.plex.testPlexClient
import com.edde746.plezy.servers.PlaybackStateStore
import com.edde746.plezy.strings.T
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

class PlayQueueLauncherTest {
    private val playback = PlaybackStateStore()
    private val played = mutableListOf<Pair<MediaItem, Boolean>>()

    /** One request to the Plex server: its method and path, and its query. */
    private data class Request(val call: String, val params: Map<String, String?>)

    private val requests = mutableListOf<Request>()

    private fun plex(handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData): PlexClient = testPlexClient(
        { request ->
            requests += Request("${request.method.value} ${request.url.encodedPath}", request.url.parameters.names().associateWith { request.url.parameters[it] })
            handler(request)
        },
        machineIdentifier = "machine-1",
    )

    private fun TestScope.launcher(
        vararg clients: MediaBackend,
        startsFromBeginning: Boolean = false,
        play: suspend (MediaItem, Boolean) -> Unit = { item, resolve -> played += item to resolve },
        mediaBrowserQueues: (MediaBackend) -> JellyfinSequentialLauncher? = { null },
    ) = PlayQueueLauncher(this, FakeServers(*clients), playback, { startsFromBeginning }, play, mediaBrowserQueues)

    private fun entry(id: String, queueItemId: Int = 41, type: String = "movie", viewOffset: Long? = null) =
        """{"playQueueItemID":$queueItemId,"ratingKey":"$id","type":"$type"${viewOffset?.let { ",\"viewOffset\":$it" }.orEmpty()}}"""

    private fun queueJson(vararg entries: String, shuffled: Boolean = false, selected: Int = 41) =
        """{"MediaContainer":{"playQueueID":73,"playQueueVersion":1,"playQueueSelectedItemID":$selected,""" +
            """"playQueueShuffled":${if (shuffled) 1 else 0},"playQueueTotalCount":${entries.size},"Metadata":[${entries.joinToString(",")}]}}"""

    private val plexPlaylist = MediaPlaylist(id = "12", backend = BackendKind.PLEX, title = "Playlist", playlistType = "video")

    // Guards.

    @Test
    fun shufflingAnythingButAShowOrSeasonFails() = runTest {
        val result = launcher(plex { jsonResponse(queueJson(entry("ep"))) })
            .launchShuffledShow(MediaItem(id = "rk1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE)).await()

        assertIs<PlayQueueResult.Error>(result)
        assertTrue("shows and seasons" in result.cause.message.orEmpty())
        assertTrue(requests.isEmpty())
    }

    @Test
    fun launchingACollectionThatIsNoCollectionFails() = runTest {
        val result = launcher(plex { jsonResponse(queueJson(entry("ep"))) })
            .launchCollection(MediaItem(id = "m", backend = BackendKind.PLEX, kind = MediaKind.MOVIE), shuffle = false).await()

        assertIs<PlayQueueResult.Error>(result)
        assertTrue("collection or playlist" in result.cause.message.orEmpty())
    }

    // Plex queues.

    @Test
    fun queuesTheWholeSectionShuffledAndPlaysItsHead() = runTest {
        val client = plex { jsonResponse(queueJson(entry("ep-9", type = "episode"), shuffled = true)) }
        val library = MediaLibrary(id = "2", backend = BackendKind.PLEX, title = "TV Shows", kind = MediaKind.SHOW, serverId = TEST_SERVER_ID)

        val result = launcher(client).launchShuffledLibrary(library).await()

        assertEquals(PlayQueueResult.Success, result)
        // The server expands a section's shows to their episodes; one URI covers movie and show libraries.
        val create = requests.single()
        assertEquals("POST /playQueues", create.call)
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/sections/2/all", create.params["uri"])
        assertEquals("1", create.params["shuffle"])
        assertEquals(73, playback.playQueueId)
        assertEquals("ep-9", played.single().first.id)
        assertEquals("2", played.single().first.libraryId)
    }

    @Test
    fun aLibraryShuffleNeverFallsBackToAnotherServer() = runTest {
        val library = MediaLibrary(id = "2", backend = BackendKind.PLEX, title = "Movies", kind = MediaKind.MOVIE, serverId = "elsewhere")

        val result = launcher(plex { jsonResponse(queueJson(entry("m"))) }).launchShuffledLibrary(library).await()

        assertIs<PlayQueueResult.Error>(result)
        assertEquals(T.errors.noClientAvailable, result.message)
        assertTrue(requests.isEmpty())
    }

    @Test
    fun publishesThePlexQueueBeforeNavigatingToItsSelectedItem() = runTest {
        val client = plex { jsonResponse(queueJson(entry("movie-1"))) }
        val launcher = launcher(client, play = { selected, resolve ->
            assertTrue(playback.isQueueActive)
            assertEquals(73, playback.playQueueId)
            assertEquals(selected, playback.currentQueueItem)
            assertEquals(listOf(selected), playback.loadedItems)
            played += selected to resolve
        })

        val result = launcher.launchPlaylist(plexPlaylist, shuffle = false).await()

        assertEquals(PlayQueueResult.Success, result)
        assertEquals("movie-1", played.single().first.id)
        assertTrue(played.single().second, "the item's watch state is resolved again")
        assertEquals("12", requests.single().params["playlistID"])
        assertEquals("video", requests.single().params["type"])
    }

    @Test
    fun noPlexServerAtAllFailsWithNoClientAvailable() = runTest {
        val result = launcher().launchPlaylist(plexPlaylist, shuffle = false).await()

        assertIs<PlayQueueResult.Error>(result)
        assertEquals(T.errors.noClientAvailable, result.message)
    }

    @Test
    fun cancellingTheLoadingDialogStopsTheLaunchBeforeItPublishesOrNavigates() = runTest {
        val entered = CompletableDeferred<Unit>()
        val gate = CompletableDeferred<Unit>()
        val client = plex {
            entered.complete(Unit)
            gate.await()
            jsonResponse(queueJson(entry("movie-1")))
        }

        val launch = launcher(client).launchPlaylist(plexPlaylist, shuffle = false)
        entered.await()
        assertTrue(launch.loading.value)
        launch.cancel()
        gate.complete(Unit)

        assertEquals(PlayQueueResult.Cancelled, launch.await())
        assertEquals(null, launch.await().message)
        assertFalse(launch.loading.value)
        assertFalse(playback.isQueueActive)
        assertTrue(played.isEmpty())
    }

    @Test
    fun navigationFailureIsReturnedAsAnErrorNotSuccess() = runTest {
        val failure = IllegalStateException("navigation failed")
        val client = plex { jsonResponse(queueJson(entry("movie-1"))) }

        val launch = launcher(client, play = { _, _ -> throw failure }).launchPlaylist(plexPlaylist, shuffle = false)
        val result = launch.await()

        assertIs<PlayQueueResult.Error>(result)
        assertSame(failure, result.cause)
        assertEquals(T.messages.failedPlayback(action = T.common.play, error = localizedErrorReason(failure)), result.message)
        assertTrue(playback.isQueueActive)
        assertEquals("movie-1", playback.currentQueueItem?.id)
    }

    @Test
    fun theLoadingDialogNamesTheChosenAction() = runTest {
        val client = plex { jsonResponse(queueJson(entry("movie-1"))) }
        val launcher = launcher(client)

        val sequential = launcher.launchPlaylist(plexPlaylist, shuffle = false)
        val shuffled = launcher.launchPlaylist(plexPlaylist, shuffle = true)

        assertEquals(T.common.play, sequential.title)
        assertEquals(T.common.shuffle, shuffled.title)
        assertEquals(PlayQueueResult.Success, sequential.await())
        assertEquals(PlayQueueResult.Success, shuffled.await())
    }

    @Test
    fun aShuffledLaunchStripsTheLaunchedItemsResumeOffsetWhenThePrefIsOn() = runTest {
        val client = plex { jsonResponse(queueJson(entry("ep-1", type = "episode", viewOffset = 120_000), shuffled = true)) }

        val result = launcher(client, startsFromBeginning = true).launchPlaylist(plexPlaylist, shuffle = true).await()

        assertEquals(PlayQueueResult.Success, result)
        assertEquals(0L, played.single().first.viewOffsetMs)
        assertFalse(played.single().second, "the watch state is not resolved again, which would restore the offset")
        // The queue keeps the server's offset; only the launched copy is stripped.
        assertEquals(120_000L, playback.loadedItems.single().viewOffsetMs)
    }

    @Test
    fun aShuffledLaunchKeepsTheResumeOffsetWhenThePrefIsOff() = runTest {
        val client = plex { jsonResponse(queueJson(entry("ep-1", type = "episode", viewOffset = 120_000), shuffled = true)) }

        launcher(client).launchPlaylist(plexPlaylist, shuffle = true).await()

        assertEquals(120_000L, played.single().first.viewOffsetMs)
    }

    @Test
    fun aSequentialLaunchKeepsTheResumeOffsetEvenWithThePrefOn() = runTest {
        val client = plex { jsonResponse(queueJson(entry("ep-1", type = "episode", viewOffset = 120_000))) }

        launcher(client, startsFromBeginning = true).launchPlaylist(plexPlaylist, shuffle = false).await()

        assertEquals(120_000L, played.single().first.viewOffsetMs)
        assertTrue(played.single().second)
    }

    @Test
    fun aCollectionQueueStartsAtTheChosenItem() = runTest {
        val client = plex { jsonResponse(queueJson(entry("first", queueItemId = 40), entry("chosen", queueItemId = 41), selected = 41)) }
        val collection = MediaItem(
            id = "c-5", backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, serverId = TEST_SERVER_ID, libraryId = "3", libraryTitle = "Films",
        )

        val result = launcher(client).launchCollection(collection, shuffle = false, startItem = MediaItem(id = "chosen", backend = BackendKind.PLEX, kind = MediaKind.MOVIE)).await()

        assertEquals(PlayQueueResult.Success, result)
        val create = requests.single().params
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/collections/c-5", create["uri"])
        assertEquals("/library/metadata/chosen", create["key"])
        assertEquals("0", create["shuffle"])
        assertEquals("chosen", played.single().first.id)
        assertEquals("c-5", playback.shuffleContextKey)
    }

    @Test
    fun aShuffledCollectionIgnoresTheStartItemAndPlaysTheHead() = runTest {
        val client = plex { jsonResponse(queueJson(entry("head", queueItemId = 40), entry("other", queueItemId = 41), shuffled = true, selected = 41)) }
        val collection = MediaItem(id = "c-5", backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, serverId = TEST_SERVER_ID)

        launcher(client).launchCollection(collection, shuffle = true, startItem = MediaItem(id = "other", backend = BackendKind.PLEX, kind = MediaKind.MOVIE)).await()

        assertEquals(null, requests.single().params["key"])
        assertEquals("1", requests.single().params["shuffle"])
        assertEquals("head", played.single().first.id)
    }

    @Test
    fun anEmptyCreatedQueueIsReadAgainByItsId() = runTest {
        val client = plex { request ->
            if (request.method.value == "POST") jsonResponse(queueJson()) else jsonResponse(queueJson(entry("late")))
        }
        val folder = MediaItem(id = "f", backend = BackendKind.PLEX, kind = MediaKind.FOLDER, serverId = TEST_SERVER_ID, backendFolderKey = "/library/sections/1/folder?parent=9")

        val result = launcher(client).launchFolder(folder, shuffle = false).await()

        assertEquals(PlayQueueResult.Success, result)
        assertEquals(listOf("POST /playQueues", "GET /playQueues/73"), requests.map { it.call })
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/sections/1/folder?parent=9", requests.first().params["uri"])
        assertEquals("late", played.single().first.id)
        assertEquals("/library/sections/1/folder?parent=9", playback.shuffleContextKey)
    }

    @Test
    fun aQueueStillEmptyAfterTheSecondReadIsEmpty() = runTest {
        val client = plex { jsonResponse(queueJson()) }

        val result = launcher(client).launchPlaylist(plexPlaylist, shuffle = false).await()

        assertEquals(PlayQueueResult.Empty, result)
        assertEquals(T.messages.failedToCreatePlayQueueNoItems, result.message)
        assertFalse(playback.isQueueActive)
        assertTrue(played.isEmpty())
    }

    @Test
    fun aFolderWithoutItsFolderKeyFails() = runTest {
        val folder = MediaItem(id = "f", backend = BackendKind.PLEX, kind = MediaKind.FOLDER, serverId = TEST_SERVER_ID)

        val result = launcher(plex { jsonResponse(queueJson(entry("m"))) }).launchFolder(folder, shuffle = true).await()

        assertIs<PlayQueueResult.Error>(result)
        assertTrue(requests.isEmpty())
    }

    @Test
    fun aShuffledSeasonQueuesItsShowAndStampsTheServerOnTheItemPlayed() = runTest {
        val client = plex { jsonResponse(queueJson(entry("ep-4", type = "episode"), shuffled = true)) }
        val season = MediaItem(
            id = "season-2", backend = BackendKind.PLEX, kind = MediaKind.SEASON, parentId = "show-1",
            serverId = TEST_SERVER_ID, serverName = "Home", libraryId = "2", libraryTitle = "TV Shows",
        )

        val result = launcher(client).launchShuffledShow(season).await()

        assertEquals(PlayQueueResult.Success, result)
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/metadata/show-1/allLeaves", requests.single().params["uri"])
        assertEquals("1", requests.single().params["shuffle"])
        val item = played.single().first
        assertEquals(TEST_SERVER_ID, item.serverId)
        assertEquals("Home", item.serverName)
        assertEquals("2", item.libraryId)
        assertEquals("show-1", playback.shuffleContextKey)
    }

    // Jellyfin and Emby: local queues.

    private class MediaBrowserSource(val playlist: List<MediaItem> = emptyList(), val episodes: List<MediaItem> = emptyList()) {
        fun launcher() = JellyfinSequentialLauncher(
            fetchPlaylistPage = { _, start, size -> LibraryPage(playlist.drop(start).take(size), playlist.size, start) },
            fetchPlayableDescendants = { emptyList() },
            fetchPlayableFolderDescendants = { emptyList() },
            fetchClientSideEpisodeQueue = { episodes },
            fetchRandomLibraryVideos = { _, _ -> emptyList() },
            random = Random(1),
        )
    }

    private val jfPlaylist = MediaPlaylist(id = "pl-1", backend = BackendKind.JELLYFIN, title = "Mix", playlistType = "video", serverId = "srv-jf")

    @Test
    fun aMediaBrowserPlaylistPlaysAsALocalQueueWithoutAServerQueue() = runTest {
        val items = listOf(jfMovie("a"), jfMovie("b"), jfMovie("c"))
        val source = MediaBrowserSource(playlist = items)

        val result = launcher(SeriesBackend(), mediaBrowserQueues = { source.launcher() })
            .launchPlaylist(jfPlaylist, shuffle = false, startItem = items[1]).await()

        assertEquals(PlayQueueResult.Success, result)
        assertEquals(items, playback.loadedItems)
        assertEquals("pl-1", playback.shuffleContextKey)
        assertEquals(1, playback.currentPlayQueueItemId)
        assertEquals(items[1] to false, played.single())
        assertTrue(requests.isEmpty())
    }

    @Test
    fun aShuffledLocalQueueHoldsTheStrippedItemItLaunches() = runTest {
        val episodes = listOf(jfEpisode("e1", "series-A").copy(viewOffsetMs = 5_000), jfEpisode("e2", "series-A").copy(viewOffsetMs = 7_000))
        val source = MediaBrowserSource(episodes = episodes)
        val show = MediaItem(id = "series-A", backend = BackendKind.JELLYFIN, kind = MediaKind.SHOW, serverId = "srv-jf")

        val result = launcher(SeriesBackend(), startsFromBeginning = true, mediaBrowserQueues = { source.launcher() }).launchShuffledShow(show).await()

        assertEquals(PlayQueueResult.Success, result)
        val launched = played.single().first
        assertEquals(0L, launched.viewOffsetMs)
        assertTrue(playback.isItemInActiveQueue(launched), "the queue holds the launched copy, so the player keeps the queue")
        assertTrue(playback.isShuffleActive)
        assertEquals("series-A", playback.shuffleContextKey)
    }

    @Test
    fun anEmptyLocalQueueIsEmpty() = runTest {
        val result = launcher(SeriesBackend(), mediaBrowserQueues = { MediaBrowserSource().launcher() }).launchPlaylist(jfPlaylist, shuffle = true).await()

        assertEquals(PlayQueueResult.Empty, result)
        assertFalse(playback.isQueueActive)
    }

    @Test
    fun aMediaBrowserItemWithoutItsServerFails() = runTest {
        val result = launcher(SeriesBackend(), mediaBrowserQueues = { MediaBrowserSource().launcher() })
            .launchPlaylist(jfPlaylist.copy(serverId = null), shuffle = false).await()

        assertIs<PlayQueueResult.Error>(result)
    }
}
