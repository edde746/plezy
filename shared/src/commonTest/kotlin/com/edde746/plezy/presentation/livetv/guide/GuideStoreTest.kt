package com.edde746.plezy.presentation.livetv.guide

import com.edde746.plezy.input.InputKey
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.groupLiveTvChannelsBySource
import com.edde746.plezy.livetv.scopeKey
import com.edde746.plezy.presentation.livetv.localWallTime
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNotSame
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant

class GuideStoreTest {
    private fun TestScope.wait(millis: Long) {
        advanceTimeBy(millis)
        runCurrent()
    }

    @Test
    fun theGuideOpensAnHourBeforeTheCurrentHalfHourForSixHours() = runTest {
        val h = GuideHarness.oneServer(this)
        val request = h.serverA.requests.single()
        assertEquals(Instant.fromEpochSeconds(NOW_WINDOW_START), request.from)
        assertEquals(Instant.fromEpochSeconds(NOW_WINDOW_START + 6 * 3600), request.to)
        assertTrue(h.state.showsFullSpinner)

        h.completeInitial()
        val state = h.state
        assertFalse(state.isLoading)
        assertEquals("Now", state.dayLabel, "the live window is named by its pick, not by its start an hour back")
        assertNull(state.timeLabel)
        assertEquals(12, state.timeMarks.size)
        assertEquals(listOf("18:30", "19:00"), state.timeMarks.take(2).map { it.label })
        assertEquals(listOf(0.0, 180.0), state.timeMarks.take(2).map { it.left })
        // 70 minutes in: two slots and a third of one.
        assertEquals(420.0, state.nowOffset)
        assertEquals(GuideHorizontalScroll.ToNow(420.0), state.scroll?.horizontal)
    }

    @Test
    fun selectHoldSurvivesEquivalentFreshGuideObjectsAndOpensDetailsOnce() = runTest {
        val h = GuideHarness.oneServer(this, isTv = true)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.press(InputKey.DOWN)
        h.press(InputKey.RIGHT)
        val pressed = assertNotNull(h.state.focus.program)
        assertEquals("Slot 3", pressed.title)

        h.down(InputKey.SELECT)
        wait(250)
        // A reload away and back hands the guide fresh objects of the same airings.
        h.store.selectTimeNav(GuideTimeNavItem.LATER)
        h.store.selectTimeNav(GuideTimeNavItem.EARLIER)
        runCurrent()
        val fresh = h.serverA.slots(0, NOW_WINDOW_START, 12)
        h.serverA.requests[2].answer.complete(fresh)
        runCurrent()
        assertNotSame(pressed, h.state.focus.program)
        assertEquals(pressed, h.state.focus.program)

        wait(249)
        assertEquals(emptyList(), h.events)
        wait(1)
        assertEquals(listOf<GuideEvent>(GuideEvent.ShowDetails(h.channels[0], fresh[2])), h.events)

        wait(1000)
        h.store.onKeyUp(InputKey.SELECT)
        runCurrent()
        assertEquals(1, h.events.size)
    }

    @Test
    fun selectHoldDoesNotOpenDetailsAfterFocusMovesToADifferentAiring() = runTest {
        val h = GuideHarness.oneServer(this, isTv = true)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.press(InputKey.DOWN)
        h.press(InputKey.RIGHT)

        h.down(InputKey.SELECT)
        wait(250)
        h.down(InputKey.RIGHT)
        assertEquals("Slot 4", h.focusedCell())
        wait(250)
        assertEquals(emptyList(), h.events)
        wait(1000)
        h.store.onKeyUp(InputKey.SELECT)
        runCurrent()
        assertEquals(emptyList(), h.events)
    }

    @Test
    fun aSupersededGuideLoadKeepsOneIntervalAndCannotReplaceCurrentPrograms() = runTest {
        val h = GuideHarness.twoServers(this)
        h.completeInitial()

        h.store.selectTimeNav(GuideTimeNavItem.LATER)
        h.store.selectTimeNav(GuideTimeNavItem.LATER)
        runCurrent()
        assertEquals(3, h.serverA.requests.size)
        val older = h.serverA.requests[1]
        val newer = h.serverA.requests[2]
        assertEquals(6 * 3600L, older.to.epochSeconds - older.from.epochSeconds)
        assertEquals(6 * 3600L, newer.to.epochSeconds - newer.from.epochSeconds)
        assertEquals(2 * 3600L, newer.from.epochSeconds - older.from.epochSeconds)

        h.serverA.complete(2, "Current A")
        runCurrent()
        assertEquals(2, h.serverB.requests.size)
        assertEquals(newer.from, h.serverB.requests[1].from)
        assertEquals(newer.to, h.serverB.requests[1].to)

        h.serverB.complete(1, "Current B")
        runCurrent()
        assertEquals(listOf("Current A"), h.titles("A"))
        assertEquals(listOf("Current B"), h.titles("B"))

        h.serverA.complete(1, "Obsolete A")
        runCurrent()
        assertEquals(2, h.serverB.requests.size)
        assertEquals(listOf("Current A"), h.titles("A"))
        assertEquals(listOf("Current B"), h.titles("B"))
    }

    @Test
    fun twoHoursEarlierOpensTheGridAtTheWindowStartItsLabelShowsAndNowScrollsBackToNow() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()

        h.store.selectTimeNav(GuideTimeNavItem.EARLIER)
        runCurrent()
        h.serverA.complete(1, "Earlier")
        runCurrent()
        assertEquals("Today", h.state.dayLabel)
        assertEquals("16:30", h.state.timeLabel)
        assertEquals(GuideHorizontalScroll.ToProgram(0.0), h.state.scroll?.horizontal)

        h.store.selectTimeNav(GuideTimeNavItem.DAY)
        val now = assertIs<GuideMenu.Days>(h.state.menu).choices.first()
        h.store.pickDay(now)
        runCurrent()
        h.serverA.complete(2, "Now")
        runCurrent()
        assertEquals(GuideHorizontalScroll.ToNow(420.0), h.state.scroll?.horizontal)
        assertEquals("Now", h.state.dayLabel)
    }

    @Test
    fun thePillNamesTheTimeInViewAndNowOnlyWhileTheLiveWindowShowsNow() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()
        // The live window from 18:30, now 420 points in (19:40), a view 720 points wide.
        h.store.setView(300.0, 720.0)
        assertEquals("Now", h.state.dayLabel)
        assertNull(h.state.timeLabel)

        // Scrolled two and a half hours on: now is out of view.
        h.store.setView(900.0, 720.0)
        assertEquals("Today", h.state.dayLabel)
        assertEquals("21:00", h.state.timeLabel)
        // Part-way into a half hour: the half hour nearest the view's start, 21:10 by 21:00 and 21:27 by 21:30.
        h.store.setView(960.0, 720.0)
        assertEquals("21:00", h.state.timeLabel)
        h.store.setView(1062.0, 720.0)
        assertEquals("21:30", h.state.timeLabel)
        h.store.setView(300.0, 720.0)
        assertEquals("Now", h.state.dayLabel)
        assertNull(h.state.timeLabel)

        // A window moved to: it opens at its start, and the time follows the view; never "Now", though it holds now.
        h.store.selectTimeNav(GuideTimeNavItem.EARLIER)
        runCurrent()
        h.serverA.complete(1, "Earlier")
        runCurrent()
        assertEquals("Today", h.state.dayLabel)
        assertEquals("16:30", h.state.timeLabel)
        h.store.setView(360.0, 720.0)
        assertEquals("17:30", h.state.timeLabel)
        h.store.setView(540.0, 720.0)
        assertEquals("Today", h.state.dayLabel)
        assertEquals("18:00", h.state.timeLabel)
    }

    @Test
    fun anObsoleteCompletionCannotClearLoadingOwnedByANewerRequest() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()

        h.store.selectTimeNav(GuideTimeNavItem.LATER)
        h.store.selectTimeNav(GuideTimeNavItem.LATER)
        runCurrent()
        assertEquals(3, h.serverA.requests.size)
        h.serverA.complete(1, "Obsolete")
        runCurrent()

        // In-session reloads keep the grid: the light overlay, not the full spinner.
        assertTrue(h.state.isLoading)
        assertTrue(h.state.showsReloadOverlay)
        assertFalse(h.state.showsFullSpinner)
        assertFalse("Obsolete" in h.titles("A"))
    }

    @Test
    fun pickingADayAppliesItImmediatelyAndDismissingTheSlotMenuKeepsIt() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()

        h.press(InputKey.SELECT)
        val days = assertIs<GuideMenu.Days>(h.state.menu)
        assertEquals(1 + GUIDE_PICKER_DAYS, days.choices.size)
        assertEquals(listOf("Now", "Today", "Tomorrow"), days.choices.take(3).map { it.label })
        assertEquals(listOf(true, false, false), days.choices.take(3).map { it.selected }, "Now is the pick shown")

        h.store.pickDay(days.choices[2])
        runCurrent()
        // Tomorrow at the window's time of day: 18:30 local.
        val dayRequest = h.serverA.requests[1]
        assertEquals(Instant.fromEpochSeconds(1_794_072_600), dayRequest.from)
        assertEquals(Instant.fromEpochSeconds(1_794_072_600 + 6 * 3600), dayRequest.to)
        val slots = assertIs<GuideMenu.Slots>(h.state.menu)
        assertEquals("TOMORROW", slots.header)
        assertEquals(listOf(0, 2, 6, 12, 18, 22), slots.slots.map { it.hour })
        assertEquals(listOf("Midnight", "Overnight", "Morning", "Daytime", "Evening", "Late Night"), slots.slots.map { it.label })

        h.store.dismissMenu()
        runCurrent()
        assertEquals(2, h.serverA.requests.size)
        assertNull(h.state.menu)
        assertEquals("Tomorrow", h.state.dayLabel)
    }

    @Test
    fun pickingASlotAfterTheDayRefinesTheWindowToThatSlot() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()
        h.store.openDayMenu()
        h.store.pickDay(assertIs<GuideMenu.Days>(h.state.menu).choices[2])
        runCurrent()
        assertEquals(2, h.serverA.requests.size)

        val morning = assertIs<GuideMenu.Slots>(h.state.menu).slots.first { it.hour == 6 }
        h.store.pickSlot(morning)
        runCurrent()
        assertEquals(3, h.serverA.requests.size)
        // Tomorrow 06:00 local is 05:00 UTC.
        assertEquals(Instant.fromEpochSeconds(1_794_027_600), h.serverA.requests[2].from)
        assertEquals(Instant.fromEpochSeconds(1_794_027_600 + 6 * 3600), h.serverA.requests[2].to)
        assertNull(h.state.menu)
    }

    @Test
    fun aDaysSlotPickedWithoutTheMenuOpensTheWindowAtThatSlot() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()
        val tomorrow = h.store.dayChoices()[2]
        assertEquals("Tomorrow", tomorrow.label)
        h.store.pickSlot(tomorrow.epochDay!!, guideTimeSlots().first { it.hour == 6 })
        runCurrent()
        assertEquals(2, h.serverA.requests.size)
        // Tomorrow 06:00 local is 05:00 UTC.
        assertEquals(Instant.fromEpochSeconds(1_794_027_600), h.serverA.requests[1].from)
        assertNull(h.state.menu)
        assertTrue(h.store.dayChoices()[2].selected, "tomorrow is the window's day now")
    }

    @Test
    fun theSlotMenusBackEntryReturnsToTheDays() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()
        h.store.openDayMenu()
        h.store.pickDay(assertIs<GuideMenu.Days>(h.state.menu).choices[2])
        h.store.backToDays()
        val days = assertIs<GuideMenu.Days>(h.state.menu)
        assertTrue(days.choices[2].selected)

        h.store.pickDay(days.choices[0])
        runCurrent()
        assertEquals(Instant.fromEpochSeconds(NOW_WINDOW_START), h.serverA.requests.last().from)
        assertEquals("Now", h.state.dayLabel)
    }

    @Test
    fun daysAreCalendarDaysAcrossASummerTimeChange() = runTest {
        // Berlin, the night summer time starts: 2026-03-29 01:00 UTC moves the clock from 02:00 to 03:00.
        val berlin: (Long) -> Int = { if (it < 1_774_746_000_000L) 3600 else 7200 }
        val server = GuideServer("server-a", "station-a")
        // 2026-03-28 21:10 local: the window opens at 20:00 local (19:00 UTC).
        val h = GuideHarness(this, listOf(server), listOf(guideChannel("server-a", "station-a", "A")), utcOffset = berlin, nowMillis = 1_774_728_600_000L)
        assertEquals(Instant.fromEpochSeconds(1_774_724_400), server.requests[0].from)
        server.completeEmpty(0)
        runCurrent()

        h.store.openDayMenu()
        h.store.pickDay(assertIs<GuideMenu.Days>(h.state.menu).choices[2])
        runCurrent()
        // 20:00 the next day is 23 hours on: 18:00 UTC.
        assertEquals(Instant.fromEpochSeconds(1_774_807_200), server.requests[1].from)
        assertEquals("Tomorrow", h.state.dayLabel)
        assertEquals("20:00", h.state.timeLabel)

        h.store.pickSlot(assertIs<GuideMenu.Slots>(h.state.menu).slots.first { it.hour == 6 })
        runCurrent()
        assertEquals(Instant.fromEpochSeconds(1_774_756_800), server.requests[2].from)

        // 02:00 doesn't exist that night: the clock reads 03:00 (01:00 UTC).
        assertEquals(1_774_746_000_000L, localWallTime(20_541, 120, berlin))
    }

    @Test
    fun afterADayChangeCompletesTheGuideKeepsItsFocus() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()
        h.store.setFocused(true)

        h.press(InputKey.SELECT)
        h.store.pickDay(assertIs<GuideMenu.Days>(h.state.menu).choices[2])
        val requests = h.state.focusRequest
        h.store.dismissMenu()
        runCurrent()
        // Closing the menu hands the platform's focus back to the guide, which stays mounted while it loads.
        assertEquals(requests + 1, h.state.focusRequest)
        assertTrue(h.state.showsReloadOverlay)
        assertEquals(GuideFocus(zone = GuideZone.TIME_NAV, timeNavItem = GuideTimeNavItem.DAY), h.state.focus)

        h.serverA.complete(1, "Tomorrow Programs")
        runCurrent()
        assertEquals(listOf("Tomorrow Programs"), h.titles("A"))
        assertTrue(h.state.isFocused(GuideTimeNavItem.DAY))
    }

    @Test
    fun horizontalVirtualizationKeepsTheDpadFocusTargetLaidOut() = runTest {
        val h = GuideHarness.oneServer(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.store.setFocused(true)

        // The UI: a viewport beside the channel column, scrolled as the guide asks.
        val viewport = 1280.0 - GuideLayout.CHANNEL_COLUMN_WIDTH
        val maxScroll = GuideLayout.GRID_WIDTH - viewport
        var offset = 0.0
        var performed = 0
        fun scroll() {
            val request = h.state.scroll ?: return
            if (request.id == performed) return
            performed = request.id
            offset = when (val horizontal = request.horizontal) {
                is GuideHorizontalScroll.ToNow -> guideScrollToNowOffset(horizontal.nowOffset, viewport, maxScroll)
                is GuideHorizontalScroll.ToProgram -> guideProgramScrollOffset(horizontal.left, offset, viewport, maxScroll) ?: offset
                null -> offset
            }
        }
        scroll()
        h.press(InputKey.DOWN)
        scroll()
        repeat(13) {
            h.press(InputKey.RIGHT)
            scroll()
        }

        assertEquals("Slot 12", h.focusedCell())
        val (row, slot12) = h.cell("Slot 12")
        val (_, slot1) = h.cell("Slot 1")
        assertTrue(guideBlockVisible(slot12.left, slot12.width, offset, viewport))
        assertFalse(guideBlockVisible(slot1.left, slot1.width, offset, viewport))
        assertEquals(GuideCellTone.FOCUSED, h.state.tone(row, slot12))
    }

    @Test
    fun verticalNavigationFollowsTheDisplayedSourceGroupOrderNotTheFlatChannelOrder() = runTest {
        // Number-sorted across servers: the two sources interleave.
        val h = GuideHarness.twoServers(
            this,
            listOf(
                guideChannel("server-a", "st-a1", "A1", "1"),
                guideChannel("server-a", "st-a2", "A2", "2"),
                guideChannel("server-b", "st-b21", "B21", "2.1"),
                guideChannel("server-a", "st-a3", "A3", "3"),
                guideChannel("server-a", "st-a4", "A4", "4"),
                guideChannel("server-b", "st-b41", "B41", "4.1"),
                guideChannel("server-b", "st-b43", "B43", "4.3"),
                guideChannel("server-b", "st-b44", "B44", "4.4"),
                guideChannel("server-a", "st-a5", "A5", "5"),
                guideChannel("server-b", "st-b51", "B51", "5.1"),
            ),
        )
        h.completeInitialEmpty()
        h.press(InputKey.DOWN)
        assertEquals("A1", h.focusedCell())

        val displayOrder = listOf("A1", "A2", "A3", "A4", "A5", "B21", "B41", "B43", "B44", "B51")
        for (callSign in displayOrder.drop(1)) {
            h.press(InputKey.DOWN)
            assertEquals(callSign, h.focusedCell())
        }
        // Down on the last displayed row stays.
        h.press(InputKey.DOWN)
        assertEquals("B51", h.focusedCell())
        for (callSign in displayOrder.reversed().drop(1)) {
            h.press(InputKey.UP)
            assertEquals(callSign, h.focusedCell())
        }
    }

    @Test
    fun downReachesTheLastDisplayedRowWhenTheFlatLastChannelSitsMidGuide() = runTest {
        val h = GuideHarness.twoServers(
            this,
            listOf(
                guideChannel("server-a", "st-a1", "A1", "1"),
                guideChannel("server-b", "st-b2", "B2", "2"),
                guideChannel("server-a", "st-a10", "A10", "10"),
            ),
        )
        h.completeInitialEmpty()
        h.press(InputKey.DOWN)
        assertEquals("A1", h.focusedCell())
        h.press(InputKey.DOWN)
        assertEquals("A10", h.focusedCell())
        h.press(InputKey.DOWN)
        assertEquals("B2", h.focusedCell())
        h.press(InputKey.DOWN)
        assertEquals("B2", h.focusedCell())
        h.press(InputKey.UP)
        assertEquals("A10", h.focusedCell())
        h.press(InputKey.UP)
        assertEquals("A1", h.focusedCell())

        // Up on the first displayed row leaves the grid for the day picker.
        h.press(InputKey.UP)
        assertEquals(GuideFocus(zone = GuideZone.TIME_NAV, timeNavItem = GuideTimeNavItem.DAY, channelIndex = 0), h.state.focus)
    }

    @Test
    fun sourceHeaderRowsPrecedeEachGroupOnlyWhenThereAreSeveral() = runTest {
        val one = GuideHarness.oneServer(this)
        assertEquals(listOf("A"), one.state.rows.map { (it as GuideRow.Channel).channel.callSign })

        val two = GuideHarness.twoServers(this)
        val rows = two.state.rows
        assertEquals(listOf(GuideRow.SourceHeader::class, GuideRow.Channel::class, GuideRow.SourceHeader::class, GuideRow.Channel::class), rows.map { it::class })
        assertEquals(listOf("server-a", "server-b"), rows.filterIsInstance<GuideRow.SourceHeader>().map { it.label })
        assertEquals(144.0, two.state.rowTop(1))
        assertEquals(208.0, two.state.contentHeight)
    }

    @Test
    fun upAndDownInTheProgramColumnKeepTheFocusedTime() = runTest {
        val h = GuideHarness.twoServers(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.serverB.completeSlots(0, 12)
        runCurrent()

        h.press(InputKey.DOWN)
        assertEquals("A", h.focusedCell())
        h.press(InputKey.RIGHT)
        // The window opens an hour before the current half hour, so what airs now is the third slot.
        assertEquals("Slot 3", h.focusedCell())
        repeat(5) { h.press(InputKey.RIGHT) }
        assertEquals("Slot 8", h.focusedCell())

        h.press(InputKey.DOWN)
        assertEquals("Slot 8", h.focusedCell())
        assertEquals(1, h.state.focus.channelIndex)
        assertEquals("station-b", h.state.focus.program?.channelIdentifier)
        // B's row (below two headers and A's row) and the block come into view.
        val scroll = assertNotNull(h.state.scroll)
        assertEquals(144.0, scroll.rowTop)
        assertEquals(GuideHorizontalScroll.ToProgram(7 * 180.0), scroll.horizontal)
    }

    @Test
    fun movingIntoARowWithNoProgramsFocusesItsChannelCell() = runTest {
        val h = GuideHarness.twoServers(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.serverB.completeEmpty(0)
        runCurrent()

        h.press(InputKey.DOWN)
        h.press(InputKey.RIGHT)
        assertEquals("Slot 3", h.focusedCell())
        h.press(InputKey.DOWN)
        assertEquals("B", h.focusedCell())
        assertEquals(GuideColumn.CHANNEL, h.state.focus.column)
    }

    @Test
    fun rightFromAChannelInAWindowMovedBackLandsOnTheAiringInView() = runTest {
        val h = GuideHarness.oneServer(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.store.selectTimeNav(GuideTimeNavItem.EARLIER)
        runCurrent()
        h.serverA.completeSlots(1, 12)
        runCurrent()

        // The window from 16:30 opens at its start; now (19:40) is out of view.
        h.store.setView(0.0, 720.0)
        h.store.focusContent()
        h.press(InputKey.RIGHT)
        assertEquals("Slot 1", h.focusedCell())

        // Scrolled to 17:27: the airing from the half hour nearest it, 17:30.
        h.store.setView(342.0, 720.0)
        h.store.focusContent()
        assertEquals("17:30", h.state.timeLabel)
        h.press(InputKey.RIGHT)
        assertEquals("Slot 3", h.focusedCell())

        // Scrolled to 17:10: the airing from 17:00.
        h.store.setView(240.0, 720.0)
        h.store.focusContent()
        assertEquals("17:00", h.state.timeLabel)
        h.press(InputKey.RIGHT)
        assertEquals("Slot 2", h.focusedCell())

        // Scrolled on to show now: the airing on now.
        h.store.setView(900.0, 720.0)
        h.store.focusContent()
        h.press(InputKey.RIGHT)
        assertEquals("Slot 7", h.focusedCell())
    }

    @Test
    fun rightAndLeftWalkTheAiringsAndLeaveThroughTheChannelCell() = runTest {
        val h = GuideHarness.oneServer(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.press(InputKey.DOWN)
        h.press(InputKey.RIGHT)
        h.press(InputKey.LEFT)
        assertEquals("Slot 2", h.focusedCell())
        h.press(InputKey.LEFT)
        h.press(InputKey.LEFT)
        assertEquals("A", h.focusedCell())
        assertEquals(emptyList(), h.events)
        h.press(InputKey.LEFT)
        assertEquals(listOf<GuideEvent>(GuideEvent.Back), h.events)
    }

    @Test
    fun theTimeNavigationLeavesUpToTheTabsAndLeftToTheSideNavigation() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitialEmpty()
        h.press(InputKey.UP)
        assertEquals(listOf<GuideEvent>(GuideEvent.FocusTabs), h.events)
        h.press(InputKey.LEFT)
        assertEquals(GuideTimeNavItem.EARLIER, h.state.focus.timeNavItem)
        h.press(InputKey.LEFT)
        assertEquals(listOf(GuideEvent.FocusTabs, GuideEvent.Back), h.events)

        // ◀ moves the window two hours back.
        h.press(InputKey.SELECT)
        assertEquals(Instant.fromEpochSeconds(NOW_WINDOW_START - 2 * 3600), h.serverA.requests.last().from)
    }

    @Test
    fun backInTheGridGoesToTheDayPickerOnKeyUpAndBackThereLeavesTheGuide() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitialEmpty()
        h.press(InputKey.DOWN)
        h.down(InputKey.BACK)
        assertEquals(GuideZone.GRID, h.state.focus.zone)
        h.store.onKeyUp(InputKey.BACK)
        assertEquals(GuideZone.TIME_NAV, h.state.focus.zone)
        assertEquals(GuideTimeNavItem.DAY, h.state.focus.timeNavItem)
        assertEquals(emptyList(), h.events)
        h.press(InputKey.ESCAPE)
        assertEquals(listOf<GuideEvent>(GuideEvent.Back), h.events)
    }

    @Test
    fun selectOnAChannelTunesAndSelectOnAnAiringOpensItsDetailsOffTv() = runTest {
        val h = GuideHarness.oneServer(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.press(InputKey.DOWN)
        h.press(InputKey.SELECT)
        h.press(InputKey.RIGHT)
        h.press(InputKey.SELECT)
        val channel = h.channels[0]
        assertEquals(listOf(GuideEvent.Tune(channel), GuideEvent.ShowDetails(channel, h.cell("Slot 3").second.program)), h.events)
    }

    @Test
    fun onTvSelectOnAnAiringOnNowTunesAndOnALaterOneOpensItsDetails() = runTest {
        val h = GuideHarness.oneServer(this, isTv = true)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.press(InputKey.DOWN)
        h.press(InputKey.RIGHT)
        h.press(InputKey.SELECT)
        h.press(InputKey.RIGHT)
        h.press(InputKey.SELECT)
        h.store.longPressProgram(0, h.cell("Slot 3").second.program)
        runCurrent()
        val channel = h.channels[0]
        assertEquals(
            listOf(
                GuideEvent.Tune(channel),
                GuideEvent.ShowDetails(channel, h.cell("Slot 4").second.program),
                GuideEvent.ShowDetails(channel, h.cell("Slot 3").second.program),
            ),
            h.events,
        )
    }

    @Test
    fun theContextMenuKeyOpensTheFocusedChannelMenuOncePerPress() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitialEmpty()
        h.press(InputKey.DOWN)
        h.store.onKeyDown(InputKey.MENU)
        h.store.onKeyDown(InputKey.MENU, repeat = true)
        h.store.onKeyUp(InputKey.MENU)
        runCurrent()
        assertEquals(0, h.state.channelMenu)
        assertEquals(emptyList<GuideEvent>(), h.events)
    }

    @Test
    fun theChannelMenuFavoriteTogglesTheChannelAndClosingItGivesTheGuideFocusBack() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitialEmpty()
        h.store.openChannelMenu(0)
        val requests = h.state.focusRequest
        h.store.toggleFavorite(0)
        h.store.dismissChannelMenu()
        runCurrent()
        assertEquals(listOf<GuideEvent>(GuideEvent.ToggleFavorite(h.channels[0])), h.events)
        assertNull(h.state.channelMenu)
        assertEquals(requests + 1, h.state.focusRequest)
    }

    @Test
    fun theFKeyTogglesTheFocusedChannelFavorite() = runTest {
        val h = GuideHarness.oneServer(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.press(InputKey.DOWN)
        h.press(InputKey.F)
        h.press(InputKey.RIGHT)
        assertFalse(h.store.onKeyDown(InputKey.F))
        assertEquals(listOf<GuideEvent>(GuideEvent.ToggleFavorite(h.channels[0])), h.events)
    }

    @Test
    fun onTvASelectHoldOnAChannelCellOpensItsMenu() = runTest {
        val h = GuideHarness.oneServer(this, isTv = true)
        h.completeInitialEmpty()
        h.store.setFocused(true)
        h.press(InputKey.DOWN)
        h.down(InputKey.SELECT)
        wait(600)
        // The menu takes the focus; the held key's release goes to it.
        h.store.setFocused(false)
        runCurrent()
        assertEquals(0, h.state.channelMenu)
        assertEquals(emptyList<GuideEvent>(), h.events)

        // Back in the guide, a short press tunes.
        h.store.dismissChannelMenu()
        h.store.setFocused(true)
        h.press(InputKey.SELECT)
        assertEquals(listOf<GuideEvent>(GuideEvent.Tune(h.channels[0])), h.events)
    }

    @Test
    fun aGuideSearchJumpDuringLoadIsStashedAndWinsOverTheScrollToNow() = runTest {
        val h = GuideHarness.twoServers(this)
        h.press(InputKey.DOWN)
        h.store.focusContent()
        h.store.jumpToChannel(h.channels[1])
        val requests = h.state.focusRequest

        h.completeInitialEmpty()
        assertEquals("B", h.focusedCell())
        assertEquals(requests + 1, h.state.focusRequest)
        val scroll = assertNotNull(h.state.scroll)
        assertEquals(144.0, scroll.rowTop)
        assertNull(scroll.horizontal)
    }

    @Test
    fun aFocusRequestDuringLoadLandsOnTheFirstChannelOnceLoaded() = runTest {
        val h = GuideHarness.twoServers(this)
        h.store.focusContent()
        assertEquals(GuideZone.TIME_NAV, h.state.focus.zone)
        h.completeInitialEmpty()
        assertEquals("A", h.focusedCell())
        assertEquals(1, h.state.focusRequest)
    }

    @Test
    fun jumpToProgramShiftsTheWindowToTheAiringAndFocusesItsBlock() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitial()
        h.press(InputKey.DOWN)
        assertEquals("A", h.focusedCell())

        // Eight hours past the window's start: outside the six shown.
        val begin = NOW_WINDOW_START + 8 * 3600
        val target = LiveTvProgram(
            ratingKey = "search-target",
            title = "Search Target",
            beginsAt = begin,
            endsAt = begin + 1800,
            channelIdentifier = "station-a",
            serverId = "server-a",
        )
        h.store.jumpToProgram(h.channels.single(), target)
        runCurrent()

        assertEquals(2, h.serverA.requests.size)
        val shifted = h.serverA.requests[1]
        assertEquals(Instant.fromEpochSeconds(begin - 1800), shifted.from)
        assertEquals(Instant.fromEpochSeconds(begin - 1800 + 6 * 3600), shifted.to)

        // Slot 2 begins at the airing's start: the jump lands on it.
        h.serverA.completeSlots(1, 2)
        runCurrent()
        assertEquals("Slot 2", h.focusedCell())
        assertEquals(GuideHorizontalScroll.ToProgram(180.0), h.state.scroll?.horizontal)
    }

    @Test
    fun aReloadMovesAFocusedAiringItNoLongerHasToWhatItsRowHasOnNow() = runTest {
        val h = GuideHarness.oneServer(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.press(InputKey.DOWN)
        h.press(InputKey.RIGHT)
        repeat(2) { h.press(InputKey.RIGHT) }
        assertEquals("Slot 5", h.focusedCell())

        h.store.selectTimeNav(GuideTimeNavItem.LATER)
        h.store.selectTimeNav(GuideTimeNavItem.EARLIER)
        runCurrent()
        h.serverA.requests[2].answer.complete(h.serverA.slots(7, NOW_WINDOW_START, 12))
        runCurrent()
        assertEquals("Slot 3", h.focusedCell())
        assertEquals("server-a-7-2", h.state.focus.program?.ratingKey)
    }

    @Test
    fun aNowAnchoredWindowFollowsNowAndAPickedDayNeverJumps() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitialEmpty()
        h.store.refresh.setSelected(true)
        runCurrent()

        // The window ends 290 minutes from now: the tick that finds now at its end moves it.
        wait(289 * 60_000L)
        assertEquals(1, h.serverA.requests.size)
        assertEquals(420.0 + 289 * 6, h.state.nowOffset)
        wait(60_000L)
        assertEquals(2, h.serverA.requests.size)
        assertEquals(Instant.fromEpochSeconds(NOW_WINDOW_START + 5 * 3600), h.serverA.requests[1].from)
        h.serverA.completeEmpty(1)
        runCurrent()

        h.store.openDayMenu()
        h.store.pickDay(assertIs<GuideMenu.Days>(h.state.menu).choices[2])
        h.store.dismissMenu()
        runCurrent()
        h.serverA.completeEmpty(2)
        runCurrent()
        wait(24 * 3600_000L)
        assertEquals(3, h.serverA.requests.size)
    }

    @Test
    fun comingBackAfterHalfAnHourScrollsToNowAndSoonerDoesNot() = runTest {
        val h = GuideHarness.oneServer(this)
        h.completeInitialEmpty()
        h.store.refresh.setSelected(true)
        runCurrent()
        val scrolled = assertNotNull(h.state.scroll).id

        h.foreground.value = false
        runCurrent()
        wait(29 * 60_000L)
        h.foreground.value = true
        runCurrent()
        assertEquals(scrolled, h.state.scroll?.id)

        h.store.refresh.setShown(false)
        wait(30 * 60_000L)
        h.store.refresh.setShown(true)
        runCurrent()
        val scroll = assertNotNull(h.state.scroll)
        assertNotEquals(scrolled, scroll.id)
        // 129 minutes past the window's start.
        assertEquals(GuideHorizontalScroll.ToNow(129 * 6.0), scroll.horizontal)
        assertEquals(1, h.serverA.requests.size)
    }

    @Test
    fun favoritesAreMarkedOnTheirRows() = runTest {
        val h = GuideHarness.twoServers(this)
        h.store.setChannels(h.channels, groupLiveTvChannelsBySource(h.channels), setOf(h.channels[1].scopeKey))
        assertEquals(listOf(false, true), h.state.rows.filterIsInstance<GuideRow.Channel>().map { it.isFavorite })
    }

    @Test
    fun `after the channel list changes under the focus Select opens what is drawn focused`() = runTest {
        val h = GuideHarness.twoServers(this)
        h.serverA.completeSlots(0, 12)
        runCurrent()
        h.serverB.completeSlots(0, 12)
        runCurrent()
        h.press(InputKey.DOWN)
        h.press(InputKey.RIGHT)
        val focused = assertNotNull(h.state.focus.program)
        assertEquals("station-a", focused.channelIdentifier)

        // B moves above A, as a reorder of the favourites does.
        val reordered = h.channels.reversed()
        h.store.setChannels(reordered, groupLiveTvChannelsBySource(reordered), emptySet())
        val row = h.state.rows.filterIsInstance<GuideRow.Channel>().single { it.channelIndex == h.state.focus.channelIndex }
        assertEquals("A", row.channel.callSign)
        assertTrue(row.programs.any { it.program == h.state.focus.program })
        h.press(InputKey.SELECT)
        assertEquals(listOf<GuideEvent>(GuideEvent.ShowDetails(row.channel, focused)), h.events)

        // A leaves: the focus lands on B's row, on what B airs now.
        h.events.clear()
        val onlyB = listOf(h.channels[1])
        h.store.setChannels(onlyB, groupLiveTvChannelsBySource(onlyB), emptySet())
        val program = assertNotNull(h.state.focus.program)
        assertEquals("station-b", program.channelIdentifier)
        assertEquals("Slot 3", program.title)
        h.press(InputKey.SELECT)
        assertEquals(listOf<GuideEvent>(GuideEvent.ShowDetails(onlyB[0], program)), h.events)
    }

    @Test
    fun `the guide opens an hour before either of the two Berlin 02 45 of the night summer time ends`() {
        // Berlin, 25 Oct 2026: 01:00 UTC turns the clock back from 03:00 to 02:00, so 02:45 comes twice.
        val berlin: (Long) -> Int = { if (it < 1_792_890_000_000L) 7200 else 3600 }
        // 02:45 summer time (00:45 UTC): 01:30 summer time, 23:30 UTC.
        assertEquals(1_792_884_600L, guideNowWindowStart(1_792_889_100L, berlin))
        // 02:45 winter time (01:45 UTC): 01:30 winter time, 00:30 UTC.
        assertEquals(1_792_888_200L, guideNowWindowStart(1_792_892_700L, berlin))
    }

    @Test
    fun aBlockIsClampedToTheWindowAndNeverNarrowerThanSixPoints() = runTest {
        val h = GuideHarness.oneServer(this)
        val start = h.serverA.requests.single().from.epochSeconds
        val end = start + 6 * 3600
        fun airing(title: String, beginsAt: Long, endsAt: Long) =
            LiveTvProgram(ratingKey = title, title = title, beginsAt = beginsAt, endsAt = endsAt, channelIdentifier = "station-a", serverId = "server-a")
        h.serverA.requests.single().answer.complete(
            listOf(
                airing("Overnight", start - 3600, start + 900),
                airing("Blip", start + 7200, start + 7210),
                airing("Late", end - 600, end + 3600),
                airing("Gone", start - 7200, start - 3600),
            ),
        )
        runCurrent()
        val overnight = h.cell("Overnight").second
        assertEquals(0.0, overnight.left)
        assertEquals(15 * 6.0, overnight.width)
        val blip = h.cell("Blip").second
        assertEquals(120 * 6.0, blip.left)
        assertEquals(GuideLayout.MIN_BLOCK_WIDTH, blip.width)
        val late = h.cell("Late").second
        assertEquals(350 * 6.0, late.left)
        assertEquals(10 * 6.0, late.width)
        assertEquals(listOf("Overnight", "Blip", "Late"), h.titles("A"))
    }

    @Test
    fun anAiringsIdentitySurvivesFreshObjectsButNotAnotherSlot() {
        val channel = guideChannel("server-a", "station-7", "SEVEN")
        fun program(beginsAt: Long = 1_800_000_000) =
            LiveTvProgram(ratingKey = "program/42", title = "Evening News", beginsAt = beginsAt, endsAt = beginsAt + 3600, channelIdentifier = "station-7")
        assertEquals(guideAiringIdentity(channel, program()), guideAiringIdentity(channel.copy(), program()))
        assertNotEquals(guideAiringIdentity(channel, program()), guideAiringIdentity(channel, program(1_800_003_600)))
    }
}
