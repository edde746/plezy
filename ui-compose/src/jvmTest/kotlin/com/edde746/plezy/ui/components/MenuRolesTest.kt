package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test

/** What a screen reader hears of an item's menu on TV: buttons (the one in effect selected), not choices. */
@OptIn(ExperimentalTestApi::class)
class MenuRolesTest {
    @Test
    fun onTvAnItemsMenuListsItsActionsAsButtons() = runComposeUiTest {
        menu(FormFactor.TV) {
            ItemMenu(true, {}, listOf(ItemMenuEntry("Mark as watched") {}, ItemMenuEntry("Keep synced", selected = true) {}), probe = "menu")
        }
        onNode(hasClickAction() and hasText("Mark as watched")).assert(hasRole(Role.Button)).assert(SemanticsMatcher.keyNotDefined(SemanticsProperties.Selected))
        onNode(hasClickAction() and hasText("Keep synced")).assert(hasRole(Role.Button)).assertIsSelected()
    }

    private fun hasRole(role: Role) = SemanticsMatcher.expectValue(SemanticsProperties.Role, role)

    private fun ComposeUiTest.menu(formFactor: FormFactor, content: @Composable () -> Unit) = setContent {
        PlezyTheme {
            AdaptiveLayout(formFactor) {
                OverlayHostBox(Modifier.fillMaxSize()) { content() }
            }
        }
    }
}
