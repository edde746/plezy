package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.SessionChoice
import com.edde746.plezy.playback.session.SessionNotice
import com.edde746.plezy.playback.session.SourceTrack
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** The transient feedback over the video: the seek badge, the play/pause flash, the toasts and their icons. */
class FeedbackTest {
    /** Playing at [position] with the controls gone (a mouse's 3 s). */
    private fun PlayerHarness.hiddenAt(position: Double, duration: Double = 3600.0) {
        playing(position = position, duration = duration)
        advance(3.seconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aSeekKeyWithTheControlsHiddenSeeksAndShowsItsBadge() = playerTest {
        hiddenAt(600.0)
        press(InputKey.RIGHT)
        assertEquals(SkipBadge(forward = true, label = "10s", serial = 1), state.skipBadge)
        assertEquals(listOf(610.0 to true), engine.seeks)
    }

    @Test
    fun repeatedSkipsOneWayAddUpToARunningTotal() = playerTest {
        hiddenAt(600.0)
        repeat(3) { press(InputKey.RIGHT) }
        assertEquals("30s", state.skipBadge?.label)
        assertEquals(3, state.skipBadge?.serial)
    }

    @Test
    fun flippingDirectionStartsTheCountOver() = playerTest {
        hiddenAt(600.0)
        press(InputKey.RIGHT)
        press(InputKey.LEFT)
        assertEquals("10s", state.skipBadge?.label)
        assertEquals(false, state.skipBadge?.forward)
    }

    @Test
    fun aBurstThatReachesTheStartCountsOnlyWhatItTravelled() = playerTest {
        hiddenAt(25.0)
        repeat(5) { press(InputKey.LEFT) }
        assertEquals("25s", state.skipBadge?.label)
        assertEquals(listOf(15.0, 5.0, 0.0), engine.seeks.map { it.first })
    }

    @Test
    fun aPressWithNothingToRewindThroughRaisesNoBadgeAndNoSeek() = playerTest {
        hiddenAt(0.0)
        press(InputKey.LEFT)
        assertNull(state.skipBadge)
        assertTrue(engine.seeks.isEmpty())

        press(InputKey.RIGHT)
        assertEquals("10s", state.skipBadge?.label)
        assertEquals(listOf(10.0 to true), engine.seeks)
    }

    @Test
    fun theBadgeShowsFor1200msAfterItsLastSkip() = playerTest {
        hiddenAt(600.0)
        press(InputKey.RIGHT)
        advance(1000.milliseconds)
        press(InputKey.RIGHT)
        advance(1199.milliseconds)
        assertEquals("20s", state.skipBadge?.label)
        advance(1.milliseconds)
        assertNull(state.skipBadge)
    }

    @Test
    fun aSeekButtonWithTheControlsUpShowsNoBadge() = playerTest {
        playing(position = 600.0, duration = 3600.0)
        dispatch(PlayerCommand.SeekBy(10.0))
        assertNull(state.skipBadge)
        assertEquals(listOf(610.0 to true), engine.seeks)
    }

    @Test
    fun theBadgeReadsATimecodeFromAMinuteOn() = playerTest {
        hiddenAt(600.0)
        dispatch(PlayerCommand.SeekBy(59.0))
        assertEquals("59s", state.skipBadge?.label)
        advance(2.seconds)
        dispatch(PlayerCommand.SeekBy(60.0))
        assertEquals("1:00", state.skipBadge?.label)
        dispatch(PlayerCommand.SeekBy(115.0))
        assertEquals("2:55", state.skipBadge?.label)
    }

    @Test
    fun anotherEpisodeTakesTheBadgeWithTheOldTimeline() = playerTest {
        sessionInfo { it.copy(nextEpisode = NextEpisode("Next", autoplay = false)) }
        hiddenAt(600.0)
        press(InputKey.RIGHT)
        dispatch(PlayerCommand.NextEpisode)
        assertNull(state.skipBadge)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun aPauseWithTheControlsHiddenBringsThemUpAndFlashesNothingOverThem() = playerTest {
        hiddenAt(600.0)
        press(InputKey.MEDIA_PAUSE)
        assertTrue(state.controlsVisible, "the pause brings the controls up")
        assertNull(state.transportFlash, "their Play/Pause says it: no message over it")
    }

    /** A play with the controls down flashes its glyph, each time anew. */
    @Test
    fun aRepeatedTransportCommandFlashesAgain() = playerTest(InputProfile.TV) {
        playing()
        press(InputKey.MEDIA_PAUSE)
        dispatch(PlayerCommand.HideControls)
        press(InputKey.MEDIA_PLAY_PAUSE)
        assertEquals(TransportFlash(paused = false, serial = 2), state.transportFlash)
        advance(800.milliseconds)
        assertNull(state.transportFlash)
        press(InputKey.MEDIA_PAUSE)
        dispatch(PlayerCommand.HideControls)
        press(InputKey.MEDIA_PLAY)
        assertEquals(TransportFlash(paused = false, serial = 4), state.transportFlash)
    }

    @Test
    fun theControlsUpOrTheSystemsPauseFlashNothing() = playerTest {
        playing()
        dispatch(PlayerCommand.TogglePause)
        assertNull(state.transportFlash)
        dispatch(PlayerCommand.TogglePause)
        advance(3.seconds)
        dispatch(PlayerCommand.SystemPause)
        assertNull(state.transportFlash)
    }

    @Test
    fun aDirectedPlayOnAPausedVideoRewindsThenResumes() = playerTest(InputProfile.TV) {
        sessionInfo { it.copy(rewindOnResumeSeconds = 5) }
        playing(position = 600.0, duration = 3600.0)
        engineState { it.copy(paused = true) }
        dispatch(PlayerCommand.HideControls)
        press(InputKey.MEDIA_PLAY)
        assertEquals(listOf(595.0 to true), engine.seeks)
        assertEquals(listOf(false), engine.paused)
        assertEquals(TransportFlash(paused = false, serial = 1), state.transportFlash)
    }

    @Test
    fun aDirectedPauseOnAPausedVideoNeitherResumesNorRewinds() = playerTest {
        sessionInfo { it.copy(rewindOnResumeSeconds = 5) }
        hiddenAt(600.0)
        engineState { it.copy(paused = true) }
        press(InputKey.MEDIA_PAUSE)
        assertTrue(engine.seeks.isEmpty())
        assertEquals(listOf(true), engine.paused)
    }

    @Test
    fun theSystemsResumeAndLiveNeverRewind() = playerTest {
        sessionInfo { it.copy(rewindOnResumeSeconds = 5) }
        playing(position = 600.0, duration = 3600.0)
        dispatch(PlayerCommand.SystemPause)
        dispatch(PlayerCommand.SystemResume)
        assertTrue(engine.seeks.isEmpty())

        sessionInfo { it.copy(live = true) }
        dispatch(PlayerCommand.Pause)
        dispatch(PlayerCommand.Play)
        assertTrue(engine.seeks.isEmpty())
    }

    @Test
    fun everyVolumeChangeShowsAToastWithTheIconOfItsLevel() = playerTest {
        playing()
        dispatch(PlayerCommand.SetVolume(30.0))
        assertEquals("Volume 30%", state.osd)
        assertEquals(OsdIcon.VOLUME_DOWN, state.osdIcon)
        dispatch(PlayerCommand.SetVolume(80.0))
        assertEquals(OsdIcon.VOLUME_UP, state.osdIcon)
        dispatch(PlayerCommand.SetVolume(0.0))
        assertEquals(OsdIcon.VOLUME_OFF, state.osdIcon)
        dispatch(PlayerCommand.ToggleMute)
        assertEquals("Muted", state.osd)
        assertEquals(OsdIcon.VOLUME_OFF, state.osdIcon)
        advance(1500.milliseconds)
        assertNull(state.osd)
        assertNull(state.osdIcon)
    }

    @Test
    fun theVolumeGoesUpToTheProfilesTop() = playerTest(preferences = PlayerChoices(maxVolume = 200)) {
        playing()
        dispatch(PlayerCommand.SetVolume(250.0))
        assertEquals(200.0, engine.volumes.last())
        dispatch(PlayerCommand.SetVolume(150.0))
        assertEquals(200, state.volume.maxPercent)
        assertEquals(0.75f, state.volume.fraction)
    }

    @Test
    fun theViewersVolumeIsKeptForTheNextPlaybackWithinTheTop() = playerTest(preferences = PlayerChoices(maxVolume = 150)) {
        playing()
        dispatch(PlayerCommand.SetVolume(80.0))
        advance(1.seconds)
        dispatch(PlayerCommand.SetVolume(400.0))
        advance(1.seconds)
        assertEquals(listOf(80.0, 150.0), preferences.volumes)
    }

    @Test
    fun aVolumeSetJustBeforeThePlayerClosesIsKept() = playerTest {
        playing()
        dispatch(PlayerCommand.SetVolume(42.0))
        store.release()
        assertEquals(listOf(42.0), preferences.volumes)
    }

    @Test
    fun aSpeedChangeShowsFastForwardOrSlowMotionAndIsKeptForTheTitle() = playerTest {
        playing()
        dispatch(PlayerCommand.SetSpeed(1.5))
        assertEquals(OsdIcon.FAST_FORWARD, state.osdIcon)
        dispatch(PlayerCommand.SetSpeed(0.5))
        assertEquals(OsdIcon.SLOW_MOTION, state.osdIcon)
        assertEquals(listOf("speed 1.5", "speed 0.5"), session.actions)
    }

    @Test
    fun aHeldFingersSpeedIsNotKept() = playerTest(InputProfile.TOUCH) {
        playing()
        dispatch(PlayerCommand.HoldSpeed)
        dispatch(PlayerCommand.ReleaseSpeed)
        assertTrue(session.actions.isEmpty())
    }

    @Test
    fun aSessionNoticeShowsOnceForEachSerial() = playerTest {
        playing()
        sessionInfo { it.copy(notice = SessionNotice("Transcoding unavailable", 1)) }
        assertEquals("Transcoding unavailable", state.osd)
        advance(1500.milliseconds)
        sessionInfo { it.copy(title = "Other") }
        assertNull(state.osd)
        sessionInfo { it.copy(notice = SessionNotice("Transcoding unavailable", 2)) }
        assertEquals("Transcoding unavailable", state.osd)
    }

    @Test
    fun theSessionsQuestionShowsItsOptionsAndBackDismissesIt() = playerTest {
        playing()
        sessionInfo { it.copy(choice = SessionChoice("Play from", listOf("Start", "Resume"))) }
        val choice = assertNotNullChoice()
        assertEquals("Play from", choice.title)
        assertEquals(listOf("Start", "Resume"), choice.options.map { it.label })
        dispatch(choice.options[1].command)
        assertEquals(listOf<Int?>(1), session.answers)
        assertNull(state.choice)

        sessionInfo { it.copy(choice = SessionChoice("Play from", listOf("Start", "Resume"))) }
        assertTrue(state.remoteHeld)
        dispatch(PlayerCommand.Back)
        assertEquals(listOf(1, null), session.answers)
        assertEquals(0, host.closed)
    }

    /** A mouse press held on the video plays at 2× under its own label, and lifting gives the speed back, both without a toast. */
    @Test
    fun aHeldMousePressPlaysTwiceAsFastWithoutASpeedToast() = playerTest {
        playing()
        dispatch(PlayerCommand.SetSpeed(1.5))
        advance(1500.milliseconds)
        input(InputEvent.Hold(held = true))
        assertEquals(2.0, engine.speeds.last())
        assertEquals("2×", state.heldSpeed)
        assertNull(state.osd)
        input(InputEvent.Hold(held = false))
        assertEquals(1.5, engine.speeds.last())
        assertNull(state.heldSpeed)
        assertNull(state.osd, "giving the speed back shows no toast")
    }

    @Test
    fun noHoldLiveNorForAGuestWhoMayNotControl() = playerTest {
        sessionInfo { it.copy(live = true) }
        playing()
        input(InputEvent.Hold(held = true))
        assertTrue(engine.speeds.isEmpty(), "live")
        input(InputEvent.Hold(held = false))

        sessionInfo { it.copy(live = false) }
        store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        advance(0.seconds)
        input(InputEvent.Hold(held = true))
        assertTrue(engine.speeds.isEmpty(), "a guest")
        assertNull(state.heldSpeed)
    }

    @Test
    fun aSpeedThatChangesNothingShowsNoToast() = playerTest {
        playing()
        dispatch(PlayerCommand.SetSpeed(1.0))
        assertNull(state.osd)
        dispatch(PlayerCommand.SetSpeed(1.25))
        assertEquals("Speed 1.25×", state.osd)
        advance(1500.milliseconds)
        dispatch(PlayerCommand.SetSpeed(1.252))
        assertNull(state.osd, "under half a hundredth")
    }

    @Test
    fun theTrackShortcutsCycleTheAudioAndTheSubtitlesThroughOff() = playerTest {
        playing()
        engineState {
            it.copy(
                tracks = listOf(
                    Track(1, TrackKind.AUDIO, "English", "en", "aac", selected = true, external = false),
                    Track(2, TrackKind.AUDIO, "German", "de", "aac", selected = false, external = false),
                    Track(3, TrackKind.SUBTITLE, "English", "en", "subrip", selected = true, external = false),
                ),
            )
        }
        repeat(2) { dispatch(PlayerCommand.CycleAudio) }
        repeat(2) { dispatch(PlayerCommand.CycleSubtitles) }
        assertEquals(
            listOf<Pair<TrackKind, Long?>>(TrackKind.AUDIO to 2, TrackKind.AUDIO to 1, TrackKind.SUBTITLE to null, TrackKind.SUBTITLE to 3),
            engine.selections,
        )
    }

    /** Subtitles the server burns into a transcode are pixels: the shortcut says where to change them and hides nothing. */
    @Test
    fun theSubtitleShortcutOnBurnedSubtitlesPointsToTheMenu() = playerTest {
        sessionInfo { it.copy(transcoding = true, sourceSubtitles = listOf(SourceTrack(7, "English (PGS)", selected = true))) }
        playing()
        dispatch(PlayerCommand.ToggleSubtitles)
        assertEquals("Subtitles are burned into this stream. Change them from the subtitle menu.", state.osd)
        assertTrue(engine.selections.isEmpty())
    }

    @Test
    fun theBadgeRoundsItsRunningTotalToWholeSecondsAndShowsNothingForATravelOfNoWholeSecond() = playerTest {
        hiddenAt(0.4)
        press(InputKey.LEFT)
        assertNull(state.skipBadge, "0.4 s rounds to no second")
        position(10.6)
        press(InputKey.LEFT)
        assertEquals("10s", state.skipBadge?.label)
        press(InputKey.LEFT)
        assertEquals("11s", state.skipBadge?.label, "10.6 s in all, rounded once")
    }

    @Test
    fun theRoomsSpeedShowsNoToast() = playerTest {
        playing()
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.roomRate = 1.5
        start { store.watchPlayer.setRate(1.5) }
        assertEquals(listOf(1.5), engine.speeds)
        assertNull(state.osdIcon)
    }

    @Test
    fun muteLeavesTheVolumeAndUnmuteGivesItBack() = playerTest {
        playing()
        dispatch(PlayerCommand.SetVolume(37.0))
        dispatch(PlayerCommand.ToggleMute)
        assertTrue(state.volume.muted)
        dispatch(PlayerCommand.ToggleMute)
        assertEquals(listOf(true, false), engine.mutes)
        assertEquals(listOf(37.0), engine.volumes, "muting never touched the volume")
        assertEquals(37, state.volume.percent)
        assertEquals("Volume 37%", state.osd)
        advance(1.seconds)
        assertEquals(listOf(37.0), preferences.volumes)
    }

    private fun PlayerHarness.assertNotNullChoice(): ChoiceState = state.choice ?: error("no choice shows")
}
