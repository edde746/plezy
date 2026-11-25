package com.edde746.plezy.metadata

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.plex.MemoryApiCacheStore
import com.edde746.plezy.plex.PlexTagChange
import com.edde746.plezy.plex.applyMatch
import com.edde746.plezy.plex.TEST_SERVER_ID
import com.edde746.plezy.plex.jsonResponse
import com.edde746.plezy.plex.setArtworkFromUrl
import com.edde746.plezy.plex.testPlexClient
import com.edde746.plezy.plex.unmatchItem
import com.edde746.plezy.plex.updateMetadata
import com.edde746.plezy.plex.updateMetadataPrefs
import com.edde746.plezy.plex.uploadArtwork
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject

/** A Plex server over fake HTTP: the item, its preferences, its section's filters, and every request it saw. */
internal class FakePlexEditServer(
    private val type: String = "movie",
    private val section: String? = "1",
    private val genres: List<String> = listOf("Drama"),
    private val labels: List<String> = listOf("kids", "Action, Adventure"),
    private val prefs: String = """{"Setting":[{"id":"languageOverride","value":"de-DE"},{"id":"useOriginalTitle","value":true}]}""",
    private val prefsStatus: Int = 200,
    var putStatus: Int = 200,
    private val itemStatus: Int = 200,
) {
    val requests = mutableListOf<HttpRequestData>()
    val puts get() = requests.filter { it.method == HttpMethod.Put }
    val client = testPlexClient({ request -> answer(request) })

    private fun tags(name: String, values: List<String>) = values.joinToString(",", "\"$name\":[", "]") { "{\"tag\":\"$it\"}" }

    private fun metadata(withPrefs: Boolean): String {
        val sectionPart = section?.let { "\"librarySectionID\":$it," }.orEmpty()
        val prefsPart = if (withPrefs) ",\"Preferences\":$prefs" else ""
        return """{"MediaContainer":{"Metadata":[{"ratingKey":"1","key":"/library/metadata/1","type":"$type","title":"Old Title",""" +
            """$sectionPart"summary":"Old summary","studio":"Studio A","thumb":"/library/metadata/1/thumb/1",""" +
            "${tags("Genre", genres)},${tags("Label", labels)},${tags("Style", listOf("Noir"))}$prefsPart}]}}"
    }

    private fun MockRequestHandleScope.answer(request: HttpRequestData): HttpResponseData {
        requests += request
        val path = request.url.encodedPath
        return when {
            request.method == HttpMethod.Put -> respond("", HttpStatusCode.fromValue(putStatus))
            path == "/library/metadata/1" && request.url.parameters["includePreferences"] == "1" ->
                jsonResponse(metadata(withPrefs = true), prefsStatus)
            path == "/library/metadata/1" -> jsonResponse(metadata(withPrefs = false), itemStatus)
            path == "/library/metadata/1/posters" -> jsonResponse(
                """{"MediaContainer":{"Metadata":[{"ratingKey":"https://img/a.jpg","thumb":"/t/a","selected":true},""" +
                    """{"key":"https://img/b.jpg"},{"thumb":"/t/none"}]}}""",
            )
            path == "/library/sections/1/filters" -> jsonResponse(
                """{"MediaContainer":{"Directory":[{"filter":"genre","key":"/library/sections/1/genre"},{"filter":"label","key":"/library/sections/1/label"}]}}""",
            )
            path == "/library/sections/1/label" -> jsonResponse("""{"MediaContainer":{"Directory":[{"key":"1","title":"kids"},{"key":"2","title":""},{"key":"3","title":"horror"}]}}""")
            else -> jsonResponse("{}", 404)
        }
    }
}

internal fun plexRow(type: MediaKind = MediaKind.MOVIE, libraryId: String? = "1") = MediaItem(
    id = "1", backend = BackendKind.PLEX, kind = type, title = "Row Title", summary = "Row summary", libraryId = libraryId, serverId = "server-1",
)

class PlexMetadataEditAdapterTest {
    @Test
    fun `the editor loads full metadata even for a row that has a summary and library id`() = runTest {
        val server = FakePlexEditServer()
        val draft = PlexMetadataEditAdapter(server.client).load(plexRow())
        assertEquals("Old Title", draft.text("title"))
        assertEquals(listOf("kids", "Action, Adventure"), draft.list("label"))
        assertEquals(listOf("Noir"), draft.list("style"))
        assertTrue(server.requests.any { it.url.encodedPath == "/library/metadata/1" && it.url.parameters["includePreferences"] == null })
    }

    @Test
    fun `the editor refuses to start from a partial row when the item cannot be fetched`() = runTest {
        val server = FakePlexEditServer(itemStatus = 404)
        assertFailsWith<IllegalStateException> { PlexMetadataEditAdapter(server.client).load(plexRow()) }
    }

    @Test
    fun `metadata preference request uses includePreferences and canonicalizes server values`() = runTest {
        val draft = PlexMetadataEditAdapter(FakePlexEditServer().client).load(plexRow())
        assertEquals("de-DE", draft.text("pref:languageOverride"))
        assertEquals("1", draft.text("pref:useOriginalTitle"))
    }

    @Test
    fun `missing preference rows remain unset instead of becoming fabricated defaults`() = runTest {
        val draft = PlexMetadataEditAdapter(FakePlexEditServer(type = "show", prefs = """{"Setting":[]}""").client).load(plexRow(MediaKind.SHOW))
        assertTrue("pref:episodeSort" in draft.values)
        assertNull(draft.values["pref:episodeSort"])
    }

    @Test
    fun `metadata preference request failures preserve the editable basic fields`() = runTest {
        val draft = PlexMetadataEditAdapter(FakePlexEditServer(prefsStatus = 500).client).load(plexRow())
        assertEquals("Old Title", draft.text("title"))
        assertNull(draft.values["pref:languageOverride"])
    }

    @Test
    fun `episodes load no preferences and have no advanced section`() = runTest {
        val server = FakePlexEditServer(type = "episode")
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow(MediaKind.EPISODE))
        assertFalse(server.requests.any { it.url.parameters["includePreferences"] != null })
        assertEquals(listOf("basic", "tags", "artwork"), adapter.schema(draft).map { it.id })
        assertEquals(listOf("director", "writer"), adapter.schema(draft)[1].fields.map { it.id })
        val poster = adapter.schema(draft)[2].fields.first().artwork!!
        assertEquals(2, poster.gridColumns)
        assertEquals(16.0 / 9, poster.gridAspectRatio)
    }

    @Test
    fun `sections and fields follow the kind`() = runTest {
        val adapter = PlexMetadataEditAdapter(FakePlexEditServer().client)
        val movie = adapter.schema(adapter.load(plexRow()))
        assertEquals(listOf("basic", "tags", "artwork", "advanced"), movie.map { it.id })
        assertEquals(
            listOf("title", "titleSort", "originalTitle", "originallyAvailableAt", "contentRating", "studio", "tagline", "summary"),
            movie[0].fields.map { it.id },
        )
        assertEquals(listOf("genre", "director", "writer", "producer", "country", "collection", "label"), movie[1].fields.map { it.id })
        assertEquals(listOf("artwork:posters", "artwork:arts", "artwork:clearLogos", "artwork:squareArts"), movie[2].fields.map { it.id })
        assertEquals(listOf("pref:languageOverride", "pref:useOriginalTitle"), movie[3].fields.map { it.id })
        val languages = movie[3].fields[0].options
        assertEquals(46, languages.size)
        assertEquals(MetadataOption("en-AU", "English (Australia)"), languages.first { it.value == "en-AU" })

        val season = adapter.schema(adapter.load(plexRow(MediaKind.SEASON)))
        assertEquals(listOf("basic", "artwork", "advanced"), season.map { it.id })
        assertEquals(listOf("title", "summary"), season[0].fields.map { it.id })
        assertEquals(listOf("pref:audioLanguage", "pref:subtitleLanguage", "pref:subtitleMode"), season[2].fields.map { it.id })
        assertEquals(T_SERIES_DEFAULT, season[2].fields[2].options.first().label)
    }

    @Test
    fun `a show has the movies seven tag fields and its style and mood load without showing`() = runTest {
        val adapter = PlexMetadataEditAdapter(FakePlexEditServer(type = "show").client)
        val draft = adapter.load(plexRow(MediaKind.SHOW))
        val sections = adapter.schema(draft)
        val tags = sections.first { it.id == "tags" }.fields
        assertEquals(listOf("genre", "director", "writer", "producer", "country", "collection", "label"), tags.map { it.id })
        assertEquals(listOf("Genre", "Director", "Writer", "Producer", "Country", "Collection", "Label"), tags.map { it.label })
        assertEquals(listOf("Noir"), draft.list("style"))
        assertTrue(sections.flatMap { it.fields }.none { it.id == "style" || it.id == "mood" })
    }

    @Test
    fun `the editor fails over to the next endpoint and takes the section from the container`() = runTest {
        val client = testPlexClient(
            { request ->
                when {
                    request.url.host == "plex.example.com" -> throw ConnectTimeoutException("primary down")
                    request.url.encodedPath == "/identity" -> jsonResponse("""{"MediaContainer":{"machineIdentifier":"$TEST_SERVER_ID"}}""")
                    request.url.encodedPath == "/library/metadata/1" && request.url.parameters["includePreferences"] == null ->
                        jsonResponse("""{"MediaContainer":{"librarySectionID":7,"Metadata":[{"ratingKey":"1","type":"movie","title":"Fresh"}]}}""")
                    else -> jsonResponse("{}", 404)
                }
            },
            baseUrl = "https://plex.example.com",
            prioritizedEndpoints = listOf("https://plex.example.com", "https://plex-fallback.example.com"),
        )
        val draft = PlexMetadataEditAdapter(client).load(plexRow(libraryId = null))
        assertEquals("Fresh", draft.text("title"))
        assertEquals("7", draft.currentItem.libraryId)
    }

    @Test
    fun `the editor never starts from the cached item when the server fails`() = runTest {
        var status = 200
        val client = testPlexClient({ request ->
            if (request.url.encodedPath == "/library/metadata/1") {
                jsonResponse("""{"MediaContainer":{"Metadata":[{"ratingKey":"1","type":"movie","title":"Cached","librarySectionID":1}]}}""", status)
            } else {
                jsonResponse("{}", 404)
            }
        })
        assertEquals("Cached", client.fetchItem("1")?.title)
        status = 500
        assertFails { PlexMetadataEditAdapter(client).load(plexRow()) }
    }

    @Test
    fun `save sends only changed fields locked and the tag diff`() = runTest {
        val server = FakePlexEditServer()
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow()).with("title", "New Title").with("summary", "").with("genre", listOf("Drama", "War"))
        val saved = adapter.save(draft)
        assertNotNull(saved)
        assertFalse(adapter.hasChanges(saved))
        val put = server.puts.single()
        assertEquals("/library/sections/1/all", put.url.encodedPath)
        val q = put.url.parameters
        assertEquals("1", q["type"])
        assertEquals("1", q["id"])
        assertEquals("New Title", q["title.value"])
        assertEquals("1", q["title.locked"])
        assertEquals("", q["summary.value"])
        assertNull(q["studio.value"])
        assertEquals("Drama", q["genre[0].tag.tag"])
        assertEquals("War", q["genre[1].tag.tag"])
        assertEquals("1", q["genre.locked"])
        assertNull(q["label.locked"])
    }

    @Test
    fun `removed tags are emitted single encoded because the transport encodes exactly once`() = runTest {
        val server = FakePlexEditServer(labels = listOf("kids", "Science Fiction"))
        val adapter = PlexMetadataEditAdapter(server.client)
        adapter.save(adapter.load(plexRow()).with("label", listOf("kids")))
        val query = server.puts.single().url.encodedQuery
        assertTrue("Science%20Fiction" in query || "Science+Fiction" in query, query)
        assertFalse("%2520" in query, query)
    }

    @Test
    fun `a removed tag containing a comma travels one removal per request`() = runTest {
        val server = FakePlexEditServer()
        val adapter = PlexMetadataEditAdapter(server.client)
        assertNotNull(adapter.save(adapter.load(plexRow()).with("label", listOf("kids"))))
        assertEquals(listOf(null, "Action, Adventure"), server.puts.map { it.url.parameters["label[].tag.tag-"] })
        assertEquals("kids", server.puts[1].url.parameters["label[0].tag.tag"])
        assertEquals("1", server.puts[1].url.parameters["label.locked"])
    }

    @Test
    fun `a failed comma tag removal fails the save and sends no later removal`() = runTest {
        val store = MemoryApiCacheStore()
        val puts = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            puts += request
            respond("", if (puts.size == 2) HttpStatusCode.InternalServerError else HttpStatusCode.OK)
        }, store = store)
        store.put(client.cacheServerId, "/library/metadata/1", JsonObject(emptyMap()))
        val change = PlexTagChange(current = listOf("kids"), original = listOf("kids", "a, b", "c, d"))
        assertFails { client.updateMetadata(sectionId = 1, ratingKey = "1", typeNumber = 1, tagChanges = mapOf("label" to change)) }
        assertEquals(listOf(null, "a, b"), puts.map { it.url.parameters["label[].tag.tag-"] })
        assertEquals(1, store.rows.size)
    }

    @Test
    fun `every successful edit drops the item from the cache`() = runTest {
        val store = MemoryApiCacheStore()
        val client = testPlexClient({ respond("", HttpStatusCode.OK) }, store = store)
        val edits: List<suspend () -> Boolean> = listOf(
            { client.updateMetadata(sectionId = 1, ratingKey = "1", typeNumber = 1, title = "New") },
            { client.applyMatch("1", "plex://movie/a") },
            { client.unmatchItem("1") },
            { client.setArtworkFromUrl("1", "posters", "https://img/a.jpg") },
            { client.uploadArtwork("1", "arts", byteArrayOf(1)) },
            { client.updateMetadataPrefs("1", mapOf("useOriginalTitle" to "1")) },
        )
        for (edit in edits) {
            store.put(client.cacheServerId, "/library/metadata/1", JsonObject(emptyMap()))
            store.put(client.cacheServerId, "/library/metadata/1/children", JsonObject(emptyMap()))
            store.put(client.cacheServerId, "/library/metadata/2", JsonObject(emptyMap()))
            assertTrue(edit())
            assertEquals(listOf("/library/metadata/2"), store.rows.keys.map { it.substringAfter(':') })
        }
    }

    @Test
    fun `show advanced settings offer their choices in order`() = runTest {
        val adapter = PlexMetadataEditAdapter(FakePlexEditServer(type = "show").client)
        val advanced = adapter.schema(adapter.load(plexRow(MediaKind.SHOW))).single { it.id == "advanced" }.fields
        assertEquals(
            listOf(
                "episodeSort", "autoDeletionItemPolicyUnwatchedLibrary", "autoDeletionItemPolicyWatchedLibrary", "flattenSeasons", "showOrdering",
                "languageOverride", "useOriginalTitle", "audioLanguage", "subtitleLanguage", "subtitleMode",
            ).map { "pref:$it" },
            advanced.map { it.id },
        )
        assertTrue(advanced.all { it.saveMode == MetadataSaveMode.IMMEDIATE })
        fun values(i: Int) = advanced[i].options.map { it.value }
        assertEquals(listOf("-1", "0", "1"), values(0))
        assertEquals(listOf("0", "5", "3", "1", "-3", "-7", "-30"), values(1))
        assertEquals("5 latest episodes", advanced[1].options[1].label)
        assertEquals(listOf("0", "1", "7", "30", "100"), values(2))
        assertEquals(listOf("-1", "0", "1"), values(3))
        assertEquals(listOf("", "tmdbAiring", "tvdbAiring", "tvdbAbsolute"), values(4))
        assertEquals("Library default", advanced[5].options.first().label)
        assertEquals("Account default", advanced[7].options.first().label)
    }

    @Test
    fun `language choices list the plex locales in order with english region names`() = runTest {
        val adapter = PlexMetadataEditAdapter(FakePlexEditServer(type = "show").client)
        val advanced = adapter.schema(adapter.load(plexRow(MediaKind.SHOW))).single { it.id == "advanced" }.fields
        val locales = listOf(
            "ar-SA", "bg-BG", "ca-ES", "zh-CN", "zh-HK", "zh-TW", "hr-HR", "cs-CZ", "da-DK", "nl-NL", "en-US", "en-AU", "en-CA",
            "en-GB", "et-EE", "fi-FI", "fr-FR", "fr-CA", "de-DE", "el-GR", "he-IL", "hi-IN", "hu-HU", "is-IS", "id-ID", "it-IT",
            "ja-JP", "ko-KR", "lv-LV", "lt-LT", "nb-NO", "fa-IR", "pl-PL", "pt-BR", "pt-PT", "ro-RO", "ru-RU", "sk-SK", "es-ES",
            "es-MX", "sv-SE", "th-TH", "tr-TR", "uk-UA", "vi-VN",
        )
        val metadata = advanced.single { it.id == "pref:languageOverride" }.options
        assertEquals(listOf("") + locales, metadata.map { it.value })
        val audio = advanced.single { it.id == "pref:audioLanguage" }.options
        assertEquals(listOf("", "en", "ja", "fr", "de", "it", "es", "pt", "ru", "ar") + locales, audio.map { it.value })
        assertEquals(audio, advanced.single { it.id == "pref:subtitleLanguage" }.options)
        val labels = metadata.associate { it.value to it.label }
        assertEquals("Portuguese (Brazil)", labels["pt-BR"])
        assertEquals("French (Canada)", labels["fr-CA"])
        assertEquals("English (UK)", labels["en-GB"])
        assertEquals("English", labels["en-US"])
        assertEquals("German", labels["de-DE"])
    }

    @Test
    fun `artwork fields follow the kind and fill from the item art`() = runTest {
        val adapter = PlexMetadataEditAdapter(FakePlexEditServer().client)
        val draft = adapter.load(plexRow())
        val movie = adapter.schema(draft).single { it.id == "artwork" }.fields.map { it.artwork!! }
        fun geometry(c: ArtworkConfig) = listOf(c.previewWidth, c.previewHeight, c.gridColumns)
        assertEquals(listOf("posters", "arts", "clearLogos", "squareArts"), movie.map { it.key })
        assertEquals(listOf(listOf(40, 60, 3), listOf(80, 45, 2), listOf(80, 32, 2), listOf(50, 50, 3)), movie.map(::geometry))
        assertEquals(listOf(2.0 / 3, 16.0 / 9, 2.5, 1.0), movie.map { it.gridAspectRatio })
        assertEquals(listOf(ArtworkFit.COVER, ArtworkFit.COVER, ArtworkFit.CONTAIN, ArtworkFit.COVER), movie.map { it.fit })
        assertEquals("/library/metadata/1/thumb/1", draft.values["artwork:posters"])

        val season = adapter.schema(adapter.load(plexRow(MediaKind.SEASON))).single { it.id == "artwork" }.fields
        assertEquals(listOf("artwork:posters"), season.map { it.id })
        val episode = adapter.schema(adapter.load(plexRow(MediaKind.EPISODE))).single { it.id == "artwork" }.fields.map { it.artwork!! }
        assertEquals(listOf(listOf(80, 45, 2), listOf(80, 45, 2)), episode.map(::geometry))
    }

    @Test
    fun `a failed artwork list offers nothing`() = runTest {
        val adapter = PlexMetadataEditAdapter(testPlexClient({ jsonResponse("{}", 500) }))
        val draft = MetadataDraft(sourceItem = plexRow(), currentItem = plexRow(), values = emptyMap())
        val poster = adapter.schema(draft).single { it.id == "artwork" }.fields.first()
        assertEquals(emptyList(), adapter.artwork(draft, poster))
    }

    @Test
    fun `an item without a numeric section saves nothing`() = runTest {
        val server = FakePlexEditServer(section = null)
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow(libraryId = null)).with("title", "New")
        assertNull(adapter.save(draft))
        assertTrue(server.puts.isEmpty())
    }

    @Test
    fun `a failed save keeps the changes`() = runTest {
        val server = FakePlexEditServer(putStatus = 500)
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow()).with("title", "New")
        assertFails { adapter.save(draft) }
        assertTrue(adapter.hasChanges(draft))
    }

    @Test
    fun `an immediate preference saves alone and a cleared one is sent empty`() = runTest {
        val server = FakePlexEditServer()
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow())
        val field = adapter.schema(draft).flatMap { it.fields }.first { it.id == "pref:useOriginalTitle" }
        val saved = adapter.saveImmediate(draft, field, "0")
        assertEquals("0", saved?.originalValues?.get(field.id))
        adapter.saveImmediate(draft, field, null)
        assertEquals(listOf("/library/metadata/1/prefs", "/library/metadata/1/prefs"), server.puts.map { it.url.encodedPath })
        assertEquals(listOf("0", ""), server.puts.map { it.url.parameters["useOriginalTitle"] })
        assertFalse(adapter.hasChanges(saved!!))
    }

    @Test
    fun `label suggestions come from the section label filter facet`() = runTest {
        val adapter = PlexMetadataEditAdapter(FakePlexEditServer().client)
        val draft = adapter.load(plexRow())
        assertEquals(listOf("kids", "horror"), adapter.tagSuggestions(draft, tagField("label", "Label")))
        assertEquals(emptyList(), adapter.tagSuggestions(draft, tagField("director", "Director")))
    }

    @Test
    fun `a section without a label facet returns no suggestions`() = runTest {
        val server = FakePlexEditServer()
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow())
        // The genre facet's values route answers 404: a failure is no suggestions.
        assertEquals(emptyList(), adapter.tagSuggestions(draft, tagField("genre", "Genre")))
    }

    @Test
    fun `an item without a library id skips the facet lookup`() = runTest {
        val server = FakePlexEditServer(section = null)
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow(libraryId = null))
        assertEquals(emptyList(), adapter.tagSuggestions(draft, tagField("label", "Label")))
        assertFalse(server.requests.any { "/filters" in it.url.encodedPath })
    }

    @Test
    fun `artwork lists the elements choices and applies one by url`() = runTest {
        val server = FakePlexEditServer()
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow())
        val poster = adapter.schema(draft).flatMap { it.fields }.first { it.id == "artwork:posters" }
        val options = adapter.artwork(draft, poster)
        assertEquals(listOf("https://img/a.jpg", "https://img/b.jpg"), options.map { it.sourceUrl })
        assertEquals(listOf("/t/a", "https://img/b.jpg"), options.map { it.thumbnailPath })
        assertEquals(listOf(true, false), options.map { it.selected })
        assertTrue(adapter.applyArtworkFromUrl(draft, poster, " https://img/b.jpg "))
        val put = server.puts.single()
        assertEquals("/library/metadata/1/poster", put.url.encodedPath)
        assertEquals("https://img/b.jpg", put.url.parameters["url"])
    }

    @Test
    fun `an artwork upload puts the bytes to the element`() = runTest {
        val server = FakePlexEditServer()
        val adapter = PlexMetadataEditAdapter(server.client)
        val draft = adapter.load(plexRow())
        val art = adapter.schema(draft).flatMap { it.fields }.first { it.id == "artwork:arts" }
        assertFalse(adapter.uploadArtwork(draft, art, ByteArray(0), "a.png"))
        assertTrue(adapter.uploadArtwork(draft, art, byteArrayOf(1, 2, 3), "a.png"))
        assertEquals("/library/metadata/1/art", server.puts.single().url.encodedPath)
    }

    private suspend fun assertFails(block: suspend () -> Unit) {
        val failed = try {
            block()
            false
        } catch (e: Exception) {
            true
        }
        assertTrue(failed)
    }

    private companion object {
        const val T_SERIES_DEFAULT = "Series default"
    }
}
