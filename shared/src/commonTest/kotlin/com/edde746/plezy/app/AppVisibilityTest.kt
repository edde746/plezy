package com.edde746.plezy.app

import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

/** Whether the app can be seen ([AppGraph.visible]), which watch together's player follows. */
class AppVisibilityTest {
    @Test
    fun theMacsWindowAloneDecidesWhetherTheAppCanBeSeen() = runTest {
        val graph = testGraph()
        val seen = mutableListOf<Boolean>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { graph.visible.collect { seen += it } }

        // Where no window reports (Android, desktop, iOS, tvOS): the foreground.
        graph.setForeground(true)
        assertEquals(true, seen.last(), "in the foreground")
        graph.setForeground(false)
        assertEquals(false, seen.last(), "in the background")

        // The Mac: another app in front of a window that still shows, then the window minimized while the app is active.
        graph.setWindowVisible(true)
        assertEquals(true, seen.last(), "another app in front, the window in sight")
        graph.setForeground(true)
        graph.setWindowVisible(false)
        assertEquals(false, seen.last(), "the window minimized while the app is active")
    }
}
