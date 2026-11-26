package com.edde746.plezy.app

import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.presentation.navigation.Startup
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.settings.AppSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DevLaunchTest {
    private fun parse(vararg args: String) = DevLaunch.parse(args.toList())

    private fun refused(vararg args: String) {
        assertFailsWith<IllegalArgumentException>(args.joinToString(" ")) { parse(*args) }
    }

    @Test
    fun anUnknownDevOptionFailsTheLaunch() {
        refused("--dev", "--dev-keep")
        refused("--dev", "--dev-opens", "home")
        refused("--devx")
        refused("--dev-replay", "/data/local/tmp/replay")
    }

    @Test
    fun thePlatformsOwnArgumentsAreSkipped() {
        // The Mac's AppKit pairs and a harness's own options go past the parser untouched.
        val launch = parse("-NSTreatUnknownArgumentsAsOpen", "NO", "--dev", "--report", "x.jsonl", "--dev-open", "home", "plezy://open")
        assertTrue(launch.dev)
        assertEquals(Startup(TopLevelDestination.HOME), launch.open)
        assertFalse(parse().dev)
    }

    @Test
    fun theOptionsAreRead() {
        val launch = parse(
            "--dev", "--dev-data", "tour-1", "--dev-language", "de", "--dev-discord", "424242424242424242",
            "--dev-crash-reports", "http://public@h:8768/1", "--dev-setting", "offline=true", "--dev-setting", "player.fastTimers=true",
        )
        assertEquals("tour-1", launch.data)
        assertEquals("424242424242424242", launch.discord)
        assertEquals("http://public@h:8768/1", launch.crashReports)
        // The language is the Language setting's, stored by its name.
        val language = DevSetting.Value(AppSettings.appLocale, "de", "de")
        assertEquals(listOf(DevSetting.Offline(true), DevSetting.FastTimers(true), language), launch.settings)
        assertEquals("zhHant", (parse("--dev", "--dev-language", "zh-Hant").settings.single() as DevSetting.Value<*>).stored)
        assertEquals(Startup(TopLevelDestination.HOME), launch.open)
        assertEquals(emptyList(), parse("--dev").settings)
        assertEquals(2_500L, parse("--dev-slow-start", "2.5").slowStartMillis)
        assertEquals(Startup.LIVE_TV, parse("--dev", "--dev-open", "live_tv").open)
        assertEquals(Startup(TopLevelDestination.DOWNLOADS), parse("--dev", "--dev-open", "downloads").open)
        assertEquals(listOf("http://h/a.flac", "file:///b.mp3"), parse("--dev", "--dev-music-url", "http://h/a.flac,file:///b.mp3").musicUrls)
        assertEquals(listOf("http://h/a.flac", "http://h/b.flac"), parse("--dev", "--dev-music-url", "http://h/a.flac", "--dev-music-url", "http://h/b.flac").musicUrls)
        val server = arrayOf("--dev", "--dev-server", "jellyfin=a:b@http://media.test:8096")
        assertNull(parse(*server).openMusic)
        assertEquals(DevOpenMusic.Library, parse(*server, "--dev-open-music", "library").openMusic)
        assertEquals(DevOpenMusic.Artist("Plezy Test Artist"), parse(*server, "--dev-open-music", "artist=Plezy Test Artist").openMusic)
        assertEquals(DevOpenMusic.Album("Sine Album"), parse(*server, "--dev-open-music", "album=Sine Album").openMusic)
        assertEquals(DevOpenMusic.Playlist("Plezy Mix"), parse(*server, "--dev-open-music", "playlist=Plezy Mix").openMusic)
        assertNull(parse(*server).openItem)
        assertEquals("Maestro_Show/Season_1", parse(*server, "--dev-open-item", "Maestro_Show/Season_1").openItem)
        assertFailsWith<IllegalArgumentException> { parse("--dev", "--dev-open-item", "Maestro Movie") }
        assertNull(parse(*server).openShowSchedule)
        assertEquals("Morning News", parse(*server, "--dev-open-show-schedule", "Morning News").openShowSchedule)
        assertEquals("Morning News", parse(*server, "--dev-open-show-schedule", "Morning_News").openShowSchedule)
        assertFailsWith<IllegalArgumentException> { parse("--dev", "--dev-open-show-schedule", "News") }
        val seerr = assertNotNull(parse("--dev", "--dev-seerr", "maestro@plezy.test:pass:word@http://h:28099").seerr)
        assertEquals(listOf("http://h:28099", "maestro@plezy.test", "pass:word"), listOf(seerr.url, seerr.email, seerr.password))
        assertNull(parse("--dev").seerr)
        assertEquals("K7MQ2X", parse("--dev", "--dev-watch-room", "k7m-q2x").watchRoom)
        assertNull(parse("--dev").watchRoom)
        // A flag: the destination after it is still read.
        val car = parse("--dev", "--dev-automotive", "--dev-open", "settings")
        assertTrue(car.automotive)
        assertEquals(Startup(TopLevelDestination.SETTINGS), car.open)
        assertFalse(parse("--dev").automotive)
    }

    @Test
    fun aSessionOptionNeedsDev() {
        for (option in listOf(
            arrayOf("--dev-open", "home"), arrayOf("--dev-language", "de"), arrayOf("--dev-data", "a"),
            arrayOf("--dev-setting", "offline=true"), arrayOf("--dev-discord", "1"), arrayOf("--dev-crash-reports", "http://k@h/1"),
            arrayOf("--dev-server", "jellyfin=a:b@http://media.test:8096"),
            arrayOf("--url", "http://h/a.mkv"), arrayOf("--dev-play", "plex:12"),
            arrayOf("--dev-trackers", "http://h:28100"), arrayOf("--dev-trackers", "http://h:28100", "--dev-trackers-connected"),
            arrayOf("--dev-music-url", "http://h/a.flac"),
            arrayOf("--dev-seerr", "a@b:c@http://h"), arrayOf("--dev-watch-room", "K7MQ2X"),
        )) {
            refused(*option)
            parse("--dev", *option)
        }
    }

    @Test
    fun aProductOptionRefusesDev() {
        parse("--dev-slow-start", "3")
        refused("--dev", "--dev-slow-start", "3")
    }

    @Test
    fun theServersAreRead() {
        val launch = parse(
            "--dev", "--dev-server", "jellyfin=maestro:secret@http://media.test:8096",
            "--dev-server", "emby=guest:@https://emby.test/base", "--dev-server", "jellyfin=a:p@ss:w@rd@http://h.test",
        )
        assertEquals(
            listOf(
                DevServer(MediaBrowserDialect.JELLYFIN, "maestro", "secret", "http://media.test:8096"),
                DevServer(MediaBrowserDialect.EMBY, "guest", "", "https://emby.test/base"),
                DevServer(MediaBrowserDialect.JELLYFIN, "a", "p@ss:w@rd", "http://h.test"),
            ),
            launch.servers,
        )
        assertEquals(emptyList<DevServer>(), parse("--dev").servers)
        // A launch's options may be logged: the password isn't in the server's text.
        assertEquals("jellyfin=maestro@http://media.test:8096", launch.servers[0].toString())
    }

    @Test
    fun aServerTheOptionDoesntTakeFailsTheLaunch() {
        for (spec in listOf(
            "plex=http://media.test:32400", "kodi=a:b@http://media.test", "a:b@http://media.test", "jellyfin=http://media.test",
            "jellyfin=a@http://media.test", "jellyfin=:b@http://media.test", "jellyfin=a:b@media.test:8096", "jellyfin=a:b@http://",
        )) {
            refused("--dev", "--dev-server", spec)
        }
        val plex = assertFailsWith<IllegalArgumentException> { parse("--dev", "--dev-server", "plex=http://media.test:32400") }
        assertTrue(plex.message!!.startsWith("--dev-server can't sign into Plex"), plex.message)
    }

    @Test
    fun aValueTheOptionDoesntTakeFailsTheLaunch() {
        refused("--dev", "--dev-open")
        refused("--dev", "--dev-open", "library")
        refused("--dev", "--dev-language", "xx")
        refused("--dev", "--dev-data", "a/b")
        refused("--dev", "--dev-music-url", "a.flac")
        refused("--dev", "--dev-open-music", "library")
        refused("--dev", "--dev-server", "jellyfin=a:b@http://media.test:8096", "--dev-open-music", "track=Low Hum")
        refused("--dev", "--dev-server", "jellyfin=a:b@http://media.test:8096", "--dev-open-music", "artist=")
        refused("--dev", "--dev-discord", " ")
        refused("--dev", "--dev-crash-reports", "public@h:8768/1")
        refused("--dev", "--dev-seerr", "a@b@http://h")
        refused("--dev", "--dev-seerr", "a@b:c@h:28099")
        refused("--dev", "--dev-watch-room", "K7M-Q2O")
        refused("--dev-slow-start", "0")
        refused("--dev", "--url", "h/a.mkv")
        refused("--dev", "--url", "file:///a.mkv")
        refused("--dev", "--url", "http://")
        refused("--dev", "--dev-play", "plex")
        refused("--dev", "--dev-play", ":12")
        refused("--dev", "--dev-play", "plex:")
        refused("--dev", "--dev-trackers", "h:28100")
        refused("--dev", "--dev-trackers-connected")
    }

    @Test
    fun aPlayIsReadFromItsOption() {
        assertEquals("https://h/a b.mkv", parse("--dev", "--url", "https://h/a b.mkv").url)
        assertEquals(DevPlay("jellyfin", "Big Buck Bunny: Sunflower"), parse("--dev", "--dev-play", "jellyfin:Big Buck Bunny: Sunflower").play)
        assertNull(parse("--dev").url)
        assertNull(parse("--dev").play)
    }

    @Test
    fun aUrlAndADevPlayAreTwoPlays() {
        refused("--dev", "--url", "http://h/a.mkv", "--dev-play", "plex:12")
    }

    @Test
    fun theTrackerOptionsAreRead() {
        val launch = parse("--dev", "--dev-trackers-connected", "--dev-trackers", "http://10.0.2.2:28100", "--dev-open", "home")
        assertEquals("http://10.0.2.2:28100", launch.trackers)
        assertTrue(launch.trackersConnected)
        assertEquals(Startup(TopLevelDestination.HOME), launch.open)
        val plain = parse("--dev", "--dev-trackers", "https://fake.test")
        assertEquals("https://fake.test", plain.trackers)
        assertFalse(plain.trackersConnected)
        assertNull(parse("--dev").trackers)
    }

    @Test
    fun aPlaylistIsReadFromItsOption() {
        assertEquals(DevPlaylist("emby", "Binge: Part 2"), parse("--dev", "--dev-playlist", "emby:Binge: Part 2").playlist)
        assertNull(parse("--dev").playlist)
        refused("--dev-playlist", "emby:Binge")
        refused("--dev", "--dev-playlist", "Binge")
        refused("--dev", "--dev-playlist", "emby:")
    }

    @Test
    fun downloadsAreTitlesOfItemsOnTheFirstServerInOrder() {
        val server = "jellyfin=maestro:secret@http://media.test:8096"
        val launch = parse("--dev", "--dev-server", server, "--dev-download", " Alpha_Archive ", "--dev-download", "Maestro Show")
        assertEquals(listOf("Alpha_Archive", "Maestro Show"), launch.downloads)
        assertEquals(emptyList<String>(), parse("--dev").downloads)
        refused("--dev", "--dev-download", "Alpha_Archive")
        refused("--dev", "--dev-server", server, "--dev-download", " ")
    }

    @Test
    fun theHomeFakesAreFlagsAndARevokeNeedsAServer() {
        val launch = parse("--dev", "--dev-server-tasks", "--dev-revoke-token", "--dev-server", "jellyfin=a:b@http://media.test:8096")
        assertTrue(launch.serverTasks)
        assertTrue(launch.revokeToken)
        assertFalse(parse("--dev").serverTasks)
        assertFalse(DevLaunch.takesValue("--dev-server-tasks"))
        refused("--dev", "--dev-revoke-token")
    }

    @Test
    fun aPlatformsParserKnowsWhichOptionsTakeAValue() {
        assertTrue(DevLaunch.isOption("--dev-anything"))
        assertFalse(DevLaunch.isOption("--report"))
        assertTrue(DevLaunch.isOption("--url"))
        assertTrue(DevLaunch.takesValue("--url"))
        assertFalse(DevLaunch.isOption("--urls"))
        assertFalse(DevLaunch.takesValue("--dev"))
        assertTrue(DevLaunch.takesValue("--dev-open"))
        assertFalse(DevLaunch.takesValue("--dev-trackers-connected"))
        assertTrue(DevLaunch.takesValue("--dev-trackers"))
    }
}
