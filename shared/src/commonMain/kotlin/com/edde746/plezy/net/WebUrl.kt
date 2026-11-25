package com.edde746.plezy.net

/**
 * URL handling modelled on the WHATWG URL parser (as the `url` crate implements it). Only absolute URLs are handled;
 * [normalize] implements the subset of the parser that http(s) and ws(s) URLs go through.
 */
object WebUrl {
    private val SCHEME = Regex("^[A-Za-z][A-Za-z0-9+.\\-]*:")
    private val SPECIAL_SCHEMES = setOf("http", "https", "ws", "wss", "ftp", "file")
    private val DEFAULT_PORTS = mapOf("http" to 80, "https" to 443, "ws" to 80, "wss" to 443, "ftp" to 21)

    /** The lowercased scheme of an absolute URL, or null when [url] has none. */
    fun scheme(url: String): String? = SCHEME.find(url)?.value?.dropLast(1)?.lowercase()

    /**
     * Whether [url] is an `http`/`https` link: the only kind the app hands to the system's opener, on every platform
     * (`AppSession.openUrl` and each platform's opener check it). Anything else (`file:`, a Windows path, `smb:`,
     * `search-ms:`, another app's scheme) never leaves the app.
     */
    fun isWeb(url: String): Boolean = scheme(url).let { it == "http" || it == "https" }

    /**
     * Whether [url] is an absolute URL the `url` crate would accept: a scheme, and for the special schemes
     * (`http`, `https`, `ws`, `wss`, `ftp`) `//` and a non-empty host with a valid port. Other schemes (`plezy:`,
     * `data:`) only need the scheme.
     */
    fun isAbsolute(url: String): Boolean = canonical(url) != null

    /**
     * [url] as the WHATWG parser serializes it: [normalize]d for `http`, `https`, `ws`, `wss` and `ftp`, as
     * written for other schemes, null when it isn't an absolute URL.
     */
    fun canonical(url: String): String? {
        val scheme = scheme(url) ?: return null
        return if (scheme !in SPECIAL_SCHEMES || scheme == "file") url else normalize(url)
    }

    /** The path of a hierarchical URL (`/a/b` in `https://host/a/b?q`), or null when [url] has no authority. */
    fun path(url: String): String? {
        val scheme = scheme(url) ?: return null
        val rest = url.substring(scheme.length + 1)
        if (!rest.startsWith("//")) return null
        val afterAuthority = rest.substring(2).dropWhile { it != '/' && it != '?' && it != '#' }
        return afterAuthority.takeWhile { it != '?' && it != '#' }
    }

    /**
     * Parses and serializes an `http`/`https`/`ws`/`wss`/`ftp` URL the way the `url` crate does: surrounding spaces
     * and C0 controls trimmed, tabs and newlines removed, scheme and host lowercased, the default port dropped,
     * backslashes read as `/`, dot segments resolved, an empty path made `/`, and characters outside the WHATWG
     * path/query/fragment/userinfo sets percent-encoded (existing escapes are kept as written). Returns null for
     * anything else or when the URL is invalid. Internationalized host names are not supported (null).
     */
    fun normalize(input: String): String? {
        val trimmed = input.trim { it <= ' ' }.filterNot { it == '\t' || it == '\n' || it == '\r' }
        val scheme = scheme(trimmed) ?: return null
        if (scheme !in SPECIAL_SCHEMES || scheme == "file") return null
        var rest = trimmed.substring(scheme.length + 1)
        if (!(rest.startsWith("//") || rest.startsWith("\\\\") || rest.startsWith("/\\") || rest.startsWith("\\/"))) return null
        rest = rest.substring(2)

        val authorityEnd = rest.indexOfFirst { it == '/' || it == '\\' || it == '?' || it == '#' }.let { if (it < 0) rest.length else it }
        val authority = rest.substring(0, authorityEnd)
        var tail = rest.substring(authorityEnd)

        val at = authority.lastIndexOf('@')
        val userInfo = if (at >= 0) authority.substring(0, at) else null
        val hostPort = if (at >= 0) authority.substring(at + 1) else authority
        val (host, port) = splitHostPort(hostPort, scheme) ?: return null

        val fragment = tail.indexOf('#').let { i -> if (i < 0) null else tail.substring(i + 1).also { tail = tail.substring(0, i) } }
        val query = tail.indexOf('?').let { i -> if (i < 0) null else tail.substring(i + 1).also { tail = tail.substring(0, i) } }
        val path = normalizePath(tail.replace('\\', '/'))

        return buildString {
            append(scheme).append("://")
            if (userInfo != null) {
                val user = userInfo.substringBefore(':')
                val password = if (':' in userInfo) userInfo.substringAfter(':') else ""
                if (user.isNotEmpty() || password.isNotEmpty()) {
                    append(percentEncode(user, ::inUserInfoSet))
                    if (password.isNotEmpty()) append(':').append(percentEncode(password, ::inUserInfoSet))
                    append('@')
                }
            }
            append(host)
            if (port != null) append(':').append(port)
            append(path)
            if (query != null) append('?').append(percentEncode(query, ::inSpecialQuerySet))
            if (fragment != null) append('#').append(percentEncode(fragment, ::inFragmentSet))
        }
    }

    private fun splitHostPort(hostPort: String, scheme: String): Pair<String, Int?>? {
        val host: String
        val portText: String?
        if (hostPort.startsWith("[")) {
            val close = hostPort.indexOf(']')
            if (close < 0) return null
            host = hostPort.substring(0, close + 1).lowercase()
            val after = hostPort.substring(close + 1)
            portText = when {
                after.isEmpty() -> null
                after.startsWith(":") -> after.substring(1)
                else -> return null
            }
            if (!host.substring(1, host.length - 1).all { it.isHexDigitChar() || it == ':' || it == '.' }) return null
        } else {
            val colon = hostPort.lastIndexOf(':')
            host = (if (colon >= 0) hostPort.substring(0, colon) else hostPort).lowercase()
            portText = if (colon >= 0) hostPort.substring(colon + 1) else null
            if (host.isEmpty() || host.any { it.code >= 0x7F || it in FORBIDDEN_HOST_CHARS || it <= ' ' }) return null
        }
        val port = when {
            portText.isNullOrEmpty() -> null
            portText.all { it in '0'..'9' } -> portText.toIntOrNull()?.takeIf { it <= 65535 } ?: return null
            else -> return null
        }
        return host to port.takeIf { it != DEFAULT_PORTS[scheme] }
    }

    private fun normalizePath(raw: String): String {
        if (raw.isEmpty()) return "/"
        val segments = raw.substring(1).split('/')
        val out = ArrayList<String>(segments.size)
        segments.forEachIndexed { index, segment ->
            val last = index == segments.lastIndex
            when (segment.lowercase()) {
                ".", "%2e" -> if (last) out.add("")
                "..", ".%2e", "%2e.", "%2e%2e" -> {
                    if (out.isNotEmpty()) out.removeAt(out.lastIndex)
                    if (last) out.add("")
                }
                else -> out.add(percentEncode(segment, ::inPathSet))
            }
        }
        return "/" + out.joinToString("/")
    }

    private val FORBIDDEN_HOST_CHARS = setOf('#', '%', '/', ':', '<', '>', '?', '@', '[', '\\', ']', '^', '|')

    private fun Char.isHexDigitChar() = this in '0'..'9' || this in 'a'..'f' || this in 'A'..'F'

    private fun inFragmentSet(c: Char) = c < ' ' || c == ' ' || c == '"' || c == '<' || c == '>' || c == '`'
    private fun inSpecialQuerySet(c: Char) = c < ' ' || c == ' ' || c == '"' || c == '#' || c == '<' || c == '>' || c == '\''
    private fun inPathSet(c: Char) = c < ' ' || c == ' ' || c == '"' || c == '#' || c == '<' || c == '>' || c == '?' ||
        c == '`' || c == '{' || c == '}'
    private fun inUserInfoSet(c: Char) = inPathSet(c) || c == '/' || c == ':' || c == ';' || c == '=' || c == '@' ||
        c == '[' || c == '\\' || c == ']' || c == '^' || c == '|'

    private fun percentEncode(value: String, inSet: (Char) -> Boolean): String {
        if (value.all { it.code in 0x20..0x7E && !inSet(it) }) return value
        val out = StringBuilder(value.length + 8)
        for (byte in value.encodeToByteArray()) {
            val b = byte.toInt() and 0xFF
            val c = b.toChar()
            if (b in 0x20..0x7E && !inSet(c)) out.append(c) else out.append('%').append(HEX[b shr 4]).append(HEX[b and 0xF])
        }
        return out.toString()
    }

    private const val HEX = "0123456789ABCDEF"
}
