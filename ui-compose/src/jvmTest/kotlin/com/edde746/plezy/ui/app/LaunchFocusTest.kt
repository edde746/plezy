package com.edde746.plezy.ui.app

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.toAwtImage
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.InputModeManager
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.click
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.BundledText
import com.edde746.plezy.app.DeviceIdentity
import com.edde746.plezy.app.PlatformPlayback
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.components.PlezyButton
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import java.io.File

/**
 * Focus the app places as a screen opens (its first button) in a window that starts outside touch mode, as an Android
 * tablet's does after keys the system took before the app started. The app's frame
 * ([PlezyFrame]) draws that focus only from a key press on, and a touch hides it again, on phones and tablets; TV
 * shows it from the start. The app's session runs on the tests' main thread ([TestMain]), as the product's does on its
 * own.
 */
@OptIn(ExperimentalTestApi::class)
class LaunchFocusTest {
    /** The system's settings, as a platform reports them before it builds a core. */
    @BeforeTest
    fun setUp() {
        TestMain.install()
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    /**
     * On a tablet the first button, focused as the screen opens, is drawn exactly as it is without focus: no ring and
     * no focus layer. Right moves focus to the second button and draws it there; a touch hides it, focus staying put.
     */
    @Test
    fun onATabletFocusPlacedAtLaunchShowsFromAKeyUntilATouch() = runComposeUiTest {
        screen(FormFactor.HANDHELD) { input ->
            onNode(button(FIRST)).assertIsFocused()
            runOnIdle { assertEquals(InputMode.Keyboard, input().inputMode, "the window starts outside touch mode") }
            val firstAtLaunch = shot(FIRST)
            val secondAtRest = shot(SECOND)

            onRoot().performKeyInput { pressKey(Key.DirectionRight) }
            onNode(button(SECOND)).assertIsFocused()
            assertTrue(firstAtLaunch.contentEquals(shot(FIRST)), "the first button, focused as the screen opened, was drawn with its focus before any key")
            assertFalse(secondAtRest.contentEquals(shot(SECOND)), "Right moved focus to the second button without drawing it")

            onRoot().performTouchInput { click(Offset(width - 8f, height - 8f)) }
            onNode(button(SECOND)).assertIsFocused()
            assertTrue(secondAtRest.contentEquals(shot(SECOND)), "the second button's focus still drawn after a touch")
        }
    }

    /** On TV the first button, focused as the screen opens, shows its focus at once. */
    @Test
    fun onTvFocusPlacedAtLaunchShowsAtOnce() = runComposeUiTest {
        screen(FormFactor.TV) {
            onNode(button(FIRST)).assertIsFocused()
            val firstAtLaunch = shot(FIRST)

            onRoot().performKeyInput { pressKey(Key.DirectionRight) }
            onNode(button(SECOND)).assertIsFocused()
            assertFalse(firstAtLaunch.contentEquals(shot(FIRST)), "the first button, focused as the screen opened, wasn't drawn with its focus")
        }
    }

    /**
     * Two buttons, the first focused as they show, in the app's frame on [formFactor], in a 7" tablet's window, given to
     * [test] with the window's input mode as the frame sees it.
     */
    private fun ComposeUiTest.screen(formFactor: FormFactor, test: (input: () -> InputModeManager) -> Unit) =
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "test").use { boot ->
            lateinit var input: InputModeManager
            setContent {
                input = LocalInputModeManager.current
                PlezyFrame(boot.graph, TestPlatform(formFactor), appearance = null, Modifier.size(960.dp, 540.dp)) {
                    val first = remember { FocusRequester() }
                    Row {
                        PlezyButton(FIRST, {}, Modifier.focusRequester(first))
                        PlezyButton(SECOND, {})
                    }
                    LaunchedEffect(Unit) { first.requestFocus() }
                }
            }
            waitForIdle()
            test { input }
        }

    private fun button(title: String): SemanticsMatcher = hasText(title) and hasClickAction()

    /** The button [title]'s pixels as drawn now. */
    private fun ComposeUiTest.shot(title: String): IntArray =
        onNode(button(title)).captureToImage().toAwtImage().let { it.getRGB(0, 0, it.width, it.height, null, 0, it.width) }

    /** The platform as far as the app's frame reaches it: its form factor. [CarScaleTest] frames the app in it too. */
    internal class TestPlatform(override val formFactor: FormFactor) : PlezyPlatform {
        override val appleTv = false
        override val playerConfig: PlayerConfig get() = error("the test plays nothing")
        override val device: DeviceIdentity get() = error("the test names no device")

        /** Never created: the frame shows no artwork. */
        override val artworkCacheDirectory = File(System.getProperty("java.io.tmpdir"), "plezy-test-artwork")

        override fun createPlayback(settings: DeviceSettings): PlatformPlayback = error("the test plays nothing")

        override fun createMusicAudioPlayer(): AudioPlayer = error("the test plays nothing")

        override fun setFullscreen(fullscreen: Boolean) = Unit

        override fun openUrl(url: String) = false

        override fun setClipboardText(text: String, sensitive: Boolean) = Unit

        override fun deviceFeatures(): DeviceFeatures = error("the test reads no device")

        override fun bundledTexts(folder: String): List<BundledText> = error("the test reads no device")

        override fun exit() = Unit

        @Composable
        override fun VideoSurface(engine: PlayerEngine, modifier: Modifier) = Unit

        override fun saveFile(fileName: String, text: String, done: (SaveResult) -> Unit) = Unit

        override fun openFile(opened: (name: String, text: String) -> Unit, failed: () -> Unit) = Unit
    }
}

private const val FIRST = "Nine Winters North"
private const val SECOND = "The Brine Houses"
