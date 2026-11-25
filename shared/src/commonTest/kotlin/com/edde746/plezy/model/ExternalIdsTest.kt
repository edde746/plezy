package com.edde746.plezy.model

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ExternalIdsTest {
    private fun json(text: String) = Json.parseToJsonElement(text)

    private fun providerIds(vararg entries: Pair<String, String>) = JsonObject(entries.associate { (key, value) -> key to JsonPrimitive(value) })

    // fromGuids

    @Test
    fun parsesPlexImdbTmdbTvdbUris() {
        val ids = ExternalIds.fromGuids(json("""[{"id":"imdb://tt12345"},{"id":"tmdb://456"},{"id":"tvdb://789"}]""").jsonArray)
        assertEquals(ExternalIds(imdb = "tt12345", tmdb = 456, tvdb = 789), ids)
        assertTrue(ids.hasAny)
    }

    @Test
    fun ignoresUnknownSchemesAndBadShapes() {
        val ids = ExternalIds.fromGuids(json("""[{"id":"mbid://abc"},"not-a-map",{"id":null},{"id":"tmdb://not-a-number"}]""").jsonArray)
        assertFalse(ids.hasAny)
    }

    // fromLegacyPlexGuid

    @Test
    fun normalizesOfficialPlexAgentGuids() {
        val cases = mapOf(
            "com.plexapp.agents.imdb://tt29768334?lang=en" to ExternalIds(imdb = "tt29768334"),
            "com.plexapp.agents.themoviedb://1241983" to ExternalIds(tmdb = 1241983),
            "com.plexapp.agents.thetvdb://315500?lang=en" to ExternalIds(tvdb = 315500),
        )
        for ((guid, expected) in cases) assertEquals(expected, ExternalIds.fromLegacyPlexGuid(guid), guid)
    }

    @Test
    fun normalizesHamaGuidModesWithDirectExternalIds() {
        val cases = mapOf(
            "com.plexapp.agents.hama://tvdb-315500" to ExternalIds(tvdb = 315500),
            "com.plexapp.agents.hama://tvdb2-315500" to ExternalIds(tvdb = 315500),
            "com.plexapp.agents.hama://tvdb9-315500" to ExternalIds(tvdb = 315500),
            "com.plexapp.agents.hama://tmdb-69346" to ExternalIds(tmdb = 69346),
            "com.plexapp.agents.hama://tsdb-69346?lang=en" to ExternalIds(tmdb = 69346),
            "com.plexapp.agents.hama://imdb-6455986" to ExternalIds(imdb = "tt6455986"),
            "com.plexapp.agents.hama://imdb-tt6455986" to ExternalIds(imdb = "tt6455986"),
            "com.plexapp.agents.hama://anidb-11905?lang=en" to ExternalIds(anidb = 11905),
        )
        for ((guid, expected) in cases) assertEquals(expected, ExternalIds.fromLegacyPlexGuid(guid), guid)
    }

    @Test
    fun anAnidbIdIsNotACatalogId() {
        val ids = ExternalIds.fromLegacyPlexGuid("com.plexapp.agents.hama://anidb-11905")
        assertTrue(ids.hasAny)
        assertFalse(ids.hasCatalogIds, "IMDb/TMDB/TVDB consumers must not act on an AniDB id")
        assertTrue(ids.isEmpty)
    }

    @Test
    fun rejectsUnsupportedAgentsAnidbGroupingModesAndMalformedIds() {
        val invalid = listOf(
            null,
            "",
            "not a URI",
            "plex://movie/abc",
            "local://315500",
            "com.plexapp.agents.none://315500",
            // anidb2..9 group several AniDB entries under one TVDB-numbered Plex show.
            "com.plexapp.agents.hama://anidb2-11905",
            "com.plexapp.agents.hama://anidb9-11905",
            "com.plexapp.agents.hama://anidb-not-a-number",
            "com.plexapp.agents.hama://anidb-",
            "com.plexapp.agents.hama://tvdb10-315500",
            "com.plexapp.agents.hama://tvdb-not-a-number",
            "com.plexapp.agents.hama://tmdb-",
            "com.plexapp.agents.hama://imdb-not-an-id",
            "com.plexapp.agents.themoviedb://1241983/extra",
        )
        for (guid in invalid) assertFalse(ExternalIds.fromLegacyPlexGuid(guid).hasAny, "$guid")
    }

    // legacyPlexGuidPrefixes

    @Test
    fun everyPrefixNamesAGuidFromLegacyPlexGuidReadsBackToTheSameId() {
        val ids = ExternalIds(imdb = "tt0245429", tmdb = 129, tvdb = 276, anidb = 112)
        val prefixes = ids.legacyPlexGuidPrefixes
        assertTrue(prefixes.isNotEmpty())
        for (prefix in prefixes) {
            assertTrue(prefix.endsWith("?"), "a literal prefix filter must stop at the lang argument")
            assertTrue(ExternalIds.fromLegacyPlexGuid("${prefix}lang=en").intersects(ids), prefix)
        }
        assertTrue("com.plexapp.agents.thetvdb://276?" in prefixes)
        assertTrue("com.plexapp.agents.hama://tvdb4-276?" in prefixes)
        assertTrue("com.plexapp.agents.hama://anidb-112?" in prefixes)
    }

    @Test
    fun prefixesAreEmptyWithoutIds() {
        assertTrue(ExternalIds().legacyPlexGuidPrefixes.isEmpty())
    }

    // fillFrom, JSON, intersects

    @Test
    fun keepsItsOwnIdsAndOnlyFillsTheOnesItIsMissing() {
        val merged = ExternalIds(tvdb = 315500).fillFrom(ExternalIds(imdb = "tt6455986", tvdb = 999, anidb = 11905))
        assertEquals(315500, merged.tvdb, "the modern Guid array wins per field")
        assertEquals("tt6455986", merged.imdb)
        assertEquals(11905, merged.anidb)
    }

    @Test
    fun roundTripsEveryIdThroughJsonAndOmitsAbsentOnes() {
        val ids = ExternalIds(imdb = "tt1", tmdb = 2, tvdb = 3, anidb = 4)
        assertEquals(ids, Json.decodeFromString(ExternalIds.serializer(), Json.encodeToString(ExternalIds.serializer(), ids)))
        assertEquals("{}", Json.encodeToString(ExternalIds.serializer(), ExternalIds()))
        assertEquals("""{"tmdb":2}""", Json.encodeToString(ExternalIds.serializer(), ExternalIds(tmdb = 2)))
        assertFalse(Json.decodeFromString(ExternalIds.serializer(), "{}").hasAny)
    }

    @Test
    fun idsQueuedWithoutAnAnidbFieldStillDecode() {
        assertEquals(ExternalIds(imdb = "tt1", tmdb = 2), Json.decodeFromString(ExternalIds.serializer(), """{"imdb":"tt1","tmdb":2}"""))
    }

    @Test
    fun rowIdentityNamesOneIdInPreferenceOrder() {
        assertEquals("imdb=tt1", ExternalIds(imdb = "tt1", tmdb = 2).rowIdentity())
        assertEquals("tvdb=3", ExternalIds(tvdb = 3, anidb = 4).rowIdentity())
        assertNull(ExternalIds(anidb = 4).rowIdentity())
    }

    @Test
    fun intersectsMatchesOnAnAnidbIdAlone() {
        val hama = ExternalIds(anidb = 11905)
        assertTrue(hama.intersects(ExternalIds(anidb = 11905)))
        assertFalse(hama.intersects(ExternalIds(tvdb = 315500)))
    }

    @Test
    fun intersectsMatchesWhenAnySharedIdFormIsEqual() {
        val trakt = ExternalIds(imdb = "tt0133093", tmdb = 603)
        assertTrue(trakt.intersects(ExternalIds(tmdb = 603)))
        assertTrue(trakt.intersects(ExternalIds(imdb = "tt0133093", tvdb = 999)))
    }

    @Test
    fun intersectsNeverMatchesOnAbsentOrDifferingIds() {
        val trakt = ExternalIds(imdb = "tt0133093")
        assertFalse(trakt.intersects(ExternalIds(tmdb = 603)))
        assertFalse(trakt.intersects(ExternalIds(imdb = "tt9999999")))
        assertFalse(ExternalIds().intersects(ExternalIds()))
    }

    // fromJellyfinProviderIds, jellyfinCandidatesMatching

    @Test
    fun extractsTmdbImdbTvdbCaseInsensitively() {
        assertEquals(ExternalIds(imdb = "tt99999", tmdb = 12345, tvdb = 777), ExternalIds.fromJellyfinProviderIds(providerIds("Tmdb" to "12345", "Imdb" to "tt99999", "Tvdb" to "777")))
        assertEquals(ExternalIds(imdb = "tt000", tmdb = 111), ExternalIds.fromJellyfinProviderIds(providerIds("tmdb" to "111", "imdb" to "tt000")))
    }

    @Test
    fun ignoresUnknownProvidersEmptyAndNonNumericValues() {
        assertFalse(ExternalIds.fromJellyfinProviderIds(providerIds("AniList" to "42", "Tvdb" to "")).hasAny)
        assertEquals(ExternalIds(imdb = "tt12345"), ExternalIds.fromJellyfinProviderIds(providerIds("Tmdb" to "not-a-number", "Imdb" to "tt12345")))
        assertFalse(ExternalIds.fromJellyfinProviderIds(json("""{"Tmdb":603}""").jsonObject).hasAny)
    }

    private val target = ExternalIds(imdb = "tt0133093", tmdb = 603)

    private fun candidates(text: String) = (json(text) as JsonArray).map { it.jsonObject }

    @Test
    fun picksTheCandidateWhoseProviderIdsIntersectSkippingOthers() {
        val matches = ExternalIds.jellyfinCandidatesMatching(
            candidates(
                """[{"Name":"The Matrix Reloaded","ProviderIds":{"Imdb":"tt0234215","Tmdb":"604"}},{"Name":"No provider ids"},""" +
                    """{"Name":"The Matrix","ProviderIds":{"Tmdb":"603"}}]""",
            ),
            target,
        )
        assertEquals(listOf(JsonPrimitive("The Matrix")), matches.map { it["Name"] })
    }

    @Test
    fun returnsEveryLibraryCopyOfTheSameTitleInResponseOrder() {
        val matches = ExternalIds.jellyfinCandidatesMatching(
            candidates(
                """[{"Id":"movie-4k","ProviderIds":{"Tmdb":"603"}},{"Id":"movie-other","ProviderIds":{"Imdb":"tt0234215"}},""" +
                    """{"Id":"movie-hd","ProviderIds":{"Imdb":"tt0133093"}}]""",
            ),
            target,
        )
        assertEquals(listOf(JsonPrimitive("movie-4k"), JsonPrimitive("movie-hd")), matches.map { it["Id"] })
    }

    @Test
    fun returnsNoCandidatesWhenNothingVerifies() {
        assertTrue(ExternalIds.jellyfinCandidatesMatching(candidates("""[{"ProviderIds":{"Imdb":"tt0234215"}}]"""), target).isEmpty())
    }

    // ExternalSeasonRef

    @Test
    fun agreedSeasonResolvesOnlyWhenBothProvidersMappedTheSeasonAndAgree() {
        assertEquals(3, ExternalSeasonRef(tvdb = 3, tmdb = 3).agreedSeason)
        // A continuation season TVDB numbers 2 and TMDB folds into 1 has no honest answer.
        assertNull(ExternalSeasonRef(tvdb = 2, tmdb = 1).agreedSeason)
    }

    @Test
    fun aMissingSeasonNumberIsNotAgreement() {
        assertNull(ExternalSeasonRef(tvdb = 2).agreedSeason)
        assertNull(ExternalSeasonRef(tmdb = 2).agreedSeason)
        assertNull(ExternalSeasonRef().agreedSeason)
    }

    @Test
    fun isSequelStaysKnowableEvenWhenTheNumbersDisagree() {
        assertTrue(ExternalSeasonRef(tvdb = 2, tmdb = 1).isSequel)
        assertFalse(ExternalSeasonRef(tvdb = 1, tmdb = 1).isSequel)
        assertTrue(ExternalSeasonRef(tmdb = 4).isSequel)
        assertFalse(ExternalSeasonRef().isSequel)
    }

    @Test
    fun seasonRefRoundTripsThroughJson() {
        val ref = ExternalSeasonRef(tvdb = 2, tmdb = 1)
        assertEquals(ref, Json.decodeFromString(ExternalSeasonRef.serializer(), Json.encodeToString(ExternalSeasonRef.serializer(), ref)))
        assertEquals("{}", Json.encodeToString(ExternalSeasonRef.serializer(), ExternalSeasonRef()))
        assertFalse(Json.decodeFromString(ExternalSeasonRef.serializer(), "{}").hasAny)
    }
}
