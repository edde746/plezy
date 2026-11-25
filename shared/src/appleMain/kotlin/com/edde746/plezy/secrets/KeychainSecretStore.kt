package com.edde746.plezy.secrets

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.alloc
import kotlinx.cinterop.convert
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.readBytes
import kotlinx.cinterop.reinterpret
import kotlinx.cinterop.usePinned
import kotlinx.cinterop.value
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import platform.CoreFoundation.CFDataCreate
import platform.CoreFoundation.CFDataGetBytePtr
import platform.CoreFoundation.CFDataGetLength
import platform.CoreFoundation.CFDataRef
import platform.CoreFoundation.CFDictionaryAddValue
import platform.CoreFoundation.CFDictionaryCreateMutable
import platform.CoreFoundation.CFDictionaryRef
import platform.CoreFoundation.CFMutableDictionaryRef
import platform.CoreFoundation.CFRelease
import platform.CoreFoundation.CFRetain
import platform.CoreFoundation.CFStringCreateWithCString
import platform.CoreFoundation.CFStringRef
import platform.CoreFoundation.CFTypeRef
import platform.CoreFoundation.CFTypeRefVar
import platform.CoreFoundation.kCFBooleanTrue
import platform.CoreFoundation.kCFStringEncodingUTF8
import platform.CoreFoundation.kCFTypeDictionaryKeyCallBacks
import platform.CoreFoundation.kCFTypeDictionaryValueCallBacks
import platform.Foundation.CFBridgingRelease
import platform.Security.SecCopyErrorMessageString
import platform.Security.SecItemAdd
import platform.Security.SecItemCopyMatching
import platform.Security.SecItemDelete
import platform.Security.SecItemUpdate
import platform.Security.errSecDuplicateItem
import platform.Security.errSecItemNotFound
import platform.Security.errSecSuccess
import platform.Security.kSecAttrAccessible
import platform.Security.kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
import platform.Security.kSecAttrAccount
import platform.Security.kSecAttrService
import platform.Security.kSecClass
import platform.Security.kSecClassGenericPassword
import platform.Security.kSecMatchLimit
import platform.Security.kSecMatchLimitAll
import platform.Security.kSecMatchLimitOne
import platform.Security.kSecReturnAttributes
import platform.Security.kSecReturnData
import platform.Security.kSecUseDataProtectionKeychain
import platform.Security.kSecValueData
import kotlin.experimental.ExperimentalNativeApi

/**
 * [SecretStore] on iOS, iPadOS, macOS and tvOS: one Keychain generic password per key (service [SERVICE], account =
 * the key), readable after the first unlock following a boot, so background refreshes work while the device is
 * locked. `ThisDeviceOnly` keeps the items out of iCloud Keychain and out of backups restored onto another device.
 *
 * On macOS the items go to the data protection keychain (the iOS-style one), not a file-based login keychain; that
 * needs the app to be signed with an application identifier (a team-signed build, as for every sandboxed app).
 * Items live in the app's default access group; every app and extension that should share them needs the same
 * `keychain-access-groups` entitlement.
 *
 * Failures other than "not found" throw [KeychainException] (e.g. -34018, a missing entitlement).
 */
@OptIn(ExperimentalForeignApi::class)
class KeychainSecretStore internal constructor(private val service: String) : SecretStore {
    constructor() : this(SERVICE)

    override suspend fun get(key: String): ByteArray? = withContext(Dispatchers.IO) {
        memScoped {
            val result = alloc<CFTypeRefVar>()
            val status = withQuery(key, { returnDataOnce() }) { SecItemCopyMatching(it, result.ptr) }
            when (status) {
                errSecSuccess -> {
                    val data: CFDataRef = checkNotNull(result.value).reinterpret()
                    try {
                        val length = CFDataGetLength(data).toInt()
                        if (length == 0) ByteArray(0) else checkNotNull(CFDataGetBytePtr(data)).readBytes(length)
                    } finally {
                        CFRelease(data)
                    }
                }
                errSecItemNotFound -> null
                else -> throw KeychainException("read", status)
            }
        }
    }

    override suspend fun put(key: String, value: ByteArray) = withContext(Dispatchers.IO) {
        // One writer per process, so an update that finds nothing and the add that follows don't race each other.
        lock.withLock {
            var status = update(key, value)
            if (status == errSecItemNotFound) {
                status = withQuery(key, { valueAndAccess(value) }) { SecItemAdd(it, null) }
                // Added by another process in between.
                if (status == errSecDuplicateItem) status = update(key, value)
            }
            if (status != errSecSuccess) throw KeychainException("write", status)
        }
    }

    override suspend fun delete(key: String) = withContext(Dispatchers.IO) {
        val status = withQuery(key, {}) { SecItemDelete(it) }
        if (status != errSecSuccess && status != errSecItemNotFound) throw KeychainException("delete", status)
    }

    override suspend fun deleteAll(prefix: String) = withContext(Dispatchers.IO) {
        val accounts = memScoped {
            val result = alloc<CFTypeRefVar>()
            val status = withQuery(null, {
                add(kSecReturnAttributes, kCFBooleanTrue)
                add(kSecMatchLimit, kSecMatchLimitAll)
            }) { SecItemCopyMatching(it, result.ptr) }
            when (status) {
                errSecSuccess -> (CFBridgingRelease(result.value) as List<*>).mapNotNull { (it as Map<*, *>)[accountAttribute] as? String }
                errSecItemNotFound -> emptyList()
                else -> throw KeychainException("list", status)
            }
        }
        for (account in accounts.filter { it.startsWith(prefix) }) {
            val status = withQuery(account, {}) { SecItemDelete(it) }
            if (status != errSecSuccess && status != errSecItemNotFound) throw KeychainException("delete", status)
        }
    }

    /**
     * Whether the Keychain holds any item of this store, synchronously. A Keychain that can't be asked counts as holding
     * some.
     */
    fun hasAny(): Boolean = withQuery(null, { add(kSecMatchLimit, kSecMatchLimitOne) }) { SecItemCopyMatching(it, null) } != errSecItemNotFound

    private fun update(key: String, value: ByteArray): Int {
        val attributes = dictionary { valueAndAccess(value) }
        try {
            return withQuery(key, {}) { SecItemUpdate(it, attributes) }
        } finally {
            CFRelease(attributes)
        }
    }

    /** The query that identifies [key]'s item (every item of [service] for null), plus [extra], for the duration of [block]. */
    private inline fun <T> withQuery(key: String?, extra: CFMutableDictionaryRef.() -> Unit, block: (CFDictionaryRef) -> T): T {
        val query = dictionary {
            add(kSecClass, kSecClassGenericPassword)
            add(kSecAttrService, service)
            if (key != null) add(kSecAttrAccount, key)
            if (isMacOs) add(kSecUseDataProtectionKeychain, kCFBooleanTrue)
            extra()
        }
        try {
            return block(query)
        } finally {
            CFRelease(query)
        }
    }

    private fun CFMutableDictionaryRef.returnDataOnce() {
        add(kSecReturnData, kCFBooleanTrue)
        add(kSecMatchLimit, kSecMatchLimitOne)
    }

    private fun CFMutableDictionaryRef.valueAndAccess(value: ByteArray) {
        add(kSecValueData, value)
        add(kSecAttrAccessible, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
    }

    companion object {
        /** The Keychain service of every item. */
        const val SERVICE = "com.edde746.plezy"

        private val lock = Mutex()

        /** The key of an item's account in the attributes [SecItemCopyMatching] returns. */
        private val accountAttribute: String = CFBridgingRelease(CFRetain(kSecAttrAccount)) as String

        @OptIn(ExperimentalNativeApi::class)
        private val isMacOs = Platform.osFamily == OsFamily.MACOSX
    }
}

/** A Keychain call failed with [status] (an `OSStatus`, e.g. -34018 for a missing entitlement). */
class KeychainException(operation: String, val status: Int) : Exception("Keychain $operation failed: OSStatus $status (${describe(status)})")

@OptIn(ExperimentalForeignApi::class)
private fun describe(status: Int): String =
    SecCopyErrorMessageString(status, null)?.let { CFBridgingRelease(it) as? String } ?: "no description"

// Dictionaries retain what they hold (kCFType callbacks), so each value created here is released once it's added.

@OptIn(ExperimentalForeignApi::class)
private inline fun dictionary(build: CFMutableDictionaryRef.() -> Unit): CFMutableDictionaryRef {
    val dictionary = checkNotNull(CFDictionaryCreateMutable(null, 0, kCFTypeDictionaryKeyCallBacks.ptr, kCFTypeDictionaryValueCallBacks.ptr))
    try {
        dictionary.build()
    } catch (e: Throwable) {
        CFRelease(dictionary)
        throw e
    }
    return dictionary
}

@OptIn(ExperimentalForeignApi::class)
private fun CFMutableDictionaryRef.add(key: CFStringRef?, value: CFTypeRef?) = CFDictionaryAddValue(this, key, value)

@OptIn(ExperimentalForeignApi::class)
private fun CFMutableDictionaryRef.add(key: CFStringRef?, value: String) {
    val string = checkNotNull(CFStringCreateWithCString(null, value, kCFStringEncodingUTF8))
    CFDictionaryAddValue(this, key, string)
    CFRelease(string)
}

@OptIn(ExperimentalForeignApi::class)
private fun CFMutableDictionaryRef.add(key: CFStringRef?, value: ByteArray) {
    val data = checkNotNull(
        if (value.isEmpty()) CFDataCreate(null, null, 0)
        else value.usePinned { CFDataCreate(null, it.addressOf(0).reinterpret(), value.size.convert()) },
    )
    CFDictionaryAddValue(this, key, data)
    CFRelease(data)
}
