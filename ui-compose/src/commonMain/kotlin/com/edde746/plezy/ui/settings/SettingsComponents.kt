package com.edde746.plezy.ui.settings

import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.settings.SettingChoiceRow
import com.edde746.plezy.presentation.settings.SettingToggleRow
import com.edde746.plezy.ui.components.ChoiceMenu
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.GroupGap
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.GroupSpacing
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.HitTarget
import com.edde746.plezy.ui.components.RowCheckbox
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.TextAndTrailing
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.contentColumn
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.components.rememberHitTarget
import com.edde746.plezy.ui.components.reorderHandle
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection

/** A page's explanation under its title: what the settings apply to. */
@Composable
internal fun SettingsNote(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = MaterialTheme.typography.bodyMedium,
        color = PlezyColors.TextMuted,
        modifier = modifier.padding(horizontal = 16.dp, vertical = 4.dp),
    )
}

/**
 * A note among settings rows, not a control (a warning beside the action it concerns): [icon] and [text] in the rows'
 * subtitle style, the icon at the text's size, centred where a [GroupRow]'s icon sits, and the text where its title
 * starts.
 */
@Composable
internal fun NoteLine(text: String, icon: ImageVector, modifier: Modifier = Modifier) {
    val color = PlezyColors.MutedContent
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        Icon(icon, contentDescription = null, Modifier.padding(horizontal = 3.dp).size(16.dp), tint = color)
        Text(text, style = MaterialTheme.typography.bodySmall, color = color)
    }
}

/**
 * One row of a settings group, drawn in the [Shape] its place in the group gives it ([settingsGroup]); [key] keeps
 * the lazy list's item.
 */
internal class SettingsItem(val key: String, val content: @Composable (Shape) -> Unit)

/**
 * A group of settings rows (the ones present: a device lacking a feature has no row for it) under an optional
 * [header], connected ([groupShape]), [GroupSpacing] below what is above it: the header's top padding, or a space as
 * tall without one, so two groups never read as one. An optional [footer] under the rows says, once, what they all do.
 */
internal fun LazyListScope.settingsGroup(key: String, header: String?, rows: List<SettingsItem?>, footer: String? = null) {
    val present = rows.filterNotNull()
    if (present.isEmpty()) return
    if (header != null) item(key = "$key.header") { GroupHeader(header) } else item(key = "$key.space") { Spacer(Modifier.height(GroupSpacing)) }
    present.forEachIndexed { index, row -> item(key = row.key) { row.content(groupShape(index, present.size)) } }
    if (footer != null) item(key = "$key.footer") { SettingsNote(footer, Modifier.layoutProbe("settings.group.$key.footer")) }
}

/**
 * A settings list: the pane's rows in its [contentColumn], centred under the pane's heading, with room at every edge
 * for a focused control's growth (TV; the rows themselves don't grow); scrolled by [state]. Harness name
 * `settings.list`.
 */
@Composable
internal fun SettingsList(modifier: Modifier = Modifier, state: LazyListState = rememberLazyListState(), content: LazyListScope.() -> Unit) {
    val dimens = LocalPlezyDimens.current
    LazyColumn(
        modifier.contentColumn().fillMaxSize().layoutProbe("settings.list", reportsFocus = false),
        state = state,
        contentPadding = PaddingValues(start = dimens.screenPadding, end = dimens.screenPadding, top = dimens.focusReach, bottom = dimens.sectionSpacing),
        verticalArrangement = Arrangement.spacedBy(GroupGap),
        content = content,
    )
}

/** A row that opens something (a list, a page): [title], an optional [subtitle] and [value], and a chevron. */
@Composable
internal fun SettingsLinkRow(
    title: String,
    subtitle: String?,
    value: String?,
    onClick: () -> Unit,
    shape: Shape,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    selected: Boolean = false,
) {
    GroupRow(title, onClick, modifier, shape, subtitle, value, icon, selected = selected, trailing = { Chevron() })
}

/**
 * An on/off setting: the whole row toggles it (click, Enter, the remote's OK); the switch shows the state, beside the
 * text or under it ([TextAndTrailing]); with [tickBox] (an agreement to tick) a tick box instead. [contentTitle]:
 * whether the row's title is content text (a person's: a profile's name), which takes its direction from its first
 * letter ([contentDirection]). Not [SettingToggleRow.enabled], it neither toggles nor takes focus, and shows dimmed.
 */
@Composable
internal fun SettingToggleItem(
    row: SettingToggleRow,
    onChange: (Boolean) -> Unit,
    shape: Shape,
    modifier: Modifier = Modifier,
    contentTitle: Boolean = false,
    tickBox: Boolean = false,
) {
    PlezyToggleSurface(
        row.checked, onChange, modifier.fillMaxWidth(), shape = shape, enabled = row.enabled,
        role = if (tickBox) Role.Checkbox else Role.Switch,
    ) {
        Row(
            Modifier.heightIn(min = 56.dp).padding(start = 16.dp, end = 12.dp, top = 10.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            row.icon?.let { Icon(it.vector, contentDescription = null, Modifier.size(22.dp), tint = PlezyColors.MutedContent) }
            TextAndTrailing(
                text = { RowText(row.title, row.subtitle, contentTitle = contentTitle) },
                trailing = { if (tickBox) RowCheckbox(row.checked) else RowSwitch(row.checked, row.enabled) },
                modifier = Modifier.weight(1f),
            )
        }
    }
}

/**
 * Title and optional subtitle of a settings row, in the row's content colour, each wrapping in full. [contentTitle],
 * [contentSubtitle]: whether [title], [subtitle] is content text (an addon's or a person's), which takes its direction
 * from its first letter ([contentDirection]).
 */
@Composable
internal fun RowText(
    title: String,
    subtitle: String?,
    modifier: Modifier = Modifier,
    contentTitle: Boolean = false,
    contentSubtitle: Boolean = false,
) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        val titleStyle = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium)
        Text(title, style = if (contentTitle) titleStyle.contentDirection() else titleStyle)
        if (subtitle != null) {
            val subtitleStyle = MaterialTheme.typography.bodySmall
            Text(
                subtitle,
                style = if (contentSubtitle) subtitleStyle.contentDirection() else subtitleStyle,
                color = PlezyColors.MutedContent,
            )
        }
    }
}

/**
 * A setting with a fixed list of values: the row shows the value beside its title while short, else under it
 * ([SettingChoiceRow.trailingValue], [SettingChoiceRow.subtitle]), and opens them in a [ChoiceMenu] at the row (on TV
 * the side panel, the selected one focused); picking one calls [onSelect] with its id, dismissing chooses nothing. Not
 * [SettingChoiceRow.enabled], it neither opens nor takes focus.
 * Harness names: [probe], `[probe].option.<i>`.
 */
@Composable
internal fun SettingChoiceItem(
    row: SettingChoiceRow,
    onSelect: (String) -> Unit,
    probe: String,
    shape: Shape,
    modifier: Modifier = Modifier,
) {
    var open by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxWidth()) {
        GroupRow(
            row.title,
            onClick = { open = true },
            modifier = modifier.layoutProbe(probe),
            shape = shape,
            subtitle = row.subtitle,
            value = row.trailingValue,
            icon = row.icon?.vector,
            enabled = row.enabled,
            trailing = { Icon(PlezyIcons.ArrowDropDown, contentDescription = null, tint = PlezyColors.MutedContent) },
        )
        ChoiceMenu(
            expanded = open,
            onDismiss = { open = false },
            title = row.title,
            choices = row.options.map { MenuChoice(it.label, it.selected, detail = it.subtitle) },
            onPick = { onSelect(row.options[it].id) },
            probe = probe,
        )
    }
}

/**
 * A drag handle's icon, for mouse and touch only (not focusable); [modifier] holds its [reorderHandle]. On a touch screen
 * the drag starts anywhere in a square of at least 48 dp centred on it ([HitTarget]), the icon keeping its size and place.
 */
@Composable
internal fun DragHandleIcon(description: String, modifier: Modifier = Modifier) {
    val target = rememberHitTarget()
    Icon(
        PlezyIcons.DragIndicator,
        contentDescription = description,
        modifier = (target?.bounds ?: Modifier).then(modifier).then(target?.square ?: Modifier).padding(4.dp).size(24.dp),
        tint = PlezyColors.TextMuted,
    )
}
