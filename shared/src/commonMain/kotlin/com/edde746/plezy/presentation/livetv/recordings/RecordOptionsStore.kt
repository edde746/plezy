package com.edde746.plezy.presentation.livetv.recordings

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.MediaSubscriptionCreateRequest
import com.edde746.plezy.livetv.SubscriptionSetting
import com.edde746.plezy.livetv.liveTvDvr
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.plex.PlexMetadataType
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.ServerSettings
import com.edde746.plezy.settings.ServerSettingsRepository
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** What a Record Options sheet edits. */
sealed interface RecordOptionsMode {
    /** A new rule for the airing titled [headerTitle], from its template [entries] (episode, series…). */
    data class Create(val headerTitle: String, val entries: List<MediaSubscription>) : RecordOptionsMode

    /** The existing [rule]'s settings. */
    data class Edit(val rule: MediaSubscription) : RecordOptionsMode
}

/**
 * The Record Options sheet: "Record options" (or "Edit rule") over [subtitle]; [entries] chips when the template offers
 * several; the [target] library row; one row per visible setting ([settings]), or [emptyText] when there are none;
 * Cancel and [saveLabel], disabled while [saving].
 */
data class RecordOptionsUiState(
    val title: String,
    val subtitle: String,
    val entries: List<RecordEntryChip>,
    val target: RecordTargetUi?,
    val settings: List<RecordSettingRow>,
    val emptyText: String?,
    val saveLabel: String,
    val cancelLabel: String,
    val saving: Boolean,
)

data class RecordEntryChip(val title: String, val selected: Boolean)

/** "Save to" and the library a recording lands in; [options] lists the libraries to pick from, empty when there is no choice. */
data class RecordTargetUi(val label: String, val value: String, val options: List<RecordTargetOption>)

data class RecordTargetOption(val sectionId: Int, val title: String, val selected: Boolean)

/** One editable recording option. */
sealed interface RecordSettingRow {
    val id: String
    val label: String
    val summary: String?

    /** A switch ([RecordOptionsStore.setToggle]). */
    data class Toggle(override val id: String, override val label: String, override val summary: String?, val checked: Boolean) : RecordSettingRow

    /** A picker showing [value] ([RecordOptionsStore.setChoice]). */
    data class Choice(
        override val id: String,
        override val label: String,
        override val summary: String?,
        val value: String,
        val options: List<RecordChoiceOption>,
    ) : RecordSettingRow

    /** A text field ([RecordOptionsStore.setText]); [numeric] fields take an optional `-` then digits. */
    data class Field(override val id: String, override val label: String, override val summary: String?, val text: String, val numeric: Boolean) :
        RecordSettingRow
}

data class RecordChoiceOption(val value: String, val label: String, val selected: Boolean)

/**
 * The Record Options sheet's state: creating a recording rule from a template entry, or editing a rule's settings.
 *
 * Only changed settings are sent: a value equal to the setting's baseline (its value, else its default) or a cleared
 * number drops the edit. Creating needs a target library when the template names one or Plex offers eligible libraries
 * (movie or show sections, not shared, numeric ids; never Jellyfin's or Emby's); the target is the explicit pick, else
 * the pick last saved for this server and rule type (when still eligible), else the template's. Only an explicit pick
 * is remembered. The sheet ends through [onClose] with its [RecordOutcome].
 */
class RecordOptionsStore(
    private val client: MediaBackend,
    private val serverSettings: ServerSettingsRepository,
    private val mode: RecordOptionsMode,
    parentScope: CoroutineScope,
    private val onClose: (RecordOutcome) -> Unit,
) {
    private val scope = parentScope.childScope()
    private val entries: List<MediaSubscription> = when (mode) {
        is RecordOptionsMode.Create -> mode.entries
        is RecordOptionsMode.Edit -> listOf(mode.rule)
    }
    private val isEdit = mode is RecordOptionsMode.Edit
    private var entry: MediaSubscription = entries.firstOrNull { it.selected == true } ?: entries.first()
    private val dirtyPrefs = LinkedHashMap<String, Any?>()
    private var libraries: List<MediaLibrary> = emptyList()
    private var savedSections: Map<Int, Int> = emptyMap()
    private var selectedSectionId: Int? = null
    private var saving = false
    private var closed = false

    private val mutableState = MutableStateFlow(snapshot())
    val state: StateFlow<RecordOptionsUiState> = mutableState.asStateFlow()

    init {
        if (!isEdit) scope.launch { loadTargets() }
    }

    /** Shows the template entry at [index] of [RecordOptionsUiState.entries], dropping the edits and the library pick. */
    fun selectEntry(index: Int) {
        val next = entries.getOrNull(index) ?: return
        if (next === entry || saving) return
        entry = next
        dirtyPrefs.clear()
        selectedSectionId = null
        publish()
    }

    fun selectTarget(sectionId: Int) {
        if (eligibleLibraries().none { it.id == sectionId.toString() }) return
        selectedSectionId = sectionId
        publish()
    }

    fun setToggle(id: String, checked: Boolean) = setPref(id, checked)

    fun setChoice(id: String, value: String) = setPref(id, value)

    /** A text field's new [text]: a number for numeric settings (empty restores the baseline), else the text itself. */
    fun setText(id: String, text: String) {
        val setting = setting(id) ?: return
        if (setting.type == "int") {
            if (!NUMERIC_INPUT.matches(text)) return
            setPref(id, text.toIntOrNull())
        } else {
            setPref(id, text)
        }
    }

    fun cancel() {
        if (saving) return
        close(RecordOutcome.CANCELLED)
    }

    fun save() {
        if (saving || closed) return
        val dvr = client.liveTvDvr ?: return close(RecordOutcome.FAILED)
        val eligible = if (isEdit) emptyList() else eligibleLibraries()
        val targetSectionId = if (isEdit) null else effectiveSectionId(eligible)
        val requiresTarget = !isEdit && (entry.targetLibrarySectionId != null || eligible.isNotEmpty())
        if (requiresTarget && targetSectionId == null) return close(RecordOutcome.TARGET_MISSING)
        val prefs = LinkedHashMap(dirtyPrefs)
        val saved = entry
        val pick = selectedSectionId
        saving = true
        publish()
        scope.launch {
            val outcome = try {
                if (mode is RecordOptionsMode.Edit) {
                    if (mode.rule.key.isEmpty()) {
                        RecordOutcome.FAILED
                    } else {
                        dvr.updateRecordingRule(mode.rule.key, saved.validatePrefs(prefs))
                        RecordOutcome.UPDATED
                    }
                } else {
                    dvr.createRecordingRule(MediaSubscriptionCreateRequest.fromTemplate(saved, targetLibrarySectionId = targetSectionId, prefs = prefs))
                    val type = saved.type
                    if (pick != null && type != null) serverSettings.set(client.serverId.value, ServerSettings.dvrTargetSection(type), pick)
                    RecordOutcome.SCHEDULED
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Saving recording rule failed" }
                recordOutcomeOf(e)
            }
            saving = false
            close(outcome)
        }
    }

    fun release() = scope.cancel()

    private fun close(outcome: RecordOutcome) {
        if (closed) return
        closed = true
        onClose(outcome)
    }

    private suspend fun loadTargets() {
        val types = entries.mapNotNull { it.type }.distinct()
        try {
            savedSections = types.associateWith { serverSettings.value(client.serverId.value, ServerSettings.dvrTargetSection(it)) }
            publish()
            libraries = client.fetchLibraries()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // The row then shows the template's library, read only.
            Log.w(TAG, e) { "Libraries for the recording target failed" }
        }
        publish()
    }

    private fun setting(id: String): SubscriptionSetting? = entry.settings.firstOrNull { it.id == id }

    private fun setPref(id: String, value: Any?) {
        val setting = setting(id) ?: return
        if ((setting.type == "int" && value == null) || sameValue(value, baseline(setting))) {
            dirtyPrefs.remove(id)
        } else {
            dirtyPrefs[id] = value
        }
        publish()
    }

    private fun baseline(setting: SubscriptionSetting): Any? = setting.value ?: setting.defaultValue

    private fun current(setting: SubscriptionSetting): Any? = if (setting.id in dirtyPrefs) dirtyPrefs[setting.id] else baseline(setting)

    /** The library kind a recording of the entry's type lands in. */
    private fun entryLibraryKind(): MediaKind? = when (entry.type) {
        PlexMetadataType.MOVIE -> MediaKind.MOVIE
        PlexMetadataType.SHOW, PlexMetadataType.SEASON, PlexMetadataType.EPISODE -> MediaKind.SHOW
        else -> null
    }

    private fun eligibleLibraries(): List<MediaLibrary> {
        val kind = entryLibraryKind()
        if (kind == null || client.backend != BackendKind.PLEX) return emptyList()
        return libraries.filter { it.kind == kind && !it.isShared && it.id.toIntOrNull() != null }
    }

    private fun savedSectionId(eligible: List<MediaLibrary>): Int? {
        val saved = entry.type?.let { savedSections[it] } ?: return null
        if (saved <= 0) return null
        return saved.takeIf { id -> eligible.any { it.id == id.toString() } }
    }

    private fun effectiveSectionId(eligible: List<MediaLibrary>): Int? =
        selectedSectionId ?: savedSectionId(eligible) ?: entry.targetLibrarySectionId

    private fun publish() {
        mutableState.value = snapshot()
    }

    private fun snapshot(): RecordOptionsUiState {
        val eligible = if (isEdit) emptyList() else eligibleLibraries()
        val target = effectiveSectionId(eligible)
        val targetLabel = if (isEdit) {
            entry.librarySectionTitle.orEmpty()
        } else {
            eligible.firstOrNull { it.id == target?.toString() }?.title ?: entry.librarySectionTitle.orEmpty()
        }
        val visible = entry.settings.filter { !it.hidden && !it.advanced }
        return RecordOptionsUiState(
            title = if (isEdit) T.liveTv.editRule else T.liveTv.recordOptions,
            subtitle = when (mode) {
                is RecordOptionsMode.Create -> mode.headerTitle
                is RecordOptionsMode.Edit -> mode.rule.title.orEmpty()
            },
            entries = if (entries.size > 1) entries.map { RecordEntryChip(it.title.orEmpty(), it === entry) } else emptyList(),
            target = if (targetLabel.isNotEmpty() || eligible.size > 1) {
                RecordTargetUi(
                    label = T.liveTv.saveTo,
                    value = targetLabel,
                    options = if (eligible.size > 1) eligible.map { RecordTargetOption(it.id.toInt(), it.title, it.id == target?.toString()) } else emptyList(),
                )
            } else {
                null
            },
            settings = visible.map(::row),
            emptyText = if (visible.isEmpty()) entry.airingsType.orEmpty() else null,
            saveLabel = if (isEdit) T.common.save else T.liveTv.record,
            cancelLabel = T.common.cancel,
            saving = saving,
        )
    }

    private fun row(setting: SubscriptionSetting): RecordSettingRow {
        val label = setting.label ?: setting.id
        val value = current(setting)
        val options = setting.options
        return when {
            setting.type == "bool" -> RecordSettingRow.Toggle(setting.id, label, setting.summary, asBoolean(value))
            setting.type == "int" && options.isNotEmpty() -> {
                val text = value?.toString().orEmpty()
                RecordSettingRow.Choice(
                    id = setting.id,
                    label = label,
                    summary = setting.summary,
                    value = options.firstOrNull { it.value == text }?.label ?: text,
                    options = options.map { RecordChoiceOption(it.value, it.label, it.value == text) },
                )
            }
            else -> RecordSettingRow.Field(setting.id, label, setting.summary, value?.toString().orEmpty(), numeric = setting.type == "int")
        }
    }

    private companion object {
        const val TAG = "RecordOptionsStore"
        val NUMERIC_INPUT = Regex("-?\\d*")

        fun sameValue(a: Any?, b: Any?): Boolean = if (a == null || b == null) a == null && b == null else a.toString() == b.toString()

        fun asBoolean(value: Any?): Boolean = when (value) {
            is Boolean -> value
            is Number -> value.toDouble() != 0.0
            is String -> value.lowercase().let { it == "true" || it == "1" }
            else -> false
        }
    }
}
