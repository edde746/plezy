package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.width
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.PlayerOption
import com.edde746.plezy.presentation.player.PlayerOptionId
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.interfaceLanguages
import kotlin.test.Test
import kotlin.test.assertTrue

/** The options' rows with a value (Playback speed, Version & quality, Sleep timer…), worded in every language. */
@OptIn(ExperimentalTestApi::class)
class PlayerOptionRowTextTest {
    /**
     * On a desktop's panel, a phone's sheet on its side and a TV's sheet, in every language: each row's title keeps one
     * line, whole, and its value sits after it on one line in what's left; a version too long for that room ends in
     * "…". An upright phone keeps English titles on one line; a long language's title too long for it wraps rather than
     * being cut, its value still beside it.
     */
    @Test
    fun aRowsTitleKeepsOneLineAndItsValueTakesWhatIsLeft() {
        val wrong = mutableListOf<String>()
        // The store gives the fit apart from the options (the aspect button's). Read in English before any other
        // language: the shared test states are worded once, as first read.
        val fit = testPlayerOptions.first { it.id == PlayerOptionId.VIDEO_FIT }
        try {
            for (language in interfaceLanguages) {
                T.locale = language
                for ((formFactor, size) in LAYOUTS) runComposeUiTest {
                    val at = "in $language on $formFactor ${size.width.value.toInt()}×${size.height.value.toInt()}"
                    val oneLine = size.width > size.height || language == "en"
                    val rows = rows(version = LONG_VERSION)
                    player(formFactor, size = size) { testPlayerState(menu = PlayerMenu.OPTIONS).copy(options = rows, videoFit = fit) }
                    mainClock.advanceTimeBy(1_000)
                    for (row in rows.filter { it.toggle == null }) {
                        val title = layout(row.label)
                        if (title.didOverflowHeight || oneLine && title.lineCount != 1) {
                            wrong += "\"${row.label}\" shows on ${title.lineCount} lines, cut: ${title.didOverflowHeight} $at"
                        }
                        val value = layout(row.value)
                        if (value.lineCount != 1) wrong += "\"${row.value}\" shows on ${value.lineCount} lines $at"
                        val titleRight = onNodeWithText(row.label, useUnmergedTree = true).getUnclippedBoundsInRoot().right
                        val valueBounds = onNodeWithText(row.value, useUnmergedTree = true).getUnclippedBoundsInRoot()
                        if (valueBounds.left < titleRight) wrong += "\"${row.value}\" starts ${titleRight - valueBounds.left} into \"${row.label}\" $at"
                        if (valueBounds.width < 8.dp) wrong += "\"${row.value}\" has ${valueBounds.width} beside \"${row.label}\" $at"
                    }
                    // Laid out wider than its one line has room for: drawn cut with "…".
                    if (!layout(LONG_VERSION).didOverflowHeight) wrong += "the long version isn't cut $at"
                }
            }
        } finally {
            T.locale = "en"
        }
        assertTrue(wrong.isEmpty(), wrong.joinToString("\n"))
    }

    /**
     * On a desktop's panel in English, German and Russian, every option with a value shows on one line whole, the panel
     * widening for it: each title and each value ("Original 405 kbps"). A switch's title keeps one line too unless the
     * panel stands at its 440 dp cap, where it may wrap, whole ("Nächste Folge automatisch abspielen"). The sleep timer
     * counting down leaves the panel as wide as with the timer off.
     */
    @Test
    fun onADesktopThePanelFitsEveryOptionAndKeepsItsWidthWhileTheSleepTimerCounts() {
        val wrong = mutableListOf<String>()
        val fit = testPlayerOptions.first { it.id == PlayerOptionId.VIDEO_FIT }
        try {
            for (language in listOf("en", "de", "ru")) {
                T.locale = language
                runComposeUiTest {
                    val off = T.player.options.off
                    var sleep by mutableStateOf(off)
                    player(FormFactor.DESKTOP) {
                        testPlayerState(menu = PlayerMenu.OPTIONS).copy(options = rows("Original 405 kbps", sleep), videoFit = fit)
                    }
                    mainClock.advanceTimeBy(1_000)
                    val capped = panelWidth() >= 439.5.dp
                    for (row in rows("Original 405 kbps", off)) {
                        val title = layout(row.label)
                        val switch = row.toggle != null
                        if (title.didOverflowHeight || (!switch || !capped) && title.lineCount != 1) {
                            wrong += "\"${row.label}\" shows on ${title.lineCount} lines, cut: ${title.didOverflowHeight}, panel ${panelWidth()} in $language"
                        }
                        if (!switch && layout(row.value).didOverflowHeight) wrong += "\"${row.value}\" is cut in $language"
                    }
                    val widthOff = panelWidth()
                    sleep = T.player.options.sleepLeft("1:59:59")
                    mainClock.advanceTimeBy(1_000)
                    if (layout(sleep).didOverflowHeight) wrong += "\"$sleep\" is cut in $language"
                    if (panelWidth() != widthOff) wrong += "the panel is ${panelWidth()} wide counting down, $widthOff with the timer off, in $language"
                }
            }
        } finally {
            T.locale = "en"
        }
        assertTrue(wrong.isEmpty(), wrong.joinToString("\n"))
    }

    /** The laid-out text of the one text node showing [text]. */
    private fun ComposeUiTest.layout(text: String): TextLayoutResult {
        val layouts = mutableListOf<TextLayoutResult>()
        onNodeWithText(text, useUnmergedTree = true).performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(layouts) }
        return layouts.single()
    }

    /** The desktop menu panel's width: the pane a screen reader announces. */
    private fun ComposeUiTest.panelWidth() = onNode(SemanticsMatcher.keyIsDefined(SemanticsProperties.PaneTitle)).getUnclippedBoundsInRoot().width

    /**
     * The options with a page, worded in the current language as the store words them, each value its own: [version]
     * playing, the sleep timer showing [sleep] (its value forms the store's), and auto-play next, a switch.
     */
    private fun rows(version: String, sleep: String = T.player.options.off): List<PlayerOption> {
        val options = T.player.options
        fun row(id: PlayerOptionId, label: String, value: String, page: PlayerMenu) =
            PlayerOption(id, label, value, adjusted = false, page, choices = emptyList(), on = null, toggle = null)
        return listOf(
            row(PlayerOptionId.SPEED, T.videoSettings.playbackSpeed, T.player.speed.normal, PlayerMenu.SPEED),
            row(PlayerOptionId.ZOOM, options.zoom, "100%", PlayerMenu.ZOOM),
            row(PlayerOptionId.VERSIONS, T.videoControls.versionQualityButton, version, PlayerMenu.VERSIONS),
            row(PlayerOptionId.SLEEP_TIMER, options.sleepTimer, sleep, PlayerMenu.SLEEP_TIMER)
                .copy(valueForms = listOf(options.off, options.sleepEndOfVideo, options.sleepLeft("2:00:00"))),
            row(PlayerOptionId.SHADERS, options.shaders, "NVScaler", PlayerMenu.SHADERS),
            PlayerOption(
                PlayerOptionId.AUTO_PLAY_NEXT, options.autoPlayNext, options.on, adjusted = false, page = null, choices = emptyList(),
                on = true, toggle = PlayerCommand.SetAutoPlayNext(false),
            ),
        )
    }

    private companion object {
        /** A desktop, a phone on its side and upright, a TV. */
        val LAYOUTS = listOf(
            FormFactor.DESKTOP to DpSize(960.dp, 540.dp),
            FormFactor.HANDHELD to DpSize(960.dp, 540.dp),
            FormFactor.HANDHELD to DpSize(360.dp, 780.dp),
            FormFactor.TV to DpSize(960.dp, 540.dp),
        )

        /** A version and quality longer than any row has room for. */
        const val LONG_VERSION = "Original 405 kbps · 1080p HEVC Main 10 · Dolby Vision"
    }
}
