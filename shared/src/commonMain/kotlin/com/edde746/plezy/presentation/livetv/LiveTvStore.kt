package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.localizedLoadErrorMessage
import com.edde746.plezy.backend.localizedLoadErrorText
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.livetv.FavoriteChannelPersistenceMode
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvDvrSupport
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.favoriteChannelKey
import com.edde746.plezy.livetv.favoriteChannelOf
import com.edde746.plezy.livetv.filterLiveTvChannelsForFavorites
import com.edde746.plezy.livetv.groupLiveTvChannelsBySource
import com.edde746.plezy.livetv.liveTvDvr
import com.edde746.plezy.livetv.liveTvNonEmpty
import com.edde746.plezy.livetv.liveTvProgramMatchesChannel
import com.edde746.plezy.livetv.scopeKey
import com.edde746.plezy.livetv.stableKey
import com.edde746.plezy.log.Log
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.Instant

/**
 * The Live TV screen: the channels of every Live TV server and DVR, the tabs, the favourites (filter, toggle, reorder),
 * the guide search and the app bar's actions. It drives the tab stores: the Guide gets the channels to show, What's On
 * every channel, and each tab's refresh runs only while it is the selected tab ([LiveTvRefreshGate]).
 *
 * Main thread only; [close] when the screen goes (the tab stores are their owner's to close).
 *
 * @param favoritesOnly whether the favourites filter starts on (the "Default to favourite channels" setting).
 * @param use24HourClock whether search results show times on a 24-hour clock (the platform's setting).
 * @param utcOffset the local UTC offset, in seconds, at an epoch millisecond.
 */
class LiveTvStore(
    private val servers: LiveTvServers,
    private val guide: LiveTvGuideTab,
    private val whatsOn: LiveTvWhatsOnTab,
    private val recordings: LiveTvRecordingsTab,
    favoritesOnly: Boolean,
    parentScope: CoroutineScope,
    use24HourClock: Boolean,
    private val now: () -> Instant = { Clock.System.now() },
    private val utcOffset: (Long) -> Int = ::localUtcOffsetSeconds,
) {
    private val scope = parentScope.childScope()
    private var use24HourClock = use24HourClock

    private var channels: List<LiveTvChannel> = emptyList()
    private var loading = true
    private var error: String? = null
    private var tabs = listOf(LiveTvTab.GUIDE)
    private var selectedTab = LiveTvTab.GUIDE
    private var canProcessRules = false
    private var favoritesOnly = favoritesOnly
    private var message: LiveTvMessage? = null
    private var focus: LiveTvFocusTarget? = null
    private var channelsLoad: Job? = null

    private var favorites: List<FavoriteChannel> = emptyList()
        set(value) {
            field = value
            favoriteKeys = value.mapTo(HashSet()) { it.stableKey }
        }
    private var favoriteKeys: Set<String> = emptySet()

    // The favourite source, store and persistence mode of each Live TV entry (`{serverId}\0{dvrKey}`), which entry each
    // loaded channel came through, and the store of each favourite source. The last also holds sources of favourites
    // that other servers sharing an account-wide store returned.
    private var scopeByEntry: Map<String, FavoriteScope> = emptyMap()
    private var entryByChannel: Map<String, String> = emptyMap()
    private val storeBySource = HashMap<String, String>()

    private var favoritesGeneration = 0
    private var favoritesLoad: Job? = null
    private val favoriteMutations = Mutex()

    // Whether [favorites] is an authoritative set. A reload keeps the previous set until the new one lands, so the
    // filter never widens meanwhile; mutations wait for every store to have loaded, so a write can't wipe a store whose
    // read failed.
    private var favoritesLoaded = false
    private var favoritesWritable = false

    private var search: SearchSession? = null
    private var searchGeneration = 0
    private var reorder: List<FavoriteChannel>? = null

    private var pushedGuide: Triple<List<LiveTvChannel>, Set<String>, Boolean>? = null

    private val mutableState = MutableStateFlow(buildState())
    val state: StateFlow<LiveTvUiState> = mutableState.asStateFlow()

    init {
        refreshTabs()
        gateTabs()
        publish()
        loadChannels()
    }

    /** Selects [tab]; selecting the selected tab sends focus into its content. */
    fun selectTab(tab: LiveTvTab) {
        if (tab !in tabs) return
        if (tab == selectedTab) {
            focus = LiveTvFocusTarget.CONTENT
        } else {
            selectedTab = tab
            gateTabs()
        }
        publish()
    }

    /** The screen was shown (true) or covered or left (false): the tabs' refreshes follow. */
    fun setShown(shown: Boolean) {
        guide.refresh.setShown(shown)
        whatsOn.refresh.setShown(shown)
        recordings.refresh.setShown(shown)
    }

    /** The platform's 24-hour clock setting changed. */
    fun setUse24HourClock(use24HourClock: Boolean) {
        if (this.use24HourClock == use24HourClock) return
        this.use24HourClock = use24HourClock
        publish()
    }

    /** Moves focus into the selected tab's content (down from the chips). */
    fun focusContent() = requestFocus(LiveTvFocusTarget.CONTENT)

    /** Moves focus to the tab chips (up from the content). */
    fun focusTabBar() = requestFocus(LiveTvFocusTarget.TAB_BAR)

    /** Moves focus to the app bar's buttons (right from the last chip). */
    fun focusActions() = requestFocus(LiveTvFocusTarget.ACTIONS)

    fun focusHandled() {
        focus = null
        publish()
    }

    /** Shows [message] in the screen's snackbar (an outcome of a sheet over it). */
    fun showMessage(message: LiveTvMessage) {
        this.message = message
        publish()
    }

    fun messageShown() {
        message = null
        publish()
    }

    /** Runs an app bar button. */
    fun perform(action: LiveTvAction) {
        when (action) {
            LiveTvAction.SEARCH -> openSearch()
            LiveTvAction.FAVORITES_FILTER -> setFavoritesOnly(!favoritesOnly)
            LiveTvAction.REORDER_FAVORITES -> openReorder()
            LiveTvAction.PROCESS_RULES -> scope.launch { processRecordingRules() }
            LiveTvAction.REFRESH -> scope.launch { refresh() }
        }
    }

    /** Loads the channels again after the load failed. */
    fun retry() {
        loadChannels()
    }

    /** The favourites empty state's "Show all channels": the filter goes off; [hadFocus] moves focus to the guide. */
    fun showAllChannels(hadFocus: Boolean) {
        favoritesOnly = false
        if (hadFocus) focus = LiveTvFocusTarget.CONTENT
        publish()
    }

    /** Adds [channel] to the favourites, or removes it, once the favourites have loaded. */
    fun toggleFavorite(channel: LiveTvChannel) = enqueueFavoriteMutation {
        val source = sourceFor(channel)
        val storeKey = channel.favoriteStoreKey ?: scopeFor(channel)?.storeKey
        if (storeKey != null) storeBySource[source] = storeKey
        favorites = if (favoriteChannelKey(source, channel.key) in favoriteKeys) {
            favorites.filterNot { it.id == channel.key && it.source == source }
        } else {
            favorites + favoriteChannelOf(channel, source)
        }
    }

    fun close() = scope.cancel()

    // Guide search

    /** Opens the guide search over every channel, loading the next day's airings. */
    fun openSearch() {
        val generation = ++searchGeneration
        val session = SearchSession(channels)
        search = session
        publish()
        scope.launch { loadSearchPrograms(session, generation) }
    }

    /** The search field's text. */
    fun setSearchQuery(query: String) {
        val session = search ?: return
        session.query = query
        publish()
    }

    /** The query was submitted (or came from a remote): focus goes to the first result, if any. */
    fun submitSearch() {
        val session = search ?: return
        if (searchState(session).hasResults) requestFocus(LiveTvFocusTarget.SEARCH_RESULT)
    }

    fun closeSearch() {
        search = null
        searchGeneration++
        publish()
    }

    /** Closes the search and shows [channel] in the guide. */
    fun selectSearchChannel(channel: LiveTvChannel) {
        closeSearch()
        showInGuide(channel)
        guide.jumpToChannel(channel)
    }

    /** Closes the search and shows [program] on [channel] in the guide. */
    fun selectSearchProgram(channel: LiveTvChannel, program: LiveTvProgram) {
        closeSearch()
        showInGuide(channel)
        guide.jumpToProgram(channel, program)
    }

    // Reorder favourites

    fun openReorder() {
        reorder = favorites
        publish()
    }

    fun closeReorder() {
        reorder = null
        publish()
    }

    /** Moves the favourite at [from] to [to] and saves the order. */
    fun moveFavorite(from: Int, to: Int) {
        val list = reorder?.toMutableList() ?: return
        if (from !in list.indices || to !in list.indices || from == to) return
        list.add(to, list.removeAt(from))
        reorder = list
        publish()
        enqueueFavoriteMutation { favorites = list }
    }

    /** Removes the favourite at [index] and saves; removing the last closes the sheet. */
    fun removeFavorite(index: Int) {
        val list = reorder?.toMutableList() ?: return
        if (index !in list.indices) return
        val removed = list.removeAt(index)
        reorder = list.takeIf { it.isNotEmpty() }
        publish()
        enqueueFavoriteMutation { favorites = favorites.filterNot { it.stableKey == removed.stableKey } }
    }

    // Channels

    private fun loadChannels(): Job {
        channelsLoad?.takeIf { it.isActive }?.let { return it }
        return scope.launch { loadChannelsOnce() }.also { channelsLoad = it }
    }

    private suspend fun loadChannelsOnce() {
        loading = true
        error = null
        publish()
        try {
            val entries = servers.entries
            if (entries.isEmpty()) {
                loading = false
                error = T.liveTv.noDvr
                publish()
                return
            }
            val loaded = mutableListOf<LiveTvChannel>()
            val seen = HashSet<String>()
            val scopes = HashMap<String, FavoriteScope>()
            val entryKeys = HashMap<String, String>()
            val stores = HashMap<String, String>()
            var tried = 0
            var failed = 0
            var firstFailure: Exception? = null

            // One entry per DVR: visit them all, channels dedupe by scope key.
            servers.forEachLiveTvServer(
                dedupeByServerId = false,
                onError = { _, entry, e ->
                    failed++
                    if (firstFailure == null) firstFailure = e
                    Log.e(TAG, e) { "Failed to load channels from server ${entry.serverId.value}" }
                },
            ) { client, entry ->
                tried++
                val liveTv = client.liveTv
                val source = liveTv.buildFavoriteChannelSource(entry.lineup)
                val storeKey = liveTv.favoriteStoreKey
                val entryKey = entryKey(entry)
                scopes[entryKey] = FavoriteScope(source, storeKey, liveTv.favoritePersistenceMode)
                stores[source] = storeKey
                val sourceTitle = sourceTitle(entry)
                // Plex maps the channels a DVR has enabled; Jellyfin and Emby list subscribed channels only.
                val enabled = enabledChannelKeys(entry)
                for (channel in liveTv.fetchChannels(entry.lineup)) {
                    if (enabled != null && channel.key !in enabled) continue
                    val scoped = channel.copy(
                        liveDvrKey = entry.dvrKey,
                        liveTvSourceTitle = sourceTitle,
                        favoriteSource = source,
                        favoriteStoreKey = storeKey,
                    )
                    if (seen.add(scoped.scopeKey)) {
                        entryKeys[scoped.scopeKey] = entryKey
                        loaded += scoped
                    }
                }
            }

            val failure = firstFailure
            if (failure != null && failed == tried) {
                // Nothing replaces what shows: keep the loaded channels and say so, or show the error with none.
                val text = localizedLoadErrorText(failure, T.liveTv.title)
                loading = false
                if (channels.isEmpty()) error = text else message = LiveTvMessage(text, isError = true)
                publish()
                return
            }

            channels = loaded.sortedBy { it.number?.toDoubleOrNull() ?: UNNUMBERED }
            scopeByEntry = scopes
            entryByChannel = entryKeys
            storeBySource.clear()
            storeBySource.putAll(stores)
            loading = false
            refreshTabs()
            gateTabs()
            whatsOn.setChannels(channels)
            if (channels.isNotEmpty()) focus = LiveTvFocusTarget.CONTENT
            publish()
            favoritesLoad = scope.launch { loadFavorites() }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            loading = false
            error = localizedLoadErrorMessage(e, T.liveTv.title)
            publish()
        }
    }

    private fun enabledChannelKeys(entry: LiveTvServerEntry): Set<String>? {
        val dvrs = entry.dvrs.filter { it.key == entry.dvrKey }.ifEmpty { entry.dvrs }
        if (dvrs.none { it.channelMappings.isNotEmpty() }) return null
        return dvrs.flatMap { dvr -> dvr.channelMappings.filter { it.enabled == true }.mapNotNull { it.channelKey } }.toSet()
    }

    private fun sourceTitle(entry: LiveTvServerEntry): String? {
        val dvr = entry.dvrs.firstOrNull { it.key == entry.dvrKey } ?: return liveTvNonEmpty(entry.lineup)
        return liveTvNonEmpty(dvr.lineupTitle) ?: liveTvNonEmpty(dvr.lineupUrl) ?: liveTvNonEmpty(dvr.lineup)
    }

    // Tabs and actions

    private fun refreshTabs() {
        var hasWhatsOn = false
        var hasDvr = false
        var processes = false
        for (entry in servers.entries) {
            val client = servers.client(entry.serverId) ?: continue
            hasWhatsOn = hasWhatsOn || client.liveTv.whatsOn != null
            val dvr = client.liveTvDvr ?: continue
            hasDvr = true
            processes = processes || dvr.supportsRuleProcessing
        }
        tabs = listOfNotNull(LiveTvTab.GUIDE, LiveTvTab.WHATS_ON.takeIf { hasWhatsOn }, LiveTvTab.RECORDINGS.takeIf { hasDvr })
        canProcessRules = processes
        if (selectedTab !in tabs) selectedTab = LiveTvTab.GUIDE
    }

    private fun gateTabs() {
        guide.refresh.setSelected(selectedTab == LiveTvTab.GUIDE)
        whatsOn.refresh.setSelected(selectedTab == LiveTvTab.WHATS_ON)
        recordings.refresh.setSelected(selectedTab == LiveTvTab.RECORDINGS)
    }

    private suspend fun refresh() {
        if (selectedTab == LiveTvTab.RECORDINGS) {
            recordings.reload()
            return
        }
        broadcastToDvrs(T.liveTv.guideReloadRequested, T.liveTv.guideReloadFailed, "Reload guide") { dvr, entry ->
            dvr.reloadGuide(entry.dvrKey)
        }
        loadChannels().join()
    }

    private suspend fun processRecordingRules() {
        val reached = broadcastToDvrs(T.liveTv.rulesProcessRequested, T.liveTv.rulesProcessFailed, "Process recording rules") { dvr, _ ->
            dvr.processRecordingRules()
        }
        if (reached) recordings.reload()
    }

    /**
     * Runs [action] on every DVR at once, then says how it went: [success] when all took it, the admin requirement
     * when every failure was a 403, else [failure]. False when there is no DVR.
     */
    private suspend fun broadcastToDvrs(
        success: String,
        failure: String,
        what: String,
        action: suspend (LiveTvDvrSupport, LiveTvServerEntry) -> Unit,
    ): Boolean {
        val targets = servers.entries.mapNotNull { entry -> servers.client(entry.serverId)?.liveTvDvr?.let { it to entry } }
        if (targets.isEmpty()) return false
        val failures = coroutineScope {
            targets.map { (dvr, entry) ->
                async {
                    try {
                        action(dvr, entry)
                        null
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.w(TAG, e) { "$what failed for DVR ${entry.dvrKey}" }
                        e
                    }
                }
            }.awaitAll().filterNotNull()
        }
        message = when {
            failures.isEmpty() -> LiveTvMessage(success)
            failures.all { it is MediaServerHttpException && it.statusCode == 403 } -> LiveTvMessage(T.liveTv.dvrAdminRequired, isError = true)
            else -> LiveTvMessage(failure, isError = true)
        }
        publish()
        return true
    }

    // Favourites

    private suspend fun loadFavorites() {
        val generation = ++favoritesGeneration
        favoritesWritable = false
        val previousStores = storeBySource.toMap()
        val scopes = scopeByEntry.toMutableMap()
        val stores = HashMap(storeBySource)
        val merged = mutableListOf<FavoriteChannel>()
        val succeeded = HashSet<String>()
        val failed = HashSet<String>()
        val seen = HashSet<String>()

        // One entry per DVR: register every entry's scope, read each store once.
        servers.forEachLiveTvServer(
            dedupeByServerId = false,
            onError = { client, _, e ->
                val storeKey = client.liveTv.favoriteStoreKey
                if (storeKey !in succeeded) failed += storeKey
                Log.e(TAG, e) { "Failed to load favorite channels for $storeKey" }
            },
        ) { client, entry ->
            val liveTv = client.liveTv
            val storeKey = liveTv.favoriteStoreKey
            val source = liveTv.buildFavoriteChannelSource(entry.lineup)
            scopes[entryKey(entry)] = FavoriteScope(source, storeKey, liveTv.favoritePersistenceMode)
            stores[source] = storeKey
            if (storeKey in succeeded) return@forEachLiveTvServer
            val read = liveTv.fetchFavoriteChannels()
            succeeded += storeKey
            failed -= storeKey
            for (favorite in read) {
                stores[favorite.source] = storeKey
                if (seen.add(favorite.stableKey)) merged += favorite
            }
        }

        // A failed store keeps the favourites it had.
        for (favorite in favorites) {
            val storeKey = previousStores[favorite.source]
            if (storeKey != null && storeKey in failed && seen.add(favorite.stableKey)) merged += favorite
        }

        if (generation != favoritesGeneration) return
        scopeByEntry = scopes
        storeBySource.clear()
        storeBySource.putAll(stores)
        favorites = merged
        favoritesLoaded = failed.isEmpty() || succeeded.isNotEmpty() || merged.isNotEmpty()
        favoritesWritable = failed.isEmpty()
        publish()
    }

    private fun setFavoritesOnly(on: Boolean) {
        favoritesOnly = on
        publish()
    }

    /** Runs [mutation] after the favourites load in flight, one at a time, then saves the favourites. */
    private fun enqueueFavoriteMutation(mutation: () -> Unit) {
        val pendingLoad = favoritesLoad
        scope.launch {
            favoriteMutations.withLock {
                try {
                    pendingLoad?.join()
                    if (!favoritesWritable) {
                        message = LiveTvMessage(T.liveTv.favoritesLoadFailed, isError = true)
                        publish()
                        return@withLock
                    }
                    val before = favorites
                    mutation()
                    val after = favorites
                    publish()
                    try {
                        persistFavorites()
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        // A reload that landed meanwhile is newer than either list.
                        if (favorites === after) {
                            favorites = before
                            if (reorder != null) reorder = before
                        }
                        throw e
                    }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.e(TAG, e) { "Failed to update favorite channels" }
                    message = LiveTvMessage(T.liveTv.favoritesUpdateFailed, isError = true)
                    publish()
                }
            }
        }
    }

    /** Writes each store once: a shared store gets all its favourites, a per-server one only that server's. */
    private suspend fun persistFavorites() {
        val byStore = favorites.groupBy { storeBySource[it.source] }
        val written = HashSet<String>()
        val writes = mutableListOf<suspend () -> Unit>()
        for (entry in servers.entries) {
            val client = servers.client(entry.serverId) ?: continue
            val scope = scopeByEntry[entryKey(entry)] ?: continue
            if (!written.add(scope.storeKey)) continue
            val inStore = byStore[scope.storeKey].orEmpty()
            val list = when (scope.mode) {
                FavoriteChannelPersistenceMode.SHARED_FULL_LIST -> inStore
                FavoriteChannelPersistenceMode.SERVER_SLICE -> inStore.filter { it.source == scope.source }
            }
            writes += { client.liveTv.setFavoriteChannels(list) }
        }
        val failures = coroutineScope {
            writes.map { write ->
                async {
                    try {
                        write()
                        null
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        e
                    }
                }
            }.awaitAll().filterNotNull()
        }
        failures.firstOrNull()?.let { throw it }
    }

    private fun scopeFor(channel: LiveTvChannel): FavoriteScope? = entryByChannel[channel.scopeKey]?.let { scopeByEntry[it] }

    private fun sourceFor(channel: LiveTvChannel): String = channel.favoriteSource ?: scopeFor(channel)?.source.orEmpty()

    private fun isFavorite(channel: LiveTvChannel): Boolean = favoriteChannelKey(sourceFor(channel), channel.key) in favoriteKeys

    private fun displayedChannels(): List<LiveTvChannel> =
        filterLiveTvChannelsForFavorites(channels, favoritesOnly, favoritesLoaded, favorites, ::sourceFor)

    /** The guide shows [channel]'s row: the filter goes off when it isn't a favourite; the Guide tab is selected. */
    private fun showInGuide(channel: LiveTvChannel) {
        if (favoritesOnly && !isFavorite(channel)) favoritesOnly = false
        if (selectedTab != LiveTvTab.GUIDE) {
            selectedTab = LiveTvTab.GUIDE
            gateTabs()
        }
        publish()
    }

    // Search

    private suspend fun loadSearchPrograms(session: SearchSession, generation: Int) {
        val openedAt = now()
        // Jellyfin and Emby read `from` as the earliest start: an hour back keeps the airing on now.
        val from = openedAt - 1.hours
        val to = openedAt + SEARCH_WINDOW
        val fetched = mutableListOf<LiveTvProgram>()
        servers.forEachLiveTvServer(
            isCurrent = { generation == searchGeneration },
            onError = { _, entry, e -> Log.e(TAG, e) { "Guide search: failed to load programs from server ${entry.serverId.value}" } },
        ) { client, _ ->
            fetched += client.liveTv.fetchSchedule(from, to)
        }
        if (generation != searchGeneration) return
        val nowSeconds = openedAt.epochSeconds
        session.programs = fetched
            .filter { program -> program.endsAt.let { it == null || it > nowSeconds } }
            .mapNotNull { program -> session.channels.firstOrNull { liveTvProgramMatchesChannel(program, it) }?.let { SearchProgram(program, it) } }
            .sortedBy { it.program.beginsAt ?: 0 }
        session.loading = false
        publish()
    }

    private fun searchState(session: SearchSession): GuideSearchUiState {
        val query = session.query.trim()
        val lower = query.lowercase()
        val channels = if (lower.isEmpty()) {
            session.channels
        } else {
            session.channels.filter { channel ->
                listOf(channel.title, channel.callSign, channel.number).any { it?.lowercase()?.contains(lower) == true }
            }
        }
        val showsPrograms = query.length >= MIN_PROGRAM_QUERY
        val programs = if (!showsPrograms) {
            emptyList()
        } else {
            session.programs.asSequence()
                .filter { it.program.title.lowercase().contains(lower) || it.program.grandparentTitle?.lowercase()?.contains(lower) == true }
                .take(MAX_PROGRAM_RESULTS)
                .toList()
        }
        val nowSeconds = now().epochSeconds
        val hasResults = channels.isNotEmpty() || programs.isNotEmpty()
        return GuideSearchUiState(
            title = T.liveTv.searchGuide,
            hint = T.liveTv.searchHint,
            query = session.query,
            channelsLabel = T.liveTv.channelsSection,
            channels = channels.map { GuideSearchChannelRow(it, it.displayName, it.number?.let { number -> T.liveTv.channelNumber(number) }) },
            programsLabel = T.liveTv.programsSection,
            showsPrograms = showsPrograms && (programs.isNotEmpty() || session.loading),
            programsLoading = session.loading,
            programs = programs.map { (program, channel) ->
                val airTime = program.beginsAt?.let { "${liveTvRelativeDay(it, nowSeconds, utcOffset)} ${clockTime(it, use24HourClock, utcOffset)}" }
                GuideSearchProgramRow(channel, program, program.displayTitle, listOfNotNull(channel.displayName, airTime).joinToString(" · "))
            },
            noResults = if (!hasResults && !(showsPrograms && session.loading)) T.liveTv.searchNoResults(query) else null,
        )
    }

    // State

    private fun requestFocus(target: LiveTvFocusTarget) {
        focus = target
        publish()
    }

    private fun publish() {
        val displayed = displayedChannels()
        val state = buildState(displayed)
        val pushed = Triple(displayed, state.favoriteChannelKeys, favoritesOnly)
        if (pushed != pushedGuide) {
            pushedGuide = pushed
            guide.setChannels(pushed.first, groupLiveTvChannelsBySource(pushed.first), pushed.second)
        }
        mutableState.value = state
    }

    private fun buildState(displayed: List<LiveTvChannel> = displayedChannels()): LiveTvUiState {
        val showsFavoritesEmpty = channels.isNotEmpty() && displayed.isEmpty()
        val body = when {
            loading -> LiveTvBody.Loading
            error != null -> LiveTvBody.Failed(error!!, T.common.retry)
            channels.isEmpty() && LiveTvTab.RECORDINGS !in tabs -> LiveTvBody.Empty(T.liveTv.noChannels)
            else -> LiveTvBody.Tabs
        }
        return LiveTvUiState(
            title = T.liveTv.title,
            tabs = tabs.map { LiveTvTabUi(it, tabLabel(it)) },
            selectedTab = selectedTab,
            actions = actions(),
            body = body,
            guideEmpty = T.liveTv.noChannels.takeIf { channels.isEmpty() },
            favoritesEmpty = if (showsFavoritesEmpty) {
                LiveTvFavoritesEmptyUi(T.liveTv.noFavoriteChannels, T.liveTv.noFavoriteChannelsHint, T.liveTv.showAllChannels)
            } else {
                null
            },
            favoritesOnly = favoritesOnly,
            channels = channels,
            favoriteChannelKeys = channels.filter(::isFavorite).mapTo(HashSet()) { it.scopeKey },
            search = search?.let(::searchState),
            reorder = reorder?.let(::reorderState),
            message = message,
            focus = focus,
        )
    }

    private fun actions(): List<LiveTvActionUi> {
        val recordingsTab = selectedTab == LiveTvTab.RECORDINGS
        return listOfNotNull(
            LiveTvActionUi(LiveTvAction.SEARCH, T.liveTv.searchGuide),
            LiveTvActionUi(LiveTvAction.FAVORITES_FILTER, T.liveTv.favorites, active = favoritesOnly).takeIf { !recordingsTab },
            LiveTvActionUi(LiveTvAction.REORDER_FAVORITES, T.liveTv.reorderFavorites).takeIf { !recordingsTab && favoritesOnly && favorites.size > 1 },
            LiveTvActionUi(LiveTvAction.PROCESS_RULES, T.liveTv.processRecordingRules).takeIf { recordingsTab && canProcessRules },
            LiveTvActionUi(LiveTvAction.REFRESH, if (recordingsTab) T.common.refresh else T.liveTv.reloadGuide),
        )
    }

    private fun reorderState(list: List<FavoriteChannel>): ReorderFavoritesUiState {
        val byFavoriteKey = channels.associateBy { favoriteChannelKey(sourceFor(it), it.key) }
        return ReorderFavoritesUiState(
            title = T.liveTv.reorderFavorites,
            rows = list.map { favorite ->
                val channel = byFavoriteKey[favorite.stableKey]
                ReorderFavoriteRow(
                    key = favorite.stableKey,
                    title = channel?.displayName ?: favorite.title ?: favorite.id,
                    number = channel?.number ?: favorite.vcn,
                    thumb = channel?.thumb,
                    serverId = channel?.serverId,
                )
            },
        )
    }

    private fun tabLabel(tab: LiveTvTab): String = when (tab) {
        LiveTvTab.GUIDE -> T.liveTv.guide
        LiveTvTab.WHATS_ON -> T.liveTv.whatsOn
        LiveTvTab.RECORDINGS -> T.liveTv.scheduledRecordings
    }

    private fun entryKey(entry: LiveTvServerEntry): String = "${entry.serverId.value}\u0000${entry.dvrKey}"

    private class FavoriteScope(val source: String, val storeKey: String, val mode: FavoriteChannelPersistenceMode)

    private class SearchSession(val channels: List<LiveTvChannel>) {
        var query = ""
        var programs: List<SearchProgram> = emptyList()
        var loading = true
    }

    private data class SearchProgram(val program: LiveTvProgram, val channel: LiveTvChannel)

    private companion object {
        const val TAG = "LiveTv"
        const val UNNUMBERED = 999999.0
        const val MIN_PROGRAM_QUERY = 2
        const val MAX_PROGRAM_RESULTS = 30
        val SEARCH_WINDOW = 24.hours
    }
}
