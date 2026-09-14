#include "AssPack.h"

#include <limits.h>
#include <stdlib.h>
#include <string.h>

// A tile is a <= atlasMaxW x atlasMaxH sub-rect of an ASS_Image. A single image
// can exceed one atlas page only when the render frame is larger than a page
// (>4K, or a GPU whose max texture is below the frame) — multi-page can't split
// one image across pages (a quad samples one texture), so tiling does, keeping
// the never-drop guarantee. (#1436 itself was atlas-AREA overflow, fixed by the
// multi-page pack below, not oversized single images.) Tiles are built in list
// order (= libass blend/painter order, preserved for emission); the single-page
// pack runs height-sorted via a separate key array so emission order is untouched.
typedef struct {
  ASS_Image* img;  // source image (for bitmap/stride/color/dst_x/dst_y)
  int ox, oy;      // tile offset within the source bitmap
  int tw, th;      // tile size (<= atlasMaxW x atlasMaxH)
  int page;        // atlas page the tile is packed into; -1 if dropped for capacity
  int sx, sy;      // packed slot within the page; valid when page >= 0
} PackTile;

typedef struct {
  int th;   // tile height (the sort key)
  int idx;  // index into the build-order tiles[] array
} TileSortKey;

static int compareTileKeysByHeightDesc(const void* a, const void* b) {
  return ((const TileSortKey*)b)->th - ((const TileSortKey*)a)->th;
}

// 8 floats per vertex (x, y, u, v, r, g, b, a) x 6 vertices; layout must match
// BYTES_PER_QUAD/VERTEX in AssSubtitleAtlasPipeline.kt.
static void emitQuad(
    float* vx, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1, float r, float g,
    float b, float a) {
  const float pos[6][2] = {{x0, y0}, {x1, y0}, {x0, y1}, {x1, y0}, {x1, y1}, {x0, y1}};
  const float uv[6][2] = {{u0, v0}, {u1, v0}, {u0, v1}, {u1, v0}, {u1, v1}, {u0, v1}};
  for (int i = 0; i < 6; i++) {
    *vx++ = pos[i][0];
    *vx++ = pos[i][1];
    *vx++ = uv[i][0];
    *vx++ = uv[i][1];
    *vx++ = r;
    *vx++ = g;
    *vx++ = b;
    *vx++ = a;
  }
}

// Flattens the whole image list into one premultiplied RGBA rect (the union
// bounding box) at the start of `atlasPixels`, emitted as a single quad. The
// blend is libass painter-order src-over, the same math the GL path applies to
// alpha-atlas quads, so output is visually identical — memory just becomes
// O(union area <= frame area) instead of O(sum of image areas). Used for
// frames whose summed image area cannot fit ASS_PACK_MAX_PAGES alpha pages
// (#1868: ~150 overlapping paint-strokes put ~5 pages of tiles at 1080p and
// ~19 at 4K behind a 4-page cap, silently dropping the painter-order tail —
// the sign's text).
static void compositeFrame(
    ASS_Image* image, uint8_t* atlasPixels, size_t atlasCap, size_t pageBytes, float* vertices, size_t vertexCap,
    AssPackResult* out) {
  int ux0 = INT_MAX, uy0 = INT_MAX, ux1 = INT_MIN, uy1 = INT_MIN;
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w <= 0 || img->h <= 0) continue;
    if (img->dst_x < ux0) ux0 = img->dst_x;
    if (img->dst_y < uy0) uy0 = img->dst_y;
    if (img->dst_x + img->w > ux1) ux1 = img->dst_x + img->w;
    if (img->dst_y + img->h > uy1) uy1 = img->dst_y + img->h;
  }
  const int uw = ux1 - ux0;
  const int uh = uy1 - uy0;
  const size_t rgbaBytes = (size_t)uw * uh * 4;

  out->mode = ASS_PACK_MODE_COMPOSITE;
  out->requiredPages = (int)((rgbaBytes + pageBytes - 1) / pageBytes);
  out->pageCount = 1;
  if (rgbaBytes > atlasCap || vertexCap < 192) {
    // Buffers too small for the flattened rect: report the needed capacity and
    // write nothing — the caller grows and re-renders (same contract as the
    // multi-page atlas grow). truncated flags the frame as not presentable.
    out->truncated = out->totalTiles;
    return;
  }

  memset(atlasPixels, 0, rgbaBytes);
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w <= 0 || img->h <= 0) continue;
    const unsigned int c = img->color;
    const unsigned cr = (c >> 24) & 0xFFu;
    const unsigned cg = (c >> 16) & 0xFFu;
    const unsigned cb = (c >> 8) & 0xFFu;
    const unsigned ca = 0xFFu - (c & 0xFFu);
    if (ca == 0) continue;
    for (int y = 0; y < img->h; y++) {
      const uint8_t* src = img->bitmap + (size_t)y * img->stride;
      uint8_t* dst = atlasPixels + (((size_t)(img->dst_y - uy0 + y) * uw) + (size_t)(img->dst_x - ux0)) * 4;
      for (int x = 0; x < img->w; x++, dst += 4) {
        const unsigned a = (src[x] * ca + 127u) / 255u;
        if (a == 0) continue;
        const unsigned inv = 255u - a;
        dst[0] = (uint8_t)((cr * a + dst[0] * inv + 127u) / 255u);
        dst[1] = (uint8_t)((cg * a + dst[1] * inv + 127u) / 255u);
        dst[2] = (uint8_t)((cb * a + dst[2] * inv + 127u) / 255u);
        dst[3] = (uint8_t)((255u * a + dst[3] * inv + 127u) / 255u);
      }
    }
  }

  out->atlasWidth = uw;
  out->pageHeights[0] = uh;
  out->pageQuads[0] = 1;
  out->quadCount = 1;
  out->truncated = 0;
  emitQuad(
      vertices, (float)ux0, (float)uy0, (float)(ux0 + uw), (float)(uy0 + uh), 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
      1.0f);
}

int ass_pack_frame(
    ASS_Image* image, uint8_t* atlasPixels, size_t atlasCap, int atlasMaxW, int atlasMaxH, float* vertices,
    size_t vertexCap, AssPackResult* out) {
  memset(out, 0, sizeof(*out));
  out->mode = ASS_PACK_MODE_ATLAS;
  out->requiredPages = 1;
  out->pageCount = 1;

  // 48 floats per quad x 4 bytes = 192 bytes/quad
  const int maxQuads = (int)(vertexCap / 192);
  const size_t pageBytes = (size_t)atlasMaxW * atlasMaxH;
  int providedPages = (int)(atlasCap / pageBytes);
  if (providedPages > ASS_PACK_MAX_PAGES) providedPages = ASS_PACK_MAX_PAGES;

  // Split every image into <= atlasMaxW x atlasMaxH tiles, then pack the tiles.
  // tiles[] stays in list order (= blend/painter order for emission); keys[] is
  // sorted by height for the single-page pack so it produces tight rows.
  int total = 0;
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w > 0 && img->h > 0) {
      int cols = (img->w + atlasMaxW - 1) / atlasMaxW;
      int rows = (img->h + atlasMaxH - 1) / atlasMaxH;
      total += cols * rows;
    }
  }
  out->totalTiles = total;
  if (total == 0) return 1;

  PackTile* tiles = (PackTile*)malloc(sizeof(PackTile) * (size_t)total);
  TileSortKey* keys = (TileSortKey*)malloc(sizeof(TileSortKey) * (size_t)total);
  if (!tiles || !keys) {
    free(tiles);
    free(keys);
    return 0;
  }
  int n = 0;
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w <= 0 || img->h <= 0) continue;
    out->srcPixels += (long long)img->w * img->h;
    for (int oy = 0; oy < img->h; oy += atlasMaxH) {
      int th = img->h - oy;
      if (th > atlasMaxH) th = atlasMaxH;
      for (int ox = 0; ox < img->w; ox += atlasMaxW) {
        int tw = img->w - ox;
        if (tw > atlasMaxW) tw = atlasMaxW;
        tiles[n] = (PackTile){.img = img, .ox = ox, .oy = oy, .tw = tw, .th = th, .page = -1, .sx = -1, .sy = -1};
        keys[n] = (TileSortKey){.th = th, .idx = n};
        n++;
      }
    }
  }
  int truncated = 0;

  // Pass 1a: height-sorted single page — the common case, minimal packed height
  // (byte-identical to the prior single-page packer when the frame fits one page).
  qsort(keys, (size_t)n, sizeof(TileSortKey), compareTileKeysByHeightDesc);
  int cursorX = 0, cursorY = 0, rowH = 0, packedH = 0, accepted = 0;
  for (int i = 0; i < n; i++) {
    PackTile* t = &tiles[keys[i].idx];
    if (accepted >= maxQuads) break;
    int cx = cursorX, cy = cursorY, rh = rowH;
    if (cx + t->tw > atlasMaxW) {
      cy += rh;
      cx = 0;
      rh = 0;
    }
    if (cy + t->th > atlasMaxH) continue;  // doesn't fit a single page
    t->page = 0;
    t->sx = cx;
    t->sy = cy;
    cursorX = cx + t->tw;
    cursorY = cy;
    rowH = (t->th > rh) ? t->th : rh;
    if (cy + t->th > packedH) packedH = cy + t->th;
    accepted++;
  }

  if (accepted == n) {
    out->pageHeights[0] = packedH;
    out->pageQuads[0] = accepted;
  } else {
    // Pass 1b: the frame overflows one page. Re-pack in list order, starting a new
    // page whenever a tile won't fit the current one. List order keeps the page
    // index monotonic in painter order, so each page's quads stay one contiguous run.
    for (int i = 0; i < n; i++) {
      tiles[i].page = -1;
      tiles[i].sx = -1;
      tiles[i].sy = -1;
    }
    int requiredPages = 1;
    int page = 0, cx = 0, cy = 0, rh = 0, placed = 0;
    for (int i = 0; i < n; i++) {
      PackTile* t = &tiles[i];
      if (cx + t->tw > atlasMaxW) {
        cy += rh;
        cx = 0;
        rh = 0;
      }
      if (cy + t->th > atlasMaxH) {
        page++;
        cx = 0;
        cy = 0;
        rh = 0;
      }
      if (page + 1 > requiredPages) requiredPages = page + 1;
      if (page < providedPages && placed < maxQuads) {
        t->page = page;
        t->sx = cx;
        t->sy = cy;
        if (cy + t->th > out->pageHeights[page]) out->pageHeights[page] = cy + t->th;
        out->pageQuads[page]++;
        placed++;
      }
      cx += t->tw;
      rh = (t->th > rh) ? t->th : rh;
    }
    if (requiredPages > ASS_PACK_MAX_PAGES || n > maxQuads) {
      // The frame can never fit the paged alpha atlas: its tiles exceed the page
      // cap or the vertex budget outright. Flatten instead of dropping the
      // painter-order tail (#1868).
      free(tiles);
      free(keys);
      memset(out->pageHeights, 0, sizeof(out->pageHeights));
      memset(out->pageQuads, 0, sizeof(out->pageQuads));
      compositeFrame(image, atlasPixels, atlasCap, pageBytes, vertices, vertexCap, out);
      return 1;
    }
    out->requiredPages = requiredPages;
    out->pageCount = (requiredPages < providedPages) ? requiredPages : providedPages;
    accepted = placed;
    truncated = n - placed;
  }

  out->truncated = truncated;
  if (accepted == 0) {
    free(tiles);
    free(keys);
    memset(out->pageHeights, 0, sizeof(out->pageHeights));
    memset(out->pageQuads, 0, sizeof(out->pageQuads));
    return 1;
  }

  // Clear only the packed rows of each written page.
  for (int p = 0; p < out->pageCount; p++) {
    memset(atlasPixels + (size_t)p * pageBytes, 0, (size_t)atlasMaxW * out->pageHeights[p]);
  }

  // Emit tiles in list order (= libass's painter/blend order), copying each placed
  // tile into its page slot and emitting its quad. Monotonic page assignment makes
  // each page's quads a contiguous run, matching pageQuads[] for the per-page draw.
  int qi = 0;
  for (int i = 0; i < n; i++) {
    PackTile* t = &tiles[i];
    if (t->page < 0) continue;
    ASS_Image* img = t->img;
    const int px = t->sx;
    const int py = t->sy;
    uint8_t* pageBase = atlasPixels + (size_t)t->page * pageBytes;

    for (int y = 0; y < t->th; y++) {
      uint8_t* dst = pageBase + (size_t)(py + y) * atlasMaxW + px;
      const uint8_t* src = img->bitmap + (size_t)(t->oy + y) * img->stride + t->ox;
      memcpy(dst, src, (size_t)t->tw);
    }

    const unsigned int c = img->color;
    emitQuad(
        vertices + (size_t)qi * 48, (float)(img->dst_x + t->ox), (float)(img->dst_y + t->oy),
        (float)(img->dst_x + t->ox + t->tw), (float)(img->dst_y + t->oy + t->th), (float)px / (float)atlasMaxW,
        (float)py / (float)atlasMaxH, (float)(px + t->tw) / (float)atlasMaxW, (float)(py + t->th) / (float)atlasMaxH,
        (float)((c >> 24) & 0xFFu) / 255.0f, (float)((c >> 16) & 0xFFu) / 255.0f, (float)((c >> 8) & 0xFFu) / 255.0f,
        (float)(0xFFu - (c & 0xFFu)) / 255.0f);
    qi++;
  }

  free(tiles);
  free(keys);
  out->quadCount = qi;
  out->atlasWidth = atlasMaxW;
  return 1;
}
