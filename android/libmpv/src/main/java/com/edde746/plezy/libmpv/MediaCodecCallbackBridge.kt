package com.edde746.plezy.libmpv

import android.media.MediaCodec
import android.media.MediaFormat
import android.os.Handler
import android.os.HandlerThread
import android.os.Process

/**
 * libavcodec's MediaCodec callback bridge (`libavcodec/jni.h`,
 * `av_jni_set_mediacodec_callback_class`).
 *
 * FFmpeg's Java MediaCodec wrapper needs a Java object to receive
 * [MediaCodec.Callback] and [MediaCodec.OnFrameRenderedListener] events, and
 * a library cannot ship one; this is that object. `main.cpp` registers the
 * class once, libavcodec instantiates it per codec with the native codec
 * handle, binds the native methods below with `RegisterNatives`, hands the
 * platform [handler]'s thread for delivery, and calls [release] right before
 * freeing the codec. Nothing in the app calls this class.
 *
 * Every callback runs on the object's own Looper thread, at the priority the
 * NDK gives its codec looper. [release] serializes against them: a callback
 * that observes it is dropped, and once it returns no callback touches native
 * again — the native side frees the handle on that guarantee.
 */
@Suppress("unused")
internal class MediaCodecCallbackBridge(private val codec: Long) :
  MediaCodec.Callback(),
  MediaCodec.OnFrameRenderedListener {
  private val thread = HandlerThread("libavcodec-mediacodec", Process.THREAD_PRIORITY_VIDEO).apply { start() }
  private val callbackHandler = Handler(thread.looper)
  private val lock = Any()
  private var released = false

  fun handler(): Handler = callbackHandler

  fun release() {
    synchronized(lock) { released = true }
    thread.quitSafely()
  }

  override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
    synchronized(lock) {
      if (!released) nativeOnInputAvailable(this.codec, index)
    }
  }

  override fun onOutputBufferAvailable(codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo) {
    synchronized(lock) {
      if (!released) nativeOnOutputAvailable(this.codec, index, info.offset, info.size, info.presentationTimeUs, info.flags)
    }
  }

  override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) {
    synchronized(lock) {
      if (!released) nativeOnFormatChanged(this.codec, format)
    }
  }

  override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) {
    synchronized(lock) {
      if (!released) nativeOnError(this.codec, e.errorCode, e.diagnosticInfo)
    }
  }

  override fun onFrameRendered(codec: MediaCodec, presentationTimeUs: Long, nanoTime: Long) {
    synchronized(lock) {
      if (!released) nativeOnFrameRendered(this.codec, presentationTimeUs, nanoTime)
    }
  }

  companion object {
    @JvmStatic private external fun nativeOnInputAvailable(codec: Long, index: Int)

    @JvmStatic private external fun nativeOnOutputAvailable(
      codec: Long,
      index: Int,
      offset: Int,
      size: Int,
      presentationTimeUs: Long,
      flags: Int
    )

    @JvmStatic private external fun nativeOnFormatChanged(codec: Long, format: MediaFormat)

    @JvmStatic private external fun nativeOnError(codec: Long, errorCode: Int, diagnosticInfo: String)

    @JvmStatic private external fun nativeOnFrameRendered(codec: Long, presentationTimeUs: Long, nanoTime: Long)
  }
}
