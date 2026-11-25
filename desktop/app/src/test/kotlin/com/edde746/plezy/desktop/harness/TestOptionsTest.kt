package com.edde746.plezy.desktop.harness

import com.edde746.plezy.app.DevSetting
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.presentation.navigation.Startup
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.desktop.Cli
import com.edde746.plezy.desktop.engineOptions
import com.edde746.plezy.mpv.MpvEngineOptions
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class TestOptionsTest {
    private fun parse(vararg args: String) = TestOptions.parse(arrayOf(*args)).second

    private fun cli(vararg args: String) = TestOptions.parse(arrayOf(*args)).first

    @Test
    fun theProductStartTakesNoDevEntry() {
        assertFalse(parse().dev.dev)
        val devEntries = listOf(
            arrayOf("--dev-open", "home"),
            arrayOf("--dev-language", "de"),
            arrayOf("--dev-setting", "enable_hardware_decoding=false"),
            arrayOf("--dev-discord", "1"),
            arrayOf("--dev-data", "a"),
        )
        for (entry in devEntries) {
            assertFailsWith<Cli.Error> { parse(*entry) }
        }
    }

    @Test
    fun anUnknownDevOptionIsAUsageError() {
        assertFailsWith<Cli.Error> { parse("--dev", "--dev-keep") }
        assertFailsWith<Cli.Error> { parse("--dev", "--dev-opens", "home") }
    }

    @Test
    fun aSlowStartSlowsTheProductOnly() {
        assertEquals(2_500L, parse("--data-dir", "C:\\runs\\a", "--dev-slow-start", "2.5").dev.slowStartMillis)
        assertFailsWith<Cli.Error> { parse("--dev", "--dev-slow-start", "2") }
        assertFailsWith<Cli.Error> { parse("--dev-slow-start", "0") }
    }

    @Test
    fun aDevSessionKeepsItsDatabaseInADataDirOrUnderAName() {
        val options = parse("--dev", "--data-dir", "C:\\runs\\a", "--dev-open", "home")
        assertTrue(options.dev.dev)
        assertEquals(Path.of("C:\\runs\\a"), options.dataDir)
        assertEquals(DatabaseFactory.defaultDirectory().resolve("dev-data").resolve("tour-1"), parse("--dev", "--dev-data", "tour-1").dataDir)
        assertNull(parse("--dev").dataDir)
        assertFailsWith<Cli.Error> { parse("--dev", "--data-dir", "C:\\runs\\a", "--dev-data", "tour-1") }
    }

    @Test
    fun aBadDevEntryIsAUsageError() {
        assertFailsWith<Cli.Error> { parse("--dev", "--dev-open", "player") }
        assertFailsWith<Cli.Error> { parse("--dev", "--dev-setting", "enable_hardware_decoding=off") }
        assertEquals("424242424242424242", parse("--dev", "--dev-discord", "424242424242424242").dev.discord)
        assertFailsWith<Cli.Error> { parse("--dev", "--dev-discord", " ") }
        assertFailsWith<Cli.Error> { parse("--dev", "--dev-open") }
    }

    @Test
    fun devNoAudioStartsTheEngineOnNoAudioOutputWithoutRecovery() {
        fun engine(vararg args: String): MpvEngineOptions {
            val (cli, options) = TestOptions.parse(arrayOf(*args))
            return engineOptions(cli, DevSession(options.dev, null), null, null, DeviceSettings.DEFAULT)
        }
        val silent = engine("--dev", "--dev-no-audio")
        assertEquals("null", silent.extraOptions["ao"])
        assertFalse(silent.audioRecovery)
        val normal = engine("--dev")
        assertNull(normal.extraOptions["ao"])
        assertTrue(normal.audioRecovery)
        assertEquals("wasapi", engine("--dev", "--dev-no-audio", "--mpv-opt", "ao=wasapi").extraOptions["ao"], "an mpv option wins")
        assertFailsWith<Cli.Error> { parse("--dev-no-audio") }
    }

    @Test
    fun devOpenNamesTheStartDestination() {
        assertEquals(Startup(TopLevelDestination.HOME), parse("--dev").dev.open)
        assertEquals(Startup(TopLevelDestination.HOME), parse("--dev", "--dev-open", "home").dev.open)
    }

    @Test
    fun aDevSessionCanStartOffline() {
        assertEquals(listOf<DevSetting>(DevSetting.Offline(true)), parse("--dev", "--dev-setting", "offline=true").dev.settings)
        assertEquals(listOf<DevSetting>(DevSetting.Later(DevSetting.Offline(false), 30.0)), parse("--dev", "--dev-setting", "offline=false@30").dev.settings)
        assertFailsWith<Cli.Error> { parse("--dev", "--dev-setting", "offline=yes") }
        assertFailsWith<Cli.Error> { parse("--dev-setting", "offline=true") }
    }

    @Test
    fun theAppsOptionsAndLinkPassThrough() {
        val link = "plezy://item/4242"
        assertEquals(
            Cli(mpvOptions = mapOf("mute" to "yes"), link = link),
            cli("--dev", "--mpv-opt", "mute=yes", "--report", "C:\\x.jsonl", "--exit-after", "8", link),
        )
        val options = parse("--dev", "--report", "C:\\x.jsonl", "--exit-after", "8", link)
        assertTrue(options.dev.dev)
        assertEquals(TestOptions(dev = options.dev, report = Path.of("C:\\x.jsonl"), exitAfterSeconds = 8.0), options)
    }

    @Test
    fun nothingFollowsALink() {
        // Windows passes the link it opens as "%1": one holding a quote would split into more arguments after it.
        val link = "plezy://item/4242"
        assertFailsWith<Cli.Error> { parse(link, "--report", "\\\\host\\share\\x.jsonl") }
        assertFailsWith<Cli.Error> { parse("--data-dir", "C:\\runs\\a", link, "--report", "C:\\x.jsonl") }
        assertEquals(link, cli("--data-dir", "C:\\runs\\a", "--report", "C:\\x.jsonl", link).link)
    }
}
