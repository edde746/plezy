package com.edde746.plezy.playback.players

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.UrlTokens
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPartTimeline
import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ExternalPlayerChoice
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.math.abs
import kotlin.math.roundToLong
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * Where playback in an external player stopped, as the player reported it: Android's activity result, or an
 * x-callback-url return link on iPhone and iPad. [positionMs] and [durationMs] are on the handed-over file's clock (one
 * part of an item stacked across files), null when unknown. [completed]: the player says it played to the end.
 * [error]: it says playback failed; nothing should be reported then.
 */
data class ExternalPlaybackResult(
    val positionMs: Long?,
    val durationMs: Long?,
    val completed: Boolean = false,
    val error: Boolean = false,
)

/**
 * One launch's [result], with what it was launched for: the [item], the server ([backend]; null for a download played
 * without one), the source and, for an item stacked across files, the [partTimeline] that places the handed-over file
 * on the item.
 */
data class ExternalPlaybackEnded(
    val item: MediaItem,
    val backend: MediaBackend?,
    val mediaSourceId: String?,
    val partTimeline: MediaPartTimeline?,
    val result: ExternalPlaybackResult,
)

/** A subtitle handed to an Android player: its URL or a local path, its [name], [enabled] the one to show. */
data class ExternalPlayerSubtitle(val uri: String, val name: String?, val enabled: Boolean) {
    override fun toString(): String = "ExternalPlayerSubtitle(uri=<redacted>, name=$name, enabled=$enabled)"
}

/**
 * What one launch hands the platform. On Android the intent hand-off: [url] (an http(s) URL, a `content://` URI, a
 * `file://` URL or a path), [title], [startPositionMs] (0: from the beginning), the [packages] to try in order (none:
 * the system resolves it) and the [subtitles]. Elsewhere the [attempts], tried in order until one starts.
 */
data class ExternalPlayerLaunch(
    val url: String,
    val title: String? = null,
    val startPositionMs: Long = 0,
    val packages: List<String> = emptyList(),
    val subtitles: List<ExternalPlayerSubtitle> = emptyList(),
    val attempts: List<ExternalPlayerAttempt> = emptyList(),
) {
    override fun toString(): String =
        "ExternalPlayerLaunch(url=<redacted>, title=$title, startPositionMs=$startPositionMs, packages=$packages, subtitles=${subtitles.size}, attempts=$attempts)"
}

enum class ExternalLaunchStatus {
    LAUNCHED,

    /** No app took it: the package isn't installed, no program or handler was found. */
    NOT_INSTALLED,

    /** It failed otherwise (a launch already waiting for its result, an error). */
    FAILED,
}

/** The platform's side of external players (`AppPlatform.externalPlayers`). */
interface ExternalPlayerLauncher {
    val platform: ExternalPlayerPlatform

    /** The host lookups detection makes ([KnownPlayers.detect]). */
    val probe: PlayerInstallProbe

    /**
     * Starts [launch]. A player that reports back (Android's activity result) calls [ended] once, later, from the main
     * thread. Never logs the URL.
     */
    suspend fun launch(launch: ExternalPlayerLaunch, ended: (ExternalPlaybackResult) -> Unit): ExternalLaunchStatus
}

/** How [ExternalPlayerService.launch] went. */
sealed interface ExternalLaunchOutcome {
    data object Launched : ExternalLaunchOutcome

    /** Nothing was launched; [message] is the snackbar to show, null for none. */
    data class NotLaunched(val message: String?) : ExternalLaunchOutcome
}

/**
 * Plays items in the external player of `selected_external_player` ([AppSettings.selectedExternalPlayer]) through the
 * platform's [launcher], and reports where each launch's player stopped on [ended]. One per running app.
 *
 * Off Android, players launched through x-callback-url ([KnownPlayers.launchesWithCallback]) get return links
 * `plezy://external-player/{success|cancel|error}/<session>`; the app hands every link it is opened with to
 * [handleCallbackUrl]. Only the latest launch can call back: a new launch replaces it, and each link is used once.
 */
class ExternalPlayerService(
    private val launcher: ExternalPlayerLauncher,
    private val settings: DeviceSettingsRepository,
    private val clock: Clock = Clock.System,
) {
    val platform: ExternalPlayerPlatform get() = launcher.platform

    private val mutableEnded = MutableSharedFlow<ExternalPlaybackEnded>(extraBufferCapacity = 16)

    /** Each launch's result, once its player reported it. */
    val ended: SharedFlow<ExternalPlaybackEnded> = mutableEnded.asSharedFlow()

    private val detection = Mutex()
    private var detected: List<KnownPlayer>? = null
    private var callbackSession: CallbackSession? = null

    /**
     * The known players offered here and found installed ([KnownPlayers.detect]), detected once per process: a player
     * installed while the app runs appears after a restart.
     */
    suspend fun players(): List<KnownPlayer> = detection.withLock {
        detected ?: KnownPlayers.detect(launcher.platform, launcher.probe).also { detected = it }
    }

    /**
     * Plays [item] in the selected external player: a download's file [videoUrl] (with the [downloadedSubtitles] saved
     * beside it, handed to Android players), or else the stream [backend] resolves for it. The player starts at the
     * resume point, on the handed-over file's clock for an item stacked across files.
     */
    suspend fun launch(
        item: MediaItem,
        backend: MediaBackend?,
        mediaIndex: Int = 0,
        mediaSourceId: String? = null,
        videoUrl: String? = null,
        downloadedSubtitles: List<SubtitleSidecar> = emptyList(),
    ): ExternalLaunchOutcome {
        try {
            val resume = item.viewOffsetMs?.takeIf { it > 0 }?.milliseconds
            val url: String
            var subtitles: List<SubtitleSidecar> = emptyList()
            val partTimeline: MediaPartTimeline?
            if (videoUrl != null) {
                url = videoUrl
                subtitles = downloadedSubtitles
                // A download is handed over as its first file.
                partTimeline = item.mediaVersions?.getOrNull(mediaIndex)?.let { MediaPartTimeline.fromParts(it.parts) }
            } else if (backend != null) {
                val target = backend.resolveExternalPlayback(item, mediaIndex, mediaSourceId, resume)
                if (target == null || target.url.isEmpty()) return ExternalLaunchOutcome.NotLaunched(T.messages.fileInfoNotAvailable)
                url = target.url
                subtitles = target.subtitles
                partTimeline = target.partTimeline
            } else {
                Log.e(TAG) { "launching an external player needs a download's file or a server" }
                return ExternalLaunchOutcome.NotLaunched(null)
            }
            val start = startPosition(resume, partTimeline)

            val choice = settings.value(AppSettings.selectedExternalPlayer)
            // Nothing to hand off to: the system default on Apple TV, where it stays the stored default.
            if (!KnownPlayers.isAvailable(choice, platform)) return ExternalLaunchOutcome.NotLaunched(T.externalPlayer.launchFailed)
            val name = if (choice.isCustom) choice.name else KnownPlayers.findById(choice.id)?.name ?: choice.name

            if (platform == ExternalPlayerPlatform.ANDROID) {
                val launch = ExternalPlayerLaunch(
                    url = url,
                    title = item.title?.trim()?.takeIf { it.isNotEmpty() },
                    startPositionMs = start?.inWholeMilliseconds ?: 0,
                    packages = if (choice.id == KnownPlayers.SYSTEM_DEFAULT_ID) emptyList() else KnownPlayers.androidPackageCandidates(choice),
                    subtitles = subtitles.mapNotNull(::subtitleArgument),
                )
                val status = launcher.launch(launch) { result -> report(ExternalPlaybackEnded(item, backend, mediaSourceId, partTimeline, result)) }
                return when (status) {
                    ExternalLaunchStatus.LAUNCHED -> ExternalLaunchOutcome.Launched
                    ExternalLaunchStatus.NOT_INSTALLED -> ExternalLaunchOutcome.NotLaunched(T.externalPlayer.appNotInstalled(name))
                    ExternalLaunchStatus.FAILED -> ExternalLaunchOutcome.NotLaunched(T.externalPlayer.launchFailed)
                }
            }

            val status = if (!choice.isCustom && KnownPlayers.launchesWithCallback(choice.id, platform)) {
                val session = beginCallbackSession(choice.id, item, backend, mediaSourceId, partTimeline)
                val options = ExternalPlayerLaunchOptions(
                    startPositionMs = start?.inWholeMilliseconds,
                    returnLinks = returnLinks(session),
                    filename = playerFilename(item, url),
                )
                val playUri = KnownPlayers.callbackPlayUri(choice.id, url, options)!!
                callbackLog { "launching ${choice.id} for ${item.id} (session $session, start $start, durationMs ${item.durationMs}): ${redactTokens(url)}" }
                callbackLog { "player url: ${redactTokens(playUri)}" }
                val attempts = KnownPlayers.attempts(choice, platform, url, launcher.probe.environment, callbackUrl = playUri)
                launcher.launch(ExternalPlayerLaunch(url, attempts = attempts)) {}.also { status ->
                    callbackLog { "launch returned $status" }
                    if (status != ExternalLaunchStatus.LAUNCHED && callbackSession?.id == session) callbackSession = null
                }
            } else {
                launcher.launch(ExternalPlayerLaunch(url, attempts = KnownPlayers.attempts(choice, platform, url, launcher.probe.environment))) {}
            }
            return if (status == ExternalLaunchStatus.LAUNCHED) {
                ExternalLaunchOutcome.Launched
            } else {
                ExternalLaunchOutcome.NotLaunched(T.externalPlayer.appNotInstalled(name))
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "launching the external player failed" }
            return ExternalLaunchOutcome.NotLaunched(T.externalPlayer.launchFailed)
        }
    }

    /** Begins the callback session of a launch of [playerId]: its id, base 36 microseconds since the epoch. */
    internal fun beginCallbackSession(
        playerId: String,
        item: MediaItem,
        backend: MediaBackend?,
        mediaSourceId: String? = null,
        partTimeline: MediaPartTimeline? = null,
    ): String {
        val now = clock.now()
        val micros = now.epochSeconds * 1_000_000 + now.nanosecondsOfSecond / 1_000
        val id = micros.toString(36)
        callbackSession = CallbackSession(id, playerId, item, backend, mediaSourceId, partTimeline)
        return id
    }

    /**
     * Handles `plezy://external-player/<result>/<session>?position=&duration=`, the return link an x-callback-url player
     * opens when playback ends, and reports what it says on [ended]. Returns whether the link belonged to the pending
     * launch; anything else is ignored.
     */
    fun handleCallbackUrl(url: String): Boolean {
        callbackLog { "received: ${redactTokens(url)}" }
        val link = AppLink.parse(url)
        if (link == null || link.scheme != SCHEME || link.host != RETURN_HOST || link.segments.size < 2) {
            callbackLog { "not an external-player return link; ignoring" }
            return false
        }
        val session = callbackSession
        if (session == null || session.id != link.segments[1]) {
            callbackLog { "session ${link.segments[1]} does not match pending ${session?.id}; ignoring" }
            return false
        }
        callbackSession = null

        val reportedDuration = callbackNumber(link.query["duration"])
        val msPerUnit = msPerUnit(reportedDuration, session.item.durationMs)
        val durationMs = reportedDuration?.let { (it * msPerUnit).roundToLong() }
        val positionMs = callbackNumber(link.query["position"])?.let { (it * msPerUnit).roundToLong() }
        // A reported position always wins. Without one, success means the video finished only for players that call it
        // on completion (not VLC, which calls it on every stop).
        val successMeansFinished = KnownPlayers.xCallbackPlayer(session.playerId)?.successMeansFinished ?: true
        val result = when (link.segments[0]) {
            SUCCESS -> ExternalPlaybackResult(positionMs, durationMs, completed = positionMs == null && successMeansFinished)
            CANCEL -> ExternalPlaybackResult(positionMs, durationMs)
            else -> ExternalPlaybackResult(null, null, error = true)
        }
        callbackLog {
            "result ${link.segments[0]} from ${session.playerId}: position=${link.query["position"]} duration=${link.query["duration"]} " +
                "-> msPerUnit $msPerUnit, $result (item durationMs ${session.item.durationMs})"
        }
        report(ExternalPlaybackEnded(session.item, session.backend, session.mediaSourceId, session.partTimeline, result))
        return true
    }

    private fun report(ended: ExternalPlaybackEnded) {
        Log.i(TAG) { "${ended.item.id} ended in the external player: ${ended.result}" }
        if (!mutableEnded.tryEmit(ended)) Log.w(TAG) { "an external player's result for ${ended.item.id} was dropped" }
    }

    private class CallbackSession(
        val id: String,
        val playerId: String,
        val item: MediaItem,
        val backend: MediaBackend?,
        val mediaSourceId: String?,
        val partTimeline: MediaPartTimeline?,
    )

    companion object {
        /** The app's link scheme. */
        const val SCHEME: String = "plezy"

        /** The host of the return links: `plezy://external-player/…`. */
        const val RETURN_HOST: String = "external-player"

        private const val SUCCESS = "success"
        private const val CANCEL = "cancel"
        private const val ERROR = "error"
        private const val TAG = "ExternalPlayers"

        /** The return links of callback session [session]: in the path, since players append their own query. */
        fun returnLinks(session: String): ExternalPlayerReturnLinks {
            fun link(result: String) = "$SCHEME://$RETURN_HOST/$result/$session"
            return ExternalPlayerReturnLinks(success = link(SUCCESS), cancel = link(CANCEL), error = link(ERROR))
        }

        /** [url] is an external player's return link, for the app's link handling to route. */
        fun isReturnLink(url: String): Boolean = AppLink.parse(url)?.let { it.scheme == SCHEME && it.host == RETURN_HOST } == true

        /**
         * Where the handed-over file starts: the resume point, or for an item stacked across files the resume point
         * minus the current file's start when that file covers it, else nothing.
         */
        fun startPosition(resume: Duration?, partTimeline: MediaPartTimeline?): Duration? = when {
            partTimeline == null -> resume
            resume != null && partTimeline.covers(resume) -> resume - partTimeline.current.start
            else -> null
        }

        /**
         * A name players can identify [item] by: `Title (Year).ext` for a movie, `Show - S01E02 - Title.ext` for an
         * episode, the extension copied from [streamUrl]'s last path segment. Null when the item lacks what that needs.
         */
        fun playerFilename(item: MediaItem, streamUrl: String): String? {
            val name = when (item.kind) {
                MediaKind.MOVIE -> {
                    val title = fileNamePart(item.title)
                    val year = item.year
                    if (title == null || year == null) title else "$title ($year)"
                }
                MediaKind.EPISODE -> {
                    val show = fileNamePart(item.grandparentTitle)
                    val season = item.parentIndex
                    val episode = item.index
                    if (show == null || season == null || episode == null) {
                        null
                    } else {
                        val code = "S" + season.toString().padStart(2, '0') + "E" + episode.toString().padStart(2, '0')
                        val title = fileNamePart(item.title)
                        if (title == null) "$show - $code" else "$show - $code - $title"
                    }
                }
                else -> null
            } ?: return null
            val lastSegment = AppLink.parse(streamUrl)?.segments?.lastOrNull().orEmpty()
            val extension = EXTENSION.find(lastSegment)?.groupValues?.get(1)
            return if (extension == null) name else "$name.$extension"
        }

        /** Masks server tokens ([UrlTokens]) before a URL reaches the log. */
        fun redactTokens(text: String): String = UrlTokens.redact(text, "<redacted>")

        private val EXTENSION = Regex("\\.([A-Za-z0-9]{2,4})$")
        private val UNSAFE_FILE_CHARACTERS = Regex("[\\\\/:*?\"<>|]")
        private val WHITESPACE = Regex("\\s+")

        private fun fileNamePart(value: String?): String? =
            value?.replace(UNSAFE_FILE_CHARACTERS, " ")?.replace(WHITESPACE, " ")?.trim()?.takeIf { it.isNotEmpty() }

        /** One subtitle as the intent hand-off takes it; a `file:` URL goes as its path, shared like the video. */
        private fun subtitleArgument(subtitle: SubtitleSidecar): ExternalPlayerSubtitle? {
            val uri = subtitle.url.takeIf { it.isNotEmpty() } ?: return null
            val path = if (uri.startsWith("file:")) UriComponent.decode(uri.removePrefix("file://").removePrefix("file:")) else uri
            return ExternalPlayerSubtitle(path, subtitle.title?.trim()?.takeIf { it.isNotEmpty() }, subtitle.isDefault)
        }

        private fun callbackNumber(value: String?): Double? = value?.toDoubleOrNull()?.takeIf { it.isFinite() && it > 0 }

        /**
         * Milliseconds per reported time unit: seconds (Outplayer documents its `position` so), unless the reported
         * duration lines up with the item's runtime in milliseconds.
         */
        private fun msPerUnit(reportedDuration: Double?, itemDurationMs: Long?): Int {
            if (reportedDuration == null || itemDurationMs == null || itemDurationMs <= 0) return 1000
            val asMs = abs(reportedDuration - itemDurationMs)
            val asSeconds = abs(reportedDuration * 1000 - itemDurationMs)
            return if (asMs < asSeconds) 1 else 1000
        }

        private fun callbackLog(message: () -> String) = Log.d(TAG) { "[callback] " + message() }
    }
}

/**
 * A URL as the return-link handling reads it: [scheme] and [host] lowercased, the path's [segments] percent-decoded
 * (empty ones dropped), the [query] after the first `?` split at `&` and the first `=`, decoded with `+` as a space.
 */
internal class AppLink(val scheme: String, val host: String, val segments: List<String>, val query: Map<String, String>) {
    companion object {
        fun parse(url: String): AppLink? {
            val schemeEnd = url.indexOf("://")
            if (schemeEnd <= 0) return null
            val withoutFragment = url.substringBefore('#')
            val rest = withoutFragment.substring(schemeEnd + 3)
            val beforeQuery = rest.substringBefore('?')
            val queryText = if ('?' in rest) rest.substringAfter('?') else ""
            val host = beforeQuery.substringBefore('/').substringAfterLast('@').substringBefore(':')
            val path = if ('/' in beforeQuery) beforeQuery.substringAfter('/') else ""
            val segments = path.split('/').filter { it.isNotEmpty() }.map(UriComponent::decode)
            val query = queryText.split('&').filter { it.isNotEmpty() }.associate { pair ->
                fun decode(text: String) = UriComponent.decode(text.replace('+', ' '))
                decode(pair.substringBefore('=')) to decode(pair.substringAfter('=', ""))
            }
            return AppLink(url.substring(0, schemeEnd).lowercase(), host.lowercase(), segments, query)
        }
    }
}
