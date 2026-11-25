package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.TranscodeFallbackReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.MediaVersion
import kotlin.test.Test
import kotlin.test.assertEquals

class PlaybackSourceTest {
    private fun context(result: PlaybackInitializationResult) = PlaybackContext(
        item = testItem("item-1", "srv"),
        result = result,
        sourceKind = if (result.isOffline) PlaybackSourceKind.LOCAL_FILE else PlaybackSourceKind.REMOTE_DIRECT,
        reportingMode = PlaybackReportingMode.ONLINE,
        streamHeaders = mapOf("X-Test" to "token"),
    )

    @Test
    fun keepsTheRequestedPresetWhenNoFallbackOccurred() {
        val source = PlaybackSource.of(context(PlaybackInitializationResult(emptyList(), videoUrl = "u")), TranscodeQualityPreset.P1080_8MBPS)
        assertEquals(TranscodeQualityPreset.P1080_8MBPS, source.qualityPreset)
    }

    @Test
    fun fallsBackToOriginalWhenTheBackendRejectedThePreset() {
        val source = PlaybackSource.of(
            context(PlaybackInitializationResult(emptyList(), videoUrl = "u", fallbackReason = TranscodeFallbackReason.entries.first())),
            TranscodeQualityPreset.P1080_8MBPS,
        )
        assertEquals(TranscodeQualityPreset.ORIGINAL, source.qualityPreset)
    }

    @Test
    fun anOriginalQualityRequestIgnoresTheFallbackReason() {
        val source = PlaybackSource.of(
            context(PlaybackInitializationResult(emptyList(), videoUrl = "u", fallbackReason = TranscodeFallbackReason.entries.first())),
            TranscodeQualityPreset.ORIGINAL,
        )
        assertEquals(TranscodeQualityPreset.ORIGINAL, source.qualityPreset)
    }

    @Test
    fun refinesTheMediaSourceIdFromTheClampedVersionIndex() {
        val versions = listOf(MediaVersion(id = "v0"), MediaVersion(id = "v1"))
        val source = PlaybackSource.of(
            context(PlaybackInitializationResult(versions, videoUrl = "u", selectedMediaIndex = 1)),
            TranscodeQualityPreset.ORIGINAL,
            requestedMediaSourceId = "requested",
        )
        assertEquals("v1", source.mediaSourceId)
        assertEquals(1, source.mediaIndex)
    }

    @Test
    fun keepsTheRequestedSourceIdWhenTheIndexIsOutOfRange() {
        val source = PlaybackSource.of(
            context(PlaybackInitializationResult(emptyList(), videoUrl = "u", selectedMediaIndex = 2)),
            TranscodeQualityPreset.ORIGINAL,
            requestedMediaSourceId = "requested",
        )
        assertEquals("requested", source.mediaSourceId)
    }

    @Test
    fun prefersTheResultSourceIdOverDerivedAndRequestedIds() {
        // Offline fallback playback: the result names the downloaded version, which wins over the stale requested id
        // even where a version list would derive another.
        val versions = listOf(MediaVersion(id = "v0"), MediaVersion(id = "v1"))
        val source = PlaybackSource.of(
            context(PlaybackInitializationResult(versions, videoUrl = "u", selectedMediaIndex = 1, selectedMediaSourceId = "downloaded")),
            TranscodeQualityPreset.ORIGINAL,
            requestedMediaSourceId = "requested",
        )
        assertEquals("downloaded", source.mediaSourceId)
    }
}
