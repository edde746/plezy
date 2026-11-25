package com.edde746.plezy.ui.image

import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.Paint
import coil3.Bitmap
import coil3.size.Size
import coil3.transform.Transformation
import kotlin.math.roundToInt

/**
 * Blurs an image past recognition, so an episode's still gives nothing away: each cell of a grid [CELLS] across (the
 * image's aspect kept) is the average of the pixels under it, and the grid is box-blurred [PASSES] times, close to a
 * Gaussian over about 1/16 of the width; drawn at the image's size, the screen's filtering spreads it smoothly. Only
 * colours and their rough layout are left. It runs on the decoded pixels, so it works the same on every Android
 * version (a Compose blur draws nothing different before Android 12) and on the desktop. Coil runs it off the main
 * thread, once per image and size, and keeps what it gives in its memory cache, so a list scrolls past it at no cost.
 */
internal object StillBlur : Transformation() {
    override val cacheKey = "stillBlur"

    override suspend fun transform(input: Bitmap, size: Size): Bitmap {
        val image = input.toComposeBitmap()
        val width = image.width
        val height = image.height
        val columns = CELLS
        val rows = (CELLS * height.toFloat() / width).roundToInt().coerceAtLeast(1)
        // The sums of each cell's channels and its pixel count, from one row of pixels at a time.
        val sums = Array(4) { LongArray(columns * rows) }
        val counts = IntArray(columns * rows)
        val row = IntArray(width)
        for (y in 0 until height) {
            image.readPixels(row, startY = y, height = 1)
            val cellRow = y * rows / height * columns
            for (x in 0 until width) {
                val cell = cellRow + x * columns / width
                val pixel = row[x]
                sums[0][cell] += (pixel ushr 24).toLong()
                sums[1][cell] += (pixel shr 16 and 0xFF).toLong()
                sums[2][cell] += (pixel shr 8 and 0xFF).toLong()
                sums[3][cell] += (pixel and 0xFF).toLong()
                counts[cell]++
            }
        }
        val channels = Array(4) { channel -> FloatArray(columns * rows) { sums[channel][it].toFloat() / counts[it].coerceAtLeast(1) } }
        repeat(PASSES) {
            for (channel in channels) {
                boxBlur(channel, columns, rows, across = true)
                boxBlur(channel, columns, rows, across = false)
            }
        }
        val blurred = ImageBitmap(columns, rows)
        val canvas = Canvas(blurred)
        val paint = Paint().apply { isAntiAlias = false }
        for (y in 0 until rows) {
            for (x in 0 until columns) {
                val cell = y * columns + x
                paint.color = Color(
                    red = channels[1][cell].roundToInt(),
                    green = channels[2][cell].roundToInt(),
                    blue = channels[3][cell].roundToInt(),
                    alpha = channels[0][cell].roundToInt(),
                )
                canvas.drawRect(Rect(x.toFloat(), y.toFloat(), x + 1f, y + 1f), paint)
            }
        }
        return blurred.toCoilBitmap()
    }
}

/**
 * One pass of a 3-wide box blur along the rows ([across]) or the columns of [values], a [columns] × [rows] grid; the
 * edges repeat their last cell.
 */
private fun boxBlur(values: FloatArray, columns: Int, rows: Int, across: Boolean) {
    val lines = if (across) rows else columns
    val length = if (across) columns else rows
    val line = FloatArray(length)
    for (l in 0 until lines) {
        fun index(i: Int) = if (across) l * columns + i else i * columns + l
        for (i in 0 until length) line[i] = values[index(i)]
        for (i in 0 until length) {
            values[index(i)] = (line[(i - 1).coerceAtLeast(0)] + line[i] + line[(i + 1).coerceAtMost(length - 1)]) / 3f
        }
    }
}

/** The grid's cells across: a 16:9 still is 24 × 14 of them. */
private const val CELLS = 24

/** The box blur's passes over the grid: three come close to a Gaussian of 1.4 cells. */
private const val PASSES = 3
