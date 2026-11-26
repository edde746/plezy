package com.edde746.plezy.ui.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotFocused
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.BackdropRotation
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.home.HomeUiState
import com.edde746.plezy.presentation.home.LibraryShortcutUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.ui.BLUE_ART
import com.edde746.plezy.ui.RED_ART
import com.edde746.plezy.ui.NAVIGATION
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.app.LaunchFocusTest.TestPlatform
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.colourAt
import com.edde746.plezy.ui.colourImages
import com.edde746.plezy.ui.card
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.theme.PlezyTheme
import com.edde746.plezy.ui.movieCard
import coil3.SingletonImageLoader
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * TV Home under the remote: focus goes to the first shelf's first card once content is there (also from a shortcut the
 * window gave focus to as it opened), follows Continue
 * Watching that lands first, stays on the navigation a key took it to, waits while a root route covers Home, moves
 * between the shortcuts and the first hub, reaches View All as the row's last card, comes back to the card whose menu
 * closes after an action, follows its card as Continue Watching refreshes under it, and the backdrop follows the card
 * focus rests on, in its latest copy, turning through its backgrounds, giving way to the first shelf's first card once
 * that item is gone.
 */
@OptIn(ExperimentalTestApi::class)
class HomeFocusTest {
    private var load by mutableStateOf(LoadState.CONTENT)
    private var continueWatching by mutableStateOf<HubUi?>(null)
    private var recent by mutableStateOf(hub("recent", "Recently Added", "Alpha", "Bravo", "Charlie"))
    private var menuFor by mutableStateOf<String?>(null)
    private var onView by mutableStateOf(true)
    private val viewAll = mutableListOf<String>()
    private val opened = mutableListOf<String>()

    /** The backdrop's images make Coil's singleton loader; a later test's app root sets its own. */
    @AfterTest
    fun resetImages() {
        SingletonImageLoader.reset()
    }

    /** Focus lands on the first card once Home has content, not on the shortcuts above it. */
    @Test
    fun focusLandsOnTheFirstCardOnceContentArrives() = runComposeUiTest {
        load = LoadState.LOADING
        home()
        load = LoadState.CONTENT
        onNode(card("Alpha")).assertIsFocused()
    }

    /**
     * Focus the platform gave a shortcut as the window opened, before content (a launch with Home's data kept), goes to
     * the first card once content arrives; a shortcut a key moved to keeps it as Home loads again.
     */
    @Test
    fun focusTheWindowGaveAShortcutGoesToTheFirstCardOnceContentArrives() = runComposeUiTest {
        load = LoadState.LOADING
        home()
        onNodeWithText(LIVE_TV).requestFocus()
        onNodeWithText(LIVE_TV).assertIsFocused()
        load = LoadState.CONTENT
        onNode(card("Alpha")).assertIsFocused()
        key(Key.DirectionUp)
        onNodeWithText(LIVE_TV).assertIsFocused()
        load = LoadState.LOADING
        waitForIdle()
        load = LoadState.CONTENT
        waitForIdle()
        onNodeWithText(LIVE_TV).assertIsFocused()
    }

    /** Continue Watching arriving after the hubs takes the first place, and the focus Home placed follows it. */
    @Test
    fun continueWatchingArrivingAfterTheHubsTakesTheFocusHomePlaced() = runComposeUiTest {
        home()
        onNode(card("Alpha")).assertIsFocused()
        continueWatching = hub(CONTINUE_WATCHING, "Continue Watching", "Resume")
        onNode(card("Resume")).assertIsFocused()
    }

    /** Focus a key took to the navigation stays there while Home loads again. */
    @Test
    fun focusAKeyTookToTheNavigationStaysThereWhileHomeReloads() = runComposeUiTest {
        home()
        onNode(card("Alpha")).assertIsFocused()
        key(Key.DirectionLeft)
        onNodeWithText(NAVIGATION).assertIsFocused()
        load = LoadState.LOADING
        waitForIdle()
        load = LoadState.CONTENT
        waitForIdle()
        onNodeWithText(NAVIGATION).assertIsFocused()
    }

    /**
     * Content arriving while a root route (the profile picker) covers Home takes no focus; the claim lands on the first
     * card once Home is on view again (a profile switch's new Home).
     */
    @Test
    fun contentArrivingUnderARootRouteTakesFocusOnceHomeIsOnView() = runComposeUiTest {
        load = LoadState.LOADING
        onView = false
        home()
        load = LoadState.CONTENT
        waitForIdle()
        onNode(card("Alpha")).assertIsNotFocused()
        onView = true
        onNode(card("Alpha")).assertIsFocused()
    }

    /** Up from the first hub goes to the shortcuts' first chip; Down from any chip goes back to the hub's first card. */
    @Test
    fun upFromTheFirstHubReachesTheShortcutsAndDownComesBack() = runComposeUiTest {
        home()
        onNode(card("Alpha")).assertIsFocused()
        key(Key.DirectionRight)
        key(Key.DirectionUp)
        onNodeWithText(LIVE_TV).assertIsFocused()
        key(Key.DirectionRight)
        onNodeWithText("Movies · Server A").assertIsFocused()
        key(Key.DirectionDown)
        onNode(card("Alpha")).assertIsFocused()
    }

    /**
     * The libraries follow Live TV in the state's order, a namesake's server named after its title, then Home's other
     * shortcuts, and the user menu still ends the row; a click on a library opens it.
     */
    @Test
    fun theLibrariesFollowLiveTvAndOpenOnClick() = runComposeUiTest {
        home()
        onNode(card("Alpha")).assertIsFocused()
        key(Key.DirectionUp)
        onNodeWithText(LIVE_TV).assertIsFocused()
        key(Key.DirectionRight)
        onNodeWithText("Movies · Server A").assertIsFocused()
        key(Key.DirectionRight)
        onNodeWithText("Shows").assertIsFocused()
        key(Key.DirectionRight)
        onNodeWithText("Movies · Server B").assertIsFocused()
        key(Key.DirectionRight)
        onNodeWithText(DOWNLOADS).assertIsFocused()
        key(Key.DirectionRight)
        onNodeWithText(USER_MENU).assertIsFocused()
        onNodeWithText("Movies · Server B").performClick()
        assertEquals(listOf("b/movies"), opened)
    }

    /** A hub with more ends in View All, which the remote reaches as the row's last card and which opens the hub. */
    @Test
    fun theViewAllCardEndsAHubWithMoreAndOpensIt() = runComposeUiTest {
        recent = recent.copy(more = true)
        home()
        onNode(card("Alpha")).assertIsFocused()
        repeat(3) { key(Key.DirectionRight) }
        onNodeWithText(VIEW_ALL).assertIsFocused()
        key(Key.Enter)
        assertEquals(listOf("recent"), viewAll)
    }

    /**
     * A card's menu closing after its action (Mark as Watched, the card drawn again as watched) gives focus back to the
     * card at once, while the menu still slides away.
     */
    @Test
    fun aCardsMenuClosingAfterItsActionGivesFocusBackToTheCard() = runComposeUiTest {
        home()
        onNode(card("Alpha")).assertIsFocused()
        key(Key.DirectionRight)
        onNode(card("Bravo"), useUnmergedTree = true).assertIsFocused()
        menuFor = "Bravo"
        onNodeWithText(MARK_WATCHED).assertIsFocused()

        mainClock.autoAdvance = false
        menuFor = null
        recent = recent.copy(items = recent.items.map { if (it.title == "Bravo") it.copy(watched = true) else it })
        mainClock.advanceTimeByFrame()
        mainClock.advanceTimeByFrame()
        onNodeWithText(MARK_WATCHED).assertExists()
        // The screen under an open overlay is hidden from the merged tree.
        onNode(card("Bravo"), useUnmergedTree = true).assertIsFocused()

        mainClock.autoAdvance = true
        onNodeWithText(MARK_WATCHED).assertDoesNotExist()
        onNode(card("Bravo"), useUnmergedTree = true).assertIsFocused()
    }

    /**
     * Continue Watching moving the card just played to the front keeps focus on that card, in view, and Right goes on to
     * its new neighbour.
     */
    @Test
    fun focusStaysOnThePlayedCardContinueWatchingMovesToTheFront() = runComposeUiTest {
        continueWatching = hub(CONTINUE_WATCHING, "Continue Watching", "A", "B", "C", "D", "E", "F")
        home()
        onNode(card("A")).assertIsFocused()
        repeat(3) { key(Key.DirectionRight) }
        onNode(card("D")).assertIsFocused()

        continueWatching = hub(CONTINUE_WATCHING, "Continue Watching", "D", "A", "B", "C", "E", "F")
        waitForIdle()
        onNode(card("D")).assertIsFocused().assertIsDisplayed()
        key(Key.DirectionRight)
        onNode(card("A")).assertIsFocused()
    }

    /**
     * A finished episode leaving Continue Watching hands focus to the card in its place; the next episode landing a
     * refresh later takes focus from there.
     */
    @Test
    fun focusReachesTheNextEpisodeLandingARefreshAfterTheFinishedOneLeft() = runComposeUiTest {
        val movieA = movieCard("Movie A")
        val movieC = movieCard("Movie C")
        val finished = movieCard("Episode 1").copy(seriesKey = "show")
        val next = movieCard("Episode 2").copy(seriesKey = "show")
        continueWatching = continueWatchingOf(movieA, finished, movieC)
        home()
        key(Key.DirectionRight)
        onNode(card("Episode 1")).assertIsFocused()

        continueWatching = continueWatchingOf(movieA, movieC)
        waitForIdle()
        onNode(card("Movie C")).assertIsFocused()

        continueWatching = continueWatchingOf(next, movieA, movieC)
        waitForIdle()
        onNode(card("Episode 2")).assertIsFocused()
    }

    /** The first card's backdrop shows as soon as Home has it: only later focus moves wait for focus to rest. */
    @Test
    fun theFirstBackdropShowsWithoutWaitingForFocusToRest() = runComposeUiTest {
        recent = recent.copy(items = recent.items.map { it.withBackdrop(it.title) })
        mainClock.autoAdvance = false
        home()
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS / 2)
        assertBackdrop("Alpha")
    }

    /**
     * The backdrop shows the focused card's once focus rests on it; cards passed on the way (a quick run of presses)
     * never show theirs, and the last one stays until the next has rested.
     */
    @Test
    fun theBackdropFollowsTheCardFocusRestsOn() = runComposeUiTest {
        recent = recent.copy(items = recent.items.map { it.copy(backdrops = listOf(Artwork.fixed("https://art.test/${it.title}.jpg")!!)) })
        home()
        onNode(card("Alpha")).assertIsFocused()
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        assertBackdrop("Alpha")

        mainClock.autoAdvance = false
        key(Key.DirectionRight)
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS / 2)
        key(Key.DirectionRight)
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS / 2)
        assertBackdrop("Alpha")
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS)
        assertBackdrop("Charlie")
    }

    /** The backdrop turns through the focused card's backgrounds, the next every 10 s. */
    @Test
    fun theBackdropTurnsThroughTheFocusedCardsBackgrounds() = runComposeUiTest {
        colourImages(mutableListOf())
        recent = recent.copy(items = recent.items.map { it.copy(backdrops = listOf(RED_ART, BLUE_ART).map { path -> Artwork.fixed(path)!! }) })
        home()
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        waitUntil { colourAt(940, 10) == "red" }
        mainClock.advanceTimeBy(BackdropRotation.ROTATION_MILLIS)
        waitUntil { colourAt(940, 10) == "blue" }
    }

    /**
     * The backdrop follows every card focus rests on: one without backgrounds shows its own artwork, and one with
     * neither shows none, the last fading out rather than staying behind it.
     */
    @Test
    fun aCardWithoutBackgroundsShowsItsArtworkAndOneWithNoneShowsNothing() = runComposeUiTest {
        colourImages(mutableListOf())
        val (alpha, bravo, charlie) = recent.items
        recent = recent.copy(
            items = listOf(alpha.copy(backdrops = listOf(Artwork.fixed(RED_ART)!!)), bravo.copy(artwork = Artwork.fixed(BLUE_ART)), charlie),
        )
        home()
        onNode(card("Alpha")).assertIsFocused()
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        waitUntil { colourAt(940, 10) == "red" }

        key(Key.DirectionRight)
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        waitUntil { colourAt(940, 10) == "blue" }

        key(Key.DirectionRight)
        onNode(card("Charlie")).assertIsFocused()
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        onNodeWithTag("home.backdrop").assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, ""))
        waitUntil { colourAt(940, 10) == "none" }
    }

    /** A refresh that gives the focused item another backdrop shows the new one, focus still on the card. */
    @Test
    fun theBackdropShowsTheFocusedItemsLatestCopy() = runComposeUiTest {
        recent = recent.copy(items = recent.items.map { it.withBackdrop(it.title) })
        home()
        onNode(card("Alpha")).assertIsFocused()
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        assertBackdrop("Alpha")

        recent = recent.copy(items = recent.items.map { if (it.title == "Alpha") it.withBackdrop("AlphaRefreshed") else it })
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        onNode(card("Alpha")).assertIsFocused()
        assertBackdrop("AlphaRefreshed")
    }

    /**
     * The focused item gone from every shelf (focus on the shortcuts meanwhile) gives way to the first card of the first
     * shelf that has one, past an empty one.
     */
    @Test
    fun anItemGoneFromEveryShelfGivesWayToTheFirstCardOfTheFirstShelfWithOne() = runComposeUiTest {
        recent = recent.copy(items = recent.items.map { it.withBackdrop(it.title) })
        home()
        onNode(card("Alpha")).assertIsFocused()
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        assertBackdrop("Alpha")
        key(Key.DirectionUp)
        onNodeWithText(LIVE_TV).assertIsFocused()

        continueWatching = continueWatchingOf()
        recent = recent.copy(items = recent.items.filter { it.title != "Alpha" })
        mainClock.advanceTimeBy(BACKDROP_SETTLE_MS + 100)
        assertBackdrop("Bravo")
    }

    /** Live TV arriving at the row's start once the server says it has it leaves the row at its start, Live TV in view. */
    @Test
    fun aChipArrivingAtTheStartLeavesTheRowAtItsStart() = runComposeUiTest {
        var liveTv by mutableStateOf(false)
        setContent {
            PlezyTheme {
                Box(Modifier.size(400.dp, 100.dp)) {
                    val memory = rememberFocusMemory()
                    ShortcutRow(memory, shortcutKey(if (liveTv) "liveTv" else "downloads"), null) {
                        if (liveTv) item(key = "liveTv") { PlezyChip(LIVE_TV, false, {}) }
                        item(key = "downloads") { PlezyChip(DOWNLOADS, false, {}) }
                        // More chips than the row's width, so it can scroll.
                        items(6) { PlezyChip("Shortcut $it", false, {}) }
                    }
                }
            }
        }
        waitForIdle()
        liveTv = true
        waitForIdle()
        val chip = onNodeWithText(LIVE_TV).getBoundsInRoot()
        assertTrue(chip.left >= 0.dp, "Live TV starts at ${chip.left}, cut off at the row's start")
    }

    private fun ComposeUiTest.assertBackdrop(title: String) =
        onNodeWithTag("home.backdrop").assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, "https://art.test/$title.jpg"))

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    /**
     * TV Home over [continueWatching] and [recent] with two shortcuts, and the menu of the card [menuFor] while open, on
     * a platform without reduced motion.
     */
    private fun ComposeUiTest.home() = setContent {
        CompositionLocalProvider(LocalPlezyPlatform provides TestPlatform(FormFactor.TV)) {
            TvFrame(onView = { onView }) {
                val state = HomeUiState(
                    load = load,
                    continueWatching = continueWatching.takeIf { load == LoadState.CONTENT },
                    hubs = if (load == LoadState.CONTENT) listOf(recent) else emptyList(),
                    hubsLoading = false,
                    error = null,
                )
                HomeContent(
                    state,
                    HomeActions(
                        open = { _, _ -> },
                        menu = { _, card -> menuFor = card.title },
                        viewAll = { viewAll += it.id },
                        refresh = {},
                        retry = {},
                        messageShown = {},
                        openLibrary = { opened += it },
                    ),
                ) { memory, below, modifier ->
                    ShortcutRow(memory, shortcutKey("liveTv"), below, modifier) {
                        item { PlezyChip(LIVE_TV, false, {}, Modifier.rememberFocus(memory, shortcutKey("liveTv"))) }
                        libraryChips(LIBRARIES, memory) { opened += it }
                        item { PlezyChip(DOWNLOADS, false, {}, Modifier.rememberFocus(memory, shortcutKey("downloads"))) }
                        item { PlezyChip(USER_MENU, false, {}, Modifier.rememberFocus(memory, shortcutKey("userMenu"))) }
                    }
                }
                ItemMenu(
                    expanded = menuFor != null,
                    onDismiss = { menuFor = null },
                    entries = listOf(ItemMenuEntry(MARK_WATCHED) {}, ItemMenuEntry("Add to…") {}),
                    probe = "menu",
                    title = menuFor,
                    media = true,
                )
            }
        }
    }

    private fun MediaCardUi.withBackdrop(name: String) = copy(backdrops = listOf(Artwork.fixed("https://art.test/$name.jpg")!!))

    private companion object {
        const val CONTINUE_WATCHING = "continue_watching"
        const val MARK_WATCHED = "Mark as Watched"
        const val LIVE_TV = "Live TV"
        const val DOWNLOADS = "Downloads"
        const val VIEW_ALL = "View All"
        const val USER_MENU = "maestro"
        val LIBRARIES = listOf(
            LibraryShortcutUi("a/movies", "Movies", "Server A", MediaKind.MOVIE),
            LibraryShortcutUi("a/shows", "Shows", null, MediaKind.SHOW),
            LibraryShortcutUi("b/movies", "Movies", "Server B", MediaKind.MOVIE),
        )

        fun continueWatchingOf(vararg cards: MediaCardUi) =
            HubUi(id = CONTINUE_WATCHING, title = "Continue Watching", items = cards.toList(), shape = CardShape.POSTER)

        fun hub(id: String, title: String, vararg cards: String) =
            HubUi(id = id, title = title, items = cards.map { movieCard(it) }, shape = CardShape.POSTER)
    }
}
