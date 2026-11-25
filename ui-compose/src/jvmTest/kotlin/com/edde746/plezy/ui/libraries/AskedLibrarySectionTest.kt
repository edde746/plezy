package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.presentation.navigation.LibrarySection
import com.edde746.plezy.presentation.navigation.Startup
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.ui.TestDesktop
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.app.PlezyFrame
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.util.concurrent.ConcurrentHashMap
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * A section asked for from elsewhere (Home's Downloads shortcut, a remote's Downloads tab, a start on Downloads) holds
 * until one is picked in Libraries, also when the Libraries screen is made anew: a profile switch makes every screen
 * anew (a development launch on Downloads switches to the profile it signs in as once it runs).
 *
 * The app's session runs on the tests' main thread ([TestMain]), as the product's does on its own, beside the test's UI
 * thread.
 */
@OptIn(ExperimentalTestApi::class)
class AskedLibrarySectionTest {
    private val main = TestMain.dispatcher

    @BeforeTest
    fun setUp() {
        TestMain.install()
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    @Test
    fun downloadsAskedForStillShowWhenLibrariesIsMadeAnew() = runComposeUiTest {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val platform = TestDesktop(Files.createTempDirectory("downloads").toString())
            val app = runBlocking(main) { AppSession(boot.graph, platform, Startup(TopLevelDestination.LIBRARIES, section = LibrarySection.DOWNLOADS)) }
            val placed = ConcurrentHashMap.newKeySet<String>()
            val probe = LayoutProbe { name, bounds -> if (bounds == null) placed.remove(name) else placed.add(name) }
            var made by mutableIntStateOf(0)
            setContent {
                CompositionLocalProvider(LocalLayoutProbe provides probe) {
                    PlezyFrame(boot.graph, platform, appearance = null, Modifier.size(1280.dp, 720.dp)) { key(made) { LibrariesDestination(app) } }
                }
            }
            try {
                waitUntil(timeoutMillis = 20_000) { "downloads.tab.manage" in placed }
                assertTrue("libraries.picker" in placed, "online, Downloads' row starts with the library chip")

                made++
                waitForIdle()
                assertTrue("downloads.tab.manage" in placed, "Downloads shows on the screen made anew")
                assertFalse("libraries" in placed, "the libraries didn't take its place")
            } finally {
                runBlocking(main) { app.close() }
            }
        }
    }
}
