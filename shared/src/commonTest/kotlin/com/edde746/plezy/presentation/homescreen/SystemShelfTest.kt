package com.edde746.plezy.presentation.homescreen

import com.edde746.plezy.app.FakeHomeScreen
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.strings.InterfaceLocale
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The home screen shelf: one owner at a time with a generation that grows with each change of owner, a clear when the
 * owner's session ends or when a session may not publish, the item mapping (content id, show and episode titles, times),
 * each home screen's artwork, the row limit and items whose server is gone.
 */
class SystemShelfTest {
    private class ShelfClient(private val throwOnThumbnail: Boolean = false) : FakeMediaBackend("server-a") {
        val thumbnailRequests = mutableListOf<Triple<String?, Int?, Int?>>()

        override fun thumbnailUrl(path: String?, width: Int?, height: Int?, cover: Boolean): String {
            if (throwOnThumbnail) throw IllegalStateException("conversion failed")
            thumbnailRequests += Triple(path, width, height)
            return "https://media.invalid$path?token=transient"
        }
    }

    @BeforeTest
    fun english() = InterfaceLocale.setSystemLanguages(listOf("en"))

    private fun shelf(home: FakeHomeScreen?) = SystemShelf(home) { NOW }

    private fun SystemShelf.sync(profileId: String, items: List<MediaItem>, client: ShelfClient, hideSpoilers: Boolean = false, mode: EpisodePosterMode = EpisodePosterMode.SERIES_POSTER) =
        sync(profileId, items, { if (it == client.serverId) client else null }, hideSpoilers, mode)

    @Test
    fun aSyncForAnOwnerWhoseSessionEndedPublishesNothingAndTheEndClears() {
        val home = FakeHomeScreen()
        val shelf = shelf(home)
        shelf.beginProfileSession("owner-a", mayPublish = true)
        shelf.endProfileSession("owner-a")

        assertFalse(shelf.sync("owner-a", emptyList(), ShelfClient()))
        assertEquals(listOf(HomeScreenShelf(null, 2, "Continue Watching", emptyList())), home.published)
    }

    @Test
    fun eachOwnerPublishesUnderItsOwnLaterGeneration() {
        val home = FakeHomeScreen()
        val shelf = shelf(home)
        shelf.beginProfileSession("owner-a", mayPublish = true)
        assertTrue(shelf.sync("owner-a", emptyList(), ShelfClient()))
        shelf.endProfileSession("owner-a")
        shelf.beginProfileSession("owner-b", mayPublish = true)
        assertFalse(shelf.sync("owner-a", emptyList(), ShelfClient()))
        assertTrue(shelf.sync("owner-b", emptyList(), ShelfClient()))

        assertEquals(listOf("owner-a" to 1L, null to 2L, "owner-b" to 3L), home.published.map { it.ownerId to it.generation })
        // Beginning the session it already has changes nothing; ending another's leaves the shelf alone.
        shelf.beginProfileSession("owner-b", mayPublish = true)
        shelf.endProfileSession("owner-a")
        assertEquals("owner-b", shelf.sessionProfile)
        assertEquals(3, home.published.size)
        assertFailsWith<IllegalArgumentException> { shelf.beginProfileSession("", mayPublish = true) }
    }

    @Test
    fun aSessionThatMayNotPublishClearsTheShelfPublishesOnceAllowedAndEndsWithoutAnotherClear() {
        val home = FakeHomeScreen()
        val shelf = shelf(home)
        // The clear also removes what an earlier launch left on the home screen.
        shelf.beginProfileSession("protected", mayPublish = false)
        assertFalse(shelf.sync("protected", emptyList(), ShelfClient()))
        shelf.beginProfileSession("protected", mayPublish = false)

        shelf.beginProfileSession("protected", mayPublish = true)
        assertTrue(shelf.sync("protected", emptyList(), ShelfClient()))

        shelf.beginProfileSession("protected", mayPublish = false)
        assertFalse(shelf.sync("protected", emptyList(), ShelfClient()))
        assertEquals("protected", shelf.sessionProfile)

        shelf.endProfileSession("protected")
        assertNull(shelf.sessionProfile)
        assertEquals(listOf(null to 1L, "protected" to 2L, null to 3L), home.published.map { it.ownerId to it.generation })
    }

    @Test
    fun withoutAHomeScreenNothingIsPublished() {
        val shelf = shelf(null)
        shelf.beginProfileSession("owner-a", mayPublish = true)
        assertFalse(shelf.sync("owner-a", listOf(movie()), ShelfClient()))
        shelf.endProfileSession("owner-a")
    }

    @Test
    fun anItemCarriesItsContentIdTimesAndPosterSourceAndAFailedPosterKeepsTheRest() {
        val home = FakeHomeScreen()
        val shelf = shelf(home)
        shelf.beginProfileSession("owner-a", mayPublish = true)
        val client = ShelfClient()
        assertTrue(shelf.sync("owner-a", listOf(movie()), client))

        val item = home.published.single().items.single()
        assertEquals("plezy_server-a_item-a", item.contentId)
        assertEquals("plezy://play?content_id=plezy_server-a_item-a", item.playUrl)
        assertEquals("Private title", item.title)
        assertNull(item.episodeTitle)
        assertEquals("Private summary", item.description)
        assertEquals(7_200_000, item.durationMillis)
        assertEquals(60_000, item.positionMillis)
        assertEquals(NOW, item.lastEngagedMillis)
        assertEquals("https://media.invalid/poster?token=transient", item.posterSource)
        assertEquals(Triple("/poster", 640, 360), client.thumbnailRequests.single())

        assertTrue(shelf.sync("owner-a", listOf(movie().copy(lastViewedAt = 1_700_000_000)), ShelfClient(throwOnThumbnail = true)))
        val fallback = home.published.last().items.single()
        assertEquals("Private title", fallback.title)
        assertNull(fallback.posterSource)
        assertEquals(1_700_000_000_000, fallback.lastEngagedMillis)
    }

    @Test
    fun anEpisodeIsTitledByItsShowWithItsOwnTitleBeside() {
        val home = FakeHomeScreen()
        val shelf = shelf(home)
        shelf.beginProfileSession("owner-a", mayPublish = true)
        shelf.sync("owner-a", listOf(episode(grandparentThumbPath = "/series-poster")), ShelfClient())
        val item = home.published.single().items.single()
        assertEquals("Show", item.title)
        assertEquals("Finale", item.episodeTitle)
        assertEquals("Show", item.seriesTitle)
        assertEquals(2, item.seasonNumber)
        assertEquals(5, item.episodeNumber)
        assertTrue(item.isEpisode)
    }

    @Test
    fun theTopShelfWalksItsPosterChainAt600x900AndSkipsTheSpoilerOverride() {
        for ((mode, posters) in listOf(
            EpisodePosterMode.SEASON_POSTER to listOf("/season-poster", "/series-poster", "/episode-still"),
            // Every other setting gets the series poster: an episode still can't fill a 2:3 slot.
            EpisodePosterMode.SERIES_POSTER to listOf("/series-poster", "/series-poster", "/episode-still"),
            EpisodePosterMode.EPISODE_THUMBNAIL to listOf("/series-poster", "/series-poster", "/episode-still"),
        )) {
            val shelf = shelf(FakeHomeScreen(HomeScreenArtwork.POSTER))
            shelf.beginProfileSession("owner-a", mayPublish = true)
            val client = ShelfClient()
            val episodes = listOf(
                episode(parentThumbPath = "/season-poster", grandparentThumbPath = "/series-poster"),
                episode(grandparentThumbPath = "/series-poster"),
                episode(),
            )
            assertTrue(shelf.sync("owner-a", episodes, client, hideSpoilers = true, mode = mode))
            assertEquals(posters, client.thumbnailRequests.map { it.first }, "$mode")
            assertTrue(client.thumbnailRequests.all { it.second == 600 && it.third == 900 })
        }
    }

    @Test
    fun watchNextKeeps640x360EpisodeThumbnailsAndTheSpoilerSafeOverride() {
        val shelf = shelf(FakeHomeScreen(HomeScreenArtwork.LANDSCAPE))
        shelf.beginProfileSession("owner-a", mayPublish = true)
        val client = ShelfClient()
        val episode = episode(parentThumbPath = "/season-poster", grandparentThumbPath = "/series-poster")

        assertTrue(shelf.sync("owner-a", listOf(episode), client, hideSpoilers = true))
        assertTrue(shelf.sync("owner-a", listOf(episode), client))
        assertEquals(listOf("/spoiler-safe-art", "/episode-still"), client.thumbnailRequests.map { it.first })
        assertTrue(client.thumbnailRequests.all { it.second == 640 && it.third == 360 })
    }

    @Test
    fun publishesAtMostOneRowOfItemsWhoseServerHasAClient() {
        val home = FakeHomeScreen()
        val shelf = shelf(home)
        shelf.beginProfileSession("owner-a", mayPublish = true)
        val items = (1..25).map { movie().copy(id = "m$it") }.toMutableList()
        items.add(0, movie().copy(id = "gone", serverId = "server-b"))
        items.add(1, movie().copy(id = "unknown", serverId = null))
        shelf.sync("owner-a", items, ShelfClient())
        val published = home.published.single().items
        assertEquals(HOME_SCREEN_LIMIT, published.size)
        assertEquals((1..20).map { "plezy_server-a_m$it" }, published.map { it.contentId })
    }

    private fun movie() = MediaItem(
        id = "item-a",
        backend = BackendKind.PLEX,
        kind = MediaKind.MOVIE,
        title = "Private title",
        summary = "Private summary",
        thumbPath = "/poster",
        durationMs = 7_200_000,
        viewOffsetMs = 60_000,
        serverId = "server-a",
        serverName = "Server",
    )

    private fun episode(parentThumbPath: String? = null, grandparentThumbPath: String? = null) = MediaItem(
        id = "ep-1",
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        title = "Finale",
        grandparentTitle = "Show",
        parentIndex = 2,
        index = 5,
        parentThumbPath = parentThumbPath,
        grandparentThumbPath = grandparentThumbPath,
        grandparentArtPath = "/spoiler-safe-art",
        thumbPath = "/episode-still",
        serverId = "server-a",
        serverName = "Server",
    )

    private companion object {
        const val NOW = 1_234_567L
    }
}
