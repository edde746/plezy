package com.edde746.plezy.exoplayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class StreamBitrateMeterTest {

  /** Feeds [count] packets of [sizeBytes] every [intervalUs], starting at [startUs]. */
  private fun StreamBitrateMeter.feed(count: Int, sizeBytes: Int, intervalUs: Long, startUs: Long = 0L) {
    for (i in 0 until count) onPacket(startUs + i * intervalUs, sizeBytes)
  }

  @Test
  fun `constant packet stream measures its bitrate`() {
    val meter = StreamBitrateMeter()
    // 1200-byte packets every 32 ms: 1200 * 8 / 0.032 = 300 kbps.
    meter.feed(count = 32, sizeBytes = 1200, intervalUs = 32_000)
    assertEquals(300_000, meter.bitrateBps())
  }

  @Test
  fun `too few packets report nothing`() {
    val meter = StreamBitrateMeter()
    meter.feed(count = 15, sizeBytes = 1200, intervalUs = 32_000)
    assertNull(meter.bitrateBps())
  }

  @Test
  fun `zero pts span reports nothing`() {
    val meter = StreamBitrateMeter()
    repeat(32) { meter.onPacket(0L, 1200) }
    assertNull(meter.bitrateBps())
  }

  @Test
  fun `window drops old packets so a bitrate change is followed`() {
    val meter = StreamBitrateMeter(windowUs = 1_000_000)
    meter.feed(count = 100, sizeBytes = 1200, intervalUs = 32_000)
    // Continue at four times the packet size; after well over a window of
    // new packets, only the new rate remains.
    meter.feed(count = 100, sizeBytes = 4800, intervalUs = 32_000, startUs = 100 * 32_000L)
    assertEquals(1_200_000, meter.bitrateBps())
  }

  @Test
  fun `backwards pts jump resets the window`() {
    val meter = StreamBitrateMeter()
    meter.feed(count = 32, sizeBytes = 1200, intervalUs = 32_000)
    // Seek back: the single post-seek packet must not combine with the
    // pre-seek span.
    meter.onPacket(0L, 1200)
    assertNull(meter.bitrateBps())
    meter.feed(count = 31, sizeBytes = 1200, intervalUs = 32_000, startUs = 32_000)
    assertEquals(300_000, meter.bitrateBps())
  }

  @Test
  fun `empty packets are ignored`() {
    val meter = StreamBitrateMeter()
    meter.feed(count = 32, sizeBytes = 1200, intervalUs = 32_000)
    meter.onPacket(32 * 32_000L, 0)
    assertEquals(300_000, meter.bitrateBps())
  }
}
