package com.edde746.plezy

import android.content.pm.ActivityInfo
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PlayerOrientationTest {
    @Test
    fun `a fold an unfold or a display switch is told from a rotation`() {
        assertTrue(PlayerOrientation.isDisplaySwitch(ActivityInfo.CONFIG_SMALLEST_SCREEN_SIZE or ActivityInfo.CONFIG_SCREEN_SIZE))
        assertTrue(PlayerOrientation.isDisplaySwitch(ActivityInfo.CONFIG_SCREEN_LAYOUT))
        assertTrue(PlayerOrientation.isDisplaySwitch(ActivityInfo.CONFIG_SCREEN_SIZE))
        assertFalse(PlayerOrientation.isDisplaySwitch(ActivityInfo.CONFIG_SCREEN_SIZE or ActivityInfo.CONFIG_ORIENTATION))
        assertFalse(PlayerOrientation.isDisplaySwitch(ActivityInfo.CONFIG_UI_MODE))
    }
}
