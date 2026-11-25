package com.edde746.plezy.data.recovery

import com.edde746.plezy.secrets.KeychainSecretStore
import kotlinx.cinterop.ExperimentalForeignApi
import platform.CoreFoundation.CFBooleanGetTypeID
import platform.CoreFoundation.CFGetTypeID
import platform.CoreFoundation.CFRelease
import platform.Foundation.CFBridgingRetain
import platform.Foundation.NSNumber
import platform.Foundation.NSUserDefaults

/**
 * [RecoveryStore] in the standard user defaults, which the system keeps when it purges an Apple TV app's Caches. A
 * value set is read back at once and held by the defaults' daemon, so it survives the app's crash; the daemon writes it
 * to disk on its own schedule, so a power loss before then can lose it.
 */
internal class UserDefaultsRecoveryStore(private val defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults) : RecoveryStore {
    override fun contains(key: String): Boolean = defaults.objectForKey(key) != null

    override fun string(key: String): String? = defaults.objectForKey(key) as? String

    // A number stored as one isn't a boolean, though `boolForKey` would read it as one.
    @OptIn(ExperimentalForeignApi::class)
    override fun boolean(key: String): Boolean? {
        val value = defaults.objectForKey(key) as? NSNumber ?: return null
        val ref = CFBridgingRetain(value) ?: return null
        try {
            return if (CFGetTypeID(ref) == CFBooleanGetTypeID()) value.boolValue else null
        } finally {
            CFRelease(ref)
        }
    }

    override fun putString(key: String, value: String) = defaults.setObject(value, key)

    override fun putBoolean(key: String, value: Boolean) = defaults.setBool(value, key)

    override fun remove(key: String) = defaults.removeObjectForKey(key)
}

/**
 * Whether the Keychain holds any of the app's secrets ([KeychainSecretStore.hasAny]): tokens of accounts signed in
 * here, which outlive a purge of the database.
 */
internal fun keychainHoldsSecrets(): Boolean = KeychainSecretStore().hasAny()
