package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.detail.TrackStatusUi
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe

/**
 * What Play's tracks will be, on one line in [style]: the picture labels ("4K", "HEVC", "DV"), the speaker and the audio
 * track ("English · EAC3 5.1"), the subtitles mark and the subtitle or "Off", joined with bullets. When the line is
 * wider than it may be, the details go first (the subtitle's, then the audio's), then the picture labels from the
 * last, then the audio track; the subtitle stays, cut short with an ellipsis where it still doesn't fit. Icons are 1.15 × the font size. Read-only, off the focus path; one
 * element for screen readers ([TrackStatusUi.semanticLabel]). Harness name `detail.tracks`. Without [tracks] (still
 * probed) the line's room, empty.
 */
@Composable
internal fun TrackStatus(tracks: TrackStatusUi?, style: TextStyle, modifier: Modifier = Modifier) {
    val measurer = rememberTextMeasurer()
    val density = LocalDensity.current
    val iconSize = with(density) { (style.fontSize * ICON_SCALE).toDp() }
    if (tracks == null) {
        Row(modifier, verticalAlignment = Alignment.CenterVertically) {
            Spacer(Modifier.size(iconSize))
            Text("", style = style, maxLines = 1)
        }
        return
    }
    val color = if (style.color.isSpecified) style.color else MaterialTheme.colorScheme.onSurface
    val parts = remember(tracks) { trackParts(tracks) }
    BoxWithConstraints(
        modifier
            .layoutProbe("detail.tracks", reportsFocus = false)
            .clearAndSetSemantics { contentDescription = tracks.semanticLabel },
    ) {
        val kept = remember(parts, constraints.maxWidth, style, density) { fitParts(parts, constraints, style, measurer, density) }
        Row(verticalAlignment = Alignment.CenterVertically) {
            var first = true
            parts.forEachIndexed { index, part ->
                if (kept[index] == 0) return@forEachIndexed
                if (!first) Text(SEPARATOR, style = style, color = color, maxLines = 1, softWrap = false)
                first = false
                part.icon?.let {
                    Icon(it, contentDescription = null, Modifier.size(iconSize), tint = color)
                    Spacer(Modifier.width(ICON_GAP))
                }
                val text = if (kept[index] == 2) part.text + DETAIL_SEPARATOR + part.detail else part.text
                // A part measured narrower than the platform's fonts draw it is cut short rather than drawn past the edge.
                Text(text, Modifier.weight(1f, fill = false), style = style, color = color, maxLines = 1, softWrap = false, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

/** A part of the line: [text] after its [icon], with its [detail] after it while there is room; [drop] orders the shedding (higher goes first). */
private class TrackPart(val icon: ImageVector?, val text: String, val detail: String?, val drop: Int, val detailDrop: Int)

private fun trackParts(tracks: TrackStatusUi): List<TrackPart> = buildList {
    for (label in tracks.video) add(TrackPart(null, label, null, drop = 2, detailDrop = 2))
    tracks.audio?.let { add(TrackPart(PlezyIcons.VolumeUp, it, tracks.audioDetail, drop = 1, detailDrop = 3)) }
    add(TrackPart(PlezyIcons.Subtitles, tracks.subtitle, tracks.subtitleDetail, drop = 0, detailDrop = 3))
}

/** How many units of each part fit [constraints]' width: 0 (shed), 1 (the text) or 2 (the text and its detail). */
private fun fitParts(parts: List<TrackPart>, constraints: Constraints, style: TextStyle, measurer: TextMeasurer, density: Density): IntArray {
    fun width(text: String) = measurer.measure(text, style, maxLines = 1, softWrap = false).size.width
    val icon = with(density) { (style.fontSize * ICON_SCALE).roundToPx() + ICON_GAP.roundToPx() }
    val units = parts.map { part ->
        listOfNotNull((if (part.icon != null) icon else 0) + width(part.text), part.detail?.let { width(DETAIL_SEPARATOR + it) })
    }
    val kept = IntArray(parts.size) { units[it].size }
    if (!constraints.hasBoundedWidth) return kept
    val separator = width(SEPARATOR)
    fun total(): Int {
        var sum = 0
        var shown = 0
        for (index in parts.indices) {
            if (kept[index] == 0) continue
            for (unit in 0 until kept[index]) sum += units[index][unit]
            shown++
        }
        return sum + separator * (shown - 1).coerceAtLeast(0)
    }
    fun nextDrop(index: Int) = if (kept[index] == 2) parts[index].detailDrop else parts[index].drop
    while (total() > constraints.maxWidth) {
        var drop = -1
        for (index in parts.indices) {
            if (kept[index] == 0) continue
            if (drop == -1 || nextDrop(index) >= nextDrop(drop)) drop = index
        }
        if (drop == -1) break
        kept[drop]--
    }
    return kept
}

private const val SEPARATOR = "  •  "
private const val DETAIL_SEPARATOR = " · "
private const val ICON_SCALE = 1.15f
private val ICON_GAP = 4.dp
