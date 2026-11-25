package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFilePart
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaStreamDetails
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.presentation.player.ChapterItem
import com.edde746.plezy.presentation.player.FileInfoState
import com.edde746.plezy.presentation.player.OptionChoice
import com.edde746.plezy.presentation.player.PlayerOption
import com.edde746.plezy.presentation.player.PlayerOptionId
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.player.SubtitleSearchState
import com.edde746.plezy.presentation.player.TrackItem
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.app.LaunchFocusTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * The desktop's docked pages: Shaders, File info and the subtitle search open in the side panel the chapters use, with
 * its header and close button, and the keyboard walks into them and back out to the menu they opened from.
 */
@OptIn(ExperimentalTestApi::class)
class PlayerDockedPagesTest {
    private val commands = mutableListOf<PlayerCommand>()
    private val desktop = DpSize(1280.dp, 800.dp)

    /** The Shaders page asks the platform for its file dialogs. */
    private val platform = LaunchFocusTest.TestPlatform(FormFactor.DESKTOP)

    private fun row(label: String) = hasText(label) and hasClickAction()

    /** Each page's panel stands where the chapters' does, as wide and as tall, with the same close button. */
    @Test
    fun onTheDesktopTheShadersFileInfoAndSubtitleSearchDockWhereTheChaptersDo() = runComposeUiTest {
        val probe = PlayerProbe()
        var state by mutableStateOf(pages.copy(menu = PlayerMenu.CHAPTERS))
        player(FormFactor.DESKTOP, probe = probe, size = desktop, platform = platform) { state }
        waitForIdle()
        val chapters = assertNotNull(probe.bounds["player.menu"], "the chapters docked")
        val close = assertNotNull(probe.bounds["sheet.close"], "the chapters' close button")
        assertTrue(close.left >= chapters.left && close.right <= chapters.right && close.top >= chapters.top, "the close button in the panel")
        for (menu in listOf(PlayerMenu.SHADERS, PlayerMenu.FILE_INFO, PlayerMenu.SUBTITLE_SEARCH)) {
            state = pages.copy(menu = null)
            waitForIdle()
            state = pages.copy(menu = menu)
            waitForIdle()
            assertEquals(chapters, probe.bounds["player.menu"], "$menu docked as the chapters are")
            assertEquals(close, probe.bounds["sheet.close"], "$menu's close button where the chapters' is")
        }
    }

    /** On a docked page the close button closes the menu, Escape and the back button go back to the menu it came from. */
    @Test
    fun onTheDesktopADockedPageClosesByItsButtonAndEscapeGoesBack() = runComposeUiTest {
        player(FormFactor.DESKTOP, size = desktop, platform = platform, onCommand = { commands += it }) { pages.copy(menu = PlayerMenu.FILE_INFO) }
        onNodeWithContentDescription(T.common.close).performClick()
        press(Key.Escape)
        onNodeWithContentDescription(T.nav.back).performClick()
        runOnIdle { assertEquals(listOf(PlayerCommand.CloseMenu, PlayerCommand.Back, PlayerCommand.Back), commands) }
    }

    /**
     * From the settings at their button, the Shaders page docks with focus on the preset in use, the arrow keys walk
     * its presets, and back on the settings focus is on the Shaders row again.
     */
    @Test
    fun onTheDesktopTheKeyboardWalksTheShadersAndBackReturnsToItsRow() = runComposeUiTest {
        var state by mutableStateOf(pages.copy(menu = PlayerMenu.OPTIONS))
        player(FormFactor.DESKTOP, size = desktop, platform = platform, onCommand = { commands += it }) { state }
        onNode(row(T.player.options.videoFit)).assertIsFocused()
        state = pages.copy(menu = PlayerMenu.SHADERS)
        onNode(row(T.player.options.off)).assertIsFocused()
        press(Key.DirectionDown)
        onNode(row(NVSCALER)).assertIsFocused()
        press(Key.Escape)
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Back), commands) }
        state = pages.copy(menu = PlayerMenu.OPTIONS)
        onNode(row(T.player.options.shaders)).assertIsFocused()
    }

    /** From the subtitles the search docks with focus on its language, and back on the subtitles focus is on its entry. */
    @Test
    fun onTheDesktopBackFromTheSubtitleSearchFocusesItsEntry() = runComposeUiTest {
        var state by mutableStateOf(pages.copy(menu = PlayerMenu.SUBTITLES))
        player(FormFactor.DESKTOP, size = desktop, platform = platform, onCommand = { commands += it }) { state }
        state = pages.copy(menu = PlayerMenu.SUBTITLE_SEARCH)
        onNode(row(T.videoControls.language)).assertIsFocused()
        press(Key.Escape)
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Back), commands) }
        state = pages.copy(menu = PlayerMenu.SUBTITLES)
        onNode(row(T.videoControls.searchSubtitles)).assertIsFocused()
    }

    /** A player with every page's content: chapters, shaders, subtitles with the search, and the file info loaded. */
    private val pages: PlayerUiState = run {
        val state = testPlayerState()
        val shaders = PlayerOption(
            PlayerOptionId.SHADERS, T.player.options.shaders, T.player.options.off, adjusted = false, PlayerMenu.SHADERS,
            listOf(
                OptionChoice(T.player.options.off, null, selected = true, PlayerCommand.SetShaderPreset("none")),
                OptionChoice(NVSCALER, T.player.options.shader.nvscalerDetail, selected = false, PlayerCommand.SetShaderPreset("nvscaler")),
            ),
            on = null, toggle = null,
        )
        val video = MediaStreamDetails(MediaStreamKind.VIDEO, 1, codec = "hevc")
        state.copy(
            options = state.options + shaders,
            chapters = listOf(
                ChapterItem("Opening", "0:00", null, current = true, PlayerCommand.SeekToChapter(0)),
                ChapterItem("Story", "5:00", null, current = false, PlayerCommand.SeekToChapter(1)),
            ),
            subtitleTracks = listOf(TrackItem(null, "Off", null, selected = true), TrackItem(3, "English", null, selected = false)),
            subtitleSearch = SubtitleSearchState(
                language = "English",
                languageCode = "en",
                languages = listOf(OptionChoice("English", null, selected = true, PlayerCommand.SearchSubtitles("en", null))),
                title = "Dune",
                searching = false,
                results = emptyList(),
                downloading = null,
                message = null,
            ),
            fileInfo = FileInfoState(false, MediaFileInfo(listOf(MediaFileVersion(parts = listOf(MediaFilePart(streams = listOf(video)))))), "Dune", null),
        )
    }
}

private const val NVSCALER = "NVScaler"
