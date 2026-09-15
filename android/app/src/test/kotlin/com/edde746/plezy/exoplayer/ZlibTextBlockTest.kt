package com.edde746.plezy.exoplayer

import java.io.ByteArrayOutputStream
import java.util.zip.Deflater
import java.util.zip.DeflaterOutputStream
import java.util.zip.Inflater
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Unit spec for [rewriteZlibTextBlock]: the block header (track-number varint,
 * timecode, flags) must survive byte-identically, the payload must inflate, and
 * every block the rewriter cannot prove safe must pass through unchanged (null).
 */
class ZlibTextBlockTest {

  private val inflater = Inflater()

  private fun block(header: ByteArray, payload: ByteArray): ByteArray = header + payload

  private fun deflate(bytes: ByteArray): ByteArray {
    val target = ByteArrayOutputStream()
    DeflaterOutputStream(target, Deflater()).use { it.write(bytes) }
    return target.toByteArray()
  }

  // Track 3 (varint 0x83), relative timecode 0x0102, no lacing.
  private val unlacedHeader = byteArrayOf(0x83.toByte(), 0x01, 0x02, 0x00)

  @Test
  fun inflatesUnlacedBlockPayloadAndPreservesHeader() {
    val dialogue = "42,,Default,,0,0,0,,SUBTITLE LINE 1 (0:00:00.00)".toByteArray()
    val data = block(unlacedHeader, deflate(dialogue))

    val rewritten = rewriteZlibTextBlock(data, data.size, inflater)!!

    assertArrayEquals(unlacedHeader + dialogue, rewritten)
  }

  @Test
  fun twoByteTrackNumberVarintIsPreserved() {
    val dialogue = "1,,Default,,0,0,0,,hello".toByteArray()
    val header = byteArrayOf(0x41, 0x2A, 0x01, 0x02, 0x00) // varint 0x412A = track 298
    val data = block(header, deflate(dialogue))

    val rewritten = rewriteZlibTextBlock(data, data.size, inflater)!!

    assertArrayEquals(header + dialogue, rewritten)
  }

  @Test
  fun lacedBlockPassesThrough() {
    val laced = byteArrayOf(0x83.toByte(), 0x01, 0x02, 0x06) // EBML lacing bits set
    val data = block(laced, deflate("payload".toByteArray()))

    assertNull(rewriteZlibTextBlock(data, data.size, inflater))
  }

  @Test
  fun corruptStreamPassesThrough() {
    val data = block(unlacedHeader, byteArrayOf(0x44, 0x69, 0x61, 0x6C)) // "Dial", not zlib

    assertNull(rewriteZlibTextBlock(data, data.size, inflater))
  }

  @Test
  fun truncatedStreamPassesThrough() {
    val compressed = deflate("a longer payload that spans several deflate symbols".toByteArray())
    val truncated = compressed.copyOf(compressed.size - 4)
    val data = block(unlacedHeader, truncated)

    assertNull(rewriteZlibTextBlock(data, data.size, inflater))
  }

  @Test
  fun headerOnlyBlockPassesThrough() {
    assertNull(rewriteZlibTextBlock(unlacedHeader, unlacedHeader.size, inflater))
  }
}
