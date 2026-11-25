package com.edde746.plezy.ui.image

import android.os.Build
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.asImageBitmap
import coil3.Bitmap
import coil3.ComponentRegistry

internal actual fun Bitmap.toComposeBitmap(): ImageBitmap = asImageBitmap()

// A hardware copy, as Coil's own decodes are: the software bitmap would sit in the heap and again as a texture once drawn.
// Hardware bitmaps came with API 26; below it the software bitmap is the result.
internal actual fun ImageBitmap.toCoilBitmap(): Bitmap {
    val software = asAndroidBitmap()
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return software
    return software.copy(android.graphics.Bitmap.Config.HARDWARE, false)?.also { software.recycle() } ?: software
}

// Coil's own: Android's ImageDecoder (BitmapFactory before API 29) shrinks a JPEG in the codec and the rest bilinearly.
internal actual fun ComponentRegistry.Builder.addDecoders() = Unit

internal actual fun argbBitmap(pixels: IntArray, width: Int, height: Int): Bitmap =
    android.graphics.Bitmap.createBitmap(pixels, width, height, android.graphics.Bitmap.Config.ARGB_8888).asImageBitmap().toCoilBitmap()
