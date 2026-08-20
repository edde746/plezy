package com.edde746.plezy.libass.media.parser

import androidx.annotation.OptIn
import androidx.media3.common.Format
import androidx.media3.common.util.UnstableApi
import org.junit.Assert.assertArrayEquals
import org.junit.Test

@OptIn(UnstableApi::class)
class AssHeaderParserTest {

  @Test
  fun doubleNulTerminatedHeaderAppendsEventsAfterContent() {
    val input = SCRIPT_HEADER.toByteArray() + byteArrayOf(0, 0)

    assertArrayEquals(expectedHeader(), parse(input))
  }

  @Test
  fun unterminatedHeaderWithoutEventsIsRepaired() {
    assertArrayEquals(expectedHeader(), parse(SCRIPT_HEADER.toByteArray()))
  }

  @Test
  fun repairPreservesNonUtf8HeaderBytes() {
    val content = SCRIPT_HEADER.toByteArray() + byteArrayOf(0xE9.toByte())
    val input = content + byteArrayOf(0)
    val expected = content + ("\n" + EVENTS_SECTION).toByteArray()

    assertArrayEquals(expected, parse(input))
  }

  @Test
  fun existingEventsSectionIsPreserved() {
    val input = expectedHeader()

    assertArrayEquals(input, parse(input))
  }

  @Test
  fun trailingNulsAreRemovedWithoutDuplicatingExistingEvents() {
    val input = expectedHeader() + byteArrayOf(0, 0)

    assertArrayEquals(expectedHeader(), parse(input))
  }

  private fun parse(header: ByteArray): ByteArray = AssHeaderParser.parse(
    Format.Builder()
      .setInitializationData(listOf(byteArrayOf(), header))
      .build()
  )

  private fun expectedHeader(): ByteArray = "$SCRIPT_HEADER\n$EVENTS_SECTION".toByteArray()

  private companion object {
    const val SCRIPT_HEADER = "[Script Info]\r\nScriptType: v4.00+\r\n"
    const val EVENTS_SECTION = "[Events]\n" +
      "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"
  }
}
