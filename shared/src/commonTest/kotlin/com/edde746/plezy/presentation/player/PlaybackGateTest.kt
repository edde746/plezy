package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

/** What starts the video while a car forbids it, the car's restriction itself, and the background's pause. */
@OptIn(ExperimentalCoroutinesApi::class)
class PlaybackGateTest {
    private fun PlayerHarness.paused() = engineState { it.copy(loaded = true, positionSeconds = 100.0, durationSeconds = 600.0, paused = true) }

    @Test
    fun `while a car forbids video a play goes nowhere and play pause pauses`() = playerTest {
        host.playbackAllowed = false
        paused()
        dispatch(PlayerCommand.Play)
        dispatch(PlayerCommand.TogglePause)
        dispatch(PlayerCommand.SystemResume)
        assertTrue(engine.paused.none { !it }, "nothing started: ${engine.paused}")
        assertTrue(session.engineState.value.paused)

        playing()
        dispatch(PlayerCommand.TogglePause)
        assertEquals(true, engine.paused.last())
        assertTrue(session.engineState.value.paused)
    }

    @Test
    fun `while a car forbids video a play in a room goes nowhere either`() = playerTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = true).also { it.routesControls = true }
        store.attachWatch(watch)
        host.playbackAllowed = false
        paused()
        dispatch(PlayerCommand.Play)
        assertEquals(emptyList(), watch.presses)
        assertTrue(engine.paused.none { !it })
    }

    @Test
    fun `the rooms start is refused while a car forbids video`() = playerTest {
        paused()
        host.playbackAllowed = false
        val play = start { runCatching { store.watchPlayer.play() } }
        val refused = assertIs<IllegalStateException>(play.getCompleted().exceptionOrNull())
        assertEquals("playback is restricted while driving", refused.message)
        assertTrue(engine.paused.none { !it })

        host.playbackAllowed = true
        val allowed = start { runCatching { store.watchPlayer.play() } }
        assertTrue(allowed.getCompleted().isSuccess)
        assertEquals(false, engine.paused.last())
    }

    @Test
    fun `a restriction pauses the video`() = playerTest {
        playing()
        host.playbackAllowed = false
        store.onPlaybackAllowedChanged()
        assertEquals(listOf(true), engine.paused)
    }

    @Test
    fun `a restriction while following a room leaves this viewers pause to the room`() = playerTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = true).also { it.routesControls = true }
        store.attachWatch(watch)
        playing()
        host.playbackAllowed = false
        store.onPlaybackAllowedChanged()
        assertEquals(emptyList(), watch.presses, "the room isn't paused")
        assertEquals(emptyList(), engine.paused, "the room's own view pauses this player alone")
    }

    @Test
    fun `back from the background while video may not play it neither plays nor rewinds`() = playerTest {
        sessionInfo { it.copy(rewindOnResumeSeconds = 10) }
        playing(position = 100.0)
        store.pauseForBackground()
        host.playbackAllowed = false
        store.resumeAfterBackground(play = true)
        assertEquals(listOf(true), engine.paused)
        assertTrue(engine.seeks.isEmpty(), "${engine.seeks}")
    }

    @Test
    fun `the background pauses a playing video and back it plays again rewound`() = playerTest {
        sessionInfo { it.copy(rewindOnResumeSeconds = 10) }
        playing(position = 100.0)
        assertTrue(store.pauseForBackground())
        assertEquals(listOf(true), engine.paused)
        store.resumeAfterBackground(play = true)
        assertEquals(false, engine.paused.last())
        assertEquals(90.0, engine.seeks.last().first)
    }

    @Test
    fun `the background leaves a paused or ended video and back nothing plays where the car forbids it`() = playerTest {
        paused()
        assertFalse(store.pauseForBackground())
        engineState { it.copy(paused = false, eof = true, positionSeconds = 600.0) }
        assertFalse(store.pauseForBackground())
        assertEquals(emptyList(), engine.paused)

        playing()
        store.pauseForBackground()
        host.playbackAllowed = false
        store.resumeAfterBackground(play = true)
        assertEquals(listOf(true), engine.paused)
    }
}
