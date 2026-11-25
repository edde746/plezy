package com.edde746.plezy.app

import com.edde746.plezy.crash.StartupFailures
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.input.Hotkeys
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.music.PlaybackCoordinator
import com.edde746.plezy.net.NetworkState
import com.edde746.plezy.net.PlezyHttpClient
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.CustomShader
import com.edde746.plezy.playback.Downmix
import com.edde746.plezy.playback.ShaderPreset
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.presentation.player.DiscordPosters
import com.edde746.plezy.presentation.player.PictureChoices
import com.edde746.plezy.presentation.player.PlayerChoices
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.player.PlayerPreferences
import com.edde746.plezy.secrets.SecretStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ScopedPlayerPref
import com.edde746.plezy.settings.ScopedPlayerPrefs
import com.edde746.plezy.settings.parseMpvConfigText
import com.edde746.plezy.trackers.BuildTrackerConfig
import com.edde746.plezy.trackers.TrackerHub
import com.edde746.plezy.trackers.TrackerTokenStore
import com.edde746.plezy.trackers.devTrackerRedirect
import com.edde746.plezy.trackers.ids.AnimeMappings
import com.edde746.plezy.trackers.ids.mediaTrackerIdResolvers
import com.edde746.plezy.trackers.relay.OAuthRelayClient
import com.edde746.plezy.trackers.trackerProviders
import io.ktor.client.HttpClient
import kotlin.time.Clock
import kotlin.time.TimeSource
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonObject

/**
 * Where this build is distributed, which decides what it offers: update checks only where nothing else updates the app
 * ([SIDELOADED]); the Supporter purchase only where a store sells it ([STORE] on Android and Apple).
 * Android and desktop builds take theirs from `-Pplezy.flavor` (settings.gradle.kts), the Apple apps from their
 * Info.plist's `PlezyFlavor` (apple/project.yml's PLEZY_APPLE_FLAVOR).
 */
enum class BuildFlavor {
    /** Google Play, the App Store and the Microsoft Store: the store updates the app. */
    STORE,

    /** The Amazon Appstore. */
    AMAZON,

    /**
     * The GitHub release's builds, installed by hand or by a package manager: the APKs, the IPA, the macOS DMG, the
     * Windows installer and portable archives, the Linux packages, AppImage and Flatpak.
     */
    SIDELOADED,
}

/**
 * The shared core for one app process (a manual composition root): the local data, the secret store, the HTTP client,
 * and the state the platform reports (network, foreground, visibility).
 *
 * Construct it off the main thread (it opens the database); use the rest from the main thread. [scope] is the app's
 * main-thread scope: stores and sessions run in it. [requestDispatcher] is where a play's start reads the database and
 * asks its server, off the main thread ([com.edde746.plezy.playback.session.PlaybackEnvironment.requests]).
 *
 * @param appVersion as About shows it ("2.26.0"); sent as `User-Agent: Plezy/<version>` by the HTTP client and the
 *   player.
 */
class AppGraph internal constructor(
    val data: LocalData,
    val secrets: SecretStore,
    val flavor: BuildFlavor,
    val appVersion: String,
    val http: HttpClient,
    val scope: CoroutineScope,
    internal val clock: Clock,
    /** Where the app keeps files of its own beside the database ([DatabaseFactory.filesDirectory]). */
    internal val filesDirectory: String,
    internal val requestDispatcher: CoroutineDispatcher = Dispatchers.Default,
    internal val timeSource: TimeSource.WithComparableMarks = TimeSource.Monotonic,
    /** Where Plezy's earlier releases kept their data, imported on the first start ([RootSession]); null for none. */
    internal val earlierRelease: EarlierReleaseLocations? = null,
    /**
     * The background downloader's partial files (`DownloadPlatform.tempDirectory`), discarded when the database can't
     * open on a full disk ([RootSession]); null on a device without downloads.
     */
    internal val downloadTempDirectory: String? = null,
    /** A development build (Android's debug build, Apple's Debug configuration): the player offers its debug entries. */
    internal val development: Boolean = false,
    /** The build as a failed start's record names it (`AppBootstrap.product`'s `buildLabel`): `version+build`. */
    internal val buildLabel: String = appVersion,
) : AutoCloseable {
    constructor(
        database: DatabaseFactory,
        secrets: SecretStore,
        flavor: BuildFlavor,
        appVersion: String,
        http: HttpClient = PlezyHttpClient.create(appVersion),
        scope: CoroutineScope,
        clock: Clock = Clock.System,
    ) : this(LocalData(database), secrets, flavor, appVersion, http, scope, clock, database.filesDirectory())

    /** The last failed start's record, kept beside the database; the Logs screen shows it. */
    val startupFailures: StartupFailures = StartupFailures(filesDirectory)

    /** Discord's posters, uploaded once per server artwork for as long as the host keeps them. */
    val discordPosters: DiscordPosters by lazy { DiscordPosters(http, clock) }

    /** The start's work after the app's first frame has run ([afterFirstFrame]): once per process. Main thread. */
    internal var firstFrameWorkDone = false

    private var trackerHub: TrackerHub? = null

    /**
     * The trackers (Trakt, Simkl, MDBList, MyAnimeList, AniList) of every profile on this device, with this build's
     * registrations ([BuildTrackerConfig]); made on first use unless a development session installed its own
     * ([installTrackers]).
     */
    val trackers: TrackerHub get() = trackerHub ?: installTrackers(http)

    private var trackerMappings: AnimeMappings? = null

    /** The anime mapping datasets [trackers] resolve with; the anime catalogs bridge their ids through them too. */
    internal val animeMappings: AnimeMappings get() = trackerMappings ?: installTrackers(http).let { checkNotNull(trackerMappings) }

    /**
     * Makes [trackers] with the services' calls, the OAuth relay's and the anime mappings' download going through
     * [serviceHttp] (a development session's redirect to a fake tracker server). Once, before the first use.
     */
    private fun installTrackers(serviceHttp: HttpClient): TrackerHub {
        check(trackerHub == null) { "the trackers are already installed" }
        val config = BuildTrackerConfig.config
        val mappings = AnimeMappings(serviceHttp, filesDirectory, data.deviceSettings, scope).also { trackerMappings = it }
        return TrackerHub(
            accountRepository = data.trackerAccounts,
            queue = data.trackerWriteQueue,
            settings = data.deviceSettings,
            tokens = TrackerTokenStore(secrets),
            providers = trackerProviders(serviceHttp, config, appVersion),
            resolvers = mediaTrackerIdResolvers(mappings),
            relay = config.relayBaseUrl.takeIf { it.isNotBlank() }?.let { OAuthRelayClient(serviceHttp, it) },
            clock = clock,
            timeSource = timeSource,
            scope = scope,
        ).also { trackerHub = it }
    }

    /**
     * Makes [trackers] against the fake tracker server at [baseUrl] (a development session's `--dev-trackers`): every
     * service's calls, the relay's and the anime mappings' download go there ([devTrackerRedirect]). Once, before the
     * first use.
     */
    fun installDevTrackers(baseUrl: String): TrackerHub = installTrackers(http.config { install(devTrackerRedirect(baseUrl)) })

    private val mutableNetwork = MutableStateFlow(NetworkState.ONLINE)

    /**
     * The device's network as the platform last reported it ([AppBootstrap.onNetworkChanged]); [NetworkState.ONLINE]
     * until it does. A development session's `offline` switch holds it offline.
     */
    val network: StateFlow<NetworkState> = mutableNetwork.asStateFlow()

    // The platform's last report, kept while a development session holds the network offline.
    private var reportedNetwork = NetworkState.ONLINE
    private val mutableOfflineHeld = MutableStateFlow(false)

    /** A development session holds the app offline ([holdOffline]): the shell is offline whatever the servers say. */
    val offlineHeld: StateFlow<Boolean> = mutableOfflineHeld.asStateFlow()

    internal fun setNetwork(state: NetworkState) {
        reportedNetwork = state
        if (!mutableOfflineHeld.value) mutableNetwork.value = state
    }

    /**
     * A development session's `offline` switch (the dev module's `DevSetting.Offline`): while [held], [network] stays
     * offline whatever the platform reports and the shell is offline ([offlineHeld]; desktop and simulators prove
     * offline mode with it); released, it is the platform's last report.
     */
    fun holdOffline(held: Boolean) {
        mutableOfflineHeld.value = held
        mutableNetwork.value = if (held) NetworkState.OFFLINE else reportedNetwork
    }

    private val mutableForeground = MutableStateFlow(false)

    /**
     * Whether the app is in the foreground as the platform last reported it ([AppBootstrap.onForeground],
     * [AppBootstrap.onBackground]); `false` until the first report, so a process started for background work (Android's
     * download worker) counts as in the background.
     */
    val foreground: StateFlow<Boolean> = mutableForeground.asStateFlow()

    internal fun setForeground(foreground: Boolean) {
        mutableForeground.value = foreground
    }

    /** The Mac's window as it last reported it ([AppBootstrap.onWindowVisibleChanged]); null where nothing reports it. */
    private val mutableWindowVisible = MutableStateFlow<Boolean?>(null)

    /**
     * Whether the app can be seen. On the Mac its window's report alone decides ([AppBootstrap.onWindowVisibleChanged]):
     * a window in sight behind another app's counts, and one minimized, hidden or covered whole doesn't, even while the
     * app is the active one. Elsewhere it is [foreground].
     */
    val visible: Flow<Boolean> = combine(foreground, mutableWindowVisible) { foreground, window -> window ?: foreground }.distinctUntilChanged()

    internal fun setWindowVisible(visible: Boolean) {
        mutableWindowVisible.value = visible
    }

    /**
     * A development session's `player.fastTimers` switch (the dev module's `DevSetting.FastTimers`): while on, the
     * players opened next get [playerConfig]'s fast sleep timer.
     */
    var fastPlayerTimers = false

    /**
     * The config the next player opens with, from the platform's [config]: with this build's [development] entries, and
     * with a development session's fast timers ([fastPlayerTimers]) its sleep timer's minutes
     * [FAST_SLEEP_TIMER_MINUTE_SECONDS] seconds each.
     */
    internal fun playerConfig(config: PlayerConfig): PlayerConfig = config.copy(
        development = development,
        sleepTimerMinuteSeconds = if (fastPlayerTimers) FAST_SLEEP_TIMER_MINUTE_SECONDS else config.sleepTimerMinuteSeconds,
    )

    /** The player's options this device keeps for the next video, as its device settings. */
    val playerPreferences: PlayerPreferences = object : PlayerPreferences {
        private val settings = data.deviceSettings
        private val player = listOf(
            AppSettings.rotationLocked, AppSettings.playerAlwaysOnTop, AppSettings.maxVolume, AppSettings.subtitleSearchLanguage,
            AppSettings.audioOutputDevice, AppSettings.sleepTimerDuration, AppSettings.rememberBrightnessLevel,
            AppSettings.rememberedBrightnessLevel, AppSettings.seekTimeSmall, AppSettings.seekTimeLarge,
            AppSettings.videoPlayerNavigationEnabled, AppSettings.keyboardHotkeys, AppSettings.downmixCenterBoost,
            AppSettings.audioDownmixNormalize, AppSettings.showPlaybackInfo, AppSettings.autoHidePlaybackInfo, AppSettings.ambientLighting,
        )

        override val choices = combine(settings.observe(), settings.observe(player)) { it, values ->
            PlayerChoices(
                customShaders = it.customShaders,
                audioNormalization = it.audioNormalization,
                audioChannels = it.audioChannels,
                hdr = it.hdr,
                audioOutputDevice = values[4] as String,
                configAudioDevice = parseMpvConfigText(it.mpvConfigText).any { (name, _) -> name == "audio-device" },
                sleepTimerMinutes = values[5] as Int,
                dolbyVisionConversion = it.dvConversionMode,
                brightnessSwipe = it.brightnessSwipe,
                volumeSwipe = it.volumeSwipe,
                pinchToZoom = it.pinchToZoom,
                rotationLocked = values[0] as Boolean,
                alwaysOnTop = values[1] as Boolean,
                maxVolume = values[2] as Int,
                subtitleSearchLanguage = values[3] as String?,
                downmix = Downmix(values[12] as Int, values[13] as Boolean),
                showPlaybackInfo = values[14] as Boolean,
                autoHidePlaybackInfo = values[15] as Boolean,
                ambientLighting = values[16] as Boolean,
                rememberBrightness = values[6] as Boolean,
                rememberedBrightness = values[7] as Double,
                seekSeconds = values[8] as Int,
                longSeekSeconds = values[9] as Int,
                playerNavigation = values[10] as Boolean?,
                hotkeys = Hotkeys.decode(values[11] as JsonObject),
            )
        }
            .distinctUntilChanged()

        override suspend fun picture(item: MediaItem?) = PictureChoices(
            fit = ScopedPlayerPrefs.resolve(settings, ScopedPlayerPrefs.boxFitMode, item),
            zoom = ScopedPlayerPrefs.resolve(settings, ScopedPlayerPrefs.videoZoom, item),
            shaderPreset = ScopedPlayerPrefs.resolve(settings, ScopedPlayerPrefs.shaderPreset, item),
        )

        override fun setVideoFit(item: MediaItem?, fit: VideoFit) = saveScoped(ScopedPlayerPrefs.boxFitMode, item, fit)

        override fun setVideoZoom(item: MediaItem?, zoom: Double) = saveScoped(ScopedPlayerPrefs.videoZoom, item, zoom)

        override fun setShaderPreset(item: MediaItem?, id: String) = saveScoped(ScopedPlayerPrefs.shaderPreset, item, id)

        override fun addCustomShader(item: MediaItem?, shader: CustomShader) {
            scope.launch {
                data.deviceSettings.update(AppSettings.customShaderPresets) { it + shader }
                ScopedPlayerPrefs.write(settings, ScopedPlayerPrefs.shaderPreset, item, shader.id, clock.now().toEpochMilliseconds())
            }
        }

        override fun removeCustomShader(shader: CustomShader) {
            scope.launch {
                data.deviceSettings.update(AppSettings.globalShaderPreset) { if (it == shader.id) ShaderPreset.Off.id else it }
                data.deviceSettings.update(AppSettings.customShaderPresets) { shaders -> shaders.filter { it.id != shader.id } }
            }
        }

        override fun setAudioNormalization(enabled: Boolean) = save(AppSettings.audioNormalization, enabled)

        override fun setAudioChannels(channels: AudioChannels) = save(AppSettings.audioChannelLimit, channels)

        override fun setRotationLocked(locked: Boolean) = save(AppSettings.rotationLocked, locked)

        override fun setAlwaysOnTop(enabled: Boolean) = save(AppSettings.playerAlwaysOnTop, enabled)

        override fun setSubtitleSearchLanguage(language: String) = save(AppSettings.subtitleSearchLanguage, language)

        override fun setShowPlaybackInfo(enabled: Boolean) = save(AppSettings.showPlaybackInfo, enabled)

        override fun setAmbientLighting(enabled: Boolean) = save(AppSettings.ambientLighting, enabled)

        override fun setRememberedBrightness(level: Double) = save(AppSettings.rememberedBrightnessLevel, level.coerceIn(0.0, 1.0))

        override fun setVolume(percent: Double) = save(AppSettings.volume, percent.coerceIn(0.0, 300.0))

        override fun setHdr(enabled: Boolean) = save(AppSettings.enableHdr, enabled)

        override fun setAudioOutputDevice(name: String) = save(AppSettings.audioOutputDevice, name)

        private fun <T> save(setting: DeviceSetting<T>, value: T) {
            scope.launch { data.deviceSettings.set(setting, value) }
        }

        private fun <T> saveScoped(pref: ScopedPlayerPref<T>, item: MediaItem?, value: T) {
            scope.launch { ScopedPlayerPrefs.write(settings, pref, item, value, clock.now().toEpochMilliseconds()) }
        }
    }

    /** Keeps one native player alive: video claims playback from the music session before it builds its engine. */
    val playbackCoordinator = PlaybackCoordinator()

    /** Stops everything this graph runs and closes the HTTP client and the database ([LocalData.close]). */
    override fun close() {
        scope.cancel()
        http.close()
        data.close()
    }
}

/** A sleep-timer minute's length in seconds under [AppGraph.fastPlayerTimers]: a tenth of a minute. */
private const val FAST_SLEEP_TIMER_MINUTE_SECONDS = 6
