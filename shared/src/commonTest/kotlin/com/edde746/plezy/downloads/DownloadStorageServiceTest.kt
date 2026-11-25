package com.edde746.plezy.downloads

import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.test.runTest
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemPathSeparator
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadStorageServiceTest {
    private val data = testData()
    private val settings = data.deviceSettings
    private val root = StorageRoot()
    private val support = root.support

    @AfterTest
    fun tearDown() {
        data.close()
        root.delete()
    }

    private fun storage(supportsSaf: Boolean = false, excludeFromBackup: ((String) -> Unit)? = null) =
        DownloadStorageService(root.platform(supportsSaf, excludeFromBackup), settings)

    private suspend fun initialized(): DownloadStorageService = storage().also { it.initialize() }

    private fun isDirectory(path: String) = SystemFileSystem.metadataOrNull(Path(path))?.isDirectory == true

    private fun join(vararg parts: String) = LocalPath.join(parts.first(), *parts.drop(1).toTypedArray())

    // SAF mode

    @Test
    fun safModeIsOffWhereThePlatformHasNoStorageAccessFramework() = runTest {
        settings.setCustomDownloadPath("content://com.android.externalstorage.documents/tree/primary%3ADownload", "saf")
        val storage = initialized()

        assertFalse(storage.isUsingSaf)
        assertNull(storage.safBaseUri)
    }

    @Test
    fun safModeWithATreeRootExposesTheBaseUri() = runTest {
        val tree = "content://com.android.externalstorage.documents/tree/primary%3ADownload"
        settings.setCustomDownloadPath(tree, "saf")
        val storage = storage(supportsSaf = true).also { it.initialize() }

        assertTrue(storage.isUsingSaf)
        assertEquals(tree, storage.safBaseUri)
        assertNull(storage.customFileRootPath)
    }

    @Test
    fun isSafUriDetectsContentUrisRegardlessOfPlatform() {
        val storage = storage()
        assertTrue(storage.isSafUri("content://com.android.externalstorage.documents/tree/primary%3ADownload"))
        assertFalse(storage.isSafUri("/var/mobile/Containers/Data/Application/abc/Documents/downloads/x.mkv"))
        assertFalse(storage.isSafUri("file:///tmp/foo"))
    }

    // Downloads directory resolution

    @Test
    fun defaultsToDownloadsInTheBaseDirectory() = runTest {
        val storage = initialized()

        val directory = storage.getDownloadsDirectory()
        assertTrue(isDirectory(directory))
        assertEquals(join(support, "downloads"), directory)
        assertFalse(storage.isUsingCustomPath())
    }

    @Test
    fun honorsAWritableCustomFileTypePath() = runTest {
        val custom = root.path("custom-downloads")
        SystemFileSystem.createDirectories(Path(custom))
        settings.setCustomDownloadPath(custom)
        val storage = initialized()

        assertEquals(custom, storage.getDownloadsDirectory())
        assertTrue(storage.isUsingCustomPath())
        assertEquals(custom, storage.getCurrentDownloadPathDisplay())
    }

    @Test
    fun fallsBackToDefaultWhenCustomPathIsNotWritable() = runTest {
        val blocking = root.path("not-a-directory")
        writeFile(blocking, "blocking ancestor")
        settings.setCustomDownloadPath(join(blocking, "downloads"))
        val storage = initialized()

        val directory = storage.getDownloadsDirectory()
        assertTrue(isDirectory(directory))
        assertEquals(join(support, "downloads"), directory)
    }

    @Test
    fun theWritabilityProbeLeavesNothingBehind() {
        val directory = root.path("probe")
        assertTrue(storage().isDirectoryWritable(directory))
        assertTrue(isDirectory(directory))
        assertEquals(emptyList(), SystemFileSystem.list(Path(directory)).toList())
    }

    @Test
    fun refreshCustomPathPicksUpSettingsChanges() = runTest {
        val storage = initialized()
        assertFalse(storage.isUsingCustomPath())

        val custom = root.path("after-refresh")
        SystemFileSystem.createDirectories(Path(custom))
        settings.setCustomDownloadPath(custom)
        storage.refreshCustomPath()

        assertTrue(storage.isUsingCustomPath())
        assertEquals(custom, storage.getDownloadsDirectory())
    }

    // Artwork directory

    @Test
    fun artworkDefaultsBesideTheDownloadsAndCachesTheSyncPath() = runTest {
        val storage = initialized()

        val artwork = storage.getArtworkDirectory()
        assertTrue(isDirectory(artwork))
        assertEquals(join(support, "artwork"), artwork)
        assertEquals(artwork, storage.artworkDirectoryPath)
    }

    @Test
    fun placesArtworkNextToACustomDownloadsPath() = runTest {
        val custom = root.path("media-root", "downloads")
        SystemFileSystem.createDirectories(Path(custom))
        settings.setCustomDownloadPath(custom)
        val storage = initialized()

        val artwork = storage.getArtworkDirectory()
        assertEquals(root.path("media-root", "artwork"), artwork)
        assertTrue(isDirectory(artwork))
    }

    @Test
    fun artworkStaysInTheDefaultFolderWhenTheCustomFoldersParentIsNotWritable() = runTest {
        val blocking = root.path("not-a-directory")
        writeFile(blocking, "blocking ancestor")
        settings.setCustomDownloadPath(join(blocking, "downloads"))
        val storage = initialized()

        assertEquals(join(support, "artwork"), storage.getArtworkDirectory())
        assertEquals(
            join(support, "artwork", "${DownloadStorageService.md5Hex("srv:/library/metadata/1/thumb")}.jpg"),
            storage.getArtworkPathSync(ServerId("srv"), "/library/metadata/1/thumb"),
        )
    }

    @Test
    fun getArtworkPathSyncReturnsNullBeforeInitializeAndDeduplicatesAfter() = runTest {
        val storage = storage()
        assertNull(storage.artworkDirectoryPath)
        assertNull(storage.getArtworkPathSync(ServerId("srv"), "/library/metadata/1/thumb"))

        storage.initialize()
        val first = storage.getArtworkPathSync(ServerId("srv"), "/library/metadata/1/thumb")
        val again = storage.getArtworkPathSync(ServerId("srv"), "/library/metadata/1/thumb")
        val other = storage.getArtworkPathSync(ServerId("srv"), "/library/metadata/2/thumb")
        assertNotNull(first)
        assertEquals(first, again)
        assertNotEquals(first, other)
        assertTrue(first.endsWith(".jpg"))
    }

    @Test
    fun artworkFileIsNamedByTheMd5OfServerAndKey() = runTest {
        val storage = initialized()
        assertEquals(
            join(support, "artwork", "${DownloadStorageService.md5Hex("srv:/library/metadata/1/thumb")}.jpg"),
            storage.getArtworkPathSync(ServerId("srv"), "/library/metadata/1/thumb"),
        )
    }

    @Test
    fun asyncAndSyncArtworkPathsAgreeForTheSameInput() = runTest {
        val storage = initialized()
        assertEquals(
            storage.getArtworkPathFromThumb(ServerId("srv"), "/library/metadata/9/thumb"),
            storage.getArtworkPathSync(ServerId("srv"), "/library/metadata/9/thumb"),
        )
    }

    @Test
    fun artworkExistsReflectsOnDiskState() = runTest {
        val storage = initialized()
        assertFalse(storage.artworkExists(ServerId("srv"), "/thumb/1"))

        writeFile(storage.getArtworkPathFromThumb(ServerId("srv"), "/thumb/1"), "fake-artwork")
        assertTrue(storage.artworkExists(ServerId("srv"), "/thumb/1"))
    }

    // Backup exclusion

    @Test
    fun initializeMarksTheDefaultDownloadAndArtworkRootsCoveringExistingDownloads() = runTest {
        val excluded = mutableListOf<String>()
        storage(excludeFromBackup = { excluded += it }).initialize()

        assertEquals(setOf(join(support, "downloads"), join(support, "artwork")), excluded.toSet())
    }

    @Test
    fun leavesACustomDownloadFolderAndTheArtworkBesideItUnmarked() = runTest {
        val custom = root.path("media-root", "downloads")
        SystemFileSystem.createDirectories(Path(custom))
        settings.setCustomDownloadPath(custom)
        val excluded = mutableListOf<String>()
        val storage = storage(excludeFromBackup = { excluded += it }).also { it.initialize() }

        assertEquals(custom, storage.getDownloadsDirectory())
        assertEquals(emptyList(), excluded)
    }

    @Test
    fun aRefusedMarkStillResolvesBothRoots() = runTest {
        val storage = storage(excludeFromBackup = { throw IllegalStateException("EXCLUDE_FROM_BACKUP_FAILED") })
        storage.initialize()

        assertEquals(join(support, "downloads"), storage.getDownloadsDirectory())
        assertEquals(join(support, "artwork"), storage.artworkDirectoryPath)
    }

    // toRelativePath / toAbsolutePath

    @Test
    fun stripsTheBaseDirectoryToMakeAPathRelative() = runTest {
        val storage = initialized()
        assertEquals(join("downloads", "srv", "42", "video.mp4"), storage.toRelativePath(join(support, "downloads", "srv", "42", "video.mp4")))
    }

    @Test
    fun returnsAbsolutePathsOutsideTheBaseDirectoryUnchanged() = runTest {
        val storage = initialized()
        val outside = root.path("Volumes", "External", "Movies", "x.mkv")
        assertEquals(outside, storage.toRelativePath(outside))
    }

    @Test
    fun leavesASiblingDirectoryWhoseNameMerelyStartsWithTheBaseDirectoryAlone() = runTest {
        val storage = initialized()
        val outside = join("$support-external", "downloads", "srv", "1", "video.mkv")
        assertEquals(outside, storage.toRelativePath(outside))
    }

    @Test
    fun toAbsolutePathJoinsRelativePathsAgainstTheBaseDirectory() = runTest {
        val storage = initialized()
        assertEquals(join(support, "downloads", "srv", "1", "video.mp4"), storage.toAbsolutePath(join("downloads", "srv", "1", "video.mp4")))
    }

    @Test
    fun toAbsolutePathReturnsAbsolutePathsUnchanged() = runTest {
        val storage = initialized()
        val absolute = root.path("Data", "Movies", "m.mkv")
        assertEquals(absolute, storage.toAbsolutePath(absolute))
    }

    @Test
    fun toRelativePathThenToAbsolutePathRoundTrips() = runTest {
        val storage = initialized()
        val absolute = join(support, "downloads", "srv", "7", "video.mp4")
        assertEquals(absolute, storage.toAbsolutePath(storage.toRelativePath(absolute)))
    }

    // resolveTaskDirectory

    @Test
    fun describesAnAppStorageTargetRelativeToTheBaseDirectory() = runTest {
        val storage = initialized()
        val video = storage.getVideoFilePath(ServerId("srv"), "item-1", "mkv")

        val location = storage.resolveTaskDirectory(video)
        assertEquals(BaseDirectory.APPLICATION_SUPPORT, location.baseDirectory)
        assertEquals(join("downloads", "srv", "item-1"), location.directory)
        assertFalse(LocalPath.isAbsolute(location.directory))
    }

    @Test
    fun reanchorsAnEnqueuedTargetAfterTheAppStorageDirectoryMoves() = runTest {
        val storage = initialized()
        val video = storage.getVideoFilePath(ServerId("srv"), "item-1", "mkv")
        val location = storage.resolveTaskDirectory(video)
        val storedTarget = join(location.directory, LocalPath.basename(video))
        assertEquals(video, storage.toAbsolutePath(storedTarget))

        // The same base directory lookup now resolves somewhere else, and the enqueued target must follow it.
        root.base = root.path("moved", "support")
        assertEquals(root.path("moved", "support", "downloads", "srv", "item-1", "video.mkv"), storage.toAbsolutePath(storedTarget))
    }

    @Test
    fun keepsACustomDownloadRootAbsoluteBecauseItDoesNotMoveWithTheApp() = runTest {
        val custom = root.path("external", "PlezyDownloads")
        settings.setCustomDownloadPath(custom)
        val storage = initialized()

        val video = storage.getVideoFilePath(ServerId("srv"), "item-1", "mkv")
        assertTrue(video.startsWith(custom))
        assertEquals(TaskDirectory(BaseDirectory.ROOT, LocalPath.dirname(video)), storage.resolveTaskDirectory(video))
    }

    @Test
    fun keepsACustomRootThatOnlySharesANamePrefixWithTheBaseDirectory() = runTest {
        val custom = "$support-external"
        settings.setCustomDownloadPath(custom)
        val storage = initialized()

        val video = storage.getVideoFilePath(ServerId("srv"), "item-1", "mkv")
        assertTrue(video.startsWith(custom))
        assertEquals(TaskDirectory(BaseDirectory.ROOT, LocalPath.dirname(video)), storage.resolveTaskDirectory(video))
    }

    // ensureAbsolutePath

    @Test
    fun keepsAnExistingAbsolutePathThatPointsAtARealFile() = runTest {
        val storage = initialized()
        val file = join(storage.getDownloadsDirectory(), "concrete.mkv")
        writeFile(file)
        assertEquals(file, storage.ensureAbsolutePath(file))
    }

    @Test
    fun joinsARelativePathAgainstTheBaseDirectoryAndFindsTheFile() = runTest {
        val storage = initialized()
        val file = join(storage.getDownloadsDirectory(), "rel-found.mkv")
        writeFile(file)
        assertEquals(file, storage.ensureAbsolutePath(join("downloads", "rel-found.mkv")))
    }

    @Test
    fun recoversFromADoubledBaseDirectoryPrefixWhenTheRecoveredFileExists() = runTest {
        val storage = initialized()
        val file = join(support, "downloads", "srv-x", "recovered.mkv")
        writeFile(file)

        val corrupted = "$support$support${SystemPathSeparator}downloads${SystemPathSeparator}srv-x${SystemPathSeparator}recovered.mkv"
        assertEquals(file, storage.ensureAbsolutePath(corrupted))
    }

    @Test
    fun recoversARelativePathHoldingTheBaseDirectoryWithoutItsLeadingSlash() = runTest {
        val storage = initialized()
        val file = join(support, "downloads", "srv", "nested.mkv")
        writeFile(file)

        val corrupted = "data" + join(support, "downloads", "srv", "nested.mkv")
        assertEquals(file, storage.ensureAbsolutePath(corrupted))
    }

    @Test
    fun fallsBackToTheFirstCandidateWhenNothingExistsOnDisk() = runTest {
        val storage = initialized()
        val stored = "downloads/missing/never.mkv"
        assertEquals(LocalPath.normalize(join(support, stored)), storage.ensureAbsolutePath(stored))
    }

    @Test
    fun anAbsolutePathShorterThanTheBaseDirectoryDoesNotThrow() = runTest {
        val storage = initialized()
        val stored = root.root.substring(0, LocalPath.rootLength(root.root)) + "nope.mkv"
        assertEquals(LocalPath.normalize(stored), storage.ensureAbsolutePath(stored))
    }

    // getReadablePath

    @Test
    fun passesContentUrisThroughUnchanged() = runTest {
        val storage = initialized()
        val uri = "content://com.android.externalstorage.documents/tree/primary%3ADownload/document/x"
        assertEquals(uri, storage.getReadablePath(uri))
    }

    @Test
    fun resolvesOtherStoredPathsWithEnsureAbsolutePath() = runTest {
        val storage = initialized()
        val file = join(storage.getDownloadsDirectory(), "readable.mkv")
        writeFile(file)
        assertEquals(file, storage.getReadablePath(join("downloads", "readable.mkv")))
    }

    // SAF path components and names

    @Test
    fun movieComponentsAndFileNameUseASanitizedTitleAndYear() {
        val storage = storage()
        val movie = movie("My/Movie:Name?", 2023)

        assertEquals(listOf("Movies", "MyMovieName (2023)"), storage.getMovieSafPathComponents(movie))
        assertEquals("MyMovieName (2023) ${tag(movie)}.mkv", storage.getMovieSafFileName(movie, "mkv"))
        assertEquals("MyMovieName (2023) ${tag(movie)}", storage.getMovieSafBaseName(movie))
    }

    @Test
    fun aMovieWithoutAYearHasNoParenthesizedSuffix() {
        val storage = storage()
        val movie = movie("Untitled")
        assertEquals(listOf("Movies", "Untitled"), storage.getMovieSafPathComponents(movie))
        assertEquals("Untitled ${tag(movie)}.mp4", storage.getMovieSafFileName(movie, "mp4"))
    }

    @Test
    fun episodeComponentsUseShowSeasonAndEpisodeNumberWithTitle() {
        val storage = storage()
        val episode = episode("My Show", 2010, season = 1, number = 5, title = "Pilot:Pt 1")

        assertEquals(listOf("TV Shows", "My Show (2010)", "Season 01"), storage.getEpisodeSafPathComponents(episode))
        assertEquals("S01E05 - PilotPt 1 ${tag(episode)}.mkv", storage.getEpisodeSafFileName(episode, "mkv"))
        assertEquals("S01E05 - PilotPt 1 ${tag(episode)}", storage.getEpisodeSafBaseName(episode))
    }

    @Test
    fun showComponentsUseTheItemTitleWithoutAGrandparentTitle() {
        val show = MediaItem(id = "s-1", backend = BackendKind.PLEX, kind = MediaKind.SHOW, title = "Solo Show", year = 2024)
        assertEquals(listOf("TV Shows", "Solo Show (2024)"), storage().getShowSafPathComponents(show))
    }

    @Test
    fun seasonComponentsUseTheSeasonIndexForItsNumber() {
        val season = MediaItem(id = "season-3", backend = BackendKind.PLEX, kind = MediaKind.SEASON, title = "Season 3", grandparentTitle = "Show A", year = 2019, index = 3)
        assertEquals(listOf("TV Shows", "Show A (2019)", "Season 03"), storage().getSeasonSafPathComponents(season))
    }

    @Test
    fun anExplicitShowYearOverridesTheEpisodeYearForTheShowFolder() {
        val episode = episode("Year Mismatch", 2010, season = 2, number = 1, title = "Title")
        assertEquals(listOf("TV Shows", "Year Mismatch (2008)", "Season 02"), storage().getEpisodeSafPathComponents(episode, showYear = 2008))
    }

    @Test
    fun fileNamesDropIllegalCharactersAndEdgeDotsAndReplaceInnerDots() {
        assertEquals("Mr_ Robot", DownloadStorageService.sanitizeFileName("..Mr. Robot.."))
        assertEquals("ACDC", DownloadStorageService.sanitizeFileName("AC/DC"))
        assertEquals("ab", DownloadStorageService.sanitizeFileName(" <a>:\"b|?* "))
    }

    // Download identity in file names

    private fun sameTitle(kind: MediaKind, serverId: String, id: String) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = kind,
        serverId = serverId,
        title = "Same Title",
        year = 2000,
        grandparentTitle = if (kind == MediaKind.EPISODE) "Same Show" else "Same Artist",
        parentTitle = "Same Album",
        parentIndex = 1,
        index = 1,
    )

    @Test
    fun theTagIsAStableDigestOfTheServerAndItemId() {
        assertEquals("Same Title (2000) [20065bd2].mkv", storage().getMovieSafFileName(sameTitle(MediaKind.MOVIE, "srv", "42"), "mkv"))
    }

    @Test
    fun sameTitledMoviesFromOtherServersOrLibrariesGetTheirOwnFile() = sameTitledItemsGetTheirOwnFile(MediaKind.MOVIE)

    @Test
    fun sameTitledEpisodesFromOtherServersOrLibrariesGetTheirOwnFile() = sameTitledItemsGetTheirOwnFile(MediaKind.EPISODE)

    @Test
    fun sameTitledTracksFromOtherServersOrLibrariesGetTheirOwnFile() = sameTitledItemsGetTheirOwnFile(MediaKind.TRACK)

    private fun sameTitledItemsGetTheirOwnFile(kind: MediaKind) = runTest {
        val storage = initialized()
        fun pathOf(item: MediaItem) = when (kind) {
            MediaKind.MOVIE -> storage.getMovieVideoPath(item, "mkv")
            MediaKind.EPISODE -> storage.getEpisodeVideoPath(item, "mkv")
            else -> storage.getTrackAudioPath(item, "mkv")
        }
        val plex = sameTitle(kind, "plex-srv", "42")
        val paths = linkedSetOf(pathOf(plex), pathOf(sameTitle(kind, "jf-srv", "42")), pathOf(sameTitle(kind, "plex-srv", "43")))

        assertEquals(3, paths.size)
        assertEquals(1, paths.map(LocalPath::dirname).toSet().size, "copies still share the title folder")
        assertEquals(paths.first(), pathOf(plex), "the name is deterministic")
    }

    // Track paths

    @Test
    fun trackAudioPathLaysOutMusicArtistAlbumNumberAndTitle() = runTest {
        val storage = initialized()
        val track = track("Song", artist = "Artist", album = "Album", number = 3)

        val audio = storage.getTrackAudioPath(track, "mp3")
        assertEquals(join(storage.getDownloadsDirectory(), "Music", "Artist", "Album", "03 - Song ${tag(track)}.mp3"), audio)
        assertTrue(isDirectory(LocalPath.dirname(audio)), "the album directory is created")
    }

    @Test
    fun safComponentsAndFileNameMirrorTheFileLayoutAndSanitizeIllegalCharacters() {
        val storage = storage()
        val track = track("So/ng: Two?", artist = "AC/DC", album = "Back:In*Black", number = 1)

        assertEquals(listOf("Music", "ACDC", "BackInBlack"), storage.getTrackSafPathComponents(track))
        assertEquals("01 - Song Two ${tag(track)}.flac", storage.getTrackSafFileName(track, "flac"))
    }

    @Test
    fun safTargetRoutesTracksToTheMusicLayoutInsteadOfTheGenericFallback() {
        val track = track("Song", artist = "Artist", album = "Album", number = 3)
        assertEquals(SafTarget(listOf("Music", "Artist", "Album"), "03 - Song ${tag(track)}.mp3"), storage().safTarget(track, "mp3", serverId = "srv"))
    }

    @Test
    fun safTargetPutsOtherKindsUnderServerAndItem() {
        val clip = MediaItem(id = "clip-1", backend = BackendKind.PLEX, kind = MediaKind.CLIP, title = "Clip")
        assertEquals(SafTarget(listOf("srv", "clip-1"), "video.mp4"), storage().safTarget(clip, "mp4", serverId = "srv"))
    }

    @Test
    fun missingOrBlankArtistAndAlbumFallBackToUnknownArtistAndUnknownAlbum() {
        val storage = storage()
        assertEquals(listOf("Music", "Unknown Artist", "Unknown Album"), storage.getTrackSafPathComponents(track("Song", number = 1)))
        // Sanitizing can empty a component made of illegal characters only.
        assertEquals(
            listOf("Music", "Unknown Artist", "Unknown Album"),
            storage.getTrackSafPathComponents(track("Song", artist = "  ", album = "???", number = 1)),
        )
    }

    @Test
    fun aTrackWithoutAnIndexIsJustTheSanitizedTitle() {
        val track = track("Hidden: Track", artist = "Artist", album = "Album")
        assertEquals("Hidden Track ${tag(track)}.mp3", storage().getTrackSafFileName(track, "mp3"))
    }

    @Test
    fun multiDiscAlbumsPrefixTheDiscNumberAndDiscOneStaysUnprefixed() {
        val storage = storage()
        val discTwo = track("Song", artist = "Artist", album = "Album", number = 5, disc = 2)
        assertEquals("2-05 - Song ${tag(discTwo)}.mp3", storage.getTrackSafFileName(discTwo, "mp3"))
        val discOne = track("Song", artist = "Artist", album = "Album", number = 5, disc = 1)
        assertEquals("05 - Song ${tag(discOne)}.mp3", storage.getTrackSafFileName(discOne, "mp3"))
    }

    // Media directories on disk

    @Test
    fun getMediaDirectoryCreatesServerAndItemUnderDownloads() = runTest {
        val storage = initialized()
        val directory = storage.getMediaDirectory(ServerId("srv-1"), "42")
        assertTrue(isDirectory(directory))
        assertEquals(join(storage.getDownloadsDirectory(), "srv-1", "42"), directory)
    }

    @Test
    fun otherKindsKeepVideoAndSubtitlesUnderServerAndItem() = runTest {
        val storage = initialized()
        val item = join(storage.getDownloadsDirectory(), "srv", "7")
        assertEquals(join(item, "video.mkv"), storage.getVideoFilePath(ServerId("srv"), "7", "mkv"))
        assertEquals(join(item, "subtitles", "3.srt"), storage.getSubtitlePath(ServerId("srv"), "7", 3, "srt"))
    }

    @Test
    fun movieDirectoryAndVideoPathAgree() = runTest {
        val storage = initialized()
        val movie = movie("Big Movie", 2020)

        val directory = storage.getMovieDirectory(movie)
        val video = storage.getMovieVideoPath(movie, "mkv")
        assertTrue(isDirectory(directory))
        assertEquals(directory, LocalPath.dirname(video))
        assertEquals("Big Movie (2020) ${tag(movie)}.mkv", LocalPath.basename(video))
        assertEquals(storage.sidecarSubtitlesDirectoryPath(video), storage.getMovieSubtitlesDirectory(movie), "playback derives it from the video")
    }

    @Test
    fun episodeVideoAndThumbnailShareTheSeasonDirectory() = runTest {
        val storage = initialized()
        val episode = episode("Demo Show", 2015, season = 2, number = 4, title = "Pilot")

        val video = storage.getEpisodeVideoPath(episode, "mkv")
        val thumb = storage.getEpisodeThumbnailPath(episode)
        assertEquals(LocalPath.dirname(video), LocalPath.dirname(thumb))
        assertEquals("S02E04 - Pilot ${tag(episode)}.mkv", LocalPath.basename(video))
        assertEquals("S02E04 - Pilot ${tag(episode)}.jpg", LocalPath.basename(thumb))

        val subtitles = storage.getEpisodeSubtitlesDirectory(episode)
        assertTrue(isDirectory(subtitles))
        assertEquals(storage.sidecarSubtitlesDirectoryPath(video), subtitles)
    }

    // Stacked files

    @Test
    fun laterFilesAreNamedAfterTheFirstBesideItWithTheirOwnExtension() = runTest {
        val storage = initialized()
        val movie = movie("Big Movie", 2020)
        val first = storage.getMovieVideoPath(movie, "mkv")
        val second = storage.partFilePath(first, 1, "mkv")
        val third = storage.partFilePath(first, 2, "mp4")

        assertEquals(LocalPath.dirname(first), LocalPath.dirname(second))
        assertEquals("Big Movie (2020) ${tag(movie)} - part2.mkv", LocalPath.basename(second))
        assertEquals("Big Movie (2020) ${tag(movie)} - part3.mp4", LocalPath.basename(third))
        assertEquals("Big Movie (2020) ${tag(movie)} - part2.avi", storage.partFilePath(LocalPath.basename(first), 1, "avi"))
        assertEquals(join(LocalPath.dirname(first), "Big Movie (2020) ${tag(movie)} - part2_subs"), storage.sidecarSubtitlesDirectoryPath(second))
    }

    @Test
    fun partZeroIsTheFirstFileItself() {
        assertFailsWith<IllegalArgumentException> { storage().partFilePath("a.mkv", 0, "mkv") }
    }

    @Test
    fun recognizesOnlyLaterFilesOfTheSameFirstFile() {
        val storage = storage()
        val first = "Movie (2020) [abcd1234]"

        assertTrue(storage.isPartFileBaseName(first, "$first - part2"))
        assertTrue(storage.isPartFileBaseName(first, "$first - part12"))
        assertFalse(storage.isPartFileBaseName(first, first))
        assertFalse(storage.isPartFileBaseName(first, "$first - part1"), "part 1 is the first file itself")
        assertFalse(storage.isPartFileBaseName(first, "$first - part02"))
        assertFalse(storage.isPartFileBaseName(first, "$first - partX"))
        assertFalse(storage.isPartFileBaseName(first, "Movie (2020) [ffff0000] - part2"))
    }

    @Test
    fun safSidecarsOfALaterFileGetTheirOwnAppManagedFolderCreatedOnDemand() = runTest {
        val storage = initialized()
        val directory = storage.getPartSubtitlesDirectory(ServerId("srv-1"), "42", 1)

        assertEquals(join(storage.getSubtitlesDirectory(ServerId("srv-1"), "42"), "part2"), directory)
        assertFalse(exists(directory))
    }

    @Test
    fun aStorageExceptionNamesItsMessagePathAndCause() {
        val text = DownloadStorageException("boom", "/tmp/x", IllegalStateException("inner")).toString()
        assertTrue("boom" in text)
        assertTrue("/tmp/x" in text)
        assertTrue("inner" in text)
    }

    private fun movie(title: String, year: Int? = null) =
        MediaItem(id = "m-$title", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = title, year = year)

    private fun episode(show: String, showYear: Int?, season: Int, number: Int, title: String) = MediaItem(
        id = "ep-$show-$season-$number",
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        title = title,
        grandparentTitle = show,
        year = showYear,
        parentIndex = season,
        index = number,
    )

    private fun track(title: String, artist: String? = null, album: String? = null, number: Int? = null, disc: Int? = null) = MediaItem(
        id = "track-$title-$number",
        backend = BackendKind.PLEX,
        kind = MediaKind.TRACK,
        title = title,
        grandparentTitle = artist,
        parentTitle = album,
        index = number,
        parentIndex = disc,
    )

    /** The identity tag; the literal in the stable-digest test pins the formula. */
    private fun tag(item: MediaItem) = "[${DownloadStorageService.md5Hex(item.globalKey).substring(0, 8)}]"
}
