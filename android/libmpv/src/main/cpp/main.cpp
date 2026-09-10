#include <jni.h>
#include <mpv/client.h>
#include <pthread.h>

#include <clocale>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

extern "C" {
#include <libavcodec/jni.h>
}

#include "event.h"
#include "globals.h"
#include "jni_utils.h"
#include "log.h"
#include "session.h"

#define ARRAYLEN(a) (sizeof(a) / sizeof(a[0]))

void render_cleanup(JNIEnv* env, Session& session);

extern "C" {
jni_func(jlong, nativeCreate, jobject appctx);
jni_func(jint, nativeInit, jlong session);
jni_func(void, nativeDestroy, jlong session);

jni_func(jint, nativeSetLogLevel, jlong session, jstring level);

jni_func(jlong, nativeCommand, jlong session, jobjectArray jarray);
jni_func(void, nativeHookContinue, jlong session, jlong id);
};

JavaVM* g_vm;

static std::once_flag environment_once;

// Process-wide JNI and FFmpeg wiring, done exactly once. Sessions coexist - a
// wedged one outlives its successor - so this must never be rewritten
// underneath a session that can still call back, and the app context global
// ref is taken a single time rather than per create.
static void prepare_environment(JNIEnv* env, jobject appctx) {
  std::call_once(environment_once, [env, appctx] {
    setlocale(LC_NUMERIC, "C");

    if (!env->GetJavaVM(&g_vm) && g_vm) av_jni_set_java_vm(g_vm, NULL);

    jobject global_appctx = env->NewGlobalRef(appctx);
    if (global_appctx) av_jni_set_android_app_ctx(global_appctx, NULL);

    init_methods_cache(env);
  });
}

// bionic's mallopt is API 26+ and M_PURGE API 28+, above this module's minSdk,
// so the symbol is resolved weakly and simply skipped on an older device.
// Same shape as the Choreographer and EGL entry points elsewhere in the app.
#define MP_M_PURGE (-101)
extern "C" int mallopt(int, int) __attribute__((weak));

static void purge_native_arena() {
  if (mallopt) mallopt(MP_M_PURGE, 0);
}

jni_func(jlong, nativeCreate, jobject appctx) {
  prepare_environment(env, appctx);

  // No predecessor is consulted, waited for, or destroyed here: a session that
  // is still retiring - even one whose mpv_terminate_destroy never returns -
  // owns nothing this one needs.
  mpv_handle* mpv = mpv_create();
  if (!mpv) {
    die("context init failed");
    return 0;
  }

  mpv_request_log_messages(mpv, "warn");
  return (jlong)session_register(mpv)->id;
}

jni_func(jint, nativeInit, jlong session) {
  std::shared_ptr<Session> s = session_find((uint64_t)session);
  if (!s) return MPV_ERROR_UNINITIALIZED;

  pthread_mutex_lock(&s->lifecycle);
  // A destroy may have unpublished this session between the lookup and L.
  if (s->retired) {
    pthread_mutex_unlock(&s->lifecycle);
    return MPV_ERROR_UNINITIALIZED;
  }

  const int result = mpv_initialize(s->handle);
  if (result < 0) {
    ALOGE("mpv_initialize returned error %s", mpv_error_string(result));
    pthread_mutex_unlock(&s->lifecycle);
    return result;
  }

  // Per-file decode routing (Dolby Vision P5, H.264 High 10) has to land
  // before mpv creates the decoder; file-loaded is already too late for the
  // MediaCodec path. on_preloaded runs after the demuxer opened the file and
  // holds playback until Kotlin continues it (MpvPlayer.onHook).
  mpv_hook_add(s->handle, 0, "on_preloaded", 0);

  if (pthread_create(&s->event_thread, NULL, event_thread, s.get()) != 0) {
    die("thread create failed");
    pthread_mutex_unlock(&s->lifecycle);
    return MPV_ERROR_GENERIC;
  }
  s->event_thread_started = true;
  pthread_setname_np(s->event_thread, "event_thread");
  pthread_mutex_unlock(&s->lifecycle);
  return 0;
}

jni_func(void, nativeDestroy, jlong session) {
  // Unpublished first, so no later JNI entry can find it and exactly one
  // caller is handed the retirement. A wrapper whose session is already gone
  // has nothing left to destroy.
  std::shared_ptr<Session> s = session_retire((uint64_t)session);
  if (!s) return;

  pthread_mutex_lock(&s->lifecycle);
  {
    pthread_rwlock_wrlock(&s->admission);
    s->retired = true;
    pthread_rwlock_unlock(&s->admission);
  }

  // Admission is revoked and its readers have drained; the event thread is the
  // handle's only remaining borrower, and a rejected hook can take admission
  // and return during this join.
  if (s->event_thread_started) {
    s->event_thread_exit = true;
    mpv_wakeup(s->handle);
    pthread_join(s->event_thread, NULL);
    s->event_thread_started = false;
  }

  // Blocks through decoder and video-output teardown, and on a wedged decoder
  // may never return. That costs this thread and this session; the registry no
  // longer lists it, so the next nativeCreate is unaffected.
  // The MediaCodec VO can retain the Surface until final decoder teardown, so
  // its JNI refs stay alive for the entire blocking termination.
  mpv_terminate_destroy(s->handle);
  render_cleanup(env, *s);
  // A 4K session grows the native arena by ~115 MB and hands almost all of it
  // back here, but Scudo keeps the freed pages: measured on an armeabi-v7a TV
  // box, ~20 MB stayed resident for close to half an hour before the allocator
  // released it on its own. Ask once, at the one moment a large, short-lived
  // arena has just drained. This is reclaim, not a fix for playback footprint:
  // during playback the heap is 96% genuinely allocated, so nothing here helps
  // a foreground app that is being killed while playing.
  purge_native_arena();
  pthread_mutex_unlock(&s->lifecycle);
}

jni_func(jint, nativeSetLogLevel, jlong session, jstring jlevel) {
  SessionGuard guard(session);
  if (!guard.mpv) return MPV_ERROR_UNINITIALIZED;

  const std::string level = java_string_to_utf8(env, jlevel);
  if (env->ExceptionCheck()) return MPV_ERROR_NOMEM;
  const int result = mpv_request_log_messages(guard.mpv, level.c_str());
  if (result < 0) ALOGE("mpv_request_log_messages returned error %s", mpv_error_string(result));
  return result;
}

// Runs a command synchronously. Returns the negative mpv error on failure,
// the `playlist_entry_id` a `loadfile` created (always > 0), or 0 for a
// command that succeeded without one. A retired session reports
// MPV_ERROR_UNINITIALIZED like any other rejected command.
jni_func(jlong, nativeCommand, jlong session, jobjectArray jarray) {
  SessionGuard guard(session);
  if (!guard.mpv) return MPV_ERROR_UNINITIALIZED;

  const char* arguments[128] = {0};
  int len = env->GetArrayLength(jarray);
  if (len >= (int)ARRAYLEN(arguments)) {
    die("too many command arguments");
    return MPV_ERROR_INVALID_PARAMETER;
  }

  std::vector<std::string> storage;
  storage.reserve(len);
  for (int i = 0; i < len; ++i) {
    jstring jarg = (jstring)env->GetObjectArrayElement(jarray, i);
    storage.push_back(java_string_to_utf8(env, jarg));
    arguments[i] = storage.back().c_str();
    env->DeleteLocalRef(jarg);
  }

  mpv_node result{};
  const int status = mpv_command_ret(guard.mpv, arguments, &result);
  if (status < 0) {
    ALOGE("mpv_command(%s) returned error %s", len > 0 ? arguments[0] : "", mpv_error_string(status));
    return status;
  }

  jlong playlist_entry_id = 0;
  const mpv_node_list* map = result.format == MPV_FORMAT_NODE_MAP ? result.u.list : nullptr;
  if (map && map->keys && map->values) {
    for (int i = 0; i < map->num; ++i) {
      if (map->keys[i] && strcmp(map->keys[i], "playlist_entry_id") == 0 && map->values[i].format == MPV_FORMAT_INT64) {
        playlist_entry_id = (jlong)map->values[i].u.int64;
        break;
      }
    }
  }
  mpv_free_node_contents(&result);
  return playlist_entry_id;
}

// A continuation for a retired session is dropped, even while its handle is
// still terminating. Destruction releases any outstanding hooks; a session's
// hook ids are its own, so no other session can ever receive one.
jni_func(void, nativeHookContinue, jlong session, jlong id) {
  SessionGuard guard(session);
  if (!guard.mpv) return;
  mpv_hook_continue(guard.mpv, (uint64_t)id);
}
