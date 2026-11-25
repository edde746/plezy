package com.edde746.plezy.presentation.livetv.guide

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Where a program block's text goes as the grid scrolls sideways, when it shows none, and where the grid scrolls to. */
class GuideLayoutTest {
    private val halfHour = GuideLayout.SLOT_WIDTH
    private val gap = 4.0

    @Test
    fun aBlockInViewStartsItsTextAtItsPadding() {
        assertEquals(GuideLayout.TEXT_PADDING, guideBlockTextInset(left = 360.0, width = halfHour, scrollOffset = 300.0, gap = gap))
    }

    @Test
    fun aBlockBegunBeforeTheTimeShownStartsItsTextWhereTheViewStarts() {
        assertEquals(GuideLayout.TEXT_PADDING + 100, guideBlockTextInset(left = 0.0, width = 2 * halfHour, scrollOffset = 100.0, gap = gap))
    }

    @Test
    fun aBlockShowingTooLittleOfItselfPastTheViewsStartShowsNoText() {
        // Half an hour with 50 points of it left in view: 50 less the gap and the padding each side holds no title.
        assertNull(guideBlockTextInset(left = 0.0, width = halfHour, scrollOffset = halfHour - 50, gap = gap))
        assertNull(guideBlockTextInset(left = 0.0, width = halfHour, scrollOffset = halfHour + 50, gap = gap))
    }

    @Test
    fun anAiringTooShortForATitleShowsNoText() {
        // Eight minutes: 48 points wide.
        assertNull(guideBlockTextInset(left = 360.0, width = halfHour * 8 / 30, scrollOffset = 0.0, gap = gap))
    }

    @Test
    fun aBlockWithRoomForAShortWordStillShowsItsText() {
        val width = GuideLayout.MIN_TEXT_WIDTH + 2 * GuideLayout.TEXT_PADDING + gap
        assertEquals(GuideLayout.TEXT_PADDING, guideBlockTextInset(left = 360.0, width = width, scrollOffset = 0.0, gap = gap))
    }

    @Test
    fun anAiringBroughtIntoViewStartsTheViewSoNoSliverOfTheOneBeforeShows() {
        // Past the view's end, then before its start: the view starts where the airing does.
        assertEquals(10 * halfHour, guideProgramScrollOffset(left = 10 * halfHour, currentOffset = 0.0, viewportWidth = 1000.0, maxScroll = 5000.0))
        assertEquals(2 * halfHour, guideProgramScrollOffset(left = 2 * halfHour, currentOffset = 3 * halfHour, viewportWidth = 1000.0, maxScroll = 5000.0))
        assertNull(guideProgramScrollOffset(left = 4 * halfHour, currentOffset = 3 * halfHour, viewportWidth = 1000.0, maxScroll = 5000.0))
    }

    @Test
    fun nowScrolledIntoAWideViewStartsTheViewAtTheStartOfASlot() {
        // Now 100 minutes in (600 points), a third of a 900 point view before it: 300 points in, so the view starts at
        // the start of that slot, 180, now's slot (540 to 720) whole in it.
        assertEquals(halfHour, guideScrollToNowOffset(nowOffset = 100.0 / 30 * halfHour, viewportWidth = 900.0, maxScroll = 5000.0))
        assertEquals(0.0, guideScrollToNowOffset(nowOffset = 60.0, viewportWidth = 900.0, maxScroll = 5000.0))
    }

    @Test
    fun nowScrolledIntoANarrowViewStartsTheViewAtNowsOwnSlot() {
        // A 300 point view: from the slot a third of the way before now (360) now's slot would end past the view (720
        // after 660), so the view starts at now's slot, whatever the minute; a view narrower than a slot puts now a
        // third of the way across.
        assertEquals(3 * halfHour, guideScrollToNowOffset(nowOffset = 600.0, viewportWidth = 300.0, maxScroll = 5000.0))
        assertEquals(3 * halfHour, guideScrollToNowOffset(nowOffset = 3 * halfHour + 5, viewportWidth = 300.0, maxScroll = 5000.0))
        assertEquals(3 * halfHour, guideScrollToNowOffset(nowOffset = 4 * halfHour - 5, viewportWidth = 300.0, maxScroll = 5000.0))
        assertEquals(550.0, guideScrollToNowOffset(nowOffset = 600.0, viewportWidth = 150.0, maxScroll = 5000.0))
    }
}
