package com.edde746.plezy.ui.settings

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.icons.pathNodes

/**
 * The icons of the Settings screen and its sections, beyond [com.edde746.plezy.ui.icons.PlezyIcons]: Material Icons
 * (baseline, 24 dp; Apache License 2.0) as path data, built on first use.
 */
internal object SettingsIcons {
    val AccountCircle by icon(
        "M12,2C6.48,2 2,6.48 2,12s4.48,10 10,10 10,-4.48 10,-10S17.52,2 12,2zM12,6c1.93,0 3.5,1.57 3.5,3.5S13.93,13 12,13" +
            "s-3.5,-1.57 -3.5,-3.5S10.07,6 12,6zM12,20c-2.03,0 -4.43,-0.82 -6.14,-2.88C7.55,15.8 9.68,15 12,15s4.45,0.8 6.14,2.12" +
            "C16.43,19.18 14.03,20 12,20z",
    )
    val Warning by icon("M1,21h22L12,2 1,21zM13,18h-2v-2h2v2zM13,14h-2v-4h2v4z")
}

private fun icon(pathData: String) = lazy(LazyThreadSafetyMode.NONE) {
    ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 24f, viewportHeight = 24f)
        .addPath(pathNodes(pathData), fill = SolidColor(Color.Black))
        .build()
}
