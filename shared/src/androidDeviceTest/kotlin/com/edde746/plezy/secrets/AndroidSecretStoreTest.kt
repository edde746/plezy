package com.edde746.plezy.secrets

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.test.runTest
import java.io.File
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.SecretKeyFactory
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFails
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The contract plus what only the Keystore-backed store has: lost keys, foreign entries, nothing readable at rest. */
class AndroidSecretStoreTest : SecretStoreContract() {
    private val context: Context = InstrumentationRegistry.getInstrumentation().targetContext
    private val preferences get() = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    override fun createStore(): SecretStore = AndroidSecretStore(context, PREFERENCES, ALIAS)

    private fun keyStore() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    @AfterTest
    fun removeTestKeyAndEntries() {
        keyStore().deleteEntry(ALIAS)
        preferences.edit().clear().commit()
    }

    @Test
    fun entriesWhoseKeystoreKeyIsGoneReadAsMissing() = runTest {
        createStore().run {
            put("lost.a", byteArrayOf(1, 2, 3))
            put("lost.b", byteArrayOf(4, 5, 6))
        }
        // What a restore onto another device, or a wiped Keystore, leaves behind: ciphertext without its key. A store
        // keeps its key for the process, so the next process's store is the one that finds it gone.
        keyStore().deleteEntry(ALIAS)
        val store = createStore()

        assertNull(store.get("lost.a"))
        assertNull(store.get("lost.b"))
        assertTrue(preferences.all.isEmpty(), "unreadable entries are dropped")

        store.put("lost.a", byteArrayOf(7))
        assertContentEquals(byteArrayOf(7), createStore().get("lost.a"))
    }

    @Test
    fun aStoreReadsWhatAnotherStoreWroteOrDeletedSinceItsLastRead() = runTest {
        val reader = createStore()
        val writer = createStore()
        writer.put("account.session", byteArrayOf(1))
        assertContentEquals(byteArrayOf(1), reader.get("account.session"))

        writer.put("account.session", byteArrayOf(2))
        assertContentEquals(byteArrayOf(2), reader.get("account.session"))

        writer.delete("account.session")
        assertNull(reader.get("account.session"))

        writer.put("account.session", byteArrayOf(3))
        assertContentEquals(byteArrayOf(3), reader.get("account.session"))
    }

    @Test
    fun aValueReadBackIsTheCallersToChange() = runTest {
        val store = createStore()
        val written = byteArrayOf(1, 2, 3)
        store.put("account.session", written)
        written[0] = 9
        assertNotNull(store.get("account.session"))[1] = 9
        assertContentEquals(byteArrayOf(1, 2, 3), store.get("account.session"))
    }

    @Test
    fun entriesMovedToAnotherNameOrDamagedReadAsMissing() = runTest {
        val store = createStore()
        store.put("real", byteArrayOf(9, 9, 9))
        val sealed = assertNotNull(preferences.getString("real", null))
        preferences.edit().putString("moved", sealed).putString("damaged", "not base64 ~~").commit()

        assertNull(store.get("moved"), "the key name is bound into the ciphertext")
        assertNull(store.get("damaged"))
        assertFalse(preferences.contains("moved"))
        assertFalse(preferences.contains("damaged"))
        assertContentEquals(byteArrayOf(9, 9, 9), store.get("real"))
    }

    @Test
    fun aKeystoreFailureOtherThanALostKeyDeletesNothing() = runTest {
        createStore().put("account.session", byteArrayOf(1, 2, 3))
        // keystore2 reports a transient failure (a system error, a binder call that failed) as it reports a key it
        // can't use. Keys this store may only decrypt, or only encrypt, with stand in for it, each met by a store that
        // loads it.
        replaceKey(KeyProperties.PURPOSE_DECRYPT)
        assertFails { createStore().put("tracker.trakt.p1", byteArrayOf(4)) }
        assertTrue(preferences.contains("account.session"), "a failed write deletes nothing")

        replaceKey(KeyProperties.PURPOSE_ENCRYPT)
        assertFails { createStore().get("account.session") }
        assertTrue(preferences.contains("account.session"), "a failed read deletes nothing")
    }

    private fun replaceKey(purposes: Int) {
        keyStore().deleteEntry(ALIAS)
        val spec = KeyGenParameterSpec.Builder(ALIAS, purposes)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()
        KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(spec)
            generateKey()
        }
    }

    @Test
    fun nothingIsReadableAtRest() = runTest {
        val value = "plaintext-marker-0123456789".encodeToByteArray()
        createStore().put("marker", value)

        val file = File(context.dataDir, "shared_prefs/$PREFERENCES.xml").readText()
        assertTrue("marker" in file)
        assertFalse("plaintext-marker" in file)
        assertFalse(Base64.encodeToString(value, Base64.NO_WRAP).take(24) in file)

        val key = keyStore().getKey(ALIAS, null) as SecretKey
        assertNull(key.encoded, "the Keystore key is not exportable")
        val info = SecretKeyFactory.getInstance(key.algorithm, "AndroidKeyStore").getKeySpec(key, KeyInfo::class.java) as KeyInfo
        assertEquals(256, info.keySize)
        assertFalse(info.isUserAuthenticationRequired, "background sync reads it without the user")
    }

    private companion object {
        const val PREFERENCES = "com.edde746.plezy.secrets.test"
        const val ALIAS = "com.edde746.plezy.secrets.test"
    }
}
