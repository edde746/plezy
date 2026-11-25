package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.withKeyDown
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.probe.FocusedProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.layoutProbe
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The TV detail under the remote: the action row's buttons and their order, where Up and Down from it go, ⋮ and a
 * season's menu being the shared media menu, an episode card and an extra playing, an extra's menu, and Back after a
 * child screen leaves.
 */
@OptIn(ExperimentalTestApi::class)
class DetailTvFocusTest {
    private val probe = FocusedProbe()

    @Test
    fun aMoviesActionRowRunsPlayVersionsTrailerDownloadWatchedThenMore() = runComposeUiTest {
        detail(DetailFixture.movie(tv = true))
        assertEquals("detail.play", probe.focused)
        assertEquals(listOf("detail.versions", "detail.trailer", "detail.download", "detail.watched", "detail.more"), walk(Key.DirectionRight, 5))
    }

    @Test
    fun aShowsActionRowShufflesAndHasNoVersions() = runComposeUiTest {
        detail(DetailFixture.show(tv = true))
        press(Key.DirectionUp)
        press(Key.DirectionUp)
        assertEquals("detail.play", probe.focused)
        assertEquals(listOf("detail.shuffle", "detail.download", "detail.watched", "detail.more"), walk(Key.DirectionRight, 4))
    }

    @Test
    fun upFromPlayReachesTheTitleBlockAndDownTheFirstSectionBelow() = runComposeUiTest {
        detail(DetailFixture.movie(tv = true))
        press(Key.DirectionUp)
        assertEquals("detail.overviewMore", probe.focused)
        press(Key.DirectionDown)
        assertEquals("detail.play", probe.focused)
        press(Key.DirectionDown)
        assertEquals("detail.extra.0", probe.focused)
    }

    @Test
    fun moreOpensTheSharedMediaMenuOfTheItemWithoutWhatTheRowShows() = runComposeUiTest {
        val fixture = DetailFixture.movie(tv = true)
        detail(fixture)
        val row = walk(Key.DirectionRight, 5)
        assertEquals("detail.more", probe.focused)
        assertTrue("detail.trailer" in row && "detail.watched" in row, "$row")
        press(Key.DirectionCenter)
        val menu = checkNotNull(fixture.menu.menu.value) { "More opened no menu" }
        assertTrue("Arrival" in menu.title, menu.title)
        // The row's trailer and watched buttons: the menu leaves them out.
        val entries = menu.entries.map { it.label }
        assertTrue(entries.isNotEmpty(), "$entries")
        assertFalse(T.tooltips.playTrailer in entries, "$entries")
        assertFalse(T.mediaMenu.markAsWatched in entries, "$entries")
    }

    @Test
    fun theSeasonChipsMenuKeyAndHeldSelectOpenTheSeasonsMenu() = runComposeUiTest {
        val fixture = DetailFixture.show(tv = true)
        detail(fixture)
        onNode(episode("1. Episode 1")).assertIsFocused()
        press(Key.DirectionUp)
        assertEquals("detail.season.0", probe.focused)

        onRoot().performKeyInput { withKeyDown(Key.ShiftLeft) { pressKey(Key.F10) } }
        waitForIdle()
        assertSeasonMenu(fixture)
        runOnIdle { fixture.menu.dismiss() }

        onRoot().performKeyInput { keyDown(Key.DirectionCenter) }
        mainClock.advanceTimeBy(1_000)
        onRoot().performKeyInput { keyUp(Key.DirectionCenter) }
        waitForIdle()
        assertSeasonMenu(fixture)
    }

    @Test
    fun anEpisodeCardPlaysTheEpisode() = runComposeUiTest {
        val fixture = DetailFixture.show(tv = true)
        detail(fixture)
        press(Key.DirectionRight)
        onNode(episode("2. Episode 2")).assertIsFocused()
        press(Key.DirectionCenter)
        assertEquals(listOf("s1e2"), fixture.plays.map { (it as PlayRequest.Item).itemId })
    }

    @Test
    fun theCastFollowsTheExtrasAndAnExtraPlaysOnSelectAndOpensItsMenuOnTheMenuKeyAndAHeldSelect() = runComposeUiTest {
        val fixture = DetailFixture.movie(tv = true)
        detail(fixture)
        assertEquals(listOf("detail.extra.0", "detail.cast.0"), walk(Key.DirectionDown, 2))
        onNodeWithText(T.discover.extras).assertExists()
        press(Key.DirectionUp)
        assertEquals("detail.extra.0", probe.focused)

        press(Key.DirectionCenter)
        assertEquals(listOf("trailer"), fixture.plays.map { (it as PlayRequest.Item).itemId })

        onRoot().performKeyInput { withKeyDown(Key.ShiftLeft) { pressKey(Key.F10) } }
        waitForIdle()
        assertExtraMenu(fixture)
        runOnIdle { fixture.menu.dismiss() }

        onRoot().performKeyInput { keyDown(Key.DirectionCenter) }
        mainClock.advanceTimeBy(1_000)
        onRoot().performKeyInput { keyUp(Key.DirectionCenter) }
        waitForIdle()
        assertExtraMenu(fixture)
        assertEquals(1, fixture.plays.size, "the held Select also played the extra")
    }

    /**
     * A child screen that leaves as Back goes down: the release that follows, in the detail's first frames, is not a
     * second Back; a Back after that leaves the detail. The system's Back acts on the release, as Android's does.
     */
    @Test
    fun theBackReleaseThatLeftAChildIsIgnoredAndTheNextBackLeaves() = runComposeUiTest {
        val fixture = DetailFixture.movie(tv = true)
        setContent {
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                TvFrame {
                    Box(
                        Modifier.fillMaxSize().onKeyEvent { event ->
                            (event.key == Key.Back && event.type == KeyEventType.KeyUp).also { if (it) fixture.navigator.back() }
                        },
                    ) {
                        val stack by fixture.navigator.backStack.collectAsState()
                        if (stack.last() == fixture.route) {
                            val state by fixture.store.state.collectAsState()
                            DetailContent(state, fixture.intents)
                        } else {
                            ChildScreen { fixture.navigator.back() }
                        }
                    }
                }
            }
        }
        waitForIdle()
        press(Key.DirectionDown)
        press(Key.DirectionDown)
        assertEquals("detail.cast.0", probe.focused)
        press(Key.DirectionCenter)
        assertTrue(fixture.navigator.current is Route.Person, "the cast card opened ${fixture.navigator.current}")
        assertEquals("child", probe.focused)

        mainClock.autoAdvance = false
        onRoot().performKeyInput { keyDown(Key.Back) }
        assertEquals(fixture.route, fixture.navigator.current)
        // The detail shows again, and focus comes back into it a frame later.
        mainClock.advanceTimeByFrame()
        mainClock.advanceTimeByFrame()
        assertTrue(probe.focused.orEmpty().startsWith("detail."), "focus is on ${probe.focused}, not in the detail")
        onRoot().performKeyInput { keyUp(Key.Back) }
        assertEquals(fixture.route, fixture.navigator.current, "the release that left the child also left the detail")

        mainClock.autoAdvance = true
        press(Key.Back)
        assertEquals(Route.Home, fixture.navigator.current)
    }

    /** Back from a related hub's View All grid gives focus back to the hub's View All card. */
    @Test
    fun backFromARelatedHubsViewAllFocusesItsViewAll() = runComposeUiTest {
        val similar = (1..3).map { DetailFixture.item("m$it", MediaKind.MOVIE, "Movie $it") }
        val hub = MediaHub("similar", "More Like This", "movie", similar, more = true, serverId = DetailFixture.SERVER)
        val fixture = DetailFixture.movie(tv = true, related = listOf(hub))
        setContent {
            val stack by fixture.navigator.backStack.collectAsState()
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                TvFrame(onView = { stack.last() == fixture.route }) {
                    // The detail leaves while the grid covers it, its saved state kept, as the navigation does.
                    val saved = rememberSaveableStateHolder()
                    if (stack.last() == fixture.route) {
                        saved.SaveableStateProvider("detail") {
                            val state by fixture.store.state.collectAsState()
                            DetailContent(state, fixture.intents)
                        }
                    }
                }
            }
        }
        waitForIdle()
        press(Key.DirectionDown)
        press(Key.DirectionDown)
        repeat(3) { press(Key.DirectionRight) }
        assertTrue(probe.focused.orEmpty().endsWith(".viewAll.card"), "focus is on ${probe.focused}, not View All")
        press(Key.DirectionCenter)
        assertTrue(fixture.navigator.current is Route.HubDetail, "View All opened ${fixture.navigator.current}")

        runOnIdle { fixture.navigator.back() }
        waitForIdle()
        assertTrue(probe.focused.orEmpty().endsWith(".viewAll.card"), "focus came back to ${probe.focused}, not View All")
    }

    /** The last section focused rests at the top under the title's line, as every section does: those above it are gone. */
    @Test
    fun theInformationFocusedRestsUnderTheTitlesLineWithNothingAboveItShowing() = runComposeUiTest {
        val similar = (1..3).map { DetailFixture.item("m$it", MediaKind.MOVIE, "Movie $it") }
        val hub = MediaHub("similar", "More Like This", "movie", similar, serverId = DetailFixture.SERVER)
        detail(DetailFixture.movie(tv = true, related = listOf(hub)))
        assertEquals("detail.info", walk(Key.DirectionDown, 4).last())
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        val studio = onNodeWithText("Paramount").getBoundsInRoot()
        assertTrue(studio.top >= TitleBand, "the information starts at ${studio.top}, under the title's line ($TitleBand)")
        assertNothingShowsUnderTheTitle(hasContentDescription("Amy Adams", substring = true), "the cast")
        assertNothingShowsUnderTheTitle(hasContentDescription("Movie 1"), "More Like This")
    }

    /** The information's words start at the cast heading's leading edge; only its focus ring reaches past them. */
    @Test
    fun theInformationsWordsLineUpWithTheCastHeading() = runComposeUiTest {
        detail(DetailFixture.movie(tv = true))
        repeat(6) { if (probe.focused != "detail.cast.0") press(Key.DirectionDown) }
        assertEquals("detail.cast.0", probe.focused)
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        val heading = onNodeWithText(T.discover.cast).getBoundsInRoot()
        press(Key.DirectionDown)
        assertEquals("detail.info", probe.focused)
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        val studio = onNodeWithText("Paramount").getBoundsInRoot()
        assertEquals(heading.left, studio.left, "the studio's left edge")
    }

    /** A related hub focused rests at the top under the title's line, its posters whole, the extras above it gone. */
    @Test
    fun aRelatedHubFocusedRestsUnderTheTitlesLineWithItsPostersWholeAndNothingAboveItShowing() = runComposeUiTest {
        val similar = (1..3).map { DetailFixture.item("m$it", MediaKind.MOVIE, "Movie $it") }
        val hub = MediaHub("similar", "More Like This", "movie", similar, serverId = DetailFixture.SERVER)
        detail(DetailFixture.movie(tv = true, related = listOf(hub)))
        press(Key.DirectionDown)
        press(Key.DirectionDown)
        val poster = onNode(hasContentDescription("Movie 1") and hasClickAction())
        poster.assertIsFocused()
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        val heading = onNodeWithText("More Like This").getBoundsInRoot()
        assertTrue(heading.top >= TitleBand, "More Like This starts at ${heading.top}, under the title's line ($TitleBand)")
        val posterTop = poster.getBoundsInRoot().top
        assertTrue(posterTop >= TitleBand, "the first poster starts at $posterTop, under the title's line ($TitleBand)")
        assertNothingShowsUnderTheTitle(hasText("Trailer"), "the extras")
    }

    /**
     * Until the page is ready its actions and sections are laid out unseen: nothing of them is shown, read out or
     * reachable by the remote. Ready, they show whole.
     */
    @Test
    fun theActionsAndSectionsStayUnseenAndOutOfReachUntilThePageIsReady() = runComposeUiTest {
        val fixture = DetailFixture.movie(tv = true)
        val ready = mutableStateOf(false)
        setContent {
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                TvFrame {
                    val state by fixture.store.state.collectAsState()
                    DetailContent(state.copy(ready = state.ready && ready.value), fixture.intents)
                }
            }
        }
        waitForIdle()
        onAllNodesWithText(T.discover.extras).assertCountEquals(0)
        onAllNodes(hasContentDescription("Trailer") and hasClickAction()).assertCountEquals(0)
        repeat(3) { press(Key.DirectionDown) }
        assertTrue(probe.focused == null || probe.focused == "detail.overviewMore", "focus reached ${probe.focused} before the page was ready")

        ready.value = true
        waitForIdle()
        onNodeWithText(T.discover.extras).assertExists()
        onNode(hasContentDescription("Trailer") and hasClickAction()).assertExists()
    }

    /** What [matcher] finds, a section above the one focused, shows no further down than the title's line. */
    private fun ComposeUiTest.assertNothingShowsUnderTheTitle(matcher: SemanticsMatcher, what: String) {
        onAllNodes(matcher).fetchSemanticsNodes().forEach { node ->
            val bottom = with(density) { node.boundsInRoot.bottom.toDp() }
            assertTrue(bottom <= TitleBand, "$what shows down to $bottom, past the title's line ($TitleBand)")
        }
    }

    private fun ComposeUiTest.assertSeasonMenu(fixture: DetailFixture) {
        val menu = checkNotNull(fixture.menu.menu.value) { "the season's menu didn't open" }
        assertTrue("Season 1" in menu.title, menu.title)
        val entries = menu.entries.map { it.label }
        assertTrue(T.mediaMenu.markAsWatched in entries, "$entries")
        assertTrue(T.mediaMenu.deleteSeasonFromServer in entries, "$entries")
    }

    private fun assertExtraMenu(fixture: DetailFixture) {
        val menu = checkNotNull(fixture.menu.menu.value) { "the extra's menu didn't open" }
        assertTrue("Trailer" in menu.title, menu.title)
        assertTrue(T.mediaMenu.markAsWatched in menu.entries.map { it.label }, "${menu.entries.map { it.label }}")
    }

    private fun ComposeUiTest.detail(fixture: DetailFixture) {
        setContent {
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                TvFrame {
                    val state by fixture.store.state.collectAsState()
                    DetailContent(state, fixture.intents)
                }
            }
        }
        waitForIdle()
    }

    /** The episode card named [title]. */
    private fun episode(title: String): SemanticsMatcher = hasContentDescription(title) and hasClickAction()

    /** The focused element's harness name after each of [times] presses of [key]. */
    private fun ComposeUiTest.walk(key: Key, times: Int): List<String?> = List(times) {
        press(key)
        probe.focused
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }
}

/** A screen over the detail: one button holding focus, which leaves as Back goes down. */
@androidx.compose.runtime.Composable
private fun ChildScreen(leave: () -> Unit) {
    val focus = remember { FocusRequester() }
    PlezyButton(
        "Actor",
        onClick = {},
        modifier = Modifier
            .focusRequester(focus)
            .layoutProbe("child")
            .onKeyEvent { event -> (event.key == Key.Back && event.type == KeyEventType.KeyDown).also { if (it) leave() } },
    )
    LaunchedEffect(Unit) { focus.requestFocus() }
}

/** The band at the top of the page that the title's name takes once the page has moved off the title block. */
private val TitleBand = 56.dp
