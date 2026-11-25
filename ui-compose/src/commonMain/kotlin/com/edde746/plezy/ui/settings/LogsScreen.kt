package com.edde746.plezy.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isMetaPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.format.logClockTime
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.LogEntryUi
import com.edde746.plezy.presentation.settings.LogsStore
import com.edde746.plezy.presentation.settings.SettingIcon
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.use24HourClock
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * Logs ([LogsPage]) of [app]'s log store, kept with [route]: its events' messages and dialogs (an uploaded log's id),
 * and the log read again each time the page shows again.
 */
@Composable
internal fun LogsScreen(app: AppSession, route: Route) {
    val store = retainedStore(app, route, "settings.logs", { app.settings.logs() }, LogsStore::release) ?: return
    val toasts = remember { SettingsToasts() }
    val dialogs = remember { SettingsDialogs() }
    SettingsEvents(app, store.events, toasts, dialogs, store = null)
    ResumeOnReturn(app, route, store::refresh)
    LogsPage(store, toasts, onBack = { app.navigator.back() })
    SettingsDialogsContent(dialogs, app, store = null)
}

/**
 * Logs: the device block, then the app's log, newest first, each entry's time, level and tag over its message and
 * error; Refresh (also Ctrl+R or Cmd+R), Copy, Upload and Clear at the top (the last three while there is a log or a
 * failed start's record); [onBack] leaves. Each entry takes focus, so a remote scrolls through them. The text can be
 * selected, but on TV, where the selection would be a focus stop of its own around the entries: a Back no control
 * takes moves focus out to the nearest stop around it (Compose's default), so the remote's Back would land there
 * instead of leaving the page. Harness names: `settings.logs.<refresh|copy|upload|clear|entry.i>`.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun LogsPage(store: LogsStore, toasts: SettingsToasts, onBack: () -> Unit) {
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    val clock24 = use24HourClock()
    val list = rememberLazyListState()
    SettingsPageFrame(T.screens.logs, hub = false, toasts, onBack, modifier = Modifier.onPreviewKeyEvent { event ->
        val refresh = event.type == KeyEventType.KeyDown && event.key == Key.R && (event.isCtrlPressed || event.isMetaPressed)
        if (refresh) store.refresh()
        refresh
    }, scrolled = { list.canScrollBackward }, actions = {
        PlezyIconButton(PlezyIcons.Refresh, T.common.refresh, store::refresh, Modifier.layoutProbe("settings.logs.refresh"), style = IconButtonStyle.PLAIN)
        PlezyIconButton(SettingSymbols.ContentCopy, T.logs.copyLogs, store::copy, Modifier.layoutProbe("settings.logs.copy"), style = IconButtonStyle.PLAIN, enabled = state.hasLogs)
        if (state.uploading) {
            LoadingIndicator(Modifier.size(24.dp))
        } else {
            PlezyIconButton(SettingIcon.UPLOAD.vector, T.logs.uploadLogs, store::upload, Modifier.layoutProbe("settings.logs.upload"), style = IconButtonStyle.PLAIN, enabled = state.hasLogs)
        }
        PlezyIconButton(SettingSymbols.Delete, T.logs.clearLogs, store::clear, Modifier.layoutProbe("settings.logs.clear"), style = IconButtonStyle.PLAIN, enabled = state.hasLogs)
    }) {
        if (!state.hasLogs) {
            EmptyState(T.messages.noLogsAvailable, icon = SettingIcon.ARTICLE.vector)
        } else {
            val entries = @Composable {
                SettingsList(state = list) {
                    if (state.header.isNotEmpty()) {
                        item(key = "header") {
                            Text(state.header, Modifier.padding(horizontal = 4.dp, vertical = 8.dp), style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace), color = PlezyColors.TextMuted)
                        }
                    }
                    itemsIndexed(state.entries) { index, entry -> LogEntry(entry, clock24, Modifier.rememberFocus(memory, "entry.$index").layoutProbe("settings.logs.entry.$index")) }
                }
            }
            if (tv) entries() else SelectionContainer { entries() }
        }
    }
    RestoreFocus(memory, ready = state.entries.isNotEmpty(), fallback = "entry.0")
}

/** One log entry: time (on the platform's 12/24-hour clock), level (in its colour) and tag, then the message and the error, monospace. */
@Composable
private fun LogEntry(entry: LogEntryUi, use24HourClock: Boolean, modifier: Modifier) {
    val time = remember(entry.epochMillis, use24HourClock) { logClockTime(entry.epochMillis, use24HourClock) }
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    Column(
        modifier
            .fillMaxWidth()
            .focusable(interactionSource = interactions)
            .background(if (focused) PlezyColors.SurfaceHighest else PlezyColors.SurfaceHigh, MaterialTheme.shapes.medium)
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(time, style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace), color = PlezyColors.TextMuted)
            Text(entry.level, style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold), color = levelColor(entry.level))
            Text(entry.tag, style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace), color = PlezyColors.TextMuted)
        }
        Text(entry.message, style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace))
        entry.error?.let { Text(it, style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace), color = PlezyColors.Error) }
    }
}

/** A level's colour: errors red, warnings amber, the rest muted. */
@Composable
private fun levelColor(level: String): Color = when (level.uppercase()) {
    "ERROR", "FATAL", "E" -> PlezyColors.Error
    "WARNING", "WARN", "W" -> Color(0xFFFFB300)
    else -> PlezyColors.TextMuted
}
