package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.backend.localizedLoadErrorMessage
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.LibrarySort
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.music.InstantMixFeedback
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.music.MusicPlayback
import com.edde746.plezy.music.playFetchedTracks
import com.edde746.plezy.music.playInstantMixFeedback
import com.edde746.plezy.music.playTrackWithAlbumContext
import com.edde746.plezy.music.playTracks
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch

/** A snackbar the music screens show: [error] ones in the error style. */
data class MusicMessage(val text: String, val error: Boolean)

/**
 * The music entries of an artist's, album's or track's item menu ([MusicMenuEntries]), in display order
 * ([MusicScreens.menuActions]).
 */
internal enum class MusicMenuAction {
    PLAY,
    PLAY_NEXT,
    ADD_TO_QUEUE,
    INSTANT_MIX,
    GO_TO_ALBUM,
    GO_TO_ARTIST,
    ;

    val label: String
        get() = when (this) {
            PLAY -> T.common.play
            PLAY_NEXT -> T.music.playNext
            ADD_TO_QUEUE -> T.music.addToQueue
            INSTANT_MIX -> T.music.instantMix
            GO_TO_ALBUM -> T.music.goToAlbum
            GO_TO_ARTIST -> T.music.goToArtist
        }
}

/**
 * The music screens' shared ground: the profile's music session, the servers the items come from, where the screens
 * go and the snackbars they show ([messages]). It makes each music screen's store; the app makes one per profile
 * session. Main thread only.
 *
 * @param clients the client of a connected server.
 * @param serverOnline whether a server answers now (Instant Mix in a menu needs it).
 * @param tv a TV, which has no mini-player: starting playback opens Now Playing, the rail shows a Now Playing item.
 * @param offline the app is in offline mode (the TV rail's Now Playing item hides; album and artist screens show their
 *   downloaded tracks).
 * @param downloads the downloads (offline albums and artists, the album Download button); null without downloads.
 * @param sleepTimerMinutes the configured sleep timer minutes (`sleep_timer_duration`), offered among the durations.
 */
class MusicScreens(
    val playback: MusicPlayback,
    private val navigator: PlezyNavigator,
    private val clients: (ServerId) -> MediaBackend?,
    private val serverOnline: (ServerId) -> Boolean,
    val tv: Boolean,
    internal val offline: StateFlow<Boolean>,
    internal val sleepTimerMinutes: StateFlow<Int>,
    parentScope: CoroutineScope,
    val downloads: MusicDownloads? = null,
) {
    internal val scope = parentScope.childScope()
    private val mutableMessages = MutableSharedFlow<MusicMessage>(extraBufferCapacity = 8)

    /** Snackbars to show, each once. */
    val messages: SharedFlow<MusicMessage> = mutableMessages.asSharedFlow()

    internal val backStack get() = navigator.backStack

    fun nowPlaying(): NowPlayingStore = NowPlayingStore(this, scope)

    fun miniPlayer(): MiniPlayerStore = MiniPlayerStore(this, scope)

    fun album(route: Route.MusicAlbum): AlbumStore = AlbumStore(this, route, scope)

    fun artist(route: Route.MusicArtist): ArtistStore = ArtistStore(this, route, scope)

    /** [delete] asks, then deletes a playlist, calling back once it is gone. */
    fun playlist(route: Route.MusicPlaylist, delete: (MediaPlaylist, onDeleted: () -> Unit) -> Unit): MusicPlaylistStore =
        MusicPlaylistStore(this, route, delete, scope)

    /** The client of [serverId]'s server, if it is connected. */
    fun backend(serverId: String?): MediaBackend? = ServerId.tryParse(serverId)?.let(clients)

    /** [item]'s server offers Instant Mix. */
    fun instantMixAvailable(item: MediaItem): Boolean = backend(item.serverId)?.capabilities?.instantMix == true

    /** Opens Now Playing; nothing when it already shows. */
    fun openNowPlaying() {
        if (navigator.current != Route.NowPlaying) navigator.navigate(Route.NowPlaying)
    }

    /** The session ended: Now Playing leaves, and only it, wherever it is on the stack. */
    internal fun closeNowPlaying() {
        navigator.remove(Route.NowPlaying)
    }

    /** Leaves the screen on top (a deleted playlist's). */
    internal fun back() = navigator.back()

    fun openArtist(serverId: String, artistId: String) = navigator.navigate(Route.MusicArtist(serverId, artistId))

    fun openAlbum(serverId: String, albumId: String) = navigator.navigate(Route.MusicAlbum(serverId, albumId))

    /** A music card's tap: an artist or an album opens, a track plays in its album. */
    fun open(item: MediaItem) {
        val serverId = item.serverId ?: return
        when (item.kind) {
            MediaKind.ARTIST -> openArtist(serverId, item.id)
            MediaKind.ALBUM -> openAlbum(serverId, item.id)
            MediaKind.TRACK -> scope.launch { started(playback.playTrackWithAlbumContext(item, backend(serverId))) }
            else -> Log.w(TAG) { "No music screen for ${item.kind}" }
        }
    }

    internal fun message(text: String, error: Boolean = false) {
        mutableMessages.tryEmit(MusicMessage(text, error))
    }

    /** Playback started from a screen: a TV shows Now Playing (it has no mini-player). */
    internal fun started(started: Boolean) {
        if (started && tv) openNowPlaying()
    }

    internal suspend fun playTracks(
        tracks: List<MediaItem>,
        context: MusicPlayContext,
        startTrack: MediaItem? = null,
        shuffle: Boolean = false,
        offline: Boolean = false,
    ) {
        if (tracks.isEmpty()) return message(T.messages.noItemsAvailable)
        started(playback.playTracks(tracks, startTrack, context, shuffle, offline))
    }

    /**
     * Whether [serverId]'s music shows from the downloads: the app is offline, or the server has no client. Never
     * without downloads.
     */
    internal fun offlineFor(serverId: String): Boolean = downloads != null && (offline.value || backend(serverId) == null)

    /**
     * A track of the Downloads screen's Music tab tapped: [tracks] (its downloaded siblings) play from [index] fully
     * offline, under their album ([album], the albums grouping) or the Downloads title (the tracks grouping).
     */
    fun playDownloaded(tracks: List<MediaItem>, index: Int, album: Boolean) {
        val start = tracks.getOrNull(index) ?: return
        val context = if (album) {
            MusicPlayContext(start.albumTitle.orEmpty(), MusicPlayContextKind.ALBUM)
        } else {
            MusicPlayContext(T.downloads.title, MusicPlayContextKind.TRACKS)
        }
        scope.launch { playTracks(tracks, context, startTrack = start, offline = true) }
    }

    /**
     * Shuffle on the music [library]: up to [LIBRARY_SHUFFLE_TRACKS] of its tracks, drawn at random by its server in one
     * request (a large library is never read whole), play shuffled under the library's title.
     */
    fun shuffleLibrary(library: MediaLibrary) {
        val backend = backend(library.serverId) ?: return message(T.errors.noClientAvailable, error = true)
        val query = LibraryQuery(kind = MediaKind.TRACK, limit = LIBRARY_SHUFFLE_TRACKS, sort = LibrarySort(RANDOM_SORT))
        scope.launch {
            started(
                playback.playFetchedTracks(
                    fetch = { backend.fetchLibraryPagedContent(library.id, query, library.kind).items.filter { it.kind == MediaKind.TRACK } },
                    playContext = MusicPlayContext(library.title, MusicPlayContextKind.LIBRARY),
                    onError = { message(localizedLoadErrorMessage(it, library.title), error = true) },
                    onEmpty = { message(T.messages.noItemsAvailable) },
                    shuffle = true,
                ),
            )
        }
    }

    /** An Instant Mix seeded from [seed]; its failure or emptiness says so. */
    internal suspend fun playInstantMix(seed: MediaItem) {
        when (val feedback = playback.playInstantMixFeedback(seed)) {
            InstantMixFeedback.Started -> started(true)
            InstantMixFeedback.Silent -> Unit
            is InstantMixFeedback.Failed -> message(feedback.message, error = true)
        }
    }

    /**
     * [item]'s music menu: Play; Play next and Add to queue; Instant Mix while its server offers it and answers; Go to
     * album (a track) unless that album's screen is [albumScreen]; Go to artist (an album's, a track's) unless that
     * artist's screen is [artistScreen].
     */
    internal fun menuActions(item: MediaItem, albumScreen: String? = null, artistScreen: String? = null): List<MusicMenuAction> {
        val artistId = when (item.kind) {
            MediaKind.ALBUM -> item.parentId
            MediaKind.TRACK -> item.grandparentId
            else -> null
        }
        val online = ServerId.tryParse(item.serverId)?.let(serverOnline) == true
        return buildList {
            add(MusicMenuAction.PLAY)
            add(MusicMenuAction.PLAY_NEXT)
            add(MusicMenuAction.ADD_TO_QUEUE)
            if (online && instantMixAvailable(item)) add(MusicMenuAction.INSTANT_MIX)
            if (item.kind == MediaKind.TRACK && item.parentId != null && item.parentId != albumScreen) add(MusicMenuAction.GO_TO_ALBUM)
            if (artistId != null && artistId != artistScreen) add(MusicMenuAction.GO_TO_ARTIST)
        }
    }

    /** Runs [action] of [item]'s menu ([menuActions]). */
    internal fun runMenuAction(item: MediaItem, action: MusicMenuAction) {
        val serverId = item.serverId
        when (action) {
            MusicMenuAction.PLAY -> launchReporting(item) { play(item) }
            MusicMenuAction.PLAY_NEXT -> launchReporting(item) { enqueue(item, next = true) }
            MusicMenuAction.ADD_TO_QUEUE -> launchReporting(item) { enqueue(item, next = false) }
            MusicMenuAction.INSTANT_MIX -> scope.launch { playInstantMix(item) }
            MusicMenuAction.GO_TO_ALBUM -> if (serverId != null && item.parentId != null) openAlbum(serverId, item.parentId)
            MusicMenuAction.GO_TO_ARTIST -> {
                val artistId = if (item.kind == MediaKind.ALBUM) item.parentId else item.grandparentId
                if (serverId != null && artistId != null) openArtist(serverId, artistId)
            }
        }
    }

    /** Play from a menu: a track in its album, an album's tracks, an artist's every track. */
    private suspend fun play(item: MediaItem) {
        if (item.kind == MediaKind.TRACK) return started(playback.playTrackWithAlbumContext(item, backend(item.serverId)))
        val kind = if (item.kind == MediaKind.ARTIST) MusicPlayContextKind.ARTIST else MusicPlayContextKind.ALBUM
        started(playback.playFetchedTracks(fetch = { tracksOf(item) }, playContext = MusicPlayContext(item.displayTitle, kind)))
    }

    /** Play next or Add to queue; dropped when another session started while the tracks loaded, or there are none. */
    private suspend fun enqueue(item: MediaItem, next: Boolean) {
        val revision = playback.queueSessionRevision
        val tracks = try {
            tracksOf(item)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (playback.queueSessionRevision != revision) return
            throw e
        }
        if (playback.queueSessionRevision != revision || tracks.isEmpty()) return
        if (next) playback.addNext(tracks) else playback.addToEnd(tracks)
    }

    /** The tracks a music action works on: the track itself, an album's, an artist's every playable one. */
    private suspend fun tracksOf(item: MediaItem): List<MediaItem> = when (item.kind) {
        MediaKind.ALBUM -> requireBackend(item).fetchAlbumTracks(item.id)
        MediaKind.ARTIST -> requireBackend(item).fetchPlayableDescendants(item.id)
        else -> listOf(item)
    }

    private fun requireBackend(item: MediaItem): MediaBackend =
        backend(item.serverId) ?: throw IllegalStateException("No client for ${item.serverId}")

    /** Runs [block], showing its failure as a snackbar. */
    private fun launchReporting(item: MediaItem, block: suspend () -> Unit) {
        scope.launch {
            try {
                block()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Music action on ${item.globalKey} failed" }
                message(T.messages.errorLoading(localizedErrorReason(e)), error = true)
            }
        }
    }

    private companion object {
        /** The most tracks a shuffled music library queues. */
        const val LIBRARY_SHUFFLE_TRACKS = 200
        const val RANDOM_SORT = "random"
        const val TAG = "MusicScreens"
    }
}
