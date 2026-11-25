package com.edde746.plezy.presentation.player

import com.edde746.plezy.presentation.player.MovableBarButton.PICTURE_IN_PICTURE
import com.edde746.plezy.presentation.player.MovableBarButton.ROTATION_LOCK
import com.edde746.plezy.presentation.player.MovableBarButton.SCREEN_LOCK
import com.edde746.plezy.presentation.player.MovableBarButton.VIDEO_FIT
import kotlin.test.Test
import kotlin.test.assertEquals

/** The top bar's movable buttons: which a narrow bar moves into the options sheet, in which order, from what width. */
class TopBarButtonsTest {
    private val all = MovableBarButton.entries.toSet()

    /** A 1000-wide bar whose title keeps its 40 % (400) and whose fixed part leaves [room] for the movable buttons. */
    private fun moved(room: Float, present: Set<MovableBarButton> = all) =
        TopBarButtons.moved(present, barWidth = 1000f, fixedWidth = 600f - room, lineWidth = 0f, buttonWidth = 40f, gap = 2f)

    @Test
    fun buttonsMoveOneAtATimeInTheirOrderAsTheRoomShrinks() {
        assertEquals(emptySet(), moved(4 * 40f + 3 * 2f))
        assertEquals(setOf(ROTATION_LOCK), moved(3 * 40f + 2 * 2f))
        assertEquals(setOf(ROTATION_LOCK, VIDEO_FIT), moved(2 * 40f + 2f))
        assertEquals(setOf(ROTATION_LOCK, VIDEO_FIT, PICTURE_IN_PICTURE), moved(40f))
        assertEquals(all, moved(39f))
        assertEquals(all, moved(-200f), "an overfull bar moves them all and no more")
    }

    @Test
    fun aButtonStaysOnlyWhileItFitsWhole() {
        assertEquals(setOf(ROTATION_LOCK, VIDEO_FIT), moved(2 * 40f + 2f), "two buttons and their gap: two stay")
        assertEquals(setOf(ROTATION_LOCK, VIDEO_FIT, PICTURE_IN_PICTURE), moved(2 * 40f + 2f - 0.5f), "half a unit short: one")
    }

    @Test
    fun anAbsentButtonIsSkippedAndTheOrderKept() {
        val noPip = setOf(ROTATION_LOCK, VIDEO_FIT, SCREEN_LOCK)
        assertEquals(setOf(ROTATION_LOCK, VIDEO_FIT), moved(40f, noPip))
        assertEquals(setOf(ROTATION_LOCK), moved(2 * 40f + 2f, noPip))
        assertEquals(setOf(VIDEO_FIT), moved(40f, setOf(VIDEO_FIT, SCREEN_LOCK)))
        assertEquals(emptySet(), moved(0f, emptySet()))
    }

    /** The title keeps 40 % of the bar, or one line of twelve characters where that is wider: the bar's width decides. */
    @Test
    fun theTitleKeepsTheLargerOfItsShareAndOneReadableLine() {
        fun moved(bar: Float, line: Float) =
            TopBarButtons.moved(all, barWidth = bar, fixedWidth = 100f, lineWidth = line, buttonWidth = 40f, gap = 2f)
        // 400 wide: the share (160) leaves 140 = three buttons.
        assertEquals(setOf(ROTATION_LOCK), moved(400f, line = 150f))
        // A line wider than the share takes its place: 200 leaves 100 = two buttons.
        assertEquals(setOf(ROTATION_LOCK, VIDEO_FIT), moved(400f, line = 200f))
        // A wider bar: its share (240 of 600) leaves 260, all four.
        assertEquals(emptySet(), moved(600f, line = 200f))
    }
}
