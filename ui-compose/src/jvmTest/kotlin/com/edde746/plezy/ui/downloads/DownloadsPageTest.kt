package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.presentation.libraries.LibrariesUiState
import com.edde746.plezy.presentation.libraries.libraryListEntries
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.Startup
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TestDesktop
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.app.PlezyFrame
import com.edde746.plezy.ui.home.HomeScreen
import com.edde746.plezy.ui.libraries.LibraryPicker
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.util.concurrent.ConcurrentHashMap
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Downloads is a destination of its own: a page titled Downloads, opened by Home's Downloads shortcut, and no longer a
 * choice of Libraries' library chip.
 *
 * The app's session runs on the tests' main thread ([TestMain]), as the product's does on its own, beside the test's UI
 * thread.
 */
@OptIn(ExperimentalTestApi::class)
class DownloadsPageTest {
    private val main = TestMain.dispatcher

    @BeforeTest
    fun setUp() {
        TestMain.install()
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    @Test
    fun aDownloadsStartShowsThePageUnderItsTitleWithoutTheLibraryChip() = runComposeUiTest {
        session(Startup(TopLevelDestination.DOWNLOADS), { DownloadsDestination(it) }) { app, placed ->
            waitUntil(timeoutMillis = 20_000) { "downloads.tab.manage" in placed }
            assertEquals(listOf<Route>(Route.Downloads), app.navigator.backStack.value)
            onNodeWithText(T.downloads.title).assertExists()
            assertTrue("downloads.title" in placed, "the page has no title")
            assertFalse("libraries.picker" in placed, "the library chip still leads Downloads' row")
        }
    }

    @Test
    fun homesDownloadsShortcutOpensTheDownloadsPage() = runComposeUiTest {
        session(Startup(TopLevelDestination.HOME), { HomeScreen(it) }) { app, placed ->
            waitUntil(timeoutMillis = 20_000) { "home.downloads" in placed }
            onNode(hasClickAction() and hasText(T.navigation.downloads)).performClick()
            waitUntil(timeoutMillis = 5_000) { app.navigator.backStack.value == listOf(Route.Downloads) }
            assertEquals(TopLevelDestination.DOWNLOADS, app.shell.state.value.selected)
        }
    }

    @Test
    fun librariesChipListsTheLibrariesAndNotDownloads() = runComposeUiTest {
        val movies = MediaLibrary(id = "1", backend = BackendKind.JELLYFIN, title = "Movies", kind = MediaKind.MOVIE, serverId = "s1", serverName = "Home")
        val shows = MediaLibrary(id = "2", backend = BackendKind.JELLYFIN, title = "Shows", kind = MediaKind.SHOW, serverId = "s1", serverName = "Home")
        val state = LibrariesUiState(libraries = listOf(movies, shows), entries = libraryListEntries(listOf(movies, shows), groupByServer = true), selected = movies)
        setContent { PlezyTheme { Box(Modifier.size(1280.dp, 720.dp)) { LibraryPicker(state, onLibrary = {}) } } }
        onNode(hasClickAction() and hasText("Movies")).performClick()
        waitForIdle()
        onNodeWithText("Shows").assertExists()
        onAllNodesWithText(T.navigation.downloads).assertCountEquals(0)
    }

    /** [content] of an app session started on [start], in the app's frame, then [test] with the probes placed. */
    private fun ComposeUiTest.session(start: Startup, content: @Composable (AppSession) -> Unit, test: (AppSession, Set<String>) -> Unit) {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val platform = TestDesktop(Files.createTempDirectory("downloads").toString())
            val app = runBlocking(main) { AppSession(boot.graph, platform, start) }
            val placed = ConcurrentHashMap.newKeySet<String>()
            val probe = LayoutProbe { name, bounds -> if (bounds == null) placed.remove(name) else placed.add(name) }
            setContent {
                CompositionLocalProvider(LocalLayoutProbe provides probe) {
                    PlezyFrame(boot.graph, platform, appearance = null, Modifier.size(1280.dp, 720.dp)) { content(app) }
                }
            }
            try {
                test(app, placed)
            } finally {
                runBlocking(main) { app.close() }
            }
        }
    }
}
