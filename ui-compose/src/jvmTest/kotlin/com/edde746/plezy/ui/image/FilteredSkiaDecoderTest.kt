package com.edde746.plezy.ui.image

import coil3.BitmapImage
import coil3.PlatformContext
import coil3.decode.ImageSource
import coil3.request.Options
import coil3.size.Scale
import coil3.size.Size
import kotlinx.coroutines.runBlocking
import okio.Buffer
import okio.FileSystem
import okio.Source
import okio.Timeout
import okio.buffer
import org.jetbrains.skia.EncodedImageFormat
import org.jetbrains.skia.Image
import org.jetbrains.skia.ImageInfo
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class FilteredSkiaDecoderTest {
    @Test
    fun anImageShrunkToItsViewAveragesItsPixelsInsteadOfPickingThem() = runBlocking {
        // An episode thumbnail's size in black and white columns 1 px wide, the finest detail an image has: shrunk to
        // the 299 × 168 a thumbnail is drawn at 150 %, picking pixels leaves black and white bands; averaging, grey.
        val width = 780
        val height = 439
        // Opaque: every fourth byte (alpha) full.
        val pixels = ByteArray(width * height * 4) { if (it % 4 == 3 || (it / 4) % width % 2 == 1) -1 else 0 }
        val png = Image.makeRaster(ImageInfo.makeN32Premul(width, height), pixels, width * 4)
            .encodeToData(EncodedImageFormat.PNG)!!.bytes
        val options = Options(PlatformContext.INSTANCE, size = Size(299, 168), scale = Scale.FILL)

        val result = FilteredSkiaDecoder(ImageSource(Buffer().write(png), FileSystem.SYSTEM), options).decode()

        val bitmap = (result.image as BitmapImage).bitmap
        assertEquals(299 to 168, bitmap.width to bitmap.height)
        val decoded = bitmap.readPixels()!!
        val off = decoded.indices.filter { it % 4 != 3 }.map { decoded[it].toInt() and 0xFF }.filter { it !in 112..143 }
        assertTrue(off.isEmpty(), "${off.size} channel values off grey, e.g. ${off.take(8)}")
    }

    /** A logo far wider than tall (2000 × 20) fitted into a 40 dp square keeps a pixel of height, rather than none. */
    @Test
    fun aVeryWideImageShrunkToASmallViewKeepsAPixelOfHeight() = runBlocking {
        val png = Image.makeRaster(ImageInfo.makeN32Premul(2000, 20), ByteArray(2000 * 20 * 4) { -1 }, 2000 * 4)
            .encodeToData(EncodedImageFormat.PNG)!!.bytes
        val options = Options(PlatformContext.INSTANCE, size = Size(40, 40), scale = Scale.FIT)

        val result = FilteredSkiaDecoder(ImageSource(Buffer().write(png), FileSystem.SYSTEM), options).decode()

        val bitmap = (result.image as BitmapImage).bitmap
        assertEquals(40 to 1, bitmap.width to bitmap.height)
    }

    /** A file past any image's size (an addon's image URL leading to a huge download) fails, read no further. */
    @Test
    fun aFileLargerThanAnyImageFailsWithoutBeingReadWhole() {
        var read = 0L
        // Zeros, twice the most an image may be.
        val huge = object : Source {
            override fun read(sink: Buffer, byteCount: Long): Long {
                if (read >= 2 * MAX_ENCODED_BYTES) return -1
                val n = minOf(byteCount, 2 * MAX_ENCODED_BYTES - read)
                sink.write(ByteArray(n.toInt()))
                read += n
                return n
            }

            override fun timeout() = Timeout.NONE

            override fun close() = Unit
        }
        val options = Options(PlatformContext.INSTANCE, size = Size(40, 40), scale = Scale.FIT)

        assertFailsWith<IllegalStateException> {
            runBlocking { FilteredSkiaDecoder(ImageSource(huge.buffer(), FileSystem.SYSTEM), options).decode() }
        }
        assertTrue(read <= MAX_ENCODED_BYTES + 64 * 1024, "read $read bytes")
    }

    /** A small file whose header declares 30000 × 30000 fails before its pixels are decoded into gigabytes. */
    @Test
    fun anImageDeclaringTooManyPixelsFails() {
        val png = Image.makeRaster(ImageInfo.makeN32Premul(1, 1), ByteArray(4) { -1 }, 4).encodeToData(EncodedImageFormat.PNG)!!.bytes
        // IHDR's width and height (bytes 16-23), and its CRC over the chunk's type and data (bytes 12-28).
        val declared = java.nio.ByteBuffer.wrap(png).putInt(16, 30_000).putInt(20, 30_000)
        val crc = java.util.zip.CRC32().apply { update(png, 12, 17) }.value
        declared.putInt(29, crc.toInt())
        val options = Options(PlatformContext.INSTANCE, size = Size(40, 40), scale = Scale.FIT)

        val failure = assertFailsWith<IllegalStateException> {
            runBlocking { FilteredSkiaDecoder(ImageSource(Buffer().write(png), FileSystem.SYSTEM), options).decode() }
        }
        assertEquals("an image of 30000 × 30000 pixels", failure.message)
    }
}
