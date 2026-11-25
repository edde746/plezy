package com.edde746.plezy.ui.image

import coil3.PlatformContext
import coil3.asImage
import coil3.disk.DiskCache
import coil3.memory.MemoryCache
import coil3.network.NetworkClient
import coil3.network.NetworkRequest
import coil3.network.NetworkResponse
import coil3.request.ImageRequest
import coil3.request.SuccessResult
import com.edde746.plezy.image.ArtworkCache
import com.edde746.plezy.image.ImageMemoryBudget
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import java.nio.file.FileSystems
import java.nio.file.attribute.PosixFilePermissions
import java.util.concurrent.TimeUnit
import coil3.network.NetworkResponseBody
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import okio.Buffer
import okio.BufferedSink
import kotlin.time.Duration.Companion.milliseconds
import okio.ByteString.Companion.encodeUtf8
import okio.FileSystem
import okio.IOException
import okio.Path
import okio.Path.Companion.toOkioPath
import org.jetbrains.skia.Bitmap
import org.jetbrains.skia.EncodedImageFormat
import org.jetbrains.skia.Image
import org.jetbrains.skia.ImageInfo
import java.io.File
import java.nio.file.Files
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ArtworkLoaderTest {
    private val fileSystem = FileSystem.SYSTEM

    /** The platform's cache folder: the loader's folder and its lock file go in it. */
    private val root: Path = Files.createTempDirectory("artwork-cache").toOkioPath()
    private val directory: Path = root / "artwork"

    @AfterTest
    fun deleteDirectory() = fileSystem.deleteRecursively(root)

    @Test
    fun `the caches key an image without its token and its download carries the token`() = runBlocking {
        val token = "secret-token"
        val url = "https://srv.example:32400/photo/:/transcode?width=200&minSize=1" +
            "&url=%2Flibrary%2Fmetadata%2F1%2Fthumb%2F99%3FX-Plex-Token%3D$token&X-Plex-Token=$token"
        val png = Image.makeRaster(ImageInfo.makeN32Premul(2, 2), ByteArray(16) { -1 }, 8).encodeToData(EncodedImageFormat.PNG)!!.bytes
        val requests = mutableListOf<HttpRequestData>()
        val http = HttpClient(
            MockEngine { request ->
                requests += request
                respond(png, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "image/png"))
            },
        )
        val loader = artworkImageLoader(PlatformContext.INSTANCE, http, reduced = false, ImageMemoryBudget(800, 100L shl 20), directory.toFile())

        val result = loader.execute(ImageRequest.Builder(PlatformContext.INSTANCE).data(url).size(2, 2).build())

        assertIs<SuccessResult>(result)
        val sent = requests.single().url
        assertEquals(token, sent.parameters["X-Plex-Token"])
        assertTrue("X-Plex-Token=$token" in sent.parameters["url"].orEmpty())
        val memoryKeys = loader.memoryCache!!.keys
        assertTrue(memoryKeys.isNotEmpty())
        assertTrue(memoryKeys.none { key -> token in key.key || key.extras.values.any { token in it } })
        loader.diskCache!!.openSnapshot(ArtworkCache.key(url))!!.close()
        // Its journal closed, so the directory can go on Windows too.
        loader.diskCache!!.shutdown()
        loader.shutdown()
        val files = fileSystem.listRecursively(directory).filter { fileSystem.metadata(it).isRegularFile }.toList()
        assertTrue(files.isNotEmpty())
        for (file in files) {
            assertFalse(token in file.name)
            assertFalse(token in fileSystem.read(file) { readByteString() }.utf8(), "$file holds the token")
        }
    }

    @Test
    fun `as the disk cache opens it drops images written over 14 days ago and the oldest past 3000`() {
        val now = System.currentTimeMillis()
        val keys = List(ArtworkCache.MAX_ENTRIES + 2) { "image$it" }
        val cache = DiskCache.Builder().directory(directory).build()
        for (key in keys) {
            val editor = cache.openEditor(key)!!
            fileSystem.write(editor.metadata) { writeUtf8("metadata") }
            fileSystem.write(editor.data) { writeUtf8("image") }
            editor.commit()
        }
        cache.shutdown()
        // Coil names an entry's files by its key's SHA-256: the first written 15 days ago, the rest a second apart.
        keys.forEachIndexed { index, key ->
            val writtenAt = if (index == 0) now - 15L * 24 * 60 * 60 * 1000 else now - index * 1000L
            assertTrue(File((directory / "${key.encodeUtf8().sha256().hex()}.1").toString()).setLastModified(writtenAt))
        }

        sweepArtworkCache(fileSystem, directory, now)

        val reopened = DiskCache.Builder().directory(directory).build()
        assertNull(reopened.openSnapshot(keys.first()))
        assertNull(reopened.openSnapshot(keys.last()))
        assertNotNull(reopened.openSnapshot(keys[1])).close()
        assertNotNull(reopened.openSnapshot(keys[ArtworkCache.MAX_ENTRIES])).close()
        reopened.shutdown()
        assertEquals(ArtworkCache.MAX_ENTRIES, fileSystem.list(directory).count { it.name.endsWith(".1") })
    }

    @Test
    fun `no more requests than permitted run at once`() = runBlocking {
        var active = 0
        var most = 0
        val gate = CompletableDeferred<Unit>()
        val client = LimitedNetworkClient(
            object : NetworkClient {
                override suspend fun <T> executeRequest(request: NetworkRequest, block: suspend (response: NetworkResponse) -> T): T {
                    most = maxOf(most, ++active)
                    gate.await()
                    active--
                    return block(NetworkResponse())
                }
            },
            permits = 6,
        )

        val requests = List(20) { launch { client.executeRequest(NetworkRequest("https://srv/$it")) {} } }
        repeat(20) { yield() }
        assertEquals(6, active)
        gate.complete(Unit)
        requests.joinAll()

        assertEquals(6, most)
    }

    @Test
    fun `a transfer with no headers within the stall time is aborted and frees its permit`() = runTest {
        val hang = CompletableDeferred<Unit>()
        var calls = 0
        val client = LimitedNetworkClient(
            object : NetworkClient {
                override suspend fun <T> executeRequest(request: NetworkRequest, block: suspend (response: NetworkResponse) -> T): T {
                    if (calls++ == 0) hang.await()
                    return block(NetworkResponse())
                }
            },
            permits = 1,
            stall = 200.milliseconds,
            time = testScheduler.timeSource,
        )
        val request = NetworkRequest("https://srv/poster?X-Plex-Token=secret-token")
        val stalled = assertFailsWith<StalledTransferException> { client.executeRequest(request) {} }
        assertFalse("secret-token" in stalled.message.orEmpty(), "the stall's message holds the token: ${stalled.message}")
        assertEquals("loaded", client.executeRequest(request) { "loaded" })
    }

    @Test
    fun `a body that keeps arriving is never stalled however long it takes`() = runTest {
        // The body's bytes come on a dispatcher of their own, as a transfer's come on another thread than the watch's.
        val transfer = StandardTestDispatcher(testScheduler, "transfer")
        val client = LimitedNetworkClient(
            object : NetworkClient {
                override suspend fun <T> executeRequest(request: NetworkRequest, block: suspend (response: NetworkResponse) -> T): T =
                    block(NetworkResponse(body = object : NetworkResponseBody {
                        override suspend fun writeTo(sink: BufferedSink) = withContext(transfer) {
                            // 600 ms in all, a chunk every 100: each within the 300 ms stall time.
                            repeat(6) {
                                delay(100)
                                sink.write(ByteArray(10_000))
                            }
                        }

                        override suspend fun writeTo(fileSystem: FileSystem, path: Path) = error("unused")

                        override fun close() {}
                    }))
            },
            permits = 1,
            stall = 300.milliseconds,
            time = testScheduler.timeSource,
        )
        val received = Buffer()
        client.executeRequest(NetworkRequest("https://srv/poster")) { it.body!!.writeTo(received) }
        assertEquals(60_000, received.size)
        assertEquals(600, currentTime)
    }

    @Test
    fun `a body that stops arriving is aborted`(): Unit = runTest {
        val transfer = StandardTestDispatcher(testScheduler, "transfer")
        val client = LimitedNetworkClient(
            object : NetworkClient {
                override suspend fun <T> executeRequest(request: NetworkRequest, block: suspend (response: NetworkResponse) -> T): T =
                    block(NetworkResponse(body = object : NetworkResponseBody {
                        override suspend fun writeTo(sink: BufferedSink) = withContext(transfer) {
                            delay(100)
                            sink.write(ByteArray(10_000))
                            awaitCancellation()
                        }

                        override suspend fun writeTo(fileSystem: FileSystem, path: Path) = error("unused")

                        override fun close() {}
                    }))
            },
            permits = 1,
            stall = 200.milliseconds,
            time = testScheduler.timeSource,
        )
        assertFailsWith<StalledTransferException> {
            client.executeRequest(NetworkRequest("https://srv/poster")) { it.body!!.writeTo(Buffer()) }
        }
        // Aborted 200 ms after its last bytes, not 200 ms after it began.
        assertEquals(300, currentTime)
    }

    @Test
    fun `a failed or cancelled request releases its permit`() = runBlocking {
        val hang = CompletableDeferred<Unit>()
        var calls = 0
        val client = LimitedNetworkClient(
            object : NetworkClient {
                override suspend fun <T> executeRequest(request: NetworkRequest, block: suspend (response: NetworkResponse) -> T): T {
                    when (calls++) {
                        0 -> throw IOException("refused")
                        1 -> hang.await()
                    }
                    return block(NetworkResponse())
                }
            },
            permits = 1,
        )
        val request = NetworkRequest("https://srv/poster")

        assertFailsWith<IOException> { client.executeRequest(request) {} }
        val hung = launch { client.executeRequest(request) {} }
        repeat(5) { yield() }
        hung.cancel()

        assertEquals("loaded", withTimeout(5_000) { client.executeRequest(request) { "loaded" } })
    }

    @Test
    fun `past its image limit the memory cache drops the least recently used`() {
        val cache = CountedMemoryCache(MemoryCache.Builder().maxSizeBytes(100L shl 20).build(), maxImages = 2)
        val (first, second, third) = List(3) { MemoryCache.Key("image$it") }
        cache[first] = pixel()
        cache[second] = pixel()
        assertNotNull(cache[first])

        cache[third] = pixel()

        assertEquals(setOf(first, third), cache.keys)
    }

    @Test
    fun `the app image memory reports what the loader holds and empties on eviction`() = runBlocking {
        val png = Image.makeRaster(ImageInfo.makeN32Premul(2, 2), ByteArray(16) { -1 }, 8).encodeToData(EncodedImageFormat.PNG)!!.bytes
        val http = HttpClient(MockEngine { respond(png, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "image/png")) })
        val loader = artworkImageLoader(PlatformContext.INSTANCE, http, reduced = false, ImageMemoryBudget(800, 100L shl 20), directory.toFile())

        assertIs<SuccessResult>(loader.execute(ImageRequest.Builder(PlatformContext.INSTANCE).data("https://srv/poster").size(2, 2).build()))

        assertEquals(1, ImageMemory.images)
        assertTrue(ImageMemory.bytes > 0)
        ImageMemory.evict()
        assertEquals(mapOf<String, Any>("imageCacheMbAfter" to 0L, "imageCacheImagesAfter" to 0), ImageMemory.pressureData(after = true))
        loader.diskCache!!.shutdown()
        loader.shutdown()
    }

    @Test
    fun `artwork is cached in the folder given and only its owner can open the folder`() = runBlocking {
        val url = "https://srv/poster"
        val loader = artworkImageLoader(PlatformContext.INSTANCE, server(), reduced = false, ImageMemoryBudget(800, 100L shl 20), directory.toFile())

        assertIs<SuccessResult>(loader.execute(ImageRequest.Builder(PlatformContext.INSTANCE).data(url).size(2, 2).build()))
        loader.diskCache!!.shutdown()
        loader.shutdown()

        val image = "${ArtworkCache.key(url).encodeUtf8().sha256().hex()}.1"
        assertTrue(fileSystem.exists(directory / image))
        assertFalse(fileSystem.exists(FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "coil3_disk_cache" / image))
        if ("posix" in FileSystems.getDefault().supportedFileAttributeViews()) {
            assertEquals(PosixFilePermissions.fromString("rwx------"), Files.getPosixFilePermissions(directory.toNioPath()))
        }
    }

    @Test
    fun `a second loader on a folder in use keeps its artwork in memory and the folder opens again once let go`() = runBlocking {
        val first = artworkImageLoader(PlatformContext.INSTANCE, server(), reduced = false, ImageMemoryBudget(800, 100L shl 20), directory.toFile())
        val second = artworkImageLoader(PlatformContext.INSTANCE, server(), reduced = false, ImageMemoryBudget(800, 100L shl 20), directory.toFile())
        assertNotNull(first.diskCache)

        assertNull(second.diskCache)
        assertIs<SuccessResult>(second.execute(ImageRequest.Builder(PlatformContext.INSTANCE).data("https://srv/poster").size(2, 2).build()))

        first.diskCache!!.shutdown()
        val third = artworkImageLoader(PlatformContext.INSTANCE, server(), reduced = false, ImageMemoryBudget(800, 100L shl 20), directory.toFile())
        assertNotNull(third.diskCache).shutdown()
        listOf(first, second, third).forEach { it.shutdown() }
    }

    @Test
    fun `a folder another process holds opens no disk cache until that process lets go`() {
        val java = ProcessHandle.current().info().command().get()
        val holder = ProcessBuilder(java, "-cp", System.getProperty("java.class.path"), ArtworkCacheHolder::class.java.name, directory.toString())
            .redirectError(ProcessBuilder.Redirect.INHERIT)
            .start()
        try {
            assertEquals("held", holder.inputReader().readLine())
            assertNull(openArtworkDiskCache(directory.toFile()))
        } finally {
            holder.outputStream.close()
            assertTrue(holder.waitFor(30, TimeUnit.SECONDS))
        }
        assertNotNull(openArtworkDiskCache(directory.toFile())).shutdown()
    }

    /** A server answering every request with a 2×2 white PNG. */
    private fun server(): HttpClient {
        val png = Image.makeRaster(ImageInfo.makeN32Premul(2, 2), ByteArray(16) { -1 }, 8).encodeToData(EncodedImageFormat.PNG)!!.bytes
        return HttpClient(MockEngine { respond(png, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "image/png")) })
    }

    private fun pixel() = MemoryCache.Value(Bitmap().apply { allocN32Pixels(1, 1) }.asImage())
}

/** Another Plezy process: holds the artwork disk cache in the folder its argument names until its input closes. */
object ArtworkCacheHolder {
    @JvmStatic
    fun main(args: Array<String>) {
        val cache = checkNotNull(openArtworkDiskCache(File(args[0])))
        println("held")
        System.`in`.read()
        cache.shutdown()
    }
}
