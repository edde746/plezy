package com.edde746.plezy.presentation.browse

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.formatContentRating
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.layout.hubShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import kotlin.math.roundToInt
import com.edde746.plezy.model.CardShape as ItemShape

/**
 * The settings that change how a card shows an item: `episode_poster_mode`, `show_episode_number_on_cards`,
 * `hide_spoilers`, `show_watched_indicators`, `show_unwatched_count`.
 *
 * @param mixedHub the card sits in a row of several kinds, where movies and shows take their wide art under the
 *   episode-thumbnail mode.
 * @param showTitleImplied the card sits inside its own show (a show's episode rail on TV): an episode is titled by its
 *   own title and captioned by its number and runtime, without the show's name or a season link.
 */
data class CardOptions(
    val episodePosterMode: EpisodePosterMode = EpisodePosterMode.EPISODE_THUMBNAIL,
    val showEpisodeNumber: Boolean = true,
    val hideSpoilers: Boolean = false,
    val showWatchedIndicators: Boolean = true,
    val showUnwatchedCount: Boolean = true,
    val mixedHub: Boolean = false,
    val showTitleImplied: Boolean = false,
)

/**
 * [this] item as a card shows it, its id the item's global key. [client] is the item's server, which sizes its images
 * to where the UIs draw them; without one the card draws its icon.
 */
fun MediaItem.toCardUi(client: MediaBackend?, options: CardOptions = CardOptions()): MediaCardUi {
    val mode = options.episodePosterMode
    val shape = cardShape(mode, options.mixedHub).toCardShape()
    val spoiler = options.hideSpoilers && shouldHideSpoiler
    val offset = viewOffsetMs
    val duration = durationMs
    val titleImplied = options.showTitleImplied && kind == MediaKind.EPISODE
    val seasonLink = if (kind == MediaKind.EPISODE && parentIndex != null && parentId != null) detailRouteOf(this) else null
    return MediaCardUi(
        id = globalKey,
        title = if (titleImplied) title ?: displayTitle else displayTitle,
        caption = gridCaption(options.showEpisodeNumber, titleImplied),
        shape = shape,
        placeholder = placeholderKind(kind),
        artwork = Artwork.of(client, posterThumb(mode, options.mixedHub), shape.imageKind()),
        // 16:9 thumbs never fall back; posters and squares do.
        fallbackArtwork = if (shape == CardShape.WIDE) null else Artwork.of(client, posterThumbFallback(mode, options.mixedHub), shape.imageKind()),
        blurred = spoiler && mode == EpisodePosterMode.EPISODE_THUMBNAIL,
        backdrops = heroBackdropPaths.mapNotNull { Artwork.of(client, it, ImageKind.ART) },
        logo = Artwork.of(client, clearLogoPath, ImageKind.HERO_LOGO),
        summary = if (spoiler) null else summary?.takeIf { it.isNotBlank() },
        metadata = heroMetadata(),
        // Music shows no watched marks: a played track or album is no video seen.
        watched = options.showWatchedIndicators && !kind.isMusic && isWatched && !hasActiveProgress,
        progress = if (hasActiveProgress && offset != null && duration != null && duration > 0) offset.toDouble() / duration else null,
        unwatchedCount = if (options.showUnwatchedCount && !kind.isMusic) unwatchedCount ?: 0 else 0,
        minutesLeft = if (hasActiveProgress && offset != null && duration != null) ((duration - offset) / 60_000.0).roundToInt() else null,
        titleLink = if (titleImplied) null else titleLinkOf(this),
        captionLink = if (titleImplied) null else seasonLink?.let { CardLink("S$parentIndex", it) },
        listMetadata = listMetadataLine().takeIf { it.isNotEmpty() },
        listSubtitle = if (seasonLink != null) gridCaption(options.showEpisodeNumber) else listSubtitle(options.showEpisodeNumber),
        seriesKey = seriesGlobalKey,
    )
}

/**
 * [this] playlist as a card of [shape]: titled by its title, captioned "N items" (an empty line without items), its
 * list metadata "N items • 2h 10m • Smart Playlist".
 */
fun MediaPlaylist.toCardUi(client: MediaBackend?, shape: CardShape): MediaCardUi {
    val count = leafCount?.takeIf { it > 0 }?.let { T.playlists.itemCount(it.toString()) }
    return MediaCardUi(
        id = globalKey,
        title = title,
        caption = count,
        shape = shape,
        placeholder = PlaceholderKind.PLAYLIST,
        artwork = Artwork.of(client, displayImagePath, shape.imageKind()),
        summary = summary?.takeIf { it.isNotBlank() },
        listMetadata = listOfNotNull(count, durationMs?.let(::formatDurationTextual), T.playlists.smartPlaylist.takeIf { smart })
            .joinToString(" • ").takeIf { it.isNotEmpty() },
    )
}

/**
 * The detail a click on [item]'s title opens: an episode's show (at the episode) when it knows its show, a season's
 * show when it knows it, a movie's own; null for anything else, whose title is plain text.
 */
fun titleLinkOf(item: MediaItem): Route? = when (item.kind) {
    MediaKind.EPISODE -> item.grandparentId?.let { detailRouteOf(item) }
    MediaKind.SEASON -> item.parentId?.let { detailRouteOf(item) }
    MediaKind.MOVIE -> detailRouteOf(item)
    else -> null
}

/**
 * The list view's metadata line: a collection's "N items"; else the content rating, the year, the edition, the
 * runtime (not an artist's, which sums whatever tracks the server holds), the rating ("7.7★") and the studio, joined by
 * " • ". Empty when there is none.
 */
fun MediaItem.listMetadataLine(): String {
    if (kind == MediaKind.COLLECTION) {
        val count = childCount ?: leafCount
        return if (count != null && count > 0) T.playlists.itemCount(count.toString()) else ""
    }
    return listOfNotNull(
        contentRating?.takeIf { it.isNotEmpty() }?.let(::formatContentRating)?.takeIf { it.isNotEmpty() },
        year?.toString(),
        editionTitle,
        durationMs?.takeIf { kind != MediaKind.ARTIST }?.let(::formatDurationTextual),
        rating?.let { "${formatRating(it)}★" },
        studio?.takeIf { it.isNotEmpty() },
    ).joinToString(" • ")
}

/**
 * The list view's line under the metadata (an episode with its season's id takes [gridCaption]'s "S1 E4 · Title"
 * with its season link instead): an album's artist, a track's artist, "S{season}[ E{episode}]" for a numbered item,
 * else the subtitle, else the parent's title.
 */
fun MediaItem.listSubtitle(showEpisodeNumber: Boolean): String? {
    if (kind == MediaKind.ALBUM) return albumArtistTitle
    if (kind == MediaKind.TRACK) return trackArtistTitle
    if (parentIndex != null && index != null) return "S$parentIndex${if (showEpisodeNumber) " E$index" else ""}"
    return displaySubtitle ?: parentTitle
}

/**
 * [this] hub as a row, its cards mapped by [toCardUi] ([client] the hub's server), laid out as a mixed hub where its
 * items make one ([isMixedHub]).
 */
fun MediaHub.toHubUi(client: MediaBackend?, options: CardOptions = CardOptions(), continueWatching: Boolean = false): HubUi {
    val cardOptions = options.copy(mixedHub = isMixedHub(items, options.episodePosterMode))
    val cards = items.map { it.toCardUi(client, cardOptions) }
    return HubUi(
        id = hubKey(serverId, id),
        title = title,
        items = cards,
        shape = hubShape(cards.map { it.shape }, options.episodePosterMode == EpisodePosterMode.EPISODE_THUMBNAIL),
        more = more,
        continueWatching = continueWatching,
    )
}

/**
 * Whether [items] make a mixed hub: some of them wide in [mode] (episodes under the episode-thumbnail mode, clips,
 * home videos) and some not. The hub's own type says nothing: a row of movies alone keeps their posters.
 */
fun isMixedHub(items: List<MediaItem>, mode: EpisodePosterMode): Boolean =
    items.any { it.usesWideAspectRatio(mode) } && items.any { !it.usesWideAspectRatio(mode) }

/** A hub's row id ([HubUi.id]): its id under its server's, as two servers' hubs share ids. */
fun hubKey(serverId: String?, hubId: String): String = serverId?.let { "$it:$hubId" } ?: hubId

/**
 * The grid card's line under the title; null keeps the line empty. An episode reads "S1 E4 · Title" ("S1 E4 · 42m"
 * when [showTitleImplied]: its title is the card's).
 */
fun MediaItem.gridCaption(showEpisodeNumber: Boolean, showTitleImplied: Boolean = false): String? {
    if (kind == MediaKind.COLLECTION) {
        val count = childCount ?: leafCount
        if (count != null && count > 0) return T.playlists.itemCount(count.toString())
    }
    if (kind == MediaKind.ALBUM && albumArtistTitle != null) return albumArtistTitle
    if (kind == MediaKind.TRACK) {
        val parts = listOfNotNull(trackArtistTitle, durationMs?.let(::formatDurationTextual))
        if (parts.isNotEmpty()) return parts.joinToString(" • ")
    }
    if (kind == MediaKind.EPISODE && parentIndex != null) {
        val number = "S$parentIndex${if (showEpisodeNumber && index != null) " E$index" else ""}"
        if (showTitleImplied) return listOfNotNull(number, durationMs?.let(::formatDurationTextual)).joinToString(" · ")
        return "$number · ${displaySubtitle ?: displayTitle}"
    }
    displaySubtitle?.let { return it }
    parentTitle?.let { return it }
    val year = year ?: return null
    return editionTitle?.let { "$year · $it" } ?: "$year"
}

/**
 * The hero's metadata line, "TV Show • ★ 8.4 • TV-MA • 2019"; null without a rating, a content rating or a year. The
 * kind reads "Movie" for a movie and "TV Show" for a show, season or episode; any other kind (an album, artist, track…)
 * its own noun ([MediaKind.label]).
 */
fun MediaItem.heroMetadata(): String? {
    if (year == null && contentRating == null && rating == null) return null
    return listOfNotNull(
        when (kind) {
            MediaKind.MOVIE -> T.discover.movie
            MediaKind.SHOW, MediaKind.SEASON, MediaKind.EPISODE -> T.discover.tvShow
            else -> kind.label
        },
        rating?.let { "★ ${formatRating(it)}" },
        contentRating?.let(::formatContentRating),
        year?.toString(),
    ).joinToString(" • ")
}

/** A rating as cards write it: whole numbers bare, others with one decimal. */
fun formatRating(value: Double): String {
    if (value == kotlin.math.truncate(value)) return value.toLong().toString()
    val tenths = (value * 10).roundToInt()
    return "${tenths / 10}.${kotlin.math.abs(tenths % 10)}"
}

private fun ItemShape.toCardShape(): CardShape = when (this) {
    ItemShape.POSTER -> CardShape.POSTER
    ItemShape.WIDE -> CardShape.WIDE
    ItemShape.SQUARE -> CardShape.SQUARE
}

/** What a card's artwork is drawn as: a poster, a 16:9 thumb or a square. */
private fun CardShape.imageKind(): ImageKind = when (this) {
    CardShape.POSTER -> ImageKind.POSTER
    CardShape.WIDE -> ImageKind.THUMB
    CardShape.SQUARE -> ImageKind.SQUARE
}

/**
 * Card artwork that failed to load, remembered for the whole process (at most [LIMIT], the oldest forgotten first), so
 * a card built later goes straight to its [MediaCardUi.fallbackArtwork] ([primaryArtwork]). Only a load that was tried
 * and failed is remembered. Main thread only.
 */
object FailedArtwork {
    const val LIMIT = 512

    private val keys = LinkedHashSet<String>()

    /** Remembers that [artwork] failed to load, as the newest entry. */
    fun remember(artwork: Artwork) {
        keys.remove(artwork.key)
        keys.add(artwork.key)
        if (keys.size > LIMIT) keys.remove(keys.first())
    }

    /** Whether [artwork] failed to load before (and is still remembered). */
    fun isFailed(artwork: Artwork?): Boolean = artwork != null && artwork.key in keys

    /** Forgets everything: for tests. */
    fun clear() = keys.clear()
}

/** The artwork [this] card loads first: its fallback when its artwork failed before ([FailedArtwork]), else its artwork. */
val MediaCardUi.primaryArtwork: Artwork?
    get() = if (fallbackArtwork != null && FailedArtwork.isFailed(artwork)) fallbackArtwork else artwork

/** What [this] card falls back to when [primaryArtwork] fails: its fallback, unless it already starts there. */
val MediaCardUi.retryArtwork: Artwork?
    get() = if (primaryArtwork === fallbackArtwork) null else fallbackArtwork
