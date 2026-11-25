package com.edde746.plezy.model

import com.edde746.plezy.log.Log

/** Which server software a server, item or row belongs to. [id] is the persisted and wire token. */
enum class BackendKind(val id: String) {
    PLEX("plex"),
    JELLYFIN("jellyfin"),
    EMBY("emby"),
    ;

    /** Jellyfin and Emby speak the MediaBrowser API; "not Plex" logic tests this, never `!= PLEX` alone. */
    val usesMediaBrowserApi: Boolean get() = dialect != null

    val dialect: MediaBrowserDialect?
        get() = when (this) {
            PLEX -> null
            JELLYFIN -> MediaBrowserDialect.JELLYFIN
            EMBY -> MediaBrowserDialect.EMBY
        }

    companion object {
        /** The kind of exactly [id]; throws on anything else. */
        fun fromId(id: String): BackendKind =
            entries.firstOrNull { it.id == id } ?: throw IllegalArgumentException("Unknown backend id: $id")

        /**
         * The kind of a decoded cache or JSON row: null is Plex (rows from before Jellyfin existed), an unknown id is
         * logged and read as Plex.
         */
        fun fromString(id: String?): BackendKind {
            if (id == null) return PLEX
            return entries.firstOrNull { it.id == id } ?: PLEX.also { Log.w(TAG) { "Unknown backend id \"$id\"; defaulting to plex" } }
        }

        private const val TAG = "BackendKind"
    }
}

/** The two MediaBrowser servers and what differs between them on the wire. */
enum class MediaBrowserDialect(val id: String, val productName: String) {
    JELLYFIN("jellyfin", "Jellyfin"),
    EMBY("emby", "Emby"),
    ;

    val backend: BackendKind get() = if (this == JELLYFIN) BackendKind.JELLYFIN else BackendKind.EMBY

    val exampleBaseUrl: String get() = if (this == JELLYFIN) "https://jellyfin.example.com" else "https://emby.example.com"

    /** The UDP broadcast payload LAN discovery sends to port [LAN_DISCOVERY_PORT]. */
    val lanDiscoveryMessage: String get() = if (this == JELLYFIN) "who is JellyfinServer?" else "who is EmbyServer?"

    /** Ports tried for a bare host the user typed. */
    val httpsPortGuesses: List<Int> get() = if (this == JELLYFIN) listOf(8096) else listOf(8920, 8096)

    /** The token's query parameter: Jellyfin 12 rejects the legacy `api_key`. */
    val tokenQueryParam: String get() = if (this == JELLYFIN) "ApiKey" else "api_key"

    val webSocketPath: String get() = if (this == JELLYFIN) "/socket" else "/embywebsocket"

    private val isJellyfin get() = this == JELLYFIN
    private val isEmby get() = this == EMBY

    /** Emby sends LibraryChanged only after `POST /Sessions/Capabilities/Full`. */
    val requiresSessionCapabilitiesForLibraryEvents: Boolean get() = isEmby
    val supportsQuickConnect: Boolean get() = isJellyfin
    val supportsTrickplay: Boolean get() = isJellyfin
    val supportsMediaSegments: Boolean get() = isJellyfin

    /** Never lead the codec list with AV1 on Emby. */
    val rotatesDisabledTranscodeCodecs: Boolean get() = isJellyfin
    val requiresMpegTsForLiveTv: Boolean get() = isEmby

    /** `/Audio/{id}/Lyrics`: never called on Emby, where it spawns an ffmpeg that fails with a 500. */
    val supportsLyrics: Boolean get() = isJellyfin
    val supportsAggregateItemFilters: Boolean get() = isJellyfin
    val supportsContinueWatchingRemoval: Boolean get() = isEmby
    val metadataWritesUseNamePairLists: Boolean get() = isEmby
    val supportsGlobalNextUp: Boolean get() = isJellyfin
    val supportsNextUpRewatching: Boolean get() = isJellyfin
    val resumeReturnsOnlyStartedItems: Boolean get() = isJellyfin
    val requiresPlaySessionId: Boolean get() = isEmby
    val persistsTrackSelectionsViaAccountFlags: Boolean get() = isJellyfin
    val playlistsFilterByMediaType: Boolean get() = isJellyfin
    val searchesPeopleThroughItems: Boolean get() = isEmby
    val searchesMovieLibrariesByMediaType: Boolean get() = isEmby
    val requiresUserScopedItemRoutes: Boolean get() = isEmby

    companion object {
        const val LAN_DISCOVERY_PORT: Int = 7359

        fun fromId(id: String): MediaBrowserDialect =
            entries.firstOrNull { it.id == id } ?: throw IllegalArgumentException("Unknown MediaBrowserDialect id: $id")

        /** Anything but `emby`, missing included, is Jellyfin: rows from before Emby support carry no dialect. */
        fun fromIdOrJellyfin(id: Any?): MediaBrowserDialect = if (id == "emby") EMBY else JELLYFIN

        /**
         * The dialect `/System/Info/Public` reveals: a ProductName naming either wins; else an Emby-only
         * `RemoteAddresses` key; else null (keep the user's choice).
         */
        fun detectFromPublicSystemInfo(productName: Any?, hasRemoteAddresses: Boolean): MediaBrowserDialect? {
            if (productName is String && productName.isNotEmpty()) {
                val normalized = productName.lowercase()
                if ("jellyfin" in normalized) return JELLYFIN
                if ("emby" in normalized) return EMBY
            }
            return if (hasRemoteAddresses) EMBY else null
        }
    }
}
