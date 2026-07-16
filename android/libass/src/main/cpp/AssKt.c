// JNI bindings for libass. Exports use standard Java_<package>_<Class>_<method>
// naming so no RegisterNatives/JNI_OnLoad registration is needed.
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <android/log.h>
#include <jni.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>

static inline long long nowMs(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

#include "ass/ass.h"

#define LOG_TAG "SubtitleRenderer"

static void assMessageCallback(int level, const char* fmt, va_list args, void* data) {
  if (level > 4) return;

  if (level >= 2) {
    __android_log_vprint(ANDROID_LOG_WARN, LOG_TAG, fmt, args);
  } else {
    __android_log_vprint(ANDROID_LOG_ERROR, LOG_TAG, fmt, args);
  }
}

// --- Ass (library) ---

JNIEXPORT jlong JNICALL Java_com_edde746_plezy_libass_Ass_nativeAssInit(JNIEnv* env, jclass clazz) {
  ASS_Library* assLibrary = ass_library_init();
  ass_set_message_cb(assLibrary, assMessageCallback, NULL);
  ass_set_extract_fonts(assLibrary, 1);
  return (jlong)assLibrary;
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_Ass_nativeAssAddFont(
    JNIEnv* env, jclass clazz, jlong ass, jstring name, jbyteArray byteArray) {
  jsize length = (*env)->GetArrayLength(env, byteArray);
  jbyte* bytePtr = (*env)->GetByteArrayElements(env, byteArray, NULL);
  if (bytePtr == NULL) {
    return;
  }
  const char* cName = (*env)->GetStringUTFChars(env, name, NULL);
  ass_add_font(((ASS_Library*)ass), cName, (char*)bytePtr, length);
  (*env)->ReleaseByteArrayElements(env, byteArray, bytePtr, 0);
  if (cName != NULL) {
    (*env)->ReleaseStringUTFChars(env, name, cName);
  }
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_Ass_nativeAssDeinit(JNIEnv* env, jclass clazz, jlong ass) {
  if (ass) {
    ass_library_done((ASS_Library*)ass);
  }
}

// --- AssTrack ---

JNIEXPORT jlong JNICALL
Java_com_edde746_plezy_libass_AssTrack_nativeAssTrackInit(JNIEnv* env, jclass clazz, jlong ass) {
  ASS_Track* track = ass_new_track((ASS_Library*)ass);
  if (track != NULL) {
    if (ass_track_set_feature(track, ASS_FEATURE_FAST_BLUR, 1) != 0) {
      __android_log_print(ANDROID_LOG_WARN, LOG_TAG, "ASS_FEATURE_FAST_BLUR unavailable in libass build");
    }
  }
  return (jlong)track;
}

// Shared body of readBuffer/readChunk: pins the byte array and feeds libass.
// chunked != 0 routes to ass_process_chunk (timed dialogue), else ass_process_data.
static void processTrackBytes(
    JNIEnv* env, jlong track, jbyteArray buffer, jint offset, jint length, jlong start, jlong duration, int chunked) {
  if (!track) return;
  jbyte* elements = (*env)->GetByteArrayElements(env, buffer, NULL);
  if (elements == NULL) {
    return;
  }
  if (chunked) {
    ass_process_chunk((ASS_Track*)track, (char*)(elements + offset), length, start, duration);
  } else {
    ass_process_data((ASS_Track*)track, (char*)(elements + offset), length);
  }
  (*env)->ReleaseByteArrayElements(env, buffer, elements, 0);
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_AssTrack_nativeAssTrackReadBuffer(
    JNIEnv* env, jclass clazz, jlong track, jbyteArray buffer, jint offset, jint length) {
  processTrackBytes(env, track, buffer, offset, length, 0, 0, 0);
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_AssTrack_nativeAssTrackReadChunk(
    JNIEnv* env, jclass clazz, jlong track, jlong start, jlong duration, jbyteArray buffer, jint offset, jint length) {
  processTrackBytes(env, track, buffer, offset, length, start, duration, 1);
}

JNIEXPORT void JNICALL
Java_com_edde746_plezy_libass_AssTrack_nativeAssTrackDeinit(JNIEnv* env, jclass clazz, jlong track) {
  if (!track) return;
  ass_free_track((ASS_Track*)track);
}

// Earliest event Start strictly after afterMs, or -1. Lets the render pipeline
// pre-render (cache-warm) the next upcoming event during idle stretches so
// heavy typesetting doesn't pay its cache-cold rasterization at appearance.
JNIEXPORT jlong JNICALL Java_com_edde746_plezy_libass_AssTrack_nativeAssTrackNextEventStart(
    JNIEnv* env, jclass clazz, jlong track, jlong afterMs) {
  if (!track) return -1;
  ASS_Track* t = (ASS_Track*)track;
  long long best = -1;
  for (int i = 0; i < t->n_events; i++) {
    const long long start = t->events[i].Start;
    if (start > afterMs && (best < 0 || start < best)) best = start;
  }
  return (jlong)best;
}

// Earliest visible-content boundary (event Start OR End) strictly after afterMs,
// or -1. A cache-warming prefetch is only invisible while no boundary passes:
// the render pipeline uses this to ensure nothing on screen is due to change
// before the event it is about to warm.
JNIEXPORT jlong JNICALL Java_com_edde746_plezy_libass_AssTrack_nativeAssTrackNextEventChange(
    JNIEnv* env, jclass clazz, jlong track, jlong afterMs) {
  if (!track) return -1;
  ASS_Track* t = (ASS_Track*)track;
  long long best = -1;
  for (int i = 0; i < t->n_events; i++) {
    const long long start = t->events[i].Start;
    const long long end = start + t->events[i].Duration;
    if (start > afterMs && (best < 0 || start < best)) best = start;
    if (end > afterMs && (best < 0 || end < best)) best = end;
  }
  return (jlong)best;
}

// --- AssRender ---

// The fork's fontconfig build has no Android font search defaults. A tiny
// process-local config lets /system fonts resolve without adding Context/JNI plumbing.
static char* ensureFontsConf(void) {
  const char* tmp = getenv("TMPDIR");
  if (tmp == NULL || tmp[0] == '\0') tmp = "/data/local/tmp";

  char cacheDir[PATH_MAX];
  snprintf(cacheDir, sizeof(cacheDir), "%s/fontconfig", tmp);
  mkdir(cacheDir, 0700);

  char* confPath = (char*)malloc(PATH_MAX);
  if (confPath == NULL) return NULL;
  snprintf(confPath, PATH_MAX, "%s/fonts.conf", tmp);

  FILE* f = fopen(confPath, "w");
  if (f == NULL) {
    free(confPath);
    return NULL;
  }
  fprintf(
      f,
      "<?xml version=\"1.0\"?>\n"
      "<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">\n"
      "<fontconfig>\n"
      "  <dir>/system/fonts</dir>\n"
      "  <dir>/system/font</dir>\n"
      "  <dir>/product/fonts</dir>\n"
      "  <dir>/data/fonts</dir>\n"
      "  <cachedir>%s</cachedir>\n"
      "</fontconfig>\n",
      cacheDir);
  fclose(f);
  return confPath;
}

JNIEXPORT jlong JNICALL
Java_com_edde746_plezy_libass_AssRender_nativeAssRenderInit(JNIEnv* env, jclass clazz, jlong ass) {
  ASS_Renderer* assRenderer = ass_renderer_init((ASS_Library*)ass);
  if (assRenderer == NULL) return 0;
  unsigned threads = ass_set_threads(assRenderer, 0);
  if (threads == 0) {
    __android_log_print(ANDROID_LOG_WARN, LOG_TAG, "libass threading unavailable in native build");
  } else {
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "libass rendering threads enabled: %u", threads);
  }
  char* fontsConf = ensureFontsConf();
  ass_set_fonts(assRenderer, NULL, "sans-serif", ASS_FONTPROVIDER_FONTCONFIG, fontsConf, 1);
  free(fontsConf);
  return (jlong)assRenderer;
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_AssRender_nativeAssRenderSetFontScale(
    JNIEnv* env, jclass clazz, jlong render, jfloat scale) {
  if (!render) return;
  ass_set_font_scale((ASS_Renderer*)render, scale);
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_AssRender_nativeAssRenderSetCacheLimit(
    JNIEnv* env, jclass clazz, jlong render, jint glyphMax, jint bitmapMaxSize) {
  if (!render) return;
  ass_set_cache_limits((ASS_Renderer*)render, glyphMax, bitmapMaxSize);
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_AssRender_nativeAssRenderSetFrameSize(
    JNIEnv* env, jclass clazz, jlong render, jint width, jint height) {
  if (!render) return;
  ass_set_frame_size((ASS_Renderer*)render, width, height);
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_AssRender_nativeAssRenderSetStorageSize(
    JNIEnv* env, jclass clazz, jlong render, jint width, jint height) {
  if (!render) return;
  ass_set_storage_size((ASS_Renderer*)render, width, height);
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_AssRender_nativeAssRenderSetMargins(
    JNIEnv* env, jclass clazz, jlong render, jint top, jint bottom, jint left, jint right) {
  if (!render) return;
  ass_set_margins((ASS_Renderer*)render, top, bottom, left, right);
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_AssRender_nativeAssRenderSetUseMargins(
    JNIEnv* env, jclass clazz, jlong render, jboolean use) {
  if (!render) return;
  ass_set_use_margins((ASS_Renderer*)render, use ? 1 : 0);
}

JNIEXPORT void JNICALL
Java_com_edde746_plezy_libass_AssRender_nativeAssRenderDeinit(JNIEnv* env, jclass clazz, jlong render) {
  if (render) {
    ass_renderer_done((ASS_Renderer*)render);
  }
}

// Hard cap on atlas pages (see the packing comment below). 4 pages of a GL-max
// texture is far above the worst real frame measured (a 4K-rendered full-screen
// typeset letter needs 3); beyond it tiles are dropped and counted in truncated.
#define MAX_ATLAS_PAGES 4

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

static int imageListHasOutput(ASS_Image* image) {
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w > 0 && img->h > 0) return 1;
  }
  return 0;
}

// Throttle for truncation warnings (shared across renderers; logging only).
static int truncationLogCounter = 0;

// Frame metadata crosses to Kotlin through a fixed-layout int[] header (filled here,
// read + turned into an AssAtlasFrame by AssRender.kt) instead of constructing the
// object in JNI. A NewObject on an overloaded constructor is fragile under R8: the
// minified release build stripped/rewrote the (I[I[IIIIZ)V ctor the lookup bound by,
// crashing with NoSuchMethodError (#1436 follow-up). Binding a native method by name
// + populating a primitive array has no such reflective dependency. Layout:
//   [0]=atlasWidth [1]=quadCount [2]=changed [3]=truncated [4]=requiredPages
//   [5]=hasOutput  [6]=pageCount
//   [7 .. 7+MAX-1]            = pageHeights[pageCount]
//   [7+MAX .. 7+2*MAX-1]      = pageQuadCounts[pageCount]
#define ASS_HEADER_INTS (7 + 2 * MAX_ATLAS_PAGES)

static jint writeAtlasHeader(
    JNIEnv* env, jintArray headerBuf, int atlasWidth, int quadCount, int changed, int truncated, int requiredPages,
    int hasOutput, int pageCount, const int* pageHeights, const int* pageQuads) {
  int hdr[ASS_HEADER_INTS];
  memset(hdr, 0, sizeof(hdr));
  hdr[0] = atlasWidth;
  hdr[1] = quadCount;
  hdr[2] = changed;
  hdr[3] = truncated;
  hdr[4] = requiredPages;
  hdr[5] = hasOutput;
  hdr[6] = pageCount;
  for (int i = 0; i < pageCount && i < MAX_ATLAS_PAGES; i++) {
    hdr[7 + i] = pageHeights ? pageHeights[i] : 0;
    hdr[7 + MAX_ATLAS_PAGES + i] = pageQuads ? pageQuads[i] : 0;
  }
  (*env)->SetIntArrayRegion(env, headerBuf, 0, ASS_HEADER_INTS, hdr);
  return 1;
}

// Renders a frame into the provided atlas + vertex direct ByteBuffers.
//
// - atlasBuf holds one or more vertically-stacked ALPHA_8 *pages*, each atlasMaxW ×
//   atlasMaxH (row stride atlasMaxW); page p starts at byte offset p*atlasMaxW*atlasMaxH.
//   The buffer's capacity bounds how many pages this render may fill; AssAtlasFrame
//   reports pageHeights (rows worth uploading per page) and requiredPages.
// - vertexBuf holds a per-quad vertex stream (6 vertices × (2 pos + 2 uv + 4 color)
//   floats = 48 floats = 192 bytes per quad). Must match BYTES_PER_QUAD/VERTEX in
//   AssSubtitleAtlasPipeline.kt. UVs are page-local, normalized against atlasMaxW ×
//   atlasMaxH (the per-page texture dims).
// - The common case packs everything into a single height-sorted page (minimizes
//   packed height, byte-identical to the prior single-page packer). When that
//   overflows (a 4K full-screen sign can exceed one GL-max texture), the packer
//   spills into additional pages in list order: page assignment is monotonic in
//   libass's painter order, so each page's quads are one contiguous run in the
//   vertex stream and drawing the pages in turn reproduces the blend order.
// - Vertices are always emitted in original list order (= libass's painter order).
//
// Never fails on content size: when the frame needs more pages than the buffer holds
// (requiredPages > pageHeights.size) the caller grows the buffer and re-renders; any
// genuinely undrawable tiles (past MAX_ATLAS_PAGES / the vertex budget) are dropped
// and counted in truncated.
//
// Returns 0 for missing buffers/handles (the caller maps that to a null frame); 1 when
// the header was written. On changed == 0 the header carries (atlasWidth=0, quadCount=0,
// changed, hasOutput) without touching the atlas/vertex buffers — hasOutput lets Kotlin
// distinguish "reuse the previous atlas" from "blank, clear the GL surface."
JNIEXPORT jint JNICALL Java_com_edde746_plezy_libass_AssRender_nativeAssRenderFrameAtlas(
    JNIEnv* env, jclass clazz, jlong render, jlong track, jlong time, jobject atlasBuf, jint atlasMaxW, jint atlasMaxH,
    jobject vertexBuf, jintArray headerBuf) {
  if (!render || !track || !atlasBuf || !vertexBuf || !headerBuf || atlasMaxW <= 0 || atlasMaxH <= 0) return 0;

  const long long t0 = nowMs();
  int changed;
  ASS_Image* image = ass_render_frame((ASS_Renderer*)render, (ASS_Track*)track, time, &changed);
  const long long tAss = nowMs();

  if (changed == 0) {
    const int hasOutput = imageListHasOutput(image) ? 1 : 0;
    if (tAss - t0 > 40) {
      __android_log_print(
          ANDROID_LOG_WARN, LOG_TAG, "slow render t=%lldms: ass=%lldms (changed=%d, hasOutput=%d)", (long long)time,
          tAss - t0, changed, hasOutput);
    }
    return writeAtlasHeader(env, headerBuf, 0, 0, changed, 0, 1, hasOutput, 1, NULL, NULL);
  }

  if (image == NULL) {
    if (tAss - t0 > 40) {
      __android_log_print(
          ANDROID_LOG_WARN, LOG_TAG, "slow render t=%lldms: ass=%lldms (changed=%d, no output)", (long long)time,
          tAss - t0, changed);
    }
    return writeAtlasHeader(env, headerBuf, 0, 0, changed, 0, 1, 0, 1, NULL, NULL);
  }

  uint8_t* atlasPixels = (uint8_t*)(*env)->GetDirectBufferAddress(env, atlasBuf);
  jlong atlasCap = (*env)->GetDirectBufferCapacity(env, atlasBuf);
  float* vertices = (float*)(*env)->GetDirectBufferAddress(env, vertexBuf);
  jlong vertexCap = (*env)->GetDirectBufferCapacity(env, vertexBuf);
  if (!atlasPixels || !vertices) return 0;
  if ((jlong)atlasMaxW * atlasMaxH > atlasCap) {
    __android_log_print(
        ANDROID_LOG_ERROR, LOG_TAG, "atlas buffer smaller than %dx%d (capacity %lld bytes)", atlasMaxW, atlasMaxH,
        (long long)atlasCap);
    return 0;
  }
  // 48 floats per quad × 4 bytes = 192 bytes/quad
  const int maxQuads = (int)(vertexCap / 192);
  const size_t pageBytes = (size_t)atlasMaxW * atlasMaxH;
  int providedPages = (int)(atlasCap / (jlong)pageBytes);
  if (providedPages < 1) return 0;  // one page is guaranteed above; keep the page math safe
  if (providedPages > MAX_ATLAS_PAGES) providedPages = MAX_ATLAS_PAGES;

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
  if (total == 0) {
    return writeAtlasHeader(env, headerBuf, 0, 0, changed, 0, 1, 0, 1, NULL, NULL);
  }

  PackTile* tiles = (PackTile*)malloc(sizeof(PackTile) * (size_t)total);
  TileSortKey* keys = (TileSortKey*)malloc(sizeof(TileSortKey) * (size_t)total);
  if (!tiles || !keys) {
    free(tiles);
    free(keys);
    return 0;
  }
  int n = 0;
  long long srcPixels = 0;
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w <= 0 || img->h <= 0) continue;
    srcPixels += (long long)img->w * img->h;
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
  int pageHeights[MAX_ATLAS_PAGES] = {0};
  int pageQuads[MAX_ATLAS_PAGES] = {0};
  int pageCount = 1;
  int requiredPages = 1;
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
    pageHeights[0] = packedH;
    pageQuads[0] = accepted;
  } else {
    // Pass 1b: the frame overflows one page. Re-pack in list order, starting a new
    // page whenever a tile won't fit the current one. List order keeps the page
    // index monotonic in painter order, so each page's quads stay one contiguous run.
    for (int i = 0; i < n; i++) {
      tiles[i].page = -1;
      tiles[i].sx = -1;
      tiles[i].sy = -1;
    }
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
        if (cy + t->th > pageHeights[page]) pageHeights[page] = cy + t->th;
        pageQuads[page]++;
        placed++;
      }
      cx += t->tw;
      rh = (t->th > rh) ? t->th : rh;
    }
    pageCount = (requiredPages < providedPages) ? requiredPages : providedPages;
    accepted = placed;
    truncated = n - placed;
  }

  // Warn only for genuinely-unrecoverable loss. A frame that needs more pages than
  // the buffer currently holds, yet fits within MAX_ATLAS_PAGES and the vertex
  // budget, is recoverable: the caller grows the buffer and re-renders, so the
  // first (discarded) render's truncated > 0 is a false alarm, not data loss. Tiles
  // are only truly lost past the page cap or the vertex budget.
  const int recoverableGrow = requiredPages <= MAX_ATLAS_PAGES && n <= maxQuads;
  if (truncated > 0 && !recoverableGrow && (truncationLogCounter++ & 63) == 0) {
    __android_log_print(
        ANDROID_LOG_WARN, LOG_TAG, "atlas truncation: %d of %d tiles dropped (atlas %dx%d, need %d pages have %d)",
        truncated, n, atlasMaxW, atlasMaxH, requiredPages, providedPages);
  }
  if (accepted == 0) {
    free(tiles);
    free(keys);
    return writeAtlasHeader(env, headerBuf, 0, 0, changed, truncated, requiredPages, 1, 1, NULL, NULL);
  }

  // Clear only the packed rows of each written page.
  for (int p = 0; p < pageCount; p++) {
    memset(atlasPixels + (size_t)p * pageBytes, 0, (size_t)atlasMaxW * pageHeights[p]);
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

    const float x0 = (float)(img->dst_x + t->ox);
    const float y0 = (float)(img->dst_y + t->oy);
    const float x1 = x0 + (float)t->tw;
    const float y1 = y0 + (float)t->th;
    const float u0 = (float)px / (float)atlasMaxW;
    const float v0 = (float)py / (float)atlasMaxH;
    const float u1 = (float)(px + t->tw) / (float)atlasMaxW;
    const float v1 = (float)(py + t->th) / (float)atlasMaxH;
    const unsigned int c = img->color;
    const float r = (float)((c >> 24) & 0xFFu) / 255.0f;
    const float g = (float)((c >> 16) & 0xFFu) / 255.0f;
    const float b = (float)((c >> 8) & 0xFFu) / 255.0f;
    const float a = (float)(0xFFu - (c & 0xFFu)) / 255.0f;

    float* vx = vertices + (size_t)qi * 48;
    // 8 floats per vertex: x, y, u, v, r, g, b, a.
    // Triangle 1: (x0,y0) (x1,y0) (x0,y1)
    vx[0] = x0;
    vx[1] = y0;
    vx[2] = u0;
    vx[3] = v0;
    vx[4] = r;
    vx[5] = g;
    vx[6] = b;
    vx[7] = a;
    vx[8] = x1;
    vx[9] = y0;
    vx[10] = u1;
    vx[11] = v0;
    vx[12] = r;
    vx[13] = g;
    vx[14] = b;
    vx[15] = a;
    vx[16] = x0;
    vx[17] = y1;
    vx[18] = u0;
    vx[19] = v1;
    vx[20] = r;
    vx[21] = g;
    vx[22] = b;
    vx[23] = a;
    // Triangle 2: (x1,y0) (x1,y1) (x0,y1)
    vx[24] = x1;
    vx[25] = y0;
    vx[26] = u1;
    vx[27] = v0;
    vx[28] = r;
    vx[29] = g;
    vx[30] = b;
    vx[31] = a;
    vx[32] = x1;
    vx[33] = y1;
    vx[34] = u1;
    vx[35] = v1;
    vx[36] = r;
    vx[37] = g;
    vx[38] = b;
    vx[39] = a;
    vx[40] = x0;
    vx[41] = y1;
    vx[42] = u0;
    vx[43] = v1;
    vx[44] = r;
    vx[45] = g;
    vx[46] = b;
    vx[47] = a;

    qi++;
  }

  free(tiles);
  free(keys);

  // Slow-render breakdown: separates libass's own cost (rasterize/blur/shape)
  // from this function's packing + memcpy, so device logs attribute the time.
  const long long tEnd = nowMs();
  if (tEnd - t0 > 40) {
    __android_log_print(
        ANDROID_LOG_WARN, LOG_TAG,
        "slow render t=%lldms: total=%lldms ass=%lldms pack+copy=%lldms images=%d srcPx=%lldk "
        "atlas=%dx%d pages=%d quads=%d",
        (long long)time, tEnd - t0, tAss - t0, tEnd - tAss, n, srcPixels / 1000, atlasMaxW, atlasMaxH, pageCount, qi);
  }

  // atlasWidth is the full row stride (GLES2 can't upload with stride ≠ width);
  // pageHeights/pageQuadCounts describe the per-page upload + draw ranges.
  return writeAtlasHeader(
      env, headerBuf, atlasMaxW, qi, changed, truncated, requiredPages, 1, pageCount, pageHeights, pageQuads);
}

// --- AssFrameTimestamps (EGL_ANDROID_get_frame_timestamps) ---
//
// Measures the overlay buffer's ACTUAL on-screen present time so subtitle
// frame-perfection can be checked against the video frame's release time as
// ground truth, instead of the queue time (eglSwapBuffers return) the swap loop
// otherwise sees. The Java EGLExt only exposes eglPresentationTimeANDROID, so the
// frame-timestamp entry points are resolved here via eglGetProcAddress.
//
// All functions run on the GL thread with the pipeline's EGL context current.

// Older NDK eglext.h may predate the extension; fall back to the spec values.
#ifndef EGL_TIMESTAMPS_ANDROID
#define EGL_TIMESTAMPS_ANDROID 0x3430
#endif
#ifndef EGL_COMPOSITION_LATCH_TIME_ANDROID
#define EGL_COMPOSITION_LATCH_TIME_ANDROID 0x3436
#endif
#ifndef EGL_FIRST_COMPOSITION_START_TIME_ANDROID
#define EGL_FIRST_COMPOSITION_START_TIME_ANDROID 0x3437
#endif
#ifndef EGL_DISPLAY_PRESENT_TIME_ANDROID
#define EGL_DISPLAY_PRESENT_TIME_ANDROID 0x343A
#endif
#ifndef EGL_TIMESTAMP_INVALID_ANDROID
#define EGL_TIMESTAMP_INVALID_ANDROID (-1)
#endif
#ifndef EGL_TIMESTAMP_PENDING_ANDROID
#define EGL_TIMESTAMP_PENDING_ANDROID (-2)
#endif
#ifndef EGL_ANDROID_get_frame_timestamps
typedef khronos_stime_nanoseconds_t EGLnsecsANDROID;
typedef EGLBoolean(EGLAPIENTRYP PFNEGLGETNEXTFRAMEIDANDROIDPROC)(EGLDisplay, EGLSurface, EGLuint64KHR*);
typedef EGLBoolean(EGLAPIENTRYP PFNEGLGETFRAMETIMESTAMPSANDROIDPROC)(
    EGLDisplay, EGLSurface, EGLuint64KHR, EGLint, const EGLint*, EGLnsecsANDROID*);
typedef EGLBoolean(EGLAPIENTRYP PFNEGLGETFRAMETIMESTAMPSUPPORTEDANDROIDPROC)(EGLDisplay, EGLSurface, EGLint);
#endif

// nativeInit status: success codes are the chosen timestamp source (≥ 0); the
// actual display present time on code 0, and SurfaceFlinger composition timestamps
// (a near-constant ~1-vsync earlier than scanout) on codes 1/2 — a constant bias
// that doesn't hide the inter-layer jitter / multi-vsync outliers we look for.
// Negative codes are failure reasons surfaced to the stats path for diagnosis.
#define FT_SRC_PRESENT 0
#define FT_SRC_COMPOSITION_START 1
#define FT_SRC_COMPOSITION_LATCH 2
#define FT_ERR_NO_SURFACE (-1)
#define FT_ERR_NO_EXTENSION (-2)
#define FT_ERR_NO_PROC (-3)
#define FT_ERR_UNSUPPORTED (-4)
#define FT_ERR_ENABLE_FAILED (-5)

static PFNEGLGETNEXTFRAMEIDANDROIDPROC pEglGetNextFrameId = NULL;
static PFNEGLGETFRAMETIMESTAMPSANDROIDPROC pEglGetFrameTimestamps = NULL;
static PFNEGLGETFRAMETIMESTAMPSUPPORTEDANDROIDPROC pEglGetFrameTimestampSupported = NULL;
static EGLDisplay gFtDisplay = EGL_NO_DISPLAY;
static EGLSurface gFtSurface = EGL_NO_SURFACE;
static EGLint gFtPresentName = EGL_DISPLAY_PRESENT_TIME_ANDROID;

// Probes the extension on the currently-current draw surface and enables capture.
// Re-resolves the display/surface each call so surface recreation is handled.
// Returns one of the FT_* codes above.
JNIEXPORT jint JNICALL Java_com_edde746_plezy_libass_AssFrameTimestamps_nativeInit(JNIEnv* env, jclass clazz) {
  gFtSurface = EGL_NO_SURFACE;
  EGLDisplay dpy = eglGetCurrentDisplay();
  EGLSurface surf = eglGetCurrentSurface(EGL_DRAW);
  if (dpy == EGL_NO_DISPLAY || surf == EGL_NO_SURFACE) return FT_ERR_NO_SURFACE;

  const char* exts = eglQueryString(dpy, EGL_EXTENSIONS);
  if (exts == NULL || strstr(exts, "EGL_ANDROID_get_frame_timestamps") == NULL) {
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "frame-timestamps: extension not present");
    return FT_ERR_NO_EXTENSION;
  }
  if (pEglGetNextFrameId == NULL) {
    pEglGetNextFrameId = (PFNEGLGETNEXTFRAMEIDANDROIDPROC)eglGetProcAddress("eglGetNextFrameIdANDROID");
    pEglGetFrameTimestamps = (PFNEGLGETFRAMETIMESTAMPSANDROIDPROC)eglGetProcAddress("eglGetFrameTimestampsANDROID");
    pEglGetFrameTimestampSupported =
        (PFNEGLGETFRAMETIMESTAMPSUPPORTEDANDROIDPROC)eglGetProcAddress("eglGetFrameTimestampSupportedANDROID");
  }
  if (pEglGetNextFrameId == NULL || pEglGetFrameTimestamps == NULL || pEglGetFrameTimestampSupported == NULL) {
    __android_log_print(ANDROID_LOG_WARN, LOG_TAG, "frame-timestamps: entry points unresolved");
    return FT_ERR_NO_PROC;
  }

  // Prefer true display present; many TV HWCs (e.g. Amlogic) don't report present
  // fences but do report SurfaceFlinger composition timestamps. Take the first
  // supported — composition timing still pins the swap to a vsync for A-vs-B.
  jint status;
  if (pEglGetFrameTimestampSupported(dpy, surf, EGL_DISPLAY_PRESENT_TIME_ANDROID)) {
    gFtPresentName = EGL_DISPLAY_PRESENT_TIME_ANDROID;
    status = FT_SRC_PRESENT;
  } else if (pEglGetFrameTimestampSupported(dpy, surf, EGL_FIRST_COMPOSITION_START_TIME_ANDROID)) {
    gFtPresentName = EGL_FIRST_COMPOSITION_START_TIME_ANDROID;
    status = FT_SRC_COMPOSITION_START;
  } else if (pEglGetFrameTimestampSupported(dpy, surf, EGL_COMPOSITION_LATCH_TIME_ANDROID)) {
    gFtPresentName = EGL_COMPOSITION_LATCH_TIME_ANDROID;
    status = FT_SRC_COMPOSITION_LATCH;
  } else {
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "frame-timestamps: no supported timestamp name");
    return FT_ERR_UNSUPPORTED;
  }

  if (!eglSurfaceAttrib(dpy, surf, EGL_TIMESTAMPS_ANDROID, EGL_TRUE)) {
    __android_log_print(ANDROID_LOG_WARN, LOG_TAG, "frame-timestamps: enable failed 0x%x", eglGetError());
    return FT_ERR_ENABLE_FAILED;
  }
  gFtDisplay = dpy;
  gFtSurface = surf;
  __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "frame-timestamps: enabled (source=%d)", status);
  return status;
}

// Frame id the next eglSwapBuffers will produce; call immediately before it.
JNIEXPORT jlong JNICALL
Java_com_edde746_plezy_libass_AssFrameTimestamps_nativeGetNextFrameId(JNIEnv* env, jclass clazz) {
  if (pEglGetNextFrameId == NULL || gFtSurface == EGL_NO_SURFACE) return -1;
  EGLuint64KHR id = 0;
  if (!pEglGetNextFrameId(gFtDisplay, gFtSurface, &id)) return -1;
  return (jlong)id;
}

// Present (or composition) time for frameId (System.nanoTime() domain), or the
// PENDING(-2)/INVALID(-1) sentinels. Reported a few frames after the swap.
JNIEXPORT jlong JNICALL
Java_com_edde746_plezy_libass_AssFrameTimestamps_nativeGetDisplayPresentTime(JNIEnv* env, jclass clazz, jlong frameId) {
  if (pEglGetFrameTimestamps == NULL || gFtSurface == EGL_NO_SURFACE) return EGL_TIMESTAMP_INVALID_ANDROID;
  const EGLint names[1] = {gFtPresentName};
  EGLnsecsANDROID values[1] = {0};
  if (!pEglGetFrameTimestamps(gFtDisplay, gFtSurface, (EGLuint64KHR)frameId, 1, names, values)) {
    // Frame id evicted from SurfaceFlinger's history, or bad surface.
    return EGL_TIMESTAMP_INVALID_ANDROID;
  }
  return (jlong)values[0];
}
