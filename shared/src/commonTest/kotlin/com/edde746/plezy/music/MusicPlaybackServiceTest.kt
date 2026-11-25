package com.edde746.plezy.music

import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.music.playingFromTitle
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.MediaCommandHandler
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingKind
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

class MusicPlaybackServiceTest {
    private val t1 = track("t1")
    private val t2 = track("t2")
    private val t3 = track("t3")

    private fun musicTest(block: suspend TestScope.() -> Unit) = runTest {
        block()
    }

    private val MusicHarness.ids get() = state.queue.ids()

    // ---- Shuffled session start ---------------------------------------------------------------------------------

    private val playlist = List(6) { track("p$it") }

    @Test
    fun noStartTrackShufflesTheHeadTooInsteadOfPinningTheFirstTrack() = musicTest {
        val h = MusicHarness(this, random = LowestRandom)
        h.playTracks(playlist, shuffle = true)

        val opened = assertNotNull(h.state.currentTrack)
        assertNotEquals("p0", opened.id, "shuffle opened on the list head")
        assertEquals(opened.id, h.state.queue.first().id)
        assertEquals(playlist.ids().toSet(), h.ids.toSet())
        assertTrue(h.state.shuffled)
        assertEquals(listOf(urlFor(opened)), h.player.openedUris)
    }

    @Test
    fun anExplicitStartTrackStillAnchorsTheShuffledQueue() = musicTest {
        val h = MusicHarness(this, random = LowestRandom)
        h.playTracks(playlist, startTrack = playlist[3], shuffle = true)

        assertEquals("p3", h.state.currentTrack?.id)
        assertEquals("p3", h.state.queue.first().id)
        assertEquals(playlist.ids().toSet(), h.ids.toSet())
    }

    @Test
    fun aStartTrackAbsentFromTheListDropsTheAnchorRatherThanPinningTheFirstTrack() = musicTest {
        val h = MusicHarness(this, random = LowestRandom)
        h.playTracks(playlist, startTrack = track("not-in-list"), shuffle = true)

        assertNotEquals("p0", h.state.currentTrack?.id)
        assertEquals(playlist.ids().toSet(), h.ids.toSet())
    }

    // ---- Volume -------------------------------------------------------------------------------------------------

    @Test
    fun volumeDragsMoveOnlyThePreview() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        val before = h.state

        h.service.setVolume(42.0, persist = false)

        assertEquals(42.0, h.service.volumePreview.value)
        assertEquals(listOf(42.0), h.player.volumes)
        assertSame(before, h.state, "a drag publishes no session state")
    }

    @Test
    fun volumePersistenceKeepsOneWriteInFlightAndCoalescesABurstToTheLatestValue() = musicTest {
        val writes = mutableListOf<Double>()
        val gates = mutableListOf<CompletableDeferred<Unit>>()
        var inFlight = 0
        var maxInFlight = 0
        val h = MusicHarness(this, volumeWriter = { volume ->
            writes += volume
            inFlight++
            maxInFlight = maxOf(maxInFlight, inFlight)
            val gate = CompletableDeferred<Unit>().also { gates += it }
            try {
                gate.await()
            } finally {
                inFlight--
            }
        })
        var settled = 0
        val callers = listOf(10.0, 20.0, 30.0).map { v -> async { h.service.setVolume(v); settled++ } }
        runCurrent()
        assertEquals(listOf(10.0), writes)
        assertEquals(1, inFlight)
        assertEquals(0, settled)

        gates[0].complete(Unit)
        runCurrent()
        assertEquals(listOf(10.0, 30.0), writes)
        assertEquals(1, maxInFlight)
        assertEquals(0, settled)

        gates[1].complete(Unit)
        callers.forEach { it.await() }
        assertEquals(0, inFlight)
        assertEquals(3, settled)
        assertEquals(30.0, h.state.volume)
    }

    @Test
    fun volumePersistencePropagatesADrainErrorAndAcceptsALaterWrite() = musicTest {
        val writes = mutableListOf<Double>()
        val gates = mutableListOf<CompletableDeferred<Unit>>()
        val h = MusicHarness(this, volumeWriter = { volume ->
            writes += volume
            CompletableDeferred<Unit>().also { gates += it }.await()
        })
        val failure = IllegalStateException("persistence failed")
        val first = async { runCatching { h.service.setVolume(40.0) } }
        val second = async { runCatching { h.service.setVolume(50.0) } }
        runCurrent()
        gates[0].completeExceptionally(failure)
        runCurrent()
        assertEquals(listOf(40.0, 50.0), writes)
        assertFalse(first.isCompleted)
        assertFalse(second.isCompleted)

        gates[1].complete(Unit)
        // Coroutines may hand a copy across the await: compare what it says.
        assertEquals(failure.message, first.await().exceptionOrNull()?.message)
        assertEquals(failure.message, second.await().exceptionOrNull()?.message)

        val recovered = async { h.service.setVolume(60.0) }
        runCurrent()
        assertEquals(listOf(40.0, 50.0, 60.0), writes)
        gates[2].complete(Unit)
        recovered.await()
    }

    @Test
    fun theStoredMusicVolumeReachesEveryNewPlayer() = musicTest {
        val data = musicData()
        data.deviceSettings.set(AppSettings.musicVolume, 35.0)
        val h = MusicHarness(this, data = data)
        h.playTracks(listOf(t1))

        assertEquals(35.0, h.state.volume)
        assertEquals(listOf(35.0), h.player.volumes)
    }

    @Test
    fun aMusicVolumeResetOrImportedReachesThePlayingPlayer() = musicTest {
        val data = musicData()
        val h = MusicHarness(this, data = data, volumeWriter = { data.deviceSettings.set(AppSettings.musicVolume, it) })
        h.playTracks(listOf(t1))
        h.service.setVolume(40.0)
        h.pump()
        assertEquals(40.0, data.deviceSettings.value(AppSettings.musicVolume))

        h.data.settingsBackup.resetAll()
        h.pump()
        assertEquals(100.0, h.state.volume)
        assertEquals(100.0, h.service.volumePreview.value)
        assertEquals(100.0, h.player.volumes.last())

        val file = """{"formatVersion":1,"prefs":{"music_volume":{"type":"double","value":25.0}}}"""
        h.data.settingsBackup.import(file.encodeToByteArray(), "local-1")
        h.pump()
        assertEquals(25.0, h.state.volume)
        assertEquals(25.0, h.player.volumes.last())
    }

    // ---- Opening and gapless --------------------------------------------------------------------------------------

    @Test
    fun playFromListOpensTheFirstTrackAndArmsTheSecond() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))

        assertEquals(listOf(urlFor(t1)), h.player.openedUris)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals("t1", h.state.currentTrack?.id)
        assertEquals(0, h.state.currentIndex)
        assertEquals(urlFor(t2), h.player.armed?.uri)
        assertEquals(listOf("t1"), h.backend.reportsFor("started").map { it.itemId })
        assertEquals("Track t1", h.controls.last.title)
    }

    @Test
    fun aSupersededSlowGaplessResolveCannotOverwriteTheNewlyRequestedArm() = musicTest {
        val h = MusicHarness(this)
        val oldArm = h.resolver.gateNextResolve(t2.id)
        h.playTracks(listOf(t1, t2))
        assertTrue(oldArm.entered.isCompleted)
        assertNull(h.player.armed)

        h.service.addNext(listOf(t3))
        oldArm.release()
        h.pump()

        assertEquals(urlFor(t3), h.player.armed?.uri)
    }

    @Test
    fun endOfTrackSleepInvalidatesASlowGaplessResolve() = musicTest {
        val h = MusicHarness(this)
        val arm = h.resolver.gateNextResolve(t2.id)
        h.playTracks(listOf(t1, t2))
        h.service.setSleepTimer(null, endOfTrack = true)
        arm.release()
        h.pump()

        assertTrue(h.state.sleepTimerEndOfTrack)
        assertNull(h.player.armed)
    }

    @Test
    fun manualAdvanceCancelsABlockedArmUntilTheReplacementOpenCommits() = musicTest {
        val h = MusicHarness(this)
        val staleArm = h.resolver.gateNextResolve(t2.id)
        val replacementResolve = h.resolver.gateNextResolve(t2.id)
        h.playTracks(listOf(t1, t2, t3))
        assertTrue(staleArm.entered.isCompleted)

        val openGate = h.player.gateNextOpen()
        val advance = launch { h.service.next() }
        runCurrent()
        assertTrue(replacementResolve.entered.isCompleted)
        replacementResolve.release()
        runCurrent()
        assertTrue(openGate.entered.isCompleted)

        staleArm.release()
        h.pump()
        assertNull(h.resolver.resolveCounts[t3.id])
        assertNull(h.player.armed)
        assertEquals(listOf(urlFor(t1)), h.player.openedUris)

        openGate.release()
        advance.join()
        h.pump()
        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
        assertEquals(1, h.resolver.resolveCounts[t3.id])
        assertEquals(urlFor(t3), h.player.armed?.uri)

        assertTrue(h.player.emitNaturalBoundary())
        h.pump()
        assertEquals("t3", h.state.currentTrack?.id)
        assertEquals(2, h.state.currentIndex)
        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris, "t3 advances from the engine's arm")
    }

    @Test
    fun queueEditsDuringAReplacementOpenCoalesceIntoTheLatestPostOpenArm() = musicTest {
        val t4 = track("t4")
        val t5 = track("t5")
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))

        val openGate = h.player.gateNextOpen()
        val advance = launch { h.service.next() }
        runCurrent()
        assertTrue(openGate.entered.isCompleted)
        val latestArm = h.resolver.gateNextResolve(t5.id)

        h.service.addNext(listOf(t4))
        h.service.addNext(listOf(t5))
        h.pump()
        assertNull(h.resolver.resolveCounts[t4.id])
        assertNull(h.resolver.resolveCounts[t5.id])
        assertNull(h.player.armed)

        openGate.release()
        advance.join()
        runCurrent()
        assertTrue(latestArm.entered.isCompleted)
        assertNull(h.resolver.resolveCounts[t4.id])
        assertEquals(1, h.resolver.resolveCounts[t5.id])
        assertNull(h.player.armed)

        latestArm.release()
        h.pump()
        assertEquals(listOf("t1", "t2", "t5", "t4", "t3"), h.ids)
        assertEquals(urlFor(t5), h.player.armed?.uri)
        assertTrue(h.player.emitNaturalBoundary())
        h.pump()
        assertEquals("t5", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
    }

    @Test
    fun completedFallbackCancelsABlockedArmUntilTheReplacementOpenCommits() = musicTest {
        val h = MusicHarness(this)
        val staleArm = h.resolver.gateNextResolve(t2.id)
        val replacementResolve = h.resolver.gateNextResolve(t2.id)
        h.playTracks(listOf(t1, t2, t3))
        assertTrue(staleArm.entered.isCompleted)
        val openGate = h.player.gateNextOpen()

        h.player.emitCompleted()
        runCurrent()
        assertTrue(replacementResolve.entered.isCompleted)
        replacementResolve.release()
        runCurrent()
        assertTrue(openGate.entered.isCompleted)

        staleArm.release()
        h.pump()
        assertNull(h.resolver.resolveCounts[t3.id])
        assertNull(h.player.armed)

        openGate.release()
        h.pump()
        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
        assertEquals(urlFor(t3), h.player.armed?.uri)
        assertTrue(h.player.emitNaturalBoundary())
        h.pump()
        assertEquals("t3", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
    }

    @Test
    fun aSlowInstantMixCannotReplaceANewerExplicitQueue() = musicTest {
        val h = MusicHarness(this)
        val mixGate = CompletableDeferred<List<MediaItem>>()
        h.backend.instantMixGate = mixGate

        val mix = async { h.service.playInstantMix(t1) }
        runCurrent()
        h.playTracks(listOf(t3))
        mixGate.complete(listOf(t1, t2))

        assertEquals(InstantMixOutcome.SUPERSEDED, mix.await())
        h.pump()
        assertEquals("t3", h.state.currentTrack?.id)
        assertEquals(listOf("t3"), h.ids)
    }

    @Test
    fun anInstantMixWhoseOpenLosesToANewerQueueReportsSuperseded() = musicTest {
        val h = MusicHarness(this)
        h.backend.instantMixGate = CompletableDeferred(listOf(t1, t2))
        val resolve = h.resolver.gateNextResolve("t1")

        val mix = async { h.service.playInstantMix(t1) }
        runCurrent()
        h.playTracks(listOf(t3))
        resolve.release()

        assertEquals(InstantMixOutcome.SUPERSEDED, mix.await())
        h.pump()
        assertEquals("t3", h.state.currentTrack?.id)
    }

    @Test
    fun anOfflineQueueResolvesEveryLaterTrackAndArmAsLocalOnly() = musicTest {
        val h = MusicHarness(this)
        h.service.playFromList(listOf(t1, t2, t3), null, MusicPlayContext("Test", MusicPlayContextKind.ALBUM), shuffle = false, initialPosition = null, offline = true)
        h.pump()
        h.service.next()
        h.pump()
        assertEquals("t2", h.state.currentTrack?.id)
        assertTrue(h.resolver.resolves.size >= 3, "the arms resolve too: ${h.resolver.resolves}")
        assertTrue(h.resolver.resolves.all { (_, offline) -> offline }, "${h.resolver.resolves}")

        h.playTracks(listOf(t1, t2))
        assertTrue(h.resolver.resolves.takeLast(2).none { (_, offline) -> offline }, "an online queue drops the policy")
    }

    @Test
    fun anInstantMixPlaysUnderTheSeedsTitleOrSaysItIsEmpty() = musicTest {
        val h = MusicHarness(this)
        h.backend.instantMixGate = CompletableDeferred(emptyList())
        assertEquals(InstantMixOutcome.EMPTY, h.service.playInstantMix(t1))

        h.backend.instantMixGate = CompletableDeferred(listOf(t2, t3))
        assertEquals(InstantMixOutcome.STARTED, h.service.playInstantMix(t1))
        assertEquals(MusicPlayContext("Track t1", MusicPlayContextKind.MIX), h.state.playContext)
        assertEquals(listOf("t2", "t3"), h.ids)
    }

    @Test
    fun trackTransitionAdvancesTheCursorRearmsAndReportsThePreviousTrackStoppedAtDuration() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))

        h.player.emitTransition(urlFor(t2))
        h.pump()

        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(1, h.state.currentIndex)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals(urlFor(t3), h.player.armed?.uri)
        assertEquals(listOf(urlFor(t1)), h.player.openedUris, "no second open: the engine advanced gaplessly")
        val stopped = h.backend.reportsFor("stopped")
        assertEquals(listOf("t1"), stopped.map { it.itemId })
        assertEquals(TRACK_DURATION, stopped.single().position)
        assertEquals(listOf("t1"), h.backend.markedWatched, "a full playout crosses the watched threshold")
        assertEquals(listOf("t1", "t2"), h.backend.reportsFor("started").map { it.itemId })
    }

    @Test
    fun aGaplesslyAdvancedTrackReportsItsOwnStartNotTheFinishedTracksPlayhead() = musicTest {
        val long = track("long", durationMs = 7.minutes.inWholeMilliseconds)
        val h = MusicHarness(this)
        h.playTracks(listOf(long, t2))

        h.player.setOutgoingPlayhead(7.minutes, 7.minutes)
        h.player.emitTransition(urlFor(t2))
        h.pump()

        val started = h.backend.reportsFor("started")
        assertEquals(listOf("long", "t2"), started.map { it.itemId })
        assertEquals(Duration.ZERO, started.last().position)
        assertEquals(TRACK_DURATION, started.last().duration, "the first report carries t2's own duration")
        assertEquals(listOf("long"), h.backend.markedWatched)
    }

    @Test
    fun aTrackWithNoMetadataDurationIsReportedStoppedWhereTheSourceActuallyGotTo() = musicTest {
        val undated = track("nd", durationMs = null)
        val h = MusicHarness(this)
        h.playTracks(listOf(undated, t2))

        h.player.outgoingSourcePosition = 2.minutes + 12.seconds
        h.player.setPosition(Duration.ZERO)
        h.player.emitTransition(urlFor(t2))
        h.pump()

        val stopped = h.backend.reportsFor("stopped")
        assertEquals(listOf("nd"), stopped.map { it.itemId })
        assertEquals(2.minutes + 12.seconds, stopped.single().position)
    }

    @Test
    fun completedWithNothingArmedParksPausedAtTheEndAndKeepsTheTrack() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        h.player.emitTransition(urlFor(t2))
        h.pump()
        assertNull(h.player.armed)

        h.player.emitCompleted()
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(2, h.state.queue.size)
        val stopped = h.backend.reportsFor("stopped")
        assertEquals(listOf("t1", "t2"), stopped.map { it.itemId })
        assertEquals(TRACK_DURATION, stopped.last().position)
        assertFalse(h.controls.last.playing)
    }

    @Test
    fun playAfterTheQueuePlayedOutRestartsTheLastTrack() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        h.player.emitCompleted()
        h.pump()

        h.service.play()
        h.pump()

        assertEquals(listOf(Duration.ZERO), h.player.seeks)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals(listOf("t1", "t1"), h.backend.reportsFor("started").map { it.itemId })
    }

    @Test
    fun completedWithAFailedArmFallsBackToOpeningTheNextTrack() = musicTest {
        val h = MusicHarness(this)
        h.resolver.failingIds += "t2"
        h.playTracks(listOf(t1, t2))
        assertNull(h.player.armed)

        h.resolver.failingIds.clear()
        h.player.emitCompleted()
        h.pump()

        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
    }

    @Test
    fun aCompletedPulseContradictedWithinTheConfirmationWindowIsIgnored() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        h.player.emitTransition(urlFor(t2))
        h.pump()

        // A boundary pulse with nothing armed that the engine takes back (playing on) before it is confirmed.
        h.player.emitCompleted()
        h.player.seekBy0()
        h.pump()

        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals("t2", h.state.currentTrack?.id)
    }

    private suspend fun FakeAudioPlayer.seekBy0() = seek(state.position)

    // ---- Errors -------------------------------------------------------------------------------------------------

    @Test
    fun playerErrorSurfacesAndAutoSkipsToTheNextTrack() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))
        val errors = mutableListOf<Throwable>()
        backgroundScope.launch { h.service.errors.collect { errors += it } }
        runCurrent()

        h.player.emitError("boom")
        h.pump()

        assertEquals(1, errors.size)
        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
    }

    @Test
    fun threeConsecutiveFailuresStopTheSessionWithAnErrorStatus() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))
        h.resolver.failingIds += listOf("t2", "t3")
        val errors = mutableListOf<Throwable>()
        backgroundScope.launch { h.service.errors.collect { errors += it } }
        runCurrent()

        h.player.emitError("boom")
        h.pump()

        assertEquals(3, errors.size)
        assertEquals(MusicPlaybackStatus.ERROR, h.state.status)
        assertNull(h.state.currentTrack)
        assertTrue(h.state.queue.isEmpty())
        assertTrue(h.players.single().disposed)
    }

    @Test
    fun playbackProgressAfterAnErrorResetsTheStrikeCounter() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3, track("t4")))

        h.player.emitError("boom")
        h.pump()
        h.player.setPosition(5.seconds)
        h.player.emitError("boom")
        h.pump()
        h.player.setPosition(5.seconds)
        h.player.emitError("boom")
        h.pump()

        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals("t4", h.state.currentTrack?.id)
    }

    // ---- Video's claim ------------------------------------------------------------------------------------------

    @Test
    fun claimVideoStopsTheSessionAndDisposesTheAudioCore() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        val player = h.player

        h.coordinator.claimVideo()

        assertTrue(player.disposed)
        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
        assertTrue(h.state.queue.isEmpty())
        assertEquals(1, h.controls.hides)
        assertEquals(listOf("t1"), h.backend.reportsFor("stopped").map { it.itemId })

        h.playTracks(listOf(t3))
        assertEquals(2, h.players.size)
        assertEquals(listOf(urlFor(t3)), h.player.openedUris)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
    }

    @Test
    fun aClosedSessionNoLongerAnswersVideosClaim() = musicTest {
        val coordinator = PlaybackCoordinator()
        val first = MusicHarness(this, coordinator = coordinator)
        val second = MusicHarness(this, coordinator = coordinator)
        second.playTracks(listOf(t1))
        first.service.close()

        coordinator.claimVideo()

        assertTrue(second.player.disposed, "a replaced session's close keeps its successor registered")
    }

    // ---- Modes and queue edits ----------------------------------------------------------------------------------

    @Test
    fun repeatOneArmsTheSameUriWithoutANewResolveAndRepeatsOnTransition() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        assertEquals(urlFor(t2), h.player.armed?.uri)

        h.service.setRepeatMode(MusicRepeatMode.ONE)
        h.pump()
        assertEquals(urlFor(t1), h.player.armed?.uri)
        assertEquals(1, h.resolver.resolveCounts["t1"])

        h.player.emitTransition(urlFor(t1))
        h.pump()
        assertEquals("t1", h.state.currentTrack?.id)
        assertEquals(0, h.state.currentIndex)
        assertEquals(urlFor(t1), h.player.armed?.uri)
        assertEquals(1, h.resolver.resolveCounts["t1"])
    }

    @Test
    fun queueEditsThatKeepTheSameNextTrackDoNotRearmOrReresolve() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))
        val armCalls = h.player.setNextCalls.size

        h.service.addToEnd(listOf(track("t4")))
        h.pump()

        assertEquals(armCalls, h.player.setNextCalls.size)
        assertEquals(1, h.resolver.resolveCounts["t2"])
    }

    @Test
    fun previousRestartsTheTrackPast3sAndStepsBackBeforeThat() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        h.player.emitTransition(urlFor(t2))
        h.pump()

        h.player.setPosition(10.seconds)
        h.service.previous()
        assertEquals(listOf(Duration.ZERO), h.player.seeks)
        assertEquals("t2", h.state.currentTrack?.id)

        h.player.setPosition(1.seconds)
        h.service.previous()
        h.pump()
        assertEquals("t1", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1), urlFor(t1)), h.player.openedUris)
    }

    @Test
    fun jumpToPlaysTheEntryAndIgnoresTheCurrentOrOutOfRange() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))

        h.service.jumpTo(0)
        h.service.jumpTo(9)
        h.service.jumpTo(2)
        h.pump()

        assertEquals("t3", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1), urlFor(t3)), h.player.openedUris)
    }

    @Test
    fun anEnqueueWhileIdleParksASessionPausedOnTheFirstAddedTrack() = musicTest {
        val h = MusicHarness(this)
        h.service.addToEnd(listOf(t2, t3))
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(MusicPlayContext("Album", MusicPlayContextKind.TRACKS), h.state.playContext)
        assertFalse(h.player.state.playing)
    }

    @Test
    fun stopClearsTheSessionAndPublishes() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        val revision = h.service.queueSessionRevision

        h.service.stop()
        h.pump()

        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
        assertTrue(h.state.queue.isEmpty())
        assertNull(h.state.playContext)
        assertTrue(h.player.disposed)
        assertEquals(1, h.controls.hides)
        assertEquals(listOf("t1"), h.backend.reportsFor("stopped").map { it.itemId })
        assertNotEquals(revision, h.service.queueSessionRevision)
    }

    @Test
    fun aFailedExplicitResumeDoesNotPublishPlayingStatus() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        h.service.pause()
        h.pump()
        val gate = CompletableDeferred<Unit>()
        h.player.playGate = gate
        val denied = IllegalStateException("audio focus denied")

        val resume = async { runCatching { h.service.play() } }
        runCurrent()
        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        gate.completeExceptionally(denied)

        assertEquals(denied.message, resume.await().exceptionOrNull()?.message)
        assertEquals(1, h.player.playCalls)
        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
    }

    @Test
    fun aLatePlayCompletionCannotReviveAStoppedSession() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        h.service.pause()
        val gate = CompletableDeferred<Unit>()
        h.player.playGate = gate

        val play = launch { h.service.play() }
        runCurrent()
        h.service.stop()
        gate.complete(Unit)
        play.join()
        h.pump()

        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
    }

    @Test
    fun aLatePauseCompletionCannotChangeAStoppedSession() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        val gate = CompletableDeferred<Unit>()
        h.player.pauseGate = gate

        val pause = launch { h.service.pause() }
        runCurrent()
        h.service.stop()
        gate.complete(Unit)
        pause.join()
        h.pump()

        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
    }

    @Test
    fun removingTheCurrentTrackOpensTheNextOne() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))

        h.service.removeAt(0)
        h.pump()

        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(listOf("t2", "t3"), h.ids)
        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
        assertEquals(listOf("t1"), h.backend.reportsFor("stopped").map { it.itemId })
    }

    // ---- OS media controls ----------------------------------------------------------------------------------------

    @Test
    fun aSystemPauseResumesOnTheSystemsResume() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))

        h.controls.send(MediaCommand.SystemPause)
        h.pump()
        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals(1, h.player.pauseCalls)
        assertEquals(0, h.controls.userPauses, "the system's pause isn't the user's")

        h.controls.send(MediaCommand.SystemResume)
        h.pump()
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals(1, h.player.playCalls)
    }

    @Test
    fun aSystemPauseWithoutTheSystemsResumeStaysPaused() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))

        h.controls.send(MediaCommand.SystemPause)
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals(0, h.player.playCalls)
    }

    @Test
    fun aUserPauseAfterASystemPauseKeepsTheSessionPausedOnTheSystemsResume() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        h.controls.send(MediaCommand.SystemPause)
        h.pump()

        h.controls.send(MediaCommand.Pause)
        h.pump()
        h.controls.send(MediaCommand.SystemResume)
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals(0, h.player.playCalls)
        assertEquals(1, h.controls.userPauses)
    }

    @Test
    fun aSystemPauseOfAPausedSessionNeverResumesIt() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        h.service.pause()
        h.pump()

        h.controls.send(MediaCommand.SystemPause)
        h.pump()
        h.controls.send(MediaCommand.SystemResume)
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals(0, h.player.playCalls)
    }

    @Test
    fun theOsStopCommandStopsTheSession() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        val player = h.player

        h.controls.send(MediaCommand.Stop)
        h.pump()

        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
        assertTrue(player.disposed)
    }

    @Test
    fun osSkipCommandsSeekWithinTheTrackClampedToItsBounds() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        h.player.setPosition(30.seconds)

        h.controls.send(MediaCommand.SeekBy(15.0))
        h.pump()
        assertEquals(listOf(45.seconds), h.player.seeks)

        h.controls.send(MediaCommand.SeekBy(-15.0))
        h.pump()
        assertEquals(30.seconds, h.player.seeks.last())

        h.player.setPosition(5.seconds)
        h.controls.send(MediaCommand.SeekBy(-15.0))
        h.pump()
        assertEquals(Duration.ZERO, h.player.seeks.last())

        h.player.setPosition(TRACK_DURATION - 3.seconds)
        h.controls.send(MediaCommand.SeekBy(15.0))
        h.pump()
        assertEquals(TRACK_DURATION, h.player.seeks.last())
    }

    @Test
    fun osPlayPauseNextPreviousAndSeekDriveTheSession() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))

        h.controls.send(MediaCommand.TogglePause)
        h.pump()
        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        h.controls.send(MediaCommand.Play)
        h.pump()
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        h.controls.send(MediaCommand.SeekTo(42.0))
        h.pump()
        assertEquals(42.seconds, h.player.seeks.last())
        h.controls.send(MediaCommand.Next)
        h.pump()
        assertEquals("t2", h.state.currentTrack?.id)
        h.player.setPosition(Duration.ZERO)
        h.controls.send(MediaCommand.Previous)
        h.pump()
        assertEquals("t1", h.state.currentTrack?.id)
    }

    @Test
    fun musicAdvertisesNextOnlyWhenAManualNextExists() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))

        var shown = h.controls.last
        assertEquals(NowPlayingKind.MUSIC, shown.kind)
        assertTrue(shown.canSkipNext)
        assertFalse(shown.canSkipPrevious)
        assertTrue(shown.canSeek)
        assertFalse(shown.live)
        assertEquals(1.0, shown.rate)
        assertEquals("Artist", shown.subtitle)
        assertEquals("Album", shown.album)
        assertTrue(shown.backgroundPlayback)

        h.service.clearUpcoming()
        h.pump()
        shown = h.controls.last
        assertFalse(shown.canSkipNext)
        assertFalse(shown.canSkipPrevious)
    }

    @Test
    fun musicOffersPreviousOnlyWithAnEntryBeforeOrUnderRepeatAll() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        h.pump()
        assertFalse(h.state.canGoPrevious, "the first track without repeat has none before")
        assertFalse(h.controls.last.canSkipPrevious)

        h.service.setRepeatMode(MusicRepeatMode.ALL)
        h.pump()
        assertTrue(h.state.canGoPrevious, "repeat-all wraps to the last track")
        assertTrue(h.controls.last.canSkipPrevious)

        h.service.setRepeatMode(MusicRepeatMode.OFF)
        h.service.next()
        h.pump()
        assertEquals("t2", h.state.currentTrack?.id)
        assertTrue(h.state.canGoPrevious)
        assertTrue(h.controls.last.canSkipPrevious)
        assertFalse(h.state.canGoNext, "the last track without repeat has none after")
    }

    @Test
    fun playheadUpdatesReachTheOsAtMostOnceASecondWithTheLatestLast() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        advanceTimeBy(2.seconds)
        val before = h.controls.shows.size

        h.player.setPosition(1.seconds)
        h.pump()
        h.player.setPosition(1.2.seconds)
        h.player.setPosition(1.4.seconds)
        h.pump()
        assertEquals(before + 1, h.controls.shows.size, "the leading update only")

        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(before + 2, h.controls.shows.size)
        assertEquals(1.4, h.controls.last.positionSeconds)

        h.service.pause()
        h.pump()
        assertFalse(h.controls.last.playing, "a pause goes out at once")
    }

    @Test
    fun theSessionRepublishesThePlayerPlayheadJumps() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        val jumps = mutableListOf<Duration?>()
        backgroundScope.launch { h.service.playheadJumps.collect { jumps += it } }
        runCurrent()

        h.player.emitJump(2.minutes)
        h.player.emitJump(null)
        h.pump()

        assertEquals(listOf(2.minutes, null), jumps)
    }

    // ---- Gapless boundary races ---------------------------------------------------------------------------------

    @Test
    fun aTransitionRacedByAReorderIsAdoptedViaTheStaleArmMemo() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))
        assertEquals(urlFor(t2), h.player.armed?.uri)

        h.service.reorder(1, 2)
        h.player.emitTransition(urlFor(t2))
        h.pump()

        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(2, h.state.currentIndex)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals(listOf(urlFor(t1)), h.player.openedUris, "adopted gaplessly, no re-open")
        val stopped = h.backend.reportsFor("stopped")
        assertEquals("t1", stopped.single().itemId)
        assertEquals(TRACK_DURATION, stopped.single().position)
        assertEquals(listOf("t1", "t2"), h.backend.reportsFor("started").map { it.itemId })
    }

    @Test
    fun aTransitionIntoATrackRemovedAtTheBoundaryAdvancesToTheRealNext() = musicTest {
        val t4 = track("t4")
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3, t4))

        h.service.removeAt(1)
        h.player.emitTransition(urlFor(t2))
        h.pump()

        assertEquals("t3", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1), urlFor(t3)), h.player.openedUris)
        assertEquals(urlFor(t4), h.player.armed?.uri)
        assertEquals("t1", h.backend.reportsFor("stopped").single().itemId)

        h.player.emitCompleted()
        h.pump()
        assertEquals("t3", h.state.currentTrack?.id, "a stale boundary pulse must not double-advance")
        assertEquals(listOf(urlFor(t1), urlFor(t3)), h.player.openedUris)
    }

    @Test
    fun removedAtTheBoundaryWithNoNextParksPaused() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))

        h.service.removeAt(1)
        h.player.emitTransition(urlFor(t2))
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals("t1", h.state.currentTrack?.id)
        assertEquals(1, h.player.pauseCalls, "the removed track is audible: silence it")
        assertEquals(listOf(urlFor(t1)), h.player.openedUris)
    }

    @Test
    fun aStaleTransitionAfterAManualAdvanceIsDropped() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3))

        h.service.removeAt(1)
        h.service.next()
        h.pump()
        assertEquals("t3", h.state.currentTrack?.id)

        h.player.emitTransition(urlFor(t2))
        h.pump()

        assertEquals("t3", h.state.currentTrack?.id)
        assertEquals(1, h.state.currentIndex)
        assertEquals(listOf(urlFor(t1), urlFor(t3)), h.player.openedUris)
    }

    @Test
    fun aFailedNativeArmFallsBackToAnExplicitOpenAtCompletion() = musicTest {
        val h = MusicHarness(this)
        h.failingSetNextUris += urlFor(t2)
        h.playTracks(listOf(t1, t2))
        assertNull(h.player.armed)

        h.player.emitCompleted()
        h.pump()

        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
    }

    @Test
    fun transitionMatchingIsUrlShapeAgnostic() = musicTest {
        val h = MusicHarness(this)
        h.resolver.urlOverrides["t2"] = "content://downloads/t2"
        h.playTracks(listOf(t1, t2))
        assertEquals("content://downloads/t2", h.player.armed?.uri)

        h.player.emitTransition("content://downloads/t2")
        h.pump()

        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
    }

    // ---- Sleep timer --------------------------------------------------------------------------------------------

    @Test
    fun aTimedSleepTimerExposesItsArmedDurationForThePresetMenu() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))

        h.service.setSleepTimer(30.minutes)
        assertTrue(h.state.sleepTimerActive)
        assertEquals(30.minutes, h.state.sleepTimerDuration)
        assertFalse(h.state.sleepTimerEndOfTrack)

        h.service.setSleepTimer(null, endOfTrack = true)
        assertNull(h.state.sleepTimerDuration)
        assertTrue(h.state.sleepTimerActive)

        h.service.setSleepTimer(null)
        assertFalse(h.state.sleepTimerActive)
        assertNull(h.state.sleepTimerDuration)
    }

    @Test
    fun aTimedSleepTimerPausesWhenItFiresAndKeepsTheSession() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))

        h.service.setSleepTimer(15.minutes)
        advanceTimeBy(15.minutes + 1.seconds)
        runCurrent()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals("t1", h.state.currentTrack?.id)
        assertFalse(h.state.sleepTimerActive)
    }

    @Test
    fun anEndOfTrackSleepTimerSuppressesArmingAndPausesAtCompletion() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        assertEquals(urlFor(t2), h.player.armed?.uri)

        h.service.setSleepTimer(null, endOfTrack = true)
        h.pump()
        assertTrue(h.state.sleepTimerActive)
        assertNull(h.player.armed)

        h.player.emitCompleted()
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals("t1", h.state.currentTrack?.id)
        assertFalse(h.state.sleepTimerActive)
    }

    // ---- Hardware keys -------------------------------------------------------------------------------------------

    @Test
    fun transportKeysDriveTheLiveSessionAndStopUnregistersTheHandler() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))

        assertEquals(listOf(true, true, true), h.system.press(MusicKey.NEXT))
        h.pump()
        assertEquals("t2", h.state.currentTrack?.id)

        assertEquals(listOf(true, true, true), h.system.press(MusicKey.PAUSE))
        h.pump()
        assertEquals(1, h.player.pauseCalls)

        h.service.stop()
        h.pump()
        assertNull(h.system.keyHandler)
        assertEquals(listOf(false, false, false), h.system.press(MusicKey.PLAY_PAUSE))
    }

    // ---- Discord ------------------------------------------------------------------------------------------------

    @Test
    fun aSessionPublishesListeningWithdrawsOnPauseReturnsOnResumeAndClearsOnStop() = musicTest {
        val data = musicData()
        data.deviceSettings.set(AppSettings.enableDiscordRpc, true)
        val discord = FakeDiscordHost()
        val h = MusicHarness(this, data = data, discord = discord)
        h.playTracks(listOf(t1, t2))

        var presence = discord.activities.last()
        assertTrue(presence.listening)
        assertEquals("Track t1", presence.details)
        assertEquals("Artist", presence.state)
        assertEquals("Album", presence.imageText)
        assertNotNull(presence.startSeconds, "audible playback runs the progress bar")

        val published = discord.activities.size
        h.service.pause()
        h.pump()
        assertEquals(1, discord.clears, "a paused session can sit in the mini-player for hours")
        assertEquals(published, discord.activities.size)

        h.service.play()
        h.pump()
        presence = discord.activities.last()
        assertEquals("Track t1", presence.details)
        assertNotNull(presence.startSeconds)

        h.player.emitTransition(urlFor(t2))
        h.pump()
        assertEquals("Track t2", discord.activities.last().details)

        h.service.stop()
        h.pump()
        assertEquals(2, discord.clears)
    }

    @Test
    fun aQueueThatPlaysOutWithdrawsTheCard() = musicTest {
        val data = musicData()
        data.deviceSettings.set(AppSettings.enableDiscordRpc, true)
        val discord = FakeDiscordHost()
        val h = MusicHarness(this, data = data, discord = discord)
        h.playTracks(listOf(t1))
        assertNotNull(discord.activities.last().startSeconds)
        val published = discord.activities.size

        h.player.emitCompleted()
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertTrue(discord.clears > 0)
        assertEquals(published, discord.activities.size)
    }

    // ---- Session restore ----------------------------------------------------------------------------------------

    private fun TestScope.restoreData() = musicData()

    private fun store(data: com.edde746.plezy.data.LocalData) = MusicSessionStore(data.musicSessions, "profile-1")

    private suspend fun seedParkedSession(data: com.edde746.plezy.data.LocalData, tracks: List<MediaItem>, cursor: Int = 0, position: Duration = Duration.ZERO) {
        store(data).save(
            MusicSessionSnapshot(
                MusicQueueState(tracks, tracks.indices.toList(), cursor, shuffled = false, repeatMode = MusicRepeatMode.OFF),
                MusicPlayContext("Album", MusicPlayContextKind.ALBUM),
                position,
            ),
        )
    }

    private suspend fun TestScope.playedAndPausedAt42(data: com.edde746.plezy.data.LocalData) {
        val first = MusicHarness(this, data = data, sessionStore = store(data))
        first.pump()
        first.playTracks(listOf(t1, t2, t3), startTrack = t2)
        first.player.setPosition(42.seconds)
        first.service.pause()
        first.pump()
        first.service.close()
        runCurrent()
    }

    @Test
    fun aPlayedSessionRestoresParkedPausedWithoutSpinningUpTheAudioCore() = musicTest {
        val data = restoreData()
        playedAndPausedAt42(data)

        val second = MusicHarness(this, data = data, sessionStore = store(data))
        second.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, second.state.status)
        assertEquals("t2", second.state.currentTrack?.id)
        assertEquals(listOf("t1", "t2", "t3"), second.state.queue.ids())
        assertEquals(1, second.state.currentIndex)
        assertEquals(42.seconds, second.service.position.value)
        assertEquals(MusicPlayContextKind.ALBUM, second.state.playContext?.kind)
        assertTrue(second.players.isEmpty(), "restore creates no player")
        assertTrue(second.resolver.resolveCounts.isEmpty(), "restore resolves no source")
    }

    @Test
    fun firstPlayOpensTheRestoredTrackAtThePersistedOffset() = musicTest {
        val data = restoreData()
        playedAndPausedAt42(data)

        val second = MusicHarness(this, data = data, sessionStore = store(data))
        second.pump()
        second.service.play()
        second.pump()

        assertEquals(1, second.players.size)
        assertEquals(listOf(urlFor(t2)), second.player.openedUris)
        assertEquals(listOf<Duration?>(42.seconds), second.player.openStarts)
        assertTrue(second.state.isPlaying)
    }

    @Test
    fun seekWhileParkedMovesTheResumePoint() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1, t2), position = 10.seconds)
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()
        assertEquals(10.seconds, h.service.position.value)

        h.service.seek(90.seconds)
        assertEquals(90.seconds, h.service.position.value)

        h.service.play()
        h.pump()
        assertEquals(listOf<Duration?>(90.seconds), h.player.openStarts)
    }

    @Test
    fun previousWhileParkedRestartsTheCurrentTrackFromTheTop() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1, t2), position = 100.seconds)
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()

        h.service.previous()
        h.pump()

        assertEquals(listOf(urlFor(t1)), h.player.openedUris)
        assertEquals(listOf<Duration?>(null), h.player.openStarts, "previous discards the resume offset")
    }

    @Test
    fun nextWhileParkedAdvancesAndPlaysTheFollowingTrackFromTheTop() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1, t2), position = 100.seconds)
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()

        h.service.next()
        h.pump()

        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t2)), h.player.openedUris)
        assertEquals(listOf<Duration?>(null), h.player.openStarts)
    }

    @Test
    fun aResumePointAtOrPastTheTracksEndRestoresAtItsStart() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1), position = TRACK_DURATION)
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()

        assertEquals(Duration.ZERO, h.service.position.value)
    }

    @Test
    fun aUserPlayRacingTheRestoreReadWins() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1), position = 30.seconds)

        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t2, t3))
        h.pump()

        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(listOf("t2", "t3"), h.ids)
    }

    @Test
    fun stopClearsThePersistedSession() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1, t2))
        h.pump()
        assertNotNull(store(data).load())

        h.service.stop()
        h.pump()
        assertNull(store(data).load())
    }

    @Test
    fun aProfileSwitchSavesAndEndsTheSessionThenBringsBackTheOtherProfilesParked() = musicTest {
        val data = restoreData()
        val other = MusicSessionStore(data.musicSessions, "profile-2")
        other.save(
            MusicSessionSnapshot(
                MusicQueueState(listOf(t3), listOf(0), 0, shuffled = false, repeatMode = MusicRepeatMode.OFF),
                MusicPlayContext("Other", MusicPlayContextKind.PLAYLIST),
                20.seconds,
            ),
        )
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1, t2))
        h.player.setPosition(30.seconds)
        val first = h.player

        h.service.switchProfile(other)
        h.pump()

        assertTrue(first.disposed, "the previous profile's audio core goes")
        assertEquals("t3", h.state.currentTrack?.id)
        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals(20.seconds, h.service.position.value)
        val kept = assertNotNull(store(data).load(), "the previous profile keeps its session for its next start")
        assertEquals(listOf("t1", "t2"), kept.queue.items.ids())
        assertEquals(30.seconds, kept.position)
    }

    @Test
    fun `a profile switch after a downloads only queue plays the other profiles saved queue online`() = musicTest {
        val data = restoreData()
        val other = MusicSessionStore(data.musicSessions, "profile-2")
        other.save(
            MusicSessionSnapshot(
                MusicQueueState(listOf(t3), listOf(0), 0, shuffled = false, repeatMode = MusicRepeatMode.OFF),
                MusicPlayContext("Other", MusicPlayContextKind.PLAYLIST),
                Duration.ZERO,
            ),
        )
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.service.playFromList(listOf(t1, t2), null, MusicPlayContext("Downloads", MusicPlayContextKind.ALBUM), shuffle = false, initialPosition = null, offline = true)
        h.pump()

        h.service.switchProfile(other)
        h.pump()
        h.service.play()
        h.pump()

        assertEquals("t3" to false, h.resolver.resolves.last())
    }

    // ---- Progress reports -----------------------------------------------------------------------------------------

    @Test
    fun aDownloadedTrackPlayedOfflineQueuesItsProgressForTheNextSync() = musicTest {
        val h = MusicHarness(this)
        h.resolver.reporting["t1"] = com.edde746.plezy.playback.source.PlaybackReportingMode.OFFLINE_QUEUE
        h.playTracks(listOf(t1, t2))
        h.player.setPosition(42.seconds)

        h.service.next()
        h.pump()

        assertTrue(h.backend.reports.none { it.itemId == "t1" }, "nothing reaches the server")
        assertEquals("t1" to 42_000L, h.offlineQueued.last())
    }

    @Test
    fun aTrackWhoseServerTakesNoReportsReportsNothing() = musicTest {
        val h = MusicHarness(this)
        h.resolver.reporting["t1"] = com.edde746.plezy.playback.source.PlaybackReportingMode.DISABLED
        h.playTracks(listOf(t1))
        h.service.stop()
        h.pump()

        assertTrue(h.backend.reports.isEmpty())
        assertTrue(h.offlineQueued.isEmpty())
    }

    @Test
    fun restoreIsSkippedWhenTheSettingIsOff() = musicTest {
        val data = restoreData()
        data.deviceSettings.set(AppSettings.resumeMusicOnLaunch, false)
        seedParkedSession(data, listOf(t1))

        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()

        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
    }

    // ---- Apple passthrough --------------------------------------------------------------------------------------

    @Test
    fun anAppleMusicPlayerStartsOnTheSystemDolbyDecoderBeforeItsFirstOpen() = musicTest {
        val data = musicData()
        data.deviceSettings.set(AppSettings.audioPassthrough, true)
        val h = MusicHarness(this, data = data, appleAudioOutput = true)
        h.playTracks(listOf(t1, t2))

        assertEquals(listOf(urlFor(t1)), h.player.openedUris)
        assertEquals(listOf(true to 0), h.player.passthroughWrites)
    }

    @Test
    fun musicStaysDecodedWhenTheSettingIsOffNormalizationOverridesItOrTheOutputIsNotApple() = musicTest {
        for ((passthrough, normalization, apple) in listOf(Triple(false, false, true), Triple(true, true, true), Triple(true, false, false))) {
            val data = musicData()
            data.deviceSettings.set(AppSettings.audioPassthrough, passthrough)
            data.deviceSettings.set(AppSettings.audioNormalization, normalization)
            val h = MusicHarness(this, data = data, appleAudioOutput = apple)
            h.playTracks(listOf(t1))

            assertEquals(listOf(urlFor(t1)), h.player.openedUris)
            assertTrue(h.player.passthroughWrites.isEmpty(), "passthrough=$passthrough normalization=$normalization apple=$apple")
        }
    }

    @Test
    fun eachOpenTakesTheDebugLoggingSettingAsItIsThen() = musicTest {
        val data = musicData()
        data.deviceSettings.set(AppSettings.enableDebugLogging, true)
        val h = MusicHarness(this, data = data)
        h.playTracks(listOf(t1))
        data.deviceSettings.set(AppSettings.enableDebugLogging, false)
        h.playTracks(listOf(t2))

        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
        assertEquals(listOf(true to 0, false to 1), h.player.verboseWrites)
    }

    @Test
    fun theVideoPlayersOutputPickReachesTheMusicPlayerBeforeItsFirstOpen() = musicTest {
        val data = musicData()
        data.deviceSettings.set(AppSettings.audioOutputDevice, "coreaudio/BuiltInSpeakerDevice")
        val h = MusicHarness(this, data = data)
        h.playTracks(listOf(t1))

        assertEquals(listOf("coreaudio/BuiltInSpeakerDevice"), h.player.audioDevices)
    }

    // ---- Apple TV -----------------------------------------------------------------------------------------------

    @Test
    fun appleTvPausesMusicWhenTheAppGoesToTheBackground() = musicTest {
        val h = MusicHarness(this, formFactor = FormFactor.TV, appleAudioOutput = true)
        h.playTracks(listOf(t1))

        h.foreground.value = false
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
    }

    @Test
    fun otherDevicesKeepMusicPlayingInTheBackground() = musicTest {
        for ((formFactor, apple) in listOf(FormFactor.TV to false, FormFactor.HANDHELD to true)) {
            val h = MusicHarness(this, formFactor = formFactor, appleAudioOutput = apple)
            h.playTracks(listOf(t1))

            h.foreground.value = false
            h.pump()

            assertEquals(MusicPlaybackStatus.PLAYING, h.state.status, "$formFactor apple=$apple")
        }
    }

    // ---- Session state ------------------------------------------------------------------------------------------

    @Test
    fun isPlayingFollowsThePlayingStatusAndThePlayheadNeverRepublishesTheState() = musicTest {
        val h = MusicHarness(this)
        assertFalse(h.state.isPlaying)
        assertEquals(-1, h.state.currentIndex, "idle has no current entry")
        val states = mutableListOf<MusicState>()
        backgroundScope.launch { h.service.state.collect { states += it } }
        runCurrent()

        h.playTracks(listOf(t1, t2))
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertTrue(h.state.isPlaying)
        val before = h.state
        val published = states.size

        h.player.setPosition(10.seconds)
        h.pump()
        h.player.setPosition(20.seconds)
        h.pump()
        assertEquals(20.seconds, h.service.position.value)
        assertSame(before, h.state, "progress goes through the position stream only")
        assertEquals(published, states.size)

        h.service.pause()
        h.pump()
        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertFalse(h.state.isPlaying)
    }

    @Test
    fun anArtistQueueKeepsItsTitleAndALooseTrackListFollowsTheAlbum() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()

        h.service.playFromList(listOf(t1, t2), null, MusicPlayContext("The Artist", MusicPlayContextKind.ARTIST))
        h.pump()
        assertEquals(MusicPlayContext("The Artist", MusicPlayContextKind.ARTIST), h.state.playContext)
        assertEquals("The Artist", playingFromTitle(t1, h.state.playContext))
        assertEquals("artist", data.musicSessions.load("profile-1")?.contextKind)

        h.service.playFromList(listOf(t3), null, MusicPlayContext("Search", MusicPlayContextKind.TRACKS))
        h.pump()
        assertEquals(MusicPlayContext("Search", MusicPlayContextKind.TRACKS), h.state.playContext)
        assertEquals("Album", playingFromTitle(t3, h.state.playContext))
        assertEquals("tracks", data.musicSessions.load("profile-1")?.contextKind)
    }

    // ---- Session start and the open -----------------------------------------------------------------------------

    @Test
    fun anEmptyListStartsNothingAndLeavesALiveQueueAlone() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(emptyList())
        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
        assertTrue(h.players.isEmpty())

        h.playTracks(listOf(t1, t2))
        h.playTracks(emptyList())
        assertEquals("t1", h.state.currentTrack?.id)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals(listOf(urlFor(t1)), h.player.openedUris)
    }

    @Test
    fun theStartTrackIsMatchedByServerAndIdNotByIdAlone() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2), startTrack = track("t2", serverId = "other"))
        assertEquals("t1", h.state.currentTrack?.id)

        h.playTracks(listOf(t1, t2), startTrack = track("t2"))
        assertEquals("t2", h.state.currentTrack?.id)
    }

    @Test
    fun aNewQueueSavesItsWholeSnapshotAtTheTopAndDropsAPendingResume() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1), position = 30.seconds)
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()
        assertEquals(30.seconds, h.service.position.value)

        h.service.playFromList(listOf(t1, t2, t3), t1, MusicPlayContext("Mixtape", MusicPlayContextKind.PLAYLIST))
        h.pump()

        assertEquals(listOf<Duration?>(null), h.player.openStarts, "the restored offset belongs to the restored session")
        val saved = assertNotNull(store(data).load())
        assertEquals(listOf("t1", "t2", "t3"), saved.queue.items.ids())
        assertEquals(0, saved.queue.cursor)
        assertEquals(Duration.ZERO, saved.position)
        assertEquals(MusicPlayContext("Mixtape", MusicPlayContextKind.PLAYLIST), saved.playContext)
    }

    @Test
    fun aNewQueueStartsWithNoFailureStrikes() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2, t3, track("t4")))
        h.player.emitError("boom")
        h.pump()
        h.player.emitError("boom")
        h.pump()
        assertEquals("t3", h.state.currentTrack?.id)

        h.playTracks(listOf(t1, t2))
        h.player.emitError("boom")
        h.pump()

        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals("t2", h.state.currentTrack?.id)
    }

    @Test
    fun anOpenClearsTheStaleArmThenResolvesThenOpensPlayingThenArmsTheNext() = musicTest {
        val h = MusicHarness(this)
        val statuses = mutableListOf<MusicPlaybackStatus>()
        backgroundScope.launch { h.service.state.collect { statuses += it.status } }
        runCurrent()
        val resolve = h.resolver.gateNextResolve(t1.id)

        val start = launch { h.playTracks(listOf(t1, t2)) }
        runCurrent()
        assertTrue(resolve.entered.isCompleted)
        assertEquals(MusicPlaybackStatus.LOADING, h.state.status)
        assertEquals(listOf<String?>(null), h.player.setNextCalls.map { it?.uri })
        assertTrue(h.player.openedUris.isEmpty())

        resolve.release()
        start.join()
        assertEquals(listOf(urlFor(t1)), h.player.openedUris)
        assertTrue(h.player.state.playing)
        assertEquals(listOf(urlFor(t2)), h.player.setNextCalls.mapNotNull { it?.uri }, "the arm comes after the open")
        assertEquals(urlFor(t2), h.player.armed?.uri)
        assertEquals(listOf(MusicPlaybackStatus.IDLE, MusicPlaybackStatus.LOADING, MusicPlaybackStatus.PLAYING), statuses.distinct())
    }

    @Test
    fun aQueueReplacedWhileItsSourceResolvesNeverOpensTheOldTrack() = musicTest {
        val h = MusicHarness(this)
        val errors = mutableListOf<Throwable>()
        backgroundScope.launch { h.service.errors.collect { errors += it } }
        val resolve = h.resolver.gateNextResolve(t1.id)
        val first = launch { h.playTracks(listOf(t1)) }
        runCurrent()

        h.playTracks(listOf(t3))
        resolve.release()
        first.join()
        h.pump()

        assertEquals(listOf(urlFor(t3)), h.player.openedUris)
        assertEquals("t3", h.state.currentTrack?.id)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertTrue(errors.isEmpty())
    }

    @Test
    fun anInstantMixWithoutItsServerOrWithAFailedFetchThrowsAndLeavesTheErrorsStreamAlone() = musicTest {
        val h = MusicHarness(this)
        val errors = mutableListOf<Throwable>()
        backgroundScope.launch { h.service.errors.collect { errors += it } }
        runCurrent()

        val noServer = assertFailsWith<PlaybackException> { h.service.playInstantMix(track("seed", serverId = "gone")) }
        assertEquals(T.music.instantMixNoServer, noServer.message)
        assertEquals(PlaybackFailureReason.SERVER_UNAVAILABLE, noServer.reason)

        h.backend.instantMixGate = CompletableDeferred<List<MediaItem>>().apply { completeExceptionally(IllegalStateException("mix fetch failed")) }
        val failed = assertFailsWith<IllegalStateException> { h.service.playInstantMix(t1) }
        assertEquals("mix fetch failed", failed.message)
        h.pump()

        assertTrue(errors.isEmpty())
        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
    }

    // ---- Gapless arm ------------------------------------------------------------------------------------------

    @Test
    fun theArmFollowsShuffleAndSleepModeChangesAndClearsAtTheQueueEnd() = musicTest {
        val h = MusicHarness(this, random = LowestRandom)
        h.playTracks(listOf(t1, t2, t3))
        assertEquals(urlFor(t2), h.player.armed?.uri)

        h.service.toggleShuffle()
        h.pump()
        assertEquals(listOf("t1", "t3", "t2"), h.ids)
        assertEquals(urlFor(t3), h.player.armed?.uri)

        h.service.setSleepTimer(null, endOfTrack = true)
        h.pump()
        assertNull(h.player.armed)
        h.service.setSleepTimer(null)
        h.pump()
        assertEquals(urlFor(t3), h.player.armed?.uri)

        h.service.clearUpcoming()
        h.pump()
        assertNull(h.player.armed)
        assertNull(h.player.setNextCalls.last())
    }

    @Test
    fun aPlayedOutQueueSavesItsLastTrackAtTheTop() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1, t2), startTrack = t2)
        h.player.setPosition(100.seconds)
        h.pump()
        assertEquals(100.seconds, store(data).load()?.position)

        h.player.emitCompleted()
        h.pump()

        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        val saved = assertNotNull(store(data).load())
        assertEquals(1, saved.queue.cursor)
        assertEquals(Duration.ZERO, saved.position)
    }

    // ---- Transport ----------------------------------------------------------------------------------------------

    @Test
    fun playAndToggleWithoutATrackDoNothing() = musicTest {
        val h = MusicHarness(this)
        h.service.play()
        h.service.togglePlayPause()
        h.pump()

        assertTrue(h.players.isEmpty())
        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
    }

    @Test
    fun toggleOpensARestoredSessionThenFlipsBetweenPauseAndPlay() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1, t2), position = 10.seconds)
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()
        assertTrue(h.players.isEmpty())

        h.service.togglePlayPause()
        h.pump()
        assertEquals(listOf(urlFor(t1)), h.player.openedUris)
        assertEquals(listOf<Duration?>(10.seconds), h.player.openStarts)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)

        h.service.togglePlayPause()
        h.pump()
        assertEquals(MusicPlaybackStatus.PAUSED, h.state.status)
        assertEquals(1, h.player.pauseCalls)

        h.service.togglePlayPause()
        h.pump()
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertEquals(1, h.player.playCalls)
    }

    @Test
    fun nextReportsTheTrackStoppedWhereItIsAndOpensTheFollowingOneFromTheTop() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1, t2, t3))
        h.player.setPosition(42.seconds)

        h.service.next()
        h.pump()
        val stopped = h.backend.reportsFor("stopped").single()
        assertEquals("t1", stopped.itemId)
        assertEquals(42.seconds, stopped.position)
        assertEquals("t2", h.state.currentTrack?.id)
        assertEquals(listOf<Duration?>(null, null), h.player.openStarts)
        val saved = assertNotNull(store(data).load())
        assertEquals(1, saved.queue.cursor)
        assertEquals(Duration.ZERO, saved.position)

        h.service.jumpTo(2)
        h.pump()
        h.service.setRepeatMode(MusicRepeatMode.ONE)
        h.service.next()
        h.pump()
        assertEquals("t3", h.state.currentTrack?.id, "no manual next at the end without repeat-all")
        assertEquals(3, h.player.openedUris.size)

        h.service.setRepeatMode(MusicRepeatMode.ALL)
        h.service.next()
        h.pump()
        assertEquals("t1", h.state.currentTrack?.id)
        assertEquals(0, h.state.currentIndex)
    }

    @Test
    fun previousAtTheQueueHeadRestartsAndWrapsUnderRepeatAll() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        h.player.setPosition(1.seconds)

        h.service.previous()
        h.pump()
        assertEquals(listOf(Duration.ZERO), h.player.seeks)
        assertEquals("t1", h.state.currentTrack?.id)
        assertEquals(listOf(urlFor(t1)), h.player.openedUris)

        h.service.setRepeatMode(MusicRepeatMode.ALL)
        h.player.setPosition(3.seconds)
        h.service.previous()
        h.pump()
        assertEquals("t2", h.state.currentTrack?.id, "3 s exactly still steps back")
        assertEquals(listOf(urlFor(t1), urlFor(t2)), h.player.openedUris)
    }

    @Test
    fun aParkedSeekIsClampedToTheTrackAndSaved() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1, t2), position = 10.seconds)
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()
        val positions = mutableListOf<Duration>()
        backgroundScope.launch { h.service.position.collect { positions += it } }
        runCurrent()

        h.service.seek(10.minutes)
        h.pump()
        assertEquals(TRACK_DURATION, positions.last())
        assertEquals(TRACK_DURATION, store(data).load()?.position)

        h.service.seek((-5).seconds)
        h.pump()
        assertEquals(Duration.ZERO, positions.last())
        assertEquals(Duration.ZERO, store(data).load()?.position)
        assertTrue(h.players.isEmpty())
    }

    @Test
    fun remoteAndHardwareSkipsStepFifteenSecondsClampedToTheTrack() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))

        h.player.setPosition(5.seconds)
        h.system.press(MusicKey.REWIND)
        h.pump()
        assertEquals(Duration.ZERO, h.player.seeks.last())

        h.player.setPosition(TRACK_DURATION - 5.seconds)
        h.system.press(MusicKey.FAST_FORWARD)
        h.pump()
        assertEquals(TRACK_DURATION, h.player.seeks.last())

        h.player.setPosition(30.seconds)
        h.system.press(MusicKey.FAST_FORWARD)
        h.pump()
        assertEquals(45.seconds, h.player.seeks.last())
        h.system.press(MusicKey.REWIND)
        h.pump()
        assertEquals(30.seconds, h.player.seeks.last())
    }

    @Test
    fun osSkipsUseTheIntervalTheOsSendsAndSpeedChangesAreIgnored() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))
        h.player.setPosition(30.seconds)
        h.pump()
        val before = h.state

        h.controls.send(MediaCommand.SetSpeed(2.0))
        h.pump()
        assertSame(before, h.state)
        assertTrue(h.player.seeks.isEmpty())
        assertEquals(1.0, h.controls.last.rate)

        h.controls.send(MediaCommand.SeekBy(30.0))
        h.pump()
        assertEquals(60.seconds, h.player.seeks.last())
        h.controls.send(MediaCommand.SeekBy(-10.0))
        h.pump()
        assertEquals(50.seconds, h.player.seeks.last())
    }

    @Test
    fun anOsCommandArrivingAfterTheSessionEndedIsIgnored() = musicTest {
        var handler: MediaCommandHandler? = null
        val host = object : MediaControlsHost {
            override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) {
                handler = commands
            }

            override fun hide() {}
        }
        val players = mutableListOf<FakeAudioPlayer>()
        val service = MusicPlaybackService(
            scope = backgroundScope,
            audioPlayerFactory = { FakeAudioPlayer().also { players += it } },
            resolver = FakeMusicSourceResolver(null),
            clients = { null },
            settings = musicData().deviceSettings,
            coordinator = PlaybackCoordinator(),
            foreground = MutableStateFlow(true),
            formFactor = FormFactor.HANDHELD,
            appleAudioOutput = false,
            controls = host,
            timeSource = testScheduler.timeSource,
            completedConfirmDelay = Duration.ZERO,
        )
        service.playFromList(listOf(t1, t2), null, MusicPlayContext("Test", MusicPlayContextKind.ALBUM))
        runCurrent()
        val stale = assertNotNull(handler)
        service.stop()
        runCurrent()

        for (command in listOf(MediaCommand.Play, MediaCommand.TogglePause, MediaCommand.Next, MediaCommand.Previous, MediaCommand.SeekBy(15.0))) {
            stale.perform(command)
        }
        runCurrent()

        assertEquals(MusicPlaybackStatus.IDLE, service.state.value.status)
        assertEquals(1, players.size)
        assertEquals(0, players.single().playCalls)
        assertTrue(players.single().seeks.isEmpty())
        assertEquals(listOf(urlFor(t1)), players.single().openedUris)
    }

    // ---- Session end ------------------------------------------------------------------------------------------

    @Test
    fun stopEndsTheSleepTimerWithTheSessionAndStopsThePlayerBeforeDisposingIt() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1))
        h.service.setSleepTimer(15.minutes)
        val player = h.player

        h.service.stop()
        h.pump()
        assertEquals(1, player.stopCalls)
        assertTrue(player.disposed)
        assertFalse(h.state.sleepTimerActive)
        assertEquals(-1, h.state.currentIndex)

        h.playTracks(listOf(t2))
        advanceTimeBy(16.minutes)
        runCurrent()
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status, "the ended session's timer went with it")
    }

    @Test
    fun stoppingARestoredSessionForgetsItsResumePointAndTheSavedRow() = musicTest {
        val data = restoreData()
        seedParkedSession(data, listOf(t1, t2), position = 30.seconds)
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.pump()
        assertEquals("t1", h.state.currentTrack?.id)

        h.service.stop()
        h.service.play()
        h.pump()

        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
        assertNull(h.state.playContext)
        assertTrue(h.players.isEmpty())
        assertNull(store(data).load())
    }

    @Test
    fun claimVideoStopsTheAudioCoreBeforeDisposingItAndForgetsTheSavedSession() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1, t2))
        h.pump()
        assertNotNull(store(data).load())
        val player = h.player

        h.coordinator.claimVideo()
        h.pump()

        assertEquals(1, player.stopCalls)
        assertTrue(player.disposed)
        assertNull(store(data).load())
    }

    @Test
    fun aFailureWithNoNextTrackStopsTheSessionWithAnErrorAndForgetsTheSavedSession() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1))
        h.pump()
        assertNotNull(store(data).load())
        val errors = mutableListOf<Throwable>()
        backgroundScope.launch { h.service.errors.collect { errors += it } }
        runCurrent()

        h.player.emitError("boom")
        h.pump()
        assertEquals(1, errors.size)
        assertEquals(MusicPlaybackStatus.ERROR, h.state.status)
        assertNull(h.state.currentTrack)
        assertTrue(h.state.queue.isEmpty())
        assertTrue(h.players.single().disposed)
        assertNull(store(data).load())

        h.player.emitError("again")
        h.pump()
        assertEquals(1, errors.size, "an ended session takes no more errors")
        assertEquals(MusicPlaybackStatus.ERROR, h.state.status)
    }

    @Test
    fun removingTheOnlyTrackStopsTheSession() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1))
        h.pump()
        val player = h.player

        h.service.removeAt(0)
        h.pump()

        assertEquals(MusicPlaybackStatus.IDLE, h.state.status)
        assertNull(h.state.currentTrack)
        assertTrue(player.disposed)
        assertNull(store(data).load())
    }

    // ---- Volume, queue edits and reports ------------------------------------------------------------------------

    @Test
    fun theMusicVolumeIsClampedIndependentOfVideoAndFullVolumeIsNeverSentToANewPlayer() = musicTest {
        val data = musicData()
        data.deviceSettings.set(AppSettings.volume, 30.0)
        val h = MusicHarness(this, data = data)
        h.playTracks(listOf(t1))
        assertEquals(100.0, h.state.volume)
        assertTrue(h.player.volumes.isEmpty())

        h.service.setVolume(-20.0)
        assertEquals(0.0, h.state.volume)
        h.service.setVolume(250.0)
        assertEquals(100.0, h.state.volume)
        assertEquals(listOf(0.0, 100.0), h.player.volumes)
    }

    @Test
    fun addingToASingleTrackQueueArmsItSavesItAndOffersNext() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1))
        h.pump()
        assertNull(h.player.armed)
        assertFalse(h.state.canGoNext)
        assertFalse(h.controls.last.canSkipNext)

        h.service.addToEnd(listOf(t2))
        h.pump()

        assertEquals(urlFor(t2), h.player.armed?.uri)
        assertEquals(listOf("t1", "t2"), h.ids)
        assertTrue(h.state.canGoNext)
        assertTrue(h.controls.last.canSkipNext)
        assertEquals(listOf("t1", "t2"), store(data).load()?.queue?.items?.ids())
    }

    @Test
    fun pausingAndResumingReportPausedThenPlayingForTheCurrentTrack() = musicTest {
        val h = MusicHarness(this)
        h.playTracks(listOf(t1, t2))

        h.service.pause()
        h.pump()
        assertEquals(listOf("t1"), h.backend.reportsFor("paused").map { it.itemId })

        h.service.play()
        h.pump()
        assertEquals("t1", h.backend.reports.last().itemId)
        assertEquals("progress", h.backend.reports.last().state)
    }

    // ---- Session persistence ------------------------------------------------------------------------------------

    @Test
    fun theWholeSnapshotIsRewrittenOnlyOnShapeAndModeChangesWhileProgressMovesTheCursorAndPlayhead() = musicTest {
        val data = restoreData()
        val h = MusicHarness(this, data = data, sessionStore = store(data))
        h.playTracks(listOf(t1, t2, t3))
        h.pump()
        suspend fun row() = assertNotNull(data.musicSessions.load("profile-1"))

        // A full save rewrites the context; a progress write leaves this marker in place.
        suspend fun mark() = data.musicSessions.save(row().copy(contextTitle = "marker"))
        assertEquals("Test", row().contextTitle, "the session start saves in full")
        mark()

        h.player.emitTransition(urlFor(t2))
        h.pump()
        assertEquals("marker", row().contextTitle)
        assertEquals(1, row().cursor)
        assertEquals(0L, row().positionMs)

        h.player.setOutgoingPlayhead(42.seconds, TRACK_DURATION)
        h.service.pause()
        h.pump()
        assertEquals(42_000L, row().positionMs, "a pause flushes the playhead")

        h.service.play()
        h.player.setPosition(50.seconds)
        h.pump()
        assertEquals(50_000L, row().positionMs)
        h.player.setPosition(52.seconds)
        h.pump()
        assertEquals(50_000L, row().positionMs, "ticks are throttled")
        advanceTimeBy(5.seconds)
        h.player.setPosition(57.seconds)
        h.pump()
        assertEquals(57_000L, row().positionMs)

        h.player.setOutgoingPlayhead(61.seconds, TRACK_DURATION)
        h.foreground.value = false
        h.pump()
        assertEquals(61_000L, row().positionMs, "backgrounding flushes the playhead")
        h.foreground.value = true
        h.pump()
        assertEquals("marker", row().contextTitle)

        h.service.setRepeatMode(MusicRepeatMode.ALL)
        h.pump()
        assertEquals("Test", row().contextTitle)
        assertEquals("all", row().repeatMode)
        mark()
        h.service.toggleShuffle()
        h.pump()
        assertEquals("Test", row().contextTitle)
        assertTrue(row().shuffled)
        mark()
        h.service.addToEnd(listOf(track("t4")))
        h.pump()
        assertEquals("Test", row().contextTitle)

        mark()
        h.player.setOutgoingPlayhead(70.seconds, TRACK_DURATION)
        h.service.close()
        runCurrent()
        assertEquals(70_000L, row().positionMs, "closing flushes the playhead")
        assertEquals("marker", row().contextTitle)
    }
}
