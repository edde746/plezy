package com.edde746.plezy.ui.detail

import com.edde746.plezy.backend.ItemWithOnDeck
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaDeletionPermission
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRole
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.detail.DetailDeps
import com.edde746.plezy.presentation.detail.DetailDownloads
import com.edde746.plezy.presentation.detail.DownloadedVersion
import com.edde746.plezy.presentation.detail.EpisodeDownloadUi
import com.edde746.plezy.presentation.detail.MediaDetailStore
import com.edde746.plezy.presentation.detail.OfflineDetailSource
import com.edde746.plezy.presentation.downloads.DownloadButtonIcon
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.LibraryRefreshNotifier
import com.edde746.plezy.servers.OfflineModeSource
import com.edde746.plezy.servers.OfflineWatchDownloads
import com.edde746.plezy.servers.OfflineWatchProvider
import com.edde746.plezy.servers.OfflineWatchQueue
import com.edde746.plezy.servers.OfflineWatchSyncService
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchClients
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchStateStore
import com.edde746.plezy.servers.WatchedThresholdSource
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flowOf
import java.lang.reflect.Proxy
import kotlin.time.Duration

/**
 * One detail screen over a Jellyfin server that holds [item] (and, under it, [children]: a show's seasons, a season's
 * episodes) with its [extras] and [related] hubs: the real store, the app's shared media menu and a navigator whose top
 * screen is the detail, over Home. Everything runs at once on the test's thread. The server answers what a detail asks
 * and fails loudly on anything else. [downloads] gives the item a download button and its episodes [episodeDownload],
 * [shuffle] lets a show shuffle, [cards] are the card settings. [offline] opens it from the downloads, which hold the
 * same titles.
 */
internal class DetailFixture(
    val item: MediaItem,
    private val children: Map<String, List<MediaItem>> = emptyMap(),
    private val extras: List<MediaItem> = emptyList(),
    tv: Boolean,
    downloads: Boolean = false,
    shuffle: Boolean = false,
    cards: CardOptions = CardOptions(),
    offline: Boolean = false,
    private val episodeDownload: EpisodeDownloadUi? = null,
    private val related: List<MediaHub> = emptyList(),
) {
    val route = Route.MediaDetail(ServerId(SERVER), item.id, offline = offline)
    val plays = mutableListOf<PlayRequest>()
    val navigator = PlezyNavigator(Route.Home).also { it.navigate(route) }
    private val scope = CoroutineScope(Dispatchers.Unconfined)
    private val server: MediaBackend = server()
    private val notifier = WatchStateNotifier()
    private val watchActions = watchActions()
    private val watchState = WatchStateStore(notifier, scope)

    val store = MediaDetailStore(
        route,
        DetailDeps(
            client = { if (it.value == SERVER) server else null },
            watchActions = watchActions,
            watchState = watchState,
            watchEvents = notifier.events,
            deletions = DeletionNotifier().events,
            play = { plays += it },
            cardOptions = { cards },
            tv = tv,
            downloads = if (downloads) Downloads() else null,
            shuffle = if (shuffle) ({ _: MediaItem -> error("shuffling is not part of these tests") }) else null,
            offline = Downloaded(),
        ),
        scope,
    )

    /** The app's media menu: the user administers the server, which answers and allows deleting. */
    val menu = MediaMenu(
        navigator = navigator,
        client = { if (it.value == SERVER) server else null },
        isOnline = { true },
        isOwnerOrAdmin = { true },
        activeProfile = { null },
        isOffline = { false },
        hasMultipleProfiles = { false },
        fresh = watchState::apply,
        watchStateChanges = watchState.changes,
        watchActions = watchActions,
        deletions = DeletionNotifier(),
        libraryRefresh = LibraryRefreshNotifier(),
        addedToList = { _, _ -> },
        play = { plays += it },
        launchQueue = { error("play queues are not part of these tests") },
        scope = scope,
    )

    val intents = detailIntents(route, store, watchlist = null, menu, navigator)

    /** The server: the item with no on-deck episode, its children a page at a time, its extras, its related hubs. */
    private fun server(): MediaBackend =
        Proxy.newProxyInstance(MediaBackend::class.java.classLoader, arrayOf(MediaBackend::class.java, MediaDeletionPermission::class.java)) { proxy, method, args ->
            when {
                method.name == "fetchItemWithOnDeck" -> ItemWithOnDeck(item.takeIf { it.id == args[0] }, null)
                method.name == "fetchChildren" -> children[args[0]].orEmpty()
                method.name == "fetchChildrenPage" -> children[args[0]].orEmpty().let { LibraryPage(it, it.size) }
                method.name == "fetchExtras" -> extras
                method.name == "fetchRelatedHubs" -> related
                method.name == "fetchDeletePermission" -> true
                method.name == "carriedDeletePermission" -> null
                method.name.startsWith("getServerId") -> SERVER
                method.name == "getServerName" -> "Server"
                method.name == "getBackend" -> BackendKind.JELLYFIN
                method.name == "getCapabilities" -> null
                method.name == "toString" -> "DetailServer"
                method.name == "hashCode" -> 0
                method.name == "equals" -> proxy === args[0]
                else -> error("the detail asked the server for ${method.name}")
            }
        } as MediaBackend

    /** Watch marks over no server, trackers or downloads: nothing in these tests marks anything. */
    private fun watchActions(): WatchActions {
        val clients = unused<WatchClients>()
        val offlineMode = object : OfflineModeSource {
            override val isOffline = MutableStateFlow(false)
        }
        val downloads = unused<OfflineWatchDownloads>()
        val sync = OfflineWatchSyncService(
            unused<OfflineWatchQueue>(),
            downloads,
            clients,
            notifier,
            { error("trackers are not part of these tests") },
            unused<WatchedThresholdSource>(),
            offlineMode,
            scope,
            minSyncInterval = Duration.ZERO,
            forceSyncOnResume = false,
        )
        val offlineWatch = OfflineWatchProvider(sync, downloads, notifier, scope, { SpecialsOrdering.SPECIALS_LAST }, { false })
        return WatchActions(clients, offlineMode, offlineWatch, notifier, { _, _, _ -> error("trackers are not part of these tests") }, scope)
    }

    /** Every title can be downloaded; each episode's download is [episodeDownload]. */
    private inner class Downloads : DetailDownloads {
        override fun spec(item: MediaItem) = flowOf(DownloadButtonSpec(DownloadButtonIcon.DOWNLOAD, tooltip = null))
        override val changes = emptyFlow<Any?>()
        override fun episodeStatus(episode: MediaItem): EpisodeDownloadUi? = episodeDownload
        override suspend fun press(item: MediaItem, client: MediaBackend, fallbackVersions: List<MediaVersion>?) = error("downloading is not part of these tests")
    }

    /** The downloads: the server's titles, without their artwork files or any version on disk. */
    private inner class Downloaded : OfflineDetailSource {
        override suspend fun metadata(serverId: ServerId, itemId: String) = item.takeIf { it.id == itemId }
        override fun seasons(show: MediaItem) = children[show.id].orEmpty()
        override fun episodes(show: MediaItem) = children[show.id].orEmpty().flatMap { children[it.id].orEmpty() }
        override suspend fun onDeck(show: MediaItem): MediaItem? = null
        override fun artwork(serverId: ServerId, path: String?): String? = null
        override suspend fun downloadedVersion(item: MediaItem): DownloadedVersion? = null
    }

    companion object {
        const val SERVER = "jf"

        /** An overview longer than the three lines the page shows of it, so its More takes focus. */
        val LONG_OVERVIEW = List(12) { "A linguist works with the military to talk to the visitors before the world goes to war." }.joinToString(" ")

        fun item(id: String, kind: MediaKind, title: String, block: MediaItem.() -> MediaItem = { this }) =
            MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, title = title, serverId = SERVER).block()

        /** A movie in two versions with a trailer, one actor, a studio and [overview]; it can be downloaded. */
        fun movie(tv: Boolean, overview: String = LONG_OVERVIEW, offline: Boolean = false, related: List<MediaHub> = emptyList()) = DetailFixture(
            item("movie", MediaKind.MOVIE, "Arrival") {
                copy(
                    summary = overview,
                    mediaVersions = listOf(MediaVersion("v1", videoResolution = "1080"), MediaVersion("v2", videoResolution = "4k")),
                    trailerKey = "/library/metadata/trailer",
                    roles = listOf(MediaRole(id = "p1", tag = "Amy Adams", role = "Louise Banks")),
                    studio = "Paramount",
                )
            },
            extras = listOf(item("trailer", MediaKind.MOVIE, "Trailer")),
            tv = tv,
            downloads = true,
            offline = offline,
            related = related,
        )

        /** A show of two seasons of [episodes] episodes each, one actor and a long overview, which can shuffle. */
        fun show(tv: Boolean, episodes: Int = 3): DetailFixture {
            val seasons = (1..2).map { n -> item("s$n", MediaKind.SEASON, "Season $n") { copy(index = n, parentId = "show") } }
            val rows = seasons.associate { season ->
                season.id to (1..episodes).map { n ->
                    item("${season.id}e$n", MediaKind.EPISODE, "Episode $n") { copy(index = n, parentIndex = season.index, parentId = season.id, grandparentId = "show") }
                }
            }
            return DetailFixture(
                item("show", MediaKind.SHOW, "Severance") {
                    copy(summary = LONG_OVERVIEW, roles = listOf(MediaRole(id = "p1", tag = "Adam Scott", role = "Mark")), studio = "Apple")
                },
                children = mapOf("show" to seasons) + rows,
                tv = tv,
                downloads = true,
                shuffle = true,
            )
        }

        /** An interface nothing in these tests reaches: any call fails the test. */
        private inline fun <reified T : Any> unused(): T =
            Proxy.newProxyInstance(T::class.java.classLoader, arrayOf(T::class.java)) { proxy, method, args ->
                when (method.name) {
                    "toString" -> T::class.simpleName
                    "hashCode" -> 0
                    "equals" -> proxy === args[0]
                    else -> error("${T::class.simpleName}.${method.name} is not part of these tests")
                }
            } as T
    }
}
