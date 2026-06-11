package com.edde746.plezy.libass.media.widget

import android.opengl.EGL14
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.opengl.GLES20
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
import com.edde746.plezy.libass.media.AssHandler
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicReference

/**
 * Atlas-rendering pipeline behind [AssSubtitleSurfaceView].
 * Runs libass on its own [HandlerThread] into a packed
 * ALPHA_8 texture atlas plus a single vertex stream, and a GL thread that uploads
 * both and issues one `glDrawArrays` per frame. Each swap is pinned to the video's
 * target release time via [EGLExt.eglPresentationTimeANDROID]: SurfaceFlinger holds
 * the buffer and composes it on the same vsync as the corresponding video frame.
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
}

/** Payload handed from the libass worker to the GL thread. */
internal class AtlasPayload(
  val slotIndex: Int,
  val atlasBuf: ByteBuffer,
  val vertexBuf: ByteBuffer,
  var frame: AssAtlasFrame,
  var presentationTimeUs: Long,
  var releaseTimeNs: Long,
  /** Bumped on every content-changing render; lets the GL thread tell "same slot,
   *  new content" apart from "same slot, same content" when deciding to re-upload. */
  var contentSeq: Long = 0L
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
  assHandler: AssHandler,
  lowRamDevice: Boolean = false
) {
  private val surfaceWidth = width
  private val surfaceHeight = height

  // 3 slots give the render-ahead engine a writable target while one slot is
  // posted and another is in GL's hands; low-RAM devices stay at 2 slots with
  // speculation off (the legacy on-demand behavior, ~19 MB less in buffers).
  private val slotCount = if (lowRamDevice) 2 else 3
  private val speculationEnabled = AssAtlasPipelineConfig.SPECULATION_ENABLED && slotCount >= 3

  // Atlas dims, resolved exactly once (first-wins): normally by the GL thread from
  // GL_MAX_TEXTURE_SIZE right after EGL init; by the libass thread's 1 s fallback
  // if GL never comes up. Both threads then agree on the dims, which matters
  // because the C side bakes UV denominators = these dims into the vertex stream
  // and the GL side allocates the texture once at these dims.
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
        atlasBuf = ByteBuffer.allocateDirect(w * h).order(ByteOrder.nativeOrder()),
        vertexBuf = ByteBuffer.allocateDirect(
          AssAtlasPipelineConfig.MAX_QUADS * AssAtlasPipelineConfig.BYTES_PER_QUAD
        ).order(ByteOrder.nativeOrder()),
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
  private val glThread = AtlasGlThread(
    surface,
    width,
    height,
    assHandler,
    takePending = {
      pendingPayload.getAndSet(null)?.also { glLastTakenSlot = it.slotIndex }
    },
    resolveAtlasDims = ::resolveAtlasDims
  )
  private val libassThread = AtlasLibassThread(
    assHandler,
    acquireSlots = ::acquireSlots,
    speculationEnabled = speculationEnabled,
    glTakenSlot = { glLastTakenSlot },
    onFrameReady = { payload ->
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

  /** Cache-warming prefetch renders of upcoming events. */
  val prefetchCount: Long get() = libassThread.prefetchCount

  /** Worst (minimum) lead of a changed-content pinned swap vs its target release
   *  time, in ms; negative = the new content was queued after the video frame's
   *  vsync. Long.MAX_VALUE until a changed pinned swap happened. */
  val minLeadChangedMs: Long get() = glThread.minLeadChangedMs

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
  private val onFrameReady: (AtlasPayload) -> Unit
) : HandlerThread(TAG, Process.THREAD_PRIORITY_DISPLAY) {

  /** Immutable (pts, release) request — handed off through a single atomic so a
   *  concurrent enqueue can neither be lost by drain's consume nor torn in half.
   *  [enqueueNs] timestamps the handoff so drain can report how long the request
   *  sat behind an in-flight render (the queue-wait component of subtitle lag). */
  private class PendingFrame(val ptsUs: Long, val releaseNs: Long, val enqueueNs: Long = System.nanoTime())

  private lateinit var handler: Handler

  private val pending = AtomicReference<PendingFrame?>(null)

  @Volatile private var lastRequestedPtsUs = UNSET
  private var contentSeqCounter = 0L

  // Thread-confined; created on first render so non-ASS playback never allocates.
  private var engine: SpecRenderEngine? = null

  val specHits: Long get() = engine?.specHits ?: 0L
  val specMisses: Long get() = engine?.specMisses ?: 0L
  val specSkips: Long get() = engine?.specSkips ?: 0L
  val prefetchCount: Long get() = engine?.prefetchCount ?: 0L

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
    val dropped = pending.getAndSet(PendingFrame(presentationTimeUs, releaseTimeNs))
    if (dropped != null && AssAtlasPipelineConfig.TIMING_LOGS) {
      // A request was coalesced away — the renderer is behind by at least one
      // frame. agedMs = how long the dropped request had been waiting.
      Log.d(
        TAG,
        "drop pts=${dropped.ptsUs / 1000}ms agedMs=${(System.nanoTime() - dropped.enqueueNs) / 1_000_000} " +
          "replacedBy=${presentationTimeUs / 1000}ms"
      )
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

  private fun ensureEngine(slots: AtlasSlots): SpecRenderEngine {
    engine?.let { return it }
    return SpecRenderEngine(
      slotCount = slots.payloads.size,
      speculationEnabled = speculationEnabled,
      renderAt = { timeMs, slot -> timedRender(timeMs, slots, slot) },
      // Renderer identity in the high bits + its state generation in the low bits:
      // a recreated renderer (media item transition) can never alias a stale
      // speculation, even if the new generation counter happens to match.
      stateGeneration = {
        assHandler.render?.let {
          (System.identityHashCode(it).toLong() shl 32) or (it.stateGeneration.toLong() and 0xffffffffL)
        } ?: -1L
      },
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
    val frame = render.renderFrameAtlas(timeMs, payload.atlasBuf, slots.atlasW, slots.atlasH, payload.vertexBuf)
      ?: return null
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
    val pts = request.ptsUs
    val releaseNs = request.releaseNs
    lastRequestedPtsUs = pts
    val tDrain = System.nanoTime()
    // How long the request sat in the handoff (behind an in-flight on-demand or
    // speculative render) — the queue-wait component of any subtitle lag.
    val waitMs = (tDrain - request.enqueueNs) / 1_000_000
    // Before any ASS render exists (SRT/VTT or no subs) do nothing — this also
    // keeps the slot buffers unallocated for non-ASS playback.
    if (assHandler.render == null) return
    val slots = acquireSlots()
    val engine = ensureEngine(slots)
    val pinned = releaseNs != C.TIME_UNSET
    // Budget left until the video frame's vsync when we START servicing.
    val budgetMs = if (pinned) (releaseNs - tDrain) / 1_000_000 else -1L

    when (val outcome = engine.service(pts, pinned)) {
      is SpecRenderEngine.Outcome.Post -> {
        val payload = slots.payloads[outcome.slot]
        if (outcome.newContent) {
          payload.frame = outcome.frame
          payload.contentSeq = ++contentSeqCounter
        }
        payload.presentationTimeUs = pts
        payload.releaseTimeNs = releaseNs
        onFrameReady(payload)
        if (AssAtlasPipelineConfig.TIMING_LOGS) {
          Log.d(
            TAG,
            "render pts=${pts / 1000}ms seq=${payload.contentSeq} waitMs=$waitMs budgetMs=$budgetMs " +
              "libassMs=$lastLibassMs lockWaitMs=${assHandler.render?.lastLockWaitMs} " +
              "specHit=${outcome.specHit} changed=${payload.frame.changed} quads=${payload.frame.quadCount} " +
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
    engine.speculateAfter(pts, pinned, hasPending = pending.get() != null)?.let { write ->
      val payload = slots.payloads[write.slot]
      payload.frame = write.frame
      payload.contentSeq = ++contentSeqCounter
      if (AssAtlasPipelineConfig.TIMING_LOGS) {
        Log.d(
          TAG,
          "spec after=${pts / 1000}ms seq=${payload.contentSeq} libassMs=$lastLibassMs " +
            "lockWaitMs=${assHandler.render?.lastLockWaitMs} slot=${write.slot} quads=${write.frame.quadCount}"
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
    val nowMs = ptsUs / 1000
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
 * `glDrawArrays` per frame. Swaps immediately with the swap pinned to the video's
 * target release time via [EGLExt.eglPresentationTimeANDROID]; SurfaceFlinger
 * holds the buffer until then, so the thread is never blocked waiting for a vsync.
 */
@UnstableApi
private class AtlasGlThread(
  private val surface: Surface,
  @Volatile private var width: Int,
  @Volatile private var height: Int,
  private val assHandler: AssHandler,
  private val takePending: () -> AtlasPayload?,
  private val resolveAtlasDims: (maxTextureSize: Int) -> Pair<Int, Int>
) : HandlerThread(TAG, Process.THREAD_PRIORITY_DISPLAY) {

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
      // thread's fallback) and allocate the texture once at those dims — uploads
      // are glTexSubImage2D of the packed rows from then on.
      val maxTexture = IntArray(1)
      GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, maxTexture, 0)
      val (atlasW, atlasH) = resolveAtlasDims(maxTexture[0])
      renderer.allocateAtlasTexture(atlasW, atlasH)
      sizeChanged(width, height)
    } catch (e: GlUtil.GlException) {
      Log.e(TAG, "Failed to initialize EGL", e)
    }
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
    val payload = takePending() ?: return

    // Render immediately (GL commands queue on the GPU). Re-upload only when the
    // slot's content actually changed — identity alone is not enough because the
    // libass side rewrites slot buffers in place (contentSeq tracks the rewrites).
    val t0 = System.nanoTime()
    val reuse = payload === lastUploadedPayload && payload.contentSeq == lastUploadedSeq
    renderer.onDrawFrame(payload, reuseUploads = reuse)
    lastUploadedPayload = payload
    lastUploadedSeq = payload.contentSeq
    val t1 = System.nanoTime()

    // Swap immediately with the presentation time set: SurfaceFlinger holds the
    // queued buffer until the video frame's target release time, so the subtitle
    // can never appear early, and the GL thread is free again within a couple of
    // milliseconds. Sleeping here until near the target vsync (as a removed
    // TextureView path once required) made this thread blind for almost a whole
    // frame interval — the single-slot latest-wins handoff would then drop an
    // intermediate subtitle state (e.g. the transition to blank), showing the
    // previous state one frame too long.
    if (payload.releaseTimeNs != C.TIME_UNSET) {
      EGLExt.eglPresentationTimeANDROID(eglDisplay, eglSurface, payload.releaseTimeNs)
    }
    EGL14.eglSwapBuffers(eglDisplay, eglSurface)
    val t2 = System.nanoTime()
    if (payload.releaseTimeNs != C.TIME_UNSET) {
      swapCount++
      val lateNs = t2 - payload.releaseTimeNs
      if (lateNs > LATE_THRESHOLD_NS) {
        lateSwapCount++
        val lateMs = lateNs / 1_000_000
        if (lateMs > maxLateMs) maxLateMs = lateMs
      }
      // Lead of changed-content swaps is the frame-perfection signal: ≥ 0 means
      // the new subtitle content reached the queue before the video frame's vsync.
      if (payload.contentSeq != lastSwappedSeq) {
        val leadMs = -lateNs / 1_000_000
        if (leadMs < minLeadChangedMs) minLeadChangedMs = leadMs
      }
    }
    lastSwappedSeq = payload.contentSeq
    if (AssAtlasPipelineConfig.TIMING_LOGS) {
      val pinned = payload.releaseTimeNs != C.TIME_UNSET
      // headroomMs: slack before the target vsync when GL STARTED; leadMs: slack
      // when the buffer was actually queued (negative = queued after the vsync).
      val headroomMs = if (pinned) (payload.releaseTimeNs - t0) / 1_000_000 else -1L
      val leadMs = if (pinned) (payload.releaseTimeNs - t2) / 1_000_000 else -1L
      Log.d(
        TAG,
        "swap pts=${payload.presentationTimeUs / 1000}ms seq=${payload.contentSeq} " +
          "quads=${payload.frame.quadCount} reused=$reuse drawMs=${(t1 - t0) / 1_000_000} " +
          "swapMs=${(t2 - t1) / 1_000_000} headroomMs=$headroomMs leadMs=$leadMs pinned=$pinned"
      )
    }
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

    /**
     * Swaps finishing this far past the target release time arrived after the
     * buffer should already have been queued and may miss the frame's vsync —
     * actual slack depends on the display's vsync offset from the release time.
     */
    private const val LATE_THRESHOLD_NS = 4_000_000L
  }
}

/**
 * GL-side work for the atlas-based path. Maintains a single atlas texture and a
 * single vertex buffer; uploads them per frame (unless the payload identity
 * matches the last upload) and issues one `glDrawArrays` for the whole frame.
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
            float alpha = texture2D(u_Texture, v_TexCoord).a;
            gl_FragColor = v_Color * alpha;
        }
  """.trimIndent()

  private var surfaceSize = Size.ZERO
  private lateinit var glProgram: GlProgram

  private var atlasTexId = 0
  private var vertexBufferId = 0

  private var aPosition = 0
  private var aTexCoord = 0
  private var aColor = 0
  private var uTexture = 0
  private var uSurfaceSize = 0

  private var atlasAllocatedW = 0
  private var atlasAllocatedH = 0

  /**
   * Allocates the atlas texture once at the resolved dims. The C side bakes UV
   * denominators = these dims into the vertex stream, so per-frame uploads can be
   * partial ([uploadAtlas]) without ever reallocating — drivers keep one stable
   * texture allocation instead of churning on packed-height changes.
   */
  fun allocateAtlasTexture(width: Int, height: Int) {
    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, atlasTexId)
    GLES20.glTexImage2D(
      GLES20.GL_TEXTURE_2D, 0, GLES20.GL_ALPHA,
      width, height, 0,
      GLES20.GL_ALPHA, GLES20.GL_UNSIGNED_BYTE, null
    )
    atlasAllocatedW = width
    atlasAllocatedH = height
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

    val tex = IntArray(1)
    GLES20.glGenTextures(1, tex, 0)
    atlasTexId = tex[0]
    GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, atlasTexId)
    GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
    GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
    GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
    GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
    GLES20.glUniform1i(uTexture, 0)

    val buf = IntArray(1)
    GLES20.glGenBuffers(1, buf, 0)
    vertexBufferId = buf[0]

    GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1)
    GLES20.glEnable(GLES20.GL_BLEND)
    GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
  }

  fun onSurfaceChanged(width: Int, height: Int) {
    surfaceSize = Size(width, height)
    assHandler.render?.setFrameSize(width, height)
    GLES20.glViewport(0, 0, width, height)
    GLES20.glUniform2f(uSurfaceSize, width.toFloat(), height.toFloat())
  }

  fun onDrawFrame(payload: AtlasPayload, reuseUploads: Boolean) {
    GlUtil.clearFocusedBuffers()

    val frame = payload.frame
    val quadCount = frame.quadCount
    if (quadCount == 0) return

    if (!reuseUploads) {
      uploadAtlas(payload.atlasBuf, frame.atlasWidth, frame.atlasHeight)
      uploadVertices(payload.vertexBuf, quadCount)
    }

    GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vertexBufferId)
    val stride = AssAtlasPipelineConfig.BYTES_PER_VERTEX
    GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, stride, 0)
    GLES20.glVertexAttribPointer(aTexCoord, 2, GLES20.GL_FLOAT, false, stride, 8)
    GLES20.glVertexAttribPointer(aColor, 4, GLES20.GL_FLOAT, false, stride, 16)
    GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, quadCount * 6)
  }

  private fun uploadAtlas(atlasBuf: ByteBuffer, atlasW: Int, atlasH: Int) {
    atlasBuf.position(0).limit(atlasW * atlasH)
    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, atlasTexId)
    if (atlasW == atlasAllocatedW && atlasH <= atlasAllocatedH) {
      // Steady state: packed rows into the once-allocated texture.
      GLES20.glTexSubImage2D(
        GLES20.GL_TEXTURE_2D, 0, 0, 0, atlasW, atlasH,
        GLES20.GL_ALPHA, GLES20.GL_UNSIGNED_BYTE, atlasBuf
      )
    } else {
      // Defensive: dims disagree with the allocation (shouldn't happen — both
      // sides resolve dims through the same first-wins gate).
      Log.w("AssAtlasRenderer", "atlas upload ${atlasW}x$atlasH outside allocation ${atlasAllocatedW}x$atlasAllocatedH")
      GLES20.glTexImage2D(
        GLES20.GL_TEXTURE_2D, 0, GLES20.GL_ALPHA,
        atlasW, atlasH, 0,
        GLES20.GL_ALPHA, GLES20.GL_UNSIGNED_BYTE, atlasBuf
      )
      atlasAllocatedW = atlasW
      atlasAllocatedH = atlasH
    }
  }

  private fun uploadVertices(vertexBuf: ByteBuffer, quadCount: Int) {
    val size = quadCount * AssAtlasPipelineConfig.BYTES_PER_QUAD
    vertexBuf.position(0).limit(size)
    GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vertexBufferId)
    GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, size, vertexBuf, GLES20.GL_STREAM_DRAW)
  }

  fun onSurfaceDestroyed() {
    if (atlasTexId != 0) {
      val tex = intArrayOf(atlasTexId)
      GLES20.glDeleteTextures(1, tex, 0)
      atlasTexId = 0
    }
    if (vertexBufferId != 0) {
      val buf = intArrayOf(vertexBufferId)
      GLES20.glDeleteBuffers(1, buf, 0)
      vertexBufferId = 0
    }
    if (::glProgram.isInitialized) glProgram.delete()
  }
}
