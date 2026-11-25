package com.edde746.plezy

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.addCallback
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.InterceptPlatformTextInput
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.crash.StartupFailedException
import com.edde746.plezy.crash.StartupFailureRecord
import com.edde746.plezy.crash.StartupMark
import com.edde746.plezy.crash.StartupMarks
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.downloads.android
import com.edde746.plezy.downloads.android.AndroidDownloads
import com.edde746.plezy.secrets.AndroidSecretStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.ui.app.PlezyApp
import com.edde746.plezy.ui.app.PlezyRoot
import com.edde746.plezy.ui.app.StartupFailureScreen
import com.edde746.plezy.ui.components.appArea
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.LocalPerfProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.launch

/**
 * The app's one activity: the product ([PlezyRoot]: the splash, then the app), or a debug launch's dev session
 * ([PlezyApp]). The window starts in the launch colour of the user's theme ([SplashTheme]), which shows through the
 * splash; the system's splash (Android 12+) leaves without its fade. The app draws edge to edge inside the system bars
 * and the display cutout, the bars counted while hidden too ([appArea]), so leaving the player, which hides them while
 * it shows and lays its video out under them and the cutout (AndroidPlatform.VideoSurface), moves no screen as they
 * come back. Compose draws focus itself: the system's focus highlight is off.
 *
 * Back goes through the navigation event dispatcher: the screens' back handlers (menus and overlays first, then the
 * back stack), and at the root the system's default (the task moves to the background). The video's SurfaceViews
 * hand mpv to its placeholder surface when the activity stops (playback pauses) and back when it returns.
 *
 * A playing video goes to picture-in-picture on Home ([PictureInPicture]); the activity stays started there, so the
 * surfaces and the playback carry on. The player's window follows its rotation lock and hides the system bars ([PlayerOrientation]). A
 * `plezy://` link opens the app (or comes to the running one) and goes to the product's root ([openLink]). An external
 * player a play hands off to reports back as an activity result ([com.edde746.plezy.players.AndroidPlayerApps]). The
 * network and the system's settings reach the shared cores from
 * the process ([ProcessNetwork], [PlezyApplication]), not from here.
 */
class PlezyActivity : ComponentActivity() {
    private val plezy: PlezyApplication get() = application as PlezyApplication
    private var launch: TestLaunch? = null
    private var product: ProductApp? = null
    private var pictureInPicture: PictureInPicture? = null
    private var playerOrientation: PlayerOrientation? = null

    /** The user left since the last start (Home, Recents, Back at the root): a picked launcher icon applies as it stops. */
    private var userLeaving = false

    /** The shared core on screen: the product's, or a debug launch's dev session once it is built. */
    private val boot: AppBootstrap? get() = product?.boot ?: launch?.boot

    override fun onCreate(savedInstanceState: Bundle?) {
        // The launch colour the user's theme left ([SplashTheme]) on the window before anything draws.
        SplashTheme.restore(this)
        enableEdgeToEdge(SystemBarStyle.dark(Color.TRANSPARENT), SystemBarStyle.dark(Color.TRANSPARENT))
        super.onCreate(savedInstanceState)
        // The system splash (Android 12+) goes at once, without its fade: the launch colour stays under the splash.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) splashScreen.setOnExitAnimationListener { it.remove() }
        // Compose draws its own focus: no system focus highlight over it.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) window.decorView.defaultFocusHighlightEnabled = false
        // Back that no screen takes (added before the screens' handlers, so it runs last): the system moves the task to
        // the background without finishing it and without a leave hint; it counts as leaving.
        onBackPressedDispatcher.addCallback(this) {
            userLeaving = true
            isEnabled = false
            onBackPressedDispatcher.onBackPressed()
            isEnabled = true
        }
        val plezy = plezy
        plezy.platform.activity = this
        // Before the activity starts: an external player's or the document picker's result reaches the launcher this
        // activity registers, also one started from an activity this one replaces.
        plezy.platform.externalPlayers.attach(this)
        plezy.platform.files.attach(this)
        plezy.downloads.permissions.attach(this)
        plezy.platform.notificationPermission.attach(this)
        plezy.armMemoryWatchdog()
        pictureInPicture = PictureInPicture(this, plezy.platform, plezy.platform.mediaControls).also {
            plezy.platform.activityPictureInPicture = it
            it.attach()
        }
        playerOrientation = PlayerOrientation(this, plezy.platform.isTelevision).also { plezy.platform.playerOrientation = it }
        // A fresh launch starts over; a recreated activity goes on with the launch it showed.
        if (savedInstanceState == null) {
            plezy.testLaunch?.close()
            plezy.testLaunch = testLaunch(plezy, intent)
        }
        val launch = plezy.testLaunch
        this.launch = launch
        // A product whose core can't be built shows the startup failure screen; its Retry builds it again.
        var failed: StartupFailureRecord? = null
        val product = if (launch?.dev == true) {
            null
        } else {
            try {
                plezy.product.also { launch?.attachProduct(it.root) }
            } catch (e: StartupFailedException) {
                failed = e.record
                null
            }
        }
        this.product = product
        val failure = failed
        // Auto picture-in-picture follows the `auto_pip` setting while the activity lives.
        val autoPip = boot?.graph?.data?.deviceSettings?.observe(AppSettings.autoPip)
        val pip = pictureInPicture
        if (autoPip != null && pip != null && pip.supported) {
            lifecycleScope.launch {
                autoPip.collect { pip.autoPipOn = AppSettings.autoPipOn(it, supportsPictureInPicture = true, isMacOs = false) }
            }
        }
        // The player's rotation lock, as the player's button and the settings change it.
        boot?.let { boot ->
            lifecycleScope.launch {
                boot.graph.data.deviceSettings.observe(AppSettings.rotationLocked).collect { playerOrientation?.rotationLockChanged(it) }
            }
        }
        // A link that launched the app; not again when the activity is recreated or relaunched from Recents.
        if (savedInstanceState == null && intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY == 0) openLink(intent)

        setContent {
            InterceptPlatformTextInput(UnaskedFocusActions) {
                CompositionLocalProvider(
                    LocalLayoutProbe provides launch?.probe,
                    LocalPerfProbe provides launch?.perfProbe,
                ) {
                    val modifier = Modifier.windowInsetsPadding(WindowInsets.appArea)
                    if (failure != null) {
                        PlezyTheme { StartupFailureScreen(failure, ::recreate, ::resetData) }
                    } else if (product != null) {
                        // The splash leaves the launch screen, in the colour restored above, on display.
                        PlezyRoot(product.root, plezy.platform, modifier, transparentWhileLoading = true, onResetData = ::resetData)
                    } else {
                        launch?.devApp?.let { PlezyApp(it, plezy.platform, modifier) }
                    }
                }
            }
        }
        // The process's first frame.
        if (!plezy.drewFirstFrame) {
            plezy.drewFirstFrame = true
            window.decorView.post { StartupMarks.mark(StartupMark.FIRST_FRAME) }
        }
    }

    /**
     * The startup failure screen's Reset app data, once the user confirmed it: the product's database closes (it opened
     * here, in RootSession), the saved data is reset ([AppBootstrap.resetData]), and the process starts again as a first
     * run. The product is built once per process, so a new process is the start over.
     */
    private suspend fun resetData() {
        product?.boot?.graph?.data?.close()
        AppBootstrap.resetData(
            DatabaseFactory(this), AndroidSecretStore(this), DownloadStoragePlatform.android(this), AndroidDownloads.tempDirectory(this),
        )
        startActivity(Intent.makeRestartActivityTask(ComponentName(this, PlezyActivity::class.java)))
        Runtime.getRuntime().exit(0)
    }

    /** A link opened while the app runs (singleTop: the running activity gets it). */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        openLink(intent)
    }

    /**
     * A `plezy://` link [intent] views (the manifest's intent filter), handed over unchanged to the product's root
     * ([com.edde746.plezy.app.RootSession.openUrl]), or to a dev session's app ([com.edde746.plezy.app.AppSession.links]).
     */
    private fun openLink(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val url = intent.dataString ?: return
        if (!url.startsWith("plezy:", ignoreCase = true)) return
        val product = product
        if (product != null) product.root.openUrl(url) else launch?.devApp?.links?.open(url)
    }

    /**
     * A hardware media key reaches the window while the app is in front (a HID remote's, a keyboard's): a music
     * session's key handler takes it first ([com.edde746.plezy.media.AndroidMusicSystem.dispatch]), and what it consumes
     * goes nowhere else (not the focused item, not the system's media-button fallback). This overrides Activity's
     * public method; lint resolves it to androidx.core's ComponentActivity override, which is restricted to AndroidX.
     */
    @SuppressLint("RestrictedApi")
    override fun dispatchKeyEvent(event: KeyEvent): Boolean =
        plezy.platform.musicSystem.dispatch(event) || super.dispatchKeyEvent(event)

    /**
     * A car covers the app for driving without stopping it (the system's blocking activity pauses it): there, a pause is
     * the background, and the resume the foreground again.
     */
    override fun onPause() {
        if (plezy.platform.musicSystem.car != null) boot?.onBackground()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        if (plezy.platform.musicSystem.car != null) boot?.onForeground()
    }

    override fun onStart() {
        super.onStart()
        userLeaving = false
        boot?.onForeground()
        plezy.platform.mediaControls.onForeground()
        plezy.downloads.onForeground()
        launch?.event("onStart")
    }

    /**
     * A picked launcher icon applies once the user leaves (Home, Recents, Back at the root, the app closing), never when
     * the app opens another activity or plays in picture-in-picture: the switch finishes the task started through the
     * alias it disables, which then happens behind the launcher.
     */
    override fun onStop() {
        launch?.event("onStop")
        boot?.onBackground()
        plezy.memoryWatchdog.onBackground()
        if ((userLeaving || isFinishing) && !isInPictureInPictureMode) plezy.platform.appIcons.applyPending()
        super.onStop()
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        userLeaving = true
        pictureInPicture?.onUserLeaveHint()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        // Leaving while stopped: the window was closed rather than expanded.
        val stopped = !lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)
        launch?.event("pictureInPicture", mapOf("inPictureInPicture" to isInPictureInPictureMode, "stopped" to stopped))
        playerOrientation?.onPictureInPictureChanged(isInPictureInPictureMode)
        pictureInPicture?.onModeChanged(isInPictureInPictureMode, stopped)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        playerOrientation?.onConfigurationChanged(newConfig)
        launch?.event(
            "configuration",
            mapOf(
                "rotation" to ContextCompat.getDisplayOrDefault(this).rotation,
                "widthDp" to newConfig.screenWidthDp,
                "heightDp" to newConfig.screenHeightDp,
            ),
        )
    }

    override fun onDestroy() {
        val plezy = plezy
        pictureInPicture?.detach()
        plezy.platform.externalPlayers.detach(this)
        plezy.platform.files.detach(this)
        plezy.downloads.permissions.detach(this)
        plezy.platform.notificationPermission.detach(this)
        if (plezy.platform.activityPictureInPicture === pictureInPicture) plezy.platform.activityPictureInPicture = null
        if (plezy.platform.playerOrientation === playerOrientation) plezy.platform.playerOrientation = null
        if (plezy.platform.activity === this) plezy.platform.activity = null
        if (isFinishing) {
            launch?.close()
            if (plezy.testLaunch === launch) plezy.testLaunch = null
        }
        super.onDestroy()
    }
}
