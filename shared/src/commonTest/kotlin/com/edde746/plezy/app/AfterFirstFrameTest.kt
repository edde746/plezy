package com.edde746.plezy.app

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.writeString
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.days

class AfterFirstFrameTest {
    private val temp = Path(SystemTemporaryDirectory, "plezy-legacy-cache-test-${Random.nextLong().toULong()}")
    private val cache = Path(temp, LEGACY_IMAGE_CACHE)

    @AfterTest
    fun removeTemp() {
        fun delete(path: Path) {
            if (SystemFileSystem.metadataOrNull(path)?.isDirectory == true) SystemFileSystem.list(path).forEach(::delete)
            SystemFileSystem.delete(path, mustExist = false)
        }
        delete(temp)
    }

    private fun writeCache() {
        SystemFileSystem.createDirectories(Path(cache, "thumbs"))
        SystemFileSystem.sink(Path(cache, "thumbs", "a.jpg")).buffered().use { it.writeString("jpeg") }
        SystemFileSystem.sink(Path(cache, "index.json")).buffered().use { it.writeString("{}") }
    }

    @Test
    fun `the legacy image cache is deleted with its contents and the flag set`() = runTest {
        val settings = testData().deviceSettings
        writeCache()

        cleanLegacyImageCache(settings, temp.toString())

        assertFalse(SystemFileSystem.exists(cache))
        assertTrue(SystemFileSystem.exists(temp))
        assertTrue(settings.value(AppSettings.cleanedOldImageCache))
    }

    @Test
    fun `a second start leaves a cache made since alone`() = runTest {
        val settings = testData().deviceSettings
        writeCache()
        cleanLegacyImageCache(settings, temp.toString())
        writeCache()

        cleanLegacyImageCache(settings, temp.toString())

        assertTrue(SystemFileSystem.exists(Path(cache, "index.json")))
    }

    @Test
    fun `a missing cache still sets the flag`() = runTest {
        val settings = testData().deviceSettings

        cleanLegacyImageCache(settings, temp.toString())

        assertTrue(settings.value(AppSettings.cleanedOldImageCache))
    }

    @Test
    fun `a launch without the earlier releases temporary directory changes nothing`() = runTest {
        val settings = testData().deviceSettings

        cleanLegacyImageCache(settings, null)

        assertFalse(settings.value(AppSettings.cleanedOldImageCache))
    }

    @Test
    fun `a desktop with start in fullscreen on enters fullscreen once`() = runTest {
        val off = FakeAppPlatform(formFactor = FormFactor.DESKTOP)
        afterFirstFrame(testGraph(), off)
        runCurrent()
        assertEquals(emptyList(), off.log)

        val graph = testGraph()
        graph.data.deviceSettings.set(AppSettings.startInFullscreen, true)
        val desktop = FakeAppPlatform(formFactor = FormFactor.DESKTOP)
        afterFirstFrame(graph, desktop)
        afterFirstFrame(graph, desktop)
        runCurrent()
        assertEquals(listOf("fullscreen true"), desktop.log)

        val phoneGraph = testGraph()
        phoneGraph.data.deviceSettings.set(AppSettings.startInFullscreen, true)
        val phone = FakeAppPlatform(formFactor = FormFactor.HANDHELD)
        afterFirstFrame(phoneGraph, phone)
        runCurrent()
        assertEquals(emptyList(), phone.log)
    }

    @Test
    fun `a start deletes unpinned cache rows older than 30 days and keeps pinned ones`() = runTest {
        val clock = TestClock()
        val data = LocalData(inMemoryDatabase(), { clock.now }, StandardTestDispatcher(testScheduler))
        val cache = data.apiCache
        val body = buildJsonObject { put("title", "a") }
        cache.put("srv", "/old", body)
        cache.put("srv", "/pinned", body)
        cache.pin("srv", "/pinned")
        clock.now += 1.days.inWholeMilliseconds
        cache.put("srv", "/recent", body)
        clock.now += 30.days.inWholeMilliseconds

        afterFirstFrame(testGraph(data = data), FakeAppPlatform(formFactor = FormFactor.HANDHELD))
        runCurrent()

        assertNull(cache.get("srv", "/old"))
        assertEquals(body, cache.get("srv", "/pinned"))
        assertEquals(body, cache.get("srv", "/recent"))
    }
}
