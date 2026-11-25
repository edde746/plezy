package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.InMemoryApiCacheStore
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.downloads.DownloadedVideo
import com.edde746.plezy.downloads.DownloadedVideoSource
import com.edde746.plezy.jellyfin.JellyfinCacheResolver
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId

/** A client whose playback initialization is [initialize]; [initializations] counts the calls. */
class PlaybackClient(
    serverId: String,
    backend: BackendKind = BackendKind.PLEX,
    scopeId: String? = null,
    var initialize: (PlaybackInitializationOptions) -> PlaybackInitializationResult = {
        PlaybackInitializationResult(availableVersions = emptyList(), videoUrl = "https://example.com/video.mp4")
    },
) : FakeMediaBackend(serverId, backend, scopeId = scopeId) {
    var initializations = 0
        private set

    override suspend fun getPlaybackInitialization(options: PlaybackInitializationOptions): PlaybackInitializationResult {
        initializations++
        return initialize(options)
    }
}

/** A client that must not be asked: the downloaded copy plays without it. */
fun failingClient(serverId: String) = PlaybackClient(serverId) {
    throw IllegalStateException("live playback initialization should not be called for downloaded playback")
}

/** A client streaming `https://server/stream/<index>` for the requested version. */
fun streamingClient(serverId: String) = PlaybackClient(serverId) { options ->
    PlaybackInitializationResult(
        availableVersions = emptyList(),
        videoUrl = "https://server/stream/${options.selectedMediaIndex}",
        selectedMediaIndex = options.selectedMediaIndex,
    )
}

class FakePlaybackServers(vararg clients: FakeMediaBackend) : PlaybackServers {
    private val clients = clients.associateBy { it.serverId }
    val online = clients.map { it.serverId }.toMutableSet()
    val hidden = mutableSetOf<ServerId>()
    override var refusedServerIds: Set<ServerId> = emptySet()

    override fun client(serverId: ServerId) = clients[serverId]

    override fun isServerVisible(serverId: ServerId) = serverId !in hidden

    override fun isClientOnline(serverId: ServerId) = serverId in online
}

/**
 * Completed downloads, matched as the download library matches them: by source id when both sides have one, else by
 * index; a mismatch only with `allowAnyVersion`. [Copy.paths] are the stored files, one per part.
 */
class FakeDownloads : DownloadedVideoSource {
    data class Copy(
        val serverId: String,
        val itemId: String,
        val paths: List<String>,
        val mediaIndex: Int = 0,
        val mediaSourceId: String? = null,
        val clientScopeId: String? = null,
        val subtitles: List<String> = emptyList(),
    )

    val copies = mutableListOf<Copy>()

    /** Thrown by every lookup when set. */
    var failure: Exception? = null

    fun add(copy: Copy) {
        copies += copy
    }

    override suspend fun resolve(
        serverId: ServerId,
        itemId: String,
        mediaIndex: Int?,
        mediaSourceId: String?,
        allowAnyVersion: Boolean,
        partIndex: Int,
    ): DownloadedVideo? {
        failure?.let { throw it }
        val copy = copies.firstOrNull { it.serverId == serverId.value && it.itemId == itemId } ?: return null
        val requestedId = mediaSourceId?.trim()?.ifEmpty { null }
        val matches = if (requestedId != null && copy.mediaSourceId != null) {
            requestedId == copy.mediaSourceId
        } else {
            mediaIndex == null || mediaIndex == copy.mediaIndex
        }
        if (!matches && !allowAnyVersion) return null
        val path = copy.paths.getOrNull(partIndex) ?: return null
        return DownloadedVideo(serverId, itemId, path, copy.mediaIndex, copy.mediaSourceId, partIndex, copy.paths.size, copy.clientScopeId)
    }

    override suspend fun sidecarSubtitles(video: DownloadedVideo, metadata: MediaItem?): List<String> =
        copies.first { it.serverId == video.serverId.value && it.itemId == video.itemId }.subtitles

    /** Saved artwork by `serverId:path`. */
    val artwork = mutableMapOf<String, String>()

    override suspend fun artworkUrl(serverId: ServerId, path: String): String? = artwork["$serverId:$path"]
}

fun cachedMetadata(store: InMemoryApiCacheStore) =
    CachedPlaybackMetadata(store, JellyfinCacheResolver(store, connections = { emptyList() }, bindings = { emptyList() }))

fun testItem(id: String, serverId: String, backend: BackendKind = BackendKind.PLEX, kind: MediaKind = MediaKind.MOVIE) =
    MediaItem(id = id, backend = backend, kind = kind, serverId = serverId)
