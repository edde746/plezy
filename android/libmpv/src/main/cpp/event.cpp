#include <jni.h>
#include <mpv/client.h>

#include "globals.h"
#include "jni_utils.h"
#include "log.h"

static void sendPropertyUpdateToJava(JNIEnv* env, mpv_event_property* prop) {
  jstring jprop = env->NewStringUTF(prop->name);
  jstring jvalue = NULL;
  switch (prop->format) {
    case MPV_FORMAT_NONE:
      env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_S, jprop);
      break;
    case MPV_FORMAT_FLAG:
      env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_Sb, jprop, *(int*)prop->data);
      break;
    case MPV_FORMAT_INT64:
      env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_Sl, jprop, *(int64_t*)prop->data);
      break;
    case MPV_FORMAT_DOUBLE:
      env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_Sd, jprop, *(double*)prop->data);
      break;
    case MPV_FORMAT_STRING:
      jvalue = env->NewStringUTF(*(const char**)prop->data);
      env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onPropertyChanged_SS, jprop, jvalue);
      break;
    default:
      break;
  }
  if (jprop) env->DeleteLocalRef(jprop);
  if (jvalue) env->DeleteLocalRef(jvalue);
}

static void sendEventToJava(JNIEnv* env, int event) {
  env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onEvent, event);
}

static void sendEndFileToJava(JNIEnv* env, mpv_event* event) {
  mpv_event_end_file* end_file = (mpv_event_end_file*)event->data;
  int reason = end_file ? end_file->reason : -1;
  env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onEndFile, (jint)reason);
}

static inline bool invalid_utf8(unsigned char c) { return c == 0xc0 || c == 0xc1 || c >= 0xf5; }

static void sendLogMessageToJava(JNIEnv* env, mpv_event_log_message* msg) {
  const auto invalid_utf8 = [](unsigned char c) { return c == 0xc0 || c == 0xc1 || c >= 0xf5; };
  for (int i = 0; msg->text[i]; i++) {
    if (invalid_utf8(static_cast<unsigned char>(msg->text[i]))) return;
  }

  jstring jprefix = env->NewStringUTF(msg->prefix);
  jstring jtext = env->NewStringUTF(msg->text);

  env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onLogMessage, jprefix, (jint)msg->log_level, jtext);

  if (jprefix) env->DeleteLocalRef(jprefix);
  if (jtext) env->DeleteLocalRef(jtext);
}

void* event_thread(void* arg) {
  JNIEnv* env = NULL;
  acquire_jni_env(g_vm, &env);
  if (!env) die("failed to acquire java env");

  while (true) {
    mpv_event* mp_event;
    mpv_event_property* mp_property;
    mpv_event_log_message* msg;

    mp_event = mpv_wait_event(g_mpv, -1.0);

    if (g_event_thread_request_exit) break;

    if (mp_event->event_id == MPV_EVENT_NONE) continue;

    switch (mp_event->event_id) {
      case MPV_EVENT_LOG_MESSAGE:
        msg = (mpv_event_log_message*)mp_event->data;
        ALOGV("[%s:%s] %s", msg->prefix, msg->level, msg->text);
        sendLogMessageToJava(env, msg);
        break;
      case MPV_EVENT_PROPERTY_CHANGE:
        mp_property = (mpv_event_property*)mp_event->data;
        sendPropertyUpdateToJava(env, mp_property);
        break;
      case MPV_EVENT_END_FILE:
        sendEndFileToJava(env, mp_event);
        break;
      default:
        ALOGV("event: %s\n", mpv_event_name(mp_event->event_id));
        sendEventToJava(env, mp_event->event_id);
        break;
    }
  }

  g_vm->DetachCurrentThread();

  return NULL;
}
