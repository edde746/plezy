package com.edde746.plezy.libass

/**
 * Result of a packed-atlas render. The atlas pixel data is stored in the direct ByteBuffer
 * that was passed into [AssRender.renderFrameAtlas]; the vertex stream is in the other.
 *
 * @param atlasWidth  atlas row stride in pixels (= the allocated width; 0 when [changed] == 0)
 * @param atlasHeight packed atlas height in pixels — the rows worth uploading
 * @param quadCount   number of quads; the vertex buffer holds [quadCount] * 6 vertices
 * @param changed     libass change flag (0 = no change, 1 = positions, 2 = content)
 * @param truncated   images dropped because they exceeded the atlas/vertex capacity;
 *                    the frame is incomplete but never stale (> 0 should be rare —
 *                    it means even the GL-max-sized atlas couldn't fit the frame)
 * @param hasOutput   true when libass reported at least one visible image for this
 *                    timestamp, even when [changed] is 0 and the buffers were not
 *                    rewritten. false means this timestamp should be blank.
 */
class AssAtlasFrame(
  val atlasWidth: Int,
  val atlasHeight: Int,
  val quadCount: Int,
  val changed: Int,
  val truncated: Int,
  val hasOutput: Boolean
) {
  constructor(
    atlasWidth: Int,
    atlasHeight: Int,
    quadCount: Int,
    changed: Int,
    truncated: Int
  ) : this(atlasWidth, atlasHeight, quadCount, changed, truncated, quadCount > 0)
}
