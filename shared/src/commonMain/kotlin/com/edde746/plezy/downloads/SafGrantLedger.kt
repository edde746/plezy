package com.edde746.plezy.downloads

import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.downloads.DownloadLibraryRepository
import com.edde746.plezy.data.downloads.storedPartPaths
import com.edde746.plezy.log.Log
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/** Reads and writes the selected download location ([DownloadLocationSnapshot]) and reloads the storage service. */
internal interface DownloadLocationStore {
    suspend fun read(): DownloadLocationSnapshot

    /** Stores the location's path and type together: a reader never sees one without the other. */
    suspend fun write(location: DownloadLocationSnapshot)

    /** Makes the storage service use the location just written. */
    suspend fun refreshStorage()
}

/**
 * Who holds each persisted storage-access grant (Android document trees): the selected location and every download
 * row stored under a root. A grant is released only once nothing holds it. Every change of ownership runs one at a
 * time ([serialize]), so a root switch can't release a grant a download is claiming meanwhile.
 */
internal class SafGrantLedger(
    private val database: DownloadLibraryRepository,
    private val safStorage: SafStorageOperations,
    private val location: DownloadLocationStore,
    private val isDirectoryWritable: suspend (String) -> Boolean,
) {
    private val mutex = Mutex()

    suspend fun <T> serialize(action: suspend () -> T): T = mutex.withLock { action() }

    private suspend fun canonicalRootForLocation(snapshot: DownloadLocationSnapshot): String? {
        if (snapshot.type != SAF || snapshot.path == null) return null
        return safStorage.resolvePersistedPermissionUri(snapshot.path)
    }

    suspend fun setDownloadLocation(path: String, pathType: String, checkCurrent: (() -> Unit)?) {
        if (path.isBlank() || (pathType != FILE && pathType != SAF)) throw IllegalArgumentException("Invalid download location")
        serialize { installDownloadLocation(DownloadLocationSnapshot(path, pathType), checkCurrent) }
    }

    suspend fun resetDownloadLocation(checkCurrent: (() -> Unit)?) {
        serialize { installDownloadLocation(DownloadLocationSnapshot(null, null), checkCurrent) }
    }

    /**
     * Switches to [next] all or nothing: both settings and the storage reload, rolled back on failure. A grant the
     * switch took and nothing else holds is released on rollback; the previous root's once the switch stands. The
     * caller's cancellation doesn't stop it halfway: the switch runs to its end (applied or rolled back), as a settings
     * screen closing mid-switch would otherwise leave the stored and the live location apart.
     */
    private suspend fun installDownloadLocation(next: DownloadLocationSnapshot, checkCurrent: (() -> Unit)?): Unit = withContext(NonCancellable) {
        checkCurrent?.invoke()
        val previous = location.read()
        val previousRoot = canonicalRootForLocation(previous)
        checkCurrent?.invoke()
        val nextRoot = canonicalRootForLocation(next)
        checkCurrent?.invoke()
        if (next.type == SAF && next.path != null && nextRoot == null) {
            throw DownloadStorageException("Selected SAF root has no persisted permission", next.path, IllegalStateException("Persisted SAF permission is unavailable"))
        }
        if (next.type == FILE && next.path != null) {
            val writable = isDirectoryWritable(next.path)
            checkCurrent?.invoke()
            if (!writable) throw DownloadStorageException("Download directory is not writable", next.path, IllegalStateException("Access denied"))
        }

        var storageRefreshStarted = false
        try {
            checkCurrent?.invoke()
            location.write(next)
            checkCurrent?.invoke()
            storageRefreshStarted = true
            location.refreshStorage()
        } catch (error: Throwable) {
            checkCurrent?.invoke()
            var rollbackError: Throwable? = null
            for (step in listOf<suspend () -> Unit>(
                { location.write(previous) },
                { location.refreshStorage() },
            )) {
                try {
                    checkCurrent?.invoke()
                    step()
                } catch (e: Exception) {
                    if (rollbackError == null) rollbackError = e
                }
            }
            if (rollbackError != null) Log.e(TAG, rollbackError) { "Failed to restore download location after transition failure" }
            if (!storageRefreshStarted && nextRoot != null && nextRoot != previousRoot) {
                checkCurrent?.invoke()
                releaseSafRootIfUnowned(nextRoot)
            }
            throw error
        }

        if (previousRoot != null && previousRoot != nextRoot) {
            checkCurrent?.invoke()
            releaseSafRootIfUnowned(previousRoot)
        }
    }

    /** Releases [safRootUri]'s grant unless a download row or the selected location still holds it. */
    suspend fun releaseSafRootIfUnowned(safRootUri: String): Boolean {
        if (database.countDownloadsReferencingSafRoot(safRootUri) > 0) return false
        val selected = location.read()
        val selectedUri = if (selected.type == SAF) selected.path else null
        if (selectedUri != null) {
            if (selectedUri == safRootUri) return false
            val selectedRoot = safStorage.resolvePersistedPermissionUri(selectedUri)
            if (selectedRoot == null || selectedRoot == safRootUri) return false
        }
        return safStorage.releasePersistedPermission(safRootUri)
    }

    /** Points [globalKey]'s row at [nextRoot] and releases the root it held before if nothing else does. */
    suspend fun replaceDownloadSafRootClaim(globalKey: String, nextRoot: String?): String? {
        val existing = database.getDownloadedMedia(globalKey) ?: return null
        val previousRoot = existing.saf_root_uri
        if (previousRoot == nextRoot) return nextRoot
        database.updateDownloadSafRoot(globalKey, nextRoot)
        if (previousRoot != null) releaseSafRootIfUnowned(previousRoot)
        return nextRoot
    }

    /** Deletes [globalKey]'s row and releases the root its files were under once nothing else holds it. */
    suspend fun deleteDownloadRowAndRelease(globalKey: String) {
        serialize {
            val row = database.getDownloadedMedia(globalKey)
            var root = row?.saf_root_uri
            val videoUri = row?.let(::firstSafStoredPath)
            if (root == null && videoUri != null) root = safStorage.resolvePersistedPermissionUri(videoUri)
            val deletedRoot = database.deleteDownload(globalKey)
            root = root ?: deletedRoot
            if (root != null) releaseSafRootIfUnowned(root)
        }
    }

    suspend fun claimDownloadSafRoot(globalKey: String, uri: String) {
        serialize {
            val root = safStorage.resolvePersistedPermissionUri(uri) ?: throw IllegalStateException("SAF root claim could not be canonicalized")
            replaceDownloadSafRootClaim(globalKey, root)
        }
    }

    suspend fun clearDownloadSafRoot(globalKey: String) {
        serialize { replaceDownloadSafRootClaim(globalKey, null) }
    }

    /**
     * Records on each row the canonical root it is stored under (the live document task's directory, the row's root, or
     * its first document's), then releases the persisted grants nothing holds. Any root that can't be resolved defers
     * every release: an unknown owner may hold any of them.
     */
    suspend fun reconcile(tasks: List<DownloadTask>) {
        serialize {
            val rows = database.getAllDownloads()
            val rowsByKey = rows.associateBy { it.global_key }
            val activeDocumentTasks = mutableMapOf<String, DownloadTask>()
            for (task in tasks) {
                if (!task.isDocumentTask || task.metaData.isEmpty()) continue
                val row = rowsByKey[task.metaData] ?: continue
                if (row.bg_task_id == task.taskId) activeDocumentTasks[row.global_key] = task
            }

            val owners = mutableSetOf<String>()
            var resolutionFailed = false
            val selected = location.read()
            val selectedUri = if (selected.type == SAF) selected.path else null
            if (selectedUri != null) {
                val selectedRoot = safStorage.resolvePersistedPermissionUri(selectedUri)
                if (selectedRoot == null) resolutionFailed = true else owners += selectedRoot
            }

            for (row in rows) {
                val candidate = activeDocumentTasks[row.global_key]?.directoryUri ?: row.saf_root_uri ?: firstSafStoredPath(row) ?: continue
                val canonicalRoot = safStorage.resolvePersistedPermissionUri(candidate)
                if (canonicalRoot == null) {
                    resolutionFailed = true
                    continue
                }
                owners += canonicalRoot
                if (row.saf_root_uri != canonicalRoot) database.updateDownloadSafRoot(row.global_key, canonicalRoot)
            }

            val persistedRoots = safStorage.getPersistedPermissionUris()
            if (persistedRoots == null || resolutionFailed) return@serialize
            for (root in persistedRoots) {
                if (root !in owners) safStorage.releasePersistedPermission(root)
            }
        }
    }

    suspend fun readLocation(): DownloadLocationSnapshot = location.read()

    companion object {
        const val FILE = DownloadStorageService.PATH_TYPE_FILE
        const val SAF = DownloadStorageService.PATH_TYPE_SAF
        private const val TAG = "SafGrantLedger"

        /** The first of [row]'s stored files that is a document (`content://`), if any. */
        fun firstSafStoredPath(row: Downloaded_media): String? = row.storedPartPaths.firstOrNull { it.startsWith("content://") }
    }
}
