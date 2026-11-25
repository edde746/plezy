package com.edde746.plezy.presentation.detail

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaStream
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.MediaVersion
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MediaQualityLabelsTest {
    private fun item(vararg versions: MediaVersion) =
        MediaItem(id = "1", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, mediaVersions = versions.toList())

    private fun version(resolution: String?, vararg streams: MediaStream, width: Int? = null, height: Int? = null) =
        MediaVersion("v", width = width, height = height, videoResolution = resolution, parts = listOf(MediaPart("p", streams = streams.toList())))

    @Test
    fun `formats resolution dolby vision and atmos`() {
        val v = version(
            "4k",
            MediaStream("v", MediaStreamKind.VIDEO, hdr = true, dolbyVision = true),
            MediaStream("a", MediaStreamKind.AUDIO, codec = "truehd", displayTitle = "English (TrueHD Atmos 7.1)", channels = 8, selected = true),
        )
        assertEquals(listOf("4K", "DV", "TrueHD Atmos"), mediaQualityLabels(item(v)))
    }

    @Test
    fun `formats the dolby vision profile`() {
        val v = version("4k", MediaStream("v", MediaStreamKind.VIDEO, dolbyVision = true, dolbyVisionProfile = 8), MediaStream("a", MediaStreamKind.AUDIO, codec = "eac3", channels = 6))
        assertEquals(listOf("4K", "DV P8", "EAC3 5.1"), mediaQualityLabels(item(v)))
    }

    @Test
    fun `formats hdr and surround`() {
        val v = version("1080", MediaStream("v", MediaStreamKind.VIDEO, hdr = true), MediaStream("a", MediaStreamKind.AUDIO, codec = "eac3", channels = 6))
        assertEquals(listOf("1080p", "HDR", "EAC3 5.1"), mediaQualityLabels(item(v)))
    }

    @Test
    fun `falls back to dimensions and prefers the selected then default audio`() {
        val v = version(
            null,
            MediaStream("a1", MediaStreamKind.AUDIO, codec = "aac", channels = 2),
            MediaStream("a2", MediaStreamKind.AUDIO, codec = "ac3", channels = 6, isDefault = true),
            width = 1920,
            height = 800,
        )
        assertEquals(listOf("1080p", "AC3 5.1"), mediaQualityLabels(item(v)))
    }

    @Test
    fun `an out of range version uses the first and none gives nothing`() {
        val v = version("720")
        assertEquals(listOf("720p"), mediaQualityLabels(item(v), versionIndex = 4))
        assertEquals(emptyList(), mediaQualityLabels(item()))
    }

    @Test
    fun `size needs every part size`() {
        val sized = MediaVersion("v", parts = listOf(MediaPart("p", sizeBytes = 1024L * 1024 * 1024)))
        val unknown = MediaVersion("v", parts = listOf(MediaPart("p", sizeBytes = 10), MediaPart("q")))
        assertEquals("1 GB", mediaSizeLabel(item(sized)))
        assertNull(mediaSizeLabel(item(unknown)))
    }
}

class ItemLinkTest {
    private val movie = MediaItem(id = "42", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, serverId = "srv", guid = "plex://movie/5d776b59ad5437001f79c6f8")

    @Test
    fun `a server link names server and item`() {
        assertEquals("plezy://play?server=srv&id=42", serverItemLink(movie).toString())
        assertNull(serverItemLink(movie.copy(kind = MediaKind.SEASON)))
    }

    @Test
    fun `a movie links by tmdb and its plex hash`() = runTest {
        val client = FakeMediaBackend("srv").apply { externalIds = { ExternalIds(imdb = "tt0133093", tmdb = 603) } }
        assertEquals("plezy://play?type=movie&tmdb=603&plex=5d776b59ad5437001f79c6f8", linkForItem(client, movie).toString())
    }

    @Test
    fun `a show prefers tvdb and names a profile when asked`() = runTest {
        val client = FakeMediaBackend("srv").apply { externalIds = { ExternalIds(tmdb = 1, tvdb = 81189) } }
        val link = linkForItem(client, movie.copy(kind = MediaKind.SHOW, guid = null))!!
        assertEquals("plezy://play?type=show&tvdb=81189&profile=Kids", link.asProfile("Kids"))
    }

    @Test
    fun `failed ids and episodes keep the server link`() = runTest {
        val client = FakeMediaBackend("srv").apply { externalIds = { error("down") } }
        assertEquals("plezy://play?server=srv&id=42", linkForItem(client, movie.copy(guid = null)).toString())
        assertEquals("plezy://play?server=srv&id=42", linkForItem(client, movie.copy(kind = MediaKind.EPISODE)).toString())
    }
}

class OfflineTrackStatusTest {
    private val item = MediaItem(
        id = "1",
        backend = BackendKind.JELLYFIN,
        kind = MediaKind.MOVIE,
        mediaVersions = listOf(MediaVersion("a", videoResolution = "1080", videoCodec = "h264"), MediaVersion("b", videoResolution = "4k", videoCodec = "hevc")),
    )

    @Test
    fun `the downloaded version is found by id before index and subtitles read off`() {
        val status = offlineTrackStatus(item, DownloadedVersion(mediaIndex = 0, mediaSourceId = "b"))!!
        assertEquals(listOf("4K", "HEVC"), status.video)
        assertNull(status.audio)
        assertEquals(com.edde746.plezy.strings.T.common.off, status.subtitle)
        assertEquals(listOf("1080p", "H.264"), offlineTrackStatus(item, DownloadedVersion(mediaIndex = 0, mediaSourceId = "gone"))!!.video)
    }

    @Test
    fun `no download or an out of range version shows nothing`() {
        assertNull(offlineTrackStatus(item, null))
        assertNull(offlineTrackStatus(item, DownloadedVersion(mediaIndex = 5, mediaSourceId = null)))
    }
}
