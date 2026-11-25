package com.edde746.plezy.secrets

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/**
 * The [SecretStore] contract, run against every platform store: the Android Keystore store (androidDeviceTest), the
 * Keychain (iosTest, tvosTest), Windows Credential Manager and libsecret (app-desktop's `secretStoreTest`).
 *
 * Every key a test writes is unique to the test instance and deleted afterwards, so the suite can run against a
 * user's real store. app-desktop compiles this directory too: it holds only this suite and uses only public API.
 */
abstract class SecretStoreContract {
    /** A store over the platform's storage. Two stores from this function see the same entries. */
    protected abstract fun createStore(): SecretStore

    private val store by lazy { createStore() }
    private val run = Random.nextLong().toULong().toString(16)
    private val written = mutableSetOf<String>()

    /** A key unique to this test instance, deleted after the test. Dots are part of the name. */
    private fun key(name: String): String = "plezy-test.$run.$name".also { written += it }

    private fun bytes(size: Int, seed: Int): ByteArray = Random(seed).nextBytes(size)

    @AfterTest
    fun deleteWrittenKeys() = runTest {
        for (key in written) store.delete(key)
    }

    @Test
    fun missingKeyReadsAsNull() = runTest {
        assertNull(store.get(key("never.written")))
    }

    @Test
    fun storedValueReadsBackInAnotherStore() = runTest {
        val key = key("account.session")
        val value = bytes(32, seed = 1)
        store.put(key, value)
        assertContentEquals(value, store.get(key))
        assertContentEquals(value, createStore().get(key), "a second store sees the persisted value")
    }

    @Test
    fun putReplacesThePreviousValue() = runTest {
        val key = key("session")
        // Grows past and shrinks below every size boundary an implementation might split at.
        for ((i, size) in listOf(100, 3, 4096, 2600, 1).withIndex()) {
            val value = bytes(size, seed = 10 + i)
            store.put(key, value)
            assertContentEquals(value, store.get(key), "after writing $size bytes")
        }
        assertContentEquals(bytes(1, seed = 14), createStore().get(key))
    }

    @Test
    fun deleteRemovesTheValue() = runTest {
        val key = key("tracker.trakt.refresh")
        store.put(key, bytes(48, seed = 2))
        store.delete(key)
        assertNull(store.get(key))
        assertNull(createStore().get(key))
        // Deleting again, and deleting a key that never existed, is not an error.
        store.delete(key)
        store.delete(key("never.written"))
        assertNull(store.get(key))
    }

    @Test
    fun deleteAllRemovesTheKeysUnderItsPrefixOnly() = runTest {
        val under = listOf(key("reset.a"), key("reset.b.c"))
        val other = key("kept")
        for (key in under + other) store.put(key, bytes(16, seed = key.length))

        store.deleteAll("plezy-test.$run.reset.")

        for (key in under) assertNull(createStore().get(key), "$key is under the prefix")
        assertNotNull(createStore().get(other), "$other is not")
        // Nothing left under it is not an error.
        store.deleteAll("plezy-test.$run.reset.")
    }

    @Test
    fun emptyValueIsStoredNotMissing() = runTest {
        val key = key("empty")
        store.put(key, ByteArray(0))
        val read = assertNotNull(store.get(key), "an empty value is a value")
        assertContentEquals(ByteArray(0), read)
        assertContentEquals(ByteArray(0), createStore().get(key))
    }

    @Test
    fun fourKibibytesOfEveryByteValueRoundTrip() = runTest {
        val key = key("large")
        // Every byte value, zeros and invalid UTF-8 included, then random bytes up to the 4 KiB limit.
        val value = ByteArray(256) { it.toByte() } + ByteArray(256) + bytes(4096 - 512, seed = 3)
        store.put(key, value)
        assertContentEquals(value, store.get(key))
        assertContentEquals(value, createStore().get(key))
    }

    @Test
    fun keysWithDotsAreDistinctEntries() = runTest {
        val names = listOf("account", "account.session", "account.session.old", "account_session", "account.sessio", ".account.session.")
        val keys = names.map(::key)
        keys.forEachIndexed { i, key -> store.put(key, byteArrayOf(i.toByte(), 0, i.toByte())) }
        keys.forEachIndexed { i, key -> assertContentEquals(byteArrayOf(i.toByte(), 0, i.toByte()), store.get(key), key) }

        store.delete(keys[1])
        assertNull(store.get(keys[1]))
        keys.forEachIndexed { i, key ->
            if (i != 1) assertContentEquals(byteArrayOf(i.toByte(), 0, i.toByte()), store.get(key), "$key survives deleting ${keys[1]}")
        }
    }

    @Test
    fun concurrentCallsFromManyThreadsAllLand() = runTest {
        val keys = (0 until 16).map { key("parallel.$it") }
        withContext(Dispatchers.Default) {
            keys.mapIndexed { i, key -> async { store.put(key, bytes(64 + i, seed = 100 + i)) } }.awaitAll()
            // Overwrites and reads interleaved across threads.
            keys.mapIndexed { i, key ->
                async {
                    store.put(key, bytes(16 + i, seed = 200 + i))
                    assertContentEquals(bytes(16 + i, seed = 200 + i), store.get(key))
                }
            }.awaitAll()
        }
        keys.forEachIndexed { i, key -> assertContentEquals(bytes(16 + i, seed = 200 + i), createStore().get(key)) }
    }
}
