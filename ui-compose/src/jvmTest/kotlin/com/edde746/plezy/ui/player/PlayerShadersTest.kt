package com.edde746.plezy.ui.player

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.app.BundledText
import com.edde746.plezy.app.DeviceIdentity
import com.edde746.plezy.app.PlatformPlayback
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.presentation.player.OptionChoice
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.player.PlayerOption
import com.edde746.plezy.presentation.player.PlayerOptionId
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.app.SaveResult
import com.edde746.plezy.ui.app.PlezyPlatform
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import java.io.File

/** The player's Shaders page: importing a shader through the system's open dialog, deleting an imported one. */
@OptIn(ExperimentalTestApi::class)
class PlayerShadersTest {
    private val text = T.player.options.shader
    private val commands = mutableListOf<PlayerCommand>()
    private val platform = OpenDialogPlatform()

    /**
     * The import entry shows only where the page offers it (a device with file dialogs); it opens the system's open
     * dialog, and the picked file's name and text import it, or a file that couldn't be read fails the import.
     */
    @Test
    fun importOpensTheOpenDialogAndImportsThePickedFile() = runComposeUiTest {
        var state by mutableStateOf(shadersPage(importLabel = null))
        player(FormFactor.HANDHELD, onCommand = { commands += it }, platform = platform) { state }
        onNodeWithText(CUSTOM).assertExists()
        onNodeWithText(text.importShader).assertDoesNotExist()

        state = shadersPage(importLabel = text.importShader)
        onNodeWithText(text.importShader).performClick()
        val opened = assertNotNull(platform.opened, "the open dialog shown")
        runOnIdle {
            opened("Sharpen.glsl", "//!HOOK MAIN")
            platform.failed!!()
            assertEquals(listOf(PlayerCommand.ImportShader("Sharpen.glsl", "//!HOOK MAIN"), PlayerCommand.ShaderImportFailed), commands)
        }
    }

    /** An imported shader's delete button asks first: Cancel keeps it, Delete deletes it. A built-in preset has none. */
    @Test
    fun deletingAnImportedShaderAsksFirst() = runComposeUiTest {
        player(FormFactor.HANDHELD, onCommand = { commands += it }, platform = platform) { shadersPage(importLabel = text.importShader) }
        onNodeWithContentDescription(text.deleteLabel(NVSCALER)).assertDoesNotExist()

        onNodeWithContentDescription(text.deleteLabel(CUSTOM)).performClick()
        onNodeWithText(text.deleteTitle(CUSTOM)).assertExists()
        onNodeWithText(text.cancel).performClick()
        onNodeWithText(text.deleteTitle(CUSTOM)).assertDoesNotExist()
        runOnIdle { assertEquals(emptyList(), commands) }

        onNodeWithContentDescription(text.deleteLabel(CUSTOM)).performClick()
        onNodeWithText(text.delete).performClick()
        onNodeWithText(text.deleteTitle(CUSTOM)).assertDoesNotExist()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.DeleteShader(CUSTOM_ID)), commands) }
        assertNull(platform.opened, "no open dialog")
    }

    /** The Shaders page as the store lists it: off (selected), NVScaler and one imported shader, then [importLabel]. */
    private fun shadersPage(importLabel: String?): PlayerUiState {
        val state = testPlayerState(menu = PlayerMenu.SHADERS)
        val shaders = PlayerOption(
            PlayerOptionId.SHADERS, T.player.options.shaders, T.player.options.off, adjusted = false, PlayerMenu.SHADERS,
            listOf(
                OptionChoice(T.player.options.off, null, selected = true, PlayerCommand.SetShaderPreset("none")),
                OptionChoice(NVSCALER, text.nvscalerDetail, selected = false, PlayerCommand.SetShaderPreset("nvscaler")),
                OptionChoice(CUSTOM, text.customDetail, selected = false, PlayerCommand.SetShaderPreset(CUSTOM_ID), delete = PlayerCommand.DeleteShader(CUSTOM_ID)),
            ),
            on = null, toggle = null, importLabel = importLabel,
        )
        return state.copy(options = state.options + shaders)
    }

    /** A phone's platform as far as the player reaches it: its open dialog, whose answers the test gives. */
    private class OpenDialogPlatform : PlezyPlatform {
        var opened: ((name: String, text: String) -> Unit)? = null
        var failed: (() -> Unit)? = null

        override val formFactor = FormFactor.HANDHELD
        override val appleTv = false
        override val playerConfig: PlayerConfig get() = error("the test plays nothing")
        override val device: DeviceIdentity get() = error("the test names no device")
        override val artworkCacheDirectory: File get() = error("the test shows no artwork")

        override fun createPlayback(settings: DeviceSettings): PlatformPlayback = error("the test plays nothing")

        override fun createMusicAudioPlayer(): AudioPlayer = error("the test plays nothing")

        override fun setFullscreen(fullscreen: Boolean) = Unit

        override fun openUrl(url: String) = false

        override fun setClipboardText(text: String, sensitive: Boolean) = Unit

        override fun deviceFeatures(): DeviceFeatures = error("the test opens no settings")

        override fun bundledTexts(folder: String): List<BundledText> = error("the test opens no settings")

        override fun exit() = Unit

        @Composable
        override fun VideoSurface(engine: PlayerEngine, modifier: Modifier) = Unit

        override fun saveFile(fileName: String, text: String, done: (SaveResult) -> Unit) = Unit

        override fun openFile(opened: (name: String, text: String) -> Unit, failed: () -> Unit) {
            this.opened = opened
            this.failed = failed
        }
    }
}

private const val NVSCALER = "NVScaler"
private const val CUSTOM = "Sharpen"
private const val CUSTOM_ID = "custom_1"
