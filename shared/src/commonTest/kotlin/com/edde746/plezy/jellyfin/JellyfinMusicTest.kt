package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.LyricLine
import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlinx.coroutines.test.runTest

class JellyfinMusicTest {
    private val artist = MediaItem("artist-1", BackendKind.JELLYFIN, MediaKind.ARTIST)
    private val track = MediaItem("item-1", BackendKind.JELLYFIN, MediaKind.TRACK)

    @Test
    fun artistAlbumsAndAlbumTracksUseLeafFields() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[],"TotalRecordCount":0}""") }
        val music = JellyfinMusic(server.core())
        music.fetchArtistAlbums(artist)
        music.fetchAlbumTracks("album-1")
        assertEquals(
            mapOf(
                "userId" to "user-1",
                "AlbumArtistIds" to "artist-1",
                "IncludeItemTypes" to "MusicAlbum",
                "Recursive" to "true",
                "SortBy" to "PremiereDate,ProductionYear,SortName",
                "SortOrder" to "Descending",
                "Fields" to "PremiereDate,OriginalTitle,SortName,DateCreated",
                "EnableUserData" to "false",
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            server.requests[0].query,
        )
        assertEquals(
            mapOf(
                "userId" to "user-1",
                "AlbumIds" to "album-1",
                "IncludeItemTypes" to "Audio",
                "Recursive" to "true",
                "SortBy" to "ParentIndexNumber,IndexNumber,SortName",
                "SortOrder" to "Ascending",
                "Fields" to "UserData,PremiereDate,OriginalTitle,SortName",
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            server.requests[1].query,
        )
    }

    @Test
    fun discographyIsOneAlbumsGroup() = runTest {
        val server = JellyfinTestServer {
            FakeResponse(body = """{"Items":[{"Id":"album-1","Type":"MusicAlbum"},{"Id":"album-2","Type":"MusicAlbum"}],"TotalRecordCount":2}""")
        }
        val groups = JellyfinMusic(server.core()).fetchArtistDiscography(artist)
        assertEquals(DiscographyGroupKind.ALBUMS, groups.single().kind)
        assertEquals(listOf("album-1", "album-2"), groups.single().items.map { it.id })

        val empty = JellyfinTestServer { FakeResponse(body = """{"Items":[]}""") }
        assertEquals(emptyList(), JellyfinMusic(empty.core()).fetchArtistDiscography(artist))
    }

    @Test
    fun instantMixRoute() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[{"Id":"t","Type":"Audio"}]}""") }
        assertEquals(listOf("t"), JellyfinMusic(server.core()).fetchInstantMix("seed 1").map { it.id })
        assertEquals(
            mapOf(
                "userId" to "user-1",
                "Limit" to "100",
                "Fields" to "RecursiveItemCount,ChildCount,OriginalTitle,SortName,Overview,DateCreated,CanDelete",
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            server.single("/Items/seed%201/InstantMix").query,
        )
    }

    @Test
    fun embyReturnsNoLyricsWithoutRequestWhileJellyfinUsesItsRoute() = runTest {
        val emby = JellyfinTestServer { FakeResponse(500, "harmful request") }
        assertNull(JellyfinMusic(emby.core(MediaBrowserDialect.EMBY)).fetchLyrics(track))
        assertEquals(emptyList(), emby.requests)

        val jellyfin = JellyfinTestServer { FakeResponse(body = """{"Lyrics":[{"Text":"Line one"}]}""") }
        assertEquals(Lyrics(false, listOf(LyricLine("Line one"))), JellyfinMusic(jellyfin.core()).fetchLyrics(track))
        assertEquals("/Audio/item-1/Lyrics", jellyfin.requests.single().path)
        assertEquals("", jellyfin.requests.single().url.encodedQuery)
    }

    @Test
    fun lyricsAreSyncedWhenAnyLineHasAStart() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Lyrics":[{"Text":"a","Start":15000000},{"Text":"b"}]}""") }
        assertEquals(Lyrics(true, listOf(LyricLine("a", 1500), LyricLine("b"))), JellyfinMusic(server.core()).fetchLyrics(track))
    }

    @Test
    fun missingOrEmptyLyricsAreNullAndOtherFailuresThrow() = runTest {
        assertNull(JellyfinMusic(JellyfinTestServer { FakeResponse(404, "") }.core()).fetchLyrics(track))
        assertNull(JellyfinMusic(JellyfinTestServer { FakeResponse(body = """{"Lyrics":[]}""") }.core()).fetchLyrics(track))
        val error = assertFailsWith<MediaServerHttpException> { JellyfinMusic(JellyfinTestServer { FakeResponse(500, "") }.core()).fetchLyrics(track) }
        assertEquals(500, error.statusCode)
    }
}
