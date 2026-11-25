package com.edde746.plezy.plex

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PlexServerConnectionCandidatesTest {
    private fun server(vararg connections: JsonObject): PlexServer = PlexServer.fromJson(
        buildJsonObject {
            put("name", "Home Server")
            put("clientIdentifier", "srv-1")
            put("accessToken", "token-1")
            put("owned", true)
            put("connections", JsonArray(connections.toList()))
        },
    )

    private fun conn(
        protocol: String,
        address: String,
        port: Int,
        uri: String,
        local: Boolean = false,
        relay: Boolean = false,
        ipv6: Boolean? = null,
    ) = buildJsonObject {
        put("protocol", protocol)
        put("address", address)
        put("port", port)
        put("uri", uri)
        put("local", local)
        put("relay", relay)
        if (ipv6 != null) put("IPv6", ipv6)
    }

    private val duck = "https://whereyaat.duckdns.org:32400"
    private val localPlexDirect = "https://192-168-1-50.abc.plex.direct:32400"
    private val remotePlexDirect = "https://203-0-113-10.abc.plex.direct:32400"
    private val relayPlexDirect = "https://198-51-100-7.abc.plex.direct:8443"

    @Test
    fun `does not add HTTP fallback for a custom remote Plex hostname on port 32400`() {
        val s = server(conn("https", "whereyaat.duckdns.org", 32400, duck))
        assertEquals(listOf(duck), s.connections.map { it.uri })
        assertEquals(listOf(duck), s.prioritizedEndpointUrls())
    }

    @Test
    fun `ignores a cached HTTP fallback for a custom remote Plex hostname`() {
        val s = server(conn("https", "whereyaat.duckdns.org", 32400, duck))
        assertEquals(PlexNetworkClass.UNKNOWN, s.plexNetworkClass("http://whereyaat.duckdns.org:32400"))
        assertEquals(listOf(duck), s.prioritizedEndpointUrls(preferredFirst = "http://whereyaat.duckdns.org:32400"))
    }

    @Test
    fun `adds HTTP fallbacks only for local non relay connections on private addresses`() {
        val publicLocal = "https://198-51-100-20.abc.plex.direct:32400"
        val s = server(
            conn("https", "192.168.1.50", 32400, localPlexDirect, local = true),
            conn("https", "203.0.113.10", 32400, remotePlexDirect),
            conn("https", "198.51.100.7", 8443, relayPlexDirect, relay = true),
            // A server with a public interface: plex.tv flags it local, but the address is reachable from anywhere.
            conn("https", "198.51.100.20", 32400, publicLocal, local = true),
        )
        assertEquals(
            listOf(
                localPlexDirect, publicLocal, remotePlexDirect, relayPlexDirect,
                "http://192.168.1.50:32400", "http://192-168-1-50.abc.plex.direct:32400",
            ),
            s.prioritizedEndpointUrls(),
        )
        assertEquals(
            listOf("http://192-168-1-50.abc.plex.direct:32400"),
            s.connections.filter { it.protocol == "http" }.map { it.uri },
        )
        for (url in listOf(
            "http://203.0.113.10:32400", "http://198.51.100.7:8443", "http://198.51.100.20:32400",
            "http://203-0-113-10.abc.plex.direct:32400",
        )) {
            assertEquals(PlexNetworkClass.UNKNOWN, s.plexNetworkClass(url), url)
            assertFalse(url in s.prioritizedEndpointUrls(preferredFirst = url), url)
        }
    }

    @Test
    fun `drops cleartext remote and relay fallbacks persisted by older builds`() {
        val s = server(
            conn("https", "203.0.113.10", 32400, remotePlexDirect),
            conn("http", "203.0.113.10", 32400, "http://203-0-113-10.abc.plex.direct:32400"),
            conn("https", "198.51.100.7", 8443, relayPlexDirect, relay = true),
            conn("http", "198.51.100.7", 8443, "http://198-51-100-7.abc.plex.direct:8443", relay = true),
            conn("https", "whereyaat.duckdns.org", 32400, duck),
            conn("http", "whereyaat.duckdns.org", 32400, "http://whereyaat.duckdns.org:32400"),
        )
        val expected = listOf(remotePlexDirect, relayPlexDirect, duck)
        assertEquals(expected, s.connections.map { it.uri })
        assertEquals(listOf(remotePlexDirect, duck, relayPlexDirect), s.prioritizedEndpointUrls())
        assertEquals(expected, PlexServer.fromJson(s.toJson()).connections.map { it.uri })
    }

    @Test
    fun `keeps a server published cleartext remote connection`() {
        val s = server(conn("http", "203.0.113.10", 32400, "http://203.0.113.10:32400"))
        assertEquals(listOf("http://203.0.113.10:32400"), s.prioritizedEndpointUrls())
        assertEquals(PlexNetworkClass.REMOTE, s.plexNetworkClass("http://203.0.113.10:32400"))
    }

    @Test
    fun `does not add HTTP fallback for standard HTTPS reverse proxy hostname`() {
        val s = server(conn("https", "plex.example.com", 443, "https://plex.example.com"))
        val urls = s.prioritizedEndpointUrls()
        assertFalse("http://plex.example.com" in s.connections.map { it.uri })
        assertTrue("https://plex.example.com" in urls)
        assertFalse("http://plex.example.com:443" in urls)
    }

    @Test
    fun `does not add HTTP fallback for path based HTTPS hostname`() {
        val s = server(conn("https", "plex.example.com", 32400, "https://plex.example.com:32400/plex"))
        val urls = s.prioritizedEndpointUrls()
        assertFalse("http://plex.example.com:32400/plex" in s.connections.map { it.uri })
        assertTrue("https://plex.example.com:32400/plex" in urls)
        assertFalse("http://plex.example.com:32400" in urls)
    }

    @Test
    fun `does not add HTTP fallback when native port is not in the URI`() {
        val s = server(conn("https", "plex.example.com", 32400, "https://plex.example.com"))
        val urls = s.prioritizedEndpointUrls()
        assertFalse("http://plex.example.com" in s.connections.map { it.uri })
        assertTrue("https://plex.example.com" in urls)
        assertFalse("http://plex.example.com:32400" in urls)
    }

    @Test
    fun `treats custom public HTTPS preferred endpoint as remote for failover filtering`() {
        val preferred = "https://plex.example.com"
        val s = server(
            conn("https", "192.168.1.50", 32400, localPlexDirect, local = true),
            conn("https", "203.0.113.10", 32400, remotePlexDirect),
        )
        val urls = s.prioritizedEndpointUrls(preferredFirst = preferred)
        assertEquals(PlexNetworkClass.REMOTE, s.plexNetworkClass(preferred))
        assertEquals(preferred, urls.first())
        assertTrue(remotePlexDirect in urls)
        assertFalse(localPlexDirect in urls)
        assertFalse("http://192.168.1.50:32400" in urls)
    }

    @Test
    fun `local looking Tailscale CGNAT and MagicDNS preferred endpoints are not remote`() {
        for (preferred in listOf("https://plex.lan", "https://100.90.80.70:32400", "https://plex.tailnet.ts.net:32400")) {
            val s = server(conn("https", "192.168.1.50", 32400, localPlexDirect, local = true))
            val urls = s.prioritizedEndpointUrls(preferredFirst = preferred)
            assertEquals(PlexNetworkClass.UNKNOWN, s.plexNetworkClass(preferred), preferred)
            assertEquals(preferred, urls.first())
            assertTrue(localPlexDirect in urls, preferred)
        }
    }

    @Test
    fun `orders IPv4 candidates before IPv6 siblings within each failover bucket`() {
        val ipv4 = localPlexDirect
        val flagged = "https://fd21-0-0-0-0-0-0-1.abc.plex.direct:32400"
        val unflagged = "https://fd21-0-0-0-0-0-0-2.abc.plex.direct:32400"
        val s = server(
            conn("https", "fd21::1", 32400, flagged, local = true, ipv6 = true),
            conn("https", "fd21::2", 32400, unflagged, local = true),
            conn("https", "192.168.1.50", 32400, ipv4, local = true),
        )
        assertEquals(
            listOf(
                ipv4, flagged, unflagged,
                "http://192.168.1.50:32400", "http://192-168-1-50.abc.plex.direct:32400",
                "http://[fd21::1]:32400", "http://fd21-0-0-0-0-0-0-1.abc.plex.direct:32400",
                "http://[fd21::2]:32400", "http://fd21-0-0-0-0-0-0-2.abc.plex.direct:32400",
            ),
            s.prioritizedEndpointUrls(),
        )
    }

    @Test
    fun `persisting and re parsing a server does not grow its expanded connection list`() {
        val parsed = server(
            conn("https", "192.168.1.50", 32400, localPlexDirect, local = true),
            conn("http", "192.168.1.50", 32400, "http://192.168.1.50:32400", local = true),
        )
        val expanded = listOf(localPlexDirect, "http://192-168-1-50.abc.plex.direct:32400", "http://192.168.1.50:32400")
        val reparsed = PlexServer.fromJson(parsed.toJson())
        val rereparsed = PlexServer.fromJson(reparsed.toJson())
        assertEquals(expanded, parsed.connections.map { it.uri })
        assertEquals(expanded, reparsed.connections.map { it.uri })
        assertEquals(expanded, rereparsed.connections.map { it.uri })
        assertEquals(listOf(true, true, true), reparsed.connections.map { it.local })
        assertEquals(parsed.prioritizedEndpointUrls(), reparsed.prioritizedEndpointUrls())
    }

    @Test
    fun `unreachable IPv6 addresses yield no candidate`() {
        val s = server(
            conn("https", "fe80::1", 32400, "https://fe80-0-0-0-0-0-0-1.abc.plex.direct:32400", local = true),
            conn("https", "192.168.1.50", 32400, localPlexDirect, local = true),
        )
        assertEquals(listOf(localPlexDirect, "http://192.168.1.50:32400"), s.prioritizedCandidates().map { it.url }.take(2))
        assertTrue(s.prioritizedCandidates().none { "fe80" in it.url })
    }

    @Test
    fun `server parse tolerates scalar drift and requires a usable connection`() {
        val s = PlexServer.fromJson(
            buildJsonObject {
                put("name", "S")
                put("clientIdentifier", "id")
                put("accessToken", "t")
                put("owned", "1")
                put("product", 7)
                put("platform", true)
                put(
                    "connections",
                    JsonArray(
                        listOf(
                            buildJsonObject { put("protocol", "https") },
                            buildJsonObject {
                                put("protocol", "https"); put("address", "203.0.113.10"); put("port", "32400")
                                put("uri", remotePlexDirect); put("local", 0); put("relay", "false")
                            },
                        ),
                    ),
                )
            },
        )
        assertTrue(s.owned)
        assertEquals("7", s.product)
        assertEquals("true", s.platform)
        assertEquals(listOf(remotePlexDirect), s.connections.map { it.uri })
        kotlin.test.assertFailsWith<IllegalArgumentException> {
            PlexServer.fromJson(
                buildJsonObject {
                    put("name", "S"); put("clientIdentifier", "id"); put("accessToken", "t")
                    put("connections", JsonArray(listOf(buildJsonObject { put("protocol", "https") })))
                },
            )
        }
    }
}
