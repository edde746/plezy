package com.edde746.plezy

import android.annotation.SuppressLint
import android.app.Activity
import android.app.ActivityManager
import android.app.Dialog
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.media.MediaCodecList
import android.net.Uri
import android.os.Build
import android.os.PersistableBundle
import android.os.Process
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.ViewConfiguration
import android.view.WindowManager
import android.view.accessibility.AccessibilityManager
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.LocalActivity
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.WindowCompat
import com.edde746.plezy.app.BrowserMode
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.BundledText
import com.edde746.plezy.app.DeviceIdentity
import com.edde746.plezy.app.DevicePlatform
import com.edde746.plezy.app.PlatformPlayback
import com.edde746.plezy.appicon.AppIconPreviews
import com.edde746.plezy.appicon.AppIconSelection
import com.edde746.plezy.appicon.AppIconSwitcher
import com.edde746.plezy.cast.NsdCastDiscovery
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.downloads.android.AndroidDownloads
import com.edde746.plezy.image.ArtworkDevice
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.log.Log
import com.edde746.plezy.media.AndroidMediaControls
import com.edde746.plezy.media.AndroidMusicSystem
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.mpv.MpvVideoView
import com.edde746.plezy.mpv.androidAudioPlayer
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.net.WebUrl
import com.edde746.plezy.output.AndroidPlaybackOutput
import com.edde746.plezy.output.DeviceOutput
import com.edde746.plezy.playback.BundledShaders
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.ShaderDirectories
import com.edde746.plezy.playback.ShaderFiles
import com.edde746.plezy.playback.ShaderRenderer
import com.edde746.plezy.playback.output.PlaybackOutputHost
import com.edde746.plezy.playback.output.VideoCapabilities
import com.edde746.plezy.players.AndroidPlayerApps
import com.edde746.plezy.presentation.player.DeviceLevels
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.PictureInPictureHost
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.supporter.AndroidPlayBilling
import com.edde746.plezy.supporter.SupporterPlatform
import com.edde746.plezy.ui.app.SaveResult
import com.edde746.plezy.ui.app.PlezyPlatform
import com.edde746.plezy.ui.updates.PlatformUpdates
import com.edde746.plezy.updates.Installation
import com.edde746.plezy.watchnext.WatchNext
import java.io.File
import kotlin.concurrent.thread

/**
 * The Compose app's platform on Android phones, tablets, Android TV and Fire TV, one per process
 * ([PlezyApplication]). The activity on screen attaches itself as [activity] for what needs one: launching other
 * apps, leaving, the display mode, and its [pictureInPicture]. Phones and tablets are both [FormFactor.HANDHELD]; the
 * window's size picks their layout.
 *
 * Every playback gets its own mpv engine ([createPlayback]), with the playback's Dolby Vision and HDR settings, which
 * reach mpv before its first file. It shows in the media session ([mediaControls]) and follows the output plan
 * ([AndroidPlaybackOutput]).
 */
internal class AndroidPlatform(context: Context, override val downloads: AndroidDownloads) : PlezyPlatform {
    private val context: Context = context.applicationContext

    /** The activity showing the app, while one does. */
    var activity: Activity? = null

    override fun tintSystemBars(dark: Boolean) {
        val window = activity?.window ?: return
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = !dark
            isAppearanceLightNavigationBars = !dark
        }
    }

    /** More mpv options for every engine, applied last. Only debug launches set them (test runs pass `ao=null`). */
    var mpvOptions: Map<String, String> = emptyMap()

    /** Every new engine's events (`MpvPlayerEngine`'s `events`). Only a debug launch's perf marks set them. */
    var mpvEvents: ((String) -> Unit)? = null

    override val formFactor: FormFactor = if (isTelevision(this.context)) FormFactor.TV else FormFactor.HANDHELD

    override val appleTv = false

    override val lowEndHardware: Boolean by lazy {
        val activities = this.context.getSystemService(ActivityManager::class.java)
        val memory = ActivityManager.MemoryInfo().also(activities::getMemoryInfo)
        activities.isLowRamDevice || !Process.is64Bit() || memory.totalMem <= LOW_END_MEMORY_BYTES
    }

    override val automotive: Boolean = this.context.packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)

    /**
     * The GitHub release check in the release build (a store build's flavor has none); none in the debug and harness
     * builds.
     */
    override val updates: PlatformUpdates? = if (BuildConfig.BUILD_TYPE == "release") PlatformUpdates(Installation.Other) else null

    val isTelevision: Boolean get() = formFactor == FormFactor.TV

    /**
     * The largest window the app can have, in pixels (the surface it composites at), with the reduced tier's hardware
     * signals: a 32-bit process, the system's low-RAM flag and the total memory.
     */
    override val artworkDevice: ArtworkDevice
        get() {
            val activities = context.getSystemService(ActivityManager::class.java)
            val memory = ActivityManager.MemoryInfo().also { activities.getMemoryInfo(it) }
            val windows = context.getSystemService(WindowManager::class.java)
            val (width, height) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                windows.maximumWindowMetrics.bounds.let { it.width() to it.height() }
            } else {
                @Suppress("DEPRECATION")
                DisplayMetrics().also { windows.defaultDisplay.getRealMetrics(it) }.let { it.widthPixels to it.heightPixels }
            }
            return ArtworkDevice(width, height, Process.is64Bit(), activities.isLowRamDevice, memory.totalMem)
        }

    /** In the app's own cache, which the system may clear when storage runs low. */
    override val artworkCacheDirectory = File(this.context.cacheDir, "artwork")

    override val device: DeviceIdentity = DeviceIdentity(
        platform = "Android",
        // The build's display id (`ro.build.display.id`, e.g. `AP4A.250105.002`), as the earlier releases sent it.
        platformVersion = Build.DISPLAY,
        deviceModel = Build.MODEL,
        deviceName = assignedDeviceName(this.context) ?: "${Build.BRAND} ${Build.MODEL}",
        isTv = isTelevision,
    )

    override fun diagnostics(): List<String> {
        val tv = TvSignals.read(context)
        return listOfNotNull(
            "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "${Build.MANUFACTURER} ${Build.MODEL}",
            tv.reasons.takeIf { it.isNotEmpty() }?.let { "TV signals: ${it.joinToString()}${if (tv.isAutomotive) " (a car: not a TV)" else ""}" },
        )
    }

    /** The activity's picture-in-picture, while an activity shows. */
    var activityPictureInPicture: PictureInPicture? = null

    /** The activity's picture-in-picture where the device has it; a recomposition reads it again with the player. */
    override val pictureInPicture: PictureInPictureHost? get() = activityPictureInPicture?.takeIf { it.supported }

    /** The activity's player window (orientation, immersive bars), while an activity shows. */
    var playerOrientation: PlayerOrientation? = null

    /** The activity is in picture-in-picture: the player shows only its video. Compose state. */
    override var inPictureInPicture: Boolean by mutableStateOf(false)

    /** The playback asks for the display to stay awake ([PlatformPlayback.keepDisplayAwake]). Compose state. */
    private var keepScreenOn by mutableStateOf(false)

    /**
     * Touch exploration is on (TalkBack turns it on): the player keeps its controls up meanwhile. Compose state,
     * following the system's switch.
     */
    override var assistiveTechnology: Boolean by mutableStateOf(false)
        private set

    /**
     * Remove animations is on (the system's transition animation scale at 0). Compose state, following the system's
     * setting.
     */
    override var reducedMotion: Boolean by mutableStateOf(false)
        private set

    init {
        val accessibility = this.context.getSystemService(AccessibilityManager::class.java)
        assistiveTechnology = accessibility.isTouchExplorationEnabled
        accessibility.addTouchExplorationStateChangeListener { assistiveTechnology = it }
        val resolver = this.context.contentResolver
        val scale = android.provider.Settings.Global.TRANSITION_ANIMATION_SCALE
        fun readScale() {
            reducedMotion = android.provider.Settings.Global.getFloat(resolver, scale, 1f) == 0f
        }
        readScale()
        resolver.registerContentObserver(
            android.provider.Settings.Global.getUriFor(scale),
            false,
            object : android.database.ContentObserver(android.os.Handler(android.os.Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) = readScale()
            },
        )
    }

    override val playerConfig: PlayerConfig = PlayerConfig.defaults(
        if (formFactor == FormFactor.TV) InputProfile.TV else InputProfile.TOUCH,
        ViewConfiguration.getDoubleTapTimeout().toLong(),
    )

    /** A phone's or tablet's brightness and media volume, for the player's swipes; a TV has no swipes. */
    override val deviceLevels: DeviceLevels? = if (isTelevision) null else AndroidDeviceLevels(this.context) { activity?.window }

    /** The media session every playback, video or music, shows in (notification, lock screen, media keys). */
    val mediaControls: AndroidMediaControls by lazy { AndroidMediaControls(this.context, isTelevision) }

    override val musicControls: MediaControlsHost get() = mediaControls

    override val musicSystem: AndroidMusicSystem by lazy { AndroidMusicSystem(this.context) }

    /** Android 13+'s notification permission, asked by downloads and music through the activity on screen. */
    override val notificationPermission = AndroidNotificationPermission(this.context)

    /** DNS-SD for casting through the system's NsdManager. */
    override val castDiscovery = NsdCastDiscovery(this.context)

    override fun createPlayback(settings: DeviceSettings): PlatformPlayback {
        val mpv = MpvPlayerEngine(context, mpvOptions, mpvEvents, settings, isTelevision)
        return object : PlatformPlayback {
            override val engine: PlayerEngine = mpv
            override val hardwareDecoder = HardwareDecoder.ANDROID
            override val runsAmbientLighting = true
            override val mediaControls: MediaControlsHost = this@AndroidPlatform.mediaControls
            override val output: PlaybackOutputHost = AndroidPlaybackOutput(context, mpv, { activity?.window }) {
                this@AndroidPlatform.mediaControls.displaySwitching = it
            }

            override fun keepDisplayAwake(awake: Boolean) {
                keepScreenOn = awake
            }

            override val pictureInPictureStarting: Boolean get() = activityPictureInPicture?.autoEntering == true
        }
    }

    /** The music player; a debug launch's mpv options ([mpvOptions], a test run's `ao=null`) apply to it too. */
    override fun createMusicAudioPlayer(): AudioPlayer = androidAudioPlayer(context, mpvOptions)


    override fun deviceFeatures(): DeviceFeatures = DeviceOutput.features(context, isTelevision)

    override fun videoCapabilities(): VideoCapabilities = DeviceOutput.videoCapabilities(context)

    init {
        // Android reads the codec list once per process (MediaCodecList's own cache), in tens of milliseconds of calls to
        // the media server: read here on a thread of its own, so the first server's client, made on the main thread as
        // the app starts ([videoCapabilities]), finds it read.
        thread(name = "codec list") { MediaCodecList(MediaCodecList.REGULAR_CODECS) }
    }

    /** External players: an intent hand-off to the selected player app; results come back to [PlezyActivity]. */
    override val externalPlayers: AndroidPlayerApps = AndroidPlayerApps(this.context)

    /**
     * The engine's video and subtitle planes under the player's controls ([MpvVideoView]), which tell the
     * picture-in-picture window of its picture. The view stays bound to its engine after the playback releases it, so
     * a late `surfaceDestroyed` waits for the engine's teardown to move mpv off the Surface.
     * While it is shown the system bars are hidden ([PlayerOrientation]): the player always fills the screen,
     * and the view reaches under the display cutout the app's content keeps clear of (PlayerScreen lays the video out
     * to the display's edges). The window behind it turns black meanwhile, as the video's own letterbox is, instead of
     * showing the app's background where the view doesn't cover it yet (the player fading in). The view keeps the screen
     * on while the playback asks ([keepScreenOn]): its window has `FLAG_KEEP_SCREEN_ON` only while the view is attached
     * and shown, in picture in picture too, so leaving the player or the app lets the display sleep as well. The
     * player's orientation follows its rotation lock ([PlayerOrientation]).
     */
    @Composable
    override fun VideoSurface(engine: PlayerEngine, modifier: Modifier) {
        val activity = LocalActivity.current
        DisposableEffect(activity) {
            val window = activity?.window
            val background = window?.decorView?.background
            window?.decorView?.setBackgroundColor(Color.BLACK)
            val orientation = playerOrientation
            orientation?.playerShown()
            onDispose {
                window?.decorView?.background = background
                orientation?.playerHidden()
            }
        }
        // A new playback's engine gets a view of its own.
        key(engine) {
            AndroidView(
                factory = {
                    MpvVideoView(it).apply {
                        setEngine(engine as MpvPlayerEngine)
                        onPictureChanged = { width, height -> activityPictureInPicture?.onPicture(width, height) { pictureBoundsInWindow() } }
                    }
                },
                modifier = modifier,
                update = { it.keepScreenOn = keepScreenOn },
            )
        }
    }

    /** The player always fills the screen on Android; the store never asks. */
    override fun setFullscreen(fullscreen: Boolean) = Unit

    /**
     * Opens the web link [url] in the app that handles it: YouTube links in the YouTube app where it claims them, the
     * rest in the browser ([opens]). A TV without a browser may still have YouTube, which takes `vnd.youtube:` links;
     * with no app at all it returns false, and the app shows the link as a QR code for a phone. Anything but an
     * `http`/`https` link is refused ([WebUrl.isWeb]).
     */
    override fun openUrl(url: String): Boolean {
        if (!WebUrl.isWeb(url)) {
            Log.w(TAG) { "Not opening a link with scheme ${WebUrl.scheme(url)}" }
            return false
        }
        val activity = activity ?: return false
        if (opens(activity, Intent(Intent.ACTION_VIEW, Uri.parse(url)))) return true
        val youTube = youTubeId(url)
        if (youTube != null && start(activity, Intent(Intent.ACTION_VIEW, Uri.parse("vnd.youtube:$youTube")))) return true
        // The URL itself may carry a token: log only where it points.
        Log.w(TAG) { "No app opens ${Uri.parse(url).scheme}://${Uri.parse(url).host}" }
        return false
    }

    /** The web view an in-app [openUrl] shows over the activity on TV, until [closeInAppBrowser] or Back. */
    private var webView: Dialog? = null

    /** An in-app [openUrl] started a Custom Tab, which [closeInAppBrowser] closes. */
    private var customTab = false

    /**
     * Opens the web link [url] as [mode] asks: [BrowserMode.IN_APP_BROWSER] in a Custom Tab over the activity (a
     * browser without Custom Tabs shows it as a page of its own), [BrowserMode.IN_APP_WEB_VIEW] in a web view of the
     * app's own, full screen over the activity, [BrowserMode.EXTERNAL] as [openUrl] does. False with no browser (a
     * Custom Tab) or no system web view.
     */
    override fun openUrl(url: String, mode: BrowserMode): Boolean {
        if (mode == BrowserMode.EXTERNAL) return openUrl(url)
        if (!WebUrl.isWeb(url)) {
            Log.w(TAG) { "Not opening a link with scheme ${WebUrl.scheme(url)}" }
            return false
        }
        val activity = activity ?: return false
        closeInAppBrowser()
        if (mode == BrowserMode.IN_APP_WEB_VIEW) return showWebView(activity, url)
        customTab = hasBrowser(activity) && start(activity, CustomTabsIntent.Builder().build().intent.setData(Uri.parse(url)))
        return customTab
    }

    override fun closeInAppBrowser() {
        webView?.dismiss()
        webView = null
        val activity = activity
        if (customTab && activity != null) {
            // The Custom Tab runs in this activity's task, over it: bringing the activity back to the top ends it.
            start(activity, Intent(activity, activity.javaClass).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP))
        }
        customTab = false
    }

    /** Shows [url] in a full-screen web view over [activity] ([webView]); false where the device has no system web view. */
    @SuppressLint("SetJavaScriptEnabled")
    private fun showWebView(activity: Activity, url: String): Boolean {
        val view = try {
            WebView(activity)
        } catch (e: RuntimeException) {
            Log.w(TAG) { "No web view on this device: ${e::class.simpleName}" }
            return false
        }
        // plex.tv's sign-in is a script-driven page that keeps its session in DOM storage; its links stay in the view.
        view.settings.javaScriptEnabled = true
        view.settings.domStorageEnabled = true
        view.webViewClient = WebViewClient()
        view.loadUrl(url)
        val dialog = Dialog(activity, android.R.style.Theme_DeviceDefault_NoActionBar_Fullscreen)
        dialog.setContentView(view)
        dialog.setOnDismissListener {
            view.destroy()
            if (webView === dialog) webView = null
        }
        dialog.show()
        view.requestFocus()
        webView = dialog
        return true
    }

    override fun setClipboardText(text: String, sensitive: Boolean) {
        val clipboard = context.getSystemService(ClipboardManager::class.java) ?: return
        val clip = ClipData.newPlainText(null, text)
        // Android 13+ shows a copy's preview unless it is marked sensitive.
        if (sensitive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            clip.description.extras = PersistableBundle().apply { putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true) }
        }
        clipboard.setPrimaryClip(clip)
    }

    /** Phones and tablets have the system's share sheet; TVs have none to speak of (the room's QR code serves there). */
    override val canShare: Boolean get() = !isTelevision

    override fun share(text: String) {
        val activity = activity ?: return
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
        start(activity, Intent.createChooser(send, null))
    }

    /** The document picker ([saveFile], [openFile]); its answers come back to [PlezyActivity]. */
    val files: AndroidFiles = AndroidFiles(this.context)

    /**
     * Phones and tablets. Not a TV: of the boxes checked (2026-10-11), Fire TV has no document picker, Google TV only the
     * framework's stub ("You don't have an app that can do this"), and the SHIELD's DocumentsUI can't reach its name
     * field or Save with a remote.
     */
    override val hasFileDialogs: Boolean get() = !isTelevision

    /** Android TV's Watch Next row ([WatchNext.create]); none on phones, tablets and Fire TV, nor before Android 8. */
    override val homeScreen: WatchNext? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WatchNext.create(this.context) else null

    /**
     * The launcher icon: one pick for the process, applied as the user leaves ([PlezyActivity.onStop]); Android TV
     * switches the banner the same way, Fire TV and cars don't ([AppIconSwitcher.isSupported]).
     */
    internal val appIcons = AppIconSelection(AppIconSwitcher(this.context.packageManager, this.context.packageName))

    /** The build flavor's Supporter perks: Google Play sells them; the launcher's icons. */
    override val supporter = SupporterPlatform.of(
        BuildFlavor.valueOf(BuildConfig.BUILD_FLAVOR),
        if (isTelevision) DevicePlatform.ANDROID_TV else DevicePlatform.ANDROID,
        billing = AndroidPlayBilling(this.context) { activity },
        appIcons = appIcons,
    )

    private val appIconPreviews = AppIconPreviews(this.context, isTelevision)

    /** The icon picker's thumbnails ([AppIconPreviews]). */
    @Composable
    override fun AppIconPreview(id: String, modifier: Modifier) = appIconPreviews.Preview(id, modifier)

    override fun saveFile(fileName: String, text: String, done: (SaveResult) -> Unit) = files.save(fileName, text, done)

    /**
     * The files under [folder] in the APK's assets, at any depth: an asset folder lists its entries, a file (or a path
     * that isn't there) none.
     */
    override fun bundledTexts(folder: String): List<BundledText> {
        val assets = context.assets
        fun under(path: String, relative: String): List<BundledText> {
            val entries = assets.list(path).orEmpty()
            if (entries.isEmpty()) return listOf(BundledText(relative, assets.open(path).use { it.readBytes().decodeToString() }))
            return entries.flatMap { under("$path/$it", "$relative/$it") }
        }
        return assets.list(folder).orEmpty().flatMap { under("$folder/$it", it) }.sortedBy { it.path }
    }

    override fun openFile(opened: (name: String, text: String) -> Unit, failed: () -> Unit) = files.open(opened, failed)

    override fun openImage(opened: (name: String, bytes: ByteArray) -> Unit, failed: () -> Unit) = files.openImage(opened, failed)

    /**
     * The player's shaders, run by mpv's GL vo on OpenGL ES ([ShaderRenderer.OPENGL_ES]). mpv reads files, not the APK's
     * assets, so a shipped one ([SHADER_ASSETS]) is copied into the cache's shaders/ before it runs, off the main
     * thread; the imported ones are kept in the app's files' custom_shaders/, where the earlier releases kept them.
     */
    override val shaderFiles: ShaderFiles = ShaderDirectories(
        ShaderRenderer.OPENGL_ES,
        BundledShaders.Packaged { path -> context.assets.open("$SHADER_ASSETS/$path").use { it.readBytes() } },
        File(context.cacheDir, SHADER_ASSETS).path,
        File(context.filesDir, CUSTOM_SHADERS).path,
    )

    /** Leaves the app and its task: it goes from Recents too. On the next turn of the main thread, after the caller. */
    override fun exit() {
        val activity = activity ?: return
        activity.window.decorView.post { activity.finishAndRemoveTask() }
    }

    /**
     * Starts [intent]; false when no app takes it, or when the system refuses it (`FileUriExposedException`,
     * `SecurityException`), which is logged by its class only: its message can carry the link.
     */
    private fun start(activity: Activity, intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    } catch (e: RuntimeException) {
        Log.w(TAG) { "The system refused to start ${intent.action}: ${e::class.simpleName}" }
        false
    }

    /**
     * Starts [view] in the app that takes it, unless only Android TV's framework stubs would ([isTvStub]). From
     * Android 11 an app that claims the link itself comes first (the system tells it from the browsers, which alone are
     * in this app's sight), then a browser where there is one; before Android 11 every app is in sight.
     */
    private fun opens(activity: Activity, view: Intent): Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        start(activity, Intent(view).addFlags(Intent.FLAG_ACTIVITY_REQUIRE_NON_BROWSER)) || (hasBrowser(activity) && start(activity, view))
    } else {
        activity.packageManager.queryIntentActivities(view, PackageManager.MATCH_DEFAULT_ONLY).any { !isTvStub(it.activityInfo.packageName) } &&
            start(activity, view)
    }

    private companion object {
        const val TAG = "AndroidPlatform"

        /** Total memory at or under which the device counts as low-end: below 3 GB Shield-class devices. */
        const val LOW_END_MEMORY_BYTES = 2252L * 1024 * 1024

        /** The asset folder of the shaders the app ships, by preset (`nvscaler/`, `artcnn/`, `anime4k/`). */
        const val SHADER_ASSETS = "shaders"

        /** The imported shaders' folder in the app's files. */
        const val CUSTOM_SHADERS = "custom_shaders"

        /** The video id of a `youtube.com/watch?v=` or `youtu.be/` link. */
        fun youTubeId(url: String): String? {
            val uri = Uri.parse(url)
            val host = uri.host?.removePrefix("www.")?.removePrefix("m.") ?: return null
            return when (host) {
                "youtube.com" -> uri.getQueryParameter("v")
                "youtu.be" -> uri.lastPathSegment
                else -> null
            }?.takeIf { it.isNotBlank() }
        }
    }
}

/** Android TV, Fire TV and other TV boxes ([TvSignals]); never a car. */
internal fun isTelevision(context: Context): Boolean = TvSignals.read(context).isTv

/**
 * The name the user gave the device (Settings → About → Device name, as Cast and Nearby show it), else its Bluetooth
 * name, which usually mirrors it and reads without the Bluetooth permission; null when neither is set.
 */
private fun assignedDeviceName(context: Context): String? {
    val name = Settings.Global.getString(context.contentResolver, Settings.Global.DEVICE_NAME)?.trim()
    if (!name.isNullOrEmpty()) return name
    return Settings.Secure.getString(context.contentResolver, "bluetooth_name")?.trim()?.takeIf { it.isNotEmpty() }
}

/** A browser is installed (TVs often have none): an app other than Android TV's framework stubs ([isTvStub]) opens [BROWSER_PROBE]. */
internal fun hasBrowser(context: Context): Boolean =
    context.packageManager.queryIntentActivities(BROWSER_PROBE, PackageManager.MATCH_DEFAULT_ONLY).any { !isTvStub(it.activityInfo.packageName) }

/**
 * A web link as a browser takes it (the manifest's `<queries>` put the browsers in sight); made on first use, so
 * nothing here touches the framework before a browser is looked for.
 */
private val BROWSER_PROBE: Intent by lazy { Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com")).addCategory(Intent.CATEGORY_BROWSABLE) }

/**
 * [packageName] is Android TV's stand-in for the apps a TV may lack (`Stubs$BrowserStub` for the browser), which takes
 * a browser's links on a TV without one only to say that no app opens them: AOSP's
 * `com.android.tv.frameworkpackagestubs`, or the `com.google.android.tv.` one some Google builds of Android TV ship.
 */
internal fun isTvStub(packageName: String): Boolean = packageName.endsWith(".frameworkpackagestubs")
