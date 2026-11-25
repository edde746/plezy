package com.edde746.plezy.ui.onboarding

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.keyframes
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.onboarding.PinPrompter
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The PIN the app is asking for ([PinPrompter.request]), drawn once over everything while there is one: a [PinPad] in a
 * dialog, shaking as a new error comes. Four digits answer ([PinPrompter.submit]) at once; Cancel, Back or a click
 * outside cancel. Focus the screen below takes while it shows comes back to the key that had it, so a remote never
 * drives the screen under it.
 *
 * Harness names: `pin.dialog` and [PinPad]'s.
 */
@Composable
fun PinPrompt(prompter: PinPrompter) {
    val request by prompter.request.collectAsState()
    val shown = request ?: return
    // The digits of this request: a new one (the next step, or a retry after a wrong PIN) starts empty.
    var digits by remember(shown.id) { mutableStateOf("") }
    val shake = remember { Animatable(0f) }
    LaunchedEffect(shown.id) {
        if (shown.error == null) return@LaunchedEffect
        shake.snapTo(0f)
        shake.animateTo(0f, keyframes {
            durationMillis = 600
            10f at 120
            -10f at 240
            10f at 360
            -10f at 480
        })
    }
    val first = remember { FocusRequester() }
    ModalOverlay(
        title = null,
        onDismiss = prompter::cancel,
        modifier = Modifier.graphicsLayer { translationX = shake.value * density }.layoutProbe("pin.dialog", reportsFocus = false),
        initialFocus = first,
        maxWidth = if (pinPadBeside()) 720.dp else 400.dp,
    ) {
        PinPad(
            title = shown.title,
            entered = digits.length,
            length = PIN_LENGTH,
            message = shown.error,
            first = first,
            onDigit = { digit ->
                if (digits.length < PIN_LENGTH) {
                    digits += digit
                    if (digits.length == PIN_LENGTH) prompter.submit(digits)
                }
            },
            onBackspace = { digits = digits.dropLast(1) },
            onCancel = prompter::cancel,
            header = { Icon(PlezyIcons.Lock, contentDescription = null, Modifier.size(28.dp), tint = PlezyColors.Primary) },
        )
    }
}

private const val PIN_LENGTH = 4

/**
 * A four-digit PIN pad: [header], [title], one dot per digit with [entered] filled, [message] (a wrong PIN, a
 * mismatch), digits 1–9 then 0 and backspace, and Cancel. The keyboard's digits, numpad and Backspace type while the pad
 * has focus (desktop keyboards, remotes with number keys); the arrows walk the keys and Select or Enter presses the
 * focused one once, however long it is held. The keys take focus at 1 ([first]); focus taken from the pad while it shows
 * comes back to the key that had it.
 *
 * Harness names: `pin.dots`, `pin.message`, `pin.digit.<0-9>`, `pin.backspace`, `pin.cancel`.
 */
@Composable
fun PinPad(
    title: String,
    entered: Int,
    length: Int,
    message: String?,
    first: FocusRequester,
    onDigit: (Int) -> Unit,
    onBackspace: () -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier,
    header: (@Composable () -> Unit)? = null,
) {
    val keySize = if (LocalWindowLayout.current.formFactor == FormFactor.TV) 76.dp else 64.dp
    val keys = remember { (0..9).associateWith { if (it == 1) first else FocusRequester() } }
    val cancelFocus = remember { FocusRequester() }
    val beside = pinPadBeside()
    var lastFocused by remember { mutableStateOf(1) }
    var hadFocus by remember { mutableStateOf(false) }
    var lost by remember { mutableStateOf(false) }
    LaunchedEffect(lost) {
        if (!lost) return@LaunchedEffect
        // A frame later, so focus passing between the pad's own controls (a key to Cancel) is left alone.
        withFrameNanos { }
        if (!hadFocus) keys.getValue(lastFocused).requestFocus()
        lost = false
    }
    val outer = modifier
        .fillMaxWidth()
        .onFocusChanged {
            if (hadFocus && !it.hasFocus) lost = true
            hadFocus = it.hasFocus
        }
        .onPreviewKeyEvent { event ->
            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
            val digit = digitOf(event.key)
            when {
                digit != null -> onDigit(digit)
                event.key == Key.Backspace -> onBackspace()
                else -> return@onPreviewKeyEvent false
            }
            true
        }
    val heading: @Composable () -> Unit = {
        header?.invoke()
        Text(title, style = MaterialTheme.typography.headlineSmall, textAlign = TextAlign.Center)
        Row(Modifier.layoutProbe("pin.dots", reportsFocus = false), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            repeat(length) { index ->
                Box(Modifier.size(14.dp).background(if (index < entered) MaterialTheme.colorScheme.onSurface else PlezyColors.SurfaceHighest, CircleShape))
            }
        }
        // Beside the keys the column is narrow: room for a wrapped error is kept, so neither the title nor Cancel moves.
        Text(
            message.orEmpty(),
            Modifier.heightIn(min = 24.dp).layoutProbe("pin.message", reportsFocus = false).semantics { liveRegion = LiveRegionMode.Polite },
            style = MaterialTheme.typography.bodyLarge,
            color = PlezyColors.Error,
            textAlign = TextAlign.Center,
            minLines = if (beside) 3 else 1,
        )
    }
    val keypad: @Composable () -> Unit = {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            for (row in DIGIT_ROWS) {
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    for (digit in row) DigitKey(digit, keySize, onDigit, keys.getValue(digit), if (beside && digit == row.first()) cancelFocus else null) { lastFocused = digit }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Spacer(Modifier.size(keySize))
                DigitKey(0, keySize, onDigit, keys.getValue(0), if (beside) cancelFocus else null) { lastFocused = 0 }
                PlezyIconButton(
                    PlezyIcons.Backspace,
                    contentDescription = T.common.delete,
                    onClick = onBackspace,
                    modifier = Modifier.layoutProbe("pin.backspace"),
                    style = IconButtonStyle.PLAIN,
                    size = keySize,
                )
            }
        }
    }
    val cancel: @Composable () -> Unit = {
        PlezyButton(
            T.common.cancel,
            onCancel,
            Modifier.focusRequester(cancelFocus).focusProperties { if (beside) right = keys.getValue(lastFocused) }.layoutProbe("pin.cancel"),
            style = ButtonStyle.TEXT,
        )
    }
    if (beside) {
        // A short window (a TV, a phone on its side) has no room for the keys under the title: side by side, the title's
        // column taking the width the keys leave, so an error that widens its text never moves the keys.
        Row(outer, horizontalArrangement = Arrangement.spacedBy(24.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                heading()
                cancel()
            }
            keypad()
        }
    } else {
        Column(outer, verticalArrangement = Arrangement.spacedBy(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            heading()
            keypad()
            cancel()
        }
    }
}

/**
 * Whether the keys stand beside the title rather than under it: on TV and in a window too short for the stacked pad in
 * its dialog (about 640 dp).
 */
@Composable
internal fun pinPadBeside(): Boolean =
    LocalWindowLayout.current.formFactor == FormFactor.TV || LocalWindowSize.current.value.height < 640.dp

/** One digit of the pad, a circle [size] wide; Left from it goes to [toCancel] (Cancel beside the keys) when given. */
@Composable
private fun DigitKey(digit: Int, size: Dp, onDigit: (Int) -> Unit, focus: FocusRequester, toCancel: FocusRequester?, onFocused: () -> Unit) {
    PlezySurface(
        onClick = { onDigit(digit) },
        modifier = Modifier.size(size).focusRequester(focus).focusProperties { if (toCancel != null) left = toCancel }.onFocusChanged { if (it.isFocused) onFocused() }.layoutProbe("pin.digit.$digit"),
        shape = CircleShape,
        contentAlignment = Alignment.Center,
        grows = false,
    ) {
        Text(digit.toString(), style = MaterialTheme.typography.headlineSmall)
    }
}

private val DIGIT_ROWS = listOf(listOf(1, 2, 3), listOf(4, 5, 6), listOf(7, 8, 9))

private fun digitOf(key: Key): Int? = when (key) {
    Key.Zero, Key.NumPad0 -> 0
    Key.One, Key.NumPad1 -> 1
    Key.Two, Key.NumPad2 -> 2
    Key.Three, Key.NumPad3 -> 3
    Key.Four, Key.NumPad4 -> 4
    Key.Five, Key.NumPad5 -> 5
    Key.Six, Key.NumPad6 -> 6
    Key.Seven, Key.NumPad7 -> 7
    Key.Eight, Key.NumPad8 -> 8
    Key.Nine, Key.NumPad9 -> 9
    else -> null
}
