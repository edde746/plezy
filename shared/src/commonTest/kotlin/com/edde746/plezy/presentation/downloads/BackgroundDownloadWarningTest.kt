package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.data.testData
import com.edde746.plezy.downloads.BackgroundWorkDiagnosticsService
import com.edde746.plezy.downloads.BackgroundWorkProbe
import com.edde746.plezy.downloads.BackgroundWorkReason
import com.edde746.plezy.downloads.DownloadStallDetector
import com.edde746.plezy.downloads.FakeBackgroundWorkProbe
import com.edde746.plezy.downloads.activity
import com.edde746.plezy.downloads.diagnostics
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Instant
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

class BackgroundDownloadWarningTest {
    private val probe = FakeBackgroundWorkProbe()
    private val settings = testData().deviceSettings
    private val texts = T.downloads.backgroundWarning

    private fun blocked(reason: String) = mapOf("verdict" to "blocked", "reasons" to listOf(reason))

    private fun TestScope.warning(
        service: BackgroundWorkDiagnosticsService,
        permission: suspend () -> Unit = {},
        openUrl: suspend (String) -> Boolean = { true },
    ) = BackgroundDownloadWarning(service, settings, { permission() }, openUrl, backgroundScope)

    private suspend fun BackgroundDownloadWarning.awaitDialog() = state.first { it.dialog != null }.dialog!!

    @Test
    fun requestsTheNotificationPermissionBeforeProbingRestrictions() = runTest {
        val events = mutableListOf<String>()
        val recording = object : BackgroundWorkProbe by probe {
            override suspend fun backgroundWorkSignals(): Map<String, Any?>? {
                events += "probe"
                return probe.signals
            }
        }
        val warning = warning(diagnostics(recording), permission = { events += "permission" })

        assertTrue(warning.confirmBeforeDownload())
        assertEquals(listOf("permission", "probe"), events)
    }

    @Test
    fun downloadAnywayAcknowledgesTheWarningAndProceeds() = runTest {
        probe.signals = blocked("notifications_disabled")
        val warning = warning(diagnostics(probe))

        val result = async { warning.confirmBeforeDownload() }
        val dialog = warning.awaitDialog()
        assertEquals(texts.dialogTitle, dialog.title)
        assertEquals(texts.dialogDownloadAnyway, dialog.dismissLabel)
        warning.proceed()

        assertTrue(result.await())
        assertTrue(settings.value(AppSettings.backgroundDownloadWarningAck))
    }

    @Test
    fun theFixActionOpensSettingsAndCancelsTheDownload() = runTest {
        probe.signals = blocked("background_restricted")
        val warning = warning(diagnostics(probe))

        val result = async { warning.confirmBeforeDownload() }
        assertEquals(texts.dialogFixFirst, warning.awaitDialog().fixLabel)
        warning.fix()

        assertFalse(result.await())
        assertEquals(listOf("app_details"), probe.openedTargets)
    }

    @Test
    fun notificationDenialOpensAppNotificationSettingsWithoutNeedingAChannel() = runTest {
        probe.signals = blocked("notifications_disabled")
        val warning = warning(diagnostics(probe))

        val result = async { warning.confirmBeforeDownload() }
        warning.awaitDialog()
        warning.fix()

        assertFalse(result.await())
        assertEquals(listOf("app_notifications"), probe.openedTargets)
    }

    @Test
    fun openingTheOemRemedyClearsStaleEmpiricalEvidence() = runTest {
        val detector = DownloadStallDetector(observationsToConfirm = 1, minimumBackgroundGap = Duration.ZERO)
        val at = Instant.parse("2026-01-01T00:00:00Z")
        detector.onPaused(activity(), at)
        detector.evaluate(detector.captureResumed(activity(), at + 1.hours), true)
        val service = diagnostics(probe, stallDetector = detector)
        service.refresh()
        val warning = warning(service)

        warning.showDetails()
        assertEquals(texts.openSettings, warning.awaitDialog().fixLabel)
        warning.fix()
        warning.state.first { it.dialog == null }

        assertFalse(detector.isStalled)
        assertTrue(service.status.value.reasons.isEmpty())
    }

    @Test
    fun acknowledgedWarningsStillRequestThePermissionButSkipTheProbe() = runTest {
        settings.set(AppSettings.backgroundDownloadWarningAck, true)
        var permissionRequests = 0
        val warning = warning(diagnostics(probe), permission = { permissionRequests++ })

        assertTrue(warning.confirmBeforeDownload())
        assertEquals(1, permissionRequests)
        assertTrue(probe.calls.isEmpty())
    }

    @Test
    fun aBlockedStatusShowsTheBannerOnlyWhileDownloadsArePending() = runTest {
        probe.signals = blocked("background_restricted")
        val service = diagnostics(probe)
        val status = service.refresh()
        val warning = warning(service)

        assertEquals(texts.bannerBlocked, warning.banner(status, hasPendingDownloads = true)?.text)
        assertNull(warning.banner(status, hasPendingDownloads = false))
    }

    @Test
    fun dataSaverUsesTheDegradedBannerAndDialogCopy() = runTest {
        probe.signals = mapOf("verdict" to "degraded", "reasons" to listOf("data_saver"))
        val service = diagnostics(probe)
        val status = service.refresh()
        val warning = warning(service)

        val banner = assertNotNull(warning.banner(status, hasPendingDownloads = true))
        assertEquals(texts.bannerDegraded, banner.text)
        assertFalse(banner.blocked)

        warning.showDetails()
        val dialog = warning.awaitDialog()
        assertEquals(texts.sheetTitleDegraded, dialog.title)
        assertEquals(listOf(texts.reasonDataSaver), dialog.reasons)
    }

    @Test
    fun anUnavailableHelpLinkSaysSoAndCloseStillProceeds() = runTest {
        probe.signals = blocked("background_restricted")
        val service = diagnostics(probe)
        service.refresh()
        val warning = warning(service, openUrl = { false })

        warning.showDetails()
        warning.awaitDialog()
        warning.openHelp()

        assertEquals(texts.linkUnavailable, warning.state.first { it.message != null }.message)
        assertNotNull(warning.state.value.dialog)
        warning.proceed()
        assertNull(warning.state.value.dialog)
    }

    @Test
    fun unsupportedDevicesSkipBothWarningSurfaces() = runTest {
        probe.signals = blocked("background_restricted")
        var permissionRequests = 0
        val service = diagnostics(probe, supported = false)
        val warning = warning(service, permission = { permissionRequests++ })

        assertTrue(warning.confirmBeforeDownload())
        assertEquals(0, permissionRequests)
        assertTrue(probe.calls.isEmpty())
        val status = service.status.value.withReason(BackgroundWorkReason.BACKGROUND_RESTRICTED)
        assertNull(warning.banner(status, hasPendingDownloads = true))
    }

    @Test
    fun aRecheckProbesAgainAndPublishesTheNewVerdict() = runTest {
        val warning = warning(diagnostics(probe))
        assertTrue(warning.supported)
        assertFalse(warning.status.value.probed)

        assertTrue(warning.recheck().isHealthy)
        assertTrue(warning.status.value.probed)

        probe.signals = blocked("background_restricted")
        assertTrue(warning.recheck().isBlocked)
        assertTrue(warning.status.value.isBlocked)
        assertEquals(2, probe.calls.count { it == "getBackgroundWorkSignals" })
    }
}
