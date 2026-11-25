package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaStreamKind
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject

/** `BaseItemDto` → neutral model. */
class JellyfinMappersTest {
    private val serverId = "jf-machine-1"

    private fun map(json: String, absolutizer: JellyfinImageAbsolutizer? = null, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN, serverName: String? = null): MediaItem? =
        JellyfinMappers.mediaItem(Json.parseToJsonElement(json).jsonObject, serverId, serverName, absolutizer, dialect)

    private fun item(json: String) = map(json)!!

    private fun library(json: String, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN) =
        JellyfinMappers.library(Json.parseToJsonElement(json).jsonObject, serverId, null, dialect)

    @Test fun mapsMovieWithWatchStateRatingsGenresAndPeople() {
        val item = map(
            """
            {"Id":"abc123","Name":"Inception","OriginalTitle":"Inception","Type":"Movie","Overview":"Dream within a dream.",
             "Taglines":["Your mind is the scene of the crime."],"ProductionYear":2010,"PremiereDate":"2010-07-16T00:00:00.0000000Z",
             "OfficialRating":"PG-13","CommunityRating":8.8,"CriticRating":88,"Genres":["Action","Sci-Fi"],
             "People":[{"Type":"Actor","Name":"Leo","Id":"p1","PrimaryImageTag":"tag1","Role":"Cobb"},{"Type":"Director","Name":"Christopher Nolan"}],
             "Studios":[{"Name":"Warner Bros"}],"ProductionLocations":["United States"],"RunTimeTicks":88800000000,
             "UserData":{"PlayCount":1,"PlaybackPositionTicks":30000000000,"Played":true,"LastPlayedDate":"2026-04-25T20:00:00.0000000Z"},
             "DateCreated":"2025-01-15T10:00:00.0000000Z","DateLastSaved":"2026-03-01T10:00:00.0000000Z",
             "ImageTags":{"Primary":"thumbtag","Logo":"logotag"},"BackdropImageTags":["backtag","backtag-2","backtag-3"]}
            """,
            serverName = "Home",
        )!!
        assertEquals("abc123", item.id)
        assertEquals(BackendKind.JELLYFIN, item.backend)
        assertEquals(MediaKind.MOVIE, item.kind)
        assertEquals("Inception", item.title)
        assertEquals("Dream within a dream.", item.summary)
        assertEquals("Your mind is the scene of the crime.", item.tagline)
        assertEquals(2010, item.year)
        assertEquals("2010-07-16", item.originallyAvailableAt)
        assertEquals(1736935200L, item.addedAt)
        assertEquals(1772359200L, item.updatedAt)
        assertEquals(1777147200L, item.lastViewedAt)
        assertEquals("PG-13", item.contentRating)
        assertEquals("Warner Bros", item.studio)
        assertEquals(8.8, item.rating)
        assertEquals(listOf("audience", "rottenTomatoesCritic"), item.ratings?.map { it.source })
        // CriticRating is the 0–100 Tomatometer; the neutral scale is 0–10.
        assertEquals(listOf(8.8, 8.8), item.ratings?.map { it.value })
        assertEquals(listOf("Action", "Sci-Fi"), item.genres)
        assertEquals(listOf("Christopher Nolan"), item.directors)
        assertEquals(listOf("United States"), item.countries)
        val role = item.roles!!.single()
        assertEquals("Leo", role.tag)
        assertEquals("Cobb", role.role)
        assertEquals("/Items/p1/Images/Primary?tag=tag1", role.thumbPath)
        assertEquals(8_880_000L, item.durationMs)
        assertEquals(3_000_000L, item.viewOffsetMs)
        assertEquals(1, item.viewCount)
        assertEquals("/Items/abc123/Images/Primary?tag=thumbtag", item.thumbPath)
        assertEquals("/Items/abc123/Images/Backdrop/0?tag=backtag", item.artPath)
        assertEquals(
            listOf("/Items/abc123/Images/Backdrop/0?tag=backtag", "/Items/abc123/Images/Backdrop/1?tag=backtag-2", "/Items/abc123/Images/Backdrop/2?tag=backtag-3"),
            item.backdropPaths,
        )
        assertEquals("/Items/abc123/Images/Logo?tag=logotag", item.clearLogoPath)
        assertEquals(serverId, item.serverId)
        assertEquals("Home", item.serverName)
        assertEquals("abc123", item.raw?.get("Id")?.let { (it as kotlinx.serialization.json.JsonPrimitive).content })
    }

    @Test fun embyDialectStampsBackendAndKeepsOpaqueIds() {
        val item = map("""{"Id":"7330","Name":"Movie","Type":"Movie","MediaSources":[{"Id":"mediasource_7330","MediaStreams":[]}]}""", dialect = MediaBrowserDialect.EMBY)!!
        assertEquals("7330", item.id)
        assertEquals(BackendKind.EMBY, item.backend)
        assertEquals("mediasource_7330", item.mediaVersions!!.single().id)
        assertEquals("mediasource_7330", item.mediaVersions!!.single().parts.single().id)
    }

    @Test fun dividesTheTomatometerRatherThanRangeSniffing() {
        // 9 means 9%, not 9.0/10.
        val rating = item("""{"Id":"movie-rotten","Type":"Movie","CriticRating":9}""").ratings!!.single()
        assertEquals("rottenTomatoesCritic", rating.source)
        assertTrue(abs(rating.value - 0.9) < 1e-9)
    }

    @Test fun photosGetNoRatingsBecauseCommunityRatingIsExifStars() {
        val photo = item("""{"Id":"photo-1","Type":"Photo","CommunityRating":4}""")
        assertEquals(MediaKind.PHOTO, photo.kind)
        assertNull(photo.ratings)
        assertNull(item("""{"Id":"movie-bare","Type":"Movie"}""").ratings)
    }

    @Test fun keepsBackdropIndicesDeduplicatesTagsAndAbsolutizes() {
        val item = map(
            """{"Id":"movie-1","Type":"Movie","BackdropImageTags":["first",42,"","first","fifth"]}""",
            absolutizer = JellyfinImageAbsolutizer("https://jellyfin.example"),
        )!!
        assertEquals("https://jellyfin.example/Items/movie-1/Images/Backdrop/0?tag=first", item.artPath)
        assertEquals(
            listOf(
                "https://jellyfin.example/Items/movie-1/Images/Backdrop/0?tag=first",
                "https://jellyfin.example/Items/movie-1/Images/Backdrop/4?tag=fifth",
            ),
            item.backdropPaths,
        )
    }

    @Test fun playCountWithoutPlayedIsNotWatched() {
        val item = item("""{"Id":"started-only","Name":"Started Only","Type":"Movie","UserData":{"PlayCount":1,"Played":false}}""")
        assertEquals(0, item.viewCount)
        assertFalse(item.isWatched)
    }

    @Test fun mapsIsFavoriteAndIgnoresLikes() {
        val item = item("""{"Id":"fav-1","Name":"Favorited Movie","Type":"Movie","UserData":{"IsFavorite":true,"Likes":true}}""")
        assertEquals(true, item.isFavorite)
        assertNull(item.userRating)
        assertNull(item("""{"Id":"no-userdata","Name":"No UserData","Type":"Movie"}""").isFavorite)
    }

    @Test fun genericVideoTypesArePlayableClips() {
        val video = item("""{"Id":"home-video","Name":"Home Video","Type":"Video"}""")
        val musicVideo = item("""{"Id":"music-video","Name":"Music Video","Type":"MusicVideo"}""")
        assertEquals(MediaKind.CLIP, video.kind)
        assertEquals(MediaKind.CLIP, musicVideo.kind)
        assertTrue(video.kind.isVideo)
        assertTrue(musicVideo.kind.isVideo)
    }

    @Test fun musicVideoWatchStateIgnoresRecursiveAndChildCounts() {
        fun musicVideo(played: Boolean) = item(
            """{"Id":"music-video","Name":"Music Video","Type":"MusicVideo","RecursiveItemCount":"1","ChildCount":1,
               "UserData":{"Played":$played,"PlayCount":"${if (played) 1 else 0}","UnplayedItemCount":"0"}}""",
        )
        val unplayed = musicVideo(false)
        assertEquals(1, unplayed.leafCount)
        assertNull(unplayed.viewedLeafCount)
        assertFalse(unplayed.isWatched)
        assertTrue(musicVideo(true).isWatched)
    }

    @Test fun episodeKeepsSeriesAndSeasonHierarchy() {
        val item = item(
            """{"Id":"ep1","Name":"Pilot","Type":"Episode","IndexNumber":1,"ParentIndexNumber":1,"SeriesId":"series-1","SeriesName":"Breaking Bad",
               "SeriesPrimaryImageTag":"seriesPrimary","SeasonId":"season-1","SeasonName":"Season 1","SeasonPrimaryImageTag":"seasonPrimary",
               "UserData":{"UnplayedItemCount":0}}""",
        )
        assertEquals(MediaKind.EPISODE, item.kind)
        assertEquals(1, item.index)
        assertEquals(1, item.parentIndex)
        assertEquals("season-1", item.parentId)
        assertEquals("Season 1", item.parentTitle)
        assertEquals("/Items/season-1/Images/Primary?tag=seasonPrimary", item.parentThumbPath)
        assertEquals("series-1", item.grandparentId)
        assertEquals("Breaking Bad", item.grandparentTitle)
        assertEquals("/Items/series-1/Images/Primary?tag=seriesPrimary", item.grandparentThumbPath)
        assertEquals("/Items/series-1/Images/Backdrop/0", item.grandparentArtPath)
    }

    @Test fun episodeMapsEveryInheritedSeriesBackdrop() {
        val item = item(
            """{"Id":"ep-parent-art","Type":"Episode","SeriesId":"series-fallback","ParentBackdropItemId":"series-parent",
               "ParentBackdropImageTags":["parent-0","parent-1","parent-2"]}""",
        )
        val expected = listOf(
            "/Items/series-parent/Images/Backdrop/0?tag=parent-0",
            "/Items/series-parent/Images/Backdrop/1?tag=parent-1",
            "/Items/series-parent/Images/Backdrop/2?tag=parent-2",
        )
        assertEquals(expected[0], item.grandparentArtPath)
        assertEquals(expected, item.grandparentBackdropPaths)
        assertEquals(expected, item.heroBackdropPaths)
    }

    @Test fun seasonWithoutOwnBackdropsHeroesInheritedSeriesBackdrops() {
        val item = item(
            """{"Id":"season-parent-art","Type":"Season","SeriesId":"series-1","BackdropImageTags":[],"ParentBackdropItemId":"series-1",
               "ParentBackdropImageTags":["parent-0","parent-1"]}""",
        )
        assertEquals(listOf("/Items/series-1/Images/Backdrop/0?tag=parent-0", "/Items/series-1/Images/Backdrop/1?tag=parent-1"), item.heroBackdropPaths)
    }

    @Test fun seasonPosterFallsBackToSeriesPosterWithoutSeasonTag() {
        val item = item(
            """{"Id":"ep1","Name":"Pilot","Type":"Episode","SeriesId":"series-1","SeriesName":"Breaking Bad","SeriesPrimaryImageTag":"seriesPrimary",
               "SeasonId":"season-1","SeasonName":"Season 1"}""",
        )
        assertEquals("/Items/season-1/Images/Primary", item.parentThumbPath)
        assertEquals("/Items/series-1/Images/Primary?tag=seriesPrimary", item.grandparentThumbPath)
        assertEquals("/Items/season-1/Images/Primary", item.posterThumb(EpisodePosterMode.SEASON_POSTER))
        assertEquals("/Items/series-1/Images/Primary?tag=seriesPrimary", item.posterThumbFallback(EpisodePosterMode.SEASON_POSTER))
    }

    @Test fun seriesViewedLeafCountIsTotalMinusUnplayed() {
        val item = item("""{"Id":"s1","Name":"Show","Type":"Series","ChildCount":12,"RecursiveItemCount":12,"UserData":{"UnplayedItemCount":4}}""")
        assertEquals(12, item.leafCount)
        assertEquals(8, item.viewedLeafCount)
        assertTrue(item.isPartiallyWatched)
        assertFalse(item.isWatched)
    }

    @Test fun containerCountsTolerateScalarDriftAndClampInvalidUnplayed() {
        val item = item("""{"Id":"s-invalid-counts","Name":"Show","Type":"Series","RecursiveItemCount":"5","ChildCount":2.0,"UserData":{"UnplayedItemCount":"8"}}""")
        assertEquals(5, item.leafCount)
        assertEquals(2, item.childCount)
        assertEquals(0, item.viewedLeafCount)
        assertEquals(5, item.unwatchedCount)
        assertFalse(item.isWatched)
    }

    @Test fun seriesLeafCountPrefersRecursiveItemCount() {
        // ChildCount is the season count; leaves are episodes.
        val item = item("""{"Id":"s2","Name":"Show with seasons","Type":"Series","ChildCount":4,"RecursiveItemCount":50,"UserData":{"UnplayedItemCount":7}}""")
        assertEquals(50, item.leafCount)
        assertEquals(43, item.viewedLeafCount)
    }

    @Test fun pathEncodesImageIdsAndTags() {
        val item = item(
            """{"Id":"folder/item #1?x","Type":"Episode","Name":"Reserved IDs","SeriesId":"series/id #1?x","SeriesPrimaryImageTag":"series/tag ?x",
               "ParentLogoItemId":"logo/id #1?x","ParentLogoImageTag":"logo/tag ?x","ImageTags":{"Primary":"primary/tag ?x"},
               "People":[{"Type":"Actor","Name":"Actor","Id":"person/id #1?x","PrimaryImageTag":"person/tag ?x"}]}""",
        )
        assertEquals("/Items/folder%2Fitem%20%231%3Fx/Images/Primary?tag=primary%2Ftag%20%3Fx", item.thumbPath)
        assertEquals("/Items/series%2Fid%20%231%3Fx/Images/Primary?tag=series%2Ftag%20%3Fx", item.grandparentThumbPath)
        assertEquals("/Items/logo%2Fid%20%231%3Fx/Images/Logo?tag=logo%2Ftag%20%3Fx", item.clearLogoPath)
        assertEquals("/Items/person%2Fid%20%231%3Fx/Images/Primary?tag=person%2Ftag%20%3Fx", item.roles!!.single().thumbPath)
    }

    @Test fun mediaVersionsMapSourcesAndStreams() {
        val item = item(
            """
            {"Id":"movie-1","Name":"Movie","Type":"Movie","MediaSources":[{"Id":"src-1","Container":"mkv","Bitrate":8000000,"Size":10737418240,
              "RunTimeTicks":60000000000,"MediaStreams":[
                {"Index":0,"Type":"Video","Codec":"h264","IsDefault":true,"RealFrameRate":23.976,"Width":1920,"Height":1080},
                {"Index":1,"Type":"Audio","Codec":"eac3","Language":"eng","DisplayLanguage":"English","Channels":6,"IsDefault":true},
                {"Index":2,"Type":"Subtitle","Codec":"srt","Language":"eng","IsExternal":true,"IsForced":true,"DeliveryUrl":"/Videos/movie-1/movie-1/Subtitles/2/Stream.srt"}
              ]}]}
            """,
        )
        val v = item.mediaVersions!!.single()
        assertEquals("src-1", v.id)
        assertEquals(1920 to 1080, v.width to v.height)
        assertEquals("1080", v.videoResolution)
        assertEquals("h264", v.videoCodec)
        // Bitrate bps → kbps.
        assertEquals(8000, v.bitrate)
        assertEquals("mkv", v.container)
        val part = v.parts.single()
        assertEquals("src-1", part.id)
        assertEquals("/Videos/src-1/stream", part.streamPath)
        assertEquals(10737418240L, part.sizeBytes)
        assertEquals(6_000_000L, part.durationMs)
        val video = part.streams.first { it.kind == MediaStreamKind.VIDEO }
        assertEquals("h264", video.codec)
        assertTrue(abs(video.frameRate!! - 23.976) < 0.001)
        assertTrue(video.selected)
        val audio = part.streams.first { it.kind == MediaStreamKind.AUDIO }
        assertEquals("eac3", audio.codec)
        assertEquals(6, audio.channels)
        assertEquals("eng", audio.languageCode)
        val subtitle = part.streams.first { it.kind == MediaStreamKind.SUBTITLE }
        assertTrue(subtitle.forced)
        assertTrue(subtitle.isExternal)
        assertEquals("/Videos/movie-1/movie-1/Subtitles/2/Stream.srt", subtitle.sidecarPath)
    }

    @Test fun mediaStreamsMapDolbyVisionHdrAndSourceDefaultAudio() {
        val streams = item(
            """
            {"Id":"movie-1","Name":"Movie","Type":"Movie","MediaSources":[{"Id":"src-1","DefaultAudioStreamIndex":2,"MediaStreams":[
              {"Index":0,"Type":"Video","Codec":"hevc","Width":3840,"Height":2160,"VideoRangeType":"DOVI","VideoRange":"HDR",
               "VideoDoViTitle":"Dolby Vision Profile 8","DvProfile":8,"DvLevel":6,"DvBlSignalCompatibilityId":1},
              {"Index":1,"Type":"Audio","Codec":"eac3","Channels":6,"IsDefault":true},
              {"Index":2,"Type":"Audio","Codec":"aac","Channels":2}
            ]}]}
            """,
        ).mediaVersions!!.single().parts.single().streams
        val video = streams.first { it.kind == MediaStreamKind.VIDEO }
        assertEquals("hevc", video.codec)
        assertTrue(video.hdr)
        assertTrue(video.dolbyVision)
        assertEquals(8, video.dolbyVisionProfile)
        assertFalse(streams.first { it.index == 1 }.selected)
        assertTrue(streams.first { it.index == 2 }.selected)
    }

    @Test fun mediaStreamsMapHdrWithoutDolbyVision() {
        val video = item(
            """{"Id":"movie-1","Name":"Movie","Type":"Movie","MediaSources":[{"Id":"src-1","MediaStreams":[
               {"Index":0,"Type":"Video","Codec":"hevc","VideoRangeType":"HDR10","VideoRange":"HDR"}]}]}""",
        ).mediaVersions!!.single().parts.single().streams.single()
        assertTrue(video.hdr)
        assertFalse(video.dolbyVision)
        assertNull(video.dolbyVisionProfile)
    }

    @Test fun neverDerivesLibraryIdentityFromItemFields() {
        val item = map(
            """{"Id":"movie-1","Type":"Movie","Name":"Movie","ParentId":"folder-1","SeriesStudio":"Studio X","ParentLibraryId":"lib-1","ParentLibraryName":"Movies"}""",
            serverName = "Home",
        )!!
        assertNull(item.libraryId)
        assertNull(item.libraryTitle)
    }

    @Test fun libraryKindFromCollectionType() {
        val cases = mapOf(
            "movies" to MediaKind.MOVIE,
            "tvshows" to MediaKind.SHOW,
            "music" to MediaKind.ARTIST,
            "musicvideos" to MediaKind.CLIP,
            "homevideos" to MediaKind.CLIP,
            "photos" to MediaKind.PHOTO,
            "boxsets" to MediaKind.COLLECTION,
            "playlists" to MediaKind.PLAYLIST,
        )
        for ((type, kind) in cases) {
            val lib = library("""{"Id":"view-$type","Name":"Library","CollectionType":"$type"}""")!!
            assertEquals(kind, lib.kind, type)
            assertEquals(BackendKind.JELLYFIN, lib.backend)
        }
        assertEquals(BackendKind.EMBY, library("""{"Id":"view-movies","Name":"Movies","CollectionType":"movies"}""", MediaBrowserDialect.EMBY)!!.backend)
    }

    @Test fun libraryDatesAndTitleFallback() {
        val lib = library("""{"Id":"v","CollectionType":"movies","DateCreated":"2025-01-15T10:00:00Z","DateModified":"2026-03-01T10:00:00Z"}""")!!
        assertEquals(1736935200L, lib.createdAt)
        assertEquals(1772359200L, lib.updatedAt)
        assertTrue(lib.title.isNotEmpty())
    }

    @Test fun collectionFolderWithoutContentTypeBrowsesMoviesAndShows() {
        for (view in listOf(
            """{"Id":"view-missing-type","Name":"Mixed","Type":"CollectionFolder","IsFolder":true}""",
            """{"Id":"view-empty-type","Name":"Mixed","Type":"CollectionFolder","CollectionType":"","IsFolder":true}""",
        )) {
            val mixed = library(view)!!
            assertEquals(MediaKind.FOLDER, mixed.kind)
            assertEquals(listOf(MediaKind.MOVIE, MediaKind.SHOW), mixed.defaultBrowseKinds)
        }
        val books = library("""{"Id":"view-books","Name":"Books","Type":"CollectionFolder","CollectionType":"books"}""")!!
        assertEquals(MediaKind.UNKNOWN, books.kind)
        assertTrue(books.defaultBrowseKinds.isEmpty())
    }

    @Test fun minimalAndNullFieldsDegradeGracefully() {
        val bare = map("""{"Id":"bare-1","Type":"Movie"}""", serverName = "Home")!!
        assertEquals(MediaKind.MOVIE, bare.kind)
        assertNull(bare.summary)
        assertNull(bare.year)
        assertFalse(bare.isWatched)
        assertTrue(bare.genres.isNullOrEmpty())
        assertTrue(bare.directors.isNullOrEmpty())
        assertNull(bare.viewOffsetMs)
        assertNull(bare.lastViewedAt)

        val nulls = item("""{"Id":"i","Type":"Movie","Name":"X","People":null,"Genres":null,"Studios":null,"ProductionLocations":null,"MediaSources":null,"RunTimeTicks":"not-a-number"}""")
        assertTrue(nulls.writers.isNullOrEmpty())
        assertTrue(nulls.roles.isNullOrEmpty())
        assertNull(nulls.studio)
        assertTrue(nulls.countries.isNullOrEmpty())
        assertTrue(nulls.mediaVersions.isNullOrEmpty())
        assertNull(nulls.durationMs)
    }

    @Test fun rejectsMissingOrEmptyIds() {
        assertNull(map("""{"Type":"Movie","Name":"noId"}"""))
        assertNull(map("""{"Id":"","Type":"Movie","Name":"emptyId"}"""))
        assertNull(library("""{"Name":"Library","CollectionType":"movies"}"""))
        val item = item(
            """{"Id":"movie-x","Type":"Movie","MediaSources":[{"Container":"mkv","Bitrate":8000000,"MediaStreams":[]},
               {"Id":"src-ok","Container":"mp4","Bitrate":4000000,"MediaStreams":[]}]}""",
        )
        assertEquals(listOf("src-ok"), item.mediaVersions!!.map { it.id })
    }

    @Test fun ticksAndDateConversions() {
        assertEquals(1234L, JellyfinTime.ticksToMs(12_345_678))
        assertEquals(12_340_000L, JellyfinTime.msToTicks(1234))
        assertEquals("2010-07-16", JellyfinTime.isoToYmd("2010-07-16T00:00:00.0000000Z"))
        assertEquals(1736935200L, JellyfinTime.isoToEpochSeconds("2025-01-15T10:00:00.0000000Z"))
        assertNull(JellyfinTime.isoToEpochSeconds(""))
    }
}
