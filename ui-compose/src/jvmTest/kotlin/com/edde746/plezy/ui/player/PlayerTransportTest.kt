package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.presentation.player.ChapterItem
import com.edde746.plezy.presentation.player.EpisodeButtons
import com.edde746.plezy.presentation.player.TrackItem
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The bottom bar on every form factor: the timeline with the time it ends, then the transport (Previous, the previous chapter,
 * back, Play/Pause, forward, the next chapter, Next) on the left and the menus on the right.
 */
@OptIn(ExperimentalTestApi::class)
class PlayerTransportTest {
    private val transport = listOf(
        "player.previous", "player.previousChapter", "player.rewind", "player.playPause", "player.fastForward", "player.nextChapter", "player.next",
    )
    private val commands = mutableListOf<PlayerCommand>()

    /**
     * The transport reads Previous, the previous chapter, back, Play/Pause, forward, the next chapter, Next, left to
     * right. On TV focus comes to it on Play/Pause; the D-pad walks it in that order, off buttons included (dimmed), and
     * Right from Next goes on to the settings, the first of the track buttons.
     */
    @Test
    fun onTvFocusStartsOnPlayPauseAndTheDpadWalksTheTransportInOrder() = runComposeUiTest {
        val probe = PlayerProbe()
        tvPlayer(probe) { testPlayerState() }
        runOnIdle { assertEquals("player.playPause", probe.focused) }
        val lefts = transport.map { probe.bounds.getValue(it).left }
        assertEquals(lefts.sorted(), lefts, "the transport's buttons from left to right")

        repeat(3) { press(Key.DirectionLeft) }
        val walked = mutableListOf<String?>(runOnIdle { probe.focused })
        repeat(transport.size - 1) {
            press(Key.DirectionRight)
            walked += runOnIdle { probe.focused }
        }
        assertEquals<List<String?>>(transport, walked, "focus from Previous rightwards")
        press(Key.DirectionRight)
        runOnIdle { assertEquals("player.options", probe.focused) }
    }

    /**
     * On the first episode Previous is there but off, drawn at half its brightness, and a press does nothing; on the last
     * Next is. The one that is on plays its episode.
     */
    @Test
    fun previousIsOffOnTheFirstEpisodeAndNextOnTheLast() = runComposeUiTest {
        var state by mutableStateOf(testPlayerState(episodes = EpisodeButtons(previous = false, next = true)))
        player(FormFactor.TV, onCommand = { commands += it }) { state }
        onNodeWithContentDescription(T.videoControls.previousButton).assertIsNotEnabled()
        onNodeWithContentDescription(T.videoControls.nextButton).assertIsEnabled()
        val faint = brightest(T.videoControls.previousButton)
        val bright = brightest(T.videoControls.nextButton)
        assertTrue(faint < bright * 0.6f, "the off button's icon at luminance $faint, the one on at $bright")
        onNodeWithContentDescription(T.videoControls.previousButton).performClick()
        onNodeWithContentDescription(T.videoControls.nextButton).performClick()

        state = state.copy(episodes = EpisodeButtons(previous = true, next = false))
        onNodeWithContentDescription(T.videoControls.nextButton).assertIsNotEnabled().performClick()
        onNodeWithContentDescription(T.videoControls.previousButton).assertIsEnabled().performClick()
        runOnIdle {
            val episodes = commands.filter { it == PlayerCommand.NextEpisode || it == PlayerCommand.PreviousEpisode }
            assertEquals(listOf<PlayerCommand>(PlayerCommand.NextEpisode, PlayerCommand.PreviousEpisode), episodes)
        }
    }

    /** The chapter buttons are off without chapters; with them they seek to the previous and the next one. */
    @Test
    fun theChapterButtonsSeekByChapterWhereThereAreChapters() = runComposeUiTest {
        var state by mutableStateOf(testPlayerState())
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { state }
        onNodeWithContentDescription(T.videoControls.previousChapterButton).assertIsNotEnabled()
        onNodeWithContentDescription(T.videoControls.nextChapterButton).assertIsNotEnabled().performClick()
        state = state.copy(chapters = listOf(ChapterItem("Opening", "0:00", null, current = true, command = PlayerCommand.SeekToChapter(0))))
        onNodeWithContentDescription(T.videoControls.previousChapterButton).assertIsEnabled().performClick()
        onNodeWithContentDescription(T.videoControls.nextChapterButton).assertIsEnabled().performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.PreviousChapter, PlayerCommand.NextChapter), commands) }
    }

    /** The seek buttons, the desktop's bar and a phone's centre transport, say the Small Skip Duration and seek by it. */
    @Test
    fun theSeekButtonsSayAndSeekTheSmallSkipDuration() {
        for (formFactor in listOf(FormFactor.DESKTOP, FormFactor.HANDHELD)) runComposeUiTest {
            val seen = mutableListOf<PlayerCommand>()
            player(formFactor, onCommand = { seen += it }) { testPlayerState().copy(seekSeconds = 15) }
            onNodeWithContentDescription(T.videoControls.seekBackwardButton("15")).performClick()
            onNodeWithContentDescription(T.videoControls.seekForwardButton("15")).performClick()
            runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SeekBy(-15.0), PlayerCommand.SeekBy(15.0)), seen, "$formFactor") }
        }
    }

    /** The time left and the clock time the video ends show together in the timeline row, on every form factor. */
    @Test
    fun theTimelineSaysWhenTheVideoEnds() {
        val timeline = MutableStateFlow(testTimeline.copy(endsAt = "Ends at 21:43", finishClock = "21:43"))
        for (formFactor in listOf(FormFactor.DESKTOP, FormFactor.TV, FormFactor.HANDHELD)) {
            runComposeUiTest {
                player(formFactor, timeline = timeline) { testPlayerState() }
                onNodeWithText("${testTimeline.remaining} · 21:43").assertExists()
            }
        }
    }

    /**
     * The menus on the desktop read settings, audio, subtitles, the picture's fit, always on top and fullscreen, left
     * to right after the volume.
     */
    @Test
    fun onTheDesktopTheMenusFollowTheVolumeInOrder() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.DESKTOP, probe = probe) { withTracks().copy(alwaysOnTop = false) }
        waitForIdle()
        val row = listOf("player.mute", "player.options", "player.audio", "player.subtitles", "player.fit", "player.alwaysOnTop", "player.fullscreen")
        val lefts = row.map { probe.bounds.getValue(it).left }
        assertEquals(lefts.sorted(), lefts, "$row from left to right")
        assertTrue("player.lock" !in probe.bounds && "player.rotation" !in probe.bounds, "no phone buttons on the desktop")
    }

    /** The settings button is marked while a zoom or a shader is on. */
    @Test
    fun theSettingsButtonIsMarkedWhileThePictureIsAdjusted() = runComposeUiTest {
        val probe = PlayerProbe()
        var state by mutableStateOf(testPlayerState())
        player(FormFactor.DESKTOP, probe = probe) { state }
        waitForIdle()
        assertTrue("player.options.adjusted" !in probe.bounds, "marked at rest")
        state = state.copy(settingsHighlighted = true)
        waitForIdle()
        assertTrue("player.options.adjusted" in probe.bounds, "not marked while adjusted")
    }

    /** The fit button shows the fit now and moves on to the next one: letterbox, fill, stretch. */
    @Test
    fun theFitButtonCyclesThePicturesFit() = runComposeUiTest {
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { testPlayerState() }
        onNodeWithContentDescription(T.videoControls.aspectRatioButton)
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, T.player.options.fit.cover))
            .performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SetVideoFit(VideoFit.FILL)), commands) }
    }

    /**
     * On a phone, upright and on its side (a Pixel's 731 × 411 dp, a Fold's cover screen's 872 × 320 dp), Previous,
     * back 10 s, Play/Pause, forward 10 s and Next sit in one line in the middle of the window, 16 dp apart as iOS's,
     * the timeline under them with nothing below it, and the menus with the screen lock in the top bar, all inside the
     * window, its width and its height. The chapter buttons are not there: the chapters page has them.
     */
    @Test
    fun onAPhoneTheTransportIsCentredAndTheMenusAreInTheTopBar() {
        val sizes = listOf(DpSize(360.dp, 740.dp), DpSize(800.dp, 360.dp), DpSize(731.dp, 411.dp), DpSize(872.dp, 320.dp))
        for (size in sizes) runComposeUiTest {
            val probe = PlayerProbe()
            player(FormFactor.HANDHELD, probe = probe, size = size, onCommand = { commands += it }) { withTracks().copy(rotationLocked = true) }
            waitForIdle()
            val ids = listOf("player.previous", "player.rewind", "player.playPause", "player.fastForward", "player.next")
            val row = ids.map { probe.bounds.getValue(it) }
            assertOneLine(row, "$size: the transport")
            assertEquals(row.map { it.left }.sorted(), row.map { it.left }, "$size: the transport from left to right")
            val gap = with(density) { 16.dp.toPx() }
            row.zipWithNext().forEach { (a, b) -> assertEquals(gap, b.left - a.right, 1f, "$size: 16 dp between $a and $b") }
            val width = with(density) { size.width.toPx() }
            val height = with(density) { size.height.toPx() }
            assertEquals(width / 2, row[2].center.x, 1f, "$size: play/pause in the middle")
            assertEquals(height / 2, row[2].center.y, 1f, "$size: play/pause in the middle")
            val chapters = listOf("player.previousChapter", "player.nextChapter")
            assertEquals(emptyList(), chapters.filter { it in probe.bounds }, "$size: no chapter buttons on a phone")
            onNodeWithContentDescription(T.videoControls.seekBackwardButton("10")).performClick()
            onNodeWithContentDescription(T.videoControls.seekForwardButton("10")).performClick()
            runOnIdle {
                assertEquals(listOf<PlayerCommand>(PlayerCommand.SeekBy(-10.0), PlayerCommand.SeekBy(10.0)), commands.filterIsInstance<PlayerCommand.SeekBy>())
                commands.clear()
            }
            val scrub = probe.bounds.getValue("player.scrub")
            assertTrue(row.all { it.bottom <= scrub.top }, "$size: the transport $row above the timeline $scrub")
            // Upright the bar keeps the title's room: the fit and the locks move into the options sheet
            // (PlayerChromeTest); Settings, Audio and Subtitles always stay.
            val movable = if (size.width > size.height) listOf("player.fit", "player.rotation", "player.lock") else emptyList()
            val names = listOf("player.options", "player.audio", "player.subtitles") + movable
            val missing = names.filter { it !in probe.bounds }
            assertEquals(emptyList(), missing, "$size: menus not laid out")
            val menus = names.map { probe.bounds.getValue(it) }
            assertTrue((row + menus).all { it.left >= 0f && it.right <= width }, "$size: the bar's buttons inside the window's width")
            assertTrue((row + menus).all { it.top >= 0f && it.bottom <= height }, "$size: the bar's buttons inside the window's height: $menus")
            val back = probe.bounds.getValue("player.back")
            assertTrue(menus.all { abs(it.center.y - back.center.y) <= 1f }, "$size: the menus $menus in the top bar beside Back $back")
            assertTrue("player.mute" !in probe.bounds, "$size: no volume on a phone")
        }
    }

    /** Screen readers find the timeline and the desktop's volume by their names, and hear the position and the level. */
    @Test
    fun screenReadersFindTheTimelineAndTheVolumeByTheirNames() = runComposeUiTest {
        player(FormFactor.DESKTOP) { testPlayerState() }
        onNodeWithContentDescription(T.player.timeline).assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, "0:15 / 0:20"))
        onNodeWithContentDescription(T.videoControls.volumeSlider).assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, "100%"))
    }

    /** An episode with audio and subtitle tracks, so the tracks button shows. */
    private fun withTracks() = testPlayerState().copy(
        audioTracks = listOf(TrackItem(1, "English", null, selected = true), TrackItem(2, "Japanese", null, selected = false)),
        subtitleTracks = listOf(TrackItem(null, "Off", null, selected = false), TrackItem(3, "English", null, selected = true)),
    )

    private fun assertOneLine(buttons: List<Rect>, what: String) {
        assertTrue(buttons.all { abs(it.center.y - buttons[0].center.y) <= 1f }, "$what on one line: $buttons")
    }

    /** The brightest luminance drawn within the button labelled [label] (its icon, over the controls' scrim). */
    private fun ComposeUiTest.brightest(label: String): Float {
        val bounds = onNodeWithContentDescription(label).getBoundsInRoot()
        val pixels = onRoot().captureToImage().toPixelMap()
        val xs = with(density) { bounds.left.toPx().roundToInt().coerceAtLeast(0) until bounds.right.toPx().roundToInt().coerceAtMost(pixels.width) }
        val ys = with(density) { bounds.top.toPx().roundToInt().coerceAtLeast(0) until bounds.bottom.toPx().roundToInt().coerceAtMost(pixels.height) }
        var max = 0f
        for (x in xs) for (y in ys) max = maxOf(max, pixels[x, y].luminance())
        return max
    }
}
