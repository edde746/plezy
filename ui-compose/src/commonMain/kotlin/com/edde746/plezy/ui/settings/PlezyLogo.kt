package com.edde746.plezy.ui.settings

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.icons.pathNodes

/** Plezy's mark (the play triangle with its two waves), in its orange gradient, as drawn at the head of About. */
internal val PlezyLogo: ImageVector by lazy(LazyThreadSafetyMode.NONE) {
    ImageVector.Builder(defaultWidth = 72.dp, defaultHeight = 80.35.dp, viewportWidth = 358.32f, viewportHeight = 399.86f)
        .addGroup(translationY = -32f)
        .addPath(
            pathNodes(
                "M335.65,192.66L68.01,38.14C37.78,20.69,0,42.5,0,77.41v309.04c0,34.91,37.78,56.72,68.01,39.27l267.64-154.52c30." +
        "23-17.45,30.23-61.08,0-78.54ZM255.53,276.8c-19.1,17.66-38.75,26.49-58.4,26.49s-39.29-8.83-58.39-26.49c-14.39-1" +
        "3.3-28.55-20.05-42.11-20.05s-27.72,6.75-42.1,20.05c-4.87,4.5-12.46,4.2-16.96-.67-4.5-4.86-4.2-12.45.67-16.95,3" +
        "8.2-35.33,78.59-35.33,116.79,0,14.38,13.3,28.55,20.04,42.1,20.04s27.72-6.74,42.11-20.04c4.86-4.5,12.46-4.21,16" +
        ".95.66,4.5,4.87,4.21,12.46-.66,16.96ZM255.53,204.04c-19.1,17.67-38.75,26.5-58.4,26.5s-39.29-8.83-58.39-26.5c-1" +
        "4.39-13.3-28.55-20.04-42.11-20.04s-27.72,6.74-42.1,20.04c-4.87,4.5-12.46,4.21-16.96-.66s-4.2-12.46.67-16.96c38" +
        ".2-35.32,78.59-35.32,116.79,0,14.38,13.3,28.55,20.05,42.1,20.05s27.72-6.75,42.11-20.05c4.86-4.5,12.46-4.2,16.9" +
        "5.67,4.5,4.86,4.21,12.45-.66,16.95Z",
            ),
            fill = Brush.linearGradient(listOf(Color(0xFFAB543A), Color(0xFFFF7E57)), start = Offset(22.67f, 425.72f), end = Offset(201.83f, 115.4f)),
        )
        .clearGroup()
        .build()
}
