package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.MpvPreset
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlin.time.Clock

/**
 * mpv.conf: one document, `mpv_config_text`, edited whole or (TV) line by line. Edits are written
 * [DEBOUNCE_MILLIS] after the last one, one full-document write at a time, the latest last; [flush] writes what is
 * pending at once (leaving the page, a preset). A write that fails stays pending and says so. A change made elsewhere
 * (an import, a reset) replaces the editor's text, and one arriving during a write is queued after it, so the older
 * write never ends up stored. Presets save the document under a name (the same name replaces it), load it back,
 * and delete it. On Linux the options the video plane ignores are named.
 */
internal class MpvConfigPage(
    private val settings: DeviceSettingsRepository,
    facts: SettingsFacts,
    private val clock: Clock,
    private val parentScope: CoroutineScope,
) : MpvConfigStore {
    private val scope = parentScope.childScope()
    private val mutableMessages = Channel<SettingsEvent.Message>(Channel.BUFFERED)
    override val messages: Flow<SettingsEvent.Message> = mutableMessages.receiveAsFlow()

    private val linuxNote = if (facts.linux) T.mpvConfig.embeddedVoHint else null
    private val lineEditor = facts.tv

    private class Queued(val text: String, val revision: Int)

    private var text = ""
    private var presets: List<MpvPreset> = emptyList()

    /** The text known stored, and the revision it was edited at. */
    private var persisted = ""
    private var persistedRevision = 0
    private var revision = 0
    private var pending: Queued? = null
    private var active: Queued? = null
    private var debounce: Job? = null
    private var drain: CompletableDeferred<Boolean>? = null

    /** What this page stored lately: their observation is no change from elsewhere. */
    private val written = ArrayDeque<String>()

    private val mutableState = MutableStateFlow(buildState())
    override val state: StateFlow<MpvConfigUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            var first = true
            settings.observe(AppSettings.mpvConfigText).collect { stored ->
                if (first) {
                    first = false
                    text = stored
                    persisted = stored
                    publish()
                } else {
                    observed(stored)
                }
            }
        }
        scope.launch {
            settings.observe(AppSettings.mpvConfigPresets).collect {
                presets = it
                publish()
            }
        }
    }

    override fun edit(text: String) {
        this.text = text
        publish()
        queue(text)
    }

    /** A row's new text; a pasted value with line breaks becomes rows from [index] on. */
    override fun editLine(index: Int, text: String) {
        val lines = lines().toMutableList()
        require(index in lines.indices) { "No line $index" }
        val parts = text.replace("\r\n", "\n").replace('\r', '\n').split('\n')
        lines[index] = parts.first()
        lines.addAll(index + 1, parts.drop(1))
        edit(lines.joinToString("\n"))
    }

    override fun addLine() = edit((lines() + "").joinToString("\n"))

    /** Removes a row; removing the only one clears it (the document always has one). */
    override fun removeLine(index: Int) {
        val lines = lines().toMutableList()
        require(index in lines.indices) { "No line $index" }
        if (lines.size == 1) lines[0] = "" else lines.removeAt(index)
        edit(lines.joinToString("\n"))
    }

    override suspend fun flush(): Boolean {
        debounce?.cancel()
        drain?.let { return it.await() }
        val run = CompletableDeferred<Boolean>()
        drain = run
        try {
            run.complete(drainPending())
        } finally {
            // Cancelled mid-write: the callers waiting on this drain are told it didn't save.
            run.complete(false)
            drain = null
        }
        return run.await()
    }

    override fun savePreset(name: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty() || text.isBlank()) return
        scope.launch {
            if (!flush()) return@launch
            val saved = guarded("saving the mpv preset") {
                val preset = MpvPreset(trimmed, text, clock.now().toString())
                settings.update(AppSettings.mpvConfigPresets) { list -> list.filter { it.name != trimmed } + preset }
            }
            if (saved) send(T.mpvConfig.presetSaved)
        }
    }

    override fun loadPreset(name: String) {
        val preset = presets.firstOrNull { it.name == name } ?: throw IllegalArgumentException("No preset $name")
        edit(preset.text)
        scope.launch { if (flush()) send(T.mpvConfig.presetLoaded) }
    }

    override fun deletePreset(name: String) {
        scope.launch {
            val deleted = guarded("deleting the mpv preset") {
                settings.update(AppSettings.mpvConfigPresets) { list -> list.filter { it.name != name } }
            }
            if (deleted) send(T.mpvConfig.presetDeleted)
        }
    }

    /** Ends the page; an edit still pending or being written is stored as it stands now. */
    override fun release() {
        debounce?.cancel()
        if (pending != null || active != null) {
            val latest = text
            parentScope.launch {
                try {
                    settings.set(AppSettings.mpvConfigText, latest)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.e("settings", e) { "saving mpv.conf as the page closed failed" }
                }
            }
        }
        scope.cancel()
        mutableMessages.close()
    }

    private fun lines(): List<String> = text.split('\n')

    private fun queue(text: String) {
        if (active == null && pending == null && text == persisted) return
        pending = Queued(text, ++revision)
        debounce?.cancel()
        debounce = scope.launch {
            delay(DEBOUNCE_MILLIS)
            // flush() cancels the pending debounce: this one, which is running it.
            debounce = null
            flush()
        }
    }

    private suspend fun drainPending(): Boolean {
        while (true) {
            val next = pending ?: return true
            pending = null
            active = next
            remember(next.text)
            val saved = guarded("saving mpv.conf") { settings.set(AppSettings.mpvConfigText, next.text) }
            active = null
            if (!saved) {
                if (pending == null) pending = next
                return false
            }
            if (next.revision >= persistedRevision) {
                persistedRevision = next.revision
                persisted = next.text
            }
        }
    }

    /** The stored text changed: from elsewhere unless it is what this page stored. */
    private fun observed(stored: String) {
        if (stored == persisted || stored in written || active?.text == stored) return
        debounce?.cancel()
        val change = ++revision
        written.clear()
        persisted = stored
        persistedRevision = change
        // A write in flight can't be taken back: the change is written after it, so it stays the last.
        pending = if (active == null) null else Queued(stored, change)
        text = stored
        publish()
    }

    private fun remember(text: String) {
        written.addLast(text)
        while (written.size > REMEMBERED_WRITES) written.removeFirst()
    }

    private suspend fun guarded(what: String, block: suspend () -> Unit): Boolean = try {
        block()
        true
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e("settings", e) { "$what failed" }
        send(T.settings.saveFailed, error = true)
        false
    }

    private fun send(text: String, error: Boolean = false) {
        mutableMessages.trySend(SettingsEvent.Message(text, error))
    }

    private fun publish() {
        mutableState.value = buildState()
    }

    private fun buildState() = MpvConfigUiState(
        text = text,
        lines = lines(),
        presets = presets.map { it.name },
        canSavePreset = text.isNotBlank(),
        linuxNote = linuxNote,
        lineEditor = lineEditor,
    )

    companion object {
        const val DEBOUNCE_MILLIS = 400L
        private const val REMEMBERED_WRITES = 16
    }
}
