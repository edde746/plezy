package com.edde746.plezy.mpv

import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.VideoInfo
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The video decoder waits at `on_preloaded` only for the open that armed the hold, and only until that open's release:
 * a hold that leaks into another open delays its picture by the whole hold timeout.
 */
class DecoderHoldGateTest {
    private val answers = mutableListOf<Pair<Long, VideoInfo?>>()

    private fun DecoderHoldGate.armRecording(token: Long) = arm(token) { answers += token to it }

    private val video = VideoInfo(3840, 2160, null, 23.976, DynamicRange.SDR)

    @Test
    fun aHeldDecoderWaitsForItsOwnTokensRelease() {
        val gate = DecoderHoldGate()
        gate.armRecording(1)
        gate.onFileStarted()

        val hold = gate.take()!!
        hold.answer(video)
        assertEquals(listOf<Pair<Long, VideoInfo?>>(1L to video), answers)

        gate.release(2)
        assertFalse(hold.released.isCompleted)
        gate.release(1)
        assertTrue(hold.released.isCompleted)
        // Taken once: the next file of the same open is not held.
        assertNull(gate.take())
    }

    @Test
    fun aNewerArmSupersedesTheArmedOneAndOutlivesItsRelease() {
        val gate = DecoderHoldGate()
        gate.armRecording(1)
        gate.armRecording(2)
        assertEquals(listOf<Pair<Long, VideoInfo?>>(1L to null), answers)

        // The superseded open's late release must not cancel the newer arm.
        gate.release(1)
        assertEquals(2L, gate.take()!!.token)
    }

    @Test
    fun anArmIsCancelledByItsOwnFileEndingNotThePreviousOnes() {
        val gate = DecoderHoldGate()
        gate.armRecording(1)
        // The file the open replaces ends before the armed file starts.
        gate.onFileEnded()
        assertTrue(answers.isEmpty())

        gate.onFileStarted()
        // The armed file failed before its hook.
        gate.onFileEnded()
        assertEquals(listOf<Pair<Long, VideoInfo?>>(1L to null), answers)
        assertNull(gate.take())
    }

    @Test
    fun aReleaseBeforeTheHookCancelsTheArm() {
        val gate = DecoderHoldGate()
        gate.armRecording(1)
        gate.release(1)
        assertEquals(listOf<Pair<Long, VideoInfo?>>(1L to null), answers)
        assertNull(gate.take())
    }

    @Test
    fun closeAnswersTheArmLetsTheHeldDecoderGoAndRefusesNewArms() {
        val gate = DecoderHoldGate()
        gate.armRecording(1)
        val held = gate.take()!!
        gate.armRecording(2)

        gate.close()
        assertTrue(held.released.isCompleted)
        assertEquals(listOf<Pair<Long, VideoInfo?>>(2L to null), answers)

        gate.armRecording(3)
        assertEquals(listOf<Pair<Long, VideoInfo?>>(2L to null, 3L to null), answers)
        assertNull(gate.take())
    }

    @Test
    fun aFinishedHoldIgnoresItsLateRelease() {
        val gate = DecoderHoldGate()
        gate.armRecording(1)
        val first = gate.take()!!
        gate.finish(first)
        gate.armRecording(2)
        val second = gate.take()!!

        gate.release(1)
        assertFalse(second.released.isCompleted)
    }
}
