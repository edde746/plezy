package com.edde746.plezy.presentation.player

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** [PlayerChrome]: when the player's controls show and hide by themselves. */
@OptIn(ExperimentalCoroutinesApi::class)
class PlayerChromeTest {
    private fun chromeTest(initiallyVisible: Boolean = true, body: suspend TestScope.(PlayerChrome) -> Unit) = runTest {
        val chrome = PlayerChrome(backgroundScope, testScheduler.timeSource, initiallyVisible)
        body(chrome)
    }

    private fun TestScope.pump(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    @Test
    fun autoHidesVisibleControlsWhilePlaying() = chromeTest { chrome ->
        chrome.configure(hideDelay = 100.milliseconds)
        chrome.setPlaying(true)
        assertTrue(chrome.visible)
        pump(99.milliseconds)
        assertTrue(chrome.visible)
        pump(1.milliseconds)
        assertFalse(chrome.visible)
    }

    @Test
    fun visibleHoldsSuppressAutoHideUntilReleased() = chromeTest { chrome ->
        chrome.configure(hideDelay = 100.milliseconds)
        chrome.setPlaying(true)
        chrome.hold(ChromeHold.PROMPT_INTERACTION)
        pump(200.milliseconds)
        assertTrue(chrome.visible)
        chrome.release(ChromeHold.PROMPT_INTERACTION)
        pump(100.milliseconds)
        assertFalse(chrome.visible)
    }

    @Test
    fun pausedControlsStayUntilDismissedAndHideAgainOncePlaying() = chromeTest { chrome ->
        chrome.configure(hideDelay = 100.milliseconds)
        chrome.setPlaying(true)
        pump(50.milliseconds)
        // Pausing also disarms the playing timer already running.
        chrome.setPlaying(false)
        pump(10.seconds)
        assertTrue(chrome.visible, "a paused picture keeps its controls")
        chrome.show()
        assertTrue(chrome.recordPointerActivity())
        chrome.hold(ChromeHold.PROMPT_INTERACTION)
        chrome.release(ChromeHold.PROMPT_INTERACTION)
        chrome.configure(hideDelay = 200.milliseconds)
        pump(10.seconds)
        assertTrue(chrome.visible, "nothing done while paused starts a timer")
        chrome.setPlaying(true)
        pump(199.milliseconds)
        assertTrue(chrome.visible)
        pump(1.milliseconds)
        assertFalse(chrome.visible, "playing again, they hide after the delay")
    }

    @Test
    fun pointerActivityIsThrottledWhileTheControlsShow() = chromeTest { chrome ->
        chrome.configure(hideDelay = 1.seconds)
        assertTrue(chrome.recordPointerActivity())
        pump(119.milliseconds)
        assertFalse(chrome.recordPointerActivity(), "within 120 ms")
        pump(1.milliseconds)
        assertTrue(chrome.recordPointerActivity())
    }

    @Test
    fun losingTheFirstFrameCancelsAutoHideAndRegainingItRestartsIt() = chromeTest { chrome ->
        chrome.configure(hideDelay = 100.milliseconds)
        chrome.setPlaying(true)
        chrome.configure(hasFirstFrame = false)
        pump(1.seconds)
        assertTrue(chrome.visible)
        chrome.configure(hasFirstFrame = true)
        pump(100.milliseconds)
        assertFalse(chrome.visible)
    }

    @Test
    fun showStoresAPlayPauseFocusRequestEvenWhenAlreadyVisible() = chromeTest { chrome ->
        var changes = 0
        val counted = PlayerChrome(backgroundScope, testScheduler.timeSource, onChange = { changes++ })
        counted.show(focusPlayPause = true)
        assertEquals(1, changes)
        assertTrue(counted.pendingPlayPauseFocus)
        assertTrue(counted.takePlayPauseFocus())
        assertFalse(counted.takePlayPauseFocus())
    }

    @Test
    fun aHiddenStartHasNothingToHide() = chromeTest(initiallyVisible = false) { chrome ->
        assertFalse(chrome.visible)
        assertFalse(chrome.hide(), "there is nothing to hide, so Back falls through to the screen")
        chrome.show()
        assertTrue(chrome.visible)
    }

    @Test
    fun aHoldShowsTheControlsAndHideIgnoringHoldsBypassesIt() = chromeTest(initiallyVisible = false) { chrome ->
        chrome.hold(ChromeHold.SCRUB)
        assertTrue(chrome.visible)
        assertFalse(chrome.hide())
        assertTrue(chrome.hide(ignoreHolds = true))
        assertFalse(chrome.visible)
    }

    @Test
    fun aSilentReleaseRestartsNothing() = chromeTest { chrome ->
        chrome.configure(hideDelay = 100.milliseconds)
        chrome.setPlaying(true)
        chrome.hold(ChromeHold.PROMPT_INTERACTION)
        chrome.release(ChromeHold.PROMPT_INTERACTION, restartAutoHide = false)
        assertFalse(chrome.isHeld(ChromeHold.PROMPT_INTERACTION))
        pump(1.seconds)
        assertTrue(chrome.visible)
    }

    @Test
    fun hoverShowsAndLeavingHidesWhilePlaying() = chromeTest(initiallyVisible = false) { chrome ->
        chrome.setPlaying(true)
        chrome.recordPointerActivity()
        assertTrue(chrome.visible)
        chrome.pointerExit()
        assertFalse(chrome.visible)
    }

    @Test
    fun leavingWhilePausedKeepsTheControls() = chromeTest { chrome ->
        chrome.setPlaying(true)
        chrome.setPlaying(false)
        chrome.pointerExit()
        assertTrue(chrome.visible)
    }

    @Test
    fun leavingInPictureInPictureKeepsTheControls() = chromeTest { chrome ->
        chrome.setPlaying(true)
        chrome.hold(ChromeHold.PIP)
        chrome.pointerExit()
        assertTrue(chrome.visible)
    }

    @Test
    fun aPressDraggedOutHidesOnReleaseUnlessItCameBack() = chromeTest { chrome ->
        chrome.setPlaying(true)
        chrome.pointerDown(1)
        chrome.pointerExit()
        assertTrue(chrome.visible, "the press holds them")
        chrome.pointerUp(1)
        assertFalse(chrome.visible, "hidden as it lifts")

        chrome.show()
        chrome.pointerDown(2)
        chrome.pointerDown(3)
        chrome.pointerExit()
        chrome.pointerEnter()
        chrome.pointerUp(2)
        assertTrue(chrome.isHeld(ChromeHold.POINTER_PRESS), "another pointer is still down")
        chrome.pointerUp(3)
        assertTrue(chrome.visible, "it came back before lifting")
    }
}
