package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.KeyModifiers
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** A remote's or keyboard's media keys in the player: they act on the press, and their repeats and releases go nowhere else. */
class MediaKeysTest {
    @Test
    fun playPauseTogglesOnThePressOnlyAndConsumesItsRepeatsAndRelease() {
        for (profile in InputProfile.entries) playerTest(profile) {
            playing()
            assertTrue(input(InputEvent.KeyDown(InputKey.MEDIA_PLAY_PAUSE, KeyModifiers.NONE)), "$profile: down")
            assertTrue(state.paused, "$profile: paused")
            assertTrue(input(InputEvent.KeyDown(InputKey.MEDIA_PLAY_PAUSE, KeyModifiers.NONE, repeat = true)), "$profile: repeat")
            assertTrue(state.paused, "$profile: a held key doesn't flicker")
            assertTrue(input(InputEvent.KeyUp(InputKey.MEDIA_PLAY_PAUSE)), "$profile: up")
            assertTrue(press(InputKey.MEDIA_PLAY_PAUSE))
            assertFalse(state.paused, "$profile: playing again")
        }
    }

    @Test
    fun playAndPauseKeysSetTheStateTheyName() = playerTest(InputProfile.TV) {
        playing()
        press(InputKey.MEDIA_PLAY)
        assertFalse(state.paused)
        press(InputKey.MEDIA_PAUSE)
        assertTrue(state.paused)
        press(InputKey.MEDIA_PAUSE)
        assertTrue(state.paused)
        press(InputKey.MEDIA_PLAY)
        assertFalse(state.paused)
    }

    /** An unconsumed fast-forward reached the media session, which skipped its own 15 s once per repeat. */
    @Test
    fun aFastForwardKeySeeksAndIsConsumed() = playerTest(InputProfile.TV) {
        playing(position = 240.0)
        assertTrue(input(InputEvent.KeyDown(InputKey.MEDIA_FAST_FORWARD, KeyModifiers.NONE)), "down")
        assertTrue(input(InputEvent.KeyDown(InputKey.MEDIA_FAST_FORWARD, KeyModifiers.NONE, repeat = true)), "repeat")
        assertTrue(input(InputEvent.KeyUp(InputKey.MEDIA_FAST_FORWARD)), "up")
        assertEquals(true, engine.seeks.lastOrNull()?.let { it.first > 240.0 }, "sought forward")
    }
}
