package com.edde746.plezy.presentation.player

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Remember brightness: with it on, the level a brightness swipe settled on is kept and the next playback opens at it;
 * closing the player still gives the screen its own brightness back.
 */
class RememberBrightnessTest {
    private val remembering = PlayerChoices(rememberBrightness = true)

    @Test
    fun playbackOpensAtTheRememberedLevelAndExitStillRestores() {
        val levels = FakeLevels()
        touchTest(levels = levels, preferences = remembering.copy(rememberedBrightness = 0.35)) {
            assertEquals(listOf(0.35), levels.brightnessWrites)
            store.release()
            assertEquals(1, levels.restores, "leaving the player doesn't leave the rest of the app dimmed")
        }
    }

    @Test
    fun anUnsetRememberedLevelWritesNothingAtStartup() {
        val levels = FakeLevels()
        touchTest(levels = levels, preferences = remembering) {
            assertEquals(emptyList(), levels.brightnessWrites)
        }
    }

    @Test
    fun withTheToggleOffAStoredLevelIsLeftAloneAtStartup() {
        val levels = FakeLevels()
        touchTest(levels = levels, preferences = PlayerChoices(rememberedBrightness = 0.35)) {
            assertEquals(emptyList(), levels.brightnessWrites)
        }
    }

    @Test
    fun aDisabledBrightnessSwipeNeverReappliesARememberedLevel() {
        val levels = FakeLevels()
        touchTest(levels = levels, preferences = remembering.copy(rememberedBrightness = 0.35, brightnessSwipe = false)) {
            assertEquals(emptyList(), levels.brightnessWrites)
        }
    }

    @Test
    fun aFinishedBrightnessSwipePersistsTheLevelItSettledOn() {
        val levels = FakeLevels()
        touchTest(levels = levels, preferences = remembering) {
            edgeSwipe(x = 40f)
            assertEquals(0.7, levels.brightnessWrites.last(), 1e-6)
            assertEquals(0.7, preferences.choices.value.rememberedBrightness, 1e-6)
        }
    }

    @Test
    fun withTheToggleOffABrightnessSwipePersistsNothing() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            edgeSwipe(x = 40f)
            assertTrue(levels.brightnessWrites.isNotEmpty(), "the swipe itself works without the toggle")
            assertEquals(-1.0, preferences.choices.value.rememberedBrightness)
        }
    }

    @Test
    fun aVolumeSwipeNeverWritesTheRememberedBrightness() {
        val levels = FakeLevels()
        touchTest(levels = levels, preferences = remembering) {
            edgeSwipe(x = WIDTH - 40f)
            assertTrue(levels.volumeWrites.isNotEmpty())
            assertEquals(-1.0, preferences.choices.value.rememberedBrightness)
        }
    }
}
