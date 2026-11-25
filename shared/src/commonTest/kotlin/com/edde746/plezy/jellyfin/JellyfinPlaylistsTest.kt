package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

class JellyfinPlaylistsTest {
    private fun playlists(server: JellyfinTestServer, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN): JellyfinPlaylists {
        val core = server.core(dialect)
        return JellyfinPlaylists(core) { id ->
            val response = core.get("/Users/user-1/Items/$id")
            response.obj?.let(core::mapItem)
        }
    }

    private val typedPlaylists = listOf(
        """{"Id":"video-1","Name":"Video Playlist","Type":"Playlist","MediaType":"Video"}""" to "Video",
        """{"Id":"audio-1","Name":"Audio Playlist","Type":"Playlist","MediaType":"Audio"}""" to "Audio",
        """{"Id":"photo-1","Name":"Photo Playlist","Type":"Playlist","MediaType":"Photo"}""" to "Photo",
    )

    @Test
    fun jellyfinFiltersByRequestedMediaType() = runTest {
        val server = JellyfinTestServer { req ->
            val items = typedPlaylists.filter { req.query["MediaTypes"] == null || it.second == req.query["MediaTypes"] }.map { it.first }
            FakeResponse(body = """{"Items":[${items.joinToString(",")}],"TotalRecordCount":${items.size}}""")
        }
        val page = playlists(server).fetchPlaylistsPage("video")
        assertEquals(listOf("video-1"), page.items.map { it.id })
        assertEquals(
            mapOf(
                "userId" to "user-1",
                "IncludeItemTypes" to "Playlist",
                "Recursive" to "true",
                "MediaTypes" to "Video",
                "StartIndex" to "0",
                "Limit" to "200",
                "Fields" to "Overview,DateCreated,DateLastSaved,DateModified,ChildCount,Tags",
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            server.single("/Items").query,
        )
    }

    @Test
    fun sendsRequestedOffsetAndReturnsServerTotal() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[{"Id":"video-40","Type":"Playlist"}],"TotalRecordCount":50}""") }
        val page = playlists(server).fetchPlaylistsPage("video", start = 20, size = 10)
        assertEquals(50, page.totalCount)
        assertEquals(20, page.offset)
        val query = server.single("/Items").query
        assertEquals("20", query["StartIndex"])
        assertEquals("10", query["Limit"])
    }

    @Test
    fun unsupportedTypeAndSmartReturnEmptyWithoutRequest() = runTest {
        val server = JellyfinTestServer { FakeResponse(500, "unexpected") }
        val unsupported = playlists(server).fetchPlaylistsPage("unsupported", start = 20, size = 10)
        assertEquals(emptyList(), unsupported.items)
        assertEquals(0, unsupported.totalCount)
        assertEquals(20, unsupported.offset)
        assertEquals(emptyList(), playlists(server).fetchPlaylistsPage("video", smart = true).items)
        assertEquals(emptyList(), server.requests)
    }

    @Test
    fun emptyTypeSendsNoMediaTypesAndLabelsVideo() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[{"Id":"p","Type":"Playlist"}]}""") }
        val page = playlists(server).fetchPlaylistsPage("")
        assertFalse("MediaTypes" in server.single("/Items").query)
        assertEquals("video", page.items.single().playlistType)
    }

    @Test
    fun embyOmitsMediaTypesAndLabelsUntypedPlaylistsWithRequestedType() = runTest {
        var n = 0
        val server = JellyfinTestServer { n++; FakeResponse(body = """{"Items":[{"Id":"playlist-$n","Name":"Playlist $n","Type":"Playlist"}],"TotalRecordCount":1}""") }
        val client = playlists(server, MediaBrowserDialect.EMBY)
        val video = client.fetchPlaylistsPage("video")
        val audio = client.fetchPlaylistsPage("audio")
        assertEquals(listOf("GET /Items", "GET /Items"), server.requests.map { "${it.method} ${it.path}" })
        server.requests.forEach {
            assertFalse("MediaTypes" in it.query)
            assertEquals("200", it.query["Limit"])
            assertEquals("", it.body)
        }
        assertEquals("video", video.items.single().playlistType)
        assertEquals("audio", audio.items.single().playlistType)
        assertEquals(BackendKind.EMBY, video.items.single().backend)
    }

    @Test
    fun embyPlaylistTimestampComesFromDateModified() = runTest {
        val server = JellyfinTestServer {
            FakeResponse(body = """{"Items":[{"Id":"pl-1","Name":"Road Trip","DateCreated":"2026-01-01T00:00:00.0000000Z","DateModified":"2026-02-03T04:05:06.0000000Z"}],"TotalRecordCount":1}""")
        }
        val playlist = playlists(server, MediaBrowserDialect.EMBY).fetchPlaylistsPage("video").items.single()
        assertEquals(1770091506L, playlist.updatedAt)
        assertEquals(1767225600L, playlist.addedAt)
    }

    @Test
    fun jellyfinDtoMediaTypeWinsOverRequestedLabel() = runTest {
        val server = JellyfinTestServer { req ->
            val type = req.query["MediaTypes"]!!
            FakeResponse(body = """{"Items":[{"Id":"p","Type":"Playlist","MediaType":"${if (type == "Video") "Audio" else "Video"}"}],"TotalRecordCount":1}""")
        }
        val client = playlists(server)
        assertEquals("audio", client.fetchPlaylistsPage("video").items.single().playlistType)
        assertEquals("video", client.fetchPlaylistsPage("audio").items.single().playlistType)
        assertEquals(listOf("Video", "Audio"), server.requests.map { it.query["MediaTypes"] })
    }

    @Test
    fun playlistThumbnailIsAbsoluteWithoutTheToken() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[{"Id":"video-1","Type":"Playlist","MediaType":"Video","ImageTags":{"Primary":"tag 1"}}]}""") }
        val thumb = playlists(server).fetchPlaylistsPage("video").items.single().thumbPath!!
        assertEquals("http://jf.local:8096/Items/video-1/Images/Primary", thumb.substringBefore('?'))
        assertEquals(mapOf("tag" to "tag 1"), JellyfinImageAbsolutizer.queryParams(thumb))
    }

    @Test
    fun playlistPageUsesRequestedBoundsAndFallbackTotal() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[${(0 until 10).joinToString(",") { """{"Id":"movie-$it","Type":"Movie"}""" }}]}""") }
        val page = playlists(server).fetchPlaylistPage("pl-1", start = 20, size = 10)
        assertEquals(10, page.items.size)
        assertEquals(31, page.totalCount)
        assertEquals(20, page.offset)
        val query = server.single("/Playlists/pl-1/Items").query
        assertEquals("20", query["StartIndex"])
        assertEquals("10", query["Limit"])
        assertEquals("RecursiveItemCount,ChildCount,OriginalTitle,SortName,Overview,DateCreated,CanDelete", query["Fields"])
    }

    @Test
    fun missingEntryIdReturnsFalseWithoutRequest() = runTest {
        val server = JellyfinTestServer {
            FakeResponse(body = """{"Items":[{"Id":"PRIVATE-ID","Name":"PRIVATE-TITLE","Type":"Movie"}],"TotalRecordCount":1}""")
        }
        val client = playlists(server)
        val item = client.fetchPlaylistPage("playlist").items.single()
        assertNull(item.playlistItemId)
        assertFalse(client.movePlaylistItem("playlist", item, 0, null))
        assertFalse(client.removeFromPlaylist("playlist", item))
        assertFalse(client.movePlaylistItem("playlist", MediaItem("x", BackendKind.PLEX, MediaKind.MOVIE, playlistItemId = "e"), 0, null))
        assertEquals(listOf("GET"), server.requests.map { it.method })
    }

    @Test
    fun validEntriesMoveAndRemove() = runTest {
        val server = JellyfinTestServer { req ->
            if (req.method == "GET") FakeResponse(body = """{"Items":[{"Id":"media-1","Type":"Movie","PlaylistItemId":"playlist-entry-1"}],"TotalRecordCount":1}""") else FakeResponse()
        }
        val client = playlists(server)
        val item = client.fetchPlaylistPage("playlist").items.single()
        assertEquals("playlist-entry-1", item.playlistItemId)
        assertTrue(client.movePlaylistItem("playlist", item, 3, null))
        assertTrue(client.removeFromPlaylist("playlist", item))
        assertEquals(listOf("GET", "POST", "DELETE"), server.requests.map { it.method })
        assertEquals("/Playlists/playlist/Items/playlist-entry-1/Move/3", server.requests[1].path)
        assertEquals("/Playlists/playlist/Items", server.requests[2].path)
        assertEquals("playlist-entry-1", server.requests[2].query["entryIds"])
    }

    @Test
    fun moveRequestFailureThrows() = runTest {
        val server = JellyfinTestServer { FakeResponse(500, "{}") }
        val entry = MediaItem("item-1", BackendKind.JELLYFIN, MediaKind.MOVIE, playlistItemId = "entry-1")
        assertFailsWith<MediaServerHttpException> { playlists(server).movePlaylistItem("playlist", entry, 0, null) }
    }

    @Test
    fun createReturnsMetadataNullOrThrows() = runTest {
        val valid = JellyfinTestServer { req ->
            when (req.path) {
                "/Playlists" -> FakeResponse(body = """{"Id":"playlist-1"}""")
                "/Users/user-1/Items/playlist-1" -> FakeResponse(body = """{"Id":"playlist-1","Name":"Playlist","Type":"Playlist","MediaType":"Audio"}""")
                "/Playlists/playlist-1/Items" -> FakeResponse(body = """{"Items":[{"Id":"t1","Type":"Audio","MediaType":"Audio"}],"TotalRecordCount":2}""")
                else -> FakeResponse(404, "{}")
            }
        }
        val track = MediaItem("t1", BackendKind.JELLYFIN, MediaKind.TRACK)
        assertEquals("playlist-1", playlists(valid).createPlaylist("My List", listOf(track, track.copy(id = "t2")))?.id)
        assertEquals(
            mapOf("Name" to "My List", "Ids" to "t1,t2", "UserId" to "user-1", "MediaType" to "Audio"),
            valid.single("/Playlists").query,
        )

        assertNull(playlists(JellyfinTestServer { FakeResponse(body = "{}") }).createPlaylist("Playlist", emptyList()))
        for (status in listOf(400, 500)) {
            val error = assertFailsWith<MediaServerHttpException> {
                playlists(JellyfinTestServer { FakeResponse(status, "{}") }).createPlaylist("Playlist", emptyList())
            }
            assertEquals(status, error.statusCode)
        }
    }

    @Test
    fun aPlaylistIsMusicWhenItsFirstEntryIs() = runTest {
        val entries = mapOf(
            "mix" to """{"Id":"t1","Type":"Audio","MediaType":"Audio"}""",
            "binge" to """{"Id":"e1","Type":"Episode","MediaType":"Video"}""",
            "empty" to null,
        )
        for (dialect in listOf(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.EMBY)) {
            val server = JellyfinTestServer { req ->
                val path = req.path
                when {
                    // The playlist itself carries no type, as on Emby.
                    path.startsWith("/Users/user-1/Items/") -> FakeResponse(body = """{"Id":"${path.substringAfterLast('/')}","Type":"Playlist"}""")
                    path.startsWith("/Playlists/") -> {
                        val first = entries[path.removePrefix("/Playlists/").removeSuffix("/Items")]
                        FakeResponse(body = """{"Items":[${first.orEmpty()}],"TotalRecordCount":${if (first == null) 0 else 4}}""")
                    }
                    else -> FakeResponse(404, "{}")
                }
            }
            val client = playlists(server, dialect)
            assertEquals("audio", client.fetchPlaylistMetadata("mix")?.playlistType, "$dialect music")
            assertEquals("video", client.fetchPlaylistMetadata("binge")?.playlistType, "$dialect episodes")
            assertEquals("video", client.fetchPlaylistMetadata("empty")?.playlistType, "$dialect empty")
        }
    }

    @Test
    fun addAndDeleteRoutes() = runTest {
        val server = JellyfinTestServer()
        val client = playlists(server)
        assertTrue(client.addToPlaylist("pl", emptyList()))
        assertEquals(emptyList(), server.requests)
        assertTrue(client.addToPlaylist("pl", listOf(MediaItem("a", BackendKind.JELLYFIN, MediaKind.MOVIE))))
        assertEquals(mapOf("Ids" to "a", "UserId" to "user-1"), server.single("/Playlists/pl/Items").query)
    }
}
