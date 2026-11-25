package com.edde746.plezy.importer

import com.edde746.plezy.crypto.cryptoProvider
import dev.whyoleg.cryptography.DelicateCryptographyApi
import dev.whyoleg.cryptography.algorithms.AES
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject

/**
 * Decrypts the credentials Plezy's earlier releases stored encrypted: `enc:v1:` followed by the JSON
 * `{"n": nonce, "c": ciphertext, "m": tag}` (standard base64), AES-256-GCM with a 12-byte nonce, a 16-byte tag and no
 * associated data, under the key in the `credential_vault_key_v1` preference. Values without the prefix are older
 * plaintext ones and pass through.
 *
 * A value that won't decrypt (another key, a damaged payload, no key at all) is a lost credential: [reveal] returns
 * null rather than failing, and the account signs in again.
 */
class EarlierReleaseCredentialVault(key: ByteArray?) {
    private val key: ByteArray? = key?.takeIf { it.size == 32 }

    /** [value] decrypted, [value] itself if it isn't encrypted, or null if it won't decrypt. */
    @OptIn(DelicateCryptographyApi::class)
    suspend fun reveal(value: String): String? {
        if (!value.startsWith(PREFIX)) return value
        val key = key ?: return null
        return try {
            val payload = parseStrictJson(value.removePrefix(PREFIX)) as JsonObject
            fun field(name: String) = decodeDartBase64((payload.getValue(name) as JsonPrimitive).also { require(it.isString) }.content)
            val nonce = field("n")
            val ciphertext = field("c")
            val tag = field("m")
            require(nonce.size == 12 && tag.size == 16) { "Not an AES-GCM payload" }
            val aes = cryptoProvider.get(AES.GCM).keyDecoder().decodeFromByteArray(AES.Key.Format.RAW, key)
            aes.cipher().decryptWithIv(nonce, ciphertext + tag).decodeToString(throwOnInvalidSequence = true)
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            // Wrong key, a failed tag check or a malformed payload: the credential is lost, never a crash.
            null
        }
    }

    /**
     * A connection's `config_json` with its tokens decrypted: `accountToken` and each `servers[].accessToken` for
     * kind `plex`, `accessToken` for `jellyfin` and `emby`. A token that won't decrypt becomes `""`, the shape of a
     * connection that must sign in again; empty tokens and other kinds' fields stay as they are.
     */
    suspend fun revealConnectionConfig(kind: String, config: JsonObject): JsonObject {
        val tokenKey = when (kind) {
            "plex" -> "accountToken"
            "jellyfin", "emby" -> "accessToken"
            else -> return config
        }
        val revealed = LinkedHashMap(config)
        revealToken(config[tokenKey])?.let { revealed[tokenKey] = it }
        val servers = config["servers"]
        if (kind == "plex" && servers is JsonArray) {
            revealed["servers"] = JsonArray(
                servers.map { server ->
                    if (server !is JsonObject) return@map server
                    val token = revealToken(server["accessToken"]) ?: return@map server
                    JsonObject(LinkedHashMap(server).apply { put("accessToken", token) })
                },
            )
        }
        return JsonObject(revealed)
    }

    /**
     * A stored Seerr session (the `seerr_session` preference, bare or profile-scoped) with its `secret`, the
     * password, decrypted; `""` if it won't decrypt. Null if [stored] isn't a JSON object, a session the earlier
     * releases dropped too.
     */
    suspend fun revealSeerrSession(stored: String): JsonObject? {
        val session = runCatching { parseStrictJson(stored) }.getOrNull() as? JsonObject ?: return null
        val secret = revealToken(session["secret"]) ?: return session
        return buildJsonObject {
            for ((name, value) in session) put(name, if (name == "secret") secret else value)
        }
    }

    /** A non-empty string token decrypted (`""` when it won't); null when [token] isn't one, leaving it as is. */
    private suspend fun revealToken(token: JsonElement?): JsonPrimitive? {
        if (token !is JsonPrimitive || token is JsonNull || !token.isString || token.content.isEmpty()) return null
        return JsonPrimitive(reveal(token.content) ?: "")
    }

    companion object {
        const val PREFIX = "enc:v1:"

        /** The vault keyed by [prefs]' `credential_vault_key_v1`; without a usable key every encrypted value is lost. */
        fun from(prefs: EarlierReleasePrefs): EarlierReleaseCredentialVault =
            EarlierReleaseCredentialVault(prefs.string(EarlierReleasePrefs.VAULT_KEY)?.let { runCatching { decodeDartBase64(it) }.getOrNull() })
    }
}
