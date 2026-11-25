package com.edde746.plezy.playback

import kotlin.test.Test
import kotlin.test.assertEquals

class VideoLayoutTest {
    @Test
    fun eachFitIsMpvsPanscanOrAspectOverrideWithTheZoomOnTop() {
        assertEquals(
            mapOf("panscan" to "0", "video-aspect-override" to "no", "video-zoom" to "0", "sub-ass-force-margins" to "no"),
            VideoLayout.DEFAULT.properties(surfaceAspect = 16.0 / 9),
        )
        assertEquals(
            mapOf("panscan" to "1", "video-aspect-override" to "no", "video-zoom" to "0", "sub-ass-force-margins" to "yes"),
            VideoLayout(VideoFit.COVER).properties(surfaceAspect = 16.0 / 9),
        )
        assertEquals(
            mapOf("panscan" to "0", "video-aspect-override" to "2.1667", "video-zoom" to "0.585", "sub-ass-force-margins" to "yes"),
            VideoLayout(VideoFit.FILL, zoom = 1.5).properties(surfaceAspect = 2340.0 / 1080),
        )
        assertEquals("no", VideoLayout(VideoFit.FILL).properties(surfaceAspect = null)["video-aspect-override"], "a fill waits for the surface's size")
        assertEquals(
            mapOf("panscan" to "0", "video-aspect-override" to "no", "video-zoom" to "-1", "sub-ass-force-margins" to "no"),
            VideoLayout(zoom = 0.5).properties(surfaceAspect = 1.0),
        )
    }

    @Test
    fun theZoomKeepsToWholePercentWithinItsRange() {
        assertEquals(1.0, VideoLayout.normalizeZoom(1.004))
        assertEquals(1.24, VideoLayout.normalizeZoom(1.236))
        assertEquals(2.0, VideoLayout.normalizeZoom(3.0))
        assertEquals(0.5, VideoLayout.normalizeZoom(0.0))
        assertEquals(1.0, VideoLayout.normalizeZoom(Double.NaN))
    }
}
