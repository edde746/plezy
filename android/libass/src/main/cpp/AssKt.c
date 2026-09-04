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

#include "AssPack.h"
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

JNIEXPORT void JNICALL Java_com_edde746_plezy_libass_Ass_nativeAssClearFonts(JNIEnv* env, jclass clazz, jlong ass) {
  if (ass) {
    ass_clear_fonts((ASS_Library*)ass);
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

// Packing/composite policy lives in AssPack.c (pure C, desktop-testable); this
// file owns the JNI boundary, buffer plumbing and logging.

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
//   [7+2*MAX]                 = mode (ASS_PACK_MODE_ATLAS | ASS_PACK_MODE_COMPOSITE)
#define ASS_HEADER_INTS (7 + 2 * ASS_PACK_MAX_PAGES + 1)

static jint writeAtlasHeader(
    JNIEnv* env, jintArray headerBuf, int atlasWidth, int quadCount, int changed, int truncated, int requiredPages,
    int hasOutput, int pageCount, const int* pageHeights, const int* pageQuads, int mode) {
  int hdr[ASS_HEADER_INTS];
  memset(hdr, 0, sizeof(hdr));
  hdr[0] = atlasWidth;
  hdr[1] = quadCount;
  hdr[2] = changed;
  hdr[3] = truncated;
  hdr[4] = requiredPages;
  hdr[5] = hasOutput;
  hdr[6] = pageCount;
  for (int i = 0; i < pageCount && i < ASS_PACK_MAX_PAGES; i++) {
    hdr[7 + i] = pageHeights ? pageHeights[i] : 0;
    hdr[7 + ASS_PACK_MAX_PAGES + i] = pageQuads ? pageQuads[i] : 0;
  }
  hdr[7 + 2 * ASS_PACK_MAX_PAGES] = mode;
  (*env)->SetIntArrayRegion(env, headerBuf, 0, ASS_HEADER_INTS, hdr);
  return 1;
}

// Renders a frame into the provided atlas + vertex direct ByteBuffers.
//
// - In the common ATLAS mode, atlasBuf holds one or more vertically-stacked ALPHA_8
//   *pages*, each atlasMaxW × atlasMaxH (row stride atlasMaxW); page p starts at byte
//   offset p*atlasMaxW*atlasMaxH. The buffer's capacity bounds how many pages this
//   render may fill; AssAtlasFrame reports pageHeights (rows worth uploading per page)
//   and requiredPages. UVs are page-local, normalized against atlasMaxW × atlasMaxH.
// - In COMPOSITE mode (frames whose tiles can never fit ASS_PACK_MAX_PAGES pages or
//   the vertex budget) atlasBuf instead starts with one premultiplied RGBA rect of
//   atlasWidth × pageHeights[0] pixels, drawn as the single emitted quad (UVs 0..1).
// - vertexBuf holds a per-quad vertex stream (6 vertices × (2 pos + 2 uv + 4 color)
//   floats = 48 floats = 192 bytes per quad). Must match BYTES_PER_QUAD/VERTEX in
//   AssSubtitleAtlasPipeline.kt. Vertices are emitted in libass's painter order.
//
// Never drops content for size: when the frame needs more capacity than the buffer
// holds (requiredPages > pageHeights.size) the caller grows the buffer and re-renders;
// frames too dense for the paged atlas flatten into the RGBA composite (see AssPack.c).
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
    return writeAtlasHeader(env, headerBuf, 0, 0, changed, 0, 1, hasOutput, 1, NULL, NULL, ASS_PACK_MODE_ATLAS);
  }

  if (image == NULL) {
    if (tAss - t0 > 40) {
      __android_log_print(
          ANDROID_LOG_WARN, LOG_TAG, "slow render t=%lldms: ass=%lldms (changed=%d, no output)", (long long)time,
          tAss - t0, changed);
    }
    return writeAtlasHeader(env, headerBuf, 0, 0, changed, 0, 1, 0, 1, NULL, NULL, ASS_PACK_MODE_ATLAS);
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

  AssPackResult pack;
  if (!ass_pack_frame(image, atlasPixels, (size_t)atlasCap, atlasMaxW, atlasMaxH, vertices, (size_t)vertexCap, &pack)) {
    return 0;
  }

  // Warn only for genuinely-unrecoverable loss. A frame that needs more capacity than
  // the buffer currently holds is recoverable: the caller grows the buffer and
  // re-renders, so the first (discarded) render's truncated > 0 is a false alarm, not
  // data loss. With the composite fallback, unrecoverable truncation should be
  // unreachable for real content.
  const int maxQuads = (int)(vertexCap / 192);
  const int recoverableGrow =
      pack.requiredPages <= ASS_PACK_MAX_PAGES && (pack.mode == ASS_PACK_MODE_COMPOSITE || pack.totalTiles <= maxQuads);
  if (pack.truncated > 0 && !recoverableGrow && (truncationLogCounter++ & 63) == 0) {
    __android_log_print(
        ANDROID_LOG_WARN, LOG_TAG, "atlas truncation: %d of %d tiles dropped (atlas %dx%d, need %d pages have %lld)",
        pack.truncated, pack.totalTiles, atlasMaxW, atlasMaxH, pack.requiredPages,
        (long long)(atlasCap / ((jlong)atlasMaxW * atlasMaxH)));
  }

  // Slow-render breakdown: separates libass's own cost (rasterize/blur/shape)
  // from this function's packing/compositing, so device logs attribute the time.
  const long long tEnd = nowMs();
  if (tEnd - t0 > 40) {
    __android_log_print(
        ANDROID_LOG_WARN, LOG_TAG,
        "slow render t=%lldms: total=%lldms ass=%lldms pack+copy=%lldms images=%d srcPx=%lldk "
        "atlas=%dx%d pages=%d quads=%d mode=%d",
        (long long)time, tEnd - t0, tAss - t0, tEnd - tAss, pack.totalTiles, pack.srcPixels / 1000, atlasMaxW,
        atlasMaxH, pack.pageCount, pack.quadCount, pack.mode);
  }

  // ATLAS: atlasWidth is the full row stride (GLES2 can't upload with stride ≠ width)
  // and pageHeights/pageQuadCounts describe the per-page upload + draw ranges.
  // COMPOSITE: atlasWidth × pageHeights[0] are the RGBA rect dims for the one quad.
  return writeAtlasHeader(
      env, headerBuf, pack.atlasWidth, pack.quadCount, changed, pack.truncated, pack.requiredPages,
      pack.totalTiles > 0 ? 1 : 0, pack.pageCount, pack.pageHeights, pack.pageQuads, pack.mode);
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
