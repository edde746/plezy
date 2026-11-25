package com.edde746.plezy.downloads

import com.edde746.plezy.backend.DownloadTranscoding
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.defaultPlaybackSeason
import com.edde746.plezy.model.fetchFirstEpisodeForSeason
import com.edde746.plezy.model.resolveMediaVersions
import kotlinx.coroutines.CancellationException

/**
 * Which version a download takes: [mediaIndex], and for a show or season the [acceptedSignatures] of the version picked
 * on a representative episode. An episode without a matching version asks [onVersionMismatch] for its index (null:
 * skip the episode). [quality]: the original file, or a server transcode, for every download the request queues.
 */
data class DownloadVersionConfig(
    val mediaIndex: Int = 0,
    val acceptedSignatures: Set<String> = emptySet(),
    val onVersionMismatch: (suspend (episode: MediaItem, versions: List<MediaVersion>) -> Int?)? = null,
    val quality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
) {
    companion object {
        fun fromSignature(
            signature: String,
            mediaIndex: Int = 0,
            onVersionMismatch: (suspend (MediaItem, List<MediaVersion>) -> Int?)? = null,
        ) = DownloadVersionConfig(mediaIndex, setOf(signature), onVersionMismatch)
    }
}

/**
 * The versions before downloading [item]: a movie's or episode's own, a show's or season's representative episode's
 * ([fetchRepresentativeVersions]); null when none are known. More than one is a choice to offer.
 */
suspend fun downloadVersions(item: MediaItem, backend: MediaBackend, fallbackVersions: List<MediaVersion>? = null): List<MediaVersion>? =
    when (item.kind) {
        MediaKind.MOVIE, MediaKind.EPISODE -> resolveMediaVersions(item, backend, fallbackVersions)
        MediaKind.SHOW, MediaKind.SEASON -> fetchRepresentativeVersions(backend, item)
        else -> null
    }?.takeIf { it.isNotEmpty() }

/**
 * Whether [item] (a movie, episode, show or season) can download transcoded to a smaller quality: [backend]'s server
 * transcodes downloads (Jellyfin). Elsewhere a download is always the original file.
 */
fun canTranscodeDownload(item: MediaItem, backend: MediaBackend): Boolean =
    backend.capabilities.downloadTranscoding && backend is DownloadTranscoding &&
        item.kind in setOf(MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.SHOW, MediaKind.SEASON)

/**
 * The config for version [selectedIndex] of [choices] for [item]: a show or season keeps the version's signature so
 * each episode takes its matching version, asking [onVersionMismatch] when none matches.
 */
fun downloadVersionConfigFor(
    item: MediaItem,
    choices: List<MediaVersion>,
    selectedIndex: Int,
    onVersionMismatch: (suspend (MediaItem, List<MediaVersion>) -> Int?)? = null,
): DownloadVersionConfig = when (item.kind) {
    MediaKind.SHOW, MediaKind.SEASON -> DownloadVersionConfig.fromSignature(choices[selectedIndex].signature, selectedIndex, onVersionMismatch)
    else -> DownloadVersionConfig(mediaIndex = selectedIndex)
}

/**
 * The versions of a show's or season's representative episode: a season's first episode, or a show's default season's
 * first episode, fetched in full. Null when there is none or a lookup fails (logged).
 */
suspend fun fetchRepresentativeVersions(backend: MediaBackend, item: MediaItem): List<MediaVersion>? = try {
    val episodeId = when (item.kind) {
        MediaKind.SEASON -> fetchFirstEpisodeForSeason(backend, item.id, seriesId = item.grandparentId ?: item.parentId)?.id
        MediaKind.SHOW -> defaultPlaybackSeason(backend.fetchChildren(item.id))?.let { season ->
            fetchFirstEpisodeForSeason(backend, season.id, seriesId = item.id)?.id
        }
        else -> null
    }
    episodeId?.let { backend.fetchItem(it)?.mediaVersions }
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.w("Downloads", e) { "Failed to fetch representative versions" }
    null
}
