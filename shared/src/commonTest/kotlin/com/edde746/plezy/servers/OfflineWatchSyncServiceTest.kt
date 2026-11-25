package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class OfflineWatchSyncServiceTest {
    private val queue = InMemoryOfflineWatchQueue()
    private val downloads = FakeOfflineWatchDownloads()
    private val clients = FakeWatchClients()
    private val notifier = WatchStateNotifier()
    private val trackers = RecordingTrackers()
    private val offlineMode = ToggleOfflineMode()
    private var cachedThresholdPercent: Int? = null
    private val thresholds = object : WatchedThresholdSource {
        override fun reportsServerThreshold(client: MediaBackend): Boolean = false
        override fun cachedPercent(serverId: ServerId): Int? = cachedThresholdPercent
    }

    private val srv = ServerId("srv")
    private val jf = ServerId("jf-machine")
    private val plex = ServerId("plex-machine")
    private val emby = ServerId("emby-machine")

    private fun TestScope.service(
        minSyncInterval: Duration = Duration.ZERO,
        forceSyncOnResume: Boolean = false,
        trackers: ProfileTrackerWatchMarks = this@OfflineWatchSyncServiceTest.trackers,
    ) = OfflineWatchSyncService(
        queue = queue,
        downloads = downloads,
        clients = clients,
        notifier = notifier,
        trackers = trackers,
        thresholds = thresholds,
        offlineMode = offlineMode,
        scope = backgroundScope,
        minSyncInterval = minSyncInterval,
        forceSyncOnResume = forceSyncOnResume,
        timeSource = testScheduler.timeSource,
    )

    private fun jellyfinUser(userId: String) = RecordingBackend("jf-machine", BackendKind.JELLYFIN, scopeId = "jf-machine/$userId")

    private fun embyUser(userId: String) = RecordingBackend("emby-machine", BackendKind.EMBY, scopeId = "emby-machine/$userId")

    private fun plexProfileClient(profileId: String) =
        RecordingBackend("plex-machine", BackendKind.PLEX, scopeId = PlexProfileScopeId.of(plex, profileId).value)

    private fun movie(id: String, serverId: String = "srv") = MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, serverId = serverId)

    // Initial state.

    @Test
    fun aFreshlyConstructedServiceHasNoPendingCount() = runTest {
        val svc = service()

        assertEquals(0, svc.getPendingSyncCount())
        assertNull(svc.getLocalWatchStatus("srv:nonexistent"))
    }

    @Test
    fun isWatchedByProgressIsPureMath() = runTest {
        val svc = service()

        assertFalse(svc.isWatchedByProgress(0, 0))
        assertFalse(svc.isWatchedByProgress(1000, 0))
        assertFalse(svc.isWatchedByProgress(89, 100))
        assertTrue(svc.isWatchedByProgress(90, 100))
        assertTrue(svc.isWatchedByProgress(95, 100))
        assertTrue(svc.isWatchedByProgress(100, 100))
    }

    @Test
    fun getWatchedThresholdFallsBackToDefaultWhenNoClientAndNoSettings() = runTest {
        assertEquals(0.9, service().getWatchedThreshold(ServerId("unknown-server")))
    }

    @Test
    fun getWatchedThresholdUsesTheMediaBrowserClientElseTheStoredPlexSetting() = runTest {
        val svc = service()
        cachedThresholdPercent = 80
        assertEquals(0.8, svc.getWatchedThreshold(plex), "no client: the stored setting")

        clients.register(plexProfileClient("p1").apply { watchedThreshold = 0.5 })
        assertEquals(0.8, svc.getWatchedThreshold(plex), "prefs not loaded: the stored setting still")

        clients.register(jellyfinUser("user-a").apply { watchedThreshold = 0.9 })
        assertEquals(0.9, svc.getWatchedThreshold(jf))
    }

    // Queueing marks.

    @Test
    fun queueMarkWatchedPersistsAWatchedActionAndBumpsPendingCount() = runTest {
        val svc = service()

        svc.queueMarkWatched(srv, "42")

        assertEquals(1, svc.getPendingSyncCount())
        val action = queue.latest("srv:42")!!
        assertEquals(OfflineWatchActionType.WATCHED, action.type)
        assertEquals(srv, action.serverId)
        assertEquals("42", action.itemId)
    }

    @Test
    fun queueMarkUnwatchedPersistsAnUnwatchedAction() = runTest {
        service().queueMarkUnwatched(srv, "42")

        assertEquals(OfflineWatchActionType.UNWATCHED, queue.latest("srv:42")?.type)
    }

    // Replay.

    @Test
    fun serverUnavailableKeepsQueuedActionWithoutConsumingAttempts() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        svc.queueMarkWatched(srv, "42")

        svc.syncPendingItems()

        val action = queue.latest("srv:42")!!
        assertEquals(0, action.syncAttempts)
        assertNull(action.lastError)
    }

    @Test
    fun maxAttemptActionIsRetainedForExplicitCleanupInsteadOfDeleted() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = RecordingBackend("srv", BackendKind.PLEX)
        clients.register(client)
        svc.queueMarkWatched(srv, "42")
        repeat(OfflineWatchSyncService.MAX_SYNC_ATTEMPTS) {
            val action = queue.latest("srv:42")!!
            queue.recordFailedAttemptIfUnchanged(action.rowId, action.updatedAt, "server error")
        }

        svc.syncPendingItems()

        val retained = queue.latest("srv:42")!!
        assertEquals(OfflineWatchSyncService.MAX_SYNC_ATTEMPTS, retained.syncAttempts)
        assertEquals("server error", retained.lastError)
        assertTrue(client.watched.isEmpty())
    }

    @Test
    fun partialPlexOfflineProgressReplaysAsOfflineStoppedProgress() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = RecordingBackend("srv", BackendKind.PLEX)
        clients.register(client)
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 50_000, durationMs = 100_000)
        val queued = queue.latest("srv:42")!!

        svc.syncPendingItems()

        assertEquals(listOf(50_000L), client.started.map { it.positionMs })
        assertEquals(listOf(50_000L), client.stopped.map { it.positionMs })
        val report = client.stopped.single().report!!
        assertTrue(report.isOfflineReplay)
        assertEquals(queued.updatedAt, report.recordedAt?.toEpochMilliseconds())
        assertTrue(client.watched.isEmpty())
        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun unknownDurationOfflineProgressStillReplaysStoppedPosition() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = RecordingBackend("srv", BackendKind.PLEX)
        clients.register(client)
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 50_000, durationMs = null)

        svc.syncPendingItems()

        assertEquals(listOf(RecordingBackend.Report("42", 50_000, null)), client.started)
        assertEquals(50_000L, client.stopped.single().positionMs)
        assertNull(client.stopped.single().durationMs)
        assertTrue(client.watched.isEmpty())
        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun completedPlexOfflineProgressReplaysAtDurationAndMarksWatched() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = RecordingBackend("srv", BackendKind.PLEX)
        clients.register(client)
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 95_000, durationMs = 100_000)
        val queued = queue.latest("srv:42")!!

        svc.syncPendingItems()

        assertTrue(client.started.isEmpty())
        val stopped = client.stopped.single()
        assertEquals(100_000L, stopped.positionMs)
        assertEquals(100_000L, stopped.durationMs)
        assertTrue(stopped.report!!.isOfflineReplay)
        assertEquals(false, stopped.report.willContinue)
        assertEquals(queued.updatedAt, stopped.report.recordedAt?.toEpochMilliseconds())
        assertEquals(listOf("42"), client.watched)
        assertEquals(listOf("42" to true), trackers.marks)
        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun completedJellyfinOfflineProgressMarksWatchedViaTheStopReportNotMarkWatched() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = RecordingBackend("srv", BackendKind.JELLYFIN)
        clients.register(client)
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 95_000, durationMs = 100_000)

        svc.syncPendingItems()

        assertEquals(100_000L, client.stopped.single().positionMs)
        assertTrue(client.watched.isEmpty(), "a second mark would double-scrobble through the Jellyfin Trakt plugin")
        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun aMediaBrowserReplayWhoseStartedReportFailsStaysQueuedWithAnAttempt() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = RecordingBackend("srv", BackendKind.JELLYFIN)
        client.playbackStartedHandler = { _, _, _ -> throw IllegalStateException("no session") }
        clients.register(client)
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 50_000, durationMs = 100_000)

        svc.syncPendingItems()

        val action = queue.latest("srv:42")!!
        assertEquals(1, action.syncAttempts)
        assertEquals("write did not persist", action.lastError)
    }

    @Test
    fun aReplayedActionIsDeletedAndItsOfflinePatchPromoted() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        clients.register(RecordingBackend("srv", BackendKind.PLEX))
        val promotions = mutableListOf<WatchPatchPromotion>()
        backgroundScope.launch { notifier.promotions.collect { promotions += it } }
        runCurrent()
        val queued = svc.queueMarkWatched(srv, "42")

        svc.syncPendingItems()
        runCurrent()

        assertNull(queue.latest("srv:42"))
        assertEquals(listOf(WatchPatchPromotion(WatchPatchId.offlineAction("p1", queued.rowId, queued.revision))), promotions)
    }

    // Profile scoping.

    @Test
    fun defersEntirelyWhenNoProfileIsActive() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = RecordingBackend("srv", BackendKind.PLEX)
        clients.register(client)
        svc.queueMarkWatched(srv, "42")

        svc.setActiveProfileId(null)
        svc.syncPendingItems()

        assertTrue(client.watched.isEmpty())
        assertEquals(1, queue.pendingCount(null, OfflineWatchSyncService.MAX_SYNC_ATTEMPTS))
    }

    @Test
    fun requeuesRemainingActionsWhenTheActiveProfileChangesMidSync() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = jellyfinUser("user-a")
        client.markWatchedHandler = {
            client.watched += it.id
            svc.setActiveProfileId("p2")
        }
        clients.register(client)
        svc.queueMarkWatched(jf, "item-1")
        svc.queueMarkWatched(jf, "item-2")

        svc.syncPendingItems()

        assertEquals(1, client.watched.size)
        assertEquals(emptyList(), trackers.marks, "the switch came before the trackers heard of it")
        // The action the switch interrupted isn't acknowledged either: it replays again for p1.
        assertEquals(2, queue.pendingCount("p1", OfflineWatchSyncService.MAX_SYNC_ATTEMPTS))
    }

    @Test
    fun aReplayInFlightAcrossAProfileSwitchNeverMarksTheNewProfilesTrackers() = runTest {
        // Each profile's trackers record what reaches them.
        val marked = mutableListOf<String>()
        val svc = service(trackers = { profileId -> TrackerWatchMarks { item, _, watched -> marked += "$profileId ${item.id} $watched" } })
        svc.setActiveProfileId("profile-a")
        val client = jellyfinUser("user-a")
        val writing = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        client.markWatchedHandler = {
            writing.complete(Unit)
            release.await()
            client.watched += it.id
        }
        clients.register(client)
        svc.queueMarkWatched(jf, "item-1")

        val sync = launch { svc.syncPendingItems() }
        writing.await()
        svc.setActiveProfileId("profile-b")
        release.complete(Unit)
        sync.join()

        assertEquals(emptyList(), marked, "no tracker hears of profile A's mark after the switch")
        assertEquals(1, queue.pendingCount("profile-a", OfflineWatchSyncService.MAX_SYNC_ATTEMPTS), "it stays queued for profile A")
        assertEquals(0, queue.latest("jf-machine:item-1")?.syncAttempts)

        svc.setActiveProfileId("profile-a")
        client.markWatchedHandler = { client.watched += it.id }
        svc.syncPendingItems()
        assertEquals(listOf("profile-a item-1 true"), marked)
        assertEquals(0, queue.pendingCount("profile-a", OfflineWatchSyncService.MAX_SYNC_ATTEMPTS))
    }

    @Test
    fun legacyActionsAreAdoptedOnlyWhenExactlyOneProfileExists() = runTest {
        val svc = service()
        queue.insertMark(null, srv, null, "1", OfflineWatchActionType.WATCHED)

        svc.setActiveProfileId("p1", availableProfileCount = 2)
        assertEquals(0, svc.getPendingSyncCount())

        svc.setActiveProfileId("p2", availableProfileCount = 1)
        runCurrent()
        assertEquals(1, svc.getPendingSyncCount())
        assertEquals("p2", queue.latest("srv:1")?.profileId)
    }

    // Progress queueing.

    @Test
    fun persistsAProgressRowWithShouldMarkWatchedFalseBelowThreshold() = runTest {
        service().queueProgressUpdate(srv, "42", viewOffsetMs = 50, durationMs = 100)

        val action = queue.latest("srv:42")!!
        assertEquals(OfflineWatchActionType.PROGRESS, action.type)
        assertEquals(50L, action.viewOffsetMs)
        assertEquals(100L, action.durationMs)
        assertFalse(action.shouldMarkWatched)
    }

    @Test
    fun persistsUnknownDurationProgressWithoutMarkingWatched() = runTest {
        service().queueProgressUpdate(srv, "42", viewOffsetMs = 50, durationMs = null)

        val action = queue.latest("srv:42")!!
        assertEquals(50L, action.viewOffsetMs)
        assertNull(action.durationMs)
        assertFalse(action.shouldMarkWatched)
    }

    @Test
    fun persistsShouldMarkWatchedTrueAtOrAboveTheDefaultThreshold() = runTest {
        service().queueProgressUpdate(srv, "42", viewOffsetMs = 95, durationMs = 100)

        assertTrue(queue.latest("srv:42")!!.shouldMarkWatched)
    }

    // Queued progress superseded by a watch-state write.

    @Test
    fun aWatchedEventDropsTheQueuedProgressRowForThatItem() = runTest {
        val svc = service()
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 50_000, durationMs = 100_000)
        assertEquals(1, svc.getPendingSyncCount())

        notifier.notifyWatched(movie("42"))
        runCurrent()

        assertEquals(0, svc.getPendingSyncCount())
        assertNull(queue.latest("srv:42"))
    }

    @Test
    fun anUnwatchedEventDropsItToo() = runTest {
        val svc = service()
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 50_000, durationMs = 100_000)

        notifier.notifyWatched(movie("42"), isNowWatched = false)
        runCurrent()

        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun otherItemsAndQueuedManualMarksAreLeftAlone() = runTest {
        val svc = service()
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 50_000, durationMs = 100_000)
        svc.queueProgressUpdate(srv, "43", viewOffsetMs = 50_000, durationMs = 100_000)
        svc.queueMarkWatched(srv, "44")

        notifier.notifyWatched(movie("42"))
        runCurrent()

        assertNull(queue.latest("srv:42"))
        assertEquals(OfflineWatchActionType.PROGRESS, queue.latest("srv:43")?.type)
        assertEquals(OfflineWatchActionType.WATCHED, queue.latest("srv:44")?.type)
    }

    @Test
    fun progressRecordedAfterTheMarkSurvivesThatIsARewatch() = runTest {
        val svc = service()
        notifier.notifyWatched(movie("42"))
        runCurrent()

        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 5000, durationMs = 100_000)

        assertEquals(5000L, queue.latest("srv:42")?.viewOffsetMs)
    }

    @Test
    fun anOfflineMarkDropsOnlyProgressOlderThanItsRevision() = runTest {
        val svc = service()
        val older = svc.queueProgressUpdate(srv, "42", viewOffsetMs = 5000, durationMs = 100_000)
        val mark = WatchPatchId.offlineAction(null, rowId = 99, revision = older.revision)

        notifier.notifyWatched(movie("42"), patchId = mark)
        runCurrent()
        assertEquals(5000L, queue.latest("srv:42")?.viewOffsetMs, "progress at the mark's revision is a concurrent rewatch")

        notifier.notifyWatched(movie("42"), patchId = WatchPatchId.offlineAction(null, rowId = 99, revision = older.revision + 1))
        runCurrent()
        assertNull(queue.latest("srv:42"))
    }

    @Test
    fun aSupersededRowNeverReachesTheServerOnTheNextSync() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = RecordingBackend("srv", BackendKind.JELLYFIN)
        clients.register(client)
        svc.queueProgressUpdate(srv, "42", viewOffsetMs = 50_000, durationMs = 100_000)

        notifier.notifyWatched(movie("42"))
        runCurrent()
        svc.syncPendingItems()

        assertTrue(client.stopped.isEmpty())
        assertTrue(client.started.isEmpty())
    }

    // Local status queries.

    @Test
    fun localWatchStatusFollowsTheQueuedAction() = runTest {
        val svc = service()
        assertNull(svc.getLocalWatchStatus("srv:none"))

        svc.queueMarkWatched(srv, "1")
        svc.queueMarkUnwatched(srv, "2")
        assertEquals(true, svc.getLocalWatchStatus("srv:1"))
        assertEquals(false, svc.getLocalWatchStatus("srv:2"))
    }

    @Test
    fun returnsWatchedStatusOnlyForExplicitActionsOrThresholdCrossingProgress() = runTest {
        val svc = service()

        svc.queueProgressUpdate(srv, "1", viewOffsetMs = 50, durationMs = 100)
        assertNull(svc.getLocalWatchStatus("srv:1"), "below the threshold is resume-only")

        svc.queueProgressUpdate(srv, "2", viewOffsetMs = 99, durationMs = 100)
        assertEquals(true, svc.getLocalWatchStatus("srv:2"))
    }

    @Test
    fun countsEveryQueuedAction() = runTest {
        val svc = service()

        svc.queueMarkWatched(srv, "1")
        svc.queueMarkUnwatched(srv, "2")
        svc.queueProgressUpdate(srv, "3", viewOffsetMs = 50, durationMs = 100)

        assertEquals(3, svc.getPendingSyncCount())
    }

    @Test
    fun batchedStatusesCoverEveryRequestedKey() = runTest {
        val svc = service()
        assertTrue(svc.getLocalWatchStatusesBatched(emptySet()).isEmpty())

        svc.queueMarkWatched(srv, "1")
        svc.queueMarkUnwatched(srv, "2")
        svc.queueProgressUpdate(srv, "3", viewOffsetMs = 99, durationMs = 100)

        assertEquals(
            mapOf("srv:1" to true, "srv:2" to false, "srv:3" to true, "srv:missing" to null),
            svc.getLocalWatchStatusesBatched(setOf("srv:1", "srv:2", "srv:3", "srv:missing")),
        )
    }

    @Test
    fun filtersBatchedLocalStatusesByActiveJellyfinScope() = runTest {
        val svc = service()
        clients.register(jellyfinUser("user-b"))
        downloads.clientScopes["jf-machine:item-1"] = "jf-machine/user-a"
        queue.insertMark(null, jf, "jf-machine/user-a", "item-1", OfflineWatchActionType.UNWATCHED)
        queue.insertMark(null, jf, "jf-machine/user-b", "item-1", OfflineWatchActionType.WATCHED)

        assertEquals(true, svc.getLocalWatchStatusesBatched(setOf("jf-machine:item-1"))["jf-machine:item-1"])
    }

    @Test
    fun localWatchActionsAreIsolatedByActiveProfile() = runTest {
        val svc = service()

        svc.setActiveProfileId("profile-a")
        svc.queueMarkWatched(plex, "item-1")
        assertEquals(true, svc.getLocalWatchStatus("plex-machine:item-1"))
        assertEquals(1, svc.getPendingSyncCount())

        svc.setActiveProfileId("profile-b")
        assertNull(svc.getLocalWatchStatus("plex-machine:item-1"))
        assertEquals(0, svc.getPendingSyncCount())
        svc.queueMarkUnwatched(plex, "item-1")
        assertEquals(false, svc.getLocalWatchStatus("plex-machine:item-1"))
        assertEquals(1, svc.getPendingSyncCount())

        svc.setActiveProfileId("profile-a")
        assertEquals(true, svc.getLocalWatchStatus("plex-machine:item-1"))
        assertEquals(1, svc.getPendingSyncCount())
    }

    // Plex profile scopes.

    @Test
    fun queuesAndReplaysThroughTheExactActivePlexProfileScope() = runTest {
        val svc = service()
        svc.setActiveProfileId("profile-a")
        val clientA = plexProfileClient("profile-a")
        clients.register(clientA)

        val queued = svc.queueMarkWatched(plex, "item-1")
        assertEquals(clientA.cacheServerId, queued.clientScopeId)
        assertEquals(clientA.cacheServerId, queue.rows.single().clientScopeId)

        svc.syncPendingItems()

        assertEquals(listOf("item-1"), clientA.watched)
        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun doesNotReplayAQueuedPlexOwnerActionThroughAForeignActiveProfile() = runTest {
        val svc = service()
        svc.setActiveProfileId("profile-a")
        val clientB = plexProfileClient("profile-b")
        clients.register(clientB)
        queue.insertMark("profile-a", plex, PlexProfileScopeId.of(plex, "profile-a").value, "item-1", OfflineWatchActionType.WATCHED)

        svc.syncPendingItems()

        assertTrue(clientB.watched.isEmpty())
        assertEquals(1, svc.getPendingSyncCount())
    }

    @Test
    fun aDownloadedPlexProfileScopeIsRewrittenToTheActiveProfile() = runTest {
        val svc = service()
        svc.setActiveProfileId("profile-b")
        downloads.clientScopes["plex-machine:item-1"] = PlexProfileScopeId.of(plex, "profile-a").value

        val queued = svc.queueMarkWatched(plex, "item-1")

        assertEquals(PlexProfileScopeId.of(plex, "profile-b").value, queued.clientScopeId)
    }

    // Jellyfin user scopes.

    @Test
    fun emptyActiveScopeFallsBackToTheDownloadedScopeDuringClientPreBind() = runTest {
        val svc = service()
        downloads.clientScopes["jf-machine:item-1"] = "jf-machine/user-a"
        clients.register(RecordingBackend("jf-machine", BackendKind.JELLYFIN, scopeId = ""))

        val queued = svc.queueMarkWatched(jf, "item-1")

        assertEquals("jf-machine/user-a", queued.clientScopeId)
        assertEquals("jf-machine/user-a", queue.rows.single().clientScopeId)
    }

    @Test
    fun queuesWithDownloadedJellyfinSourceScopeWhenNoActiveClientIsRegistered() = runTest {
        val svc = service()
        downloads.clientScopes["jf-machine:item-1"] = "jf-machine/user-a"

        svc.queueMarkWatched(jf, "item-1")

        assertEquals("jf-machine/user-a", queue.rows.single().clientScopeId)
    }

    @Test
    fun localStatusUsesActiveScopeOverDownloadedSourceScope() = runTest {
        val svc = service()
        clients.register(jellyfinUser("user-b"))
        downloads.clientScopes["jf-machine:item-1"] = "jf-machine/user-a"
        queue.upsertProgress(null, jf, "jf-machine/user-a", "item-1", viewOffsetMs = 5000, durationMs = 100_000, shouldMarkWatched = false)
        queue.upsertProgress(null, jf, "jf-machine/user-b", "item-1", viewOffsetMs = 90_000, durationMs = 100_000, shouldMarkWatched = true)

        assertEquals(true, svc.getLocalWatchStatus("jf-machine:item-1"))
        assertNull(svc.getLocalWatchStatus("jf-machine:item-1", clientScopeId = "jf-machine/user-a"))
    }

    @Test
    fun queuesWithActiveJellyfinUserInsteadOfDownloadedSourceScope() = runTest {
        val svc = service()
        downloads.clientScopes["jf-machine:item-1"] = "jf-machine/user-a"
        clients.register(jellyfinUser("user-b"))

        val queued = svc.queueMarkWatched(jf, "item-1")

        assertEquals("jf-machine/user-b", queued.clientScopeId)
        assertEquals("jf-machine/user-b", queue.rows.single().clientScopeId)
    }

    @Test
    fun replaysThroughTheQueuedJellyfinUserAfterActiveUserChanges() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val userA = jellyfinUser("user-a")
        val userB = jellyfinUser("user-b")
        clients.register(userA)
        svc.queueMarkWatched(jf, "item-1")
        assertEquals("jf-machine/user-a", queue.rows.single().clientScopeId)

        clients.register(userB, online = false)
        svc.syncPendingItems()

        assertEquals(0, svc.getPendingSyncCount())
        assertEquals(listOf("item-1"), userA.watched)
        assertTrue(userB.calls.isEmpty())
    }

    @Test
    fun legacyJellyfinRowsWithoutClientScopeIdAreNotSyncedThroughTheActiveServerClient() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val client = jellyfinUser("user-b")
        clients.register(client)
        queue.insertMark("p1", jf, null, "item-1", OfflineWatchActionType.WATCHED)

        svc.syncPendingItems()

        assertEquals(1, svc.getPendingSyncCount())
        assertTrue(client.calls.isEmpty())
    }

    @Test
    fun legacyJellyfinRowsWithoutClientScopeIdDoNotBorrowDownloadedSourceScopeDuringReplay() = runTest {
        val svc = service()
        svc.setActiveProfileId("p1")
        val userA = jellyfinUser("user-a")
        val userB = jellyfinUser("user-b")
        downloads.clientScopes["jf-machine:item-1"] = "jf-machine/user-a"
        queue.insertMark("p1", jf, null, "item-1", OfflineWatchActionType.WATCHED)
        clients.register(userA)
        clients.register(userB)

        svc.syncPendingItems()

        assertEquals(1, svc.getPendingSyncCount())
        assertTrue(userA.calls.isEmpty())
        assertTrue(userB.calls.isEmpty())
    }

    // Pull.

    @Test
    fun watchStatePullUsesActiveScopeForSharedMovieDownloads() = runTest {
        val svc = service()
        val userA = jellyfinUser("user-a")
        val userB = jellyfinUser("user-b")
        userB.items = { id -> MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, serverId = "jf-machine", viewCount = 1) }
        val events = mutableListOf<WatchStateEvent>()
        backgroundScope.launch { notifier.events.collect { events += it } }
        runCurrent()
        downloads.own("profile-b", DownloadedWatchItem(jf, "item-1", MediaKind.MOVIE, parentId = null))
        svc.setActiveProfileId("profile-b")
        clients.register(userA)
        clients.register(userB)

        svc.syncWatchStatesFromServer()
        runCurrent()

        assertTrue(userA.calls.isEmpty())
        assertTrue("fetchItem:item-1" in userB.calls)
        assertEquals("jf-machine/user-b", events.single().cacheServerId)
        assertTrue(events.single().serverAcknowledged)
        assertEquals(listOf("item-1" to true), trackers.marks)
    }

    @Test
    fun watchStatePullUsesActiveScopeForSharedEpisodeSeasonBatches() = runTest {
        val svc = service()
        val userA = jellyfinUser("user-a")
        val userB = jellyfinUser("user-b")
        userB.children = { listOf(MediaItem(id = "ep-1", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, serverId = "jf-machine", viewCount = 1)) }
        downloads.own("profile-b", DownloadedWatchItem(jf, "ep-1", MediaKind.EPISODE, parentId = "season-1"))
        svc.setActiveProfileId("profile-b")
        clients.register(userA)
        clients.register(userB)

        svc.syncWatchStatesFromServer()

        assertTrue(userA.calls.isEmpty())
        assertTrue("fetchChildren:season-1" in userB.calls)
        assertEquals(listOf("jf-machine/user-b|ep-1|true"), (userB.cache as FakeBackendCache).applied)
    }

    @Test
    fun aPullWithoutACachedPriorRowCachesWithoutAnnouncing() = runTest {
        val svc = service()
        val client = jellyfinUser("user-b")
        client.items = { id -> MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, serverId = "jf-machine", viewCount = 1) }
        val cache = client.cache as FakeBackendCache
        val events = mutableListOf<WatchStateEvent>()
        backgroundScope.launch { notifier.events.collect { events += it } }
        runCurrent()
        downloads.own("profile-b", DownloadedWatchItem(jf, "ep-1", MediaKind.EPISODE, parentId = "season-1"))
        downloads.own("profile-b", DownloadedWatchItem(jf, "ep-2", MediaKind.EPISODE, parentId = "season-2"))
        client.children = { parentId ->
            val id = if (parentId == "season-1") "ep-1" else "ep-2"
            listOf(MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, serverId = "jf-machine", viewCount = 1))
        }
        cache.metadata["jf-machine/user-b|ep-2"] = MediaItem(id = "ep-2", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, serverId = "jf-machine", viewCount = 0)
        svc.setActiveProfileId("profile-b")
        clients.register(client)

        svc.syncWatchStatesFromServer()
        runCurrent()

        assertTrue("fetchItem:ep-1" in client.calls, "no cached row: the fetch writes it")
        assertEquals(listOf("ep-2"), events.map { it.itemId }, "only the transition against a cached prior is announced")
    }

    @Test
    fun watchStatePullIgnoresPhysicalDownloadsNotOwnedByActiveProfile() = runTest {
        val svc = service()
        val userB = jellyfinUser("user-b")
        downloads.own("profile-a", DownloadedWatchItem(jf, "item-1", MediaKind.MOVIE, parentId = null))
        svc.setActiveProfileId("profile-b")
        clients.register(userB)

        svc.syncWatchStatesFromServer()

        assertTrue(userB.calls.isEmpty())
    }

    @Test
    fun watchStatePullStopsWhenTheActiveProfileChangesMidPull() = runTest {
        lateinit var svc: OfflineWatchSyncService
        svc = service()
        val userB = jellyfinUser("user-b")
        val requested = mutableListOf<String>()
        userB.items = { id ->
            requested += id
            svc.setActiveProfileId("profile-c")
            MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, serverId = "jf-machine", viewCount = 1)
        }
        val events = mutableListOf<WatchStateEvent>()
        backgroundScope.launch { notifier.events.collect { events += it } }
        runCurrent()
        for (id in listOf("item-1", "item-2")) downloads.own("profile-b", DownloadedWatchItem(jf, id, MediaKind.MOVIE, parentId = null))
        svc.setActiveProfileId("profile-b")
        clients.register(userB)

        svc.syncWatchStatesFromServer()
        runCurrent()

        assertEquals(1, requested.size)
        assertTrue(events.isEmpty(), "the previous profile must not announce the new user's watch state")
    }

    @Test
    fun serversConnectingAfterAProfileSwitchSyncTheNewProfile() = runTest {
        val svc = service()
        val userA = jellyfinUser("user-a")
        var itemRequests = 0
        userA.items = { id ->
            itemRequests++
            MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, serverId = "jf-machine", viewCount = 0)
        }
        for (profileId in listOf("profile-a", "profile-b")) downloads.own(profileId, DownloadedWatchItem(jf, "item-1", MediaKind.MOVIE, parentId = null))
        clients.register(userA)

        svc.setActiveProfileId("profile-a")
        svc.onServersConnected()
        runCurrent()
        assertEquals(1, itemRequests)

        svc.setActiveProfileId("profile-b")
        svc.onServersConnected()
        runCurrent()
        assertEquals(2, itemRequests)
    }

    @Test
    fun thePullIsThrottledByTheMinimumIntervalUnlessForced() = runTest {
        val svc = service(minSyncInterval = OfflineWatchSyncService.DESKTOP_MIN_SYNC_INTERVAL)
        val client = jellyfinUser("user-a")
        var itemRequests = 0
        client.items = { id ->
            itemRequests++
            MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, serverId = "jf-machine")
        }
        downloads.own("p1", DownloadedWatchItem(jf, "item-1", MediaKind.MOVIE, parentId = null))
        clients.register(client)
        svc.setActiveProfileId("p1")

        svc.onServersConnected()
        runCurrent()
        svc.onAppResumed()
        runCurrent()
        assertEquals(1, itemRequests, "a resume within the interval pushes but skips the pull")

        testScheduler.advanceTimeBy(3.minutes)
        svc.onAppResumed()
        runCurrent()
        assertEquals(2, itemRequests)
    }

    @Test
    fun anActionReplaysWhenItsServerConnectsAfterAnotherServer() = runTest {
        val svc = service()
        svc.setActiveProfileId("profile-a")
        val embyClient = embyUser("user-a")
        val jellyfinClient = jellyfinUser("user-a")
        clients.register(jellyfinClient, online = false)
        svc.queueProgressUpdate(jf, "resume-movie", viewOffsetMs = 113_000, durationMs = 3_600_000)

        clients.register(embyClient)
        svc.onServersConnected()
        runCurrent()
        assertEquals(1, svc.getPendingSyncCount(), "the first server's sync keeps the other server's action queued")

        clients.register(jellyfinClient)
        svc.onServersConnected()
        runCurrent()
        assertEquals(listOf(113_000L), jellyfinClient.stopped.map { it.positionMs })
        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun aServerConnectingDuringAPassHasItsActionReplayedOnceThePassSettles() = runTest {
        val svc = service()
        svc.setActiveProfileId("profile-a")
        val embyClient = embyUser("user-a")
        val pulling = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        embyClient.items = { id ->
            pulling.complete(Unit)
            release.await()
            MediaItem(id = id, backend = BackendKind.EMBY, kind = MediaKind.MOVIE, serverId = "emby-machine")
        }
        downloads.own("profile-a", DownloadedWatchItem(emby, "emby-movie", MediaKind.MOVIE, parentId = null))
        val jellyfinClient = jellyfinUser("user-a")
        clients.register(jellyfinClient, online = false)
        svc.queueProgressUpdate(jf, "resume-movie", viewOffsetMs = 113_000, durationMs = 3_600_000)

        clients.register(embyClient)
        svc.onServersConnected()
        pulling.await()
        clients.register(jellyfinClient)
        svc.onServersConnected()
        runCurrent()

        release.complete(Unit)
        runCurrent()
        assertEquals(listOf(113_000L), jellyfinClient.stopped.map { it.positionMs })
        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun afterTheNetworkReturnsAnActionReplaysWhenItsServerReconnectsSecond() = runTest {
        val svc = service()
        svc.setActiveProfileId("profile-a")
        val embyClient = embyUser("user-a")
        val jellyfinClient = jellyfinUser("user-a")
        clients.register(embyClient)
        clients.register(jellyfinClient)
        svc.onServersConnected()
        runCurrent()

        offlineMode.isOffline.value = true
        clients.register(embyClient, online = false)
        clients.register(jellyfinClient, online = false)
        svc.onServersConnected()
        runCurrent()
        svc.queueProgressUpdate(jf, "resume-movie", viewOffsetMs = 113_000, durationMs = 3_600_000)

        clients.register(embyClient)
        offlineMode.isOffline.value = false
        svc.onServersConnected()
        runCurrent()
        assertEquals(1, svc.getPendingSyncCount())

        clients.register(jellyfinClient)
        svc.onServersConnected()
        runCurrent()
        assertEquals(listOf(113_000L), jellyfinClient.stopped.map { it.positionMs })
        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun aServerConnectingAfterTheLastPullIsPulledWithinTheMinimumInterval() = runTest {
        val svc = service(minSyncInterval = OfflineWatchSyncService.DESKTOP_MIN_SYNC_INTERVAL)
        val embyClient = embyUser("user-a")
        val jellyfinClient = jellyfinUser("user-a")
        val requested = mutableListOf<String>()
        embyClient.items = { id ->
            requested += id
            MediaItem(id = id, backend = BackendKind.EMBY, kind = MediaKind.MOVIE, serverId = "emby-machine")
        }
        jellyfinClient.items = { id ->
            requested += id
            MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, serverId = "jf-machine")
        }
        downloads.own("profile-a", DownloadedWatchItem(emby, "emby-movie", MediaKind.MOVIE, parentId = null))
        downloads.own("profile-a", DownloadedWatchItem(jf, "jellyfin-movie", MediaKind.MOVIE, parentId = null))
        clients.register(jellyfinClient, online = false)
        clients.register(embyClient)
        svc.setActiveProfileId("profile-a")

        svc.onServersConnected()
        runCurrent()
        assertEquals(listOf("emby-movie"), requested)

        clients.register(jellyfinClient)
        svc.onServersConnected()
        runCurrent()
        assertEquals(1, requested.count { it == "jellyfin-movie" })
    }

    @Test
    fun removesEveryQueuedAction() = runTest {
        val svc = service()
        svc.queueMarkWatched(srv, "1")
        svc.queueMarkUnwatched(srv, "2")
        assertEquals(2, svc.getPendingSyncCount())

        svc.clearAll()

        assertEquals(0, svc.getPendingSyncCount())
    }

    @Test
    fun syncsOnTheOfflineToOnlineEdgeOnly() = runTest {
        offlineMode.isOffline.value = true
        val svc = service()
        svc.setActiveProfileId("profile-a")
        val client = plexProfileClient("profile-a")
        clients.register(client)

        svc.queueMarkWatched(plex, "item-1")
        offlineMode.isOffline.value = false
        runCurrent()
        assertEquals(listOf("item-1"), client.watched)

        svc.queueMarkWatched(plex, "item-2")
        offlineMode.isOffline.value = false
        runCurrent()
        assertEquals(listOf("item-1"), client.watched)
        assertEquals(1, svc.getPendingSyncCount())
    }

    @Test
    fun stopBackgroundSyncSettlesThePassInFlightWithoutARefreshAndBlocksLaterPasses() = runTest {
        val svc = service()
        val client = jellyfinUser("user-a")
        val itemRequested = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        client.items = { id ->
            itemRequested.complete(Unit)
            release.await()
            MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, serverId = "jf-machine", viewCount = 1)
        }
        downloads.own("profile-a", DownloadedWatchItem(jf, "item-1", MediaKind.MOVIE, parentId = null))
        clients.register(client)
        var refreshes = 0
        backgroundScope.launch { svc.watchStatesRefreshed.collect { refreshes++ } }
        runCurrent()
        svc.setActiveProfileId("profile-a")

        svc.onServersConnected()
        itemRequested.await()
        var stopped = false
        launch {
            svc.stopBackgroundSync()
            stopped = true
        }
        runCurrent()
        assertFalse(stopped, "the pass in flight may still write")

        release.complete(Unit)
        runCurrent()
        assertTrue(stopped)
        assertEquals(0, refreshes)

        val calls = client.calls.size
        svc.onAppResumed()
        runCurrent()
        assertEquals(calls, client.calls.size)
    }
}
