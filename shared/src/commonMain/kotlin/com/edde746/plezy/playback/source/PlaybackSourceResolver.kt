package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.PlaybackSubtitleSidecar
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.downloads.DownloadedVideo
import com.edde746.plezy.downloads.DownloadedVideoSource
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.MultiServerManager
import com.edde746.plezy.strings.T
import io.ktor.http.Url
import io.ktor.http.encodeURLPath
import kotlinx.coroutines.CancellationException
import kotlin.math.roundToInt

/** The servers a playback may use, as [MultiServerManager] knows them. */
interface PlaybackServers {
    /** The registered client of [serverId], online or not. */
    fun client(serverId: ServerId): MediaBackend?

    /** Not hidden by the active profile's server selection. */
    fun isServerVisible(serverId: ServerId): Boolean

    /** Servers that refused this account (401 or 403). */
    val refusedServerIds: Set<ServerId>

    fun isClientOnline(serverId: ServerId): Boolean
}

/** [MultiServerManager] as [PlaybackServers]. */
fun MultiServerManager.playbackServers(): PlaybackServers = object : PlaybackServers {
    override fun client(serverId: ServerId): MediaBackend? = this@playbackServers.client(serverId)

    override fun isServerVisible(serverId: ServerId): Boolean = this@playbackServers.isServerVisible(serverId)

    override val refusedServerIds: Set<ServerId> get() = this@playbackServers.refusedServerIds

    override fun isClientOnline(serverId: ServerId): Boolean = this@playbackServers.isClientOnline(serverId)
}

/**
 * Turns a play request into the source the player opens, for video and music alike. Start it before building the
 * player: it does only network and database work, and its failure surfaces when awaited.
 */
class PlaybackSourceResolver(
    private val servers: PlaybackServers,
    private val downloads: DownloadedVideoSource,
    private val cachedMetadata: CachedPlaybackMetadata,
) {
    /**
     * Resolves [options] on the client [playbackClient] finds for its item's server. A downloaded copy plays first in
     * the offline library ([offlineLibraryMode]), at Original quality, or when [downloadOutranksQuality] (the preset is
     * the saved default, not a pick); otherwise the server negotiates the stream. The offline library never falls back
     * to a server.
     *
     * Throws [PlaybackException]: `NO_PLAYABLE_SOURCE` when the offline library has no usable download or nothing can
     * play without a client; the client's classified failure otherwise.
     */
    suspend fun resolve(
        options: PlaybackInitializationOptions,
        offlineLibraryMode: Boolean,
        downloadOutranksQuality: Boolean = false,
    ): PlaybackContext =
        resolve(options, playbackClient(options.metadata.serverId?.let(::ServerId), offlineLibraryMode), offlineLibraryMode, downloadOutranksQuality)

    /**
     * [resolve] on [client], which the caller found with [playbackClient]: this reads no server state, so it may run
     * away from the thread the servers change on. Without a client any downloaded version plays.
     */
    suspend fun resolve(
        options: PlaybackInitializationOptions,
        client: MediaBackend?,
        offlineLibraryMode: Boolean,
        downloadOutranksQuality: Boolean,
    ): PlaybackContext {
        val item = options.metadata
        val result = initialize(
            options,
            client,
            preferOffline = offlineLibraryMode || options.qualityPreset.isOriginal || downloadOutranksQuality,
            requireOffline = offlineLibraryMode,
        )
        val sourceKind = when {
            result.isOffline -> PlaybackSourceKind.LOCAL_FILE
            result.isTranscoding -> PlaybackSourceKind.REMOTE_TRANSCODE
            else -> PlaybackSourceKind.REMOTE_DIRECT
        }
        return PlaybackContext(
            item = item,
            result = result,
            sourceKind = sourceKind,
            reportingMode = reportingMode(sourceKind, client, offlineLibraryMode),
            reportingClient = client,
            streamHeaders = streamHeaders(
                client,
                sourceKind,
                options.sessionIdentifier,
                trackStreamUrl = if (item.kind == MediaKind.TRACK) result.videoUrl else null,
            ),
        )
    }

    /**
     * The client a play of [serverId] resolves on: the server's registered one, even while its status reads offline;
     * none for a hidden or refused server, nor in the offline library ([offlineLibraryMode]) for a server that is
     * offline. It reads the servers' state, so it runs on the thread that state changes on (the main thread).
     */
    fun playbackClient(serverId: ServerId?, offlineLibraryMode: Boolean): MediaBackend? {
        if (serverId == null || !servers.isServerVisible(serverId) || serverId in servers.refusedServerIds) return null
        if (offlineLibraryMode && !servers.isClientOnline(serverId)) return null
        return servers.client(serverId)
    }

    private suspend fun initialize(
        options: PlaybackInitializationOptions,
        client: MediaBackend?,
        preferOffline: Boolean,
        requireOffline: Boolean,
    ): PlaybackInitializationResult {
        val item = options.metadata
        val serverId = item.serverId?.let(::ServerId) ?: client?.serverId
        // With nothing to stream from, any downloaded version beats failing; with a server, an explicitly requested
        // version that isn't downloaded streams.
        val offlineOnly = client == null || requireOffline
        if (serverId != null && (preferOffline || client == null)) {
            val video = downloaded(serverId, item.id, options.selectedMediaIndex, options.selectedMediaSourceId, allowAnyVersion = offlineOnly)
            if (video != null) {
                val offline = offlineResult(item, video, client, options, offlineOnly)
                if (offline != null) return offline
            }
        }
        if (requireOffline) throw downloadUnavailable()
        if (client == null) throw PlaybackException(T.messages.noVideoUrl, PlaybackFailureReason.NO_PLAYABLE_SOURCE)
        return client.getPlaybackInitialization(options)
    }

    /**
     * The downloaded copy as a result, with track labels from the cached media info (never the network). A stacked
     * item plays the file holding the start position; when that file isn't on disk (a copy from before stacked items
     * were downloaded whole) it streams instead, or fails when it must stay offline.
     */
    private suspend fun offlineResult(
        item: MediaItem,
        first: DownloadedVideo,
        client: MediaBackend?,
        options: PlaybackInitializationOptions,
        offlineOnly: Boolean,
    ): PlaybackInitializationResult? {
        val mediaInfo = cachedMetadata.mediaSourceInfo(item.backend, cacheServerId(first, client), item.id, first.mediaIndex, options.startPosition)
        val partIndex = mediaInfo?.partTimeline?.currentIndex ?: 0
        val video = if (partIndex > 0) {
            downloaded(first.serverId, item.id, first.mediaIndex, first.mediaSourceId, allowAnyVersion = true, partIndex = partIndex)
        } else {
            first
        }
        if (video == null) {
            Log.w(TAG) { "Downloaded copy of ${item.id} has no file for part ${partIndex + 1}" }
            if (offlineOnly) throw downloadUnavailable()
            return null
        }
        Log.d(TAG) { "Using offline playback for ${item.id}" }
        val sidecars = downloadedSubtitleSidecars(downloads.sidecarSubtitles(video, item), mediaInfo)
        val transcoded = !video.transcodeQuality.isOriginal
        return PlaybackInitializationResult(
            availableVersions = emptyList(),
            videoUrl = fileUrl(video.path),
            mediaInfo = if (transcoded) mediaInfo?.let { transcodedDownloadInfo(it, sidecars) } else mediaInfo,
            subtitleSidecars = sidecars,
            isOffline = true,
            playMethod = "DirectPlay",
            selectedMediaIndex = video.mediaIndex,
            selectedMediaSourceId = video.mediaSourceId,
            downloadedQuality = video.transcodeQuality,
        )
    }

    /**
     * The cached media info of a copy the server transcoded, narrowed to what the file holds: the one audio track it
     * carries (the server's default), and the subtitles saved beside it as files ([sidecars]); image subtitles and the
     * other audio tracks stayed on the server.
     */
    private fun transcodedDownloadInfo(info: MediaSourceInfo, sidecars: List<PlaybackSubtitleSidecar>): MediaSourceInfo {
        val audio = info.audioTracks.firstOrNull { it.id == info.defaultAudioStreamIndex } ?: info.audioTracks.firstOrNull { it.selected } ?: info.audioTracks.firstOrNull()
        val saved = sidecars.mapNotNullTo(HashSet()) { it.sourceStreamId }
        return info.copy(
            audioTracks = listOfNotNull(audio?.withSelected(true)),
            subtitleTracks = info.subtitleTracks.filter { it.id in saved }.map { if (it.isExternalFile) it else it.copy(usesExternalDelivery = true) },
        )
    }

    /**
     * The sidecar subtitles saved with the downloaded [video] of [item], labelled from the cached media info: what an
     * external player gets beside the local file. [client] is the server's live client, if any, whose cache scope
     * holds the media info.
     */
    suspend fun downloadedSubtitles(item: MediaItem, video: DownloadedVideo, client: MediaBackend?): List<PlaybackSubtitleSidecar> {
        val mediaInfo = cachedMetadata.mediaSourceInfo(item.backend, cacheServerId(video, client), item.id, video.mediaIndex)
        return downloadedSubtitleSidecars(downloads.sidecarSubtitles(video, item), mediaInfo)
    }

    /** The cached media info lives under the live client's scope, else the download's, else the server's. */
    private fun cacheServerId(video: DownloadedVideo, client: MediaBackend?): String =
        client?.cacheServerId ?: video.clientScopeId ?: video.serverId.value

    /**
     * The chapters and markers cached for [item] where no server answers (offline): under its download's scope, else
     * its server's. Null when none are cached.
     */
    suspend fun cachedPlaybackExtras(item: MediaItem, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean): PlaybackExtras? {
        val serverId = ServerId.tryParse(item.serverId) ?: return null
        val scope = downloaded(serverId, item.id, mediaIndex = null, mediaSourceId = null, allowAnyVersion = true)?.let { cacheServerId(it, null) } ?: serverId.value
        return cachedMetadata.playbackExtras(item.backend, scope, item.id, introPattern, creditsPattern, forceChapterFallback)
    }

    /** [item]'s image [path] as its download saved it (a `file://` URL); null when it saved none. */
    suspend fun downloadedArtwork(item: MediaItem, path: String?): String? {
        val serverId = ServerId.tryParse(item.serverId) ?: return null
        return path?.takeIf { it.isNotBlank() }?.let { downloads.artworkUrl(serverId, it) }
    }

    /** The downloaded file, or null when there is none or the lookup fails (the server streams instead). */
    private suspend fun downloaded(
        serverId: ServerId,
        itemId: String,
        mediaIndex: Int?,
        mediaSourceId: String?,
        allowAnyVersion: Boolean,
        partIndex: Int = 0,
    ): DownloadedVideo? = try {
        downloads.resolve(serverId, itemId, mediaIndex, mediaSourceId, allowAnyVersion, partIndex)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Error checking the downloaded copy of $itemId" }
        null
    }

    private fun reportingMode(sourceKind: PlaybackSourceKind, client: MediaBackend?, offlineLibraryMode: Boolean): PlaybackReportingMode = when {
        client != null && sourceKind == PlaybackSourceKind.LOCAL_FILE -> PlaybackReportingMode.ONLINE_WITH_OFFLINE_FALLBACK
        client != null -> PlaybackReportingMode.ONLINE
        sourceKind == PlaybackSourceKind.LOCAL_FILE || offlineLibraryMode -> PlaybackReportingMode.OFFLINE_QUEUE
        else -> PlaybackReportingMode.DISABLED
    }

    /**
     * The client's stream headers for a remote source. Plex also names the playback session, except for a track whose
     * stream URL already names it: gapless playback opens the next track with the playing one's headers, and a header
     * naming another session makes the server refuse that track's transcode.
     */
    private fun streamHeaders(
        client: MediaBackend?,
        sourceKind: PlaybackSourceKind,
        sessionIdentifier: String?,
        trackStreamUrl: String?,
    ): Map<String, String>? {
        if (client == null || sourceKind == PlaybackSourceKind.LOCAL_FILE) return null
        val headers = client.streamHeaders.toMutableMap()
        if (client.backend == BackendKind.PLEX && sessionIdentifier != null && urlSessionIdentifier(trackStreamUrl) != sessionIdentifier) {
            headers[PLEX_SESSION_HEADER] = sessionIdentifier
        }
        return headers
    }

    private fun urlSessionIdentifier(url: String?): String? =
        url?.let { runCatching { Url(it) }.getOrNull() }?.parameters?.get(PLEX_SESSION_HEADER)

    private fun downloadUnavailable() =
        PlaybackException("The downloaded media file is unavailable.", PlaybackFailureReason.NO_PLAYABLE_SOURCE)

    private companion object {
        const val TAG = "PlaybackSourceResolver"
        const val PLEX_SESSION_HEADER = "X-Plex-Session-Identifier"
    }
}

/** [path] as the URL the player opens: a plain path gets `file://`, a URI (`content://`, `file://`) stays as it is. */
internal fun fileUrl(path: String): String = if ("://" in path) path else "file://$path"

/** The `file:` URI of the absolute [path], percent-encoded; a Windows path gets forward slashes (`file:///C:/…`). */
internal fun fileUri(path: String): String {
    val slashed = path.replace('\\', '/')
    return "file://" + (if (slashed.startsWith('/')) slashed else "/$slashed").encodeURLPath()
}

/**
 * The sidecar subtitle files of a download ([paths], absolute) as preloaded sidecars: local files cost nothing to
 * attach and stay selectable as a secondary subtitle. A file named `<number>.<ext>` is the source stream with that id
 * and takes its title, language, codec and default and forced flags from [mediaInfo]'s cached track; any other is
 * titled after its file name.
 */
internal fun downloadedSubtitleSidecars(paths: List<String>, mediaInfo: MediaSourceInfo?): List<PlaybackSubtitleSidecar> = paths.map { path ->
    val name = path.substringAfterLast('/').substringAfterLast('\\').let { file -> file.substringBeforeLast('.').ifEmpty { file } }
    val streamId = name.toIntOrNull()
    val cached = streamId?.let { id -> mediaInfo?.subtitleTracks?.firstOrNull { it.id == id } }
    PlaybackSubtitleSidecar(
        sourceStreamId = streamId,
        preload = true,
        track = SubtitleSidecar(
            url = fileUri(path),
            title = cached?.displayTitle ?: cached?.language ?: T.videoControls.subtitleFile(name),
            language = cached?.languageCode,
            codec = cached?.codec,
            forced = cached?.forced ?: false,
            isDefault = cached?.selected ?: false,
        ),
    )
}

/**
 * The file info of a downloaded copy the server transcoded to [quality]: one MPEG-TS file of H.264 and AAC at the
 * quality's bitrate cap, its picture the source version's (version [mediaIndex] of [source], the server's file info)
 * fitted inside the quality's frame, over [durationMs].
 */
internal fun transcodedCopyFileInfo(source: MediaFileInfo?, mediaIndex: Int, quality: TranscodeQualityPreset, durationMs: Long?): MediaFileInfo {
    val original = source?.versions?.getOrNull(mediaIndex)
    val frameWidth = quality.videoResolution?.substringBefore('x')?.toIntOrNull()
    val frameHeight = quality.resolutionHeight
    val width = original?.width
    val height = original?.height
    // The encoder keeps the picture's shape and even dimensions, and never scales up.
    val fitted = if (width != null && height != null && width > 0 && height > 0 && frameWidth != null && frameHeight != null) {
        val scale = minOf(1.0, frameWidth.toDouble() / width, frameHeight.toDouble() / height)
        (width * scale).roundToInt() / 2 * 2 to (height * scale).roundToInt() / 2 * 2
    } else {
        null
    }
    return MediaFileInfo(
        listOf(
            MediaFileVersion(
                id = original?.id,
                container = "mpegts",
                bitrateKbps = quality.videoBitrateKbps,
                durationMs = durationMs?.toInt() ?: original?.durationMs,
                width = fitted?.first,
                height = fitted?.second,
                aspectRatio = original?.aspectRatio,
                videoResolutionLabel = frameHeight?.toString(),
                videoCodec = "h264",
                audioCodec = "aac",
            ),
        ),
    )
}
