package com.edde746.plezy.servers

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class NotifiersTest {
    private val deletions = DeletionNotifier()

    private fun deletion(serverId: String, itemId: String, parentChain: List<String> = emptyList(), kind: MediaKind = MediaKind.MOVIE) =
        DeletionEvent(itemId = itemId, serverId = ServerId(serverId), parentChain = parentChain, kind = kind)

    private fun <E> TestScope.collect(flow: Flow<E>): List<E> {
        val received = mutableListOf<E>()
        backgroundScope.launch { flow.collect { received += it } }
        runCurrent()
        return received
    }

    private fun TestScope.notify(vararg events: DeletionEvent) {
        events.forEach(deletions::notify)
        runCurrent()
    }

    @Test
    fun filtersByServerIdWhenProvided() = runTest {
        val received = collect(deletions.events.affecting(serverId = { ServerId("s1") }, itemIds = { null }))
        val keep = deletion("s1", "1")

        notify(deletion("s2", "1"), keep)

        assertEquals(listOf(keep), received)
    }

    @Test
    fun globalKeysFilterDeliversEventsMatchingAnyGlobalKey() = runTest {
        val keys = setOf(buildGlobalKey(ServerId("s1"), "42"), buildGlobalKey(ServerId("s1"), "7"))
        val received = collect(deletions.events.affecting(globalKeys = { keys }, itemIds = { null }))
        val hit = deletion("s1", "42")

        notify(hit, deletion("s1", "9999"))

        assertEquals(listOf(hit), received)
    }

    @Test
    fun globalKeysFilterTakesPrecedenceOverItemIds() = runTest {
        val received = collect(deletions.events.affecting(globalKeys = { setOf("s1:99") }, itemIds = { setOf("5") }))

        notify(deletion("s1", "5"))
        assertTrue(received.isEmpty())

        val hit = deletion("s1", "99")
        notify(hit)
        assertEquals(listOf(hit), received)
    }

    @Test
    fun nullItemIdsDeliversAllEvents() = runTest {
        val received = collect(deletions.events.affecting(itemIds = { null }))
        val a = deletion("s1", "1")
        val b = deletion("s2", "2")

        notify(a, b)

        assertEquals(listOf(a, b), received)
    }

    @Test
    fun emptyItemIdsDeliversNothing() = runTest {
        val received = collect(deletions.events.affecting(itemIds = { emptySet() }))

        notify(deletion("s1", "1"), deletion("s2", "2"))

        assertTrue(received.isEmpty())
    }

    @Test
    fun itemIdsFilterDeliversDirectHits() = runTest {
        val received = collect(deletions.events.affecting(itemIds = { setOf("42") }))
        val hit = deletion("s1", "42")

        notify(hit, deletion("s1", "99"))

        assertEquals(listOf(hit), received)
    }

    @Test
    fun itemIdsFilterDeliversParentChainHits() = runTest {
        val received = collect(deletions.events.affecting(itemIds = { setOf("show123") }))
        val season = deletion("s1", "season789", parentChain = listOf("show123"), kind = MediaKind.SEASON)

        notify(season)

        assertEquals(listOf(season), received)
    }

    @Test
    fun filtersReEvaluateOnEachEvent() = runTest {
        var ids = setOf("1")
        val received = collect(deletions.events.affecting(itemIds = { ids }))

        notify(deletion("s1", "1"), deletion("s1", "2"))
        assertEquals(listOf("1"), received.map { it.itemId })

        ids = setOf("2")
        notify(deletion("s1", "1"), deletion("s1", "2"))
        assertEquals(listOf("1", "2"), received.map { it.itemId })
    }

    @Test
    fun globalKeyMatchCoversAncestors() {
        val event = deletion("s1", "episode", parentChain = listOf("season", "show"))

        assertTrue(event.affectsAnyGlobalKey(setOf("s1:show")))
        assertTrue(event.affectsItem("season"))
        assertEquals(false, event.affectsAnyGlobalKey(setOf("s2:show")))
    }

    @Test
    fun deletedItemCarriesItsHierarchyAndLeafCount() = runTest {
        val received = collect(deletions.events)
        val season = MediaItem(id = "season-1", backend = BackendKind.PLEX, kind = MediaKind.SEASON, parentId = "show-1", leafCount = 8, serverId = "s1")

        deletions.notifyDeletedItem(season, isDownloadOnly = true)
        deletions.notifyDeletedItem(season.copy(serverId = null))
        runCurrent()

        assertEquals(
            listOf(DeletionEvent("season-1", ServerId("s1"), listOf("show-1"), MediaKind.SEASON, leafCount = 8, isDownloadOnly = true)),
            received,
        )
    }

    @Test
    fun hierarchicalKeysIncludeParentsAndCollapseWithoutAServer() {
        val episode = MediaItem(id = "ep", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, parentId = "season", grandparentId = "show", serverId = "s1")
        val orphan = episode.copy(id = "orphan", serverId = null)

        assertEquals(setOf("ep", "season", "show"), hierarchicalEventIds(listOf(episode)))
        assertEquals(setOf("s1:ep", "s1:season", "s1:show"), hierarchicalEventGlobalKeys(listOf(episode)))
        assertNull(hierarchicalEventGlobalKeys(listOf(episode, orphan)))
        assertEquals(setOf("s2:orphan", "s2:season", "s2:show"), hierarchicalEventGlobalKeys(listOf(orphan), fallbackServerId = ServerId("s2")))
    }
}
