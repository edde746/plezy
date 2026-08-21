package com.edde746.plezy.exoplayer

import androidx.media3.common.text.Cue
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Test

class SubtitleCueLayoutTest {

  @Test
  fun concurrentUnpositionedCuesStackFromBottom() {
    val first = Cue.Builder().setText("first").build()
    val second = Cue.Builder().setText("second").build()

    val laidOut = SubtitleCueLayout.layout(listOf(first, second), positionPercent = 100, fontSize = 36f)

    assertEquals(Cue.LINE_TYPE_NUMBER, laidOut[0].lineType)
    assertEquals(-2f, laidOut[0].line)
    assertEquals(Cue.ANCHOR_TYPE_END, laidOut[0].lineAnchor)
    assertEquals(-1f, laidOut[1].line)
  }

  @Test
  fun userPositionPreservesStackSpacing() {
    val first = Cue.Builder().setText("first").build()
    val second = Cue.Builder().setText("second").build()

    val laidOut = SubtitleCueLayout.layout(listOf(first, second), positionPercent = 50, fontSize = 36f)

    assertEquals(Cue.LINE_TYPE_FRACTION, laidOut[0].lineType)
    assertEquals(0.44f, laidOut[0].line, 0.0001f)
    assertEquals(0.5f, laidOut[1].line, 0.0001f)
    assertEquals(Cue.ANCHOR_TYPE_END, laidOut[0].lineAnchor)
    assertEquals(Cue.ANCHOR_TYPE_END, laidOut[1].lineAnchor)
  }

  @Test
  fun explicitCuePositionIsNotOverridden() {
    val positioned = Cue.Builder()
      .setText("positioned")
      .setLine(0.25f, Cue.LINE_TYPE_FRACTION)
      .setLineAnchor(Cue.ANCHOR_TYPE_START)
      .build()

    val laidOut = SubtitleCueLayout.layout(listOf(positioned), positionPercent = 50, fontSize = 36f)

    assertSame(positioned, laidOut.single())
  }
}
