package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.livetv.LiveTvDvr
import com.edde746.plezy.livetv.liveTvServerEntries
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * One Live TV source on a server: a Plex DVR ([dvrKey] its key, with its [lineup], and every DVR of the server in
 * [dvrs] for channel mappings), or a Jellyfin or Emby server's single channel list ([dvrKey] the backend's id).
 */
data class LiveTvServerEntry(
    val serverId: ServerId,
    val dvrKey: String,
    val lineup: String? = null,
    val dvrs: List<LiveTvDvr> = emptyList(),
)

/** A server and the name banners show for it (the server id when it has none). */
data class NamedServer(val serverId: ServerId, val displayName: String)

/**
 * The servers as the active profile sees them. Server lists are filtered by the profile's visibility filter; the
 * refusal lists by the profile's expected servers (else the visibility filter).
 *
 * @param visibleServerIds the profile's visibility filter; null: every server is visible. An empty set is a filter: the
 *   profile has servers, none of them visible.
 * @param expectedServerIds the servers the profile should have, unreachable ones included; the visible servers when
 *   the profile named none.
 * @param authErrorServers servers that rejected the token (401): the "Sign in again" banner.
 * @param accessDeniedServers servers that refuse the account (403): no sign-in is offered.
 * @param liveTvChecked every visible online server has been asked whether it has Live TV ([liveTvServers] is whole).
 */
data class MultiServerState(
    val serverIds: List<ServerId> = emptyList(),
    val onlineServerIds: List<ServerId> = emptyList(),
    val expectedServerIds: List<ServerId> = emptyList(),
    val visibleServerIds: Set<ServerId>? = null,
    val authErrorServers: List<NamedServer> = emptyList(),
    val accessDeniedServers: List<NamedServer> = emptyList(),
    val refusedServerIds: List<ServerId> = emptyList(),
    val hasOnlinePlexServers: Boolean = false,
    val liveTvServers: List<LiveTvServerEntry> = emptyList(),
    val liveTvChecked: Boolean = true,
) {
    val hasExplicitVisibleServerFilter: Boolean get() = visibleServerIds != null
    val onlineServerCount: Int get() = onlineServerIds.size
    val totalServerCount: Int get() = serverIds.size
    val hasConnectedServers: Boolean get() = onlineServerIds.isNotEmpty()
    val hasLiveTv: Boolean get() = liveTvServers.isNotEmpty()
    val authErrorServerIds: List<ServerId> get() = authErrorServers.map { it.serverId }
    val accessDeniedServerIds: List<ServerId> get() = accessDeniedServers.map { it.serverId }

    /** Online and visible to the profile. */
    fun isServerOnline(serverId: ServerId): Boolean = serverId in onlineServerIds
}

/**
 * The active profile's view of [manager]: its visibility filter and expected servers, the online and refused servers
 * it sees, and which of them offer Live TV.
 *
 * After each manager status snapshot, expected servers that came online join the visibility filter, [state] updates,
 * [onlineServersChanges] emits the visible online set (every time: each collector decides what is new to it), and Live
 * TV is checked again when a server came online that was not before, or when an online server answers through another
 * client or authentication session than the last check asked (a new client, an in-place profile switch): Live TV access
 * is per user.
 *
 * [liveTvAvailability] answers for one client (Plex: one entry per DVR; Jellyfin and Emby: one entry when Live TV is
 * available; empty: none) and throws the request's failure.
 */
class MultiServerStore(
    private val manager: MultiServerManager,
    private val liveTvAvailability: suspend (MediaBackend) -> List<LiveTvServerEntry> = ::liveTvServerEntries,
    scope: CoroutineScope,
) {
    private val storeScope = scope.childScope()

    private var expectedVisibleServerIds: Set<ServerId>? = null
    private var liveTvServers: List<LiveTvServerEntry> = emptyList()

    // The servers the last finished Live TV check asked.
    private var liveTvCheckedIds: Set<ServerId> = emptySet()

    // The client, and its authentication session at probe time, that the last check asked on each server, whatever the
    // answer; each server's Live TV entries come from that probe. A failed re-probe may keep the entries only on that
    // same client and session.
    private var liveTvProbes: Map<ServerId, LiveTvProbe> = emptyMap()
    private var previousOnline: Set<ServerId> = emptySet()
    private var liveTvGeneration = 0
    private var disposed = false

    private val mutableState = MutableStateFlow(snapshot())
    val state: StateFlow<MultiServerState> = mutableState.asStateFlow()

    private val onlineServers = MutableSharedFlow<Set<ServerId>>(extraBufferCapacity = Int.MAX_VALUE)

    /** The visible online servers after each manager status snapshot. */
    val onlineServersChanges: SharedFlow<Set<ServerId>> = onlineServers.asSharedFlow()

    init {
        storeScope.launch(start = CoroutineStart.UNDISPATCHED) {
            manager.statusUpdates.collect { onStatus() }
        }
    }

    /** The state computed from the manager now, ahead of [state]'s next update. */
    fun snapshot(): MultiServerState {
        val visibleFilter = manager.visibleServerIds
        val expected = expectedVisibleServerIds
        val serverIds = manager.serverIds.filter { manager.isServerVisible(it) }
        val online = visibleOnlineServerIds()
        val refusalFilter = expected ?: visibleFilter
        fun filtered(ids: Set<ServerId>): List<ServerId> = if (refusalFilter == null) ids.toList() else ids.filter { it in refusalFilter }
        fun named(ids: List<ServerId>): List<NamedServer> = ids.map { NamedServer(it, manager.serverDisplayName(it)) }
        return MultiServerState(
            serverIds = serverIds,
            onlineServerIds = online,
            expectedServerIds = expected?.toList() ?: serverIds,
            visibleServerIds = visibleFilter,
            authErrorServers = named(filtered(manager.authErrorServerIds)),
            accessDeniedServers = named(filtered(manager.accessDeniedServerIds)),
            refusedServerIds = filtered(manager.refusedServerIds),
            hasOnlinePlexServers = online.any { manager.client(it) is PlexServerClient },
            liveTvServers = liveTvServers,
            liveTvChecked = liveTvCheckedIds.containsAll(online),
        )
    }

    fun client(serverId: ServerId): MediaBackend? = manager.client(serverId)

    /** Replaces the visibility filter (null: all visible). Live TV outside it goes at once; a re-check follows. */
    fun setVisibleServerIds(ids: Set<ServerId>?) {
        if (manager.visibleServerIds == ids) return
        manager.setVisibleServerIds(ids)
        pruneLiveTvForVisibility()
        publish()
        refreshLiveTvSoon()
    }

    /** Replaces the servers the profile should have (null: fall back to the visible ones). */
    fun setExpectedVisibleServerIds(ids: Set<ServerId>?) {
        if (expectedVisibleServerIds == ids) return
        expectedVisibleServerIds = ids?.toSet()
        publish()
    }

    /**
     * Asks every visible online server whether it offers Live TV. A newer check discards an older one's answer. A
     * transient failure (a timeout, a connection error, a 5xx) keeps the entries the last check found on the same client
     * and authentication session; any other failure drops them. An answer obtained across a session change (an
     * in-place profile switch) belongs to the previous profile and is dropped.
     */
    suspend fun checkLiveTvAvailability() {
        if (disposed) return
        val generation = ++liveTvGeneration
        val found = mutableListOf<LiveTvServerEntry>()
        val probes = HashMap<ServerId, LiveTvProbe>()
        val asked = visibleOnlineServerIds()
        for (serverId in asked) {
            val client = manager.client(serverId) ?: continue
            val probe = LiveTvProbe(client, client.authenticationSessionId)
            probes[serverId] = probe
            try {
                val entries = liveTvAvailability(client)
                if (client.authenticationSessionId !== probe.authentication) continue
                found += entries
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Live TV check failed for $serverId" }
                val previous = liveTvProbes[serverId]
                if (isTransientLiveTvFailure(e) &&
                    client.authenticationSessionId === probe.authentication &&
                    previous != null &&
                    previous.client === client &&
                    previous.authentication === probe.authentication
                ) {
                    found += liveTvServers.filter { it.serverId == serverId }
                }
            }
        }
        if (disposed || generation != liveTvGeneration) return
        liveTvServers = found.filter { manager.isServerVisible(it.serverId) }
        liveTvProbes = probes
        liveTvCheckedIds = asked.toSet()
        publish()
    }

    /** Stops following the manager and discards Live TV checks in flight. */
    fun dispose() {
        disposed = true
        liveTvGeneration++
        storeScope.cancel()
    }

    private fun onStatus() {
        promoteOnlineExpectedServers()
        val currentOnline = visibleOnlineServerIds().toSet()
        val hasNewServer = currentOnline.any { it !in previousOnline }
        previousOnline = currentOnline
        publish()
        onlineServers.tryEmit(currentOnline)
        if (hasNewServer || currentOnline.any(::isLiveTvProbeOutdated)) storeScope.launch { checkLiveTvAvailability() }
    }

    private fun isLiveTvProbeOutdated(serverId: ServerId): Boolean {
        val client = manager.client(serverId) ?: return false
        val probe = liveTvProbes[serverId] ?: return true
        return probe.client !== client || probe.authentication !== client.authenticationSessionId
    }

    private fun promoteOnlineExpectedServers() {
        val visible = manager.visibleServerIds ?: return
        val expected = expectedVisibleServerIds
        if (expected.isNullOrEmpty()) return
        val onlineExpected = manager.onlineServerIds.filter { it in expected && it !in visible }
        if (onlineExpected.isEmpty()) return
        manager.setVisibleServerIds(visible + onlineExpected)
    }

    private fun visibleOnlineServerIds(): List<ServerId> = manager.onlineServerIds.filter { manager.isServerVisible(it) }

    private fun pruneLiveTvForVisibility() {
        if (manager.visibleServerIds == null) return
        liveTvServers = liveTvServers.filter { manager.isServerVisible(it.serverId) }
    }

    private fun refreshLiveTvSoon() {
        storeScope.launch { checkLiveTvAvailability() }
    }

    private fun publish() {
        if (!disposed) mutableState.value = snapshot()
    }

    private class LiveTvProbe(val client: MediaBackend, val authentication: Any)

    private companion object {
        const val TAG = "MultiServerStore"

        fun isTransientLiveTvFailure(error: Exception): Boolean {
            if (error !is MediaServerHttpException || error.isCancellation) return false
            val status = error.statusCode
            if (status == 401 || status == 403) return false
            return error.isTransient || (status != null && status >= 500)
        }
    }
}
