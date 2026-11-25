package com.edde746.plezy.servers

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class WatchStateSnapshotTest {
    private fun action(type: OfflineWatchActionType, updatedAt: Long, viewOffsetMs: Long? = null, durationMs: Long? = null) = OfflineWatchAction(
        rowId = updatedAt,
        profileId = null,
        serverId = ServerId("srv"),
        clientScopeId = null,
        itemId = "item-1",
        type = type,
        viewOffsetMs = viewOffsetMs,
        durationMs = durationMs,
        createdAt = updatedAt,
        updatedAt = updatedAt,
    )

    @Test
    fun newerSubThresholdProgressPreservesWatchedStateWhileUpdatingResumeOffset() {
        val snapshot = WatchStateSnapshot.fromActions(
            listOf(
                action(OfflineWatchActionType.WATCHED, updatedAt = 1),
                action(OfflineWatchActionType.PROGRESS, updatedAt = 2, viewOffsetMs = 5000, durationMs = 100_000),
            ),
        )

        assertNull(snapshot.isWatched)
        assertTrue(snapshot.hasViewOffsetMs)
        assertEquals(5000L, snapshot.viewOffsetMs)
    }

    @Test
    fun newerWatchedActionClearsOlderProgressOffset() {
        val snapshot = WatchStateSnapshot.fromActions(
            listOf(
                action(OfflineWatchActionType.PROGRESS, updatedAt = 1, viewOffsetMs = 5000, durationMs = 100_000),
                action(OfflineWatchActionType.WATCHED, updatedAt = 2),
            ),
        )

        assertEquals(true, snapshot.isWatched)
        assertTrue(snapshot.hasViewOffsetMs)
        assertEquals(0L, snapshot.viewOffsetMs)
    }

    @Test
    fun subThresholdProgressEventsOnlyUpdateResumeOffset() {
        val snapshot = WatchStateSnapshot.fromEvent(
            WatchStateEvent(
                itemId = "item-1",
                serverId = ServerId("srv"),
                changeType = WatchStateChangeType.PROGRESS_UPDATE,
                parentChain = emptyList(),
                viewOffset = 5000,
                isNowWatched = false,
            ),
        )

        assertNull(snapshot.isWatched)
        assertTrue(snapshot.hasViewOffsetMs)
        assertEquals(5000L, snapshot.viewOffsetMs)
    }

    @Test
    fun removedFromContinueWatchingIsNotAWatchStateOverlayPatch() {
        val snapshot = WatchStateSnapshot.fromEvent(
            WatchStateEvent(
                itemId = "item-1",
                serverId = ServerId("srv"),
                changeType = WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING,
                parentChain = emptyList(),
            ),
        )

        assertTrue(snapshot.isEmpty)
    }

    @Test
    fun applyingAWatchedSnapshotPatchesContainerLeafCountsSoIsWatchedFlips() {
        val season = MediaItem(id = "season-1", backend = BackendKind.PLEX, kind = MediaKind.SEASON, leafCount = 8, viewedLeafCount = 2, serverId = "srv")

        val resolved = WatchStateSnapshot(isWatched = true, hasViewOffsetMs = true, viewOffsetMs = 0).apply(season)
        assertEquals(8, resolved.viewedLeafCount)
        assertTrue(resolved.isWatched)

        val unmarked = WatchStateSnapshot(isWatched = false, hasViewOffsetMs = true, viewOffsetMs = 0).apply(resolved)
        assertEquals(0, unmarked.viewedLeafCount)
        assertFalse(unmarked.isWatched)
    }
}
