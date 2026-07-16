package com.edde746.plezy.libass.media.widget

import android.opengl.EGL14
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.opengl.GLES20
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Process
import android.util.Log
import android.view.Surface
import androidx.media3.common.C
import androidx.media3.common.util.GlProgram
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import com.edde746.plezy.libass.AssAtlasFrame
import com.edde746.plezy.libass.AssFrameTimestamps
import com.edde746.plezy.libass.media.AssHandler
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import java.util.concurrent.locks.LockSupport

/**
 * Atlas-rendering pipeline behind [AssSubtitleSurfaceView].
 * Runs libass on its own [HandlerThread] into a packed ALPHA_8 atlas of one or more
 * pages plus a vertex stream, and a GL thread that uploads both and issues one
 * `glDrawArrays` per atlas page. Each timed swap is pinned to the corresponding
 * video frame via [EGLExt.eglPresentationTimeANDROID].
 */
@UnstableApi
internal object AssAtlasPipelineConfig {
  /** Flip to `true` for `adb logcat -s AssSurfaceGlThread:D AssLibassThread:D` traces. */
  internal const val TIMING_LOGS = false

  /** Fallback atlas row width when GL caps are unknown (EGL init failed/slow). */
  internal const val FALLBACK_ATLAS_W = 2048

  /** Fallback atlas height; 2048 × 4096 = 8 MB matches the long-proven default. */
  internal const val FALLBACK_ATLAS_H = 4096

  /**
   * Pixel budget per atlas slot once GL caps are known: 4096×4096 or 2048×8192
   * (16 MB ALPHA_8). Sized so heavy typesetting (full-screen gradients/blurs)
   * fits where the old fixed 2048×4096 overflowed and dropped frames.
   */
  internal const val ATLAS_PIXEL_BUDGET = 16 * 1024 * 1024

  /** Preallocated vertex-stream capacity (192 bytes × 16384 = 3 MB per buffer). */
  internal const val MAX_QUADS = 16384

  /**
   * Hard cap on vertically-stacked atlas pages per slot. A frame whose packed
   * sub-pixels exceed one [ATLAS_PIXEL_BUDGET] texture (a 4K-rendered full-screen
   * typeset sign) spills into extra pages so nothing is dropped (#1436); the atlas
   * buffer grows on demand toward this cap. 4 covers the worst frame measured (a 4K
   * letter needs 3); past it tiles are dropped and counted in `truncated`. Must match
   * MAX_ATLAS_PAGES in AssKt.c.
   */
  internal const val MAX_ATLAS_PAGES = 4

  /** Must match the byte layout produced by `nativeAssRenderFrameAtlas` in AssKt.c. */
  internal const val BYTES_PER_VERTEX = 32
  internal const val BYTES_PER_QUAD = BYTES_PER_VERTEX * 6

  /**
   * Kill switch for speculative render-ahead (see [SpecRenderEngine]) and the
   * event prefetch. With it off (or on low-RAM devices, which stay at 2 slots)
   * every request renders on-demand inside the video frame's release deadline —
   * the pre-speculation behavior.
   *
   * Only pays off when typical changed renders fit the speculation coverage
   * window (~frame interval + release budget): with the un-optimized (-O0)
   * native core's 90ms+ renders it could only add overhead; with the -O3/NEON
   * core's ~35-50ms renders it converts near-misses into on-time latches.
   */
  internal const val SPECULATION_ENABLED = true

  /**
   * Disabled by default: queueing subtitles one predicted video frame ahead made
   * Android playback often look one frame early. Keep the estimator behind a flag
   * in case a device-specific compositor path later proves it needs this again.
   */
  internal const val COMPOSITOR_PHASE_LEAD_ENABLED = false

  /**
   * Internal raster resolution for the libass overlay, as a fraction of the
   * physical surface (1.0 = full, off). Lowering it shrinks the libass frame so
   * heavy/animated signs rasterize over fewer pixels (raster cost ∝ area; layout
   * cost unchanged) and the GL upscales the result to the full surface — a
   * quality-for-throughput trade for render-bound low-end TVs. Applied
   * consistently to the libass frame size, the mpv-style margins ([AssHandler])
   * and the GL `u_SurfaceSize` ([AtlasRenderer]); at 1.0 it is an exact no-op.
   * Runtime-settable from the user's "Render Resolution" subtitle setting (Android exposes
   * Full / ¾ / ½ / ⅓ / ¼) via [AssHandler.setRenderScale]; 1.0 = exact no-op (the default).
   */
  @Volatile
  internal var renderScale = 1.0f

  /** Scales a physical-pixel extent to the libass render resolution; identity at 1.0. */
  internal fun scaledForRender(px: Int): Int = if (renderScale == 1.0f) px else Math.round(px * renderScale)
}

internal class AtlasPayload(
  val slotIndex: Int,
  /** Vertically-stacked atlas pages (page p at byte offset p·atlasW·atlasH). Starts
   *  one page; [growAtlas] reallocates it larger when a dense frame needs more. */
  var atlasBuf: ByteBuffer,
  val vertexBuf: ByteBuffer,
  /** How many pages [atlasBuf] currently holds — the high-water mark for this slot. */
  var pageCapacity: Int,
  var frame: AssAtlasFrame,
  var presentationTimeUs: Long,
  var releaseTimeNs: Long,
  var sourcePresentationTimeUs: Long = presentationTimeUs,
  var phaseLeadUs: Long = 0L,
  /** Slot identity alone is not enough because libass rewrites buffers in place. */
  var contentSeq: Long = 0L,
  var requestSeq: Long = 0L,
  var stateGeneration: Long = 0L
) {
  /** Reallocates [atlasBuf] to hold [pages] stacked atlasW×atlasH pages. Runs on the
   *  libass thread before hand-off, so no GL reader can be looking at the old buffer. */
  fun growAtlas(pages: Int, atlasW: Int, atlasH: Int) {
    atlasBuf = ByteBuffer.allocateDirect(atlasW * atlasH * pages).order(ByteOrder.nativeOrder())
    pageCapacity = pages
  }
}

private class AtlasDrawSnapshot(
  val atlasBuf: ByteBuffer,
  val vertexBuf: ByteBuffer,
  val frame: AssAtlasFrame,
  val sourcePresentationTimeUs: Long,
  val presentationTimeUs: Long,
  val releaseTimeNs: Long,
  val phaseLeadUs: Long,
  val contentSeq: Long,
  val requestSeq: Long,
  val stateGeneration: Long
)

private fun AtlasPayload.snapshot(): AtlasDrawSnapshot = AtlasDrawSnapshot(
  atlasBuf = atlasBuf,
  vertexBuf = vertexBuf,
  frame = frame,
  sourcePresentationTimeUs = sourcePresentationTimeUs,
  presentationTimeUs = presentationTimeUs,
  releaseTimeNs = releaseTimeNs,
  phaseLeadUs = phaseLeadUs,
  contentSeq = contentSeq,
  requestSeq = requestSeq,
  stateGeneration = stateGeneration
)

/** Payload slots plus the atlas dims their buffers were sized for. */
internal class AtlasSlots(
  val payloads: Array<AtlasPayload>,
  val atlasW: Int,
  val atlasH: Int
)

/**
 * Owns both the libass worker and the GL thread. The two talk via a single-slot
 * atomic — a newer payload always replaces a pending one so the GL thread never
 * falls behind.
 */
@UnstableApi
internal class AssAtlasPipeline(
  surface: Surface,
  width: Int,
  height: Int,
  private val assHandler: AssHandler,
  lowRamDevice: Boolean = false,
  refreshRateHz: Float = 60f
) {
  private val surfaceWidth = width
  private val surfaceHeight = height

  /** The calibrator needs the final pre-swap point, and this must survive surface recreation. */
  var preSwapProbe: ((releaseTimeNs: Long) -> Unit)?
    get() = glThread.preSwapProbe
    set(value) {
      glThread.preSwapProbe = value
    }

  // Present-error buckets need to stay meaningful across display modes.
  private val vsyncNs = (1_000_000_000.0 / (if (refreshRateHz >= 1f) refreshRateHz else 60f)).toLong()

  // 3 slots give the render-ahead engine a writable target while one slot is
  // posted and another is in GL's hands; low-RAM devices stay at 2 slots with
  // speculation off (the legacy on-demand behavior, ~19 MB less in buffers).
  private val slotCount = if (lowRamDevice) 2 else 3
  private val speculationEnabled = AssAtlasPipelineConfig.SPECULATION_ENABLED && slotCount >= 3

  // Atlas dims, resolved exactly once (first-wins): normally by the GL thread from
  // GL_MAX_TEXTURE_SIZE right after EGL init; by the libass thread's 1 s fallback
  // if GL never comes up. Both threads then agree on the dims, which matters
  // because the C side bakes UV denominators = these dims into the vertex stream
  // and the GL side allocates each atlas-page texture at these dims.
  private val dimsResolved = java.util.concurrent.atomic.AtomicBoolean(false)
  private val dimsLatch = java.util.concurrent.CountDownLatch(1)

  @Volatile private var atlasW = 0

  @Volatile private var atlasH = 0

  private fun resolveAtlasDims(maxTextureSize: Int): Pair<Int, Int> {
    if (dimsResolved.compareAndSet(false, true)) {
      if (maxTextureSize < 4096) {
        // Query failed (or an ancient GPU): keep the long-proven fixed size.
        atlasW = AssAtlasPipelineConfig.FALLBACK_ATLAS_W
        atlasH = AssAtlasPipelineConfig.FALLBACK_ATLAS_H
      } else {
        val w = if (surfaceWidth > 2048) 4096 else 2048
        atlasW = w
        atlasH = minOf(maxTextureSize, AssAtlasPipelineConfig.ATLAS_PIXEL_BUDGET / w)
      }
      if (AssAtlasPipelineConfig.TIMING_LOGS) {
        Log.d("AssAtlasPipeline", "atlas dims ${atlasW}x$atlasH (glMaxTexture=$maxTextureSize)")
      }
      dimsLatch.countDown()
    }
    return atlasW to atlasH
  }

  // Lazily allocated on the libass thread once atlas dims are known; ~19 MB of
  // direct buffers per slot at the full budget, so don't pay it before the
  // first actual render. Confined to the libass thread after creation.
  private var slots: AtlasSlots? = null

  private fun rendererStateGeneration(): Long = assHandler.render?.let {
    (System.identityHashCode(it).toLong() shl 32) or (it.stateGeneration.toLong() and 0xffffffffL)
  } ?: -1L

  private fun acquireSlots(): AtlasSlots {
    slots?.let { return it }
    if (!dimsLatch.await(1, java.util.concurrent.TimeUnit.SECONDS)) {
      resolveAtlasDims(0) // first-wins: no-op if the GL thread resolved meanwhile
    }
    val w = atlasW
    val h = atlasH
    val payloads = Array(slotCount) { index ->
      AtlasPayload(
        slotIndex = index,
        // One page up front (the common case); grows on demand for dense frames.
        atlasBuf = ByteBuffer.allocateDirect(w * h).order(ByteOrder.nativeOrder()),
        vertexBuf = ByteBuffer.allocateDirect(
          AssAtlasPipelineConfig.MAX_QUADS * AssAtlasPipelineConfig.BYTES_PER_QUAD
        ).order(ByteOrder.nativeOrder()),
        pageCapacity = 1,
        frame = AssAtlasFrame(0, 0, 0, 0, 0),
        presentationTimeUs = 0L,
        releaseTimeNs = C.TIME_UNSET
      )
    }
    return AtlasSlots(payloads, w, h).also { slots = it }
  }

  /** Slot index the GL thread most recently took for drawing; the libass side
   *  never writes it. Written only inside [takePending] on the GL thread. */
  @Volatile private var glLastTakenSlot = -1

  private val pendingPayload = AtomicReference<AtlasPayload?>(null)
  private val latestReadyRequestSeq = AtomicLong(0L)
  private val glThread = AtlasGlThread(
    surface,
    width,
    height,
    assHandler,
    vsyncNs = vsyncNs,
    takePending = {
      pendingPayload.getAndSet(null)?.also { glLastTakenSlot = it.slotIndex }
    },
    latestReadyRequestSeq = { latestReadyRequestSeq.get() },
    currentStateGeneration = ::rendererStateGeneration,
    resolveAtlasDims = ::resolveAtlasDims
  )
  private val libassThread = AtlasLibassThread(
    assHandler,
    acquireSlots = ::acquireSlots,
    speculationEnabled = speculationEnabled,
    glTakenSlot = { glLastTakenSlot },
    stateGeneration = ::rendererStateGeneration,
    onFrameReady = { payload ->
      latestReadyRequestSeq.set(payload.requestSeq)
      pendingPayload.set(payload)
      glThread.triggerDraw()
    }
  )

  fun start() {
    if (AssAtlasPipelineConfig.TIMING_LOGS) {
      Log.d(
        "AssAtlasPipeline",
        "start surface=${surfaceWidth}x$surfaceHeight slots=$slotCount speculation=$speculationEnabled"
      )
    }
    glThread.start()
    libassThread.start()
  }

  fun requestRender(presentationTimeUs: Long, releaseTimeNs: Long) {
    libassThread.enqueue(presentationTimeUs, releaseTimeNs)
  }

  /**
   * Re-renders the last requested position — for renderer state changes (margins,
   * use-margins) that must become visible while playback is paused. Safe during
   * playback: the next video frame's [requestRender] supersedes it (latest-wins).
   */
  fun invalidate() {
    libassThread.invalidate()
  }

  fun onSurfaceSizeChanged(width: Int, height: Int) {
    glThread.onSurfaceSizeChanged(width, height)
  }

  /** Vsync-pinned swaps performed (excludes untimed invalidate repaints). */
  val swapCount: Long get() = glThread.swapCount

  /** Pinned swaps that finished past the swap-time budget (possible missed vsync). */
  val lateSwapCount: Long get() = glThread.lateSwapCount

  /** Worst observed swap lateness past the target release time, in milliseconds. */
  val maxLateMs: Long get() = glThread.maxLateMs

  /** Total libass renders performed (one per serviced request). */
  val renderCount: Long get() = libassThread.renderCount

  /** Renders where libass reported changed content (atlas/vertex rewritten). */
  val changedRenderCount: Long get() = libassThread.changedRenderCount

  /** Renders that overflowed the atlas/vertex capacity (frame content incomplete). */
  val overflowCount: Long get() = libassThread.overflowCount

  /** Duration of the most recent libass render, in milliseconds. */
  val lastLibassMs: Long get() = libassThread.lastLibassMs

  /** Worst observed libass render duration, in milliseconds. */
  val maxLibassMs: Long get() = libassThread.maxLibassMs

  /** Changed-render duration histogram: [≤10ms, ≤25ms, ≤42ms, ≤84ms, >84ms]. */
  val libassMsHistogram: List<Long> get() = libassThread.histogramSnapshot()

  /** Requests served from a pre-rendered (speculative) frame — GL-only hot path. */
  val specHits: Long get() = libassThread.specHits

  /** Requests where a speculative frame existed but didn't match (seek, state change). */
  val specMisses: Long get() = libassThread.specMisses

  /** Speculation rounds skipped (paused, pending request, no confident cadence). */
  val specSkips: Long get() = libassThread.specSkips

  /** changed==0/no-output renders forced into explicit transparent swaps. */
  val blankClearCount: Long get() = libassThread.blankClearCount

  /** Cache-warming prefetch renders of upcoming events. */
  val prefetchCount: Long get() = libassThread.prefetchCount

  /** Frame requests replaced before the libass worker serviced them. */
  val coalescedRequestCount: Long get() = libassThread.coalescedRequestCount

  /** Completed libass results discarded because renderer state changed before handoff. */
  val staleGenerationCount: Long get() = libassThread.staleGenerationCount

  /** Completed overlay snapshots skipped because a newer completed request superseded them before swap. */
  val supersededBeforeSwapCount: Long get() = glThread.supersededBeforeSwapCount

  /** Completed overlay snapshots skipped because renderer state changed before swap. */
  val staleBeforeSwapCount: Long get() = glThread.staleBeforeSwapCount

  /** Worst (minimum) lead of a changed-content pinned swap vs its target release
   *  time, in ms; negative = the new content was queued after the video frame's
   *  vsync. Long.MAX_VALUE until a changed pinned swap happened. */
  val minLeadChangedMs: Long get() = glThread.minLeadChangedMs

  /** Current steady-state compositor phase lead, in ms. */
  val phaseLeadMs: Long get() = libassThread.phaseLeadUs / 1000

  /** Most recent pinned swap lead vs its target release time, in ms. */
  val lastSwapLeadMs: Long get() = glThread.lastSwapLeadMs

  /** Most recent pinned swap headroom when GL work started, in ms. */
  val lastSwapHeadroomMs: Long get() = glThread.lastSwapHeadroomMs

  /** Most recent phase-led wait before swap, in ms. */
  val lastScheduledSleepMs: Long get() = glThread.lastScheduledSleepMs

  /** Adaptive swap lead actually in effect (half the measured refresh), in ms. */
  val swapLeadMs: Long get() = glThread.swapLeadNs / 1_000_000

  /** True once the EGL frame-timestamp extension is probed and capturing. */
  val presentTimingEnabled: Boolean get() = glThread.presentTimingEnabled

  /** Active present-time source, or why it's off (present/comp-start/comp-latch/off:…). */
  val presentSource: String get() = glThread.presentSource

  /** Actual on-screen present time of the most recent measured swap minus its
   *  target release time, in ms (negative = presented before the video frame's
   *  vsync, positive = after). The frame-perfection ground truth. */
  val lastPresentErrorMs: Long get() = glThread.lastPresentErrorMs

  /** Largest-magnitude present error observed, in ms. */
  val worstPresentErrorMs: Long get() = glThread.worstPresentErrorMs

  /** Pinned swaps whose actual present time was read back from SurfaceFlinger. */
  val presentMeasuredCount: Long get() = glThread.presentMeasuredCount

  /** Swaps SurfaceFlinger reported as dropped/never-presented. */
  val presentInvalidCount: Long get() = glThread.presentInvalidCount

  /** Pending present-time reads evicted unread because the ring filled. */
  val presentDroppedCount: Long get() = glThread.presentDroppedCount

  /** Present-error distribution in vsync-interval units:
   *  [≤−1.5, (−1.5,−0.5), (−0.5,+0.5), [+0.5,+1.5), ≥+1.5]. A clean spike in the
   *  middle bucket = frame-perfect; a spike at [+0.5,+1.5) = a 1-vsync late latch. */
  val presentErrorHistogram: List<Long> get() = glThread.presentErrorHistogram

  fun releaseAndWait() {
    libassThread.releaseAndWait()
    glThread.releaseAndWait()
  }
}

/**
 * Stops a [Handler] synchronously: posts [releaseWhat] with an [Ack], waits up to 1 s
 * for the handler to invoke [onReleased] (on its own looper) and signal the latch.
 */
private fun postShutdownAndWait(
  handler: Handler,
  releaseWhat: Int,
  onReleased: () -> Unit
) {
  val latch = Object()
  synchronized(latch) {
    handler.obtainMessage(releaseWhat, Ack(latch, onReleased)).sendToTarget()
    try {
      latch.wait(1_000)
    } catch (_: InterruptedException) {
      Thread.currentThread().interrupt()
    }
  }
}

/** Transport for [postShutdownAndWait] — the handler callback calls [release] then notifies. */
private class Ack(val latch: Any, val release: () -> Unit)

private class PhaseAdjustedFrame(
  val sourcePtsUs: Long,
  val renderPtsUs: Long,
  val releaseNs: Long,
  val phaseLeadUs: Long,
  val releaseLeadNs: Long
)

/**
 * Predicts the next video frame from the callback cadence. Media3 gives us the
 * frame currently being released, but a separate subtitle SurfaceView may not latch
 * in the same composition phase. Once cadence is stable, callback N renders and
 * timestamps the ASS layer for predicted frame N+1.
 */
private class SubtitleFramePhaseEstimator {
  private val ptsDeltasUs = LongArray(DELTA_SAMPLES)
  private val releaseDeltasNs = LongArray(DELTA_SAMPLES)
  private var deltaCount = 0
  private var deltaIndex = 0
  private var lastPtsUs = UNSET
  private var lastReleaseNs = C.TIME_UNSET

  @Synchronized
  fun adjust(ptsUs: Long, releaseNs: Long): PhaseAdjustedFrame {
    if (!AssAtlasPipelineConfig.COMPOSITOR_PHASE_LEAD_ENABLED || releaseNs == C.TIME_UNSET) {
      return PhaseAdjustedFrame(ptsUs, ptsUs, releaseNs, 0L, 0L)
    }

    observe(ptsUs, releaseNs)
    if (deltaCount < MIN_DELTA_SAMPLES) {
      return PhaseAdjustedFrame(ptsUs, ptsUs, releaseNs, 0L, 0L)
    }

    val ptsLeadUs = median(ptsDeltasUs, deltaCount)
    val releaseLeadNs = median(releaseDeltasNs, deltaCount)
    return PhaseAdjustedFrame(
      sourcePtsUs = ptsUs,
      renderPtsUs = saturatedAdd(ptsUs, ptsLeadUs),
      releaseNs = saturatedAdd(releaseNs, releaseLeadNs),
      phaseLeadUs = ptsLeadUs,
      releaseLeadNs = releaseLeadNs
    )
  }

  private fun observe(ptsUs: Long, releaseNs: Long) {
    val prevPtsUs = lastPtsUs
    val prevReleaseNs = lastReleaseNs
    lastPtsUs = ptsUs
    lastReleaseNs = releaseNs
    if (prevPtsUs == UNSET || prevReleaseNs == C.TIME_UNSET) return

    val ptsDeltaUs = ptsUs - prevPtsUs
    val releaseDeltaNs = releaseNs - prevReleaseNs
    if (ptsDeltaUs <= 0 ||
      ptsDeltaUs > MAX_DELTA_US ||
      releaseDeltaNs <= 0 ||
      releaseDeltaNs > MAX_DELTA_NS
    ) {
      deltaCount = 0
      deltaIndex = 0
      return
    }

    ptsDeltasUs[deltaIndex] = ptsDeltaUs
    releaseDeltasNs[deltaIndex] = releaseDeltaNs
    deltaIndex = (deltaIndex + 1) % DELTA_SAMPLES
    if (deltaCount < DELTA_SAMPLES) deltaCount++
  }

  private fun median(values: LongArray, count: Int): Long {
    val copy = values.copyOfRange(0, count)
    copy.sort()
    return copy[count / 2]
  }

  private fun saturatedAdd(value: Long, delta: Long): Long = if (delta > 0 && value > Long.MAX_VALUE - delta) Long.MAX_VALUE else value + delta

  private companion object {
    const val UNSET = Long.MIN_VALUE
    const val DELTA_SAMPLES = 8
    const val MIN_DELTA_SAMPLES = 4
    const val MAX_DELTA_US = 250_000L
    const val MAX_DELTA_NS = 250_000_000L
  }
}

/**
 * Runs libass off the GL thread into a packed atlas + vertex stream. Latest-wins:
 * older pending renders are dropped when a newer one arrives. Slot choice, the
 * changed-flag bookkeeping and speculative render-ahead live in [SpecRenderEngine];
 * this thread owns the buffers, the timing/stat accounting and the GL handoff.
 */
@UnstableApi
private class AtlasLibassThread(
  private val assHandler: AssHandler,
  private val acquireSlots: () -> AtlasSlots,
  private val speculationEnabled: Boolean,
  private val glTakenSlot: () -> Int,
  private val stateGeneration: () -> Long,
  private val onFrameReady: (AtlasPayload) -> Unit
) : HandlerThread(TAG, Process.THREAD_PRIORITY_DISPLAY) {

  /** Immutable frame request — handed off through a single atomic so a concurrent
   *  enqueue can neither be lost by drain's consume nor torn in half. [ptsUs] is
   *  the libass render timestamp after any phase lead; [sourcePtsUs] is the video
   *  callback PTS after user subtitle delay but before the compositor lead.
   *  [sequence] is the selected-video-frame request identity, and [enqueueNs]
   *  timestamps the handoff so drain can report queue wait. */
  private class PendingFrame(
    val sourcePtsUs: Long,
    val ptsUs: Long,
    val releaseNs: Long,
    val phaseLeadUs: Long,
    val releaseLeadNs: Long,
    val sequence: Long,
    val enqueueNs: Long = System.nanoTime()
  )

  private lateinit var handler: Handler

  private val pending = AtomicReference<PendingFrame?>(null)
  private val phaseEstimator = SubtitleFramePhaseEstimator()
  private val requestSeqCounter = AtomicLong(0L)

  @Volatile private var lastRequestedPtsUs = UNSET
  private var contentSeqCounter = 0L

  // Thread-confined; created on first render so non-ASS playback never allocates.
  private var engine: SpecRenderEngine? = null
  private var engineStateGeneration = Long.MIN_VALUE

  val specHits: Long get() = engine?.specHits ?: 0L
  val specMisses: Long get() = engine?.specMisses ?: 0L
  val specSkips: Long get() = engine?.specSkips ?: 0L
  val blankClearCount: Long get() = engine?.blankClearCount ?: 0L
  val prefetchCount: Long get() = engine?.prefetchCount ?: 0L

  @Volatile var coalescedRequestCount = 0L
    private set

  @Volatile var staleGenerationCount = 0L
    private set

  @Volatile var phaseLeadUs = 0L
    private set

  // Telemetry; single-writer (this thread), read from the stats path.
  @Volatile var renderCount = 0L
    private set

  @Volatile var changedRenderCount = 0L
    private set

  @Volatile var overflowCount = 0L
    private set

  @Volatile var lastLibassMs = 0L
    private set

  @Volatile var maxLibassMs = 0L
    private set

  /** Changed-render durations bucketed at ≤10 / ≤25 / ≤42 / ≤84 / >84 ms. */
  private val histogram = java.util.concurrent.atomic.AtomicLongArray(5)

  fun histogramSnapshot(): List<Long> = List(histogram.length()) { histogram.get(it) }

  private fun recordChangedRenderMs(ms: Long) {
    val bucket = when {
      ms <= 10 -> 0
      ms <= 25 -> 1
      ms <= 42 -> 2
      ms <= 84 -> 3
      else -> 4
    }
    histogram.incrementAndGet(bucket)
  }

  override fun start() {
    super.start()
    handler = Handler(looper) { msg ->
      when (msg.what) {
        MSG_RENDER -> drainAndRender()
        MSG_RELEASE -> {
          val ack = msg.obj as Ack
          ack.release()
          quit()
          synchronized(ack.latch) { (ack.latch as Object).notifyAll() }
        }
      }
      true
    }
  }

  fun enqueue(presentationTimeUs: Long, releaseTimeNs: Long) {
    if (!::handler.isInitialized) return
    val adjusted = phaseEstimator.adjust(presentationTimeUs, releaseTimeNs)
    phaseLeadUs = adjusted.phaseLeadUs
    val sequence = requestSeqCounter.incrementAndGet()
    val dropped = pending.getAndSet(
      PendingFrame(
        sourcePtsUs = adjusted.sourcePtsUs,
        ptsUs = adjusted.renderPtsUs,
        releaseNs = adjusted.releaseNs,
        phaseLeadUs = adjusted.phaseLeadUs,
        releaseLeadNs = adjusted.releaseLeadNs,
        sequence = sequence
      )
    )
    if (dropped != null) {
      coalescedRequestCount++
      if (AssAtlasPipelineConfig.TIMING_LOGS) {
        // A request was coalesced away — the renderer is behind by at least one
        // frame. agedMs = how long the dropped request had been waiting.
        Log.d(
          TAG,
          "drop seq=${dropped.sequence} src=${dropped.sourcePtsUs / 1000}ms pts=${dropped.ptsUs / 1000}ms " +
            "agedMs=${(System.nanoTime() - dropped.enqueueNs) / 1_000_000} " +
            "replacedBySeq=$sequence replacedBySrc=${presentationTimeUs / 1000}ms replacedByPts=${adjusted.renderPtsUs / 1000}ms"
        )
      }
    }
    handler.removeMessages(MSG_RENDER)
    handler.sendEmptyMessage(MSG_RENDER)
  }

  /** Re-enqueues the last requested PTS (renderer state changed, possibly while paused). */
  fun invalidate() {
    val pts = lastRequestedPtsUs
    if (pts == UNSET) return
    // TIME_UNSET release time => the GL thread swaps immediately instead of
    // vsync-pinning to a video frame that may never come while paused.
    enqueue(pts, C.TIME_UNSET)
  }

  private fun ensureEngine(slots: AtlasSlots, generation: Long): SpecRenderEngine {
    engine?.takeIf { engineStateGeneration == generation }?.let { return it }
    engineStateGeneration = generation
    unchangedStreak = 0
    return SpecRenderEngine(
      slotCount = slots.payloads.size,
      speculationEnabled = speculationEnabled,
      renderAt = { timeMs, slot -> timedRender(timeMs, slots, slot) },
      // Renderer identity in the high bits + its state generation in the low bits:
      // a recreated renderer (media item transition) can never alias a stale
      // speculation, even if the new generation counter happens to match.
      stateGeneration = stateGeneration,
      glTakenSlot = glTakenSlot,
      debugLog = if (AssAtlasPipelineConfig.TIMING_LOGS) ({ msg -> Log.d(TAG, msg) }) else null
    ).also { engine = it }
  }

  /** Consecutive renders that reported no content change — a static screen.
   *  Reset by any changed render (dialogue flips, karaoke, animated signs). */
  private var unchangedStreak = 0

  /** Renders into [slot]'s buffers, owning the per-render timing/stat accounting
   *  for both on-demand and speculative renders. */
  private fun timedRender(timeMs: Long, slots: AtlasSlots, slot: Int): AssAtlasFrame? {
    val render = assHandler.render ?: return null
    val payload = slots.payloads[slot]
    val t0 = System.nanoTime()
    var frame = render.renderFrameAtlas(timeMs, payload.atlasBuf, slots.atlasW, slots.atlasH, payload.vertexBuf)
      ?: return null
    // A frame overflows one atlas page only on dense full-screen typesetting. When it
    // does, grow this slot's buffer to the pages it needs (capped) and render once more
    // — libass's caches make the re-render cheap, and the slot keeps the larger buffer
    // so the same density never re-grows. The truncated first result is never handed off.
    if (frame.requiredPages > payload.pageCapacity && payload.pageCapacity < AssAtlasPipelineConfig.MAX_ATLAS_PAGES) {
      payload.growAtlas(
        minOf(frame.requiredPages, AssAtlasPipelineConfig.MAX_ATLAS_PAGES),
        slots.atlasW,
        slots.atlasH
      )
      frame = render.renderFrameAtlas(timeMs, payload.atlasBuf, slots.atlasW, slots.atlasH, payload.vertexBuf)
        ?: return null
    }
    val libassMs = (System.nanoTime() - t0) / 1_000_000
    renderCount++
    lastLibassMs = libassMs
    if (libassMs > maxLibassMs) maxLibassMs = libassMs
    if (frame.truncated > 0) overflowCount++
    if (frame.changed != 0) {
      changedRenderCount++
      recordChangedRenderMs(libassMs)
      unchangedStreak = 0
    } else {
      unchangedStreak++
    }
    return frame
  }

  private fun drainAndRender() {
    val request = pending.getAndSet(null) ?: return
    val sourcePts = request.sourcePtsUs
    val pts = request.ptsUs
    val releaseNs = request.releaseNs
    lastRequestedPtsUs = sourcePts
    val tDrain = System.nanoTime()
    // How long the request sat in the handoff (behind an in-flight on-demand or
    // speculative render) — the queue-wait component of any subtitle lag.
    val waitMs = (tDrain - request.enqueueNs) / 1_000_000
    // Before any ASS render exists (SRT/VTT or no subs) do nothing — this also
    // keeps the slot buffers unallocated for non-ASS playback.
    if (assHandler.render == null) return
    val slots = acquireSlots()
    val generation = stateGeneration()
    val engine = ensureEngine(slots, generation)
    val pinned = releaseNs != C.TIME_UNSET
    // Budget left until the video frame's vsync when we START servicing.
    val budgetMs = if (pinned) (releaseNs - tDrain) / 1_000_000 else -1L

    when (val outcome = engine.service(pts, pinned)) {
      is SpecRenderEngine.Outcome.Post -> {
        if (stateGeneration() != generation) {
          staleGenerationCount++
          engineStateGeneration = Long.MIN_VALUE
          if (AssAtlasPipelineConfig.TIMING_LOGS) {
            Log.d(TAG, "stale-render req=${request.sequence} pts=${pts / 1000}ms")
          }
          return
        }
        val payload = slots.payloads[outcome.slot]
        if (outcome.newContent) {
          payload.frame = outcome.frame
          payload.contentSeq = ++contentSeqCounter
        }
        payload.sourcePresentationTimeUs = sourcePts
        payload.presentationTimeUs = pts
        payload.releaseTimeNs = releaseNs
        payload.phaseLeadUs = request.phaseLeadUs
        payload.requestSeq = request.sequence
        payload.stateGeneration = generation
        onFrameReady(payload)
        if (AssAtlasPipelineConfig.TIMING_LOGS) {
          Log.d(
            TAG,
            "render req=${request.sequence} src=${sourcePts / 1000}ms pts=${pts / 1000}ms phaseLeadMs=${request.phaseLeadUs / 1000} " +
              "releaseLeadMs=${request.releaseLeadNs / 1_000_000} seq=${payload.contentSeq} waitMs=$waitMs budgetMs=$budgetMs " +
              "libassMs=$lastLibassMs lockWaitMs=${assHandler.render?.lastLockWaitMs} " +
              "specHit=${outcome.specHit} changed=${payload.frame.changed} output=${payload.frame.hasOutput} quads=${payload.frame.quadCount} " +
              "atlas=${payload.frame.atlasWidth}x${payload.frame.atlasHeight} truncated=${payload.frame.truncated}"
          )
        }
      }
      SpecRenderEngine.Outcome.Skip -> {
        if (AssAtlasPipelineConfig.TIMING_LOGS) {
          Log.d(TAG, "skip pts=${pts / 1000}ms waitMs=$waitMs budgetMs=$budgetMs (no content)")
        }
      }
    }

    // Pre-render the predicted next frame in the dead time between requests so the
    // next service is (usually) a GL-only hit. Never delays a waiting request.
    if (stateGeneration() != generation) return
    engine.speculateAfter(pts, pinned, hasPending = pending.get() != null)?.let { write ->
      val payload = slots.payloads[write.slot]
      payload.frame = write.frame
      payload.contentSeq = ++contentSeqCounter
      if (AssAtlasPipelineConfig.TIMING_LOGS) {
        Log.d(
          TAG,
          "spec after=${pts / 1000}ms seq=${payload.contentSeq} libassMs=$lastLibassMs " +
            "lockWaitMs=${assHandler.render?.lastLockWaitMs} slot=${write.slot} output=${write.frame.hasOutput} quads=${write.frame.quadCount}"
        )
      }
    }

    maybePrefetch(engine, slots, pts, pinned)
  }

  /** Start time of the last event boundary we cache-warmed (libass/track ms). */
  private var lastPrefetchedStartMs = Long.MIN_VALUE

  /** Wall time of the last prefetch render, for the cooldown. */
  private var lastPrefetchNs = Long.MIN_VALUE / 2

  /**
   * Cache-warms the next upcoming subtitle event so heavy typesetting pays its
   * cache-cold rasterization (seconds on weak devices) before the sign appears
   * instead of at appearance.
   *
   * The render blocks this thread, and during playback a new request is never
   * more than one frame interval away — so a prefetch is only allowed when its
   * delay cannot be SEEN, not merely when the queue is momentarily empty
   * (the v1 mistake, which thrashed on densely-authored per-frame events and
   * stalled visible dialogue):
   *  - the screen must be static ([unchangedStreak]): requests delayed behind
   *    the prefetch re-render identical content, so their lateness is invisible;
   *  - the warmed event must be the NEXT on-screen change (no other event start
   *    or end before it) — this also kills dense per-frame event sections,
   *    where the next change is always ≤ one frame away;
   *  - a cooldown bounds the worst-case overhead to one render per window.
   */
  private fun maybePrefetch(engine: SpecRenderEngine, slots: AtlasSlots, ptsUs: Long, pinned: Boolean) {
    if (!speculationEnabled) return
    if (!pinned) return
    if (pending.get() != null) return
    if (unchangedStreak < PREFETCH_STATIC_STREAK) return
    val now = System.nanoTime()
    if (now - lastPrefetchNs < PREFETCH_COOLDOWN_NS) return
    val track = assHandler.track ?: return
    val nowMs = Math.floorDiv(ptsUs, 1_000L)
    // Events closer than MIN_AHEAD are the regular per-frame path's business;
    // beyond HORIZON the warmed bitmaps may be evicted before they're needed.
    val targetMs = track.nextEventStartMs(nowMs + PREFETCH_MIN_AHEAD_MS)
    if (targetMs < 0 || targetMs == lastPrefetchedStartMs) return
    if (targetMs > nowMs + PREFETCH_HORIZON_MS) return
    // Invisibility gate, time-budgeted: a prefetch is invisible as long as it
    // finishes before anything on screen is due to change (the screen is static
    // per the streak gate, so requests delayed behind it re-render identical
    // content). Estimate the cost from the worst render seen this session —
    // an overestimate only skips warming; an underestimate delays one boundary
    // by the shortfall. nextEventChangeMs also sees ends, so a dialogue line
    // due to disappear inside the budget skips the prefetch.
    val nextChangeMs = track.nextEventChangeMs(nowMs)
    if (nextChangeMs in 0 until targetMs) {
      val runwayMs = nextChangeMs - nowMs
      val costEstimateMs = (maxLibassMs * 5 / 4).coerceIn(PREFETCH_COST_FLOOR_MS, PREFETCH_COST_CEIL_MS)
      if (runwayMs < costEstimateMs + PREFETCH_SAFETY_MS) return
    }
    lastPrefetchedStartMs = targetMs
    lastPrefetchNs = now
    engine.prefetch(targetMs * 1000)?.let { write ->
      val payload = slots.payloads[write.slot]
      payload.frame = write.frame
      payload.contentSeq = ++contentSeqCounter
    }
    if (AssAtlasPipelineConfig.TIMING_LOGS) {
      Log.d(
        TAG,
        "prefetch evt=${targetMs}ms aheadMs=${targetMs - nowMs} " +
          "tookMs=${(System.nanoTime() - now) / 1_000_000} libassMs=$lastLibassMs"
      )
    }
  }

  fun releaseAndWait() {
    if (!::handler.isInitialized) {
      quit()
      return
    }
    postShutdownAndWait(handler, MSG_RELEASE) { /* nothing thread-local to tear down */ }
  }

  companion object {
    private const val TAG = "AssLibassThread"
    private const val MSG_RENDER = 1
    private const val MSG_RELEASE = 2
    private const val UNSET = Long.MIN_VALUE

    /** Don't prefetch events the per-frame speculation will reach imminently. */
    private const val PREFETCH_MIN_AHEAD_MS = 1_000L

    /** Don't warm caches so early that the bitmaps could be evicted again. */
    private const val PREFETCH_HORIZON_MS = 15_000L

    /** Static-screen requirement before a prefetch may block this thread. */
    private const val PREFETCH_STATIC_STREAK = 3

    /** Minimum spacing between prefetch renders. */
    private const val PREFETCH_COOLDOWN_NS = 2_000_000_000L

    /** Cost-estimate clamp for the time-budgeted invisibility gate: never
     *  assume a prefetch cheaper than the floor (estimator may not have seen a
     *  heavy frame yet) nor pointlessly demand more runway than the ceiling. */
    private const val PREFETCH_COST_FLOOR_MS = 250L
    private const val PREFETCH_COST_CEIL_MS = 1_500L

    /** Slack added to the cost estimate when checking the static runway. */
    private const val PREFETCH_SAFETY_MS = 150L
  }
}

/**
 * Owns the EGL surface, uploads the atlas + vertex stream and issues a single
 * `glDrawArrays` per frame. Timed swaps are queued close to the target video
 * release time and stamped via [EGLExt.eglPresentationTimeANDROID].
 */
@UnstableApi
private class AtlasGlThread(
  private val surface: Surface,
  @Volatile private var width: Int,
  @Volatile private var height: Int,
  private val assHandler: AssHandler,
  private val vsyncNs: Long,
  private val takePending: () -> AtlasPayload?,
  private val latestReadyRequestSeq: () -> Long,
  private val currentStateGeneration: () -> Long,
  private val resolveAtlasDims: (maxTextureSize: Int) -> Pair<Int, Int>
) : HandlerThread(TAG, Process.THREAD_PRIORITY_DISPLAY) {

  // Calibration hook invoked just before each pinned eglSwapBuffers (see AssAtlasPipeline).
  @Volatile var preSwapProbe: ((releaseTimeNs: Long) -> Unit)? = null

  // Swap lead = half the refresh interval, clamped. Measured live from the actual
  // gap between video-frame release targets rather than display.refreshRate, which
  // can still read the pre-switch rate when a pre-open mode change hasn't settled
  // (the bug that pinned the lead at ~8 ms while the panel was really at 24 Hz).
  private val releaseDeltasNs = LongArray(8)
  private var releaseDeltaCount = 0
  private var releaseDeltaIndex = 0
  private var lastCadenceReleaseNs = C.TIME_UNSET

  // Median gap between successive video-frame release targets (≈ one refresh at
  // matched cadence). Drives both the swap lead and the present offset.
  @Volatile private var measuredIntervalNs: Long = vsyncNs

  @Volatile var swapLeadNs: Long =
    (vsyncNs / 2).coerceIn(SCHEDULED_SWAP_LEAD_MIN_NS, SCHEDULED_SWAP_LEAD_MAX_NS)
    private set

  private fun updateSwapLead(releaseNs: Long) {
    val prev = lastCadenceReleaseNs
    lastCadenceReleaseNs = releaseNs
    if (prev == C.TIME_UNSET) return
    val d = releaseNs - prev
    if (d <= 0 || d > MAX_RELEASE_DELTA_NS) {
      releaseDeltaCount = 0
      releaseDeltaIndex = 0
      return
    }
    releaseDeltasNs[releaseDeltaIndex] = d
    releaseDeltaIndex = (releaseDeltaIndex + 1) % releaseDeltasNs.size
    if (releaseDeltaCount < releaseDeltasNs.size) releaseDeltaCount++
    if (releaseDeltaCount >= 4) {
      val copy = releaseDeltasNs.copyOf(releaseDeltaCount)
      copy.sort()
      measuredIntervalNs = copy[releaseDeltaCount / 2]
      swapLeadNs = (measuredIntervalNs / 2).coerceIn(
        SCHEDULED_SWAP_LEAD_MIN_NS,
        SCHEDULED_SWAP_LEAD_MAX_NS
      )
    }
  }

  private lateinit var handler: Handler
  private var eglDisplay: EGLDisplay = EGL14.EGL_NO_DISPLAY
  private var eglContext: EGLContext = EGL14.EGL_NO_CONTEXT
  private var eglSurface: EGLSurface = EGL14.EGL_NO_SURFACE

  private val renderer = AtlasRenderer(assHandler)
  private var lastUploadedPayload: AtlasPayload? = null
  private var lastUploadedSeq = -1L
  private var lastSwappedSeq = -1L

  // Lateness telemetry; single-writer (this thread), read from the stats path.
  @Volatile var swapCount = 0L
    private set

  @Volatile var lateSwapCount = 0L
    private set

  @Volatile var maxLateMs = 0L
    private set

  /** Minimum lead (release target − swap completion) over changed-content pinned
   *  swaps; negative = content queued after the video frame's vsync. */
  @Volatile var minLeadChangedMs = Long.MAX_VALUE
    private set

  @Volatile var lastSwapLeadMs = 0L
    private set

  @Volatile var lastSwapHeadroomMs = 0L
    private set

  @Volatile var lastScheduledSleepMs = 0L
    private set

  @Volatile var supersededBeforeSwapCount = 0L
    private set

  @Volatile var staleBeforeSwapCount = 0L
    private set

  // --- Present-time ground truth (EGL_ANDROID_get_frame_timestamps) ---
  // The actual on-screen present time is reported a few swaps after eglSwapBuffers,
  // so swapped frame ids are recorded here and resolved lazily. Confined to this
  // (single) GL thread; telemetry fields are @Volatile for the stats reader.
  @Volatile var presentTimingEnabled = false
    private set

  /** Which timestamp source the probe settled on, or why it's off (for diagnosis). */
  @Volatile var presentSource = "off:uninit"
    private set

  private val ptFrameId = LongArray(PRESENT_RING)
  private val ptReleaseNs = LongArray(PRESENT_RING)
  private var ptHead = 0
  private var ptCount = 0

  @Volatile var lastPresentErrorMs = 0L
    private set

  @Volatile var worstPresentErrorMs = 0L
    private set

  @Volatile var presentMeasuredCount = 0L
    private set

  @Volatile var presentInvalidCount = 0L
    private set

  @Volatile var presentDroppedCount = 0L
    private set

  private val ptBuckets = LongArray(PRESENT_BUCKETS)
  val presentErrorHistogram: List<Long> get() = ptBuckets.toList()

  // Tracks renderer-state generation so transient seek swaps don't permanently
  // corrupt the worst-case lead/present signals.
  private var lastGenerationSeen = Long.MIN_VALUE

  override fun start() {
    super.start()
    handler = Handler(looper) { msg ->
      try {
        when (msg.what) {
          MSG_INIT -> initEgl()
          MSG_DRAW -> drawAndSwap()
          MSG_SIZE_CHANGED -> sizeChanged(width, height)
          MSG_RELEASE -> {
            val ack = msg.obj as Ack
            ack.release()
            quit()
            synchronized(ack.latch) { (ack.latch as Object).notifyAll() }
          }
        }
      } catch (e: Exception) {
        Log.e(TAG, "GL thread error", e)
        releaseEgl()
      }
      true
    }
    handler.sendEmptyMessage(MSG_INIT)
  }

  fun onSurfaceSizeChanged(width: Int, height: Int) {
    this.width = width
    this.height = height
    handler.sendEmptyMessage(MSG_SIZE_CHANGED)
  }

  fun triggerDraw() {
    if (!::handler.isInitialized) return
    handler.removeMessages(MSG_DRAW)
    handler.sendEmptyMessage(MSG_DRAW)
  }

  fun releaseAndWait() {
    if (!::handler.isInitialized) {
      quit()
      return
    }
    postShutdownAndWait(handler, MSG_RELEASE) { releaseEgl() }
  }

  private fun initEgl() {
    try {
      eglDisplay = GlUtil.getDefaultEglDisplay()
      eglContext = GlUtil.createEglContext(eglDisplay)
      eglSurface = GlUtil.createEglSurface(eglDisplay, surface, C.COLOR_TRANSFER_SDR, false)
      EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
      renderer.onSurfaceCreated()
      // Resolve atlas dims from real GL caps (first-wins against the libass
      // thread's fallback) and allocate the page-0 texture at those dims (extra
      // pages lazily) — uploads are glTexSubImage2D of the packed rows from then on.
      val maxTexture = IntArray(1)
      GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, maxTexture, 0)
      val (atlasW, atlasH) = resolveAtlasDims(maxTexture[0])
      renderer.allocateAtlasTexture(atlasW, atlasH)
      sizeChanged(width, height)
      initPresentTiming()
    } catch (e: GlUtil.GlException) {
      Log.e(TAG, "Failed to initialize EGL", e)
    }
  }

  /** Probes the EGL frame-timestamp extension on the freshly-current surface.
   *  EGL_ANDROID_get_frame_timestamps exists from Android 8.0 (entry points are
   *  resolved at runtime via eglGetProcAddress), so gate at O and let the native
   *  probe disable itself where the driver/emulator reports it unsupported — that
   *  "unsupported" result is itself the signal that present time can't be measured. */
  private fun initPresentTiming() {
    ptHead = 0
    ptCount = 0
    val status = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      AssFrameTimestamps.ERR_UNSUPPORTED
    } else {
      try {
        AssFrameTimestamps.nativeInit()
      } catch (t: Throwable) {
        Log.w(TAG, "frame-timestamp init failed; present timing disabled", t)
        AssFrameTimestamps.ERR_NO_PROC
      }
    }
    presentTimingEnabled = status >= 0
    presentSource = AssFrameTimestamps.sourceLabel(status)
  }

  private fun sizeChanged(width: Int, height: Int) {
    renderer.onSurfaceChanged(width, height)
    if (eglDisplay != EGL14.EGL_NO_DISPLAY) {
      GlUtil.clearFocusedBuffers()
      EGL14.eglSwapBuffers(eglDisplay, eglSurface)
    }
  }

  private fun drawAndSwap() {
    if (eglDisplay == EGL14.EGL_NO_DISPLAY) return
    drainPresentTimestamps()
    val payload = takePending() ?: return

    val t0 = System.nanoTime()
    val snapshot = payload.snapshot()
    val reuse = payload === lastUploadedPayload && snapshot.contentSeq == lastUploadedSeq
    renderer.onDrawFrame(snapshot, reuseUploads = reuse)
    lastUploadedPayload = payload
    lastUploadedSeq = snapshot.contentSeq
    val t1 = System.nanoTime()

    // The overlay needs latch margin, but a drawn pinned payload still belongs to
    // its video frame even if the next frame becomes ready while we wait.
    val pinned = snapshot.releaseTimeNs != C.TIME_UNSET
    val contentChanged = snapshot.contentSeq != lastSwappedSeq
    if (pinned) updateSwapLead(snapshot.releaseTimeNs)
    val presentTarget = snapshot.releaseTimeNs
    val scheduledSleepMs = if (pinned) sleepUntilScheduledSwap(presentTarget) else 0L
    val latestReadySeq = latestReadyRequestSeq()
    val currentGeneration = currentStateGeneration()
    if (currentGeneration != lastGenerationSeen) {
      // Seek/track/size churn should not poison the worst-case lead signal.
      lastGenerationSeen = currentGeneration
      minLeadChangedMs = Long.MAX_VALUE
    }
    val stale = snapshot.stateGeneration != currentGeneration
    // A newer ready request can be for the next video frame, while this buffer is
    // still the only correct content for its own target frame.
    val superseded = !pinned && snapshot.requestSeq < latestReadySeq
    if (stale || superseded) {
      if (stale) staleBeforeSwapCount++
      if (superseded) supersededBeforeSwapCount++
      lastScheduledSleepMs = scheduledSleepMs
      if (AssAtlasPipelineConfig.TIMING_LOGS) {
        Log.d(
          TAG,
          "skip-before-swap req=${snapshot.requestSeq} latest=$latestReadySeq " +
            "stale=$stale gen=${snapshot.stateGeneration}/$currentGeneration " +
            "src=${snapshot.sourcePresentationTimeUs / 1000}ms pts=${snapshot.presentationTimeUs / 1000}ms " +
            "sleepMs=$scheduledSleepMs pinned=$pinned"
        )
      }
      return
    }
    if (pinned) {
      // Keep the empty probe transaction out from between the presentation
      // timestamp and the swap it is meant to measure.
      preSwapProbe?.invoke(presentTarget)
      EGLExt.eglPresentationTimeANDROID(eglDisplay, eglSurface, presentTarget)
    }
    // SurfaceFlinger only knows the frame id before swap and the present time later.
    val frameId = if (pinned && presentTimingEnabled) {
      try {
        AssFrameTimestamps.nativeGetNextFrameId()
      } catch (t: Throwable) {
        presentTimingEnabled = false
        -1L
      }
    } else {
      -1L
    }
    EGL14.eglSwapBuffers(eglDisplay, eglSurface)
    val t2 = System.nanoTime()
    if (frameId >= 0) recordSwappedFrame(frameId, presentTarget)
    var headroomMs = -1L
    var leadMs = -1L
    if (pinned) {
      swapCount++
      headroomMs = (presentTarget - t0) / 1_000_000
      val lateNs = t2 - presentTarget
      leadMs = -lateNs / 1_000_000
      lastSwapHeadroomMs = headroomMs
      lastSwapLeadMs = leadMs
      lastScheduledSleepMs = scheduledSleepMs
      if (lateNs > LATE_THRESHOLD_NS) {
        lateSwapCount++
        val lateMs = lateNs / 1_000_000
        if (lateMs > maxLateMs) maxLateMs = lateMs
      }
      if (contentChanged) {
        if (leadMs < minLeadChangedMs) minLeadChangedMs = leadMs
      }
      if (swapCount % SYNC_LOG_INTERVAL_SWAPS == 0L) {
        Log.i(
          TAG,
          "[ASS-sync] swaps=$swapCount late=$lateSwapCount maxLateMs=$maxLateMs " +
            "minLeadChangedMs=${if (minLeadChangedMs == Long.MAX_VALUE) "n/a" else minLeadChangedMs} " +
            "present=$presentSource presentErrMs=$lastPresentErrorMs worstPresentMs=$worstPresentErrorMs " +
            "presentHist=${ptBuckets.joinToString(",")} measured=$presentMeasuredCount " +
            "presentInvalid=$presentInvalidCount presentDropped=$presentDroppedCount " +
            "src=${snapshot.sourcePresentationTimeUs / 1000}ms pts=${snapshot.presentationTimeUs / 1000}ms " +
            "phaseLeadMs=${snapshot.phaseLeadUs / 1000} sleepMs=$scheduledSleepMs headroomMs=$headroomMs leadMs=$leadMs " +
            "req=${snapshot.requestSeq} seq=${snapshot.contentSeq} superseded=$supersededBeforeSwapCount stale=$staleBeforeSwapCount " +
            "changed=$contentChanged reused=$reuse"
        )
      }
    }
    lastSwappedSeq = snapshot.contentSeq
    if (AssAtlasPipelineConfig.TIMING_LOGS) {
      // headroomMs: slack before the target vsync when GL STARTED; leadMs: slack
      // when the buffer was actually queued (negative = queued after the vsync).
      Log.d(
        TAG,
        "swap src=${snapshot.sourcePresentationTimeUs / 1000}ms pts=${snapshot.presentationTimeUs / 1000}ms " +
          "phaseLeadMs=${snapshot.phaseLeadUs / 1000} req=${snapshot.requestSeq} seq=${snapshot.contentSeq} " +
          "quads=${snapshot.frame.quadCount} reused=$reuse drawMs=${(t1 - t0) / 1_000_000} " +
          "sleepMs=$scheduledSleepMs swapMs=${(t2 - t1) / 1_000_000} headroomMs=$headroomMs leadMs=$leadMs pinned=$pinned"
      )
    }
  }

  private fun sleepUntilScheduledSwap(releaseTimeNs: Long): Long {
    val startNs = System.nanoTime()
    val wakeNs = releaseTimeNs - swapLeadNs
    var remainingNs = wakeNs - startNs
    while (remainingNs > SCHEDULED_SWAP_SPIN_NS && !Thread.currentThread().isInterrupted) {
      LockSupport.parkNanos(remainingNs)
      remainingNs = wakeNs - System.nanoTime()
    }
    return ((System.nanoTime() - startNs).coerceAtLeast(0L)) / 1_000_000
  }

  private fun recordSwappedFrame(frameId: Long, releaseNs: Long) {
    if (ptCount == PRESENT_RING) {
      ptHead = (ptHead + 1) % PRESENT_RING
      ptCount--
      presentDroppedCount++
    }
    val tail = (ptHead + ptCount) % PRESENT_RING
    ptFrameId[tail] = frameId
    ptReleaseNs[tail] = releaseNs
    ptCount++
  }

  private fun drainPresentTimestamps() {
    if (!presentTimingEnabled) return
    while (ptCount > 0) {
      val idx = ptHead
      val present = try {
        AssFrameTimestamps.nativeGetDisplayPresentTime(ptFrameId[idx])
      } catch (t: Throwable) {
        presentTimingEnabled = false
        return
      }
      if (present == AssFrameTimestamps.PENDING) return
      ptHead = (ptHead + 1) % PRESENT_RING
      ptCount--
      if (present <= 0L) {
        presentInvalidCount++
        continue
      }
      recordPresentError(present - ptReleaseNs[idx])
    }
  }

  private fun recordPresentError(errorNs: Long) {
    presentMeasuredCount++
    val errorMs = errorNs / 1_000_000
    lastPresentErrorMs = errorMs
    if (Math.abs(errorMs) > Math.abs(worstPresentErrorMs)) worstPresentErrorMs = errorMs
    val frac = errorNs.toDouble() / vsyncNs.toDouble()
    val bucket = when {
      frac < -1.5 -> 0
      frac < -0.5 -> 1
      frac < 0.5 -> 2
      frac < 1.5 -> 3
      else -> 4
    }
    ptBuckets[bucket]++
  }

  private fun releaseEgl() {
    if (eglDisplay != EGL14.EGL_NO_DISPLAY) {
      try {
        renderer.onSurfaceDestroyed()
        GlUtil.destroyEglSurface(eglDisplay, eglSurface)
        GlUtil.destroyEglContext(eglDisplay, eglContext)
      } catch (e: GlUtil.GlException) {
        Log.e(TAG, "Failed to release EGL", e)
      } finally {
        eglDisplay = EGL14.EGL_NO_DISPLAY
        eglContext = EGL14.EGL_NO_CONTEXT
        eglSurface = EGL14.EGL_NO_SURFACE
      }
    }
  }

  companion object {
    private const val TAG = "AssSurfaceGlThread"
    private const val MSG_INIT = 1
    private const val MSG_DRAW = 2
    private const val MSG_SIZE_CHANGED = 3
    private const val MSG_RELEASE = 4
    private const val SYNC_LOG_INTERVAL_SWAPS = 120L

    // Missing SurfaceFlinger's latch deadline costs a full refresh, so keep the
    // margin proportional to the active cadence.
    private const val SCHEDULED_SWAP_LEAD_MIN_NS = 6_000_000L
    private const val SCHEDULED_SWAP_LEAD_MAX_NS = 18_000_000L
    private const val SCHEDULED_SWAP_SPIN_NS = 200_000L
    private const val MAX_RELEASE_DELTA_NS = 250_000_000L
    private const val PRESENT_RING = 16
    private const val PRESENT_BUCKETS = 5

    /**
     * Swaps finishing this far past the target release time arrived after the
     * buffer should already have been queued and may miss the frame's vsync —
     * actual slack depends on the display's vsync offset from the release time.
     */
    private const val LATE_THRESHOLD_NS = 4_000_000L
  }
}

/**
 * GL-side work for the atlas-based path. Maintains one ALPHA_8 atlas texture per
 * page (allocated lazily, up to MAX_ATLAS_PAGES) plus a single vertex buffer;
 * uploads them per frame (unless the payload identity matches the last upload) and
 * issues one `glDrawArrays` per page, drawing pages in turn to reproduce libass's
 * blend order.
 */
@UnstableApi
private class AtlasRenderer(private val assHandler: AssHandler) {

  private val vertexShaderCode = """
        attribute vec2 a_Position;
        attribute vec2 a_TexCoord;
        attribute vec4 a_Color;
        uniform vec2 u_SurfaceSize;
        varying vec2 v_TexCoord;
        varying vec4 v_Color;
        void main() {
            vec2 clip = (a_Position / u_SurfaceSize) * 2.0 - 1.0;
            clip.y = -clip.y;
            gl_Position = vec4(clip, 0.0, 1.0);
            v_TexCoord = a_TexCoord;
            v_Color = a_Color;
        }
  """.trimIndent()

  private val fragmentShaderCode = """
        precision mediump float;
        varying vec2 v_TexCoord;
        varying vec4 v_Color;
        uniform sampler2D u_Texture;
        void main() {
            float mask = texture2D(u_Texture, v_TexCoord).a;
            float alpha = v_Color.a * mask;
            gl_FragColor = vec4(v_Color.rgb * alpha, alpha);
        }
  """.trimIndent()

  private var surfaceSize = Size.ZERO
  private lateinit var glProgram: GlProgram

  // One texture per atlas page; allocated lazily as the page count grows.
  private val atlasTexIds = IntArray(AssAtlasPipelineConfig.MAX_ATLAS_PAGES)
  private var allocatedPages = 0
  private var vertexBufferId = 0

  private var aPosition = 0
  private var aTexCoord = 0
  private var aColor = 0
  private var uTexture = 0
  private var uSurfaceSize = 0

  private var atlasAllocatedW = 0
  private var atlasAllocatedH = 0

  /**
   * Records the per-page texture dims and allocates the first page's texture. The C
   * side bakes UV denominators = these dims into the vertex stream and stacks pages
   * at byte multiples of width×height, so per-frame uploads stay partial
   * ([uploadPage]) — drivers keep stable texture allocations instead of churning on
   * packed-height changes — and extra pages allocate lazily ([ensurePageTexture]).
   */
  fun allocateAtlasTexture(width: Int, height: Int) {
    atlasAllocatedW = width
    atlasAllocatedH = height
    allocatedPages = 0
    ensurePageTexture(0)
  }

  /** Lazily allocates atlas-page textures through [page] at the recorded dims. */
  private fun ensurePageTexture(page: Int) {
    while (allocatedPages <= page && allocatedPages < atlasTexIds.size) {
      val p = allocatedPages
      val tex = IntArray(1)
      GLES20.glGenTextures(1, tex, 0)
      atlasTexIds[p] = tex[0]
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, atlasTexIds[p])
      GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
      GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
      GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
      GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
      GLES20.glTexImage2D(
        GLES20.GL_TEXTURE_2D, 0, GLES20.GL_ALPHA,
        atlasAllocatedW, atlasAllocatedH, 0,
        GLES20.GL_ALPHA, GLES20.GL_UNSIGNED_BYTE, null
      )
      allocatedPages = p + 1
    }
  }

  fun onSurfaceCreated() {
    glProgram = GlProgram(vertexShaderCode, fragmentShaderCode)
    GlUtil.checkGlError()
    glProgram.use()

    aPosition = glProgram.getAttributeArrayLocationAndEnable("a_Position")
    aTexCoord = glProgram.getAttributeArrayLocationAndEnable("a_TexCoord")
    aColor = glProgram.getAttributeArrayLocationAndEnable("a_Color")
    uTexture = glProgram.getUniformLocation("u_Texture")
    uSurfaceSize = glProgram.getUniformLocation("u_SurfaceSize")

    GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
    GLES20.glUniform1i(uTexture, 0)
    // Atlas-page textures are generated lazily in allocateAtlasTexture/ensurePageTexture.

    val buf = IntArray(1)
    GLES20.glGenBuffers(1, buf, 0)
    vertexBufferId = buf[0]

    GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1)
    GLES20.glEnable(GLES20.GL_BLEND)
    // Store the translucent SurfaceView buffer premultiplied, matching Android
    // layer composition and avoiding a second alpha multiply on libass masks.
    GLES20.glBlendFuncSeparate(
      GLES20.GL_ONE,
      GLES20.GL_ONE_MINUS_SRC_ALPHA,
      GLES20.GL_ONE,
      GLES20.GL_ONE_MINUS_SRC_ALPHA
    )
  }

  fun onSurfaceChanged(width: Int, height: Int) {
    surfaceSize = Size(width, height)
    // Render libass at RENDER_SCALE of the physical surface; the viewport stays
    // full-size so the GL upscales the lower-res atlas to fill the surface. The
    // u_SurfaceSize denominator must match the (scaled) libass frame so vertices,
    // baked in frame-space, still map across the whole surface.
    val frameW = AssAtlasPipelineConfig.scaledForRender(width)
    val frameH = AssAtlasPipelineConfig.scaledForRender(height)
    assHandler.render?.setFrameSize(frameW, frameH)
    GLES20.glViewport(0, 0, width, height)
    GLES20.glUniform2f(uSurfaceSize, frameW.toFloat(), frameH.toFloat())
  }

  fun onDrawFrame(payload: AtlasDrawSnapshot, reuseUploads: Boolean) {
    GlUtil.clearFocusedBuffers()

    val frame = payload.frame
    val quadCount = frame.quadCount
    if (quadCount == 0) return

    if (!reuseUploads) {
      uploadVertices(payload.vertexBuf, quadCount)
    }

    GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vertexBufferId)
    val stride = AssAtlasPipelineConfig.BYTES_PER_VERTEX
    GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, stride, 0)
    GLES20.glVertexAttribPointer(aTexCoord, 2, GLES20.GL_FLOAT, false, stride, 8)
    GLES20.glVertexAttribPointer(aColor, 4, GLES20.GL_FLOAT, false, stride, 16)

    // Each atlas page is its own texture; its quads are one contiguous run in the
    // stream (page assignment is monotonic in painter order). Upload + draw each in
    // turn, which reproduces the libass blend order across pages.
    GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
    var quadOffset = 0
    for (p in 0 until frame.pageCount) {
      val pageQuads = frame.pageQuadCounts[p]
      if (pageQuads > 0) {
        ensurePageTexture(p)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, atlasTexIds[p])
        if (!reuseUploads) uploadPage(payload.atlasBuf, p, frame.atlasWidth, frame.pageHeights[p])
        GLES20.glDrawArrays(GLES20.GL_TRIANGLES, quadOffset * 6, pageQuads * 6)
      }
      quadOffset += pageQuads
    }
  }

  /** Uploads page [page]'s packed rows from the stacked atlas buffer into the
   *  currently-bound page texture. */
  private fun uploadPage(atlasBuf: ByteBuffer, page: Int, atlasW: Int, pageH: Int) {
    if (pageH <= 0) return
    if (atlasW != atlasAllocatedW || pageH > atlasAllocatedH) {
      // Defensive: dims disagree with the allocation (shouldn't happen — both sides
      // resolve dims through the same first-wins gate).
      Log.w("AssAtlasRenderer", "page upload ${atlasW}x$pageH outside allocation ${atlasAllocatedW}x$atlasAllocatedH")
      return
    }
    val start = page * atlasW * atlasAllocatedH
    atlasBuf.clear()
    atlasBuf.limit(start + atlasW * pageH)
    atlasBuf.position(start)
    GLES20.glTexSubImage2D(
      GLES20.GL_TEXTURE_2D, 0, 0, 0, atlasW, pageH,
      GLES20.GL_ALPHA, GLES20.GL_UNSIGNED_BYTE, atlasBuf
    )
  }

  private fun uploadVertices(vertexBuf: ByteBuffer, quadCount: Int) {
    val size = quadCount * AssAtlasPipelineConfig.BYTES_PER_QUAD
    vertexBuf.position(0).limit(size)
    GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vertexBufferId)
    GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, size, vertexBuf, GLES20.GL_STREAM_DRAW)
  }

  fun onSurfaceDestroyed() {
    if (allocatedPages > 0) {
      GLES20.glDeleteTextures(allocatedPages, atlasTexIds, 0)
      atlasTexIds.fill(0)
      allocatedPages = 0
    }
    if (vertexBufferId != 0) {
      val buf = intArrayOf(vertexBufferId)
      GLES20.glDeleteBuffers(1, buf, 0)
      vertexBufferId = 0
    }
    if (::glProgram.isInitialized) glProgram.delete()
  }
}
