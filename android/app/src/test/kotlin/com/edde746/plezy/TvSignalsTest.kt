package com.edde746.plezy

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Which devices count as a TV. */
class TvSignalsTest {
    private val phone = TvSignals(
        isAutomotive = false,
        isTelevisionUiMode = false,
        hasTelevisionFeature = false,
        hasLeanback = false,
        hasFireTvFeature = false,
        hasTouchscreen = true,
    )

    @Test
    fun aPhoneIsNoTv() {
        assertFalse(phone.isTv)
        assertEquals(emptyList(), phone.reasons)
    }

    @Test
    fun anySingleTvSignalMakesATv() {
        val cases = mapOf(
            phone.copy(isTelevisionUiMode = true) to "ui_mode_television",
            phone.copy(hasTelevisionFeature = true) to "television_feature",
            phone.copy(hasLeanback = true) to "leanback",
            phone.copy(hasFireTvFeature = true) to "fire_tv",
            phone.copy(hasTouchscreen = false) to "no_touchscreen",
        )
        for ((signals, reason) in cases) {
            assertTrue(signals.isTv, reason)
            assertEquals(listOf(reason), signals.reasons)
        }
    }

    @Test
    fun aCarIsNeverATvWhateverItReports() {
        val car = phone.copy(isAutomotive = true, hasLeanback = true, hasTouchscreen = false)
        assertFalse(car.isTv)
        assertEquals(listOf("leanback", "no_touchscreen"), car.reasons)
    }
}
