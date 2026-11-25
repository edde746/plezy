package com.edde746.plezy.presentation.explore

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

private fun item(title: String, year: Int) =
    MediaItem(id = title, backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = title, year = year)

private val shelf = listOf(item("Beta", 2001), item("Alpha", 1999), item("Gamma", 2010))

private fun TestScope.store(all: List<MediaItem>) = ExploreRowStore(
    ExploreRow(MediaHub("explore.trending", "Trending", "movie", all.take(1), size = all.size, more = true), ExploreRowIcon.TRENDING),
    loadAll = { all },
    parentScope = CoroutineScope(backgroundScope.coroutineContext + UnconfinedTestDispatcher(testScheduler)),
)

private fun ExploreRowUiState.titles() = (body as ExploreRowBody.Items).items.map { it.title }

class ExploreRowStoreTest {
    @Test
    fun aViewAllOffersTheHubSortsAndOrdersEveryLoadedItemByThePickedOne() = runTest {
        val store = store(shelf)
        val state = store.state.value
        assertEquals(listOf("titleSort", "year", "addedAt", "rating"), state.sortOptions.map { it.key })
        assertEquals(listOf("Beta", "Alpha", "Gamma"), state.titles())

        store.setSort(state.sortOptions.first { it.key == "year" }, descending = true)
        assertEquals(listOf("Gamma", "Beta", "Alpha"), store.state.value.titles())

        store.setSort(state.sortOptions.first { it.key == "titleSort" }, descending = false)
        assertEquals(listOf("Alpha", "Beta", "Gamma"), store.state.value.titles())
    }

    @Test
    fun resettingTheSortGivesBackTheShelfsOrder() = runTest {
        val store = store(shelf)
        store.setSort(store.state.value.sortOptions.first(), descending = true)

        store.setSort(null, descending = true)

        assertEquals(listOf("Beta", "Alpha", "Gamma"), store.state.value.titles())
        assertEquals(false, store.state.value.descending)
    }

    @Test
    fun theSortMenuLeadsWithClearAndTheDirectionsOnceAnOrderIsSet() = runTest {
        val store = store(shelf)
        fun choices() = store.state.value.sortChoices
        fun labels() = choices().map { it.label }
        fun checked() = choices().filter { it.selected }.map { it.label }
        val fields = store.state.value.sortOptions.map { it.title }
        assertEquals(fields, labels(), "the page's own order: the orders alone")
        assertEquals(emptyList(), checked())

        store.pickSort(1)
        assertEquals(listOf(T.common.clear, T.libraries.ascending, T.libraries.descending) + fields, labels())
        assertEquals(listOf(null, "", null, T.libraries.sortBy), choices().take(4).map { it.heading }, "the directions, then the orders under Sort By")
        assertEquals(listOf(T.libraries.descending, fields[1]), checked(), "an order picked from the page's own takes its own direction")
        assertEquals(listOf("Gamma", "Beta", "Alpha"), store.state.value.titles())

        store.pickSort(4)
        assertEquals(listOf(T.libraries.descending, fields[1]), checked(), "the order in effect picked again changes nothing")

        store.pickSort(1)
        assertEquals(listOf(T.libraries.ascending, fields[1]), checked())
        assertEquals(listOf("Alpha", "Beta", "Gamma"), store.state.value.titles())

        store.pickSort(3)
        assertEquals(listOf(T.libraries.ascending, fields[0]), checked(), "another order keeps the direction")

        store.pickSort(0)
        assertEquals(fields, labels(), "Clear: the orders alone again")
        assertEquals(emptyList(), checked())
        assertEquals(listOf("Beta", "Alpha", "Gamma"), store.state.value.titles())
    }
}
