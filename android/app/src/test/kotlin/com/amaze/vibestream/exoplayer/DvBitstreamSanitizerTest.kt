package com.amaze.vibestream.exoplayer

import java.nio.ByteBuffer
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DvBitstreamSanitizerTest {

  private val sanitizer = DvBitstreamSanitizer()

  // --- HDR10+ SEI stripping (native DV codec path) ---

  @Test
  fun stripsHdr10PlusPrefixSeiBetweenVclNals() {
    val vcl1 = annexBNal(1, byteArrayOf(0x01, 0x02))
    val vcl2 = annexBNal(1, byteArrayOf(0x03, 0x04))
    val buffer = bufferOf(vcl1, hdr10PlusSei(), vcl2)
    val originalLimit = buffer.limit()

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(buffer))
    assertTrue(buffer.limit() < originalLimit)
    assertEquals(0, buffer.position())
  }

  @Test
  fun stripsSuffixSei() {
    val vcl = annexBNal(1, byteArrayOf(0x01))
    val suffixSei = annexBNal(40, hdr10PlusSeiPayload())
    val buffer = bufferOf(vcl, suffixSei)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertArrayEquals(vcl, remainingBytes(buffer))
  }

  @Test
  fun handles3ByteStartCodes() {
    val vcl1 = annexBNal(1, byteArrayOf(0x01, 0x02), startCodeLen = 3)
    val sei = annexBNal(39, hdr10PlusSeiPayload(), startCodeLen = 3)
    val vcl2 = annexBNal(1, byteArrayOf(0x03), startCodeLen = 3)
    val buffer = bufferOf(vcl1, sei, vcl2)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(buffer))
  }

  @Test
  fun preservesNonHdr10PlusT35Sei() {
    // Same T.35 layout but wrong country code (0x00 instead of 0xB5).
    val sei = annexBNal(
      39,
      byteArrayOf(0x04, 0x07, 0x00, 0x00, 0x3C, 0x00, 0x01, 0x04, 0x00)
    )
    val buffer = bufferOf(annexBNal(1, byteArrayOf(0x01)), sei, annexBNal(1, byteArrayOf(0x02)))
    val original = remainingBytes(buffer)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertArrayEquals(original, remainingBytes(buffer))
  }

  @Test
  fun noOpWithoutSeiNals() {
    val buffer = bufferOf(annexBNal(1, byteArrayOf(0x01, 0x02)), annexBNal(1, byteArrayOf(0x03)))
    val original = remainingBytes(buffer)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = true)

    assertArrayEquals(original, remainingBytes(buffer))
  }

  @Test
  fun keepsTruncatedSei() {
    // Declares payload size 7 but the identifier bytes are cut short.
    val truncated = annexBNal(39, byteArrayOf(0x04, 0x07, 0xB5.toByte(), 0x00, 0x3C))
    val buffer = bufferOf(annexBNal(1, byteArrayOf(0x01)), truncated)
    val original = remainingBytes(buffer)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertArrayEquals(original, remainingBytes(buffer))
  }

  @Test
  fun keepsHdr10PlusSeiWhenFlagOff() {
    val buffer = bufferOf(annexBNal(1, byteArrayOf(0x01)), hdr10PlusSei())
    val original = remainingBytes(buffer)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = false, stripDvRpu = false)

    assertArrayEquals(original, remainingBytes(buffer))
  }

  // --- DV RPU/EL stripping (HEVC fallback path) ---

  @Test
  fun rpuModeStripsRpuAndElButKeepsHdr10PlusSei() {
    val vcl = annexBNal(1, byteArrayOf(0x01))
    val rpu = annexBNal(62, byteArrayOf(0x19, 0x08))
    val el = annexBNal(63, byteArrayOf(0x42))
    val sei = hdr10PlusSei()
    val buffer = bufferOf(vcl, rpu, sei, el)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = false, stripDvRpu = true)

    assertArrayEquals(concat(vcl, sei), remainingBytes(buffer))
  }

  @Test
  fun bothFlagsStripBothMetadataKinds() {
    val vcl1 = annexBNal(19, byteArrayOf(0x00)) // IDR_W_RADL
    val vcl2 = annexBNal(1, byteArrayOf(0x05))
    val buffer = bufferOf(vcl1, annexBNal(62, byteArrayOf(0x19)), hdr10PlusSei(), vcl2)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = true)

    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(buffer))
  }

  // --- Buffer handling ---

  @Test
  fun respectsPositionAndRestoresIt() {
    val prefix = byteArrayOf(0xAA.toByte(), 0xBB.toByte())
    val vcl = annexBNal(1, byteArrayOf(0x01))
    val content = concat(prefix, vcl, hdr10PlusSei())
    val buffer = ByteBuffer.wrap(content.copyOf())
    buffer.position(prefix.size)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertEquals(prefix.size, buffer.position())
    assertArrayEquals(vcl, remainingBytes(buffer))
    // Bytes before the position are untouched.
    assertEquals(0xAA.toByte(), buffer.get(0))
    assertEquals(0xBB.toByte(), buffer.get(1))
  }

  @Test
  fun worksOnDirectBuffers() {
    val vcl = annexBNal(1, byteArrayOf(0x01, 0x02))
    val buffer = directBufferOf(vcl, hdr10PlusSei())

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertArrayEquals(vcl, remainingBytes(buffer))
  }

  @Test
  fun emptyBufferIsNoOp() {
    val buffer = ByteBuffer.allocate(0)

    sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = true)

    assertEquals(0, buffer.position())
    assertEquals(0, buffer.limit())
  }

  @Test
  fun stripsOnDirectBufferWithNonZeroPosition() {
    val vcl1 = annexBNal(1, byteArrayOf(0x01, 0x02))
    val vcl2 = annexBNal(1, byteArrayOf(0x03))
    val buffer = directBufferOf(byteArrayOf(0xAA.toByte(), 0xBB.toByte()), vcl1, hdr10PlusSei(), vcl2)
    buffer.position(2)

    val stripped = sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertEquals(1, stripped)
    assertEquals(2, buffer.position())
    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(buffer))
    // Bytes before the position are untouched.
    assertEquals(0xAA.toByte(), buffer.get(0))
    assertEquals(0xBB.toByte(), buffer.get(1))
  }

  @Test
  fun noStripLeavesDirectBufferStateUntouched() {
    val vcl1 = annexBNal(1, byteArrayOf(0x01, 0x02))
    val vcl2 = annexBNal(1, byteArrayOf(0x03))
    val buffer = directBufferOf(vcl1, vcl2)
    val originalLimit = buffer.limit()

    val stripped = sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = true)

    assertEquals(0, stripped)
    assertEquals(0, buffer.position())
    assertEquals(originalLimit, buffer.limit())
    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(buffer))
  }

  @Test
  fun stripsTrailingRpuWithZeroByteTailWriteBack() {
    val vcl1 = annexBNal(1, byteArrayOf(0x01, 0x02))
    val vcl2 = annexBNal(1, byteArrayOf(0x03))
    val rpu = annexBNal(62, byteArrayOf(0x19, 0x08))
    val buffer = directBufferOf(vcl1, vcl2, rpu)
    val originalLimit = buffer.limit()

    val stripped = sanitizer.sanitize(buffer, stripHdr10PlusSei = false, stripDvRpu = true)

    assertEquals(1, stripped)
    assertEquals(originalLimit - rpu.size, buffer.limit())
    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(buffer))
  }

  @Test
  fun growsScratchForLargeSamples() {
    // Exceeds the initial 256KB scratch and one doubling; non-zero filler so no
    // accidental start codes appear in the payloads.
    val vcl1 = annexBNal(1, ByteArray(800_000) { 0xAB.toByte() })
    val vcl2 = annexBNal(1, ByteArray(700_000) { 0xCD.toByte() })
    val buffer = bufferOf(vcl1, hdr10PlusSei(), vcl2)

    val stripped = sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertEquals(1, stripped)
    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(buffer))
  }

  @Test
  fun reusesSanitizerAcrossSequentialBuffers() {
    val vcl1 = annexBNal(1, byteArrayOf(0x01, 0x02))
    val vcl2 = annexBNal(1, byteArrayOf(0x03, 0x04))

    val first = bufferOf(vcl1, hdr10PlusSei(), vcl2)
    assertEquals(1, sanitizer.sanitize(first, stripHdr10PlusSei = true, stripDvRpu = false))
    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(first))

    val second = bufferOf(vcl1, vcl2)
    assertEquals(0, sanitizer.sanitize(second, stripHdr10PlusSei = true, stripDvRpu = false))
    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(second))

    val third = bufferOf(hdr10PlusSei(), vcl1, annexBNal(62, byteArrayOf(0x19)), vcl2, hdr10PlusSei())
    assertEquals(3, sanitizer.sanitize(third, stripHdr10PlusSei = true, stripDvRpu = true))
    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(third))
  }

  @Test
  fun keepsBufferWithoutStartCodes() {
    val content = byteArrayOf(0x12, 0x34, 0x56, 0x78)
    val buffer = ByteBuffer.wrap(content.copyOf())

    val stripped = sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = true)

    assertEquals(0, stripped)
    assertEquals(0, buffer.position())
    assertEquals(content.size, buffer.limit())
    assertArrayEquals(content, remainingBytes(buffer))
  }

  @Test
  fun stripsMultipleSeisInOneAccessUnit() {
    val vcl1 = annexBNal(1, byteArrayOf(0x01, 0x02))
    val vcl2 = annexBNal(1, byteArrayOf(0x03))
    val suffixSei = annexBNal(40, hdr10PlusSeiPayload())
    val buffer = bufferOf(vcl1, hdr10PlusSei(), vcl2, suffixSei)

    val stripped = sanitizer.sanitize(buffer, stripHdr10PlusSei = true, stripDvRpu = false)

    assertEquals(2, stripped)
    assertArrayEquals(concat(vcl1, vcl2), remainingBytes(buffer))
  }

  // --- Helpers ---

  /** Builds an HEVC NAL unit: start code + 2-byte NAL header encoding [nalUnitType] + payload. */
  private fun annexBNal(nalUnitType: Int, payload: ByteArray, startCodeLen: Int = 4): ByteArray {
    val startCode = if (startCodeLen == 3) byteArrayOf(0, 0, 1) else byteArrayOf(0, 0, 0, 1)
    val header = byteArrayOf(((nalUnitType shl 1) and 0x7E).toByte(), 0x01)
    return concat(startCode, header, payload)
  }

  /**
   * SEI payload: type 4 (user_data_registered_itu_t_t35), size 7, then the HDR10+
   * identifiers — country 0xB5, provider 0x003C, oriented code 0x0001, app id 4, version 0 —
   * closed by the rbsp_trailing_bits stop byte real SEI NALs always end with (a trailing 0x00
   * would otherwise be ambiguous against a following 3-byte start code).
   */
  private fun hdr10PlusSeiPayload(): ByteArray = byteArrayOf(0x04, 0x07, 0xB5.toByte(), 0x00, 0x3C, 0x00, 0x01, 0x04, 0x00, 0x80.toByte())

  private fun hdr10PlusSei(): ByteArray = annexBNal(39, hdr10PlusSeiPayload())

  private fun concat(vararg parts: ByteArray): ByteArray {
    val result = ByteArray(parts.sumOf { it.size })
    var offset = 0
    for (part in parts) {
      part.copyInto(result, offset)
      offset += part.size
    }
    return result
  }

  private fun bufferOf(vararg parts: ByteArray): ByteBuffer = ByteBuffer.wrap(concat(*parts))

  private fun directBufferOf(vararg parts: ByteArray): ByteBuffer {
    val content = concat(*parts)
    val buffer = ByteBuffer.allocateDirect(content.size)
    buffer.put(content)
    buffer.flip()
    return buffer
  }

  private fun remainingBytes(buffer: ByteBuffer): ByteArray {
    val copy = ByteArray(buffer.remaining())
    buffer.duplicate().get(copy)
    return copy
  }
}
