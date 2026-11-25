package com.edde746.plezy.ui.home

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.Startup
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TestDesktop
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.app.PlezyFrame
import com.edde746.plezy.ui.app.PlezyPlatform
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.util.concurrent.ConcurrentHashMap
import kotlin.test.BeforeTest
import kotlin.test.Test

/** What a screen reader hears of Home's command chips on TV: buttons, not tabs, with no selected state. */
@OptIn(ExperimentalTestApi::class)
class HomeChipRolesTest {
    private val main = TestMain.dispatcher

    @BeforeTest
    fun setUp() {
        TestMain.install()
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    @Test
    fun onTvRefreshIsAButtonWithNoSelectedState() = runComposeUiTest {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val desktop = TestDesktop(Files.createTempDirectory("home").toString())
            val platform = object : PlezyPlatform by desktop {
                override val formFactor = FormFactor.TV
            }
            val app = runBlocking(main) { AppSession(boot.graph, platform, Startup(TopLevelDestination.HOME)) }
            val placed = ConcurrentHashMap.newKeySet<String>()
            val probe = LayoutProbe { name, bounds -> if (bounds == null) placed.remove(name) else placed.add(name) }
            setContent {
                CompositionLocalProvider(LocalLayoutProbe provides probe) {
                    PlezyFrame(boot.graph, platform, appearance = null, Modifier.size(960.dp, 540.dp)) { HomeScreen(app) }
                }
            }
            try {
                waitUntil(timeoutMillis = 20_000) { "home.refresh" in placed }
                onNode(hasClickAction() and hasText(T.common.refresh))
                    .assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button))
                    .assert(SemanticsMatcher.keyNotDefined(SemanticsProperties.Selected))
            } finally {
                runBlocking(main) { app.close() }
            }
        }
    }
}
