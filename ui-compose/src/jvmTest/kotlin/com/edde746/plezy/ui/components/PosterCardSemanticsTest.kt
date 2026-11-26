package com.edde746.plezy.ui.components

import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.movieCard
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * What a screen reader finds on a card: one button named by the title, its state the caption and where it sits, that
 * opens it and has its menu; the title and caption drawn under the artwork aren't announced again.
 */
@OptIn(ExperimentalTestApi::class)
class PosterCardSemanticsTest {
    @Test
    fun aCardIsOneButtonNamedByItsTitleThatOpensAndHasAMenu() = runComposeUiTest {
        val pressed = mutableListOf<String>()
        val item = movieCard("m1", "Movie One").copy(caption = "2024")
        setContent {
            TvFrame {
                PosterCard(item, onClick = { pressed += "open" }, onLongClick = { pressed += "menu" }, position = "Row 1 of 1, column 1 of 1")
            }
        }
        val card = onNodeWithContentDescription("Movie One")
        card.assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button))
        card.assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, "2024, Row 1 of 1, column 1 of 1"))
        card.assert(SemanticsMatcher.keyIsDefined(SemanticsActions.OnClick))
        card.assert(SemanticsMatcher.keyIsDefined(SemanticsActions.OnLongClick))
        card.assert(SemanticsMatcher.keyNotDefined(SemanticsProperties.Text))
        onAllNodes(hasText("Movie One")).assertCountEquals(0)
        onAllNodes(hasText("2024")).assertCountEquals(0)
        card.performSemanticsAction(SemanticsActions.OnClick)
        card.performSemanticsAction(SemanticsActions.OnLongClick)
        assertEquals(listOf("open", "menu"), pressed)
    }
}
