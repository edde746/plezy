package com.edde746.plezy.presentation.music

import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape

/**
 * A music item as a card: square, an artist's drawn as a circle, never marked watched (music is played, not watched);
 * an album captioned with its artist, a track with its artist and length. [MediaCardUi.id] is the item's global key.
 */
fun musicCard(item: MediaItem, backend: MediaBackend?): MediaCardUi = MediaCardUi(
    id = item.globalKey,
    title = item.displayTitle,
    caption = when (item.kind) {
        MediaKind.ALBUM -> item.albumArtistTitle
        MediaKind.TRACK -> listOfNotNull(item.trackArtistTitle, item.durationMs?.let(::formatDurationTextual)).joinToString(" • ").ifEmpty { null }
        else -> null
    },
    shape = CardShape.SQUARE,
    placeholder = when (item.kind) {
        MediaKind.ARTIST -> PlaceholderKind.ARTIST
        MediaKind.ALBUM -> PlaceholderKind.ALBUM
        else -> PlaceholderKind.TRACK
    },
    artwork = backend.squareArtwork(item),
)

/** A music detail screen's header: the artwork beside (wide) or over (compact) the title and its lines. */
data class MusicHeaderUi(
    val title: String,
    /** Square artwork; an artist's drawn as a circle. Null for the kind's icon. */
    val artwork: Artwork?,
    /** An album's artist; null hides it. */
    val artist: String? = null,
    /** The artist line opens the artist. */
    val artistLinked: Boolean = false,
    /** "1998 · 12 tracks · 54m", an artist's genres. */
    val meta: String? = null,
    /** An artist's biography, three lines until expanded. */
    val bio: String? = null,
)

/** The compact header (artwork over centred text and actions) below this width; the wide one from it. */
const val MUSIC_HEADER_WIDE_FROM = 600.0
