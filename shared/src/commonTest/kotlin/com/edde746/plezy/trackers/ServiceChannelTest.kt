package com.edde746.plezy.trackers

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration

class ServiceChannelTest {
    @Test
    fun aBurstBehindAHungRequestShedsTheOldestReportsButNeverAStopOrAWrite() = runTest {
        val channel = ServiceChannel(backgroundScope, TrackerService.SIMKL)
        val sent = mutableListOf<String>()
        val hung = CompletableDeferred<Unit>()
        fun submit(name: String, state: ScrobbleState?) = channel.submit(state, Duration.ZERO) {
            if (name == "start-1") hung.await()
            sent += name
            true
        }
        submit("start-1", ScrobbleState.START)
        runCurrent()
        val answers = listOf(
            submit("stop-1", ScrobbleState.STOP),
            submit("start-2", ScrobbleState.START),
            submit("history", null),
            submit("pause-2", ScrobbleState.PAUSE),
            submit("start-3", ScrobbleState.START),
            submit("pause-3", ScrobbleState.PAUSE),
        )
        hung.complete(Unit)
        channel.settle()
        // Five reports waited behind the hung one: the oldest that isn't a stop went.
        assertEquals(listOf("start-1", "stop-1", "history", "pause-2", "start-3", "pause-3"), sent)
        assertEquals(listOf(true, false, true), answers.take(3).map { it.await() })
    }
}
