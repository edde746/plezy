package com.edde746.plezy.importer

import kotlin.test.Test
import kotlin.test.assertEquals

class EarlierReleaseLocationsTest {
    private fun linux(files: Set<String>, dataHome: String? = null, documents: String? = "/home/alex/Documents") = desktopEarlierReleaseLocations(
        osName = "Linux",
        environment = { if (it == "XDG_DATA_HOME") dataHome else null },
        home = "/home/alex",
        isFile = { it in files },
        documents = { documents },
    )

    @Test
    fun linuxUsesTheAppIdDirectoryWhenItHoldsTheEarlierRelease() {
        val locations = linux(
            files = setOf("/home/alex/.local/share/com.edde746.plezy/shared_preferences.json", "/home/alex/.local/share/plezy/plezy_downloads.db"),
        )

        assertEquals("/home/alex/.local/share/com.edde746.plezy", locations.baseDirectory)
        assertEquals(EarlierReleasePreferencesLocation.JsonFile("/home/alex/.local/share/com.edde746.plezy/shared_preferences.json"), locations.preferences)
        assertEquals("/home/alex/Documents/plezy_downloads.db", locations.legacyDatabase)
    }

    @Test
    fun linuxUsesTheExecutableNameDirectoryWhenOnlyItHoldsTheEarlierRelease() {
        // The app id directory holds this app's own database, made by a start whose import didn't finish.
        val appOwn = "/home/alex/.local/share/com.edde746.plezy/plezy.db"
        val database = linux(files = setOf(appOwn, "/home/alex/.local/share/plezy/plezy_downloads.db"))
        val preferences = linux(files = setOf(appOwn, "/home/alex/.local/share/plezy/shared_preferences.json"))

        assertEquals("/home/alex/.local/share/plezy", database.baseDirectory)
        assertEquals("/home/alex/.local/share/plezy", preferences.baseDirectory)
        assertEquals(EarlierReleasePreferencesLocation.JsonFile("/home/alex/.local/share/plezy/shared_preferences.json"), preferences.preferences)
    }

    @Test
    fun aFlatpakSandboxRemapsTheDataDirectory() {
        val locations = linux(files = emptySet(), dataHome = "/home/alex/.var/app/com.edde746.plezy/data", documents = null)

        assertEquals("/home/alex/.var/app/com.edde746.plezy/data/com.edde746.plezy", locations.baseDirectory)
        assertEquals(null, locations.legacyDatabase)
    }

    private fun windows(documents: String?) = desktopEarlierReleaseLocations(
        osName = "Windows 11",
        environment = mapOf("APPDATA" to "C:\\Users\\alex\\AppData\\Roaming", "USERPROFILE" to "C:\\Users\\alex")::get,
        home = "C:\\Users\\alex",
        isFile = { false },
        documents = { documents },
    )

    @Test
    fun windowsUsesTheRoamingSupportDirectoryAndTheDocumentsKnownFolder() {
        val locations = windows(documents = "D:\\OneDrive\\Documents")

        assertEquals("C:\\Users\\alex\\AppData\\Roaming\\com.edde746\\Plezy", locations.baseDirectory)
        assertEquals(EarlierReleasePreferencesLocation.JsonFile("C:\\Users\\alex\\AppData\\Roaming\\com.edde746\\Plezy\\shared_preferences.json"), locations.preferences)
        assertEquals("D:\\OneDrive\\Documents\\plezy_downloads.db", locations.legacyDatabase)
        assertEquals("C:\\Users\\alex\\AppData\\Roaming\\com.example\\Plezy", locations.orphanedSupportDirectory)
    }

    @Test
    fun windowsLooksForNoOlderDatabaseWhenItCannotTellWhereDocumentsIs() {
        assertEquals(null, windows(documents = null).legacyDatabase)
    }

    @Test
    fun theTemporaryDirectoryIsTmpThenTempThenTheProfileOnWindows() {
        fun temporary(environment: Map<String, String>) = desktopEarlierReleaseLocations(
            osName = "Windows 11",
            environment = environment::get,
            home = "C:\\Users\\alex",
            isFile = { false },
            documents = { null },
        ).temporaryDirectory

        assertEquals("C:\\Temp", temporary(mapOf("TMP" to "C:\\Temp\\", "TEMP" to "D:\\Temp")))
        assertEquals("D:\\Temp", temporary(mapOf("TEMP" to "D:\\Temp")))
        assertEquals("C:\\Users\\alex", temporary(emptyMap()))
    }

    @Test
    fun theTemporaryDirectoryIsTmpdirElseTmpOnLinux() {
        val withTmpdir = desktopEarlierReleaseLocations("Linux", mapOf("TMPDIR" to "/run/user/1000/tmp")::get, "/home/alex", { false }, { null })

        assertEquals("/run/user/1000/tmp", withTmpdir.temporaryDirectory)
        assertEquals("/tmp", linux(files = emptySet()).temporaryDirectory)
    }
}
