package com.edde746.plezy.downloads

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.system.ErrnoException
import android.system.Os
import android.webkit.MimeTypeMap
import com.edde746.plezy.log.Log
import kotlinx.io.IOException
import kotlinx.io.RawSink
import kotlinx.io.asSink
import java.io.FileNotFoundException
import java.io.FileOutputStream

/**
 * The storage-access-framework documents of download tasks, through the [ContentResolver]: a task writes straight into
 * its document under the folder the user granted, appending on a resume.
 *
 * A task's document is found by its name among the folder's children before one is created, so a resumed task (a
 * pause, the worker's next run) and a rerun after a dead process write into the document already there, never into a
 * numbered copy the provider would make beside it ("name (1)"); one the provider still names otherwise as it creates
 * it (a document of that name appeared meanwhile) is deleted, and the one there is used.
 */
class SafDocumentStore(context: Context) : DocumentStore {
    private val resolver: ContentResolver = context.applicationContext.contentResolver
    private val context = context.applicationContext

    override fun findOrCreate(treeUri: String, filename: String): String {
        val folder = Uri.parse(treeUri)
        val parent = parentId(folder)
        find(folder, parent, filename)?.let { return it.toString() }
        val created = try {
            DocumentsContract.createDocument(resolver, DocumentsContract.buildDocumentUriUsingTree(folder, parent), mimeType(filename), filename)
        } catch (e: Exception) {
            throw IOException("creating a document failed: ${e::class.simpleName}")
        } ?: throw IOException("the provider created no document")
        if (displayName(created) == filename) return created.toString()
        // The provider renamed it: the document of that name is there now.
        delete(created.toString())
        return find(folder, parent, filename)?.toString() ?: throw IOException("the document can't be created under its name")
    }

    override fun size(documentUri: String): Long? = try {
        resolver.openFileDescriptor(Uri.parse(documentUri), "r")?.use { it.statSize.takeIf { size -> size >= 0 } }
    } catch (_: FileNotFoundException) {
        null
    } catch (_: SecurityException) {
        null
    }

    override fun truncate(documentUri: String) {
        writable(documentUri).use { descriptor -> FileOutputStream(descriptor.fileDescriptor).channel.truncate(0) }
    }

    override fun appendSink(documentUri: String): RawSink {
        val descriptor = writable(documentUri)
        val stream = try {
            ParcelFileDescriptor.AutoCloseOutputStream(descriptor).also { it.channel.position(it.channel.size()) }
        } catch (e: java.io.IOException) {
            descriptor.close()
            throw e
        }
        return stream.asSink()
    }

    override fun delete(documentUri: String): Boolean = try {
        DocumentsContract.deleteDocument(resolver, Uri.parse(documentUri))
    } catch (_: FileNotFoundException) {
        true
    } catch (e: Exception) {
        Log.w(TAG) { "deleting a document failed: ${e::class.simpleName}" }
        false
    }

    override fun capacity(documentUri: String): VolumeCapacity? = try {
        resolver.openFileDescriptor(Uri.parse(documentUri), "r")?.use { descriptor ->
            val stat = Os.fstatvfs(descriptor.fileDescriptor)
            VolumeCapacity(available = stat.f_bavail * stat.f_frsize, total = stat.f_blocks * stat.f_frsize)
        }
    } catch (_: ErrnoException) {
        null
    } catch (_: FileNotFoundException) {
        null
    } catch (_: SecurityException) {
        null
    }

    /** The document's id under a tree URI, or the tree's own document for a bare tree URI. */
    private fun parentId(folder: Uri): String =
        if (DocumentsContract.isDocumentUri(context, folder)) DocumentsContract.getDocumentId(folder) else DocumentsContract.getTreeDocumentId(folder)

    /** The document named [filename] directly under [parent] (not a folder); null when there is none. */
    private fun find(folder: Uri, parent: String, filename: String): Uri? {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(folder, parent)
        val columns = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_MIME_TYPE)
        val cursor = try {
            resolver.query(children, columns, null, null, null)
        } catch (e: Exception) {
            throw IOException("listing the download folder failed: ${e::class.simpleName}")
        } ?: throw IOException("the download folder can't be listed")
        cursor.use {
            while (it.moveToNext()) {
                if (it.getString(1) == filename && it.getString(2) != DocumentsContract.Document.MIME_TYPE_DIR) {
                    return DocumentsContract.buildDocumentUriUsingTree(folder, it.getString(0))
                }
            }
        }
        return null
    }

    private fun displayName(document: Uri): String? = try {
        resolver.query(document, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) it.getString(0) else null
        }
    } catch (_: Exception) {
        null
    }

    private fun writable(documentUri: String): ParcelFileDescriptor = try {
        resolver.openFileDescriptor(Uri.parse(documentUri), "rw")
    } catch (e: Exception) {
        throw IOException("opening a document failed: ${e::class.simpleName}")
    } ?: throw IOException("the document can't be opened")

    private companion object {
        const val TAG = "downloads"

        fun mimeType(filename: String): String =
            MimeTypeMap.getSingleton().getMimeTypeFromExtension(filename.substringAfterLast('.', "").lowercase()) ?: "application/octet-stream"
    }
}
