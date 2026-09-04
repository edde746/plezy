#include <jni.h>
#include <mpv/client.h>

#include "globals.h"
#include "jni_utils.h"
#include "log.h"

extern "C" {
jni_func(void, nativeAttachSurface, jobject surface_);
jni_func(void, nativeDetachSurface);
jni_func(void, nativeAttachOsdSurface, jobject surface_);
jni_func(void, nativeDetachOsdSurface);
};

static jobject surface;

jni_func(void, nativeAttachSurface, jobject surface_) {
  CHECK_MPV_INIT();

  surface = env->NewGlobalRef(surface_);
  if (!surface) {
    die("invalid surface provided");
    return;
  }
  int64_t wid = reinterpret_cast<intptr_t>(surface);
  int result = mpv_set_option(g_mpv, "wid", MPV_FORMAT_INT64, &wid);
  if (result < 0) ALOGE("mpv_set_option(wid) returned error %s", mpv_error_string(result));
}

jni_func(void, nativeDetachSurface) {
  CHECK_MPV_INIT();

  int64_t wid = 0;
  int result = mpv_set_option(g_mpv, "wid", MPV_FORMAT_INT64, &wid);
  if (result < 0) ALOGE("mpv_set_option(wid) returned error %s", mpv_error_string(result));

  env->DeleteGlobalRef(surface);
  surface = NULL;
}

static jobject osd_surface;

// The OSD plane of vo=mediacodec. Same lifetime rules as the video surface:
// the global ref must outlive the VO, so detach only after vo has been unset.
jni_func(void, nativeAttachOsdSurface, jobject surface_) {
  CHECK_MPV_INIT();

  osd_surface = env->NewGlobalRef(surface_);
  if (!osd_surface) {
    die("invalid osd surface provided");
    return;
  }
  int64_t wid = reinterpret_cast<intptr_t>(osd_surface);
  int result = mpv_set_option(g_mpv, "vo-mediacodec-osd-surface", MPV_FORMAT_INT64, &wid);
  if (result < 0) ALOGE("mpv_set_option(vo-mediacodec-osd-surface) returned error %s", mpv_error_string(result));
}

jni_func(void, nativeDetachOsdSurface) {
  CHECK_MPV_INIT();
  if (!osd_surface) return;

  int64_t wid = 0;
  int result = mpv_set_option(g_mpv, "vo-mediacodec-osd-surface", MPV_FORMAT_INT64, &wid);
  if (result < 0) ALOGE("mpv_set_option(vo-mediacodec-osd-surface) returned error %s", mpv_error_string(result));

  env->DeleteGlobalRef(osd_surface);
  osd_surface = NULL;
}

void render_cleanup(JNIEnv* env) {
  if (surface) {
    env->DeleteGlobalRef(surface);
    surface = NULL;
  }
  if (osd_surface) {
    env->DeleteGlobalRef(osd_surface);
    osd_surface = NULL;
  }
}
