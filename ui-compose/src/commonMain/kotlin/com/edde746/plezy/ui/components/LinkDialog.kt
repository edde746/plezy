package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * A `plezy://` link (an item's Show link, a profile's Show profile link) as a QR code and as text, with what opening it
 * does ([hint]), Copy (the link to the clipboard; [onCopied] says so) and Close ([onDismiss]). Harness names [probe] and
 * `<probe>.qr`. [option] goes under the hint (Show link's "Open as {profile}" switch).
 */
@Composable
fun LinkDialog(
    link: String,
    hint: String,
    probe: String,
    onCopied: () -> Unit,
    onDismiss: () -> Unit,
    option: (@Composable () -> Unit)? = null,
) {
    val platform = LocalPlezyPlatform.current
    val close = remember { FocusRequester() }
    ModalOverlay(T.deepLinks.dialogTitle, onDismiss, Modifier.layoutProbe(probe), initialFocus = close) {
        // On a TV's short window the code and text scroll, so the actions keep their height.
        Column(
            Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            QrCodeImage(link, T.deepLinks.dialogTitle, qrSize(), Modifier.layoutProbe("$probe.qr"))
            SelectionContainer {
                Text(
                    link,
                    style = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace),
                    color = PlezyColors.Text,
                    textAlign = TextAlign.Center,
                    maxLines = 4,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Text(hint, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, textAlign = TextAlign.Center)
            option?.invoke()
        }
        OverlayActions(primary = close) {
            PlezyButton(T.deepLinks.copy, {
                platform.setClipboardText(link, sensitive = false)
                onCopied()
            }, icon = PlezyIcons.ContentCopy)
            PlezyButton(T.common.close, onDismiss, Modifier.focusRequester(close), style = ButtonStyle.PRIMARY)
        }
    }
}
