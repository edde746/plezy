package com.edde746.plezy.livetv.playback

import com.edde746.plezy.livetv.LiveTvBackgroundPolicy
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TvBackgroundPolicyTest {
    @Test
    fun aTvBackgroundStopsASessionThatCantBeKept() {
        assertTrue(shouldStopLiveSessionForTvBackground(tv = true, policy = LiveTvBackgroundPolicy.STOP_AND_EXIT))
    }

    @Test
    fun aTvBackgroundKeepsACaptureBufferSession() {
        assertFalse(shouldStopLiveSessionForTvBackground(tv = true, policy = LiveTvBackgroundPolicy.RETAIN_SESSION))
    }

    @Test
    fun anotherDevicesBackgroundStopsNothing() {
        assertFalse(shouldStopLiveSessionForTvBackground(tv = false, policy = LiveTvBackgroundPolicy.STOP_AND_EXIT))
    }
}
