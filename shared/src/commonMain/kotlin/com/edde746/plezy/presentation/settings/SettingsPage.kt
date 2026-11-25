package com.edde746.plezy.presentation.settings

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/**
 * The settings pages. The hub is the Settings tab's root ([com.edde746.plezy.presentation.navigation.Route.Settings]);
 * every other page is pushed as `Route.SettingsPage(page, arg)`. Pages drawn from rows ([rows]) render through the
 * UIs' one row renderer; the others have their own screens and stores.
 */
enum class SettingsPageId(val rows: Boolean) {
    HUB(true),
    GENERAL(true),
    APPEARANCE(true),
    VIDEO_PLAYBACK(true),
    SUBTITLE_STYLING(true),
    ABOUT(true),

    /** Theme picker: [ThemePickerPage]. */
    THEME(false),

    /** Custom theme editor: [CustomThemeEditorPage]. */
    CUSTOM_THEME(false),

    /** mpv.conf: [MpvConfigStore]. */
    MPV_CONFIG(false),

    /** External player: [ExternalPlayerPage]. */
    EXTERNAL_PLAYER(false),

    /** Keyboard shortcuts: [KeyboardShortcutsPage]. */
    KEYBOARD_SHORTCUTS(false),

    /** Logs: [LogsStore]. */
    LOGS(false),

    /** Manage libraries: the Libraries destination's store ([com.edde746.plezy.app.AppSession.libraries]). */
    MANAGE_LIBRARIES(false),

    /** Open source licenses ([ThirdPartyNotices]); `arg` the package for its detail. */
    LICENSES(false),

    /** Account preferences: the account list or one account's body; `arg` the account key for the detail. */
    ACCOUNT_PREFERENCES(true),
}

/** One row page as the UIs draw it: [title] in the pinned bar, then [groups]. [loading] shows a spinner instead. */
data class SettingsPageUiState(
    val title: String,
    val groups: List<SettingsGroup>,
    val loading: Boolean = false,
    /** Text above the groups (account preferences' header, an empty state's body). */
    val header: String? = null,
    /** An empty or error state in place of the groups: its title, body, icon and optional retry row id. */
    val empty: SettingsEmptyState? = null,
)

/** An empty or error state; [retryLabel] adds a retry, which calls [SettingsPageStore.activate] with [RETRY_ID]. */
data class SettingsEmptyState(val title: String, val body: String?, val icon: SettingIcon, val retryLabel: String? = null) {
    companion object {
        const val RETRY_ID: String = "retry"
    }
}

/**
 * What a row page's store asks of its UI once ([SettingsPageStore.events]): open a page, confirm, pick a file,
 * show a message, open a link.
 */
sealed interface SettingsEvent {
    /** Push the settings page [page] (`Route.SettingsPage(page, arg)`). */
    data class Open(val page: SettingsPageId, val arg: String? = null) : SettingsEvent

    /** Open another route of the app: profiles, add connection, Services (their slices' UIs). */
    data class OpenExternal(val target: ExternalTarget) : SettingsEvent

    /**
     * A confirmation dialog; its confirm calls [SettingsPageStore.confirm] with [id]. [destructive] paints confirm
     * in the error colour.
     */
    data class Confirm(val id: String, val title: String, val message: String, val confirmLabel: String, val destructive: Boolean) : SettingsEvent

    /** A dialog with a text field (the relay URL): [SettingsPageStore.submitText] with [id] stores or returns an error. */
    data class EditText(val row: SettingTextRow) : SettingsEvent

    /** Save [bytes] to a file the user picks, suggesting [fileName]; then [SettingsPageStore.exported]. */
    data class SaveFile(val fileName: String, val bytes: ByteArray) : SettingsEvent {
        override fun equals(other: Any?): Boolean = this === other
        override fun hashCode(): Int = fileName.hashCode()
    }

    /** Let the user pick a settings file; then [SettingsPageStore.imported] with its bytes (null: cancelled). */
    data object OpenFile : SettingsEvent

    /** A snackbar. */
    data class Message(val text: String, val error: Boolean = false) : SettingsEvent

    /** Open [url] in the browser. */
    data class OpenUrl(val url: String) : SettingsEvent

    /** The GitHub check found a newer release: show the update dialog ([com.edde746.plezy.updates.ReleaseUpdate]). */
    data class UpdateAvailable(val version: String, val notes: String?, val url: String?) : SettingsEvent

    /**
     * Check for Updates where the platform's updater updates the app ([com.edde746.plezy.updates.Updater.NATIVE]):
     * let it check in the foreground (Sparkle on the Mac, the installer updater on Windows), with its own UI.
     */
    data object NativeUpdateCheck : SettingsEvent

    /** Clear the UI's image cache (memory and disk); the store's success message follows. */
    data object ClearImageCache : SettingsEvent

    /** The logs were uploaded as [id]: show it ("Logs uploaded", "Log ID:") with a copy action. */
    data class LogsUploaded(val id: String) : SettingsEvent
}

/** Screens of other slices the hub opens; [SERVICES] is the trackers' and Seerr's Services screen. */
enum class ExternalTarget { PROFILES, ADD_CONNECTION, SUPPORTER, DONATE, SERVICES, LOGOUT }

/**
 * A row page's store. Call everything on the main thread; [release] ends it. Intents name the row by
 * [SettingRow.id]; an id the page doesn't have is a programming error.
 */
interface SettingsPageStore {
    val state: StateFlow<SettingsPageUiState>
    val events: Flow<SettingsEvent>

    fun toggle(id: String, checked: Boolean)

    fun choose(id: String, optionId: String)

    /** Stores [text] typed into a number row's dialog; returns the error to show ([checkNumber]'s), or null when stored. */
    fun setNumber(id: String, text: String): String?

    /**
     * Why [text] typed into a number row's dialog isn't a value of it ("Please enter a valid number", out of bounds), or
     * null; the dialog shows it while typing. Stores nothing.
     */
    fun checkNumber(id: String, text: String): String?

    fun setSlider(id: String, value: Double)

    fun setChecked(id: String, checkedIds: List<String>)

    /** Stores a text row's or text dialog's value; returns the inline error (at least [checkText]'s), or null when stored. */
    fun submitText(id: String, text: String): String?

    /**
     * Why [text] typed into a text row's dialog isn't taken, for a row checked while typing (a pattern: "Invalid regular
     * expression"), or null; a row checked only on Save (the relay) has nothing to say here. Stores nothing.
     */
    fun checkText(id: String, text: String): String?

    /**
     * A text row's reset action: the default text, which the dialog shows (nothing is stored yet), or null once the
     * reset is stored, which closes the dialog.
     */
    fun resetText(id: String): String?

    fun setColor(id: String, hex: String)

    /** A link row was activated. */
    fun activate(id: String)

    /** A [SettingsEvent.Confirm] was confirmed. */
    fun confirm(id: String)

    /** The file of a [SettingsEvent.SaveFile] was written (true) or the picker cancelled or failed (false, [error]). */
    fun exported(saved: Boolean, error: String? = null)

    /** The file picked for a [SettingsEvent.OpenFile]: its bytes, or null when cancelled. */
    fun imported(bytes: ByteArray?)

    /** The page shows again (back from a sub-page, the tab reselected): refresh what isn't observed. */
    fun resumed() {}

    fun release()
}
