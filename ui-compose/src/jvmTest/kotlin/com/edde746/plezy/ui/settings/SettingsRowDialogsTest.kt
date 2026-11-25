package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasAnyDescendant
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.performClick
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
import com.edde746.plezy.ui.TestDesktop
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.app.PlezyFrame
import com.edde746.plezy.ui.onboarding.OnboardingRoute
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.util.Collections
import java.util.concurrent.ConcurrentHashMap
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Settings' rows open their dialogs wherever they show: a row's field dialog stays open while the keyboard it raises
 * shortens the window so far that the row leaves the list, and the hub's download location row opens its dialog from
 * the list beside a section as from the hub alone.
 */
@OptIn(ExperimentalTestApi::class)
class SettingsRowDialogsTest {
    private val main = TestMain.dispatcher
    private var width by mutableStateOf(400.dp)
    private var height by mutableStateOf(800.dp)

    @BeforeTest
    fun setUp() {
        TestMain.install()
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    @Test
    fun aRowsFieldDialogStaysOpenWhileTheShortenedWindowScrollsTheRowAway() = settings { app, placed ->
        open(app, Route.SettingsPage(SettingsPageId.VIDEO_PLAYBACK))
        waitUntil(timeoutMillis = 10_000) { "settings.list" in placed }
        onNode(hasScrollAction()).performScrollToNode(hasText("Maximum Volume"))
        onNode(hasText("Maximum Volume") and hasClickAction()).performClick()
        waitUntil(timeoutMillis = 10_000) { "settings.number.field" in placed }

        // The keyboard up: the window above it shows the page's first rows only.
        height = 240.dp
        waitForIdle()
        assertFalse("settings.row.max_volume" in placed, "the row left the shortened list")
        assertTrue("settings.number.field" in placed, "the dialog stays open")
    }

    @Test
    fun theDownloadLocationRowOpensItsDialogBesideASection() = settings { app, placed ->
        width = 1280.dp
        height = 720.dp
        waitUntil(timeoutMillis = 20_000) { "settings.pane" in placed }
        open(app, Route.SettingsPage(SettingsPageId.GENERAL))
        waitUntil(timeoutMillis = 10_000) { "settings.title" in placed }
        // The hub's list, beside the section: the one holding the hub's rows.
        onNode(hasScrollAction() and hasAnyDescendant(hasText("Appearance"))).performScrollToNode(hasText("Download location"))
        onNode(hasText("Download location") and hasClickAction()).performClick()
        waitUntil(timeoutMillis = 10_000) { "settings.downloadLocation.dialog" in placed }
    }

    private fun ComposeUiTest.open(app: AppSession, route: Route) {
        runBlocking(main) { app.navigator.navigate(route) }
        waitForIdle()
    }

    /** The app on Settings in a window of [width] by [height], the names its harness probes have placed now in `placed`. */
    private fun settings(test: ComposeUiTest.(AppSession, Set<String>) -> Unit) = runComposeUiTest {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val platform = TestDesktop(Files.createTempDirectory("settings").toString())
            val app = runBlocking(main) { AppSession(boot.graph, platform, Startup(TopLevelDestination.SETTINGS)) }
            val placed: MutableSet<String> = Collections.newSetFromMap(ConcurrentHashMap())
            val probe = LayoutProbe { name, bounds -> if (bounds == null) placed.remove(name) else placed.add(name) }
            setContent {
                CompositionLocalProvider(LocalLayoutProbe provides probe) {
                    PlezyFrame(boot.graph, platform, appearance = null, Modifier.size(width, height)) { Top(app) }
                }
            }
            try {
                waitUntil(timeoutMillis = 20_000) { "settings.list" in placed }
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
}
