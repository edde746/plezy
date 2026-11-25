package com.edde746.plezy.ui.components

import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.Constraints
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Lays the content out at its own size, unconstrained, and where that is more than the room there is scales it down
 * from its top-left corner to fit (never up).
 */
internal fun Modifier.scaleDownToFit(): Modifier = layout { measurable, constraints ->
    val placed = measurable.measure(Constraints())
    val scale = min(
        1f,
        min(
            if (constraints.hasBoundedWidth && placed.width > 0) constraints.maxWidth.toFloat() / placed.width else 1f,
            if (constraints.hasBoundedHeight && placed.height > 0) constraints.maxHeight.toFloat() / placed.height else 1f,
        ),
    )
    layout((placed.width * scale).roundToInt(), (placed.height * scale).roundToInt()) {
        placed.placeWithLayer(0, 0) {
            scaleX = scale
            scaleY = scale
            transformOrigin = TransformOrigin(0f, 0f)
        }
    }
}
