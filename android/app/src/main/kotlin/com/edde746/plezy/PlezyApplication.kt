package com.edde746.plezy

import android.app.ActivityManager
import android.app.Application
import android.os.Process
import com.edde746.plezy.crash.MemoryPressure
import com.edde746.plezy.crash.RssPolicy
import com.edde746.plezy.crash.RssWatchdog
import com.edde746.plezy.ui.image.ImageMemory
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import java.io.File
import java.io.IOException
import android.app.LocaleManager
import android.content.res.Configuration
import android.content.res.Resources
import android.os.Build
import android.view.accessibility.AccessibilityManager
import android.view.accessibility.CaptioningManager
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.downloads.android.AndroidDownloads
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.DeviceRegion
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.mpv.MpvNativeLibraries
import com.edde746.plezy.playback.SystemMediaAccessibility
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.PerfProbe

/**
 * The process: one [platform], and the product ([product], built when the first activity shows it) or a debug build's
 * [testLaunch]. Both outlive the activity, so a recreated or relaunched activity shows the app as it was. The process
 * hears the system's settings ([SystemInputs]) and the default network ([network]) from its start, whatever starts it.
 */
class PlezyApplication : Application() {
    internal val platform: AndroidPlatform by lazy { AndroidPlatform(this, downloads) }

    /** As shown in About. */
    internal val version: String by lazy { packageManager.getPackageInfo(packageName, 0).versionName ?: "dev" }

    /** Where this build is distributed: -Pplezy.flavor (android/app/build.gradle.kts). */
    internal val flavor: BuildFlavor = BuildFlavor.valueOf(BuildConfig.BUILD_FLAVOR)

    // A debug launch may slow the product's start.
    private val productApp = lazy { ProductApp(this, platform, version, flavor, network, testLaunch?.slowStartMillis ?: 0) }

    internal val product: ProductApp by productApp

    /** The default network, for every shared core in the process (from [onCreate] on). */
    internal val network: ProcessNetwork by lazy {
        ProcessNetwork(this) { listOfNotNull(productApp.takeIf { it.isInitialized() }?.value?.boot, testLaunch?.boot) }
    }

    /** Downloads' platform and worker host. */
    internal val downloads: AndroidDownloads by lazy { AndroidDownloads(this, isTelevision(this)) { product } }

    /** The debug launch the activity shows, if any; each fresh launch replaces it. */
    internal var testLaunch: TestLaunch? = null

    /** An activity of this process has drawn its first frame ([com.edde746.plezy.crash.StartupMark.FIRST_FRAME]). */
    internal var drewFirstFrame = false

    override fun onCreate() {
        super.onCreate()
        Log.sink = Log.Sink { level, tag, message, error ->
            val priority = when (level) {
                Log.Level.DEBUG -> android.util.Log.DEBUG
                Log.Level.INFO -> android.util.Log.INFO
                Log.Level.WARN -> android.util.Log.WARN
                Log.Level.ERROR -> android.util.Log.ERROR
            }
            android.util.Log.println(priority, tag, if (error != null) "$message\n$error" else message)
        }
        // The previous process's last marks are read before this one's first.
        PreviousExit.keepStartupMarks(this)
        PreviousExit.keepPreviousPlayback(this)
        MpvNativeLibraries.onLoaded = NativeModuleCache::invalidate
        reportSystemInputs()
        network.start()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // The system's languages or region changed, or this app's language in the system settings (Android 13+).
        InterfaceLocale.setSystemLanguages(languages(newConfig))
        DeviceRegion.setSystemRegion(systemRegion())
    }

    private val memoryPressure = MemoryPressure()

    /**
     * Evicts the image caches before the process's memory gets it killed ([RssWatchdog]): above 45 % of the device's RAM
     * (within 512 MiB..1.5 GiB), checked every 15 s on low-end hardware, 30 s otherwise; above 35 % as the app goes to
     * the background ([PlezyActivity.onStop]); at once on the system's memory pressure. Checking from the first activity
     * on ([armMemoryWatchdog]).
     */
    internal val memoryWatchdog: RssWatchdog by lazy {
        val activities = getSystemService(ActivityManager::class.java)
        val total = ActivityManager.MemoryInfo().also(activities::getMemoryInfo).totalMem.takeIf { it > 0 }
        val lowEnd = RssPolicy.lowEndAndroid(Process.is64Bit(), activities.isLowRamDevice, total)
        RssWatchdog(RssPolicy.android(total, lowEnd), { procStatusKb("VmRSS")?.let { it * 1024 } }, { ImageMemory.bytes }, ImageMemory::evict)
    }
    private var memoryWatchdogArmed = false

    /** Starts the memory watchdog's checks, once per process. Main thread. */
    internal fun armMemoryWatchdog() {
        if (memoryWatchdogArmed) return
        memoryWatchdogArmed = true
        MainScope().launch { memoryWatchdog.run() }
    }

    /**
     * The system is running low on memory while the app runs: the mpv engines narrow their demuxer cache
     * ([MpvPlayerEngine.trimMemory]), and the decoded images go ([RssWatchdog.onMemoryPressure]), recorded with what was
     * held before and after ([MemoryPressure]) for a crash report.
     */
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        MpvPlayerEngine.trimMemory(level)
        @Suppress("DEPRECATION")
        if (level == TRIM_MEMORY_RUNNING_LOW || level == TRIM_MEMORY_RUNNING_CRITICAL) recordMemoryPressure()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        @Suppress("DEPRECATION")
        MpvPlayerEngine.trimMemory(TRIM_MEMORY_RUNNING_LOW)
        recordMemoryPressure()
    }

    /** The process's resident memory now and at its peak (`VmRSS`, `VmHWM`), the image cache and the playback's state. */
    private fun recordMemoryPressure() {
        val memory = listOfNotNull(
            procStatusKb("VmRSS")?.let { "rssMb" to (it shr 10) },
            procStatusKb("VmHWM")?.let { "maxRssMb" to (it shr 10) },
        ).toMap()
        memoryPressure.onPressure(memory + ImageMemory.pressureData(after = false) + MemoryPressure.currentPlayback()) {
            memoryWatchdog.onMemoryPressure()
            ImageMemory.pressureData(after = true)
        }
    }

    /** The value of [key] in `/proc/self/status`, in kB; null when it can't be read. */
    private fun procStatusKb(key: String): Long? = try {
        File("/proc/self/status").readLines().firstOrNull { it.startsWith("$key:") }
            ?.substringAfter(':')?.trim()?.substringBefore(' ')?.toLongOrNull()
    } catch (e: IOException) {
        Log.d("memory", e) { "could not read the process's memory" }
        null
    }

    /**
     * The system's settings the shared code follows ([SystemInputs]), as the process starts: the activity, or WorkManager
     * for the download worker without one. The languages and the region again on each configuration change; Caption
     * preferences' switch and, on Android 13+, Audio description (for the track choice) again whenever either changes.
     */
    private fun reportSystemInputs() {
        val captioning = getSystemService(CaptioningManager::class.java)
        val accessibility = getSystemService(AccessibilityManager::class.java)
        fun audioDescriptions() = Build.VERSION.SDK_INT >= 33 && accessibility.isAudioDescriptionRequested
        SystemInputs.report(languages(resources.configuration), systemRegion(), captioning.isEnabled, audioDescriptions())
        fun reportMediaAccessibility() = SystemMediaAccessibility.report(captioning.isEnabled, audioDescriptions())
        captioning.addCaptioningChangeListener(object : CaptioningManager.CaptioningChangeListener() {
            override fun onEnabledChanged(enabled: Boolean) = reportMediaAccessibility()
        })
        if (Build.VERSION.SDK_INT >= 33) accessibility.addAudioDescriptionRequestedChangeListener(mainExecutor) { reportMediaAccessibility() }
    }

    /** The languages the system asks this app for, most preferred first (the per-app language first, where set). */
    private fun languages(configuration: Configuration): List<String> {
        val locales = configuration.locales
        return List(locales.size()) { locales[it].toLanguageTag() }
    }

    /**
     * The system's region, for streams' country lists: its first language's country. Not this process's locales, which
     * Android 13+ starts with the app's own language when the user picks one in the system settings.
     */
    private fun systemRegion(): String? {
        val locales = if (Build.VERSION.SDK_INT >= 33) getSystemService(LocaleManager::class.java).systemLocales else Resources.getSystem().configuration.locales
        return locales[0]?.country
    }
}

/**
 * What a debug build's launch intent asks for beyond the product (the test harness): a dev session instead of the
 * product, more mpv options, a test report, perf marks. `testLaunch(application, intent)` reads it from the extras
 * (src/debug); in release builds it returns null (src/release), so they contain none of it.
 */
internal interface TestLaunch {
    /** The launch runs no product: a dev session instead, or extras that can't run, which end the launch. */
    val dev: Boolean

    /** The dev session's shared core, once it is built; null for a launch of the product. */
    val boot: AppBootstrap?

    /** The dev session's app once it has started; null before. Compose state. */
    val devApp: AppSession?

    /** The product's start takes this many milliseconds longer (`--dev-slow-start`); 0 otherwise. */
    val slowStartMillis: Long

    /** Collects where the named controls are and which has focus, for the report; null without a report. */
    val probe: LayoutProbe?

    /** Marks when the screens first draw their content, for the perf runs; null without `perf`. */
    val perfProbe: PerfProbe?

    /** The product runs: the report samples its root. */
    fun attachProduct(root: RootSession)

    /** An activity event (start, stop, a rotation), for the report. */
    fun event(name: String, detail: Map<String, Any?> = emptyMap())

    /** The launch is over (its activity finished): ends the dev session and the report. */
    fun close()
}
