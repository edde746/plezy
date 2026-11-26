package com.edde746.plezy.presentation.browse

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.libraryCopyQualityLabel
import com.edde746.plezy.plex.plexLibrarySectionIdFromString
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.playlistRoute
import com.edde746.plezy.settings.ContinueWatchingAction
import com.edde746.plezy.settings.EpisodeAction
import com.edde746.plezy.strings.T
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull

/** What selecting an item does ([activationOf]). */
sealed interface ItemActivation {
    /** Play it. */
    data class Play(val item: MediaItem) : ItemActivation

    /** Play the track in its album's queue, in the music player. */
    data class PlayTrack(val item: MediaItem) : ItemActivation

    /** Open [route] (its detail, a collection, a music screen). */
    data class Open(val route: Route) : ItemActivation

    /** Show the library [globalKey] in Libraries. */
    data class OpenLibrary(val globalKey: String) : ItemActivation

    /** Nothing opens: [message] says the item's kind isn't supported. */
    data class Unsupported(val message: String) : ItemActivation
}

/**
 * What selecting [item] does. [playDirectly] marks Continue Watching (its row, the hero, its View all), which follows
 * [continueWatchingAction]: an episode or a movie plays unless that says Details. Elsewhere an episode follows
 * [episodeAction] and a clip plays; a movie, show, season or anything else opens its detail, a collection its own
 * screen, a playlist its screen ([playlistRoute]), an artist or an album its music screen, a track plays in its album, a
 * photo is unsupported. A Plex row whose key is a library section's path (a whole library a shared server lists) opens
 * that library. Null for an item of no server, or a section path naming no section.
 */
fun activationOf(
    item: MediaItem,
    playDirectly: Boolean,
    continueWatchingAction: ContinueWatchingAction,
    episodeAction: EpisodeAction,
): ItemActivation? {
    val serverId = ServerId.tryParse(item.serverId) ?: return null
    val rawKey = (item.raw?.get("key") as? JsonPrimitive)?.contentOrNull
    if (rawKey != null && rawKey.startsWith("/library/sections/")) {
        return plexLibrarySectionIdFromString(rawKey)?.let { ItemActivation.OpenLibrary(buildGlobalKey(serverId, it.toString())) }
    }
    val detail = { detailRouteOf(item)?.let(ItemActivation::Open) }
    val cwDetails = playDirectly && continueWatchingAction == ContinueWatchingAction.DETAILS
    return when (item.kind) {
        MediaKind.COLLECTION -> ItemActivation.Open(Route.CollectionDetail(serverId, item.id))
        MediaKind.PLAYLIST -> ItemActivation.Open(playlistRoute(serverId, item.id, item.playlistType()))
        MediaKind.ARTIST -> ItemActivation.Open(Route.MusicArtist(serverId.value, item.id))
        MediaKind.ALBUM -> ItemActivation.Open(Route.MusicAlbum(serverId.value, item.id))
        MediaKind.TRACK -> ItemActivation.PlayTrack(item)
        MediaKind.EPISODE -> {
            val details = if (playDirectly) cwDetails else episodeAction == EpisodeAction.DETAILS
            if (details) detail() else ItemActivation.Play(item)
        }
        MediaKind.CLIP -> ItemActivation.Play(item)
        MediaKind.PHOTO -> ItemActivation.Unsupported(T.messages.photosNotSupported)
        MediaKind.MOVIE -> if (playDirectly && !cwDetails) ItemActivation.Play(item) else detail()
        else -> detail()
    }
}

/** A playlist row's type, lowercased, as its server gave it: Plex's `playlistType`, MediaBrowser's `MediaType` (Emby leaves it out). */
private fun MediaItem.playlistType(): String? {
    val field = if (backend == BackendKind.PLEX) "playlistType" else "MediaType"
    return (raw?.get(field) as? JsonPrimitive)?.contentOrNull?.lowercase()
}

/**
 * The detail [item] opens: an episode its show at its season and itself, a season its show at that season, anything
 * else its own, seeded with [item]. A season is never a screen of its own: one whose row doesn't name its show (and an
 * episode naming only its season) opens on the season's id, which the detail resolves to its show. Null for an item of
 * no server.
 */
fun detailRouteOf(item: MediaItem): Route? {
    val serverId = ServerId.tryParse(item.serverId) ?: return null
    val grandparent = item.grandparentId
    val parent = item.parentId
    return when {
        item.kind == MediaKind.EPISODE && grandparent != null -> Route.MediaDetail(serverId, grandparent, initialSeasonId = parent, initialEpisodeId = item.id)
        item.kind == MediaKind.EPISODE && parent != null -> Route.MediaDetail(serverId, parent, initialEpisodeId = item.id)
        item.kind == MediaKind.SEASON -> seasonRoute(serverId, item)
        else -> Route.MediaDetail(serverId, item.id).seeded(item)
    }
}

/** The detail a [season] on [serverId] opens: its show's, at that season (the season's own id when the row names no show). */
fun seasonRoute(serverId: ServerId, season: MediaItem): Route.MediaDetail =
    Route.MediaDetail(serverId, season.seasonShowId ?: season.id, initialSeasonId = season.id)

/**
 * The copy picker's line for each of [copies] (one Continue Watching row standing for the same title in several
 * libraries or on several servers): only what tells them apart, joined by " • ": the episode when the copies stopped at
 * different ones, the library (else the server, else the backend), the best quality, and the server when they span
 * several.
 */
fun copyLabels(copies: List<MediaItem>): List<String> {
    val showEpisode = copies.map { it.parentIndex to it.index }.toSet().size > 1
    val showServer = copies.map { it.serverId }.toSet().size > 1
    return copies.map { copy ->
        val library = copy.libraryTitle
        listOfNotNull(
            if (showEpisode && copy.kind == MediaKind.EPISODE && copy.parentIndex != null && copy.index != null) "S${copy.parentIndex} E${copy.index}" else null,
            library ?: copy.serverName ?: copy.backend.dialect?.productName ?: "Plex",
            libraryCopyQualityLabel(copy),
            if (showServer && library != null) copy.serverName else null,
        ).joinToString(" • ")
    }
}
