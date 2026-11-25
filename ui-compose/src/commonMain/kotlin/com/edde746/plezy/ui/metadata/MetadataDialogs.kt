package com.edde746.plezy.ui.metadata

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.gestures.BringIntoViewSpec
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.input.clearText
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.metadata.EditorDialog
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.metadata.QuickTagStore
import com.edde746.plezy.presentation.metadata.TagEditStore
import com.edde746.plezy.ui.components.BusyOverlay
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.SheetOption
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.focus.inViewAboveKeyboard
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import kotlin.math.floor

/**
 * The release date's picker, 1800 to 2200, on the field's day (else today's month); Save stores the picked day. The
 * card leaves its margin to Material's picker, which needs 360 dp for its week, so a phone shows all seven days; in a
 * window too short for it (a phone in landscape) the card scrolls as a whole.
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
internal fun DateDialog(dialog: EditorDialog.Date, onSave: (Int, Int, Int) -> Unit, onCancel: () -> Unit) {
    val initial = if (dialog.year != null && dialog.month != null && dialog.day != null) {
        epochDay(dialog.year!!, dialog.month!!, dialog.day!!) * MILLIS_PER_DAY
    } else {
        null
    }
    val picker = rememberDatePickerState(initialSelectedDateMillis = initial, yearRange = 1800..2200)
    val saveFocus = remember { FocusRequester() }
    // TV's panel keeps its own margin. The remote can't leave the picker's month for the buttons under it (Down pages
    // to the next month): there the dialog opens on Save, the panel scrolled to it, and Up goes into the month.
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    ModalOverlay(title = null, onDismiss = onCancel, initialFocus = saveFocus.takeIf { tv }, maxWidth = 360.dp, padded = false) {
        // Android TV pivots a focused element to 30 % of its row: Up from Save onto the month's last row would scroll
        // the months half a page. In the picker focus moves the months by whole pages only, past the grid's edge.
        CompositionLocalProvider(LocalBringIntoViewSpec provides WholePages) {
            DatePicker(
                picker,
                Modifier.layoutProbe("metadata.date.picker"),
                title = { Text(dialog.title, Modifier.padding(start = 24.dp, top = 16.dp)) },
                colors = DatePickerDefaults.colors(containerColor = Color.Transparent),
            )
        }
        OverlayActions(if (tv) Modifier else Modifier.padding(start = 24.dp, end = 24.dp, bottom = 24.dp), primary = saveFocus) {
            PlezyButton(dialog.cancelLabel, onCancel, Modifier.layoutProbe("metadata.date.cancel"), style = ButtonStyle.TEXT)
            PlezyButton(
                dialog.saveLabel,
                {
                    picker.selectedDateMillis?.let { millis ->
                        val (y, m, d) = civil(Math.floorDiv(millis, MILLIS_PER_DAY))
                        onSave(y, m, d)
                    }
                },
                Modifier.focusRequester(saveFocus).layoutProbe("metadata.date.save"),
                style = ButtonStyle.PRIMARY,
                enabled = picker.selectedDateMillis != null,
            )
        }
    }
}

/**
 * Scrolling that keeps a pager-like row on whole pages: an element in view stays; one past the view's edge brings in
 * the page it is on (the view's size from where the view is), or, partly in view, comes just inside the edge.
 */
@OptIn(ExperimentalFoundationApi::class)
private object WholePages : BringIntoViewSpec {
    override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float): Float = when {
        offset >= 0f && offset + size <= containerSize -> 0f
        offset >= containerSize || offset + size <= 0f -> floor(offset / containerSize) * containerSize
        offset < 0f -> offset
        else -> offset + size - containerSize
    }
}

/**
 * A choice's options as a sheet of options (a side panel on TV), the selected one checked and focused; Back or the
 * scrim cancels. Harness names `metadata.choice.<index>`.
 */
@Composable
internal fun ChoiceDialog(dialog: EditorDialog.Choice, onChoose: (String) -> Unit, onCancel: () -> Unit) {
    val selected = remember { FocusRequester() }
    val selectedIndex = dialog.options.indexOfFirst { it.value == dialog.selected }
    PlezySheet(onDismiss = onCancel, title = dialog.title, initialFocus = if (selectedIndex >= 0) selected else null, probe = "metadata.choice") {
        Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            dialog.options.forEachIndexed { index, option ->
                SheetOption(
                    option.label,
                    onClick = { onChoose(option.value) },
                    modifier = (if (index == selectedIndex) Modifier.focusRequester(selected) else Modifier).layoutProbe("metadata.choice.$index"),
                    selected = index == selectedIndex,
                )
            }
        }
    }
}

/**
 * A tag list's dialog ([TagEditStore]): the "Add tag" field with its + button (Enter adds too), up to 12 suggestion
 * chips under it (at most 120 dp high), the tags (a press removes one, focus back to the field), Cancel and Save.
 * Down from the field goes to the first chip while any shows; from the chips the D-pad moves on by direction, to the
 * tags and the buttons. Harness names `metadata.tags.<field|add|chip.N|tag.N|cancel|save>`.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TagEditDialog(store: TagEditStore, onSave: () -> Unit, onCancel: () -> Unit) {
    val state by store.state.collectAsState()
    val keyboard = rememberKeyboardOnSelect()
    val field = remember { FocusRequester() }
    val firstChip = remember { FocusRequester() }
    val saveFocus = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current
    val text = remember { TextFieldState() }
    LaunchedEffect(text) {
        snapshotFlow { text.text.toString() }.collect(store::setQuery)
    }
    val add = {
        if (store.add(text.text.toString())) text.clearText()
        field.requestFocus()
    }
    ModalOverlay(title = state.title, onDismiss = onCancel, initialFocus = field, maxWidth = 440.dp) {
        OutlinedTextField(
            state = text,
            label = { Text(state.addTagLabel) },
            lineLimits = TextFieldLineLimits.SingleLine,
            readOnly = keyboard.readOnly,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
            onKeyboardAction = { add() },
            trailingIcon = { PlezyIconButton(PlezyIcons.Add, state.addTagLabel, { add() }, Modifier.layoutProbe("metadata.tags.add")) },
            modifier = Modifier
                .fillMaxWidth()
                .focusRequester(field)
                .then(keyboard.modifier)
                .onPreviewKeyEvent { event ->
                    if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                    when (event.key) {
                        Key.Enter, Key.NumPadEnter -> {
                            add()
                            true
                        }
                        // The chips are the main action here: Down lands on the first (most recent) one.
                        Key.DirectionDown -> if (store.state.value.suggestions.isNotEmpty()) {
                            firstChip.requestFocus()
                            true
                        } else {
                            focusManager.moveFocus(FocusDirection.Down)
                        }
                        else -> false
                    }
                }
                .remoteLeavesField(text)
                .inViewAboveKeyboard()
                .layoutProbe("metadata.tags.field"),
        )
        if (state.suggestions.isNotEmpty()) {
            // Weighted as the tags are: in a window the keyboard has shortened the chips scroll, and the buttons keep
            // their height.
            FlowRow(
                Modifier.fillMaxWidth().weight(1f, fill = false).heightIn(max = 120.dp).verticalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                state.suggestions.forEachIndexed { index, suggestion ->
                    PlezyChip(
                        label = suggestion,
                        selected = false,
                        onClick = {
                            store.add(suggestion)
                            field.requestFocus()
                        },
                        modifier = (if (index == 0) Modifier.focusRequester(firstChip) else Modifier).layoutProbe("metadata.tags.chip.$index"),
                        leadingIcon = PlezyIcons.Add,
                        contentLabel = true,
                    )
                }
            }
        }
        if (state.tags.isNotEmpty()) {
            Column(
                Modifier.weight(1f, fill = false).heightIn(max = 300.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                state.tags.forEachIndexed { index, tag ->
                    GroupRow(
                        title = tag,
                        onClick = {
                            store.remove(index)
                            field.requestFocus()
                        },
                        modifier = Modifier.layoutProbe("metadata.tags.tag.$index"),
                        shape = groupShape(index, state.tags.size),
                        trailing = { Icon(PlezyIcons.Close, contentDescription = null) },
                    )
                }
            }
        }
        OverlayActions(primary = saveFocus) {
            PlezyButton(state.cancelLabel, onCancel, Modifier.layoutProbe("metadata.tags.cancel"), style = ButtonStyle.TEXT)
            PlezyButton(state.saveLabel, onSave, Modifier.focusRequester(saveFocus).layoutProbe("metadata.tags.save"), style = ButtonStyle.PRIMARY)
        }
    }
}

/**
 * Quick Tag of an item's menu ([com.edde746.plezy.presentation.metadata.MetadataEditing.open]): a blocking spinner
 * while it loads or saves, the Label dialog between; [onDone] once it is over.
 */
@Composable
fun QuickTagHost(store: QuickTagStore, onDone: () -> Unit) {
    val state by store.state.collectAsState()
    LaunchedEffect(state.done) { if (state.done) onDone() }
    if (state.busy) BusyOverlay(null, null, "metadata.quickTag.busy")
    state.tags?.let { TagEditDialog(it, onSave = store::save, onCancel = store::cancel) }
}

private const val MILLIS_PER_DAY = 86_400_000L

/** Days since 1970-01-01 of a proleptic Gregorian date (the date picker's UTC midnight). */
internal fun epochDay(year: Int, month: Int, day: Int): Long {
    val y = (if (month <= 2) year - 1 else year).toLong()
    val era = Math.floorDiv(y, 400L)
    val yoe = y - era * 400
    val mp = (month + 9) % 12
    val doy = (153 * mp + 2) / 5 + day - 1
    val doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
    return era * 146_097 + doe - 719_468
}

/** The date of [epochDay] ([epochDay]'s inverse) as (year, month, day). */
internal fun civil(epochDay: Long): Triple<Int, Int, Int> {
    val z = epochDay + 719_468
    val era = Math.floorDiv(z, 146_097L)
    val doe = z - era * 146_097
    val yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
    val doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
    val mp = (5 * doy + 2) / 153
    val day = (doy - (153 * mp + 2) / 5 + 1).toInt()
    val month = (if (mp < 10) mp + 3 else mp - 9).toInt()
    val year = (yoe + era * 400 + if (month <= 2) 1 else 0).toInt()
    return Triple(year, month, day)
}
