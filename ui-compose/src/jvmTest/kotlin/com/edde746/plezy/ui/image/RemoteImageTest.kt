package com.edde746.plezy.ui.image

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import coil3.PlatformContext
import coil3.SingletonImageLoader
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageMemoryBudget
import com.edde746.plezy.ui.colourAt
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.asCoroutineDispatcher
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toOkioPath
import androidx.compose.material3.Text
import androidx.compose.ui.test.onNodeWithText
import coil3.ImageLoader
import org.jetbrains.skia.Bitmap
import org.jetbrains.skia.EncodedImageFormat
import org.jetbrains.skia.Image
import java.nio.file.Files
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

/** A [RemoteImage] through the app's loader ([artworkImageLoader]), its server serving one red picture. */
@OptIn(ExperimentalTestApi::class)
class RemoteImageTest {
    /** The platform's cache folder, holding the loader's. */
    private val root: Path = Files.createTempDirectory("artwork-cache").toOkioPath()
    private val red = Bitmap().apply {
        allocN32Pixels(4, 4)
        erase(0xFFFF0000.toInt())
    }.let { Image.makeFromBitmap(it).encodeToData(EncodedImageFormat.PNG)!!.bytes }

    /** How many times the server sent the picture. */
    private val served = AtomicInteger()
    private val http = HttpClient(
        MockEngine {
            served.incrementAndGet()
            respond(red, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "image/png"))
        },
    )
    private val loaders = mutableListOf<ImageLoader>()

    @AfterTest
    fun reset() {
        SingletonImageLoader.reset()
        loaders.forEach { it.diskCache?.shutdown() }
        FileSystem.SYSTEM.deleteRecursively(root)
    }

    /** The app's loader over [server], caching in the test's folder. */
    private fun loader(server: HttpClient = http) =
        artworkImageLoader(PlatformContext.INSTANCE, server, reduced = false, ImageMemoryBudget(800, 100L shl 20), (root / "artwork").toFile()).also { loaders += it }

    /** A server that lost a poster for a moment (a proxy's 404) and has it again: the poster loads when next asked for. */
    @Test
    fun `an image that failed once loads when asked for again`() = runComposeUiTest {
        val asked = AtomicInteger()
        SingletonImageLoader.setUnsafe(
            loader(
                HttpClient(
                    MockEngine {
                        if (asked.incrementAndGet() == 1) {
                            respond("missing", HttpStatusCode.NotFound)
                        } else {
                            respond(red, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "image/png"))
                        }
                    },
                ),
            ),
        )
        var composed by mutableStateOf(true)
        var loaded: Boolean? = null
        setContent {
            if (composed) RemoteImage(Artwork.fixed("https://srv/poster"), null, Modifier.size(40.dp), blank = Color.Blue, onResult = { _, ok -> loaded = ok })
        }
        waitUntil { loaded == false }

        composed = false
        waitForIdle()
        loaded = null
        composed = true
        waitUntil { loaded == true }

        assertEquals("red", colourAt(20, 20))
        assertEquals(2, asked.get())
    }

    /** A card without its own artwork whose stand-in fails too: its placeholder, not an empty box. */
    @Test
    fun `with no artwork and a fallback that fails the error slot shows`() = runComposeUiTest {
        SingletonImageLoader.setUnsafe(loader(HttpClient(MockEngine { respond("missing", HttpStatusCode.NotFound) })))
        var failures = 0
        setContent {
            RemoteImage(
                null, null, Modifier.size(40.dp),
                fallbackArtwork = Artwork.fixed("https://srv/fallback"),
                onResult = { _, ok -> if (!ok) failures++ },
                error = { Text("placeholder") },
            )
        }
        waitUntil { failures == 1 }

        onNodeWithText("placeholder").assertExists()
    }

    /** A card scrolled away and back, or a shelf's card composed again: its picture, not its blank, in its first frame. */
    @Test
    fun `an image composed again shows at once while the loader still looks it up`() = runComposeUiTest {
        val app = loader()
        // The loader's lookups run on this one thread, which the test can hold.
        val lookups = Executors.newSingleThreadExecutor()
        SingletonImageLoader.setUnsafe(app.newBuilder().interceptorCoroutineContext(lookups.asCoroutineDispatcher()).build())
        var composed by mutableStateOf(true)
        setContent {
            if (composed) RemoteImage(Artwork.fixed("https://srv/poster"), null, Modifier.size(40.dp), blank = Color.Blue)
        }
        waitUntil { colourAt(20, 20) == "red" }

        composed = false
        waitForIdle()
        val held = CountDownLatch(1)
        lookups.execute { held.await() }
        composed = true

        assertEquals("red", colourAt(20, 20), "the image composed again showed its blank")
        held.countDown()
        lookups.shutdown()
    }

    /**
     * A card's image fetched over the network, then read from the disk cache (the app opened again, its memory cache
     * empty): each time its picture in the first frame after it loads, never a fade from its blank.
     */
    @Test
    fun `an image shows at once from the network and from the disk cache`() = runComposeUiTest {
        val app = loader()
        SingletonImageLoader.setUnsafe(app)
        var composed by mutableStateOf(true)
        var loaded = false
        setContent {
            if (composed) RemoteImage(Artwork.fixed("https://srv/poster"), null, Modifier.size(40.dp), blank = Color.Blue, onResult = { _, ok -> loaded = ok })
        }
        waitUntil { loaded }
        assertEquals("red", colourAt(20, 20), "the image fetched over the network faded in from its blank")

        composed = false
        waitForIdle()
        app.memoryCache!!.clear()
        loaded = false
        composed = true
        waitUntil { loaded }

        assertEquals("red", colourAt(20, 20), "the image from the disk cache faded in from its blank")
        assertEquals(1, served.get(), "the image was fetched again instead of read from the disk cache")
    }
}
