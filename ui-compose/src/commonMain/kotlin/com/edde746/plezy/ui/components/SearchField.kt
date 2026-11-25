package com.edde746.plezy.ui.components

import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.clearText
import androidx.compose.foundation.text.input.rememberTextFieldState
import androidx.compose.foundation.text.input.setTextAndPlaceCursorAtEnd
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onInterceptKeyBeforeSoftKeyboard
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.LocalKeyboardHeight
import com.edde746.plezy.ui.navigation.LocalSideNavigation
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The search field (outlined, round, the search icon, [hint] while empty), the loading indicator at its end
 * while [searching], and over its end once it holds text the button that clears it (and gives the field focus back).
 * It starts from [text], tells [onText] each edit, and takes [text] when it changes to something it didn't send.
 * The keyboard's Search and Enter ask [onSubmit], whose true (the results for the text already show) moves focus down
 * to them. On TV so does Back putting the keyboard away: the typing is done, so a search still waiting out its pause
 * after the last key runs at once. [fieldModifier] goes on the text field itself (its focus), [modifier] on the whole.
 * While the on-screen keyboard is up in a short window (a phone in landscape, [DENSE_BELOW] tall) it is compact: one
 * line as tall as its icons' touch targets, no padding above and below its text, so the results keep the room above
 * the keyboard.
 *
 * The button is drawn over the field, not inside it: the field's key handling sees every key of what is inside its
 * decoration (Select raising the TV keyboard, Android's own D-pad handling of text fields), so a remote couldn't press
 * it there; the arrow toward it at the text's end reaches it, the opposite arrow goes back. Down leaves the field for
 * what is under it. On an Android TV the keyboard waits for Select; a desktop in TV mode types into it once it has
 * focus. Back while it has focus (the keyboard down) empties it; empty, beside a rail, Back moves to the rail. Harness
 * names: [probe], [clearProbe].
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class, ExperimentalComposeUiApi::class)
@Composable
internal fun SearchField(
    text: String,
    hint: String,
    onText: (String) -> Unit,
    onSubmit: () -> Boolean,
    probe: String,
    clearProbe: String,
    modifier: Modifier = Modifier,
    fieldModifier: Modifier = Modifier,
    searching: Boolean = false,
) {
    val field = rememberTextFieldState(text)
    // What the field last handed out: a text that differs was set from elsewhere.
    val sent = remember { arrayOf(text) }
    OnTextChange(field) {
        sent[0] = it
        onText(it)
    }
    LaunchedEffect(text) {
        if (text != sent[0]) {
            sent[0] = text
            field.setTextAndPlaceCursorAtEnd(text)
        }
    }
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    val keyboard = rememberKeyboardOnSelect()
    val dimens = LocalPlezyDimens.current
    val focusManager = LocalFocusManager.current
    val rail = LocalSideNavigation.current != null
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val dense = LocalKeyboardHeight.current() > 0 && LocalWindowSize.current.value.height < DENSE_BELOW
    val towardsRail = if (rtl) FocusDirection.Right else FocusDirection.Left
    val fieldFocus = remember { FocusRequester() }
    val clearFocus = remember { FocusRequester() }
    val submit = { if (onSubmit()) focusManager.moveFocus(FocusDirection.Down) }
    SystemBackHandler(enabled = focused && (field.text.isNotEmpty() || rail)) {
        if (field.text.isNotEmpty()) field.clearText() else focusManager.moveFocus(towardsRail)
    }
    Box(modifier.fillMaxWidth()) {
        Box(Modifier.contentColumn()) {
            OutlinedTextField(
                state = field,
                modifier = Modifier
                    .fillMaxWidth()
                    .then(if (dense) Modifier.height(DENSE_HEIGHT) else Modifier)
                    .then(fieldModifier)
                    .focusRequester(fieldFocus)
                    .then(keyboard.modifier)
                    // The keyboard takes Back to put itself away; the app sees the press first.
                    .onInterceptKeyBeforeSoftKeyboard { event ->
                        if (event.key == Key.Back && event.type == KeyEventType.KeyDown && keyboard.keyboardUp) submit()
                        false
                    }
                    .onPreviewKeyEvent { event ->
                        if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                        when (event.key) {
                            Key.Enter, Key.NumPadEnter -> {
                                submit()
                                true
                            }
                            // A single-line field would move the cursor; Down leaves it for what is under it (D-pad).
                            Key.DirectionDown -> focusManager.moveFocus(FocusDirection.Down)
                            // At the text's end, the arrow toward the clear button goes to it (a remote has no Tab).
                            // Focus search doesn't find it: its bounds lie inside the field's.
                            Key.DirectionRight, Key.DirectionLeft -> {
                                val towardClear = if (rtl) Key.DirectionLeft else Key.DirectionRight
                                val atEnd = field.selection.collapsed && field.selection.end == field.text.length
                                if (event.key == towardClear && field.text.isNotEmpty() && atEnd) clearFocus.requestFocus() else false
                            }
                            else -> false
                        }
                    }
                    .remoteLeavesField(field)
                    .layoutProbe(probe),
                placeholder = { Text(hint, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                leadingIcon = { Icon(PlezyIcons.Search, contentDescription = null) },
                trailingIcon = if (field.text.isEmpty() && !searching) {
                    null
                } else {
                    {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (searching) LoadingIndicator(Modifier.size(LoadingIndicatorSize))
                            // The clear button's room: the button is drawn over it.
                            if (field.text.isNotEmpty()) Spacer(Modifier.padding(end = 4.dp).size(dimens.iconButtonSize))
                        }
                    }
                },
                lineLimits = TextFieldLineLimits.SingleLine,
                readOnly = keyboard.readOnly,
                shape = CircleShape,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = PlezyColors.Primary,
                    unfocusedBorderColor = PlezyColors.TextFaint,
                    cursorColor = PlezyColors.Primary,
                ),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                onKeyboardAction = { default -> if (onSubmit()) focusManager.moveFocus(FocusDirection.Down) else default() },
                interactionSource = interactions,
                contentPadding = if (dense) OutlinedTextFieldDefaults.contentPadding(top = 0.dp, bottom = 0.dp) else OutlinedTextFieldDefaults.contentPadding(),
            )
            if (field.text.isNotEmpty()) {
                // Where the field puts its trailing slot (material3's text field layout): at its end, centred.
                Box(Modifier.align(Alignment.CenterEnd).minimumInteractiveComponentSize(), contentAlignment = Alignment.Center) {
                    // The field's trailing icon colour.
                    CompositionLocalProvider(LocalContentColor provides MaterialTheme.colorScheme.onSurfaceVariant) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (searching) Spacer(Modifier.size(LoadingIndicatorSize))
                            PlezyIconButton(
                                PlezyIcons.Close,
                                T.common.clear,
                                {
                                    field.clearText()
                                    fieldFocus.requestFocus()
                                },
                                // The arrow back goes to the field: focus search doesn't count the field, which
                                // contains the button, as beside it.
                                Modifier
                                    .padding(end = 4.dp)
                                    .focusRequester(clearFocus)
                                    .focusProperties { start = fieldFocus }
                                    .layoutProbe(clearProbe),
                                style = IconButtonStyle.PLAIN,
                            )
                        }
                    }
                }
            }
        }
    }
}

/** The loading indicator's size in the field's trailing slot, and the room the clear button keeps for it. */
private val LoadingIndicatorSize = 28.dp

/** A window shorter than this (a phone in landscape) takes the compact field while the keyboard is up. */
private val DENSE_BELOW = 480.dp

/** The compact field's height: its icons' touch targets. */
private val DENSE_HEIGHT = 48.dp
