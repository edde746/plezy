package com.edde746.plezy.servers

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch

/** Something that knows whether the app is offline; services depend on this, not on [OfflineModeStore]. */
interface OfflineModeSource {
    val isOffline: StateFlow<Boolean>
}

enum class OfflineModeReason {
    ONLINE,

    /**
     * The first connect pass has not settled, or a bind of the profile's servers that started while the app was online
     * is still connecting them: the app is treated as online meanwhile.
     */
    WAITING_FOR_SERVER_STATUS,

    NO_KNOWN_VISIBLE_SERVERS,

    /**
     * Every server the profile should have answered and refuses the account (a rejected token or a refused account):
     * reachable, so not offline; the refusal banner explains the empty app.
     */
    ONLY_REFUSED_SERVERS,

    NO_SERVER_CONNECTION,
}

/**
 * Offline mode and the device's connectivity. [isOffline] holds only for [OfflineModeReason.NO_SERVER_CONNECTION].
 * The OS connectivity is not part of it: "no network" means no internet-capable adapter, not no route to the
 * server, and a server on loopback or on a LAN without internet stays reachable. [connectivity] still serves the
 * consumers that need the internet or the link type.
 */
data class OfflineModeState(val reason: OfflineModeReason, val connectivity: Connectivity) {
    val isOffline: Boolean get() = reason == OfflineModeReason.NO_SERVER_CONNECTION
    val hasWifiOrEthernet: Boolean get() = connectivity.hasWifiOrEthernet
    val isCellularOnly: Boolean get() = connectivity.isCellularOnly
}

/**
 * Whether the app is offline: no server the active profile sees ([servers]; [manager]'s servers when there is no
 * profile view) is reachable. Until the manager's first status snapshot after [initialize] (or a server already online,
 * or a settled profile visibility filter) the app counts as online, so a cold start does not flash the offline UI.
 * Connecting is not offline either: while a bind of the profile's servers runs ([binding]) that started with the app
 * online (a sign-in, a profile switch), the app counts as online until a server connects or the bind settles without
 * one. A bind that starts offline (Reconnect) leaves it offline.
 *
 * Holds the app's one connectivity subscription ([connectivityProbe]).
 */
class OfflineModeStore(
    private val manager: MultiServerManager,
    private val servers: MultiServerStore?,
    private val connectivityProbe: ConnectivityProbe,
    binding: Flow<Boolean>,
    scope: CoroutineScope,
) : OfflineModeSource {
    private val storeScope = scope.childScope()
    private var statusKnown = false
    private var initialized = false
    private var connectivity = Connectivity.NOT_REPORTED

    // A bind that started while the app was online is running: its servers are being connected.
    private var connecting = false

    private val mutableState: MutableStateFlow<OfflineModeState>
    val state: StateFlow<OfflineModeState>

    private val mutableIsOffline: MutableStateFlow<Boolean>
    override val isOffline: StateFlow<Boolean>

    init {
        val profile = servers?.snapshot()
        markStatusKnownIfSettled(profile)
        val initial = OfflineModeState(reason(profile), connectivity)
        mutableState = MutableStateFlow(initial)
        state = mutableState.asStateFlow()
        mutableIsOffline = MutableStateFlow(initial.isOffline)
        isOffline = mutableIsOffline.asStateFlow()
        if (servers != null) {
            storeScope.launch(start = CoroutineStart.UNDISPATCHED) {
                servers.state.collect {
                    val current = servers.snapshot()
                    markStatusKnownIfSettled(current)
                    publish(current)
                }
            }
        }
        storeScope.launch(start = CoroutineStart.UNDISPATCHED) {
            binding.distinctUntilChanged().collect { running ->
                // Read as the bind starts, before its servers move the state.
                connecting = running && !mutableState.value.isOffline
                publish(servers?.snapshot())
            }
        }
    }

    /** Reads the connectivity, then follows its changes and the manager's status snapshots. Once. */
    suspend fun initialize() {
        if (initialized) return
        initialized = true
        connectivity = connectivityProbe.check()
        storeScope.launch(start = CoroutineStart.UNDISPATCHED) {
            connectivityProbe.changes.collect {
                connectivity = it
                publish(servers?.snapshot())
            }
        }
        storeScope.launch(start = CoroutineStart.UNDISPATCHED) {
            manager.statusUpdates.collect {
                statusKnown = true
                publish(servers?.snapshot())
            }
        }
        publish(servers?.snapshot())
    }

    /** Stops following everything; the state stays as it was. */
    fun dispose() {
        storeScope.cancel()
    }

    private fun publish(profile: MultiServerState?) {
        val next = OfflineModeState(reason(profile), connectivity)
        mutableState.value = next
        mutableIsOffline.value = next.isOffline
    }

    private fun reason(profile: MultiServerState?): OfflineModeReason {
        if (!statusKnown) return OfflineModeReason.WAITING_FOR_SERVER_STATUS
        val known = profile?.expectedServerIds?.size ?: manager.serverIds.size
        if (known == 0) return OfflineModeReason.NO_KNOWN_VISIBLE_SERVERS
        if (profile != null && profile.refusedServerIds.size == known) return OfflineModeReason.ONLY_REFUSED_SERVERS
        if (!hasServerConnection(profile)) {
            return if (connecting) OfflineModeReason.WAITING_FOR_SERVER_STATUS else OfflineModeReason.NO_SERVER_CONNECTION
        }
        return OfflineModeReason.ONLINE
    }

    private fun hasServerConnection(profile: MultiServerState?): Boolean =
        profile?.hasConnectedServers ?: manager.onlineServerIds.isNotEmpty()

    private fun markStatusKnownIfSettled(profile: MultiServerState?) {
        if (hasServerConnection(profile) || profile?.hasExplicitVisibleServerFilter == true) statusKnown = true
    }
}
