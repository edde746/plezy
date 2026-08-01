package com.edde746.plezy.libass

import java.nio.ByteBuffer
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class AssRender(nativeAss: Long, private val lock: ReentrantLock) {

  companion object {

    /** Must match MAX_ATLAS_PAGES + the header layout in AssKt.c (`writeAtlasHeader`). */
    private const val MAX_ATLAS_PAGES = 4
    private const val HEADER_INTS = 7 + 2 * MAX_ATLAS_PAGES

    @JvmStatic
    external fun nativeAssRenderInit(ass: Long): Long

    @JvmStatic
    external fun nativeAssRenderSetFontScale(render: Long, scale: Float)

    @JvmStatic
    external fun nativeAssRenderSetCacheLimit(render: Long, glyphMax: Int, bitmapMaxSize: Int)

    @JvmStatic
    external fun nativeAssRenderSetStorageSize(render: Long, width: Int, height: Int)

    @JvmStatic
    external fun nativeAssRenderSetFrameSize(render: Long, width: Int, height: Int)

    @JvmStatic
    external fun nativeAssRenderSetMargins(render: Long, top: Int, bottom: Int, left: Int, right: Int)

    @JvmStatic
    external fun nativeAssRenderSetUseMargins(render: Long, use: Boolean)

    /**
     * Renders into [atlasBuf]/[vertexBuf] and writes frame metadata into [header]
     * (layout per `writeAtlasHeader` in AssKt.c). Returns 1 when the header was written,
     * 0 for missing buffers/handles. The frame object is built on the Kotlin side from
     * the header so the JNI boundary never constructs it (R8-safe; see [renderFrameAtlas]).
     */
    @JvmStatic
    external fun nativeAssRenderFrameAtlas(
      render: Long,
      track: Long,
      time: Long,
      atlasBuf: ByteBuffer,
      atlasMaxWidth: Int,
      atlasMaxHeight: Int,
      vertexBuf: ByteBuffer,
      header: IntArray
    ): Int

    @JvmStatic
    external fun nativeAssRenderDeinit(render: Long)
  }

  private var nativeRender: Long = nativeAssRenderInit(nativeAss)

  /** Reusable JNI frame-metadata header (see `writeAtlasHeader` in AssKt.c). Calls to
   *  [renderFrameAtlas] are serialized by [lock], so one buffer is safe to reuse. */
  private val frameHeader = IntArray(HEADER_INTS)

  @Volatile
  var released = false
    private set

  private var track: AssTrack? = null

  /**
   * Bumped on every renderer-state mutation (track, sizes, margins, font scale).
   * Lets the render-ahead pipeline detect that a speculatively rendered frame was
   * produced against stale state and must not be presented.
   */
  private val generation = java.util.concurrent.atomic.AtomicInteger(0)

  /** Current renderer-state generation; see [generation]. */
  val stateGeneration: Int get() = generation.get()

  /** Runs [block] with the native handle under the shared libass lock; no-op once released. */
  private inline fun withNative(block: (Long) -> Unit) {
    lock.withLock {
      if (!released && nativeRender != 0L) block(nativeRender)
    }
  }

  fun setTrack(track: AssTrack?) {
    generation.incrementAndGet()
    lock.withLock { this.track = track }
  }

  fun setFontScale(scale: Float) {
    generation.incrementAndGet()
    withNative { nativeAssRenderSetFontScale(it, scale) }
  }

  fun setCacheLimit(glyphMax: Int, bitmapMaxSize: Int) = withNative { nativeAssRenderSetCacheLimit(it, glyphMax, bitmapMaxSize) }

  fun setStorageSize(width: Int, height: Int) {
    generation.incrementAndGet()
    withNative { nativeAssRenderSetStorageSize(it, width, height) }
  }

  fun setFrameSize(width: Int, height: Int) {
    generation.incrementAndGet()
    withNative { nativeAssRenderSetFrameSize(it, width, height) }
  }

  /**
   * mpv-style frame margins: offsets of the video dst rect within the frame set by
   * [setFrameSize]. Negative when the video extends beyond the frame (zoomed in / cover).
   */
  fun setMargins(top: Int, bottom: Int, left: Int, right: Int) {
    generation.incrementAndGet()
    withNative { nativeAssRenderSetMargins(it, top, bottom, left, right) }
  }

  /**
   * mpv's sub-ass-force-margins: lay out non-positioned events against the full frame
   * (kept on the visible screen) instead of the video rect between the margins.
   */
  fun setUseMargins(use: Boolean) {
    generation.incrementAndGet()
    withNative { nativeAssRenderSetUseMargins(it, use) }
  }

  /** How long the most recent [renderFrameAtlas] waited to acquire the shared
   *  libass lock (contended by track dialogue/font feeding), in milliseconds. */
  @Volatile
  var lastLockWaitMs: Long = 0
    private set

  /**
   * Renders a frame into a packed ALPHA_8 texture atlas plus a vertex stream.
   *
   * The atlas may span one or more vertically-stacked pages (a dense full-screen
   * sign can exceed a single GL-max texture); vertices stay in libass painter order,
   * grouped per page ([AssAtlasFrame.pageQuadCounts]). The caller uploads each page
   * to its own texture and draws it with its own `glDrawArrays`, reproducing the
   * blend order. UVs are page-local, normalized against ([atlasMaxW], [atlasMaxH]).
   *
   * Never fails on content size: when the frame needs more pages than [atlasBuf]
   * holds, [AssAtlasFrame.requiredPages] signals the caller to grow the buffer and
   * re-render; only tiles past `MAX_ATLAS_PAGES` or the vertex budget are dropped
   * and counted in [AssAtlasFrame.truncated].
   *
   * @param atlasBuf   direct ByteBuffer receiving the stacked pages (≥ atlasMaxW × atlasMaxH per page)
   * @param atlasMaxW  per-page atlas row stride in pixels (bound by `GL_MAX_TEXTURE_SIZE`)
   * @param atlasMaxH  per-page atlas height in pixels (bound by `GL_MAX_TEXTURE_SIZE`)
   * @param vertexBuf  direct ByteBuffer receiving the vertex stream (192 bytes per quad)
   */
  fun renderFrameAtlas(
    time: Long,
    atlasBuf: ByteBuffer,
    atlasMaxW: Int,
    atlasMaxH: Int,
    vertexBuf: ByteBuffer
  ): AssAtlasFrame? {
    val tQueue = System.nanoTime()
    lock.withLock {
      lastLockWaitMs = (System.nanoTime() - tQueue) / 1_000_000
      if (released || nativeRender == 0L) return null
      val t = track ?: return null
      if (t.released || t.nativeAssTrack == 0L) return null
      val header = frameHeader
      val status =
        nativeAssRenderFrameAtlas(nativeRender, t.nativeAssTrack, time, atlasBuf, atlasMaxW, atlasMaxH, vertexBuf, header)
      if (status == 0) return null
      val pageCount = header[6]
      return AssAtlasFrame(
        atlasWidth = header[0],
        pageHeights = IntArray(pageCount) { header[7 + it] },
        pageQuadCounts = IntArray(pageCount) { header[7 + MAX_ATLAS_PAGES + it] },
        quadCount = header[1],
        changed = header[2],
        truncated = header[3],
        requiredPages = header[4],
        hasOutput = header[5] != 0
      )
    }
  }

  fun release() {
    lock.withLock {
      if (released) return
      released = true
      track = null
      if (nativeRender != 0L) {
        nativeAssRenderDeinit(nativeRender)
        nativeRender = 0
      }
    }
  }

  protected fun finalize() {
    release()
  }
}
