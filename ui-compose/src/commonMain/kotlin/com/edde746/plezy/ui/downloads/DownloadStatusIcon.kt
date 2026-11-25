package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.TooltipBox
import androidx.compose.material3.TooltipDefaults
import androidx.compose.material3.PlainTooltip
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.rememberTooltipState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.presentation.downloads.DownloadButtonIcon
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.downloads.DownloadButtonTint
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.LocalContentColor
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.DownloadMark
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.theme.LocalPlezyColors
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyColors

/** The detail download button's tints ([DownloadButtonTint]). */
private object StatusColors {
    val Orange = Color(0xFFFF9800)
    val Amber = Color(0xFFFFC107)
    val Grey = Color(0xFF9E9E9E)
    val Red = Color(0xFFF44336)
    val Teal = Color(0xFF009688)
}

/** A [DownloadButtonTint] as its colour; [DownloadButtonTint.NONE] is null (the button's own content colour). */
internal fun DownloadButtonTint.color(): Color? = when (this) {
    DownloadButtonTint.NONE -> null
    DownloadButtonTint.AMBER -> StatusColors.Amber
    DownloadButtonTint.RED -> StatusColors.Red
    DownloadButtonTint.GREY -> StatusColors.Grey
    DownloadButtonTint.TEAL -> StatusColors.Teal
    DownloadButtonTint.ORANGE -> StatusColors.Orange
}

/**
 * The media detail screen's download button ([com.edde746.plezy.presentation.downloads.downloadButtonSpec]): a round
 * button showing the download's state (a spinner while queueing, a progress ring round the download arrow while
 * downloading, the done mark once downloaded, the sync icon for a synced item, …) in its tint, with
 * [DownloadButtonSpec.tooltip] on hover or long press; [onPress] runs
 * [com.edde746.plezy.presentation.downloads.DetailDownload.press]. It takes no press while queueing or downloading.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailDownloadButton(spec: DownloadButtonSpec, onPress: () -> Unit, modifier: Modifier = Modifier, overPicture: Boolean = false) {
    val label = spec.tooltip ?: T.downloads.downloadNow
    val dimens = LocalPlezyDimens.current
    val size = dimens.iconButtonSize
    val button: @Composable () -> Unit = {
        PlezySurface(
            onClick = { if (spec.interactive) onPress() },
            modifier = modifier.size(size).semantics { contentDescription = label },
            shape = CircleShape,
            color = if (overPicture) PlezyColors.PictureButton else LocalPlezyColors.current.surfaceHigh,
            contentAlignment = Alignment.Center,
            hitTarget = true,
        ) {
            val tint = spec.tint.color() ?: LocalContentColor.current
            when (spec.icon) {
                DownloadButtonIcon.SPINNER -> CircularProgressIndicator(Modifier.size(size * 0.45f), color = tint, strokeWidth = 2.dp)
                DownloadButtonIcon.PROGRESS -> CompositionLocalProvider(LocalContentColor provides tint) {
                    DownloadMark(PlezyIcons.Download, (spec.progress ?: 0f).coerceIn(0f, 1f), size = size * 0.6f)
                }
                else -> Icon(spec.icon.vector(), contentDescription = null, Modifier.size(size * 0.5f), tint = tint)
            }
        }
    }
    // On TV, which has no pointer, focus would raise the tooltip over the text above the button.
    if (spec.tooltip == null || dimens.focusGrows) {
        button()
    } else {
        TooltipBox(TooltipDefaults.rememberPlainTooltipPositionProvider(), { PlainTooltip { Text(label) } }, rememberTooltipState()) { button() }
    }
}

private fun DownloadButtonIcon.vector() = when (this) {
    DownloadButtonIcon.QUEUED -> PlezyIcons.Schedule
    DownloadButtonIcon.PAUSED -> PlezyIcons.Pause
    DownloadButtonIcon.FAILED -> PlezyIcons.ErrorOutline
    DownloadButtonIcon.CANCELLED -> PlezyIcons.Close
    DownloadButtonIcon.SYNC -> PlezyIcons.Sync
    DownloadButtonIcon.SYNC_DISABLED -> PlezyIcons.SyncProblem
    DownloadButtonIcon.DOWNLOADED -> PlezyIcons.DownloadDone
    DownloadButtonIcon.DOWNLOAD, DownloadButtonIcon.PARTIAL, DownloadButtonIcon.SPINNER, DownloadButtonIcon.PROGRESS -> PlezyIcons.Download
}
