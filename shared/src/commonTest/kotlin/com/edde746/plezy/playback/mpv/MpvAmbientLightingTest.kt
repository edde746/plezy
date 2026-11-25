package com.edde746.plezy.playback.mpv

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MpvAmbientLightingTest {
    private val calls = mutableListOf<String>()
    private var refuses: String? = null
    private val ambient = MpvAmbientLighting(
        set = { name, value ->
            calls += "$name=$value"
            name != refuses
        },
        command = { args ->
            calls += args.joinToString(" ")
            true
        },
    )

    @Test
    fun onHandsMpvThePicturesAspectThenTheShaderThenTheFill() {
        ambient.onVideoParams(16.0 / 9)
        ambient.set(SHADER)
        assertEquals(
            listOf("sub-video-rect-aspect=${16.0 / 9}", "change-list glsl-shaders append $SHADER", "keepaspect=no"),
            calls,
        )
    }

    @Test
    fun onWaitsForThePicturesAspect() {
        ambient.set(SHADER)
        assertEquals(emptyList(), calls, "no picture yet")
        ambient.onVideoParams(null)
        assertEquals(emptyList(), calls)
        ambient.onVideoParams(2.4)
        assertEquals(listOf("sub-video-rect-aspect=2.4", "change-list glsl-shaders append $SHADER", "keepaspect=no"), calls)
    }

    @Test
    fun offLetterboxesFirstThenTakesTheShaderOutAndTheSubtitlesBackToThePicture() {
        ambient.onVideoParams(16.0 / 9)
        ambient.set(SHADER)
        calls.clear()
        ambient.set(null)
        assertEquals(listOf("keepaspect=yes", "change-list glsl-shaders remove $SHADER", "sub-video-rect-aspect=no"), calls)
        calls.clear()
        ambient.onVideoParams(2.4)
        assertEquals(emptyList(), calls, "off: another picture changes nothing")
    }

    @Test
    fun aRefusedSubtitleRectLeavesTheFrameAsItIs() {
        refuses = "sub-video-rect-aspect"
        ambient.onVideoParams(16.0 / 9)
        ambient.set(SHADER)
        assertEquals(listOf("sub-video-rect-aspect=${16.0 / 9}"), calls)
        ambient.onVideoParams(2.4)
        ambient.afterShadersRebuilt()
        assertEquals(1, calls.size, "it stays off: no fill, no shader")
    }

    @Test
    fun anotherPictureMovesOnlyTheSubtitles() {
        ambient.onVideoParams(16.0 / 9)
        ambient.set(SHADER)
        calls.clear()
        ambient.onVideoParams(2.39)
        ambient.onVideoParams(2.39)
        assertEquals(listOf("sub-video-rect-aspect=2.39"), calls)
    }

    @Test
    fun aRebuiltShaderListGetsTheShaderBackLast() {
        ambient.afterShadersRebuilt()
        assertEquals(emptyList(), calls, "off: nothing to put back")
        ambient.onVideoParams(1.5)
        ambient.set(SHADER)
        calls.clear()
        ambient.afterShadersRebuilt()
        assertEquals(listOf("change-list glsl-shaders append $SHADER"), calls)
    }

    @Test
    fun theDisplayAspectIsThePicturesShownSize() {
        assertEquals(2.4, MpvState.displayAspect("""{"pixelformat":"yuv420p","w":1920,"h":800,"dw":1920,"dh":800}"""))
        assertEquals(16.0 / 9, MpvState.displayAspect("""{"w":1440,"h":1080,"dw":1920,"dh":1080}"""), "anamorphic: the display size")
        assertTrue(MpvState.displayAspect(null) == null && MpvState.displayAspect("""{"w":1,"h":1}""") == null)
    }

    private companion object {
        const val SHADER = "/cache/shaders/ambient_lighting.glsl"
    }
}
