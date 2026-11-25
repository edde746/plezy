package com.edde746.plezy.presentation.onboarding

import com.edde746.plezy.log.Log
import com.edde746.plezy.profiles.ProfileServices
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.MultiServerManager
import com.edde746.plezy.servers.MultiServerStore
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** The offline strip's and rail's Reconnect: [reconnecting] shows a spinner; [message] a snackbar to show once. */
data class ReconnectUiState(val reconnecting: Boolean = false, val message: String? = null)

/**
 * Reconnect, offered while the app is offline: starts the profiles' bind, checks every server's health (so a stale
 * "online" goes offline before the offline list is taken), reconnects the offline ones with a fresh endpoint race, and
 * binds the active profile again when it reaches no server though one could ([shouldRebindAfterReconnect]). No server
 * after all: "Unable to connect to media server". One at a time.
 */
class ReconnectStore(
    private val profiles: ProfileServices,
    private val manager: MultiServerManager,
    private val servers: MultiServerStore,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(ReconnectUiState())

    val state: StateFlow<ReconnectUiState> = mutableState.asStateFlow()

    fun reconnect() {
        if (mutableState.value.reconnecting) return
        mutableState.value = ReconnectUiState(reconnecting = true)
        scope.launch {
            var connected = false
            try {
                profiles.start()
                manager.checkServerHealth()
                manager.reconnectOfflineServers(forceRediscovery = true)
                val retry = shouldRebindAfterReconnect(
                    hasActiveProfile = profiles.active.value != null,
                    hasVisibleConnectedServers = servers.state.value.hasConnectedServers,
                    hasManagerOnlineServers = manager.onlineServerIds.isNotEmpty(),
                    hasKnownOfflineServers = manager.offlineServerIds.isNotEmpty(),
                )
                if (retry) {
                    profiles.rebindActive()
                    profiles.awaitBindingSettle()
                }
                connected = servers.state.value.hasConnectedServers
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Reconnecting failed" }
            }
            mutableState.value = ReconnectUiState(message = if (connected) null else T.errors.connectionFailed)
        }
    }

    fun messageShown() {
        mutableState.value = mutableState.value.copy(message = null)
    }

    fun close() = scope.cancel()

    private companion object {
        const val TAG = "Reconnect"
    }
}

/**
 * After a reconnect, whether to bind the active profile again: it has none of its servers, and either the manager
 * holds one online or it knows of none offline (the profile's bind never ran or failed before registering any).
 */
fun shouldRebindAfterReconnect(
    hasActiveProfile: Boolean,
    hasVisibleConnectedServers: Boolean,
    hasManagerOnlineServers: Boolean,
    hasKnownOfflineServers: Boolean,
): Boolean = hasActiveProfile && !hasVisibleConnectedServers && (hasManagerOnlineServers || !hasKnownOfflineServers)
