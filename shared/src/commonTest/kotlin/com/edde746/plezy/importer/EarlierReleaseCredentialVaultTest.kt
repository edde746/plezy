package com.edde746.plezy.importer

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

// The vectors were encrypted by an independent AES-GCM implementation (tools/earlier-release-fixtures).
class EarlierReleaseCredentialVaultTest {
    private val vault = EarlierReleaseCredentialVault.from(
        EarlierReleasePrefs(mapOf(EarlierReleasePrefs.VAULT_KEY to EarlierReleasePrefValue.StringValue(EarlierReleaseFixtureVectors.VAULT_KEY))),
    )

    @Test
    fun revealsAProtectedValue() = runTest {
        assertEquals("super-secret", vault.reveal(EarlierReleaseFixtureVectors.PROTECTED_SECRET))
        assertEquals("tökén ✓", vault.reveal(EarlierReleaseFixtureVectors.PROTECTED_UNICODE))
    }

    @Test
    fun returnsUnprotectedValuesUnchanged() = runTest {
        assertEquals("plaintext-token", vault.reveal("plaintext-token"))
    }

    @Test
    fun returnsNullOnATamperedTag() = runTest {
        assertNull(vault.reveal(EarlierReleaseFixtureVectors.TAMPERED_MAC))
    }

    @Test
    fun returnsNullOnACorruptPayload() = runTest {
        assertNull(vault.reveal("enc:v1:not-json"))
        assertNull(vault.reveal("enc:v1:{\"n\":\"!!\",\"c\":\"!!\",\"m\":\"!!\"}"))
        assertNull(vault.reveal("enc:v1:{\"n\":\"AAAA\"}"))
    }

    @Test
    fun returnsNullWhenTheKeyDivergedFromTheCiphertext() = runTest {
        assertNull(vault.reveal(EarlierReleaseFixtureVectors.PROTECTED_UNDER_OTHER_KEY))
    }

    @Test
    fun withoutAKeyEveryProtectedValueIsLost() = runTest {
        val keyless = EarlierReleaseCredentialVault.from(EarlierReleasePrefs(emptyMap()))

        assertNull(keyless.reveal(EarlierReleaseFixtureVectors.PROTECTED_SECRET))
        assertEquals("plaintext-token", keyless.reveal("plaintext-token"))
    }

    @Test
    fun revealsPlexAccountAndServerTokens() = runTest {
        val config = vault.revealConnectionConfig("plex", parseStrictJson(EarlierReleaseFixtureVectors.PLEX_CONFIG).jsonObject)

        assertEquals("plex-account-token", config.getValue("accountToken").jsonPrimitive.content)
        val servers = config.getValue("servers") as JsonArray
        assertEquals(
            listOf("plex-server-token-1", "plaintext-plex-server-token-2"),
            servers.map { it.jsonObject.getValue("accessToken").jsonPrimitive.content },
        )
        assertEquals("plezy-client-1", config.getValue("clientIdentifier").jsonPrimitive.content)
    }

    @Test
    fun mapsAnUndecryptableTokenToTheEmptyString() = runTest {
        val config = vault.revealConnectionConfig("jellyfin", parseStrictJson(EarlierReleaseFixtureVectors.LOST_CONFIG).jsonObject)

        assertEquals("", config.getValue("accessToken").jsonPrimitive.content)
        assertEquals("user-2", config.getValue("userId").jsonPrimitive.content)
    }

    @Test
    fun mapsUndecryptablePlexTokensToTheEmptyString() = runTest {
        val lost = EarlierReleaseFixtureVectors.PROTECTED_UNDER_OTHER_KEY
        val config = vault.revealConnectionConfig(
            "plex",
            JsonObject(
                mapOf(
                    "accountToken" to JsonPrimitive(lost),
                    "servers" to JsonArray(listOf(JsonObject(mapOf("accessToken" to JsonPrimitive(lost))))),
                ),
            ),
        )

        assertEquals("", config.getValue("accountToken").jsonPrimitive.content)
        assertEquals("", (config.getValue("servers") as JsonArray).single().jsonObject.getValue("accessToken").jsonPrimitive.content)
    }

    @Test
    fun leavesOtherKindsAlone() = runTest {
        val config = JsonObject(mapOf("accessToken" to JsonPrimitive(EarlierReleaseFixtureVectors.PROTECTED_SECRET)))

        assertEquals(config, vault.revealConnectionConfig("unknown", config))
    }

    @Test
    fun revealsTheSeerrSecret() = runTest {
        val session = vault.revealSeerrSession(EarlierReleaseFixtureVectors.SEERR_SESSION)!!

        assertEquals("seerr-password", session.getValue("secret").jsonPrimitive.content)
        assertEquals("connect.sid=s%3Afixture", session.getValue("cookie").jsonPrimitive.content)
        assertNull(vault.revealSeerrSession("not json"))
    }
}
