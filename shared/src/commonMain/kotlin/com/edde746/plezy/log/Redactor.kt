package com.edde746.plezy.log

/**
 * Removes secrets from free text before it is logged, and from crash reports' text (`CrashReports.scrub`, which every
 * platform's crash reporter runs on each report before it is sent). Every secret becomes [MARK].
 *
 * - **Registered values first** ([LogRedaction]'s registry): the tokens, server URLs and other secrets the app knows by
 *   value, wherever they appear.
 * - **Every URL is a secret beyond its origin.** Media server URLs carry access tokens in their queries, and stream
 *   URLs are signed or keyed. A URL keeps its scheme and host; userinfo, path, query and fragment become [MARK]:
 *   `https://server.example/…`. A URL runs to the next space,
 *   `"`, `<`, `>` or `\`: an apostrophe is part of it (file names in stream URLs carry them, `Night's.Journey.mkv`)
 *   unless it ends it, as in mpv's and FFmpeg's quoted `'<url>'`. A peer-to-peer link keeps only its scheme.
 * - **Key shapes in any text**: `key=value` pairs whose name marks a credential (`apikey`, `token`, `account_key`,
 *   …), a `name=value` pair whose value has an API key's shape (16 or more letters and digits, with both), bearer/basic
 *   authorization values, JWTs, UUIDs, 52-character capitals-and-digits API keys, long hex strings and other long
 *   letter-and-digit tokens.
 * - **Then the media-server shapes** ([LogRedaction]): IPv4 addresses, plex.direct server hashes and the credential
 *   fields media servers use.
 *
 * Redaction errs towards removing too much: a log line without a harmless id is better than a leaked key.
 */
object Redactor {
    /** What replaces a secret. */
    const val MARK = "…"

    private val URL = Regex("""\b([A-Za-z][A-Za-z0-9+.\-]*)://([^\s"<>\\]*)""")
    private val PEER_TO_PEER_LINK = Regex("""\bmagnet:\?[^\s"'<>]*""", RegexOption.IGNORE_CASE)

    private const val CREDENTIAL_NAMES =
        "api[_-]?key|apikey|access[_-]?token|refresh[_-]?token|auth[_-]?token|token|secret|password|passwd|pass|" +
            "key|auth|session|sid|[a-z0-9]+[_-](?:key|token)"

    /** `name=value` / `name: value` / `"name":"value"` with a credential-like name; the value is replaced. */
    private val CREDENTIAL_PAIR = Regex(
        """(?i)(["']?\b(?:$CREDENTIAL_NAMES)\b["']?\s*[:=]\s*["']?)([^\s"'&|,;}\]]+)""",
    )

    /** `name=value` whose value has an API key's shape: 16 or more letters and digits, with at least one of each. */
    private val KEYED_PAIR = Regex("""(\b[A-Za-z][A-Za-z0-9_\-]*=)(?=[A-Za-z0-9]*[0-9])(?=[A-Za-z0-9]*[A-Za-z])[A-Za-z0-9]{16,}\b""")

    private val AUTHORIZATION = Regex("""(?i)\b(bearer|basic)\s+[A-Za-z0-9._~+/\-]+=*""")

    private val JWT = Regex("""\beyJ[A-Za-z0-9_\-]{8,}\.[A-Za-z0-9_\-]{8,}\.[A-Za-z0-9_\-]{8,}""")
    private val UUID = Regex("""\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b""")
    private val CAPITALS_TOKEN = Regex("""\b[A-Z0-9]{52}\b""")
    private val LONG_HEX = Regex("""\b[0-9a-fA-F]{32,}\b""")
    private val LONG_TOKEN =
        Regex("""\b(?=[A-Za-z0-9_\-]*[0-9])(?=[A-Za-z0-9_\-]*[A-Z])(?=[A-Za-z0-9_\-]*[a-z])[A-Za-z0-9_\-]{28,}\b""")

    fun redact(text: String): String {
        var out = LogRedaction.redactLiterals(text)
        out = URL.replace(out) { m -> redactUrl(m.groupValues[1], m.groupValues[2]) }
        out = PEER_TO_PEER_LINK.replace(out, "magnet:$MARK")
        out = AUTHORIZATION.replace(out) { m -> m.groupValues[1] + " " + MARK }
        out = CREDENTIAL_PAIR.replace(out) { m -> m.groupValues[1] + MARK }
        out = KEYED_PAIR.replace(out) { m -> m.groupValues[1] + MARK }
        for (shape in listOf(JWT, UUID, CAPITALS_TOKEN, LONG_HEX, LONG_TOKEN)) out = shape.replace(out, MARK)
        return LogRedaction.redactShapes(out)
    }

    /**
     * Keeps prose punctuation and a closing quote that follow a URL (`(see https://x/y).`, `'https://x/y'`) outside
     * the redacted part.
     */
    private fun redactUrl(scheme: String, match: String): String {
        val rest = match.trimEnd { it in TRAILING_PUNCTUATION }
        return redactUrlParts(scheme, rest) + match.substring(rest.length)
    }

    private const val TRAILING_PUNCTUATION = ").,;:!?]}'"

    private fun redactUrlParts(scheme: String, rest: String): String {
        val authorityEnd = rest.indexOfAny(charArrayOf('/', '?', '#')).let { if (it < 0) rest.length else it }
        val host = rest.substring(0, authorityEnd).substringAfterLast('@')
        val hidden = authorityEnd < rest.length && rest.substring(authorityEnd) != "/" ||
            '@' in rest.substring(0, authorityEnd)
        return "$scheme://$host" + if (hidden) "/$MARK" else rest.substring(authorityEnd)
    }
}
