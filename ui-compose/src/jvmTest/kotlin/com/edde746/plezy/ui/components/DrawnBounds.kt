package com.edde746.plezy.ui.components

import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.unit.DpRect

/**
 * Where the node's control is drawn, in the root: its layout's own box. A control with a hit target ([HitTarget]) takes
 * taps, and has its semantic bounds, in a larger square around it; this is the size and place it shows at.
 */
internal fun SemanticsNodeInteraction.getDrawnBoundsInRoot(): DpRect {
    val layout = fetchSemanticsNode().layoutInfo
    val box = layout.coordinates
    val at = box.positionInRoot()
    return with(layout.density) {
        DpRect(at.x.toDp(), at.y.toDp(), (at.x + box.size.width).toDp(), (at.y + box.size.height).toDp())
    }
}
