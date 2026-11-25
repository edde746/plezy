package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The player as a Watch Together room reads and commands it ([PlayerStore.watchPlayer]). */
class PlayerAdapterTest {
    @Test
    fun theReadsFollowTheEngine() = playerTest {
        val player = store.watchPlayer
        assertNull(player.durationMs, "nothing loaded")
        assertFalse(player.renderedFrame)

        playing(position = 12.3456, duration = 600.0)
        assertEquals(12_346, player.positionMs)
        assertEquals(600_000, player.durationMs)
        assertTrue(player.playing)
        assertFalse(player.renderedFrame, "loaded, no frame yet")
        engineState { it.copy(playbackRestarts = 1) }
        assertTrue(player.renderedFrame)
        assertEquals(1, player.restarts)

        engineState { it.copy(buffering = true) }
        assertTrue(player.buffering)
        // At the end the player stands still, whatever mpv's pause says.
        engineState { it.copy(buffering = false, eof = true) }
        assertFalse(player.playing)

        assertFalse(player.audioPassthrough)
        engineState { it.copy(audioPassthrough = true) }
        assertTrue(player.audioPassthrough, "the receiver decodes the audio: a nudge would glitch it")
    }

    @Test
    fun playAndPauseReturnOnceTheEngineReportsThem() = playerTest {
        playing()
        engine.echo = false
        val player = store.watchPlayer

        val pause = start { player.pause() }
        assertEquals(listOf(true), engine.paused)
        assertFalse(player.playing, "the command reads at once")
        assertFalse(pause.isCompleted)
        engineState { it.copy(paused = true) }
        assertTrue(pause.isCompleted)

        val play = start { player.play() }
        assertEquals(listOf(true, false), engine.paused)
        assertFalse(play.isCompleted)
        engineState { it.copy(paused = false) }
        assertTrue(play.isCompleted)
    }

    @Test
    fun aSeekIsIssuedOnlyInALoadedFileAndExactly() = playerTest {
        val player = store.watchPlayer

        val early = start { player.seek(42_000) }
        assertEquals(emptyList(), engine.seeks, "nothing to seek in yet: the room's adapter waits until the file takes seeks")
        assertTrue(early.isCompleted)

        playing(position = 0.0, duration = 600.0)
        val seek = start { player.seek(42_000) }
        assertEquals(listOf(42.0 to true), engine.seeks)
        assertTrue(seek.isCompleted, "issued; the room's adapter waits for the landing")
    }

    @Test
    fun theRoomRepeatingTheViewersSeekDoesntSeekTwice() = playerTest {
        playing()
        engine.echo = false
        dispatch(PlayerCommand.SeekTo(300.0))
        assertEquals(listOf(300.0), engine.seeks.map { it.first })

        start { store.watchPlayer.seek(300_100) }
        assertEquals(1, engine.seeks.size)

        // Another position is another seek.
        start { store.watchPlayer.seek(100_000) }
        assertEquals(100.0, engine.seeks.last().first)
    }

    @Test
    fun aSeekStaysWithinTheVideoAndInARoomEveryoneSeeksThere() = playerTest {
        playing(position = 100.0, duration = 600.0)
        dispatch(PlayerCommand.SeekTo(-5.0))
        dispatch(PlayerCommand.SeekTo(700.0))
        assertEquals(listOf(0.0, 600.0), engine.seeks.map { it.first })

        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true
        dispatch(PlayerCommand.SeekTo(200.0))
        assertEquals(listOf(200.0), watch.seeks)
    }

    @Test
    fun theRoomHearsStateChangesNotPositionTicks() = playerTest {
        var changes = 0
        store.watchPlayer.onChanged = { changes++ }
        playing()
        assertEquals(1, changes)

        position(101.0)
        position(102.0)
        assertEquals(1, changes)

        engineState { it.copy(buffering = true) }
        engineState { it.copy(buffering = false, playbackRestarts = 1) }
        engineState { it.copy(paused = true) }
        assertEquals(4, changes)
    }

    @Test
    fun inARoomPlayAndPauseGoToTheRoomAndTheRateShowsAsTheRooms() = playerTest {
        playing()
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true

        dispatch(PlayerCommand.TogglePause)
        assertEquals(listOf("pause"), watch.presses)
        assertEquals(emptyList(), engine.paused, "the room commands the player")

        watch.roomRate = 1.5
        start { store.watchPlayer.setRate(1.56) }
        assertEquals(listOf(1.56), engine.speeds)
        assertEquals(PlayerText.speed(1.5), state.speedLabel, "the nudge doesn't show")
    }

    @Test
    fun aSpeedCommandInARoomItFollowsShowsNoSpeedToast() = playerTest {
        playing()
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        watch.state.value = watch.state.value!!.copy(following = true)
        store.attachWatch(watch)

        dispatch(PlayerCommand.SpeedUp)

        assertEquals(listOf(1.25), engine.speeds)
        assertNull(state.osd, "the room owns the rate")
    }

    /**
     * Play at the end of the file in a room starts the room over from the start, as Play does outside one: the relay
     * ends a room played from its end at once, so a bare play would only show "Finished" again.
     */
    @Test
    fun inARoomPlayAtTheEndStartsTheRoomOver() = playerTest {
        playing()
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true
        engineState { it.copy(positionSeconds = 600.0, paused = true, eof = true) }

        dispatch(PlayerCommand.TogglePause)
        assertEquals(listOf(0.0), watch.seeks, "the room goes back to the start")
        assertEquals(listOf("play"), watch.presses)
        dispatch(PlayerCommand.Play)
        assertEquals(listOf(0.0, 0.0), watch.seeks)
        assertEquals(listOf("play", "play"), watch.presses)

        engineState { it.copy(positionSeconds = 300.0, eof = false) }
        dispatch(PlayerCommand.Play)
        assertEquals(listOf(0.0, 0.0), watch.seeks, "mid-file, Play plays on")
    }

    @Test
    fun inARoomTheRoomsRateAndItsNudgesShowNoSpeedToast() = playerTest {
        playing()
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true
        watch.roomRate = 1.5

        start { store.watchPlayer.setRate(1.5) }
        start { store.watchPlayer.setRate(1.44) }
        start { store.watchPlayer.setRate(1.5) }
        assertEquals(listOf(1.5, 1.44, 1.5), engine.speeds)
        assertNull(state.osd, "the room's speed is not the viewer's change")
        assertEquals(PlayerText.speed(1.5), state.speedLabel)
    }
}
