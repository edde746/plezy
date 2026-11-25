package com.edde746.plezy.playback.players

import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.playback.players.ExternalPlayerAttempt.Command
import com.edde746.plezy.playback.players.ExternalPlayerAttempt.OpenUrl
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.ANDROID
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.IOS
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.LINUX
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.MACOS
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.TVOS
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.WINDOWS
import com.edde746.plezy.settings.CustomPlayerType
import com.edde746.plezy.settings.ExternalPlayerChoice
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ExternalPlayersTest {
    @Test
    fun eachPlatformOffersItsPlayersInOrder() {
        fun ids(platform: ExternalPlayerPlatform) = KnownPlayers.supportedOn(platform).map { it.id }
        assertEquals(listOf("system_default", "vlc", "mpv", "mx_player", "just_player"), ids(ANDROID))
        assertEquals(listOf("system_default", "vlc", "infuse", "outplayer"), ids(IOS))
        assertEquals(listOf("vlc", "infuse"), ids(TVOS))
        assertEquals(listOf("system_default", "vlc", "mpv", "iina"), ids(MACOS))
        assertEquals(listOf("system_default", "vlc", "mpv", "potplayer"), ids(WINDOWS))
        assertEquals(listOf("system_default", "vlc", "mpv", "celluloid"), ids(LINUX))
    }

    @Test
    fun aProbeThatThrowsListsThePlayerInsteadOfHidingIt() = runTest {
        for (platform in ExternalPlayerPlatform.entries) {
            assertEquals(KnownPlayers.detect(platform, FakeProbe(everything = true)), KnownPlayers.detect(platform, FakeProbe(failEveryLookup = true)))
        }
    }

    @Test
    fun undetectedPlayersKeepTheirDeclaredOrder() = runTest {
        for (platform in ExternalPlayerPlatform.entries) {
            val all = KnownPlayers.detect(platform, FakeProbe(everything = true))
            val none = KnownPlayers.detect(platform, FakeProbe())
            assertEquals(all.filter { it in none }, none)
            if (platform != TVOS) assertEquals("system_default", none.first().id)
        }
    }

    @Test
    fun linuxAsksTheShellToResolveEachCommandOnPath() = runTest {
        val probe = FakeProbe()
        KnownPlayers.detect(LINUX, probe)
        assertEquals(setOf("command vlc", "command mpv", "command celluloid"), probe.lookups.toSet())
    }

    @Test
    fun macOsAsksLaunchServicesForBundlesAndTheShellForMpv() = runTest {
        val probe = FakeProbe()
        KnownPlayers.detect(MACOS, probe)
        assertEquals(setOf("bundle org.videolan.vlc", "bundle com.colliderli.iina", "command mpv"), probe.lookups.toSet())
    }

    @Test
    fun windowsFallsBackToWhereExeWhenNoInstallPathMatches() = runTest {
        val probe = FakeProbe()
        KnownPlayers.detect(WINDOWS, probe)
        assertEquals(setOf("command vlc", "command mpv", "command PotPlayerMini64"), probe.lookups.filter { it.startsWith("command") }.toSet())
    }

    @Test
    fun windowsSkipsWhereExeOnceAConcreteVlcInstallPathMatches() = runTest {
        val probe = FakeProbe(paths = setOf("C:\\Program Files\\VideoLAN\\VLC\\vlc.exe"), schemes = setOf("potplayer://"))
        assertEquals(listOf("system_default", "vlc", "potplayer"), KnownPlayers.detect(WINDOWS, probe).map { it.id })
        assertEquals(listOf("command mpv"), probe.lookups.filter { it.startsWith("command") })
    }

    @Test
    fun iOsAsksTheSameUrlHandlerQuestionTheLauncherGatesOn() = runTest {
        val probe = FakeProbe()
        KnownPlayers.detect(IOS, probe)
        assertEquals(setOf("scheme vlc://", "scheme infuse://", "scheme outplayer://"), probe.lookups.toSet())
        val tv = FakeProbe()
        KnownPlayers.detect(TVOS, tv)
        assertEquals(setOf("scheme vlc://", "scheme infuse://"), tv.lookups.toSet())
    }

    @Test
    fun androidProbesNothing() = runTest {
        val probe = FakeProbe()
        assertEquals(KnownPlayers.supportedOn(ANDROID), KnownPlayers.detect(ANDROID, probe))
        assertEquals(emptyList(), probe.lookups)
    }

    @Test
    fun eachDesktopListsOnlyThePlayersItFinds() = runTest {
        suspend fun ids(platform: ExternalPlayerPlatform, probe: FakeProbe) = KnownPlayers.detect(platform, probe).map { it.id }
        assertEquals(listOf("system_default", "mpv"), ids(LINUX, FakeProbe(commands = setOf("mpv"))))
        assertEquals(listOf("system_default", "vlc", "celluloid"), ids(LINUX, FakeProbe(commands = setOf("vlc", "celluloid"))))
        assertEquals(listOf("system_default", "vlc"), ids(MACOS, FakeProbe(bundles = setOf("org.videolan.vlc"))))
        assertEquals(listOf("system_default", "iina"), ids(MACOS, FakeProbe(bundles = setOf("com.colliderli.iina"))))
        assertEquals(listOf("system_default", "mpv"), ids(MACOS, FakeProbe(commands = setOf("mpv"))))
        assertEquals(
            listOf("system_default", "vlc"),
            ids(WINDOWS, FakeProbe(paths = setOf("D:\\Apps\\VideoLAN\\VLC\\vlc.exe"), environment = mapOf("ProgramFiles" to "D:\\Apps\\"))),
        )
        assertEquals(listOf("system_default", "vlc", "mpv"), ids(WINDOWS, FakeProbe(commands = setOf("vlc", "mpv"))))
        assertEquals(listOf("system_default", "potplayer"), ids(WINDOWS, FakeProbe(commands = setOf("PotPlayerMini64"))))
    }

    @Test
    fun windowsVlcCandidatesAreDedupedInOrder() {
        assertEquals(
            listOf("vlc", "C:\\Program Files\\VideoLAN\\VLC\\vlc.exe", "C:\\Program Files (x86)\\VideoLAN\\VLC\\vlc.exe"),
            KnownPlayers.windowsVlcCommands(mapOf("ProgramW6432" to "C:\\Program Files", "ProgramFiles" to "c:\\program files\\")),
        )
    }

    @Test
    fun outplayersPlayLinkPercentEncodesTheStreamAndCarriesThePositionAndReturnLinks() {
        val stream = "http://10.0.0.2:32400/library/parts/1/file name.mkv?X-Plex-Token=abc&download=1"
        val uri = KnownPlayers.callbackPlayUri(
            "outplayer",
            stream,
            ExternalPlayerLaunchOptions(startPositionMs = 90_700, returnLinks = ExternalPlayerService.returnLinks("s1")),
        )!!
        assertTrue(uri.startsWith("outplayer://x-callback-url/play?url=http%3A%2F%2F10.0.0.2"))
        assertTrue("file%20name.mkv%3FX-Plex-Token%3Dabc%26download%3D1" in uri)
        val query = query(uri)
        assertEquals(stream, query["url"])
        assertEquals("90", query["position"])
        assertEquals("plezy://external-player/success/s1", query["x-success"])
        assertEquals("plezy://external-player/cancel/s1", query["x-cancel"])
        assertEquals("plezy://external-player/error/s1", query["x-error"])
        assertEquals(listOf("url"), query(KnownPlayers.callbackPlayUri("outplayer", stream, ExternalPlayerLaunchOptions())!!).keys.toList())
    }

    @Test
    fun infusesPlayLinkHasNoCancelLinkAndCarriesTheFileName() {
        val uri = KnownPlayers.callbackPlayUri(
            "infuse",
            "http://srv/v.mkv",
            ExternalPlayerLaunchOptions(42_000, ExternalPlayerService.returnLinks("s2"), "The Office - S02E01 - The Dundies.mkv"),
        )!!
        assertTrue(uri.startsWith("infuse://x-callback-url/play?url=http%3A%2F%2Fsrv%2Fv.mkv"))
        val query = query(uri)
        assertEquals("42", query["position"])
        assertEquals("plezy://external-player/success/s2", query["x-success"])
        assertEquals("plezy://external-player/error/s2", query["x-error"])
        assertFalse("x-cancel" in query)
        assertEquals("The Office - S02E01 - The Dundies.mkv", query["filename"])
        assertTrue("filename=The%20Office%20-%20S02E01%20-%20The%20Dundies.mkv" in uri)
    }

    @Test
    fun outplayerLinksLeaveOutTheFileNameItDoesNotDocument() {
        val uri = KnownPlayers.callbackPlayUri("outplayer", "http://srv/v.mkv", ExternalPlayerLaunchOptions(filename = "Inception (2010).mkv"))!!
        assertEquals(listOf("url"), query(uri).keys.toList())
    }

    @Test
    fun vlcStreamsThroughVlcXCallbackWithOnlyTheKeysItReadsAndRawReturnLinks() {
        val stream = "https://srv.plex.direct:32400/library/parts/1/2/file.mkv?X-Plex-Token=abc"
        val uri = KnownPlayers.callbackPlayUri(
            "vlc",
            stream,
            ExternalPlayerLaunchOptions(90_000, ExternalPlayerService.returnLinks("s3"), "Inception (2010).mkv"),
        )!!
        assertTrue(uri.startsWith("vlc-x-callback://x-callback-url/stream?url=https%3A%2F%2Fsrv.plex.direct"))
        val query = query(uri)
        assertEquals(stream, query["url"])
        assertEquals(setOf("url", "x-success", "x-error"), query.keys)
        assertTrue("x-success=plezy://external-player/success/s3" in uri)
        assertTrue("x-error=plezy://external-player/error/s3" in uri)
    }

    @Test
    fun vlcsOwnQueryParsingRecoversUsableReturnLinks() {
        val uri = KnownPlayers.callbackPlayUri(
            "vlc",
            "https://srv.plex.direct:32400/library/parts/1/2/file.mkv?X-Plex-Token=abc&download=1",
            ExternalPlayerLaunchOptions(returnLinks = ExternalPlayerService.returnLinks("s3")),
        )!!
        // VLC 3.7.3's URLHandler.parseURL: split on `&`, then on `=`, keep the second part, open it as a URL.
        val parsed = uri.substringAfter('?').split('&').map { it.split('=') }.filter { it.size >= 2 }.associate { it[0] to it[1] }
        assertEquals("plezy://external-player/success/s3", parsed["x-success"])
        assertEquals("plezy://external-player/error/s3", parsed["x-error"])
        assertTrue(parsed.getValue("url").startsWith("https%3A%2F%2F"))
    }

    @Test
    fun onlyXCallbackPlayersHaveAPlayLinkAndOnlyIPhoneAndIPadUseIt() {
        assertNull(KnownPlayers.callbackPlayUri("mpv", "http://srv/v.mkv", ExternalPlayerLaunchOptions()))
        assertTrue(KnownPlayers.launchesWithCallback("vlc", IOS))
        assertTrue(KnownPlayers.launchesWithCallback("infuse", IOS))
        assertFalse(KnownPlayers.launchesWithCallback("infuse", TVOS))
        assertFalse(KnownPlayers.launchesWithCallback("vlc", MACOS))
        assertFalse(KnownPlayers.launchesWithCallback("mpv", IOS))
    }

    @Test
    fun androidPackagesAreAKnownPlayersOrACustomCommandsPackage() {
        assertEquals(listOf("com.mxtech.videoplayer.ad", "com.mxtech.videoplayer.pro"), KnownPlayers.androidPackageCandidates(ExternalPlayerChoice("mx_player", "MX Player")))
        assertEquals(listOf("org.videolan.vlc"), KnownPlayers.androidPackageCandidates(ExternalPlayerChoice("vlc", "VLC")))
        assertEquals(emptyList(), KnownPlayers.androidPackageCandidates(ExternalPlayerChoice.SYSTEM_DEFAULT))
        assertEquals(listOf("com.example.player"), KnownPlayers.androidPackageCandidates(custom(" com.example.player ", CustomPlayerType.COMMAND)))
        assertEquals(emptyList(), KnownPlayers.androidPackageCandidates(custom("player://", CustomPlayerType.URL_SCHEME)))
    }

    @Test
    fun eachPlayerStartsAsItsPlatformStartsIt() {
        val url = "http://srv/v.mkv?X-Plex-Token=t"
        fun attempts(id: String, platform: ExternalPlayerPlatform, env: Map<String, String> = emptyMap()) =
            KnownPlayers.attempts(KnownPlayers.findById(id)!!.choice, platform, url, env)
        assertEquals(listOf(OpenUrl(url, checkHandler = false)), attempts("system_default", LINUX))
        assertEquals(listOf(Command(listOf("open", "-a", "VLC", url))), attempts("vlc", MACOS))
        assertEquals(listOf(Command(listOf("vlc", url))), attempts("vlc", LINUX))
        assertEquals(listOf(OpenUrl("vlc://$url", checkHandler = false)), attempts("vlc", TVOS))
        assertEquals(
            listOf("vlc", "C:\\Program Files\\VideoLAN\\VLC\\vlc.exe", "C:\\Program Files (x86)\\VideoLAN\\VLC\\vlc.exe"),
            attempts("vlc", WINDOWS).map { (it as Command).command.first() },
        )
        assertEquals(listOf(Command(listOf("mpv", url))), attempts("mpv", MACOS))
        assertEquals(listOf(OpenUrl("iina://weblink?url=" + UriComponent.encode(url), checkHandler = true)), attempts("iina", MACOS))
        assertEquals(listOf(OpenUrl("infuse://x-callback-url/play?url=" + UriComponent.encode(url), checkHandler = false)), attempts("infuse", TVOS))
        assertEquals(listOf(OpenUrl("potplayer://$url", checkHandler = true), Command(listOf("PotPlayerMini64", url))), attempts("potplayer", WINDOWS))
        assertEquals(listOf(Command(listOf("celluloid", url))), attempts("celluloid", LINUX))
        assertEquals(
            listOf(OpenUrl("outplayer://x-callback-url/play?url=" + UriComponent.encode(url), checkHandler = false)),
            attempts("outplayer", IOS),
        )
    }

    @Test
    fun customPlayersStartAsTheirTypeSays() {
        val url = "http://srv/v.mkv"
        assertEquals(
            listOf(OpenUrl("myplayer://play?url=" + UriComponent.encode(url), checkHandler = false)),
            KnownPlayers.attempts(custom("myplayer://play?url=", CustomPlayerType.URL_SCHEME), IOS, url, emptyMap()),
        )
        assertEquals(listOf(OpenUrl("myplayer://$url", checkHandler = true)), KnownPlayers.attempts(custom("myplayer://", CustomPlayerType.URL_SCHEME), LINUX, url, emptyMap()))
        assertEquals(
            listOf(Command(listOf("VLC", url)), Command(listOf("open", "-a", "VLC", url))),
            KnownPlayers.attempts(custom("VLC", CustomPlayerType.COMMAND), MACOS, url, emptyMap()),
        )
        assertEquals(listOf(Command(listOf("/opt/mpv", url))), KnownPlayers.attempts(custom("/opt/mpv", CustomPlayerType.COMMAND), WINDOWS, url, emptyMap()))
    }

    private fun custom(value: String, type: CustomPlayerType) = ExternalPlayerChoice("c1", "Mine", isCustom = true, customValue = value, customType = type)

    /** [uri]'s query as `Uri.queryParameters` reads it: split at `&` and the first `=`, decoded. */
    private fun query(uri: String): Map<String, String> = uri.substringAfter('?').split('&').associate {
        UriComponent.decode(it.substringBefore('=')) to UriComponent.decode(it.substringAfter('='))
    }
}

/** Answers the host lookups from fixed sets, recording each ("command mpv", "bundle …", "scheme vlc://", "file …"). */
internal class FakeProbe(
    private val commands: Set<String> = emptySet(),
    private val paths: Set<String> = emptySet(),
    private val bundles: Set<String> = emptySet(),
    private val schemes: Set<String> = emptySet(),
    override val environment: Map<String, String> = emptyMap(),
    private val everything: Boolean = false,
    private val failEveryLookup: Boolean = false,
) : PlayerInstallProbe {
    val lookups = mutableListOf<String>()

    private fun answer(lookup: String, found: Boolean): Boolean {
        lookups += lookup
        if (failEveryLookup) throw IllegalStateException("probe unavailable")
        return everything || found
    }

    override suspend fun commandExists(command: String) = answer("command $command", command in commands)

    override suspend fun fileExists(path: String) = answer("file $path", path in paths)

    override suspend fun applicationInstalled(bundleId: String) = answer("bundle $bundleId", bundleId in bundles)

    override suspend fun schemeHasHandler(scheme: String) = answer("scheme $scheme", scheme in schemes)
}
