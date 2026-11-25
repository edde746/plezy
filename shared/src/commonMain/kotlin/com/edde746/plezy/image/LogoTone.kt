package com.edde746.plezy.image

import com.edde746.plezy.presentation.theme.Palette

/**
 * How a clear logo's pixels are toned, which decides whether [remapLightNeutral] may recolour it for a light surface.
 * Clear logos and channel logos are made for dark screens: white marks on transparency, invisible on a light theme.
 */
enum class LogoTone {
    /** Too few opaque pixels to judge: left alone. */
    UNKNOWN,

    /** A near-white, low-saturation mark. */
    LIGHT_MONOCHROME,

    /** A light mark with an incidental colour accent (at most 15 % saturated pixels). Safe to recolour anywhere. */
    LIGHT_ACCENTED,

    /** Light content beside significant colour. Recolouring changes the mark's character: only small cells do it. */
    LIGHT_MIXED,

    /** Dark or coloured art, or one neutral enclosed by the other (dark ink on a white plate): never recoloured. */
    BACKED,
}

/** The colour a light-toned logo is recoloured towards on [palette]: its text colour on a light theme, else none. */
fun logoInk(palette: Palette): Long? = if (palette.isDark) null else palette.text

/** Whether a logo of this tone is recoloured: monochrome and accented always, mixed only when [remapMixed]. */
fun LogoTone.recolours(remapMixed: Boolean): Boolean =
    this == LogoTone.LIGHT_MONOCHROME || this == LogoTone.LIGHT_ACCENTED || (remapMixed && this == LogoTone.LIGHT_MIXED)

/**
 * The tone of a frame of straight-alpha `0xAARRGGBB` [pixels], [width] wide, sampling every [stride]th pixel on both
 * axes. Pixels under alpha 32 are transparent; saturation `255 × (max − min) / max` of 89 or more is colour, otherwise
 * Rec. 601 luma of 153 or more is a light neutral, below it a dark one. Under 2 % opaque samples is [LogoTone.UNKNOWN];
 * half of either neutral enclosed by the other on all four sides is [LogoTone.BACKED]; then the share of light pixels
 * (luma 176 and up) decides.
 */
fun analyzeLogoTone(pixels: IntArray, width: Int, height: Int, stride: Int = 1): LogoTone {
    val cols = (width + stride - 1) / stride
    val rows = (height + stride - 1) / stride
    val sampled = cols * rows
    if (sampled == 0) return LogoTone.UNKNOWN
    val classes = ByteArray(sampled)
    var opaque = 0
    var light = 0
    var lightLowSat = 0
    var colored = 0
    var lightNeutral = 0
    var darkNeutral = 0
    var cell = 0
    for (y in 0 until height step stride) {
        for (x in 0 until width step stride) {
            val pixel = pixels[y * width + x]
            val here = cell++
            if (pixel ushr 24 < 32) continue
            opaque++
            val r = pixel shr 16 and 0xFF
            val g = pixel shr 8 and 0xFF
            val b = pixel and 0xFF
            val maxC = maxOf(r, g, b)
            val minC = minOf(r, g, b)
            val luma = luma(r, g, b)
            when {
                maxC > 0 && 255 * (maxC - minC) / maxC >= 89 -> {
                    colored++
                    classes[here] = COLORED
                }
                luma >= 153 -> {
                    lightNeutral++
                    classes[here] = LIGHT
                }
                else -> {
                    darkNeutral++
                    classes[here] = DARK
                }
            }
            if (luma < 176) continue
            light++
            if (maxC - minC <= 48) lightLowSat++
        }
    }
    if (opaque * 50 < sampled) return LogoTone.UNKNOWN
    if (darkNeutral > 0 && lightNeutral > 0 && enclosed(classes, cols, rows, lightNeutral, darkNeutral)) {
        return LogoTone.BACKED
    }
    val lightFrac = light.toDouble() / opaque
    if (lightFrac >= 0.85 && lightLowSat.toDouble() / opaque >= 0.80) return LogoTone.LIGHT_MONOCHROME
    if (lightFrac >= 0.30) return if (colored * 100 <= opaque * 15) LogoTone.LIGHT_ACCENTED else LogoTone.LIGHT_MIXED
    return LogoTone.BACKED
}

/**
 * [pixels] (straight-alpha `0xAARRGGBB`) with each pixel moved towards [ink] by how light and neutral it is: fully
 * from 0.85 luma at no saturation, not at all under 0.6 luma or over 0.35 saturation. Colour keeps its pixels, alpha
 * stays, antialiased edges land in between (so no light fringe), and fully transparent pixels become 0.
 */
fun remapLightNeutral(pixels: IntArray, ink: Long): IntArray {
    val tr = (ink shr 16 and 0xFF).toInt()
    val tg = (ink shr 8 and 0xFF).toInt()
    val tb = (ink and 0xFF).toInt()
    return IntArray(pixels.size) { i ->
        val pixel = pixels[i]
        val a = pixel ushr 24
        if (a == 0) return@IntArray 0
        var r = pixel shr 16 and 0xFF
        var g = pixel shr 8 and 0xFF
        var b = pixel and 0xFF
        val maxC = maxOf(r, g, b)
        val minC = minOf(r, g, b)
        val sat = if (maxC == 0) 0 else 255 * (maxC - minC) / maxC
        val w = ((luma(r, g, b) - 153) * 4).coerceIn(0, 255) * ((89 - sat) * 5).coerceIn(0, 255) / 255
        if (w != 0) {
            r += (tr - r) * w / 255
            g += (tg - g) * w / 255
            b += (tb - b) * w / 255
        }
        (a shl 24) or (r shl 16) or (g shl 8) or b
    }
}

private fun luma(r: Int, g: Int, b: Int): Int = (r * 77 + g * 150 + b * 29) shr 8

private const val TRANSPARENT: Byte = 0
private const val LIGHT: Byte = 1
private const val DARK: Byte = 2
private const val COLORED: Byte = 3

/**
 * Whether half of either neutral is enclosed by the other: the first differently classed cell left, right, up and down
 * of it is the opposite neutral (the edge counts as transparent).
 */
private fun enclosed(classes: ByteArray, cols: Int, rows: Int, lightNeutral: Int, darkNeutral: Int): Boolean {
    val open = BooleanArray(classes.size)
    for (y in 0 until rows) {
        val start = y * cols
        scan(classes, open, start, start + cols, 1)
        scan(classes, open, start + cols - 1, start - 1, -1)
    }
    for (x in 0 until cols) {
        scan(classes, open, x, x + rows * cols, cols)
        scan(classes, open, x + (rows - 1) * cols, x - cols, -cols)
    }
    var enclosedLight = 0
    var enclosedDark = 0
    for (i in classes.indices) {
        if (open[i]) continue
        when (classes[i]) {
            LIGHT -> enclosedLight++
            DARK -> enclosedDark++
        }
    }
    return enclosedLight * 2 >= lightNeutral || enclosedDark * 2 >= darkNeutral
}

private fun scan(classes: ByteArray, open: BooleanArray, from: Int, to: Int, step: Int) {
    var behindLight = TRANSPARENT
    var behindDark = TRANSPARENT
    var i = from
    while (i != to) {
        val c = classes[i]
        when (c) {
            LIGHT -> {
                if (behindLight != DARK) open[i] = true
                behindDark = c
            }
            DARK -> {
                if (behindDark != LIGHT) open[i] = true
                behindLight = c
            }
            else -> {
                behindLight = c
                behindDark = c
            }
        }
        i += step
    }
}
