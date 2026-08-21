package com.edde746.plezy.exoplayer

import androidx.annotation.OptIn
import androidx.media3.common.text.Cue
import androidx.media3.common.util.UnstableApi

@OptIn(UnstableApi::class)
internal object SubtitleCueLayout {

  fun layout(cues: List<Cue>, positionPercent: Int, fontSize: Float): List<Cue> = applyPosition(stackUnpositioned(cues), positionPercent, fontSize)

  // SRT carries no per-cue positioning, so SubripParser emits cues with
  // lineType = TYPE_UNSET. SubtitlePainter then renders every such cue at the
  // same default bottom-anchored position, causing visible overlap when more
  // than one is active. Reassign line numbers from the bottom up so concurrent
  // unpositioned cues stack instead. Workaround for
  // https://github.com/androidx/media/issues/2237; can be removed once
  // https://github.com/androidx/media/pull/3151 lands and we upgrade Media3.
  private fun stackUnpositioned(cues: List<Cue>): List<Cue> {
    if (cues.size < 2) return cues
    val toStack = cues.indices.filter {
      cues[it].lineType == Cue.TYPE_UNSET && cues[it].text != null
    }
    if (toStack.size < 2) return cues
    val rebuilt = cues.toMutableList()
    var nextRow = -1
    // Reverse so the last cue in the group lands on row -1 (bottom).
    for (idx in toStack.reversed()) {
      val cue = cues[idx]
      rebuilt[idx] = cue.buildUpon()
        .setLine(nextRow.toFloat(), Cue.LINE_TYPE_NUMBER)
        .setLineAnchor(Cue.ANCHOR_TYPE_END)
        .build()
      val rowsConsumed = (cue.text?.toString()?.count { it == '\n' } ?: 0) + 1
      nextRow -= rowsConsumed
    }
    return rebuilt
  }

  private fun applyPosition(cues: List<Cue>, positionPercent: Int, fontSize: Float): List<Cue> {
    val clampedPosition = positionPercent.coerceIn(0, 100)
    if (clampedPosition == 100 || cues.isEmpty()) return cues

    val baseLine = clampedPosition / 100f
    val rowHeight = (fontSize / 720f * 1.2f).coerceAtLeast(0.01f)
    var changed = false

    val rebuilt = cues.map { cue ->
      if (!usesDefaultVerticalPlacement(cue)) return@map cue

      val rowOffset = if (cue.lineType == Cue.LINE_TYPE_NUMBER && cue.line < 0f) {
        (-cue.line - 1f).coerceAtLeast(0f)
      } else {
        0f
      }
      val line = if (clampedPosition == 0) {
        (rowOffset * rowHeight).coerceAtMost(1f)
      } else {
        (baseLine - rowOffset * rowHeight).coerceIn(0f, 1f)
      }
      val lineAnchor = if (clampedPosition == 0) Cue.ANCHOR_TYPE_START else Cue.ANCHOR_TYPE_END

      changed = true
      cue.buildUpon()
        .setLine(line, Cue.LINE_TYPE_FRACTION)
        .setLineAnchor(lineAnchor)
        .build()
    }

    return if (changed) rebuilt else cues
  }

  private fun usesDefaultVerticalPlacement(cue: Cue): Boolean {
    if (cue.text == null || cue.bitmap != null || cue.verticalType != Cue.TYPE_UNSET) return false
    return cue.line == Cue.DIMEN_UNSET || (cue.lineType == Cue.LINE_TYPE_NUMBER && cue.line < 0f)
  }
}
