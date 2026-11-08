package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The video decoder waits at `on_preloaded` only for the open that armed the
 * hold, and only until that open's release (#2998): a hold that leaks into
 * another open delays its picture by the whole hold timeout.
 */
class DecoderHoldTest {
  private val answers = mutableListOf<Pair<Long, Map<String, Any?>?>>()

  private fun DecoderHold.armRecording(token: Long) = arm(token) { answers += token to it }

  private val format = mapOf<String, Any?>("fps" to 23.976, "width" to 3840, "height" to 2160)

  @Test
  fun aHeldDecoderWaitsForItsOwnTokensRelease() {
    val gate = DecoderHold()
    gate.armRecording(1)
    gate.onFileStarted()

    val hold = gate.take()!!
    hold.answer(format)
    assertEquals(listOf(1L to format), answers)

    gate.release(2)
    assertFalse(hold.released.isCompleted)
    gate.release(1)
    assertTrue(hold.released.isCompleted)
    // Taken once: the next file of the same open is not held.
    assertNull(gate.take())
  }

  @Test
  fun aNewerArmSupersedesTheArmedOneAndOutlivesItsRelease() {
    val gate = DecoderHold()
    gate.armRecording(1)
    gate.armRecording(2)
    assertEquals(listOf(1L to null), answers)

    // The superseded open's late release must not cancel the newer arm.
    gate.release(1)
    assertEquals(2L, gate.take()!!.token)
  }

  @Test
  fun anArmIsCancelledByItsOwnFileEndingNotThePreviousOnes() {
    val gate = DecoderHold()
    gate.armRecording(1)
    // The file the open replaces ends before the armed file starts.
    gate.onFileEnded()
    assertTrue(answers.isEmpty())

    gate.onFileStarted()
    // The armed file failed before its hook.
    gate.onFileEnded()
    assertEquals(listOf(1L to null), answers)
    assertNull(gate.take())
  }

  @Test
  fun aReleaseBeforeTheHookCancelsTheArm() {
    val gate = DecoderHold()
    gate.armRecording(1)
    gate.release(1)
    assertEquals(listOf(1L to null), answers)
    assertNull(gate.take())
  }

  @Test
  fun closeAnswersTheArmLetsTheHeldDecoderGoAndRefusesNewArms() {
    val gate = DecoderHold()
    gate.armRecording(1)
    val held = gate.take()!!
    gate.armRecording(2)

    gate.close()
    assertTrue(held.released.isCompleted)
    assertEquals(listOf(2L to null), answers)

    gate.armRecording(3)
    assertEquals(listOf(2L to null, 3L to null), answers)
    assertNull(gate.take())
  }

  @Test
  fun aFinishedHoldIgnoresItsLateRelease() {
    val gate = DecoderHold()
    gate.armRecording(1)
    val first = gate.take()!!
    gate.finish(first)
    gate.armRecording(2)
    val second = gate.take()!!

    gate.release(1)
    assertFalse(second.released.isCompleted)
  }
}
