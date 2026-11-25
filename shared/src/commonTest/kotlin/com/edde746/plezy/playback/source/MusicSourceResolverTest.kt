package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.InMemoryApiCacheStore
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.music.PlaybackMusicSourceResolver
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/** What the music source resolver asks the shared playback resolver for, and what a track opens with. */
class MusicSourceResolverTest {
    private val downloads = FakeDownloads()

    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    private fun resolver(client: PlaybackClient, quality: AudioQualityPreset = AudioQualityPreset.ORIGINAL) = PlaybackMusicSourceResolver(
        PlaybackSourceResolver(FakePlaybackServers(client), downloads, cachedMetadata(InMemoryApiCacheStore())),
    ) { quality }

    private fun track(id: String) = testItem(id, "srv", kind = MediaKind.TRACK).copy(title = "Song $id")

    @Test
    fun everyTrackAsksForTheFirstVersionAtOriginalWithTheMusicQualityAndItsOwnSessions() = runTest {
        val asked = mutableListOf<PlaybackInitializationOptions>()
        val client = PlaybackClient("srv") { options ->
            asked += options
            PlaybackInitializationResult(availableVersions = emptyList(), videoUrl = "https://server/${options.metadata.id}", isTranscoding = options.metadata.id == "t2")
        }
        val resolver = resolver(client, AudioQualityPreset.HIGH)

        val first = resolver.resolve(track("t1"), offline = false)
        val second = resolver.resolve(track("t2"), offline = false)

        for (options in asked) {
            assertEquals(0, options.selectedMediaIndex)
            assertEquals(TranscodeQualityPreset.ORIGINAL, options.qualityPreset)
            assertEquals(AudioQualityPreset.HIGH, options.audioQualityPreset)
            assertNotNull(options.sessionIdentifier)
            assertNotNull(options.transcodeSessionId)
        }
        assertNotEquals(asked[0].sessionIdentifier, asked[1].sessionIdentifier, "gapless arms never share a session")
        assertNotEquals(asked[0].transcodeSessionId, asked[1].transcodeSessionId, "nor a transcode session")
        assertEquals("DirectPlay", first.playMethod)
        assertEquals("Transcode", second.playMethod)
    }

    @Test
    fun aTrackTheServerGivesNoUrlFailsNamingTheTrack() = runTest {
        val client = PlaybackClient("srv") { PlaybackInitializationResult(availableVersions = emptyList(), videoUrl = null) }

        val error = assertFailsWith<PlaybackException> { resolver(client).resolve(track("t1"), offline = false) }

        assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, error.reason)
        assertEquals(T.music.noAudioUrl("Song t1"), error.message)
    }

    @Test
    fun anOnlinePlayPrefersTheDownloadedCopyAndOpensItWithoutHeaders() = runTest {
        downloads.add(FakeDownloads.Copy("srv", "t1", listOf("/music/t1.flac")))
        val client = PlaybackClient("srv").apply { streamHeaders = mapOf("X-Plex-Token" to "secret") }

        val local = resolver(client).resolve(track("t1"), offline = false)
        val streamed = resolver(client).resolve(track("t2"), offline = false)

        assertTrue("/music/t1.flac" in local.url, local.url)
        assertFalse(local.url.startsWith("http"), local.url)
        assertEquals(emptyMap(), local.headers, "a local file carries no server credentials")
        assertEquals("secret", streamed.headers["X-Plex-Token"])
        assertEquals(1, client.initializations, "only the streamed track asks the server")
    }
}
