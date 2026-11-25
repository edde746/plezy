package com.edde746.plezy.ui.livetv

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsNode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotFocused
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.rightClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.livetv.FavoriteChannelPersistenceMode
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvDvrSupport
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.LiveTvSupport
import com.edde746.plezy.livetv.LiveTvWhatsOn
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.presentation.livetv.guide.GuideColumn
import com.edde746.plezy.presentation.livetv.guide.GuideEvent
import com.edde746.plezy.presentation.livetv.guide.GuideRow
import com.edde746.plezy.presentation.livetv.guide.GuideStore
import com.edde746.plezy.presentation.livetv.guide.GuideZone
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.flow.MutableStateFlow
import java.lang.reflect.Proxy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Instant

/**
 * The guide draws the channels and the airings its store loads from the servers, and the D-pad moves its focus as the
 * store decides: the drawn focus (the inverted cell) follows the store's.
 */
@OptIn(ExperimentalTestApi::class)
class GuideTabTest {
    /**
     * A fixed half hour and now a quarter hour into it, so the airings, the window and the opening scroll don't move with
     * the wall clock (a phone's narrow view reaches the next hour's airings only from a few minutes into the half hour).
     */
    private val halfHour = 1_800_000_000L
    private val now = Instant.fromEpochSeconds(halfHour + 15 * 60L)
    private val channels = listOf(
        LiveTvChannel(key = "one", title = "Plezy One", serverId = SERVER),
        LiveTvChannel(key = "two", title = "Plezy Two", serverId = SERVER),
    )
    private val programs = channels.flatMap { channel ->
        val name = channel.title!!.substringAfter(' ')
        listOf("past" to -1, "airing" to 0, "next" to 1).map { (what, slot) ->
            LiveTvProgram(
                ratingKey = "${channel.key}-$what",
                title = "$name $what",
                summary = "About $name $what",
                beginsAt = halfHour + slot * 1800L,
                endsAt = halfHour + (slot + 1) * 1800L,
                channelIdentifier = channel.key,
                serverId = SERVER,
            )
        }
    }

    /**
     * Shows the guide of [channels] airing [airings] in a [formFactor] window ([width] wide, else the test's window), the
     * store's events collected in [events].
     */
    private fun ComposeUiTest.showGuide(
        airings: List<LiveTvProgram>,
        formFactor: FormFactor,
        shown: List<LiveTvChannel> = channels,
        schedule: Deferred<Unit>? = null,
        focus: FocusRequester = FocusRequester(),
        events: MutableList<GuideEvent> = mutableListOf(),
        width: Dp? = null,
    ): GuideStore {
        lateinit var guide: GuideStore
        val dispatcher = NavigationEventDispatcher()
        setContent {
            val owner = remember { object : NavigationEventDispatcherOwner { override val navigationEventDispatcher = dispatcher } }
            val scope = rememberCoroutineScope()
            guide = remember {
                GuideStore(FakeServers(airings, schedule), scope, MutableStateFlow(true), isTv = formFactor == FormFactor.TV, use24HourClock = true, now = { now }, utcOffset = { 0 }).also {
                    it.setChannels(shown, emptyList(), emptySet())
                }
            }
            LaunchedEffect(guide) { guide.events.collect { events += it } }
            CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
                PlezyTheme {
                    AdaptiveLayout(formFactor, if (width != null) Modifier.width(width) else Modifier) {
                        OverlayHostBox(Modifier.fillMaxSize()) {
                            GuideTab(guide, logo = { null }, thumb = { null }, focusRequester = focus)
                        }
                    }
                }
            }
        }
        return guide
    }

    /** The airing block titled [title]: its description starts with its title. */
    private fun ComposeUiTest.block(title: String) = onNode(
        SemanticsMatcher("the block of $title") { node ->
            node.config.getOrNull(SemanticsProperties.ContentDescription).orEmpty().any { it == title || it.startsWith("$title, ") }
        },
    )

    @Test
    fun theGuideDrawsTheChannelsAndTheirAiringsAndTheDpadMovesItsFocus() = runComposeUiTest {
        val focus = FocusRequester()
        val guide = showGuide(programs, FormFactor.TV, focus = focus)
        waitUntil { !guide.state.value.isLoading }
        onNodeWithText("Plezy One").assertExists()
        onNodeWithText("Plezy Two").assertExists()
        for (title in listOf("One past", "One airing", "One next", "Two past", "Two airing", "Two next")) block(title).assertExists()

        runOnIdle {
            focus.requestFocus()
            guide.focusContent()
        }
        waitForIdle()
        onNode(hasContentDescription("Plezy One")).assertIsSelected()

        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        waitForIdle()
        runOnIdle {
            val state = guide.state.value.focus
            assertEquals(GuideZone.GRID, state.zone)
            assertEquals(GuideColumn.PROGRAM, state.column)
            assertEquals("One airing", state.program?.title, "Right from a channel lands on the airing on now")
        }
        onNode(hasContentDescription("Plezy One")).assertIsNotSelected()
        block("One airing").assertIsSelected()

        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        waitForIdle()
        runOnIdle {
            assertEquals(1, guide.state.value.focus.channelIndex)
            assertEquals("Two airing", guide.state.value.focus.program?.title, "Down keeps the focused time")
        }
        block("One airing").assertIsNotSelected()
        block("Two airing").assertIsSelected()
    }

    @Test
    fun onTvTheDetailsShowTheAiringTheDpadFocuses() = runComposeUiTest {
        val focus = FocusRequester()
        val guide = showGuide(programs, FormFactor.TV, focus = focus)
        waitUntil { !guide.state.value.isLoading }
        // Before the D-pad enters the grid (its focus on the time choices): the first channel's airing on now, no blank band.
        onNodeWithText("About One airing").assertExists()

        runOnIdle {
            focus.requestFocus()
            guide.focusContent()
        }
        waitForIdle()
        // On a channel: its airing on now.
        onNodeWithText("About One airing").assertExists()

        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        waitForIdle()
        onNodeWithText("About One next").assertExists()
        onNodeWithText("About One airing").assertDoesNotExist()

        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        waitForIdle()
        onNodeWithText("About Two next").assertExists()
        onNodeWithText("About One next").assertDoesNotExist()
    }

    /**
     * On TV the details and the day pill follow what is in view: scrolled past now the pill names the time in view, not
     * "Now"; two hours back, with the focus on the time choices and then on the channel, the details show the channel's
     * airing in view, not the one on air off screen.
     */
    @Test
    fun onTvTheDetailsAndTheDayPillFollowWhatIsInView() = runComposeUiTest {
        val focus = FocusRequester()
        val channel = channels.first()
        val slots = (-6..12).map { slot ->
            LiveTvProgram(
                ratingKey = "slot$slot",
                title = "Slot $slot",
                summary = "About slot $slot",
                beginsAt = halfHour + slot * 1800L,
                endsAt = halfHour + (slot + 1) * 1800L,
                channelIdentifier = channel.key,
                serverId = SERVER,
            )
        }
        val guide = showGuide(slots, FormFactor.TV, shown = listOf(channel), focus = focus, width = 960.dp)
        waitUntil { !guide.state.value.isLoading }
        waitForIdle()
        onNodeWithText("Now").assertExists()
        onNodeWithText("About slot 0").assertExists()

        runOnIdle {
            focus.requestFocus()
            guide.focusContent()
        }
        waitForIdle()
        repeat(6) {
            onRoot().performKeyInput { pressKey(Key.DirectionRight) }
            waitForIdle()
        }
        onNodeWithText("About slot 5").assertExists()
        onNodeWithText("Now").assertDoesNotExist()
        onNodeWithText("Today").assertExists()

        // Up to the day pill, Left to two hours back, Select: the window opens at its start, the airing on now off screen.
        for (key in listOf(Key.DirectionUp, Key.DirectionLeft, Key.DirectionCenter)) {
            onRoot().performKeyInput { pressKey(key) }
            waitForIdle()
        }
        waitUntil { !guide.state.value.isLoading }
        waitForIdle()
        runOnIdle { assertEquals(GuideZone.TIME_NAV, guide.state.value.focus.zone) }
        onNodeWithText("About slot -6").assertExists()

        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        waitForIdle()
        runOnIdle { assertEquals(GuideColumn.CHANNEL, guide.state.value.focus.column) }
        onNodeWithText("About slot -6").assertExists()
        onNodeWithText("About slot 0").assertDoesNotExist()
    }

    @Test
    fun withAPointerATapOnAnAiringAsksForItsDetailsAndATapOnAChannelTunesIt() = runComposeUiTest {
        val events = mutableListOf<GuideEvent>()
        val guide = showGuide(programs, FormFactor.DESKTOP, events = events)
        waitUntil { !guide.state.value.isLoading }
        waitForIdle()

        block("Two next").performClick()
        waitUntil { events.isNotEmpty() }
        val details = events.single() as GuideEvent.ShowDetails
        assertEquals("Plezy Two", details.channel.title)
        assertEquals("Two next", details.program.title)

        onNode(hasContentDescription("Plezy One")).performClick()
        waitUntil { events.size == 2 }
        assertEquals("Plezy One", (events[1] as GuideEvent.Tune).channel.title)
    }

    @Test
    fun withAPointerARightClickOnAChannelOpensItsMenuWhoseFavoriteTurnsItOver() = runComposeUiTest {
        val events = mutableListOf<GuideEvent>()
        val guide = showGuide(programs, FormFactor.DESKTOP, events = events)
        waitUntil { !guide.state.value.isLoading }
        waitForIdle()

        onNode(hasContentDescription("Plezy One")).performMouseInput { rightClick() }
        onNode(hasClickAction() and hasText("Favorite")).assertExists()
        runOnIdle { assertEquals(emptyList(), events) }

        onNode(hasClickAction() and hasText("Favorite")).performClick()
        waitUntil { events.isNotEmpty() }
        assertEquals("Plezy One", (events.single() as GuideEvent.ToggleFavorite).channel.title)
        onNodeWithText("Favorite").assertDoesNotExist()
    }

    @Test
    fun onAPhoneALongPressOnAChannelOpensItsMenuWhoseDetailsShowWhatAirsNow() = runComposeUiTest {
        val events = mutableListOf<GuideEvent>()
        val guide = showGuide(programs, FormFactor.HANDHELD, events = events)
        waitUntil { !guide.state.value.isLoading }
        waitForIdle()

        onNode(hasContentDescription("Plezy One")).performTouchInput { longClick() }
        onNode(hasClickAction() and hasText("Watch Channel")).assertExists()
        onNode(hasClickAction() and hasText("Favorite")).assertExists()
        runOnIdle { assertEquals(emptyList(), events) }

        onNode(hasClickAction() and hasText("View details")).performClick()
        waitUntil { events.isNotEmpty() }
        val details = events.single() as GuideEvent.ShowDetails
        assertEquals("Plezy One", details.channel.title)
        assertEquals("One airing", details.program.title)
        waitUntil { guide.state.value.channelMenu == null }
    }

    /**
     * On TV, View details picked in a channel's menu (its side panel) opens the airing's details from the channel: as
     * they close, focus goes back to the guide on that channel, not to the screen's first control (its header's Back).
     */
    @Test
    fun onTvTheDetailsPickedInAChannelsMenuGiveFocusBackToTheChannelAsTheyClose() = runComposeUiTest {
        val focus = FocusRequester()
        lateinit var guide: GuideStore
        setContent {
            val scope = rememberCoroutineScope()
            guide = remember {
                GuideStore(FakeServers(programs), scope, MutableStateFlow(true), isTv = true, use24HourClock = true, now = { now }, utcOffset = { 0 }).also {
                    it.setChannels(channels, emptyList(), emptySet())
                }
            }
            var details by remember { mutableStateOf<GuideEvent.ShowDetails?>(null) }
            LaunchedEffect(guide) { guide.events.collect { if (it is GuideEvent.ShowDetails) details = it } }
            TvFrame {
                // The Live TV screen: its header's button out of it over the guide.
                Column {
                    PlezyButton(LEAVE, {})
                    GuideTab(guide, logo = { null }, thumb = { null }, focusRequester = focus)
                }
                details?.let { shown -> PlezySheet(onDismiss = { details = null }, title = shown.program.title) { PlezyButton(PLAY, {}) } }
            }
        }
        waitUntil { !guide.state.value.isLoading }
        runOnIdle {
            focus.requestFocus()
            guide.focusContent()
        }
        waitForIdle()
        runOnIdle { guide.openChannelMenu(0) }
        waitForIdle()
        onNodeWithText("Watch Channel").assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        waitForIdle()
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        waitForIdle()
        onNodeWithText("View details").assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionCenter) }
        waitForIdle()
        onNodeWithText(PLAY).assertIsFocused()

        onRoot().performKeyInput { pressKey(Key.Back) }
        waitForIdle()
        onNodeWithText(PLAY).assertDoesNotExist()
        onNodeWithText(LEAVE).assertIsNotFocused()
        runOnIdle {
            assertTrue(guide.state.value.hasFocus, "the guide has the focus back")
            assertEquals(0, guide.state.value.focus.channelIndex)
            assertEquals(GuideColumn.CHANNEL, guide.state.value.focus.column)
        }
        onNode(hasContentDescription("Plezy One")).assertIsSelected()
    }

    @Test
    fun aFocusRequestMadeWhileTheFirstWindowLoadsTakesThePlatformFocusOnceTheGridShows() = runComposeUiTest {
        val schedule = CompletableDeferred<Unit>()
        val guide = showGuide(programs, FormFactor.DESKTOP, schedule = schedule)
        waitUntil { guide.state.value.showsFullSpinner }
        // As the Live TV screen asks once its channels are in: the guide's first window is still loading.
        runOnIdle { guide.focusContent() }
        schedule.complete(Unit)
        waitUntil { !guide.state.value.isLoading }
        waitForIdle()
        onNode(hasContentDescription("Plezy One")).assertIsSelected()

        // The arrows reach the guide without a click: it holds the platform's focus.
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        waitForIdle()
        runOnIdle { assertEquals("One airing", guide.state.value.focus.program?.title) }
        block("One airing").assertIsSelected()
    }

    @Test
    fun aRowComposesOnlyTheBlocksNearTheViewportAndKeepsTheDpadTargetComposed() = runComposeUiTest {
        val focus = FocusRequester()
        val channel = channels.first()
        val many = (-4..40).map { slot ->
            LiveTvProgram(
                ratingKey = "slot$slot",
                title = "Slot $slot",
                beginsAt = halfHour + slot * 1800L,
                endsAt = halfHour + (slot + 1) * 1800L,
                channelIdentifier = channel.key,
                serverId = SERVER,
            )
        }
        val guide = showGuide(many, FormFactor.TV, shown = listOf(channel), focus = focus)
        waitUntil { !guide.state.value.isLoading }
        waitForIdle()
        // The window runs from an hour before now for six hours: slots −2 to 9, the last ones past the viewport's right.
        block("Slot 0").assertExists()
        block("Slot 9").assertDoesNotExist()

        runOnIdle {
            focus.requestFocus()
            guide.focusContent()
        }
        waitForIdle()
        // The first Right goes from the channel to the airing block, each one after to the next block.
        repeat(9) {
            onRoot().performKeyInput { pressKey(Key.DirectionRight) }
            waitForIdle()
        }
        val focused = runOnIdle { guide.state.value.focus.program?.title }
        assertEquals("Slot 8", focused, "Right walks one block per press from the airing one")
        block("Slot 8").assertIsSelected()
        block("Slot 0").assertDoesNotExist()
    }

    @Test
    fun onAPhoneAHalfHourAiringShowsItsTitleAndTimesWholeAndAShortOneItsStartAlone() = runComposeUiTest {
        val channel = channels.first()
        // On a phone the guide opens at the start of now's half hour: the airings after it are in view, unscrolled.
        fun airing(key: String, title: String, from: Long, minutes: Int) = LiveTvProgram(
            ratingKey = key, title = title, beginsAt = from, endsAt = from + minutes * 60L, channelIdentifier = channel.key, serverId = SERVER,
        )
        val airings = listOf(
            airing("news", "Morning News", halfHour + 1800, 30),
            airing("short", "Short", halfHour + 3600 + 120, 12),
        )
        val guide = showGuide(airings, FormFactor.HANDHELD, shown = listOf(channel), width = 400.dp)
        waitUntil { !guide.state.value.isLoading }
        waitForIdle()
        val cells = (guide.state.value.rows.single() as GuideRow.Channel).programs
        val news = cells.single { it.title == "Morning News" }
        val short = cells.single { it.title == "Short" }

        for (text in listOf(news.title, news.timeText!!)) {
            assertFalse(placed(text).single().isCut(), "\"$text\" shows whole in a half hour on a phone")
        }
        assertEquals(1, placed(short.startText!!).size, "a short airing shows its start")
        assertEquals(emptyList(), placed(short.timeText!!), "a short airing's room holds no cut times")
    }

    /** The text nodes laid out on screen reading [text]. */
    private fun ComposeUiTest.placed(text: String): List<SemanticsNode> =
        onAllNodesWithText(text, useUnmergedTree = true).fetchSemanticsNodes().filter { it.layoutInfo.isPlaced }

    /** Whether this text node's text is cut for want of room: it is wider whole than it is laid out. */
    private fun SemanticsNode.isCut(): Boolean {
        val layouts = mutableListOf<TextLayoutResult>()
        config[SemanticsActions.GetTextLayoutResult].action?.invoke(layouts)
        val layout = layouts.single()
        return layout.multiParagraph.intrinsics.maxIntrinsicWidth > layout.size.width + 0.5f
    }

    /** [schedule] holds the schedule's answer until it completes. */
    private class FakeServers(programs: List<LiveTvProgram>, schedule: Deferred<Unit>? = null) : LiveTvServers {
        private val client = fakeClient(programs, schedule)
        override val entries = listOf(LiveTvServerEntry(ServerId(SERVER), "dvr"))
        override fun client(serverId: ServerId): MediaBackend? = client.takeIf { serverId.value == SERVER }
    }

    private companion object {
        const val SERVER = "server-1"
        const val LEAVE = "Leave Live TV"
        const val PLAY = "Play the airing"

        /** A server that has Live TV and no DVR, answering the schedule with [programs] once [schedule] completes. */
        fun fakeClient(programs: List<LiveTvProgram>, schedule: Deferred<Unit>?): MediaBackend {
            val liveTv = object : LiveTvSupport {
                override val dvr: LiveTvDvrSupport? = null
                override val whatsOn: LiveTvWhatsOn? = null
                override suspend fun isAvailable() = true
                override suspend fun fetchChannels(lineup: String?): List<LiveTvChannel> = emptyList()
                override suspend fun fetchSchedule(from: Instant?, to: Instant?): List<LiveTvProgram> {
                    schedule?.await()
                    return programs
                }
                override suspend fun startPlayback(channelKey: String, dvrKey: String?, quality: TranscodeQualityPreset): LiveTvPlaybackSession? = null
                override suspend fun buildFavoriteChannelSource(lineup: String?) = "server://$SERVER/default"
                override val favoriteStoreKey = "test"
                override val favoritePersistenceMode = FavoriteChannelPersistenceMode.entries.first()
                override suspend fun fetchFavoriteChannels(migrate: Boolean, checkCurrent: (() -> Unit)?): List<FavoriteChannel> = emptyList()
                override suspend fun setFavoriteChannels(channels: List<FavoriteChannel>, checkCurrent: (() -> Unit)?) = Unit
            }
            return Proxy.newProxyInstance(MediaBackend::class.java.classLoader, arrayOf(MediaBackend::class.java)) { _, method, _ ->
                when {
                    method.name.startsWith("getServerId") -> SERVER
                    method.name == "getLiveTv" -> liveTv
                    method.name == "getCapabilities" -> ServerCapabilities(liveTv = true)
                    method.name == "toString" -> "FakeServer"
                    method.name == "hashCode" -> 0
                    else -> error("Not faked: ${method.name}")
                }
            } as MediaBackend
        }
    }
}
