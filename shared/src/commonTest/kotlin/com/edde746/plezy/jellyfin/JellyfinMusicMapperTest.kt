package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject

/** Music hierarchy mapping, on rows captured (trimmed) from a Jellyfin 10.11 server. */
class JellyfinMusicMapperTest {
    private val audio = Json.parseToJsonElement(
        """
        {"Name":"Intro (Live)","ServerId":"9c23dc6d65044485b4ee44287e723c90","Id":"425f9ab168792a3be733d169b770853f","HasLyrics":false,
         "Container":"flac","SortName":"0001 - 0001 - Intro (Live)","PremiereDate":"2022-01-01T00:00:00.0000000Z","RunTimeTicks":120000000,
         "ProductionYear":2022,"IndexNumber":1,"ParentIndexNumber":1,"Type":"Audio",
         "UserData":{"PlaybackPositionTicks":0,"PlayCount":0,"IsFavorite":false,"Played":false},
         "Artists":["The Synth Pops"],"ArtistItems":[{"Name":"The Synth Pops","Id":"a603621309dc866c91b6c5fe10cee64d"}],
         "Album":"Live at Testhalle","AlbumId":"27511f928761c3f5c080d43d6799ea09","AlbumPrimaryImageTag":"233dccb8ad84d8ac473dbffb86c35e6c",
         "AlbumArtist":"The Synth Pops","AlbumArtists":[{"Name":"The Synth Pops","Id":"a603621309dc866c91b6c5fe10cee64d"}],
         "ImageTags":{"Primary":"1ed1281fd45ff9b8b5ad62b6f6a34d17"},"BackdropImageTags":[],"MediaType":"Audio"}
        """,
    ).jsonObject

    private val album = Json.parseToJsonElement(
        """
        {"Name":"Live at Testhalle","Id":"27511f928761c3f5c080d43d6799ea09","SortName":"live at testhalle","PremiereDate":"2022-01-01T00:00:00.0000000Z",
         "RunTimeTicks":1610000000,"ProductionYear":2022,"IsFolder":true,"Type":"MusicAlbum","UserData":{"PlayCount":0,"IsFavorite":false,"Played":false},
         "RecursiveItemCount":8,"ChildCount":8,"Artists":["The Synth Pops"],"AlbumArtist":"The Synth Pops",
         "AlbumArtists":[{"Name":"The Synth Pops","Id":"a603621309dc866c91b6c5fe10cee64d"}],"ImageTags":{"Primary":"233dccb8ad84d8ac473dbffb86c35e6c"},
         "MediaType":"Unknown"}
        """,
    ).jsonObject

    private fun map(json: JsonObject): MediaItem = JellyfinMappers.mediaItem(json, "jf-machine-1", null, null)!!

    private fun JsonObject.with(vararg fields: Pair<String, Any?>): JsonObject = JsonObject(
        this.toMutableMap().apply {
            for ((key, value) in fields) {
                when (value) {
                    null -> remove(key)
                    is String -> put(key, JsonPrimitive(value))
                    is kotlinx.serialization.json.JsonElement -> put(key, value)
                    else -> error("unsupported $value")
                }
            }
        },
    )

    private val albumPoster = "/Items/27511f928761c3f5c080d43d6799ea09/Images/Primary?tag=233dccb8ad84d8ac473dbffb86c35e6c"

    @Test fun mapsTrackWithAlbumAndArtistHierarchy() {
        val item = map(audio)
        assertEquals(MediaKind.TRACK, item.kind)
        assertEquals("Intro (Live)", item.title)
        assertEquals("27511f928761c3f5c080d43d6799ea09", item.parentId)
        assertEquals("Live at Testhalle", item.parentTitle)
        assertEquals("a603621309dc866c91b6c5fe10cee64d", item.grandparentId)
        assertEquals("The Synth Pops", item.grandparentTitle)
        assertEquals(1, item.trackNumber)
        assertEquals(1, item.discNumber)
        assertEquals("Live at Testhalle", item.albumTitle)
        assertEquals(2022, item.albumYear)
        assertEquals("The Synth Pops", item.albumArtistTitle)
        // Artists == [AlbumArtist]: no per-track performer.
        assertNull(item.originalTitle)
        assertEquals("The Synth Pops", item.trackArtistTitle)
        // Embedded art wins over the album fallback.
        assertEquals("/Items/425f9ab168792a3be733d169b770853f/Images/Primary?tag=1ed1281fd45ff9b8b5ad62b6f6a34d17", item.thumbPath)
        assertEquals(albumPoster, item.posterThumbFallback())
        assertEquals(12_000L, item.durationMs)
    }

    @Test fun compilationTrackMapsDifferingArtistsIntoOriginalTitle() {
        val item = map(
            audio.with(
                "Artists" to JsonArray(listOf(JsonPrimitive("Artist One"), JsonPrimitive("Artist Two"))),
                "AlbumArtist" to "Various Artists",
                "AlbumArtists" to Json.parseToJsonElement("""[{"Name":"Various Artists","Id":"va-1"}]"""),
            ),
        )
        assertEquals("Artist One, Artist Two", item.originalTitle)
        assertEquals("Artist One, Artist Two", item.trackArtistTitle)
        assertEquals("Various Artists", item.albumArtistTitle)
        assertEquals("va-1", item.grandparentId)
    }

    @Test fun trackWithoutEmbeddedArtFallsBackToAlbumPrimary() {
        assertEquals(albumPoster, map(audio.with("ImageTags" to JsonObject(emptyMap()))).thumbPath)
    }

    @Test fun trackWithoutAnyTagStillTriesAlbumPrimaryEndpoint() {
        val item = map(audio.with("ImageTags" to JsonObject(emptyMap()), "AlbumPrimaryImageTag" to null))
        assertEquals("/Items/27511f928761c3f5c080d43d6799ea09/Images/Primary", item.thumbPath)
        assertNull(item.posterThumbFallback())
    }

    @Test fun mapsAlbumWithArtistParentAndTrackCount() {
        val item = map(album)
        assertEquals(MediaKind.ALBUM, item.kind)
        assertEquals("Live at Testhalle", item.title)
        assertEquals("Live at Testhalle", item.albumTitle)
        assertEquals(2022, item.year)
        // An album's parent is its artist, as on Plex.
        assertEquals("a603621309dc866c91b6c5fe10cee64d", item.parentId)
        assertEquals("The Synth Pops", item.parentTitle)
        assertEquals("The Synth Pops", item.albumArtistTitle)
        assertNull(item.grandparentId)
        assertNull(item.grandparentTitle)
        assertEquals(8, item.leafCount)
        assertNull(item.originalTitle)
        assertEquals(albumPoster, item.thumbPath)
    }

    @Test fun episodeHierarchyKeepsPriorityOverMusicFallbacks() {
        val item = map(audio.with("Type" to "Episode", "SeasonId" to "season-1", "SeasonName" to "Season 1", "SeriesId" to "series-1", "SeriesName" to "Show"))
        assertEquals("season-1", item.parentId)
        assertEquals("Season 1", item.parentTitle)
        assertEquals("series-1", item.grandparentId)
        assertEquals("Show", item.grandparentTitle)
    }
}
