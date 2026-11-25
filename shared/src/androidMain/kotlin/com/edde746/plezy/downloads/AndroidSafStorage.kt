package com.edde746.plezy.downloads

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.content.UriPermission
import android.graphics.Bitmap
import android.graphics.Point
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/**
 * [SafStorageOperations] over Android's documents provider ([DocumentsContract]). A tree URI and a document URI inside
 * a tree are both accepted wherever a directory is expected.
 */
class AndroidSafStorage(private val context: Context) : SafStorageOperations {
    private val resolver: ContentResolver get() = context.contentResolver

    override val isAvailable: Boolean get() = true

    override suspend fun getChild(parentUri: String, names: List<String>): SafDocumentFile? = attempt("getChild", null) {
        var current = directoryUri(Uri.parse(parentUri))
        for (name in names) current = findDirectChild(current, name)?.let { Uri.parse(it.uri) } ?: return@attempt null
        document(current)
    }

    override suspend fun createNestedDirectories(parentUri: String, pathComponents: List<String>): String? =
        attempt("createNestedDirectories", null) { mkdirp(Uri.parse(parentUri), pathComponents).toString() }

    override suspend fun delete(uri: String, isDir: Boolean): Boolean = attempt("delete", false) {
        DocumentsContract.deleteDocument(resolver, documentUri(Uri.parse(uri), isDir))
    }

    override suspend fun exists(uri: String, isDir: Boolean): Boolean = attempt("exists", false) {
        resolver.query(documentUri(Uri.parse(uri), isDir), arrayOf(Document.COLUMN_DOCUMENT_ID), null, null, null)
            ?.use { it.count > 0 } ?: false
    }

    override suspend fun size(uri: String): Long? = attempt("size", null) { document(Uri.parse(uri))?.length }

    override suspend fun read(uri: String, offset: Long, length: Int): ByteArray? = attempt("read", null) {
        val stream = resolver.openInputStream(Uri.parse(uri)) ?: error("No stream for the document")
        stream.use { input ->
            var skipped = 0L
            while (skipped < offset) {
                val step = input.skip(offset - skipped)
                if (step <= 0) return@attempt ByteArray(0)
                skipped += step
            }
            val bytes = ByteArray(length)
            var read = 0
            while (read < length) {
                val step = input.read(bytes, read, length - read)
                if (step < 0) break
                read += step
            }
            bytes.copyOf(read)
        }
    }

    override suspend fun list(uri: String): List<SafDocumentFile>? = attempt("list", null) { children(directoryUri(Uri.parse(uri))) }

    override suspend fun resolvePersistedPermissionUri(uri: String): String? =
        attempt("resolvePersistedPermissionUri", null) { resolvePermission(Uri.parse(uri))?.uri?.toString() }

    override suspend fun getPersistedPermissionUris(): List<String>? =
        attempt("getPersistedPermissionUris", null) { resolver.persistedUriPermissions.map { it.uri.toString() } }

    override suspend fun releasePersistedPermission(uri: String): Boolean = attempt("releasePersistedPermission", false) {
        releasePermission(Uri.parse(uri), read = true, write = true)
        true
    }

    /** Whether a persisted grant covers [uri] with the access asked for. */
    suspend fun hasPersistedPermission(uri: String, checkRead: Boolean = true, checkWrite: Boolean = false): Boolean =
        withContext(Dispatchers.IO) {
            val permission = resolvePermission(Uri.parse(uri)) ?: return@withContext false
            (!checkRead || permission.isReadPermission) && (!checkWrite || permission.isWritePermission)
        }

    /**
     * Keeps read and write access to a tree the directory picker returned ([openDirectoryIntent]) across restarts,
     * and returns the URI of its root document, the form a custom download folder is stored in.
     */
    fun persistPickedDirectory(treeUri: Uri): String {
        resolver.takePersistableUriPermission(treeUri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        return directoryUri(treeUri).toString()
    }

    /**
     * Saves a [width]×[height] thumbnail of the document [uri] to [destPath]: a video's frame ([extractVideoFrame]),
     * else the provider's thumbnail. False when the document has no type or no thumbnail.
     */
    suspend fun saveThumbnailToFile(uri: String, width: Int, height: Int, destPath: String, png: Boolean = false, quality: Int = if (png) 100 else 80): Boolean =
        withContext(Dispatchers.IO) {
            val document = Uri.parse(uri)
            val mime = queryString(document, Document.COLUMN_MIME_TYPE) ?: return@withContext false
            val bitmap = if (mime.startsWith("video/")) {
                extractVideoFrame(context, document, width, height)
            } else {
                DocumentsContract.getDocumentThumbnail(resolver, document, Point(width, height), null)
            } ?: return@withContext false
            File(destPath).outputStream().use { out ->
                bitmap.compress(if (png) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG, quality, out)
            }
            true
        }

    /** Runs a provider call off the main thread; a failure is logged and answered with [failed]. */
    private suspend fun <T> attempt(operation: String, failed: T, block: () -> T): T = withContext(Dispatchers.IO) {
        try {
            block()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "SAF $operation failed" }
            failed
        }
    }

    /** A directory's document URI: a tree URI's root document, or the document a tree-scoped URI names. */
    private fun directoryUri(uri: Uri): Uri {
        val id = if (DocumentsContract.isDocumentUri(context, uri)) DocumentsContract.getDocumentId(uri) else DocumentsContract.getTreeDocumentId(uri)
        return DocumentsContract.buildDocumentUriUsingTree(uri, id)
    }

    private fun documentUri(uri: Uri, isDir: Boolean): Uri = if (isDir) directoryUri(uri) else uri

    private fun mkdirp(parent: Uri, names: List<String>): Uri {
        var current = directoryUri(parent)
        for (name in names) {
            val found = findDirectChild(current, name)
            current = when {
                found == null -> {
                    val created = DocumentsContract.createDocument(resolver, current, Document.MIME_TYPE_DIR, name)
                        ?: error("Failed to create directory $name")
                    // The provider renames a directory created concurrently under the same name; use the requested one.
                    if (queryString(created, Document.COLUMN_DISPLAY_NAME) == name) created else findDirectChild(current, name)?.let { Uri.parse(it.uri) } ?: error("Failed to create directory $name")
                }
                !found.isDir -> error("File found at $name while creating directory")
                else -> Uri.parse(found.uri)
            }
        }
        return current
    }

    private fun children(directory: Uri): List<SafDocumentFile> {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(directory, DocumentsContract.getDocumentId(directory))
        val columns = arrayOf(Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME, Document.COLUMN_SIZE, Document.COLUMN_MIME_TYPE, Document.COLUMN_LAST_MODIFIED)
        val cursor = resolver.query(childrenUri, columns, null, null, null) ?: error("No listing for $directory")
        return cursor.use {
            buildList {
                while (it.moveToNext()) {
                    val isDir = it.getString(3) == Document.MIME_TYPE_DIR
                    add(
                        SafDocumentFile(
                            uri = DocumentsContract.buildDocumentUriUsingTree(directory, it.getString(0)).toString(),
                            name = it.getString(1).orEmpty(),
                            isDir = isDir,
                            length = if (isDir || it.isNull(2)) 0 else it.getLong(2),
                            lastModified = if (it.isNull(4)) 0 else it.getLong(4),
                        ),
                    )
                }
            }
        }
    }

    private fun findDirectChild(directory: Uri, name: String): SafDocumentFile? = children(directory).firstOrNull { it.name == name }

    private fun document(uri: Uri): SafDocumentFile? {
        val columns = arrayOf(Document.COLUMN_DISPLAY_NAME, Document.COLUMN_MIME_TYPE, Document.COLUMN_SIZE, Document.COLUMN_LAST_MODIFIED)
        return resolver.query(uri, columns, null, null, null)?.use {
            if (!it.moveToFirst()) return@use null
            val isDir = it.getString(1) == Document.MIME_TYPE_DIR
            SafDocumentFile(
                uri = uri.toString(),
                name = it.getString(0).orEmpty(),
                isDir = isDir,
                length = if (isDir || it.isNull(2)) 0 else it.getLong(2),
                lastModified = if (it.isNull(3)) 0 else it.getLong(3),
            )
        }
    }

    private fun queryString(uri: Uri, column: String): String? =
        resolver.query(uri, arrayOf(column), null, null, null)?.use { if (it.moveToFirst() && !it.isNull(0)) it.getString(0) else null }

    /** The persisted grant for [requested]: the exact URI, else a tree grant with the same provider and root document. */
    private fun resolvePermission(requested: Uri): UriPermission? {
        val permissions = resolver.persistedUriPermissions
        permissions.firstOrNull { it.uri == requested }?.let { return it }
        val identity = treeIdentity(requested) ?: return null
        return permissions.firstOrNull { treeIdentity(it.uri) == identity }
    }

    private fun releasePermission(requested: Uri, read: Boolean, write: Boolean) {
        val permission = resolvePermission(requested) ?: return
        var flags = 0
        if (read && permission.isReadPermission) flags = flags or Intent.FLAG_GRANT_READ_URI_PERMISSION
        if (write && permission.isWritePermission) flags = flags or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        if (flags == 0) return
        try {
            resolver.releasePersistableUriPermission(permission.uri, flags)
        } catch (failure: SecurityException) {
            // Released concurrently: only a grant that still holds a requested mode is a failure.
            val remaining = resolvePermission(requested) ?: return
            if ((read && remaining.isReadPermission) || (write && remaining.isWritePermission)) throw failure
        }
    }

    private fun treeIdentity(uri: Uri): Triple<String, String, String>? {
        if (!DocumentsContract.isTreeUri(uri)) return null
        val scheme = uri.scheme ?: return null
        val authority = uri.authority ?: return null
        return try {
            Triple(scheme, authority, DocumentsContract.getTreeDocumentId(uri))
        } catch (e: IllegalArgumentException) {
            Log.d(TAG, e) { "Not a tree URI: $uri" }
            null
        }
    }

    companion object {
        private const val TAG = "SafStorage"

        /** The directory picker's request: a tree with persistable read and write access. */
        fun openDirectoryIntent(initialUri: Uri? = null): Intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            if (initialUri != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }
}

/**
 * A [width]×[height] frame of the video [uri] near its start (the closest sync frame; the unscaled first frame before
 * Android 8.1), or null when it has none. The retriever is always released.
 */
fun extractVideoFrame(context: Context, uri: Uri, width: Int, height: Int, retriever: MediaMetadataRetriever = MediaMetadataRetriever()): Bitmap? = try {
    retriever.setDataSource(context, uri)
    if (Build.VERSION.SDK_INT >= 27) {
        retriever.getScaledFrameAtTime(-1, MediaMetadataRetriever.OPTION_CLOSEST_SYNC, width, height)
    } else {
        retriever.frameAtTime
    }
} finally {
    retriever.release()
}
