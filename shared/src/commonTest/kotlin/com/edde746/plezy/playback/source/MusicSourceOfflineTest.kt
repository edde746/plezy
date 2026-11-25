package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.InMemoryApiCacheStore
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.music.PlaybackMusicSourceResolver
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** The music source resolver's offline flag: offline plays need a downloaded copy. */
class MusicSourceOfflineTest {
    private val downloads = FakeDownloads()

    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    private fun resolver(client: PlaybackClient, configure: FakePlaybackServers.() -> Unit = {}) = PlaybackMusicSourceResolver(
        PlaybackSourceResolver(FakePlaybackServers(client).apply(configure), downloads, cachedMetadata(InMemoryApiCacheStore())),
    ) { AudioQualityPreset.ORIGINAL }

    private fun track(id: String) = testItem(id, "srv", kind = MediaKind.TRACK)

    @Test
    fun anOfflinePlayOfATrackWithoutADownloadFailsWithoutAskingTheServer() = runTest {
        val client = PlaybackClient("srv")
        val error = assertFailsWith<PlaybackException> { resolver(client).resolve(track("track-1"), offline = true) }
        assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, error.reason)
        assertEquals(0, client.initializations)
    }

    @Test
    fun anOfflinePlayOfADownloadedTrackPlaysItsFileEvenWithTheServerOutOfReach() = runTest {
        downloads.add(FakeDownloads.Copy("srv", "track-1", listOf("/music/track-1.flac")))
        val client = PlaybackClient("srv")

        val source = resolver(client) { online.clear() }.resolve(track("track-1"), offline = true)

        assertTrue("/music/track-1.flac" in source.url, source.url)
        assertFalse(source.url.startsWith("http"), source.url)
        assertEquals(PlaybackReportingMode.OFFLINE_QUEUE, source.reporting)
        assertEquals(0, client.initializations)
    }

    @Test
    fun anOnlinePlayOfATrackWithoutADownloadStreamsFromTheServer() = runTest {
        val client = PlaybackClient("srv")
        val source = resolver(client).resolve(track("track-2"), offline = false)
        assertTrue(source.url.startsWith("http"), source.url)
        assertEquals(1, client.initializations)
    }
}
