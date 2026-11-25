package com.edde746.plezy.presentation.browse

import com.edde746.plezy.model.MediaKind

/**
 * What stands in for missing artwork: the kind's icon on the muted surface, in a circle for a person or an artist
 * ([circular]) and in the artwork's own shape (a poster's, an album's, an episode's) for anything else.
 */
enum class PlaceholderKind {
    MOVIE,
    SHOW,
    EPISODE,
    ALBUM,
    TRACK,
    ARTIST,
    PERSON,
    PLAYLIST,
    COLLECTION,
    CHANNEL,
    ;

    val circular: Boolean get() = this == ARTIST || this == PERSON
}

/** The placeholder of an item of [kind]: a season shows its show's, any kind without its own a movie's. */
fun placeholderKind(kind: MediaKind): PlaceholderKind = when (kind) {
    MediaKind.SHOW, MediaKind.SEASON -> PlaceholderKind.SHOW
    MediaKind.EPISODE -> PlaceholderKind.EPISODE
    MediaKind.ALBUM -> PlaceholderKind.ALBUM
    MediaKind.TRACK -> PlaceholderKind.TRACK
    MediaKind.ARTIST -> PlaceholderKind.ARTIST
    MediaKind.PLAYLIST -> PlaceholderKind.PLAYLIST
    MediaKind.COLLECTION -> PlaceholderKind.COLLECTION
    else -> PlaceholderKind.MOVIE
}
