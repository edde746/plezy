package com.edde746.plezy.model

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MediaItemTest {
    private fun movie(
        id: String = "m1",
        title: String? = "Movie",
        year: Int? = null,
        viewCount: Int? = null,
        leafCount: Int? = null,
        viewedLeafCount: Int? = null,
        durationMs: Long? = null,
        viewOffsetMs: Long? = null,
        artPath: String? = null,
        backdropPaths: List<String>? = null,
        backgroundSquarePath: String? = null,
        backend: BackendKind = BackendKind.PLEX,
    ) = MediaItem(
        id = id,
        backend = backend,
        kind = MediaKind.MOVIE,
        title = title,
        year = year,
        viewCount = viewCount,
        leafCount = leafCount,
        viewedLeafCount = viewedLeafCount,
        durationMs = durationMs,
        viewOffsetMs = viewOffsetMs,
        artPath = artPath,
        backdropPaths = backdropPaths,
        backgroundSquarePath = backgroundSquarePath,
        serverId = "s1",
    )

    private fun item(kind: MediaKind, backend: BackendKind = BackendKind.PLEX, id: String = "item-1") =
        MediaItem(id = id, backend = backend, kind = kind)

    private val containerKinds = listOf(
        MediaKind.SHOW,
        MediaKind.SEASON,
        MediaKind.ARTIST,
        MediaKind.ALBUM,
        MediaKind.COLLECTION,
        MediaKind.PLAYLIST,
        MediaKind.FOLDER,
    )

    // Identity and keys

    @Test
    fun serverIdRejectsBlankAndTryParseReturnsNull() {
        assertFailsWith<IllegalArgumentException> { ServerId("") }
        assertFailsWith<IllegalArgumentException> { ServerId("   ") }
        assertNull(ServerId.tryParse(null))
        assertNull(ServerId.tryParse(" "))
        assertEquals(ServerId("abc"), ServerId.tryParse("abc"))
        assertEquals("abc", "${ServerId("abc")}")
    }

    @Test
    fun globalKeysSplitAtTheFirstColon() {
        assertEquals("srv:42", buildGlobalKey(ServerId("srv"), "42"))
        assertEquals(ServerId("srv") to "a:b", parseGlobalKey("srv:a:b"))
        assertNull(parseGlobalKey(":42"))
        assertNull(parseGlobalKey("no-colon"))
        assertEquals("p1|srv:42", buildProfileScopedKey("p1", ServerId("srv"), "42"))
    }

    @Test
    fun itemKeysUseTheServerIdWhenSet() {
        assertEquals("s1:m1", movie().globalKey)
        assertEquals("m1", movie().copy(serverId = null).globalKey)
        assertEquals("s1:lib", movie().copy(libraryId = "lib").libraryGlobalKey)
        assertNull(movie().libraryGlobalKey)
        assertNull(movie().copy(serverId = null, libraryId = "lib").libraryGlobalKey)
    }

    @Test
    fun seriesGlobalKeyFollowsEpisodesAndSeasonsOnly() {
        val episode = MediaItem(id = "e", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, parentId = "season", grandparentId = "show", serverId = "s1")
        assertEquals("s1:show", episode.seriesGlobalKey)
        assertEquals("show", episode.copy(serverId = null).seriesGlobalKey)
        val season = MediaItem(id = "sn", backend = BackendKind.PLEX, kind = MediaKind.SEASON, parentId = "show", serverId = "s1")
        assertEquals("s1:show", season.seriesGlobalKey)
        assertEquals("s1:gp", season.copy(grandparentId = "gp").seriesGlobalKey)
        assertNull(movie().copy(parentId = "p", grandparentId = "gp").seriesGlobalKey)
    }

    @Test
    fun parentChainDropsMissingAncestors() {
        assertEquals(listOf("season", "show"), item(MediaKind.EPISODE).copy(parentId = "season", grandparentId = "show").parentChain)
        assertEquals(listOf("show"), item(MediaKind.SEASON).copy(parentId = "show").parentChain)
        assertEquals(emptyList(), movie().parentChain)
    }

    // Kinds

    @Test
    fun mediaKindFromStringMapsBackendNames() {
        assertEquals(MediaKind.SHOW, MediaKind.fromString("Series"))
        assertEquals(MediaKind.ARTIST, MediaKind.fromString("MusicArtist"))
        assertEquals(MediaKind.ALBUM, MediaKind.fromString("MusicAlbum"))
        assertEquals(MediaKind.TRACK, MediaKind.fromString("Audio"))
        assertEquals(MediaKind.COLLECTION, MediaKind.fromString("BoxSet"))
        for (clip in listOf("Trailer", "Video", "MusicVideo")) assertEquals(MediaKind.CLIP, MediaKind.fromString(clip))
        assertEquals(MediaKind.FOLDER, MediaKind.fromString("CollectionFolder"))
        assertEquals(MediaKind.UNKNOWN, MediaKind.fromString(null))
        assertEquals(MediaKind.UNKNOWN, MediaKind.fromString("whatever"))
        for (kind in MediaKind.entries) assertEquals(kind, MediaKind.fromString(kind.id))
    }

    @Test
    fun mediaKindPredicates() {
        assertEquals(setOf(MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.CLIP), MediaKind.entries.filter { it.isVideo }.toSet())
        assertEquals(setOf(MediaKind.ARTIST, MediaKind.ALBUM, MediaKind.TRACK), MediaKind.entries.filter { it.isMusic }.toSet())
        assertEquals(setOf(MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.CLIP, MediaKind.TRACK), MediaKind.entries.filter { it.isPlayable }.toSet())
        assertEquals(setOf(MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.TRACK, MediaKind.CLIP), MediaKind.entries.filter { it.hasFileInfo }.toSet())
    }

    // isWatched

    @Test
    fun movieWithViewCountAboveZeroIsWatched() {
        assertTrue(movie(viewCount = 1).isWatched)
        assertTrue(movie(viewCount = 5).isWatched)
    }

    @Test
    fun movieWithViewCountZeroOrNullIsUnwatched() {
        assertFalse(movie(viewCount = 0).isWatched)
        assertFalse(movie(viewCount = null).isWatched)
    }

    @Test
    fun showWithAllLeavesWatchedIsWatched() {
        assertTrue(item(MediaKind.SHOW).copy(leafCount = 10, viewedLeafCount = 10).isWatched)
    }

    @Test
    fun showWithViewedLeafCountAboveLeafCountIsStillWatched() {
        val show = item(MediaKind.SHOW).copy(leafCount = 10, viewedLeafCount = 11)
        assertTrue(show.isWatched)
        assertEquals(0, show.unwatchedCount)
    }

    @Test
    fun showWithNoLeafInfoFallsBackToViewCount() {
        assertTrue(item(MediaKind.SHOW).copy(viewCount = 1).isWatched)
    }

    @Test
    fun leafMediaIgnoresAggregateLeafCounts() {
        assertFalse(movie(viewCount = 0, leafCount = 1, viewedLeafCount = 1).isWatched)
        assertTrue(movie(viewCount = 1, leafCount = 1, viewedLeafCount = 0).isWatched)
    }

    @Test
    fun containerMediaUsesAggregateLeafCounts() {
        assertTrue(item(MediaKind.ALBUM).copy(viewCount = 0, leafCount = 8, viewedLeafCount = 8).isWatched)
    }

    @Test
    fun everyMediaKindHasExplicitLeafOrContainerWatchSemantics() {
        assertEquals(containerKinds, MediaKind.entries.filter { it.usesLeafWatchCounts })
        for (kind in MediaKind.entries) {
            val item = MediaItem(id = kind.id, backend = BackendKind.PLEX, kind = kind, viewCount = 0, leafCount = 2, viewedLeafCount = 2, serverId = "s1")
            val usesLeaves = kind in containerKinds
            assertEquals(usesLeaves, item.isWatched, "${kind.id} watched semantics")
            assertFalse(item.isPartiallyWatched, "${kind.id} partial semantics")
            assertEquals(if (usesLeaves) 0 else null, item.unwatchedCount, "${kind.id} unwatched count semantics")
        }
    }

    @Test
    fun zeroContainerLeafTotalFallsBackToViewCount() {
        assertTrue(item(MediaKind.SHOW).copy(viewCount = 1, leafCount = 0, viewedLeafCount = 0).isWatched)
    }

    @Test
    fun showsNeverFallBackToChildCount() {
        val show = item(MediaKind.SHOW).copy(childCount = 3, viewedLeafCount = 3)
        assertNull(show.leafWatchTotal)
        assertNull(show.leafWatchFraction)
    }

    // heroArtCandidates

    @Test
    fun nearSquareContainersPreferSquareArtBeforeWideCoverArt() {
        assertEquals(listOf("/square", "/art"), movie(artPath = "/art", backgroundSquarePath = "/square").heroArtCandidates(1.0))
    }

    @Test
    fun nearSquareContainersFallBackToWideCoverArtWhenSquareArtIsMissing() {
        assertEquals(listOf("/art"), movie(artPath = "/art").heroArtCandidates(1.0))
    }

    @Test
    fun wideContainersPreferWideCoverArtBeforeSquareArt() {
        assertEquals(listOf("/art", "/square"), movie(artPath = "/art", backgroundSquarePath = "/square").heroArtCandidates(16.0 / 9))
    }

    @Test
    fun episodesPreferShowArtBeforeEpisodeArtForWideHeroContainers() {
        val episode = MediaItem(
            id = "e1",
            backend = BackendKind.PLEX,
            kind = MediaKind.EPISODE,
            title = "Episode",
            grandparentTitle = "Show",
            grandparentArtPath = "/show-art",
            artPath = "/episode-art",
            backgroundSquarePath = "/square",
            serverId = "s1",
        )
        assertEquals(listOf("/show-art", "/episode-art", "/square"), episode.heroArtCandidates(16.0 / 9))
        assertEquals(listOf("/square", "/show-art", "/episode-art"), episode.heroArtCandidates(1.0))
    }

    @Test
    fun jellyfinMoviesExposeEveryBackdropInDisplayOrder() {
        val movie = movie(
            backend = BackendKind.JELLYFIN,
            artPath = "/art-0",
            backdropPaths = listOf("/art-0", "/art-1", "/art-2"),
            backgroundSquarePath = "/square",
        )
        assertEquals(listOf("/art-0", "/art-1", "/art-2"), movie.heroBackdropPaths)
        assertEquals(listOf("/art-0", "/art-1", "/art-2", "/square"), movie.heroArtCandidates(16.0 / 9))
    }

    @Test
    fun episodesPreferInheritedBackdropsOverTheirOwnArt() {
        val episode = MediaItem(
            id = "e-multi",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.EPISODE,
            artPath = "/episode-0",
            backdropPaths = listOf("/episode-0", "/episode-1"),
            grandparentArtPath = "/show-0",
            grandparentBackdropPaths = listOf("/show-0", "/show-1", "/show-2"),
        )
        assertEquals(listOf("/show-0", "/show-1", "/show-2"), episode.heroBackdropPaths)
        assertEquals(listOf("/show-0", "/show-1", "/show-2", "/episode-0", "/episode-1"), episode.heroArtCandidates(16.0 / 9))
    }

    @Test
    fun seasonsWithoutBackdropsOfTheirOwnFallBackToInheritedSeriesBackdrops() {
        val season = MediaItem(
            id = "s-inherited",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.SEASON,
            grandparentArtPath = "/show-0",
            grandparentBackdropPaths = listOf("/show-0", "/show-1"),
            backgroundSquarePath = "/square",
        )
        assertEquals(listOf("/show-0", "/show-1"), season.heroBackdropPaths)
        assertEquals(listOf("/show-0", "/show-1", "/square"), season.heroArtCandidates(16.0 / 9))
    }

    @Test
    fun nonEpisodesKeepTheirOwnBackdropsAheadOfInheritedOnes() {
        val season = MediaItem(
            id = "s-own",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.SEASON,
            artPath = "/season-0",
            backdropPaths = listOf("/season-0", "/season-1"),
            grandparentArtPath = "/show-0",
            grandparentBackdropPaths = listOf("/show-0"),
            backgroundSquarePath = "/square",
        )
        assertEquals(listOf("/season-0", "/season-1"), season.heroBackdropPaths)
        assertEquals(listOf("/season-0", "/season-1", "/show-0", "/square"), season.heroArtCandidates(16.0 / 9))
        assertEquals(listOf("/square", "/season-0", "/season-1", "/show-0"), season.heroArtCandidates(1.0))
    }

    @Test
    fun legacyScalarArtRemainsASingleStaticBackdrop() {
        val movie = movie(artPath = "/legacy-art")
        assertEquals(listOf("/legacy-art"), movie.resolvedBackdropPaths)
        assertEquals(listOf("/legacy-art"), movie.heroBackdropPaths)
    }

    @Test
    fun resolvedBackdropsIgnoreEmptyValues() {
        assertEquals(emptyList(), movie(artPath = "", backdropPaths = emptyList()).resolvedBackdropPaths)
        assertEquals(listOf("/gp"), item(MediaKind.EPISODE).copy(grandparentArtPath = "/gp", grandparentBackdropPaths = emptyList()).resolvedGrandparentBackdropPaths)
    }

    // heroRotationPaths

    private fun displayOrder(item: MediaItem, aspect: Double): List<String> {
        val rotation = item.heroRotationPaths(aspect)
        val candidates = item.heroArtCandidates(aspect)
        return rotation + candidates.filter { it !in rotation }
    }

    @Test
    fun nearSquareContainersHoldOnSquareArtInsteadOfRotatingBackdrops() {
        val movie = movie(backend = BackendKind.JELLYFIN, artPath = "/art-0", backdropPaths = listOf("/art-0", "/art-1"), backgroundSquarePath = "/square")
        assertEquals(listOf("/square"), movie.heroRotationPaths(1.0))
    }

    @Test
    fun nearSquareContainersRotateBackdropsWhenThereIsNoSquareArt() {
        val movie = movie(backend = BackendKind.JELLYFIN, artPath = "/art-0", backdropPaths = listOf("/art-0", "/art-1"))
        assertEquals(listOf("/art-0", "/art-1"), movie.heroRotationPaths(1.0))
    }

    @Test
    fun wideContainersRotateBackdropsAndLeaveSquareArtBehindThem() {
        val movie = movie(backend = BackendKind.JELLYFIN, artPath = "/art-0", backdropPaths = listOf("/art-0", "/art-1"), backgroundSquarePath = "/square")
        assertEquals(listOf("/art-0", "/art-1"), movie.heroRotationPaths(16.0 / 9))
    }

    @Test
    fun rotationBeforeFallbackReproducesTheCandidateOrderAtEveryAspect() {
        val episode = MediaItem(
            id = "e-order",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.EPISODE,
            artPath = "/episode-0",
            backdropPaths = listOf("/episode-0", "/episode-1"),
            grandparentArtPath = "/show-0",
            grandparentBackdropPaths = listOf("/show-0", "/show-1"),
            backgroundSquarePath = "/square",
            serverId = "s1",
        )
        val seasonWithOwn = episode.copy(id = "s-order", kind = MediaKind.SEASON, artPath = "/season-0", backdropPaths = listOf("/season-0", "/season-1"))
        val seasonInheriting = seasonWithOwn.copy(artPath = null, backdropPaths = null)

        for (item in listOf(episode, seasonWithOwn, seasonInheriting)) {
            for (aspect in listOf(0.75, 1.0, 1.38, 1.39, 16.0 / 9, 2.4)) {
                assertEquals(item.heroArtCandidates(aspect), displayOrder(item, aspect), "${item.id} (${item.resolvedBackdropPaths.size} own) at aspect $aspect")
            }
        }
    }

    // isPartiallyWatched

    @Test
    fun showWithSomeLeavesWatchedIsPartiallyWatched() {
        assertTrue(item(MediaKind.SHOW).copy(leafCount = 10, viewedLeafCount = 3).isPartiallyWatched)
    }

    @Test
    fun seasonProgressUsesDirectEpisodeCountOnlyWhenTheLeafTotalIsAbsent() {
        val season = item(MediaKind.SEASON, BackendKind.JELLYFIN, "season").copy(childCount = 8, viewedLeafCount = 3)
        assertEquals(8, season.leafWatchTotal)
        assertEquals(3.0 / 8, season.leafWatchFraction)
        assertTrue(season.isPartiallyWatched)
        assertEquals(10, season.copy(leafCount = 10).leafWatchTotal)
    }

    @Test
    fun showWithZeroLeavesWatchedIsNotPartiallyWatched() {
        assertFalse(item(MediaKind.SHOW).copy(leafCount = 10, viewedLeafCount = 0).isPartiallyWatched)
    }

    @Test
    fun showWithAllLeavesWatchedIsNotPartiallyWatched() {
        assertFalse(item(MediaKind.SHOW).copy(leafCount = 10, viewedLeafCount = 10).isPartiallyWatched)
    }

    @Test
    fun aggregateProgressClampsContradictoryCounts() {
        val overReported = item(MediaKind.SHOW, id = "show").copy(leafCount = 10, viewedLeafCount = 11)
        val negative = overReported.copy(viewedLeafCount = -1)
        assertEquals(1.0, overReported.leafWatchFraction)
        assertEquals(0.0, negative.leafWatchFraction)
    }

    @Test
    fun movieWithoutLeafInfoIsNotPartiallyWatched() {
        assertFalse(movie(viewCount = 0).isPartiallyWatched)
        assertFalse(movie(viewCount = 1).isPartiallyWatched)
    }

    // Watch-state normalization

    @Test
    fun leafStateIgnoresAndClearsStaleAggregateFields() {
        val movie = MediaItem(
            id = "m",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.MOVIE,
            viewCount = 0,
            leafCount = 3,
            viewedLeafCount = 3,
            raw = buildJsonObject { putJsonObject("UserData") { put("UnplayedItemCount", "0") } },
        )
        assertFalse(movie.isWatched)
        assertFalse(movie.isPartiallyWatched)
        assertNull(movie.unwatchedCount)
        assertNull(movie.withWatchedFlag(false).viewedLeafCount)
        assertTrue(movie.withWatchedFlag(true).isWatched)
    }

    @Test
    fun containerMutationsUpdateTheAggregateAndItemFlagsTogether() {
        val album = item(MediaKind.ALBUM, id = "a").copy(viewCount = 0, leafCount = 8, viewedLeafCount = 3)

        val watched = album.withWatchedFlag(true)
        assertEquals(1, watched.viewCount)
        assertEquals(8, watched.viewedLeafCount)
        assertTrue(watched.isWatched)

        val unwatched = watched.withWatchedFlag(false)
        assertEquals(0, unwatched.viewCount)
        assertEquals(0, unwatched.viewedLeafCount)
        assertFalse(unwatched.isWatched)
    }

    @Test
    fun containersWithoutLeafTotalKeepTheirViewedLeafCount() {
        val collection = item(MediaKind.COLLECTION).copy(viewedLeafCount = 2)
        assertEquals(2, collection.withWatchedFlag(true).viewedLeafCount)
        assertTrue(collection.withWatchedFlag(true).isWatched)
    }

    @Test
    fun containerUnwatchedCountsAreClampedAndTolerateStringApiValues() {
        val overReported = item(MediaKind.SHOW, id = "s1").copy(leafCount = 10, viewedLeafCount = 11)
        val slimJellyfin = item(MediaKind.SHOW, BackendKind.JELLYFIN, "s2").copy(
            raw = buildJsonObject { putJsonObject("UserData") { put("UnplayedItemCount", "4") } },
        )
        assertEquals(0, overReported.unwatchedCount)
        assertEquals(4, slimJellyfin.unwatchedCount)
        assertEquals(3, item(MediaKind.SHOW).copy(leafCount = 10, viewedLeafCount = 7).unwatchedCount)
    }

    // Progress and recency

    @Test
    fun viewOffsetBetweenZeroAndDurationCountsAsActiveProgress() {
        assertTrue(movie(durationMs = 10000, viewOffsetMs = 5000).hasActiveProgress)
    }

    @Test
    fun viewOffsetZeroIsNotActiveProgress() {
        assertFalse(movie(durationMs = 10000, viewOffsetMs = 0).hasActiveProgress)
    }

    @Test
    fun viewOffsetAtOrPastDurationIsNotActiveProgress() {
        assertFalse(movie(durationMs = 10000, viewOffsetMs = 10000).hasActiveProgress)
        assertFalse(movie(durationMs = 10000, viewOffsetMs = 99999).hasActiveProgress)
    }

    @Test
    fun nullDurationOrViewOffsetDisablesTheCheck() {
        assertFalse(movie(durationMs = null, viewOffsetMs = 5000).hasActiveProgress)
        assertFalse(movie(durationMs = 10000, viewOffsetMs = null).hasActiveProgress)
    }

    @Test
    fun watchedButResumableCountsAsUnwatchedOrInProgress() {
        assertTrue(movie(viewCount = 0).isUnwatchedOrInProgress)
        assertFalse(movie(viewCount = 1).isUnwatchedOrInProgress)
        assertTrue(movie(viewCount = 1, durationMs = 10000, viewOffsetMs = 5000).isUnwatchedOrInProgress)
    }

    @Test
    fun recencySortKeyPrefersLastViewedThenAdded() {
        assertEquals(20L, movie().copy(lastViewedAt = 20, addedAt = 10).recencySortKey)
        assertEquals(10L, movie().copy(addedAt = 10).recencySortKey)
        assertEquals(0L, movie().recencySortKey)
    }

    // copy

    @Test
    fun copyOverridesOnlyTheNamedFields() {
        val copy = movie(title = "Old", viewCount = 0).copy(title = "New", viewCount = 3)
        assertEquals("New", copy.title)
        assertEquals(3, copy.viewCount)
        assertEquals("m1", copy.id)
    }

    @Test
    fun copyPreservesPlexOnlyFieldsWhenOmitted() {
        val original = MediaItem(
            id = "p1",
            backend = BackendKind.PLEX,
            kind = MediaKind.MOVIE,
            title = "Old",
            editionTitle = "Director Cut",
            ratings = listOf(MediaRatingSource("rottenTomatoesCritic", 9.4), MediaRatingSource("imdb", 8.9, 1200)),
            trailerKey = "/library/metadata/1",
            playlistItemId = "42",
            playQueueItemId = 7,
        )
        val copy = original.copy(title = "New")
        assertEquals("New", copy.title)
        assertEquals("Director Cut", copy.editionTitle)
        assertEquals(listOf("rottenTomatoesCritic", "imdb"), copy.ratings?.map { it.source })
        assertEquals(1200, copy.ratings?.last()?.votes)
        assertEquals("/library/metadata/1", copy.trailerKey)
        assertEquals("42", copy.playlistItemId)
        assertEquals(7, copy.playQueueItemId)
    }

    @Test
    fun copyCanClearNullableFieldsExplicitly() {
        val copy = movie(title = "Movie", viewCount = 1, durationMs = 1000, viewOffsetMs = 500).copy(title = null, viewOffsetMs = null)
        assertNull(copy.title)
        assertNull(copy.viewOffsetMs)
        assertEquals(1, copy.viewCount)
    }

    // JSON

    @Test
    fun jsonRoundTripsPlexOnlyFields() {
        val original = MediaItem(
            id = "p1",
            backend = BackendKind.PLEX,
            kind = MediaKind.MOVIE,
            title = "Movie",
            editionTitle = "Theatrical",
            ratings = listOf(MediaRatingSource("rottenTomatoesCritic", 9.1), MediaRatingSource("imdb", 8.4, 250858)),
            genres = listOf("Drama"),
            roles = listOf(MediaRole(id = "1", tag = "Actor", role = "Lead", thumbPath = "/photo")),
            mediaVersions = listOf(
                MediaVersion(id = "v1", width = 1920, height = 1080, parts = listOf(MediaPart(id = "part1", streamPath = "/stream", sizeBytes = 1000))),
            ),
            trailerKey = "/trailer",
            playlistItemId = "4",
            playQueueItemId = 5,
        )

        val json = original.toJson()
        val decoded = MediaItem.fromJson(json)

        assertEquals("plex", json["backend"]?.jsonPrimitive?.content)
        assertFalse(json.containsKey("summary"))
        assertEquals(JsonPrimitive(4L), json["playlistItemId"])
        assertEquals(BackendKind.PLEX, decoded.backend)
        assertEquals("Theatrical", decoded.editionTitle)
        assertEquals(listOf("rottenTomatoesCritic", "imdb"), decoded.ratings?.map { it.source })
        assertEquals(9.1, decoded.ratings?.first()?.value)
        assertEquals(250858, decoded.ratings?.last()?.votes)
        assertEquals(listOf("Drama"), decoded.genres)
        assertEquals("Actor", decoded.roles?.single()?.tag)
        assertEquals("/stream", decoded.mediaVersions?.single()?.parts?.single()?.streamPath)
        assertEquals("/trailer", decoded.trailerKey)
        assertEquals("4", decoded.playlistItemId)
        assertEquals(5, decoded.playQueueItemId)
        assertEquals(original, decoded)
    }

    @Test
    fun jsonRoundTripsJellyfinPlaylistItemId() {
        val original = MediaItem(id = "j1", backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = "Movie", playlistItemId = "entry-1")
        val json = original.toJson()
        val decoded = MediaItem.fromJson(json)
        assertEquals("jellyfin", json["backend"]?.jsonPrimitive?.content)
        assertEquals(JsonPrimitive("entry-1"), json["playlistItemId"])
        assertEquals(BackendKind.JELLYFIN, decoded.backend)
        assertEquals("entry-1", decoded.playlistItemId)
    }

    @Test
    fun jellyfinJsonOmitsPlexOnlyKeys() {
        val json = MediaItem(
            id = "j1",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.MOVIE,
            editionTitle = "E",
            trailerKey = "/t",
            playQueueItemId = 3,
            subtype = "clip",
        ).toJson()
        for (key in listOf("editionTitle", "trailerKey", "playQueueItemId", "subtype")) assertFalse(json.containsKey(key), key)
    }

    @Test
    fun jsonRoundTripsJellyfinBackdropLists() {
        val original = MediaItem(
            id = "j-backdrops",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.EPISODE,
            artPath = "/episode-0",
            backdropPaths = listOf("/episode-0", "/episode-1"),
            grandparentArtPath = "/show-0",
            grandparentBackdropPaths = listOf("/show-0", "/show-1"),
        )
        val decoded = MediaItem.fromJson(original.toJson())
        assertEquals(listOf("/episode-0", "/episode-1"), decoded.backdropPaths)
        assertEquals(listOf("/show-0", "/show-1"), decoded.grandparentBackdropPaths)
        assertEquals(listOf("/show-0", "/show-1"), decoded.heroBackdropPaths)
    }

    @Test
    fun cachedLeafItemsIgnoreStaleAggregateWatchFields() {
        val original = MediaItem(
            id = "cached-music-video",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.CLIP,
            viewCount = 0,
            leafCount = 1,
            viewedLeafCount = 1,
            raw = buildJsonObject { putJsonObject("UserData") { put("UnplayedItemCount", 0) } },
        )
        val decoded = MediaItem.fromJson(original.toJson())
        assertEquals(1, decoded.viewedLeafCount)
        assertFalse(decoded.isWatched)
        assertFalse(decoded.isPartiallyWatched)
        assertNull(decoded.unwatchedCount)
        assertEquals(original.raw, decoded.raw)
    }

    @Test
    fun missingBackendKeepsLegacyPlexFallback() {
        val decoded = MediaItem.fromJson(buildJsonObject { put("id", "legacy"); put("kind", "movie") })
        assertEquals(BackendKind.PLEX, decoded.backend)
        assertEquals("legacy", decoded.id)
        assertEquals(MediaKind.MOVIE, decoded.kind)
        assertEquals(BackendKind.PLEX, MediaItem.fromJson(buildJsonObject { put("backend", "kodi") }).backend)
    }

    @Test
    fun anEmbyItemPersistsItsOwnBackendIdAndRestoresTheDialect() {
        val original = MediaItem(id = "7330", backend = BackendKind.EMBY, kind = MediaKind.MOVIE, title = "Movie 001", playlistItemId = "entry-1")
        val json = original.toJson()
        val decoded = MediaItem.fromJson(json)
        assertEquals("emby", json["backend"]?.jsonPrimitive?.content)
        assertFalse(json.containsKey("dialect"))
        assertEquals(BackendKind.EMBY, decoded.backend)
        assertEquals(MediaBrowserDialect.EMBY, decoded.dialect)
        assertEquals("entry-1", decoded.playlistItemId)
        assertEquals("7330", decoded.id)
    }

    @Test
    fun bothMediaBrowserBackendsCarryTheirDialect() {
        assertEquals(MediaBrowserDialect.EMBY, item(MediaKind.MOVIE, BackendKind.EMBY).dialect)
        assertEquals(MediaBrowserDialect.JELLYFIN, item(MediaKind.MOVIE, BackendKind.JELLYFIN).dialect)
        assertNull(item(MediaKind.MOVIE).dialect)
    }

    @Test
    fun jsonReadsLenientlyTypedValues() {
        val decoded = MediaItem.fromJson(
            buildJsonObject {
                put("backend", "plex")
                put("id", 123)
                put("kind", "episode")
                put("year", "2001")
                put("durationMs", 4.5e9)
                put("rating", "7.5")
                put("playlistItemId", "9")
                put("genres", JsonArray(listOf(JsonPrimitive("Drama"), JsonPrimitive(7))))
            },
        )
        assertEquals("123", decoded.id)
        assertEquals(2001, decoded.year)
        assertEquals(4_500_000_000L, decoded.durationMs)
        assertEquals(7.5, decoded.rating)
        assertEquals("9", decoded.playlistItemId)
        assertEquals(listOf("Drama", "7"), decoded.genres)
        assertEquals("", MediaItem.fromJson(JsonObject(emptyMap())).id)
        assertEquals(MediaKind.UNKNOWN, MediaItem.fromJson(JsonObject(emptyMap())).kind)
    }

    @Test
    fun versionJsonWritesPartsWithoutStreams() {
        val version = MediaVersion(
            id = "v",
            parts = listOf(MediaPart(id = "p", streams = listOf(MediaStream(id = "s", kind = MediaStreamKind.AUDIO)), accessible = false)),
        )
        val json = version.toJson()
        val part = (json["parts"] as JsonArray).single() as JsonObject
        assertFalse(part.containsKey("streams"))
        assertEquals(emptyList(), MediaVersion.fromJson(json).parts.single().streams)
        assertEquals(false, MediaVersion.fromJson(json).parts.single().accessible)
        assertEquals(emptyList(), MediaVersion.fromJson(buildJsonObject { put("id", 5) }).parts)
        assertEquals("5", MediaVersion.fromJson(buildJsonObject { put("id", 5) }).id)
    }

    // Home videos

    private val homeVideo = MediaItem(id = "hv1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, subtype = "clip", thumbPath = "/thumb", artPath = "/art")

    @Test
    fun movieWithSubtypeClipRendersWideInEveryEpisodePosterMode() {
        for (mode in EpisodePosterMode.entries) {
            assertTrue(homeVideo.usesWideAspectRatio(mode), mode.name)
            assertEquals(CardShape.WIDE, homeVideo.cardShape(mode), mode.name)
        }
    }

    @Test
    fun posterThumbPrefersTheGeneratedVideoFrameThumbOverArtEvenInMixedHubs() {
        assertEquals("/thumb", homeVideo.posterThumb())
        assertEquals("/thumb", homeVideo.posterThumb(EpisodePosterMode.EPISODE_THUMBNAIL, mixedHubContext = true))
    }

    @Test
    fun otherPlexSubtypesDoNotWidenAMovie() {
        val trailer = MediaItem(id = "t1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, subtype = "trailer", thumbPath = "/thumb")
        assertFalse(trailer.usesWideAspectRatio(EpisodePosterMode.SERIES_POSTER))
        assertEquals(CardShape.POSTER, trailer.cardShape(EpisodePosterMode.SERIES_POSTER))
    }

    // Poster selection

    private val episode = MediaItem(
        id = "e",
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        thumbPath = "/ep",
        parentThumbPath = "/season",
        grandparentThumbPath = "/show",
    )

    @Test
    fun episodePosterFollowsTheMode() {
        assertEquals("/show", episode.posterThumb())
        assertEquals("/season", episode.posterThumb(EpisodePosterMode.SEASON_POSTER))
        assertEquals("/ep", episode.posterThumb(EpisodePosterMode.EPISODE_THUMBNAIL))
        assertEquals("/show", episode.copy(parentThumbPath = null).posterThumb(EpisodePosterMode.SEASON_POSTER))
        assertEquals("/ep", episode.copy(grandparentThumbPath = null).posterThumb())
    }

    @Test
    fun seasonAndMixedHubPosters() {
        val season = MediaItem(id = "s", backend = BackendKind.PLEX, kind = MediaKind.SEASON, thumbPath = "/thumb", artPath = "/art", grandparentThumbPath = "/show")
        assertEquals("/art", season.posterThumb(EpisodePosterMode.EPISODE_THUMBNAIL, mixedHubContext = true))
        assertEquals("/show", season.posterThumb())
        assertEquals("/thumb", season.copy(grandparentThumbPath = null).posterThumb())
        val movie = movie(artPath = "/art").copy(thumbPath = "/poster")
        assertEquals("/art", movie.posterThumb(EpisodePosterMode.EPISODE_THUMBNAIL, mixedHubContext = true))
        assertEquals("/poster", movie.posterThumb(EpisodePosterMode.EPISODE_THUMBNAIL))
        val clip = MediaItem(id = "c", backend = BackendKind.JELLYFIN, kind = MediaKind.CLIP, artPath = "/art")
        assertEquals("/art", clip.posterThumb())
    }

    @Test
    fun posterFallbacks() {
        val track = MediaItem(id = "t", backend = BackendKind.PLEX, kind = MediaKind.TRACK, thumbPath = "/track", parentThumbPath = "/album")
        assertEquals("/album", track.posterThumbFallback())
        assertNull(track.copy(thumbPath = "/album").posterThumbFallback())
        assertEquals("/show", episode.posterThumbFallback(EpisodePosterMode.SEASON_POSTER))
        assertNull(episode.copy(parentThumbPath = null).posterThumbFallback(EpisodePosterMode.SEASON_POSTER))
        assertNull(episode.posterThumbFallback())
        assertNull(movie().posterThumbFallback())
    }

    @Test
    fun cardShapes() {
        assertEquals(CardShape.WIDE, episode.cardShape(EpisodePosterMode.EPISODE_THUMBNAIL))
        assertEquals(CardShape.POSTER, episode.cardShape(EpisodePosterMode.SERIES_POSTER))
        assertEquals(CardShape.SQUARE, item(MediaKind.ARTIST).cardShape(EpisodePosterMode.EPISODE_THUMBNAIL, mixedHubContext = true))
        assertTrue(item(MediaKind.SEASON).usesWideAspectRatio(EpisodePosterMode.EPISODE_THUMBNAIL, mixedHubContext = true))
        assertFalse(item(MediaKind.SEASON).usesWideAspectRatio(EpisodePosterMode.EPISODE_THUMBNAIL))
        assertTrue(item(MediaKind.CLIP).usesWideAspectRatio(EpisodePosterMode.SERIES_POSTER))
    }

    // Titles

    @Test
    fun episodePrefersGrandparentShowTitle() {
        val ep = MediaItem(id = "e1", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, title = "Pilot", grandparentTitle = "Breaking Bad", parentTitle = "Season 1", serverId = "s1")
        assertEquals("Breaking Bad", ep.displayTitle)
        assertEquals("Pilot", ep.displaySubtitle)
    }

    @Test
    fun seasonPrefersGrandparentOverParent() {
        val season = MediaItem(id = "sn1", backend = BackendKind.PLEX, kind = MediaKind.SEASON, title = "Season 1", grandparentTitle = "Breaking Bad", serverId = "s1")
        assertEquals("Breaking Bad", season.displayTitle)
        val plexSeason = season.copy(grandparentTitle = null, parentTitle = "Show")
        assertEquals("Show", plexSeason.displayTitle)
        assertEquals("Season 1", plexSeason.displaySubtitle)
    }

    @Test
    fun movieReturnsItsOwnTitleWithNoSubtitle() {
        val movie = movie(title = "Inception")
        assertEquals("Inception", movie.displayTitle)
        assertNull(movie.displaySubtitle)
    }

    @Test
    fun nullTitleDegradesToEmptyString() {
        assertEquals("", movie(title = null).displayTitle)
    }

    // Music

    @Test
    fun albumYearIsExposedOnlyForTracksAndAlbums() {
        val track = MediaItem(id = "item-1", backend = BackendKind.PLEX, kind = MediaKind.TRACK, parentTitle = "Album", year = 2001)
        val album = MediaItem(id = "item-1", backend = BackendKind.PLEX, kind = MediaKind.ALBUM, title = "Album", year = 2001)
        assertEquals("Album", track.albumTitle)
        assertEquals(2001, track.albumYear)
        assertEquals(2001, album.albumYear)
        assertNull(movie(year = 2001).albumYear)
    }

    @Test
    fun trackMetadataGetters() {
        val track = MediaItem(id = "t", backend = BackendKind.PLEX, kind = MediaKind.TRACK, index = 3, parentIndex = 2, grandparentTitle = "Band")
        assertEquals(3, track.trackNumber)
        assertEquals(2, track.discNumber)
        assertEquals("Band", track.albumArtistTitle)
        assertEquals("Band", track.trackArtistTitle)
        assertEquals("Guest", track.copy(originalTitle = "Guest").trackArtistTitle)
        val album = MediaItem(id = "a", backend = BackendKind.PLEX, kind = MediaKind.ALBUM, index = 3, parentTitle = "Band")
        assertEquals("Band", album.albumArtistTitle)
        assertNull(album.trackNumber)
        assertNull(album.trackArtistTitle)
    }

    // Shared files

    private fun withFiles(id: String, vararg parts: Pair<String, String?>, serverId: String = "s1") = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        serverId = serverId,
        mediaVersions = listOf(MediaVersion(id = "v", parts = parts.map { (partId, file) -> MediaPart(id = partId, file = file) })),
    )

    @Test
    fun multiEpisodeFilesAreMatchedByPath() {
        val e24 = withFiles("24", "p24" to "/S02E24-E25.mkv")
        val e25 = withFiles("25", "p25" to "/S02E24-E25.mkv")
        assertEquals(setOf("/S02E24-E25.mkv"), e24.allPartFiles)
        assertTrue(e24.sharesFileWith(e25))
        assertTrue(e24.sharesFileWith(e25, playedPartId = "p24"))
        assertFalse(e24.sharesFileWith(withFiles("25", "p25" to "/S02E24-E25.mkv", serverId = "s2")))
        assertFalse(e24.sharesFileWith(withFiles("x", "px" to "")))
        assertFalse(e24.sharesFileWith(withFiles("26", "p26" to "/S02E26.mkv")))
    }

    @Test
    fun playedPartRestrictsTheComparisonToItsFile() {
        val stacked = withFiles("m", "a" to "/cd1.mkv", "b" to "/cd2.mkv")
        val other = withFiles("o", "c" to "/cd2.mkv")
        assertTrue(stacked.sharesFileWith(other))
        assertFalse(stacked.sharesFileWith(other, playedPartId = "a"))
        assertTrue(stacked.sharesFileWith(other, playedPartId = "unknown"))
    }
}
