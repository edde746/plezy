package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.placeholderKind
import com.edde746.plezy.presentation.browse.MediaCardUi

/**
 * A downloaded [item] as the Downloads screen's card: its stored artwork ([artworkPath], a local file), the watch
 * badges from its offline watch state, an episode's "S1 E4" caption, a title's year, a folder's item count.
 */
fun downloadCard(item: MediaItem, artworkPath: String?, folderCount: Int? = null): MediaCardUi {
    val caption = when {
        item.isEpisode -> listOfNotNull(
            item.grandparentTitle,
            if (item.parentIndex != null && item.index != null) "S${item.parentIndex} E${item.index}" else null,
        ).joinToString(" · ").ifEmpty { null }
        item.isSeason -> item.parentTitle
        item.kind == MediaKind.ALBUM -> item.parentTitle
        folderCount != null -> folderCount.toString()
        else -> item.year?.toString()
    }
    val unwatched = if (item.isShow || item.isSeason) ((item.leafCount ?: 0) - (item.viewedLeafCount ?: 0)).coerceAtLeast(0) else 0
    return MediaCardUi(
        id = item.globalKey,
        title = item.displayTitle,
        caption = caption,
        shape = com.edde746.plezy.presentation.layout.CardShape.valueOf(item.cardShape(EpisodePosterMode.SERIES_POSTER).name),
        placeholder = placeholderKind(item.kind),
        artwork = Artwork.fixed(artworkPath),
        watched = item.isWatched && unwatched == 0 && !item.isDownloadsFolder,
        progress = item.viewOffsetMs?.let { offset -> item.durationMs?.takeIf { it > 0 }?.let { offset.toDouble() / it } }
            ?.takeIf { it > 0 && it < 1 },
        unwatchedCount = unwatched,
    )
}
