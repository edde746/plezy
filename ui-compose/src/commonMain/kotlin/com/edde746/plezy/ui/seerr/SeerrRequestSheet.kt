package com.edde746.plezy.ui.seerr

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextOverflow
import com.edde746.plezy.ui.focus.FocusInto
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.seerr.SeerrAdvancedSection
import com.edde746.plezy.presentation.seerr.SeerrPicker
import com.edde746.plezy.presentation.seerr.SeerrPickerKind
import com.edde746.plezy.presentation.seerr.SeerrRequestBody
import com.edde746.plezy.presentation.seerr.SeerrRequestFocusTarget
import com.edde746.plezy.presentation.seerr.SeerrRequestUiState
import com.edde746.plezy.presentation.seerr.SeerrSeasonSection
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ChoiceMenu
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.InlineError
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowCheckbox
import com.edde746.plezy.ui.components.RowSwitch
import androidx.compose.ui.graphics.Shape
import com.edde746.plezy.ui.components.Badge
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.TextAndTrailing
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.settings.RowText
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.onFocusedBoundsChanged
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.runtime.snapshotFlow
import kotlinx.coroutines.flow.first
import kotlin.math.roundToInt
import androidx.compose.ui.platform.LocalDensity
import com.edde746.plezy.ui.components.hidesRowsAbove
import com.edde746.plezy.ui.components.hidesRowsBelow
import com.edde746.plezy.ui.components.scrollEdgeFades

/** What the Seerr request sheet asks of its store. */
class SeerrRequestIntents(
    val retry: () -> Unit,
    val setSeasonSelected: (seasonNumber: Int, selected: Boolean) -> Unit,
    val setAllSeasons: (Boolean) -> Unit,
    val set4k: (Boolean) -> Unit,
    val select: (SeerrPickerKind, optionId: Int) -> Unit,
    val toggleTagsExpanded: () -> Unit,
    val setTagSelected: (tagId: Int, selected: Boolean) -> Unit,
    val submit: () -> Unit,
)

/**
 * The Seerr request sheet of [route] over the screen it was asked from. Once the store closes it (submitted, the
 * permission gone, the account changed) it leaves the stack and hands its message, and whether it is an error, to
 * [onNotice] for the screen beneath.
 */
@Composable
fun SeerrRequestSheet(app: AppSession, route: Route.SeerrRequest, onNotice: (text: String, isError: Boolean) -> Unit) {
    val store = remember(app, route) { app.seerrRequest(route) } ?: return
    val state by store.state.collectAsState()
    LaunchedEffect(state.closed) {
        val closed = state.closed ?: return@LaunchedEffect
        closed.message?.let { onNotice(it, closed.isError) }
        app.navigator.back()
    }
    val intents = remember(store) {
        SeerrRequestIntents(
            retry = store::retry,
            setSeasonSelected = store::setSeasonSelected,
            setAllSeasons = store::setAllSeasons,
            set4k = store::set4k,
            select = store::select,
            toggleTagsExpanded = store::toggleTagsExpanded,
            setTagSelected = store::setTagSelected,
            submit = store::submit,
        )
    }
    SeerrRequestContent(state, intents, onDismiss = { app.navigator.back() })
}

/**
 * The request sheet ([PlezySheet] titled "Request", on TV the side panel): the item's title, then the loading
 * indicator, the load failure with Retry (focused), "nothing to request" beside a check mark with Close (focused), or
 * the form as settings groups: the seasons (All seasons, then each season with its tick box; one Seerr already has or
 * is processing shows that state instead, disabled), Request in 4K with its switch, the advanced pickers (each a row
 * opening its options in a [ChoiceMenu]) and tags; the inline error, and Request at the sheet's foot (a spinner in its
 * icon's place, its label kept, while it submits). Harness names: `seerr.request.*`.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class, ExperimentalFoundationApi::class)
@Composable
fun SeerrRequestContent(state: SeerrRequestUiState, intents: SeerrRequestIntents, onDismiss: () -> Unit) {
    val retry = remember { FocusRequester() }
    val submit = remember { FocusRequester() }
    val firstSeason = remember { FocusRequester() }
    val close = remember { FocusRequester() }
    val scroll = rememberScrollState()
    // The form's content and its focused control, to find that control's foot in the form.
    var form by remember { mutableStateOf<LayoutCoordinates?>(null) }
    var focused by remember { mutableStateOf<LayoutCoordinates?>(null) }
    val edge = with(LocalDensity.current) { FormPadding.roundToPx() }
    PlezySheet(onDismiss = onDismiss, title = state.heading, probe = "seerr.request") {
        // A row cut at the form's foot or top fades into the sheet, so it reads as more to scroll rather than clipped.
        Column(
            Modifier.fillMaxWidth().weight(1f, fill = false)
                .scrollEdgeFades(above = { scroll.hidesRowsAbove(edge) }, below = { scroll.hidesRowsBelow(edge) })
                .verticalScroll(scroll)
                .onGloballyPositioned { form = it }
                .onFocusedBoundsChanged { focused = it }
                .padding(vertical = FormPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(state.title, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, maxLines = 2, overflow = TextOverflow.Ellipsis)
            when (val body = state.body) {
                SeerrRequestBody.Loading -> Box(Modifier.fillMaxWidth().padding(vertical = 32.dp), contentAlignment = Alignment.Center) { LoadingIndicator(Modifier.size(40.dp)) }
                is SeerrRequestBody.LoadFailed -> {
                    Text(body.message, style = MaterialTheme.typography.bodyMedium)
                    PlezyButton(body.retryLabel, intents.retry, Modifier.focusRequester(retry).layoutProbe("seerr.request.retry"))
                    LaunchedEffect(Unit) { retry.requestFocus() }
                }
                is SeerrRequestBody.NothingToRequest -> Row(
                    Modifier.padding(vertical = 16.dp).layoutProbe("seerr.request.nothing", reportsFocus = false),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(PlezyIcons.CheckCircle, contentDescription = null)
                    Spacer(Modifier.width(10.dp))
                    Text(body.message, style = MaterialTheme.typography.bodyMedium)
                }
                is SeerrRequestBody.Form -> {
                    body.seasons?.let { Seasons(it, enabled = !body.submitting, intents, firstSeason, body.submitJumpSeason, submit) }
                    body.request4k?.let { on ->
                        PlezyToggleSurface(on, intents.set4k, Modifier.fillMaxWidth().layoutProbe("seerr.request.4k"), shape = MaterialTheme.shapes.large, enabled = !body.submitting) {
                            RowLine(body.request4kLabel, null) { RowSwitch(on, enabled = !body.submitting) }
                        }
                    }
                    body.advanced?.let { Advanced(it, enabled = !body.submitting, intents) }
                    body.error?.let { InlineError(it) }
                    // The form arrives after the sheet has opened on its loading state: a remote starts on All
                    // seasons, else on Request.
                    FocusInto(if (body.seasons != null) firstSeason else submit, Unit)
                }
            }
        }
        when (val body = state.body) {
            is SeerrRequestBody.NothingToRequest -> {
                OverlayActions {
                    PlezyButton(T.common.close, onDismiss, Modifier.focusRequester(close).layoutProbe("seerr.request.close"), style = ButtonStyle.PRIMARY)
                }
                FocusInto(close, Unit)
            }
            // While it sends, Request keeps its label and focus, a spinner in its icon's place; the store ignores presses.
            is SeerrRequestBody.Form -> OverlayActions(primary = submit) {
                PlezyButton(
                    body.submitLabel,
                    intents.submit,
                    Modifier.focusRequester(submit).layoutProbe("seerr.request.submit"),
                    style = ButtonStyle.PRIMARY,
                    icon = PlezyIcons.Add,
                    enabled = body.canSubmit || body.submitting,
                    busy = body.submitting,
                )
            }
            else -> Unit
        }
    }
    LaunchedEffect(state.refocus) {
        when (state.refocus?.target) {
            SeerrRequestFocusTarget.SUBMIT -> submit.requestFocus()
            SeerrRequestFocusTarget.FIRST_SEASON -> firstSeason.requestFocus()
            null -> Unit
        }
    }
    // The form's first focus brings its row into view with room around it, which scrolled the opening form past the
    // title and the Seasons heading: once it has, the form goes back as far towards its top as keeps that row whole.
    var opened by remember { mutableStateOf(false) }
    LaunchedEffect(focused != null) {
        if (opened || focused == null) return@LaunchedEffect
        opened = true
        repeat(2) { withFrameNanos {} }
        snapshotFlow { scroll.isScrollInProgress }.first { !it }
        val content = form ?: return@LaunchedEffect
        val row = focused?.takeIf { it.isAttached } ?: return@LaunchedEffect
        val foot = content.localBoundingBoxOf(row, clipBounds = false).bottom
        scroll.scrollTo((foot - scroll.viewportSize).roundToInt().coerceIn(0, scroll.value))
    }
}

/** The form's room above and below its rows inside its scrolling. */
private val FormPadding = 4.dp

/**
 * The seasons as one group under its heading; [first] sits on All seasons, the group's first row. Down from the [jump]
 * season goes straight to the Request button ([submit]).
 */
@Composable
private fun Seasons(section: SeerrSeasonSection, enabled: Boolean, intents: SeerrRequestIntents, first: FocusRequester, jump: Int?, submit: FocusRequester) {
    val count = section.rows.size + 1
    Column {
        GroupHeader(section.heading, Modifier.padding(top = 0.dp))
        RowGroup {
            CheckRow(
                section.allLabel,
                null,
                section.allSelected,
                enabled,
                intents.setAllSeasons,
                groupShape(0, count),
                Modifier.focusRequester(first).layoutProbe("seerr.request.allSeasons"),
            )
            section.rows.forEachIndexed { index, row ->
                val toSubmit = if (row.seasonNumber == jump) {
                    Modifier.onPreviewKeyEvent { it.type == KeyEventType.KeyDown && it.key == Key.DirectionDown && submit.requestFocus() }
                } else {
                    Modifier
                }
                CheckRow(
                    row.title,
                    row.subtitle,
                    row.checked,
                    enabled && row.enabled,
                    { intents.setSeasonSelected(row.seasonNumber, it) },
                    groupShape(index + 1, count),
                    toSubmit.layoutProbe("seerr.request.season.${row.seasonNumber}"),
                    blocked = row.blockedLabel,
                )
            }
        }
    }
}

/** The advanced options as one group under its heading (a spinner beside it while they load), then the anime note. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun Advanced(section: SeerrAdvancedSection, enabled: Boolean, intents: SeerrRequestIntents) {
    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            GroupHeader(section.heading)
            if (section.loading) {
                Spacer(Modifier.width(10.dp))
                LoadingIndicator(Modifier.size(14.dp))
            }
        }
        val tags = section.tags
        val tagRows = if (tags != null && tags.expanded) tags.options.size else 0
        val count = section.pickers.size + (if (tags != null) 1 else 0) + tagRows
        RowGroup {
            section.pickers.forEachIndexed { index, picker -> Picker(picker, enabled, intents.select, groupShape(index, count)) }
            if (tags != null) {
                val at = section.pickers.size
                GroupRow(
                    tags.label,
                    onClick = intents.toggleTagsExpanded.takeIf { enabled },
                    modifier = Modifier.layoutProbe("seerr.request.tags"),
                    shape = groupShape(at, count),
                    subtitle = tags.summary,
                    trailing = { Icon(PlezyIcons.ArrowDropDown, contentDescription = null, Modifier.rotate(if (tags.expanded) 180f else 0f)) },
                )
                if (tags.expanded) {
                    tags.options.forEachIndexed { index, tag ->
                        CheckRow(tag.label, null, tag.selected, enabled, { intents.setTagSelected(tag.id, it) }, groupShape(at + 1 + index, count))
                    }
                }
            }
        }
    }
    section.animeNote?.let {
        Text(it, Modifier.padding(horizontal = 16.dp), style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
    }
}

/** A picker's row: its label and current value, opening its options in a [ChoiceMenu]. */
@Composable
private fun Picker(picker: SeerrPicker, enabled: Boolean, select: (SeerrPickerKind, Int) -> Unit, shape: Shape) {
    var open by remember { mutableStateOf(false) }
    Box {
        GroupRow(
            picker.label,
            onClick = { open = true }.takeIf { enabled },
            modifier = Modifier.layoutProbe("seerr.request.picker.${picker.kind.name.lowercase()}"),
            shape = shape,
            value = picker.value,
            trailing = { Icon(PlezyIcons.ArrowDropDown, contentDescription = null, tint = PlezyColors.MutedContent) },
        )
        ChoiceMenu(
            expanded = open,
            onDismiss = { open = false },
            title = picker.label,
            choices = picker.options.map { MenuChoice(it.label, it.selected) },
            onPick = { select(picker.kind, picker.options[it].id) },
            probe = "seerr.request.options",
        )
    }
}

/**
 * A tick-box row of a group, in [shape]: [label] (with [subtitle]) and its tick box; for a season Seerr already has or
 * is processing, a plain row with that state ([blocked]) in the box's place, which takes no press.
 */
@Composable
private fun CheckRow(
    label: String,
    subtitle: String?,
    checked: Boolean,
    enabled: Boolean,
    onChange: (Boolean) -> Unit,
    shape: Shape,
    modifier: Modifier = Modifier,
    blocked: String? = null,
) {
    if (blocked != null) {
        GroupRow(label, onClick = null, modifier = modifier, shape = shape, subtitle = subtitle, trailing = { Badge(blocked) })
        return
    }
    PlezyToggleSurface(checked, onChange, modifier.fillMaxWidth(), shape = shape, enabled = enabled, role = Role.Checkbox) {
        RowLine(label, subtitle) { RowCheckbox(checked) }
    }
}

/** A row's text and what trails it, as a settings row lays them out. */
@Composable
private fun RowLine(label: String, subtitle: String?, trailing: @Composable () -> Unit) {
    Row(Modifier.heightIn(min = 56.dp).padding(start = 16.dp, end = 12.dp, top = 10.dp, bottom = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        TextAndTrailing(text = { RowText(label, subtitle) }, trailing = trailing, modifier = Modifier.weight(1f))
    }
}
