package com.edde746.plezy.trackers.client

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.HistoryItem
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerMediaKind
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.time.Instant

class HistoryBodyTest {
    private fun episode(tvdb: Int, season: Int, number: Int) =
        TrackerContext(TrackerMediaKind.EPISODE, ExternalIds(tvdb = tvdb), season = season, episode = number)

    private fun movie(tmdb: Int) = TrackerContext(TrackerMediaKind.MOVIE, ExternalIds(tmdb = tmdb))

    private fun ids(context: TrackerContext): JsonObject = buildJsonObject {
        context.ids.tvdb?.let { put("tvdb", it) }
        context.ids.tmdb?.let { put("tmdb", it) }
    }

    @Test
    fun aContainerFoldsIntoOneEntryPerShowAndSeasonAndARepeatedItemGoesOnce() {
        val at = Instant.parse("2026-10-01T20:00:00Z")
        val body = historyBody(
            listOf(
                HistoryItem(episode(1, 1, 1), at),
                HistoryItem(episode(1, 1, 2)),
                HistoryItem(episode(2, 1, 1)),
                HistoryItem(episode(1, 2, 1)),
                // Two media-server rows for one episode: one play, not two.
                HistoryItem(episode(1, 1, 2), at),
                HistoryItem(movie(9)),
                HistoryItem(movie(9)),
            ),
            dated = true,
            ids = ::ids,
        )
        assertEquals<JsonElement?>(
            parse(
                """{"movies":[{"ids":{"tmdb":9}}],"shows":[
                  {"ids":{"tvdb":1},"seasons":[{"number":1,"episodes":[{"number":1,"watched_at":"2026-10-01T20:00:00Z"},{"number":2}]},{"number":2,"episodes":[{"number":1}]}]},
                  {"ids":{"tvdb":2},"seasons":[{"number":1,"episodes":[{"number":1}]}]}
                ]}""",
            ),
            body,
        )
    }

    @Test
    fun whatTheServiceCantAddressIsLeftOutAndNothingLeftSendsNothing() {
        val at = Instant.parse("2026-01-01T00:00:00Z")
        val items = listOf(HistoryItem(movie(9), at), HistoryItem(episode(1, 1, 1)), HistoryItem(episode(1, 1, 1).copy(season = null)))
        assertNull(historyBody(items, dated = true) { JsonObject(emptyMap()) })
        assertNull(historyBody(items, dated = true) { null })
        // A removal carries no date.
        assertEquals<JsonElement?>(
            parse("""{"movies":[{"ids":{"tmdb":9}}],"shows":[{"ids":{"tvdb":1},"seasons":[{"number":1,"episodes":[{"number":1}]}]}]}"""),
            historyBody(items, dated = false, ids = ::ids),
        )
    }
}
