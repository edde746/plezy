package com.edde746.plezy.ui.app

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Alignment
import kotlin.test.assertTrue
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.sheetOptionMinHeight
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A car's interface scale over the whole app ([PlezyFrame]): the screens lay out in a window that many times smaller
 * in dp, drawn back over the whole window; anything but a car draws at the platform's density. The app's session runs
 * on the tests' main thread ([TestMain]), as the product's does on its own.
 */
@OptIn(ExperimentalTestApi::class)
class CarScaleTest {
    @BeforeTest
    fun setUp() {
        TestMain.install()
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    @Test
    fun aCarLaysTheAppOutNarrowerThanTheWindow() = runComposeUiTest {
        assertTrue(frameWidth(automotive = true, stored = null) < 960f - 0.5f)
    }

    @Test
    fun aCarLaysTheAppOutAtTheScaleTheUserPicked() = runComposeUiTest {
        assertEquals(960f / 1.8f, frameWidth(automotive = true, stored = 1.8), 0.5f)
    }

    @Test
    fun anythingButACarLaysTheAppOutAtThePlatformsDensity() = runComposeUiTest {
        assertEquals(960f, frameWidth(automotive = false, stored = 1.8), 0.5f)
    }

    @Test
    fun theScaleMultipliesTheDensityAndKeepsTheFontScale() {
        val platform = Density(2f, fontScale = 1.3f)
        assertEquals(platform.density, scaledDensity(platform, 1.0).density)
        val car = scaledDensity(platform, 1.5)
        assertEquals(platform.density * 1.5f, car.density)
        assertEquals(platform.fontScale, car.fontScale)
    }

    @Test
    fun sheetRowsGrowOnlyInACarAndNeverShrinkAControl() {
        val control = 40.dp
        assertEquals(control, sheetOptionMinHeight(automotive = false, controlHeight = control))
        val car = sheetOptionMinHeight(automotive = true, controlHeight = control)
        assertTrue(car > control, "a car's row $car over a $control control")
        // A TV's own controls are taller than the standard row: never shrunk to it.
        val tall = car + 8.dp
        assertEquals(tall, sheetOptionMinHeight(automotive = true, controlHeight = tall))
    }

    @Test
    fun aRootNoticeIsLaidOutInsideTheCarScale() = runComposeUiTest {
        val scale = 960f / frameWidth(automotive = true, stored = null)
        val car = noticeHeight(automotive = true)
        val phone = noticeHeight(automotive = false)
        assertEquals(phone * scale, car, phone * 0.05f)
    }

    /**
     * The frame's modifier is the window's safe area (the activity's system-bar insets, taken once at the root): a root
     * notice at the frame's foot stays inside it, above a bottom bar and beside a side bar.
     */
    @Test
    fun aRootNoticeStaysInsideTheSafeArea() = runComposeUiTest {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val appearance = Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false, automotive = false)
            setContent {
                Box(Modifier.size(960.dp, 540.dp)) {
                    val insets = Modifier.fillMaxSize().padding(start = 48.dp, top = 24.dp, bottom = 40.dp)
                    PlezyFrame(boot.graph, LaunchFocusTest.TestPlatform(FormFactor.HANDHELD), appearance, insets) {
                        Box(Modifier.fillMaxSize()) { TimedToast("Metadata updated", "car.notice", onShown = {}, modifier = Modifier.align(Alignment.BottomStart)) }
                    }
                }
            }
            waitForIdle()
            val bounds = onNodeWithText("Metadata updated").fetchSemanticsNode().boundsInRoot
            assertTrue(bounds.left / density.density >= 48f - 0.5f, "the notice under the side bar")
            assertTrue(bounds.bottom / density.density <= 540f - 40f + 0.5f, "the notice under the bottom bar")
        }
    }

    /**
     * In a car the system bars' insets keep their size in pixels under the interface scale: a root notice stays beside
     * the side bar and above the bottom bar, not under them and not pushed off by the bars grown 1.35 times.
     */
    @Test
    fun aRootNoticeStaysInsideTheSafeAreaAtTheCarScale() = runComposeUiTest {
        val scale = 960f / frameWidth(automotive = true, stored = null)
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val appearance = Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false, automotive = true)
            val px = density.density
            // The window's bars as Android reports them, in pixels: a 48 dp side bar and a 40 dp bottom bar.
            val bars = WindowInsets(left = (48 * px).toInt(), bottom = (40 * px).toInt())
            var frameWidth = 0f
            setContent {
                Box(Modifier.size(960.dp, 540.dp)) {
                    PlezyFrame(boot.graph, LaunchFocusTest.TestPlatform(FormFactor.HANDHELD), appearance, Modifier.fillMaxSize().windowInsetsPadding(bars)) {
                        BoxWithConstraints(Modifier.fillMaxSize()) {
                            frameWidth = maxWidth.value
                            TimedToast("Metadata updated", "car.notice", onShown = {}, modifier = Modifier.align(Alignment.BottomStart))
                        }
                    }
                }
            }
            waitForIdle()
            val bounds = onNodeWithText("Metadata updated").fetchSemanticsNode().boundsInRoot
            assertEquals((960f - 48f) / scale, frameWidth, 0.5f)
            assertTrue(bounds.left / px >= 48f - 0.5f, "the notice under the side bar")
            assertTrue(bounds.bottom / px <= 540f - 40f + 0.5f, "the notice under the bottom bar")
        }
    }

    /** The height in window dp of a root notice ([TimedToast]) drawn in the frame, on a car [automotive] or not. */
    private fun ComposeUiTest.noticeHeight(automotive: Boolean): Float =
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val appearance = Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false, automotive = automotive)
            setContent {
                Box(Modifier.size(960.dp, 540.dp)) {
                    PlezyFrame(boot.graph, LaunchFocusTest.TestPlatform(FormFactor.HANDHELD), appearance, Modifier.fillMaxSize()) {
                        Box(Modifier.fillMaxSize()) { TimedToast("Metadata updated", "car.notice", onShown = {}) }
                    }
                }
            }
            waitForIdle()
            onNodeWithText("Metadata updated").fetchSemanticsNode().boundsInRoot.height / density.density
        }

    /** The width in dp the app's screens get in a 960 dp wide window, on a phone [automotive] or not, [stored] picked. */
    private fun ComposeUiTest.frameWidth(automotive: Boolean, stored: Double?): Float =
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            val appearance = Appearance.of(AppearanceSettings(automotiveUiScale = stored), FormFactor.HANDHELD, supporterUnlocked = false, automotive = automotive)
            var width = 0f
            setContent {
                // The window: 960 dp at the platform's density, whatever the frame's.
                Box(Modifier.size(960.dp, 540.dp)) {
                    PlezyFrame(boot.graph, LaunchFocusTest.TestPlatform(FormFactor.HANDHELD), appearance, Modifier.fillMaxSize()) {
                        BoxWithConstraints { width = maxWidth.value }
                    }
                }
            }
            waitForIdle()
            width
        }
}
