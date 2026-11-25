package com.edde746.plezy.backend.net

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

@OptIn(ExperimentalCoroutinesApi::class)
class EndpointRaceTest {
    private data class Probe(val url: String, val ok: Boolean)

    private val headStart = 60.milliseconds
    private val logs = mutableListOf<String>()
    private val originalSink = Log.sink
    private val originalLevel = Log.minLevel

    @BeforeTest
    fun captureLogs() {
        Log.minLevel = Log.Level.DEBUG
        Log.sink = Log.Sink { _, _, message, error -> logs += message + "\n" + error.orEmpty() }
    }

    @AfterTest
    fun restoreLogs() {
        Log.sink = originalSink
        Log.minLevel = originalLevel
    }

    private fun race(
        candidates: List<String>,
        preferred: String? = null,
        tierOf: ((String) -> Int)? = null,
        measure: suspend (String) -> Probe = { Probe(it, false) },
        selectBest: (Map<String, Probe>) -> String? = { it.keys.first() },
        probe: suspend (String) -> Probe,
    ): Flow<EndpointRaceSelection<String, Probe>> = raceEndpointCandidates(
        label = "test",
        candidates = candidates,
        urlOf = { it },
        probe = { candidate, _ -> probe(candidate) },
        measure = measure,
        isSuccess = { it.ok },
        selectBestCandidate = selectBest,
        preferredUrl = preferred,
        tierOf = tierOf,
        preferredTimeout = 500.milliseconds,
        preferredHeadStart = headStart,
        raceTimeout = 500.milliseconds,
    )

    /** Probes that answer only when the test completes their gate; [counts] records every probe started. */
    private class Gates {
        val counts = mutableMapOf<String, Int>()
        val gates = mutableMapOf<String, MutableList<CompletableDeferred<Probe>>>()

        suspend fun probe(url: String): Probe {
            counts[url] = (counts[url] ?: 0) + 1
            val gate = CompletableDeferred<Probe>()
            gates.getOrPut(url) { mutableListOf() } += gate
            return gate.await()
        }

        fun answer(url: String, ok: Boolean) {
            gates.getValue(url).last().complete(Probe(url, ok))
        }
    }

    private fun TestScope.collect(flow: Flow<EndpointRaceSelection<String, Probe>>, into: MutableList<EndpointRaceSelection<String, Probe>>): Job =
        launch { flow.toList(into) }

    @Test
    fun aHealthyCachedEndpointWinsWithinTheHeadStartWithoutRacing() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("a", "cached"), preferred = "cached") { gates.probe(it) }, selections)
        runCurrent()
        assertEquals(mapOf("cached" to 1), gates.counts)

        gates.answer("cached", ok = true)
        runCurrent()

        assertEquals(EndpointRacePhase.FIRST, selections.first().phase)
        assertEquals("cached", selections.first().candidate)
        assertTrue(selections.first().fromPreferred)
        assertFalse("a" in gates.counts)
        job.cancel()
    }

    @Test
    fun aStaleSlowCachedEndpointOverlapsTheRaceInsteadOfBlockingIt() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("fast", "cached"), preferred = "cached") { gates.probe(it) }, selections)
        runCurrent()
        assertEquals(mapOf("cached" to 1), gates.counts)

        advanceTimeBy(headStart - 1.milliseconds)
        runCurrent()
        assertEquals(mapOf("cached" to 1), gates.counts)

        advanceTimeBy(1.milliseconds)
        runCurrent()
        assertEquals(mapOf("cached" to 1, "fast" to 1), gates.counts)

        gates.answer("fast", ok = true)
        runCurrent()
        assertEquals(EndpointRacePhase.FIRST, selections.first().phase)
        assertEquals("fast", selections.first().candidate)
        assertFalse(selections.first().fromPreferred)
        assertEquals(1, gates.counts["cached"])
        job.cancel()
    }

    @Test
    fun aCachedEndpointAnsweringAfterTheHeadStartStillWinsWhenFirst() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("slow", "cached"), preferred = "cached") { gates.probe(it) }, selections)
        runCurrent()
        advanceTimeBy(headStart)
        runCurrent()
        assertEquals(mapOf("cached" to 1, "slow" to 1), gates.counts)

        gates.answer("cached", ok = true)
        runCurrent()

        assertEquals("cached", selections.first().candidate)
        assertTrue(selections.first().fromPreferred)
        assertEquals(1, gates.counts["cached"], "the pending head-start probe joins the race rather than being re-sent")
        job.cancel()
    }

    @Test
    fun aCachedEndpointFailingWithinTheHeadStartFallsBackToAFreshRace() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("cached", "alt"), preferred = "cached") { gates.probe(it) }, selections)
        runCurrent()

        gates.answer("cached", ok = false)
        runCurrent()
        assertEquals(mapOf("cached" to 2, "alt" to 1), gates.counts)

        gates.answer("cached", ok = false)
        gates.answer("alt", ok = true)
        runCurrent()

        assertEquals("alt", selections.first().candidate)
        assertFalse(selections.first().fromPreferred)
        assertEquals(2, gates.counts["cached"])
        job.cancel()
    }

    @Test
    fun aPreferredUrlNotAmongTheCandidatesSkipsTheCachedProbe() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("a", "b"), preferred = "custom-url") { gates.probe(it) }, selections)
        runCurrent()

        assertFalse("custom-url" in gates.counts)
        assertEquals(mapOf("a" to 1, "b" to 1), gates.counts, "no head start: every candidate races at once")
        gates.answer("a", ok = true)
        gates.answer("b", ok = false)
        runCurrent()

        assertEquals("a", selections.first().candidate)
        assertFalse(selections.first().fromPreferred)
        job.cancel()
    }

    @Test
    fun emitsNothingWhenEveryCandidateFails() = runTest {
        assertEquals(emptyList(), race(listOf("a", "b"), preferred = "a") { Probe(it, false) }.toList())
    }

    @Test
    fun emitsNothingWithoutCandidates() = runTest {
        assertEquals(emptyList(), race(emptyList()) { Probe(it, true) }.toList())
    }

    @Test
    fun aThrowingProbeCountsAsAFailedCandidate() = runTest {
        val selections = race(listOf("broken", "ok")) { if (it == "broken") error("probe crashed") else Probe(it, true) }.toList()
        assertEquals("ok", selections.first().candidate)
    }

    @Test
    fun phaseTwoStillPromotesTheSelectorBestEndpoint() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(
            race(listOf("quick", "better"), measure = { Probe(it, true) }, selectBest = { "better" }) { gates.probe(it) },
            selections,
        )
        runCurrent()
        gates.answer("quick", ok = true)
        runCurrent()

        assertEquals(2, selections.size)
        assertEquals(EndpointRacePhase.FIRST, selections.first().phase)
        assertEquals("quick", selections.first().candidate)
        assertEquals(EndpointRacePhase.BEST, selections.last().phase)
        assertEquals("better", selections.last().candidate)
        assertEquals(setOf("quick", "better"), selections.last().successfulResults.keys)
        job.cancel()
    }

    @Test
    fun preferredEndpointDiagnosticsContainNoCandidateLiterals() = runTest {
        val canary = "https://preferred-race-canary.invalid/private-race-path"

        val selections = race(listOf(canary), preferred = canary, measure = { Probe(it, true) }) { Probe(it, true) }.toList()

        assertTrue(selections.all { it.candidate == canary })
        assertTrue(logs.isNotEmpty())
        assertNoLogContains("preferred-race-canary.invalid", "private-race-path")
    }

    // A real probe fails with its transport's error, whose text names the endpoint it tried.
    @Test
    fun candidateFailureDiagnosticsSanitizeEndpointBearingFields() = runTest {
        val canary = "https://failure-race-canary.invalid/private-failure-path"

        val selections = race(listOf(canary)) { candidate ->
            throw IllegalStateException("probe failed at $candidate on failure-race-canary.invalid path /private-failure-path")
        }.toList()

        assertEquals(emptyList(), selections)
        assertNoLogContains("failure-race-canary.invalid", "private-failure-path")
    }

    private fun assertNoLogContains(vararg literals: String) {
        for (line in logs) for (literal in literals) assertFalse(literal in line, "log leaks $literal: $line")
    }

    private val relayTier: (String) -> Int = { if (it == "relay") 1 else 0 }

    @Test
    fun aFallbackTierSuccessIsHeldAndAcceptedOnlyAfterPreferredTiersFail() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("direct", "relay"), tierOf = relayTier) { gates.probe(it) }, selections)
        runCurrent()
        // The hold delays acceptance, never the probe: both start at once.
        assertEquals(mapOf("direct" to 1, "relay" to 1), gates.counts)

        gates.answer("relay", ok = true)
        runCurrent()
        assertEquals(emptyList(), selections)

        gates.answer("direct", ok = false)
        runCurrent()
        assertEquals(EndpointRacePhase.FIRST, selections.first().phase)
        assertEquals("relay", selections.first().candidate)
        job.cancel()
    }

    @Test
    fun aSlowerPreferredTierSuccessBeatsAnEarlierFallbackTierSuccess() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("direct", "relay"), tierOf = relayTier) { gates.probe(it) }, selections)
        runCurrent()

        gates.answer("relay", ok = true)
        runCurrent()
        assertEquals(emptyList(), selections)

        gates.answer("direct", ok = true)
        runCurrent()
        assertEquals("direct", selections.first().candidate)
        job.cancel()
    }

    @Test
    fun theFallbackTierWinsWithoutDelayOnceEveryPreferredTierCandidateFailed() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("direct", "relay"), tierOf = relayTier) { gates.probe(it) }, selections)
        runCurrent()

        gates.answer("direct", ok = false)
        runCurrent()
        gates.answer("relay", ok = true)
        runCurrent()

        // No hold window remains: accepted on the spot, no virtual time passes.
        assertEquals("relay", selections.first().candidate)
        assertEquals(0L, testScheduler.currentTime)
        job.cancel()
    }

    @Test
    fun aCachedFallbackTierUrlGetsNoHeadStartAndStillLosesToAPreferredTier() = runTest {
        val gates = Gates()
        val selections = mutableListOf<EndpointRaceSelection<String, Probe>>()
        val job = collect(race(listOf("direct", "relay"), preferred = "relay", tierOf = relayTier) { gates.probe(it) }, selections)
        runCurrent()
        // A cached relay URL (persisted by an older build) is an ordinary participant: no window where only it probes.
        assertEquals(mapOf("direct" to 1, "relay" to 1), gates.counts)

        gates.answer("relay", ok = true)
        runCurrent()
        assertEquals(emptyList(), selections)

        gates.answer("direct", ok = true)
        runCurrent()
        assertEquals("direct", selections.first().candidate)
        assertFalse(selections.first().fromPreferred)
        job.cancel()
    }

    @Test
    fun emitsNothingWhenEveryTierFails() = runTest {
        assertEquals(emptyList(), race(listOf("direct", "relay"), tierOf = relayTier) { Probe(it, false) }.toList())
    }
}
