package com.edde746.plezy.desktop.players

import com.edde746.plezy.playback.players.ExternalLaunchStatus
import com.edde746.plezy.playback.players.ExternalPlayerAttempt
import com.edde746.plezy.playback.players.ExternalPlayerAttempt.Command
import com.edde746.plezy.playback.players.ExternalPlayerLaunch
import com.edde746.plezy.playback.players.ExternalPlayerPlatform
import com.edde746.plezy.playback.players.KnownPlayers
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Each launch's attempts, tried in order until one starts, with a URL's handler asked for first where it should be. */
class DesktopPlayerAppsTest {
    private class FakeSystem(
        override val platform: ExternalPlayerPlatform,
        private val programs: Set<String> = emptySet(),
        private val schemes: Set<String> = emptySet(),
    ) : DesktopSystem {
        val did = mutableListOf<String>()
        override val environment: Map<String, String> = emptyMap()
        override suspend fun commandExists(command: String) = command in programs
        override suspend fun fileExists(path: String) = path in programs
        override suspend fun applicationInstalled(bundleId: String) = false
        override fun handles(scheme: String) = scheme in schemes
        override fun start(command: List<String>): Boolean = (command.first() in programs).also { if (it) did += "start ${command.joinToString(" ")}" }
        override fun open(url: String): Boolean = true.also { did += "open $url" }
    }

    private val url = "http://srv/v.mkv?X-Plex-Token=t"

    private fun launch(system: FakeSystem, id: String, observed: MutableList<Pair<ExternalPlayerAttempt?, ExternalLaunchStatus>> = mutableListOf()): ExternalLaunchStatus {
        val apps = DesktopPlayerApps(system) { started, status -> observed += started to status }
        val attempts = KnownPlayers.attempts(KnownPlayers.findById(id)!!.choice, system.platform, url, mapOf("ProgramFiles" to "C:\\Program Files"))
        return runBlocking { apps.launch(ExternalPlayerLaunch(url, attempts = attempts)) {} }
    }

    @Test
    fun windowsVlcStartsFromTheFirstPlaceItIs() {
        val system = FakeSystem(ExternalPlayerPlatform.WINDOWS, programs = setOf("C:\\Program Files\\VideoLAN\\VLC\\vlc.exe"))
        val observed = mutableListOf<Pair<ExternalPlayerAttempt?, ExternalLaunchStatus>>()
        assertEquals(ExternalLaunchStatus.LAUNCHED, launch(system, "vlc", observed))
        assertEquals(listOf("start C:\\Program Files\\VideoLAN\\VLC\\vlc.exe $url"), system.did)
        assertEquals(listOf<Pair<ExternalPlayerAttempt?, ExternalLaunchStatus>>(Command(listOf("C:\\Program Files\\VideoLAN\\VLC\\vlc.exe", url)) to ExternalLaunchStatus.LAUNCHED), observed)
    }

    @Test
    fun potPlayerOpensThroughItsHandlerElseItsProgram() {
        val handler = FakeSystem(ExternalPlayerPlatform.WINDOWS, schemes = setOf("potplayer"))
        assertEquals(ExternalLaunchStatus.LAUNCHED, launch(handler, "potplayer"))
        assertEquals(listOf("open potplayer://$url"), handler.did)
        val program = FakeSystem(ExternalPlayerPlatform.WINDOWS, programs = setOf("PotPlayerMini64"))
        assertEquals(ExternalLaunchStatus.LAUNCHED, launch(program, "potplayer"))
        assertEquals(listOf("start PotPlayerMini64 $url"), program.did)
    }

    @Test
    fun aMissingPlayerIsNotInstalledAndTheSystemDefaultOpensTheUrl() {
        val linux = FakeSystem(ExternalPlayerPlatform.LINUX)
        val observed = mutableListOf<Pair<ExternalPlayerAttempt?, ExternalLaunchStatus>>()
        assertEquals(ExternalLaunchStatus.NOT_INSTALLED, launch(linux, "mpv", observed))
        assertEquals(listOf<Pair<ExternalPlayerAttempt?, ExternalLaunchStatus>>(null to ExternalLaunchStatus.NOT_INSTALLED), observed)
        assertEquals(ExternalLaunchStatus.LAUNCHED, launch(linux, "system_default"))
        assertEquals(listOf("open $url"), linux.did)
    }

    @Test
    fun aProbeThatNeverExitsFailsWithinItsTimeoutAndIsKilled() {
        val hang = if (System.getProperty("os.name").startsWith("Windows")) listOf("ping", "-n", "60", "127.0.0.1") else listOf("sleep", "60")
        val before = ProcessHandle.current().children().map { it.pid() }.toList().toSet()
        val started = System.nanoTime()
        assertNull(probe(hang, timeoutSeconds = 1))
        assertTrue(System.nanoTime() - started < TimeUnit.SECONDS.toNanos(5), "the probe outlasted its timeout")
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5)
        fun left() = ProcessHandle.current().children().filter { it.pid() !in before && it.isAlive }.toList()
        while (left().isNotEmpty() && System.nanoTime() < deadline) Thread.sleep(50)
        assertEquals(emptyList(), left().map { it.info().command().orElse("?") })
    }
}
