package com.edde746.plezy.backend.net

import com.edde746.plezy.net.UriComponent
import io.ktor.http.URLBuilder
import io.ktor.http.URLProtocol
import io.ktor.http.Url

/** [input] trimmed, without one trailing slash. */
fun stripTrailingSlash(input: String): String {
    val trimmed = input.trim()
    return if (trimmed.endsWith('/')) trimmed.dropLast(1) else trimmed
}

private val SCHEME = Regex("""^[A-Za-z][A-Za-z\d+.-]*://""")

/** A base URL as stored and compared: trimmed, no trailing slash, scheme lower-cased. */
fun canonicalizeBaseUrl(input: String): String {
    val stripped = stripTrailingSlash(input)
    val match = SCHEME.find(stripped) ?: return stripped
    return match.value.lowercase() + stripped.substring(match.range.last + 1)
}

/** [input] starts with `scheme://`. */
fun hasUrlScheme(input: String): Boolean = SCHEME.containsMatchIn(input)

/** A scheme to try a bare host with, and the port to add when the user typed none (null: the scheme's own). */
data class BaseUrlGuess(val scheme: String, val port: Int?)

/**
 * The base URLs a user's [input] may mean: as typed when it has a scheme, else one per [guesses] (a port the user typed
 * wins over a guess's), deduplicated; empty when there is no host.
 */
fun expandBaseUrlCandidates(input: String, guesses: List<BaseUrlGuess>): List<String> {
    val trimmed = canonicalizeBaseUrl(input)
    if (trimmed.isEmpty()) return emptyList()
    if (hasUrlScheme(trimmed)) return listOf(trimmed)
    val authority = trimmed.substringBefore('/').substringBefore('?').substringBefore('#').substringAfterLast('@')
    if (authority.isEmpty()) return emptyList()
    val parsed = runCatching { Url("http://$trimmed") }.getOrNull() ?: return emptyList()
    if (parsed.host.isEmpty()) return emptyList()
    val typedPort = parsed.specifiedPort.takeIf { it != 0 }
    val candidates = LinkedHashSet<String>()
    for (guess in guesses) {
        val candidate = URLBuilder().apply {
            protocol = URLProtocol.createOrDefault(guess.scheme)
            user = parsed.user
            password = parsed.password
            host = parsed.host
            port = typedPort ?: guess.port ?: 0
            pathSegments = parsed.rawSegments
        }.buildString()
        val normalized = stripTrailingSlash(candidate)
        if (normalized.isNotEmpty()) candidates += normalized
    }
    return candidates.toList()
}

/**
 * A query string from [params] in order, both sides percent-encoded as `encodeURIComponent` does (space as `%20`).
 * Null values are skipped; an [Iterable] value repeats its key once per element.
 */
fun encodeQueryParameters(params: Map<String, Any?>?): String {
    if (params.isNullOrEmpty()) return ""
    val parts = mutableListOf<String>()
    fun add(key: String, value: Any?) {
        when (value) {
            null -> Unit
            is Iterable<*> -> value.forEach { add(key, it) }
            else -> parts += UriComponent.encode(key) + "=" + UriComponent.encode(value.toString())
        }
    }
    for ((key, value) in params) add(key, value)
    return parts.joinToString("&")
}
