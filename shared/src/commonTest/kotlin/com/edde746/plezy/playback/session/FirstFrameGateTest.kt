package com.edde746.plezy.playback.session

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertSame
import kotlin.test.assertTrue

class FirstFrameGateTest {
    @Test
    fun markReadyLatchesBothReportingAndUiReadiness() {
        val gate = FirstFrameGate()
        gate.markReady()
        assertTrue(gate.rendered)
        assertTrue(gate.uiReady.value)
    }

    @Test
    fun forcingTheUiReadyOnFailureHidesTheSpinnerWithoutLatchingRendered() {
        val gate = FirstFrameGate()
        gate.forceUiReadyOnFailure()
        assertTrue(gate.uiReady.value, "the spinner hides on a startup failure")
        assertFalse(gate.rendered, "reporting readiness is stricter than the UI's")
    }

    @Test
    fun resetUiForOpenLeavesTheReportingLatch() {
        val gate = FirstFrameGate().apply { markReady() }
        gate.resetUiForOpen()
        assertFalse(gate.uiReady.value)
        assertTrue(gate.rendered)
    }

    @Test
    fun resetRenderedForAttemptLeavesUiReadiness() {
        val gate = FirstFrameGate().apply { markReady() }
        gate.resetRenderedForAttempt()
        assertFalse(gate.rendered)
        assertTrue(gate.uiReady.value)
    }

    @Test
    fun resetClearsBoth() {
        val gate = FirstFrameGate().apply { markReady() }
        gate.reset()
        assertFalse(gate.rendered)
        assertFalse(gate.uiReady.value)
    }

    @Test
    fun aSnapshotRestoresADivergedStateAcrossAFailedReplacement() {
        val gate = FirstFrameGate().apply { forceUiReadyOnFailure() }
        val snapshot = gate.snapshot()
        gate.reset()
        gate.restore(snapshot)
        assertTrue(gate.uiReady.value)
        assertFalse(gate.rendered)
    }

    @Test
    fun uiReadyKeepsItsIdentityAcrossResets() {
        val gate = FirstFrameGate()
        val flow = gate.uiReady
        gate.markReady()
        gate.reset()
        gate.restore(FirstFrameGate.Snapshot(uiReady = true, rendered = true))
        assertSame(flow, gate.uiReady)
        assertTrue(flow.value)
    }
}
