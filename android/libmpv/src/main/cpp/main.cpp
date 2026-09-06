#include <jni.h>
#include <mpv/client.h>
#include <pthread.h>

#include <atomic>
#include <clocale>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <string>
#include <vector>

extern "C" {
#include <libavcodec/jni.h>
}

#include "event.h"
#include "globals.h"
#include "jni_utils.h"
#include "log.h"

#define ARRAYLEN(a) (sizeof(a) / sizeof(a[0]))

void render_cleanup(JNIEnv* env);

extern "C" {
jni_func(jlong, nativeCreate, jobject appctx);
jni_func(jint, nativeInit, jlong session);
jni_func(void, nativeDestroy, jlong session);

jni_func(jint, nativeSetLogLevel, jlong session, jstring level);

jni_func(jlong, nativeCommand, jlong session, jobjectArray jarray);
jni_func(void, nativeHookContinue, jlong session, jlong id);
};

JavaVM* g_vm;
mpv_handle* g_mpv;
uint64_t g_session;
pthread_rwlock_t g_session_lock = PTHREAD_RWLOCK_INITIALIZER;
std::atomic<bool> g_event_thread_request_exit(false);

static uint64_t next_session = 0;
static pthread_t event_thread_id;
static bool event_thread_started = false;

// Write-locked scope for the lifecycle entries; waits for every admitted
// reader to return before the handle can change underneath it.
class LifecycleGuard {
 public:
  LifecycleGuard() { pthread_rwlock_wrlock(&g_session_lock); }
  ~LifecycleGuard() { pthread_rwlock_unlock(&g_session_lock); }
  LifecycleGuard(const LifecycleGuard&) = delete;
  LifecycleGuard& operator=(const LifecycleGuard&) = delete;
};

static void prepare_environment(JNIEnv* env, jobject appctx) {
  setlocale(LC_NUMERIC, "C");

  if (!env->GetJavaVM(&g_vm) && g_vm) av_jni_set_java_vm(g_vm, NULL);

  jobject global_appctx = env->NewGlobalRef(appctx);
  if (global_appctx) av_jni_set_android_app_ctx(global_appctx, NULL);

  init_methods_cache(env);
}

// Caller holds the write lock. Stops the event thread, retires the session
// id (so a late nativeHookContinue / property call for it is refused, not
// delivered to whatever comes next), and tears the core down. mpv itself
// continues any hook the destroyed handle was still holding.
static void destroy_locked(JNIEnv* env) {
  mpv_handle* local_mpv = g_mpv;

  // Configuration (including an invalid initial log level) can fail before
  // nativeInit starts the event thread.
  if (event_thread_started) {
    g_event_thread_request_exit = true;
    mpv_wakeup(local_mpv);
    pthread_join(event_thread_id, NULL);
    event_thread_started = false;
  }

  g_mpv = NULL;
  g_session = 0;

  // The MediaCodec VO can retain the Surface until final decoder teardown.
  // Keep its JNI refs alive for the entire blocking termination.
  mpv_terminate_destroy(local_mpv);
  render_cleanup(env);
}

jni_func(jlong, nativeCreate, jobject appctx) {
  LifecycleGuard lock;
  prepare_environment(env, appctx);

  if (g_mpv) {
    ALOGE("destroying leaked mpv instance");
    destroy_locked(env);
  }

  g_mpv = mpv_create();
  if (!g_mpv) {
    die("context init failed");
    return 0;
  }
  g_session = ++next_session;

  mpv_request_log_messages(g_mpv, "warn");
  return (jlong)g_session;
}

jni_func(jint, nativeInit, jlong session) {
  LifecycleGuard lock;
  if (!g_mpv || g_session != (uint64_t)session) return MPV_ERROR_UNINITIALIZED;

  const int result = mpv_initialize(g_mpv);
  if (result < 0) {
    ALOGE("mpv_initialize returned error %s", mpv_error_string(result));
    return result;
  }

  // Per-file decode routing (Dolby Vision P5, H.264 High 10) has to land
  // before mpv creates the decoder; file-loaded is already too late for the
  // MediaCodec path. on_preloaded runs after the demuxer opened the file and
  // holds playback until Kotlin continues it (MpvPlayer.onHook).
  mpv_hook_add(g_mpv, 0, "on_preloaded", 0);

  g_event_thread_request_exit = false;
  event_thread_bind(g_mpv, g_session);
  if (pthread_create(&event_thread_id, NULL, event_thread, NULL) != 0) {
    die("thread create failed");
    return MPV_ERROR_GENERIC;
  }
  event_thread_started = true;
  pthread_setname_np(event_thread_id, "event_thread");
  return 0;
}

jni_func(void, nativeDestroy, jlong session) {
  LifecycleGuard lock;
  // A wrapper whose session a later nativeCreate already retired has nothing
  // left to destroy; the successor is not its to touch.
  if (!g_mpv || g_session != (uint64_t)session) return;
  destroy_locked(env);
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

// A continuation for a retired session is dropped: the hook id belongs to a
// handle that no longer exists, and destroying that handle already continued
// it. The successor must never receive it.
jni_func(void, nativeHookContinue, jlong session, jlong id) {
  SessionGuard guard(session);
  if (!guard.mpv) return;
  mpv_hook_continue(guard.mpv, (uint64_t)id);
}
