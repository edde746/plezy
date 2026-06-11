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

  init {
    setZOrderMediaOverlay(true)
    holder.setFormat(PixelFormat.TRANSLUCENT)
    holder.addCallback(this)
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

  /** Cache-warming prefetch renders of upcoming events. */
  val prefetchCount: Long get() = pipeline?.prefetchCount ?: 0L

  /** Minimum lead of changed-content pinned swaps vs the video frame's release
   *  time, in ms (negative = late); null until one happened. */
  val minLeadChangedMs: Long? get() = pipeline?.minLeadChangedMs?.takeIf { it != Long.MAX_VALUE }

  override fun surfaceCreated(holder: SurfaceHolder) {
    val rect = holder.surfaceFrame
    assHandler.setOverlaySurfaceSize(rect.width(), rect.height())
    val lowRam = (context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager)
      ?.isLowRamDevice ?: false
    pipeline = AssAtlasPipeline(holder.surface, rect.width(), rect.height(), assHandler, lowRam)
      .also { it.start() }
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
