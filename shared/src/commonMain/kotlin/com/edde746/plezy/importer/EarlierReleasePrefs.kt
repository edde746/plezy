package com.edde746.plezy.importer

/** One value in the preference store of Plezy's earlier releases: the five types their settings used. */
sealed interface EarlierReleasePrefValue {
    data class BoolValue(val value: Boolean) : EarlierReleasePrefValue

    /** A Dart `int`: 64 bits on every platform. */
    data class LongValue(val value: Long) : EarlierReleasePrefValue

    data class DoubleValue(val value: Double) : EarlierReleasePrefValue

    data class StringValue(val value: String) : EarlierReleasePrefValue

    data class StringListValue(val value: List<String>) : EarlierReleasePrefValue
}

/**
 * The preferences Plezy's earlier releases kept, under the key names the app read (bare, no `flutter.` prefix).
 *
 * Those releases wrote bare keys. Installs from before that change stored every key as `flutter.<key>`; the first
 * launch of a newer release copied them to bare keys once and set [MIGRATION_SENTINEL], leaving the prefixed copies
 * behind, stale. [resolve] applies the same rule: with the sentinel the prefixed keys are ignored, without it they
 * stand in for missing bare keys.
 *
 * [legacyStore] keeps the prefixed entries as stored (without their prefix) whatever the sentinel says: some releases
 * after the copy still wrote Live TV favourites there alone, and adopted them from there when the bare key was missing.
 * Nothing else reads it.
 */
class EarlierReleasePrefs(
    val values: Map<String, EarlierReleasePrefValue>,
    val legacyStore: Map<String, EarlierReleasePrefValue> = emptyMap(),
) {
    val keys: Set<String> get() = values.keys

    operator fun get(key: String): EarlierReleasePrefValue? = values[key]

    /** The value at [key] if it is a bool; null if it is absent or another type. Likewise for the other getters. */
    fun bool(key: String): Boolean? = (values[key] as? EarlierReleasePrefValue.BoolValue)?.value

    fun long(key: String): Long? = (values[key] as? EarlierReleasePrefValue.LongValue)?.value

    fun double(key: String): Double? = (values[key] as? EarlierReleasePrefValue.DoubleValue)?.value

    fun string(key: String): String? = (values[key] as? EarlierReleasePrefValue.StringValue)?.value

    fun stringList(key: String): List<String>? = (values[key] as? EarlierReleasePrefValue.StringListValue)?.value

    /** The string at `flutter.<key>` in [legacyStore]; null if it is absent or another type. */
    fun legacyString(key: String): String? = (legacyStore[key] as? EarlierReleasePrefValue.StringValue)?.value

    override fun equals(other: Any?): Boolean = other is EarlierReleasePrefs && other.values == values && other.legacyStore == legacyStore

    override fun hashCode(): Int = 31 * values.hashCode() + legacyStore.hashCode()

    override fun toString(): String = "EarlierReleasePrefs(${values.keys.sorted()})"

    companion object {
        /** Prefix of the keys the releases before the bare-key store wrote. */
        const val LEGACY_PREFIX = "flutter."

        /** Set once the prefixed keys were copied to bare keys. */
        const val MIGRATION_SENTINEL = "plezy_legacy_prefs_migrated_v1"

        /** The vault key (base64 of 32 bytes) that `enc:v1:` credentials decrypt with. */
        const val VAULT_KEY = "credential_vault_key_v1"

        /**
         * The keys as the app read them from a store's raw entries ([stored], keys as on disk, prefixed and bare
         * together): bare keys, plus the prefixed keys without their prefix when the store has no
         * [MIGRATION_SENTINEL], a bare key winning over its prefixed copy.
         */
        fun resolve(stored: Map<String, EarlierReleasePrefValue>): EarlierReleasePrefs {
            val bare = stored.filterKeys { !it.startsWith(LEGACY_PREFIX) }
            val legacy = LinkedHashMap<String, EarlierReleasePrefValue>()
            for ((key, value) in stored) {
                if (key.startsWith(LEGACY_PREFIX)) legacy[key.removePrefix(LEGACY_PREFIX)] = value
            }
            if (MIGRATION_SENTINEL in bare) return EarlierReleasePrefs(bare, legacy)
            return EarlierReleasePrefs(legacy + bare, legacy)
        }
    }
}
