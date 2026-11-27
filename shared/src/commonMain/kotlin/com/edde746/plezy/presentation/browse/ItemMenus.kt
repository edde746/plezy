package com.edde746.plezy.presentation.browse

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.presentation.detail.serverItemLink
import com.edde746.plezy.presentation.player.PlayerStates
import com.edde746.plezy.profiles.PlexHomeProfile
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.strings.T

/** What a menu acts on: a media item (a movie, a show, an episode, a collection, …) or a playlist. */
sealed interface MenuTarget {
    val serverId: String?
    val title: String

    data class Item(val item: MediaItem) : MenuTarget {
        override val serverId: String? get() = item.serverId
        override val title: String get() = item.displayTitle
    }

    data class Playlist(val playlist: MediaPlaylist) : MenuTarget {
        override val serverId: String? get() = playlist.serverId
        override val title: String get() = playlist.title
    }
}

/**
 * Where a menu opens, which changes what it offers: [continueWatching] a Continue Watching card; [collectionId] a card
 * inside that collection; [seriesId] a card on that show's own detail screen (no Go to series to it); [albumId] /
 * [artistId] a card on that album's or artist's screen (no Go to album / artist to it).
 */
data class MenuPlace(
    val continueWatching: Boolean = false,
    val collectionId: String? = null,
    val seriesId: String? = null,
    val albumId: String? = null,
    val artistId: String? = null,
)

/** A menu entry's icon; each UI draws its own glyph for it. */
enum class MenuIcon {
    PLAY, TRAILER, SHUFFLE, REPLAY, WATCHED, UNWATCHED, CLOSE, INFO, STAR, EDIT, LABEL, SEARCH, LINK_OFF, REMOVE, TV, LINK,
    VIDEO_FILE, OPEN_IN_NEW, DOWNLOAD, SYNC, SYNC_DISABLED, DELETE, DELETE_FOREVER, BOOKMARK_ADD, BOOKMARK_REMOVE, ADD,
    PLAYLIST, COLLECTION, SMART_PLAYLIST, PLAY_NEXT, QUEUE, INSTANT_MIX, ALBUM, ARTIST, ERROR, TIMER, ARROW_UP, ARROW_DOWN,
}

/**
 * One entry of an item's menu: [id] is what [MediaMenu.select] takes (and the harness's `menu.<id>`), [icon] its symbol
 * (none for a choice among like entries: a version, a quality), [selected] the choice in effect among them, checked. An
 * entry with [children] is a submenu where the UI has them (the Apple menus): a pick selects one of them by its own id;
 * a UI without submenus selects the entry itself, which asks the same choice in a prompt.
 */
data class MenuEntry(
    val id: String,
    val label: String,
    val icon: MenuIcon?,
    val destructive: Boolean = false,
    val children: List<MenuEntry> = emptyList(),
    val selected: Boolean = false,
)

/** An open menu: [title] names exactly what its [entries] act on (the episode, not its show). */
data class ItemMenu(val title: String, val entries: List<MenuEntry>)

/**
 * Where a [MenuEntryProvider]'s entries go in an item's menu, in menu order: music actions first; Rate after Mark as
 * Watched and the watchlist after Rate; downloads before Add to…; metadata edits (Edit, Quick Tag, Match) after the file
 * entries. A playlist's or collection's download entries go in [LIST_DOWNLOADS], between Shuffle and Delete.
 */
enum class MenuSlot { MUSIC, RATE, METADATA, DOWNLOADS, WATCHLIST, LIST_DOWNLOADS }

/**
 * Entries another feature adds to the menus (downloads, the watchlist, music, ratings, metadata edits): [entries] for a
 * target in its [slot] (none when it offers nothing there), [perform] runs one it offered and returns the message to
 * show, or null. Entry ids are the provider's own and must not repeat the menu's (`download`, `toggle_watchlist`, …).
 */
interface MenuEntryProvider {
    val slot: MenuSlot

    /** [target]'s entries from what is at hand, at once: a menu peeked as its item shows ([MediaMenu.peek]) reads them. */
    fun entries(target: MenuTarget, place: MenuPlace): List<MenuEntry>

    /**
     * Fetches what the next [entries] for [target] should know (the watchlist's membership), as its item gains focus,
     * is pressed or comes under the pointer ([MediaMenu.warm]).
     */
    fun warm(target: MenuTarget) {}

    /**
     * Fetches, once for every menu that needs it (shared loads, kept for the session), what [target]'s menu should know
     * (the watchlists' membership): as its menu is first peeked ([MediaMenu.peek]), and as it opens. True when it learnt
     * something the menu's entries may now show; the peeked menus are then read again, and the open menu shows it.
     */
    suspend fun warmAhead(target: MenuTarget): Boolean = false

    suspend fun perform(target: MenuTarget, place: MenuPlace, entryId: String): MenuMessage?
}

/**
 * A caller's own entry, appended last (the now-playing screen's Sleep timer), or first when [leading] (the detail's
 * Play from beginning for a show or season): [run] when picked.
 */
class MenuExtra(val id: String, val label: String, val icon: MenuIcon, val leading: Boolean = false, val run: () -> Unit)

/** What an item's menu knows about the user and the item's server when it opens. */
data class MenuGates(
    /** Admin actions are allowed ([isAdminActionAllowed]). */
    val isAdmin: Boolean = false,
    /** The server can transcode video. */
    val canTranscode: Boolean = false,
    /** The item's server answers now (capabilities stay set while it doesn't). */
    val serverOnline: Boolean = false,
    /** The server can take an item off Continue Watching. */
    val canRemoveFromContinueWatching: Boolean = false,
    /** Delete from server is allowed for this item ([isMediaDeletionAllowed]). */
    val canDeleteFromServer: Boolean = false,
    /** This device opens videos in other player apps. */
    val externalPlayers: Boolean = false,
    /** The version Play plays (an index of the item's versions), which Play Version checks. */
    val version: Int = 0,
    /** The quality Play plays at, which Play Version checks. */
    val quality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
)

/**
 * Whether admin actions are allowed on an item: the user owns or administers its server, unless the item is a Plex
 * one and the active profile is a Plex Home user who is not its admin.
 */
fun isAdminActionAllowed(isOwnerOrAdmin: Boolean, backend: BackendKind?, activeProfile: Profile?): Boolean {
    val blockedByPlexHomeRole = backend == BackendKind.PLEX && activeProfile is PlexHomeProfile && !activeProfile.plexAdmin
    return isOwnerOrAdmin && !blockedByPlexHomeRole
}

/**
 * Whether Delete from server may be offered. Jellyfin and Emby: only the server's own answer for the item
 * ([itemPermission]; the admin bit says nothing about deletion there), unknown counting as no. Plex: the admin gate (only
 * the owning account may delete) and the server's Allow media deletion switch ([itemPermission]), which Plex doesn't
 * enforce itself; unknown counting as no. An item of no backend: never.
 */
fun isMediaDeletionAllowed(backend: BackendKind?, itemPermission: Boolean?, adminActionAllowed: Boolean): Boolean = when (backend) {
    null -> false
    BackendKind.PLEX -> adminActionAllowed && itemPermission == true
    else -> itemPermission == true
}

/** The kinds Delete from server applies to. */
internal val MediaKind.isServerDeletable: Boolean
    get() = this == MediaKind.EPISODE || this == MediaKind.MOVIE || this == MediaKind.SHOW || this == MediaKind.SEASON

/**
 * The menu's title: the item it acts on alone, without its show or season ("Season 1", an episode's own title), or the
 * playlist. Its show's name when the item has no title.
 */
internal fun MenuTarget.menuTitle(): String = when (this) {
    is MenuTarget.Item -> item.title.takeUnless { it.isNullOrEmpty() } ?: item.displayTitle
    is MenuTarget.Playlist -> playlist.title
}

/**
 * The buttons a page header's action row can show (a detail's, an album's): its ⋯ menu leaves out the entries of those
 * it shows ([itemMenuEntries]' `onRow`), which the row offers already. [PLAY] and [INSTANT_MIX] are music's.
 */
enum class RowAction { PLAY, VERSIONS, TRAILER, SHUFFLE, INSTANT_MIX, DOWNLOAD, WATCHED, WATCHLIST }

/** The music actions' menu entries ([MenuSlot.MUSIC]) a row's [RowAction] stands for. */
private val musicRowEntries = mapOf(RowAction.PLAY to "music_play", RowAction.INSTANT_MIX to "music_instant_mix")

/**
 * A single item's entries, in order: [provided] music actions; Play from beginning, Mark as Watched / Unwatched
 * (Played / Unplayed for music), Rate, watchlist, Remove from Continue Watching; Go to series, View details, Shuffle
 * Play, Play trailer (only with [trailer]: the detail screen passes it); downloads, Add to… (a submenu of Playlist and
 * Collection where both may be added to), Remove from collection; Play Version (a submenu of the versions and qualities
 * where the item's versions are known: [playVersionChoices]), Play in External Player, File Info, Show link; metadata
 * edits; Delete from server. The entries of the buttons in [onRow] are left out: the detail's row shows them. Its
 * watched toggle does one of the two (Mark as Unwatched once the item is watched, else Mark as Watched): a partly
 * watched item keeps the other.
 */
internal fun itemMenuEntries(
    item: MediaItem,
    place: MenuPlace,
    gates: MenuGates,
    provided: Map<MenuSlot, List<MenuEntry>>,
    trailer: Boolean = false,
    onRow: Set<RowAction> = emptySet(),
): List<MenuEntry> {
    val kind = item.kind
    val movieOrEpisode = kind == MediaKind.MOVIE || kind == MediaKind.EPISODE
    val partial = item.isPartiallyWatched
    val activeProgress = movieOrEpisode && item.hasActiveProgress
    val video = item.isVideoContent
    val seriesKey = if (kind == MediaKind.EPISODE) item.grandparentId else item.parentId
    val canManageCollections = item.backend == BackendKind.PLEX || gates.isAdmin
    val hasVersionChoice = item.mediaVersions.orEmpty().size > 1
    val menu = T.mediaMenu
    return buildList {
        if (kind.isMusic) {
            val shown = onRow.mapNotNull(musicRowEntries::get)
            addAll(provided[MenuSlot.MUSIC].orEmpty().filter { it.id !in shown })
        }
        if (activeProgress) add(MenuEntry(PLAY_FROM_BEGINNING, menu.playFromBeginning, MenuIcon.REPLAY))
        if (kind != MediaKind.PHOTO) {
            val music = kind.isMusic
            val toggle = if (RowAction.WATCHED !in onRow) null else if (item.isWatched) UNWATCH else WATCH
            if (toggle != WATCH && (!item.isWatched || partial || activeProgress)) {
                add(MenuEntry(WATCH, if (music) menu.markAsPlayed else menu.markAsWatched, MenuIcon.WATCHED))
            }
            if (toggle != UNWATCH && (item.isWatched || partial || activeProgress)) {
                add(MenuEntry(UNWATCH, if (music) menu.markAsUnplayed else menu.markAsUnwatched, MenuIcon.UNWATCHED))
            }
        }
        if (video) addAll(provided[MenuSlot.RATE].orEmpty())
        if (RowAction.WATCHLIST !in onRow) addAll(provided[MenuSlot.WATCHLIST].orEmpty())
        if (place.continueWatching && gates.canRemoveFromContinueWatching) {
            add(MenuEntry(REMOVE_FROM_CONTINUE_WATCHING, menu.removeFromContinueWatching, MenuIcon.CLOSE))
        }
        if ((kind == MediaKind.EPISODE || kind == MediaKind.SEASON) && seriesKey != null && !place.continueWatching && place.seriesId != seriesKey) {
            add(MenuEntry(SERIES, menu.goToSeries, MenuIcon.TV))
        }
        if (place.continueWatching && video) add(MenuEntry(DETAILS, menu.viewDetails, MenuIcon.INFO))
        if ((kind == MediaKind.SHOW || kind == MediaKind.SEASON) && RowAction.SHUFFLE !in onRow) add(MenuEntry(SHUFFLE_PLAY, menu.shufflePlay, MenuIcon.SHUFFLE))
        if (trailer && RowAction.TRAILER !in onRow) add(MenuEntry(PLAY_TRAILER, T.tooltips.playTrailer, MenuIcon.TRAILER))
        if (RowAction.DOWNLOAD !in onRow) addAll(provided[MenuSlot.DOWNLOADS].orEmpty())
        if (video) {
            val targets = if (canManageCollections) {
                listOf(
                    MenuEntry(ADD_TO_PLAYLIST, T.playlists.playlist, MenuIcon.PLAYLIST),
                    MenuEntry(ADD_TO_COLLECTION, T.collections.collection, MenuIcon.COLLECTION),
                )
            } else {
                emptyList()
            }
            add(MenuEntry(ADD_TO, T.common.addTo, MenuIcon.ADD, children = targets))
        }
        if (place.collectionId != null && canManageCollections) {
            add(MenuEntry(REMOVE_FROM_COLLECTION, T.collections.removeFromCollection, MenuIcon.REMOVE))
        }
        if (movieOrEpisode && (hasVersionChoice || gates.canTranscode) && gates.serverOnline && RowAction.VERSIONS !in onRow) {
            add(MenuEntry(PLAY_VERSION, menu.playVersion, MenuIcon.VIDEO_FILE, children = playVersionChoices(item, gates)))
        }
        if (gates.externalPlayers && movieOrEpisode) add(MenuEntry(PLAY_EXTERNAL, T.externalPlayer.playInExternalPlayer, MenuIcon.OPEN_IN_NEW))
        if (kind.hasFileInfo) add(MenuEntry(FILE_INFO, menu.fileInfo, MenuIcon.INFO))
        if (serverItemLink(item) != null) add(MenuEntry(SHOW_LINK, T.deepLinks.showLink, MenuIcon.LINK))
        addAll(provided[MenuSlot.METADATA].orEmpty())
        if (gates.canDeleteFromServer) add(MenuEntry(DELETE_MEDIA, deleteMenuLabel(kind), MenuIcon.DELETE_FOREVER, destructive = true))
    }
}

/**
 * Play Version's submenu, as its prompts ask the choice: with several versions each version (`play_version_<v>`), a
 * submenu of the qualities where the server transcodes (`play_version_<v>_<preset>`, [PlayerStates.offeredQualities]); with
 * one version its qualities; [gates]' version checked, and its quality under every version (the quality is the app's,
 * whichever version plays). Empty while the item's versions aren't known: the entry fetches and asks them.
 */
private fun playVersionChoices(item: MediaItem, gates: MenuGates): List<MenuEntry> {
    val versions = item.mediaVersions.orEmpty()
    fun qualities(index: Int): List<MenuEntry> = if (!gates.canTranscode) {
        emptyList()
    } else {
        val version = versions[index]
        PlayerStates.offeredQualities(version.bitrate, version.resolutionHeight, gates.quality).map { row ->
            MenuEntry("${PLAY_VERSION}_${index}_${row.preset.name}", row.label, icon = null, selected = row.selected)
        }
    }
    return when (versions.size) {
        0 -> emptyList()
        1 -> qualities(0)
        else -> versions.mapIndexed { index, version ->
            MenuEntry("${PLAY_VERSION}_$index", version.displayLabel, icon = null, children = qualities(index), selected = index == gates.version)
        }
    }
}

/** The version and quality (null: the original) a Play Version submenu entry's [id] picks; null for any other id. */
internal fun playVersionChoice(id: String): Pair<Int, TranscodeQualityPreset?>? {
    val parts = id.removePrefix("${PLAY_VERSION}_").takeIf { it != id }?.split('_', limit = 2) ?: return null
    val version = parts[0].toIntOrNull() ?: return null
    return version to parts.getOrNull(1)?.let { name -> TranscodeQualityPreset.entries.firstOrNull { it.name == name } }
}

/** A playlist's or collection's entries: Play, Shuffle Play, [provided] downloads, Delete. */
internal fun listMenuEntries(provided: Map<MenuSlot, List<MenuEntry>>): List<MenuEntry> = buildList {
    add(MenuEntry(PLAY, T.common.play, MenuIcon.PLAY))
    add(MenuEntry(SHUFFLE, T.mediaMenu.shufflePlay, MenuIcon.SHUFFLE))
    addAll(provided[MenuSlot.LIST_DOWNLOADS].orEmpty())
    add(MenuEntry(DELETE, T.common.delete, MenuIcon.DELETE, destructive = true))
}

private fun deleteMenuLabel(kind: MediaKind): String = when (kind) {
    MediaKind.SEASON -> T.mediaMenu.deleteSeasonFromServer
    MediaKind.SHOW -> T.mediaMenu.deleteShowFromServer
    MediaKind.MOVIE -> T.mediaMenu.deleteMovieFromServer
    else -> T.mediaMenu.deleteEpisodeFromServer
}

internal const val PLAY = "play"
internal const val SHUFFLE = "shuffle"
internal const val DELETE = "delete"
internal const val PLAY_FROM_BEGINNING = "play_from_beginning"
internal const val PLAY_TRAILER = "play_trailer"
internal const val WATCH = "watch"
internal const val UNWATCH = "unwatch"
internal const val REMOVE_FROM_CONTINUE_WATCHING = "remove_from_continue_watching"
internal const val DETAILS = "details"
internal const val REMOVE_FROM_COLLECTION = "remove_from_collection"
internal const val SERIES = "series"
internal const val SHUFFLE_PLAY = "shuffle_play"
internal const val SHOW_LINK = "show_link"
internal const val PLAY_VERSION = "play_version"
internal const val FILE_INFO = "fileinfo"
internal const val PLAY_EXTERNAL = "play_external"
internal const val ADD_TO = "add_to"
internal const val DELETE_MEDIA = "delete_media"
internal const val ADD_TO_PLAYLIST = "add_to_playlist"
internal const val ADD_TO_COLLECTION = "add_to_collection"
