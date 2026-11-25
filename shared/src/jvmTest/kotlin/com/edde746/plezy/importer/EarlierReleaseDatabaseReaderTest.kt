package com.edde746.plezy.importer

import com.edde746.plezy.importer.EarlierReleaseFixtures.T
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assume.assumeTrue
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.attribute.PosixFilePermissions
import java.sql.DriverManager
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.io.path.readBytes
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class EarlierReleaseDatabaseReaderTest {
    private val v25 = EarlierReleaseFixtures.path("v25/plezy_downloads.db")

    @Test
    fun readsEveryTableOfASchema25DatabaseIncludingRowsStillInTheWal() {
        val db = readEarlierReleaseDatabase(v25.toString())

        assertEquals(25, db.schemaVersion)
        assertEquals(
            listOf(
                EarlierReleaseDownloadedMediaRow(
                    id = 1, serverId = "srv-plex-1", clientScopeId = "srv-plex-1/~plex-profile/local-aaa", ratingKey = "101",
                    globalKey = "srv-plex-1:101", type = "movie", parentRatingKey = null, grandparentRatingKey = null, status = 3,
                    progress = 100, totalBytes = 4_000_000_000, downloadedBytes = 4_000_000_000,
                    videoFilePath = "downloads/Movies/Heat (1995)/Heat (1995) [0a1b2c3d].mkv",
                    additionalPartPaths = "[\"downloads/Movies/Heat (1995)/Heat (1995) [0a1b2c3d] - part2.mkv\",null]",
                    safRootUri = null, thumbPath = "/library/metadata/101/thumb/1700000000", downloadedAt = T + 1_000_000,
                    errorMessage = null, retryCount = 0, bgTaskId = null, mediaIndex = 0, mediaSourceId = null, libraryId = "1",
                    libraryTitle = "Movies",
                ),
                EarlierReleaseDownloadedMediaRow(
                    id = 2, serverId = "jf-machine", clientScopeId = "jf-machine/user-1", ratingKey = "ep-7",
                    globalKey = "jf-machine:ep-7", type = "episode", parentRatingKey = "season-2", grandparentRatingKey = "show-1",
                    status = 4, progress = 42, totalBytes = 900_000_000, downloadedBytes = 378_000_000,
                    videoFilePath = "content://com.android.externalstorage.documents/tree/primary%3APlezy/document/primary%3APlezy%2FS02E07.mkv",
                    additionalPartPaths = null, safRootUri = "content://com.android.externalstorage.documents/tree/primary%3APlezy",
                    thumbPath = "https://jf.example.invalid/Items/ep-7/Images/Primary?tag=abc&api_key=secret-key", downloadedAt = null,
                    errorMessage = "HTTP 503", retryCount = 2, bgTaskId = "task-2", mediaIndex = 1, mediaSourceId = "source-7",
                    libraryId = "lib-tv", libraryTitle = "Séries",
                ),
                EarlierReleaseDownloadedMediaRow(
                    id = 3, serverId = "srv-plex-1", clientScopeId = null, ratingKey = "102", globalKey = "srv-plex-1:102", type = "movie",
                    parentRatingKey = null, grandparentRatingKey = null, status = 0, progress = 0, totalBytes = null, downloadedBytes = 0,
                    videoFilePath = null, additionalPartPaths = null, safRootUri = null, thumbPath = null, downloadedAt = null,
                    errorMessage = null, retryCount = 0, bgTaskId = null, mediaIndex = 0, mediaSourceId = null, libraryId = null,
                    libraryTitle = null,
                ),
            ),
            db.downloadedMedia,
        )
        assertEquals(
            listOf(
                EarlierReleaseDownloadOwnerRow("local-aaa", "jf-machine:ep-7", "jellyfin", "jf-machine/user-1", T + 1_100_000),
                EarlierReleaseDownloadOwnerRow("local-aaa", "srv-plex-1:101", "plex", "srv-plex-1/~plex-profile/local-aaa", T + 1_000_000),
                EarlierReleaseDownloadOwnerRow("local-bbb", "jf-machine:ep-7", null, null, T + 1_200_000),
            ),
            db.downloadOwners,
        )
        assertEquals(listOf(EarlierReleaseDownloadQueueRow(1, "jf-machine:ep-7", 5, T + 1_100_000, downloadSubtitles = true, downloadArtwork = false)), db.downloadQueue)
        // Of the API cache only the pinned row: the unpinned `srv-plex-1:/library/sections` is left behind.
        assertEquals(
            listOf(
                EarlierReleaseApiCacheRow(
                    "srv-plex-1/~plex-profile/local-aaa:/library/metadata/101",
                    "{\"MediaContainer\":{\"Metadata\":[{\"ratingKey\":\"101\",\"title\":\"Heat\"}]}}",
                    cachedAt = 1_700_000_000,
                ),
            ),
            db.pinnedApiCache,
        )
        assertEquals(
            listOf(
                EarlierReleaseOfflineWatchProgressRow(
                    1, "local-aaa", "srv-plex-1", null, "101", "srv-plex-1:101", "progress", 120_000, 7_200_000, false,
                    T + 2_000_000, T + 2_000_500, 0, null,
                ),
                EarlierReleaseOfflineWatchProgressRow(
                    2, null, "jf-machine", "jf-machine/user-1", "ep-7", "jf-machine:ep-7", "watched", null, null, true,
                    T + 2_100_000, T + 2_100_000, 2, "HTTP 503",
                ),
            ),
            db.offlineWatchProgress,
        )
        assertEquals(
            listOf(
                EarlierReleaseSyncRuleRow(
                    1, "local-aaa", "jf-machine", "show-1", "jf-machine:show-1", "show", 5, true, T + 3_000_000, T + 3_100_000, 0,
                    "unwatched", includeSpecials = true, downloadLinksInitialized = true,
                ),
                EarlierReleaseSyncRuleRow(
                    2, "", "srv-plex-1", "coll-9", "srv-plex-1:coll-9", "collection", 0, false, T + 3_200_000, null, 2, "all",
                    includeSpecials = false, downloadLinksInitialized = false,
                ),
            ),
            db.syncRules,
        )
        assertEquals(listOf(EarlierReleaseSyncRuleDownloadRow(1, "local-aaa", "jf-machine:ep-7")), db.syncRuleDownloads)
        assertEquals(listOf(EarlierReleaseDownloadCollectionRow("local-aaa", "srv-plex-1", "coll-9", "[\"101\",\"102\"]")), db.downloadCollections)
        assertEquals(
            listOf(EarlierReleaseDownloadCollectionSyncRow("local-aaa", "srv-plex-1", T + 3_300_000, "[\"101\",\"102\",\"103\"]")),
            db.downloadCollectionSyncs,
        )
        assertEquals(
            listOf(
                EarlierReleaseConnectionRow("emby-machine/user-9", "emby", "Cabin", "", T + 150_000, T + 160_000),
                EarlierReleaseConnectionRow("jf-lost/user-2", "jellyfin", "Lost", "", T + 170_000, null),
                EarlierReleaseConnectionRow("jf-machine/user-1", "jellyfin", "Basement", "", T + 100_000, null),
                EarlierReleaseConnectionRow("plex-acct-1", "plex", "Alex Plex", "", T, T + 500_000),
            ),
            db.connections.map { it.copy(configJson = "") },
        )
        assertEquals(
            listOf(
                EarlierReleaseProfileRow(
                    "local-aaa", "local", "Alex", null, "{\"pinHash\":\"a2779ae69839fea3247e7f508276ea5a588d45734004bced89590b08549d37fe\"}",
                    0, T, T + 900_000,
                ),
                // Its last use was updated in the write-ahead log.
                EarlierReleaseProfileRow("local-bbb", "local", "Kid", "https://avatar.example.invalid/kid.png", "{}", 1, T + 200_000, T + 950_000),
                EarlierReleaseProfileRow("plex-home-legacy", "plex_home", "Legacy Home", null, "{}", 2, T + 210_000, null),
            ),
            db.profiles,
        )
        assertEquals(
            listOf(
                EarlierReleaseProfileConnectionRow("local-aaa", "jf-machine/user-1", "", "user-1", false, null, null),
                EarlierReleaseProfileConnectionRow("local-aaa", "plex-acct-1", "", "plex-user-1", true, T + 300_000, T + 800_000),
                EarlierReleaseProfileConnectionRow("local-bbb", "emby-machine/user-9", "", "user-9", true, null, T + 700_000),
                EarlierReleaseProfileConnectionRow("plex-home-plex-acct-1-uuid-9", "plex-acct-1", "", "uuid-9", false, T + 310_000, null),
            ),
            db.profileConnections.map { it.copy(userToken = "") },
        )
        assertEquals(
            listOf(
                EarlierReleaseMusicSessionRow(
                    "local-aaa", "[{\"id\":\"t1\"},{\"id\":\"t2\"}]", "[1,0]", 1, true, "all", "Album X", "album", 61_000, T + 4_000_000,
                ),
            ),
            db.musicSessions,
        )
    }

    @Test
    fun theTokensDecryptWithTheVaultKeyFromThePreferences() = runTest {
        val vault = EarlierReleaseCredentialVault.from(readDesktopEarlierReleasePrefs(EarlierReleaseFixtures.path("desktop/shared_preferences.json").toString())!!)
        val db = readEarlierReleaseDatabase(v25.toString())

        val tokens = db.connections.associate { row ->
            val config = vault.revealConnectionConfig(row.kind, parseStrictJson(row.configJson).jsonObject)
            val servers = (config["servers"] as JsonArray?)?.map { it.jsonObject.getValue("accessToken").jsonPrimitive.content }.orEmpty()
            row.id to listOf(config.getValue(if (row.kind == "plex") "accountToken" else "accessToken").jsonPrimitive.content) + servers
        }
        assertEquals(
            mapOf(
                "emby-machine/user-9" to listOf("plaintext-emby-token"),
                "jf-lost/user-2" to listOf(""),
                "jf-machine/user-1" to listOf("jellyfin-access-token"),
                "plex-acct-1" to listOf("plex-account-token", "plex-server-token-1", "plaintext-plex-server-token-2"),
            ),
            tokens,
        )
        assertEquals(
            listOf("", "profile-token-alex", "plaintext-profile-token-kid", "home-user-token"),
            db.profileConnections.map { vault.reveal(it.userToken) },
        )
    }

    @Test
    fun leavesTheOriginalFilesUntouched() {
        val directory = v25.parent
        val before = directory.listDirectoryEntries().associate { it.name to it.readBytes() }

        readEarlierReleaseDatabase(v25.toString())

        val after = directory.listDirectoryEntries().associate { it.name to it.readBytes() }
        assertEquals(setOf("plezy_downloads.db", "plezy_downloads.db-wal"), after.keys)
        for ((name, bytes) in before) assertContentEquals(bytes, after[name], name)
    }

    @Test
    fun upgradesASchema16DatabaseAsTheEarlierReleasesDid() {
        val db = readEarlierReleaseDatabase(EarlierReleaseFixtures.path("v16/plezy_downloads.db").toString())

        assertEquals(16, db.schemaVersion)
        // Step 17: pinned Plex metadata copied under each owner's namespace, an ownerless download's under the
        // transfer namespace without watch state (an unparseable one discarded), and the bare rows removed.
        val item = "{\"MediaContainer\":{\"size\":1,\"Metadata\":[{\"ratingKey\":\"item\",\"title\":\"Item item\",\"viewOffset\":5000}]}}"
        val children = "{\"MediaContainer\":{\"size\":1,\"Metadata\":[{\"ratingKey\":\"child\",\"title\":\"Item child\"}]}}"
        val season = "{\"MediaContainer\":{\"size\":1,\"Metadata\":[{\"ratingKey\":\"season\",\"title\":\"Item season\"}]}}"
        assertEquals(
            listOf(
                EarlierReleaseApiCacheRow("plex-server/~plex-profile/profile-a:/library/metadata/item", item, 1_700_000_001),
                EarlierReleaseApiCacheRow("plex-server/~plex-profile/profile-a:/library/metadata/item/children", children, 1_700_000_002),
                EarlierReleaseApiCacheRow("plex-server/~plex-profile/profile-a:/library/metadata/season", season, 1_700_000_003),
                EarlierReleaseApiCacheRow("plex-server/~plex-profile/profile-b:/library/metadata/item", item, 1_700_000_001),
                EarlierReleaseApiCacheRow("plex-server/~plex-profile/profile-b:/library/metadata/item/children", children, 1_700_000_002),
                EarlierReleaseApiCacheRow("plex-server/~plex-profile/profile-b:/library/metadata/season", season, 1_700_000_003),
                EarlierReleaseApiCacheRow(
                    "plex-server/~plex-transfer:/library/metadata/orphan",
                    "{\"MediaContainer\":{\"Metadata\":[{\"ratingKey\":\"orphan\",\"Media\":[{\"Part\":[{\"file\":\"x.mkv\"}]}]}]}}",
                    1_700_000_007,
                ),
                EarlierReleaseApiCacheRow("plex-server:/library/metadata/item/extras", "{}", 1_700_000_005),
                EarlierReleaseApiCacheRow("plex-server:/library/sections/1/all", "{}", 1_700_000_006),
            ),
            db.pinnedApiCache,
        )
        assertEquals(
            listOf("plex-server/~plex-profile/profile-a", "plex-server/~plex-transfer", null, "jf-machine/user-a"),
            db.downloadedMedia.map { it.clientScopeId },
        )
        // Step 19: each owner's scope from its own profile; a Jellyfin profile's default binding wins.
        assertEquals(
            listOf(
                EarlierReleaseDownloadOwnerRow("profile-a", "jf-machine:jf-item", "jellyfin", "jf-machine/user-z", T + 12),
                EarlierReleaseDownloadOwnerRow("profile-a", "plex-server:item", "plex", "plex-server/~plex-profile/profile-a", T + 10),
                EarlierReleaseDownloadOwnerRow("profile-b", "plex-server:item", "plex", "plex-server/~plex-profile/profile-b", T + 11),
                EarlierReleaseDownloadOwnerRow("profile-c", "jf-machine:jf-item", "jellyfin", "jf-machine/user-c", T + 13),
                EarlierReleaseDownloadOwnerRow("profile-x", "jf-machine:jf-item", null, null, T + 14),
            ),
            db.downloadOwners,
        )
        // Step 21 rebuilt connections without is_default; steps 18-25 added columns and tables with their defaults.
        assertEquals(
            listOf(
                EarlierReleaseConnectionRow("jf-machine", "jellyfin", "Bare", "{}", T + 3, null),
                EarlierReleaseConnectionRow("jf-machine/user-a", "jellyfin", "A", "{}", T, null),
                EarlierReleaseConnectionRow("jf-machine/user-z", "jellyfin", "Z", "{}", T + 1, T + 2),
            ),
            db.connections,
        )
        assertEquals(
            listOf(
                EarlierReleaseSyncRuleRow(
                    1, "profile-a", "jf-machine", "show-1", "jf-machine:show-1", "show", 3, true, T, null, 0, "unwatched",
                    includeSpecials = false, downloadLinksInitialized = false,
                ),
            ),
            db.syncRules,
        )
        val item4 = db.downloadedMedia.single { it.id == 4L }
        assertEquals(listOf("task-4", "source-4", null, null, null, null), listOf(item4.bgTaskId, item4.mediaSourceId, item4.safRootUri, item4.libraryId, item4.libraryTitle, item4.additionalPartPaths))
        assertEquals(2L, item4.mediaIndex)
        assertTrue(db.syncRuleDownloads.isEmpty() && db.musicSessions.isEmpty() && db.downloadCollections.isEmpty() && db.downloadCollectionSyncs.isEmpty())
        assertEquals(1, db.offlineWatchProgress.size)
        assertEquals(3, db.profileConnections.size)
    }

    @Test
    fun aRetriedUpgradeToleratesWhatAnInterruptedOneAlreadyDid() {
        // Schema 16's tables, indexes and columns, marked 13: steps 14-16 find their work done.
        val retried = readEarlierReleaseDatabase(withUserVersion(13, fixture = "v16"))

        assertEquals(13, retried.schemaVersion)
        assertEquals(readEarlierReleaseDatabase(EarlierReleaseFixtures.path("v16/plezy_downloads.db").toString()).copy(schemaVersion = 13), retried)
    }

    @Test
    fun refusesADatabaseANewerReleaseWrote() {
        val copy = withUserVersion(26)

        assertEquals(26, assertFailsWith<EarlierReleaseDatabaseVersionException> { readEarlierReleaseDatabase(copy) }.version)
    }

    @Test
    fun refusesADatabaseOlderThanTheOldestUpgradableSchema() {
        val copy = withUserVersion(5)

        assertEquals(5, assertFailsWith<EarlierReleaseDatabaseVersionException> { readEarlierReleaseDatabase(copy) }.version)
    }

    @Test
    fun anEmptyFileHoldsNoRows() {
        val file = Files.createTempDirectory("flutter-import").resolve("plezy_downloads.db").also { Files.createFile(it) }

        val db = readEarlierReleaseDatabase(file.toString())

        assertEquals(0, db.schemaVersion)
        assertTrue(db.connections.isEmpty() && db.downloadedMedia.isEmpty() && db.pinnedApiCache.isEmpty())
    }

    @Test
    fun theWorkingCopyGoesInADirectoryOnlyItsOwnerCanOpen() {
        // The shared temporary directory (`/tmp`) is readable by every local user; the copy holds tokens and history.
        // Windows has no POSIX permissions to check.
        assumeTrue("posix" in FileSystems.getDefault().supportedFileAttributeViews())
        val directory = Path.of(createPrivateDirectory())
        try {
            assertEquals(PosixFilePermissions.fromString("rwx------"), Files.getPosixFilePermissions(directory))
        } finally {
            Files.delete(directory)
        }
    }

    private fun withUserVersion(version: Int, fixture: String = "v25"): String {
        val file = EarlierReleaseFixtures.copyOf(fixture).resolve("plezy_downloads.db")
        DriverManager.getConnection("jdbc:sqlite:$file").use { it.createStatement().use { s -> s.execute("PRAGMA user_version = $version") } }
        return file.toString()
    }
}
