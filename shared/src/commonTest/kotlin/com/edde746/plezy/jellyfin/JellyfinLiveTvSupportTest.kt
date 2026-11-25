package com.edde746.plezy.jellyfin

import com.edde746.plezy.data.testData
import com.edde746.plezy.livetv.FavoriteChannelPersistenceMode
import com.edde746.plezy.livetv.liveTvDvr
import com.edde746.plezy.livetv.liveTvServerEntries
import com.edde746.plezy.model.MediaBrowserDialect
import io.ktor.utils.io.errors.IOException
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

class JellyfinLiveTvSupportTest {
    private val data = testData()

    @AfterTest
    fun closeData() = data.close()

    private fun TestScope.client(server: JellyfinTestServer, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN) = JellyfinClient(
        connection = server.connection(dialect),
        http = server.http,
        identity = JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", "dev-1"),
        cache = JellyfinApiCache(server.store, JellyfinCacheResolver(server.store, { emptyList() }, { emptyList() })),
        scope = CoroutineScope(coroutineContext),
        favorites = data.liveTvFavorites,
    )

    // Availability is a one-channel probe; an int total decides, else the Items list; failures are false.
    @Test fun availabilityFollowsTheChannelProbe() = runTest {
        val cases = listOf(
            FakeResponse(body = """{"TotalRecordCount":3,"Items":[]}""") to true,
            FakeResponse(body = """{"TotalRecordCount":0,"Items":[{"Id":"c"}]}""") to false,
            FakeResponse(body = """{"Items":[{"Id":"c"}]}""") to true,
            FakeResponse(body = """{"Items":[]}""") to false,
            FakeResponse(status = 500, body = """{"TotalRecordCount":3}""") to false,
            FakeResponse(status = 204, body = "") to false,
        )
        for ((answer, expected) in cases) {
            val server = JellyfinTestServer { answer }
            assertEquals(expected, server.liveTv(this).isAvailable(), answer.body)
            val probe = server.requests.single()
            assertEquals("/LiveTv/Channels", probe.path)
            assertEquals(mapOf("limit" to "1", "userId" to "user-1"), probe.query)
        }
        assertFalse(JellyfinTestServer { throw IOException("down") }.liveTv(this).isAvailable())
    }

    // The user's channels, sorted by name; number falls back to ChannelNumber; tagged logos are absolute.
    @Test fun channelsMapTheUsersChannelList() = runTest {
        val server = JellyfinTestServer {
            FakeResponse(
                body = """{"Items":[
                    {"Id":"ch-1","Name":"News","CallSign":"NWS","Number":"4.1","ImageTags":{"Primary":"t 1"}},
                    {"Id":"ch-2","Name":"Films","ChannelNumber":"7"}
                ]}""",
            )
        }
        val channels = server.liveTv(this).fetchChannels(lineup = "ignored")
        val request = server.requests.single()
        assertEquals("/LiveTv/Channels", request.path)
        assertEquals(
            mapOf("userId" to "user-1", "enableImages" to "true", "enableUserData" to "true", "sortBy" to "SortName", "sortOrder" to "Ascending"),
            request.query,
        )
        val news = channels[0]
        assertEquals("ch-1", news.key)
        assertEquals("ch-1", news.identifier)
        assertEquals("News", news.title)
        assertEquals("NWS", news.callSign)
        assertEquals("4.1", news.number)
        assertEquals("http://jf.local:8096/Items/ch-1/Images/Primary?tag=t%201", news.thumb)
        assertEquals("machine-1", news.serverId)
        assertEquals("Home", news.serverName)
        assertEquals("7", channels[1].number)
        assertNull(channels[1].thumb)
    }

    // The guide window is an overlap filter (minEndDate/maxStartDate), never minStartDate, and asks for Overview.
    @Test fun scheduleAsksForTheOverlappingWindow() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[]}""") }
        server.liveTv(this).fetchSchedule(Instant.parse("2026-08-20T19:00:00Z"), Instant.parse("2026-08-21T01:00:00Z"))
        val request = server.requests.single()
        assertEquals("/LiveTv/Programs", request.path)
        assertEquals("2026-08-20T19:00:00.000Z", request.query["minEndDate"])
        assertEquals("2026-08-21T01:00:00.000Z", request.query["maxStartDate"])
        assertEquals("Overview", request.query["fields"])
        assertEquals("StartDate", request.query["sortBy"])
        assertFalse("minStartDate" in request.query)
    }

    // The program id seeds recording; a timer key only while the airing records, the series key only beside it.
    @Test fun programsCarryTheirRecordingState() = runTest {
        val server = JellyfinTestServer {
            FakeResponse(
                body = """{"Items":[
                    {"Id":"p-1","Name":"Ep 1","TimerId":"t-1","SeriesTimerId":"s-1"},
                    {"Id":"p-2","Name":"Ep 2","TimerId":"t-2"},
                    {"Id":"p-3","Name":"Ep 3","SeriesTimerId":"s-1"},
                    {"Id":"p-4","Name":"Ep 4","TimerId":""}
                ]}""",
            )
        }
        val programs = server.liveTv(this).fetchSchedule()
        assertEquals(listOf("p-1", "p-2", "p-3", "p-4"), programs.map { it.guid })
        assertEquals("timer:t-1", programs[0].subscriptionId)
        assertEquals("series:s-1", programs[0].grandparentSubscriptionId)
        assertEquals("series:s-1", programs[0].recordingRuleKey)
        assertEquals("timer:t-2", programs[1].recordingRuleKey)
        assertNull(programs[1].grandparentSubscriptionId)
        assertNull(programs[2].subscriptionId)
        assertNull(programs[2].grandparentSubscriptionId)
        assertNull(programs[3].recordingRuleKey)
    }

    // The fields a guide airing carries.
    @Test fun programsMapTheGuideFields() = runTest {
        for (dialect in MediaBrowserDialect.entries) {
            val server = JellyfinTestServer { request ->
                val overview = if (request.query["fields"]?.split(',')?.contains("Overview") == true) ""","Overview":"Headlines."""" else ""
                FakeResponse(
                    body = """{"Items":[{"Id":"p-1","Name":"News at Six","StartDate":"2026-08-20T18:00:00.0000000Z",
                        "EndDate":"2026-08-20T19:00:00.0000000Z","ChannelId":"ch-1","ChannelName":"NWS","IsLive":true,"IsPremiere":false,
                        "SeriesName":"News","IndexNumber":3,"ParentIndexNumber":1,"ProductionYear":2026,"ImageTags":{"Primary":"pt"}$overview}]}""",
                )
            }
            val program = server.liveTv(this, dialect).fetchSchedule(Instant.parse("2026-08-20T18:00:00Z"), Instant.parse("2026-08-20T20:00:00Z")).single()
            assertEquals("Headlines.", program.summary, dialect.name)
            assertEquals("News at Six", program.title)
            assertEquals("episode", program.type)
            assertEquals(Instant.parse("2026-08-20T18:00:00Z").epochSeconds, program.beginsAt)
            assertEquals(Instant.parse("2026-08-20T19:00:00Z").epochSeconds, program.endsAt)
            assertEquals("ch-1", program.channelIdentifier)
            assertEquals("NWS", program.channelCallSign)
            assertEquals(true, program.live)
            assertEquals(false, program.premiere)
            assertEquals("News", program.grandparentTitle)
            assertEquals(3, program.index)
            assertEquals(1, program.parentIndex)
            assertEquals(2026, program.year)
            assertEquals("http://jf.local:8096/Items/p-1/Images/Primary?tag=pt", program.thumb)
            assertEquals("machine-1", program.serverId)
        }
    }

    // Favourites are identified by the server and stored per connection, a write carrying this server only.
    @Test fun favouritesAreScopedToTheConnection() = runTest {
        val liveTv = JellyfinTestServer().liveTv(this)
        assertEquals("server://machine-1/jellyfin", liveTv.buildFavoriteChannelSource("any-lineup"))
        assertEquals("jellyfin:machine-1/user-1", liveTv.favoriteStoreKey)
        assertEquals(FavoriteChannelPersistenceMode.SERVER_SLICE, liveTv.favoritePersistenceMode)
    }

    // Both dialects record through the timer adapter, without DVRs and without rule processing.
    @Test fun bothDialectsExposeTheTimerAdapterWithoutDvrs() = runTest {
        for (dialect in MediaBrowserDialect.entries) {
            val server = JellyfinTestServer { error("the DVR adapter must not issue a request") }
            val client = client(server, dialect)
            assertTrue(client.capabilities.liveTv)
            assertTrue(client.capabilities.liveTvDvr)
            val dvr = client.liveTvDvr!!
            assertSame<Any>(client.liveTv, dvr)
            assertNull(client.liveTv.whatsOn)
            assertFalse(dvr.supportsRuleProcessing)
            assertEquals(emptyList(), dvr.fetchDvrs())
            dvr.reloadGuide("any")
            assertFailsWith<UnsupportedOperationException> { dvr.processRecordingRules() }
            assertTrue(server.requests.isEmpty())
        }
    }

    // The empty DVR list keeps the synthesized entry keyed by the backend's id.
    @Test fun availabilitySynthesizesOneEntryPerServer() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"TotalRecordCount":1,"Items":[]}""") }
        val entries = liveTvServerEntries(client(server))
        assertEquals(listOf("/LiveTv/Channels"), server.requests.map { it.path })
        assertEquals(listOf("machine-1" to "jellyfin"), entries.map { it.serverId.value to it.dvrKey })
    }
}
