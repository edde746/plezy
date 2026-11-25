package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.input.TouchPhase
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Edge swipes and holds on a touch screen, through the store: the levels a swipe sets and shows, how it starts, waits
 * for its level and writes it, and the speed a held finger plays at and gives back, alone, live and in a room.
 */
class TouchGesturesStoreTest {
    /** The level shown: its kind, percent and label. */
    private fun PlayerHarness.assertLevel(kind: LevelKind, percent: Int, message: String? = null) {
        val text = PlayerText.volume(percent)
        val label = if (kind == LevelKind.BRIGHTNESS) T.player.osd.brightness(text) else T.player.osd.volume(text)
        assertEquals(Triple(kind, text, label), state.level?.let { Triple(it.kind, it.percent, it.label) }, message)
        assertEquals(percent / 100f, state.level!!.fraction, 0.01f)
    }

    @Test
    fun aSwipeUpAnEdgeSetsItsLevelAndShowsItOnItsSide() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            dispatch(PlayerCommand.SetSpeed(1.5))
            assertNotNull(state.osd)
            edgeSwipe(x = 40f)
            assertEquals(0.7, levels.brightness!!, 1e-6, "84 up the 420 between the bands: +0.2")
            assertLevel(LevelKind.BRIGHTNESS, 70)
            assertNull(state.osd, "the level shows in the message's place")

            edgeSwipe(x = WIDTH - 40f, fromY = 300f, toY = 384f)
            assertEquals(0.3, levels.volume!!, 1e-6, "down the right edge: the volume down")
            assertLevel(LevelKind.VOLUME, 30)
            assertEquals(0.7, levels.brightness!!, 1e-6, "the other edge's level stays")

            advance(699.milliseconds)
            assertNotNull(state.level)
            advance(1.milliseconds)
            assertNull(state.level, "the level goes 700 ms after the swipe")
        }
    }

    @Test
    fun aSwipeStartsOnlyOnAnEdgeOutsideTheBandsThatHasSwipesOn() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            edgeSwipe(x = 200f)
            edgeSwipe(x = 40f, fromY = 80f, toY = 0f)
            edgeSwipe(x = 40f, fromY = 590f, toY = 520f)
            choices { it.copy(brightnessSwipe = false) }
            edgeSwipe(x = 40f)
            choices { it.copy(brightnessSwipe = true, volumeSwipe = false) }
            edgeSwipe(x = WIDTH - 40f)
            assertEquals(emptyList(), levels.brightnessWrites)
            assertEquals(emptyList(), levels.volumeWrites)
            assertNull(state.level)
        }
    }

    @Test
    fun aSwipeTakesAClearlyVerticalMoveAndASecondFingerEndsIt() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            val sideways = nextPointer()
            touch(TouchPhase.DOWN, sideways, 40f to 400f)
            touch(TouchPhase.MOVE, sideways, 40f to 390f)
            assertNull(state.level, "within the slop")
            touch(TouchPhase.MOVE, sideways, 80f to 395f)
            touch(TouchPhase.MOVE, sideways, 80f to 300f)
            touch(TouchPhase.UP, sideways, 80f to 300f)
            assertEquals(emptyList(), levels.brightnessWrites, "a move across first is no swipe, whatever follows")

            val first = nextPointer()
            touch(TouchPhase.DOWN, first, 40f to 400f)
            touch(TouchPhase.MOVE, first, 40f to 316f)
            val written = levels.brightnessWrites.toList()
            val second = nextPointer()
            touch(TouchPhase.DOWN, second, 400f to 300f)
            touch(TouchPhase.MOVE, first, 40f to 200f)
            touch(TouchPhase.UP, first, 40f to 200f)
            touch(TouchPhase.UP, second, 400f to 300f)
            assertEquals(written, levels.brightnessWrites, "a second finger ends the swipe")
        }
    }

    @Test
    fun aSwipeWaitsUpTo300msForItsLevelThenGivesUp() {
        val levels = FakeLevels().apply { deferReads = true }
        touchTest(levels = levels) {
            // Nothing knows the volume: its reads answer nothing until the last one.
            levels.volume = null
            val pointer = nextPointer()
            touch(TouchPhase.DOWN, pointer, 40f to 400f)
            touch(TouchPhase.MOVE, pointer, 40f to 316f)
            advance(299.milliseconds)
            assertEquals(emptyList(), levels.brightnessWrites, "the level isn't known yet")
            levels.answerReads()
            assertEquals(0.7, levels.brightnessWrites.single(), 1e-6, "it starts from the level read, with the way moved meanwhile")
            touch(TouchPhase.UP, pointer, 40f to 316f)

            val late = nextPointer()
            touch(TouchPhase.DOWN, late, WIDTH - 40f to 400f)
            touch(TouchPhase.MOVE, late, WIDTH - 40f to 316f)
            advance(300.milliseconds)
            levels.volume = 0.5
            levels.answerReads()
            touch(TouchPhase.MOVE, late, WIDTH - 40f to 250f)
            touch(TouchPhase.UP, late, WIDTH - 40f to 250f)
            assertEquals(emptyList(), levels.volumeWrites, "no level within 300 ms: the swipe gave up")
            assertNull(state.level?.takeIf { it.kind == LevelKind.VOLUME })
        }
    }

    @Test
    fun aSwipeWritesTheDeviceEvery45msByAHundredthAtLeastAndAtItsEnds() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            val pointer = nextPointer()
            touch(TouchPhase.DOWN, pointer, 40f to 400f)
            touch(TouchPhase.MOVE, pointer, 40f to 316f)
            assertEquals(1, levels.brightnessWrites.size, "the start writes at once")
            advance(45.milliseconds)
            touch(TouchPhase.MOVE, pointer, 40f to 312f)
            assertEquals(1, levels.brightnessWrites.size, "less than a hundredth more")
            touch(TouchPhase.MOVE, pointer, 40f to 311f)
            assertEquals(2, levels.brightnessWrites.size)
            touch(TouchPhase.MOVE, pointer, 40f to 290f)
            assertEquals(2, levels.brightnessWrites.size, "within 45 ms of the last write")
            assertLevel(LevelKind.BRIGHTNESS, 76, "the indicator follows every move")
            touch(TouchPhase.UP, pointer, 40f to 290f)
            assertEquals(3, levels.brightnessWrites.size, "the end writes at once")
            assertEquals(0.5 + 110.0 / 420, levels.brightnessWrites.last(), 1e-6)
        }
    }

    @Test
    fun theControlsStayAsTheyAreWhileASwipeLasts() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            dispatch(PlayerCommand.ShowControls)
            val pointer = nextPointer()
            touch(TouchPhase.DOWN, pointer, 40f to 400f)
            touch(TouchPhase.MOVE, pointer, 40f to 316f)
            advance(10.seconds)
            assertTrue(state.controlsVisible, "no auto-hide mid-swipe")
            touch(TouchPhase.UP, pointer, 40f to 316f)
            advance(4.seconds)
            assertTrue(state.controlsVisible)
            advance(1.seconds)
            assertFalse(state.controlsVisible, "the auto-hide starts over as it ends")
        }
    }

    @Test
    fun anEdgeSwipeEndsAHoldAndSwallowsTheTapsRightAfter() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            val pointer = hold(40f to 400f)
            assertEquals(listOf(2.0), engine.speeds)
            touch(TouchPhase.MOVE, pointer, 40f to 316f)
            assertEquals(listOf(2.0, 1.0), engine.speeds, "the swipe gives the speed back")
            assertNull(state.heldSpeed)
            touch(TouchPhase.UP, pointer, 40f to 316f)
            tap(CENTRE)
            assertFalse(state.controlsVisible, "a tap right after a swipe is its tail")
            advance(400.milliseconds)
            tap(CENTRE)
            assertTrue(state.controlsVisible)
        }
    }

    @Test
    fun aHoldPlaysAtTwiceTheSpeedAndTheLiftGivesBackTheSpeedItHad() = touchTest {
        dispatch(PlayerCommand.SetSpeed(1.5))
        advance(2.seconds)

        val pointer = hold()
        assertEquals(2.0, engine.speeds.last())
        assertEquals(PlayerText.speed(2.0), state.heldSpeed)
        assertNull(state.osd, "the held speed shows in its own place, not as a message")

        lift(pointer)
        assertEquals(listOf(1.5, 2.0, 1.5), engine.speeds)
        assertNull(state.heldSpeed)
        assertNull(state.osd, "giving the speed back shows no message")
        assertEquals(PlayerText.speed(1.5), state.speedLabel)
        advance(400.milliseconds)
        assertFalse(state.controlsVisible, "the hold's lift is no tap")
    }

    @Test
    fun aFingerThatMovesOrIsJoinedByASecondIsNoHold() = touchTest {
        val moving = nextPointer()
        touch(TouchPhase.DOWN, moving, CENTRE)
        touch(TouchPhase.MOVE, moving, CENTRE.first + 30f to CENTRE.second)
        advance(600.milliseconds)
        touch(TouchPhase.UP, moving, CENTRE.first + 30f to CENTRE.second)

        val first = nextPointer()
        val second = nextPointer()
        touch(TouchPhase.DOWN, first, CENTRE)
        touch(TouchPhase.DOWN, second, CENTRE.first + 40f to CENTRE.second)
        advance(600.milliseconds)
        touch(TouchPhase.UP, first, CENTRE)
        touch(TouchPhase.UP, second, CENTRE.first + 40f to CENTRE.second)
        assertEquals(emptyList(), engine.speeds)
    }

    @Test
    fun noHoldLive() = touchTest {
        sessionInfo { it.copy(live = true) }
        lift(hold())
        assertEquals(emptyList(), engine.speeds)
        assertNull(state.heldSpeed)
    }

    @Test
    fun noGestureActsInPictureInPictureOrWithTheContentStripOpen() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            for (blocked in listOf("picture in picture", "content strip")) {
                if (blocked == "picture in picture") store.onPictureInPictureChanged(true) else dispatch(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP))
                doubleTap(FORWARD)
                twoFingerTap()
                edgeSwipe(x = 40f)
                lift(hold())
                assertEquals(emptyList(), engine.seeks, blocked)
                assertEquals(emptyList(), engine.paused, blocked)
                assertEquals(emptyList(), engine.speeds, blocked)
                assertEquals(emptyList(), levels.brightnessWrites, blocked)
                store.onPictureInPictureChanged(false)
            }
        }
    }

    /**
     * Holding in a room this device controls changes the room's speed, so everyone plays at 2× together, and the lift
     * gives everyone back the room's speed: not the player's own while the room nudges it to catch up.
     */
    @Test
    fun inARoomThisDeviceControlsTheHoldIsTheRoomsSpeedForEveryone() = touchTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true
        watch.roomRate = 1.25
        start { store.watchPlayer.setRate(1.3) }

        val pointer = hold()
        assertEquals(listOf(2.0), watch.rates)
        lift(pointer)
        assertEquals(listOf(2.0, 1.25), watch.rates)
        assertEquals(listOf(1.3, 2.0, 1.25), engine.speeds)
    }

    @Test
    fun aGuestWhoDoesntControlTheRoomHoldsNothingAndIsToldWhy() = touchTest {
        val watch = FakeWatch(canControl = false, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true

        val pointer = hold()
        assertEquals("Only the host controls playback", state.osd)
        lift(pointer)
        assertEquals(emptyList(), engine.speeds)
        assertEquals(emptyList(), watch.rates)
        assertNull(state.heldSpeed)
    }

    /** The host takes control away during a hold: the speed is the room's now, and the lift changes nothing. */
    @Test
    fun aHoldWhenTheRoomTakesControlAwayEndsWhereItIs() = touchTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true

        val pointer = hold()
        watch.state.value = watch.state.value?.copy(canControl = false)
        advance(0.seconds)
        lift(pointer)
        assertEquals(listOf(2.0), watch.rates)
        assertEquals(listOf(2.0), engine.speeds)
        assertNull(state.heldSpeed)
    }
}
