package com.edde746.plezy.ui.trackers

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.trackers.DetailWatchlistStore
import com.edde746.plezy.presentation.trackers.WatchlistSourceOption
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.icons.CatalogSourceLogo
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance

/**
 * The watchlists of one title, a [PlezySheet] titled Watchlist (on TV the side panel) while [options] is not null:
 * one group of rows, a row per source with its mark, its name over what picking it does (add or remove), and a check
 * while the title is on that watchlist. The first row takes focus. [onPick] gets the row's index, [onDismiss] a
 * dismissal. Harness names `<probe>.sheet`, `<probe>.<i>`.
 */
@Composable
internal fun WatchlistSheet(options: List<WatchlistSourceOption>?, onPick: (Int) -> Unit, onDismiss: () -> Unit, probe: String) {
    if (options == null) return
    val first = remember { FocusRequester() }
    PlezySheet(onDismiss = onDismiss, title = T.explore.rows.watchlist, initialFocus = first, probe = "$probe.sheet") {
        Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(vertical = 4.dp)) {
            RowGroup {
                options.forEachIndexed { index, option ->
                    GroupRow(
                        option.name,
                        onClick = { onPick(index) },
                        modifier = Modifier.layoutProbe("$probe.$index").then(if (index == 0) Modifier.focusRequester(first) else Modifier),
                        shape = groupShape(index, options.size),
                        subtitle = option.action,
                        leading = { CatalogSourceLogo(option.logo, size = 24.dp) },
                        trailing = { if (option.member) Icon(PlezyIcons.Check, contentDescription = null, Modifier.size(22.dp)) },
                    )
                }
            }
        }
    }
}

/**
 * The detail's watchlist button ([DetailWatchlistStore]): the bookmark, filled while the item is on any connected
 * source's watchlist, its label what a press does; with several sources a press opens [WatchlistSheet]. Off TV it
 * can't be pressed until a membership is known; on TV a press then loads the watchlists. Nothing while the store has no
 * button. Harness names `detail.watchlist`, `detail.watchlist.option.<i>`.
 */
@Composable
internal fun DetailWatchlistButton(store: DetailWatchlistStore, modifier: Modifier = Modifier) {
    val ui by store.state.collectAsState()
    val state = ui ?: return
    val tv = LocalAppearance.current.tv
    Box {
        PlezyIconButton(
            if (state.onWatchlist == true) PlezyIcons.Bookmark else PlezyIcons.BookmarkBorder,
            state.label,
            store::press,
            modifier.layoutProbe("detail.watchlist"),
            style = IconButtonStyle.OVER_PICTURE,
            enabled = state.enabled || tv,
        )
        WatchlistSheet(state.chooser, onPick = store::choose, onDismiss = { store.choose(null) }, probe = "detail.watchlist.option")
    }
}
