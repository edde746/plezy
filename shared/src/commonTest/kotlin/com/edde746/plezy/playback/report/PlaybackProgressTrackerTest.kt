package com.edde746.plezy.playback.report

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackSessionTerminatedException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaAudioTrack
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.playback.tracks.NativeAudioTrack
import com.edde746.plezy.playback.tracks.NativeSubtitleTrack
import com.edde746.plezy.playback.tracks.NativeTracks
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateNotifier
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class PlaybackProgressTrackerTest {
    /** A player whose state the test sets. */
    private class FakePlayer(
        var position: Duration = Duration.ZERO,
        var duration: Duration = Duration.ZERO,
        var playing: Boolean = true,
        var tracks: NativeTracks = NativeTracks(),
    ) {
        fun progress() = PlayerProgress(position, duration, isActive = playing, tracks = tracks)
    }

    private val notifier = WatchStateNotifier()

    private fun TestScope.tracker(
        backend: MediaBackend?,
        player: FakePlayer,
        item: MediaItem = testItem(),
        isOffline: Boolean = false,
        offlineQueue: OfflineProgressQueue? = null,
        queueOnOnlineFailure: Boolean = false,
        playSessionId: String? = null,
        mediaInfo: MediaSourceInfo? = null,
        rememberTrackSelections: () -> Boolean = { true },
        onScrobbled: (suspend () -> Unit)? = null,
        onPausedKeepalive: (suspend () -> Unit)? = null,
        canReportPlayback: () -> Boolean = { true },
        hasRenderedPlayback: (() -> Boolean)? = null,
        subtitleOffIsDeliberate: () -> Boolean = { true },
        burnedSubtitleStreamIndex: () -> Int? = { null },
        updateInterval: Duration = 10.seconds,
    ) = PlaybackProgressTracker(
        backend = backend,
        item = item,
        player = player::progress,
        scope = backgroundScope,
        notifier = notifier,
        isOffline = isOffline,
        offlineQueue = offlineQueue,
        queueOnOnlineFailure = queueOnOnlineFailure,
        playSessionId = playSessionId,
        mediaInfo = mediaInfo,
        rememberTrackSelections = rememberTrackSelections,
        onScrobbled = onScrobbled,
        onPausedKeepalive = onPausedKeepalive,
        canReportPlayback = canReportPlayback,
        hasRenderedPlayback = hasRenderedPlayback,
        subtitleOffIsDeliberate = subtitleOffIsDeliberate,
        burnedSubtitleStreamIndex = burnedSubtitleStreamIndex,
        updateInterval = updateInterval,
    )

    private fun player(positionS: Long, durationS: Long = 100) = FakePlayer(positionS.seconds, durationS.seconds)

    /** Jellyfin-style: the stopped report marks the item played, so the in-player path issues no explicit mark. */
    private fun stopMarksWatchedBackend() = ReportingBackend().apply { marksWatchedOnPlaybackStopped = true }

    /** Holds every started report until [gate] completes. */
    private fun delayedStartBackend(gate: CompletableDeferred<Unit>) =
        ReportingBackend().apply { onReport = { if (it.kind == ReportKind.STARTED) gate.await() } }

    /** Answers the progress report after [terminateNext] is set with the server ending the session. */
    private class Terminating {
        var terminateNext = false
        val backend = ReportingBackend().apply {
            onReport = { call ->
                if (call.kind == ReportKind.PROGRESS && terminateNext) {
                    terminateNext = false
                    throw PlaybackSessionTerminatedException(2006, "Admin terminated playback with reason: Go Away")
                }
            }
        }
    }

    private val jellyfinItem get() = testItem(backend = BackendKind.JELLYFIN)

    // Constructor.

    @Test
    fun offlineRequiresAnOfflineQueue() = runTest {
        assertFailsWith<IllegalArgumentException> { tracker(backend = null, player = FakePlayer(), isOffline = true) }
    }

    @Test
    fun onlineRequiresABackend() = runTest {
        assertFailsWith<IllegalArgumentException> { tracker(backend = null, player = FakePlayer(), isOffline = false) }
    }

    // Duration guard.

    @Test
    fun doesNotSendProgressWhenDurationIsZero() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, FakePlayer())

        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(emptyList(), backend.attempts)
        assertEquals(emptyList(), backend.watched)
    }

    // Playback readiness.

    @Test
    fun blocksNonTerminalReportsUntilPlaybackOutputIsReady() = runTest {
        val backend = ReportingBackend()
        var ready = false
        val tracker = tracker(backend, player(5), canReportPlayback = { ready })

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        assertEquals(emptyList(), backend.attempts)
        tracker.sendProgress(PlaybackReportState.PAUSED)
        runCurrent()
        assertEquals(emptyList(), backend.attempts)

        ready = true
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        assertEquals(listOf("playing"), backend.states)
    }

    @Test
    fun stoppedBeforeRenderedOutputTerminatesAtKnownProgressWithoutScrobbling() = runTest {
        val backend = ReportingBackend()
        val player = player(99)
        val tracker = tracker(backend, player, item = testItem(viewOffsetMs = 12000), canReportPlayback = { false }, hasRenderedPlayback = { false })

        tracker.sendProgress(PlaybackReportState.STOPPED, positionOverride = player.duration)

        assertEquals(listOf("stopped" to 12000L), backend.reports.map { it.state to it.positionMs })
        assertEquals(emptyList(), backend.watched)
    }

    @Test
    fun fatalStopUsesTheLastReportablePositionInsteadOfTheAdvancingNativeClock() = runTest {
        val backend = ReportingBackend()
        val player = player(50)
        var canReport = true
        val tracker = tracker(backend, player, canReportPlayback = { canReport }, hasRenderedPlayback = { true })

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        canReport = false
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(listOf(50000L to "playing", 50000L to "stopped"), backend.reports.map { it.positionMs to it.state })
        assertEquals(emptyList(), backend.watched)
    }

    // Online.

    @Test
    fun stoppedAwaitsTheUnderlyingCallAndReportsCorrectArgs() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(30))

        tracker.sendProgress(PlaybackReportState.STOPPED)

        val call = backend.reports.single()
        assertEquals("42", call.itemId)
        assertEquals(30000L, call.positionMs)
        assertEquals("stopped", call.state)
        assertEquals(100000L, call.durationMs)
    }

    @Test
    fun stoppedCanOverrideStalePlayerPositionForCompletion() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(12))

        tracker.sendProgress(PlaybackReportState.STOPPED, positionOverride = 100.seconds)

        assertEquals(100000L, backend.reports.single().positionMs)
        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun playingFiresAndForgetsButEventuallyReports() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(5))

        tracker.sendProgress(PlaybackReportState.PLAYING)
        assertEquals(emptyList(), backend.reports)
        runCurrent()

        assertEquals(listOf("playing"), backend.states)
    }

    @Test
    fun forwardsPlaySessionIdToStartedProgressAndStoppedReports() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(5), playSessionId = "play-session-1")

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(listOf("playing", "playing", "stopped"), backend.states)
        assertEquals(List(3) { "play-session-1" }, backend.reports.map { it.playSessionId })
    }

    @Test
    fun coalescesConcurrentStartReportsWhileTheFirstStartIsInFlight() = runTest {
        val gate = CompletableDeferred<Unit>()
        val backend = delayedStartBackend(gate)
        val tracker = tracker(backend, player(5))

        tracker.sendProgress(PlaybackReportState.PLAYING)
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        assertEquals(emptyList(), backend.reports)

        gate.complete(Unit)
        runCurrent()

        assertEquals(listOf("playing"), backend.states)
    }

    @Test
    fun ordersStoppedAfterAnInFlightStartReport() = runTest {
        val gate = CompletableDeferred<Unit>()
        val backend = delayedStartBackend(gate)
        val tracker = tracker(backend, player(5))

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        val stop = async { tracker.sendProgress(PlaybackReportState.STOPPED) }
        runCurrent()
        assertEquals(emptyList(), backend.reports)

        gate.complete(Unit)
        stop.await()

        assertEquals(listOf("playing", "stopped"), backend.states)
    }

    @Test
    fun doesNotSendQueuedProgressAfterTerminalStoppedState() = runTest {
        val gate = CompletableDeferred<Unit>()
        val backend = delayedStartBackend(gate)
        val tracker = tracker(backend, player(5))

        tracker.sendProgress(PlaybackReportState.PLAYING)
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        val stop = async { tracker.sendProgress(PlaybackReportState.STOPPED) }
        runCurrent()
        gate.complete(Unit)
        stop.await()

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        assertEquals(listOf("playing", "stopped"), backend.states)
    }

    @Test
    fun coalescesConcurrentStoppedReportsIntoOneTerminalStop() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(5))
        val recorder = NotifierRecorder(this, notifier)

        val first = async { tracker.sendStoppedProgressOnce() }
        val second = async { tracker.sendStoppedProgressOnce() }
        first.await()
        second.await()
        runCurrent()

        assertEquals(listOf("stopped"), backend.states)
        assertEquals(1, recorder.events.count { it.itemId == "42" && it.changeType == WatchStateChangeType.PROGRESS_UPDATE })
    }

    @Test
    fun concurrentStoppedReportsSendOneStop() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(5))
        val recorder = NotifierRecorder(this, notifier)

        val first = async { tracker.sendProgress(PlaybackReportState.STOPPED) }
        val second = async { tracker.sendProgress(PlaybackReportState.STOPPED) }
        first.await()
        second.await()
        runCurrent()

        assertEquals(listOf("stopped"), backend.states)
        assertEquals(1, recorder.events.count { it.changeType == WatchStateChangeType.PROGRESS_UPDATE })
    }

    @Test
    fun allowsALaterStoppedReportToRetryAfterFinalStopFails() = runTest {
        val backend = ReportingBackend().apply { failNext = RuntimeException("network blip") }
        val tracker = tracker(backend, player(5))

        tracker.sendProgress(PlaybackReportState.STOPPED)
        assertEquals(emptyList(), backend.reports)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        assertEquals(emptyList(), backend.reports)

        tracker.sendProgress(PlaybackReportState.STOPPED)
        assertEquals(listOf("stopped"), backend.states)
    }

    @Test
    fun stoppedReportDeliveredGatesTheRetryAndOverridesSurviveAResetPlayer() = runTest {
        val backend = ReportingBackend().apply { failNext = RuntimeException("connect timed out") }
        val player = player(5)
        val tracker = tracker(backend, player)

        tracker.sendStoppedProgressOnce(positionOverride = 5.seconds)
        assertFalse(tracker.stoppedReportDelivered, "a transport failure is not delivery")
        assertEquals(emptyList(), backend.reports)

        // The retry runs after the engine was released, when its state reads zero: the report rides the overrides.
        player.position = Duration.ZERO
        player.duration = Duration.ZERO
        tracker.sendProgress(PlaybackReportState.STOPPED, positionOverride = 5.seconds, durationOverride = 100.seconds)

        assertTrue(tracker.stoppedReportDelivered)
        assertEquals(listOf(Triple("stopped", 5000L, 100000L)), backend.reports.map { Triple(it.state, it.positionMs, it.durationMs) })
    }

    @Test
    fun mapsCurrentPlayerTracksToServerStreamIndexesForProgressReports() = runTest {
        val backend = ReportingBackend()
        val selectedAudio = NativeAudioTrack(id = "audio_1", language = "jpn")
        val player = player(5).apply {
            tracks = NativeTracks(
                audio = listOf(NativeAudioTrack(id = "audio_0", language = "eng"), selectedAudio),
                subtitle = listOf(NativeSubtitleTrack(id = "text_0", language = "eng")),
                selectedAudio = selectedAudio,
                selectedSubtitle = NativeSubtitleTrack.OFF,
            )
        }
        val mediaInfo = MediaSourceInfo(
            videoUrl = "",
            audioTracks = listOf(MediaAudioTrack(id = 1, languageCode = "eng", selected = false), MediaAudioTrack(id = 2, languageCode = "jpn", selected = true)),
            subtitleTracks = listOf(MediaSubtitleTrack(id = 3, languageCode = "eng", selected = false, forced = false)),
            chapters = emptyList(),
            mediaSourceId = "source-1",
        )
        val tracker = tracker(backend, player, mediaInfo = mediaInfo)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        val progress = backend.reports[1]
        assertEquals("source-1", progress.mediaSourceId)
        assertEquals(2, progress.audioStreamIndex)
        assertEquals(-1, progress.subtitleStreamIndex)
    }

    @Test
    fun jellyfinReportsTheSelectedSubtitleByIdentityNotCatalogPosition() = runTest {
        val backend = ReportingBackend()
        val audio = NativeAudioTrack(id = "1", language = "jpn")
        // The engine lists the embedded track first and the sidecar after it; Jellyfin lists its external file first.
        val embeddedJpn = NativeSubtitleTrack(id = "1", language = "jpn", codec = "ass")
        val sidecarEng = NativeSubtitleTrack(
            id = "2",
            language = "eng",
            codec = "subrip",
            isExternal = true,
            uri = "https://jf.example/Videos/42/source-1/Subtitles/3/0/Stream.srt",
        )
        val tracks = NativeTracks(audio = listOf(audio), subtitle = listOf(embeddedJpn, sidecarEng), selectedAudio = audio, selectedSubtitle = embeddedJpn)
        val player = player(5).apply { this.tracks = tracks }
        val mediaInfo = MediaSourceInfo(
            videoUrl = "",
            audioTracks = listOf(MediaAudioTrack(id = 1, languageCode = "jpn", selected = true)),
            subtitleTracks = listOf(
                MediaSubtitleTrack(
                    id = 3, languageCode = "eng", codec = "srt", selected = false, forced = false, external = true,
                    key = "/Videos/42/source-1/Subtitles/3/0/Stream.srt",
                ),
                MediaSubtitleTrack(id = 2, languageCode = "jpn", codec = "ass", selected = false, forced = false),
            ),
            chapters = emptyList(),
            mediaSourceId = "source-1",
        )
        val tracker = tracker(backend, player, item = jellyfinItem, mediaInfo = mediaInfo)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        // By position the embedded pick would have reported the external row (3).
        assertEquals(2, backend.reports.single().subtitleStreamIndex)

        player.tracks = tracks.copy(selectedSubtitle = sidecarEng)
        tracker.sendProgress(PlaybackReportState.STOPPED)
        assertEquals(3, backend.reports.last().subtitleStreamIndex)
    }

    @Test
    fun aBurnedInSubtitleIsReportedAsItsSourceStreamNotAsOff() = runTest {
        val backend = ReportingBackend()
        val audio = NativeAudioTrack(id = "1", language = "jpn")
        // The transcode paints the subtitle into the picture: no engine track.
        val player = player(5).apply {
            tracks = NativeTracks(audio = listOf(audio), selectedAudio = audio, selectedSubtitle = NativeSubtitleTrack.OFF)
        }
        val mediaInfo = MediaSourceInfo(
            videoUrl = "",
            audioTracks = listOf(MediaAudioTrack(id = 1, languageCode = "jpn", selected = true)),
            subtitleTracks = listOf(MediaSubtitleTrack(id = 3, languageCode = "eng", codec = "pgssub", selected = true, forced = false)),
            chapters = emptyList(),
            mediaSourceId = "source-1",
        )
        val tracker = tracker(backend, player, item = jellyfinItem, mediaInfo = mediaInfo, burnedSubtitleStreamIndex = { 3 })

        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(3, backend.reports.single().subtitleStreamIndex)
    }

    @Test
    fun jellyfinReportsSelectedSourceAudioWhenPlayerExposesASingleOutputTrack() = runTest {
        val backend = ReportingBackend()
        val outputAudio = NativeAudioTrack(id = "audio_0", language = "jpn")
        val player = player(5).apply {
            tracks = NativeTracks(
                audio = listOf(outputAudio),
                subtitle = listOf(NativeSubtitleTrack(id = "text_0", language = "eng")),
                selectedAudio = outputAudio,
                selectedSubtitle = NativeSubtitleTrack.OFF,
            )
        }
        val mediaInfo = MediaSourceInfo(
            videoUrl = "",
            audioTracks = listOf(
                MediaAudioTrack(id = 1, languageCode = "eng", selected = false),
                MediaAudioTrack(id = 4, languageCode = "jpn", selected = true, external = true),
            ),
            subtitleTracks = listOf(MediaSubtitleTrack(id = 3, languageCode = "eng", selected = false, forced = false)),
            chapters = emptyList(),
            mediaSourceId = "source-1",
        )
        val tracker = tracker(backend, player, item = jellyfinItem, mediaInfo = mediaInfo)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        val progress = backend.reports[1]
        assertEquals("source-1", progress.mediaSourceId)
        assertEquals(4, progress.audioStreamIndex)
        assertEquals(-1, progress.subtitleStreamIndex)
    }

    private fun twoAudioSubtitlesOff(): Pair<FakePlayer, MediaSourceInfo> {
        val selectedAudio = NativeAudioTrack(id = "audio_1", language = "jpn")
        val player = player(5).apply {
            tracks = NativeTracks(
                audio = listOf(NativeAudioTrack(id = "audio_0", language = "eng"), selectedAudio),
                subtitle = listOf(NativeSubtitleTrack(id = "text_0", language = "eng")),
                selectedAudio = selectedAudio,
                selectedSubtitle = NativeSubtitleTrack.OFF,
            )
        }
        val mediaInfo = MediaSourceInfo(
            videoUrl = "",
            audioTracks = listOf(MediaAudioTrack(id = 1, languageCode = "eng", selected = false), MediaAudioTrack(id = 2, languageCode = "jpn", selected = true)),
            subtitleTracks = listOf(MediaSubtitleTrack(id = 3, languageCode = "eng", selected = false, forced = false)),
            chapters = emptyList(),
            mediaSourceId = "source-1",
        )
        return player to mediaInfo
    }

    @Test
    fun anOffThatFellOutOfADeclinedCarryIsNotPersistedAsMinusOne() = runTest {
        val backend = ReportingBackend()
        val (player, mediaInfo) = twoAudioSubtitlesOff()
        val tracker = tracker(backend, player, mediaInfo = mediaInfo, subtitleOffIsDeliberate = { false })

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        val progress = backend.reports[1]
        // Withheld: an explicit -1 would come back as this item's default.
        assertNull(progress.subtitleStreamIndex)
        assertEquals(2, progress.audioStreamIndex)
    }

    private fun selectedPair(): Pair<FakePlayer, MediaSourceInfo> {
        val selectedAudio = NativeAudioTrack(id = "audio_1", language = "jpn")
        val selectedSubtitle = NativeSubtitleTrack(id = "text_0", language = "eng")
        val player = player(5).apply {
            tracks = NativeTracks(audio = listOf(selectedAudio), subtitle = listOf(selectedSubtitle), selectedAudio = selectedAudio, selectedSubtitle = selectedSubtitle)
        }
        val mediaInfo = MediaSourceInfo(
            videoUrl = "",
            audioTracks = listOf(MediaAudioTrack(id = 2, languageCode = "jpn", selected = true)),
            subtitleTracks = listOf(MediaSubtitleTrack(id = 3, languageCode = "eng", selected = true, forced = false)),
            chapters = emptyList(),
            mediaSourceId = "source-1",
        )
        return player to mediaInfo
    }

    @Test
    fun stoppedReportsCarryTheEngineStreamSelectionSoALatePickStillPersists() = runTest {
        val backend = ReportingBackend()
        val (player, mediaInfo) = selectedPair()
        val tracker = tracker(backend, player, mediaInfo = mediaInfo)

        // No progress report ever ran: a pick within the last interval has only the stop left to ride.
        tracker.sendProgress(PlaybackReportState.STOPPED)

        val stopped = backend.reports.single()
        assertEquals("source-1", stopped.mediaSourceId)
        assertEquals(2, stopped.audioStreamIndex)
        assertEquals(3, stopped.subtitleStreamIndex)
    }

    @Test
    fun stoppedReportsDoNotPersistADeclinedOffAsMinusOne() = runTest {
        val backend = ReportingBackend()
        val selectedAudio = NativeAudioTrack(id = "audio_1", language = "jpn")
        val player = player(5).apply {
            tracks = NativeTracks(
                audio = listOf(selectedAudio),
                subtitle = listOf(NativeSubtitleTrack(id = "text_0", language = "eng")),
                selectedAudio = selectedAudio,
                selectedSubtitle = NativeSubtitleTrack.OFF,
            )
        }
        val mediaInfo = MediaSourceInfo(
            videoUrl = "",
            audioTracks = listOf(MediaAudioTrack(id = 2, languageCode = "jpn", selected = true)),
            subtitleTracks = listOf(MediaSubtitleTrack(id = 3, languageCode = "eng", selected = false, forced = false)),
            chapters = emptyList(),
            mediaSourceId = "source-1",
        )
        val tracker = tracker(backend, player, mediaInfo = mediaInfo, subtitleOffIsDeliberate = { false })

        tracker.sendProgress(PlaybackReportState.STOPPED)

        val stopped = backend.reports.single()
        assertNull(stopped.subtitleStreamIndex)
        assertEquals(2, stopped.audioStreamIndex)
    }

    @Test
    fun stoppedReportsWithholdStreamIndexesWhenRememberingIsOff() = runTest {
        val backend = ReportingBackend()
        val (player, mediaInfo) = selectedPair()
        val tracker = tracker(backend, player, mediaInfo = mediaInfo, rememberTrackSelections = { false })

        tracker.sendProgress(PlaybackReportState.STOPPED)

        val stopped = backend.reports.single()
        assertEquals("source-1", stopped.mediaSourceId)
        assertNull(stopped.audioStreamIndex)
        assertNull(stopped.subtitleStreamIndex)
    }

    @Test
    fun anUnreadableRememberSettingReportsTheSelectedStreams() = runTest {
        val backend = ReportingBackend()
        val (player, mediaInfo) = selectedPair()
        val tracker = tracker(backend, player, mediaInfo = mediaInfo, rememberTrackSelections = { throw IllegalStateException("settings not loaded") })

        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(2, backend.reports.single().audioStreamIndex)
        assertEquals(3, backend.reports.single().subtitleStreamIndex)
    }

    // Threshold gating.

    @Test
    fun doesNotScrobbleBelowTheThreshold() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(89))

        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(emptyList(), backend.watched)
    }

    @Test
    fun aSessionWithNoObservableCrossingStillIssuesTheExplicitMark() = runTest {
        // A lone stopped report at 95 %: the server never held a sub-threshold offset this session, so won't mark it.
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(95))

        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun aBackendThatMarksWatchedOnStopSkipsTheExplicitServerMark() = runTest {
        val backend = stopMarksWatchedBackend()
        val tracker = tracker(backend, player(95))
        val recorder = NotifierRecorder(this, notifier)

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(emptyList(), backend.watched)
        assertEquals(1, recorder.events.count { it.itemId == "42" && it.changeType == WatchStateChangeType.WATCHED })
    }

    @Test
    fun respectsACustomServerThreshold() = runTest {
        val backend = ReportingBackend().apply { watchedThreshold = 0.8 }
        val tracker = tracker(backend, player(81))

        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun scrobbleIsIdempotentAcrossMultipleProgressCalls() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(95))

        tracker.sendProgress(PlaybackReportState.STOPPED)
        tracker.sendProgress(PlaybackReportState.STOPPED)
        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(1, backend.watched.size)
    }

    @Test
    fun aFailedExplicitMarkIsRetriedOnTheNextSessionEnd() = runTest {
        val backend = ReportingBackend().apply { failNextMark = RuntimeException("mark failed") }
        val tracker = tracker(backend, player(95))

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()
        assertEquals(1, backend.markAttempts)
        assertEquals(emptyList(), backend.watched)

        tracker.resumeAfterStoppedReport()
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()
        assertEquals(2, backend.markAttempts)
        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun onScrobbledFiresOnceAfterASuccessfulScrobble() = runTest {
        val backend = ReportingBackend()
        var hookCalls = 0
        val tracker = tracker(backend, player(95), onScrobbled = { hookCalls++ })

        tracker.sendProgress(PlaybackReportState.STOPPED)
        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(listOf("42"), backend.watched)
        assertEquals(1, hookCalls)
    }

    @Test
    fun onScrobbledIsNotInvokedBelowThreshold() = runTest {
        val backend = ReportingBackend()
        var hookCalls = 0
        val tracker = tracker(backend, player(89), onScrobbled = { hookCalls++ })

        tracker.sendProgress(PlaybackReportState.STOPPED)

        assertEquals(0, hookCalls)
    }

    @Test
    fun onScrobbledWaitsForTheExplicitMarkAndNeverRunsAheadOfIt() = runTest {
        // The hook marks same-file siblings with server writes: never while this item's own mark is pending.
        val backend = ReportingBackend()
        var hookCalls = 0
        val tracker = tracker(backend, player(95), onScrobbled = { hookCalls++ })

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        assertEquals(0, backend.markAttempts, "the mark waits for the session to end")
        assertEquals(0, hookCalls, "and the siblings wait for the mark")

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()
        assertEquals(listOf("42"), backend.watched)
        assertEquals(1, hookCalls)
    }

    @Test
    fun onScrobbledDoesNotRunWhenTheExplicitMarkFailsAndRunsOnTheRetry() = runTest {
        val backend = ReportingBackend().apply { failNextMark = RuntimeException("mark failed") }
        var hookCalls = 0
        val tracker = tracker(backend, player(95), onScrobbled = { hookCalls++ })

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()
        assertEquals(1, backend.markAttempts)
        assertEquals(emptyList(), backend.watched)
        assertEquals(0, hookCalls, "siblings must not be marked while the primary is not")

        tracker.resumeAfterStoppedReport()
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()
        assertEquals(listOf("42"), backend.watched)
        assertEquals(1, hookCalls)
    }

    @Test
    fun aThrowingOnScrobbledDoesNotResetTheScrobbleLatch() = runTest {
        val backend = ReportingBackend()
        var hookCalls = 0
        val tracker = tracker(backend, player(95), onScrobbled = {
            hookCalls++
            throw RuntimeException("sibling mark failed")
        })

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(1, backend.watched.size)
        assertEquals(1, hookCalls)
    }

    // Server-side crossing detection: both backends mark an item played from a crossing they see within one session.

    @Test
    fun aDeliveredCrossingMarksWatchedLocallyAndNeverIssuesTheExplicitMark() = runTest {
        val backend = ReportingBackend()
        val player = player(50)
        val tracker = tracker(backend, player)
        val recorder = NotifierRecorder(this, notifier)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        assertEquals(emptyList(), backend.watched, "the server saw the crossing and marked it itself")
        assertEquals(1, recorder.events.count { it.changeType == WatchStateChangeType.WATCHED }, "local watched state flips exactly once")
    }

    @Test
    fun aSessionThatBeginsPastTheThresholdMarksExplicitlyButOnlyOnceItEnds() = runTest {
        val backend = ReportingBackend()
        val player = player(95)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        assertEquals(emptyList(), backend.watched, "still live: a rewind could yet create a crossing")

        player.position = 100.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun theExplicitMarkCompletesWithTheStoppedReport() = runTest {
        val backend = ReportingBackend().apply { markGate = CompletableDeferred() }
        val tracker = tracker(backend, player(95))

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        val stop = async { tracker.sendStoppedProgressOnce() }
        runCurrent()
        assertEquals(1, backend.markAttempts)
        assertFalse(stop.isCompleted, "the stop waits for the mark it triggered")

        backend.markGate!!.complete(Unit)
        stop.await()
        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun aSessionThatBeginsPastTheThresholdThenRewindsAndReCrossesNeverMarksExplicitly() = runTest {
        val backend = ReportingBackend()
        val player = player(95)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 50.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 92.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 100.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(emptyList(), backend.watched, "the server saw the 50 % to 92 % crossing itself")
    }

    @Test
    fun aCrossingLandingOnTheStoppedReportSuppressesTheExplicitMark() = runTest {
        val backend = ReportingBackend()
        val player = player(50)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 100.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(emptyList(), backend.watched)
    }

    @Test
    fun aCrossingLandingOnAPausedReportSuppressesTheExplicitMark() = runTest {
        val backend = ReportingBackend()
        val player = player(50)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 92.seconds
        tracker.sendProgress(PlaybackReportState.PAUSED)
        runCurrent()

        assertEquals(emptyList(), backend.watched)
    }

    @Test
    fun onScrobbledStillFiresWhenTheExplicitMarkIsSuppressed() = runTest {
        val backend = ReportingBackend()
        val player = player(50)
        var hookCalls = 0
        val tracker = tracker(backend, player, onScrobbled = { hookCalls++ })

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        assertEquals(emptyList(), backend.watched)
        assertEquals(1, hookCalls, "same-file siblings are still marked")
    }

    @Test
    fun resumeAfterStoppedReportClearsTheCrossingStateForTheNextSession() = runTest {
        val backend = ReportingBackend()
        val player = player(40)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()
        assertEquals(emptyList(), backend.watched, "never crossed the threshold")

        tracker.resumeAfterStoppedReport()
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun aBelowThresholdReportDroppedDuringStartupDoesNotArmTheCrossing() = runTest {
        // The start at 95 % is in flight; a same-state 50 % heartbeat meanwhile is dropped. The server only saw 95 %.
        val gate = CompletableDeferred<Unit>()
        val backend = delayedStartBackend(gate)
        val player = player(95)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 50.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        gate.complete(Unit)
        runCurrent()
        assertEquals(listOf(95000L), backend.reports.map { it.positionMs }, "the 50 % snapshot was never sent")

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()
        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun aDroppedCrossingFollowedByASeekBackBelowTheThresholdMarksExplicitly() = runTest {
        val gate = CompletableDeferred<Unit>()
        val backend = delayedStartBackend(gate)
        val player = player(50)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        gate.complete(Unit)
        runCurrent()
        assertEquals(listOf(50000L), backend.reports.map { it.positionMs }, "the crossing snapshot was dropped")
        assertEquals(emptyList(), backend.watched, "the decision is deferred, not made")

        player.position = 50.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(listOf("42"), backend.watched, "the session ended with no crossing the server could see")
    }

    @Test
    fun aDroppedCrossingSettlesAsServerMarkedOnceALaterReportIsDelivered() = runTest {
        val gate = CompletableDeferred<Unit>()
        val backend = delayedStartBackend(gate)
        val player = player(50)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        gate.complete(Unit)
        runCurrent()
        assertEquals(emptyList(), backend.watched)

        player.position = 96.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 100.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(emptyList(), backend.watched, "the later delivery completed the crossing on the server")
    }

    @Test
    fun aReportAtPositionZeroDoesNotArmTheCrossing() = runTest {
        // Plex treats zero as the session's start: a 0 then 100 % session is not marked played by the server.
        val backend = ReportingBackend()
        val player = player(0)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 100.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(listOf("42"), backend.watched)
    }

    @Test
    fun aReportOneSecondInDoesArmTheCrossing() = runTest {
        val backend = ReportingBackend()
        val player = player(1)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 100.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(emptyList(), backend.watched)
    }

    // Offline.

    @Test
    fun queuesAProgressUpdateOffline() = runTest {
        val queue = RecordingOfflineQueue()
        val tracker = tracker(backend = null, player = player(12, 60), isOffline = true, offlineQueue = queue)

        tracker.sendProgress(PlaybackReportState.PLAYING)

        assertEquals(listOf("srv:42@12000/60000"), queue.queued)
    }

    @Test
    fun doesNotQueueOfflinePlayingProgressBeforePlaybackOutputIsReady() = runTest {
        val queue = RecordingOfflineQueue()
        var ready = false
        val tracker = tracker(backend = null, player = player(12, 60), isOffline = true, offlineQueue = queue, canReportPlayback = { ready })

        tracker.sendProgress(PlaybackReportState.PLAYING)
        assertEquals(emptyList(), queue.queued)

        ready = true
        tracker.sendProgress(PlaybackReportState.PLAYING)
        assertEquals(1, queue.queued.size)
    }

    @Test
    fun offlineWithoutServerIdQueuesNothing() = runTest {
        val queue = RecordingOfflineQueue()
        val tracker = tracker(backend = null, player = player(5, 60), item = testItem(serverId = null), isOffline = true, offlineQueue = queue)

        tracker.sendProgress(PlaybackReportState.PLAYING)

        assertEquals(emptyList(), queue.queued)
    }

    @Test
    fun onlineLocalPlaybackQueuesFallbackProgressWhenReportingFails() = runTest {
        val queue = RecordingOfflineQueue()
        val backend = ReportingBackend().apply { failNext = IllegalStateException("offline") }
        val tracker = tracker(backend, player(10), offlineQueue = queue, queueOnOnlineFailure = true)

        tracker.sendProgress(PlaybackReportState.STOPPED, positionOverride = 100.seconds)

        assertEquals(listOf("srv:42@100000/100000"), queue.queued)
    }

    @Test
    fun aFailedPlayingReportIsQueuedForADownloadPlayedOnline() = runTest {
        val queue = RecordingOfflineQueue()
        val backend = ReportingBackend().apply { failNext = IllegalStateException("offline") }
        val tracker = tracker(backend, player(10), offlineQueue = queue, queueOnOnlineFailure = true)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        assertEquals(listOf("srv:42@10000/100000"), queue.queued)
    }

    // Watch-state events.

    @Test
    fun emitsAProgressEventWhenStoppedPastPositionZero() = runTest {
        val backend = ReportingBackend(scopeId = "srv/profile-a")
        val tracker = tracker(backend, player(30))
        val recorder = NotifierRecorder(this, notifier)

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        val progress = recorder.events.filter { it.itemId == "42" && it.changeType == WatchStateChangeType.PROGRESS_UPDATE }
        assertEquals(30000L, progress.first().viewOffset)
        assertEquals("srv/profile-a", progress.first().cacheServerId)
    }

    @Test
    fun doesNotEmitOnStoppedAtPositionZero() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(0), item = testItem(id = "no-watch"))
        val recorder = NotifierRecorder(this, notifier)

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(0, recorder.events.count { it.changeType == WatchStateChangeType.PROGRESS_UPDATE })
    }

    @Test
    fun doesNotEmitAProgressEventWhenScrobbleAlreadyFired() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(95), item = testItem(id = "scrobbler"))
        val recorder = NotifierRecorder(this, notifier)

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(1, recorder.events.count { it.changeType == WatchStateChangeType.WATCHED })
        assertEquals(0, recorder.events.count { it.changeType == WatchStateChangeType.PROGRESS_UPDATE })
    }

    @Test
    fun progressEventsFollowThe30SecondDeltaAndAMediaBrowserStartIsNotAcknowledged() = runTest {
        val backend = ReportingBackend(backend = BackendKind.JELLYFIN)
        val player = player(10, 1000)
        val tracker = tracker(backend, player, item = jellyfinItem)
        val recorder = NotifierRecorder(this, notifier)

        tracker.sendProgress(PlaybackReportState.PLAYING) // started: position not kept
        runCurrent()
        player.position = 20.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING) // within 30 s, but the first acknowledged one
        runCurrent()
        player.position = 30.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING) // within 30 s of an acknowledged one
        runCurrent()
        player.position = 50.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING) // 30 s on
        runCurrent()

        assertEquals(
            listOf(10000L to false, 20000L to true, 50000L to true),
            recorder.events.filter { it.changeType == WatchStateChangeType.PROGRESS_UPDATE }.map { it.viewOffset to it.serverAcknowledged },
        )
    }

    // Periodic tracking.

    @Test
    fun reportsImmediatelyFollowsCadenceAndResumesPlayingAfterPause() = runTest {
        val backend = ReportingBackend()
        val player = player(5)
        var pausedKeepalives = 0
        val tracker = tracker(backend, player, updateInterval = 1.seconds, onPausedKeepalive = { pausedKeepalives++ })

        tracker.startTracking()
        runCurrent()
        assertEquals(listOf("playing"), backend.states)

        advanceTimeBy(999.milliseconds)
        runCurrent()
        assertEquals(1, backend.reports.size)

        advanceTimeBy(1.milliseconds)
        runCurrent()
        assertEquals(listOf("playing", "playing"), backend.states)

        player.playing = false
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(listOf("playing", "playing", "paused"), backend.states)
        assertEquals(1, pausedKeepalives)

        player.playing = true
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(listOf("playing", "playing", "paused", "playing"), backend.states)
        assertEquals(1, pausedKeepalives)

        tracker.dispose()
    }

    @Test
    fun aPausedKeepaliveTheServerHasNotAnsweredIsNotStackedByLaterTicks() = runTest {
        val backend = ReportingBackend()
        val player = player(5).apply { playing = false }
        val pings = mutableListOf<CompletableDeferred<Unit>>()
        val tracker = tracker(backend, player, updateInterval = 1.seconds, onPausedKeepalive = {
            val ping = CompletableDeferred<Unit>()
            pings += ping
            ping.await()
        })

        tracker.startTracking()
        advanceTimeBy(3.seconds)
        runCurrent()
        assertEquals(1, pings.size, "the first ping still waits on the server")

        pings.single().complete(Unit)
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(2, pings.size, "the next tick pings again once the server answered")

        pings.last().complete(Unit)
        tracker.dispose()
    }

    @Test
    fun startTrackingOverridesOnlyTheInitialReportWithTheCallerSuppliedStartState() = runTest {
        // At bind time the player can still carry the previous item's playhead (a gapless music advance).
        val backend = ReportingBackend()
        val player = FakePlayer(7.minutes, 7.minutes)
        val tracker = tracker(backend, player, updateInterval = 1.seconds)

        tracker.startTracking(initialPosition = Duration.ZERO, initialDuration = 3.minutes)
        runCurrent()
        assertEquals(0L, backend.reports.single().positionMs)
        assertEquals(3.minutes.inWholeMilliseconds, backend.reports.single().durationMs)
        assertEquals(emptyList(), backend.watched)

        player.position = 30.seconds
        player.duration = 3.minutes
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(30000L, backend.reports.last().positionMs)
        assertEquals(3.minutes.inWholeMilliseconds, backend.reports.last().durationMs)

        tracker.dispose()
    }

    @Test
    fun coalescesTimerTicksWhileAProgressReportIsInFlight() = runTest {
        val gates = mutableListOf<CompletableDeferred<Unit>>()
        val progressAttempts = mutableListOf<Long>()
        val backend = ReportingBackend().apply {
            onReport = { call ->
                if (call.kind == ReportKind.PROGRESS) {
                    progressAttempts += call.positionMs
                    val gate = CompletableDeferred<Unit>()
                    gates += gate
                    gate.await()
                }
            }
        }
        val player = player(5)
        val tracker = tracker(backend, player, updateInterval = 1.seconds)

        tracker.startTracking()
        runCurrent()
        assertEquals(1, backend.reports.size)

        player.position = 10.seconds
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(listOf(10000L), progressAttempts)

        player.position = 20.seconds
        advanceTimeBy(1.seconds)
        runCurrent()
        player.position = 30.seconds
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(listOf(10000L), progressAttempts)

        gates.first().complete(Unit)
        runCurrent()
        assertEquals(listOf(10000L, 30000L), progressAttempts)

        gates.last().complete(Unit)
        runCurrent()
        assertEquals(listOf(5000L, 10000L, 30000L), backend.reports.map { it.positionMs })

        tracker.dispose()
    }

    @Test
    fun backsOffByOneThenTwoTicksAndResumesAfterSuccess() = runTest {
        var failuresRemaining = 2
        var progressAttempts = 0
        val backend = ReportingBackend().apply {
            onReport = { call ->
                if (call.kind == ReportKind.PROGRESS) {
                    progressAttempts++
                    if (failuresRemaining > 0) {
                        failuresRemaining--
                        throw IllegalStateException("planned progress failure")
                    }
                }
            }
        }
        val tracker = tracker(backend, player(5), updateInterval = 1.seconds)

        tracker.startTracking()
        runCurrent()
        assertEquals(1, backend.reports.size)

        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(1, progressAttempts)

        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(1, progressAttempts)

        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(2, progressAttempts)

        advanceTimeBy(2.seconds)
        runCurrent()
        assertEquals(2, progressAttempts)

        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(3, progressAttempts)
        assertEquals(2, backend.reports.size)

        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(4, progressAttempts)
        assertEquals(3, backend.reports.size)

        tracker.dispose()
    }

    @Test
    fun backoffCapsAtSixTicks() = runTest {
        var progressAttempts = 0
        val backend = ReportingBackend().apply {
            onReport = { call ->
                if (call.kind == ReportKind.PROGRESS) {
                    progressAttempts++
                    throw IllegalStateException("server down")
                }
            }
        }
        val tracker = tracker(backend, player(5), updateInterval = 1.seconds)

        tracker.startTracking()
        runCurrent()
        // Failures 1..4 skip 1, 2, 4 and then 6 (not 8) ticks: attempts land at 1, 3, 6, 11 and 18 s.
        val attemptTimes = mutableListOf<Long>()
        repeat(18) { second ->
            advanceTimeBy(1.seconds)
            runCurrent()
            if (progressAttempts > attemptTimes.size) attemptTimes += (second + 1).toLong()
        }
        assertEquals(listOf(1L, 3L, 6L, 11L, 18L), attemptTimes)

        tracker.dispose()
    }

    @Test
    fun disposeCancelsFuturePeriodicReports() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(5), updateInterval = 1.seconds)

        tracker.startTracking()
        runCurrent()
        assertEquals(1, backend.reports.size)

        tracker.dispose()
        advanceTimeBy(1.minutes)
        runCurrent()
        assertEquals(1, backend.reports.size)
    }

    // Track changes.

    @Test
    fun aTrackChangeReportsRightAwaySoTheServerLearnsTheSelection() = runTest {
        val backend = ReportingBackend()
        val player = player(5)
        val tracker = tracker(backend, player, updateInterval = 1.minutes)

        tracker.startTracking()
        runCurrent()
        player.position = 7.seconds
        tracker.onTracksChanged()
        runCurrent()
        player.playing = false
        player.position = 8.seconds
        tracker.onTracksChanged()
        runCurrent()

        assertEquals(listOf("playing" to 5000L, "playing" to 7000L, "paused" to 8000L), backend.reports.map { it.state to it.positionMs })
        tracker.dispose()
    }

    @Test
    fun aTrackChangeWhilePausedBeforeAnySessionReportsNothing() = runTest {
        val backend = ReportingBackend()
        val player = player(5).apply { playing = false }
        val tracker = tracker(backend, player, updateInterval = 1.minutes)

        tracker.startTracking()
        tracker.onTracksChanged()
        runCurrent()

        assertEquals(emptyList(), backend.attempts)
        tracker.dispose()
    }

    // Server-side session termination.

    @Test
    fun terminatedPausedSessionSendsOneFinalStopGoesSilentAndReopensOnResume() = runTest {
        val server = Terminating()
        val player = player(5)
        var pausedKeepalives = 0
        val tracker = tracker(server.backend, player, updateInterval = 1.seconds, onPausedKeepalive = { pausedKeepalives++ })

        tracker.startTracking()
        runCurrent()
        player.playing = false
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(listOf("playing", "paused"), server.backend.states)
        assertEquals(1, pausedKeepalives)

        // The server answers the next paused heartbeat with a termination: one stop at the playhead, no retry.
        server.terminateNext = true
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(listOf("playing", "paused", "stopped"), server.backend.states)
        assertEquals(5000L, server.backend.reports.last().positionMs)

        // Still paused: no heartbeats re-registering the session, no keepalives (the count includes the detection
        // tick, whose ping went before the termination was known).
        advanceTimeBy(5.seconds)
        runCurrent()
        assertEquals(3, server.backend.reports.size)
        assertEquals(2, pausedKeepalives)

        // Unpause: a new session opens with a started report right away (no failure backoff).
        player.playing = true
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(
            listOf(ReportKind.STARTED, ReportKind.PROGRESS, ReportKind.PROGRESS, ReportKind.STOPPED, ReportKind.STARTED),
            server.backend.attempts.map { it.kind },
        )

        // The new session pauses normally: heartbeats and keepalives resume.
        player.playing = false
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals("paused", server.backend.reports.last().state)
        assertEquals(3, pausedKeepalives)

        tracker.dispose()
    }

    @Test
    fun terminatedWhilePlayingBufferedPlaybackKeepsTheSessionClosedUntilTheViewerResumes() = runTest {
        val server = Terminating()
        val player = player(5)
        val tracker = tracker(server.backend, player, updateInterval = 1.seconds)

        tracker.startTracking()
        runCurrent()

        server.terminateNext = true
        advanceTimeBy(1.seconds)
        runCurrent()
        assertTrue(tracker.stoppedByServer)

        // Buffered playback carries on; its heartbeats must not re-open the session the admin ended.
        player.position = 30.seconds
        advanceTimeBy(5.seconds)
        runCurrent()
        assertEquals(listOf(ReportKind.STARTED, ReportKind.PROGRESS, ReportKind.STOPPED), server.backend.attempts.map { it.kind })
        assertTrue(tracker.stoppedByServer)

        // A pause and resume is a person at the screen: a new session opens.
        player.playing = false
        advanceTimeBy(1.seconds)
        runCurrent()
        player.playing = true
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(ReportKind.STARTED, server.backend.attempts.last().kind)
        assertFalse(tracker.stoppedByServer)

        tracker.dispose()
    }

    @Test
    fun theTerminalReportAfterATerminationRecordsWherePlaybackEndedAndMarksTheItemWatched() = runTest {
        val server = Terminating()
        val player = player(50)
        val tracker = tracker(server.backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        server.terminateNext = true
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()

        // Buffered playback runs to the end with nobody touching it.
        player.position = 100.seconds
        tracker.sendProgress(PlaybackReportState.PLAYING)
        tracker.sendStoppedProgressOnce(positionOverride = 100.seconds)
        runCurrent()

        assertEquals(
            listOf("playing" to 50000L, "stopped" to 50000L, "stopped" to 100000L),
            server.backend.reports.map { it.state to it.positionMs },
        )
        assertEquals(listOf("42"), server.backend.watched)
        // Finishing the item is not a viewer action: the next item still waits for a person.
        assertTrue(tracker.stoppedByServer)
    }

    @Test
    fun terminationIsNotAReportFailureNothingIsQueuedForOfflineReplay() = runTest {
        val queue = RecordingOfflineQueue()
        val server = Terminating()
        val tracker = tracker(server.backend, player(10), offlineQueue = queue, queueOnOnlineFailure = true)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        server.terminateNext = true
        tracker.sendProgress(PlaybackReportState.PAUSED)
        runCurrent()

        assertEquals(listOf("playing", "stopped"), server.backend.states)
        assertEquals(emptyList(), queue.queued)
    }

    // Stopped once and re-opening.

    @Test
    fun resumeAfterStoppedReportOpensAFreshReportingSession() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(5))

        tracker.sendStoppedProgressOnce()
        tracker.sendStoppedProgressOnce()
        assertEquals(listOf("stopped"), backend.states)

        tracker.resumeAfterStoppedReport()
        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        tracker.sendStoppedProgressOnce()

        assertEquals(listOf("stopped", "playing", "stopped"), backend.states)
    }

    @Test
    fun aStoppedReportEndsTheSessionAClockThatRunsPastTheEndReportsNothing() = runTest {
        val backend = ReportingBackend()
        val player = player(50)
        val tracker = tracker(backend, player, updateInterval = 1.seconds)

        tracker.startTracking()
        runCurrent()
        assertEquals(listOf("playing"), backend.states)

        backgroundScope.launch { tracker.sendStoppedProgressOnce(positionOverride = 100.seconds) }
        runCurrent()

        player.position = 160.seconds
        advanceTimeBy(10.seconds)
        runCurrent()

        assertEquals(listOf("playing", "stopped"), backend.states)
        assertEquals(100000L, backend.reports.last().positionMs)

        tracker.dispose()
    }

    @Test
    fun redeliversAnUndeliveredStopEvery10SecondsUpTo5TimesWhileSuspended() = runTest {
        var failures = 3
        val backend = ReportingBackend().apply {
            onReport = { call ->
                if (call.kind == ReportKind.STOPPED && failures > 0) {
                    failures--
                    throw IllegalStateException("connect timed out")
                }
            }
        }
        val tracker = tracker(backend, player(5))
        tracker.sendStoppedProgressOnce(positionOverride = 5.seconds)
        assertFalse(tracker.stoppedReportDelivered)

        val redelivery = async { tracker.redeliverStoppedReport(5.seconds, 100.seconds) { true } }
        advanceTimeBy(9.seconds)
        runCurrent()
        assertEquals(1, backend.attempts.size)
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(2, backend.attempts.size)
        redelivery.await()

        assertTrue(tracker.stoppedReportDelivered)
        assertEquals(4, backend.attempts.size, "two more failures, then delivered: no further attempt")
        assertEquals(listOf(5000L to 100000L), backend.reports.map { it.positionMs to it.durationMs })
    }

    @Test
    fun redeliveryStopsAfter5AttemptsOrOnceNoLongerSuspended() = runTest {
        val backend = ReportingBackend().apply {
            onReport = { call -> if (call.kind == ReportKind.STOPPED) throw IllegalStateException("connect timed out") }
        }
        val tracker = tracker(backend, player(5))
        tracker.sendStoppedProgressOnce()

        tracker.redeliverStoppedReport(5.seconds, 100.seconds) { true }
        assertEquals(1 + PlaybackProgressTracker.STOP_REPORT_MAX_RETRIES, backend.attempts.size)

        var suspended = true
        val redelivery = async { tracker.redeliverStoppedReport(5.seconds, 100.seconds) { suspended } }
        advanceTimeBy(10.seconds)
        runCurrent()
        suspended = false
        redelivery.await()
        assertEquals(2 + PlaybackProgressTracker.STOP_REPORT_MAX_RETRIES, backend.attempts.size)
    }

    // Lifecycle.

    @Test
    fun startAndStopTrackingIsACleanNoOpForAnInactivePlayer() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, FakePlayer(playing = false))

        tracker.startTracking()
        tracker.stopTracking()
        runCurrent()

        assertEquals(emptyList(), backend.attempts)
    }

    @Test
    fun startTrackingIsIdempotent() = runTest {
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(5), updateInterval = 1.seconds)

        tracker.startTracking()
        tracker.startTracking()
        runCurrent()
        assertEquals(listOf("playing"), backend.states)

        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(listOf("playing", "playing"), backend.states)

        tracker.dispose()
    }

    @Test
    fun disposeIsIdempotent() = runTest {
        val tracker = tracker(ReportingBackend(), FakePlayer(playing = false))
        tracker.dispose()
        tracker.dispose()
    }

    // Watched-patch promotion: a crossing's unacknowledged patch is promoted once the server took the watch.

    @Test
    fun aDeliveredStopPromotesTheCrossingOnABackendThatMarksOnStop() = runTest {
        val recorder = NotifierRecorder(this, notifier)
        val backend = stopMarksWatchedBackend()
        val tracker = tracker(backend, player(95))

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(1, recorder.promotions.size)
        assertEquals(emptyList(), backend.watched)
    }

    @Test
    fun aMediaBrowserStopForASessionThatNeverOpenedDoesNotPromote() = runTest {
        // Jellyfin drops a stop for a session it never opened: the watch it would have recorded is still owed.
        val recorder = NotifierRecorder(this, notifier)
        val tracker = tracker(stopMarksWatchedBackend(), player(95), item = jellyfinItem)

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(1, recorder.events.count { it.changeType == WatchStateChangeType.WATCHED })
        assertEquals(emptyList(), recorder.promotions)
    }

    @Test
    fun aMediaBrowserStopIntoAnOpenedSessionPromotes() = runTest {
        val recorder = NotifierRecorder(this, notifier)
        val player = player(10)
        val tracker = tracker(stopMarksWatchedBackend(), player, item = jellyfinItem)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(1, recorder.promotions.size)
    }

    @Test
    fun aServerObservedCrossingPromotesWithoutAnExplicitMark() = runTest {
        val recorder = NotifierRecorder(this, notifier)
        val backend = ReportingBackend()
        val player = player(10)
        val tracker = tracker(backend, player)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(1, recorder.promotions.size)
        assertEquals(emptyList(), backend.watched)
    }

    @Test
    fun theExplicitMarkPathPromotesExactlyOnce() = runTest {
        val recorder = NotifierRecorder(this, notifier)
        val backend = ReportingBackend()
        val tracker = tracker(backend, player(95))

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(listOf("42"), backend.watched)
        assertEquals(1, recorder.promotions.size)
    }

    @Test
    fun aFailedExplicitMarkLeavesThePatchOwed() = runTest {
        val recorder = NotifierRecorder(this, notifier)
        val backend = ReportingBackend().apply { failNextMark = RuntimeException("mark failed") }
        val tracker = tracker(backend, player(95))

        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()

        assertEquals(1, recorder.events.count { it.changeType == WatchStateChangeType.WATCHED })
        assertEquals(emptyList(), recorder.promotions)
    }

    @Test
    fun aReArmedSessionDoesNotPromoteOffThePreviousStop() = runTest {
        val recorder = NotifierRecorder(this, notifier)
        val player = player(10)
        val tracker = tracker(stopMarksWatchedBackend(), player, item = jellyfinItem)

        tracker.sendProgress(PlaybackReportState.PLAYING)
        runCurrent()
        player.position = 95.seconds
        tracker.sendProgress(PlaybackReportState.STOPPED)
        runCurrent()
        assertEquals(1, recorder.promotions.size)

        // A new server session must earn its own delivered stop.
        tracker.resumeAfterStoppedReport()
        runCurrent()
        assertEquals(1, recorder.promotions.size)
    }

    @Test
    fun thePlayMethodIsTheServersElseTranscodeOrDirectPlay() {
        assertEquals("DirectStream", PlayMethod.of("DirectStream", transcoding = true))
        assertEquals("Transcode", PlayMethod.of(null, transcoding = true))
        assertEquals("DirectPlay", PlayMethod.of(null, transcoding = false))
    }
}
