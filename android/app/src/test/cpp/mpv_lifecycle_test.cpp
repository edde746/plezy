#include <pthread.h>

#include <cerrno>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

static int tracked_mutex_lock(pthread_mutex_t* mutex);
static int tracked_write_lock(pthread_rwlock_t* lock);
static int controlled_thread_create(pthread_t* thread, const pthread_attr_t* attr, void* (*entry)(void*), void* arg);

// Compile the real JNI entries, admission guards, event loop and surface
// cleanup. Only external dependencies are controlled; no copy of the lock
// algorithm or direct assignment to production lifecycle globals is used.
#define UTIL_EXTERN
#define pthread_mutex_lock tracked_mutex_lock
#define pthread_rwlock_wrlock tracked_write_lock
#define pthread_create controlled_thread_create
// Android's two-argument thread naming API is not available on macOS.
#define pthread_setname_np(thread, name) ((void)0)
#include "../../../../libmpv/src/main/cpp/main.cpp"
#undef pthread_setname_np
#undef pthread_create
#undef pthread_rwlock_wrlock
#undef pthread_mutex_lock
#include "../../../../libmpv/src/main/cpp/event.cpp"
#include "../../../../libmpv/src/main/cpp/render.cpp"

struct mpv_handle {
  bool initialized = false;
  bool terminated = false;
  bool event_started = false;
  bool event_exited = false;
  bool woken = false;
  bool hook_pending = false;
  bool reject_hook_during_destroy = false;
  bool callback_entered = false;
  bool callback_returned = false;
  bool command_active = false;
  bool termination_entered = false;
  int initialize_result = 0;
  int hook_continuations = 0;
  int commands = 0;
  jlong callback_session = 0;
  jobject video = nullptr;
  jobject osd = nullptr;
  mpv_event_hook hook{"on_preloaded", 17};
  mpv_event event{};
};

namespace {

std::mutex gate;
std::condition_variable changed;
JavaVM vm;
JNIEnv jni;
int app_context;
mpv_handle* active_handle = nullptr;
// Retain fake allocations after termination so any erroneous late MPV access
// fails explicitly rather than depending on allocator reuse or undefined UAF.
std::vector<std::unique_ptr<mpv_handle>> handles;
std::vector<std::unique_ptr<_jstring>> callback_strings;
std::map<jobject, int> global_refs;
mpv_handle* held_termination = nullptr;
bool allow_termination = false;
bool allow_command = false;
bool successor_waiting = false;
bool reader_draining = false;
bool fail_thread_create = false;
thread_local mpv_handle* event_handle = nullptr;
enum class Operation { ordinary, successor, replacing_reader };
thread_local Operation operation = Operation::ordinary;

void require(bool condition, const char* message) {
  if (condition) return;
  std::fprintf(stderr, "%s\n", message);
  std::abort();
}

template <typename Predicate>
void await(std::unique_lock<std::mutex>& lock, Predicate predicate, const char* message) {
  require(changed.wait_for(lock, std::chrono::seconds(5), predicate), message);
}

void require_live(mpv_handle* handle) {
  require(handle && handle == active_handle && !handle->terminated, "MPV accessed outside its native lifetime");
}

void require_surfaces(mpv_handle* handle) {
  if (handle->video) require(global_refs[handle->video] == 1, "video Surface released before termination completed");
  if (handle->osd) require(global_refs[handle->osd] == 1, "OSD Surface released before termination completed");
}

jobject new_global_ref(jobject object) {
  std::lock_guard<std::mutex> lock(gate);
  if (object) ++global_refs[object];
  return object;
}

void delete_global_ref(jobject object) {
  if (!object) return;
  std::lock_guard<std::mutex> lock(gate);
  require(global_refs[object] > 0, "JNI global reference released more than once");
  if (active_handle && (active_handle->video == object || active_handle->osd == object)) {
    require(active_handle->terminated, "Surface cleanup preceded native termination");
  }
  --global_refs[object];
}

void detach_event_thread() {
  std::lock_guard<std::mutex> lock(gate);
  require_live(event_handle);
  event_handle->event_exited = true;
  changed.notify_all();
}

void on_static_void_method(jmethodID method, va_list args) {
  require(method == mpv_MpvPlayer_onHook, "unexpected callback in lifecycle scenario");
  const jlong session = va_arg(args, jlong);
  const jstring name = va_arg(args, jstring);
  const jlong hook = va_arg(args, jlong);
  require(name->value == "on_preloaded", "wrong hook callback delivered");
  {
    std::unique_lock<std::mutex> lock(gate);
    require_live(event_handle);
    event_handle->callback_session = session;
    event_handle->callback_entered = true;
    changed.notify_all();
    if (event_handle->reject_hook_during_destroy) {
      // The callback is already inside Java when teardown starts. Kotlin's
      // rejected-channel path continues synchronously on this event thread.
      await(lock, [] { return event_handle->woken; }, "destroy never woke the overlapping hook callback");
    }
  }
  jni_func_name(nativeHookContinue)(&jni, nullptr, session, hook);
  {
    std::lock_guard<std::mutex> lock(gate);
    event_handle->callback_returned = true;
    changed.notify_all();
  }
}

jlong create_player() {
  const jlong session = jni_func_name(nativeCreate)(&jni, nullptr, &app_context);
  require(session > 0, "nativeCreate failed");
  return session;
}

jlong command(jlong session, const char* name = "play") {
  _jstring argument{name};
  _jobjectArray arguments{{&argument}};
  return jni_func_name(nativeCommand)(&jni, nullptr, session, &arguments);
}

void initialize_player(jlong session) {
  require(jni_func_name(nativeInit)(&jni, nullptr, session) == 0, "nativeInit failed");
}

void destroy_player(jlong session) { jni_func_name(nativeDestroy)(&jni, nullptr, session); }

void reset_dependencies() {
  std::lock_guard<std::mutex> lock(gate);
  require(active_handle == nullptr, "previous test left a live MPV instance");
  for (const auto& entry : global_refs) {
    require(entry.first == &app_context || entry.second == 0, "terminal Surface cleanup leaked a global reference");
  }
  handles.clear();
  callback_strings.clear();
  global_refs.clear();
  held_termination = nullptr;
  allow_termination = false;
  allow_command = false;
  successor_waiting = false;
  reader_draining = false;
  fail_thread_create = false;
  jni.exception_pending = false;
}

void rejected_hook_and_successor_retirement() {
  reset_dependencies();
  const jlong old_session = create_player();
  mpv_handle* old = active_handle;
  int video, osd;
  jni_func_name(nativeAttachSurface)(&jni, nullptr, old_session, &video);
  jni_func_name(nativeAttachOsdSurface)(&jni, nullptr, old_session, &osd);
  {
    std::lock_guard<std::mutex> lock(gate);
    old->hook_pending = true;
    old->reject_hook_during_destroy = true;
    held_termination = old;
  }
  initialize_player(old_session);
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [&] { return old->callback_entered; }, "event loop did not deliver the hook");
  }
  std::thread retiring([&] { destroy_player(old_session); });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [&] { return old->termination_entered; }, "retirement deadlocked with the synchronous hook callback");
    require(old->callback_returned && old->event_exited, "termination preceded event-thread completion");
    require(old->callback_session == old_session, "retiring callback lost its bound session");
    require(old->hook_continuations == 0, "revoked hook reached the retiring MPV handle");
    require_surfaces(old);
  }

  jlong successor_session = 0;
  std::thread creating([&] {
    operation = Operation::successor;
    successor_session = create_player();
  });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [] { return successor_waiting; }, "successor did not wait for terminal retirement");
  }
  // S must be available while termination holds L. These calls must reject
  // without touching the retiring core, surfaces, or a future successor.
  require(command(old_session) == MPV_ERROR_UNINITIALIZED, "revoked command was admitted during termination");
  jni_func_name(nativeHookContinue)(&jni, nullptr, old_session, old->hook.id);
  jni_func_name(nativeDetachSurface)(&jni, nullptr, old_session);
  jni_func_name(nativeDetachOsdSurface)(&jni, nullptr, old_session);
  {
    std::lock_guard<std::mutex> lock(gate);
    require_surfaces(old);
    allow_termination = true;
    changed.notify_all();
  }
  retiring.join();
  creating.join();
  require(successor_session > old_session, "successor did not receive a new session");
  mpv_handle* successor = active_handle;
  {
    std::lock_guard<std::mutex> lock(gate);
    successor->hook_pending = true;
  }
  jni_func_name(nativeAttachSurface)(&jni, nullptr, successor_session, &video);
  jni_func_name(nativeAttachOsdSurface)(&jni, nullptr, successor_session, &osd);
  initialize_player(successor_session);
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [&] { return successor->callback_returned; }, "successor event loop did not serve its own hook");
    require(successor->callback_session == successor_session, "successor inherited the old event binding");
    require(successor->hook_continuations == 1, "live hook was not continued exactly once");
  }
  destroy_player(old_session);
  require(
      jni_func_name(nativeInit)(&jni, nullptr, old_session) == MPV_ERROR_UNINITIALIZED, "stale init reached successor");
  require(command(old_session) == MPV_ERROR_UNINITIALIZED, "stale command reached successor");
  jni_func_name(nativeHookContinue)(&jni, nullptr, old_session, old->hook.id);
  jni_func_name(nativeDetachSurface)(&jni, nullptr, old_session);
  jni_func_name(nativeDetachOsdSurface)(&jni, nullptr, old_session);
  require(command(successor_session) == 0, "stale teardown retired the successor");
  {
    std::lock_guard<std::mutex> lock(gate);
    require_surfaces(successor);
    require(successor->hook_continuations == 1, "old hook id was forwarded to successor");
  }
  destroy_player(successor_session);
}

void admitted_command_survives_replacement() {
  reset_dependencies();
  const jlong old_session = create_player();
  mpv_handle* old = active_handle;
  initialize_player(old_session);
  jlong result = MPV_ERROR_GENERIC;
  std::thread reader([&] { result = command(old_session, "hold"); });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [&] { return old->command_active; }, "command was not admitted");
  }
  jlong successor_session = 0;
  std::thread replacing([&] {
    operation = Operation::replacing_reader;
    successor_session = create_player();
  });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [] { return reader_draining; }, "replacement did not drain the admitted command");
    require(!old->termination_entered && !old->woken, "retirement overtook an admitted command");
    allow_command = true;
    changed.notify_all();
  }
  reader.join();
  replacing.join();
  require(result == 0 && old->commands == 1, "admitted command lost its handle before returning");
  require(command(old_session) == MPV_ERROR_UNINITIALIZED, "late old-session command was admitted");
  destroy_player(old_session);
  initialize_player(successor_session);
  require(command(successor_session) == 0, "replacement was affected by stale owner traffic");
  destroy_player(successor_session);
}

void partial_initialization_can_retire() {
  enum class Failure { configuration, initialization, thread_start };
  for (Failure failure : {Failure::configuration, Failure::initialization, Failure::thread_start}) {
    reset_dependencies();
    const jlong session = create_player();
    mpv_handle* failed = active_handle;
    if (failure == Failure::configuration) {
      _jstring invalid{"not-a-level"};
      require(
          jni_func_name(nativeSetLogLevel)(&jni, nullptr, session, &invalid) < 0, "invalid configuration succeeded");
    } else {
      failed->initialize_result = failure == Failure::initialization ? MPV_ERROR_GENERIC : 0;
      fail_thread_create = failure == Failure::thread_start;
      require(jni_func_name(nativeInit)(&jni, nullptr, session) < 0, "injected initialization failure was lost");
      if (failure == Failure::thread_start)
        require(jni.ExceptionCheck(), "thread-start failure lost its JNI exception");
    }
    destroy_player(session);
    require(
        failed->terminated && !failed->event_started && !failed->woken, "partial init used an unstarted event thread");
    require(command(session) == MPV_ERROR_UNINITIALIZED, "failed session retained public admission");
    jni.exception_pending = false;
    const jlong successor = create_player();
    initialize_player(successor);
    require(command(successor) == 0, "partial init prevented the next player from working");
    destroy_player(successor);
  }
}

}  // namespace

// Observe real contention to arrange overlap without sleeps or a guessed
// scheduling delay. The production guards still acquire the real pthread
// locks; the notification only lets the test release its external MPV gates.
static int tracked_mutex_lock(pthread_mutex_t* mutex) {
  if (operation != Operation::successor) return pthread_mutex_lock(mutex);
  const int result = pthread_mutex_trylock(mutex);
  if (result != EBUSY) return result;
  {
    std::lock_guard<std::mutex> lock(gate);
    successor_waiting = true;
    changed.notify_all();
  }
  return pthread_mutex_lock(mutex);
}

static int tracked_write_lock(pthread_rwlock_t* lock) {
  if (operation != Operation::replacing_reader) return pthread_rwlock_wrlock(lock);
  const int result = pthread_rwlock_trywrlock(lock);
  if (result != EBUSY) return result;
  {
    std::lock_guard<std::mutex> guard(gate);
    reader_draining = true;
    changed.notify_all();
  }
  return pthread_rwlock_wrlock(lock);
}

static int controlled_thread_create(pthread_t* thread, const pthread_attr_t* attr, void* (*entry)(void*), void* arg) {
  std::lock_guard<std::mutex> lock(gate);
  if (fail_thread_create) {
    fail_thread_create = false;
    return EAGAIN;
  }
  const int result = pthread_create(thread, attr, entry, arg);
  if (result == 0) active_handle->event_started = true;
  return result;
}

extern "C" mpv_handle* mpv_create() {
  std::lock_guard<std::mutex> lock(gate);
  require(active_handle == nullptr, "successor MPV creation overlapped predecessor termination");
  for (const auto& entry : global_refs) {
    require(entry.first == &app_context || entry.second == 0, "successor creation preceded retiring Surface cleanup");
  }
  handles.push_back(std::make_unique<mpv_handle>());
  active_handle = handles.back().get();
  return active_handle;
}

extern "C" int mpv_initialize(mpv_handle* handle) {
  std::lock_guard<std::mutex> lock(gate);
  require_live(handle);
  if (handle->initialize_result < 0) return handle->initialize_result;
  handle->initialized = true;
  return 0;
}

extern "C" void mpv_wakeup(mpv_handle* handle) {
  std::lock_guard<std::mutex> lock(gate);
  require_live(handle);
  require(!handle->command_active, "wake overtook an admitted command");
  require(handle->event_started, "wake targeted an unstarted event thread");
  handle->woken = true;
  changed.notify_all();
}

extern "C" void mpv_terminate_destroy(mpv_handle* handle) {
  std::unique_lock<std::mutex> lock(gate);
  require_live(handle);
  require(!handle->command_active, "termination overtook an admitted command");
  require(!handle->event_started || handle->event_exited, "termination overtook the bound event thread");
  require_surfaces(handle);
  handle->termination_entered = true;
  changed.notify_all();
  if (handle == held_termination)
    await(lock, [] { return allow_termination; }, "test did not release native termination");
  require_surfaces(handle);
  handle->terminated = true;
  active_handle = nullptr;
}

extern "C" mpv_event* mpv_wait_event(mpv_handle* handle, double) {
  std::unique_lock<std::mutex> lock(gate);
  event_handle = handle;
  require_live(handle);
  await(lock, [&] { return handle->hook_pending || handle->woken; }, "event loop was not woken for teardown");
  handle->event = {};
  if (handle->hook_pending) {
    handle->hook_pending = false;
    handle->event.event_id = MPV_EVENT_HOOK;
    handle->event.data = &handle->hook;
  }
  return &handle->event;
}

extern "C" int mpv_hook_add(mpv_handle* handle, uint64_t, const char*, int) {
  std::lock_guard<std::mutex> lock(gate);
  require_live(handle);
  return 0;
}

extern "C" int mpv_hook_continue(mpv_handle* handle, uint64_t id) {
  std::lock_guard<std::mutex> lock(gate);
  require_live(handle);
  require(id == handle->hook.id && handle->hook_continuations == 0, "hook continued twice or on the wrong handle");
  ++handle->hook_continuations;
  return 0;
}

extern "C" int mpv_command_ret(mpv_handle* handle, const char** args, mpv_node* result) {
  std::unique_lock<std::mutex> lock(gate);
  require_live(handle);
  require(handle->initialized, "command reached an uninitialized core");
  handle->command_active = true;
  changed.notify_all();
  if (std::strcmp(args[0], "hold") == 0)
    await(lock, [] { return allow_command; }, "test did not release admitted command");
  require_live(handle);
  handle->command_active = false;
  ++handle->commands;
  *result = {};
  return 0;
}

extern "C" int mpv_request_log_messages(mpv_handle* handle, const char* level) {
  std::lock_guard<std::mutex> lock(gate);
  require_live(handle);
  return std::strcmp(level, "not-a-level") == 0 ? MPV_ERROR_INVALID_PARAMETER : 0;
}

extern "C" int mpv_set_option(mpv_handle* handle, const char* name, mpv_format format, void* data) {
  std::lock_guard<std::mutex> lock(gate);
  require_live(handle);
  require(format == MPV_FORMAT_INT64, "unexpected Surface option format");
  jobject object = reinterpret_cast<jobject>(static_cast<intptr_t>(*static_cast<int64_t*>(data)));
  if (std::strcmp(name, "wid") == 0) {
    handle->video = object;
  } else {
    require(std::strcmp(name, "vo-mediacodec-osd-surface") == 0, "unexpected Surface option");
    handle->osd = object;
  }
  return 0;
}

extern "C" int mpv_get_property(mpv_handle*, const char*, mpv_format, void*) {
  require(false, "unexpected property read in lifecycle scenario");
  return MPV_ERROR_GENERIC;
}

extern "C" const char* mpv_error_string(int) { return "controlled MPV failure"; }
extern "C" void mpv_free_node_contents(mpv_node*) {}
extern "C" int av_jni_set_java_vm(void*, void*) { return 0; }
extern "C" int av_jni_set_android_app_ctx(void*, void*) { return 0; }
extern "C" int __android_log_print(int, const char*, const char*, ...) { return 0; }

bool acquire_jni_env(JavaVM* supplied_vm, JNIEnv** env) {
  require(supplied_vm == &vm, "event thread acquired the wrong Java VM");
  *env = &jni;
  return true;
}

void init_methods_cache(JNIEnv*) {
  std::lock_guard<std::mutex> lock(gate);
  require(active_handle == nullptr, "JNI environment rewritten before predecessor retirement");
  mpv_MpvPlayer_onHook = reinterpret_cast<jmethodID>(1);
}

jstring new_java_string(JNIEnv*, const char* value) {
  std::lock_guard<std::mutex> lock(gate);
  callback_strings.push_back(std::make_unique<_jstring>(_jstring{value ? value : ""}));
  return callback_strings.back().get();
}

std::string java_string_to_utf8(JNIEnv*, jstring value) { return value ? value->value : ""; }
void die(const char*) { jni.exception_pending = true; }

int main() {
  jni.vm = &vm;
  jni.on_new_global_ref = new_global_ref;
  jni.on_delete_global_ref = delete_global_ref;
  jni.on_static_void_method = on_static_void_method;
  vm.on_detach = detach_event_thread;
  rejected_hook_and_successor_retirement();
  admitted_command_survives_replacement();
  partial_initialization_can_retire();
  reset_dependencies();
  std::puts("MPV lifecycle: callback overlap, reader lifetime, successor isolation and partial init passed");
  return 0;
}
