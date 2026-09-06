#include <jni.h>
#include <mpv/client.h>

#include <cmath>

#include "globals.h"
#include "jni_utils.h"
#include "log.h"

// The session every callback below names, bound once before the thread
// starts (event_thread_bind). Kotlin drops a callback whose session is not
// the wrapper it published for, so a retiring core's tail — end-file,
// property changes, a hook raised just before teardown — can never be read
// as the successor's. L keeps this binding immutable through join, including
// the interval after admission is revoked; callbacks never acquire L.
static mpv_handle* thread_mpv;
static uint64_t thread_session;

void event_thread_bind(mpv_handle* mpv, uint64_t session) {
  thread_mpv = mpv;
  thread_session = session;
}

static void sendPropertyUpdateToJava(JNIEnv* env, mpv_event_property* prop, int64_t source_id, bool has_source_id) {
  jstring jprop = new_java_string(env, prop->name);
  jstring jvalue = NULL;
  const jboolean jhas_source_id = has_source_id ? JNI_TRUE : JNI_FALSE;
  const jlong jsession = (jlong)thread_session;
  switch (prop->format) {
    case MPV_FORMAT_NONE:
      env->CallStaticVoidMethod(
          mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_SJZ, jsession, jprop, (jlong)source_id, jhas_source_id);
      break;
    case MPV_FORMAT_FLAG:
      env->CallStaticVoidMethod(
          mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_SZJZ, jsession, jprop, (jboolean) * (int*)prop->data,
          (jlong)source_id, jhas_source_id);
      break;
    case MPV_FORMAT_INT64:
      env->CallStaticVoidMethod(
          mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_SJJZ, jsession, jprop, (jlong) * (int64_t*)prop->data,
          (jlong)source_id, jhas_source_id);
      break;
    case MPV_FORMAT_DOUBLE:
      env->CallStaticVoidMethod(
          mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_SDJZ, jsession, jprop, (jdouble) * (double*)prop->data,
          (jlong)source_id, jhas_source_id);
      break;
    case MPV_FORMAT_STRING:
      jvalue = new_java_string(env, *(const char**)prop->data);
      env->CallStaticVoidMethod(
          mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_SSJZ, jsession, jprop, jvalue, (jlong)source_id,
          jhas_source_id);
      break;
    default:
      break;
  }
  if (jprop) env->DeleteLocalRef(jprop);
  if (jvalue) env->DeleteLocalRef(jvalue);
}

static void sendEventToJava(
    JNIEnv* env, int event, int64_t source_id, bool has_source_id, double position_seconds = 0.0,
    bool has_position_seconds = false) {
  env->CallStaticVoidMethod(
      mpv_MpvPlayer, mpv_MpvPlayer_onEvent, (jlong)thread_session, (jint)event, (jlong)source_id,
      has_source_id ? JNI_TRUE : JNI_FALSE, (jdouble)position_seconds, has_position_seconds ? JNI_TRUE : JNI_FALSE);
}

static void sendEndFileToJava(JNIEnv* env, mpv_event* event) {
  mpv_event_end_file* end_file = (mpv_event_end_file*)event->data;
  const int reason = end_file ? end_file->reason : -1;
  const int64_t source_id = end_file ? end_file->playlist_entry_id : 0;
  env->CallStaticVoidMethod(
      mpv_MpvPlayer, mpv_MpvPlayer_onEndFile, (jlong)thread_session, (jint)reason, (jlong)source_id,
      end_file ? JNI_TRUE : JNI_FALSE);
}

static void sendLogMessageToJava(JNIEnv* env, mpv_event_log_message* msg) {
  jstring jprefix = new_java_string(env, msg->prefix);
  jstring jtext = new_java_string(env, msg->text);

  env->CallStaticVoidMethod(
      mpv_MpvPlayer, mpv_MpvPlayer_onLogMessage, (jlong)thread_session, jprefix, (jint)msg->log_level, jtext);

  if (jprefix) env->DeleteLocalRef(jprefix);
  if (jtext) env->DeleteLocalRef(jtext);
}

// A hook holds mpv (playback does not proceed) until Kotlin answers with
// nativeHookContinue(session, id); MpvPlayer guarantees that answer for every
// hook it is handed, and mpv itself continues any hook still held when the
// handle is destroyed.
static void sendHookToJava(JNIEnv* env, mpv_event_hook* hook) {
  jstring jname = new_java_string(env, hook->name);
  env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onHook, (jlong)thread_session, jname, (jlong)hook->id);
  if (jname) env->DeleteLocalRef(jname);
}

void* event_thread(void* arg) {
  JNIEnv* env = NULL;
  acquire_jni_env(g_vm, &env);
  if (!env) die("failed to acquire java env");

  int64_t source_id = 0;
  bool has_source_id = false;

  while (true) {
    mpv_event* mp_event;
    mpv_event_property* mp_property;
    mpv_event_log_message* msg;

    mp_event = mpv_wait_event(thread_mpv, -1.0);

    if (g_event_thread_request_exit) break;

    if (mp_event->event_id == MPV_EVENT_NONE) continue;

    switch (mp_event->event_id) {
      case MPV_EVENT_LOG_MESSAGE:
        msg = (mpv_event_log_message*)mp_event->data;
        sendLogMessageToJava(env, msg);
        break;
      case MPV_EVENT_PROPERTY_CHANGE:
        mp_property = (mpv_event_property*)mp_event->data;
        sendPropertyUpdateToJava(env, mp_property, source_id, has_source_id);
        break;
      case MPV_EVENT_END_FILE:
        sendEndFileToJava(env, mp_event);
        break;
      case MPV_EVENT_START_FILE: {
        mpv_event_start_file* start_file = (mpv_event_start_file*)mp_event->data;
        has_source_id = start_file != NULL;
        source_id = start_file ? start_file->playlist_entry_id : 0;
        sendEventToJava(env, mp_event->event_id, source_id, has_source_id);
        break;
      }
      case MPV_EVENT_FILE_LOADED:
        sendEventToJava(env, mp_event->event_id, source_id, has_source_id);
        break;
      case MPV_EVENT_HOOK:
        sendHookToJava(env, (mpv_event_hook*)mp_event->data);
        break;
      case MPV_EVENT_PLAYBACK_RESTART: {
        double position_seconds = 0.0;
        const bool has_position_seconds =
            mpv_get_property(thread_mpv, "time-pos", MPV_FORMAT_DOUBLE, &position_seconds) >= 0 &&
            std::isfinite(position_seconds);
        sendEventToJava(env, mp_event->event_id, source_id, has_source_id, position_seconds, has_position_seconds);
        break;
      }
      default:
        // Nothing on the Kotlin side consumes the remaining ids (MpvEvent.fromId).
        break;
    }
  }

  g_vm->DetachCurrentThread();

  return NULL;
}
