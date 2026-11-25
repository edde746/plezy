package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** A live playback ([SessionInfo.live]) in the player: its timeline, no seeking, no prompts. */
class LiveTest {
    @Test
    fun theTimelineSaysLiveWithoutATimePlayed() = playerTest {
        sessionInfo { it.copy(live = true) }
        playing(position = 30.0, duration = 36.0)
        assertEquals(PlaybackMode.LIVE, state.mode)
        assertFalse(state.showsTimeline, "no timeline: the top bar's LIVE says it")
        assertFalse(state.showsSeekButtons)
        assertFalse(state.seekable)
        assertEquals(listOf("", "", ""), listOf(timeline.position, timeline.duration, timeline.remaining), "no position or duration")
        assertEquals(T.player.live.badge, timeline.liveLabel)

        advance(75.seconds)
        position(105.0)
        assertEquals(T.player.live.badge, timeline.liveLabel, "no time played since tuning")
        assertEquals(T.player.live.atEdge, timeline.positionLabel)

        sessionInfo { it.copy(live = false) }
        assertEquals(PlaybackMode.VIDEO, state.mode, "a video file after the live one")
        assertTrue(state.showsTimeline && state.showsSeekButtons)
        assertEquals("", timeline.liveLabel)
        assertTrue(state.seekable)
    }

    @Test
    fun noKeyCommandOrMediaControlSeeksALivePlayback() = playerTest(InputProfile.TV) {
        sessionInfo { it.copy(live = true) }
        playing(position = 30.0, duration = 36.0)
        engineState { it.copy(chapters = listOf(Chapter("One", 0.0), Chapter("Two", 20.0))) }
        for (key in listOf(InputKey.LEFT, InputKey.RIGHT)) {
            press(key)
            dispatch(PlayerCommand.HideControls)
            press(key)
        }
        for (command in listOf(
            PlayerCommand.SeekBy(-10.0), PlayerCommand.SeekTo(0.0), PlayerCommand.SeekToFraction(0.5), PlayerCommand.ScrubTo(0.2),
            PlayerCommand.CommitScrub, PlayerCommand.NextChapter, PlayerCommand.PreviousChapter, PlayerCommand.SkipSegment,
        )) {
            dispatch(command)
        }
        advance(5.seconds)
        assertNull(timeline.scrub)
        assertEquals(emptyList(), engine.seeks)
        assertEquals(emptyList(), session.seeks)

        sessionInfo { it.copy(live = false) }
        dispatch(PlayerCommand.SeekBy(-10.0))
        assertEquals(1, engine.seeks.size, "a video file after the live one seeks")
    }

    /** The timeline had focus when the file turned live: it is gone, so Left and Right go back to moving focus. */
    @Test
    fun theTimelinesFocusGoesWithItWhenAPlaybackTurnsLive() = playerTest(InputProfile.TV) {
        playing(position = 30.0, duration = 36.0)
        dispatch(PlayerCommand.ShowControls)
        store.onTimelineFocusChanged(true)
        assertTrue(press(InputKey.LEFT), "the focused timeline scrubs")
        dispatch(PlayerCommand.CancelScrub)
        sessionInfo { it.copy(live = true) }
        input(InputEvent.ControlFocus(onControl = true))
        assertFalse(press(InputKey.LEFT), "Left moves focus")
        assertFalse(press(InputKey.RIGHT), "Right moves focus")
    }

    @Test
    fun noCreditsSkipOrUpNextComeUpAndTheEndStaysTheEnd() = playerTest {
        sessionInfo { it.copy(live = true, episode = true, nextEpisode = NextEpisode(title = "Chapter Two", subtitle = "S1E2")) }
        playing(position = 540.0, duration = 600.0)
        engineState { it.copy(chapters = listOf(Chapter("Episode", 0.0), Chapter("End Credits", 550.0))) }
        position(590.0)
        advance(20.seconds)
        assertNull(state.prompt)
        engineState { it.copy(positionSeconds = 600.0, eof = true) }
        advance(20.seconds)
        assertNull(state.prompt)
        assertEquals(0, session.nextEpisodes)
        dispatch(PlayerCommand.TogglePause)
        assertEquals(emptyList(), engine.seeks, "nothing to start over")
    }
}
