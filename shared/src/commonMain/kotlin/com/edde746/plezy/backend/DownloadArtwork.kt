package com.edde746.plezy.backend

import com.edde746.plezy.model.MediaItem

/**
 * The storage key of an artwork path or URL, made as Plezy's earlier releases made it so the artwork they saved keeps
 * its file names. A path or URL with a query is normalized as those releases normalized it (scheme and host
 * lowercased, a default port dropped, escapes normalized, dot segments removed); its query parameters are decoded (a
 * repeated one keeps its last value at its first place, one without a name goes) and written again without Jellyfin's
 * `api_key` (`+` for a space, everything but `A-Za-z0-9-._~` percent-encoded, an empty value without `=`). A query of
 * nothing but `api_key` goes whole: a key never holds the token. Any other query that ends up empty is kept as it was.
 * Anything else, or what doesn't read as a URI, stays as it is.
 */
fun artworkStorageKey(pathOrUrl: String): String {
    val uri = ArtworkUri.parse(pathOrUrl) ?: return pathOrUrl
    val query = uri.query ?: return pathOrUrl
    val parameters = LinkedHashMap<String, String>()
    for (element in query.split('&')) {
        val equals = element.indexOf('=')
        when {
            equals < 0 -> if (element.isNotEmpty()) parameters[decodeQueryComponent(element)] = ""
            equals > 0 -> parameters[decodeQueryComponent(element.substring(0, equals))] = decodeQueryComponent(element.substring(equals + 1))
        }
    }
    val hadToken = parameters.remove("api_key") != null
    if (parameters.isEmpty()) return uri.toString(if (hadToken) null else normalizeComponent(query, ::isQueryChar))
    val rebuilt = parameters.entries.joinToString("&") { (name, value) ->
        if (value.isEmpty()) encodeQueryComponent(name) else "${encodeQueryComponent(name)}=${encodeQueryComponent(value)}"
    }
    return uri.toString(rebuilt)
}

/** A URI's parts, normalized as the earlier releases normalized them; [query] raw. */
private class ArtworkUri(
    val scheme: String?,
    val userInfo: String,
    val host: String?,
    val port: String?,
    val path: String,
    val query: String?,
    val fragment: String?,
) {
    fun toString(query: String?): String = buildString {
        if (scheme != null) append(scheme).append(':')
        if (host != null) {
            append("//")
            if (userInfo.isNotEmpty()) append(userInfo).append('@')
            append(host)
            if (port != null) append(':').append(port)
        }
        append(path)
        if (query != null) append('?').append(query)
        if (fragment != null) append('#').append(fragment)
    }

    companion object {
        private val PARTS = Regex("^(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\\?([^#]*))?(?:#([\\s\\S]*))?$")
        private val SCHEME = Regex("[A-Za-z][A-Za-z0-9+.-]*")

        /** [value]'s parts, or null when the earlier releases wouldn't read it as a URI (a bad scheme, host or port). */
        fun parse(value: String): ArtworkUri? {
            val parts = PARTS.matchEntire(value) ?: return null
            val scheme = parts.groups[1]?.value?.also { if (!SCHEME.matches(it)) return null }?.lowercase()
            val authority = parts.groups[2]?.value
            var userInfo = ""
            var host: String? = null
            var port: String? = null
            if (authority != null) {
                val at = authority.lastIndexOf('@')
                if (at >= 0) userInfo = normalizeComponent(authority.substring(0, at), ::isUserInfoChar)
                val hostAndPort = authority.substring(at + 1)
                val hostEnd = if (hostAndPort.startsWith('[')) {
                    hostAndPort.indexOf(']').also { if (it < 0) return null } + 1
                } else {
                    hostAndPort.indexOf(':').let { if (it < 0) hostAndPort.length else it }
                }
                val rawHost = hostAndPort.substring(0, hostEnd)
                host = if (rawHost.startsWith('[')) rawHost.lowercase() else lowercaseOutsideEscapes(normalizeComponent(rawHost, ::isRegNameChar))
                val rawPort = hostAndPort.substring(hostEnd)
                if (rawPort.isNotEmpty()) {
                    if (rawPort[0] != ':' || rawPort.drop(1).any { it !in '0'..'9' }) return null
                    val number = rawPort.drop(1).trimStart('0').ifEmpty { if (rawPort.length > 1) "0" else "" }
                    val default = (scheme == "http" && number == "80") || (scheme == "https" && number == "443")
                    if (number.isNotEmpty() && !default) port = number
                }
            }
            val rawPath = normalizeComponent(parts.groups[3]?.value.orEmpty(), ::isPathChar)
            val path = if (scheme == null && authority == null && !rawPath.startsWith('/')) {
                normalizeRelativePath(rawPath)
            } else {
                removeDotSegments(rawPath)
            }
            val fragment = parts.groups[5]?.value?.let { normalizeComponent(it, ::isQueryChar) }
            return ArtworkUri(scheme, userInfo, host, port, path, parts.groups[4]?.value, fragment)
        }
    }
}

private fun isUnreserved(c: Char) = c in 'A'..'Z' || c in 'a'..'z' || c in '0'..'9' || c == '-' || c == '.' || c == '_' || c == '~'

private fun isRegNameChar(c: Char) = isUnreserved(c) || c in "!$&'()*+,;="

private fun isUserInfoChar(c: Char) = isRegNameChar(c) || c == ':'

private fun isPathChar(c: Char) = isUserInfoChar(c) || c == '@' || c == '/'

private fun isQueryChar(c: Char) = isPathChar(c) || c == '?'

private fun hexValue(c: Char): Int = when (c) {
    in '0'..'9' -> c - '0'
    in 'A'..'F' -> c - 'A' + 10
    in 'a'..'f' -> c - 'a' + 10
    else -> -1
}

private fun StringBuilder.appendEscape(byte: Int) {
    append('%').append(HEX[byte shr 4]).append(HEX[byte and 0xF])
}

private const val HEX = "0123456789ABCDEF"

/**
 * [component] with each valid escape of an unreserved character decoded, every other valid escape in uppercase, a `%`
 * starting no valid escape escaped, and each character [allowed] doesn't take escaped as UTF-8.
 */
private fun normalizeComponent(component: String, allowed: (Char) -> Boolean): String = buildString {
    var i = 0
    while (i < component.length) {
        val c = component[i]
        if (c == '%') {
            val high = if (i + 2 < component.length) hexValue(component[i + 1]) else -1
            val low = if (high >= 0) hexValue(component[i + 2]) else -1
            if (low < 0) {
                append("%25")
                i++
                continue
            }
            val value = high * 16 + low
            if (value < 0x80 && isUnreserved(value.toChar())) append(value.toChar()) else appendEscape(value)
            i += 3
        } else if (c.code < 0x80 && allowed(c)) {
            append(c)
            i++
        } else {
            val end = if (c.isHighSurrogate() && i + 1 < component.length) i + 2 else i + 1
            for (byte in component.substring(i, end).encodeToByteArray()) appendEscape(byte.toInt() and 0xFF)
            i = end
        }
    }
}

/** [host] with its ASCII letters lowercased, the hex digits of its escapes left as they are. */
private fun lowercaseOutsideEscapes(host: String): String = buildString {
    var i = 0
    while (i < host.length) {
        val c = host[i]
        if (c == '%') {
            appendRange(host, i, minOf(i + 3, host.length))
            i += 3
        } else {
            append(if (c in 'A'..'Z') c + 32 else c)
            i++
        }
    }
}

private fun mayContainDotSegments(path: String) = path.startsWith('.') || "/." in path

/** An absolute path's `.` and `..` segments resolved (RFC 3986's remove_dot_segments, as the earlier releases did). */
private fun removeDotSegments(path: String): String {
    if (!mayContainDotSegments(path)) return path
    val output = ArrayList<String>()
    var appendSlash = false
    for (segment in path.split('/')) {
        appendSlash = false
        when (segment) {
            ".." -> {
                if (output.isNotEmpty()) {
                    output.removeAt(output.lastIndex)
                    if (output.isEmpty()) output += ""
                }
                appendSlash = true
            }
            "." -> appendSlash = true
            else -> output += segment
        }
    }
    if (appendSlash) output += ""
    return output.joinToString("/")
}

/**
 * A relative path's `.` segments dropped and `..` segments resolved where they can be, leading ones kept; a colon in
 * its first segment escaped so it can't read as a scheme.
 */
private fun normalizeRelativePath(path: String): String {
    if (!mayContainDotSegments(path)) return escapeScheme(path)
    val output = ArrayList<String>()
    var appendSlash = false
    for (segment in path.split('/')) {
        appendSlash = false
        when {
            segment == ".." && output.isNotEmpty() && output.last() != ".." -> {
                output.removeAt(output.lastIndex)
                appendSlash = true
            }
            segment == ".." -> output += ".."
            segment == "." -> appendSlash = true
            else -> output += segment
        }
    }
    if (output.isEmpty() || (output.size == 1 && output[0].isEmpty())) return "./"
    if (appendSlash || output.last() == "..") output += ""
    output[0] = escapeScheme(output[0])
    return output.joinToString("/")
}

private fun escapeScheme(segment: String): String {
    if (segment.length < 2 || !(segment[0] in 'A'..'Z' || segment[0] in 'a'..'z')) return segment
    for (i in 1 until segment.length) {
        val c = segment[i]
        if (c == ':') return segment.substring(0, i) + "%3A" + segment.substring(i + 1)
        if (!(c in 'A'..'Z' || c in 'a'..'z' || c in '0'..'9' || c == '+' || c == '-' || c == '.')) break
    }
    return segment
}

/** `+` as a space and `%XX` escapes as bytes, over the UTF-8 of [value]. */
private fun decodeQueryComponent(value: String): String {
    val input = value.encodeToByteArray()
    val output = ByteArray(input.size)
    var size = 0
    var i = 0
    while (i < input.size) {
        val byte = input[i]
        val high = if (byte == '%'.code.toByte() && i + 2 < input.size) hexValue(input[i + 1].toInt().toChar()) else -1
        val low = if (high >= 0) hexValue(input[i + 2].toInt().toChar()) else -1
        when {
            byte == '+'.code.toByte() -> output[size++] = ' '.code.toByte()
            low >= 0 -> {
                output[size++] = (high * 16 + low).toByte()
                i += 2
            }
            else -> output[size++] = byte
        }
        i++
    }
    return output.decodeToString(0, size)
}

private fun encodeQueryComponent(value: String): String = buildString {
    for (byte in value.encodeToByteArray()) {
        val c = (byte.toInt() and 0xFF).toChar()
        when {
            c.code < 0x80 && isUnreserved(c) -> append(c)
            c == ' ' -> append('+')
            else -> appendEscape(byte.toInt() and 0xFF)
        }
    }
}

/**
 * The artwork to save with a download of [item]: its thumb, clear logo, art and square background, in that order.
 * [resolveUrl] turns an image path into the URL to fetch (Plex builds a tokened URL, Jellyfin's paths are URLs
 * already); a missing path, or a null or empty URL, skips the image.
 */
fun buildArtworkSpecs(item: MediaItem, resolveUrl: (String) -> String?): List<DownloadArtworkSpec> =
    listOf(item.thumbPath, item.clearLogoPath, item.artPath, item.backgroundSquarePath).mapNotNull { path ->
        if (path.isNullOrEmpty()) return@mapNotNull null
        val url = resolveUrl(path)
        if (url.isNullOrEmpty()) null else DownloadArtworkSpec(localKey = artworkStorageKey(path), url = url)
    }
