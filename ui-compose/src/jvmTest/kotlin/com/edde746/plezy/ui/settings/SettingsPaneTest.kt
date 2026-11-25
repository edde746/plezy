package com.edde746.plezy.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onLast
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.hasScrollToNodeAction
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.Startup
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.settings.SettingsPageId
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TestDesktop
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.onboarding.OnboardingRoute
import com.edde746.plezy.ui.app.PlezyFrame
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.util.Collections
import java.util.concurrent.ConcurrentHashMap
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * Settings on a wide desktop window: every page opened from the hub's list shows in the pane beside it, without a back
 * button there (the list is the way on), taking the place of the page open there at once, which leaves without one too;
 * a page that page opens in turn has one, and comes and goes as any pushed screen.
 */
@OptIn(ExperimentalTestApi::class)
class SettingsPaneTest {
    private val main = TestMain.dispatcher

    @BeforeTest
    fun setUp() {
        TestMain.install()
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    @Test
    fun aSectionOpenedFromTheListHasNoBackButtonAndItsOwnPagesHave() = settings { app, placed ->
        open(app, Route.SettingsPage(SettingsPageId.APPEARANCE))
        waitUntil(timeoutMillis = 10_000) { "settings.row.theme" in placed }
        assertFalse("header.back" in placed, "the section beside the list has no back button")

        open(app, Route.SettingsPage(SettingsPageId.THEME))
        waitUntil(timeoutMillis = 10_000) { "header.back" in placed }
        assertTrue("settings.pane" in placed, "the page the section opened shows beside the list")
    }

    @Test
    fun theProfilePickerOpensBesideTheListWithoutBack() = settings { app, placed ->
        open(app, Route.ProfilePicker(required = false))
        waitUntil(timeoutMillis = 10_000) { "picker.header" in placed }
        assertTrue("settings.pane" in placed, "the picker shows beside the list")
        assertFalse("header.back" in placed, "the picker beside the list has no back button")
    }

    @Test
    fun aSectionGivenWayToAnotherShowsNoBackButtonInAnyFrame() = settings(host = { Changing(it) }) { _, placed -> switchSections(placed) }

    @Test
    fun aSectionTakesThePaneWithItsRowsFromItsFirstFrame() = settings { _, placed -> switchSections(placed) }

    @Test
    fun theListStaysScrolledWhereItWasAsASectionLowInItOpens() = settings(host = { Changing(it) }) { _, placed ->
        // The hub's list, the first list on screen.
        onAllNodes(hasScrollToNodeAction()).onFirst().performScrollToNode(hasText(T.settings.videoPlayerControls))
        val row = onAllNodes(hasText(T.settings.videoPlayerControls) and hasClickAction()).onFirst()
        waitForIdle()
        val before = row.getBoundsInRoot()
        row.performClick()
        waitUntil(timeoutMillis = 10_000) { "settings.keys.reset" in placed }
        // The screen that was open gone, the new one's list alone.
        mainClock.advanceTimeBy(1_000)
        assertEquals(before, onAllNodes(hasText(T.settings.videoPlayerControls) and hasClickAction()).onFirst().getBoundsInRoot(), "the row picked")
    }

    @Test
    fun aScreenOpenedFromTheListTakesThePaneAtOnceAndPagesOverItMove() {
        val hub = listOf(Route.Settings)
        val appearance = hub + Route.SettingsPage(SettingsPageId.APPEARANCE)
        val theme = appearance + Route.SettingsPage(SettingsPageId.THEME)
        assertTrue(swapsSettingsPane(appearance, hub + Route.SettingsPage(SettingsPageId.VIDEO_PLAYBACK)), "section to section")
        assertTrue(swapsSettingsPane(hub, appearance), "the hub alone to a section")
        assertTrue(swapsSettingsPane(appearance, hub), "a section back to the hub alone")
        assertTrue(swapsSettingsPane(appearance, hub + Route.Services), "a section to Services")
        assertTrue(swapsSettingsPane(appearance, hub + Route.ProfilePicker(required = false, manage = true)), "a section to the profiles")
        assertFalse(swapsSettingsPane(appearance, theme), "a page pushed over a section")
        assertFalse(swapsSettingsPane(theme, appearance), "a page popped back to its section")
        assertFalse(swapsSettingsPane(listOf(Route.Home), appearance), "Settings shown again")
        assertFalse(swapsSettingsPane(appearance, listOf(Route.Home)), "Settings left")
        assertFalse(swapsSettingsPane(hub, hub + Route.NowPlaying), "a screen of no settings")
    }

    private fun ComposeUiTest.open(app: AppSession, route: Route) {
        runBlocking(main) { app.navigator.navigate(route) }
        waitForIdle()
    }

    /** Appearance, Video Playback, then General, each picked in the hub's list beside the one open ([switchTo]). */
    private fun ComposeUiTest.switchSections(placed: Set<String>) {
        // The hub alone shows General beside its list.
        switchTo(T.settings.appearance, from = GeneralRow, to = AppearanceRow, placed)
        switchTo(T.settings.videoPlayback, from = AppearanceRow, to = PlaybackRow, placed)
        switchTo(T.settings.general, from = PlaybackRow, to = GeneralRow, placed)
    }

    /**
     * Clicks the hub's row [title] and walks the frames that follow one at a time until the page picked shows (its row
     * [to]; its store loads at its own pace): none shows a back button, and the pane shows the page that was open there
     * (its row [from]) or the one picked in every one, never neither (a page still loading).
     */
    private fun ComposeUiTest.switchTo(title: String, from: String, to: String, placed: Set<String>) {
        waitUntil(timeoutMillis = 10_000) { from in placed }
        mainClock.autoAdvance = false
        onAllNodes(hasText(title) and hasClickAction()).onLast().performClick()
        val deadline = TimeSource.Monotonic.markNow() + 10.seconds
        var frame = 0
        while (to !in placed) {
            assertTrue(deadline.hasNotPassedNow(), "$to never showed after picking $title")
            mainClock.advanceTimeByFrame()
            frame++
            assertFalse("header.back" in placed, "a back button $frame frames after picking $title")
            assertTrue(from in placed || to in placed, "neither page's rows $frame frames after picking $title")
        }
        mainClock.autoAdvance = true
    }

    /**
     * The app on Settings in a 1280 by 720 window drawn by [host], the names its harness probes have placed now in
     * `placed`.
     */
    private fun settings(host: @Composable (AppSession) -> Unit = { Top(it) }, test: ComposeUiTest.(AppSession, Set<String>) -> Unit) = runComposeUiTest {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val platform = TestDesktop(Files.createTempDirectory("settings").toString())
            val app = runBlocking(main) { AppSession(boot.graph, platform, Startup(TopLevelDestination.SETTINGS)) }
            val placed: MutableSet<String> = Collections.newSetFromMap(ConcurrentHashMap())
            val probe = LayoutProbe { name, bounds -> if (bounds == null) placed.remove(name) else placed.add(name) }
            setContent {
                CompositionLocalProvider(LocalLayoutProbe provides probe) {
                    PlezyFrame(boot.graph, platform, appearance = null, Modifier.size(1280.dp, 720.dp)) { host(app) }
                }
            }
            try {
                // The pane, and the hub's list with its rows (they wait for the accounts).
                waitUntil(timeoutMillis = 20_000) { "settings.pane" in placed && "settings.row.general" in placed }
                test(app, placed)
            } finally {
                runBlocking(main) { app.close() }
            }
        }
    }

    /** The top of the app's stack, as the app's navigation shows a settings or profile screen. */
    @Composable
    private fun Top(app: AppSession) {
        val stack by app.navigator.backStack.collectAsState()
        when (val top = stack.last()) {
            Route.Settings, is Route.SettingsPage -> SettingsScreen(app, top)
            else -> OnboardingRoute(app, top)
        }
    }

    /**
     * The top of the app's stack as the app's navigation changes screens: a frame after the change, the new top over the
     * one it replaces, which stays drawn, as it was, until the transition is over.
     */
    @Composable
    private fun Changing(app: AppSession) {
        val stack by app.navigator.backStack.collectAsState()
        val top = stack.last()
        var drawn by remember { mutableStateOf(listOf(top)) }
        LaunchedEffect(top) {
            drawn = (drawn.takeLast(1) + top).distinct()
            delay(300)
            drawn = listOf(top)
        }
        Box(Modifier.fillMaxSize()) {
            for (route in drawn) key(route) {
                Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) { SettingsScreen(app, route) }
            }
        }
    }

    private companion object {
        /** A row only General has; only Appearance; only Video Playback. */
        const val GeneralRow = "settings.row.language"
        const val AppearanceRow = "settings.row.theme"
        const val PlaybackRow = "settings.row.mpv_config"
    }
}