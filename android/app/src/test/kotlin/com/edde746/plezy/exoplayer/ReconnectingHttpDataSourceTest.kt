package com.edde746.plezy.exoplayer

import android.net.Uri
import androidx.media3.common.C
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.HttpDataSource
import androidx.media3.datasource.TransferListener
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

private const val MIB = 1024 * 1024

@RunWith(RobolectricTestRunner::class)
class ReconnectingHttpDataSourceTest {

  @Test
  fun recyclesRangeStreamWhenThroughputCollapsesAfterExtendedPlayback() {
    var nowMs = 1_000L
    val upstream = FakeUpstreamHttpFactory(totalSize = 32 * MIB)
    val factory = ReconnectingHttpDataSource.Factory(
      upstreamFactory = upstream,
      clockMs = { nowMs }
    )
    val dataSource = factory.createDataSource()

    val initialSpec = DataSpec.Builder()
      .setUri(Uri.parse("https://plex.example/library/parts/100/file.mkv"))
      .setPosition(0L)
      .setHttpRequestHeaders(mapOf("Range" to "bytes=0-", "X-Plex-Token" to "secret"))
      .build()

    dataSource.open(initialSpec)
    assertEquals(1, upstream.openedSpecs.size)

    val chunk = ByteArray(1 * MIB)
    var totalRead = 0

    // 1. Initial burst phase: read 20 MiB over 4 seconds (5 MiB/s = 40 Mbps burst).
    repeat(20) {
      val n = dataSource.readWithClockAdvance(upstream, chunk, 0, chunk.size) { nowMs += 200L }
      assertEquals(1 * MIB, n)
      verifyChunkContents(chunk, totalRead, n)
      totalRead += n
    }
    assertEquals("no reconnect during healthy initial burst", 0, dataSource.reconnectCount)
    assertTrue((factory.currentThroughputBytesPerSec() ?: 0L) >= 4L * MIB)

    // 2. Simulate 12 minutes of playback elapsed on this connection followed by a loader pause.
    nowMs += 12 * 60 * 1_000L

    val wakeRead = dataSource.read(chunk, 0, 64 * 1024)
    verifyChunkContents(chunk, totalRead, wakeRead)
    totalRead += wakeRead

    assertEquals(
      "an aged stream resuming after an idle gap rotates immediately before reading",
      1,
      dataSource.reconnectCount
    )
    assertEquals(2, upstream.openedSpecs.size)
    assertEquals(20L * MIB, upstream.openedSpecs[1].position)
    assertFalse(
      "stale Range: bytes=0- header must be stripped so DataSpec.position drives the Range header",
      upstream.openedSpecs[1].httpRequestHeaders.keys.any { it.equals("Range", ignoreCase = true) }
    )
    assertEquals("secret", upstream.openedSpecs[1].httpRequestHeaders["X-Plex-Token"])
  }

  @Test
  fun recyclesStreamDuringContinuousReadsWhenActiveThroughputCollapsesBelowQuarterOfPeak() {
    var nowMs = 1_000L
    val totalStreamBytes = 128 * MIB
    val upstream = FakeUpstreamHttpFactory(totalSize = totalStreamBytes)
    val factory = ReconnectingHttpDataSource.Factory(
      upstreamFactory = upstream,
      clockMs = { nowMs }
    )
    val dataSource = factory.createDataSource()

    dataSource.open(
      DataSpec.Builder()
        .setUri(Uri.parse("https://jellyfin.example/Videos/1/stream.mkv"))
        .setPosition(0L)
        .setLength(totalStreamBytes.toLong())
        .build()
    )

    val buf = ByteArray(512 * 1024) // 512 KiB
    var totalRead = 0

    // 1. Burst 16 MiB over 4 seconds (32 reads of 512 KiB, 125ms each -> 4 MiB/s peak).
    repeat(32) {
      val n = dataSource.readWithClockAdvance(upstream, buf, 0, buf.size) { nowMs += 125L }
      verifyChunkContents(buf, totalRead, n)
      totalRead += n
    }
    assertEquals(0, dataSource.reconnectCount)

    // 2. Keep reading continuously for 32 seconds at healthy speed (512 KiB per 250ms = 2 MiB/s, 50% of peak).
    repeat(128) {
      val n = dataSource.readWithClockAdvance(upstream, buf, 0, buf.size) { nowMs += 250L }
      verifyChunkContents(buf, totalRead, n)
      totalRead += n
    }
    assertEquals("healthy continuous stream must not reconnect", 0, dataSource.reconnectCount)

    // 3. Throughput suddenly collapses to 256 KiB/s (< 25% of 4 MiB/s peak) across two 4s windows.
    // Window 1: 4 reads of 256 KiB, each taking 1_000ms inside read() (4_000ms total -> 256 KiB/s).
    repeat(4) {
      val n = dataSource.readWithClockAdvance(upstream, buf, 0, 256 * 1024) { nowMs += 1_000L }
      verifyChunkContents(buf, totalRead, n)
      totalRead += n
    }
    assertEquals("1 degraded window is not yet enough to reconnect", 0, dataSource.reconnectCount)

    // Window 2: another 4s of degraded throughput (256 KiB/s) arms throughput-collapse reconnect.
    repeat(4) {
      val n = dataSource.readWithClockAdvance(upstream, buf, 0, 256 * 1024) { nowMs += 1_000L }
      verifyChunkContents(buf, totalRead, n)
      totalRead += n
    }

    // Next read triggers in-place Range reconnection at exact byte offset `totalRead`!
    val reconnectOffset = totalRead.toLong()
    val n = dataSource.read(buf, 0, 256 * 1024)
    verifyChunkContents(buf, totalRead, n)
    totalRead += n

    assertEquals(1, dataSource.reconnectCount)
    assertEquals(1, factory.totalReconnectCount())
    assertEquals(2, upstream.openedSpecs.size)
    assertEquals(reconnectOffset, upstream.openedSpecs[1].position)
    assertEquals(totalStreamBytes.toLong() - reconnectOffset, upstream.openedSpecs[1].length)
    assertTrue("previous delegate must be closed on reconnect", upstream.instances[0].closed)
  }

  @Test
  fun midPlaybackRebufferSignalRecyclesAgedStreamImmediatelyOnNextRead() {
    var nowMs = 5_000L
    val upstream = FakeUpstreamHttpFactory(totalSize = 16 * MIB)
    val factory = ReconnectingHttpDataSource.Factory(
      upstreamFactory = upstream,
      clockMs = { nowMs }
    )
    val dataSource = factory.createDataSource()

    dataSource.open(DataSpec(Uri.parse("https://plex.example/video.mp4")))
    val buf = ByteArray(64 * 1024)
    var totalRead = 0

    // Read 256 KiB initially.
    repeat(4) {
      val n = dataSource.read(buf, 0, buf.size)
      verifyChunkContents(buf, totalRead, n)
      totalRead += n
    }

    // Stream has been open for 15 seconds (> 10s minimum age for rebuffer reconnect).
    nowMs += 15_000L
    factory.notifyRebuffering()

    val expectedResumeOffset = totalRead.toLong()
    val n = dataSource.read(buf, 0, buf.size)
    verifyChunkContents(buf, totalRead, n)
    totalRead += n

    assertEquals(1, dataSource.reconnectCount)
    assertEquals(expectedResumeOffset, upstream.openedSpecs[1].position)
  }

  @Test
  fun doesNotReconnectWhenServerDoesNotAdvertiseByteRangeSupport() {
    var nowMs = 1_000L
    val upstream = FakeUpstreamHttpFactory(
      totalSize = 8 * MIB,
      responseCode = 200,
      responseHeaders = emptyMap()
    )
    val factory = ReconnectingHttpDataSource.Factory(
      upstreamFactory = upstream,
      clockMs = { nowMs }
    )
    val dataSource = factory.createDataSource()

    dataSource.open(DataSpec(Uri.parse("https://live.example/unseekable.ts")))
    val buf = ByteArray(64 * 1024)
    dataSource.read(buf, 0, buf.size)

    nowMs += 180_000L
    factory.notifyRebuffering()
    dataSource.read(buf, 0, buf.size)

    assertEquals("must never Range-reconnect an unseekable HTTP 200 stream", 0, dataSource.reconnectCount)
    assertEquals(1, upstream.openedSpecs.size)
  }

  private fun verifyChunkContents(buf: ByteArray, startOffset: Int, length: Int) {
    val expected = ByteArray(length) { i -> ((startOffset + i) and 0xFF).toByte() }
    assertArrayEquals(expected, buf.copyOfRange(0, length))
  }
}

@androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
private class FakeUpstreamHttpFactory(
  private val totalSize: Int,
  private val responseCode: Int = 206,
  private val responseHeaders: Map<String, List<String>> = mapOf(
    "Content-Range" to listOf("bytes 0-${totalSize - 1}/$totalSize"),
    "Accept-Ranges" to listOf("bytes")
  )
) : HttpDataSource.Factory {
  val openedSpecs = mutableListOf<DataSpec>()
  val instances = mutableListOf<FakeHttpDataSource>()
  var nextReadHook: (() -> Unit)? = null

  override fun createDataSource(): HttpDataSource {
    return FakeHttpDataSource(totalSize, responseCode, responseHeaders, this).also {
      instances.add(it)
    }
  }

  override fun setDefaultRequestProperties(defaultRequestProperties: Map<String, String>): HttpDataSource.Factory = this
}

@androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
private class FakeHttpDataSource(
  private val totalSize: Int,
  private val status: Int,
  private val headers: Map<String, List<String>>,
  private val parent: FakeUpstreamHttpFactory
) : HttpDataSource {
  private var currentUri: Uri? = null
  private var readPosition: Int = 0
  private var endPosition: Int = totalSize
  var closed: Boolean = false

  override fun addTransferListener(transferListener: TransferListener) = Unit
  override fun setRequestProperty(name: String, value: String) = Unit
  override fun clearRequestProperty(name: String) = Unit
  override fun clearAllRequestProperties() = Unit
  override fun getUri(): Uri? = currentUri
  override fun getResponseCode(): Int = status
  override fun getResponseHeaders(): Map<String, List<String>> = headers

  override fun open(dataSpec: DataSpec): Long {
    parent.openedSpecs.add(dataSpec)
    currentUri = dataSpec.uri
    readPosition = dataSpec.position.toInt()
    endPosition = if (dataSpec.length == C.LENGTH_UNSET.toLong()) {
      totalSize
    } else {
      minOf(totalSize, readPosition + dataSpec.length.toInt())
    }
    return (endPosition - readPosition).toLong()
  }

  override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
    parent.nextReadHook?.invoke()
    parent.nextReadHook = null
    if (readPosition >= endPosition) return C.RESULT_END_OF_INPUT
    val toRead = minOf(length, endPosition - readPosition)
    for (i in 0 until toRead) {
      buffer[offset + i] = ((readPosition + i) and 0xFF).toByte()
    }
    readPosition += toRead
    return toRead
  }

  override fun close() {
    closed = true
  }
}

private fun ReconnectingHttpDataSource.readWithClockAdvance(
  upstream: FakeUpstreamHttpFactory,
  buffer: ByteArray,
  offset: Int,
  length: Int,
  duringRead: () -> Unit
): Int {
  upstream.nextReadHook = duringRead
  return read(buffer, offset, length)
}
