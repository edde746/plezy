package com.edde746.plezy.desktop.secrets

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemoryLayout
import java.lang.foreign.MemoryLayout.PathElement.groupElement
import java.lang.foreign.MemorySegment
import java.lang.foreign.StructLayout
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_BYTE
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.invoke.MethodHandle
import java.nio.charset.StandardCharsets.UTF_16LE

/**
 * [SecretStore] on Windows: one generic credential per key in Credential Manager, target `com.edde746.plezy/<key>`,
 * persisted for this user on this machine only (`CRED_PERSIST_LOCAL_MACHINE`: not roamed with a domain profile).
 * Windows encrypts credentials with the user's logon secret (DPAPI).
 *
 * A credential blob holds at most 2560 bytes, so larger values continue in up to 64 attributes of 256 bytes
 * (`Plezy_Part1`, `Plezy_Part2`, …) of the same credential: one write, never a half-updated value.
 *
 * Credential Manager needs the credentials of an interactive logon: in a session without them (an SSH session with
 * key authentication, a service) every call fails with ERROR_NO_SUCH_LOGON_SESSION.
 *
 * Calls run one at a time in the process. Concurrent CredWriteW calls from several threads of one process lose
 * writes: on Windows 11, of 16 parallel writes to distinct targets, up to 14 read back stale or missing, while
 * serialized writes, also against a second process writing at the same time, lost none.
 */
internal class WindowsCredentialStore : SecretStore {
    override suspend fun get(key: String): ByteArray? = call { arena ->
        val state = arena.allocate(CAPTURE_STATE)
        val out = arena.allocate(ADDRESS)
        if (Api.credReadW.int(state, arena.wide(target(key)), CRED_TYPE_GENERIC, 0, out) == 0) {
            val error = state.lastError()
            if (error == ERROR_NOT_FOUND) return@call null
            throw failure("CredReadW", error)
        }
        val credential = out.get(ADDRESS, 0).reinterpret(CREDENTIAL.byteSize())
        try {
            readValue(credential)
        } finally {
            Api.credFree.invokeWithArguments(credential)
        }
    }

    override suspend fun put(key: String, value: ByteArray) {
        require(value.size <= MAX_VALUE_BYTES) { "A Windows credential holds at most $MAX_VALUE_BYTES bytes, not ${value.size}" }
        call { arena ->
            val blobSize = minOf(value.size, BLOB_BYTES)
            val parts = (blobSize until value.size step PART_BYTES).map { value.copyOfRange(it, minOf(it + PART_BYTES, value.size)) }
            val attributes = if (parts.isEmpty()) MemorySegment.NULL else arena.allocate(ATTRIBUTE, parts.size.toLong())
            parts.forEachIndexed { i, part ->
                val attribute = attributes.asSlice(i * ATTRIBUTE.byteSize(), ATTRIBUTE)
                attribute.set(ADDRESS, ATTRIBUTE_KEYWORD, arena.wide(PART_KEYWORD + (i + 1)))
                attribute.set(JAVA_INT, ATTRIBUTE_VALUE_SIZE, part.size)
                attribute.set(ADDRESS, ATTRIBUTE_VALUE, arena.bytes(part))
            }
            val credential = arena.allocate(CREDENTIAL)
            credential.set(JAVA_INT, CREDENTIAL_TYPE, CRED_TYPE_GENERIC)
            credential.set(ADDRESS, CREDENTIAL_TARGET_NAME, arena.wide(target(key)))
            credential.set(JAVA_INT, CREDENTIAL_BLOB_SIZE, blobSize)
            credential.set(ADDRESS, CREDENTIAL_BLOB, if (blobSize == 0) MemorySegment.NULL else arena.bytes(value.copyOfRange(0, blobSize)))
            credential.set(JAVA_INT, CREDENTIAL_PERSIST, CRED_PERSIST_LOCAL_MACHINE)
            credential.set(JAVA_INT, CREDENTIAL_ATTRIBUTE_COUNT, parts.size)
            credential.set(ADDRESS, CREDENTIAL_ATTRIBUTES, attributes)
            val state = arena.allocate(CAPTURE_STATE)
            if (Api.credWriteW.int(state, credential, 0) == 0) throw failure("CredWriteW", state.lastError())
        }
    }

    override suspend fun delete(key: String) = call { arena ->
        val state = arena.allocate(CAPTURE_STATE)
        if (Api.credDeleteW.int(state, arena.wide(target(key)), CRED_TYPE_GENERIC, 0) == 0) {
            val error = state.lastError()
            if (error != ERROR_NOT_FOUND) throw failure("CredDeleteW", error)
        }
    }

    override suspend fun deleteAll(prefix: String) = call { arena ->
        val state = arena.allocate(CAPTURE_STATE)
        val count = arena.allocate(JAVA_INT)
        val out = arena.allocate(ADDRESS)
        // The filter, a target name prefix and `*`, ignores case: the exact prefix is checked below.
        if (Api.credEnumerateW.int(state, arena.wide(TARGET_PREFIX + prefix + "*"), 0, count, out) == 0) {
            val error = state.lastError()
            if (error == ERROR_NOT_FOUND) return@call
            throw failure("CredEnumerateW", error)
        }
        val credentials = out.get(ADDRESS, 0)
        val targets = try {
            val size = count.get(JAVA_INT, 0)
            val array = credentials.reinterpret(size * ADDRESS.byteSize())
            (0 until size).mapNotNull { i ->
                val credential = array.getAtIndex(ADDRESS, i.toLong()).reinterpret(CREDENTIAL.byteSize())
                val target = credential.get(ADDRESS, CREDENTIAL_TARGET_NAME).reinterpret(Long.MAX_VALUE).getString(0, UTF_16LE)
                target.takeIf { credential.get(JAVA_INT, CREDENTIAL_TYPE) == CRED_TYPE_GENERIC && it.startsWith(TARGET_PREFIX + prefix) }
            }
        } finally {
            Api.credFree.invokeWithArguments(credentials)
        }
        for (target in targets) {
            if (Api.credDeleteW.int(state, arena.wide(target), CRED_TYPE_GENERIC, 0) == 0) {
                val error = state.lastError()
                if (error != ERROR_NOT_FOUND) throw failure("CredDeleteW", error)
            }
        }
    }

    /** Runs [block] off the caller's thread, one call at a time. */
    private suspend fun <T> call(block: (Arena) -> T): T = withContext(Dispatchers.IO) {
        lock.withLock { Arena.ofConfined().use(block) }
    }

    private fun target(key: String): String {
        require(key.isNotEmpty()) { "Empty secret key" }
        return TARGET_PREFIX + key
    }

    private fun readValue(credential: MemorySegment): ByteArray {
        val blobSize = credential.get(JAVA_INT, CREDENTIAL_BLOB_SIZE)
        val blob = if (blobSize == 0) ByteArray(0) else credential.get(ADDRESS, CREDENTIAL_BLOB).reinterpret(blobSize.toLong()).toArray(JAVA_BYTE)
        val count = credential.get(JAVA_INT, CREDENTIAL_ATTRIBUTE_COUNT)
        if (count == 0) return blob
        val attributes = credential.get(ADDRESS, CREDENTIAL_ATTRIBUTES).reinterpret(count * ATTRIBUTE.byteSize())
        val parts = sortedMapOf<Int, ByteArray>()
        for (i in 0 until count) {
            val attribute = attributes.asSlice(i * ATTRIBUTE.byteSize(), ATTRIBUTE)
            val keyword = attribute.get(ADDRESS, ATTRIBUTE_KEYWORD).reinterpret(Long.MAX_VALUE).getString(0, UTF_16LE)
            val index = keyword.removePrefix(PART_KEYWORD).takeIf { it != keyword }?.toIntOrNull() ?: continue
            val size = attribute.get(JAVA_INT, ATTRIBUTE_VALUE_SIZE)
            parts[index] = if (size == 0) ByteArray(0) else attribute.get(ADDRESS, ATTRIBUTE_VALUE).reinterpret(size.toLong()).toArray(JAVA_BYTE)
        }
        check(parts.keys.toList() == (1..parts.size).toList()) { "Credential parts ${parts.keys} are not contiguous" }
        return parts.values.fold(blob) { acc, part -> acc + part }
    }

    companion object {
        const val TARGET_PREFIX = "com.edde746.plezy/"

        private const val CRED_TYPE_GENERIC = 1
        private const val CRED_PERSIST_LOCAL_MACHINE = 2
        private const val ERROR_NOT_FOUND = 1168
        private const val ERROR_NO_SUCH_LOGON_SESSION = 1312

        // CRED_MAX_CREDENTIAL_BLOB_SIZE, CRED_MAX_ATTRIBUTES, CRED_MAX_VALUE_SIZE.
        private const val BLOB_BYTES = 5 * 512
        private const val MAX_PARTS = 64
        private const val PART_BYTES = 256
        private const val MAX_VALUE_BYTES = BLOB_BYTES + MAX_PARTS * PART_BYTES
        private const val PART_KEYWORD = "Plezy_Part"

        /** One lock for every instance (see the class comment). */
        private val lock = Mutex()

        /** CREDENTIALW (x64). */
        private val CREDENTIAL: StructLayout = MemoryLayout.structLayout(
            JAVA_INT.withName("Flags"),
            JAVA_INT.withName("Type"),
            ADDRESS.withName("TargetName"),
            ADDRESS.withName("Comment"),
            MemoryLayout.structLayout(JAVA_INT, JAVA_INT).withName("LastWritten"), // FILETIME
            JAVA_INT.withName("CredentialBlobSize"),
            MemoryLayout.paddingLayout(4),
            ADDRESS.withName("CredentialBlob"),
            JAVA_INT.withName("Persist"),
            JAVA_INT.withName("AttributeCount"),
            ADDRESS.withName("Attributes"),
            ADDRESS.withName("TargetAlias"),
            ADDRESS.withName("UserName"),
        )
        private val CREDENTIAL_TYPE = CREDENTIAL.byteOffset(groupElement("Type"))
        private val CREDENTIAL_TARGET_NAME = CREDENTIAL.byteOffset(groupElement("TargetName"))
        private val CREDENTIAL_BLOB_SIZE = CREDENTIAL.byteOffset(groupElement("CredentialBlobSize"))
        private val CREDENTIAL_BLOB = CREDENTIAL.byteOffset(groupElement("CredentialBlob"))
        private val CREDENTIAL_PERSIST = CREDENTIAL.byteOffset(groupElement("Persist"))
        private val CREDENTIAL_ATTRIBUTE_COUNT = CREDENTIAL.byteOffset(groupElement("AttributeCount"))
        private val CREDENTIAL_ATTRIBUTES = CREDENTIAL.byteOffset(groupElement("Attributes"))

        /** CREDENTIAL_ATTRIBUTEW (x64). */
        private val ATTRIBUTE: StructLayout = MemoryLayout.structLayout(
            ADDRESS.withName("Keyword"),
            JAVA_INT.withName("Flags"),
            JAVA_INT.withName("ValueSize"),
            ADDRESS.withName("Value"),
        )
        private val ATTRIBUTE_KEYWORD = ATTRIBUTE.byteOffset(groupElement("Keyword"))
        private val ATTRIBUTE_VALUE_SIZE = ATTRIBUTE.byteOffset(groupElement("ValueSize"))
        private val ATTRIBUTE_VALUE = ATTRIBUTE.byteOffset(groupElement("Value"))

        private val CAPTURE_STATE: StructLayout = Linker.Option.captureStateLayout()
        private val LAST_ERROR = CAPTURE_STATE.byteOffset(groupElement("GetLastError"))

        private fun MemorySegment.lastError(): Int = get(JAVA_INT, LAST_ERROR)

        private fun Arena.wide(text: String): MemorySegment = allocateFrom(text, UTF_16LE)

        private fun Arena.bytes(bytes: ByteArray): MemorySegment = allocate(bytes.size.toLong()).copyFrom(MemorySegment.ofArray(bytes))

        private fun failure(function: String, error: Int): IllegalStateException {
            val detail = if (error == ERROR_NO_SUCH_LOGON_SESSION) {
                "this logon session has no credentials; Credential Manager needs an interactive logon"
            } else {
                Api.describe(error)
            }
            return IllegalStateException("$function failed: error $error ($detail)")
        }
    }

    /** advapi32's credential functions, bound on first use. */
    private object Api {
        private val advapi32 = SymbolLookup.libraryLookup("advapi32", Arena.global())
        private val kernel32 = SymbolLookup.libraryLookup("kernel32", Arena.global())
        private val lastError = Linker.Option.captureCallState("GetLastError")

        val credReadW: MethodHandle = advapi32.bind("CredReadW", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, ADDRESS), lastError)
        val credWriteW: MethodHandle = advapi32.bind("CredWriteW", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT), lastError)
        val credDeleteW: MethodHandle = advapi32.bind("CredDeleteW", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT), lastError)
        val credEnumerateW: MethodHandle =
            advapi32.bind("CredEnumerateW", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, ADDRESS, ADDRESS), lastError)
        val credFree: MethodHandle = advapi32.bind("CredFree", FunctionDescriptor.ofVoid(ADDRESS))
        private val formatMessageW = kernel32.bind(
            "FormatMessageW",
            FunctionDescriptor.of(JAVA_INT, JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, ADDRESS, JAVA_INT, ADDRESS),
        )

        /** The system's text for a Win32 error code. */
        fun describe(error: Int): String = Arena.ofConfined().use { arena ->
            val chars = 512
            val buffer = arena.allocate(chars * 2L)
            val flags = 0x1000 or 0x200 // FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS
            val length = formatMessageW.int(flags, MemorySegment.NULL, error, 0, buffer, chars, MemorySegment.NULL)
            if (length == 0) "no description" else buffer.getString(0, UTF_16LE).trim()
        }
    }
}
