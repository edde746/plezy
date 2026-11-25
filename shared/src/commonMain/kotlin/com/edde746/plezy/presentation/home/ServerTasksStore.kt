package com.edde746.plezy.presentation.home

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexActivity
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.cancelActivity
import com.edde746.plezy.plex.getActivities
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.MultiServerManager
import com.edde746.plezy.servers.MultiServerStore
import com.edde746.plezy.servers.NamedServer
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * The servers the Server Tasks panel asks for their running tasks: the online Plex servers (`/activities` is Plex's
 * alone), by name, as they change.
 */
interface ServerTaskServers {
    val servers: Flow<List<NamedServer>>

    /** [serverId]'s running tasks; throws when it can't say. */
    suspend fun activities(serverId: ServerId): List<PlexActivity>

    /** Cancels task [uuid] on [serverId]; throws when the server refuses. */
    suspend fun cancel(serverId: ServerId, uuid: String)
}

/** The product's [ServerTaskServers]: the profile's online servers with a Plex client. */
class PlexServerTasks(private val manager: MultiServerManager, store: MultiServerStore) : ServerTaskServers {
    override val servers: Flow<List<NamedServer>> = store.state.map { state ->
        state.onlineServerIds.filter { manager.client(it) is PlexClient }.map { NamedServer(it, manager.serverDisplayName(it)) }
    }

    override suspend fun activities(serverId: ServerId): List<PlexActivity> = client(serverId)?.getActivities().orEmpty()

    override suspend fun cancel(serverId: ServerId, uuid: String) {
        client(serverId)?.cancelActivity(uuid)
    }

    private fun client(serverId: ServerId): PlexClient? = manager.client(serverId) as? PlexClient
}

/** One server's running tasks in the panel, under its name. */
data class ServerTasksGroup(val serverId: String, val name: String, val tasks: List<PlexActivity>)

enum class ServerTasksLoad { LOADING, ERROR, CONTENT }

/**
 * The Server Tasks button and its panel: [shown] while a server can answer and the device isn't a phone or tablet;
 * [open] while the panel is. The panel says Loading…, Failed to load tasks, or lists the servers that run tasks
 * ([groups]; none: No tasks running).
 */
data class ServerTasksUiState(
    val shown: Boolean = false,
    val open: Boolean = false,
    val load: ServerTasksLoad = ServerTasksLoad.LOADING,
    val groups: List<ServerTasksGroup> = emptyList(),
)

/**
 * Home's Server Tasks: opening the panel loads every server's tasks at once, then again [POLL_MILLIS] after each answer,
 * silently (a failed poll keeps what shows and polls on), while the panel stays open; one load at a time, a newer one
 * (a cancel's refresh) replacing the one under way. Closing stops it, the request in flight too. A failed first load
 * says so and stops. Cancelling a task loads the panel again once the server took it. [formFactor] hides the button
 * on phones and tablets (Force TV mode shows it).
 */
class ServerTasksStore(
    private val source: ServerTaskServers,
    formFactor: Flow<FormFactor>,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(ServerTasksUiState())
    private var servers: List<NamedServer> = emptyList()
    private var load: Job? = null
    private var generation = 0

    val state: StateFlow<ServerTasksUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(source.servers, formFactor) { servers, form -> servers to (servers.isNotEmpty() && form != FormFactor.HANDHELD) }
                .distinctUntilChanged()
                .collect { (list, shown) ->
                    servers = list
                    if (!shown) close()
                    mutableState.update { it.copy(shown = shown) }
                }
        }
    }

    /** The button: opens the panel, or closes it. */
    fun toggle() {
        if (mutableState.value.open) close() else open()
    }

    /** Back, a tap outside, the button again, Home leaving. */
    fun close() {
        stopLoad()
        mutableState.update { it.copy(open = false, groups = emptyList(), load = ServerTasksLoad.LOADING) }
    }

    /** Cancels task [uuid] on [serverId], then loads the panel again. A refusal leaves the panel as it is. */
    fun cancel(serverId: String, uuid: String) {
        scope.launch {
            try {
                source.cancel(ServerId(serverId), uuid)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Cancelling $uuid on $serverId failed" }
                return@launch
            }
            if (mutableState.value.open) refresh()
        }
    }

    fun dispose() = scope.cancel()

    private fun open() {
        if (!mutableState.value.shown) return
        mutableState.update { it.copy(open = true) }
        refresh()
    }

    /** Loads now (showing Loading…), then polls until the panel closes or a newer load replaces this one. */
    private fun refresh() {
        stopLoad()
        val mine = generation
        mutableState.update { it.copy(load = ServerTasksLoad.LOADING, groups = emptyList()) }
        load = scope.launch {
            var silent = false
            while (true) {
                val groups = try {
                    fetch()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "Loading the server tasks failed" }
                    null
                }
                if (mine != generation) return@launch
                when {
                    groups != null -> mutableState.update { it.copy(load = ServerTasksLoad.CONTENT, groups = groups) }
                    !silent -> {
                        mutableState.update { it.copy(load = ServerTasksLoad.ERROR, groups = emptyList()) }
                        return@launch
                    }
                }
                delay(POLL_MILLIS)
                silent = true
            }
        }
    }

    private fun stopLoad() {
        generation++
        load?.cancel()
        load = null
    }

    private suspend fun fetch(): List<ServerTasksGroup> = coroutineScope {
        servers.map { server ->
            async { ServerTasksGroup(server.serverId.value, server.displayName, source.activities(server.serverId)) }
        }.awaitAll().filter { it.tasks.isNotEmpty() }
    }

    companion object {
        /** The pause between one answer and the next poll. */
        const val POLL_MILLIS = 3_000L
        private const val TAG = "ServerTasks"
    }
}
