package com.edde746.plezy.metadata

import com.edde746.plezy.app.MetadataMenuEntries
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.MenuSlot
import com.edde746.plezy.presentation.browse.MenuTarget
import com.edde746.plezy.presentation.metadata.MetadataEditing
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import kotlin.test.assertNotNull
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.jsonResponse
import com.edde746.plezy.plex.testPlexClient
import com.edde746.plezy.presentation.metadata.EditorDialog
import com.edde746.plezy.presentation.metadata.EditorLoad
import com.edde746.plezy.presentation.metadata.MetadataEditDeps
import com.edde746.plezy.presentation.metadata.MetadataEditStore
import com.edde746.plezy.presentation.metadata.PlexMatchStore
import com.edde746.plezy.presentation.metadata.TagEditStore
import com.edde746.plezy.presentation.navigation.Route
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest

/**
 * The stores' scope: on the test's scheduler, so `advanceUntilIdle` runs them (it leaves `backgroundScope`'s work
 * alone once only that remains), but not the test's child, so the test ends without closing them.
 */
private fun TestScope.storeScope() = CoroutineScope(coroutineContext + Job())

/** What the stores told the app. */
private class RecordingDeps(client: MediaBackend?, recent: List<String> = emptyList()) {
    val notices = mutableListOf<String>()
    val closed = mutableListOf<Route>()
    val edited = mutableListOf<Pair<ServerId, String>>()
    val recorded = mutableListOf<Triple<List<String>, String, String>>()
    val deps = MetadataEditDeps(
        client = { client },
        recentTags = { _, _ -> recent },
        addRecentTags = { tags, server, field -> recorded += Triple(tags, server, field) },
        notify = { notices += it },
        close = { closed += it },
        edited = { s, i -> edited += s to i },
    )
}

class MetadataEditStoreTest {
    private val route = Route.MetadataEdit(ServerId("server-1"), "1")

    private fun TestScope.editor(server: FakePlexEditServer, deps: RecordingDeps = RecordingDeps(server.client)): MetadataEditStore =
        MetadataEditStore(route, deps.deps, storeScope()).also { advanceUntilIdle() }

    @Test
    fun `loads the item into sections of tiles`() = runTest {
        val store = editor(FakePlexEditServer())
        val state = store.state.value
        assertEquals(EditorLoad.READY, state.load)
        assertEquals(listOf("basic", "tags", "artwork", "advanced"), state.sections.map { it.id })
        val basic = state.sections[0].fields
        assertEquals("Old Title", basic.first { it.id == "title" }.value)
        assertNull(basic.first { it.id == "tagline" }.value)
        assertEquals("kids, Action, Adventure", state.sections[1].fields.first { it.id == "label" }.value)
        assertEquals("German", state.sections[3].fields[0].value)
        assertFalse(state.canSave)
    }

    @Test
    fun `a load failure says so without sections`() = runTest {
        val server = FakePlexEditServer(itemStatus = 404)
        val deps = RecordingDeps(server.client)
        val store = editor(server, deps)
        assertEquals(EditorLoad.FAILED, store.state.value.load)
        assertEquals(listOf("Failed to update metadata"), deps.notices)
    }

    @Test
    fun `final save rejects duplicate submit and back then recovers after failure`() = runTest {
        val server = FakePlexEditServer(putStatus = 500)
        val deps = RecordingDeps(server.client)
        val store = editor(server, deps)
        store.edit("title")
        store.submitText("New Title")
        assertTrue(store.state.value.canSave)
        store.save()
        assertTrue(store.state.value.committing)
        store.save()
        store.edit("summary")
        assertNull(store.state.value.dialog)
        advanceUntilIdle()
        assertEquals(1, server.puts.size)
        assertFalse(store.state.value.committing)
        assertTrue(store.state.value.canSave)
        assertEquals(listOf("Failed to update metadata"), deps.notices)
        assertTrue(deps.closed.isEmpty())

        server.putStatus = 200
        store.save()
        advanceUntilIdle()
        assertEquals(listOf("Failed to update metadata", "Metadata updated"), deps.notices)
        assertEquals(listOf<Route>(route), deps.closed)
    }

    @Test
    fun `a successful save records the added tags as recent`() = runTest {
        val server = FakePlexEditServer()
        val deps = RecordingDeps(server.client)
        val store = editor(server, deps)
        store.edit("label")
        val tags = assertIs<EditorDialog.Tags>(store.state.value.dialog).store
        tags.add("horror")
        store.submitTags()
        store.save()
        advanceUntilIdle()
        assertEquals(listOf(Triple(listOf("horror"), "server-1", "label")), deps.recorded)
    }

    @Test
    fun `the label field offers server tag suggestions as chips`() = runTest {
        val server = FakePlexEditServer(labels = listOf("kids"))
        val store = editor(server, RecordingDeps(server.client, recent = listOf("Recent", "KIDS")))
        store.edit("label")
        advanceUntilIdle()
        val tags = assertIs<EditorDialog.Tags>(store.state.value.dialog).store
        assertEquals(listOf("Recent", "horror"), tags.state.value.suggestions)
    }

    @Test
    fun `D pad arrows in a choice dialog move focus without committing a value`() = runTest {
        val server = FakePlexEditServer()
        val store = editor(server)
        store.edit("pref:useOriginalTitle")
        val choice = assertIs<EditorDialog.Choice>(store.state.value.dialog)
        assertEquals(listOf("-1", "0", "1"), choice.options.map { it.value })
        assertEquals("1", choice.selected)
        advanceUntilIdle()
        assertTrue(server.puts.isEmpty())
    }

    @Test
    fun `boolean preference selection and updates use canonical choice values`() = runTest {
        val server = FakePlexEditServer()
        val store = editor(server)
        store.edit("pref:useOriginalTitle")
        store.choose("0")
        assertTrue(store.state.value.committing)
        advanceUntilIdle()
        assertEquals("0", server.puts.single().url.parameters["useOriginalTitle"])
        assertFalse(store.state.value.committing)
        assertFalse(store.state.value.canSave)
        assertEquals("No", store.state.value.sections[3].fields[1].value)
    }

    @Test
    fun `immediate failure rolls back its value and re enables controls`() = runTest {
        val server = FakePlexEditServer(putStatus = 500)
        val deps = RecordingDeps(server.client)
        val store = editor(server, deps)
        store.edit("pref:useOriginalTitle")
        store.choose("0")
        assertEquals("No", store.state.value.sections[3].fields[1].value)
        advanceUntilIdle()
        assertFalse(store.state.value.committing)
        assertEquals("Yes", store.state.value.sections[3].fields[1].value)
        assertEquals(listOf("Failed to update metadata"), deps.notices)
    }

    @Test
    fun `artwork mutation blocks cancel and duplicate options until success`() = runTest {
        val server = FakePlexEditServer()
        val deps = RecordingDeps(server.client)
        val store = editor(server, deps)
        store.edit("artwork:posters")
        advanceUntilIdle()
        val picker = assertIs<EditorDialog.Artwork>(store.state.value.dialog).store
        assertEquals(listOf(true, false), picker.state.value.tiles.map { it.selected })
        assertEquals("Artwork option 1, selected", picker.state.value.tiles[0].label)
        picker.select(1)
        picker.select(0)
        store.dismissDialog()
        assertTrue(picker.state.value.applying)
        assertIs<EditorDialog.Artwork>(store.state.value.dialog)
        advanceUntilIdle()
        assertEquals(1, server.puts.size)
        assertNull(store.state.value.dialog)
        assertEquals(listOf("Artwork updated"), deps.notices)
    }

    @Test
    fun `upload failure keeps artwork dialog mounted`() = runTest {
        val server = FakePlexEditServer()
        val deps = RecordingDeps(server.client)
        val store = editor(server, deps)
        store.edit("artwork:arts")
        advanceUntilIdle()
        val picker = assertIs<EditorDialog.Artwork>(store.state.value.dialog).store
        server.putStatus = 500
        picker.upload(byteArrayOf(1), "a.png")
        advanceUntilIdle()
        assertIs<EditorDialog.Artwork>(store.state.value.dialog)
        assertFalse(picker.state.value.applying)
        assertEquals(listOf("Failed to update artwork"), deps.notices)
        store.dismissDialog()
        assertNull(store.state.value.dialog)
    }

    @Test
    fun `closing the editor refreshes the item`() = runTest {
        val server = FakePlexEditServer()
        val deps = RecordingDeps(server.client)
        editor(server, deps).close()
        assertEquals(listOf(ServerId("server-1") to "1"), deps.edited)
    }

    @Test
    fun `save without changes sends nothing and a text keeps its spaces`() = runTest {
        val server = FakePlexEditServer()
        val deps = RecordingDeps(server.client)
        val store = editor(server, deps)
        store.save()
        advanceUntilIdle()
        assertTrue(server.puts.isEmpty())
        assertTrue(deps.notices.isEmpty())
        store.edit("summary")
        val text = assertIs<EditorDialog.Text>(store.state.value.dialog)
        assertEquals("Old summary", text.value)
        assertTrue(text.multiline)
        store.submitText("  spaced  ")
        assertEquals("  spaced  ", store.state.value.sections[0].fields.first { it.id == "summary" }.value)
        assertTrue(store.state.value.canSave)
    }

    @Test
    fun `applied artwork reloads only the artwork and keeps pending edits`() = runTest {
        val server = FakePlexEditServer()
        val deps = RecordingDeps(server.client)
        val store = editor(server, deps)
        store.edit("title")
        store.submitText("Pending")
        store.edit("artwork:posters")
        advanceUntilIdle()
        fun itemFetches() = server.requests.count { it.url.encodedPath == "/library/metadata/1" && it.url.parameters["includePreferences"] == null }
        val before = itemFetches()
        assertIs<EditorDialog.Artwork>(store.state.value.dialog).store.select(1)
        advanceUntilIdle()
        assertNull(store.state.value.dialog)
        assertEquals(listOf("Artwork updated"), deps.notices)
        assertEquals("Pending", store.state.value.sections[0].fields.first { it.id == "title" }.value)
        assertTrue(store.state.value.canSave)
        assertEquals(before + 1, itemFetches())
    }

    @Test
    fun `the editor and the match screen ask for the server of the item`() = runTest {
        val server = FakePlexEditServer()
        val asked = mutableListOf<ServerId>()
        val recording = RecordingDeps(server.client)
        val deps = MetadataEditDeps({ asked += it; server.client }, recording.deps.recentTags, recording.deps.addRecentTags, recording.deps.notify, recording.deps.close, recording.deps.edited)
        MetadataEditStore(Route.MetadataEdit(ServerId("server-2"), "1"), deps, storeScope())
        PlexMatchStore(Route.PlexMatch(ServerId("server-3"), "1", "Old Title", null, matched = false), deps, storeScope())
        advanceUntilIdle()
        assertEquals(setOf(ServerId("server-2"), ServerId("server-3")), asked.toSet())
    }
}

class TagEditStoreTest {
    @Test
    fun `chips appear without applied tags and filter by typed text`() = runTest {
        val store = TagEditStore("Label", listOf("Kids"), { listOf("kids", "horror", "Hobbit", "drama") }, storeScope())
        advanceUntilIdle()
        assertEquals(listOf("horror", "Hobbit", "drama"), store.state.value.suggestions)
        store.setQuery("HO")
        assertEquals(listOf("horror", "Hobbit"), store.state.value.suggestions)
        assertTrue(store.add())
        assertEquals(listOf("Kids", "HO"), store.tags)
        assertEquals("", store.state.value.query)
    }

    @Test
    fun `duplicates in any case and blanks are not added`() = runTest {
        val store = TagEditStore("Label", listOf("Kids"), { emptyList() }, storeScope())
        assertFalse(store.add("  kids "))
        assertFalse(store.add("  "))
        assertTrue(store.add(" new "))
        store.remove(0)
        assertEquals(listOf("new"), store.tags)
    }

    @Test
    fun `suggestions cap at twelve`() = runTest {
        val store = TagEditStore("Label", emptyList(), { (1..20).map { "t$it" } }, storeScope())
        advanceUntilIdle()
        assertEquals(12, store.state.value.suggestions.size)
    }

    @Test
    fun `a failed suggestions future still leaves the dialog usable`() = runTest {
        val store = TagEditStore("Label", emptyList(), { error("boom") }, storeScope())
        advanceUntilIdle()
        assertEquals(emptyList(), store.state.value.suggestions)
        assertTrue(store.add("a"))
    }
}

class PlexMatchStoreTest {
    private val route = Route.PlexMatch(ServerId("server-1"), "1", "Old Title", 2001, matched = true)

    @Test
    fun `the first search runs at once and a pick applies the match`() = runTest {
        val gate = CompletableDeferred<Unit>()
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            when {
                request.url.encodedPath == "/library/metadata/1/matches" -> jsonResponse(
                    """{"MediaContainer":{"SearchResult":[{"guid":"plex://movie/a","name":"Found","year":2001,"score":"98","summary":"S"},{"guid":"plex://movie/b","name":"Other"}]}}""",
                )
                request.method == HttpMethod.Put -> {
                    gate.await()
                    respond("", HttpStatusCode.OK)
                }
                else -> jsonResponse("{}", 404)
            }
        })
        val deps = RecordingDeps(client)
        val store = PlexMatchStore(route, deps.deps, storeScope())
        advanceUntilIdle()
        val search = requests.single()
        assertEquals("1", search.url.parameters["manual"])
        assertEquals("Old Title", search.url.parameters["title"])
        assertEquals("2001", search.url.parameters["year"])
        val state = store.state.value
        assertEquals("Fix Match…", state.title)
        assertEquals(listOf("Found (2001)", "Other"), state.results!!.map { it.title })
        assertEquals("98", state.results!![0].score)

        store.setYear("20a019")
        assertEquals("2001", store.state.value.year)
        store.apply(0)
        store.apply(1)
        assertEquals("plex://movie/a", store.state.value.applyingGuid)
        gate.complete(Unit)
        advanceUntilIdle()
        val put = requests.single { it.method == HttpMethod.Put }
        assertEquals("/library/metadata/1/match", put.url.encodedPath)
        assertEquals("plex://movie/a", put.url.parameters["guid"])
        assertEquals("Found", put.url.parameters["name"])
        assertEquals("2001", put.url.parameters["year"])
        assertEquals(listOf("Match applied"), deps.notices)
        assertEquals(listOf<Route>(route), deps.closed)
    }

    @Test
    fun `a failed search says so and shows no matches`() = runTest {
        val deps = RecordingDeps(testPlexClient({ jsonResponse("{}", 500) }))
        val store = PlexMatchStore(route.copy(year = null, matched = false), deps.deps, storeScope())
        advanceUntilIdle()
        assertEquals("Match…", store.state.value.title)
        assertEquals(emptyList(), store.state.value.results)
        assertTrue(deps.notices.single().startsWith("Search failed"))
    }

    @Test
    fun `the search sends trimmed values and leaves empty ones out and a later failure keeps the results`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            if (requests.size == 1) jsonResponse("""{"MediaContainer":{"SearchResult":[{"guid":"plex://movie/a","name":"Found"}]}}""") else jsonResponse("{}", 500)
        })
        val deps = RecordingDeps(client)
        val store = PlexMatchStore(route.copy(title = "  Spaced Title  ", year = null), deps.deps, storeScope())
        advanceUntilIdle()
        assertEquals("Spaced Title", requests[0].url.parameters["title"])
        assertFalse("year" in requests[0].url.parameters.names())
        assertFalse("agent" in requests[0].url.parameters.names())
        assertFalse("language" in requests[0].url.parameters.names())
        store.setName(" ")
        store.search()
        advanceUntilIdle()
        assertFalse("title" in requests[1].url.parameters.names())
        assertEquals(listOf("Found"), store.state.value.results!!.map { it.title })
        assertTrue(deps.notices.single().startsWith("Search failed"))
    }

    @Test
    fun `a failed match says so and stays open`() = runTest {
        val client = testPlexClient({ request ->
            if (request.method == HttpMethod.Put) {
                respond("", HttpStatusCode.InternalServerError)
            } else {
                jsonResponse("""{"MediaContainer":{"SearchResult":[{"guid":"plex://movie/a","name":"Found"}]}}""")
            }
        })
        val deps = RecordingDeps(client)
        val store = PlexMatchStore(route, deps.deps, storeScope())
        advanceUntilIdle()
        store.apply(0)
        advanceUntilIdle()
        assertEquals(listOf("Failed to apply match"), deps.notices)
        assertTrue(deps.closed.isEmpty())
        assertNull(store.state.value.applyingGuid)
    }

    @Test
    fun `closing the match screen refreshes the item whatever came of it`() = runTest {
        val deps = RecordingDeps(testPlexClient({ jsonResponse("{}", 500) }))
        val store = PlexMatchStore(route, deps.deps, storeScope())
        advanceUntilIdle()
        store.close()
        assertEquals(listOf(ServerId("server-1") to "1"), deps.edited)
    }
}

class MetadataMenuEntriesTest {
    private val matched = plexRow().copy(guid = "plex://movie/abc")
    private val target = MenuTarget.Item(matched)
    private val place = MenuPlace()

    private fun TestScope.editing(server: FakePlexEditServer, deps: RecordingDeps, admin: Boolean = true, navigator: PlezyNavigator = PlezyNavigator(Route.Home)) =
        MetadataEditing(deps.deps, navigator, isOwnerOrAdmin = { admin }, activeProfile = { null }, scope = storeScope())

    @Test
    fun `an admin gets every edit of a matched plex movie in the metadata slot`() = runTest {
        val server = FakePlexEditServer()
        val entries = MetadataMenuEntries { editing(server, RecordingDeps(server.client)) }
        assertEquals(MenuSlot.METADATA, entries.slot)
        val offered = entries.entries(target, place)
        assertEquals(listOf("edit_metadata", "quick_tag", "match", "unmatch"), offered.map { it.id })
        assertEquals(listOf("unmatch"), offered.filter { it.destructive }.map { it.id })
        val guest = MetadataMenuEntries { editing(server, RecordingDeps(server.client), admin = false) }
        assertEquals(emptyList(), guest.entries(target, place))
        assertEquals(emptyList(), entries.entries(MenuTarget.Item(matched.copy(serverId = null)), place))
    }

    @Test
    fun `edit and match open their screens`() = runTest {
        val server = FakePlexEditServer()
        val navigator = PlezyNavigator(Route.Home)
        val metadata = editing(server, RecordingDeps(server.client), navigator = navigator)
        val entries = MetadataMenuEntries { metadata }
        assertNull(entries.perform(target, place, "edit_metadata"))
        assertTrue(Route.MetadataEdit(ServerId("server-1"), "1") in navigator.stacks.value)
        entries.perform(target, place, "match")
        assertTrue(Route.PlexMatch(ServerId("server-1"), "1", "Row Title", null, matched = true) in navigator.stacks.value)
    }

    @Test
    fun `quick tag shows over the app until it is done`() = runTest {
        val server = FakePlexEditServer()
        val metadata = editing(server, RecordingDeps(server.client))
        MetadataMenuEntries { metadata }.perform(target, place, "quick_tag")
        val store = assertNotNull(metadata.quickTag.value)
        advanceUntilIdle()
        assertNotNull(store.state.value.tags)
        store.cancel()
        assertTrue(store.state.value.done)
        assertTrue(server.puts.isEmpty())
        metadata.quickTagDone()
        assertNull(metadata.quickTag.value)
    }

    @Test
    fun `unmatch asks first and a dismissed prompt sends nothing`() = runTest {
        val server = FakePlexEditServer()
        val deps = RecordingDeps(server.client)
        val metadata = editing(server, deps)
        MetadataMenuEntries { metadata }.perform(target, place, "unmatch")
        assertEquals(matched, metadata.unmatchPrompt.value)
        metadata.dismissUnmatch()
        advanceUntilIdle()
        assertNull(metadata.unmatchPrompt.value)
        assertTrue(server.puts.isEmpty())

        metadata.unmatch(matched)
        advanceUntilIdle()
        assertEquals(listOf("/library/metadata/1/unmatch"), server.puts.map { it.url.encodedPath })
        assertEquals(listOf("Item unmatched"), deps.notices)
        assertEquals(listOf(ServerId("server-1") to "1"), deps.edited)
    }
}
