package com.edde746.plezy.playback.report

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.servers.RecordingTrackers
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateNotifier
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class SameFileSiblingsTest {
    private val notifier = WatchStateNotifier()
    private val trackers = RecordingTrackers()

    private fun episode(id: String, watched: Boolean = false) =
        testItem(id = id, kind = MediaKind.EPISODE).copy(viewCount = if (watched) 1 else 0)

    @Test
    fun marksEachUnwatchedSiblingOnTheServerAndTheTrackers() = runTest {
        val backend = ReportingBackend()
        val recorder = NotifierRecorder(this, notifier)

        markSameFileSiblingsWatched(listOf(episode("2"), episode("3", watched = true), episode("4")), backend, notifier, trackers)
        runCurrent()

        assertEquals(listOf("2", "4"), backend.watched)
        assertEquals(listOf("2" to true, "4" to true), trackers.marks)
        assertEquals(listOf("2", "4"), recorder.events.filter { it.changeType == WatchStateChangeType.WATCHED }.map { it.itemId })
    }

    @Test
    fun aBackendThatMarksOnTheStopGetsNoExplicitMarkForSiblings() = runTest {
        val backend = ReportingBackend(backend = BackendKind.JELLYFIN).apply { marksWatchedOnPlaybackStopped = true }
        val recorder = NotifierRecorder(this, notifier)

        markSameFileSiblingsWatched(listOf(episode("2")), backend, notifier, trackers)
        runCurrent()

        assertEquals(emptyList(), backend.watched)
        assertEquals(listOf("2" to true), trackers.marks)
        assertEquals(1, recorder.events.count { it.changeType == WatchStateChangeType.WATCHED })
    }
}
