package com.edde746.plezy.data

import com.edde746.plezy.data.recovery.RecoveryKeys
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.downloads.DownloadStorageService
import com.edde746.plezy.downloads.discardDownloaderTempFiles
import com.edde746.plezy.importer.resetMarker
import com.edde746.plezy.log.Log
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import kotlinx.io.IOException
import kotlinx.io.buffered
import kotlinx.io.writeString
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlin.time.Clock
import kotlin.time.Instant

/**
 * Resets the app's saved data once the user confirmed it, after the start found it unusable ([DataFault]): the next
 * start is a first run, which signs in.
 *
 * - The database moves aside as `plezy.db.unreadable-<epoch ms>`, with its `-wal` and `-shm`, for a support case; only
 *   the newest such copy is kept.
 * - The earlier release is marked handled outside the database ([resetMarker] in the files directory): the first run
 *   after the reset imports nothing of it ([com.edde746.plezy.importer.EarlierReleaseImport]).
 * - Every secret of [secrets] (the accounts' and trackers' tokens) is deleted, and a recovery image (Apple TV) with it.
 * - The downloads in the app's own storage (`downloads` and `artwork` under [downloads]'s base directory) and the
 *   downloader's partial files ([downloadTempDirectory]) are deleted: without the database nothing knows them. A
 *   download folder the user chose elsewhere is left as it is, and so are the earlier release's own files in the base
 *   directory (its database, preferences and credential vault), which the import only reads.
 *
 * Nothing may have the database open. Throws when the database can't be moved (nothing else is touched then) or a
 * secret can't be deleted; a download file that can't be deleted is logged, and the rest go.
 */
internal class DataReset(
    private val database: DatabaseFactory,
    private val secrets: SecretStore,
    private val downloads: DownloadStoragePlatform?,
    private val downloadTempDirectory: String?,
) {
    internal var fileSystem: FileSystem = SystemFileSystem
    internal var now: () -> Instant = { Clock.System.now() }

    suspend fun reset(): Unit = withContext(Dispatchers.IO) {
        database.file()?.let(::moveAside)
        markEarlierReleaseHandled()
        secrets.deleteAll("")
        database.purgeable()?.store?.let { store -> (RecoveryKeys.ALL + RecoveryKeys.INSTALL).forEach(store::remove) }
        downloads?.baseDirectoryPath?.invoke()?.let { base ->
            for (folder in listOf(DownloadStorageService.DOWNLOADS, DownloadStorageService.ARTWORK)) deleteTree(Path(base, folder))
        }
        downloadTempDirectory?.let { discardDownloaderTempFiles(it, fileSystem) }
        Log.i(TAG) { "the app's data was reset" }
    }

    private fun moveAside(file: Path) {
        val dir = checkNotNull(file.parent) { "The database file has no directory" }
        val prefix = "${file.name}$UNREADABLE"
        // Only the newest copy is kept: the earlier ones go before this one is made.
        for (old in fileSystem.list(dir)) {
            if (old.name.startsWith(prefix)) fileSystem.delete(old, mustExist = false)
        }
        val aside = "$prefix${now().toEpochMilliseconds()}"
        for (suffix in listOf("", "-wal", "-shm")) {
            val from = Path("$file$suffix")
            if (fileSystem.exists(from)) fileSystem.atomicMove(from, Path(dir, "$aside$suffix"))
        }
        Log.i(TAG) { "moved the unreadable database aside as $aside" }
    }

    private fun markEarlierReleaseHandled() {
        val marker = resetMarker(database.filesDirectory())
        marker.parent?.let(fileSystem::createDirectories)
        fileSystem.sink(marker).buffered().use { it.writeString(now().toString()) }
    }

    private fun deleteTree(path: Path) {
        val metadata = fileSystem.metadataOrNull(path) ?: return
        if (metadata.isDirectory) fileSystem.list(path).forEach(::deleteTree)
        try {
            fileSystem.delete(path, mustExist = false)
        } catch (e: IOException) {
            Log.w(TAG, e) { "Couldn't delete ${path.name}" }
        }
    }

    private companion object {
        const val TAG = "DataReset"
        const val UNREADABLE = ".unreadable-"
    }
}
