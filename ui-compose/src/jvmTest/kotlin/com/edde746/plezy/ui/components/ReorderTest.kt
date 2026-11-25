package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runSkikoComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals

/** Dragging a row of a reorderable list (Addons, Home's rows, the language lists) past rows of other heights. */
@OptIn(ExperimentalTestApi::class)
class ReorderTest {
    /**
     * A 200 px row dragged well past four 40 px rows (160 px in all) drops last, where it is drawn, not one place down
     * for each of its own heights.
     */
    @Test
    fun aTallRowDraggedPastShortOnesDropsWhereItIsDrawn() = runSkikoComposeUiTest(size = Size(400f, 800f), density = Density(1f)) {
        val heights = listOf(200, 40, 40, 40, 40)
        val moves = mutableListOf<Pair<String, Int>>()
        setContent {
            val reorder = rememberReorderState(0.dp)
            Column {
                heights.forEachIndexed { index, height ->
                    Box(Modifier.fillMaxWidth().height(height.dp).reorderItem(reorder, "row$index", index).testTag("row$index")) {
                        Box(Modifier.size(24.dp).testTag("handle$index").reorderHandle(reorder, "row$index", index, heights.size) { key, to -> moves += key to to })
                    }
                }
            }
        }
        onNodeWithTag("handle0").performTouchInput {
            down(center)
            repeat(10) { moveBy(Offset(0f, 40f)) }
        }
        val drawn = onNodeWithTag("row0").getBoundsInRoot().top
        onNodeWithTag("handle0").performTouchInput { up() }
        assertEquals(listOf("row0" to heights.lastIndex), moves, "dropped with the row drawn $drawn down")
    }
}
