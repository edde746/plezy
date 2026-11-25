package com.edde746.plezy.presentation.browse

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** How a backdrop turns through an item's backgrounds, skips the ones that fail and when it holds still. */
class BackdropRotationTest {
    private fun rotates(rotation: BackdropRotation, active: Boolean = true, visible: Boolean = true, reducedTier: Boolean = false, reducedMotion: Boolean = false) =
        BackdropRotation.rotates(rotation, active, visible, reducedTier, reducedMotion)

    @Test
    fun `rotates loaded backdrops in order and wraps`() {
        var rotation = BackdropRotation(3)
        val shown = mutableListOf<Int?>(rotation.current)
        repeat(3) {
            rotation = rotation.advance()
            shown += rotation.current
        }
        assertEquals(listOf<Int?>(0, 1, 2, 0), shown)
    }

    @Test
    fun `skips a missing incoming image without dropping the settled backdrop`() {
        // The second fails as it comes in: the rotation moves past it at once and never comes back to it.
        val rotation = BackdropRotation(3).advance().fail(1)
        assertEquals(2, rotation.current)
        assertEquals(0, rotation.advance().current)
        assertEquals(2, rotation.advance().advance().current)
    }

    @Test
    fun `reduced tier still advances past a broken first backdrop`() {
        val rotation = BackdropRotation(2).fail(0)
        assertEquals(1, rotation.current)
        assertFalse(rotates(rotation))
    }

    @Test
    fun `every backdrop failing leaves nothing to show`() {
        assertNull(BackdropRotation(2).fail(0).fail(1).current)
        assertNull(BackdropRotation(0).current)
    }

    @Test
    fun `keeps one backdrop static`() {
        assertFalse(rotates(BackdropRotation(1)))
        assertEquals(0, BackdropRotation(1).advance().current)
        assertTrue(rotates(BackdropRotation(2)))
    }

    @Test
    fun `pauses while the application is not resumed`() {
        assertFalse(rotates(BackdropRotation(3), visible = false))
        assertFalse(rotates(BackdropRotation(3), active = false))
    }

    @Test
    fun `does not auto rotate when reduced motion is requested`() {
        assertFalse(rotates(BackdropRotation(3), reducedMotion = true))
        assertEquals(0, BackdropRotation.fadeMillis(reducedTier = false, reducedMotion = true))
    }

    @Test
    fun `does not auto rotate on the reduced device tier`() {
        assertFalse(rotates(BackdropRotation(3), reducedTier = true))
        assertEquals(0, BackdropRotation.fadeMillis(reducedTier = true, reducedMotion = false))
        assertEquals(280, BackdropRotation.fadeMillis(reducedTier = false, reducedMotion = false))
    }
}
