package com.edde746.plezy.ui.components

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * A sheet's list holds more above (its top fades) only once a row is hidden above its top or cut there by more than the
 * list's padding (the room of its rows' focus, under their label's margin), and more below (its bottom fades) the same
 * way: not while just its padding at that end is out of view, nor while a row there loses only that much.
 */
@OptIn(ExperimentalTestApi::class)
class ScrollEdgeFadeTest {
    @Test
    fun aListHoldsMoreAboveOnceARowIsCutPastItsPadding() = runComposeUiTest {
        val list = LazyListState()
        setContent {
            LazyColumn(Modifier.size(100.dp, 200.dp), state = list, contentPadding = PaddingValues(vertical = 16.dp)) {
                items(20) { Box(Modifier.fillMaxWidth().height(40.dp)) }
            }
        }
        val padding = with(density) { 16.dp.toPx() }
        runOnIdle { assertFalse(list.hidesRowsAbove(), "at its top") }
        runOnIdle { list.dispatchRawDelta(padding) }
        runOnIdle { assertFalse(list.hidesRowsAbove(), "its top padding scrolled away, the first row whole") }
        runOnIdle { list.dispatchRawDelta(padding) }
        runOnIdle { assertFalse(list.hidesRowsAbove(), "the first row cut by no more than the padding") }
        runOnIdle { list.dispatchRawDelta(2f) }
        runOnIdle { assertTrue(list.hidesRowsAbove(), "the first row cut past the padding") }
        runOnIdle { list.dispatchRawDelta(200f) }
        runOnIdle { assertTrue(list.hidesRowsAbove(), "the first rows gone") }
    }

    @Test
    fun aListHoldsMoreBelowWhileARowIsCutPastItsPadding() = runComposeUiTest {
        val list = LazyListState()
        setContent {
            LazyColumn(Modifier.size(100.dp, 200.dp), state = list, contentPadding = PaddingValues(vertical = 16.dp)) {
                items(20) { Box(Modifier.fillMaxWidth().height(40.dp)) }
            }
        }
        val padding = with(density) { 16.dp.toPx() }
        runOnIdle { assertTrue(list.hidesRowsBelow(), "at its top, the rows below hidden") }
        runOnIdle { list.requestScrollToItem(19) }
        runOnIdle { assertFalse(list.hidesRowsBelow(), "at its end, the last row whole above its bottom padding") }
        runOnIdle { list.dispatchRawDelta(-padding) }
        runOnIdle { assertFalse(list.hidesRowsBelow(), "its bottom padding out of view, the last row whole") }
        runOnIdle { list.dispatchRawDelta(-padding) }
        runOnIdle { assertFalse(list.hidesRowsBelow(), "the last row cut by no more than the padding") }
        runOnIdle { list.dispatchRawDelta(-2f) }
        runOnIdle { assertTrue(list.hidesRowsBelow(), "the last row cut past the padding") }
    }

    @Test
    fun aColumnHoldsMoreAtAnEndOnlyPastItsPadding() = runComposeUiTest {
        val scroll = ScrollState(0)
        setContent {
            Column(Modifier.size(100.dp, 200.dp).verticalScroll(scroll).padding(vertical = 16.dp)) {
                repeat(20) { Box(Modifier.fillMaxWidth().height(40.dp)) }
            }
        }
        val padding = with(density) { 16.dp.roundToPx() }
        runOnIdle { assertFalse(scroll.hidesRowsAbove(padding), "at its top") }
        runOnIdle { assertTrue(scroll.hidesRowsBelow(padding), "at its top, the rows below hidden") }
        runOnIdle { scroll.dispatchRawDelta(padding.toFloat()) }
        runOnIdle { assertFalse(scroll.hidesRowsAbove(padding), "its top padding scrolled away, the first row whole") }
        runOnIdle { scroll.dispatchRawDelta(padding.toFloat()) }
        runOnIdle { assertFalse(scroll.hidesRowsAbove(padding), "the first row cut by no more than the padding") }
        runOnIdle { scroll.dispatchRawDelta(2f) }
        runOnIdle { assertTrue(scroll.hidesRowsAbove(padding), "the first row cut past the padding") }
        runOnIdle { scroll.dispatchRawDelta(scroll.maxValue.toFloat()) }
        runOnIdle { assertFalse(scroll.hidesRowsBelow(padding), "at its end") }
        runOnIdle { scroll.dispatchRawDelta(-padding.toFloat()) }
        runOnIdle { assertFalse(scroll.hidesRowsBelow(padding), "its bottom padding out of view, the last row whole") }
        runOnIdle { scroll.dispatchRawDelta(-padding.toFloat()) }
        runOnIdle { assertFalse(scroll.hidesRowsBelow(padding), "the last row cut by no more than the padding") }
        runOnIdle { scroll.dispatchRawDelta(-2f) }
        runOnIdle { assertTrue(scroll.hidesRowsBelow(padding), "the last row cut past the padding") }
    }
}
