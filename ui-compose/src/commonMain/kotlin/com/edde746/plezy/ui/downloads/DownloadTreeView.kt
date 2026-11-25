package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.presentation.downloads.DownloadRowAction
import com.edde746.plezy.presentation.downloads.DownloadTreeNode
import com.edde746.plezy.presentation.downloads.DownloadTreeRow
import com.edde746.plezy.presentation.downloads.downloadRowActions
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.DownloadProgressBar
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.ui.components.DownloadMark
import com.edde746.plezy.ui.components.icon
import androidx.compose.runtime.CompositionLocalProvider
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.rememberHeaderListState

/**
 * The Manage tab: every download as a tree (movies, shows → seasons → episodes, albums → tracks), [rows] already
 * flattened by what is expanded. A container row toggles with a tap or Select ([onToggle]), a title opens its page
 * ([onOpen]); each row ends in its actions ([downloadRowActions]) as plain icon buttons, reached with D-pad right. With
 * none, the titles tabs' empty
 * state ("No downloads yet" and what shows here).
 */
@Composable
fun DownloadTreeView(
    rows: List<DownloadTreeRow>,
    onToggle: (key: String) -> Unit,
    onOpen: (MediaItem) -> Unit,
    onAction: (DownloadTreeNode, DownloadRowAction) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (rows.isEmpty()) {
        return EmptyState(
            T.downloads.noDownloadsDescription,
            modifier.layoutProbe("downloads.tree", reportsFocus = false),
            title = T.downloads.noDownloads,
            icon = PlezyIcons.Download,
        )
    }
    val side = LocalPlezyDimens.current.screenPadding
    LazyColumn(
        modifier.fillMaxSize().layoutProbe("downloads.tree", reportsFocus = false),
        rememberHeaderListState(),
        contentPadding = PaddingValues(start = side, end = side, top = 4.dp, bottom = 24.dp),
    ) {
        itemsIndexed(rows, key = { _, row -> row.node.key }) { index, row ->
            // Expanded: its children follow it, one level deeper.
            val expanded = rows.getOrNull(index + 1)?.let { it.depth > row.depth } == true
            DownloadTreeRowView(row, expanded, onToggle, onOpen, onAction)
        }
    }
}

@Composable
private fun DownloadTreeRowView(
    row: DownloadTreeRow,
    expanded: Boolean,
    onToggle: (key: String) -> Unit,
    onOpen: (MediaItem) -> Unit,
    onAction: (DownloadTreeNode, DownloadRowAction) -> Unit,
) {
    val node = row.node
    val canExpand = node.hasChildren
    val actions = downloadRowActions(node)
    // A child's mark lines up under its parent's: each level indents by the arrow and its gap, which only containers
    // (shows, seasons, albums) show.
    Row(
        Modifier.fillMaxWidth().padding(start = (row.depth * 28).dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PlezySurface(
            onClick = { if (canExpand) onToggle(node.key) else node.metadata?.let(onOpen) },
            modifier = Modifier.weight(1f).layoutProbe("downloads.row.${node.key}"),
            shape = RoundedCornerShape(8.dp),
            color = Color.Transparent,
            grows = false,
        ) {
            Row(Modifier.padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                if (canExpand) {
                    Icon(PlezyIcons.ChevronRight, contentDescription = null, Modifier.size(20.dp).rotate(if (expanded) 90f else 0f))
                    Spacer(Modifier.width(8.dp))
                }
                val status = node.effectiveStatus
                val markColor = if (status == DownloadedMediaStatus.FAILED) PlezyColors.Error else LocalContentColor.current
                CompositionLocalProvider(LocalContentColor provides markColor) {
                    DownloadMark(status.icon, node.progress.toFloat().takeIf { status == DownloadedMediaStatus.DOWNLOADING }, size = 24.dp)
                }
                Spacer(Modifier.width(12.dp))
                DownloadRowText(node, canExpand)
            }
        }
        if (actions.isNotEmpty()) {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                for (action in actions) {
                    PlezyIconButton(
                        action.icon,
                        action.label,
                        onClick = { onAction(node, action) },
                        style = IconButtonStyle.PLAIN,
                        size = 36.dp,
                        modifier = Modifier.layoutProbe("downloads.row.${node.key}.${action.name.lowercase()}"),
                    )
                }
            }
        }
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.DownloadRowText(node: DownloadTreeNode, canExpand: Boolean) {
    val secondary = PlezyColors.MutedContent
    val small = MaterialTheme.typography.bodySmall
    val status = node.effectiveStatus
    Column(Modifier.weight(1f)) {
        Text(
            node.title,
            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = if (canExpand) FontWeight.SemiBold else FontWeight.Normal),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        if (canExpand) {
            Spacer(Modifier.height(4.dp))
            Text(node.summary, style = small, color = secondary)
        }
        if (status == DownloadedMediaStatus.DOWNLOADING) {
            Spacer(Modifier.height(8.dp))
            DownloadProgressBar(node.progress.toFloat())
            node.downloadProgress?.let { download ->
                Spacer(Modifier.height(4.dp))
                Text("${formatPercent(node.progress)}% - ${download.speedFormatted}", style = small, color = secondary)
            }
        }
        if (status == DownloadedMediaStatus.QUEUED) {
            Spacer(Modifier.height(4.dp))
            Text(T.downloads.downloadQueued, style = small, color = secondary)
        }
        val error = node.downloadProgress?.errorMessage
        if (status == DownloadedMediaStatus.FAILED && error != null) {
            Spacer(Modifier.height(4.dp))
            Text(error, style = small, color = PlezyColors.Error, maxLines = 2, overflow = TextOverflow.Ellipsis)
        }
    }
}

/** [fraction] (0–1) as a percentage with one decimal ("42.5"). */
internal fun formatPercent(fraction: Double): String {
    val tenths = kotlin.math.round(fraction * 1000).toLong()
    return "${tenths / 10}.${tenths % 10}"
}

private val DownloadRowAction.icon: ImageVector
    get() = when (this) {
        DownloadRowAction.PAUSE, DownloadRowAction.PAUSE_ALL -> PlezyIcons.Pause
        DownloadRowAction.RESUME, DownloadRowAction.RESUME_ALL -> PlezyIcons.PlayArrow
        DownloadRowAction.CANCEL -> PlezyIcons.Close
        DownloadRowAction.RETRY, DownloadRowAction.RETRY_ALL -> PlezyIcons.Refresh
        DownloadRowAction.DELETE, DownloadRowAction.DELETE_ALL -> PlezyIcons.Delete
    }
