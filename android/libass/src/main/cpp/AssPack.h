// Pure-C frame packer behind the JNI atlas render entry point (AssKt.c).
// Kept free of JNI/Android includes so desktop test harnesses can compile the
// exact shipped packing/composite logic against a host libass build.
#ifndef PLEZY_ASS_PACK_H
#define PLEZY_ASS_PACK_H

#include <stddef.h>
#include <stdint.h>

#include "ass/ass.h"

// Hard cap on atlas pages. 4 pages of a GL-max texture covers the worst real
// frame measured for ordinary typesetting (a 4K-rendered full-screen letter
// needs 3); denser frames (#1868: ~1500 overlapping paint-stroke images whose
// summed area is ~19 pages at 4K) fall back to the RGBA composite below instead
// of dropping tiles. Must match AssAtlasPipelineConfig.MAX_ATLAS_PAGES.
#define ASS_PACK_MAX_PAGES 4

// Result modes. ATLAS: one or more ALPHA_8 pages plus per-quad vertices, the
// common fast path. COMPOSITE: the frame's images were flattened CPU-side into
// a single premultiplied RGBA rect (the union bounding box) drawn as one quad —
// memory is bounded by frame area instead of the sum of per-image areas.
#define ASS_PACK_MODE_ATLAS 0
#define ASS_PACK_MODE_COMPOSITE 1

typedef struct {
  int mode;  // ASS_PACK_MODE_*
  // ATLAS: row stride of every page. COMPOSITE: width of the RGBA rect.
  int atlasWidth;
  int quadCount;
  // Tiles dropped for capacity (frame incomplete). Composite output never
  // drops content; it reports truncated == totalTiles only in the
  // nothing-written grow request state (quadCount == 0).
  int truncated;
  // Pages of caller buffer capacity this frame needs to render completely.
  // When it exceeds the provided capacity the caller grows and re-renders.
  int requiredPages;
  int pageCount;
  int totalTiles;       // tiles the frame splits into (caller-side logging)
  long long srcPixels;  // summed source image area (caller-side logging)
  // ATLAS: packed rows per page / quads per page (contiguous vertex runs).
  // COMPOSITE: pageHeights[0] = RGBA rect height, pageQuads[0] = 1.
  int pageHeights[ASS_PACK_MAX_PAGES];
  int pageQuads[ASS_PACK_MAX_PAGES];
} AssPackResult;

// Packs libass's image list for `atlasPixels`/`vertices` (layout documented at
// the JNI entry point in AssKt.c). Never drops content for size: frames that
// cannot fit ASS_PACK_MAX_PAGES alpha pages (or the vertex budget) flatten into
// an RGBA composite; when the provided buffers are too small for either
// representation, requiredPages tells the caller how much to grow before
// re-rendering, and nothing is written. Returns 0 only on allocation failure.
int ass_pack_frame(
    ASS_Image* image, uint8_t* atlasPixels, size_t atlasCap, int atlasMaxW, int atlasMaxH, float* vertices,
    size_t vertexCap, AssPackResult* out);

#endif  // PLEZY_ASS_PACK_H
