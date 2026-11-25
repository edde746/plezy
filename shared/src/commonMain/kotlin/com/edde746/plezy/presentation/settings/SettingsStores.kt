package com.edde746.plezy.presentation.settings

import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.app.AppPlatform
import com.edde746.plezy.app.DeviceIdentity
import com.edde746.plezy.app.DevicePlatform
import com.edde746.plezy.cast.CastPeerInfo
import com.edde746.plezy.model.AccountPreferenceTarget
import com.edde746.plezy.model.AccountPreferencesSource
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.players.ExternalPlayerService
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AccountPreferencesController
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.servers.LibrariesLoadState
import com.edde746.plezy.servers.LibrariesState
import com.edde746.plezy.strings.T
import com.edde746.plezy.updates.AppUpdates
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.launch

/**
 * What the settings pages know of the device they run on, from [AppPlatform] and Force TV mode: which rows and
 * groups they show.
 *
 * @param os the OS, a [DevicePlatform] value (Android TV apart from Android).
 * @param formFactor the layout: the platform's, or a TV in Force TV mode.
 * @param appleTv an Apple TV: no downloads.
 * @param hasFileDialogs the system's save and open dialogs work here: Backup is offered (not on Android TV or tvOS).
 * @param supportsExternalPlayers the platform hands videos to player apps ([AppPlatform.externalPlayers]).
 * @param features the device settings that apply on this device ([AppPlatform.deviceFeatures]).
 */
data class SettingsFacts(
    val os: String,
    val formFactor: FormFactor,
    val appleTv: Boolean,
    val hasFileDialogs: Boolean,
    val supportsExternalPlayers: Boolean,
    val features: DeviceFeatures,
) {
    /** The TV layout (Android TV, Apple TV, Force TV mode). */
    val tv: Boolean get() = formFactor == FormFactor.TV

    /** A phone or tablet in its touch layout. */
    val handheld: Boolean get() = formFactor == FormFactor.HANDHELD

    val android: Boolean get() = os == DevicePlatform.ANDROID || os == DevicePlatform.ANDROID_TV
    val androidTv: Boolean get() = os == DevicePlatform.ANDROID_TV
    val linux: Boolean get() = os == DevicePlatform.LINUX
    val windows: Boolean get() = os == DevicePlatform.WINDOWS
    val macos: Boolean get() = os == DevicePlatform.MACOS

    /** iPhone, iPad, Apple TV. */
    val ios: Boolean get() = os == DevicePlatform.IOS || os == DevicePlatform.IPADOS || os == DevicePlatform.TVOS

    /** Windows, macOS or Linux, whatever the layout. */
    val desktopOs: Boolean get() = os == DevicePlatform.WINDOWS || os == DevicePlatform.MACOS || os == DevicePlatform.LINUX

    /** The keyboard shortcut editor: desktop systems. */
    val keyboardShortcutsSupported: Boolean get() = desktopOs

    /** Picture in picture as the app leaves: Android, iOS and macOS, never in the TV layout. */
    val supportsPip: Boolean get() = (android || os == DevicePlatform.IOS || os == DevicePlatform.IPADOS || macos) && !tv && !appleTv

    /** The app icon can change: iOS, tvOS and Android. */
    val appIconsSupported: Boolean get() = ios || android

    /** Passthrough is offered: Apple, Windows, Linux and Android TV. */
    val supportsAudioPassthrough: Boolean get() = ios || desktopOs || androidTv

    /** Show Navigation Bar Labels is offered: Android phones' bar can hide its labels; Apple's tab bar always shows them. */
    val navBarLabelsSupported: Boolean get() = android && handheld

    /** Always Keep Sidebar Open is offered: the iPad's and the Mac's sidebar can stay open; Compose's rail never expands. */
    val keepSidebarOpenSupported: Boolean get() = (os == DevicePlatform.IPADOS || macos) && !tv

    companion object {
        /** The OS [device] runs ([DevicePlatform]). */
        fun osOf(device: DeviceIdentity): String = when (device.platform) {
            "Android" -> if (device.isTv) DevicePlatform.ANDROID_TV else DevicePlatform.ANDROID
            "iOS" -> if (device.deviceModel?.startsWith("iPad") == true) DevicePlatform.IPADOS else DevicePlatform.IOS
            "tvOS" -> DevicePlatform.TVOS
            "macOS" -> DevicePlatform.MACOS
            "Windows" -> DevicePlatform.WINDOWS
            "Linux" -> DevicePlatform.LINUX
            else -> device.platform.lowercase()
        }
    }
}

/** The Supporter themes: [available] in this build and install, [unlocked] by a purchase. */
data class ThemePerks(val available: Boolean, val unlocked: Boolean)

/** An account whose preferences the active profile edits, and how to reach them (null: not reachable now). */
data class AccountPreferenceAccount(val target: AccountPreferenceTarget, val source: AccountPreferencesSource?)

/**
 * Whether Settings offers Manage Libraries: any library is loaded, or the active profile's libraries are still on their
 * way (its servers bind or load), so the row keeps its place through a profile switch and its page fills when they come.
 */
internal fun manageLibrariesShown(libraries: LibrariesState, profileActive: Boolean, binding: Boolean, serverCount: Int): Boolean {
    if (libraries.hasLibraries) return true
    val settled = libraries.loadState == LibrariesLoadState.LOADED || libraries.loadState == LibrariesLoadState.ERROR
    return profileActive && !settled && (binding || serverCount > 0)
}

/** What the settings stores take from the running session (AppSession), beside the graph and the platform. */
internal interface SettingsSession {
    val perks: StateFlow<ThemePerks>

    /** Manage Libraries shows ([manageLibrariesShown]). */
    val hasLibraries: StateFlow<Boolean>

    /** A catalog source exists (Plex Discover, trackers): Show Explore Tab shows. */
    val hasCatalog: StateFlow<Boolean>
    val profiles: StateFlow<List<Profile>>
    val activeProfile: StateFlow<Profile?>

    /** The profiles are still read, or the active one's bind runs or hasn't finished: its connections may not all be known. */
    val profileBinding: StateFlow<Boolean>

    /** The Services row's subtitle: the connected services, from the trackers' side of the session. */
    val servicesSummary: Flow<String> get() = flowOf(T.settings.servicesDescription)

    /** The accounts the active profile edits preferences of ([resolveAccountPreferenceAccounts]), in order. */
    suspend fun accountPreferenceAccounts(): List<AccountPreferenceAccount>

    /** Where those accounts' preferences are read and written: one cache, which playback reads too. */
    val accountPreferences: AccountPreferencesController

    /** The libraries and hidden libraries read again after an import. */
    suspend fun reloadLibraries()

    /** Puts downloads back in the default folder (Reset Settings does this first); nothing without downloads. */
    suspend fun resetDownloadLocation()

    /** The senders that cast to this device without asking, newest first. */
    val castSenders: Flow<List<CastPeerInfo>> get() = flowOf(emptyList())

    /** Forgets the sender [id]: it asks again before it casts here. */
    suspend fun forgetCastSender(id: String) = Unit
}

/**
 * The settings pages' stores ([com.edde746.plezy.app.AppSession.settings]): each call makes a new store, which the UI
 * keeps while its route is on the stack (`navigator.retain`) and releases. It also applies the settings whose effect
 * is the process's: the log level (Debug Logging) and the interface language. [updates] backs the hub's Updates group,
 * shown only where it is [AppUpdates.available].
 */
class SettingsStores internal constructor(
    private val graph: AppGraph,
    private val platform: AppPlatform,
    private val session: SettingsSession,
    parentScope: CoroutineScope,
    private val updates: AppUpdates? = platform.installation?.let { AppUpdates(graph, it) },
    private val externalPlayers: ExternalPlayerService? = platform.externalPlayers?.let { ExternalPlayerService(it, graph.data.deviceSettings, graph.clock) },
) {
    private val scope = parentScope.childScope()
    private val features by lazy { platform.deviceFeatures() }
    private val forceTv = MutableStateFlow(false)

    // Made when a settings page first reads them: the device's features ([AppPlatform.deviceFeatures]) probe the display
    // and the audio route, which the app's start doesn't need.
    private val mutableFacts by lazy {
        MutableStateFlow(factsFor(forceTv.value)).also { facts -> scope.launch { forceTv.collect { facts.value = factsFor(it) } } }
    }

    /** The device's facts now ([SettingsFacts]); they follow Force TV mode. */
    val facts: SettingsFacts get() = mutableFacts.value

    internal val factsFlow: StateFlow<SettingsFacts> get() = mutableFacts.asStateFlow()

    init {
        scope.launch { graph.data.deviceSettings.observe(AppSettings.forceTvMode).collect { forceTv.value = it } }
    }

    /** The store of the row page [id] ([SettingsPageId.rows]); [arg] its subject (an account's key). */
    fun page(id: SettingsPageId, arg: String? = null): SettingsPageStore = when (id) {
        SettingsPageId.HUB -> HubPage(graph, platform, session, factsFlow, updates, scope, session.servicesSummary)
        SettingsPageId.GENERAL -> GeneralPage(graph.data.deviceSettings, session, factsFlow, scope)
        SettingsPageId.APPEARANCE -> AppearancePage(graph.data.deviceSettings, session, factsFlow, scope)
        SettingsPageId.VIDEO_PLAYBACK -> VideoPlaybackPage(graph.data.deviceSettings, factsFlow, scope)
        SettingsPageId.SUBTITLE_STYLING -> SubtitleStylingPage(graph.data.deviceSettings, factsFlow, scope)
        SettingsPageId.ABOUT -> AboutPage(graph.data.deviceSettings, graph.appVersion, scope)
        SettingsPageId.ACCOUNT_PREFERENCES -> AccountPreferencesPage(graph.data.deviceSettings, session, arg, scope)
        else -> throw IllegalArgumentException("$id isn't a row page")
    }

    fun themePicker(): ThemePickerPage = ThemePickerPage(graph.data.deviceSettings, session.perks, factsFlow, scope)

    /** The editor of the Custom theme; [systemDark] picks System's palette when it is what the editor starts from. */
    fun customThemeEditor(systemDark: Boolean = true): CustomThemeEditorPage =
        CustomThemeEditorPage(graph.data.deviceSettings, session.perks, factsFlow, systemDark, scope)

    fun mpvConfig(): MpvConfigStore = MpvConfigPage(graph.data.deviceSettings, factsFlow.value, graph.clock, scope)

    fun externalPlayer(): ExternalPlayerPage {
        val players = checkNotNull(externalPlayers) { "External players aren't supported here" }
        return ExternalPlayerPage(graph.data.deviceSettings, players.platform, players::players, factsFlow.value, graph.clock, scope)
    }

    fun keyboardShortcuts(): KeyboardShortcutsPage = KeyboardShortcutsPage(graph.data.deviceSettings, factsFlow.value.macos, scope)

    fun logs(): LogsStore = LogsPage(graph.http, graph.appVersion, platform, graph.startupFailures, scope)

    /** Open source licenses: the list, or with [name] one component's licence texts. */
    fun licenses(name: String? = null): LicensesStore = LicensesStore(SettingsFacts.osOf(platform.device), name, platform::bundledTexts, scope)

    internal fun close() {
        scope.cancel()
    }

    private fun factsFor(forceTv: Boolean) = SettingsFacts(
        os = SettingsFacts.osOf(platform.device),
        formFactor = if (forceTv) FormFactor.TV else platform.formFactor,
        appleTv = platform.appleTv,
        hasFileDialogs = platform.hasFileDialogs,
        supportsExternalPlayers = platform.externalPlayers != null && !platform.appleTv,
        features = features,
    )
}
