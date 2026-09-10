#include "session.h"

#include <map>
#include <mutex>

namespace {

std::mutex& registry_lock() {
  static std::mutex lock;
  return lock;
}

std::map<uint64_t, std::shared_ptr<Session>>& registry() {
  static std::map<uint64_t, std::shared_ptr<Session>> sessions;
  return sessions;
}

uint64_t next_id = 0;

}  // namespace

Session::Session(uint64_t id, mpv_handle* handle) : id(id), handle(handle) {}

Session::~Session() {
  pthread_mutex_destroy(&lifecycle);
  pthread_rwlock_destroy(&admission);
  pthread_mutex_destroy(&surface_lock);
}

std::shared_ptr<Session> session_register(mpv_handle* handle) {
  std::lock_guard<std::mutex> lock(registry_lock());
  std::shared_ptr<Session> session = std::make_shared<Session>(++next_id, handle);
  registry()[session->id] = session;
  return session;
}

std::shared_ptr<Session> session_find(uint64_t id) {
  std::lock_guard<std::mutex> lock(registry_lock());
  auto entry = registry().find(id);
  return entry == registry().end() ? nullptr : entry->second;
}

std::shared_ptr<Session> session_retire(uint64_t id) {
  std::lock_guard<std::mutex> lock(registry_lock());
  auto entry = registry().find(id);
  if (entry == registry().end()) return nullptr;
  std::shared_ptr<Session> session = entry->second;
  registry().erase(entry);
  return session;
}

SessionGuard::SessionGuard(jlong id) : session(session_find((uint64_t)id)) {
  if (!session) return;
  pthread_rwlock_rdlock(&session->admission);
  if (!session->retired) mpv = session->handle;
}

SessionGuard::~SessionGuard() {
  if (session) pthread_rwlock_unlock(&session->admission);
}
