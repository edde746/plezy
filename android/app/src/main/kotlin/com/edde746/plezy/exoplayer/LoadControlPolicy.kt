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

  /** `DefaultLoadControl` play-start threshold on a first buffer. */
  const val BUFFER_FOR_PLAYBACK_MS = 1_000

  /**
   * `DefaultLoadControl` play-start threshold after a rebuffer. Below this the player is
   * *supposed* to stay in `STATE_BUFFERING`, so anything judging a buffering player has to clear
   * this bar before it can call the wait anomalous — see [BufferingStallPolicy].
   */
  const val BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS = 5_000

  /**
   * Fraction of a memory budget the allocator may claim. Matches the threshold the Buffer
   * Size setting already warns at (`value > heapMB / 4`).
   */
  private const val BUDGET_DIVISOR = 4

  /**
   * Memory tier below which the shipped Auto durations stay conservative, in
   * `ActivityManager.MemoryInfo.availMem` MiB.
   */
  private const val LOW_MEMORY_MB = 2048

  /** Auto durations, by memory tier. These are the values that shipped before #1816. */
  private const val AUTO_MIN_BUFFER_LOW_MEMORY_MS = 15_000
  private const val AUTO_MAX_BUFFER_LOW_MEMORY_MS = 50_000
  private const val AUTO_MIN_BUFFER_MS = 30_000
  private const val AUTO_MAX_BUFFER_MS = 60_000

  /**
   * How deep the loader may read ahead.
   *
   * Named tiers rather than a duration, because a duration would be a promise this cannot keep:
   * `prioritizeTimeOverSizeThresholds` is disabled, so `targetBufferBytes` stops the loader even
   * below `minBufferMs`, and effective read-ahead is `min(maxBufferMs, 8 * bytes / bitrate)`. On a
   * high bitrate stream the byte term wins whatever is chosen here. The tiers therefore describe
   * an intent — how much network variance to absorb — and the Buffer Size setting bounds the
   * memory it may cost.
   *
   * Values match jellyfin-androidtv and jellyfin-android so a user moving between Jellyfin clients
   * gets the same behaviour from the same words.
   */
  enum class BufferTier(val minBufferMs: Int, val maxBufferMs: Int) {
    /** Memory-tiered defaults, resolved per device in [bufferDurations]. */
    AUTO(0, 0),

    /** For moderate or variable connections. */
    LARGE(50_000, 120_000),

    /** For slow or high-latency links, where a stall costs more than the memory does. */
    EXTRA_LARGE(80_000, 240_000);

    companion object {
      /**
       * Wire values are the Dart enum's `nativeValue`. An unknown string means a Dart/Kotlin
       * skew, and [AUTO] is the only safe reading of "I do not know what this user asked for".
       */
      fun fromWire(value: String?): BufferTier = when (value) {
        "large" -> LARGE
        "extra_large" -> EXTRA_LARGE
        else -> AUTO
      }
    }
  }

  /** The min/max pair handed to `DefaultLoadControl.Builder.setBufferDurationsMs`. */
  data class BufferDurations(val minBufferMs: Int, val maxBufferMs: Int)

  /**
   * Read-ahead duration bounds for this session.
   *
   * The returned pair always satisfies the ordering media3 asserts on
   * (`bufferForPlayback* <= minBufferMs <= maxBufferMs`). That is enforced here rather than
   * trusted, because media3 validates with Guava `Preconditions` — an unconditional throw that
   * R8 does not elide — so a bad pair is an `IllegalArgumentException` out of
   * `DefaultLoadControl.Builder.build()` on a user's device, not a degraded buffer.
   *
   * @param availableMB `ActivityManager.MemoryInfo.availMem`. Non-positive when unknown, which
   *   is treated as the low-memory tier.
   */
  fun bufferDurations(tier: BufferTier, availableMB: Int): BufferDurations {
    val playStartFloor = maxOf(BUFFER_FOR_PLAYBACK_MS, BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS)
    val (rawMin, rawMax) = if (tier == BufferTier.AUTO) {
      if (availableMB <= LOW_MEMORY_MB) {
        AUTO_MIN_BUFFER_LOW_MEMORY_MS to AUTO_MAX_BUFFER_LOW_MEMORY_MS
      } else {
        AUTO_MIN_BUFFER_MS to AUTO_MAX_BUFFER_MS
      }
    } else {
      tier.minBufferMs to tier.maxBufferMs
    }
    val minBufferMs = rawMin.coerceAtLeast(playStartFloor)
    return BufferDurations(minBufferMs, rawMax.coerceAtLeast(minBufferMs))
  }

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
