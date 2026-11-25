package com.edde746.plezy.ui.catalog

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalInputModeManager
import com.edde746.plezy.presentation.catalog.CatalogRelationEntry
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.presentation.catalog.CatalogDetailLink
import com.edde746.plezy.presentation.catalog.CatalogDetailFact
import com.edde746.plezy.presentation.catalog.CatalogDetailUiState
import com.edde746.plezy.presentation.catalog.CatalogLibraryCopy
import com.edde746.plezy.presentation.catalog.CatalogLibrarySection
import com.edde746.plezy.presentation.catalog.CatalogRequestAction
import com.edde746.plezy.presentation.catalog.CatalogWatchlistAction
import com.edde746.plezy.presentation.seerr.SeerrBlock
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.probe.FocusedProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/** A catalog title's detail over states built here: its action bar, and the D-pad through its sections and library copies. */
@OptIn(ExperimentalTestApi::class)
class CatalogDetailScreenTest {
    private val calls = mutableListOf<String>()
    private val dispatcher = NavigationEventDispatcher()
    private val probe = FocusedProbe()
    private var shown by mutableStateOf<CatalogDetailUiState?>(null)

    /**
     * On TV the D-pad walks down the detail page in its order: from the actions through the overview, each library copy
     * in the listed order (best quality first), the cast, then the links in the information at the foot; Up from the
     * cast reaches the last copy, and Select on a copy opens it.
     */
    @Test
    fun theDpadWalksEachLibraryCopyThenTheCastThenTheLinks() = runComposeUiTest {
        detail(
            FormFactor.TV,
            state().copy(
                links = listOf(CatalogDetailLink(LINK, "https://www.themoviedb.org/movie/329865")),
                library = copies(MOVIES, UHD),
                cast = listOf(CatalogCastMember("Amy Adams", "Louise Banks")),
            ),
        )
        onNodeWithText(T.explore.addToWatchlist).assertIsFocused()
        press(Key.DirectionDown)
        assertEquals("catalogDetail.overview", probe.focused)
        press(Key.DirectionDown)
        onNode(button(MOVIES)).assertIsFocused()
        press(Key.DirectionDown)
        onNode(button(UHD)).assertIsFocused()
        press(Key.DirectionDown)
        assertEquals("catalogDetail.cast.0", probe.focused)
        press(Key.DirectionDown)
        onNode(button(LINK)).assertIsFocused()
        press(Key.DirectionUp)
        assertEquals("catalogDetail.cast.0", probe.focused)
        press(Key.DirectionUp)
        onNode(button(UHD)).assertIsFocused()
        press(Key.DirectionCenter)
        runOnIdle { assertEquals(listOf("copy:$UHD"), calls) }
    }

    /**
     * On TV with nothing below the cast that takes a press (no links), Down from the cast still moves on, to the facts
     * at the foot, the page scrolling to them; Up comes back to the cast.
     */
    @Test
    fun downFromTheCastReachesTheFacts() = runComposeUiTest {
        detail(
            FormFactor.TV,
            state().copy(
                cast = listOf(CatalogCastMember("Amy Adams", "Louise Banks")),
                facts = listOf(CatalogDetailFact("Studios", "FilmNation")),
                crew = listOf(CatalogDetailFact("Director", "Denis Villeneuve")),
            ),
        )
        repeat(MAX_STEPS) { if (probe.focused != "catalogDetail.cast.0") press(Key.DirectionDown) }
        assertEquals("catalogDetail.cast.0", probe.focused)
        press(Key.DirectionDown)
        assertEquals("catalogDetail.facts", probe.focused)
        onNodeWithText("Denis Villeneuve").assertIsDisplayed()
        press(Key.DirectionUp)
        assertEquals("catalogDetail.cast.0", probe.focused)
    }

    /** A later lookup that adds a copy before the focused one and re-sorts the list leaves focus on the same copy. */
    @Test
    fun focusStaysOnTheSameCopyWhenTheCopiesAreMergedAgain() = runComposeUiTest {
        detail(FormFactor.TV, state().copy(library = copies(MOVIES, UHD)))
        repeat(MAX_STEPS) { if (probe.focused != "catalogDetail.copy.1") press(Key.DirectionDown) }
        onNode(button(UHD)).assertIsFocused()
        runOnIdle { shown = checkNotNull(shown).copy(library = copies(ANIME, UHD, MOVIES)) }
        waitForIdle()
        onNode(button(UHD)).assertIsFocused()
        assertEquals("catalogDetail.copy.1", probe.focused)
        runOnIdle { shown = checkNotNull(shown).copy(library = copies(ANIME, MOVIES, UHD)) }
        waitForIdle()
        onNode(button(UHD)).assertIsFocused()
        assertEquals("catalogDetail.copy.2", probe.focused)
    }

    /** On TV focus starts on the first action (Watchlist); Right walks to Request and Watch trailer, which act. */
    @Test
    fun focusStartsOnTheActionRowWhichActs() = runComposeUiTest {
        detail(FormFactor.TV, state())
        onNodeWithText(T.explore.addToWatchlist).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        onNodeWithText(T.seerr.request).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionCenter) }
        onNode(hasContentDescription(T.explore.detail.watchTrailer)).performClick()
        onNodeWithText(T.explore.addToWatchlist).performClick()
        runOnIdle { assertEquals(listOf("request", "trailer", "watchlist"), calls) }
    }

    /**
     * Request turns into what a request makes it (Requested, Processing, Available) as a status label, not a button
     * that takes no press, and keeps its width doing so, so the actions beside it stay put.
     */
    @Test
    fun requestTurnsIntoAStatusLabelOfItsWidth() = runComposeUiTest {
        detail(FormFactor.HANDHELD, state().copy(stats = emptyList()))
        val request = bounds(T.seerr.request)
        val watchlist = bounds(T.explore.addToWatchlist)
        val trailer = onNode(hasContentDescription(T.explore.detail.watchTrailer)).getBoundsInRoot()
        for (block in listOf(SeerrBlock.REQUESTED, SeerrBlock.PROCESSING, SeerrBlock.AVAILABLE)) {
            runOnIdle { shown = checkNotNull(shown).copy(request = CatalogRequestAction(329865, "Arrival", block)) }
            waitForIdle()
            onNode(button(block.label)).assertDoesNotExist()
            val now = onNode(hasText(block.label)).getBoundsInRoot()
            assertEquals(request.left, now.left, "${block.label}'s left")
            assertEquals(request.right, now.right, "${block.label}'s right")
            assertEquals(watchlist.left, bounds(T.explore.addToWatchlist).left, "Watchlist's left beside ${block.label}")
            assertEquals(trailer.left, onNode(hasContentDescription(T.explore.detail.watchTrailer)).getBoundsInRoot().left, "Watch trailer's left beside ${block.label}")
        }
    }

    /** The store's message shows at the foot and is reported shown once it has been up. */
    @Test
    fun theMessageShows() = runComposeUiTest {
        detail(FormFactor.HANDHELD, state(message = T.explore.detail.trailerUnavailable))
        onNodeWithText(T.explore.detail.trailerUnavailable).assertExists()
    }

    /** On TV the overview's words start where the title's do, its press highlight reaching past them. */
    @Test
    fun theOverviewLinesUpWithTheTitleOnTv() = runComposeUiTest {
        detail(FormFactor.TV, state())
        val title = onNodeWithText("Arrival").getBoundsInRoot()
        val words = onNodeWithText("Linguist Louise Banks leads an elite team.", useUnmergedTree = true).getBoundsInRoot()
        assertEquals(title.left, words.left, "the overview's left edge")
    }

    /**
     * On a touch screen focus coming back to the page (a sheet over it closing, as after a request) lands on nothing
     * that scrolls it: the page stays where it was, its title on screen, and the cast below the fold takes no focus.
     */
    @Test
    fun aTouchScreenPageKeepsItsPlaceWhenFocusComesBack() = runComposeUiTest {
        val cast = (1..6).map { CatalogCastMember(name = "Actor $it", secondary = "Role $it") }
        // Enough stats above the cast to put it below the window, and nothing above it that takes the focus first.
        val stats = (1..120).map { "Stat $it" }
        detail(FormFactor.HANDHELD, state().copy(watchlist = null, request = null, hasTrailer = false, overview = null, stats = stats, cast = cast), touch = true)
        val title = onNodeWithText("Arrival").getBoundsInRoot()
        // Android hands a window focus back as a move down from its top.
        runOnIdle { focus.moveFocus(FocusDirection.Down) }
        waitForIdle()
        assertEquals(null, probe.focused)
        assertEquals(title, onNodeWithText("Arrival").getBoundsInRoot())
    }

    /**
     * On TV a title already requested opens with focus on the first action that takes a press, never on its status;
     * Request turning into Requested under the focus (a request sent from the sheet) hands it on the same way.
     */
    @Test
    fun focusStartsPastADisabledRequest() = runComposeUiTest {
        detail(FormFactor.TV, state().copy(watchlist = null, request = CatalogRequestAction(329865, "Arrival", SeerrBlock.REQUESTED)))
        onNode(hasContentDescription(T.explore.detail.watchTrailer)).assertIsFocused()
        runOnIdle { shown = checkNotNull(shown).copy(request = CatalogRequestAction(329865, "Arrival")) }
        press(Key.DirectionLeft)
        onNodeWithText(T.seerr.request).assertIsFocused()
        runOnIdle { shown = checkNotNull(shown).copy(request = CatalogRequestAction(329865, "Arrival", SeerrBlock.REQUESTED)) }
        waitForIdle()
        onNode(hasContentDescription(T.explore.detail.watchTrailer)).assertIsFocused()
    }

    /**
     * The Ratings section names each score's source as people know it (Rotten Tomatoes' two panels, IMDb), never by
     * its key, and writes the score as that source does; a tracker's score for a source the title already carries
     * shows once.
     */
    @Test
    fun theRatingsNameTheirSourcesAndShowEachOnce() = runComposeUiTest {
        val critics = MediaRatingSource("rottenTomatoesCritic", 9.5)
        val audience = MediaRatingSource("rottenTomatoesAudience", 9.2)
        val imdb = MediaRatingSource("imdb", 8.6)
        detail(FormFactor.HANDHELD, state().copy(ratings = listOf(imdb), communityRatings = listOf(critics, audience, imdb)))
        onNodeWithText("rottenTomatoes", substring = true).assertDoesNotExist()
        onNodeWithContentDescription("${T.common.ratingSource.rottenTomatoesCritic} 95%").assertExists()
        onNodeWithContentDescription("${T.common.ratingSource.rottenTomatoesAudience} 92%").assertExists()
        onAllNodesWithContentDescription("${T.common.ratingSource.imdb} 8.6").assertCountEquals(1)
    }

    private fun state(message: String? = null) = CatalogDetailUiState(
        item = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Arrival", CatalogItemIds(tmdb = 329865)),
        tagline = null,
        title = "Arrival",
        metaLine = "2016 • 1h 56m",
        genres = "Drama • Science Fiction",
        watchlist = CatalogWatchlistAction(onWatchlist = false, label = T.explore.addToWatchlist),
        request = CatalogRequestAction(329865, "Arrival"),
        hasTrailer = true,
        settled = true,
        stats = listOf("7.6", T.explore.badge.available),
        overview = "Linguist Louise Banks leads an elite team.",
        background = null,
        facts = emptyList(),
        recommenders = emptyList(),
        ratings = emptyList(),
        communityRatings = emptyList(),
        schedule = emptyList(),
        crew = emptyList(),
        tags = null,
        watchOnLinks = emptyList(),
        links = emptyList(),
        library = CatalogLibrarySection.NotInLibrary,
        castTitle = T.explore.cast,
        cast = emptyList(),
        relations = emptyList(),
        related = emptyList(),
        message = message,
    )

    private lateinit var focus: FocusManager

    private fun ComposeUiTest.detail(formFactor: FormFactor, state: CatalogDetailUiState, touch: Boolean = false) {
        shown = state
        setContent {
            focus = LocalFocusManager.current
            val inputModes = LocalInputModeManager.current
            if (touch) SideEffect { inputModes.requestInputMode(InputMode.Touch) }
            val owner = remember {
                object : NavigationEventDispatcherOwner {
                    override val navigationEventDispatcher = dispatcher
                }
            }
            val size = if (formFactor == FormFactor.TV) DpSize(960.dp, 540.dp) else DpSize(411.dp, 900.dp)
            CompositionLocalProvider(
                LocalNavigationEventDispatcherOwner provides owner,
                LocalAppearance provides Appearance.of(AppearanceSettings(), formFactor, supporterUnlocked = false),
                LocalLayoutProbe provides probe,
            ) {
                PlezyTheme {
                    Box(Modifier.size(size)) {
                        AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) {
                            OverlayHostBox { CatalogDetailContent(checkNotNull(shown), intents()) }
                        }
                    }
                }
            }
        }
        waitForIdle()
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    /** The pressable element showing [text]. */
    private fun button(text: String): SemanticsMatcher = hasText(text) and hasClickAction()

    /** The bounds of the button showing [text]. */
    private fun ComposeUiTest.bounds(text: String): DpRect = onNode(button(text)).getBoundsInRoot()

    /** The title in the libraries named [titles], in that order, each on its own server. */
    private fun copies(vararg titles: String) = CatalogLibrarySection.Copies(
        titles.map { title ->
            val item = MediaItem(id = "arrival", backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = "Arrival", serverId = title)
            CatalogLibraryCopy(key = item.globalKey, item = item, backend = BackendKind.JELLYFIN, title = title, subtitle = null, libraryKind = MediaKind.MOVIE)
        },
        uncheckedNote = null,
    )

    private fun intents() = CatalogDetailIntents(
        toggleWatchlist = { calls += "watchlist" },
        request = { calls += "request" },
        playTrailer = { calls += "trailer" },
        openLink = { calls += "link:$it" },
        revealSpoilerTags = { calls += "spoilers" },
        messageShown = { calls += "messageShown" },
        openItem = { calls += "open:${it.title}" },
        openCopy = { calls += "copy:${it.title}" },
        openPerson = { calls += "person:${it.personId}" },
        back = null,
    )

    private companion object {
        const val LINK = "Open on TMDB"
        const val MOVIES = "Movies"
        const val UHD = "4K Movies"
        const val ANIME = "Anime"

        /** More presses than any walk here takes. */
        const val MAX_STEPS = 10
    }
}
