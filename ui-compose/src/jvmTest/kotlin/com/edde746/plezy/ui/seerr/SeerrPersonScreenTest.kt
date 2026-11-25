package com.edde746.plezy.ui.seerr

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.seerr.SeerrCatalogPerson
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.presentation.catalog.CatalogDetailUiState
import com.edde746.plezy.presentation.catalog.CatalogLibrarySection
import com.edde746.plezy.presentation.catalog.CatalogRequestAction
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.seerr.SeerrPersonStore
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.catalog.CatalogDetailContent
import com.edde746.plezy.ui.catalog.CatalogDetailIntents
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.probe.FocusedProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Instant

/**
 * From a Seerr title's cast to the person's Seerr page and on to one of their titles: the detail's cast entry with a
 * person id opens the page, the one without takes no press, and a title card on the page opens that title.
 */
@OptIn(ExperimentalTestApi::class)
class SeerrPersonScreenTest {
    private val dispatcher = NavigationEventDispatcher()
    private val probe = FocusedProbe()

    /** The screen on top: the title's detail until a cast entry opens a person page. */
    private var screen by mutableStateOf<Route?>(null)

    /** The titles the person page's cards opened. */
    private val opened = mutableListOf<Route>()

    @Test
    fun `a Seerr cast member opens their person page and a title card there opens the title`() = runComposeUiTest {
        show(FormFactor.HANDHELD)
        onNode(hasText(GREENWOOD) and hasClickAction()).assertDoesNotExist()
        onNode(hasText(HANKS) and hasClickAction()).performScrollTo().performClick()
        waitForIdle()
        assertEquals(Route.SeerrPerson(31, HANKS), screen)
        onNodeWithText("Acting").assertExists()
        onNodeWithText(T.discover.titleCount(2)).assertExists()
        // The facts start where the biography does: one leading edge down the header.
        assertEquals(
            onNodeWithText("An actor.", useUnmergedTree = true).getBoundsInRoot().left,
            onNodeWithText("Concord, California, USA", useUnmergedTree = true).getBoundsInRoot().left,
        )
        onNode(hasContentDescription(GUMP.title) and hasClickAction()).performClick()
        runOnIdle { assertEquals(listOf<Route>(Route.CatalogDetail(GUMP)), opened) }
    }

    /** On TV the person page opens on their newest title with the whole header still in view above it. */
    @Test
    fun `on TV the remote opens the cast member and then their newest title`() = runComposeUiTest {
        show(FormFactor.TV)
        repeat(MAX_STEPS) { if (probe.focused != "catalogDetail.cast.0") press(Key.DirectionDown) }
        assertEquals("catalogDetail.cast.0", probe.focused)
        press(Key.DirectionCenter)
        assertEquals(Route.SeerrPerson(31, HANKS), screen)
        onNodeWithText("Acting").assertIsDisplayed()
        onNodeWithText("Concord, California, USA").assertIsDisplayed()
        onNodeWithText("An actor.").assertIsDisplayed()
        press(Key.DirectionCenter)
        runOnIdle { assertEquals(listOf<Route>(Route.CatalogDetail(BROTHERS)), opened) }
    }

    private fun detailState() = CatalogDetailUiState(
        item = CatalogItem(CatalogSourceId.SEERR, MediaKind.MOVIE, "The Post", CatalogItemIds(tmdb = 446354)),
        tagline = null,
        title = "The Post",
        metaLine = "2017",
        genres = null,
        watchlist = null,
        request = CatalogRequestAction(446354, "The Post"),
        hasTrailer = false,
        settled = true,
        stats = emptyList(),
        overview = "A cover-up spanning four presidents.",
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
        cast = listOf(CatalogCastMember(HANKS, "Ben Bradlee", personId = 31), CatalogCastMember(GREENWOOD, "Robert McNamara")),
        relations = emptyList(),
        related = emptyList(),
        message = null,
    )

    private fun detailIntents() = CatalogDetailIntents(
        toggleWatchlist = {},
        request = {},
        playTrailer = {},
        openLink = {},
        revealSpoilerTags = {},
        messageShown = {},
        openItem = {},
        openCopy = {},
        openPerson = { screen = it },
        back = null,
    )

    private fun ComposeUiTest.show(formFactor: FormFactor) {
        setContent {
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
                            OverlayHostBox {
                                when (val route = screen) {
                                    is Route.SeerrPerson -> PersonPage(route)
                                    else -> CatalogDetailContent(detailState(), detailIntents())
                                }
                            }
                        }
                    }
                }
            }
        }
        waitForIdle()
    }

    @Composable
    private fun PersonPage(route: Route.SeerrPerson) {
        val scope = rememberCoroutineScope()
        val store = remember(route) {
            SeerrPersonStore(
                route,
                {
                    val details = MediaPersonDetails(biography = "An actor.", birthDate = CalendarDate(1956, 7, 9), birthPlace = "Concord, California, USA")
                    SeerrCatalogPerson(HANKS, null, "Acting", details, listOf(GUMP, BROTHERS))
                },
                { CalendarDate(2026, 11, 14) },
                scope,
            )
        }
        val state by store.state.collectAsState()
        SeerrPersonContent(state, SeerrPersonIntents(back = {}, retry = store::retry, open = { card -> store.routeFor(card.id)?.let { opened += it } }))
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private companion object {
        const val HANKS = "Tom Hanks"
        const val GREENWOOD = "Bruce Greenwood"

        val GUMP = CatalogItem(CatalogSourceId.SEERR, MediaKind.MOVIE, "Forrest Gump", CatalogItemIds(tmdb = 13), releaseDate = Instant.parse("1994-07-06T00:00:00Z"))
        val BROTHERS = CatalogItem(CatalogSourceId.SEERR, MediaKind.SHOW, "Band of Brothers", CatalogItemIds(tmdb = 4613), releaseDate = Instant.parse("2001-09-09T00:00:00Z"))

        /** More presses than any walk here takes. */
        const val MAX_STEPS = 10
    }
}
