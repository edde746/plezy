package com.edde746.plezy.ui.components

import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicSecureTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.KeyboardActionHandler
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.selection.LocalTextSelectionColors
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.error
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle

/**
 * A password field, the app's one: Material's outlined field over the platform's secure field, which shows dots for
 * the text, tells accessibility it is a password and offers no Cut or Copy. Unlike Material's secure field it can be
 * [readOnly], as a TV's field is until Select ([com.edde746.plezy.ui.focus.rememberKeyboardOnSelect]): a remote passing
 * over it raises no keyboard. [error], when given, shows under it in place of [supporting].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PasswordField(
    state: TextFieldState,
    label: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    readOnly: Boolean = false,
    icon: ImageVector? = null,
    supporting: String? = null,
    error: String? = null,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    onKeyboardAction: KeyboardActionHandler? = null,
) {
    val colors = OutlinedTextFieldDefaults.colors()
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    val isError = error != null
    val textColor = when {
        !enabled -> colors.disabledTextColor
        isError -> colors.errorTextColor
        focused -> colors.focusedTextColor
        else -> colors.unfocusedTextColor
    }
    // The outlined label sits on the border: half its line height above the box, as Material's own fields leave.
    val labelHalf = with(LocalDensity.current) { MaterialTheme.typography.bodySmall.lineHeight.toDp() / 2 }
    CompositionLocalProvider(LocalTextSelectionColors provides colors.textSelectionColors) {
        BasicSecureTextField(
            state = state,
            modifier = modifier
                .semantics(mergeDescendants = true) { if (error != null) error(error) }
                .padding(top = labelHalf)
                .defaultMinSize(OutlinedTextFieldDefaults.MinWidth, OutlinedTextFieldDefaults.MinHeight),
            enabled = enabled,
            readOnly = readOnly,
            textStyle = LocalTextStyle.current.merge(TextStyle(color = textColor)),
            keyboardOptions = keyboardOptions,
            onKeyboardAction = onKeyboardAction,
            interactionSource = interaction,
            cursorBrush = SolidColor(if (isError) colors.errorCursorColor else colors.cursorColor),
            decorator = OutlinedTextFieldDefaults.decorator(
                state = state,
                enabled = enabled,
                lineLimits = TextFieldLineLimits.SingleLine,
                outputTransformation = null,
                interactionSource = interaction,
                label = { Text(label) },
                leadingIcon = icon?.let { { Icon(it, contentDescription = null) } },
                supportingText = (error ?: supporting)?.let { { Text(it) } },
                isError = isError,
                colors = colors,
            ),
        )
    }
}
