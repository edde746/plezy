package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.PixelMap
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.presentation.player.StillWatchingState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.theme.onVideoColors
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** The options button, the options menu and its pages, and the sleep timer's question. */
@OptIn(ExperimentalTestApi::class)
class PlayerOptionsTest {
    private val text = T.player.options
    private val commands = mutableListOf<PlayerCommand>()
    private val dispatcher = NavigationEventDispatcher()
    private val back = DirectNavigationEventInput().also { dispatcher.addInput(it) }

    /** The bottom bar's options button opens the options; pressed again while they (or a page of them) show, closes them. */
    @Test
    fun theOptionsButtonOpensAndClosesTheOptions() = runComposeUiTest {
        var state by mutableStateOf(testPlayerState())
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { state }
        onNodeWithContentDescription(T.videoControls.settingsButton).performClick()
        state = state.copy(menu = PlayerMenu.ZOOM)
        // A click: the open page hides the controls from screen readers, not from the mouse.
        onNodeWithContentDescription(T.videoControls.settingsButton, useUnmergedTree = true).performClick()
        runOnIdle { assertEquals(listOf(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS), PlayerCommand.CloseMenu), commands) }
    }

    /**
     * While a desktop menu's panel is open a screen reader reaches the panel alone, as it does a sheet: the controls
     * under it are hidden from it.
     */
    @Test
    fun onDesktopAScreenReaderReachesOnlyTheOpenPanel() = runComposeUiTest {
        player(FormFactor.DESKTOP) { testPlayerState(menu = PlayerMenu.OPTIONS) }
        onNodeWithText(text.videoFit).assertExists()
        onNodeWithContentDescription(testPlayerState().playPauseLabel).assertDoesNotExist()
        onNodeWithContentDescription(T.videoControls.settingsButton).assertDoesNotExist()
    }

    /** The video's show and hide button is hidden from a screen reader under a desktop menu too, and back once it closes. */
    @Test
    fun onDesktopTheVideosButtonIsHiddenFromAScreenReaderWhileAMenuIsOpen() = runComposeUiTest {
        var state by mutableStateOf(testPlayerState(menu = PlayerMenu.OPTIONS))
        player(FormFactor.DESKTOP) { state }
        onNodeWithContentDescription(T.videoControls.hidePlaybackControls).assertDoesNotExist()
        state = state.copy(menu = null)
        onNodeWithContentDescription(T.videoControls.hidePlaybackControls).assertExists()
    }

    /**
     * Under the sheet's header every option shows with its value in the store's order, an adjusted one marked (no
     * Playback info row: the performance overlay toggle stands for it), and none of the audio settings, which the audio
     * menu holds; an option with a page opens it, a switch flips in place.
     */
    @Test
    fun anOptionOpensItsPageAndASwitchFlips() = runComposeUiTest {
        val bounds = HashMap<String, Rect>()
        player(FormFactor.DESKTOP, probe = LayoutProbe { name, rect -> if (rect != null) bounds[name] = rect else bounds.remove(name) }, onCommand = { commands += it }) {
            testPlayerState(menu = PlayerMenu.OPTIONS)
        }
        onNodeWithText(T.player.info.title).assertDoesNotExist()
        for (option in testPlayerOptions) onNodeWithText(option.label).assertExists()
        for (option in testAudioOptions) onNodeWithText(option.label).assertDoesNotExist()
        onNodeWithText(text.fit.cover).assertExists()
        runOnIdle {
            assertTrue("player.option.videoFit.adjusted" in bounds, "the filled picture marked")
            assertFalse("player.option.zoom.adjusted" in bounds, "no zoom unmarked")
        }
        onNodeWithText(text.videoFit).performClick()
        onNodeWithText(text.autoPlayNext).performClick()
        runOnIdle {
            assertEquals(listOf(PlayerCommand.OpenMenu(PlayerMenu.VIDEO_FIT), PlayerCommand.SetAutoPlayNext(false)), commands)
        }
    }

    /** On TV the settings open with focus on their first row, for the remote. */
    @Test
    fun onTvTheOptionsOpenWithTheFirstOptionFocused() = runComposeUiTest {
        player(FormFactor.TV, dispatcher) { testPlayerState(menu = PlayerMenu.OPTIONS) }
        onNodeWithText(text.videoFit).assertIsFocused()
    }

    /**
     * On TV an audio setting's page opens on its selected choice, each choice with its detail; a pick sends its command.
     * Back leaves the page for the audio menu (the store's Back), where focus returns to the setting the page belongs to.
     */
    @Test
    fun onTvAnAudioPageFocusesItsChoiceAndBackReturnsToItsRowInTheAudioMenu() = runComposeUiTest {
        val limits = T.settings
        var state by mutableStateOf(testPlayerState(menu = PlayerMenu.AUDIO_CHANNELS))
        player(FormFactor.TV, dispatcher, onCommand = { commands += it }) { state }
        onNodeWithText(limits.audioChannelLimitStereo).assertIsFocused()
        onNodeWithText(limits.audioChannelLimitSurround51Description).assertExists()

        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Back), commands) }
        state = state.copy(menu = PlayerMenu.AUDIO)
        onNodeWithText(text.audioChannels).assertIsFocused()

        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(PlayerCommand.CloseMenu, commands.last()) }

        state = state.copy(menu = PlayerMenu.AUDIO_CHANNELS)
        onNodeWithText(limits.audioChannelLimitSurround51).performClick()
        runOnIdle { assertEquals(PlayerCommand.SetAudioChannels(AudioChannels.SURROUND_51), commands.last()) }
    }

    /** On a touch screen and on TV alike a page has a back button beside its title, to the options. */
    @Test
    fun aPageGoesBackByItsButtonOnTouchScreensAndTv() {
        for (formFactor in listOf(FormFactor.HANDHELD, FormFactor.TV)) {
            runComposeUiTest {
                commands.clear()
                player(formFactor, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.VIDEO_FIT) }
                onNodeWithText(text.videoFit).assertExists()
                onNodeWithContentDescription(T.nav.back).performClick()
                runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Back), commands, "$formFactor") }
            }
        }
    }

    /** A page's title, beside its back button, sits where the options' title did: the header doesn't jump on the way in. */
    @Test
    fun aPagesTitleStartsWhereTheOptionsTitleDid() {
        for (formFactor in listOf(FormFactor.HANDHELD, FormFactor.TV)) {
            runComposeUiTest {
                var state by mutableStateOf(testPlayerState(menu = PlayerMenu.OPTIONS))
                player(formFactor) { state }
                mainClock.advanceTimeBy(1_000)
                val options = onNodeWithText(T.videoControls.settingsButton).getBoundsInRoot()
                state = state.copy(menu = PlayerMenu.VIDEO_FIT)
                mainClock.advanceTimeBy(1_000)
                val page = onNodeWithText(text.videoFit).getBoundsInRoot()
                assertEquals(options.top.value, page.top.value, 0.5f, "$formFactor")
                assertEquals(options.bottom.value, page.bottom.value, 0.5f, "$formFactor")
            }
        }
    }

    /**
     * An upright phone whose top bar has no room for the rotation lock offers it in the options sheet (drawn by the app's
     * overlay host, outside the player), where a press toggles it.
     */
    @Test
    fun aNarrowPhoneOffersTheTopBarsMovedButtonInTheOptions() = runComposeUiTest {
        player(FormFactor.HANDHELD, onCommand = { commands += it }, size = DpSize(300.dp, 700.dp)) {
            testPlayerState(menu = PlayerMenu.OPTIONS).copy(rotationLocked = false)
        }
        onNodeWithText(T.videoControls.lockRotation).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.ToggleRotationLock), commands) }
    }

    /** "Still watching?" shows its countdown; on TV Continue has focus, and Pause answers it. */
    @Test
    fun onTvStillWatchingFocusesContinueAndPauseAnswers() = runComposeUiTest {
        val asking = StillWatchingState(countdown = "Pausing in 25 seconds", secondsLeft = 25, progress = 1f / 6)
        player(FormFactor.TV, dispatcher, onCommand = { commands += it }) { testPlayerState(stillWatching = asking) }
        onNodeWithText(T.player.stillWatching.title).assertExists()
        onNodeWithText(asking.countdown).assertExists()
        onNodeWithText(T.player.stillWatching.keepWatching).assertIsFocused()
        onNodeWithText(T.player.stillWatching.pause).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Pause), commands) }
    }

    /**
     * On TV focused Continue changes nothing of its size: no growth, no ring outside it. Continue and Pause are drawn
     * one height, and the countdown line above them stays clear of both.
     */
    @Test
    fun onTvFocusedContinueIsDrawnAsTallAsPauseAndClearOfTheCountdown() = runComposeUiTest {
        val asking = StillWatchingState(countdown = "Pausing in 25 seconds", secondsLeft = 25, progress = 1f / 6)
        tvPlayer { testPlayerState(stillWatching = asking) }
        val keep = onNodeWithText(T.player.stillWatching.keepWatching)
        keep.assertIsFocused()
        waitForIdle()
        val pixels = onRoot().captureToImage().toPixelMap()
        val countdown = onNodeWithText(asking.countdown).getBoundsInRoot()
        val keepBounds = keep.getBoundsInRoot()
        val pauseBounds = onNodeWithText(T.player.stillWatching.pause).getBoundsInRoot()
        // From the countdown line's bottom edge to the card's: under the buttons lies its 16 dp padding.
        val top = px(countdown.bottom)
        val bottom = px(pauseBounds.bottom + 14.dp)
        val keepRows = drawnRows(pixels, px((keepBounds.left + keepBounds.right) / 2), top, bottom)
        val pauseRows = drawnRows(pixels, px((pauseBounds.left + pauseBounds.right) / 2), top, bottom)
        assertEquals(pauseRows, keepRows, "the rows focused Continue and Pause are drawn on")
        assertEquals(px(pauseBounds.bottom) - px(pauseBounds.top), pauseRows.last - pauseRows.first + 1, "Pause drawn at its own height")
        assertTrue(keepRows.first > top, "focused Continue is drawn up to the countdown line")
    }

    private fun ComposeUiTest.px(dp: Dp): Int = with(density) { dp.toPx() }.roundToInt()

    /** The first and last rows in [top]..<[bottom] of column [x] drawn on: other than the card's own fill. */
    private fun drawnRows(pixels: PixelMap, x: Int, top: Int, bottom: Int): IntRange {
        val drawn = (top until bottom).filter { pixels[x, it] != onVideoColors.surface }
        return drawn.first()..drawn.last()
    }
}
