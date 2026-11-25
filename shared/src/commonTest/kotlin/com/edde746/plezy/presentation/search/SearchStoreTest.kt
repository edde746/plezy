package com.edde746.plezy.presentation.search

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPerson
import com.edde746.plezy.model.PersonCredit
import com.edde746.plezy.model.SearchHit
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.rankSearchHits
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.metadata.EditedItem
import com.edde746.plezy.servers.SearchAggregationResult
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SearchStoreTest {
    private val server = ServerId("a")
    private val queries = mutableListOf<String>()
    private val hidden = MutableStateFlow(emptySet<String>())
    private var answer: suspend (String) -> SearchAggregationResult = { ok(it, emptyList()) }
    private var serverCount = 1
    private var libraryLabel: (MediaItem) -> String? = { null }
    private val opened = mutableListOf<MediaItem>()
    private val menus = mutableListOf<MediaItem>()
    private val watchStates = MutableSharedFlow<WatchStateEvent>()
    private val edits = MutableSharedFlow<EditedItem>()
    private var fetched: (String) -> MediaItem? = { null }
    private val expired = MutableStateFlow(emptyList<String>())

    private fun movie(id: String, title: String, kind: MediaKind = MediaKind.MOVIE, library: String = "1") =
        MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, title = title, serverId = "a", libraryId = library)

    private fun ok(query: String, items: List<MediaItem>, people: List<MediaPerson> = emptyList(), failed: Set<ServerId> = emptySet()) =
        SearchAggregationResult(
            rankSearchHits(items.map { SearchHit.Media(it) } + people.map { SearchHit.Person(it) }, query, 100),
            items, people, setOf(server), emptySet(), failed,
        )

    private fun TestScope.store() = SearchStore(
        SearchDeps(
            search = { q, keys ->
                queries += q
                val result = answer(q)
                result.copy(
                    hits = result.hits.filter { it !is SearchHit.Media || "a:${it.item.libraryId}" !in keys },
                    candidates = result.candidates.filter { "a:${it.libraryId}" !in keys },
                )
            },
            hiddenLibrariesReady = {},
            hiddenLibraryKeys = { hidden.value },
            hiddenLibraryChanges = hidden,
            client = { null },
            serverCount = { serverCount },
            libraryLabel = { libraryLabel(it) },
            cardOptions = { CardOptions() },
            open = { opened += it },
            menu = { menus += it },
            watchStates = watchStates,
            edited = edits,
            fetchItem = { _, id -> fetched(id) },
            sessionExpired = expired,
        ),
        backgroundScope,
    )

    @Test
    fun `a field focus asked before the screen shows reaches it once`() = runTest {
        val store = store()
        store.focusField()
        store.focusField()
        var focused = 0
        backgroundScope.launch { store.fieldFocusRequests.collect { focused++ } }
        runCurrent()
        assertEquals(1, focused)
        store.focusField()
        runCurrent()
        assertEquals(2, focused)
    }

    @Test
    fun `searches once the text rests for 500ms`() = runTest {
        val store = store()
        store.setQuery("ma")
        advanceTimeBy(300)
        store.setQuery("mat")
        advanceTimeBy(499)
        assertTrue(queries.isEmpty())
        advanceTimeBy(2)
        runCurrent()
        assertEquals(listOf("mat"), queries)
    }

    @Test
    fun `editing cancels the stale request and its answer never lands`() = runTest {
        val gate = CompletableDeferred<Unit>()
        answer = { q -> if (q == "old") gate.await(); ok(q, listOf(movie("1", q))) }
        val store = store()
        store.setQuery("old")
        advanceTimeBy(501)
        store.setQuery("new")
        gate.complete(Unit)
        advanceTimeBy(501)
        runCurrent()
        assertEquals(listOf("new"), store.state.value.results.map { (it as SearchResultUi.Media).card.title })
    }

    @Test
    fun `selection only changes and reverting to the last query do not search again`() = runTest {
        answer = { ok(it, listOf(movie("1", "Matrix"))) }
        val store = store()
        store.setQuery("matrix")
        advanceTimeBy(501)
        runCurrent()
        store.setQuery("matri")
        store.setQuery("matrix")
        advanceTimeBy(1000)
        runCurrent()
        assertEquals(listOf("matrix"), queries)
        assertTrue(!store.state.value.searching)
    }

    @Test
    fun `clearing resets to the prompt`() = runTest {
        answer = { ok(it, listOf(movie("1", "Matrix"))) }
        val store = store()
        store.setQuery("matrix")
        advanceTimeBy(501)
        runCurrent()
        store.setQuery("  ")
        assertEquals(SearchPhase.IDLE, store.state.value.phase)
        assertTrue(store.state.value.results.isEmpty())
    }

    @Test
    fun `refreshing runs the query on screen again keeping its results and an empty field does nothing`() = runTest {
        answer = { ok(it, listOf(movie("1", "Matrix"))) }
        val store = store()
        store.refresh()
        runCurrent()
        assertTrue(queries.isEmpty())

        store.setQuery(" matrix ")
        advanceTimeBy(501)
        runCurrent()
        store.refresh()
        runCurrent()
        assertEquals(listOf("matrix", "matrix"), queries)
        assertEquals(listOf("Matrix"), store.state.value.results.map { (it as SearchResultUi.Media).card.title })
    }

    @Test
    fun `all server failures render the failed state`() = runTest {
        answer = { SearchAggregationResult(emptyList(), emptyList(), emptyList(), emptySet(), emptySet(), setOf(server)) }
        val store = store()
        store.setQuery("x")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(SearchPhase.FAILED, store.state.value.phase)
    }

    /** The failure names the server whose sign-in expired, or lists several, instead of a snackbar. */
    @Test
    fun `a search failing on an expired session names the server instead of a snackbar`() = runTest {
        answer = { SearchAggregationResult(emptyList(), emptyList(), emptyList(), emptySet(), emptySet(), setOf(server)) }
        val store = store()
        val messages = mutableListOf<String>()
        backgroundScope.launch { store.messages.collect { messages += it } }
        store.setQuery("x")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(SearchPhase.FAILED, store.state.value.phase)
        assertNull(store.state.value.sessionExpired)
        assertEquals(1, messages.size)

        // The session expires while the failure shows: the screen switches to say so.
        expired.value = listOf("Living Room")
        runCurrent()
        assertEquals(T.search.sessionExpiredMessageOne("Living Room"), store.state.value.sessionExpired)

        expired.value = listOf("Living Room", "Cabin")
        store.submit()
        runCurrent()
        assertEquals(T.search.sessionExpiredMessageMany("Living Room, Cabin"), store.state.value.sessionExpired)
        assertEquals(1, messages.size)

        // Signed in again, a failure is an ordinary one.
        expired.value = emptyList()
        runCurrent()
        assertNull(store.state.value.sessionExpired)
    }

    @Test
    fun `all server cancellation keeps prior results without an error`() = runTest {
        answer = { ok(it, listOf(movie("1", "Matrix"))) }
        val store = store()
        store.setQuery("matrix")
        advanceTimeBy(501)
        runCurrent()
        answer = { SearchAggregationResult(emptyList(), emptyList(), emptyList(), emptySet(), setOf(server), emptySet()) }
        store.setQuery("matrix 2")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(1, store.state.value.results.size)
        assertTrue(!store.state.value.searching)
    }

    @Test
    fun `kind chips appear only when results span several kinds and filter the list`() = runTest {
        answer = { ok(it, listOf(movie("1", "Dune"))) }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        assertTrue(store.state.value.filters.isEmpty())

        answer = {
            ok(it, listOf(movie("1", "Dune"), movie("2", "Dune", MediaKind.SHOW)), listOf(MediaPerson("p", "Dune Person", BackendKind.JELLYFIN, server, credit = PersonCredit.ACTOR)))
        }
        store.setQuery("dune ")
        store.refresh()
        runCurrent()
        val filters = store.state.value.filters
        assertEquals(listOf(SearchFilter.All, SearchFilter.Kind(MediaKind.MOVIE), SearchFilter.Kind(MediaKind.SHOW), SearchFilter.People), filters)
        store.selectFilter(SearchFilter.People)
        assertTrue(store.state.value.results.single() is SearchResultUi.Person)
        store.selectFilter(SearchFilter.All)
        assertEquals(3, store.state.value.results.size)
    }

    @Test
    fun `under All results of several kinds show in kind groups in their chips order`() = runTest {
        answer = {
            ok(
                it,
                listOf(movie("1", "Keanu", MediaKind.SHOW), movie("2", "The Keanu Story"), movie("3", "Keanu Chronicles")),
                listOf(MediaPerson("p", "Keanu Reeves", BackendKind.JELLYFIN, server)),
            )
        }
        val store = store()
        store.setQuery("keanu")
        advanceTimeBy(501)
        runCurrent()
        val titles = { group: SearchResultGroup ->
            group.results.map { (it as? SearchResultUi.Media)?.card?.title ?: (it as SearchResultUi.Person).name }
        }
        val groups = store.state.value.groups
        assertEquals(store.state.value.filters.drop(1).map { it.label }, groups.map { it.title }, "the groups in the chips' order, though the show ranks best")
        assertEquals(listOf(SearchFilter.Kind(MediaKind.MOVIE).label, SearchFilter.Kind(MediaKind.SHOW).label, SearchFilter.People.label), groups.map { it.title })
        assertEquals(listOf(listOf("Keanu Chronicles", "The Keanu Story"), listOf("Keanu"), listOf("Keanu Reeves")), groups.map(titles))
        assertEquals(groups.flatMap { it.results }, store.state.value.results)

        store.selectFilter(SearchFilter.Kind(MediaKind.MOVIE))
        assertEquals(listOf(null), store.state.value.groups.map { it.title })
        assertEquals(listOf("Keanu Chronicles", "The Keanu Story"), titles(store.state.value.groups.single()))
    }

    @Test
    fun `results of a single kind show without a heading`() = runTest {
        answer = { ok(it, listOf(movie("1", "Dune"), movie("2", "Dune Part Two"))) }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(listOf(null), store.state.value.groups.map { it.title })
        assertEquals(2, store.state.value.results.size)
    }

    @Test
    fun `a query that matches only a person shows the person`() = runTest {
        answer = { ok(it, emptyList(), listOf(MediaPerson("p", "Keanu Reeves", BackendKind.JELLYFIN, server))) }
        val store = store()
        store.setQuery("keanu")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(SearchPhase.RESULTS, store.state.value.phase)
        assertEquals("p", (store.state.value.results.single() as SearchResultUi.Person).route.personId)
    }

    @Test
    fun `hiding a library while results are shown reruns the query`() = runTest {
        answer = { ok(it, listOf(movie("1", "Dune", library = "1"), movie("2", "Dune", library = "2"))) }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(2, store.state.value.results.size)
        hidden.value = setOf("a:2")
        runCurrent()
        assertEquals(1, store.state.value.results.size)
    }

    @Test
    fun `a library hidden while the first search runs stays out of its results`() = runTest {
        val gate = CompletableDeferred<Unit>()
        answer = { gate.await(); ok(it, listOf(movie("1", "Dune", library = "1"), movie("2", "Dune", library = "2"))) }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        hidden.value = setOf("a:2")
        runCurrent()
        gate.complete(Unit)
        runCurrent()
        assertEquals(1, store.state.value.results.size)
    }

    @Test
    fun `submit before the debounce searches now and focuses the first result`() = runTest {
        answer = { ok(it, listOf(movie("1", "Dune"))) }
        val store = store()
        var focused = 0
        backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { store.focusFirstResult.collect { focused++ } }
        store.setQuery("dune")
        store.submit()
        runCurrent()
        assertEquals(listOf("dune"), queries)
        assertEquals(1, focused)
    }

    @Test
    fun `submitting the query of a failed search searches again and focuses its results`() = runTest {
        var fail = true
        answer = { q ->
            if (fail) SearchAggregationResult(emptyList(), emptyList(), emptyList(), emptySet(), emptySet(), setOf(server)) else ok(q, listOf(movie("1", "Dune")))
        }
        val store = store()
        var focused = 0
        backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { store.focusFirstResult.collect { focused++ } }
        store.setQuery("dune")
        store.submit()
        runCurrent()
        assertEquals(SearchPhase.FAILED, store.state.value.phase)
        fail = false
        store.submit()
        runCurrent()
        assertEquals(listOf("dune", "dune"), queries)
        assertEquals(SearchPhase.RESULTS, store.state.value.phase)
        assertEquals(1, focused)
    }

    @Test
    fun `submitting the query of a search that threw searches again`() = runTest {
        var fail = true
        answer = { q -> if (fail) error("offline") else ok(q, listOf(movie("1", "Dune"))) }
        val store = store()
        store.setQuery("dune")
        store.submit()
        runCurrent()
        assertEquals(SearchPhase.FAILED, store.state.value.phase)
        fail = false
        store.submit()
        runCurrent()
        assertEquals(SearchPhase.RESULTS, store.state.value.phase)
    }

    @Test
    fun `submitting a query with no results searches it again`() = runTest {
        answer = { ok(it, emptyList()) }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(SearchPhase.EMPTY, store.state.value.phase)
        answer = { ok(it, listOf(movie("1", "Dune"))) }
        store.submit()
        runCurrent()
        assertEquals(SearchPhase.RESULTS, store.state.value.phase)
    }

    @Test
    fun `a submit cleared before it landed does not focus a later typed query`() = runTest {
        val gate = CompletableDeferred<Unit>()
        answer = { q -> if (q == "old") gate.await(); ok(q, listOf(movie("1", q))) }
        val store = store()
        var focused = 0
        backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { store.focusFirstResult.collect { focused++ } }
        store.setQuery("old")
        store.submit()
        runCurrent()
        store.setQuery("")
        store.setQuery("new")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(listOf("new"), store.state.value.results.map { (it as SearchResultUi.Media).card.title })
        assertEquals(0, focused)
    }

    @Test
    fun `a submit edited away before it landed does not focus the edited query`() = runTest {
        val gate = CompletableDeferred<Unit>()
        answer = { q -> if (q == "old") gate.await(); ok(q, listOf(movie("1", q))) }
        val store = store()
        var focused = 0
        backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { store.focusFirstResult.collect { focused++ } }
        store.setQuery("old")
        store.submit()
        runCurrent()
        store.setQuery("new")
        advanceTimeBy(501)
        runCurrent()
        assertEquals(1, store.state.value.results.size)
        assertEquals(0, focused)
    }

    @Test
    fun `selecting a title hands it to the activation every screen uses and its menu`() = runTest {
        val episode = movie("1", "Dune", MediaKind.EPISODE)
        answer = { ok(it, listOf(episode)) }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        val key = store.state.value.results.single().key
        store.open(key)
        store.menu(key)
        assertEquals(listOf(episode), opened)
        assertEquals(listOf(episode), menus)
    }

    @Test
    fun aRowNamesItsServerWithItsLibraryOrWhenTheProfileHasSeveralServers() = runTest {
        answer = { ok(it, listOf(movie("1", "Dune").copy(serverName = "Home", backend = BackendKind.EMBY), movie("2", "Dune", MediaKind.SHOW, library = "2").copy(serverName = "Home"))) }
        libraryLabel = { if (it.libraryId == "1") "Anime" else null }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        val sources = { store.state.value.results.associate { (it as SearchResultUi.Media).card.id to it.source } }
        val first = store.state.value.results.first { (it as SearchResultUi.Media).backend == BackendKind.EMBY } as SearchResultUi.Media
        assertEquals("Home • Anime", first.source)
        assertEquals(setOf("Home • Anime", null), sources().values.toSet())

        serverCount = 2
        store.refresh()
        runCurrent()
        assertEquals(setOf("Home • Anime", "Home"), sources().values.toSet())
    }

    @Test
    fun `a watched title is fetched again on its server and keeps its library without searching again`() = runTest {
        answer = { ok(it, listOf(movie("1", "Dune").copy(libraryTitle = "Anime"), movie("2", "Dune", MediaKind.SHOW))) }
        libraryLabel = { it.libraryTitle }
        fetched = { id -> MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = "Dune Watched", serverId = "a") }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        store.selectFilter(SearchFilter.Kind(MediaKind.MOVIE))
        watchStates.emit(WatchStateEvent("1", server, WatchStateChangeType.WATCHED, emptyList()))
        runCurrent()
        val row = store.state.value.results.single() as SearchResultUi.Media
        assertEquals("Dune Watched", row.card.title)
        assertEquals("Anime", row.source)
        store.selectFilter(SearchFilter.All)
        assertTrue(store.state.value.results.any { (it as SearchResultUi.Media).card.title == "Dune Watched" })
        assertEquals(listOf("dune"), queries)
    }

    @Test
    fun anEditedOrRemovedFromContinueWatchingTitleIsFetchedAgainButProgressIsNot() = runTest {
        answer = { ok(it, listOf(movie("1", "Dune"))) }
        var version = 0
        fetched = { id -> version++; movie(id, "Dune $version") }
        val store = store()
        store.setQuery("dune")
        advanceTimeBy(501)
        runCurrent()
        watchStates.emit(WatchStateEvent("1", server, WatchStateChangeType.PROGRESS_UPDATE, emptyList()))
        runCurrent()
        assertEquals("Dune", (store.state.value.results.single() as SearchResultUi.Media).card.title)
        edits.emit(EditedItem(server, "1"))
        runCurrent()
        assertEquals("Dune 1", (store.state.value.results.single() as SearchResultUi.Media).card.title)
        watchStates.emit(WatchStateEvent("1", server, WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING, emptyList()))
        runCurrent()
        assertEquals("Dune 2", (store.state.value.results.single() as SearchResultUi.Media).card.title)
        assertEquals(listOf("dune"), queries)
    }
}
