package com.edde746.plezy.servers

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class RefreshPacerTest {
    private val debounce = 3.seconds
    private val cooldown = 2.minutes
    private val blockedRetry = 15.seconds

    private class Harness(val pacer: RefreshPacer, val passes: MutableList<Int>) {
        var blocked = false
        var dropped = false
    }

    private fun TestScope.build(): Harness {
        val passes = mutableListOf<Int>()
        lateinit var harness: Harness
        val pacer = RefreshPacer(
            backgroundScope,
            debounce = debounce,
            cooldown = cooldown,
            blockedRetry = blockedRetry,
            isBlocked = { harness.blocked },
            runPass = {
                if (harness.dropped) {
                    false
                } else {
                    passes += passes.size
                    true
                }
            },
            timeSource = testScheduler.timeSource,
        )
        harness = Harness(pacer, passes)
        return harness
    }

    /** Fires everything due within [duration], the boundary included. */
    private fun TestScope.elapse(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    @Test
    fun aBurstCoalescesIntoOnePassAtTheDebounceEdge() = runTest {
        val h = build()
        h.pacer.schedule()
        elapse(1.seconds)
        h.pacer.schedule()
        h.pacer.schedule()
        assertTrue(h.passes.isEmpty())
        elapse(2.seconds)
        assertEquals(1, h.passes.size, "one pass exactly [debounce] after the first event")
        h.pacer.dispose()
    }

    @Test
    fun aSustainedSubDebounceEventStreamCannotStarveThePass() = runTest {
        val h = build()
        repeat(10) {
            h.pacer.schedule()
            elapse(2.seconds)
        }
        assertTrue(h.passes.isNotEmpty(), "arm-once debounce fires despite the stream never going quiet")
        h.pacer.dispose()
    }

    @Test
    fun blockedPassRetriesUntilUnblocked() = runTest {
        val h = build()
        h.blocked = true
        h.pacer.schedule()
        elapse(debounce + blockedRetry * 2)
        assertTrue(h.passes.isEmpty())
        h.blocked = false
        elapse(blockedRetry)
        assertEquals(1, h.passes.size)
        h.pacer.dispose()
    }

    @Test
    fun cooldownLatchesExactlyOneTrailingPass() = runTest {
        val h = build()
        h.pacer.schedule()
        elapse(debounce)
        assertEquals(1, h.passes.size, "leading pass right after a quiet period")
        repeat(3) {
            h.pacer.schedule()
            elapse(10.seconds)
        }
        assertEquals(1, h.passes.size, "cooldown holds")
        elapse(cooldown)
        assertEquals(2, h.passes.size, "exactly one trailing pass at the window edge")
        elapse(cooldown * 2)
        assertEquals(2, h.passes.size, "no further passes without new events")
        h.pacer.dispose()
    }

    @Test
    fun aChangeEventAfterTheCooldownExpiresRefreshesPromptly() = runTest {
        val h = build()
        h.pacer.schedule()
        elapse(debounce)
        assertEquals(1, h.passes.size)
        elapse(cooldown)
        h.pacer.schedule()
        elapse(debounce)
        assertEquals(2, h.passes.size)
        h.pacer.dispose()
    }

    @Test
    fun notePassCreditsAnExternalRefreshAndTheNextEventDefersToTheTrailingEdge() = runTest {
        val h = build()
        h.pacer.notePass()
        h.pacer.schedule()
        elapse(debounce)
        assertTrue(h.passes.isEmpty(), "the fresh pull pass absorbs the immediate push pass")
        elapse(cooldown)
        assertEquals(1, h.passes.size, "the change still lands as the trailing pass")
        h.pacer.dispose()
    }

    @Test
    fun notePassDefersALatchedTrailingPassToTheRefreshedWindowEdge() = runTest {
        val h = build()
        h.pacer.schedule()
        elapse(debounce)
        h.pacer.schedule()
        elapse(debounce)
        assertEquals(1, h.passes.size)
        elapse(1.minutes)
        h.pacer.notePass()
        elapse(cooldown - 1.minutes)
        assertEquals(1, h.passes.size, "the old window edge no longer fires")
        elapse(1.minutes)
        assertEquals(2, h.passes.size, "the owed pass lands at the refreshed edge")
        h.pacer.dispose()
    }

    @Test
    fun aDroppedPassDoesNotSpendTheCooldown() = runTest {
        val h = build()
        h.dropped = true
        h.pacer.schedule()
        elapse(debounce)
        assertTrue(h.passes.isEmpty())
        h.dropped = false
        h.pacer.schedule()
        elapse(debounce)
        assertEquals(1, h.passes.size, "next event refreshes promptly; no cooldown was armed")
        h.pacer.dispose()
    }

    @Test
    fun disposeCancelsScheduledWork() = runTest {
        val h = build()
        h.pacer.schedule()
        h.pacer.dispose()
        elapse(debounce * 2)
        assertTrue(h.passes.isEmpty())
    }
}
