package com.edde746.plezy.music

import com.edde746.plezy.presentation.player.MediaCommand
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Android Automotive: the vehicle's restrictions (or, while it can't answer, the app being in front) decide whether
 * music may sound (DD-2); a parked car keeps background audio; parking resumes only what driving stopped.
 */
class MusicPlaybackAutomotiveTest {
    private val one = track("one")
    private val two = track("two")

    private class Car(
        val test: TestScope,
        answer: CarRestrictionState? = null,
        foreground: Boolean = true,
        configure: FakeCarSource.() -> Unit = {},
    ) {
        val source = FakeCarSource(answer).apply(configure)
        val h = MusicHarness(test, car = source, foreground = kotlinx.coroutines.flow.MutableStateFlow(foreground))
        val player get() = h.player

        /** What the controls last told the OS about background playback. */
        val backgroundPlayback get() = h.controls.shows.map { it.backgroundPlayback }

        suspend fun start(vararg tracks: com.edde746.plezy.model.MediaItem) = h.playTracks(tracks.toList())

        fun drive() = h.pushAndPump(FakeCarSource.DRIVING)
        fun park() = h.pushAndPump(FakeCarSource.PARKED)
        fun serviceGone() = h.pushAndPump(FakeCarSource.GONE)

        fun MusicHarness.pushAndPump(state: CarRestrictionState) {
            source.push(state)
            pump()
        }

        fun foreground(inFront: Boolean) {
            h.foreground.value = inFront
            h.pump()
        }
    }

    @Test
    fun anOpenThatBeatsTheVehicleAnswerStillEndsUpWithBackgroundAudioOn() = runTest {
        val car = Car(this, FakeCarSource.PARKED) { answerGate = CompletableDeferred() }
        // The service asked at construction: the answer is held until released.
        val started = launch { car.start(one) }
        runCurrent()
        assertTrue(car.h.players.isEmpty(), "the open waits for the vehicle")

        car.source.releaseAnswers()
        started.join()
        car.h.pump()

        assertTrue(car.backgroundPlayback.last())
        assertTrue(car.player.state.playing)
    }

    @Test
    fun aVehicleAnswerArrivingAfterTheOpenReconfiguresTheLiveSession() = runTest {
        val car = Car(this) { neverAnswer = true }
        car.start(one)
        // The open spent the whole wait budget on a silent car and fell back.
        testScheduler.advanceUntilIdle()
        assertFalse(car.backgroundPlayback.last(), "no verdict yet: stay conservative")

        car.park()

        assertTrue(car.backgroundPlayback.last(), "the live session is reconfigured")
    }

    @Test
    fun aSessionOpenedWhileTheCarServiceIsStillConnectingStillGetsBackgroundAudio() = runTest {
        val car = Car(this, FakeCarSource.CONNECTING)
        val started = launch { car.start(one) }
        runCurrent()
        assertTrue(car.h.players.isEmpty(), "the open waits for the promised verdict")

        car.source.push(FakeCarSource.PARKED)
        started.join()
        car.h.pump()

        assertTrue(car.backgroundPlayback.last())
        assertTrue(car.player.state.playing)
    }

    @Test
    fun aParkedVehicleKeepsMusicPlayingWhileTheAppIsBackgrounded() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        assertTrue(car.player.state.playing)

        car.foreground(false)

        assertTrue(car.player.state.playing)
        assertEquals(MusicPlaybackStatus.PLAYING, car.h.state.status)
        assertTrue(true in car.backgroundPlayback)
    }

    @Test
    fun aDrivingVehicleStopsMusicAndParkingAgainResumesIt() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)

        car.drive()
        car.foreground(false)
        assertFalse(car.player.state.playing, "DD-2: driving stops audio")

        car.park()
        car.foreground(true)
        assertTrue(car.player.state.playing, "parking again resumes what driving stopped")
    }

    @Test
    fun aPauseTakenDuringTheDriveIsNotUndoneByParking() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        car.drive()
        assertFalse(car.player.state.playing)

        car.h.service.pause()
        car.park()

        assertFalse(car.player.state.playing, "parking must not restart what someone stopped")
    }

    @Test
    fun aCarServiceRestartDoesNotSilenceABackgroundTrackForGood() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        car.foreground(false)
        assertTrue(car.player.state.playing, "parked background audio")

        car.serviceGone()
        assertFalse(car.player.state.playing, "no verdict: the background fallback stops it")

        car.park()
        assertTrue(car.player.state.playing, "a transient service restart isn't permanent")
    }

    @Test
    fun foregroundingDuringACarServiceOutageDoesNotForgetWhoPaused() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        car.foreground(false)
        car.serviceGone()
        assertFalse(car.player.state.playing)

        car.foreground(true)
        assertFalse(car.player.state.playing, "regaining focus is not a request to play")

        car.park()
        assertTrue(car.player.state.playing)
    }

    @Test
    fun aRestrictionLandingMidResumeDoesNotStrandTheTrackPaused() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        car.drive()
        assertFalse(car.player.state.playing)

        val playGate = CompletableDeferred<Unit>()
        car.player.playGate = playGate
        car.park()
        car.drive()
        car.player.playGate = null
        playGate.complete(Unit)
        car.h.pump()
        assertFalse(car.player.state.playing, "driving again: it must not play")

        car.park()
        assertTrue(car.player.state.playing, "the car still owns this pause")
    }

    @Test
    fun parkingDoesNotStartAQueueTheUserNeverPlayed() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        car.drive()
        assertFalse(car.player.state.playing)

        car.h.service.stop()
        car.h.service.addToEnd(listOf(two))
        car.h.pump()
        assertFalse(car.h.players.last().state.playing)

        car.park()

        assertFalse(car.h.players.last().state.playing, "the car never stopped this queue")
        assertNotEquals(MusicPlaybackStatus.PLAYING, car.h.state.status)
    }

    @Test
    fun oneDrivingTransitionPausesOnceHoweverManyTimesItIsReported() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        val pausesBefore = car.player.pauseCalls
        val pauseGate = CompletableDeferred<Unit>()
        car.player.pauseGate = pauseGate

        car.drive()
        car.foreground(false)
        assertEquals(1, car.player.pauseCalls - pausesBefore, "the pause in flight is the one that lands")

        car.player.pauseGate = null
        pauseGate.complete(Unit)
        car.h.pump()
        assertFalse(car.player.state.playing)
    }

    @Test
    fun aLiftArrivingWhileTheRestrictionPauseIsInFlightStillResumes() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        val pauseGate = CompletableDeferred<Unit>()
        car.player.pauseGate = pauseGate

        car.drive()
        car.park()
        car.player.pauseGate = null
        pauseGate.complete(Unit)
        car.h.pump()

        assertTrue(car.player.state.playing, "a pause landing after the lift must not leave a parked car silent")
    }

    @Test
    fun aVehicleThatCannotReportRestrictionsKeepsTheConservativeOptOut() = runTest {
        val car = Car(this)
        car.start(one)

        assertFalse(true in car.backgroundPlayback)
    }

    @Test
    fun playIsRefusedWhileTheAppIsInTheBackgroundOfACarThatCannotAnswer() = runTest {
        val car = Car(this, foreground = false)
        car.start(one)
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
        assertFalse(car.player.state.playing)

        car.h.service.play()

        assertEquals(0, car.player.playCalls)
        assertFalse(car.player.state.playing)
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
        assertTrue(car.player.setNextCalls.all { it == null })
    }

    @Test
    fun aMediaSessionPlayIsRefusedWhileTheAppIsInTheBackgroundOfACarThatCannotAnswer() = runTest {
        val car = Car(this, foreground = false)
        car.start(one)

        car.h.controls.send(MediaCommand.Play)
        car.h.pump()

        assertEquals(0, car.player.playCalls)
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
    }

    @Test
    fun deniedNextAndPreviousAreConsumedWithoutEffectWhileRestricted() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one, two)
        car.drive()

        car.h.controls.send(MediaCommand.Next)
        car.h.controls.send(MediaCommand.Previous)
        car.h.pump()

        assertEquals("one", car.h.state.currentTrack?.id)
        assertEquals(1, car.player.openedUris.size)
    }

    @Test
    fun backgroundPlaybackIsOffOnACarThatCannotAnswer() = runTest {
        val car = Car(this, foreground = false)
        car.start(one)

        assertTrue(car.backgroundPlayback.isNotEmpty())
        assertTrue(car.backgroundPlayback.none { it })
    }

    @Test
    fun playbackRemainsUnrestrictedOffACar() = runTest {
        val h = MusicHarness(this, foreground = kotlinx.coroutines.flow.MutableStateFlow(false))
        h.playTracks(listOf(one))
        assertTrue(h.player.state.playing)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
        assertTrue(h.controls.shows.all { it.backgroundPlayback })

        h.service.pause()
        h.service.play()
        h.pump()

        assertEquals(1, h.player.playCalls)
        assertEquals(MusicPlaybackStatus.PLAYING, h.state.status)
    }

    @Test
    fun theBackgroundFallbackPausesAndClearsTheGaplessArm() = runTest {
        val car = Car(this)
        car.start(one, two)
        assertEquals(urlFor(two), car.player.armed?.uri)

        car.foreground(false)

        assertTrue(car.player.pauseCalls >= 1)
        assertNull(car.player.armed)
        assertFalse(car.player.state.playing)
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
    }

    @Test
    fun aTransitionRacingTheCarPauseIsAdoptedButCannotKeepPlaying() = runTest {
        val car = Car(this)
        car.start(one, two)

        car.h.foreground.value = false
        car.player.emitTransition(urlFor(two))
        car.h.pump()

        assertEquals("two", car.h.state.currentTrack?.id)
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
        assertFalse(car.player.state.playing)
        assertNull(car.player.armed)
    }

    @Test
    fun aMediaSessionStopRemainsUnconditionalWhileRestricted() = runTest {
        val car = Car(this, foreground = false)
        car.start(one)

        car.h.controls.send(MediaCommand.Stop)
        car.h.pump()

        assertEquals(MusicPlaybackStatus.IDLE, car.h.state.status)
        assertNull(car.h.state.currentTrack)
        assertEquals(1, car.player.stopCalls)
    }

    @Test
    fun theGaplessArmIsRestoredOnceRestrictionsLift() = runTest {
        val car = Car(this)
        car.start(one, two)
        car.foreground(false)
        assertNull(car.player.armed)

        car.foreground(true)

        assertEquals(urlFor(two), car.player.armed?.uri, "gapless survives a park-and-resume")
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status, "but parking doesn't restart audio by itself")
        assertFalse(car.player.state.playing)
    }

    @Test
    fun drivingSilencesAudioStillPlayingWhileTheNextSourceResolves() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one, two)
        assertTrue(car.player.state.playing)

        car.h.resolver.gate = CompletableDeferred()
        car.h.system.press(MusicKey.NEXT)
        car.h.pump()
        assertEquals(MusicPlaybackStatus.LOADING, car.h.state.status)
        assertTrue(car.player.state.playing, "the old track still sounds")

        car.drive()
        car.foreground(false)
        assertFalse(car.player.state.playing, "DD-2: driving stops audio, resolver or not")

        car.h.resolver.gate?.complete(Unit)
        car.h.pump()
    }

    @Test
    fun aMediaSessionPauseStillStopsAudioWhileRestricted() = runTest {
        val car = Car(this)
        car.start(one)
        car.foreground(false)
        val pauses = car.player.pauseCalls

        car.h.controls.send(MediaCommand.Pause)
        car.h.pump()

        assertTrue(car.player.pauseCalls > pauses)
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
    }

    @Test
    fun aRestrictedCarRefusesPlaybackEvenInFront() = runTest {
        val car = Car(this, FakeCarSource.DRIVING)
        car.start(one)

        assertFalse(car.player.state.playing)
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
        car.h.service.play()
        assertEquals(0, car.player.playCalls)
    }

    @Test
    fun nothingIsArmedWhilePlaybackStaysRestricted() = runTest {
        val car = Car(this, FakeCarSource.DRIVING)
        car.start(one, two)
        car.h.service.addToEnd(listOf(track("three")))
        car.h.service.setRepeatMode(MusicRepeatMode.ALL)
        car.h.pump()

        assertNull(car.player.armed)
        assertTrue(car.player.setNextCalls.all { it == null })
    }

    @Test
    fun aPlayThatLandsAfterTheCarRestrictedPausesAgain() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        car.h.service.pause()
        car.h.pump()
        val playGate = CompletableDeferred<Unit>()
        car.player.playGate = playGate

        val play = launch { car.h.service.play() }
        runCurrent()
        car.drive()
        car.player.playGate = null
        playGate.complete(Unit)
        play.join()
        car.h.pump()

        assertFalse(car.player.state.playing)
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
    }

    @Test
    fun aSystemPauseDuringTheDriveTakesTheCarsResumeAway() = runTest {
        val car = Car(this, FakeCarSource.PARKED)
        car.start(one)
        car.drive()
        assertFalse(car.player.state.playing)

        car.h.controls.send(MediaCommand.SystemPause)
        car.h.pump()
        car.park()

        assertFalse(car.player.state.playing, "only the car's own pause is the car's to undo")
        assertEquals(MusicPlaybackStatus.PAUSED, car.h.state.status)
    }
}
