#include <jni.h>
#include <mpv/client.h>
#include <pthread.h>

#include <atomic>
#include <clocale>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <mutex>
#include <string>
#include <vector>

extern "C" {
#include <libavcodec/jni.h>
}

#include "event.h"
#include "jni_utils.h"
#include "log.h"

#define ARRAYLEN(a) (sizeof(a) / sizeof(a[0]))

void render_cleanup(JNIEnv* env);

extern "C" {
jni_func(void, nativeCreate, jobject appctx);
jni_func(void, nativeInit);
jni_func(void, nativeDestroy);

jni_func(jint, nativeSetLogLevel, jstring level);

jni_func(jlong, nativeCommand, jobjectArray jarray);
jni_func(void, nativeHookContinue, jlong id);
};

JavaVM* g_vm;
mpv_handle* g_mpv;
std::atomic<bool> g_event_thread_request_exit(false);

static pthread_t event_thread_id;
static bool event_thread_started = false;
static std::mutex g_lifecycle_mutex;

static void prepare_environment(JNIEnv* env, jobject appctx) {
  setlocale(LC_NUMERIC, "C");

  if (!env->GetJavaVM(&g_vm) && g_vm) av_jni_set_java_vm(g_vm, NULL);

  jobject global_appctx = env->NewGlobalRef(appctx);
  if (global_appctx) av_jni_set_android_app_ctx(global_appctx, NULL);

  init_methods_cache(env);
}

jni_func(void, nativeCreate, jobject appctx) {
  std::lock_guard<std::mutex> lock(g_lifecycle_mutex);
  prepare_environment(env, appctx);

  mpv_handle* leaked_mpv = NULL;
  if (g_mpv) {
    ALOGE("destroying leaked mpv instance");
    leaked_mpv = g_mpv;
    if (event_thread_started) {
      g_event_thread_request_exit = true;
      mpv_wakeup(leaked_mpv);
      pthread_join(event_thread_id, NULL);
      event_thread_started = false;
    }
    g_mpv = NULL;
    mpv_terminate_destroy(leaked_mpv);
    render_cleanup(env);
  }

  g_mpv = mpv_create();
  if (!g_mpv) {
    die("context init failed");
    return;
  }

  mpv_request_log_messages(g_mpv, "warn");
}

jni_func(void, nativeInit) {
  std::lock_guard<std::mutex> lock(g_lifecycle_mutex);
  if (!g_mpv) {
    die("mpv is not created");
    return;
  }

  if (mpv_initialize(g_mpv) < 0) {
    die("mpv init failed");
    return;
  }

  // Per-file decode routing (Dolby Vision P5, H.264 High 10) has to land
  // before mpv creates the decoder; file-loaded is already too late for the
  // MediaCodec path. on_preloaded runs after the demuxer opened the file and
  // holds playback until Kotlin continues it (MpvPlayer.onHook).
  mpv_hook_add(g_mpv, 0, "on_preloaded", 0);

  g_event_thread_request_exit = false;
  if (pthread_create(&event_thread_id, NULL, event_thread, NULL) != 0) {
    die("thread create failed");
    return;
  }
  event_thread_started = true;
  pthread_setname_np(event_thread_id, "event_thread");
}

jni_func(void, nativeDestroy) {
  std::lock_guard<std::mutex> lock(g_lifecycle_mutex);
  if (!g_mpv) {
    return;
  }
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

  // The MediaCodec VO can retain the Surface until final decoder teardown.
  // Keep its JNI refs alive for the entire blocking termination.
  mpv_terminate_destroy(local_mpv);
  render_cleanup(env);
}

jni_func(jint, nativeSetLogLevel, jstring jlevel) {
  std::lock_guard<std::mutex> lock(g_lifecycle_mutex);
  if (!g_mpv) return MPV_ERROR_UNINITIALIZED;

  const std::string level = java_string_to_utf8(env, jlevel);
  if (env->ExceptionCheck()) return MPV_ERROR_NOMEM;
  const int result = mpv_request_log_messages(g_mpv, level.c_str());
  if (result < 0) ALOGE("mpv_request_log_messages returned error %s", mpv_error_string(result));
  return result;
}

// Runs a command synchronously. Returns the negative mpv error on failure,
// the `playlist_entry_id` a `loadfile` created (always > 0), or 0 for a
// command that succeeded without one. `die` (a Java RuntimeException) is
// reserved for a missing core, matching the other entry points.
jni_func(jlong, nativeCommand, jobjectArray jarray) {
  CHECK_MPV_INIT_RET(MPV_ERROR_UNINITIALIZED);

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
  const int status = mpv_command_ret(g_mpv, arguments, &result);
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

jni_func(void, nativeHookContinue, jlong id) {
  if (!g_mpv) return;
  mpv_hook_continue(g_mpv, (uint64_t)id);
}
