package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.InputTransformation
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * A yes-or-no question ([ModalOverlay]): [title], [message], [content] under it where the question holds more (a
 * warning, a switch), then [cancelLabel] and [confirmLabel], in the error colour when [destructive]. Cancel has focus as
 * it opens, so Enter never confirms. Back, Escape, a click outside and Cancel run [onCancel]; [onConfirm] runs alone
 * (whoever shows the question stops showing it). Harness names: `<probe>.cancel`, [confirmProbe].
 */
@Composable
fun ConfirmDialog(
    title: String,
    message: String?,
    confirmLabel: String,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
    probe: String,
    modifier: Modifier = Modifier,
    destructive: Boolean = true,
    cancelLabel: String = T.common.cancel,
    confirmProbe: String = "$probe.confirm",
    content: (@Composable () -> Unit)? = null,
) {
    val cancel = remember { FocusRequester() }
    ModalOverlay(title, onCancel, modifier, initialFocus = cancel) {
        if (message != null || content != null) {
            Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                message?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted) }
                content?.invoke()
            }
        }
        OverlayActions(primary = cancel) {
            PlezyButton(cancelLabel, onCancel, Modifier.focusRequester(cancel).layoutProbe("$probe.cancel"), style = ButtonStyle.TEXT)
            PlezyButton(confirmLabel, onConfirm, Modifier.layoutProbe(confirmProbe), style = if (destructive) ButtonStyle.DESTRUCTIVE else ButtonStyle.PRIMARY)
        }
    }
}

/**
 * A one-field form ([ModalOverlay]): [state]'s field, focused, labelled [label] with [hint] while empty, [suffix] after
 * the text (a unit), monospace for a pattern, [inputTransformation] refusing what it can't hold; [error] under it, else
 * [message] (what the setting does); then
 * [leading] (a Reset), [cancelLabel] and [submitLabel]. Submit hands [onSubmit] the text, untrimmed: it closes the form
 * or leaves it open with an [error]. In a single-line field Enter and the keyboard's Done submit too, and Down leaves
 * the field for the buttons; a [multiline] one takes them as text. Back, Escape, a click outside and Cancel run
 * [onCancel]. On TV the keyboard waits for Select, and the remote's arrows leave the field at its ends. Harness names:
 * [fieldProbe], `<probe>.error`, `<probe>.cancel`, [submitProbe].
 */
@Composable
fun TextFieldDialog(
    title: String,
    state: TextFieldState,
    onSubmit: (String) -> Unit,
    onCancel: () -> Unit,
    probe: String,
    label: String? = null,
    hint: String? = null,
    suffix: String? = null,
    error: String? = null,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    inputTransformation: InputTransformation? = null,
    monospace: Boolean = false,
    multiline: Boolean = false,
    submitLabel: String = T.common.save,
    cancelLabel: String = T.common.cancel,
    fieldProbe: String = "$probe.field",
    submitProbe: String = "$probe.save",
    leading: (@Composable () -> Unit)? = null,
    message: String? = null,
) {
    val keyboard = rememberKeyboardOnSelect()
    val focusManager = LocalFocusManager.current
    val field = remember { FocusRequester() }
    val submitFocus = remember { FocusRequester() }
    val submit = { onSubmit(state.text.toString()) }
    ModalOverlay(title, onCancel, initialFocus = field) {
        val textStyle = MaterialTheme.typography.bodyLarge
        OutlinedTextField(
            state = state,
            lineLimits = if (multiline) TextFieldLineLimits.MultiLine(minHeightInLines = 3, maxHeightInLines = 8) else TextFieldLineLimits.SingleLine,
            readOnly = keyboard.readOnly,
            inputTransformation = inputTransformation,
            label = label?.let { { Text(it) } },
            placeholder = hint?.let { { Text(it, maxLines = 1) } },
            suffix = suffix?.let { { Text(it) } },
            isError = error != null,
            textStyle = if (monospace) textStyle.copy(fontFamily = FontFamily.Monospace) else textStyle,
            keyboardOptions = keyboardOptions.copy(imeAction = if (multiline) ImeAction.Default else ImeAction.Done),
            onKeyboardAction = if (multiline) null else { _ -> submit() },
            modifier = Modifier
                .fillMaxWidth()
                .focusRequester(field)
                .then(keyboard.modifier)
                .onPreviewKeyEvent { event ->
                    if (event.type != KeyEventType.KeyDown || multiline) return@onPreviewKeyEvent false
                    when (event.key) {
                        Key.Enter, Key.NumPadEnter -> {
                            submit()
                            true
                        }
                        // A single-line field would move the cursor; Down leaves it for the buttons (D-pad, arrows).
                        Key.DirectionDown -> focusManager.moveFocus(FocusDirection.Down)
                        else -> false
                    }
                }
                .remoteLeavesField(state)
                .inViewAboveKeyboard()
                .layoutProbe(fieldProbe),
        )
        if (error != null) {
            InlineError(error, Modifier.layoutProbe("$probe.error"))
        } else if (message != null) {
            Text(message, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, modifier = Modifier.layoutProbe("$probe.message"))
        }
        OverlayActions(primary = submitFocus) {
            leading?.invoke()
            PlezyButton(cancelLabel, onCancel, Modifier.layoutProbe("$probe.cancel"), style = ButtonStyle.TEXT)
            PlezyButton(submitLabel, { submit() }, Modifier.focusRequester(submitFocus).layoutProbe(submitProbe), style = ButtonStyle.PRIMARY)
        }
    }
}

/**
 * Work the screen waits on ([ModalOverlay]): [title] over Material's loading indicator, and with [onCancel] a focused
 * Cancel that stops it, as Back does. Without [onCancel] nothing closes it but the work's end; a click outside never
 * does. Harness names: [probe], `<probe>.cancel`.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun BusyOverlay(title: String?, onCancel: (() -> Unit)?, probe: String) {
    val cancel = remember { FocusRequester() }
    ModalOverlay(
        title,
        onDismiss = { onCancel?.invoke() },
        modifier = Modifier.layoutProbe(probe, reportsFocus = false),
        initialFocus = if (onCancel != null) cancel else null,
        maxWidth = if (title == null && onCancel == null) 120.dp else 360.dp,
        dismissOnScrim = false,
    ) {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { LoadingIndicator() }
        if (onCancel != null) {
            OverlayActions(primary = cancel) {
                PlezyButton(T.common.cancel, onCancel, Modifier.focusRequester(cancel).layoutProbe("$probe.cancel"), style = ButtonStyle.TEXT)
            }
        }
    }
}
