package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.model.LyricLine
import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.music.MusicRepeatMode
import com.edde746.plezy.music.engine.AudioPlayerInitializationException
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class NowPlayingStoreTest {
    private val first = musicTrack("one", title = "First Track", album = "First Album", year = 1973)
    private val second = musicTrack("two", title = "Second Track", album = "Second Album", year = 1999)

    private fun test(tv: Boolean = false, block: suspend TestScope.(MusicHarness, NowPlayingStore) -> Unit) = runTest(UnconfinedTestDispatcher()) {
        val harness = MusicHarness(backgroundScope, tv = tv)
        harness.navigator.navigate(Route.NowPlaying)
        val store = harness.screens.nowPlaying()
        try {
            block(harness, store)
        } finally {
            store.close()
        }
    }

    @Test
    fun theSeekBarShowsTheTimePlayedAndTheTimeLeftAddingUpToTheTrack() {
        val progress = MusicProgress(position = 37.6.seconds, duration = 60.4.seconds)
        assertEquals("0:37", progress.positionLabel)
        assertEquals(T.player.remaining("0:23"), progress.remainingLabel)
        // A drag along the bar reads where it stands; at the end nothing is left.
        assertEquals("0:15", progress.positionAt(0.25))
        assertEquals(T.player.remaining("0:45"), progress.remainingAt(0.25))
        assertEquals(T.player.remaining("0:00"), progress.remainingAt(1.0))
    }

    @Test
    fun anAlbumQueueFollowsTheCurrentAlbumAcrossAlbums() = test { h, store ->
        h.playback.playing(first, MusicPlayContext("First Album", MusicPlayContextKind.ALBUM))
        assertEquals(T.music.playingFrom("First Album · 1973"), store.state.value.playingFrom)

        h.playback.playing(second)
        assertEquals(T.music.playingFrom("Second Album · 1999"), store.state.value.playingFrom)
    }

    @Test
    fun playlistPlaybackKeepsItsProvenanceLabel() = test { h, store ->
        h.playback.playing(first, MusicPlayContext("Road Trip", MusicPlayContextKind.PLAYLIST))
        assertEquals(T.music.playingFrom("Road Trip"), store.state.value.playingFrom)
    }

    @Test
    fun aPendingDpadSeekIsDiscardedWhenTheTrackChanges() = test(tv = true) { h, store ->
        h.playback.playing(first)
        store.stepSeek(forward = true, repeat = false)
        h.playback.playing(second)
        store.endStepSeek()
        testScheduler.advanceUntilIdle()
        assertEquals(emptyList(), h.playback.seeks)
    }

    @Test
    fun aDpadSeekAfterAnOutsideJumpStartsFromWhereTheJumpLanded() = test(tv = true) { h, store ->
        h.playback.playing(first)
        store.stepSeek(forward = true, repeat = false)
        store.endStepSeek()
        assertEquals(1, h.playback.seeks.size)
        val step = h.playback.seeks.single()
        assertTrue(step > Duration.ZERO)

        // The lock screen, a headset or the OS controls moved the playhead.
        h.playback.position.value = 2.minutes
        h.playback.playheadJumps.emit(2.minutes)

        store.stepSeek(forward = true, repeat = false)
        store.endStepSeek()
        assertEquals(2.minutes + step, h.playback.seeks.last())
    }

    @Test
    fun repeatedStepsGrowAndAddUpToOneSeek() = test(tv = true) { h, store ->
        h.playback.playing(first)
        store.stepSeek(forward = true, repeat = false)
        repeat(3) { store.stepSeek(forward = true, repeat = true) }
        assertEquals(emptyList(), h.playback.seeks)
        store.endStepSeek()
        assertEquals(1, h.playback.seeks.size)
        assertTrue(h.playback.seeks.single() >= 40.seconds)
    }

    @Test
    fun seekProgressResetsTheMomentTheTrackChanges() = test { h, store ->
        h.playback.playing(first)
        h.playback.position.value = 2.minutes
        assertEquals(2.minutes, store.progress.value.position)
        assertEquals(3.minutes, store.progress.value.duration)

        h.playback.state.value = h.playback.state.value.copy(currentTrack = second)
        assertEquals(Duration.ZERO, store.progress.value.position)
    }

    @Test
    fun aFailedAudioCoreIsNamedNotPrintedAsAnExceptionClass() = test { h, _ ->
        h.playback.playing(first)
        h.playback.errors.emit(AudioPlayerInitializationException("mpv_create failed"))
        h.playback.errors.emit(PlaybackException("No audio URL"))
        assertEquals(
            listOf(MusicMessage(T.messages.playbackFailed, error = true), MusicMessage(T.messages.errorLoading("No audio URL"), error = true)),
            h.messages,
        )
    }

    @Test
    fun anEndedSessionRemovesACoveredNowPlayingWithoutClosingTheScreenAbove() = test { h, _ ->
        h.playback.playing(first)
        val album = Route.MusicAlbum(SERVER, "album")
        h.navigator.navigate(album)

        h.playback.end()
        assertEquals(listOf(Route.Home, album), h.navigator.backStack.value)

        h.navigator.back()
        assertEquals(listOf<Route>(Route.Home), h.navigator.backStack.value)
    }

    @Test
    fun anEndedSessionClosesNowPlayingOnTopOnce() = test { h, _ ->
        h.playback.playing(first)
        h.playback.end()
        assertEquals(listOf<Route>(Route.Home), h.navigator.backStack.value)

        // The store that closed its screen never closes another.
        h.navigator.navigate(Route.NowPlaying)
        h.playback.playing(second)
        h.playback.end()
        assertEquals(listOf(Route.Home, Route.NowPlaying), h.navigator.backStack.value)
    }

    @Test
    fun theSleepTimerOffersTheVideoSetWithTheConfiguredMinutesAndMarksOnlyTheArmedOne() = test { h, store ->
        h.playback.playing(first)
        val minutes = listOf(5, 10, 15, 30, 45, 60, 90, 120).map { T.music.sleepTimerMinutes(it.toString()) }
        assertEquals(listOf(T.common.off, T.music.sleepTimerEndOfTrack) + minutes, store.state.value.sleepTimer.map { it.label })
        assertEquals(listOf(true) + List(9) { false }, store.state.value.sleepTimer.map { it.selected })

        store.setSleepTimer(SleepTimerChoice.Minutes(30))
        assertEquals(listOf(false, false, false, false, false, true, false, false, false, false), store.state.value.sleepTimer.map { it.selected })

        store.setSleepTimer(SleepTimerChoice.EndOfTrack)
        assertEquals(listOf(false, true) + List(8) { false }, store.state.value.sleepTimer.map { it.selected })

        // A configured length that isn't one of them takes its place among them.
        h.sleepTimerMinutes.value = 25
        assertEquals(
            listOf(5, 10, 15, 25, 30, 45, 60, 90, 120),
            store.state.value.sleepTimer.mapNotNull { (it.choice as? SleepTimerChoice.Minutes)?.minutes },
        )
    }

    @Test
    fun syncedLyricsHighlightThePlayingLineAndSeekToATappedOne() = test { h, store ->
        h.playback.lyrics = { Lyrics(synced = true, lines = listOf(LyricLine("a", 0), LyricLine("b", 10_000), LyricLine("", 20_000))) }
        h.playback.playing(first)
        assertEquals(emptyList(), h.playback.calls.filter { it.startsWith("lyrics") })

        store.toggleLyrics()
        assertEquals(LyricsUi.Lines(listOf("a", "b", "…"), synced = true), store.state.value.lyrics)
        assertEquals(0, store.activeLyricLine.value)
        h.playback.position.value = 15.seconds
        assertEquals(1, store.activeLyricLine.value)

        store.seekToLyric(2)
        assertEquals(listOf(20.seconds), h.playback.seeks)

        // Fetched once per track for the screen's life.
        store.toggleLyrics()
        store.toggleLyrics()
        assertEquals(listOf("lyrics:one"), h.playback.calls.filter { it.startsWith("lyrics") })
    }

    @Test
    fun `back on a track with the lyrics hidden showing them highlights the line and a tap seeks without a second fetch`() = test { h, store ->
        h.playback.lyrics = { Lyrics(synced = true, lines = listOf(LyricLine("a", 0), LyricLine("b", 10_000))) }
        h.playback.playing(first)
        store.toggleLyrics()
        store.toggleLyrics()
        h.playback.playing(second)
        h.playback.playing(first)

        store.toggleLyrics()
        assertEquals(LyricsUi.Lines(listOf("a", "b"), synced = true), store.state.value.lyrics)
        h.playback.position.value = 15.seconds
        assertEquals(1, store.activeLyricLine.value)
        store.seekToLyric(0)
        assertEquals(listOf(Duration.ZERO), h.playback.seeks)
        assertEquals(listOf("lyrics:one"), h.playback.calls.filter { it.startsWith("lyrics") })
    }

    @Test
    fun aTrackWithoutLyricsSaysSo() = test { h, store ->
        h.playback.playing(first)
        store.toggleLyrics()
        assertEquals(LyricsUi.None, store.state.value.lyrics)
    }

    @Test
    fun theQueueListsHistoryCurrentAndUpcomingWithoutTrackNumbers() = test { h, store ->
        val queue = listOf(
            musicTrack("t1", title = "Alpha", number = 7),
            musicTrack("t2", title = "Beta", number = 1),
            musicTrack("t3", title = "Gamma", number = 2),
        )
        h.playback.playing(queue[1], queue = queue)
        val ui = store.state.value.queue
        assertEquals(T.music.trackCount(3), ui.count)
        assertEquals(listOf("Alpha", "Beta", "Gamma"), ui.rows.map { it.title })
        assertEquals(1, ui.currentIndex)
        assertEquals(listOf(true, false, false), ui.rows.map { it.dimmed })
        assertEquals(listOf(null, null, null), ui.rows.map { it.trackNumber })
        assertEquals(listOf("Artist t1", "Artist t2", "Artist t3"), ui.rows.map { it.subtitle })

        store.jumpTo(2)
        store.jumpTo(0)
        assertEquals(listOf(2, 0), h.playback.jumps)
    }

    @Test
    fun theSameTrackTwiceInTheQueueGetsTwoKeys() = test { h, store ->
        val track = musicTrack("t1")
        h.playback.playing(track, queue = listOf(track, track), index = 0)
        assertEquals(listOf("$SERVER:t1#0", "$SERVER:t1#1"), store.state.value.queue.rows.map { it.key })
    }

    @Test
    fun repeatCyclesOffAllOneOff() = test { h, store ->
        h.playback.playing(first)
        val modes = (1..3).map {
            store.cycleRepeat()
            store.state.value.repeatMode
        }
        assertEquals(listOf(MusicRepeatMode.ALL, MusicRepeatMode.ONE, MusicRepeatMode.OFF), modes)
    }

    @Test
    fun previousAndNextAreEnabledOnlyWithAnEntryThatWay() = test { h, store ->
        h.playback.playing(first)
        assertFalse(store.state.value.canGoPrevious)
        assertFalse(store.state.value.canGoNext)

        h.playback.state.value = h.playback.state.value.copy(canGoPrevious = true, canGoNext = true)
        assertTrue(store.state.value.canGoPrevious)
        assertTrue(store.state.value.canGoNext)
    }

    @Test
    fun theVolumeSliderPreviewsThenPersists() = test { h, store ->
        h.playback.playing(first)
        store.previewVolume(40.0)
        assertEquals(40.0, store.volume.value)
        store.commitVolume(140.0)
        assertEquals(listOf("volume:40.0:false", "volume:100.0:true"), h.playback.calls.filter { it.startsWith("volume") })
        assertFalse(store.state.value.loading)
    }
}
