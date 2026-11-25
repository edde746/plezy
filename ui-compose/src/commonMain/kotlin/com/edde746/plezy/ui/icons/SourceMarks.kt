package com.edde746.plezy.ui.icons

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.size
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.catalog.CatalogSourceId

/**
 * A catalog source's brand mark ([size] square), drawn in [tint] (the ambient content colour): the switcher's and the
 * source rows' logos. AniList keeps its brand-blue L beside the tinted A.
 */
@Composable
fun CatalogSourceLogo(id: CatalogSourceId, modifier: Modifier = Modifier, size: Dp = 20.dp, tint: Color = LocalContentColor.current) {
    val vector = remember(id, tint) { markVector(MARKS.getValue(id), tint) }
    Image(vector, contentDescription = null, modifier.size(size))
}

/** One path of a mark: its SVG path data, its own colour (null: the tint), and whether its holes are cut even-odd. */
private class MarkPath(val data: String, val color: Color? = null, val evenOdd: Boolean = false)

/** A mark's SVG viewBox and paths. */
private class Mark(val minX: Float, val minY: Float, val size: Float, val paths: List<MarkPath>)

private fun markVector(mark: Mark, tint: Color): ImageVector =
    ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = mark.size, viewportHeight = mark.size)
        .addGroup(translationX = -mark.minX, translationY = -mark.minY)
        .apply {
            for (path in mark.paths) {
                addPath(pathNodes(path.data), fill = SolidColor(path.color ?: tint), pathFillType = if (path.evenOdd) PathFillType.EvenOdd else PathFillType.NonZero)
            }
        }
        .clearGroup()
        .build()

// The services' marks as their sites publish them (square viewBoxes).
private val MARKS: Map<CatalogSourceId, Mark> = mapOf(
    CatalogSourceId.PLEX to Mark(
        636.71f, 89.58f, 269.72f,
        listOf(MarkPath("M774.47 359.3H677.74L768.67 224.5L677.74 89.58H774.47L865.4 224.5L774.47 359.3Z")),
    ),
    CatalogSourceId.TRAKT to Mark(
        0f, 0f, 48f,
        listOf(
            MarkPath(
                "M45.99 14.39 30.17 30.22l-1.46-1.46 16.31-16.32c-.15-.3-.32-.58-.5-.87l-17.2 17.2 2.16 2.16-1.46 1.46-3.62-3.62L43" +
                    ".34 9.82c-.18-.27-.38-.53-.6-.78L23.01 28.78l4.31 4.31-1.46 1.46-14.4-14.4 1.46-1.46 8.62 8.62L41.37 7.46c-.12-" +
                    ".14-.26-.28-.4-.42C36.62 2.69 30.62 0 24 0S11.38 2.69 7.03 7.03C2.69 11.37 0 17.37 0 24c0 13.25 10.75 24 24 24 6" +
                    ".62 0 12.62-2.69 16.97-7.03C45.31 36.64 48 30.64 48 24c0-3.42-.71-6.67-2.01-9.61ZM21.54 25.9l-7.93-7.92 1.46-1.4" +
                    "6L23 24.44l-1.46 1.46Zm2.16-2.16-7.93-7.92 1.46-1.46 7.93 7.92-1.46 1.46Zm.3 19.65c-10.7 0-19.39-8.7-19.39-19.39S" +
                    "13.3 4.61 24 4.61c2.91 0 5.72.63 8.33 1.88l-.89 1.88c-2.33-1.11-4.84-1.68-7.43-1.68-9.55 0-17.33 7.77-17.33 17.3" +
                    "2s7.78 17.33 17.33 17.33c6.82 0 13.03-4.03 15.82-10.25l1.89.84C38.6 38.9 31.65 43.41 24.01 43.41Z",
            ),
        ),
    ),
    CatalogSourceId.MAL to Mark(
        25f, 37f, 900f,
        listOf(
            MarkPath("M360.18,640.05h-93.37v-215.38h-.85l-71.97,95.92-70.16-95.92h-.96v215.38H29.5v-356.23h88.57l75.91,104.66,77.61-104.66h88.58v356.23Z"),
            MarkPath(
                "M667.97,640.05h-93.37v-112.96h-101.99c.5,36.48,12.42,74.14,35.77,112.96l-75.8,50.14c-11.5-17.25-21.42-35.61-29.7" +
                    "6-55.09-8.34-19.48-14.71-39.57-19.11-60.26-4.4-20.69-6.6-41.26-6.6-61.7s2.31-42.21,6.92-62.76c4.61-20.55,11.71-4" +
                    "0.12,21.29-58.72,9.58-18.59,21.58-35.1,35.98-49.51,15.83-15.97,32.77-28.19,50.84-36.68,18.06-8.48,36.89-14.21,56" +
                    ".48-17.19,19.59-2.98,42.09-4.47,67.5-4.47h45.78l21.83,80.27h-73.25c-30.38,0-54.35,4.36-71.92,13.08-17.57,8.72-29" +
                    ".85,18.47-36.84,29.24-6.99,10.77-13.65,24.24-19.96,40.4h92.84v-71.76h93.37v264.99Z",
            ),
            MarkPath("M797.69,559.78h122.54l-21.83,80.28h-194.08v-356.23h93.37v275.96Z"),
        ),
    ),
    CatalogSourceId.ANILIST to Mark(
        75f, 75f, 363f,
        listOf(
            MarkPath(
                "M321.92 323.27V136.6c0-10.698-5.887-16.602-16.558-16.602h-36.433c-10.672 0-16.561 5.904-16.561 16.602v88.651c0 " +
                    "2.497 23.996 14.089 24.623 16.541 18.282 71.61 3.972 128.92-13.359 131.6 28.337 1.405 31.455 15.064 10.348 5.731" +
                    " 3.229-38.209 15.828-38.134 52.049-1.406.31.317 7.427 15.282 7.87 15.282h85.545c10.672 0 16.558-5.9 16.558-16.6v" +
                    "-36.524c0-10.698-5.886-16.602-16.558-16.602z",
                color = Color(0xFF02A9FF),
            ),
            MarkPath("M170.68 120 74.999 393h74.338l16.192-47.222h80.96L262.315 393h73.968l-95.314-273zm11.776 165.28 23.183-75.629 25.393 75.629z"),
        ),
    ),
    CatalogSourceId.SIMKL to Mark(
        205f, 196f, 1124f,
        listOf(
            MarkPath(
                "M205.832 970.284c0 35.322 1.82 65.9 5.433 91.774 6.709 53.176 28.198 94.359 64.507 123.51 33.579 27.302 88.907 4" +
                    "5.656 165.984 55.065 63.178 7.983 165.983 11.993 308.45 11.993 234.287 0 377.455-7.982 429.428-23.947 52.859-15." +
                    "964 90.936-45.77 114.232-89.46 23.295-44.153 34.944-113.446 34.944-207.843 0-84.525-11.907-145.798-35.645-183.85" +
                    "8-15.702-25.836-36.64-45.772-62.885-59.885-26.244-14.074-61.52-24.64-105.9-31.697-43.937-7.018-145.452-12.917-30" +
                    "4.58-17.622-175.752-5.63-274.576-11.49-296.545-17.584-26.024-7.519-39-28.188-39-62.006 0-35.205 12.312-57.03 36." +
                    "972-65.514 21.97-7.018 92.115-10.566 210.476-10.566 119.65 0 194.955 1.427 225.92 4.203 34.942 3.317 55.584 18.0" +
                    "4 61.85 44.26 2.25 8.908 3.835 24.833 4.72 47.777h271c.368-22.442.589-38.83.589-49.127 0-95.475-21.527-161.676-6" +
                    "4.58-198.657-31.847-26.683-83.858-45.386-156.032-56.183-54.7-7.944-148.4-11.915-281.099-11.915-204.024 0-333.149" +
                    " 4.704-387.407 14.075-60.082 10.797-104.942 33.047-134.505 66.748-39.477 44.538-59.198 121.158-59.198 229.823 0 " +
                    "51.555 4.017 93.278 12.09 125.129 14.338 57.649 44.822 98.407 91.451 122.276 36.309 18.741 98.861 29.538 187.622" +
                    " 32.353 34.058.926 108.444 4.204 223.228 9.833 111.172 5.63 184.23 8.445 219.212 8.445 50.645.926 82.678 8.213 9" +
                    "6.168 21.787 9.843 9.832 14.783 26.915 14.783 51.286 0 35.63-7.852 58.612-23.518 68.908-11.206 7.018-34.502 11.9" +
                    "53-69.887 14.73-18.837.963-87.84 1.658-207.011 2.12-86.954-.462-138.265-.924-153.93-1.387-31.369-.926-53.338-2.5" +
                    "84-65.871-4.936-12.532-2.314-23.738-6.44-33.58-12.996-18.835-13.573-28.014-44.036-27.571-91.389H205.832v50.824-.347z",
            ),
        ),
    ),
    CatalogSourceId.SEERR to Mark(
        0f, 0f, 96f,
        listOf(
            MarkPath(
                "M48 96C74.5097 96 96 74.5097 96 48C96 21.4903 74.5097 0 48 0C21.4903 0 0 21.4903 0 48C0 74.5097 21.4903 96 48 96" +
                    "ZM80.0001 52C80.0001 67.464 67.4641 80 52.0001 80C36.5361 80 24.0001 67.464 24.0001 52C24.0001 49.1303 24.4318 4" +
                    "6.3615 25.2338 43.7548C27.4288 48.6165 32.3194 52 38.0001 52C45.7321 52 52.0001 45.732 52.0001 38C52.0001 32.319" +
                    "2 48.6166 27.4287 43.755 25.2337C46.3616 24.4317 49.1304 24 52.0001 24C67.4641 24 80.0001 36.536 80.0001 52Z",
                evenOdd = true,
            ),
        ),
    ),
    CatalogSourceId.MDBLIST to Mark(
        0f, 0f, 24f,
        listOf(
            MarkPath(
                "M1.928.029A2.47 2.47 0 0 0 .093 1.673c-.085.248-.09.629-.09 10.33s.005 10.08.09 10.33a2.51 2.51 0 0 0 1.512 1.55" +
                    "8l.276.108h20.237l.277-.108a2.51 2.51 0 0 0 1.512-1.559c.085-.25.09-.63.09-10.33s-.005-10.08-.09-10.33A2.51 2.51" +
                    " 0 0 0 22.395.115l-.277-.109L12.117 0C6.615-.004 2.032.011 1.929.029m7.48 8.067 2.123 2.004v1.54c0 .897-.02 1.5" +
                    "36-.043 1.527s-.92-.845-1.995-1.86c-1.071-1.01-1.962-1.84-1.977-1.84s-.024 1.91-.024 4.248v4.25H4.911V6.085h1.18" +
                    "8l1.183.006zm9.729 3.93v5.94h-2.63l-.01-4.25-.013-4.25-1.907 1.795a367 367 0 0 1-1.98 1.864c-.076.056-.08-.047-" +
                    ".08-1.489v-1.555l2.127-1.995 2.122-1.995 1.187-.005h1.184z",
            ),
        ),
    ),
)
