package com.edde746.plezy.secrets

/**
 * A [SecretStore] in memory, behaving as the platform stores do (values copied in and out): a development session's,
 * whose secrets (fake tracker tokens) must not reach the device's store, where they would share the tracker session
 * index with the product.
 */
internal class MemorySecretStore : SecretStore {
    val entries = HashMap<String, ByteArray>()

    override suspend fun get(key: String): ByteArray? = entries[key]?.copyOf()

    override suspend fun put(key: String, value: ByteArray) {
        entries[key] = value.copyOf()
    }

    override suspend fun delete(key: String) {
        entries.remove(key)
    }

    override suspend fun deleteAll(prefix: String) {
        entries.keys.removeAll { it.startsWith(prefix) }
    }
}
