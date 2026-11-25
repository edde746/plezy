package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.seerr.SeerrCatalogPerson
import com.edde746.plezy.catalog.seerr.SeerrCatalogSource
import com.edde746.plezy.format.DateLength
import com.edde746.plezy.format.formatDate
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.presentation.detail.InfoRowUi
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.seerr.json
import com.edde746.plezy.seerr.path
import com.edde746.plezy.seerr.seerrClient
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.test.fail
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class SeerrPersonStoreTest {
    private val route = Route.SeerrPerson(31, "Tom Hanks", "https://image.tmdb.org/t/p/w300/cast.jpg")
    private val today = CalendarDate(2026, 11, 14)

    /** A store loading from a Seerr whose person routes answer [person] and [credits]; artwork stays on TMDB's CDN. */
    private fun TestScope.seerrStore(person: String, credits: String): SeerrPersonStore {
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json("""{"message":"Not Found"}""", 404)
                "/api/v1/person/31" -> json(person)
                "/api/v1/person/31/combined_credits" -> json(credits)
                else -> fail("unexpected request ${request.url}")
            }
        }
        return SeerrPersonStore(route, SeerrCatalogSource(seerrClient(server))::fetchPerson, { today }, backgroundScope)
    }

    private suspend fun SeerrPersonStore.settled() = state.first { it.settled }

    @Test
    fun `the page shows the person as Seerr gives them and their titles as catalog cards`() = runTest {
        val store = seerrStore(
            person = """{"id":31,"name":"Thomas Hanks","biography":"An actor and filmmaker.","birthday":"1956-07-09",
                "deathday":null,"placeOfBirth":"Concord, California, USA","knownForDepartment":"Acting","profilePath":"/hanks.jpg"}""",
            credits = """{"id":31,"cast":[{"id":13,"mediaType":"movie","title":"Forrest Gump","releaseDate":"1994-07-06",
                "posterPath":"/fg.jpg","voteAverage":8.5,"character":"Forrest Gump","mediaInfo":{"status":5}}],"crew":[]}""",
        )
        val state = store.settled()

        assertEquals("Thomas Hanks", state.name)
        assertEquals("https://image.tmdb.org/t/p/w300/hanks.jpg", state.image?.path)
        assertEquals("Acting", state.department)
        assertEquals(
            listOf(
                InfoRowUi(T.discover.person.born, T.discover.person.dateWithAge(formatDate("1956-07-09", DateLength.LONG), "70")),
                InfoRowUi(T.discover.person.birthplace, "Concord, California, USA"),
            ),
            state.facts,
        )
        assertEquals("An actor and filmmaker.", state.biography)
        assertEquals(T.discover.titleCount(1), state.titleCount)
        assertEquals(SectionLoad.CONTENT, state.load)
        val card = state.grid(posterPx = 300).items.single()
        assertEquals("Forrest Gump", card.title)
        assertTrue(T.explore.badge.available in card.qualityLabels, "the card carries Seerr's availability: ${card.qualityLabels}")
    }

    @Test
    fun `their titles show once each newest first with undated titles last`() = runTest {
        val store = seerrStore(
            person = """{"id":31,"name":"Tom Hanks"}""",
            credits = """{"id":31,"cast":[
                {"id":13,"mediaType":"movie","title":"Forrest Gump","releaseDate":"1994-07-06","character":"Forrest"},
                {"id":900,"mediaType":"movie","title":"Untitled Project","releaseDate":""},
                {"id":4613,"mediaType":"tv","name":"Band of Brothers","firstAirDate":"2001-09-09","character":"Narrator"},
                {"id":862,"mediaType":"movie","title":"Toy Story","releaseDate":"1995-11-22","character":"Woody"}],
                "crew":[
                {"id":4613,"mediaType":"tv","name":"Band of Brothers","firstAirDate":"2001-09-09","job":"Executive Producer"},
                {"id":4613,"mediaType":"movie","title":"Same Number Movie","releaseDate":"2010-01-01","job":"Producer"}]}""",
        )
        val state = store.settled()

        assertEquals(
            listOf("Same Number Movie", "Band of Brothers", "Toy Story", "Forrest Gump", "Untitled Project"),
            state.grid(posterPx = 300).items.map { it.title },
        )
        assertEquals(T.discover.titleCount(5), state.titleCount)
    }

    @Test
    fun `a card opens the title in the Seerr catalog detail`() = runTest {
        val store = seerrStore(
            person = """{"id":31,"name":"Tom Hanks"}""",
            credits = """{"id":31,"cast":[{"id":4613,"mediaType":"tv","name":"Band of Brothers","firstAirDate":"2001-09-09"},
                {"id":13,"mediaType":"movie","title":"Forrest Gump","releaseDate":"1994-07-06"}],"crew":[]}""",
        )
        val cards = store.settled().grid(posterPx = 300).items

        val route = store.routeFor(cards.last().id) as Route.CatalogDetail
        assertEquals(CatalogSourceId.SEERR, route.item.source)
        assertEquals(MediaKind.MOVIE, route.item.kind)
        assertEquals(13, route.item.ids.tmdb)
        assertEquals("Forrest Gump", route.item.title)
        assertNull(store.routeFor("catalog:seerr:unknown"))
    }

    @Test
    fun `a failed load shows the cast entry with Retry and a retry loads the page`() = runTest {
        var attempts = 0
        val store = SeerrPersonStore(
            route,
            { personId ->
                assertEquals(31, personId)
                if (++attempts == 1) error("Seerr is down")
                SeerrCatalogPerson("Tom Hanks", null, "Acting", MediaPersonDetails.EMPTY, emptyList())
            },
            { today },
            backgroundScope,
        )
        assertEquals(SectionLoad.LOADING, store.state.value.load)
        runCurrent()

        val failed = store.state.value
        assertTrue(failed.settled)
        assertEquals(SectionLoad.ERROR, failed.load)
        assertEquals(T.errors.unableToLoad(isolate("Tom Hanks")), failed.error)
        assertEquals("Tom Hanks", failed.name)
        assertEquals(route.imageUrl, failed.image?.path)
        assertNull(failed.titleCount)

        store.retry()
        assertEquals(SectionLoad.LOADING, store.state.value.load)
        runCurrent()
        assertEquals(2, attempts)
        assertEquals(SectionLoad.EMPTY, store.state.value.load)
        assertNull(store.state.value.error)
        assertEquals("Acting", store.state.value.department)
    }
}
