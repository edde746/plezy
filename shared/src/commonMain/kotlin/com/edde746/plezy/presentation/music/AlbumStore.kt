package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.backend.localizedLoadErrorMessage
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.music.MusicPlaybackStatus
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.downloads.detailDownloadVisible
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * An album's screen.
 *
 * @param rows the tracks, with "Disc N" headers on a multi-disc album ([albumRows]).
 * @param instantMix the album's server offers Instant Mix.
 * @param playingKey the session's current track: its row shows the equalizer (animated while [playing]).
 * @param offline the tracks are the album's downloaded ones, played from their files (the app is offline or the
 *   server is out of reach).
 * @param download the Download button; null hides it (offline, no downloads).
 */
data class AlbumUiState(
    val load: LoadState = LoadState.LOADING,
    val header: MusicHeaderUi? = null,
    val rows: List<AlbumRow> = emptyList(),
    val instantMix: Boolean = false,
    val playingKey: String? = null,
    val playing: Boolean = false,
    val error: String? = null,
    val offline: Boolean = false,
    val download: DownloadButtonSpec? = null,
)

/**
 * The album screen's store: the album and its tracks in disc and track order ([com.edde746.plezy.backend.MediaBackend.fetchAlbumTracks]);
 * Play, Shuffle and a tapped row play the album (from that row). Offline (or when the server's tracks fail to load
 * and some are downloaded) it shows the downloaded tracks and plays them from their files. The Download button queues
 * the album's every track, or offers deleting a completed one. [close] when the screen goes.
 */
class AlbumStore internal constructor(private val screens: MusicScreens, private val route: Route.MusicAlbum, parentScope: CoroutineScope) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(AlbumUiState())
    private val backend = screens.backend(route.serverId)
    private var album: MediaItem? = null
    private var tracks: List<MediaItem> = emptyList()
    private var offline = false
    private var loading: Job? = null

    val state: StateFlow<AlbumUiState> = mutableState.asStateFlow()

    /** The loaded album (the overflow's item menu, the Apple UIs' download button); null until it loads. */
    val item: MediaItem? get() = album

    init {
        scope.launch {
            screens.playback.state.collect { music ->
                mutableState.update { it.copy(playingKey = music.currentTrack?.globalKey, playing = music.status == MusicPlaybackStatus.PLAYING) }
            }
        }
        screens.downloads?.let { downloads -> scope.launch { downloads.changes.collect { publishDownload() } } }
        load()
    }

    fun retry() {
        mutableState.update { it.copy(load = LoadState.LOADING, error = null) }
        load()
    }

    fun play() = playAll(shuffle = false)

    fun shuffle() = playAll(shuffle = true)

    /** A track row tapped: the album plays from it. */
    fun playFrom(index: Int) {
        val track = tracks.getOrNull(index) ?: return
        scope.launch { screens.playTracks(tracks, context(), startTrack = track, offline = offline) }
    }

    fun instantMix() {
        val album = album ?: return
        scope.launch { screens.playInstantMix(album) }
    }

    /** The artist line: the album's artist opens. */
    fun openArtist() {
        val artistId = album?.parentId ?: return
        screens.openArtist(route.serverId, artistId)
    }

    /** Where this screen's item menus open (the overflow's, a track's): a track's has no Go to album, this being it. */
    val menuPlace: MenuPlace get() = MenuPlace(albumId = route.id)

    /** The track at [index], for its item menu. */
    fun track(index: Int): MediaItem? = tracks.getOrNull(index)

    /** The Download button pressed: [MusicDownloads.press]'s feedback shows as a snackbar. */
    fun download() {
        val album = album ?: return
        val downloads = screens.downloads ?: return
        val backend = backend ?: return
        scope.launch {
            try {
                downloads.press(album, backend)?.let { screens.message(it.message, it.isError) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                screens.message(T.messages.errorLoading(localizedErrorReason(e)), error = true)
            }
        }
    }

    fun close() = scope.cancel()

    private fun publishDownload() {
        val album = album
        val downloads = screens.downloads
        val visible = album != null && downloads != null && backend != null && detailDownloadVisible(offline, downloadsSupported = true)
        mutableState.update { it.copy(download = if (visible) downloads!!.buttonSpec(album!!) else null) }
    }

    private fun playAll(shuffle: Boolean) {
        if (tracks.isEmpty()) return screens.message(T.messages.noItemsAvailable)
        scope.launch { screens.playTracks(tracks, context(), shuffle = shuffle, offline = offline) }
    }

    private fun context() = MusicPlayContext(album?.displayTitle.orEmpty(), MusicPlayContextKind.ALBUM)

    private fun load() {
        loading?.cancel()
        loading = scope.launch {
            if (screens.offlineFor(route.serverId)) {
                if (!showDownloaded()) {
                    mutableState.update { it.copy(load = LoadState.EMPTY, offline = true, download = null) }
                }
                return@launch
            }
            try {
                val backend = backend ?: throw IllegalStateException("No client for ${route.serverId}")
                val (item, fetched) = coroutineScope {
                    val item = async { backend.fetchItem(route.id) }
                    val fetched = backend.fetchAlbumTracks(route.id)
                    item.await() to fetched
                }
                val album = item ?: throw IllegalStateException("Album ${route.id} not found")
                show(album, fetched, backend.squareArtwork(album), offline = false)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (showDownloaded()) return@launch
                mutableState.update { it.copy(load = LoadState.ERROR, error = localizedLoadErrorMessage(e, album?.displayTitle ?: T.common.mediaKind.album)) }
            }
        }
    }

    /** Shows the album's downloaded tracks; false when none are. */
    private fun showDownloaded(): Boolean {
        val downloads = screens.downloads ?: return false
        val key = musicGlobalKey(route.serverId, route.id)
        val fetched = downloads.albumTracks(key)
        val first = fetched.firstOrNull() ?: return false
        val album = downloads.item(key) ?: MediaItem(
            id = route.id,
            backend = first.backend,
            kind = MediaKind.ALBUM,
            title = first.albumTitle,
            parentId = first.grandparentId,
            parentTitle = first.grandparentTitle,
            year = first.year,
            thumbPath = first.parentThumbPath,
            serverId = route.serverId,
        )
        show(album, fetched, Artwork.fixed(downloads.artwork(album) ?: downloads.artwork(first)), offline = true)
        return true
    }

    private fun show(album: MediaItem, fetched: List<MediaItem>, artwork: Artwork?, offline: Boolean) {
        this.album = album
        this.offline = offline
        tracks = fetched
        val total = fetched.sumOf { it.durationMs ?: 0 }
        val meta = listOfNotNull(
            album.year?.toString(),
            T.music.trackCount(fetched.size).takeIf { fetched.isNotEmpty() },
            formatDurationTextual(total).takeIf { total > 0 },
        )
        val artist = album.albumArtistTitle?.takeIf { it.isNotEmpty() }
        mutableState.update {
            it.copy(
                load = if (fetched.isEmpty()) LoadState.EMPTY else LoadState.CONTENT,
                header = MusicHeaderUi(
                    title = album.displayTitle,
                    artwork = artwork,
                    artist = artist,
                    artistLinked = artist != null && album.parentId != null,
                    meta = bulleted(meta).ifEmpty { null },
                ),
                rows = albumRows(fetched),
                instantMix = !offline && screens.instantMixAvailable(album),
                error = null,
                offline = offline,
            )
        }
        publishDownload()
    }
}
