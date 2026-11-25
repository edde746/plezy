package com.edde746.plezy.ui.components

import androidx.compose.material3.LocalMinimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntSize
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.LocalWindowLayout

/**
 * The hit target of a control drawn smaller than a finger's least target (an icon button, a one-line button): on a
 * touch screen (phones and tablets) a square of Material's minimum interactive size (48 dp) at least, centred on the
 * control. Its [bounds] go before the control's click handling and its [square] after it: the square takes the taps and
 * is the control's bounds for screen readers, the control keeps its drawn size and place, and the row around it lays
 * out the drawn size alone, the square reaching over the room beside it. A remote (TV) moves focus and a pointer
 * (desktop) is precise: there, as for a control drawn at least that large, nothing changes.
 */
internal class HitTarget(private val side: Dp) {
    /** The drawn control's size, measured inside [square] for [bounds]. */
    private var drawn = IntSize.Zero

    /** Lays out the drawn size in the row, centred on the square. */
    val bounds: Modifier = Modifier.layout { measurable, constraints ->
        val square = measurable.measure(constraints)
        val size = drawn
        layout(size.width, size.height) { square.place((size.width - square.width) / 2, (size.height - square.height) / 2) }
    }

    /** The square, at least [side] each way, the drawn control centred in it. */
    val square: Modifier = Modifier.layout { measurable, constraints ->
        val control = measurable.measure(constraints)
        drawn = IntSize(control.width, control.height)
        val least = side.roundToPx()
        val width = maxOf(control.width, least)
        val height = maxOf(control.height, least)
        layout(width, height) { control.place((width - control.width) / 2, (height - control.height) / 2) }
    }
}

/** This window's [HitTarget] for one control: null on TV and desktop. */
@Composable
internal fun rememberHitTarget(): HitTarget? {
    if (LocalWindowLayout.current.formFactor != FormFactor.HANDHELD) return null
    val side = LocalMinimumInteractiveComponentSize.current
    return remember(side) { HitTarget(side) }
}
