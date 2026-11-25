package com.edde746.plezy.data.downloads

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SyncRuleRepositoryTest {
    private val clock = TestClock()
    private val data = testData(clock)
    private val rules = data.syncRules

    private suspend fun links(ruleId: Long): List<String> = data.db.read { syncRuleQueries.selectLinkedKeys(ruleId).executeAsList() }
    private val srv = ServerId("srv")

    @AfterTest
    fun close() = data.close()

    private suspend fun show(ratingKey: String = "10", profileId: String = "", episodeCount: Int = 5) =
        rules.upsert(profileId, srv, ratingKey, SyncRuleTarget.SHOW, episodeCount)

    @Test
    fun aRuleIsKeyedByProfileAndItem() = runTest {
        val legacy = show()
        assertEquals("srv:10", legacy.globalKey)
        assertEquals("", legacy.profileId)
        assertTrue(legacy.enabled)
        assertNull(legacy.lastExecutedAt)

        val a = show(profileId = "profile-a", episodeCount = 5)
        val b = show(profileId = "profile-b", episodeCount = 9)
        assertEquals("profile-a|srv:10", a.globalKey)
        assertEquals("profile-b|srv:10", b.globalKey)
        assertEquals(listOf(5), rules.rules("profile-a").map { it.episodeCount })
        assertEquals(listOf(9), rules.rules("profile-b").map { it.episodeCount })
        assertEquals(3, rules.rules().size)
        assertEquals(a, rules.rule("profile-a|srv:10"))
        assertNull(rules.rule("srv:nope"))
    }

    @Test
    fun creatingTheRuleAgainUpdatesItKeepingEnabledAndLastRun() = runTest {
        val created = show()
        rules.setEnabled(created.globalKey, false)
        clock.now += 1000
        rules.completeExecution(created.globalKey)

        val updated = rules.upsert("", srv, "10", SyncRuleTarget.SEASON, 99, mediaIndex = 2, downloadFilter = SyncRuleFilter.ALL, includeSpecials = false)
        assertEquals(created.id, updated.id)
        assertEquals(1, rules.rules().size)
        assertEquals(SyncRuleTarget.SEASON, updated.target)
        assertEquals(99, updated.episodeCount)
        assertEquals(2, updated.mediaIndex)
        assertEquals(SyncRuleFilter.ALL, updated.downloadFilter)
        assertFalse(updated.includeSpecials)
        assertFalse(updated.enabled, "an update keeps a disabled rule disabled")
        assertEquals(clock.now, updated.lastExecutedAt)
        assertTrue(updated.downloadLinksInitialized)
        assertEquals(created.createdAt, updated.createdAt)
    }

    @Test
    fun updateOptionsChangesOnlyWhatItIsGiven() = runTest {
        val created = show()
        val counted = rules.updateOptions(created, episodeCount = 12)
        assertEquals(12, counted.episodeCount)
        assertEquals(SyncRuleTarget.SHOW, counted.target)
        assertEquals(SyncRuleFilter.UNWATCHED, counted.downloadFilter)

        val filtered = rules.updateOptions(counted, downloadFilter = SyncRuleFilter.ALL, enabled = false)
        assertEquals(12, filtered.episodeCount)
        assertEquals(SyncRuleFilter.ALL, filtered.downloadFilter)
        assertFalse(filtered.enabled)
    }

    @Test
    fun updateOptionsRefusesARuleDeletedAndCreatedAgain() = runTest {
        val stale = show()
        rules.delete(stale.globalKey)
        assertFailsWith<IllegalStateException> { rules.updateOptions(stale, episodeCount = 1) }
        val recreated = show()
        assertNotEquals(stale.id, recreated.id)
        assertFailsWith<IllegalStateException> { rules.updateOptions(stale, episodeCount = 1) }
        assertEquals(5, rules.rule(recreated.globalKey)?.episodeCount)
    }

    @Test
    fun setEnabledToggles() = runTest {
        val created = show()
        rules.setEnabled(created.globalKey, false)
        assertEquals(false, rules.rule(created.globalKey)?.enabled)
        rules.setEnabled(created.globalKey, true)
        assertEquals(true, rules.rule(created.globalKey)?.enabled)
    }

    @Test
    fun completingARunStampsItAndMarksTheLinksRecorded() = runTest {
        val created = show()
        assertFalse(created.downloadLinksInitialized)
        clock.now += 5
        rules.completeExecution(created.globalKey)
        val rule = rules.rule(created.globalKey)!!
        assertEquals(clock.now, rule.lastExecutedAt)
        assertTrue(rule.downloadLinksInitialized)
    }

    @Test
    fun deletingARuleRemovesItAndItsLinks() = runTest {
        val first = show("10")
        val second = show("11")
        rules.linkDownload(first, "srv:e1")
        rules.delete(first.globalKey)
        assertEquals(listOf("srv:11"), rules.rules().map { it.globalKey })
        assertEquals(emptyList(), links(first.id))
        assertEquals(listOf(second), rules.rules())
    }

    @Test
    fun exclusiveDownloadKeysKeepDownloadsAnotherRuleOfTheProfileCovers() = runTest {
        suspend fun playlist(profileId: String, id: String) = rules.upsert(profileId, srv, id, SyncRuleTarget.PLAYLIST, 0)
        val target = playlist("profile-a", "playlist-a")
        val sibling = playlist("profile-a", "playlist-b")
        val otherProfile = playlist("profile-b", "playlist-c")
        rules.linkDownload(target, "srv:exclusive")
        rules.linkDownload(target, "srv:sibling-shared")
        rules.linkDownload(target, "srv:profile-shared")
        rules.linkDownload(target, "srv:exclusive")
        rules.linkDownload(sibling, "srv:sibling-shared")
        rules.linkDownload(otherProfile, "srv:profile-shared")

        assertEquals(setOf("srv:exclusive", "srv:profile-shared"), rules.exclusiveDownloadKeys(target).toSet())
        assertEquals(emptyList(), rules.exclusiveDownloadKeys(rules.upsert("profile-a", srv, "none", SyncRuleTarget.PLAYLIST, 0)))
    }

    @Test
    fun theFirstProfileAdoptsRulesFromBeforeProfiles() = runTest {
        val legacy = show("10")
        val duplicate = show("11")
        rules.linkDownload(legacy, "srv:e1")
        rules.linkDownload(duplicate, "srv:e2")
        val owned = show("11", profileId = "p1", episodeCount = 3)

        rules.adoptLegacyRulesForProfile("")
        assertEquals(3, rules.rules().size)

        rules.adoptLegacyRulesForProfile("p1")
        assertEquals(listOf("p1|srv:10", "p1|srv:11"), rules.rules().map { it.globalKey }.sorted())
        assertEquals(emptyList(), rules.rules(""))
        val adopted = rules.rule("p1|srv:10")!!
        assertEquals(legacy.id, adopted.id)
        assertEquals(3, rules.rule("p1|srv:11")?.episodeCount, "the profile's own rule wins")
        assertEquals(owned.id, rules.rule("p1|srv:11")?.id)
        // The adopted rule's links moved with it.
        assertEquals(listOf("srv:e1"), rules.exclusiveDownloadKeys(adopted))
        assertEquals(emptyList(), links(duplicate.id))
    }

    @Test
    fun linksAreRefreshedForUnlinkedRulesAndEveryShowOrSeasonRule() = runTest {
        val unlinked = rules.upsert("p1", srv, "c1", SyncRuleTarget.COLLECTION, 0)
        val linked = rules.upsert("p1", srv, "c2", SyncRuleTarget.COLLECTION, 0)
        rules.markDownloadLinksInitialized(linked.globalKey)
        val showRule = show("s1", profileId = "p1")
        rules.completeExecution(showRule.globalKey)
        rules.upsert("p1", ServerId("other"), "c3", SyncRuleTarget.COLLECTION, 0)
        rules.upsert("p2", srv, "c4", SyncRuleTarget.COLLECTION, 0)

        assertEquals(listOf(unlinked.globalKey, showRule.globalKey), rules.rulesNeedingLinks("p1", srv).map { it.globalKey })
    }

    @Test
    fun ownedDownloadsUnderAnItemAreTheProfilesLiveOnes() = runTest {
        // status: 0 queued, 2 paused, 3 completed, 4 failed.
        media("srv:e1", parent = "season1", grandparent = "show1", status = 3)
        media("srv:e2", parent = "season1", grandparent = "show1", status = 0)
        media("srv:e3", parent = "season2", grandparent = "show1", status = 2)
        media("srv:e4", parent = "season1", grandparent = "show1", status = 4)
        media("srv:e5", parent = "season1", grandparent = "show1", status = 3, owner = "p2")
        media("other:e6", parent = "season1", grandparent = "show1", status = 3, serverId = "other")
        media("srv:s1", parent = "show1", grandparent = null, status = 3)

        assertEquals(listOf("srv:e1", "srv:e2"), rules.ownedDownloadKeysUnder("p1", srv, "season1", matchGrandparent = false))
        assertEquals(listOf("srv:s1"), rules.ownedDownloadKeysUnder("p1", srv, "show1", matchGrandparent = false))
        assertEquals(listOf("srv:e1", "srv:e2", "srv:e3", "srv:s1"), rules.ownedDownloadKeysUnder("p1", srv, "show1", matchGrandparent = true))
    }

    @Test
    fun aProfilesRulesGoWithItAndClearAllRemovesEveryRule() = runTest {
        val gone = show("10", profileId = "p1")
        rules.linkDownload(gone, "srv:e1")
        show("10", profileId = "p2")
        show("11")
        rules.deleteForProfile("p1")
        assertEquals(listOf("p2|srv:10", "srv:11"), rules.rules().map { it.globalKey })
        assertEquals(emptyList(), links(gone.id))
        rules.clearAll()
        assertEquals(emptyList(), rules.rules())
    }

    private fun media(globalKey: String, parent: String, grandparent: String?, status: Int, owner: String = "p1", serverId: String = "srv") {
        val ratingKey = globalKey.substringAfter(':')
        data.driver.execute(
            null,
            "INSERT INTO downloaded_media(server_id, rating_key, global_key, type, parent_rating_key, grandparent_rating_key, status) " +
                "VALUES ('$serverId', '$ratingKey', '$globalKey', 'episode', '$parent', ${grandparent?.let { "'$it'" } ?: "NULL"}, $status)",
            0,
        )
        data.driver.execute(null, "INSERT INTO download_owners(profile_id, global_key, created_at) VALUES ('$owner', '$globalKey', 0)", 0)
    }
}
