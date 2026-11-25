package com.edde746.plezy.watch

import com.edde746.plezy.crypto.cryptoProvider
import com.edde746.plezy.log.Log
import dev.whyoleg.cryptography.algorithms.SHA256
import io.ktor.client.HttpClient
import io.ktor.client.plugins.api.ClientPlugin
import io.ktor.client.plugins.api.Send
import io.ktor.client.plugins.api.createClientPlugin
import io.ktor.http.HttpStatusCode
import io.ktor.http.URLProtocol
import io.ktor.http.Url
import kotlinx.coroutines.CancellationException
import party.openwatch.PartyException
import party.openwatch.Relays
import party.openwatch.formatCode
import kotlin.time.TimeSource

/** Open Watch Party's relay settings, room codes and room bounds as Plezy uses them. */
object WatchPartyRelays {
    /** The offset bound of the SDK: 7 days either way. */
    const val MAX_OFFSET_MS: Long = 604_800_000L

    /** The room rates the SDK accepts. */
    const val MIN_RATE: Double = 0.5
    const val MAX_RATE: Double = 2.0

    /** The relay scope of the public relays ([relayScopeOf]). */
    const val PUBLIC_SCOPE: String = "public"

    /**
     * [input] as the base URL of a self-hosted Open Watch Party relay: `http` or `https`, a host, an optional port and
     * path prefix; scheme and host lower case, a default port dropped, no trailing `/`, the path's case kept, an IPv6
     * literal in its brackets. Null when it isn't one the SDK accepts (blank, another scheme, user info, a query or a
     * fragment, no host).
     */
    fun canonicalBaseUrl(input: String): String? {
        val trimmed = input.trim()
        val match = URL.matchEntire(trimmed) ?: return null
        val (rawScheme, authority, rest) = match.destructured
        val scheme = rawScheme.lowercase()
        if (scheme != "http" && scheme != "https") return null
        if ('@' in authority || '?' in rest || '#' in rest) return null
        val host: String
        val portText: String
        if (authority.startsWith("[")) {
            val close = authority.indexOf(']')
            if (close < 0) return null
            host = authority.substring(1, close)
            val after = authority.substring(close + 1)
            if (after.isNotEmpty() && !after.startsWith(":")) return null
            portText = after.removePrefix(":")
        } else {
            val colon = authority.lastIndexOf(':')
            host = if (colon < 0) authority else authority.substring(0, colon)
            portText = if (colon < 0) "" else authority.substring(colon + 1)
        }
        if (host.isEmpty() || (portText.isNotEmpty() && !portText.all { it in '0'..'9' })) return null
        val port = portText.toIntOrNull()
        val defaultPort = if (scheme == "https") 443 else 80
        val lowerHost = host.lowercase()
        val base = buildString {
            append(scheme).append("://")
            append(if (':' in lowerHost) "[$lowerHost]" else lowerHost)
            if (port != null && port != defaultPort) append(':').append(port)
            append(encodePath(rest).trimEnd('/'))
        }
        return base.takeIf(::sdkAccepts)
    }

    /**
     * A stable key for the relay network a room code belongs to, so recent rooms of one relay setting don't show under
     * another: [PUBLIC_SCOPE], or the lowercase hex SHA-256 of the canonical custom base URL (not the URL itself).
     */
    fun relayScopeOf(canonicalBaseUrl: String?): String =
        if (canonicalBaseUrl == null) {
            PUBLIC_SCOPE
        } else {
            cryptoProvider.get(SHA256).hasher().hashBlocking(canonicalBaseUrl.encodeToByteArray()).toHexString()
        }

    /** [text] as a room code (separators dropped, letters upper-cased), or null when it isn't 6 symbols of the alphabet. */
    fun normalizeRoomCode(text: String): String? = try {
        formatCode(text).replace("-", "")
    } catch (_: PartyException) {
        null
    }

    /** [code] as shown: two groups, `K7M-Q2X`. [code] must be a room code. */
    fun formatRoomCode(code: String): String = formatCode(code)

    /**
     * The join field after an edit: upper-cased, everything but `A-Z0-9` dropped, 6 symbols at most, `-` after the
     * third; letters outside the code alphabet stay so Join can say the code is wrong. [caret] (in [text]) maps to
     * [TypedRoomCode.caret]: after the same number of symbols.
     */
    fun typedRoomCode(text: String, caret: Int = text.length): TypedRoomCode {
        fun symbols(s: String) = s.uppercase().filter { it in 'A'..'Z' || it in '0'..'9' }
        val kept = symbols(text).take(CODE_LENGTH)
        val formatted = if (kept.length > 3) "${kept.substring(0, 3)}-${kept.substring(3)}" else kept
        val before = symbols(text.substring(0, caret.coerceIn(0, text.length))).length.coerceAtMost(kept.length)
        return TypedRoomCode(formatted, if (before > 3) before + 1 else before)
    }

    private const val CODE_LENGTH = 6

    /** `scheme://authority` and the rest (line breaks included); the authority runs to the first `/`, `?` or `#`. */
    private val URL = Regex("""^([A-Za-z][A-Za-z0-9+.\-]*)://([^/?#]*)([\s\S]*)$""")

    /** [path] with anything outside printable ASCII percent-encoded as UTF-8, as a parsed URI holds it. */
    private fun encodePath(path: String): String = buildString {
        for (byte in path.encodeToByteArray()) {
            val b = byte.toInt() and 0xFF
            if (b in 0x21..0x7E) append(b.toChar()) else append('%').append(HEX[b shr 4]).append(HEX[b and 0xF])
        }
    }

    private const val HEX = "0123456789ABCDEF"

    /**
     * Whether the SDK's `Relays.at` takes [base]: `http(s)://` and a host, and a WebSocket URL of printable ASCII
     * without `?` or `#`.
     */
    private fun sdkAccepts(base: String): Boolean {
        val rest = base.substringAfter("://")
        return rest.substringBefore('/').isNotEmpty() && rest.none { it.code !in 0x21..0x7E || it == '?' || it == '#' }
    }
}

/** The join field's text and caret after [WatchPartyRelays.typedRoomCode]. */
data class TypedRoomCode(val text: String, val caret: Int)

/**
 * The relays rooms live on for the device's relay setting: the public relays, or the self-hosted one at a canonical
 * base. The [Relays] object (its list and refresh schedule) is kept and rebuilt only when the base changes. Their
 * WebSockets connect through [appHttp] with [relayConnectLog].
 */
internal class WatchRelayChoice(appHttp: HttpClient) {
    private var base: String? = null
    private var relays: Relays? = null
    private val http: HttpClient by lazy { appHttp.config { install(relayConnectLog(relays = { relays })) } }

    fun relaysFor(canonicalBaseUrl: String?): Relays {
        relays?.takeIf { base == canonicalBaseUrl }?.let { return it }
        val next = if (canonicalBaseUrl == null) Relays.public(http) else Relays.at(http, canonicalBaseUrl)
        base = canonicalBaseUrl
        relays = next
        return next
    }
}

/**
 * Logs each WebSocket connect to a relay, which the SDK reduces to `unreachable` when it fails: a success with its time
 * (debug logging), a failure with its time and cause (DNS, TLS, a refused upgrade, a timeout). The relay is named by
 * its id in [relays]' list (`na`, `eu`, `asia`, `custom`), read at log time since the list refreshes, else its host.
 */
internal fun relayConnectLog(relays: () -> Relays?, timeSource: TimeSource = TimeSource.Monotonic): ClientPlugin<Unit> =
    createClientPlugin("WatchRelayConnectLog") {
        on(Send) { request ->
            val url = request.url.build()
            if (url.protocol != URLProtocol.WS && url.protocol != URLProtocol.WSS) return@on proceed(request)
            val started = timeSource.markNow()
            fun id(): String = relays()?.list?.firstOrNull { sameSocket(Url(it.url), url) }?.id ?: url.host
            try {
                val call = proceed(request)
                val ms = started.elapsedNow().inWholeMilliseconds
                val status = call.response.status
                if (status == HttpStatusCode.SwitchingProtocols) {
                    Log.d(RELAY_TAG) { "relay ${id()} connected in $ms ms" }
                } else {
                    Log.w(RELAY_TAG) { "relay ${id()} failed to connect after $ms ms: HTTP ${status.value}" }
                }
                call
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(RELAY_TAG, e) { "relay ${id()} failed to connect after ${started.elapsedNow().inWholeMilliseconds} ms" }
                throw e
            }
        }
    }

private fun sameSocket(a: Url, b: Url): Boolean = a.host == b.host && a.port == b.port && a.encodedPath == b.encodedPath

private const val RELAY_TAG = "WatchTogether"
