@file:OptIn(ExperimentalCoroutinesApi::class)

package com.edde746.plezy.presentation.ratings

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.ResolvedIds
import com.edde746.plezy.trackers.TrackerFixture
import com.edde746.plezy.trackers.TrackerIdResolver
import com.edde746.plezy.trackers.TrackerService
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

/** Names every item as [target] says (`null`: no tracker can), counting the asks. */
private class SheetResolver(var target: suspend (MediaItem) -> RatingTarget?) : TrackerIdResolver {
    var asks = 0
    var cleared = 0

    override suspend fun resolveForRating(item: MediaItem): RatingTarget? {
        asks++
        return target(item)
    }

    override suspend fun resolveForMovie(movie: MediaItem): ResolvedIds? = error("not a rating")

    override suspend fun resolveForEpisode(episode: MediaItem, includeCurrentEpisode: Boolean): ResolvedIds? = error("not a rating")

    override fun clearCache() {
        cleared++
    }
}

/** A media server that takes ratings and favorites, recording them. */
private class RatingServer(capabilities: ServerCapabilities) :
    MediaBackend by FakeMediaBackend("s1", serverName = "Living Room", capabilities = capabilities) {
    val writes = mutableListOf<String>()
    var failure: Exception? = null

    override suspend fun rate(item: MediaItem, rating: Double) {
        failure?.let { throw it }
        writes += "rate $rating"
    }

    override suspend fun setFavorite(item: MediaItem, isFavorite: Boolean) {
        writes += "favorite $isFavorite"
    }
}

/** The rating sheet: its rows, the trackers' scores loading into them, and how changes save. */
class RatingSheetStoreTest {
    private val movie = MediaItem(id = "movie-1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, userRating = 6.0)
    private val target = RatingTarget(RatingKind.MOVIE, ExternalIds(imdb = "tt1"), AnimeIds(mal = 5, anilist = 5))
    private val resolver = SheetResolver { target }
    private val server = RatingServer(ServerCapabilities.PLEX)
    private val serverChanges = mutableListOf<Double>()
    private val favoriteChanges = mutableListOf<Boolean>()

    private suspend fun TestScope.sheet(
        services: List<TrackerService> = TrackerService.entries,
        item: MediaItem = movie,
        backend: MediaBackend? = server,
        seed: TrackerFixture.() -> Unit = {},
    ): Pair<TrackerFixture, RatingSheetStore> {
        val fixture = TrackerFixture(this, idResolver = resolver)
        for (service in services) fixture.connect(service)
        fixture.seed()
        val store = RatingSheetStore.open(
            fixture.hub.userRatings,
            fixture.profileId,
            item,
            backend,
            backgroundScope,
            onServerRatingChanged = { serverChanges += it },
            onServerFavoriteChanged = { favoriteChanges += it },
        )
        return fixture to store
    }

    private fun RatingSheetStore.tracker(service: TrackerService) = state.value.trackers.single { it.service == service }

    private val notAvailable = RatingRowStatus(T.rateSheet.notAvailable, isError = true)
    private val failed = RatingRowStatus(T.errors.failedToRate, isError = true)
    private val saved = RatingRowStatus(T.rateSheet.saved, isError = false)

    @Test
    fun theRowsAreTheServerThenEveryConnectedTrackerInTheSheetsOrder() = runTest {
        val (fixture, store) = sheet()

        val state = store.state.value
        assertEquals(T.rateSheet.server, state.server?.title)
        assertEquals("Plex - Living Room", state.server?.subtitle)
        assertEquals(6, state.server?.value, "the server's 0–10 rating as half stars")
        assertEquals(
            listOf(TrackerService.TRAKT, TrackerService.MYANIMELIST, TrackerService.ANILIST, TrackerService.SIMKL, TrackerService.MDBLIST),
            state.trackers.map { it.service },
        )
        assertEquals(T.services.connectedAs("alex"), state.trackers.first().subtitle)
        assertTrue(state.trackers.all { it.loading }, "the scores load at once")
        assertNull(state.noConnectedServices)
        fixture.close()
    }

    @Test
    fun anUnratableItemKeepsEveryTrackerRowSoTheSheetCannotResizeUnderTheUser() = runTest {
        resolver.target = { null }
        val (fixture, store) = sheet()
        runCurrent()

        assertEquals(5, store.state.value.trackers.size, "no row may be dropped")
        assertTrue(store.state.value.trackers.all { it.status == notAvailable && !it.loading })
        fixture.close()
    }

    @Test
    fun trackerRowsSettleWithAnErrorWhenTheItemsIdsCannotBeResolved() = runTest {
        resolver.target = { throw IllegalStateException("server unreachable") }
        val (fixture, store) = sheet()
        runCurrent()

        assertTrue(store.state.value.trackers.all { it.status == failed && !it.loading }, "no row may keep loading")
        fixture.close()
    }

    @Test
    fun eachTrackersScoreLoadsIntoItsRowOrSaysWhyNot() = runTest {
        resolver.target = { target.copy(anime = AnimeIds(anilist = 5)) }
        val (fixture, store) = sheet(
            seed = {
                tracker(TrackerService.TRAKT).scores["movie imdb=tt1"] = 8
                tracker(TrackerService.SIMKL).failNext("rating", IllegalStateException("down"))
            },
        )
        runCurrent()

        assertEquals(8, store.tracker(TrackerService.TRAKT).value)
        assertNull(store.tracker(TrackerService.TRAKT).status)
        assertEquals(notAvailable, store.tracker(TrackerService.MYANIMELIST).status, "no MyAnimeList id")
        assertEquals(0, store.tracker(TrackerService.ANILIST).value, "not rated")
        assertEquals(failed, store.tracker(TrackerService.SIMKL).status)
        assertTrue(store.state.value.trackers.none { it.loading })
        assertEquals(1, resolver.asks, "the ids resolve once for every tracker")
        fixture.close()
    }

    @Test
    fun aStepSavesAfterTheDebounceAndOnlyTheLastValue() = runTest {
        val (fixture, store) = sheet(services = listOf(TrackerService.TRAKT))
        runCurrent()

        store.step(RatingRowKey.Tracker(TrackerService.TRAKT), +1)
        advanceTimeBy(300.milliseconds)
        store.step(RatingRowKey.Tracker(TrackerService.TRAKT), +1)
        advanceTimeBy(599.milliseconds)
        runCurrent()
        assertEquals(listOf("rating movie imdb=tt1"), fixture.calls(TrackerService.TRAKT))

        advanceTimeBy(2.milliseconds)
        runCurrent()
        assertEquals(listOf("rating movie imdb=tt1", "rate movie imdb=tt1 2"), fixture.calls(TrackerService.TRAKT))
        assertEquals(saved, store.tracker(TrackerService.TRAKT).status)
        fixture.close()
    }

    @Test
    fun selectSavesNowAndZeroRemovesTheRating() = runTest {
        val (fixture, store) = sheet(services = listOf(TrackerService.TRAKT), seed = { tracker(TrackerService.TRAKT).scores["movie imdb=tt1"] = 8 })
        runCurrent()

        store.submit(RatingRowKey.Tracker(TrackerService.TRAKT), 7)
        runCurrent()
        store.submit(RatingRowKey.Tracker(TrackerService.TRAKT), 0)
        runCurrent()

        assertEquals(listOf("rating movie imdb=tt1", "rate movie imdb=tt1 7", "unrate movie imdb=tt1"), fixture.calls(TrackerService.TRAKT))
        assertEquals(0, store.tracker(TrackerService.TRAKT).value)
        assertEquals(saved, store.tracker(TrackerService.TRAKT).status)
        fixture.close()
    }

    @Test
    fun aFailedSaveSaysSoInTheRowAndAsASnackbar() = runTest {
        val (fixture, store) = sheet(services = listOf(TrackerService.TRAKT, TrackerService.MYANIMELIST))
        runCurrent()
        fixture.tracker(TrackerService.TRAKT).failNext("rate", IllegalStateException("down"))
        resolver.target = { target.copy(anime = null) }

        store.submit(RatingRowKey.Tracker(TrackerService.TRAKT), 9)
        store.submit(RatingRowKey.Tracker(TrackerService.MYANIMELIST), 9)
        runCurrent()

        assertEquals(failed, store.tracker(TrackerService.TRAKT).status)
        assertEquals(notAvailable, store.tracker(TrackerService.MYANIMELIST).status, "not available is no snackbar")
        assertEquals(T.errors.failedToRate, store.state.value.message)
        store.messageShown()
        assertNull(store.state.value.message)
        fixture.close()
    }

    @Test
    fun theServerRowRatesInHalfStarsAndClearsAtZero() = runTest {
        val (fixture, store) = sheet(services = emptyList())

        store.submit(RatingRowKey.Server, 7)
        runCurrent()
        store.step(RatingRowKey.Server, -7)
        advanceTimeBy(RatingSheetStore.AUTO_SAVE_DELAY)
        runCurrent()

        assertEquals(listOf("rate 7.0", "rate -1.0"), server.writes)
        assertEquals(listOf(7.0, 0.0), serverChanges)
        assertEquals(saved, store.state.value.server?.status)
        assertEquals(T.rateSheet.noConnectedServices, store.state.value.noConnectedServices)
        fixture.close()
    }

    @Test
    fun aServerThatRefusesTheRatingSaysSoInTheRowAndAsASnackbar() = runTest {
        val (fixture, store) = sheet(services = emptyList())
        server.failure = IllegalStateException("500")

        store.submit(RatingRowKey.Server, 8)
        runCurrent()

        assertEquals(failed, store.state.value.server?.status)
        assertEquals(T.errors.failedToRate, store.state.value.message)
        assertEquals(emptyList(), serverChanges)
        fixture.close()
    }

    @Test
    fun aServerWithoutNumericRatingsGetsAFavoriteToggle() = runTest {
        val favorites = RatingServer(ServerCapabilities(userFavorites = true))
        val (fixture, store) = sheet(services = emptyList(), backend = favorites)

        assertEquals(true, store.state.value.server?.favoriteOnly)
        store.submit(RatingRowKey.Server)
        runCurrent()
        store.step(RatingRowKey.Server, -1)
        advanceTimeBy(RatingSheetStore.AUTO_SAVE_DELAY)
        runCurrent()

        assertEquals(listOf("favorite true", "favorite false"), favorites.writes)
        assertEquals(listOf(true, false), favoriteChanges)
        fixture.close()
    }

    @Test
    fun aServerThatNeitherRatesNorKeepsFavoritesHasNoRowAndNorDoesAnOfflineOne() = runTest {
        val (fixture, store) = sheet(services = emptyList(), backend = RatingServer(ServerCapabilities()))
        assertNull(store.state.value.server)
        val (offlineFixture, offline) = sheet(services = listOf(TrackerService.TRAKT), backend = null)
        runCurrent()
        assertNull(offline.state.value.server)
        assertEquals(notAvailable, offline.tracker(TrackerService.TRAKT).status, "no server, no ids")
        fixture.close()
        offlineFixture.close()
    }

    @Test
    fun changesStillWaitingWhenTheSheetClosesAreSavedAnyway() = runTest {
        val (fixture, store) = sheet(services = listOf(TrackerService.TRAKT))
        runCurrent()

        store.change(RatingRowKey.Tracker(TrackerService.TRAKT), 6)
        store.change(RatingRowKey.Server, 4)
        store.release()
        runCurrent()

        assertEquals(listOf("rating movie imdb=tt1", "rate movie imdb=tt1 6"), fixture.calls(TrackerService.TRAKT))
        assertEquals(listOf("rate 4.0"), server.writes)
        assertEquals(1, resolver.cleared)
        fixture.close()
    }
}
