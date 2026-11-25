package com.edde746.plezy.model

/**
 * What a server's backend can do, for UI affordances. Static per backend kind except [videoTranscoding], which Plex
 * probes per server.
 */
data class ServerCapabilities(
    /** Live TV may exist; whether it does is the server's `liveTv.isAvailable()`. */
    val liveTv: Boolean = false,
    val liveTvDvr: Boolean = false,
    val videoTranscoding: Boolean = true,
    /** The server transcodes a download to a smaller quality ([com.edde746.plezy.backend.DownloadTranscoding]). */
    val downloadTranscoding: Boolean = false,
    /** Curated global home hubs; without them home is built from per-library hubs. */
    val richHubs: Boolean = false,
    /** 0–10 ratings; without them the rating sheet sets a favorite instead. */
    val numericUserRating: Boolean = false,
    val userFavorites: Boolean = false,
    val continueWatchingRemoval: Boolean = false,
    val externalSubtitleSearch: Boolean = false,
    val richMetadataEdit: Boolean = false,
    val scrubThumbnails: Boolean = false,
    val folderGrouping: Boolean = false,
    val instantMix: Boolean = false,
    val libraryChangeEvents: Boolean = false,
) {
    companion object {
        val PLEX = ServerCapabilities(
            liveTv = true,
            liveTvDvr = true,
            richHubs = true,
            numericUserRating = true,
            continueWatchingRemoval = true,
            externalSubtitleSearch = true,
            richMetadataEdit = true,
            scrubThumbnails = true,
            folderGrouping = true,
            instantMix = true,
            libraryChangeEvents = true,
        )

        val JELLYFIN = ServerCapabilities(
            liveTv = true,
            liveTvDvr = true,
            userFavorites = true,
            richMetadataEdit = true,
            scrubThumbnails = true,
            folderGrouping = true,
            instantMix = true,
            libraryChangeEvents = true,
            downloadTranscoding = true,
        )

        val EMBY = JELLYFIN.copy(continueWatchingRemoval = true, downloadTranscoding = false)

        fun forBackend(kind: BackendKind): ServerCapabilities = when (kind) {
            BackendKind.PLEX -> PLEX
            BackendKind.JELLYFIN -> JELLYFIN
            BackendKind.EMBY -> EMBY
        }
    }
}
