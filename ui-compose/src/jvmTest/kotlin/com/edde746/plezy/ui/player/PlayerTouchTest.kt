package com.edde746.plezy.ui.player

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.TouchInjectionScope
import androidx.compose.ui.test.click
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeUp
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.TouchPhase
import com.edde746.plezy.model.FormFactor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The fingers on the video on a phone, the controls down, go to the store as they are (the store tells the gestures
 * apart): each finger's down, moves and lift, where it is over the player's size; a mouse's click stays a click.
 */
@OptIn(ExperimentalTestApi::class)
class PlayerTouchTest {
    private fun touches(gesture: TouchInjectionScope.() -> Unit): List<InputEvent> {
        val events = mutableListOf<InputEvent>()
        runComposeUiTest {
            player(FormFactor.HANDHELD, onInput = { events += it; true }) {
                testPlayerState().copy(controlsVisible = false)
            }
            onRoot().performTouchInput(gesture)
            waitForIdle()
        }
        return events
    }

    @Test
    fun aTapIsAFingerDownAndUpWhereItIs() {
        val events = touches { click(Offset(width * 0.8f, height * 0.5f)) }.filterIsInstance<InputEvent.Touch>()
        assertEquals(listOf(TouchPhase.DOWN, TouchPhase.UP), events.map { it.phase })
        assertEquals(1, events.map { it.pointer }.distinct().size, "one finger")
        for (touch in events) {
            assertEquals(0.8f, touch.x / touch.width, 0.01f)
            assertEquals(0.5f, touch.y / touch.height, 0.01f)
        }
    }

    @Test
    fun aDragSendsEveryMove() {
        val events = touches { swipeUp(startY = height * 0.8f, endY = height * 0.3f, durationMillis = 300) }
        val touches = events.filterIsInstance<InputEvent.Touch>()
        assertEquals(events.size, touches.size, "only touches: $events")
        assertEquals(TouchPhase.DOWN, touches.first().phase)
        assertEquals(TouchPhase.UP, touches.last().phase)
        val moves = touches.filter { it.phase == TouchPhase.MOVE }
        assertTrue(moves.size > 1, "the moves: $touches")
        assertTrue(moves.zipWithNext().all { (a, b) -> b.y <= a.y }, "up the player: $moves")
        assertEquals(0.3f, touches.last().y / touches.last().height, 0.02f)
    }

    @Test
    fun twoFingersAreTwoPointers() {
        val events = touches {
            down(0, Offset(width * 0.4f, height * 0.5f))
            down(1, Offset(width * 0.6f, height * 0.5f))
            up(0)
            up(1)
        }.filterIsInstance<InputEvent.Touch>()
        assertEquals(listOf(TouchPhase.DOWN, TouchPhase.DOWN, TouchPhase.UP, TouchPhase.UP), events.map { it.phase })
        assertEquals(2, events.map { it.pointer }.distinct().size)
    }

    @Test
    fun aMouseClickIsAClick() {
        val events = mutableListOf<InputEvent>()
        runComposeUiTest {
            player(FormFactor.HANDHELD, onInput = { events += it; true }) {
                testPlayerState().copy(controlsVisible = false)
            }
            onRoot().performMouseInput { click(Offset(width * 0.8f, height * 0.5f)) }
            waitForIdle()
        }
        assertEquals(listOf(0.8f), events.filterIsInstance<InputEvent.Click>().map { it.x })
        assertEquals(emptyList(), events.filterIsInstance<InputEvent.Touch>())
    }
}
