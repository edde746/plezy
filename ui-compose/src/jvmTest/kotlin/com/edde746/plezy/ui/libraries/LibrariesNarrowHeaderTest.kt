package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.libraries.LibraryTab
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.HeaderAction
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.compactFilterRow
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A narrow library header: its forms turn with the window's width only, never with the tab or the sort. As the row
 * narrows the buttons turn to their icons before the library's name gives way (never its arrow): Shuffle and the ⋮
 * first, the secondary ones, which here show their icons alone in every form; then the sort chip, then the view chip,
 * then the Filters chip; then the name is cut short; then Shuffle moves into the ⋮. No label but the name is ever cut
 * short. Every control of the row stands on one centre line, every round button is one size, and each draws its icon
 * in its middle.
 */
@OptIn(ExperimentalTestApi::class)
class LibrariesNarrowHeaderTest {
    private var shuffleInMore: Boolean? = null

    /** The order the row gives way in, each step taken only once the one before would cut the name. */
    @Test
    fun theChipsTurnRoundBeforeTheNameGivesWayThenShuffleMoves() {
        // Beside the name at the row's widest: 50 px, the sort chip's label 100 more, the view chip's 80, Filters' 60.
        val widest = { forms: FittedForms -> 50 + (if (forms.sortLabel) 100 else 0) + (if (forms.viewLabel) 80 else 0) + if (forms.filtersLabel) 60 else 0 }
        fun at(row: Int) = fittedForms(row, shuffle = 56, nameWhole = 150, nameLeast = 88, iconNeed = 200, widest = widest)
        val labelled = FittedForms()
        val round = FittedForms(pickerIcon = false, sortLabel = false, viewLabel = false, filtersLabel = false)
        assertEquals(labelled, at(546), "room for every label and the library's icon")
        assertEquals(labelled.copy(pickerIcon = false), at(545), "the library's icon goes first")
        assertEquals(labelled.copy(pickerIcon = false), at(496), "every label, the name whole")
        assertEquals(labelled.copy(pickerIcon = false, sortLabel = false), at(495), "then the sort chip turns round, the icon not back")
        assertEquals(labelled.copy(pickerIcon = false, sortLabel = false), at(396))
        assertEquals(round.copy(filtersLabel = true), at(395), "then the view chip")
        assertEquals(round.copy(filtersLabel = true), at(316))
        assertEquals(round, at(315), "then the Filters chip, the name still whole")
        assertEquals(round, at(194), "only then is the name cut short, down to its least")
        assertEquals(round.copy(shuffleInMenu = true), at(193), "then Shuffle moves into the ⋮")
    }

    /**
     * On the Fold's inner and cover screens, the Pixel, a narrow Windows window and TV, every tab and every sort keep the
     * header's forms; only the library's name is cut short, only once every chip is round, and its chip keeps its arrow.
     */
    @Test
    fun everyTabAndSortKeepTheHeadersForms() = runComposeUiTest {
        var device by mutableStateOf(DEVICES.first())
        var shown by mutableStateOf(LibraryTab.BROWSE)
        var sort by mutableStateOf(SORTS.first())
        setContent { Header(device.width, { shown }, device.formFactor, sort = { sort }) }
        val seen = DEVICES.associate { at ->
            device = at
            val rows = mutableSetOf<Form>()
            val sorts = mutableSetOf<Boolean?>()
            for (tab in TABS) {
                for (label in if (tab == LibraryTab.BROWSE) SORTS else SORTS.take(1)) {
                    shown = tab
                    sort = label
                    waitForIdle()
                    val form = form(tab)
                    rows += form
                    if (tab == LibraryTab.BROWSE) sorts += sortNamed(label)
                    val state = "${at.name}, ${tab.label}, $label: $form"
                    assertTrue(arrowRoom() >= 30.dp, "the library chip keeps its arrow ($state): ${arrowRoom()} after its name")
                    assertTrue(actionsShowIconsAlone(), "Shuffle and the ⋮ show labels while a chip gives way ($state)")
                    val labels = listOfNotNull(tab.label.takeIf { form.viewNamed }, FILTERS.takeIf { onScreen(hasText(FILTERS), unmerged = true).isNotEmpty() }, label.takeIf { sortNamed(label) == true })
                    for (text in labels) {
                        assertTrue(!cut(text), "only the library's name is cut short, not $text ($state)")
                    }
                    if (cut(NAME)) assertTrue(labels.isEmpty(), "the name is cut short while $labels show their labels ($state)")
                }
            }
            assertEquals(1, rows.size, "on ${at.name} the row changes form with the tab or the sort: $rows")
            assertEquals(1, sorts.size, "on ${at.name} the sort chip changes form with the sort: $sorts")
            println("${at.name} (${at.width}): ${rows.single()}, sort named ${sorts.single()}")
            at.name to rows.single()
        }
        assertTrue(seen.getValue("TV").viewNamed, "TV's view chip names the tab: nothing else on the screen does")
    }

    /**
     * On every screen the header is tested on, every control of the row (the chips, the round chips, Shuffle and the ⋮)
     * stands on one centre line, every round one is drawn one size, and each draws its icon in its middle.
     */
    @Test
    fun everyControlStandsOnOneCentreLineAndEveryRoundOneIsOneSize() = runComposeUiTest {
        var device by mutableStateOf(DEVICES.first())
        setContent { Header(device.width, { LibraryTab.BROWSE }, device.formFactor) }
        for (at in DEVICES) {
            device = at
            waitForIdle()
            val controls = onAllNodes(hasClickAction())
            val nodes = controls.fetchSemanticsNodes()
            val centres = nodes.map { it.boundsInRoot.center.y }
            assertTrue(centres.max() - centres.min() <= 0.5f, "on ${at.name} the controls' centres spread ${(centres.max() - centres.min()) / density.density} dp: $centres")
            val round = nodes.indices.map { controls[it].captureToImage().toPixelMap() }.mapNotNull { pixels ->
                // The drawn control is what differs from the square's corner, which its round shape never reaches.
                val corner = pixels[0, 0]
                val differs = { x: Int, y: Int -> pixels[x, y].let { abs(it.red - corner.red) + abs(it.green - corner.green) + abs(it.blue - corner.blue) > 0.05f } }
                val xs = (0 until pixels.width).filter { x -> (0 until pixels.height).any { y -> differs(x, y) } }
                val ys = (0 until pixels.height).filter { y -> (0 until pixels.width).any { x -> differs(x, y) } }
                val drawn = (xs.last() - xs.first() + 1) to (ys.last() - ys.first() + 1)
                if (abs(drawn.first - drawn.second) > 1) return@mapNotNull null
                // The icon: what differs from the fill just inside the top of the circle, inside the circle.
                val fill = pixels[(xs.first() + xs.last()) / 2, ys.first() + 2]
                val radius = drawn.first / 2f - 2
                val middle = (xs.first() + xs.last() + 1) / 2f to (ys.first() + ys.last() + 1) / 2f
                val inked = xs.flatMap { x -> ys.map { y -> x to y } }.filter { (x, y) ->
                    val dx = x + 0.5f - middle.first
                    val dy = y + 0.5f - middle.second
                    val pixel = pixels[x, y]
                    dx * dx + dy * dy < radius * radius && abs(pixel.red - fill.red) + abs(pixel.green - fill.green) + abs(pixel.blue - fill.blue) > 0.5f
                }
                assertTrue(inked.isNotEmpty(), "on ${at.name} a round control draws no icon")
                val across = (inked.minOf { it.first } + inked.maxOf { it.first } + 1) / 2f - middle.first
                val down = (inked.minOf { it.second } + inked.maxOf { it.second } + 1) / 2f - middle.second
                assertTrue(abs(across) <= density.density && abs(down) <= density.density, "on ${at.name} a round control's icon is ${across / density.density}, ${down / density.density} dp off its middle")
                drawn.first
            }
            assertTrue(round.size >= 3, "on ${at.name} the row shows ${round.size} round controls")
            assertTrue(round.max() - round.min() <= 1, "on ${at.name} the round controls are drawn ${round.map { it / density.density }} dp wide")
            println("${at.name}: centres ${centres.distinct()}, round ${round.distinct()}")
        }
    }

    /**
     * The row's forms: the library chip's icon, Shuffle in the ⋮, the view chip naming [tab], the tabs as the view chip,
     * the width the library's name has.
     */
    private data class Form(val pickerIcon: Boolean, val shuffleInMore: Boolean?, val viewNamed: Boolean, val viewChip: Boolean, val name: Dp)

    /** The nodes [matcher] finds that are on screen: not the header's measuring copy, which is never placed. */
    private fun ComposeUiTest.onScreen(matcher: SemanticsMatcher, unmerged: Boolean = false) =
        onAllNodes(matcher, useUnmergedTree = unmerged).fetchSemanticsNodes().filter { it.layoutInfo.isPlaced }

    private fun ComposeUiTest.form(tab: LibraryTab): Form {
        val view = onScreen(hasContentDescription("${T.libraries.content}: ${tab.label}"))
        return Form(
            pickerIcon = onScreen(hasTestTag(PICKER_ICON)).isNotEmpty(),
            shuffleInMore = shuffleInMore,
            viewNamed = view.any { node -> node.config.getOrNull(SemanticsProperties.Text).orEmpty().any { it.text == tab.label } },
            viewChip = view.isNotEmpty(),
            name = nameWidth(),
        )
    }

    /** Whether Browse's sort chip shows [label] (else its icon alone); null where Browse's options are one chip. */
    private fun ComposeUiTest.sortNamed(label: String): Boolean? {
        if (onScreen(hasContentDescription(SORT)).isEmpty()) return null
        return onScreen(hasText(label), unmerged = true).isNotEmpty()
    }

    /** Whether Shuffle and the ⋮ show their icons alone: the first to give way, before any chip. */
    private fun ComposeUiTest.actionsShowIconsAlone(): Boolean =
        onScreen(hasContentDescription(T.libraries.shuffleLibrary) or hasContentDescription(MORE)).let { actions ->
            actions.isNotEmpty() && actions.all { it.config.getOrNull(SemanticsProperties.Text).isNullOrEmpty() }
        }

    /** The room between the library chip's name and the chip's end: the arrow's while it shows. */
    private fun ComposeUiTest.arrowRoom(): Dp {
        val chip = onScreen(hasTestTag(PICKER_ICON) or hasTestTag(PICKER)).single().boundsInRoot
        val name = onScreen(hasText(NAME), unmerged = true).single().boundsInRoot
        return with(density) { (chip.right - name.right).toDp() }
    }

    /** The width the library chip's name has. */
    private fun ComposeUiTest.nameWidth(): Dp = with(density) { onScreen(hasText(NAME), unmerged = true).single().boundsInRoot.width.toDp() }

    /** Whether the text showing [text] is narrower than it needs: cut short. */
    private fun ComposeUiTest.cut(text: String): Boolean {
        val node = onScreen(hasText(text), unmerged = true).first()
        val layouts = mutableListOf<TextLayoutResult>()
        node.config[SemanticsActions.GetTextLayoutResult].action?.invoke(layouts)
        val layout = layouts.single()
        return layout.multiParagraph.intrinsics.maxIntrinsicWidth > layout.size.width + 1
    }

    /**
     * The header on [tab] in a [width] wide window of [formFactor]: the library chip, the view chip, on Browse its
     * options as the app shows them there (on phones the Library options and grouping chips, else the Filters chip, the
     * sort chip of [sort] and the grouping chip), Shuffle and the ⋮.
     */
    @Composable
    private fun Header(width: Dp, tab: () -> LibraryTab, formFactor: FormFactor, sort: () -> String = { SORTS.first() }) {
        PlezyTheme {
            Box(Modifier.size(width, 300.dp)) {
                AdaptiveLayout(formFactor) {
                    CompositionLocalProvider(LocalAppearance provides Appearance.of(AppearanceSettings(), formFactor, supporterUnlocked = false)) {
                        val memory = rememberFocusMemory()
                        val focus = remember { LibrariesFocus(memory) }
                        val shown = tab()
                        val compact = compactFilterRow()
                        LibrariesBar(
                            tabs = TABS,
                            tab = shown,
                            focus = focus,
                            onTab = {},
                            picker = { icon ->
                                PlezyChip(NAME, selected = false, onClick = {}, leadingIcon = PlezyIcons.Movie.takeIf { icon }, dropdown = true, modifier = Modifier.testTag(if (icon) PICKER_ICON else PICKER))
                            },
                            options = when {
                                shown != LibraryTab.BROWSE -> null
                                compact -> { _ ->
                                    PlezyChip("", selected = false, onClick = {}, leadingIcon = PlezyIcons.Tune, dropdown = true, modifier = Modifier.semantics { contentDescription = OPTIONS })
                                    PlezyChip("", selected = false, onClick = {}, leadingIcon = PlezyIcons.Category, dropdown = true, modifier = Modifier.semantics { contentDescription = GROUPING })
                                }
                                else -> { forms ->
                                    PlezyChip(if (forms.filtersLabel) FILTERS else "", selected = false, onClick = {}, leadingIcon = PlezyIcons.FilterAlt, dropdown = true, modifier = Modifier.semantics { contentDescription = FILTERS })
                                    PlezyChip(if (forms.sortLabel) sort() else "", selected = false, onClick = {}, leadingIcon = PlezyIcons.ArrowUpward, dropdown = true, modifier = Modifier.semantics { contentDescription = SORT })
                                    PlezyChip("", selected = false, onClick = {}, leadingIcon = PlezyIcons.Category, dropdown = true, modifier = Modifier.semantics { contentDescription = GROUPING })
                                }
                            },
                            name = NAME,
                            onShuffle = {},
                            more = { shuffle ->
                                SideEffect { shuffleInMore = shuffle != null }
                                HeaderAction(PlezyIcons.MoreVert, MORE, {}, "more")
                            },
                            optionsRoom = browseOptionsRoom(compact, filtersLabel = FILTERS.takeIf { !compact }, sorts = if (compact) emptyList() else SORTS),
                        ) {}
                    }
                }
            }
        }
    }

    /** A screen the header is tested on: its [name], the header's [width], its [formFactor]. */
    private data class Device(val name: String, val width: Dp, val formFactor: FormFactor)

    private companion object {
        const val NAME = "Codec Samples"
        const val OPTIONS = "Library options"
        const val FILTERS = "Filters"
        const val SORT = "Sort By"
        const val GROUPING = "Type"
        const val MORE = "More"
        const val PICKER = "picker"
        const val PICKER_ICON = "picker with its icon"
        val TABS = listOf(LibraryTab.RECOMMENDED, LibraryTab.BROWSE, LibraryTab.COLLECTIONS, LibraryTab.PLAYLISTS)
        val SORTS = listOf("Title", "Date Added", "Release Date", "Community Rating", "Random")

        /**
         * The Fold's inner and cover screens and the Pixel (1768, 840 and 1080 px wide at 420 dpi), the app's least
         * Windows window (640 px at 125 %: 507 dp for the app), a TV's 960 dp less its navigation column.
         */
        val DEVICES = listOf(
            Device("Fold inner", 673.dp, FormFactor.HANDHELD),
            Device("Fold cover", 320.dp, FormFactor.HANDHELD),
            Device("Pixel", 411.dp, FormFactor.HANDHELD),
            Device("Windows narrow", 507.dp, FormFactor.DESKTOP),
            Device("TV", 880.dp, FormFactor.TV),
        )
    }
}
