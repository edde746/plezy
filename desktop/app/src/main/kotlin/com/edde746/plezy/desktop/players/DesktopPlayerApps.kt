package com.edde746.plezy.desktop.players

import com.edde746.plezy.desktop.browse
import com.edde746.plezy.desktop.windows.WindowsRegistry
import com.edde746.plezy.log.Log
import com.edde746.plezy.playback.players.ExternalLaunchStatus
import com.edde746.plezy.playback.players.ExternalPlaybackResult
import com.edde746.plezy.playback.players.ExternalPlayerAttempt
import com.edde746.plezy.playback.players.ExternalPlayerLaunch
import com.edde746.plezy.playback.players.ExternalPlayerLauncher
import com.edde746.plezy.playback.players.ExternalPlayerPlatform
import com.edde746.plezy.playback.players.PlayerInstallProbe
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * External players on Windows and Linux ([ExternalPlayerLauncher]): each launch's attempts in turn
 * ([com.edde746.plezy.playback.players.KnownPlayers.attempts]) until one starts. A program starts detached with the URL
 * as its argument; a URL goes to the system's handler for it, first asking whether there is one when the attempt says
 * so. Nothing comes back from a desktop player.
 *
 * Nothing here logs a URL or a command line: the stream's URL carries the server's key.
 *
 * @param observer the test report (the harness launcher's `--report`; null otherwise): hears each launch.
 */
internal class DesktopPlayerApps(
    private val system: DesktopSystem,
    private val observer: ExternalPlayersObserver? = null,
) : ExternalPlayerLauncher {
    override val platform: ExternalPlayerPlatform get() = system.platform
    override val probe: PlayerInstallProbe get() = system

    override suspend fun launch(launch: ExternalPlayerLaunch, ended: (ExternalPlaybackResult) -> Unit): ExternalLaunchStatus =
        withContext(Dispatchers.IO) {
            val started = launch.attempts.firstOrNull(::attempt)
            val status = if (started != null) ExternalLaunchStatus.LAUNCHED else ExternalLaunchStatus.NOT_INSTALLED
            Log.i(TAG) { "${started ?: "No attempt"} of ${launch.attempts.size} started" }
            observer?.externalPlayerLaunched(started, status)
            status
        }

    private fun attempt(attempt: ExternalPlayerAttempt): Boolean = when (attempt) {
        is ExternalPlayerAttempt.OpenUrl -> {
            val scheme = attempt.url.substringBefore(':', "")
            if (attempt.checkHandler && !system.handles(scheme)) false else system.open(attempt.url)
        }
        is ExternalPlayerAttempt.Command -> system.start(attempt.command)
    }

    private companion object {
        const val TAG = "ExternalPlayers"
    }
}

/** What external players need of this computer: the install lookups, starting programs and opening URLs. */
internal interface DesktopSystem : PlayerInstallProbe {
    val platform: ExternalPlayerPlatform

    /** An app is registered for URLs of [scheme] (`potplayer`). */
    fun handles(scheme: String): Boolean

    /** Starts [command] (the program, then its arguments) detached, its output discarded; false when it can't start. */
    fun start(command: List<String>): Boolean

    /** Hands [url] to the app the system opens it with. */
    fun open(url: String): Boolean

    override suspend fun schemeHasHandler(scheme: String): Boolean = handles(scheme.substringBefore(':'))

    /** This computer: Windows, else Linux. */
    class Real(windows: Boolean = System.getProperty("os.name").startsWith("Windows")) : DesktopSystem {
        override val platform: ExternalPlayerPlatform = if (windows) ExternalPlayerPlatform.WINDOWS else ExternalPlayerPlatform.LINUX
        private val windows = platform == ExternalPlayerPlatform.WINDOWS

        override val environment: Map<String, String> = System.getenv()

        /** `where.exe` on Windows, the shell's `command -v` elsewhere: the lookups the programs' start goes through. */
        override suspend fun commandExists(command: String): Boolean = withContext(Dispatchers.IO) {
            val lookup = if (windows) listOf("where.exe", command) else listOf("sh", "-c", "command -v \"\$1\" >/dev/null 2>&1", "plezy-command-probe", command)
            probe(lookup) != null
        }

        override suspend fun fileExists(path: String): Boolean = withContext(Dispatchers.IO) { File(path).isFile }

        override suspend fun applicationInstalled(bundleId: String): Boolean = false

        override fun handles(scheme: String): Boolean = if (windows) {
            // An unreadable registry reads as no handler: the launch goes on to its next attempt.
            try {
                WindowsRegistry.string(WindowsRegistry.Root.CLASSES_ROOT, "$scheme\\shell\\open\\command", "") != null
            } catch (e: IllegalStateException) {
                Log.w(TAG, e) { "Reading the $scheme handler failed" }
                false
            }
        } else {
            probe(listOf("xdg-mime", "query", "default", "x-scheme-handler/$scheme"))?.isNotBlank() == true
        }

        override fun start(command: List<String>): Boolean {
            val program = command.first()
            if (windows && isBatchFile(program)) {
                Log.w(TAG) { "$program is a batch file, which cmd.exe would run with the URL's & as commands: not started" }
                return false
            }
            return try {
                val arguments = if (windows) command.drop(1).map(::windowsArgument) else command.drop(1)
                ProcessBuilder(listOf(program) + arguments)
                    .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                    .redirectError(ProcessBuilder.Redirect.DISCARD)
                    .start()
                    .outputStream.close()
                Log.i(TAG) { "Started $program" }
                true
            } catch (e: IOException) {
                Log.d(TAG) { "$program didn't start: ${e.javaClass.simpleName}" }
                false
            }
        }

        override fun open(url: String): Boolean = browse(url)

        private companion object {
            const val TAG = "ExternalPlayers"
        }
    }

    companion object {
        /**
         * [program] is a batch file (`.bat`, `.cmd`), which Windows runs through `cmd.exe`, whose parser reads `&`, `|`
         * and `%` in any argument; Windows drops a name's trailing dots and spaces first.
         */
        fun isBatchFile(program: String): Boolean {
            val name = program.trimEnd('.', ' ')
            return name.endsWith(".bat", ignoreCase = true) || name.endsWith(".cmd", ignoreCase = true)
        }
    }
}

/**
 * [argument] as a Windows program's command line holds it, for the program to split back as it was (by the rules of
 * `CommandLineToArgvW` and the C runtime's start-up code): as it is without whitespace or `"`, else in quotes, with each
 * `"` escaped by a backslash and the backslashes before a `"` or the closing quote doubled (`""` when empty). The JDK
 * passes an argument already in quotes on as it is, and one without whitespace too; its own quoting puts quotes around
 * an argument with whitespace and escapes no `"` in it, so a URL holding one would come apart into more arguments.
 */
internal fun windowsArgument(argument: String): String {
    if (argument.isNotEmpty() && argument.none { it == '"' || it.isWhitespace() }) return argument
    return buildString {
        append('"')
        var backslashes = 0
        for (c in argument) {
            if (c == '\\') {
                backslashes++
                continue
            }
            repeat(if (c == '"') 2 * backslashes + 1 else backslashes) { append('\\') }
            append(c)
            backslashes = 0
        }
        repeat(2 * backslashes) { append('\\') }
        append('"')
    }
}

/**
 * Runs [command] for at most [timeoutSeconds]: its output once it exited 0 in time, else null, a child still running
 * then killed. The output is read after the exit: a probe's is a line or two, far below a pipe's buffer.
 */
internal fun probe(command: List<String>, timeoutSeconds: Long = 5): String? {
    val process = try {
        ProcessBuilder(command).redirectError(ProcessBuilder.Redirect.DISCARD).start()
    } catch (_: IOException) {
        return null
    }
    process.outputStream.close()
    if (!process.waitFor(timeoutSeconds, TimeUnit.SECONDS)) {
        process.destroyForcibly()
        return null
    }
    return process.inputStream.bufferedReader().use { it.readText() }.takeIf { process.exitValue() == 0 }
}

/** The test report (the harness launcher's `--report`): hears each external player launch. */
internal fun interface ExternalPlayersObserver {
    /** A launch ended [status]: [started] the attempt that started (null: none did). */
    fun externalPlayerLaunched(started: ExternalPlayerAttempt?, status: ExternalLaunchStatus)
}
