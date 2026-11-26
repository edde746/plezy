package com.edde746.plezy.importer

import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.data.testData
import com.edde746.plezy.data.tracker.TrackerAccount
import com.edde746.plezy.importer.EarlierReleaseFixtures.T
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibrarySort
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.profiles.computePinHash
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.settings.ServerSettings
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.settings.TrackerLibraryFilterMode
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.trackers.FailingSecretStore
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.TrackerTokenStore
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.exists
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.io.path.readBytes
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EarlierReleaseImportTest {
    private val clock = TestClock()
    private val secrets = MemorySecretStore()
    private val opened = mutableListOf<LocalData>()

    @AfterTest
    fun close() = opened.forEach { it.close() }

    private fun data(factory: DatabaseFactory = DatabaseFactory.inMemory()) = testData(clock, factory).also { opened += it }

    /** An install of the earlier releases on Windows or Linux: the fixture database [database] and preference store [prefs]. */
    private fun desktopInstall(database: String?, prefs: String?): EarlierReleaseLocations {
        val base = database?.let { EarlierReleaseFixtures.copyOf(it) } ?: Files.createTempDirectory("flutter-import")
        prefs?.let { Files.copy(EarlierReleaseFixtures.path("$it/shared_preferences.json"), base.resolve("shared_preferences.json")) }
        return EarlierReleaseLocations(
            baseDirectory = base.toString(),
            supportDirectory = base.toString(),
            legacyDatabase = null,
            orphanedSupportDirectory = null,
            preferences = EarlierReleasePreferencesLocation.JsonFile(base.resolve("shared_preferences.json").toString()),
        )
    }

    private fun contents(directory: String): Map<String, List<Byte>> =
        Path.of(directory).listDirectoryEntries().associate { it.name to it.readBytes().toList() }

    private suspend fun LocalData.storedSetting(key: String): String? = db.read { deviceSettingQueries.selectByKey(key).executeAsOneOrNull() }

    private fun StoredConnection.text(field: String): String? = (config[field] as? JsonPrimitive)?.content

    @Test
    fun importsADesktopInstallUpgradedInPlaceAndKeepsNoTokenInTheDatabase() = runTest {
        val install = desktopInstall("v25", "desktop-upgrade")
        val before = contents(install.baseDirectory)
        val directory = Files.createTempDirectory("plezy")
        val data = data(DatabaseFactory(directory.resolve("plezy.db")))
        val import = EarlierReleaseImport(data, secrets)
        var began = 0

        assertEquals(EarlierReleaseOutcome.IMPORTED, import.run(install) { began++ })
        assertEquals(1, began)
        assertEquals(EarlierReleaseOutcome.IMPORTED, import.outcome())

        // Connections, their tokens decrypted (plaintext ones too); one encrypted under a lost key signs in again.
        val connections = ConnectionStore(data, secrets).list().associateBy { it.id }
        assertEquals(listOf("plex-acct-1", "jf-machine/user-1", "emby-machine/user-9", "jf-lost/user-2"), connections.keys.toList())
        val plex = connections.getValue("plex-acct-1")
        assertEquals(BackendKind.PLEX, plex.kind)
        assertEquals(T to T + 500_000, plex.createdAt to plex.lastAuthenticatedAt)
        assertEquals("plex-account-token", plex.text("accountToken"))
        assertEquals(
            listOf("plex-server-token-1", "plaintext-plex-server-token-2"),
            plex.config.getValue("servers").jsonArray.map { it.jsonObject.getValue("accessToken").jsonPrimitive.content },
        )
        assertEquals("jellyfin-access-token", connections.getValue("jf-machine/user-1").text("accessToken"))
        assertEquals(BackendKind.EMBY, connections.getValue("emby-machine/user-9").kind)
        assertEquals("plaintext-emby-token", connections.getValue("emby-machine/user-9").text("accessToken"))
        assertNull(connections.getValue("jf-lost/user-2").text("accessToken"))

        // Local profiles with their PIN hashes (a retired Plex Home row is dropped), bindings with defaults repaired.
        assertEquals(
            listOf(
                LocalProfile("local-aaa", "Alex", null, computePinHash("1234"), 0, T, T + 900_000),
                LocalProfile("local-bbb", "Kid", "https://avatar.example.invalid/kid.png", null, 1, T + 200_000, T + 950_000),
            ),
            data.profiles.list(),
        )
        assertEquals(
            setOf(
                ProfileConnection("local-aaa", "plex-acct-1", "profile-token-alex", "plex-user-1", true, T + 300_000, T + 800_000),
                ProfileConnection("local-aaa", "jf-machine/user-1", null, "user-1", false, null, null),
                ProfileConnection("local-bbb", "emby-machine/user-9", "plaintext-profile-token-kid", "user-9", true, null, T + 700_000),
                ProfileConnection("plex-home-plex-acct-1-uuid-9", "plex-acct-1", "home-user-token", "uuid-9", true, T + 310_000, null),
            ),
            ProfileConnectionRegistry(data, secrets).listAll().toSet(),
        )

        // Settings as typed values: the bare keys win over the stale prefixed ones; a value of another type is left out.
        val settings = data.deviceSettings
        assertEquals(true, settings.value(AppSettings.enableDebugLogging))
        assertEquals(15, settings.value(AppSettings.seekTimeSmall))
        assertEquals(AppSettings.seekTimeLarge.default, settings.value(AppSettings.seekTimeLarge))
        assertEquals(80.0, settings.value(AppSettings.volume))
        assertEquals(ViewMode.LIST, settings.value(AppSettings.viewMode))
        assertEquals(ThemeMode.OLED, settings.value(AppSettings.themeMode))
        assertEquals(true, settings.value(AppSettings.requireProfileSelectionOnOpen))
        assertEquals(
            Json.parseToJsonElement("""{"play_pause":{"key":"space","modifiers":[]}}"""),
            settings.value(AppSettings.keyboardHotkeys),
        )
        assertEquals("""{"play_pause":{"key":"space","modifiers":[]}}""", data.storedSetting("keyboard_hotkeys"))
        assertEquals(listOf("srv-plex-1:1", "jf-machine:lib-tv"), settings.value(AppSettings.trackerFilterIds(TrackerService.TRAKT)))
        assertEquals(TrackerLibraryFilterMode.WHITELIST, settings.value(AppSettings.trackerFilterMode(TrackerService.TRAKT)))
        assertFalse(settings.value(AppSettings.scrobble(TrackerService.MYANIMELIST)))
        // The shapes of older releases, migrated: a density name, a skip toggle.
        assertEquals(2, settings.value(AppSettings.libraryDensity))
        assertEquals(SkipMode.AUTO, settings.value(AppSettings.skipIntroMode))
        assertNull(data.storedSetting("auto_skip_intro"))

        // Identity: the active profile, the client identifier, profiles' last use and the Plex Home users cache.
        val identity = ProfileIdentity(data)
        assertEquals("local-aaa", identity.activeProfileId())
        assertEquals("plezy-client-1", identity.getOrCreateClientIdentifier())
        assertEquals(T + 900_000, identity.profileLastUsed("local-aaa"))
        assertEquals(T + 950_000, identity.profileLastUsed("plex-home-plex-acct-1-0123456789abcdef"))
        assertEquals(listOf("0123456789abcdef", "fedcba9876543210"), identity.plexHomeUsers("plex-acct-1")?.map { it.uuid })
        assertTrue(settings.value(AppSettings.profileMigrationDone))

        // Profile settings by scope: a Plex Home profile's full-id scope moves to its user's.
        assertEquals(listOf("srv-plex-1:1", "jf-machine:lib-tv"), data.libraryPrefs.libraryOrder("local-aaa"))
        assertEquals(LibrarySort("titleSort", LibrarySortDirection.DESCENDING), data.libraryPrefs.sort("srv-plex-1:1"))
        assertEquals(LibrarySort("SortName", LibrarySortDirection.ASCENDING), data.libraryPrefs.sort("jf-machine:lib-tv"))
        assertEquals("srv-plex-1:1", data.libraryPrefs.selectedLibraryKey())
        assertEquals(setOf("jf-machine:lib-x"), data.libraryPrefs.hiddenLibraries("local-aaa"))
        assertEquals("trakt", data.profileSettings.value("0123456789abcdef", ProfileSettings.catalogActiveSource))
        assertNull(data.db.read { deviceSettingQueries.selectProfileSetting("local-aaa", "hidden_genres").executeAsOneOrNull() })

        // Server settings.
        assertEquals(85, data.serverSettings.value("srv-plex-1", ServerSettings.watchedThreshold))
        assertEquals("https://10-0-0-2.example.invalid:32400", data.serverSettings.value("srv-plex-1", ServerSettings.serverEndpoint))
        assertEquals(4, data.serverSettings.value("srv-plex-1", ServerSettings.dvrTargetSection(1)))

        // Credentials and the earlier releases' bookkeeping aren't settings.
        for (key in listOf("credential_vault_key_v1", "plex_token", "plezy_legacy_prefs_migrated_v1", "NSWindow Frame com.edde746.plezy.MainWindow")) {
            assertNull(data.storedSetting(key), key)
        }

        // Tracker sessions: the bare one goes to the active profile, a Plex Home user's to that user (every profile of it
        // shares it); one the earlier release wouldn't load stays behind.
        val tokens = TrackerTokenStore(secrets)
        assertEquals(listOf(TrackerAccount(TrackerService.TRAKT, "alex", clock.now)), data.trackerAccounts.accounts("local-aaa"))
        assertEquals(
            TrackerSession("trakt-access-token", "trakt-refresh-token", 4_102_444_800, "alex", 1_700_000_000),
            tokens.load("local-aaa", TrackerService.TRAKT)?.session,
        )
        val homeAdmin = "plex-home-plex-acct-1-0123456789abcdef"
        assertEquals(listOf(TrackerService.MYANIMELIST), data.trackerAccounts.accounts(homeAdmin).map { it.service })
        assertEquals("mal-access-token", tokens.load("0123456789abcdef", TrackerService.MYANIMELIST)?.session?.accessToken)
        assertEquals(emptyList(), data.trackerAccounts.accounts("local-bbb"))

        // The Seerr session, its password decrypted.
        val seerr = Json.parseToJsonElement(checkNotNull(secrets.get("seerr_session.local-aaa")).decodeToString()).jsonObject
        assertEquals("seerr-password", seerr.getValue("secret").jsonPrimitive.content)
        assertEquals("connect.sid=s%3Afixture", seerr.getValue("cookie").jsonPrimitive.content)

        // Live TV favourites, the older server-keyed list adopted for a connection without its own.
        assertEquals(
            listOf(FavoriteChannel("tuner", "ch-1", "News", null, "4.1"), FavoriteChannel("tuner", "ch-2", "Weather")),
            data.liveTvFavorites.favorites("jf-machine/user-1"),
        )
        assertEquals(listOf(FavoriteChannel("m3u", "ch-9", "Cartoons")), data.liveTvFavorites.favorites("emby-machine/user-9"))
        // A list later releases wrote only to the prefixed store counts, migration sentinel or not.
        assertEquals(listOf(FavoriteChannel("tuner", "ch-5", "Movies")), data.liveTvFavorites.favorites("jf-lost/user-2"))

        // Downloads with their paths as stored, rows still in the earlier database's WAL among them.
        val media = data.db.read { downloadedMediaQueries.selectAllMedia().executeAsList() }
        assertEquals(listOf(1L, 2L, 3L), media.map { it.id })
        assertEquals("downloads/Movies/Heat (1995)/Heat (1995) [0a1b2c3d].mkv", media[0].video_file_path)
        assertEquals("""["downloads/Movies/Heat (1995)/Heat (1995) [0a1b2c3d] - part2.mkv",null]""", media[0].additional_part_paths)
        assertEquals(
            "content://com.android.externalstorage.documents/tree/primary%3APlezy/document/primary%3APlezy%2FS02E07.mkv",
            media[1].video_file_path,
        )
        assertEquals("content://com.android.externalstorage.documents/tree/primary%3APlezy", media[1].saf_root_uri)
        assertEquals(listOf("jf-machine:ep-7"), data.db.read { downloadedMediaQueries.selectAllQueue().executeAsList() }.map { it.media_global_key })

        // The pinned API cache only, its time now in milliseconds.
        val cached = data.db.read { apiCacheQueries.selectByPrefix("").executeAsList() }
        assertEquals(listOf("srv-plex-1/~plex-profile/local-aaa:/library/metadata/101"), cached.map { it.cache_key })
        assertEquals(1_700_000_000_000, cached.single().cached_at)

        // The unsent watch actions in their order; sync rules, collections and the music session.
        assertEquals(listOf(1L, 2L), data.db.read { offlineWatchQueries.selectPending().executeAsList() }.map { it.id })
        assertEquals(listOf(1L, 2L), data.db.read { syncRuleQueries.selectAll().executeAsList() }.map { it.id })
        assertEquals(listOf("jf-machine:ep-7"), data.db.read { syncRuleQueries.selectLinkedKeys(1).executeAsList() })
        assertEquals(listOf("coll-9"), data.db.read { syncRuleQueries.selectCollections("local-aaa").executeAsList() }.map { it.collection_id })
        assertEquals(61_000, data.db.read { musicSessionQueries.selectByProfile("local-aaa").executeAsOne() }.position_ms)

        // The earlier release's files are as they were.
        val after = contents(install.baseDirectory)
        assertEquals(before.keys, after.keys)
        for ((name, bytes) in before) assertContentEquals(bytes, after.getValue(name), name)

        // No token, encrypted or not, reached the database file.
        data.close()
        val files = directory.listDirectoryEntries().map { String(it.readBytes(), Charsets.ISO_8859_1) }
        val leaks = listOf(
            "plex-account-token", "plex-server-token-1", "plaintext-plex-server-token-2", "jellyfin-access-token",
            "plaintext-emby-token", "profile-token-alex", "plaintext-profile-token-kid", "home-user-token", "seerr-password",
            "trakt-access-token", "trakt-refresh-token", "mal-access-token", "enc:v1:",
        )
        for (token in leaks) assertTrue(files.none { token in it }, "$token is in the database")
    }

    @Test
    fun importsAnAndroidInstallFromItsDataStore() = runTest {
        val base = EarlierReleaseFixtures.copyOf("v25")
        val install = EarlierReleaseLocations(
            baseDirectory = base.toString(),
            supportDirectory = base.toString(),
            legacyDatabase = null,
            orphanedSupportDirectory = null,
            preferences = EarlierReleasePreferencesLocation.AndroidStores(
                dataStore = EarlierReleaseFixtures.path("android/files/datastore/FlutterSharedPreferences.preferences_pb").toString(),
                legacyXml = EarlierReleaseFixtures.path("android/shared_prefs/FlutterSharedPreferences.xml").toString(),
            ),
        )
        val data = data()

        assertEquals(EarlierReleaseOutcome.IMPORTED, EarlierReleaseImport(data, secrets).run(install))

        // The DataStore's vault key decrypts the database's tokens.
        assertEquals("plex-account-token", ConnectionStore(data, secrets).get("plex-acct-1")?.text("accountToken"))
        assertEquals(
            "profile-token-alex",
            ProfileConnectionRegistry(data, secrets).get("local-aaa", "plex-acct-1")?.userToken,
        )
        // The DataStore's values; the migrated legacy XML store's are stale.
        assertFalse(data.deviceSettings.value(AppSettings.enableDebugLogging))
        assertEquals(15, data.deviceSettings.value(AppSettings.seekTimeSmall))
        assertEquals(-250, data.deviceSettings.value(AppSettings.audioSyncOffset))
        assertEquals(100.0, data.deviceSettings.value(AppSettings.volume))
        assertEquals(ViewMode.LIST, data.deviceSettings.value(AppSettings.viewMode))
        assertEquals("local-aaa", ProfileIdentity(data).activeProfileId())
        // A string list in the DataStore's list encoding.
        assertEquals(listOf("2", "1", "7"), data.libraryPrefs.libraryOrder("local-aaa"))
        assertTrue(secrets.get("seerr_session.local-aaa") != null)
    }

    @Test
    fun upgradesASchema16DatabaseAndReadsAStoreFromBeforeTheBareKeys() = runTest {
        val install = desktopInstall("v16", "desktop-legacy")
        val data = data()

        assertEquals(EarlierReleaseOutcome.IMPORTED, EarlierReleaseImport(data, secrets).run(install))

        val snapshot = readEarlierReleaseDatabase(EarlierReleaseFixtures.path("v16/plezy_downloads.db").toString())
        assertEquals(snapshot.connections.map { it.id }.toSet(), ConnectionStore(data, secrets).list().map { it.id }.toSet())
        assertEquals(
            snapshot.pinnedApiCache.map { it.cacheKey to it.cachedAt * 1000 }.sortedBy { it.first },
            data.db.read { apiCacheQueries.selectByPrefix("").executeAsList() }.map { it.cache_key to it.cached_at },
        )
        assertEquals(snapshot.downloadedMedia.map { it.globalKey }, data.db.read { downloadedMediaQueries.selectAllMedia().executeAsList() }.map { it.global_key })
        // Without the migration sentinel the prefixed keys stand in for missing bare ones; a bare key wins.
        assertEquals(ViewMode.GRID, data.deviceSettings.value(AppSettings.viewMode))
        assertEquals(20, data.deviceSettings.value(AppSettings.seekTimeSmall))
        assertEquals(80.0, data.deviceSettings.value(AppSettings.volume))
        // The library order of releases before profiles, unscoped: the first profile to become active adopts it.
        assertEquals("""["a","b"]""", data.storedSetting("library_order"))
        // No legacy account to move: the profile migration is marked done and no profile is chosen.
        assertTrue(data.deviceSettings.value(AppSettings.profileMigrationDone))
        assertNull(ProfileIdentity(data).activeProfileId())
    }

    @Test
    fun aDamagedDesktopStoreGivesUpItsCredentialsAlone() = runTest {
        val install = desktopInstall("v25", "desktop-damaged")
        val data = data()

        assertEquals(EarlierReleaseOutcome.IMPORTED, EarlierReleaseImport(data, secrets).run(install))

        val connections = ConnectionStore(data, secrets).list().associateBy { it.id }
        assertEquals("plex-account-token", connections.getValue("plex-acct-1").text("accountToken"))
        // Its settings are lost.
        assertNull(data.deviceSettings.value(AppSettings.themeMode))
        // The legacy Plex token it held, with no profile migration recorded, becomes a Plex account of its own.
        val clientId = ProfileIdentity(data).getOrCreateClientIdentifier()
        assertEquals("legacy-plex-token", connections.getValue("plex.$clientId").text("accountToken"))
    }

    @Test
    fun aSecondRunDoesNothing() = runTest {
        val data = data()
        val import = EarlierReleaseImport(data, secrets)
        assertEquals(EarlierReleaseOutcome.IMPORTED, import.run(desktopInstall("v25", "desktop-upgrade")))
        data.deviceSettings.set(AppSettings.viewMode, ViewMode.GRID)
        var began = 0

        assertNull(import.run(desktopInstall("v25", "desktop-upgrade")) { began++ })

        assertEquals(0, began)
        assertEquals(ViewMode.GRID, data.deviceSettings.value(AppSettings.viewMode))
        assertEquals(4, ConnectionStore(data, secrets).list().size)
    }

    @Test
    fun aFailingWriteLeavesNoRowsAndNoMarkerAndTheNextStartImports() = runTest {
        val data = data()
        val connections = ConnectionStore(data, secrets)
        // A row the import's own collides with fails its transaction.
        connections.upsert(StoredConnection("emby-machine/user-9", BackendKind.EMBY, JsonObject(emptyMap()), createdAt = 1))
        val import = EarlierReleaseImport(data, secrets)

        assertFailsWith<Exception> { import.run(desktopInstall("v25", "desktop-upgrade")) }

        assertNull(import.outcome())
        assertEquals(listOf("emby-machine/user-9"), connections.list().map { it.id })
        assertEquals(emptyList(), data.profiles.list())
        assertNull(data.storedSetting("view_mode"))
        assertEquals(emptyList(), data.db.read { downloadedMediaQueries.selectAllMedia().executeAsList() })
        assertEquals(emptyList(), data.trackerAccounts.accounts("local-aaa"))

        connections.remove("emby-machine/user-9")
        assertEquals(EarlierReleaseOutcome.IMPORTED, import.run(desktopInstall("v25", "desktop-upgrade")))
        assertEquals(4, connections.list().size)
        assertEquals(ViewMode.LIST, data.deviceSettings.value(AppSettings.viewMode))
    }

    @Test
    fun aSecretStoreThatRefusesEveryWriteImportsEverythingButTheTokens() = runTest {
        // Windows' Credential Manager once this user's credentials fill it.
        val refusing = FailingSecretStore().apply { failWrites = true }
        val data = data()
        val import = EarlierReleaseImport(data, refusing)

        assertEquals(EarlierReleaseOutcome.IMPORTED, import.run(desktopInstall("v25", "desktop-upgrade")))

        assertEquals(EarlierReleaseOutcome.IMPORTED, import.outcome())
        assertEquals(emptyMap(), refusing.memory.entries)
        // Every account's row is kept without its tokens: it signs in again.
        assertEquals(
            setOf("plex-acct-1", "jf-machine/user-1", "emby-machine/user-9", "jf-lost/user-2"),
            data.db.read { connectionQueries.selectAll().executeAsList() }.map { it.id }.toSet(),
        )
        val listed = ConnectionStore(data, refusing).list()
        assertTrue(listed.isNotEmpty() && listed.all { it.text("accountToken") == null && it.text("accessToken") == null })
        // The rest as with a working store: profiles, settings, downloads.
        assertEquals(listOf("local-aaa", "local-bbb"), data.profiles.list().map { it.id })
        assertEquals(ViewMode.LIST, data.deviceSettings.value(AppSettings.viewMode))
        assertTrue(data.db.read { downloadedMediaQueries.selectAllMedia().executeAsList() }.isNotEmpty())
        // A tracker account whose session wasn't stored isn't listed as connected.
        assertEquals(emptyList(), data.trackerAccounts.accounts("local-aaa"))
        assertEquals(emptyList(), data.trackerAccounts.accounts("plex-home-plex-acct-1-0123456789abcdef"))
    }

    @Test
    fun aWindowsInstallFromBeforeTheCompanyNameWasSetIsImportedFromItsOwnDirectory() = runTest {
        val roaming = Files.createTempDirectory("roaming")
        val install = desktopEarlierReleaseLocations(
            osName = "Windows 11",
            environment = { if (it == "APPDATA") roaming.toString() else null },
            home = roaming.toString(),
            isFile = { false },
            documents = { null },
        )
        val orphaned = Path.of(checkNotNull(install.orphanedSupportDirectory))
        Files.createDirectories(orphaned)
        Files.copy(EarlierReleaseFixtures.path("desktop-upgrade/shared_preferences.json"), orphaned.resolve("shared_preferences.json"))
        EarlierReleaseFixtures.path("v25").listDirectoryEntries().forEach { Files.copy(it, orphaned.resolve(it.name)) }
        val data = data()

        assertEquals(EarlierReleaseOutcome.IMPORTED, EarlierReleaseImport(data, secrets).run(install))

        assertEquals("plex-account-token", ConnectionStore(data, secrets).get("plex-acct-1")?.text("accountToken"))
        assertEquals(ViewMode.LIST, data.deviceSettings.value(AppSettings.viewMode))
    }

    @Test
    fun aLinuxInstallInTheExecutableNameDirectoryIsImportedAfterAStartThatMadeTheAppIdDirectory() = runTest {
        val dataHome = Files.createTempDirectory("xdg-data")
        val earlier = Files.createDirectories(dataHome.resolve("plezy"))
        Files.copy(EarlierReleaseFixtures.path("desktop-upgrade/shared_preferences.json"), earlier.resolve("shared_preferences.json"))
        EarlierReleaseFixtures.path("v25").listDirectoryEntries().forEach { Files.copy(it, earlier.resolve(it.name)) }
        // An earlier start opened this app's database, which made the app id directory, and ended before its import.
        val data = data(DatabaseFactory(dataHome.resolve(EARLIER_RELEASE_APP_ID).resolve("plezy.db")))
        val import = EarlierReleaseImport(data, secrets)
        assertNull(import.outcome())
        assertTrue(Files.isDirectory(dataHome.resolve(EARLIER_RELEASE_APP_ID)))
        val install = desktopEarlierReleaseLocations(
            osName = "Linux",
            environment = { if (it == "XDG_DATA_HOME") dataHome.toString() else null },
            home = dataHome.toString(),
            isFile = { Files.isRegularFile(Path.of(it)) },
            documents = { null },
        )

        assertEquals(EarlierReleaseOutcome.IMPORTED, import.run(install))

        assertEquals("plex-account-token", ConnectionStore(data, secrets).get("plex-acct-1")?.text("accountToken"))
        assertEquals(ViewMode.LIST, data.deviceSettings.value(AppSettings.viewMode))
    }

    @Test
    fun aWindowsDatabaseInARedirectedDocumentsFolderIsImportedOnce() = runTest {
        val roaming = Files.createTempDirectory("roaming")
        // Documents moved to OneDrive: the user's profile folder holds none of it.
        val documents = Files.createTempDirectory("onedrive-documents")
        val install = desktopEarlierReleaseLocations(
            osName = "Windows 11",
            environment = mapOf("APPDATA" to roaming.toString(), "USERPROFILE" to Files.createTempDirectory("profile").toString())::get,
            home = roaming.toString(),
            isFile = { false },
            documents = { documents.toString() },
        )
        // The database where the Windows path names it (on another host a file of that name: the path is Windows').
        val database = checkNotNull(install.legacyDatabase)
        val fixture = EarlierReleaseFixtures.path("v25")
        Files.copy(fixture.resolve("plezy_downloads.db"), Path.of(database))
        Files.copy(fixture.resolve("plezy_downloads.db-wal"), Path.of("$database-wal"))
        val preferences = Path.of((install.preferences as EarlierReleasePreferencesLocation.JsonFile).path)
        Files.createDirectories(preferences.parent)
        Files.copy(EarlierReleaseFixtures.path("desktop-upgrade/shared_preferences.json"), preferences)
        val data = data()
        val import = EarlierReleaseImport(data, secrets)

        assertEquals(EarlierReleaseOutcome.IMPORTED, import.run(install))
        assertNull(import.run(install))

        val snapshot = readEarlierReleaseDatabase(database)
        assertTrue(snapshot.connections.isNotEmpty() && snapshot.downloadedMedia.isNotEmpty())
        assertEquals(snapshot.connections.map { it.id }.toSet(), data.db.read { connectionQueries.selectAll().executeAsList() }.map { it.id }.toSet())
        assertEquals(
            snapshot.downloadedMedia.map { it.globalKey },
            data.db.read { downloadedMediaQueries.selectAllMedia().executeAsList() }.map { it.global_key },
        )
        assertEquals(ViewMode.LIST, data.deviceSettings.value(AppSettings.viewMode))
    }

    @Test
    fun theOrphanedWindowsDirectoryIsIgnoredWhileTheCurrentOneHoldsData() {
        val install = desktopInstall("v25", prefs = null).copy(orphanedSupportDirectory = EarlierReleaseFixtures.path("desktop-upgrade").toString())

        assertNull(install.orphanedInstead())
    }

    @Test
    fun anInstallWithoutTheEarlierReleasesIsMarkedDone() = runTest {
        val data = data()
        val import = EarlierReleaseImport(data, secrets)
        val install = desktopInstall(database = null, prefs = null)
        assertFalse(Path.of(install.database).exists())

        assertEquals(EarlierReleaseOutcome.NOTHING, import.run(install))

        assertEquals(EarlierReleaseOutcome.NOTHING, import.outcome())
        assertNull(import.run(desktopInstall("v25", "desktop-upgrade")))
        assertEquals(emptyList(), ConnectionStore(data, secrets).list())
    }
}
