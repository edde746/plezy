package com.edde746.plezy.data.recovery

/**
 * Small key-value storage that outlives the database when the system deletes it (the standard user defaults on Apple
 * TV). A value set is read back at once and survives the app's process ending, even by a crash, but not necessarily a
 * power loss before the system writes it to disk. Calls are synchronous and run inside the database's write; a write
 * that fails throws.
 */
internal interface RecoveryStore {
    /** Whether [key] holds a value of any type. */
    fun contains(key: String): Boolean

    /** [key]'s string, or null when it holds none (absent, or a value of another type). */
    fun string(key: String): String?

    /** [key]'s boolean, or null when it holds none (absent, or a value of another type). */
    fun boolean(key: String): Boolean?

    fun putString(key: String, value: String)

    fun putBoolean(key: String, value: Boolean)

    /** Removes [key]; removing a missing key is not an error. */
    fun remove(key: String)
}

/**
 * A database the system may delete ([com.edde746.plezy.data.DatabaseFactory] on Apple TV): its recovery image goes to
 * [store], and [priorInstall] tells, beyond the [RecoveryKeys.INSTALL] mark in [store], whether the app was used on
 * this install before, should the database and the image both be gone. [byteCeiling] bounds the image
 * ([RECOVERY_BYTE_CEILING]).
 */
internal class PurgeableDatabase(
    val store: RecoveryStore,
    val priorInstall: () -> Boolean,
    val byteCeiling: Int = RECOVERY_BYTE_CEILING,
)

/**
 * The most the recovery keys may take together, as the UTF-8 JSON object of them: the image shares the user defaults'
 * small quota with the rest of the app. A larger image is neither written nor trusted.
 */
internal const val RECOVERY_BYTE_CEILING = 400_000
