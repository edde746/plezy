package com.edde746.plezy.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyColors
import com.google.zxing.EncodeHintType
import com.google.zxing.WriterException
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import com.google.zxing.qrcode.encoder.Encoder

/**
 * [payload] as a QR code (ZXing's: UTF-8, error correction level M, as Apple's), dark modules on a light square
 * whatever the theme (phone cameras read that reliably), with a four-module quiet zone, [size] wide. A payload no QR
 * code can hold (past about 2.3 KB) shows an error line in its place, [size] wide,
 * read out as itself rather than as [contentDescription]. [pureWhite]: black on pure white instead of the theme's
 * lightest and darkest tones.
 */
@Composable
fun QrCodeImage(payload: String, contentDescription: String, size: Dp, modifier: Modifier = Modifier, pureWhite: Boolean = false) {
    val modules = remember(payload) {
        try {
            Encoder.encode(payload, ErrorCorrectionLevel.M, mapOf(EncodeHintType.CHARACTER_SET to "UTF-8")).matrix
        } catch (_: WriterException) {
            null
        }
    }
    if (modules == null) {
        Row(modifier.width(size), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
            Icon(PlezyIcons.ErrorOutline, contentDescription = null, Modifier.size(20.dp), tint = PlezyColors.Error)
            Text(
                T.nav.qrFailed,
                Modifier.semantics { liveRegion = LiveRegionMode.Polite },
                style = MaterialTheme.typography.bodyMedium,
                color = PlezyColors.Error,
            )
        }
        return
    }
    val scheme = MaterialTheme.colorScheme
    val themeLight = if (scheme.surface.luminance() > scheme.onSurface.luminance()) scheme.surface else scheme.onSurface
    val light = if (pureWhite) Color.White else themeLight
    val dark = if (pureWhite) Color.Black else if (themeLight == scheme.surface) scheme.onSurface else scheme.surface
    Canvas(modifier.size(size).aspectRatio(1f).semantics { this.contentDescription = contentDescription }) {
        drawRect(light)
        val quiet = 4
        val cell = this.size.width / (modules.width + 2 * quiet)
        for (y in 0 until modules.height) {
            for (x in 0 until modules.width) {
                if (modules[x, y].toInt() != 1) continue
                // A hair of overlap, so neighbouring modules don't show seams when the cell size isn't whole pixels.
                drawRect(dark, Offset((x + quiet) * cell, (y + quiet) * cell), Size(cell + 0.5f, cell + 0.5f))
            }
        }
    }
}

/** The QR code's width for this window: larger on TV (read across a room), smaller on phones. */
@Composable
fun qrSize(): Dp = when {
    LocalWindowLayout.current.formFactor == FormFactor.TV -> 280.dp
    LocalWindowLayout.current.widthClass == WidthClass.COMPACT -> 200.dp
    else -> 232.dp
}
