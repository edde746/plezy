package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.navigation.LocalKeyboardHeight
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalTestApi::class)
class SearchFieldTest {
    /**
     * A phone in landscape (840 × 400 dp) with the keyboard up takes the compact field, 48 dp tall, so the results keep
     * the room above the keyboard; with the keyboard down, or in a tall window, the field is its full 56 dp.
     */
    @Test
    fun theFieldIsCompactWhileTheKeyboardIsUpInAShortWindow() {
        for ((height, keyboard, tall) in listOf(Triple(400, true, 48f), Triple(400, false, 56f), Triple(900, true, 56f))) runComposeUiTest {
            setContent {
                CompositionLocalProvider(LocalKeyboardHeight provides { if (keyboard) 600 else 0 }) {
                    PlezyTheme {
                        Box(Modifier.size(840.dp, height.dp)) {
                            AdaptiveLayout(FormFactor.HANDHELD) {
                                SearchField("Two", "Search", onText = {}, onSubmit = { false }, probe = "field", clearProbe = "clear", fieldModifier = Modifier.testTag("field"))
                            }
                        }
                    }
                }
            }
            val shown = with(density) { onNodeWithTag("field").fetchSemanticsNode().boundsInRoot.height.toDp() }
            assertEquals(tall, shown.value, 0.5f, "a $height dp tall window, the keyboard ${if (keyboard) "up" else "down"}: the field is $shown tall")
        }
    }
}
