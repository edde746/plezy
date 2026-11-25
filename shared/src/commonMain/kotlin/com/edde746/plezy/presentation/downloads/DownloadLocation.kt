package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.settings.trailingValueOf
import com.edde746.plezy.presentation.settings.valueSubtitleOf
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import io.ktor.http.decodeURLPart
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

/** A folder the platform picker returned: a filesystem [path] (type `file`) or an Android tree URI (type `saf`). */
data class PickedFolder(val path: String, val type: String) {
    companion object {
        const val FILE = "file"
        const val SAF = "saf"
    }
}

/**
 * The platform's folder picker. [available] false: none on this device (Android TV without a documents UI).
 * [pick] returns null when the user cancelled.
 */
interface FolderPicker {
    val available: Boolean

    suspend fun pick(title: String): PickedFolder?
}

/**
 * The Downloads location row and its dialog. [dialogOpen] while the dialog shows. The row reads "Download location"
 * with [rowValue], "App storage" or a custom folder by its last two folders ([shortFolder]), beside the title while
 * short ([rowTrailingValue]), else under it ([rowSubtitle]).
 */
data class DownloadLocationUiState(
    val currentPath: String = "",
    val isCustom: Boolean = false,
    val dialogOpen: Boolean = false,
    val busy: Boolean = false,
    val message: DownloadFeedback? = null,
) {
    val rowTitle: String get() = T.settings.downloadLocation
    val rowValue: String get() = if (isCustom) shortFolder(currentPath) else T.settings.downloadLocationAppStorage
    val rowTrailingValue: String? get() = trailingValueOf(rowValue)
    val rowSubtitle: String? get() = valueSubtitleOf(rowValue, null)
    val dialogTitle: String get() = T.settings.downloads
    val description: String get() = T.settings.downloadLocationDescription
    val currentPathLine: String get() = T.settings.currentPath(path = currentPath)
    val selectLabel: String get() = T.settings.selectFolder
    val resetLabel: String get() = T.settings.resetToDefault

    /** "Reset to default" shows only for a custom location. */
    val offersReset: Boolean get() = isCustom
}

/**
 * [path] as a short line: "…/" and its last two folders ("…/Media/Plezy", "…\Videos\Plezy" for a Windows path), the
 * whole path when it has no more than two. An Android document tree URI counts the folders of the path it grants.
 */
internal fun shortFolder(path: String): String {
    val tree = path.substringAfter("/tree/", "").takeIf { path.startsWith("content://") }
    val folders = tree?.decodeURLPart()?.substringAfter(':') ?: path
    val separator = if ('\\' in folders && '/' !in folders) "\\" else "/"
    val parts = folders.split('/', '\\').filter { it.isNotEmpty() }
    return if (parts.size > 2) "…$separator" + parts.takeLast(2).joinToString(separator) else folders
}

/**
 * Settings → Downloads location: the current folder, a picker ([picker]: Android's document tree, stored as `saf`;
 * elsewhere a folder dialog, stored as `file` once [isWritable] says a file can be created there), and the reset to the
 * app's own folder. The switch itself is the controller's, which moves the queue over and rolls back on failure.
 *
 * @param defaultPath the app's own downloads folder, shown while no custom one is set.
 */
class DownloadLocationModel(
    private val controller: DownloadsController,
    private val settings: DeviceSettingsRepository,
    private val picker: FolderPicker,
    private val isWritable: (String) -> Boolean,
    private val defaultPath: () -> String,
    private val scope: CoroutineScope,
) {
    private val mutableState = MutableStateFlow(DownloadLocationUiState(currentPath = defaultPath()))
    val state: StateFlow<DownloadLocationUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(settings.observe(AppSettings.customDownloadPath), settings.observe(AppSettings.customDownloadPathType)) { path, _ -> path }
                .collect { path -> mutableState.value = mutableState.value.copy(currentPath = path ?: defaultPath(), isCustom = path != null) }
        }
    }

    fun openDialog() {
        mutableState.value = mutableState.value.copy(dialogOpen = true)
    }

    fun closeDialog() {
        mutableState.value = mutableState.value.copy(dialogOpen = false)
    }

    /** "Select folder": the picker, then the switch; the dialog closes once the location changed. */
    fun selectFolder() = work {
        if (!picker.available) return@work DownloadFeedback(T.settings.downloadLocationPickerUnavailable, isError = true)
        val picked = picker.pick(T.settings.selectFolder) ?: return@work null
        if (picked.type == PickedFolder.FILE && !isWritable(picked.path)) {
            return@work DownloadFeedback(T.settings.downloadLocationInvalid, isError = true)
        }
        controller.setDownloadLocation(picked.path, picked.type)
        closeDialog()
        DownloadFeedback(T.settings.downloadLocationChanged, isError = false)
    }

    /** "Reset to default". */
    fun reset() = work {
        controller.resetDownloadLocation()
        closeDialog()
        DownloadFeedback(T.settings.downloadLocationReset, isError = false)
    }

    fun messageShown() {
        mutableState.value = mutableState.value.copy(message = null)
    }

    private fun work(block: suspend () -> DownloadFeedback?) {
        if (mutableState.value.busy) return
        mutableState.value = mutableState.value.copy(busy = true)
        scope.launch {
            val feedback = try {
                block()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Download directory selection failed" }
                DownloadFeedback(T.messages.errorLoading(error = localizedErrorReason(e)), isError = true)
            }
            mutableState.value = mutableState.value.copy(busy = false, message = feedback ?: mutableState.value.message)
        }
    }

    private companion object {
        const val TAG = "DownloadLocation"
    }
}
