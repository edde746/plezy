package com.edde746.plezy.presentation.settings

import com.edde746.plezy.crash.StartupFailures
import com.edde746.plezy.app.AppPlatform
import com.edde746.plezy.image.ArtworkDiagnosticsLog
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogBuffer
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Advanced → View Logs: this run's log ([LogBuffer]) newest first under a block naming the app, its
 * version and the device. Copy puts the header and the records, oldest first, on the clipboard, trimmed to the newest
 * [MAX_CLIPBOARD_BYTES]; Upload posts the same to Plezy's log relay, trimmed to [MAX_UPLOAD_BYTES], and shows the id
 * it answers; Clear forgets the records. A failed start's record ([StartupFailures.pending]) joins the header, so
 * copies and uploads carry it, and Clear forgets it too.
 */
internal class LogsPage(
    private val http: HttpClient,
    appVersion: String,
    private val platform: AppPlatform,
    private val startupFailures: StartupFailures,
    parentScope: CoroutineScope,
) : LogsStore {
    private val scope = parentScope.childScope()
    private val mutableEvents = Channel<SettingsEvent>(Channel.BUFFERED)
    override val events: Flow<SettingsEvent> = mutableEvents.receiveAsFlow()

    private val deviceBlock = buildString {
        val device = platform.device
        appendLine("${T.app.title} v$appVersion")
        val diagnostics = platform.diagnostics()
        if (diagnostics.isEmpty()) {
            appendLine("${device.platform} ${device.platformVersion}")
            device.deviceModel?.let { appendLine(it) }
        } else {
            diagnostics.forEach { appendLine(it) }
        }
        if (device.isTv || platform.formFactor == com.edde746.plezy.model.FormFactor.TV) appendLine("TV mode: yes")
        ArtworkDiagnosticsLog.headerLines.forEach { appendLine(it) }
        val video = platform.videoCapabilities()
        appendLine("Display: HDR ${if (video.hdr) "yes" else "no"}, Dolby Vision ${if (video.dolbyVision) "yes" else "no"}")
        appendLine("Video decoders: ${video.hardwareCodecs.sorted().joinToString().ifEmpty { "none reported" }}")
    }.trimEnd()

    /** The device block, then the failed start's record while there is one. */
    private val header: String
        get() = startupFailures.pending?.let { "$deviceBlock\n\n${it.describe()}" } ?: deviceBlock

    private var records: List<LogBuffer.Entry> = LogBuffer.snapshot()
    private var uploading = false

    private val mutableState = MutableStateFlow(buildState())
    override val state: StateFlow<LogsUiState> = mutableState.asStateFlow()

    override fun text(): String = format(MAX_CLIPBOARD_BYTES)

    override fun copy() {
        platform.setClipboardText(text())
        mutableEvents.trySend(SettingsEvent.Message(T.messages.logsCopied))
    }

    override fun refresh() {
        records = LogBuffer.snapshot()
        publish()
    }

    override fun clear() {
        LogBuffer.clear()
        records = emptyList()
        publish()
        if (startupFailures.pending != null) {
            scope.launch {
                startupFailures.clear()
                publish()
            }
        }
        mutableEvents.trySend(SettingsEvent.Message(T.messages.logsCleared))
    }

    override fun upload() {
        if (uploading) return
        uploading = true
        publish()
        val payload = format(MAX_UPLOAD_BYTES)
        scope.launch {
            val event = try {
                SettingsEvent.LogsUploaded(post(payload))
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w("settings", e) { "uploading the logs failed" }
                SettingsEvent.Message(T.messages.logsUploadFailed, error = true)
            }
            uploading = false
            publish()
            mutableEvents.trySend(event)
        }
    }

    override fun release() {
        scope.cancel()
        mutableEvents.close()
    }

    /** Posts [payload] as plain text and returns the id the relay answers (`{"id": …}`). */
    private suspend fun post(payload: String): String {
        val response = http.post(UPLOAD_URL) {
            contentType(ContentType.Text.Plain)
            setBody(payload)
        }
        check(response.status.isSuccess()) { "The log relay answered ${response.status}" }
        val body = Json.parseToJsonElement(response.bodyAsText()) as? JsonObject ?: error("The log relay's answer isn't an object")
        return (body["id"] as? JsonPrimitive)?.takeIf { it.isString }?.content ?: error("The log relay's answer has no id")
    }

    /** The header, then every record oldest first, trimmed to [maxBytes] ([constrainLogPayload]). */
    private fun format(maxBytes: Int): String {
        val logs = records.joinToString("\n") { entry ->
            buildString {
                append("[${localTimeOfDay(entry.epochMillis)}] [${entry.level.name}] ${entry.tag}: ${entry.message}")
                entry.error?.let { append("\nError: ").append(it) }
            }
        }
        return constrainLogPayload("$header\n---\n", logs, maxBytes)
    }

    private fun publish() {
        mutableState.value = buildState()
    }

    private fun buildState() = LogsUiState(
        entries = records.asReversed().map { LogEntryUi(it.epochMillis, it.level.name, it.tag, it.message, it.error) },
        uploading = uploading,
        header = header,
        hasLogs = records.isNotEmpty() || startupFailures.pending != null,
    )

    companion object {
        const val UPLOAD_URL = "https://ice.plezy.app/logs"

        /** What the log relay takes: 1 MiB. */
        const val MAX_UPLOAD_BYTES = 1024 * 1024

        /** What fits the clipboard everywhere (Android's binder caps a transaction near 1 MiB, UTF-16 doubles it). */
        const val MAX_CLIPBOARD_BYTES = 256 * 1024
    }
}

/**
 * [header] then [logs], in at most [maxBytes] of UTF-8: the header whole, and of the logs the newest that fit, from the
 * start of a line, never splitting a character. A header past [maxBytes] is cut at a character's boundary.
 */
internal fun constrainLogPayload(header: String, logs: String, maxBytes: Int): String {
    if (maxBytes <= 0) return ""
    val headerBytes = header.encodeToByteArray()
    if (headerBytes.size >= maxBytes) {
        var end = maxBytes
        while (end > 0 && end < headerBytes.size && (headerBytes[end].toInt() and 0xC0) == 0x80) end--
        return headerBytes.decodeToString(0, end)
    }
    val logBytes = logs.encodeToByteArray()
    val available = maxBytes - headerBytes.size
    if (logBytes.size <= available) return header + logs
    var start = logBytes.size - available
    while (start < logBytes.size && (logBytes[start].toInt() and 0xC0) == 0x80) start++
    val nextLine = (start until logBytes.size).firstOrNull { logBytes[it] == '\n'.code.toByte() }
    if (nextLine != null && nextLine + 1 < logBytes.size) start = nextLine + 1
    return header + logBytes.decodeToString(start, logBytes.size)
}
