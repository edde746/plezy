package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.KeyModifiers
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.QueueEntry
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration

/** The controls' previous and next episode buttons ([PlayerUiState.episodes]) and the keys that change the episode. */
class EpisodeButtonsTest {
    private val next = NextEpisode(title = "Chapter Three", subtitle = "S1E3")

    private fun PlayerHarness.middleEpisode() = sessionInfo { it.copy(episode = true, nextEpisode = next, hasPreviousEpisode = true) }

    /** A queue of [count] entries playing the one at [current]. */
    private fun queue(current: Int, count: Int = 3) = List(count) { QueueEntry("$it", "Entry $it", current = it == current) }

    @Test
    fun aMovieHasNeitherAndPreviousRestartsIt() = playerTest {
        playing(position = 2.0)
        assertNull(state.episodes)
        dispatch(PlayerCommand.PreviousEpisode)
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(1, session.previousEpisodes, "the session restarts what has nothing before it")
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun withNothingBeforePreviousIsStillRestartPastTheFirstSeconds() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next) }
        playing(position = 7.0)
        assertEquals(EpisodeButtons(previous = true, next = true, previousRestarts = true), state.episodes)
        dispatch(PlayerCommand.PreviousEpisode)
        assertEquals(0.0, engine.seeks.last().first)
    }

    @Test
    fun pastTheFirstSecondsPreviousIsNamedRestartAndRestarts() = playerTest {
        middleEpisode()
        playing(position = 3.0)
        assertEquals(EpisodeButtons(previous = true, next = true), state.episodes, "at 3 s it still goes back")
        assertEquals("Previous episode", state.episodes?.previousLabel)
        playing(position = 3.5)
        assertEquals(EpisodeButtons(previous = true, next = true, previousRestarts = true), state.episodes)
        assertEquals("Restart", state.episodes?.previousLabel)
        engineState { it.copy(paused = true) }
        dispatch(PlayerCommand.PreviousEpisode)
        assertEquals(0.0, engine.seeks.last().first, "paused too, it restarts")
        assertEquals(0, session.previousEpisodes)
    }

    @Test
    fun onlyAnEpisodesButtonsNameAnEpisode() = playerTest {
        playing(position = 2.0)
        middleEpisode()
        assertEquals("Previous episode", state.episodes?.previousLabel)
        assertEquals("Next episode", state.episodes?.nextLabel)
        sessionInfo { it.copy(episode = false, queue = queue(current = 1)) }
        assertEquals("Previous", state.episodes?.previousLabel, "a movie in a shuffled queue")
        assertEquals("Next", state.episodes?.nextLabel)
    }

    @Test
    fun aSeriesAlwaysHasBothDisabledAtItsEnds() = playerTest {
        playing(position = 2.0)
        sessionInfo { it.copy(episode = true) }
        assertEquals(EpisodeButtons(previous = false, next = false), state.episodes, "a series of one episode")

        sessionInfo { it.copy(nextEpisode = next) }
        assertEquals(EpisodeButtons(previous = false, next = true), state.episodes, "the first episode")
        dispatch(PlayerCommand.PreviousEpisode)
        assertEquals(1, session.previousEpisodes, "the first episode restarts")

        sessionInfo { it.copy(nextEpisode = null, hasPreviousEpisode = true) }
        assertEquals(EpisodeButtons(previous = true, next = false), state.episodes, "the last episode")
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(0, session.nextEpisodes)

        middleEpisode()
        assertEquals(EpisodeButtons(previous = true, next = true), state.episodes)
    }

    @Test
    fun aQueueDecidesBothForEveryItemItHolds() = playerTest {
        playing(position = 2.0)
        sessionInfo { it.copy(queue = queue(current = 0)) }
        assertEquals(EpisodeButtons(previous = false, next = true, episode = false), state.episodes, "a movie at a shuffle's head")
        sessionInfo { it.copy(queue = queue(current = 1)) }
        assertEquals(EpisodeButtons(previous = true, next = true, episode = false), state.episodes)
        sessionInfo { it.copy(queue = queue(current = 2)) }
        assertEquals(EpisodeButtons(previous = true, next = false, episode = false), state.episodes, "at its end")
    }

    @Test
    fun theButtonsNeverDisagreeWithTheQueueShown() = playerTest {
        playing(position = 2.0)
        sessionInfo { it.copy(episode = true, nextEpisode = next, hasPreviousEpisode = true, queue = queue(current = 0, count = 1)) }
        assertEquals(EpisodeButtons(previous = false, next = false), state.episodes, "nothing listed before or after")
        sessionInfo { it.copy(nextEpisode = null, hasPreviousEpisode = false, queue = queue(current = 1)) }
        assertEquals(EpisodeButtons(previous = true, next = true), state.episodes, "entries listed both ways")
    }

    @Test
    fun nextPlaysTheEntryAfterBeforeTheLookupNamesIt() = playerTest {
        playing()
        sessionInfo { it.copy(queue = queue(current = 0)) }
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(listOf("queue 1"), session.actions.filter { it.startsWith("queue") })
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun whileAnItemOpensBothAreOffAndTakeNoPress() = playerTest {
        playing(position = 2.0)
        sessionInfo { it.copy(queue = queue(current = 1), resolving = true) }
        assertEquals(EpisodeButtons(previous = false, next = false, episode = false), state.episodes, "the item before opens")
        dispatch(PlayerCommand.NextEpisode)
        dispatch(PlayerCommand.PreviousEpisode)
        assertEquals(emptyList(), session.actions.filter { it.startsWith("queue") })
        assertEquals(0, session.nextEpisodes)
        assertEquals(0, session.previousEpisodes)
        sessionInfo { it.copy(resolving = false) }
        assertEquals(EpisodeButtons(previous = true, next = true, episode = false), state.episodes, "it opened")
    }

    @Test
    fun previousPlaysTheEpisodeBefore() = playerTest {
        middleEpisode()
        playing(position = 2.0)
        dispatch(PlayerCommand.PreviousEpisode)
        assertEquals(1, session.previousEpisodes)
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun previousDuringUpNextDropsIt() = playerTest {
        middleEpisode()
        playing(position = 595.0, duration = 600.0)
        assertEquals("Chapter Three", state.prompt?.text)
        assertEquals(EpisodeButtons(previous = true, next = true, previousRestarts = true), state.episodes)
        dispatch(PlayerCommand.PreviousEpisode)
        assertEquals(0.0, engine.seeks.last().first, "a restart")
        assertNull(state.prompt)
    }

    @Test
    fun theHostChangesEpisodes() = playerTest {
        middleEpisode()
        playing(position = 2.0)
        store.attachWatch(FakeWatch(canControl = true, canChangeEpisode = true))
        advance(Duration.ZERO)
        assertEquals(EpisodeButtons(previous = true, next = true), state.episodes)
        dispatch(PlayerCommand.PreviousEpisode)
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(1, session.previousEpisodes)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun aGuestSeesBothDisabledAndIsToldWhy() = playerTest {
        middleEpisode()
        playing()
        store.attachWatch(FakeWatch(canControl = true, canChangeEpisode = false))
        advance(Duration.ZERO)
        assertEquals(EpisodeButtons(previous = false, next = false), state.episodes)
        dispatch(PlayerCommand.PreviousEpisode)
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(0, session.previousEpisodes)
        assertEquals(0, session.nextEpisodes)
        assertEquals("Only the host controls playback", state.osd)
    }

    @Test
    fun mediaPreviousAndNextStepChaptersNotEpisodes() = playerTest {
        engineState {
            it.copy(loaded = true, positionSeconds = 30.0, durationSeconds = 60.0, chapters = listOf(Chapter("One", 0.0), Chapter("Two", 20.0)))
        }
        middleEpisode()
        press(InputKey.MEDIA_PREVIOUS)
        assertEquals(20.0, engine.seeks.last().first, "back to the start of the chapter")
        assertEquals(0, session.previousEpisodes)
        press(InputKey.MEDIA_NEXT)
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun shiftPAndShiftNOnAKeyboardChangeTheEpisode() = playerTest {
        middleEpisode()
        playing(position = 2.0)
        press(InputKey.P, KeyModifiers(shift = true))
        press(InputKey.N, KeyModifiers(shift = true))
        assertEquals(1, session.previousEpisodes)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun aGuestsEpisodeKeysAreRefusedAndConsumed() = playerTest {
        middleEpisode()
        playing()
        store.attachWatch(FakeWatch(canControl = true, canChangeEpisode = false))
        advance(Duration.ZERO)
        assertTrue(press(InputKey.P, KeyModifiers(shift = true)))
        assertTrue(press(InputKey.N, KeyModifiers(shift = true)))
        assertEquals(0, session.previousEpisodes)
        assertEquals(0, session.nextEpisodes)
        assertEquals("Only the host controls playback", state.osd)
    }
}
