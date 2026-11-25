package com.edde746.plezy.metadata

import com.edde746.plezy.presentation.browse.isAdminActionAllowed
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.metadata.MetadataAction
import com.edde746.plezy.presentation.metadata.MetadataMenu
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.PlexHomeProfile
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

class MetadataEditModelsTest {
    private val item = MediaItem(id = "1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE)

    /** An adapter whose schema is [fields]; nothing it does reaches a server. */
    private class SchemaOnly(val fields: List<MetadataField>) : MetadataEditAdapter {
        override val client: MediaBackend get() = error("unused")
        override suspend fun load(item: MediaItem) = error("unused")
        override fun schema(draft: MetadataDraft) = listOf(MetadataSection("s", "S", fields))
        override suspend fun save(draft: MetadataDraft) = error("unused")
        override suspend fun artwork(draft: MetadataDraft, field: MetadataField) = error("unused")
        override suspend fun applyArtworkFromUrl(draft: MetadataDraft, field: MetadataField, url: String) = error("unused")
        override suspend fun uploadArtwork(draft: MetadataDraft, field: MetadataField, bytes: ByteArray, fileName: String?) = error("unused")
        override fun withReloadedArtwork(draft: MetadataDraft, item: MediaItem) = draft
    }

    @Test
    fun `adapter dirty tracking ignores immediate fields`() {
        val choice = MetadataField("pref:a", "A", MetadataFieldType.CHOICE, MetadataSaveMode.IMMEDIATE)
        val artwork = MetadataField("artwork:posters", "Poster", MetadataFieldType.ARTWORK, MetadataSaveMode.IMMEDIATE)
        val title = MetadataField("title", "Title", MetadataFieldType.TEXT)
        val adapter = SchemaOnly(listOf(choice, artwork, title))
        val draft = MetadataDraft(item, item, mapOf("pref:a" to "1", "artwork:posters" to "/a", "title" to "T"))
        assertFalse(adapter.hasChanges(draft.with("pref:a", "0").with("artwork:posters", "/b")))
        assertTrue(adapter.hasChanges(draft.with("title", "U")))
    }

    @Test
    fun `adapter dirty tracking compares string lists as sets`() {
        val adapter = SchemaOnly(listOf(tagField("genre", "Genre")))
        val draft = MetadataDraft(item, item, mapOf("genre" to listOf("Drama", "War")))
        assertFalse(adapter.hasChanges(draft.with("genre", listOf("War", " Drama ", "Drama", ""))))
        assertTrue(adapter.hasChanges(draft.with("genre", listOf("War"))))
    }

    @Test
    fun `added tags are what each tag field gained`() {
        val fields = listOf(tagField("genre", "Genre"), tagField("label", "Label"), MetadataField("title", "Title", MetadataFieldType.TEXT))
        val draft = MetadataDraft(item, item, mapOf("genre" to listOf("Drama"), "label" to listOf("a"), "title" to "T"))
            .with("genre", listOf("Drama", "War")).with("label", emptyList<String>()).with("title", "U")
        assertEquals(mapOf("genre" to listOf("War")), draft.addedTags(fields))
    }

    @Test
    fun `dates are zero padded and parsed from their day`() {
        assertEquals("0999-01-02", metadataDate(999, 1, 2))
        assertEquals(Triple(2001, 2, 3), parseMetadataDate("2001-02-03T00:00:00Z"))
        assertNull(parseMetadataDate(""))
        assertNull(parseMetadataDate("2001-13-01"))
    }

    @Test
    fun `basic fields follow the kind in order`() {
        assertEquals(listOf("title", "summary"), metadataBasicFields(MediaKind.SEASON).map { it.id })
        assertEquals(
            listOf("title", "titleSort", "originallyAvailableAt", "contentRating", "summary"),
            metadataBasicFields(MediaKind.EPISODE).map { it.id },
        )
    }

    @Test
    fun `a show has the movies basic fields with its release date a date and studio typed by the backend`() {
        val show = metadataBasicFields(MediaKind.SHOW)
        assertEquals(
            listOf("title", "titleSort", "originalTitle", "originallyAvailableAt", "contentRating", "studio", "tagline", "summary"),
            show.map { it.id },
        )
        assertEquals(listOf("Sort Title", "Release Date"), show.filter { it.id == "titleSort" || it.id == "originallyAvailableAt" }.map { it.label })
        assertEquals(MetadataFieldType.DATE, show.first { it.id == "originallyAvailableAt" }.type)
        assertEquals(MetadataFieldType.MULTILINE_TEXT, show.last().type)
        assertEquals(MetadataFieldType.TEXT, show.first { it.id == "studio" }.type)
        val mediaBrowser = metadataBasicFields(MediaKind.SHOW, studioType = MetadataFieldType.STRING_LIST)
        assertEquals(MetadataFieldType.STRING_LIST, mediaBrowser.first { it.id == "studio" }.type)
    }
}

class MetadataMenuTest {
    private val data = testData()

    @AfterTest
    fun closeData() = data.close()

    private val plexMovie = MediaItem(id = "1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, guid = "plex://movie/abc", serverId = "server-1")
    private fun home(admin: Boolean) = PlexHomeProfile(id = "h", displayName = "Kid", parentConnectionId = "plex.a", plexHomeUserUuid = "u", plexAdmin = admin)

    @Test
    fun `blocks non admin Plex Home users on Plex items`() {
        assertFalse(isAdminActionAllowed(true, BackendKind.PLEX, home(admin = false)))
    }

    @Test
    fun `does not apply Plex Home role to Jellyfin items`() {
        assertTrue(isAdminActionAllowed(true, BackendKind.JELLYFIN, home(admin = false)))
        assertFalse(isAdminActionAllowed(false, BackendKind.JELLYFIN, null))
    }

    @Test
    fun `allows Plex admin Home users on Plex items`() {
        assertTrue(isAdminActionAllowed(true, BackendKind.PLEX, home(admin = true)))
        assertTrue(isAdminActionAllowed(true, BackendKind.PLEX, LocalProfile(id = "l", displayName = "Me", createdAt = 0)))
    }

    @Test
    fun `allows Jellyfin video metadata edit through capability gate`() = runTest {
        val client = mbClient(mbServer(), data)
        assertTrue(MetadataEditAdapter.supports(client, MediaKind.MOVIE))
        assertTrue(MetadataEditAdapter.supports(client, MediaKind.SHOW))
        assertFalse(MetadataEditAdapter.supports(client, MediaKind.TRACK))
        assertFalse(MetadataEditAdapter.supports(null, MediaKind.MOVIE))
        val movie = mbItem()
        assertEquals(listOf(MetadataAction.EDIT, MetadataAction.QUICK_TAG), MetadataMenu.entries(movie, client, admin = true).map { it.action })
        assertEquals(listOf(MetadataAction.EDIT), MetadataMenu.entries(mbItem(MediaKind.EPISODE), client, admin = true).map { it.action })
    }

    @Test
    fun `hides Quick Tag for a non admin`() = runTest {
        assertEquals(emptyList(), MetadataMenu.entries(mbItem(), mbClient(mbServer(), data), admin = false))
    }

    @Test
    fun `a matched Plex movie offers Fix Match and Unmatch`() {
        val client = FakePlexEditServer().client
        val entries = MetadataMenu.entries(plexMovie, client, admin = true)
        assertEquals(listOf(MetadataAction.EDIT, MetadataAction.QUICK_TAG, MetadataAction.MATCH, MetadataAction.UNMATCH), entries.map { it.action })
        assertEquals(listOf("Edit…", "Quick Tag…", "Fix Match…", "Unmatch"), entries.map { it.label })
    }

    @Test
    fun `an unmatched Plex item offers Match without Unmatch`() {
        val client = FakePlexEditServer().client
        for (guid in listOf(null, "", "com.plexapp.agents.none://1", "tv.plex.agents.none://2")) {
            val entries = MetadataMenu.entries(plexMovie.copy(guid = guid), client, admin = true)
            assertEquals(listOf("Edit…", "Quick Tag…", "Match…"), entries.map { it.label })
        }
        assertEquals(listOf(MetadataAction.EDIT), MetadataMenu.entries(plexMovie.copy(kind = MediaKind.SEASON), client, admin = true).map { it.action })
        assertEquals(emptyList(), MetadataMenu.entries(plexMovie.copy(kind = MediaKind.TRACK), client, admin = true))
    }
}
