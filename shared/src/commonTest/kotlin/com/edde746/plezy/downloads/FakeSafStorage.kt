package com.edde746.plezy.downloads

/**
 * A [SafStorageOperations] that only answers reachability ([exists]): whether a downloaded `content://` copy is still
 * there, which decides local playback versus streaming. Every other operation throws: a suite reaching one needs a
 * richer fake.
 *
 * @param reachable the answer for every URI when [existing] is null.
 * @param existing when set, exactly the reachable URIs ([reachable] is ignored).
 */
class FakeSafStorage(
    private val reachable: Boolean = true,
    private val existing: Set<String>? = null,
) : SafStorageOperations {
    /** URIs passed to [exists], in call order. */
    val existsCalls = mutableListOf<String>()

    override val isAvailable: Boolean get() = true

    override suspend fun exists(uri: String, isDir: Boolean): Boolean {
        existsCalls += uri
        return existing?.contains(uri) ?: reachable
    }

    override suspend fun getChild(parentUri: String, names: List<String>): SafDocumentFile? = throw UnsupportedOperationException("getChild")

    override suspend fun createNestedDirectories(parentUri: String, pathComponents: List<String>): String? =
        throw UnsupportedOperationException("createNestedDirectories")

    override suspend fun delete(uri: String, isDir: Boolean): Boolean = throw UnsupportedOperationException("delete")

    override suspend fun list(uri: String): List<SafDocumentFile>? = throw UnsupportedOperationException("list")

    override suspend fun size(uri: String): Long? = throw UnsupportedOperationException("size")

    override suspend fun read(uri: String, offset: Long, length: Int): ByteArray? = throw UnsupportedOperationException("read")

    override suspend fun resolvePersistedPermissionUri(uri: String): String? = throw UnsupportedOperationException("resolvePersistedPermissionUri")

    override suspend fun getPersistedPermissionUris(): List<String>? = throw UnsupportedOperationException("getPersistedPermissionUris")

    override suspend fun releasePersistedPermission(uri: String): Boolean = throw UnsupportedOperationException("releasePersistedPermission")
}
