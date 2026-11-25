package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.downloads.SyncRuleIcon
import com.edde746.plezy.presentation.downloads.SyncRuleRow
import com.edde746.plezy.presentation.downloads.SyncRulesStore
import com.edde746.plezy.presentation.downloads.SyncRulesUiState
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.GroupGap
import com.edde746.plezy.ui.components.RowInset
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.SwipeToRemove
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/** Active sync rules over [store]; [onBack] closes it. */
@Composable
fun SyncRulesScreen(store: SyncRulesStore, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    SyncRulesContent(state, onBack, store::setEnabled, store::edit, store::remove, store::messageShown, modifier)
}

/**
 * The sync rules list, laid out as Keep synced: the rules as one connected group of rows, each its kind's icon, its
 * title, what it keeps and its server's state (a press or Select edits it), then beside it the enabled switch and the
 * remove button, each its own stop for a remote. On a touch screen a swipe toward the start removes it too. The empty
 * state when there are none.
 */
@Composable
fun SyncRulesContent(
    state: SyncRulesUiState,
    onBack: () -> Unit,
    onEnabled: (globalKey: String, enabled: Boolean) -> Unit,
    onEdit: (globalKey: String) -> Unit,
    onRemove: (globalKey: String) -> Unit,
    onMessageShown: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val touch = LocalWindowLayout.current.formFactor == FormFactor.HANDHELD
    val list = rememberLazyListState()
    Box(modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            ScreenHeader(state.title, onBack = onBack, scrolled = { list.canScrollBackward })
            if (state.rules.isEmpty()) {
                EmptyState(state.empty, icon = PlezyIcons.Sync, modifier = Modifier.layoutProbe("syncRules.empty", reportsFocus = false))
            } else {
                val side = LocalPlezyDimens.current.screenPadding
                LazyColumn(
                    Modifier.fillMaxSize().layoutProbe("syncRules.list", reportsFocus = false),
                    state = list,
                    contentPadding = PaddingValues(start = side, end = side, top = LocalPlezyDimens.current.focusReach, bottom = 24.dp),
                ) {
                    itemsIndexed(state.rules, key = { _, rule -> rule.globalKey }) { index, rule ->
                        val tile = @Composable {
                            RuleRow(
                                rule,
                                groupShape(index, state.rules.size),
                                state.removeLabel,
                                { onEnabled(rule.globalKey, it) },
                                { onEdit(rule.globalKey) },
                                { onRemove(rule.globalKey) },
                                Modifier.padding(top = if (index > 0) GroupGap else 0.dp),
                            )
                        }
                        if (touch) SwipeToRemove("syncRules.${rule.globalKey}.swipe", { onRemove(rule.globalKey) }, tile) else tile()
                    }
                }
            }
        }
        state.message?.let { TimedToast(it.message, "syncRules.message", onMessageShown, Modifier.align(Alignment.BottomCenter), it.isError) }
    }
}

/**
 * A rule's card: a click edits it; its switch and × at its end turn it on and off and remove it, each a stop of its own
 * (Right from the card, Left back to it).
 */
@Composable
private fun RuleRow(rule: SyncRuleRow, shape: Shape, removeLabel: String, onEnabled: (Boolean) -> Unit, onEdit: () -> Unit, onRemove: () -> Unit, modifier: Modifier) {
    val card = remember { FocusRequester() }
    val switch = remember { FocusRequester() }
    PlezySurface(
        onClick = onEdit,
        // The switch sits inside the card's bounds, where a directional search from the card never looks.
        modifier = modifier.fillMaxWidth().focusRequester(card).focusProperties { end = switch }.layoutProbe("syncRules.${rule.globalKey}"),
        shape = shape,
        grows = false,
    ) {
        Row(
            Modifier.padding(start = RowInset, end = 4.dp, top = RowInset, bottom = RowInset),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(RowInset),
        ) {
            Icon(
                when (rule.icon) {
                    SyncRuleIcon.PLAYLIST -> PlezyIcons.PlaylistPlay
                    SyncRuleIcon.COLLECTION -> PlezyIcons.Bookmark
                    SyncRuleIcon.SHOW -> PlezyIcons.Tv
                },
                contentDescription = null,
                Modifier.size(24.dp),
            )
            Column(Modifier.weight(1f)) {
                Text(rule.title, style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold), maxLines = 2, overflow = TextOverflow.Ellipsis)
                Text(rule.subtitle, style = MaterialTheme.typography.bodySmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(rule.serverLine, style = MaterialTheme.typography.bodySmall, color = PlezyColors.MutedContent, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                PlezyToggleSurface(
                    rule.enabled,
                    onEnabled,
                    Modifier.focusRequester(switch).focusProperties { start = card }.layoutProbe("syncRules.${rule.globalKey}.enabled"),
                    shape = CircleShape,
                    color = Color.Transparent,
                    contentColor = LocalContentColor.current,
                ) {
                    Box(Modifier.padding(horizontal = 6.dp, vertical = 2.dp)) { RowSwitch(rule.enabled) }
                }
                PlezyIconButton(
                    PlezyIcons.Close,
                    removeLabel,
                    onClick = onRemove,
                    style = IconButtonStyle.PLAIN,
                    modifier = Modifier.layoutProbe("syncRules.${rule.globalKey}.remove"),
                )
            }
        }
    }
}
