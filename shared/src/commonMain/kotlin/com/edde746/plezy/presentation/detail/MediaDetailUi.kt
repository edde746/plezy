package com.edde746.plezy.presentation.detail

import com.edde746.plezy.image.Artwork
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.strings.T
import kotlin.math.roundToInt

/** Where one section of a detail screen stands: its spinner, its error with Retry, its empty text, or its rows. */
enum class SectionLoad { LOADING, ERROR, EMPTY, CONTENT }

/** A media item's detail screen ([MediaDetailStore]). */
data class MediaDetailUiState(
    /** [SectionLoad.LOADING] until the item paints, [SectionLoad.ERROR] when it is unavailable. */
    val load: SectionLoad,
    val kind: MediaKind?,
    val hero: DetailHeroUi?,
    val actions: DetailActionsUi,
    /** A show's season tabs; empty for a flattened show and other kinds. */
    val seasons: List<SeasonTabUi>,
    val selectedSeason: Int,
    /** The seasons' load: a show's tabs or its flattened episode list wait on it. */
    val seasonsLoad: SectionLoad,
    /** The selected season's (or a flattened show's, or a season's own) episodes; null for movies and episodes. */
    val episodes: EpisodeListUi?,
    val cast: List<CastUi>,
    /** Trailers and featurettes, played on select. */
    val extras: List<MediaCardUi>,
    /** Related hubs: the collection, similar titles, more with the cast. */
    val related: List<HubUi>,
    /** Studio, directors and rating ("Studio" → "A24"). */
    val info: List<InfoRowUi>,
    /**
     * Everything the TV layout waits for has landed (the item with its download button, its extras and related hubs, its
     * episodes): it reveals its actions and sections and focuses its first control.
     */
    val ready: Boolean,
    /**
     * The item (with its on-deck episode and its download button) is still to come: the hero is the card's it was
     * opened from. The phone, tablet and desktop pages show only its artwork and title meanwhile, and bring in the facts,
     * the actions, the overview and the sections below once it has landed, so nothing it brings moves the page.
     */
    val itemLoading: Boolean = false,
    /**
     * The episode focus starts on (the TV rail's initial item, the phone list's scroll target): the requested episode,
     * else the on-deck one, when it is in the selected list.
     */
    val initialEpisodeId: String? = null,
    /** What Play's tracks will be, right of the action row; null until probed or when unknown. */
    val tracks: TrackStatusUi? = null,
    /** [tracks] are still to come: the track status keeps its line's room, so its arrival moves nothing. */
    val tracksLoading: Boolean = false,
    /** The download button; null when it doesn't show (offline, no downloads on the device). */
    val download: DownloadButtonSpec? = null,
    /** A shuffle is loading: its loading dialog's title, with Cancel ([MediaDetailStore.cancelLaunch]). */
    val launching: String? = null,
    /** Each season tab shows the season's poster above it (the setting; never on TV). */
    val seasonPosters: Boolean = false,
    /** Where a deep link's focus lands first (not on TV); null when the route asks for none or it isn't known yet. */
    val initialFocus: DetailInitialFocus? = null,
    /** The unavailable state offers Retry ([MediaDetailStore.retry]): the server's fetch failed and may work again. */
    val canRetry: Boolean = false,
    /** A one-off message (a toast) until the screen has shown it ([MediaDetailStore.messageShown]). */
    val message: String? = null,
    /** The item was deleted: the screen leaves once it is the top screen, at once or when it shows again. */
    val gone: Boolean = false,
)

/**
 * A deep link's first focus: the requested episode's row ([episodeId]) once paging has brought it in, else (no such
 * episode) the selected season's tab ([seasonIndex]), else a flattened list's first episode. One of the two is set.
 */
data class DetailInitialFocus(val episodeId: String? = null, val seasonIndex: Int? = null)

/**
 * The tracks Play will start on: the picture labels ("4K", "HEVC", "DV"), the audio track and the subtitle, which is
 * [subtitle] or "Off". Labels shed from the end when the row runs out of room: details first, then [video], then audio.
 */
data class TrackStatusUi(
    val video: List<String>,
    val audio: String?,
    val audioDetail: String?,
    val subtitle: String,
    val subtitleDetail: String?,
) {
    /** The status as one spoken line: "Audio & Subtitles: 4K, HEVC, English · EAC3 5.1, Off". */
    val semanticLabel: String
        get() {
            fun joined(text: String?, detail: String?) = if (text == null || detail == null) text else "$text · $detail"
            val parts = video + listOfNotNull(joined(audio, audioDetail), joined(subtitle, subtitleDetail))
            return "${T.videoControls.tracksButton}: ${parts.joinToString(", ")}"
        }
}

/** The item at the top of a detail screen, or on TV the focused episode in its place. */
data class DetailHeroUi(
    val title: String,
    /** An episode's own title under its show's logo. */
    val episodeTitle: String?,
    val logo: Artwork?,
    /**
     * The backgrounds the hero turns through ([com.edde746.plezy.presentation.browse.BackdropRotation]): its backdrops
     * (an episode's show's first), else its art; offline only the stored ones. Empty: none to show.
     */
    val backdrops: List<Artwork>,
    val poster: Artwork?,
    val tagline: String?,
    /** "S1 E4", the air date or year, certification, duration: the metadata line's parts in order. */
    val metadata: List<String>,
    val genres: List<String>,
    val summary: String?,
    val qualityLabels: List<String>,
    /** The version's total size ("4.2 GB"). */
    val sizeLabel: String?,
    /** Plex's edition title ("Director's Cut"). */
    val edition: String?,
    /** The server's and the item's own ratings sources, for the ratings strip. */
    val ratings: List<MediaRatingSource>,
)

/** The action row. */
data class DetailActionsUi(
    /** The Play button's text ("S1E4"); null draws the icon alone. */
    val playLabel: String? = null,
    /** Play resumes: the target has a saved position, and Play from start is offered. */
    val resume: Boolean = false,
    /** The versions' names when there are several: the split segment that picks one. */
    val versions: List<String> = emptyList(),
    /** The version Play plays (the saved version choice, else the first), an index of [versions]. */
    val version: Int = 0,
    /**
     * The qualities a movie or episode plays at ([version] of [versions] where there are several) where the server
     * transcodes ([MediaDetailStore.playQuality]), the original first; empty where it doesn't. Play's version menu shows
     * where these or [versions] are there.
     */
    val qualities: List<String> = emptyList(),
    /** The quality Play plays at, an index of [qualities]. */
    val quality: Int = 0,
    val trailer: Boolean = false,
    /** Shows and seasons play shuffled. */
    val shuffle: Boolean = false,
    val watched: Boolean = false,
    /** The mark-watched toggle shows (not for an item without a server). */
    val canMarkWatched: Boolean = false,
    /** Plays nothing yet: the item or its episodes are still loading. */
    val playEnabled: Boolean = false,
    /** The ⋮ menu shows (online only). */
    val more: Boolean = false,
)

/**
 * A season's chip: [watched] once every episode is (the check), else [progress], the watched share of its episodes
 * (above 0, below 1: the ring), null for a season not started or without episode counts (nothing). Both follow the
 * watched-indicators setting.
 */
data class SeasonTabUi(
    val id: String,
    val title: String,
    val poster: Artwork?,
    val watched: Boolean,
    val progress: Double?,
)

/** A season's (or a flattened show's) episode list. */
data class EpisodeListUi(
    val load: SectionLoad,
    val rows: List<EpisodeRowUi>,
    /** More pages wait: reaching the end (or focusing the last row) loads the next. */
    val hasMore: Boolean,
    /** The next page failed: the list's tail shows Retry. */
    val moreFailed: Boolean,
)

data class EpisodeRowUi(
    val id: String,
    /** "4. Title" (an index of 0 kept as it is). */
    val title: String,
    /** Null when hidden as a spoiler or empty. */
    val summary: String?,
    val thumb: Artwork?,
    /** Spoilers hidden: the thumbnail is drawn blurred. */
    val blurThumb: Boolean,
    /** Duration, air date, ★ rating, quality labels, size: the row's metadata, joined with bullets. */
    val metadata: List<String>,
    val watched: Boolean,
    /** 0-1 while partly watched. */
    val progress: Double?,
    /** Play's target: the on-deck episode, highlighted and focused first. */
    val onDeck: Boolean,
    /** The row's leading download icon (online only); null when the episode isn't downloaded. */
    val download: EpisodeDownloadUi? = null,
)

/**
 * An episode's download as its row shows it: a spinner while it is being queued, else its [status] icon; [label] says
 * it to screen readers.
 */
data class EpisodeDownloadUi(
    val status: DownloadedMediaStatus?,
    /** 0-1 while downloading. */
    val progress: Float?,
    val queueing: Boolean,
) {
    /** The download's state in words ("Downloading…, 40%"); null when there is none to say. */
    val label: String?
        get() = if (queueing) {
            T.downloads.queuedTooltip
        } else {
            when (status) {
                DownloadedMediaStatus.QUEUED -> T.downloads.queuedTooltip
                DownloadedMediaStatus.DOWNLOADING -> listOfNotNull(
                    T.downloads.downloadingTooltip,
                    progress?.let { T.downloads.notification.progress(percent = (it * 100).roundToInt().toString()) },
                ).joinToString(", ")
                DownloadedMediaStatus.PAUSED -> T.downloads.notificationPaused
                DownloadedMediaStatus.FAILED -> T.downloads.errorDownloadFailed
                DownloadedMediaStatus.CANCELLED -> T.downloads.cancelledDownload
                DownloadedMediaStatus.PARTIAL -> T.downloads.partiallyDownloaded
                DownloadedMediaStatus.COMPLETED -> T.downloads.notificationComplete
                null -> null
            }
        }
}

data class CastUi(
    val personId: String?,
    val name: String,
    /** The character played. */
    val role: String?,
    val image: Artwork?,
)

data class InfoRowUi(val label: String, val value: String)
