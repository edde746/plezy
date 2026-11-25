package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.libraries.BooleanFilterState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * A filter editor's yes/no field: one focus stop, [label] with its value (Any, Yes, or No where the field can be
 * negated) trailing it. Select steps on to the next value, round to Any; Right steps on and Left back.
 */
@Composable
fun BooleanFilterRow(label: String, value: BooleanFilterState, supportsExclusion: Boolean, onChange: (BooleanFilterState) -> Unit, modifier: Modifier = Modifier) {
    val states = listOfNotNull(BooleanFilterState.ANY, BooleanFilterState.YES, BooleanFilterState.NO.takeIf { supportsExclusion })
    val step = { by: Int -> onChange(states[(states.indexOf(value).coerceAtLeast(0) + by + states.size) % states.size]) }
    SheetOption(
        label,
        onClick = { step(1) },
        choice = false,
        modifier = modifier.onPreviewKeyEvent { event -> directionKey(event)?.let { step(if (it) 1 else -1); true } ?: false },
        badge = {
            FilterValue(
                when (value) {
                    BooleanFilterState.ANY -> T.libraries.advancedFilters.any
                    BooleanFilterState.YES -> T.libraries.advancedFilters.yes
                    BooleanFilterState.NO -> T.libraries.advancedFilters.no
                },
            )
        },
    )
}

/** A filter editor's field that opens a page of its values: [label], what it is set to ([value]) trailing it, a chevron. */
@Composable
fun FilterFieldRow(label: String, value: String?, onClick: () -> Unit, modifier: Modifier = Modifier) {
    SheetOption(
        label,
        onClick = onClick,
        modifier = modifier,
        choice = false,
        badge = {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                value?.let { FilterValue(it) }
                Chevron()
            }
        },
    )
}

/** A filter field's value at the end of its row, muted, as a [GroupRow]'s value. */
@Composable
private fun FilterValue(value: String) {
    Text(
        value,
        Modifier.widthIn(max = 200.dp),
        style = MaterialTheme.typography.bodyMedium,
        color = PlezyColors.MutedContent,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
    )
}

/** Left: false (ascending, include), Right: true (descending, exclude), on a key's press; null for other keys. */
internal fun directionKey(event: KeyEvent): Boolean? = when {
    event.type != KeyEventType.KeyDown -> null
    event.key == Key.DirectionLeft -> false
    event.key == Key.DirectionRight -> true
    else -> null
}
