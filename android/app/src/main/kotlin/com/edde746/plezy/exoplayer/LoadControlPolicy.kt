package com.edde746.plezy.exoplayer

/**
 * Auto sizing for [androidx.media3.exoplayer.DefaultLoadControl]'s `targetBufferBytes` (#1618).
 *
 * A byte cap collapses as bitrate rises: 64 MiB is 53s of a 10 Mbit/s stream but 5.2s of a
 * 103 Mbit/s UHD remux. With `prioritizeTimeOverSizeThresholds = false` the cap is hard, so
 * read-ahead that short starves the audio sink in bursts — enough, on some routes, to keep a
 * passthrough AudioTrack from ever starting.
 *
 * The tiers this replaced came from mpv demuxer OOM tuning and handed ExoPlayer a flat
 * 64 MiB, under half of what media3 would pick for the same selection
 * ([MEDIA3_DEFAULT_TARGET_BYTES]). The fix is not "buffer more than upstream", it is "stop
 * buffering less unless the heap requires it".
 *
 * Not bitrate-aware: the `LoadControl` is built during `initialize`, before any media is
 * opened, so a byte budget is all that is knowable.
 */
internal object LoadControlPolicy {
  private const val MIB = 1024 * 1024

  /**
   * media3's own `calculateTargetBufferBytes` for a video + audio selection: 2000 + 200
   * segments at `C.DEFAULT_BUFFER_SEGMENT_SIZE` (64 KiB). A ceiling, never exceeded here.
   */
  const val MEDIA3_DEFAULT_TARGET_BYTES = 2200 * 64 * 1024

  /**
   * Floor, kept at the lowest tier that has already shipped, and it wins over the budgets
   * below — going under it reintroduces the starvation this policy exists to prevent.
   */
  const val MIN_TARGET_BYTES = 32 * MIB

  /**
   * Fraction of a memory budget the allocator may claim. Matches the threshold the Buffer
   * Size setting already warns at (`value > heapMB / 4`).
   */
  private const val BUDGET_DIVISOR = 4

  /**
   * @param largeHeapMB `ActivityManager.largeMemoryClass` — the hard Java-heap ceiling for
   *   this process, which is what bounds `DefaultAllocator` (it hands out `byte[]`).
   *   Non-positive when unknown.
   * @param availableMB `ActivityManager.MemoryInfo.availMem`, so a device that is currently
   *   under pressure does not get sized purely off its theoretical heap. Non-positive when
   *   unknown.
   */
  fun autoTargetBufferBytes(largeHeapMB: Int, availableMB: Int): Int {
    var budget = MEDIA3_DEFAULT_TARGET_BYTES.toLong()
    if (largeHeapMB > 0) budget = minOf(budget, largeHeapMB.toLong() / BUDGET_DIVISOR * MIB)
    if (availableMB > 0) budget = minOf(budget, availableMB.toLong() / BUDGET_DIVISOR * MIB)
    return maxOf(budget, MIN_TARGET_BYTES.toLong()).toInt()
  }

  /** Seconds of media a budget covers at [bitrateBps], for logs. Null when unknown. */
  fun readAheadSeconds(targetBufferBytes: Int, bitrateBps: Long): Double? {
    if (bitrateBps <= 0L) return null
    return targetBufferBytes * 8.0 / bitrateBps
  }
}
