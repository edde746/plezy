package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.presentation.settings.SettingsPageId
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class PlezyNavigatorTest {
    @Test
    fun theRequiredProfilePickerOverThePlayerCoversItAndKeepsItUp() {
        val picker = Route.ProfilePicker(required = true)
        val over = BackStackLayout.of(listOf(Route.Home, Route.Player, picker))
        assertEquals(listOf<Route>(Route.Home, Route.Player), over.screens)
        assertEquals(picker, over.overPlayer)
        assertNull(over.sheet)

        val alone = BackStackLayout.of(listOf(Route.Home, picker))
        assertEquals(listOf(Route.Home, picker), alone.screens, "over any other screen it is a screen of its own")
        assertNull(alone.overPlayer)
        assertNull(BackStackLayout.of(listOf(Route.Home, Route.Player, Route.ProfilePicker(required = false))).overPlayer)
    }

    @Test
    fun retainedObjectLivesWhileItsRouteIsOnTheStack() {
        val navigator = PlezyNavigator(Route.Home)
        val released = mutableListOf<String>()
        navigator.navigate(Route.Player)

        val first = navigator.retain(Route.Player, "store", { "player store" }, { released += it })
        val again = navigator.retain(Route.Player, "store", { "another" }, { released += it })
        assertSame(first, again)
        assertEquals(emptyList(), released)

        assertTrue(navigator.back())
        assertEquals(listOf("player store"), released)
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value)
    }

    @Test
    fun aRouteOffTheStackGetsNothing() {
        val navigator = PlezyNavigator(Route.Home)
        assertNull(navigator.retain(Route.Player, "store", { "player store" }, {}))
    }

    @Test
    fun aDestinationNotYetShownKeepsWhatItGotAsTheStacksChange() {
        val navigator = PlezyNavigator(Route.Home)
        val released = mutableListOf<String>()
        val first = navigator.retain(Route.Libraries, "store", { "libraries store" }, { released += it })
        navigator.navigate(Route.Player)
        navigator.back()
        assertEquals(emptyList(), released)
        assertSame(first, navigator.retain(Route.Libraries, "store", { "another" }, { released += it }))

        navigator.close()
        assertEquals(listOf("libraries store"), released)
    }

    @Test
    fun popRemovesTheRouteAndEverythingAboveIt() {
        val navigator = PlezyNavigator(Route.Home)
        navigator.navigate(Route.Player)

        assertTrue(navigator.pop(Route.Player))
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value)
        assertFalse(navigator.pop(Route.Player))
    }

    @Test
    fun aPageOfADestinationLeftIsNoPopOfTheShownOne() {
        val general = Route.SettingsPage(SettingsPageId.GENERAL)
        val navigator = PlezyNavigator(Route.Home)
        navigator.pick(TopLevelDestination.SETTINGS)
        navigator.navigate(general)
        navigator.pick(TopLevelDestination.HOME)
        val before = navigator.stacks.value

        assertFalse(navigator.pop(general))
        assertEquals(before, navigator.stacks.value)

        navigator.pick(TopLevelDestination.SETTINGS)
        assertEquals(listOf(Route.Settings, general), navigator.backStack.value)
    }

    @Test
    fun theRootStays() {
        val navigator = PlezyNavigator(Route.Home)
        assertFalse(navigator.back())
        assertFalse(navigator.pop(Route.Home))
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value)
    }

    @Test
    fun aRouteOpenedAgainStaysOnceAndPickingTheShownDestinationPopsToItsRoot() {
        val navigator = PlezyNavigator(Route.Home)
        navigator.navigate(Route.Player)
        navigator.navigate(Route.Player)
        assertEquals(listOf(Route.Home, Route.Player), navigator.backStack.value)

        navigator.pick(TopLevelDestination.HOME)
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value)
    }

    @Test
    fun aDevelopmentSessionsFirstScreenIsHomesStackUntilHomeIsPickedWhileItShows() {
        val navigator = PlezyNavigator(Route.Player)
        assertEquals(TopLevelDestination.HOME, navigator.stacks.value.shown)
        assertNull(TopLevelDestination.selectedIn(navigator.backStack.value))

        navigator.pick(TopLevelDestination.HOME)
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value)
    }

    @Test
    fun theRemovalListenerHearsEveryRouteThatLeavesTheStacks() {
        val navigator = PlezyNavigator(Route.Home)
        val gone = mutableListOf<Route>()
        navigator.addRemovalListener { gone += it }
        navigator.navigate(Route.Player)
        navigator.back()
        assertEquals(listOf<Route>(Route.Player), gone)
    }

    @Test
    fun closeReleasesWhatEveryStackKept() {
        val navigator = PlezyNavigator(Route.Home)
        val released = mutableListOf<String>()
        navigator.retain(Route.Home, "home", { "home store" }, { released += it })
        navigator.navigate(Route.Player)
        navigator.retain(Route.Player, "player", { "player store" }, { released += it })

        navigator.close()
        assertEquals(setOf("home store", "player store"), released.toSet())
    }

    @Test
    fun pickingTheShownDestinationAtItsRootIsAReselection() = runTest(UnconfinedTestDispatcher()) {
        val navigator = PlezyNavigator(Route.Home)
        val reselected = mutableListOf<TopLevelDestination>()
        backgroundScope.launch { navigator.reselected.collect { reselected += it } }

        navigator.pick(TopLevelDestination.HOME)
        assertEquals(listOf(TopLevelDestination.HOME), reselected)

        // Over a screen the pick pops to the root, which isn't a reselection; another destination isn't either.
        navigator.navigate(Route.HubDetail("hub", "Hub"))
        navigator.pick(TopLevelDestination.HOME)
        navigator.pick(TopLevelDestination.SEARCH)
        assertEquals(listOf<Route>(Route.Search), navigator.backStack.value)
        assertEquals(listOf(TopLevelDestination.HOME), reselected)

        navigator.pick(TopLevelDestination.SEARCH)
        assertEquals(listOf(TopLevelDestination.HOME, TopLevelDestination.SEARCH), reselected)
    }

    @Test
    fun destinationsMountAsTheyFirstShowAndStayMountedWhileTheChromeShowsThem() {
        val navigator = PlezyNavigator(Route.Home)
        val online = listOf(TopLevelDestination.HOME, TopLevelDestination.LIBRARIES, TopLevelDestination.SEARCH, TopLevelDestination.SETTINGS)
        assertEquals(listOf(TopLevelDestination.HOME), navigator.stacks.value.mounted(online))

        navigator.pick(TopLevelDestination.SEARCH)
        navigator.pick(TopLevelDestination.LIBRARIES)
        assertEquals(listOf(TopLevelDestination.HOME, TopLevelDestination.LIBRARIES, TopLevelDestination.SEARCH), navigator.stacks.value.mounted(online))

        // Offline the chrome holds Libraries and Settings: the online destinations' screens go with their items.
        navigator.pick(TopLevelDestination.SETTINGS)
        val offline = listOf(TopLevelDestination.LIBRARIES, TopLevelDestination.SETTINGS)
        assertEquals(listOf(TopLevelDestination.LIBRARIES, TopLevelDestination.SETTINGS), navigator.stacks.value.mounted(offline))
        // The shown destination draws even before the chrome lists it.
        val listed = listOf(TopLevelDestination.HOME, TopLevelDestination.LIBRARIES, TopLevelDestination.SEARCH)
        assertEquals(listed + TopLevelDestination.SETTINGS, navigator.stacks.value.mounted(listed))
    }

    @Test
    fun aProfileSwitchRestartsEveryStackAndReleasesTheirStoresButThePickerSwitching() {
        val navigator = PlezyNavigator(Route.Home)
        val released = mutableListOf<String>()
        navigator.retain(Route.Home, "store", { "home store" }, { released += it })
        navigator.navigate(Route.Settings)
        navigator.navigate(Route.Services)
        navigator.retain(Route.Services, "store", { "services store" }, { released += it })
        val picker = Route.ProfilePicker(required = false)
        navigator.navigate(picker)
        navigator.retain(picker, "store", { "picker store" }, { released += it })

        navigator.restart { it is Route.ProfilePicker }

        assertEquals(listOf(Route.Settings, picker), navigator.backStack.value)
        assertEquals(listOf<Route>(Route.Home), navigator.stacks.value.stack(TopLevelDestination.HOME))
        assertEquals(setOf("home store", "services store"), released.toSet())
        assertEquals("picker store", navigator.retained(picker, "store"))
        assertEquals("home store again", navigator.retain(Route.Home, "store", { "home store again" }, {}))
    }
}
