package com.edde746.plezy.libass.media.widget

import android.app.ActivityManager
import android.content.Context
import android.graphics.PixelFormat
import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.media3.common.util.UnstableApi
import com.edde746.plezy.libass.media.AssHandler

/**
 * Subtitle overlay rendered through a dedicated [SurfaceView] layer.
 *
 * Uses a SurfaceFlinger layer directly, which lets the atlas-based pipeline
 * vsync-align its swap with the corresponding video frame via
 * `eglPresentationTimeANDROID`.
 */
@UnstableApi
class AssSubtitleSurfaceView(
  context: Context,
  private val assHandler: AssHandler
) : SurfaceView(context),
  SurfaceHolder.Callback {

  private var pipeline: AssAtlasPipeline? = null
  private var preSwapProbe: ((Long) -> Unit)? = null

  init {
    setZOrderMediaOverlay(true)
    holder.setFormat(PixelFormat.TRANSLUCENT)
    holder.addCallback(this)
  }

  /**
   * Hook invoked on the GL thread just before each pinned overlay swap, with that swap's target
   * releaseTimeNs. Set by the app's latency calibrator; cleared (null) once it converges.
   * Survives pipeline recreation (re-applied in [surfaceCreated]).
   */
  fun setPreSwapProbe(hook: ((Long) -> Unit)?) {
    preSwapProbe = hook
    pipeline?.preSwapProbe = hook
  }

  fun requestRender(presentationTimeUs: Long, releaseTimeNs: Long) {
    pipeline?.requestRender(presentationTimeUs, releaseTimeNs)
  }

  /** Re-renders the last position, e.g. after margin changes while paused. */
  fun invalidateSubtitles() {
    pipeline?.invalidate()
  }

  /** Vsync-pinned swaps performed by the current pipeline. */
  val swapCount: Long get() = pipeline?.swapCount ?: 0L

  /** Pinned swaps that finished past the swap-time budget (possible missed vsync). */
  val lateSwapCount: Long get() = pipeline?.lateSwapCount ?: 0L

  /** Worst observed swap lateness past the target release time, in milliseconds. */
  val maxLateMs: Long get() = pipeline?.maxLateMs ?: 0L

  /** Total libass renders performed by the current pipeline. */
  val renderCount: Long get() = pipeline?.renderCount ?: 0L

  /** Renders where libass reported changed content. */
  val changedRenderCount: Long get() = pipeline?.changedRenderCount ?: 0L

  /** Renders that overflowed the atlas/vertex capacity. */
  val overflowCount: Long get() = pipeline?.overflowCount ?: 0L

  /** Duration of the most recent libass render, in milliseconds. */
  val lastLibassMs: Long get() = pipeline?.lastLibassMs ?: 0L

  /** Worst observed libass render duration, in milliseconds. */
  val maxLibassMs: Long get() = pipeline?.maxLibassMs ?: 0L

  /** Changed-render duration histogram: [≤10ms, ≤25ms, ≤42ms, ≤84ms, >84ms]. */
  val libassMsHistogram: List<Long> get() = pipeline?.libassMsHistogram ?: emptyList()

  /** Requests served from a pre-rendered (speculative) frame. */
  val specHits: Long get() = pipeline?.specHits ?: 0L

  /** Requests where speculation existed but didn't match (seek, state change). */
  val specMisses: Long get() = pipeline?.specMisses ?: 0L

  /** Speculation rounds skipped (paused, pending request, no confident cadence). */
  val specSkips: Long get() = pipeline?.specSkips ?: 0L

  /** changed==0/no-output renders forced into explicit transparent swaps. */
  val blankClearCount: Long get() = pipeline?.blankClearCount ?: 0L

  /** Cache-warming prefetch renders of upcoming events. */
  val prefetchCount: Long get() = pipeline?.prefetchCount ?: 0L

  /** Frame requests replaced before the libass worker serviced them. */
  val coalescedRequestCount: Long get() = pipeline?.coalescedRequestCount ?: 0L

  /** Completed libass results discarded because renderer state changed before handoff. */
  val staleGenerationCount: Long get() = pipeline?.staleGenerationCount ?: 0L

  /** Completed overlay snapshots skipped because newer completed content superseded them. */
  val supersededBeforeSwapCount: Long get() = pipeline?.supersededBeforeSwapCount ?: 0L

  /** Completed overlay snapshots skipped because renderer state changed before swap. */
  val staleBeforeSwapCount: Long get() = pipeline?.staleBeforeSwapCount ?: 0L

  /** Minimum lead of changed-content pinned swaps vs the video frame's release
   *  time, in ms (negative = late); null until one happened. */
  val minLeadChangedMs: Long? get() = pipeline?.minLeadChangedMs?.takeIf { it != Long.MAX_VALUE }

  /** Current compositor phase lead applied by the atlas pipeline, in ms. */
  val phaseLeadMs: Long get() = pipeline?.phaseLeadMs ?: 0L

  /** Most recent pinned swap lead vs its target release time, in ms. */
  val lastSwapLeadMs: Long get() = pipeline?.lastSwapLeadMs ?: 0L

  /** Most recent pinned swap headroom when GL work started, in ms. */
  val lastSwapHeadroomMs: Long get() = pipeline?.lastSwapHeadroomMs ?: 0L

  /** Most recent phase-led wait before swap, in ms. */
  val lastScheduledSleepMs: Long get() = pipeline?.lastScheduledSleepMs ?: 0L

  /** Adaptive swap lead actually in effect (half the measured refresh interval), in ms. */
  val swapLeadMs: Long get() = pipeline?.swapLeadMs ?: 0L

  /** True once the EGL frame-timestamp extension is probed and capturing present
   *  times (API 26+, real device). False on the emulator / pre-26 / no driver support. */
  val presentTimingEnabled: Boolean get() = pipeline?.presentTimingEnabled ?: false

  /** Active present-time source, or why it's off (present/comp-start/comp-latch/off:…). */
  val presentSource: String get() = pipeline?.presentSource ?: "off:no-pipeline"

  /** Actual on-screen present time of the most recent measured swap minus its
   *  target release time, in ms (negative = before the video frame's vsync). The
   *  frame-perfection ground truth; null until a swap has been measured. */
  val lastPresentErrorMs: Long? get() = pipeline?.lastPresentErrorMs.takeIf { presentMeasuredCount > 0 }

  /** Largest-magnitude present error observed, in ms; null until measured. */
  val worstPresentErrorMs: Long? get() = pipeline?.worstPresentErrorMs.takeIf { presentMeasuredCount > 0 }

  /** Pinned swaps whose actual present time was read back from SurfaceFlinger. */
  val presentMeasuredCount: Long get() = pipeline?.presentMeasuredCount ?: 0L

  /** Swaps SurfaceFlinger reported as dropped/never-presented. */
  val presentInvalidCount: Long get() = pipeline?.presentInvalidCount ?: 0L

  /** Pending present-time reads evicted unread because the ring filled. */
  val presentDroppedCount: Long get() = pipeline?.presentDroppedCount ?: 0L

  /** Present-error distribution in vsync-interval units:
   *  [≤−1.5, (−1.5,−0.5), (−0.5,+0.5), [+0.5,+1.5), ≥+1.5]. Middle = frame-perfect. */
  val presentErrorHistogram: List<Long> get() = pipeline?.presentErrorHistogram ?: emptyList()

  override fun surfaceCreated(holder: SurfaceHolder) {
    val rect = holder.surfaceFrame
    assHandler.setOverlaySurfaceSize(rect.width(), rect.height())
    val lowRam = (context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager)
      ?.isLowRamDevice ?: false
    // Display refresh drives the present-error histogram's vsync-relative buckets.
    val refreshRate = display?.refreshRate?.takeIf { it >= 1f } ?: 60f
    pipeline = AssAtlasPipeline(holder.surface, rect.width(), rect.height(), assHandler, lowRam, refreshRate)
      .also {
        it.preSwapProbe = preSwapProbe
        it.start()
      }
  }

  override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
    assHandler.setOverlaySurfaceSize(width, height)
    pipeline?.onSurfaceSizeChanged(width, height)
  }

  override fun surfaceDestroyed(holder: SurfaceHolder) {
    pipeline?.releaseAndWait()
    pipeline = null
  }
}
