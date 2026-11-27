package com.edde746.plezy.presentation.browse

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaDeletionPermission
import com.edde746.plezy.backend.MediaDeletionRefusedException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.links.linkProfileRef
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.formatMediaTargetLabel
import com.edde746.plezy.playback.queue.PlayQueueLaunch
import com.edde746.plezy.playback.queue.PlayQueueResult
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.detail.linkForItem
import com.edde746.plezy.presentation.detail.serverItemLink
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.player.PlayerStates
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.servers.DeleteImpact
import com.edde746.plezy.servers.DeleteImpactUnverifiedReason
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.LibraryRefreshNotifier
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchMarkOutcome
import com.edde746.plezy.servers.resolveDeleteImpact
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration

/**
 * Item and playlist menus: [open] resolves what the menu offers (the user's rights on the item's server, whether that
 * server answers, its own per-item delete answer, the [providers]' entries) and publishes it as [menu], and again while
 * it is open once the providers have fetched what it should know (the watchlist's membership); [select] runs an entry,
 * whose questions and sheets come up one at a time as [prompt] and whose outcome lands in [message]. One menu at a
 * time: an open while a menu is open or its action runs does nothing. Main thread only.
 *
 * A UI whose menus are the system's, which need their entries as they open (the context menus of iOS and Apple TV),
 * reads an item's menu as it shows it ([peek]: from what is at hand, at once), reads it again as [revision] moves, and
 * runs its entries through [selectPeeked].
 *
 * @param client the client of a server: an item only ever uses its own server's, never another's.
 * @param isOnline whether a server answers now.
 * @param isOwnerOrAdmin whether the user owns (Plex) or administers (Jellyfin, Emby) a server.
 * @param isOffline the app is offline.
 * @param hasMultipleProfiles the account has several profiles: Show link offers to name the active one.
 * @param fresh an item with the watch state the app knows now (the card may be older).
 * @param watchStateChanges emits as what [fresh] knows changes: [revision] moves.
 * @param addedToList an item was added to playlist or collection `listId` of a server, or a collection was made with
 *   it: that list's download sync rule, if any, runs now.
 * @param play plays an item.
 * @param launchQueue starts a list's play queue (a playlist, a collection, a shuffled show).
 * @param playAudioPlaylist plays an audio playlist in the music player, from a track, answering false when the playlist
 *   has no tracks; null where none is wired.
 * @param playExternal opens an item in another player app, returning the message to show when it couldn't; null on a
 *   device without other player apps.
 */
class MediaMenu(
    private val navigator: PlezyNavigator,
    private val client: (ServerId) -> MediaBackend?,
    private val isOnline: (ServerId) -> Boolean,
    private val isOwnerOrAdmin: (ServerId) -> Boolean,
    private val activeProfile: () -> Profile?,
    private val isOffline: () -> Boolean,
    private val hasMultipleProfiles: () -> Boolean,
    private val fresh: (MediaItem) -> MediaItem,
    private val watchStateChanges: Flow<Unit>,
    private val watchActions: WatchActions,
    private val deletions: DeletionNotifier,
    private val libraryRefresh: LibraryRefreshNotifier,
    private val addedToList: (ServerId, listId: String) -> Unit,
    private val play: (PlayRequest.Item) -> Unit,
    private val launchQueue: (QueueLaunch) -> PlayQueueLaunch,
    private val scope: CoroutineScope,
    private val providers: List<MenuEntryProvider> = emptyList(),
    private val playAudioPlaylist: (suspend (MediaPlaylist, shuffle: Boolean, start: MediaItem?) -> Boolean)? = null,
    private val playExternal: (suspend (MediaItem) -> String?)? = null,
    private val deletePermissionTimeout: Duration = MediaServerTimeouts.DELETE_PERMISSION_PROBE,
    /** The version Play plays of an item (its saved choice, an index of its versions), null for the first. */
    private val savedVersion: (suspend (MediaItem) -> Int?)? = null,
    /** The quality Play plays at. */
    private val currentQuality: (suspend () -> TranscodeQualityPreset)? = null,
) {
    private val mutableMenu = MutableStateFlow<ItemMenu?>(null)
    private val mutablePrompt = MutableStateFlow<MenuPrompt?>(null)
    private val mutableMessage = MutableStateFlow<MenuMessage?>(null)
    private var busy = false
    private var opened: Opened? = null
    private var answer: CompletableDeferred<Any?>? = null
    private var launch: PlayQueueLaunch? = null

    /** The quality Play plays at, as last looked up ([currentQuality]): the one Play Version's qualities check. */
    private var quality = TranscodeQualityPreset.ORIGINAL

    /** [refreshQuality]'s lookup, while it runs. */
    private var qualityLookup: Job? = null

    /** The open menu, or null. */
    val menu: StateFlow<ItemMenu?> = mutableMenu.asStateFlow()

    private val mutableRevision = MutableStateFlow(0)

    /** The menu [open] resolves at hand while [peek] runs its request, else null. */
    private var peeking: Peek? = null

    /** The items whose providers fetched ahead what their first menu should know ([MenuEntryProvider.warmAhead]). */
    private val fetchedAhead = mutableSetOf<String>()

    /**
     * Moves as what a [peek]ed menu offers may have changed: the watch state the app knows, what a provider learnt
     * ahead, a peeked entry that ran. A UI that peeked reads its menus again.
     */
    val revision: StateFlow<Int> = mutableRevision.asStateFlow()

    init {
        scope.launch { watchStateChanges.collect { mutableRevision.update { it + 1 } } }
    }

    /**
     * The menu [request] would open (it calls [open], as a screen's menu request does), resolved at once from what is
     * at hand without opening it: no server is asked (Delete shows as the item's list said). Null when the request
     * opens no menu. The first peek of an item has the providers fetch ahead what its menu should know (the watchlists,
     * loaded once for every menu); [revision] moves if they learnt something.
     */
    fun peek(request: () -> Unit): ItemMenu? = peeked(request)?.let { opened ->
        ItemMenu(opened.target.menuTitle(), opened.entries.map { it.first })
    }

    /**
     * The item [request] opens the menu of has focus, is pressed or is under the pointer: its providers fetch what its
     * next menu should know (the watchlist's membership), as opening a menu has them do.
     */
    fun warm(request: () -> Unit) {
        val opened = peeked(request) ?: return
        providers.forEach { it.warm(opened.target) }
    }

    /** Runs the entry [entryId] of the menu [request] opens, peeked again, as [select] runs an open menu's. */
    fun selectPeeked(request: () -> Unit, entryId: String) {
        val current = peeked(request) ?: return
        if (busy) return
        busy = true
        runAction(entryId) {
            try {
                run(current, entryId)
            } finally {
                mutableRevision.update { it + 1 }
            }
        }
    }

    private fun peeked(request: () -> Unit): Opened? {
        val peek = Peek()
        peeking = peek
        try {
            request()
        } finally {
            peeking = null
        }
        return peek.opened
    }

    /** The running action's question or sheet, or null. */
    val prompt: StateFlow<MenuPrompt?> = mutablePrompt.asStateFlow()

    /** The last action's outcome to show, until [messageShown]. */
    val message: StateFlow<MenuMessage?> = mutableMessage.asStateFlow()

    /**
     * Opens [item]'s menu where [place] says it is; [extras] come first when leading, else last. [playTrailer] adds
     * Play trailer (the detail screen, which knows the item's trailer). [onRow]: the buttons the detail's action row
     * shows, whose entries the menu leaves out.
     */
    fun open(
        item: MediaItem,
        place: MenuPlace = MenuPlace(),
        extras: List<MenuExtra> = emptyList(),
        playTrailer: (() -> Unit)? = null,
        onRow: Set<RowAction> = emptySet(),
    ) = open(MenuTarget.Item(fresh(item)), place, extras, playTrailer, onRow)

    /** Opens [playlist]'s menu. */
    fun open(playlist: MediaPlaylist) = open(MenuTarget.Playlist(playlist), MenuPlace(), emptyList(), null, emptySet())

    /**
     * Closes the menu. Its entries stay pickable until the next [open]: a UI closes the menu as an entry is picked, just
     * before it calls [select].
     */
    fun dismiss() {
        if (mutableMenu.value == null) return
        mutableMenu.value = null
        busy = false
    }

    /** Runs the menu's entry [entryId] and closes the menu. */
    fun select(entryId: String) {
        val current = opened ?: return
        if (busy && mutableMenu.value == null) return
        opened = null
        busy = true
        mutableMenu.value = null
        runAction(entryId) { run(current, entryId) }
    }

    /**
     * Plays [playlist] as its menu's Play and Shuffle do, from [start] (its first item when null), behind the same
     * loading prompt; an audio playlist in the music player.
     */
    fun play(playlist: MediaPlaylist, shuffle: Boolean, start: MediaItem? = null) {
        if (busy) return
        busy = true
        runAction("play") { playPlaylist(playlist, shuffle, start) }
    }

    /** Asks "Delete playlist?", then deletes [playlist]; [onDeleted] once it is gone. */
    fun delete(playlist: MediaPlaylist, onDeleted: () -> Unit) {
        if (busy) return
        busy = true
        runAction(DELETE) { if (deletePlaylist(playlist, T.playlists.deleteConfirm)) onDeleted() }
    }

    private fun runAction(name: String, work: suspend () -> Unit) {
        scope.launch {
            try {
                work()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Menu action $name failed" }
                show(T.messages.errorLoading(error = reason(e)), isError = true)
            } finally {
                launch = null
                mutablePrompt.value = null
                busy = false
            }
        }
    }

    /** Answers a [MenuPrompt.Confirm]. */
    fun confirm(accepted: Boolean) = respond(accepted)

    /** Answers a [MenuPrompt.Options] with the option at [index], or null (dismissed). */
    fun choose(index: Int?) = respond(index)

    /**
     * Asks [prompt] while a [MenuEntryProvider]'s entry runs (a source to pick), as the menu's own entries ask: the
     * index of the option picked, or null when it was dismissed.
     */
    suspend fun askOption(prompt: MenuPrompt.Options): Int? = ask(prompt)

    /** Answers a [MenuPrompt.TextInput] with [text], or null (cancelled). */
    fun submit(text: String?) = respond(text)

    /** Closes a [MenuPrompt.FileInfo] or a [MenuPrompt.Link], or cancels a cancellable [MenuPrompt.Busy]. */
    fun closePrompt() {
        if (mutablePrompt.value is MenuPrompt.Busy) launch?.cancel() else respond(null)
    }

    /** The [message] has shown. */
    fun messageShown() {
        mutableMessage.value = null
    }

    private fun open(target: MenuTarget, place: MenuPlace, extras: List<MenuExtra>, playTrailer: (() -> Unit)?, onRow: Set<RowAction>) {
        peeking?.let { peek ->
            peek.opened = resolve(target, place, extras, playTrailer, onRow, carriedDeletePermission(target), version = 0)
            fetchAhead(target)
            refreshQuality()
            return
        }
        if (busy) return
        busy = true
        scope.launch {
            try {
                currentQuality?.let { quality = it() }
                val version = (target as? MenuTarget.Item)?.item?.let { savedVersion?.invoke(it) } ?: 0
                val deletePermission = deletePermission(target)
                val resolved = resolve(target, place, extras, playTrailer, onRow, deletePermission, version)
                publish(resolved)
                // What the providers fetch as it opens (the watchlist's membership) shows in it while it is open.
                if (!warmAhead(target) || opened !== resolved || mutableMenu.value == null) return@launch
                val learnt = resolve(target, place, extras, playTrailer, onRow, deletePermission, version)
                if (learnt.entries.map { it.first } != resolved.entries.map { it.first }) publish(learnt)
            } catch (e: CancellationException) {
                busy = false
                throw e
            } catch (e: Exception) {
                busy = false
                Log.w(TAG, e) { "Opening the menu of ${target.title} failed" }
                show(T.messages.errorLoading(error = reason(e)), isError = true)
            }
        }
    }

    private fun publish(resolved: Opened) {
        opened = resolved
        mutableMenu.value = ItemMenu(resolved.target.menuTitle(), resolved.entries.map { it.first })
    }

    /**
     * Has the providers fetch, once per item, what its first menu should know ([warmAhead]: the watchlists, loaded once
     * for every menu); [revision] moves if one learnt something. A fetch that failed (a request timed out as the session
     * started) is made again as the item is next peeked.
     */
    private fun fetchAhead(target: MenuTarget) {
        val key = target.aheadKey()
        if (providers.isEmpty() || !fetchedAhead.add(key)) return
        scope.launch { if (warmAhead(target) { fetchedAhead.remove(key) }) mutableRevision.update { it + 1 } }
    }

    /**
     * Has the providers fetch what [target]'s menu should know (`MenuEntryProvider.warmAhead`); true if one learnt
     * something. [failed] when one failed.
     */
    private suspend fun warmAhead(target: MenuTarget, failed: () -> Unit = {}): Boolean = coroutineScope {
        providers.map { provider ->
            async {
                try {
                    provider.warmAhead(target)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "Warming the menu of ${target.title} ahead failed" }
                    failed()
                    false
                }
            }
        }.awaitAll().any { it }
    }

    /**
     * Looks the quality Play plays at up again ([currentQuality]) as a menu is peeked, which asks nothing as it resolves;
     * [revision] moves when it changed, so the peeked menus check the new one.
     */
    private fun refreshQuality() {
        val lookup = currentQuality ?: return
        if (qualityLookup?.isActive == true) return
        qualityLookup = scope.launch {
            val current = lookup()
            if (current == quality) return@launch
            quality = current
            mutableRevision.update { it + 1 }
        }
    }

    /**
     * [target]'s menu, Delete offered by [deletePermission] (the server's answer: [deletePermission] or
     * [carriedDeletePermission]), Play Version checking [version] and [quality].
     */
    private fun resolve(
        target: MenuTarget,
        place: MenuPlace,
        extras: List<MenuExtra>,
        playTrailer: (() -> Unit)?,
        onRow: Set<RowAction>,
        deletePermission: Boolean?,
        version: Int,
    ): Opened {
        val serverId = ServerId.tryParse(target.serverId)
        val provided = mutableMapOf<MenuSlot, List<MenuEntry>>()
        val owners = mutableMapOf<String, MenuEntryProvider>()
        for (provider in providers) {
            val entries = try {
                provider.entries(target, place)
            } catch (e: Exception) {
                Log.w(TAG, e) { "A menu provider's entries for ${target.title} failed" }
                emptyList()
            }
            provided[provider.slot] = provided[provider.slot].orEmpty() + entries
            entries.forEach { owners[it.id] = provider }
        }
        val entries = when (target) {
            is MenuTarget.Playlist -> listMenuEntries(provided)
            is MenuTarget.Item -> if (target.item.kind == MediaKind.COLLECTION) {
                listMenuEntries(provided)
            } else {
                itemMenuEntries(target.item, place, gates(target.item, serverId, deletePermission, version), provided, trailer = playTrailer != null, onRow)
            }
        }
        val (leading, trailing) = extras.partition { it.leading }
        fun List<MenuExtra>.rows() = map { MenuEntry(it.id, it.label, it.icon) to it }
        return Opened(target, place, leading.rows() + entries.map { it to null } + trailing.rows(), owners, playTrailer)
    }

    private fun gates(item: MediaItem, serverId: ServerId?, deletePermission: Boolean?, version: Int): MenuGates {
        if (serverId == null) return MenuGates(externalPlayers = playExternal != null)
        val client = client(serverId)
        val online = isOnline(serverId)
        val admin = isAdminActionAllowed(isOwnerOrAdmin(serverId), item.backend, activeProfile())
        val deletable = item.kind.isServerDeletable && isMediaDeletionAllowed(item.backend, deletePermission, admin)
        return MenuGates(
            version = version,
            quality = quality,
            isAdmin = admin,
            canTranscode = client?.capabilities?.videoTranscoding == true,
            serverOnline = online,
            canRemoveFromContinueWatching = client?.capabilities?.continueWatchingRemoval == true,
            canDeleteFromServer = deletable,
            externalPlayers = playExternal != null,
        )
    }

    /**
     * The answer to whether the user may delete [target]'s item from what is at hand: the item's list's (Plex: the
     * server's switch as last read), which Delete checks again as it runs; false for anything unknown (offline, the
     * server down, no answer carried); null where nothing answers (a list, a kind no server deletes, a Plex server whose
     * owner or admin the user isn't: only they may delete there, so nothing is asked).
     */
    private fun carriedDeletePermission(target: MenuTarget): Boolean? {
        val (item, permission) = deletable(target) ?: return null
        if (!reachable(item)) return false
        return permission.carriedDeletePermission(item) ?: false
    }

    /**
     * As [carriedDeletePermission], asking the server where the item's list carried no answer: false on no answer in
     * time (the probe holds the menu up) or an error.
     */
    private suspend fun deletePermission(target: MenuTarget): Boolean? {
        val (item, permission) = deletable(target) ?: return null
        if (!reachable(item)) return false
        return permission.carriedDeletePermission(item) ?: askDeletePermission(permission, item) ?: false
    }

    /** [target]'s item and the client that answers whether it may be deleted, where one does. */
    private fun deletable(target: MenuTarget): Pair<MediaItem, MediaDeletionPermission>? {
        val item = (target as? MenuTarget.Item)?.item ?: return null
        if (item.kind == MediaKind.COLLECTION || !item.kind.isServerDeletable) return null
        val serverId = ServerId.tryParse(item.serverId) ?: return null
        val permission = client(serverId) as? MediaDeletionPermission ?: return null
        if (item.backend == BackendKind.PLEX && !isAdminActionAllowed(isOwnerOrAdmin(serverId), item.backend, activeProfile())) return null
        return item to permission
    }

    private fun reachable(item: MediaItem): Boolean {
        val serverId = ServerId.tryParse(item.serverId) ?: return false
        return isOnline(serverId) && !isOffline()
    }

    /** [MediaDeletionPermission.fetchDeletePermission], null on no answer in time or an error. */
    private suspend fun askDeletePermission(permission: MediaDeletionPermission, item: MediaItem): Boolean? =
        try {
            withTimeoutOrNull(deletePermissionTimeout) { permission.fetchDeletePermission(item) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Delete permission probe failed" }
            null
        }

    private suspend fun run(opened: Opened, entryId: String) {
        val (entry, extra) = opened.entries.firstOrNull { it.first.id == entryId }
            ?: opened.entries.firstNotNullOfOrNull { (top, _) -> top.descendant(entryId) }?.let { it to null }
            ?: return
        if (extra != null) return extra.run()
        opened.owners[entry.id]?.let { provider ->
            provider.perform(opened.target, opened.place, entry.id)?.let { show(it.text, it.isError) }
            return
        }
        when (val target = opened.target) {
            is MenuTarget.Playlist -> runList(target, entry.id)
            is MenuTarget.Item -> if (target.item.kind == MediaKind.COLLECTION) runList(target, entry.id) else runItem(target.item, opened, entry.id)
        }
    }

    private suspend fun runList(target: MenuTarget, id: String) {
        when (id) {
            PLAY, SHUFFLE -> {
                val shuffle = id == SHUFFLE
                when (target) {
                    is MenuTarget.Playlist -> playPlaylist(target.playlist, shuffle, null)
                    is MenuTarget.Item -> awaitLaunch(launchQueue(QueueLaunch.Collection(target.item, shuffle)))
                }
            }
            DELETE -> when (target) {
                is MenuTarget.Playlist -> deletePlaylist(target.playlist)
                is MenuTarget.Item -> deleteCollection(target.item)
            }
        }
    }

    /**
     * Plays [playlist] from [start] (the first item when null): an audio playlist in the music player, saying so when it
     * has no tracks.
     */
    private suspend fun playPlaylist(playlist: MediaPlaylist, shuffle: Boolean, start: MediaItem?) {
        if (playlist.playlistType == AUDIO) {
            val music = playAudioPlaylist ?: return show(T.messages.musicNotSupported, isError = true)
            if (!music(playlist, shuffle, start)) show(T.messages.failedToCreatePlayQueueNoItems, isError = true)
            return
        }
        awaitLaunch(launchQueue(QueueLaunch.Playlist(playlist, shuffle, start)))
    }

    /** Asks, then deletes [playlist]; true when it is gone. */
    private suspend fun deletePlaylist(playlist: MediaPlaylist, confirmTitle: String = T.playlists.delete): Boolean {
        val client = clientOf(playlist.serverId)
        if (ask<Boolean>(MenuPrompt.Confirm(confirmTitle, T.playlists.deleteMessage(name = playlist.title), T.common.delete)) != true) return false
        val deleted = attempt { client.deletePlaylist(playlist) }
        if (!deleted) {
            show(T.playlists.errorDeleting, isError = true)
            return false
        }
        show(T.playlists.deleted)
        libraryRefresh.notifyPlaylistsChanged()
        return true
    }

    private suspend fun deleteCollection(collection: MediaItem) {
        val client = clientOf(collection.serverId)
        val title = T.collections.deleteCollection
        if (ask<Boolean>(MenuPrompt.Confirm(title, T.collections.deleteConfirm(title = collection.displayTitle), T.common.delete)) != true) return
        try {
            if (client.deleteCollection(collection)) {
                show(T.collections.deleted)
                libraryRefresh.notifyCollectionsChanged()
            } else {
                show(T.collections.deleteFailed, isError = true)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Deleting collection ${collection.id} failed" }
            show(T.collections.deleteFailedWithError(error = reason(e)), isError = true)
        }
    }

    private suspend fun runItem(item: MediaItem, opened: Opened, id: String) {
        val place = opened.place
        when (id) {
            PLAY_FROM_BEGINNING -> play(PlayRequest.Item(serverIdOf(item.serverId), item.id, item.copy(viewOffsetMs = 0), startPosition = Duration.ZERO))
            PLAY_TRAILER -> opened.playTrailer?.invoke()
            WATCH, UNWATCH -> setWatched(item, id == WATCH)
            REMOVE_FROM_CONTINUE_WATCHING -> {
                watchActions.removeFromContinueWatching(item)
                show(T.messages.removedFromContinueWatching)
            }
            DETAILS, SERIES -> detailRouteOf(item)?.let(navigator::navigate)
            REMOVE_FROM_COLLECTION -> place.collectionId?.let { removeFromCollection(item, it) }
            SHUFFLE_PLAY -> awaitLaunch(launchQueue(QueueLaunch.ShuffledShow(item)))
            SHOW_LINK -> showLink(item)
            PLAY_VERSION -> playVersion(item)
            PLAY_EXTERNAL -> playExternal?.invoke(item)?.let { show(it, isError = true) }
            FILE_INFO -> fileInfo(item)
            ADD_TO -> addTo(item)
            ADD_TO_PLAYLIST -> addToPlaylist(item, clientOf(item.serverId))
            ADD_TO_COLLECTION -> addToCollection(item, clientOf(item.serverId))
            DELETE_MEDIA -> deleteFromServer(item)
            else -> playVersionChoice(id)?.let { (version, quality) -> playVersion(item, item.mediaVersions.orEmpty(), version, quality) }
        }
    }

    private suspend fun setWatched(item: MediaItem, watched: Boolean) {
        val text = when (watchActions.setWatched(item, watched)) {
            WatchMarkOutcome.QUEUED_OFFLINE -> if (watched) T.messages.markedAsWatchedOffline else T.messages.markedAsUnwatchedOffline
            WatchMarkOutcome.MARKED -> if (watched) T.messages.markedAsWatched else T.messages.markedAsUnwatched
            WatchMarkOutcome.SKIPPED -> return show(T.messages.errorLoading(error = T.errors.reasonUnreachable), isError = true)
        }
        show(text)
    }

    private suspend fun removeFromCollection(item: MediaItem, collectionId: String) {
        val client = clientOf(item.serverId)
        val confirm = MenuPrompt.Confirm(
            T.collections.removeFromCollection,
            T.collections.removeFromCollectionConfirm(title = item.displayTitle),
            T.common.delete,
        )
        if (ask<Boolean>(confirm) != true) return
        try {
            if (client.removeFromCollection(collectionId, item)) {
                show(T.collections.removedFromCollection)
                libraryRefresh.notifyCollectionsChanged()
            } else {
                show(T.collections.removeFromCollectionFailed, isError = true)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Removing ${item.id} from collection $collectionId failed" }
            show(T.collections.removeFromCollectionError(error = reason(e)), isError = true)
        }
    }

    private suspend fun playVersion(item: MediaItem) {
        val serverId = serverIdOf(item.serverId)
        val client = clientOf(item.serverId)
        val versions = item.mediaVersions?.takeIf { it.isNotEmpty() }
            ?: whileBusy { client.fetchItem(item.id)?.mediaVersions }.orEmpty()
        val saved = if (versions.size > 1) savedVersion?.invoke(item.copy(mediaVersions = versions)) ?: 0 else 0
        val index = if (versions.size > 1) {
            val options = versions.mapIndexed { index, version -> MenuOption(version.displayLabel, selected = index == saved) }
            ask<Int>(MenuPrompt.Options(T.mediaMenu.playVersion, options)) ?: return
        } else {
            0
        }
        val picked = if (isOnline(serverId) && client.capabilities.videoTranscoding) {
            val version = versions.getOrNull(index)
            val rows = PlayerStates.offeredQualities(version?.bitrate, version?.resolutionHeight, quality)
            val options = rows.map { MenuOption(it.label, selected = it.selected) }
            rows[ask<Int>(MenuPrompt.Options(T.videoControls.qualityColumnHeader, options)) ?: return].preset
        } else {
            null
        }
        playVersion(item, versions, index, picked)
    }

    /**
     * Plays [item]'s version [index] of [versions] as it is, at [quality] (null: the original).
     */
    private fun playVersion(item: MediaItem, versions: List<MediaVersion>, index: Int, quality: TranscodeQualityPreset?) {
        play(
            PlayRequest.Item(
                serverIdOf(item.serverId),
                item.id,
                item,
                mediaIndex = index,
                mediaSourceId = versions.getOrNull(index)?.id?.takeIf { item.backend != BackendKind.PLEX },
                strictMediaSelection = true,
                qualityPreset = quality ?: TranscodeQualityPreset.ORIGINAL,
            ),
        )
    }

    /** The entry [id] among this entry's submenu, at any depth. */
    private fun MenuEntry.descendant(id: String): MenuEntry? =
        children.firstOrNull { it.id == id } ?: children.firstNotNullOfOrNull { it.descendant(id) }

    private suspend fun fileInfo(item: MediaItem) {
        val client = clientOf(item.serverId)
        val info = whileBusy { client.getFileInfo(item) } ?: return show(T.messages.fileInfoNotAvailable, isError = true)
        ask<Unit>(MenuPrompt.FileInfo(formatMediaTargetLabel(item), info))
    }

    /** Resolves the link to share for [item] (by catalogue id where it has one) and shows it. */
    private suspend fun showLink(item: MediaItem) {
        val serverId = serverIdOf(item.serverId)
        val link = whileBusy { client(serverId)?.let { linkForItem(it, item) } ?: serverItemLink(item) } ?: return
        val profile = activeProfile()?.takeIf { hasMultipleProfiles() }
        val asProfile = profile?.let { LinkAsProfile(T.deepLinks.openAsProfile(it.displayName), link.asProfile(linkProfileRef(it))) }
        ask<Unit>(MenuPrompt.Link(link.toString(), item.kind, asProfile))
    }

    private suspend fun addTo(item: MediaItem) {
        val client = clientOf(item.serverId)
        val collections = item.backend == BackendKind.PLEX || isAdminActionAllowed(isOwnerOrAdmin(client.serverId), item.backend, activeProfile())
        if (!collections) return addToPlaylist(item, client)
        val options = listOf(MenuOption(T.playlists.playlist, MenuIcon.PLAYLIST), MenuOption(T.collections.collection, MenuIcon.COLLECTION))
        when (ask<Int>(MenuPrompt.Options(T.common.addTo, options))) {
            0 -> addToPlaylist(item, client)
            1 -> addToCollection(item, client)
        }
    }

    private suspend fun addToPlaylist(item: MediaItem, client: MediaBackend) {
        val picked = pick(T.playlists.selectPlaylist, T.playlists.searchPlaylists, T.playlists.noPlaylists) { start, size ->
            val page = client.fetchPlaylistsPage(playlistType = "video", smart = false, start = start, size = size)
            LibraryPage(page.items.map { it.pickerRow() }, page.totalCount, page.offset)
        } ?: return
        when (picked) {
            PickerResult.CreateNew -> {
                val name = askName(T.playlists.create, T.playlists.playlistName, T.playlists.enterPlaylistName) ?: return
                if (attempt { client.createPlaylist(name, listOf(item)) != null }) {
                    show(T.playlists.created)
                    libraryRefresh.notifyPlaylistsChanged()
                } else {
                    show(T.playlists.errorCreating, isError = true)
                }
            }
            is PickerResult.Existing -> if (attempt { client.addToPlaylist(picked.id, listOf(item)) }) {
                show(T.playlists.itemAdded)
                libraryRefresh.notifyPlaylistsChanged()
                addedToList(client.serverId, picked.id)
            } else {
                show(T.playlists.errorAdding, isError = true)
            }
        }
    }

    private suspend fun addToCollection(item: MediaItem, client: MediaBackend) {
        val libraryId = item.libraryId?.takeIf { it.isNotEmpty() }
            ?: libraryOf(client, item.id)
            ?: item.grandparentId?.let { libraryOf(client, it) }
            ?: return show(T.messages.unableToDetermineLibrarySection, isError = true)
        val picked = pick(T.collections.selectCollection, T.collections.searchCollections, T.libraries.noCollections) { start, size ->
            val page = client.fetchCollectionsPage(libraryId, start, size)
            LibraryPage(page.items.map { PickerRow(it.id, it.title.orEmpty(), it.childCount?.let(::itemCount), MenuIcon.COLLECTION) }, page.totalCount, page.offset)
        } ?: return
        when (picked) {
            PickerResult.CreateNew -> {
                val name = askName(T.common.createNew, T.collections.collectionName, T.collections.enterCollectionName) ?: return
                var created: String? = null
                if (attempt { client.createCollection(libraryId, name, listOf(item), item.kind).also { created = it } != null }) {
                    show(T.collections.created)
                    libraryRefresh.notifyCollectionsChanged()
                    addedToList(client.serverId, created!!)
                } else {
                    show(T.collections.errorAddingToCollection, isError = true)
                }
            }
            is PickerResult.Existing -> if (attempt { client.addToCollection(picked.id, listOf(item)) }) {
                show(T.collections.addedToCollection)
                libraryRefresh.notifyCollectionsChanged()
                addedToList(client.serverId, picked.id)
            } else {
                show(T.collections.errorAddingToCollection, isError = true)
            }
        }
    }

    private suspend fun libraryOf(client: MediaBackend, id: String): String? = try {
        client.fetchItem(id)?.libraryId?.takeIf { it.isNotEmpty() }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Resolving the library of $id failed" }
        null
    }

    private suspend fun deleteFromServer(item: MediaItem) {
        val client = clientOf(item.serverId)
        // Offered on the answer at hand (the item's list's; Plex: the switch as last read), which can be stale: the
        // server's own, now, before anything else.
        val permission = client as? MediaDeletionPermission
        if (permission?.carriedDeletePermission(item) != null) {
            val allowed = whileBusy { askDeletePermission(permission, item) }
            if (allowed == false && item.backend == BackendKind.PLEX) return show(T.mediaMenu.mediaDeletionDisabledOnServer, isError = true)
            if (allowed != true) return show(T.mediaMenu.mediaFailedToDelete, isError = true)
        }
        val kind = item.kind
        val impact = if (kind == MediaKind.EPISODE || kind == MediaKind.MOVIE) whileBusy { resolveDeleteImpact(item, client) } else null
        val confirm = MenuPrompt.Confirm(
            title = deleteTitle(kind),
            message = T.mediaMenu.confirmDeleteTarget(title = formatMediaTargetLabel(item)),
            confirmLabel = if (impact?.isUnverified == true) T.mediaMenu.deleteAnyway else deleteConfirmLabel(kind),
            warning = deleteWarning(item, impact),
        )
        if (ask<Boolean>(confirm) != true) return
        val deleted = try {
            client.deleteMediaItem(item)
        } catch (e: CancellationException) {
            throw e
        } catch (e: MediaDeletionRefusedException) {
            // Refused before the delete went out: nothing changed on the server.
            Log.w(TAG, e) { "The server's setting refused deleting ${item.id}" }
            return show(T.mediaMenu.mediaDeletionDisabledOnServer, isError = true)
        } catch (e: Exception) {
            Log.w(TAG, e) { "Deleting ${item.id} from its server failed" }
            false
        }
        if (!deleted) return show(T.mediaMenu.mediaFailedToDelete, isError = true)
        show(T.mediaMenu.mediaDeletedSuccessfully)
        deletions.notifyDeletedItem(item)
        impact?.sharedWith?.forEach { deletions.notifyDeletedItem(it) }
    }

    private suspend fun awaitLaunch(launch: PlayQueueLaunch) {
        this.launch = launch
        mutablePrompt.value = MenuPrompt.Busy(launch.title, cancellable = true)
        val result = try {
            launch.await()
        } finally {
            this.launch = null
            mutablePrompt.value = null
        }
        result.message?.let { show(it, isError = result !is PlayQueueResult.Success) }
    }

    private suspend fun pick(
        title: String,
        searchHint: String,
        empty: String,
        loadPage: suspend (Int, Int) -> LibraryPage<PickerRow>,
    ): PickerResult? {
        val picker = ContainerPicker(title, searchHint, empty, loadPage, scope)
        mutablePrompt.value = MenuPrompt.Picker(picker)
        return try {
            picker.await()
        } finally {
            mutablePrompt.value = null
        }
    }

    private suspend fun askName(title: String, label: String, hint: String): String? =
        ask<String>(MenuPrompt.TextInput(title, label, hint))?.trim()?.takeIf { it.isNotEmpty() }

    @Suppress("UNCHECKED_CAST")
    private suspend fun <R> ask(prompt: MenuPrompt): R? {
        val deferred = CompletableDeferred<Any?>()
        answer = deferred
        mutablePrompt.value = prompt
        return try {
            deferred.await() as R?
        } finally {
            answer = null
            mutablePrompt.value = null
        }
    }

    private fun respond(value: Any?) {
        answer?.complete(value)
    }

    private suspend fun <R> whileBusy(work: suspend () -> R): R {
        mutablePrompt.value = MenuPrompt.Busy()
        return try {
            work()
        } finally {
            mutablePrompt.value = null
        }
    }

    /** [work]'s answer, false when it threw (logged). */
    private suspend fun attempt(work: suspend () -> Boolean): Boolean = try {
        work()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "A menu action's server call failed" }
        false
    }

    /** Shows [text] as the [message]. */
    fun show(text: String, isError: Boolean = false) {
        mutableMessage.value = MenuMessage(text, isError)
    }

    private fun serverIdOf(serverId: String?): ServerId = ServerId.tryParse(serverId) ?: throw ItemServerUnavailable()

    /** The client of the item's own server; an item never goes to another server's. */
    private fun clientOf(serverId: String?): MediaBackend = client(serverIdOf(serverId)) ?: throw ItemServerUnavailable()

    private fun reason(e: Exception): String = if (e is ItemServerUnavailable) T.errors.reasonUnreachable else localizedErrorReason(e)

    private class Opened(
        val target: MenuTarget,
        val place: MenuPlace,
        val entries: List<Pair<MenuEntry, MenuExtra?>>,
        val owners: Map<String, MenuEntryProvider>,
        val playTrailer: (() -> Unit)?,
    )

    private fun MenuTarget.aheadKey(): String = when (this) {
        is MenuTarget.Item -> "$serverId/${item.id}"
        is MenuTarget.Playlist -> "$serverId/playlist/${playlist.id}"
    }

    /** A [peek] under way: the menu its request opened. */
    private class Peek {
        var opened: Opened? = null
    }

    /** The item's server has no client: an action can't reach it. */
    private class ItemServerUnavailable : Exception("The item's server has no client")

    private companion object {
        const val TAG = "MediaMenu"
        const val AUDIO = "audio"
    }
}

/** A list play queue a menu starts ([MediaMenu]'s `launchQueue`). */
sealed interface QueueLaunch {
    data class Playlist(val playlist: MediaPlaylist, val shuffle: Boolean, val start: MediaItem? = null) : QueueLaunch

    data class Collection(val collection: MediaItem, val shuffle: Boolean) : QueueLaunch

    data class ShuffledShow(val item: MediaItem) : QueueLaunch
}

/** A [MenuPrompt.Confirm]'s danger block for deleting [item], or null when the delete is verified to take only it. */
internal fun deleteWarning(item: MediaItem, impact: DeleteImpact?): String? {
    if (item.kind == MediaKind.SHOW || item.kind == MediaKind.SEASON) {
        val episodes = item.leafCount ?: if (item.kind == MediaKind.SEASON) item.childCount else null
        return if (episodes != null && episodes > 0) T.mediaMenu.deleteEpisodeCountWarning(n = episodes) else T.mediaMenu.deleteMultipleWarning
    }
    if (impact == null) return null
    if (impact.isUnverified) {
        return if (impact.reason == DeleteImpactUnverifiedReason.NO_FILE_INFO) {
            T.mediaMenu.deleteScopeUnverifiedNoFileInfo
        } else {
            T.mediaMenu.deleteScopeUnverifiedProbeFailed
        }
    }
    if (!impact.isBroad) return null
    return buildList {
        if (impact.files.size > 1) add(T.mediaMenu.deleteMultiPartWarning(n = impact.files.size))
        if (impact.sharedWith.isNotEmpty()) {
            add(T.mediaMenu.deleteSharedFileHeading(n = impact.sharedWith.size))
            impact.sharedWith.forEach { add("\u2022 ${formatMediaTargetLabel(it)}") }
        }
    }.joinToString("\n")
}

private fun deleteTitle(kind: MediaKind): String = when (kind) {
    MediaKind.SEASON -> T.mediaMenu.deleteSeasonTitle
    MediaKind.SHOW -> T.mediaMenu.deleteShowTitle
    MediaKind.MOVIE -> T.mediaMenu.deleteMovieTitle
    else -> T.mediaMenu.deleteEpisodeTitle
}

private fun deleteConfirmLabel(kind: MediaKind): String = when (kind) {
    MediaKind.SEASON -> T.mediaMenu.deleteSeasonConfirm
    MediaKind.SHOW -> T.mediaMenu.deleteShowConfirm
    MediaKind.MOVIE -> T.mediaMenu.deleteMovieConfirm
    else -> T.mediaMenu.deleteEpisodeConfirm
}

private fun itemCount(count: Int): String = if (count == 1) T.playlists.oneItem else T.playlists.itemCount(count = count.toString())

private fun MediaPlaylist.pickerRow() = PickerRow(
    id = id,
    title = title,
    subtitle = leafCount?.let(::itemCount),
    icon = if (smart) MenuIcon.SMART_PLAYLIST else MenuIcon.PLAYLIST,
    enabled = !smart,
)
