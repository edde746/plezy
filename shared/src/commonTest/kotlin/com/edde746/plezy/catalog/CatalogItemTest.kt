package com.edde746.plezy.catalog

import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.model.isCatalogItem
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put

class CatalogItemTest {
    private val allIds = CatalogItemIds(
        plex = "plex-4",
        trakt = 8,
        slug = "title",
        mal = 5,
        anilist = 6,
        simkl = 7,
        imdb = "tt123",
        tmdb = 2,
        tvdb = 3,
    )

    private val item = CatalogItem(
        source = CatalogSourceId.ANILIST,
        kind = MediaKind.SHOW,
        title = "You and I Are Polar Opposites Season 2",
        altTitles = listOf("Seihantai na Kimi to Boku 2nd Season", "\u6b63\u53cd\u5bfe\u306a\u541b\u3068\u50d5 \u7b2c2\u671f"),
        season = ExternalSeasonRef(tvdb = 2, tmdb = 1),
        year = 2026,
        ids = CatalogItemIds(anilist = 210031, mal = 63832, tvdb = 457078),
    )

    @Test
    fun providerNativeIdsRoundTripThroughJson() {
        val json = allIds.toJson()

        assertEquals(
            buildJsonObject {
                put("plex", "plex-4")
                put("trakt", 8)
                put("slug", "title")
                put("mal", 5)
                put("anilist", 6)
                put("simkl", 7)
                put("imdb", "tt123")
                put("tmdb", 2)
                put("tvdb", 3)
            },
            json,
        )
        val decoded = CatalogItemIds.fromJson(json)
        assertEquals(allIds, decoded)
        assertTrue(decoded.hasAny)
    }

    @Test
    fun canonicalAndMembershipKeysAreOrderedDeterministically() {
        assertEquals("imdb:tt123", allIds.canonicalKey)
        assertEquals(
            listOf("imdb:tt123", "tmdb:2", "tvdb:3", "mal:5", "anilist:6", "simkl:7", "plex:plex-4", "trakt:8", "slug:title"),
            allIds.allKeys,
        )
        assertEquals("mal:5", CatalogItemIds(mal = 5, anilist = 6, simkl = 7).canonicalKey)
        assertEquals("anilist:6", CatalogItemIds(anilist = 6, simkl = 7).canonicalKey)
        assertEquals("simkl:7", CatalogItemIds(simkl = 7, trakt = 8).canonicalKey)
        assertEquals("plex:plex-4", CatalogItemIds(plex = "plex-4", trakt = 8).canonicalKey)
    }

    @Test
    fun entryKeyIdentifiesTheEntryNotTheSeriesItSharesWithItsSeasons() {
        // Every season of one show carries the same series ids, so the canonical key collides across seasons.
        val s1 = CatalogItemIds(mal = 39535, imdb = "tt13293588", tmdb = 94664, tvdb = 371310)
        val s2 = CatalogItemIds(mal = 51179, imdb = "tt13293588", tmdb = 94664, tvdb = 371310)

        assertEquals(s1.canonicalKey, s2.canonicalKey)
        assertEquals("mal:39535", s1.entryKey)
        assertEquals("mal:51179", s2.entryKey)
        assertEquals("anilist:6", CatalogItemIds(anilist = 6, imdb = "tt1").entryKey)
        // Falls back to the series id when the entry has no provider-native id.
        assertEquals("imdb:tt1", CatalogItemIds(imdb = "tt1").entryKey)
    }

    @Test
    fun survivesTheMediaItemRawRoundTripTheDetailScreenReliesOn() {
        val rendered = item.toMediaItem()

        assertEquals("catalog:anilist:show/tvdb:457078", rendered.id)
        assertNull(rendered.serverId)
        assertTrue(rendered.isCatalogItem)
        val decoded = rendered.catalogItem!!
        assertEquals(item.altTitles, decoded.altTitles)
        assertEquals(ExternalSeasonRef(tvdb = 2, tmdb = 1), decoded.season)
        assertEquals(item.title, decoded.title)
        assertEquals("mal:63832", decoded.ids.entryKey)
    }

    @Test
    fun carriesEveryAttributedRatingOntoTheSynthesizedMediaItem() {
        val rated = CatalogItem(
            source = CatalogSourceId.SIMKL,
            kind = MediaKind.MOVIE,
            title = "Rated",
            ids = CatalogItemIds(tmdb = 603),
            rating = 8.1,
            ratings = listOf(MediaRatingSource("simkl", 8.1, 11), MediaRatingSource("imdb", 7.9, 12)),
        )

        val rendered = rated.toMediaItem()

        assertEquals(8.1, rendered.rating)
        assertEquals(listOf("simkl", "imdb"), rendered.ratings?.map { it.source })
        assertEquals(12, rendered.ratings?.last()?.votes)
    }

    @Test
    fun survivesAnEncodeDecodeCycleThroughJsonText() {
        val decoded = CatalogItem.fromJson(Json.parseToJsonElement(item.toJson().toString()).jsonObject)

        assertEquals(item.altTitles, decoded.altTitles)
        assertEquals(2, decoded.season?.tvdb)
        assertEquals(1, decoded.season?.tmdb)
        assertTrue(decoded.season!!.isSequel)
        assertNull(decoded.season.agreedSeason)
    }

    @Test
    fun everyFieldSurvivesTheJsonRoundTrip() {
        val full = CatalogItem(
            source = CatalogSourceId.SEERR,
            kind = MediaKind.MOVIE,
            title = "Full",
            ids = allIds,
            altTitles = listOf("Alt"),
            season = ExternalSeasonRef(tvdb = 1),
            year = 1999,
            overview = "Overview",
            runtimeMinutes = 136,
            rating = 8.7,
            votes = 100,
            genres = listOf("Action"),
            certification = "R",
            trailerUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            airStatus = CatalogAirStatus.ENDED,
            episodeCount = 12,
            network = "HBO",
            posterUrl = "https://p/default",
            backdropUrl = "https://b/default",
            posterVariants = mapOf(342 to "https://p/342", 500 to "https://p/500"),
            backdropVariants = mapOf(1280 to "https://b/1280"),
            logoUrl = "https://l",
            bannerUrl = "https://banner",
            accentColor = "#aabbcc",
            ratings = listOf(MediaRatingSource("imdb", 7.9, 12)),
            ranks = listOf(CatalogRank(3, CatalogRankScope.AIRING, allTime = false, year = 2025, season = CatalogSeasonName.FALL)),
            audience = CatalogAudience(watchingNow = 4, viewers = 9, viewersPeriod = CatalogAudiencePeriod.ALL_TIME, dropRate = 0.5),
            broadcast = CatalogBroadcast(weekday = 2, time = "21:00", timezone = "Asia/Tokyo"),
            nextEpisode = CatalogNextEpisode(Instant.parse("2025-10-01T15:00:00Z"), episode = 4),
            serverState = CatalogServerState(
                availability = CatalogAvailability.PARTIALLY_AVAILABLE,
                request4k = CatalogRequestState.PENDING,
                availableSeasons = 1,
                totalSeasons = 2,
            ),
            releaseDate = Instant.parse("1999-03-31T00:00:00Z"),
            physicalReleaseDate = Instant.parse("1999-09-21T00:00:00Z"),
            endDate = Instant.parse("2003-11-05T00:00:00Z"),
            addedAt = Instant.parse("2024-01-02T03:04:05Z"),
            userRating = 9.0,
            originalTitle = "Original",
            tagline = "Tagline",
            broadcastSeason = CatalogSeasonInfo(CatalogSeasonName.SPRING, 1999),
            format = CatalogFormat.TV_SHORT,
            sourceMaterial = CatalogSourceMaterial.LIGHT_NOVEL,
            studios = listOf("Studio"),
            countries = listOf("us"),
            languages = listOf("en"),
            credits = listOf(CatalogCredit("Lana", CatalogCreditRole.DIRECTOR)),
            tags = listOf(CatalogTag("Twist", rank = 90, isSpoiler = true)),
            links = listOf(CatalogLink("Site", "https://site", isStreaming = true)),
            unairedEpisodeCount = 3,
            recommenders = listOf(CatalogRecommender("neo", CatalogRecommendationReason.FAVORITED, name = "Neo", note = "Whoa")),
            contentAdvisory = "Violence",
            budget = 63_000_000,
            revenue = 467_222_728,
            isAdult = false,
            recommendationCount = 12,
            recommendationPercent = 0.8,
            background = "Background",
            cast = listOf(CatalogCastMember("Keanu", secondary = "Neo", imageUrl = "https://c")),
        )

        val text = full.toJson().toString()
        assertEquals(full, CatalogItem.fromJson(Json.parseToJsonElement(text).jsonObject))
        val json = full.toJson()
        assertEquals(JsonPrimitive("tvShort"), json["format"])
        assertEquals(JsonPrimitive("1999-03-31T00:00:00Z"), json["releaseDate"])
        assertEquals(JsonPrimitive("https://p/342"), json["posterVariants"]!!.jsonObject["342"])
    }

    @Test
    fun omitsAltTitlesAndSeasonWhenAbsentRatherThanEmittingEmpties() {
        val bare = CatalogItem(source = CatalogSourceId.TRAKT, kind = MediaKind.MOVIE, title = "Solo Movie", ids = CatalogItemIds(imdb = "tt1"))

        assertFalse("altTitles" in bare.toJson())
        assertFalse("season" in bare.toJson())
        val decoded = CatalogItem.fromJson(bare.toJson())
        assertTrue(decoded.altTitles.isEmpty())
        assertNull(decoded.season)
    }

    @Test
    fun anUnknownSourceFailsLoudly() {
        val json = JsonObject(item.toJson() + ("source" to JsonPrimitive("letterboxd")))

        assertFailsWith<IllegalArgumentException> { CatalogItem.fromJson(json) }
    }

    @Test
    fun enrichedWithUnionsAudienceCountersInsteadOfReplacingThem() {
        // A Simkl trending row supplies windowed viewers and planning; its detail body only a drop rate.
        val row = CatalogItem(
            source = CatalogSourceId.SIMKL,
            kind = MediaKind.SHOW,
            title = "House of the Dragon",
            ids = CatalogItemIds(simkl = 1197910),
            audience = CatalogAudience(viewers = 7603, viewersPeriod = CatalogAudiencePeriod.WEEK, planning = 8422),
        )
        val detail = row.copy(audience = CatalogAudience(dropRate = 0.031))

        val merged = row.enrichedWith(detail).audience!!
        assertEquals(7603, merged.viewers)
        assertEquals(CatalogAudiencePeriod.WEEK, merged.viewersPeriod)
        assertEquals(8422, merged.planning)
        assertEquals(0.031, merged.dropRate)
    }

    @Test
    fun enrichedWithLetsDetailReplaceARowValueAndMergesIdsPerKey() {
        val row = CatalogItem(
            source = CatalogSourceId.SEERR,
            kind = MediaKind.MOVIE,
            title = "The Matrix",
            ids = CatalogItemIds(imdb = "tt0133093"),
            ranks = listOf(CatalogRank(rank = 3, scope = CatalogRankScope.TRENDING, allTime = false)),
        )
        val detail = CatalogItem(
            source = CatalogSourceId.SEERR,
            kind = MediaKind.MOVIE,
            title = "The Matrix",
            overview = "A full synopsis the row never carried.",
            ids = CatalogItemIds(tmdb = 603),
        )

        val merged = row.enrichedWith(detail)
        assertEquals("A full synopsis the row never carried.", merged.overview)
        assertEquals("tt0133093", merged.ids.imdb, "row-only id must survive")
        assertEquals(603, merged.ids.tmdb, "detail id must be adopted")
        assertEquals(3, merged.ranks?.single()?.rank, "a rank is row context a detail body cannot know")
    }

    @Test
    fun posterVariantPicksTheNarrowestThatCoversTheTarget() {
        val poster = item.copy(posterUrl = "default", posterVariants = mapOf(342 to "w342", 500 to "w500"))

        assertEquals("w342", poster.posterFor(200))
        assertEquals("w500", poster.posterFor(400))
        assertEquals("default", poster.posterFor(800), "nothing wide enough: the default asset wins")
        assertEquals("w500", poster.copy(posterUrl = null).posterFor(800), "then the widest variant")
        assertEquals("default", poster.copy(posterVariants = null).posterFor(200))
    }
}
