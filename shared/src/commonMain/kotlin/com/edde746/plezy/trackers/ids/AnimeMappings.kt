package com.edde746.plezy.trackers.ids

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.net.readBody
import com.edde746.plezy.settings.AppSettings
import io.ktor.client.HttpClient
import io.ktor.client.request.header
import io.ktor.client.request.prepareGet
import io.ktor.http.HttpHeaders
import io.ktor.utils.io.readBuffer
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.io.buffered
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readByteArray

/** Fribb rows by a library item's external ids ([FribbIndex.lookup]). */
internal fun interface FribbLookup {
    suspend fun lookup(movie: Boolean, anidb: Int?, tvdb: Int?, tmdb: Int?, imdb: String?): List<FribbRow>
}

/** Anime-Lists episode and season matching ([AnimeListsIndex]). */
internal interface AnimeListsLookup {
    suspend fun lookupEpisode(tvdbId: Int?, tmdbId: Int?, season: Int?, episode: Int?): AnimeEpisodeMatch?

    suspend fun animeIdsForSeason(tvdbId: Int?, tmdbId: Int?, season: Int): Set<Int>

    suspend fun animeIdsForShow(tvdbId: Int?, tmdbId: Int?): Set<Int>
}

/** Both datasets of one anime-mappings file. */
internal class AnimeMappingIndexes(val fribb: FribbIndex, val animeLists: AnimeListsIndex) {
    val isEmpty: Boolean get() = fribb.isEmpty && animeLists.isEmpty

    val summary: String get() = "${fribb.summary}, ${animeLists.summary}"

    companion object {
        val EMPTY = AnimeMappingIndexes(FribbIndex.EMPTY, AnimeListsIndex.EMPTY)
    }
}

/**
 * The anime mappings: one file (`anime-mappings.bin.gz`, about 0.65 MB, from the latest release of
 * https://github.com/edde746/anime-mappings, rebuilt daily) bundling two community datasets:
 *
 * - Fribb's `anime-list-mini.json` (https://github.com/Fribb/anime-lists): which AniDB, MyAnimeList, AniList and Simkl
 *   entry is which IMDb/TMDB/TVDB title and season ([FribbIndex]).
 * - Anime-Lists' `anime-list.xml` (https://github.com/Anime-Lists/anime-lists): where each AniDB entry's episodes lie
 *   on TVDB's and TMDB's seasons ([AnimeListsIndex]).
 *
 * Nothing is downloaded until the first lookup, which only a tracker needing anime ids makes. The file is kept in
 * [directory] and decoded off the caller's thread ([parseDispatcher]); concurrent first lookups share one load. A
 * failed download (offline, an error status, 60 s without an answer) answers empty and isn't kept, so the next
 * lookup tries again; a copy that doesn't decode is deleted, so the next lookup downloads it again.
 *
 * The first download records the file's ETag ([AppSettings.animeMappingsEtag]) and the time of the check
 * ([AppSettings.animeMappingsLastCheck]), so a relaunch the same day asks nothing. After a load, a check a day old
 * asks again with `If-None-Match` (single-flight): any answer counts as the check, a 304 keeps the copy, a 200
 * replaces the file, the ETag and the loaded index; failures are logged and change nothing.
 */
internal class AnimeMappings(
    private val http: HttpClient,
    private val directory: Path,
    private val settings: DeviceSettingsRepository,
    private val scope: CoroutineScope,
    private val clock: Clock,
    private val fileSystem: FileSystem,
    private val ioDispatcher: CoroutineDispatcher,
    private val parseDispatcher: CoroutineDispatcher,
) : FribbLookup, AnimeListsLookup {
    /** @param directory the app's support (data) directory, where the file is kept. */
    constructor(http: HttpClient, directory: String, settings: DeviceSettingsRepository, scope: CoroutineScope) :
        this(http, Path(directory), settings, scope, Clock.System, SystemFileSystem, Dispatchers.IO, Dispatchers.Default)

    private val lock = Mutex()
    private var index: AnimeMappingIndexes? = null
    private var loading: Deferred<AnimeMappingIndexes>? = null
    private val refreshing = Mutex()

    private val file = Path(directory, FILE_NAME)

    override suspend fun lookup(movie: Boolean, anidb: Int?, tvdb: Int?, tmdb: Int?, imdb: String?): List<FribbRow> =
        indexes().fribb.lookup(movie, anidb, tvdb, tmdb, imdb)

    /** The row of MyAnimeList entry [malId]: Explore matches a catalog entry back to library external ids. */
    internal suspend fun lookupByMal(malId: Int): FribbRow? = indexes().fribb.byMal(malId)

    override suspend fun lookupEpisode(tvdbId: Int?, tmdbId: Int?, season: Int?, episode: Int?): AnimeEpisodeMatch? =
        indexes().animeLists.lookupEpisode(tvdbId, tmdbId, season, episode)

    override suspend fun animeIdsForSeason(tvdbId: Int?, tmdbId: Int?, season: Int): Set<Int> =
        indexes().animeLists.animeIdsForSeason(tvdbId, tmdbId, season)

    override suspend fun animeIdsForShow(tvdbId: Int?, tmdbId: Int?): Set<Int> =
        indexes().animeLists.animeIdsForShow(tvdbId, tmdbId)

    /** The loaded indexes, loading (and on first use downloading) them; empty when they can't be had now. */
    internal suspend fun indexes(): AnimeMappingIndexes {
        index?.let { return it }
        val load = lock.withLock {
            index?.let { return it }
            loading ?: scope.async(ioDispatcher) { loadOrDownload() }.also { loading = it }
        }
        return load.await()
    }

    /** The conditional daily check, once a load succeeded. Never throws; a check already running is enough. */
    internal suspend fun refreshIfDue() {
        if (index == null || !refreshing.tryLock()) return
        try {
            val now = clock.now().toEpochMilliseconds()
            val lastCheck = settings.value(AppSettings.animeMappingsLastCheck) ?: 0
            if (now - lastCheck < REFRESH_INTERVAL.inWholeMilliseconds) return
            val answer = fetch(settings.value(AppSettings.animeMappingsEtag))
            if (answer == null) {
                Log.d(TAG) { "anime mappings: refresh got no answer within $REQUEST_TIMEOUT" }
                return
            }
            // Any answer counts as the day's check.
            settings.set(AppSettings.animeMappingsLastCheck, now)
            when {
                answer.status == 304 -> Log.d(TAG) { "anime mappings: unchanged" }
                answer.status != 200 -> Log.d(TAG) { "anime mappings: refresh answered HTTP ${answer.status}" }
                else -> {
                    save(answer)
                    val fresh = decode(answer.body)
                    lock.withLock { index = fresh }
                    Log.i(TAG) { "anime mappings: refreshed (${fresh.summary})" }
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "anime mappings: refresh failed" }
        } finally {
            refreshing.unlock()
        }
    }

    private suspend fun loadOrDownload(): AnimeMappingIndexes {
        val loaded = try {
            readCopy() ?: download()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "anime mappings: the copy doesn't decode, deleting it so the next lookup downloads again" }
            withContext(ioDispatcher) { fileSystem.delete(file, mustExist = false) }
            AnimeMappingIndexes.EMPTY
        }
        lock.withLock {
            loading = null
            // An empty index isn't kept: the next lookup tries again, so an offline launch heals itself.
            if (!loaded.isEmpty) index = loaded
        }
        if (!loaded.isEmpty) scope.launch(ioDispatcher) { refreshIfDue() }
        return loaded
    }

    /** The disk copy's indexes, `null` when there is none; throws when it doesn't decode. */
    private suspend fun readCopy(): AnimeMappingIndexes? {
        val bytes = withContext(ioDispatcher) {
            if (fileSystem.exists(file)) fileSystem.source(file).buffered().use { it.readByteArray() } else null
        } ?: return null
        return decode(bytes)
    }

    /** The first download: kept with its ETag and as today's check. Empty when it fails. */
    private suspend fun download(): AnimeMappingIndexes {
        Log.d(TAG) { "anime mappings: no copy on disk, downloading" }
        deleteLegacyCopies()
        val answer = try {
            fetch(etag = null)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "anime mappings: download failed" }
            return AnimeMappingIndexes.EMPTY
        }
        if (answer == null || answer.status != 200) {
            Log.w(TAG) { "anime mappings: download " + (answer?.let { "answered HTTP ${it.status}" } ?: "got no answer") }
            return AnimeMappingIndexes.EMPTY
        }
        save(answer)
        // Seeds the daily check: a relaunch the same day asks nothing.
        settings.set(AppSettings.animeMappingsLastCheck, clock.now().toEpochMilliseconds())
        return decode(answer.body).also { Log.i(TAG) { "anime mappings: downloaded (${it.summary})" } }
    }

    private class Answer(val status: Int, val etag: String?, val body: ByteArray)

    /** GETs the file, with `If-None-Match` when there is an [etag]; `null` when no answer came within [REQUEST_TIMEOUT]. */
    private suspend fun fetch(etag: String?): Answer? = withContext(ioDispatcher) {
        withTimeoutOrNull(REQUEST_TIMEOUT) {
            http.prepareGet(URL) {
                if (etag != null) header(HttpHeaders.IfNoneMatch, etag)
            }.execute { response ->
                val body = if (response.status.value == 200) {
                    response.readBody { it.readBuffer(MAX_BYTES + 1) }.readByteArray()
                        .also { check(it.size <= MAX_BYTES) { "the file is larger than $MAX_BYTES bytes" } }
                } else {
                    ByteArray(0)
                }
                Answer(response.status.value, response.headers[HttpHeaders.ETag], body)
            }
        }
    }

    /** Writes [answer]'s file over the copy, and its ETag when it has one. */
    private suspend fun save(answer: Answer) {
        withContext(ioDispatcher) {
            fileSystem.createDirectories(directory)
            val partial = Path(directory, "$FILE_NAME.part")
            fileSystem.sink(partial).buffered().use { it.write(answer.body) }
            fileSystem.atomicMove(partial, file)
        }
        answer.etag?.let { settings.set(AppSettings.animeMappingsEtag, it) }
    }

    private suspend fun decode(bytes: ByteArray): AnimeMappingIndexes = withContext(parseDispatcher) { read(bytes) }

    /** The two files earlier releases downloaded on their own, before this one bundled them. */
    private suspend fun deleteLegacyCopies() = withContext(ioDispatcher) {
        for (name in LEGACY_FILE_NAMES) fileSystem.delete(Path(directory, name), mustExist = false)
    }

    companion object {
        const val URL: String = "https://github.com/edde746/anime-mappings/releases/latest/download/anime-mappings.bin.gz"
        const val FILE_NAME: String = "anime-mappings.bin.gz"

        internal val REFRESH_INTERVAL: Duration = 1.days
        internal val REQUEST_TIMEOUT: Duration = 60.seconds

        private val LEGACY_FILE_NAMES = listOf("anime-list-mini.json", "anime-list.xml")

        /** About ten times the file's size: a bound on what a wrong answer makes this hold. */
        private const val MAX_BYTES = 8L * 1024 * 1024
        private const val TAG = "TrackerIds"

        /**
         * Both indexes of an anime-mappings packed list, gzipped (its first bytes `1f 8b`) or already unpacked by the
         * transport. Throws [IllegalArgumentException] for anything that isn't a version 1 packed list.
         */
        internal fun read(bytes: ByteArray): AnimeMappingIndexes {
            val unpacked = if (bytes.size >= 2 && bytes[0] == 0x1f.toByte() && bytes[1] == 0x8b.toByte()) gunzip(bytes) else bytes
            val tables = PackedTables.read(unpacked)
            return AnimeMappingIndexes(FribbIndex.from(tables.table("fribb")), AnimeListsIndex.from(tables))
        }
    }
}
