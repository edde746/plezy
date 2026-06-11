package com.edde746.plezy.libass

import java.nio.ByteBuffer
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class AssRender(nativeAss: Long, private val lock: ReentrantLock) {

  companion object {

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

    @JvmStatic
    external fun nativeAssRenderFrameAtlas(
      render: Long,
      track: Long,
      time: Long,
      atlasBuf: ByteBuffer,
      atlasMaxWidth: Int,
      atlasMaxHeight: Int,
      vertexBuf: ByteBuffer
    ): AssAtlasFrame?

    @JvmStatic
    external fun nativeAssRenderDeinit(render: Long)
  }

  private var nativeRender: Long = nativeAssRenderInit(nativeAss)

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

  /**
   * Renders a frame into a packed ALPHA_8 texture atlas plus a single vertex stream
   * ready for `glDrawArrays(GL_TRIANGLES, 0, quadCount * 6)`.
   *
   * UVs are normalized against ([atlasMaxW], [atlasMaxH]) — the allocated texture
   * dims — so the caller can allocate the texture once and `glTexSubImage2D` only
   * the packed rows. Images that exceed the capacity are dropped and counted in
   * [AssAtlasFrame.truncated]; the render never fails on content size.
   *
   * @param atlasBuf     direct ByteBuffer receiving the packed pixels (≥ atlasMaxW × atlasMaxH)
   * @param atlasMaxW    atlas row stride in pixels (bound by `GL_MAX_TEXTURE_SIZE`)
   * @param atlasMaxH    atlas height in pixels (bound by `GL_MAX_TEXTURE_SIZE`)
   * @param vertexBuf    direct ByteBuffer receiving the vertex stream (192 bytes per quad)
   */
  /** How long the most recent [renderFrameAtlas] waited to acquire the shared
   *  libass lock (contended by track dialogue/font feeding), in milliseconds. */
  @Volatile
  var lastLockWaitMs: Long = 0
    private set

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
      return nativeAssRenderFrameAtlas(nativeRender, t.nativeAssTrack, time, atlasBuf, atlasMaxW, atlasMaxH, vertexBuf)
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
