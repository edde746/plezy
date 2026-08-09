package com.edde746.plezy.exoplayer

import androidx.media3.ui.AspectRatioFrameLayout
import org.junit.Assert.assertEquals
import org.junit.Test

class SubtitleViewLayoutTest {

  @Test
  fun letterboxUsesVisibleVideoRectForTextAndBitmapSubtitles() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT)
    val bitmap = bitmapDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT)

    assertEquals(SubtitleViewDimensions(1920, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
  }

  @Test
  fun coverKeepsTextOnScreenAndBitmapSubtitlesFullyVisible() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM)
    val bitmap = bitmapDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM)

    assertEquals(SubtitleViewDimensions(2424, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
    assertAspectCloseTo16By9(bitmap!!)
  }

  @Test
  fun manualZoomKeepsBitmapSubtitlesFullyVisible() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT, zoomScale = 1.5f)
    val bitmap = bitmapDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT, zoomScale = 1.5f)

    assertEquals(SubtitleViewDimensions(2424, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
    assertAspectCloseTo16By9(bitmap!!)
  }

  @Test
  fun stretchDoesNotStretchBitmapSubtitlesToScreenAspect() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL)
    val bitmap = bitmapDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL)

    assertEquals(SubtitleViewDimensions(2424, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
    assertAspectCloseTo16By9(bitmap!!)
  }

  @Test
  fun anchorToScreenSizesTextToContainerAndKeepsBitmapOnVideoRect() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT, anchorToScreen = true)
    val bitmap = bitmapDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT)

    assertEquals(SubtitleViewDimensions(2424, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
    assertAspectCloseTo16By9(bitmap!!)
  }

  @Test
  fun anchorToScreenReachesBelowLetterboxedWideVideo() {
    // 2.37:1 video on a 16:9 screen — the #1730 use case. Without the anchor
    // the text view stops at the bottom letterbox bar; with it the view spans
    // the physical screen height.
    val unanchored = SubtitleViewLayout.textDimensions(
      containerWidth = 1920,
      containerHeight = 1080,
      videoWidth = 2560,
      videoHeight = 1080,
      pixelRatio = 1f,
      resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT,
      zoomScale = 1f
    )
    val anchored = SubtitleViewLayout.textDimensions(
      containerWidth = 1920,
      containerHeight = 1080,
      videoWidth = 2560,
      videoHeight = 1080,
      pixelRatio = 1f,
      resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT,
      zoomScale = 1f,
      anchorToScreen = true
    )

    assertEquals(SubtitleViewDimensions(1920, 810), unanchored)
    assertEquals(SubtitleViewDimensions(1920, 1080), anchored)
  }

  private fun textDimensions(
    resizeMode: Int,
    zoomScale: Float = 1f,
    anchorToScreen: Boolean = false
  ): SubtitleViewDimensions? = SubtitleViewLayout.textDimensions(
    containerWidth = 2424,
    containerHeight = 1080,
    videoWidth = 1920,
    videoHeight = 1080,
    pixelRatio = 1f,
    resizeMode = resizeMode,
    zoomScale = zoomScale,
    anchorToScreen = anchorToScreen
  )

  private fun bitmapDimensions(
    resizeMode: Int,
    zoomScale: Float = 1f
  ): SubtitleViewDimensions? = SubtitleViewLayout.bitmapDimensions(
    containerWidth = 2424,
    containerHeight = 1080,
    videoWidth = 1920,
    videoHeight = 1080,
    pixelRatio = 1f,
    resizeMode = resizeMode,
    zoomScale = zoomScale
  )

  private fun assertAspectCloseTo16By9(dimensions: SubtitleViewDimensions) {
    val aspect = dimensions.width.toDouble() / dimensions.height
    assertEquals(16.0 / 9.0, aspect, 0.001)
  }
}
