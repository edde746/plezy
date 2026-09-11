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
#define pthread_mutex_lock tracked_mutex_lock
#include "../../../../libmpv/src/main/cpp/render.cpp"
#undef pthread_mutex_lock

struct mpv_handle {
  bool initialized = false;
  bool terminated = false;
  bool live = false;
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
  jobject osd_option = nullptr;
  std::string vo = "mediacodec";
  int rebuilds = 0;
  mpv_event_hook hook{"on_preloaded", 17};
  mpv_event event{};
};

namespace {

std::mutex gate;
std::condition_variable changed;
JavaVM vm;
JNIEnv jni;
int app_context;
// The most recently created handle. Sessions are independent, so more than one
// can be live at a time and "the" handle is only ever the newest; liveness is
// [mpv_handle::live], never identity against this.
mpv_handle* latest_handle = nullptr;
// Retain fake allocations after termination so any erroneous late MPV access
// fails explicitly rather than depending on allocator reuse or undefined UAF.
std::vector<std::unique_ptr<mpv_handle>> handles;
std::vector<std::unique_ptr<_jstring>> callback_strings;
// Each NewGlobalRef is a distinct handle, even for the same Java Surface.
std::vector<std::unique_ptr<jobject>> reference_handles;
std::map<jobject, jobject> global_refs;
int fail_ref_after = 0;
std::vector<std::string> option_failures;
bool consume_osd_before_failure = false;
bool hold_wid = false;
bool wid_entered = false;
bool allow_wid = false;
bool surface_waiting = false;
mpv_handle* held_termination = nullptr;
bool allow_termination = false;
bool allow_command = false;
bool reader_draining = false;
bool fail_thread_create = false;
// Process-wide JNI wiring runs under std::call_once, so this stays 1 for the
// whole run no matter how many sessions are created.
int methods_cache_inits = 0;
thread_local mpv_handle* event_handle = nullptr;
enum class Operation { ordinary, retiring_reader, surface_handoff };
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

void require_live(mpv_handle* handle) { require(handle && handle->live, "MPV accessed outside its native lifetime"); }

void require_surfaces(mpv_handle* handle) {
  for (jobject ref : {handle->video, handle->osd, handle->osd_option}) {
    if (ref) require(global_refs.count(ref) == 1, "Surface option/consumer retained a deleted JNI reference");
  }
}

jobject new_global_ref(jobject object) {
  std::lock_guard<std::mutex> lock(gate);
  if (!object) return nullptr;
  if (fail_ref_after > 0 && --fail_ref_after == 0) return nullptr;
  reference_handles.push_back(std::make_unique<jobject>(object));
  jobject ref = reference_handles.back().get();
  global_refs.emplace(ref, object);
  return ref;
}

void delete_global_ref(jobject object) {
  if (!object) return;
  std::lock_guard<std::mutex> lock(gate);
  require(global_refs.count(object) == 1, "JNI global reference released more than once");
  for (const auto& entry : handles) {
    mpv_handle* handle = entry.get();
    if (handle->video != object && handle->osd != object && handle->osd_option != object) continue;
    require(handle->terminated, "Surface released while still referenced by MPV");
  }
  global_refs.erase(object);
}

jboolean is_same_object(jobject a, jobject b) {
  std::lock_guard<std::mutex> lock(gate);
  auto resolve = [](jobject object) {
    const auto it = global_refs.find(object);
    return it == global_refs.end() ? object : it->second;
  };
  return resolve(a) == resolve(b) ? JNI_TRUE : JNI_FALSE;
}

int live_surface_refs() {
  int count = 0;
  for (const auto& entry : global_refs) {
    if (entry.second != &app_context) ++count;
  }
  return count;
}

void require_pair(mpv_handle* handle, jobject video, jobject osd) {
  require_surfaces(handle);
  require(global_refs.at(handle->video) == video, "VO retained the wrong video Surface");
  require((handle->osd ? global_refs.at(handle->osd) : nullptr) == osd, "VO retained the wrong OSD Surface");
  require(handle->osd_option == handle->osd, "OSD option and active consumer disagree");
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

// An empty renderer is a surface handoff; a named one is a renderer switch
// that must keep the attached video Surface.
jint attach_surfaces(
    jlong session, jobject video, jobject osd, const char* vo = "", jlong video_generation = 1,
    jlong osd_generation = 1) {
  _jstring renderer{vo};
  return jni_func_name(nativeAttachSurfaces)(
      &jni, nullptr, session, video, osd, video_generation, osd_generation, &renderer);
}

void reset_dependencies() {
  std::lock_guard<std::mutex> lock(gate);
  for (const auto& entry : handles) require(!entry->live, "previous test left a live MPV instance");
  require(live_surface_refs() == 0, "terminal Surface cleanup leaked a global reference");
  handles.clear();
  callback_strings.clear();
  global_refs.clear();
  reference_handles.clear();
  fail_ref_after = 0;
  option_failures.clear();
  consume_osd_before_failure = false;
  hold_wid = false;
  wid_entered = false;
  allow_wid = false;
  surface_waiting = false;
  held_termination = nullptr;
  allow_termination = false;
  allow_command = false;
  reader_draining = false;
  fail_thread_create = false;
  jni.exception_pending = false;
}

// A retirement that never returns must cost only its own session: the next one
// is built, initialized and played while the wedged one is still inside
// mpv_terminate_destroy, and every entry naming the retiring session rejects.
void wedged_retirement_does_not_block_the_next_session() {
  reset_dependencies();
  const jlong old_session = create_player();
  mpv_handle* old = latest_handle;
  int video, osd;
  require(attach_surfaces(old_session, &video, &osd) == 0, "initial surface handoff failed");
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

  // Creation consults nothing. This is the freeze: on one global mpv handle
  // behind one lifecycle lock, nativeCreate blocked on the lock the wedged
  // termination below is holding, and playback stayed dead until a restart.
  const jlong successor_session = create_player();
  require(successor_session > old_session, "successor did not receive a new session");
  mpv_handle* successor = latest_handle;
  require(successor != old, "successor reused the retiring handle");

  // Admission is revoked and its readers have drained, so every entry naming
  // the retiring session must reject without touching its core or Surfaces.
  require(command(old_session) == MPV_ERROR_UNINITIALIZED, "revoked command was admitted during termination");
  jni_func_name(nativeHookContinue)(&jni, nullptr, old_session, old->hook.id);
  require(
      attach_surfaces(old_session, nullptr, nullptr) == MPV_ERROR_UNINITIALIZED,
      "revoked surface handoff was admitted during termination");

  int successor_video, successor_osd;
  {
    std::lock_guard<std::mutex> lock(gate);
    require_surfaces(old);
    successor->hook_pending = true;
  }
  require(
      attach_surfaces(successor_session, &successor_video, &successor_osd) == 0, "successor surface handoff failed");
  initialize_player(successor_session);
  require(command(successor_session) == 0, "successor could not play while its predecessor was wedged");
  {
    std::lock_guard<std::mutex> lock(gate);
    // The wedged session keeps its own Surfaces: freeing a Surface a live
    // decoder may still be writing into is worse than leaking it.
    require_surfaces(old);
    require_pair(successor, &successor_video, &successor_osd);
    allow_termination = true;
    changed.notify_all();
  }
  retiring.join();
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
  require(
      attach_surfaces(old_session, nullptr, nullptr) == MPV_ERROR_UNINITIALIZED,
      "stale surface handoff reached successor");
  require(command(successor_session) == 0, "stale teardown retired the successor");
  {
    std::lock_guard<std::mutex> lock(gate);
    require_surfaces(successor);
    require(successor->hook_continuations == 1, "old hook id was forwarded to successor");
  }
  destroy_player(successor_session);
}

// Retirement is what revokes admission now, not the arrival of a successor, so
// nativeDestroy is the operation that has to drain an in-flight command before
// it wakes, joins and terminates.
void admitted_command_survives_retirement() {
  reset_dependencies();
  const jlong session = create_player();
  mpv_handle* handle = latest_handle;
  initialize_player(session);
  jlong result = MPV_ERROR_GENERIC;
  std::thread reader([&] { result = command(session, "hold"); });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [&] { return handle->command_active; }, "command was not admitted");
  }
  std::thread retiring([&] {
    operation = Operation::retiring_reader;
    destroy_player(session);
  });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [] { return reader_draining; }, "retirement did not drain the admitted command");
    require(!handle->termination_entered && !handle->woken, "retirement overtook an admitted command");
    allow_command = true;
    changed.notify_all();
  }
  reader.join();
  retiring.join();
  require(result == 0 && handle->commands == 1, "admitted command lost its handle before returning");
  require(command(session) == MPV_ERROR_UNINITIALIZED, "late command reached the retired session");

  const jlong successor = create_player();
  initialize_player(successor);
  require(command(successor) == 0, "the retired session's traffic affected its successor");
  destroy_player(successor);
}

void partial_initialization_can_retire() {
  enum class Failure { configuration, initialization, thread_start };
  for (Failure failure : {Failure::configuration, Failure::initialization, Failure::thread_start}) {
    reset_dependencies();
    const jlong session = create_player();
    mpv_handle* failed = latest_handle;
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

void paired_surface_replacements() {
  reset_dependencies();
  const jlong session = create_player();
  initialize_player(session);
  mpv_handle* handle = latest_handle;
  int video_a, video_b, osd_a, osd_b;
  require(attach_surfaces(session, &video_a, &osd_a) == 0, "initial paired handoff failed");
  require_pair(handle, &video_a, &osd_a);
  require(attach_surfaces(session, &video_b, &osd_b) == 0, "paired replacement failed");
  require_pair(handle, &video_b, &osd_b);
  for (jobject next_osd : {static_cast<jobject>(&osd_a), static_cast<jobject>(nullptr), static_cast<jobject>(&osd_b)}) {
    const int rebuilds = handle->rebuilds;
    require(attach_surfaces(session, &video_b, next_osd) == 0, "OSD-only replacement failed");
    require_pair(handle, &video_b, next_osd);
    require(handle->rebuilds == rebuilds, "OSD-only change rebuilt the video output");
    require(live_surface_refs() == (next_osd ? 2 : 1), "replacement leaked overwritten Surface references");
  }
  const int rebuilds = handle->rebuilds;
  const jobject video_ref = handle->video;
  require(attach_surfaces(session, &video_b, &osd_b) == 0, "identical surface refresh failed");
  require(handle->video == video_ref && handle->rebuilds == rebuilds, "identical refresh rebuilt the decoder");
  require(attach_surfaces(session, &video_b, &osd_b, "", 2, 1) == 0, "new video generation failed");
  require(handle->rebuilds == rebuilds + 1, "reused Java Surface hid a new native video lifetime");
  const jobject osd_ref = handle->osd;
  require(attach_surfaces(session, &video_b, &osd_b, "", 2, 2) == 0, "new OSD generation failed");
  require(handle->osd != osd_ref && handle->rebuilds == rebuilds + 1, "OSD generation change rebuilt video");
  destroy_player(session);
}

// A renderer switch rebuilds through the vo option against the attached video
// Surface stays attached while OSD rebinding acknowledges its own producer.
void renderer_switch_retains_the_video_surface() {
  reset_dependencies();
  const jlong session = create_player();
  initialize_player(session);
  mpv_handle* handle = latest_handle;
  int video_a, video_b, osd_a, osd_b;
  require(
      attach_surfaces(session, &video_a, &osd_a, "gpu") == MPV_ERROR_INVALID_PARAMETER,
      "renderer switch admitted before any video Surface was attached");
  require(live_surface_refs() == 0, "rejected renderer switch leaked references");
  require(attach_surfaces(session, &video_a, &osd_a) == 0, "initial paired handoff failed");
  const jobject attached_video = handle->video;

  require(
      attach_surfaces(session, &video_b, &osd_b, "gpu") == MPV_ERROR_INVALID_PARAMETER,
      "renderer switch admitted a different video Surface");
  require_pair(handle, &video_a, &osd_a);
  require(live_surface_refs() == 2, "rejected renderer switch leaked references");

  int rebuilds = handle->rebuilds;
  require(attach_surfaces(session, &video_a, &osd_b, "gpu") == 0, "renderer switch failed");
  require(handle->vo == "gpu", "renderer switch did not rewrite vo");
  require(handle->video == attached_video, "renderer switch replaced the attached video reference");
  require_pair(handle, &video_a, &osd_b);
  require(handle->rebuilds == rebuilds + 1, "renderer switch did not rebuild the VO");
  require(live_surface_refs() == 2, "renderer switch leaked the previous OSD reference");

  // Same renderer: replace only the OSD consumer, retaining the decoder.
  rebuilds = handle->rebuilds;
  require(attach_surfaces(session, &video_a, &osd_a, "gpu") == 0, "handoff under the active renderer failed");
  require(handle->vo == "gpu", "handoff under the active renderer rewrote vo");
  require(handle->video == attached_video, "OSD handoff replaced the video reference");
  require_pair(handle, &video_a, &osd_a);
  require(handle->rebuilds == rebuilds, "OSD handoff rebuilt the decoder");
  require(live_surface_refs() == 2, "handoff under the active renderer leaked references");

  // A failed vo write rolls the OSD option back and keeps the attached video;
  // the staged OSD ref is retained until the next successful rebuild, as a
  // consumer may have been created between the two writes.
  const jobject retained_video = handle->video;
  option_failures = {"vo"};
  require(attach_surfaces(session, &video_a, &osd_b, "mediacodec") == MPV_ERROR_GENERIC, "vo failure was lost");
  require(handle->vo == "gpu" && handle->video == retained_video, "failed renderer switch changed the VO");
  require_pair(handle, &video_a, &osd_a);
  require(attach_surfaces(session, &video_a, &osd_b, "mediacodec") == 0, "renderer switch did not recover");
  require(handle->vo == "mediacodec", "recovered renderer switch did not rewrite vo");
  require_pair(handle, &video_a, &osd_b);
  require(live_surface_refs() == 2, "recovered renderer switch retained failed references");
  destroy_player(session);
}

void surface_handoff_failures() {
  reset_dependencies();
  const jlong session = create_player();
  initialize_player(session);
  mpv_handle* handle = latest_handle;
  int video_a, video_b, osd_a, osd_b;
  require(attach_surfaces(session, &video_a, &osd_a) == 0, "initial paired handoff failed");
  require(
      attach_surfaces(session, nullptr, &osd_b) == MPV_ERROR_INVALID_PARAMETER,
      "live session admitted a null video Surface");
  for (int allocation : {1, 2}) {
    fail_ref_after = allocation;
    require(
        attach_surfaces(session, &video_b, &osd_b) == MPV_ERROR_NOMEM, "global-reference allocation failure was lost");
    require_pair(handle, &video_a, &osd_a);
    require(live_surface_refs() == 2, "allocation failure leaked a staged Surface");
  }
  option_failures = {"vo-mediacodec-osd-surface"};
  require(attach_surfaces(session, &video_b, &osd_b) == MPV_ERROR_GENERIC, "OSD option failure was lost");
  require_pair(handle, &video_a, &osd_a);
  require(live_surface_refs() == 2, "rejected OSD option leaked staged references");

  option_failures = {"wid"};
  require(attach_surfaces(session, &video_b, &osd_b) == MPV_ERROR_GENERIC, "wid option failure was lost");
  require_pair(handle, &video_a, &osd_a);
  require(attach_surfaces(session, &video_b, &osd_b) == 0, "handoff did not recover from wid failure");
  require_pair(handle, &video_b, &osd_b);
  require(live_surface_refs() == 2, "successful replacement retained failed handoff references");

  // A VO can start between option writes. A failed rollback leaves its staged
  // reference live until a later successful handoff or full destruction.
  consume_osd_before_failure = true;
  for (bool fail_rollback : {false, true}) {
    option_failures = {"wid"};
    if (fail_rollback) option_failures.push_back("vo-mediacodec-osd-surface");
    require(attach_surfaces(session, &video_a, &osd_a) == MPV_ERROR_GENERIC, "failed handoff reported success");
    require(option_failures.empty(), "OSD option rollback was not attempted");
    require_surfaces(handle);
  }
  require(attach_surfaces(session, &video_a, nullptr) == 0, "handoff did not recover from rollback failure");
  require_pair(handle, &video_a, nullptr);
  require(live_surface_refs() == 1, "successful null-OSD replacement leaked failed handoff references");

  option_failures = {"wid", "vo-mediacodec-osd-surface"};
  require(attach_surfaces(session, &video_b, &osd_b) < 0, "terminal failed handoff reported success");
  destroy_player(session);
  require(live_surface_refs() == 0, "termination leaked pending failed-handoff references");
}

void overlapping_handoffs_and_teardown() {
  reset_dependencies();
  const jlong session = create_player();
  initialize_player(session);
  mpv_handle* handle = latest_handle;
  int video_a, video_b, video_c, osd_a, osd_b, osd_c;
  require(attach_surfaces(session, &video_a, &osd_a) == 0, "initial paired handoff failed");
  hold_wid = true;
  jint first_result = MPV_ERROR_GENERIC, second_result = MPV_ERROR_GENERIC;
  std::thread first([&] { first_result = attach_surfaces(session, &video_b, &osd_b); });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [] { return wid_entered; }, "first handoff did not enter synchronous VO rebuild");
    require_surfaces(handle);
    require(live_surface_refs() == 4, "old Surface references did not survive the wid rebuild");
  }
  std::thread second([&] {
    operation = Operation::surface_handoff;
    second_result = attach_surfaces(session, &video_c, &osd_c);
  });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [] { return surface_waiting; }, "overlapping handoff bypassed surface serialization");
    require(live_surface_refs() == 4, "waiting handoff mutated active Surface references");
  }
  std::thread retiring([&] {
    operation = Operation::retiring_reader;
    destroy_player(session);
  });
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [] { return reader_draining; }, "teardown did not drain admitted surface handoffs");
    require(!handle->termination_entered, "teardown overtook an admitted surface handoff");
    allow_wid = true;
    changed.notify_all();
  }
  first.join();
  second.join();
  retiring.join();
  require(first_result == 0 && second_result == 0, "admitted handoff lost its session during teardown");
  require(handle->rebuilds == 3, "overlapping handoffs lost a complete VO rebuild");
  require(live_surface_refs() == 0, "overlapping replacement/teardown leaked Surface references");
}

}  // namespace

// Observe real contention to arrange overlap without sleeps or a guessed
// scheduling delay. The production guards still acquire the real pthread
// locks; the notification only lets the test release its external MPV gates.
static int tracked_mutex_lock(pthread_mutex_t* mutex) {
  if (operation != Operation::surface_handoff) return pthread_mutex_lock(mutex);
  const int result = pthread_mutex_trylock(mutex);
  if (result != EBUSY) return result;
  {
    std::lock_guard<std::mutex> lock(gate);
    surface_waiting = true;
    changed.notify_all();
  }
  return pthread_mutex_lock(mutex);
}

static int tracked_write_lock(pthread_rwlock_t* lock) {
  if (operation != Operation::retiring_reader) return pthread_rwlock_wrlock(lock);
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
  // The event thread is started for one specific session, which is not
  // necessarily the newest one.
  if (result == 0) static_cast<Session*>(arg)->handle->event_started = true;
  return result;
}

extern "C" mpv_handle* mpv_create() {
  std::lock_guard<std::mutex> lock(gate);
  // Nothing is asserted about predecessors. A session still terminating - even
  // one wedged forever - owns nothing this one needs, and it keeps its own
  // Surfaces referenced until its own teardown frees them.
  handles.push_back(std::make_unique<mpv_handle>());
  latest_handle = handles.back().get();
  latest_handle->live = true;
  return latest_handle;
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
  handle->live = false;
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
  std::unique_lock<std::mutex> lock(gate);
  require_live(handle);
  require_surfaces(handle);
  require(format == MPV_FORMAT_INT64, "unexpected Surface option format");
  jobject object = reinterpret_cast<jobject>(static_cast<uintptr_t>(*static_cast<int64_t*>(data)));
  require(!object || global_refs.count(object) == 1, "option received an invalid JNI reference");
  const bool is_wid = std::strcmp(name, "wid") == 0;
  if (is_wid && hold_wid) {
    wid_entered = true;
    changed.notify_all();
    await(lock, [] { return allow_wid; }, "test did not release the synchronous wid rebuild");
    require_surfaces(handle);
  }
  if (!option_failures.empty() && option_failures.front() == name) {
    option_failures.erase(option_failures.begin());
    if (is_wid && consume_osd_before_failure) handle->osd = handle->osd_option;
    return MPV_ERROR_GENERIC;
  }
  if (is_wid) {
    // mpv ignores equal option values; changing wid synchronously retires the
    // consumers and rebuilds using the OSD option, not the former OSD plane.
    if (handle->video != object) {
      handle->video = object;
      handle->osd = handle->osd_option;
      ++handle->rebuilds;
    }
  } else {
    require(std::strcmp(name, "vo-mediacodec-osd-surface") == 0, "unexpected Surface option");
    handle->osd_option = object;
    // UPDATE_VIDEO returns only after the active OSD consumer has retired.
    handle->osd = object;
  }
  return 0;
}

extern "C" int mpv_get_property(mpv_handle*, const char*, mpv_format, void*) {
  require(false, "unexpected property read in lifecycle scenario");
  return MPV_ERROR_GENERIC;
}

// The renderer switch reads the active vo and rewrites it; like wid, the vo
// option has UPDATE_VO and rebuilds against the staged OSD option while the
// video Surface stays attached.
extern "C" char* mpv_get_property_string(mpv_handle* handle, const char* name) {
  std::lock_guard<std::mutex> lock(gate);
  require_live(handle);
  require(std::strcmp(name, "vo") == 0, "unexpected string property read in lifecycle scenario");
  return strdup(handle->vo.c_str());
}

extern "C" void mpv_free(void* data) { std::free(data); }

extern "C" int mpv_set_option_string(mpv_handle* handle, const char* name, const char* value) {
  std::lock_guard<std::mutex> lock(gate);
  require_live(handle);
  require_surfaces(handle);
  require(std::strcmp(name, "vo") == 0, "unexpected string option");
  if (!option_failures.empty() && option_failures.front() == name) {
    option_failures.erase(option_failures.begin());
    return MPV_ERROR_GENERIC;
  }
  require(handle->vo != value, "renderer switch rewrote the active vo");
  handle->vo = value;
  handle->osd = handle->osd_option;
  ++handle->rebuilds;
  return 0;
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
  require(++methods_cache_inits == 1, "process JNI wiring was rebuilt for a second session");
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
  jni.on_is_same_object = is_same_object;
  jni.on_static_void_method = on_static_void_method;
  vm.on_detach = detach_event_thread;
  wedged_retirement_does_not_block_the_next_session();
  admitted_command_survives_retirement();
  partial_initialization_can_retire();
  paired_surface_replacements();
  renderer_switch_retains_the_video_surface();
  surface_handoff_failures();
  overlapping_handoffs_and_teardown();
  reset_dependencies();
  std::puts("MPV lifecycle: wedged-session recovery, paired handoffs, rollback ownership, overlapping teardown");
  return 0;
}
