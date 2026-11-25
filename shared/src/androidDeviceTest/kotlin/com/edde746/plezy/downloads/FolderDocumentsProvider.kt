package com.edde746.plezy.downloads

import android.database.Cursor
import android.database.MatrixCursor
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract.Document
import android.provider.DocumentsContract.Root
import android.provider.DocumentsProvider
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileNotFoundException

/**
 * A documents provider over a folder of the test app's own ([ROOT_ID] is [directory]), so the storage access framework
 * runs for real: tree and document URIs, child listings, creating and deleting through the provider. A document's id is
 * its path under [directory], [ROOT_ID] first ("tree", "tree/Movies"). A name taken when a document is created gets
 * " (1)", " (2)" and so on, as the system's providers do.
 */
class FolderDocumentsProvider : DocumentsProvider() {
    private val directory: File get() = folder(context!!.cacheDir)

    override fun onCreate(): Boolean = true

    override fun queryRoots(projection: Array<out String>?): Cursor = MatrixCursor(projection ?: ROOT_COLUMNS).apply {
        newRow().add(Root.COLUMN_ROOT_ID, ROOT_ID).add(Root.COLUMN_DOCUMENT_ID, ROOT_ID).add(Root.COLUMN_TITLE, "Test folder")
            .add(Root.COLUMN_FLAGS, Root.FLAG_SUPPORTS_CREATE or Root.FLAG_SUPPORTS_IS_CHILD)
    }

    override fun queryDocument(documentId: String, projection: Array<out String>?): Cursor =
        MatrixCursor(projection ?: DOCUMENT_COLUMNS).apply { addRow(this, documentId, file(documentId)) }

    override fun queryChildDocuments(parentDocumentId: String, projection: Array<out String>?, sortOrder: String?): Cursor {
        val parent = file(parentDocumentId)
        if (!parent.isDirectory) throw FileNotFoundException("$parentDocumentId is not a directory")
        return MatrixCursor(projection ?: DOCUMENT_COLUMNS).apply {
            parent.listFiles().orEmpty().sortedBy { it.name }.forEach { addRow(this, "$parentDocumentId/${it.name}", it) }
        }
    }

    override fun openDocument(documentId: String, mode: String, signal: CancellationSignal?): ParcelFileDescriptor =
        ParcelFileDescriptor.open(file(documentId), ParcelFileDescriptor.parseMode(mode))

    override fun createDocument(parentDocumentId: String, mimeType: String, displayName: String): String {
        val parent = file(parentDocumentId)
        var name = displayName
        var n = 0
        while (File(parent, name).exists()) name = "$displayName (${++n})"
        val created = File(parent, name)
        val made = if (mimeType == Document.MIME_TYPE_DIR) created.mkdir() else created.createNewFile()
        if (!made) throw FileNotFoundException("Couldn't create $name in $parentDocumentId")
        return "$parentDocumentId/$name"
    }

    override fun deleteDocument(documentId: String) {
        if (!file(documentId).deleteRecursively()) throw FileNotFoundException("Couldn't delete $documentId")
    }

    override fun isChildDocument(parentDocumentId: String, documentId: String): Boolean =
        documentId.startsWith("$parentDocumentId/")

    private fun file(documentId: String): File {
        if (documentId != ROOT_ID && !documentId.startsWith("$ROOT_ID/")) throw FileNotFoundException("No document $documentId")
        val file = File(directory, documentId.removePrefix(ROOT_ID).trimStart('/'))
        if (!file.exists()) throw FileNotFoundException("No document $documentId")
        return file
    }

    private fun addRow(cursor: MatrixCursor, documentId: String, file: File) {
        val mime = if (file.isDirectory) {
            Document.MIME_TYPE_DIR
        } else {
            MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension) ?: "application/octet-stream"
        }
        val flags = if (file.isDirectory) Document.FLAG_DIR_SUPPORTS_CREATE or Document.FLAG_SUPPORTS_DELETE else Document.FLAG_SUPPORTS_DELETE
        cursor.newRow().add(Document.COLUMN_DOCUMENT_ID, documentId).add(Document.COLUMN_DISPLAY_NAME, file.name)
            .add(Document.COLUMN_MIME_TYPE, mime).add(Document.COLUMN_SIZE, if (file.isDirectory) null else file.length())
            .add(Document.COLUMN_LAST_MODIFIED, file.lastModified()).add(Document.COLUMN_FLAGS, flags)
    }

    companion object {
        const val AUTHORITY = "com.edde746.plezy.test.folderdocuments"
        const val ROOT_ID = "tree"

        /** The folder the provider serves under [cacheDir]. */
        fun folder(cacheDir: File): File = File(cacheDir, "saf-tree")

        private val ROOT_COLUMNS = arrayOf(Root.COLUMN_ROOT_ID, Root.COLUMN_DOCUMENT_ID, Root.COLUMN_TITLE, Root.COLUMN_FLAGS)
        private val DOCUMENT_COLUMNS = arrayOf(
            Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME, Document.COLUMN_MIME_TYPE, Document.COLUMN_SIZE,
            Document.COLUMN_LAST_MODIFIED, Document.COLUMN_FLAGS,
        )
    }
}
