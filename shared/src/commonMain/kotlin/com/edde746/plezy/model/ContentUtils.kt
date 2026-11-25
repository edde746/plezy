package com.edde746.plezy.model

/** Library and item type strings as servers send them. */
object ContentTypes {
    const val MOVIE = "movie"
    const val SHOW = "show"
    const val SEASON = "season"
    const val EPISODE = "episode"
    const val ARTIST = "artist"
    const val ALBUM = "album"
    const val TRACK = "track"
    const val COLLECTION = "collection"
    const val PLAYLIST = "playlist"
    const val CLIP = "clip"
}

/** The icon a library row shows; each platform maps it onto its own symbol. */
enum class LibraryIconKind {
    MOVIE,
    TV,
    MUSIC_NOTE,
    PHOTO,
    SHARE,
    FOLDER,
    ;

    companion object {
        /** The icon for a library [type] (case-insensitive): mixed libraries share, unknown types are folders. */
        fun forLibraryType(type: String): LibraryIconKind = when (type.lowercase()) {
            ContentTypes.MOVIE -> MOVIE
            ContentTypes.SHOW -> TV
            ContentTypes.ARTIST -> MUSIC_NOTE
            "photo" -> PHOTO
            "mixed" -> SHARE
            else -> FOLDER
        }
    }
}

private val COUNTRY_PREFIX = Regex("^[a-z]{2,3}/(.+)$", RegexOption.IGNORE_CASE)

/** A content rating without its country prefix (`gb/15` → `15`, `deu/16` → `16`); empty for null or empty. */
fun formatContentRating(contentRating: String?): String {
    if (contentRating.isNullOrEmpty()) return ""
    return COUNTRY_PREFIX.find(contentRating)?.groupValues?.get(1) ?: contentRating
}
