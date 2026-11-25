package com.edde746.plezy.plex

import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.EndpointNetworkClass
import com.edde746.plezy.servers.PlexServerEntry
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.time.Instant

/** Where an endpoint sits for failover purposes. */
enum class PlexNetworkClass { LOCAL, REMOTE, RELAY, UNKNOWN }

/** One way to reach a server, as plex.tv's resources publish it (or its synthetic LAN cleartext twin). */
data class PlexConnection(
    val protocol: String,
    val address: String,
    val port: Int,
    val uri: String,
    val local: Boolean,
    val relay: Boolean,
    val ipv6: Boolean,
) {
    /**
     * True for an IPv6 endpoint, from Plex's `IPv6` flag or the raw address. IPv6 endpoints rank below their IPv4
     * siblings everywhere: some native resolvers (Android's) don't retry an AAAA-only host on a network with an IPv6
     * prefix but no route, so IPv4 keeps every stack on an endpoint all of them resolve.
     */
    val isIPv6: Boolean get() = ipv6 || parseIpLiteral(normalizedHost(address))?.size == 16

    val networkClass: PlexNetworkClass
        get() = when {
            relay -> PlexNetworkClass.RELAY
            local -> PlexNetworkClass.LOCAL
            else -> PlexNetworkClass.REMOTE
        }

    /** `http://<address>:<port>`, an IPv6 address bracketed. */
    val httpDirectUrl: String
        get() {
            val safe = if (':' in address && !address.startsWith('[')) "[$address]" else address
            return "http://$safe:$port"
        }

    val displayType: String
        get() {
            val base = if (relay) "Relay" else if (local) "Local" else "Remote"
            return if (isIPv6) "$base IPv6" else base
        }

    /** The same endpoint over http (scheme swapped in [uri]). */
    fun toHttpFallback(): PlexConnection {
        require(protocol == "https") { "Only an HTTPS connection has an HTTP fallback" }
        return copy(protocol = "http", uri = uri.replaceFirst("https://", "http://"))
    }

    fun toJson(): JsonObject = buildJsonObject {
        put("protocol", protocol)
        put("address", address)
        put("port", port)
        put("uri", uri)
        put("local", local)
        put("relay", relay)
        put("IPv6", ipv6)
    }

    /** Two rows for the same URL that disagree about local/relay/IPv6 are different candidates. */
    internal val endpointIdentity: String get() = "$protocol|$address|$port|$uri|$local|$relay|$ipv6"

    companion object {
        /** Requires non-empty `protocol`, `address`, `uri` and a numeric `port`; else [IllegalArgumentException]. */
        fun fromJson(json: JsonObject): PlexConnection {
            val protocol = json["protocol"].stringOrNull()
            val address = json["address"].stringOrNull()
            val uri = json["uri"].stringOrNull()
            val port = json["port"].flexInt()
            require(!protocol.isNullOrEmpty() && !address.isNullOrEmpty() && !uri.isNullOrEmpty() && port != null) {
                "Invalid connection data: missing required fields (protocol, address, port, or uri)"
            }
            return PlexConnection(
                protocol = protocol,
                address = address,
                port = port,
                uri = uri,
                local = json["local"].flexBool(),
                relay = json["relay"].flexBool(),
                ipv6 = json["IPv6"].flexBool(),
            )
        }
    }
}

/** A connection candidate: the connection and the URL to probe on it. */
data class PlexConnectionCandidate(
    val connection: PlexConnection,
    val url: String,
    val isPlexDirectUri: Boolean,
    val isHttps: Boolean,
)

/** A Plex Media Server as plex.tv's resources list it. [connections] holds the expanded list (LAN cleartext twins). */
data class PlexServer(
    override val name: String,
    val clientIdentifier: String,
    override val accessToken: String,
    val connections: List<PlexConnection>,
    override val owned: Boolean,
    val product: String? = null,
    val platform: String? = null,
    val lastSeenAt: Instant? = null,
) : PlexServerEntry {
    override val serverId: ServerId get() = ServerId(clientIdentifier)

    override val publishesLocalDirectConnection: Boolean get() = connections.any { it.local && !it.relay }

    /**
     * [plexNetworkClass] for the manager, which only tells remote and relay endpoints apart from the rest: an
     * unknown class (an unpublished LAN, private or cleartext URL) counts as local.
     */
    override fun networkClassForUrl(url: String): EndpointNetworkClass = when (plexNetworkClass(url)) {
        PlexNetworkClass.REMOTE -> EndpointNetworkClass.REMOTE
        PlexNetworkClass.RELAY -> EndpointNetworkClass.RELAY
        PlexNetworkClass.LOCAL, PlexNetworkClass.UNKNOWN -> EndpointNetworkClass.LOCAL
    }

    fun toJson(): JsonObject = buildJsonObject {
        put("name", name)
        put("clientIdentifier", clientIdentifier)
        put("accessToken", accessToken)
        put("connections", JsonArray(connections.map { it.toJson() }))
        put("owned", owned)
        put("product", product)
        put("platform", platform)
        put("lastSeenAt", lastSeenAt?.toString())
    }

    /**
     * The URL candidates in failover order: buckets https local, https remote, https relay, http local, http remote,
     * http relay, IPv4 before IPv6 inside each; unreachable addresses (`::`, link-local) skipped; URLs deduplicated.
     * With [restrictTo] remote or relay, LAN candidates are dropped when anything else remains (an off-LAN session
     * can't reach them).
     */
    fun prioritizedCandidates(
        excludeUrls: Set<String> = emptySet(),
        restrictTo: PlexNetworkClass? = null,
    ): List<PlexConnectionCandidate> {
        val seen = excludeUrls.toMutableSet()
        val buckets = List(6) { mutableListOf<PlexConnectionCandidate>() }
        fun bucket(c: PlexConnection, https: Boolean): Int = (if (https) 0 else 3) + when {
            c.relay -> 2
            c.local -> 0
            else -> 1
        }
        fun add(c: PlexConnection, url: String, plexDirect: Boolean, https: Boolean) {
            if (url.isEmpty() || !seen.add(url)) return
            buckets[bucket(c, https)] += PlexConnectionCandidate(c, url, plexDirect, https)
        }
        for (c in connections) {
            if (isUnreachableAddress(c.address)) continue
            add(c, c.uri, isPlexDirectUri(c.uri), c.protocol == "https")
            if (allowsHttpFallback(c)) add(c, httpFallbackUrl(c), plexDirect = false, https = false)
        }
        val all = buckets.flatMap { b -> b.filter { !it.connection.isIPv6 } + b.filter { it.connection.isIPv6 } }
        if (restrictTo == PlexNetworkClass.REMOTE || restrictTo == PlexNetworkClass.RELAY) {
            val filtered = all.filter { it.connection.networkClass != PlexNetworkClass.LOCAL }
            if (filtered.isNotEmpty()) return filtered
        }
        return all
    }

    /** The failover list with no preferred endpoint. */
    fun prioritizedEndpointUrls(): List<String> = prioritizedEndpointUrls("")

    /**
     * The failover list. [preferredFirst] (empty: none) leads unless it is a cleartext URL the server doesn't publish
     * on a public host (failover would send the token over it); its network class restricts the rest
     * ([prioritizedCandidates]).
     */
    override fun prioritizedEndpointUrls(preferredFirst: String): List<String> {
        val urls = mutableListOf<String>()
        val exclude = mutableSetOf<String>()
        var restrictTo: PlexNetworkClass? = null
        if (preferredFirst.isNotEmpty() && !isUnpublishedPublicCleartextUrl(preferredFirst)) {
            urls += preferredFirst
            exclude += preferredFirst
            restrictTo = plexNetworkClass(preferredFirst)
        }
        prioritizedCandidates(exclude, restrictTo).mapTo(urls) { it.url }
        return urls
    }

    /** The published connection's class; an unpublished `https` URL on a public host is remote; else unknown. */
    fun plexNetworkClass(url: String): PlexNetworkClass =
        candidateForUrl(url)?.connection?.networkClass ?: classifyCustomUrl(url)

    /** The candidate [url] names: a published URI or a LAN cleartext twin. A stale cleartext URL maps to none. */
    fun candidateForUrl(url: String): PlexConnectionCandidate? {
        for (c in connections) {
            if (c.uri == url) {
                val host = SimpleUri.parse(url)?.host?.lowercase().orEmpty()
                return PlexConnectionCandidate(c, url, "plex.direct" in host, url.startsWith("https://"))
            }
            if (allowsHttpFallback(c) && httpFallbackUrl(c) == url) return PlexConnectionCandidate(c, url, false, false)
        }
        return null
    }

    private fun isUnpublishedPublicCleartextUrl(url: String): Boolean {
        val uri = SimpleUri.parse(url) ?: return false
        if (!uri.scheme.equals("http", ignoreCase = true)) return false
        return candidateForUrl(url) == null && !isLocalOrPrivateHost(normalizedHost(uri.host))
    }

    private fun classifyCustomUrl(url: String): PlexNetworkClass {
        val uri = SimpleUri.parse(url) ?: return PlexNetworkClass.UNKNOWN
        if (!uri.scheme.equals("https", ignoreCase = true)) return PlexNetworkClass.UNKNOWN
        val host = normalizedHost(uri.host)
        if (host.isEmpty() || isLocalOrPrivateHost(host)) return PlexNetworkClass.UNKNOWN
        return PlexNetworkClass.REMOTE
    }

    companion object {
        /**
         * Parses a resources (or persisted) server: non-empty `name`, `clientIdentifier`, `accessToken` and
         * `connections` are required ([IllegalArgumentException] otherwise); invalid connections are skipped; LAN
         * https connections gain their cleartext twin, and twins older builds persisted for non-LAN endpoints are
         * dropped; equal endpoints are kept once, so persisting and re-parsing is idempotent.
         */
        fun fromJson(json: JsonObject): PlexServer {
            val name = json["name"].stringOrNull()
            val clientIdentifier = json["clientIdentifier"].stringOrNull()
            val accessToken = json["accessToken"].stringOrNull()
            val rawConnections = json["connections"] as? JsonArray
            require(
                !name.isNullOrEmpty() && !clientIdentifier.isNullOrEmpty() && !accessToken.isNullOrEmpty() &&
                    !rawConnections.isNullOrEmpty(),
            ) { "Invalid server data: missing required fields (name, clientIdentifier, accessToken, or connections)" }

            val parsed = rawConnections.mapNotNull { element ->
                (element as? JsonObject)?.let { runCatching { PlexConnection.fromJson(it) }.getOrNull() }
            }
            // plex.tv never publishes an http twin of an https endpoint, so an exact twin of a non-LAN sibling is a
            // synthetic fallback an older build persisted: it would send the token in cleartext across the internet.
            val stale = parsed.filter { it.protocol == "https" && !isLanConnection(it) }
                .mapTo(HashSet()) { it.toHttpFallback().endpointIdentity }
            val seen = HashSet<String>()
            val connections = mutableListOf<PlexConnection>()
            fun add(c: PlexConnection) {
                if (seen.add(c.endpointIdentity)) connections += c
            }
            for (c in parsed) {
                if (c.endpointIdentity in stale) continue
                add(c)
                if (allowsHttpFallback(c)) add(c.toHttpFallback())
            }
            require(connections.isNotEmpty()) { "Server has no valid connections" }

            return PlexServer(
                name = name,
                clientIdentifier = clientIdentifier,
                accessToken = accessToken,
                connections = connections,
                owned = json["owned"].flexBool(),
                product = optionalScalarString(json["product"]),
                platform = optionalScalarString(json["platform"]),
                lastSeenAt = json["lastSeenAt"].scalarString()?.let { runCatching { Instant.parse(it) }.getOrNull() },
            )
        }

        /** Phase-1 race tier: IPv4 direct 0, IPv6 direct 1, relay 2. */
        fun raceTier(connection: PlexConnection): Int = when {
            connection.relay -> 2
            connection.isIPv6 -> 1
            else -> 0
        }

        internal fun isLanConnection(c: PlexConnection): Boolean =
            c.local && !c.relay && isLocalOrPrivateHost(normalizedHost(c.address))

        /**
         * Every request carries `X-Plex-Token`, so a cleartext twin exists only where the path stays on the LAN: an
         * https, local, non-relay connection on a private address, reachable as a plex.direct name, an IP literal or
         * a native hostname on :32400.
         */
        internal fun allowsHttpFallback(c: PlexConnection): Boolean {
            if (c.protocol != "https" || !isLanConnection(c)) return false
            return isPlexDirectUri(c.uri) || isIpLiteral(c.address) || isNativePlexHostnameHttps(c)
        }

        internal fun httpFallbackUrl(c: PlexConnection): String =
            if (isNativePlexHostnameHttps(c)) c.uri.replaceFirst("https://", "http://") else c.httpDirectUrl

        internal fun isPlexDirectUri(uri: String): Boolean =
            SimpleUri.parse(uri)?.host?.lowercase()?.endsWith(".plex.direct") ?: (".plex.direct" in uri)

        internal fun isNativePlexHostnameHttps(c: PlexConnection): Boolean {
            if (c.protocol != "https" || c.port != 32400 || isIpLiteral(c.address)) return false
            val uri = SimpleUri.parse(c.uri) ?: return false
            if (uri.scheme != "https" || uri.query != null || uri.fragment != null) return false
            if (uri.port != c.port) return false
            if (uri.path.isNotEmpty() && uri.path != "/") return false
            val address = normalizedHost(c.address)
            return address.isNotEmpty() && uri.host.lowercase() == address
        }

        private fun isIpLiteral(address: String): Boolean = parseIpLiteral(normalizedHost(address)) != null

        /** IPv6 `::`, all-zero forms and link-local `fe80:` addresses: no client can reach them. */
        internal fun isUnreachableAddress(address: String): Boolean {
            val n = address.replace('-', ':').lowercase()
            if (n == "::" || ALL_ZERO.matches(n)) return true
            return n.startsWith("fe80:")
        }

        private val ALL_ZERO = Regex("^(0+:){7}0+$")

        private fun optionalScalarString(value: JsonElement?): String? = when (value) {
            null, JsonNull -> null
            is JsonPrimitive -> value.content
            else -> null
        }
    }
}

internal fun normalizedHost(host: String): String =
    (if (host.startsWith('[') && host.endsWith(']')) host.substring(1, host.length - 1) else host).lowercase()

/**
 * Private, loopback, link-local, CGNAT (Tailscale) and unspecified IPs; `localhost`, dotless names and the `.local`,
 * `.lan`, `.home.arpa`, `.internal` and `.ts.net` suffixes.
 */
internal fun isLocalOrPrivateHost(host: String): Boolean {
    val ip = parseIpLiteral(host)
    if (ip != null) return isPrivateOrLocalAddress(ip)
    if (host == "localhost" || '.' !in host) return true
    return LOCAL_SUFFIXES.any { host.endsWith(it) }
}

private val LOCAL_SUFFIXES = listOf(".local", ".lan", ".home.arpa", ".internal", ".ts.net")

private fun isPrivateOrLocalAddress(bytes: ByteArray): Boolean {
    val u = IntArray(bytes.size) { bytes[it].toInt() and 0xFF }
    if (u.size == 4) {
        val a = u[0]
        val b = u[1]
        return a == 0 || a == 10 || (a == 100 && b in 64..127) || a == 127 || (a == 169 && b == 254) ||
            (a == 172 && b in 16..31) || (a == 192 && b == 168)
    }
    val loopback = (0 until 15).all { u[it] == 0 } && u[15] == 1
    val unspecified = u.all { it == 0 }
    return loopback || unspecified || (u[0] and 0xFE) == 0xFC || (u[0] == 0xFE && (u[1] and 0xC0) == 0x80)
}
