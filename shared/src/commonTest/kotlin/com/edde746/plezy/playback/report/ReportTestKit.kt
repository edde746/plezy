package com.edde746.plezy.playback.report

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.WatchPatchPromotion
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.servers.WatchStateNotifier
import kotlin.time.Duration
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.yield

internal enum class ReportKind { STARTED, PROGRESS, STOPPED }

/** One report call as the server got it; [state] is the timeline state it stands for (a start plays). */
internal data class ReportCall(
    val kind: ReportKind,
    val itemId: String,
    val positionMs: Long,
    val durationMs: Long?,
    val isPaused: Boolean = false,
    val playSessionId: String? = null,
    val playMethod: String? = null,
    val mediaSourceId: String? = null,
    val audioStreamIndex: Int? = null,
    val subtitleStreamIndex: Int? = null,
) {
    val state: String
        get() = when (kind) {
            ReportKind.STARTED -> "playing"
            ReportKind.PROGRESS -> if (isPaused) "paused" else "playing"
            ReportKind.STOPPED -> "stopped"
        }
}

/**
 * A backend that records report calls with every argument. Each call first yields (a network call never answers on
 * the spot), is appended to [attempts], runs [onReport] (a test suspends or throws there), then throws [failNext] once
 * if set, and only then lands in [reports]. [markWatched] counts [markAttempts], waits on [markGate], throws
 * [failNextMark] once if set, and lands in [watched].
 */
internal class ReportingBackend(
    serverId: String = "srv",
    backend: BackendKind = BackendKind.PLEX,
    scopeId: String? = null,
) : FakeMediaBackend(serverId, backend, scopeId = scopeId) {
    val attempts = mutableListOf<ReportCall>()
    val reports = mutableListOf<ReportCall>()
    val watched = mutableListOf<String>()
    var failNext: Exception? = null
    var onReport: suspend (ReportCall) -> Unit = {}
    var markAttempts = 0
    var markGate: CompletableDeferred<Unit>? = null
    var failNextMark: Exception? = null

    init {
        markWatchedHandler = { item ->
            markAttempts++
            markGate?.await()
            failNextMark?.let {
                failNextMark = null
                throw it
            }
            watched += item.id
        }
    }

    val states: List<String> get() = reports.map { it.state }

    override suspend fun reportPlaybackStarted(
        itemId: String, position: Duration, duration: Duration?, playSessionId: String?, playMethod: String?, liveStreamId: String?,
        mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?,
    ) = deliver(
        ReportCall(
            ReportKind.STARTED, itemId, position.inWholeMilliseconds, duration?.inWholeMilliseconds,
            playSessionId = playSessionId, playMethod = playMethod, mediaSourceId = mediaSourceId,
            audioStreamIndex = audioStreamIndex, subtitleStreamIndex = subtitleStreamIndex,
        ),
    )

    override suspend fun reportPlaybackProgress(
        itemId: String, position: Duration, duration: Duration, isPaused: Boolean, playSessionId: String?, playMethod: String?,
        liveStreamId: String?, mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?,
    ) = deliver(
        ReportCall(
            ReportKind.PROGRESS, itemId, position.inWholeMilliseconds, duration.inWholeMilliseconds, isPaused,
            playSessionId = playSessionId, playMethod = playMethod, mediaSourceId = mediaSourceId,
            audioStreamIndex = audioStreamIndex, subtitleStreamIndex = subtitleStreamIndex,
        ),
    )

    override suspend fun reportPlaybackStopped(
        itemId: String, position: Duration, duration: Duration?, playSessionId: String?, liveStreamId: String?, mediaSourceId: String?,
        audioStreamIndex: Int?, subtitleStreamIndex: Int?, report: PlaybackReportMetadata,
    ) = deliver(
        ReportCall(
            ReportKind.STOPPED, itemId, position.inWholeMilliseconds, duration?.inWholeMilliseconds,
            playSessionId = playSessionId, mediaSourceId = mediaSourceId,
            audioStreamIndex = audioStreamIndex, subtitleStreamIndex = subtitleStreamIndex,
        ),
    )

    private suspend fun deliver(call: ReportCall) {
        yield()
        attempts += call
        onReport(call)
        failNext?.let {
            failNext = null
            throw it
        }
        reports += call
    }
}

/** An offline queue that records `serverId:itemId@offset/duration`. */
internal class RecordingOfflineQueue : OfflineProgressQueue {
    val queued = mutableListOf<String>()
    override suspend fun queueProgress(serverId: ServerId, itemId: String, viewOffsetMs: Long, durationMs: Long?) {
        queued += "$serverId:$itemId@$viewOffsetMs/$durationMs"
    }
}

internal fun testItem(
    id: String = "42",
    backend: BackendKind = BackendKind.PLEX,
    serverId: String? = "srv",
    viewOffsetMs: Long? = null,
    durationMs: Long? = null,
    kind: MediaKind = MediaKind.MOVIE,
) = MediaItem(id = id, backend = backend, kind = kind, title = "Test Item", serverId = serverId, viewOffsetMs = viewOffsetMs, durationMs = durationMs)

/** Collects [notifier]'s events and promotions from now on. */
internal class NotifierRecorder(scope: TestScope, notifier: WatchStateNotifier) {
    val events = mutableListOf<WatchStateEvent>()
    val promotions = mutableListOf<WatchPatchPromotion>()

    init {
        val dispatcher = UnconfinedTestDispatcher(scope.testScheduler)
        scope.backgroundScope.launch(dispatcher) { notifier.events.collect { events += it } }
        scope.backgroundScope.launch(dispatcher) { notifier.promotions.collect { promotions += it } }
    }
}
