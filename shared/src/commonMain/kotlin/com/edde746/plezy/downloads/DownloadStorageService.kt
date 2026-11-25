package com.edde746.plezy.downloads

import com.edde746.plezy.crypto.cryptoProvider
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.settings.AppSettings
import dev.whyoleg.cryptography.DelicateCryptographyApi
import dev.whyoleg.cryptography.algorithms.MD5
import kotlinx.io.IOException
import kotlinx.io.buffered
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.writeString
import kotlin.time.Clock

/** The download storage could not create or reach a directory (permission denied, full volume, revoked grant). */
class DownloadStorageException(message: String, val path: String, cause: Throwable) : Exception(message, cause) {
    override fun toString(): String = "DownloadStorageException: $message (path: $path, cause: $cause)"
}

/**
 * What the download storage takes from the platform.
 *
 * @param baseDirectory the directory download paths inside the app's storage are stored relative to:
 *   [BaseDirectory.APPLICATION_DOCUMENTS] on Android, iPhone and iPad, [BaseDirectory.APPLICATION_SUPPORT] on the Mac,
 *   Windows and Linux.
 * @param baseDirectoryPath [baseDirectory]'s absolute path now. It moves with the app's container (an iOS container
 *   change, Android adoptable storage), so it is read on every use. It equals the earlier releases' directory, so the
 *   relative paths they stored resolve.
 * @param supportsSaf a custom download folder can be a storage-access-framework tree (Android).
 * @param excludeFromBackup marks a directory excluded from device backup, throwing when the system refuses; null where
 *   the app's directories aren't backed up (only iPhone and iPad back up Documents).
 */
class DownloadStoragePlatform(
    val baseDirectory: BaseDirectory,
    val baseDirectoryPath: () -> String,
    val supportsSaf: Boolean,
    val excludeFromBackup: ((String) -> Unit)? = null,
) {
    init {
        require(baseDirectory != BaseDirectory.ROOT) { "Downloads are anchored to the app's documents or support directory" }
    }

    companion object
}

/** Where a [DownloadTask] for a target file goes: [directory] under [baseDirectory] (absolute for [BaseDirectory.ROOT]). */
data class TaskDirectory(val baseDirectory: BaseDirectory, val directory: String)

/** A storage-access-framework target: [fileName] in the directory [components] under the tree. */
data class SafTarget(val components: List<String>, val fileName: String)

/**
 * Where downloads live on this device and what their files are called.
 *
 * The root is `<base>/downloads` ([DownloadStoragePlatform.baseDirectoryPath]), with artwork in `<base>/artwork`. A
 * writable custom folder (setting `custom_download_path` of type `file`) replaces the root, with its artwork in
 * `artwork` beside it when that is writable. On Android the custom folder can be a storage-access-framework tree
 * (type `saf`): [isUsingSaf], [safBaseUri], and the `*SafPathComponents`/`*SafFileName` layout under it.
 *
 * Files are named after the item, plus a tag that is the item's own ([itemTag]):
 * - movie: `Movies/<Title> (<Year>)/<Title> (<Year>) [tag].<ext>`
 * - episode: `TV Shows/<Show> (<Show year>)/Season <NN>/S<NN>E<NN> - <Title> [tag].<ext>`
 * - track: `Music/<Album artist>/<Album>/<NN> - <Title> [tag].<ext>` (`<disc>-<NN>` past disc 1)
 * - anything else: `<serverId>/<itemId>/video.<ext>`
 *
 * A video's subtitles go to `<video without extension>_subs/<stream id>.<ext>`. Paths inside the base directory are
 * stored relative to it ([toRelativePath]); everything else absolute.
 */
class DownloadStorageService(
    private val platform: DownloadStoragePlatform,
    private val settings: DeviceSettingsRepository,
    private val fileSystem: FileSystem = SystemFileSystem,
    private val clock: Clock = Clock.System,
) {
    private var customDownloadPath: String? = null
    private var customPathType: String = PATH_TYPE_FILE
    private var downloadsDirectory: String? = null

    /** The artwork directory resolved last, for synchronous lookups; null before [initialize]. */
    var artworkDirectoryPath: String? = null
        private set

    /** The custom folder is a storage-access-framework tree. */
    val isUsingSaf: Boolean get() = platform.supportsSaf && customPathType == PATH_TYPE_SAF && customDownloadPath != null

    /** The custom folder's tree URI while [isUsingSaf]. */
    val safBaseUri: String? get() = if (isUsingSaf) customDownloadPath else null

    /** The custom download folder when it is a file system path. */
    val customFileRootPath: String? get() = if (customPathType == PATH_TYPE_FILE) customDownloadPath else null

    /** Where relative download paths are anchored for [NativeDownloader] tasks. */
    val baseDirectory: BaseDirectory get() = platform.baseDirectory

    /**
     * Reads the custom folder and resolves the artwork directory. On a platform that excludes downloads from backup it
     * resolves the downloads directory too, which marks it, so downloads made before the exclusion leave the backup
     * now rather than at the next download.
     */
    suspend fun initialize() {
        readCustomPath()
        getArtworkDirectory()
        if (platform.excludeFromBackup != null) getDownloadsDirectory()
    }

    /** Reads the custom folder again after it changed; the roots are resolved anew. */
    suspend fun refreshCustomPath() {
        readCustomPath()
        getArtworkDirectory()
    }

    private suspend fun readCustomPath() {
        customDownloadPath = settings.value(AppSettings.customDownloadPath)
        customPathType = settings.value(AppSettings.customDownloadPathType) ?: PATH_TYPE_FILE
        downloadsDirectory = null
        artworkDirectoryPath = null
    }

    /** The absolute directory relative download paths are anchored to, read fresh (it moves with the app). */
    fun baseAppDirectoryPath(): String = platform.baseDirectoryPath()

    fun isUsingCustomPath(): Boolean = customDownloadPath != null

    /** The custom folder (path or tree URI) when set, else the downloads directory. */
    fun getCurrentDownloadPathDisplay(): String = customDownloadPath ?: getDownloadsDirectory()

    /** Whether files can be written in [directory]: creates it, then writes and deletes `.write_test_<ms>`. */
    fun isDirectoryWritable(directory: String): Boolean = try {
        fileSystem.createDirectories(Path(directory))
        val probe = Path(LocalPath.join(directory, ".write_test_${clock.now().toEpochMilliseconds()}"))
        fileSystem.sink(probe).buffered().use { it.writeString("test") }
        fileSystem.delete(probe)
        true
    } catch (e: IOException) {
        Log.d(TAG, e) { "Directory not writable: $directory" }
        false
    }

    /** The downloads root, created: the custom folder when writable, else `<base>/downloads`. */
    fun getDownloadsDirectory(): String {
        downloadsDirectory?.let { return it }
        val custom = customFileRootPath
        if (custom != null && isDirectoryWritable(custom)) {
            downloadsDirectory = custom
            return custom
        }
        val directory = ensureDirectoryExists(LocalPath.join(baseAppDirectoryPath(), DOWNLOADS))
        excludeFromBackup(directory)
        downloadsDirectory = directory
        return directory
    }

    /** The artwork directory, created: `artwork` beside a custom folder when writable, else `<base>/artwork`. */
    fun getArtworkDirectory(): String {
        val custom = customFileRootPath
        if (custom != null) {
            val beside = LocalPath.join(LocalPath.dirname(custom), ARTWORK)
            if (isDirectoryWritable(beside)) {
                artworkDirectoryPath = beside
                return beside
            }
        }
        val directory = ensureDirectoryExists(LocalPath.join(baseAppDirectoryPath(), ARTWORK))
        excludeFromBackup(directory)
        artworkDirectoryPath = directory
        return directory
    }

    /** Marks an app-owned root excluded from device backup; a refusal is logged, never fatal. */
    private fun excludeFromBackup(directory: String) {
        val exclude = platform.excludeFromBackup ?: return
        try {
            exclude(directory)
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to exclude $directory from backup" }
        }
    }

    /**
     * The artwork file of [thumbPath] (an artwork storage key) on [serverId]: `<artwork>/<md5 of "serverId:key">.jpg`.
     * Null before [initialize].
     */
    fun getArtworkPathSync(serverId: ServerId, thumbPath: String): String? {
        val directory = artworkDirectoryPath ?: return null
        return LocalPath.join(directory, "${md5Hex("$serverId:$thumbPath")}.jpg")
    }

    /** [getArtworkPathSync] after resolving the artwork directory. */
    fun getArtworkPathFromThumb(serverId: ServerId, thumbPath: String): String =
        LocalPath.join(getArtworkDirectory(), "${md5Hex("$serverId:$thumbPath")}.jpg")

    fun artworkExists(serverId: ServerId, thumbPath: String): Boolean = fileSystem.exists(Path(getArtworkPathFromThumb(serverId, thumbPath)))

    /** `<downloads>/<serverId>/<itemId>`, created. */
    fun getMediaDirectory(serverId: ServerId, ratingKey: String): String =
        ensureDirectoryExists(LocalPath.join(getDownloadsDirectory(), serverId.value, ratingKey))

    fun getVideoFilePath(serverId: ServerId, ratingKey: String, extension: String): String =
        LocalPath.join(getMediaDirectory(serverId, ratingKey), "video.$extension")

    /** `<downloads>/<serverId>/<itemId>/subtitles`, created. */
    fun getSubtitlesDirectory(serverId: ServerId, ratingKey: String): String =
        ensureDirectoryExists(LocalPath.join(getMediaDirectory(serverId, ratingKey), "subtitles"))

    fun getSubtitlePath(serverId: ServerId, ratingKey: String, trackId: Int, extension: String): String =
        LocalPath.join(getSubtitlesDirectory(serverId, ratingKey), "$trackId.$extension")

    /**
     * The app-managed subtitle directory of file [partIndex] (0-based, above 0) of an item stacked across several
     * files, used when that file is a storage-access-framework document: `part<N>` under [getSubtitlesDirectory], so
     * one file's sidecars are never offered while another plays. Not created here.
     */
    fun getPartSubtitlesDirectory(serverId: ServerId, ratingKey: String, partIndex: Int): String =
        LocalPath.join(getDownloadsDirectory(), serverId.value, ratingKey, "subtitles", "part${partIndex + 1}")

    /**
     * The path (or bare name) of file [partIndex] (0-based, above 0) of an item stacked across several files, beside
     * [firstFilePath]: `<first file without extension> - part<N>.<extension>`.
     */
    fun partFilePath(firstFilePath: String, partIndex: Int, extension: String): String {
        require(partIndex > 0) { "Part 0 is the first file itself" }
        return "${LocalPath.withoutExtension(firstFilePath)} - part${partIndex + 1}.$extension"
    }

    /** Whether [fileBaseName] (no extension) names a later file of the item whose first file is [firstFileBaseName]. */
    fun isPartFileBaseName(firstFileBaseName: String, fileBaseName: String): Boolean {
        val prefix = "$firstFileBaseName - part"
        if (!fileBaseName.startsWith(prefix)) return false
        val number = fileBaseName.substring(prefix.length).toIntOrNull() ?: return false
        return number > 1 && fileBaseName == "$prefix$number"
    }

    fun getMovieDirectory(movie: MediaItem): String = downloadsSubdirectory(getMovieSafPathComponents(movie))

    fun getMovieVideoPath(movie: MediaItem, extension: String): String =
        LocalPath.join(getMovieDirectory(movie), getMovieSafFileName(movie, extension))

    /** `<downloads>/TV Shows/<Show> (<Year>)`; [showYear] is the show's premiere year (an episode's year can differ). */
    fun getShowDirectory(metadata: MediaItem, showYear: Int? = null): String =
        downloadsSubdirectory(getShowSafPathComponents(metadata, showYear))

    /** The season directory of an episode ([MediaItem.parentIndex] is its season). */
    fun getSeasonDirectory(metadata: MediaItem, showYear: Int? = null): String =
        downloadsSubdirectory(getEpisodeSafPathComponents(metadata, showYear))

    fun getEpisodeVideoPath(episode: MediaItem, extension: String, showYear: Int? = null): String =
        LocalPath.join(getSeasonDirectory(episode, showYear), "${formatEpisodeFileName(episode)}.$extension")

    /** The thumbnail earlier releases saved beside an episode's video. */
    fun getEpisodeThumbnailPath(episode: MediaItem, showYear: Int? = null): String =
        LocalPath.join(getSeasonDirectory(episode, showYear), "${formatEpisodeFileName(episode)}.jpg")

    fun getEpisodeSubtitlesDirectory(episode: MediaItem, showYear: Int? = null): String =
        ensureDirectoryExists(LocalPath.join(getSeasonDirectory(episode, showYear), "${formatEpisodeFileName(episode)}_subs"))

    fun getEpisodeSubtitlePath(episode: MediaItem, trackId: Int, extension: String, showYear: Int? = null): String =
        LocalPath.join(getEpisodeSubtitlesDirectory(episode, showYear), "$trackId.$extension")

    fun getMovieSubtitlesDirectory(movie: MediaItem): String =
        ensureDirectoryExists(LocalPath.join(getMovieDirectory(movie), "${movieFileBaseName(movie)}_subs"))

    fun getMovieSubtitlePath(movie: MediaItem, trackId: Int, extension: String): String =
        LocalPath.join(getMovieSubtitlesDirectory(movie), "$trackId.$extension")

    /** A downloaded video's sidecar subtitle directory: its path with the extension replaced by `_subs`. */
    fun sidecarSubtitlesDirectoryPath(videoPath: String): String = videoPath.replace(EXTENSION, "_subs")

    fun getTrackAlbumDirectory(track: MediaItem): String = downloadsSubdirectory(getTrackSafPathComponents(track))

    fun getTrackAudioPath(track: MediaItem, extension: String): String =
        LocalPath.join(getTrackAlbumDirectory(track), getTrackSafFileName(track, extension))

    /**
     * [absolutePath] relative to the base directory when inside it (so it survives the app's container moving), else
     * unchanged (a custom folder, which doesn't move with the app). Containment is by components: a sibling
     * `<base>-external` is not inside.
     */
    fun toRelativePath(absolutePath: String): String {
        val base = baseAppDirectoryPath()
        return if (LocalPath.isWithin(base, absolutePath)) LocalPath.relative(absolutePath, base) else absolutePath
    }

    /**
     * The [DownloadTask] base directory and directory for a target file: relative to [baseDirectory] inside the app's
     * storage, so a task persisted across a restart follows the app's container; [BaseDirectory.ROOT] with the
     * absolute directory for a custom folder.
     */
    fun resolveTaskDirectory(absolutePath: String): TaskDirectory {
        val relative = toRelativePath(absolutePath)
        if (relative == absolutePath) return TaskDirectory(BaseDirectory.ROOT, LocalPath.dirname(absolutePath))
        return TaskDirectory(platform.baseDirectory, LocalPath.dirname(relative))
    }

    /** [relativePath] under the base directory; an absolute path is returned unchanged. */
    fun toAbsolutePath(relativePath: String): String =
        if (LocalPath.isAbsolute(relativePath)) relativePath else LocalPath.join(baseAppDirectoryPath(), relativePath)

    /**
     * The absolute file of a stored path. Candidates, in order: the path as stored (joined to the base when relative);
     * for an absolute path holding the base twice, the part after the second copy; for a relative path holding the
     * base, the part after it; the tail from the last `downloads/`. The first that exists wins, else the first.
     */
    fun ensureAbsolutePath(storedPath: String): String {
        val base = baseAppDirectoryPath()
        val candidates = LinkedHashSet<String>()
        fun add(candidate: String) {
            if (candidate.isNotEmpty()) candidates += LocalPath.normalize(candidate)
        }
        fun tailAfter(index: Int) = storedPath.substring(index + base.length).trimStart('/', '\\')
        if (LocalPath.isAbsolute(storedPath)) {
            add(storedPath)
            val first = storedPath.indexOf(base)
            if (first != -1) {
                val second = storedPath.indexOf(base, first + base.length)
                if (second != -1) add(LocalPath.join(base, tailAfter(second)))
            }
            val downloads = storedPath.lastIndexOf("$DOWNLOADS/")
            if (downloads != -1) add(toAbsolutePath(storedPath.substring(downloads)))
        } else {
            add(toAbsolutePath(storedPath))
            val nested = storedPath.indexOf(base)
            if (nested > 0) add(LocalPath.join(base, tailAfter(nested)))
            val downloads = storedPath.lastIndexOf("$DOWNLOADS/")
            if (downloads >= 0) add(toAbsolutePath(storedPath.substring(downloads)))
        }
        return candidates.firstOrNull { fileSystem.exists(Path(it)) } ?: candidates.firstOrNull() ?: toAbsolutePath(storedPath)
    }

    /** `["Movies", "<Title> (<Year>)"]`. */
    fun getMovieSafPathComponents(movie: MediaItem): List<String> = listOf("Movies", movieFolderName(movie))

    /** `["TV Shows", "<Show> (<Year>)", "Season <NN>"]`, the season from [MediaItem.parentIndex]. */
    fun getEpisodeSafPathComponents(episode: MediaItem, showYear: Int? = null): List<String> =
        listOf("TV Shows", showFolderName(episode, showYear), "Season ${pad(episode.parentIndex ?: 0)}")

    fun getShowSafPathComponents(metadata: MediaItem, showYear: Int? = null): List<String> =
        listOf("TV Shows", showFolderName(metadata, showYear))

    /** A season's own components: its number is [MediaItem.index]. */
    fun getSeasonSafPathComponents(season: MediaItem, showYear: Int? = null): List<String> =
        listOf("TV Shows", showFolderName(season, showYear), "Season ${pad(season.index ?: 0)}")

    /** `["Music", "<Album artist>", "<Album>"]`, `Unknown Artist`/`Unknown Album` when missing or emptied. */
    fun getTrackSafPathComponents(track: MediaItem): List<String> {
        val artist = sanitizeFileName(track.albumArtistTitle.orEmpty()).ifEmpty { "Unknown Artist" }
        val album = sanitizeFileName(track.albumTitle.orEmpty()).ifEmpty { "Unknown Album" }
        return listOf("Music", artist, album)
    }

    fun getMovieSafFileName(movie: MediaItem, extension: String): String = "${movieFileBaseName(movie)}.$extension"

    fun getMovieSafBaseName(movie: MediaItem): String = movieFileBaseName(movie)

    fun getEpisodeSafFileName(episode: MediaItem, extension: String): String = "${formatEpisodeFileName(episode)}.$extension"

    fun getEpisodeSafBaseName(episode: MediaItem): String = formatEpisodeFileName(episode)

    fun getTrackSafFileName(track: MediaItem, extension: String): String = "${formatTrackFileName(track)}.$extension"

    /**
     * The directory components and file name of a download's target, shared by the enqueue that writes it and the
     * completion that looks it up. [serverId] is read only for kinds without their own layout.
     */
    fun safTarget(metadata: MediaItem, extension: String, showYear: Int? = null, serverId: String?): SafTarget = when {
        metadata.isMovie -> SafTarget(getMovieSafPathComponents(metadata), getMovieSafFileName(metadata, extension))
        metadata.isEpisode -> SafTarget(getEpisodeSafPathComponents(metadata, showYear), getEpisodeSafFileName(metadata, extension))
        metadata.isTrack -> SafTarget(getTrackSafPathComponents(metadata), getTrackSafFileName(metadata, extension))
        else -> SafTarget(listOf(requireNotNull(serverId) { "A ${metadata.kind} target needs its server id" }, metadata.id), "video.$extension")
    }

    fun isSafUri(storedPath: String): Boolean = storedPath.startsWith("content://")

    /** A `content://` URI as stored, else [ensureAbsolutePath]. */
    fun getReadablePath(storedPath: String): String = if (isSafUri(storedPath)) storedPath else ensureAbsolutePath(storedPath)

    /**
     * The download's identity in its file names, `[<first 8 hex of md5("serverId:itemId")>]`: titles alone collide
     * (one movie in two libraries, or on a Plex and a Jellyfin server). It must never change: in-flight downloads and
     * storage-access-framework recovery look files up by it.
     */
    private fun itemTag(item: MediaItem): String = "[${md5Hex(item.globalKey).substring(0, 8)}]"

    private fun formatEpisodeFileName(episode: MediaItem): String {
        val title = sanitizeFileName(requireNotNull(episode.title) { "An episode without a title has no file name" })
        return "S${pad(episode.parentIndex ?: 0)}E${pad(episode.index ?: 0)} - $title ${itemTag(episode)}"
    }

    private fun formatTitleWithYear(title: String, year: Int?): String {
        val sanitized = sanitizeFileName(title)
        return if (year != null) "$sanitized ($year)" else sanitized
    }

    private fun movieFolderName(movie: MediaItem): String =
        formatTitleWithYear(requireNotNull(movie.title) { "A movie without a title has no folder" }, movie.year)

    /** The folder stays title-only, so copies of one title share it; the file is the item's. */
    private fun movieFileBaseName(movie: MediaItem): String = "${movieFolderName(movie)} ${itemTag(movie)}"

    private fun showFolderName(metadata: MediaItem, showYear: Int?): String {
        val title = metadata.grandparentTitle ?: requireNotNull(metadata.title) { "A show without a title has no folder" }
        return formatTitleWithYear(title, showYear ?: metadata.year)
    }

    private fun formatTrackFileName(track: MediaItem): String {
        val title = "${sanitizeFileName(requireNotNull(track.title) { "A track without a title has no file name" })} ${itemTag(track)}"
        val number = track.trackNumber ?: return title
        val disc = track.discNumber
        return if (disc != null && disc > 1) "$disc-${pad(number)} - $title" else "${pad(number)} - $title"
    }

    private fun downloadsSubdirectory(components: List<String>): String =
        ensureDirectoryExists(LocalPath.join(getDownloadsDirectory(), *components.toTypedArray()))

    private fun ensureDirectoryExists(directory: String): String {
        try {
            fileSystem.createDirectories(Path(directory))
        } catch (e: IOException) {
            throw DownloadStorageException("Cannot create directory", directory, e)
        }
        return directory
    }

    companion object {
        private const val TAG = "DownloadStorage"
        internal const val DOWNLOADS = "downloads"
        internal const val ARTWORK = "artwork"
        const val PATH_TYPE_FILE = "file"
        const val PATH_TYPE_SAF = "saf"
        private val EXTENSION = Regex("""\.[^.]+$""")
        private val ILLEGAL = Regex("""[<>:"/\\|?*]""")
        private val EDGE_DOTS = Regex("""^\.+|\.+$""")

        /** Drops `<>:"/\|?*`, then leading and trailing dots; other dots become `_`; trimmed. */
        internal fun sanitizeFileName(name: String): String =
            name.replace(ILLEGAL, "").replace(EDGE_DOTS, "").replace('.', '_').trim()

        private fun pad(number: Int): String = number.toString().padStart(2, '0')

        @OptIn(DelicateCryptographyApi::class)
        internal fun md5Hex(text: String): String =
            cryptoProvider.get(MD5).hasher().hashBlocking(text.encodeToByteArray())
                .joinToString("") { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }
    }
}
