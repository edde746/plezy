package com.amaze.vibestream.exoplayer

import android.view.SurfaceControl
import androidx.annotation.Keep

/**
 * EXPERIMENTAL SPIKE: the API-34 transaction callback path is the only in-app signal we have
 * for comparing the codec video plane and the libass overlay plane with the same clock.
 */
// R8 cannot see the JNI-by-name callback edge, and class-level @Keep is not enough for members.
@Keep
object SurfaceTxProbe {
  init {
    System.loadLibrary("asskt")
  }

  const val SOURCE_VIDEO = 0
  const val SOURCE_OVERLAY = 1

  // CLOCK_MONOTONIC keeps native callback times comparable with ExoPlayer release targets.
  @Volatile
  @JvmStatic
  var sink: ((Long, Long, Long, Int, Int, Int, Long) -> Unit)? = null

  // The same transaction must be applied to the frame so the callback follows that buffer.
  @JvmStatic
  external fun nativeAttach(transaction: SurfaceControl.Transaction, tag: Long, source: Int)

  // JNI calls this by name after shrink.
  @Keep
  @JvmStatic
  fun onResult(
    tag: Long,
    latchNs: Long,
    releaseNs: Long,
    surfaceCount: Int,
    fenceState: Int,
    source: Int,
    callbackNs: Long
  ) {
    val s = sink ?: return
    s.invoke(tag, latchNs, releaseNs, surfaceCount, fenceState, source, callbackNs)
  }
}
