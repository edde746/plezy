#include <jni.h>
#include <mpv/client.h>

#include <new>
#include <vector>

#include "globals.h"
#include "jni_utils.h"
#include "log.h"

extern "C" {
jni_func(jint, nativeAttachSurfaces, jlong session, jobject surface_, jobject osd_surface_);
};

// Admission (S) precedes this mutex. Teardown drains S before cleanup and
// never takes this mutex, so a waiting handoff cannot outlive its mpv handle.
static pthread_mutex_t surface_lock = PTHREAD_MUTEX_INITIALIZER;
class SurfaceGuard {
 public:
  SurfaceGuard() { pthread_mutex_lock(&surface_lock); }
  ~SurfaceGuard() { pthread_mutex_unlock(&surface_lock); }
  SurfaceGuard(const SurfaceGuard&) = delete;
  SurfaceGuard& operator=(const SurfaceGuard&) = delete;
};
static jobject surface;
static jobject osd_surface;
// A failed wid update can leave an OSD option/consumer using a staged ref.
// Even a successful option rollback cannot retire a consumer created between
// the two writes. Release these only after a successful wid rebuild or destroy.
static std::vector<jobject> pending_osd_surfaces;

jni_func(jint, nativeAttachSurfaces, jlong session, jobject surface_, jobject osd_surface_) {
  SessionGuard guard(session);
  if (!guard.mpv) return MPV_ERROR_UNINITIALIZED;
  if (!surface_) return MPV_ERROR_INVALID_PARAMETER;
  SurfaceGuard lock;

  if (osd_surface_) {
    try {
      pending_osd_surfaces.reserve(pending_osd_surfaces.size() + 1);
    } catch (const std::bad_alloc&) {
      return MPV_ERROR_NOMEM;
    }
  }
  jobject next_surface = env->NewGlobalRef(surface_);
  if (!next_surface) return MPV_ERROR_NOMEM;
  jobject next_osd = osd_surface_ ? env->NewGlobalRef(osd_surface_) : nullptr;
  if (osd_surface_ && !next_osd) {
    env->DeleteGlobalRef(next_surface);
    return MPV_ERROR_NOMEM;
  }

  int64_t osd_wid = reinterpret_cast<intptr_t>(next_osd);
  int result = mpv_set_option(guard.mpv, "vo-mediacodec-osd-surface", MPV_FORMAT_INT64, &osd_wid);
  if (result < 0) {
    env->DeleteGlobalRef(next_surface);
    if (next_osd) env->DeleteGlobalRef(next_osd);
    return result;
  }
  if (next_osd) pending_osd_surfaces.push_back(next_osd);

  // wid has UPDATE_VO: mpv_set_option synchronously tears down the old VO and
  // decoder before rebuilding with both options. A fresh video global ref also
  // changes wid when only the Java OSD Surface changed (equal values are ignored).
  int64_t wid = reinterpret_cast<intptr_t>(next_surface);
  result = mpv_set_option(guard.mpv, "wid", MPV_FORMAT_INT64, &wid);
  if (result < 0) {
    osd_wid = reinterpret_cast<intptr_t>(osd_surface);
    const int rollback = mpv_set_option(guard.mpv, "vo-mediacodec-osd-surface", MPV_FORMAT_INT64, &osd_wid);
    if (rollback < 0) ALOGE("OSD surface rollback failed: %s", mpv_error_string(rollback));
    env->DeleteGlobalRef(next_surface);
    return result;
  }

  if (next_osd) pending_osd_surfaces.pop_back();
  if (surface) env->DeleteGlobalRef(surface);
  if (osd_surface) env->DeleteGlobalRef(osd_surface);
  for (jobject pending : pending_osd_surfaces) env->DeleteGlobalRef(pending);
  pending_osd_surfaces.clear();
  surface = next_surface;
  osd_surface = next_osd;
  return 0;
}

// Caller holds L after revoking admission, draining JNI readers, joining the
// event thread and terminating mpv. S is not held. L prevents a successor from
// publishing new surfaces until these retiring references have been released.
void render_cleanup(JNIEnv* env) {
  if (surface) {
    env->DeleteGlobalRef(surface);
    surface = nullptr;
  }
  if (osd_surface) {
    env->DeleteGlobalRef(osd_surface);
    osd_surface = nullptr;
  }
  for (jobject pending : pending_osd_surfaces) env->DeleteGlobalRef(pending);
  pending_osd_surfaces.clear();
}
