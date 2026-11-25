package com.edde746.plezy.crash

import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

class MemoryPressureTest {
    private val sent = mutableListOf<Breadcrumb>()
    private val start = Instant.parse("2026-10-20T16:36:39Z")
    private var now = start
    private val pressure = MemoryPressure { now }

    @BeforeTest
    fun install() {
        CrashCapture.breadcrumbs = CrashCapture.BreadcrumbSink { if (it.category == MemoryPressure.CATEGORY) sent += it }
    }

    @AfterTest
    fun remove() {
        CrashCapture.breadcrumbs = null
        MemoryPressure.playback = null
    }

    private fun warnAt(after: Duration, before: Map<String, Any> = emptyMap(), release: () -> Map<String, Any> = { emptyMap() }) {
        now = start + after
        pressure.onPressure(before, release)
    }

    @Test
    fun `records what was held before the app released memory and what is left after`() {
        var released = false
        val before = mapOf("rssMb" to 512, "imageCacheMb" to 6, "imageCacheImages" to 2) +
            MemoryPressure.playbackData(videoSession = true, playing = true, positionMs = 60_000, bufferedMs = 95_000)
        warnAt(Duration.ZERO, before) {
            released = true
            mapOf("imageCacheMbAfter" to 0, "imageCacheImagesAfter" to 0)
        }

        assertEquals(true, released)
        val breadcrumb = sent.single()
        assertEquals("Memory pressure", breadcrumb.message)
        assertEquals(true, breadcrumb.warning)
        assertEquals(
            mapOf(
                "rssMb" to 512, "imageCacheMb" to 6, "imageCacheImages" to 2, "videoSession" to true, "playbackActive" to true,
                "bufferAheadMs" to 35_000L, "imageCacheMbAfter" to 0, "imageCacheImagesAfter" to 0,
            ),
            breadcrumb.data,
        )
    }

    @Test
    fun `a burst records once and the next breadcrumb counts the warnings it absorbed`() {
        var releases = 0
        val release = { releases++; emptyMap<String, Any>() }
        warnAt(Duration.ZERO, release = release)
        warnAt(200.milliseconds, release = release)
        warnAt(2.seconds, release = release)
        warnAt(29.seconds, release = release)
        assertEquals(1, sent.size)
        assertEquals(4, releases, "every warning still releases memory")
        assertFalse("suppressed" in sent.single().data)

        warnAt(MemoryPressure.INTERVAL)
        assertEquals(2, sent.size)
        assertEquals(3, sent.last().data["suppressed"])

        warnAt(MemoryPressure.INTERVAL * 2)
        assertEquals(3, sent.size)
        assertFalse("suppressed" in sent.last().data)
    }

    @Test
    fun `a clock set back records again at once`() {
        warnAt(10.seconds)
        warnAt(Duration.ZERO)
        assertEquals(2, sent.size)
    }

    @Test
    fun `the image cache is reported in whole megabytes before and after the release`() {
        assertEquals(
            mapOf<String, Any>("imageCacheMb" to 6L, "imageCacheImages" to 2),
            MemoryPressure.imageCacheData(6L * 1024 * 1024 + 1000, 2, after = false),
        )
        assertEquals(
            mapOf<String, Any>("imageCacheMbAfter" to 0L, "imageCacheImagesAfter" to 0),
            MemoryPressure.imageCacheData(0, 0, after = true),
        )
    }

    @Test
    fun `reports player fields only for a built player and never a negative buffer`() {
        assertEquals(mapOf<String, Any>("videoSession" to false), MemoryPressure.currentPlayback())
        assertEquals(mapOf<String, Any>("videoSession" to true), MemoryPressure.playbackData(true, null, 0, 0))

        // A forward seek past the cached range leaves the playhead ahead of the cache's end until it refills.
        MemoryPressure.playback = { MemoryPressure.playbackData(true, playing = false, positionMs = 300_000, bufferedMs = 120_000) }
        assertEquals(
            mapOf<String, Any>("videoSession" to true, "playbackActive" to false, "bufferAheadMs" to 0L),
            MemoryPressure.currentPlayback(),
        )
    }

    @Test
    fun `breadcrumbs left before a crash reporter runs reach it once it starts`() {
        CrashCapture.breadcrumbs = null
        CrashCapture.breadcrumb(Breadcrumb("startup.phase", "database_ready"))
        val trail = mutableListOf<String>()
        CrashCapture.breadcrumbs = CrashCapture.BreadcrumbSink { trail += it.message }
        CrashCapture.breadcrumb(Breadcrumb("startup.phase", "main_screen"))
        assertEquals(listOf("database_ready", "main_screen"), trail)

        CrashCapture.breadcrumbs = null
        CrashCapture.breadcrumbs = CrashCapture.BreadcrumbSink { trail += it.message }
        assertEquals(2, trail.size, "each waiting breadcrumb is handed over once")
    }
}
