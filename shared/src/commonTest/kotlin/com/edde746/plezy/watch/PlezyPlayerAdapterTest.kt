package com.edde746.plezy.watch

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaVersion
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Plezy's player behind the Open Watch Party SDK: what the room reads of it, and how its commands land. */
class PlezyPlayerAdapterTest {
    private fun copy(durationMs: Long? = 7_020_000, versions: List<MediaVersion>? = null): WatchCopy {
        val item = MediaItem(
            id = "movie-1",
            backend = BackendKind.PLEX,
            kind = MediaKind.MOVIE,
            title = "Alien",
            durationMs = durationMs,
            serverId = "nas",
            mediaVersions = versions,
        )
        return WatchCopy.of(item, versions?.first())
    }

    private fun TestScope.adapter(player: FakeRoomPlayer = FakeRoomPlayer(renderedFrame = true), copy: WatchCopy = copy()) =
        PlezyPlayerAdapter(player, copy, testScheduler.timeSource)

    /** Runs [block] in the background up to its first wait. */
    private fun TestScope.start(block: suspend () -> Unit): Job = backgroundScope.launch { block() }.also { runCurrent() }

    // Reads

    @Test
    fun positionPauseAndBufferingComeFromThePlayer() = runTest {
        val player = FakeRoomPlayer(positionMs = 42_000, playing = true, buffering = true)
        val adapter = adapter(player)
        assertEquals(42_000, adapter.positionMs)
        assertFalse(adapter.paused)
        assertTrue(adapter.buffering)

        player.playing = false
        player.buffering = false
        player.positionMs = 43_210
        assertTrue(adapter.paused)
        assertFalse(adapter.buffering)
        assertEquals(43_210, adapter.positionMs)
    }

    @Test
    fun aFileThePlayerDoesNotReportYetReadsAsOpeningAtItsStart() = runTest {
        // The engine still reports the last file (or its own start) while it opens this one at 90 s.
        val player = FakeRoomPlayer(positionMs = 2_000, durationMs = 60_000, renderedFrame = true)
        val adapter = PlezyPlayerAdapter(player, copy(), testScheduler.timeSource, WatchFileStart(loadId = 2, positionMs = 90_000))
        assertEquals(90_000, adapter.positionMs, "where the file opens, not where the engine still is")
        assertEquals(7_020_000, adapter.durationMs, "the copy's length, not the last file's")
        assertFalse(adapter.firstFrameShown)

        player.startLoad(2)
        assertEquals(90_000, adapter.positionMs)
        assertFalse(adapter.firstFrameShown)

        player.showFirstFrame(90_400)
        assertEquals(90_400, adapter.positionMs)
        assertEquals(60_000, adapter.durationMs)
        assertTrue(adapter.firstFrameShown)

        adapter.reopened(WatchFileStart(loadId = 3, positionMs = 30_000))
        assertEquals(30_000, adapter.positionMs, "a reload of the file reads as opening again")
        assertFalse(adapter.firstFrameShown)
    }

    @Test
    fun thePlayerLengthWinsBeforeItKnowsOneTheCopyLengthStandsIn() = runTest {
        val player = FakeRoomPlayer(durationMs = 0)
        val adapter = adapter(player)
        assertEquals(7_020_000, adapter.durationMs)

        player.emitDuration(7_021_500)
        assertEquals(7_021_500, adapter.durationMs)

        assertNull(adapter(FakeRoomPlayer(durationMs = null), copy(durationMs = null)).durationMs)

        val versioned = copy(
            versions = listOf(
                MediaVersion(id = "cut", parts = listOf(MediaPart(id = "p", durationMs = 7_380_000))),
                MediaVersion(id = "other"),
            ),
        )
        assertEquals(7_380_000, adapter(FakeRoomPlayer(durationMs = 0), versioned).durationMs, "the copy's own version, not the item")
    }

    @Test
    fun theFirstFrameCountsOnlyOnceAHoldIsOver() = runTest {
        val player = FakeRoomPlayer()
        val adapter = adapter(player)
        assertFalse(adapter.firstFrameShown)
        player.emitPlaybackRestart()
        assertTrue(adapter.firstFrameShown)

        val first = Job()
        val second = Job()
        adapter.hold(first)
        assertFalse(adapter.firstFrameShown)
        adapter.hold(second)
        first.complete()
        assertFalse(adapter.firstFrameShown, "a replaced hold ending does not end the newer one")

        second.completeExceptionally(IllegalStateException("display mode switch failed"))
        assertTrue(adapter.firstFrameShown, "a failed hold still ends")
    }

    @Test
    fun rateChangesAreOfferedUnlessAudioPassesThrough() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        val adapter = adapter(player)
        assertTrue(adapter.canSetRate)
        player.audioPassthrough = true
        assertFalse(adapter.canSetRate)
    }

    @Test
    fun seeksLandExactlyAFileThatShowsFramesButCantSeekIsFollowedByRateOnly() = runTest {
        assertEquals(0, adapter(FakeRoomPlayer(seekable = true, renderedFrame = true)).seekAccuracyMs)
        // Still opening: not known yet, so the room may seek once it can.
        assertEquals(0, adapter(FakeRoomPlayer(seekable = false)).seekAccuracyMs)
        assertEquals(
            PlezyPlayerAdapter.CANNOT_SEEK_ACCURACY_MS,
            adapter(FakeRoomPlayer(seekable = false, renderedFrame = true)).seekAccuracyMs,
        )
    }

    // Commands

    @Test
    fun playPauseAndRateGoToTheScreenCommands() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        val adapter = adapter(player)
        start { adapter.play() }
        assertTrue(player.playing)
        start { adapter.setRate(1.5) }
        start { adapter.pause() }
        assertEquals(listOf("play", "rate:1.5", "pause"), player.commandLog)
        assertFalse(player.playing)
    }

    @Test
    fun aRefusedPlayThrowsToTheSdk() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        player.nextCommandError = IllegalStateException("distraction optimization")
        assertFailsWith<IllegalStateException> { adapter(player).play() }
    }

    @Test
    fun commandsWaitForAHold() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        val adapter = adapter(player)
        val hold = Job()
        adapter.hold(hold)

        val play = start { adapter.play() }
        advanceTimeBy(5_000)
        runCurrent()
        assertEquals(emptyList(), player.commandLog)
        assertFalse(play.isCompleted)

        hold.complete()
        runCurrent()
        assertEquals(listOf("play"), player.commandLog)
        assertTrue(play.isCompleted)
    }

    @Test
    fun aReleasedAdapterReturnsAtOnceAndCommandsNothingAlsoFromInsideAHold() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        val adapter = adapter(player)
        adapter.hold(Job())
        val held = start { adapter.play() }
        assertFalse(held.isCompleted)

        adapter.release()
        runCurrent()
        assertTrue(held.isCompleted)
        assertTrue(adapter.isReleased)

        val done = mutableListOf<String>()
        start { adapter.pause(); done += "pause" }
        start { adapter.seek(1_000); done += "seek" }
        start { adapter.setRate(2.0); done += "rate" }
        assertEquals(listOf("pause", "seek", "rate"), done)
        assertEquals(emptyList(), player.commandLog)
    }

    @Test
    fun aDisposedPlayerIsNotCommanded() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        val adapter = adapter(player)
        player.disposed = true
        val seek = start { adapter.seek(1_000) }
        start { adapter.play() }
        assertTrue(seek.isCompleted)
        assertEquals(emptyList(), player.commandLog)
    }

    // Seek

    @Test
    fun landsOnThePlaybackRestart() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        val adapter = adapter(player)
        val seek = start { adapter.seek(60_000) }

        assertEquals(listOf("seek:60000"), player.commandLog)
        assertTrue(seek.isCompleted)
        assertEquals(60_000, player.positionMs)
    }

    @Test
    fun waitsUntilThePlayerTakesSeeksBeforeIssuingOne() = runTest {
        val player = FakeRoomPlayer(seekable = false)
        val adapter = adapter(player)
        val seek = start { adapter.seek(60_000) }
        advanceTimeBy(2_000)
        runCurrent()
        assertEquals(emptyList(), player.commandLog, "mpv refuses a seek while it opens the file")

        player.emitPlaybackRestart()
        advanceTimeBy(100)
        runCurrent()
        assertEquals(listOf("seek:60000"), player.commandLog)
        assertTrue(seek.isCompleted)
    }

    @Test
    fun withoutARestartLandsOnceThePositionIsThereAndThePlayerIsNotBuffering() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true).apply { emitRestartOnSeek = false }
        val adapter = adapter(player)
        val seek = start { adapter.seek(60_000) }
        player.buffering = true
        advanceTimeBy(1_000)
        runCurrent()
        assertEquals(listOf("seek:60000"), player.commandLog)
        assertFalse(seek.isCompleted, "still buffering at the target")

        player.buffering = false
        advanceTimeBy(100)
        runCurrent()
        assertTrue(seek.isCompleted)
    }

    @Test
    fun doesNotCountTheOldPositionAsLandedInItsFirst300Ms() = runTest {
        val player = FakeRoomPlayer(positionMs = 60_000, renderedFrame = true).apply { emitRestartOnSeek = false }
        val adapter = adapter(player)
        val seek = backgroundScope.launch { adapter.seek(60_500) }
        player.positionMs = 60_000
        advanceTimeBy(200)
        runCurrent()
        assertFalse(seek.isCompleted)
        advanceTimeBy(200)
        runCurrent()
        assertTrue(seek.isCompleted)
    }

    @Test
    fun givesUpAtTheLandingTimeout() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true).apply { emitRestartOnSeek = false }
        val adapter = adapter(player)
        val seek = start { adapter.seek(60_000) }
        player.positionMs = 0
        advanceTimeBy(PlezyPlayerAdapter.LANDING_TIMEOUT.inWholeMilliseconds - 100)
        runCurrent()
        assertFalse(seek.isCompleted)
        advanceTimeBy(200)
        runCurrent()
        assertTrue(seek.isCompleted)
    }

    @Test
    fun aReleaseEndsTheWaitForTheLanding() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true).apply { emitRestartOnSeek = false }
        val adapter = adapter(player)
        val seek = start { adapter.seek(60_000) }
        player.positionMs = 0
        advanceTimeBy(1_000)
        runCurrent()
        assertFalse(seek.isCompleted)

        adapter.release()
        runCurrent()
        assertTrue(seek.isCompleted)
    }

    @Test
    fun aFailedSeekThrowsToTheSdk() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        player.nextCommandError = IllegalStateException("seek refused")
        assertFailsWith<IllegalStateException> { adapter(player).seek(1_000) }
    }

    @Test
    fun aSeekWaitsForTheLoadOfItsFile() = runTest {
        val player = FakeRoomPlayer(renderedFrame = true)
        val adapter = PlezyPlayerAdapter(player, copy(), testScheduler.timeSource, WatchFileStart(loadId = 2, positionMs = 0))
        val seek = start { adapter.seek(60_000) }
        advanceTimeBy(1_000)
        runCurrent()
        assertTrue(player.commandLog.isEmpty(), "the last file takes no seek meant for this one")

        player.startLoad(2)
        advanceTimeBy(100)
        runCurrent()
        assertEquals(listOf("seek:60000"), player.commandLog)
        assertTrue(seek.isCompleted)
    }
}
