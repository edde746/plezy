package com.edde746.plezy

import android.content.Intent
import android.util.Log as AndroidLog
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.DevLaunch
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.app.applyDevSettings
import com.edde746.plezy.app.devAppSession
import com.edde746.plezy.app.httpClient
import com.edde746.plezy.crash.ReleaseChannel
import com.edde746.plezy.crash.crashReports
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.log.Log
import com.edde746.plezy.ui.probe.LayoutProbe
import io.ktor.client.HttpClient
import io.ktor.client.call.HttpClientCall
import io.ktor.client.plugins.HttpSend
import io.ktor.client.plugins.plugin
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HeadersBuilder
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpProtocolVersion
import io.ktor.http.HttpStatusCode
import io.ktor.http.Url
import io.ktor.http.encodedPath
import io.ktor.util.date.GMTDate
import io.ktor.utils.io.ByteReadChannel
import io.ktor.utils.io.InternalAPI
import java.io.File
import java.security.MessageDigest
import java.util.zip.GZIPInputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject

/**
 * Debug builds' launch extras, what the device test harness passes to `am start` ([LaunchExtras]), or null for a plain
 * launch (the product).
 */
internal fun testLaunch(application: PlezyApplication, intent: Intent): TestLaunch? {
    val extras = LaunchExtras.from(intent) ?: return null
    return DebugLaunch(application, extras)
}

/**
 * Debug builds keep every list's semantics whatever accessibility services are on ([LocalKeepsSemantics]): UI
 * automation reads the tree but isn't among the services the platform lists. A `perf` launch has the product's.
 */
internal fun keepsSemantics(launch: TestLaunch?): Boolean = launch?.perfProbe == null

/**
 * The test extras of a launch intent:
 * - `dev` (strings, `--esa dev --dev,--dev-open,home`): the development options, the arguments the desktop harness
 *   launcher and the Apple apps take, read as theirs are ([DevLaunch.parse]; `am` splits the value at commas, `\,`
 *   keeps one in an option). `--dev` starts a development session: an in-memory database (or a kept one, `--dev-data
 *   <name>`, [DEV_DATABASE_PREFIX]: clearing the app's data, `pm clear` or an uninstall, removes it) and secrets in
 *   memory, on its `--dev-open` destination. Nothing it does reaches the device's database or its secret store.
 *   `--dev-slow-start <seconds>` (not with `--dev`) makes the product's start that much longer, so the splash shows its
 *   status line. `--dev-discord` fails the launch: Android has no Discord.
 * - `mpv` (strings): more mpv options, `name=value`, applied last (test runs pass `ao=null`).
 * - `devReplay` (string, with `--dev`): a replay of the dev session's HTTP:
 *   every request to a host other than 127.0.0.1 or localhost is answered from it instead. A directory on the device
 *   (`--es devReplay /data/local/tmp/plezy-replay`): the recording itself, answered in the app ([replayRecording]), so
 *   none of those requests leaves the device; an http URL (`--es devReplay http://127.0.0.1:8890`): a replay server,
 *   which records what it lacks ([replayRequests]).
 * - `devReplayLatency` (int, `--ei devReplayLatency 150`): with a recording on the device, how many milliseconds each
 *   of its answers waits, as over a real network.
 * - `report` (boolean): log a [TestReport] under the `PlezyReport` logcat tag.
 * - `perf` (boolean, `--ez perf true`): log perf marks under the `PlezyPerf` logcat tag ([PerfMarks]): when the
 *   screens first draw their content and when the player's engine loads, each with the last key press's time. The
 *   semantics tree is then the product's too ([keepsSemantics]).
 * Any other extra named `dev<Name>` fails the launch, as an unknown development option does.
 */
internal class LaunchExtras(
    /** `dev`: the development options; null when they can't be read ([problem] says why). */
    val dev: DevLaunch?,
    val mpvOptions: Map<String, String>,
    val devReplay: Replay?,
    val report: Boolean,
    val perf: Boolean,
    /** Why the extras can't run, for the log and the report; null when they can. */
    val problem: String?,
) {
    companion object {
        private const val DEV = "dev"
        private val NAMES = setOf(DEV, "mpv", "devReplay", "devReplayLatency", "report", "perf")

        /** An extra named as this platform's own `devReplay` is: a `dev<Name>` extra the launch doesn't take. */
        private val DEV_EXTRA = Regex("dev[A-Z].*")

        /** The extras of [intent]. */
        fun from(intent: Intent): LaunchExtras? {
            val keys = intent.extras?.keySet() ?: return null
            val unknown = keys.filter { it !in NAMES && DEV_EXTRA.matches(it) }
            if (keys.none { it in NAMES } && unknown.isEmpty()) return null
            fun strings(name: String): List<String> =
                intent.getStringArrayExtra(name)?.toList() ?: intent.getStringExtra(name)?.let(::listOf) ?: emptyList()

            val problems = mutableListOf<String>()
            if (unknown.isNotEmpty()) {
                problems += "${unknown.joinToString()}: unknown extras; the development options go in $DEV, a string array (--esa $DEV --dev,--dev-open,home)"
            }
            val args = intent.getStringArrayExtra(DEV)
            if (DEV in keys && args == null) problems += "$DEV isn't a string array of the development options (--esa $DEV --dev,--dev-open,home)"
            val dev = try {
                DevLaunch.parse(args?.toList().orEmpty())
            } catch (e: IllegalArgumentException) {
                null.also { problems += "$DEV: ${e.message}" }
            }
            if (dev?.discord != null) problems += "--dev-discord: Android has no Discord Rich Presence"
            if (dev?.noAudio == true) problems += "--dev-no-audio: the desktop engine's only; Android mutes with the mpv extra ao=null"
            val mpvOptions = strings("mpv").mapNotNull { option ->
                val eq = option.indexOf('=')
                if (eq <= 0) null.also { problems += "mpv: '$option' isn't name=value" } else option.substring(0, eq) to option.substring(eq + 1)
            }.toMap()
            val latency = intent.getIntExtra("devReplayLatency", 0)
            if (latency < 0) problems += "devReplayLatency: $latency isn't a number of milliseconds"
            val devReplay = intent.getStringExtra("devReplay")?.let { value ->
                when {
                    value.startsWith("http://") || value.startsWith("https://") -> Replay.Server(Url(value))
                    value.startsWith("/") -> Replay.Recording(File(value), latency.toLong())
                    else -> null.also { problems += "devReplay: '$value' is neither an http URL nor a directory" }
                }
            }
            if (latency != 0 && devReplay !is Replay.Recording) problems += "devReplayLatency needs devReplay's directory"
            if (devReplay != null && dev?.dev != true) problems += "devReplay needs --dev"
            return LaunchExtras(
                dev, mpvOptions, devReplay, intent.getBooleanExtra("report", false), intent.getBooleanExtra("perf", false),
                problems.joinToString("; ").ifEmpty { null },
            )
        }
    }
}

/** `devReplay`: what answers the dev session's requests off the device. */
internal sealed interface Replay {
    /** A replay server at [url] (the device test harness runs one), which records what it lacks. */
    class Server(val url: Url) : Replay

    /** The recording in [directory] on the device, each answer [latencyMillis] after it was asked. */
    class Recording(val directory: File, val latencyMillis: Long) : Replay
}

/**
 * One debug launch: its [TestReport] and [PerfMarks], and with `--dev` a development session over its own graph
 * ([AppBootstrap.local]), started once its settings are stored; on a failure the activity finishes. The dev graph hears
 * the process's network; with `devReplay` its HTTP is answered from the replay from the start ([replayRecording],
 * [replayRequests]).
 */
private class DebugLaunch(private val application: PlezyApplication, private val extras: LaunchExtras) : TestLaunch {
    private val scope = MainScope()
    private val report: TestReport? = if (extras.report) TestReport(application) else null

    /** The development session the extras ask for; null for the product, or when the extras can't run. */
    private val session: DevLaunch? = extras.dev?.takeIf { it.dev && extras.problem == null }

    override val boot: AppBootstrap? = session?.let { launch ->
        AppBootstrap.local(
            launch.data?.let { DatabaseFactory.named(application, "$DEV_DATABASE_PREFIX$it.db") } ?: DatabaseFactory.inMemory(application),
            application.flavor, application.version, launch.httpClient(application.version),
        )
    }

    // Extras that can't run start no product either: the launch ends ([fail]).
    override val dev: Boolean = extras.problem != null || extras.dev?.dev == true
    override var devApp: AppSession? by mutableStateOf(null)
        private set
    override val slowStartMillis: Long = extras.dev?.slowStartMillis ?: 0
    override val perfProbe: PerfMarks? = if (extras.perf) PerfMarks(application) else null
    override val probe: LayoutProbe? get() = report?.probe ?: perfProbe?.focusProbe

    init {
        application.platform.mpvOptions = extras.mpvOptions
        report?.start(extras)
        perfProbe?.start()
        if (boot != null) {
            when (val replay = extras.devReplay) {
                is Replay.Server -> replayRequests(boot.graph.http, replay.url)
                is Replay.Recording -> replayRecording(boot.graph.http, replay)
                null -> {}
            }
            application.network.tell(boot)
        }
        when {
            extras.problem != null -> fail(extras.problem)
            boot != null && session != null -> scope.launch { startDev(boot, session) }
        }
    }

    override fun attachProduct(root: RootSession) {
        report?.root = root
    }

    override fun event(name: String, detail: Map<String, Any?>) {
        report?.event(name, detail)
    }

    override fun close() {
        scope.cancel()
        devApp?.close()
        devApp = null
        boot?.close()
        application.platform.mpvOptions = emptyMap()
        report?.stop()
        perfProbe?.stop()
    }

    /**
     * The shared dev session [launch] asks for (the desktop and Apple apps start the same). Its crash reports follow its
     * settings once they are stored, so a session started with them off never starts Sentry. Its theme is the next
     * cold start's launch colour, as the product's is ([SplashTheme]). A step of its launch that fails (its sign-in,
     * its play) fails the launch ([fail]).
     */
    private suspend fun startDev(boot: AppBootstrap, launch: DevLaunch) {
        boot.graph.applyDevSettings(launch.settings)
        boot.graph.followCrashReports(application, boot.crashReports(ReleaseChannel.DEVELOPMENT, launch.crashReports.orEmpty()))
        val app = boot.graph.devAppSession(launch, application.platform, ::fail)
        report?.app = app
        devApp = app
        scope.launch { app.appearance.collect { SplashTheme.save(application, it.theme, application.platform.activity) } }
    }

    /** Logs why the launch can't run (through [Log], which redacts links) and finishes the activity. */
    private fun fail(message: String) {
        Log.e(TAG) { "Test launch failed: $message" }
        report?.event("devStartFailed")
        application.platform.exit()
    }

    private companion object {
        const val TAG = "TestLaunch"
    }
}

/**
 * Answers every request of [http] to a host other than 127.0.0.1 or localhost from [recording]'s files on the device,
 * as the device test harness's replay server records them (per answer `<key>.json`, its status and headers, and
 * `<key>.body`, its bytes as the origin sent them; the key is the SHA-1 of `<method> <url>`), so the session's
 * requests never wait on the device's network. A gzip answer is unzipped, as OkHttp does off the
 * network; a request the recording lacks is answered 404 and logged under [REPLAY_TAG] as `miss <method> <url>`.
 * Installed after the client is built, the interceptor is the innermost one, so the redirects Ktor follows are answered
 * here too.
 */
// HttpClientCall's constructor is Ktor's internal API: what an engine's answer becomes.
@OptIn(InternalAPI::class)
private fun replayRecording(http: HttpClient, recording: Replay.Recording) {
    http.plugin(HttpSend).intercept { request ->
        val url = request.url.build()
        if (url.host == "127.0.0.1" || url.host == "localhost") return@intercept execute(request)
        val port = if (url.port == url.protocol.defaultPort) "" else ":${url.port}"
        val asked = "${request.method.value} ${url.protocol.name}://${url.host}$port${url.encodedPathAndQuery.ifEmpty { "/" }}"
        val key = MessageDigest.getInstance("SHA-1").digest(asked.encodeToByteArray()).joinToString("") { "%02x".format(it) }
        val answer = withContext(Dispatchers.IO) {
            val meta = File(recording.directory, "$key.json")
            if (meta.exists()) JSONObject(meta.readText()) to File(recording.directory, "$key.body").readBytes() else null
        }
        val headers = HeadersBuilder()
        val status: HttpStatusCode
        val body: ByteArray
        if (answer == null) {
            AndroidLog.i(REPLAY_TAG, "miss $asked")
            status = HttpStatusCode.NotFound
            headers.append(HttpHeaders.ContentType, "text/plain")
            body = "not in the recording\n".encodeToByteArray()
        } else {
            delay(recording.latencyMillis)
            val (meta, bytes) = answer
            val recorded = meta.getJSONArray("headers").let { list -> List(list.length()) { list.getJSONArray(it) } }
            val gzip = recorded.any { it.getString(0).equals(HttpHeaders.ContentEncoding, ignoreCase = true) && it.getString(1) == "gzip" }
            status = HttpStatusCode.fromValue(meta.getInt("status"))
            for (header in recorded) {
                if (!gzip || !header.getString(0).equals(HttpHeaders.ContentEncoding, ignoreCase = true)) headers.append(header.getString(0), header.getString(1))
            }
            body = if (gzip) GZIPInputStream(bytes.inputStream()).use { it.readBytes() } else bytes
            if (!gzip) headers.append(HttpHeaders.ContentLength, body.size.toString())
        }
        val callContext = currentCoroutineContext() + Job(request.executionContext)
        HttpClientCall(http, request.build(), HttpResponseData(status, GMTDate(), headers.build(), HttpProtocolVersion.HTTP_1_1, ByteReadChannel(body), callContext))
    }
}

/**
 * Sends every request of [http] to a host other than 127.0.0.1 or localhost to [replay] instead, at
 * `<replay>/<scheme>/<host>[:<port>]<path>` (the port only where it isn't the scheme's default), with its query,
 * method, headers and body as they were. Installed after the client is built, the interceptor is the innermost one, so
 * the redirects Ktor follows are sent there too.
 */
private fun replayRequests(http: HttpClient, replay: Url) {
    val base = replay.encodedPath.trimEnd('/')
    http.plugin(HttpSend).intercept { request ->
        val url = request.url
        if (url.host != "127.0.0.1" && url.host != "localhost") {
            val original = url.build()
            val port = if (original.port == original.protocol.defaultPort) "" else ":${original.port}"
            url.protocol = replay.protocol
            url.host = replay.host
            url.port = replay.port
            url.encodedPath = "$base/${original.protocol.name}/${original.host}$port${original.encodedPath}"
        }
        execute(request)
    }
}

/** The logcat tag of [replayRecording]'s misses, which the device test harness's perf runs count. */
private const val REPLAY_TAG = "PlezyReplay"

/** A `--dev-data <name>` session's database, `dev-<name>.db` beside the app's own. */
private const val DEV_DATABASE_PREFIX = "dev-"
