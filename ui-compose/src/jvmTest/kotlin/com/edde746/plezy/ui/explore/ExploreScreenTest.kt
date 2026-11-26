package com.edde746.plezy.ui.explore

import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotFocused
import androidx.compose.ui.test.click
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.explore.CatalogSearchBody
import com.edde746.plezy.presentation.explore.ExploreBody
import com.edde746.plezy.presentation.explore.ExploreRow
import com.edde746.plezy.presentation.explore.ExploreRowIcon
import com.edde746.plezy.presentation.explore.ExploreSourceOption
import com.edde746.plezy.presentation.explore.ExploreUiState
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.NAVIGATION
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.catalog.CatalogCardActions
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.focus.ScreenFocus
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.focus.focusGate
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Explore over states built here: the source switcher as the filter row's first chip, the inline search in place of
 * the shelves, TV's filter row (switcher, Search, Refresh) in every state without shelves, and where focus goes as
 * Explore comes on view with and without a search.
 */
@OptIn(ExperimentalTestApi::class)
class ExploreScreenTest {
    private val calls = mutableListOf<String>()
    private val dispatcher = NavigationEventDispatcher()
    private val navigation = FocusRequester()
    private var onView by mutableStateOf(true)

    /** The switcher opens every connected source, each with its logo, the active one selected; a pick selects it. */
    @Test
    fun theSwitcherListsEverySourceWithItsLogo() = runComposeUiTest {
        explore(FormFactor.HANDHELD) { uiState(body = ExploreBody.Rows(listOf(shelf()))) }
        onNodeWithContentDescription(T.explore.selectSource, substring = true).performClick()
        for (source in SOURCES) {
            onNodeWithTag("explore.sourceLogo.${source.id.id}", useUnmergedTree = true).assertExists()
        }
        onNodeWithText(CatalogSourceId.MAL.displayName).performClick()
        runOnIdle { assertEquals(listOf("select:mal"), calls) }
    }

    /** With one source connected there is nothing to switch to: on a phone no chip names it, only the field does. */
    @Test
    fun aSingleSourceShowsNoSourceChipOnAPhone() = runComposeUiTest {
        explore(FormFactor.HANDHELD) { uiState(body = ExploreBody.Rows(listOf(shelf()))).copy(sources = SOURCES.take(1)) }
        onNodeWithText(T.explore.searchHint("Trakt"), useUnmergedTree = true).assertExists()
        onNodeWithText("Trakt").assertDoesNotExist()
        onNodeWithContentDescription(T.explore.selectSource, substring = true).assertDoesNotExist()
    }

    /** On TV with one source the filter row holds Search and Refresh, no source chip. */
    @Test
    fun aSingleSourceShowsNoSourceChipOnTv() = runComposeUiTest {
        explore(FormFactor.TV) { uiState(body = ExploreBody.Rows(listOf(shelf()))).copy(sources = SOURCES.take(1)) }
        onNodeWithText(T.common.search).assertExists()
        onNodeWithText("Trakt").assertDoesNotExist()
        onNodeWithContentDescription(T.explore.selectSource, substring = true).assertDoesNotExist()
    }

    /** While the field holds text the search's results stand where the shelves were; the shelves come back after. */
    @Test
    fun searchResultsReplaceTheShelves() = runComposeUiTest {
        var state by mutableStateOf(uiState(body = ExploreBody.Rows(listOf(shelf()))))
        explore(FormFactor.HANDHELD) { state }
        onNodeWithText("Trending Movies").assertExists()
        onNodeWithContentDescription("Shelf Movie").assertExists()

        state = state.copy(searchText = "found", search = CatalogSearchBody.Results(listOf(item("Found Movie").toMediaItem())))
        onNodeWithContentDescription("Found Movie").assertExists()
        onNodeWithText("Trending Movies").assertDoesNotExist()
        onNodeWithContentDescription("Shelf Movie").assertDoesNotExist()

        state = state.copy(searchText = "", search = null)
        onNodeWithText("Trending Movies").assertExists()
    }

    /** On TV a source without shelves keeps the filter row: the switcher, Search and Refresh stay reachable. */
    @Test
    fun theTvFilterRowStaysWithoutShelves() = runComposeUiTest {
        var state by mutableStateOf(uiState(body = ExploreBody.Empty("Nothing from Trakt")))
        explore(FormFactor.TV) { state }
        for (body in listOf(ExploreBody.Empty("Nothing from Trakt"), ExploreBody.Failed("Trakt failed"), ExploreBody.Loading)) {
            state = uiState(body = body)
            onNodeWithContentDescription(T.explore.selectSource, substring = true).assertExists()
            onNodeWithText(T.common.search).assertExists()
            onNodeWithText(T.common.refresh).assertExists()
        }
        state = uiState(body = ExploreBody.Empty("Nothing from Trakt"))
        onNodeWithText("Nothing from Trakt").assertExists()
        onNodeWithText(T.common.search).performClick()
        runOnIdle { assertEquals(listOf("search:trakt"), calls) }
    }

    /**
     * With a search showing results, focus coming to Explore goes to the first result every time: not to the field
     * (focus there would raise the keyboard over the results), not to another result it had. Up from the first result
     * reaches the field.
     */
    @Test
    fun aSearchWithResultsGetsFocusOnItsFirstResultEveryTime() = runComposeUiTest {
        val results = CatalogSearchBody.Results(listOf(item("Found Movie").toMediaItem(), item("Other Movie").toMediaItem()))
        val state = uiState(body = ExploreBody.Rows(listOf(shelf()))).copy(searchText = "found", search = results)
        exploreOnView { state }
        onNodeWithContentDescription("Found Movie").assertIsFocused()
        key(Key.DirectionUp)
        onNode(hasSetTextAction()).assertIsFocused()

        leaveAndComeBack()
        onNodeWithContentDescription("Found Movie").assertIsFocused()

        key(Key.DirectionDown)
        onNodeWithContentDescription("Other Movie").assertIsFocused()
        leaveAndComeBack()
        onNodeWithContentDescription("Found Movie").assertIsFocused()
    }

    /** With a search showing no results, focus coming to Explore goes to the field. */
    @Test
    fun aSearchWithoutResultsGetsFocusOnTheField() = runComposeUiTest {
        val state = uiState(body = ExploreBody.Rows(listOf(shelf()))).copy(searchText = "nothing", search = CatalogSearchBody.Empty("Nothing found"))
        exploreOnView { state }
        onNode(hasSetTextAction()).assertIsFocused()
    }

    /**
     * Without a search focus goes to the first shelf, Up from it to the field; coming back after that it goes to the
     * shelf card it had, not to the field.
     */
    @Test
    fun withoutASearchFocusGoesToTheFirstShelfAndUpToTheField() = runComposeUiTest {
        exploreOnView { uiState(body = ExploreBody.Rows(listOf(shelf()))) }
        onNodeWithContentDescription("Shelf Movie").assertIsFocused()
        key(Key.DirectionUp)
        onNode(hasSetTextAction()).assertIsFocused()

        leaveAndComeBack()
        onNodeWithContentDescription("Shelf Movie").assertIsFocused()
    }

    /**
     * With focus outside Explore (on the navigation, which was clicked to open it), a click on the search field gives
     * the field focus, so what is typed next lands in it; it isn't sent on to the first shelf as focus coming in is.
     */
    @Test
    fun aClickOnTheFieldFromOutsideFocusesTheField() = runComposeUiTest {
        exploreOnView { uiState(body = ExploreBody.Rows(listOf(shelf()))) }
        runOnIdle { navigation.requestFocus() }
        onNodeWithText(NAVIGATION).assertIsFocused()
        onNode(hasSetTextAction()).performMouseInput { click(center) }
        waitForIdle()
        onNode(hasSetTextAction()).assertIsFocused()
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    /** Focus goes to the navigation while Explore leaves the view, then Explore comes back on view. */
    private fun ComposeUiTest.leaveAndComeBack() {
        runOnIdle { navigation.requestFocus() }
        onNodeWithText(NAVIGATION).assertIsFocused()
        onView = false
        waitForIdle()
        onView = true
        waitForIdle()
    }

    /**
     * A phone's Explore in a screen of the back stack, on view while [onView], beside the navigation's button, the keys
     * in use.
     */
    private fun ComposeUiTest.exploreOnView(state: () -> ExploreUiState) = setContent {
        val owner = remember {
            object : NavigationEventDispatcherOwner {
                override val navigationEventDispatcher = dispatcher
            }
        }
        CompositionLocalProvider(
            LocalNavigationEventDispatcherOwner provides owner,
            LocalAppearance provides Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false),
        ) {
            PlezyTheme {
                Box(Modifier.size(DpSize(411.dp, 900.dp))) {
                    AdaptiveLayout(FormFactor.HANDHELD, Modifier.arrowKeyFocus()) {
                        OverlayHostBox {
                            val screen = remember { ScreenFocus { onView } }
                            Row {
                                PlezyButton(NAVIGATION, {}, Modifier.focusRequester(navigation))
                                Box(Modifier.fillMaxSize().then(screen.modifier).focusGate { onView }) {
                                    CompositionLocalProvider(LocalScreenFocus provides screen) { ExploreContent(state(), intents(), actions()) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * On TV, focus sent into Explore from outside (the navigation opening it) while its shelves load waits for them and
     * lands on the first card, not on the filter row's first chip; sent again with the shelves there, it lands there too.
     */
    @Test
    fun onTvFocusSentInWhileLoadingLandsOnTheFirstCard() = runComposeUiTest {
        var state by mutableStateOf(uiState(body = ExploreBody.Loading))
        val screen = FocusRequester()
        explore(FormFactor.TV, Modifier.focusRequester(screen).focusGroup()) { state }
        runOnIdle { screen.requestFocus() }
        waitForIdle()
        onNodeWithText(T.common.search).assertIsNotFocused()
        state = uiState(body = ExploreBody.Rows(listOf(shelf())))
        waitForIdle()
        onNodeWithContentDescription("Shelf Movie").assertExists()
        onAllNodes(isFocused()).assertCountEquals(1)
        onNodeWithText(T.common.search).assertIsNotFocused()
        onNodeWithText(T.common.refresh).assertIsNotFocused()
    }

    private fun uiState(body: ExploreBody) = ExploreUiState(
        title = "Trakt",
        sources = SOURCES.map { ExploreSourceOption(it.id, it.name, it.selected) },
        searchHint = T.explore.searchHint("Trakt"),
        searchText = "",
        search = null,
        body = body,
    )

    private fun item(title: String) = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, title, CatalogItemIds(tmdb = title.hashCode()))

    private fun shelf() = ExploreRow(
        MediaHub("explore:trakt:trending", "Trending Movies", "movie", listOf(item("Shelf Movie").toMediaItem()), size = 1),
        ExploreRowIcon.TRENDING,
    )

    private fun ComposeUiTest.explore(formFactor: FormFactor, frame: Modifier = Modifier, state: () -> ExploreUiState) = setContent {
        val owner = remember {
            object : NavigationEventDispatcherOwner {
                override val navigationEventDispatcher = dispatcher
            }
        }
        val size = if (formFactor == FormFactor.TV) DpSize(960.dp, 540.dp) else DpSize(411.dp, 900.dp)
        CompositionLocalProvider(
            LocalNavigationEventDispatcherOwner provides owner,
            LocalAppearance provides Appearance.of(AppearanceSettings(), formFactor, supporterUnlocked = false),
        ) {
            PlezyTheme {
                Box(Modifier.size(size).then(frame)) {
                    AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) {
                        OverlayHostBox { ExploreContent(state(), intents(), actions()) }
                    }
                }
            }
        }
    }

    private fun intents() = ExploreIntents(
        selectSource = { calls += "select:${it.id}" },
        setSearchText = { calls += "text:$it" },
        submitSearch = { false },
        refresh = { calls += "refresh" },
        retry = { calls += "retry" },
        openSearch = { calls += "search:${it.id}" },
        openViewAll = { calls += "viewAll:${it.hub.id}" },
    )

    private fun actions() = CatalogCardActions(
        open = { calls += "open:${it.title}" },
        menuEntries = { emptyList() },
        runMenu = { _, _ -> null },
    )

    private companion object {
        val SOURCES = listOf(
            ExploreSourceOption(CatalogSourceId.TRAKT, "Trakt", selected = true),
            ExploreSourceOption(CatalogSourceId.MAL, "MyAnimeList", selected = false),
            ExploreSourceOption(CatalogSourceId.PLEX, "Plex", selected = false),
        )
    }
}
