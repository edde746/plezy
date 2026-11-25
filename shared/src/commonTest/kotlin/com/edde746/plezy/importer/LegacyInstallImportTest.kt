package com.edde746.plezy.importer

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.testData
import com.edde746.plezy.importer.EarlierReleasePrefValue.BoolValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringValue
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.net.NetworkState
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ViewMode
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The single-account installs of Plezy's earliest releases, moved to profiles as they're imported. */
class LegacyInstallImportTest {
    private val clock = TestClock()
    private val data = testData(clock)
    private val secrets = MemorySecretStore()
    private val import = EarlierReleaseImport(data, secrets)
    private val connections = ConnectionStore(data, secrets)
    private val identity = ProfileIdentity(data)

    @AfterTest
    fun close() = data.close()

    private fun prefs(vararg entries: Pair<String, Any>) = EarlierReleasePrefs(
        entries.associate { (key, value) -> key to if (value is Boolean) BoolValue(value) else StringValue(value as String) },
    )

    /** Imports [prefs] beside a database holding [accounts] alone, asking plex.tv through [plexUser] (null: offline). */
    private suspend fun importPrefs(prefs: EarlierReleasePrefs, vararg accounts: EarlierReleaseConnectionRow, plexUser: PlexUserLookup? = null) {
        val database = EMPTY_EARLIER_RELEASE_SNAPSHOT.copy(connections = accounts.toList())
        assertEquals(EarlierReleaseOutcome.IMPORTED, import.importFound(EarlierRelease(prefs, database, EarlierReleaseOutcome.IMPORTED), plexUser))
    }

    private fun plexAccount(id: String, token: String) = EarlierReleaseConnectionRow(
        id, "plex", "Owner",
        """{"accountToken":"$token","clientIdentifier":"client-owner","accountLabel":"Owner","activeProfile":null,"servers":[]}""",
        createdAt = 1, lastAuthenticatedAt = null,
    )

    private fun homeUser(uuid: String, title: String, admin: Boolean) =
        """{"id":1,"uuid":"$uuid","title":"$title","thumb":"","hasPassword":false,"restricted":${!admin},"updatedAt":null,""" +
            """"admin":$admin,"guest":false,"protected":false}"""

    private fun homeUsersCache(vararg users: String) =
        """{"id":1,"name":"Home","guestUserID":null,"guestUserUUID":"","guestEnabled":false,"subscription":true,"users":[${users.joinToString(",")}]}"""

    private val legacyServer =
        """[{"name":"Plex","clientIdentifier":"server-1","accessToken":"server-token","owned":true,""" +
            """"connections":[{"protocol":"http","address":"127.0.0.1","port":32400,"uri":"http://127.0.0.1:32400"}]}]"""

    @Test
    fun aFreshInstallGetsNoProfileAndIsMarkedMigrated() = runTest {
        importPrefs(prefs())

        assertEquals(emptyList(), data.profiles.list())
        assertNull(identity.activeProfileId())
        assertTrue(data.deviceSettings.value(AppSettings.profileMigrationDone))
    }

    @Test
    fun aLegacyPlexTokenBecomesAnAccountKeyedByTheDeviceClientIdentifier() = runTest {
        importPrefs(prefs("plex_token" to "legacy-token-1", "client_identifier" to "client-1"))

        val account = connections.list().single()
        assertEquals("plex.client-1", account.id)
        assertEquals(BackendKind.PLEX, account.kind)
        assertEquals(clock.now, account.createdAt)
        assertEquals(JsonPrimitive("legacy-token-1"), account.config["accountToken"])
        assertEquals(JsonPrimitive("client-1"), account.config["clientIdentifier"])
        assertEquals(JsonPrimitive("Plex"), account.config["accountLabel"])
        assertNull(data.db.read { deviceSettingQueries.selectByKey("plex_token").executeAsOneOrNull() })
    }

    @Test
    fun aLegacyPlexTokenWithoutAClientIdentifierMakesOne() = runTest {
        importPrefs(prefs("plex_token" to "legacy-token-abc"))

        val clientId = checkNotNull(data.deviceSettings.value(AppSettings.clientIdentifier))
        val account = connections.list().single()
        assertEquals("plex.$clientId", account.id)
        assertEquals(JsonPrimitive(clientId), account.config["clientIdentifier"])
        assertEquals(JsonPrimitive("legacy-token-abc"), account.config["accountToken"])
    }

    @Test
    fun theLegacyHomeUserIsChosenAndTheHomeUsersCachedForTheAccount() = runTest {
        importPrefs(
            prefs(
                "plex_token" to "legacy-token-home",
                "client_identifier" to "client-1",
                "servers_list" to legacyServer,
                "current_user_uuid" to "home-user-1",
                "home_users_cache" to homeUsersCache(homeUser("home-user-0", "Owner", admin = true), homeUser("home-user-1", "Kid", admin = false)),
            ),
        )

        assertEquals("plex-home-plex.client-1-home-user-1", identity.activeProfileId())
        assertEquals(listOf("home-user-0", "home-user-1"), identity.plexHomeUsers("plex.client-1")?.map { it.uuid })
        val server = connections.list().single().config.getValue("servers").jsonArray.single().jsonObject
        assertEquals("server-1", server.getValue("clientIdentifier").jsonPrimitive.content)
        assertEquals("server-token", server.getValue("accessToken").jsonPrimitive.content)
        // The legacy single-account keys aren't kept.
        assertNull(data.deviceSettings.value(AppSettings.currentUserUuid))
        assertNull(data.deviceSettings.value(AppSettings.homeUsersCache))
        assertNull(data.deviceSettings.value(AppSettings.serversList))
        assertTrue(data.deviceSettings.value(AppSettings.profileMigrationDone))
    }

    @Test
    fun theHomeAdminIsChosenWithoutALegacyHomeUser() = runTest {
        importPrefs(
            prefs(
                "plex_token" to "legacy-owner-token",
                "client_identifier" to "client-owner",
                "home_users_cache" to homeUsersCache(homeUser("managed-user", "Managed", admin = false), homeUser("admin-user", "Owner", admin = true)),
            ),
        )

        assertEquals(emptyList(), data.profiles.list())
        assertEquals("plex-home-plex.client-owner-admin-user", identity.activeProfileId())
    }

    @Test
    fun theFirstHomeUserIsChosenWithoutALegacyHomeUserOrAnAdmin() = runTest {
        importPrefs(
            prefs(
                "plex_token" to "legacy-token",
                "client_identifier" to "client-1",
                "current_user_uuid" to "gone-user",
                "home_users_cache" to homeUsersCache(homeUser("first-user", "First", admin = false), homeUser("second-user", "Second", admin = false)),
            ),
        )

        assertEquals("plex-home-plex.client-1-first-user", identity.activeProfileId())
        assertNull(data.deviceSettings.value(AppSettings.currentUserUuid))
    }

    @Test
    fun aStoreThatLostOnlyTheMigrationFlagChoosesNoProfile() = runTest {
        importPrefs(
            prefs("plex_home_users_plex.client-owner" to "[${homeUser("admin-user", "Owner", admin = true)}]"),
            plexAccount("plex.client-owner", "account-token"),
        )

        assertNull(identity.activeProfileId())
        assertTrue(data.deviceSettings.value(AppSettings.profileMigrationDone))
        assertEquals(listOf("plex.client-owner"), connections.list().map { it.id })
    }

    @Test
    fun aLeftoverServerListIsDroppedOnceMigrated() = runTest {
        importPrefs(prefs("profile_migration_v1_done" to true, "servers_list" to legacyServer))

        assertNull(data.deviceSettings.value(AppSettings.serversList))
        assertEquals(emptyList(), connections.list())
    }

    @Test
    fun aLegacyAccountWithoutCachedHomeUsersKeepsItsTokenAndChoosesNoProfile() = runTest {
        importPrefs(prefs("plex_token" to "legacy-owner-token", "client_identifier" to "client-owner"))

        assertEquals(JsonPrimitive("legacy-owner-token"), connections.get("plex.client-owner")?.config?.get("accountToken"))
        assertNull(identity.activeProfileId())
        assertNull(identity.plexHomeUsers("plex.client-owner"))
        assertTrue(data.deviceSettings.value(AppSettings.profileMigrationDone))
    }

    @Test
    fun aLegacyTokenAlreadyMovedToAnAccountUsesThatAccount() = runTest {
        importPrefs(
            prefs(
                "plex_token" to "legacy-token",
                "client_identifier" to "client-owner",
                "home_users_cache" to homeUsersCache(homeUser("admin-user", "Owner", admin = true)),
            ),
            plexAccount("plex.account-uuid", "legacy-token"),
        )

        assertEquals(listOf("plex.account-uuid"), connections.list().map { it.id })
        assertEquals("plex-home-plex.account-uuid-admin-user", identity.activeProfileId())
    }

    @Test
    fun legacyProfileStateThatCameBackAfterTheMigrationIsChosenAgain() = runTest {
        importPrefs(
            prefs(
                "profile_migration_v1_done" to true,
                "active_app_profile_id" to "local-other",
                "current_user_uuid" to "kid-user",
                "home_users_cache" to homeUsersCache(homeUser("admin-user", "Owner", admin = true), homeUser("kid-user", "Kid", admin = false)),
            ),
            plexAccount("plex.account-uuid", "account-token"),
        )

        assertEquals("plex-home-plex.account-uuid-kid-user", identity.activeProfileId())
        assertEquals(listOf("admin-user", "kid-user"), identity.plexHomeUsers("plex.account-uuid")?.map { it.uuid })
    }

    // plex.tv's word on a legacy account.

    private val asked = mutableListOf<Pair<String, String>>()

    private fun plexTv(user: String): PlexUserLookup = { token, clientId ->
        asked += token to clientId
        Json.parseToJsonElement(user).jsonObject
    }

    private val plexTvDown: PlexUserLookup = { token, clientId ->
        asked += token to clientId
        throw IllegalStateException("plex.tv is down")
    }

    private suspend fun label(id: String) = connections.get(id)?.config?.get("accountLabel")?.jsonPrimitive?.content

    @Test
    fun onlineTheLegacyAccountIsKeyedByItsPlexUuidAndLabelledWithItsUsername() = runTest {
        importPrefs(
            prefs(
                "plex_token" to "legacy-token-uuid",
                "client_identifier" to "device-client",
                "current_user_uuid" to "kid-user",
                "home_users_cache" to homeUsersCache(homeUser("admin-user", "Owner", admin = true), homeUser("kid-user", "Kid", admin = false)),
            ),
            plexUser = plexTv("""{"uuid":"account-uuid-1","username":"edde","email":"edde@example.com"}"""),
        )

        val account = connections.list().single()
        assertEquals("plex.account-uuid-1", account.id)
        assertEquals(JsonPrimitive("device-client"), account.config["clientIdentifier"])
        assertEquals("edde", label(account.id))
        assertEquals(listOf("legacy-token-uuid" to "device-client"), asked)
        assertEquals("plex-home-plex.account-uuid-1-kid-user", identity.activeProfileId())
        assertNull(data.deviceSettings.value(EarlierReleaseImport.MARKER)?.unidentifiedPlexAccount)
    }

    @Test
    fun anAccountWithoutAUsernameIsLabelledWithItsEmail() = runTest {
        importPrefs(prefs("plex_token" to "legacy-token-1", "client_identifier" to "client-1"), plexUser = plexTv("""{"uuid":"u1","email":"edde@example.com"}"""))

        assertEquals("edde@example.com", label("plex.u1"))
    }

    @Test
    fun anAccountPlexTvDidNotNameIsNamedAtTheNextStartOnline() = runTest {
        importPrefs(prefs("plex_token" to "legacy-token-1", "client_identifier" to "client-1"), plexUser = plexTvDown)
        assertEquals("Plex", label("plex.client-1"))
        assertEquals("plex.client-1", data.deviceSettings.value(EarlierReleaseImport.MARKER)?.unidentifiedPlexAccount)

        val network = MutableStateFlow(NetworkState.OFFLINE)
        val naming = launch { import.nameImportedPlexAccount(connections, network, plexTv("""{"uuid":"account-uuid-1","username":"edde"}""")) }
        testScheduler.advanceUntilIdle()
        assertEquals(1, asked.size)
        network.value = NetworkState.ONLINE
        naming.join()

        // The id stays: the account's profiles and caches are keyed by it.
        assertEquals(listOf("plex.client-1"), connections.list().map { it.id })
        assertEquals("edde", label("plex.client-1"))
        assertEquals(listOf("legacy-token-1" to "client-1"), asked.drop(1))
        assertNull(data.deviceSettings.value(EarlierReleaseImport.MARKER)?.unidentifiedPlexAccount)
        import.nameImportedPlexAccount(connections, network, plexTv("""{"username":"other"}"""))
        assertEquals(2, asked.size)
    }

    @Test
    fun anOfflineImportKeysTheAccountByTheClientIdentifierUntilPlexTvAnswers() = runTest {
        importPrefs(prefs("plex_token" to "legacy-token-1", "client_identifier" to "client-1"))
        val online = MutableStateFlow(NetworkState.ONLINE)

        import.nameImportedPlexAccount(connections, online, plexTvDown)

        assertEquals("Plex", label("plex.client-1"))
        assertEquals("plex.client-1", data.deviceSettings.value(EarlierReleaseImport.MARKER)?.unidentifiedPlexAccount)
        import.nameImportedPlexAccount(connections, online, plexTv("""{"uuid":"account-uuid-1","username":"edde"}"""))
        assertEquals("edde", label("plex.client-1"))
    }
}

/** Apple TV, whose database the system may purge: its recovery copy in the user defaults stands in. */
class TvosImportTest {
    private val data = testData(TestClock())
    private val secrets = MemorySecretStore()
    private val import = EarlierReleaseImport(data, secrets)

    @AfterTest
    fun close() = data.close()

    private val vaultKey = EarlierReleasePrefs.VAULT_KEY to StringValue(EarlierReleaseFixtureVectors.VAULT_KEY)
    private val activeProfile = "active_app_profile_id" to StringValue("local-aaa")

    /** An Apple TV start over the earlier release's preferences [prefs] and no database left. */
    private suspend fun importTv(prefs: EarlierReleasePrefs?) = import.importFound(readEarlierRelease(prefs, database = null, purgeableDatabase = true))

    @Test
    fun aPurgedDatabaseComesBackFromTheCommittedRecoveryImage() = runTest {
        val prefs = EarlierReleasePrefs(
            mapOf(
                vaultKey,
                activeProfile,
                TVOS_RECOVERY_MANIFEST_KEY to StringValue(EarlierReleaseFixtureVectors.TVOS_MANIFEST),
                TVOS_RECOVERY_IDENTITY_KEY to StringValue(EarlierReleaseFixtureVectors.TVOS_IDENTITY),
                TVOS_RECOVERY_PENDING_KEY to StringValue(EarlierReleaseFixtureVectors.TVOS_PENDING),
            ),
        )

        assertEquals(EarlierReleaseOutcome.RESTORED, importTv(prefs))

        assertEquals(EarlierReleaseOutcome.RESTORED, import.outcome())
        val connection = ConnectionStore(data, secrets).list().single()
        assertEquals("jf-machine/user-1", connection.id)
        assertEquals(JsonPrimitive("jellyfin-access-token"), connection.config["accessToken"])
        assertEquals(listOf("local-aaa"), data.profiles.list().map { it.id })
        assertEquals("profile-token-tv", ProfileConnectionRegistry(data, secrets).get("local-aaa", "jf-machine/user-1")?.userToken)
        assertEquals(listOf(4L), data.db.read { offlineWatchQueries.selectPending().executeAsList() }.map { it.id })
        // The recovery copy itself isn't a setting.
        assertNull(data.db.read { deviceSettingQueries.selectByKey(TVOS_RECOVERY_MANIFEST_KEY).executeAsOneOrNull() })
        assertEquals("local-aaa", ProfileIdentity(data).activeProfileId())
    }

    @Test
    fun aPurgedDatabaseWithoutARecoveryImageAsksToSignInAgainAndKeepsTheSettings() = runTest {
        val prefs = EarlierReleasePrefs(mapOf(vaultKey, activeProfile, "view_mode" to StringValue("list")))

        assertEquals(EarlierReleaseOutcome.RECOVERY_REQUIRED, importTv(prefs))

        assertEquals(EarlierReleaseOutcome.RECOVERY_REQUIRED, import.outcome())
        assertEquals(emptyList(), ConnectionStore(data, secrets).list())
        assertEquals(ViewMode.LIST, data.deviceSettings.value(AppSettings.viewMode))
    }

    @Test
    fun anAppleTvThatNeverRanTheEarlierReleasesHasNothingToImport() = runTest {
        assertEquals(EarlierReleaseOutcome.NOTHING, importTv(prefs = null))
    }
}

/** The Live TV favourites of Jellyfin and Emby connections, from the slots the earlier releases adopted them from. */
class LiveTvFavoritesImportTest {
    private val data = testData(TestClock())
    private val import = EarlierReleaseImport(data, MemorySecretStore())

    @AfterTest
    fun close() = data.close()

    private fun jellyfin(id: String, createdAt: Long) =
        EarlierReleaseConnectionRow(id, "jellyfin", id, """{"serverMachineId":"srv","accessToken":""}""", createdAt, null)

    private fun channels(id: String) = StringValue("""[{"source":"tuner","id":"$id"}]""")

    @Test
    fun aConnectionWithoutItsOwnListAdoptsTheOlderSlotsInTheEarlierReleasesOrderEachOnce() = runTest {
        val prefs = EarlierReleasePrefs.resolve(
            mapOf(
                EarlierReleasePrefs.MIGRATION_SENTINEL to BoolValue(true),
                "jellyfin_fav_channels:srv/user-c" to channels("own"),
                "flutter.jellyfin_fav_channels:srv/user-c" to channels("stale"),
                "jellyfin_fav_channels:srv" to channels("server"),
                "flutter.jellyfin_fav_channels:srv" to channels("prefixed-server"),
            ),
        )
        val database = EMPTY_EARLIER_RELEASE_SNAPSHOT.copy(connections = listOf(jellyfin("srv/user-a", 1), jellyfin("srv/user-b", 2), jellyfin("srv/user-c", 3)))

        import.importFound(EarlierRelease(prefs, database, EarlierReleaseOutcome.IMPORTED))

        assertEquals(listOf("server"), data.liveTvFavorites.favorites("srv/user-a").map { it.id })
        assertEquals(listOf("prefixed-server"), data.liveTvFavorites.favorites("srv/user-b").map { it.id })
        assertEquals(listOf("own"), data.liveTvFavorites.favorites("srv/user-c").map { it.id })
    }
}

/** The Android player engine choice and its options, which this app no longer has. */
class RemovedPlayerSettingsImportTest {
    private val clock = TestClock()
    private val opened = ArrayList<LocalData>()

    @AfterTest
    fun close() = opened.forEach { it.close() }

    /** The settings an import of [prefs] keeps: device, profile and server rows. */
    private suspend fun importedSettings(vararg prefs: Pair<String, EarlierReleasePrefValue>): List<Set<Any>> {
        val data = testData(clock).also { opened += it }
        val found = EarlierRelease(EarlierReleasePrefs(prefs.toMap()), EMPTY_EARLIER_RELEASE_SNAPSHOT, EarlierReleaseOutcome.IMPORTED)
        assertEquals(EarlierReleaseOutcome.IMPORTED, EarlierReleaseImport(data, MemorySecretStore()).importFound(found))
        return data.db.read {
            listOf(
                deviceSettingQueries.selectAll().executeAsList().toSet(),
                deviceSettingQueries.selectAllProfileSettings().executeAsList().toSet(),
                deviceSettingQueries.selectAllServerSettings().executeAsList().toSet(),
            )
        }
    }

    @Test
    fun theAndroidEngineChoiceAndItsOptionsStoreNothingAndChangeNothingElse() = runTest {
        val kept = arrayOf(
            AppSettings.enableHardwareDecoding.key to BoolValue(false),
            AppSettings.dvConversionMode.key to StringValue("dv81"),
        )
        val removed = arrayOf(
            "android_use_exoplayer" to BoolValue(true),
            "use_exoplayer" to BoolValue(true),
            "tunneled_playback" to BoolValue(true),
            "playback_buffer_tier" to StringValue("extraLarge"),
            "subtitle_anchor_to_screen" to BoolValue(true),
        )

        val withRemoved = importedSettings(*kept, *removed)

        assertEquals(importedSettings(*kept), withRemoved)
        assertTrue(Device_setting(AppSettings.dvConversionMode.key, "\"dv81\"") in withRemoved[0])
    }
}
