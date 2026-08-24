package com.edde746.plezy.exoplayer

/**
 * Rolling average bitrate of one demuxed stream, measured from packet sizes
 * over their presentation-time span — the same source of truth mpv uses for
 * its `audio-bitrate` property. It exists because containers frequently
 * declare no per-track bitrate (Matroska without BPS statistics tags), which
 * left the performance overlay with nothing to show (#2063).
 *
 * Fed from the loader thread ([onPacket]) and read from the stats path
 * ([bitrateBps]); both are synchronized. The measurement follows the demux
 * position, which runs ahead of the playhead by the buffered duration —
 * acceptable for a diagnostics overlay.
 */
internal class StreamBitrateMeter(private val windowUs: Long = DEFAULT_WINDOW_US) {

  private val ptsUsQueue = ArrayDeque<Long>()
  private val sizeQueue = ArrayDeque<Int>()
  private var windowBytes = 0L

  @Synchronized
  fun onPacket(ptsUs: Long, sizeBytes: Int) {
    if (sizeBytes <= 0) return
    // A backwards pts jump is a seek; packets on either side of it do not
    // form a contiguous span, so the window restarts.
    val last = ptsUsQueue.lastOrNull()
    if (last != null && ptsUs < last) reset()
    ptsUsQueue.addLast(ptsUs)
    sizeQueue.addLast(sizeBytes)
    windowBytes += sizeBytes
    while (ptsUsQueue.size > 1 && ptsUsQueue.last() - ptsUsQueue.first() > windowUs) {
      ptsUsQueue.removeFirst()
      windowBytes -= sizeQueue.removeFirst()
    }
  }

  /**
   * Average bitrate in bits per second over the current window, or null until
   * enough packets span a measurable interval.
   */
  @Synchronized
  fun bitrateBps(): Int? {
    if (ptsUsQueue.size < MIN_PACKETS) return null
    val spanUs = ptsUsQueue.last() - ptsUsQueue.first()
    if (spanUs <= 0) return null
    // The pts span covers the durations of every packet except the last one,
    // whose bytes are therefore excluded — a constant-rate stream measures
    // exactly its rate.
    val bytes = windowBytes - sizeQueue.last()
    if (bytes <= 0) return null
    return (bytes * 8_000_000L / spanUs).toInt()
  }

  @Synchronized
  fun reset() {
    ptsUsQueue.clear()
    sizeQueue.clear()
    windowBytes = 0L
  }

  companion object {
    private const val DEFAULT_WINDOW_US = 10_000_000L
    private const val MIN_PACKETS = 16
  }
}
