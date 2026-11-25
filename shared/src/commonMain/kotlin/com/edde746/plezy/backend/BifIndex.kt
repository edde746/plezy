package com.edde746.plezy.backend

import com.edde746.plezy.log.Log
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration

/**
 * A BIF file (Roku's seek-preview format, served by Plex and Emby): each frame's start time and where its JPEG sits
 * in the file.
 *
 * Layout, little-endian: magic `89 42 49 46 0D 0A 1A 0A`, version (u32 at 8), image count (u32 at 12), milliseconds per
 * timestamp unit (u32 at 16, 0 meaning 1000), reserved to 64, then image count + 1 index entries of 8 bytes
 * (timestamp u32, file offset u32), the last a sentinel whose offset ends the final image.
 */
class BifIndex private constructor(
    private val bytes: ByteArray,
    private val startsMs: LongArray,
    private val from: IntArray,
    private val to: IntArray,
) {
    val frameCount: Int get() = startsMs.size

    /** The JPEG of the last frame starting at or before [time] (the first frame before it starts); null when empty. */
    fun imageAt(time: Duration): ByteArray? {
        if (startsMs.isEmpty()) return null
        val ms = time.inWholeMilliseconds
        var lo = 0
        var hi = startsMs.size - 1
        while (lo < hi) {
            val mid = (lo + hi + 1) / 2
            if (startsMs[mid] <= ms) lo = mid else hi = mid - 1
        }
        return bytes.copyOfRange(from[lo], to[lo])
    }

    companion object {
        private val MAGIC = byteArrayOf(0x89.toByte(), 0x42, 0x49, 0x46, 0x0D, 0x0A, 0x1A, 0x0A)
        private const val HEADER_SIZE = 64
        private const val ENTRY_SIZE = 8

        /**
         * The frames of [bytes]; none when the header is short or wrong or the index table is cut off. A frame whose
         * byte range is empty, reversed or runs past the file is skipped.
         */
        fun parse(bytes: ByteArray): BifIndex {
            val empty = BifIndex(ByteArray(0), LongArray(0), IntArray(0), IntArray(0))
            if (bytes.size < HEADER_SIZE) return empty
            for (i in MAGIC.indices) if (bytes[i] != MAGIC[i]) return empty
            val imageCount = bytes.uint32(12)
            val multiplier = bytes.uint32(16).takeIf { it != 0L } ?: 1000L
            if (bytes.size < HEADER_SIZE + (imageCount + 1) * ENTRY_SIZE) return empty

            val count = imageCount.toInt()
            val startsMs = LongArray(count)
            val from = IntArray(count)
            val to = IntArray(count)
            var kept = 0
            for (i in 0 until count) {
                val entry = HEADER_SIZE + i * ENTRY_SIZE
                val start = bytes.uint32(entry + 4)
                val end = bytes.uint32(entry + ENTRY_SIZE + 4)
                if (end <= start || end > bytes.size) continue
                startsMs[kept] = bytes.uint32(entry) * multiplier
                from[kept] = start.toInt()
                to[kept] = end.toInt()
                kept++
            }
            return BifIndex(bytes, startsMs.copyOf(kept), from.copyOf(kept), to.copyOf(kept))
        }

        private fun ByteArray.uint32(at: Int): Long =
            (this[at].toLong() and 0xFF) or
                ((this[at + 1].toLong() and 0xFF) shl 8) or
                ((this[at + 2].toLong() and 0xFF) shl 16) or
                ((this[at + 3].toLong() and 0xFF) shl 24)
    }
}

/** Seek-bar previews from one BIF file; frames take [aspectRatio] (the video's), 16:9 when unknown. */
class BifScrubPreviewSource(index: BifIndex, private val aspectRatio: Double? = null) : ScrubPreviewSource {
    private var index: BifIndex? = index

    override val isAvailable: Boolean get() = (index?.frameCount ?: 0) > 0

    override fun frameAt(time: Duration): ScrubFrame? {
        val bytes = index?.imageAt(time) ?: return null
        return ScrubFrame.Bytes(bytes, aspectRatio ?: (16.0 / 9))
    }

    override fun dispose() {
        index = null
    }

    companion object {
        private const val TAG = "BifScrubPreview"

        /**
         * Downloads and parses a BIF through [fetchBytes] (Plex's `/library/parts/{id}/indexes/sd`, Emby's
         * `/Videos/{id}/index.bif`). The whole file stays in memory while the player is open, so [fetchBytes] gets the
         * platform's size budget and must stop reading past it. A failed download is logged and leaves the source
         * unavailable: the seek bar simply shows no previews.
         */
        suspend fun load(aspectRatio: Double?, fetchBytes: suspend (maxBytes: Long) -> ByteArray?): BifScrubPreviewSource {
            val bytes = try {
                fetchBytes(bifMaxBytes)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "BIF download failed" }
                null
            }
            return BifScrubPreviewSource(BifIndex.parse(bytes ?: ByteArray(0)), aspectRatio)
        }
    }
}

/** The largest BIF a preview source holds: 200 MiB on desktop operating systems, 50 MiB on phones and TVs. */
internal expect val bifMaxBytes: Long
