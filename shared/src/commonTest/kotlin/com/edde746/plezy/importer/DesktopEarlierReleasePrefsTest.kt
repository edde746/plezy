package com.edde746.plezy.importer

import com.edde746.plezy.importer.EarlierReleasePrefValue.DoubleValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.LongValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringListValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringValue
import kotlin.io.encoding.Base64
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DesktopEarlierReleasePrefsTest {
    private val vaultKey = Base64.encode(ByteArray(32) { it.toByte() })
    private val traktSession =
        """{"access_token":"trakt-access-token","refresh_token":"trakt-refresh-token","expires_at":4102444800,"username":"someone","created_at":1700000000}"""
    private val seerrSession =
        """{"base_url":"https://seerr.example.com","method":"local","identifier":"user@example.com","secret":"enc:v1:{\"c\":\"AA==\",\"n\":\"AA==\",\"m\":\"AA==\"}","cookie":"seerr-connect-sid","user_id":1,"permissions":2,"display_name":"Someone","instance_label":"Seerr","created_at":1700000000}"""

    private fun entry(key: String, value: String) = "${quote(key)}:${quote(value)}"

    private fun quote(value: String) = "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

    @Test
    fun readsAWellFormedDocument() {
        val entries = decodeDesktopPrefs("""{"theme":"dark","count":3,"volume":100.0,"list":["a"]}""".encodeToByteArray())

        assertEquals(
            mapOf("theme" to StringValue("dark"), "count" to LongValue(3), "volume" to DoubleValue(100.0), "list" to StringListValue(listOf("a"))),
            entries,
        )
    }

    @Test
    fun anEmptyStoreIsAFirstLaunch() {
        assertEquals(emptyMap(), decodeDesktopPrefs(ByteArray(0)))
    }

    @Test
    fun aByteOrderMarkIsSkipped() {
        val bytes = byteArrayOf(0xEF.toByte(), 0xBB.toByte(), 0xBF.toByte()) + """{"theme":"dark"}""".encodeToByteArray()

        assertEquals(mapOf("theme" to StringValue("dark")), decodeDesktopPrefs(bytes))
    }

    @Test
    fun rejectsDamagedDocuments() {
        for (document in listOf("""{"theme":"dark"""", """{"theme":"dark","broken":null}""", "[1,2,3]", "   \n", """{"a":yes}""", """{"a":{"b":1}}""", """{"a":["x",1]}""")) {
            assertFailsWith<CorruptPreferenceStoreException>(document) { decodeDesktopPrefs(document.encodeToByteArray()) }
        }
    }

    @Test
    fun anAllZeroDocumentIsDamageWithItsShape() {
        val damage = assertFailsWith<CorruptPreferenceStoreException> { decodeDesktopPrefs(ByteArray(64)) }

        assertEquals(PrefsStoreShape(length = 64, validUtf8 = true, allZero = true), damage.shape)
        assertTrue(damage.message!!.contains("every byte zero"))
    }

    @Test
    fun bytesThatAreNotUtf8AreDamage() {
        val damage = assertFailsWith<CorruptPreferenceStoreException> {
            decodeDesktopPrefs(byteArrayOf(0xFF.toByte(), 0xFE.toByte()) + """{"theme":"dark"}""".encodeToByteArray())
        }

        assertFalse(damage.shape.validUtf8)
    }

    @Test
    fun theDamageNeverQuotesTheDocument() {
        val document = "{" + entry(EarlierReleasePrefs.VAULT_KEY, vaultKey) + ",\"broken\":"
        val damage = assertFailsWith<CorruptPreferenceStoreException> { decodeDesktopPrefs(document.encodeToByteArray()) }

        assertFalse(damage.message!!.contains(vaultKey))
        assertNull(damage.cause)
    }

    @Test
    fun salvagesTheVaultKeyFromATruncatedDocument() {
        val raw = "{\"theme\":\"dark\",${entry(EarlierReleasePrefs.VAULT_KEY, vaultKey)},\"library_den"

        assertEquals(vaultKey, salvageDesktopPrefs(raw.encodeToByteArray()).vaultKey)
    }

    @Test
    fun aVaultKeyThatIsNot32BytesIsLost() {
        val salvaged = salvageDesktopPrefs("{${entry(EarlierReleasePrefs.VAULT_KEY, Base64.encode(ByteArray(16) { 7 }))}}".encodeToByteArray())

        assertNull(salvaged.vaultKey)
        assertEquals(1, salvaged.losses)
    }

    @Test
    fun salvagesProfileScopedTrackerAndSeerrSessions() {
        val raw = "{${entry("user_abc_trakt_session", traktSession)},${entry("user_abc_seerr_session", seerrSession)},\"theme\":\"dark\"}"

        val salvaged = salvageDesktopPrefs(raw.encodeToByteArray())

        assertEquals(setOf("user_abc_trakt_session", "user_abc_seerr_session"), salvaged.sessions.keys)
        assertEquals(traktSession, salvaged.sessions["user_abc_trakt_session"])
        assertEquals(0, salvaged.losses)
    }

    @Test
    fun anUndecodableSessionIsLostRatherThanSalvaged() {
        val salvaged = salvageDesktopPrefs("{${entry("trakt_session", "{\"access_token\":\"only-half")}}".encodeToByteArray())

        assertEquals(emptyMap(), salvaged.sessions)
        assertEquals(1, salvaged.losses)
    }

    @Test
    fun aTrackerSessionWithoutItsRequiredFieldsIsLost() {
        // Trakt sessions refresh and expire; one without a refresh token can't be kept.
        val salvaged = salvageDesktopPrefs("{${entry("trakt_session", """{"access_token":"a","created_at":1}""")}}".encodeToByteArray())

        assertEquals(1, salvaged.losses)
    }

    @Test
    fun filesALegacyPrefixedKeyUnderItsBareKey() {
        val raw = "{${entry("flutter.trakt_session", traktSession)},${entry("flutter.${EarlierReleasePrefs.VAULT_KEY}", vaultKey)}}"

        val salvaged = salvageDesktopPrefs(raw.encodeToByteArray())

        assertEquals(vaultKey, salvaged.vaultKey)
        assertEquals(setOf("trakt_session"), salvaged.sessions.keys)
    }

    @Test
    fun theBareEntryWinsOverTheLegacyOneInEitherOrder() {
        val legacy = entry("flutter.trakt_session", traktSession.replace("trakt-access-token", "legacy-access"))
        val current = entry("trakt_session", traktSession.replace("trakt-access-token", "current-access"))
        for (raw in listOf("{$legacy,$current}", "{$current,$legacy}")) {
            assertTrue(salvageDesktopPrefs(raw.encodeToByteArray()).sessions.getValue("trakt_session").contains("current-access"))
        }
    }

    @Test
    fun salvagesBehindALeadingNul() {
        val bytes = byteArrayOf(0) + "{${entry(EarlierReleasePrefs.VAULT_KEY, vaultKey)}}".encodeToByteArray()

        assertFailsWith<CorruptPreferenceStoreException> { decodeDesktopPrefs(bytes) }
        assertEquals(vaultKey, salvageDesktopPrefs(bytes).vaultKey)
    }

    @Test
    fun keepsTheLegacyPlexTokenAsItIs() {
        assertEquals(mapOf("plex_token" to "opaque"), salvageDesktopPrefs("{\"plex_token\":\"opaque\"}".encodeToByteArray()).sessions)
    }
}
