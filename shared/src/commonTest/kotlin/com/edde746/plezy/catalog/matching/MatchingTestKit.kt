package com.edde746.plezy.catalog.matching

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.DataAggregationService
import com.edde746.plezy.servers.FakeOnlineServers
import com.edde746.plezy.servers.LibraryLookupResult
import com.edde746.plezy.servers.MultiServerState
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlin.time.TestTimeSource

internal fun ids(vararg values: String): Set<ServerId> = values.mapTo(LinkedHashSet()) { ServerId(it) }

/** A library copy as a reverse lookup returns it: no versions, no server name, so copies order by global key. */
internal fun libraryCopy(
    id: String,
    serverId: String? = null,
    kind: MediaKind = MediaKind.MOVIE,
    backend: BackendKind = BackendKind.PLEX,
    libraryId: String? = null,
    libraryTitle: String? = null,
) = MediaItem(id = id, backend = backend, kind = kind, libraryId = libraryId, libraryTitle = libraryTitle, serverId = serverId)

/** A lookup wave: by default no server is named in any outcome set. */
internal fun wave(
    items: List<MediaItem>,
    succeeded: Set<ServerId> = emptySet(),
    failed: Set<ServerId> = emptySet(),
    cancelled: Set<ServerId> = emptySet(),
    unqueried: Set<ServerId> = emptySet(),
) = LibraryLookupResult(items, succeededServerIds = succeeded, cancelledServerIds = cancelled, failedServerIds = failed, unqueriedServerIds = unqueried)

/** Canned waves, answered in order; every query is recorded. */
internal class ScriptedLookup : LibraryCopyLookup {
    val calls = mutableListOf<LibraryCopyQuery>()
    val responses = ArrayDeque<LibraryLookupResult>()

    override suspend fun find(query: LibraryCopyQuery): LibraryLookupResult {
        calls += query
        return responses.removeFirst()
    }
}

/** A matcher over [lookup] for a profile with no expected servers. */
internal fun TestScope.scriptedMatcher(lookup: ScriptedLookup, clock: TestTimeSource = TestTimeSource()) =
    CatalogLibraryMatcher(lookup, MutableStateFlow(MultiServerState()), backgroundScope, clock)

/** A server answering the reverse lookup with [copies] (null: it can't run the query), throwing [error], or waiting on [pending]. */
internal class LookupServer(
    id: String,
    var copies: List<MediaItem>? = emptyList(),
    var error: Throwable? = null,
    backend: BackendKind = BackendKind.PLEX,
) : FakeMediaBackend(id, backend) {
    var pending: CompletableDeferred<List<MediaItem>?>? = null
    var lookups = 0

    init {
        byExternalIds = { _, _, _, _, _, _ ->
            lookups++
            error?.let { throw it }
            val gate = pending
            if (gate != null) gate.await() else copies
        }
    }
}

/**
 * A matcher over the real [DataAggregationService]: only it tells a registered server that is offline (never asked)
 * from one that left the account. The profile's expected servers are the registered ones until [setExpected] names
 * them. The matcher follows every expected-server change as it happens.
 */
@OptIn(ExperimentalCoroutinesApi::class)
internal class LiveHarness(scope: TestScope, val clock: TestTimeSource = TestTimeSource()) {
    val servers = FakeOnlineServers()
    val state = MutableStateFlow(MultiServerState())
    private val registered = LinkedHashSet<ServerId>()
    private var expected: Set<ServerId>? = null
    private val followScope = CoroutineScope(scope.backgroundScope.coroutineContext + UnconfinedTestDispatcher(scope.testScheduler))

    val matcher: CatalogLibraryMatcher = newMatcher()

    /** Another matcher over the same servers, as a new profile session builds. */
    fun newMatcher() = CatalogLibraryMatcher(DataAggregationService(servers) { emptyMap() }.libraryCopyLookup(), state, followScope, clock)

    fun register(client: FakeMediaBackend, online: Boolean = true) {
        servers.register(client, online)
        registered += client.serverId
        publish()
    }

    /** The profile's expected servers; null falls back to the registered ones. */
    fun setExpected(serverIds: Set<ServerId>?) {
        expected = serverIds
        publish()
    }

    private fun publish() {
        state.value = MultiServerState(expectedServerIds = (expected ?: registered).toList())
    }
}
