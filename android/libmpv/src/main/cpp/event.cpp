#include <jni.h>
#include <mpv/client.h>

#include <cmath>
#include <string>
#include <vector>

#include "globals.h"
#include "jni_utils.h"
#include "log.h"
#include "session.h"

// Every callback names the session it originated from. Kotlin drops a callback
// whose session is not the wrapper it published for, so a retiring core's tail
// - end-file, property changes, a hook raised just before teardown - can never
// be read as another session's. The thread borrows its session's immutable
// handle until joined, including the interval after admission is revoked, so a
// callback that reenters through a SessionGuard is simply refused.

static void sendPropertyUpdateToJava(
    JNIEnv* env, jlong jsession, mpv_event_property* prop, int64_t source_id, bool has_source_id) {
  jstring jprop = new_java_string(env, prop->name);
  jstring jvalue = NULL;
  const jboolean jhas_source_id = has_source_id ? JNI_TRUE : JNI_FALSE;
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
    JNIEnv* env, jlong jsession, int event, int64_t source_id, bool has_source_id, double position_seconds = 0.0,
    bool has_position_seconds = false) {
  env->CallStaticVoidMethod(
      mpv_MpvPlayer, mpv_MpvPlayer_onEvent, jsession, (jint)event, (jlong)source_id,
      has_source_id ? JNI_TRUE : JNI_FALSE, (jdouble)position_seconds, has_position_seconds ? JNI_TRUE : JNI_FALSE);
}

static void sendEndFileToJava(JNIEnv* env, jlong jsession, const mpv_event_end_file* end_file) {
  const int reason = end_file ? end_file->reason : -1;
  const int64_t source_id = end_file ? end_file->playlist_entry_id : 0;
  // mpv_error code when reason is MPV_END_FILE_REASON_ERROR, 0 otherwise.
  const int error = end_file ? end_file->error : 0;
  // Its text, for a failure no error-level log line described.
  jstring jerror_message = reason == MPV_END_FILE_REASON_ERROR ? new_java_string(env, mpv_error_string(error)) : NULL;
  env->CallStaticVoidMethod(
      mpv_MpvPlayer, mpv_MpvPlayer_onEndFile, jsession, (jint)reason, (jlong)source_id, end_file ? JNI_TRUE : JNI_FALSE,
      (jint)error, jerror_message);
  if (jerror_message) env->DeleteLocalRef(jerror_message);
}

static void sendLogMessageToJava(JNIEnv* env, jlong jsession, mpv_event_log_message* msg) {
  jstring jprefix = new_java_string(env, msg->prefix);
  jstring jtext = new_java_string(env, msg->text);

  env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onLogMessage, jsession, jprefix, (jint)msg->log_level, jtext);

  if (jprefix) env->DeleteLocalRef(jprefix);
  if (jtext) env->DeleteLocalRef(jtext);
}

// A hook holds mpv (playback does not proceed) until Kotlin answers with
// nativeHookContinue(session, id); MpvPlayer guarantees that answer for every
// hook it is handed, and mpv itself continues any hook still held when the
// handle is destroyed.
static void sendHookToJava(JNIEnv* env, jlong jsession, mpv_event_hook* hook) {
  jstring jname = new_java_string(env, hook->name);
  env->CallStaticVoidMethod(mpv_MpvPlayer, mpv_MpvPlayer_onHook, jsession, jname, (jlong)hook->id);
  if (jname) env->DeleteLocalRef(jname);
}

namespace {

// The playlist entry the events after a START_FILE belong to.
struct SourceState {
  int64_t id = 0;
  bool has = false;
};

// An event dequeued while draining ahead of an error end-file. mpv frees an
// event's data at the next mpv_wait_event, so this copies what dispatchEvent
// reads and nothing more.
struct HeldEvent {
  mpv_event_id id = MPV_EVENT_NONE;
  bool has_data = false;
  // The property's or the hook's name.
  std::string name;
  mpv_format format = MPV_FORMAT_NONE;
  union {
    int flag;
    int64_t int64;
    double number;
  } value{};
  std::string string_value;
  mpv_event_start_file start_file{};
  mpv_event_end_file end_file{};
  uint64_t hook_id = 0;
};

}  // namespace

// Forwards one event, advancing [source] at START_FILE. The live loop and the
// replay of events held behind an error end-file share it, so both attribute
// events to the same entry.
static void dispatchEvent(JNIEnv* env, jlong jsession, mpv_handle* mpv, const mpv_event* event, SourceState& source) {
  switch (event->event_id) {
    case MPV_EVENT_LOG_MESSAGE:
      sendLogMessageToJava(env, jsession, (mpv_event_log_message*)event->data);
      break;
    case MPV_EVENT_PROPERTY_CHANGE:
      sendPropertyUpdateToJava(env, jsession, (mpv_event_property*)event->data, source.id, source.has);
      break;
    case MPV_EVENT_END_FILE:
      sendEndFileToJava(env, jsession, (const mpv_event_end_file*)event->data);
      break;
    case MPV_EVENT_START_FILE: {
      const mpv_event_start_file* start_file = (const mpv_event_start_file*)event->data;
      source.has = start_file != NULL;
      source.id = start_file ? start_file->playlist_entry_id : 0;
      sendEventToJava(env, jsession, event->event_id, source.id, source.has);
      break;
    }
    case MPV_EVENT_FILE_LOADED:
      sendEventToJava(env, jsession, event->event_id, source.id, source.has);
      break;
    case MPV_EVENT_HOOK:
      sendHookToJava(env, jsession, (mpv_event_hook*)event->data);
      break;
    case MPV_EVENT_PLAYBACK_RESTART: {
      double position_seconds = 0.0;
      const bool has_position_seconds = mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &position_seconds) >= 0 &&
                                        std::isfinite(position_seconds);
      sendEventToJava(env, jsession, event->event_id, source.id, source.has, position_seconds, has_position_seconds);
      break;
    }
    default:
      // Nothing on the Kotlin side consumes the remaining ids (MpvEvent.fromId).
      break;
  }
}

static void holdEvent(const mpv_event* event, std::vector<HeldEvent>& held) {
  HeldEvent copy;
  copy.id = event->event_id;
  copy.has_data = event->data != NULL;
  switch (event->event_id) {
    case MPV_EVENT_PROPERTY_CHANGE: {
      const mpv_event_property* prop = (const mpv_event_property*)event->data;
      copy.name = prop->name;
      copy.format = prop->format;
      switch (prop->format) {
        case MPV_FORMAT_NONE:
          break;
        case MPV_FORMAT_FLAG:
          copy.value.flag = *(int*)prop->data;
          break;
        case MPV_FORMAT_INT64:
          copy.value.int64 = *(int64_t*)prop->data;
          break;
        case MPV_FORMAT_DOUBLE:
          copy.value.number = *(double*)prop->data;
          break;
        case MPV_FORMAT_STRING:
          if (const char* value = *(const char**)prop->data) copy.string_value = value;
          break;
        default:
          // sendPropertyUpdateToJava forwards no other format.
          return;
      }
      break;
    }
    case MPV_EVENT_START_FILE:
      if (event->data) copy.start_file = *(const mpv_event_start_file*)event->data;
      break;
    case MPV_EVENT_END_FILE:
      if (event->data) copy.end_file = *(const mpv_event_end_file*)event->data;
      break;
    case MPV_EVENT_HOOK: {
      const mpv_event_hook* hook = (const mpv_event_hook*)event->data;
      copy.name = hook->name;
      copy.hook_id = hook->id;
      break;
    }
    case MPV_EVENT_FILE_LOADED:
    case MPV_EVENT_PLAYBACK_RESTART:
      break;
    default:
      // dispatchEvent forwards nothing else.
      return;
  }
  held.push_back(std::move(copy));
}

// Rebuilds the event view dispatchEvent reads from a held copy.
static void replayHeldEvent(JNIEnv* env, jlong jsession, mpv_handle* mpv, HeldEvent& held, SourceState& source) {
  mpv_event event{};
  event.event_id = held.id;
  mpv_event_property prop{};
  mpv_event_hook hook{};
  const char* string_value = held.string_value.c_str();
  switch (held.id) {
    case MPV_EVENT_PROPERTY_CHANGE:
      prop.name = held.name.c_str();
      prop.format = held.format;
      prop.data = held.format == MPV_FORMAT_STRING ? (void*)&string_value
                  : held.format == MPV_FORMAT_NONE ? NULL
                                                   : (void*)&held.value;
      event.data = &prop;
      break;
    case MPV_EVENT_START_FILE:
      event.data = held.has_data ? &held.start_file : NULL;
      break;
    case MPV_EVENT_END_FILE:
      event.data = held.has_data ? &held.end_file : NULL;
      break;
    case MPV_EVENT_HOOK:
      hook.name = held.name.c_str();
      hook.id = held.hook_id;
      event.data = &hook;
      break;
    default:
      break;
  }
  dispatchEvent(env, jsession, mpv, &event, source);
}

// Bounds how long an error end-file can wait behind a core that keeps
// logging, while still taking everything mpv can have buffered. mpv keeps up
// to 10000 lines per client at the verbose level and 1000 below it
// (player/client.c, mpv_request_log_messages), drops the oldest when full, and
// then reads out one "log message buffer overflow" notice ahead of the rest
// (common/msg.c). The lines explaining a failure are the newest, so a smaller
// cap would stop just short of them under verbose logging.
static const int kEndFileDrainLimit = 10000 + 1;

// Why an error end-file first takes the lines already pending behind it.
//
// mpv writes a client's log lines to a buffer separate from its event queue,
// synchronously as they are logged, and mpv_wait_event hands out queued events
// and pending property changes before any buffered line (player/client.c).
// So the lines explaining a failed open - ffmpeg's "HTTP error 404", "[stream]
// Failed to open ..." - are all buffered by the time its END_FILE is posted,
// yet a thread that fell a few hundred microseconds behind, e.g. inside a JNI
// callback, dequeues the END_FILE first. Kotlin (MpvEndFileDiagnostics) and
// Dart (the player screen's HTTP-status and last-error latches) read the
// lines before an end-file as its cause; delivered late, the failure is
// reported as mpv's generic "loading failed".
//
// Hence, for an error end-file only: take what is pending without blocking,
// forward log lines at once, hold every other event in order, then forward the
// end-file and replay what was held. A stop or eof end-file is not drained: on
// `loadfile replace` it precedes the next file's START_FILE, and draining would
// pull that open's failure lines ahead of the START_FILE that resets both
// latches. Accepted cost: a line logged after the END_FILE was posted can also
// be pulled ahead. That takes a second playlist entry opening right behind the
// failed one: mpv's HLS playlist walk, and gapless music, which arms the next
// track with `loadfile append` and prefetches it, so it is reachable in normal
// music playback. Only diagnostic text is affected: the end-file may carry the
// next entry's line as its message. Music's failure handling keys on the
// end-file's sourceId, never on the text.
static void forwardErrorEndFile(
    JNIEnv* env, jlong jsession, Session* session, const mpv_event_end_file end_file, SourceState& source) {
  std::vector<HeldEvent> held;
  for (int n = 0; n < kEndFileDrainLimit && !session->event_thread_exit; ++n) {
    mpv_event* next = mpv_wait_event(session->handle, 0);
    if (next->event_id == MPV_EVENT_NONE) break;
    if (next->event_id == MPV_EVENT_LOG_MESSAGE) {
      sendLogMessageToJava(env, jsession, (mpv_event_log_message*)next->data);
    } else {
      holdEvent(next, held);
    }
  }
  sendEndFileToJava(env, jsession, &end_file);
  for (HeldEvent& event : held) replayHeldEvent(env, jsession, session->handle, event, source);
}

void* event_thread(void* arg) {
  // Borrowed, not owned: the retirement that frees the session joins this
  // thread first (nativeDestroy), so the pointer outlives the loop.
  Session* session = (Session*)arg;
  const jlong jsession = (jlong)session->id;
  mpv_handle* const mpv = session->handle;

  JNIEnv* env = NULL;
  acquire_jni_env(g_vm, &env);
  if (!env) die("failed to acquire java env");

  SourceState source;

  // Checked before every wait, not only after one: a drain's non-blocking
  // wait can consume nativeDestroy's single wakeup, and a blocking wait after
  // it would never return.
  while (!session->event_thread_exit) {
    mpv_event* event = mpv_wait_event(mpv, -1.0);

    if (session->event_thread_exit) break;

    if (event->event_id == MPV_EVENT_NONE) continue;

    const mpv_event_end_file* end_file = (const mpv_event_end_file*)event->data;
    if (event->event_id == MPV_EVENT_END_FILE && end_file && end_file->reason == MPV_END_FILE_REASON_ERROR) {
      // A copy: the drain's next wait frees the event's data.
      forwardErrorEndFile(env, jsession, session, *end_file, source);
    } else {
      dispatchEvent(env, jsession, mpv, event, source);
    }
  }

  g_vm->DetachCurrentThread();

  return NULL;
}
