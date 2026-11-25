package com.edde746.plezy.data.watch

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.OfflineWatchAction
import com.edde746.plezy.servers.OfflineWatchActionType
import com.edde746.plezy.servers.OfflineWatchActionType.PROGRESS
import com.edde746.plezy.servers.OfflineWatchActionType.UNWATCHED
import com.edde746.plezy.servers.OfflineWatchActionType.WATCHED
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class OfflineWatchRepositoryTest {
    private val clock = TestClock()
    private val data = testData(clock)
    private val watch = data.offlineWatch
    private val srv = ServerId("srv")
    private val p = "p1"

    @AfterTest
    fun close() = data.close()

    /** A row written as it is, with the given times. */
    private suspend fun insertRaw(
        itemId: String,
        type: OfflineWatchActionType,
        updatedAt: Long,
        createdAt: Long = updatedAt,
        serverId: String = "s",
        profileId: String? = null,
        clientScopeId: String? = null,
    ): Long = data.db.write {
        q.offlineWatchQueries.insertAction(
            profileId, serverId, clientScopeId, itemId, "$serverId:$itemId", type.id, null, null, false, createdAt, updatedAt,
        )
        q.offlineWatchQueries.lastInsertId().executeAsOne()
    }

    private suspend fun progress(
        viewOffset: Long,
        shouldMarkWatched: Boolean = false,
        clientScopeId: String? = null,
        profileId: String? = p,
        itemId: String = "42",
    ) = watch.upsertProgress(profileId, srv, clientScopeId, itemId, viewOffset, 10_000, shouldMarkWatched)

    private suspend fun mark(
        type: OfflineWatchActionType,
        itemId: String = "42",
        clientScopeId: String? = null,
        profileId: String? = p,
    ) = watch.insertMark(profileId, srv, clientScopeId, itemId, type)

    /** Every profile's actions of the item, newest first. */
    private suspend fun actions(globalKey: String = "srv:42"): List<OfflineWatchAction> =
        watch.actionsForKeys(setOf(globalKey), profileId = null)[globalKey].orEmpty()

    @Test
    fun progressIsQueuedAsOneRowPerItem() = runTest {
        progress(5000)
        val row = watch.pendingActions(p).single()
        assertEquals("srv:42", row.globalKey)
        assertEquals(srv, row.serverId)
        assertEquals("42", row.itemId)
        assertNull(row.clientScopeId)
        assertEquals(PROGRESS, row.type)
        assertEquals(5000L, row.viewOffsetMs)
        assertEquals(10_000L, row.durationMs)
        assertFalse(row.shouldMarkWatched)
        assertEquals(0, row.syncAttempts)

        progress(9500, shouldMarkWatched = true)
        val merged = watch.pendingActions(p).single()
        assertEquals(row.rowId, merged.rowId)
        assertEquals(9500L, merged.viewOffsetMs)
        assertTrue(merged.shouldMarkWatched)
    }

    @Test
    fun aMergeIsANewRevisionEvenWithinOneMillisecondAndForgetsTheFailedOnesRetries() = runTest {
        val first = progress(1000)
        assertEquals(clock.now, first.revision)
        assertTrue(watch.recordFailedAttemptIfUnchanged(first.rowId, first.revision, "boom"))

        val second = progress(2000)
        assertEquals(first.rowId, second.rowId)
        assertEquals(first.revision + 1, second.revision)
        val row = watch.pendingActions(p).single()
        assertEquals(0, row.syncAttempts)
        assertNull(row.lastError)

        // Replay settles only the revision it sent.
        assertFalse(watch.deleteIfUnchanged(first.rowId, first.revision))
        assertFalse(watch.recordFailedAttemptIfUnchanged(first.rowId, first.revision, "late"))
        assertTrue(watch.deleteIfUnchanged(second.rowId, second.revision))
        assertEquals(emptyList(), watch.pendingActions(p))
    }

    @Test
    fun scopedUsersKeepSeparateProgress() = runTest {
        progress(1000, clientScopeId = "srv/user-a")
        progress(9000, shouldMarkWatched = true, clientScopeId = "srv/user-b")
        val rows = watch.pendingActions(p).sortedBy { it.clientScopeId }
        assertEquals(listOf("srv/user-a", "srv/user-b"), rows.map { it.clientScopeId })
        assertEquals(listOf(1000L, 9000L), rows.map { it.viewOffsetMs })
    }

    @Test
    fun aMarkReplacesTheItemsQueuedActions() = runTest {
        progress(5000)
        mark(WATCHED)
        val row = watch.pendingActions(p).single()
        assertEquals(WATCHED, row.type)
        assertNull(row.viewOffsetMs)

        mark(UNWATCHED)
        assertEquals(listOf(UNWATCHED), watch.pendingActions(p).map { it.type })
    }

    @Test
    fun aMarkReplacesOnlyTheSameProfileAndScopesActions() = runTest {
        progress(1000, clientScopeId = "srv/user-a")
        progress(2000, clientScopeId = "srv/user-b")
        progress(3000, profileId = "p2", clientScopeId = "srv/user-a")
        progress(4000, profileId = null, clientScopeId = "srv/user-a")
        mark(WATCHED, clientScopeId = "srv/user-a")
        assertEquals(
            setOf(Triple(p, "srv/user-a", WATCHED), Triple(p, "srv/user-b", PROGRESS), Triple("p2", "srv/user-a", PROGRESS), Triple(null, "srv/user-a", PROGRESS)),
            actions().map { Triple(it.profileId, it.clientScopeId, it.type) }.toSet(),
        )
    }

    @Test
    fun aMarkThatReachedTheServerDropsOnlyOlderQueuedProgress() = runTest {
        progress(5000, clientScopeId = "srv/user-a")
        progress(5000, clientScopeId = "srv/user-b")
        mark(UNWATCHED, itemId = "43", clientScopeId = "srv/user-a")
        assertEquals(1, watch.deleteProgress(p, srv, "srv/user-a", "42", beforeRevision = null))
        assertEquals(0, watch.deleteProgress(p, srv, "srv/user-a", "43", beforeRevision = null), "marks stay")
        assertEquals(listOf("srv/user-b" to PROGRESS, "srv/user-a" to UNWATCHED), watch.pendingActions(p).map { it.clientScopeId to it.type })

        // Settling a queued mark: progress as new as the mark or newer is a rewatch.
        val rewatch = progress(1000, clientScopeId = "srv/user-b")
        assertEquals(0, watch.deleteProgress(p, srv, "srv/user-b", "42", beforeRevision = rewatch.revision))
        assertEquals(1, watch.deleteProgress(p, srv, "srv/user-b", "42", beforeRevision = rewatch.revision + 1))
    }

    @Test
    fun replayIsOldestFirst() = runTest {
        insertRaw("1", WATCHED, updatedAt = 100, createdAt = 100, profileId = p)
        insertRaw("2", WATCHED, updatedAt = 50, createdAt = 50, profileId = p)
        insertRaw("3", WATCHED, updatedAt = 10, createdAt = 10, profileId = "p2")
        assertEquals(listOf("2", "1"), watch.pendingActions(p).map { it.itemId })
    }

    @Test
    fun theFirstProfileAdoptsActionsFromBeforeProfiles() = runTest {
        mark(WATCHED, itemId = "1", profileId = null)
        mark(WATCHED, itemId = "2", profileId = "profile-existing")
        watch.adoptLegacyActions("")
        assertEquals(listOf<String?>(null), actions("srv:1").map { it.profileId })

        watch.adoptLegacyActions("profile-a")
        assertEquals(listOf("1"), watch.pendingActions("profile-a").map { it.itemId })
        assertEquals(listOf("2"), watch.pendingActions("profile-existing").map { it.itemId })
    }

    @Test
    fun readsAreNewestFirstWithTheLaterRowWinningATie() = runTest {
        val oldest = insertRaw("ordered", PROGRESS, updatedAt = 100)
        val olderTie = insertRaw("ordered", WATCHED, updatedAt = 200)
        val newerTie = insertRaw("ordered", UNWATCHED, updatedAt = 200)
        assertEquals(listOf(newerTie, olderTie, oldest), actions("s:ordered").map { it.rowId })
    }

    @Test
    fun readsTellANullScopeFromACompoundOne() = runTest {
        val nullScope = insertRaw("scoped", UNWATCHED, updatedAt = 100)
        val compound = insertRaw("scoped", WATCHED, updatedAt = 200, clientScopeId = "s/user-a")
        suspend fun inScope(scope: String?) =
            watch.actionsForKeys(setOf("s:scoped"), profileId = null, clientScopeIdsByGlobalKey = mapOf("s:scoped" to scope)).getValue("s:scoped").map { it.rowId }
        assertEquals(listOf(nullScope), inScope(null))
        assertEquals(listOf(compound), inScope("s/user-a"))
        assertEquals(listOf(nullScope), inScope(""), "an empty scope is none")
        assertEquals(listOf(compound, nullScope), actions("s:scoped").map { it.rowId }, "a key the map doesn't name isn't filtered")
    }

    @Test
    fun readsIsolateProfiles() = runTest {
        val profileA = insertRaw("profiled", UNWATCHED, updatedAt = 100, profileId = "profile-a")
        val profileB = insertRaw("profiled", WATCHED, updatedAt = 200, profileId = "profile-b")
        val legacy = insertRaw("profiled", WATCHED, updatedAt = 300)
        assertEquals(listOf(profileA), watch.actionsForKeys(setOf("s:profiled"), profileId = "profile-a").getValue("s:profiled").map { it.rowId })
        assertEquals(listOf(legacy, profileB, profileA), actions("s:profiled").map { it.rowId }, "unfiltered: every profile")
    }

    @Test
    fun readsTakeWildcardCharactersLiterally() = runTest {
        val exact = insertRaw("item%_", WATCHED, updatedAt = 100, serverId = "server_%", profileId = "profile_%", clientScopeId = "server_%/user_1")
        insertRaw("item%_", UNWATCHED, updatedAt = 400, serverId = "server_%", profileId = "profile_abc", clientScopeId = "server_%/user_1")
        insertRaw("item%_", UNWATCHED, updatedAt = 300, serverId = "server_%", profileId = "profile_%", clientScopeId = "server_abc/user_a")
        insertRaw("itemZZZx", UNWATCHED, updatedAt = 200, serverId = "server_abc", profileId = "profile_%", clientScopeId = "server_%/user_1")
        val key = "server_%:item%_"

        val batched = watch.actionsForKeys(setOf(key), profileId = "profile_%", clientScopeIdsByGlobalKey = mapOf(key to "server_%/user_1"))
        assertEquals(setOf(key), batched.keys)
        val action = batched.getValue(key).single()
        assertEquals(exact, action.rowId)
        assertEquals(ServerId("server_%"), action.serverId)
        assertEquals("item%_", action.itemId)
    }

    @Test
    fun batchedReadsListOnlyKeysWithActions() = runTest {
        insertRaw("1", PROGRESS, updatedAt = 1000)
        insertRaw("1", WATCHED, updatedAt = 1100)
        insertRaw("2", UNWATCHED, updatedAt = 1000)
        val actions = watch.actionsForKeys(setOf("s:1", "s:2", "s:3-missing"), profileId = null)
        assertEquals(setOf("s:1", "s:2"), actions.keys)
        assertEquals(listOf(WATCHED, PROGRESS), actions.getValue("s:1").map { it.type })
        assertEquals(listOf(UNWATCHED), actions.getValue("s:2").map { it.type })
        assertEquals(emptyMap(), watch.actionsForKeys(emptySet(), profileId = null))
    }

    @Test
    fun aFailedReplayCountsAnAttemptAndKeepsTheLastError() = runTest {
        val queued = mark(WATCHED)
        assertTrue(watch.recordFailedAttemptIfUnchanged(queued.rowId, queued.revision, "boom"))
        var row = watch.pendingActions(p).single()
        assertEquals(1, row.syncAttempts)
        assertEquals("boom", row.lastError)

        assertTrue(watch.recordFailedAttemptIfUnchanged(row.rowId, row.updatedAt, null))
        row = watch.pendingActions(p).single()
        assertEquals(2, row.syncAttempts)
        assertNull(row.lastError)

        assertFalse(watch.recordFailedAttemptIfUnchanged(999, 0, "irrelevant"))
        assertFalse(watch.deleteIfUnchanged(999, 0))
    }

    @Test
    fun deleteIfUnchangedRemovesOnlyThatRow() = runTest {
        val first = mark(WATCHED, itemId = "1")
        mark(WATCHED, itemId = "2")
        assertTrue(watch.deleteIfUnchanged(first.rowId, first.revision))
        assertEquals(listOf("2"), watch.pendingActions(p).map { it.itemId })
    }

    @Test
    fun pendingCountCountsActionsStillToRetry() = runTest {
        assertEquals(0, watch.pendingCount(profileId = null, maxSyncAttempts = 5))
        val first = mark(WATCHED, itemId = "1")
        mark(UNWATCHED, itemId = "2", profileId = null)
        assertEquals(2, watch.pendingCount(profileId = null, maxSyncAttempts = 5))
        assertEquals(1, watch.pendingCount(profileId = p, maxSyncAttempts = 5))
        watch.recordFailedAttemptIfUnchanged(first.rowId, first.revision, "boom")
        assertEquals(1, watch.pendingCount(profileId = null, maxSyncAttempts = 1))
        assertEquals(0, watch.pendingCount(profileId = p, maxSyncAttempts = 1))
    }

    @Test
    fun aProfilesActionsGoWithItAndClearAllEmptiesTheQueue() = runTest {
        mark(WATCHED, itemId = "1")
        mark(WATCHED, itemId = "2", profileId = "p2")
        mark(UNWATCHED, itemId = "3", profileId = null)
        watch.deleteForProfile(p)
        assertEquals(0, watch.pendingCount(profileId = p, maxSyncAttempts = 5))
        assertEquals(2, watch.pendingCount(profileId = null, maxSyncAttempts = 5))
        watch.clearAll()
        assertEquals(0, watch.pendingCount(profileId = null, maxSyncAttempts = 5))
    }
}
