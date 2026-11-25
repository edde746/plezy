package com.edde746.plezy.downloads

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext
import kotlinx.io.Buffer
import kotlinx.io.IOException
import kotlinx.io.buffered
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.readByteArray

/** The download manager's file operations on local paths, run on [io]. Missing targets are no-ops. */
internal class LocalFiles(private val fileSystem: FileSystem, private val io: CoroutineDispatcher) {
    suspend fun exists(path: String): Boolean = withContext(io) { fileSystem.exists(Path(path)) }

    suspend fun isDirectory(path: String): Boolean = withContext(io) { fileSystem.metadataOrNull(Path(path))?.isDirectory == true }

    suspend fun isFile(path: String): Boolean = withContext(io) { fileSystem.metadataOrNull(Path(path))?.isRegularFile == true }

    /** The file's size in bytes; throws when it can't be read. */
    suspend fun size(path: String): Long = withContext(io) {
        fileSystem.metadataOrNull(Path(path))?.size ?: throw IOException("No file at $path")
    }

    /** Up to [length] bytes of the file from [offset] (fewer at its end); throws when it can't be read. */
    suspend fun read(path: String, offset: Long, length: Int): ByteArray = withContext(io) {
        fileSystem.source(Path(path)).buffered().use { source ->
            source.skip(offset)
            val buffer = Buffer()
            while (buffer.size < length) {
                if (source.readAtMostTo(buffer, length - buffer.size) < 0) break
            }
            buffer.readByteArray()
        }
    }

    /** The entries of directory [path] as paths; empty when it doesn't exist. */
    suspend fun list(path: String): List<String> = withContext(io) {
        val dir = Path(path)
        if (fileSystem.metadataOrNull(dir)?.isDirectory != true) emptyList() else fileSystem.list(dir).map { it.toString() }
    }

    suspend fun createDirectories(path: String) = withContext(io) { fileSystem.createDirectories(Path(path)) }

    /** Renames file [from] to [to], replacing what is there; throws when it can't. */
    suspend fun move(from: String, to: String) = withContext(io) { fileSystem.atomicMove(Path(from), Path(to)) }

    /** Deletes the file (or empty directory) at [path]; true when it existed. Failures are logged, never thrown. */
    suspend fun deleteIfExists(path: String, description: String): Boolean = withContext(io) {
        try {
            val target = Path(path)
            if (!fileSystem.exists(target)) return@withContext false
            fileSystem.delete(target)
            Log.i(TAG) { "Deleted $description: $path" }
            true
        } catch (e: IOException) {
            Log.w(TAG, e) { "Failed to delete $description: $path" }
            false
        }
    }

    /** Deletes directory [path] with everything in it; true when it existed. */
    suspend fun deleteRecursively(path: String): Boolean = withContext(io) {
        val root = Path(path)
        if (!fileSystem.exists(root)) return@withContext false
        fun remove(target: Path) {
            if (fileSystem.metadataOrNull(target)?.isDirectory == true) fileSystem.list(target).forEach(::remove)
            fileSystem.delete(target)
        }
        remove(root)
        true
    }

    private companion object {
        const val TAG = "DownloadFiles"
    }
}
