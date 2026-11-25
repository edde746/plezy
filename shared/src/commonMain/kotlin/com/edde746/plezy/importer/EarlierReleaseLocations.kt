package com.edde746.plezy.importer

import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemPathSeparator

/** Bundle id, application id and app id of Plezy's earlier releases on every platform. */
const val EARLIER_RELEASE_APP_ID = "com.edde746.plezy"

/**
 * Where Plezy's earlier releases kept their data on this device; each platform builds it (`EarlierReleaseLocations.android`,
 * `.desktop`, `.apple`). The app keeps the same ids, so these are its own directories.
 */
data class EarlierReleaseLocations(
    /**
     * Holds `plezy_downloads.db`, `downloads/` and `artwork/`; stored download paths are relative to it. Documents on
     * Android (`app_flutter`), iOS and Apple TV (`Library/Caches/Documents`), the support directory elsewhere.
     */
    val baseDirectory: String,
    /** The support directory: `custom_shaders/`, `startup_failure.json`. */
    val supportDirectory: String,
    /** The database older desktop releases kept in the Documents folder, used when the base directory has none. */
    val legacyDatabase: String?,
    /** On Windows, the support directory of builds before the company name was set, which may still hold data. */
    val orphanedSupportDirectory: String?,
    val preferences: EarlierReleasePreferencesLocation,
    /**
     * Apple TV: the system may purge the base directory, so the preferences hold a recovery image of the database's
     * rows that can't be fetched again (readTvosRecoveryImage).
     */
    val purgeableDatabase: Boolean = false,
    /**
     * The temporary directory the earlier releases' path lookup gave them, where they once kept an image cache
     * (`plexImageCache`, deleted once: [com.edde746.plezy.app.cleanLegacyImageCache]): Android's cache directory,
     * `Library/Caches` on iPhone, iPad and Apple TV and `~/Library/Caches/com.edde746.plezy` on the Mac, `GetTempPath`'s
     * folder on Windows, `$TMPDIR` (else `/tmp`) on Linux. Null where none is known.
     */
    val temporaryDirectory: String? = null,
) {
    /** `plezy_downloads.db` in [baseDirectory]. */
    val database: String get() = baseDirectory.trimEnd(SystemPathSeparator) + SystemPathSeparator + EARLIER_RELEASE_DATABASE_FILE_NAME

    /** [database] if it exists, else [legacyDatabase] if that does, else null: nothing to import. */
    fun existingDatabase(): String? = listOfNotNull(database, legacyDatabase).firstOrNull { SystemFileSystem.exists(Path(it)) }

    companion object
}

/** The preference store of the earlier releases on this platform. */
sealed interface EarlierReleasePreferencesLocation {
    /** Android: the DataStore file and the older SharedPreferences XML file. */
    data class AndroidStores(val dataStore: String, val legacyXml: String) : EarlierReleasePreferencesLocation

    /** Windows and Linux: `shared_preferences.json`. */
    data class JsonFile(val path: String) : EarlierReleasePreferencesLocation

    /** Apple platforms: the persistent domain [domain] of the user defaults. */
    data class UserDefaults(val domain: String) : EarlierReleasePreferencesLocation
}

/** Reads the preference store at [location]; null when there is none (nothing to import). */
expect fun readEarlierReleasePrefs(location: EarlierReleasePreferencesLocation): EarlierReleasePrefs?
