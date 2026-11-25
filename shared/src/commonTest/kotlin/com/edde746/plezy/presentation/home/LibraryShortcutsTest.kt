package com.edde746.plezy.presentation.home

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.profiles.ProfileBindState
import com.edde746.plezy.servers.LibrariesLoadState
import com.edde746.plezy.servers.LibrariesState
import com.edde746.plezy.servers.MultiServerState
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class LibraryShortcutsTest {
    private fun library(id: String, title: String, server: String, backend: BackendKind = BackendKind.JELLYFIN, kind: MediaKind = MediaKind.MOVIE) =
        MediaLibrary(id = id, backend = backend, title = title, kind = kind, serverId = server, serverName = "Server $server")

    @Test
    fun theVisibleLibrariesInTheirOrderWithTheirKinds() {
        val libraries = listOf(
            library("b", "Shows", "plex_1", BackendKind.PLEX, MediaKind.SHOW),
            library("a", "Movies", "jf_1"),
            library("c", "Music", "emby_1", BackendKind.EMBY, MediaKind.ARTIST),
        )
        val shortcuts = libraryShortcuts(libraries, hiddenKeys = setOf(libraries[1].globalKey))
        assertEquals(listOf("Shows", "Music"), shortcuts.map { it.title })
        assertEquals(listOf(MediaKind.SHOW, MediaKind.ARTIST), shortcuts.map { it.kind })
        assertEquals(listOf(libraries[0].globalKey, libraries[2].globalKey), shortcuts.map { it.globalKey })
    }

    @Test
    fun aServersNameOnlyWhereAnotherServerHasALibraryOfTheSameName() {
        val libraries = listOf(
            library("1", "Movies", "jf_1"),
            library("2", "movies", "plex_1", BackendKind.PLEX),
            library("3", "Shows", "jf_1"),
            library("4", "Shows", "jf_1"),
            library("5", "Music", "jf_1"),
        )
        assertEquals(
            listOf("Server jf_1", "Server plex_1", null, null, null),
            libraryShortcuts(libraries, emptySet()).map { it.serverName },
        )
    }

    @Test
    fun aHiddenNamesakeNamesNoServer() {
        val libraries = listOf(library("1", "Movies", "jf_1"), library("2", "Movies", "plex_1", BackendKind.PLEX))
        assertEquals(listOf(null), libraryShortcuts(libraries, setOf(libraries[1].globalKey)).map { it.serverName })
    }

    @Test
    fun theChipRowWaitsForEveryOnlineServersLibrariesAndTheBind() {
        val first = ServerId("jf_1")
        val second = ServerId("emby_1")
        val bound = ProfileBindState(binding = false, bound = true)
        val bothOnline = MultiServerState(onlineServerIds = listOf(first, second))
        val firstAnswered = LibrariesState(loadState = LibrariesLoadState.LOADED, answeredServerIds = setOf(first))

        // The first server's libraries are in, the second's namesake would still rename a chip.
        assertFalse(shortcutsSettled(firstAnswered, bothOnline, bound))
        // The second server is still connecting: the bind runs.
        assertFalse(shortcutsSettled(firstAnswered, MultiServerState(onlineServerIds = listOf(first)), ProfileBindState(binding = true, bound = true)))
        assertFalse(shortcutsSettled(firstAnswered, MultiServerState(onlineServerIds = listOf(first)), ProfileBindState()))
        // Answered, with libraries or failing.
        assertTrue(shortcutsSettled(firstAnswered.copy(answeredServerIds = setOf(first, second)), bothOnline, bound))
        // Live TV not yet asked of every server.
        assertFalse(shortcutsSettled(firstAnswered.copy(answeredServerIds = setOf(first, second)), bothOnline.copy(liveTvChecked = false), bound))
        // A failed first load shows what the row has.
        assertTrue(shortcutsSettled(LibrariesState(loadState = LibrariesLoadState.ERROR), bothOnline, bound))
        assertFalse(shortcutsSettled(LibrariesState(loadState = LibrariesLoadState.LOADING), bothOnline, bound))
    }
}
