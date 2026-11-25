package com.edde746.plezy.desktop.secrets

import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.runBlocking
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.attribute.PosixFilePermissions
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LinuxSecretStoreTest {
    // The file store is Linux's: it needs POSIX permissions, which a Windows test host's file system lacks.
    private val posix = "posix" in FileSystems.getDefault().supportedFileAttributeViews()
    private val path = Files.createTempDirectory("plezy-secrets").resolve("data").resolve(SECRETS_FILE)
    private val token = "jellyfin-token".encodeToByteArray()

    /** A Secret Service that is missing ([available] false) or keeps its items in memory. */
    private class Service(var available: Boolean) : SecretStore {
        val items = mutableMapOf<String, ByteArray>()

        private fun check() {
            if (!available) throw SecretServiceUnavailableException("The name org.freedesktop.secrets was not provided by any .service files")
        }

        override suspend fun get(key: String): ByteArray? = check().let { items[key] }

        override suspend fun put(key: String, value: ByteArray) = check().let { items[key] = value }

        override suspend fun delete(key: String) = check().let { items.remove(key); Unit }

        override suspend fun deleteAll(prefix: String) {
            check()
            items.keys.removeAll { it.startsWith(prefix) }
        }
    }

    private fun store(service: SecretStore) = LinuxSecretStore(service, SecretFile(path))

    @Test
    fun `without a Secret Service secrets go to a file only this user can read`() = runBlocking {
        if (!posix) return@runBlocking
        store(Service(available = false)).put("connection.jellyfin", token)

        assertContentEquals(token, store(Service(available = false)).get("connection.jellyfin"), "a later start reads it back")
        assertEquals("rw-------", PosixFilePermissions.toString(Files.getPosixFilePermissions(path)))
        store(Service(available = false)).delete("connection.jellyfin")
        assertNull(store(Service(available = false)).get("connection.jellyfin"))
    }

    @Test
    fun `a secret kept in the file is found once a Secret Service appears and moves into it on the next write`() = runBlocking {
        if (!posix) return@runBlocking
        store(Service(available = false)).put("connection.jellyfin", token)
        val service = Service(available = true)

        assertContentEquals(token, store(service).get("connection.jellyfin"))
        val renewed = "renewed".encodeToByteArray()
        store(service).put("connection.jellyfin", renewed)
        assertContentEquals(renewed, service.items["connection.jellyfin"])
        assertNull(SecretFile(path).get("connection.jellyfin"), "the file keeps no copy once the service has it")
    }

    @Test
    fun `with a Secret Service no file is written`() = runBlocking {
        if (!posix) return@runBlocking
        val service = Service(available = true)
        store(service).put("connection.jellyfin", token)

        assertContentEquals(token, store(service).get("connection.jellyfin"))
        assertFalse(Files.exists(path))
    }

    @Test
    fun `deleteAll removes the keys under its prefix from the Secret Service and the file`() = runBlocking {
        if (!posix) return@runBlocking
        store(Service(available = false)).put("profile.1.token", token)
        store(Service(available = false)).put("connection.jellyfin", token)
        val service = Service(available = true)
        store(service).put("profile.2.token", token)
        store(service).put("profile", token)

        store(service).deleteAll("profile.")

        assertEquals(setOf("profile"), service.items.keys)
        assertNull(SecretFile(path).get("profile.1.token"))
        assertContentEquals(token, SecretFile(path).get("connection.jellyfin"))
    }

    @Test
    fun `deleteAll without a Secret Service still empties the file`() = runBlocking {
        if (!posix) return@runBlocking
        store(Service(available = false)).put("profile.1.token", token)

        store(Service(available = false)).deleteAll("")

        assertNull(SecretFile(path).get("profile.1.token"))
    }

    @Test
    fun `a file that cannot be written fails the write`() = runBlocking {
        if (!posix) return@runBlocking
        // The data folder's place is taken by a file: the secrets' file can't be made.
        Files.createDirectories(path.parent.parent)
        Files.writeString(path.parent, "not a folder")

        assertIs<java.io.IOException>(runCatching { store(Service(available = false)).put("connection.jellyfin", token) }.exceptionOrNull())
    }

    @Test
    fun `a failing Secret Service is not mistaken for a missing one`() = runBlocking {
        if (!posix) return@runBlocking
        val failing = object : SecretStore {
            override suspend fun get(key: String): ByteArray? = error("libsecret lookup failed (secret-error): locked")

            override suspend fun put(key: String, value: ByteArray) = error("libsecret store failed (secret-error): locked")

            override suspend fun delete(key: String) = error("libsecret clear failed (secret-error): locked")

            override suspend fun deleteAll(prefix: String) = error("libsecret search failed (secret-error): locked")
        }

        val failure = runCatching { store(failing).put("connection.jellyfin", token) }.exceptionOrNull()
        assertIs<IllegalStateException>(failure)
        assertTrue(failure !is SecretServiceUnavailableException && failure.message!!.contains("locked"))
        assertFalse(Files.exists(path))
    }
}
