package com.edde746.plezy.watchnext

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** A Watch Next poster is kept only as a whole PNG, JPEG, GIF or WebP: by its magic bytes and its end. */
class ImageFormatTest {
    private fun bytes(vararg values: Int) = ByteArray(values.size) { values[it].toByte() }

    private val pngStart = intArrayOf(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
    private val pngEnd = intArrayOf(0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82)

    @Test
    fun wholeImagesOfEachFormatAreRecognized() {
        assertEquals(ImageFormat.PNG, imageFormatOf(bytes(*pngStart, 0, 0, 0, 0, *pngEnd)))
        assertEquals(ImageFormat.JPEG, imageFormatOf(bytes(0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0xFF, 0xD9)))
        assertEquals(ImageFormat.GIF, imageFormatOf(bytes(0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0, 0, 0, 0, 0, 0, 0x3B)))
        // RIFF length 8 + 4: the file is 16 bytes.
        assertEquals(ImageFormat.WEBP, imageFormatOf(bytes(0x52, 0x49, 0x46, 0x46, 8, 0, 0, 0, 0x57, 0x45, 0x42, 0x50, 0, 0, 0, 0)))
    }

    @Test
    fun cutOffFilesAndOtherBytesAreRefused() {
        assertNull(imageFormatOf(bytes(*pngStart, 0, 0, 0, 0, 0, 0, 0, 0)))
        assertNull(imageFormatOf(bytes(0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x00)))
        assertNull(imageFormatOf(bytes(0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0, 0, 0, 0, 0, 0, 0)))
        assertNull(imageFormatOf(bytes(0x52, 0x49, 0x46, 0x46, 20, 0, 0, 0, 0x57, 0x45, 0x42, 0x50, 0, 0, 0, 0)))
        assertNull(imageFormatOf("<html>not an image</html>".encodeToByteArray()))
        assertNull(imageFormatOf(ByteArray(0)))
    }
}
