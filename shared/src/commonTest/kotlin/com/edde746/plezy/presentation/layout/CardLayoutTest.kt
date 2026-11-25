package com.edde746.plezy.presentation.layout

import com.edde746.plezy.settings.GridSpacing
import kotlin.test.Test
import kotlin.test.assertEquals

class CardLayoutTest {
    @Test
    fun gridTitlesTakeTwoLinesAtTheCompactDensitiesAndOneFromTheDefaultUp() {
        assertEquals(listOf(2, 2, 1, 1, 1), (1..5).map { GridLayout.titleLines(it) })
    }

    @Test
    fun squareCellsKeepTheirGutterAndFullBleedCellsTakeTheTvGap() {
        assertEquals(8.0, GridLayout.spacing(GridSpacing.TIGHT, CardShape.SQUARE, fullBleed = false))
        assertEquals(12.0, GridLayout.spacing(GridSpacing.SPACIOUS, CardShape.SQUARE, fullBleed = false))
        assertEquals(12.0, GridLayout.spacing(GridSpacing.TIGHT, CardShape.POSTER, fullBleed = true, tvScale = 1.0))
        assertEquals(18.0, GridLayout.spacing(GridSpacing.TIGHT, CardShape.POSTER, fullBleed = true, tvScale = 1.35 * 2))
    }

    @Test
    fun layoutClassesFollowTheGridsBreakpoints() {
        assertEquals(LayoutClass.PHONE, LayoutClass.of(599.0, tv = false))
        assertEquals(LayoutClass.TABLET, LayoutClass.of(600.0, tv = false))
        assertEquals(LayoutClass.DESKTOP, LayoutClass.of(1200.0, tv = false))
        assertEquals(LayoutClass.TV, LayoutClass.of(500.0, tv = true))
    }

    @Test
    fun listRowsScaleTheirArtworkWithDensity() {
        assertEquals(ListRowLayout(95.0, 142.5), ListRowLayout.of(3, CardShape.POSTER))
        assertEquals(ListRowLayout(95.0 * 1.6, 95.0 * 0.9), ListRowLayout.of(3, CardShape.WIDE))
        assertEquals(ListRowLayout(120.0, 120.0), ListRowLayout.of(5, CardShape.SQUARE))
        assertEquals(158.5, ListRowLayout.of(3, CardShape.POSTER).rowHeight)
        assertEquals(listOf(2, 2, 3, 4, 5), (1..5).map(ListRowLayout::summaryLines))
    }

    @Test
    fun aHubRowsShapeFollowsItsItemsAndTheEpisodePosterSetting() {
        assertEquals(CardShape.SQUARE, hubShape(listOf(CardShape.SQUARE, CardShape.SQUARE), episodeThumbnails = true))
        assertEquals(CardShape.WIDE, hubShape(listOf(CardShape.WIDE, CardShape.POSTER), episodeThumbnails = true))
        assertEquals(CardShape.POSTER, hubShape(listOf(CardShape.WIDE, CardShape.POSTER), episodeThumbnails = false))
        assertEquals(CardShape.WIDE, hubShape(listOf(CardShape.WIDE), episodeThumbnails = false))
        assertEquals(CardShape.POSTER, hubShape(emptyList(), episodeThumbnails = true))
    }
}

class TvLayoutTest {
    @Test
    fun theTvScaleFollowsTheHeightWithinItsBounds() {
        assertEquals(1.0, TvScale.of(1080.0))
        assertEquals(0.85, TvScale.of(540.0))
        assertEquals(1.35, TvScale.of(2160.0))
    }
}
