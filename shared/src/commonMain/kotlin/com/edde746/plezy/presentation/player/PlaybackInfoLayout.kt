package com.edde746.plezy.presentation.player

/**
 * What the playback info's card holds and how it lays out ([arrange]), the same on every UI:
 * - Its text keeps one size: each UI draws it no smaller than its idiom's floor and never scales it down to fit.
 * - It covers no control: the UI offers it rooms ([InfoRoom]), free rectangles clear of the title, the transport, the
 *   scrubber and any open menu, and the card fits inside one of them.
 * - It covers at most [MAX_SHARE] of the picture.
 * - No data value is cut ([InfoRow.freeText]: only a file's name, a track's title, the audio output's device may end
 *   in "…"): its columns are the idiom's width ([InfoCardMetrics.column]), wider where the data of the sections they
 *   hold needs it ([InfoWidth]), and in a narrower room as narrow as the room, but never narrower than that data.
 * - What doesn't fit is left out by whole sections, least useful first: the sections kept are always the first ones of
 *   [PRIORITY] (Stream, Video, Audio, Performance, then Buffer and App, then Color, HDR, Subtitles), shown in their own
 *   order. A section that doesn't fit is never passed over for a smaller, less useful one after it.
 * - Of the arrangements that hold the most sections, the one with the fewest columns (the card stays in its corner),
 *   the sections split among them by [InfoColumns], in the first room the UI offers that holds it.
 *
 * Sizes are in the UI's own units (dp, points), rows one line each.
 */
object PlaybackInfoLayout {
    /**
     * The order sections are kept in when not all fit: what plays (the stream, its video and audio) and how well it
     * plays, then why it may stall (the cache and the download speed, whether the server transcodes), then the
     * picture's and the subtitles' details.
     */
    val PRIORITY = listOf(
        InfoSectionId.STREAM, InfoSectionId.VIDEO, InfoSectionId.AUDIO, InfoSectionId.PERFORMANCE, InfoSectionId.BUFFER,
        InfoSectionId.APP, InfoSectionId.COLOR, InfoSectionId.HDR, InfoSectionId.SUBTITLES,
    )

    /** The most of the picture the card covers: a third. */
    const val MAX_SHARE = 1.0 / 3

    /**
     * The card for [sections] in the first of [rooms] that holds the most of them, within [MAX_SHARE] of [picture]
     * (the player's width times its height), each section [widths] across as the UI measures it; null when no room
     * holds even the first section.
     */
    fun arrange(
        sections: List<InfoSection>,
        rooms: List<InfoRoom>,
        picture: Float,
        metrics: InfoCardMetrics,
        widths: (InfoSection) -> InfoWidth,
    ): InfoCardLayout? {
        val measured = sections.map(widths)
        val ranked = sections.indices.sortedBy { PRIORITY.indexOf(sections[it].id) }
        val maxArea = picture * MAX_SHARE
        for (count in ranked.size downTo 1) {
            val kept = ranked.take(count).toSet()
            val shown = sections.filterIndexed { index, _ -> index in kept }
            // The narrowest column the kept sections' data reads whole in: their widest label beside their widest value.
            val need = kept.maxOf { measured[it].label } + metrics.labelGap + kept.maxOf { measured[it].data }
            for (columns in 1..minOf(metrics.maxColumns, shown.size)) {
                val split = InfoColumns.split(shown, columns)
                val height = metrics.padding * 2 + metrics.title + split.maxOf { metrics.height(it) }
                rooms.forEachIndexed { index, room ->
                    val column = maxOf(need, minOf(metrics.column, room.width - metrics.padding * 2))
                    val width = metrics.padding * 2 + column * columns + metrics.columnGap * (columns - 1)
                    if (width <= room.width && height <= room.height && width * height <= maxArea) {
                        return InfoCardLayout(index, split, width, height, column)
                    }
                }
            }
        }
        return null
    }
}

/** A free rectangle the card may take, as wide and as tall as given; where it is, is the UI's. */
data class InfoRoom(val width: Float, val height: Float)

/**
 * How wide a section's rows are as the UI draws them: its widest label (as wide as the UI lets a label get), and its
 * widest data value, every row's but free text's ([InfoRow.freeText]). A UI that writes the label and the value on one
 * run of text gives the whole run as [data] and no [label].
 */
data class InfoWidth(val label: Float, val data: Float)

/**
 * The card's measures in the UI's units: its columns' width and the gap between them, at most [maxColumns] of them;
 * a row's label and value [labelGap] apart; its padding on every side; its title's height with the gap under it
 * ([title], 0 without a title); a section's heading and a row's line, with [rowGap] under the heading and each row, and
 * [sectionGap] between sections.
 */
data class InfoCardMetrics(
    val column: Float,
    val columnGap: Float,
    val maxColumns: Int,
    val labelGap: Float,
    val padding: Float,
    val title: Float,
    val heading: Float,
    val row: Float,
    val rowGap: Float,
    val sectionGap: Float,
) {
    /** A column of [sections]' height. */
    fun height(sections: List<InfoSection>): Float =
        sections.sumOf { (heading + (row + rowGap) * it.rows.size).toDouble() }.toFloat() + sectionGap * (sections.size - 1).coerceAtLeast(0)
}

/**
 * The card ([PlaybackInfoLayout.arrange]): in the [room]-th room offered, [columns] of sections, each [column] wide,
 * [width] by [height] in all.
 */
data class InfoCardLayout(val room: Int, val columns: List<List<InfoSection>>, val width: Float, val height: Float, val column: Float)
