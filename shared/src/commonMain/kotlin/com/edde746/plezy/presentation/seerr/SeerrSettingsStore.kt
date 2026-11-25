package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.seerr.SeerrAccounts
import com.edde746.plezy.seerr.SeerrAuthMethod
import com.edde746.plezy.seerr.SeerrSession
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * The Services hub's Seerr row: "Seerr" over its status, as the trackers' rows: "Not connected", or the signed-in
 * user and the server ("Alice · Jellyseerr": the instance's name, else its address without the scheme). Opening it
 * leads to the Seerr settings when connected, else to the connect screen.
 */
data class SeerrServiceRow(val title: String, val subtitle: String, val connected: Boolean) {
    companion object {
        fun of(session: SeerrSession?): SeerrServiceRow = SeerrServiceRow(
            T.seerr.title,
            session?.let { "${it.displayName} · ${it.instanceLabel.ifEmpty { it.baseUrl.substringAfter("://").trimEnd('/') }}" }
                ?: T.services.notConnected,
            connected = session != null,
        )
    }
}

/**
 * The Seerr settings screen ([title]): who is signed in ([connectedAs], by [method]), the instance ([instanceLabel],
 * [baseUrl]) and [disconnectLabel] (destructive). [confirm] is the disconnect confirmation while it is up. [closed] is
 * set once the account has no session (disconnected here or invalidated in the background): the screen closes itself.
 */
data class SeerrSettingsUiState(
    val title: String,
    val connectedAs: String,
    val method: String,
    val instanceLabel: String,
    val baseUrl: String,
    val disconnectLabel: String,
    val confirm: SeerrDisconnectConfirm?,
    val closed: Boolean,
)

/** "Disconnect Seerr?" with its body, a destructive confirm and a cancel. */
data class SeerrDisconnectConfirm(val title: String, val message: String, val confirmLabel: String, val cancelLabel: String)

/** The Seerr settings screen's store; call everything on the main thread, [release] ends it. */
class SeerrSettingsStore internal constructor(private val accounts: SeerrAccounts, parentScope: CoroutineScope) {
    private val scope = parentScope.childScope()

    /** The session last shown, kept so the screen keeps its content while it closes. */
    private var shown: SeerrSession? = accounts.session.value
    private var confirming = false

    private val mutableState = MutableStateFlow(build(accounts.session.value))

    val state: StateFlow<SeerrSettingsUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            accounts.session.collect { session ->
                if (session != null) shown = session
                mutableState.value = build(session)
            }
        }
    }

    /** Disconnect: asks for confirmation first. */
    fun requestDisconnect() {
        if (accounts.session.value == null) return
        confirming = true
        publish()
    }

    fun cancelDisconnect() {
        confirming = false
        publish()
    }

    /** Forgets the account; the screen closes once the session is gone. */
    fun confirmDisconnect() {
        if (!confirming) return
        confirming = false
        publish()
        scope.launch { accounts.disconnect() }
    }

    fun release() {
        scope.cancel()
    }

    private fun publish() {
        mutableState.value = build(accounts.session.value)
    }

    private fun build(current: SeerrSession?): SeerrSettingsUiState {
        val session = current ?: shown
        return SeerrSettingsUiState(
            title = T.seerr.title,
            connectedAs = session?.let { T.services.connectedAs(it.displayName) }.orEmpty(),
            method = session?.method?.let(::methodLabel).orEmpty(),
            instanceLabel = session?.instanceLabel?.takeIf { it.isNotEmpty() } ?: T.seerr.instance,
            baseUrl = session?.baseUrl.orEmpty(),
            disconnectLabel = T.common.disconnect,
            confirm = if (confirming && current != null) {
                SeerrDisconnectConfirm(T.seerr.disconnectConfirm, T.seerr.disconnectConfirmBody, T.common.disconnect, T.common.cancel)
            } else {
                null
            },
            closed = current == null,
        )
    }

    private fun methodLabel(method: SeerrAuthMethod): String = when (method) {
        SeerrAuthMethod.PLEX -> "Plex"
        SeerrAuthMethod.JELLYFIN -> "Jellyfin"
        SeerrAuthMethod.EMBY -> "Emby"
        SeerrAuthMethod.LOCAL -> T.seerr.email
        SeerrAuthMethod.QUICK_CONNECT -> T.auth.quickConnect
    }
}
