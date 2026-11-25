package com.edde746.plezy.presentation.catalog

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.catalog.CatalogAudience
import com.edde746.plezy.catalog.CatalogAudiencePeriod
import com.edde746.plezy.catalog.CatalogAvailability
import com.edde746.plezy.catalog.CatalogBroadcast
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogCredit
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogFormat
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogLink
import com.edde746.plezy.catalog.CatalogNextEpisode
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRank
import com.edde746.plezy.catalog.CatalogRankScope
import com.edde746.plezy.catalog.CatalogRecommendationReason
import com.edde746.plezy.catalog.CatalogRecommender
import com.edde746.plezy.catalog.CatalogRelation
import com.edde746.plezy.catalog.CatalogRelationType
import com.edde746.plezy.catalog.CatalogRequestState
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSeasonInfo
import com.edde746.plezy.catalog.CatalogSeasonName
import com.edde746.plezy.catalog.CatalogServerState
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogSourceMaterial
import com.edde746.plezy.catalog.CatalogTag
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.explore.CatalogSourcesState
import com.edde746.plezy.presentation.seerr.SeerrBlock
import com.edde746.plezy.seerr.SeerrPermission
import com.edde746.plezy.servers.FakeWatchClients
import com.edde746.plezy.servers.LibraryLookupResult
import com.edde746.plezy.servers.WatchClients
import com.edde746.plezy.strings.T
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Instant
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class CatalogDetailStoreTest {
    @BeforeTest
    fun setUp() {
        T.locale = "en"
    }

    @AfterTest
    fun tearDown() {
        T.locale = "en"
    }

    // Enrichment

    @Test
    fun fetchDetailReplacesTheOpeningItemWithItsEnrichedItemOnceLoaded() = runTest {
        val detail = CompletableDeferred<CatalogDetail>()
        val source = FakeCatalogSource(detail = { detail.await() })
        val harness = DetailHarness(this, source)
        runCurrent()
        assertEquals("Catalog Movie", harness.state.title)
        assertEquals("Overview", harness.state.overview)

        detail.complete(
            CatalogDetail(CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Enriched Catalog Movie", CatalogItemIds(tmdb = 1), overview = "Enriched overview")),
        )
        runCurrent()

        assertEquals(1, source.fetchDetailCalls)
        assertEquals("Enriched Catalog Movie", harness.state.title)
        assertEquals("Enriched overview", harness.state.overview)
    }

    @Test
    fun fetchDetailFailureLeavesTheOpeningItemRendered() = runTest {
        val source = FakeCatalogSource(detail = { throw IllegalStateException("detail unavailable") })
        val harness = DetailHarness(this, source)
        runCurrent()

        assertEquals(1, source.fetchDetailCalls)
        assertEquals("Catalog Movie", harness.state.title)
        assertEquals("Overview", harness.state.overview)
        assertTrue(harness.state.cast.isEmpty())
        assertTrue(harness.state.related.isEmpty())
    }

    @Test
    fun theActionsWaitForTheDetailLoadThatMovesThem() = runTest {
        val detail = CompletableDeferred<CatalogDetail>()
        val harness = DetailHarness(this, FakeCatalogSource(detail = { detail.await() }), seerr = true, permissions = flowOf(SeerrPermission.REQUEST))
        runCurrent()
        assertNotNull(harness.state.request)
        assertFalse(harness.state.settled)
        assertFalse(harness.state.hasActions)

        detail.complete(CatalogDetail(ITEM.copy(tagline = "A tagline", genres = listOf("Drama"))))
        runCurrent()

        assertTrue(harness.state.settled)
        assertTrue(harness.state.hasActions)
    }

    @Test
    fun theActionsShowAfterAFailedDetailLoad() = runTest {
        val harness = DetailHarness(
            this, FakeCatalogSource(detail = { throw IllegalStateException("detail unavailable") }), seerr = true,
            permissions = flowOf(SeerrPermission.REQUEST),
        )
        runCurrent()

        assertTrue(harness.state.settled)
        assertTrue(harness.state.hasActions)
    }

    @Test
    fun communityRatingsAreAskedForWithTheEnrichedItem() = runTest {
        val asked = mutableListOf<CatalogItem>()
        val score = MediaRatingSource("imdb", 7.9, votes = 12)
        val harness = DetailHarness(
            this,
            FakeCatalogSource(detail = { CatalogDetail(ENRICHED_ROW) }),
            item = BARE_ROW,
            communityRatings = { item ->
                asked += item
                flowOf(listOf(score))
            },
        )
        runCurrent()

        assertEquals(listOf(ENRICHED_ROW), asked)
        assertEquals(listOf(score), harness.state.communityRatings)
    }

    // Re-resolve

    @Test
    fun detailEnrichmentThatAddsExternalIdsReResolvesLibraryMatches() = runTest {
        val hit = copy("server-match", libraryTitle = "Movies")
        val harness = DetailHarness(
            this,
            FakeCatalogSource(detail = { CatalogDetail(ENRICHED_ROW) }),
            item = BARE_ROW,
            match = { item -> lookup(if (item.ids.tmdb != null) listOf(hit) else emptyList()) },
        )
        runCurrent()

        assertEquals(listOf(null, 99), harness.matchCalls.map { it.ids.tmdb })
        val library = assertIs<CatalogLibrarySection.Copies>(harness.state.library)
        assertEquals(listOf("Movies"), library.copies.map { it.title })
    }

    @Test
    fun detailEnrichmentThatAddsTheNativeTitleReResolvesLibraryMatches() = runTest {
        val bare = CatalogItem(CatalogSourceId.TRAKT, MediaKind.SHOW, "Frieren: Beyond Journey's End", CatalogItemIds(trakt = 198225, tvdb = 424536))
        val enriched = bare.copy(originalTitle = "葬送のフリーレン")
        val harness = DetailHarness(
            this,
            FakeCatalogSource(detail = { CatalogDetail(enriched) }),
            item = bare,
            passes = listOf(
                { lookup(succeeded = setOf("server-1")) },
                { lookup(listOf(copy("romaji-copy", libraryTitle = "Anime (romaji)"))) },
            ),
        )
        runCurrent()

        assertEquals(2, harness.matchCalls.size)
        val library = assertIs<CatalogLibrarySection.Copies>(harness.state.library)
        assertEquals(listOf("Anime (romaji)"), library.copies.map { it.title })
    }

    @Test
    fun aDetailThatAddsNothingAsksTheLibrariesOnce() = runTest {
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(ITEM) }))
        runCurrent()

        assertEquals(1, harness.matchCalls.size)
    }

    // Seerr request

    @Test
    fun requestAppearsOnceTheDetailLoadSuppliesTheTmdbId() = runTest {
        val detail = CompletableDeferred<CatalogDetail>()
        val harness = DetailHarness(this, FakeCatalogSource(detail = { detail.await() }), item = BARE_ROW, seerr = true, permissions = flowOf(SeerrPermission.REQUEST))
        runCurrent()
        assertNull(harness.state.request)

        detail.complete(CatalogDetail(ENRICHED_ROW))
        runCurrent()

        assertEquals(CatalogRequestAction(99, "Row-only Movie"), harness.state.request)
    }

    @Test
    fun requestAppearsImmediatelyWhenTheRowItemAlreadyCarriesATmdbId() = runTest {
        val detail = CompletableDeferred<CatalogDetail>()
        val harness = DetailHarness(this, FakeCatalogSource(detail = { detail.await() }), seerr = true, permissions = flowOf(SeerrPermission.REQUEST))
        runCurrent()

        assertEquals(CatalogRequestAction(1, "Catalog Movie"), harness.state.request)
    }

    @Test
    fun requestStaysHiddenWithoutTheRequestPermission() = runTest {
        val harness = DetailHarness(this, FakeCatalogSource(), seerr = true, permissions = flowOf(0))
        runCurrent()

        assertNull(harness.state.request)
    }

    @Test
    fun requestFollowsAPermissionGrantAndRevocationWhileOpen() = runTest {
        val permissions = MutableStateFlow<Int?>(0)
        val harness = DetailHarness(this, FakeCatalogSource(), seerr = true, permissions = permissions)
        runCurrent()
        assertNull(harness.state.request)

        permissions.value = SeerrPermission.REQUEST
        runCurrent()
        assertNotNull(harness.state.request)

        permissions.value = 0
        runCurrent()
        assertNull(harness.state.request)
    }

    @Test
    fun requestDisappearsWhenTheAccountDisconnectsWhileOpen() = runTest {
        val permissions = MutableStateFlow<Int?>(SeerrPermission.REQUEST)
        val harness = DetailHarness(this, FakeCatalogSource(), seerr = true, permissions = permissions)
        runCurrent()
        assertNotNull(harness.state.request)

        harness.sources.value = CatalogSourcesState(connected = listOf(harness.source))
        permissions.value = null
        runCurrent()

        assertNull(harness.state.request)
    }

    @Test
    fun aTitleSeerrHasShowsAvailableDisabledInPlaceOfRequest() = runTest {
        val harness = DetailHarness(this, FakeCatalogSource(), seerr = true, permissions = flowOf(SeerrPermission.REQUEST), requestBlock = { _, _ -> SeerrBlock.AVAILABLE })
        runCurrent()

        val request = assertNotNull(harness.state.request)
        assertEquals(T.seerr.statusAvailable, request.label)
        assertFalse(request.enabled)
        assertEquals(listOf(MediaKind.MOVIE to 1), harness.lookups)
    }

    /** Request's Available status says Seerr has it: no library note repeats it, nor says it's missing. */
    @Test
    fun aTitleSeerrHasButNoLibraryHoldsLeavesItToTheAvailableStatus() = runTest {
        val available = DetailHarness(this, FakeCatalogSource(), seerr = true, permissions = flowOf(SeerrPermission.REQUEST), requestBlock = { _, _ -> SeerrBlock.AVAILABLE })
        val requested = DetailHarness(this, FakeCatalogSource(), seerr = true, permissions = flowOf(SeerrPermission.REQUEST), requestBlock = { _, _ -> SeerrBlock.REQUESTED })
        runCurrent()

        assertEquals(CatalogLibrarySection.SaidByStatus, available.state.library)
        assertEquals(CatalogLibrarySection.NotInLibrary, requested.state.library)
    }

    @Test
    fun theDetailSettlesOnlyOnceSeerrHasAnswered() = runTest {
        val detail = CompletableDeferred<CatalogDetail>()
        val answer = CompletableDeferred<SeerrBlock?>()
        val harness = DetailHarness(
            this, FakeCatalogSource(detail = { detail.await() }), seerr = true, permissions = flowOf(SeerrPermission.REQUEST),
            requestBlock = { _, _ -> answer.await() },
        )
        runCurrent()
        detail.complete(CatalogDetail(ITEM))
        runCurrent()
        // The detail is in, Seerr hasn't answered: the actions may still change.
        assertFalse(harness.state.settled)
        assertEquals(T.seerr.request, harness.state.request?.label)

        answer.complete(SeerrBlock.REQUESTED)
        runCurrent()
        assertTrue(harness.state.settled)
        assertEquals(T.seerr.statusRequested, harness.state.request?.label)
    }

    @Test
    fun aRequestSentFromTheSheetAsksSeerrAgainAndReloadsTheDetail() = runTest {
        var block: SeerrBlock? = null
        var overview = "Not requested"
        val source = FakeCatalogSource(detail = { CatalogDetail(ITEM.copy(overview = overview)) })
        val harness = DetailHarness(this, source, seerr = true, permissions = flowOf(SeerrPermission.REQUEST), requestBlock = { _, _ -> block })
        runCurrent()
        assertTrue(harness.state.request!!.enabled)
        assertEquals(1, source.fetchDetailCalls)

        block = SeerrBlock.REQUESTED
        overview = "Requested"
        // Another title's request changes nothing here.
        harness.requested.emit(2)
        runCurrent()
        assertEquals(1, harness.lookups.size)
        assertEquals(1, source.fetchDetailCalls)

        harness.requested.emit(1)
        runCurrent()
        assertEquals(2, harness.lookups.size)
        assertEquals(T.seerr.statusRequested, harness.state.request?.label)
        assertFalse(harness.state.request!!.enabled)
        // The detail, and the request state it carries, is fetched again.
        assertEquals(2, source.fetchDetailCalls)
        assertEquals("Requested", harness.state.overview)
    }

    /**
     * The disabled Request action carries the title's state: the stats line doesn't repeat it (the request's state while
     * requested, Available once available) but keeps the availability facts beside it and the 4K request.
     */
    @Test
    fun theStatsLineDoesNotRepeatTheStateTheRequestActionShows() = runTest {
        var block: SeerrBlock? = SeerrBlock.REQUESTED
        var server = CatalogServerState(
            availability = CatalogAvailability.PARTIALLY_AVAILABLE, request = CatalogRequestState.PENDING,
            request4k = CatalogRequestState.APPROVED, availableSeasons = 1, totalSeasons = 3,
        )
        val source = FakeCatalogSource(detail = { CatalogDetail(ITEM.copy(serverState = server)) })
        val harness = DetailHarness(this, source, seerr = true, permissions = flowOf(SeerrPermission.REQUEST), requestBlock = { _, _ -> block })
        runCurrent()
        assertEquals(listOf(T.explore.badge.partiallyAvailable, T.explore.badge.requested4k, T.explore.badge.seasonsAvailable("1", "3")), harness.state.stats)

        block = SeerrBlock.AVAILABLE
        server = CatalogServerState(availability = CatalogAvailability.AVAILABLE, request = CatalogRequestState.APPROVED)
        harness.requested.emit(1)
        runCurrent()
        assertEquals(listOf(T.explore.badge.requested), harness.state.stats)

        // Request open: the request's state is the line's to say.
        block = null
        server = CatalogServerState(request = CatalogRequestState.DECLINED)
        harness.requested.emit(1)
        runCurrent()
        assertEquals(listOf(T.explore.badge.declined), harness.state.stats)
    }

    @Test
    fun aFailedLookupLeavesRequestOpen() = runTest {
        val harness = DetailHarness(this, FakeCatalogSource(), seerr = true, permissions = flowOf(SeerrPermission.REQUEST), requestBlock = { _, _ -> error("Seerr down") })
        runCurrent()
        assertTrue(harness.state.settled)
        assertEquals(CatalogRequestAction(1, "Catalog Movie"), harness.state.request)
    }

    @Test
    fun seerrIsNotAskedWithoutTheRequestPermission() = runTest {
        val harness = DetailHarness(this, FakeCatalogSource(), seerr = true, permissions = flowOf(0), requestBlock = { _, _ -> SeerrBlock.AVAILABLE })
        runCurrent()
        assertTrue(harness.lookups.isEmpty())
        assertTrue(harness.state.settled)
    }

    // Library section

    @Test
    fun listsEveryLibraryCopyOfOneTitleBestQualityFirst() = runTest {
        val harness = DetailHarness(
            this,
            FakeCatalogSource(),
            passes = listOf {
                lookup(listOf(copy("hd-copy", libraryTitle = "Movies", resolution = "1080"), copy("uhd-copy", libraryTitle = "4K Movies", resolution = "4k")))
            },
        )
        runCurrent()

        val library = assertIs<CatalogLibrarySection.Copies>(harness.state.library)
        assertEquals(listOf("4K Movies", "Movies"), library.copies.map { it.title })
        val subtitles = library.copies.map { assertNotNull(it.subtitle) }
        assertContains(subtitles[0], "4K")
        assertContains(subtitles[0], "Living Room")
        assertContains(subtitles[1], "1080p")
        assertNull(library.uncheckedNote)
    }

    @Test
    fun aCopyCarriesTheKindOfItsLibraryElseItsOwnKind() = runTest {
        val libraries = MutableStateFlow(emptyList<MediaLibrary>())
        val harness = DetailHarness(
            this,
            FakeCatalogSource(),
            passes = listOf {
                lookup(listOf(copy("home-copy", libraryTitle = "Home Videos", resolution = "4k"), copy("mixed-copy", libraryTitle = "Everything", resolution = "1080"), copy("bare-copy")))
            },
            libraries = libraries,
        )
        runCurrent()
        val kinds = { assertIs<CatalogLibrarySection.Copies>(harness.state.library).copies.map { it.libraryKind } }
        assertEquals(listOf(MediaKind.MOVIE, MediaKind.MOVIE, MediaKind.MOVIE), kinds())

        libraries.value = listOf(
            MediaLibrary("home-copy", BackendKind.PLEX, "Home Videos", kind = MediaKind.CLIP, serverId = "server-1"),
            MediaLibrary("mixed-copy", BackendKind.PLEX, "Everything", kind = MediaKind.UNKNOWN, serverId = "server-1"),
        )
        runCurrent()

        assertEquals(listOf(MediaKind.CLIP, MediaKind.MOVIE, MediaKind.MOVIE), kinds())
    }

    @Test
    fun checkingWhileTheFirstLookupRuns() = runTest {
        val pending = CompletableDeferred<LibraryLookupResult>()
        val harness = DetailHarness(this, FakeCatalogSource(), passes = listOf { pending.await() })
        runCurrent()

        assertEquals(CatalogLibrarySection.Checking, harness.state.library)
    }

    @Test
    fun aReResolveThatComesBackShortKeepsTheCopiesAlreadyFound() = runTest {
        val harness = enrichedHarness(
            this,
            { lookup(listOf(copy("hd-copy", libraryTitle = "Movies"))) },
            { lookup() },
        )
        runCurrent()

        assertEquals(2, harness.matchCalls.size)
        val library = assertIs<CatalogLibrarySection.Copies>(harness.state.library)
        assertEquals(listOf("Movies"), library.copies.map { it.title })
    }

    @Test
    fun aFailedReResolveDoesNotClaimTheTitleLeftTheLibrary() = runTest {
        val harness = enrichedHarness(
            this,
            { lookup(listOf(copy("hd-copy", libraryTitle = "Movies"))) },
            { throw IllegalStateException("server unreachable") },
        )
        runCurrent()

        assertEquals(2, harness.matchCalls.size)
        val library = assertIs<CatalogLibrarySection.Copies>(harness.state.library)
        assertEquals(listOf("Movies"), library.copies.map { it.title })
    }

    @Test
    fun aMatcherErrorCountsEveryExpectedServerUnchecked() = runTest {
        val harness = DetailHarness(
            this,
            FakeCatalogSource(),
            passes = listOf { throw IllegalStateException("lookup failed") },
            expectedServerIds = setOf(ServerId("server-1"), ServerId("server-2")),
        )
        runCurrent()

        assertEquals(CatalogLibrarySection.Unchecked(T.explore.libraryCheckFailed(2)), harness.state.library)
    }

    @Test
    fun aServerThatCouldNotBeAskedIsReportedInsteadOfCountedAsAMiss() = runTest {
        val harness = enrichedHarness(this, { lookup(failed = setOf("server-1")) })
        runCurrent()

        assertEquals(CatalogLibrarySection.Unchecked(T.explore.libraryCheckFailed(1)), harness.state.library)
    }

    @Test
    fun aServerThatWasNeverAskedIsReportedInsteadOfCountedAsAMiss() = runTest {
        val harness = enrichedHarness(this, { lookup(unqueried = setOf("server-1")) })
        runCurrent()

        assertEquals(CatalogLibrarySection.Unchecked(T.explore.libraryCheckFailed(1)), harness.state.library)
    }

    @Test
    fun anUncheckedServerIsNotedUnderTheCopiesOtherServersFound() = runTest {
        val harness = enrichedHarness(
            this,
            { lookup(listOf(copy("hd-copy", libraryTitle = "Movies")), succeeded = setOf("server-1"), failed = setOf("server-2", "server-3")) },
        )
        runCurrent()

        val library = assertIs<CatalogLibrarySection.Copies>(harness.state.library)
        assertEquals(listOf("Movies"), library.copies.map { it.title })
        assertEquals(T.explore.libraryCheckFailed(2), library.uncheckedNote)
    }

    @Test
    fun aServerThatAnswersALaterPassStopsBeingReportedAsUnchecked() = runTest {
        val harness = enrichedHarness(
            this,
            { lookup(failed = setOf("server-1")) },
            { lookup(succeeded = setOf("server-1")) },
        )
        runCurrent()

        assertEquals(CatalogLibrarySection.NotInLibrary, harness.state.library)
    }

    @Test
    fun enrichmentFailureStaysUncheckedWhicheverLookupFinishesFirst() {
        for (nativeTitle in listOf(false, true)) {
            for (richerFinishesFirst in listOf(false, true)) {
                runTest {
                    val bare = if (nativeTitle) ITEM else BARE_ROW
                    val enriched = if (nativeTitle) ITEM.copy(overview = null, originalTitle = "銀河鉄道の夜") else ENRICHED_ROW
                    val detail = CompletableDeferred<CatalogDetail>()
                    val weaker = CompletableDeferred<LibraryLookupResult>()
                    val richer = CompletableDeferred<LibraryLookupResult>()
                    val verified = copy("verified", libraryTitle = "Verified Movies")
                    val harness = DetailHarness(
                        this,
                        FakeCatalogSource(detail = { detail.await() }),
                        item = bare,
                        passes = listOf({ weaker.await() }, { richer.await() }),
                    )
                    runCurrent()
                    if (!richerFinishesFirst) {
                        weaker.complete(lookup(listOf(verified), succeeded = setOf("server-1")))
                        runCurrent()
                        assertEquals(listOf("Verified Movies"), assertIs<CatalogLibrarySection.Copies>(harness.state.library).copies.map { it.title })
                    }
                    detail.complete(CatalogDetail(enriched))
                    runCurrent()
                    richer.complete(if (nativeTitle) lookup(cancelled = setOf("server-1")) else lookup(failed = setOf("server-1")))
                    runCurrent()
                    val unchecked = T.explore.libraryCheckFailed(1)
                    if (richerFinishesFirst) {
                        assertEquals(CatalogLibrarySection.Unchecked(unchecked), harness.state.library)
                        weaker.complete(lookup(listOf(verified), succeeded = setOf("server-1")))
                        runCurrent()
                    }
                    val library = assertIs<CatalogLibrarySection.Copies>(harness.state.library, "native=$nativeTitle richerFirst=$richerFinishesFirst")
                    assertEquals(listOf("Verified Movies"), library.copies.map { it.title })
                    assertEquals(unchecked, library.uncheckedNote)
                }
            }
        }
    }

    @Test
    fun aWeakerSuccessfulMissCannotTurnFailedEnrichmentIntoLibraryAbsence() = runTest {
        val harness = enrichedHarness(
            this,
            { lookup(succeeded = setOf("server-1")) },
            { lookup(failed = setOf("server-1")) },
        )
        runCurrent()

        assertEquals(CatalogLibrarySection.Unchecked(T.explore.libraryCheckFailed(1)), harness.state.library)
    }

    @Test
    fun aLateWeakerFailureCannotOverwriteRicherSuccessfulEmptyCoverage() = runTest {
        val weaker = CompletableDeferred<LibraryLookupResult>()
        val harness = enrichedHarness(
            this,
            { weaker.await() },
            { lookup(succeeded = setOf("server-1")) },
        )
        runCurrent()
        assertEquals(CatalogLibrarySection.NotInLibrary, harness.state.library)

        weaker.complete(lookup(failed = setOf("server-1")))
        runCurrent()

        assertEquals(CatalogLibrarySection.NotInLibrary, harness.state.library)
    }

    @Test
    fun aReResolveThatLostItsLibraryStampKeepsTheOneAlreadyShown() = runTest {
        val harness = enrichedHarness(
            this,
            { lookup(listOf(copy("hd-copy", libraryTitle = "Movies", resolution = "1080"))) },
            { lookup(listOf(copy("hd-copy", serverName = null))) },
        )
        runCurrent()

        assertEquals(2, harness.matchCalls.size)
        val only = assertIs<CatalogLibrarySection.Copies>(harness.state.library).copies.single()
        assertEquals("Movies", only.title)
        val subtitle = assertNotNull(only.subtitle)
        assertContains(subtitle, "1080p")
        assertContains(subtitle, "Living Room")
    }

    @Test
    fun aReResolveThatFindsAnotherLibraryAddsItToTheList() = runTest {
        val harness = enrichedHarness(
            this,
            { lookup(listOf(copy("uhd-copy", libraryTitle = "4K Movies", resolution = "4k"))) },
            { lookup(listOf(copy("uhd-copy", libraryTitle = "4K Movies", resolution = "4k"), copy("hd-copy", libraryTitle = "Movies", resolution = "1080"))) },
        )
        runCurrent()

        assertEquals(listOf("4K Movies", "Movies"), assertIs<CatalogLibrarySection.Copies>(harness.state.library).copies.map { it.title })
    }

    @Test
    fun aCopyKeepsItsKeyWhenALaterPassSortsAnotherAboveIt() = runTest {
        val detail = CompletableDeferred<CatalogDetail>()
        val harness = DetailHarness(
            this,
            FakeCatalogSource(detail = { detail.await() }),
            item = BARE_ROW,
            passes = listOf(
                { lookup(listOf(copy("hd-copy", libraryTitle = "Movies", resolution = "1080"))) },
                { lookup(listOf(copy("hd-copy", libraryTitle = "Movies", resolution = "1080"), copy("uhd-copy", libraryTitle = "4K Movies", resolution = "4k"))) },
            ),
        )
        runCurrent()
        assertEquals(listOf("server-1:hd-copy"), assertIs<CatalogLibrarySection.Copies>(harness.state.library).copies.map { it.key })

        detail.complete(CatalogDetail(ENRICHED_ROW))
        runCurrent()

        assertEquals(
            listOf("server-1:uhd-copy", "server-1:hd-copy"),
            assertIs<CatalogLibrarySection.Copies>(harness.state.library).copies.map { it.key },
        )
    }

    // Watchlist

    @Test
    fun pendingWatchlistActionStaysOfferedAndItsPressRetriesTheSnapshot() = runTest {
        val source = FakeCatalogSource(watchlistLoading = true)
        val harness = DetailHarness(this, source)
        runCurrent()
        assertEquals(CatalogWatchlistAction(null, T.explore.addToWatchlist), harness.state.watchlist)
        val loadsAtOpen = source.ensureCalls

        harness.store.toggleWatchlist()
        runCurrent()
        assertEquals(0, source.addCalls)
        assertEquals(loadsAtOpen + 1, source.ensureCalls)

        source.completeWatchlistLoad()
        runCurrent()
        assertEquals(CatalogWatchlistAction(false, T.explore.addToWatchlist), harness.state.watchlist)
        harness.store.toggleWatchlist()
        runCurrent()

        assertEquals(1, source.addCalls)
        assertEquals(CatalogWatchlistAction(true, T.explore.removeFromWatchlist), harness.state.watchlist)
    }

    @Test
    fun aWatchlistChangeInFlightIgnoresAnotherPress() = runTest {
        val source = FakeCatalogSource()
        val gate = CompletableDeferred<Unit>()
        source.addGate = gate
        val harness = DetailHarness(this, source)
        runCurrent()

        harness.store.toggleWatchlist()
        runCurrent()
        harness.store.toggleWatchlist()
        runCurrent()
        gate.complete(Unit)
        runCurrent()

        assertEquals(1, source.addCalls)
    }

    @Test
    fun aFailedWatchlistChangeSaysSo() = runTest {
        val source = FakeCatalogSource()
        source.addFailure = IllegalStateException("rejected")
        val harness = DetailHarness(this, source)
        runCurrent()

        harness.store.toggleWatchlist()
        runCurrent()
        assertEquals(T.explore.watchlistUpdateFailed, harness.state.message)

        harness.store.messageShown()
        assertNull(harness.state.message)
    }

    @Test
    fun noWatchlistActionWhenTheOwnSourceHasNone() = runTest {
        val harness = DetailHarness(this, FakeCatalogSource(supportsWatchlist = false))
        runCurrent()

        assertNull(harness.state.watchlist)
    }

    // Trailer and links

    @Test
    fun trailerActionAppearsOnlyAfterAnItemSuppliesATrailerUrl() = runTest {
        val detail = CompletableDeferred<CatalogDetail>()
        val harness = DetailHarness(this, FakeCatalogSource(detail = { detail.await() }))
        runCurrent()
        assertFalse(harness.state.hasTrailer)

        detail.complete(CatalogDetail(ITEM.copy(trailerUrl = "https://example.com/trailer")))
        runCurrent()

        assertTrue(harness.state.hasTrailer)
    }

    @Test
    fun saysSoWhenAnOutboundLinkCannotBeOpened() = runTest {
        val item = ITEM.copy(links = listOf(CatalogLink("StreamCo", "https://example.com/watch", isStreaming = true)))
        val host = FakeHost(openSucceeds = false)
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item, host = host)
        runCurrent()
        val link = harness.state.watchOnLinks.single()
        assertEquals("Open on StreamCo", link.label)

        harness.store.openLink(link.url)

        assertEquals(listOf("https://example.com/watch"), host.opened)
        assertEquals(T.explore.detail.linkUnavailable, harness.state.message)
    }

    @Test
    fun saysSoWhenTheTrailerCannotBeOpened() = runTest {
        val host = FakeHost(openSucceeds = false)
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(TRAILER_ITEM) }), item = TRAILER_ITEM, host = host)
        runCurrent()

        harness.store.playTrailer()

        assertEquals(listOf("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), host.opened)
        assertEquals(T.explore.detail.trailerUnavailable, harness.state.message)
    }

    @Test
    fun withoutABrowserOutboundLinksAreHidden() = runTest {
        val item = ITEM.copy(
            links = listOf(CatalogLink("StreamCo", "https://example.com/watch", isStreaming = true), CatalogLink("Official Site", "https://example.com")),
        )
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item, host = FakeHost(hasBrowser = false))
        runCurrent()

        assertTrue(harness.state.watchOnLinks.isEmpty())
        assertTrue(harness.state.links.isEmpty())
    }

    @Test
    fun withoutABrowserAYouTubeTrailerGoesToTheYouTubeApp() = runTest {
        val host = FakeHost(hasBrowser = false)
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(TRAILER_ITEM) }), item = TRAILER_ITEM, host = host)
        runCurrent()
        assertTrue(harness.state.hasTrailer)

        harness.store.playTrailer()

        assertEquals(listOf("youtube://www.youtube.com/watch?v=dQw4w9WgXcQ"), host.opened)
        assertNull(harness.state.message)
    }

    @Test
    fun withoutABrowserSaysSoWhenTheYouTubeAppDoesNotOpenTheTrailer() = runTest {
        val host = FakeHost(hasBrowser = false, openSucceeds = false)
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(TRAILER_ITEM) }), item = TRAILER_ITEM, host = host)
        runCurrent()

        harness.store.playTrailer()

        assertEquals(T.explore.detail.trailerUnavailable, harness.state.message)
    }

    @Test
    fun withoutABrowserTheTrailerIsHiddenWithoutTheYouTubeAppOrALibraryTrailer() = runTest {
        val harness = DetailHarness(
            this,
            FakeCatalogSource(detail = { CatalogDetail(TRAILER_ITEM) }),
            item = TRAILER_ITEM,
            host = FakeHost(hasBrowser = false, youTubeInstalled = false),
        )
        runCurrent()

        assertFalse(harness.state.hasTrailer)
    }

    @Test
    fun aLibraryCopysOwnTrailerIsOfferedWithoutTheYouTubeAppAndPlaysInThePlayer() = runTest {
        val backend = ExtrasBackend(
            listOf(
                extra("featurette-1", "Featurette"),
                extra("trailer-1", "Trailer"),
            ),
        )
        val clients = FakeWatchClients().apply { register(backend) }
        val host = FakeHost(hasBrowser = false, youTubeInstalled = false)
        val harness = DetailHarness(
            this,
            FakeCatalogSource(detail = { CatalogDetail(TRAILER_ITEM) }),
            item = TRAILER_ITEM,
            host = host,
            clients = clients,
            passes = listOf { lookup(listOf(copy("copy-1", libraryTitle = "Movies"))) },
        )
        runCurrent()

        assertEquals(listOf("copy-1"), backend.fetched)
        assertTrue(harness.state.hasTrailer)
        harness.store.playTrailer()
        assertTrue(host.opened.isEmpty())
        val played = host.played.single()
        assertEquals("trailer-1", played.id)
        assertEquals("server-1", played.serverId)
    }

    @Test
    fun aLibraryTrailerThatCannotPlayHereFallsBackToTheProvidersThenSaysSo() = runTest {
        val backend = ExtrasBackend(listOf(extra("trailer-1", "Trailer")))
        val clients = FakeWatchClients().apply { register(backend) }
        val host = FakeHost(openSucceeds = false, playSucceeds = false)
        val harness = DetailHarness(
            this,
            FakeCatalogSource(detail = { CatalogDetail(TRAILER_ITEM) }),
            item = TRAILER_ITEM,
            host = host,
            clients = clients,
            passes = listOf { lookup(listOf(copy("copy-1", libraryTitle = "Movies"))) },
        )
        runCurrent()

        harness.store.playTrailer()

        assertEquals("trailer-1", host.played.single().id)
        assertEquals(listOf("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), host.opened)
        assertEquals(T.explore.detail.trailerUnavailable, harness.state.message)
    }

    // Header, chips and sections

    @Test
    fun headerCarriesTheMetaLineAndGenres() = runTest {
        val item = ITEM.copy(year = 2024, runtimeMinutes = 135, certification = " PG-13 ", genres = listOf("Drama", "Comedy"), tagline = "A tagline")
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item)
        runCurrent()

        assertEquals("2024 • 2 h 15 min • PG-13", harness.state.metaLine)
        assertEquals("Drama • Comedy", harness.state.genres)
        assertEquals("A tagline", harness.state.tagline)
    }

    @Test
    fun theScoreChipCarriesItsCompactVoteCount() = runTest {
        val item = ITEM.copy(rating = 7.46, votes = 12_345)
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item)
        runCurrent()

        assertEquals("7.5 (12.3K votes)", harness.state.stats.first())
    }

    @Test
    fun seasonalRankKeepsItsSeasonWindowInsteadOfClaimingAllTimeRank() = runTest {
        val item = CatalogItem(
            CatalogSourceId.TRAKT,
            MediaKind.SHOW,
            "Seasonal Show",
            CatalogItemIds(tmdb = 12),
            ranks = listOf(CatalogRank(7, CatalogRankScope.POPULAR, allTime = false, year = 2025, season = CatalogSeasonName.FALL)),
        )
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item)
        runCurrent()

        assertContains(harness.state.stats, "#7 in Fall 2025")
        assertFalse("#7 popular" in harness.state.stats)
    }

    @Test
    fun windowedViewersRenderOnlyWhenTheirPeriodIsPresent() = runTest {
        val missingPeriod = ITEM.copy(audience = CatalogAudience(listed = 3, viewers = 42))
        val first = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(missingPeriod) }), item = missingPeriod)
        runCurrent()
        assertEquals(listOf("3 listed"), first.state.stats)

        val weekly = ITEM.copy(audience = CatalogAudience(viewers = 42, viewersPeriod = CatalogAudiencePeriod.WEEK))
        val second = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(weekly) }), item = weekly)
        runCurrent()
        assertEquals(listOf("42 watched this week"), second.state.stats)
    }

    @Test
    fun spoilerTagsStayHiddenUntilRevealed() = runTest {
        val item = ITEM.copy(tags = listOf(CatalogTag("Found family", rank = 80), CatalogTag("Secret identity", rank = 95, isSpoiler = true)))
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item)
        runCurrent()
        assertEquals(CatalogDetailTags(listOf("Found family"), canRevealSpoilers = true), harness.state.tags)

        harness.store.revealSpoilerTags()

        assertEquals(CatalogDetailTags(listOf("Secret identity", "Found family"), canRevealSpoilers = false), harness.state.tags)
    }

    @Test
    fun backgroundProseIsItsOwnSection() = runTest {
        val item = ITEM.copy(background = "Filmed over three winters.")
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item)
        runCurrent()

        assertEquals("Filmed over three winters.", harness.state.background)
    }

    @Test
    fun allNullMetadataLeavesEveryOptionalSectionOut() = runTest {
        val item = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Bare Movie", CatalogItemIds(tmdb = 15))
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item)
        runCurrent()
        val state = harness.state

        assertEquals("Bare Movie", state.title)
        assertNull(state.metaLine)
        assertNull(state.genres)
        assertTrue(state.stats.isEmpty())
        assertNull(state.overview)
        assertNull(state.background)
        assertTrue(state.facts.isEmpty())
        assertTrue(state.recommenders.isEmpty())
        assertTrue(state.ratings.isEmpty())
        assertTrue(state.schedule.isEmpty())
        assertTrue(state.crew.isEmpty())
        assertNull(state.tags)
        assertTrue(state.watchOnLinks.isEmpty())
        assertTrue(state.links.isEmpty())
        assertTrue(state.cast.isEmpty())
        assertTrue(state.relations.isEmpty())
        assertTrue(state.related.isEmpty())
    }

    @Test
    fun relationsFlattenToOneLabelledEntryPerTitleApartFromMoreLikeThis() = runTest {
        val sequel = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "The Sequel", CatalogItemIds(tmdb = 17), year = 2019)
        val spinOff = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "The Spin-off", CatalogItemIds(tmdb = 20))
        val recommendation = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "A Similar Movie", CatalogItemIds(tmdb = 18))
        val harness = DetailHarness(
            this,
            FakeCatalogSource(
                detail = {
                    CatalogDetail(
                        ITEM,
                        related = listOf(recommendation),
                        relations = listOf(
                            CatalogRelation(CatalogRelationType.SEQUEL, listOf(sequel)),
                            CatalogRelation(CatalogRelationType.SPIN_OFF, listOf(spinOff)),
                        ),
                    )
                },
            ),
        )
        runCurrent()

        assertEquals(listOf(recommendation), harness.state.related)
        assertEquals(
            listOf(
                CatalogRelationEntry(T.explore.relation.sequel, "The Sequel • 2019", sequel),
                CatalogRelationEntry(T.explore.relation.spinOff, "The Spin-off", spinOff),
            ),
            harness.state.relations,
        )
    }

    @Test
    fun animeProvidersTitleTheirCastCharactersAndEveryOtherSourceCast() = runTest {
        for (source in CatalogSourceId.entries) {
            val harness = DetailHarness(this, FakeCatalogSource(id = source), item = ITEM.copy(source = source))
            runCurrent()

            val expected = if (source == CatalogSourceId.MAL || source == CatalogSourceId.ANILIST) T.explore.characters else T.explore.cast
            assertEquals(expected, harness.state.castTitle, "$source")
            assertEquals(listOf("First Actor", "Second Actor"), harness.state.cast.map { it.name }, "$source")
        }
    }

    @Test
    fun socialRecommendationKeepsItsPersonReasonAndNote() = runTest {
        val item = ITEM.copy(
            recommenders = listOf(CatalogRecommender("pat", CatalogRecommendationReason.RECOMMENDED, name = "Pat", note = "A thoughtful recommendation.")),
        )
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item)
        runCurrent()

        assertEquals(listOf(CatalogDetailRecommender("Recommended by Pat", "A thoughtful recommendation.")), harness.state.recommenders)
    }

    @Test
    fun extendedFactsLandInTheirSectionsWithLocalizedValues() = runTest {
        val item = CatalogItem(
            CatalogSourceId.TRAKT,
            MediaKind.SHOW,
            "Fact-rich Show",
            CatalogItemIds(tmdb = 20),
            broadcastSeason = CatalogSeasonInfo(CatalogSeasonName.FALL, 2025),
            format = CatalogFormat.OVA,
            sourceMaterial = CatalogSourceMaterial.LIGHT_NOVEL,
            studios = listOf("Studio One"),
            countries = listOf("US"),
            languages = listOf("ja"),
            credits = listOf(CatalogCredit("A. Director", CatalogCreditRole.DIRECTOR), CatalogCredit("W. Writer", CatalogCreditRole.WRITER)),
            broadcast = CatalogBroadcast(weekday = 2, time = "21:00", timezone = "Asia/Tokyo"),
            nextEpisode = CatalogNextEpisode(Instant.parse("2100-01-01T00:00:00Z"), episode = 4),
            serverState = CatalogServerState(
                availability = CatalogAvailability.AVAILABLE,
                request = CatalogRequestState.PENDING,
                availableSeasons = 2,
                totalSeasons = 3,
            ),
            audience = CatalogAudience(dropRate = 0.25),
            releaseDate = Instant.parse("2024-01-02T00:00:00Z"),
            endDate = Instant.parse("2025-06-07T00:00:00Z"),
            userRating = 9.0,
            originalTitle = "Original Fact Title",
            altTitles = listOf("Alternate Fact Title"),
            contentAdvisory = "Suitable for older teens.",
            budget = 1_000_000,
            revenue = 2_500_000,
            links = listOf(CatalogLink("StreamCo", "https://example.com/watch", isStreaming = true), CatalogLink("Official Site", "https://example.com")),
        )
        val harness = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item)
        runCurrent()
        val state = harness.state

        for (chip in listOf("Fall 2025", "OVA", "Light novel", "25% dropped it", "Available", "Pending approval", "2/3 seasons")) {
            assertContains(state.stats, chip)
        }
        assertEquals("Airs Tuesday at 21:00 Asia/Tokyo", state.schedule[0])
        assertContains(state.schedule[1], "Ep 4 in")
        val facts = state.facts.associate { it.label to it.value }
        val detail = T.explore.detail
        assertEquals("Original Fact Title", facts[detail.originalTitle])
        assertEquals("Alternate Fact Title", facts[detail.alsoKnownAs])
        assertEquals("United States", facts[detail.country])
        assertEquals("Japanese", facts[detail.language])
        assertEquals("Jan 2, 2024", facts[detail.released])
        assertEquals("9.0", facts[detail.yourRating])
        assertContains(assertNotNull(facts[detail.budget]), "1,000,000")
        assertContains(assertNotNull(facts[detail.revenue]), "2,500,000")
        assertEquals("Suitable for older teens.", facts[detail.contentAdvisory])
        assertEquals(
            listOf(CatalogDetailFact(T.explore.creditRole.director, "A. Director"), CatalogDetailFact(T.explore.creditRole.writer, "W. Writer")),
            state.crew,
        )
        assertEquals(listOf(CatalogDetailLink("Open on StreamCo", "https://example.com/watch")), state.watchOnLinks)
        assertEquals(listOf(CatalogDetailLink("Open on Official Site", "https://example.com")), state.links)
    }

    @Test
    fun anAiringTimeFollowsThePlatformsClock() = runTest {
        val item = ITEM.copy(broadcast = CatalogBroadcast(weekday = 2, time = "21:00", timezone = "Asia/Tokyo"))
        val twelveHour = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(item) }), item = item, host = FakeHost(use24HourClock = false))
        runCurrent()
        assertEquals("Airs Tuesday at 9:00 PM Asia/Tokyo", twelveHour.state.schedule[0].replace('\u202F', ' '))
        val unreadable = ITEM.copy(broadcast = CatalogBroadcast(weekday = 2, time = "late evening"))
        val asItIs = DetailHarness(this, FakeCatalogSource(detail = { CatalogDetail(unreadable) }), item = unreadable, host = FakeHost(use24HourClock = false))
        runCurrent()
        assertEquals("Airs Tuesday at late evening", asItIs.state.schedule[0])
    }

    // Kit

    private fun enrichedHarness(scope: TestScope, vararg passes: suspend () -> LibraryLookupResult) =
        DetailHarness(scope, FakeCatalogSource(detail = { CatalogDetail(ENRICHED_ROW) }), item = BARE_ROW, passes = passes.toList())

    private class DetailHarness(
        scope: TestScope,
        val source: FakeCatalogSource,
        item: CatalogItem = ITEM,
        passes: List<suspend () -> LibraryLookupResult> = listOf { lookup() },
        match: (suspend (CatalogItem) -> LibraryLookupResult)? = null,
        seerr: Boolean = false,
        permissions: Flow<Int?> = flowOf(null),
        host: FakeHost = FakeHost(),
        clients: WatchClients = FakeWatchClients(),
        expectedServerIds: Set<ServerId> = emptySet(),
        communityRatings: (CatalogItem) -> Flow<List<MediaRatingSource>> = { flowOf(emptyList()) },
        libraries: Flow<List<MediaLibrary>> = flowOf(emptyList()),
        requestBlock: suspend (MediaKind, Int) -> SeerrBlock? = { _, _ -> null },
    ) {
        val matchCalls = mutableListOf<CatalogItem>()
        val lookups = mutableListOf<Pair<MediaKind, Int>>()
        val requested = MutableSharedFlow<Int>()
        private val seerrSource = if (seerr) FakeCatalogSource(id = CatalogSourceId.SEERR, supportsWatchlist = false) else null
        val sources = MutableStateFlow(CatalogSourcesState(connected = listOfNotNull(source, seerrSource), seerr = seerrSource))
        val store = CatalogDetailStore(
            opening = item,
            sources = sources,
            seerrPermissions = permissions,
            matchLibrary = { lookupItem ->
                val pass = passes[minOf(matchCalls.size, passes.size - 1)]
                matchCalls += lookupItem
                match?.invoke(lookupItem) ?: pass()
            },
            expectedServerIds = { expectedServerIds },
            clients = clients,
            libraries = libraries,
            communityRatings = communityRatings,
            seerrRequestBlock = { kind, tmdbId ->
                lookups += kind to tmdbId
                requestBlock(kind, tmdbId)
            },
            seerrRequested = requested,
            host = host,
            parentScope = scope.backgroundScope,
            clock = FixedClock,
        )
        val state: CatalogDetailUiState get() = store.state.value
    }

    private class FakeHost(
        override val hasBrowser: Boolean = true,
        override val use24HourClock: Boolean = true,
        private val youTubeInstalled: Boolean = true,
        private val openSucceeds: Boolean = true,
        private val playSucceeds: Boolean = true,
    ) : CatalogDetailHost {
        val opened = mutableListOf<String>()
        val played = mutableListOf<MediaItem>()

        override suspend fun youTubeAppInstalled(): Boolean = youTubeInstalled

        override fun openUrl(url: String): Boolean {
            opened += url
            return openSucceeds
        }

        override fun playTrailer(trailer: MediaItem): Boolean {
            played += trailer
            return playSucceeds
        }
    }

    private class FakeCatalogSource(
        override val id: CatalogSourceId = CatalogSourceId.TRAKT,
        override val supportsWatchlist: Boolean = true,
        watchlistLoading: Boolean = false,
        private val detail: suspend (CatalogItem) -> CatalogDetail = { item ->
            CatalogDetail(
                item,
                cast = listOf(CatalogCastMember("First Actor", "Lead"), CatalogCastMember("Second Actor", "Support")),
                related = listOf(CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Related Movie", CatalogItemIds(tmdb = 2))),
            )
        },
    ) : CatalogSource {
        private var membership: Boolean? = if (watchlistLoading) null else false
        private val load = if (watchlistLoading) CompletableDeferred<Unit>() else null
        private val changes = MutableSharedFlow<Unit>(extraBufferCapacity = 16)
        var fetchDetailCalls = 0
        var ensureCalls = 0
        var addCalls = 0
        var addGate: CompletableDeferred<Unit>? = null
        var addFailure: Exception? = null

        override val supportedRows: List<CatalogRowId> = emptyList()
        override val watchlistChanges: Flow<Unit> = changes

        override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage = throw IllegalArgumentException("No rows")

        override suspend fun search(query: String, limit: Int): List<CatalogItem> = emptyList()

        override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail {
            fetchDetailCalls++
            return detail(item)
        }

        override suspend fun ensureWatchlistLoaded() {
            ensureCalls++
            load?.await()
        }

        fun completeWatchlistLoad() {
            membership = false
            changes.tryEmit(Unit)
            load!!.complete(Unit)
        }

        override fun isOnWatchlist(kind: MediaKind, ids: CatalogItemIds): Boolean? = membership

        override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? = null

        override suspend fun addToWatchlist(kind: MediaKind, ids: CatalogItemIds) {
            addCalls++
            addGate?.await()
            addFailure?.let { throw it }
            membership = true
            changes.tryEmit(Unit)
        }

        override suspend fun removeFromWatchlist(kind: MediaKind, ids: CatalogItemIds) {
            membership = false
            changes.tryEmit(Unit)
        }

        override fun dispose() {}
    }

    private class ExtrasBackend(private val extras: List<MediaItem>) : FakeMediaBackend("server-1") {
        val fetched = mutableListOf<String>()

        override suspend fun fetchExtras(id: String): List<MediaItem> {
            fetched += id
            return extras
        }
    }

    private object FixedClock : Clock {
        override fun now(): Instant = Instant.parse("2026-01-01T00:00:00Z")
    }

    private companion object {
        val ITEM = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Catalog Movie", CatalogItemIds(tmdb = 1), overview = "Overview")

        /** A row whose bare form carries only its provider id; the detail body adds the external ids. */
        val BARE_ROW = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Row-only Movie", CatalogItemIds(trakt = 5))
        val ENRICHED_ROW = BARE_ROW.copy(ids = CatalogItemIds(trakt = 5, tmdb = 99))

        val TRAILER_ITEM = CatalogItem(
            CatalogSourceId.TRAKT,
            MediaKind.MOVIE,
            "Trailer Movie",
            CatalogItemIds(tmdb = 51),
            trailerUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        )

        fun lookup(
            items: List<MediaItem> = emptyList(),
            succeeded: Set<String> = emptySet(),
            failed: Set<String> = emptySet(),
            cancelled: Set<String> = emptySet(),
            unqueried: Set<String> = emptySet(),
        ) = LibraryLookupResult(
            items = items,
            succeededServerIds = succeeded.mapTo(mutableSetOf(), ::ServerId),
            cancelledServerIds = cancelled.mapTo(mutableSetOf(), ::ServerId),
            failedServerIds = failed.mapTo(mutableSetOf(), ::ServerId),
            unqueriedServerIds = unqueried.mapTo(mutableSetOf(), ::ServerId),
        )

        fun copy(id: String, libraryTitle: String? = null, resolution: String? = null, serverName: String? = "Living Room") = MediaItem(
            id = id,
            backend = BackendKind.PLEX,
            kind = MediaKind.MOVIE,
            title = "Catalog Movie",
            serverId = "server-1",
            serverName = serverName,
            libraryId = libraryTitle?.let { id },
            libraryTitle = libraryTitle,
            mediaVersions = resolution?.let { listOf(MediaVersion(id = "$id-v", videoResolution = it, videoCodec = "hevc", container = "mkv")) },
        )

        fun extra(id: String, type: String) = MediaItem(
            id = id,
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.MOVIE,
            serverId = "server-1",
            raw = buildJsonObject { put("ExtraType", type) },
        )
    }
}
