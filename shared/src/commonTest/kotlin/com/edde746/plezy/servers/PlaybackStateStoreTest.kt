package com.edde746.plezy.servers

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LocalPlayQueue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaVersion
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

private fun item(id: String, queueItemId: Int) =
    MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.EPISODE, playQueueItemId = queueItemId, title = "Episode $id")

/** A queue entry with file identity: episodes of one multi-episode file get distinct part ids but share [file]. */
private fun itemWithFile(id: String, queueItemId: Int, file: String) = MediaItem(
    id = id,
    backend = BackendKind.PLEX,
    kind = MediaKind.EPISODE,
    playQueueItemId = queueItemId,
    title = "Episode $id",
    mediaVersions = listOf(MediaVersion(id = "v-$id", parts = listOf(MediaPart(id = "part-$id", file = file)))),
)

private fun queue(
    id: Int = 1,
    selectedItemId: Int? = null,
    shuffled: Boolean = false,
    totalCount: Int? = null,
    size: Int? = null,
    items: List<MediaItem>? = null,
) = ServerPlayQueue(id, selectedItemId, shuffled, totalCount, size, items)

/** Counts state publications after the call. */
@OptIn(ExperimentalCoroutinesApi::class)
private fun TestScope.countUpdates(store: PlaybackStateStore): () -> Int {
    var count = -1
    backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { store.state.collect { count++ } }
    return { count }
}

private data class WindowRequest(val queueId: Int, val center: String?, val window: Int)

private const val FILE_A = "/tv/S02E24-E25.mkv"

class PlaybackStateStoreTest {
    @Test
    fun `starts in idle state with no queue`() {
        val p = PlaybackStateStore()
        assertFalse(p.isQueueActive)
        assertFalse(p.isPlaylistActive)
        assertFalse(p.isShuffleActive)
        assertNull(p.playQueueId)
        assertNull(p.currentPlayQueueItemId)
        assertNull(p.shuffleContextKey)
        assertTrue(p.loadedItems.isEmpty())
    }

    @Test
    fun `setPlaybackFromPlayQueue populates state and notifies`() = runTest {
        val p = PlaybackStateStore()
        val notified = countUpdates(p)
        val items = listOf(item("100", 1001), item("101", 1002), item("102", 1003))

        p.setPlaybackFromPlayQueue(queue(id = 42, selectedItemId = 1002, shuffled = true, totalCount = 3, items = items), "show-key")

        assertEquals(42, p.playQueueId)
        assertEquals(1002, p.currentPlayQueueItemId)
        assertTrue(p.isShuffleActive)
        assertTrue(p.isPlaylistActive)
        assertTrue(p.isQueueActive)
        assertEquals("show-key", p.shuffleContextKey)
        assertEquals(3, p.loadedItems.size)
        assertEquals(1, notified())
    }

    @Test
    fun `totalCount falls back to size then items length`() = runTest {
        val p = PlaybackStateStore()
        val items = listOf(item("a", 1), item("b", 2))
        val requested = mutableListOf<WindowRequest>()
        p.setPlayQueueWindowFetcher { queueId, center, window ->
            requested += WindowRequest(queueId, center, window)
            queue(id = queueId, selectedItemId = 2, totalCount = 7, items = items + item("c", 3))
        }

        // Size is the queue length, so the window is not the end and stepping past it fetches around the anchor.
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 2, size = 7, items = items), null)
        assertEquals("c", p.getNextEpisode("b").item?.id)
        assertEquals(listOf(WindowRequest(1, "2", 50)), requested)

        // Without total and size, the items are the whole queue: 'b' is last and nothing is fetched.
        p.clearShuffle()
        requested.clear()
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 2, items = items), null)
        assertEquals(QueueNavigationStatus.BOUNDARY, p.getNextEpisode("b").status)
        assertTrue(requested.isEmpty())
    }

    @Test
    fun `clearShuffle resets all state and notifies`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(queue(id = 99, selectedItemId = 1, totalCount = 2, items = listOf(item("a", 1), item("b", 2))), "context-1")
        assertTrue(p.isQueueActive)
        val notified = countUpdates(p)

        p.clearShuffle()
        assertFalse(p.isQueueActive)
        assertFalse(p.isPlaylistActive)
        assertFalse(p.isShuffleActive)
        assertNull(p.playQueueId)
        assertNull(p.currentPlayQueueItemId)
        assertNull(p.shuffleContextKey)
        assertTrue(p.loadedItems.isEmpty())
        assertEquals(1, notified())
    }

    @Test
    fun `setCurrentItem updates the cursor only for validated queue members`() = runTest {
        val p = PlaybackStateStore()
        val notified = countUpdates(p)
        p.setCurrentItem(item("a", 1001))
        assertNull(p.currentPlayQueueItemId)
        assertEquals(0, notified())

        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1001, totalCount = 2, items = listOf(item("a", 1001), item("b", 1002))), null)
        val before = notified()

        // A fresh copy of a loaded member is accepted.
        p.setCurrentItem(item("b", 1002))
        assertEquals(1002, p.currentPlayQueueItemId)
        assertEquals(before + 1, notified())

        // A stamped item outside this queue cannot move the cursor.
        p.setCurrentItem(item("outsider", 2002))
        assertEquals(1002, p.currentPlayQueueItemId)
        assertEquals(before + 1, notified())
    }

    @Test
    fun `getNextEpisode returns next loaded item when current is mid window`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1002, totalCount = 3, items = listOf(item("a", 1001), item("b", 1002), item("c", 1003))), null)

        val next = p.getNextEpisode("b")
        assertEquals(QueueNavigationStatus.FOUND, next.status)
        assertEquals("c", next.item!!.id)
        assertEquals(1003, next.item!!.playQueueItemId)
        // Lookups never move the cursor; setCurrentItem does.
        assertEquals(1002, p.currentPlayQueueItemId)
    }

    @Test
    fun `getNextEpisode reports the queue boundary at the end`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1002, totalCount = 2, items = listOf(item("a", 1001), item("b", 1002))), null)

        val next = p.getNextEpisode("b")
        assertEquals(QueueNavigationStatus.BOUNDARY, next.status)
        assertNull(next.item)
    }

    @Test
    fun `getNextEpisode anchors on the supplied media key instead of a stale cursor`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1001, totalCount = 3, items = listOf(item("a", 1001), item("b", 1002), item("c", 1003))), null)

        val next = p.getNextEpisode("b")

        assertEquals(QueueNavigationStatus.FOUND, next.status)
        assertEquals("c", next.item!!.id)
        assertEquals(1001, p.currentPlayQueueItemId)
    }

    @Test
    fun `server window extension uses opaque queue ids and the real anchor`() = runTest {
        val p = PlaybackStateStore()
        val first = item("a", 1001)
        val nextItem = item("b", 9007)
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1001, totalCount = 2, items = listOf(first)), null)
        var requestedCenter: String? = null
        p.setPlayQueueWindowFetcher { queueId, center, _ ->
            requestedCenter = center
            queue(id = queueId, selectedItemId = 1001, totalCount = 2, items = listOf(first, nextItem))
        }

        val next = p.getNextEpisode("a")

        assertEquals("1001", requestedCenter)
        assertEquals(QueueNavigationStatus.FOUND, next.status)
        assertEquals("b", next.item!!.id)
    }

    @Test
    fun `windowed queue confirms its global end with a centered fetch`() = runTest {
        val p = PlaybackStateStore()
        val items = listOf(item("y", 5001), item("z", 9007))
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 9007, totalCount = 100, items = items), null)
        var fetchCount = 0
        p.setPlayQueueWindowFetcher { queueId, center, _ ->
            fetchCount++
            assertEquals("9007", center)
            queue(id = queueId, selectedItemId = 9007, totalCount = 100, items = items)
        }

        assertEquals(QueueNavigationStatus.BOUNDARY, p.getNextEpisode("z").status)
        assertEquals(1, fetchCount)
    }

    @Test
    fun `getNextEpisode does not retry recursively when loaded window misses target`() = runTest {
        val p = PlaybackStateStore()
        val items = listOf(item("a", 1001), item("b", 1002))
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1002, totalCount = 3, items = items), null)
        var fetchCount = 0
        p.setPlayQueueWindowFetcher { queueId, _, _ ->
            fetchCount++
            queue(id = queueId, selectedItemId = 1002, totalCount = 3, items = items)
        }

        assertEquals(QueueNavigationStatus.BOUNDARY, p.getNextEpisode("b").status)
        assertEquals(1, fetchCount)
    }

    @Test
    fun `window fetched for a replaced queue is dropped instead of published`() = runTest {
        val p = PlaybackStateStore()
        val oldItem = item("old-a", 1001)
        p.setPlaybackFromPlayQueue(queue(id = 1, selectedItemId = 1001, totalCount = 2, items = listOf(oldItem)), null)
        val gate = CompletableDeferred<ServerPlayQueue?>()
        p.setPlayQueueWindowFetcher { _, _, _ -> gate.await() }
        val pending = async(start = CoroutineStart.UNDISPATCHED) { p.getNextEpisode("old-a") }

        // A different queue starts while the old queue's window is in flight.
        p.setPlaybackFromPlayQueue(queue(id = 2, selectedItemId = 2001, totalCount = 1, items = listOf(item("new-a", 2001))), null)
        val notified = countUpdates(p)
        gate.complete(queue(id = 1, selectedItemId = 1001, shuffled = true, totalCount = 2, items = listOf(oldItem, item("old-b", 1002))))
        val next = pending.await()

        assertEquals(QueueNavigationStatus.FAILED, next.status)
        assertEquals(listOf("new-a"), p.loadedItems.map { it.id })
        assertFalse(p.isShuffleActive)
        assertEquals(0, notified())
    }

    @Test
    fun `window fetched for a cleared queue is dropped instead of reviving it`() = runTest {
        val p = PlaybackStateStore()
        val first = item("a", 1001)
        p.setPlaybackFromPlayQueue(queue(id = 1, selectedItemId = 1001, totalCount = 2, items = listOf(first)), null)
        val gate = CompletableDeferred<ServerPlayQueue?>()
        p.setPlayQueueWindowFetcher { _, _, _ -> gate.await() }
        val pending = async(start = CoroutineStart.UNDISPATCHED) { p.getNextEpisode("a") }

        p.clearShuffle()
        gate.complete(queue(id = 1, selectedItemId = 1001, totalCount = 2, items = listOf(first, item("b", 1002))))
        val next = pending.await()

        assertEquals(QueueNavigationStatus.FAILED, next.status)
        assertFalse(p.isQueueActive)
        assertTrue(p.loadedItems.isEmpty())
    }

    @Test
    fun `getNextEpisode reports unavailable with no active queue`() = runTest {
        val next = PlaybackStateStore().getNextEpisode("any-key")
        assertEquals(QueueNavigationStatus.UNAVAILABLE, next.status)
        assertNull(next.item)
    }

    @Test
    fun `getPreviousEpisode returns previous loaded item when current is mid window`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1002, totalCount = 3, items = listOf(item("a", 1001), item("b", 1002), item("c", 1003))), null)

        val previous = p.getPreviousEpisode("b")
        assertEquals(QueueNavigationStatus.FOUND, previous.status)
        assertEquals("a", previous.item!!.id)
        assertEquals(1001, previous.item!!.playQueueItemId)
    }

    @Test
    fun `getPreviousEpisode at index 0 returns null`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1001, totalCount = 2, items = listOf(item("a", 1001), item("b", 1002))), null)

        val previous = p.getPreviousEpisode("a")
        assertEquals(QueueNavigationStatus.BOUNDARY, previous.status)
        assertNull(previous.item)
    }

    @Test
    fun `getPreviousEpisode without queue mode returns null`() = runTest {
        val previous = PlaybackStateStore().getPreviousEpisode("any-key")
        assertEquals(QueueNavigationStatus.UNAVAILABLE, previous.status)
        assertNull(previous.item)
    }

    @Test
    fun `playQueueItemIdFor returns synthetic ids for Jellyfin local queue items`() {
        // The player keeps a launcher-set queue only for its members; a null id here would replace a playlist queue
        // with the show's episodes.
        val p = PlaybackStateStore()
        val ep1 = MediaItem(id = "ep1", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE)
        val ep2 = MediaItem(id = "ep2", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE)
        val outsider = MediaItem(id = "ep-other", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE)

        p.setPlaybackFromLocalQueue(LocalPlayQueue(items = listOf(ep1, ep2), currentIndex = 0), contextKey = "playlist-X")

        assertEquals(0, p.playQueueItemIdFor(ep1))
        assertEquals(1, p.playQueueItemIdFor(ep2))
        assertNull(p.playQueueItemIdFor(outsider))
        assertTrue(p.isItemInActiveQueue(ep1))
        assertFalse(p.isItemInActiveQueue(outsider))
    }

    @Test
    fun `isItemInActiveQueue keeps Plex playlist and collection queues alive`() {
        val p = PlaybackStateStore()
        val inQueue = item("ep-in-playlist", 5001)
        // An item opened outside a queue carries no queue item id.
        val outsider = MediaItem(id = "ep-different-show", backend = BackendKind.PLEX, kind = MediaKind.EPISODE)

        // The context key is the playlist id, unrelated to any item's show.
        p.setPlaybackFromPlayQueue(
            queue(id = 77, selectedItemId = 5001, totalCount = 2, items = listOf(inQueue, item("ep-other-in-playlist", 5002))),
            "playlist-Z",
        )

        assertTrue(p.isItemInActiveQueue(inQueue))
        assertFalse(p.isItemInActiveQueue(outsider))
    }

    @Test
    fun `isItemInActiveQueue rejects foreign server stamped queue items`() {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(queue(id = 77, selectedItemId = 5001, totalCount = 1, items = listOf(item("ep-in-queue", 5001))), "playlist-Z")

        assertTrue(p.isItemInActiveQueue(item("ep-in-queue", 5001)))
        assertFalse(p.isItemInActiveQueue(item("foreign", 9001)))
        assertFalse(p.isItemInActiveQueue(item("foreign", 5001)))
    }

    @Test
    fun `isItemInActiveQueue is false when no queue is active`() {
        val p = PlaybackStateStore()
        assertFalse(p.isQueueActive)
        assertFalse(p.isItemInActiveQueue(item("ep1", 1)))
    }

    // Multi-episode files: e24 and e25 share a file; e23 and e26 don't.
    private fun multiEpisodeQueue(selectedItemId: Int = 1002) = PlaybackStateStore().apply {
        setPlaybackFromPlayQueue(
            queue(
                selectedItemId = selectedItemId,
                totalCount = 4,
                items = listOf(
                    itemWithFile("e23", 1001, "/tv/S02E23.mkv"),
                    itemWithFile("e24", 1002, FILE_A),
                    itemWithFile("e25", 1003, FILE_A),
                    itemWithFile("e26", 1004, "/tv/S02E26-E27.mkv"),
                ),
            ),
            null,
        )
    }

    @Test
    fun `getNextEpisode skips the same file sibling using playedPartId`() = runTest {
        val next = multiEpisodeQueue().getNextEpisode("e24", playedPartId = "part-e24")
        assertEquals(QueueNavigationStatus.FOUND, next.status)
        assertEquals("e26", next.item!!.id)
    }

    @Test
    fun `getNextEpisode skips the same file sibling via file intersection without playedPartId`() = runTest {
        val next = multiEpisodeQueue().getNextEpisode("e24")
        assertEquals(QueueNavigationStatus.FOUND, next.status)
        assertEquals("e26", next.item!!.id)
    }

    @Test
    fun `getNextEpisode skips multiple siblings of a triple episode file`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(
            queue(
                selectedItemId = 1001,
                totalCount = 4,
                items = listOf(
                    itemWithFile("e1", 1001, FILE_A),
                    itemWithFile("e2", 1002, FILE_A),
                    itemWithFile("e3", 1003, FILE_A),
                    itemWithFile("e4", 1004, "/tv/S02E26-E27.mkv"),
                ),
            ),
            null,
        )

        val next = p.getNextEpisode("e1", playedPartId = "part-e1")
        assertEquals(QueueNavigationStatus.FOUND, next.status)
        assertEquals("e4", next.item!!.id)
    }

    @Test
    fun `getNextEpisode returns null when only same file siblings remain`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(
            queue(selectedItemId = 1001, totalCount = 2, items = listOf(itemWithFile("e24", 1001, FILE_A), itemWithFile("e25", 1002, FILE_A))),
            null,
        )

        assertEquals(QueueNavigationStatus.BOUNDARY, p.getNextEpisode("e24", playedPartId = "part-e24").status)
    }

    @Test
    fun `items without file data keep positional behavior even with playedPartId`() = runTest {
        val p = PlaybackStateStore()
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1001, totalCount = 2, items = listOf(item("a", 1001), item("b", 1002))), null)

        val next = p.getNextEpisode("a", playedPartId = "part-a")
        assertEquals(QueueNavigationStatus.FOUND, next.status)
        assertEquals("b", next.item!!.id)
    }

    @Test
    fun `skip past the loaded window extends it and lands on the next distinct file`() = runTest {
        val p = PlaybackStateStore()
        val windowItems = listOf(itemWithFile("e24", 1001, FILE_A), itemWithFile("e25", 1002, FILE_A))
        p.setPlaybackFromPlayQueue(queue(selectedItemId = 1001, totalCount = 3, items = windowItems), null)
        var fetchCount = 0
        p.setPlayQueueWindowFetcher { queueId, _, _ ->
            fetchCount++
            queue(id = queueId, selectedItemId = 1001, totalCount = 3, items = windowItems + itemWithFile("e26", 1003, "/tv/S02E26-E27.mkv"))
        }

        val next = p.getNextEpisode("e24", playedPartId = "part-e24")
        assertEquals(QueueNavigationStatus.FOUND, next.status)
        assertEquals("e26", next.item!!.id)
        assertEquals(1, fetchCount)
    }

    @Test
    fun `getPreviousEpisode collapses to the first episode of the same file group`() = runTest {
        // From e26 the previous file is e24-e25, entered at e24.
        val previous = multiEpisodeQueue(selectedItemId = 1004).getPreviousEpisode("e26", playedPartId = "part-e26")
        assertEquals(QueueNavigationStatus.FOUND, previous.status)
        assertEquals("e24", previous.item!!.id)
    }

    @Test
    fun `getPreviousEpisode skips same file siblings of the playing item`() = runTest {
        val previous = multiEpisodeQueue(selectedItemId = 1003).getPreviousEpisode("e25", playedPartId = "part-e25")
        assertEquals(QueueNavigationStatus.FOUND, previous.status)
        assertEquals("e23", previous.item!!.id)
    }

    @Test
    fun `sameFileSiblings returns the other episodes of the playing file`() {
        val p = multiEpisodeQueue()
        assertEquals(listOf("e25"), p.sameFileSiblings(p.loadedItems[1], playedPartId = "part-e24").map { it.id })
        assertTrue(p.sameFileSiblings(p.loadedItems.first(), playedPartId = "part-e23").isEmpty())
    }

    @Test
    fun `sameFileSiblings is empty without an active queue`() {
        assertTrue(PlaybackStateStore().sameFileSiblings(itemWithFile("e24", 1, FILE_A), playedPartId = "part-e24").isEmpty())
    }
}
