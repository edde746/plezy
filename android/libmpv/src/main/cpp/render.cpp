#include <jni.h>
#include <mpv/client.h>

#include "globals.h"
#include "jni_utils.h"
#include "log.h"

extern "C" {
jni_func(void, nativeAttachSurface, jlong session, jobject surface_);
jni_func(void, nativeDetachSurface, jlong session);
jni_func(void, nativeAttachOsdSurface, jlong session, jobject surface_);
jni_func(void, nativeDetachOsdSurface, jlong session);
};

static jobject surface;

jni_func(void, nativeAttachSurface, jlong session, jobject surface_) {
  SessionGuard guard(session);
  if (!guard.mpv) return;

  surface = env->NewGlobalRef(surface_);
  if (!surface) {
    die("invalid surface provided");
    return;
  }
  int64_t wid = reinterpret_cast<intptr_t>(surface);
  int result = mpv_set_option(guard.mpv, "wid", MPV_FORMAT_INT64, &wid);
  if (result < 0) ALOGE("mpv_set_option(wid) returned error %s", mpv_error_string(result));
}

jni_func(void, nativeDetachSurface, jlong session) {
  SessionGuard guard(session);
  if (!guard.mpv) return;

  int64_t wid = 0;
  int result = mpv_set_option(guard.mpv, "wid", MPV_FORMAT_INT64, &wid);
  if (result < 0) ALOGE("mpv_set_option(wid) returned error %s", mpv_error_string(result));

  env->DeleteGlobalRef(surface);
  surface = NULL;
}

static jobject osd_surface;

// The OSD plane of vo=mediacodec. Same lifetime rules as the video surface:
// the global ref must outlive the VO, so detach only after vo has been unset.
jni_func(void, nativeAttachOsdSurface, jlong session, jobject surface_) {
  SessionGuard guard(session);
  if (!guard.mpv) return;

  osd_surface = env->NewGlobalRef(surface_);
  if (!osd_surface) {
    die("invalid osd surface provided");
    return;
  }
  int64_t wid = reinterpret_cast<intptr_t>(osd_surface);
  int result = mpv_set_option(guard.mpv, "vo-mediacodec-osd-surface", MPV_FORMAT_INT64, &wid);
  if (result < 0) ALOGE("mpv_set_option(vo-mediacodec-osd-surface) returned error %s", mpv_error_string(result));
}

jni_func(void, nativeDetachOsdSurface, jlong session) {
  SessionGuard guard(session);
  if (!guard.mpv || !osd_surface) return;

  int64_t wid = 0;
  int result = mpv_set_option(guard.mpv, "vo-mediacodec-osd-surface", MPV_FORMAT_INT64, &wid);
  if (result < 0) ALOGE("mpv_set_option(vo-mediacodec-osd-surface) returned error %s", mpv_error_string(result));

  env->DeleteGlobalRef(osd_surface);
  osd_surface = NULL;
}

// Caller holds the lifecycle write lock; the surfaces belong to the session
// being retired and are released with it.
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
