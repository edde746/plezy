package com.edde746.plezy.servers

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.test.assertFalse
import kotlin.time.Clock
import kotlin.time.Instant
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

private val episode = MediaItem(
    id = "episode-1",
    backend = BackendKind.JELLYFIN,
    kind = MediaKind.EPISODE,
    parentId = "season-1",
    grandparentId = "show-1",
    serverId = "jf-machine",
)

private val plexScope = PlexProfileScopeId.of(ServerId("plex-machine"), "profile-a").value

private val plexEpisode = MediaItem(
    id = "episode-1",
    backend = BackendKind.PLEX,
    kind = MediaKind.EPISODE,
    serverId = "plex-machine",
    durationMs = 3_600_000,
)

class WatchStateStoreTest {
    private val notifier = WatchStateNotifier()
    private var sequence = 0L

    private val fixedClock = object : Clock {
        override fun now(): Instant = Instant.fromEpochMilliseconds(1_000)
    }

    private fun TestScope.store(): WatchStateStore = WatchStateStore(notifier, backgroundScope, fixedClock)

    private fun TestScope.emit(
        changeType: WatchStateChangeType,
        isNowWatched: Boolean?,
        serverId: String = "jf-machine",
        itemId: String = "item-1",
        cacheServerId: String? = null,
        viewOffset: Long? = null,
        parentChain: List<String> = emptyList(),
        serverAcknowledged: Boolean = false,
    ) {
        notifier.notify(
            WatchStateEvent(
                itemId = itemId,
                serverId = ServerId(serverId),
                changeType = changeType,
                parentChain = parentChain,
                cacheServerId = cacheServerId,
                viewOffset = viewOffset,
                isNowWatched = isNowWatched,
                serverAcknowledged = serverAcknowledged,
                patchId = WatchPatchId.session(++sequence),
            ),
        )
        runCurrent()
    }

    private fun TestScope.emitPausedEpisode(viewOffset: Long = 1_800_000, acknowledged: Boolean = true, cacheServerId: String? = null) =
        emit(WatchStateChangeType.PROGRESS_UPDATE, isNowWatched = false, itemId = "episode-1", viewOffset = viewOffset, cacheServerId = cacheServerId, serverAcknowledged = acknowledged)

    private val fresh = episode.copy(viewOffsetMs = 2_700_000, durationMs = 3_600_000)

    private fun WatchStateStore.observe(item: MediaItem, clientScope: String? = null, watermark: Long = observationWatermark, epoch: Any = observationEpoch) =
        recordObservations(listOf(ObservedRow(item, clientScope)), watermark, epoch)

    @Test
    fun removedFromContinueWatchingDoesNotReplaceAnExistingWatchedPatch() = runTest {
        val store = store()
        emit(WatchStateChangeType.WATCHED, isNowWatched = true)
        emit(WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING, isNowWatched = null)

        val patch = store.patchForGlobalKey("jf-machine:item-1")
        assertEquals(true, patch?.isWatched)
        assertEquals(0L, patch?.viewOffsetMs)
    }

    @Test
    fun knownActiveScopeResolvesANewerLegacyBareEventIntoThatScope() = runTest {
        val store = store()
        store.setActiveClientScopesByServer(mapOf(ServerId("jf-machine") to "jf-machine/user-a"))
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, cacheServerId = "jf-machine/user-a")
        emit(WatchStateChangeType.UNWATCHED, isNowWatched = false)

        assertEquals(false, store.patchForGlobalKey("jf-machine:item-1")?.isWatched)
    }

    @Test
    fun unscopedPatchRemainsVisibleWhenTheActiveClientScopeArrivesLater() = runTest {
        val store = store()
        emit(WatchStateChangeType.WATCHED, isNowWatched = true)
        store.setActiveClientScopesByServer(mapOf(ServerId("jf-machine") to "jf-machine/user-a"))

        assertEquals(true, store.patchForGlobalKey("jf-machine:item-1")?.isWatched)
    }

    @Test
    fun newerActiveScopedPatchWinsOverOlderUnscopedPatch() = runTest {
        val store = store()
        store.setActiveClientScopesByServer(mapOf(ServerId("jf-machine") to "jf-machine/user-a"))
        emit(WatchStateChangeType.UNWATCHED, isNowWatched = false)
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, cacheServerId = "jf-machine/user-a")

        assertEquals(true, store.patchForGlobalKey("jf-machine:item-1")?.isWatched)
    }

    @Test
    fun explicitForeignScopeIsIgnoredWhenResolvingTheActiveScope() = runTest {
        val store = store()
        store.setActiveClientScopesByServer(mapOf(ServerId("jf-machine") to "jf-machine/user-a"))
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, cacheServerId = "jf-machine/user-a")
        emit(WatchStateChangeType.UNWATCHED, isNowWatched = false, cacheServerId = "jf-machine/user-b")

        assertEquals(true, store.patchForGlobalKey("jf-machine:item-1")?.isWatched)
    }

    @Test
    fun anAncestorPatchReachesDescendantsThroughParentChain() = runTest {
        val store = store()
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, itemId = "show-1")

        assertEquals(true, store.patchForItem(episode)?.isWatched)
        assertTrue(store.apply(episode).isWatched)
        assertNull(store.patchForGlobalKey(episode.globalKey), "only resolution sees the ancestor")
    }

    @Test
    fun newerContainerMarkOverridesAnOlderPerItemPatch() = runTest {
        val store = store()
        emit(WatchStateChangeType.UNWATCHED, isNowWatched = false, itemId = "episode-1")
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, itemId = "season-1", parentChain = listOf("show-1"))

        assertEquals(true, store.patchForItem(episode)?.isWatched)
    }

    @Test
    fun newerPerItemPatchOverridesAnOlderContainerMark() = runTest {
        val store = store()
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, itemId = "show-1")
        emit(WatchStateChangeType.UNWATCHED, isNowWatched = false, itemId = "episode-1")

        assertEquals(false, store.patchForItem(episode)?.isWatched)
    }

    @Test
    fun ancestorPatchesResolveThroughTheActiveClientScope() = runTest {
        val store = store()
        store.setActiveClientScopesByServer(mapOf(ServerId("jf-machine") to "jf-machine/user-a"))
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, itemId = "show-1", cacheServerId = "jf-machine/user-a")

        assertEquals(true, store.patchForItem(episode)?.isWatched)
    }

    @Test
    fun applyingAWatchedPatchToAContainerAlsoPatchesLeafCounts() = runTest {
        val store = store()
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, itemId = "season-1")
        val season = MediaItem(
            id = "season-1",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.SEASON,
            parentId = "show-1",
            serverId = "jf-machine",
            leafCount = 10,
            viewedLeafCount = 3,
        )

        val resolved = store.apply(season)
        assertEquals(10, resolved.viewedLeafCount)
        assertTrue(resolved.isWatched)
    }

    @Test
    fun hydratedParentAndItemPatchesRetainPersistedFreshness() = runTest {
        val store = store()
        store.setHydratedPatches(
            listOf(
                HydratedWatchStatePatch("jf-machine:show-1", WatchStateSnapshot(isWatched = true, hasViewOffsetMs = true, viewOffsetMs = 0), updatedAt = 100, order = 1),
                HydratedWatchStatePatch("jf-machine:episode-1", WatchStateSnapshot(isWatched = false, hasViewOffsetMs = true, viewOffsetMs = 0), updatedAt = 200, order = 2),
            ),
        )

        val resolved = store.apply(episode.copy(viewOffsetMs = 30_000))
        assertFalse(resolved.isWatched)
        assertEquals(0L, resolved.viewOffsetMs)
    }

    @Test
    fun hydratedPatchesAreIsolatedToTheActiveClientScope() = runTest {
        val store = store()
        store.setHydratedPatches(
            listOf(
                HydratedWatchStatePatch("jf-machine/user-a:show-1", WatchStateSnapshot(isWatched = true), updatedAt = 100, order = 1),
                HydratedWatchStatePatch("jf-machine/user-b:show-1", WatchStateSnapshot(isWatched = false), updatedAt = 100, order = 2),
            ),
        )

        store.setActiveClientScopesByServer(mapOf(ServerId("jf-machine") to "jf-machine/user-a"))
        assertTrue(store.apply(episode).isWatched)
        store.setActiveClientScopesByServer(mapOf(ServerId("jf-machine") to "jf-machine/user-b"))
        assertFalse(store.apply(episode).isWatched)
    }

    // Authoritative observations supersede acknowledged patches.

    @Test
    fun aFetchThatStartedAfterThePatchRendersTheServerOffset() = runTest {
        val store = store()
        emitPausedEpisode()
        assertEquals(1_800_000L, store.apply(fresh).viewOffsetMs, "precondition: the stale patch still wins")

        store.observe(fresh)

        assertEquals(2_700_000L, store.apply(fresh).viewOffsetMs)
        assertNull(store.patchForItem(fresh))
    }

    @Test
    fun aPatchRecordedDuringTheFetchSurvivesItsObservation() = runTest {
        val store = store()
        val watermark = store.observationWatermark
        emitPausedEpisode()

        store.observe(fresh, watermark = watermark)

        assertEquals(1_800_000L, store.apply(fresh).viewOffsetMs)
    }

    @Test
    fun anUnacknowledgedPatchIsNeverSupersededByARead() = runTest {
        val store = store()
        emitPausedEpisode(acknowledged = false)

        store.observe(fresh)

        assertEquals(1_800_000L, store.apply(fresh).viewOffsetMs)
    }

    @Test
    fun anObservationFromAnotherStoreEpochIsRejected() = runTest {
        val store = store()
        emitPausedEpisode()

        store.observe(fresh, epoch = Any())

        assertEquals(1_800_000L, store.apply(fresh).viewOffsetMs)
    }

    @Test
    fun anOlderResponseCannotLowerAnObservationAlreadyRecorded() = runTest {
        val store = store()
        val stale = store.observationWatermark
        emitPausedEpisode()

        store.observe(fresh)
        store.observe(fresh, watermark = stale)

        assertEquals(2_700_000L, store.apply(fresh).viewOffsetMs, "max per key, so response order cannot matter")
    }

    @Test
    fun suppressingAnItemDoesNotExposeAnOlderAncestorPatch() = runTest {
        val store = store()
        emit(WatchStateChangeType.UNWATCHED, isNowWatched = false, itemId = "season-1", serverAcknowledged = true)
        emitPausedEpisode()
        val observed = fresh.copy(viewCount = 0)

        store.observe(observed)

        assertNull(store.patchForItem(observed))
        assertEquals(2_700_000L, store.apply(observed).viewOffsetMs)
    }

    @Test
    fun anAncestorMarkNewerThanTheObservationStillReachesDescendants() = runTest {
        val store = store()
        emitPausedEpisode()
        store.observe(fresh)
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, itemId = "season-1", serverAcknowledged = true)

        assertTrue(store.apply(fresh).isWatched)
    }

    @Test
    fun anUnobservedSiblingStillSeesTheContainerMark() = runTest {
        val store = store()
        emit(WatchStateChangeType.WATCHED, isNowWatched = true, itemId = "season-1", serverAcknowledged = true)
        val observed = episode.copy(viewCount = 0)
        val sibling = episode.copy(id = "episode-2")

        store.observe(observed)

        assertFalse(store.apply(observed).isWatched, "the observed child yields to the server")
        assertTrue(store.apply(sibling).isWatched, "the unobserved sibling keeps the container mark")
    }

    @Test
    fun anObservationUnderOneClientScopeCannotSuppressAnotherScope() = runTest {
        val store = store()
        store.setActiveClientScopesByServer(mapOf(ServerId("jf-machine") to "jf-machine/user-b"))
        emitPausedEpisode(cacheServerId = "jf-machine/user-b")

        store.observe(fresh, clientScope = "jf-machine/user-a")

        assertEquals(1_800_000L, store.apply(fresh).viewOffsetMs)
    }

    @Test
    fun aProfileSwitchClearsObservationsAlongWithPatches() = runTest {
        val store = store()
        emitPausedEpisode()
        store.observe(fresh)
        store.setActiveProfileId("profile-2")

        emitPausedEpisode(viewOffset = 900_000)

        assertEquals(900_000L, store.apply(fresh).viewOffsetMs, "a stale observation must not suppress the new patch")
    }

    // Promotion settles an owed write.

    @Test
    fun aPromotedPatchBecomesSuppressible() = runTest {
        val store = store()
        val patchId = notifier.notifyProgress(episode, viewOffset = 1_800_000, duration = 3_600_000)!!
        runCurrent()

        store.observe(fresh)
        assertEquals(1_800_000L, store.apply(fresh).viewOffsetMs, "unacknowledged, so the read must not retire it")

        notifier.promote(patchId)
        runCurrent()

        assertEquals(1_800_000L, store.apply(fresh).viewOffsetMs, "the observation before the write cannot suppress it")
        store.observe(fresh)
        assertEquals(2_700_000L, store.apply(fresh).viewOffsetMs)
    }

    @Test
    fun promotingAnUnknownIdIsANoOp() = runTest {
        val store = store()
        emit(WatchStateChangeType.PROGRESS_UPDATE, isNowWatched = false, viewOffset = 1_800_000)

        notifier.promote(WatchPatchId.session(999_999))
        runCurrent()

        assertEquals(1_800_000L, store.patchForGlobalKey("jf-machine:item-1")?.viewOffsetMs)
    }

    @Test
    fun aPromotedHydratedPatchStopsOutlivingAuthoritativeReads() = runTest {
        val store = store()
        val patchId = WatchPatchId.offlineAction(profileId = "profile-a", rowId = 7, revision = 100)
        store.setHydratedPatches(
            listOf(HydratedWatchStatePatch("jf-machine:episode-1", WatchStateSnapshot(hasViewOffsetMs = true, viewOffsetMs = 1_800_000), updatedAt = 100, order = 7, patchId = patchId)),
        )
        assertEquals(1_800_000L, store.apply(fresh).viewOffsetMs, "an owed write outlives any read")

        notifier.promote(patchId)
        runCurrent()
        store.observe(fresh)

        assertEquals(2_700_000L, store.apply(fresh).viewOffsetMs, "the write settled, so the server read now wins")
    }

    // A Plex client's cache scope is a profile scope, not the public server id: patch and observation share a key.

    @Test
    fun aRefreshedRowOverridesTheOffsetTheMacPausedAt() = runTest {
        val store = store()
        store.setActiveClientScopesByServer(mapOf(ServerId("plex-machine") to plexScope))
        emit(
            WatchStateChangeType.PROGRESS_UPDATE,
            isNowWatched = false,
            serverId = "plex-machine",
            itemId = "episode-1",
            cacheServerId = plexScope,
            viewOffset = 1_800_000,
            serverAcknowledged = true,
        )
        val serverRow = plexEpisode.copy(viewOffsetMs = 2_700_000)
        assertEquals(1_800_000L, store.apply(serverRow).viewOffsetMs)

        store.observe(serverRow, clientScope = plexScope)

        assertEquals(2_700_000L, store.apply(serverRow).viewOffsetMs)
    }

    @Test
    fun aPreRefreshPauseStillPinsSoALaterLocalActionIsNotLost() = runTest {
        val store = store()
        store.setActiveClientScopesByServer(mapOf(ServerId("plex-machine") to plexScope))
        val serverRow = plexEpisode.copy(viewOffsetMs = 2_700_000)
        store.observe(serverRow, clientScope = plexScope)

        emit(
            WatchStateChangeType.PROGRESS_UPDATE,
            isNowWatched = false,
            serverId = "plex-machine",
            itemId = "episode-1",
            cacheServerId = plexScope,
            viewOffset = 3_000_000,
            serverAcknowledged = true,
        )

        assertEquals(3_000_000L, store.apply(serverRow).viewOffsetMs)
    }

    @Test
    fun anUnscopedStoreNeitherPinsNorMisSuppresses() = runTest {
        val store = store()
        store.setActiveClientScopesByServer(emptyMap())
        emit(
            WatchStateChangeType.PROGRESS_UPDATE,
            isNowWatched = false,
            serverId = "plex-machine",
            itemId = "episode-1",
            cacheServerId = plexScope,
            viewOffset = 1_800_000,
            serverAcknowledged = true,
        )

        assertEquals(2_700_000L, store.apply(plexEpisode.copy(viewOffsetMs = 2_700_000)).viewOffsetMs)
    }
}
