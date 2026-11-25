package com.edde746.plezy.music

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MusicNavigationTest {
    private val seed = track("track-1")

    private class OutcomeMusic(private val outcome: InstantMixOutcome? = null, private val error: Exception? = null) : StubMusicPlayback() {
        override suspend fun playInstantMix(seed: MediaItem): InstantMixOutcome {
            error?.let { throw it }
            return outcome!!
        }
    }

    @Test
    fun aThrownFetchFailureSurfacesTheGenericInstantMixSnackbar() = runTest {
        assertEquals(InstantMixFeedback.Failed(T.music.instantMixFailed), OutcomeMusic(error = IllegalStateException("boom")).playInstantMixFeedback(seed))
    }

    @Test
    fun aPlaybackExceptionSurfacesItsOwnLocalizedMessage() = runTest {
        val music = OutcomeMusic(error = PlaybackException(T.music.instantMixNoServer))
        assertEquals(InstantMixFeedback.Failed(T.music.instantMixNoServer), music.playInstantMixFeedback(seed))
    }

    @Test
    fun anEmptyMixSurfacesTheNoTracksSnackbar() = runTest {
        assertEquals(InstantMixFeedback.Failed(T.music.instantMixEmpty), OutcomeMusic(InstantMixOutcome.EMPTY).playInstantMixFeedback(seed))
    }

    @Test
    fun aStartedMixShowsNoSnackbar() = runTest {
        assertEquals(InstantMixFeedback.Started, OutcomeMusic(InstantMixOutcome.STARTED).playInstantMixFeedback(seed))
    }

    @Test
    fun aSupersededMixStaysSilent() = runTest {
        assertEquals(InstantMixFeedback.Silent, OutcomeMusic(InstantMixOutcome.SUPERSEDED).playInstantMixFeedback(seed))
    }

    @Test
    fun aSlowFetchCannotReplaceAQueueStartedLater() = runTest {
        val music = StubMusicPlayback()
        val gate = CompletableDeferred<List<MediaItem>>()
        val context = MusicPlayContext("Mix", MusicPlayContextKind.PLAYLIST)
        val slow = async { music.playFetchedTracks(fetch = { gate.await() }, playContext = context) }
        testScheduler.runCurrent()
        music.playTracks(listOf(track("b")), playContext = context)
        gate.complete(listOf(track("a")))

        assertFalse(slow.await())
        assertEquals(listOf(listOf("b")), music.played.map { it.first })
    }

    @Test
    fun aFailedOrEmptyFetchGoesToItsHandlersWhileTheIntentIsCurrent() = runTest {
        val music = StubMusicPlayback()
        val context = MusicPlayContext("List", MusicPlayContextKind.PLAYLIST)
        var failed: Throwable? = null
        var empty = false
        assertFalse(music.playFetchedTracks(fetch = { error("boom") }, playContext = context, onError = { failed = it }))
        assertFalse(music.playFetchedTracks(fetch = { emptyList() }, playContext = context, onEmpty = { empty = true }))

        assertEquals("boom", failed?.message)
        assertTrue(empty)
        assertTrue(music.played.isEmpty())
    }

    @Test
    fun aTrackPlaysInsideItsAlbumAndAloneWhenTheAlbumLacksItOrFails() = runTest {
        val music = StubMusicPlayback()
        val inAlbum = track("t2", albumId = "album")
        val albumTracks = listOf(track("t1", albumId = "album"), inAlbum, track("t3", albumId = "album"))
        var albumFetch: suspend () -> List<MediaItem> = { albumTracks }
        val backend = object : FakeMediaBackend("srv") {
            override suspend fun fetchAlbumTracks(albumId: String): List<MediaItem> = albumFetch()
        }

        assertTrue(music.playTrackWithAlbumContext(inAlbum, backend))
        albumFetch = { listOf(track("other")) }
        music.playTrackWithAlbumContext(inAlbum, backend)
        albumFetch = { error("offline") }
        music.playTrackWithAlbumContext(inAlbum, backend)
        music.playTrackWithAlbumContext(track("loose"), null)

        assertEquals(
            listOf(
                Triple(listOf("t1", "t2", "t3"), "t2", MusicPlayContext("Album", MusicPlayContextKind.ALBUM)),
                Triple(listOf("t2"), null, MusicPlayContext("Track t2", MusicPlayContextKind.TRACKS)),
                Triple(listOf("t2"), null, MusicPlayContext("Track t2", MusicPlayContextKind.TRACKS)),
                Triple(listOf("loose"), null, MusicPlayContext("Track loose", MusicPlayContextKind.TRACKS)),
            ),
            music.played,
        )
    }
}
