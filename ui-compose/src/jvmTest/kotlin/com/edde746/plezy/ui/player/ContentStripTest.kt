package com.edde746.plezy.ui.player

import androidx.compose.ui.geometry.Offset
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.ChapterItem
import com.edde746.plezy.presentation.player.QueueItem
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** The chapters and the queue on one page: opened by Down on TV and a swipe up on a phone, the current entry first in view. */
@OptIn(ExperimentalTestApi::class)
class ContentStripTest {
    private val commands = mutableListOf<PlayerCommand>()
    private val chapters = listOf(
        ChapterItem("Opening", "0:00", null, current = false, command = PlayerCommand.SeekToChapter(0)),
        ChapterItem("The Reactor", "12:30", null, current = true, command = PlayerCommand.SeekToChapter(1)),
    )
    private val queue = listOf(QueueItem("2", "Please Remain Calm", "S1E2", null, current = false))
    private val withStrip = testPlayerState().copy(chapters = chapters, queue = queue)

    /** On TV the row has no chapters or queue buttons while the page holds them; Down from the row opens it. */
    @Test
    fun onTvDownFromTheRowOpensTheChaptersAndQueue() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.TV, probe = probe, onCommand = { commands += it }) { withStrip }
        waitForIdle()
        assertTrue("player.chapters" !in probe.bounds && "player.queue" !in probe.bounds, "the page's buttons in the row")
        press(Key.DirectionDown)
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP)), commands) }
    }

    /** The desktop has the chapters and queue buttons instead, each opening its list. */
    @Test
    fun onTheDesktopTheChaptersAndQueueHaveButtons() = runComposeUiTest {
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { withStrip }
        onNodeWithContentDescription(T.videoControls.chaptersButton).performClick()
        onNodeWithContentDescription(T.videoControls.queue).performClick()
        runOnIdle {
            assertEquals(listOf<PlayerCommand>(PlayerCommand.OpenMenu(PlayerMenu.CHAPTERS), PlayerCommand.OpenMenu(PlayerMenu.QUEUE)), commands)
        }
    }

    /**
     * The open page on TV: focus on the current chapter, a pick seeks to it, and the Queue chip lists the queue, whose
     * pick plays it.
     */
    @Test
    fun onTvThePageListsTheChaptersAndTheQueue() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.TV, probe = probe, onCommand = { commands += it }) { withStrip.copy(menu = PlayerMenu.CONTENT_STRIP) }
        mainClock.advanceTimeBy(500)
        waitForIdle()
        runOnIdle { assertEquals("player.menu.item.1", probe.focused) }
        press(Key.Enter)
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SeekToChapter(1)), commands) }
        onNodeWithText(T.videoControls.queue).performClick()
        onNodeWithText("Please Remain Calm").performClick()
        runOnIdle { assertEquals(PlayerCommand.PlayQueueItem("2"), commands.last()) }
    }

    /** In a long queue the entry playing opens in the middle of the list, with entries before and after it in view. */
    @Test
    fun theEntryPlayingOpensInTheMiddleOfALongQueue() = runComposeUiTest {
        val probe = PlayerProbe()
        val long = List(40) { QueueItem("$it", "Episode $it", "S1E$it", null, current = it == 25) }
        player(FormFactor.TV, probe = probe) { testPlayerState().copy(queue = long, menu = PlayerMenu.CONTENT_STRIP) }
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        val sheet = probe.bounds.getValue("player.menu")
        val playing = probe.bounds.getValue("player.menu.item.25")
        assertTrue(playing.center.y in sheet.top + sheet.height * 0.3f..sheet.top + sheet.height * 0.7f, "the entry playing $playing in the middle of $sheet")
        assertTrue(probe.bounds.getValue("player.menu.item.24").bottom > sheet.top, "the entry before it in view")
    }

    /**
     * On a phone on its side (915 × 412 dp) the page docks along the right edge at full height, headed by its tabs
     * beside its close button: no title above them repeats the tab picked, and the first entry starts within 80 dp of
     * the sheet's top.
     */
    @Test
    fun onALandscapePhoneThePageDocksAndItsFirstEntryStartsNearItsTop() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.HANDHELD, probe = probe, size = DpSize(915.dp, 412.dp)) { withStrip.copy(menu = PlayerMenu.CONTENT_STRIP) }
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        val sheet = probe.bounds.getValue("player.menu")
        assertEquals(0f, sheet.top, 1f, "the sheet starts at the window's top")
        assertEquals(px(412).toFloat(), sheet.bottom, 1f, "the sheet reaches the window's bottom")
        assertEquals(px(915).toFloat(), sheet.right, 1f, "the sheet is docked along the right edge")
        val first = probe.bounds.getValue("player.menu.item.0")
        assertTrue(first.top - sheet.top <= px(80), "the first entry starts ${first.top - sheet.top} px below the sheet's top")
        val close = probe.bounds.getValue("sheet.close")
        val tab = probe.bounds.getValue("player.menu.tab.chapters")
        assertTrue(close.center.y in tab.top..tab.bottom, "the close button $close on the tabs' line $tab")
        onAllNodesWithText(T.videoControls.chapters).assertCountEquals(1)
    }

    /**
     * While the page is docked on a phone on its side, the timeline (and the centre transport with it) steps aside
     * rather than show cut by the panel; the title stays. They come back as the page closes.
     */
    @Test
    fun onALandscapePhoneTheDockedPageSetsTheTransportAsideUntilItCloses() = runComposeUiTest {
        val probe = PlayerProbe()
        var menu by mutableStateOf<PlayerMenu?>(PlayerMenu.CONTENT_STRIP)
        player(FormFactor.HANDHELD, probe = probe, size = DpSize(915.dp, 412.dp)) { withStrip.copy(menu = menu) }
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        assertTrue("player.scrub" !in probe.bounds, "the timeline under the docked page")
        assertTrue("player.title" in probe.bounds, "the title went with the transport")
        menu = null
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        assertTrue("player.scrub" in probe.bounds, "the timeline is back once the page closed")
    }

    /** On an upright phone (412 × 915 dp) the page is a bottom sheet whose tabs head it under the handle. */
    @Test
    fun onAnUprightPhoneTheTabsHeadTheBottomSheet() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.HANDHELD, probe = probe, size = DpSize(412.dp, 915.dp)) { withStrip.copy(menu = PlayerMenu.CONTENT_STRIP) }
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        val sheet = probe.bounds.getValue("player.menu")
        assertEquals(px(412).toFloat(), sheet.width, 1f, "the bottom sheet spans the upright phone")
        val first = probe.bounds.getValue("player.menu.item.0")
        assertTrue(first.top - sheet.top <= px(96), "the first entry starts ${first.top - sheet.top} px below the sheet's top")
        onAllNodesWithText(T.videoControls.chapters).assertCountEquals(1)
    }

    /**
     * On an upright phone the bottom sheet keeps one height whichever tab shows, the taller list's and no more (two short
     * lists leave most of the video in view), and shows only the picked tab's entries.
     */
    @Test
    fun onAnUprightPhoneTheSheetKeepsOneHeightAcrossItsTabs() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.HANDHELD, probe = probe, size = DpSize(412.dp, 915.dp)) { withStrip.copy(menu = PlayerMenu.CONTENT_STRIP) }
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        val chapters = probe.bounds.getValue("player.menu")
        assertTrue(chapters.height < px(915) / 2, "the sheet is ${chapters.height} px tall")
        assertFalse(placed("Please Remain Calm"), "the queue's entry under the Chapters tab")
        onNodeWithText(T.videoControls.queue).performClick()
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        assertEquals(chapters, probe.bounds.getValue("player.menu"), "the sheet on the Queue tab")
        onNodeWithText("Please Remain Calm").assertIsDisplayed()
        assertFalse(placed("The Reactor"), "a chapter under the Queue tab")
    }

    private fun ComposeUiTest.placed(text: String) = onAllNodesWithText(text).fetchSemanticsNodes().any { it.layoutInfo.isPlaced }

    /** On a phone a swipe up on the bottom controls opens the page. */
    @Test
    fun onAPhoneASwipeUpOpensTheChaptersAndQueue() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.HANDHELD, probe = probe, onCommand = { commands += it }, size = DpSize(800.dp, 380.dp)) { withStrip }
        waitForIdle()
        // Below the bar's touch area (it reaches past its height to a touch target's 48 dp): the bar takes a drag on it.
        val from = probe.bounds.getValue("player.position").bottomCenter - Offset(0f, 2f)
        onRoot().performTouchInput {
            down(from)
            moveBy(Offset(0f, -px(40).toFloat()))
            moveBy(Offset(0f, -px(80).toFloat()))
            up()
        }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP)), commands) }
    }

    /** A slow swipe (no fling) opens the page past halfway of its 150 dp reach: 60 dp up doesn't, 100 dp does. */
    @Test
    fun onAPhoneASlowSwipeOpensThePagePastHalfway() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.HANDHELD, probe = probe, onCommand = { commands += it }, size = DpSize(800.dp, 380.dp)) { withStrip }
        waitForIdle()
        val from = probe.bounds.getValue("player.position").bottomCenter - Offset(0f, 2f)
        fun slowSwipeUp(dp: Int) = onRoot().performTouchInput {
            down(from)
            // 10 dp each 100 ms: 100 dp a second, no fling.
            repeat(dp / 10) { moveBy(Offset(0f, -px(10).toFloat()), delayMillis = 100) }
            up()
        }
        slowSwipeUp(60)
        waitForIdle()
        assertEquals(emptyList(), commands)
        slowSwipeUp(100)
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP)), commands) }
    }

    private fun ComposeUiTest.px(dp: Int): Int = with(density) { dp.dp.roundToPx() }
}
