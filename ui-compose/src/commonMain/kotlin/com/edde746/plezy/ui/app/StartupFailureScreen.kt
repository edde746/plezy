package com.edde746.plezy.ui.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.edde746.plezy.crash.LogUpload
import com.edde746.plezy.crash.StartupFailureRecord
import com.edde746.plezy.data.DataFault
import com.edde746.plezy.log.Log
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

/**
 * The start failed ([com.edde746.plezy.crash.StartupFailedException], or
 * [com.edde746.plezy.app.RootScreen.Failed]): what failed (`phase · error type`), Retry (focused), which starts
 * again, Copy details, the record's [StartupFailureRecord.describe] block, and Upload details, which sends that block
 * to the log relay ([LogUpload]) and shows the Log ID it answers. The record is already kept for the next start, which
 * sends it and shows it on the Logs screen.
 *
 * When the app's saved data is what failed ([StartupFailureRecord.dataFault]) and the platform can reset it
 * ([onReset]), the screen says so and what a reset removes, and offers Reset app data: first, focused, for data it
 * can't read; after Retry for data a newer version wrote, which updating the app opens. The reset runs once the user
 * confirms; [onReset] starts the app again when it's done, and a failure says so here.
 */
@OptIn(androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
@Suppress("DEPRECATION")
@Composable
fun StartupFailureScreen(failure: StartupFailureRecord, onRetry: () -> Unit, onReset: (suspend () -> Unit)? = null) {
    val clipboard = LocalClipboardManager.current
    val retry = remember { FocusRequester() }
    val reset = remember { FocusRequester() }
    val scope = rememberCoroutineScope()
    var uploading by remember { mutableStateOf(false) }
    // The Log ID, or the failure's message; null before an upload.
    var upload by remember { mutableStateOf<Result<String>?>(null) }
    val fault = failure.dataFault?.takeIf { onReset != null }
    var confirming by remember { mutableStateOf(false) }
    var resetting by remember { mutableStateOf(false) }
    var resetFailed by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { (if (fault == DataFault.UNREADABLE) reset else retry).requestFocus() }
    val resetButton = @Composable {
        PlezyButton(
            T.startup.resetData, { confirming = true }, Modifier.focusRequester(reset).layoutProbe("startup.reset"),
            style = if (fault == DataFault.UNREADABLE) ButtonStyle.PRIMARY else ButtonStyle.SECONDARY,
            icon = PlezyIcons.DeleteForever, enabled = !resetting,
        )
    }
    // The confirmation is a dialog of this screen's own: the app's overlay host isn't there yet.
    OverlayHostBox(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).layoutProbe("startup.screen", reportsFocus = false)) {
        Box(Modifier.fillMaxSize().verticalScroll(rememberScrollState()), contentAlignment = Alignment.Center) {
            Column(
                Modifier.widthIn(max = 560.dp).padding(horizontal = 24.dp, vertical = 32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(PlezyIcons.ErrorOutline, null, Modifier.size(48.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(16.dp))
                val (title, body) = when (fault) {
                    DataFault.UNREADABLE -> T.startup.dataUnreadableTitle to T.startup.dataUnreadableBody
                    DataFault.NEWER -> T.startup.dataNewerTitle to T.startup.dataNewerBody
                    null -> T.startup.failedTitle to T.startup.failedBody
                }
                Text(title, Modifier.layoutProbe("startup.title"), style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
                Spacer(Modifier.height(8.dp))
                Text(body, style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
                if (fault != null) {
                    Spacer(Modifier.height(8.dp))
                    Text(
                        T.startup.resetExplanation, style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Spacer(Modifier.height(16.dp))
                Text(
                    "${T.startup.phaseLabel}: ${failure.phaseId} · ${failure.errorType}",
                    Modifier.layoutProbe("startup.failure"),
                    style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(20.dp))
                FlowRow(horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (fault == DataFault.UNREADABLE) resetButton()
                    PlezyButton(
                        T.common.retry, onRetry, Modifier.focusRequester(retry).layoutProbe("startup.retry"),
                        style = if (fault == DataFault.UNREADABLE) ButtonStyle.SECONDARY else ButtonStyle.PRIMARY, icon = PlezyIcons.Refresh,
                        enabled = !resetting,
                    )
                    if (fault == DataFault.NEWER) resetButton()
                    PlezyButton(
                        T.startup.copyDetails, { clipboard.setText(AnnotatedString(failure.describe())) },
                        Modifier.layoutProbe("startup.copy"), icon = PlezyIcons.ContentCopy,
                    )
                    PlezyButton(
                        T.startup.uploadDetails,
                        {
                            uploading = true
                            scope.launch {
                                upload = try {
                                    Result.success(LogUpload.upload(failure.describe(), failure.appVersion))
                                } catch (e: CancellationException) {
                                    throw e
                                } catch (e: Exception) {
                                    Log.w(TAG, e) { "Startup diagnostics upload failed" }
                                    Result.failure(e)
                                } finally {
                                    uploading = false
                                }
                            }
                        },
                        Modifier.layoutProbe("startup.upload"), icon = PlezyIcons.Send, enabled = !uploading,
                    )
                }
                if (resetFailed) {
                    Spacer(Modifier.height(16.dp))
                    Text(
                        T.startup.resetFailed, Modifier.layoutProbe("startup.resetFailed"),
                        color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium,
                    )
                }
                upload?.let { result ->
                    Spacer(Modifier.height(16.dp))
                    result.onSuccess { id ->
                        Text("${T.messages.logsUploaded} · ${T.messages.logId}:", style = MaterialTheme.typography.bodyMedium)
                        SelectionContainer {
                            Text(
                                id, Modifier.layoutProbe("startup.logId"),
                                style = MaterialTheme.typography.titleMedium.copy(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold),
                            )
                        }
                    }.onFailure {
                        Text(T.messages.logsUploadFailed, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
        }
        if (confirming && onReset != null) {
            ConfirmDialog(
                title = T.startup.resetConfirmTitle,
                message = T.startup.resetExplanation,
                confirmLabel = T.common.reset,
                onConfirm = {
                    confirming = false
                    resetting = true
                    resetFailed = false
                    scope.launch {
                        try {
                            onReset()
                        } catch (e: CancellationException) {
                            throw e
                        } catch (e: Exception) {
                            Log.e(TAG, e) { "Resetting the app's data failed" }
                            resetFailed = true
                        } finally {
                            resetting = false
                        }
                    }
                },
                onCancel = { confirming = false },
                probe = "startup.resetConfirm",
            )
        }
    }
}

private const val TAG = "startup"
