package com.edde746.plezy.ui.livetv

import androidx.compose.runtime.getValue
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.livetv.schedule.ScheduleRow
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.components.use24HourClock
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * A show's upcoming airings ([Route.LiveTvShowSchedule]): the show's title with Back and, when the server records,
 * "Record show"; then one row per airing (on now tinted, with a play icon), its first focused. A tap tunes an airing on
 * now, else opens its details. Harness names `liveTv.schedule.record`, `liveTv.schedule.<i>`.
 */
@Composable
fun ShowScheduleScreen(app: AppSession, route: Route.LiveTvShowSchedule, modifier: Modifier = Modifier) {
    val clock24 = use24HourClock()
    val store = remember(app, route) { app.liveTvShowSchedule(route, clock24) } ?: return
    LaunchedEffect(clock24) { store.setUse24HourClock(clock24) }
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    val dimens = LocalPlezyDimens.current
    val list = rememberLazyListState()
    Box(modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            ScreenHeader(state.title, onBack = app.navigator::back, contentTitle = true, scrolled = { list.canScrollBackward }) {
                state.recordShowLabel?.let {
                    PlezyIconButton(PlezyIcons.Record, it, store::recordShow, Modifier.layoutProbe("liveTv.schedule.record"))
                }
            }
            when {
                state.loading -> LoadingState()
                state.emptyText != null -> EmptyState(state.emptyText.orEmpty(), icon = PlezyIcons.LiveTv)
                else -> LazyColumn(
                    Modifier.fillMaxSize(),
                    state = list,
                    contentPadding = PaddingValues(start = dimens.screenPadding, end = dimens.screenPadding, top = dimens.focusReach, bottom = 24.dp),
                ) {
                    item(key = "rows") {
                        RowGroup {
                            state.rows.forEachIndexed { index, row ->
                                ScheduleTile(row, groupShape(index, state.rows.size), { store.tap(index) }, Modifier.rememberFocus(memory, "row$index").layoutProbe("liveTv.schedule.$index"))
                            }
                        }
                    }
                }
            }
        }
        state.message?.let {
            TimedToast(it.text, "liveTv.message", store::messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = dimens.sectionSpacing), isError = it.isError)
        }
    }
    RestoreFocus(memory, ready = state.rows.isNotEmpty(), fallback = "row0")
    state.details?.let { ProgramDetailsSheet(it, store::closeDetails) }
    state.recordOptions?.let { RecordOptionsSheet(it) }
}

@Composable
private fun ScheduleTile(row: ScheduleRow, shape: androidx.compose.ui.graphics.Shape, onClick: () -> Unit, modifier: Modifier) {
    PlezySurface(onClick = onClick, modifier = modifier.fillMaxWidth(), shape = shape, color = if (row.live) PlezyColors.SurfaceHighest else PlezyColors.SurfaceHigh, grows = false) {
        Column(Modifier.heightIn(min = 56.dp).padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    row.title,
                    Modifier.weight(1f),
                    style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                row.premiereBadge?.let { StatusPill(it, MaterialTheme.colorScheme.primary) }
                if (row.live) Icon(PlezyIcons.PlayCircle, contentDescription = null, Modifier.size(20.dp), tint = MaterialTheme.colorScheme.primary)
            }
            // Secondary lines follow the tile's content colour, so they stay readable on the focused (inverted) tile.
            val secondary = PlezyColors.MutedContent
            Text(row.subtitle, style = MaterialTheme.typography.bodySmall, color = secondary, maxLines = 2, overflow = TextOverflow.Ellipsis)
            row.channelName?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = secondary, maxLines = 1) }
        }
    }
}
