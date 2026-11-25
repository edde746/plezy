package com.edde746.plezy.presentation.homescreen

import com.edde746.plezy.links.ShelfContentId
import com.edde746.plezy.model.MediaKind

/**
 * The TV's home screen outside the app ([com.edde746.plezy.app.AppPlatform.homeScreen]): Android TV's Watch Next row,
 * the Apple TV's Top Shelf, both showing the active profile's Continue Watching ([SystemShelf]). What was published
 * last stays while the app isn't running.
 *
 * Posters: the app downloads each item's [HomeScreenItem.posterSource] itself and hands the home screen only the image
 * (Android: a file behind a non-exported content provider, read through per-URI grants to the launchers; tvOS: a file
 * in the App Group's container). The source URL carries the media server's credentials, so it never leaves the app:
 * no launcher, extension or shared container sees a server address or a token, and the Top Shelf extension makes no
 * network call.
 */
interface HomeScreen {
    /** The poster shape this home screen draws ([SystemShelf] picks each item's artwork for it). */
    val artwork: HomeScreenArtwork

    /**
     * Shows [shelf] in place of what was published before. A [HomeScreenShelf.generation] lower than the last one
     * published, or the same generation with another owner, is stale and ignored. Main thread; returns at once: the
     * work (posters included) runs in the background, and shelves that pile up meanwhile collapse into the latest.
     */
    fun publish(shelf: HomeScreenShelf)
}

/** The artwork a home screen draws. */
enum class HomeScreenArtwork {
    /** 16:9 at 640×360: an episode's thumbnail (spoiler-safe art when Hide Spoilers asks), a movie's poster image. */
    LANDSCAPE,

    /** 2:3 at 600×900: the series poster for an episode (the season's under the season-poster setting), a movie's poster. */
    POSTER,
}

/**
 * What a home screen shows: the Continue Watching of profile [ownerId] (newest first, at most [HOME_SCREEN_LIMIT]),
 * under [sectionTitle] in the interface language. [ownerId] null: nothing (no profile, signed out, between two
 * profiles): every row and poster of an earlier owner goes. [generation] grows with every change of owner, so work
 * queued for an earlier owner can't land after a later one's.
 */
data class HomeScreenShelf(val ownerId: String?, val generation: Long, val sectionTitle: String, val items: List<HomeScreenItem>)

/**
 * One Continue Watching item as a TV's home screen shows it. Times are milliseconds, instants epoch milliseconds.
 *
 * @param contentId `plezy_<serverId>_<itemId>` ([ShelfContentId]): the row's id, opened by [playUrl].
 * @param title the show's name for an episode, else the item's title.
 * @param episodeTitle the episode's own title; null for anything but an episode of a show.
 * @param posterSource where the app downloads the poster from: a media server URL with its credentials, for the app's
 *   own request only (see [HomeScreen]); null for none.
 * @param positionMillis where Play resumes it; 0 when it starts from the beginning (up next).
 * @param durationMillis the video's length; 0 when unknown.
 * @param lastEngagedMillis when it was last watched, else when it was published.
 */
data class HomeScreenItem(
    val contentId: String,
    val kind: MediaKind,
    val title: String,
    val episodeTitle: String?,
    val description: String?,
    val posterSource: String?,
    val durationMillis: Long,
    val positionMillis: Long,
    val lastEngagedMillis: Long,
    val seriesTitle: String?,
    val seasonNumber: Int?,
    val episodeNumber: Int?,
) {
    /** What selecting the item opens: `plezy://play?content_id=<contentId>`. */
    val playUrl: String get() = ShelfContentId.playUrl(contentId)

    val isEpisode: Boolean get() = kind == MediaKind.EPISODE
}

/** How many items a home screen gets: one row's worth, as Android TV's Watch Next and the Top Shelf show. */
const val HOME_SCREEN_LIMIT: Int = 20
