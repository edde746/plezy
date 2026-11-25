package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MediaFileInfoTest {
    private fun stream(
        ordinal: Int = 1,
        displayTitle: String? = null,
        title: String? = null,
        language: String? = null,
        codec: String? = null,
        channels: Int? = null,
        channelLayout: String? = null,
        sampleRate: Int? = null,
        frameRate: Double? = null,
        spatialFormat: String? = null,
    ) = MediaStreamDetails(
        kind = MediaStreamKind.AUDIO,
        ordinal = ordinal,
        displayTitle = displayTitle,
        title = title,
        language = language,
        codec = codec,
        channels = channels,
        channelLayout = channelLayout,
        sampleRate = sampleRate,
        frameRate = frameRate,
        spatialFormat = spatialFormat,
    )

    @Test
    fun formatsChannelLayoutsAndCountsWithoutEmptyPunctuation() {
        assertEquals("5.1 (6 ch)", stream(channels = 6, channelLayout = "5.1").channelsFormatted)
        assertEquals("5.1", stream(channelLayout = "5.1").channelsFormatted)
        assertEquals("6 ch", stream(channels = 6).channelsFormatted)
        assertNull(stream().channelsFormatted)
    }

    @Test
    fun formatsSampleRates() {
        assertEquals("48 kHz", stream(sampleRate = 48000).sampleRateFormatted)
        assertEquals("44.1 kHz", stream(sampleRate = 44100).sampleRateFormatted)
    }

    @Test
    fun formatsFrameRates() {
        assertEquals("24 fps", stream(frameRate = 24.0).frameRateFormatted)
        assertEquals("23.976 fps", stream(frameRate = 23.976).frameRateFormatted)
    }

    @Test
    fun extractsFileNameFromEitherSeparator() {
        assertEquals("Movie.mkv", MediaFilePart(filePath = "/media/movies/Movie.mkv").fileName)
        assertEquals("Movie.mkv", MediaFilePart(filePath = "C:\\Media\\Movies\\Movie.mkv").fileName)
        assertNull(MediaFilePart(filePath = "").fileName)
    }

    @Test
    fun formatsDurations() {
        assertEquals("1h 23m 45s", formatMediaDuration(5025000))
        assertEquals("23m 45s", formatMediaDuration(1425000))
        assertEquals("45s", formatMediaDuration(45000))
        assertNull(formatMediaDuration(null))
    }

    @Test
    fun headlineFallsBackThroughDisplayTitleTitleLanguageCodecAndOrdinal() {
        assertEquals("Display", stream(displayTitle = "Display", title = "Title", language = "English", codec = "aac").headline)
        assertEquals("Title", stream(title = "Title", language = "English", codec = "aac").headline)
        assertEquals("English", stream(language = "English", codec = "aac").headline)
        assertEquals("aac", stream(codec = "aac").headline)
        assertEquals("#7", stream(ordinal = 7).headline)
        assertEquals("aac", stream(title = "  ", codec = " aac ").headline)
    }

    @Test
    fun versionResolutionPrefersDimensionsThenServerLabel() {
        assertEquals("3840x2160", MediaFileVersion(width = 3840, height = 2160, videoResolutionLabel = "4k").resolutionFormatted)
        assertEquals("4k", MediaFileVersion(width = 3840, videoResolutionLabel = "4k").resolutionFormatted)
        assertNull(MediaFileVersion().resolutionFormatted)
    }

    @Test
    fun versionAspectRatioAndTotals() {
        assertEquals("1.78", MediaFileVersion(aspectRatio = 1.7777).aspectRatioFormatted)
        assertNull(MediaFileVersion().aspectRatioFormatted)
        val version = MediaFileVersion(
            parts = listOf(MediaFilePart(fileSize = 1024L * 1024 * 1024), MediaFilePart(fileSize = 512L * 1024 * 1024), MediaFilePart()),
        )
        assertEquals(1536L * 1024 * 1024, version.totalFileSize)
        assertEquals("1.5 GB", version.totalFileSizeFormatted)
        assertNull(MediaFileVersion(parts = listOf(MediaFilePart())).totalFileSizeFormatted)
        assertEquals("1h 23m 45s", MediaFileVersion(durationMs = 5025000).durationFormatted)
    }

    @Test
    fun videoRangeLabels() {
        assertEquals(
            listOf("SDR", "HDR", "HDR10", "HDR10+", "HLG", "Dolby Vision", "Dolby Vision (HDR10)", "Dolby Vision (HLG)", null),
            MediaVideoRange.entries.map { it.label },
        )
    }

    @Test
    fun spatialAudio() {
        assertTrue(stream(spatialFormat = "DolbyAtmos").isSpatialAudio)
        assertEquals("Dolby Atmos", stream(spatialFormat = "DolbyAtmos").spatialFormatLabel)
        assertFalse(stream(spatialFormat = "None").isSpatialAudio)
        assertFalse(stream(spatialFormat = "").isSpatialAudio)
        assertNull(stream().spatialFormatLabel)
    }

    @Test
    fun streamsOfKindFilters() {
        val video = MediaStreamDetails(kind = MediaStreamKind.VIDEO, ordinal = 1)
        val part = MediaFilePart(streams = listOf(video, stream()))
        assertEquals(listOf(video), part.streamsOfKind(MediaStreamKind.VIDEO))
    }

    @Test
    fun dolbyVisionProfileFallsBackToTitle() {
        assertEquals("Dolby Vision Profile 8.1", MediaDolbyVisionInfo(title = "Dolby Vision Profile 8.1").profileFormatted)
        assertTrue(MediaDolbyVisionInfo().isEmpty)
    }
}
