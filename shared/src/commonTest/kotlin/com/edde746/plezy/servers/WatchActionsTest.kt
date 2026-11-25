package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class WatchActionsTest {
    private val queue = InMemoryOfflineWatchQueue()
    private val downloads = FakeOfflineWatchDownloads()
    private val clients = FakeWatchClients()
    private val notifier = WatchStateNotifier()
    private val trackers = RecordingTrackers()
    private val offlineMode = ToggleOfflineMode()

    private val movie = MediaItem(id = "42", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, serverId = "srv", libraryId = "1")

    private fun TestScope.actions(): WatchActions {
        val sync = OfflineWatchSyncService(
            queue, downloads, clients, notifier, trackers,
            thresholds = object : WatchedThresholdSource {
                override fun reportsServerThreshold(client: MediaBackend): Boolean = false
                override fun cachedPercent(serverId: ServerId): Int? = null
            },
            offlineMode = offlineMode,
            scope = backgroundScope,
            minSyncInterval = Duration.ZERO,
            forceSyncOnResume = false,
            timeSource = testScheduler.timeSource,
        )
        val offlineWatch = OfflineWatchProvider(sync, downloads, notifier, backgroundScope, { SpecialsOrdering.SPECIALS_LAST }, { false })
        return WatchActions(clients, offlineMode, offlineWatch, notifier, trackers, backgroundScope)
    }

    private fun TestScope.collectEvents(): List<WatchStateEvent> {
        val events = mutableListOf<WatchStateEvent>()
        backgroundScope.launch { notifier.events.collect { events += it } }
        runCurrent()
        return events
    }

    @Test
    fun anOfflineMarkIsQueuedNotSent() = runTest {
        val actions = actions()
        val client = RecordingBackend("srv", BackendKind.PLEX)
        clients.register(client)
        offlineMode.isOffline.value = true

        assertEquals(WatchMarkOutcome.QUEUED_OFFLINE, actions.setWatched(movie, watched = true))

        assertTrue(client.watched.isEmpty())
        assertEquals(OfflineWatchActionType.WATCHED, queue.latest("srv:42")?.type)
    }

    @Test
    fun anOnlineMarkGoesToTheServerThenOneAcknowledgedEventAndTheTrackers() = runTest {
        val actions = actions()
        val client = RecordingBackend("srv", BackendKind.PLEX)
        clients.register(client)
        val events = collectEvents()

        assertEquals(WatchMarkOutcome.MARKED, actions.setWatched(movie, watched = false))
        runCurrent()

        assertEquals(listOf("42"), client.unwatched)
        val event = events.single()
        assertEquals(WatchStateChangeType.UNWATCHED, event.changeType)
        assertTrue(event.serverAcknowledged)
        assertEquals("srv", event.cacheServerId)
        assertEquals("1", event.librarySectionId)
        assertEquals(listOf("42" to false), trackers.marks)
        assertTrue(queue.rows.isEmpty())
    }

    @Test
    fun aMarkWithoutAServerOrClientIsSkipped() = runTest {
        val actions = actions()

        assertEquals(WatchMarkOutcome.SKIPPED, actions.setWatched(movie, watched = true))
        assertEquals(WatchMarkOutcome.SKIPPED, actions.setWatched(movie.copy(serverId = null), watched = true, offline = true))
    }

    @Test
    fun removingFromContinueWatchingNeedsAClientAndLeavesWatchStateAlone() = runTest {
        val actions = actions()
        assertFailsWith<IllegalStateException> { actions.removeFromContinueWatching(movie) }

        val client = RecordingBackend("srv", BackendKind.PLEX)
        client.removeFromContinueWatchingHandler = {}
        clients.register(client)
        val events = collectEvents()

        actions.removeFromContinueWatching(movie)
        runCurrent()

        assertTrue("removeFromContinueWatching:42" in client.calls)
        assertEquals(WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING, events.single().changeType)
    }

    @Test
    fun aStopMarkOnPlexIsAnExplicitAcknowledgedMark() = runTest {
        val client = RecordingBackend("srv", BackendKind.PLEX)
        val events = collectEvents()

        client.markWatchedFromPlaybackStop(movie, notifier)
        runCurrent()

        assertEquals(listOf("42"), client.watched)
        assertTrue(events.single().serverAcknowledged)
    }

    @Test
    fun externalCompletionOnJellyfinMarksWatchedViaTheStopReportNotMarkWatched() = runTest {
        val client = RecordingBackend("srv", BackendKind.JELLYFIN)
        val events = collectEvents()

        client.markWatchedFromPlaybackStop(movie, notifier)
        runCurrent()

        assertTrue(client.watched.isEmpty(), "no explicit watched mark is sent to the server")
        assertEquals(WatchStateChangeType.WATCHED, events.single().changeType)
        assertFalse(events.single().serverAcknowledged)
    }

    @Test
    fun aDeliveredCrossingMarksWatchedLocallyAndNeverIssuesTheExplicitMark() = runTest {
        val client = RecordingBackend("srv", BackendKind.PLEX)
        val events = collectEvents()

        val patchId = client.notifyWatchedFromPlaybackSession(movie, notifier)
        runCurrent()

        assertNotNull(patchId)
        assertTrue(client.calls.isEmpty(), "a delivered crossing issues no server call")
        assertEquals(patchId, events.single().patchId)
        assertFalse(events.single().serverAcknowledged)
    }
}
