package com.edde746.plezy.playback.players

import com.edde746.plezy.backend.ExternalPlaybackTarget
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaPartTimeline
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomPlayerType
import com.edde746.plezy.settings.ExternalPlayerChoice
import com.edde746.plezy.strings.T
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Instant

class ExternalPlayerServiceTest {
    private class FakeClock(var now: Instant = Instant.fromEpochMilliseconds(1_790_000_000_000)) : Clock {
        override fun now(): Instant = now
    }

    /** Records each launch; reports [ended] through the last launch's callback when a test calls [finish]. */
    private class FakeLauncher(override val platform: ExternalPlayerPlatform, var status: ExternalLaunchStatus = ExternalLaunchStatus.LAUNCHED) :
        ExternalPlayerLauncher {
        override val probe: PlayerInstallProbe = FakeProbe(everything = true)
        val launches = mutableListOf<ExternalPlayerLaunch>()
        private var ended: ((ExternalPlaybackResult) -> Unit)? = null

        override suspend fun launch(launch: ExternalPlayerLaunch, ended: (ExternalPlaybackResult) -> Unit): ExternalLaunchStatus {
            launches += launch
            this.ended = ended
            return status
        }

        fun finish(result: ExternalPlaybackResult) = ended!!(result)
    }

    private class Server(val target: ExternalPlaybackTarget?) : FakeMediaBackend("srv") {
        val resolved = mutableListOf<Duration?>()

        override suspend fun resolveExternalPlayback(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, position: Duration?): ExternalPlaybackTarget? {
            resolved += position
            return target
        }
    }

    private val clock = FakeClock()

    private fun TestScope.data() = LocalData(inMemoryDatabase(), { 1_790_000_000_000L }, StandardTestDispatcher(testScheduler))

    private fun TestScope.service(launcher: FakeLauncher, data: LocalData = data()) = ExternalPlayerService(launcher, data.deviceSettings, clock)

    private fun movie(durationMs: Long? = null, viewOffsetMs: Long? = null, versions: List<MediaVersion>? = null) = MediaItem(
        id = "item-1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = " Inception ", year = 2010,
        durationMs = durationMs, viewOffsetMs = viewOffsetMs, mediaVersions = versions,
    )

    private fun episode(title: String? = null, season: Int? = null, index: Int? = null) = MediaItem(
        id = "ep", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, title = title, grandparentTitle = "The Office",
        parentIndex = season, index = index,
    )

    private val stacked = listOf(MediaPart(id = "11", durationMs = 3_000_000), MediaPart(id = "12", durationMs = 2_400_000))

    private fun link(result: String, session: String, query: String = "") =
        "plezy://external-player/$result/$session" + if (query.isEmpty()) "" else "?$query"

    /** Every result [service] reports from now on, as it reports it. */
    private fun TestScope.ended(service: ExternalPlayerService): MutableList<ExternalPlaybackEnded> {
        val seen = mutableListOf<ExternalPlaybackEnded>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { service.ended.collect { seen += it } }
        return seen
    }

    // ---- Start position (multi-part) ------------------------------------------------------------------------------

    @Test
    fun theResumePointIsTheStartUnlessTheHandedOverFileIsOneOfSeveral() {
        val resume = 50.minutes + 600_000.milliseconds
        assertEquals(resume, ExternalPlayerService.startPosition(resume, null))
        assertNull(ExternalPlayerService.startPosition(null, null))
        // 60 min into a 50 + 40 minute item: 10 minutes into the second file.
        assertEquals(10.minutes, ExternalPlayerService.startPosition(60.minutes, MediaPartTimeline.fromParts(stacked, 1)))
        // The first file doesn't hold minute 60: no start.
        assertNull(ExternalPlayerService.startPosition(60.minutes, MediaPartTimeline.fromParts(stacked, 0)))
        assertEquals(20.minutes, ExternalPlayerService.startPosition(20.minutes, MediaPartTimeline.fromParts(stacked, 0)))
    }

    // ---- Launch ---------------------------------------------------------------------------------------------------

    @Test
    fun androidHandsTheStreamTitleStartPackagesAndSubtitlesToTheIntent() = runTest {
        val data = data()
        data.deviceSettings.set(AppSettings.selectedExternalPlayer, ExternalPlayerChoice("mx_player", "MX Player"))
        val launcher = FakeLauncher(ExternalPlayerPlatform.ANDROID)
        val server = Server(
            ExternalPlaybackTarget(
                "http://srv/library/parts/1/file.mkv?X-Plex-Token=t",
                listOf(SubtitleSidecar("http://srv/sub.srt", title = " English ", isDefault = true), SubtitleSidecar("", title = "none")),
            ),
        )
        val outcome = service(launcher, data).launch(movie(viewOffsetMs = 90_000), server)

        assertEquals(ExternalLaunchOutcome.Launched, outcome)
        assertEquals(listOf<Duration?>(90_000.milliseconds), server.resolved)
        val launch = launcher.launches.single()
        assertEquals("http://srv/library/parts/1/file.mkv?X-Plex-Token=t", launch.url)
        assertEquals("Inception", launch.title)
        assertEquals(90_000, launch.startPositionMs)
        assertEquals(listOf("com.mxtech.videoplayer.ad", "com.mxtech.videoplayer.pro"), launch.packages)
        assertEquals(listOf(ExternalPlayerSubtitle("http://srv/sub.srt", "English", enabled = true)), launch.subtitles)
        data.close()
    }

    @Test
    fun androidReportsTheIntentResultWithWhatItWasLaunchedFor() = runTest {
        val data = data()
        val launcher = FakeLauncher(ExternalPlayerPlatform.ANDROID)
        val service = service(launcher, data)
        val seen = ended(service)
        val server = Server(ExternalPlaybackTarget("http://srv/v.mkv", partTimeline = MediaPartTimeline.fromParts(stacked, 1)))
        service.launch(movie(viewOffsetMs = 60.minutes.inWholeMilliseconds), server, mediaSourceId = "src")

        // The system default leaves the choice of app to Android.
        assertEquals(emptyList(), launcher.launches.single().packages)
        assertEquals(10.minutes.inWholeMilliseconds, launcher.launches.single().startPositionMs)
        launcher.finish(ExternalPlaybackResult(600_000, 2_400_000))
        val report = seen.single()
        assertEquals(ExternalPlaybackResult(600_000, 2_400_000), report.result)
        assertEquals("item-1", report.item.id)
        assertEquals(server, report.backend)
        assertEquals("src", report.mediaSourceId)
        assertEquals(1, report.partTimeline?.currentIndex)
        data.close()
    }

    @Test
    fun aDownloadPlaysItsFileWithItsSavedSubtitlesAsPathsOnItsFirstFilesClock() = runTest {
        val data = data()
        val launcher = FakeLauncher(ExternalPlayerPlatform.ANDROID)
        val service = service(launcher, data)
        val seen = ended(service)
        val item = movie(viewOffsetMs = 60.minutes.inWholeMilliseconds, versions = listOf(MediaVersion(id = "v", parts = stacked)))
        service.launch(
            item, backend = null, videoUrl = "file:///data/downloads/Movie.mkv",
            downloadedSubtitles = listOf(SubtitleSidecar("file:///data/downloads/Movie_subs/401%20en.srt")),
        )

        val launch = launcher.launches.single()
        assertEquals("file:///data/downloads/Movie.mkv", launch.url)
        assertEquals(listOf(ExternalPlayerSubtitle("/data/downloads/Movie_subs/401 en.srt", null, enabled = false)), launch.subtitles)
        // Minute 60 isn't in the first file.
        assertEquals(0, launch.startPositionMs)
        launcher.finish(ExternalPlaybackResult(null, null, completed = true))
        assertEquals(0, seen.single().partTimeline?.currentIndex)
        data.close()
    }

    @Test
    fun aMissingPackageOrAFailedLaunchSaysSo() = runTest {
        val data = data()
        data.deviceSettings.set(AppSettings.selectedExternalPlayer, ExternalPlayerChoice("vlc", "stored name"))
        val launcher = FakeLauncher(ExternalPlayerPlatform.ANDROID, ExternalLaunchStatus.NOT_INSTALLED)
        val service = service(launcher, data)
        val server = Server(ExternalPlaybackTarget("http://srv/v.mkv"))
        assertEquals(ExternalLaunchOutcome.NotLaunched(T.externalPlayer.appNotInstalled("VLC")), service.launch(movie(), server))
        launcher.status = ExternalLaunchStatus.FAILED
        assertEquals(ExternalLaunchOutcome.NotLaunched(T.externalPlayer.launchFailed), service.launch(movie(), server))
        data.close()
    }

    @Test
    fun anUnresolvedStreamSaysTheFileInfoIsMissing() = runTest {
        val launcher = FakeLauncher(ExternalPlayerPlatform.LINUX)
        val outcome = service(launcher).launch(movie(), Server(ExternalPlaybackTarget("")))
        assertEquals(ExternalLaunchOutcome.NotLaunched(T.messages.fileInfoNotAvailable), outcome)
        assertEquals(ExternalLaunchOutcome.NotLaunched(T.messages.fileInfoNotAvailable), service(launcher).launch(movie(), Server(null)))
        assertEquals(emptyList(), launcher.launches)
    }

    @Test
    fun aPlayerNotOfferedHereFailsWithoutLaunching() = runTest {
        // The system default stays the stored default on Apple TV, which has nothing to hand it to.
        val launcher = FakeLauncher(ExternalPlayerPlatform.TVOS)
        val outcome = service(launcher).launch(movie(), Server(ExternalPlaybackTarget("http://srv/v.mkv")))
        assertEquals(ExternalLaunchOutcome.NotLaunched(T.externalPlayer.launchFailed), outcome)
        assertEquals(emptyList(), launcher.launches)
    }

    @Test
    fun desktopPlayersAreStartedByTheirAttemptsAndACustomOneByItsName() = runTest {
        val data = data()
        val custom = ExternalPlayerChoice("c1", "My Player", isCustom = true, customValue = "myplayer", customType = CustomPlayerType.COMMAND)
        data.deviceSettings.set(AppSettings.selectedExternalPlayer, custom)
        val launcher = FakeLauncher(ExternalPlayerPlatform.LINUX)
        val service = service(launcher, data)
        assertEquals(ExternalLaunchOutcome.Launched, service.launch(movie(), Server(ExternalPlaybackTarget("http://srv/v.mkv"))))
        assertEquals(listOf<ExternalPlayerAttempt>(ExternalPlayerAttempt.Command(listOf("myplayer", "http://srv/v.mkv"))), launcher.launches.single().attempts)
        launcher.status = ExternalLaunchStatus.NOT_INSTALLED
        assertEquals(
            ExternalLaunchOutcome.NotLaunched(T.externalPlayer.appNotInstalled("My Player")),
            service.launch(movie(), Server(ExternalPlaybackTarget("http://srv/v.mkv"))),
        )
        data.close()
    }

    @Test
    fun iPhoneLaunchesAnXCallbackPlayerWithItsStartFileNameAndReturnLinks() = runTest {
        val data = data()
        data.deviceSettings.set(AppSettings.selectedExternalPlayer, ExternalPlayerChoice("infuse", "Infuse"))
        val launcher = FakeLauncher(ExternalPlayerPlatform.IOS)
        val service = service(launcher, data)
        val seen = ended(service)
        service.launch(movie(durationMs = 1_420_016, viewOffsetMs = 42_500), Server(ExternalPlaybackTarget("http://srv/library/parts/1/file.mkv?X-Plex-Token=t")))

        val session = (1_790_000_000_000L * 1000).toString(36)
        val attempt = launcher.launches.single().attempts.single() as ExternalPlayerAttempt.OpenUrl
        assertEquals(
            KnownPlayers.callbackPlayUri(
                "infuse",
                "http://srv/library/parts/1/file.mkv?X-Plex-Token=t",
                ExternalPlayerLaunchOptions(42_500, ExternalPlayerService.returnLinks(session), "Inception (2010).mkv"),
            ),
            attempt.url,
        )
        assertFalse(attempt.checkHandler)
        assertTrue(service.handleCallbackUrl(link("success", session, "position=600")))
        assertEquals(ExternalPlaybackResult(600_000, null), seen.single().result)
        data.close()
    }

    @Test
    fun aFailedXCallbackLaunchClearsItsSession() = runTest {
        val data = data()
        data.deviceSettings.set(AppSettings.selectedExternalPlayer, ExternalPlayerChoice("outplayer", "Outplayer"))
        val launcher = FakeLauncher(ExternalPlayerPlatform.IOS, ExternalLaunchStatus.NOT_INSTALLED)
        val service = service(launcher, data)
        val outcome = service.launch(movie(), Server(ExternalPlaybackTarget("http://srv/v.mkv")))
        assertEquals(ExternalLaunchOutcome.NotLaunched(T.externalPlayer.appNotInstalled("Outplayer")), outcome)
        assertFalse(service.handleCallbackUrl(link("success", (1_790_000_000_000L * 1000).toString(36))))
        data.close()
    }

    // ---- Return links ---------------------------------------------------------------------------------------------

    @Test
    fun cancelReportsThePositionThePlayerStoppedAtInSeconds() = runTest {
        val service = service(FakeLauncher(ExternalPlayerPlatform.IOS))
        val seen = ended(service)
        val session = service.beginCallbackSession("outplayer", movie(durationMs = 6_000_000), backend = null)
        assertTrue(service.handleCallbackUrl(link("cancel", session, "url=http%3A%2F%2Fsrv%2Fv.mkv&position=1234.5&duration=6000")))
        assertEquals(ExternalPlaybackResult(1_234_500, 6_000_000), seen.single().result)
    }

    @Test
    fun aReportedDurationMatchingTheRuntimeInMillisecondsSwitchesUnits() = runTest {
        val service = service(FakeLauncher(ExternalPlayerPlatform.IOS))
        val seen = ended(service)
        val session = service.beginCallbackSession("outplayer", movie(durationMs = 6_000_000), backend = null)
        service.handleCallbackUrl(link("cancel", session, "position=30000&duration=6000000"))
        assertEquals(ExternalPlaybackResult(30_000, 6_000_000), seen.single().result)
    }

    @Test
    fun successWithoutAPositionMeansFinishedForPlayersThatSaySoOnCompletion() = runTest {
        val service = service(FakeLauncher(ExternalPlayerPlatform.IOS))
        val seen = ended(service)
        service.handleCallbackUrl(link("success", service.beginCallbackSession("outplayer", movie(durationMs = 100_000), null)))
        service.handleCallbackUrl(link("success", service.beginCallbackSession("infuse", movie(durationMs = 100_000), null), "lastPlayedUrl=x"))
        // VLC calls x-success on every stop and appends nothing: stopped somewhere unknown.
        service.handleCallbackUrl(link("success", service.beginCallbackSession("vlc", movie(durationMs = 100_000), null)))
        assertEquals(
            listOf(ExternalPlaybackResult(null, null, completed = true), ExternalPlaybackResult(null, null, completed = true), ExternalPlaybackResult(null, null)),
            seen.map { it.result },
        )
    }

    @Test
    fun infuseSuccessMidVideoReportsThePositionWithoutCompletion() = runTest {
        val service = service(FakeLauncher(ExternalPlayerPlatform.IOS))
        val seen = ended(service)
        val session = service.beginCallbackSession("infuse", movie(durationMs = 1_420_016), null)
        service.handleCallbackUrl(link("success", session, "lastPlayedUrl=http%3A%2F%2Fsrv%2Fv.mkv&position=600"))
        assertEquals(ExternalPlaybackResult(600_000, null), seen.single().result)
    }

    @Test
    fun anErrorReportsAnErrorWhateverItCarries() = runTest {
        val service = service(FakeLauncher(ExternalPlayerPlatform.IOS))
        val seen = ended(service)
        service.handleCallbackUrl(link("error", service.beginCallbackSession("infuse", movie(), null), "errorCode=1&errorMessage=Playback%20failed"))
        service.handleCallbackUrl(link("error", service.beginCallbackSession("outplayer", movie(), null), "position=50"))
        assertEquals(List(2) { ExternalPlaybackResult(null, null, error = true) }, seen.map { it.result })
    }

    @Test
    fun aLinkFromAReplacedLaunchIsIgnoredAndEachLinkIsUsedOnce() = runTest {
        val service = service(FakeLauncher(ExternalPlayerPlatform.IOS))
        val seen = ended(service)
        val stale = service.beginCallbackSession("outplayer", movie(), null)
        clock.now = clock.now.plus(1.milliseconds)
        val current = service.beginCallbackSession("outplayer", movie(), null)

        assertFalse(service.handleCallbackUrl(link("cancel", stale, "position=10")))
        assertTrue(service.handleCallbackUrl(link("cancel", current, "position=10")))
        assertFalse(service.handleCallbackUrl(link("cancel", current, "position=20")))
        assertEquals(listOf(ExternalPlaybackResult(10_000, null)), seen.map { it.result })
    }

    @Test
    fun acceptsTheReturnLinkInTheShapeOutplayerOpensIt() = runTest {
        val service = service(FakeLauncher(ExternalPlayerPlatform.IOS))
        val seen = ended(service)
        val session = service.beginCallbackSession("outplayer", movie(durationMs = 1_420_016), null)
        // The stream URL appended unencoded.
        val url = ExternalPlayerService.returnLinks(session).cancel +
            "?url=https://srv.plex.direct:32400/library/parts/1/2/file.mkv?X-Plex-Token=t&position=283.283&duration=1420.016"
        assertTrue(ExternalPlayerService.isReturnLink(url))
        assertTrue(service.handleCallbackUrl(url))
        assertEquals(ExternalPlaybackResult(283_283, 1_420_016), seen.single().result)
    }

    @Test
    fun otherLinksAndLinksWithoutASessionAreNotCallbacks() = runTest {
        val service = service(FakeLauncher(ExternalPlayerPlatform.IOS))
        service.beginCallbackSession("outplayer", movie(), null)
        assertFalse(ExternalPlayerService.isReturnLink("plezy://live?channel=4.1"))
        assertFalse(service.handleCallbackUrl("plezy://live?channel=4.1"))
        assertFalse(service.handleCallbackUrl("plezy://external-player/cancel"))
        assertFalse(service.handleCallbackUrl("other://external-player/cancel/x"))
    }

    @Test
    fun returnLinksCarryTheResultAndTheSessionInThePath() {
        val links = ExternalPlayerService.returnLinks("s1")
        assertEquals(ExternalPlayerReturnLinks("plezy://external-player/success/s1", "plezy://external-player/cancel/s1", "plezy://external-player/error/s1"), links)
        for (link in listOf(links.success, links.cancel, links.error)) assertTrue(ExternalPlayerService.isReturnLink(link))
    }

    // ---- File name and logs ---------------------------------------------------------------------------------------

    @Test
    fun moviesAndEpisodesGetPlexStyleFileNamesWithTheStreamsExtension() {
        val plex = "https://srv.plex.direct:32400/library/parts/28182/1791123620/file.mkv?X-Plex-Token=t"
        assertEquals("Inception (2010).mkv", ExternalPlayerService.playerFilename(movie(), plex))
        assertEquals("The Office - S02E01 - The Dundies.mkv", ExternalPlayerService.playerFilename(episode("The Dundies", 2, 1), plex))
        // Specials keep season 0; an untitled episode drops the title.
        assertEquals(
            "Doctor Who - S00E12.mkv",
            ExternalPlayerService.playerFilename(episode(null, 0, 12).copy(grandparentTitle = "Doctor Who"), plex),
        )
        assertEquals(
            "Mission Impossible Fallout (2018).mkv",
            ExternalPlayerService.playerFilename(movie().copy(title = "Mission: Impossible / Fallout", year = 2018), plex),
        )
        assertEquals("Dune (2021).mp4", ExternalPlayerService.playerFilename(movie().copy(title = "Dune", year = 2021), "https://jf.example/Videos/abc/stream.mp4?Static=true&api_key=k"))
        assertEquals("Inception", ExternalPlayerService.playerFilename(movie().copy(year = null), "http://srv/stream"))
        assertNull(ExternalPlayerService.playerFilename(episode("Pilot", null, 1), plex))
        assertNull(ExternalPlayerService.playerFilename(movie().copy(kind = MediaKind.CLIP), plex))
    }

    @Test
    fun logsMaskServerTokens() {
        assertEquals(
            "http://srv/a?X-Plex-Token=<redacted>&x=1 https://jf/v?api_key=<redacted>&b u%3Fapikey%3D<redacted>%26b",
            ExternalPlayerService.redactTokens("http://srv/a?X-Plex-Token=secret&x=1 https://jf/v?api_key=k2&b u%3Fapikey%3Dk3%26b"),
        )
    }
}
