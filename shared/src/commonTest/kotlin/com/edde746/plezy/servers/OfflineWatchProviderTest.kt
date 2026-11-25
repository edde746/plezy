package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class OfflineWatchProviderTest {
    private val queue = InMemoryOfflineWatchQueue()
    private val downloads = FakeOfflineWatchDownloads()
    private val notifier = WatchStateNotifier()
    private var autoRemove = false

    private fun TestScope.provider(): Pair<OfflineWatchProvider, OfflineWatchSyncService> {
        val sync = OfflineWatchSyncService(
            queue = queue,
            downloads = downloads,
            clients = FakeWatchClients(),
            notifier = notifier,
            trackers = RecordingTrackers(),
            thresholds = object : WatchedThresholdSource {
                override fun reportsServerThreshold(client: MediaBackend): Boolean = false
                override fun cachedPercent(serverId: ServerId): Int? = null
            },
            offlineMode = ToggleOfflineMode(offline = true),
            scope = backgroundScope,
            minSyncInterval = Duration.ZERO,
            forceSyncOnResume = false,
            timeSource = testScheduler.timeSource,
        )
        val provider = OfflineWatchProvider(sync, downloads, notifier, backgroundScope, { SpecialsOrdering.SPECIALS_LAST }, { autoRemove })
        return provider to sync
    }

    private fun TestScope.collectEvents(): List<WatchStateEvent> {
        val events = mutableListOf<WatchStateEvent>()
        backgroundScope.launch { notifier.events.collect { events += it } }
        runCurrent()
        return events
    }

    private fun episode(id: String, season: Int, index: Int, viewCount: Int = 0) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        parentId = "season-$season",
        grandparentId = "show-123",
        parentIndex = season,
        index = index,
        viewCount = viewCount,
        serverId = "srv",
    )

    @Test
    fun getNextUnwatchedEpisodeReturnsNullForShowWithNoDownloads() = runTest {
        assertNull(provider().first.getNextUnwatchedEpisode("srv:show-123"))
    }

    @Test
    fun theNextEpisodeIsTheFirstUnwatchedInWatchOrderByLocalActionThenMetadata() = runTest {
        val (provider, sync) = provider()
        val e1 = episode("e1", season = 1, index = 1, viewCount = 1)
        val e2 = episode("e2", season = 1, index = 2)
        val e3 = episode("e3", season = 1, index = 3)
        downloads.episodesByShow["srv:show-123"] = listOf(e3, e2, e1)
        for (e in listOf(e1, e2, e3)) downloads.metadataByKey[e.globalKey] = e

        assertEquals("e2", provider.getNextUnwatchedEpisode("srv:show-123")?.id)

        sync.queueMarkWatched(ServerId("srv"), "e2")
        assertEquals("e3", provider.getNextUnwatchedEpisode("srv:show-123")?.id)

        sync.queueMarkWatched(ServerId("srv"), "e3")
        assertEquals("e1", provider.getNextUnwatchedEpisode("srv:show-123")?.id, "every episode watched: start over")
    }

    @Test
    fun markAsWatchedQueuesAnOfflineActionAndNotifies() = runTest {
        val (provider, sync) = provider()
        val events = collectEvents()
        val metadata = episode("50", season = 1, index = 1)
        downloads.metadataByKey[metadata.globalKey] = metadata

        provider.markAsWatched(ServerId("srv"), "50")
        runCurrent()

        assertEquals(true, sync.getLocalWatchStatus("srv:50"))
        val row = queue.rows.single()
        val event = events.single()
        assertEquals(WatchStateChangeType.WATCHED, event.changeType)
        assertEquals(listOf("season-1", "show-123"), event.parentChain)
        assertEquals(WatchPatchId.offlineAction(null, row.rowId, row.updatedAt), event.patchId)
    }

    @Test
    fun markAsUnwatchedQueuesAnOfflineActionAndNotifies() = runTest {
        val (provider, sync) = provider()
        val events = collectEvents()

        provider.markAsUnwatched(ServerId("srv"), "60")
        runCurrent()

        assertEquals(false, sync.getLocalWatchStatus("srv:60"))
        val event = events.single()
        assertEquals(WatchStateChangeType.UNWATCHED, event.changeType)
        assertTrue(event.parentChain.isEmpty(), "no downloaded metadata: a minimal event")
    }

    @Test
    fun markingWatchedRemovesTheDownloadWhenTheSettingIsOn() = runTest {
        val (provider, _) = provider()
        downloads.removable += listOf("srv:70", "srv:71")

        provider.markAsWatched(ServerId("srv"), "70")
        runCurrent()
        autoRemove = true
        provider.markAsWatched(ServerId("srv"), "71")
        runCurrent()

        assertEquals(listOf("srv:71"), downloads.deleted)
    }
}
