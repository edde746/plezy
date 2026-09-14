package com.edde746.plezy.mpv

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The surface vote and the display-mode target must agree on when a stream
 * is presented as fields; the measured cadence is the only signal for a
 * decoder that deinterlaces on its own.
 */
class PresentedFrameRateTest {
  @Test
  fun aDecoderEmittingFieldsIsMeasuredFromTheCadence() {
    // NVIDIA/Amlogic MediaCodec: 29.97i in, 59.94 frames out, no mpv filter.
    assertTrue(PresentedFrameRate.presentsFields(29.97003, 59.94006, deinterlaceActive = false))
    // Matroska millisecond rounding on the first sample: 16 ms or 17 ms fields.
    assertTrue(PresentedFrameRate.presentsFields(29.97003, 1000.0 / 16, deinterlaceActive = false))
    assertTrue(PresentedFrameRate.presentsFields(29.97003, 1000.0 / 17, deinterlaceActive = false))
    assertTrue(PresentedFrameRate.presentsFields(25.0, 50.0, deinterlaceActive = false))
  }

  @Test
  fun mpvsOwnDeinterlacerCountsEvenBeforeACadenceExists() {
    assertTrue(PresentedFrameRate.presentsFields(29.97003, null, deinterlaceActive = true))
  }

  @Test
  fun progressiveAndIrregularCadencesAreNotFields() {
    assertFalse(PresentedFrameRate.presentsFields(23.976, 23.976, deinterlaceActive = false))
    // Telecined 23.976 in a 29.97 container and a 3:2 cadence read as 1.25x.
    assertFalse(PresentedFrameRate.presentsFields(23.976, 29.97, deinterlaceActive = false))
    // A duplicated or dropped first frame is not a field pattern.
    assertFalse(PresentedFrameRate.presentsFields(29.97003, 89.91, deinterlaceActive = false))
    assertFalse(PresentedFrameRate.presentsFields(29.97003, 14.985, deinterlaceActive = false))
    // Nothing measured yet, or no container rate to compare against.
    assertFalse(PresentedFrameRate.presentsFields(29.97003, null, deinterlaceActive = false))
    assertFalse(PresentedFrameRate.presentsFields(0.0, 59.94, deinterlaceActive = false))
  }
}
