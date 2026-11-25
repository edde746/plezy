package com.edde746.plezy.plex

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.CardShape
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaDisplayColorTags
import com.edde746.plezy.model.MediaDisplayColorType
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaMarker
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.PersonCredit
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

private const val SERVER_ID = "plex-machine-1"
private const val SERVER_NAME = "Home"

private fun obj(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

private fun item(json: String, serverName: String? = null): MediaItem =
    PlexMappers.mediaItem(obj(json), ServerId(SERVER_ID), serverName)

class PlexMappersTest {
    @Test
    fun `metadata accepts string ratings`() {
        val item = item("""{"ratingKey":"1","rating":"8.8","audienceRating":"9.1","userRating":"9.5"}""")
        assertEquals(8.8, item.rating)
        assertEquals(9.5, item.userRating)
        assertEquals(listOf(8.8, 9.1), item.ratings?.map { it.value })
    }

    @Test
    fun `display criteria maps each Plex color metadata class`() {
        val cases = listOf(
            Triple("""{"DOVIProfile":5,"DOVIPresent":1}""", MediaDisplayColorType.DOLBY_VISION, MediaDisplayColorTags(null, null, null)),
            Triple("""{"DOVIProfile":8,"DOVIBLCompatID":4}""", MediaDisplayColorType.HLG, MediaDisplayColorTags("arib-std-b67", "bt2020", "bt2020nc")),
            Triple("""{"colorTrc":"smpte2084"}""", MediaDisplayColorType.PQ, MediaDisplayColorTags("smpte2084", "bt2020", "bt2020nc")),
            Triple("""{}""", MediaDisplayColorType.SDR, MediaDisplayColorTags("bt709", "bt709", "bt709")),
        )
        for ((stream, type, tags) in cases) {
            val criteria = PlexMappers.displayCriteria(obj("""{"width":1920,"height":1080}"""), obj(stream))
            assertNotNull(criteria)
            assertEquals(type, criteria.colorType)
            assertEquals(tags, MediaDisplayColorTags(criteria.transfer, criteria.primaries, criteria.matrix), type.name)
        }
    }

    // movie

    @Test
    fun `maps a Plex movie with watch state ratings genres and people`() {
        val item = item(
            """{
              "ratingKey":"12345","key":"/library/metadata/12345","guid":"plex://movie/5d776b59ad5437001f7be94b",
              "studio":"Warner Bros.","type":"movie","title":"Inception","titleSort":"Inception","originalTitle":"Inception",
              "tagline":"Your mind is the scene of the crime.","contentRating":"PG-13","summary":"Dom Cobb is a thief.",
              "rating":8.8,"audienceRating":9.1,"userRating":9.5,"year":2010,"originallyAvailableAt":"2010-07-16",
              "thumb":"/library/metadata/12345/thumb/1700000000","art":"/library/metadata/12345/art/1700000000",
              "duration":8880000,"addedAt":1600000000,"updatedAt":1700000000,"lastViewedAt":1750000000,
              "viewOffset":3000000,"viewCount":1,"librarySectionID":1,"librarySectionTitle":"Movies",
              "ratingImage":"rottentomatoes://image.rating.ripe","audienceRatingImage":"rottentomatoes://image.rating.upright",
              "imdbRatingCount":250858,
              "Rating":[
                {"image":"imdb://image.rating","type":"audience","value":8.4},
                {"image":"rottentomatoes://image.rating.ripe","type":"critic","value":8.8},
                {"image":"themoviedb://image.rating","type":"audience","value":9.1}
              ],
              "Genre":[{"tag":"Action"},{"tag":"Sci-Fi"}],
              "Director":[{"tag":"Christopher Nolan"}],
              "Writer":[{"tag":"Christopher Nolan"}],
              "Producer":[{"tag":"Emma Thomas"}],
              "Country":[{"tag":"United States"}],
              "Role":[
                {"id":1,"tag":"Leonardo DiCaprio","role":"Cobb","thumb":"/library/metadata/role/1/thumb"},
                {"id":2,"tag":"Joseph Gordon-Levitt","role":"Arthur"}
              ]
            }""",
            serverName = SERVER_NAME,
        )

        assertEquals("12345", item.id)
        assertEquals(BackendKind.PLEX, item.backend)
        assertEquals(MediaKind.MOVIE, item.kind)
        assertEquals("plex://movie/5d776b59ad5437001f7be94b", item.guid)
        assertEquals("Inception", item.title)
        assertEquals("Inception", item.titleSort)
        assertEquals("Inception", item.originalTitle)
        assertEquals("Your mind is the scene of the crime.", item.tagline)
        assertEquals("Dom Cobb is a thief.", item.summary)
        assertEquals("Warner Bros.", item.studio)
        assertEquals(2010, item.year)
        assertEquals("2010-07-16", item.originallyAvailableAt)
        assertEquals("PG-13", item.contentRating)
        assertEquals(8.8, item.rating)
        assertEquals(9.5, item.userRating)

        // Headline scalars first, then the array, deduped on (source, value).
        assertEquals(listOf("rottenTomatoesCritic", "rottenTomatoesAudience", "imdb", "tmdb"), item.ratings?.map { it.source })
        assertEquals(listOf(8.8, 9.1, 8.4, 9.1), item.ratings?.map { it.value })
        assertEquals(listOf(null, null, 250858, null), item.ratings?.map { it.votes })

        assertEquals(8880000L, item.durationMs)
        assertEquals(3000000L, item.viewOffsetMs)
        assertEquals(1, item.viewCount)
        assertEquals(1750000000L, item.lastViewedAt)
        assertEquals(1600000000L, item.addedAt)
        assertEquals(1700000000L, item.updatedAt)

        assertEquals("/library/metadata/12345/thumb/1700000000", item.thumbPath)
        assertEquals("/library/metadata/12345/art/1700000000", item.artPath)

        assertEquals(listOf("Action", "Sci-Fi"), item.genres)
        assertEquals(listOf("Christopher Nolan"), item.directors)
        assertEquals(listOf("Christopher Nolan"), item.writers)
        assertEquals(listOf("Emma Thomas"), item.producers)
        assertEquals(listOf("United States"), item.countries)

        val roles = assertNotNull(item.roles)
        assertEquals(2, roles.size)
        assertEquals("1", roles[0].id)
        assertEquals("Leonardo DiCaprio", roles[0].tag)
        assertEquals("Cobb", roles[0].role)
        assertEquals("/library/metadata/role/1/thumb", roles[0].thumbPath)
        assertNull(roles[1].thumbPath)

        assertEquals("1", item.libraryId)
        assertEquals("Movies", item.libraryTitle)
        assertEquals(SERVER_ID, item.serverId)
        assertEquals(SERVER_NAME, item.serverName)
    }

    @Test
    fun `a section listing yields the scalar pair alone`() {
        val item = item(
            """{"ratingKey":"listing-1","type":"movie","rating":9.4,"ratingImage":"rottentomatoes://image.rating.ripe",
               "audienceRating":8.3,"audienceRatingImage":"themoviedb://image.rating"}""",
        )
        assertEquals(listOf("rottenTomatoesCritic", "tmdb"), item.ratings?.map { it.source })
        assertEquals(listOf(9.4, 8.3), item.ratings?.map { it.value })
    }

    @Test
    fun `an unrated item reports no ratings rather than an empty list`() {
        val item = item("""{"ratingKey":"unrated-1","type":"movie"}""")
        assertNull(item.rating)
        assertNull(item.ratings)
    }

    @Test
    fun `scores outside the reportable range are dropped not folded`() {
        val item = item(
            """{"ratingKey":"noisy-1","type":"movie","rating":140,"audienceRating":-1,
               "Rating":[{"image":"imdb://image.rating","type":"audience","value":"8.5"}]}""",
        )
        val rating = item.ratings!!.single()
        assertEquals("imdb", rating.source)
        assertEquals(8.5, rating.value)
    }

    @Test
    fun `normalizes aggregate watch counts off leaf items`() {
        val item = item("""{"ratingKey":"leaf-with-counts","type":"movie","viewCount":0,"leafCount":1,"viewedLeafCount":1}""")
        assertEquals(1, item.leafCount)
        assertNull(item.viewedLeafCount)
        assertFalse(item.isWatched)
        assertNull(item.unwatchedCount)
    }

    // Plex home video: type=movie subtype=clip

    @Test
    fun `keeps the movie kind but renders wide with the video frame thumb in every poster mode`() {
        val item = item(
            """{"ratingKey":"8964","type":"movie","subtype":"clip","guid":"tv.plex.agents.none://8964",
               "title":"Holiday 2019","thumb":"/library/metadata/8964/thumb/1"}""",
        )
        assertEquals(MediaKind.MOVIE, item.kind)
        for (mode in EpisodePosterMode.entries) {
            assertTrue(item.usesWideAspectRatio(mode), mode.name)
            assertEquals(CardShape.WIDE, item.cardShape(mode), mode.name)
            assertEquals("/library/metadata/8964/thumb/1", item.posterThumb(mode), mode.name)
        }
    }

    @Test
    fun `falls back to art when the generated thumb is missing`() {
        val item = item("""{"ratingKey":"8506","type":"movie","subtype":"clip","art":"/library/metadata/8506/art/1"}""")
        assertEquals("/library/metadata/8506/art/1", item.posterThumb())
    }

    @Test
    fun `a movie without the clip subtype keeps the poster shape`() {
        val item = item("""{"ratingKey":"1","type":"movie","title":"Matched","thumb":"/t"}""")
        assertFalse(item.usesWideAspectRatio(EpisodePosterMode.SERIES_POSTER))
        assertEquals(CardShape.POSTER, item.cardShape(EpisodePosterMode.SERIES_POSTER))
    }

    // show + season + episode

    @Test
    fun `show preserves leaf counts and child counts`() {
        val item = item(
            """{"ratingKey":"500","key":"/library/metadata/500","type":"show","title":"Breaking Bad",
               "leafCount":62,"viewedLeafCount":62,"childCount":5,"year":2008}""",
        )
        assertEquals(MediaKind.SHOW, item.kind)
        assertEquals(62, item.leafCount)
        assertEquals(62, item.viewedLeafCount)
        assertEquals(5, item.childCount)
        assertTrue(item.isWatched)
    }

    @Test
    fun `show preserves Plex season display flags in raw metadata`() {
        val item = item(
            """{"ratingKey":"500","key":"/library/metadata/500","type":"show","title":"Breaking Bad",
               "skipChildren":"1","flattenSeasons":"1"}""",
        )
        val raw = assertNotNull(item.raw)
        assertEquals(JsonPrimitive("/library/metadata/500"), raw["key"])
        assertEquals(JsonPrimitive(true), raw["skipChildren"])
        assertEquals(JsonPrimitive(1), raw["flattenSeasons"])
    }

    @Test
    fun `season carries parent show reference`() {
        val item = item(
            """{"ratingKey":"510","type":"season","title":"Season 1","index":1,"parentRatingKey":"500",
               "parentTitle":"Breaking Bad","parentThumb":"/library/metadata/500/thumb/1","leafCount":7,"viewedLeafCount":3}""",
        )
        assertEquals(MediaKind.SEASON, item.kind)
        assertEquals(1, item.index)
        assertEquals("500", item.parentId)
        assertEquals("Breaking Bad", item.parentTitle)
        assertEquals("/library/metadata/500/thumb/1", item.parentThumbPath)
        assertEquals(7, item.leafCount)
        assertEquals(3, item.viewedLeafCount)
        assertTrue(item.isPartiallyWatched)
    }

    @Test
    fun `episode carries parent season and grandparent show refs`() {
        val item = item(
            """{"ratingKey":"520","type":"episode","title":"Pilot","index":1,"parentIndex":1,"parentRatingKey":"510",
               "parentTitle":"Season 1","parentYear":2008,"parentThumb":"/library/metadata/510/thumb/1",
               "grandparentRatingKey":"500","grandparentTitle":"Breaking Bad",
               "grandparentThumb":"/library/metadata/500/thumb/1","grandparentArt":"/library/metadata/500/art/1",
               "duration":2820000,"viewOffset":1410000}""",
        )
        assertEquals(MediaKind.EPISODE, item.kind)
        assertEquals(1, item.index)
        assertEquals(1, item.parentIndex)
        assertEquals("510", item.parentId)
        assertEquals("Season 1", item.parentTitle)
        assertNull(item.year)
        assertEquals("/library/metadata/510/thumb/1", item.parentThumbPath)
        assertEquals("500", item.grandparentId)
        assertEquals("Breaking Bad", item.grandparentTitle)
        assertEquals("/library/metadata/500/thumb/1", item.grandparentThumbPath)
        assertEquals("/library/metadata/500/art/1", item.grandparentArtPath)
        assertEquals(2820000L, item.durationMs)
        assertEquals(1410000L, item.viewOffsetMs)
    }

    // music

    @Test
    fun `album preserves studio and parent artist reference`() {
        val item = item(
            """{"ratingKey":"700","type":"album","title":"Random Access Memories","parentRatingKey":"699",
               "parentTitle":"Daft Punk","studio":"Columbia Records","year":2013,"leafCount":13}""",
        )
        assertEquals(MediaKind.ALBUM, item.kind)
        assertEquals("Random Access Memories", item.title)
        assertEquals("699", item.parentId)
        assertEquals("Daft Punk", item.parentTitle)
        assertEquals("Columbia Records", item.studio)
        assertEquals(2013, item.year)
        assertEquals(13, item.leafCount)
    }

    @Test
    fun `track maps audio type to MediaKind track`() {
        val item = item(
            """{"ratingKey":"710","type":"track","title":"Get Lucky","index":8,"parentRatingKey":"700",
               "parentTitle":"Random Access Memories","parentYear":2013,"grandparentRatingKey":"699",
               "grandparentTitle":"Daft Punk","duration":369000}""",
        )
        assertEquals(MediaKind.TRACK, item.kind)
        assertEquals("Get Lucky", item.title)
        assertEquals(8, item.index)
        assertEquals(369000L, item.durationMs)
        assertEquals("700", item.parentId)
        assertEquals("Random Access Memories", item.parentTitle)
        assertEquals(2013, item.year)
        assertEquals(2013, item.albumYear)
        assertEquals("699", item.grandparentId)
        assertEquals("Daft Punk", item.grandparentTitle)
        assertEquals(MediaKind.TRACK, PlexMappers.mediaItem(obj("""{"ratingKey":"711","type":"audio"}""")).kind)
    }

    // media versions + image arrays

    @Test
    fun `Media and Part list yields a MediaVersion with one MediaPart`() {
        val item = item(
            """{"ratingKey":"12345","type":"movie","title":"Inception","Media":[{
              "id":1,"videoResolution":"1080","videoCodec":"h264","bitrate":8000,"width":1920,"height":1080,"container":"mkv",
              "Part":[{"key":"/library/parts/1/file.mkv","Stream":[
                {"id":10,"streamType":1,"codec":"hevc","frameRate":23.976,"DOVIProfile":8,"DOVIPresent":1,"DOVIBLCompatID":1,
                 "colorTrc":"smpte2084","colorPrimaries":"bt2020","colorSpace":"bt2020nc"},
                {"id":11,"streamType":2,"codec":"eac3","channels":6,"languageCode":"eng","selected":true}
              ]}]
            }]}""",
        )
        val v = item.mediaVersions!!.single()
        assertEquals("1", v.id)
        assertEquals("1080", v.videoResolution)
        assertEquals("h264", v.videoCodec)
        assertEquals(8000, v.bitrate)
        assertEquals(1920, v.width)
        assertEquals(1080, v.height)
        assertEquals("mkv", v.container)
        val part = v.parts.single()
        assertEquals("/library/parts/1/file.mkv", part.streamPath)
        val video = part.streams.first { it.kind == MediaStreamKind.VIDEO }
        assertEquals("hevc", video.codec)
        assertEquals(23.976, video.frameRate!!, 0.001)
        assertTrue(video.hdr)
        assertTrue(video.dolbyVision)
        assertEquals(8, video.dolbyVisionProfile)
        val audio = part.streams.first { it.kind == MediaStreamKind.AUDIO }
        assertEquals("eac3", audio.codec)
        assertEquals(6, audio.channels)
        assertTrue(audio.selected)
    }

    @Test
    fun `Media level audio and file hints backfill streams when Part Stream is absent`() {
        val item = item(
            """{"ratingKey":"6048","type":"episode","title":"Hello, Ms. Cobel","Media":[{
              "id":"6136","videoResolution":"4k","videoCodec":"hevc","audioCodec":"eac3","audioChannels":"6",
              "width":"3840","height":"1606","container":"mkv",
              "Part":[{"id":"6154","key":"/library/parts/6154/file.mkv",
                "file":"/tv/Severance.S02.Hybrid.MULTI.2160p.WEB-DL.DV.HDR.H265-AOC/S02/S02E01.mkv"}]
            }]}""",
        )
        val part = item.mediaVersions!!.single().parts.single()
        val video = part.streams.first { it.kind == MediaStreamKind.VIDEO }
        val audio = part.streams.first { it.kind == MediaStreamKind.AUDIO }
        assertEquals("hevc", video.codec)
        assertTrue(video.hdr)
        assertTrue(video.dolbyVision)
        assertNull(video.dolbyVisionProfile)
        assertEquals("eac3", audio.codec)
        assertEquals(6, audio.channels)
        assertTrue(audio.selected)
    }

    @Test
    fun `Image array clearLogo backgroundSquare is hoisted onto top level fields`() {
        val item = item(
            """{"ratingKey":"12345","type":"movie","title":"Inception","Image":[
              {"type":"clearLogo","url":"/library/metadata/12345/clearLogo"},
              {"type":"backgroundSquare","url":"/library/metadata/12345/squareBg"},
              {"type":"snapshot","url":"/library/metadata/12345/snap"}
            ]}""",
        )
        assertEquals("/library/metadata/12345/clearLogo", item.clearLogoPath)
        assertEquals("/library/metadata/12345/squareBg", item.backgroundSquarePath)
    }

    @Test
    fun `unmatched means no guid or a no agent guid`() {
        assertTrue(PlexMappers.isUnmatched(null))
        assertTrue(PlexMappers.isUnmatched(""))
        assertTrue(PlexMappers.isUnmatched("tv.plex.agents.none://8964"))
        assertTrue(PlexMappers.isUnmatched("com.plexapp.agents.none://8964"))
        assertFalse(PlexMappers.isUnmatched("plex://movie/5d776b59ad5437001f7be94b"))
    }

    @Test
    fun `discography kind reads Format then Subformat case insensitively`() {
        assertEquals(DiscographyGroupKind.SINGLES_AND_EPS, PlexMappers.discographyKind(obj("""{"Format":[{"tag":"EP"}],"Subformat":[{"tag":"Live"}]}""")))
        assertEquals(DiscographyGroupKind.LIVE, PlexMappers.discographyKind(obj("""{"Subformat":[{"tag":"Live"}]}""")))
        assertEquals(DiscographyGroupKind.COMPILATIONS, PlexMappers.discographyKind(obj("""{"Subformat":[{"tag":"compilation"}]}""")))
        assertEquals(DiscographyGroupKind.ALBUMS, PlexMappers.discographyKind(obj("""{"Format":[{"tag":"Album"}]}""")))
    }

    // mediaLibrary

    @Test
    fun `library Directory entry maps to MediaLibrary with kind from type`() {
        val lib = PlexMappers.mediaLibrary(
            obj(
                """{"key":"1","title":"Movies","type":"movie","agent":"tv.plex.agents.movie","language":"en-US",
                   "updatedAt":1700000000,"createdAt":1600000000,"hidden":0}""",
            ),
            ServerId(SERVER_ID),
            SERVER_NAME,
        )
        assertEquals("1", lib.id)
        assertEquals(BackendKind.PLEX, lib.backend)
        assertEquals("Movies", lib.title)
        assertEquals(MediaKind.MOVIE, lib.kind)
        assertEquals("en-US", lib.language)
        assertEquals(1700000000L, lib.updatedAt)
        assertEquals(1600000000L, lib.createdAt)
        assertFalse(lib.hidden)
        assertFalse(lib.isShared)
        assertEquals(SERVER_ID, lib.serverId)
        assertEquals(SERVER_NAME, lib.serverName)
    }

    @Test
    fun `home video section type movie subtype clip maps to the clip kind`() {
        val lib = PlexMappers.mediaLibrary(
            obj("""{"key":"7","title":"Home Videos","type":"movie","subtype":"clip","agent":"tv.plex.agents.none"}"""),
            ServerId(SERVER_ID),
        )
        assertEquals(MediaKind.CLIP, lib.kind)
    }

    @Test
    fun `shared library is marked isShared`() {
        val lib = PlexMappers.mediaLibrary(obj("""{"key":"shared","title":"Shared with you","type":"movie"}"""), ServerId(SERVER_ID), isShared = true)
        assertTrue(lib.isShared)
    }

    @Test
    fun `hidden 1 maps to true`() {
        val lib = PlexMappers.mediaLibrary(obj("""{"key":"2","title":"Hidden","type":"show","hidden":1}"""), ServerId(SERVER_ID))
        assertTrue(lib.hidden)
    }

    @Test
    fun `library parsing is flexible and ignores client only fields`() {
        val lib = PlexMappers.mediaLibrary(
            obj(
                """{"key":7,"title":"Music","type":"artist","updatedAt":"1700000000","createdAt":"1600000000","hidden":"1",
                   "serverId":"ignored-server","serverName":"Ignored Server","isShared":true}""",
            ),
        )
        assertEquals("7", lib.id)
        assertEquals("Music", lib.title)
        assertEquals(MediaKind.ARTIST, lib.kind)
        assertEquals(1700000000L, lib.updatedAt)
        assertEquals(1600000000L, lib.createdAt)
        assertTrue(lib.hidden)
        assertNull(lib.serverId)
        assertNull(lib.serverName)
        assertFalse(lib.isShared)
    }

    @Test
    fun `library with missing title or type falls back to empty strings`() {
        val lib = PlexMappers.mediaLibrary(obj("""{"key":"99"}"""), ServerId(SERVER_ID))
        assertEquals("99", lib.id)
        assertEquals("", lib.title)
        assertEquals(MediaKind.UNKNOWN, lib.kind)
    }

    // mediaHub

    @Test
    fun `hub with mixed type items maps to MediaHub with neutral items`() {
        val hub = PlexMappers.mediaHub(
            obj(
                """{"key":"/hubs/movie.recentlyAdded","title":"Recently Added Movies","type":"movie",
                   "hubIdentifier":"movie.recentlyAdded.1","size":2,"more":true,"Metadata":[
                   {"ratingKey":"1","type":"movie","title":"Movie A"},{"ratingKey":"2","type":"movie","title":"Movie B"}]}""",
            ),
            ServerId(SERVER_ID),
            SERVER_NAME,
        )
        assertEquals("/hubs/movie.recentlyAdded", hub.id)
        assertEquals("movie.recentlyAdded.1", hub.identifier)
        assertEquals("Recently Added Movies", hub.title)
        assertEquals("movie", hub.type)
        assertEquals(2, hub.size)
        assertTrue(hub.more)
        assertEquals(2, hub.items.size)
        assertEquals("Movie A", hub.items[0].title)
        assertEquals(MediaKind.MOVIE, hub.items[0].kind)
        assertEquals("Movie B", hub.items[1].title)
        assertEquals(SERVER_ID, hub.items[0].serverId)
        assertEquals(SERVER_NAME, hub.items[0].serverName)
        assertEquals(SERVER_ID, hub.serverId)
        assertEquals(SERVER_NAME, hub.serverName)
    }

    @Test
    fun `Directory entries without type are inferred folder vs show`() {
        val hub = PlexMappers.mediaHub(
            obj(
                """{"key":"/hubs/foo","title":"Foo","type":"mixed","Directory":[
                   {"ratingKey":"10","title":"A Show","leafCount":24},{"ratingKey":"11","title":"A Folder"}]}""",
            ),
            ServerId(SERVER_ID),
        )
        assertEquals(2, hub.items.size)
        assertEquals(MediaKind.SHOW, hub.items[0].kind)
        assertEquals(MediaKind.FOLDER, hub.items[1].kind)
    }

    @Test
    fun `parses Metadata and Directory together`() {
        val hub = PlexMappers.mediaHub(
            obj(
                """{"key":"/hubs/foo","title":"Foo","type":"mixed",
                   "Metadata":[{"ratingKey":"1","type":"movie","title":"Movie A"}],
                   "Directory":[{"ratingKey":"10","type":"show","title":"Show B"}]}""",
            ),
            ServerId(SERVER_ID),
        )
        assertEquals(2, hub.items.size)
        assertEquals(MediaKind.MOVIE, hub.items[0].kind)
        assertEquals(MediaKind.SHOW, hub.items[1].kind)
    }

    @Test
    fun `a hub omits only the malformed sibling`() {
        val hub = PlexMappers.mediaHub(
            obj(
                """{"key":"/hubs/cc004","title":"Synthetic hub","type":"movie","Metadata":[
                   {"ratingKey":"valid-sibling","type":"movie","title":"Valid sibling"},
                   {"ratingKey":"bad","title":"Bad","Media":[{"id":1,"Part":[{"id":1,"file":"/f"}]}],"guid":7}]}""",
            ),
        )
        assertEquals(1, hub.items.size)
        assertEquals("valid-sibling", hub.items.single().id)
        assertEquals("Valid sibling", hub.items.single().title)
        assertFailsWith<IllegalArgumentException> { PlexMappers.mediaItem(obj("""{"ratingKey":"bad","guid":7}""")) }
    }

    @Test
    fun `hub size defaults to the item count`() {
        val hub = PlexMappers.mediaHub(obj("""{"key":"/hubs/x","title":"X","Metadata":[{"ratingKey":"1","type":"movie"}]}"""))
        assertEquals(1, hub.size)
        assertEquals("hub", hub.type)
    }

    // mediaPlaylist

    @Test
    fun `video playlist maps with summary and counts`() {
        val p = PlexMappers.mediaPlaylist(
            obj(
                """{"ratingKey":"999","key":"/playlists/999/items","type":"playlist","title":"Date Night",
                   "summary":"Movies for date night","smart":false,"playlistType":"video","duration":14400000,"leafCount":5,
                   "composite":"/playlists/999/composite/1700000000","addedAt":1600000000,"updatedAt":1700000000,
                   "lastViewedAt":1750000000,"viewCount":3,"thumb":"/playlists/999/thumb"}""",
            ),
            ServerId(SERVER_ID),
            SERVER_NAME,
        )
        assertEquals("999", p.id)
        assertEquals(BackendKind.PLEX, p.backend)
        assertEquals("Date Night", p.title)
        assertEquals("Movies for date night", p.summary)
        assertFalse(p.smart)
        assertEquals("video", p.playlistType)
        assertEquals(14400000L, p.durationMs)
        assertEquals(5, p.leafCount)
        assertEquals(3, p.viewCount)
        assertEquals(1600000000L, p.addedAt)
        assertEquals(1700000000L, p.updatedAt)
        assertEquals(1750000000L, p.lastViewedAt)
        assertEquals("/playlists/999/composite/1700000000", p.compositeImagePath)
        assertEquals("/playlists/999/thumb", p.thumbPath)
        assertEquals(SERVER_ID, p.serverId)
        assertEquals(SERVER_NAME, p.serverName)
    }

    @Test
    fun `smart playlist preserves the smart flag`() {
        val p = PlexMappers.mediaPlaylist(
            obj("""{"ratingKey":"888","key":"/playlists/888/items","type":"playlist","title":"Recently Added","smart":true,"playlistType":"audio"}"""),
            ServerId(SERVER_ID),
        )
        assertTrue(p.smart)
        assertEquals("audio", p.playlistType)
    }

    @Test
    fun `playlist with missing key type smart playlistType falls back to safe defaults`() {
        val p = PlexMappers.mediaPlaylist(obj("""{"ratingKey":"777","title":"Bare","summary":null}"""), ServerId(SERVER_ID))
        assertEquals("777", p.id)
        assertEquals("Bare", p.title)
        assertNull(p.summary)
        assertFalse(p.smart)
        assertEquals("", p.playlistType)
    }

    @Test
    fun `playlist parsing is flexible and ignores client only fields`() {
        val p = PlexMappers.mediaPlaylist(
            obj(
                """{"ratingKey":888,"title":"Recently Added","duration":"14400000","leafCount":"5","addedAt":"1600000000",
                   "updatedAt":"1700000000","lastViewedAt":"1750000000","viewCount":"3",
                   "serverId":"ignored-server","serverName":"Ignored Server"}""",
            ),
        )
        assertEquals("888", p.id)
        assertEquals("Recently Added", p.title)
        assertFalse(p.smart)
        assertEquals("", p.playlistType)
        assertEquals(14400000L, p.durationMs)
        assertEquals(5, p.leafCount)
        assertEquals(1600000000L, p.addedAt)
        assertEquals(1700000000L, p.updatedAt)
        assertEquals(1750000000L, p.lastViewedAt)
        assertEquals(3, p.viewCount)
        assertNull(p.serverId)
        assertNull(p.serverName)
    }

    // people

    @Test
    fun `person search rows map actor and director tags and reject the rest`() {
        val serverId = ServerId(SERVER_ID)
        val actor = PlexMappers.personFromSearchResultJson(
            obj("""{"type":"tag","tagType":6,"id":42,"tag":"Leonardo DiCaprio","thumb":"https://metadata-static.plex.tv/p.jpg"}"""),
            serverId,
            SERVER_NAME,
        )!!
        assertEquals("42", actor.id)
        assertEquals("Leonardo DiCaprio", actor.name)
        assertEquals(PersonCredit.ACTOR, actor.credit)
        assertEquals("https://metadata-static.plex.tv/p.jpg", actor.thumbPath)
        assertEquals(BackendKind.PLEX, actor.backend)
        assertEquals(PersonCredit.DIRECTOR, PlexMappers.personFromSearchResultJson(obj("""{"type":"tag","tagType":"4","id":"7","tag":"Nolan"}"""), serverId)?.credit)
        assertNull(PlexMappers.personFromSearchResultJson(obj("""{"type":"tag","tagType":5,"id":1,"tag":"Writer"}"""), serverId))
        assertNull(PlexMappers.personFromSearchResultJson(obj("""{"type":"movie","tagType":6,"id":1,"tag":"X"}"""), serverId))
        assertFailsWith<IllegalArgumentException> {
            PlexMappers.personFromSearchResultJson(obj("""{"type":"tag","tagType":6,"tag":"No id"}"""), serverId)
        }
        assertFailsWith<IllegalArgumentException> {
            PlexMappers.personFromSearchResultJson(obj("""{"type":"tag","tagType":6,"id":3,"tag":"  "}"""), serverId)
        }
    }

    // direct entry points

    @Test
    fun `mediaVersion maps version and part`() {
        val v = PlexMappers.mediaVersion(
            obj(
                """{"id":42,"videoResolution":"4k","videoCodec":"hevc","bitrate":25000,"width":3840,"height":2160,
                   "container":"mp4","Part":[{"key":"/library/parts/42/file.mp4"}]}""",
            ),
        )
        assertEquals("42", v.id)
        assertEquals("4k", v.videoResolution)
        assertEquals("hevc", v.videoCodec)
        assertEquals(25000, v.bitrate)
        assertEquals(3840, v.width)
        assertEquals(2160, v.height)
        assertEquals("mp4", v.container)
        assertEquals("/library/parts/42/file.mp4", v.parts.single().streamPath)
    }

    @Test
    fun `stacked parts take the media id first then id and position`() {
        val v = PlexMappers.mediaVersion(obj("""{"id":5,"Part":[{"key":"/a"},{"key":"/b"}]}"""))
        assertEquals(listOf("5", "5:1"), v.parts.map { it.id })
        val bare = PlexMappers.mediaVersion(obj("""{"id":6,"container":"mkv"}"""))
        assertEquals("6", bare.parts.single().id)
        assertEquals("mkv", bare.parts.single().container)
    }
}

class PlexCreditsDetectionSuppressionTest {
    private val extras = PlaybackExtras(
        chapters = emptyList(),
        markers = listOf(MediaMarker(1, MediaMarker.INTRO, 0, 60_000), MediaMarker(2, MediaMarker.CREDITS, 300_000, 351_280)),
    )
    private val episode = obj("""{"ratingKey":"ep-1","type":"episode","grandparentRatingKey":"show-1"}""")

    private fun show(preference: Int?) =
        obj(if (preference == null) """{"ratingKey":"show-1"}""" else """{"ratingKey":"show-1","enableCreditsMarkerGeneration":$preference}""")

    @Test
    fun `keeps credits markers when the show row is unavailable or the lookup fails`() = runTest {
        assertEquals(extras, plexApplyCreditsDetectionPreference(extras, episode) { null })
        assertEquals(extras, plexApplyCreditsDetectionPreference(extras, episode) { throw IllegalStateException("offline") })
    }

    @Test
    fun `credits detection is disabled only by an explicit 0`() {
        assertTrue(plexCreditsDetectionDisabled(show(0)))
        assertFalse(plexCreditsDetectionDisabled(show(-1)))
        assertFalse(plexCreditsDetectionDisabled(show(null)))
        assertFalse(plexCreditsDetectionDisabled(null))
    }
}
