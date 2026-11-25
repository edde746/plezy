package com.edde746.plezy.input

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TabNavigationTest {
    private class Screen(var tabs: List<String> = listOf("a", "b", "c"), var selected: String = tabs.first(), var active: Boolean = true) {
        val tab = TabScreen({ tabs }, { selected }, { selected = it }, { active })
    }

    @Test
    fun aRegisteredScreenTakesTheShoulderButtons() {
        val navigation = TabNavigation()
        val screen = Screen()
        navigation.register(screen.tab)
        assertTrue(navigation.dispatch(next = true))
        assertEquals("b", screen.selected)
        assertTrue(navigation.dispatch(next = false))
        assertEquals("a", screen.selected)
    }

    @Test
    fun nextStopsAtTheLastTab() {
        val navigation = TabNavigation()
        val screen = Screen()
        navigation.register(screen.tab)
        repeat(2) { navigation.dispatch(next = true) }
        assertEquals("c", screen.selected)
        assertTrue(navigation.dispatch(next = true), "the press is taken at the last tab too")
        assertEquals("c", screen.selected)
    }

    @Test
    fun previousStopsAtTheFirstTab() {
        val navigation = TabNavigation()
        val screen = Screen(selected = "c")
        navigation.register(screen.tab)
        repeat(2) { navigation.dispatch(next = false) }
        assertEquals("a", screen.selected)
        navigation.dispatch(next = false)
        assertEquals("a", screen.selected)
    }

    @Test
    fun aCoveredScreenKeepsItsTabUntilUncovered() {
        val navigation = TabNavigation()
        val screen = Screen(active = false)
        navigation.register(screen.tab)
        assertFalse(navigation.dispatch(next = true))
        assertEquals("a", screen.selected)
        screen.active = true
        assertTrue(navigation.dispatch(next = true))
        assertEquals("b", screen.selected)
    }

    @Test
    fun onlyTheActiveScreenOfSeveralMoves() {
        val navigation = TabNavigation()
        val under = Screen(active = false)
        val top = Screen()
        navigation.register(under.tab)
        navigation.register(top.tab)
        navigation.dispatch(next = true)
        assertEquals("a", under.selected)
        assertEquals("b", top.selected)
    }

    @Test
    fun unregisteringOneScreenKeepsTheOther() {
        val navigation = TabNavigation()
        val first = Screen()
        val second = Screen()
        navigation.register(first.tab)
        navigation.register(second.tab)
        navigation.dispatch(next = true)
        assertEquals("b", first.selected)
        assertEquals("a", second.selected)
        navigation.unregister(first.tab)
        navigation.dispatch(next = true)
        assertEquals("b", second.selected)
        navigation.unregister(second.tab)
        assertFalse(navigation.dispatch(next = true))
    }

    @Test
    fun theTabSetIsReadAtEachPress() {
        val navigation = TabNavigation()
        val screen = Screen(tabs = listOf("browse"))
        navigation.register(screen.tab)
        navigation.dispatch(next = true)
        assertEquals("browse", screen.selected)
        screen.tabs = listOf("recommended", "browse", "collections", "playlists")
        navigation.dispatch(next = true)
        assertEquals("collections", screen.selected)
    }

    @Test
    fun aSelectedTabOutsideTheSetMovesNothing() {
        val navigation = TabNavigation()
        val screen = Screen(selected = "gone")
        navigation.register(screen.tab)
        navigation.dispatch(next = true)
        navigation.dispatch(next = false)
        assertEquals("gone", screen.selected)
    }
}
