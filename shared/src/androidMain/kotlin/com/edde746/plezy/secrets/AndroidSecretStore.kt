package com.edde746.plezy.secrets

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import com.edde746.plezy.log.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.security.GeneralSecurityException
import java.security.KeyStore
import java.util.concurrent.ConcurrentHashMap
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * [SecretStore] on Android. Each value is sealed with AES-256-GCM (the key name as associated data, so an entry can't
 * be moved to another name) under one key held in the Android Keystore: non-exportable, and usable without user
 * authentication or an unlocked device, so background sync can read it. The ciphertext lives in the app-private
 * SharedPreferences file [PREFERENCES_NAME] (`shared_prefs/com.edde746.plezy.secrets.xml`).
 *
 * Keystore keys are never backed up or transferred, and the app excludes the preferences file from cloud backup and
 * device transfer. Should ciphertext still outlive its key (a restore that ignored the rules, a wiped Keystore, an OS
 * bug), the store drops what it can no longer open and reports those entries as missing; the next [put] creates a
 * new key. Only two things count as that: the Keystore has no key ([KeyStore.getKey] returns null), or an entry fails
 * its authentication tag under the key (or is malformed: that entry alone goes). Any other Keystore failure throws
 * from [get] and [put] and keeps every entry for a later attempt: keystore2 reports its transient failures (a system
 * error, a binder call that failed) as `UnrecoverableKeyException`, the same as a key it can't use, so its callers see
 * them as a failure of the store.
 *
 * A store keeps the Keystore key it loaded and each value it sealed or opened, so reading a value again costs no
 * Keystore call: the app makes one store for its process. A kept value serves a read only while the stored entry is
 * still the one it came from (each seal picks a new IV, so a write by another store reads as a change), and a delete or
 * a new key drops it.
 */
class AndroidSecretStore internal constructor(
    context: Context,
    private val preferencesName: String,
    private val keyAlias: String,
) : SecretStore {
    constructor(context: Context) : this(context, PREFERENCES_NAME, KEY_ALIAS)

    private val context: Context = context.applicationContext ?: context
    private val preferences: SharedPreferences by lazy { this.context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE) }

    // Guarded by [lock], as every Keystore and preferences change.
    private var secretKey: SecretKey? = null

    // The values this store sealed or opened, by key, with the entry each came from. Read without [lock].
    private val opened = ConcurrentHashMap<String, Opened>()

    // Set once [preferences] has loaded under [lock]: a read can then check its entry without waiting for the disk.
    @Volatile private var loaded = false

    override suspend fun get(key: String): ByteArray? {
        if (loaded) {
            val entry = preferences.getString(key, null) ?: return null
            opened[key]?.takeIf { it.entry == entry }?.let { return it.value.copyOf() }
        }
        return locked { read(key) }
    }

    private fun read(key: String): ByteArray? {
        val entry = preferences.getString(key, null) ?: return null
        opened[key]?.takeIf { it.entry == entry }?.let { return it.value.copyOf() }
        val secretKey = key() ?: run {
            // Ciphertext without its key can never be opened again.
            Log.w(TAG) { "The Keystore key is gone; dropping ${preferences.all.size} unreadable entries" }
            resetKey()
            return null
        }
        return try {
            open(secretKey, key, entry).also { opened[key] = Opened(entry, it.copyOf()) }
        } catch (e: AEADBadTagException) {
            // Sealed under an earlier key, or damaged: it will never open.
            Log.w(TAG, e) { "Dropping '$key': it doesn't open under the current key" }
            remove(key)
            null
        } catch (e: MalformedEntryException) {
            Log.w(TAG, e) { "Dropping '$key': malformed entry" }
            remove(key)
            null
        }
    }

    override suspend fun put(key: String, value: ByteArray) = locked {
        val entry = seal(key() ?: generateKey(), key, value)
        check(preferences.edit().putString(key, entry).commit()) { "Couldn't write $preferencesName" }
        opened[key] = Opened(entry, value.copyOf())
    }

    override suspend fun delete(key: String) = locked { remove(key) }

    override suspend fun deleteAll(prefix: String) = locked {
        val keys = preferences.all.keys.filter { it.startsWith(prefix) }
        keys.forEach(opened::remove)
        if (keys.isNotEmpty()) {
            val editor = preferences.edit()
            keys.forEach { editor.remove(it) }
            check(editor.commit()) { "Couldn't write $preferencesName" }
        }
    }

    private fun remove(key: String) {
        opened.remove(key)
        if (preferences.contains(key)) check(preferences.edit().remove(key).commit()) { "Couldn't write $preferencesName" }
    }

    /** Deletes the Keystore key and every entry sealed under it. */
    private fun resetKey() {
        secretKey = null
        opened.clear()
        try {
            keyStore().deleteEntry(keyAlias)
        } catch (e: GeneralSecurityException) {
            Log.w(TAG, e) { "Couldn't delete the Keystore key" }
        }
        check(preferences.edit().clear().commit()) { "Couldn't write $preferencesName" }
    }

    private fun keyStore(): KeyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }

    /** The Keystore key, loaded once; null when the Keystore has none. */
    private fun key(): SecretKey? = secretKey ?: (keyStore().getKey(keyAlias, null) as SecretKey?)?.also { secretKey = it }

    private fun generateKey(): SecretKey {
        // A new key can't open anything sealed before it.
        opened.clear()
        check(preferences.edit().clear().commit()) { "Couldn't write $preferencesName" }
        val spec = KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE).run {
            init(spec)
            generateKey()
        }.also { secretKey = it }
    }

    /** `version ‖ IV ‖ ciphertext ‖ tag`, Base64. The Keystore picks the IV (randomized encryption). */
    private fun seal(secretKey: SecretKey, key: String, value: ByteArray): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        cipher.updateAAD(key.encodeToByteArray())
        val sealed = cipher.doFinal(value)
        val iv = cipher.iv
        check(iv.size == IV_BYTES) { "Unexpected GCM IV size ${iv.size}" }
        return Base64.encodeToString(byteArrayOf(FORMAT_VERSION) + iv + sealed, Base64.NO_WRAP)
    }

    private fun open(secretKey: SecretKey, key: String, entry: String): ByteArray {
        val bytes = try {
            Base64.decode(entry, Base64.NO_WRAP)
        } catch (e: IllegalArgumentException) {
            throw MalformedEntryException("not Base64")
        }
        if (bytes.size < 1 + IV_BYTES + TAG_BITS / 8 || bytes[0] != FORMAT_VERSION) throw MalformedEntryException("unknown format")
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, GCMParameterSpec(TAG_BITS, bytes, 1, IV_BYTES))
        cipher.updateAAD(key.encodeToByteArray())
        return cipher.doFinal(bytes, 1 + IV_BYTES, bytes.size - 1 - IV_BYTES)
    }

    private suspend fun <T> locked(block: () -> T): T = withContext(Dispatchers.IO) {
        lock.withLock {
            try {
                block().also { loaded = true }
            } catch (e: Exception) {
                // A Keystore failure loads the key again next time, as a store that kept nothing would.
                secretKey = null
                throw e
            }
        }
    }

    private class Opened(val entry: String, val value: ByteArray)

    private class MalformedEntryException(message: String) : Exception(message)

    companion object {
        /** The SharedPreferences file (`shared_prefs/<name>.xml`) the app excludes from backup and device transfer. */
        const val PREFERENCES_NAME = "com.edde746.plezy.secrets"

        private const val KEY_ALIAS = "com.edde746.plezy.secrets"
        private const val KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val IV_BYTES = 12
        private const val TAG_BITS = 128
        private const val FORMAT_VERSION: Byte = 1
        private const val TAG = "SecretStore"

        /** One lock for every instance: they share the preferences file and the Keystore key. */
        private val lock = Mutex()
    }
}
