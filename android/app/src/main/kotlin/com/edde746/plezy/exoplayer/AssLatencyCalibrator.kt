package com.edde746.plezy.exoplayer

import android.os.Build
import android.view.SurfaceControl
import android.view.SurfaceView
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Auto-calibrates [ExoPlayerCore]'s subtitle/video layer offset by measuring, per device, how much
 * later the codec VIDEO plane reaches the display than the GL subtitle OVERLAY plane — the
 * inter-plane latency (a deep video VPP on TV boxes) that otherwise makes subtitles a frame ahead.
 *
 * Both planes are pinned to the same video-frame target (releaseTimeNs). Measuring BOTH with the
 * same mechanism — [SurfaceTxProbe] + the API-34 previous-release fence — the per-SoC buffer-recycle
 * bias cancels in the difference, leaving the pure offset:
 *
 *   offsetFrames = round( (median(videoReleaseVsTarget) − median(overlayReleaseVsTarget)) / frameMs )
 *
 * This is a MEDIAN-of-each-plane model, NOT a per-frame paired difference: every sample is
 * self-paired to its own frame's target, and the per-plane release-vs-target is a steady hardware
 * constant, so the two medians need not come from the same frames — only from the same (stable)
 * device. Both medians use a recent-sample window so they stay roughly contemporaneous, and a
 * confidence gate refuses to converge on an ambiguous (~half-frame) result.
 *
 * Video samples arrive every few frames from the metadata listener (codec thread); overlay samples
 * from the libass GL thread's pre-swap hook (sparse — only when subtitles swap). Once both planes
 * have enough samples and the result is confident it converges ONCE, applies + persists, and stops
 * all probing (zero steady-state overhead). Re-runs each play to re-confirm.
 *
 * Threads: probeVideo (codec), probeOverlay (libass GL), onResult (probe reader). The lock guards
 * only counter/sample state and is NEVER held across the binder/JNI `applyTransactionToFrame` call
 * (so the GL swap path is never stalled by it). The native slot ring is allocated atomically.
 */
internal class AssLatencyCalibrator(
  private val videoSurface: SurfaceView,
  private val overlaySurface: SurfaceView,
  private val onCalibrated: (Int) -> Unit,
  private val onDone: () -> Unit,
  private val log: (String) -> Unit
) {
  private val lock = Any()
  private val finished = AtomicBoolean(false)
  private val applyFail = AtomicInteger(0)

  @Volatile private var frameIntervalNs: Long = 0L

  @Volatile private var converged = false

  @Volatile private var stopped = false

  private var videoFrames = 0
  private var videoAttempts = 0
  private var overlaySwaps = 0
  private var overlayAttempts = 0
  private val videoRel = ArrayDeque<Double>()
  private val overlayRel = ArrayDeque<Double>()

  fun start() {
    SurfaceTxProbe.sink = { tag, latch, release, count, state, source, cb ->
      onResult(tag, latch, release, count, state, source, cb)
    }
    log("calibration started (API ${Build.VERSION.SDK_INT})")
  }

  fun probeVideo(releaseTimeNs: Long, fps: Float) {
    if (stopped || converged || Build.VERSION.SDK_INT < 34) return
    if (fps > 1f) frameIntervalNs = (1_000_000_000.0 / fps).toLong()
    var doAttach = false
    var giveUp = false
    synchronized(lock) {
      videoFrames++
      if (videoFrames > GIVEUP_FRAMES) {
        giveUp = true
      } else if (videoAttempts < VIDEO_ATTEMPT_CAP && videoFrames % VIDEO_EVERY == 0) {
        videoAttempts++
        doAttach = true
      }
    }
    if (giveUp) {
      finishIncomplete()
    } else if (doAttach) {
      attach(videoSurface, releaseTimeNs, SurfaceTxProbe.SOURCE_VIDEO)
    }
  }

  fun probeOverlay(releaseTimeNs: Long) {
    if (stopped || converged || Build.VERSION.SDK_INT < 34) return
    var doAttach = false
    synchronized(lock) {
      overlaySwaps++
      if (overlayAttempts < OVERLAY_ATTEMPT_CAP && overlaySwaps % OVERLAY_EVERY == 0) {
        overlayAttempts++
        doAttach = true
      }
    }
    if (doAttach) attach(overlaySurface, releaseTimeNs, SurfaceTxProbe.SOURCE_OVERLAY)
  }

  /** Never called while holding [lock]: applyTransactionToFrame is a binder call and runs on the
   *  GL swap path. The native slot allocation is atomic, so concurrent callers are safe. */
  private fun attach(surface: SurfaceView, releaseTimeNs: Long, source: Int) {
    try {
      val tx = SurfaceControl.Transaction()
      SurfaceTxProbe.nativeAttach(tx, releaseTimeNs, source)
      surface.applyTransactionToFrame(tx)
    } catch (t: Throwable) {
      if (applyFail.incrementAndGet() == 1) {
        log("applyTransactionToFrame failed: ${t.javaClass.simpleName}: ${t.message}")
      }
    }
  }

  private fun onResult(
    tag: Long,
    latchNs: Long,
    releaseNs: Long,
    surfaceCount: Int,
    fenceState: Int,
    source: Int,
    callbackNs: Long
  ) {
    if (surfaceCount <= 0 || fenceState != FENCE_OK || releaseNs <= 0) return
    val relMs = (releaseNs - tag) / 1_000_000.0
    var result: Int? = null
    synchronized(lock) {
      if (converged || stopped) return
      val list = if (source == SurfaceTxProbe.SOURCE_OVERLAY) overlayRel else videoRel
      val window = if (source == SurfaceTxProbe.SOURCE_OVERLAY) OVERLAY_WINDOW else VIDEO_WINDOW
      list.addLast(relMs)
      while (list.size > window) list.removeFirst() // keep a recent window so medians stay fresh
      result = tryComputeOffset()
    }
    result?.let {
      onCalibrated(it)
      finish()
    }
  }

  private fun tryComputeOffset(): Int? {
    val frameMs = frameIntervalNs / 1_000_000.0
    if (frameMs <= 0.5) return null
    if (videoRel.size < VIDEO_MIN || overlayRel.size < OVERLAY_MIN) return null
    val medV = median(videoRel)
    val medO = median(overlayRel)
    val offsetMs = medV - medO
    val raw = offsetMs / frameMs
    val frames = raw.roundToInt()
    // Confidence gate: only trust a measurement that points clearly at an integer frame count.
    // An ambiguous ~half-frame result (corruption / drift / wrong fps) keeps collecting instead.
    if (abs(raw - frames) > CONFIDENCE_TOL) return null
    val clamped = frames.coerceIn(-2, 2)
    converged = true
    log(
      "CALIBRATED offsetFrames=$clamped raw=${"%.2f".format(raw)} " +
        "(video=${"%.1f".format(medV)}ms − overlay=${"%.1f".format(medO)}ms = ${"%.1f".format(offsetMs)}ms " +
        "/ frameMs=${"%.2f".format(frameMs)}) samples video=${videoRel.size} overlay=${overlayRel.size} " +
        "applyFail=${applyFail.get()}"
    )
    return clamped
  }

  private fun finishIncomplete() {
    if (converged || stopped) return
    log(
      "calibration incomplete after $videoFrames frames " +
        "(video=${videoRel.size} overlay=${overlayRel.size}); keeping seed"
    )
    finish()
  }

  fun stop() = finish()

  private fun finish() {
    if (!finished.compareAndSet(false, true)) return
    stopped = true
    SurfaceTxProbe.sink = null
    onDone()
  }

  private fun median(xs: Collection<Double>): Double {
    val s = xs.sorted()
    val n = s.size
    return if (n % 2 == 1) s[n / 2] else (s[n / 2 - 1] + s[n / 2]) / 2.0
  }

  companion object {
    private const val FENCE_OK = 3
    private const val VIDEO_EVERY = 2
    private const val OVERLAY_EVERY = 1 // overlay swaps are already sparse
    private const val VIDEO_MIN = 40
    private const val OVERLAY_MIN = 12
    private const val VIDEO_WINDOW = 60 // recent-sample window for the median
    private const val OVERLAY_WINDOW = 40
    private const val VIDEO_ATTEMPT_CAP = 200 // ~16s @24fps/2 of video probing, then the window freezes
    private const val OVERLAY_ATTEMPT_CAP = 60
    private const val CONFIDENCE_TOL = 0.33 // |raw − round(raw)| must be within ⅓ frame to converge
    private const val GIVEUP_FRAMES = 1800 // ~75s @24fps without enough confident overlay samples
  }
}
