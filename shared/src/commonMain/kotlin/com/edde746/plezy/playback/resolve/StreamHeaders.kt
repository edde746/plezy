package com.edde746.plezy.playback.resolve

/**
 * A stream's request headers for the player (mpv's `http-header-fields`), cleaned once ([sanitize]):
 * - names are trimmed and must be RFC 9110 tokens (ASCII); values are trimmed and may hold only tabs and printable
 *   ASCII: a CR or LF would inject header lines, and OkHttp (Android, Windows, Linux) refuses any other character
 *   with an exception that fails the whole request. A header that breaks either rule is dropped;
 * - framing and routing headers are dropped: a fixed `Range` would break seeking, `Host` would break the CDN host a
 *   link redirects to, and the HTTP stack owns the rest;
 * - names are unique case-insensitively (the last one wins), and `User-Agent` is spelled canonically, so a player
 *   that sets its own agent can look it up.
 */
internal object StreamHeaders {
    const val USER_AGENT = "User-Agent"

    private val dropped = setOf(
        "host", "range", "content-length", "transfer-encoding", "connection", "upgrade", "keep-alive", "te",
        "trailer", "proxy-connection",
    )

    fun sanitize(headers: Map<String, String>): Map<String, String> {
        val byLowercaseName = LinkedHashMap<String, Pair<String, String>>()
        for ((rawName, rawValue) in headers) {
            val name = rawName.trim()
            val value = rawValue.trim()
            if (!name.isToken() || value.any { it != '\t' && it !in ' '..'~' }) continue
            val key = name.lowercase()
            if (key in dropped) continue
            byLowercaseName.remove(key)
            byLowercaseName[key] = (if (key == "user-agent") USER_AGENT else name) to value
        }
        return byLowercaseName.values.associate { it }
    }

    private fun String.isToken() = isNotEmpty() && all { it.isLetterOrDigit() && it.code < 128 || it in TOKEN_SYMBOLS }

    private const val TOKEN_SYMBOLS = "!#$%&'*+-.^_`|~"
}
