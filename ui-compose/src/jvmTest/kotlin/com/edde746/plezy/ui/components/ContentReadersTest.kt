package com.edde746.plezy.ui.components

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Which enabled accessibility services read the screen's content, so lists keep their semantics for them. */
class ContentReadersTest {
    private val launcherHaptics = EnabledService(speaks = false, followsContent = false)
    private val screenReader = EnabledService(speaks = true, followsContent = true)

    @Test
    fun aServiceThatOnlyFeelsFocusReadsNothing() {
        assertFalse(readsContent(enabled = true, touchExploration = false, services = listOf(launcherHaptics)))
    }

    @Test
    fun aScreenReaderReadsTheContent() {
        assertTrue(readsContent(enabled = true, touchExploration = false, services = listOf(screenReader)))
        assertTrue(readsContent(enabled = true, touchExploration = false, services = listOf(launcherHaptics, screenReader)))
        assertTrue(readsContent(enabled = true, touchExploration = false, services = listOf(EnabledService(speaks = true, followsContent = false))))
    }

    @Test
    fun aServiceFollowingScrollsOrContentChangesReadsTheContent() {
        assertTrue(readsContent(enabled = true, touchExploration = false, services = listOf(EnabledService(speaks = false, followsContent = true))))
    }

    @Test
    fun touchExplorationReadsTheContent() {
        assertTrue(readsContent(enabled = true, touchExploration = true, services = listOf(launcherHaptics)))
    }

    @Test
    fun anUnlistedServiceAsUiAutomationReadsTheContent() {
        assertTrue(readsContent(enabled = true, touchExploration = false, services = emptyList()))
    }

    @Test
    fun nothingReadsWithAccessibilityOff() {
        assertFalse(readsContent(enabled = false, touchExploration = false, services = emptyList()))
        assertFalse(readsContent(enabled = false, touchExploration = false, services = listOf(screenReader)))
    }
}
