package com.edde746.plezy.image

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.convert
import kotlinx.cinterop.usePinned
import platform.CoreGraphics.CGBitmapContextCreate
import platform.CoreGraphics.CGBitmapContextCreateImage
import platform.CoreGraphics.CGColorSpaceCreateDeviceRGB
import platform.CoreGraphics.CGColorSpaceRelease
import platform.CoreGraphics.CGContextDrawImage
import platform.CoreGraphics.CGContextRelease
import platform.CoreGraphics.CGImageAlphaInfo
import platform.CoreGraphics.CGImageGetHeight
import platform.CoreGraphics.CGImageGetWidth
import platform.CoreGraphics.CGImageRef
import platform.CoreGraphics.CGRectMake
import platform.CoreGraphics.kCGBitmapByteOrder32Little

/**
 * [image] with its light marks recoloured towards [ink] ([remapLightNeutral]) when its tone allows it ([recolours]),
 * else null (draw it as it is). Frames over a megapixel are left alone: a clear logo is far smaller.
 */
@OptIn(ExperimentalForeignApi::class)
fun toneLogo(image: CGImageRef?, ink: Long, remapMixed: Boolean): CGImageRef? {
    val width = CGImageGetWidth(image).toInt()
    val height = CGImageGetHeight(image).toInt()
    if (width <= 0 || height <= 0 || width.toLong() * height > 1L shl 20) return null
    // Premultiplied BGRA, little-endian: each pixel reads as one premultiplied 0xAARRGGBB int.
    val premultiplied = IntArray(width * height)
    if (!premultiplied.usePinned { draw(image, it.addressOf(0), width, height) }) return null
    val straight = IntArray(premultiplied.size) { unpremultiply(premultiplied[it]) }
    if (!analyzeLogoTone(straight, width, height, stride = 2).recolours(remapMixed)) return null
    val out = remapLightNeutral(straight, ink)
    for (i in out.indices) out[i] = premultiply(out[i])
    return out.usePinned { pinned ->
        val space = CGColorSpaceCreateDeviceRGB()
        val context = CGBitmapContextCreate(pinned.addressOf(0), width.convert(), height.convert(), 8u, (width * 4).convert(), space, BITMAP_INFO)
        CGColorSpaceRelease(space)
        CGBitmapContextCreateImage(context).also { CGContextRelease(context) }
    }
}

@OptIn(ExperimentalForeignApi::class)
private fun draw(image: CGImageRef?, into: kotlinx.cinterop.CPointer<kotlinx.cinterop.IntVar>, width: Int, height: Int): Boolean {
    val space = CGColorSpaceCreateDeviceRGB()
    val context = CGBitmapContextCreate(into, width.convert(), height.convert(), 8u, (width * 4).convert(), space, BITMAP_INFO)
    CGColorSpaceRelease(space)
    context ?: return false
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, width.toDouble(), height.toDouble()), image)
    CGContextRelease(context)
    return true
}

@OptIn(ExperimentalForeignApi::class)
private val BITMAP_INFO: UInt = CGImageAlphaInfo.kCGImageAlphaPremultipliedFirst.value or kCGBitmapByteOrder32Little

private fun unpremultiply(pixel: Int): Int {
    val a = pixel ushr 24
    if (a == 0 || a == 255) return if (a == 0) 0 else pixel
    fun channel(shift: Int) = minOf(255, ((pixel shr shift and 0xFF) * 255 + a / 2) / a)
    return (a shl 24) or (channel(16) shl 16) or (channel(8) shl 8) or channel(0)
}

private fun premultiply(pixel: Int): Int {
    val a = pixel ushr 24
    if (a == 255) return pixel
    fun channel(shift: Int) = (pixel shr shift and 0xFF) * a / 255
    return (a shl 24) or (channel(16) shl 16) or (channel(8) shl 8) or channel(0)
}
