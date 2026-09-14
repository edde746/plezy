package com.edde746.plezy.libass

/**
 * Result of a packed-atlas render. The atlas pixel data is stored in the direct ByteBuffer
 * that was passed into [AssRender.renderFrameAtlas]; the vertex stream is in the other.
 *
 * In the common [MODE_ATLAS] the atlas may span more than one ALPHA_8 *page* — a heavy
 * full-screen sign can produce more sub-pixels than a single GL-max texture holds. Pages
 * are vertically stacked in the atlas ByteBuffer (page `p` at byte offset
 * `p * atlasWidth * atlasMaxHeight`), each its own texture, and are drawn in turn. Quads
 * are emitted in libass painter order and page assignment is monotonic in that order, so
 * each page's quads form one contiguous run in the vertex stream ([pageQuadCounts]); the
 * runner uploads page `p`, then draws its run.
 *
 * In [MODE_COMPOSITE] the frame was too dense for the paged atlas (its summed image area
 * exceeds every page: overlapping paint-stroke signs, #1868) and the native side flattened
 * it into one premultiplied RGBA rect of [atlasWidth] × `pageHeights[0]` pixels at the
 * start of the atlas ByteBuffer, drawn as the single emitted quad with UVs 0..1.
 *
 * Built in Kotlin by [AssRender.renderFrameAtlas] from the int[] header the native
 * renderer fills (see `writeAtlasHeader` in AssKt.c) — never constructed from JNI, so
 * the minifier may obfuscate it freely without breaking the native boundary.
 *
 * @param atlasWidth     atlas row stride in pixels (= the allocated width; same for every
 *                       page; 0 when [changed] == 0) — or the RGBA rect width in
 *                       [MODE_COMPOSITE]
 * @param pageHeights    packed height (rows worth uploading) of each page; `size` = page count
 * @param pageQuadCounts quads on each page, contiguous in the vertex stream in this order;
 *                       `size` = page count, `sum` = [quadCount]
 * @param quadCount      total quads; the vertex buffer holds [quadCount] * 6 vertices
 * @param changed        libass change flag (0 = no change, 1 = positions, 2 = content)
 * @param truncated      images dropped because the frame needed more capacity than the
 *                       buffer holds; the frame is incomplete but never stale. Recoverable
 *                       by growing to [requiredPages]; with the composite fallback,
 *                       unrecoverable truncation should be unreachable for real content
 * @param requiredPages  pages of buffer capacity this frame needs to render completely.
 *                       When it exceeds [pageHeights].size the caller must grow the atlas
 *                       buffer and re-render; the rendered pages are still valid in the
 *                       meantime.
 * @param hasOutput      true when libass reported at least one visible image for this
 *                       timestamp, even when [changed] is 0 and the buffers were not
 *                       rewritten. false means this timestamp should be blank.
 * @param mode           [MODE_ATLAS] or [MODE_COMPOSITE]; must match the ASS_PACK_MODE_*
 *                       constants in AssPack.h
 */
class AssAtlasFrame(
  val atlasWidth: Int,
  val pageHeights: IntArray,
  val pageQuadCounts: IntArray,
  val quadCount: Int,
  val changed: Int,
  val truncated: Int,
  val requiredPages: Int,
  val hasOutput: Boolean,
  val mode: Int = MODE_ATLAS
) {
  companion object {
    /** One or more ALPHA_8 atlas pages, per-quad colors in the vertex stream. */
    const val MODE_ATLAS = 0

    /** One premultiplied RGBA rect at the start of the atlas buffer, one quad. */
    const val MODE_COMPOSITE = 1
  }

  /** Number of atlas pages this frame occupies. */
  val pageCount: Int get() = pageHeights.size

  /** Packed height of the first page; the only page in the common single-page case. */
  val atlasHeight: Int get() = if (pageHeights.isNotEmpty()) pageHeights[0] else 0

  /** Single-page convenience: blank/unchanged frames and tests. */
  constructor(
    atlasWidth: Int,
    atlasHeight: Int,
    quadCount: Int,
    changed: Int,
    truncated: Int,
    hasOutput: Boolean
  ) : this(atlasWidth, intArrayOf(atlasHeight), intArrayOf(quadCount), quadCount, changed, truncated, 1, hasOutput)

  constructor(
    atlasWidth: Int,
    atlasHeight: Int,
    quadCount: Int,
    changed: Int,
    truncated: Int
  ) : this(atlasWidth, atlasHeight, quadCount, changed, truncated, quadCount > 0)
}
