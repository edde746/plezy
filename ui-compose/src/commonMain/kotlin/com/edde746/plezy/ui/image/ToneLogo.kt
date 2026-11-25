package com.edde746.plezy.ui.image

import coil3.Bitmap
import coil3.size.Size
import coil3.transform.Transformation
import com.edde746.plezy.image.analyzeLogoTone
import com.edde746.plezy.image.recolours
import com.edde746.plezy.image.remapLightNeutral

/**
 * Recolours a light clear logo towards [ink] (the light theme's text colour, `logoInk`), so a white mark made for dark
 * screens reads on a light page. Art that brings its own contrast, and mixed-colour marks unless [remapMixed], keep
 * their pixels. Coil runs it off the main thread once per image and caches the result under the ink.
 */
internal class ToneLogo(private val ink: Long, private val remapMixed: Boolean) : Transformation() {
    override val cacheKey = "toneLogo-${ink.toString(16)}-$remapMixed"

    override suspend fun transform(input: Bitmap, size: Size): Bitmap {
        val image = input.toComposeBitmap()
        if (image.width.toLong() * image.height > LOGO_MAX_PIXELS) return input
        val pixels = IntArray(image.width * image.height)
        image.readPixels(pixels)
        if (!analyzeLogoTone(pixels, image.width, image.height, stride = 2).recolours(remapMixed)) return input
        return argbBitmap(remapLightNeutral(pixels, ink), image.width, image.height)
    }
}

/** Larger frames than this (a megapixel) are drawn as they are: a clear logo is far smaller. */
private const val LOGO_MAX_PIXELS = 1L shl 20

/** Where a clear logo sits, which decides whether a mark with significant colour is recoloured too. */
enum class LogoRecolour(val remapMixed: Boolean) {
    /** A title's logo, large on the page: mixed-colour marks keep their look. */
    TITLE(remapMixed = false),

    /** A small channel cell: every light mark is recoloured. */
    CELL(remapMixed = true),
}
