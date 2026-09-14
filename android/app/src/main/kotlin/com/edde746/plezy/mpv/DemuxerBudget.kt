package com.edde746.plezy.mpv

import android.content.ComponentCallbacks2

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
 * line in the user's mpv.conf still wins; [forTrimLevel] re-derives it from
 * the same table when Android reports memory pressure, and the core writes
 * that as a property mid-session.
 */
data class DemuxerBudget(val aheadBytes: Long, val backBytes: Long) {
  /**
   * This budget narrowed to [wanted], never widened. Pressure response is
   * one-way inside a session: re-growing while the device is still thrashing
   * is how the app got killed in the first place, and a milder trim level
   * arriving after a harsher one asks for exactly that. The next
   * initialization starts from the full tier again.
   */
  fun narrowedTo(wanted: DemuxerBudget): DemuxerBudget = DemuxerBudget(aheadBytes = minOf(aheadBytes, wanted.aheadBytes), backBytes = minOf(backBytes, wanted.backBytes))

  companion object {
    private const val MIB = 1024L * 1024L

    /** Tier boundaries. */
    private const val TIGHT_TIER_MAX_MB = 256
    private const val MID_TIER_MAX_MB = 512

    /**
     * The forward budget a critical device is held to. Named rather than
     * looked back out of the table: the tightest tier's forward bound is
     * already the floor of every tier, so deriving it only bought a non-null
     * assertion and a comparison that could not change the answer.
     */
    private const val CRITICAL_AHEAD_BYTES = 32L * 1024L * 1024L

    /**
     * Seconds of content the forward budget must still cover at a critical
     * level, because read-ahead is only ever spent in seconds: the same
     * 32 MiB is 13 s of a 20 Mbps episode and 3.4 s of an 80 Mbps UHD remux.
     * The byte clamp cut #2314's 4K direct play from ~8.5 s of cushion to
     * 3.4 s, one-way for the session, which is what turned the server's ~10 s
     * read stalls from a brief audio dropout into a full rebuffer. Six seconds
     * is the content window `stream_buffer_sizing.dart` sizes the stream ring
     * for.
     */
    private const val CRITICAL_AHEAD_SECONDS = 6

    /**
     * Shortest cached span [streamByteRate] measures a rate from. Less than
     * this is a cache filling after a seek or already starving, so the ratio
     * would be noise.
     */
    private const val MIN_MEASURABLE_CACHE_SECONDS = 1.0

    /** Null for an unknown class (<= 0): callers keep mpv's own defaults. */
    fun forHeapClassMB(largeMemoryClassMB: Int): DemuxerBudget? = when {
      largeMemoryClassMB <= 0 -> null
      largeMemoryClassMB <= TIGHT_TIER_MAX_MB -> DemuxerBudget(aheadBytes = 32 * MIB, backBytes = 16 * MIB)
      largeMemoryClassMB <= MID_TIER_MAX_MB -> DemuxerBudget(aheadBytes = 64 * MIB, backBytes = 32 * MIB)
      else -> DemuxerBudget(aheadBytes = 100 * MIB, backBytes = 48 * MIB)
    }

    /**
     * The budget to hold while Android reports memory pressure at [level]
     * (a `ComponentCallbacks2.TRIM_MEMORY_*` value), or null when the level
     * asks for nothing back.
     *
     * The back cache goes first: `demuxer-donate-buffer` defaults on, so the
     * back cache absorbs forward bytes the reader has not claimed and the
     * resident ceiling is really ahead+back. Dropping it is also the only
     * reclaim that cannot stall playback - the reader never reads from it, so
     * the cost is a re-download on a backward seek, not a rebuffer. Read-ahead
     * is only bounded once the device is critical, and then only down to
     * [criticalAheadBytes] of [streamByteRate]: shrinking it further forces a
     * rebuffer exactly when the device is already struggling.
     *
     * `TRIM_MEMORY_UI_HIDDEN` and `TRIM_MEMORY_RUNNING_MODERATE` ask for
     * nothing: neither says the device is short on memory, and the audio-only
     * core keeps playing through both. Note the constants are not ordered by
     * severity (`RUNNING_CRITICAL` is 15, `UI_HIDDEN` 20), so this matches
     * levels by name rather than comparing them.
     *
     * Android 14 (API 34) stopped delivering the `RUNNING_*` levels and
     * `onLowMemory` altogether; `UI_HIDDEN` and `BACKGROUND` are all that
     * arrive there. The devices this exists for are the 1-2 GB TV boxes
     * (Fire OS 7/8) that still deliver the full set, and
     * `adb shell am send-trim-memory` delivers any level on any version.
     */
    fun forTrimLevel(largeMemoryClassMB: Int, level: Int, streamByteRate: Long = 0L): DemuxerBudget? {
      val steady = forHeapClassMB(largeMemoryClassMB) ?: return null
      return when (level) {
        ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
        ComponentCallbacks2.TRIM_MEMORY_COMPLETE -> DemuxerBudget(
          aheadBytes = criticalAheadBytes(steady.aheadBytes, streamByteRate),
          backBytes = 0
        )
        ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW,
        ComponentCallbacks2.TRIM_MEMORY_BACKGROUND,
        ComponentCallbacks2.TRIM_MEMORY_MODERATE -> steady.copy(backBytes = 0)
        // Nothing to give back. Null rather than the steady budget: the caller
        // ratchets one way, so returning it could only ever be a no-op.
        else -> null
      }
    }

    /**
     * The forward budget a critical device is held to: [CRITICAL_AHEAD_BYTES]
     * or [CRITICAL_AHEAD_SECONDS] of [streamByteRate], whichever is larger,
     * and never more than [steadyAheadBytes] - there is nothing to reclaim
     * above what the tier granted. A zero rate leaves the byte floor alone.
     */
    fun criticalAheadBytes(steadyAheadBytes: Long, streamByteRate: Long): Long = minOf(maxOf(CRITICAL_AHEAD_BYTES, streamByteRate * CRITICAL_AHEAD_SECONDS), steadyAheadBytes)

    /**
     * Bytes per second of the stream being played, or 0 when neither signal
     * is usable.
     *
     * The file average ([fileBytes] / [fileSeconds], mpv's `file-size` and
     * `duration`) covers the whole session but understates local peaks -
     * #2314's file averages 57.7 Mbps and plays 81 Mbps stretches. The cached
     * span ([cachedBytes] / [cachedSeconds], `fw-bytes` and
     * `demuxer-cache-duration`) measures the region actually playing but is
     * unusable while the cache is shallow. Read-ahead has to survive the
     * peak, so the larger wins.
     */
    fun streamByteRate(cachedBytes: Long, cachedSeconds: Double, fileBytes: Long, fileSeconds: Double): Long {
      val cached = if (cachedBytes > 0 && cachedSeconds >= MIN_MEASURABLE_CACHE_SECONDS) {
        (cachedBytes / cachedSeconds).toLong()
      } else {
        0L
      }
      val average = if (fileBytes > 0 && fileSeconds > 0.0) (fileBytes / fileSeconds).toLong() else 0L
      return maxOf(cached, average)
    }
  }
}
