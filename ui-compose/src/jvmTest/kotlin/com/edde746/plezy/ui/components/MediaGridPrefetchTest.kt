package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.performScrollToIndex
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageMemoryBudget
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.image.artworkImageLoader
import com.edde746.plezy.ui.movieCard
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.CompletableDeferred
import org.jetbrains.skia.EncodedImageFormat
import org.jetbrains.skia.Image
import org.jetbrains.skia.ImageInfo
import java.io.File
import java.nio.file.Files
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A grid of posters through the app's loader: the posters on screen are asked for once each (by their cards), the two
 * rows past them ahead of time, and nothing a grid asked for keeps loading once it is gone.
 */
@OptIn(ExperimentalTestApi::class)
class MediaGridPrefetchTest {
    private val root: File = Files.createTempDirectory("artwork-cache").toFile()
    private val png = Image.makeRaster(ImageInfo.makeN32Premul(2, 2), ByteArray(16) { -1 }, 8).encodeToData(EncodedImageFormat.PNG)!!.bytes

    /** How many times each poster was asked for, by URL. */
    private val asked = ConcurrentHashMap<String, AtomicInteger>()

    /** While set, the server holds every request until it completes. */
    @Volatile
    private var hold: CompletableDeferred<Unit>? = null

    /** The requests the server is holding. */
    private val held = AtomicInteger()

    init {
        // The loader's fetches start on Main, as in the app.
        TestMain.install()
    }

    private val loader: ImageLoader = artworkImageLoader(
        PlatformContext.INSTANCE,
        HttpClient(
            MockEngine { request ->
                asked.getOrPut(request.url.toString()) { AtomicInteger() }.incrementAndGet()
                hold?.let { gate ->
                    held.incrementAndGet()
                    try {
                        gate.await()
                    } finally {
                        held.decrementAndGet()
                    }
                }
                respond(png, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "image/png"))
            },
        ),
        reduced = false,
        ImageMemoryBudget(800, 100L shl 20),
        File(root, "artwork"),
    ).also { SingletonImageLoader.setUnsafe(it) }
    private val appearance = Appearance.of(AppearanceSettings(), FormFactor.DESKTOP, supporterUnlocked = false)
    private val cards = List(300) { movieCard("m$it").copy(artwork = Artwork.fixed(url(it))) }

    @AfterTest
    fun reset() {
        hold?.complete(Unit)
        SingletonImageLoader.reset()
        loader.diskCache?.shutdown()
        root.deleteRecursively()
    }

    @Test
    fun `the posters on screen are asked for once each and the two rows past them ahead of time`() = runComposeUiTest {
        val state = LazyGridState()
        setContent {
            TvFrame {
                Box(Modifier.size(900.dp, 500.dp)) {
                    MediaGrid(cards.size, cards::getOrNull, CardShape.POSTER, PaddingValues(0.dp), onClick = {}, state = state, appearance = appearance)
                }
            }
        }
        waitForIdle()
        val info = state.layoutInfo
        val last = info.visibleItemsInfo.last().index
        val expected = (0..last + 2 * info.maxSpan).map(::url).toSet()

        waitUntil(timeoutMillis = 10_000) { asked.keys == expected }
        waitForIdle()

        assertEquals(expected, asked.keys)
        assertEquals(emptyMap(), asked.filterValues { it.get() != 1 }.mapValues { it.value.get() }, "posters asked for more than once")
    }

    @Test
    fun `a grid scrolled and then left leaves no poster loading`() = runComposeUiTest {
        hold = CompletableDeferred()
        var shown by mutableStateOf(true)
        setContent {
            TvFrame {
                Box(Modifier.size(900.dp, 500.dp)) {
                    if (shown) MediaGrid(cards.size, cards::getOrNull, CardShape.POSTER, PaddingValues(0.dp), onClick = {}, appearance = appearance)
                }
            }
        }
        waitUntil { held.get() > 0 }
        onNode(hasScrollToIndexAction()).performScrollToIndex(150)
        waitForIdle()

        shown = false
        waitForIdle()

        waitUntil(timeoutMillis = 5_000) { held.get() == 0 }
    }

    private fun url(index: Int) = "https://srv/poster/$index"
}
