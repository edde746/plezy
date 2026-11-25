package com.edde746.plezy.plex

import kotlin.random.Random

/** The product name every Plex request names. */
const val PLEX_PRODUCT = "Plezy"

/** The library provider identifier of Plex's own media library. */
const val PLEX_LIBRARY_IDENTIFIER = "com.plexapp.plugins.library"

/**
 * [value] reduced to what an HTTP header carries: Latin letters without a decomposition folded to ASCII (æ → ae,
 * ß → ss, ø → o, …), accents removed (NFD, then every code unit outside 0x20–0x7E dropped), trimmed; null when nothing
 * is left. Plex shows the device name as the session's player, so it must survive the header.
 */
fun sanitizeHeaderValue(value: String?): String? {
    if (value == null) return null
    val folded = buildString(value.length) {
        for (c in value) append(NON_DECOMPOSABLE_LATIN[c] ?: c)
    }
    val ascii = buildString(folded.length) {
        for (c in canonicalDecomposition(folded)) if (c.code in 0x20..0x7E) append(c)
    }.trim()
    return ascii.ifEmpty { null }
}

/** NFD of [value]. */
internal expect fun canonicalDecomposition(value: String): String

private val NON_DECOMPOSABLE_LATIN: Map<Char, String> = mapOf(
    'æ' to "ae", 'Æ' to "AE", 'œ' to "oe", 'Œ' to "OE", 'ø' to "o", 'Ø' to "O", 'ß' to "ss",
    'đ' to "d", 'Đ' to "D", 'ð' to "d", 'Ð' to "D", 'þ' to "th", 'Þ' to "Th", 'ł' to "l", 'Ł' to "L",
    'ħ' to "h", 'Ħ' to "H", 'ı' to "i", 'ŧ' to "t", 'Ŧ' to "T",
)

/**
 * A transient session handle: 24 characters of `[a-z0-9]`, the shape Plex's own clients send as
 * `X-Plex-Session-Identifier` (Jellyfin takes it as an opaque `PlaySessionId`).
 */
fun generateSessionIdentifier(random: Random = Random.Default): String {
    val chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    return CharArray(24) { chars[random.nextInt(chars.length)] }.concatToString()
}

/** [url] with `X-Plex-Token` appended (`?` or `&`); unchanged for a null or empty token. */
fun withPlexToken(url: String, token: String?): String {
    if (token.isNullOrEmpty()) return url
    val separator = if ('?' in url) '&' else '?'
    return "$url${separator}X-Plex-Token=$token"
}
