package com.edde746.plezy.playback.session

import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class SimulatedHttpErrorTest {
    @Test
    fun aSimulatedStatusFailsTheOpenAsHttpAndItsStatus() {
        assertEquals(EngineError("HTTP 500", 500, EngineErrorKind.OPEN), SimulatedHttpError.of(500))
    }

    @Test
    fun eachSimulatedStatusNamesTheCauseARealOneWould() {
        assertEquals(FailureCause.SERVER_HTTP_500, SimulatedHttpError.cause(500))
        assertEquals(FailureCause.SERVER_HTTP_404, SimulatedHttpError.cause(404))
        assertEquals(FailureCause.SERVER_HTTP_503, SimulatedHttpError.cause(503))
        assertNull(SimulatedHttpError.cause(401))
    }
}
