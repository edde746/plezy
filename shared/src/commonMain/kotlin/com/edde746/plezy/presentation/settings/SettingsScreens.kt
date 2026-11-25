package com.edde746.plezy.presentation.settings

import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.Hotkey
import com.edde746.plezy.settings.HotkeyModifier
import com.edde746.plezy.settings.Hotkeys
import com.edde746.plezy.settings.ThemeMode
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

// The UI states and intents of the settings screens that aren't row pages. Each store: main thread, `release()` ends it.

/** Theme picker: groups of theme rows; [focusedMode] autofocuses in keyboard mode. */
data class ThemePickerUiState(val groups: List<ThemeGroup>, val focusedMode: ThemeMode)

data class ThemeGroup(val id: String, val header: String?, val rows: List<ThemeRowUi>)

/**
 * One theme. [palette] is its swatch (null: Custom not created yet, an empty "+" slot); [splitPalette] the System
 * row's dark half. [selected] follows what paints. [note] "Saved — unlocks with Supporter", or Custom's "Choose every
 * color yourself" (picking Custom opens its editor). [value], beside the title: Custom's "Not created" until one is
 * saved.
 */
data class ThemeRowUi(
    val mode: ThemeMode,
    val label: String,
    val palette: Palette?,
    val splitPalette: Palette? = null,
    val selected: Boolean,
    val locked: Boolean,
    val note: String?,
    val value: String? = null,
)

sealed interface ThemePickerEvent {
    data object OpenEditor : ThemePickerEvent
    data object OpenSupporter : ThemePickerEvent
}

/** Custom theme editor ([CustomThemeEditorPage]). Colours are `#AARRGGBB` upper case. */
data class CustomThemeEditorUiState(
    val draft: Palette,
    val slots: List<ColorSlotUi>,
    val selectedSlot: Int,
    /** The selected slot's hex field text and whether it is invalid (the hint shows as error). */
    val hexText: String,
    val hexInvalid: Boolean,
    val hue: Float,
    val saturation: Float,
    val brightness: Float,
    val opacity: Float,
    val quickSwatches: List<String>,
    val startFromOptions: List<SettingChoiceOption>,
    val warnings: List<String>,
    val dirty: Boolean,
    /** Save runs: the actions wait. */
    val saving: Boolean = false,
    /** The palette and the theme were stored: the editor closes. */
    val saved: Boolean = false,
)

data class ColorSlotUi(val id: String, val label: String, val hex: String)

/** mpv.conf ([MpvConfigStore]): the document, the presets, the Linux note. */
data class MpvConfigUiState(
    val text: String,
    /** [text] as the TV line editor's rows. */
    val lines: List<String>,
    val presets: List<String>,
    val canSavePreset: Boolean,
    val linuxNote: String?,
    val lineEditor: Boolean,
)

interface MpvConfigStore {
    val state: StateFlow<MpvConfigUiState>
    val messages: Flow<SettingsEvent.Message>

    /** The whole document as typed; saved debounced. */
    fun edit(text: String)
    fun editLine(index: Int, text: String)
    fun addLine()
    fun removeLine(index: Int)

    /** Persists what is pending; false when the write failed (leaving stays). */
    suspend fun flush(): Boolean
    fun savePreset(name: String)
    fun loadPreset(name: String)
    fun deletePreset(name: String)
    fun release()
}

/** External player ([ExternalPlayerPage]). */
data class ExternalPlayerUiState(
    val enabled: Boolean,
    val players: List<ExternalPlayerRowUi>,
    val custom: List<ExternalPlayerRowUi>,
    /** The custom player dialog: whether it offers Command/URL Scheme and the value field's label and hint per type. */
    val customTypes: List<SettingChoiceOption>,
    val customValueHint: Map<String, String>,
)

data class ExternalPlayerRowUi(val id: String, val name: String, val iconAsset: String?, val selected: Boolean, val systemDefault: Boolean)

/** Keyboard shortcuts ([KeyboardShortcutsPage]): one row per action in default order. */
data class KeyboardShortcutsUiState(val rows: List<ShortcutRowUi>)

/** [keys] the formatted hotkey ("Ctrl + →"), or "No shortcut set". */
data class ShortcutRowUi(val actionId: String, val title: String, val keys: String, val unset: Boolean)

enum class ShortcutResult {
    SAVED,
    CONFLICT,
    FAILED,
    ;

    /** The recorder dialog closes after a save or a conflict (its message on the page); a failure keeps it to retry. */
    val closesRecorder: Boolean get() = this != FAILED
}

/**
 * The recorder dialog's edit: [keys] the shortcut it would save ("No shortcut set" when [unset]), [saving] while Save
 * runs, [failed] after storing failed. Save is there ([canSave]) for a shortcut, or for a Clear, and not while saving.
 */
data class ShortcutRecorderUiState(val keys: String, val unset: Boolean, val edited: Boolean, val saving: Boolean, val failed: Boolean) {
    val canSave: Boolean get() = (!unset || edited) && !saving
}

/**
 * One recorder dialog: a captured key ([capture]) or Clear ([clear]) is only the dialog's edit until [save] stores it.
 * Save closes the dialog ([ShortcutResult.closesRecorder]) once stored, or when another action has the shortcut ("Shortcut
 * already assigned to …", nothing changes); after a failure ("Error") it stays to retry. Cancel discards the edit;
 * nothing edits while a save runs, and a second save meanwhile does nothing.
 */
class ShortcutRecorder internal constructor(
    private val actionId: String,
    current: Hotkey?,
    private val mac: Boolean,
    private val store: KeyboardShortcutsPage,
) {
    private var pending: Hotkey? = current
    private val mutableState = MutableStateFlow(stateOf(edited = false, saving = false, failed = false))
    val state: StateFlow<ShortcutRecorderUiState> = mutableState.asStateFlow()

    /** A key pressed in the dialog: [hidUsage] with [modifiers] (`alt|control|shift|meta`). */
    fun capture(hidUsage: Long, modifiers: Set<String>) {
        if (mutableState.value.saving) return
        pending = Hotkey(hidUsage, modifiers.map { HotkeyModifier.fromId(it) ?: throw IllegalArgumentException("No modifier $it") }.toSet())
        mutableState.value = stateOf(edited = true, saving = false, failed = false)
    }

    /** Marks the action unassigned in the dialog; Save stores it. */
    fun clear() {
        if (mutableState.value.saving) return
        pending = null
        mutableState.value = stateOf(edited = true, saving = false, failed = false)
    }

    /** Stores the edit; null when there is nothing to save or a save is running. */
    suspend fun save(): ShortcutResult? {
        val before = mutableState.value
        if (!before.canSave) return null
        val hotkey = pending
        mutableState.value = before.copy(saving = true, failed = false)
        val result = try {
            if (hotkey == null) store.clear(actionId) else store.record(actionId, hotkey.key, hotkey.modifiers.map { it.id }.toSet())
        } finally {
            mutableState.value = mutableState.value.copy(saving = false)
        }
        if (result == ShortcutResult.FAILED) mutableState.value = mutableState.value.copy(failed = true)
        return result
    }

    private fun stateOf(edited: Boolean, saving: Boolean, failed: Boolean) =
        ShortcutRecorderUiState(Hotkeys.format(pending, mac), pending == null, edited, saving, failed)
}

/**
 * Logs ([LogsStore]): newest first. [header] is the device block shown above them and leading every copy and upload
 * (app, version, OS, device, then a failed start's record); [hasLogs], a log or a failed start's record, enables
 * Copy, Upload and Clear and shows the header.
 */
data class LogsUiState(
    val entries: List<LogEntryUi>,
    val uploading: Boolean,
    val header: String = "",
    val hasLogs: Boolean = entries.isNotEmpty(),
)

/**
 * One log record. Its time is [epochMillis]: the list shows it as [com.edde746.plezy.format.logClockTime] reads it on the
 * platform's 12/24-hour clock, row by row as rows show.
 */
data class LogEntryUi(val epochMillis: Long, val level: String, val tag: String, val message: String, val error: String?)

interface LogsStore {
    val state: StateFlow<LogsUiState>
    val events: Flow<SettingsEvent>

    /** The whole log as text, oldest first after the header, trimmed to its newest 256 KiB for the clipboard. */
    fun text(): String

    /** Copies [text] and confirms it ("Logs copied to clipboard"). */
    fun copy()

    /** Reads the log again (Refresh, Ctrl/Cmd+R). */
    fun refresh()
    fun clear()

    /** Uploads the log; its id comes back as [SettingsEvent.LogsUploaded]. */
    fun upload()
    fun release()
}

/** Open source licenses ([LicensesStore]): every component, sorted by name; [detail] the one opened. */
data class LicensesUiState(val entries: List<LicenseEntryUi>, val detail: LicenseDetailUi?)

data class LicenseEntryUi(val name: String, val license: String, val url: String)

/** One component's licences; [texts] null while they are read. */
data class LicenseDetailUi(val name: String, val license: String, val url: String, val texts: List<LicenseTextUi>?)

/** One licence file: its [title] (its path) and its [paragraphs], reflowed to wrap at any width. */
data class LicenseTextUi(val title: String, val paragraphs: List<String>)
