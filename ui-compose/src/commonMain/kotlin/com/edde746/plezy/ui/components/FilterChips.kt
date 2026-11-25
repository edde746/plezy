package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.probe.layoutProbe

/** The gap between the chips of a filter row. */
val FILTER_GAP = 8.dp

/**
 * A dropdown chip's words: its menu's [name] (a TV panel's title), the chip's [text], what a screen reader hears
 * ([spoken]), and whether the chip narrows what is shown ([narrowed]: drawn in the primary fill).
 */
@Immutable
data class FilterChip(val name: String, val text: String, val spoken: String = text, val narrowed: Boolean = false)

/**
 * A dropdown chip: a [PlezyChip] showing [chip]'s text (in the primary fill while it narrows what is shown) with the
 * dropdown arrow, named for screen readers by [chip]'s spoken text, opening its [choices] in a [ChoiceMenu] (a menu; on
 * TV a side panel titled with [chip]'s name, the selected option focused). [leadingIcon] with [iconOnly] is a round
 * chip of the icon alone, without the arrow (where the row has no room for its text), its tooltip [chip]'s spoken text
 * (what it shows now). [modifier] goes to the chip.
 * Harness names: [probe], `[probe].option.<i>`.
 */
@Composable
fun MenuChip(
    chip: FilterChip,
    choices: List<MenuChoice>,
    onPick: (Int) -> Unit,
    probe: String,
    modifier: Modifier = Modifier,
    leadingIcon: ImageVector? = null,
    iconOnly: Boolean = false,
    closeOnPick: Boolean = true,
    contentLabel: Boolean = false,
) {
    var open by remember { mutableStateOf(false) }
    Box {
        PlezyChip(
            if (iconOnly) "" else chip.text,
            selected = chip.narrowed,
            onClick = { open = true },
            leadingIcon = leadingIcon,
            dropdown = true,
            modifier = modifier.semantics { contentDescription = chip.spoken }.layoutProbe(probe),
            contentLabel = contentLabel,
            tooltip = chip.spoken.takeIf { iconOnly },
        )
        ChoiceMenu(
            expanded = open,
            onDismiss = { open = false },
            title = chip.name,
            choices = choices,
            onPick = onPick,
            probe = probe,
            closeOnPick = closeOnPick,
        )
    }
}

/**
 * Its children side by side, [FILTER_GAP] apart, each as wide as it asks while they all fit. Past that the first (the
 * screen's name) cuts its label short while the others keep their width, down to [NAME_MIN]; where the others don't fit
 * beside that, the first keeps it and the narrowest of the others keep theirs while the widest share what is left
 * evenly, so the row never runs past its own width. [onWidth] hears, on each measure, the width (px) the row has for its
 * children, for a screen that picks its children's forms by the room they leave the name.
 */
@Composable
fun FittingRow(modifier: Modifier, onWidth: ((Int) -> Unit)? = null, content: @Composable () -> Unit) {
    Layout(content, modifier) { measurables, constraints ->
        onWidth?.invoke(constraints.maxWidth)
        val gap = FILTER_GAP.roundToPx()
        var left = (constraints.maxWidth - gap * (measurables.size - 1)).coerceAtLeast(0)
        val wanted = measurables.map { it.maxIntrinsicWidth(constraints.maxHeight) }
        val widths = IntArray(measurables.size)
        if (wanted.isNotEmpty()) {
            val others = wanted.drop(1).sum()
            val name = minOf(wanted[0], NAME_MIN.roundToPx(), left)
            if (others + name <= left) {
                wanted.indices.forEach { widths[it] = wanted[it] }
                widths[0] = minOf(wanted[0], left - others)
            } else {
                widths[0] = name
                left -= name
                val rest = wanted.indices.drop(1).sortedBy { wanted[it] }
                rest.forEachIndexed { done, index ->
                    widths[index] = minOf(wanted[index], left / (rest.size - done))
                    left -= widths[index]
                }
            }
        }
        val placeables = measurables.mapIndexed { index, child -> child.measure(constraints.copy(minWidth = 0, maxWidth = widths[index], minHeight = 0)) }
        val height = placeables.maxOfOrNull { it.height } ?: 0
        layout(constraints.maxWidth, height) {
            var x = 0
            placeables.forEach {
                it.placeRelative(x, (height - it.height) / 2)
                x += it.width + gap
            }
        }
    }
}

/**
 * How narrow a [FittingRow] lets its first child (the screen's name) go before the others give way: a dropdown chip's
 * edge and arrow, which it keeps, beside the first few characters of its name (60 dp of text).
 */
internal val NAME_MIN = 108.dp
