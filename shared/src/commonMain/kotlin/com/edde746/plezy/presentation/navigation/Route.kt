package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.TrackerService

/**
 * The screens of the running app, as back-stack entries ([PlezyNavigator]). Plain values: a screen's store is built
 * from them (and the app state), never carried in them, so a route can be compared, logged and restored.
 *
 * A route is drawn as a screen of its own or as a sheet over the entry below it ([presentation]; [BackStackLayout]
 * tells the UIs which entry is which).
 */
sealed interface Route {
    /** How the UIs present this route when it is the top entry with another entry below it. */
    val presentation: RoutePresentation get() = RoutePresentation.SCREEN

    /** Home: Continue Watching and the servers' hubs. */
    data object Home : Route

    /** Libraries: the servers' libraries and their items, and this device's downloads ([LibrarySection]). */
    data object Libraries : Route

    /** Live TV: the servers' channels and guide, pushed over Home from its Live TV shortcut. */
    data object LiveTv : Route

    /** A show's upcoming airings on the Live TV server [serverId], from What's On. */
    data class LiveTvShowSchedule(val showTitle: String, val serverId: String) : Route

    /** Explore: the catalog sources' rows. */
    data object Explore : Route

    /** Search across the servers. */
    data object Search : Route

    /** The active sync rules, pushed from the downloads. */
    data object SyncRules : Route

    /** Settings. */
    data object Settings : Route

    /** Settings > Services: the trackers' rows. */
    data object Services : Route

    /** A connected tracker's settings, under Services. */
    data class TrackerSettings(val service: TrackerService) : Route

    /** A tracker's library filter, under its settings. */
    data class TrackerLibraryFilter(val service: TrackerService) : Route
    /** Watch Together: create or join a room, and the room ([com.edde746.plezy.app.AppSession.watchTogether]). */
    data object WatchTogether : Route

    /** A settings page pushed over the hub ([com.edde746.plezy.presentation.settings.SettingsPageId]); [arg] its subject. */
    data class SettingsPage(val page: com.edde746.plezy.presentation.settings.SettingsPageId, val arg: String? = null) : Route

    /** The player, over the app's current playback. */
    data object Player : Route

    /** The first sign-in: Plex, or a Jellyfin or Emby server. The app's only screen until an account is added. */
    data object SignIn : Route

    /**
     * The profile picker; [required]: a profile must be picked (at launch, after sign-in), back leaves the app. [manage]:
     * opened to manage the profiles (Settings' and the profile menu's Manage profiles), titled for that.
     */
    data class ProfilePicker(val required: Boolean, val manage: Boolean = false) : Route

    /** A new local profile: its name and optional PIN, then its first connection. */
    data object AddProfile : Route

    /** A profile's name, PIN and connections. */
    data class ProfileDetail(val profileId: String) : Route

    /** The ways to add a connection, to profile [profileId] or (null) the active one. */
    data class AddConnection(val profileId: String?) : Route

    /** Plex PIN sign-in that adds an account, to profile [profileId] or (null) the device. */
    data class AddPlexAccount(val profileId: String?) : Route

    /**
     * A Jellyfin or Emby server and user, for profile [profileId] or (null) the active one. With [url] (and [username]):
     * signing in again to that server, whose session expired: the server is probed at once and only the password is asked.
     */
    data class AddMediaBrowser(val dialect: MediaBrowserDialect, val profileId: String?, val url: String? = null, val username: String? = null) : Route

    /** A Jellyfin or Emby connection's URLs. */
    data class EditConnection(val connectionId: String) : Route

    /** Another profile's connection borrowed into profile [profileId]. */
    data class BorrowConnection(val profileId: String) : Route

    /** The music player: the current track, its transport, lyrics and queue, over the music session. */
    data object NowPlaying : Route

    /** A music artist: the portrait, bio and discography. */
    data class MusicArtist(val serverId: String, val id: String) : Route

    /** A music album: the cover and its tracks by disc. */
    data class MusicAlbum(val serverId: String, val id: String) : Route

    /** An audio playlist and its tracks. */
    data class MusicPlaylist(val serverId: String, val id: String) : Route

    /**
     * A server item's detail: a movie, show, season or episode. [initialSeasonId] selects that season and
     * [initialEpisodeId] focuses that episode (a deep link, a hub's episode). [seed] is what the card it was opened from
     * knew of the item: shown when the server's fetch fails or finds nothing.
     */
    data class MediaDetail(
        val serverId: ServerId,
        val itemId: String,
        val initialSeasonId: String? = null,
        val initialEpisodeId: String? = null,
        /** Opened from the downloads: everything comes from them, nothing from the server. */
        val offline: Boolean = false,
    ) : Route {
        /**
         * The card's item of [itemId], if it was opened from one ([seeded]); none for a deep link. Not part of the
         * route's identity: an equal route without it is the same screen.
         */
        var seed: MediaItem? = null
            private set

        /** This route carrying [item] as its seed when [item] is the route's own item, else as it is. */
        fun seeded(item: MediaItem): MediaDetail = copy().also { it.seed = item.takeIf { item.id == itemId } }
    }

    /** A person's titles on one server: an actor from a cast strip or a search result. */
    data class Person(
        val serverId: ServerId,
        val personId: String,
        val name: String,
        val thumbPath: String? = null,
        /** The character they play in the title they were opened from. */
        val characterName: String? = null,
    ) : Route

    /** A server collection's items; [offline]: its downloads folder (opened from the downloads), its downloaded titles alone. */
    data class CollectionDetail(val serverId: ServerId, val collectionId: String, val offline: Boolean = false) : Route

    /** A catalog title's detail, opened from Explore, a catalog search or another title's detail. */
    data class CatalogDetail(val item: CatalogItem) : Route {
        override fun toString(): String = "CatalogDetail(${item.source.id}/${item.entryIdentityKey})"
    }

    /** The full-screen search of the catalog source [source]. */
    data class CatalogSearch(val source: CatalogSourceId) : Route

    /** The View All grid of the Explore shelf [hubId] ([com.edde746.plezy.model.MediaHub.id]), titled [title]. */
    data class ExploreRow(val hubId: String, val title: String) : Route

    /** Connecting the profile's Seerr account. */
    data object SeerrConnect : Route

    /** The profile's Seerr account: its instance, user and disconnect. */
    data object SeerrSettings : Route

    /** Requesting the TMDB title [tmdbId] from Seerr, over the screen it was asked from. */
    data class SeerrRequest(val tmdbId: Int, val kind: MediaKind, val title: String) : Route {
        override val presentation: RoutePresentation get() = RoutePresentation.SHEET
    }

    /**
     * A person's Seerr page, opened from a Seerr title's cast: [personId] TMDB's, [name] and [imageUrl] what the cast
     * entry showed, until Seerr's answer replaces them.
     */
    data class SeerrPerson(val personId: Int, val name: String, val imageUrl: String? = null) : Route

    /** The metadata editor of a server's movie, show, season or episode. */
    data class MetadataEdit(val serverId: ServerId, val itemId: String) : Route

    /**
     * Plex's match search for a movie or show, prefilled with its [title] and [year]; [matched] titles it "Fix Match…",
     * else "Match…".
     */
    data class PlexMatch(val serverId: ServerId, val itemId: String, val title: String, val year: Int?, val matched: Boolean) : Route

    // Home.

    /** A hub's View all: [hubId] is its row's id on Home ([com.edde746.plezy.presentation.browse.HubUi.id]). */
    data class HubDetail(val hubId: String, val title: String) : Route

    // Libraries.

    /** A server playlist's items. */
    data class PlaylistDetail(val serverId: ServerId, val playlistId: String) : Route
}

/**
 * The screen a playlist opens, wherever it is picked: an audio playlist ([playlistType] `audio`) the music playlist page,
 * any other (video, photo, or a playlist its server doesn't type) the playlist screen.
 */
fun playlistRoute(serverId: ServerId, playlistId: String, playlistType: String?): Route =
    if (playlistType == "audio") Route.MusicPlaylist(serverId.value, playlistId) else Route.PlaylistDetail(serverId, playlistId)

/** How a route is drawn ([Route.presentation]). */
enum class RoutePresentation {
    /** A screen of its own, in the navigation container. */
    SCREEN,

    /**
     * A sheet over the entry below it (Compose `PlezySheet`: a bottom sheet, a side panel on TV; Apple `.sheet`),
     * which stays drawn underneath. Back closes it.
     */
    SHEET,
}

/**
 * A back stack as the UIs draw it: [screens] in the navigation container (bottom to top, the last one on screen) and
 * the [sheet] over the last of them, if any. Only the top entry can be a sheet, and only with an entry below it: a
 * sheet route alone on the stack (a development session opened on Streams) is drawn as a screen. [overPlayer] is the
 * required profile picker pushed over the player (a return to the app that asks for a profile): it covers the player,
 * which stays up, paused, under it, its video surface kept.
 */
data class BackStackLayout(val screens: List<Route>, val sheet: Route?, val overPlayer: Route? = null) {
    companion object {
        fun of(backStack: List<Route>): BackStackLayout {
            val top = backStack.lastOrNull()
            return when {
                top != null && backStack.size > 1 && top.presentation == RoutePresentation.SHEET -> BackStackLayout(backStack.dropLast(1), top)
                top == Route.ProfilePicker(required = true) && backStack.getOrNull(backStack.size - 2) == Route.Player ->
                    BackStackLayout(backStack.dropLast(1), null, top)
                else -> BackStackLayout(backStack, null)
            }
        }
    }
}

/**
 * A top-level destination of the navigation bar, rail or sidebar, in display order. Each UI picks its own icon.
 * [NavigationTabs] says which show. Live TV is a screen pushed over Home ([Startup.LIVE_TV]) and the downloads a section
 * of Libraries ([LibrarySection.DOWNLOADS]).
 */
enum class TopLevelDestination(
    val route: Route,
    /** Shown only while online: offline, only Libraries (on its downloads) and Settings show. */
    val onlineOnly: Boolean,
) {
    HOME(Route.Home, onlineOnly = true),
    LIBRARIES(Route.Libraries, onlineOnly = false),
    EXPLORE(Route.Explore, onlineOnly = true),
    SEARCH(Route.Search, onlineOnly = true),
    SETTINGS(Route.Settings, onlineOnly = false),
    ;

    /** The destination's name. */
    val label: String
        get() = when (this) {
            HOME -> T.common.home
            LIBRARIES -> T.navigation.libraries
            EXPLORE -> T.navigation.explore
            SEARCH -> T.common.search
            SETTINGS -> T.common.settings
        }

    companion object {
        /** The destination [route] is, or null for a screen below the top level. */
        fun of(route: Route): TopLevelDestination? = entries.firstOrNull { it.route == route }

        /**
         * The destination the chrome selects for [backStack], a destination's stack: the one at its bottom; null for a
         * stack without one (a development session started on another screen), which shows without the chrome.
         */
        fun selectedIn(backStack: List<Route>): TopLevelDestination? = backStack.firstOrNull()?.let(::of)

        /**
         * The destination the chrome highlights over [screens], a destination's stack (bottom to top), among [shown]:
         * the one the top-most screen belonging to a shown destination belongs to ([owner]), wherever it was pushed
         * from: an artist opened from Home highlights Libraries. Null for a stack without one.
         */
        fun highlightedIn(screens: List<Route>, shown: List<TopLevelDestination>): TopLevelDestination? =
            screens.asReversed().firstNotNullOfOrNull { route -> owner(route)?.takeIf { it in shown } }

        /**
         * The library Libraries stands for over [screens] where it is the destination highlighted ([highlightedIn]): that
         * of the top-most of its screens whose library is known, walking down to the first screen of another
         * destination. A screen's library is the one [placed] names for it ([NavigationStacks.libraries]: the library an
         * item was opened under, else the one it belongs to), for an artist, album or audio playlist else its server's
         * first music library, and for Libraries itself its [selected] one; each found in [libraries]. Null where another
         * destination is highlighted or no library is known: the generic Libraries.
         */
        fun highlightedLibrary(
            screens: List<Route>,
            shown: List<TopLevelDestination>,
            libraries: List<MediaLibrary>,
            placed: Map<Route, String>,
            selected: MediaLibrary?,
        ): MediaLibrary? {
            val owned = screens.filter { route -> owner(route)?.let { it in shown } == true }
            for (route in owned.asReversed()) {
                if (owner(route) != LIBRARIES) return null
                val music = when (route) {
                    is Route.MusicArtist -> route.serverId
                    is Route.MusicAlbum -> route.serverId
                    is Route.MusicPlaylist -> route.serverId
                    else -> null
                }
                val library = placed[route]?.let { key -> libraries.firstOrNull { it.globalKey == key } }
                    ?: music?.let { serverId -> libraries.firstOrNull { it.kind == MediaKind.ARTIST && it.serverId == serverId } }
                    ?: selected.takeIf { route == Route.Libraries }
                if (library != null) return library
            }
            return null
        }

        /**
         * The destination [route] belongs to: a destination itself; a server's titles, people, collections, playlists
         * and music, their editors and the downloads' sync rules, Libraries; Live TV and Home's View all, Home; the
         * catalog's titles, people, rows and search, Explore; profiles, connections, services and settings pages, Settings.
         * Null for a screen of no destination (sign-in, a required profile pick, the players, Watch Together, a sheet),
         * which leaves the highlight to the screen under it.
         */
        fun owner(route: Route): TopLevelDestination? = when (route) {
            Route.Home, Route.LiveTv, is Route.LiveTvShowSchedule, is Route.HubDetail -> HOME
            Route.Libraries, Route.SyncRules, is Route.MediaDetail, is Route.Person, is Route.CollectionDetail,
            is Route.PlaylistDetail, is Route.MusicArtist, is Route.MusicAlbum, is Route.MusicPlaylist,
            is Route.MetadataEdit, is Route.PlexMatch,
            -> LIBRARIES
            Route.Explore, is Route.CatalogDetail, is Route.CatalogSearch, is Route.ExploreRow, is Route.SeerrPerson -> EXPLORE
            Route.Search -> SEARCH
            Route.Settings, is Route.SettingsPage, Route.Services, is Route.TrackerSettings, is Route.TrackerLibraryFilter,
            Route.SeerrConnect, Route.SeerrSettings, Route.AddProfile, is Route.ProfileDetail, is Route.AddConnection,
            is Route.AddPlexAccount, is Route.AddMediaBrowser, is Route.EditConnection, is Route.BorrowConnection,
            -> SETTINGS
            is Route.ProfilePicker -> if (route.required) null else SETTINGS
            Route.SignIn, Route.Player, Route.NowPlaying, Route.WatchTogether, is Route.SeerrRequest -> null
        }
    }
}

/**
 * The sections of Libraries: the servers' libraries, and what this device keeps for offline viewing (never on the Apple
 * TV, which keeps no files). Offline, Libraries shows only the downloads.
 */
enum class LibrarySection {
    LIBRARY,
    DOWNLOADS,
}

/**
 * Where the app opens: [destination] at its root, with [screen] over it (Live TV over Home), Libraries on [section].
 */
data class Startup(val destination: TopLevelDestination, val screen: Route? = null, val section: LibrarySection? = null) {
    /** Its name in the startup choice: Live TV's, the downloads', else the destination's. */
    val label: String
        get() = when {
            screen == Route.LiveTv -> T.navigation.liveTv
            section == LibrarySection.DOWNLOADS -> T.navigation.downloads
            else -> destination.label
        }

    companion object {
        /** Live TV, pushed over Home. */
        val LIVE_TV = Startup(TopLevelDestination.HOME, screen = Route.LiveTv)

        /** The downloads, Libraries' section. */
        val DOWNLOADS = Startup(TopLevelDestination.LIBRARIES, section = LibrarySection.DOWNLOADS)
    }
}
