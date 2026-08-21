package com.edde746.plezy.exoplayer

import java.nio.ByteBuffer

/**
 * The IEC 61937 carrier tuple every packed bitstream rides: 192kHz, 7.1, PCM-16 shaped.
 *
 * This is the high-bitrate HDMI shape Kodi uses for both TrueHD/MAT and DTS-HD Master Audio, and
 * the one [supportsIecCarrier] probes. The 44.1kHz family would need a 176.4kHz sibling, which is
 * deliberately not built; streams from that family decode instead.
 */
internal object IecCarrier {
  const val SAMPLE_RATE = 192_000
  const val CHANNEL_COUNT = 8
  const val BYTES_PER_FRAME = CHANNEL_COUNT * 2
}

/**
 * Splits one codec's bitstream into access units and packs them into IEC 61937 bursts for
 * [IecCarrierSink].
 *
 * Implementations are not thread safe; the sink drives them from the playback thread only.
 */
internal interface IecCarrierPacker {

  /**
   * Length in bytes of the access unit starting at [offset], or 0 when no unit boundary is
   * recognised there. May latch [unsupportedStream] when the boundary is recognisable but names a
   * framing this carrier cannot ride.
   */
  fun accessUnitLength(data: ByteArray, offset: Int, limit: Int): Int

  /**
   * Packs one access unit, returning a completed burst or null when this unit did not finish one.
   *
   * Returned buffers are owned by the packer and reused, alternating between two so a burst handed
   * downstream stays valid while the next one fills. Callers must submit or copy it before the
   * second following call.
   */
  fun packAccessUnit(data: ByteArray, offset: Int, length: Int): ByteBuffer?

  /**
   * True when the bitstream announced a shape this carrier cannot ride. The packer emits nothing
   * in that state; the sink latches the stream onto the decoder instead.
   */
  val unsupportedStream: Boolean

  /** Drops all carrier state. Called on flush/seek: bursts must not straddle a discontinuity. */
  fun reset()
}
