package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.browse.CardLink
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.PlezyTheme
import com.edde746.plezy.ui.theme.contentDirection
import com.edde746.plezy.ui.theme.hyphenated
import kotlin.test.Test
import kotlin.test.assertEquals

/** A card's drawn title and caption look exactly as the column of texts they replace: same room, same pixels. */
@OptIn(ExperimentalTestApi::class)
class CardLabelTest {
    @Test
    fun aShortTitleAndCaptionMatchTheirTexts() = runComposeUiTest {
        assertSame("Heat", "1995", titleLines = 1)
    }

    @Test
    fun aLongTitleEllipsizedInTwoLinesMatchesItsTexts() = runComposeUiTest {
        assertSame("The Extraordinarily Long Title of an Unremarkable Documentary", "Season 1 Episode 12", titleLines = 2)
    }

    @Test
    fun aShortTitleKeepsTheRoomOfTwoLines() = runComposeUiTest {
        assertSame("Up", "", titleLines = 2)
    }

    @Test
    fun aRightToLeftTitleMatchesItsTexts() = runComposeUiTest {
        assertSame("مسلسل طويل جدا عن البحر", "الموسم ١", titleLines = 2, direction = LayoutDirection.Rtl)
    }

    @Test
    fun aCaptionWithASeasonLinkMatchesItsTexts() = runComposeUiTest {
        assertSame("Pilot", "S2 E5 · The One Where Everything Happens At Once", titleLines = 1, link = CardLink("S2", Route.Home))
    }

    private fun ComposeUiTest.assertSame(title: String, caption: String, titleLines: Int, direction: LayoutDirection = LayoutDirection.Ltr, link: CardLink? = null) {
        setContent {
            PlezyTheme {
                CompositionLocalProvider(LocalLayoutDirection provides direction) {
                    val titleStyle = MaterialTheme.typography.titleSmall.contentDirection().hyphenated()
                    val captionStyle = MaterialTheme.typography.bodySmall.hyphenated()
                    val color = Color.White
                    Row {
                        Box(Modifier.width(WIDTH).background(Color.Black).testTag(TEXTS)) {
                            Column {
                                DetailLinkText(title, null, titleStyle, color, maxLines = titleLines)
                                LinkedLine(caption, link, captionStyle, PlezyColors.TextMuted)
                            }
                        }
                        Box(Modifier.width(WIDTH).background(Color.Black).testTag(DRAWN)) {
                            CardLabel(listOf(LabelLine(title, titleStyle, color, titleLines), LabelLine(caption, captionStyle, PlezyColors.TextMuted, 1, link?.prefix)), shown = true)
                        }
                    }
                }
            }
        }
        val texts = onNodeWithTag(TEXTS).captureToImage().toPixelMap()
        val drawn = onNodeWithTag(DRAWN).captureToImage().toPixelMap()
        assertEquals(texts.width to texts.height, drawn.width to drawn.height, "the same room")
        val differing = (0 until texts.width).sumOf { x -> (0 until texts.height).count { y -> texts[x, y] != drawn[x, y] } }
        assertEquals(0, differing, "pixels differing from the texts'")
    }

    private companion object {
        val WIDTH = 133.dp
        const val TEXTS = "texts"
        const val DRAWN = "drawn"
    }
}
