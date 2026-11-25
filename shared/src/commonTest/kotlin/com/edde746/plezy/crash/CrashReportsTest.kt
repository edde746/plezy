@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.crash

import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.DevicePlatform
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.files.Path
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class CrashReportsTest {
    private val dsn = "https://public@crashes.example/1"

    private fun TestScope.data() = LocalData(
        inMemoryDatabase(), { 1_790_000_000_000L },
        StandardTestDispatcher(testScheduler),
    )

    /** An earlier start's failure on disk, unreported, and the [CrashReports] of the next start reading it. */
    private fun TestScope.nextStart(taken: Boolean): Triple<StartupFailures, String, MutableList<CrashReport>> {
        val directory = Path(SystemTemporaryDirectory, "crash-reports-${Random.nextLong().toULong()}").toString()
        StartupFailures(directory).recordFailingStart(
            StartupFailureRecord.of(StartupPhaseException(StartupPhase.DATABASE, IllegalStateException("boom")), "1.0.0", "test"),
        )
        val failures = StartupFailures(directory)
        CrashReports(data().deviceSettings, dsn, "plezy@1.0.0", ReleaseChannel.DEVELOPMENT, backgroundScope, emptyFlow(), failures)
        runCurrent()
        assertNull(failures.pending, "the record waits for the reporter to start")
        val sent = mutableListOf<CrashReport>()
        CrashCapture.sink = CrashCapture.Sink { sent += it; taken }
        try {
            runCurrent()
        } finally {
            CrashCapture.sink = null
        }
        return Triple(failures, directory, sent)
    }

    @Test
    fun anEarlierFailureTheReporterTookIsShownAsReportedAndLeavesTheDisk() = runTest {
        val (failures, directory, sent) = nextStart(taken = true)
        assertEquals("Startup failed: [database] IllegalStateException: boom", sent.single().message)
        assertEquals(true, assertNotNull(failures.pending).reported)
        assertNull(StartupFailures(directory).peek())
    }

    @Test
    fun anEarlierFailureTheReporterDidNotTakeIsShownAndKeptForTheNextStart() = runTest {
        val (failures, directory, sent) = nextStart(taken = false)
        assertEquals(1, sent.size)
        assertEquals(false, assertNotNull(failures.pending).reported)
        assertEquals(false, assertNotNull(StartupFailures(directory).peek()).reported)
    }

    @Test
    fun scrubbedTextHasNoRegisteredTokenOrServer() {
        LogRedaction.registerServer("https://media.example.org", "plexTok3n")
        try {
            assertEquals(
                "request with … to … failed",
                CrashReports.scrub("request with plexTok3n to media.example.org failed", home = null),
            )
        } finally {
            LogRedaction.clear()
        }
    }

    @Test
    fun reportsGoToTheDsnWhileTheDeviceSettingIsOn() = runTest {
        val data = data()
        val reports = CrashReports(data.deviceSettings, dsn, "plezy@1.0.0", ReleaseChannel.DEVELOPMENT, backgroundScope, emptyFlow())
        runCurrent()
        assertEquals(dsn, reports.active.value, "on while the setting is unset")

        data.deviceSettings.set(AppSettings.crashReporting, false)
        runCurrent()
        assertNull(reports.active.value)

        data.deviceSettings.set(AppSettings.crashReporting, true)
        runCurrent()
        assertEquals(dsn, reports.active.value)
        data.close()
    }

    @Test
    fun aBuildWithoutADsnNeverReports() = runTest {
        val data = data()
        data.deviceSettings.set(AppSettings.crashReporting, true)
        val reports = CrashReports(data.deviceSettings, " ", "plezy@1.0.0", ReleaseChannel.DEVELOPMENT, backgroundScope, emptyFlow())
        runCurrent()
        assertNull(reports.active.value)
        data.close()
    }

    @Test
    fun aCoroutineTheProductSurvivedIsReportedOnlyWhileTheDeviceSettingIsOn() = runTest {
        val data = data()
        val boundary = FailureBoundary(crash = false)
        val app = CoroutineScope(backgroundScope.coroutineContext + Job(backgroundScope.coroutineContext[Job]) + boundary)
        val reports = CrashReports(data.deviceSettings, dsn, "plezy@1.0.0", ReleaseChannel.DEVELOPMENT, app, boundary.failures)
        val sent = mutableListOf<String?>()
        backgroundScope.launch { reports.failures.collect { sent += it.message } }
        // A store's scope, as every store builds it from the app's.
        val store = app.childScope()
        runCurrent()

        store.launch { error("while on") }
        runCurrent()
        data.deviceSettings.set(AppSettings.crashReporting, false)
        runCurrent()
        store.launch { error("while off") }
        runCurrent()

        assertEquals(listOf<String?>("while on"), sent)
        data.close()
    }

    @Test
    fun scrubbedTextHasNoAddonPathAndNoHomeDirectory() {
        val addon = "https://addon.example/key=ABCDEFGHIJKLMNOPQRSTUVWXYZ234567ABCDEFGHIJKLMNOPQRST/manifest.json"
        val windows = CrashReports.scrub("""failed: $addon while reading C:\Users\Jane Doe\AppData\Roaming\Plezy\plezy.db""", """C:\Users\Jane Doe""")
        assertEquals("""failed: https://addon.example/… while reading ~\AppData\Roaming\Plezy\plezy.db""", windows)

        val slashes = CrashReports.scrub("open c:/users/jane doe/Videos/a.mkv", """C:\Users\Jane Doe""")
        assertEquals("open ~/Videos/a.mkv", slashes)

        val linux = CrashReports.scrub("/home/jane/.local/share/plezy/x.db", "/home/jane")
        assertTrue(linux.startsWith("~/"))
        assertFalse("jane" in CrashReports.scrub("/home/jane/x", "/home/jane"))
        assertEquals("/data/user/0/x", CrashReports.scrub("/data/user/0/x", "/"), "a root home changes nothing")
    }

    @Test
    fun `the release is the builds commit cut to 7 characters or unknown without one`() {
        assertEquals("plezy@6cc283a", CrashReports.releaseNameOf("6cc283a7d4f0e1b2c3d4e5f60718293a4b5c6d7e"))
        assertEquals("plezy@abc", CrashReports.releaseNameOf("abc"))
        assertEquals("plezy@unknown", CrashReports.releaseNameOf(""))
        assertEquals("plezy@unknown", CrashReports.releaseNameOf("  \n"))
    }

    @Test
    fun `each release channel names its environment and dist as the earlier releases did`() {
        fun channel(flavor: BuildFlavor, platform: String, arch: String? = null) = ReleaseChannel.of(flavor, platform, arch).let { "${it.environment} ${it.dist}" }
        assertEquals("play-store play-store", channel(BuildFlavor.STORE, DevicePlatform.ANDROID))
        assertEquals("play-store play-store", channel(BuildFlavor.STORE, DevicePlatform.ANDROID_TV))
        assertEquals("amazon amazon", channel(BuildFlavor.AMAZON, DevicePlatform.ANDROID_TV))
        assertEquals("app-store app-store", channel(BuildFlavor.STORE, DevicePlatform.IPADOS))
        assertEquals("app-store app-store", channel(BuildFlavor.STORE, DevicePlatform.TVOS))
        assertEquals("github github-android-apk", channel(BuildFlavor.SIDELOADED, DevicePlatform.ANDROID))
        assertEquals("github github-android-apk", channel(BuildFlavor.SIDELOADED, DevicePlatform.ANDROID_TV))
        assertEquals("github github-ios", channel(BuildFlavor.SIDELOADED, DevicePlatform.IOS))
        assertEquals("github github-ios", channel(BuildFlavor.SIDELOADED, DevicePlatform.IPADOS), "the same IPA")
        assertEquals("github github-macos", channel(BuildFlavor.SIDELOADED, DevicePlatform.MACOS))
        assertEquals("github github-tvos", channel(BuildFlavor.SIDELOADED, DevicePlatform.TVOS))
        assertEquals("github github-windows-x64", channel(BuildFlavor.SIDELOADED, DevicePlatform.WINDOWS, "amd64"))
        assertEquals("github github-windows-arm64", channel(BuildFlavor.STORE, DevicePlatform.WINDOWS, "aarch64"), "the Store's package is the release's build")
        assertEquals("github github-linux-x64", channel(BuildFlavor.SIDELOADED, DevicePlatform.LINUX, "x86_64"))
        assertEquals("github github-linux-arm64", channel(BuildFlavor.SIDELOADED, DevicePlatform.LINUX, "aarch64"))
        assertEquals("development null", ReleaseChannel.DEVELOPMENT.let { "${it.environment} ${it.dist}" })
    }
}
