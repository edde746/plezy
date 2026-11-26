package com.edde746.plezy.app

import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.importer.EarlierReleaseImport
import com.edde746.plezy.importer.EarlierReleaseOutcome
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.profiles.BootRoute
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.trackers.FailingSecretStore
import kotlinx.coroutines.test.StandardTestDispatcher
import com.edde746.plezy.importer.EarlierReleaseFixtures
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.importer.EarlierReleasePreferencesLocation
import com.edde746.plezy.importer.readEarlierReleaseDatabase
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration

class RootSessionImportTest {
    /** An install of the earlier releases on Windows or Linux, with accounts, profiles and downloads. */
    private fun desktopInstall(): EarlierReleaseLocations {
        val base = EarlierReleaseFixtures.copyOf("v25")
        Files.copy(EarlierReleaseFixtures.path("desktop-upgrade/shared_preferences.json"), base.resolve("shared_preferences.json"))
        return EarlierReleaseLocations(
            baseDirectory = base.toString(),
            supportDirectory = base.toString(),
            legacyDatabase = null,
            orphanedSupportDirectory = null,
            preferences = EarlierReleasePreferencesLocation.JsonFile(base.resolve("shared_preferences.json").toString()),
        )
    }

    @Test
    fun aFailedImportStartsNoAppThatCouldWriteOverTheEarlierReleasesData() = runTest {
        val data = testData()
        val secrets = MemorySecretStore()
        val install = desktopInstall()
        val snapshot = readEarlierReleaseDatabase(install.database)
        assertTrue(snapshot.connections.isNotEmpty() && snapshot.downloadedMedia.isNotEmpty())
        // A row the import's own collides with fails its transaction, after it stored the tokens.
        val connections = ConnectionStore(data, secrets)
        connections.upsert(StoredConnection("emby-machine/user-9", BackendKind.EMBY, JsonObject(emptyMap()), createdAt = 1))
        val root = RootSession(testGraph(data, secrets = secrets, earlierRelease = install), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))

        val failed = assertIs<RootScreen.Failed>(root.screen.first { it != RootScreen.Starting })
        assertEquals(StartupPhase.EARLIER_RELEASE_IMPORT, failed.record.phase)
        assertNull(root.app)
        assertEquals(listOf("emby-machine/user-9"), connections.list().map { it.id })

        // Without the row in the way, Retry imports, overwriting the tokens stored before, and the app starts.
        connections.remove("emby-machine/user-9")
        root.retry()
        assertIs<RootScreen.Main>(root.screen.first { it is RootScreen.Main || it is RootScreen.Failed })
        root.close()

        // The next start finds the import done and imports nothing twice.
        val next = RootSession(testGraph(data, secrets = secrets, earlierRelease = install), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))
        assertIs<RootScreen.Main>(next.screen.first { it != RootScreen.Starting })
        // Imported once, less the Jellyfin user no profile uses, which the start removed.
        val imported = connections.list().associateBy { it.id }
        assertEquals(snapshot.connections.map { it.id }.toSet() - "jf-lost/user-2", imported.keys)
        assertEquals("plex-account-token", (imported.getValue("plex-acct-1").config["accountToken"] as? JsonPrimitive)?.content)
        assertEquals("jellyfin-access-token", (imported.getValue("jf-machine/user-1").config["accessToken"] as? JsonPrimitive)?.content)
        assertEquals(
            snapshot.downloadedMedia.map { it.globalKey },
            data.db.read { downloadedMediaQueries.selectAllMedia().executeAsList() }.map { it.global_key },
        )
        assertEquals(2, data.profiles.list().size)
        next.close()
    }

    @Test
    fun aSecretStoreThatRefusesEveryWriteStillStartsTheAppWithTheEarlierReleasesData() = runTest {
        val data = testData()
        val install = desktopInstall()
        val snapshot = readEarlierReleaseDatabase(install.database)
        // Windows' Credential Manager once this user's credentials fill it.
        val secrets = FailingSecretStore().apply { failWrites = true }
        val root = RootSession(testGraph(data, secrets = secrets, earlierRelease = install), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))

        assertIs<RootScreen.Main>(root.screen.first { it != RootScreen.Starting })
        assertEquals(EarlierReleaseOutcome.IMPORTED, EarlierReleaseImport(data, secrets).outcome())
        // The accounts sign in again; the profiles and downloads are there.
        val connections = ConnectionStore(data, secrets).list()
        assertTrue(connections.isNotEmpty())
        assertTrue(connections.all { it.config["accountToken"] == null && it.config["accessToken"] == null })
        assertEquals(2, data.profiles.list().size)
        assertEquals(
            snapshot.downloadedMedia.map { it.globalKey },
            data.db.read { downloadedMediaQueries.selectAllMedia().executeAsList() }.map { it.global_key },
        )
        root.close()
    }

    @Test
    fun aResetLeavesTheEarlierReleaseUnimportedAndTheFirstRunSignsIn() = runTest {
        val install = desktopInstall()
        assertTrue(readEarlierReleaseDatabase(install.database).connections.isNotEmpty())
        val files = Files.createTempDirectory("plezy-files")
        val database = DatabaseFactory(files.resolve("plezy.db"))
        val secrets = MemorySecretStore().apply { put("connection.c", byteArrayOf(1)) }
        LocalData(database).use { it.open() }

        AppBootstrap.resetData(database, secrets, downloads = null, downloadTempDirectory = null)

        val data = LocalData(database, { 0L }, StandardTestDispatcher(testScheduler))
        val root = RootSession(
            testGraph(data, secrets = secrets, earlierRelease = install, filesDirectory = files.toString()),
            FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO),
        )
        val main = assertIs<RootScreen.Main>(root.screen.first { it != RootScreen.Starting })
        assertEquals(BootRoute.SIGN_IN, main.entry)
        assertEquals(emptyList(), ConnectionStore(data, secrets).list())
        assertEquals(EarlierReleaseOutcome.NOTHING, EarlierReleaseImport(data, secrets).outcome())
        assertTrue("connection.c" !in secrets.entries, "the reset kept the account's secret")
        root.close()
    }
}
