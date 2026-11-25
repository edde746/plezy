package com.edde746.plezy.presentation.layout

/** TV layouts scale with the screen's height ([scale]): 1 at 1080 points, within 0.85–1.35. */
object TvScale {
    fun of(height: Double): Double = (height / 1080).coerceIn(0.85, 1.35)
}

/**
 * The shape a hub row's cards share: square when every item is square; wide when it has wide items and either no tall
 * ones or [episodeThumbnails] (episodes as thumbnails); a poster otherwise. An empty row is a poster row.
 */
fun hubShape(items: List<CardShape>, episodeThumbnails: Boolean): CardShape {
    if (items.isNotEmpty() && items.all { it == CardShape.SQUARE }) return CardShape.SQUARE
    val wide = items.any { it == CardShape.WIDE }
    val tall = items.any { it != CardShape.WIDE }
    return if (wide && (!tall || episodeThumbnails)) CardShape.WIDE else CardShape.POSTER
}

/** The TV browse rail's geometry, in points at the screen's [TvScale]. */
object TvRailLayout {
    /** The rail's inset from the screen's edge: 24 × scale within 18–40. */
    fun horizontalInset(scale: Double): Double = (24 * scale).coerceIn(18.0, 40.0)
}
