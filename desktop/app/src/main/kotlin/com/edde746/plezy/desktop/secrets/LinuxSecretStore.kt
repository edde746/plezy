package com.edde746.plezy.desktop.secrets

import com.edde746.plezy.log.Log
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.nio.channels.Channels
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.NoSuchFileException
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.nio.file.attribute.PosixFilePermission
import java.nio.file.attribute.PosixFilePermissions
import java.util.Base64
import java.util.Properties

/**
 * [SecretStore] on Linux: the Secret Service ([service], libsecret) where the session has one, else [file], readable by
 * this user alone. Many Linux desktops have no Secret Service (no keyring daemon, a minimal window manager, a sandbox
 * without the portal), and Plezy never needed one, so the app starts there as well.
 *
 * A value written while there was no Secret Service is still found once one appears: [get] falls back to [file] for
 * keys the service lacks, and [put] into the service removes the file's copy.
 */
internal class LinuxSecretStore(private val service: SecretStore, private val file: SecretFile) : SecretStore {
    override suspend fun get(key: String): ByteArray? = try {
        service.get(key) ?: file.get(key)
    } catch (e: SecretServiceUnavailableException) {
        unavailable(e)
        file.get(key)
    }

    override suspend fun put(key: String, value: ByteArray) {
        try {
            service.put(key, value)
        } catch (e: SecretServiceUnavailableException) {
            unavailable(e)
            file.put(key, value)
            return
        }
        file.delete(key)
    }

    override suspend fun delete(key: String) {
        try {
            service.delete(key)
        } catch (e: SecretServiceUnavailableException) {
            unavailable(e)
        }
        file.delete(key)
    }

    override suspend fun deleteAll(prefix: String) {
        try {
            service.deleteAll(prefix)
        } catch (e: SecretServiceUnavailableException) {
            unavailable(e)
        }
        file.deleteAll(prefix)
    }

    @Volatile private var reported = false

    private fun unavailable(e: SecretServiceUnavailableException) {
        if (reported) return
        reported = true
        Log.w(TAG, e) { "No Secret Service: secrets are kept in ${file.path}, readable by this user alone" }
    }

    private companion object {
        const val TAG = "LinuxSecretStore"
    }
}

/**
 * Secrets in the file at [path]: one Base64 value per key, the file readable and writable by this user alone and
 * replaced as a whole on every change (written beside it, then moved over it), so a crash leaves the old or the new
 * file. A file that can't be read or written fails the call.
 */
internal class SecretFile(val path: Path) {
    private val lock = Mutex()

    suspend fun get(key: String): ByteArray? = access { read().getProperty(key)?.let(Base64.getDecoder()::decode) }

    suspend fun put(key: String, value: ByteArray) = access {
        val entries = read()
        entries.setProperty(key, Base64.getEncoder().encodeToString(value))
        write(entries)
    }

    suspend fun delete(key: String) = access {
        val entries = read()
        if (entries.remove(key) != null) write(entries)
    }

    suspend fun deleteAll(prefix: String) = access {
        val entries = read()
        if (entries.keys.removeAll { (it as String).startsWith(prefix) }) write(entries)
    }

    private suspend fun <T> access(block: () -> T): T = withContext(Dispatchers.IO) { lock.withLock { block() } }

    private fun read(): Properties = Properties().apply {
        try {
            Files.newBufferedReader(path).use(::load)
        } catch (_: NoSuchFileException) {
            // No secret was kept in a file yet.
        }
    }

    private fun write(entries: Properties) {
        path.parent?.let { Files.createDirectories(it) }
        val temporary = path.resolveSibling("${path.fileName}.tmp")
        Files.deleteIfExists(temporary)
        val privateFile = PosixFilePermissions.asFileAttribute(setOf(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE))
        FileChannel.open(temporary, setOf(StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE), privateFile).use { channel ->
            entries.store(Channels.newOutputStream(channel), null)
            // On disk before the move, or a crash could publish a file whose contents were never written.
            channel.force(true)
        }
        Files.move(temporary, path, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
    }
}
