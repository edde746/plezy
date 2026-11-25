package com.edde746.plezy.playback.report

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaPartTimeline
import com.edde746.plezy.playback.players.ExternalPlaybackResult
import com.edde746.plezy.servers.RecordingTrackers
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateNotifier
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class ExternalPlaybackReportTest {
    private val notifier = WatchStateNotifier()
    private val trackers = RecordingTrackers()
    private val queue = RecordingOfflineQueue()

    private fun item(durationMs: Long? = null) = testItem(id = "item-1", durationMs = durationMs)

    private suspend fun TestScope.report(
        result: ExternalPlaybackResult,
        backend: ReportingBackend?,
        durationMs: Long? = null,
        partTimeline: MediaPartTimeline? = null,
        isLaunchCurrent: () -> Boolean = { true },
    ) {
        reportExternalPlayback(
            result = result,
            item = item(durationMs),
            backend = backend,
            notifier = notifier,
            trackers = trackers,
            scope = backgroundScope,
            offlineQueue = queue,
            partTimeline = partTimeline,
            isLaunchCurrent = isLaunchCurrent,
        )
        runCurrent()
    }

    private fun ReportingBackend.calls(kind: ReportKind) = attempts.filter { it.kind == kind }.map { it.positionMs to it.durationMs }

    @Test
    fun preservesANullDurationAndStillStopsAfterAStartFailure() = runTest {
        val backend = ReportingBackend().apply { onReport = { if (it.kind == ReportKind.STARTED) throw IllegalStateException("start failed") } }

        report(ExternalPlaybackResult(positionMs = 5000, durationMs = null), backend)

        assertEquals(listOf(5000L to null), backend.calls(ReportKind.STARTED))
        assertEquals(listOf(5000L to null), backend.calls(ReportKind.STOPPED))
        assertEquals("DirectPlay", backend.attempts.first().playMethod)
    }

    @Test
    fun queuesAnUnknownDurationResumeWhenNoClientIsAvailable() = runTest {
        report(ExternalPlaybackResult(positionMs = 5000, durationMs = null), backend = null)

        assertEquals(listOf("srv:item-1@5000/null"), queue.queued)
    }

    @Test
    fun aFailedStopIsQueuedOffline() = runTest {
        val backend = ReportingBackend().apply { onReport = { if (it.kind == ReportKind.STOPPED) throw IllegalStateException("stop failed") } }

        report(ExternalPlaybackResult(positionMs = 5000, durationMs = 100000), backend, durationMs = 100000)

        assertEquals(listOf("srv:item-1@5000/100000"), queue.queued)
        assertEquals(emptyList(), backend.watched)
    }

    @Test
    fun emitsTheExactClientCacheScope() = runTest {
        val backend = ReportingBackend(scopeId = "srv/profile-a")
        val recorder = NotifierRecorder(this, notifier)

        report(ExternalPlaybackResult(positionMs = 5000, durationMs = 100000), backend, durationMs = 100000)

        val progress = recorder.events.filter { it.itemId == "item-1" && it.changeType == WatchStateChangeType.PROGRESS_UPDATE }
        assertEquals(listOf("srv/profile-a"), progress.map { it.cacheServerId })
    }

    @Test
    fun ignoresAMissingPositionWithoutExplicitCompletion() = runTest {
        val backend = ReportingBackend()

        report(ExternalPlaybackResult(positionMs = null, durationMs = 100000), backend, durationMs = 100000)

        assertEquals(emptyList(), backend.attempts)
    }

    @Test
    fun anErrorReportsNothing() = runTest {
        val backend = ReportingBackend()

        report(ExternalPlaybackResult(positionMs = 50000, durationMs = 100000, error = true), backend, durationMs = 100000)

        assertEquals(emptyList(), backend.attempts)
        assertEquals(emptyList(), queue.queued)
    }

    @Test
    fun aReplacedLaunchReportsNothing() = runTest {
        val backend = ReportingBackend()

        report(ExternalPlaybackResult(positionMs = 50000, durationMs = 100000), backend, durationMs = 100000, isLaunchCurrent = { false })

        assertEquals(emptyList(), backend.attempts)
    }

    @Test
    fun reportsTheFullDurationForExplicitCompletion() = runTest {
        val backend = ReportingBackend()

        report(ExternalPlaybackResult(positionMs = null, durationMs = 100000, completed = true), backend, durationMs = 100000)

        assertEquals(listOf(100000L to 100000L), backend.calls(ReportKind.STARTED))
        assertEquals(listOf(100000L to 100000L), backend.calls(ReportKind.STOPPED))
        assertEquals(listOf("item-1"), backend.watched)
        assertEquals(listOf("item-1" to true), trackers.marks)
    }

    @Test
    fun midVideoSavesThePositionWithoutMarkingWatched() = runTest {
        val backend = ReportingBackend()
        val recorder = NotifierRecorder(this, notifier)

        report(ExternalPlaybackResult(positionMs = 600000, durationMs = 2400000), backend, durationMs = 2400000)

        assertEquals(listOf(600000L to 2400000L), backend.calls(ReportKind.STOPPED))
        assertEquals(emptyList(), backend.watched)
        assertEquals(emptyList(), trackers.marks)
        assertEquals(listOf(600000L), recorder.events.filter { it.changeType == WatchStateChangeType.PROGRESS_UPDATE }.map { it.viewOffset })
    }

    @Test
    fun completionOnJellyfinMarksWatchedViaTheStopReportNotMarkWatched() = runTest {
        val backend = ReportingBackend(backend = BackendKind.JELLYFIN).apply { marksWatchedOnPlaybackStopped = true }

        report(ExternalPlaybackResult(positionMs = null, durationMs = 100000, completed = true), backend, durationMs = 100000)

        // The stopped report at the full duration marks it played on the server; markWatched would double-scrobble.
        assertEquals(listOf(100000L to 100000L), backend.calls(ReportKind.STOPPED))
        assertEquals(emptyList(), backend.watched)
    }

    // A stacked item: a 50 and a 40 minute file.

    private val fileOneMs = 3000000L
    private val itemMs = 5400000L

    private fun timeline(currentIndex: Int) =
        MediaPartTimeline.fromParts(listOf(MediaPart(id = "11", durationMs = fileOneMs), MediaPart(id = "12", durationMs = 2400000)), currentIndex)!!

    @Test
    fun playingOutTheFirstFileLeavesTheItemAtTheSecondNotWatched() = runTest {
        val backend = ReportingBackend()

        report(ExternalPlaybackResult(positionMs = null, durationMs = fileOneMs, completed = true), backend, durationMs = itemMs, partTimeline = timeline(0))

        assertEquals(listOf(fileOneMs to itemMs), backend.calls(ReportKind.STOPPED))
        assertEquals(emptyList(), backend.watched)
    }

    @Test
    fun theSecondFileReportsOnTheItemClockAndFinishingItFinishesTheItem() = runTest {
        val backend = ReportingBackend()

        report(ExternalPlaybackResult(positionMs = 600000, durationMs = 2400000), backend, durationMs = itemMs, partTimeline = timeline(1))
        assertEquals(fileOneMs + 600000 to itemMs, backend.calls(ReportKind.STOPPED).last())
        assertEquals(emptyList(), backend.watched)

        report(ExternalPlaybackResult(positionMs = null, durationMs = 2400000, completed = true), backend, durationMs = itemMs, partTimeline = timeline(1))
        assertEquals(itemMs to itemMs, backend.calls(ReportKind.STOPPED).last())
        assertEquals(listOf("item-1"), backend.watched)
    }
}
