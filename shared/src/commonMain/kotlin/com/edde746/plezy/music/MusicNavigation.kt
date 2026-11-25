package com.edde746.plezy.music

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.drainPages
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException

/*
 * The music entry points the screens share. Each answers whether playback started, so a TV (no mini-player) can open
 * Now Playing; a caller whose scope goes away mid-fetch is cancelled with it.
 */

private const val TAG = "MusicNavigation"
private const val PLAYLIST_PAGE_SIZE = 200

/** Plays [tracks] ([offline]: their downloaded copies only); true when a track is current afterwards (a failed start leaves none). */
suspend fun MusicPlayback.playTracks(
    tracks: List<MediaItem>,
    startTrack: MediaItem? = null,
    playContext: MusicPlayContext,
    shuffle: Boolean = false,
    offline: Boolean = false,
): Boolean {
    playFromList(tracks, startTrack, playContext, shuffle, offline = offline)
    return state.value.currentTrack != null
}

/**
 * Fetches a track list with [fetch], then plays it, under one play intent claimed before the fetch: a slow fetch
 * never replaces a queue the user started later (it returns false silently).
 *
 * [onError] reports a failed fetch while the intent is still current; null rethrows it. [onEmpty] handles an empty
 * result; null hands the empty list on (which plays nothing).
 */
suspend fun MusicPlayback.playFetchedTracks(
    fetch: suspend () -> List<MediaItem>,
    playContext: MusicPlayContext,
    onError: ((Throwable) -> Unit)? = null,
    onEmpty: (() -> Unit)? = null,
    startTrack: MediaItem? = null,
    shuffle: Boolean = false,
): Boolean {
    val intent = beginPlayIntent()
    val tracks = try {
        fetch()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        if (!isPlayIntentCurrent(intent)) return false
        if (onError == null) throw e
        onError(e)
        return false
    }
    if (!isPlayIntentCurrent(intent)) return false
    if (tracks.isEmpty() && onEmpty != null) {
        onEmpty()
        return false
    }
    return playTracks(tracks, startTrack, playContext, shuffle)
}

/** Plays the audio [playlist] (every page of it, or [preloadedItems] when the caller holds them all). */
suspend fun MusicPlayback.playAudioPlaylist(
    backend: MediaBackend,
    playlist: MediaPlaylist,
    shuffle: Boolean = false,
    startTrack: MediaItem? = null,
    preloadedItems: List<MediaItem>? = null,
    onError: ((Throwable) -> Unit)? = null,
    onEmpty: (() -> Unit)? = null,
): Boolean = playFetchedTracks(
    fetch = { preloadedItems ?: drainPages(PLAYLIST_PAGE_SIZE) { start, size -> backend.fetchPlaylistPage(playlist.id, start, size) } },
    playContext = MusicPlayContext(playlist.title, MusicPlayContextKind.PLAYLIST),
    onError = onError,
    onEmpty = onEmpty,
    startTrack = startTrack,
    shuffle = shuffle,
)

/**
 * Plays [track] inside its album's queue, starting at it; plays it alone when it has no album or [backend], the album
 * doesn't hold it, or the album fetch fails. The fallback runs under the album fetch's intent, so it never supersedes
 * a newer request.
 */
suspend fun MusicPlayback.playTrackWithAlbumContext(track: MediaItem, backend: MediaBackend?): Boolean {
    val intent = beginPlayIntent()
    val albumId = track.parentId
    if (albumId != null && backend != null) {
        try {
            val tracks = backend.fetchAlbumTracks(albumId)
            val start = tracks.firstOrNull { it.id == track.id }
            if (!isPlayIntentCurrent(intent)) return false
            if (start != null) {
                return playTracks(tracks, start, MusicPlayContext(track.albumTitle ?: "", MusicPlayContextKind.ALBUM))
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (!isPlayIntentCurrent(intent)) return false
            Log.w(TAG, e) { "Album context fetch failed for track ${track.id}; playing the track alone" }
        }
    }
    if (!isPlayIntentCurrent(intent)) return false
    return playTracks(listOf(track), playContext = MusicPlayContext(track.title ?: "", MusicPlayContextKind.TRACKS))
}

/** What the tap site shows after [playInstantMixFeedback]: a mix is never a silent no-op unless superseded. */
sealed interface InstantMixFeedback {
    /** The mix plays (a TV opens Now Playing). */
    data object Started : InstantMixFeedback

    /** A newer play request took over: show nothing. */
    data object Silent : InstantMixFeedback

    /** The error snackbar's text. */
    data class Failed(val message: String) : InstantMixFeedback
}

/**
 * Starts an Instant Mix seeded from [seed] and says what the user sees: a failed fetch shows its
 * [PlaybackException.message] or the generic failure, an empty mix says so.
 */
suspend fun MusicPlayback.playInstantMixFeedback(seed: MediaItem): InstantMixFeedback {
    val outcome = try {
        playInstantMix(seed)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        return InstantMixFeedback.Failed(if (e is PlaybackException) e.message ?: T.music.instantMixFailed else T.music.instantMixFailed)
    }
    return when (outcome) {
        InstantMixOutcome.STARTED -> InstantMixFeedback.Started
        InstantMixOutcome.EMPTY -> InstantMixFeedback.Failed(T.music.instantMixEmpty)
        InstantMixOutcome.SUPERSEDED -> InstantMixFeedback.Silent
    }
}
