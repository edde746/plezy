package com.edde746.plezy.media

import android.view.KeyEvent
import com.edde746.plezy.music.KeyPhase
import com.edde746.plezy.music.MusicKey
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** The hardware keys the music session takes in the foreground: the track keys apart from the in-track skips. */
class MusicKeysTest {
    @Test
    fun transportKeysMapToTheirCommands() {
        assertEquals(MusicKey.PLAY, musicKey(KeyEvent.KEYCODE_MEDIA_PLAY))
        assertEquals(MusicKey.PAUSE, musicKey(KeyEvent.KEYCODE_MEDIA_PAUSE))
        assertEquals(MusicKey.PLAY_PAUSE, musicKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE))
        assertEquals(MusicKey.STOP, musicKey(KeyEvent.KEYCODE_MEDIA_STOP))
    }

    @Test
    fun trackKeysChangeTrackAndSkipKeysSeek() {
        assertEquals(MusicKey.NEXT, musicKey(KeyEvent.KEYCODE_MEDIA_NEXT))
        assertEquals(MusicKey.PREVIOUS, musicKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS))
        assertEquals(MusicKey.FAST_FORWARD, musicKey(KeyEvent.KEYCODE_MEDIA_FAST_FORWARD))
        assertEquals(MusicKey.FAST_FORWARD, musicKey(KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD))
        assertEquals(MusicKey.REWIND, musicKey(KeyEvent.KEYCODE_MEDIA_REWIND))
        assertEquals(MusicKey.REWIND, musicKey(KeyEvent.KEYCODE_MEDIA_SKIP_BACKWARD))
    }

    @Test
    fun otherKeysAreNotMusics() {
        assertNull(musicKey(KeyEvent.KEYCODE_DPAD_CENTER))
        assertNull(musicKey(KeyEvent.KEYCODE_SPACE))
        assertNull(musicKey(KeyEvent.KEYCODE_VOLUME_UP))
    }

    @Test
    fun theFirstDownActsAndRepeatsAndTheReleaseAreTheirOwnPhases() {
        assertEquals(KeyPhase.DOWN, keyPhase(KeyEvent.ACTION_DOWN, repeatCount = 0))
        assertEquals(KeyPhase.REPEAT, keyPhase(KeyEvent.ACTION_DOWN, repeatCount = 3))
        assertEquals(KeyPhase.UP, keyPhase(KeyEvent.ACTION_UP, repeatCount = 0))
    }
}
