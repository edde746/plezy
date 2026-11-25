package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.downloads.BackgroundDownloadWarning
import com.edde746.plezy.presentation.downloads.BackgroundWarningDialog
import com.edde746.plezy.presentation.downloads.DeletionDialog
import com.edde746.plezy.presentation.downloads.DownloadDialog
import com.edde746.plezy.presentation.downloads.DownloadDialogIcon
import com.edde746.plezy.presentation.downloads.DownloadDialogSwitch
import com.edde746.plezy.presentation.downloads.DownloadDialogs
import com.edde746.plezy.presentation.downloads.SmartDeletion
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.TextFieldDialog
import com.edde746.plezy.ui.components.ItemMenuSection
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.SectionedItemMenu
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.menu.MenuAnchor
import com.edde746.plezy.ui.menu.atMenuAnchor
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The download flows' dialogs, wherever they are asked from (the Downloads screen, a detail screen, a context menu):
 * [dialogs]' open question, [deletion]'s progress and [warning]'s background-download explanation. A choice
 * ([DownloadDialog.Options]) is a menu ([DownloadOptionsMenu]) at [anchor], the control pressed for it (the download
 * button, the menu entry); on TV a side panel. Place it once, at the top start of the app's root.
 */
@Composable
fun DownloadOverlays(dialogs: DownloadDialogs, deletion: SmartDeletion, warning: BackgroundDownloadWarning?, anchor: MenuAnchor) {
    val dialog by dialogs.dialog.collectAsState()
    Box(Modifier.atMenuAnchor(anchor)) {
        DownloadOptionsMenu(dialog as? DownloadDialog.Options, dialogs)
    }
    dialog?.let { DownloadDialogView(it, dialogs::setToggle, dialogs::submitCount, dialogs::confirm, dialogs::cancel) }
    val deleting by deletion.dialog.collectAsState()
    deleting?.let { DeletionProgressDialog(it) }
    if (warning != null) {
        val state by warning.state.collectAsState()
        state.dialog?.let { BackgroundWarningDialogView(it, warning::dismiss, warning::fix, warning::openHelp, warning::proceed) }
    }
}

/**
 * [options] (open while not null) as a menu: its title over its rows (each with its detail, a quality's estimated
 * size), then its switch ("Include specials"), checked while on, which a pick turns over and leaves the menu open.
 * Harness names `downloads.dialog.option.<i>`, `downloads.dialog.option.switch`.
 */
@Composable
internal fun DownloadOptionsMenu(options: DownloadDialog.Options?, dialogs: DownloadDialogs) {
    val rows = options?.options.orEmpty().mapIndexed { index, option ->
        ItemMenuEntry(option.label, icon = option.icon.vector, detail = option.detail) { dialogs.choose(index) }
    }
    val switch = options?.toggle?.let { toggle ->
        ItemMenuEntry(toggle.label, probe = "switch", selected = toggle.value, icon = toggle.icon?.vector, keepsOpen = true) { dialogs.setToggle(!toggle.value) }
    }
    SectionedItemMenu(
        expanded = options != null,
        // A pick answers first; only a dismissal of the menu still open cancels its question.
        onDismiss = { if (options != null && dialogs.dialog.value === options) dialogs.cancel() },
        sections = listOfNotNull(ItemMenuSection(options?.title, rows), switch?.let { ItemMenuSection(null, listOf(it)) }),
        probe = "downloads.dialog.option",
    )
}

/** One [DownloadDialog] that isn't a choice: the episode count field, or a confirmation. */
@Composable
fun DownloadDialogView(
    dialog: DownloadDialog,
    onToggle: (Boolean) -> Unit,
    onSubmitCount: (String) -> Unit,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
) {
    when (dialog) {
        is DownloadDialog.Options -> Unit
        is DownloadDialog.Count -> TextFieldDialog(
            dialog.title,
            remember { TextFieldState() },
            onSubmit = onSubmitCount,
            onCancel = onCancel,
            probe = "downloads.dialog",
            hint = dialog.hint,
            error = dialog.error,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            inputTransformation = { if (!asCharSequence().all(Char::isDigit)) revertAllChanges() },
            submitLabel = dialog.confirmLabel,
            fieldProbe = "downloads.dialog.count",
            submitProbe = "downloads.dialog.confirm",
        )
        is DownloadDialog.Confirm -> ConfirmDialog(
            dialog.title,
            dialog.message,
            dialog.confirmLabel,
            onConfirm = onConfirm,
            onCancel = onCancel,
            probe = "downloads.dialog",
            destructive = dialog.destructive,
            cancelLabel = dialog.cancelLabel,
            content = dialog.switch?.let { switch -> { DialogSwitch(switch, onToggle) } },
        )
    }
}

@Composable
private fun DialogSwitch(switch: DownloadDialogSwitch, onToggle: (Boolean) -> Unit) {
    PlezyToggleSurface(switch.value, onToggle, Modifier.fillMaxWidth().layoutProbe("downloads.dialog.switch"), shape = RoundedCornerShape(12.dp)) {
        Row(
            Modifier.heightIn(min = 56.dp).padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            switch.icon?.vector?.let { Icon(it, contentDescription = null, Modifier.size(22.dp)) }
            Column(Modifier.weight(1f)) {
                Text(switch.label, style = MaterialTheme.typography.bodyLarge)
                switch.subtitle?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted) }
            }
            RowSwitch(switch.value)
        }
    }
}

/** Deleting a download that takes a while: its progress, or a loading indicator until it is known. Not dismissible. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun DeletionProgressDialog(dialog: DeletionDialog) {
    ModalOverlay(title = null, onDismiss = {}) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            if (dialog.fraction == null) LoadingIndicator(Modifier.size(24.dp))
            Text(dialog.label, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f).layoutProbe("downloads.deleting", reportsFocus = false))
            dialog.percentLabel?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted) }
        }
        dialog.fraction?.let { fraction ->
            LinearProgressIndicator(progress = { fraction }, modifier = Modifier.fillMaxWidth().padding(top = 16.dp))
        }
        dialog.operation?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, modifier = Modifier.padding(top = 8.dp)) }
    }
}

/** Why downloads may stop in the background, with the fix (or, before a download, the choice to go on anyway). */
@Composable
fun BackgroundWarningDialogView(dialog: BackgroundWarningDialog, onDismiss: () -> Unit, onFix: () -> Unit, onHelp: () -> Unit, onProceed: () -> Unit) {
    val fix = remember { FocusRequester() }
    ModalOverlay(dialog.title, onDismiss = onDismiss, initialFocus = fix) {
        Text(dialog.intro, style = MaterialTheme.typography.bodyMedium)
        dialog.reasons.forEach { Text("• $it", style = MaterialTheme.typography.bodyMedium, modifier = Modifier.padding(top = 6.dp)) }
        Text(dialog.helpTitle, style = MaterialTheme.typography.titleSmall, modifier = Modifier.padding(top = 16.dp))
        Text(dialog.helpDescription, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
        PlezyButton(dialog.helpLinkLabel, onClick = onHelp, style = ButtonStyle.TEXT, modifier = Modifier.padding(top = 4.dp))
        OverlayActions(Modifier.padding(top = 16.dp), primary = fix) {
            PlezyButton(dialog.dismissLabel, onClick = if (dialog.preFlight) onProceed else onDismiss)
            PlezyButton(dialog.fixLabel, onClick = onFix, style = ButtonStyle.PRIMARY, modifier = Modifier.focusRequester(fix))
        }
    }
}

/**
 * The glyph of a download choice's row ([DownloadDialogIcon]), the same thing the Apple app's symbol shows; none for a
 * version or a quality, as no version or quality list carries icons.
 */
internal val DownloadDialogIcon.vector: ImageVector?
    get() = when (this) {
        DownloadDialogIcon.DOWNLOAD -> PlezyIcons.Download
        DownloadDialogIcon.UNWATCHED -> PlezyIcons.VisibilityOff
        DownloadDialogIcon.NEXT_5, DownloadDialogIcon.NEXT_10 -> PlezyIcons.SkipNext
        DownloadDialogIcon.CUSTOM -> PlezyIcons.Tune
        DownloadDialogIcon.DELETE -> PlezyIcons.Delete
        DownloadDialogIcon.SYNC -> PlezyIcons.Sync
        DownloadDialogIcon.SPECIALS -> PlezyIcons.StarBorder
        DownloadDialogIcon.VERSION, DownloadDialogIcon.QUALITY -> null
    }
