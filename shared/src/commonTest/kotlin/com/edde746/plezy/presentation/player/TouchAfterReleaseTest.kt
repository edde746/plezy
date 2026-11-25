package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.TouchPhase
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A finger still on the glass as the player goes (its failure view, a new player, closing) keeps sending its moves and
 * lift: with the store released they find nothing left to drive.
 */
class TouchAfterReleaseTest {
    @Test
    fun aBrightnessSwipeStillMovingAfterTheControlsUnmountNeitherThrowsNorWrites() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            val pointer = nextPointer()
            touch(TouchPhase.DOWN, pointer, 40f to 400f)
            touch(TouchPhase.MOVE, pointer, 40f to 316f)
            assertTrue(levels.brightnessWrites.isNotEmpty(), "the swipe is live as the player goes")

            store.release()
            val writes = levels.brightnessWrites.size
            touch(TouchPhase.MOVE, pointer, 40f to 250f)
            touch(TouchPhase.UP, pointer, 40f to 250f)
            assertEquals(writes, levels.brightnessWrites.size, "nothing overrides the brightness the exit gave back")
            assertEquals(1, levels.restores)
        }
    }

    @Test
    fun aTwoFingerTapLiftingAfterTheControlsUnmountLeavesPlaybackAlone() = touchTest {
        val first = nextPointer()
        val second = nextPointer()
        touch(TouchPhase.DOWN, first, 380f to 300f)
        touch(TouchPhase.DOWN, second, 420f to 300f)
        store.release()
        touch(TouchPhase.UP, first, 380f to 300f)
        touch(TouchPhase.UP, second, 420f to 300f)
        assertEquals(emptyList(), engine.paused)
    }
}
