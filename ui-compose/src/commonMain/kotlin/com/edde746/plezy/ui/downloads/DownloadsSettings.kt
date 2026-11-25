package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.downloads.DownloadLocationModel
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * [model]'s download location dialog while open (the current folder, Select folder through the platform's picker —
 * Android's document tree, the desktop folder dialog — and, for a custom folder, Reset to default), and its outcome as
 * a toast placed by [toastModifier].
 */
@Composable
fun DownloadLocationOverlay(model: DownloadLocationModel, toastModifier: Modifier = Modifier) {
    val state by model.state.collectAsState()
    if (state.dialogOpen) {
        ModalOverlay(state.dialogTitle, onDismiss = model::closeDialog, Modifier.layoutProbe("settings.downloadLocation.dialog", reportsFocus = false)) {
            Text(state.description, style = MaterialTheme.typography.bodyMedium)
            Text(state.currentPathLine, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, modifier = Modifier.padding(top = 8.dp))
            OverlayActions(Modifier.padding(top = 16.dp)) {
                if (state.offersReset) PlezyButton(state.resetLabel, onClick = model::reset, enabled = !state.busy)
                PlezyButton(T.common.cancel, onClick = model::closeDialog)
                PlezyButton(state.selectLabel, onClick = model::selectFolder, style = ButtonStyle.PRIMARY, enabled = !state.busy)
            }
        }
    }
    state.message?.let { TimedToast(it.message, "settings.downloadLocation.message", model::messageShown, toastModifier, isError = it.isError) }
}
