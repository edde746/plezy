#pragma once

#include <jni.h>
#include <mpv/client.h>
#include <pthread.h>

#include <atomic>
#include <cstdint>

extern JavaVM* g_vm;

// The process-global native session. One mpv_handle lives at a time; each is
// identified by a monotonic session id handed to Kotlin by nativeCreate. Every
// JNI entry names the session it was issued for, every callback carries the
// session it originated from, so a retired wrapper can neither touch nor be
// fed by its successor.
//
// g_session_lock: write-held across create/init/destroy, read-held for every
// other entry. A reader admitted under a matching session keeps the handle
// alive until it returns; retirement waits for it, then flips g_session so
// later callers with the old id are refused before they reach mpv.
extern mpv_handle* g_mpv;
extern uint64_t g_session;
extern pthread_rwlock_t g_session_lock;
extern std::atomic<bool> g_event_thread_request_exit;

// Read-locked admission of one JNI entry to the live session. `mpv` is NULL
// when `session` is not the live one (retired, superseded, or never created);
// the caller then reports MPV_ERROR_UNINITIALIZED / null and touches nothing.
// A refused entry is an expected outcome of teardown racing in-flight work,
// not a programming error, so it never throws into Java.
class SessionGuard {
 public:
  explicit SessionGuard(jlong session) {
    pthread_rwlock_rdlock(&g_session_lock);
    mpv = (g_mpv && g_session == (uint64_t)session) ? g_mpv : NULL;
  }
  ~SessionGuard() { pthread_rwlock_unlock(&g_session_lock); }
  SessionGuard(const SessionGuard&) = delete;
  SessionGuard& operator=(const SessionGuard&) = delete;

  mpv_handle* mpv;
};
