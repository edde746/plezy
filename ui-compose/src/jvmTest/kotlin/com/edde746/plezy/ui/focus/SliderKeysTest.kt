package com.edde746.plezy.ui.focus

import androidx.compose.material3.Slider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/** A slider without steps moves 5 % of its range a press, clamped at its ends. */
@OptIn(ExperimentalTestApi::class)
class SliderKeysTest {
    private var value by mutableFloatStateOf(0.5f)
    private val slider = FocusRequester()

    @Test
    fun theArrowsMoveASliderWithoutStepsFivePercentAPress() = runComposeUiTest {
        setContent {
            PlezyTheme {
                Slider(value, onValueChange = { value = it }, modifier = Modifier.sliderKeys(value, 0f..1f) { value = it }.focusRequester(slider))
            }
        }
        runOnIdle { slider.requestFocus() }
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        runOnIdle { assertEquals(0.55f, value, 0.0001f) }
        value = 0.02f
        onRoot().performKeyInput { pressKey(Key.DirectionLeft) }
        runOnIdle { assertEquals(0f, value, 0.0001f) }
    }
}
