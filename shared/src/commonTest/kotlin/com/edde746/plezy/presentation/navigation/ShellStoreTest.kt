package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.presentation.navigation.TopLevelDestination.DOWNLOADS
import com.edde746.plezy.presentation.navigation.TopLevelDestination.EXPLORE
import com.edde746.plezy.presentation.navigation.TopLevelDestination.HOME
import com.edde746.plezy.presentation.navigation.TopLevelDestination.LIBRARIES
import com.edde746.plezy.presentation.navigation.TopLevelDestination.SEARCH
import com.edde746.plezy.presentation.navigation.TopLevelDestination.SETTINGS
import com.edde746.plezy.settings.StartupSection
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class NavigationTabsTest {
    @Test
    fun onlineShowsTheDestinationsInOrderWithExploreOnlyWhileAvailableAndDownloadsWhereKept() {
        assertEquals(listOf(HOME, LIBRARIES, DOWNLOADS, EXPLORE, SEARCH, SETTINGS), NavigationTabs.visible(offline = false, hasExplore = true, downloads = true))
        assertEquals(listOf(HOME, LIBRARIES, DOWNLOADS, SEARCH, SETTINGS), NavigationTabs.visible(offline = false, hasExplore = false, downloads = true))
        assertEquals(listOf(HOME, LIBRARIES, SEARCH, SETTINGS), NavigationTabs.visible(offline = false, hasExplore = false, downloads = false))
    }

    @Test
    fun offlineKeepsDownloadsAndSettingsAndWithoutDownloadsOnlySettings() {
        assertEquals(listOf(DOWNLOADS, SETTINGS), NavigationTabs.visible(offline = true, hasExplore = true, downloads = true))
        assertEquals(listOf(SETTINGS), NavigationTabs.visible(offline = true, hasExplore = true, downloads = false))
    }

    @Test
    fun aPhonesMoreHoldsDownloadsAndSettingsOnlyWhileExploreShows() {
        assertEquals(listOf(DOWNLOADS, SETTINGS), NavigationTabs.moreHeld(NavigationTabs.visible(offline = false, hasExplore = true, downloads = true)))
        assertEquals(emptyList(), NavigationTabs.moreHeld(NavigationTabs.visible(offline = false, hasExplore = false, downloads = true)))
        assertEquals(emptyList(), NavigationTabs.moreHeld(NavigationTabs.visible(offline = false, hasExplore = true, downloads = false)))
        assertEquals(emptyList(), NavigationTabs.moreHeld(NavigationTabs.visible(offline = true, hasExplore = true, downloads = true)))
    }

    @Test
    fun startupPrefersTheVisiblePreferenceThenTheFirst() {
        val online = NavigationTabs.visible(offline = false, hasExplore = false, downloads = true)
        assertEquals(SEARCH, NavigationTabs.startup(online, preferred = SEARCH))
        assertEquals(HOME, NavigationTabs.startup(online, preferred = EXPLORE))
        assertEquals(HOME, NavigationTabs.startup(online, preferred = null))
    }

    @Test
    fun theLiveTvStartupSectionOpensLiveTvOverHome() {
        assertEquals(Startup(HOME, screen = Route.LiveTv), NavigationTabs.startupOf(StartupSection.LIVE_TV))
        assertEquals(Startup(HOME), NavigationTabs.startupOf(StartupSection.DISCOVER))
        assertEquals(Startup(LIBRARIES), NavigationTabs.startupOf(StartupSection.LIBRARIES))
    }

    @Test
    fun theStartupChoicesFollowTheNavigationOrderUnavailableOnesIncluded() {
        assertEquals(
            listOf(Startup(HOME), Startup(LIBRARIES), Startup.LIVE_TV, Startup(EXPLORE), Startup(SEARCH)),
            StartupSection.entries.map(NavigationTabs::startupOf),
        )
    }
}

class ShellStoreTest {
    private class Shell(scope: TestScope, available: ShellAvailability, preferred: Startup?, appleTv: Boolean = false) {
        val navigator = PlezyNavigator(Route.Home)
        val availability = MutableStateFlow(available)
        val store = ShellStore(
            navigator,
            availability,
            preferred,
            appleTv,
            // The Apple TV keeps no downloads.
            downloads = !appleTv,
            CoroutineScope(scope.backgroundScope.coroutineContext + UnconfinedTestDispatcher(scope.testScheduler)),
        )
        val selected: TopLevelDestination get() = store.state.value.selected
        val stack: List<Route> get() = navigator.backStack.value
    }

    private val online = ShellAvailability(offline = false, hasLiveTv = false, hasExplore = false)

    @Test
    fun aPreferredLiveTvOpensHomeAndPushesLiveTvOnceAServerHasIt() = runTest {
        val shell = Shell(this, online, preferred = Startup.LIVE_TV)
        assertEquals(listOf(Route.Home), shell.stack)
        assertFalse(shell.store.state.value.liveTv)

        shell.availability.value = online.copy(hasLiveTv = true)
        runCurrent()
        assertEquals(HOME, shell.selected)
        assertEquals(listOf(Route.Home, Route.LiveTv), shell.stack)
        assertTrue(shell.store.state.value.liveTv)
    }

    @Test
    fun aPreferredLiveTvWithAServerStartsOnIt() = runTest {
        val shell = Shell(this, online.copy(hasLiveTv = true), preferred = Startup.LIVE_TV)
        assertEquals(listOf(Route.Home, Route.LiveTv), shell.stack)
    }

    @Test
    fun pickingADestinationCancelsThePendingStartupSwitch() = runTest {
        val shell = Shell(this, online, preferred = Startup(EXPLORE))
        shell.store.select(SEARCH)

        shell.availability.value = online.copy(hasExplore = true)
        runCurrent()
        assertEquals(SEARCH, shell.selected)
    }

    @Test
    fun selectingADestinationThatDoesNotShowIsIgnored() = runTest {
        val shell = Shell(this, online, preferred = null)
        shell.store.select(EXPLORE)
        assertEquals(HOME, shell.selected)
        shell.store.select(LIBRARIES)
        assertEquals(LIBRARIES, shell.selected)
    }

    @Test
    fun aLibraryPickedShowsLibrariesAsLeftOnlyWhileItsStackStandsForThatLibrary() = runTest {
        val shell = Shell(this, online, preferred = null)
        val show = Route.MediaDetail(com.edde746.plezy.model.ServerId("server_1"), "show")
        shell.store.selectLibrary("shows", standsFor = null)
        shell.navigator.navigate(show)
        shell.store.select(HOME)

        // Movies picked over the show left open under Shows: Libraries at its root, not the show.
        shell.store.selectLibrary("movies", standsFor = "shows")
        assertEquals(LIBRARIES, shell.selected)
        assertEquals(listOf(Route.Libraries), shell.stack)

        shell.navigator.navigate(show)
        shell.store.select(HOME)
        // Shows picked: its show again, as it was left.
        shell.store.selectLibrary("shows", standsFor = "shows")
        assertEquals(listOf(Route.Libraries, show), shell.stack)
    }

    @Test
    fun openLiveTvPushesItOverHomeOnlyWhileAServerHasIt() = runTest {
        val shell = Shell(this, online, preferred = null)
        shell.store.openLiveTv()
        assertEquals(listOf(Route.Home), shell.stack)

        shell.availability.value = online.copy(hasLiveTv = true)
        runCurrent()
        shell.store.select(SEARCH)
        shell.store.openLiveTv()
        assertEquals(HOME, shell.selected)
        assertEquals(listOf(Route.Home, Route.LiveTv), shell.stack)
    }

    @Test
    fun liveTvGoingAwayTakesItOffHomesStack() = runTest {
        val shell = Shell(this, online.copy(hasLiveTv = true), preferred = Startup.LIVE_TV)

        shell.availability.value = online
        runCurrent()
        assertEquals(listOf(Route.Home), shell.stack)
    }

    @Test
    fun openAtRootShowsTheDestinationPoppedToItsRoot() = runTest {
        val shell = Shell(this, online, preferred = null)
        val movie = Route.MediaDetail(com.edde746.plezy.model.ServerId("server_1"), "movie", offline = true)
        shell.store.select(DOWNLOADS)
        shell.navigator.navigate(movie)
        shell.store.select(HOME)

        shell.store.openAtRoot(DOWNLOADS)
        assertEquals(DOWNLOADS, shell.selected)
        assertEquals(listOf(Route.Downloads), shell.stack)
    }

    @Test
    fun openAtRootIgnoresADestinationThatDoesNotShow() = runTest {
        val shell = Shell(this, online, preferred = null, appleTv = true)
        shell.store.openAtRoot(DOWNLOADS)
        assertEquals(HOME, shell.selected)
    }

    @Test
    fun aDownloadsStartOpensDownloads() = runTest {
        val shell = Shell(this, online, preferred = Startup(DOWNLOADS))
        assertEquals(DOWNLOADS, shell.selected)
        assertEquals(listOf(Route.Downloads), shell.stack)
    }

    @Test
    fun goingOfflineSwitchesToDownloadsAndComingBackRestoresTheDestination() = runTest {
        val shell = Shell(this, online, preferred = null)
        shell.store.select(SEARCH)

        shell.availability.value = online.copy(offline = true)
        runCurrent()
        assertEquals(DOWNLOADS, shell.selected)
        assertEquals(listOf(DOWNLOADS, SETTINGS), shell.store.state.value.destinations)
        assertTrue(shell.store.state.value.offline)

        shell.availability.value = online
        runCurrent()
        assertEquals(SEARCH, shell.selected)
    }

    @Test
    fun goingOfflineUnderTheRequiredPickerKeepsItShown() = runTest {
        val shell = Shell(this, online, preferred = null)
        shell.navigator.replaceStack(listOf(Route.ProfilePicker(required = true)))

        shell.availability.value = online.copy(offline = true)
        runCurrent()
        assertEquals(HOME, shell.selected)
        assertEquals(listOf<Route>(Route.ProfilePicker(required = true)), shell.stack)

        shell.availability.value = online
        runCurrent()
        assertEquals(HOME, shell.selected)
        assertEquals(listOf<Route>(Route.ProfilePicker(required = true)), shell.stack)
    }

    @Test
    fun pickingADestinationOfflineKeepsItWhenTheNetworkReturns() = runTest {
        val shell = Shell(this, online, preferred = null)
        shell.availability.value = online.copy(offline = true)
        runCurrent()
        shell.store.select(SETTINGS)

        shell.availability.value = online
        runCurrent()
        assertEquals(SETTINGS, shell.selected)
    }

    @Test
    fun aDestinationStillShownWhenGoingOfflineStaysShown() = runTest {
        val shell = Shell(this, online, preferred = null)
        shell.store.select(SETTINGS)
        shell.availability.value = online.copy(offline = true)
        runCurrent()
        assertEquals(SETTINGS, shell.selected)
    }

    @Test
    fun aDestinationThatStopsShowingGivesWayToTheFirst() = runTest {
        val shell = Shell(this, online.copy(hasExplore = true), preferred = null)
        shell.store.select(EXPLORE)

        shell.availability.value = online
        runCurrent()
        assertEquals(HOME, shell.selected)
        assertFalse(EXPLORE in shell.store.state.value.destinations)
    }

    @Test
    fun backPopsThenShowsTheFirstDestinationThenAsksBeforeExiting() = runTest {
        val shell = Shell(this, online, preferred = null)
        shell.store.select(LIBRARIES)
        shell.navigator.navigate(Route.Player)

        assertEquals(ShellBack.POPPED, shell.store.back())
        assertEquals(ShellBack.FIRST_DESTINATION, shell.store.back())
        assertEquals(HOME, shell.selected)
        assertEquals(ShellBack.EXIT_PROMPT, shell.store.back())
        assertTrue(shell.store.state.value.exitPrompt)
        assertEquals(ShellBack.EXIT, shell.store.back())
    }

    @Test
    fun onlyTheFirstDestinationsRootIsWhereBackArmsTheExit() = runTest {
        val shell = Shell(this, online, preferred = null)
        assertTrue(shell.store.atFirstRoot)
        shell.navigator.navigate(Route.Player)
        assertFalse(shell.store.atFirstRoot)
        shell.store.back()
        shell.store.select(LIBRARIES)
        assertFalse(shell.store.atFirstRoot)
    }

    @Test
    fun theExitPromptLastsThreeSecondsAndASwitchResetsIt() = runTest {
        val shell = Shell(this, online, preferred = null)
        assertEquals(ShellBack.EXIT_PROMPT, shell.store.back())
        advanceTimeBy(3_001)
        assertFalse(shell.store.state.value.exitPrompt)
        assertEquals(ShellBack.EXIT_PROMPT, shell.store.back())

        shell.store.select(SEARCH)
        assertFalse(shell.store.state.value.exitPrompt)
        assertEquals(ShellBack.FIRST_DESTINATION, shell.store.back())
        assertEquals(ShellBack.EXIT_PROMPT, shell.store.back())
    }

    @Test
    fun offlineBackReturnsToDownloadsTheFirstDestination() = runTest {
        val shell = Shell(this, online.copy(offline = true), preferred = Startup(SEARCH))
        assertEquals(DOWNLOADS, shell.selected)
        shell.store.select(SETTINGS)
        assertEquals(ShellBack.FIRST_DESTINATION, shell.store.back())
        assertEquals(DOWNLOADS, shell.selected)
    }

    @Test
    fun theAppleTvHandsBackAtTheRootToTheSystem() = runTest {
        val shell = Shell(this, online, preferred = null, appleTv = true)
        assertEquals(ShellBack.SYSTEM, shell.store.back())
        assertFalse(shell.store.state.value.exitPrompt)
    }

    @Test
    fun anOfflineStartIgnoresThePreferenceForTheFirstDestinationThatShows() = runTest {
        val offline = online.copy(offline = true, hasExplore = true, hasLiveTv = true)
        assertEquals(DOWNLOADS, Shell(this, offline, preferred = Startup.LIVE_TV).selected)
        assertEquals(DOWNLOADS, Shell(this, offline, preferred = Startup(EXPLORE)).selected)
        assertEquals(DOWNLOADS, Shell(this, offline, preferred = Startup(LIBRARIES)).selected)
        // The Apple TV keeps no downloads: offline only Settings shows.
        assertEquals(SETTINGS, Shell(this, offline, preferred = Startup(LIBRARIES), appleTv = true).selected)
    }
}
