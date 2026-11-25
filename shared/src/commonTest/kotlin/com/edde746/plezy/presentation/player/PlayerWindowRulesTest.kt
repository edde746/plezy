package com.edde746.plezy.presentation.player

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class PlayerWindowRulesTest {
    @Test
    fun aHandheldGetsEveryOrientationBackAndTheLandscapeLockWhenLocked() {
        assertEquals(OrientationRequest.LANDSCAPE, PlayerOrientationRules.whilePlaying(rotationLocked = true, platformOwnsOrientation = false))
        assertEquals(OrientationRequest.ALL, PlayerOrientationRules.whilePlaying(rotationLocked = false, platformOwnsOrientation = false))
        assertEquals(OrientationRequest.ALL, PlayerOrientationRules.onExit(platformOwnsOrientation = false))
    }

    /** Asking a TV for every orientation lets it turn the app upside down. */
    @Test
    fun aTvOrACarIsNeverSentAnOrientation() {
        assertNull(PlayerOrientationRules.whilePlaying(rotationLocked = true, platformOwnsOrientation = true))
        assertNull(PlayerOrientationRules.whilePlaying(rotationLocked = false, platformOwnsOrientation = true))
        assertNull(PlayerOrientationRules.onExit(platformOwnsOrientation = true))
    }

    @Test
    fun reHidesTheBarsWhileOwnedNotAfterRelease() {
        var hides = 0
        val guard = ImmersiveModeGuard { hides++ }
        val owner = Any()
        guard.acquire(owner)
        guard.onSystemBarsChanged(visible = true)
        assertEquals(1, hides)

        guard.release(owner)
        guard.onSystemBarsChanged(visible = true)
        assertEquals(1, hides)
    }

    @Test
    fun barsStayingHiddenIsNotAReShow() {
        var hides = 0
        val guard = ImmersiveModeGuard { hides++ }
        guard.acquire(Any())
        guard.onSystemBarsChanged(visible = false)
        assertEquals(0, hides)
    }

    @Test
    fun aPredecessorReleasingAfterItsSuccessorAcquiredKeepsTheSuccessorOwning() {
        var hides = 0
        val guard = ImmersiveModeGuard { hides++ }
        val predecessor = Any()
        val successor = Any()
        guard.acquire(predecessor)
        guard.acquire(successor)
        guard.release(predecessor)
        guard.onSystemBarsChanged(visible = true)
        assertEquals(1, hides)

        guard.release(successor)
        guard.onSystemBarsChanged(visible = true)
        assertEquals(1, hides)
    }
}
