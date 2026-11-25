package com.edde746.plezy.model

import com.edde746.plezy.backend.FakeMediaBackend
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Instant

class MediaVersionPreferenceTest {
    private val versions = listOf(
        MediaVersion(id = "101", videoResolution = "1080", videoCodec = "h264", container = "mkv"),
        MediaVersion(id = "102", videoResolution = "4k", videoCodec = "hevc", container = "mkv"),
    )

    @Test
    fun decodesLegacyBareIntAsIndexOnlyRecord() {
        assertEquals(MediaVersionPreference(index = 1), MediaVersionPreference.fromJson(JsonPrimitive(1)))
    }

    @Test
    fun roundTripsTheRecordForm() {
        val preference = MediaVersionPreference.forVersion(versions[1], 1, now = Instant.fromEpochMilliseconds(1_700_000_000_000))
        val decoded = MediaVersionPreference.fromJson(preference.toJson())
        assertEquals(MediaVersionPreference(versionId = "102", signature = "4k:hevc:mkv", index = 1, updatedAt = 1_700_000_000_000), decoded)
    }

    @Test
    fun omitsAbsentFieldsAndReadsGarbageAsIndexZero() {
        assertEquals(buildJsonObject { put("idx", 2) }, MediaVersionPreference(index = 2).toJson())
        assertEquals(MediaVersionPreference(index = 0), MediaVersionPreference.fromJson(JsonPrimitive("garbage")))
        assertEquals(MediaVersionPreference(index = 0), MediaVersionPreference.fromJson(buildJsonObject { put("idx", "1") }))
    }

    @Test
    fun exactVersionIdWinsOverStoredIndex() {
        assertEquals(1, MediaVersionPreference(versionId = "102", signature = "4k:hevc:mkv", index = 0).resolveIndex(versions))
    }

    @Test
    fun signatureMatchesWhenTheIdIsFromASiblingEpisode() {
        assertEquals(1, MediaVersionPreference(versionId = "999", signature = "4k:hevc:mkv", index = 0).resolveIndex(versions))
    }

    @Test
    fun signatureMatchesByResolutionWhenCodecAndContainerDiffer() {
        assertEquals(1, MediaVersionPreference(versionId = "999", signature = "4k:av1:mp4", index = 0).resolveIndex(versions))
    }

    @Test
    fun fallsBackToStoredIndexWhenIdAndSignatureMiss() {
        assertEquals(1, MediaVersionPreference(versionId = "999", signature = "720:vp9:webm", index = 1).resolveIndex(versions))
    }

    @Test
    fun returnsNullForOutOfRangeIndexWithNoMatch() {
        val preference = MediaVersionPreference(index = 5)
        assertNull(preference.resolveIndex(versions))
        assertNull(preference.resolveIndex(emptyList()))
    }

    // resolveMediaVersions

    private fun movie(mediaVersions: List<MediaVersion>? = null) =
        MediaItem(id = "movie-1", backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = "Movie", mediaVersions = mediaVersions, serverId = "srv-1")

    private fun version(id: String) = MediaVersion(id = id, videoResolution = "1080", videoCodec = "h264")

    @Test
    fun fetchesTheFullItemWhenTheBrowseRowHasNoVersions() = runTest {
        val backend = FakeMediaBackend("srv-1", BackendKind.JELLYFIN)
        backend.items = { id -> movie(listOf(version("src-1080"), version("src-4k"))).copy(id = id) }

        val resolved = resolveMediaVersions(movie(), backend)

        assertEquals(listOf("src-1080", "src-4k"), resolved.map { it.id })
        assertEquals(listOf("fetchItem:movie-1"), backend.calls)
    }

    @Test
    fun usesInlineVersionsWithoutFetching() = runTest {
        val backend = FakeMediaBackend("srv-1", BackendKind.JELLYFIN)
        val inline = listOf(version("inline"))

        assertSame(inline, resolveMediaVersions(movie(inline), backend))
        assertTrue(backend.calls.isEmpty())
    }

    @Test
    fun usesFallbackVersionsWithoutFetching() = runTest {
        val backend = FakeMediaBackend("srv-1", BackendKind.JELLYFIN)
        val fallback = listOf(version("fallback"))

        assertSame(fallback, resolveMediaVersions(movie(), backend, fallbackVersions = fallback))
        assertTrue(backend.calls.isEmpty())
    }

    @Test
    fun returnsAnEmptyListWhenTheDetailLookupFails() = runTest {
        val backend = FakeMediaBackend("srv-1", BackendKind.JELLYFIN)
        backend.items = { throw IllegalStateException("server error") }

        assertEquals(emptyList(), resolveMediaVersions(movie(), backend))
    }
}
