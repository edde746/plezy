package com.edde746.plezy.app

import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.cast.CastDiscovery
import com.edde746.plezy.music.MusicSystem
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.ShaderFiles
import com.edde746.plezy.playback.output.PlaybackOutputHost
import com.edde746.plezy.playback.output.VideoCapabilities
import com.edde746.plezy.playback.players.ExternalPlayerLauncher
import com.edde746.plezy.presentation.homescreen.HomeScreen
import com.edde746.plezy.presentation.player.DeviceLevels
import com.edde746.plezy.presentation.player.DiscordPresenceHost
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.player.PlayerStore
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.supporter.SupporterPlatform
import com.edde746.plezy.updates.Installation

/** The platforms without music's OS glue ([AppPlatform.musicSystem]). */
private object NoMusicSystem : MusicSystem

/**
 * What the running app ([AppSession], [RootSession]) needs from the OS it runs on (the glue stays native):
 * one per process, implemented by each app (Android, desktop, the Apple apps). Called on the main thread, but for
 * [bundledTexts].
 */
interface AppPlatform {
    /**
     * The kind of device the platform detects: the output policy (a desktop switches the display mode only while
     * fullscreen) and, unless Force TV mode makes it a TV ([AppSession.appearance]), the layout.
     */
    val formFactor: FormFactor

    /** What the app calls this device to media servers and companion devices, read once as the process starts. */
    val device: DeviceIdentity

    /**
     * The Logs header's lines about this system and hardware where the platform tells more than [device] (Android: the
     * release and API level, the maker and model). Empty: the header names [device]'s platform, version and model.
     */
    fun diagnostics(): List<String> = emptyList()

    /**
     * This is an Apple TV: no downloads, and back at the app's root goes to the system's home screen, unprompted. False
     * everywhere else.
     */
    val appleTv: Boolean

    /**
     * Low-end hardware (Android: a low-RAM or 32-bit device, or one with at most 2252 MiB of memory): screens keep less
     * cached. False where no such device ships.
     */
    val lowEndHardware: Boolean get() = false

    /**
     * This is an Android Automotive head unit: the interface scaled up by the car's display scale and the list rows at
     * their standard height ([com.edde746.plezy.presentation.theme.Appearance]), and Now Playing's transport keeps its
     * full size. False everywhere else.
     */
    val automotive: Boolean get() = false

    /** The player's keymap profile and timings, with the platform's double-click interval. */
    val playerConfig: PlayerConfig

    /**
     * The OS side of a new playback: its own mpv engine (on its own surface where the platform draws one per engine),
     * set up with this device's [settings].
     */
    fun createPlayback(settings: DeviceSettings): PlatformPlayback

    /**
     * A new music player: its own audio-only mpv core, apart from every video playback's engine. The caller disposes
     * it ([AudioPlayer.dispose]); the OS media controls and the audio session stay the music session's.
     */
    fun createMusicAudioPlayer(): AudioPlayer

    /** Enters or leaves fullscreen: desktop windows. Where the player always fills the screen, nothing happens. */
    fun setFullscreen(fullscreen: Boolean)

    /** The app's window can stay above the others (Windows, Linux where the window system lets it): [setAlwaysOnTop]. */
    val keepsOnTop: Boolean get() = false

    /** Keeps the app's window above the others, or lets it go; asked only where [keepsOnTop]. */
    fun setAlwaysOnTop(onTop: Boolean) = Unit

    /**
     * The app's window is fullscreen ([setFullscreen], or the window's own controls on the Mac): desktop; false where
     * the app always fills the screen. A player opening reads it: fullscreen from before it is the window's to keep.
     */
    val isFullscreen: Boolean get() = false

    /**
     * The screen's brightness and the system's volume, which swipes up and down the video change: phones and tablets.
     * Null elsewhere.
     */
    val deviceLevels: DeviceLevels? get() = null

    /**
     * Opens the `http`/`https` [url] outside the app: the browser, or the app that handles it. False when nothing on
     * this device opens it (an Apple TV has no browser, an Android TV may have none). [AppSession.openUrl] only passes
     * web links, and each platform's opener refuses (false) any other
     * ([com.edde746.plezy.net.WebUrl.isWeb]) on its own too.
     */
    fun openUrl(url: String): Boolean

    /**
     * Opens the `http`/`https` [url] as [mode] asks: [BrowserMode.EXTERNAL] is [openUrl]; an in-app mode shows it over
     * the app, where the platform has such a view (Android's Custom Tabs and web view, Safari's view on iPhone and
     * iPad). False where it has none (the desktop, the Mac, Apple TV) or nothing opened: the caller tries
     * [BrowserMode.EXTERNAL] then.
     */
    fun openUrl(url: String, mode: BrowserMode): Boolean = mode == BrowserMode.EXTERNAL && openUrl(url)

    /** Closes the view an in-app [openUrl] showed, if it still shows; nothing otherwise. */
    fun closeInAppBrowser() {}

    /**
     * Puts [text] on the clipboard as plain text, after the user asked to copy it: a share link, a room's code, an
     * addon's link. [sensitive]: the text holds a secret (an addon link's account key), so where the system can, the
     * clipboard keeps it off previews, other devices and clipboard managers: Android 13+ hides its preview, iOS keeps
     * it on this device for a few minutes, macOS marks it concealed. Windows and Linux copy it as any other text.
     */
    fun setClipboardText(text: String, sensitive: Boolean = false)

    /** The device settings that apply on this device (the display, the audio route), detected as Settings opens. */
    fun deviceFeatures(): DeviceFeatures

    /**
     * What the screen and the decoders take; where the platform can't tell more, HDR as [deviceFeatures] says it and
     * nothing else.
     */
    fun videoCapabilities(): VideoCapabilities = VideoCapabilities(hdr = deviceFeatures().hdr, dolbyVision = false, hardwareCodecs = emptySet())

    /**
     * External players on this device ([ExternalPlayerLauncher]): plays open in the one `selected_external_player` names
     * when `use_external_player` is on. Null where the platform has none (tests, tools): external players are off.
     */
    val externalPlayers: ExternalPlayerLauncher? get() = null

    /**
     * The system's save and open dialogs for a file exist here, usable with this device's input: Settings → Export and
     * import is offered ([com.edde746.plezy.presentation.settings.SettingsSection.DATA]), and the player's Shaders page
     * imports a shader. Not on Apple TV or Android TV: no picker, the framework's stub, or one a remote can't operate
     * (AndroidPlatform.hasFileDialogs).
     */
    val hasFileDialogs: Boolean get() = false

    /**
     * Where the player's shaders are on this device ([com.edde746.plezy.playback.ShaderPreset]): the app's own and the
     * imported ones. Every app's mpv runs them: Android moves a playback off its video plane to the GPU output while one
     * runs. Null hides the player's Shaders option (tests, tools).
     */
    val shaderFiles: ShaderFiles? get() = null

    /**
     * Discord's Rich Presence on this computer: the desktop and the Mac speak to the Discord app over its local IPC, and
     * Settings offers the switch ([DeviceFeatures.discordPresence]); null elsewhere, in a build given a blank Discord
     * application ([com.edde746.plezy.presentation.player.DiscordConfig]) and in a development session given none.
     */
    val discordPresence: DiscordPresenceHost? get() = null

    /**
     * The TV's home screen beside the app, where the running profile's Continue Watching shows ([HomeScreen]): Android
     * TV's Watch Next row, the Apple TV's Top Shelf. Null where the device has none (phones, desktops, Fire TV).
     */
    val homeScreen: HomeScreen? get() = null

    /**
     * The OS media controls the music session shows in (notification, lock screen, media keys, Now Playing), the same
     * host as a video's where the platform has one per process (one playback at a time); null where the platform has
     * none (tests, tools).
     */
    val musicControls: MediaControlsHost? get() = null

    /** The OS glue the music session needs beyond [musicControls]: the car service and the hardware keys. */
    val musicSystem: MusicSystem get() = NoMusicSystem

    /**
     * DNS-SD on the local network, which casting finds and announces receivers with ([CastDiscovery]); null where the
     * platform builds none (tests, tools): this device then neither finds receivers nor is found.
     */
    val castDiscovery: CastDiscovery? get() = null

    /** Android 13+'s notification permission, asked by downloads; nothing to ask elsewhere. */
    val notificationPermission: NotificationPermission get() = NoNotificationPermission

    /**
     * Downloads on this device ([PlatformDownloads]): every app but Apple TV's. Null there, and where the platform builds
     * no downloader (tests, tools): the session has no [AppSession.downloads].
     */
    val downloads: PlatformDownloads? get() = null

    /**
     * This build's Supporter perks and what sells and shows them here: the build's mode, the device's store, the
     * home-screen icon switcher ([SupporterPlatform]). [SupporterPlatform.OFF] where the build has no perks.
     */
    val supporter: SupporterPlatform get() = SupporterPlatform.OFF

    /**
     * Where this app is installed, which decides how it updates itself ([com.edde746.plezy.updates.updaterFor]):
     * Settings → Updates checks through it ([com.edde746.plezy.updates.AppUpdates]). Null where the build never checks
     * for updates (development builds, tests, tools).
     */
    val installation: Installation? get() = null

    /**
     * Every file under [folder] (a path such as `licenses/ktor`) in the app's bundled resources, at any depth: Android's
     * assets, the desktop app's resources folder (`compose.application.resources.dir`), the Apple app's bundle. Each
     * with its path relative to [folder] and its text read as UTF-8, sorted by path; none when the folder isn't there.
     * It reads files, so it is called off the main thread (About's licence texts).
     */
    fun bundledTexts(folder: String): List<BundledText>

    /** Leaves the app: Close with nothing left to go back to. Where the system leaves apps itself, nothing happens. */
    fun exit()
}

/** Where [AppPlatform.openUrl] opens a web link. */
enum class BrowserMode {
    /** A web view of the app's own: a TV, whose remote can't drive a browser (Android TV). */
    IN_APP_WEB_VIEW,

    /** The system's browser shown over the app (Android's Custom Tabs, Safari's view on iPhone and iPad). */
    IN_APP_BROWSER,

    /** Outside the app: the browser, or the app that handles the link. */
    EXTERNAL,
}

/**
 * The OS side of one playback, made by [AppPlatform.createPlayback]: the [engine], where the OS media controls show it,
 * and what switches the display for it. Whoever builds the shared parts over it (the playback session, the player
 * store, the media controls, the display output) ends them in a fixed order: the media controls and the display output
 * first, then [release], then the player store, and last the playback session, which releases [engine].
 */
interface PlatformPlayback {
    val engine: PlayerEngine

    /** The hardware decoder [engine] decodes with while the Hardware decoding setting is on (`PlaybackOptions`). */
    val hardwareDecoder: HardwareDecoder

    /** The OS media controls (notification, lock screen, media keys, Now Playing); null where the platform has none. */
    val mediaControls: MediaControlsHost?

    /** Display mode, HDR and passthrough switching for [engine]; null where the platform switches none of them. */
    val output: PlaybackOutputHost?

    /**
     * [engine] runs ambient lighting (`PlayerEngine.setAmbientLighting`): mpv's GPU outputs, and libplacebo on Apple's
     * display layer output. The player offers its switch where this is true and the platform has shader files.
     */
    val runsAmbientLighting: Boolean get() = false

    /**
     * The playback's store exists, before its first file loads: glue that drives the store starts here (the Apple audio
     * session pauses and resumes it around interruptions). Called once.
     */
    fun attach(store: PlayerStore) {}

    /**
     * Keeps the display awake (no dimming, screen saver or lock) while [awake]: the player store's
     * [PlayerUiState.keepAwake][com.edde746.plezy.presentation.player.PlayerUiState.keepAwake], passed on as it
     * changes, and false as the playback ends, before [release]. Holds at most one OS assertion, which the OS drops
     * with the process however it ends.
     */
    fun keepDisplayAwake(awake: Boolean)

    /** The playback ended, before its store and engine are: picture in picture stops, the audio session ends. Called once. */
    fun release() {}

    /**
     * Picture in picture is about to take the video as the app leaves (iOS and the Mac with auto picture in picture on,
     * Android while a window it started by itself is on its way): the player leaves its background pause alone.
     */
    val pictureInPictureStarting: Boolean get() = false
}

/** A text file of the app's bundled resources ([AppPlatform.bundledTexts]): its [path] under the folder asked for. */
data class BundledText(val path: String, val text: String)
