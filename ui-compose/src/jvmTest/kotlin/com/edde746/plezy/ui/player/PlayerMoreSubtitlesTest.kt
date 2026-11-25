package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.OptionChoice
import com.edde746.plezy.presentation.player.SubtitleLanguage
import com.edde746.plezy.presentation.player.TrackItem
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals

/** The subtitle menu's More subtitles: its entry, the languages' page and a language's page. */
@OptIn(ExperimentalTestApi::class)
class PlayerMoreSubtitlesTest {
    private val more = T.player.menu.moreSubtitles
    private val commands = mutableListOf<PlayerCommand>()
    private val dispatcher = NavigationEventDispatcher()
    private val back = DirectNavigationEventInput().also { dispatcher.addInput(it) }

    private val english = language("en", "English", "OpenSubtitles 2", "OpenSubtitles 3")
    private val japanese = language("ja", "Japanese", "Japanese 1", "Japanese 2")

    /** The subtitle menu offers More subtitles, with how many there are, while there are any; it opens their languages. */
    @Test
    fun theSubtitleMenuOffersMoreSubtitlesWhileThereAreAny() = runComposeUiTest {
        var state by mutableStateOf(subtitles(PlayerMenu.SUBTITLES, found = emptyList()))
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { state }
        onNodeWithText(more).assertDoesNotExist()

        state = subtitles(PlayerMenu.SUBTITLES)
        onNodeWithText(more).assert(hasText("4")).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.OpenMenu(PlayerMenu.MORE_SUBTITLES)), commands) }
    }

    /** A language opens its page, titled by it, where a subtitle picked is added; the page's back button goes back. */
    @Test
    fun aLanguageOpensItsPageWhereASubtitleIsAdded() = runComposeUiTest {
        var state by mutableStateOf(subtitles(PlayerMenu.MORE_SUBTITLES))
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { state }
        onNodeWithText(japanese.label).performClick()

        state = subtitles(PlayerMenu.SUBTITLE_LANGUAGE)
        onNodeWithText(japanese.label).assertExists()
        onNodeWithText("Japanese 2").performClick()
        onNodeWithContentDescription(T.nav.back).performClick()
        runOnIdle {
            assertEquals(listOf(PlayerCommand.OpenSubtitleLanguage("ja"), PlayerCommand.AddSubtitle("https://subs.example/ja/2.srt"), PlayerCommand.Back), commands)
        }
    }

    /**
     * On TV the languages' page opens on its first language and a language's page on its first subtitle. Back leaves
     * the language for the languages, focus on that language, and those for the subtitles, focus on More subtitles.
     */
    @Test
    fun onTvThePagesTakeFocusAndBackReturnsToWhatOpenedThem() = runComposeUiTest {
        var state by mutableStateOf(subtitles(PlayerMenu.SUBTITLES))
        player(FormFactor.TV, dispatcher, onCommand = { commands += it }) { state }
        onNodeWithText("French").assertIsFocused()
        state = subtitles(PlayerMenu.MORE_SUBTITLES)
        onNodeWithText(english.label).assertIsFocused()
        state = subtitles(PlayerMenu.SUBTITLE_LANGUAGE)
        onNodeWithText("Japanese 1").assertIsFocused()

        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Back), commands) }
        state = subtitles(PlayerMenu.MORE_SUBTITLES)
        onNodeWithText(japanese.label).assertIsFocused()

        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Back, PlayerCommand.Back), commands) }
        state = subtitles(PlayerMenu.SUBTITLES)
        onNodeWithText(more).assertIsFocused()
    }

    /** The player on [menu], French selected among the subtitles and [found] not added; a language's page is Japanese's. */
    private fun subtitles(menu: PlayerMenu, found: List<SubtitleLanguage> = listOf(english, japanese)) =
        testPlayerState(menu = menu).copy(
            subtitleTracks = listOf(TrackItem(null, "Off", null, selected = false), TrackItem(1, "French", null, selected = true)),
            moreSubtitles = found,
            subtitleLanguage = if (menu == PlayerMenu.SUBTITLE_LANGUAGE) japanese else null,
        )

    private fun language(key: String, label: String, vararg titles: String) = SubtitleLanguage(
        key,
        label,
        titles.size.toString(),
        titles.mapIndexed { i, title -> OptionChoice(title, detail = null, selected = false, PlayerCommand.AddSubtitle("https://subs.example/$key/${i + 1}.srt")) },
    )
}
