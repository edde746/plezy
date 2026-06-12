// JNI bindings for libass. Exports use standard Java_<package>_<Class>_<method>
// naming so no RegisterNatives/JNI_OnLoad registration is needed.
#include <android/log.h>
#include <jni.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
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
  return (jlong)ass_new_track((ASS_Library*)ass);
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

JNIEXPORT jlong JNICALL
Java_com_edde746_plezy_libass_AssRender_nativeAssRenderInit(JNIEnv* env, jclass clazz, jlong ass) {
  ASS_Renderer* assRenderer = ass_renderer_init((ASS_Library*)ass);
  ass_set_fonts(assRenderer, NULL, "sans-serif", ASS_FONTPROVIDER_FONTCONFIG, NULL, 1);
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

// (image, original-list index) pair so packing can run in height-sorted order
// while slots stay keyed by list position (= blend order) for pass 2.
typedef struct {
  ASS_Image* img;
  int idx;
} PackItem;

static int comparePackItemsByHeightDesc(const void* a, const void* b) {
  const PackItem* ia = (const PackItem*)a;
  const PackItem* ib = (const PackItem*)b;
  return ib->img->h - ia->img->h;
}

// Throttle for truncation warnings (shared across renderers; logging only).
static int truncationLogCounter = 0;

// Renders a frame into the provided atlas + vertex direct ByteBuffers.
//
// - atlasBuf holds packed ALPHA_8 pixels with row stride atlasMaxW. Only the first
//   atlasHeight rows are written; the caller uploads that region to a texture
//   allocated once at atlasMaxW × atlasMaxH.
// - vertexBuf holds a per-quad vertex stream (6 vertices × (2 pos + 2 uv + 4 color)
//   floats = 48 floats = 192 bytes per quad). Must match BYTES_PER_QUAD/VERTEX in
//   AssSubtitleAtlasPipeline.kt. Ready for a single glDrawArrays(GL_TRIANGLES, 0, N * 6).
// - UVs are normalized against atlasMaxW × atlasMaxH (the allocated texture dims),
//   not the packed region, so the texture never needs reallocation.
// - Images are packed in height-sorted rows (minimizes packed height) but vertices
//   are emitted in original list order — the list order is libass's painter order.
//
// Never fails on content size: images that don't fit the remaining atlas/vertex
// capacity are dropped and counted in AssAtlasFrame.truncated, so a heavy frame
// degrades instead of going stale. Returns NULL only for missing buffers/handles.
// On changed == 0, returns (0, 0, 0, changed, 0) without touching the buffers —
// caller reuses the atlas texture already on the GPU.
JNIEXPORT jobject JNICALL Java_com_edde746_plezy_libass_AssRender_nativeAssRenderFrameAtlas(
    JNIEnv* env, jclass clazz, jlong render, jlong track, jlong time, jobject atlasBuf, jint atlasMaxW,
    jint atlasMaxH, jobject vertexBuf) {
  if (!render || !track || !atlasBuf || !vertexBuf || atlasMaxW <= 0 || atlasMaxH <= 0) return NULL;

  jclass atlasFrameClass = (*env)->FindClass(env, "com/edde746/plezy/libass/AssAtlasFrame");
  if (!atlasFrameClass) return NULL;
  jmethodID ctor = (*env)->GetMethodID(env, atlasFrameClass, "<init>", "(IIIII)V");
  if (!ctor) return NULL;

  const long long t0 = nowMs();
  int changed;
  ASS_Image* image = ass_render_frame((ASS_Renderer*)render, (ASS_Track*)track, time, &changed);
  const long long tAss = nowMs();

  if (changed == 0 || image == NULL) {
    if (tAss - t0 > 40) {
      __android_log_print(
          ANDROID_LOG_WARN, LOG_TAG, "slow render t=%lldms: ass=%lldms (changed=%d, no output)", (long long)time,
          tAss - t0, changed);
    }
    return (*env)->NewObject(env, atlasFrameClass, ctor, 0, 0, 0, changed, 0);
  }

  uint8_t* atlasPixels = (uint8_t*)(*env)->GetDirectBufferAddress(env, atlasBuf);
  jlong atlasCap = (*env)->GetDirectBufferCapacity(env, atlasBuf);
  float* vertices = (float*)(*env)->GetDirectBufferAddress(env, vertexBuf);
  jlong vertexCap = (*env)->GetDirectBufferCapacity(env, vertexBuf);
  if (!atlasPixels || !vertices) return NULL;
  if ((jlong)atlasMaxW * atlasMaxH > atlasCap) {
    __android_log_print(
        ANDROID_LOG_ERROR, LOG_TAG, "atlas buffer smaller than %dx%d (capacity %lld bytes)", atlasMaxW, atlasMaxH,
        (long long)atlasCap);
    return NULL;
  }
  // 48 floats per quad × 4 bytes = 192 bytes/quad
  const int maxQuads = (int)(vertexCap / 192);

  int total = 0;
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w > 0 && img->h > 0) total++;
  }
  if (total == 0) {
    return (*env)->NewObject(env, atlasFrameClass, ctor, 0, 0, 0, changed, 0);
  }

  // Pass 1: assign packing slots in height-sorted order so mixed-size frames pack
  // tight rows. slotX/slotY are keyed by the image's position in the original
  // list; -1 marks images dropped for capacity.
  PackItem* items = (PackItem*)malloc(sizeof(PackItem) * (size_t)total);
  int* slotX = (int*)malloc(sizeof(int) * (size_t)total);
  int* slotY = (int*)malloc(sizeof(int) * (size_t)total);
  if (!items || !slotX || !slotY) {
    free(items);
    free(slotX);
    free(slotY);
    return NULL;
  }
  int n = 0;
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w > 0 && img->h > 0) {
      items[n].img = img;
      items[n].idx = n;
      n++;
    }
  }
  qsort(items, (size_t)n, sizeof(PackItem), comparePackItemsByHeightDesc);

  int cursorX = 0, cursorY = 0, rowH = 0;
  int truncated = 0;
  int packedH = 0;
  int accepted = 0;
  long long srcPixels = 0;
  for (int i = 0; i < n; i++) {
    ASS_Image* img = items[i].img;
    srcPixels += (long long)img->w * img->h;
    int sx = -1, sy = -1;
    if (img->w <= atlasMaxW && accepted < maxQuads) {
      int cx = cursorX, cy = cursorY, rh = rowH;
      if (cx + img->w > atlasMaxW) {
        cy += rh;
        cx = 0;
        rh = 0;
      }
      if (cy + img->h <= atlasMaxH) {
        sx = cx;
        sy = cy;
        cursorX = cx + img->w;
        cursorY = cy;
        rowH = (img->h > rh) ? img->h : rh;
        if (cy + img->h > packedH) packedH = cy + img->h;
        accepted++;
      }
    }
    if (sx < 0) truncated++;
    slotX[items[i].idx] = sx;
    slotY[items[i].idx] = sy;
  }

  if (truncated > 0 && (truncationLogCounter++ & 63) == 0) {
    __android_log_print(
        ANDROID_LOG_WARN, LOG_TAG, "atlas truncation: %d of %d images dropped (atlas %dx%d, %d quads max)",
        truncated, n, atlasMaxW, atlasMaxH, maxQuads);
  }
  if (accepted == 0) {
    free(items);
    free(slotX);
    free(slotY);
    return (*env)->NewObject(env, atlasFrameClass, ctor, 0, 0, 0, changed, truncated);
  }

  memset(atlasPixels, 0, (size_t)atlasMaxW * packedH);

  // Pass 2: walk the original list (= libass's painter/blend order), copying each
  // accepted image into its assigned slot and emitting its quad.
  int qi = 0;
  int k = 0;
  for (ASS_Image* img = image; img != NULL; img = img->next) {
    if (img->w <= 0 || img->h <= 0) continue;
    const int px = slotX[k];
    const int py = slotY[k];
    k++;
    if (px < 0) continue;

    for (int y = 0; y < img->h; y++) {
      uint8_t* dst = atlasPixels + (size_t)(py + y) * atlasMaxW + px;
      const uint8_t* src = img->bitmap + (size_t)y * img->stride;
      memcpy(dst, src, (size_t)img->w);
    }

    const float x0 = (float)img->dst_x;
    const float y0 = (float)img->dst_y;
    const float x1 = x0 + (float)img->w;
    const float y1 = y0 + (float)img->h;
    const float u0 = (float)px / (float)atlasMaxW;
    const float v0 = (float)py / (float)atlasMaxH;
    const float u1 = (float)(px + img->w) / (float)atlasMaxW;
    const float v1 = (float)(py + img->h) / (float)atlasMaxH;
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

  free(items);
  free(slotX);
  free(slotY);

  // Slow-render breakdown: separates libass's own cost (rasterize/blur/shape)
  // from this function's packing + memcpy, so device logs attribute the time.
  const long long tEnd = nowMs();
  if (tEnd - t0 > 40) {
    __android_log_print(
        ANDROID_LOG_WARN, LOG_TAG,
        "slow render t=%lldms: total=%lldms ass=%lldms pack+copy=%lldms images=%d srcPx=%lldk atlas=%dx%d quads=%d",
        (long long)time, tEnd - t0, tAss - t0, tEnd - tAss, n, srcPixels / 1000, atlasMaxW, packedH, qi);
  }

  // atlasWidth is the full row stride (GLES2 can't upload with stride ≠ width);
  // atlasHeight is the packed height — the only rows worth uploading.
  return (*env)->NewObject(env, atlasFrameClass, ctor, atlasMaxW, packedH, qi, changed, truncated);
}
