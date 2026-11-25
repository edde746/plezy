package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.RecordingConflictException
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.MediaSubscriptionCreateRequest
import com.edde746.plezy.livetv.SubscriptionSetting
import com.edde746.plezy.livetv.liveTvDvr
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.TextContent
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json

class PlexLiveTvTest {
    private val providerA = PlexEpgProvider("provider-a", "/provider-a/grid", "2")
    private val subscriptionReply = """{"MediaContainer":{"MediaSubscription":[{"key":"18","type":4,"title":"Episode"}]}}"""

    private fun client(
        epg: List<PlexEpgProvider> = listOf(providerA),
        token: String = TEST_TOKEN,
        prioritizedEndpoints: List<String> = emptyList(),
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    ) = testPlexClient(handler, token = token, prioritizedEndpoints = prioritizedEndpoints, machineIdentifier = "machine-1")
        .also { it.providers = PlexMediaProviders(epg = epg) }

    private val PlexClient.dvr get() = liveTvDvr!!

    @Test
    fun plexExposesItselfAsTheLiveTvDvrAdapter() = runTest {
        val paths = mutableListOf<String>()
        val client = client { request ->
            paths += request.url.encodedPath
            jsonResponse("""{"MediaContainer":{"Dvr":[{"key":"dvr-1","uuid":"dvr-1"}]}}""")
        }

        assertTrue(client.capabilities.liveTv)
        assertTrue(client.capabilities.liveTvDvr)
        assertSame<Any?>(client.liveTv, client.liveTv.dvr)
        assertSame(client.liveTv.dvr, client.liveTvDvr)
        assertTrue(client.dvr.supportsRuleProcessing)
        assertEquals("dvr-1", client.dvr.fetchDvrs().single().key)
        assertEquals(listOf("/livetv/dvrs"), paths)
    }

    @Test
    fun availabilityIsHavingADvrAndAFailureIsFalse() = runTest {
        var reply = """{"MediaContainer":{"Dvr":[{"key":"dvr-1"}]}}"""
        var status = 200
        val client = client { jsonResponse(reply, status) }

        assertTrue(client.liveTv.isAvailable())
        reply = """{"MediaContainer":{}}"""
        assertFalse(client.liveTv.isAvailable())
        status = 500
        assertFalse(client.liveTv.isAvailable())
    }

    @Test
    fun favoriteSourceFollowsTheRequestedLineupProvider() = runTest {
        val client = client(listOf(providerA, PlexEpgProvider("provider-b", "/provider-b/grid", "3"))) { jsonResponse("{}") }

        assertEquals("server://machine-1/provider-b", client.liveTv.buildFavoriteChannelSource("provider-b"))
        assertEquals("server://machine-1/provider-a", client.liveTv.buildFavoriteChannelSource("unknown"))
    }

    @Test
    fun favoriteStoreIsAccountScopedInsteadOfTokenScoped() {
        val a = client(token = "server-token-a") { jsonResponse("{}") }.also { it.bindAccount("plex.account-1", "account-token") }
        val b = client(token = "server-token-b") { jsonResponse("{}") }.also { it.bindAccount("plex.account-1", "account-token") }

        assertEquals(a.liveTv.favoriteStoreKey, b.liveTv.favoriteStoreKey)
    }

    @Test
    fun favoriteStoresOfTwoAccountsOnOneDeviceStaySeparate() {
        // The client identifier is device-wide, shared by every account.
        val a = client { jsonResponse("{}") }.also { it.bindAccount("plex.account-1", "token-1") }
        val b = client { jsonResponse("{}") }.also { it.bindAccount("plex.account-2", "token-2") }

        assertNotEquals(a.liveTv.favoriteStoreKey, b.liveTv.favoriteStoreKey)
    }

    @Test
    fun aFailingPlexTvFavoritesReadNeverFailsTheMediaServerOver() = runTest {
        val hosts = mutableListOf<String>()
        val client = client(prioritizedEndpoints = listOf(TEST_BASE_URL, "https://backup.example.com")) { request ->
            hosts += request.url.host
            if (request.url.host == "epg.provider.plex.tv") respond("service unavailable", HttpStatusCode.ServiceUnavailable) else jsonResponse("""{"MediaContainer":{}}""")
        }

        assertFailsWith<MediaServerHttpException> { client.liveTv.fetchFavoriteChannels() }

        assertEquals(listOf("epg.provider.plex.tv"), hosts)
        assertEquals(TEST_BASE_URL, client.config.baseUrl)
    }

    @Test
    fun favoritesGoToPlexTvWithTheAccountToken() = runTest {
        val tokens = mutableListOf<String?>()
        val client = client { request ->
            tokens += request.headers["X-Plex-Token"]
            assertEquals("5.1", request.headers["X-Plex-Provider-Version"])
            jsonResponse("""{"MediaContainer":{"FavoriteChannel":[{"source":"server://machine-1/provider-a","key":"7","title":"Seven"}]}}""")
        }
        client.bindAccount("plex.account-1", "account-token")

        val favorites = client.liveTv.fetchFavoriteChannels()
        client.liveTv.setFavoriteChannels(favorites)

        assertEquals(listOf(FavoriteChannel(source = "server://machine-1/provider-a", id = "7", title = "Seven")), favorites)
        assertEquals(listOf<String?>("account-token", "account-token"), tokens)
    }

    @Test
    fun favoriteReadPreservesASuccessfulEmptyResponse() = runTest {
        val client = client { request ->
            assertEquals("/settings/favoriteChannels", request.url.encodedPath)
            jsonResponse("""{"MediaContainer":{}}""")
        }
        assertTrue(client.liveTv.fetchFavoriteChannels().isEmpty())
    }

    @Test
    fun favoriteReadRejectsAMalformedResponse() = runTest {
        var reply = "{}"
        val client = client { jsonResponse(reply) }

        assertFailsWith<IllegalStateException> { client.liveTv.fetchFavoriteChannels() }
        reply = """{"MediaContainer":{"FavoriteChannel":{"id":"1"}}}"""
        assertFailsWith<IllegalStateException> { client.liveTv.fetchFavoriteChannels() }
    }

    @Test
    fun favoriteReadAndWritePropagateHttpErrors() = runTest {
        val methods = mutableListOf<HttpMethod>()
        val client = client { request ->
            assertEquals("/settings/favoriteChannels", request.url.encodedPath)
            methods += request.method
            respond("service unavailable", HttpStatusCode.ServiceUnavailable)
        }

        assertEquals(503, assertFailsWith<MediaServerHttpException> { client.liveTv.fetchFavoriteChannels() }.statusCode)
        assertEquals(503, assertFailsWith<MediaServerHttpException> { client.liveTv.setFavoriteChannels(emptyList()) }.statusCode)
        assertEquals(listOf(HttpMethod.Get, HttpMethod.Put), methods)
    }

    @Test
    fun favoriteWriteSendsTheJsonContentTypePlexCloudRequires() = runTest {
        var captured: HttpRequestData? = null
        val client = client { request ->
            captured = request
            jsonResponse("""{"MediaContainer":{}}""")
        }

        client.liveTv.setFavoriteChannels(listOf(FavoriteChannel(source = "server://machine-1/provider-a", id = "2", title = "Channel 2", vcn = "2")))

        // Without an explicit content type plex.tv rejects the PUT with 400.
        val request = captured!!
        assertEquals(HttpMethod.Put, request.method)
        assertEquals("https://epg.provider.plex.tv/settings/favoriteChannels", request.url.toString())
        val contentType = request.headers[HttpHeaders.ContentType] ?: request.body.contentType?.toString()
        assertTrue(contentType!!.startsWith("application/json"), contentType)
        assertEquals(
            Json.parseToJsonElement("""[{"source":"server://machine-1/provider-a","id":"2","title":"Channel 2","vcn":"2"}]"""),
            Json.parseToJsonElement((request.body as TextContent).text),
        )
    }

    @Test
    fun dvrListAppliesRootChannelMappingToEachDvrAndParsesFlexibleEnabledFlags() = runTest {
        val client = client { request ->
            assertEquals("/livetv/dvrs", request.url.encodedPath)
            jsonResponse(
                """{"MediaContainer":{"Dvr":[{"key":"1","uuid":"dvr-1","lineupTitle":"Antenna","tuners":"2","status":"1"}],""" +
                    """"ChannelMapping":[{"channelKey":"ch-1","enabled":"1","lineupIdentifier":"001"}]}}""",
            )
        }

        val dvr = client.dvr.fetchDvrs().single()

        assertEquals("1", dvr.key)
        assertEquals("Antenna", dvr.lineupTitle)
        assertEquals("ch-1", dvr.channelMappings.single().channelKey)
        assertEquals(true, dvr.channelMappings.single().enabled)
    }

    @Test
    fun subscriptionTemplateParsesSettingsAndUrlEncodedEnumLabels() = runTest {
        val client = client { request ->
            assertEquals("/media/subscriptions/template", request.url.encodedPath)
            assertEquals("plex://episode/1", request.url.parameters["guid"])
            jsonResponse(
                """{"MediaContainer":{"SubscriptionTemplate":[{"MediaSubscription":[{"key":"","type":4,"selected":"1",""" +
                    """"title":"This Episode","parameters":"hints%5Bguid%5D=plex%3A%2F%2Fepisode%2F1",""" +
                    """"Setting":[{"id":"startTimeslot","type":"int","value":"-1","enumValues":":Any|1715319000:12%3A30%20AM"}]}]}]}}""",
            )
        }

        val subscription = client.dvr.getSubscriptionTemplate("plex://episode/1").single().subscriptions.single()

        assertEquals(true, subscription.selected)
        assertTrue("hints%5Bguid%5D" in subscription.parameters!!)
        assertEquals(listOf("Any", "12:30 AM"), subscription.settings.single().options.map { it.label })
    }

    @Test
    fun createRecordingRulePreservesTemplateParametersAndAllPrefsAsQueryParams() = runTest {
        var captured: HttpRequestData? = null
        val client = client { request ->
            captured = request
            jsonResponse(subscriptionReply)
        }
        val request = MediaSubscriptionCreateRequest.fromTemplate(
            MediaSubscription(
                key = "",
                targetLibrarySectionId = 2,
                type = 4,
                parameters = "hints%5Bguid%5D=plex%3A%2F%2Fepisode%2F1",
                settings = listOf(
                    SubscriptionSetting(id = "oneShot", value = "true", defaultValue = "false", hidden = true),
                    SubscriptionSetting(id = "remoteMedia", value = "false", defaultValue = "false", hidden = true),
                    SubscriptionSetting(id = "startOffsetMinutes", value = "0", defaultValue = "0"),
                ),
            ),
            prefs = mapOf("startOffsetMinutes" to 5),
        )

        val created = client.dvr.createRecordingRule(request)

        val sent = captured!!
        assertEquals(HttpMethod.Post, sent.method)
        assertEquals("/media/subscriptions", sent.url.encodedPath)
        assertEquals(0L, sent.body.contentLength ?: 0L)
        assertNull(sent.headers[HttpHeaders.ContentType] ?: sent.body.contentType)
        assertEquals("plex://episode/1", sent.url.parameters["hints[guid]"])
        assertEquals("2", sent.url.parameters["targetLibrarySectionID"])
        assertEquals("4", sent.url.parameters["type"])
        assertEquals("true", sent.url.parameters["prefs[oneShot]"])
        assertEquals("false", sent.url.parameters["prefs[remoteMedia]"])
        assertEquals("5", sent.url.parameters["prefs[startOffsetMinutes]"])
        assertEquals("18", created?.key)
    }

    @Test
    fun fromTemplateSectionOverrideDropsTheTemplateLocationId() = runTest {
        var captured: HttpRequestData? = null
        val client = client { request ->
            captured = request
            jsonResponse(subscriptionReply)
        }
        val template = MediaSubscription(key = "", targetLibrarySectionId = 2, targetSectionLocationId = 7, type = 4)

        val overridden = MediaSubscriptionCreateRequest.fromTemplate(template, targetLibrarySectionId = 5)
        assertEquals(5, overridden.targetLibrarySectionId)
        assertNull(overridden.targetSectionLocationId)

        client.dvr.createRecordingRule(overridden)
        assertEquals("5", captured!!.url.parameters["targetLibrarySectionID"])
        assertFalse("targetSectionLocationID" in captured!!.url.parameters.names())
    }

    @Test
    fun fromTemplateWithoutOverrideKeepsTemplateSectionAndLocation() {
        val template = MediaSubscription(key = "", targetLibrarySectionId = 2, targetSectionLocationId = 7, type = 4)

        val request = MediaSubscriptionCreateRequest.fromTemplate(template)
        assertEquals(2, request.targetLibrarySectionId)
        assertEquals(7, request.targetSectionLocationId)

        // A same-section override is a no-op: the template location still applies.
        assertEquals(7, MediaSubscriptionCreateRequest.fromTemplate(template, targetLibrarySectionId = 2).targetSectionLocationId)
    }

    @Test
    fun aConflictingCreateIsARecordingConflict() = runTest {
        val client = client { jsonResponse("""{"MediaContainer":{}}""", status = 409) }

        assertFailsWith<RecordingConflictException> { client.dvr.createRecordingRule(MediaSubscriptionCreateRequest(type = 4)) }
    }

    @Test
    fun updateRecordingRuleSendsPrefsAsQueryParams() = runTest {
        var captured: HttpRequestData? = null
        val client = client { request ->
            captured = request
            jsonResponse(subscriptionReply)
        }

        val updated = client.dvr.updateRecordingRule("18", mapOf("startOffsetMinutes" to 5))

        assertEquals(HttpMethod.Put, captured!!.method)
        assertEquals("/media/subscriptions/18", captured!!.url.encodedPath)
        assertEquals(0L, captured!!.body.contentLength ?: 0L)
        assertEquals("5", captured!!.url.parameters["prefs[startOffsetMinutes]"])
        assertEquals("18", updated?.key)
    }

    @Test
    fun recordingRulesParseActiveGrabOperationMetadata() = runTest {
        var captured: HttpRequestData? = null
        val client = client { request ->
            captured = request
            jsonResponse(
                """{"MediaContainer":{"MediaSubscription":[{"key":"18","type":4,"title":"Episode","MediaGrabOperation":[""" +
                    """{"id":"grab-active","status":"grabbing","Metadata":{"title":"Live Episode","ratingKey":"episode-1",""" +
                    """"guid":"plex://episode/1","Media":[{"beginsAt":"1466060400","endsAt":"1466062200","channelIdentifier":"004"}]}}]}]}}""",
            )
        }

        val rules = client.dvr.fetchRecordingRules(includeGrabs = true, includeStorage = false)

        assertEquals("/media/subscriptions", captured!!.url.encodedPath)
        assertEquals("1", captured!!.url.parameters["includeGrabs"])
        assertEquals("0", captured!!.url.parameters["includeStorage"])
        val grab = rules.single().grabOperations.single()
        assertEquals("grabbing", grab.status)
        assertEquals("episode-1", grab.program?.ratingKey)
        assertEquals("plex://episode/1", grab.program?.guid)
        assertEquals("004", grab.program?.channelIdentifier)
    }

    @Test
    fun ruleMutationsTargetTheRuleAndProcessingPaths() = runTest {
        val requests = mutableListOf<Pair<HttpMethod, String>>()
        val client = client { request ->
            requests += request.method to request.url.encodedPath
            jsonResponse("""{"MediaContainer":{}}""")
        }

        client.dvr.deleteRecordingRule("18")
        client.dvr.processRecordingRules()
        client.dvr.reloadGuide("dvr-1")

        assertEquals(
            listOf(
                HttpMethod.Delete to "/media/subscriptions/18",
                HttpMethod.Post to "/media/subscriptions/process",
                HttpMethod.Post to "/livetv/dvrs/dvr-1/reloadGuide",
            ),
            requests,
        )
    }

    @Test
    fun cancelGrabDeletesTheOperationKeyPath() = runTest {
        val paths = mutableListOf<String>()
        val client = client { request ->
            assertEquals(HttpMethod.Delete, request.method)
            paths += request.url.encodedPath
            jsonResponse("""{"MediaContainer":{}}""")
        }

        client.dvr.cancelGrab("/media/grabbers/operations/grab-1")
        client.dvr.cancelGrab("media/grabbers/operations/grab-2")
        client.dvr.cancelGrab("grab-3")

        assertEquals(
            listOf("/media/grabbers/operations/grab-1", "/media/grabbers/operations/grab-2", "/media/grabbers/operations/grab-3"),
            paths,
        )
        assertFailsWith<IllegalArgumentException> { client.dvr.cancelGrab("") }
    }

    @Test
    fun scheduledRecordingsParseGrabOperationMetadata() = runTest {
        val client = client { request ->
            assertEquals("/media/subscriptions/scheduled", request.url.encodedPath)
            jsonResponse(
                """{"MediaContainer":{"MediaGrabOperation":[{"id":"grab-1","key":"/media/grabbers/operations/grab-1",""" +
                    """"mediaSubscriptionID":"7","status":"scheduled","percent":"42.5","Metadata":{"title":"Miracle on Dead Street",""" +
                    """"grandparentTitle":"Fresh Off the Boat","type":"episode",""" +
                    """"Media":[{"beginsAt":"1466060400","endsAt":"1466062200","channelIdentifier":"004"}]}}]}}""",
            )
        }

        val operation = client.dvr.fetchScheduledRecordings().single()

        assertEquals("grab-1", operation.id)
        assertEquals("/media/grabbers/operations/grab-1", operation.operationKey)
        assertEquals(7, operation.mediaSubscriptionId)
        assertEquals(42.5, operation.percent)
        assertEquals("Fresh Off the Boat", operation.program?.grandparentTitle)
        assertEquals("004", operation.program?.channelIdentifier)
    }

    @Test
    fun subscriptionMappingTargetsTheNumericProviderIdRoute() = runTest {
        // The identifier-scoped route answers 404; the mapping is mounted under the numeric MediaProvider id.
        var captured: HttpRequestData? = null
        val client = client { request ->
            captured = request
            // The mapping endpoint identifies rules by `id`, not `key`.
            jsonResponse("""{"MediaContainer":{"MediaSubscription":[{"id":1106,"type":2}]}}""")
        }

        val mapped = client.dvr.fetchSubscriptionMapping("provider-a", listOf("plex%3A%2F%2Fepisode%2F6a7fba88cb8a706b4d3047bb"))

        assertEquals("/media/providers/2/media/subscriptions/mapping/plex%3A%2F%2Fepisode%2F6a7fba88cb8a706b4d3047bb", captured!!.url.encodedPath)
        assertEquals("1", captured!!.url.parameters["includeStorage"])
        assertEquals("1106", mapped.single().key)
    }

    @Test
    fun scheduledRecordingsReadTheAiringFromVideoWhenMetadataIsAbsent() = runTest {
        // The server nests the airing under `Metadata` only for scheduled grabs; active ones use `Video`.
        val client = client {
            jsonResponse(
                """{"MediaContainer":{"MediaGrabOperation":[{"id":"grab-2","mediaSubscriptionID":1456,"status":"recording",""" +
                    """"Video":{"ratingKey":"plex%3A%2F%2Fepisode%2F6a58","guid":"plex://episode/6a58",""" +
                    """"key":"/tv.plex.providers.epg.cloud:2/metadata/plex%3A%2F%2Fepisode%2F6a58","type":"episode","title":"Wheeler Dealers"}}]}}""",
            )
        }

        val operation = client.dvr.fetchScheduledRecordings().single()

        assertEquals("plex%3A%2F%2Fepisode%2F6a58", operation.program?.ratingKey)
        assertEquals("plex://episode/6a58", operation.program?.guid)
    }

    @Test
    fun epgGridAiringsKeepTheirSubscriptionAttributes() = runTest {
        // The grid tags subscribed airings itself: the signal the recording indicator renders from.
        val client = client { request ->
            assertEquals("/provider-a/grid", request.url.encodedPath)
            jsonResponse(
                """{"MediaContainer":{"Metadata":[""" +
                    """{"ratingKey":"plex%3A%2F%2Fepisode%2F6a74","guid":"plex://episode/6a74","grandparentSubscriptionID":"1456",""" +
                    """"type":"episode","title":"Aston Martin DB6","Media":[{"beginsAt":"1466060400","endsAt":"1466062200","channelIdentifier":"004"}]},""" +
                    """{"ratingKey":"plex%3A%2F%2Fepisode%2Funsubscribed","type":"episode","title":"Untagged Airing",""" +
                    """"Media":[{"beginsAt":"1466062200","endsAt":"1466064000","channelIdentifier":"004"}]}]}}""",
            )
        }

        val programs = client.liveTv.fetchSchedule()

        assertEquals(2, programs.size)
        assertEquals("1456", programs[0].grandparentSubscriptionId)
        assertEquals("1456", programs[0].recordingRuleKey)
        assertNull(programs[1].subscriptionId)
        assertNull(programs[1].recordingRuleKey)
    }

    @Test
    fun epgGridReadsEachProvidersWindowHubsAndOneProgramPerAiring() = runTest {
        var captured: HttpRequestData? = null
        val client = client { request ->
            captured = request
            jsonResponse(
                """{"MediaContainer":{"Metadata":[{"ratingKey":"a","title":"News","Media":[""" +
                    """{"beginsAt":100,"endsAt":160,"channelIdentifier":"1","premiere":"1"},{"beginsAt":160,"endsAt":220,"channelIdentifier":"1"}]}],""" +
                    """"Hub":[{"Metadata":[{"ratingKey":"b","title":"Film"}]}]}}""",
            )
        }

        val programs = client.liveTv.fetchSchedule(
            from = kotlin.time.Instant.fromEpochSeconds(100),
            to = kotlin.time.Instant.fromEpochSeconds(200),
        )

        assertEquals("/provider-a/grid", captured!!.url.encodedPath)
        assertEquals("100", captured!!.url.parameters["endsAt>"])
        assertEquals("200", captured!!.url.parameters["beginsAt<"])
        assertEquals(listOf("a", "a", "b"), programs.map { it.ratingKey })
        assertEquals(listOf(100L, 160L, null), programs.map { it.beginsAt })
        assertEquals(listOf(true, null, null), programs.map { it.premiere })
        assertTrue(programs.all { it.serverId == TEST_SERVER_ID && it.serverName == "Test Server" && it.providerIdentifier == "provider-a" })
    }

    @Test
    fun cloudChannelsComeFromTheServerLineupAndFallBackToTheProviderLineup() = runTest {
        val cloud = PlexEpgProvider("tv.plex.providers.epg.cloud:2", "/tv.plex.providers.epg.cloud:2/grid", "2")
        var cloudReply = """{"MediaContainer":{"Channel":[{"key":"ch-1","callSign":"ONE"},{"key":"","title":"No key"}]}}"""
        val paths = mutableListOf<String>()
        val client = client(listOf(cloud, PlexEpgProvider("provider-b", "/provider-b/grid", "3"))) { request ->
            paths += request.url.encodedPath
            when (request.url.encodedPath) {
                "/lineups/plex/channels" -> jsonResponse(cloudReply)
                else -> jsonResponse("""{"MediaContainer":{"Metadata":[{"key":"ch-9","title":"Nine"}]}}""")
            }
        }

        val first = client.liveTv.fetchChannels("tv.plex.providers.epg.cloud:2")
        assertEquals(listOf("ch-1"), first.map { it.key })
        assertEquals(TEST_SERVER_ID, first.single().serverId)
        assertEquals("Test Server", first.single().serverName)
        assertEquals(listOf("/lineups/plex/channels"), paths)

        paths.clear()
        cloudReply = """{"MediaContainer":{}}"""
        assertEquals(listOf("ch-9"), client.liveTv.fetchChannels("tv.plex.providers.epg.cloud:2").map { it.key })
        assertEquals(listOf("/lineups/plex/channels", "/tv.plex.providers.epg.cloud:2/lineups/dvr/channels"), paths)
    }

    @Test
    fun whatsOnHubsCarryCardsAndAiringsWithTheirArtwork() = runTest {
        var captured: HttpRequestData? = null
        val client = client { request ->
            captured = request
            jsonResponse(
                """{"MediaContainer":{"Hub":[""" +
                    """{"title":"On Now","key":"/hubs/on-now","Metadata":[{"ratingKey":"p1","type":"episode","title":"Pilot",""" +
                    """"grandparentTitle":"Show","thumb":"/old-thumb","Image":[{"type":"coverPoster","url":"/poster"},""" +
                    """{"type":"coverArt","url":"/cover-art"},{"type":"background","url":"/background"}],""" +
                    """"Media":[{"beginsAt":100,"endsAt":200,"channelIdentifier":"5"}]}]},""" +
                    """{"title":"Empty","Metadata":[]},{"key":"/hubs/untitled","Metadata":[{"ratingKey":"p2","title":"Film","art":"/own-art",""" +
                    """"Image":[{"type":"background","url":"/background"}]}]}]}}""",
            )
        }

        val hubs = client.liveTv.whatsOn!!.fetchHubs()

        assertEquals("/provider-a/hubs/discover", captured!!.url.encodedPath)
        assertEquals("12", captured!!.url.parameters["count"])
        listOf("includeStations", "includeRecentChannels", "includeMeta", "includeExternalMetadata").forEach {
            assertEquals("1", captured!!.url.parameters[it], it)
        }
        assertEquals(listOf("On Now", "Unknown"), hubs.map { it.title })
        assertEquals(listOf("/hubs/on-now", "/hubs/untitled"), hubs.map { it.hubKey })
        val entry = hubs.first().entries.single()
        assertEquals("p1", entry.metadata.id)
        assertEquals("/poster", entry.metadata.thumbPath)
        assertEquals("/cover-art", entry.metadata.artPath)
        assertEquals("/poster", entry.program.thumb)
        assertEquals(100L, entry.program.beginsAt)
        assertEquals("5", entry.program.channelIdentifier)
        assertEquals("provider-a", entry.program.providerIdentifier)
        assertEquals(TEST_SERVER_ID, entry.program.serverId)
        assertEquals("/own-art", hubs.last().entries.single().program.art)
    }
}
