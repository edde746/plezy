package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isToggleable
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToKey
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.settings.SettingChoiceOption
import com.edde746.plezy.presentation.settings.SettingChoiceRow
import com.edde746.plezy.presentation.settings.SettingToggleRow
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.interfaceLanguages
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertTrue

/** Settings' rows with a control at their end (a switch, a menu's value), worded in every language. */
@OptIn(ExperimentalTestApi::class)
class SettingRowTextTest {
    /**
     * A 360 dp phone at font scales 1 and 1.3: every row's title, hint and value show whole (no line cut off, nothing
     * past its box) inside the list's padding, and each switch takes a
     * tap.
     */
    @Test
    fun onANarrowPhoneEveryRowShowsItsTextWholeAndItsControlInReach() {
        val wrong = mutableListOf<String>()
        try {
            for (language in interfaceLanguages) {
                T.locale = language
                val rows = rows()
                for (fontScale in listOf(1f, 1.3f)) runComposeUiTest {
                    val at = "in $language at font scale $fontScale"
                    val toggled = mutableListOf<String>()
                    page(rows, PHONE, FormFactor.HANDHELD, fontScale, onToggle = { toggled += it })
                    val list = onNode(hasScrollToIndexAction())
                    val inside = 16.dp..PHONE.width - 16.dp
                    for ((index, row) in rows.toggles.withIndex()) {
                        list.performScrollToKey("toggle.$index")
                        wrong += cutTexts(at)
                        val text = textBounds(row.title, row.subtitle)
                        if (text.left !in inside || text.right !in inside) wrong += "\"${row.title}\" spans ${text.left}–${text.right}, outside the list's padding $at"
                        onNode(isToggleable() and hasText(row.title)).performClick()
                    }
                    for (index in rows.choices.indices) {
                        list.performScrollToKey("choice.$index")
                        wrong += cutTexts(at)
                    }
                    runOnIdle {
                        if (toggled != rows.toggles.map { it.title }) wrong += "the switch rows took ${toggled.size} of ${rows.toggles.size} taps $at"
                    }
                }
            }
        } finally {
            T.locale = "en"
        }
        assertTrue(wrong.isEmpty(), wrong.distinct().joinToString("\n"))
    }

    /** The rows on a settings list in a window of [size], laid out right to left in a language that reads so. */
    private fun ComposeUiTest.page(
        rows: Rows,
        size: DpSize,
        formFactor: FormFactor,
        fontScale: Float,
        onToggle: (String) -> Unit = {},
    ) = setContent {
        val direction = if (InterfaceLocale.isRightToLeft(T.locale)) LayoutDirection.Rtl else LayoutDirection.Ltr
        CompositionLocalProvider(LocalDensity provides Density(LocalDensity.current.density, fontScale), LocalLayoutDirection provides direction) {
            PlezyTheme {
                Box(Modifier.size(size)) {
                    AdaptiveLayout(formFactor) {
                        SettingsList {
                            settingsGroup(
                                "toggles",
                                null,
                                rows.toggles.mapIndexed { index, row -> SettingsItem("toggle.$index") { shape -> SettingToggleItem(row, { onToggle(row.title) }, shape) } },
                            )
                            settingsGroup(
                                "choices",
                                null,
                                rows.choices.mapIndexed { index, row -> SettingsItem("choice.$index") { shape -> SettingChoiceItem(row, {}, "choice.$index", shape) } },
                            )
                        }
                    }
                }
            }
        }
    }

    /**
     * Each text shown that is cut: lines past its maximum, taller than its box, or a line wider than its box. Not
     * [TextLayoutResult.hasVisualOverflow] whole: the result the semantics action gives lays its paragraph out at the
     * text's widest allowed width, not at the text's own, so its `didOverflowWidth` holds for every text narrower than
     * its slot ("3" in a 360 dp column). Its height half (`didOverflowHeight`: lines past the maximum, or taller than
     * the box) is sound, the line breaks being those of the same widest width the text was laid out at.
     */
    private fun ComposeUiTest.cutTexts(at: String): List<String> {
        val nodes = onAllNodes(SemanticsMatcher.keyIsDefined(SemanticsActions.GetTextLayoutResult), useUnmergedTree = true)
        return List(nodes.fetchSemanticsNodes().size) { nodes[it] }.mapNotNull { node ->
            val layouts = mutableListOf<TextLayoutResult>()
            node.performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(layouts) }
            val layout = layouts.single()
            val widest = (0 until layout.lineCount).maxOf { layout.getLineRight(it) - layout.getLineLeft(it) }
            when {
                layout.didOverflowHeight -> "\"${layout.layoutInput.text}\" is cut after ${layout.lineCount} lines ($at)"
                widest > layout.size.width + 1 -> "\"${layout.layoutInput.text}\" is ${widest - layout.size.width} px wider than its box ($at)"
                else -> null
            }
        }
    }

    /** The bounds of a row's [title] and [hint] together. */
    private fun ComposeUiTest.textBounds(title: String, hint: String?): DpRect {
        val bounds = listOfNotNull(title, hint).map { onNode(hasText(it), useUnmergedTree = true).getUnclippedBoundsInRoot() }
        return DpRect(bounds.minOf { it.left }, bounds.minOf { it.top }, bounds.maxOf { it.right }, bounds.maxOf { it.bottom })
    }

    private class Rows(val toggles: List<SettingToggleRow>, val choices: List<SettingChoiceRow>)

    /**
     * Switches and menus of the Video Playback, Appearance, Subtitle Styling and Downloads pages and Trakt's settings,
     * worded in the current language as those pages word them.
     */
    private fun rows(): Rows {
        val settings = T.settings
        val subtitles = T.subtitlingStyling
        return Rows(
            toggles = listOf(
                SettingToggleRow("autoPlayNext", settings.autoPlayNextEpisode, settings.autoPlayNextEpisodeDescription, checked = true),
                SettingToggleRow("clickVideo", settings.clickVideoTogglesPlayback, settings.clickVideoTogglesPlaybackDescription, checked = false),
                SettingToggleRow("bold", subtitles.bold, null, checked = false),
                SettingToggleRow("useMargins", subtitles.useMargins, subtitles.useMarginsDescription, checked = true),
                SettingToggleRow("wifiOnly", settings.downloadOnWifiOnly, settings.downloadOnWifiOnlyDescription, checked = true),
                SettingToggleRow("autoRemoveWatched", settings.autoRemoveWatchedDownloads, settings.autoRemoveWatchedDownloadsDescription, checked = false),
                SettingToggleRow("hideSpoilers", settings.hideSpoilers, settings.hideSpoilersDescription, checked = false),
                SettingToggleRow("watchedIndicators", settings.showWatchedIndicators, settings.showWatchedIndicatorsDescription, checked = true),
                SettingToggleRow("unwatchedCount", settings.showUnwatchedCount, settings.showUnwatchedCountDescription, checked = true),
                SettingToggleRow("TRAKT.scrobble", T.trakt.scrobble, T.trakt.scrobbleDescription, checked = true),
                SettingToggleRow("TRAKT.watchedSync", T.trakt.watchedSync, T.trakt.watchedSyncDescription, checked = true),
            ),
            choices = listOf(
                choice("continueWatchingAction", settings.continueWatchingAction, null, settings.continueWatchingDetails),
                choice("skipIntro", settings.skipIntroMode, settings.skipIntroModeButtonDescription, settings.skipMarkerModeButton),
                choice("skipCredits", settings.skipCreditsMode, settings.skipCreditsModeButtonDescription, settings.skipMarkerModeButton),
                choice("assOverride", subtitles.assOverride, null, subtitles.overrideScale),
            ),
        )
    }

    private fun choice(id: String, title: String, hint: String?, value: String) =
        SettingChoiceRow(id, title, hint, listOf(SettingChoiceOption("value", value, selected = true)))

    private companion object {
        /** The narrowest common phone (a Galaxy A's 360 dp), at a height the test's window holds. */
        val PHONE = DpSize(360.dp, 760.dp)
    }
}
