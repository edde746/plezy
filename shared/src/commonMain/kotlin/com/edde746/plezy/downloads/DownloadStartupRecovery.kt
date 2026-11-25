package com.edde746.plezy.downloads

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.isStorageFullError
import com.edde746.plezy.log.Log
import kotlinx.io.IOException
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem

/**
 * Opens the local database ([openDatabase] creates and opens it, closing what it created when the open fails; on
 * Android, whose driver opens at the first statement, it calls [LocalData.open]). When it can't open because the
 * device is full, [recoverNativeDownloads] discards the background downloader's partial files
 * ([discardDownloaderTempFiles]) to free space, the database opens again, the downloader's tasks are forgotten, and
 * the downloads that were queued or downloading fail with [storageFullMessage], so the next start doesn't refill the
 * disk. Any other failure, or a second one, is thrown.
 */
internal suspend fun openLocalDataWithDownloadRecovery(
    openDatabase: suspend () -> LocalData,
    recoverNativeDownloads: suspend () -> Unit,
    storageFullMessage: String,
): LocalData {
    try {
        return openDatabase()
    } catch (e: Exception) {
        if (!isStorageFullError(e)) throw e
        Log.w(TAG, e) { "The database could not open for lack of space; discarding partial downloads" }
    }
    recoverNativeDownloads()
    val data = openDatabase()
    try {
        data.downloadTasks.deleteAll()
        data.downloadLibrary.failActiveDownloadsForStorageFull(storageFullMessage)
    } catch (e: Exception) {
        data.close()
        throw e
    }
    return data
}

/**
 * Deletes the background downloader's temporary files in [directory] (the partial transfers, `DownloadPlatform.tempDirectory`),
 * without its database: what frees space when the database can't open on a full disk. A missing directory is nothing
 * to delete; a file that can't be deleted is logged and the rest go.
 */
internal fun discardDownloaderTempFiles(directory: String, fileSystem: FileSystem = SystemFileSystem) {
    val path = Path(directory)
    if (fileSystem.metadataOrNull(path)?.isDirectory != true) return
    var freed = 0
    for (file in fileSystem.list(path)) {
        try {
            fileSystem.delete(file, mustExist = false)
            freed++
        } catch (e: IOException) {
            Log.w(TAG, e) { "Could not delete a partial download" }
        }
    }
    Log.i(TAG) { "Discarded $freed partial download file(s)" }
}

private const val TAG = "DownloadStartupRecovery"
