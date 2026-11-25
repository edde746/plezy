package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaBrowserDialect

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class JellyfinLanDiscoveryTest {
    private fun parse(json: String, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN) =
        JellyfinLanDiscovery.parseResponse(json.encodeToByteArray(), dialect)

    @Test fun parsesJellyfinReply() = assertEquals(
        DiscoveredJellyfinServer("http://192.168.1.20:8096", "srv-1", "Home", MediaBrowserDialect.JELLYFIN),
        parse("""{"Address":"http://192.168.1.20:8096/","Id":"srv-1","Name":"Home"}"""),
    )

    @Test fun stampsAskedForDialectOnEmbyReply() = assertEquals(
        DiscoveredJellyfinServer("http://127.0.0.1:8096", "emby-1", "7befeeb2e8c9", MediaBrowserDialect.EMBY),
        parse("""{"Address":"http://127.0.0.1:8096","Id":"emby-1","Name":"7befeeb2e8c9"}""", MediaBrowserDialect.EMBY),
    )

    @Test fun acceptsLowercaseKeysAndTrims() = assertEquals(
        DiscoveredJellyfinServer("http://h:8096", "x", "N", MediaBrowserDialect.JELLYFIN),
        parse("""{"address":" http://h:8096 ","id":" x ","name":" N "}"""),
    )

    @Test fun doesNotExpandBareAddresses() =
        assertEquals("192.168.1.20", parse("""{"Address":"192.168.1.20","Id":"srv-1","Name":"Home"}""")?.address)

    @Test fun ignoresMalformedReplies() {
        assertNull(parse("not json"))
        assertNull(parse("""{"Address":"http://x"}"""))
        assertNull(parse("""{"Address":"http://x","Id":"  ","Name":"n"}"""))
        assertNull(parse("""[1]"""))
    }

    @Test fun sortsDeterministically() {
        val sorted = JellyfinLanDiscovery.sort(listOf(
            DiscoveredJellyfinServer("http://192.168.1.20:8096", "srv-2", "Home", MediaBrowserDialect.JELLYFIN),
            DiscoveredJellyfinServer("http://192.168.1.10:8096", "srv-3", "Office", MediaBrowserDialect.JELLYFIN),
            DiscoveredJellyfinServer("http://192.168.1.20:8096", "srv-1", "Home", MediaBrowserDialect.EMBY),
        ))
        assertEquals(listOf("srv-1", "srv-2", "srv-3"), sorted.map { it.id })
    }
}
