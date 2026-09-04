package com.edde746.plezy.mpv

/**
 * Demuxer cache budget derived from the device heap class.
 *
 * mpv has no device-memory awareness: `demuxer-max-bytes` defaults to a fixed
 * 150 MiB forward (+50 MiB back) on every device and the demuxer fills
 * whatever it is allowed, which crowds a 1 GB TV box until Android's
 * low-memory killer takes the whole app. Tiered off
 * [android.app.ActivityManager.getLargeMemoryClass], the same signal
 * `stream_buffer_sizing.dart` and ExoPlayer's `LoadControlPolicy` use.
 *
 * Applied as pre-init *options* in [MpvPlayerCore], so a `demuxer-max-bytes`
 * line in the user's mpv.conf still wins.
 */
data class DemuxerBudget(val aheadBytes: Long, val backBytes: Long) {
  companion object {
    private const val MIB = 1024L * 1024L

    /** Null for an unknown class (<= 0): callers keep mpv's own defaults. */
    fun forHeapClassMB(largeMemoryClassMB: Int): DemuxerBudget? = when {
      largeMemoryClassMB <= 0 -> null
      largeMemoryClassMB <= 256 -> DemuxerBudget(aheadBytes = 32 * MIB, backBytes = 16 * MIB)
      largeMemoryClassMB <= 512 -> DemuxerBudget(aheadBytes = 64 * MIB, backBytes = 32 * MIB)
      else -> DemuxerBudget(aheadBytes = 100 * MIB, backBytes = 48 * MIB)
    }
  }
}
