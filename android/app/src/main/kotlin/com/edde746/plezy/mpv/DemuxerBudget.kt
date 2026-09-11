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
     * the cost is a re-download on a backward seek, not a rebuffer. The
     * forward budget drops to [CRITICAL_AHEAD_BYTES] only once the device is
     * critical, because shrinking read-ahead on a slow link forces a rebuffer
     * exactly when the device is already struggling.
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
    fun forTrimLevel(largeMemoryClassMB: Int, level: Int): DemuxerBudget? {
      val steady = forHeapClassMB(largeMemoryClassMB) ?: return null
      return when (level) {
        ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
        ComponentCallbacks2.TRIM_MEMORY_COMPLETE -> DemuxerBudget(aheadBytes = CRITICAL_AHEAD_BYTES, backBytes = 0)
        ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW,
        ComponentCallbacks2.TRIM_MEMORY_BACKGROUND,
        ComponentCallbacks2.TRIM_MEMORY_MODERATE -> steady.copy(backBytes = 0)
        // Nothing to give back. Null rather than the steady budget: the caller
        // ratchets one way, so returning it could only ever be a no-op.
        else -> null
      }
    }
  }
}
