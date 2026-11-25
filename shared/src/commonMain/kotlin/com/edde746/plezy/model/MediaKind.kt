package com.edde746.plezy.model

import com.edde746.plezy.strings.T

/** What a media item is, across backends. [id] is the persisted and wire token; [label] is for display only. */
enum class MediaKind(val id: String) {
    MOVIE("movie"),
    SHOW("show"),
    SEASON("season"),
    EPISODE("episode"),
    ARTIST("artist"),
    ALBUM("album"),
    TRACK("track"),
    COLLECTION("collection"),
    PLAYLIST("playlist"),
    CLIP("clip"),
    PHOTO("photo"),
    FOLDER("folder"),
    UNKNOWN("unknown"),
    ;

    val isVideo: Boolean get() = this == MOVIE || this == EPISODE || this == CLIP

    val isMusic: Boolean get() = this == ARTIST || this == ALBUM || this == TRACK

    val isPlayable: Boolean get() = isVideo || this == TRACK

    val hasFileInfo: Boolean get() = this == MOVIE || this == EPISODE || this == TRACK || this == CLIP

    /** Containers count watch state over their leaves; leaves by their own view count. */
    val usesLeafWatchCounts: Boolean
        get() = when (this) {
            SHOW, SEASON, ARTIST, ALBUM, COLLECTION, PLAYLIST, FOLDER -> true
            MOVIE, EPISODE, TRACK, CLIP, PHOTO, UNKNOWN -> false
        }

    /** The localized noun. Never persisted. */
    val label: String
        get() = when (this) {
            MOVIE -> T.common.mediaKind.movie
            SHOW -> T.common.mediaKind.show
            SEASON -> T.common.mediaKind.season
            EPISODE -> T.common.mediaKind.episode
            ARTIST -> T.common.mediaKind.artist
            ALBUM -> T.common.mediaKind.album
            TRACK -> T.common.mediaKind.track
            COLLECTION -> T.common.mediaKind.collection
            PLAYLIST -> T.common.mediaKind.playlist
            CLIP -> T.common.mediaKind.clip
            PHOTO -> T.common.mediaKind.photo
            FOLDER -> T.common.mediaKind.folder
            UNKNOWN -> T.common.unknown
        }

    companion object {
        /** The kind a backend's type string names, case-insensitively, with Jellyfin's names; anything else unknown. */
        fun fromString(raw: String?): MediaKind = when (raw?.lowercase()) {
            null -> UNKNOWN
            "movie" -> MOVIE
            "show", "series" -> SHOW
            "season" -> SEASON
            "episode" -> EPISODE
            "artist", "musicartist" -> ARTIST
            "album", "musicalbum" -> ALBUM
            "track", "audio" -> TRACK
            "collection", "boxset" -> COLLECTION
            "playlist" -> PLAYLIST
            "clip", "trailer", "video", "musicvideo" -> CLIP
            "photo" -> PHOTO
            "folder", "collectionfolder" -> FOLDER
            else -> UNKNOWN
        }
    }
}
