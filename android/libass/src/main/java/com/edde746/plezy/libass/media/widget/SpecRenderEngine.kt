package com.edde746.plezy.libass.media.widget

import com.edde746.plezy.libass.AssAtlasFrame

/**
 * Decision core of the speculative render-ahead pipeline.
 *
 * The problem it solves: ExoPlayer's frame-metadata callback gives only ~40 ms
 * between "video frame scheduled" and that frame's vsync, while a changed-content
 * libass render can take longer — so a render started at the callback lands a
 * frame (or more) late. The engine renders the *predicted next* PTS right after
 * servicing the current one, in the dead time between frames; when the next
 * request matches the prediction, only the GL upload+swap (~6–11 ms) sits inside
 * the deadline.
 *
 * Pure logic, single-threaded (the libass worker) — rendering, buffers and GL
 * are behind injected closures, so the state machine is unit-testable. Only the
 * stat fields are read from other threads.
 *
 * Slot ownership invariant: a slot handed to GL ([lastPostedSlot]) or currently
 * read by GL ([glTakenSlot]) is never chosen as a render target. With 3 slots and
 * at most 2 exclusions a target always exists; with 2 slots (low-RAM devices)
 * speculation must be disabled and the legacy alternation behavior falls out.
 *
 * Key subtlety inherited from libass: `ass_render_frame`'s `changed` flag compares
 * against libass's *previous render* — which, with speculation, may be content
 * that never reached the screen. The engine therefore tracks [libassLastSlot]
 * (the slot holding libass's most recent render output) rather than the last
 * *posted* slot, and prefers it as the render target: on `changed == 0` the
 * buffers were untouched and that slot already holds exactly the right content.
 */
internal class SpecRenderEngine(
  private val slotCount: Int,
  private val speculationEnabled: Boolean,
  /**
   * Renders the current track at [timeMs] into the slot's buffers. Returns null
   * when the renderer/track is gone. The closure owns timing/stat accounting.
   */
  private val renderAt: (timeMs: Long, slot: Int) -> AssAtlasFrame?,
  /**
   * Renderer identity + state generation as one comparable value. Must change
   * whenever a speculatively rendered frame could be stale: margins, sizes,
   * track switches, renderer recreation.
   */
  private val stateGeneration: () -> Long,
  /** Slot the GL thread most recently took for drawing, or -1. Never write it. */
  private val glTakenSlot: () -> Int,
  /** Diagnostic sink for hit/miss/skip decisions; null disables (no string cost). */
  private val debugLog: ((String) -> Unit)? = null
) {

  /** What the caller should do after [service]. */
  sealed class Outcome {
    /** Nothing to post (no renderer, or no rendered content exists yet). */
    object Skip : Outcome()

    /**
     * Post [slot] to GL. [newContent] means this call wrote fresh content into
     * the slot (the caller bumps the payload's content seq). [specHit] means the
     * content was pre-rendered — no libass render ran inside the deadline.
     */
    class Post(val slot: Int, val frame: AssAtlasFrame, val newContent: Boolean, val specHit: Boolean) : Outcome()
  }

  /** A speculative render that wrote new content into [slot] (bump its seq). */
  class SpecWrite(val slot: Int, val frame: AssAtlasFrame)

  // Speculation state: content for specPtsUs is pre-rendered and lives either in
  // specSlot, or — when the spec render returned changed == 0 — is identical to
  // libassLastSlot's content (specIsLibassLast).
  private var specPtsUs = UNSET
  private var specSlot = -1
  private var specIsLibassLast = false
  private var specGen = 0L

  // The slot holding libass's most recent render output and its frame.
  private var libassLastSlot = -1
  private var libassLastFrame: AssAtlasFrame? = null
  private var lastPostedSlot = -1

  // Request-cadence estimator over pinned (playing) requests: median of the last
  // 8 PTS deltas, valid after 4, reset on any non-monotonic or > 250 ms jump.
  private val deltas = LongArray(DELTA_SAMPLES)
  private var deltaCount = 0
  private var deltaIndex = 0
  private var lastPinnedPtsUs = UNSET

  // Stats; single-writer (the libass thread), read from the stats path.
  @Volatile
  var specHits = 0L
    private set

  @Volatile
  var specMisses = 0L
    private set

  @Volatile
  var specSkips = 0L
    private set

  @Volatile
  var blankClearCount = 0L
    private set

  /**
   * Services a render request for [ptsUs]. [pinned] is false for invalidate
   * repaints (paused margin changes etc.), which never feed the cadence
   * estimator and never count as speculation misses against playback.
   */
  fun service(ptsUs: Long, pinned: Boolean): Outcome {
    if (pinned) updateDeltaEstimator(ptsUs)

    val ptsMs = toLibassMs(ptsUs)
    if (specPtsUs != UNSET) {
      val specPtsMs = toLibassMs(specPtsUs)
      val genNow = stateGeneration()
      val hit = genNow == specGen && ptsMs == specPtsMs
      val slot = if (specIsLibassLast) libassLastSlot else specSlot
      val frame = libassLastFrame
      val specPts = specPtsUs
      specPtsUs = UNSET
      if (hit && slot >= 0 && frame != null) {
        specHits++
        lastPostedSlot = slot
        debugLog?.invoke(
          "hit pts=${ptsMs}ms spec=${specPtsMs}ms dUs=${ptsUs - specPts} slot=$slot"
        )
        return Outcome.Post(slot, frame, newContent = false, specHit = true)
      }
      specMisses++
      debugLog?.invoke(
        "miss pts=${ptsMs}ms spec=${specPtsMs}ms dUs=${ptsUs - specPts} " +
          "gen=${if (genNow == specGen) "ok" else "CHANGED"} slot=$slot frame=${frame != null}"
      )
    } else {
      debugLog?.invoke("no-spec pts=${ptsMs}ms")
    }

    // On-demand render. For changed == 0 with visible output, the buffers were
    // untouched and libassLastSlot already holds the right content.
    val target = renderTargetSlot() ?: return Outcome.Skip
    val frame = renderAt(ptsMs, target) ?: return Outcome.Skip
    if (frame.changed == 0) {
      if (isImplicitBlank(frame)) {
        blankClearCount++
        libassLastSlot = target
        libassLastFrame = frame
        lastPostedSlot = target
        return Outcome.Post(target, frame, newContent = true, specHit = false)
      }
      val lastSlot = libassLastSlot
      val lastFrame = libassLastFrame ?: return Outcome.Skip
      if (lastSlot < 0) return Outcome.Skip
      lastPostedSlot = lastSlot
      return Outcome.Post(lastSlot, lastFrame, newContent = false, specHit = false)
    }
    libassLastSlot = target
    libassLastFrame = frame
    lastPostedSlot = target
    return Outcome.Post(target, frame, newContent = true, specHit = false)
  }

  /**
   * Speculatively renders the predicted next request ([servicedPtsUs] + median
   * delta) into a free slot. Call after posting the current frame; skipped while
   * paused ([pinned] false), when a newer request is already waiting, or while
   * the cadence estimator has no confident delta.
   */
  fun speculateAfter(servicedPtsUs: Long, pinned: Boolean, hasPending: Boolean): SpecWrite? {
    if (!speculationEnabled) return null
    if (!pinned || hasPending || !deltaValid()) {
      specSkips++
      debugLog?.invoke(
        "spec-skip after=${servicedPtsUs / 1000}ms pinned=$pinned pending=$hasPending cadence=${deltaValid()}"
      )
      return null
    }
    val target = renderTargetSlot() ?: run {
      specSkips++
      debugLog?.invoke("spec-skip after=${servicedPtsUs / 1000}ms no-free-slot")
      return null
    }
    val gen = stateGeneration()
    val specPts = servicedPtsUs + medianDeltaUs()
    val frame = renderAt(toLibassMs(specPts), target) ?: run {
      specSkips++
      return null
    }
    specGen = gen
    specPtsUs = specPts
    if (frame.changed == 0) {
      if (isImplicitBlank(frame)) {
        blankClearCount++
        libassLastSlot = target
        libassLastFrame = frame
        specIsLibassLast = false
        specSlot = target
        return SpecWrite(target, frame)
      }
      // Content at specPts is identical to libass's last render — nothing was
      // written; a hit will repost libassLastSlot (and GL will skip the upload).
      specIsLibassLast = true
      specSlot = -1
      return null
    }
    libassLastSlot = target
    libassLastFrame = frame
    specIsLibassLast = false
    specSlot = target
    return SpecWrite(target, frame)
  }

  private fun isImplicitBlank(frame: AssAtlasFrame): Boolean =
    !frame.hasOutput && libassLastFrame?.hasOutput == true

  /**
   * Pre-renders [ptsUs] (an upcoming event's start) purely to warm the
   * renderer's glyph/bitmap caches before that content is actually needed —
   * heavy typesetting otherwise pays its cache-cold rasterization (measured
   * 0.8–2.6 s on weak devices) exactly when the sign appears. The result is
   * never posted; like any render it becomes libass's last-rendered content,
   * so any pending speculation is invalidated first (its slot/content
   * references would go stale).
   *
   * Returns the slot written (caller bumps its content seq) or null when
   * nothing was rendered.
   */
  fun prefetch(ptsUs: Long): SpecWrite? {
    specPtsUs = UNSET
    val target = renderTargetSlot() ?: return null
    val frame = renderAt(toLibassMs(ptsUs), target) ?: return null
    prefetchCount++
    if (frame.changed == 0) return null
    libassLastSlot = target
    libassLastFrame = frame
    return SpecWrite(target, frame)
  }

  /** Cache-warming prefetch renders performed; single-writer, read cross-thread. */
  @Volatile
  var prefetchCount = 0L
    private set

  private fun renderTargetSlot(): Int? {
    // The GL exclusion only exists in ≥3-slot mode; with 2 slots this reduces to
    // the legacy "don't write the posted slot" alternation.
    val taken = if (slotCount > 2) glTakenSlot() else -1
    val last = libassLastSlot
    if (last >= 0 && last != lastPostedSlot && last != taken) return last
    for (s in 0 until slotCount) {
      if (s != lastPostedSlot && s != taken) return s
    }
    return null
  }

  private fun updateDeltaEstimator(ptsUs: Long) {
    val prev = lastPinnedPtsUs
    lastPinnedPtsUs = ptsUs
    if (prev == UNSET) return
    val d = ptsUs - prev
    if (d <= 0 || d > MAX_DELTA_US) {
      // Seek/discontinuity (or duplicate PTS): forget the cadence.
      deltaCount = 0
      deltaIndex = 0
      return
    }
    deltas[deltaIndex] = d
    deltaIndex = (deltaIndex + 1) % DELTA_SAMPLES
    if (deltaCount < DELTA_SAMPLES) deltaCount++
  }

  private fun deltaValid() = deltaCount >= MIN_DELTA_SAMPLES

  private fun medianDeltaUs(): Long {
    val copy = deltas.copyOfRange(0, deltaCount)
    copy.sort()
    return copy[deltaCount / 2]
  }

  private fun toLibassMs(ptsUs: Long): Long = Math.floorDiv(ptsUs, 1_000L)

  private companion object {
    const val UNSET = Long.MIN_VALUE
    const val DELTA_SAMPLES = 8
    const val MIN_DELTA_SAMPLES = 4
    const val MAX_DELTA_US = 250_000L
  }
}
