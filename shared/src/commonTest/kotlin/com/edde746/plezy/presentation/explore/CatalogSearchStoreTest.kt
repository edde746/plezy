package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

class CatalogSearchStoreTest {
    private val source = FakeCatalogSource(CatalogSourceId.TRAKT)

    private fun TestScope.store() = CatalogSearchStore(source, backgroundScope)

    private fun CatalogSearchStore.titles() = assertIs<CatalogSearchBody.Results>(state.value.body).items.map { it.title }

    private fun TestScope.settle() {
        advanceTimeBy(600.milliseconds)
        runCurrent()
    }

    @Test
    fun itPromptsUntilTheFirstSearch() = runTest {
        val store = store()
        assertEquals(T.explore.searchHint(isolate("Trakt")), store.state.value.title)
        assertEquals(CatalogSearchBody.Idle(T.explore.searchPrompt(isolate("Trakt"))), store.state.value.body)

        store.setQuery("abc")
        assertEquals(CatalogSearchBody.Idle(T.explore.searchPrompt(isolate("Trakt"))), store.state.value.body)
        settle()
        assertEquals(listOf("Trakt search: abc"), store.titles())
    }

    @Test
    fun revertingToTheLastSearchedQueryCancelsThePendingDebounce() = runTest {
        val store = store()
        store.setQuery("abc")
        settle()
        assertEquals(listOf("abc"), source.searchQueries)

        // Typed ahead, then back to the query shown before the wait ended: the armed search never runs.
        store.setQuery("abcd")
        advanceTimeBy(100.milliseconds)
        store.setQuery("abc")
        advanceTimeBy(700.milliseconds)
        runCurrent()

        assertEquals(listOf("abc"), source.searchQueries)
        assertEquals(listOf("Trakt search: abc"), store.titles())
    }

    @Test
    fun revertingWhileASearchRunsDropsItsAnswer() = runTest {
        val store = store()
        store.setQuery("abc")
        settle()

        source.searchGate = CompletableDeferred()
        store.setQuery("abcd")
        settle()
        assertEquals(CatalogSearchBody.Loading, store.state.value.body)

        store.setQuery("abc")
        source.searchGate?.complete(Unit)
        runCurrent()
        assertEquals(listOf("Trakt search: abc"), store.titles())
    }

    @Test
    fun aFailedSearchShowsTheFailureAndRecoversOnRetryOrTheNextQuery() = runTest {
        val store = store()
        source.searchFails = true
        store.setQuery("abc")
        settle()
        assertEquals(CatalogSearchBody.Failed(T.explore.searchFailed), store.state.value.body)

        source.searchFails = false
        store.retry()
        runCurrent()
        assertEquals(listOf("Trakt search: abc"), store.titles())

        store.setQuery("abcd")
        settle()
        assertEquals(listOf("Trakt search: abcd"), store.titles())
    }

    @Test
    fun noHitsSayNothingWasFoundForTheQuery() = runTest {
        val store = store()
        source.searchTitles = emptyList()
        store.setQuery("zzz")
        settle()
        assertEquals(CatalogSearchBody.Empty(T.explore.searchEmpty(isolate("zzz"))), store.state.value.body)
    }

    @Test
    fun submitRunsTheWaitingSearchNowThenMovesToTheResults() = runTest {
        val store = store()
        store.setQuery("abc")
        assertFalse(store.submit())
        runCurrent()
        assertEquals(listOf("abc"), source.searchQueries)
        assertEquals(listOf("Trakt search: abc"), store.titles())

        assertTrue(store.submit())
        settle()
        assertEquals(listOf("abc"), source.searchQueries)
    }

    @Test
    fun clearingTheFieldPromptsAgain() = runTest {
        val store = store()
        store.setQuery("abc")
        settle()
        store.setQuery("  ")
        assertIs<CatalogSearchBody.Idle>(store.state.value.body)
        settle()
        assertEquals(listOf("abc"), source.searchQueries)
    }
}
