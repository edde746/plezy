package com.edde746.plezy.ui.image

import coil3.ImageLoader
import coil3.annotation.ExperimentalCoilApi
import coil3.asImage
import coil3.decode.DecodeResult
import coil3.decode.DecodeUtils
import coil3.decode.Decoder
import coil3.decode.ImageSource
import coil3.fetch.SourceFetchResult
import coil3.request.Options
import coil3.request.maxBitmapSize
import coil3.size.Precision
import okio.use
import org.jetbrains.skia.Bitmap
import org.jetbrains.skia.Canvas
import org.jetbrains.skia.Image
import org.jetbrains.skia.Rect
import org.jetbrains.skia.SamplingMode
import org.jetbrains.skia.impl.use

/**
 * Coil's desktop decoder (`SkiaImageDecoder`) with a filtered shrink. Coil's draws the image into the size asked for
 * with Skia's default sampling, the nearest pixel: an episode's 780 px thumbnail drawn 299 px wide kept one pixel in
 * about three and looked jagged. This one decodes to the same size, Coil's (the request's size, scale and
 * [maxBitmapSize]; larger than the image only with [Precision.EXACT]), at least a pixel each way, and gets there by
 * [resample]. A file of more than [MAX_ENCODED_BYTES] (an addon's image URL may lead anywhere) fails to decode, read
 * no further, and so does one whose header declares more than [MAX_PIXELS], before any pixel is decoded.
 */
internal class FilteredSkiaDecoder(private val source: ImageSource, private val options: Options) : Decoder {
    override suspend fun decode(): DecodeResult {
        val bytes = source.source().use { encoded ->
            check(!encoded.request(MAX_ENCODED_BYTES + 1)) { "an image file of more than $MAX_ENCODED_BYTES bytes" }
            encoded.readByteArray()
        }
        val image = Image.makeFromEncoded(bytes)
        try {
            check(image.width.toLong() * image.height <= MAX_PIXELS) { "an image of ${image.width} × ${image.height} pixels" }
            val (width, height) = decodedSize(image.width, image.height, options)
            val bitmap = resample(image, width, height)
            return DecodeResult(bitmap.asImage(), isSampled = width < image.width || height < image.height)
        } finally {
            image.close()
        }
    }

    class Factory : Decoder.Factory {
        override fun create(result: SourceFetchResult, options: Options, imageLoader: ImageLoader): Decoder =
            FilteredSkiaDecoder(result.source, options)
    }
}

/** 32 MiB: far above any poster, background or logo. */
internal const val MAX_ENCODED_BYTES: Long = 32L * 1024 * 1024

/** 50 megapixels: above an 8K backdrop (33 MP); a small file can declare far more, which decoding would allocate. */
internal const val MAX_PIXELS: Long = 50_000_000

/** The size Coil's own Skia decoder gives an image of [width] × [height] for [options], at least 1 × 1. */
@OptIn(ExperimentalCoilApi::class)
private fun decodedSize(width: Int, height: Int, options: Options): Pair<Int, Int> {
    val target = DecodeUtils.computeDstSize(width, height, options.size, options.scale, options.maxBitmapSize)
    var multiplier = DecodeUtils.computeSizeMultiplier(width, height, target.first, target.second, options.scale, options.maxBitmapSize)
    if (options.precision == Precision.INEXACT) multiplier = multiplier.coerceAtMost(1.0)
    // A wide logo shrunk to a small view: its height would round down to nothing.
    return (multiplier * width).toInt().coerceAtLeast(1) to (multiplier * height).toInt().coerceAtLeast(1)
}

/**
 * [image] at [width] × [height] without aliasing: halved while it is still twice that size or more, by bilinear
 * sampling at about half (each pixel the average of the four under it), then resampled to the size by Catmull-Rom.
 * Catmull-Rom leaves an image already at the size as it is (Mitchell blurs it) and came closest to ImageMagick's
 * Lanczos on the app's thumbnails, posters and logos.
 */
private fun resample(image: Image, width: Int, height: Int): Bitmap {
    var step = image
    while (step.width / 2 >= width && step.height / 2 >= height) {
        val half = step.drawnAt(step.width / 2, step.height / 2, SamplingMode.LINEAR).use { Image.makeFromBitmap(it) }
        if (step !== image) step.close()
        step = half
    }
    return step.drawnAt(width, height, SamplingMode.CATMULL_ROM).also { if (step !== image) step.close() }
}

/** This image drawn into a new immutable bitmap of [width] × [height] with [sampling]. */
private fun Image.drawnAt(width: Int, height: Int, sampling: SamplingMode): Bitmap {
    val bitmap = Bitmap()
    bitmap.allocN32Pixels(width, height)
    Canvas(bitmap).use { canvas ->
        val source = Rect.makeWH(this.width.toFloat(), this.height.toFloat())
        canvas.drawImageRect(this, source, Rect.makeWH(width.toFloat(), height.toFloat()), sampling, null, false)
    }
    bitmap.setImmutable()
    return bitmap
}
