package com.edde746.plezy.exoplayer

import androidx.media3.ui.AspectRatioFrameLayout
import org.junit.Assert.assertEquals
import org.junit.Test

class SubtitleViewLayoutTest {

  @Test
  fun letterboxUsesVisibleVideoRectForTextAndBitmapSubtitles() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT)
    val bitmap = bitmapDimensions()

    assertEquals(SubtitleViewDimensions(1920, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
  }

  @Test
  fun croppedVideoUsesBitmapCompositionPlaneAspect() {
    // #1945: 3840x1604 video with a 1920x1080 PGS plane in a 2400x1080 container.
    val planeAspect = SubtitleViewLayout.bitmapPlaneAspect(
      bitmapWidth = 480,
      bitmapHeight = 100,
      cueWidthFraction = 480f / 1920f,
      cueHeightFraction = 100f / 1080f
    )

    assertEquals(
      SubtitleViewDimensions(1781, 1002),
      SubtitleViewLayout.bitmapDimensions(
        containerWidth = 2400,
        containerHeight = 1080,
        videoWidth = 3840,
        videoHeight = 1604,
        pixelRatio = 1f,
        planeAspect = planeAspect
      )
    )
  }

  @Test
  fun coverKeepsTextOnScreenAndBitmapSubtitlesFullyVisible() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM)
    val bitmap = bitmapDimensions()

    assertEquals(SubtitleViewDimensions(2424, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
    assertAspectCloseTo16By9(bitmap!!)
  }

  @Test
  fun manualZoomKeepsBitmapSubtitlesFullyVisible() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT, zoomScale = 1.5f)
    val bitmap = bitmapDimensions()

    assertEquals(SubtitleViewDimensions(2424, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
    assertAspectCloseTo16By9(bitmap!!)
  }

  @Test
  fun stretchDoesNotStretchBitmapSubtitlesToScreenAspect() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL)
    val bitmap = bitmapDimensions()

    assertEquals(SubtitleViewDimensions(2424, 1080), text)
    assertEquals(SubtitleViewDimensions(1920, 1080), bitmap)
    assertAspectCloseTo16By9(bitmap!!)
  }

  @Test
  fun anchorToScreenSizesTextToContainerAndKeepsBitmapOnVideoRect() {
    val text = textDimensions(resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT, anchorToScreen = true)
    val bitmap = bitmapDimensions()

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

  private fun bitmapDimensions(): SubtitleViewDimensions? = SubtitleViewLayout.bitmapDimensions(
    containerWidth = 2424,
    containerHeight = 1080,
    videoWidth = 1920,
    videoHeight = 1080,
    pixelRatio = 1f,
    planeAspect = null
  )

  private fun assertAspectCloseTo16By9(dimensions: SubtitleViewDimensions) {
    val aspect = dimensions.width.toDouble() / dimensions.height
    assertEquals(16.0 / 9.0, aspect, 0.001)
  }
}
