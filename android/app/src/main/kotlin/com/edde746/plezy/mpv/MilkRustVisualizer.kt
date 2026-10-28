package com.edde746.plezy.mpv

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.Surface
import io.flutter.view.TextureRegistry
import java.io.File

/** Optional native engine. The AAR session token is never an mpv pointer. */
internal object MilkRustNativeBridge {
  val loadError: String? = try {
    System.loadLibrary("plezy_milkrust_host")
    null
  } catch (_: UnsatisfiedLinkError) {
    "Native MilkRust host is not installed in this build."
  }
  external fun dependencyError(): String
  external fun create(playerSession: Long, surface: Surface): Long
  external fun destroy(handle: Long)
  external fun load(handle: Long, path: String, root: String)
  external fun resize(handle: Long, width: Int, height: Int)
  external fun pause(handle: Long, paused: Boolean)
  external fun status(handle: Long): Array<String>

  // Called on the native consumer, never on the playback callback or UI thread.
  @JvmStatic fun decodeTexture(path: String): Bitmap {
    val file = File(path)
    val encodedSize = file.length()
    require(encodedSize in 1..16L * 1024 * 1024) { "Texture exceeds its byte budget." }
    val bytes = file.inputStream().use { stream ->
      val buffer = ByteArray(encodedSize.toInt())
      var offset = 0
      while (offset < buffer.size) {
        val count = stream.read(buffer, offset, buffer.size - offset)
        check(count > 0) { "Texture changed during read." }
        offset += count
      }
      check(stream.read() == -1) { "Texture changed during read." }
      buffer
    }
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
    require(
      bounds.outWidth in 1..4096 &&
        bounds.outHeight in 1..4096 &&
        bounds.outWidth.toLong() * bounds.outHeight <= 8L * 1024 * 1024
    ) { "Texture dimensions exceed the decoded image budget." }
    val options = BitmapFactory.Options().apply {
      inPreferredConfig = Bitmap.Config.ARGB_8888
      inScaled = false
      inPremultiplied = false
    }
    return checkNotNull(BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)) { "Texture decode failed." }
  }
}

internal class MilkRustVisualizer(registry: TextureRegistry, playerSession: Long) : AutoCloseable {
  private val entry = registry.createSurfaceTexture()
  private val surface = Surface(entry.surfaceTexture())
  private var handle = 0L
  val textureId: Long get() = entry.id()
  init {
    try {
      handle = MilkRustNativeBridge.create(playerSession, surface)
      check(handle != 0L)
    } catch (error: Throwable) {
      surface.release()
      entry.release()
      throw error
    }
  }
  fun load(path: String, root: String) = MilkRustNativeBridge.load(handle, path, root)
  fun resize(width: Int, height: Int) = MilkRustNativeBridge.resize(handle, width, height)
  fun pause(paused: Boolean) = MilkRustNativeBridge.pause(handle, paused)
  fun status(): Map<String, Any> {
    val values = MilkRustNativeBridge.status(handle)
    check(values.size == 6) { "Invalid native status." }
    return mapOf(
      "state" to values[0],
      "reason" to values[1],
      "hasFrame" to (values[2] == "1"),
      "droppedFrames" to values[3].toLong(),
      "width" to values[4].toInt(),
      "height" to values[5].toInt(),
      "engine" to "milkrust"
    )
  }
  override fun close() {
    if (handle == 0L) return
    val retired = handle
    handle = 0
    try {
      MilkRustNativeBridge.destroy(retired)
    } finally {
      surface.release()
      entry.release()
    }
  }
}
