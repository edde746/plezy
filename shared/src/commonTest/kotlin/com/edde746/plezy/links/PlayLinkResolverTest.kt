package com.edde746.plezy.links

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.ItemWithOnDeck
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LibraryLookupResult
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes

/**
 * How a play link resolves: by item kind, with a download while its server is away, waiting for the server, and for a
 * catalogue title across copies on several servers and backends.
 */
class PlayLinkResolverTest {
    private class Client(serverId: String, backend: BackendKind = BackendKind.PLEX) : FakeMediaBackend(serverId, backend) {
        val itemsById = mutableMapOf<String, MediaItem>()
        val onDeck = mutableMapOf<String, MediaItem>()
        val descendants = mutableMapOf<String, List<MediaItem>>()
        var fetchError: Throwable? = null

        init {
            items = { id -> fetchError?.let { throw it }; itemsById[id] }
            playableDescendants = { descendants[it].orEmpty() }
        }

        override suspend fun fetchItemWithOnDeck(id: String, onItemReady: ((MediaItem) -> Unit)?): ItemWithOnDeck =
            ItemWithOnDeck(itemsById[id], onDeck[id])
    }

    private class Servers {
        val clients = mutableMapOf<ServerId, Client>()
        val online = MutableStateFlow(setOf<ServerId>())
        var catalog = lookup(emptyList())
        val downloads = mutableMapOf<String, MediaItem>()
        val catalogQueries = mutableListOf<PlayTarget.Catalog>()
        var plexHash: (suspend (PlayTarget.Catalog) -> String?)? = null

        fun add(client: Client, online: Boolean = true) {
            clients[client.serverId] = client
            if (online) this.online.value += client.serverId
        }

        fun resolver(serverWait: Duration = 1.minutes) = PlayLinkResolver(
            PlayLinkSources(
                clientFor = { clients[it] },
                isServerOnline = { it in online.value },
                hasOnlineServers = { online.value.isNotEmpty() },
                serversChanged = online,
                findCatalogCopies = { catalogQueries += it; catalog },
                downloadedItem = { serverId, itemId -> downloads["$serverId:$itemId"] },
                resolvePlexHash = plexHash,
            ),
            serverWait,
        )
    }

    private val servers = Servers()

    private fun itemLink(server: String, id: String, mode: PlayMode = PlayMode.NEXT) = DeepLink.Play(PlayTarget.Item(ServerId(server), id), mode)

    private val movieLink = DeepLink.Play(PlayTarget.Catalog(MediaKind.MOVIE, ExternalIds(tmdb = 603)))
    private val showLink = DeepLink.Play(PlayTarget.Catalog(MediaKind.SHOW, ExternalIds(tvdb = 81189)))

    /** [resolution] plays [id]; [showPlay] as its show's Play, not as an episode on its own. */
    private fun assertPlays(id: String, resolution: PlayLinkResolution, offline: Boolean = false, showPlay: Boolean = false) {
        val item = assertIs<PlayLinkResolution.Item>(resolution, "$resolution")
        assertEquals(id, item.item.id)
        assertEquals(offline, item.offline)
        assertEquals(showPlay, item.showPlay)
    }

    private fun assertFails(reason: PlayLinkFailure, resolution: PlayLinkResolution) =
        assertEquals(PlayLinkResolution.Failure(reason), resolution)

    @Test
    fun playsAMovieOrAnEpisodeAsItIs() = runTest {
        servers.add(Client("s1").apply { itemsById["m1"] = item("m1", MediaKind.MOVIE, "s1") })
        assertPlays("m1", servers.resolver().resolve(itemLink("s1", "m1")))
    }

    @Test
    fun playsTheOnDeckEpisodeOfAShowElseItsFirstRegularEpisode() = runTest {
        val client = Client("s1", BackendKind.JELLYFIN).apply {
            itemsById["show"] = item("show", MediaKind.SHOW, "s1")
            descendants["show"] = listOf(
                item("special", MediaKind.EPISODE, "s1", season = 0, episode = 1),
                item("s2e1", MediaKind.EPISODE, "s1", season = 2, episode = 1),
                item("s1e1", MediaKind.EPISODE, "s1", season = 1, episode = 1),
            )
        }
        servers.add(client)
        assertPlays("s1e1", servers.resolver().resolve(itemLink("s1", "show")), showPlay = true)

        client.onDeck["show"] = item("s2e1", MediaKind.EPISODE, "s1", season = 2, episode = 1)
        assertPlays("s2e1", servers.resolver().resolve(itemLink("s1", "show")), showPlay = true)
    }

    @Test
    fun playsTheFirstUnwatchedEpisodeOfASeason() = runTest {
        servers.add(
            Client("s1").apply {
                itemsById["season"] = item("season", MediaKind.SEASON, "s1")
                descendants["season"] = listOf(
                    item("e2", MediaKind.EPISODE, "s1", season = 1, episode = 2),
                    item("e1", MediaKind.EPISODE, "s1", season = 1, episode = 1, viewCount = 1),
                )
            },
        )
        assertPlays("e2", servers.resolver().resolve(itemLink("s1", "season")))
    }

    @Test
    fun shufflesAShow() = runTest {
        servers.add(Client("s1").apply { itemsById["show"] = item("show", MediaKind.SHOW, "s1") })
        val resolution = servers.resolver().resolve(itemLink("s1", "show", PlayMode.SHUFFLE))
        assertEquals("show", assertIs<PlayLinkResolution.Shuffle>(resolution).item.id)
    }

    @Test
    fun refusesWhatALinkCannotPlay() = runTest {
        servers.add(Client("s1").apply { itemsById["t1"] = item("t1", MediaKind.TRACK, "s1") })
        assertFails(PlayLinkFailure.UNSUPPORTED_ITEM, servers.resolver().resolve(itemLink("s1", "t1")))
        assertFails(PlayLinkFailure.NOT_FOUND, servers.resolver().resolve(itemLink("s1", "gone")))
    }

    @Test
    fun aMovieEpisodeOrClipIgnoresTheModeAndASeasonShuffles() = runTest {
        servers.add(
            Client("s1").apply {
                itemsById["m1"] = item("m1", MediaKind.MOVIE, "s1")
                itemsById["e1"] = item("e1", MediaKind.EPISODE, "s1")
                itemsById["c1"] = item("c1", MediaKind.CLIP, "s1")
                itemsById["season"] = item("season", MediaKind.SEASON, "s1")
            },
        )
        for (id in listOf("m1", "e1", "c1")) assertPlays(id, servers.resolver().resolve(itemLink("s1", id, PlayMode.SHUFFLE)))
        val resolution = servers.resolver().resolve(itemLink("s1", "season", PlayMode.SHUFFLE))
        assertEquals("season", assertIs<PlayLinkResolution.Shuffle>(resolution).item.id)
    }

    @Test
    fun aWatchedSeasonStartsAtItsFirstEpisodeAndCollectionsOrPhotosAreRefused() = runTest {
        servers.add(
            Client("s1").apply {
                itemsById["season"] = item("season", MediaKind.SEASON, "s1")
                descendants["season"] = listOf(
                    item("e2", MediaKind.EPISODE, "s1", season = 1, episode = 2, viewCount = 1),
                    item("e1", MediaKind.EPISODE, "s1", season = 1, episode = 1, viewCount = 1),
                )
                itemsById["col"] = item("col", MediaKind.COLLECTION, "s1")
                itemsById["pic"] = item("pic", MediaKind.PHOTO, "s1")
            },
        )
        assertPlays("e1", servers.resolver().resolve(itemLink("s1", "season")))
        assertFails(PlayLinkFailure.UNSUPPORTED_ITEM, servers.resolver().resolve(itemLink("s1", "col")))
        assertFails(PlayLinkFailure.UNSUPPORTED_ITEM, servers.resolver().resolve(itemLink("s1", "pic")))
    }

    @Test
    fun stampsTheLinksServerOnAnItemWithoutOne() = runTest {
        servers.add(Client("s1").apply { itemsById["m1"] = item("m1", MediaKind.MOVIE, null) })
        val resolution = assertIs<PlayLinkResolution.Item>(servers.resolver().resolve(itemLink("s1", "m1")))
        assertEquals("s1", resolution.item.serverId)
    }

    @Test
    fun playsTheDownloadAtOnceWhileItsServerIsAway() = runTest {
        servers.add(Client("s1"), online = false)
        servers.downloads["s1:m1"] = item("m1", MediaKind.MOVIE, "s1")
        assertPlays("m1", servers.resolver().resolve(itemLink("s1", "m1")), offline = true)
    }

    @Test
    fun fallsBackToTheDownloadWhenItsServerFailsToAnswer() = runTest {
        servers.add(Client("s1").apply { fetchError = IllegalStateException("timeout") })
        assertFails(PlayLinkFailure.SERVER_UNAVAILABLE, servers.resolver().resolve(itemLink("s1", "m1")))
        servers.downloads["s1:m1"] = item("m1", MediaKind.MOVIE, "s1")
        assertPlays("m1", servers.resolver().resolve(itemLink("s1", "m1")), offline = true)
    }

    @Test
    fun waitsForItsServerToComeOnline() = runTest {
        servers.add(Client("s1").apply { itemsById["m1"] = item("m1", MediaKind.MOVIE, "s1") }, online = false)
        val resolution = async { servers.resolver().resolve(itemLink("s1", "m1")) }
        runCurrent()
        assertTrue(resolution.isActive)
        servers.online.value += ServerId("s1")
        assertPlays("m1", resolution.await())
    }

    @Test
    fun givesUpOnAServerThatStaysAway() = runTest {
        servers.add(Client("s1"), online = false)
        assertFails(PlayLinkFailure.SERVER_UNAVAILABLE, servers.resolver(serverWait = Duration.ZERO).resolve(itemLink("s1", "m1")))
        // Twenty seconds by default, then it gives up.
        val waited = async { servers.resolver().resolve(itemLink("s1", "m1")) }
        assertFails(PlayLinkFailure.SERVER_UNAVAILABLE, waited.await())
    }

    @Test
    fun resumesTheCopyOfAMovieWatchedLastAcrossServersAndBackends() = runTest {
        servers.add(Client("plex").apply { itemsById["p"] = item("p", MediaKind.MOVIE, "plex", lastViewedAt = 100) })
        servers.add(Client("jelly", BackendKind.JELLYFIN).apply { itemsById["j"] = item("j", MediaKind.MOVIE, "jelly", lastViewedAt = 200) })
        // The lookup rows carry stale watch state; the refreshed items decide.
        servers.catalog = lookup(listOf(item("p", MediaKind.MOVIE, "plex"), item("j", MediaKind.MOVIE, "jelly")))
        assertPlays("j", servers.resolver().resolve(movieLink))
        assertEquals(603, servers.catalogQueries.single().ids.tmdb)
    }

    @Test
    fun playsTheBestCopyOfAMovieNobodyWatched() = runTest {
        servers.add(Client("a"))
        servers.add(Client("b"))
        servers.catalog = lookup(listOf(item("a1", MediaKind.MOVIE, "a"), item("b1", MediaKind.MOVIE, "b")))
        assertPlays("a1", servers.resolver().resolve(movieLink))
    }

    @Test
    fun continuesTheShowWhereItIsBeingWatched() = runTest {
        servers.add(
            Client("a").apply {
                itemsById["show-a"] = item("show-a", MediaKind.SHOW, "a", lastViewedAt = 100)
                onDeck["show-a"] = item("a-s1e3", MediaKind.EPISODE, "a")
            },
        )
        servers.add(
            Client("b").apply {
                itemsById["show-b"] = item("show-b", MediaKind.SHOW, "b", lastViewedAt = 300)
                onDeck["show-b"] = item("b-s2e1", MediaKind.EPISODE, "b")
            },
        )
        servers.catalog = lookup(listOf(item("show-a", MediaKind.SHOW, "a"), item("show-b", MediaKind.SHOW, "b")))
        assertPlays("b-s2e1", servers.resolver().resolve(showLink), showPlay = true)
    }

    @Test
    fun startsAnUnwatchedShowAtItsFirstEpisode() = runTest {
        servers.add(
            Client("a").apply {
                descendants["show-a"] = listOf(
                    item("s1e2", MediaKind.EPISODE, "a", season = 1, episode = 2),
                    item("s1e1", MediaKind.EPISODE, "a", season = 1, episode = 1),
                )
            },
        )
        servers.catalog = lookup(listOf(item("show-a", MediaKind.SHOW, "a")))
        assertPlays("s1e1", servers.resolver().resolve(showLink), showPlay = true)
    }

    @Test
    fun shufflesTheBestCopyOfAShow() = runTest {
        servers.add(Client("a"))
        servers.add(Client("b"))
        servers.catalog = lookup(listOf(item("show-a", MediaKind.SHOW, "a"), item("show-b", MediaKind.SHOW, "b")))
        val resolution = servers.resolver().resolve(showLink.copy(mode = PlayMode.SHUFFLE))
        assertEquals("show-a", assertIs<PlayLinkResolution.Shuffle>(resolution).item.id)
    }

    @Test
    fun ignoresMatchesOfAnotherKind() = runTest {
        servers.add(Client("a"))
        servers.catalog = lookup(listOf(item("show-a", MediaKind.SHOW, "a")))
        assertFails(PlayLinkFailure.NOT_FOUND, servers.resolver().resolve(movieLink))
    }

    @Test
    fun blamesAnUnreachableServerNotTheLibraryWhenNothingMatched() = runTest {
        servers.add(Client("a"))
        servers.catalog = lookup(emptyList(), failed = setOf("b"))
        assertFails(PlayLinkFailure.SERVER_UNAVAILABLE, servers.resolver().resolve(movieLink))

        servers.catalog = lookup(emptyList(), unqueried = setOf("offline"))
        assertFails(PlayLinkFailure.SERVER_UNAVAILABLE, servers.resolver().resolve(movieLink))

        // Online but unable to run the query: it can't hold the title.
        servers.catalog = lookup(emptyList(), unqueried = setOf("a"))
        assertFails(PlayLinkFailure.NOT_FOUND, servers.resolver().resolve(movieLink))
    }

    @Test
    fun waitsForAnyServerBeforeLooking() = runTest {
        servers.add(Client("a"), online = false)
        servers.catalog = lookup(listOf(item("a1", MediaKind.MOVIE, "a")))
        val resolution = async { servers.resolver().resolve(movieLink) }
        runCurrent()
        assertTrue(servers.catalogQueries.isEmpty())
        servers.online.value += ServerId("a")
        assertPlays("a1", resolution.await())
    }

    @Test
    fun looksALinkWithoutAPlexGuidUpByTheGuidPlexDiscoverHasForItsIds() = runTest {
        servers.add(Client("a"))
        servers.catalog = lookup(listOf(item("a1", MediaKind.MOVIE, "a")))
        servers.plexHash = { target -> if (target.ids.tmdb == 603) "5d776825880197001ec967c2" else null }
        assertPlays("a1", servers.resolver().resolve(movieLink))
        assertEquals("plex://movie/5d776825880197001ec967c2", servers.catalogQueries.single().plexGuid)
        assertEquals(603, servers.catalogQueries.single().ids.tmdb)
    }

    @Test
    fun stillLooksUpByCatalogueIdWhenPlexDiscoverFails() = runTest {
        servers.add(Client("a"))
        servers.catalog = lookup(listOf(item("a1", MediaKind.MOVIE, "a")))
        servers.plexHash = { throw IllegalStateException("discover down") }
        assertPlays("a1", servers.resolver().resolve(movieLink))
        assertNull(servers.catalogQueries.single().plexGuid)
    }

    private companion object {
        fun item(
            id: String,
            kind: MediaKind,
            serverId: String?,
            lastViewedAt: Long? = null,
            season: Int? = null,
            episode: Int? = null,
            viewCount: Int? = null,
        ) = MediaItem(
            id = id,
            backend = BackendKind.PLEX,
            kind = kind,
            title = id,
            serverId = serverId,
            lastViewedAt = lastViewedAt,
            parentIndex = season,
            index = episode,
            viewCount = viewCount,
        )

        fun lookup(items: List<MediaItem>, failed: Set<String> = emptySet(), unqueried: Set<String> = emptySet()) = LibraryLookupResult(
            items = items,
            succeededServerIds = items.mapNotNullTo(HashSet()) { ServerId.tryParse(it.serverId) },
            cancelledServerIds = emptySet(),
            failedServerIds = failed.mapTo(HashSet(), ::ServerId),
            unqueriedServerIds = unqueried.mapTo(HashSet(), ::ServerId),
        )
    }
}
