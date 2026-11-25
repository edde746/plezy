package com.edde746.plezy.log

import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class LogRedactionTest {
    @BeforeTest
    @AfterTest
    fun reset() = LogRedaction.clear()

    /** The registry and the media-server shapes alone, without [Redactor]'s URL and key shapes. */
    private fun redact(text: String) = LogRedaction.redactShapes(LogRedaction.redactLiterals(text))

    private fun assertGone(result: String, vararg secrets: String) {
        for (secret in secrets) assertFalse(secret in result, "'$secret' survived: $result")
    }

    // Nothing registered.

    @Test
    fun `plain text passes through unchanged`() = assertEquals("hello world", redact("hello world"))

    @Test
    fun `an X Plex Token query parameter goes without registration and keeps the next parameter`() {
        val result = redact("https://example.com/api?X-Plex-Token=abc123secret&foo=bar")
        assertGone(result, "abc123secret")
        assertTrue("X-Plex-Token=…" in result)
        assertTrue("foo=bar" in result)
    }

    @Test
    fun `X Plex Token redaction ignores case`() {
        val result = redact("x-plex-token=SECRET&other=1")
        assertGone(result, "SECRET")
        assertTrue("…" in result)
    }

    @Test
    fun `a Jellyfin api key query parameter goes without registration`() {
        val result = redact("https://example.com/Items/1/Images/Primary?api_key=jelly-token-123&fmt=jpg")
        assertGone(result, "jelly-token-123")
        assertTrue("api_key=…" in result)
        assertTrue("fmt=jpg" in result)
    }

    @Test
    fun `ApiKey redaction ignores case`() {
        val result = redact("https://example.com/Items?ApiKey=topsecret&z=1")
        assertGone(result, "topsecret")
        assertTrue("…" in result)
    }

    @Test
    fun `a Quick Connect secret goes without registration`() {
        val result = redact("https://example.com/QuickConnect/Connect?secret=quick-secret-123&next=1")
        assertGone(result, "quick-secret-123")
        assertTrue("secret=…" in result)
        assertTrue("next=1" in result)
    }

    @Test
    fun `a Quick Connect secret goes whatever its case and keeps other parameters`() {
        val result = redact("SECRET=a%2Fb%20c&Authenticated=false")
        assertGone(result, "a%2Fb%20c")
        assertTrue("…" in result)
        assertTrue("Authenticated=false" in result)
    }

    @Test
    fun `a Plex Home pin goes without registration`() {
        val result = redact("POST https://clients.plex.tv/api/v2/home/users/uuid/switch?X-Plex-Token=tok&pin=1234 → 201")
        assertGone(result, "pin=1234")
        assertTrue("pin=…" in result)
    }

    @Test
    fun `pin redaction ignores case and leaves compound parameters`() {
        val result = redact("PIN=0000&checkPin=abc&next=1")
        assertGone(result, "PIN=0000")
        assertTrue("…" in result)
        assertTrue("checkPin=abc" in result)
        assertTrue("next=1" in result)
    }

    @Test
    fun `an X Emby Token header goes`() {
        val result = redact("X-Emby-Token: emby-secret")
        assertGone(result, "emby-secret")
        assertTrue("…" in result)
    }

    @Test
    fun `the MediaBrowser authorization token goes and its other fields stay`() {
        val result = redact("""Authorization: MediaBrowser Client="Plezy", Device="Plezy", DeviceId="dev-1", Version="1.0", Token="opaque-jellyfin-token"""")
        assertGone(result, "opaque-jellyfin-token")
        assertTrue("""Token="…"""" in result)
        assertTrue("""Client="Plezy"""" in result)
    }

    @Test
    fun `dotted IPv4 addresses keep their first and last octet`() = assertEquals("connect to 192.x.x.42 now", redact("connect to 192.168.1.42 now"))

    @Test
    fun `dashed IPv4 addresses of plex direct hosts keep their first and last octet`() {
        val result = redact("host 10-0-0-5.plex.direct")
        assertGone(result, "10-0-0-5")
        assertTrue("10-x-x-5" in result)
    }

    @Test
    fun `three dotted numbers are no address`() = assertEquals("version 1.2.3 was released", redact("version 1.2.3 was released"))

    @Test
    fun `bearer and basic authorization go in every serialized form`() {
        val cases = listOf(
            Triple("Authorization: Bearer bearer.value-_/+~==\nStatus: 401", "bearer.value-_/+~==", "Status: 401"),
            Triple("aUtHoRiZaTiOn = Basic basic.value-_/+~==, status=denied", "basic.value-_/+~==", "status=denied"),
            Triple("{Authorization: Bearer map.value-_/+~==, operation: connect}", "map.value-_/+~==", "operation: connect"),
            Triple("""{"authorization":"Basic json.value-_/+~==","status":"denied"}""", "json.value-_/+~==", """"status":"denied""""),
            Triple("{'Authorization' = 'Bearer quoted.value-_/+~=='; next=ok}", "quoted.value-_/+~==", "next=ok"),
        )
        for ((input, secret, neighbor) in cases) {
            val result = redact(input)
            assertFalse(secret in result, input)
            assertTrue("…" in result, input)
            assertTrue(neighbor in result, input)
        }
    }

    @Test
    fun `opaque authorization and several credential fields go`() {
        val result = redact(
            "Authorization: opaque-auth-value\n" +
                "Proxy-Authorization: Basic proxy.value+/==\n" +
                """{"password":"json-password","client_secret":"json-client-secret","status":"failed"}""",
        )
        assertGone(result, "opaque-auth-value", "proxy.value+/==", "json-password", "json-client-secret")
        assertTrue(result.count { it == '…' } >= 4)
        assertTrue(""""status":"failed"""" in result)
    }

    @Test
    fun `exact credential query and header keys go and their neighbours stay`() {
        val result = redact(
            "GET /items?api_key=query-secret&refresh_token=refresh-secret&token_count=42\n" +
                "Cookie: session=cookie-secret; refresh=second-cookie-secret\n" +
                "X-Api-Key: header-secret\n" +
                "Status: 403",
        )
        assertGone(result, "query-secret", "refresh-secret", "cookie-secret", "second-cookie-secret", "header-secret")
        assertTrue("token_count=42" in result)
        assertTrue("Status: 403" in result)
    }

    @Test
    fun `unquoted structured values with hashes go whole`() {
        val cases = listOf(
            "{password: left#right}" to "{password: …}",
            """{password: left"middle#right, status: denied}""" to "{password: …, status: denied}",
            "{password: left'middle#right; status: denied}" to "{password: …; status: denied}",
            "request couldn't serialize {password: left{middle#right, status: denied}" to
                "request couldn't serialize {password: …, status: denied}",
            "password: left#right # external comment" to "password: … # external comment",
        )
        for ((input, output) in cases) assertEquals(output, redact(input), input)
    }

    @Test
    fun `nested structured values go without their safe neighbours`() {
        val cases = listOf(
            "{password: {primary: left#right, quoted: 'comma, hash# and } brace'}, status: denied}" to "{password: …, status: denied}",
            """{secret: [left#right, {"nested": "quote\", comma, # and ] bracket"}], status: denied}""" to "{secret: …, status: denied}",
            """{"password":"left,#right} still secret","status":"denied"}""" to """{"password":"…","status":"denied"}""",
        )
        for ((input, output) in cases) assertEquals(output, redact(input), input)
    }

    @Test
    fun `URL fragments and external comments stay`() {
        assertEquals(
            "GET https://example.test/path?password=…#public-fragment",
            redact("GET https://example.test/path?password=left#public-fragment"),
        )
        assertEquals(
            """{"endpoint":"https://example.test/{item}?password=…#public-fragment","status":"denied"}""",
            redact("""{"endpoint":"https://example.test/{item}?password=left#public-fragment","status":"denied"}"""),
        )
        assertEquals("password=… # configuration comment", redact("password=left # configuration comment"))
    }

    @Test
    fun `URL userinfo goes and the destination stays`() {
        val result = redact("connect https://synthetic-user:synthetic-password@example.test:8443/library?mode=fast")
        assertGone(result, "synthetic-user", "synthetic-password")
        assertTrue("https://…@example.test:8443/library?mode=fast" in result)
    }

    @Test
    fun `prose and token count fields stay`() {
        val input = "authorization failed after token refresh; " +
            "token_count=42 token-count=43 tokenCount=44 max_tokens=45 " +
            "input_tokens=46 outputTokens=47 notsecret=visible " +
            "authorizationMode=interactive"
        assertEquals(input, redact(input))
    }

    // Registered tokens.

    @Test
    fun `a registered token goes verbatim`() {
        LogRedaction.registerToken("abc-secret-XYZ")
        val result = redact("Authorization: Bearer abc-secret-XYZ")
        assertGone(result, "abc-secret-XYZ")
        assertTrue("…" in result)
    }

    @Test
    fun `a registered token goes in its URL encoded form`() {
        LogRedaction.registerToken("a b/c")
        val result = redact("q=a+b%2Fc&z=1")
        assertEquals("q=…&z=1", result)
    }

    @Test
    fun `blank tokens register nothing`() {
        LogRedaction.registerToken(null)
        LogRedaction.registerToken("")
        LogRedaction.registerToken("   ")
        assertEquals("plain text", redact("plain text"))
    }

    @Test
    fun `a token registers trimmed`() {
        LogRedaction.registerToken("  TRIMMED  ")
        val result = redact("value=TRIMMED here")
        assertGone(result, "TRIMMED")
        assertTrue("…" in result)
    }

    // Registered server URLs.

    @Test
    fun `a registered server URL goes whole`() {
        LogRedaction.registerServerUrl("https://my-cool-plex-server.example.com")
        val result = redact("GET https://my-cool-plex-server.example.com/library/sections")
        assertGone(result, "my-cool-plex-server", "https://")
        assertTrue("…" in result)
    }

    @Test
    fun `the dotted host of a registered URL goes in a bare error message too`() {
        LogRedaction.registerServerUrl("https://family-media.private.example/jellyfin")
        assertGone(redact("family-media.private.example: Name or service not known"), "family-media.private.example")
    }

    @Test
    fun `an IPv4 host URL is not registered and its address is masked`() {
        LogRedaction.registerServerUrl("http://192.168.1.1:32400")
        val result = redact("connecting to http://192.168.1.1:32400/api")
        assertTrue("192.x.x.1" in result)
        assertFalse("…" in result)
    }

    @Test
    fun `blank URLs register nothing`() {
        LogRedaction.registerServerUrl(null)
        LogRedaction.registerServerUrl("")
        assertEquals("plain", redact("plain"))
    }

    @Test
    fun `a URL registers with and without its trailing slash`() {
        LogRedaction.registerServerUrl("https://server.example.com/")
        assertGone(redact("host https://server.example.com"), "server.example.com")
        assertGone(redact("host https://server.example.com/"), "server.example.com")
    }

    @Test
    fun `a registered plex direct URL goes despite its address label`() {
        val hash = "0123456789abcdef0123456789abcdef"
        LogRedaction.registerServerUrl("https://203-0-113-10.$hash.plex.direct:32400")
        val result = redact("GET https://203-0-113-10.$hash.plex.direct:32400/library/sections")
        assertTrue(result.startsWith("GET …"), result)
        assertGone(result, hash, "203-")
    }

    @Test
    fun `an unregistered plex direct host loses its server hash`() {
        val hash = "0123456789ABCDEF0123456789abcdef"
        assertEquals(
            "probe https://192-x-x-50.….plex.direct:32400 failed",
            redact("probe https://192-168-1-50.$hash.plex.direct:32400 failed"),
        )
    }

    @Test
    fun `mpvs escaped echo of a registered URL goes`() {
        LogRedaction.registerServerUrl("https://server.example.com")
        val result = redact("""Setting option 'sub-files' = 'https\://server.example.com/Videos/1/Subtitles/0/0/Stream.srt' (flags = 16)""")
        assertGone(result, "server.example.com")
        assertTrue("…" in result)
    }

    // Other values.

    @Test
    fun `a registered value goes`() {
        LogRedaction.registerCustomValue("SuperSecret42")
        val result = redact("debug: SuperSecret42 leaked")
        assertGone(result, "SuperSecret42")
        assertTrue("…" in result)
    }

    @Test
    fun `regex metacharacters in a registered value match literally`() {
        LogRedaction.registerCustomValue("a.b+c?d")
        val result = redact("found a.b+c?d in stream")
        assertGone(result, "a.b+c?d")
        assertTrue("…" in result)
    }

    @Test
    fun `blank values register nothing`() {
        LogRedaction.registerCustomValue(null)
        LogRedaction.registerCustomValue("")
        assertEquals("xyz", redact("xyz"))
    }

    @Test
    fun `the longest registered literal wins`() {
        LogRedaction.registerCustomValue("abcd")
        LogRedaction.registerCustomValue("abcdef")
        assertEquals("value=…", redact("value=abcdef"))
    }

    @Test
    fun `every kind goes in one pass`() {
        LogRedaction.registerToken("TOKEN_VALUE")
        LogRedaction.registerServerUrl("https://plex.example.com")
        LogRedaction.registerCustomValue("CUSTOM")
        val result = redact("TOKEN_VALUE host=https://plex.example.com extra=CUSTOM ip=10.0.0.1")
        assertGone(result, "TOKEN_VALUE", "plex.example.com", "CUSTOM", "10.0.0.1")
        assertEquals("… host=… extra=… ip=10.x.x.1", result)
    }

    @Test
    fun `the oldest of more than 50 tokens is forgotten first`() {
        for (i in 0..50) LogRedaction.registerToken("tok-$i-value")
        assertEquals("tok-0-value …", redact("tok-0-value tok-50-value"))
    }

    @Test
    fun `past 40 URL literals the oldest servers forms are forgotten first`() {
        // Each server registers five literals: with and without its slash, its host and both mpv escaped forms.
        for (i in 0..8) LogRedaction.registerServerUrl("https://s$i.example")
        assertEquals("s0.example …", redact("s0.example s1.example"))
    }

    @Test
    fun `the oldest of more than 50 custom values is forgotten first`() {
        for (i in 0..50) LogRedaction.registerCustomValue("custom-$i-value")
        assertEquals("custom-0-value …", redact("custom-0-value custom-50-value"))
    }

    @Test
    fun `clearing forgets every registered value`() {
        LogRedaction.registerToken("TOK")
        LogRedaction.registerCustomValue("VAL")
        LogRedaction.registerServerUrl("https://example.com")
        LogRedaction.clear()
        assertEquals("TOK VAL https://example.com", redact("TOK VAL https://example.com"))
    }

    @Test
    fun `the log redacts registered literals and credentials in message and error alike`() {
        LogRedaction.registerToken("registered-token-sentinel")
        LogRedaction.registerCustomValue("registered-error-sentinel")
        val written = mutableListOf<String>()
        val sink = Log.sink
        Log.sink = Log.Sink { _, _, message, error -> written += "$message\n$error" }
        try {
            Log.e("test", IllegalStateException("category=remote detail=registered-error-sentinel {\"password\":\"pw-value\",\"status\":401}")) {
                "connect operation Authorization: Bearer message.value-_/+~== credential=registered-token-sentinel status=pending"
            }
        } finally {
            Log.sink = sink
        }
        val text = written.single()
        assertGone(text, "registered-token-sentinel", "registered-error-sentinel", "message.value-_/+~==", "pw-value")
        for (kept in listOf("connect operation", "status=pending", "category=remote", "\"status\":401")) assertTrue(kept in text, text)
    }
}
