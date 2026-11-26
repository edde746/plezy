package com.edde746.plezy.model

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull

/** Container aspect ratio below which a hero prefers square background art over a cropped 16:9 backdrop. */
private const val SQUARE_HERO_ASPECT_RATIO = 1.39

/** Which artwork an episode card shows. */
enum class EpisodePosterMode { SERIES_POSTER, SEASON_POSTER, EPISODE_THUMBNAIL }

/** The silhouette a media card renders with: 2:3 posters, 16:9 wide thumbnails, 1:1 squares (music). */
enum class CardShape { POSTER, WIDE, SQUARE }

/**
 * One media item from any backend: what UI, stores, persistence and playback traffic in. [backend] tells a Plex item
 * from a Jellyfin or Emby one; a few fields only one backend fills are documented as such.
 *
 * Times are epoch seconds ([lastViewedAt], [addedAt], [updatedAt]); durations and offsets milliseconds. [raw] keeps
 * the backend's own JSON object for the few readers that need a field the model doesn't carry.
 */
data class MediaItem(
    val id: String,
    val backend: BackendKind,
    val kind: MediaKind,
    val guid: String? = null,
    val title: String? = null,
    val titleSort: String? = null,
    val summary: String? = null,
    val tagline: String? = null,
    val originalTitle: String? = null,
    /** Plex only: distinguishes versions of the same movie. */
    val editionTitle: String? = null,
    val studio: String? = null,
    val year: Int? = null,
    /** `YYYY-MM-DD`. */
    val originallyAvailableAt: String? = null,
    val contentRating: String? = null,
    val parentId: String? = null,
    val parentTitle: String? = null,
    val parentThumbPath: String? = null,
    val parentIndex: Int? = null,
    val index: Int? = null,
    val grandparentId: String? = null,
    val grandparentTitle: String? = null,
    val grandparentThumbPath: String? = null,
    val grandparentArtPath: String? = null,
    val grandparentBackdropPaths: List<String>? = null,
    val thumbPath: String? = null,
    val artPath: String? = null,
    val backdropPaths: List<String>? = null,
    val clearLogoPath: String? = null,
    val backgroundSquarePath: String? = null,
    val durationMs: Long? = null,
    val viewOffsetMs: Long? = null,
    val viewCount: Int? = null,
    val lastViewedAt: Long? = null,
    val leafCount: Int? = null,
    val viewedLeafCount: Int? = null,
    val childCount: Int? = null,
    val addedAt: Long? = null,
    val updatedAt: Long? = null,
    val rating: Double? = null,
    val userRating: Double? = null,
    /** Every attributed score the response carried, headline first. */
    val ratings: List<MediaRatingSource>? = null,
    val isFavorite: Boolean? = null,
    val genres: List<String>? = null,
    val directors: List<String>? = null,
    val writers: List<String>? = null,
    val producers: List<String>? = null,
    val countries: List<String>? = null,
    val collections: List<String>? = null,
    val labels: List<String>? = null,
    val styles: List<String>? = null,
    val moods: List<String>? = null,
    val roles: List<MediaRole>? = null,
    /**
     * Null: the response carried no versions, so fetch the item. Non-empty: the complete list, which version pickers,
     * saved-version resolution and delete impact trust without a detail fetch.
     */
    val mediaVersions: List<MediaVersion>? = null,
    val libraryId: String? = null,
    val libraryTitle: String? = null,
    /** Plex only. */
    val trailerKey: String? = null,
    /** The per-playlist entry id playlist edits address (Plex's numeric `playlistItemID`, Jellyfin's entry id). */
    val playlistItemId: String? = null,
    /** Plex only: the entry's id in a server play queue. */
    val playQueueItemId: Int? = null,
    /** Plex only: the extra's or video's classification (`trailer`, `clip`). */
    val subtype: String? = null,
    val serverId: String? = null,
    val serverName: String? = null,
    /** Plex only: the folder listing a [MediaKind.FOLDER] row opens; Jellyfin folders open by [id]. */
    val backendFolderKey: String? = null,
    val raw: JsonObject? = null,
) {
    val dialect: MediaBrowserDialect? get() = backend.dialect

    /** `"{serverId}:{id}"`, or the bare [id] without a server. */
    val globalKey: String get() = ServerId.tryParse(serverId)?.let { buildGlobalKey(it, id) } ?: id

    /** `"{serverId}:{libraryId}"` when both are known. */
    val libraryGlobalKey: String?
        get() {
            val server = ServerId.tryParse(serverId) ?: return null
            return libraryId?.let { buildGlobalKey(server, it) }
        }

    /** The series' key for an episode or season; null for every other kind. */
    val seriesGlobalKey: String?
        get() {
            val seriesId = when (kind) {
                MediaKind.EPISODE -> grandparentId
                MediaKind.SEASON -> grandparentId ?: parentId
                else -> null
            } ?: return null
            return ServerId.tryParse(serverId)?.let { buildGlobalKey(it, seriesId) } ?: seriesId
        }

    /** Ancestor ids for hierarchical invalidation: an episode's season and show, a season's show. */
    val parentChain: List<String> get() = listOfNotNull(parentId, grandparentId)

    /** Every version's file paths. A multi-episode file is several items with different part ids but one file. */
    val allPartFiles: Set<String>
        get() = buildSet {
            for (version in mediaVersions.orEmpty()) for (part in version.parts) if (!part.file.isNullOrEmpty()) add(part.file)
        }

    /**
     * Whether [other] plays the same file. With [playedPartId] known, only that part's file counts; else any overlap.
     * Items on different servers or without file paths never match.
     */
    fun sharesFileWith(other: MediaItem, playedPartId: String? = null): Boolean {
        if (other.serverId != serverId) return false
        val otherFiles = other.allPartFiles
        if (otherFiles.isEmpty()) return false
        if (playedPartId != null) {
            val playedFile = filePathForPart(playedPartId)
            if (playedFile != null) return playedFile in otherFiles
        }
        return allPartFiles.any { it in otherFiles }
    }

    private fun filePathForPart(partId: String): String? {
        for (version in mediaVersions.orEmpty()) for (part in version.parts) {
            if (part.id == partId) return part.file?.takeIf { it.isNotEmpty() }
        }
        return null
    }

    /** Continue Watching order: last watched, else added. */
    val recencySortKey: Long get() = lastViewedAt ?: addedAt ?: 0

    val hasActiveProgress: Boolean
        get() {
            val duration = durationMs ?: return false
            val offset = viewOffsetMs ?: return false
            return offset > 0 && offset < duration
        }

    /** Not fully watched, or watched but resumable: what every "unwatched only" selection keeps. */
    val isUnwatchedOrInProgress: Boolean get() = !isWatched || hasActiveProgress

    /** A container's positive leaf total; seasons fall back to their child count, shows never (children are seasons). */
    val leafWatchTotal: Int?
        get() {
            if (!kind.usesLeafWatchCounts) return null
            val total = leafCount ?: if (kind == MediaKind.SEASON) childCount else null
            return total?.takeIf { it > 0 }
        }

    /** Watched leaves over [leafWatchTotal], clamped to 0–1. */
    val leafWatchFraction: Double?
        get() {
            val total = leafWatchTotal ?: return null
            val viewed = viewedLeafCount ?: return null
            if (viewed <= 0) return 0.0
            if (viewed >= total) return 1.0
            return viewed.toDouble() / total
        }

    val isPartiallyWatched: Boolean get() = leafWatchFraction.let { it != null && it > 0 && it < 1 }

    /** Containers with a leaf total: every leaf watched. Everything else: watched at least once. */
    val isWatched: Boolean
        get() {
            val fraction = leafWatchFraction
            if (fraction != null) return fraction >= 1
            return (viewCount ?: 0) > 0
        }

    /** A container's unwatched leaves; Jellyfin's `UserData.UnplayedItemCount` without leaf totals. */
    val unwatchedCount: Int?
        get() {
            if (!kind.usesLeafWatchCounts) return null
            val total = leafWatchTotal
            val viewed = viewedLeafCount
            if (total != null && viewed != null) return (total - viewed).coerceIn(0, total)
            val userData = raw?.get("UserData") as? JsonObject
            val unplayed = (userData?.get("UnplayedItemCount") as? JsonPrimitive)?.let { it.intOrNull ?: it.content.toDoubleOrNull()?.toInt() }
            return unplayed?.takeIf { it >= 0 }
        }

    /** A copy whose [isWatched] is [watched] for every kind: the one seam watch-state overlays mutate through. */
    fun withWatchedFlag(watched: Boolean): MediaItem {
        val total = leafWatchTotal
        val viewedLeaf = when {
            total != null -> if (watched) total else 0
            kind.usesLeafWatchCounts -> viewedLeafCount
            else -> null
        }
        return copy(viewCount = if (watched) 1 else 0, viewedLeafCount = viewedLeaf)
    }

    /** The show's name for episodes and seasons, else the title. */
    val displayTitle: String
        get() {
            if ((kind == MediaKind.EPISODE || kind == MediaKind.SEASON) && grandparentTitle != null) return grandparentTitle
            if (kind == MediaKind.SEASON && parentTitle != null) return parentTitle
            return title ?: ""
        }

    /** The episode's or season's own title when [displayTitle] showed the show's. */
    val displaySubtitle: String?
        get() {
            if (kind == MediaKind.EPISODE || kind == MediaKind.SEASON) {
                if (grandparentTitle != null || (kind == MediaKind.SEASON && parentTitle != null)) return title
            }
            return null
        }

    val trackNumber: Int? get() = if (kind == MediaKind.TRACK) index else null
    val discNumber: Int? get() = if (kind == MediaKind.TRACK) parentIndex else null
    val albumTitle: String?
        get() = when (kind) {
            MediaKind.TRACK -> parentTitle
            MediaKind.ALBUM -> title
            else -> null
        }
    val albumYear: Int? get() = if (kind == MediaKind.TRACK || kind == MediaKind.ALBUM) year else null
    val albumArtistTitle: String?
        get() = when (kind) {
            MediaKind.TRACK -> grandparentTitle
            MediaKind.ALBUM -> parentTitle
            else -> null
        }

    /** A track's performing artist: its own when it differs from the album artist's. */
    val trackArtistTitle: String? get() = if (kind == MediaKind.TRACK) originalTitle ?: albumArtistTitle else null

    /** Plex's unmatched home videos: movies by kind (their actions stay) that render as clips. */
    private val isPlexHomeVideo: Boolean get() = backend == BackendKind.PLEX && kind == MediaKind.MOVIE && subtype == "clip"

    /** The card's image path for [mode]. */
    fun posterThumb(mode: EpisodePosterMode = EpisodePosterMode.SERIES_POSTER, mixedHubContext: Boolean = false): String? {
        if (kind == MediaKind.EPISODE) {
            return when (mode) {
                EpisodePosterMode.EPISODE_THUMBNAIL -> thumbPath
                EpisodePosterMode.SEASON_POSTER -> parentThumbPath ?: grandparentThumbPath ?: thumbPath
                EpisodePosterMode.SERIES_POSTER -> grandparentThumbPath ?: thumbPath
            }
        }
        if (kind == MediaKind.SEASON) {
            if (mixedHubContext && mode == EpisodePosterMode.EPISODE_THUMBNAIL) return artPath ?: thumbPath
            if (grandparentThumbPath != null) return grandparentThumbPath
        }
        if (kind == MediaKind.CLIP || isPlexHomeVideo) return thumbPath ?: artPath
        if (mixedHubContext && mode == EpisodePosterMode.EPISODE_THUMBNAIL && (kind == MediaKind.MOVIE || kind == MediaKind.SHOW)) {
            return artPath ?: thumbPath
        }
        return thumbPath
    }

    /** The image to try when [posterThumb]'s fails to load: a track's album art, a season poster's series poster. */
    fun posterThumbFallback(mode: EpisodePosterMode = EpisodePosterMode.SERIES_POSTER, mixedHubContext: Boolean = false): String? {
        val fallback = when {
            kind == MediaKind.TRACK -> parentThumbPath
            kind == MediaKind.EPISODE && mode == EpisodePosterMode.SEASON_POSTER -> grandparentThumbPath ?: thumbPath
            else -> return null
        }
        return fallback?.takeIf { it != posterThumb(mode, mixedHubContext) }
    }

    fun usesWideAspectRatio(mode: EpisodePosterMode, mixedHubContext: Boolean = false): Boolean {
        if (kind == MediaKind.CLIP || isPlexHomeVideo) return true
        if (kind == MediaKind.EPISODE && mode == EpisodePosterMode.EPISODE_THUMBNAIL) return true
        return mixedHubContext && mode == EpisodePosterMode.EPISODE_THUMBNAIL &&
            (kind == MediaKind.MOVIE || kind == MediaKind.SHOW || kind == MediaKind.SEASON)
    }

    fun cardShape(mode: EpisodePosterMode, mixedHubContext: Boolean = false): CardShape = when {
        kind.isMusic -> CardShape.SQUARE
        usesWideAspectRatio(mode, mixedHubContext) -> CardShape.WIDE
        else -> CardShape.POSTER
    }

    /** The item's own backdrops in display order, else its single [artPath]. */
    val resolvedBackdropPaths: List<String>
        get() = backdropPaths?.takeIf { it.isNotEmpty() } ?: listOfNotNull(artPath?.takeIf { it.isNotEmpty() })

    /** Backdrops inherited from the series, else its single [grandparentArtPath]. */
    val resolvedGrandparentBackdropPaths: List<String>
        get() = grandparentBackdropPaths?.takeIf { it.isNotEmpty() } ?: listOfNotNull(grandparentArtPath?.takeIf { it.isNotEmpty() })

    /** Episodes prefer the series' backdrops; everything else its own, inheriting only without any. */
    val heroBackdropPaths: List<String>
        get() {
            if (kind == MediaKind.EPISODE) return resolvedGrandparentBackdropPaths.ifEmpty { resolvedBackdropPaths }
            return resolvedBackdropPaths.ifEmpty { resolvedGrandparentBackdropPaths }
        }

    /** The backdrops a hero rotates through: a near-square container holds still on the square art when there is one. */
    fun heroRotationPaths(containerAspectRatio: Double): List<String> {
        if (containerAspectRatio < SQUARE_HERO_ASPECT_RATIO && !backgroundSquarePath.isNullOrEmpty()) return listOf(backgroundSquarePath)
        return heroBackdropPaths
    }

    /** Hero art in preference order for a container of [containerAspectRatio]; blanks and duplicates dropped. */
    fun heroArtCandidates(containerAspectRatio: Double): List<String> {
        val own = resolvedBackdropPaths
        val inherited = resolvedGrandparentBackdropPaths
        val nearSquare = containerAspectRatio < SQUARE_HERO_ASPECT_RATIO
        val preferred: List<String?> = when {
            kind == MediaKind.EPISODE && nearSquare -> listOf(backgroundSquarePath) + inherited + own
            kind == MediaKind.EPISODE -> inherited + own + backgroundSquarePath
            nearSquare -> listOf(backgroundSquarePath) + own + inherited
            else -> own + inherited + backgroundSquarePath
        }
        return preferred.filterNotNull().filter { it.isNotEmpty() }.distinct()
    }

    val isShow: Boolean get() = kind == MediaKind.SHOW
    val isMovie: Boolean get() = kind == MediaKind.MOVIE
    val isSeason: Boolean get() = kind == MediaKind.SEASON
    val isEpisode: Boolean get() = kind == MediaKind.EPISODE
    val isTrack: Boolean get() = kind == MediaKind.TRACK
    val isVideoContent: Boolean get() = kind == MediaKind.MOVIE || kind == MediaKind.SHOW || kind == MediaKind.SEASON || kind == MediaKind.EPISODE

    /** A season's show (Jellyfin and Emby name it the series, Plex the season's parent); null for anything else. */
    val seasonShowId: String? get() = if (kind == MediaKind.SEASON) grandparentId ?: parentId else null

    /** Unwatched episodes hide spoilers, in-progress ones included. */
    val shouldHideSpoiler: Boolean get() = kind == MediaKind.EPISODE && !isWatched

    /** Art that shows nothing of the episode itself. */
    val spoilerSafeArt: String? get() = grandparentArtPath ?: artPath

    companion object
}
