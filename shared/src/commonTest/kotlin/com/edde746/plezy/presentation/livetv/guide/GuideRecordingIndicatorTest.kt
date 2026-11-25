package com.edde746.plezy.presentation.livetv.guide

import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.MediaGrabOperation
import com.edde746.plezy.livetv.MediaSubscription
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The guide's recording dot and NEW pill, on airings shaped like Plex Media Server 1.43.3's grid and
 * `/media/subscriptions/scheduled` answers.
 */
class GuideRecordingIndicatorTest {
    private val title = "Motorway Cops: Catching Britain's Speeders"

    private fun json(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

    private val episodeMetadata = """
        {"ratingKey": "$EPISODE_RATING_KEY", "guid": "plex://episode/6a7fba88cb8a706b4d3047bb",
         "key": "/tv.plex.providers.epg.cloud:2/metadata/$EPISODE_RATING_KEY", "type": "episode", "title": "$title"}
    """.trimIndent()

    private val scheduledGrab = """
        {"mediaSubscriptionID": 1106, "mediaIndex": 0, "id": "e97afe16706b598f31c62cf6a402daab8562fa64",
         "key": "/media/grabbers/operations/e97afe16706b598f31c62cf6a402daab8562fa64",
         "grabberIdentifier": "tv.plex.grabbers.hdhomerun", "grabberProtocol": "livetv", "deviceID": 1,
         "status": "scheduled", "provider": "tv.plex.providers.epg.cloud:2", "Metadata": $episodeMetadata}
    """.trimIndent()

    /** The grid's airing ten minutes into the window, [extra] fields added to the row and [media] to its Media. */
    private fun gridAiring(beginsAt: Long, extra: String = "", media: String = ""): LiveTvProgram {
        val row = json(
            """
            {"ratingKey": "$EPISODE_RATING_KEY", "guid": "plex://episode/6a7fba88cb8a706b4d3047bb",
             "key": "/tv.plex.providers.epg.cloud:2/metadata/$EPISODE_RATING_KEY", "type": "episode", "title": "$title",
             "Media": [{"beginsAt": $beginsAt, "endsAt": ${beginsAt + 3600}, "channelIdentifier": "station-a"$media}]$extra}
            """.trimIndent(),
        )
        return LiveTvProgram.fromJson(row).copy(serverId = "server-a", serverName = "server-a", providerIdentifier = "tv.plex.providers.epg.cloud:2")
    }

    private class Recordings {
        var grabs: List<MediaGrabOperation> = emptyList()
        var rules: List<MediaSubscription> = emptyList()
        var scheduledFetches = 0
    }

    private fun TestScope.guide(
        recordings: Recordings = Recordings(),
        airing: (beginsAt: Long) -> LiveTvProgram = { gridAiring(it) },
    ): GuideHarness {
        val server = GuideServer("server-a", "station-a", hasDvr = true)
        server.liveTv.schedule = { from, _ -> listOf(airing(checkNotNull(from).epochSeconds + 600)) }
        server.liveTv.scheduled = {
            recordings.scheduledFetches++
            recordings.grabs
        }
        server.liveTv.rules = { includeGrabs, includeStorage ->
            check(includeGrabs && !includeStorage)
            recordings.rules
        }
        val h = GuideHarness(this, listOf(server), listOf(guideChannel("server-a", "station-a", "A")))
        runCurrent()
        assertEquals(listOf(title), h.titles("A"))
        return h
    }

    private fun GuideHarness.dot(): Boolean = cell(title).second.isRecordingScheduled

    @Test
    fun aScheduledGrabWithMatchingGridIdentifiersShowsTheDot() = runTest {
        val recordings = Recordings().apply { grabs = listOf(MediaGrabOperation.fromJson(json(scheduledGrab))) }
        assertTrue(guide(recordings).dot())
    }

    @Test
    fun aGridAiringTaggedWithItsSeriesSubscriptionShowsTheDotWithoutAnyGrabs() = runTest {
        assertTrue(guide(airing = { gridAiring(it, extra = ""","grandparentSubscriptionID": "1106"""") }).dot())
    }

    @Test
    fun anActiveGrabNestingItsAiringUnderVideoShowsTheDot() = runTest {
        val grab = MediaGrabOperation.fromJson(json("""{"id": "grab-2", "mediaSubscriptionID": 1106, "status": "recording", "Video": $episodeMetadata}"""))
        assertTrue(guide(Recordings().apply { grabs = listOf(grab) }).dot())
    }

    @Test
    fun aRulesGrabsCountOnlyWhileTheyStillRecord() = runTest {
        fun rule(status: String) = MediaSubscription(
            key = "1106",
            grabOperations = listOf(MediaGrabOperation.fromJson(json(scheduledGrab.replace("\"status\": \"scheduled\"", "\"status\": \"$status\"")))),
        )
        assertFalse(guide(Recordings().apply { rules = listOf(rule("complete")) }).dot())
        assertFalse(guide(Recordings().apply { rules = listOf(rule("error")) }).dot())
        assertTrue(guide(Recordings().apply { rules = listOf(rule("grabbing")) }).dot())
        assertTrue(guide(Recordings().apply { rules = listOf(rule(" Recording ")) }).dot())
    }

    @Test
    fun aRecordingScheduledFromTheGuideKeepsItsDotAfterAnEmptyGrabRefresh() = runTest {
        val recordings = Recordings()
        val h = guide(recordings)
        assertFalse(h.dot())
        val fetches = recordings.scheduledFetches

        h.store.setRecordingOverride(h.cell(title).second.program, scheduled = true)
        runCurrent()
        // The refresh came back before the server listed the new grab: the local action stays authoritative.
        assertTrue(recordings.scheduledFetches > fetches)
        assertTrue(h.dot())
    }

    @Test
    fun cancellingFromTheGuideHidesTheDotDespiteStaleGridAttributesUntilTheNextLoad() = runTest {
        val h = guide(airing = { gridAiring(it, extra = ""","grandparentSubscriptionID": "1106"""") })
        assertTrue(h.dot())

        h.store.setRecordingOverride(h.cell(title).second.program, scheduled = false)
        runCurrent()
        assertFalse(h.dot())

        // A full load brings the grid's attributes back, and with them the dot.
        h.store.selectTimeNav(GuideTimeNavItem.LATER)
        h.store.selectTimeNav(GuideTimeNavItem.EARLIER)
        runCurrent()
        assertTrue(h.dot())
    }

    @Test
    fun anAiringFlaggedAsAPremiereShowsNew() = runTest {
        val h = guide(airing = { gridAiring(it, media = ""","premiere": "1"""") })
        assertTrue(h.cell(title).second.isPremiere)
    }

    @Test
    fun aRepeatAiringShowsNoNew() = runTest {
        assertFalse(guide().cell(title).second.isPremiere)
    }

    @Test
    fun recordingKeysNameTheAiringsIdsAndSlotOnItsServer() {
        val program = LiveTvProgram(ratingKey = "rk", guid = "g", key = " ", title = "News", beginsAt = 100, endsAt = 200, channelIdentifier = "ch")
        assertEquals(emptySet(), guideRecordingKeys(program))
        assertEquals(
            setOf("s\u0000media\u0000rk", "s\u0000media\u0000g", "s\u0000slot\u0000ch|100|200"),
            guideRecordingKeys(program, fallbackServerId = "s"),
        )
        assertEquals(setOf("own\u0000media\u0000rk", "own\u0000media\u0000g", "own\u0000slot\u0000ch|100|"), guideRecordingKeys(program.copy(serverId = "own", endsAt = null), "s"))
    }

    private companion object {
        const val EPISODE_RATING_KEY = "plex%3A%2F%2Fepisode%2F6a7fba88cb8a706b4d3047bb"
    }
}
