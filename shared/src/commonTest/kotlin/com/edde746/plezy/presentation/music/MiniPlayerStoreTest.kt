package com.edde746.plezy.presentation.music

import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.navigation.Route
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class MiniPlayerStoreTest {
    private val dawn = musicTrack("dawn", title = "Dawn", artist = "Test Artist")

    private fun test(tv: Boolean = false, block: suspend TestScope.(MusicHarness, MiniPlayerStore) -> Unit) = runTest(UnconfinedTestDispatcher()) {
        val harness = MusicHarness(backgroundScope, tv = tv)
        val store = harness.screens.miniPlayer()
        try {
            block(harness, store)
        } finally {
            store.close()
        }
    }

    @Test
    fun appearsWhenTheSessionHasATrack() = test { h, store ->
        assertFalse(store.state.value.visible)
        assertNull(store.state.value.track)

        h.playback.playing(dawn)
        val state = store.state.value
        assertTrue(state.visible)
        assertEquals("Dawn", state.track?.title)
        assertEquals("Test Artist", state.track?.artist)
        assertTrue(state.isPlaying)
    }

    @Test
    fun staysHiddenWhileNowPlayingOrThePlayerIsOnTop() = test { h, store ->
        h.playback.playing(dawn)
        h.navigator.navigate(Route.NowPlaying)
        assertFalse(store.state.value.visible)

        // A screen opened over Now Playing brings it back.
        h.navigator.navigate(Route.MusicArtist(SERVER, "artist"))
        assertTrue(store.state.value.visible)

        h.navigator.navigate(Route.Player)
        assertFalse(store.state.value.visible)
    }

    @Test
    fun staysHiddenWhileASheetIsOpen() = test { h, store ->
        h.playback.playing(dawn)
        h.navigator.navigate(Route.MusicArtist(SERVER, "artist"))
        h.navigator.navigate(Route.SeerrRequest(1, MediaKind.MOVIE, "Film"))
        assertFalse(store.state.value.visible)

        h.navigator.back()
        assertTrue(store.state.value.visible)
    }

    @Test
    fun neverShowsOnTvWhereTheRailNamesNowPlaying() = test(tv = true) { h, store ->
        h.playback.playing(dawn)
        assertFalse(store.state.value.visible)
        assertTrue(store.state.value.railItem)

        h.offline.value = true
        assertFalse(store.state.value.railItem)
    }

    @Test
    fun theRailItemIsTvOnly() = test { h, store ->
        h.playback.playing(dawn)
        assertFalse(store.state.value.railItem)
    }

    @Test
    fun dismissingHidesAtOnceAndStopsTheSession() = test { h, store ->
        h.playback.playing(dawn)
        store.dismiss()
        assertFalse(store.state.value.visible)
        assertEquals(listOf("stop"), h.playback.calls)

        // The next session shows the card again.
        h.playback.playing(dawn)
        assertTrue(store.state.value.visible)
    }

    @Test
    fun progressResetsTheMomentTheTrackChanges() = test { h, store ->
        h.playback.playing(dawn)
        h.playback.position.value = 90.seconds
        assertEquals(0.5f, store.progress.value)

        h.playback.state.value = h.playback.state.value.copy(currentTrack = musicTrack("next"))
        assertEquals(0f, store.progress.value)
    }

    @Test
    fun theCardTapOpensNowPlaying() = test { h, store ->
        h.playback.playing(dawn)
        store.open()
        store.open()
        assertEquals(listOf(Route.Home, Route.NowPlaying), h.navigator.backStack.value)
    }

    @Test
    fun transportButtonsDriveTheSession() = test { h, store ->
        h.playback.playing(dawn)
        store.previous()
        store.togglePlayPause()
        store.next()
        assertEquals(listOf("previous", "toggle", "next"), h.playback.calls)
        assertEquals(listOf<Route>(Route.Home), h.navigator.backStack.value)
    }

    @Test
    fun previousAndNextAreEnabledOnlyWithAnEntryThatWay() = test { h, store ->
        h.playback.playing(dawn)
        assertFalse(store.state.value.canGoPrevious)
        assertFalse(store.state.value.canGoNext)

        h.playback.state.value = h.playback.state.value.copy(canGoPrevious = true, canGoNext = true)
        assertTrue(store.state.value.canGoPrevious)
        assertTrue(store.state.value.canGoNext)
    }

    @Test
    fun aDurationlessTrackShowsNoProgress() = test { h, store ->
        h.playback.playing(dawn)
        h.playback.state.value = h.playback.state.value.copy(duration = null)
        h.playback.position.value = 1.minutes
        assertEquals(0f, store.progress.value)
    }
}
