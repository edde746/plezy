package com.edde746.plezy.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.input.setTextAndPlaceCursorAtEnd
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.settings.SettingCheckOption
import com.edde746.plezy.presentation.settings.SettingChecklistRow
import com.edde746.plezy.presentation.settings.SettingColorRow
import com.edde746.plezy.presentation.settings.SettingNumberRow
import com.edde746.plezy.presentation.settings.SettingTextRow
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowCheckbox
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.TextAndTrailing
import com.edde746.plezy.ui.components.TextFieldDialog
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.focusGrowth
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * A text setting's field over the page ([TextFieldDialog]): the field labelled [SettingTextRow.fieldLabel] with its
 * hint, starting at the stored text (monospace for a pattern), and [validate]'s word on it while typing (the store's
 * [SettingsPageStore.checkText]: a pattern that isn't one). Save, Enter or the keyboard's Done hands the text,
 * untrimmed, to [onSave]: an error it returns shows under the field and the overlay stays open; null closes it. With
 * [SettingTextRow.resetLabel], a leading action fills the field with [onReset]'s default (nothing stored yet), or
 * closes the overlay when [onReset] stored the reset itself (null). On TV the keyboard waits for Select. Harness names:
 * `settings.text.<field|error|reset|cancel|save>`.
 */
@Composable
internal fun TextOverlay(
    row: SettingTextRow,
    onSave: (String) -> String?,
    onReset: () -> String?,
    onDismiss: () -> Unit,
    validate: ((String) -> String?)? = null,
) {
    val text = remember { TextFieldState(row.value) }
    var error by remember { mutableStateOf<String?>(null) }
    OnTextChange(text) { error = validate?.invoke(it) }
    TextFieldDialog(
        row.title,
        text,
        onSubmit = {
            error = onSave(it)
            if (error == null) onDismiss()
        },
        onCancel = onDismiss,
        probe = "settings.text",
        label = row.fieldLabel,
        hint = row.hint,
        error = error,
        keyboardOptions = KeyboardOptions(autoCorrectEnabled = false, keyboardType = KeyboardType.Uri),
        monospace = row.monospace,
        message = row.caption,
        leading = row.resetLabel?.let { reset ->
            {
                PlezyButton(
                    reset,
                    {
                        val default = onReset()
                        if (default == null) {
                            onDismiss()
                        } else {
                            text.setTextAndPlaceCursorAtEnd(default)
                            error = null
                        }
                    },
                    Modifier.layoutProbe("settings.text.reset"),
                    style = ButtonStyle.TEXT,
                )
            }
        },
    )
}

/**
 * A number setting's field over the page ([TextFieldDialog]): the value typed (a number keyboard), labelled with the
 * row's title, its unit after it and its hint under it; [validate]'s word on it while typing (the store's
 * [SettingsPageStore.checkNumber]: not a whole number, out of bounds). Save hands the text to [onSave], whose error
 * keeps the overlay open. Harness names: `settings.number.<field|error|cancel|save>`.
 */
@Composable
internal fun NumberOverlay(row: SettingNumberRow, onSave: (String) -> String?, validate: (String) -> String?, onDismiss: () -> Unit) {
    val text = remember { TextFieldState(row.value.toString()) }
    var error by remember { mutableStateOf<String?>(null) }
    OnTextChange(text) { error = validate(it) }
    TextFieldDialog(
        row.title,
        text,
        onSubmit = {
            error = onSave(it)
            if (error == null) onDismiss()
        },
        onCancel = onDismiss,
        probe = "settings.number",
        label = row.title,
        hint = row.hint,
        suffix = row.suffix,
        error = error,
        keyboardOptions = KeyboardOptions(autoCorrectEnabled = false, keyboardType = KeyboardType.Number),
    )
}

/**
 * A checklist's sheet ([PlezySheet], on TV the side panel): its options as one group of tick-box rows, a locked one
 * ticked and disabled (focus passes over it), the first editable one focused, Save at the foot. Save hands [onSave] the
 * ticked ids in the options' order; Back and the scrim store nothing. Harness names:
 * `settings.checklist.option.<i>`, `settings.checklist.save`.
 */
@Composable
internal fun ChecklistSheet(row: SettingChecklistRow, onSave: (List<String>) -> Unit, onDismiss: () -> Unit) {
    var checked by remember { mutableStateOf(row.options.filter { it.checked || it.locked }.map(SettingCheckOption::id).toSet()) }
    val first = row.options.indexOfFirst { !it.locked }
    val focus = remember { FocusRequester() }
    PlezySheet(onDismiss = onDismiss, title = row.title, initialFocus = focus.takeIf { first >= 0 }, probe = "settings.checklist") {
        Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(vertical = 4.dp)) {
            RowGroup {
                row.options.forEachIndexed { index, option ->
                    val on = option.locked || option.id in checked
                    PlezyToggleSurface(
                        on,
                        { checked = if (it) checked + option.id else checked - option.id },
                        Modifier
                            .fillMaxWidth()
                            .then(if (index == first) Modifier.focusRequester(focus) else Modifier)
                            .layoutProbe("settings.checklist.option.$index"),
                        shape = groupShape(index, row.options.size),
                        enabled = !option.locked,
                        role = androidx.compose.ui.semantics.Role.Checkbox,
                    ) {
                        Row(
                            Modifier.heightIn(min = 56.dp).padding(start = 16.dp, end = 12.dp, top = 10.dp, bottom = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            TextAndTrailing(text = { RowText(option.label, option.subtitle) }, trailing = { RowCheckbox(on) }, modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
        }
        OverlayActions {
            PlezyButton(
                T.common.save,
                {
                    onSave(row.options.filter { it.locked || it.id in checked }.map(SettingCheckOption::id))
                    onDismiss()
                },
                Modifier.layoutProbe("settings.checklist.save"),
                style = ButtonStyle.PRIMARY,
            )
        }
    }
}

/**
 * A colour setting's sheet ([PlezySheet], on TV the side panel): the colour beside its code as six hex digits to type
 * (six typed digits move the sliders, which rewrite it in upper case), then hue, saturation and brightness sliders
 * ([ColorSliders]), Save at the foot. Save stores `#RRGGBB` (upper case, no alpha) through [onSave] when the colour
 * changed; an unchanged colour writes nothing. Harness names: `settings.color.<hex|save>`.
 */
@Composable
internal fun ColorSheet(row: SettingColorRow, onSave: (String) -> Unit, onDismiss: () -> Unit) {
    val start = remember { Hsv.of(parseHex(row.hex)) }
    var hsv by remember { mutableStateOf(start) }
    val hex = hsv.color().toHex(alpha = false)
    val first = remember { FocusRequester() }
    PlezySheet(onDismiss = onDismiss, title = row.title, initialFocus = first, probe = "settings.color") {
        Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(vertical = 4.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                ColorDot(hsv.color(), 48)
                HexField(hex, Modifier.weight(1f).focusRequester(first)) { hsv = Hsv.of(it) }
            }
            ColorSliders(hsv, onChange = { hsv = it }, opacity = false)
        }
        OverlayActions {
            PlezyButton(
                T.common.save,
                {
                    if (hex != parseHex(row.hex).toHex(alpha = false)) onSave(hex)
                    onDismiss()
                },
                Modifier.layoutProbe("settings.color.save"),
                style = ButtonStyle.PRIMARY,
            )
        }
    }
}

/** A colour as a circle [size] dp wide, ringed with the hairline so a colour like the background still shows. */
@Composable
internal fun ColorDot(color: Color, size: Int, modifier: Modifier = Modifier) {
    Box(modifier.size(size.dp).background(color, CircleShape).border(1.dp, PlezyColors.Hairline, CircleShape))
}

/**
 * [hex] (`#RRGGBB`) as an editable field of six hex digits after a fixed `#`; six typed digits are a colour for
 * [onColor]. A change of [hex] from elsewhere rewrites the field. On TV the keyboard waits for Select, and Up and Down
 * leave the field.
 */
@Composable
private fun HexField(hex: String, modifier: Modifier, onColor: (Color) -> Unit) {
    val keyboard = rememberKeyboardOnSelect()
    val text = remember { TextFieldState(hex.removePrefix("#")) }
    LaunchedEffect(hex) {
        val typed = text.text.toString()
        if (typed.length != 6 || !typed.equals(hex.removePrefix("#"), ignoreCase = true)) text.setTextAndPlaceCursorAtEnd(hex.removePrefix("#"))
    }
    OutlinedTextField(
        state = text,
        lineLimits = TextFieldLineLimits.SingleLine,
        readOnly = keyboard.readOnly,
        label = { Text(T.accessibility.hexColor) },
        prefix = { Text("#") },
        inputTransformation = {
            if (asCharSequence().length > 6 || asCharSequence().any { it.digitToIntOrNull(16) == null }) revertAllChanges()
        },
        textStyle = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.Monospace),
        keyboardOptions = KeyboardOptions(autoCorrectEnabled = false, capitalization = KeyboardCapitalization.Characters, keyboardType = KeyboardType.Ascii),
        modifier = modifier.then(keyboard.modifier).remoteLeavesField(text).inViewAboveKeyboard().layoutProbe("settings.color.hex"),
    )
    OnTextChange(text) { typed -> if (typed.length == 6) onColor(parseHex(typed)) }
}

/**
 * Hue (0–360°), saturation and brightness (%), and with [opacity] opacity (%), for [hsv]: one group, a row each with
 * its name and value over Material's slider; each move calls [onChange]. Harness names:
 * `settings.hsv.<hue|saturation|brightness|opacity>`.
 */
@Composable
internal fun ColorSliders(hsv: Hsv, onChange: (Hsv) -> Unit, opacity: Boolean) {
    val rows = buildList {
        add(SliderLine(T.accessibility.hue, "${hsv.hue.toInt()}°", hsv.hue, 0f..360f, "hue") { onChange(hsv.copy(hue = it)) })
        add(SliderLine(T.accessibility.saturation, "${(hsv.saturation * 100).toInt()}%", hsv.saturation, 0f..1f, "saturation") { onChange(hsv.copy(saturation = it)) })
        add(SliderLine(T.accessibility.brightness, "${(hsv.value * 100).toInt()}%", hsv.value, 0f..1f, "brightness") { onChange(hsv.copy(value = it)) })
        if (opacity) add(SliderLine(T.themeEditor.opacity, "${(hsv.alpha * 100).toInt()}%", hsv.alpha, 0f..1f, "opacity") { onChange(hsv.copy(alpha = it)) })
    }
    RowGroup {
        rows.forEachIndexed { index, line ->
            Column(Modifier.fillMaxWidth().background(PlezyColors.SurfaceHigh, groupShape(index, rows.size)).padding(start = 16.dp, end = 16.dp, top = 10.dp, bottom = 4.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(line.label, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                    Text(line.value, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.MutedContent)
                }
                PlezySlider(line.current, line.onChange, line.range, steps = 0, label = line.label, modifier = Modifier.layoutProbe("settings.hsv.${line.probe}"))
            }
        }
    }
}

private class SliderLine(
    val label: String,
    val value: String,
    val current: Float,
    val range: ClosedFloatingPointRange<Float>,
    val probe: String,
    val onChange: (Float) -> Unit,
)

/**
 * Material's slider in the theme's colours, which a D-pad moves with Left and Right while Up and Down move focus on
 * (the slider would take them as steps too, and a remote could never leave it). [onChangeFinished]: a drag let go.
 */
@Composable
internal fun PlezySlider(
    value: Float,
    onChange: (Float) -> Unit,
    range: ClosedFloatingPointRange<Float>,
    steps: Int,
    label: String,
    modifier: Modifier = Modifier,
    onChangeFinished: (() -> Unit)? = null,
) {
    val focusManager = LocalFocusManager.current
    val interactions = remember { MutableInteractionSource() }
    Slider(
        value = value.coerceIn(range),
        onValueChange = onChange,
        onValueChangeFinished = onChangeFinished,
        valueRange = range,
        steps = steps,
        interactionSource = interactions,
        colors = SliderDefaults.colors(thumbColor = PlezyColors.Primary, activeTrackColor = PlezyColors.Primary, inactiveTrackColor = PlezyColors.SurfaceHighest),
        modifier = modifier
            .fillMaxWidth()
            .focusGrowth(CircleShape, grows = false)
            .semantics { contentDescription = label }
            .onPreviewKeyEvent { event ->
                val direction = when (event.key) {
                    Key.DirectionUp -> FocusDirection.Up
                    Key.DirectionDown -> FocusDirection.Down
                    else -> return@onPreviewKeyEvent false
                }
                if (event.type == KeyEventType.KeyDown) focusManager.moveFocus(direction)
                true
            },
    )
}

/** A colour as hue (0–360), saturation, value (0–1) and alpha (0–1). */
internal data class Hsv(val hue: Float, val saturation: Float, val value: Float, val alpha: Float = 1f) {
    fun color(): Color = Color.hsv(hue.coerceIn(0f, 360f), saturation.coerceIn(0f, 1f), value.coerceIn(0f, 1f), alpha.coerceIn(0f, 1f))

    companion object {
        fun of(color: Color): Hsv {
            val r = color.red
            val g = color.green
            val b = color.blue
            val max = maxOf(r, g, b)
            val min = minOf(r, g, b)
            val delta = max - min
            val hue = when {
                delta == 0f -> 0f
                max == r -> 60f * (((g - b) / delta).mod(6f))
                max == g -> 60f * ((b - r) / delta + 2f)
                else -> 60f * ((r - g) / delta + 4f)
            }
            return Hsv(hue, if (max == 0f) 0f else delta / max, max, color.alpha)
        }
    }
}

/** `#RRGGBB` or `#AARRGGBB` (the `#` optional) as a colour; anything else black. */
internal fun parseHex(hex: String): Color {
    val digits = hex.removePrefix("#")
    val value = digits.toLongOrNull(16) ?: return Color.Black
    return when (digits.length) {
        6 -> Color(0xFF000000 or value)
        8 -> Color(value)
        else -> Color.Black
    }
}

/** This colour as `#RRGGBB`, or with [alpha] `#AARRGGBB`, upper case. */
internal fun Color.toHex(alpha: Boolean): String {
    val argb = toArgb().toLong() and 0xFFFFFFFF
    return if (alpha) "#" + argb.toString(16).uppercase().padStart(8, '0') else "#" + (argb and 0xFFFFFF).toString(16).uppercase().padStart(6, '0')
}
