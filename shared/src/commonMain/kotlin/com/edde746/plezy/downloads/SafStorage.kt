package com.edde746.plezy.downloads

/**
 * A document of Android's storage access framework.
 *
 * @param length bytes, -1 when unknown (a directory).
 * @param lastModified epoch milliseconds, 0 when unknown.
 */
data class SafDocumentFile(
    val uri: String,
    val name: String,
    val isDir: Boolean = false,
    val length: Long = -1,
    val lastModified: Long = 0,
)

/**
 * The storage-access-framework operations downloads in a custom Android folder use. A failure reads as the "no answer"
 * of each operation (null, false), never as an exception, so a revoked grant or an unmounted volume doesn't break a
 * download pass; the implementation logs it.
 */
interface SafStorageOperations {
    /** Whether a tree can be stored into here at all (Android). */
    val isAvailable: Boolean

    /** The document at [names] (one component per level) under [parentUri], or null when missing or on error. */
    suspend fun getChild(parentUri: String, names: List<String>): SafDocumentFile?

    /** Creates [pathComponents] under [parentUri] as needed; the deepest directory's URI, or null on error. */
    suspend fun createNestedDirectories(parentUri: String, pathComponents: List<String>): String?

    /** Deletes a document; false on error. */
    suspend fun delete(uri: String, isDir: Boolean): Boolean

    /** Whether a document exists; false on error. */
    suspend fun exists(uri: String, isDir: Boolean): Boolean

    /** A directory's children; null on error, so an error isn't taken for an empty directory. */
    suspend fun list(uri: String): List<SafDocumentFile>?

    /** A document's size in bytes; null on error. */
    suspend fun size(uri: String): Long?

    /** Up to [length] bytes of a document from [offset] (fewer at its end); null on error. */
    suspend fun read(uri: String, offset: Long, length: Int): ByteArray?

    /**
     * The persisted tree grant covering [uri] (a tree, document or descendant URI), as the system holds it; null when
     * no grant covers it or the lookup failed, so a caller keeps ownership rather than releasing on a guess.
     */
    suspend fun resolvePersistedPermissionUri(uri: String): String?

    /** Every persisted tree grant; null when enumerating failed (retry later rather than treat it as none). */
    suspend fun getPersistedPermissionUris(): List<String>?

    /** Releases read and write access of the grant covering [uri] (nothing to release is success); false on failure. */
    suspend fun releasePersistedPermission(uri: String): Boolean
}

/** Platforms without the storage access framework: nothing exists, nothing is granted, there is nothing to release. */
object UnsupportedSafStorage : SafStorageOperations {
    override val isAvailable: Boolean get() = false

    override suspend fun getChild(parentUri: String, names: List<String>): SafDocumentFile? = null

    override suspend fun createNestedDirectories(parentUri: String, pathComponents: List<String>): String? = null

    override suspend fun delete(uri: String, isDir: Boolean): Boolean = false

    override suspend fun exists(uri: String, isDir: Boolean): Boolean = false

    override suspend fun list(uri: String): List<SafDocumentFile>? = null

    override suspend fun size(uri: String): Long? = null

    override suspend fun read(uri: String, offset: Long, length: Int): ByteArray? = null

    override suspend fun resolvePersistedPermissionUri(uri: String): String? = null

    override suspend fun getPersistedPermissionUris(): List<String> = emptyList()

    override suspend fun releasePersistedPermission(uri: String): Boolean = true
}
