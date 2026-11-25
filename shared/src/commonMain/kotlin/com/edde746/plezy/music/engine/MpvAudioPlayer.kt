package com.edde746.plezy.music.engine

import com.edde746.plezy.log.Log
import com.edde746.plezy.playback.COMMON_MPV_OPTIONS
import kotlin.concurrent.Volatile
import kotlin.math.roundToLong
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/**
 * [AudioPlayer] on one dedicated audio-only mpv handle ([MpvAudioCore]): every platform's music player, with the
 * gapless rules here once.
 *
 * The playlist is always `[playing, armed?]`. [setNext] appends the armed entry with its own HTTP headers as the
 * entry's options (one server's credentials never ride another's entry), and lets mpv open it ahead of the boundary
 * (`prefetch-playlist`) only for an http(s) entry whose headers equal the playing entry's: mpv prefetches with the
 * playing entry's header list, and a local entry opens at once anyway (an `fdclose://` one must not be opened early,
 * see [clearArmedNext]). mpv's `file-loaded` that no [open] caused while an entry is armed is the gapless advance: the
 * player takes the new source's ownership (playhead to 0, the outgoing entry's last position kept), removes the spent
 * entry 0, and reports [AudioEvent.TrackTransition] with the armed entry's own URI.
 *
 * Commands run one at a time in call order, on one coroutine at a time together with mpv's reports, and are not
 * cancelled half way: the playlist and what the player knows of it never part.
 */
class MpvAudioPlayer internal constructor(
    private val core: MpvAudioCore,
    private val platformOptions: Map<String, String>,
    private val passthroughCodecs: List<String>,
    private val contentFds: ContentFds?,
    private val dispatcher: CoroutineDispatcher,
) : AudioPlayer {
    /**
     * @param platformOptions the platform's mpv startup options (its `ao`), after the shared ones ([OPTIONS]).
     * @param passthroughCodecs what `audio-spdif` names while passthrough is on (Apple outputs); empty where the
     *   platform passes nothing through, and [setAudioPassthrough] does nothing.
     * @param contentFds Android's `content://` opener; null elsewhere.
     */
    constructor(
        core: MpvAudioCore,
        platformOptions: Map<String, String> = emptyMap(),
        passthroughCodecs: List<String> = emptyList(),
        contentFds: ContentFds? = null,
    ) : this(core, platformOptions, passthroughCodecs, contentFds, Dispatchers.Default.limitedParallelism(1))

    private val scope = CoroutineScope(SupervisorJob() + dispatcher)
    private val mutex = Mutex()
    private val inputs = Channel<Input>(Channel.UNLIMITED)
    private val eventChannel = Channel<AudioEvent>(Channel.UNLIMITED)

    override val events: Flow<AudioEvent> = eventChannel.receiveAsFlow()

    @Volatile
    override var state: AudioPlayerState = AudioPlayerState()
        private set

    @Volatile
    override var outgoingSourcePosition: Duration? = null
        private set

    @Volatile
    override var disposed: Boolean = false
        private set

    private var started = false
    private var startFailure: String? = null

    /** An [open] reached mpv and no [stop] came since: there is an entry to arm behind. */
    private var opened = false

    /** Set by [open] and taken by its own `file-loaded`, which is not a gapless advance. */
    private var expectOpenFileLoad = false

    private var armed: Armed? = null

    /**
     * The headers a prefetch of an armed entry would send: the playing entry's own, set by [open] and taken over from
     * the armed entry as mpv advances into it; null while unknown (an open in flight or refused).
     */
    private var prefetchHeaders: Map<String, String>? = null

    /** Bumped whenever another source takes the playhead: a seek answered after it speaks for the old one. */
    private var sourceGeneration = 0L

    /** The last position mpv reported for the source now playing. */
    private var lastReported = Duration.ZERO

    /** The outgoing source's last position, taken as `playlist-pos` moved while an entry was armed. */
    private var frozenOutgoing: Duration? = null

    private var lastPositionEvent: TimeMark? = null

    private val listener = object : MpvAudioCoreListener {
        override fun onProperty(name: String, value: String?) {
            inputs.trySend(Input.Property(name, value))
        }

        override fun onFileLoaded() {
            inputs.trySend(Input.FileLoaded)
        }

        override fun onEndFile(error: String?) {
            inputs.trySend(Input.EndFile(error))
        }
    }

    init {
        scope.launch { for (input in inputs) handle(input) }
    }

    override suspend fun open(media: AudioMedia, play: Boolean) = serial {
        // `loadfile replace` drops the armed entry: settle its descriptor first. No transition: playback is replaced.
        clearArmedNext(adoptIfRolledIn = false)
        // `pause` survives loadfile: a paused open pauses first, so the outgoing file never plays on unpaused.
        if (!play) setProperty("pause", "yes")
        val uri = playableUriOrRaw(media.uri)
        expectOpenFileLoad = true
        try {
            command("loadfile", uri, "replace", "-1", entryOptions(media))
        } catch (e: IllegalStateException) {
            // Nothing replaced the outgoing file: it plays on as it was.
            expectOpenFileLoad = false
            throw e
        }
        Log.i(TAG) { "opened ${uriTail(media.uri)}" }
        opened = true
        prefetchHeaders = media.headers
        outgoingSourcePosition = null
        takePlayhead(media.start?.coerceAtLeast(Duration.ZERO) ?: Duration.ZERO)
        if (play) setProperty("pause", "no")
    }

    override suspend fun play() = serial { setProperty("pause", "no") }

    override suspend fun pause() = serial { setProperty("pause", "yes") }

    override suspend fun stop() = serial {
        // `stop` empties the playlist without mpv opening the armed entry. No transition: playback is ending.
        clearArmedNext(adoptIfRolledIn = false)
        command("stop")
        opened = false
    }

    /**
     * Moves the playhead to [position] at once (and says so, [AudioEvent.PlayheadJump]); a refused seek puts it back
     * where it was, unless another source took over meanwhile: nothing in flight against the old source speaks for
     * the new one.
     */
    override suspend fun seek(position: Duration) = serial {
        val target = position.coerceAtLeast(Duration.ZERO)
        val anchor = state.position
        val generation = sourceGeneration
        movePlayhead(target)
        try {
            command("seek", seconds(target), "absolute")
        } catch (e: IllegalStateException) {
            if (generation == sourceGeneration) movePlayhead(anchor)
            throw e
        }
    }

    override suspend fun setNext(media: AudioMedia?) = serial {
        clearArmedNext(adoptIfRolledIn = true)
        if (media == null) return@serial
        check(opened) { "nothing is open to follow" }
        val network = media.uri.startsWith("http://") || media.uri.startsWith("https://")
        val prefetch = network && media.headers == prefetchHeaders
        // Live before the entry joins the playlist, and before a descriptor exists that a failure here would leak.
        setProperty("prefetch-playlist", if (prefetch) "yes" else "no")
        val (uri, fd) = playableUri(media.uri)
        // Armed before mpv has it: a boundary right after the append is already this entry's advance.
        armed = Armed(media.uri, fd, media.headers)
        try {
            command("loadfile", uri, "append", "-1", entryOptions(media))
        } catch (e: IllegalStateException) {
            // The entry never joined the playlist: its descriptor has no other owner.
            armed = null
            if (fd != null) closeFd(fd)
            throw e
        }
        Log.i(TAG) { "armed next ${uriTail(media.uri)} (prefetch $prefetch)" }
    }

    override suspend fun setVolume(percent: Double) = serial {
        setProperty("volume", percent.coerceIn(0.0, 100.0).toString())
    }

    override suspend fun setAudioDevice(name: String) = serial { setProperty("audio-device", name) }

    override suspend fun setAudioPassthrough(enabled: Boolean) = serial {
        if (passthroughCodecs.isNotEmpty()) setProperty("audio-spdif", if (enabled) passthroughCodecs.joinToString(",") else "")
    }

    override suspend fun setVerboseLogging(verbose: Boolean) = serial { core.setLogLevel(if (verbose) "v" else "warn") }

    override suspend fun dispose() = withContext(dispatcher + NonCancellable) {
        mutex.withLock {
            if (disposed) return@withLock
            if (armed != null) {
                try {
                    clearArmedNext(adoptIfRolledIn = false)
                } catch (e: IllegalStateException) {
                    Log.w(TAG, e) { "armed entry not settled before dispose" }
                }
            }
            disposed = true
            if (started) core.destroy()
            eventChannel.close()
            inputs.close()
            scope.cancel()
        }
    }

    // -- Gapless arm --------------------------------------------------------------------------------------------------

    /**
     * Clears the armed entry, if any. mpv may have rolled into it already: removing index 1 then would remove the
     * playing entry, so `playlist-pos` is read first, and an entry already playing is adopted as the advance
     * ([adoptIfRolledIn]; a replacing or stopping caller passes false: nobody listens for that entry any more).
     *
     * Descriptor ownership: mpv owns an `fdclose://` descriptor once it opened the entry. It is closed here only when
     * the entry provably never opened, `playlist-pos` 0 both before and after a remove mpv accepted; anything else
     * leaks the one descriptor rather than risk closing one mpv holds.
     */
    private suspend fun clearArmedNext(adoptIfRolledIn: Boolean) {
        val arm = armed ?: return
        armed = null
        val position = readPlaylistPos()
        if (position == "1") {
            Log.d(TAG) { "clearing an armed entry already playing" }
            if (adoptIfRolledIn) completeArmedAdvance(arm)
            return
        }
        // The handover won't happen: a later advance must not take this snapshot for its outgoing position.
        frozenOutgoing = null
        try {
            command("playlist-remove", "1")
        } catch (e: IllegalStateException) {
            // Entry 1 vanished as mpv rolled into it: the descriptor, if any, is mpv's.
            Log.d(TAG) { "armed entry not removed: ${e.message}" }
            return
        }
        val fd = arm.fd ?: return
        if (position == "0" && readPlaylistPos() == "0") closeFd(fd)
    }

    /**
     * mpv rolled into the armed entry: the new source takes the playhead, the spent entry 0 goes so the playing one is
     * entry 0 again, and its own headers are now what a prefetch would send.
     */
    private fun completeArmedAdvance(arm: Armed) {
        armed = null
        takeSourceOwnership()
        prefetchHeaders = arm.headers
        core.command(listOf("playlist-remove", "0")) { error ->
            if (error != null) Log.w(TAG) { "spent playlist entry not removed: $error" }
        }
        Log.i(TAG) { "advanced gaplessly into ${uriTail(arm.uri)}" }
        emit(AudioEvent.TrackTransition(arm.uri))
    }

    private fun takeSourceOwnership() {
        outgoingSourcePosition = frozenOutgoing ?: lastReported
        takePlayhead(Duration.ZERO)
        emit(AudioEvent.PlayheadJump(Duration.ZERO))
    }

    /** Another source starts at [start]: what came before speaks for the old one. */
    private fun takePlayhead(start: Duration) {
        sourceGeneration++
        frozenOutgoing = null
        lastReported = Duration.ZERO
        lastPositionEvent = null
        state = state.copy(position = start, duration = Duration.ZERO, completed = false)
        emit(AudioEvent.Position(start))
    }

    private fun movePlayhead(position: Duration) {
        state = state.copy(position = position)
        emit(AudioEvent.Position(position))
        emit(AudioEvent.PlayheadJump(position))
    }

    // -- mpv's reports ------------------------------------------------------------------------------------------------

    private fun handle(input: Input) {
        if (disposed) return
        when (input) {
            is Input.Property -> property(input.name, input.value)
            Input.FileLoaded -> fileLoaded()
            is Input.EndFile -> input.error?.let { emit(AudioEvent.Error(it)) }
        }
    }

    private fun property(name: String, value: String?) {
        when (name) {
            "time-pos" -> {
                val position = value?.toDoubleOrNull()?.let { (it * 1000).roundToLong().milliseconds } ?: return
                lastReported = position
                state = state.copy(position = position)
                val last = lastPositionEvent
                if (last == null || last.elapsedNow() >= POSITION_INTERVAL) {
                    lastPositionEvent = TimeSource.Monotonic.markNow()
                    emit(AudioEvent.Position(position))
                }
            }
            "duration" -> {
                val duration = value?.toDoubleOrNull()?.let { (it * 1000).roundToLong().milliseconds } ?: return
                state = state.copy(duration = duration)
                emit(AudioEvent.DurationChanged(duration))
            }
            "pause" -> flag(value)?.let {
                state = state.copy(playing = !it)
                emit(AudioEvent.Playing(!it))
            }
            "paused-for-cache" -> flag(value)?.let {
                state = state.copy(buffering = it)
                emit(AudioEvent.Buffering(it))
            }
            "eof-reached" -> flag(value)?.let {
                state = state.copy(completed = it)
                emit(AudioEvent.Completed(it))
            }
            // Detection rides `file-loaded`; this is only the last report ordered before the new source's positions
            // (the same property flow): the outgoing entry's final position, taken while it is still the current one.
            "playlist-pos" -> if (armed != null) frozenOutgoing = lastReported
        }
    }

    /**
     * A `file-loaded` [open] didn't cause, while an entry is armed, is the gapless advance. It rides mpv's events, not
     * `playlist-pos` edges, which mpv coalesces per observer (1→0→1 can net out to nothing).
     *
     * Each new entry's length is read here too: the observed `duration` comes only when it differs from what mpv sent
     * last, so an entry as long as the one before (an album's tracks of one length) would keep the reset length, 0.
     */
    private fun fileLoaded() {
        if (expectOpenFileLoad) expectOpenFileLoad = false else armed?.let(::completeArmedAdvance)
        core.getProperty("duration") { value, error ->
            if (error == null) inputs.trySend(Input.Property("duration", value))
        }
    }

    // -- mpv requests -------------------------------------------------------------------------------------------------

    /** Runs [block] after every earlier command, on the player's coroutine, never cancelled half way. */
    private suspend fun <T> serial(block: suspend () -> T): T = withContext(dispatcher + NonCancellable) {
        mutex.withLock {
            check(!disposed) { "the audio player is disposed" }
            ensureStarted()
            block()
        }
    }

    private fun ensureStarted() {
        if (!started && startFailure == null) {
            val failure = core.start(OPTIONS + platformOptions, OBSERVED, listener)
            if (failure == null) started = true else startFailure = failure
        }
        startFailure?.let { throw AudioPlayerInitializationException("the audio core didn't start: $it") }
    }

    private suspend fun command(vararg args: String) {
        val reply = CompletableDeferred<String?>()
        core.command(args.toList()) { reply.complete(it) }
        reply.await()?.let { throw IllegalStateException("mpv ${args.first()}: $it") }
    }

    private suspend fun setProperty(name: String, value: String) {
        val reply = CompletableDeferred<String?>()
        core.setProperty(name, value) { reply.complete(it) }
        reply.await()?.let { throw IllegalStateException("mpv $name: $it") }
    }

    /** `playlist-pos`, or null when mpv didn't answer: an unknown position never proves anything. */
    private suspend fun readPlaylistPos(): String? {
        val reply = CompletableDeferred<String?>()
        core.getProperty("playlist-pos") { value, error -> reply.complete(if (error == null) value else null) }
        return reply.await()
    }

    /** [uri] as mpv opens it, and the descriptor it holds; a `content://` URI that doesn't open throws. */
    private fun playableUri(uri: String): Pair<String, Int?> {
        if (!uri.startsWith("content://")) return uri to null
        val fds = contentFds ?: throw IllegalStateException("no opener for ${uriTail(uri)}")
        val fd = fds.open(uri)
        return "fdclose://$fd" to fd
    }

    /** An open's URI: a `content://` one that doesn't open goes to mpv as it is, to fail there with mpv's reason. */
    private fun playableUriOrRaw(uri: String): String = try {
        playableUri(uri).first
    } catch (e: Exception) {
        Log.w(TAG, e) { "content descriptor not opened for ${uriTail(uri)}" }
        uri
    }

    private fun closeFd(fd: Int) {
        try {
            contentFds?.close(fd)
        } catch (e: Exception) {
            Log.w(TAG, e) { "content descriptor $fd not closed" }
        }
    }

    /** An mpv flag's string value (`yes`, `no`); null while mpv has none. */
    private fun flag(value: String?): Boolean? = when (value) {
        "yes" -> true
        "no" -> false
        else -> null
    }

    private fun emit(event: AudioEvent) {
        eventChannel.trySend(event)
    }

    private class Armed(val uri: String, val fd: Int?, val headers: Map<String, String>)

    private sealed interface Input {
        class Property(val name: String, val value: String?) : Input
        data object FileLoaded : Input
        class EndFile(val error: String?) : Input
    }

    companion object {
        private const val TAG = "MpvAudio"
        private val POSITION_INTERVAL = 250.milliseconds

        /**
         * The audio core's startup options after every engine's: no video at all (embedded cover art never becomes a
         * video track, no window), gapless splicing of the armed entry when its format matches, an idle core between
         * files, and the null output when the device goes (a sleep, an unplugged headset) instead of no audio for good.
         */
        val OPTIONS: Map<String, String> = COMMON_MPV_OPTIONS + linkedMapOf(
            "vid" to "no",
            "vo" to "null",
            "force-window" to "no",
            "audio-display" to "no",
            "gapless-audio" to "weak",
            "idle" to "yes",
            "audio-fallback-to-null" to "yes",
        )

        /** What the player follows, each as its string value. */
        val OBSERVED: List<String> = listOf("time-pos", "duration", "pause", "paused-for-cache", "eof-reached", "playlist-pos")

        /**
         * One entry's `loadfile` options: its HTTP headers as one list value (the options are a key/value list whose
         * repeated key replaces the earlier pair), and where it starts. mpv's list splitter drops a backslash right
         * before a `,` and keeps every other, so a comma in a value (`X-Plex-Device: Mac17,9`) goes as `\,`, and an
         * item ending in `\` gets a trailing space (whitespace HTTP strips) so it can't escape the separator after it.
         * The fixed-length quote (`%N%`) shields the list from the outer split. No headers clears the list: a bare
         * empty value would be one empty item, a blank header line.
         */
        internal fun entryOptions(media: AudioMedia): String {
            val headers = if (media.headers.isEmpty()) {
                "http-header-fields-clr="
            } else {
                val items = media.headers.map { (name, value) ->
                    val item = "$name: $value".replace(",", "\\,")
                    if (item.endsWith("\\")) "$item " else item
                }
                "http-header-fields=${fixedLengthQuote(items.joinToString(","))}"
            }
            val start = media.start?.takeIf { it > Duration.ZERO }?.let { ",start=${seconds(it)}" }.orEmpty()
            return headers + start
        }

        private fun fixedLengthQuote(value: String): String = "%${value.encodeToByteArray().size}%$value"

        private fun seconds(position: Duration): String = (position.inWholeMilliseconds / 1000.0).toString()

        /** The query-free tail of [uri] for the log: the part's id stays, tokens don't. */
        private fun uriTail(uri: String): String {
            val path = uri.substringBefore('?')
            return if (path.length <= 40) path else "…" + path.takeLast(40)
        }
    }
}
