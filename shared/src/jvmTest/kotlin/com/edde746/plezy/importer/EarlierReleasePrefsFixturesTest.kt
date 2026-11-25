package com.edde746.plezy.importer

import com.edde746.plezy.importer.EarlierReleasePrefValue.BoolValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.DoubleValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.LongValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringListValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringValue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.jsonPrimitive
import java.nio.file.Files
import kotlin.io.path.readBytes
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class EarlierReleasePrefsFixturesTest {
    private val dataStore = EarlierReleaseFixtures.path("android/files/datastore/FlutterSharedPreferences.preferences_pb")
    private val legacyXml = EarlierReleaseFixtures.path("android/shared_prefs/FlutterSharedPreferences.xml")
    private val vaultKey = StringValue(EarlierReleaseFixtureVectors.VAULT_KEY)
    private val seerrSession = StringValue(EarlierReleaseFixtureVectors.SEERR_SESSION)

    @Test
    fun readsTheAndroidDataStoreWithItsListEncodingsAndWithoutTypesThePluginNeverRead() {
        assertEquals(
            mapOf(
                EarlierReleasePrefs.MIGRATION_SENTINEL to BoolValue(true),
                "enable_debug_logging" to BoolValue(false),
                "seek_time_small" to LongValue(15),
                "audio_sync_offset" to LongValue(-250),
                "volume" to DoubleValue(100.0),
                "view_mode" to StringValue("list"),
                "user_local-aaa_library_order" to StringListValue(listOf("2", "1", "7")),
                "user_local-aaa_hidden_genres" to StringListValue(
                    listOf("Action", "Comédie", "Documentary", "Drama", "Science Fiction", "Animation", "Thriller", "Western"),
                ),
                "subtitle_font_scale" to DoubleValue(1.25),
                EarlierReleasePrefs.VAULT_KEY to vaultKey,
                "active_app_profile_id" to StringValue("local-aaa"),
                "user_local-aaa_seerr_session" to seerrSession,
            ),
            decodeAndroidDataStorePrefs(dataStore.readBytes()),
        )
    }

    @Test
    fun readsTheLegacyAndroidXmlStore() {
        assertEquals(
            mapOf(
                "flutter.view_mode" to StringValue("grid"),
                "flutter.enable_debug_logging" to BoolValue(true),
                "flutter.seek_time_small" to LongValue(20),
                "flutter.sleep_timer_duration" to LongValue(45),
                "flutter.volume" to DoubleValue(80.0),
                "flutter.legacy_ratio" to DoubleValue(0.5),
                "flutter.library_order" to StringListValue(listOf("b", "a")),
                "flutter.hidden_genres" to StringListValue(listOf("Horror", "Kids")),
                "flutter.old_set" to StringListValue(listOf("x", "y")),
                "flutter.big_counter" to LongValue(35L * 36 + 35),
                "flutter.server_name" to StringValue("Tom & Jerry <\"Den\">"),
                "flutter.emoji" to StringValue("été"),
                "flutter.credential_vault_key_v1" to vaultKey,
            ),
            decodeLegacyAndroidPrefs(legacyXml.readBytes()),
        )
    }

    @Test
    fun aMigratedAndroidInstallReadsTheDataStoreOnly() {
        val prefs = readAndroidEarlierReleasePrefs(dataStore.toString(), legacyXml.toString())!!

        assertEquals(decodeAndroidDataStorePrefs(dataStore.readBytes()), prefs.values)
    }

    @Test
    fun anUnmigratedAndroidInstallReadsTheLegacyStoreUnderBareKeys() {
        val prefs = readAndroidEarlierReleasePrefs(dataStore.resolveSibling("absent.preferences_pb").toString(), legacyXml.toString())!!

        assertEquals("grid", prefs.string("view_mode"))
        assertEquals(80.0, prefs.double("volume"))
        assertEquals(listOf("Horror", "Kids"), prefs.stringList("hidden_genres"))
        assertEquals(EarlierReleaseFixtureVectors.VAULT_KEY, prefs.string(EarlierReleasePrefs.VAULT_KEY))
    }

    @Test
    fun noAndroidStoreIsNothingToImport() {
        val directory = Files.createTempDirectory("flutter-import")

        assertNull(readAndroidEarlierReleasePrefs(directory.resolve("a").toString(), directory.resolve("b").toString()))
    }

    @Test
    fun readsTheDesktopStoreIgnoringStaleLegacyKeysAndTheUnfinishedWrite() {
        val prefs = readDesktopEarlierReleasePrefs(EarlierReleaseFixtures.path("desktop/shared_preferences.json").toString())!!

        assertEquals(
            mapOf(
                "view_mode" to StringValue("grid"),
                "volume" to DoubleValue(100.0),
                "seek_time_small" to LongValue(15),
                "audio_sync_offset" to LongValue(-250),
                "enable_debug_logging" to BoolValue(true),
                "user_local-aaa_library_order" to StringListValue(listOf("2", "1", "7")),
                EarlierReleasePrefs.VAULT_KEY to vaultKey,
                "client_identifier" to StringValue("plezy-client-1"),
                "active_app_profile_id" to StringValue("local-aaa"),
                "profile_migration_v1_done" to BoolValue(true),
                EarlierReleasePrefs.MIGRATION_SENTINEL to BoolValue(true),
                "user_local-aaa_seerr_session" to seerrSession,
                "trakt_session" to StringValue(
                    """{"access_token":"trakt-access-token","refresh_token":"trakt-refresh-token","expires_at":4102444800,"username":"alex","created_at":1700000000}""",
                ),
            ),
            prefs.values,
        )
    }

    @Test
    fun readsAPreMigrationDesktopStoreUnderBareKeys() {
        val prefs = readDesktopEarlierReleasePrefs(EarlierReleaseFixtures.path("desktop-legacy/shared_preferences.json").toString())!!

        assertEquals(
            mapOf(
                "view_mode" to StringValue("grid"),
                "volume" to DoubleValue(80.0),
                "seek_time_small" to LongValue(20),
                "library_order" to StringListValue(listOf("a", "b")),
                "enable_debug_logging" to BoolValue(false),
            ),
            prefs.values,
        )
    }

    @Test
    fun aDamagedDesktopStoreFailsAndItsCredentialsAreSalvaged() {
        val file = EarlierReleaseFixtures.path("desktop-damaged/shared_preferences.json")

        assertFailsWith<CorruptPreferenceStoreException> { readDesktopEarlierReleasePrefs(file.toString()) }
        val salvaged = salvageDesktopPrefs(file.readBytes())
        assertEquals(EarlierReleaseFixtureVectors.VAULT_KEY, salvaged.vaultKey)
        assertEquals(setOf("trakt_session", "plex_token", "user_local-aaa_seerr_session"), salvaged.sessions.keys)
        assertEquals("legacy-plex-token", salvaged.sessions["plex_token"])
        assertEquals(EarlierReleaseFixtureVectors.SEERR_SESSION, salvaged.sessions["user_local-aaa_seerr_session"])
        // The anilist session lacks its creation time; the mal one was cut off mid-value and matches nothing.
        assertEquals(1, salvaged.losses)
    }

    @Test
    fun theSalvagedSeerrSecretStillDecrypts() = runTest {
        val salvaged = salvageDesktopPrefs(EarlierReleaseFixtures.path("desktop-damaged/shared_preferences.json").readBytes())
        val vault = EarlierReleaseCredentialVault.from(EarlierReleasePrefs(mapOf(EarlierReleasePrefs.VAULT_KEY to StringValue(salvaged.vaultKey!!))))

        val session = vault.revealSeerrSession(salvaged.sessions.getValue("user_local-aaa_seerr_session"))!!
        assertEquals("seerr-password", session.getValue("secret").jsonPrimitive.content)
    }
}
