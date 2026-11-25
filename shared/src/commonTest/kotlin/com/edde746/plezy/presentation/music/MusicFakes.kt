package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.music.InstantMixOutcome
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.music.MusicPlayback
import com.edde746.plezy.music.MusicPlaybackStatus
import com.edde746.plezy.music.MusicRepeatMode
import com.edde746.plezy.music.MusicState
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes

const val SERVER = "server_1"

/** A track of [album] (released [year]) by "Artist [id]", three minutes long, on [SERVER]. */
fun musicTrack(
    id: String,
    title: String = "Track $id",
    album: String = "Album",
    year: Int? = null,
    disc: Int? = null,
    number: Int? = null,
    serverId: String = SERVER,
    artist: String = "Artist $id",
    trackArtist: String? = null,
) = MediaItem(
    id = id,
    backend = BackendKind.PLEX,
    kind = MediaKind.TRACK,
    title = title,
    parentId = "album_$id",
    parentTitle = album,
    parentIndex = disc,
    index = number,
    grandparentId = "artist_$id",
    grandparentTitle = artist,
    originalTitle = trackArtist,
    year = year,
    durationMs = 3.minutes.inWholeMilliseconds,
    serverId = serverId,
)

/** A [MusicPlayback] whose state, playhead, jumps and errors the test drives, recording what it was asked. */
class FakeMusicPlayback : MusicPlayback {
    override val state = MutableStateFlow(MusicState())
    override val position = MutableStateFlow(Duration.ZERO)
    override val playheadJumps = MutableSharedFlow<Duration?>(extraBufferCapacity = 8)
    override val errors = MutableSharedFlow<Throwable>(extraBufferCapacity = 8)
    override val volumePreview = MutableStateFlow(100.0)
    override var queueSessionRevision = 0

    val seeks = mutableListOf<Duration>()
    val jumps = mutableListOf<Int>()
    val calls = mutableListOf<String>()
    val played = mutableListOf<Triple<List<String>, String?, MusicPlayContext>>()
    /** Each play's offline flag, in [played]'s order. */
    val offlinePlays = mutableListOf<Boolean>()
    var shuffledPlays = 0
    var lyrics: (MediaItem) -> Lyrics? = { null }
    var mix: suspend (MediaItem) -> InstantMixOutcome = { InstantMixOutcome.STARTED }
    private var intent = 0

    /** Plays [track] at [index] of [queue] from 0 under [context]. */
    fun playing(track: MediaItem, context: MusicPlayContext? = null, queue: List<MediaItem> = listOf(track), index: Int = queue.indexOf(track)) {
        position.value = Duration.ZERO
        state.value = state.value.copy(
            status = MusicPlaybackStatus.PLAYING,
            currentTrack = track,
            queue = queue,
            currentIndex = index,
            playContext = context ?: state.value.playContext,
            duration = 3.minutes,
        )
    }

    /** The session ended elsewhere (a stop, an error, a video taking the audio). */
    fun end() {
        state.value = MusicState()
    }

    override fun beginPlayIntent(): Int = ++intent
    override fun isPlayIntentCurrent(intent: Int): Boolean = intent == this.intent

    override suspend fun playFromList(
        tracks: List<MediaItem>,
        startTrack: MediaItem?,
        playContext: MusicPlayContext,
        shuffle: Boolean,
        initialPosition: Duration?,
        offline: Boolean,
    ) {
        beginPlayIntent()
        if (tracks.isEmpty()) return
        played += Triple(tracks.map { it.id }, startTrack?.id, playContext)
        offlinePlays += offline
        if (shuffle) shuffledPlays++
        playing(startTrack ?: tracks.first(), playContext, tracks)
    }

    override suspend fun playInstantMix(seed: MediaItem): InstantMixOutcome {
        calls += "mix:${seed.id}"
        return mix(seed)
    }

    override suspend fun play() { calls += "play" }
    override suspend fun pause() { calls += "pause" }
    override suspend fun togglePlayPause() { calls += "toggle" }
    override suspend fun next() { calls += "next" }
    override suspend fun previous() { calls += "previous" }

    override suspend fun seek(position: Duration) {
        seeks += position
        this.position.value = position
    }

    override suspend fun setVolume(volume: Double, persist: Boolean) {
        calls += "volume:$volume:$persist"
        volumePreview.value = volume
    }

    override fun setRepeatMode(mode: MusicRepeatMode) {
        state.value = state.value.copy(repeatMode = mode)
    }

    override fun toggleShuffle() {
        state.value = state.value.copy(shuffled = !state.value.shuffled)
    }

    override suspend fun jumpTo(index: Int) {
        jumps += index
    }

    override fun removeAt(index: Int) { calls += "remove:$index" }
    override fun reorder(from: Int, to: Int) { calls += "reorder:$from:$to" }
    override fun addNext(tracks: List<MediaItem>) { calls += "next:${tracks.map { it.id }}" }
    override fun addToEnd(tracks: List<MediaItem>) { calls += "end:${tracks.map { it.id }}" }
    override fun clearUpcoming() { calls += "clear" }

    override suspend fun stop() {
        calls += "stop"
        end()
    }

    override fun setSleepTimer(duration: Duration?, endOfTrack: Boolean) {
        state.value = state.value.copy(
            sleepTimerActive = duration != null || endOfTrack,
            sleepTimerDuration = duration,
            sleepTimerEndOfTrack = endOfTrack,
        )
    }

    override suspend fun fetchLyrics(track: MediaItem): Lyrics? {
        calls += "lyrics:${track.id}"
        return lyrics(track)
    }
}

/** The music screens over [playback], one server [backend] and a navigator on Home. */
class MusicHarness(
    scope: CoroutineScope,
    val playback: FakeMusicPlayback = FakeMusicPlayback(),
    val backend: FakeMediaBackend = FakeMediaBackend(SERVER),
    tv: Boolean = false,
    online: Boolean = true,
    val offline: MutableStateFlow<Boolean> = MutableStateFlow(false),
    downloads: MusicDownloads? = null,
    val sleepTimerMinutes: MutableStateFlow<Int> = MutableStateFlow(30),
) {
    val navigator = PlezyNavigator(Route.Home)
    val messages = mutableListOf<MusicMessage>()
    val screens = MusicScreens(
        playback = playback,
        navigator = navigator,
        clients = { if (it == ServerId(SERVER)) backend else null },
        serverOnline = { online },
        tv = tv,
        offline = offline,
        sleepTimerMinutes = sleepTimerMinutes,
        parentScope = scope,
        downloads = downloads,
    )

    init {
        scope.launch(start = CoroutineStart.UNDISPATCHED) { screens.messages.collect { messages += it } }
    }

    fun albumContext(title: String = "Album") = MusicPlayContext(title, MusicPlayContextKind.ALBUM)

    /** The playlists Delete Playlist was confirmed for, in order. */
    val deleted = mutableListOf<MediaPlaylist>()

    /** The playlist [id]'s screen, whose Delete Playlist confirms at once. */
    fun playlist(id: String = "pl") = screens.playlist(Route.MusicPlaylist(SERVER, id)) { playlist, onDeleted ->
        deleted += playlist
        onDeleted()
    }
}
