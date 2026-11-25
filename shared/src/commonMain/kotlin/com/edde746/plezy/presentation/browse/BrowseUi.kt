package com.edde746.plezy.presentation.browse

import com.edde746.plezy.image.Artwork
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route

/**
 * One media item as a card shows it: in a hub row, a grid, a list, the home hero and the TV spotlight. What it shows is
 * decided before it gets here (the caption, which watch badge, the shape for the episode poster setting); the UIs only
 * draw it.
 */
data class MediaCardUi(
    /** Unique among the items of a screen. */
    val id: String,
    val title: String,
    /** The line under the title (a year, "S1 E4 · Title", an artist); null keeps the line empty. */
    val caption: String?,
    val shape: CardShape,
    /** What the card shows without artwork, or once it failed; its [PlaceholderKind.circular] draws the card round. */
    val placeholder: PlaceholderKind,
    /** The card's artwork, at the shape's aspect. */
    val artwork: Artwork?,
    /**
     * What the card shows once [artwork] fails (a track's album cover, a season's show poster); null for wide art, which
     * never falls back. A failed [artwork] is remembered ([FailedArtwork]), so the next card goes straight here.
     */
    val fallbackArtwork: Artwork? = null,
    /** The artwork is blurred past recognition: an unwatched episode's own thumbnail under `hide_spoilers`. */
    val blurred: Boolean = false,
    /** The item's backgrounds, which the hero and the TV spotlight cycle through. */
    val backdrops: List<Artwork> = emptyList(),
    /** The item's clear logo, which the hero and the spotlight show in place of the title. */
    val logo: Artwork? = null,
    val summary: String? = null,
    /** The hero's and spotlight's metadata line ("TV Show • ★ 8.4 • TV-MA • 2019"). */
    val metadata: String? = null,
    /** Watched: the check badge. */
    val watched: Boolean = false,
    /** The playback progress, 0–1, while it is partly watched: the bar at the artwork's foot. */
    val progress: Double? = null,
    /** A show's or season's unwatched episodes: the count badge, none at 0. */
    val unwatchedCount: Int = 0,
    /** The minutes left to watch, for the hero's play button ("N min left"). */
    val minutesLeft: Int? = null,
    /**
     * The badges down the artwork's top start corner: the media's quality ("4K", "DV", "TrueHD Atmos"), or a catalog
     * title's availability, rank and audience ([com.edde746.plezy.presentation.explore.catalogBadges]).
     */
    val qualityLabels: List<String> = emptyList(),
    /**
     * The short forms of [qualityLabels] entries (a catalog title's status: ✓ for "Available", "2/3" for "2/3 seasons"),
     * keyed by label: what a poster too narrow for the words shows instead of cutting them. A label without one is left
     * out on such a poster.
     */
    val badgeShortForms: Map<String, BadgeShortForm> = emptyMap(),
    /** The TV spotlight's tint behind this item, `0xAARRGGBB` (a catalog title's accent colour); null for none. */
    val accentColor: Long? = null,
    /** A line after the spotlight's metadata (a catalog title's next episode: "Ep 5 in 2d 3h"). */
    val spotlightNote: String? = null,
    /**
     * The detail a pointer click on the title opens (an episode's or season's show, a movie's own); null: the title is
     * plain text. Pointer only: a remote or keyboard opens the card itself.
     */
    val titleLink: Route? = null,
    /** The leading part of the caption (and of the list subtitle) a pointer click opens: an episode's "S2". */
    val captionLink: CardLink? = null,
    /** The list view's metadata line: "PG-13 • 2006 • Director's Cut • 2h 10m • 7.7★ • Studio"; null for none. */
    val listMetadata: String? = null,
    /** The list view's line under the metadata: "S1 E4 · Title", an artist, a subtitle; null for none. */
    val listSubtitle: String? = null,
    /** An episode's or season's series ([com.edde746.plezy.model.MediaItem.seriesGlobalKey]), which [followFocus] follows. */
    val seriesKey: String? = null,
) {
    /** [unwatchedCount] as the badge shows it: at most "999+". */
    val unwatchedLabel: String? get() = unwatchedLabel(unwatchedCount)

    companion object {
        /** A count badge's text: the count, "999+" past 999, none at 0. */
        fun unwatchedLabel(count: Int): String? = when {
            count <= 0 -> null
            count > 999 -> "999+"
            else -> count.toString()
        }
    }
}

/** A link in a card's text: its first [prefix] characters open [route] on a pointer click. */
data class CardLink(val prefix: String, val route: Route)

/** A badge's short form ([MediaCardUi.badgeShortForms]): an [icon], else a short [text] ("4K", "2/3"). */
data class BadgeShortForm(val icon: BadgeIcon? = null, val text: String? = null)

/** The mark a status badge's short form shows. */
enum class BadgeIcon {
    /** On the server: a check. */
    AVAILABLE,

    /** Partly on the server: a half-filled circle. */
    PARTIAL,

    /** Requested, pending approval or processing: a clock. */
    REQUESTED,

    /** A declined or failed request: a no-entry mark. */
    DECLINED,
}

/** A row of cards under a title: a server's hub, Continue Watching, a catalog row. */
data class HubUi(
    val id: String,
    val title: String,
    val items: List<MediaCardUi>,
    /** The shape the row's cards share ([com.edde746.plezy.presentation.layout.hubShape]). */
    val shape: CardShape,
    /** The hub has more than it shows: a View all at its end. */
    val more: Boolean = false,
    /** The hub is Continue Watching (On Deck), whatever its title. */
    val continueWatching: Boolean = false,
    /** The hub's server, shown after its title (`show_server_name_on_hubs`, or hubs of several servers). */
    val serverName: String? = null,
    /** The icon before the hub's title: by default [HubIcon.of] its title; an Explore shelf names its own. */
    val icon: HubIcon = HubIcon.of(title, continueWatching),
    /** The provider's count of the whole result set, after the title ("347 results"); null when it reports none. */
    val totalResults: String? = null,
)

/** Where a screen's content stands. */
enum class LoadState {
    /** Loading, nothing to show yet: skeletons. */
    LOADING,

    /** Loaded, with content. */
    CONTENT,

    /** Loaded, nothing there: the empty state. */
    EMPTY,

    /** Failed, nothing to show: the error state with Retry. */
    ERROR,
}
