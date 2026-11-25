package com.edde746.plezy.ui.menu

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.presentation.player.FileInfoCard
import com.edde746.plezy.presentation.player.FileInfoCardKind
import com.edde746.plezy.presentation.player.FileInfoField
import com.edde746.plezy.presentation.player.FileInfoGrid
import com.edde746.plezy.presentation.player.FileInfoSections
import com.edde746.plezy.presentation.player.FileInfoVersion
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.use24HourClock
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The file info sheet's content ([FileInfoSections.page]) for the item named [title], in the content colour of where
 * it sits (the item menu's sheet, the player's page): the title, then each version's cards,
 * their fields in one or two columns ([FileInfoGrid]). Each field takes focus, so a remote walks (and scrolls) through
 * them; a path copies on a tap or select and says so in a toast. Harness names under [probe]: `.path.<version>.<file>`,
 * `.copied`, `.noStreams`.
 */
@Composable
internal fun FileInfoContent(info: MediaFileInfo, title: String, probe: String, modifier: Modifier = Modifier) {
    val clock = use24HourClock()
    val page = remember(info, title, clock) { FileInfoSections.page(info, title, clock) }
    val clipboard = LocalClipboardManager.current
    var copied by remember { mutableStateOf(false) }
    Box(modifier) {
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(bottom = 24.dp)) {
            if (page.title.isNotEmpty()) {
                Text(page.title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(20.dp))
            }
            page.versions.forEachIndexed { versionIndex, version ->
                if (versionIndex > 0) Spacer(Modifier.height(20.dp))
                VersionBlock(version, versionIndex, probe) { path ->
                    clipboard.setText(AnnotatedString(path))
                    copied = true
                }
            }
        }
        if (copied) {
            TimedToast(T.fileInfo.pathCopied, "$probe.copied", { copied = false }, Modifier.align(Alignment.BottomCenter).padding(bottom = LocalPlezyDimens.current.sectionSpacing))
        }
    }
}

@Composable
private fun VersionBlock(version: FileInfoVersion, index: Int, probe: String, copy: (String) -> Unit) {
    version.heading?.let { heading ->
        Row(Modifier.padding(bottom = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(PlezyIcons.Layers, contentDescription = null, Modifier.size(18.dp), tint = PlezyColors.Primary)
            Spacer(Modifier.width(8.dp))
            Text(heading, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = PlezyColors.Primary)
            version.title?.let {
                Spacer(Modifier.width(8.dp))
                Text(it, style = MaterialTheme.typography.titleSmall, color = PlezyColors.MutedContent, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
    version.overview?.let { Card(it) }
    version.files.forEachIndexed { fileIndex, file ->
        file.card?.let { card -> Card(card, pathProbe = "$probe.path.$index.$fileIndex", copy = copy) }
        file.streams.forEach { Card(it) }
        if (file.noStreams) {
            Text(
                T.fileInfo.noStreams,
                Modifier.padding(bottom = 12.dp).layoutProbe("$probe.noStreams"),
                style = MaterialTheme.typography.bodySmall,
                color = PlezyColors.MutedContent,
            )
        }
    }
    version.attachments?.let { Card(it) }
    version.delivery?.let { Card(it) }
}

/** A tonal card: a step off whatever it sits on, taken from the content colour so it reads on any theme and on video. */
@Composable
private fun Card(card: FileInfoCard, pathProbe: String? = null, copy: (String) -> Unit = {}) {
    Column(
        Modifier
            .fillMaxWidth()
            .padding(bottom = 12.dp)
            .background(LocalContentColor.current.copy(alpha = 0.05f), MaterialTheme.shapes.medium)
            .padding(start = 14.dp, end = 14.dp, top = 12.dp, bottom = 14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(card.kind.icon, contentDescription = null, Modifier.size(18.dp), tint = PlezyColors.Primary)
            Spacer(Modifier.width(8.dp))
            Text(card.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            card.subtitle?.let {
                Spacer(Modifier.width(10.dp))
                Text(
                    it,
                    Modifier.weight(1f),
                    style = MaterialTheme.typography.bodySmall,
                    color = PlezyColors.MutedContent,
                    textAlign = TextAlign.End,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        if (card.chips.isNotEmpty()) Chips(card.chips, alpha = 0.1f, Modifier.padding(top = 10.dp))
        card.path?.let { path -> PathRow(path, Modifier.padding(top = 8.dp).then(pathProbe?.let { Modifier.layoutProbe(it) } ?: Modifier)) { copy(path) } }
        if (card.fields.isNotEmpty()) FieldGrid(card.fields, Modifier.padding(top = 4.dp))
    }
}

@Composable
private fun Chips(labels: List<String>, alpha: Float, modifier: Modifier) {
    val fill = LocalContentColor.current.copy(alpha = alpha)
    FlowRow(modifier, horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        for (label in labels) {
            Text(
                label,
                Modifier.background(fill, RoundedCornerShape(8.dp)).padding(horizontal = 10.dp, vertical = 6.dp),
                style = MaterialTheme.typography.labelMedium,
            )
        }
    }
}

/** The file's path, whole and monospace; a tap or select copies it. */
@Composable
private fun PathRow(path: String, modifier: Modifier, onCopy: () -> Unit) {
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    Row(
        modifier
            .fillMaxWidth()
            .background(focusFill(focused), RoundedCornerShape(8.dp))
            .clickable(interaction, indication = null, onClickLabel = T.fileInfo.copyPath, onClick = onCopy)
            .padding(horizontal = 4.dp, vertical = 8.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Column(Modifier.weight(1f)) {
            Text(T.fileInfo.path, style = MaterialTheme.typography.labelSmall, color = PlezyColors.MutedContent)
            Spacer(Modifier.height(2.dp))
            Text(path, style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace))
        }
        Spacer(Modifier.width(8.dp))
        Icon(PlezyIcons.ContentCopy, contentDescription = T.fileInfo.copyPath, Modifier.size(18.dp), tint = PlezyColors.MutedContent)
    }
}

/** [FileInfoGrid]'s rows at the card's width; a long value spans the row. */
@Composable
private fun FieldGrid(fields: List<FileInfoField>, modifier: Modifier) {
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val columns = FileInfoGrid.columns(maxWidth.value)
        Column {
            for (row in FileInfoGrid.rows(fields, columns)) {
                Row(horizontalArrangement = Arrangement.spacedBy(FileInfoGrid.COLUMN_GAP.dp)) {
                    for (field in row) Field(field, if (field.fullWidth || columns == 1) Modifier.fillMaxWidth() else Modifier.weight(1f))
                    if (row.size < columns && !row.single().fullWidth) Spacer(Modifier.weight(1f))
                }
            }
        }
    }
}

/** A label over its value; it takes focus (and scrolls into view) for a remote, with nothing to activate. */
@Composable
private fun Field(field: FileInfoField, modifier: Modifier) {
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    Column(modifier.background(focusFill(focused), MaterialTheme.shapes.extraSmall).focusable(interactionSource = interaction).padding(vertical = 6.dp)) {
        Text(field.label, style = MaterialTheme.typography.labelSmall, color = PlezyColors.MutedContent)
        Spacer(Modifier.height(2.dp))
        Text(
            field.value,
            style = if (field.monospace) MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace) else MaterialTheme.typography.bodyMedium,
        )
    }
}

/** A field's or the path's fill while it has focus and focus shows (keys, a remote; not after a touch). */
@Composable
private fun focusFill(focused: Boolean): Color =
    if (focused && isFocusVisible()) LocalContentColor.current.copy(alpha = 0.12f) else Color.Transparent

private val FileInfoCardKind.icon: ImageVector
    get() = when (this) {
        FileInfoCardKind.OVERVIEW -> PlezyIcons.Info
        FileInfoCardKind.FILE -> PlezyIcons.Folder
        FileInfoCardKind.ATTACHMENTS -> PlezyIcons.Link
        FileInfoCardKind.DELIVERY -> PlezyIcons.Dns
        FileInfoCardKind.VIDEO -> PlezyIcons.Movie
        FileInfoCardKind.AUDIO -> PlezyIcons.GraphicEq
        FileInfoCardKind.SUBTITLES -> PlezyIcons.Subtitles
        FileInfoCardKind.LYRICS -> PlezyIcons.Lyrics
        FileInfoCardKind.IMAGES -> PlezyIcons.PhotoCamera
        FileInfoCardKind.DATA -> PlezyIcons.Memory
    }
