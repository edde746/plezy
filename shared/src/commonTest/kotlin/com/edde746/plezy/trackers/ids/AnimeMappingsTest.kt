package com.edde746.plezy.trackers.ids

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.settings.AppSettings
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.Instant
import kotlinx.coroutines.async
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.readByteArray
import kotlinx.io.writeString

/**
 * [AnimeMappings] against a fake of the release download: downloaded on the first lookup only, kept on disk with its
 * ETag, checked again a day later with `If-None-Match`, and never kept empty.
 */
class AnimeMappingsTest {
    private val directory = Path(SystemTemporaryDirectory, "plezy-anime-mappings-" + Random.nextLong().toULong())
    private var data: LocalData? = null

    /** This device's settings, their database on the test's scheduler, so a check waiting on it is the test's work. */
    private val TestScope.settings: DeviceSettingsRepository
        get() = (data ?: LocalData(inMemoryDatabase(), { 0L }, StandardTestDispatcher(testScheduler)).also { data = it }).deviceSettings

    private var now = Instant.fromEpochMilliseconds(1_790_000_000_000)
    private val clock = object : Clock {
        override fun now() = this@AnimeMappingsTest.now
    }

    /** What the release URL answers: status, body and ETag, or a transport failure; each request's `If-None-Match`. */
    private var answer: () -> Triple<Int, ByteArray, String?> = { Triple(200, animeMappingsExcerpt(), "\"v1\"") }
    private val requests = mutableListOf<String?>()

    @AfterTest
    fun cleanUp() {
        data?.close()
        if (SystemFileSystem.exists(directory)) {
            SystemFileSystem.list(directory).forEach { SystemFileSystem.delete(it) }
            SystemFileSystem.delete(directory)
        }
    }

    private fun TestScope.mappings(): AnimeMappings {
        val dispatcher = StandardTestDispatcher(testScheduler)
        val engine = MockEngine.create {
            this.dispatcher = dispatcher
            addHandler { request ->
                assertEquals(AnimeMappings.URL, request.url.toString())
                requests += request.headers[HttpHeaders.IfNoneMatch]
                val (status, body, etag) = answer()
                respond(body, HttpStatusCode.fromValue(status), etag?.let { headersOf(HttpHeaders.ETag, it) } ?: headersOf())
            }
        }
        return AnimeMappings(HttpClient(engine), directory, settings, backgroundScope, clock, SystemFileSystem, dispatcher, dispatcher)
    }

    private val file get() = Path(directory, AnimeMappings.FILE_NAME)

    private suspend fun AnimeMappings.bebop() = lookup(movie = false, anidb = 23, tvdb = null, tmdb = null, imdb = null).singleOrNull()?.mal

    @Test
    fun theFirstLookupDownloadsOnceForEveryCallerAndASameDayRelaunchAsksNothing() = runTest {
        val mappings = mappings()
        assertEquals(emptyList(), requests, "nothing is downloaded before a lookup")

        val first = async { mappings.bebop() }
        val second = async { mappings.lookupByMal(1)?.anidb }
        assertEquals(1 to 23, first.await() to second.await())
        assertEquals(listOf<String?>(null), requests)
        assertTrue(SystemFileSystem.exists(file))
        assertEquals("\"v1\"", settings.value(AppSettings.animeMappingsEtag))
        assertEquals(now.toEpochMilliseconds(), settings.value(AppSettings.animeMappingsLastCheck))
        // Anime-Lists from the same file.
        assertEquals(60, mappings.lookupEpisode(tvdbId = 252322, tmdbId = null, season = 2, episode = 2)?.anidbEpisode)

        now += 12.hours
        val relaunched = mappings()
        assertEquals(1, relaunched.bebop())
        runCurrent()
        assertEquals(1, requests.size, "a relaunch the same day reads the copy and checks nothing")
    }

    @Test
    fun aFailedDownloadAnswersEmptyAndTheNextLookupTriesAgain() = runTest {
        for (failure in listOf<() -> Triple<Int, ByteArray, String?>>({ Triple(503, ByteArray(0), null) }, { throw IllegalStateException("offline") })) {
            answer = failure
            val mappings = mappings()
            assertNull(mappings.bebop())
            assertFalse(SystemFileSystem.exists(file))
            assertNull(settings.value(AppSettings.animeMappingsLastCheck))

            answer = { Triple(200, animeMappingsExcerpt(), null) }
            assertEquals(1, mappings.bebop(), "an empty index isn't kept")
            SystemFileSystem.delete(file)
            settings.set(AppSettings.animeMappingsLastCheck, null)
        }
    }

    @Test
    fun aCopyThatDoesntDecodeIsDeletedAndDownloadedAgain() = runTest {
        SystemFileSystem.createDirectories(directory)
        SystemFileSystem.sink(file).buffered().use { it.writeString("not a packed list") }

        val mappings = mappings()
        assertNull(mappings.bebop())
        assertFalse(SystemFileSystem.exists(file), "the unreadable copy is gone")
        assertEquals(emptyList(), requests)

        assertEquals(1, mappings.bebop())
        assertEquals(1, requests.size)
    }

    @Test
    fun theFirstDownloadDeletesTheFilesEarlierReleasesKept() = runTest {
        SystemFileSystem.createDirectories(directory)
        for (name in listOf("anime-list-mini.json", "anime-list.xml")) SystemFileSystem.sink(Path(directory, name)).buffered().use { it.writeString("[]") }

        assertEquals(1, mappings().bebop())

        assertEquals(listOf(AnimeMappings.FILE_NAME), SystemFileSystem.list(directory).map { it.name })
    }

    @Test
    fun aDayLaterTheCopyIsCheckedByItsEtagAndANewReleaseReplacesIt() = runTest {
        val mappings = mappings()
        assertEquals(1, mappings.bebop())
        runCurrent()
        assertEquals(1, requests.size, "the check after the first load is within the day")

        // Unchanged: 304 keeps the copy; the check counts.
        now += 25.hours
        answer = { Triple(304, ByteArray(0), null) }
        mappings.refreshIfDue()
        assertEquals("\"v1\"", requests.last())
        assertEquals(now.toEpochMilliseconds(), settings.value(AppSettings.animeMappingsLastCheck))
        assertEquals(1, mappings.bebop())
        mappings.refreshIfDue()
        assertEquals(2, requests.size, "checked once a day")

        // A new release replaces the file, its ETag and the index in use.
        now += 25.hours
        val next = smallAnimeMappings()
        answer = { Triple(200, next, "\"v2\"") }
        mappings.refreshIfDue()
        assertEquals("\"v2\"", settings.value(AppSettings.animeMappingsEtag))
        assertNull(mappings.bebop())
        assertEquals(100, mappings.lookup(movie = true, anidb = 7, tvdb = null, tmdb = null, imdb = null).single().mal)
        assertTrue(next.contentEquals(SystemFileSystem.source(file).buffered().use { it.readByteArray() }))

        // A failed check changes nothing but the time of the check.
        now += 25.hours
        answer = { Triple(500, ByteArray(0), null) }
        mappings.refreshIfDue()
        assertEquals("\"v2\"", settings.value(AppSettings.animeMappingsEtag))
        assertEquals(100, mappings.lookup(movie = true, anidb = 7, tvdb = null, tmdb = null, imdb = null).single().mal)
        assertEquals(now.toEpochMilliseconds(), settings.value(AppSettings.animeMappingsLastCheck))
    }

    @Test
    fun aCopyLoadedOnALaterDayIsCheckedAfterItsLoad() = runTest {
        assertEquals(1, mappings().bebop())
        now += 25.hours
        answer = { Triple(304, ByteArray(0), null) }

        assertEquals(1, mappings().bebop())
        runCurrent()

        assertEquals(listOf(null, "\"v1\""), requests)
    }
}
