package com.edde746.plezy.watch

import com.edde746.plezy.log.Log
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.engine.mock.respondError
import io.ktor.client.request.get
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.test.runTest
import party.openwatch.Relays
import party.openwatch.formatCode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class WatchPartyRelaysTest {
    private val http = HttpClient(MockEngine { respondError(HttpStatusCode.NotFound) })

    private fun canonical(input: String) = WatchPartyRelays.canonicalBaseUrl(input)

    @Test
    fun lowerCasesSchemeAndHostKeepsPortAndPathCaseDropsTrailingSlashes() {
        assertEquals("https://relay.example.test/path", canonical("  HTTPS://Relay.Example.Test/path///  "))
        assertEquals("http://relay.example.test:8080/Prefix", canonical("HTTP://Relay.Example.Test:8080/Prefix/"))
        assertEquals("http://127.0.0.1:19030", canonical("http://127.0.0.1:19030"))
    }

    @Test
    fun dropsADefaultPort() {
        assertEquals("https://relay.example.test", canonical("https://relay.example.test:443"))
        assertEquals("http://relay.example.test", canonical("http://relay.example.test:80/"))
    }

    @Test
    fun keepsTheBracketsOfAnIpv6LiteralSoTheWebSocketUrlStillNamesTheHost() {
        val base = canonical("http://[::1]:8080")
        assertEquals("http://[::1]:8080", base)
        assertEquals("ws://[::1]:8080/v1/ws", WatchRelayChoice(http).relaysFor(base).list.single().url)
    }

    @Test
    fun refusesWhatTheSdkCannotUse() {
        for (
        input in listOf(
            "", "   ", "relay.example.test", "ws://relay.example.test", "wss://relay.example.test", "ftp://relay.example.test",
            "https://", "https:///path", "https://relay.example.test/path?wrong=route", "https://relay.example.test/#fragment",
            "https://user:secret@relay.example.test", "http://[not a host",
        )
        ) {
            assertNull(canonical(input), input)
        }
    }

    @Test
    fun aCanonicalBaseIsItsOwnCanonicalForm() {
        for (input in listOf("https://relay.example.test/path", "http://relay.example.test:8080", "https://h/a%20b")) {
            val base = canonical(input)!!
            assertEquals(base, canonical(base), input)
        }
    }

    @Test
    fun nullIsThePublicRelays() {
        val relays = WatchRelayChoice(http).relaysFor(null)
        assertTrue(relays.list.isNotEmpty())
        assertTrue(relays.list.all { it.url.startsWith("wss://") })
    }

    @Test
    fun thePublicRelaysAreNaEuAndAsiaEachOwningTheCodesOfItsFirstSymbols() {
        val relays = WatchRelayChoice(http).relaysFor(null)
        assertEquals(
            listOf(
                Triple("na", "wss://na.relay.openwatch.party/v1/ws", "2345678"),
                Triple("eu", "wss://eu.relay.openwatch.party/v1/ws", "9ABCDEF"),
                Triple("asia", "wss://asia.relay.openwatch.party/v1/ws", "GHJKMNP"),
            ),
            relays.list.map { Triple(it.id, it.url, it.prefixes) },
        )
        assertEquals("na", relays.relayFor("2ABCDE")?.id)
        assertEquals("eu", relays.relayFor("f2k-m3n")?.id)
        assertEquals("asia", relays.relayFor("K7MQ2X")?.id)
        assertNull(relays.relayFor("Q2K7MX"), "no public relay owns Q")
    }

    @Test
    fun aCustomBaseIsTheOnlyRelayOnItsWebSocketPath() {
        val choice = WatchRelayChoice(http)
        assertEquals("ws://127.0.0.1:19030/v1/ws", choice.relaysFor("http://127.0.0.1:19030").list.single().url)
        assertEquals("wss://relay.example.test/prefix/v1/ws", choice.relaysFor("https://relay.example.test/prefix").list.single().url)
    }

    @Test
    fun aCustomRelayOwnsEveryCode() {
        val relays = WatchRelayChoice(http).relaysFor("https://relay.example.test")
        for (code in listOf("222222", "ZZZZZZ", "K7MQ2X")) assertSame(relays.list.single(), relays.relayFor(code), code)
    }

    @Test
    fun theRelaysAreKeptUntilTheSettingChanges() {
        val choice = WatchRelayChoice(http)
        val public = choice.relaysFor(null)
        assertSame(public, choice.relaysFor(null))
        val custom = choice.relaysFor("https://relay.example.test")
        assertSame(custom, choice.relaysFor("https://relay.example.test"))
        assertNotEquals(public, choice.relaysFor(null))
    }

    @Test
    fun publicRelaysShareOneScopeEachCustomBaseHasItsOwnStableOne() {
        assertEquals("public", WatchPartyRelays.relayScopeOf(null))
        val a = WatchPartyRelays.relayScopeOf("https://relay-a.example.test")
        val b = WatchPartyRelays.relayScopeOf("https://relay-b.example.test")
        assertNotEquals(a, b)
        assertNotEquals("public", a)
        assertEquals(a, WatchPartyRelays.relayScopeOf("https://relay-a.example.test"))
        assertTrue(Regex("^[0-9a-f]{64}$").matches(a), "the scope must not hold the URL itself")
    }

    @Test
    fun acceptsACodeAsTypedOrPasted() {
        assertEquals("K7MQ2X", WatchPartyRelays.normalizeRoomCode("K7M-Q2X"))
        assertEquals("K7MQ2X", WatchPartyRelays.normalizeRoomCode("k7mq2x"))
        assertEquals("K7MQ2X", WatchPartyRelays.normalizeRoomCode(" k7m q2x\n"))
        assertEquals("K7MQ2X", WatchPartyRelays.normalizeRoomCode("K7M\u2013Q2X"))
    }

    @Test
    fun refusesWhatIsNotSixSymbolsOfTheCodeAlphabet() {
        for (input in listOf("", "K7MQ2", "K7MQ2XX", "ROOM12", "K7M-Q2I", "K7M_Q2X", "K7MQ2X!", "ÄBCDEF", "ABCDE")) {
            assertNull(WatchPartyRelays.normalizeRoomCode(input), input)
        }
    }

    @Test
    fun agreesWithTheSdkFormatting() {
        assertEquals("K7M-Q2X", formatCode(WatchPartyRelays.normalizeRoomCode("k7m q2x")!!))
        assertEquals("K7M-Q2X", WatchPartyRelays.formatRoomCode("K7MQ2X"))
    }

    @Test
    fun roomBoundsAreTheSdkLimits() {
        assertEquals(7L * 24 * 60 * 60 * 1000, WatchPartyRelays.MAX_OFFSET_MS)
        assertEquals(0.5 to 2.0, WatchPartyRelays.MIN_RATE to WatchPartyRelays.MAX_RATE)
    }

    @Test
    fun aTypedCodeShowsAsK7mQ2xUpperCaseSeparatorsDroppedSixSymbolsAtMost() {
        fun typed(text: String) = WatchPartyRelays.typedRoomCode(text).text
        assertEquals("K", typed("k"))
        assertEquals("K7M", typed("k7m"))
        assertEquals("K7M-Q", typed("k7mq"))
        assertEquals("K7M-Q2X", typed("k7m q2x"))
        assertEquals("K7M-Q2X", typed("k7m\u2013q2x"))
        assertEquals(TypedRoomCode("K7M-Q2X", 7), WatchPartyRelays.typedRoomCode("K7M-Q2XYZ"))
        assertEquals("K7M-Q0X", typed("k7m-q0x"), "letters outside the alphabet stay so Join can refuse them")
        // A symbol typed in the middle keeps the caret after it.
        assertEquals(TypedRoomCode("K7X-MQ2", 3), WatchPartyRelays.typedRoomCode("K7xM-Q2", caret = 3))
    }

    @Test
    fun eachRelayConnectIsLoggedWithTheRelayIdAndItsTimeAndAFailureWithItsCause() = runTest {
        val lines = mutableListOf<String>()
        val sink = Log.sink
        val level = Log.minLevel
        Log.sink = Log.Sink { lvl, tag, message, error -> lines += "${lvl.name} $tag $message${if (error != null) " [cause]" else ""}" }
        Log.minLevel = Log.Level.DEBUG
        try {
            var relays: Relays? = null
            val client = HttpClient(
                MockEngine { request ->
                    if (request.url.host == "down.example.test") throw IllegalStateException("connection refused")
                    respond("", HttpStatusCode.SwitchingProtocols)
                },
            ) { install(relayConnectLog({ relays }, testScheduler.timeSource)) }
            relays = Relays.public(client)
            client.get("wss://eu.relay.openwatch.party/v1/ws")
            client.get("https://openwatch.party/relays.json")
            assertFailsWith<IllegalStateException> { client.get("ws://down.example.test/v1/ws") }
            assertEquals(
                listOf(
                    "DEBUG WatchTogether relay eu connected in 0 ms",
                    "WARN WatchTogether relay down.example.test failed to connect after 0 ms [cause]",
                ),
                lines,
            )
        } finally {
            Log.sink = sink
            Log.minLevel = level
        }
    }
}
