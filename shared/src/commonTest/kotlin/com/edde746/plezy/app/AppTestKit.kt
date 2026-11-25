package com.edde746.plezy.app

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.music.CarRestrictionsSource
import com.edde746.plezy.music.FakeAudioPlayer
import com.edde746.plezy.music.FakeMusicSystem
import com.edde746.plezy.music.MusicSystem
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.output.DisplayInfo
import com.edde746.plezy.playback.output.OutputPlan
import com.edde746.plezy.playback.output.PlaybackOutputHost
import com.edde746.plezy.playback.players.ExternalPlayerLauncher
import com.edde746.plezy.playback.session.ScriptedEngine
import com.edde746.plezy.presentation.homescreen.HomeScreen
import com.edde746.plezy.presentation.homescreen.HomeScreenArtwork
import com.edde746.plezy.presentation.homescreen.HomeScreenShelf
import com.edde746.plezy.presentation.player.MediaCommandHandler
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.player.PlayerStore
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.secrets.SecretStore
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.time.Clock

/**
 * The OS side of the tests' app: every playback, fullscreen change and release lands in [log] in the order it happened,
 * a playback's entries prefixed with its number (`1: engine released`). With [externalPlayers], the device has external
 * players.
 * [opensUrls] false is a device where nothing opens a link (an Apple TV): [opened] still records what was asked. With
 * [homeScreen], the device is a TV with a home screen. [formFactor]: a desktop unless a test says otherwise. With
 * [car], the device is a car (Android Automotive) whose car service that is.
 */
internal class FakeAppPlatform(
    override val externalPlayers: ExternalPlayerLauncher? = null,
    var opensUrls: Boolean = true,
    override val homeScreen: FakeHomeScreen? = null,
    override val formFactor: FormFactor = FormFactor.DESKTOP,
    override val appleTv: Boolean = false,
    private val car: CarRestrictionsSource? = null,
) : AppPlatform {
    override val musicSystem: MusicSystem get() = car?.let(::FakeMusicSystem) ?: super.musicSystem

    val log = mutableListOf<String>()
    val playbacks = mutableListOf<FakePlatformPlayback>()
    val opened = mutableListOf<String>()
    val clipboard = mutableListOf<String>()
    var exits = 0

    /** Every ask for the notification permission (Android 13+'s system prompt). */
    var notificationAsks = 0

    override val notificationPermission = NotificationPermission { notificationAsks++ }

    override val device = DeviceIdentity(platform = "Linux", platformVersion = "6.1", deviceModel = "Linux", deviceName = "test-box", isTv = false)

    override val playerConfig = PlayerConfig.defaults(InputProfile.DESKTOP, doubleClickIntervalMillis = 500)

    override fun createPlayback(settings: DeviceSettings): PlatformPlayback = FakePlatformPlayback(playbacks.size + 1, log).also { playbacks += it }

    override fun createMusicAudioPlayer(): AudioPlayer = FakeAudioPlayer()

    /** The window's fullscreen as [setFullscreen] left it, or as a test sets it (Start in fullscreen, F11 at a screen). */
    var windowFullscreen = false

    override val isFullscreen get() = windowFullscreen

    override fun setFullscreen(fullscreen: Boolean) {
        log += "fullscreen $fullscreen"
        windowFullscreen = fullscreen
    }

    override fun openUrl(url: String): Boolean {
        opened += url
        return opensUrls
    }

    override fun setClipboardText(text: String, sensitive: Boolean) {
        clipboard += text
    }

    override fun deviceFeatures() =
        DeviceFeatures(hardwareDecoding = true, hdr = false, matchFrameRate = false, audioPassthrough = false)

    /** The tests' app bundles no resources. */
    override fun bundledTexts(folder: String): List<BundledText> = emptyList()

    override fun exit() {
        exits++
    }
}

/** A TV's home screen drawing [artwork]: [published] is every shelf the app published, in order. */
internal class FakeHomeScreen(override val artwork: HomeScreenArtwork = HomeScreenArtwork.LANDSCAPE) : HomeScreen {
    val published = mutableListOf<HomeScreenShelf>()

    override fun publish(shelf: HomeScreenShelf) {
        published += shelf
    }
}

/**
 * One playback's engine (a [ScriptedEngine]), media controls and display output, logging what happens to them; [awake]
 * is every [keepDisplayAwake] it got, in order.
 */
internal class FakePlatformPlayback(private val number: Int, private val log: MutableList<String>) : PlatformPlayback {
    val scripted = ScriptedEngine()
    var attached: PlayerStore? = null
        private set
    val awake = mutableListOf<Boolean>()

    override val engine: PlayerEngine = object : PlayerEngine by scripted {
        override fun release() {
            scripted.release()
            log += "$number: engine released"
        }
    }

    override val hardwareDecoder = HardwareDecoder.WINDOWS

    override val mediaControls = object : MediaControlsHost {
        override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) = Unit

        override fun hide() {
            log += "$number: controls hidden"
        }
    }

    override val output = object : PlaybackOutputHost {
        override suspend fun display() = DisplayInfo(modes = emptyList(), current = null, hdrSupported = false, hdrEnabled = false)

        override suspend fun apply(plan: OutputPlan) = true

        override fun restore() {
            log += "$number: display restored"
        }
    }

    override fun attach(store: PlayerStore) {
        attached = store
        log += "$number: attached"
    }

    override fun keepDisplayAwake(awake: Boolean) {
        this.awake += awake
    }

    override fun release() {
        log += "$number: platform released"
    }
}

/**
 * An [AppGraph] on the test's scheduler: [data] (by default an in-memory database of its own), [http] (by default a
 * client every request of which gets a 404), [clock] (by default the system's), [secrets] (by default in memory),
 * [earlierRelease] (by default none), [filesDirectory] (by default the system's temporary directory), and a scope that
 * ends with the test.
 */
internal fun TestScope.testGraph(
    data: LocalData = testData(),
    http: HttpClient = HttpClient(MockEngine { respond("", HttpStatusCode.NotFound) }),
    clock: Clock = Clock.System,
    secrets: SecretStore = MemorySecretStore(),
    earlierRelease: EarlierReleaseLocations? = null,
    filesDirectory: String = SystemTemporaryDirectory.toString(),
): AppGraph {
    return AppGraph(
        data = data,
        secrets = secrets,
        flavor = BuildFlavor.SIDELOADED,
        appVersion = "test",
        http = http,
        scope = CoroutineScope(backgroundScope.coroutineContext + Job(backgroundScope.coroutineContext[Job])),
        clock = clock,
        filesDirectory = filesDirectory,
        requestDispatcher = StandardTestDispatcher(testScheduler),
        timeSource = testScheduler.timeSource,
        earlierRelease = earlierRelease,
    )
}

/** Local data in an in-memory database on the test's scheduler. */
internal fun TestScope.testData(): LocalData {
    val clock = TestClock()
    return LocalData(inMemoryDatabase(), { clock.now }, StandardTestDispatcher(testScheduler))
}
