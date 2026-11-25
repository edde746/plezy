package com.edde746.plezy.presentation.player

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.playback.session.PlayerSession
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.transformLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import kotlin.math.abs
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * What Discord shows on the user's profile while a video or a music track plays (Rich Presence): a "Watching" activity
 * with the title, the episode line, the poster and the time elapsed and left, or for music a "Listening" one with the
 * track, its artist and the album's square artwork. Rich Presence has no paused state, and an activity without
 * timestamps counts up from when Discord got it, so a paused or stopped playback shows none ([of] is null), and nor
 * does a live one, which has no timeline to show.
 *
 * @param details the first line, which Discord's member list shows too: the movie, series or track name.
 * @param state the second line: the episode (`S1E2 · Pilot`) or the track's artist, or null for a movie.
 * @param imageUrl the large image: the title's poster (an episode's series poster), else the media controls'
 *   artwork, as an https URL Discord fetches itself; null when there is none.
 * @param imageText the image's tooltip: the title; for a track its album, else its artist, else the title.
 * @param startSeconds when the video would have started at the current speed, in Unix seconds: Discord counts the
 *   elapsed time from it.
 * @param endSeconds when the video ends at the current speed, in Unix seconds: Discord shows the time left and a bar;
 *   null while the length is unknown.
 * @param listening a music track ([NowPlayingKind.MUSIC]): the profile says "Listening to" instead of "Watching".
 * @param rate the playback speed the timestamps were reckoned at: a new speed is a new activity, so the time left
 *   stays true. Not sent.
 */
data class DiscordActivity(
    val details: String,
    val state: String?,
    val imageUrl: String?,
    val imageText: String,
    val startSeconds: Long,
    val endSeconds: Long?,
    val listening: Boolean = false,
    val rate: Double = 1.0,
) {
    /**
     * [other] shows the same: every field equal but the timestamps, which may differ by [TIMESTAMP_SLACK_SECONDS]: a
     * playback at its pace, or one whose position reports lag, publishes nothing; a seek publishes.
     */
    fun sameAs(other: DiscordActivity): Boolean =
        copy(startSeconds = other.startSeconds, endSeconds = other.endSeconds) == other &&
            abs(startSeconds - other.startSeconds) <= TIMESTAMP_SLACK_SECONDS && near(endSeconds, other.endSeconds)

    companion object {
        /** Discord's longest text field; a longer one fails the whole update. */
        const val MAX_TEXT = 128

        /** Discord's shortest text field; a shorter one (a film named "M") fails the whole update. */
        const val MIN_TEXT = 2

        /** Discord's longest image URL; a longer one fails the whole update, so the image is left out. */
        const val MAX_IMAGE_URL = 256

        /** How far the timestamps may move before the activity is published again: a jump past it is a seek. */
        const val TIMESTAMP_SLACK_SECONDS = 5L

        /**
         * The activity for [nowPlaying] at [nowMillis] (Unix milliseconds), or null when Discord should show none: the
         * playback is paused, stopped or live, or has no title yet.
         *
         * With the server's [NowPlaying.item], its lines are Plezy's: a movie `Title (Year)` over its studio, an
         * episode its series over `S1 E5 - Title`, a track its title over its artist, with the album (else the artist)
         * as the image's tooltip, the series (else the title) for the rest; the image is [hostedPoster] alone, the
         * server's artwork being private. Without one (a URL's video), the player's title and subtitle and an https
         * artwork URL.
         */
        fun of(nowPlaying: NowPlaying, nowMillis: Long, hostedPoster: String? = null): DiscordActivity? {
            if (!nowPlaying.playing || nowPlaying.live) return null
            val item = nowPlaying.item
            val music = nowPlaying.kind == NowPlayingKind.MUSIC || item?.kind == MediaKind.TRACK
            val title = (if (item != null) detailsOf(item) else nowPlaying.title).trim().takeIf { it.isNotEmpty() }?.limited() ?: return null
            val rate = nowPlaying.rate.takeIf { it > 0.0 } ?: 1.0
            fun scaled(seconds: Double) = (seconds.coerceAtLeast(0.0) * 1000 / rate).toLong()
            val endMillis = if (nowPlaying.durationSeconds > 0.0) nowMillis + scaled(nowPlaying.durationSeconds - nowPlaying.positionSeconds) else null
            val startMillis = endMillis?.minus(scaled(nowPlaying.durationSeconds)) ?: (nowMillis - scaled(nowPlaying.positionSeconds))
            val image = (if (item != null) hostedPoster else nowPlaying.posterUrl ?: nowPlaying.artworkUrl)
                ?.takeIf { it.startsWith("https://") && it.length <= MAX_IMAGE_URL }
            val state = (if (item != null) stateOf(item) else nowPlaying.subtitle)?.trim()?.takeIf { it.isNotEmpty() }?.limited()
            val imageText = when {
                item != null -> imageTextOf(item).trim().takeIf { it.isNotEmpty() }?.limited() ?: title
                music -> nowPlaying.album?.trim()?.takeIf { it.isNotEmpty() }?.limited() ?: state ?: title
                else -> title
            }
            return DiscordActivity(
                details = title,
                state = state,
                imageUrl = image,
                imageText = imageText,
                startSeconds = startMillis / 1000,
                endSeconds = endMillis?.div(1000),
                listening = music,
                rate = rate,
            )
        }

        private fun detailsOf(item: MediaItem): String = when (item.kind) {
            MediaKind.MOVIE -> item.title.orEmpty() + (item.year?.let { " ($it)" } ?: "")
            MediaKind.EPISODE -> item.grandparentTitle ?: item.title.orEmpty()
            else -> item.title.orEmpty()
        }

        private fun stateOf(item: MediaItem): String? = when (item.kind) {
            MediaKind.EPISODE -> {
                val season = item.parentIndex
                val episode = item.index
                if (season != null && episode != null) "S$season E$episode - ${item.title.orEmpty()}" else item.title
            }
            MediaKind.MOVIE -> item.studio
            MediaKind.TRACK -> item.trackArtistTitle
            else -> null
        }

        private fun imageTextOf(item: MediaItem): String =
            (if (item.kind == MediaKind.TRACK) item.albumTitle ?: item.trackArtistTitle ?: item.title else item.grandparentTitle ?: item.title).orEmpty()

        private fun near(a: Long?, b: Long?) = if (a == null || b == null) a == b else abs(a - b) <= TIMESTAMP_SLACK_SECONDS

        /**
         * Within Discord's limits: at most [MAX_TEXT] UTF-16 units, cut on a character's boundary, an ellipsis marking
         * the cut; a single character gets a zero-width space after it, which shows nothing, to reach [MIN_TEXT].
         */
        private fun String.limited(): String {
            if (length < MIN_TEXT) return this + "\u200B"
            if (length <= MAX_TEXT) return this
            val cut = take(MAX_TEXT - 1)
            return (if (cut.last().isHighSurrogate()) cut.dropLast(1) else cut) + "…"
        }
    }
}

/**
 * This build's Discord application ([BuildDiscordConfig]: the `plezy.discord.applicationId` Gradle property or the
 * `PLEZY_DISCORD_APPLICATION_ID` environment variable, else Plezy's). Discord names the activity after it
 * ("Watching Plezy"), and each connection's handshake carries its id ([DiscordRpc.handshake]).
 */
class DiscordConfig(applicationId: String) {
    /**
     * The application's id; null when blank: the platform then has no [DiscordPresenceHost], so Settings offers no
     * Discord switch and nothing connects to Discord.
     */
    val applicationId: String? = applicationId.takeIf { it.isNotBlank() }
}

/**
 * Discord's local RPC, as the desktop and Mac apps speak it to the Discord app on the same computer: frames of a
 * little-endian 32-bit opcode, a little-endian 32-bit length and that many bytes of UTF-8 JSON, over a Unix socket
 * (`discord-ipc-<n>` in the runtime or temporary directory) or a Windows named pipe (`\\.\pipe\discord-ipc-<n>`). This
 * object has the opcodes and the JSON; the apps have the sockets.
 */
object DiscordRpc {
    /** The first frame, with [handshake]'s JSON; Discord answers with READY ([isReady]) or closes. */
    const val OP_HANDSHAKE = 0

    /** A command or its answer. */
    const val OP_FRAME = 1

    /** Either side ends the connection; Discord's carries the reason as JSON. */
    const val OP_CLOSE = 2

    /** Discord checks the connection: answered by [OP_PONG] with the same payload. */
    const val OP_PING = 3
    const val OP_PONG = 4

    /** Bytes before a frame's JSON: the opcode and the length. */
    const val HEADER_BYTES = 8

    /** The longest frame payload either side sends; a longer length means the stream is corrupt. */
    const val MAX_PAYLOAD_BYTES = 64 * 1024

    /** Discord's activity type for a video: the profile says "Watching". */
    private const val TYPE_WATCHING = 3

    /** Discord's activity type for music: the profile says "Listening to". */
    private const val TYPE_LISTENING = 2

    /** The member list's status line names [DiscordActivity.details] ("Watching Severance") rather than the app. */
    private const val STATUS_DISPLAY_DETAILS = 2

    private val json = Json { ignoreUnknownKeys = true }

    /** The handshake's JSON: protocol version 1 and the Discord application's id ([DiscordConfig.applicationId]). */
    fun handshake(applicationId: String): String = buildJsonObject {
        put("v", 1)
        put("client_id", applicationId)
    }.toString()

    /**
     * The command that shows [activity] for the process [pid] (the app's: Discord takes the activity down when it
     * exits), or takes it down when null. [nonce] tells the answer apart; any text unique on the connection.
     */
    fun setActivity(activity: DiscordActivity?, pid: Long, nonce: String): String = buildJsonObject {
        put("cmd", "SET_ACTIVITY")
        putJsonObject("args") {
            put("pid", pid)
            if (activity != null) {
                putJsonObject("activity") {
                    put("type", if (activity.listening) TYPE_LISTENING else TYPE_WATCHING)
                    put("status_display_type", STATUS_DISPLAY_DETAILS)
                    put("details", activity.details)
                    activity.state?.let { put("state", it) }
                    putJsonObject("timestamps") {
                        put("start", activity.startSeconds)
                        activity.endSeconds?.let { put("end", it) }
                    }
                    activity.imageUrl?.let { url ->
                        putJsonObject("assets") {
                            put("large_image", url)
                            put("large_text", activity.imageText)
                        }
                    }
                }
            }
        }
        put("nonce", nonce)
    }.toString()

    /** Discord's frame [payload] is its READY event, the answer to a handshake it accepted. */
    fun isReady(payload: String): Boolean {
        val reply = parse(payload) ?: return false
        return reply["cmd"]?.jsonPrimitive?.content == "DISPATCH" && reply["evt"]?.jsonPrimitive?.content == "READY"
    }

    /**
     * Discord's frame [payload] as a log line when it reports an error (an ERROR event, or a close frame's reason):
     * its code and message; null for anything else.
     */
    fun errorOf(payload: String): String? {
        val reply = parse(payload) ?: return null
        val data = reply["data"] as? JsonObject
        val code = (data?.get("code") ?: reply["code"])?.jsonPrimitive?.intOrNull ?: return null
        val message = (data?.get("message") ?: reply["message"])?.jsonPrimitive?.content.orEmpty()
        return "$code $message".trim()
    }

    private fun parse(payload: String): JsonObject? =
        runCatching { json.parseToJsonElement(payload).jsonObject }.getOrNull()
}

/**
 * Discord's local RPC on this computer ([DiscordRpc]) as one Discord application, whose id each handshake carries,
 * implemented by the desktop and Mac apps. Called on the main thread, which it never blocks: the connection lives on a
 * thread of its own.
 */
interface DiscordPresenceHost {
    /**
     * Shows [activity] on the user's Discord profile in place of what the app showed; null takes it down. While there
     * is an activity to show, the host keeps a connection to Discord, connecting again whenever Discord isn't running
     * yet or restarts; with none, it takes the activity down and disconnects.
     */
    fun publish(activity: DiscordActivity?)
}

/**
 * One playback's Rich Presence: while the device's Discord setting is on ([enabled]), the playback's [DiscordActivity]
 * goes to the [host] whenever it shows something new; off, paused, stopped or [release]d, the activity is taken down.
 *
 * Discord takes at most [UPDATES] activity updates per [WINDOW]: one beyond that waits for its turn, and then the
 * newest activity goes out (none if it is what Discord shows already). Taking the activity down never waits: the host
 * disconnects, and an activity still waiting never goes out.
 *
 * Main thread; [release] ends it.
 *
 * @param nowPlaying the playback as the media controls see it; null while nothing plays.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class DiscordPresence internal constructor(
    nowPlaying: Flow<NowPlaying?>,
    enabled: Flow<Boolean>,
    private val host: DiscordPresenceHost,
    parentScope: CoroutineScope,
    clock: Clock,
    private val timeSource: TimeSource = TimeSource.Monotonic,
    /** The server item's poster at a public URL ([DiscordPosters]); none by default. */
    poster: suspend (MediaItem) -> String? = { null },
) {
    /** A video playback's presence, from its [store] and [session]. */
    internal constructor(
        store: PlayerStore,
        session: PlayerSession,
        enabled: Flow<Boolean>,
        host: DiscordPresenceHost,
        parentScope: CoroutineScope,
        clock: Clock,
        timeSource: TimeSource = TimeSource.Monotonic,
        poster: suspend (MediaItem) -> String? = { null },
    ) : this(
        combine(store.state, store.timeline, session.info, session.engineState) { ui, timeline, info, engine -> NowPlaying.of(ui, timeline, info, engine) },
        enabled, host, parentScope, clock, timeSource, poster,
    )

    private val scope = parentScope.childScope()

    /** What the host shows: the last activity published, or null. */
    private var published: DiscordActivity? = null

    /** When the updates of the last [WINDOW] went out, oldest first. */
    private val sent = ArrayDeque<TimeMark>()

    init {
        // The item's hosted poster: none while it uploads, so the card goes up at once and gains its image after.
        val hostedPoster = nowPlaying.map { it?.item }.distinctUntilChanged().transformLatest { item ->
            emit(null)
            if (item != null) emit(poster(item))
        }
        val wanted = combine(nowPlaying, enabled, hostedPoster) { playing, on, image ->
            if (on && playing != null) DiscordActivity.of(playing, clock.now().toEpochMilliseconds(), image) else null
        }.stateIn(scope, SharingStarted.Eagerly, null)
        scope.launch {
            wanted.collectLatest { next ->
                if (shows(next)) return@collectLatest
                if (next != null) {
                    awaitTurn(next)
                    sent.addLast(timeSource.markNow())
                }
                published = next
                host.publish(next)
            }
        }
    }

    /** The playback ended: the activity is taken down at once. */
    fun release() {
        scope.cancel()
        if (published != null) host.publish(null)
        published = null
    }

    /** [activity] is what the host shows already. */
    private fun shows(activity: DiscordActivity?): Boolean {
        val shown = published
        return if (activity == null || shown == null) activity == shown else activity.sameAs(shown)
    }

    /** When the last seek went out. */
    private var lastSeek: TimeMark? = null

    private suspend fun awaitTurn(next: DiscordActivity) {
        // A seek (only the times moved: neither appeared nor went) goes out at once, then at most once a second while
        // the user drags on.
        val shown = published
        val seek = shown != null && next.copy(startSeconds = shown.startSeconds, endSeconds = shown.endSeconds) == shown &&
            (next.endSeconds == null) == (shown.endSeconds == null)
        if (seek) {
            lastSeek?.elapsedNow()?.let { since -> if (since < MIN_INTERVAL) delay(MIN_INTERVAL - since) }
            lastSeek = timeSource.markNow()
        }
        while (sent.size >= UPDATES) {
            val wait = WINDOW - sent.first().elapsedNow()
            if (wait > Duration.ZERO) delay(wait) else sent.removeFirst()
        }
    }

    internal companion object {
        const val UPDATES = 5

        /** At most one update a second, as a seek drags. */
        val MIN_INTERVAL = 1.seconds
        val WINDOW = 20.seconds
    }
}
