package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor.AudioFormat
import java.nio.ByteBuffer
import java.nio.ByteOrder
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class EqualizerAudioProcessorTest {
  @Test
  fun flatCopiesStereoExactlyAndResetIsSafe() {
    val processor = EqualizerAudioProcessor()
    processor.configure(AudioFormat(48000, 2, C.ENCODING_PCM_16BIT))
    processor.flush()
    val input = ByteBuffer.allocateDirect(16).order(ByteOrder.nativeOrder())
    val samples = shortArrayOf(0, 1, -1, Short.MIN_VALUE, Short.MAX_VALUE, 4000, -2000, 0)
    for (sample in samples) input.putShort(sample)
    input.flip()
    processor.queueInput(input)
    val output = processor.output
    for (sample in samples) assertEquals(sample, output.short)
    assertEquals(0, input.remaining())
    assertTrue(processor.isActive)
    processor.reset()
    processor.reset()
  }

  @Test
  fun preampClipsAtPcmBoundsAndSurvivesFlush() {
    val processor = EqualizerAudioProcessor()
    processor.parameters = EqualizerParameters.create(List(10) { 0.0 }, 12.0, 0.0)
    processor.configure(AudioFormat(48000, 1, C.ENCODING_PCM_16BIT))
    processor.flush()
    repeat(2) {
      val input = ByteBuffer.allocateDirect(1024).order(ByteOrder.nativeOrder())
      repeat(512) { input.putShort(30000) }
      input.flip()
      processor.queueInput(input)
      val output = processor.output
      output.position(1000)
      assertEquals(Short.MAX_VALUE, output.short)
      processor.flush()
    }
  }
}
