package com.edde746.plezy.presentation.livetv

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.seconds

class LiveTvRefreshGateTest {
    private class Recorder {
        var ticks = 0
        val events = mutableListOf<String>()
    }

    private fun TestScope.gate(foreground: MutableStateFlow<Boolean>, recorder: Recorder): LiveTvRefreshGate {
        val gate = LiveTvRefreshGate(
            backgroundScope,
            interval = 30.seconds,
            appForeground = foreground,
            onTick = { recorder.ticks++ },
            onPaused = { recorder.events += "paused" },
            onResumed = { recorder.events += "resumed $it" },
        )
        runCurrent()
        return gate
    }

    @Test
    fun ticksRunOnlyWhileTheTabIsSelectedShownAndInTheForeground() = runTest {
        val foreground = MutableStateFlow(true)
        val recorder = Recorder()
        val gate = gate(foreground, recorder)

        advanceTimeBy(61.seconds)
        assertEquals(0, recorder.ticks)

        gate.setSelected(true)
        advanceTimeBy(61.seconds)
        assertEquals(2, recorder.ticks)

        gate.setShown(false)
        advanceTimeBy(61.seconds)
        assertEquals(2, recorder.ticks)

        gate.setShown(true)
        foreground.value = false
        runCurrent()
        advanceTimeBy(61.seconds)
        assertEquals(2, recorder.ticks)

        foreground.value = true
        runCurrent()
        advanceTimeBy(31.seconds)
        assertEquals(3, recorder.ticks)
        gate.close()
    }

    @Test
    fun eachGateEdgeReportsAPauseOrTheReasonItResumed() = runTest {
        val foreground = MutableStateFlow(true)
        val recorder = Recorder()
        val gate = gate(foreground, recorder)

        gate.setSelected(true)
        gate.setShown(false)
        gate.setShown(true)
        foreground.value = false
        runCurrent()
        foreground.value = true
        runCurrent()
        gate.setSelected(false)

        assertEquals(
            listOf(
                "resumed TAB_SELECTED",
                "paused",
                "resumed SCREEN_SHOWN",
                "paused",
                "resumed APP_FOREGROUND",
                "paused",
            ),
            recorder.events,
        )
        gate.close()
    }

    @Test
    fun aGateOpeningWhileAnotherIsClosedResumesNothing() = runTest {
        val foreground = MutableStateFlow(false)
        val recorder = Recorder()
        val gate = gate(foreground, recorder)

        gate.setSelected(true)
        gate.setSelected(true)
        advanceTimeBy(61.seconds)

        assertEquals(emptyList(), recorder.events)
        assertEquals(0, recorder.ticks)
        gate.close()
    }
}
