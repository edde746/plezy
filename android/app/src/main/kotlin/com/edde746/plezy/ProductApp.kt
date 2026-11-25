package com.edde746.plezy

import android.content.Context
import androidx.core.content.pm.PackageInfoCompat
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.DevicePlatform
import com.edde746.plezy.app.RootScreen
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.app.Startup
import com.edde746.plezy.crash.ReleaseChannel
import com.edde746.plezy.crash.StartupMark
import com.edde746.plezy.crash.StartupMarks
import com.edde746.plezy.crash.crashReports
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.downloads.android.AndroidDownloads
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.importer.android
import com.edde746.plezy.secrets.AndroidSecretStore
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/**
 * The product in this process: the shared core ([AppBootstrap.product]) on the device's database and the Android
 * Keystore secret store, and the root over it ([root]): the splash, which names the start's steps ([Startup], begun
 * first), then the app; the first start imports the data Plezy's earlier releases left in this app's directories.
 * Built on the main thread when the first activity needs it and kept for the life of the process, so an activity that
 * comes back (a relaunch after Back, a recreation) shows the app as it was. The running app's theme is kept as the next
 * start's launch colour ([SplashTheme]).
 *
 * @param slowStartMillis a debug launch's slow start (`--dev-slow-start` in the `dev` extra); 0 otherwise.
 */
internal class ProductApp(
    context: Context,
    platform: AndroidPlatform,
    version: String,
    flavor: BuildFlavor,
    network: ProcessNetwork,
    slowStartMillis: Long,
) {
    private val startup = Startup(slowStartMillis).also { StartupMarks.mark(StartupMark.APP_START) }

    /**
     * The shared core: the activity tells it when the app comes to the foreground, the process when the network changes.
     * It sends crash reports to this build's endpoint while they are on; in a debug build a coroutine that throws ends
     * the process.
     */
    val boot = AppBootstrap.product(
        DatabaseFactory(context), AndroidSecretStore(context), flavor, version, startup, development = BuildConfig.DEBUG,
        earlierRelease = EarlierReleaseLocations.android(context), downloadTempDirectory = AndroidDownloads.tempDirectory(context),
        // As a failed start's record names the build: the installed versionCode, an ABI split's own.
        buildLabel = "$version+${PackageInfoCompat.getLongVersionCode(context.packageManager.getPackageInfo(context.packageName, 0))}",
    ).also { boot ->
        network.tell(boot)
        // The APK is the same on phones and TVs, and so is its channel.
        boot.graph.followCrashReports(context, boot.crashReports(ReleaseChannel.of(flavor, DevicePlatform.ANDROID)))
    }
    val root = RootSession(boot.graph, platform, startup)

    init {
        val appContext = context.applicationContext
        boot.graph.scope.launch {
            root.screen.collectLatest { screen ->
                val app = (screen as? RootScreen.Main)?.app ?: return@collectLatest
                // The next cold start's launch colour, as the theme changes; the window on screen takes it now.
                app.appearance.collect { SplashTheme.save(appContext, it.theme, platform.activity) }
            }
        }
    }
}
