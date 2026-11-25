package com.edde746.plezy.ui

import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.onRoot
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.asImage
import coil3.decode.DataSource
import coil3.intercept.Interceptor
import coil3.request.ErrorResult
import coil3.request.ImageResult
import coil3.request.SuccessResult
import com.edde746.plezy.ui.image.SizedArtwork
import org.jetbrains.skia.Bitmap
import kotlin.math.roundToInt

/** Artwork paths that load as one plain colour ([colourImages]). */
internal const val RED_ART = "/art/red"
internal const val GREEN_ART = "/art/green"
internal const val BLUE_ART = "/art/blue"

/** An artwork path that never loads. */
internal const val BROKEN_ART = "/art/broken"

private val COLOURS = mapOf(RED_ART to 0xFFFF0000.toInt(), GREEN_ART to 0xFF00FF00.toInt(), BLUE_ART to 0xFF0000FF.toInt())

/**
 * Makes Coil's singleton loader (until [SingletonImageLoader.reset]) load [RED_ART], [GREEN_ART] and [BLUE_ART] as
 * their colours and fail every other image, noting each artwork path asked for in [requested].
 */
internal fun colourImages(requested: MutableList<String>) {
    val loader = object : Interceptor {
        override suspend fun intercept(chain: Interceptor.Chain): ImageResult {
            val path = (chain.request.data as? SizedArtwork)?.artwork?.path
            path?.let(requested::add)
            val colour = COLOURS[path] ?: return ErrorResult(null, chain.request, IllegalStateException("$path doesn't load"))
            val bitmap = Bitmap().apply {
                allocN32Pixels(4, 4)
                erase(colour)
            }
            return SuccessResult(bitmap.asImage(), chain.request, DataSource.NETWORK)
        }
    }
    SingletonImageLoader.setUnsafe(ImageLoader.Builder(PlatformContext.INSTANCE).components { add(loader) }.build())
}

/** The colour drawn at ([x], [y]) dp: `red`, `green` or `blue` where that channel stands out, else `none`. */
@OptIn(ExperimentalTestApi::class)
internal fun ComposeUiTest.colourAt(x: Int, y: Int): String {
    val pixels = onRoot().captureToImage().toPixelMap()
    val pixel = pixels[(x * density.density).roundToInt(), (y * density.density).roundToInt()]
    val channels = mapOf("red" to pixel.red, "green" to pixel.green, "blue" to pixel.blue)
    val (name, value) = channels.maxBy { it.value }
    return if (channels.all { it.key == name || value - it.value > 0.1f }) name else "none"
}
