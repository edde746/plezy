package com.edde746.plezy.exoplayer

import android.net.Uri
import androidx.media3.common.C
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.TransferListener
import java.io.IOException
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The demuxer's correctness now rests on this source answering any absolute
 * position, so these pin the contract libavformat depends on: a read lands on
 * the requested byte, a backward jump reopens rather than returning the wrong
 * bytes, and sequential reads do not reopen (which would turn steady-state
 * playback into one request per 64 KB).
 */
@RunWith(RobolectricTestRunner::class)
class FfmpegRandomAccessSourceTest {

  private val content = ByteArray(4096) { (it % 251).toByte() }
  private val uri: Uri = Uri.parse("https://example.test/movie.mkv")

  private class FakeDataSource(private val content: ByteArray) : DataSource {
    var openedAt: Long = -1
    var closed = false
    private var position = 0

    override fun open(dataSpec: DataSpec): Long {
      openedAt = dataSpec.position
      position = dataSpec.position.toInt()
      return (content.size - position).toLong()
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
      if (position >= content.size) return C.RESULT_END_OF_INPUT
      val count = minOf(length, content.size - position)
      content.copyInto(buffer, offset, position, position + count)
      position += count
      return count
    }

    override fun addTransferListener(transferListener: TransferListener) = Unit

    override fun getUri(): Uri? = null

    override fun getResponseHeaders(): Map<String, List<String>> = emptyMap()

    override fun close() {
      closed = true
    }
  }

  private inner class FakeFactory : DataSource.Factory {
    val created = mutableListOf<FakeDataSource>()

    override fun createDataSource(): DataSource = FakeDataSource(content).also { created.add(it) }
  }

  private fun sourceFor(factory: DataSource.Factory, spec: DataSpec? = DataSpec(uri)) = FfmpegRandomAccessSource(factory) { spec }

  @Test
  fun readsLandOnTheRequestedAbsolutePosition() {
    val factory = FakeFactory()
    val source = sourceFor(factory)
    val buffer = ByteArray(16)

    assertEquals(16, source.readAt(1000, buffer, 16))

    assertArrayEquals(content.copyOfRange(1000, 1016), buffer)
    assertEquals(1000L, factory.created.single().openedAt)
  }

  @Test
  fun sequentialReadsReuseOneHandle() {
    val factory = FakeFactory()
    val source = sourceFor(factory)
    val buffer = ByteArray(64)

    source.readAt(0, buffer, 64)
    source.readAt(64, buffer, 64)
    source.readAt(128, buffer, 64)

    assertEquals(1, source.openCount)
    assertArrayEquals(content.copyOfRange(128, 192), buffer)
  }

  @Test
  fun backwardJumpReopensAndReturnsTheRequestedBytes() {
    val factory = FakeFactory()
    val source = sourceFor(factory)
    val buffer = ByteArray(32)

    source.readAt(2048, buffer, 32)
    // The jump libavformat makes for an index at the end of the file, then back.
    assertEquals(32, source.readAt(16, buffer, 32))

    assertArrayEquals(content.copyOfRange(16, 48), buffer)
    assertEquals(2, source.openCount)
    assertTrue("abandoned handle must be closed", factory.created.first().closed)
  }

  @Test
  fun endOfInputReportsZeroWithoutAdvancing() {
    val factory = FakeFactory()
    val source = sourceFor(factory)
    val buffer = ByteArray(8)

    assertEquals(0, source.readAt(content.size.toLong(), buffer, 8))
  }

  @Test
  fun lengthResolvesFromAnOpenAndStaysKnown() {
    val factory = FakeFactory()
    val source = sourceFor(factory)

    assertEquals(C.LENGTH_UNSET.toLong(), source.length())
    source.readAt(512, ByteArray(8), 8)

    assertEquals(content.size.toLong(), source.length())
  }

  @Test
  fun clonedSpecKeepsCacheKeyAndFlagsButTakesOurPosition() {
    val recorded = DataSpec.Builder()
      .setUri(uri)
      .setPosition(9999)
      .setLength(1234)
      .setKey("download-cache-key")
      .setFlags(DataSpec.FLAG_ALLOW_CACHE_FRAGMENTATION)
      .setHttpRequestHeaders(mapOf("X-Test" to "1"))
      .build()
    var openedSpec: DataSpec? = null
    val factory = DataSource.Factory {
      object : DataSource {
        override fun open(dataSpec: DataSpec): Long {
          openedSpec = dataSpec
          return C.LENGTH_UNSET.toLong()
        }

        override fun read(buffer: ByteArray, offset: Int, length: Int): Int = C.RESULT_END_OF_INPUT

        override fun addTransferListener(transferListener: TransferListener) = Unit

        override fun getUri(): Uri? = null

        override fun getResponseHeaders(): Map<String, List<String>> = emptyMap()

        override fun close() = Unit
      }
    }

    sourceFor(factory, recorded).readAt(4242, ByteArray(4), 4)

    val spec = requireNotNull(openedSpec)
    assertEquals(4242L, spec.position)
    assertEquals(C.LENGTH_UNSET.toLong(), spec.length)
    assertEquals("download-cache-key", spec.key)
    assertEquals(DataSpec.FLAG_ALLOW_CACHE_FRAGMENTATION, spec.flags)
    assertEquals("1", spec.httpRequestHeaders["X-Test"])
    assertEquals(uri, spec.uri)
  }

  @Test
  fun readWithoutARecordedSpecFails() {
    val source = sourceFor(FakeFactory(), spec = null)

    assertThrows(IOException::class.java) { source.readAt(0, ByteArray(4), 4) }
  }

  @Test
  fun closeReleasesTheHandle() {
    val factory = FakeFactory()
    val source = sourceFor(factory)
    source.readAt(0, ByteArray(4), 4)

    assertTrue(source.isOpen)
    source.close()

    assertFalse(source.isOpen)
    assertTrue(factory.created.single().closed)
  }

  @Test
  fun recordingFactoryReportsTheSpecMedia3OpenedPerUri() {
    val delegate = FakeFactory()
    val recorder = RecordingDataSourceFactory(delegate)
    val other = Uri.parse("https://example.test/next-episode.mkv")

    assertNull(recorder.specFor(uri))
    recorder.createDataSource().open(DataSpec.Builder().setUri(uri).setPosition(64).setKey("a").build())
    recorder.createDataSource().open(DataSpec.Builder().setUri(other).setPosition(128).build())

    // Preloading the next item must not redirect the current demuxer's reads.
    assertEquals(64L, recorder.specFor(uri)?.position)
    assertEquals("a", recorder.specFor(uri)?.key)
    assertEquals(128L, recorder.specFor(other)?.position)
  }

  @Test
  fun recordingFactoryDelegatesReads() {
    val delegate = FakeFactory()
    val recorder = RecordingDataSourceFactory(delegate)
    val buffer = ByteArray(16)

    val dataSource = recorder.createDataSource()
    dataSource.open(DataSpec.Builder().setUri(uri).setPosition(32).build())
    assertEquals(16, dataSource.read(buffer, 0, 16))

    assertArrayEquals(content.copyOfRange(32, 48), buffer)
    assertSame(delegate.created.single(), delegate.created.first())
  }
}
