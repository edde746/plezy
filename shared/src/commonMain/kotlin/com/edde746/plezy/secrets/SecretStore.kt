package com.edde746.plezy.secrets

/**
 * The platform's secure storage: Keychain on Apple, an Android Keystore-wrapped store on Android,
 * Windows Credential Manager and libsecret on desktop. It holds the connections' and profiles' tokens and the
 * trackers' tokens, none of which may ever reach SQLite, logs or backups.
 *
 * Keys are short ASCII names chosen by the callers; values are opaque bytes of at most 4 KiB.
 * Implementations scope entries to this app and this OS user, and exclude them from device backups/migration where
 * the platform allows it, so a restored backup never carries a session to another device.
 *
 * Calls may block on platform services, so they suspend; implementations are safe to call from any thread.
 */
interface SecretStore {
    /** The value stored under [key], or null if there is none. */
    suspend fun get(key: String): ByteArray?

    /** Stores [value] under [key], replacing any previous value. */
    suspend fun put(key: String, value: ByteArray)

    /** Removes [key]; removing a missing key is not an error. */
    suspend fun delete(key: String)

    /**
     * Removes every key that starts with [prefix]: all of this store's keys for an empty one (the app data reset). None
     * matching is not an error.
     */
    suspend fun deleteAll(prefix: String)
}
