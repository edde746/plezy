package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import com.edde746.plezy.presentation.watch.WatchPlayBlockedUi
import kotlinx.coroutines.flow.update
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * The rules every UI draws the player by: which button a menu belongs to, what may be controlled, what covers the
 * video, what holds a TV remote.
 */
class PlayerRulesTest {
    private val playBlocked = WatchPlayBlockedUi("Playback didn't start", "Press play to join the room.", "Play")

    private fun PlayerHarness.room(watch: FakeWatch, change: (PlayerWatchUi) -> PlayerWatchUi) {
        watch.state.update { it?.let(change) }
        advance(Duration.ZERO)
    }

    @Test
    fun aDelayAndAnAudioSettingsPageBelongToTheirTrackMenuAndAnOptionsPageToTheOptions() {
        assertEquals(
            mapOf(
                PlayerMenu.AUDIO to PlayerMenu.AUDIO,
                PlayerMenu.SUBTITLES to PlayerMenu.SUBTITLES,
                PlayerMenu.SPEED to PlayerMenu.OPTIONS,
                PlayerMenu.CUSTOM_SPEED to PlayerMenu.OPTIONS,
                PlayerMenu.SUBTITLE_DELAY to PlayerMenu.SUBTITLES,
                PlayerMenu.AUDIO_DELAY to PlayerMenu.AUDIO,
                PlayerMenu.MORE_SUBTITLES to PlayerMenu.SUBTITLES,
                PlayerMenu.SUBTITLE_LANGUAGE to PlayerMenu.SUBTITLES,
                PlayerMenu.OPTIONS to PlayerMenu.OPTIONS,
                PlayerMenu.VIDEO_FIT to PlayerMenu.OPTIONS,
                PlayerMenu.ZOOM to PlayerMenu.OPTIONS,
                PlayerMenu.SHADERS to PlayerMenu.OPTIONS,
                PlayerMenu.SLEEP_TIMER to PlayerMenu.OPTIONS,
                PlayerMenu.AUDIO_CHANNELS to PlayerMenu.AUDIO,
                PlayerMenu.AUDIO_OUTPUT to PlayerMenu.AUDIO,
                PlayerMenu.WATCH_TOGETHER to PlayerMenu.WATCH_TOGETHER,
                PlayerMenu.TRACKS to PlayerMenu.TRACKS,
                PlayerMenu.SUBTITLE_SEARCH to PlayerMenu.SUBTITLES,
                PlayerMenu.VERSIONS to PlayerMenu.OPTIONS,
                PlayerMenu.FILE_INFO to PlayerMenu.OPTIONS,
                PlayerMenu.CHAPTERS to PlayerMenu.CHAPTERS,
                PlayerMenu.QUEUE to PlayerMenu.QUEUE,
                PlayerMenu.CONTENT_STRIP to PlayerMenu.CONTENT_STRIP,
                PlayerMenu.DOLBY_VISION_CONVERSION to PlayerMenu.OPTIONS,
                PlayerMenu.HTTP_STATUS to PlayerMenu.OPTIONS,
            ),
            PlayerMenu.entries.associateWith { it.parent },
        )
    }

    @Test
    fun onlyAGuestInAHostOnlyRoomMayNotControlPlayback() = playerTest {
        playing()
        assertTrue(state.canControl, "no room")
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        advance(Duration.ZERO)
        assertTrue(state.canControl)
        assertTrue(state.canSeek)
        room(watch) { it.copy(canControl = false) }
        assertFalse(state.canControl)
        assertFalse(state.canSeek, "the timeline can, this device may not")
        assertTrue(state.seekable)
    }

    @Test
    fun theTrackMenusShowWhenThereIsATrackToChoose() = playerTest {
        playing()
        assertFalse(state.showsAudioMenu)
        assertFalse(state.showsSubtitleMenu, "Off alone")
        engineState { it.copy(tracks = listOf(Track(1, TrackKind.AUDIO, null, "eng", "aac", selected = true, external = false))) }
        assertTrue(state.showsAudioMenu)
        assertFalse(state.showsSubtitleMenu)
        engineState { it.copy(tracks = it.tracks + Track(1, TrackKind.SUBTITLE, null, "eng", "subrip", selected = false, external = false)) }
        assertTrue(state.showsSubtitleMenu)
    }

    @Test
    fun theSpinnerCoversTheVideoOnlyWhileItLoads() = playerTest {
        sessionInfo { it.copy(resolving = true) }
        assertEquals(PlayerCentre.Loading("Preparing stream…"), state.centre)
        sessionInfo { it.copy(resolving = false) }
        assertEquals(PlayerCentre.Loading("Opening…"), state.centre)
        playing()
        assertNull(state.centre)
        engineState { it.copy(buffering = true) }
        advance(500.milliseconds)
        assertEquals(PlayerCentre.Loading("Buffering…"), state.centre)
    }

    @Test
    fun aWaitShowsTheSpinnerOnlyOnceItLastsHalfASecond() = playerTest {
        playing()
        engineState { it.copy(buffering = true) }
        advance(499.milliseconds)
        assertNull(state.centre, "a blip, such as a speed change's")
        assertEquals(PlaybackStatus.PLAYING, state.status)
        engineState { it.copy(buffering = false) }
        advance(500.milliseconds)
        assertNull(state.centre, "the blip ended")

        engineState { it.copy(buffering = true) }
        advance(499.milliseconds)
        assertNull(state.centre, "each wait counts from its own start")
        advance(1.milliseconds)
        assertEquals(PlayerCentre.Loading("Buffering…"), state.centre, "a stall for the cache")
        engineState { it.copy(buffering = false) }
        assertNull(state.centre, "gone as the wait ends")
    }

    @Test
    fun theErrorCoversTheSpinner() = playerTest {
        sessionInfo { it.copy(resolving = true, failure = PlaybackFailure.Engine(EngineError("loading failed", httpStatus = 403))) }
        assertEquals(PlayerCentre.Error(state.error!!), state.centre)
    }

    @Test
    fun theSessionSheetBacksToTheOptionsItOpenedFromAndClosesWithTheRoom() = playerTest {
        playing()
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        advance(Duration.ZERO)

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.WATCH_TOGETHER))
        dispatch(PlayerCommand.Back)
        assertEquals(PlayerMenu.OPTIONS, state.menu, "opened from the options")
        dispatch(PlayerCommand.CloseMenu)

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.WATCH_TOGETHER))
        dispatch(PlayerCommand.Back)
        assertNull(state.menu, "opened from the room pill")

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.WATCH_TOGETHER))
        watch.state.value = null
        advance(Duration.ZERO)
        assertNull(state.menu, "the room went")
    }

    /**
     * What holds a TV remote over the video, each with buttons of its own: the open menu, the error, the prompt button,
     * the sleep timer's question and a room's play prompt. The controls alone, the playback info (which takes no focus),
     * a room's reconnecting line and the spinner leave it to the video and the timeline.
     */
    @Test
    fun theMenusCardsAndPromptsHoldTheRemoteAndTheControlsDoNot() = playerTest {
        playing()
        dispatch(PlayerCommand.ShowControls)
        val shown = state
        assertTrue(shown.controlsVisible)
        assertFalse(shown.remoteHeld, "the controls alone")
        val room = assertNotNull(FakeWatch(canControl = true, canChangeEpisode = false).state.value)
        val holders = mapOf(
            "a menu" to shown.copy(menu = PlayerMenu.AUDIO),
            "the error" to shown.copy(error = PlayerStates.error(PlaybackFailure.Engine(EngineError("loading failed")))),
            "the prompt button" to shown.copy(
                prompt = PlayerStates.upNext(NextEpisode(title = "Chapter Two", subtitle = "S1E2"), progress = null, secondsLeft = null, withControls = false),
            ),
            "still watching" to shown.copy(stillWatching = PlayerStates.stillWatching(30)),
            "a room's play prompt" to shown.copy(watch = room.copy(playBlocked = playBlocked)),
        )
        for ((what, held) in holders) assertTrue(held.remoteHeld, what)
        assertFalse(shown.copy(playbackInfo = PlaybackInfoState(visible = true)).remoteHeld, "the playback info")
        assertFalse(shown.copy(watch = room.copy(reconnecting = "Reconnecting…")).remoteHeld, "a room's reconnecting line")
        assertFalse(shown.copy(status = PlaybackStatus.BUFFERING).remoteHeld, "the spinner")
    }
}
