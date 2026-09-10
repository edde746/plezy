#pragma once

#include <jni.h>
#include <mpv/client.h>
#include <pthread.h>

#include <atomic>
#include <cstdint>
#include <memory>
#include <vector>

/**
 * One native player session: an mpv_handle, the event thread bound to it, and
 * the Surfaces its video output holds.
 *
 * Sessions are independent. Nothing outside a session serializes against it,
 * so a teardown that never returns - a vendor decoder wedged inside
 * mpv_terminate_destroy - costs the thread that called nativeDestroy and this
 * session's resources, never the process's ability to open the next one.
 *
 * Two per-session locks, in this order:
 *
 * - [lifecycle] (L) serializes nativeInit against nativeDestroy, and is held
 *   through wake, join and termination so a retirement cannot overlap the
 *   initialization it is retiring.
 * - [admission] (A) guards [retired]: write-held to revoke, read-held by every
 *   other JNI entry through its last use of [handle]. Taking it for write
 *   drains the admitted readers; retirement then releases it BEFORE joining
 *   and terminating, so an event callback can reenter, be refused, and return.
 *
 * [handle] is immutable for the session's whole life: the event thread borrows
 * it until joined, which is after admission has already been revoked.
 */
struct Session {
  Session(uint64_t id, mpv_handle* handle);
  ~Session();

  Session(const Session&) = delete;
  Session& operator=(const Session&) = delete;

  const uint64_t id;
  mpv_handle* const handle;

  pthread_mutex_t lifecycle = PTHREAD_MUTEX_INITIALIZER;
  pthread_rwlock_t admission = PTHREAD_RWLOCK_INITIALIZER;
  /** Set once under L and A(write); every later JNI entry is refused. */
  bool retired = false;

  pthread_t event_thread{};
  bool event_thread_started = false;
  std::atomic<bool> event_thread_exit{false};

  /**
   * The video output's Surfaces, owned as JNI global refs (render.cpp). Guarded
   * by [surface_lock], which is never held across a lifecycle operation.
   */
  pthread_mutex_t surface_lock = PTHREAD_MUTEX_INITIALIZER;
  jobject surface = nullptr;
  jobject osd_surface = nullptr;
  jlong video_generation = 0;
  jlong osd_generation = 0;
  std::vector<jobject> pending_osd_surfaces;
};

/** Publishes a new session for [handle] and mints its monotonic id. */
std::shared_ptr<Session> session_register(mpv_handle* handle);

/** The published session with this id, or null once it has been retired. */
std::shared_ptr<Session> session_find(uint64_t id);

/**
 * Unpublishes the session, so no later lookup can find it, and hands it to the
 * caller that is to retire it. Exactly one caller receives it; a second
 * nativeDestroy for the same id gets null and has nothing to do.
 */
std::shared_ptr<Session> session_retire(uint64_t id);

/**
 * Read-locked admission of one JNI entry to a live session. [mpv] is NULL when
 * the id names a session that was retired or never existed; the caller then
 * reports MPV_ERROR_UNINITIALIZED / null and touches nothing. A refused entry
 * is an expected outcome of teardown racing in-flight work, not a programming
 * error, so it never throws into Java.
 */
class SessionGuard {
 public:
  explicit SessionGuard(jlong id);
  ~SessionGuard();
  SessionGuard(const SessionGuard&) = delete;
  SessionGuard& operator=(const SessionGuard&) = delete;

  /** Non-null exactly when [mpv] is; the session's own state stays reachable. */
  const std::shared_ptr<Session> session;
  mpv_handle* mpv = nullptr;
};
