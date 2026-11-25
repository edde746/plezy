package com.edde746.plezy.importer

import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readByteArray
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlin.io.encoding.Base64

/**
 * Measurements of a damaged preference store's bytes: a length and two flags, never a quotation, so a report of the
 * damage can't carry the credentials the store holds.
 */
data class PrefsStoreShape(val length: Int, val validUtf8: Boolean, val allZero: Boolean) {
    override fun toString(): String =
        "$length bytes, ${if (validUtf8) "valid" else "invalid"} UTF-8${if (allZero) ", every byte zero" else ""}"
}

/**
 * The desktop preference store exists but isn't a document Plezy's earlier releases could read. It keeps neither the
 * document nor the parser's error (whose message quotes the document), only [shape].
 */
class CorruptPreferenceStoreException(val shape: PrefsStoreShape, reason: String) :
    IllegalStateException("The preference store could not be parsed ($reason; $shape)")

/**
 * Reads the Windows/Linux store, `shared_preferences.json` in Plezy's support directory: one flat JSON object holding
 * bare and `flutter.`-prefixed keys. The release that wrote it stages writes in `shared_preferences.json.tmp` and
 * renames; a `.tmp` left behind is an unfinished write the canonical file supersedes, so only [file] is read.
 *
 * Null when the file doesn't exist; an empty file is a first launch, an empty store. Throws
 * [CorruptPreferenceStoreException] for damage ([decodeDesktopPrefs]); a file that can't be read throws its I/O error,
 * since that isn't damage a repair could fix.
 */
fun readDesktopEarlierReleasePrefs(file: String): EarlierReleasePrefs? {
    val bytes = readFileOrNull(file) ?: return null
    return EarlierReleasePrefs.resolve(decodeDesktopPrefs(bytes))
}

/** The bytes of the file at [path], or null if there is none. */
internal fun readFileOrNull(path: String): ByteArray? {
    val file = Path(path)
    if (!SystemFileSystem.exists(file)) return null
    return SystemFileSystem.source(file).buffered().use { it.readByteArray() }
}

/**
 * The entries of a desktop store's [bytes], keys as stored. The bytes must be strict UTF-8 (a leading byte-order mark
 * is skipped) holding a JSON object whose values are each a bool, number, string or list of strings; anything else,
 * a `null` value included, throws [CorruptPreferenceStoreException]. A JSON number with a fraction or exponent is a
 * double (the writer kept `100.0`'s `.0`), any other an int.
 */
fun decodeDesktopPrefs(bytes: ByteArray): Map<String, EarlierReleasePrefValue> {
    val shape = PrefsStoreShape(
        length = bytes.size,
        validUtf8 = runCatching { bytes.decodeToString(throwOnInvalidSequence = true) }.isSuccess,
        allZero = bytes.isNotEmpty() && bytes.all { it == 0.toByte() },
    )
    if (!shape.validUtf8) throw CorruptPreferenceStoreException(shape, "not UTF-8")
    val text = bytes.decodeToString().removePrefix("\uFEFF")
    if (text.isEmpty()) return emptyMap()
    // kotlinx's SerializationException is an IllegalArgumentException; its message quotes the document, so it's dropped.
    val document = try {
        parseStrictJson(text)
    } catch (_: IllegalArgumentException) {
        throw CorruptPreferenceStoreException(shape, "not JSON")
    }
    if (document !is JsonObject) throw CorruptPreferenceStoreException(shape, "not a JSON object")
    return document.mapValues { (_, value) ->
        prefValue(value) ?: throw CorruptPreferenceStoreException(shape, "a value of an unsupported type")
    }
}

private fun prefValue(value: JsonElement): EarlierReleasePrefValue? = when (value) {
    is JsonNull -> null
    is JsonPrimitive -> when {
        value.isString -> EarlierReleasePrefValue.StringValue(value.content)
        else -> dartBool(value)?.let { EarlierReleasePrefValue.BoolValue(it) }
            ?: when (val number = dartNumber(value)) {
                is Long -> EarlierReleasePrefValue.LongValue(number)
                is Double -> EarlierReleasePrefValue.DoubleValue(number)
                else -> null
            }
    }
    is JsonArray -> if (value.all { it is JsonPrimitive && it !is JsonNull && it.isString }) {
        EarlierReleasePrefValue.StringListValue(value.map { (it as JsonPrimitive).content })
    } else {
        null
    }
    is JsonObject -> null
}

/**
 * Credentials lifted out of a damaged desktop store: the vault key, checked to be base64 of 32 bytes, and session
 * entries (key → stored value) that decode with their format. [losses] counts credential entries found but unusable.
 */
class SalvagedCredentials(val vaultKey: String?, val sessions: Map<String, String>, val losses: Int) {
    override fun toString(): String = "SalvagedCredentials(vaultKey=${vaultKey != null}, sessions=${sessions.keys}, losses=$losses)"
}

/**
 * Salvages credentials from a desktop store [decodeDesktopPrefs] rejected, as the earlier releases' repair did. A
 * damaged store is usually cut short, so entries before the cut survive verbatim: every `"key":"value"` pair is
 * matched on the bytes (decoded leniently), unescaped and validated. Only credential keys count: the vault key, the
 * legacy `plex_token` and the tracker and Seerr sessions, bare or `user_<scope>_`-scoped. A `flutter.`-prefixed entry
 * is filed under its bare key, and a bare entry wins over it wherever each appears.
 */
fun salvageDesktopPrefs(bytes: ByteArray): SalvagedCredentials {
    var vaultKey: String? = null
    var vaultKeyLegacy = false
    val sessions = LinkedHashMap<String, String>()
    val sessionLegacy = HashMap<String, Boolean>()
    var losses = 0
    for ((rawKey, rawValue) in stringEntries(bytes.decodeToString())) {
        val storedKey = unescapeJsonString(rawKey) ?: continue
        val legacy = storedKey.startsWith(EarlierReleasePrefs.LEGACY_PREFIX)
        val key = storedKey.removePrefix(EarlierReleasePrefs.LEGACY_PREFIX)
        if (!isCredentialKey(key)) continue
        val value = unescapeJsonString(rawValue)
        if (key == EarlierReleasePrefs.VAULT_KEY) {
            if (value == null || !isVaultKey(value)) {
                losses++
            } else if (vaultKey == null || (vaultKeyLegacy && !legacy)) {
                vaultKey = value
                vaultKeyLegacy = legacy
            }
            continue
        }
        // The legacy Plex token is opaque: being non-empty is all there is to check.
        if (value.isNullOrEmpty() || !(key == LEGACY_PLEX_TOKEN || isValidSession(key, value))) {
            losses++
            continue
        }
        if (key !in sessions || (sessionLegacy[key] == true && !legacy)) {
            sessions[key] = value
            sessionLegacy[key] = legacy
        }
    }
    return SalvagedCredentials(vaultKey, sessions, losses)
}

private const val LEGACY_PLEX_TOKEN = "plex_token"
private val TRACKER_SESSION_KEYS = listOf("mal_session", "anilist_session", "simkl_session", "trakt_session", "mdblist_session")
private const val SEERR_SESSION_KEY = "seerr_session"
private val SCOPED_CREDENTIAL = Regex("^(?:user_.+_)?(?:${(TRACKER_SESSION_KEYS + SEERR_SESSION_KEY).joinToString("|")})$")
private val SEERR_METHODS = setOf("plex", "jellyfin", "emby", "local", "quickConnect")

private fun isCredentialKey(key: String): Boolean =
    key == EarlierReleasePrefs.VAULT_KEY || key == LEGACY_PLEX_TOKEN || credentialBaseKey(key) != null

/** The session slot [key] is, bare or scoped (`user_<scope>_trakt_session` → `trakt_session`). */
private fun credentialBaseKey(key: String): String? {
    if (!SCOPED_CREDENTIAL.matches(key)) return null
    return (TRACKER_SESSION_KEYS + SEERR_SESSION_KEY).firstOrNull { key == it || key.endsWith("_$it") }
}

/** The earlier releases' vault key: base64 of exactly 32 bytes. */
internal fun isVaultKey(value: String): Boolean =
    value.isNotEmpty() && runCatching { decodeDartBase64(value).size == 32 }.getOrDefault(false)

/** Dart's `base64Decode`: either alphabet, padding optional. */
internal fun decodeDartBase64(value: String): ByteArray =
    Base64.withPadding(Base64.PaddingOption.PRESENT_OPTIONAL).decode(value.replace('-', '+').replace('_', '/'))

/** Whether [value] decodes as the session format of [key]'s slot, with that format's required fields. */
private fun isValidSession(key: String, value: String): Boolean {
    val json = runCatching { parseStrictJson(value) }.getOrNull() as? JsonObject ?: return false
    fun string(name: String) = (json[name] as? JsonPrimitive)?.takeIf { it.isString && it !is JsonNull }?.content
    fun isNumber(name: String) = (json[name] as? JsonPrimitive)?.let { dartNumber(it) } != null
    fun isAbsent(name: String) = json[name] == null || json[name] is JsonNull
    fun stringOrAbsent(name: String) = isAbsent(name) || string(name) != null
    fun numberOrAbsent(name: String) = isAbsent(name) || isNumber(name)
    val base = credentialBaseKey(key) ?: return false
    if (base == SEERR_SESSION_KEY) {
        return string("base_url") != null && string("method") in SEERR_METHODS && isNumber("user_id") &&
            listOf("identifier", "secret", "cookie", "display_name", "instance_label").all(::stringOrAbsent) &&
            numberOrAbsent("permissions") && numberOrAbsent("created_at")
    }
    val accessToken = string("access_token") ?: return false
    if (!stringOrAbsent("refresh_token") || !numberOrAbsent("expires_at") || !stringOrAbsent("username") || !isNumber("created_at")) {
        return false
    }
    val refreshable = !string("refresh_token").isNullOrEmpty()
    val expires = isNumber("expires_at")
    return when (base) {
        "mal_session", "trakt_session", "mdblist_session" -> refreshable && expires
        "anilist_session" -> expires
        // Simkl's current tokens refresh and expire; its first-generation ones (no `simkl_at_` prefix) do neither.
        else -> !accessToken.startsWith("simkl_at_") || (refreshable && expires)
    }
}

/** The raw (still escaped) halves of every `"key" : "value"` pair in [text], left to right, as a scan finds them. */
private fun stringEntries(text: String): List<Pair<String, String>> {
    val entries = ArrayList<Pair<String, String>>()
    var start = 0
    while (start < text.length) {
        val quote = text.indexOf('"', start)
        if (quote < 0) break
        val key = stringLiteralEnd(text, quote)
        var next = key?.let { skipWhitespace(text, it + 1) }
        var value: Int? = null
        if (next != null && next < text.length && text[next] == ':') {
            next = skipWhitespace(text, next + 1)
            if (next < text.length && text[next] == '"') value = stringLiteralEnd(text, next)
        }
        if (key != null && value != null) {
            entries += text.substring(quote + 1, key) to text.substring(next!! + 1, value)
            start = value + 1
        } else {
            start = quote + 1
        }
    }
    return entries
}

/** The index of the quote closing the string literal opened at [open], or null if it never closes. */
private fun stringLiteralEnd(text: String, open: Int): Int? {
    var i = open + 1
    while (i < text.length) {
        when (text[i]) {
            '"' -> return i
            '\\' -> {
                if (i + 1 >= text.length || text[i + 1] in "\n\r\u2028\u2029") return null
                i += 2
            }
            else -> i++
        }
    }
    return null
}

private fun skipWhitespace(text: String, from: Int): Int {
    var i = from
    while (i < text.length && text[i].isWhitespace()) i++
    return i
}

private fun unescapeJsonString(raw: String): String? {
    if (raw.any { it < ' ' }) return null
    val parsed = runCatching { parseStrictJson("\"$raw\"") }.getOrNull() as? JsonPrimitive ?: return null
    return parsed.takeIf { it.isString }?.content
}
