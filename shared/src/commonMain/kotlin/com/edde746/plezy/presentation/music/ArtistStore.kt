package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.localizedLoadErrorMessage
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.ArtistDiscographyGroup
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.music.playFetchedTracks
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** One section of an artist's discography: a titled grid, or the one untitled grid when there is a single group. */
data class DiscographySectionUi(val title: String?, val cards: List<MediaCardUi>)

/**
 * An artist's screen: the circular portrait, name, genres and bio ([header]), and the discography as sections in the
 * order Albums, Singles & EPs, Live, Compilations (empty ones dropped; a single group is one grid without a title).
 */
data class ArtistUiState(
    val load: LoadState = LoadState.LOADING,
    val header: MusicHeaderUi? = null,
    val sections: List<DiscographySectionUi> = emptyList(),
    val instantMix: Boolean = false,
    val error: String? = null,
    val offline: Boolean = false,
)

/** The section title of a discography group. */
val DiscographyGroupKind.title: String
    get() = when (this) {
        DiscographyGroupKind.ALBUMS -> T.libraries.groupings.albums
        DiscographyGroupKind.SINGLES_AND_EPS -> T.music.discography.singlesAndEps
        DiscographyGroupKind.LIVE -> T.music.discography.live
        DiscographyGroupKind.COMPILATIONS -> T.music.discography.compilations
    }

/**
 * The artist screen's store: the artist and its discography ([com.edde746.plezy.backend.MediaBackend.fetchArtistDiscography]).
 * Play and Shuffle fetch every playable track of the artist; an album card opens the album. Offline (or when the server
 * fails to load and some are downloaded) it shows the artist's downloaded albums, Play and Shuffle playing the
 * downloaded tracks from their files. [close] when the screen goes.
 */
class ArtistStore internal constructor(private val screens: MusicScreens, private val route: Route.MusicArtist, parentScope: CoroutineScope) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(ArtistUiState())
    private val backend = screens.backend(route.serverId)
    private var artist: MediaItem? = null
    private var albums: Map<String, MediaItem> = emptyMap()
    private var downloadedTracks: List<MediaItem>? = null
    private var loading: Job? = null

    val state: StateFlow<ArtistUiState> = mutableState.asStateFlow()

    init {
        load()
    }

    fun retry() {
        mutableState.update { it.copy(load = LoadState.LOADING, error = null) }
        load()
    }

    fun play() = playAll(shuffle = false)

    fun shuffle() = playAll(shuffle = true)

    fun instantMix() {
        val artist = artist ?: return
        scope.launch { screens.playInstantMix(artist) }
    }

    /** A discography card ([MediaCardUi.id]) tapped: its album opens. */
    fun open(cardId: String) {
        albums[cardId]?.let(screens::open)
    }

    /** Where a card's item menu opens: it has no Go to artist, this being it. */
    val menuPlace: MenuPlace get() = MenuPlace(artistId = route.id)

    /** A discography card's album ([MediaCardUi.id]), for its item menu. */
    fun card(cardId: String): MediaItem? = albums[cardId]

    fun close() = scope.cancel()

    private fun playAll(shuffle: Boolean) {
        val artist = artist ?: return
        downloadedTracks?.let { tracks ->
            val context = MusicPlayContext(artist.displayTitle, MusicPlayContextKind.ARTIST)
            scope.launch { screens.playTracks(tracks, context, shuffle = shuffle, offline = true) }
            return
        }
        val backend = backend ?: return
        scope.launch {
            val started = screens.playback.playFetchedTracks(
                fetch = { backend.fetchPlayableDescendants(artist.id) },
                playContext = MusicPlayContext(artist.displayTitle, MusicPlayContextKind.ARTIST),
                onError = { screens.message(localizedLoadErrorMessage(it, artist.displayTitle), error = true) },
                onEmpty = { screens.message(T.messages.noItemsAvailable) },
                shuffle = shuffle,
            )
            screens.started(started)
        }
    }

    private fun load() {
        loading?.cancel()
        loading = scope.launch {
            if (screens.offlineFor(route.serverId)) {
                if (!showDownloaded()) mutableState.update { it.copy(load = LoadState.EMPTY, offline = true) }
                return@launch
            }
            try {
                val backend = backend ?: throw IllegalStateException("No client for ${route.serverId}")
                val artist = this@ArtistStore.artist ?: backend.fetchItem(route.id) ?: throw IllegalStateException("Artist ${route.id} not found")
                this@ArtistStore.artist = artist
                mutableState.update {
                    it.copy(
                        header = MusicHeaderUi(
                            title = artist.displayTitle,
                            artwork = backend.squareArtwork(artist),
                            meta = artist.genres.orEmpty().takeIf { g -> g.isNotEmpty() }?.let(::bulleted),
                            bio = artist.summary?.takeIf { s -> s.isNotEmpty() },
                        ),
                        instantMix = screens.instantMixAvailable(artist),
                    )
                }
                val groups = backend.fetchArtistDiscography(artist)
                albums = groups.flatMap { it.items }.associateBy { it.globalKey }
                val sections = discographySections(groups) { albumCard(musicCard(it, backend), it, artist) }
                mutableState.update { it.copy(load = if (sections.isEmpty()) LoadState.EMPTY else LoadState.CONTENT, sections = sections, error = null) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (showDownloaded()) return@launch
                mutableState.update { it.copy(load = LoadState.ERROR, error = localizedLoadErrorMessage(e, artist?.displayTitle ?: T.common.mediaKind.artist)) }
            }
        }
    }

    /** Shows the artist's downloaded albums (one untitled grid); false when nothing of the artist is downloaded. */
    private fun showDownloaded(): Boolean {
        val downloads = screens.downloads ?: return false
        val tracks = downloads.artistTracks(route.serverId, route.id)
        val first = tracks.firstOrNull() ?: return false
        val artist = this.artist ?: downloads.item(musicGlobalKey(route.serverId, route.id)) ?: MediaItem(
            id = route.id,
            backend = first.backend,
            kind = MediaKind.ARTIST,
            title = first.grandparentTitle,
            thumbPath = first.grandparentThumbPath,
            serverId = route.serverId,
        )
        this.artist = artist
        val downloadedAlbums = tracks.mapNotNull { it.parentId }.distinct().mapNotNull { albumId ->
            val track = tracks.first { it.parentId == albumId }
            downloads.item(musicGlobalKey(route.serverId, albumId)) ?: MediaItem(
                id = albumId,
                backend = track.backend,
                kind = MediaKind.ALBUM,
                title = track.albumTitle,
                parentId = route.id,
                parentTitle = track.grandparentTitle,
                year = track.year,
                thumbPath = track.parentThumbPath,
                serverId = route.serverId,
            )
        }
        albums = downloadedAlbums.associateBy { it.globalKey }
        downloadedTracks = tracks
        val cards = downloadedAlbums.map { albumCard(musicCard(it, null).copy(artwork = Artwork.fixed(downloads.artwork(it))), it, artist) }
        mutableState.update {
            it.copy(
                load = LoadState.CONTENT,
                header = MusicHeaderUi(title = artist.displayTitle, artwork = Artwork.fixed(downloads.artwork(artist))),
                sections = listOf(DiscographySectionUi(null, cards)),
                instantMix = false,
                error = null,
                offline = true,
            )
        }
        return true
    }
}

/**
 * [card] of [album] on [artist]'s page: captioned with its year, as the page already names the artist; an album of
 * another artist (a compilation it appears on) keeps that artist's name.
 */
private fun albumCard(card: MediaCardUi, album: MediaItem, artist: MediaItem): MediaCardUi {
    val albumArtist = album.albumArtistTitle
    return if (albumArtist == null || albumArtist == artist.displayTitle) card.copy(caption = album.year?.toString()) else card
}

/** [groups] as sections: titled when there are several, one untitled grid for one. */
internal fun discographySections(groups: List<ArtistDiscographyGroup>, card: (MediaItem) -> MediaCardUi): List<DiscographySectionUi> {
    val shown = groups.filter { it.items.isNotEmpty() }
    return shown.map { DiscographySectionUi(if (shown.size > 1) it.kind.title else null, it.items.map(card)) }
}
