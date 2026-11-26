package com.edde746.plezy.ui.image

import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asComposeImageBitmap
import androidx.compose.ui.graphics.asSkiaBitmap
import coil3.Bitmap
import coil3.BitmapImage
import coil3.ComponentRegistry
import coil3.ImageLoader
import org.jetbrains.skia.ColorAlphaType

internal actual fun Bitmap.toComposeBitmap(): ImageBitmap = asComposeImageBitmap()

internal actual fun ImageBitmap.toCoilBitmap(): Bitmap = asSkiaBitmap()

internal actual fun ImageLoader.Builder.tierBitmaps(reduced: Boolean): ImageLoader.Builder = this

internal actual fun ComponentRegistry.Builder.addDecoders() {
    add(FilteredSkiaDecoder.Factory())
}

internal actual fun argbBitmap(pixels: IntArray, width: Int, height: Int): Bitmap {
    val bytes = ByteArray(pixels.size * 4)
    pixels.forEachIndexed { i, pixel ->
        bytes[i * 4] = (pixel and 0xFF).toByte()
        bytes[i * 4 + 1] = (pixel shr 8 and 0xFF).toByte()
        bytes[i * 4 + 2] = (pixel shr 16 and 0xFF).toByte()
        bytes[i * 4 + 3] = (pixel ushr 24).toByte()
    }
    val info = org.jetbrains.skia.ImageInfo(width, height, org.jetbrains.skia.ColorType.BGRA_8888, org.jetbrains.skia.ColorAlphaType.UNPREMUL)
    return Bitmap().apply {
        allocPixels(info)
        installPixels(info, bytes, width * 4)
    }
}

internal actual val coil3.Image.opaque: Boolean
    get() = (this as? BitmapImage)?.bitmap?.alphaType == ColorAlphaType.OPAQUE
