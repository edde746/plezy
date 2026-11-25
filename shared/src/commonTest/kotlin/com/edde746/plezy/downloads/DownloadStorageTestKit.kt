package com.edde746.plezy.downloads

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.settings.AppSettings
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.random.Random

/**
 * A temporary directory standing in for the app's directories, as on a desktop: [support] is the base directory
 * relative download paths are anchored to. [base] can be pointed elsewhere to stand in for the app's storage moving.
 */
internal class StorageRoot(prefix: String = "plezy-storage-") {
    val root: String = Path(SystemTemporaryDirectory, prefix + Random.nextLong().toULong()).toString()
    val support: String = LocalPath.join(root, "support")
    var base: String = support

    init {
        SystemFileSystem.createDirectories(Path(root))
    }

    fun path(vararg components: String): String = LocalPath.join(root, *components)

    /** The platform of a desktop over [base]; [supportsSaf] and [excludeFromBackup] as on Android or iPhone. */
    fun platform(supportsSaf: Boolean = false, excludeFromBackup: ((String) -> Unit)? = null) =
        DownloadStoragePlatform(BaseDirectory.APPLICATION_SUPPORT, { base }, supportsSaf, excludeFromBackup)

    fun delete() = deleteDirectoryTree(Path(root))
}

/** Stores the custom download folder setting ([type] `file` or `saf`). */
internal suspend fun DeviceSettingsRepository.setCustomDownloadPath(path: String?, type: String? = DownloadStorageService.PATH_TYPE_FILE) {
    set(AppSettings.customDownloadPathType, type)
    set(AppSettings.customDownloadPath, path)
}

internal fun deleteDirectoryTree(path: Path) {
    val metadata = SystemFileSystem.metadataOrNull(path) ?: return
    if (metadata.isDirectory) SystemFileSystem.list(path).forEach(::deleteDirectoryTree)
    SystemFileSystem.delete(path)
}

internal fun writeFile(path: String, text: String = "x") {
    Path(path).parent?.let(SystemFileSystem::createDirectories)
    SystemFileSystem.sink(Path(path)).use { sink ->
        val bytes = text.encodeToByteArray()
        sink.write(kotlinx.io.Buffer().apply { write(bytes) }, bytes.size.toLong())
    }
}

internal fun exists(path: String) = SystemFileSystem.exists(Path(path))
