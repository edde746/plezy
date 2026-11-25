package com.edde746.plezy.presentation.explore

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.tracker.TrackerAccount
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.tv.PlexDiscoverSession
import com.edde746.plezy.seerr.SeerrClient
import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.trackers.FakeProvider
import com.edde746.plezy.trackers.TrackerBinding
import com.edde746.plezy.trackers.TrackerFixture
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.FakeCredentials
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class CatalogSourcesTest {
    private class Harness(
        private val scope: TestScope,
        val data: LocalData = scope.testData(),
        isTv: Boolean = false,
        val trackers: MutableStateFlow<List<TrackerBinding>> = MutableStateFlow(emptyList()),
    ) {
        val seerr = MutableStateFlow<SeerrClient?>(null)
        var session: suspend () -> PlexDiscoverSession? = { null }
        var sessionReads = 0
        val built = mutableListOf<FakeCatalogSource>()
        val plexBuilds = mutableListOf<Pair<PlexDiscoverSession, Boolean>>()

        val sources = CatalogSources(
            trackerBindings = trackers,
            seerrClient = seerr,
            plexSession = {
                sessionReads++
                session()
            },
            settings = data.profileSettings,
            isTv = isTv,
            trackerSource = { binding -> FakeCatalogSource(binding.service.catalogSourceId).also(built::add) },
            plexSource = { plexSession, imageVariants ->
                plexBuilds += plexSession to imageVariants
                FakeHubSource().also(built::add)
            },
            seerrSource = { FakeCatalogSource(CatalogSourceId.SEERR, supportsWatchlist = false).also(built::add) },
            parentScope = scope.backgroundScope,
        )

        val state get() = sources.state.value
        val ids get() = state.connected.map { it.id }

        /** A fresh sign-in of [service]: a new binding instance. */
        fun binding(service: TrackerService) =
            TrackerBinding(TrackerAccount(service, "alex", 1), FakeProvider(service, scope, mutableListOf()), FakeCredentials(service))
    }

    private fun TestScope.harness(isTv: Boolean = false) = Harness(this, isTv = isTv)

    private val sessionA = PlexDiscoverSession("profile-token", "client-id")

    @Test
    fun profileHydrationExposesPlexWhenDiscoverCredentialsAreAvailable() = runTest {
        val h = harness()
        h.session = { sessionA }

        h.sources.onActiveProfileChanged("profile-1")

        assertEquals(1, h.sessionReads)
        assertEquals(listOf(CatalogSourceId.PLEX), h.ids)
        assertEquals("Plex", h.state.active?.displayName)
        assertEquals(CatalogSourceId.PLEX, h.state.watchlistCapableSource?.id)
        assertEquals(listOf(sessionA to false), h.plexBuilds)
    }

    @Test
    fun aTvBuildsPlexSourceAsksForHubArtworkVariants() = runTest {
        val h = harness(isTv = true)
        h.session = { sessionA }

        h.sources.onActiveProfileChanged("profile-1")

        assertEquals(listOf(sessionA to true), h.plexBuilds)
    }

    @Test
    fun profileHydrationOmitsPlexWithoutAUsablePlexIdentity() = runTest {
        val h = harness()
        h.sources.onActiveProfileChanged("profile-1")
        assertEquals(emptyList(), h.ids)
        assertFalse(h.state.hasAnySource)

        h.session = { PlexDiscoverSession("", "client-id") }
        h.sources.onActiveProfileChanged("profile-2")
        assertEquals(emptyList(), h.ids)
    }

    @Test
    fun aPlexSessionReadFailureDoesNotAbortProfileHydration() = runTest {
        val h = harness()
        h.data.profileSettings.set("profile-1", ProfileSettings.catalogActiveSource, "trakt")
        h.session = { throw IllegalStateException("vault unavailable") }

        h.sources.onActiveProfileChanged("profile-1")

        assertEquals(emptyList(), h.ids)
        assertEquals(CatalogSourceId.TRAKT, h.state.preferred)
    }

    @Test
    fun aSameProfileBindingCompletionReadsThePlexSessionAgain() = runTest {
        val h = harness()
        var session: PlexDiscoverSession? = null
        h.session = { session }

        h.sources.onActiveProfileChanged("profile-1")
        h.sources.onProfileBindingStateChanged(false)
        assertEquals(1, h.sessionReads)
        assertEquals(emptyList(), h.ids)

        h.sources.onProfileBindingStateChanged(true)
        session = PlexDiscoverSession("connected", "client-id")
        h.sources.onProfileBindingStateChanged(false)
        assertEquals(2, h.sessionReads)
        assertEquals(listOf(CatalogSourceId.PLEX), h.ids)

        h.sources.onProfileBindingStateChanged(true)
        session = null
        h.sources.onProfileBindingStateChanged(false)
        assertEquals(3, h.sessionReads)
        assertEquals(emptyList(), h.ids)
    }

    @Test
    fun aFailedReadKeepsPlexOnARefreshButDropsItOnAProfileChange() = runTest {
        val h = harness()
        h.session = { sessionA }
        h.sources.onActiveProfileChanged("profile-1")

        h.session = { throw IllegalStateException("offline") }
        h.sources.onProfileBindingStateChanged(true)
        h.sources.onProfileBindingStateChanged(false)
        assertEquals(listOf(CatalogSourceId.PLEX), h.ids)

        h.sources.onActiveProfileChanged("profile-2")
        assertEquals(emptyList(), h.ids)
        assertEquals(1, h.built.single().disposed)
    }

    @Test
    fun aSessionReadOvertakenByALaterProfileChangeIsDiscarded() = runTest {
        val h = harness()
        val slow = CompletableDeferred<PlexDiscoverSession?>()
        h.session = { slow.await() }
        val first = launch { h.sources.onActiveProfileChanged("profile-1") }
        runCurrent()

        val sessionB = PlexDiscoverSession("profile-2-token", "client-id")
        h.session = { sessionB }
        h.sources.onActiveProfileChanged("profile-2")
        slow.complete(sessionA)
        first.join()

        assertEquals(listOf(sessionB to false), h.plexBuilds)
    }

    @Test
    fun trackerSourcesAppearAndGoWithTheirAccountsInTheFixedListingOrder() = runTest {
        val h = harness()
        h.session = { sessionA }
        h.sources.onActiveProfileChanged("profile-1")

        h.trackers.value = listOf(h.binding(TrackerService.MDBLIST))
        runCurrent()
        assertEquals(listOf(CatalogSourceId.MDBLIST, CatalogSourceId.PLEX), h.ids)
        assertEquals("MDBList", h.state.active?.displayName)

        h.trackers.value = TrackerService.entries.map(h::binding)
        runCurrent()
        assertEquals(
            listOf(
                CatalogSourceId.TRAKT,
                CatalogSourceId.MAL,
                CatalogSourceId.ANILIST,
                CatalogSourceId.SIMKL,
                CatalogSourceId.MDBLIST,
                CatalogSourceId.PLEX,
            ),
            h.ids,
        )

        h.trackers.value = emptyList()
        runCurrent()
        assertEquals(listOf(CatalogSourceId.PLEX), h.ids)
    }

    @Test
    fun aTrackerConnectedToTheActiveProfileListsItsSource() = runTest {
        val f = TrackerFixture(this, services = listOf(TrackerService.TRAKT))
        try {
            val bindings = MutableStateFlow<List<TrackerBinding>>(emptyList())
            val h = Harness(this, trackers = bindings)
            backgroundScope.launch { f.hub.accounts.bindings(f.profileId).collect { bindings.value = it } }
            h.sources.onActiveProfileChanged(f.profileId)
            runCurrent()
            assertEquals(emptyList(), h.ids)

            f.connect(TrackerService.TRAKT)
            runCurrent()
            assertEquals(listOf(CatalogSourceId.TRAKT), h.ids)

            f.hub.accounts.disconnect(f.profileId, TrackerService.TRAKT)
            runCurrent()
            assertEquals(emptyList(), h.ids)
            assertEquals(1, h.built.single().disposed)
        } finally {
            f.close()
        }
    }

    @Test
    fun aSourceIsRebuiltOnlyWhenItsClientChanges() = runTest {
        val h = harness()
        val binding = h.binding(TrackerService.TRAKT)
        h.trackers.value = listOf(binding)
        runCurrent()
        val trakt = h.state.connected.single()

        // Another account connecting re-emits the same binding instance: Trakt's source stays.
        h.trackers.value = listOf(binding, h.binding(TrackerService.SIMKL))
        runCurrent()
        assertSame(trakt, h.state.connected.first())
        assertEquals(0, h.built.first().disposed)

        h.trackers.value = listOf(h.binding(TrackerService.TRAKT))
        runCurrent()
        assertEquals(1, h.built.first().disposed)
        assertEquals(listOf(CatalogSourceId.TRAKT), h.ids)

        // The same Plex session value on a refresh keeps its source.
        h.session = { sessionA }
        h.sources.onActiveProfileChanged("profile-1")
        h.session = { PlexDiscoverSession("profile-token", "client-id") }
        h.sources.onProfileBindingStateChanged(true)
        h.sources.onProfileBindingStateChanged(false)
        assertEquals(1, h.plexBuilds.size)
    }

    @Test
    fun theStoredPickIsActiveWhileConnectedElseTheFirstSource() = runTest {
        val h = harness()
        h.sources.onActiveProfileChanged("profile-1")
        h.trackers.value = listOf(h.binding(TrackerService.TRAKT), h.binding(TrackerService.MYANIMELIST))
        runCurrent()
        assertEquals(CatalogSourceId.TRAKT, h.state.active?.id)

        h.sources.setActiveSource(CatalogSourceId.MAL)
        assertEquals(CatalogSourceId.MAL, h.state.active?.id)
        assertEquals("mal", h.data.profileSettings.value("profile-1", ProfileSettings.catalogActiveSource))

        h.trackers.value = listOf(h.binding(TrackerService.TRAKT))
        runCurrent()
        assertEquals(CatalogSourceId.TRAKT, h.state.active?.id)
        assertEquals(CatalogSourceId.MAL, h.state.preferred)

        h.sources.setActiveSource(null)
        assertNull(h.state.preferred)
        assertNull(h.data.profileSettings.value("profile-1", ProfileSettings.catalogActiveSource))
    }

    @Test
    fun aPlexHomeProfilesPickIsStoredUnderItsHomeUser() = runTest {
        val h = harness()
        h.sources.onActiveProfileChanged("plex-home-conn-1-0123456789abcdef")
        h.sources.setActiveSource(CatalogSourceId.ANILIST)

        assertEquals("anilist", h.data.profileSettings.value("0123456789abcdef", ProfileSettings.catalogActiveSource))
    }

    @Test
    fun aPickWrittenWhileTheProfileChangesIsNotApplied() = runTest {
        val h = harness()
        h.data.profileSettings.set("profile-2", ProfileSettings.catalogActiveSource, "anilist")
        h.sources.onActiveProfileChanged("profile-1")

        launch(start = CoroutineStart.UNDISPATCHED) { h.sources.setActiveSource(CatalogSourceId.MAL) }
        launch(start = CoroutineStart.UNDISPATCHED) { h.sources.onActiveProfileChanged("profile-2") }
        runCurrent()

        assertEquals(CatalogSourceId.ANILIST, h.state.preferred)
    }

    @Test
    fun aSourceRebindForgetsTheWatchlistCandidates() = runTest {
        val h = harness()
        h.session = { sessionA }
        h.sources.onActiveProfileChanged("profile-1")
        val server = FakeMediaBackend("server-1").apply { externalIds = { ExternalIds(imdb = "tt1") } }
        h.sources.watchlistCandidates.watchlistCandidatesFor(ServerId("server-1"), "movie-1", MediaKind.MOVIE, server)
        assertNotNull(h.sources.watchlistCandidates.cachedWatchlistCandidatesFor(ServerId("server-1"), "movie-1"))

        h.session = { PlexDiscoverSession("b", "client-id") }
        h.sources.onProfileBindingStateChanged(true)
        h.sources.onProfileBindingStateChanged(false)

        assertNull(h.sources.watchlistCandidates.cachedWatchlistCandidatesFor(ServerId("server-1"), "movie-1"))
    }

    @Test
    fun aCatalogItemsWatchlistIsItsOwnSourcesOnly() {
        val trakt = FakeCatalogSource(CatalogSourceId.TRAKT)
        val seerr = FakeCatalogSource(CatalogSourceId.SEERR, supportsWatchlist = false)
        val state = CatalogSourcesState(connected = listOf<CatalogSource>(trakt, seerr), seerr = seerr)
        fun item(source: CatalogSourceId) = CatalogItem(source, MediaKind.MOVIE, "Title", CatalogItemIds(tmdb = 1))

        assertSame(trakt, state.watchlistSourceFor(item(CatalogSourceId.TRAKT)))
        assertNull(state.watchlistSourceFor(item(CatalogSourceId.SEERR)))
        // Only an item whose source went away falls back to a connected watchlist.
        assertSame(trakt, state.watchlistSourceFor(item(CatalogSourceId.MAL)))
    }
}
