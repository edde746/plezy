package com.edde746.plezy.desktop.harness

import com.edde746.plezy.app.DevLaunch
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.desktop.Cli
import com.edde746.plezy.desktop.MinimumWindowSize
import java.nio.file.Path

/**
 * The harness launcher's test-only options ([TestMain]), on top of the app's own ([Cli]): the development options
 * ([DevLaunch], read as every platform reads them), with `--dev` a development session instead of the product: a
 * throwaway in-memory database (or one kept in [dataDir]) and secrets in memory, opened on its `--dev-open`
 * destination. Both take the app's options and its trailing `plezy://` link.
 */
internal data class TestOptions(
    /** The development options: a development session ([DevLaunch.dev]), or the product's start's test hooks. */
    val dev: DevLaunch = DevLaunch.parse(emptyList()),
    /** Sample the app into this journal ([TestReport]). */
    val report: Path? = null,
    /** Quit after this many seconds. */
    val exitAfterSeconds: Double? = null,
    /** Crash the app (an uncaught exception carrying a URL with a token) this many seconds after the start. */
    val crashAfterSeconds: Double? = null,
    /** Crash the app inside libmpv (a read through a bad handle) this many seconds after the start. */
    val crashNativeAfterSeconds: Double? = null,
    /** Make libmpv abort (a broken API use it ends the process for) this many seconds after the start. */
    val abortNativeAfterSeconds: Double? = null,
    /** Crash the JVM itself (a read through a bad address in its own code) this many seconds after the start. */
    val crashVmAfterSeconds: Double? = null,
    /** PlayerEngine setting calls to make during the run. */
    val engineSets: List<EngineSet> = emptyList(),
    /**
     * Product: a device of its own, with its database in this directory and its secrets named after it (`--data-dir`).
     * With [dev]: the development session's database in this directory instead of in memory, so the next launch with
     * it continues the session (its settings): `--data-dir`, or `--dev-data <name>`'s directory under the device's own.
     */
    val dataDir: Path? = null,
    /** The content area's size in dp at startup (1280×720 dp otherwise), scaled down to fit the work area. */
    val windowSize: Pair<Int, Int>? = null,
    /**
     * With [dev]: instead of the app, play this URL or file through the platform's playback and video surface, under a
     * continuously animated overlay (`--play`), looping, muted; the report then samples the video output and the
     * window's paint times.
     */
    val play: String? = null,
    /**
     * Once the app shows, the window resized to this many AWT units (`--window-resize`), whatever the screen: with
     * `-Dsun.java2d.uiScale=3`, 1280x720 is a 3840x2160 window on a 1280x800 screen, for measuring the drawing cost.
     */
    val windowResize: Pair<Int, Int>? = null,
    /**
     * With [play]: the display matched to the video as a fullscreen playback with frame-rate matching and HDR on
     * (`--play-match`): the platform's output host switches the display's mode and HDR state, and puts them back.
     */
    val playMatch: Boolean = false,
    /**
     * Game controllers scripted through this file instead of the system's (`--gamepad-feed`, [GamepadFeed]); a
     * relative path is in [report]'s directory.
     */
    val gamepadFeed: Path? = null,
    /** The window keeps its place across launches as the product's does (`--window-placement`). */
    val windowPlacement: Boolean = false,
    /** The report keeps every Compose frame and UI-thread stall (`--frame-times`, [FrameLog]; Windows and X11). */
    val frameTimes: Boolean = false,
) {
    /** One PlayerEngine setting call: [name] = [value], made [atSeconds] after startup. */
    data class EngineSet(val name: String, val value: String, val atSeconds: Double)

    companion object {
        /**
         * The settings `--engine-set` can call: PlayerEngine.setSpeed, setSubtitleDelay, setAudioDelay, setVolume,
         * setMuted, and mpv's setHdrOutput (`hdr`) and setHdrToneMapping (`hdr-tone-mapping`).
         */
        val ENGINE_SETTINGS = setOf("speed", "sub-delay", "audio-delay", "volume", "mute", "hdr", "hdr-tone-mapping")

        val USAGE = """
            usage: TestMainKt [test options] [app options] [<plezy:// link>]
                   TestMainKt --dev [--dev-open <destination>] [--dev-language <tag>] [--dev-setting <key>=<value>]...
                              [--dev-server <kind>=<user>:<password>@<url>]... [--dev-discord <application id>]
                              [--dev-crash-reports <dsn>] [--dev-data <name>] [--dev-no-audio]
                              [test options] [app options] [<plezy:// link>]
            development (a throwaway in-memory database, or one kept with --dev-data or --data-dir, and secrets in
            memory):
              --dev         start a development session; required by the entries below
              --dev-open    start on this top-level destination: home (the default)
              --dev-language
                            show the app in this interface language: a tag this build has strings for
                            (shared/i18n/<tag>.i18n.json); the launch fails on any other
              --dev-setting start with this device setting, repeatable: <key>=true|false for enable_hardware_decoding,
                            enable_hdr, match_content_frame_rate, audio_passthrough, enable_discord_rpc and
                            crash_reporting, or playback.cacheSizeMegabytes=<MB> (16-4096) or =auto, or the
                            subtitle style: subtitle_font_size (10-80), subtitle_border_size (0-5),
                            subtitle_position (0-150), subtitle_text_color, subtitle_border_color and
                            subtitle_background_color (#RRGGBB), subtitle_background_opacity (0-100), subtitle_bold,
                            subtitle_italic and subtitle_use_margins (true|false), sub_ass_override (no, yes, scale,
                            force, strip), or deinterlace_mode (off, video, film), or
                            offline=true to hold the device offline whatever the network (no server reachable), or
                            player.fastTimers=true to count the sleep timer's minutes as 6 s each (5 minutes in 30 s),
                            or use_external_player=true to play in the external player, selected_external_player=<id>
                            (system_default, vlc, mpv, potplayer, celluloid, …) to choose it, and
                            "custom_external_players=<name>;command;<program>" (or ;urlScheme;<prefix>) to add and
                            choose the custom player dev;
                            <key>=<value>@<seconds> stores it that many seconds after the start instead
              --dev-server  sign the session into this Jellyfin or Emby server once it starts, repeatable:
                            jellyfin=<user>:<password>@<url> or emby=… (the password may be empty), then log its
                            libraries; a sign-in that fails ends the launch. A Plex server signs in through plex.tv,
                            which no option does
              --dev-discord offer Discord's Rich Presence as this Discord application (any id: the tests' fake Discord
                            takes any); without it a dev session has none, whatever the build's
              --dev-crash-reports
                            send the session's crash reports to this Sentry DSN, a fake Sentry's
                            (http://public@<host>:<port>/1), while crash_reporting is on (it is by default);
                            without it the session sends none
              --dev-data    keep the dev session's database under this name (letters, digits, - and _) in the device's
                            data directory instead of in memory, so the next launch with the same name continues it;
                            not with --data-dir
              --dev-no-audio
                            play with no audio output (mpv's ao=null) and no audio recovery, so playback runs silently
                            on a host without an audio device instead of failing its audio output
            test options:
              --report      sample the app's screens and the player's mpv stats into this journal (report.jsonl, one
                            JSON record per line; the latest sample alone in report.last.json beside it)
              --exit-after  quit after this many seconds
              --crash-after crash the app this many seconds after the start: an uncaught exception whose message
                            carries a URL with a made-up token, which no crash report may hold
              --crash-native-after
                            crash the app this many seconds after the start inside libmpv, as a native crash: a
                            read through a bad handle, which HotSpot's crash handler reports
              --abort-native-after
                            make libmpv abort this many seconds after the start: an mpv destroyed with its render
                            context still alive, which libmpv ends the process for with abort()
              --crash-vm-after
                            crash the JVM itself this many seconds after the start: Unsafe reads a bad address,
                            a fault in the JVM's own code, which ends in its fatal-error path
              --engine-set  repeatable: call a PlayerEngine setter (speed, sub-delay, audio-delay, volume, mute=yes|no,
                            hdr=yes|no, hdr-tone-mapping=compositor|player) on the first playback's engine at its
                            start, or <seconds> after startup (e.g. speed=1.5@8)
              --data-dir    run as a device of its own: the database in this directory and the secrets under a name
                            derived from it, apart from the device's own (a fresh device, a second instance); with
                            --dev, the dev session's database there instead of in memory, so the next launch with the
                            same directory continues it
              --window-size open the window with a content area of <width>x<height> dp (default 1280x720, at least
                            640x480; smaller if the screen's work area is)
              --play        (with --dev) play this URL or file, looping and muted, under an animated overlay, instead
                            of the app; the report samples the video output and the window's paint times
              --play-match  (with --play) match the display to the video as a fullscreen playback with frame-rate
                            matching and HDR on, and put it back when the playback ends
              --window-resize
                            once the app shows, resize the window to <width>x<height> AWT units, unfitted to the screen
              --window-placement
                            keep the window's place across launches as the product does (Windows: the registry's
                            HKCU\Software\Plezy\WindowPlacement), restored over --window-size's
              --frame-times
                            (with --report) record every Compose frame's start and render time and every UI-thread
                            stall over 50 ms in the report's samples (Windows and X11, not a Wayland window)
              --dev-slow-start
                            (not with --dev) make the start this many seconds longer, so the splash
                            shows its status line (it names the step once the start has taken half a second)
              --gamepad-feed
                            read game controllers from this file instead of the system's, as XInput's: lines of
                            <slot> <buttons> <x> <y> (buttons A+B+X+UP+DOWN+LEFT+RIGHT+LB+RB or -) or <slot> off;
                            a relative path is in --report's directory
            app options:
        """.trimIndent() + "\n" + Cli.USAGE.lines().drop(1).joinToString("\n")

        /** The app's options and the test options in [args], in any order; the link last, as for the app. */
        fun parse(args: Array<String>): Pair<Cli, TestOptions> {
            val devArgs = mutableListOf<String>()
            var report: Path? = null
            var exitAfter: Double? = null
            var crashAfter: Double? = null
            var crashNativeAfter: Double? = null
            var abortNativeAfter: Double? = null
            var crashVmAfter: Double? = null
            val engineSets = mutableListOf<EngineSet>()
            var dataDir: Path? = null
            var windowSize: Pair<Int, Int>? = null
            var play: String? = null
            var windowResize: Pair<Int, Int>? = null
            var playMatch = false
            var gamepadFeed: Path? = null
            var windowPlacement = false
            var frameTimes = false
            val cli = Cli.parse(args) testOption@{ a, value ->
                when (a) {
                    "--report" -> report = Path.of(value())
                    "--exit-after" -> exitAfter = value().toDoubleOrNull()?.takeIf { it > 0 } ?: throw Cli.Error("--exit-after needs a positive number")
                    "--crash-after" -> crashAfter = value().toDoubleOrNull()?.takeIf { it > 0 } ?: throw Cli.Error("--crash-after needs a positive number")
                    "--crash-native-after" -> crashNativeAfter = value().toDoubleOrNull()?.takeIf { it > 0 }
                        ?: throw Cli.Error("--crash-native-after needs a positive number")
                    "--abort-native-after" -> abortNativeAfter = value().toDoubleOrNull()?.takeIf { it > 0 }
                        ?: throw Cli.Error("--abort-native-after needs a positive number")
                    "--crash-vm-after" -> crashVmAfter = value().toDoubleOrNull()?.takeIf { it > 0 }
                        ?: throw Cli.Error("--crash-vm-after needs a positive number")
                    "--engine-set" -> engineSets += engineSet(value())
                    "--data-dir" -> dataDir = Path.of(value())
                    "--window-size" -> windowSize = windowSize(value())
                    "--play" -> play = value()
                    "--play-match" -> playMatch = true
                    "--gamepad-feed" -> gamepadFeed = Path.of(value())
                    "--window-placement" -> windowPlacement = true
                    "--frame-times" -> frameTimes = true
                    "--window-resize" -> windowResize = value().split('x').mapNotNull { it.toIntOrNull()?.takeIf { n -> n > 0 } }
                        .takeIf { it.size == 2 }?.let { it[0] to it[1] } ?: throw Cli.Error("--window-resize needs <width>x<height>")
                    else -> {
                        // The development options go to DevLaunch as every platform's do, with their values.
                        if (!DevLaunch.isOption(a)) return@testOption false
                        devArgs += a
                        if (DevLaunch.takesValue(a)) devArgs += value()
                    }
                }
                true
            }
            val dev = try {
                DevLaunch.parse(devArgs)
            } catch (e: IllegalArgumentException) {
                throw Cli.Error(e.message ?: e.toString())
            }
            if (dataDir != null && dev.data != null) throw Cli.Error("--data-dir and --dev-data both keep the dev session's database: pass one")
            val devData = dev.data?.let { DatabaseFactory.defaultDirectory().resolve("dev-data").resolve(it) }
            if (play != null && !dev.dev) throw Cli.Error("--play needs --dev")
            if (playMatch && play == null) throw Cli.Error("--play-match needs --play")
            if (frameTimes && report == null) throw Cli.Error("--frame-times needs --report")
            val feed = gamepadFeed?.let { if (it.isAbsolute) it else (report?.toAbsolutePath()?.parent ?: Path.of("")).resolve(it) }
            return cli to TestOptions(
                dev, report, exitAfter, crashAfter, crashNativeAfter, abortNativeAfter, crashVmAfter, engineSets, dataDir ?: devData,
                windowSize,
                play, windowResize,
                playMatch, feed,
                windowPlacement, frameTimes,
            )
        }

        /** `<width>x<height>` in dp, at least [MinimumWindowSize]. */
        private fun windowSize(spec: String): Pair<Int, Int> {
            val (minWidth, minHeight) = MinimumWindowSize
            val parts = spec.split('x').map { it.toIntOrNull() ?: -1 }
            if (parts.size != 2 || parts[0] < minWidth || parts[1] < minHeight) {
                throw Cli.Error("--window-size needs <width>x<height> in dp, at least ${minWidth}x$minHeight, got '$spec'")
            }
            return parts[0] to parts[1]
        }

        /** `<name>=<value>[@<seconds>]`. */
        private fun engineSet(kv: String): EngineSet {
            val eq = kv.indexOf('=')
            if (eq <= 0) throw Cli.Error("--engine-set needs <name>=<value>, got '$kv'")
            val name = kv.substring(0, eq)
            val spec = kv.substring(eq + 1)
            if (name !in ENGINE_SETTINGS) throw Cli.Error("--engine-set: unknown setting '$name' (one of ${ENGINE_SETTINGS.joinToString()})")
            val value = spec.substringBefore('@')
            val at = if ('@' in spec) spec.substringAfter('@').toDoubleOrNull()?.takeIf { it >= 0 } ?: throw Cli.Error("--engine-set: bad time in '$spec'") else 0.0
            val valid = when (name) {
                "mute", "hdr" -> value == "yes" || value == "no"
                "hdr-tone-mapping" -> value == "compositor" || value == "player"
                else -> value.toDoubleOrNull() != null
            }
            if (!valid) throw Cli.Error("--engine-set: bad value for $name: '$value'")
            return EngineSet(name, value, at)
        }
    }
}
