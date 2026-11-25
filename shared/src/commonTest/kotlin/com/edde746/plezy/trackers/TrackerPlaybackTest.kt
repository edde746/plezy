package com.edde746.plezy.trackers

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.trackers.TrackerService.MDBLIST
import com.edde746.plezy.trackers.TrackerService.MYANIMELIST
import com.edde746.plezy.trackers.TrackerService.SIMKL
import com.edde746.plezy.trackers.TrackerService.TRAKT
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds

/**
 * Playback as the trackers follow it: live reports to Trakt, Simkl and MDBList within each service's policy, the
 * watched mark at the media server's own threshold for the rest, one watch recorded once, and accounts pinned for the
 * playback's life. The fakes log a report as `scrobble <STATE> <percent>`.
 */
class TrackerPlaybackTest {
    private val fixtures = mutableListOf<TrackerFixture>()

    @AfterTest
    fun close() = fixtures.forEach { it.close() }

    private suspend fun TestScope.fixture(vararg services: TrackerService): TrackerFixture {
        val f = TrackerFixture(this, services = services.toList()).also { fixtures += it }
        f.settle()
        for (service in services) f.connect(service)
        return f
    }

    private val show = "tt0903747"
    private val episode = episodeItem(show, 1, 3)

    /** Seconds of a 100-second video: a position is its percentage. */
    private fun pct(position: Int) = at(position, 100)

    private fun TrackerFixture.startAtZero(item: MediaItem = episode) {
        observer.start(item, backend, pct(0))
        settle()
    }

    /** Moves to [target] in 5-second steps, which aren't seeks. */
    private fun TrackerFixture.moveTo(target: Int, from: Int = 0) {
        var position = from
        while (position < target) {
            position = minOf(position + 5, target)
            observer.onPosition(pct(position))
        }
        settle()
    }

    private fun TrackerFixture.stop(at: Int) {
        observer.onVideoStopped(pct(at))
        drain()
    }

    @Test
    fun startReportsTheResumeOffset() = runTest {
        val f = fixture(TRAKT)
        f.observer.start(episode, f.backend, at(600, 2000))
        f.settle()
        assertEquals(listOf("scrobble START 30"), f.calls(TRAKT))
        assertEquals(listOf(true), f.resolver.currentEpisode, "playback counts the episode it plays")
    }

    @Test
    fun pauseCheckpointsProgressAndResumeStartsAgain() = runTest {
        val f = fixture(TRAKT)
        f.startAtZero()
        f.moveTo(40)
        f.observer.onPlayingChanged(false, pct(40))
        f.observer.onPlayingChanged(true, pct(40))
        f.drain()
        assertEquals(listOf("scrobble START 0", "scrobble PAUSE 40", "scrobble START 40"), f.calls(TRAKT))
    }

    @Test
    fun aRepeatedStartWaitsForTheServicesResendThrottle() = runTest {
        val f = fixture(TRAKT, SIMKL)
        f.startAtZero()
        f.advance(5.seconds)
        f.observer.onPlayingChanged(true, pct(0))
        f.drain()
        assertEquals(listOf("scrobble START 0"), f.calls(TRAKT))
        assertEquals(listOf("scrobble START 0"), f.calls(SIMKL))
        // 25 s after the first: Simkl's 20 s window is over, Trakt's 30 s one isn't.
        f.advance(10.seconds)
        f.observer.onPlayingChanged(true, pct(0))
        f.drain()
        assertEquals(listOf("scrobble START 0"), f.calls(TRAKT))
        assertEquals(listOf("scrobble START 0", "scrobble START 0"), f.calls(SIMKL))
        f.advance(10.seconds)
        f.observer.onPlayingChanged(true, pct(0))
        f.drain()
        assertEquals(listOf("scrobble START 0", "scrobble START 0"), f.calls(TRAKT))
    }

    @Test
    fun seekCheckpointsAreThrottledAndIgnoredWhilePausedAndSimklGetsNone() = runTest {
        val f = fixture(TRAKT, MDBLIST, SIMKL)
        f.startAtZero()
        f.observer.onPosition(pct(4))
        f.observer.onPosition(pct(40))
        // Within 5 s of the last checkpoint.
        f.observer.onPosition(pct(70))
        f.advance(5.seconds)
        assertEquals(listOf("scrobble START 0", "scrobble SEEK 40"), f.calls(TRAKT))
        assertEquals(listOf("scrobble START 0", "scrobble SEEK 40"), f.calls(MDBLIST))

        f.observer.onPosition(pct(20))
        f.observer.onPlayingChanged(false, pct(20))
        f.advance(10.seconds)
        // Paused: a jump is no checkpoint.
        f.observer.onPosition(pct(80))
        f.drain()
        assertEquals(listOf("scrobble START 0", "scrobble SEEK 40", "scrobble SEEK 20", "scrobble PAUSE 20"), f.calls(TRAKT))
        assertEquals(listOf("scrobble START 0", "scrobble PAUSE 20"), f.calls(SIMKL))
    }

    @Test
    fun aStopReportsTheMeasuredProgressWithoutAHistoryWrite() = runTest {
        val f = fixture(TRAKT, SIMKL)
        f.startAtZero()
        f.moveTo(60)
        f.stop(60)
        assertEquals(listOf("scrobble START 0", "scrobble STOP 60"), f.calls(TRAKT))
        assertEquals(listOf("scrobble START 0", "scrobble STOP 60"), f.calls(SIMKL))
    }

    @Test
    fun thePlayersVideosGoToTheProfileActiveWhenEachStarts() = runTest {
        // Only the second profile has Trakt connected.
        val f = TrackerFixture(this, services = listOf(TRAKT)).also { fixtures += it }
        f.hub.accounts.connect("p2", TRAKT, TrackerSession("b0", "r0", FAR_FUTURE, "kai", 1))
        var active: String? = "p2"
        val player = f.hub.playback { active }
        player.start(episode, f.backend, pct(0))
        f.settle()
        active = f.profileId
        player.onVideoStopped(pct(60))
        f.drain()
        assertEquals(listOf("scrobble START 0", "scrobble STOP 60"), f.calls(TRAKT), "the video stays with its profile")

        player.start(episode, f.backend, pct(0))
        player.onVideoStopped(pct(60))
        active = null
        player.start(episode, f.backend, pct(0))
        player.onVideoStopped(pct(60))
        f.drain()
        assertEquals(2, f.calls(TRAKT).size, "nothing reaches the first profile's unconnected Trakt, or no profile")
    }

    @Test
    fun aWatchedStopIsReconciledByTheOwnerAndNobodyElseWritesIt() = runTest {
        val f = fixture(TRAKT, MYANIMELIST)
        f.resolver.animeTt[show] = 21
        f.startAtZero()
        // Past the server's 70 %: MAL marks it at the crossing, Trakt owns its own watch.
        f.moveTo(76)
        f.drain()
        assertEquals(listOf("watched 21@3"), f.calls(MYANIMELIST))
        f.stop(76)
        assertEquals(listOf("scrobble START 0", "scrobble STOP 76", "reconcile 76"), f.calls(TRAKT))
        assertEquals(listOf("watched 21@3"), f.calls(MYANIMELIST), "fired once")
    }

    @Test
    fun theThresholdIsTheServersNotTheTrackersDefault() = runTest {
        val f = fixture(MYANIMELIST)
        f.resolver.animeTt[show] = 101
        f.backend.watchedThreshold = 0.95
        f.startAtZero()
        f.moveTo(90)
        f.drain()
        assertEquals(emptyList(), f.calls(MYANIMELIST), "past 80 % but below the server's 95 %")
        f.moveTo(95, from = 90)
        f.moveTo(99, from = 95)
        f.drain()
        assertEquals(listOf("watched 101@3"), f.calls(MYANIMELIST))
    }

    @Test
    fun aStopBetweenTwoPositionsStillMarksTheThresholdTrackers() = runTest {
        val f = fixture(MYANIMELIST)
        f.resolver.animeTt[show] = 101
        f.startAtZero()
        f.moveTo(65)
        f.stop(72)
        assertEquals(listOf("watched 101@3"), f.calls(MYANIMELIST))
    }

    @Test
    fun realtimeTrackersAreLeftOutOfTheThresholdWrite() = runTest {
        val f = fixture(SIMKL)
        f.startAtZero()
        f.moveTo(95)
        f.drain()
        assertEquals(listOf("scrobble START 0"), f.calls(SIMKL))
    }

    @Test
    fun anUnconfirmedWatchedStopFallsBackToHistory() = runTest {
        val f = fixture(TRAKT)
        f.startAtZero()
        f.moveTo(85)
        f.tracker(TRAKT).failNext("scrobble", TrackerException.Api(TRAKT, 500))
        f.stop(85)
        assertEquals(listOf("scrobble START 0", "scrobble STOP 85", "watched $show:1:3"), f.calls(TRAKT))
    }

    @Test
    fun watchedSyncWorksWithLiveScrobblingOff() = runTest {
        val f = fixture(TRAKT)
        f.set(AppSettings.scrobble(TRAKT), false)
        f.startAtZero()
        f.moveTo(95)
        f.stop(95)
        assertEquals(listOf("watched $show:1:3"), f.calls(TRAKT))
    }

    @Test
    fun liveScrobblingNeverWritesHistoryWhenWatchedSyncIsOff() = runTest {
        val f = fixture(TRAKT)
        f.set(AppSettings.enableTraktWatchedSync, false)
        f.startAtZero()
        f.moveTo(95)
        f.stop(50)
        assertEquals(listOf("scrobble START 0", "scrobble STOP 50"), f.calls(TRAKT))
    }

    @Test
    fun bothTraktSwitchesOffSendNothing() = runTest {
        val f = fixture(TRAKT)
        f.set(AppSettings.scrobble(TRAKT), false)
        f.set(AppSettings.enableTraktWatchedSync, false)
        f.startAtZero()
        f.moveTo(95)
        f.stop(95)
        assertEquals(emptyList(), f.calls(TRAKT))
        assertEquals(emptyList(), f.resolver.calls, "nothing to write: the item isn't even resolved")
    }

    @Test
    fun scrobblingTurnedOffMidPlaybackStillRecordsTheWatchInHistory() = runTest {
        val f = fixture(TRAKT)
        f.startAtZero()
        f.moveTo(85)
        // The stop never goes out, so Trakt's own rule never ran: the watch goes to history.
        f.set(AppSettings.scrobble(TRAKT), false)
        f.stop(85)
        assertEquals(listOf("scrobble START 0", "watched $show:1:3"), f.calls(TRAKT))
    }

    @Test
    fun aLibraryFilteredOutPlaybackIsNotReported() = runTest {
        val f = fixture(TRAKT, SIMKL)
        f.set(AppSettings.trackerFilterIds(TRAKT), listOf("s1:anime"))
        f.startAtZero(episode.copy(serverId = "s1", libraryId = "anime"))
        f.stop(0)
        assertEquals(emptyList(), f.calls(TRAKT))
        assertEquals(listOf("scrobble START 0", "scrobble STOP 0"), f.calls(SIMKL))
    }

    @Test
    fun aRepeatedStateInsideTheDebounceIsSentOnce() = runTest {
        val f = fixture(SIMKL)
        f.startAtZero()
        f.advance(30.seconds)
        f.observer.onPlayingChanged(false, pct(0))
        f.observer.onPlayingChanged(false, pct(0))
        f.drain()
        assertEquals(listOf("scrobble START 0", "scrobble PAUSE 0"), f.calls(SIMKL))
    }

    @Test
    fun aSessionOpenedAtZeroIsStillClosed() = runTest {
        val f = fixture(SIMKL)
        f.startAtZero()
        f.stop(0)
        assertEquals(listOf("scrobble START 0", "scrobble STOP 0"), f.calls(SIMKL))
    }

    @Test
    fun aPauseOrStopWithoutAStartIsNotSent() = runTest {
        val f = fixture(SIMKL)
        // Opened paused, then rolled back before it ever played.
        f.observer.start(episode, f.backend, pct(10), playing = false)
        f.settle()
        f.observer.onPlayingChanged(false, pct(10))
        f.stop(10)
        // No ids: no session either.
        f.startAtZero(movieItem("unknown"))
        f.stop(40)
        assertEquals(emptyList(), f.calls(SIMKL))
    }

    @Test
    fun liveAndNonVideoItemsAreNotTracked() = runTest {
        val f = fixture(SIMKL)
        f.observer.onVideoStarted(episode, f.backend, pct(0), playing = true, live = true)
        f.settle()
        f.stop(90)
        f.startAtZero(MediaItem(id = "clip", backend = BackendKind.PLEX, kind = MediaKind.CLIP))
        f.stop(90)
        assertEquals(emptyList(), f.calls(SIMKL))
        assertEquals(emptyList(), f.resolver.calls)
    }

    @Test
    fun aFailingReportNeverEscapesAndTheStopStillGoesOut() = runTest {
        val f = fixture(SIMKL)
        f.tracker(SIMKL).failNext("scrobble", TrackerException.Api(SIMKL, 500))
        f.startAtZero()
        f.moveTo(40)
        f.stop(40)
        assertEquals(listOf("scrobble START 0", "scrobble STOP 40"), f.calls(SIMKL))
    }

    @Test
    fun aFailingIdLookupLeavesNothingToWriteFor() = runTest {
        val f = fixture(MYANIMELIST)
        f.resolver.animeTt[show] = 101
        f.startAtZero()
        f.resolver.failing += "tt2"
        // The next item's lookup fails: the previous item's playback doesn't live on.
        f.startAtZero(episodeItem("tt2", 1, 1))
        f.moveTo(95)
        f.stop(95)
        assertEquals(emptyList(), f.calls(MYANIMELIST))
    }

    @Test
    fun theResolverIsKeptAcrossEpisodesAndRebuiltForANewBackend() = runTest {
        val f = fixture(TRAKT)
        f.startAtZero(episodeItem(show, 1, 1))
        f.stop(10)
        f.startAtZero(episodeItem(show, 1, 2))
        f.stop(10)
        assertEquals(listOf(f.backend), f.resolverBackends.toList())
        // A reconnect replaces the client under the same server id: its playback still reports, through a new resolver.
        val reconnected = FakeMediaBackend("s1").apply { watchedThreshold = 0.7 }
        f.observer.start(episodeItem("tt2", 2, 1), reconnected, pct(0))
        f.settle()
        assertEquals(2, f.resolverBackends.size)
        assertTrue(f.resolverBackends.last() === reconnected)
        assertEquals("scrobble START 0", f.calls(TRAKT).last())
    }

    @Test
    fun aQueuedStopSurvivesTheNextItemStartingBehindABusyRequest() = runTest {
        val f = fixture(SIMKL)
        f.startAtZero()
        f.moveTo(30)
        f.advance(30.seconds)
        f.tracker(SIMKL).latency = 10.seconds
        f.observer.onPlayingChanged(false, pct(30))
        f.settle()
        f.observer.onVideoStopped(pct(30))
        f.observer.start(movieItem(), f.backend, pct(0))
        f.advance(60.seconds)
        assertEquals(listOf("scrobble START 0", "scrobble PAUSE 30", "scrobble STOP 30", "scrobble START 0"), f.calls(SIMKL))
        assertEquals(listOf(show, show, show, "tt0111161"), f.log.map { it.context!!.ids.imdb })
    }

    @Test
    fun aRebindDropsAStillQueuedReport() = runTest {
        val f = fixture(SIMKL)
        f.startAtZero()
        f.moveTo(40)
        f.advance(30.seconds)
        f.tracker(SIMKL).latency = 10.seconds
        // The pause goes on the wire and blocks there; the stop only queues.
        f.observer.onPlayingChanged(false, pct(40))
        f.settle()
        f.observer.onVideoStopped(pct(40))
        f.settle()
        f.connect(SIMKL)
        f.advance(60.seconds)
        // The pause belonged to the old account; the stop goes to neither.
        assertEquals(listOf("scrobble START 0", "scrobble PAUSE 40"), f.calls(SIMKL))
    }

    @Test
    fun aRebindBeforeTheTerminalReportKeepsItOffTheNewAccount() = runTest {
        val f = fixture(TRAKT)
        f.startAtZero()
        f.moveTo(40)
        f.connect(TRAKT)
        f.advance(30.seconds)
        f.observer.onPlayingChanged(false, pct(40))
        f.stop(40)
        assertEquals(listOf("scrobble START 0"), f.calls(TRAKT))
    }

    @Test
    fun aRebindDuringTheTerminalReportCancelsTheWatchedFallback() = runTest {
        val f = fixture(SIMKL)
        f.backend.watchedThreshold = 0.75
        f.startAtZero()
        f.moveTo(76)
        // The start's spacing is over: the stop goes on the wire at once, and is still there when the account changes.
        f.advance(5.seconds)
        f.tracker(SIMKL).latency = 10.seconds
        f.observer.onVideoStopped(pct(76))
        f.advance(1.seconds)
        f.connect(SIMKL)
        f.advance(60.seconds)
        assertEquals(listOf("scrobble START 0", "scrobble STOP 76"), f.calls(SIMKL))
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun shutdownSendsTheOpenPlaybacksStop() = runTest {
        val f = fixture(TRAKT)
        f.startAtZero()
        f.moveTo(40)
        f.hub.shutdown()
        assertEquals(listOf("scrobble START 0", "scrobble STOP 40"), f.calls(TRAKT))
    }

    @Test
    fun aStopThatHangsHoldsShutdownForThreeSecondsThenIsCancelled() = runTest {
        val f = fixture(TRAKT)
        f.startAtZero()
        f.moveTo(40)
        f.tracker(TRAKT).latency = 1.hours
        val start = testScheduler.currentTime

        f.hub.shutdown()

        assertEquals(3.seconds.inWholeMilliseconds, testScheduler.currentTime - start)
        f.advance(2.hours)
        assertEquals(listOf("scrobble START 0"), f.calls(TRAKT), "the stop was cancelled, never answered")
    }

    @Test
    fun aProfileSwitchDropsTheOpenPlayback() = runTest {
        val f = fixture(TRAKT)
        f.startAtZero()
        f.moveTo(40)
        f.hub.onActiveProfileChanged("p2")
        f.settle()
        f.stop(95)
        assertEquals(listOf("scrobble START 0"), f.calls(TRAKT))
    }
}
