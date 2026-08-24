package com.edde746.plezy.exoplayer

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.io.RandomAccessFile
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Asserts the demuxer's JNI byte source stays reachable under R8.
 *
 * `ffmpeg_demuxer_jni.cc` resolves [FfmpegDemuxerJni.Input] by name — `FindClass`
 * on the interface, then `GetMethodID` for `position`, `read`, `readAt` and
 * `length`. Nothing in Kotlin calls those methods, so R8 may rename or remove
 * them while every debug check still passes; the AVIO callbacks would then fail
 * on the first read and every container would fall back to media3's extractors.
 * That is the same failure shape as #1703, which shipped.
 *
 * Run against the `minified` build type (`-Pplezy.testBuildType=minified`); on an
 * unminified variant it can only ever pass. Deliberately touches no media3 API,
 * so the only keep rules it depends on are the ones under test.
 */
@RunWith(AndroidJUnit4::class)
class FfmpegDemuxerReachabilityTest {

  @Test
  fun avioCallbacksResolveAndServeBothSequentialAndIndexReads() {
    assertTrue("ffmpeg demuxer JNI library is unavailable", FfmpegDemuxerJni.available)

    val fixture = copyFixture()
    val input = FileInput(fixture)
    try {
      // nativeOpen drives the whole handshake: FindClass on Input, GetMethodID
      // for all four methods, then avio reads served back through them. A
      // shrunk or renamed member makes this fail instead of returning streams.
      val code = FfmpegDemuxerJni.nativeOpen(input)

      assertEquals("nativeOpen failed (${input.lastError ?: "no java error"})", 0, code)
      assertTrue("demuxer reported no streams", FfmpegDemuxerJni.nativeStreamCount() > 0)
      assertTrue("position was never called", input.positionCalls > 0)

      // Header parsing is sequential, so it only proves read()/position()/length().
      // readAt() is the member nothing in the app calls except this interface's
      // own implementation, and it is what an index seek runs on.
      val durationUs = FfmpegDemuxerJni.nativeDurationUs()
      assertTrue("fixture duration unknown", durationUs > 0)
      val seek = FfmpegDemuxerJni.nativeSeek(durationUs / 2)

      assertTrue("nativeSeek failed with $seek (${input.lastError ?: "no java error"})", seek >= 0)
      assertTrue("readAt was never called for the index read", input.readAtCalls > 0)
    } finally {
      FfmpegDemuxerJni.nativeClose()
      input.close()
      fixture.delete()
    }
  }

  private fun copyFixture(): File {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val cacheDir = instrumentation.targetContext.cacheDir.also { it.mkdirs() }
    val output = File.createTempFile("ffmpeg-reachability-", ".mkv", cacheDir)
    instrumentation.context.assets.open(FIXTURE).use { source ->
      output.outputStream().use(source::copyTo)
    }
    return output
  }

  /** Byte source with no media3 involvement, so R8 has nothing else to keep. */
  private class FileInput(file: File) : FfmpegDemuxerJni.Input {
    private val handle = RandomAccessFile(file, "r")
    private val total = file.length()

    var readAtCalls = 0
      private set

    var positionCalls = 0
      private set

    override var lastError: String? = null

    override fun position(): Long {
      positionCalls++
      return handle.filePointer
    }

    override fun read(buf: ByteArray, length: Int): Int {
      val read = handle.read(buf, 0, length)
      return if (read < 0) 0 else read
    }

    override fun readAt(position: Long, buf: ByteArray, length: Int): Int {
      readAtCalls++
      val restore = handle.filePointer
      return try {
        if (position >= total) return 0
        handle.seek(position)
        val read = handle.read(buf, 0, length)
        if (read < 0) 0 else read
      } finally {
        handle.seek(restore)
      }
    }

    override fun length(): Long = total

    fun close() = handle.close()
  }

  private companion object {
    /** The cued fixture from [FfmpegExtractorSeekTest]: a SeekHead plus Cues at the end. */
    const val FIXTURE = "ffmpeg/seek_cued.mkv"
  }
}
