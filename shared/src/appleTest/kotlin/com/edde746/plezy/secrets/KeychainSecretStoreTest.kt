package com.edde746.plezy.secrets

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.alloc
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.value
import kotlinx.coroutines.test.runTest
import platform.CoreFoundation.CFDictionaryAddValue
import platform.CoreFoundation.CFDictionaryCreateMutable
import platform.CoreFoundation.CFMutableDictionaryRef
import platform.CoreFoundation.CFRelease
import platform.CoreFoundation.CFRetain
import platform.CoreFoundation.CFStringCreateWithCString
import platform.CoreFoundation.CFStringRef
import platform.CoreFoundation.CFTypeRefVar
import platform.CoreFoundation.kCFBooleanTrue
import platform.CoreFoundation.kCFStringEncodingUTF8
import platform.CoreFoundation.kCFTypeDictionaryKeyCallBacks
import platform.CoreFoundation.kCFTypeDictionaryValueCallBacks
import platform.Foundation.CFBridgingRelease
import platform.Foundation.NSNumber
import platform.Security.SecItemCopyMatching
import platform.Security.SecItemUpdate
import platform.Security.errSecSuccess
import platform.Security.kSecAttrAccessible
import platform.Security.kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
import platform.Security.kSecAttrAccessibleWhenUnlocked
import platform.Security.kSecAttrAccount
import platform.Security.kSecAttrService
import platform.Security.kSecAttrSynchronizable
import platform.Security.kSecClass
import platform.Security.kSecClassGenericPassword
import platform.Security.kSecMatchLimit
import platform.Security.kSecMatchLimitOne
import platform.Security.kSecReturnAttributes
import platform.Security.kSecUseDataProtectionKeychain
import kotlin.experimental.ExperimentalNativeApi
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The contract plus the Keychain attributes that keep secrets on this device. */
@OptIn(ExperimentalForeignApi::class, ExperimentalNativeApi::class)
class KeychainSecretStoreTest : SecretStoreContract() {
    override fun createStore(): SecretStore = KeychainSecretStore(SERVICE)

    private val account = "plezy-test.attributes"

    @AfterTest
    fun deleteAttributeTestItem() = runTest { createStore().delete(account) }

    @Test
    fun itemsStayOnThisDeviceAndOpenAfterFirstUnlock() = runTest {
        createStore().put(account, byteArrayOf(1, 2, 3))
        assertDeviceOnly()
    }

    @Test
    fun overwritingMovesAnItemToThisDeviceOnlyAccess() = runTest {
        val store = createStore()
        store.put(account, byteArrayOf(1))
        // An item that was written with other access, e.g. by an older build.
        withItemQuery { query ->
            val attributes = CFDictionaryCreateMutable(null, 0, kCFTypeDictionaryKeyCallBacks.ptr, kCFTypeDictionaryValueCallBacks.ptr)
            CFDictionaryAddValue(attributes, kSecAttrAccessible, kSecAttrAccessibleWhenUnlocked)
            assertEquals(errSecSuccess, SecItemUpdate(query, attributes))
            CFRelease(attributes)
        }
        store.put(account, byteArrayOf(2))
        assertDeviceOnly()
        assertContentEquals(byteArrayOf(2), store.get(account))
    }

    private fun assertDeviceOnly() = withItemQuery { query ->
        CFDictionaryAddValue(query, kSecReturnAttributes, kCFBooleanTrue)
        CFDictionaryAddValue(query, kSecMatchLimit, kSecMatchLimitOne)
        memScoped {
            val result = alloc<CFTypeRefVar>()
            assertEquals(errSecSuccess, SecItemCopyMatching(query, result.ptr))
            val attributes = CFBridgingRelease(result.value) as Map<*, *>
            assertEquals(string(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly), attributes[string(kSecAttrAccessible)])
            val synchronizable = attributes[string(kSecAttrSynchronizable)] as NSNumber?
            assertTrue(synchronizable == null || !synchronizable.boolValue, "not synced to iCloud Keychain")
        }
    }

    /** A Security constant as a Kotlin string (the bridged NSString), for comparing bridged dictionaries. */
    private fun string(constant: CFStringRef?): String = CFBridgingRelease(CFRetain(constant)) as String

    private fun <T> withItemQuery(block: (CFMutableDictionaryRef?) -> T): T {
        val query = CFDictionaryCreateMutable(null, 0, kCFTypeDictionaryKeyCallBacks.ptr, kCFTypeDictionaryValueCallBacks.ptr)
        val service = CFStringCreateWithCString(null, SERVICE, kCFStringEncodingUTF8)
        val accountName = CFStringCreateWithCString(null, account, kCFStringEncodingUTF8)
        CFDictionaryAddValue(query, kSecClass, kSecClassGenericPassword)
        CFDictionaryAddValue(query, kSecAttrService, service)
        CFDictionaryAddValue(query, kSecAttrAccount, accountName)
        if (Platform.osFamily == OsFamily.MACOSX) CFDictionaryAddValue(query, kSecUseDataProtectionKeychain, kCFBooleanTrue)
        CFRelease(service)
        CFRelease(accountName)
        try {
            return block(query)
        } finally {
            CFRelease(query)
        }
    }

    private companion object {
        const val SERVICE = "com.edde746.plezy.test"
    }
}
