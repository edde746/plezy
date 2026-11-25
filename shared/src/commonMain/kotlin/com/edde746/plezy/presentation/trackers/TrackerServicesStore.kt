package com.edde746.plezy.presentation.trackers

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.TrackerLibraryFilterMode
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.SignInPrompt
import com.edde746.plezy.trackers.TrackerAccounts
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.data.tracker.TrackerAccount
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException

/**
 * Settings > Services for one profile: the hub, the connect dialog, each connected service's settings and each
 * service's library filter ([ServicesUiState]).
 *
 * Tapping a row that isn't connected signs it in ([connect]): the dialog shows the code or link once the service gives
 * one (and, with pointer input, the link opens in the browser), closes when the sign-in resolves, and a sign-in that
 * didn't connect, unless the user cancelled it, leaves a "Couldn't connect" message. [cancelConnect] (the Cancel button
 * and the system back) cancels once. [release], when the screens go, cancels a sign-in still waiting: nobody could see
 * its code any more.
 *
 * The scrobble toggles, Trakt's watched sync and the library filters are this device's ([DeviceSettingsRepository]),
 * for every profile; the connections are the profile's. [libraries] are the libraries the filter lists. Where the app
 * speaks to Discord ([discordOffered]), the hub also switches Discord's Rich Presence. Main thread only.
 */
class TrackerServicesStore internal constructor(
    private val profileId: String,
    private val accounts: TrackerAccounts,
    private val settings: DeviceSettingsRepository,
    libraries: Flow<List<MediaLibrary>>,
    parentScope: CoroutineScope,
    private val discordOffered: Boolean = false,
) {
    private val scope = parentScope.childScope()
    private var data = Data()
    private var dialog: ConnectDialogUi? = null
    private var openUrl: String? = null
    private var message: String? = null
    private var connectJob: Job? = null
    private var cancelled = false

    private val mutableState = MutableStateFlow(build())

    val state: StateFlow<ServicesUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            combine(
                combine(accounts.observe(profileId), accounts.legacy(profileId), accounts.connecting) { connected, legacy, connecting ->
                    Triple(connected, legacy, connecting?.takeIf { it.profileId == profileId }?.service)
                },
                prefs(),
                libraries,
            ) { (connected, legacy, connecting), prefs, libs -> Data(connected, legacy, connecting, prefs, libs) }
                .collect {
                    data = it
                    publish()
                }
        }
    }

    /**
     * Signs [service] in, unless it is connected or a sign-in is in flight. [pointer]: the user is on touch or a
     * pointer (not a keyboard or D-pad), so the link opens in the browser by itself.
     */
    fun connect(service: TrackerService, pointer: Boolean) = start(service, pointer, reconnect = false)

    /** Signs Simkl in again while its connection is legacy ([TrackerSettingsUi.reconnect]), as [connect]. */
    fun reconnect(service: TrackerService, pointer: Boolean) = start(service, pointer, reconnect = true)

    /** Cancels the sign-in the dialog waits for: once, without a message. */
    fun cancelConnect() {
        if (connectJob == null || cancelled) return
        cancelled = true
        dialog = null
        openUrl = null
        accounts.cancelConnect()
        publish()
    }

    /** The view opened [ServicesUiState.openUrl] (or failed to: nothing to tell). */
    fun urlOpened() {
        openUrl = null
        publish()
    }

    /** The view showed [ServicesUiState.message]. */
    fun messageShown() {
        message = null
        publish()
    }

    /** Disconnects [service] (the view confirmed with [TrackerSettingsUi.disconnectConfirm]); its screen then closes. */
    fun disconnect(service: TrackerService) {
        scope.launch {
            try {
                accounts.disconnect(profileId, service)
            } catch (e: TrackerException.SecretStore) {
                // The connection is gone; the cleanup of unused sessions deletes the session later.
                Log.w(TAG, e) { "${service.id} session not deleted on disconnect" }
            }
        }
    }

    fun setToggle(service: TrackerService, toggle: TrackerToggle, on: Boolean) {
        val setting = when (toggle) {
            TrackerToggle.SCROBBLE -> AppSettings.scrobble(service)
            TrackerToggle.WATCHED_SYNC -> AppSettings.enableTraktWatchedSync
        }
        scope.launch { settings.set(setting, on) }
    }

    /** Switches Discord's Rich Presence ([ServicesUiState.discordPresence]). */
    fun setDiscordPresence(on: Boolean) {
        scope.launch { settings.set(AppSettings.enableDiscordRpc, on) }
    }

    /** Switches [service]'s filter mode; the library list stays. */
    fun setFilterMode(service: TrackerService, mode: TrackerLibraryFilterMode) {
        scope.launch { settings.set(AppSettings.trackerFilterMode(service), mode) }
    }

    /** Puts the library [globalKey] in [service]'s filter list ([on]) or takes it out. */
    fun setLibraryFiltered(service: TrackerService, globalKey: String, on: Boolean) {
        scope.launch {
            settings.update(AppSettings.trackerFilterIds(service)) { ids -> if (on) (ids + globalKey).distinct() else ids - globalKey }
        }
    }

    fun release() {
        scope.cancel()
    }

    private fun start(service: TrackerService, pointer: Boolean, reconnect: Boolean) {
        if (connectJob != null || data.connecting != null || accounts.connecting.value != null) return
        val connected = data.accounts.any { it.service == service }
        if (if (reconnect) service !in data.legacy else connected) return
        cancelled = false
        connectJob = scope.launch {
            val ok = try {
                val prompt: (SignInPrompt) -> Unit = { prompt(service, it, pointer) }
                val account = if (reconnect) accounts.reconnect(profileId, service, prompt) else accounts.signIn(profileId, service, prompt)
                account != null
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "${service.id} connect failed" }
                false
            }
            connectJob = null
            dialog = null
            openUrl = null
            if (!ok && !cancelled) message = T.services.connectFailed(name(service))
            publish()
        }
        publish()
    }

    private fun prompt(service: TrackerService, prompt: SignInPrompt, pointer: Boolean) {
        if (cancelled) return
        val name = name(service)
        val shown = when (prompt) {
            is SignInPrompt.DeviceCode -> ConnectDialogUi.DeviceCode(
                service = service,
                title = T.services.deviceCode.title(name),
                body = T.services.deviceCode.instructions,
                url = prompt.grant.verificationUrlComplete ?: prompt.grant.verificationUrl,
                readableUrl = readableUrl(prompt.grant.verificationUrl),
                openLabel = T.services.deviceCode.openToActivate(name),
                copyUrl = T.services.pendingAuth.copyUrl,
                urlCopied = T.services.pendingAuth.urlCopied,
                waiting = T.services.deviceCode.waitingForAuthorization,
                cancel = T.common.cancel,
                userCode = prompt.grant.userCode,
                copyCode = T.services.deviceCode.copyCode,
                codeCopied = T.services.deviceCode.codeCopied,
            )
            is SignInPrompt.Link -> ConnectDialogUi.Link(
                service = service,
                title = T.services.oauthProxy.title(name),
                body = T.services.oauthProxy.body,
                url = prompt.start.url,
                readableUrl = readableUrl(prompt.start.url),
                openLabel = T.services.oauthProxy.openToSignIn(name),
                copyUrl = T.services.pendingAuth.copyUrl,
                urlCopied = T.services.pendingAuth.urlCopied,
                waiting = T.services.deviceCode.waitingForAuthorization,
                cancel = T.common.cancel,
            )
        }
        dialog = shown
        if (pointer) openUrl = shown.url
        publish()
    }

    private fun publish() {
        mutableState.value = build()
    }

    private fun build(): ServicesUiState {
        val available = HUB_ORDER.filter { it in accounts.services }
        val connected = data.accounts.associateBy { it.service }
        return ServicesUiState(
            title = T.services.title,
            subtitle = T.services.hubSubtitle,
            rows = available.map { service ->
                val account = connected[service]
                ServiceRowUi(
                    service = service,
                    title = name(service),
                    subtitle = when {
                        account == null -> T.services.notConnected
                        account.username != null -> T.services.connectedAs(account.username)
                        else -> T.trakt.connected
                    },
                    connected = account != null,
                    busy = data.connecting == service,
                )
            },
            dialog = dialog,
            openUrl = openUrl,
            message = message,
            settings = available.mapNotNull { service -> connected[service]?.let { settingsOf(it) } },
            filters = available.map(::filterOf),
            discordPresence = if (discordOffered) data.prefs.discord else null,
        )
    }

    private fun settingsOf(account: TrackerAccount): TrackerSettingsUi {
        val service = account.service
        val name = name(service)
        val prefs = data.prefs
        val trakt = service == TrackerService.TRAKT
        val username = account.username
        return TrackerSettingsUi(
            service = service,
            title = name,
            accountTitle = when {
                trakt -> if (username != null) T.trakt.connectedAs(username) else T.trakt.connected
                else -> if (username != null) T.services.connectedAs(username) else name
            },
            accountSubtitle = if (trakt) T.trakt.connected else null,
            reconnect = if (service in data.legacy) ReconnectRowUi(T.services.simklReconnect.title, T.services.simklReconnect.subtitle) else null,
            behaviorTitle = T.settings.behavior,
            toggles = if (trakt) {
                listOf(
                    TrackerToggleUi(TrackerToggle.SCROBBLE, T.trakt.scrobble, T.trakt.scrobbleDescription, prefs.scrobble.getValue(service)),
                    TrackerToggleUi(TrackerToggle.WATCHED_SYNC, T.trakt.watchedSync, T.trakt.watchedSyncDescription, prefs.watchedSync),
                )
            } else {
                listOf(TrackerToggleUi(TrackerToggle.SCROBBLE, T.services.scrobble, T.services.scrobbleDescription, prefs.scrobble.getValue(service)))
            },
            libraryFilterTitle = T.services.libraryFilter.title,
            libraryFilterValue = filterValue(prefs.modes.getValue(service), prefs.ids.getValue(service)),
            disconnect = T.common.disconnect,
            disconnectConfirm = DisconnectConfirmUi(
                title = if (trakt) T.trakt.disconnectConfirm else T.services.disconnectConfirm(name),
                body = if (trakt) T.trakt.disconnectConfirmBody else T.services.disconnectConfirmBody(name),
                confirm = T.common.disconnect,
                cancel = T.common.cancel,
            ),
        )
    }

    private fun filterOf(service: TrackerService): LibraryFilterUi {
        val mode = data.prefs.modes.getValue(service)
        val selected = data.prefs.ids.getValue(service).toSet()
        // Libraries without a server can't be named by a global key the filter matches: left out.
        val byServer = data.libraries.filter { it.serverId != null }.groupBy { it.serverId!! }
        fun switches(libraries: List<MediaLibrary>) = libraries.map { LibrarySwitchUi(it.globalKey, it.title, it.globalKey in selected) }
        val groups = when {
            byServer.size > 1 -> byServer.map { (serverId, libraries) -> LibraryGroupUi(libraries.first().serverName ?: serverId, switches(libraries)) }
            else -> listOf(LibraryGroupUi(T.services.libraryFilter.libraries, switches(byServer.values.flatten())))
        }
        return LibraryFilterUi(
            service = service,
            title = T.services.libraryFilter.title,
            hint = if (mode == TrackerLibraryFilterMode.BLACKLIST) T.services.libraryFilter.modeHintBlacklist else T.services.libraryFilter.modeHintWhitelist,
            modeTitle = T.services.libraryFilter.mode,
            modes = listOf(
                FilterModeUi(TrackerLibraryFilterMode.BLACKLIST, T.services.libraryFilter.modeBlacklist, mode == TrackerLibraryFilterMode.BLACKLIST),
                FilterModeUi(TrackerLibraryFilterMode.WHITELIST, T.services.libraryFilter.modeWhitelist, mode == TrackerLibraryFilterMode.WHITELIST),
            ),
            groups = groups,
            empty = if (byServer.isEmpty()) T.services.libraryFilter.noLibraries else null,
        )
    }

    /** The device's tracker settings, as they change. */
    private fun prefs(): Flow<Prefs> {
        val services = TrackerService.entries
        val flows: List<Flow<Any>> = services.map { settings.observe(AppSettings.scrobble(it)) } +
            services.map { settings.observe(AppSettings.trackerFilterMode(it)) } +
            services.map { settings.observe(AppSettings.trackerFilterIds(it)) } +
            listOf(settings.observe(AppSettings.enableTraktWatchedSync), settings.observe(AppSettings.enableDiscordRpc))
        return combine(flows) { values ->
            val n = services.size
            @Suppress("UNCHECKED_CAST")
            Prefs(
                scrobble = services.withIndex().associate { (i, s) -> s to values[i] as Boolean },
                modes = services.withIndex().associate { (i, s) -> s to values[n + i] as TrackerLibraryFilterMode },
                ids = services.withIndex().associate { (i, s) -> s to values[2 * n + i] as List<String> },
                watchedSync = values[3 * n] as Boolean,
                discord = values[3 * n + 1] as Boolean,
            )
        }
    }

    private class Prefs(
        val scrobble: Map<TrackerService, Boolean> = TrackerService.entries.associateWith { AppSettings.scrobble(it).default },
        val modes: Map<TrackerService, TrackerLibraryFilterMode> = TrackerService.entries.associateWith { AppSettings.trackerFilterMode(it).default },
        val ids: Map<TrackerService, List<String>> = TrackerService.entries.associateWith { AppSettings.trackerFilterIds(it).default },
        val watchedSync: Boolean = AppSettings.enableTraktWatchedSync.default,
        val discord: Boolean = AppSettings.enableDiscordRpc.default,
    )

    private class Data(
        val accounts: List<TrackerAccount> = emptyList(),
        val legacy: Set<TrackerService> = emptySet(),
        val connecting: TrackerService? = null,
        val prefs: Prefs = Prefs(),
        val libraries: List<MediaLibrary> = emptyList(),
    )

    internal companion object {
        private const val TAG = "trackers"

        /** The hub's order. */
        val HUB_ORDER = listOf(TrackerService.TRAKT, TrackerService.MYANIMELIST, TrackerService.ANILIST, TrackerService.SIMKL, TrackerService.MDBLIST)

        fun name(service: TrackerService): String = when (service) {
            TrackerService.TRAKT -> T.trakt.title
            TrackerService.MYANIMELIST -> T.services.names.mal
            TrackerService.ANILIST -> T.services.names.anilist
            TrackerService.SIMKL -> T.services.names.simkl
            TrackerService.MDBLIST -> T.services.names.mdblist
        }

        /** [url] as shown: without its scheme and trailing slashes. */
        fun readableUrl(url: String): String = url.replaceFirst(Regex("^https?://"), "").trimEnd('/')

        /** The library filter row's value: what syncs with no library listed, else how many are listed. */
        fun filterValue(mode: TrackerLibraryFilterMode, ids: List<String>): String {
            val count = ids.toSet().size
            return when {
                count == 0 && mode == TrackerLibraryFilterMode.BLACKLIST -> T.services.libraryFilter.subtitleAllSyncing
                count == 0 -> T.services.libraryFilter.subtitleNoneSyncing
                mode == TrackerLibraryFilterMode.BLACKLIST -> T.services.libraryFilter.subtitleBlocked(count.toString())
                else -> T.services.libraryFilter.subtitleAllowed(count.toString())
            }
        }
    }
}
