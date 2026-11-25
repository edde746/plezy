package com.edde746.plezy.plex

import com.edde746.plezy.model.ServerId
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The `/library/metadata/{id}` and `/library/sections/{id}/all` shapes a real Plex Media Server returns. Plex sends the
 * multi-source `Rating[]` array only on the metadata endpoint, so listings carry fewer scores than detail screens.
 */
class PlexRatingPayloadShapesTest {
    private fun item(json: String) = PlexMappers.mediaItem(Json.parseToJsonElement(json).jsonObject, ServerId("plex-machine-1"))

    @Test
    fun `detail response surfaces IMDb alongside Rotten Tomatoes and TMDB`() {
        val item = item(
            """{"ratingKey":"2254","type":"show","title":"【OSHI NO KO】","audienceRating":8.3,
               "audienceRatingImage":"themoviedb://image.rating","Rating":[
               {"image":"imdb://image.rating","value":8.3,"type":"audience"},
               {"image":"rottentomatoes://image.rating.upright","value":9.6,"type":"audience"},
               {"image":"themoviedb://image.rating","value":8.3,"type":"audience"}]}""",
        )
        // The headline scalar leads; the array's TMDB entry repeats it and is deduped.
        assertEquals(listOf("tmdb", "imdb", "rottenTomatoesAudience"), item.ratings?.map { it.source })
        assertEquals(listOf(8.3, 8.3, 9.6), item.ratings?.map { it.value })
    }

    @Test
    fun `listing response carries only the scalar the server chose`() {
        val item = item("""{"ratingKey":"2254","type":"show","title":"【OSHI NO KO】","audienceRating":8.3,"audienceRatingImage":"themoviedb://image.rating"}""")
        val rating = item.ratings!!.single()
        assertEquals("tmdb", rating.source)
        assertEquals(8.3, rating.value)
    }
}
