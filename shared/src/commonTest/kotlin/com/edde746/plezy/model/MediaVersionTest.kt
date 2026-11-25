package com.edde746.plezy.model

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MediaVersionTest {
    private fun version(resolution: String, codec: String, container: String) =
        MediaVersion(id = "", videoResolution = resolution, videoCodec = codec, container = container)

    @Test
    fun exactMatchGloballyOutranksAnEarlierResolutionAndCodecMatch() {
        val versions = listOf(version("1080", "h264", "mp4"), version("4k", "hevc", "mkv"))
        assertEquals(1, MediaVersion.findMatchingIndex(versions, linkedSetOf("1080:h264:mkv", "4k:hevc:mkv")))
    }

    @Test
    fun exactMatchGloballyOutranksAnEarlierResolutionOnlyMatch() {
        val versions = listOf(version("1080", "vp9", "mp4"), version("4k", "hevc", "mkv"))
        assertEquals(1, MediaVersion.findMatchingIndex(versions, linkedSetOf("1080:h264:avi", "4k:hevc:mkv")))
    }

    @Test
    fun resolutionAndCodecGloballyOutranksAnEarlierResolutionOnlyMatch() {
        val versions = listOf(version("1080", "vp9", "mp4"), version("4k", "hevc", "mp4"))
        assertEquals(1, MediaVersion.findMatchingIndex(versions, linkedSetOf("1080:h264:avi", "4k:hevc:mkv")))
    }

    @Test
    fun skipsMalformedSignaturesWithoutBlockingALaterValidExactMatch() {
        val versions = listOf(version("1080", "h264", "mkv"))
        assertEquals(0, MediaVersion.findMatchingIndex(versions, linkedSetOf("malformed", "1080:h264:mkv")))
        assertNull(MediaVersion.findMatchingIndex(versions, linkedSetOf("malformed", "also:malformed")))
    }

    @Test
    fun earlierAcceptedSignatureWinsASameTierTieEvenWithALaterCandidate() {
        val versions = listOf(version("4k", "hevc", "mp4"), version("1080", "h264", "mp4"))
        assertEquals(1, MediaVersion.findMatchingIndex(versions, linkedSetOf("1080:h264:mkv", "4k:hevc:mkv")))
    }

    @Test
    fun retainsValidThreeFieldSignaturesWithEmptyFields() {
        assertEquals(0, MediaVersion.findMatchingIndex(listOf(MediaVersion(id = "empty")), setOf("::")))
    }

    @Test
    fun earlierCandidateWinsWhenOneSignatureHasMultipleSameTierMatches() {
        val versions = listOf(version("1080", "h264", "mp4"), version("1080", "h264", "avi"))
        assertEquals(0, MediaVersion.findMatchingIndex(versions, setOf("1080:h264:mkv")))
    }

    @Test
    fun singletonSignaturesRetainExactThenCodecThenResolutionPriority() {
        val resolutionOnly = version("1080", "vp9", "mp4")
        val resolutionAndCodec = version("1080", "h264", "mp4")
        val exact = version("1080", "h264", "mkv")
        val accepted = setOf("1080:h264:mkv")
        assertEquals(2, MediaVersion.findMatchingIndex(listOf(resolutionOnly, resolutionAndCodec, exact), accepted))
        assertEquals(1, MediaVersion.findMatchingIndex(listOf(resolutionOnly, resolutionAndCodec), accepted))
        assertEquals(0, MediaVersion.findMatchingIndex(listOf(resolutionOnly), accepted))
    }

    @Test
    fun returnsNullForEmptyCandidatesOrAcceptedSignatures() {
        assertNull(MediaVersion.findMatchingIndex(emptyList(), setOf("1080:h264:mkv")))
        assertNull(MediaVersion.findMatchingIndex(listOf(version("1080", "h264", "mkv")), emptySet()))
    }

    @Test
    fun signatureIsLowerCased() {
        assertEquals("4k:hevc:mkv", version("4K", "HEVC", "MKV").signature)
        assertEquals("::", MediaVersion(id = "x").signature)
    }

    @Test
    fun resolutionHeightPrefersTheReportedHeightThenNamedTiers() {
        assertEquals(1080, MediaVersion(id = "", height = 1080, videoResolution = "4k").resolutionHeight)
        assertEquals(480, MediaVersion(id = "", height = 0, videoResolution = "SD").resolutionHeight)
        assertEquals(720, MediaVersion(id = "", videoResolution = "hd").resolutionHeight)
        assertEquals(2160, MediaVersion(id = "", videoResolution = "4k").resolutionHeight)
        assertEquals(4320, MediaVersion(id = "", videoResolution = "8k").resolutionHeight)
        assertEquals(576, MediaVersion(id = "", videoResolution = " 576 ").resolutionHeight)
        assertNull(MediaVersion(id = "", videoResolution = "weird").resolutionHeight)
        assertNull(MediaVersion(id = "").resolutionHeight)
    }

    @Test
    fun displayLabelJoinsTechnicalPartsAndPrefixesTheName() {
        val tech = MediaVersion(id = "", videoResolution = "1080", videoCodec = "hevc", container = "mkv", bitrate = 8500)
        assertEquals("1080p HEVC MKV (8.5 Mbps)", tech.displayLabel)
        assertEquals("720p H.264", MediaVersion(id = "", height = 720, videoCodec = "h264").displayLabel)
        assertEquals("Director's Cut · 1080p HEVC MKV (8.5 Mbps)", tech.copy(name = "Director's Cut").displayLabel)
        assertEquals("Director's Cut", MediaVersion(id = "", name = "Director's Cut").displayLabel)
    }

    @Test
    fun displayLabelSaysTheResolutionOnceWhereTheNameDoes() {
        val tech = MediaVersion(id = "", videoResolution = "720", videoCodec = "h264", container = "mp4", bitrate = 1200)
        assertEquals("720p · H.264 MP4 (1.2 Mbps)", tech.copy(name = "720p").displayLabel)
        assertEquals("720p Remux · H.264 MP4 (1.2 Mbps)", tech.copy(name = "720p Remux").displayLabel)
        assertEquals("720p", MediaVersion(id = "", height = 720, name = "720p").displayLabel)
        assertEquals("Theatrical · 720p H.264 MP4 (1.2 Mbps)", tech.copy(name = "Theatrical").displayLabel)
    }

    @Test
    fun bitrateKbpsFromBpsRoundsAndRejectsNonPositive() {
        assertEquals(8500, bitrateKbpsFromBps(8_499_600))
        assertNull(bitrateKbpsFromBps(0))
        assertNull(bitrateKbpsFromBps(null))
    }

    @Test
    fun playabilityFollowsParts() {
        assertTrue(MediaVersion(id = "").isPlayable)
        assertTrue(MediaVersion(id = "", parts = listOf(MediaPart(id = "a", exists = false), MediaPart(id = "b"))).isPlayable)
        assertFalse(MediaVersion(id = "", parts = listOf(MediaPart(id = "a", accessible = false))).isPlayable)
    }

    @Test
    fun ratingFromScaleNormalizesToTenAndRejectsNonScores() {
        assertEquals(MediaRatingSource("rt", 9.4, null), MediaRatingSource.fromScale("rt", 94.0, 100.0))
        assertEquals(8.0, MediaRatingSource.fromScale("lb", 4.0, 5.0, votes = 3)?.value)
        assertEquals(3, MediaRatingSource.fromScale("lb", 4.0, 5.0, votes = 3)?.votes)
        assertNull(MediaRatingSource.fromScale("x", null, 10.0))
        assertNull(MediaRatingSource.fromScale("x", Double.NaN, 10.0))
        assertNull(MediaRatingSource.fromScale("x", 0.0, 10.0))
        assertNull(MediaRatingSource.fromScale("x", 11.0, 10.0))
        assertNull(MediaRatingSource.fromScale("x", 5.0, 10.0, votes = 0))
    }

    @Test
    fun ratingJsonOmitsMissingVotesAndRequiresSourceAndValue() {
        val rating = MediaRatingSource("imdb", 8.4)
        assertEquals(setOf("source", "value"), rating.toJson().keys)
        assertEquals(rating, MediaRatingSource.fromJson(rating.toJson()))
        assertNull(MediaRatingSource.fromJson(buildJsonObject { put("source", "imdb") }))
    }

    @Test
    fun roleJsonRoundTripsAndDefaultsTag() {
        val role = MediaRole(id = "1", tag = "Actor", role = "Lead", thumbPath = "/p")
        assertEquals(role, MediaRole.fromJson(role.toJson()))
        assertEquals("", MediaRole.fromJson(JsonObject(emptyMap())).tag)
    }

    @Test
    fun streamsWithASidecarAreExternal() {
        assertTrue(MediaStream(id = "s", kind = MediaStreamKind.SUBTITLE, sidecarPath = "/a.srt").isExternal)
        assertFalse(MediaStream(id = "s", kind = MediaStreamKind.SUBTITLE, sidecarPath = "").isExternal)
    }
}
