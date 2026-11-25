package com.edde746.plezy.image

import kotlin.math.round

/**
 * The decoded-image memory cache's limits: at most [images] images and [bytes] of bitmaps, kept modest to leave room
 * for the decoder's and the video's buffers.
 */
data class ImageMemoryBudget(val images: Int, val bytes: Long) {
    companion object {
        private const val MIB = 1L shl 20

        /**
         * The budget on a [desktop] (Windows, Linux, macOS, whatever its layout): 1000 images, 150 MiB. Else, on
         * [display]'s reduced tier, 400 and 64 MiB (its tiles still decode at a TV's density); on a [tv], 500 and
         * 64 MiB times the display budget (a 4K surface's artwork carries up to twice the pixels); otherwise 800 and
         * 100 MiB.
         */
        fun of(desktop: Boolean, tv: Boolean, display: ArtworkDisplay): ImageMemoryBudget = when {
            desktop -> ImageMemoryBudget(1000, 150 * MIB)
            display.reduced -> ImageMemoryBudget(400, 64 * MIB)
            tv -> ImageMemoryBudget(500, round(64 * MIB * display.budget).toLong())
            else -> ImageMemoryBudget(800, 100 * MIB)
        }
    }
}
