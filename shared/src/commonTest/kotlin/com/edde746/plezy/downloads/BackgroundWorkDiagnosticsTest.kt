package com.edde746.plezy.downloads

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

internal fun activity(
    activeTasks: Int = 1,
    completedTasks: Int = 0,
    failedTasks: Int = 0,
    downloadedBytes: Long = 1000,
    progressUnits: Int = 0,
    networkAvailable: Boolean? = true,
    networkStateGeneration: Int = 0,
) = DownloadActivitySnapshot(
    activeTasks = activeTasks,
    completedTasks = completedTasks,
    failedTasks = failedTasks,
    downloadedBytes = downloadedBytes,
    progressUnits = progressUnits,
    networkAvailable = networkAvailable,
    networkStateGeneration = networkStateGeneration,
)

/** A reader answering [signals]; it records its calls. */
internal class FakeBackgroundWorkProbe(var signals: Map<String, Any?> = mapOf("verdict" to "ok", "reasons" to emptyList<String>())) :
    BackgroundWorkProbe {
    val calls = mutableListOf<String>()
    val openedTargets = mutableListOf<String>()
    var gate: CompletableDeferred<Map<String, Any?>>? = null
    var missing = false
    var opens = true

    override suspend fun backgroundWorkSignals(): Map<String, Any?>? {
        calls += "getBackgroundWorkSignals"
        if (missing) throw UnsupportedOperationException()
        return gate?.await() ?: signals
    }

    override suspend fun openBackgroundSettings(target: BackgroundSettingsTarget): Boolean {
        calls += "openBackgroundSettings"
        openedTargets += target.id
        return opens
    }
}

internal class MutableClock(var now: Instant) : Clock {
    override fun now(): Instant = now
}

internal fun TestScope.diagnostics(
    probe: BackgroundWorkProbe,
    stallDetector: DownloadStallDetector = DownloadStallDetector(),
    networkProbe: suspend () -> Boolean = { true },
    clock: Clock = Clock.System,
    supported: Boolean = true,
    foreground: MutableStateFlow<Boolean> = MutableStateFlow(true),
) = BackgroundWorkDiagnosticsService(probe, supported, foreground, networkProbe, backgroundScope, stallDetector, clock)

class DownloadStallDetectorTest {
    private val detector = DownloadStallDetector(minimumBackgroundGap = 60.seconds, minimumProgressBytes = 64L * 1024, observationsToConfirm = 2)
    private val start = Instant.parse("2026-07-25T12:00:00Z")

    @Test
    fun needsTwoConsecutiveStallsBeforeAccusingTheOem() {
        detector.onPaused(activity(), start)
        assertFalse(detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true))
        assertFalse(detector.isStalled)

        detector.onPaused(activity(), start + 6.minutes)
        assertTrue(detector.evaluate(detector.captureResumed(activity(), start + 11.minutes), true))
        assertTrue(detector.isStalled)
    }

    @Test
    fun confirmsOnlyOnceSoTheWarningIsNotRaisedAgainEveryResume() {
        repeat(2) {
            detector.onPaused(activity(), start)
            detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true)
        }
        assertTrue(detector.isStalled)

        detector.onPaused(activity(), start)
        assertFalse(detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true), "already confirmed")
    }

    @Test
    fun realBackgroundProgressClearsTheCounter() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true)
        assertEquals(1, detector.consecutiveStalls)

        detector.onPaused(activity(), start + 6.minutes)
        detector.evaluate(detector.captureResumed(activity(downloadedBytes = 1000L + 5 * 1024 * 1024), start + 11.minutes), true)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun aCompletedDownloadBelowTheByteFloorClearsTheCounter() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true)
        assertEquals(1, detector.consecutiveStalls)

        detector.onPaused(activity(), start + 6.minutes)
        detector.evaluate(detector.captureResumed(activity(activeTasks = 0, completedTasks = 1, downloadedBytes = 21L * 1024), start + 11.minutes), true)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun aCompletionWithOmittedByteCountersStillClearsTheCounter() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true)
        assertEquals(1, detector.consecutiveStalls)

        detector.onPaused(activity(downloadedBytes = 500L * 1024 * 1024), start + 6.minutes)
        detector.evaluate(detector.captureResumed(activity(activeTasks = 0, completedTasks = 1, downloadedBytes = 0), start + 11.minutes), true)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun percentageProgressClearsTheCounterWhenByteLengthIsUnknown() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true)
        assertEquals(1, detector.consecutiveStalls)

        detector.onPaused(activity(progressUnits = 20), start + 6.minutes)
        detector.evaluate(detector.captureResumed(activity(progressUnits = 21), start + 11.minutes), true)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun anIdleAppIsNeverScored() {
        detector.onPaused(activity(activeTasks = 0), start)
        assertFalse(detector.evaluate(detector.captureResumed(activity(activeTasks = 0), start + 8.hours), true))
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun aTaskRemovedWithoutFailingIsInconclusive() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true)
        assertEquals(1, detector.consecutiveStalls)

        detector.onPaused(activity(), start + 6.minutes)
        detector.evaluate(detector.captureResumed(activity(activeTasks = 0), start + 11.minutes), true)
        assertEquals(1, detector.consecutiveStalls)
    }

    @Test
    fun aNewlyFailedActiveTaskIsStallEvidence() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(activeTasks = 0, failedTasks = 1), start + 5.minutes), true)
        assertEquals(1, detector.consecutiveStalls)
    }

    @Test
    fun aShortBackgroundTripProvesNothing() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(), start + 30.seconds), true)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun beingOfflineIsNotEvidenceOfARestriction() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), false)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun anOfflineEndpointIsInconclusiveEvenWhenPolicyAllowsDownloads() {
        detector.onPaused(activity(networkAvailable = false), start)
        detector.evaluate(detector.captureResumed(activity(networkAvailable = false), start + 5.minutes), true)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun aNetworkTransitionDuringTheBackgroundWindowIsInconclusive() {
        detector.onPaused(activity(networkStateGeneration = 4), start)
        detector.evaluate(detector.captureResumed(activity(networkStateGeneration = 5), start + 5.minutes), true)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun downloadsDeletedWhileBackgroundedAreInconclusive() {
        detector.onPaused(activity(activeTasks = 2, downloadedBytes = 900L * 1024 * 1024), start)
        detector.evaluate(detector.captureResumed(activity(downloadedBytes = 10L * 1024 * 1024), start + 5.minutes), true)
        assertEquals(0, detector.consecutiveStalls)
    }

    @Test
    fun resetClearsBothTheArmedSnapshotAndTheCount() {
        detector.onPaused(activity(), start)
        detector.evaluate(detector.captureResumed(activity(), start + 5.minutes), true)
        detector.reset()
        assertEquals(0, detector.consecutiveStalls)

        assertFalse(detector.evaluate(detector.captureResumed(activity(), start + 10.minutes), true))
    }
}

class BackgroundWorkStatusTest {
    @Test
    fun describeReportsUnknownUntilAProbeLands() {
        assertEquals("unknown", BackgroundWorkStatus().describe())
    }

    @Test
    fun describeCarriesVerdictReasonsAndRawSignalsForLogUploads() {
        val status = BackgroundWorkStatus(
            verdict = BackgroundWorkVerdict.BLOCKED,
            reasons = listOf(BackgroundWorkReason.BACKGROUND_RESTRICTED, BackgroundWorkReason.STANDBY_RESTRICTED),
            standbyBucket = 45,
            ignoringBatteryOptimizations = false,
            probed = true,
        )

        assertEquals("blocked background_restricted+standby_restricted bucket:45 batteryWhitelist:false", status.describe())
    }

    @Test
    fun routesNotificationFaultsToTheirValidSettingsScreens() {
        val channel = BackgroundWorkStatus(BackgroundWorkVerdict.DEGRADED, listOf(BackgroundWorkReason.DOWNLOAD_CHANNEL_BLOCKED), probed = true)
        val appWide = BackgroundWorkStatus(BackgroundWorkVerdict.BLOCKED, listOf(BackgroundWorkReason.NOTIFICATIONS_DISABLED), probed = true)
        val battery = BackgroundWorkStatus(BackgroundWorkVerdict.BLOCKED, listOf(BackgroundWorkReason.BACKGROUND_RESTRICTED), probed = true)

        assertEquals(BackgroundSettingsTarget.NOTIFICATION_CHANNEL, channel.remedyTarget)
        assertEquals(BackgroundSettingsTarget.APP_NOTIFICATIONS, appWide.remedyTarget)
        assertEquals(BackgroundSettingsTarget.APP_DETAILS, battery.remedyTarget)
    }
}

class BackgroundWorkDiagnosticsServiceTest {
    private val probe = FakeBackgroundWorkProbe()

    private fun blocked(vararg reasons: String) = mapOf("verdict" to "blocked", "reasons" to reasons.toList())

    @Test
    fun aHealthyProbeStaysHealthyButRecordsThatItRan() = runTest {
        val service = diagnostics(probe)

        val status = service.refresh()

        assertEquals(BackgroundWorkVerdict.OK, status.verdict)
        assertTrue(status.reasons.isEmpty())
        assertTrue(status.probed)
        assertEquals("ok", status.describe())
    }

    @Test
    fun bindingDownloadActivityPerformsTheColdStartProbe() = runTest {
        probe.signals = blocked("background_restricted")
        val service = diagnostics(probe)
        val source = { activity() }

        service.bindActivitySource(source)
        runCurrent()

        assertEquals(1, probe.calls.count { it == "getBackgroundWorkSignals" })
        assertTrue(service.status.value.isBlocked)
        service.unbindActivitySource(source)
        service.close()
    }

    @Test
    fun unsupportedDevicesNeitherObserveNorProbe() = runTest {
        val service = diagnostics(probe, supported = false)
        val source = { activity() }

        service.bindActivitySource(source)
        runCurrent()

        assertFalse(service.isSupported)
        assertTrue(probe.calls.isEmpty())
        assertFalse(service.status.value.probed)
        service.close()
    }

    @Test
    fun parsesABlockedVerdictWithItsReasonsInOrder() = runTest {
        probe.signals = mapOf(
            "verdict" to "blocked",
            "reasons" to listOf("background_restricted", "standby_restricted"),
            "standbyBucket" to 45,
            "ignoringBatteryOptimizations" to false,
        )
        val service = diagnostics(probe)

        val status = service.refresh()

        assertEquals(BackgroundWorkVerdict.BLOCKED, status.verdict)
        assertEquals(listOf(BackgroundWorkReason.BACKGROUND_RESTRICTED, BackgroundWorkReason.STANDBY_RESTRICTED), status.reasons)
        assertEquals(45, status.standbyBucket)
        assertEquals(BackgroundWorkReason.BACKGROUND_RESTRICTED, status.primaryReason)
    }

    @Test
    fun aBlockedVerdictWithNoRecognizableReasonIsNotTrusted() = runTest {
        probe.signals = blocked("some_future_reason")
        val service = diagnostics(probe)

        val status = service.refresh()

        assertEquals(BackgroundWorkVerdict.OK, status.verdict)
        assertTrue(status.reasons.isEmpty())
    }

    @Test
    fun refusesAnOemUnknownReasonArrivingFromTheReader() = runTest {
        probe.signals = blocked("oem_unknown")
        val service = diagnostics(probe)

        val status = service.refresh()

        assertTrue(status.reasons.isEmpty())
        assertEquals(BackgroundWorkVerdict.OK, status.verdict)
    }

    @Test
    fun dataSaverAloneIsDegradedNotBlocked() = runTest {
        probe.signals = mapOf("verdict" to "degraded", "reasons" to listOf("data_saver"))
        val service = diagnostics(probe)

        val status = service.refresh()

        assertEquals(BackgroundWorkVerdict.DEGRADED, status.verdict)
        assertFalse(status.isBlocked)
        assertFalse(status.isHealthy)
    }

    @Test
    fun concurrentRefreshesCoalesceIntoASinglePlatformCall() = runTest {
        val gate = CompletableDeferred<Map<String, Any?>>()
        probe.gate = gate
        val service = diagnostics(probe)

        val refreshes = List(3) { async { service.refresh() } }
        runCurrent()
        gate.complete(probe.signals)
        refreshes.awaitAll()

        assertEquals(1, probe.calls.count { it == "getBackgroundWorkSignals" })
    }

    @Test
    fun aMissingReaderNeverProducesAWarningAndStopsAsking() = runTest {
        probe.missing = true
        val service = diagnostics(probe)

        val first = service.refresh()
        val second = service.refresh()

        assertEquals(BackgroundWorkVerdict.OK, first.verdict)
        assertFalse(first.probed)
        assertFalse(second.probed)
        assertEquals(1, probe.calls.size)
    }

    @Test
    fun anInFlightProbeCompletingAfterClosingIsIgnored() = runTest {
        val gate = CompletableDeferred<Map<String, Any?>>()
        probe.gate = gate
        val service = diagnostics(probe)

        val refresh = async { service.refresh() }
        runCurrent()
        service.close()
        gate.complete(blocked("background_restricted"))

        refresh.await()
        assertFalse(service.status.value.probed)
    }

    @Test
    fun aConfirmedStallSurvivesAProbeThatReportsEverythingIsFine() = runTest {
        val detector = DownloadStallDetector(observationsToConfirm = 1, minimumBackgroundGap = Duration.ZERO)
        val service = diagnostics(probe, stallDetector = detector)
        val at = Instant.parse("2026-01-01T00:00:00Z")
        detector.onPaused(activity(downloadedBytes = 0), at)
        detector.evaluate(detector.captureResumed(activity(downloadedBytes = 0), at + 1.hours), true)
        assertTrue(detector.isStalled)

        val status = service.refresh()

        assertEquals(BackgroundWorkVerdict.BLOCKED, status.verdict)
        assertEquals(listOf(BackgroundWorkReason.OEM_UNKNOWN), status.reasons)
    }

    @Test
    fun clearingStallEvidenceDropsTheReasonAndProbesAgain() = runTest {
        val detector = DownloadStallDetector(observationsToConfirm = 1, minimumBackgroundGap = Duration.ZERO)
        val service = diagnostics(probe, stallDetector = detector)
        val at = Instant.parse("2026-01-01T00:00:00Z")
        detector.onPaused(activity(downloadedBytes = 0), at)
        detector.evaluate(detector.captureResumed(activity(downloadedBytes = 0), at + 1.hours), true)
        service.refresh()
        assertTrue(service.status.value.isBlocked)

        service.clearStallEvidence()

        assertTrue(service.status.value.reasons.isEmpty())
        assertEquals(BackgroundWorkVerdict.OK, service.status.value.verdict)
        assertFalse(detector.isStalled)
        assertEquals(2, probe.calls.count { it == "getBackgroundWorkSignals" })
    }

    @Test
    fun openingSettingsForwardsTheTargetIdTheReaderExpects() = runTest {
        val service = diagnostics(probe)

        val opened = service.openSettings(BackgroundSettingsTarget.NOTIFICATION_CHANNEL)

        assertTrue(opened)
        assertEquals(listOf("notification_channel"), probe.openedTargets)
    }

    @Test
    fun returningToTheForegroundScoresTheSnapshotCapturedAtThatMoment() = runTest {
        val detector = DownloadStallDetector(observationsToConfirm = 1, minimumBackgroundGap = Duration.ZERO)
        val networkGate = CompletableDeferred<Boolean>()
        val clock = MutableClock(Instant.parse("2026-01-01T00:00:00Z"))
        var current = activity(downloadedBytes = 1000)
        val foreground = MutableStateFlow(true)
        val service = diagnostics(probe, stallDetector = detector, networkProbe = { networkGate.await() }, clock = clock, foreground = foreground)
        val source = { current }
        service.bindActivitySource(source)
        runCurrent()

        foreground.value = false
        runCurrent()
        clock.now += 5.minutes
        foreground.value = true
        runCurrent()
        current = activity(downloadedBytes = 5L * 1024 * 1024)
        networkGate.complete(true)
        runCurrent()

        assertTrue(detector.isStalled, "progress after resume must not be credited to the background window")
        assertTrue(BackgroundWorkReason.OEM_UNKNOWN in service.status.value.reasons)
        service.unbindActivitySource(source)
        service.close()
    }

    @Test
    fun publishesOnlyWhenTheStatusActuallyChanges() = runTest {
        probe.signals = blocked("background_restricted")
        val service = diagnostics(probe)
        val seen = mutableListOf<BackgroundWorkStatus>()
        backgroundScope.launch { service.status.collect { seen += it } }
        runCurrent()

        service.refresh()
        runCurrent()
        service.refresh()
        runCurrent()

        assertEquals(1, seen.size - 1)
    }
}
