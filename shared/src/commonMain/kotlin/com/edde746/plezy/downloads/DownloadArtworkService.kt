package com.edde746.plezy.downloads

import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.artworkStorageKey
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readByteArray
import kotlin.coroutines.CoroutineContext

/**
 * Saves a download's artwork for offline use: `<artwork dir>/<md5("serverId:key")>.jpg`, the key being the artwork's
 * storage key ([artworkStorageKey]: Jellyfin's `api_key` dropped, the earlier releases' file names kept). A file that
 * is empty or starts like an HTML or JSON error body is not artwork: it is deleted and the image counts as failed. Two
 * requests for one file share one transfer.
 */
class DownloadArtworkService(
    private val storage: DownloadStorageService,
    private val http: MediaServerHttpClient,
    private val io: CoroutineContext = Dispatchers.IO,
) {
    private val fileSystem = SystemFileSystem
    private val lock = Mutex()
    private val downloadsByPath = HashMap<String, CompletableDeferred<Boolean>>()

    /** The artwork file of [pathOrUrl] (a raw artwork path or URL, or its storage key) on [serverId]. */
    fun localPath(serverId: ServerId, pathOrUrl: String): String =
        storage.getArtworkPathFromThumb(serverId, artworkStorageKey(pathOrUrl))

    /** [localPath] from the artwork directory resolved last; null before it is resolved or while the file isn't on disk. */
    fun localPathSync(serverId: ServerId, pathOrUrl: String?): String? {
        if (pathOrUrl.isNullOrEmpty()) return null
        return storage.getArtworkPathSync(serverId, artworkStorageKey(pathOrUrl))?.takeIf { fileSystem.exists(Path(it)) }
    }

    /** Whether [pathOrUrl]'s artwork file exists and is artwork. */
    suspend fun existsUsable(serverId: ServerId, pathOrUrl: String): Boolean =
        withContext(io) { isUsableArtworkFile(localPath(serverId, pathOrUrl)) }

    /** Saves every artwork [backend] names for [metadata]; true when every image is saved. */
    suspend fun ensureArtworkForMetadata(metadata: MediaItem, backend: MediaBackend): Boolean {
        val serverId = ServerId.tryParse(metadata.serverId) ?: return false
        return ensureArtworkSpecs(serverId, backend.resolveDownloadArtwork(metadata))
    }

    /** Saves each of [specs] in turn; true when every one is saved. */
    suspend fun ensureArtworkSpecs(serverId: ServerId, specs: Iterable<DownloadArtworkSpec>): Boolean {
        var allSettled = true
        for (spec in specs) {
            if (!downloadSingleArtwork(serverId, spec)) allSettled = false
        }
        return allSettled
    }

    /** Saves one image unless its usable file is there already; false when it could not be saved. */
    suspend fun downloadSingleArtwork(serverId: ServerId, spec: DownloadArtworkSpec): Boolean {
        if (spec.url.isEmpty()) {
            Log.w(TAG) { "Empty artwork URL for ${spec.localKey}" }
            return false
        }
        val filePath = localPath(serverId, spec.localKey)
        val operation = CompletableDeferred<Boolean>()
        val inFlight = lock.withLock { downloadsByPath[filePath].also { if (it == null) downloadsByPath[filePath] = operation } }
        if (inFlight != null) return inFlight.await()
        try {
            val settled = downloadToPath(spec, filePath)
            operation.complete(settled)
            return settled
        } catch (e: Throwable) {
            operation.completeExceptionally(e)
            throw e
        } finally {
            lock.withLock { if (downloadsByPath[filePath] === operation) downloadsByPath.remove(filePath) }
        }
    }

    private suspend fun downloadToPath(spec: DownloadArtworkSpec, filePath: String): Boolean = try {
        val file = Path(filePath)
        if (withContext(io) { isUsableArtworkFile(filePath) }) {
            true
        } else {
            withContext(io) {
                file.parent?.let(fileSystem::createDirectories)
                if (fileSystem.exists(file)) fileSystem.delete(file)
            }
            http.downloadFile(spec.url, filePath)
            withContext(io) {
                if (isUsableArtworkFile(filePath)) {
                    true
                } else {
                    if (fileSystem.exists(file)) fileSystem.delete(file)
                    Log.w(TAG) { "Downloaded artwork was not an image: ${spec.localKey}" }
                    false
                }
            }
        }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Failed to download artwork: ${spec.localKey}" }
        false
    }

    /** Non-empty, and its first bytes aren't an HTML document or a JSON object. Blocking. */
    private fun isUsableArtworkFile(path: String): Boolean {
        val file = Path(path)
        val size = fileSystem.metadataOrNull(file)?.takeIf { it.isRegularFile }?.size ?: return false
        if (size <= 0) return false
        val head = fileSystem.source(file).buffered().use { it.readByteArray(minOf(size, HEAD_BYTES.toLong()).toInt()) }
        val prefix = head.take(128).map { (it.toInt() and 0xFF).toChar() }.joinToString("").trimStart().lowercase()
        return !(prefix.startsWith("<!doctype html") || prefix.startsWith("<html") || prefix.startsWith("{"))
    }

    private companion object {
        const val TAG = "DownloadArtwork"
        const val HEAD_BYTES = 512
    }
}
