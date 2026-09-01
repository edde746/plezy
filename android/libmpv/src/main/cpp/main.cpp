#include <jni.h>
#include <mpv/client.h>
#include <pthread.h>

#include <atomic>
#include <clocale>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <mutex>

extern "C" {
#include <libavcodec/jni.h>
}

#include "event.h"
#include "jni_utils.h"
#include "log.h"

#define ARRAYLEN(a) (sizeof(a) / sizeof(a[0]))

void render_cleanup(JNIEnv* env);

static void* destroy_mpv_thread(void* arg) {
  mpv_handle* handle = (mpv_handle*)arg;
  mpv_terminate_destroy(handle);
  return NULL;
}

// Fire-and-forget mpv_terminate_destroy on a detached thread.
// Safe because the event thread has been joined and g_mpv cleared —
// no other code references this handle.
static void async_destroy(mpv_handle* handle) {
  pthread_t tid;
  if (pthread_create(&tid, NULL, destroy_mpv_thread, handle) == 0) {
    pthread_detach(tid);
  } else {
    // Fallback: destroy synchronously if thread creation fails
    mpv_terminate_destroy(handle);
  }
}

extern "C" {
jni_func(void, nativeCreate, jobject appctx);
jni_func(void, nativeInit);
jni_func(void, nativeDestroy);

jni_func(void, nativeCommand, jobjectArray jarray);
};

JavaVM* g_vm;
mpv_handle* g_mpv;
std::atomic<bool> g_event_thread_request_exit(false);

static pthread_t event_thread_id;
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
    g_event_thread_request_exit = true;
    mpv_wakeup(leaked_mpv);
    pthread_join(event_thread_id, NULL);
    g_mpv = NULL;
    render_cleanup(env);
  }

  g_mpv = mpv_create();
  if (!g_mpv) {
    die("context init failed");
    if (leaked_mpv) mpv_terminate_destroy(leaked_mpv);
    return;
  }

  mpv_request_log_messages(g_mpv, "v");

  // Async teardown of leaked handle — doesn't block caller
  if (leaked_mpv) async_destroy(leaked_mpv);
}

jni_func(void, nativeInit) {
  if (!g_mpv) {
    die("mpv is not created");
    return;
  }

  if (mpv_initialize(g_mpv) < 0) {
    die("mpv init failed");
    return;
  }

  g_event_thread_request_exit = false;
  if (pthread_create(&event_thread_id, NULL, event_thread, NULL) != 0) {
    die("thread create failed");
    return;
  }
  pthread_setname_np(event_thread_id, "event_thread");
}

jni_func(void, nativeDestroy) {
  std::lock_guard<std::mutex> lock(g_lifecycle_mutex);
  if (!g_mpv) {
    ALOGV("mpv destroy called but it's already destroyed");
    return;
  }
  mpv_handle* local_mpv = g_mpv;

  g_event_thread_request_exit = true;
  mpv_wakeup(local_mpv);
  pthread_join(event_thread_id, NULL);

  g_mpv = NULL;
  render_cleanup(env);

  // Async teardown — nativeDestroy returns immediately
  async_destroy(local_mpv);
}

jni_func(void, nativeCommand, jobjectArray jarray) {
  CHECK_MPV_INIT();

  const char* arguments[128] = {0};
  int len = env->GetArrayLength(jarray);
  if (len >= ARRAYLEN(arguments)) {
    die("too many command arguments");
    return;
  }

  for (int i = 0; i < len; ++i)
    arguments[i] = env->GetStringUTFChars((jstring)env->GetObjectArrayElement(jarray, i), NULL);

  mpv_command(g_mpv, arguments);

  for (int i = 0; i < len; ++i)
    env->ReleaseStringUTFChars((jstring)env->GetObjectArrayElement(jarray, i), arguments[i]);
}
