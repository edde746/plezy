package com.edde746.plezy.importer

import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * The earlier releases' locations on this Windows or Linux machine (a Flatpak's sandbox remaps XDG_DATA_HOME).
 *
 * @param windowsDocuments the user's Documents folder on Windows, where Explorer has it (the Documents Known Folder,
 *   which the user or OneDrive may have moved); null when Windows can't tell.
 */
fun EarlierReleaseLocations.Companion.desktop(windowsDocuments: () -> String?): EarlierReleaseLocations {
    val osName = System.getProperty("os.name")
    return desktopEarlierReleaseLocations(
        osName = osName,
        environment = System::getenv,
        home = System.getProperty("user.home"),
        isFile = { File(it).isFile },
        documents = if (osName.lowercase().startsWith("windows")) windowsDocuments else ::xdgDocumentsDirectory,
    )
}

/**
 * Windows: the support directory `%APPDATA%\com.edde746\Plezy` (Roaming), the older database in the user's Documents
 * folder, and `%APPDATA%\com.example\Plezy` from builds before the company name was set. Linux:
 * `$XDG_DATA_HOME/com.edde746.plezy` (default `~/.local/share`), or `$XDG_DATA_HOME/plezy` when only that holds the
 * preference store or the database, and the older database in the XDG Documents directory. (The earlier releases' path
 * lookup took `plezy` whenever `com.edde746.plezy` didn't exist; this app makes that directory for its own data, so a
 * start whose import didn't finish leaves it behind.) No older database is looked for when [documents] (the Documents
 * folder) can't be found, as the earlier releases did. The temporary directory: `GetTempPath`'s on Windows (`%TMP%`,
 * else `%TEMP%`, else the user's profile), `$TMPDIR` or `/tmp` on Linux.
 */
internal fun desktopEarlierReleaseLocations(
    osName: String,
    environment: (String) -> String?,
    home: String,
    isFile: (String) -> Boolean,
    documents: () -> String?,
): EarlierReleaseLocations {
    fun env(name: String) = environment(name)?.takeIf { it.isNotBlank() }
    val os = osName.lowercase()
    return when {
        os.startsWith("windows") -> {
            val roaming = env("APPDATA") ?: "$home\\AppData\\Roaming"
            val support = "$roaming\\com.edde746\\Plezy"
            EarlierReleaseLocations(
                baseDirectory = support,
                supportDirectory = support,
                legacyDatabase = documents()?.let { "$it\\$EARLIER_RELEASE_DATABASE_FILE_NAME" },
                orphanedSupportDirectory = "$roaming\\com.example\\Plezy",
                preferences = EarlierReleasePreferencesLocation.JsonFile("$support\\shared_preferences.json"),
                temporaryDirectory = (env("TMP") ?: env("TEMP") ?: env("USERPROFILE") ?: home).trimEnd('\\'),
            )
        }
        os.startsWith("linux") -> {
            val dataHome = env("XDG_DATA_HOME") ?: "$home/.local/share"
            val current = "$dataHome/$EARLIER_RELEASE_APP_ID"
            val legacy = "$dataHome/plezy"
            fun holdsEarlierRelease(directory: String) =
                isFile("$directory/$DESKTOP_PREFERENCES_FILE_NAME") || isFile("$directory/$EARLIER_RELEASE_DATABASE_FILE_NAME")
            val support = if (!holdsEarlierRelease(current) && holdsEarlierRelease(legacy)) legacy else current
            EarlierReleaseLocations(
                baseDirectory = support,
                supportDirectory = support,
                legacyDatabase = documents()?.let { "$it/$EARLIER_RELEASE_DATABASE_FILE_NAME" },
                orphanedSupportDirectory = null,
                preferences = EarlierReleasePreferencesLocation.JsonFile("$support/shared_preferences.json"),
                temporaryDirectory = env("TMPDIR") ?: "/tmp",
            )
        }
        else -> error("Plezy's earlier releases on $osName are read by the Apple app")
    }
}

/** `xdg-user-dir DOCUMENTS`, as the earlier releases asked; null when the tool is missing or fails. */
private fun xdgDocumentsDirectory(): String? = try {
    val process = ProcessBuilder("xdg-user-dir", "DOCUMENTS").redirectErrorStream(false).start()
    val output = process.inputStream.bufferedReader().readText().trim()
    if (process.waitFor(5, TimeUnit.SECONDS) && process.exitValue() == 0 && output.isNotEmpty()) output else null
} catch (_: IOException) {
    // No xdg-user-dir (a minimal or headless system): there is no Documents directory to look in.
    null
}
