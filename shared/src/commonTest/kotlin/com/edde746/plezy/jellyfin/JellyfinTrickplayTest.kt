package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.model.TrickplayInfo
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class JellyfinTrickplayTest {
    // 250 thumbnails 1 s apart, 10×10 per sheet: sheets 0 (0..99), 1 (100..199), 2 (200..249, padded).
    private fun info(width: Int = 320, height: Int = 180, tileWidth: Int = 10, tileHeight: Int = 10, thumbnailCount: Int = 250, interval: Int = 1000) =
        TrickplayInfo(width, height, tileWidth, tileHeight, thumbnailCount, interval, 0)

    private fun url(sourceId: String?) = { width: Int, sheet: Int ->
        JellyfinUrls.trickplayTile("http://jf", "tok-abc", "ApiKey", "dev", "item-99", width, sheet, sourceId)
    }

    private fun make(manifest: Map<Int, TrickplayInfo> = mapOf(320 to info()), warmed: MutableList<String>? = null) =
        JellyfinTrickplay.create(manifest, warm = warmed?.let { list -> { u: String -> list += u } }, sheetUrl = url(null))!!

    private fun ScrubFrame.SheetTile.cell() = Triple(sheetColumns.let { 0 } + tileColumn, tileRow, sheetUrl.substringAfter("/Trickplay/").substringBefore('?'))

    @Test fun nullOnEmptyManifest() = assertNull(JellyfinTrickplay.create(emptyMap(), sheetUrl = url(null)))

    @Test fun picksSmallestWidthAtLeastTarget() =
        assertEquals(160, make(mapOf(120 to info(120), 160 to info(160), 320 to info(320))).tileAt(0)!!.tileWidth)

    @Test fun fallsBackToLargestWidth() = assertEquals(120, make(mapOf(80 to info(80), 120 to info(120))).tileAt(0)!!.tileWidth)

    @Test fun indexMath() {
        val svc = make()
        assertEquals(Triple(0, 0, "320/0.jpg"), svc.tileAt(0)!!.cell())
        assertEquals(Triple(9, 9, "320/0.jpg"), svc.tileAt(99_000)!!.cell())
        val rolled = svc.tileAt(100_000)!!
        assertEquals(Triple(0, 0, "320/1.jpg"), rolled.cell())
        assertEquals(10 to 10, rolled.sheetColumns to rolled.sheetRows)
        assertEquals(Triple(9, 4, "320/2.jpg"), svc.tileAt(249_000)!!.cell())
        assertEquals(Triple(9, 4, "320/2.jpg"), svc.tileAt(10_000_000)!!.cell())
    }

    @Test fun disposeEndsAvailability() {
        val svc = make()
        assertTrue(svc.isAvailable)
        svc.dispose()
        assertFalse(svc.isAvailable)
        assertNull(svc.frameAt(0.seconds))
    }

    @Test fun paddedLastSheetReportsFullGrid() {
        val tile = make(mapOf(320 to info(tileWidth = 4, tileHeight = 4, thumbnailCount = 17))).tileAt(16_000)!!
        assertEquals(Triple(0, 0, "320/1.jpg"), tile.cell())
        assertEquals(4 to 4, tile.sheetColumns to tile.sheetRows)
    }

    @Test fun nonWideThumbnailsKeepManifestAspect() =
        assertEquals(4.0 / 3, make(mapOf(320 to info(height = 240))).frameAt(0.milliseconds)!!.aspectRatio, 0.0001)

    @Test fun sheetUrlCarriesWidthSheetSourceAndToken() {
        val svc = JellyfinTrickplay.create(mapOf(320 to info()), sheetUrl = url("src-2"))!!
        assertEquals("http://jf/Videos/item-99/Trickplay/320/1.jpg?ApiKey=tok-abc&DeviceId=dev&MediaSourceId=src-2", svc.sheetUrl(1))
        assertFalse("MediaSourceId" in make().sheetUrl(1))
    }

    private val small = mapOf(320 to info(tileWidth = 2, tileHeight = 2, thumbnailCount = 12))

    @Test fun warmsNextSheetScrubbingForward() {
        val warmed = mutableListOf<String>()
        val svc = make(small, warmed)
        svc.frameAt(0.seconds)
        svc.frameAt(4.seconds)
        assertEquals(listOf(svc.sheetUrl(1), svc.sheetUrl(2)), warmed)
    }

    @Test fun warmsPreviousSheetScrubbingBackward() {
        val warmed = mutableListOf<String>()
        val svc = make(small, warmed)
        svc.frameAt(8.seconds)
        svc.frameAt(4.seconds)
        assertEquals(listOf(svc.sheetUrl(0)), warmed)
    }

    @Test fun neverWarmsPastEitherEnd() {
        val warmed = mutableListOf<String>()
        val svc = make(small, warmed)
        listOf(0, 4, 8).forEach { svc.frameAt(it.seconds) }
        assertFalse(svc.sheetUrl(3) in warmed)
    }

    @Test fun aManifestWithoutIntervalCountOrTilesHasNoFrame() {
        for (degenerate in listOf(info(interval = 0), info(thumbnailCount = 0), info(tileWidth = 0), info(tileHeight = 0))) {
            val svc = make(mapOf(320 to degenerate))
            assertNull(svc.tileAt(5_000), "$degenerate")
            assertNull(svc.frameAt(5.seconds), "$degenerate")
        }
    }

    @Test fun scrubbingWithinASheetWarmsItsNeighbourOnce() {
        val warmed = mutableListOf<String>()
        val svc = make(small, warmed)
        listOf(0, 1, 2, 3, 1).forEach { svc.frameAt(it.seconds) }
        assertEquals(listOf(svc.sheetUrl(1)), warmed)
    }
}
