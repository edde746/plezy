package com.edde746.plezy.metadata

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.testData
import com.edde746.plezy.jellyfin.FakeResponse
import com.edde746.plezy.jellyfin.JellyfinApiCache
import com.edde746.plezy.jellyfin.JellyfinCacheResolver
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.jellyfin.JellyfinDeviceIdentity
import com.edde746.plezy.jellyfin.JellyfinTestServer
import com.edde746.plezy.jellyfin.RecordedRequest
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

internal const val MB_DTO = """{"Id":"item-1","Name":"Old Name","Type":"Movie","PremiereDate":"2001-02-03T00:00:00.0000000Z",""" +
    """"ProductionYear":2001,"ProviderIds":{"Tmdb":"9"},"Trickplay":{"x":1},"LockData":false,"LockedFields":["Name"],""" +
    """"Genres":["Drama"],"TagItems":[{"Name":"kids","Id":"t1"}],"Studios":[{"Name":"Studio A","Id":"s1"}],""" +
    """"People":[{"Name":"Ann","Id":"p1","Type":"Director","PrimaryImageTag":"img"},{"Name":"Bob","Id":"p2","Type":"Actor"}]}"""

/** A Jellyfin (or Emby) server over fake HTTP answering the editor's routes. */
internal fun mbServer(dto: String = MB_DTO, itemStatus: Int = 200) = JellyfinTestServer { req ->
    when {
        req.method == "GET" && req.path == "/Users/user-1/Items/item-1" -> FakeResponse(itemStatus, if (itemStatus == 200) dto else "")
        req.path == "/Items/Filters" -> FakeResponse(body = """{"Tags":["kids","horror"],"Genres":["Drama"]}""")
        req.path == "/Tags" -> FakeResponse(body = """{"Items":[{"Name":"kids"},{"Name":"horror"}]}""")
        req.path == "/Items/item-1/RemoteImages" -> FakeResponse(
            body = """{"Images":[{"Url":"https://img/a.jpg","ThumbnailUrl":"https://img/a_t.jpg","ProviderName":"TheMovieDb","Width":1000,"Height":1500},""" +
                """{"Url":"https://img/b.jpg","ThumbnailUrl":""},{"Url":""}]}""",
        )
        req.method == "POST" -> FakeResponse(204, "")
        else -> FakeResponse(404, "")
    }
}

internal fun mbItem(kind: MediaKind = MediaKind.MOVIE) =
    MediaItem(id = "item-1", backend = BackendKind.JELLYFIN, kind = kind, title = "Row", serverId = "machine-1", thumbPath = "/Items/item-1/Images/Primary")

/** A client of [server] whose Live TV favourites are [data]'s. */
internal fun TestScope.mbClient(server: JellyfinTestServer, data: LocalData, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN): JellyfinClient {
    val connection = server.connection(dialect)
    return JellyfinClient(
        connection = connection,
        http = server.http,
        identity = JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", connection.deviceId),
        cache = JellyfinApiCache(server.store, JellyfinCacheResolver(server.store, { listOf(connection) }, { emptyList() })),
        scope = CoroutineScope(coroutineContext),
        favorites = data.liveTvFavorites,
    )
}

class JellyfinMetadataEditAdapterTest {
    private val data = testData()

    @AfterTest
    fun closeData() = data.close()

    private fun posted(server: JellyfinTestServer): JsonObject =
        Json.parseToJsonElement(server.requests.single { it.method == "POST" && it.path == "/Items/item-1" }.body).jsonObject

    @Test
    fun `load fails when the full editable Jellyfin DTO is unavailable`() = runTest {
        val adapter = JellyfinMetadataEditAdapter(mbClient(mbServer(itemStatus = 404), data))
        assertFailsWith<IllegalStateException> { adapter.load(mbItem()) }
    }

    @Test
    fun `values come from the dto with no advanced section`() = runTest {
        val adapter = JellyfinMetadataEditAdapter(mbClient(mbServer(), data))
        val draft = adapter.load(mbItem())
        assertEquals("Old Name", draft.text("title"))
        assertEquals("2001-02-03", draft.text("originallyAvailableAt"))
        assertEquals(listOf("Studio A"), draft.list("studio"))
        assertEquals(listOf("kids"), draft.list("label"))
        assertEquals(listOf("Ann"), draft.list("director"))
        val schema = adapter.schema(draft)
        assertEquals(listOf("basic", "tags", "artwork"), schema.map { it.id })
        assertEquals(MetadataFieldType.STRING_LIST, schema[0].fields.first { it.id == "studio" }.type)
        assertEquals(listOf("genre", "director", "writer", "producer", "country", "label"), schema[1].fields.map { it.id })
        assertEquals(listOf("artwork:Primary", "artwork:Backdrop", "artwork:Logo"), schema[2].fields.map { it.id })
    }

    @Test
    fun `an episode tags only its director and writer and a season has no tags section`() = runTest {
        val adapter = JellyfinMetadataEditAdapter(mbClient(mbServer(), data))
        val episode = adapter.schema(adapter.load(mbItem(MediaKind.EPISODE)))
        assertEquals(listOf("director", "writer"), episode.first { it.id == "tags" }.fields.map { it.id })
        val season = adapter.schema(adapter.load(mbItem(MediaKind.SEASON)))
        assertEquals(listOf("basic", "artwork"), season.map { it.id })
    }

    @Test
    fun `every field is read from its dto name with names trimmed and blanks dropped`() = runTest {
        val dto = """{"Id":"item-1","Type":"Movie","ForcedSortName":"Sort","OriginalTitle":"Orig","OfficialRating":"PG-13",""" +
            """"PremiereDate":"1999-12-31T00:00:00.0000000Z","Taglines":["First line","Second line"],"Overview":"Plot",""" +
            """"GenreItems":[{"Name":" Drama "},{"Name":" "}],"ProductionLocations":["France"],"Studios":[{"Name":"A"},{"Name":"B"}],""" +
            """"Tags":["kids"],"People":[{"Name":" Ann ","Type":"director"},{"Name":"Wes","Type":"Writer"},""" +
            """{"Name":"Pat","Type":"PRODUCER"},{"Name":"Bob","Type":"Actor"},{"Name":" ","Type":"Director"}]}"""
        val draft = JellyfinMetadataEditAdapter(mbClient(mbServer(dto), data)).load(mbItem())
        assertEquals("Row", draft.text("title"), "without a Name, the item's own title")
        assertEquals("Sort", draft.text("titleSort"))
        assertEquals("Orig", draft.text("originalTitle"))
        assertEquals("1999-12-31", draft.text("originallyAvailableAt"))
        assertEquals("PG-13", draft.text("contentRating"))
        assertEquals(listOf("A", "B"), draft.list("studio"))
        assertEquals("First line", draft.text("tagline"))
        assertEquals("Plot", draft.text("summary"))
        assertEquals(listOf("Drama"), draft.list("genre"))
        assertEquals(listOf("Ann"), draft.list("director"))
        assertEquals(listOf("Wes"), draft.list("writer"))
        assertEquals(listOf("Pat"), draft.list("producer"))
        assertEquals(listOf("France"), draft.list("country"))
        assertEquals(listOf("kids"), draft.list("label"))
    }

    @Test
    fun `episode poster artwork uses 16x9 thumbnail geometry`() = runTest {
        val adapter = JellyfinMetadataEditAdapter(mbClient(mbServer(), data))
        val draft = adapter.load(mbItem(MediaKind.EPISODE))
        val poster = adapter.schema(draft).last().fields.first().artwork!!
        assertEquals(80, poster.previewWidth)
        assertEquals(45, poster.previewHeight)
        assertEquals(2, poster.gridColumns)
        assertEquals(16.0 / 9, poster.gridAspectRatio)
    }

    @Test
    fun `save reposts the whole dto with only the changes`() = runTest {
        val server = mbServer()
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data))
        val draft = adapter.load(mbItem()).with("title", "  New Name ").with("director", listOf("ann", "Cid"))
        val saved = assertNotNull(adapter.save(draft))
        assertFalse(adapter.hasChanges(saved))
        val dto = posted(server)
        assertEquals("New Name", dto["Name"]!!.jsonPrimitive.content)
        assertEquals("9", dto["ProviderIds"]!!.jsonObject["Tmdb"]!!.jsonPrimitive.content)
        assertNull(dto["Trickplay"])
        assertEquals("[\"Name\"]", dto["LockedFields"].toString())
        assertEquals("2001-02-03T00:00:00.0000000Z", dto["PremiereDate"]!!.jsonPrimitive.content)
        val people = dto["People"]!!.jsonArray.map { it.jsonObject }
        assertEquals(listOf("Bob", "ann", "Cid"), people.map { it["Name"]!!.jsonPrimitive.content })
        assertEquals("p1", people[1]["Id"]!!.jsonPrimitive.content)
        assertEquals("img", people[1]["PrimaryImageTag"]!!.jsonPrimitive.content)
        assertEquals("[{\"Name\":\"Studio A\",\"Id\":\"s1\"}]", dto["Studios"].toString())
        assertEquals("[\"kids\"]", dto["Tags"].toString())
        assertEquals(saved.raw, dto)
    }

    @Test
    fun `genres changed on the server while editing survive a summary save`() = runTest {
        var dto = MB_DTO
        val base = mbServer()
        val server = JellyfinTestServer { req -> if (req.method == "GET" && req.path == "/Users/user-1/Items/item-1") FakeResponse(body = dto) else base.handler(req) }
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data))
        val draft = adapter.load(mbItem()).with("summary", "New summary")
        dto = MB_DTO.replace("\"Genres\":[\"Drama\"]", "\"Genres\":[\"Drama\",\"Comedy\"]")
        assertNotNull(adapter.save(draft))
        val posted = posted(server)
        assertEquals("New summary", posted["Overview"]!!.jsonPrimitive.content)
        assertEquals("[\"Drama\",\"Comedy\"]", posted["Genres"].toString())
    }

    @Test
    fun `release date edit synchronizes ProductionYear with the new year`() = runTest {
        val server = mbServer()
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data))
        adapter.save(adapter.load(mbItem()).with("originallyAvailableAt", "1999-12-31"))
        val dto = posted(server)
        assertEquals("1999-12-31", dto["PremiereDate"]!!.jsonPrimitive.content)
        assertEquals(1999, dto["ProductionYear"]!!.jsonPrimitive.content.toInt())
    }

    @Test
    fun `clearing the release date also clears ProductionYear`() = runTest {
        val server = mbServer()
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data))
        adapter.save(adapter.load(mbItem()).with("originallyAvailableAt", ""))
        val dto = posted(server)
        assertEquals(JsonNull, dto["PremiereDate"])
        assertEquals(JsonNull, dto["ProductionYear"])
    }

    @Test
    fun `Emby save mirrors genres and tags into the name pair arrays`() = runTest {
        val server = mbServer()
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data, MediaBrowserDialect.EMBY))
        adapter.save(adapter.load(mbItem().copy(backend = BackendKind.EMBY)).with("summary", "x"))
        val dto = posted(server)
        assertEquals("[{\"Name\":\"Drama\"}]", dto["GenreItems"].toString())
        assertEquals("[{\"Name\":\"kids\"}]", dto["TagItems"].toString())
        assertEquals("[\"kids\"]", dto["Tags"].toString())
    }

    @Test
    fun `Jellyfin save does not send the name pair arrays`() = runTest {
        val server = mbServer(dto = MB_DTO.replace(""""TagItems":[{"Name":"kids","Id":"t1"}]""", """"Tags":["kids"]"""))
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data))
        adapter.save(adapter.load(mbItem()).with("label", listOf("kids", "new")))
        val dto = posted(server)
        assertNull(dto["TagItems"])
        assertNull(dto["GenreItems"])
        assertEquals("[\"kids\",\"new\"]", dto["Tags"].toString())
    }

    @Test
    fun `label suggestions come from the server wide Tags facet`() = runTest {
        val server = mbServer()
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data))
        val draft = adapter.load(mbItem())
        assertEquals(listOf("kids", "horror"), adapter.tagSuggestions(draft, tagField("label", "Label")))
        assertTrue(server.requests.any { it.path == "/Items/Filters" })
    }

    @Test
    fun `Emby label suggestions come from the per facet Tags route`() = runTest {
        val server = mbServer()
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data, MediaBrowserDialect.EMBY))
        val draft = adapter.load(mbItem())
        assertEquals(listOf("kids", "horror"), adapter.tagSuggestions(draft, tagField("label", "Label")))
        assertTrue(server.requests.any { it.path == "/Tags" })
    }

    @Test
    fun `fields without a server facet return no suggestions without a request`() = runTest {
        val server = mbServer()
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data))
        val draft = adapter.load(mbItem())
        val before = server.requests.size
        assertEquals(emptyList(), adapter.tagSuggestions(draft, tagField("director", "Director")))
        assertEquals(before, server.requests.size)
    }

    @Test
    fun `remote images list provider candidates and apply by download`() = runTest {
        val server = mbServer()
        val adapter = JellyfinMetadataEditAdapter(mbClient(server, data))
        val draft = adapter.load(mbItem())
        val poster = adapter.schema(draft).last().fields.first()
        val options = adapter.artwork(draft, poster)
        assertEquals(listOf("https://img/a.jpg", "https://img/b.jpg"), options.map { it.sourceUrl })
        assertEquals(listOf("https://img/a_t.jpg", "https://img/b.jpg"), options.map { it.thumbnailPath })
        assertEquals("TheMovieDb", options[0].provider)
        assertEquals(1000, options[0].width)
        val list: RecordedRequest = server.single("/Items/item-1/RemoteImages")
        assertEquals(mapOf("type" to "Primary", "startIndex" to "0", "limit" to "60", "includeAllLanguages" to "false"), list.query)
        assertTrue(adapter.applyArtworkFromUrl(draft, poster, "https://img/a.jpg"))
        val download = server.single("/Items/item-1/RemoteImages/Download")
        assertEquals(mapOf("type" to "Primary", "imageUrl" to "https://img/a.jpg"), download.query)
    }
}
