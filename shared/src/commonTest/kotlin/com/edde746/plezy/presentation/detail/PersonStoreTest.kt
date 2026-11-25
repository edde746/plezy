package com.edde746.plezy.presentation.detail

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PersonStoreTest {
    private val server = ServerId("srv")
    private var titles = (1..250).map { MediaItem(id = "t$it", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = "Title $it") }
    private var failing = false

    /** Each requested page as start and size. */
    private val requests = mutableListOf<Pair<Int?, Int?>>()

    private val backend = FakeMediaBackend("srv").apply {
        personDetails = { MediaPersonDetails.EMPTY }
        personMediaPage = { personId, start, size ->
            check(personId == "p1")
            requests += start to size
            if (failing) error("offline")
            val from = start ?: 0
            LibraryPage(titles.drop(from).take(size ?: titles.size), titles.size, from)
        }
    }

    private fun TestScope.store() = PersonStore(
        Route.Person(server, "p1", "Actor"),
        backend,
        { CardOptions() },
        { CalendarDate(2026, 1, 1) },
        backgroundScope,
    )

    @Test
    fun `the filmography loads its first page and leaves a blank card for each title still to load`() = runTest {
        val store = store()
        runCurrent()
        val state = store.state.value
        assertEquals(listOf<Pair<Int?, Int?>>(0 to 200), requests)
        assertEquals(SectionLoad.CONTENT, state.grid.load)
        assertEquals(200, state.grid.items.size)
        assertEquals(250, state.grid.total)
        assertEquals("250 titles", state.titleCount)
    }

    @Test
    fun `reaching a blank card loads the next page and a loaded card loads nothing`() = runTest {
        val store = store()
        runCurrent()
        store.ensureLoaded(150)
        runCurrent()
        assertEquals(1, requests.size)
        store.ensureLoaded(210)
        runCurrent()
        assertEquals(listOf<Pair<Int?, Int?>>(0 to 200, 200 to 200), requests)
        assertEquals(250, store.state.value.grid.items.size)
        store.ensureLoaded(249)
        runCurrent()
        assertEquals(2, requests.size)
    }

    @Test
    fun `a title opens its detail seeded with the title`() = runTest {
        val store = store()
        runCurrent()
        val route = store.routeFor(store.state.value.grid.items.first().id) as Route.MediaDetail
        assertEquals(Route.MediaDetail(server, "t1"), route)
        assertEquals("Title 1", route.seed?.title)
    }

    @Test
    fun `no titles show the empty grid`() = runTest {
        titles = emptyList()
        val store = store()
        runCurrent()
        assertEquals(SectionLoad.EMPTY, store.state.value.grid.load)
        assertEquals("0 titles", store.state.value.titleCount)
    }

    @Test
    fun `a failed first page shows its error and Retry loads it`() = runTest {
        failing = true
        val store = store()
        runCurrent()
        assertEquals(SectionLoad.ERROR, store.state.value.grid.load)
        assertEquals(T.messages.errorLoading(error = T.errors.reasonUnexpected), store.state.value.grid.error)
        assertNull(store.state.value.titleCount)
        failing = false
        store.retry()
        runCurrent()
        assertEquals(SectionLoad.CONTENT, store.state.value.grid.load)
        assertEquals(200, store.state.value.grid.items.size)
    }

    @Test
    fun `a failed later page shows Retry keeps the loaded cards and Retry loads it`() = runTest {
        val store = store()
        runCurrent()
        failing = true
        store.ensureLoaded(200)
        runCurrent()
        val failed = store.state.value.grid
        assertEquals(SectionLoad.CONTENT, failed.load)
        assertEquals(200, failed.items.size)
        assertEquals(T.messages.errorLoading(error = T.errors.reasonUnexpected), failed.moreError)
        // A blank card showing again asks nothing: Retry does.
        store.ensureLoaded(200)
        runCurrent()
        assertEquals(2, requests.size)
        failing = false
        store.retry()
        runCurrent()
        assertNull(store.state.value.grid.moreError)
        assertEquals(250, store.state.value.grid.items.size)
    }

    @Test
    fun `the page settles once both the details and the first page are in`() = runTest {
        val details = CompletableDeferred<MediaPersonDetails>()
        val firstPage = CompletableDeferred<Unit>()
        backend.personDetails = { details.await() }
        val pages = backend.personMediaPage
        backend.personMediaPage = { id, start, size ->
            firstPage.await()
            pages(id, start, size)
        }
        val store = store()
        runCurrent()
        assertFalse(store.state.value.settled)
        firstPage.complete(Unit)
        runCurrent()
        assertFalse(store.state.value.settled, "the titles alone")
        details.complete(MediaPersonDetails(biography = "Bio"))
        runCurrent()
        assertTrue(store.state.value.settled)
        assertEquals("Bio", store.state.value.biography)
    }

    @Test
    fun `failed details and a failed first page settle the page`() = runTest {
        failing = true
        backend.personDetails = { error("offline") }
        val store = store()
        runCurrent()
        assertTrue(store.state.value.settled)
        assertEquals(SectionLoad.ERROR, store.state.value.grid.load)
    }
}
