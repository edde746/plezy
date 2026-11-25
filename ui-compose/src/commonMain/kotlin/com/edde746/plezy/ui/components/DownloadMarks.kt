package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.ui.icons.PlezyIcons

/** The icon of a download's status. */
val DownloadedMediaStatus.icon: ImageVector
    get() = when (this) {
        DownloadedMediaStatus.QUEUED -> PlezyIcons.Schedule
        DownloadedMediaStatus.DOWNLOADING, DownloadedMediaStatus.PARTIAL -> PlezyIcons.Download
        DownloadedMediaStatus.PAUSED -> PlezyIcons.Pause
        DownloadedMediaStatus.FAILED -> PlezyIcons.ErrorOutline
        DownloadedMediaStatus.COMPLETED -> PlezyIcons.DownloadDone
        DownloadedMediaStatus.CANCELLED -> PlezyIcons.Close
    }

/**
 * A download's state as [icon] inside a [size] circle, with [progress] (0–1) as a ring round it while it is known: the
 * done part in the content colour over a faint track, from the top, clockwise. Follows [LocalContentColor], so it
 * inverts on a focused control.
 */
@Composable
fun DownloadMark(
    icon: ImageVector,
    progress: Float?,
    modifier: Modifier = Modifier,
    size: Dp = 24.dp,
    iconSize: Dp = if (progress != null) size * 0.55f else size * 0.8f,
    contentDescription: String? = null,
) {
    val content = LocalContentColor.current
    Box(
        modifier
            .size(size)
            .then(if (progress != null) Modifier.downloadRing(progress, content, (size.value / 12f).coerceAtLeast(2f).dp) else Modifier),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = contentDescription, Modifier.size(iconSize), tint = content)
    }
}

/** [progress] as a ring just inside this element's bounds, [width] wide, in [color] over its faint track. */
private fun Modifier.downloadRing(progress: Float, color: Color, width: Dp): Modifier = drawBehind {
    val stroke = width.toPx()
    val inset = stroke / 2
    val arcSize = Size(size.width - stroke, size.height - stroke)
    val topLeft = Offset(inset, inset)
    drawArc(color.copy(alpha = 0.24f), 0f, 360f, useCenter = false, topLeft = topLeft, size = arcSize, style = Stroke(stroke))
    val done = progress.coerceIn(0f, 1f)
    if (done > 0f) drawArc(color, -90f, 360f * done, useCenter = false, topLeft = topLeft, size = arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
}

/**
 * A download's progress as a thin bar across its row ([progress], 0–1): the done part in the progress fill over its
 * track, its rounded ends lined up with the text beside it; filled from the leading edge (right to left in Arabic).
 */
@Composable
fun DownloadProgressBar(progress: Float, modifier: Modifier = Modifier) {
    val done = progress.coerceIn(0f, 1f)
    val content = LocalContentColor.current
    Spacer(
        modifier.fillMaxWidth().height(4.dp).drawBehind {
            val radius = CornerRadius(size.height / 2)
            drawRoundRect(content.copy(alpha = 0.24f), cornerRadius = radius)
            if (done <= 0f) return@drawBehind
            val width = maxOf(size.width * done, size.height)
            val left = if (layoutDirection == LayoutDirection.Rtl) size.width - width else 0f
            drawRoundRect(content, topLeft = Offset(left, 0f), size = Size(width, size.height), cornerRadius = radius)
        },
    )
}
