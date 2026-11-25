package com.edde746.plezy.music

import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class CarUxRestrictionsTest {
    private fun TestScope.restrictions(source: FakeCarSource?) = CarUxRestrictions(source, backgroundScope, testScheduler.timeSource)

    private suspend fun TestScope.timed(block: suspend () -> Unit): Duration {
        val start = testScheduler.timeSource.markNow()
        block()
        return start.elapsedNow()
    }

    @Test
    fun staysUnknownOffACarAndNeverAsks() = runTest {
        val car = restrictions(null)
        car.ensureStarted()
        car.ensureResolved()
        assertEquals(CarUxRestrictionState.UNKNOWN, car.state.value)
    }

    @Test
    fun readsTheVehicleStateOnFirstUse() = runTest {
        val source = FakeCarSource(FakeCarSource.PARKED)
        val car = restrictions(source)
        assertEquals(CarUxRestrictionState.UNKNOWN, car.state.value)
        assertTrue(source.calls.isEmpty())

        car.ensureStarted()
        runCurrent()

        assertEquals(listOf("getState"), source.calls)
        assertEquals(CarUxRestrictionState.UNRESTRICTED, car.state.value)
    }

    @Test
    fun aCarThatCannotAnswerStaysUnknownSoCallersKeepTheForegroundRule() = runTest {
        val car = restrictions(FakeCarSource(FakeCarSource.GONE.copy(requiresDistractionOptimization = false)))
        car.ensureStarted()
        runCurrent()
        assertEquals(CarUxRestrictionState.UNKNOWN, car.state.value)
    }

    @Test
    fun aWedgedCarServiceCostsOneBudgetNotOnePerCaller() = runTest {
        val source = FakeCarSource().apply { neverAnswer = true }
        val car = restrictions(source)
        val budget = 300.milliseconds

        val first = timed { car.ensureResolved(budget) }
        val second = timed { car.ensureResolved(budget) }

        assertEquals(listOf("getState"), source.calls, "awaiting an in-flight call again is not a retry")
        assertEquals(Duration.ZERO, second, "a call known to be stuck is not waited on again")
        assertEquals(budget, first, "the timeout is the whole budget, not per attempt")
        assertEquals(CarUxRestrictionState.UNKNOWN, car.state.value)
    }

    @Test
    fun aVehicleThatAnsweredWithoutAVerdictIsAskedAgain() = runTest {
        val source = FakeCarSource(FakeCarSource.GONE.copy(requiresDistractionOptimization = false))
        val car = restrictions(source)

        car.ensureResolved(300.milliseconds)
        assertEquals(listOf("getState", "getState"), source.calls, "a car service that wasn't up yet can connect later")

        source.answer = FakeCarSource.DRIVING
        car.ensureResolved(300.milliseconds)
        assertEquals(CarUxRestrictionState.RESTRICTED, car.state.value)
    }

    @Test
    fun aCarServiceThatDiesDropsTheVerdictInsteadOfFreezingIt() = runTest {
        val source = FakeCarSource(FakeCarSource.PARKED)
        val car = restrictions(source)
        car.ensureResolved(300.milliseconds)
        assertEquals(CarUxRestrictionState.UNRESTRICTED, car.state.value)

        source.push(FakeCarSource.GONE)
        runCurrent()

        assertEquals(CarUxRestrictionState.UNKNOWN, car.state.value)
    }

    @Test
    fun aCarServiceThatIsStillConnectingIsWaitedForNotReadAsAbsent() = runTest {
        val source = FakeCarSource(FakeCarSource.CONNECTING)
        val car = restrictions(source)

        val waiting = async { car.ensureResolved(2.seconds) }
        runCurrent()
        assertFalse(waiting.isCompleted, "the verdict is on its way")

        source.push(FakeCarSource.PARKED)
        waiting.await()

        assertEquals(CarUxRestrictionState.UNRESTRICTED, car.state.value)
    }

    @Test
    fun aDeviceWithNoCarServiceIsNotWaitedForAtAll() = runTest {
        val car = restrictions(FakeCarSource(FakeCarSource.GONE))

        val spent = timed { car.ensureResolved(2.seconds) }

        assertEquals(Duration.ZERO, spent, "nothing is coming: don't hold playback")
        assertEquals(CarUxRestrictionState.UNKNOWN, car.state.value)
    }

    @Test
    fun aPromisedVerdictThatNeverArrivesIsWaitedForOnceNotPerCaller() = runTest {
        val source = FakeCarSource(FakeCarSource.CONNECTING)
        val car = restrictions(source)
        val budget = 300.milliseconds

        val first = timed { car.ensureResolved(budget) }
        val second = timed { car.ensureResolved(budget) }

        assertEquals(Duration.ZERO, second, "a push that never came must not delay every open")
        assertEquals(budget, first)
        assertEquals(CarUxRestrictionState.UNKNOWN, car.state.value)

        source.push(FakeCarSource.PARKED)
        runCurrent()
        assertEquals(CarUxRestrictionState.UNRESTRICTED, car.state.value, "a late answer still lands")
    }

    @Test
    fun aStalledPlatformIsStillAskedSoItCanRetryItsOwnConnection() = runTest {
        val source = FakeCarSource(FakeCarSource.CONNECTING)
        val car = restrictions(source)

        car.ensureResolved(200.milliseconds)
        val asks = source.calls.size
        car.ensureResolved(200.milliseconds)
        runCurrent()

        assertTrue(source.calls.size > asks)
    }

    @Test
    fun platformPushesFlipTheStateAndNotifyObservers() = runTest {
        val source = FakeCarSource(FakeCarSource.PARKED)
        val car = restrictions(source)
        car.ensureStarted()
        runCurrent()
        val seen = mutableListOf<CarUxRestrictionState>()
        backgroundScope.launch { car.state.collect { seen += it } }
        runCurrent()

        source.push(FakeCarSource.DRIVING)
        runCurrent()
        source.push(FakeCarSource.DRIVING)
        runCurrent()
        source.push(FakeCarSource.PARKED)
        runCurrent()

        assertEquals(
            listOf(CarUxRestrictionState.UNRESTRICTED, CarUxRestrictionState.RESTRICTED, CarUxRestrictionState.UNRESTRICTED),
            seen,
        )
    }

    @Test
    fun aCarServiceThatCannotBeReachedDegradesToUnknown() = runTest {
        val car = restrictions(FakeCarSource(null))
        car.ensureStarted()
        runCurrent()
        assertEquals(CarUxRestrictionState.UNKNOWN, car.state.value)
    }

    @Test
    fun playbackIsAllowedOffACarByTheVerdictInACarAndInFrontOnlyWithoutOne() {
        assertTrue(automotivePlaybackAllowed(isAutomotive = false, foreground = false, restrictions = CarUxRestrictionState.RESTRICTED))
        assertFalse(automotivePlaybackAllowed(isAutomotive = true, foreground = true, restrictions = CarUxRestrictionState.RESTRICTED))
        assertTrue(automotivePlaybackAllowed(isAutomotive = true, foreground = false, restrictions = CarUxRestrictionState.UNRESTRICTED))
        assertTrue(automotivePlaybackAllowed(isAutomotive = true, foreground = true, restrictions = CarUxRestrictionState.UNKNOWN))
        assertFalse(automotivePlaybackAllowed(isAutomotive = true, foreground = false, restrictions = CarUxRestrictionState.UNKNOWN))
    }
}
