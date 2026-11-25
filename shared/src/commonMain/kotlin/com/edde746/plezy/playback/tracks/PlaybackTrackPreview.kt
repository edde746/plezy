package com.edde746.plezy.playback.tracks

import com.edde746.plezy.model.MediaAudioTrack
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaServerUserProfile
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaSubtitleTrack

/**
 * What the player will do with an item's tracks, decided before playback by the player's own ladder ([TrackSelector])
 * over the same [source] playback opens. Only a pick carried from a previous episode and a Plex transcode decision are
 * unknowable here. [audio] null: the file has no audio rows; [subtitle] null: subtitles start off.
 */
data class PlaybackTrackPreview(val source: MediaSourceInfo, val audio: MediaAudioTrack?, val subtitle: MediaSubtitleTrack?)

/** Whether [source] has any audio or subtitle row: a cached source of a file the server never probed has none. */
fun mediaSourceHasTrackRows(source: MediaSourceInfo): Boolean = source.audioTracks.isNotEmpty() || source.subtitleTracks.isNotEmpty()

/**
 * The tracks the player's ladder picks for [item] from [source]'s rows ([PlaybackSubtitleResolver.audioTracksForSource]
 * and [PlaybackSubtitleResolver.subtitleTrackForSource]), never waiting for tracks to arrive. Null when [source] has no
 * rows: nothing is better than a guess.
 */
fun previewPlaybackTracks(item: MediaItem, source: MediaSourceInfo, profile: MediaServerUserProfile? = null): PlaybackTrackPreview? {
    if (!mediaSourceHasTrackRows(source)) return null
    val selector = TrackSelector(item.backend, source, profile)
    val audio = selector.selectAudioTrack(PlaybackSubtitleResolver.audioTracksForSource(source), null)?.track
    val subtitle = selector.selectSubtitleTrack(
        source.subtitleTracks.map { PlaybackSubtitleResolver.subtitleTrackForSource(it) },
        preference = null,
        audio = audio,
        waitForPendingSource = false,
    )?.track
    return PlaybackTrackPreview(
        source = source,
        audio = audio?.let { track -> sourceStreamIdOf(track.id)?.let { id -> source.audioTracks.firstOrNull { it.id == id } } },
        subtitle = subtitle?.let { track -> sourceStreamIdOf(track.id)?.let { id -> source.subtitleTracks.firstOrNull { it.id == id } } },
    )
}
