package com.edde746.plezy.app

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.downloads.BackgroundSettingsTarget
import com.edde746.plezy.downloads.BackgroundWorkDiagnosticsService
import com.edde746.plezy.downloads.BackgroundWorkProbe
import com.edde746.plezy.downloads.DownloadArtworkService
import com.edde746.plezy.downloads.DownloadManagerService
import com.edde746.plezy.downloads.DownloadServers
import com.edde746.plezy.downloads.DownloadStorageService
import com.edde746.plezy.downloads.DownloadTask
import com.edde746.plezy.downloads.DownloadedVideoSource
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.downloads.LibraryDownloadedVideoSource
import com.edde746.plezy.downloads.LocalPath
import com.edde746.plezy.downloads.TaskDownloader
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.downloads.BackgroundDownloadWarning
import com.edde746.plezy.presentation.downloads.DetailDownload
import com.edde746.plezy.presentation.downloads.DownloadActions
import com.edde746.plezy.presentation.downloads.DownloadDialogs
import com.edde746.plezy.presentation.downloads.DownloadLocationModel
import com.edde746.plezy.presentation.downloads.DownloadsStore
import com.edde746.plezy.presentation.downloads.SmartDeletion
import com.edde746.plezy.presentation.downloads.SyncRulesStore
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.io.files.SystemFileSystem

/**
 * The downloads of one running app ([AppSession.downloads]): the storage, the device's downloader, the download
 * manager, the [controller] every download action goes through, the [videoSource] offline playback reads and the
 * downloads screens' stores. Built by [AppSession] after its [AppServers], on the main thread; [close]d with it.
 *
 * It follows the app as the earlier releases did:
 * - at launch, the storage reads its folder and the manager recovers what the last process left before the controller
 *   loads ([DownloadManagerService.recoverInterruptedDownloads]);
 * - each server that comes online resumes the queue and refreshes its downloads' collections, once until it goes
 *   offline again;
 * - moving onto Wi-Fi or Ethernet, and offline watch state refreshed from the servers, run auto-removal and the sync
 *   rules; watched marks run the rules covering the item (the controller's own debounce);
 * - the Wi-Fi-only setting applies to every task as it changes; the active profile's switches reach the controller.
 *
 * A logout reaches the controller as the active profile clearing: its owners were detached in the database by the
 * profiles' teardown.
 *
 * @param playingItemKey the global key of the item the player plays now, or null: auto-removal and watched marks' rule
 *   runs leave it alone.
 * @param openUrl opens a web link outside the app (the background-download warning's help); false when nothing could.
 */
class AppDownloads internal constructor(
    graph: AppGraph,
    private val platform: PlatformDownloads,
    private val notificationPermission: NotificationPermission,
    private val servers: AppServers,
    private val playingItemKey: () -> String?,
    private val openUrl: (String) -> Boolean,
) {
    private val scope = graph.scope.childScope()
    private val data = graph.data
    private val http = MediaServerHttpClient(graph.http)

    private val specialsOrdering = data.deviceSettings.observe(AppSettings.specialsOrdering).current(AppSettings.specialsOrdering.default)
    private val autoRemoveWatched = data.deviceSettings.observe(AppSettings.autoRemoveWatchedDownloads).current(AppSettings.autoRemoveWatchedDownloads.default)

    /** The servers' names as the saved connections list them, for servers that aren't connected. */
    private val knownServerNames: StateFlow<Map<String, String>> = servers.connections.observeSummaries().map { connections ->
        buildMap { for (connection in connections) putAll(connection.serverNames) }
    }.current(emptyMap())

    /** Where downloads live and what their files are called. */
    val storage = DownloadStorageService(platform.storage, data.deviceSettings)

    private val artwork = DownloadArtworkService(storage, http)
    private val downloader: TaskDownloader = platform.install(graph.http) {
        TaskDownloader(data, it, graph.network, scope) { task -> authorizeDownload(task) }
    }

    /**
     * [task] with its server's access token, from the client of the identity its download was queued under: tasks are
     * kept without it. Null while that client isn't there (not connected yet, signed out, hidden).
     */
    private suspend fun authorizeDownload(task: DownloadTask): DownloadTask? {
        val serverId = parseGlobalKey(task.metaData)?.first ?: return null
        val clientScopeId = data.downloadLibrary.getDownloadedMedia(task.metaData)?.client_scope_id
        val client = servers.manager.resolveDownloadClient(serverId, clientScopeId) ?: return null
        return task.copy(url = client.authorizeDownloadUrl(task.url))
    }

    private val manager = DownloadManagerService(
        database = data.downloadLibrary,
        storage = storage,
        artwork = artwork,
        clientResolver = servers.manager::resolveDownloadClient,
        caches = servers.caches,
        mediaBrowserResolver = servers.jellyfinCacheResolver,
        downloader = downloader,
        safStorage = platform.safStorage,
        settings = data.deviceSettings,
        http = http,
        fileSystem = SystemFileSystem,
        io = Dispatchers.IO,
        parentScope = scope,
    )

    /** The completed downloads' files, which offline playback plays. */
    val videoSource: DownloadedVideoSource = LibraryDownloadedVideoSource(data.downloadLibrary, storage, platform.safStorage)

    /** The active profile's downloads and every download action. */
    val controller = DownloadsController(
        manager = manager,
        library = data.downloadLibrary,
        syncRuleRepository = data.syncRules,
        collectionRepository = data.downloadCollections,
        watchQueue = data.offlineWatch,
        servers = object : DownloadServers {
            override fun client(serverId: ServerId): MediaBackend? = servers.manager.client(serverId)

            override fun isServerOnline(serverId: ServerId): Boolean = servers.manager.isServerOnline(serverId)
        },
        watchStateNotifier = servers.watchStates,
        deletionNotifier = servers.deletions,
        notificationPermission = notificationPermission,
        videoSource = videoSource,
        artwork = artwork,
        connectivity = { servers.connectivity.check() },
        caches = servers.caches::get,
        specialsOrdering = { specialsOrdering.value },
        autoRemoveWatchedDownloads = { autoRemoveWatched.value },
        playingItemKey = playingItemKey,
        clock = { graph.clock.now().toEpochMilliseconds() },
        parentScope = scope,
    )

    /** The background-work verdict the downloads warnings read (silent where [PlatformDownloads.backgroundWork] is null). */
    private val diagnostics = BackgroundWorkDiagnosticsService(
        probe = platform.backgroundWork ?: NoBackgroundWork,
        isSupported = platform.backgroundWork != null,
        foreground = graph.foreground,
        networkProbe = {
            val links = servers.connectivity.check()
            links.hasNetwork && !manager.shouldBlockDownloadOnCellularWith(links)
        },
        scope = scope,
    )

    /** The download dialogs on screen: one at a time across the app. */
    val dialogs = DownloadDialogs()

    /** The background-restriction pre-flight and banner. */
    val warning = BackgroundDownloadWarning(diagnostics, data.deviceSettings, notificationPermission, { openUrl(it) }, scope)

    /** Deleting with a progress dialog. */
    val deletion = SmartDeletion(controller)

    /** Downloading from a title's menus: the options, then the queue. */
    val actions = DownloadActions(controller, dialogs, warning, data.deviceSettings)

    /** A detail screen's download button. */
    val detail = DetailDownload(controller, actions, dialogs, warning, deletion)

    private val resumeCovered = mutableSetOf<ServerId>()

    init {
        scope.launch {
            storage.initialize()
            manager.recoverInterruptedDownloads()
        }
        controller.setOfflineSource(servers.offlineMode)
        diagnostics.bindActivitySource(controller::downloadActivitySnapshot)
        scope.launch { servers.profiles.active.map { it?.id }.distinctUntilChanged().collect(controller::setActiveProfileId) }
        scope.launch {
            controller.onConnectivityChanged(servers.connectivity.check())
            servers.connectivity.changes.collect(controller::onConnectivityChanged)
        }
        scope.launch { servers.offlineWatchSync.watchStatesRefreshed.collect { controller.onWatchStatesRefreshed() } }
        scope.launch {
            data.deviceSettings.observe(AppSettings.downloadOnWifiOnly).distinctUntilChanged().drop(1).collect { controller.applyDownloadOnWifiOnly(it) }
        }
        scope.launch {
            servers.store.state.map { it.onlineServerIds.toSet() }.distinctUntilChanged().collect(::onServersOnline)
        }
    }

    /**
     * Resumes the queue through any online client and refreshes the downloads' collections of the servers that came
     * online since the last resume; a server that went offline counts as new when it returns.
     */
    private fun onServersOnline(online: Set<ServerId>) {
        val newlyOnline = online - resumeCovered
        val client = online.firstNotNullOfOrNull { servers.manager.client(it) }
        if (newlyOnline.isEmpty() || client == null) {
            resumeCovered.retainAll(online)
            return
        }
        resumeCovered.clear()
        resumeCovered += online
        scope.launch { controller.refreshMetadataFromCache() }
        scope.launch {
            controller.ensureInitialized()
            controller.resumeQueuedDownloads(client)
            controller.syncDownloadCollections(newlyOnline)
        }
    }

    /** The Downloads screen's store; [DownloadsStore.release] it when the screen goes. */
    fun downloadsStore(parentScope: CoroutineScope): DownloadsStore = DownloadsStore(
        controller = controller,
        prefs = data.libraryPrefs,
        warning = warning,
        diagnostics = diagnostics.status,
        watchActions = servers.watchActions,
        offline = servers.offlineMode.isOffline,
        clientFor = { serverId -> ServerId.tryParse(serverId)?.let(servers.manager::client) },
        serverNameOf = ::serverName,
        dialogs = dialogs,
        deletion = deletion,
        parentScope = parentScope,
    )

    /** The Sync rules screen's store; [SyncRulesStore.release] it when the screen goes. */
    fun syncRulesStore(parentScope: CoroutineScope): SyncRulesStore = SyncRulesStore(
        controller = controller,
        actions = actions,
        servers = servers.store.state,
        activeServerName = { servers.manager.client(it)?.serverName },
        knownServerName = { knownServerNames.value[it] },
        parentScope = parentScope,
    )

    /** Settings → Downloads location, over [scope] (the settings screen's). */
    fun location(scope: CoroutineScope): DownloadLocationModel = DownloadLocationModel(
        controller = controller,
        settings = data.deviceSettings,
        picker = platform.folderPicker,
        isWritable = storage::isDirectoryWritable,
        defaultPath = { LocalPath.join(storage.baseAppDirectoryPath(), DOWNLOADS_FOLDER) },
        scope = scope,
    )

    private fun serverName(serverId: String): String? =
        ServerId.tryParse(serverId)?.let { servers.manager.client(it)?.serverName } ?: knownServerNames.value[serverId]

    /** Stops the downloads' work; the device's downloader stops running transfers for this session. */
    fun close() {
        controller.dispose()
        diagnostics.close()
        manager.dispose()
        platform.uninstall(downloader)
        scope.cancel()
    }

    private fun <T> Flow<T>.current(initial: T): StateFlow<T> = stateIn(scope, SharingStarted.Eagerly, initial)

    private companion object {
        /** The downloads folder under the base directory ([DownloadStorageService]'s default root). */
        const val DOWNLOADS_FOLDER = "downloads"
    }
}

/**
 * Plays a downloaded movie or episode from the Downloads screen: from its downloaded copy, any downloaded version
 * while the app is offline. False for anything else (a show, a season, a track: those open where they are).
 */
fun AppSession.playDownloaded(item: MediaItem): Boolean {
    if (item.kind != MediaKind.MOVIE && item.kind != MediaKind.EPISODE) return false
    val serverId = item.serverId ?: return false
    play(PlayRequest.Item(ServerId(serverId), item.id, item, offline = servers.offlineMode.isOffline.value))
    return true
}

/** A platform that tells no background-work signals: nothing to probe, no settings to open. */
private object NoBackgroundWork : BackgroundWorkProbe {
    override suspend fun backgroundWorkSignals(): Map<String, Any?>? = null

    override suspend fun openBackgroundSettings(target: BackgroundSettingsTarget): Boolean = false
}
