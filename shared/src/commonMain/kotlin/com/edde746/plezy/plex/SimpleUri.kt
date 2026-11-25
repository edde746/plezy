package com.edde746.plezy.plex

/**
 * The parts of an absolute `scheme://[userinfo@]host[:port][path][?query][#fragment]` URL the connection rules read.
 * [host] has IPv6 brackets removed; [port] falls back to the scheme's default (80/443, else -1).
 */
internal data class SimpleUri(
    val scheme: String,
    val host: String,
    val port: Int,
    val path: String,
    val query: String?,
    val fragment: String?,
) {
    companion object {
        fun parse(text: String): SimpleUri? {
            val schemeEnd = text.indexOf("://")
            if (schemeEnd <= 0) return null
            val scheme = text.substring(0, schemeEnd).lowercase()
            var rest = text.substring(schemeEnd + 3)
            var fragment: String? = null
            rest.indexOf('#').takeIf { it >= 0 }?.let { fragment = rest.substring(it + 1); rest = rest.substring(0, it) }
            var query: String? = null
            rest.indexOf('?').takeIf { it >= 0 }?.let { query = rest.substring(it + 1); rest = rest.substring(0, it) }
            val slash = rest.indexOf('/')
            val authority = if (slash >= 0) rest.substring(0, slash) else rest
            val path = if (slash >= 0) rest.substring(slash) else ""
            val hostPort = authority.substringAfterLast('@')
            val host: String
            val portText: String?
            if (hostPort.startsWith('[')) {
                val close = hostPort.indexOf(']')
                if (close < 0) return null
                host = hostPort.substring(1, close)
                portText = hostPort.substring(close + 1).removePrefix(":").ifEmpty { null }
            } else {
                val colon = hostPort.lastIndexOf(':')
                host = if (colon >= 0) hostPort.substring(0, colon) else hostPort
                portText = if (colon >= 0) hostPort.substring(colon + 1).ifEmpty { null } else null
            }
            val port = when {
                portText != null -> portText.toIntOrNull() ?: return null
                scheme == "https" -> 443
                scheme == "http" -> 80
                else -> -1
            }
            return SimpleUri(scheme, host, port, path, query, fragment)
        }
    }
}
