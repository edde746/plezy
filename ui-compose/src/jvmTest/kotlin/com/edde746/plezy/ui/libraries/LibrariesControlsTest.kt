package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.click
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.LibraryFirstCharacter
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.libraries.AlphaJump
import com.edde746.plezy.presentation.libraries.BooleanFilterState
import com.edde746.plezy.presentation.libraries.BrowseUiState
import com.edde746.plezy.presentation.libraries.LibraryTab
import com.edde746.plezy.presentation.libraries.alphaLetterDown
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.components.BooleanFilterRow
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.movieCard
import com.edde746.plezy.ui.theme.LocalAppearance
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The Libraries screen's controls under a keyboard or remote: the sort sheet's rows, a yes/no filter, Exclude, the
 * alphabet bar, and focus handed back when a tab empties.
 */
@OptIn(ExperimentalTestApi::class)
class LibrariesControlsTest {
    /**
     * The sort sheet starts with Clear, then Ascending and Descending, then the fields under Sort By; the shown field
     * takes focus as it opens; Clear, a direction and a field each go to their own pick.
     */
    @Test
    fun theSortSheetOffersClearThenTheDirectionsThenTheFields() = runComposeUiTest {
        val picks = mutableListOf<String>()
        setContent {
            TvFrame {
                Column {
                    SortSheetBody(
                        BrowseUiState(sorts = SORTS, sort = SORTS[1], sortDescending = true),
                        onPick = { picks += it.key },
                        onDirection = { picks += if (it) "descending" else "ascending" },
                        onClear = { picks += "clear" },
                    )
                }
            }
        }
        onNode(hasText("Year")).assertIsFocused()
        val rows = listOf("Clear", "Ascending", "Descending", "Sort By", "Title", "Year", "Date Added")
        val tops = rows.map { onNode(hasText(it)).getBoundsInRoot().top }
        assertEquals(tops.sorted(), tops, "the rows in the order $rows")
        onNode(hasText("Ascending")).performClick()
        onNode(hasText("Title")).performClick()
        onNode(hasText("Clear")).performClick()
        assertEquals(listOf("ascending", "titleSort", "clear"), picks)
    }

    /** On TV the sort panel opens with focus on the shown field, below Clear and the directions. */
    @Test
    fun theSortPanelOpensOnTheShownField() = runComposeUiTest {
        setContent {
            TvFrame {
                val initial = remember { FocusRequester() }
                PlezySheet(onDismiss = {}, title = "Sort", initialFocus = initial) {
                    SortSheetBody(BrowseUiState(sorts = SORTS, sort = SORTS[2]), onPick = {}, onDirection = {}, onClear = {}, initial = initial)
                }
            }
        }
        onNode(hasText("Date Added")).assertIsFocused()
    }

    /** With no sort shown the first row takes focus, and there is no direction to offer. */
    @Test
    fun withNoSortShownTheFirstRowTakesFocus() = runComposeUiTest {
        setContent {
            TvFrame { Column { SortSheetBody(BrowseUiState(sorts = SORTS), onPick = {}, onDirection = {}, onClear = {}) } }
        }
        onNode(hasText("Title")).assertIsFocused()
        onAllNodes(hasText("Ascending")).assertCountEquals(0)
    }

    /** With nothing saved the server's own order is the shown field: it takes focus, and its direction can be turned. */
    @Test
    fun withNothingSavedTheServersOrderIsTheShownField() = runComposeUiTest {
        val directions = mutableListOf<Boolean>()
        val sorts = SORTS.map { if (it.key == "addedAt") it.copy(unsortedDirection = "asc") else it }
        setContent {
            TvFrame { Column { SortSheetBody(BrowseUiState(sorts = sorts), onPick = {}, onDirection = { directions += it }, onClear = {}) } }
        }
        onNode(hasText("Date Added")).assertIsFocused()
        onAllNodes(hasText("Clear")).assertCountEquals(0)
        onNode(hasText("Descending")).performClick()
        assertEquals(listOf(true), directions)
    }

    /** A yes/no filter is one focus stop: Right steps Any, Yes, No and round to Any; Left steps back. */
    @Test
    fun aYesNoFilterStepsWithLeftAndRightAsOneFocusStop() = runComposeUiTest {
        var value by mutableStateOf(BooleanFilterState.ANY)
        setContent {
            TvFrame {
                BooleanFilterRow("Unwatched", value, supportsExclusion = true, onChange = { value = it }, modifier = Modifier.testTag("row"))
            }
        }
        onNodeWithTag("row").requestFocus()
        // The navigation's button and the row.
        onAllNodes(SemanticsMatcher.keyIsDefined(SemanticsProperties.Focused)).assertCountEquals(2)
        key(Key.DirectionRight)
        assertEquals(BooleanFilterState.YES, value)
        key(Key.DirectionRight)
        assertEquals(BooleanFilterState.NO, value)
        key(Key.DirectionRight)
        assertEquals(BooleanFilterState.ANY, value)
        key(Key.DirectionLeft)
        assertEquals(BooleanFilterState.NO, value)
        onNodeWithTag("row").assertIsFocused()
    }

    /** A field that can't be negated steps between Any and Yes alone. */
    @Test
    fun aFieldThatCannotBeNegatedStepsBetweenAnyAndYes() = runComposeUiTest {
        var value by mutableStateOf(BooleanFilterState.YES)
        setContent { TvFrame { BooleanFilterRow("In progress", value, supportsExclusion = false, onChange = { value = it }, modifier = Modifier.testTag("row")) } }
        onNodeWithTag("row").requestFocus()
        key(Key.DirectionRight)
        assertEquals(BooleanFilterState.ANY, value)
    }

    /** Exclude: one focus stop, Right excludes and Left includes. */
    @Test
    fun excludeIsOneStopLeftIncludesRightExcludes() = runComposeUiTest {
        var excluded by mutableStateOf(false)
        setContent { TvFrame { IncludeExcludeRow(excluded, onChange = { excluded = it }, modifier = Modifier.testTag("pair")) } }
        onNodeWithTag("pair").requestFocus()
        key(Key.DirectionRight)
        assertEquals(true, excluded)
        key(Key.DirectionLeft)
        assertEquals(false, excluded)
        onNodeWithTag("pair").assertIsFocused()
    }

    /** A bar too short for 40 letters asks for the rows that fit, a line of text tall each, and draws a run as a dot. */
    @Test
    fun aLongAlphabetIsThinnedToTheRowsThatFit() = runComposeUiTest {
        var asked = 0
        var line = 0.dp
        setContent {
            TvFrame {
                line = with(LocalDensity.current) { MaterialTheme.typography.labelSmall.lineHeight.toDp() }
                Box(Modifier.height(416.dp)) {
                    AlphaJumpBar(LONG.letters, null, rows = { asked = it; LONG.rows(it) }, Modifier, onJump = {}, onSettle = {}, onExit = {})
                }
            }
        }
        assertEquals((400.dp / line).toInt(), asked)
        onNode(hasContentDescription("Alphabet navigation")).assertIsDisplayed()
        onAllNodes(hasText(LONG.letters[0])).assertCountEquals(1)
        onAllNodes(hasText(LONG.letters[1])).assertCountEquals(0)
        onAllNodes(hasText("•")).assertCountEquals(LONG.rows(asked).count { it.size > 1 })
    }

    /**
     * The alphabet's 27 letters: all of them where each gets a line of text, however tight (a TV's bar); in a landscape
     * phone's shorter bar, only the rows that fit, none over another, while a drag down the bar crosses every letter
     * in order whatever its height, the letter under the finger shown in its run's row while the finger is down.
     */
    @Test
    fun aDragDownTheAlphabetReachesEveryLetterWhateverItsHeight() = runComposeUiTest {
        val jumps = mutableListOf<String>()
        var lines by mutableStateOf(27)
        setContent {
            TvFrame {
                val line = with(LocalDensity.current) { MaterialTheme.typography.labelSmall.lineHeight.toDp() }
                // Rows of a line each, and the bar's padding.
                Box(Modifier.height(line * lines + 16.5.dp)) {
                    AlphaJumpBar(ALPHABET, null, rows = { MEDIA_BROWSER.rows(it) }, Modifier, onJump = { jumps += it }, onSettle = {}, onExit = {})
                }
            }
        }
        ALPHABET.forEach { onAllNodes(hasText(it)).assertCountEquals(1) }
        for (height in listOf(27, 20, 14, 9, 5, 2)) {
            lines = height
            waitForIdle()
            jumps.clear()
            onNodeWithContentDescription("Alphabet navigation").performTouchInput {
                down(Offset(centerX, 0f))
                for (step in 1..540) moveTo(Offset(centerX, this.height * step / 540f))
                up()
            }
            assertEquals(ALPHABET, jumps, "$height lines")
        }

        // A letter the bar has no room to draw, inside a run's row: shown in its row while the finger rests on it.
        lines = 14
        waitForIdle()
        val rows = MEDIA_BROWSER.rows(14)
        val hidden = rows.first { it.size > 1 }[1]
        onAllNodes(hasText(hidden)).assertCountEquals(0)
        val at = (0 until 1000).filter { alphaLetterDown(rows, it / 1000.0) == hidden }.average() / 1000
        jumps.clear()
        onNodeWithContentDescription("Alphabet navigation").performTouchInput {
            down(Offset(centerX, 0f))
            moveTo(Offset(centerX, height * at.toFloat()))
        }
        onAllNodes(hasText(hidden)).assertCountEquals(1)
        onNodeWithContentDescription("Alphabet navigation").performTouchInput { up() }
        assertEquals(hidden, jumps.last())
        onAllNodes(hasText(hidden)).assertCountEquals(0)
    }

    /**
     * The current letter, inside a run's row on a short bar, shows there marked; a tap anywhere on that row picks it
     * (Jellyfin and Emby: again, which clears it), and the rows stay where they were.
     */
    @Test
    fun aTapOnARunShowingTheCurrentLetterPicksIt() = runComposeUiTest {
        val jumps = mutableListOf<String>()
        val rows = MEDIA_BROWSER.rows(14)
        val run = rows.indexOfFirst { it.size > 1 }
        val current = rows[run].last()
        setContent {
            TvFrame {
                val line = with(LocalDensity.current) { MaterialTheme.typography.labelSmall.lineHeight.toDp() }
                Box(Modifier.height(line * 14 + 16.5.dp)) {
                    AlphaJumpBar(ALPHABET, current, rows = { MEDIA_BROWSER.rows(it) }, Modifier, onJump = { jumps += it }, onSettle = {}, onExit = {})
                }
            }
        }
        onNode(hasText(current) and SemanticsMatcher.expectValue(SemanticsProperties.Selected, true)).assertExists()
        onNodeWithContentDescription("Alphabet navigation").performTouchInput {
            // The row's top, where a drag would find the run's first letter.
            click(Offset(centerX, height * (run + 0.05f) / rows.size))
        }
        assertEquals(listOf(current), jumps)
        onAllNodes(hasText("•")).assertCountEquals(rows.count { it.size > 1 } - 1)
    }

    /** A letter that leaves nothing to show (Jellyfin, Emby) keeps the bar beside the message, so the letter can be cleared. */
    @Test
    fun aLetterThatLeavesNothingKeepsTheBarBesideTheMessage() = runComposeUiTest {
        val picks = mutableStateListOf<String>()
        setContent {
            TvFrame {
                val memory = rememberFocusMemory()
                val focus = remember { LibrariesFocus(memory) }
                Box(Modifier.size(900.dp, 600.dp)) {
                    PagedItemsGrid(
                        tab = LibraryTab.BROWSE,
                        focus = focus,
                        total = 0,
                        card = { null },
                        shape = CardShape.POSTER,
                        appearance = LocalAppearance.current,
                        onMissing = {},
                        onClick = {},
                        onLongClick = {},
                        letters = ABC,
                        currentLetter = "Q",
                        onLetter = { picks += it; null },
                        empty = { Text("No titles start with Q") },
                    )
                }
            }
        }
        onNodeWithText("No titles start with Q").assertIsDisplayed()
        onNodeWithContentDescription("Alphabet navigation").assertIsDisplayed()
        // The marked letter is one button named by its letter, selected.
        onNode(hasText("Q") and SemanticsMatcher.expectValue(SemanticsProperties.Selected, true)).performSemanticsAction(SemanticsActions.OnClick)
        assertEquals(listOf("Q"), picks.toList())
    }

    /** The letter filter's 'Starting with M · Clear' sits over the grid alone: the bar's letters stay where they were. */
    @Test
    fun theLetterFilterOverTheGridLeavesTheBarInPlace() = runComposeUiTest {
        var filtered by mutableStateOf<String?>(null)
        var cleared = 0
        setContent {
            TvFrame {
                val memory = rememberFocusMemory()
                val focus = remember { LibrariesFocus(memory) }
                Box(Modifier.size(900.dp, 600.dp)) {
                    PagedItemsGrid(
                        tab = LibraryTab.BROWSE,
                        focus = focus,
                        total = 0,
                        card = { null },
                        shape = CardShape.POSTER,
                        appearance = LocalAppearance.current,
                        onMissing = {},
                        onClick = {},
                        onLongClick = {},
                        letters = ABC,
                        currentLetter = filtered,
                        onLetter = { filtered = it; null },
                        filterLetter = filtered,
                        onClearLetter = { cleared++; filtered = null },
                    )
                }
            }
        }
        val bar = onNodeWithContentDescription("Alphabet navigation").getUnclippedBoundsInRoot()
        val ends = listOf("A", "Z").map { onNodeWithText(it).getUnclippedBoundsInRoot() }
        filtered = "M"
        waitForIdle()
        onNodeWithText("Starting with M · Clear").assertIsDisplayed()
        assertEquals(bar, onNodeWithContentDescription("Alphabet navigation").getUnclippedBoundsInRoot(), "the bar keeps its place")
        assertEquals(ends, listOf("A", "Z").map { onNodeWithText(it).getUnclippedBoundsInRoot() }, "no letter moves")
        onNodeWithText("Starting with M · Clear").performClick()
        waitForIdle()
        assertEquals(1, cleared)
        assertTrue(onAllNodesWithText("Starting with M · Clear").fetchSemanticsNodes().isEmpty())
    }

    /**
     * Up and Down move the bar's highlight from the current letter and jump once it has rested; Enter jumps at once;
     * Left leaves the bar for the grid.
     */
    @Test
    fun theAlphabetBarsKeysMoveJumpAndLeave() = runComposeUiTest {
        val jumps = mutableStateListOf<String>()
        var exits = 0
        setContent {
            TvFrame {
                Box(Modifier.size(40.dp, 500.dp)) {
                    AlphaJumpBar(ABC, "C", rows = { ABC.map(::listOf) }, Modifier, onJump = { jumps += it }, onSettle = { jumps += it }, onExit = { exits++ })
                }
            }
        }
        onNodeWithContentDescription("Alphabet navigation").requestFocus()
        onNodeWithContentDescription("Alphabet navigation").assertIsFocused()
        mainClock.autoAdvance = false
        key(Key.DirectionDown)
        key(Key.DirectionDown)
        // A key press takes some of the clock itself, so the jump is checked before and after a full rest.
        assertEquals(emptyList(), jumps.toList(), "before the debounce")
        mainClock.advanceTimeBy(ALPHA_KEY_DEBOUNCE_MS)
        assertEquals(listOf("E"), jumps.toList(), "after the debounce")

        key(Key.DirectionUp)
        key(Key.Enter)
        assertEquals(listOf("E", "D"), jumps.toList(), "after Enter")
        mainClock.advanceTimeBy(ALPHA_KEY_DEBOUNCE_MS * 2)
        assertEquals(listOf("E", "D"), jumps.toList(), "Enter cancels the pending jump")

        key(Key.DirectionLeft)
        assertEquals(1, exits, "Left leaves")
    }

    /** A jump from the focused bar that reloads the list (Jellyfin, Emby) leaves the bar focused once it shows again. */
    @Test
    fun theAlphabetBarKeepsFocusThroughAReloadingJump() = runComposeUiTest {
        var loading by mutableStateOf(false)
        setContent {
            TvFrame {
                val memory = rememberFocusMemory()
                val focus = remember { LibrariesFocus(memory) }
                Box(Modifier.size(900.dp, 600.dp)) {
                    if (loading) {
                        Text("loading")
                    } else {
                        PagedItemsGrid(
                            tab = LibraryTab.BROWSE,
                            focus = focus,
                            total = 3,
                            card = { movieCard("m$it") },
                            shape = CardShape.POSTER,
                            appearance = LocalAppearance.current,
                            onMissing = {},
                            onClick = {},
                            onLongClick = {},
                            letters = ABC,
                            onLetter = { loading = true; null },
                        )
                    }
                }
            }
        }
        onNodeWithContentDescription("Alphabet navigation").requestFocus()
        key(Key.Enter)
        onNodeWithText("loading").assertIsDisplayed()
        loading = false
        waitForIdle()
        onNodeWithContentDescription("Alphabet navigation").assertIsFocused()
    }

    /**
     * Select on the letter the bar's Down has already jumped to keeps it, through the reload that jump made (Jellyfin,
     * Emby: picking the shown letter again clears it); a second Select picks it again.
     */
    @Test
    fun selectOnTheLetterTheBarAlreadyJumpedToKeepsIt() = runComposeUiTest {
        var loading by mutableStateOf(false)
        val picks = mutableStateListOf<String>()
        setContent {
            TvFrame {
                val memory = rememberFocusMemory()
                val focus = remember { LibrariesFocus(memory) }
                Box(Modifier.size(900.dp, 600.dp)) {
                    if (loading) {
                        Text("loading")
                    } else {
                        PagedItemsGrid(
                            tab = LibraryTab.BROWSE,
                            focus = focus,
                            total = 3,
                            card = { movieCard("m$it") },
                            shape = CardShape.POSTER,
                            appearance = LocalAppearance.current,
                            onMissing = {},
                            onClick = {},
                            onLongClick = {},
                            letters = ABC,
                            currentLetter = picks.lastOrNull(),
                            onLetter = { picks += it; loading = true; null },
                        )
                    }
                }
            }
        }
        onNodeWithContentDescription("Alphabet navigation").requestFocus()
        key(Key.DirectionDown)
        mainClock.advanceTimeBy(ALPHA_KEY_DEBOUNCE_MS * 2)
        onNodeWithText("loading").assertIsDisplayed()
        loading = false
        waitForIdle()
        onNodeWithContentDescription("Alphabet navigation").assertIsFocused()
        assertEquals(listOf("B"), picks.toList(), "Down jumps")

        key(Key.DirectionCenter)
        assertEquals(listOf("B"), picks.toList(), "Select keeps the letter jumped to")

        key(Key.DirectionCenter)
        assertEquals(listOf("B", "B"), picks.toList(), "a second Select picks it again")
    }

    /** Focus in a tab whose reload leaves nothing goes back to the chip rather than dropping out. */
    @Test
    fun focusInATabThatEmptiesGoesBackToItsChip() = runComposeUiTest {
        var shown by mutableStateOf(true)
        setContent {
            TvFrame {
                val chip = remember { FocusRequester() }
                Column {
                    Text("chip", Modifier.focusRequester(chip).focusable().testTag("chip"))
                    Box(Modifier.handsFocusBack(shown) { chip.requestFocus() }) {
                        if (shown) Text("item", Modifier.focusable().testTag("item"))
                    }
                }
            }
        }
        onNodeWithTag("item").requestFocus()
        shown = false
        waitForIdle()
        onNodeWithTag("chip").assertIsFocused()
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private companion object {
        val SORTS = listOf(MediaSort("titleSort", "Title"), MediaSort("year", "Year", defaultDirection = "desc"), MediaSort("addedAt", "Date Added"))
        val ABC = ('A'..'Z').map { it.toString() }
        val ALPHABET = listOf("#") + ABC
        val LETTERS = (0 until 40).map { "L$it" }
        val LONG = AlphaJump(LETTERS.map { LibraryFirstCharacter(it, it, 1) })
        val MEDIA_BROWSER = AlphaJump(AlphaJump.MEDIA_BROWSER_ALPHABET)
    }
}
