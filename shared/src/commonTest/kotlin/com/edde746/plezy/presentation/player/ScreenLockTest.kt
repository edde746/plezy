package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.input.TouchPhase
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * The screen lock on a touch screen has to hold against a small child: what a locked screen ignores, what still works
 * through it, the hold that unlocks it (a tap shows the unlock button, a finger held on it for a second unlocks), and
 * how long it lasts. A tap on the button, a hold on the picture, a moving finger or a second finger never unlocks.
 */
class ScreenLockTest {
    /** Locked from the top bar's lock button, with the controls up, as the viewer does. */
    private fun locked(body: PlayerHarness.(FakeLevels) -> Unit) {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            assertEquals(T.player.lock.button, state.lockLabel, "a touch screen offers the lock")
            dispatch(PlayerCommand.ShowControls)
            dispatch(PlayerCommand.LockScreen)
            assertNotNull(state.screenLock)
            assertFalse(state.controlsVisible)
            body(levels)
        }
    }

    private val PlayerHarness.prompt: String? get() = state.screenLock?.unlock?.label
    private val PlayerHarness.holding: Boolean get() = state.screenLock?.unlock?.holding == true

    /** A finger on the unlock button for [held], as the views send it: its touches, and the hold after its down and up. */
    private fun PlayerHarness.holdButton(held: Duration) {
        val pointer = nextPointer()
        touch(TouchPhase.DOWN, pointer, UNLOCK_BUTTON)
        dispatch(PlayerCommand.UnlockHold(held = true))
        advance(held)
        touch(TouchPhase.UP, pointer, UNLOCK_BUTTON)
        dispatch(PlayerCommand.UnlockHold(held = false))
        advance(250.milliseconds)
    }

    private fun PlayerHarness.tapPicture() {
        tap(CENTRE)
        advance(250.milliseconds)
    }

    @Test
    fun aTapShowsTheButtonAndHoldingItForASecondUnlocksWithoutTouchingPlayback() = locked {
        assertEquals(T.player.lock.holdToUnlock, prompt, "locking shows the way out")
        advance(3.seconds)
        assertNull(prompt, "the prompt fades after locking")

        tapPicture()
        assertEquals(T.player.lock.holdToUnlock, prompt)
        val pointer = nextPointer()
        touch(TouchPhase.DOWN, pointer, UNLOCK_BUTTON)
        dispatch(PlayerCommand.UnlockHold(held = true))
        assertTrue(holding, "the button fills while held")
        advance(UnlockButton.HOLD_MILLIS.milliseconds - 1.milliseconds)
        assertNotNull(state.screenLock, "not before the whole second")
        advance(1.milliseconds)
        assertNull(state.screenLock)
        touch(TouchPhase.UP, pointer, UNLOCK_BUTTON)
        dispatch(PlayerCommand.UnlockHold(held = false))

        advance(400.milliseconds)
        assertTrue(state.controlsVisible, "unlocking shows the controls, and its finger reaches nothing under the shield")
        assertEquals(emptyList(), engine.paused)
    }

    @Test
    fun aTapOnTheButtonKeepsItUpWithItsHintAndUnlocksNothing() = locked {
        advance(2.seconds)
        holdButton(300.milliseconds)
        assertEquals(T.player.lock.holdToUnlock, prompt, "a tap on the button doesn't hide it")
        assertFalse(holding, "the fill goes as the finger lifts")
        advance(2.seconds)
        assertNotNull(prompt, "let go, the button stays up for the full time again")
        advance(1.seconds)
        assertNull(prompt)
        assertNotNull(state.screenLock)
        assertEquals(emptyList(), engine.paused)
    }

    @Test
    fun aPointerHeldOnTheButtonUnlocksToo() = locked {
        dispatch(PlayerCommand.UnlockHold(held = true))
        advance(UnlockButton.HOLD_MILLIS.milliseconds)
        assertNull(state.screenLock)
    }

    @Test
    fun aScreenReadersPressUnlocksAtOnce() = locked {
        dispatch(PlayerCommand.UnlockPress)
        assertNull(state.screenLock)
        assertTrue(state.controlsVisible)
    }

    @Test
    fun holdingThePictureOrAHiddenButtonNeverUnlocks() = locked {
        val onPicture = nextPointer()
        touch(TouchPhase.DOWN, onPicture, CENTRE)
        advance(10.seconds)
        touch(TouchPhase.UP, onPicture, CENTRE)
        assertNull(prompt, "a hold on the picture is no tap")
        assertNotNull(state.screenLock)
        assertEquals(emptyList(), engine.paused)
        assertEquals(emptyList(), engine.speeds, "no hold plays at 2× through the lock")

        // The hidden button is no target.
        holdButton(2.seconds)
        assertNotNull(state.screenLock)
    }

    @Test
    fun aFingerThatMovesOffTheButtonLetsGo() = locked {
        val pointer = nextPointer()
        touch(TouchPhase.DOWN, pointer, UNLOCK_BUTTON)
        dispatch(PlayerCommand.UnlockHold(held = true))
        advance(500.milliseconds)
        touch(TouchPhase.MOVE, pointer, UNLOCK_BUTTON.first + 80f to UNLOCK_BUTTON.second)
        assertFalse(holding)
        advance(2.seconds)
        touch(TouchPhase.UP, pointer, UNLOCK_BUTTON.first + 80f to UNLOCK_BUTTON.second)
        dispatch(PlayerCommand.UnlockHold(held = false))
        assertNotNull(state.screenLock)
        assertEquals(T.player.lock.holdToUnlock, prompt)
    }

    @Test
    fun aContactWithASecondFingerCountsForNothing() = locked {
        val first = nextPointer()
        val second = nextPointer()
        touch(TouchPhase.DOWN, first, UNLOCK_BUTTON)
        dispatch(PlayerCommand.UnlockHold(held = true))
        touch(TouchPhase.DOWN, second, CENTRE)
        advance(2.seconds)
        touch(TouchPhase.UP, first, UNLOCK_BUTTON)
        dispatch(PlayerCommand.UnlockHold(held = false))
        touch(TouchPhase.UP, second, CENTRE)
        advance(250.milliseconds)
        assertNull(prompt, "a second finger hides the button")
        assertNotNull(state.screenLock)
        assertEquals(emptyList(), engine.paused, "the two-finger pause is locked out too")

        tapPicture()
        holdButton(UnlockButton.HOLD_MILLIS.milliseconds)
        assertNull(state.screenLock, "the next one-finger hold works again")
    }

    @Test
    fun noTouchActsWhileLocked() = locked { levels ->
        assertNull(state.menu)
        val layouts = engine.layouts.toList()
        val writes = levels.brightnessWrites.size to levels.volumeWrites.size

        doubleTap(FORWARD)
        doubleTap(BACKWARD)
        twoFingerTap()
        edgeSwipe(x = 40f)
        edgeSwipe(x = WIDTH - 40f)
        val first = nextPointer()
        val second = nextPointer()
        touch(TouchPhase.DOWN, first, 300f to 300f)
        touch(TouchPhase.DOWN, second, 500f to 300f)
        touch(TouchPhase.MOVE, second, 700f to 300f)
        touch(TouchPhase.MOVE, second, 750f to 300f)
        touch(TouchPhase.MOVE, second, 780f to 300f)
        touch(TouchPhase.UP, first, 300f to 300f)
        touch(TouchPhase.UP, second, 780f to 300f)
        lift(hold())
        input(InputEvent.PointerMove)
        advance(1.seconds)

        assertEquals(emptyList(), engine.paused, "no tap pauses")
        assertEquals(emptyList(), engine.seeks, "no double tap seeks")
        assertEquals(layouts, engine.layouts, "no pinch zooms")
        assertEquals(writes, levels.brightnessWrites.size to levels.volumeWrites.size, "no swipe changes a level")
        assertEquals(emptyList(), engine.speeds, "no hold plays at 2×")
        assertNull(state.heldSpeed)
        assertNull(state.level)
        assertNull(state.osd)
        assertFalse(state.controlsVisible, "no touch shows the controls")
        assertNull(state.menu)
    }

    /** Locking hides the controls whatever kept them up, ends a hold and an edge swipe, and closes a menu. */
    @Test
    fun lockingHidesTheControlsAndEndsWhatAFingerWasDoing() {
        val levels = FakeLevels()
        touchTest(levels = levels) {
            val swiping = nextPointer()
            touch(TouchPhase.DOWN, swiping, 40f to 400f)
            touch(TouchPhase.MOVE, swiping, 40f to 316f)
            assertNotNull(state.level)
            dispatch(PlayerCommand.Pause)
            dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
            dispatch(PlayerCommand.LockScreen)
            assertFalse(state.controlsVisible, "paused, with a menu open")
            assertNull(state.menu)
            val written = levels.brightnessWrites.size
            touch(TouchPhase.MOVE, swiping, 40f to 200f)
            touch(TouchPhase.UP, swiping, 40f to 200f)
            assertEquals(written, levels.brightnessWrites.size, "the swipe ended with the lock")
        }
    }

    @Test
    fun mediaKeysTheSystemsControlsAndPictureInPictureStillWork() = locked {
        dispatch(PlayerCommand.SystemPause)
        assertEquals(listOf(true), engine.paused, "the system's Now Playing pause")
        assertFalse(state.controlsVisible, "paused, a locked screen keeps the controls hidden")
        dispatch(PlayerCommand.SystemResume)
        assertEquals(listOf(true, false), engine.paused)

        input(InputEvent.KeyDown(InputKey.MEDIA_PLAY_PAUSE))
        input(InputEvent.KeyUp(InputKey.MEDIA_PLAY_PAUSE))
        assertEquals(listOf(true, false, true), engine.paused, "a headset's or keyboard's play/pause key")
        store.onVisibleChanged(false)
        store.onPictureInPictureChanged(true)
        dispatch(PlayerCommand.SystemResume)
        assertTrue(store.inPictureInPicture.value)
        assertTrue(state.keepAwake, "playing on in the picture-in-picture window")
        store.onPictureInPictureChanged(false)
        store.onVisibleChanged(true)
        assertNotNull(state.screenLock, "the lock is still on after picture in picture")
    }

    @Test
    fun theLockLastsThroughTheNextEpisodeAndBackLeavesThePlayer() = locked {
        sessionInfo { it.copy(episode = true, nextEpisode = NextEpisode(title = "Chapter Two", subtitle = "S1E2")) }
        dispatch(PlayerCommand.NextEpisode)
        assertEquals(1, session.nextEpisodes)
        playing(position = 0.0)
        assertNotNull(state.screenLock, "the next episode plays locked")
        assertFalse(state.controlsVisible)

        dispatch(PlayerCommand.Back)
        assertEquals(1, host.closed, "Back leaves the player, the lock with it")
    }

    @Test
    fun onlyATouchScreenLocks() = playerTest(InputProfile.DESKTOP) {
        playing()
        assertNull(state.lockLabel)
        dispatch(PlayerCommand.LockScreen)
        assertNull(state.screenLock)
        assertTrue(state.controlsVisible)
    }
}
