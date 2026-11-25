package com.edde746.plezy.backend

import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class BifIndexTest {
    private val magic = byteArrayOf(0x89.toByte(), 0x42, 0x49, 0x46, 0x0D, 0x0A, 0x1A, 0x0A)

    /** A minimal BIF: header, index table with sentinel, then the [frames]' bytes back to back. */
    private fun buildBif(frames: List<Pair<Long, ByteArray>>, timestampMultiplier: Long = 1000): ByteArray {
        val indexSize = (frames.size + 1) * 8
        val out = ByteArray(64 + indexSize + frames.sumOf { it.second.size })
        magic.copyInto(out)
        out.putUint32(12, frames.size.toLong())
        out.putUint32(16, timestampMultiplier)
        var data = 64 + indexSize
        frames.forEachIndexed { i, (timestamp, bytes) ->
            out.putUint32(64 + i * 8, timestamp)
            out.putUint32(64 + i * 8 + 4, data.toLong())
            bytes.copyInto(out, data)
            data += bytes.size
        }
        out.putUint32(64 + frames.size * 8, 0xFFFFFFFFL)
        out.putUint32(64 + frames.size * 8 + 4, data.toLong())
        return out
    }

    private fun ByteArray.putUint32(at: Int, value: Long) {
        for (i in 0 until 4) this[at + i] = (value shr (8 * i)).toByte()
    }

    private fun ByteArray.uint32(at: Int): Long = (0 until 4).fold(0L) { acc, i -> acc or ((this[at + i].toLong() and 0xFF) shl (8 * i)) }

    private fun bytes(vararg values: Int) = ByteArray(values.size) { values[it].toByte() }

    @Test
    fun picksTheLastFrameAtOrBeforeTheTimeWithTheDefaultMultiplier() {
        val index = BifIndex.parse(buildBif(listOf(0L to bytes(0x10, 0x20), 10L to bytes(0x30, 0x40, 0x50), 20L to bytes(0x60))))
        assertEquals(3, index.frameCount)
        assertContentEquals(bytes(0x10, 0x20), index.imageAt(Duration.ZERO))
        assertContentEquals(bytes(0x10, 0x20), index.imageAt(5.seconds))
        assertContentEquals(bytes(0x30, 0x40, 0x50), index.imageAt(10.seconds))
        assertContentEquals(bytes(0x30, 0x40, 0x50), index.imageAt(15.seconds))
        assertContentEquals(bytes(0x60), index.imageAt(25.seconds))
    }

    @Test
    fun honoursANonDefaultTimestampMultiplier() {
        val index = BifIndex.parse(buildBif(listOf(0L to bytes(0xAA), 4L to bytes(0xBB)), timestampMultiplier = 500))
        assertContentEquals(bytes(0xAA), index.imageAt(Duration.ZERO))
        assertContentEquals(bytes(0xAA), index.imageAt(1999.milliseconds))
        assertContentEquals(bytes(0xBB), index.imageAt(2.seconds))
    }

    @Test
    fun multiplierZeroMeansOneSecond() {
        val index = BifIndex.parse(buildBif(listOf(0L to bytes(0x01), 7L to bytes(0x02)), timestampMultiplier = 0))
        assertContentEquals(bytes(0x02), index.imageAt(7.seconds))
    }

    @Test
    fun rejectsAShortHeaderAWrongMagicAndACutIndexTable() {
        assertEquals(0, BifIndex.parse(ByteArray(50)).frameCount)
        assertEquals(0, BifIndex.parse(ByteArray(128)).frameCount)
        val cut = ByteArray(64)
        magic.copyInto(cut)
        cut.putUint32(12, 100)
        assertEquals(0, BifIndex.parse(cut).frameCount)
        assertNull(BifIndex.parse(cut).imageAt(Duration.ZERO))
    }

    @Test
    fun skipsAFrameWhoseByteRangeIsEmpty() {
        val bif = buildBif(listOf(0L to bytes(0x11, 0x22), 5L to bytes(0x33)))
        bif.putUint32(76, bif.uint32(68))
        val index = BifIndex.parse(bif)
        assertEquals(1, index.frameCount)
        assertNotNull(index.imageAt(5.seconds))
        assertNotNull(index.imageAt(Duration.ZERO))
    }

    @Test
    fun aHeaderOnlyBifHasNoFrames() {
        val index = BifIndex.parse(buildBif(emptyList()))
        assertEquals(0, index.frameCount)
        assertNull(index.imageAt(Duration.ZERO))
    }

    @Test
    fun loadedSourceServesByteFramesWithTheVideoAspect() = runTest {
        val source = BifScrubPreviewSource.load(aspectRatio = 2.0) { buildBif(listOf(0L to bytes(0xFF))) }
        assertTrue(source.isAvailable)
        val frame = assertIs<ScrubFrame.Bytes>(source.frameAt(Duration.ZERO))
        assertContentEquals(bytes(0xFF), frame.bytes)
        assertEquals(2.0, frame.aspectRatio)
        val defaultAspect = BifScrubPreviewSource.load(aspectRatio = null) { buildBif(listOf(0L to bytes(0xFF))) }
        assertEquals(16.0 / 9, defaultAspect.frameAt(Duration.ZERO)?.aspectRatio)
    }

    @Test
    fun loadHandsThePlatformBudgetToTheDownload() = runTest {
        var budget: Long? = null
        BifScrubPreviewSource.load(aspectRatio = null) { maxBytes ->
            budget = maxBytes
            null
        }
        assertEquals(bifMaxBytes, budget)
    }

    @Test
    fun aMissingEmptyOrFailedDownloadLeavesTheSourceUnavailable() = runTest {
        val missing = BifScrubPreviewSource.load(aspectRatio = null) { null }
        assertFalse(missing.isAvailable)
        assertNull(missing.frameAt(Duration.ZERO))
        assertFalse(BifScrubPreviewSource.load(aspectRatio = null) { ByteArray(0) }.isAvailable)
        assertFalse(BifScrubPreviewSource.load(aspectRatio = null) { throw IllegalStateException("body too large") }.isAvailable)
    }

    @Test
    fun disposeReleasesTheFrames() = runTest {
        val source = BifScrubPreviewSource.load(aspectRatio = null) { buildBif(listOf(0L to bytes(0xFF))) }
        assertTrue(source.isAvailable)
        source.dispose()
        assertFalse(source.isAvailable)
        assertNull(source.frameAt(Duration.ZERO))
    }
}
