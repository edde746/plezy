package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import kotlinx.coroutines.flow.update
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** What the player does at the end of a video: leave, play the next episode, or offer it again. */
class EndOfVideoTest {
    private val next = NextEpisode(title = "Chapter Two", subtitle = "S1E2", countdownSeconds = 5)

    private fun PlayerHarness.ends() = engineState { it.copy(positionSeconds = 600.0, eof = true) }

    /** The room changes as the player sees it ([PlayerWatch.state]). */
    private fun PlayerHarness.room(watch: FakeWatch, change: (PlayerWatchUi) -> PlayerWatchUi) {
        watch.state.update { it?.let(change) }
        advance(Duration.ZERO)
    }

    @Test
    fun `the end with nothing after it leaves the player once`() = playerTest {
        playing(position = 590.0, duration = 600.0)
        ends()
        assertEquals(0, host.closed, "not before the session says nothing follows")
        sessionInfo { it.copy(ended = true) }
        assertEquals(1, host.closed)
        engineState { it.copy(positionSeconds = 600.0, paused = true) }
        assertEquals(1, host.closed)
    }

    @Test
    fun `a guest the room keeps stays at the end`() = playerTest {
        store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        playing(position = 590.0, duration = 600.0)
        ends()
        sessionInfo { it.copy(ended = true) }
        assertEquals(0, host.closed)
    }

    @Test
    fun `a guest who controls the playback but not the episode gets no up next and stays at the end`() = playerTest {
        store.attachWatch(FakeWatch(canControl = true, canChangeEpisode = false))
        sessionInfo { it.copy(episode = true, nextEpisode = next) }
        playing(position = 590.0, duration = 600.0)
        assertNull(state.prompt)
        ends()
        assertNull(state.prompt)
        assertEquals(0, session.nextEpisodes)
        assertEquals(0, host.closed)
    }

    @Test
    fun `the sleep timer stopping the video at its end keeps the player`() = playerTest {
        playing(position = 590.0, duration = 600.0)
        dispatch(PlayerCommand.SleepAtEndOfVideo)
        ends()
        sessionInfo { it.copy(ended = true) }
        assertEquals(0, host.closed)
    }

    @Test
    fun `in picture in picture the end plays the next episode at once with auto play`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next) }
        store.onPictureInPictureChanged(true)
        playing(position = 590.0, duration = 600.0)
        assertEquals(0, session.nextEpisodes)
        ends()
        assertEquals(1, session.nextEpisodes, "no countdown nobody can answer")
        engineState { it.copy(paused = true) }
        assertEquals(1, session.nextEpisodes, "once per file")
    }

    @Test
    fun `in picture in picture without auto play the end waits for the viewer`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(autoplay = false)) }
        store.onPictureInPictureChanged(true)
        playing(position = 590.0, duration = 600.0)
        ends()
        advance(30.seconds)
        assertEquals(0, session.nextEpisodes)
        store.onPictureInPictureChanged(false)
        val prompt = assertNotNull(state.prompt, "up next waits for the viewer back in the full player")
        assertNull(prompt.progress)
        dispatch(prompt.command)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun `a room that reaches its end before this file offers the host the next episode`() = playerTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = true).also { it.routesControls = true }
        store.attachWatch(watch)
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(autoplay = false)) }
        playing(position = 570.0, duration = 600.0)
        assertNull(state.prompt)
        engineState { it.copy(paused = true) }
        room(watch) { it.copy(atMediaEnd = true) }
        val prompt = assertNotNull(state.prompt)
        assertNull(prompt.progress)
        advance(30.seconds)
        assertEquals(0, session.nextEpisodes, "without auto play it waits")
    }

    @Test
    fun `with auto play the room reaching its end plays the next episode at once`() = playerTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = true).also { it.routesControls = true }
        store.attachWatch(watch)
        sessionInfo { it.copy(episode = true, nextEpisode = next) }
        playing(position = 570.0, duration = 600.0)
        engineState { it.copy(paused = true) }
        room(watch) { it.copy(atMediaEnd = true) }
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun `the room reaching its end with nothing after it leaves the host player and keeps a guest`() = playerTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = false).also { it.routesControls = true }
        store.attachWatch(watch)
        sessionInfo { it.copy(ended = true) }
        playing(position = 570.0, duration = 600.0)
        room(watch) { it.copy(atMediaEnd = true) }
        assertEquals(0, host.closed, "the guest waits for the host")
        room(watch) { it.copy(canChangeEpisode = true) }
        assertEquals(1, host.closed)
    }

    @Test
    fun `play in a room at its end starts the room over`() = playerTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = true).also { it.routesControls = true }
        store.attachWatch(watch)
        playing(position = 570.0, duration = 600.0)
        engineState { it.copy(paused = true) }
        room(watch) { it.copy(atMediaEnd = true) }
        dispatch(PlayerCommand.TogglePause)
        assertEquals(listOf(0.0), watch.seeks)
        assertEquals(listOf("play"), watch.presses)
    }

    @Test
    fun `in picture in picture a playback the server stopped waits at the end`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next, stoppedByServer = true) }
        store.onPictureInPictureChanged(true)
        playing(position = 590.0, duration = 600.0)
        ends()
        advance(30.seconds)
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun `a playback the server stopped offers the next episode without a countdown`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next, stoppedByServer = true) }
        playing(position = 596.0, duration = 600.0)
        val prompt = assertNotNull(state.prompt)
        assertNull(prompt.progress)
        advance(10.seconds)
        ends()
        advance(30.seconds)
        assertEquals(0, session.nextEpisodes)
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(1, session.nextEpisodes, "the viewer still can")
    }

    @Test
    fun `a next episode that failed on a busy server counts five seconds down to try again twice then waits`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(countdownSeconds = 0)) }
        playing(position = 595.0, duration = 600.0)
        ends()
        assertEquals(1, session.nextEpisodes, "a countdown of 0 plays it at once")

        sessionInfo { it.copy(nextFailures = 1) }
        assertEquals(5, state.prompt?.secondsLeft, "five seconds, not the profile's countdown")
        advance(4.9.seconds)
        assertEquals(1, session.nextEpisodes)
        advance(0.1.seconds)
        assertEquals(2, session.nextEpisodes)

        sessionInfo { it.copy(nextFailures = 2) }
        advance(5.seconds)
        assertEquals(3, session.nextEpisodes)

        sessionInfo { it.copy(nextFailures = 3) }
        val manual = assertNotNull(state.prompt, "up next waits for the viewer")
        assertNull(manual.progress)
        advance(60.seconds)
        assertEquals(3, session.nextEpisodes)
        dispatch(manual.command)
        assertEquals(4, session.nextEpisodes)
    }

    @Test
    fun `a next episode that failed without auto play or in a room waits for the viewer`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(autoplay = false)) }
        playing(position = 595.0, duration = 600.0)
        ends()
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(1, session.nextEpisodes)
        sessionInfo { it.copy(nextFailures = 1) }
        assertNull(assertNotNull(state.prompt).progress)
        advance(30.seconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun `in a room a next episode that failed waits for the host`() = playerTest {
        store.attachWatch(FakeWatch(canControl = true, canChangeEpisode = true))
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(countdownSeconds = 0)) }
        playing(position = 595.0, duration = 600.0)
        ends()
        assertEquals(1, session.nextEpisodes)
        sessionInfo { it.copy(nextFailures = 1) }
        assertNull(assertNotNull(state.prompt).progress)
        advance(30.seconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun `the retry countdown holds while the app is in the background`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(countdownSeconds = 0)) }
        playing(position = 595.0, duration = 600.0)
        ends()
        sessionInfo { it.copy(nextFailures = 1) }
        advance(2.seconds)
        store.pauseForBackground()
        advance(60.seconds)
        assertEquals(1, session.nextEpisodes, "nobody is there to answer it")
        store.resumeAfterBackground(play = false)
        advance(3.seconds)
        assertEquals(2, session.nextEpisodes)
    }

    @Test
    fun `the countdown holds while the app is in the background and runs on once back`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next) }
        playing(position = 595.0, duration = 600.0)
        advance(2.seconds)
        val progress = state.prompt?.progress
        store.pauseForBackground()
        advance(60.seconds)
        assertEquals(progress, state.prompt?.progress)
        assertEquals(0, session.nextEpisodes)
        store.resumeAfterBackground(play = true)
        advance(3.seconds)
        assertEquals(1, session.nextEpisodes)
    }

    @Test
    fun `the retry countdown holds while video may not play and runs on once allowed`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(countdownSeconds = 0)) }
        playing(position = 595.0, duration = 600.0)
        ends()
        sessionInfo { it.copy(nextFailures = 1) }
        advance(2.seconds)
        host.playbackAllowed = false
        store.onPlaybackAllowedChanged()
        advance(60.seconds)
        assertEquals(1, session.nextEpisodes, "the profile picker covers the prompt")
        host.playbackAllowed = true
        store.onPlaybackAllowedChanged()
        advance(3.seconds)
        assertEquals(2, session.nextEpisodes)
    }

    @Test
    fun `a new file gives the retries back`() = playerTest {
        sessionInfo { it.copy(episode = true, nextEpisode = next.copy(countdownSeconds = 0)) }
        playing(position = 595.0, duration = 600.0)
        ends()
        sessionInfo { it.copy(nextFailures = 1) }
        advance(5.seconds)
        sessionInfo { it.copy(nextFailures = 2) }
        advance(5.seconds)
        assertEquals(3, session.nextEpisodes)

        // The next file opened and played to its end.
        engineState { it.copy(loaded = false, eof = false, positionSeconds = 0.0) }
        playing(position = 595.0, duration = 600.0)
        ends()
        assertEquals(4, session.nextEpisodes)
        sessionInfo { it.copy(nextFailures = 3) }
        assertEquals(5, state.prompt?.secondsLeft, "counting down again")
    }
}
