package com.edde746.plezy.presentation.homescreen

import com.edde746.plezy.app.ContinueWatchingShelf
import com.edde746.plezy.app.FakeHomeScreen
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.InterfaceLocale
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

/** The home screen shelf kept on the active profile's Continue Watching: owners follow the profile, settings republish. */
class HomeScreenSyncTest {
    private val client = object : FakeMediaBackend("server-a") {
        override fun thumbnailUrl(path: String?, width: Int?, height: Int?, cover: Boolean): String = "https://media.invalid$path"
    }

    @BeforeTest
    fun english() = InterfaceLocale.setSystemLanguages(listOf("en"))

    @Test
    fun `a profile switch clears the old shelf before the new owner publishes and the poster setting republishes`() = runTest {
        val home = FakeHomeScreen(HomeScreenArtwork.POSTER)
        val data = LocalData(inMemoryDatabase(), { 0L }, StandardTestDispatcher(testScheduler))
        val active = MutableStateFlow<Profile?>(profile("a"))
        val continueWatching = MutableStateFlow<ContinueWatchingShelf?>(null)
        HomeScreenSync(SystemShelf(home) { 0L }, active, MutableStateFlow(listOf(profile("a"), profile("b"))), continueWatching, { if (it == client.serverId) client else null }, data.deviceSettings, backgroundScope).start()
        runCurrent()

        continueWatching.value = ContinueWatchingShelf("a", listOf(episode("e1"), episode("gone", serverId = "server-b")))
        runCurrent()
        assertEquals(listOf("a" to listOf("plezy_server-a_e1")), home.published.map { it.ownerId to it.items.map { item -> item.contentId } })
        assertEquals("https://media.invalid/series", home.published.last().items.single().posterSource)

        data.deviceSettings.set(AppSettings.episodePosterMode, EpisodePosterMode.SEASON_POSTER)
        runCurrent()
        assertEquals("https://media.invalid/season", home.published.last().items.single().posterSource)

        active.value = profile("b")
        runCurrent()
        val cleared = home.published.last()
        assertNull(cleared.ownerId)
        assertTrue(cleared.items.isEmpty())
        continueWatching.value = ContinueWatchingShelf("a", listOf(episode("late")))
        runCurrent()
        assertSame(cleared, home.published.last(), "a list read for the old profile is dropped")

        continueWatching.value = ContinueWatchingShelf("b", listOf(episode("e2")))
        runCurrent()
        assertEquals("b", home.published.last().ownerId)
        assertTrue(home.published.last().generation > cleared.generation)

        active.value = null
        runCurrent()
        assertNull(home.published.last().ownerId, "signing out clears the shelf")
        data.close()
    }

    @Test
    fun `a PIN protected profile stays off the shelf while the app asks for a profile on open and publishes once allowed`() = runTest {
        val home = FakeHomeScreen(HomeScreenArtwork.POSTER)
        val data = LocalData(inMemoryDatabase(), { 0L }, StandardTestDispatcher(testScheduler))
        data.deviceSettings.set(AppSettings.requireProfileSelectionOnOpen, true)
        val owner = profile("owner", pinHash = "hash")
        val kids = profile("kids")
        val active = MutableStateFlow<Profile?>(owner)
        val profiles = MutableStateFlow(listOf(owner, kids))
        val continueWatching = MutableStateFlow<ContinueWatchingShelf?>(ContinueWatchingShelf("owner", listOf(episode("e1"))))
        HomeScreenSync(SystemShelf(home) { 0L }, active, profiles, continueWatching, { if (it == client.serverId) client else null }, data.deviceSettings, backgroundScope).start()
        runCurrent()
        assertEquals(listOf<String?>(null), home.published.map { it.ownerId }, "the session start clears what an earlier launch left")

        data.deviceSettings.set(AppSettings.requireProfileSelectionOnOpen, false)
        runCurrent()
        assertEquals("owner", home.published.last().ownerId, "allowed again it publishes the list Home has")
        assertEquals(listOf("plezy_server-a_e1"), home.published.last().items.map { it.contentId })

        data.deviceSettings.set(AppSettings.requireProfileSelectionOnOpen, true)
        runCurrent()
        assertNull(home.published.last().ownerId)
        continueWatching.value = ContinueWatchingShelf("owner", listOf(episode("e2")))
        runCurrent()
        assertNull(home.published.last().ownerId, "a new list stays off the shelf")

        profiles.value = listOf(owner)
        runCurrent()
        assertEquals("owner", home.published.last().ownerId, "with one profile the app opens without asking")
        profiles.value = listOf(owner, kids)
        runCurrent()
        assertNull(home.published.last().ownerId)

        val unlocked = profile("owner")
        active.value = unlocked
        profiles.value = listOf(unlocked, kids)
        runCurrent()
        assertEquals("owner", home.published.last().ownerId, "removing the PIN allows it")

        active.value = kids
        continueWatching.value = ContinueWatchingShelf("kids", listOf(episode("e3")))
        runCurrent()
        assertEquals("kids", home.published.last().ownerId, "a profile without a PIN publishes")
        data.close()
    }

    private fun profile(id: String, pinHash: String? = null) = LocalProfile(id = id, displayName = id, pinHash = pinHash, createdAt = 0)

    private fun episode(id: String, serverId: String = "server-a") = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        title = "Finale",
        grandparentTitle = "Show",
        parentIndex = 2,
        index = 5,
        parentThumbPath = "/season",
        grandparentThumbPath = "/series",
        thumbPath = "/still",
        serverId = serverId,
    )
}
