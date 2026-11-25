package com.edde746.plezy.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

/** A 24 dp Material icon of one filled path in its 24-unit viewport, built on first use. */
internal fun materialIcon(pathData: String, autoMirror: Boolean = false) = lazy(LazyThreadSafetyMode.NONE) {
    ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 24f, viewportHeight = 24f, autoMirror = autoMirror)
        .addPath(pathNodes(pathData), fill = SolidColor(Color.Black))
        .build()
}

/** A 24 dp Material symbol of one path in the symbols' 960-unit viewport (its top at y = -960), built on first use. */
internal fun materialSymbol(pathData: String, fillType: PathFillType = PathFillType.NonZero) = lazy(LazyThreadSafetyMode.NONE) {
    ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 960f, viewportHeight = 960f)
        .addGroup(translationY = 960f)
        .addPath(pathNodes(pathData), fill = SolidColor(Color.Black), pathFillType = fillType)
        .clearGroup()
        .build()
}
