package com.edde746.plezy.crash

import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.DevicePlatform
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Redactor
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

/**
 * This build's crash-report endpoint: a Sentry DSN, or blank for a build that never sends a report, and the git
 * [commit] it was built from (blank when unknown). Only the release workflow builds with a DSN; a DSN ships in the
 * binary, as in every app that reports to Sentry.
 */
data class CrashReportConfig(val dsn: String = "", val commit: String = "") {
    override fun toString(): String = "CrashReportConfig(dsn=${if (dsn.isBlank()) "none" else "set"}, commit=$commit)"
}

/**
 * When this app process sends crash reports, and where to. The product reports to its build's DSN
 * ([BuildCrashReportConfig]), a development session only to the endpoint its launch names; on each device only while
 * [AppSettings.crashReporting] is on, which it is by default.
 *
 * The platform starts its crash reporter (Sentry) whenever [active] has a DSN and closes it whenever it has none, so a
 * device that turned reports off records no crash to send later, and drops any event that comes while it has none. It
 * also sends each of [failures] as an error report, and installs [CrashCapture.sink] while it runs. Every report says
 * it comes from [releaseName] on [channel], and its text goes through [scrub]; [CrashFilter] drops the noise.
 *
 * An earlier start's failure ([startupFailures]) is sent once the reporter runs (or marked as never to be sent, with
 * reports off or none in this build), then shown on the Logs screen.
 */
class CrashReports internal constructor(
    private val settings: DeviceSettingsRepository,
    private val dsn: String,
    /** Sentry's release, [releaseNameOf] this build's commit (`release` clashes with ObjC's). */
    val releaseName: String,
    /** Where this build is distributed: the reports' environment and dist. */
    val channel: ReleaseChannel,
    scope: CoroutineScope,
    failures: Flow<Throwable>,
    startupFailures: StartupFailures? = null,
) {
    /**
     * The DSN while this device sends crash reports; null while the setting is off, before it is read, and always in
     * a build without one.
     */
    val active: StateFlow<String?> = if (dsn.isBlank()) {
        MutableStateFlow<String?>(null).asStateFlow()
    } else {
        settings.observe(AppSettings.crashReporting).map { if (it) dsn else null }.stateIn(scope, SharingStarted.Eagerly, null)
    }

    /**
     * Each exception the app survived ([FailureBoundary]: a coroutine that threw in the product) while [active] has a
     * DSN, which the platform sends as an error report, scrubbed as a crash's; none while this device's reports are
     * off, and none in a build without a DSN.
     */
    val failures: Flow<Throwable> = failures.filter { active.value != null }

    init {
        if (startupFailures != null) scope.launch { settle(startupFailures) }
    }

    /** Sends an earlier start's failure once the reporter runs ([StartupFailures.flush]), then reads it for display. */
    private suspend fun settle(startupFailures: StartupFailures) {
        val optedIn = settings.settings().crashReports
        val canReport = dsn.isNotBlank()
        val sink = if (optedIn && canReport) CrashCapture.awaitSink(REPORTER_WAIT) else null
        startupFailures.flush(optedIn, canReport, sink?.let { s -> { record -> s.capture(record.report()) } })
        startupFailures.consumePrevious()
    }

    companion object {
        /** How long an earlier start's failure waits for the reporter to start before it is kept for the next start. */
        private val REPORTER_WAIT = 10.seconds

        /** `plezy@` and the first 7 characters of [commit], or `plezy@unknown` for a build without one. */
        fun releaseNameOf(commit: String): String = "plezy@" + commit.trim().take(7).ifEmpty { "unknown" }

        /**
         * A crash report's free text (exception messages, breadcrumbs, thread names, file paths): the user's [home]
         * directory becomes `~`, so no account name is sent, then [Redactor.redact] removes every URL beyond its origin
         * (addon URLs carry API keys in their paths) and every key-shaped value.
         */
        fun scrub(text: String, home: String?): String {
            var out = text
            if (home != null && home.length > 1) {
                out = out.replace(home, "~", ignoreCase = true)
                val other = if ('\\' in home) home.replace('\\', '/') else home.replace('/', '\\')
                out = out.replace(other, "~", ignoreCase = true)
            }
            return Redactor.redact(out)
        }
    }
}

/**
 * Where a build is distributed, as its crash reports name it: Sentry's [environment] and [dist] (null: none). A release
 * build's comes from its flavor and platform ([of]); a development session's is [DEVELOPMENT].
 */
data class ReleaseChannel(val environment: String, val dist: String? = null) {
    companion object {
        /** A development session's: environment `development`, no dist. */
        val DEVELOPMENT: ReleaseChannel = ReleaseChannel("development")

        /**
         * A [flavor] build's on [platform] (a [DevicePlatform] name); [arch] (the JVM's `os.arch`) names a desktop
         * build's package. Google Play's is `play-store`, Amazon's `amazon`, the App Store's `app-store` (environment
         * and dist alike). The GitHub release's builds, and the Microsoft Store's package, which is made from them, are
         * environment `github` with a dist per package: `github-android-apk`, `github-ios` (iPad too), `github-macos`,
         * `github-tvos`, `github-windows-x64`, `github-linux-arm64` and so on.
         */
        fun of(flavor: BuildFlavor, platform: String, arch: String? = null): ReleaseChannel {
            val android = platform == DevicePlatform.ANDROID || platform == DevicePlatform.ANDROID_TV
            val desktop = platform == DevicePlatform.WINDOWS || platform == DevicePlatform.LINUX
            return when {
                flavor == BuildFlavor.AMAZON -> store("amazon")
                flavor == BuildFlavor.STORE && android -> store("play-store")
                flavor == BuildFlavor.STORE && !desktop -> store("app-store")
                else -> ReleaseChannel(
                    "github",
                    "github-" + when {
                        android -> "android-apk"
                        platform == DevicePlatform.IPADOS -> DevicePlatform.IOS
                        desktop -> "$platform-${desktopArch(arch)}"
                        else -> platform
                    },
                )
            }
        }

        private fun store(name: String) = ReleaseChannel(name, name)

        /** The release's name for a JVM `os.arch`: `x64` or `arm64`; another as the JVM names it. */
        private fun desktopArch(arch: String?): String = when (val name = arch.orEmpty().lowercase()) {
            "amd64", "x86_64" -> "x64"
            "aarch64" -> "arm64"
            else -> name
        }
    }
}

/**
 * This process's crash reports: to [dsn] (by default this build's) and labelled with [channel], while this device's
 * setting is on, with the exceptions its failure boundary survived; released as this build's commit.
 */
fun AppBootstrap.crashReports(
    channel: ReleaseChannel,
    dsn: String = BuildCrashReportConfig.config.dsn,
): CrashReports = CrashReports(
    graph.data.deviceSettings, dsn, CrashReports.releaseNameOf(BuildCrashReportConfig.config.commit), channel,
    graph.scope, failures.failures, graph.startupFailures,
)
