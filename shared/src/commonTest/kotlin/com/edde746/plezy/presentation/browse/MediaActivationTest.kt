package com.edde746.plezy.presentation.browse

import com.edde746.plezy.jellyfin.JellyfinMappers
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexMappers
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.search.itemRoute
import com.edde746.plezy.settings.ContinueWatchingAction
import com.edde746.plezy.settings.EpisodeAction
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put

private val server = ServerId("server_1")

private fun episode(id: String = "ep", serverId: String = "server_1", parentIndex: Int? = 1, index: Int? = 2, libraryTitle: String? = null) = MediaItem(
    id = id,
    backend = BackendKind.PLEX,
    kind = MediaKind.EPISODE,
    title = "Episode",
    parentId = "season",
    grandparentId = "show",
    parentIndex = parentIndex,
    index = index,
    libraryTitle = libraryTitle,
    serverId = serverId,
    serverName = "Server $serverId",
)

private fun movie(id: String = "movie") = MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = "Film", serverId = "server_1")

class MediaActivationTest {
    @Test
    fun continueWatchingPlaysUnlessItsSettingSaysDetails() {
        val ep = episode()
        assertEquals(ItemActivation.Play(ep), activationOf(ep, true, ContinueWatchingAction.PLAY, EpisodeAction.DETAILS))
        assertEquals(ItemActivation.Play(movie()), activationOf(movie(), true, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
        assertEquals(
            ItemActivation.Open(Route.MediaDetail(server, "show", initialSeasonId = "season", initialEpisodeId = "ep")),
            activationOf(ep, true, ContinueWatchingAction.DETAILS, EpisodeAction.PLAY),
        )
        assertEquals(ItemActivation.Open(Route.MediaDetail(server, "movie")), activationOf(movie(), true, ContinueWatchingAction.DETAILS, EpisodeAction.PLAY))
    }

    @Test
    fun elsewhereAnEpisodeFollowsTheEpisodeSettingAndAMovieOpensItsDetail() {
        val ep = episode()
        assertEquals(ItemActivation.Play(ep), activationOf(ep, false, ContinueWatchingAction.DETAILS, EpisodeAction.PLAY))
        assertEquals(
            ItemActivation.Open(Route.MediaDetail(server, "show", initialSeasonId = "season", initialEpisodeId = "ep")),
            activationOf(ep, false, ContinueWatchingAction.PLAY, EpisodeAction.DETAILS),
        )
        assertEquals(ItemActivation.Open(Route.MediaDetail(server, "movie")), activationOf(movie(), false, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
        val collection = movie("col").copy(kind = MediaKind.COLLECTION)
        assertEquals(ItemActivation.Open(Route.CollectionDetail(server, "col")), activationOf(collection, false, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
        assertNull(activationOf(movie().copy(serverId = null), true, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
    }

    @Test
    fun aPlaylistOpensItsOwnScreenEvenFromContinueWatching() {
        val playlist = movie("pl").copy(kind = MediaKind.PLAYLIST)
        for (playDirectly in listOf(false, true)) {
            assertEquals(
                ItemActivation.Open(Route.PlaylistDetail(server, "pl")),
                activationOf(playlist, playDirectly, ContinueWatchingAction.PLAY, EpisodeAction.PLAY),
            )
        }
    }

    /** Search results and Home's hubs open what their server's row is: its playlist type as Plex or MediaBrowser gives it. */
    @Test
    fun anAudioPlaylistRowOpensTheMusicPlaylistPageAndAnyOtherThePlaylistScreen() {
        fun plex(type: String) =
            PlexMappers.mediaItem(Json.parseToJsonElement("""{"ratingKey":"pl","type":"playlist","key":"/playlists/pl/items","playlistType":"$type"}""").jsonObject, server)
        fun mediaBrowser(mediaType: String?) = JellyfinMappers.mediaItem(
            buildJsonObject {
                put("Id", "pl")
                put("Type", "Playlist")
                if (mediaType != null) put("MediaType", mediaType)
            },
            server.value,
            null,
            null,
        )!!
        fun opened(item: MediaItem) = activationOf(item, false, ContinueWatchingAction.PLAY, EpisodeAction.PLAY)
        val music = ItemActivation.Open(Route.MusicPlaylist(server.value, "pl"))
        val video = ItemActivation.Open(Route.PlaylistDetail(server, "pl"))

        assertEquals(music, opened(plex("audio")))
        assertEquals(video, opened(plex("video")))
        assertEquals(music, opened(mediaBrowser("Audio")))
        assertEquals(video, opened(mediaBrowser("Video")))
        assertEquals(video, opened(mediaBrowser(null)), "an untyped playlist, as Emby lists one")
    }

    @Test
    fun aSeasonOpensItsShowAtThatSeason() {
        val season = MediaItem(id = "season", backend = BackendKind.PLEX, kind = MediaKind.SEASON, title = "Season 1", parentId = "show", serverId = "server_1")
        assertEquals(Route.MediaDetail(server, "show", initialSeasonId = "season"), detailRouteOf(season))
    }

    @Test
    fun aSeasonSearchResultOpensItsShowAtThatSeason() {
        val season = MediaItem(id = "season", backend = BackendKind.JELLYFIN, kind = MediaKind.SEASON, title = "Season 1", grandparentId = "show", serverId = "server_1")
        assertEquals(Route.MediaDetail(server, "show", initialSeasonId = "season"), itemRoute(season, server))
        assertEquals(Route.MediaDetail(server, "show", initialSeasonId = "season"), activationOf(season, false, ContinueWatchingAction.PLAY, EpisodeAction.PLAY).let { (it as ItemActivation.Open).route })
    }

    @Test
    fun anEpisodeWithoutItsShowOpensOnItsSeasonAtTheEpisode() {
        val orphan = episode().copy(grandparentId = null)
        assertEquals(Route.MediaDetail(server, "season", initialEpisodeId = "ep"), detailRouteOf(orphan))
    }

    @Test
    fun aWholeLibraryASharedServerListsOpensThatLibrary() {
        val library = movie("7").copy(kind = MediaKind.UNKNOWN, raw = buildJsonObject { put("key", "/library/sections/7") })
        for (playDirectly in listOf(false, true)) {
            assertEquals(ItemActivation.OpenLibrary("server_1:7"), activationOf(library, playDirectly, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
        }
        val unnamed = library.copy(raw = buildJsonObject { put("key", "/library/sections/all") })
        assertNull(activationOf(unnamed, false, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
    }

    @Test
    fun aCardOpensItsDetailSeededWithItsItemAndTheSeedIsNotPartOfTheRoute() {
        val route = detailRouteOf(movie()) as Route.MediaDetail
        assertEquals(movie(), route.seed)
        assertEquals(Route.MediaDetail(server, "movie"), route)
        assertEquals(Route.MediaDetail(server, "movie").hashCode(), route.hashCode())
        assertNull(Route.MediaDetail(server, "movie").seed)
    }

    @Test
    fun anArtistAndAnAlbumOpenTheirMusicScreensAndATrackPlaysInItsAlbum() {
        val artist = movie("artist").copy(kind = MediaKind.ARTIST)
        val album = movie("album").copy(kind = MediaKind.ALBUM)
        assertEquals(ItemActivation.Open(Route.MusicArtist("server_1", "artist")), activationOf(artist, false, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
        assertEquals(ItemActivation.Open(Route.MusicAlbum("server_1", "album")), activationOf(album, false, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
        val track = movie("track").copy(kind = MediaKind.TRACK)
        assertEquals(ItemActivation.PlayTrack(track), activationOf(track, false, ContinueWatchingAction.PLAY, EpisodeAction.PLAY))
    }

    @Test
    fun aPhotoIsUnsupportedAndOpensNothing() {
        val photo = movie("photo").copy(kind = MediaKind.PHOTO)
        for (playDirectly in listOf(false, true)) {
            assertEquals(
                ItemActivation.Unsupported(T.messages.photosNotSupported),
                activationOf(photo, playDirectly, ContinueWatchingAction.DETAILS, EpisodeAction.DETAILS),
            )
        }
    }

    @Test
    fun copyLabelsSayOnlyWhatTellsTheCopiesApart() {
        val sameEpisode = listOf(episode("a", libraryTitle = "TV"), episode("b", libraryTitle = "TV 4K"))
        assertEquals(listOf("TV", "TV 4K"), copyLabels(sameEpisode))

        val acrossServers = listOf(episode("a", libraryTitle = "TV", index = 2), episode("b", "server_2", libraryTitle = "Shows", index = 3))
        assertEquals(listOf("S1 E2 • TV • Server server_1", "S1 E3 • Shows • Server server_2"), copyLabels(acrossServers))
    }
}
