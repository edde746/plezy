package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.vector.ImageVector
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.icons.PlezyIcons
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.SubcomposeLayout
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.constrainHeight
import androidx.compose.ui.unit.constrainWidth
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens

/**
 * A page header's row of actions (a media detail's, a collection's, an album's, a playlist's, a catalog title's): pills
 * ([PlezyButton], a detail's Play) and round icon buttons ([PlezyIconButton] and the round buttons built like it: cast,
 * download, ⋮), every one of them exactly the row's height and on its vertical centre, [ActionGap] apart, on one line.
 * The row's height is [actionRowHeight]: the platform's control height, or at large text the height a pill's label
 * needs. Its content sees that height as [LocalPlezyDimens]' `controlHeight` and `iconButtonSize`, so the round
 * buttons grow with the text and stay round.
 *
 * [content] (Play and what always shows beside it) comes first, at its full width; [shed] follows it with the `slots`
 * round buttons the rest of the width holds, so the secondary actions give way first, one by one, and Play keeps its
 * label until nothing else is left to give way (then it is cut short). [centred]: the line centred in the row's width.
 * Harness name [probe].
 */
@Composable
fun ActionRow(
    probe: String,
    modifier: Modifier = Modifier,
    centred: Boolean = false,
    shed: (@Composable (slots: Int) -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    val height = actionRowHeight()
    val dimens = LocalPlezyDimens.current
    val rowDimens = remember(dimens, height) { dimens.copy(controlHeight = height, iconButtonSize = height) }
    CompositionLocalProvider(LocalPlezyDimens provides rowDimens) {
        SubcomposeLayout(modifier.layoutProbe(probe, reportsFocus = false)) { constraints ->
            val side = height.roundToPx()
            val gap = ActionGap.roundToPx()
            val room = if (constraints.hasBoundedWidth) constraints.maxWidth else Constraints.Infinity
            val lead = subcompose(Slot.CONTENT, content)
            val rest = shed?.let { fit ->
                val leadWidth = lead.sumOf { it.maxIntrinsicWidth(side) + gap }
                val slots = if (room == Constraints.Infinity) Int.MAX_VALUE else ((room - leadWidth + gap) / (side + gap)).coerceAtLeast(0)
                subcompose(Slot.SHED) { fit(slots) }
            }.orEmpty()
            val controls = lead + rest
            fun exact(width: Int) = Constraints(maxWidth = width, minHeight = side, maxHeight = side)
            // Every control at its own width, then the first in what is left.
            val after = controls.drop(1).map { it.measure(exact(room)) }
            val left = if (room == Constraints.Infinity) room else (room - after.sumOf { it.width + gap }).coerceAtLeast(0)
            val line = listOfNotNull(controls.firstOrNull()?.measure(exact(left))) + after
            val lineWidth = line.sumOf { it.width } + gap * (line.size - 1).coerceAtLeast(0)
            val width = constraints.constrainWidth(lineWidth)
            layout(width, constraints.constrainHeight(if (line.isEmpty()) 0 else side)) {
                var x = if (centred) (width - lineWidth) / 2 else 0
                for (control in line) {
                    control.placeRelative(x, 0)
                    x += control.width + gap
                }
            }
        }
    }
}

/**
 * One of an [ActionRow]'s secondary actions ([FoldingActionRow]): a round button, or an entry of its ⋮; [modifier] goes
 * on the button (its focus memory key). Not [enabled]: the button stays in its place, dimmed, and leaves ⋮.
 */
class RowAction(val icon: ImageVector, val label: String, val probe: String, val modifier: Modifier = Modifier, val enabled: Boolean = true, val onClick: () -> Unit)

/**
 * An [ActionRow] whose secondary actions ([fold]) follow [content] as round buttons, as many as fit, the rest folded
 * into a round ⋮ at the row's end (harness name [moreProbe], its entries `<moreProbe>.<the action's last name part>`).
 * [more] is the screen's own ⋮ (an item's menu), the row's last button: when the row folds, the ⋮ is that one,
 * holding the folded actions and then [more]'s own entry.
 */
@Composable
fun FoldingActionRow(
    probe: String,
    fold: List<RowAction>,
    moreProbe: String,
    modifier: Modifier = Modifier,
    centred: Boolean = false,
    more: RowAction? = null,
    content: @Composable () -> Unit,
) {
    ActionRow(probe, modifier, centred, shed = { slots -> FoldedActions(fold, more, more?.probe ?: moreProbe, slots) }, content = content)
}

@Composable
private fun FoldedActions(fold: List<RowAction>, more: RowAction?, moreProbe: String, slots: Int) {
    val button = @Composable { action: RowAction -> PlezyIconButton(action.icon, action.label, action.onClick, action.modifier.layoutProbe(action.probe), enabled = action.enabled) }
    if (fold.size + (if (more != null) 1 else 0) <= slots) {
        fold.forEach { button(it) }
        more?.let { button(it) }
        return
    }
    val shown = fold.take((slots - 1).coerceAtLeast(0))
    shown.forEach { button(it) }
    var open by remember { mutableStateOf(false) }
    Box {
        PlezyIconButton(PlezyIcons.MoreVert, more?.label ?: T.common.options, { open = true }, Modifier.layoutProbe(moreProbe))
        val entries = fold.drop(shown.size).filter { it.enabled }.map { ItemMenuEntry(it.label, it.probe.substringAfterLast('.'), icon = it.icon, onClick = it.onClick) } +
            listOfNotNull(more?.let { ItemMenuEntry(it.label, "options", icon = it.icon, onClick = it.onClick) })
        ItemMenu(expanded = open, onDismiss = { open = false }, entries = entries, probe = moreProbe)
    }
}

/**
 * An [ActionRow]'s height: [LocalPlezyDimens]' `controlHeight`, or where the text is larger a pill's label line as the
 * platform lays it out (with Android's non-linear font scaling) with [ButtonLabelPadding] above and below it, so a pill
 * never cuts its label and every button of the row grows with it.
 */
@Composable
private fun actionRowHeight(): Dp {
    val style = MaterialTheme.typography.labelLarge
    val density = LocalDensity.current
    val measurer = rememberTextMeasurer()
    val line = remember(style, density) { with(density) { measurer.measure("Ag", style, maxLines = 1).size.height.toDp() } }
    return maxOf(LocalPlezyDimens.current.controlHeight, line + ButtonLabelPadding * 2)
}

/** The gap between an [ActionRow]'s controls, and between its lines. */
private val ActionGap = 10.dp

private enum class Slot { CONTENT, SHED }
