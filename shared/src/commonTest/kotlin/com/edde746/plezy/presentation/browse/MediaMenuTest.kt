package com.edde746.plezy.presentation.browse

import com.edde746.plezy.app.DownloadMenuEntries
import com.edde746.plezy.app.WatchlistMenuEntries
import com.edde746.plezy.app.WatchlistSource
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.matching.LibraryWatchlistCandidates
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaDeletionPermission
import com.edde746.plezy.backend.MediaDeletionRefusedException
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.testData
import com.edde746.plezy.downloads.ControllerHarness
import com.edde746.plezy.downloads.DownloadProgress
import com.edde746.plezy.downloads.FakeBackgroundWorkProbe
import com.edde746.plezy.downloads.FakeNativeDownloader
import com.edde746.plezy.downloads.NativeDownloader
import com.edde746.plezy.downloads.diagnostics
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.playback.queue.PlayQueueLaunch
import com.edde746.plezy.playback.queue.PlayQueueResult
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.downloads.BackgroundDownloadWarning
import com.edde746.plezy.presentation.downloads.DetailDownload
import com.edde746.plezy.presentation.downloads.DownloadActions
import com.edde746.plezy.presentation.downloads.DownloadDialogs
import com.edde746.plezy.presentation.downloads.SmartDeletion
import com.edde746.plezy.presentation.music.MusicHarness
import com.edde746.plezy.presentation.music.MusicMenuEntries
import com.edde746.plezy.presentation.music.SERVER
import com.edde746.plezy.presentation.music.musicTrack
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.player.PlayerStates
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.PlexHomeProfile
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.servers.DeletionEvent
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.FakeOfflineWatchDownloads
import com.edde746.plezy.servers.FakeWatchClients
import com.edde746.plezy.servers.InMemoryOfflineWatchQueue
import com.edde746.plezy.servers.LibraryRefreshNotifier
import com.edde746.plezy.servers.LibraryRefreshType
import com.edde746.plezy.servers.OfflineWatchProvider
import com.edde746.plezy.servers.OfflineWatchSyncService
import com.edde746.plezy.servers.RecordingTrackers
import com.edde746.plezy.servers.ToggleOfflineMode
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchStateStore
import com.edde746.plezy.servers.WatchedThresholdSource
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration

class MediaMenuTest {
    private val clients = FakeWatchClients()
    private val online = mutableSetOf<ServerId>()
    private val admins = mutableSetOf<ServerId>()
    private var profile: Profile? = null
    private var multipleProfiles = false
    private val deletions = DeletionNotifier()
    private val refresh = LibraryRefreshNotifier()
    private val navigator = PlezyNavigator(Route.Home)
    private val plays = mutableListOf<PlayRequest.Item>()
    private val offlineMode = ToggleOfflineMode()
    private var downloads: ControllerHarness? = null

    @AfterTest
    fun closeDownloads() {
        downloads?.close()
    }

    /** The lists the menu reported an item added to, by server: their download sync rules run. */
    private val addedToLists = mutableListOf<Pair<ServerId, String>>()

    private val episode = MediaItem(
        id = "ep-2",
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        title = "Cat's in the Bag...",
        index = 2,
        parentIndex = 1,
        parentId = "season-1",
        grandparentId = "show-1",
        grandparentTitle = "Breaking Bad",
        serverId = "plex",
        libraryId = "2",
    )

    // Title: the item alone, never its path.

    @Test
    fun anEpisodeMenuIsTitledByTheEpisodeAlone() {
        assertEquals("Cat's in the Bag...", MenuTarget.Item(episode).menuTitle())
    }

    @Test
    fun aSeasonMenuIsTitledByTheSeasonAlone() {
        val season = MediaItem("season-1", BackendKind.PLEX, MediaKind.SEASON, title = "Season 1", parentTitle = "Breaking Bad", serverId = "plex")
        assertEquals("Season 1", MenuTarget.Item(season).menuTitle())
    }

    @Test
    fun aShowOrMovieMenuIsTitledByItsTitle() {
        assertEquals("Breaking Bad", MenuTarget.Item(MediaItem("show-1", BackendKind.PLEX, MediaKind.SHOW, title = "Breaking Bad", serverId = "plex")).menuTitle())
        assertEquals("Heat", MenuTarget.Item(MediaItem("m-1", BackendKind.PLEX, MediaKind.MOVIE, title = "Heat", serverId = "plex")).menuTitle())
    }

    @Test
    fun aPlaylistMenuIsTitledByThePlaylist() {
        assertEquals("Road Trip", MenuTarget.Playlist(MediaPlaylist("pl-1", BackendKind.PLEX, "Road Trip", "video")).menuTitle())
    }

    // Gates.

    @Test
    fun blocksNonAdminPlexHomeUsersOnPlexItems() {
        val kid = PlexHomeProfile("home-1", "Kid", parentConnectionId = "c", plexHomeUserUuid = "u", plexAdmin = false)
        assertFalse(isAdminActionAllowed(isOwnerOrAdmin = true, BackendKind.PLEX, kid))
    }

    @Test
    fun doesNotApplyThePlexHomeRoleToJellyfinItems() {
        val kid = PlexHomeProfile("home-1", "Kid", parentConnectionId = "c", plexHomeUserUuid = "u", plexAdmin = false)
        assertTrue(isAdminActionAllowed(isOwnerOrAdmin = true, BackendKind.JELLYFIN, kid))
    }

    @Test
    fun allowsPlexAdminHomeUsersOnPlexItems() {
        val parent = PlexHomeProfile("home-1", "Parent", parentConnectionId = "c", plexHomeUserUuid = "u", plexAdmin = true)
        assertTrue(isAdminActionAllowed(isOwnerOrAdmin = true, BackendKind.PLEX, parent))
        assertFalse(isAdminActionAllowed(isOwnerOrAdmin = false, BackendKind.PLEX, parent))
    }

    @Test
    fun mediaBrowserDeletionFollowsTheServerAnswerNotTheAdminBit() {
        for (backend in listOf(BackendKind.JELLYFIN, BackendKind.EMBY)) {
            assertFalse(isMediaDeletionAllowed(backend, itemPermission = false, adminActionAllowed = true))
            assertTrue(isMediaDeletionAllowed(backend, itemPermission = true, adminActionAllowed = false))
            assertFalse(isMediaDeletionAllowed(backend, itemPermission = null, adminActionAllowed = true))
        }
    }

    @Test
    fun plexNeedsItsOwnerAndTheServerSwitchAndNoBackendIsNeverDeletable() {
        assertTrue(isMediaDeletionAllowed(BackendKind.PLEX, itemPermission = true, adminActionAllowed = true))
        assertFalse(isMediaDeletionAllowed(BackendKind.PLEX, itemPermission = false, adminActionAllowed = true))
        assertFalse(isMediaDeletionAllowed(BackendKind.PLEX, itemPermission = null, adminActionAllowed = true))
        assertFalse(isMediaDeletionAllowed(BackendKind.PLEX, itemPermission = true, adminActionAllowed = false))
        assertFalse(isMediaDeletionAllowed(null, itemPermission = true, adminActionAllowed = true))
    }

    // The delete gate as the menu resolves it.

    @Test
    fun hidesDeleteForAnAdministratorTheServerRefuses() = runTest {
        val server = jellyfin(permission = { false })
        admins += server.serverId
        assertFalse(DELETE_MEDIA in ids(menu().opened(movie(server))))
    }

    @Test
    fun showsDeleteForANonAdminTheServerPermits() = runTest {
        val server = jellyfin(permission = { true })
        val entries = menu().opened(movie(server))
        assertEquals(T.mediaMenu.deleteMovieFromServer, entries.last().label)
        assertTrue(entries.last().destructive)
    }

    @Test
    fun hidesDeleteWhenThePermissionProbeFails() = runTest {
        val server = jellyfin(permission = { throw IllegalStateException("500") })
        assertFalse(DELETE_MEDIA in ids(menu().opened(movie(server))))
    }

    @Test
    fun hidesDeleteWithoutProbingWhileTheItemServerIsOffline() = runTest {
        var probed = false
        val server = jellyfin(permission = { probed = true; true })
        online -= server.serverId
        assertFalse(DELETE_MEDIA in ids(menu().opened(movie(server))))
        assertFalse(probed)
    }

    @Test
    fun stillOpensTheMenuWithoutDeleteWhenTheProbeHangs() = runTest {
        val server = jellyfin(permission = { awaitCancellation() })
        val menu = menu()
        menu.open(movie(server))
        advanceUntilIdle()
        val opened = assertNotNull(menu.menu.value)
        assertTrue(WATCH in ids(opened.entries))
        assertFalse(DELETE_MEDIA in ids(opened.entries))
    }

    @Test
    fun aPeekedMenuAsksNoServerAndOffersDeleteAsTheListSaid() = runTest {
        var probed = false
        val server = jellyfin(permission = { probed = true; true })
        val menu = menu()
        assertFalse(DELETE_MEDIA in ids(assertNotNull(menu.peek { menu.open(movie(server)) }).entries))
        server.carried = true
        assertTrue(DELETE_MEDIA in ids(assertNotNull(menu.peek { menu.open(movie(server)) }).entries))
        advanceUntilIdle()
        assertFalse(probed)
    }

    @Test
    fun anOpenMenuTakesTheListsAnswerWithoutAsking() = runTest {
        var probed = false
        val server = jellyfin(permission = { probed = true; true })
        server.carried = false
        assertFalse(DELETE_MEDIA in ids(menu().opened(movie(server))))
        assertFalse(probed)
    }

    @Test
    fun deletingOnTheListsAnswerAsksTheServerFirstAndStopsOnARefusal() = runTest {
        val server = jellyfin(permission = { false })
        server.carried = true
        val menu = menu()
        menu.selectPeeked({ menu.open(movie(server)) }, DELETE_MEDIA)
        advanceUntilIdle()
        assertEquals(MenuMessage(T.mediaMenu.mediaFailedToDelete, isError = true), menu.message.value)
        assertNull(menu.prompt.value)
        assertTrue(server.deleted.isEmpty())
    }

    @Test
    fun deletingOnTheListsAnswerGoesOnToTheQuestionWhenTheServerAgrees() = runTest {
        val server = jellyfin(permission = { true })
        server.carried = true
        val show = MediaItem("show-1", BackendKind.JELLYFIN, MediaKind.SHOW, title = "Heat", leafCount = 2, serverId = server.serverId.value)
        val menu = menu()
        menu.selectPeeked({ menu.open(show) }, DELETE_MEDIA)
        advanceUntilIdle()
        assertEquals(T.mediaMenu.deleteShowTitle, assertIs<MenuPrompt.Confirm>(menu.prompt.value).title)
    }

    @Test
    fun plexOffersDeleteToItsOwnerOnlyWhileTheServerAllowsMediaDeletion() = runTest {
        var allowed = true
        val server = plex(permission = { allowed })
        admins += server.serverId
        val menu = menu()
        assertTrue(DELETE_MEDIA in ids(menu.opened(movie(server))))
        allowed = false
        assertFalse(DELETE_MEDIA in ids(menu.opened(movie(server))))
        server.carried = true
        assertTrue(DELETE_MEDIA in ids(assertNotNull(menu.peek { menu.open(movie(server)) }).entries), "a peeked menu goes on the switch as last read")
    }

    @Test
    fun plexAsksNothingForAUserWhoIsNotItsOwner() = runTest {
        var probed = false
        val server = plex(permission = { probed = true; true })
        server.carried = true
        val menu = menu()
        assertFalse(DELETE_MEDIA in ids(menu.opened(movie(server))))
        assertFalse(DELETE_MEDIA in ids(assertNotNull(menu.peek { menu.open(movie(server)) }).entries))
        assertFalse(probed)
    }

    @Test
    fun aPlexSwitchFoundOffBeforeTheQuestionSaysDeletionIsOffOnTheServer() = runTest {
        val server = plex(permission = { false })
        admins += server.serverId
        server.carried = true
        val menu = menu()
        menu.selectPeeked({ menu.open(movie(server)) }, DELETE_MEDIA)
        advanceUntilIdle()
        assertEquals(MenuMessage(T.mediaMenu.mediaDeletionDisabledOnServer, isError = true), menu.message.value)
        assertNull(menu.prompt.value)
        assertTrue(server.deleted.isEmpty())
    }

    @Test
    fun aPlexRefusalAfterTheQuestionSaysDeletionIsOffOnTheServerAndReportsNothingDeleted() = runTest {
        val server = plex()
        admins += server.serverId
        server.deleteAnswer = { throw MediaDeletionRefusedException() }
        server.files("ep-2" to listOf("/tv/bb/S01E02.mkv"))
        val events = collect(deletions)
        val menu = menu()
        assertTrue(DELETE_MEDIA in ids(menu.opened(episode)))
        menu.select(DELETE_MEDIA)
        advanceUntilIdle()
        assertIs<MenuPrompt.Confirm>(menu.prompt.value)
        menu.confirm(true)
        advanceUntilIdle()
        assertTrue(server.deleted.isEmpty())
        assertEquals(MenuMessage(T.mediaMenu.mediaDeletionDisabledOnServer, isError = true), menu.message.value)
        assertTrue(events.isEmpty())
    }

    @Test
    fun onlyDeletableKindsAskTheServer() = runTest {
        var probed = false
        val server = jellyfin(permission = { probed = true; true })
        menu().opened(MediaItem("t-1", BackendKind.JELLYFIN, MediaKind.TRACK, serverId = server.serverId.value))
        assertFalse(probed)
    }

    // Entries and their order.

    @Test
    fun anEpisodeInProgressOffersItsEntriesInOrder() = runTest {
        val server = plex()
        admins += server.serverId
        val inProgress = episode.copy(viewOffsetMs = 600_000, durationMs = 2_700_000)

        val entries = menu().opened(inProgress)

        assertEquals(
            listOf(PLAY_FROM_BEGINNING, WATCH, UNWATCH, SERIES, ADD_TO, PLAY_VERSION, FILE_INFO, SHOW_LINK, DELETE_MEDIA),
            ids(entries),
        )
    }

    @Test
    fun playTrailerFollowsGoToSeriesOnlyWhenTheDetailPassesIt() = runTest {
        plex()
        val inProgress = episode.copy(viewOffsetMs = 600_000, durationMs = 2_700_000)
        val menu = menu()
        assertFalse(PLAY_TRAILER in ids(menu.opened(inProgress)))

        var trailers = 0
        menu.dismiss()
        menu.open(inProgress, playTrailer = { trailers++ })
        advanceUntilIdle()
        val entries = ids(menu.menu.value!!.entries)
        assertEquals(listOf(PLAY_FROM_BEGINNING, WATCH, UNWATCH, SERIES, PLAY_TRAILER), entries.take(5))

        menu.select(PLAY_TRAILER)
        advanceUntilIdle()
        assertEquals(1, trailers)
    }

    @Test
    fun showLinkIsOfferedOnMoviesShowsAndEpisodesOfAServer() = runTest {
        val server = plex()
        val menu = menu()
        for (kind in listOf(MediaKind.MOVIE, MediaKind.SHOW, MediaKind.EPISODE)) {
            assertTrue(SHOW_LINK in ids(menu.opened(MediaItem("i-1", BackendKind.PLEX, kind, title = "X", serverId = server.serverId.value))), "$kind")
        }
        for (kind in listOf(MediaKind.ALBUM, MediaKind.TRACK, MediaKind.SEASON)) {
            assertFalse(SHOW_LINK in ids(menu.opened(MediaItem("i-1", BackendKind.PLEX, kind, title = "X", serverId = server.serverId.value))), "$kind")
        }
        assertFalse(SHOW_LINK in ids(menu.opened(MediaItem("i-1", BackendKind.PLEX, MediaKind.MOVIE, title = "X"))))
    }

    @Test
    fun aPhotoMenuOffersNoWatchState() = runTest {
        val server = plex()
        val photo = MediaItem("p-1", BackendKind.PLEX, MediaKind.PHOTO, title = "IMG_0001.jpg", serverId = server.serverId.value)
        val entries = ids(menu().opened(photo))
        assertFalse(WATCH in entries)
        assertFalse(UNWATCH in entries)
    }

    @Test
    fun showLinkNamesAPlexMovieByItsGuidAndCloses() = runTest {
        val server = plex()
        server.externalIds = { ExternalIds() }
        val menu = menu()
        menu.opened(movie(server).copy(guid = "plex://movie/5d776825880197001ec967c2"))

        menu.select(SHOW_LINK)
        advanceUntilIdle()
        val link = assertIs<MenuPrompt.Link>(menu.prompt.value)
        assertEquals("plezy://play?type=movie&plex=5d776825880197001ec967c2", link.link)
        assertEquals(MediaKind.MOVIE, link.kind)
        assertNull(link.asProfile, "one profile: no Open as switch")

        menu.closePrompt()
        advanceUntilIdle()
        assertNull(menu.prompt.value)
    }

    @Test
    fun showLinkFallsBackToTheServerLinkWhenTheIdsFail() = runTest {
        val server = plex()
        server.externalIds = { throw IllegalStateException("500") }
        val menu = menu()
        menu.opened(MediaItem("e-9", BackendKind.PLEX, MediaKind.EPISODE, title = "X", serverId = server.serverId.value))

        menu.select(SHOW_LINK)
        advanceUntilIdle()
        assertEquals("plezy://play?server=plex&id=e-9", assertIs<MenuPrompt.Link>(menu.prompt.value).link)
    }

    @Test
    fun withSeveralProfilesShowLinkOffersALinkNamingTheActiveOne() = runTest {
        val server = plex()
        server.externalIds = { throw IllegalStateException("500") }
        profile = LocalProfile("p-2", "Kid", createdAt = 0)
        multipleProfiles = true
        val menu = menu()
        menu.opened(MediaItem("e-9", BackendKind.PLEX, MediaKind.EPISODE, title = "X", serverId = server.serverId.value))

        menu.select(SHOW_LINK)
        advanceUntilIdle()
        val link = assertIs<MenuPrompt.Link>(menu.prompt.value)
        assertEquals("plezy://play?server=plex&id=e-9", link.link)
        assertEquals(LinkAsProfile("Open as Kid", "plezy://play?server=plex&id=e-9&profile=p-2"), link.asProfile)
    }

    @Test
    fun aPlaylistPlayAndShuffleLaunchItsQueue() = runTest {
        plex()
        val launches = mutableListOf<QueueLaunch>()
        val menu = menu(launchQueue = { launches += it; PlayQueueLaunch("Play", foreground()) { PlayQueueResult.Success } })
        val playlist = MediaPlaylist("pl-1", BackendKind.PLEX, "Mix", "video", serverId = "plex")
        for (entry in listOf(PLAY, SHUFFLE)) {
            menu.open(playlist)
            runCurrent()
            menu.select(entry)
            advanceUntilIdle()
        }
        assertEquals(listOf(false, true), launches.map { assertIs<QueueLaunch.Playlist>(it).shuffle })
        assertNull(menu.message.value)
    }

    @Test
    fun anEmptyAudioPlaylistSaysItHasNoItems() = runTest {
        plex()
        val played = mutableListOf<Boolean>()
        val menu = menu(playAudioPlaylist = { _, shuffle, _ -> played += shuffle; false })
        menu.open(MediaPlaylist("pl-2", BackendKind.PLEX, "Songs", "audio", serverId = "plex"))
        runCurrent()
        menu.select(SHUFFLE)
        advanceUntilIdle()

        assertEquals(listOf(true), played)
        assertEquals(MenuMessage(T.messages.failedToCreatePlayQueueNoItems, isError = true), menu.message.value)
    }

    @Test
    fun continueWatchingOffersRemoveAndDetailsButNotGoToSeries() = runTest {
        plex()
        val entries = menu().opened(episode, MenuPlace(continueWatching = true))

        assertTrue(REMOVE_FROM_CONTINUE_WATCHING in ids(entries))
        assertTrue(DETAILS in ids(entries))
        assertFalse(SERIES in ids(entries))
    }

    @Test
    fun goToSeriesIsHiddenOnThatSeriesOwnScreen() = runTest {
        plex()
        assertFalse(SERIES in ids(menu().opened(episode, MenuPlace(seriesId = "show-1"))))
        assertTrue(SERIES in ids(menu().opened(episode, MenuPlace(seriesId = "show-9"))))
    }

    @Test
    fun removeFromCollectionNeedsTheCollectionAndCollectionRights() = runTest {
        val server = jellyfin(permission = { false })
        val item = movie(server)
        assertFalse(REMOVE_FROM_COLLECTION in ids(menu().opened(item, MenuPlace(collectionId = "c-1"))))
        admins += server.serverId
        assertTrue(REMOVE_FROM_COLLECTION in ids(menu().opened(item, MenuPlace(collectionId = "c-1"))))
        assertFalse(REMOVE_FROM_COLLECTION in ids(menu().opened(item)))
    }

    @Test
    fun aPlaylistOffersPlayShuffleAndDelete() = runTest {
        plex()
        val menu = menu()
        menu.open(MediaPlaylist("pl-1", BackendKind.PLEX, "Mix", "video", serverId = "plex"))
        runCurrent()
        assertEquals(listOf(PLAY, SHUFFLE, DELETE), ids(menu.menu.value!!.entries))
        assertEquals("Mix", menu.menu.value!!.title)
    }

    @Test
    fun providerEntriesGoInTheirSlotAndRunThere() = runTest {
        plex()
        val provider = object : MenuEntryProvider {
            override val slot = MenuSlot.DOWNLOADS
            var performed: String? = null

            override fun entries(target: MenuTarget, place: MenuPlace) = listOf(MenuEntry("download", "Download", MenuIcon.DOWNLOAD))

            override suspend fun perform(target: MenuTarget, place: MenuPlace, entryId: String): MenuMessage? {
                performed = entryId
                return MenuMessage("Queued")
            }
        }
        val menu = menu(providers = listOf(provider))
        val entries = menu.opened(episode)
        assertEquals(ids(entries).indexOf("download") + 1, ids(entries).indexOf(ADD_TO))

        menu.select("download")
        advanceUntilIdle()

        assertEquals("download", provider.performed)
        assertEquals("Queued", menu.message.value?.text)
    }

    @Test
    fun aSecondOpenWhileAMenuIsOpenDoesNothing() = runTest {
        plex()
        val menu = menu()
        menu.open(episode)
        runCurrent()
        menu.open(episode.copy(id = "ep-3", title = "Other"))
        runCurrent()
        assertTrue(menu.menu.value!!.title.endsWith("Cat's in the Bag..."))
    }

    // Music items: the music actions first, then the menu's own entries and the downloads'.

    private val track = musicTrack("t")
    private val album = MediaItem("al", BackendKind.PLEX, MediaKind.ALBUM, title = "Album", parentId = "ar", serverId = SERVER)
    private val artist = MediaItem("ar", BackendKind.PLEX, MediaKind.ARTIST, title = "Artist", serverId = SERVER)

    @Test
    fun aMusicItemsMenuIsTheMusicActionsThenMarkWatchedDownloadAndFileInfo() = runTest {
        val server = plex(SERVER)
        val music = MusicHarness(backgroundScope, backend = server)
        val menu = menu(listOf(MusicMenuEntries { music.screens }) + downloadEntries())
        val queueing = listOf("music_play", "music_play_next", "music_add_to_queue", "music_instant_mix")

        assertEquals(queueing + listOf("music_go_to_album", "music_go_to_artist", WATCH, "download", FILE_INFO), ids(menu.opened(track)))
        // On its album's screen no Go to album, on its artist's no Go to artist.
        assertEquals(queueing + listOf("music_go_to_artist", WATCH, "download", FILE_INFO), ids(menu.opened(track, MenuPlace(albumId = track.parentId))))
        assertEquals(queueing + listOf(WATCH, "download"), ids(menu.opened(album, MenuPlace(artistId = album.parentId))))
        // An album has no file of its own; an artist's whole discography is no one-tap download.
        assertEquals(queueing + listOf("music_go_to_artist", WATCH, "download"), ids(menu.opened(album)))
        assertEquals(queueing + WATCH, ids(menu.opened(artist)))
        // Music links aren't shared: no Show link.
        assertFalse(SHOW_LINK in ids(menu.opened(track)))
    }

    @Test
    fun aDownloadedTrackOffersDeletingItsDownloadOnlineAndOffline() = runTest {
        val server = plex(SERVER)
        val music = MusicHarness(backgroundScope, backend = server)
        val menu = menu(listOf(MusicMenuEntries { music.screens }) + downloadEntries())
        downloaded(track)
        assertEquals(listOf("delete_download", FILE_INFO), ids(menu.opened(track)).takeLast(2))

        // Offline (the server has no client): the queueing and going entries stay, Instant Mix goes, the download can
        // still be deleted and a track that isn't downloaded offers no download, which needs the server.
        val offline = FakeWatchClients()
        val offlineMusic = MusicHarness(backgroundScope, backend = server, online = false)
        val offlineMenu = menu(listOf(MusicMenuEntries { offlineMusic.screens }) + downloadEntries(offline::client))
        assertEquals(
            listOf("music_play", "music_play_next", "music_add_to_queue", "music_go_to_album", "music_go_to_artist", WATCH, "delete_download", FILE_INFO),
            ids(offlineMenu.opened(track)),
        )
        assertFalse(ids(offlineMenu.opened(musicTrack("u"))).any { it.contains("download") })
    }

    @Test
    fun aDeviceThatCannotDownloadOffersNoDownloadEntriesForMusic() = runTest {
        val server = plex(SERVER)
        val music = MusicHarness(backgroundScope, backend = server)
        // As Apple TV: no downloader (and there the app adds no download entries at all).
        val menu = menu(listOf(MusicMenuEntries { music.screens }) + downloadEntries(downloader = null))
        assertEquals(listOf(WATCH, FILE_INFO), ids(menu.opened(track)).takeLast(2))
        assertEquals(WATCH, ids(menu.opened(album)).last())
    }

    /** The downloads' entries over a fresh downloads controller ([downloader] null: a device that can't download). */
    private suspend fun TestScope.downloadEntries(
        client: (ServerId) -> MediaBackend? = clients::client,
        downloader: NativeDownloader? = FakeNativeDownloader(),
    ): List<MenuEntryProvider> {
        val h = downloads ?: ControllerHarness.create(downloader).also { downloads = it }
        val settings = testData().deviceSettings
        val warning = BackgroundDownloadWarning(diagnostics(FakeBackgroundWorkProbe()), settings, {}, { true }, backgroundScope)
        val dialogs = DownloadDialogs()
        val detail = DetailDownload(h.controller, DownloadActions(h.controller, dialogs, warning, settings), dialogs, warning, SmartDeletion(h.controller))
        return listOf(MenuSlot.DOWNLOADS, MenuSlot.LIST_DOWNLOADS).map { DownloadMenuEntries(h.controller, detail, client, it) }
    }

    /** [item]'s download completed. */
    private suspend fun downloaded(item: MediaItem) {
        checkNotNull(downloads).seed(
            downloads = mapOf(item.globalKey to DownloadProgress(item.globalKey, DownloadedMediaStatus.COMPLETED)),
            metadata = mapOf(item.globalKey to item),
        )
    }

    // Menus peeked as their items show (system menus that need their entries as they open).

    @Test
    fun aPeekedMenuResolvesAtOnceWithoutOpening() = runTest {
        plex()
        val menu = menu()
        val peeked = assertNotNull(menu.peek { menu.open(episode) })
        assertTrue(WATCH in ids(peeked.entries))
        assertNull(menu.menu.value)
    }

    @Test
    fun aPeekedEntryRunsAndTheMenuReadAgainOffersTheOtherMark() = runTest {
        val server = plex()
        server.markWatchedHandler = { }
        val menu = menu()
        val revision = menu.revision.value

        menu.selectPeeked({ menu.open(episode) }, WATCH)
        advanceUntilIdle()
        // The watch state the app knows (the store runs in the background) takes the mark.
        runCurrent()

        assertEquals(listOf("markWatched:ep-2"), server.calls)
        assertEquals(MenuMessage(T.messages.markedAsWatched), menu.message.value)
        assertTrue(menu.revision.value > revision, "the peeked menus are read again")
        val entries = ids(assertNotNull(menu.peek { menu.open(episode) }).entries)
        assertTrue(UNWATCH in entries)
        assertFalse(WATCH in entries)
    }

    @Test
    fun aCardAlreadyOnTheWatchlistOffersRemoveOnceItsFirstPeekFetchedAheadWithOneWatchlistFetch() = runTest {
        val server = plex()
        server.externalIds = { ExternalIds(imdb = "tt-$it") }
        val trakt = WatchlistSource(CatalogSourceId.TRAKT, members = null).apply { onLoad = mutableSetOf("tt-m-1") }
        val menu = menu(providers = listOf(watchlist(trakt)))
        val ids = listOf("m-1", "m-2", "m-3")
        val revision = menu.revision.value
        ids.forEach { id -> menu.peek { menu.open(movie(server).copy(id = id)) } }
        advanceUntilIdle()
        assertTrue(menu.revision.value > revision, "what was fetched ahead has the menus read again")

        fun watchlistEntry(id: String) = ids(assertNotNull(menu.peek { menu.open(movie(server).copy(id = id)) }).entries)
            .single { it == WatchlistMenuEntries.ADD || it == WatchlistMenuEntries.REMOVE }
        assertEquals(WatchlistMenuEntries.REMOVE, watchlistEntry("m-1"), "the card on the watchlist")
        assertEquals(WatchlistMenuEntries.ADD, watchlistEntry("m-2"))
        assertEquals(WatchlistMenuEntries.ADD, watchlistEntry("m-3"))
        advanceUntilIdle()
        assertEquals(1, trakt.fetches, "one watchlist fetch for every card")
        assertEquals(ids.size, server.calls.count { it.startsWith("fetchExternalIds:") }, "each card's ids, once")
    }

    @Test
    fun anOpenMenuOfACardOnTheWatchlistOpensAtOnceThenOffersRemoveOnceTheWatchlistLoads() = runTest {
        val server = plex()
        server.externalIds = { ExternalIds(imdb = "tt-$it") }
        val trakt = WatchlistSource(CatalogSourceId.TRAKT, members = null).apply {
            onLoad = mutableSetOf("tt-m-1")
            loading = CompletableDeferred()
        }
        val menu = menu(providers = listOf(watchlist(trakt)))
        fun watchlistEntry() = ids(assertNotNull(menu.menu.value, "the menu is open").entries)
            .single { it == WatchlistMenuEntries.ADD || it == WatchlistMenuEntries.REMOVE }

        menu.open(movie(server))
        advanceUntilIdle()
        assertEquals(WatchlistMenuEntries.ADD, watchlistEntry(), "the menu opens before the watchlist has loaded")
        checkNotNull(trakt.loading).complete(Unit)
        advanceUntilIdle()
        assertEquals(WatchlistMenuEntries.REMOVE, watchlistEntry(), "the open menu offers Remove once it has")

        menu.select(WatchlistMenuEntries.REMOVE)
        advanceUntilIdle()
        assertEquals(listOf("remove tt-m-1"), trakt.mutations)
        assertEquals(MenuMessage(T.explore.removedFromWatchlist), menu.message.value)
    }

    @Test
    fun aMenuClosedBeforeTheWatchlistLoadsStaysClosed() = runTest {
        val server = plex()
        server.externalIds = { ExternalIds(imdb = "tt-$it") }
        val trakt = WatchlistSource(CatalogSourceId.TRAKT, members = null).apply {
            onLoad = mutableSetOf("tt-m-1")
            loading = CompletableDeferred()
        }
        val menu = menu(providers = listOf(watchlist(trakt)))
        menu.open(movie(server))
        advanceUntilIdle()
        menu.dismiss()
        checkNotNull(trakt.loading).complete(Unit)
        advanceUntilIdle()
        assertNull(menu.menu.value)
    }

    /** The watchlist's entries over [sources], on this test's servers. */
    private fun TestScope.watchlist(vararg sources: CatalogSource): WatchlistMenuEntries {
        val cache = LibraryWatchlistCandidates { sources.toList() }
        return WatchlistMenuEntries(
            candidates = { cache },
            sources = { sources.toList() },
            client = clients::client,
            isOnline = { it in online },
            isOffline = { false },
            choose = { null },
            scope = backgroundScope,
        )
    }

    @Test
    fun peekingLeavesAnOpenMenuOpen() = runTest {
        plex()
        val menu = menu()
        menu.opened(episode)
        val peeked = assertNotNull(menu.peek { menu.open(episode.copy(id = "ep-3", title = "Other")) })
        advanceUntilIdle()
        assertTrue(menu.menu.value!!.title.endsWith("Cat's in the Bag..."))
        assertTrue(peeked.title.endsWith("Other"))
    }

    // Watch marks and client resolution.

    @Test
    fun markAsWatchedSaysSoOnSuccess() = runTest {
        val server = plex()
        server.markWatchedHandler = { }
        val menu = menu()
        menu.opened(episode)

        menu.select(WATCH)
        advanceUntilIdle()

        assertEquals(MenuMessage(T.messages.markedAsWatched), menu.message.value)
        assertEquals(listOf("markWatched:ep-2"), server.calls)
    }

    @Test
    fun markAsWatchedReportsAFailureWhenTheItemServerHasNoClient() = runTest {
        val other = plex("other")
        val menu = menu()
        menu.opened(episode.copy(serverId = "gone"))

        menu.select(WATCH)
        advanceUntilIdle()

        assertEquals(MenuMessage(T.messages.errorLoading(error = T.errors.reasonUnreachable), isError = true), menu.message.value)
        assertTrue(other.calls.isEmpty())
    }

    @Test
    fun anItemWhoseServerHasNoClientIsNeverSentToAnotherServer() = runTest {
        val other = plex("other")
        admins += other.serverId
        val menu = menu()
        menu.opened(episode.copy(serverId = "gone", kind = MediaKind.MOVIE))

        menu.select(ADD_TO)
        advanceUntilIdle()

        assertTrue(other.calls.isEmpty())
        assertTrue(menu.message.value!!.isError)
    }

    // Add to.

    @Test
    fun aNonAdminGoesStraightToThePlaylistPickerAndAddsTheItem() = runTest {
        val server = jellyfin(permission = { false })
        server.playlists = listOf(MediaPlaylist("pl-1", BackendKind.JELLYFIN, "Favourites", "video", leafCount = 3))
        val changes = collect(refresh)
        val menu = menu()
        menu.opened(movie(server))

        menu.select(ADD_TO)
        runCurrent()
        val picker = assertIs<MenuPrompt.Picker>(menu.prompt.value).picker
        assertEquals(listOf(PickerRow("pl-1", "Favourites", T.playlists.itemCount(count = "3"), MenuIcon.PLAYLIST)), picker.state.value.rows)
        picker.pick("pl-1")
        advanceUntilIdle()

        assertEquals(listOf("pl-1" to "m-1"), server.added)
        assertEquals(MenuMessage(T.playlists.itemAdded), menu.message.value)
        assertEquals(listOf(LibraryRefreshType.PLAYLISTS), changes)
        assertEquals(listOf(server.serverId to "pl-1"), addedToLists)
    }

    @Test
    fun anAdminChoosesBetweenPlaylistAndCollection() = runTest {
        val server = jellyfin(permission = { false })
        admins += server.serverId
        val menu = menu()
        menu.opened(movie(server))

        menu.select(ADD_TO)
        runCurrent()

        val options = assertIs<MenuPrompt.Options>(menu.prompt.value)
        assertEquals(listOf(T.playlists.playlist, T.collections.collection), options.options.map { it.label })
    }

    @Test
    fun anAdminsAddToIsASubmenuWhoseCollectionOpensTheCollectionPicker() = runTest {
        val server = plex()
        val menu = menu()
        val entry = menu.opened(movie(server)).single { it.id == ADD_TO }
        assertEquals(listOf(ADD_TO_PLAYLIST, ADD_TO_COLLECTION), ids(entry.children))

        menu.select(ADD_TO_COLLECTION)
        runCurrent()
        assertIs<MenuPrompt.Picker>(menu.prompt.value).picker.pick("col-1")
        advanceUntilIdle()

        assertEquals(listOf(server.serverId to "col-1"), addedToLists)
    }

    @Test
    fun addToPlaylistFromTheSubmenuOpensThePlaylistPicker() = runTest {
        val server = plex()
        server.playlists = listOf(MediaPlaylist("pl-1", BackendKind.PLEX, "Favourites", "video"))
        val menu = menu()
        menu.opened(movie(server))

        menu.select(ADD_TO_PLAYLIST)
        runCurrent()
        assertIs<MenuPrompt.Picker>(menu.prompt.value).picker.pick("pl-1")
        advanceUntilIdle()

        assertEquals(listOf("pl-1" to "m-1"), server.added)
    }

    @Test
    fun aNonAdminsAddToHasNoSubmenu() = runTest {
        val server = jellyfin(permission = { false })
        val menu = menu()

        assertEquals(emptyList(), menu.opened(movie(server)).single { it.id == ADD_TO }.children)
    }

    @Test
    fun createNewPromptsForANameAndCreatesThePlaylistWithTheItem() = runTest {
        val server = jellyfin(permission = { false })
        val menu = menu()
        menu.opened(movie(server))
        menu.select(ADD_TO)
        runCurrent()

        assertIs<MenuPrompt.Picker>(menu.prompt.value).picker.createNew()
        runCurrent()
        assertIs<MenuPrompt.TextInput>(menu.prompt.value)
        menu.submit("  Weekend  ")
        advanceUntilIdle()

        assertEquals(listOf("Weekend" to listOf("m-1")), server.created)
        assertEquals(MenuMessage(T.playlists.created), menu.message.value)
        // A new playlist has no sync rule yet.
        assertEquals(emptyList(), addedToLists)
    }

    @Test
    fun thePlaylistPickerFiltersByTitleOnceThereAreTenOrMore() = runTest {
        val server = jellyfin(permission = { false })
        server.playlists = (1..12).map { MediaPlaylist("pl-$it", BackendKind.JELLYFIN, if (it == 7) "Road Trip" else "List $it", "video") }
        val menu = menu()
        menu.opened(movie(server))
        menu.select(ADD_TO)
        runCurrent()
        val picker = assertIs<MenuPrompt.Picker>(menu.prompt.value).picker
        assertTrue(picker.state.value.showFilter)

        picker.filter("road")

        assertEquals(listOf("pl-7"), picker.state.value.rows.map { it.id })
    }

    @Test
    fun aCollectionAddNeedsTheItemsLibrary() = runTest {
        val server = plex()
        server.items = { null }
        val menu = menu()
        menu.opened(episode.copy(libraryId = null, kind = MediaKind.MOVIE, grandparentId = null))
        menu.select(ADD_TO)
        runCurrent()
        menu.choose(1)
        advanceUntilIdle()

        assertEquals(MenuMessage(T.messages.unableToDetermineLibrarySection, isError = true), menu.message.value)
    }

    @Test
    fun addingToACollectionOrMakingOneRunsThatCollectionsSyncRule() = runTest {
        val server = plex()
        val menu = menu()
        menu.opened(movie(server))
        menu.select(ADD_TO)
        runCurrent()
        menu.choose(1)
        runCurrent()
        assertIs<MenuPrompt.Picker>(menu.prompt.value).picker.pick("col-1")
        advanceUntilIdle()

        menu.opened(movie(server))
        menu.select(ADD_TO)
        runCurrent()
        menu.choose(1)
        runCurrent()
        assertIs<MenuPrompt.Picker>(menu.prompt.value).picker.createNew()
        runCurrent()
        menu.submit("Heists")
        advanceUntilIdle()

        assertEquals(listOf("col-1" to "m-1"), server.addedToCollection)
        assertEquals(listOf("1/Heists/m-1/MOVIE"), server.createdCollections)
        assertEquals(listOf(server.serverId to "col-1", server.serverId to "col-new"), addedToLists)
    }

    // Remove from collection.

    @Test
    fun removeFromCollectionAsksThenRemovesAndRefreshesCollections() = runTest {
        val server = plex()
        val changes = collect(refresh)
        val menu = menu()
        menu.opened(episode, MenuPlace(collectionId = "c-1"))

        menu.select(REMOVE_FROM_COLLECTION)
        runCurrent()
        assertEquals(T.collections.removeFromCollectionConfirm(title = episode.displayTitle), assertIs<MenuPrompt.Confirm>(menu.prompt.value).message)
        menu.confirm(true)
        advanceUntilIdle()

        assertEquals(listOf("c-1" to "ep-2"), server.removed)
        assertEquals(listOf(LibraryRefreshType.COLLECTIONS), changes)
    }

    // Delete from server.

    @Test
    fun namesTheEpisodeNeverTheShowAtEveryStep() = runTest {
        val server = plex()
        admins += server.serverId
        server.files("ep-2" to listOf("/tv/bb/S01E02.mkv"))
        val menu = menu()
        val entries = menu.opened(episode)
        assertEquals("Cat's in the Bag...", menu.menu.value!!.title)
        assertEquals(T.mediaMenu.deleteEpisodeFromServer, entries.single { it.id == DELETE_MEDIA }.label)

        menu.select(DELETE_MEDIA)
        advanceUntilIdle()

        val confirm = assertIs<MenuPrompt.Confirm>(menu.prompt.value)
        assertEquals(T.mediaMenu.deleteEpisodeTitle, confirm.title)
        assertEquals(T.mediaMenu.confirmDeleteTarget(title = "Breaking Bad · S1 E2 · Cat's in the Bag..."), confirm.message)
        assertEquals(T.mediaMenu.deleteEpisodeConfirm, confirm.confirmLabel)
        assertNull(confirm.warning)
    }

    @Test
    fun aShowDeleteSaysSoAndStatesTheEpisodeCount() = runTest {
        val server = plex()
        admins += server.serverId
        val show = MediaItem("show-1", BackendKind.PLEX, MediaKind.SHOW, title = "Breaking Bad", leafCount = 62, serverId = "plex")
        val menu = menu()
        menu.opened(show)

        menu.select(DELETE_MEDIA)
        advanceUntilIdle()

        val confirm = assertIs<MenuPrompt.Confirm>(menu.prompt.value)
        assertEquals(T.mediaMenu.deleteShowTitle, confirm.title)
        assertEquals(T.mediaMenu.deleteEpisodeCountWarning(n = 62), confirm.warning)
        assertTrue(server.calls.isEmpty(), "a show's reach is stated, not probed")
    }

    @Test
    fun cancellingIssuesNoDeleteRequest() = runTest {
        val server = plex()
        admins += server.serverId
        server.files("ep-2" to listOf("/tv/bb/S01E02.mkv"))
        val menu = menu()
        menu.opened(episode)
        menu.select(DELETE_MEDIA)
        advanceUntilIdle()

        menu.confirm(false)
        advanceUntilIdle()

        assertTrue(server.deleted.isEmpty())
        assertNull(menu.prompt.value)
    }

    @Test
    fun confirmingDeletesExactlyTheFocusedEpisode() = runTest {
        val server = plex()
        admins += server.serverId
        server.files("ep-2" to listOf("/tv/bb/S01E02.mkv"))
        val events = collect(deletions)
        val menu = menu()
        menu.opened(episode)
        menu.select(DELETE_MEDIA)
        advanceUntilIdle()

        menu.confirm(true)
        advanceUntilIdle()

        assertEquals(listOf("ep-2"), server.deleted)
        assertEquals(listOf("ep-2"), events.map { it.itemId })
        assertEquals(MenuMessage(T.mediaMenu.mediaDeletedSuccessfully), menu.message.value)
    }

    @Test
    fun warnsAboutEpisodesSharingTheFileAndReportsThemDeleted() = runTest {
        val server = plex()
        admins += server.serverId
        val file = "/tv/bb/S01E02-E03.mkv"
        server.files("ep-2" to listOf(file), "ep-3" to listOf(file))
        val events = collect(deletions)
        val menu = menu()
        menu.opened(episode)
        menu.select(DELETE_MEDIA)
        advanceUntilIdle()

        val warning = assertIs<MenuPrompt.Confirm>(menu.prompt.value).warning
        assertEquals("${T.mediaMenu.deleteSharedFileHeading(n = 1)}\n\u2022 Breaking Bad · S1 E3 · Episode 3", warning)
        menu.confirm(true)
        advanceUntilIdle()

        assertEquals(listOf("ep-2"), server.deleted)
        assertEquals(listOf("ep-2", "ep-3"), events.map { it.itemId })
    }

    @Test
    fun warnsWhenTheEpisodeIsSplitAcrossSeveralFiles() = runTest {
        val server = plex()
        admins += server.serverId
        server.files("ep-2" to listOf("/a-cd1.mkv", "/a-cd2.mkv"))
        val menu = menu()
        menu.opened(episode)
        menu.select(DELETE_MEDIA)
        advanceUntilIdle()

        assertEquals(T.mediaMenu.deleteMultiPartWarning(n = 2), assertIs<MenuPrompt.Confirm>(menu.prompt.value).warning)
    }

    @Test
    fun refusesToImplySingleFileScopeWhenTheServerWithholdsPaths() = runTest {
        val server = plex()
        admins += server.serverId
        server.files("ep-2" to listOf(null))
        val menu = menu()
        menu.opened(episode)
        menu.select(DELETE_MEDIA)
        advanceUntilIdle()

        val confirm = assertIs<MenuPrompt.Confirm>(menu.prompt.value)
        assertEquals(T.mediaMenu.deleteScopeUnverifiedNoFileInfo, confirm.warning)
        assertEquals(T.mediaMenu.deleteAnyway, confirm.confirmLabel)
    }

    @Test
    fun flagsAnUnverifiedScopeWhenTheSiblingLookupFailsAndStillDeletes() = runTest {
        val server = plex()
        admins += server.serverId
        server.files("ep-2" to listOf("/a.mkv"))
        server.children = { throw IllegalStateException("500") }
        val menu = menu()
        menu.opened(episode)
        menu.select(DELETE_MEDIA)
        advanceUntilIdle()

        assertEquals(T.mediaMenu.deleteScopeUnverifiedProbeFailed, assertIs<MenuPrompt.Confirm>(menu.prompt.value).warning)
        menu.confirm(true)
        advanceUntilIdle()
        assertEquals(listOf("ep-2"), server.deleted)
    }

    // Play.

    @Test
    fun playFromBeginningStartsAtZero() = runTest {
        plex()
        val menu = menu()
        menu.opened(episode.copy(viewOffsetMs = 600_000, durationMs = 2_700_000))

        menu.select(PLAY_FROM_BEGINNING)
        advanceUntilIdle()

        assertEquals(Duration.ZERO, plays.single().startPosition)
        assertEquals(0L, plays.single().item?.viewOffsetMs)
    }

    @Test
    fun playVersionPlaysThePickedVersionStrictly() = runTest {
        val server = plex()
        server.capabilities = server.capabilities.copy(videoTranscoding = false)
        val menu = menu()
        val versions = listOf(MediaVersion("v-1", videoResolution = "1080"), MediaVersion("v-2", videoResolution = "4k"))
        menu.opened(episode.copy(mediaVersions = versions))

        menu.select(PLAY_VERSION)
        runCurrent()
        assertEquals(2, assertIs<MenuPrompt.Options>(menu.prompt.value).options.size)
        menu.choose(1)
        advanceUntilIdle()

        assertEquals(1, plays.single().mediaIndex)
        assertTrue(plays.single().strictMediaSelection)
    }

    @Test
    fun playVersionsSubmenuPlaysTheVersionAndQualityPicked() = runTest {
        val server = plex()
        server.capabilities = server.capabilities.copy(videoTranscoding = true)
        val menu = menu()
        val versions = listOf(MediaVersion("v-1", videoResolution = "1080"), MediaVersion("v-2", videoResolution = "4k"))
        val entry = menu.opened(episode.copy(mediaVersions = versions)).single { it.id == PLAY_VERSION }

        assertEquals(listOf("play_version_0", "play_version_1"), ids(entry.children))
        val qualities = entry.children[1].children
        assertEquals(TranscodeQualityPreset.displayOrder.map { "play_version_1_${it.name}" }, ids(qualities))
        assertTrue((entry.children + qualities).all { it.icon == null }, "versions and qualities carry no symbol of their own")
        menu.select("play_version_1_${TranscodeQualityPreset.displayOrder[2].name}")
        advanceUntilIdle()

        assertEquals(null, menu.prompt.value)
        assertEquals(1, plays.single().mediaIndex)
        assertEquals(TranscodeQualityPreset.displayOrder[2], plays.single().qualityPreset)
        assertTrue(plays.single().strictMediaSelection)
    }

    @Test
    fun playVersionsSubmenuOfOneVersionListsItsQualities() = runTest {
        val server = plex()
        server.capabilities = server.capabilities.copy(videoTranscoding = true)
        val menu = menu()
        val entry = menu.opened(episode.copy(mediaVersions = listOf(MediaVersion("v-1")))).single { it.id == PLAY_VERSION }

        assertEquals(TranscodeQualityPreset.displayOrder.map { "play_version_0_${it.name}" }, ids(entry.children))
    }

    @Test
    fun playVersionSubmenuAndPromptsCheckTheVersionAndQualityPlayPlays() = runTest {
        val server = plex()
        server.capabilities = server.capabilities.copy(videoTranscoding = true)
        val current = TranscodeQualityPreset.displayOrder[3]
        val menu = menu(savedVersion = { 1 }, currentQuality = { current })
        val versions = listOf(MediaVersion("v-1", videoResolution = "1080", bitrate = 8000), MediaVersion("v-2", videoResolution = "4k", bitrate = 214))
        val expected = PlayerStates.offeredQualities(214, 2160, current)
        val entry = menu.opened(episode.copy(mediaVersions = versions)).single { it.id == PLAY_VERSION }

        assertEquals(listOf(false, true), entry.children.map { it.selected }, "the saved version is checked")
        val qualities = entry.children[1].children
        assertEquals(expected.map { it.label }, qualities.map { it.label })
        assertEquals(expected.map { it.selected }, qualities.map { it.selected })
        assertEquals(3, qualities.indexOfFirst { it.selected }, "the quality Play plays at is checked")
        assertEquals(PlayerStates.offeredQualities(8000, 1080, current).map { it.selected }, entry.children[0].children.map { it.selected }, "another version's qualities check it too")

        menu.select(PLAY_VERSION)
        runCurrent()
        val versionPrompt = assertIs<MenuPrompt.Options>(menu.prompt.value)
        assertEquals(listOf(false, true), versionPrompt.options.map { it.selected })
        menu.choose(1)
        runCurrent()
        val qualityPrompt = assertIs<MenuPrompt.Options>(menu.prompt.value)
        assertEquals(expected.map { it.label }, qualityPrompt.options.map { it.label })
        assertEquals(expected.map { it.selected }, qualityPrompt.options.map { it.selected })
        menu.choose(2)
        advanceUntilIdle()

        assertEquals(1, plays.single().mediaIndex)
        assertEquals(expected[2].preset, plays.single().qualityPreset)
    }

    @Test
    fun anotherVersionsQualityPromptChecksTheQualityPlayPlaysAt() = runTest {
        val server = plex()
        server.capabilities = server.capabilities.copy(videoTranscoding = true)
        val current = TranscodeQualityPreset.displayOrder[3]
        val menu = menu(currentQuality = { current })
        val versions = listOf(MediaVersion("v-1", videoResolution = "1080"), MediaVersion("v-2", videoResolution = "4k"))
        menu.opened(episode.copy(mediaVersions = versions))

        menu.select(PLAY_VERSION)
        runCurrent()
        menu.choose(1)
        runCurrent()

        val qualities = assertIs<MenuPrompt.Options>(menu.prompt.value).options
        assertEquals(3, qualities.indexOfFirst { it.selected }, "the version Play doesn't play lists the quality checked")
    }

    @Test
    fun aPeekedPlayVersionChecksTheQualityPlayPlaysAt() = runTest {
        val server = plex()
        server.capabilities = server.capabilities.copy(videoTranscoding = true)
        val current = TranscodeQualityPreset.displayOrder[3]
        val menu = menu(currentQuality = { current })
        val item = episode.copy(mediaVersions = listOf(MediaVersion("v-1"), MediaVersion("v-2")))
        fun checked() = assertNotNull(menu.peek { menu.open(item) }).entries.single { it.id == PLAY_VERSION }
            .children.map { version -> version.children.indexOfFirst { it.selected } }
        val revision = menu.revision.value
        checked()
        advanceUntilIdle()

        assertTrue(menu.revision.value > revision, "the peeked menus are read again")
        assertEquals(listOf(3, 3), checked(), "every version's qualities check the quality Play plays at")
    }

    @Test
    fun playVersionHidesPresetsTheSourceFitsUnderAndPicksByPreset() = runTest {
        val server = plex()
        server.capabilities = server.capabilities.copy(videoTranscoding = true)
        val menu = menu()
        val small = MediaVersion("v-1", height = 480, bitrate = 1200)
        val entry = menu.opened(episode.copy(mediaVersions = listOf(small))).single { it.id == PLAY_VERSION }
        val offered = PlayerStates.offeredQualities(1200, 480, TranscodeQualityPreset.ORIGINAL).map { it.preset }

        assertEquals(offered.map { "play_version_0_${it.name}" }, ids(entry.children))
        assertTrue(TranscodeQualityPreset.P1080_20MBPS !in offered && TranscodeQualityPreset.P320_720 in offered)
        menu.select(entry.children[1].id)
        advanceUntilIdle()
        assertEquals(offered[1], plays.single().qualityPreset, "the row picked plays, whatever rows are hidden before it")
    }

    @Test
    fun playVersionListsEveryQualityWhateverTheSourceBitrate() = runTest {
        val server = plex()
        server.capabilities = server.capabilities.copy(videoTranscoding = true)
        val menu = menu()
        val entry = menu.opened(episode.copy(mediaVersions = listOf(MediaVersion("v-1", bitrate = 214)))).single { it.id == PLAY_VERSION }

        assertEquals(TranscodeQualityPreset.displayOrder.size, entry.children.size, "presets above the source stay offered")
        assertEquals(listOf(true) + List(entry.children.size - 1) { false }, entry.children.map { it.selected }, "the original by default")
    }

    // Order, extras and the entries' actions.

    @Test
    fun everyEntryOfAnItemMenuKeepsItsPlace() {
        fun slot(id: String) = listOf(MenuEntry(id, id, MenuIcon.INFO))
        val provided = mapOf(
            MenuSlot.MUSIC to slot("music"),
            MenuSlot.RATE to slot("rate"),
            MenuSlot.METADATA to slot("edit"),
            MenuSlot.DOWNLOADS to slot("download"),
            MenuSlot.WATCHLIST to slot("watchlist"),
        )
        val gates = MenuGates(
            isAdmin = true,
            canTranscode = true,
            serverOnline = true,
            canRemoveFromContinueWatching = true,
            canDeleteFromServer = true,
            externalPlayers = true,
        )
        val inProgress = episode.copy(viewOffsetMs = 600_000, durationMs = 2_700_000)

        assertEquals(
            listOf(
                PLAY_FROM_BEGINNING, WATCH, UNWATCH, "rate", "watchlist", SERIES, PLAY_TRAILER, "download", ADD_TO, REMOVE_FROM_COLLECTION,
                PLAY_VERSION, PLAY_EXTERNAL, FILE_INFO, SHOW_LINK, "edit", DELETE_MEDIA,
            ),
            ids(itemMenuEntries(inProgress, MenuPlace(collectionId = "c-1"), gates, provided, trailer = true)),
        )
        assertEquals(
            listOf(PLAY_FROM_BEGINNING, WATCH, UNWATCH, "rate", "watchlist", REMOVE_FROM_CONTINUE_WATCHING, DETAILS, "download"),
            ids(itemMenuEntries(inProgress, MenuPlace(continueWatching = true), gates, provided)).take(8),
        )
        val season = MediaItem("s-1", BackendKind.PLEX, MediaKind.SEASON, title = "Season 1", parentId = "show-1", serverId = "plex")
        val seasonIds = ids(itemMenuEntries(season, MenuPlace(), gates, provided))
        assertEquals(seasonIds.indexOf(SERIES) + 1, seasonIds.indexOf(SHUFFLE_PLAY))
        val album = MediaItem("al-1", BackendKind.PLEX, MediaKind.ALBUM, title = "Album", serverId = "plex")
        val albumIds = ids(itemMenuEntries(album, MenuPlace(continueWatching = true), gates, provided))
        assertEquals("music", albumIds.first())
        assertFalse("rate" in albumIds || DETAILS in albumIds || ADD_TO in albumIds, "$albumIds")
    }

    @Test
    fun eachKindsMenuOffersItsEntriesInTheReviewedOrder() {
        fun slot(id: String) = listOf(MenuEntry(id, id, MenuIcon.INFO))
        val provided = mapOf(
            MenuSlot.RATE to slot("rate"),
            MenuSlot.METADATA to slot("edit"),
            MenuSlot.DOWNLOADS to slot("download"),
            MenuSlot.WATCHLIST to slot("watchlist"),
        )
        val gates = MenuGates(
            isAdmin = true,
            canTranscode = true,
            serverOnline = true,
            canRemoveFromContinueWatching = true,
            canDeleteFromServer = true,
            externalPlayers = true,
        )
        val movie = MediaItem("m-1", BackendKind.PLEX, MediaKind.MOVIE, title = "Heat", serverId = "plex")
        val show = MediaItem("show-1", BackendKind.PLEX, MediaKind.SHOW, title = "Show", serverId = "plex")
        val season = MediaItem("s-1", BackendKind.PLEX, MediaKind.SEASON, title = "Season 1", parentId = "show-1", serverId = "plex")
        fun order(item: MediaItem, place: MenuPlace = MenuPlace()) = ids(itemMenuEntries(item, place, gates, provided))

        assertEquals(
            listOf(WATCH, "rate", "watchlist", "download", ADD_TO, PLAY_VERSION, PLAY_EXTERNAL, FILE_INFO, SHOW_LINK, "edit", DELETE_MEDIA),
            order(movie),
        )
        assertEquals(
            listOf(WATCH, "rate", "watchlist", SERIES, "download", ADD_TO, PLAY_VERSION, PLAY_EXTERNAL, FILE_INFO, SHOW_LINK, "edit", DELETE_MEDIA),
            order(episode),
        )
        assertEquals(listOf(WATCH, "rate", "watchlist", SHUFFLE_PLAY, "download", ADD_TO, SHOW_LINK, "edit", DELETE_MEDIA), order(show))
        assertEquals(
            listOf(WATCH, "rate", "watchlist", SERIES, SHUFFLE_PLAY, "download", ADD_TO, "edit", DELETE_MEDIA),
            order(season),
        )
        assertEquals(
            listOf(
                WATCH, "rate", "watchlist", REMOVE_FROM_CONTINUE_WATCHING, DETAILS, "download", ADD_TO, PLAY_VERSION, PLAY_EXTERNAL,
                FILE_INFO, SHOW_LINK, "edit", DELETE_MEDIA,
            ),
            order(movie, MenuPlace(continueWatching = true)),
        )
    }

    @Test
    fun aDetailMenuLeavesOutTheEntriesItsRowShowsAsButtons() {
        fun slot(id: String) = listOf(MenuEntry(id, id, MenuIcon.INFO))
        val provided = mapOf(MenuSlot.DOWNLOADS to slot("download"), MenuSlot.WATCHLIST to slot("watchlist"))
        val gates = MenuGates(canTranscode = true, serverOnline = true)
        val movie = MediaItem("m-1", BackendKind.PLEX, MediaKind.MOVIE, title = "Heat", serverId = "plex")
        val everything = RowAction.entries.toSet()

        val full = ids(itemMenuEntries(movie, MenuPlace(), gates, provided, trailer = true))
        assertTrue(listOf(PLAY_TRAILER, WATCH, PLAY_VERSION, "download", "watchlist").all { it in full }, "$full")
        assertEquals(listOf(ADD_TO, FILE_INFO, SHOW_LINK), ids(itemMenuEntries(movie, MenuPlace(), gates, provided, trailer = true, onRow = everything)))
        // A row that shed its download and watched buttons for room: the menu offers them again.
        val narrow = ids(itemMenuEntries(movie, MenuPlace(), gates, provided, trailer = true, onRow = setOf(RowAction.VERSIONS, RowAction.TRAILER)))
        assertEquals(listOf(WATCH, "watchlist", "download", ADD_TO, FILE_INFO, SHOW_LINK), narrow)
        val season = MediaItem("s-1", BackendKind.PLEX, MediaKind.SEASON, title = "Season 1", parentId = "show-1", serverId = "plex")
        assertFalse(SHUFFLE_PLAY in ids(itemMenuEntries(season, MenuPlace(), gates, provided, onRow = setOf(RowAction.SHUFFLE))))
        // The row's watched toggle marks the item the other way from what it is: a partly watched show keeps Unwatched.
        val show = MediaItem("sh-1", BackendKind.PLEX, MediaKind.SHOW, title = "Show", serverId = "plex", leafCount = 4, viewedLeafCount = 1)
        fun marks(item: MediaItem) = ids(itemMenuEntries(item, MenuPlace(), gates, provided, onRow = setOf(RowAction.WATCHED))).filter { it == WATCH || it == UNWATCH }
        assertEquals(listOf(UNWATCH), marks(show))
        assertEquals(emptyList<String>(), marks(show.copy(viewedLeafCount = 4)))
        assertEquals(emptyList<String>(), marks(show.copy(viewedLeafCount = 0)))
        // An album's header row: Play, Instant Mix and the download.
        val music = provided + (MenuSlot.MUSIC to listOf("music_play", "music_play_next", "music_instant_mix").flatMap(::slot))
        val album = MediaItem("al-1", BackendKind.PLEX, MediaKind.ALBUM, title = "Album", serverId = "plex")
        assertEquals(listOf("music_play_next", WATCH), ids(itemMenuEntries(album, MenuPlace(), gates, music, onRow = setOf(RowAction.PLAY, RowAction.INSTANT_MIX, RowAction.DOWNLOAD))).take(2))
        assertFalse("download" in ids(itemMenuEntries(album, MenuPlace(), gates, music, onRow = setOf(RowAction.DOWNLOAD))))
    }

    @Test
    fun musicIsMarkedPlayedOrUnplayedAndVideoWatchedOrUnwatched() {
        val gates = MenuGates(serverOnline = true)
        fun labels(item: MediaItem) = itemMenuEntries(item, MenuPlace(), gates, emptyMap()).filter { it.id == WATCH || it.id == UNWATCH }.map { it.label }
        val track = MediaItem("t-1", BackendKind.PLEX, MediaKind.TRACK, title = "Track", serverId = "plex")
        val movie = MediaItem("m-1", BackendKind.PLEX, MediaKind.MOVIE, title = "Heat", serverId = "plex")

        assertEquals(listOf(T.mediaMenu.markAsPlayed), labels(track))
        assertEquals(listOf(T.mediaMenu.markAsUnplayed), labels(track.copy(viewCount = 1)))
        for (kind in listOf(MediaKind.ALBUM, MediaKind.ARTIST)) assertEquals(listOf(T.mediaMenu.markAsPlayed), labels(track.copy(kind = kind)), "$kind")
        assertEquals(listOf(T.mediaMenu.markAsWatched), labels(movie))
        assertEquals(listOf(T.mediaMenu.markAsUnwatched), labels(movie.copy(viewCount = 1)))
    }

    @Test
    fun aCallersExtraEntriesComeLastAndRunTheirOwnAction() = runTest {
        plex()
        var ran = 0
        val menu = menu()
        menu.open(episode, extras = listOf(MenuExtra("sleep_timer", "Sleep timer", MenuIcon.TIMER) { ran++ }))
        advanceUntilIdle()
        assertEquals("sleep_timer", ids(menu.menu.value!!.entries).last())

        menu.select("sleep_timer")
        advanceUntilIdle()
        assertEquals(1, ran)
        assertTrue(plays.isEmpty())
        assertNull(menu.message.value)
    }

    @Test
    fun aLeadingExtraOpensFirstAndTheOthersStayLast() = runTest {
        val server = plex()
        admins += server.serverId
        val show = MediaItem("show-1", BackendKind.PLEX, MediaKind.SHOW, title = "Breaking Bad", serverId = "plex")
        val menu = menu()
        val extras = listOf(
            MenuExtra("sleep_timer", "Sleep timer", MenuIcon.TIMER) {},
            MenuExtra("from_start", "Play from beginning", MenuIcon.REPLAY, leading = true) {},
        )
        menu.open(show, extras = extras)
        advanceUntilIdle()

        val ids = ids(menu.menu.value!!.entries)
        assertEquals(listOf("from_start", WATCH), ids.take(2))
        assertEquals(listOf(DELETE_MEDIA, "sleep_timer"), ids.takeLast(2))
    }

    @Test
    fun viewDetailsIsOnlyForVideoInContinueWatchingAndOpensTheDetail() = runTest {
        plex()
        val menu = menu()
        assertFalse(DETAILS in ids(menu.opened(episode)))
        val album = MediaItem("al-1", BackendKind.PLEX, MediaKind.ALBUM, title = "Album", serverId = "plex")
        assertFalse(DETAILS in ids(menu.opened(album, MenuPlace(continueWatching = true))))

        menu.opened(episode, MenuPlace(continueWatching = true))
        menu.select(DETAILS)
        advanceUntilIdle()
        assertEquals(
            Route.MediaDetail(ServerId("plex"), "show-1", initialSeasonId = "season-1", initialEpisodeId = "ep-2"),
            navigator.backStack.value.last(),
        )
    }

    @Test
    fun shufflePlayOnAShowLaunchesItsShuffledQueueBehindASpinner() = runTest {
        plex()
        val launches = mutableListOf<QueueLaunch>()
        val gate = CompletableDeferred<Unit>()
        val menu = menu(launchQueue = { launches += it; PlayQueueLaunch("Shuffling", foreground()) { gate.await(); PlayQueueResult.Success } })
        val show = MediaItem("show-1", BackendKind.PLEX, MediaKind.SHOW, title = "Breaking Bad", serverId = "plex")
        menu.opened(show)

        menu.select(SHUFFLE_PLAY)
        runCurrent()
        assertEquals(listOf<QueueLaunch>(QueueLaunch.ShuffledShow(show)), launches)
        assertEquals(MenuPrompt.Busy("Shuffling", cancellable = true), menu.prompt.value)

        gate.complete(Unit)
        advanceUntilIdle()
        assertNull(menu.prompt.value)
    }

    @Test
    fun fileInfoShowsTheServersAnswerBehindASpinnerOrSaysThereIsNone() = runTest {
        val server = plex()
        val gate = CompletableDeferred<Unit>()
        val info = MediaFileInfo(versions = listOf(MediaFileVersion(id = "v-1")))
        server.fileInfo = { gate.await(); info }
        val menu = menu()
        menu.opened(movie(server))

        menu.select(FILE_INFO)
        runCurrent()
        assertEquals(MenuPrompt.Busy(), menu.prompt.value)
        gate.complete(Unit)
        runCurrent()
        assertEquals(MenuPrompt.FileInfo("Heat", info), menu.prompt.value)
        menu.closePrompt()
        advanceUntilIdle()
        assertNull(menu.prompt.value)

        server.fileInfo = { null }
        menu.opened(movie(server))
        menu.select(FILE_INFO)
        advanceUntilIdle()
        assertEquals(MenuMessage(T.messages.fileInfoNotAvailable, isError = true), menu.message.value)
    }

    @Test
    fun playInExternalPlayerNeedsAPlayerAppAndAMovieOrEpisode() = runTest {
        val server = plex()
        assertFalse(PLAY_EXTERNAL in ids(menu().opened(movie(server))))

        val opened = mutableListOf<String>()
        val menu = menu(playExternal = { opened += it.id; "No player" })
        assertTrue(PLAY_EXTERNAL in ids(menu.opened(movie(server))))
        assertTrue(PLAY_EXTERNAL in ids(menu.opened(episode)))
        assertFalse(PLAY_EXTERNAL in ids(menu.opened(movie(server).copy(kind = MediaKind.SHOW))))

        menu.opened(movie(server))
        menu.select(PLAY_EXTERNAL)
        advanceUntilIdle()
        assertEquals(listOf("m-1"), opened)
        assertEquals(MenuMessage("No player", isError = true), menu.message.value)
    }

    @Test
    fun markAsUnwatchedSaysSoAndAnOfflineMarkIsQueuedAndSaysSo() = runTest {
        val server = plex()
        server.markUnwatchedHandler = { }
        val menu = menu()
        menu.opened(episode.copy(viewCount = 1))
        menu.select(UNWATCH)
        advanceUntilIdle()
        assertEquals(MenuMessage(T.messages.markedAsUnwatched), menu.message.value)

        offlineMode.isOffline.value = true
        menu.opened(episode)
        menu.select(WATCH)
        advanceUntilIdle()
        assertEquals(MenuMessage(T.messages.markedAsWatchedOffline), menu.message.value)
        assertTrue(server.calls.none { it.startsWith("markWatched") }, "${server.calls}")
    }

    // Collections and playlists.

    @Test
    fun removeFromCollectionSaysWhetherItWorkedAndCancellingRemovesNothing() = runTest {
        val server = plex()
        val menu = menu()
        fun removeConfirmed(accept: Boolean) {
            menu.opened(episode, MenuPlace(collectionId = "c-1"))
            menu.select(REMOVE_FROM_COLLECTION)
            runCurrent()
            menu.confirm(accept)
            advanceUntilIdle()
        }

        removeConfirmed(false)
        assertTrue(server.removed.isEmpty())

        removeConfirmed(true)
        assertEquals(MenuMessage(T.collections.removedFromCollection), menu.message.value)

        server.removeAnswer = { false }
        removeConfirmed(true)
        assertEquals(MenuMessage(T.collections.removeFromCollectionFailed, isError = true), menu.message.value)

        server.removeAnswer = { throw IllegalStateException("500") }
        removeConfirmed(true)
        val failure = menu.message.value!!
        assertTrue(failure.isError)
        assertTrue(failure.text != T.collections.removeFromCollectionFailed, failure.text)
    }

    @Test
    fun deletingACollectionAsksThenDeletesSaysSoAndRefreshesCollections() = runTest {
        val server = plex()
        val changes = collect(refresh)
        val menu = menu()
        val collection = MediaItem("col-1", BackendKind.PLEX, MediaKind.COLLECTION, title = "Bond", serverId = "plex")
        assertEquals(listOf(PLAY, SHUFFLE, DELETE), ids(menu.opened(collection)))

        menu.select(DELETE)
        runCurrent()
        val confirm = assertIs<MenuPrompt.Confirm>(menu.prompt.value)
        assertEquals(T.collections.deleteCollection, confirm.title)
        assertEquals(T.collections.deleteConfirm(title = "Bond"), confirm.message)
        menu.confirm(true)
        advanceUntilIdle()
        assertEquals(listOf("col-1"), server.deletedCollections)
        assertEquals(MenuMessage(T.collections.deleted), menu.message.value)
        assertEquals(listOf(LibraryRefreshType.COLLECTIONS), changes)

        server.deleteCollectionAnswer = { false }
        menu.opened(collection)
        menu.select(DELETE)
        runCurrent()
        menu.confirm(true)
        advanceUntilIdle()
        assertEquals(MenuMessage(T.collections.deleteFailed, isError = true), menu.message.value)
        assertEquals(listOf(LibraryRefreshType.COLLECTIONS), changes)
    }

    @Test
    fun deletingAPlaylistFromItsMenuAsksThenDeletesAndRefreshesPlaylists() = runTest {
        val server = plex()
        val changes = collect(refresh)
        val menu = menu()
        val playlist = MediaPlaylist("pl-1", BackendKind.PLEX, "Mix", "video", serverId = "plex")
        fun delete(accept: Boolean) {
            menu.open(playlist)
            runCurrent()
            menu.select(DELETE)
            runCurrent()
            assertEquals(T.playlists.delete, assertIs<MenuPrompt.Confirm>(menu.prompt.value).title)
            menu.confirm(accept)
            advanceUntilIdle()
        }

        delete(false)
        assertTrue(server.deletedPlaylists.isEmpty())
        delete(true)
        assertEquals(listOf("pl-1"), server.deletedPlaylists)
        assertEquals(MenuMessage(T.playlists.deleted), menu.message.value)
        assertEquals(listOf(LibraryRefreshType.PLAYLISTS), changes)
    }

    @Test
    fun thePlaylistPickerAsksForVideoPlaylistsAndGreysOutSmartOnes() = runTest {
        val server = jellyfin(permission = { false })
        server.playlists = listOf(
            MediaPlaylist("pl-1", BackendKind.JELLYFIN, "One", "video", leafCount = 1),
            MediaPlaylist("pl-2", BackendKind.JELLYFIN, "Auto", "video", smart = true, leafCount = 5),
        )
        val menu = menu()
        menu.opened(movie(server))
        menu.select(ADD_TO)
        runCurrent()
        val picker = assertIs<MenuPrompt.Picker>(menu.prompt.value).picker

        assertEquals(listOf<Pair<String, Boolean?>>("video" to false), server.playlistQueries)
        assertEquals(
            listOf(
                PickerRow("pl-1", "One", T.playlists.oneItem, MenuIcon.PLAYLIST),
                PickerRow("pl-2", "Auto", T.playlists.itemCount(count = "5"), MenuIcon.SMART_PLAYLIST, enabled = false),
            ),
            picker.state.value.rows,
        )
        picker.pick("pl-2")
        runCurrent()
        assertTrue(server.added.isEmpty())

        picker.cancel()
        advanceUntilIdle()
        assertNull(menu.prompt.value)
        assertNull(menu.message.value)
    }

    @Test
    fun thePickerLoadsAHundredAtATimeKeepsLoadingWhileFilteringAndRetriesAfterAnError() = runTest {
        val pages = mutableListOf<Int>()
        var failing = true
        val rows = (1..250).map { PickerRow("r$it", if (it == 230) "Road Trip" else "List $it", null, MenuIcon.PLAYLIST) }
        val picker = ContainerPicker("Pick", "Search", "None", { start, size ->
            assertEquals(100, size)
            pages += start
            if (failing) throw IllegalStateException("offline")
            LibraryPage(rows.drop(start).take(size), rows.size, start)
        }, foreground())
        runCurrent()
        assertTrue(picker.state.value.error != null)
        assertTrue(picker.state.value.rows.isEmpty())

        failing = false
        picker.retry()
        runCurrent()
        assertEquals(listOf(0, 0), pages)
        assertNull(picker.state.value.error)
        assertEquals(100, picker.state.value.rows.size)
        assertTrue(picker.state.value.hasMore && picker.state.value.showFilter)

        picker.filter("ROAD")
        runCurrent()
        assertEquals(listOf(0, 0, 100, 200), pages)
        assertEquals(listOf("r230"), picker.state.value.rows.map { it.id })
        assertFalse(picker.state.value.hasMore)

        val answer = async { picker.await() }
        picker.createNew()
        assertEquals(PickerResult.CreateNew, answer.await())
    }

    @Test
    fun aCollectionAddFindsTheLibraryThroughTheShowThenAddsToOneOrCreatesIt() = runTest {
        val server = plex()
        admins += server.serverId
        server.items = { id -> if (id == "show-1") MediaItem("show-1", BackendKind.PLEX, MediaKind.SHOW, title = "Breaking Bad", libraryId = "7", serverId = "plex") else null }
        server.collections = listOf(MediaItem("c-1", BackendKind.PLEX, MediaKind.COLLECTION, title = "Faves", childCount = 1, serverId = "plex"))
        val changes = collect(refresh)
        val menu = menu()
        val noLibrary = episode.copy(libraryId = null)
        fun collectionPicker(): ContainerPicker {
            menu.opened(noLibrary)
            menu.select(ADD_TO)
            runCurrent()
            menu.choose(1)
            runCurrent()
            return assertIs<MenuPrompt.Picker>(menu.prompt.value).picker
        }

        val picker = collectionPicker()
        assertEquals(listOf("7"), server.collectionQueries)
        assertEquals(listOf(PickerRow("c-1", "Faves", T.playlists.oneItem, MenuIcon.COLLECTION)), picker.state.value.rows)
        picker.pick("c-1")
        advanceUntilIdle()
        assertEquals(listOf("c-1" to "ep-2"), server.addedToCollection)
        assertEquals(MenuMessage(T.collections.addedToCollection), menu.message.value)

        collectionPicker().createNew()
        runCurrent()
        val name = assertIs<MenuPrompt.TextInput>(menu.prompt.value)
        assertEquals(T.common.createNew, name.title)
        assertEquals(T.collections.collectionName, name.label)
        menu.submit(" Heisenberg ")
        advanceUntilIdle()
        assertEquals(listOf("7/Heisenberg/ep-2/EPISODE"), server.createdCollections)
        assertEquals(MenuMessage(T.collections.created), menu.message.value)
        assertEquals(listOf(LibraryRefreshType.COLLECTIONS, LibraryRefreshType.COLLECTIONS), changes)
    }

    private fun TestScope.menu(
        providers: List<MenuEntryProvider> = emptyList(),
        launchQueue: (QueueLaunch) -> PlayQueueLaunch = { throw AssertionError("no queue launch expected") },
        playAudioPlaylist: (suspend (MediaPlaylist, Boolean, MediaItem?) -> Boolean)? = null,
        playExternal: (suspend (MediaItem) -> String?)? = null,
        savedVersion: (suspend (MediaItem) -> Int?)? = null,
        currentQuality: (suspend () -> TranscodeQualityPreset)? = null,
    ): MediaMenu {
        val notifier = WatchStateNotifier()
        val trackers = RecordingTrackers()
        val sync = OfflineWatchSyncService(
            InMemoryOfflineWatchQueue(), FakeOfflineWatchDownloads(), clients, notifier, trackers,
            thresholds = object : WatchedThresholdSource {
                override fun reportsServerThreshold(client: com.edde746.plezy.backend.MediaBackend): Boolean = false
                override fun cachedPercent(serverId: ServerId): Int? = null
            },
            offlineMode = offlineMode,
            scope = backgroundScope,
            minSyncInterval = Duration.ZERO,
            forceSyncOnResume = false,
            timeSource = testScheduler.timeSource,
        )
        val offlineWatch = OfflineWatchProvider(sync, FakeOfflineWatchDownloads(), notifier, backgroundScope, { SpecialsOrdering.SPECIALS_LAST }, { false })
        val watchState = WatchStateStore(notifier, backgroundScope)
        scope = this
        return MediaMenu(
            navigator = navigator,
            client = clients::client,
            isOnline = { it in online },
            isOwnerOrAdmin = { it in admins },
            activeProfile = { profile ?: LocalProfile("p", "Me", createdAt = 0) },
            isOffline = { false },
            hasMultipleProfiles = { multipleProfiles },
            fresh = watchState::apply,
            watchStateChanges = watchState.changes,
            watchActions = WatchActions(clients, offlineMode, offlineWatch, notifier, trackers, backgroundScope),
            deletions = deletions,
            libraryRefresh = refresh,
            addedToList = { server, list -> addedToLists += server to list },
            play = { plays += it },
            launchQueue = launchQueue,
            scope = foreground(),
            providers = providers,
            playAudioPlaylist = playAudioPlaylist,
            playExternal = playExternal,
            savedVersion = savedVersion,
            currentQuality = currentQuality,
        )
    }

    /** Work [advanceUntilIdle] runs (it skips backgroundScope's), cancelled with the test. */
    private fun TestScope.foreground() = CoroutineScope(StandardTestDispatcher(testScheduler) + Job(backgroundScope.coroutineContext[Job]))

    /** The test the menu runs in, for [opened]. */
    private lateinit var scope: TestScope

    /** Opens [item]'s menu afresh and answers its entries. */
    private fun MediaMenu.opened(item: MediaItem, place: MenuPlace = MenuPlace()): List<MenuEntry> {
        dismiss()
        open(item, place)
        scope.advanceUntilIdle()
        return menu.value!!.entries
    }

    private fun ids(entries: List<MenuEntry>) = entries.map { it.id }

    /** A Plex server whose Allow media deletion switch answers [permission] (on unless said). */
    private fun plex(id: String = "plex", permission: suspend () -> Boolean = { true }): MenuBackend =
        MenuBackend(id, BackendKind.PLEX, permission).also(::register)

    private fun jellyfin(permission: suspend () -> Boolean): MenuBackend = MenuBackend("jf", BackendKind.JELLYFIN, permission).also(::register)

    private fun register(server: MenuBackend) {
        clients.register(server)
        online += server.serverId
    }

    private fun movie(server: MenuBackend) =
        MediaItem("m-1", server.backend, MediaKind.MOVIE, title = "Heat", serverId = server.serverId.value, libraryId = "1")

    private fun TestScope.collect(notifier: LibraryRefreshNotifier): List<LibraryRefreshType> {
        val events = mutableListOf<LibraryRefreshType>()
        foreground().launch { notifier.events.collect { events += it } }
        runCurrent()
        return events
    }

    private fun TestScope.collect(notifier: DeletionNotifier): List<DeletionEvent> {
        val events = mutableListOf<DeletionEvent>()
        foreground().launch { notifier.events.collect { events += it } }
        runCurrent()
        return events
    }

    /** A server with playlists, collections and deletions scripted, and the delete answer of [permission]. */
    class MenuBackend(id: String, backend: BackendKind, private val permission: (suspend () -> Boolean)? = null) :
        FakeMediaBackend(id, backend), MediaDeletionPermission {
        var playlists: List<MediaPlaylist> = emptyList()
        val playlistQueries = mutableListOf<Pair<String, Boolean?>>()
        val added = mutableListOf<Pair<String, String>>()
        val created = mutableListOf<Pair<String, List<String>>>()
        val removed = mutableListOf<Pair<String, String>>()
        val deleted = mutableListOf<String>()
        var removeAnswer: suspend () -> Boolean = { true }
        var deleteAnswer: suspend () -> Boolean = { true }
        var collections: List<MediaItem> = listOf(MediaItem("col-1", backend, MediaKind.COLLECTION, title = "Heist"))
        val collectionQueries = mutableListOf<String>()
        val addedToCollection = mutableListOf<Pair<String, String>>()
        val createdCollections = mutableListOf<String>()
        var deleteCollectionAnswer: suspend () -> Boolean = { true }
        val deletedCollections = mutableListOf<String>()
        val deletedPlaylists = mutableListOf<String>()
        var fileInfo: suspend () -> MediaFileInfo? = { null }

        /** The answer the item's list carried ([MediaDeletionPermission.carriedDeletePermission]). */
        var carried: Boolean? = null

        override suspend fun fetchDeletePermission(item: MediaItem): Boolean? = permission?.invoke()

        override fun carriedDeletePermission(item: MediaItem): Boolean? = carried

        override suspend fun fetchPlaylistsPage(playlistType: String, smart: Boolean?, start: Int?, size: Int?): LibraryPage<MediaPlaylist> {
            playlistQueries += playlistType to smart
            val from = start ?: 0
            return LibraryPage(playlists.drop(from).take(size ?: playlists.size), playlists.size, from)
        }

        override suspend fun addToPlaylist(playlistId: String, items: List<MediaItem>): Boolean {
            items.forEach { added += playlistId to it.id }
            return true
        }

        override suspend fun createPlaylist(title: String, items: List<MediaItem>): MediaPlaylist {
            created += title to items.map { it.id }
            return MediaPlaylist("new", backend, title, "video")
        }

        override suspend fun deletePlaylist(playlist: MediaPlaylist): Boolean {
            deletedPlaylists += playlist.id
            return true
        }

        override suspend fun fetchCollectionsPage(libraryId: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
            collectionQueries += libraryId
            val from = start ?: 0
            return LibraryPage(collections.drop(from).take(size ?: collections.size), collections.size, from)
        }

        override suspend fun createCollection(libraryId: String, title: String, items: List<MediaItem>, itemKind: MediaKind?): String {
            createdCollections += "$libraryId/$title/${items.joinToString { it.id }}/$itemKind"
            return "col-new"
        }

        override suspend fun addToCollection(collectionId: String, items: List<MediaItem>): Boolean {
            items.forEach { addedToCollection += collectionId to it.id }
            return true
        }

        override suspend fun removeFromCollection(collectionId: String, item: MediaItem): Boolean {
            removed += collectionId to item.id
            return removeAnswer()
        }

        override suspend fun deleteCollection(collection: MediaItem): Boolean {
            deletedCollections += collection.id
            return deleteCollectionAnswer()
        }

        override suspend fun getFileInfo(item: MediaItem): MediaFileInfo? = fileInfo()

        override suspend fun deleteMediaItem(item: MediaItem): Boolean {
            val deletedNow = deleteAnswer()
            if (deletedNow) deleted += item.id
            return deletedNow
        }

        /** The season's episodes with these files (a null path withheld), both as rows and from the detail endpoint. */
        fun files(vararg episodes: Pair<String, List<String?>>) {
            val rows = episodes.map { (id, files) ->
                val index = id.removePrefix("ep-").toInt()
                MediaItem(
                    id, backend, MediaKind.EPISODE, title = "Episode $index", index = index, parentIndex = 1, parentId = "season-1",
                    grandparentTitle = "Breaking Bad", serverId = serverId.value,
                    mediaVersions = listOf(MediaVersion("v", parts = files.mapIndexed { i, file -> MediaPart("p$i", file = file) })),
                )
            }
            items = { id -> rows.firstOrNull { it.id == id } }
            children = { rows }
        }
    }
}
