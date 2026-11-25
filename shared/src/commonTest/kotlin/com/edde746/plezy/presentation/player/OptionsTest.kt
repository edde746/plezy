package com.edde746.plezy.presentation.player

import com.edde746.plezy.downloads.testMediaItem
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.KeyModifiers
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.input.TouchPhase
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.AudioDevice
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.EngineFeatures
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.playback.VideoInfo
import com.edde746.plezy.playback.VideoLayout
import com.edde746.plezy.playback.session.NextEpisode
import kotlinx.coroutines.flow.update
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

class OptionsTest {
    private fun PlayerHarness.option(id: PlayerOptionId): PlayerOption? =
        state.options.firstOrNull { it.id == id } ?: state.audioOptions.firstOrNull { it.id == id } ?: state.videoFit?.takeIf { it.id == id }

    /** Opens [id]'s page from the menu that lists it (the options, or the audio menu) and picks [label] there. */
    private fun PlayerHarness.choose(id: PlayerOptionId, label: String) {
        val option = option(id) ?: error("no $id option")
        val page = option.page ?: error("$id has no page")
        dispatch(PlayerCommand.OpenMenu(page.parent))
        dispatch(PlayerCommand.OpenMenu(page))
        dispatch(option.choices.first { it.label == label }.command)
    }

    @Test
    fun theOptionsListSpeedZoomAndSleepTimerAndTheAudioMenuTheAudioSettings() = playerTest {
        playing()
        assertEquals(
            listOf(
                PlayerOptionId.SPEED to "Normal",
                PlayerOptionId.ZOOM to "100%",
                PlayerOptionId.SLEEP_TIMER to "Off",
                PlayerOptionId.PLAYBACK_INFO to "Off",
            ),
            state.options.map { it.id to it.value },
        )
        assertEquals(
            listOf(PlayerOptionId.AUDIO_NORMALIZATION to "Off", PlayerOptionId.AUDIO_CHANNELS to "Original"),
            state.audioOptions.map { it.id to it.value },
        )
        assertEquals("Letterbox", state.videoFit?.value, "the fit is the aspect button's, not an option")
        assertEquals(listOf("Letterbox", "Fill screen", "Stretch"), state.videoFit?.choices?.map { it.label })
        assertEquals(
            listOf("Reset", "50%", "75%", "90%", "100%", "110%", "120%", "130%", "140%", "150%", "175%", "200%"),
            option(PlayerOptionId.ZOOM)?.choices?.map { it.label },
        )
        assertEquals(
            listOf("Off", "End of current video", "5 minutes", "10 minutes", "15 minutes", "30 minutes", "45 minutes", "60 minutes", "90 minutes", "120 minutes"),
            option(PlayerOptionId.SLEEP_TIMER)?.choices?.map { it.label },
        )
        assertEquals(true, option(PlayerOptionId.SLEEP_TIMER)?.choices?.first()?.selected)
        assertEquals(PlayerCommand.SetAudioNormalization(true), option(PlayerOptionId.AUDIO_NORMALIZATION)?.toggle)
        assertTrue(state.options.none { it.adjusted } && state.audioOptions.none { it.adjusted })
    }

    private fun passthrough(on: Boolean) =
        PlayerConfig.defaults(InputProfile.DESKTOP, doubleClickIntervalMillis = 500).copy(audioPassthrough = true, audioPassthroughOn = on)

    /** With passthrough on, the audio menu's normalization row says it turns passthrough off. */
    @Test
    fun withPassthroughOnNormalizationSaysItTurnsPassthroughOff() = playerTest(config = passthrough(on = true)) {
        playing()
        assertEquals("Turns passthrough off", option(PlayerOptionId.AUDIO_NORMALIZATION)?.detail)
    }

    /** With passthrough offered but off, the normalization row has nothing under it. */
    @Test
    fun withPassthroughOffNormalizationHasNoNote() = playerTest(config = passthrough(on = false)) {
        playing()
        assertNull(option(PlayerOptionId.AUDIO_NORMALIZATION)?.detail)
    }

    @Test
    fun aPickedFitGoesToTheEngineAndIsKeptForTheNextVideo() = playerTest {
        playing()
        choose(PlayerOptionId.VIDEO_FIT, "Stretch")
        assertEquals(listOf(VideoLayout(VideoFit.FILL)), engine.layouts)
        assertEquals(VideoFit.FILL, preferences.kept().fit, "this device keeps the fit for the next video")
        assertNull(state.menu, "a pick closes the page")
        assertNull(state.osd, "the menu showed the pick")
        assertEquals("Stretch", option(PlayerOptionId.VIDEO_FIT)?.value)
        assertEquals(true, option(PlayerOptionId.VIDEO_FIT)?.adjusted)
    }

    @Test
    fun theKeptFitGoesToTheEngineAsThePlayerOpens() = playerTest(picture = PictureChoices(fit = VideoFit.COVER)) {
        assertEquals(listOf(VideoLayout(VideoFit.COVER)), engine.layouts)
        assertEquals("Fill screen", option(PlayerOptionId.VIDEO_FIT)?.value)
    }

    @Test
    fun zoomKeysStepByAPercentWithinTheRangeAndShowTheZoom() = playerTest {
        playing()
        val alt = KeyModifiers(alt = true)
        press(InputKey.PLUS, alt)
        assertEquals(VideoLayout(zoom = 1.01), engine.layouts.last())
        assertEquals("Zoom 101%", state.osd)
        press(InputKey.MINUS, alt)
        press(InputKey.MINUS, alt)
        assertEquals(0.99, engine.layouts.last().zoom)
        press(InputKey.BACKSPACE, alt)
        assertEquals(VideoLayout.DEFAULT, engine.layouts.last())
        assertEquals("Zoom 100%", state.osd)

        dispatch(PlayerCommand.SetZoom(1.987))
        assertEquals(1.99, engine.layouts.last().zoom)
        dispatch(PlayerCommand.ZoomIn)
        dispatch(PlayerCommand.ZoomIn)
        assertEquals(2.0, engine.layouts.last().zoom, "the zoom stops at 200 %")
        dispatch(PlayerCommand.SetZoom(0.1))
        assertEquals(0.5, engine.layouts.last().zoom, "and at 50 %")
    }

    @Test
    fun aZoomPickedInItsPageClosesItWithoutAMessage() = playerTest {
        playing()
        choose(PlayerOptionId.ZOOM, "120%")
        assertEquals(VideoLayout(zoom = 1.2), engine.layouts.last())
        assertNull(state.menu)
        assertNull(state.osd)
        assertEquals("120%", option(PlayerOptionId.ZOOM)?.value)
        assertEquals(listOf("120%"), option(PlayerOptionId.ZOOM)?.choices?.filter { it.selected }?.map { it.label })
        choose(PlayerOptionId.ZOOM, "Reset")
        assertEquals(VideoLayout.DEFAULT, engine.layouts.last())
    }

    /**
     * Two fingers 200 apart pinched to each of [scales] of that, then lifted (after the two-finger tap's time: a pinch
     * is no tap).
     */
    private fun PlayerHarness.pinch(vararg scales: Double) {
        val first = nextPointer()
        val second = nextPointer()
        touch(TouchPhase.DOWN, first, 300f to 300f)
        touch(TouchPhase.DOWN, second, 500f to 300f)
        for (scale in scales) touch(TouchPhase.MOVE, second, 300f + 200f * scale.toFloat() to 300f)
        advance(400.milliseconds)
        touch(TouchPhase.UP, first, 300f to 300f)
        touch(TouchPhase.UP, second, 300f + 200f * scales.last().toFloat() to 300f)
    }

    @Test
    fun aPinchZoomsOnceItClearlyMovesSnapsTo100AndShowsTheZoomAtTheEnd() = playerTest(InputProfile.TOUCH) {
        playing()
        // Fingers resting on the video, or barely moving: nothing.
        pinch(1.03, 1.05)
        assertEquals(emptyList(), engine.layouts)
        assertNull(state.osd)

        // A pinch out zooms from its third clear move, by the pinch's own scale.
        val first = nextPointer()
        val second = nextPointer()
        touch(TouchPhase.DOWN, first, 300f to 300f)
        touch(TouchPhase.DOWN, second, 500f to 300f)
        touch(TouchPhase.MOVE, second, 540f to 300f)
        touch(TouchPhase.MOVE, second, 560f to 300f)
        assertEquals(emptyList(), engine.layouts)
        touch(TouchPhase.MOVE, second, 580f to 300f)
        assertEquals(VideoLayout(zoom = 1.4), engine.layouts.last())
        touch(TouchPhase.MOVE, second, 600f to 300f)
        assertEquals(VideoLayout(zoom = 1.5), engine.layouts.last())
        assertNull(state.osd, "no message while the fingers move")
        advance(400.milliseconds)
        touch(TouchPhase.UP, second, 600f to 300f)
        assertEquals("Zoom 150%", state.osd, "the zoom shows as a finger lifts")
        touch(TouchPhase.UP, first, 300f to 300f)

        // Pinching back in from 150 % lands on 100 % exactly when it ends close to it.
        pinch(0.8, 0.7, 0.68)
        assertEquals(VideoLayout.DEFAULT, engine.layouts.last(), "102 % snaps to 100 %")
        assertEquals("Zoom 100%", state.osd)
    }

    private val episode = testMediaItem("e1", MediaKind.EPISODE, "srv", grandparentId = "show")
    private val nextEpisode = testMediaItem("e2", MediaKind.EPISODE, "srv", grandparentId = "show")
    private val movie = testMediaItem("m1", MediaKind.MOVIE, "srv")

    /** The session leaves the title playing and opens [item], resolving it first. */
    private fun PlayerHarness.open(item: MediaItem) {
        sessionInfo { it.copy(item = null, resolving = true) }
        sessionInfo { it.copy(item = item, resolving = false) }
    }

    @Test
    fun theTitlesKeptFitZoomAndShaderGoToTheEngineAsItOpens() = playerTest(shaderFiles = FakeShaderFiles()) {
        keepPicture(episode) { PictureChoices(VideoFit.FILL, 1.2, "nvscaler") }
        open(episode)
        playing()
        assertEquals(VideoLayout(VideoFit.FILL, 1.2), engine.layouts.last())
        assertEquals(listOf("/app/shaders/nvscaler/NVScaler.glsl"), engine.shaders.last())
        assertEquals("Stretch", option(PlayerOptionId.VIDEO_FIT)?.value)
        assertEquals("120%", option(PlayerOptionId.ZOOM)?.value)
    }

    @Test
    fun aPickedFitZoomKeysAPinchAndAPickedShaderAreKeptForTheTitlePlaying() =
        playerTest(InputProfile.TOUCH, shaderFiles = FakeShaderFiles()) {
            open(episode)
            playing()
            dispatch(PlayerCommand.SetVideoFit(VideoFit.COVER))
            dispatch(PlayerCommand.SetShaderPreset("nvscaler"))
            dispatch(PlayerCommand.ZoomIn)
            assertEquals(PictureChoices(VideoFit.COVER, 1.01, "nvscaler"), preferences.kept(nextEpisode), "kept for the show")
            assertEquals(PictureChoices(), preferences.kept(), "the global options stay")
            assertEquals(PictureChoices(), preferences.kept(movie))

            dispatch(PlayerCommand.ResetZoom)
            assertEquals(1.0, preferences.kept(episode).zoom)
            val first = nextPointer()
            val second = nextPointer()
            touch(TouchPhase.DOWN, first, 300f to 300f)
            touch(TouchPhase.DOWN, second, 500f to 300f)
            touch(TouchPhase.MOVE, second, 540f to 300f)
            touch(TouchPhase.MOVE, second, 560f to 300f)
            touch(TouchPhase.MOVE, second, 580f to 300f)
            assertEquals(1.4, engine.layouts.last().zoom)
            assertEquals(1.0, preferences.kept(episode).zoom, "nothing kept while the fingers move")
            advance(400.milliseconds)
            touch(TouchPhase.UP, second, 580f to 300f)
            assertEquals(1.4, preferences.kept(episode).zoom, "kept as the pinch ends")
            touch(TouchPhase.UP, first, 300f to 300f)
        }

    @Test
    fun theNextTitleSwitchesToWhatItKeepsWhileAChangeKeptNowhereCarriesOn() = playerTest(shaderFiles = FakeShaderFiles()) {
        keepPicture(episode) { it.copy(shaderPreset = "nvscaler") }
        keepPicture(movie) { PictureChoices(VideoFit.COVER, 1.1, "none") }
        open(episode)
        playing()
        press(InputKey.G)
        assertEquals(emptyList(), engine.shaders.last(), "off for this player only")

        open(nextEpisode)
        assertEquals(emptyList(), engine.shaders.last(), "the show keeps the same preset: the shaders stay off")

        open(movie)
        assertEquals(VideoLayout(VideoFit.COVER, 1.1), engine.layouts.last())
        assertEquals("Off", option(PlayerOptionId.SHADERS)?.value)

        open(episode)
        assertEquals(VideoLayout.DEFAULT, engine.layouts.last())
        assertEquals(listOf("/app/shaders/nvscaler/NVScaler.glsl"), engine.shaders.last(), "the show's preset again")
    }

    @Test
    fun gKeepsThePresetItTurnsOnForTheTitleAndTurningOffKeepsNothing() = playerTest(shaderFiles = FakeShaderFiles()) {
        open(episode)
        playing()
        press(InputKey.G)
        assertEquals(listOf("/app/shaders/nvscaler/NVScaler.glsl"), engine.shaders.last())
        assertEquals("nvscaler", preferences.kept(nextEpisode).shaderPreset, "kept for the show")
        assertEquals("none", preferences.kept().shaderPreset, "the global preset stays")
        press(InputKey.G)
        assertEquals(emptyList(), engine.shaders.last())
        assertEquals("nvscaler", preferences.kept(episode).shaderPreset, "off isn't kept")
    }

    @Test
    fun neitherLiveNorAGuestWhoMayNotControlIsOfferedTheSpeedAndLiveHasNoFileInfo() = playerTest {
        sessionInfo { it.copy(fileInfo = true) }
        playing()
        assertNotNull(option(PlayerOptionId.SPEED))
        assertNotNull(option(PlayerOptionId.FILE_INFO))
        sessionInfo { it.copy(live = true) }
        assertNull(option(PlayerOptionId.SPEED))
        assertNull(option(PlayerOptionId.FILE_INFO))
        sessionInfo { it.copy(live = false) }
        store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        advance(0.seconds)
        assertNull(option(PlayerOptionId.SPEED))
    }

    @Test
    fun aPinchWithPinchToZoomOffLeavesTheZoom() = playerTest(InputProfile.TOUCH) {
        playing()
        choices { it.copy(pinchToZoom = false) }
        pinch(1.2, 1.3, 1.4, 1.5)
        assertTrue(engine.layouts.none { it.zoom != 1.0 }, "no zoom: ${engine.layouts}")
        assertNull(state.osd)
    }

    @Test
    fun pictureInPictureShowsTheWholePictureAndTheLayoutComesBackAfter() = playerTest {
        playing()
        dispatch(PlayerCommand.SetVideoFit(VideoFit.COVER))
        dispatch(PlayerCommand.SetZoom(1.3))
        store.onPictureInPictureChanged(true)
        assertEquals(VideoLayout.DEFAULT, engine.layouts.last())
        assertEquals("Fill screen", option(PlayerOptionId.VIDEO_FIT)?.value, "the options keep the viewer's choice")
        store.onPictureInPictureChanged(false)
        assertEquals(VideoLayout(VideoFit.COVER, 1.3), engine.layouts.last())
    }

    @Test
    fun backFromAnOptionsPageReturnsToTheOptions() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SLEEP_TIMER))
        assertEquals(PlayerOptionId.SLEEP_TIMER, state.openOption?.id)
        press(InputKey.ESCAPE)
        assertEquals(PlayerMenu.OPTIONS, state.menu)
        assertNull(state.openOption)
        press(InputKey.ESCAPE)
        assertNull(state.menu)
    }

    /** The sleep timer's value forms are the same whatever it shows: Off, the end of the video, its longest countdown. */
    @Test
    fun theSleepTimersValueFormsStayPutWhileItCountsDown() = playerTest {
        playing()
        val forms = listOf("Off", "End of current video", "2:00:00 left")
        assertEquals(forms, option(PlayerOptionId.SLEEP_TIMER)?.valueForms)
        choose(PlayerOptionId.SLEEP_TIMER, "5 minutes")
        advance(61.seconds)
        assertEquals("3:59 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
        assertEquals(forms, option(PlayerOptionId.SLEEP_TIMER)?.valueForms)
    }

    @Test
    fun theSleepTimerAsksAfterItsMinutesThenPausesUnlessTheViewerKeepsWatching() = playerTest {
        playing()
        choose(PlayerOptionId.SLEEP_TIMER, "5 minutes")
        assertEquals("5:00 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
        advance(61.seconds)
        assertEquals("3:59 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
        // The timer counts real time: a pause doesn't stop it.
        dispatch(PlayerCommand.Pause)
        dispatch(PlayerCommand.Play)
        advance(239.seconds)
        assertEquals(StillWatchingState("Pausing in 30 seconds", secondsLeft = 30, progress = 0f), state.stillWatching)
        advance(10.seconds)
        assertEquals("Pausing in 20 seconds", state.stillWatching?.countdown)

        // Kept watching: the same five minutes again.
        dispatch(PlayerCommand.KeepWatching)
        assertNull(state.stillWatching)
        assertEquals("5:00 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
        advance(5.minutes)
        assertEquals(30, state.stillWatching?.secondsLeft)

        // Unanswered: the playback pauses when the countdown runs out, and the timer is off.
        advance(29.seconds)
        assertEquals(false, state.paused)
        advance(1.seconds)
        assertEquals(true, state.paused)
        assertNull(state.stillWatching)
        assertEquals("Off", option(PlayerOptionId.SLEEP_TIMER)?.value)
        advance(10.minutes)
        assertNull(state.stillWatching)
    }

    @Test
    fun theSleepTimerAsksAndPausesOnTimeHoweverLateEachSecondWakes() = TestTimeSource().let { clock ->
        playerTest(timeSource = clock) {
            playing()
            dispatch(PlayerCommand.SetSleepTimer(5))
            // Each second wakes after 1.5 s, as on a slow TV: the timer follows the time measured.
            fun lateSecond() {
                clock += 1500.milliseconds
                advance(1.seconds)
            }
            repeat(199) { lateSecond() }
            assertNull(state.stillWatching, "4:58.5")
            lateSecond()
            assertEquals(30, state.stillWatching?.secondsLeft, "asked at 5:00, after 200 late seconds rather than 300")
            repeat(19) { lateSecond() }
            assertEquals(false, state.paused, "28.5 s of the question's 30")
            lateSecond()
            assertEquals(true, state.paused, "paused 30 s after asking, after 20 late seconds")
        }
    }

    @Test
    fun withFastTimersTheSleepTimersMinutesAreSixSecondsEachAndTheQuestionStillWaitsThirty() = playerTest(
        config = PlayerConfig.defaults(InputProfile.DESKTOP, doubleClickIntervalMillis = 500).copy(sleepTimerMinuteSeconds = 6),
    ) {
        playing()
        choose(PlayerOptionId.SLEEP_TIMER, "5 minutes")
        // The menu tells the real time left.
        assertEquals("0:30 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
        advance(29.seconds)
        assertEquals("0:01 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
        assertNull(state.stillWatching)
        advance(1.seconds)
        assertEquals(StillWatchingState("Pausing in 30 seconds", secondsLeft = 30, progress = 0f), state.stillWatching)

        // Kept watching: the same 30 s again.
        dispatch(PlayerCommand.KeepWatching)
        assertNull(state.stillWatching)
        assertEquals("0:30 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
        advance(29.seconds)
        assertNull(state.stillWatching)
        advance(1.seconds)
        assertEquals(30, state.stillWatching?.secondsLeft)

        // Unanswered: the playback pauses after the question's full 30 s.
        advance(29.seconds)
        assertEquals(false, state.paused)
        advance(1.seconds)
        assertEquals(true, state.paused)
        assertEquals("Off", option(PlayerOptionId.SLEEP_TIMER)?.value)
    }

    @Test
    fun settingTheSleepTimerSaysSoInAMessage() = playerTest {
        playing()
        choose(PlayerOptionId.SLEEP_TIMER, "5 minutes")
        assertEquals("Sleep timer set for 5 minutes", state.osd)
        dispatch(PlayerCommand.SleepAtEndOfVideo)
        assertEquals("Sleep timer set for End of current video", state.osd)
    }

    @Test
    fun pausingOrBackAnswersTheSleepTimersQuestion() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.SetSleepTimer(10))
        advance(10.minutes)
        assertEquals(30, state.stillWatching?.secondsLeft)
        // Back is "still watching".
        press(InputKey.ESCAPE)
        assertNull(state.stillWatching)
        assertEquals("10:00 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
        advance(10.minutes)
        dispatch(PlayerCommand.Pause)
        assertNull(state.stillWatching)
        assertEquals("Off", option(PlayerOptionId.SLEEP_TIMER)?.value)
    }

    @Test
    fun theSleepTimersQuestionStaysAwayWhileUpNextShows() = playerTest {
        sessionInfo { it.copy(nextEpisode = NextEpisode(title = "Chapter Two", subtitle = "S1E2", countdownSeconds = 30)) }
        playing(position = 100.0, duration = 600.0)
        dispatch(PlayerCommand.SetSleepTimer(5))
        advance(4.minutes + 50.seconds)
        position(575.0)
        assertNotNull(state.prompt, "up next counts down")
        advance(15.seconds)
        assertNull(state.stillWatching)
        assertNull(state.sleepTimer, "the timer went off rather than wait at 0s")
        assertEquals("Off", option(PlayerOptionId.SLEEP_TIMER)?.value)
        assertNotNull(state.prompt, "up next goes on")
    }

    @Test
    fun aSleepTimerRunningOutWhilePlayNextWaitsAtTheEndGoesOff() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = NextEpisode(title = "Chapter Two", subtitle = "S1E2", autoplay = false)) }
        playing(position = 100.0, duration = 600.0)
        dispatch(PlayerCommand.SetSleepTimer(10))
        engineState { it.copy(positionSeconds = 600.0, eof = true) }
        assertNotNull(state.prompt, "play next waits at the end")
        advance(10.minutes + 5.seconds)
        assertNull(state.sleepTimer, "no banner stuck at 0s")
        assertNull(state.stillWatching)
        assertEquals("Off", option(PlayerOptionId.SLEEP_TIMER)?.value)
        assertNotNull(state.prompt, "play next still waits to be asked")
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun theNextEpisodeAnswersTheSleepTimersQuestion() = playerTest {
        sessionInfo { it.copy(nextEpisode = NextEpisode(title = "Chapter Two", subtitle = "S1E2")) }
        playing()
        dispatch(PlayerCommand.SetSleepTimer(10))
        advance(10.minutes)
        assertEquals(30, state.stillWatching?.secondsLeft)
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(1, session.nextEpisodes)
        assertNull(state.stillWatching)
        assertEquals("10:00 left", option(PlayerOptionId.SLEEP_TIMER)?.value)
    }

    @Test
    fun aSleepTimerForTheEndOfTheVideoStopsThereInsteadOfPlayingTheNextEpisode() = playerTest {
        sessionInfo { it.copy(nextEpisode = NextEpisode(title = "Chapter Two", subtitle = "S1E2")) }
        playing(position = 500.0, duration = 600.0)
        choose(PlayerOptionId.SLEEP_TIMER, "End of current video")
        assertEquals("End of current video", option(PlayerOptionId.SLEEP_TIMER)?.value)
        position(595.0)
        assertNull(state.prompt, "no countdown to the next episode")
        engineState { it.copy(positionSeconds = 600.0, eof = true) }
        assertEquals(0, session.nextEpisodes)
        assertEquals(true, engine.paused.last())
        assertEquals("Off", option(PlayerOptionId.SLEEP_TIMER)?.value)
    }

    @Test
    fun autoPlayNextIsASwitchWhileThereIsANextEpisode() = playerTest {
        playing(position = 500.0, duration = 600.0)
        assertNull(option(PlayerOptionId.AUTO_PLAY_NEXT))
        sessionInfo { it.copy(nextEpisode = NextEpisode(title = "Chapter Two", subtitle = "S1E2")) }
        assertEquals(true, option(PlayerOptionId.AUTO_PLAY_NEXT)?.on)
        dispatch(option(PlayerOptionId.AUTO_PLAY_NEXT)!!.toggle!!)
        assertEquals(listOf(false), session.autoPlayNext)
        assertEquals(false, option(PlayerOptionId.AUTO_PLAY_NEXT)?.on)
        position(595.0)
        assertNull(state.prompt, "without auto-play or credits nothing comes up before the end")
    }

    @Test
    fun theAudioOptionsGoToTheEngineAndAreKept() = playerTest {
        playing()
        dispatch(option(PlayerOptionId.AUDIO_NORMALIZATION)!!.toggle!!)
        assertEquals(listOf(true), engine.normalizations)
        assertEquals(true, preferences.choices.value.audioNormalization)
        assertEquals("On", option(PlayerOptionId.AUDIO_NORMALIZATION)?.value)

        choose(PlayerOptionId.AUDIO_CHANNELS, "Stereo")
        assertEquals(listOf(AudioChannels.STEREO), engine.channels)
        assertEquals(AudioChannels.STEREO, preferences.choices.value.audioChannels)
        assertNull(state.menu, "a pick closes the page")
        assertEquals(
            listOf("All channels", "Mixes 7.1 down", null),
            option(PlayerOptionId.AUDIO_CHANNELS)?.choices?.map { it.detail },
            "no passthrough here: stereo says nothing of it",
        )
    }

    @Test
    fun anAudioSettingsPageGoesBackToTheAudioMenu() = playerTest {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO_CHANNELS))
        assertEquals(PlayerMenu.AUDIO_CHANNELS, state.menu)
        dispatch(PlayerCommand.Back)
        assertEquals(PlayerMenu.AUDIO, state.menu)
        dispatch(PlayerCommand.Back)
        assertNull(state.menu)
    }

    @Test
    fun theAudioOutputIsOfferedWhereTheEngineListsOutputsAndThePickIsKept() = playerTest {
        playing()
        engineState { it.copy(audioDevices = listOf(AudioDevice("auto", "Autoselect device"), AudioDevice("coreaudio/BuiltInSpeakerDevice", "MacBook Air Speakers"))) }
        assertNull(option(PlayerOptionId.AUDIO_OUTPUT), "an engine that lists no outputs: no row")
        engine.features = EngineFeatures(audioDevices = true)
        engineState { it.copy(audioDevices = listOf(AudioDevice("auto", "Autoselect device"))) }
        assertEquals("System default", option(PlayerOptionId.AUDIO_OUTPUT)?.value)
        engineState {
            it.copy(audioDevices = listOf(AudioDevice("auto", "Autoselect device"), AudioDevice("coreaudio/BuiltInSpeakerDevice", "MacBook Air Speakers")))
        }
        choose(PlayerOptionId.AUDIO_OUTPUT, "MacBook Air Speakers")
        assertEquals(listOf("coreaudio/BuiltInSpeakerDevice"), engine.audioDevices)
        assertEquals("MacBook Air Speakers", option(PlayerOptionId.AUDIO_OUTPUT)?.value)
        assertEquals("coreaudio/BuiltInSpeakerDevice", preferences.choices.value.audioOutputDevice, "kept for the players to come")
        assertNull(state.menu)
    }

    @Test
    fun anEngineThatListsNoOutputsOpensAPageSayingSo() = playerTest {
        playing()
        engine.features = EngineFeatures(audioDevices = true)
        // A change of the state: the options are built again with the engine's features.
        engineState { it.copy(audioDevices = emptyList(), volume = 97.0) }
        val output = assertNotNull(option(PlayerOptionId.AUDIO_OUTPUT))
        assertEquals(PlayerMenu.AUDIO_OUTPUT, output.page)
        assertTrue(output.choices.isEmpty())
        assertEquals("No audio devices available", output.empty)
    }

    @Test
    fun aRefusedOutputPickKeepsTheRememberedOutput() = playerTest(preferences = PlayerChoices(audioOutputDevice = "pipewire")) {
        playing()
        engine.features = EngineFeatures(audioDevices = true)
        engine.echo = false
        engineState { it.copy(audioDevices = listOf(AudioDevice("alsa", "Default (alsa)"))) }
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO_OUTPUT))
        dispatch(PlayerCommand.SetAudioDevice("alsa"))
        engineState { it.copy(audioDevice = "auto", volume = 90.0) }
        engineState { it.copy(audioDevice = "coreaudio/other") }
        assertEquals("pipewire", preferences.choices.value.audioOutputDevice)
    }

    @Test
    fun anMpvConfAudioDeviceWinsOverTheRememberedOutput() =
        playerTest(preferences = PlayerChoices(audioOutputDevice = "coreaudio/BuiltInSpeakerDevice", configAudioDevice = true)) {
            playing()
            engine.features = EngineFeatures(audioDevices = true)
            engineState { it.copy(audioDevices = listOf(AudioDevice("auto", "Autoselect device"), AudioDevice("coreaudio/BuiltInSpeakerDevice", "MacBook Air Speakers"))) }
            assertEquals(emptyList<String>(), engine.audioDevices, "the line's output plays")
        }

    @Test
    fun aFailedHdrWriteRestoresTheToggleWithoutPersisting() = playerTest {
        playing()
        assertNull(option(PlayerOptionId.HDR), "no HDR control: no switch")
        engine.features = EngineFeatures(hdrControl = true)
        engineState { it.copy(volume = 99.0) }
        val ids = state.options.map { it.id }
        assertEquals(ids.indexOf(PlayerOptionId.SLEEP_TIMER) + 1, ids.indexOf(PlayerOptionId.HDR), "after the sleep timer")
        assertEquals(true, option(PlayerOptionId.HDR)?.on)
        dispatch(option(PlayerOptionId.HDR)!!.toggle!!)
        assertEquals(false, option(PlayerOptionId.HDR)?.on)
        assertEquals(true, preferences.choices.value.hdr)
        val (written, answer) = hdrWrites.single()
        assertEquals(false, written)
        answer(false)
        advance(0.milliseconds)
        assertEquals(true, option(PlayerOptionId.HDR)?.on)
        assertEquals(true, preferences.choices.value.hdr)
        assertEquals("HDR isn't available here — this desktop compositor or video output can't carry it.", state.osd)
        dispatch(option(PlayerOptionId.HDR)!!.toggle!!)
        hdrWrites.last().second(true)
        advance(0.milliseconds)
        assertEquals(false, preferences.choices.value.hdr)
        assertEquals(false, option(PlayerOptionId.HDR)?.on)
    }

    @Test
    fun theHdrSwitchIsDimmedAndSaysNotHdrForAnSdrVideo() = playerTest {
        playing()
        engine.features = EngineFeatures(hdrControl = true)
        engineState { it.copy(video = VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.HDR10)) }
        val hdr = assertNotNull(option(PlayerOptionId.HDR))
        assertTrue(hdr.enabled)
        assertNull(hdr.detail)
        engineState { it.copy(video = VideoInfo(320, 180, "h264", 25.0, DynamicRange.SDR)) }
        val sdr = assertNotNull(option(PlayerOptionId.HDR), "the switch stays in the options")
        assertEquals(false, sdr.enabled)
        assertEquals("Not HDR", sdr.detail)
        assertEquals(true, sdr.on, "it still shows the device's setting")
    }

    @Test
    fun theSleepChoicesIncludeAConfiguredDefaultOnceInOrder() = playerTest(preferences = PlayerChoices(sleepTimerMinutes = 25)) {
        playing()
        assertEquals(
            listOf("Off", "End of current video", "5 minutes", "10 minutes", "15 minutes", "25 minutes", "30 minutes", "45 minutes", "60 minutes", "90 minutes", "120 minutes"),
            option(PlayerOptionId.SLEEP_TIMER)?.choices?.map { it.label },
        )
        preferences.choices.update { it.copy(sleepTimerMinutes = 45) }
        advance(0.milliseconds)
        assertEquals(10, option(PlayerOptionId.SLEEP_TIMER)?.choices?.size, "a standard default isn't listed twice")
    }

    @Test
    fun theDebugEntriesShowInADevelopmentBuildOnly() = playerTest {
        playing()
        engine.features = EngineFeatures(dolbyVisionConversion = true)
        engineState { it.copy(volume = 98.0) }
        assertTrue(state.options.none { it.id == PlayerOptionId.HTTP_STATUS || it.id == PlayerOptionId.DOLBY_VISION_CONVERSION })
    }

    @Test
    fun anOutputListedByTwoDriversIsToldApartByItsDriver() = playerTest {
        playing()
        engine.features = EngineFeatures(audioDevices = true)
        engineState {
            it.copy(
                audioDevices = listOf(
                    AudioDevice("auto", "Autoselect device"),
                    AudioDevice("coreaudio/BuiltInSpeakerDevice", "MacBook Air Speakers"),
                    AudioDevice("avfoundation/BuiltInSpeakerDevice", "MacBook Air Speakers"),
                    AudioDevice("coreaudio/AirPods", "AirPods Pro"),
                ),
            )
        }
        val choices = assertNotNull(option(PlayerOptionId.AUDIO_OUTPUT)).choices
        assertEquals(
            listOf(
                "System default" to null,
                "MacBook Air Speakers" to "Core Audio",
                "MacBook Air Speakers" to "AVFoundation",
                "AirPods Pro" to null,
            ),
            choices.map { it.label to it.detail },
        )
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO_OUTPUT))
        dispatch(choices[2].command)
        assertEquals(listOf("avfoundation/BuiltInSpeakerDevice"), engine.audioDevices)
        assertEquals("\u2068MacBook Air Speakers\u2069 · AVFoundation", option(PlayerOptionId.AUDIO_OUTPUT)?.value, "the device's name isolated beside its driver")
    }
}
