package com.edde746.plezy.presentation.homescreen

import com.edde746.plezy.model.MediaKind
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The Top Shelf's payload, the contract with the tvOS extension (apple/TopShelf/TopShelfContent.swift): the owner, the
 * row's title, each item's label, progress, poster file and link, and never a poster's source URL.
 */
class TopShelfPayloadTest {
    private val episode = item("plezy_srv_ep1", MediaKind.EPISODE, "Lost", episodeTitle = "The Long Con", season = 2, episode = 5, position = 600_000, duration = 2_400_000)
    private val movie = item("plezy_srv_m1", MediaKind.MOVIE, "Heat")

    private fun parse(json: String): JsonObject = Json.parseToJsonElement(json).jsonObject

    @Test
    fun theOwnersItemsCarryLabelProgressPosterFileAndLink() {
        val payload = parse(TopShelfPayload.json(HomeScreenShelf("owner-a", 3, "Continue Watching", listOf(episode, movie)), mapOf("plezy_srv_ep1" to "0123abcd.art")))
        assertEquals(TopShelfPayload.SCHEMA_VERSION, payload["schemaVersion"]!!.jsonPrimitive.content.toInt())
        assertEquals("owner-a", payload["ownerId"]!!.jsonPrimitive.content)
        assertEquals("Continue Watching", payload["sectionTitle"]!!.jsonPrimitive.content)
        val (first, second) = payload["items"]!!.jsonArray.map { it.jsonObject }
        assertEquals("plezy_srv_ep1", first["id"]!!.jsonPrimitive.content)
        assertEquals("S2 E5 - The Long Con", first["title"]!!.jsonPrimitive.content)
        assertEquals(0.25, first["progress"]!!.jsonPrimitive.content.toDouble())
        assertEquals("0123abcd.art", first["imageFile"]!!.jsonPrimitive.content)
        assertEquals("plezy://play?content_id=plezy_srv_ep1", first["playUrl"]!!.jsonPrimitive.content)
        assertEquals("Heat", second["title"]!!.jsonPrimitive.content)
        assertNull(second["progress"])
        assertNull(second["imageFile"])
    }

    @Test
    fun aPosterSourceNeverReachesThePayload() {
        val json = TopShelfPayload.json(HomeScreenShelf("owner-a", 1, "Continue Watching", listOf(episode)), emptyMap())
        assertFalse("token" in json)
        assertFalse("media.invalid" in json)
    }

    @Test
    fun aShelfWithoutOwnerHasNoItems() {
        val payload = parse(TopShelfPayload.json(HomeScreenShelf(null, 2, "Continue Watching", listOf(episode)), emptyMap()))
        assertNull(payload["ownerId"])
        assertTrue(payload["items"]!!.jsonArray.isEmpty())
    }

    @Test
    fun theLabelNamesTheEpisodeAsFarAsItsNumbersGo() {
        assertEquals("S2 E5 - The Long Con", TopShelfPayload.label(episode))
        assertEquals("E7 - Jupiter Jazz", TopShelfPayload.label(item("c", MediaKind.EPISODE, "Bebop", episodeTitle = "Jupiter Jazz", episode = 7)))
        assertEquals("Bebop - Jupiter Jazz", TopShelfPayload.label(item("c", MediaKind.EPISODE, "Bebop", episodeTitle = "Jupiter Jazz")))
        assertEquals("Heat", TopShelfPayload.label(movie))
    }

    @Test
    fun progressIsClampedAndNeedsAPositionAndADuration() {
        fun progress(position: Long, duration: Long) =
            parse(TopShelfPayload.json(HomeScreenShelf("o", 1, "t", listOf(item("x", MediaKind.MOVIE, "X", position = position, duration = duration))), emptyMap()))["items"]!!
                .jsonArray.single().jsonObject["progress"]?.jsonPrimitive?.content?.toDouble()
        assertEquals(1.0, progress(5_000, 4_000))
        assertNull(progress(0, 4_000))
        assertNull(progress(1_000, 0))
    }

    private fun item(
        contentId: String,
        kind: MediaKind,
        title: String,
        episodeTitle: String? = null,
        season: Int? = null,
        episode: Int? = null,
        position: Long = 0,
        duration: Long = 0,
    ) = HomeScreenItem(
        contentId = contentId,
        kind = kind,
        title = title,
        episodeTitle = episodeTitle,
        description = null,
        posterSource = "https://media.invalid/poster?token=secret",
        durationMillis = duration,
        positionMillis = position,
        lastEngagedMillis = 0,
        seriesTitle = null,
        seasonNumber = season,
        episodeNumber = episode,
    )
}
