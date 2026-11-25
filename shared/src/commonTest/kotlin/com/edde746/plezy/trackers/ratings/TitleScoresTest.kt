package com.edde746.plezy.trackers.ratings

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.ResolvedIds
import com.edde746.plezy.trackers.TrackerIdResolver
import com.edde746.plezy.trackers.TrackerIdResolverFactory
import com.edde746.plezy.trackers.TrackerService
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A resolver that names an item by its server's external ids, plus [anime] while anime ids are wanted; it records
 * whether they were.
 */
private class ServerIdsResolver(private val backend: MediaBackend, private val needsAnimeIds: () -> Boolean, private val anime: AnimeIds?) :
    TrackerIdResolver {
    val animeWanted = mutableListOf<Boolean>()

    override suspend fun resolveForRating(item: MediaItem): RatingTarget {
        val wanted = needsAnimeIds()
        animeWanted += wanted
        val kind = if (item.kind == MediaKind.MOVIE) RatingKind.MOVIE else RatingKind.SHOW
        return RatingTarget(kind, backend.fetchExternalIds(item.id), anime?.takeIf { wanted })
    }

    override suspend fun resolveForMovie(movie: MediaItem): ResolvedIds? = error("not a rating")

    override suspend fun resolveForEpisode(episode: MediaItem, includeCurrentEpisode: Boolean): ResolvedIds? = error("not a rating")

    override fun clearCache() = Unit
}

/** Which trackers are asked about a library item (a detail page) or a catalog title (Explore), and with which ids. */
class TitleScoresTest {
    private val backend = FakeMediaBackend("s1").apply { externalIds = { ExternalIds(imdb = "tt1") } }
    private val resolvers = mutableListOf<ServerIdsResolver>()

    private fun factory(anime: AnimeIds? = null) = TrackerIdResolverFactory { backend, needsAnimeIds ->
        ServerIdsResolver(backend, needsAnimeIds, anime).also { resolvers += it }
    }

    private fun item(kind: MediaKind) = MediaItem(id = "item-1", backend = BackendKind.PLEX, kind = kind)

    private fun fetches() = backend.calls.count { it.startsWith("fetchExternalIds") }

    @Test
    fun aLibraryItemResolvesItsExternalIdsOnceForEveryTracker() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))
        val simkl = FakeRatingsSource(TrackerService.SIMKL, listOf(r("simkl", 8.4)))
        val mdblist = FakeRatingsSource(TrackerService.MDBLIST, listOf(r("imdb", 9.3)))

        val emissions = trackerRatings(listOf(trakt, simkl, mdblist), factory()).forLibraryItem("p1", item(MediaKind.MOVIE), backend).toList()

        assertEquals(1, fetches())
        for (source in listOf(trakt, simkl, mdblist)) assertEquals(listOf(RatingTitle(movie = true, TitleIds(imdb = "tt1"))), source.asked)
        assertEquals(listOf("imdb", "trakt", "simkl"), emissions.last().map { it.source })
    }

    @Test
    fun anEpisodeIsNotScoredTheTrackersScoreWholeTitles() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))

        val emissions = trackerRatings(listOf(trakt), factory()).forLibraryItem("p1", item(MediaKind.EPISODE), backend).toList()

        assertEquals(emptyList(), emissions)
        assertEquals(0, fetches())
        assertEquals(0, trakt.calls)
    }

    @Test
    fun aLibraryItemIsResolvedOnlyWhileATrackerIsConnected() = runTest {
        assertEquals(emptyList(), trackerRatings(emptyList(), factory()).forLibraryItem("p1", item(MediaKind.SHOW), backend).toList())
        assertEquals(0, fetches())
    }

    @Test
    fun animeListsAreAskedByTheMappedAnimeIdsAndNotAboutOtherTitles() = runTest {
        val mal = FakeRatingsSource(TrackerService.MYANIMELIST, listOf(r("mal", 8.6)), needsAnimeIds = true)
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))

        val anime = trackerRatings(listOf(mal, trakt), factory(AnimeIds(mal = 1535, anilist = 1535))).forLibraryItem("p1", item(MediaKind.SHOW), backend).toList()

        assertEquals(listOf(true), resolvers.single().animeWanted, "anime ids are looked up while MyAnimeList is connected")
        assertEquals(listOf(RatingTitle(movie = false, TitleIds(imdb = "tt1", mal = 1535, anilist = 1535))), mal.asked)
        assertEquals(listOf("trakt", "mal"), anime.last().map { it.source })

        val other = FakeRatingsSource(TrackerService.MYANIMELIST, listOf(r("mal", 8.6)), needsAnimeIds = true)
        trackerRatings(listOf(other), factory()).forLibraryItem("p1", item(MediaKind.SHOW), backend).toList()
        assertEquals(0, other.calls, "a title outside the anime lists isn't asked of them")
    }

    @Test
    fun withoutAnAnimeListConnectedNoAnimeIdsAreLookedUp() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))

        trackerRatings(listOf(trakt), factory(AnimeIds(mal = 1))).forLibraryItem("p1", item(MediaKind.MOVIE), backend).toList()

        assertEquals(listOf(false), resolvers.single().animeWanted)
    }

    @Test
    fun aLibraryItemWhoseIdsFailToResolveGetsNoScores() = runTest {
        backend.externalIds = { throw IllegalStateException("server unreachable") }
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))

        assertEquals(emptyList(), trackerRatings(listOf(trakt), factory()).forLibraryItem("p1", item(MediaKind.MOVIE), backend).toList())
        assertEquals(0, trakt.calls)
    }

    @Test
    fun aCatalogItemIsNotAskedOfItsOwnTrackerAndTheOthersCopyOfItsScoreIsDropped() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))
        val mdblist = FakeRatingsSource(TrackerService.MDBLIST, listOf(r("imdb", 9.3), r("trakt", 9.0)))

        val emissions = trackerRatings(listOf(trakt, mdblist))
            .forCatalogTitle("p1", MediaKind.MOVIE, TitleIds(trakt = 234, imdb = "tt0111161"), TrackerService.TRAKT)
            .toList()

        assertEquals(0, trakt.calls)
        assertEquals(listOf("imdb"), emissions.last().map { it.source })
    }

    @Test
    fun anMdblistItemIsAskedOfMdblistWhichHasNoScoreOfItsOwn() = runTest {
        val mdblist = FakeRatingsSource(TrackerService.MDBLIST, listOf(r("imdb", 9.3), r("trakt", 9.0)))

        val emissions = trackerRatings(listOf(mdblist))
            .forCatalogTitle("p1", MediaKind.MOVIE, TitleIds(imdb = "tt0111161"), TrackerService.MDBLIST)
            .toList()

        assertEquals(listOf("imdb", "trakt"), emissions.last().map { it.source })
    }

    @Test
    fun aTrackerThatCannotPlaceACatalogItemStillGetsTheItemsOwnIds() = runTest {
        // AniList rows carry MAL ids but no IMDb or TMDB id, so MyAnimeList's own lookup has nothing to go on.
        val mal = FakeRatingsSource(TrackerService.MYANIMELIST, listOf(r("mal", 8.6)), needsAnimeIds = true)
        val resolved = mutableListOf<TrackerService>()

        val emissions = trackerRatings(listOf(mal))
            .forCatalogTitle("p1", MediaKind.SHOW, TitleIds(anilist = 154587, mal = 52991), TrackerService.ANILIST) {
                resolved += it
                null
            }
            .toList()

        assertEquals(listOf(TrackerService.MYANIMELIST), resolved)
        assertEquals(52991, mal.asked.single().ids.mal)
        assertEquals(listOf("mal"), emissions.last().map { it.source })
    }

    @Test
    fun aCatalogTrackersOwnIdsAreMergedOverTheItems() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))

        trackerRatings(listOf(trakt))
            .forCatalogTitle("p1", MediaKind.SHOW, TitleIds(tmdb = 1396, mal = 1), TrackerService.MYANIMELIST) { TitleIds(trakt = 1388, tmdb = 9) }
            .toList()

        assertEquals(TitleIds(tmdb = 1396, trakt = 1388, mal = 1), trakt.asked.single().ids)
    }

    @Test
    fun onlyCatalogMoviesAndShowsAreScored() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))

        val emissions = trackerRatings(listOf(trakt)).forCatalogTitle("p1", MediaKind.SEASON, TitleIds(trakt = 1), null).toList()

        assertTrue(emissions.isEmpty())
        assertEquals(0, trakt.calls)
    }
}
