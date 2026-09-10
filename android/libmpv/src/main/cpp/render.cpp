#include <jni.h>
#include <mpv/client.h>

#include <cstdint>
#include <new>
#include <string>
#include <vector>

#include "jni_utils.h"
#include "log.h"
#include "session.h"

extern "C" {
jni_func(
    jint, nativeAttachSurfaces, jlong session, jobject surface_, jobject osd_surface_, jlong video_generation_,
    jlong osd_generation_, jstring vo_);
};

// Admission precedes this mutex, and it belongs to the session whose Surfaces
// it guards. Teardown drains admission before cleanup and never takes this
// mutex, so a waiting handoff cannot outlive its mpv handle.
class SurfaceGuard {
 public:
  explicit SurfaceGuard(Session& session) : session(session) { pthread_mutex_lock(&session.surface_lock); }
  ~SurfaceGuard() { pthread_mutex_unlock(&session.surface_lock); }
  SurfaceGuard(const SurfaceGuard&) = delete;
  SurfaceGuard& operator=(const SurfaceGuard&) = delete;

 private:
  Session& session;
};

jni_func(
    jint, nativeAttachSurfaces, jlong session, jobject surface_, jobject osd_surface_, jlong video_generation_,
    jlong osd_generation_, jstring vo_) {
  SessionGuard guard(session);
  if (!guard.mpv) return MPV_ERROR_UNINITIALIZED;
  if (!surface_) return MPV_ERROR_INVALID_PARAMETER;
  Session& s = *guard.session;
  SurfaceGuard lock(s);

  // Java Surface objects can be reused for a new BufferQueue. Suppress writes
  // only when both object identity and the owner's lifecycle generation match.
  const bool same_video =
      s.surface && s.video_generation == video_generation_ && env->IsSameObject(s.surface, surface_);
  const bool same_osd =
      (!s.osd_surface && !osd_surface_) || (s.osd_surface && osd_surface_ && s.osd_generation == osd_generation_ &&
                                            env->IsSameObject(s.osd_surface, osd_surface_));
  std::string next_vo;
  try {
    next_vo = java_string_to_utf8(env, vo_);
  } catch (const std::bad_alloc&) {
    return MPV_ERROR_NOMEM;
  }
  if (env->ExceptionCheck()) return MPV_ERROR_NOMEM;
  bool change_vo = false;
  if (!next_vo.empty()) {
    if (!same_video) return MPV_ERROR_INVALID_PARAMETER;
    char* current_vo = mpv_get_property_string(guard.mpv, "vo");
    change_vo = !current_vo || next_vo != current_vo;
    mpv_free(current_vo);
  }
  if (same_video && same_osd && !change_vo && s.pending_osd_surfaces.empty()) return 0;

  if (osd_surface_ && !same_osd) {
    try {
      s.pending_osd_surfaces.reserve(s.pending_osd_surfaces.size() + 1);
    } catch (const std::bad_alloc&) {
      return MPV_ERROR_NOMEM;
    }
  }
  jobject next_surface = same_video ? s.surface : env->NewGlobalRef(surface_);
  if (!next_surface) return MPV_ERROR_NOMEM;
  jobject next_osd = same_osd ? s.osd_surface : osd_surface_ ? env->NewGlobalRef(osd_surface_) : nullptr;
  if (osd_surface_ && !next_osd) {
    if (!same_video) env->DeleteGlobalRef(next_surface);
    return MPV_ERROR_NOMEM;
  }

  int64_t osd_wid = static_cast<int64_t>(reinterpret_cast<uintptr_t>(next_osd));
  int result = mpv_set_option(guard.mpv, "vo-mediacodec-osd-surface", MPV_FORMAT_INT64, &osd_wid);
  if (result < 0) {
    if (!same_video) env->DeleteGlobalRef(next_surface);
    if (!same_osd && next_osd) env->DeleteGlobalRef(next_osd);
    return result;
  }
  if (!same_osd && next_osd) s.pending_osd_surfaces.push_back(next_osd);

  // The OSD option now synchronously retires/rebinds only its own producer.
  // A video identity change still rebuilds once, never by parking wid at zero.
  if (change_vo) {
    result = mpv_set_option_string(guard.mpv, "vo", next_vo.c_str());
  } else if (!same_video) {
    int64_t wid = static_cast<int64_t>(reinterpret_cast<uintptr_t>(next_surface));
    result = mpv_set_option(guard.mpv, "wid", MPV_FORMAT_INT64, &wid);
  }
  if (result < 0) {
    osd_wid = static_cast<int64_t>(reinterpret_cast<uintptr_t>(s.osd_surface));
    const int rollback = mpv_set_option(guard.mpv, "vo-mediacodec-osd-surface", MPV_FORMAT_INT64, &osd_wid);
    if (rollback < 0) ALOGE("OSD surface rollback failed: %s", mpv_error_string(rollback));
    if (!same_video) env->DeleteGlobalRef(next_surface);
    return result;
  }

  if (!same_osd && next_osd) s.pending_osd_surfaces.pop_back();
  if (!same_video && s.surface) env->DeleteGlobalRef(s.surface);
  if (!same_osd && s.osd_surface) env->DeleteGlobalRef(s.osd_surface);
  for (jobject pending : s.pending_osd_surfaces) env->DeleteGlobalRef(pending);
  s.pending_osd_surfaces.clear();
  s.surface = next_surface;
  s.osd_surface = next_osd;
  s.video_generation = video_generation_;
  s.osd_generation = osd_generation_;
  return 0;
}

// Caller holds the session's lifecycle lock after revoking admission, draining
// JNI readers, joining the event thread and terminating mpv. Nothing else can
// reach this session by then: it was unpublished before any of that started.
void render_cleanup(JNIEnv* env, Session& session) {
  if (session.surface) {
    env->DeleteGlobalRef(session.surface);
    session.surface = nullptr;
  }
  if (session.osd_surface) {
    env->DeleteGlobalRef(session.osd_surface);
    session.osd_surface = nullptr;
  }
  for (jobject pending : session.pending_osd_surfaces) env->DeleteGlobalRef(pending);
  session.pending_osd_surfaces.clear();
}
