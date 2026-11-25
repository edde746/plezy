package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject

class JellyfinMetadataEditTest {
    private val movie = MediaItem("item-1", BackendKind.JELLYFIN, MediaKind.MOVIE)
    private fun json(text: String) = Json.parseToJsonElement(text).jsonObject

    private val editableMovie = json(
        """{"Id":"item-1","Name":"Movie","Type":"Movie","ProviderIds":{"Tmdb":"123"},"Tags":["Favorite"],"Genres":["Drama"],
           "Studios":[{"Name":"Studio A","Id":"studio-a"},{"Name":"Studio B","Id":"studio-b"}],
           "People":[{"Name":"Alice","Type":"Director","Id":"person-alice","PrimaryImageTag":"alice-tag","ProviderIds":{"Imdb":"nm1"}},
                     {"Name":"Bob","Type":"Director","Id":"person-bob"},{"Name":"Wendy","Type":"Writer","Id":"person-wendy"},
                     {"Name":"Actor One","Type":"Actor","Role":"Hero","Id":"actor-1"}],
           "ProductionLocations":["US"],"Taglines":["Original tagline","Second tagline"],"LockedFields":["Overview"],"LockData":true,
           "PremiereDate":"2020-01-01T00:00:00.0000000Z","ProductionYear":1999,"Trickplay":{"1":{}}}""",
    )
    private val embyItem = json(
        """{"Id":"item-1","Name":"Movie","Type":"Movie","Overview":"Original summary","ProviderIds":{},"Genres":[],
           "GenreItems":[{"Name":"Action","Id":3}],"TagItems":[{"Name":"archive","Id":7}]}""",
    )
    private val jellyfinItem = json("""{"Id":"item-1","Name":"Movie","Type":"Movie","Overview":"Original summary","ProviderIds":{},"Genres":["Drama"],"Tags":["Favorite"]}""")

    private fun JsonObject.named(key: String, name: String) = this[key]!!.jsonArray.map { it.jsonObject }.single { (it["Name"] as JsonPrimitive).content == name }

    @Test
    fun editableItemIsTheFullUserScopedDto() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Id":"folder/item #1?x","Type":"Movie","ProviderIds":{"Tmdb":"1"}}""") }
        val item = JellyfinMetadataEdit(server.core()) {}.fetchEditableMetadataItem("folder/item #1?x")
        assertEquals(json("""{"Tmdb":"1"}"""), item?.get("ProviderIds"))
        assertEquals("/Users/user-1/Items/folder%2Fitem%20%231%3Fx", server.requests.single().path)
        assertEquals(emptyMap(), server.requests.single().query)
    }

    @Test
    fun editableItemIsNullOn404AndOffline() = runTest {
        val server = JellyfinTestServer { FakeResponse(404, "") }
        val core = server.core()
        assertNull(JellyfinMetadataEdit(core) {}.fetchEditableMetadataItem("item-1"))
        core.offlineMode = true
        assertNull(JellyfinMetadataEdit(core) {}.fetchEditableMetadataItem("item-1"))
        assertEquals(1, server.requests.size)
    }

    @Test
    fun updatePostsFullDtoAndInvalidatesTheItem() = runTest {
        val server = JellyfinTestServer { FakeResponse(204, "") }
        val invalidated = mutableListOf<String>()
        val dto = json("""{"Id":"item-1","Name":"Edited","Type":"Movie","ProviderIds":{"Tmdb":"123"},"Tags":["Favorite"]}""")
        assertTrue(JellyfinMetadataEdit(server.core()) { invalidated += it }.updateMetadataItem("item-1", dto))
        assertEquals("/Items/item-1", server.requests.single().path)
        assertEquals(dto, Json.parseToJsonElement(server.requests.single().body))
        assertEquals(listOf("item-1"), invalidated)
    }

    @Test
    fun everyArtworkWriteInvalidatesTheItemAndAFailedInvalidationKeepsTheWrite() = runTest {
        val server = JellyfinTestServer { FakeResponse(204, "") }
        val invalidated = mutableListOf<String>()
        val edit = JellyfinMetadataEdit(server.core()) { invalidated += it }
        assertTrue(edit.downloadRemoteImage("item-1", "Primary", "https://img.example/poster.jpg"))
        assertTrue(edit.uploadItemImage("item-1", "Backdrop", byteArrayOf(1, 2), "image/png"))
        assertEquals(listOf("item-1", "item-1"), invalidated)
        assertTrue(JellyfinMetadataEdit(server.core()) { error("cache unavailable") }.updateMetadataItem("item-1", jellyfinItem))
    }

    @Test
    fun remoteImageSearchAndApplyRoutes() = runTest {
        val server = JellyfinTestServer { req ->
            if (req.path == "/Items/item-1/RemoteImages") {
                FakeResponse(body = """{"TotalRecordCount":1,"Images":[{"ProviderName":"TheMovieDb","Url":"https://img.example/poster.jpg","Type":"Primary"}]}""")
            } else {
                FakeResponse(204, "")
            }
        }
        val edit = JellyfinMetadataEdit(server.core()) {}
        val result = edit.getRemoteImages("item-1", "Primary", limit = 20, providerName = "TheMovieDb")
        assertTrue(edit.downloadRemoteImage("item-1", "Primary", "https://img.example/poster.jpg"))
        assertEquals("https://img.example/poster.jpg", (result["Images"]!!.jsonArray.single().jsonObject["Url"] as JsonPrimitive).content)
        assertEquals(
            mapOf("type" to "Primary", "startIndex" to "0", "limit" to "20", "providerName" to "TheMovieDb", "includeAllLanguages" to "false"),
            server.requests[0].query,
        )
        assertEquals("/Items/item-1/RemoteImages/Download", server.requests[1].path)
        assertEquals(mapOf("type" to "Primary", "imageUrl" to "https://img.example/poster.jpg"), server.requests[1].query)
    }

    @OptIn(ExperimentalEncodingApi::class)
    @Test
    fun bothDialectsReceiveArtworkAsBase64TextTypedAsTheImage() = runTest {
        for (dialect in MediaBrowserDialect.entries) {
            val server = JellyfinTestServer { FakeResponse(204, "") }
            val bytes = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xE0.toByte(), 0x00, 0x10)
            assertTrue(JellyfinMetadataEdit(server.core(dialect)) {}.uploadItemImage("item-1", "Primary", bytes, "image/jpeg"))
            val sent = server.requests.single()
            assertEquals("POST /Items/item-1/Images/Primary", "${sent.method} ${sent.path}")
            assertEquals(Base64.encode(bytes), sent.body)
            assertContentEquals(bytes, Base64.decode(sent.body))
            assertTrue(sent.headers.getValue("Content-Type").startsWith("image/jpeg"))
        }
    }

    @Test
    fun jellyfinTagSuggestionsComeFromServerWideFilters() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Genres":["Drama"],"Tags":["kids","","horror"],"Years":[2020]}""") }
        assertEquals(listOf("kids", "horror"), JellyfinMetadataEdit(server.core()) {}.fetchTagFacetValues("Tags"))
        assertEquals(mapOf("userId" to "user-1"), server.single("/Items/Filters").query)
    }

    @Test
    fun embyTagSuggestionsComeFromThePerFacetRoute() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[{"Name":"kids"},{"Name":"horror"}]}""") }
        assertEquals(listOf("kids", "horror"), JellyfinMetadataEdit(server.core(MediaBrowserDialect.EMBY)) {}.fetchTagFacetValues("Tags"))
        assertEquals(mapOf("UserId" to "user-1", "Recursive" to "true"), server.single("/Tags").query)
    }

    @Test
    fun facetFailureYieldsNoSuggestions() = runTest {
        val server = JellyfinTestServer { FakeResponse(500, "boom") }
        assertEquals(emptyList(), JellyfinMetadataEdit(server.core()) {}.fetchTagFacetValues("Tags"))
    }

    @Test
    fun genreSuggestionsReadTheGenresFacetOnBothDialects() = runTest {
        val jellyfin = JellyfinTestServer { FakeResponse(body = """{"Genres":["Drama","Comedy"],"Tags":["kids"]}""") }
        assertEquals(listOf("Drama", "Comedy"), JellyfinMetadataEdit(jellyfin.core()) {}.fetchTagFacetValues("Genres"))
        assertEquals(mapOf("userId" to "user-1"), jellyfin.single("/Items/Filters").query)
        val emby = JellyfinTestServer { FakeResponse(body = """{"Items":[{"Name":"Drama"}]}""") }
        assertEquals(listOf("Drama"), JellyfinMetadataEdit(emby.core(MediaBrowserDialect.EMBY)) {}.fetchTagFacetValues("Genres"))
        assertEquals(mapOf("UserId" to "user-1", "Recursive" to "true"), emby.single("/Genres").query)
    }

    @Test
    fun savePreservesUnchangedPeopleAndStudioIdentity() {
        val body = JellyfinMetadataEditDto.applyEdits(
            editableMovie,
            mapOf("director" to listOf("Alice", "Charlie"), "studio" to listOf("Studio A", "Studio C"), "tagline" to "Updated tagline"),
            namePairs = false,
        )
        val people = body["People"]!!.jsonArray.map { it.jsonObject }
        assertFalse(people.any { (it["Name"] as JsonPrimitive).content == "Bob" })
        assertEquals(editableMovie.named("People", "Alice"), body.named("People", "Alice"))
        assertEquals(json("""{"Name":"Charlie","Type":"Director"}"""), body.named("People", "Charlie"))
        assertEquals(JsonPrimitive("actor-1"), body.named("People", "Actor One")["Id"])
        assertEquals(JsonPrimitive("person-wendy"), body.named("People", "Wendy")["Id"])
        val studios = body["Studios"]!!.jsonArray.map { it.jsonObject }
        assertEquals(listOf("Studio A", "Studio C"), studios.map { (it["Name"] as JsonPrimitive).content })
        assertEquals(JsonPrimitive("studio-a"), body.named("Studios", "Studio A")["Id"])
        assertEquals(json("""{"Name":"Studio C"}"""), body.named("Studios", "Studio C"))
        assertEquals(Json.parseToJsonElement("""["Updated tagline","Second tagline"]"""), body["Taglines"])
        assertFalse("Trickplay" in body)
        assertFalse("GenreItems" in body)
    }

    @Test
    fun changedScalarsAreTrimmedEmptyBecomesNullAndNothingIsLocked() {
        val body = JellyfinMetadataEditDto.applyEdits(
            editableMovie,
            mapOf("title" to "  New Name  ", "titleSort" to " Sort ", "originalTitle" to "", "contentRating" to " PG-13 ", "summary" to "   "),
            namePairs = false,
        )
        assertEquals(JsonPrimitive("New Name"), body["Name"])
        assertEquals(JsonPrimitive("Sort"), body["ForcedSortName"])
        assertEquals(JsonNull, body["OriginalTitle"])
        assertEquals(JsonPrimitive("PG-13"), body["OfficialRating"])
        assertEquals(JsonNull, body["Overview"])
        assertEquals(editableMovie["ProductionLocations"], body["ProductionLocations"])
        assertEquals(editableMovie["Taglines"], body["Taglines"])
        assertEquals(Json.parseToJsonElement("""["Overview"]"""), body["LockedFields"])
        assertEquals(JsonPrimitive(true), body["LockData"])
    }

    @Test
    fun taglineCountriesAndGenresReplaceTheirLists() {
        val cleared = JellyfinMetadataEditDto.applyEdits(editableMovie, mapOf("tagline" to " "), namePairs = false)
        assertEquals(JsonArray(emptyList()), cleared["Taglines"])
        val body = JellyfinMetadataEditDto.applyEdits(editableMovie, mapOf("country" to listOf("SE", "US"), "genre" to listOf("War")), namePairs = false)
        assertEquals(Json.parseToJsonElement("""["SE","US"]"""), body["ProductionLocations"])
        assertEquals(Json.parseToJsonElement("""["War"]"""), body["Genres"])
        assertEquals(editableMovie["Taglines"], body["Taglines"])
    }

    @Test
    fun releaseDateEditSynchronizesProductionYear() {
        val edited = JellyfinMetadataEditDto.applyEdits(editableMovie, mapOf("originallyAvailableAt" to "2001-07-14"), namePairs = false)
        assertEquals(JsonPrimitive("2001-07-14"), edited["PremiereDate"])
        assertEquals(JsonPrimitive(2001), edited["ProductionYear"])
        val sameDay = JellyfinMetadataEditDto.applyEdits(editableMovie, mapOf("originallyAvailableAt" to "2020-01-01"), namePairs = false)
        assertEquals(JsonPrimitive("2020-01-01T00:00:00.0000000Z"), sameDay["PremiereDate"])
        val cleared = JellyfinMetadataEditDto.applyEdits(editableMovie, mapOf("originallyAvailableAt" to ""), namePairs = false)
        assertEquals(JsonNull, cleared["PremiereDate"])
        assertEquals(JsonNull, cleared["ProductionYear"])
    }

    @Test
    fun embySaveMirrorsGenresAndTagsIntoNamePairs() {
        val body = JellyfinMetadataEditDto.applyEdits(embyItem, mapOf("genre" to listOf("Adventure", "Comedy"), "label" to listOf("family", "favorite")), namePairs = true)
        assertEquals(Json.parseToJsonElement("""[{"Name":"Adventure"},{"Name":"Comedy"}]"""), body["GenreItems"])
        assertEquals(Json.parseToJsonElement("""[{"Name":"family"},{"Name":"favorite"}]"""), body["TagItems"])
    }

    @Test
    fun jellyfinSaveSendsPlainListsOnly() {
        val body = JellyfinMetadataEditDto.applyEdits(jellyfinItem, mapOf("genre" to listOf("Adventure", "Comedy"), "label" to listOf("family", "favorite")), namePairs = false)
        assertEquals(JsonArray(listOf(JsonPrimitive("Adventure"), JsonPrimitive("Comedy"))), body["Genres"])
        assertEquals(JsonArray(listOf(JsonPrimitive("family"), JsonPrimitive("favorite"))), body["Tags"])
        assertFalse("GenreItems" in body)
        assertFalse("TagItems" in body)
    }

    @Test
    fun embyValuesAreReadFromNamePairsAndSurviveAnUnrelatedSave() {
        val values = JellyfinMetadataEditDto.readValues(embyItem, movie.copy(backend = BackendKind.EMBY))
        assertEquals(listOf("archive"), values["label"])
        assertEquals(listOf("Action"), values["genre"])
        val body = JellyfinMetadataEditDto.applyEdits(embyItem, mapOf("summary" to "Updated summary"), namePairs = true)
        assertEquals(JsonPrimitive("Updated summary"), body["Overview"])
        assertEquals(Json.parseToJsonElement("""[{"Name":"archive"}]"""), body["TagItems"])
    }

    @Test
    fun embyNamePairsFeedItemTagsAndGenresWhilePlainArraysWin() = runTest {
        val core = JellyfinTestServer().core(MediaBrowserDialect.EMBY)
        val item = core.mapItem(
            json("""{"Id":"7330","Name":"Movie 001","Type":"Movie","Genres":[],"GenreItems":[{"Name":"Action","Id":3},{"Name":"Science Fiction","Id":4}],"TagItems":[{"Name":"smoke-label","Id":7}]}"""),
        )!!
        assertEquals(listOf("smoke-label"), item.labels)
        assertEquals(listOf("Action", "Science Fiction"), item.genres)
        assertEquals(BackendKind.EMBY, item.backend)
        val both = core.mapItem(json("""{"Id":"1","Type":"Movie","Tags":["plain"],"TagItems":[{"Name":"pair"}]}"""))!!
        assertEquals(listOf("plain"), both.labels)
    }

    @Test
    fun uploadContentTypeIsSniffedThenNamed() {
        fun bytes(vararg b: Int) = ByteArray(b.size) { b[it].toByte() }
        val riff = "RIFF".encodeToByteArray() + bytes(0, 0, 0, 0) + "WEBP".encodeToByteArray()
        assertEquals("image/webp", JellyfinMetadataEditDto.imageContentType(riff, "x.jpg"))
        assertEquals("image/png", JellyfinMetadataEditDto.imageContentType(bytes(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A), null))
        assertEquals("image/jpeg", JellyfinMetadataEditDto.imageContentType(bytes(0xFF, 0xD8, 0xFF), null))
        assertEquals("image/gif", JellyfinMetadataEditDto.imageContentType("GIF89a".encodeToByteArray(), null))
        assertEquals("image/bmp", JellyfinMetadataEditDto.imageContentType(bytes(0x42, 0x4D), null))
        assertEquals("image/png", JellyfinMetadataEditDto.imageContentType(bytes(1, 2), "Poster.PNG"))
        assertEquals("image/jpeg", JellyfinMetadataEditDto.imageContentType(bytes(1, 2), null))
    }
}
