package com.edde746.plezy.log

import kotlin.concurrent.atomics.AtomicReference
import kotlin.concurrent.atomics.ExperimentalAtomicApi

/**
 * The registry of secrets the app knows by value, and the shapes media servers put secrets in: [Redactor]'s
 * media-server layer. [Redactor.redact] replaces the registered literals before anything else and runs the shapes
 * after its own URL and key shapes. Every secret becomes [Redactor.MARK].
 *
 * - **Registered literals**: each server's access token (and its URL-encoded form), each server URL (with and without
 *   its trailing slash, its origin, and mpv's `\:`-escaped echo of each), and any other secret value (a Seerr key or
 *   session cookie, a Quick Connect secret). The newest 50 tokens, 40 URLs and 50 other values are kept, the oldest
 *   dropped first; the longest literal wins where two overlap. A URL whose host is an IPv4 address isn't registered:
 *   the address masking covers it.
 * - **Shapes**: IPv4 addresses (dotted, or dashed as in `*.plex.direct` hosts) keep their first and last octet
 *   (`192.x.x.42`), a `plex.direct` host's 32-hex server hash goes, as do the MediaBrowser header's `Token="…"`, the
 *   value of a credential field (authorization, cookie, X-Plex-Token, X-Emby-Token, api_key, access/refresh/id tokens,
 *   client secret, password, secret, pin, token) in a query, header, JSON or map, and URL userinfo. Prose and fields
 *   that only contain such a word (`token_count`, `authorizationMode`) stay.
 *
 * Safe from any thread: registration swaps an immutable snapshot.
 */
@OptIn(ExperimentalAtomicApi::class)
object LogRedaction {
    private const val MARK = Redactor.MARK

    private const val MAX_TOKENS = 50

    /** Each server registers up to 8 URL literals (slash, origin, mpv-escaped), so several servers fit. */
    private const val MAX_URLS = 40
    private const val MAX_CUSTOM = 50

    /** Shorter values aren't registered: replacing every one- to three-character string would shred every log line. */
    private const val MIN_CUSTOM_LENGTH = 4

    private class Literals(val tokens: List<String>, val urls: List<String>, val custom: List<String>) {
        val pattern: Regex? = (tokens + urls + custom).distinct().sortedByDescending { it.length }
            .takeIf { it.isNotEmpty() }
            ?.joinToString("|") { Regex.escape(it) }
            ?.let(::Regex)
    }

    private val literals = AtomicReference(Literals(emptyList(), emptyList(), emptyList()))

    private val IPV4 = Regex("""\b(\d{1,3})([.-])(\d{1,3})\2(\d{1,3})\2(\d{1,3})\b""")
    private val IPV4_HOST = Regex("""^\d{1,3}([.-]\d{1,3}){3}$""")
    private val PLEX_DIRECT_HASH = Regex("""\.[0-9a-fA-F]{32}\.plex\.direct""", RegexOption.IGNORE_CASE)
    private val MEDIA_BROWSER_TOKEN = Regex("""Token="[^"]+"""", RegexOption.IGNORE_CASE)
    private val SENSITIVE_FIELD = Regex(
        """(^|[\s?&{},;\[(])(["']?)(authorization|proxy-authorization|cookie|set-cookie|x-auth-token|x-plex-token|""" +
            """x-emby-token|x-api-key|api[-_]?key|auth[-_]?token|access[-_]?token|refresh[-_]?token|id[-_]?token|""" +
            """client[-_]?secret|password|passwd|secret|pin|token)(["']?)([ \t]*[:=][ \t]*)""",
        setOf(RegexOption.IGNORE_CASE, RegexOption.MULTILINE),
    )
    private val AUTHORIZATION_SCHEME = Regex("""(?:Bearer|Basic)[ \t]+""", RegexOption.IGNORE_CASE)
    private val URL_USERINFO = Regex("""\b([a-zA-Z][a-zA-Z0-9+.-]*://)([^/@\s]+)@""")

    /** A server's or plex.tv's access token; its URL-encoded form too. */
    fun registerToken(token: String?) {
        val value = token?.trim()?.takeIf { it.isNotEmpty() } ?: return
        val encoded = encodeQueryComponent(value)
        update { it.copy(tokens = it.tokens.with(value, MAX_TOKENS).let { t -> if (encoded != value) t.with(encoded, MAX_TOKENS) else t }) }
    }

    /**
     * A server's URL in use: with and without its trailing slash, its origin, and its host name when it has a dot (a
     * resolver's or socket's error names the bare host; a dotless name could be an ordinary word).
     */
    fun registerServerUrl(url: String?) {
        val value = url?.trim()?.takeIf { it.isNotEmpty() } ?: return
        val host = hostOf(value)
        if (IPV4_HOST.matches(host ?: value)) return
        val forms = buildList {
            val stripped = value.trimEnd('/')
            if (stripped.isNotEmpty()) {
                add(stripped)
                add("$stripped/")
            }
            originOf(value)?.let(::add)
            host?.takeIf { '.' in it }?.let(::add)
        }
        update { current ->
            var urls = current.urls
            for (form in forms) {
                urls = urls.with(form, MAX_URLS)
                val escaped = form.replace(":", "\\:")
                if (escaped != form) urls = urls.with(escaped, MAX_URLS)
            }
            current.copy(urls = urls)
        }
    }

    /** A server's URL and its access token, before any request goes to it. */
    fun registerServer(url: String?, token: String?) {
        registerServerUrl(url)
        registerToken(token)
    }

    /** Any other secret value, at least [MIN_CUSTOM_LENGTH] characters once trimmed. */
    fun registerCustomValue(value: String?) {
        val normalized = value?.trim()?.takeIf { it.length >= MIN_CUSTOM_LENGTH } ?: return
        update { it.copy(custom = it.custom.with(normalized, MAX_CUSTOM)) }
    }

    /** Forgets every registered value (sign-out). */
    fun clear() {
        literals.store(Literals(emptyList(), emptyList(), emptyList()))
    }

    /** [message] with every registered literal replaced. */
    internal fun redactLiterals(message: String): String = literals.load().pattern?.replace(message, MARK) ?: message

    /** [message] with the media-server shapes replaced; runs after [redactLiterals] and [Redactor]'s own shapes. */
    internal fun redactShapes(message: String): String {
        var out = IPV4.replace(message) { m ->
            val separator = m.groupValues[2]
            "${m.groupValues[1]}${separator}x${separator}x$separator${m.groupValues[5]}"
        }
        out = PLEX_DIRECT_HASH.replace(out, ".$MARK.plex.direct")
        out = MEDIA_BROWSER_TOKEN.replace(out, "Token=\"$MARK\"")
        out = redactSensitiveFields(out)
        return URL_USERINFO.replace(out) { m -> "${m.groupValues[1]}$MARK@" }
    }

    private fun Literals.copy(tokens: List<String> = this.tokens, urls: List<String> = this.urls, custom: List<String> = this.custom) =
        Literals(tokens, urls, custom)

    private inline fun update(change: (Literals) -> Literals) {
        while (true) {
            val current = literals.load()
            if (literals.compareAndSet(current, change(current))) return
        }
    }

    /** [value] appended, the oldest dropped beyond [max]; unchanged when it is there already. */
    private fun List<String>.with(value: String, max: Int): List<String> =
        if (value in this) this else (this + value).takeLast(max)

    /** `host[:port]` of [url] without its userinfo, or null when it has no `scheme://`. */
    private fun authorityOf(url: String): String? =
        url.substringAfter("://", missingDelimiterValue = "").substringBefore('/').substringBefore('?').substringBefore('#')
            .substringAfterLast('@').ifEmpty { null }

    private fun hostOf(url: String): String? = authorityOf(url)?.substringBeforeLast(':')

    /** `scheme://host[:port]`, or null when [url] has no host. */
    private fun originOf(url: String): String? = authorityOf(url)?.let { "${url.substringBefore("://")}://$it" }

    /** As a query component: letters, digits and `-_.!~*'()` stay, a space becomes `+`, the rest `%XX` of its UTF-8. */
    private fun encodeQueryComponent(value: String): String = buildString {
        for (byte in value.encodeToByteArray()) {
            val c = byte.toInt() and 0xFF
            val ch = c.toChar()
            when {
                ch.isAsciiLetterOrDigit() || ch in "-_.!~*'()" -> append(ch)
                ch == ' ' -> append('+')
                else -> append('%').append(HEX[c shr 4]).append(HEX[c and 0xF])
            }
        }
    }

    private const val HEX = "0123456789ABCDEF"

    private fun Char.isAsciiLetterOrDigit() = this in 'a'..'z' || this in 'A'..'Z' || this in '0'..'9'

    private fun redactSensitiveFields(message: String): String {
        val result = StringBuilder()
        var cursor = 0
        var structureCursor = 0
        var braceDepth = 0
        var bracketDepth = 0
        var quotedBraceDepth = 0
        var quotedBracketDepth = 0
        var quote = 0.toChar()
        var escaped = false

        for (match in SENSITIVE_FIELD.findAll(message)) {
            val matchEnd = match.range.last + 1
            if (match.range.first < cursor || matchEnd >= message.length) continue
            val key = match.groupValues[3].lowercase()
            val valueStart = matchEnd
            if (message.startsWith(MARK, valueStart)) continue

            while (structureCursor < valueStart) {
                val character = message[structureCursor]
                if (quote != 0.toChar()) {
                    if (!escaped && character == quote) {
                        quote = 0.toChar()
                        quotedBraceDepth = 0
                        quotedBracketDepth = 0
                    } else if (!escaped && character == '{') {
                        quotedBraceDepth++
                    } else if (!escaped && character == '[') {
                        quotedBracketDepth++
                    } else if (!escaped && character == '}' && quotedBraceDepth > 0) {
                        quotedBraceDepth--
                    } else if (!escaped && character == ']' && quotedBracketDepth > 0) {
                        quotedBracketDepth--
                    }
                    escaped = !escaped && character == '\\'
                    structureCursor++
                    continue
                }
                val opensQuote = character == '"' ||
                    (character == '\'' && (structureCursor == 0 || message[structureCursor - 1].isLogWhitespace() || message[structureCursor - 1] in "(,:;=[{"))
                when {
                    opensQuote -> quote = character
                    character == '{' -> braceDepth++
                    character == '[' -> bracketDepth++
                    character == '}' && braceDepth > 0 -> braceDepth--
                    character == ']' && bracketDepth > 0 -> bracketDepth--
                }
                structureCursor++
            }

            val valueQuote = message[valueStart]
            val isQuoted = valueQuote == '"' || valueQuote == '\''
            if (!isQuoted && key == "authorization" && message.regionMatches(valueStart, "mediabrowser", 0, "mediabrowser".length, ignoreCase = true)) {
                continue
            }
            val isStructured = when (match.groupValues[1]) {
                "?", "&" -> false
                "{", "[" -> true
                else -> if (quote != 0.toChar()) quotedBraceDepth > 0 || quotedBracketDepth > 0 else braceDepth > 0 || bracketDepth > 0
            }
            val contentStart = if (isQuoted) valueStart + 1 else valueStart
            val valueEnd = if (isQuoted) {
                quotedValueEnd(message, contentStart, valueQuote)
            } else {
                unquotedValueEnd(message, contentStart, key, isStructured, hashTerminates = '=' in match.groupValues[5])
            }
            if (valueEnd <= contentStart) continue
            // A value [Redactor]'s key shapes removed already (`Bearer …`, `"…"`) stays as it is.
            if (message.substring(contentStart, valueEnd).trim().substringAfterLast(' ') == MARK) continue
            result.append(message, cursor, contentStart).append(MARK)
            cursor = valueEnd
        }
        if (cursor == 0) return message
        return result.append(message, cursor, message.length).toString()
    }

    private fun Char.isLogWhitespace() = this == ' ' || this == '\t' || this == '\n' || this == '\r'

    private fun quotedValueEnd(message: String, start: Int, quote: Char): Int {
        var escaped = false
        for (index in start until message.length) {
            val character = message[index]
            if (character == '\n' || character == '\r') return index
            if (!escaped && character == quote) return index
            escaped = !escaped && character == '\\'
        }
        return message.length
    }

    private fun unquotedValueEnd(message: String, start: Int, key: String, isStructured: Boolean, hashTerminates: Boolean): Int {
        if (isStructured) return structuredValueEnd(message, start)
        var index = start
        if (key == "authorization" || key == "proxy-authorization") {
            AUTHORIZATION_SCHEME.matchAt(message, start)?.let { index = it.range.last + 1 }
        }
        val cookie = key == "cookie" || key == "set-cookie"
        while (index < message.length) {
            val character = message[index]
            val terminates = if (cookie) {
                character in "\n\r),]}"
            } else {
                character in " \t\n\r\"'&),;]}" || (hashTerminates && character == '#')
            }
            if (terminates) break
            index++
        }
        return index
    }

    private fun structuredValueEnd(message: String, start: Int): Int {
        var braceDepth = 0
        var bracketDepth = 0
        var parenthesisDepth = 0
        var quote = 0.toChar()
        var escaped = false
        val first = message[start]
        val nested = first == '{' || first == '[' || first == '('
        for (index in start until message.length) {
            val character = message[index]
            if (nested && quote != 0.toChar()) {
                if (!escaped && character == quote) quote = 0.toChar()
                escaped = !escaped && character == '\\'
                continue
            }
            if (nested && (character == '"' || character == '\'')) {
                quote = character
                continue
            }
            val atValueLevel = braceDepth == 0 && bracketDepth == 0 && parenthesisDepth == 0
            if (atValueLevel && character in "\n\r),;]}") return index
            if (!nested) continue
            when {
                character == '{' -> braceDepth++
                character == '[' -> bracketDepth++
                character == '(' -> parenthesisDepth++
                character == '}' && braceDepth > 0 -> braceDepth--
                character == ']' && bracketDepth > 0 -> bracketDepth--
                character == ')' && parenthesisDepth > 0 -> parenthesisDepth--
            }
        }
        return message.length
    }
}
