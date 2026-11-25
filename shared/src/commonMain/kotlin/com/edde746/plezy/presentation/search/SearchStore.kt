package com.edde746.plezy.presentation.search

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPerson
import com.edde746.plezy.model.PersonCredit
import com.edde746.plezy.model.SearchHit
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.mergeFetchedMediaItem
import com.edde746.plezy.model.rankMediaSearchResults
import com.edde746.plezy.model.rankPeopleSearchResults
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.metadata.EditedItem
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.SearchAggregationResult
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** A kind filter chip: All, a media kind, or People. */
sealed interface SearchFilter {
    data object All : SearchFilter

    data class Kind(val kind: MediaKind) : SearchFilter

    data object People : SearchFilter

    val label: String
        get() = when (this) {
            All -> T.libraries.groupings.all
            People -> T.search.people
            is Kind -> kindLabel(kind)
        }
}

/** One result row. */
sealed interface SearchResultUi {
    val key: String

    /**
     * A title, drawn as a list card; selecting it ([SearchStore.open]) does what selecting the title does anywhere.
     * [source] names where it lives ("Server • Library") when that tells copies apart, after [backend]'s mark. [label]
     * is what a screen reader says for it: the card's title, and for an episode or a season, titled by its show, its
     * caption too ("Maestro Show, S1 E2 · Episode 2"), so it never sounds like the show.
     */
    data class Media(
        val card: MediaCardUi,
        val source: String?,
        val backend: BackendKind,
        val label: String,
    ) : SearchResultUi {
        override val key: String get() = card.id
    }

    /** An actor or director; selecting opens their titles on their server. [source] names that server after [backend]'s mark. */
    data class Person(
        override val key: String,
        val name: String,
        /** "Actor" or "Director". */
        val credit: String?,
        val image: Artwork?,
        val source: String?,
        val backend: BackendKind,
        val route: Route.Person,
    ) : SearchResultUi
}

/**
 * A run of results under one heading. Under All, when the results span several kinds, one per kind ([title] its chip's
 * label: "Movies", "People"), the kinds in their chips' order and each kind's results in rank order; else a single
 * untitled group.
 */
data class SearchResultGroup(val title: String?, val results: List<SearchResultUi>)

/** Where the search screen stands. */
enum class SearchPhase { IDLE, SEARCHING, RESULTS, EMPTY, FAILED }

/**
 * @param sessionExpired while the search [SearchPhase.FAILED] and a server's sign-in has expired, the sentence naming
 *   that server (or listing several): the screen says so and offers Sign in again rather than Retry; else null.
 */
data class SearchUiState(
    val query: String,
    val phase: SearchPhase,
    /** The chips, All first; empty when the results span a single kind. */
    val filters: List<SearchFilter>,
    val filter: SearchFilter,
    /** The results, in their groups; none before a search lands. */
    val groups: List<SearchResultGroup>,
    /** A search is running for the query on screen (the spinner over results that may be shown). */
    val searching: Boolean,
    val sessionExpired: String? = null,
) {
    /** Every group's results in the order shown. */
    val results: List<SearchResultUi> = groups.flatMap { it.results }
}

/** What the search store reads outside itself. */
class SearchDeps(
    val search: suspend (query: String, hiddenLibraryKeys: Set<String>) -> SearchAggregationResult,
    /** Hydrates the hidden libraries before the first search. */
    val hiddenLibrariesReady: suspend () -> Unit,
    val hiddenLibraryKeys: () -> Set<String>,
    val hiddenLibraryChanges: Flow<Set<String>>,
    val client: (ServerId) -> MediaBackend?,
    /** Servers the profile sees, online or not: rows name their server only when there are several. */
    val serverCount: () -> Int,
    /** The library a title's row names: null on a server of one library; the loaded library's name when the title has only its id. */
    val libraryLabel: (MediaItem) -> String?,
    val cardOptions: () -> CardOptions,
    /** Selects a title as everywhere else: plays it, or opens its detail or its music screen. */
    val open: (MediaItem) -> Unit,
    /** Opens a title's menu. */
    val menu: (MediaItem) -> Unit,
    /** Watch-state changes: a shown title they touch (other than its progress) is fetched again from its server. */
    val watchStates: Flow<WatchStateEvent>,
    /** Titles whose metadata was edited: a shown one is fetched again from its server. */
    val edited: Flow<EditedItem> = emptyFlow(),
    /** A title fetched from its own server, null when it has none. */
    val fetchItem: suspend (ServerId, String) -> MediaItem?,
    /** The names of the servers the profile sees that refused its sign-in (the session expired), as they change. */
    val sessionExpired: Flow<List<String>> = flowOf(emptyList()),
    val debounce: Duration = 500.milliseconds,
)

/**
 * Search across the servers ([Route.Search]): searches [SearchDeps.debounce] after the text stops changing, ranks
 * titles and people on one scale ([com.edde746.plezy.model.rankSearchHits]), groups them by kind under All
 * ([SearchResultGroup]) and filters them by kind. A later query
 * cancels the one in flight and an older answer never lands. A shown title whose watch state or metadata changes is
 * fetched again from its server, in place, without searching again. Main thread only; [close] when the screen goes.
 */
class SearchStore(private val deps: SearchDeps, parentScope: CoroutineScope) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(SearchUiState("", SearchPhase.IDLE, emptyList(), SearchFilter.All, emptyList(), false))
    val state: StateFlow<SearchUiState> = mutableState.asStateFlow()

    private val mutableMessages = MutableSharedFlow<String>(extraBufferCapacity = 4, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    /** Snackbars: a partial or failed search. */
    val messages: SharedFlow<String> = mutableMessages.asSharedFlow()

    private val mutableLanded = MutableSharedFlow<Unit>(extraBufferCapacity = 1, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    /** A submitted search's results landed: the UI moves focus to the first result. */
    val focusFirstResult: SharedFlow<Unit> = mutableLanded.asSharedFlow()

    private val fieldFocus = Channel<Unit>(Channel.CONFLATED)

    /**
     * The search field asked for focus ([focusField]): the UI focuses it once its screen is composed. A request made
     * before the screen shows waits for it.
     */
    val fieldFocusRequests: Flow<Unit> = fieldFocus.receiveAsFlow()

    /** Focuses the search field (Ctrl or Cmd+F): now, or as the screen shows ([fieldFocusRequests]). */
    fun focusField() {
        fieldFocus.trySend(Unit)
    }

    private var text = ""
    private var lastSearched: String? = null
    private var inFlightQuery: String? = null
    private var generation = 0
    private var debounceJob: Job? = null
    private var searchJob: Job? = null
    /** The submitted query whose results take focus when they land; null when none is waiting. */
    private var focusQuery: String? = null
    private var result: SearchAggregationResult? = null
    private var hiddenWatch: Job? = null

    /** The sentence for the servers whose sign-in has expired ([SearchDeps.sessionExpired]); null while none has. */
    private var expired: String? = null

    init {
        scope.launch { deps.watchStates.collect(::onWatchState) }
        scope.launch { deps.edited.collect { edit -> refetch(edit.serverId) { it.id == edit.itemId } } }
        scope.launch {
            deps.sessionExpired.collect {
                expired = sessionExpiredMessage(it)
                val current = mutableState.value
                if (current.phase == SearchPhase.FAILED) mutableState.value = current.copy(sessionExpired = expired)
            }
        }
    }

    /** The field's text changed; the search runs once it rests. */
    fun setQuery(value: String) {
        if (value == text) return
        text = value
        val query = value.trim()
        if (query.isEmpty()) return clear()
        // Text moving off a submitted query drops its focus: the results of what is typed now were not asked for.
        if (focusQuery != query) focusQuery = null
        // Text diverging from the running search invalidates it.
        if (inFlightQuery != null && inFlightQuery != query) cancelSearch()
        debounceJob?.cancel()
        if (query == lastSearched && inFlightQuery == null) {
            publish(searching = false)
            return
        }
        if (query == inFlightQuery) {
            publish(searching = true)
            return
        }
        publish(searching = mutableState.value.searching)
        debounceJob = scope.launch {
            delay(deps.debounce)
            run(query)
        }
    }

    /**
     * The keyboard's Search (TV): the results shown for this text get focus; with none shown (none yet, none found, the
     * search failed) it searches now and focuses them when they land.
     */
    fun submit() {
        val query = text.trim()
        if (query.isEmpty()) return
        if (query == lastSearched && inFlightQuery == null && mutableState.value.results.isNotEmpty()) {
            mutableLanded.tryEmit(Unit)
            return
        }
        focusQuery = query
        debounceJob?.cancel()
        if (inFlightQuery != query) run(query)
    }

    /** Runs the query on screen again (Ctrl/Cmd+R). */
    fun refresh() {
        val query = text.trim()
        if (query.isNotEmpty()) {
            debounceJob?.cancel()
            run(query)
        }
    }

    fun clear() {
        text = ""
        debounceJob?.cancel()
        cancelSearch()
        generation++
        lastSearched = null
        focusQuery = null
        result = null
        mutableState.value = SearchUiState("", SearchPhase.IDLE, emptyList(), SearchFilter.All, emptyList(), false)
    }

    /** Selects the title of row [key] as selecting it does anywhere else. */
    fun open(key: String) {
        item(key)?.let(deps.open)
    }

    /** Opens the menu of the title of row [key]. */
    fun menu(key: String) {
        item(key)?.let(deps.menu)
    }

    private fun item(key: String): MediaItem? = result?.candidates?.firstOrNull { it.globalKey == key }
        ?: result?.hits?.firstNotNullOfOrNull { (it as? SearchHit.Media)?.item?.takeIf { item -> item.globalKey == key } }

    fun selectFilter(filter: SearchFilter) {
        if (filter !in mutableState.value.filters) return
        mutableState.value = mutableState.value.copy(filter = filter)
        publish(searching = mutableState.value.searching)
    }

    fun close() = scope.cancel()

    private fun cancelSearch() {
        searchJob?.cancel()
        searchJob = null
        inFlightQuery = null
    }

    private fun run(query: String) {
        cancelSearch()
        val runGeneration = ++generation
        inFlightQuery = query
        publish(searching = true)
        searchJob = scope.launch {
            deps.hiddenLibrariesReady()
            watchHiddenLibraries()
            val answer = try {
                deps.search(query, deps.hiddenLibraryKeys())
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (runGeneration != generation) return@launch
                Log.w(TAG, e) { "search failed" }
                inFlightQuery = null
                lastSearched = query
                fail(T.errors.searchFailed(localizedErrorReason(e)))
                return@launch
            }
            if (runGeneration != generation) return@launch
            inFlightQuery = null
            land(query, answer)
        }
    }

    private fun land(query: String, answer: SearchAggregationResult) {
        val succeeded = answer.succeededServerIds.isNotEmpty()
        if (!succeeded && answer.failedServerIds.isEmpty() && answer.cancelledServerIds.isNotEmpty()) {
            // Every server cancelled: nothing failed, the earlier results stay.
            focusQuery = null
            publish(searching = false)
            return
        }
        lastSearched = query
        if (!succeeded) {
            fail(T.errors.searchUnavailable)
            return
        }
        if (answer.failedServerIds.isNotEmpty()) mutableMessages.tryEmit(T.messages.searchPartialResults)
        result = answer
        publish(searching = false)
        if (focusQuery == query) {
            focusQuery = null
            if (query == text.trim() && mutableState.value.results.isNotEmpty()) mutableLanded.tryEmit(Unit)
        }
    }

    /**
     * The search failed: no results, and [message] as a snackbar, unless a server's session has expired, which the
     * screen itself says ([SearchUiState.sessionExpired]).
     */
    private fun fail(message: String) {
        focusQuery = null
        result = null
        mutableState.value = mutableState.value.copy(phase = SearchPhase.FAILED, groups = emptyList(), filters = emptyList(), searching = false, sessionExpired = expired)
        if (expired == null) mutableMessages.tryEmit(message)
    }

    /** A shown title a menu action changed: fetched again from its own server and put in its place. */
    private suspend fun onWatchState(event: WatchStateEvent) {
        if (event.changeType == WatchStateChangeType.PROGRESS_UPDATE) return
        refetch(event.serverId) { event.affectsItem(it.id) }
    }

    private suspend fun refetch(serverId: ServerId, affects: (MediaItem) -> Boolean) {
        val shown = result ?: return
        val touched = shown.candidates.filter { it.serverId == serverId.value && affects(it) }
        for (stale in touched) {
            val fetched = try {
                deps.fetchItem(serverId, stale.id)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Refreshing ${stale.globalKey} failed" }
                null
            } ?: continue
            replace(stale.globalKey, mergeFetchedMediaItem(fetched, serverId, stale))
        }
    }

    /** Puts [fresh] in place of the title [key] in the ranked list and the pool the chips filter, keeping their order. */
    private fun replace(key: String, fresh: MediaItem) {
        val shown = result ?: return
        if (shown.candidates.none { it.globalKey == key }) return
        result = shown.copy(
            hits = shown.hits.map { if (it is SearchHit.Media && it.item.globalKey == key) SearchHit.Media(fresh) else it },
            candidates = shown.candidates.map { if (it.globalKey == key) fresh else it },
        )
        publish(searching = mutableState.value.searching)
    }

    private fun watchHiddenLibraries() {
        if (hiddenWatch != null) return
        hiddenWatch = scope.launch {
            deps.hiddenLibraryChanges.distinctUntilChanged().drop(1).collect {
                val inFlight = inFlightQuery
                if (inFlight != null) run(inFlight) else if (lastSearched != null && text.isNotBlank()) refresh()
            }
        }
    }

    private fun publish(searching: Boolean) {
        val answer = result
        val query = lastSearched ?: text.trim()
        val filters = answer?.let(::filtersOf).orEmpty()
        val filter = mutableState.value.filter.takeIf { it in filters } ?: SearchFilter.All
        val hits: List<SearchHit> = when {
            answer == null -> emptyList()
            filter is SearchFilter.Kind -> rankMediaSearchResults(answer.candidates.filter { it.kind == filter.kind }, query, LIMIT).map { SearchHit.Media(it) }
            filter == SearchFilter.People -> rankPeopleSearchResults(answer.people, query, LIMIT).map { SearchHit.Person(it) }
            else -> answer.hits
        }
        val groups = when {
            hits.isEmpty() -> emptyList()
            filter == SearchFilter.All -> groupsOf(hits, filters)
            else -> listOf(SearchResultGroup(null, hits.map(::row)))
        }
        val phase = when {
            searching && groups.isEmpty() -> SearchPhase.SEARCHING
            answer == null && mutableState.value.phase == SearchPhase.FAILED && !searching -> SearchPhase.FAILED
            answer == null -> if (searching) SearchPhase.SEARCHING else SearchPhase.IDLE
            groups.isEmpty() -> SearchPhase.EMPTY
            else -> SearchPhase.RESULTS
        }
        mutableState.value = SearchUiState(text, phase, filters, filter, groups, searching, sessionExpired = expired.takeIf { phase == SearchPhase.FAILED })
    }

    /** All's ranked [hits] by kind, the kinds in [filters]' order; one untitled group when they span one kind. */
    private fun groupsOf(hits: List<SearchHit>, filters: List<SearchFilter>): List<SearchResultGroup> {
        val byKind = hits.groupBy { if (it is SearchHit.Media) SearchFilter.Kind(it.item.kind) else SearchFilter.People }
        if (byKind.size == 1) return listOf(SearchResultGroup(null, hits.map(::row)))
        return byKind.entries.sortedBy { filters.indexOf(it.key) }.map { (kind, kindHits) -> SearchResultGroup(kind.label, kindHits.map(::row)) }
    }

    private fun filtersOf(answer: SearchAggregationResult): List<SearchFilter> {
        val kinds = answer.candidates.mapTo(HashSet()) { it.kind }
        val present = KIND_ORDER.filter { it in kinds }.map { SearchFilter.Kind(it) }
        val people = answer.people.isNotEmpty()
        if (present.size + (if (people) 1 else 0) <= 1) return emptyList()
        return listOf(SearchFilter.All) + present + listOfNotNull(SearchFilter.People.takeIf { people })
    }

    private fun row(hit: SearchHit): SearchResultUi = when (hit) {
        is SearchHit.Media -> mediaRow(hit.item)
        is SearchHit.Person -> personRow(hit.person)
    }

    private fun mediaRow(item: MediaItem): SearchResultUi.Media {
        val serverId = ServerId.tryParse(item.serverId)
        val client = serverId?.let(deps.client)
        val library = deps.libraryLabel(item)
        // A named library always names its server too; without one, only a profile of several servers does.
        val server = if (library != null || deps.serverCount() > 1) item.serverName ?: client?.serverName else null
        val parts = listOfNotNull(server, library)
        val card = item.toCardUi(client, deps.cardOptions())
        val titledByShow = item.kind == MediaKind.EPISODE || item.kind == MediaKind.SEASON
        return SearchResultUi.Media(
            card = card,
            source = parts.takeIf { it.isNotEmpty() }?.joinToString(SOURCE_SEPARATOR),
            backend = item.backend,
            label = listOfNotNull(card.title, card.caption.takeIf { titledByShow }).joinToString(", "),
        )
    }

    private fun personRow(person: MediaPerson): SearchResultUi.Person {
        val client = deps.client(person.serverId)
        return SearchResultUi.Person(
            key = person.globalKey,
            name = person.name,
            credit = when (person.credit) {
                PersonCredit.ACTOR -> T.explore.creditRole.actor
                PersonCredit.DIRECTOR -> T.explore.creditRole.director
                null -> null
            },
            image = Artwork.of(client, person.thumbPath, ImageKind.AVATAR),
            source = if (deps.serverCount() > 1) person.serverName ?: client?.serverName else null,
            backend = person.backend,
            route = Route.Person(person.serverId, person.id, person.name, person.thumbPath),
        )
    }

    private companion object {
        const val TAG = "Search"
        const val LIMIT = 100
        const val SOURCE_SEPARATOR = " • "
        val KIND_ORDER = listOf(
            MediaKind.MOVIE, MediaKind.SHOW, MediaKind.SEASON, MediaKind.EPISODE, MediaKind.ARTIST,
            MediaKind.ALBUM, MediaKind.TRACK, MediaKind.COLLECTION, MediaKind.PLAYLIST,
        )
    }
}

/** Where selecting [item] goes: a collection's grid, else its detail seeded with [item]. */
internal fun itemRoute(item: MediaItem, server: ServerId): Route {
    return when (item.kind) {
        MediaKind.COLLECTION -> Route.CollectionDetail(server, item.id)
        else -> Route.MediaDetail(server, item.id).seeded(item)
    }
}

private fun kindLabel(kind: MediaKind): String = when (kind) {
    MediaKind.MOVIE -> T.libraries.groupings.movies
    MediaKind.SHOW -> T.libraries.groupings.shows
    MediaKind.SEASON -> T.libraries.groupings.seasons
    MediaKind.EPISODE -> T.libraries.groupings.episodes
    MediaKind.ARTIST -> T.libraries.groupings.artists
    MediaKind.ALBUM -> T.libraries.groupings.albums
    MediaKind.TRACK -> T.libraries.groupings.tracks
    MediaKind.COLLECTION -> T.libraries.tabs.collections
    MediaKind.PLAYLIST -> T.libraries.tabs.playlists
    else -> kind.id
}

/** The expired-session sentence naming [servers] (their names, in order); null when there are none. */
internal fun sessionExpiredMessage(servers: List<String>): String? = when (servers.size) {
    0 -> null
    1 -> T.search.sessionExpiredMessageOne(servers.single())
    else -> T.search.sessionExpiredMessageMany(servers.joinToString(", "))
}
