package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.model.TrickplayInfo
import kotlin.time.Duration

/**
 * Jellyfin sprite-sheet scrub thumbnails for one item and source. The width is the smallest ≥ the tooltip width, else
 * the largest. A frame is a tile of a sheet; on each sheet change the adjacent sheet in the scrub direction is handed
 * to [warm] (bytes only, never decoded) so fast scrubs stay smooth.
 */
class JellyfinTrickplay private constructor(
    val info: TrickplayInfo,
    private val sheetUrl: (width: Int, sheetIndex: Int) -> String,
    private val warm: ((String) -> Unit)?,
) : ScrubPreviewSource {
    private var lastSheetIndex: Int? = null
    private var disposed = false

    override val isAvailable: Boolean get() = !disposed && info.thumbnailCount > 0

    override fun frameAt(time: Duration): ScrubFrame.SheetTile? {
        val (sheet, tile) = locate(time.inWholeMilliseconds) ?: return null
        sheetToPrefetch(sheet)?.let { next -> warm?.invoke(sheetUrl(next)) }
        return tile
    }

    /** The tile showing [timeMs], without prefetching; null when disposed or the manifest is degenerate. */
    fun tileAt(timeMs: Long): ScrubFrame.SheetTile? = locate(timeMs)?.second

    private fun locate(timeMs: Long): Pair<Int, ScrubFrame.SheetTile>? {
        if (disposed || info.thumbnailCount <= 0 || info.interval <= 0) return null
        val tilesPerSheet = info.tileWidth * info.tileHeight
        if (tilesPerSheet <= 0) return null
        val index = (timeMs / info.interval).coerceIn(0, (info.thumbnailCount - 1).toLong()).toInt()
        val sheet = index / tilesPerSheet
        val inSheet = index - sheet * tilesPerSheet
        return sheet to ScrubFrame.SheetTile(sheetUrl(sheet), inSheet % info.tileWidth, inSheet / info.tileWidth, info.tileWidth, info.tileHeight, info.width, info.height)
    }

    fun sheetUrl(sheetIndex: Int): String = sheetUrl(info.width, sheetIndex)

    private fun sheetToPrefetch(currentSheet: Int): Int? {
        val last = lastSheetIndex
        if (currentSheet == last) return null
        lastSheetIndex = currentSheet
        val tilesPerSheet = info.tileWidth * info.tileHeight
        val lastSheet = (info.thumbnailCount - 1) / tilesPerSheet
        return if (last == null || currentSheet > last) (currentSheet + 1).takeIf { it <= lastSheet } else (currentSheet - 1).takeIf { it >= 0 }
    }

    override fun dispose() {
        disposed = true
        lastSheetIndex = null
    }

    companion object {
        const val TARGET_TOOLTIP_WIDTH = 160

        fun create(
            manifest: Map<Int, TrickplayInfo>,
            targetTooltipWidth: Int = TARGET_TOOLTIP_WIDTH,
            warm: ((String) -> Unit)? = null,
            sheetUrl: (width: Int, sheetIndex: Int) -> String,
        ): JellyfinTrickplay? {
            if (manifest.isEmpty()) return null
            val widths = manifest.keys.sorted()
            val preferred = widths.firstOrNull { it >= targetTooltipWidth } ?: widths.last()
            return JellyfinTrickplay(manifest.getValue(preferred), sheetUrl, warm)
        }
    }
}
