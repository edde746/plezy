package com.edde746.plezy.presentation.player

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The playback info's card never covers more than a third of the picture nor leaves its room, cuts no data value, and
 * when the room is short or narrow it leaves out whole sections, least useful first.
 */
class PlaybackInfoLayoutTest {
    // Rows of 10, headings of 10, no gaps or padding: a section of n rows is 10 (n + 1) tall, a column 100 wide.
    private val metrics = InfoCardMetrics(
        column = 100f, columnGap = 0f, maxColumns = 3, labelGap = 10f, padding = 0f, title = 0f, heading = 10f, row = 10f, rowGap = 0f, sectionGap = 0f,
    )

    private fun section(id: InfoSectionId, rows: Int) = InfoSection(id, id.name, List(rows) { InfoRow("$it", "") })

    // As the store orders them: 50, 70, 40, 20, 60, 20, 50, 40 and 30 tall, 380 in one column.
    private val all = listOf(
        section(InfoSectionId.STREAM, 4), section(InfoSectionId.VIDEO, 6), section(InfoSectionId.COLOR, 3),
        section(InfoSectionId.HDR, 1), section(InfoSectionId.AUDIO, 5), section(InfoSectionId.SUBTITLES, 1),
        section(InfoSectionId.PERFORMANCE, 4), section(InfoSectionId.APP, 3), section(InfoSectionId.BUFFER, 2),
    )

    private val big = 1_000_000f

    // Labels 30 wide and data 60: every section's data reads whole in the 100 column, and in nothing narrower.
    private fun arrange(vararg rooms: InfoRoom, picture: Float = big, widths: (InfoSection) -> InfoWidth = { InfoWidth(30f, 60f) }) =
        PlaybackInfoLayout.arrange(all, rooms.toList(), picture, metrics, widths)

    private fun ids(layout: InfoCardLayout?) = layout?.columns?.flatten()?.map { it.id }

    @Test
    fun withRoomEverySectionShowsInOneColumnInItsOwnOrder() {
        val layout = arrange(InfoRoom(400f, 1000f))
        assertEquals(listOf(all), layout?.columns)
        assertEquals(Triple(100f, 380f, 100f), layout?.let { Triple(it.width, it.height, it.column) })
    }

    @Test
    fun aShortRoomDropsSectionsLeastUsefulFirstAndKeepsTheirOrder() {
        // Stream 50 + Video 70 + Audio 60 = 180; Performance's 50 more doesn't fit 200.
        assertEquals(listOf(InfoSectionId.STREAM, InfoSectionId.VIDEO, InfoSectionId.AUDIO), ids(arrange(InfoRoom(100f, 200f))))
        // As the room grows a section at a time, they come in this order.
        val ranked = all.sortedBy { PlaybackInfoLayout.PRIORITY.indexOf(it.id) }
        var shown = emptySet<InfoSectionId>()
        val added = (1..all.size).map { count ->
            val height = ranked.take(count).sumOf { 10 * (it.rows.size + 1) }.toFloat()
            val now = ids(arrange(InfoRoom(100f, height)))!!.toSet()
            (now - shown).single().also { shown = now }
        }
        assertEquals(
            listOf(
                InfoSectionId.STREAM, InfoSectionId.VIDEO, InfoSectionId.AUDIO, InfoSectionId.PERFORMANCE, InfoSectionId.BUFFER,
                InfoSectionId.APP, InfoSectionId.COLOR, InfoSectionId.HDR, InfoSectionId.SUBTITLES,
            ),
            added,
        )
        // Shown in the store's order whatever was kept: Color (kept seventh) before Audio.
        assertEquals(
            listOf(
                InfoSectionId.STREAM, InfoSectionId.VIDEO, InfoSectionId.COLOR, InfoSectionId.AUDIO, InfoSectionId.PERFORMANCE,
                InfoSectionId.APP, InfoSectionId.BUFFER,
            ),
            ids(arrange(InfoRoom(100f, 340f))),
        )
    }

    @Test
    fun aSectionThatDoesNotFitIsNotPassedOverForALessUsefulOne() {
        // Stream and Video take 120 of 150: Audio's 60 doesn't fit, Subtitles' 20 would, and still stays out.
        assertEquals(listOf(InfoSectionId.STREAM, InfoSectionId.VIDEO), ids(arrange(InfoRoom(100f, 150f))))
    }

    @Test
    fun theCardNeverCoversMoreThanAThirdOfThePicture() {
        for ((width, height) in listOf(600f to 300f, 960f to 540f, 360f to 740f, 300f to 200f)) {
            val picture = width * height
            val layout = arrange(InfoRoom(width, height), picture = picture)!!
            assertTrue(layout.width * layout.height <= picture / 3, "$width × $height: ${layout.width} × ${layout.height}")
        }
        // A room 900 tall in a picture of 90,000: the card is at most 30,000, so 300 tall, Stream to App.
        val layout = arrange(InfoRoom(100f, 900f), picture = 90_000f)!!
        assertEquals(300f, layout.height)
        assertEquals(6, ids(layout)!!.size)
    }

    @Test
    fun aShortWideRoomTakesColumnsAndAsFewAsHoldTheMost() {
        // 150 tall: every section in three columns.
        val three = arrange(InfoRoom(300f, 150f))!!
        assertEquals(3, three.columns.size)
        assertEquals(all.toSet(), three.columns.flatten().toSet())
        assertEquals(300f, three.width)
        // 200 tall holds them all in two: never three.
        assertEquals(2, arrange(InfoRoom(300f, 200f))!!.columns.size)
    }

    @Test
    fun theFirstRoomThatHoldsTheMostSectionsWins() {
        // Beside a phone's transport (narrow) or above it (wide and short): the one that holds more.
        val layout = arrange(InfoRoom(100f, 130f), InfoRoom(300f, 90f))!!
        assertEquals(1, layout.room)
        assertEquals(listOf(InfoSectionId.STREAM, InfoSectionId.VIDEO, InfoSectionId.AUDIO), ids(layout))
        // Even, the first.
        assertEquals(0, arrange(InfoRoom(100f, 130f), InfoRoom(100f, 130f))!!.room)
    }

    @Test
    fun withoutRoomForTheFirstSectionThereIsNoCard() {
        assertNull(arrange(InfoRoom(100f, 40f), InfoRoom(90f, 1000f)))
        assertNull(arrange())
    }

    // Stream's data needs a column of 70, Video's 160, the others' 80.
    private val varied: (InfoSection) -> InfoWidth = {
        when (it.id) {
            InfoSectionId.STREAM -> InfoWidth(30f, 30f)
            InfoSectionId.VIDEO -> InfoWidth(40f, 110f)
            else -> InfoWidth(30f, 40f)
        }
    }

    @Test
    fun aColumnWidensForDataThatWouldBeCut() {
        // Video's widest label and widest value side by side: 40 + 10 + 110.
        val layout = arrange(InfoRoom(400f, 1000f), widths = varied)!!
        assertEquals(listOf(all), layout.columns)
        assertEquals(160f to 160f, layout.column to layout.width)
        // Without Video, the idiom's column.
        val alone = PlaybackInfoLayout.arrange(all.filter { it.id != InfoSectionId.VIDEO }, listOf(InfoRoom(400f, 1000f)), big, metrics, varied)!!
        assertEquals(100f, alone.column)
    }

    @Test
    fun aNarrowRoomNarrowsTheColumnOnlyAsFarAsItsDataAndDropsSectionsInstead() {
        // 90 wide: Stream's data reads whole in it, Video's wouldn't; Audio's would, and still stays out after Video.
        val narrow = arrange(InfoRoom(90f, 1000f), widths = varied)!!
        assertEquals(listOf(InfoSectionId.STREAM), ids(narrow))
        assertEquals(90f, narrow.column)
        // As narrow as Stream's data, and no narrower: then no card.
        assertEquals(70f, arrange(InfoRoom(70f, 1000f), widths = varied)?.column)
        assertNull(arrange(InfoRoom(69f, 1000f), widths = varied))
        // A wide room after the narrow one holds more, so it wins.
        val wide = arrange(InfoRoom(90f, 1000f), InfoRoom(400f, 1000f), widths = varied)!!
        assertEquals(1, wide.room)
        assertEquals(all.size, ids(wide)!!.size)
    }
}
