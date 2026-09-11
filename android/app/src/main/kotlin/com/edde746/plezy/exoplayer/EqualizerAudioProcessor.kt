package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor.AudioFormat
import androidx.media3.common.audio.AudioProcessor.UnhandledAudioFormatException
import androidx.media3.common.audio.BaseAudioProcessor
import java.nio.ByteBuffer
import kotlin.math.roundToInt

/** PCM16 processor in the normal audio sink, after stereo downmix. */
class EqualizerAudioProcessor : BaseAudioProcessor() {
  @Volatile var parameters = EqualizerParameters.FLAT
  private var equalizer: PcmEqualizer? = null

  override fun onConfigure(inputAudioFormat: AudioFormat): AudioFormat {
    if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) throw UnhandledAudioFormatException(inputAudioFormat)
    // Stay in the pipeline while flat so live edits need no sink reconfiguration.
    return inputAudioFormat
  }

  override fun onFlush() {
    equalizer = if (inputAudioFormat == AudioFormat.NOT_SET) null else PcmEqualizer(inputAudioFormat.sampleRate, inputAudioFormat.channelCount)
  }

  override fun onReset() {
    equalizer = null
    // The player owns parameters; seeks and renderer recovery must retain them.
  }

  override fun queueInput(inputBuffer: ByteBuffer) {
    val processor = checkNotNull(equalizer)
    processor.update(parameters)
    val output = replaceOutputBuffer(inputBuffer.remaining())
    val channels = inputAudioFormat.channelCount
    while (inputBuffer.hasRemaining()) {
      for (channel in 0 until channels) {
        val input = inputBuffer.short / 32768.0
        val sample = (processor.process(input, channel) * 32768.0).roundToInt().coerceIn(-32768, 32767)
        output.putShort(sample.toShort())
      }
    }
    output.flip()
  }
}
