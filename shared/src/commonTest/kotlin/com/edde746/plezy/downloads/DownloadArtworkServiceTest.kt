package com.edde746.plezy.downloads

import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.artworkStorageKey
import com.edde746.plezy.backend.buildArtworkSpecs
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readByteArray
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadArtworkServiceTest {
    private val data = testData()
    private val root = StorageRoot()
    private val storage = DownloadStorageService(root.platform(), data.deviceSettings)
    private val server = ServerId("srv")

    @AfterTest
    fun tearDown() {
        data.close()
        root.delete()
    }

    /** The service over a server answering every request with [status] and [body], all on the test's virtual time. */
    private fun TestScope.service(status: HttpStatusCode = HttpStatusCode.OK, body: String = "image") =
        service(MockServer(this) { respond(body, status) })

    private fun TestScope.service(server: MockServer) =
        DownloadArtworkService(storage, MediaServerHttpClient(server.http), StandardTestDispatcher(testScheduler))

    private fun read(path: String) = SystemFileSystem.source(Path(path)).buffered().use { it.readByteArray() }

    @Test
    fun buildArtworkSpecsIncludesAllStandardArtworkWithSanitizedLocalKeys() {
        val item = MediaItem(
            id = "item-1",
            backend = BackendKind.JELLYFIN,
            kind = MediaKind.MOVIE,
            serverId = "srv",
            thumbPath = "https://jf/Items/1/Images/Primary?tag=p&api_key=secret",
            clearLogoPath = "https://jf/Items/1/Images/Logo?tag=l&api_key=secret",
            artPath = "https://jf/Items/1/Images/Backdrop/0?tag=b&api_key=secret",
            backgroundSquarePath = "https://jf/Items/1/Images/Thumb?tag=s&api_key=secret",
        )

        val specs = buildArtworkSpecs(item) { it }

        assertEquals(4, specs.size)
        assertTrue(specs.none { "api_key" in it.localKey })
        assertTrue(specs.all { "api_key=secret" in it.url })
    }

    @Test
    fun localPathsNormalizeTokenizedJellyfinUrls() = runTest {
        storage.initialize()
        val service = service()
        assertEquals(
            service.localPath(server, "https://jf/Items/1/Images/Logo?tag=abc"),
            service.localPath(server, "https://jf/Items/1/Images/Logo?tag=abc&api_key=secret"),
        )
    }

    @Test
    fun theEarlierReleasesArtworkFilesAreFoundByTheRawPaths() = runTest {
        storage.initialize()
        val service = service()
        // The names the earlier releases gave these images' files on the server `srv`.
        val earlierNames = mapOf(
            "https://jf.example/i?name=a%20b&api_key=x" to "315db023b09153509e93c18c052c8812.jpg",
            "https://jf.example/i?a=1&b=2&a=3&api_key=k" to "335497563fe9f3a95c2dda8286f35d14.jpg",
            "https://jf.example/i?title=Am%c3%a9lie&api_key=k" to "970ddeb130bd01f04b938e2774dd5da9.jpg",
            "HTTPS://JF.Example:443/Items/A%7e%41%2f?tag=1&api_key=k" to "49bd216b6efa63b092c9610347e82952.jpg",
        )
        for ((raw, name) in earlierNames) {
            val file = service.localPath(server, raw)
            assertEquals(name, Path(file).name, raw)
            writeFile(file, "image")
            assertTrue(service.existsUsable(server, raw), raw)
        }
    }

    @Test
    fun aStoredPathIsGivenOnlyWhileItsFileIsThere() = runTest {
        storage.initialize()
        val service = service()
        val raw = "https://jf/Items/1/Images/Primary?tag=p&api_key=secret"
        assertNull(service.localPathSync(server, raw), "never saved")

        val file = service.localPath(server, raw)
        writeFile(file, "image")
        assertEquals(file, service.localPathSync(server, raw))

        SystemFileSystem.delete(Path(file))
        assertNull(service.localPathSync(server, raw), "deleted since")
    }

    @Test
    fun downloadSingleArtworkReplacesUnusableExistingFiles() = runTest {
        storage.initialize()
        val service = service(body = "valid image bytes")
        val raw = "https://jf/Items/1/Images/Logo?tag=abc&api_key=secret"
        val file = service.localPath(server, raw)
        writeFile(file, "<html>not an image</html>")

        assertTrue(service.downloadSingleArtwork(server, DownloadArtworkSpec(artworkStorageKey(raw), "https://example.test/logo.png")))
        assertContentEquals("valid image bytes".encodeToByteArray(), read(file))
        assertTrue(service.existsUsable(server, raw))
    }

    @Test
    fun artworkSettlementReportsHttpAndInvalidImageFailures() = runTest {
        storage.initialize()
        val missing = service(HttpStatusCode.NotFound, "not found")
        val invalid = service(body = "<html>error</html>")

        assertFalse(missing.ensureArtworkSpecs(server, listOf(DownloadArtworkSpec("/missing.jpg", "https://example.test/missing.jpg"))))
        assertFalse(invalid.ensureArtworkSpecs(server, listOf(DownloadArtworkSpec("/invalid.jpg", "https://example.test/invalid.jpg"))))
        assertFalse(missing.existsUsable(server, "/missing.jpg"))
        assertFalse(invalid.existsUsable(server, "/invalid.jpg"))
        assertFalse(exists(missing.localPath(server, "/missing.jpg") + ".download"), "no partial file is left")
    }

    @Test
    fun emptyAndJsonBodiesAreNotArtwork() = runTest {
        storage.initialize()
        assertFalse(service(body = "").downloadSingleArtwork(server, DownloadArtworkSpec("/empty.jpg", "https://example.test/empty.jpg")))
        assertFalse(service(body = "  {\"error\":1}").downloadSingleArtwork(server, DownloadArtworkSpec("/json.jpg", "https://example.test/json.jpg")))
        assertFalse(exists(storage.getArtworkPathFromThumb(server, "/json.jpg")))
    }

    @Test
    fun downloadSingleArtworkSharesOneTransferBetweenDuplicateRequests() = runTest {
        storage.initialize()
        val release = CompletableDeferred<Unit>()
        val mock = MockServer(this) {
            release.await()
            respond("valid image bytes")
        }
        val service = service(mock)
        val raw = "https://jf/Items/1/Images/Logo?tag=abc&api_key=secret"
        val spec = DownloadArtworkSpec(artworkStorageKey(raw), "https://example.test/logo.png")

        val first = async { service.downloadSingleArtwork(server, spec) }
        runCurrent()
        val second = async { service.downloadSingleArtwork(server, spec) }
        runCurrent()
        release.complete(Unit)

        assertEquals(listOf(true, true), listOf(first, second).awaitAll())
        assertEquals(1, mock.requests.size)
        assertTrue(service.existsUsable(server, raw))
    }
}
