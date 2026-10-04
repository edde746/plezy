#include <pthread.h>

#include <algorithm>
#include <chrono>
#include <condition_variable>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <deque>
#include <functional>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

// Compile the real event loop and record the JNI callbacks it makes, in order.
// Only mpv's event queue is scripted; the lifecycle test's fakes stay
// hook-only, so this is its own executable.
#define UTIL_EXTERN
#include "../../../../libmpv/src/main/cpp/event.cpp"

namespace {

// One event as mpv_wait_event hands it out. mpv owns the data the event
// points at and frees it at the next mpv_wait_event, so every event the fake
// has handed out is poisoned at the next call and kept allocated: a read of
// freed data then returns garbage deterministically instead of depending on
// the allocator.
struct Scripted {
  mpv_event event{};
  std::string name;
  std::string text;
  union {
    int flag;
    int64_t int64;
    double number;
  } value{};
  mpv_event_property property{};
  mpv_event_log_message log{};
  mpv_event_start_file start_file{};
  mpv_event_end_file end_file{};
  mpv_event_hook hook{};
  const char* text_pointer = nullptr;
  // Runs inside the mpv_wait_event call that dequeues this event.
  std::function<void(mpv_handle&)> on_dequeue;
  // Posted only after the drain found the queue empty: a non-blocking wait
  // does not see it, the next blocking wait returns it.
  bool posted_after_drain = false;
};

}  // namespace

struct mpv_handle {
  Session* session = nullptr;
  std::deque<std::unique_ptr<Scripted>> pending;
  std::vector<std::unique_ptr<Scripted>> handed_out;
  // mpv reuses one event struct per client, overwritten by every call.
  mpv_event current{};
  bool woken = false;
  // nativeDestroy wakes the event thread exactly once after setting its exit
  // flag; a blocking wait after that wakeup was consumed never returns.
  bool destroy_wakeup_consumed = false;
  bool idle = false;
  // Supplies another pending event whenever the queue runs dry, modelling a
  // core that keeps logging; returns null once it has stopped.
  std::function<std::unique_ptr<Scripted>()> keep_logging;
};

namespace {

constexpr int64_t kPoison = 0x5a5a5a5a;
constexpr jlong kSessionId = 41;

std::mutex gate;
std::condition_variable changed;
JavaVM vm;
JNIEnv jni;
std::vector<std::string> calls;
bool end_file_forwarded = false;
bool exited = false;
std::vector<std::unique_ptr<_jstring>> java_strings;

void require(bool condition, const char* message) {
  if (condition) return;
  std::fprintf(stderr, "%s\n", message);
  std::abort();
}

template <typename Predicate>
void await(std::unique_lock<std::mutex>& lock, Predicate predicate, const char* message) {
  require(changed.wait_for(lock, std::chrono::seconds(5), predicate), message);
}

// Enumerations get valid but wrong values: a stale read must be visible, and
// an out-of-range enum value would itself be undefined.
void poison(Scripted& scripted) {
  std::fill(scripted.name.begin(), scripted.name.end(), '#');
  std::fill(scripted.text.begin(), scripted.text.end(), '#');
  scripted.value.int64 = kPoison;
  scripted.property.format = MPV_FORMAT_BYTE_ARRAY;
  scripted.log.log_level = MPV_LOG_LEVEL_NONE;
  scripted.start_file.playlist_entry_id = kPoison;
  scripted.end_file.reason = MPV_END_FILE_REASON_REDIRECT;
  scripted.end_file.error = static_cast<int>(kPoison);
  scripted.end_file.playlist_entry_id = kPoison;
  scripted.hook.id = kPoison;
}

std::unique_ptr<Scripted> scripted(mpv_event_id id) {
  auto event = std::make_unique<Scripted>();
  event->event.event_id = id;
  return event;
}

std::unique_ptr<Scripted> posted_after_drain(std::unique_ptr<Scripted> event) {
  event->posted_after_drain = true;
  return event;
}

std::unique_ptr<Scripted> start_file(int64_t entry) {
  auto event = scripted(MPV_EVENT_START_FILE);
  event->start_file.playlist_entry_id = entry;
  event->event.data = &event->start_file;
  return event;
}

std::unique_ptr<Scripted> end_file(mpv_end_file_reason reason, int64_t entry, int error = 0) {
  auto event = scripted(MPV_EVENT_END_FILE);
  event->end_file.reason = reason;
  event->end_file.error = error;
  event->end_file.playlist_entry_id = entry;
  event->event.data = &event->end_file;
  return event;
}

std::unique_ptr<Scripted> log_line(const char* prefix, mpv_log_level level, const char* text) {
  auto event = scripted(MPV_EVENT_LOG_MESSAGE);
  event->name = prefix;
  event->text = text;
  event->log.prefix = event->name.c_str();
  event->log.level = level == MPV_LOG_LEVEL_ERROR ? "error" : "warn";
  event->log.text = event->text.c_str();
  event->log.log_level = level;
  event->event.data = &event->log;
  return event;
}

std::unique_ptr<Scripted> property(const char* name, mpv_format format) {
  auto event = scripted(MPV_EVENT_PROPERTY_CHANGE);
  event->name = name;
  event->property.name = event->name.c_str();
  event->property.format = format;
  event->property.data = format == MPV_FORMAT_NONE ? nullptr : &event->value;
  event->event.data = &event->property;
  return event;
}

std::unique_ptr<Scripted> string_property(const char* name, const char* value) {
  auto event = property(name, MPV_FORMAT_STRING);
  event->text = value;
  event->text_pointer = event->text.c_str();
  event->property.data = &event->text_pointer;
  return event;
}

std::unique_ptr<Scripted> hook(const char* name, uint64_t id) {
  auto event = scripted(MPV_EVENT_HOOK);
  event->name = name;
  event->hook.name = event->name.c_str();
  event->hook.id = id;
  event->event.data = &event->hook;
  return event;
}

std::string text_of(jstring value) { return value ? value->value : "<null>"; }

std::string entry_of(jlong source, int has_source) {
  return has_source ? " entry=" + std::to_string(source) : std::string(" entry=none");
}

// One line per JNI callback, decoded with the argument promotions the real
// CallStaticVoidMethod varargs undergo (jboolean and jint travel as int).
void record(jmethodID method, va_list args) {
  require(va_arg(args, jlong) == kSessionId, "a callback named another session");
  std::ostringstream call;
  if (method == mpv_MpvPlayer_onLogMessage) {
    const jstring prefix = va_arg(args, jstring);
    const int level = va_arg(args, int);
    const jstring text = va_arg(args, jstring);
    call << "log " << level << " [" << text_of(prefix) << "] " << text_of(text);
  } else if (method == mpv_MpvPlayer_onEndFile) {
    const int reason = va_arg(args, int);
    const jlong source = va_arg(args, jlong);
    const int has_source = va_arg(args, int);
    const int error = va_arg(args, int);
    const jstring message = va_arg(args, jstring);
    call << "end-file reason=" << reason << entry_of(source, has_source) << " error=" << error
         << " message=" << text_of(message);
  } else if (method == mpv_MpvPlayer_onEvent) {
    const int id = va_arg(args, int);
    const jlong source = va_arg(args, jlong);
    const int has_source = va_arg(args, int);
    const double position = va_arg(args, double);
    const int has_position = va_arg(args, int);
    call << "event " << id << entry_of(source, has_source);
    if (has_position) call << " position=" << position;
  } else if (method == mpv_MpvPlayer_onHook) {
    const jstring name = va_arg(args, jstring);
    const jlong id = va_arg(args, jlong);
    call << "hook " << text_of(name) << " id=" << id;
  } else {
    const jstring name = va_arg(args, jstring);
    call << "property " << text_of(name) << "=";
    if (method == mpv_MpvPlayer_onPropertyChanged_SJZ) {
      call << "none";
    } else if (method == mpv_MpvPlayer_onPropertyChanged_SZJZ) {
      call << (va_arg(args, int) ? "yes" : "no");
    } else if (method == mpv_MpvPlayer_onPropertyChanged_SJJZ) {
      call << va_arg(args, jlong);
    } else if (method == mpv_MpvPlayer_onPropertyChanged_SDJZ) {
      call << va_arg(args, double);
    } else {
      require(method == mpv_MpvPlayer_onPropertyChanged_SSJZ, "unexpected JNI callback");
      call << '"' << text_of(va_arg(args, jstring)) << '"';
    }
    const jlong source = va_arg(args, jlong);
    call << entry_of(source, va_arg(args, int));
  }
  std::lock_guard<std::mutex> lock(gate);
  if (method == mpv_MpvPlayer_onEndFile) end_file_forwarded = true;
  calls.push_back(call.str());
}

void detach_event_thread() {
  std::lock_guard<std::mutex> lock(gate);
  exited = true;
  changed.notify_all();
}

// Runs the real event thread over [script]. Once it blocks on an empty queue,
// retires it the way nativeDestroy does - exit flag, one wakeup, join - and
// returns the callbacks it made. A thread that exits on its own (a teardown
// the script raced into a wait) is joined without a second wakeup.
std::vector<std::string> run(
    std::vector<std::unique_ptr<Scripted>> script, std::function<std::unique_ptr<Scripted>()> keep_logging = nullptr) {
  mpv_handle handle;
  Session session(static_cast<uint64_t>(kSessionId), &handle);
  handle.session = &session;
  for (auto& event : script) handle.pending.push_back(std::move(event));
  handle.keep_logging = std::move(keep_logging);
  {
    std::lock_guard<std::mutex> lock(gate);
    calls.clear();
    end_file_forwarded = false;
    exited = false;
  }

  pthread_t thread;
  require(pthread_create(&thread, nullptr, event_thread, &session) == 0, "event thread did not start");
  bool exited_on_its_own;
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [&] { return handle.idle || exited; }, "event thread neither consumed the script nor exited");
    exited_on_its_own = exited;
  }
  if (!exited_on_its_own) {
    session.event_thread_exit = true;
    mpv_wakeup(&handle);
  }
  {
    std::unique_lock<std::mutex> lock(gate);
    await(lock, [] { return exited; }, "event thread did not exit after nativeDestroy's wakeup");
  }
  require(pthread_join(thread, nullptr) == 0, "event thread did not join");
  std::lock_guard<std::mutex> lock(gate);
  java_strings.clear();
  return calls;
}

template <typename... Events>
std::vector<std::unique_ptr<Scripted>> script(Events... events) {
  std::vector<std::unique_ptr<Scripted>> list;
  (list.push_back(std::move(events)), ...);
  return list;
}

void require_calls(
    const std::vector<std::string>& actual, const std::vector<std::string>& expected, const char* scenario) {
  if (actual == expected) return;
  std::fprintf(stderr, "%s\nexpected:\n", scenario);
  for (const auto& call : expected) std::fprintf(stderr, "  %s\n", call.c_str());
  std::fprintf(stderr, "actual:\n");
  for (const auto& call : actual) std::fprintf(stderr, "  %s\n", call.c_str());
  std::abort();
}

// mpv hands out a client's queued events and property changes before any line
// in its separate log buffer, so an event thread that fell behind dequeues a
// failed open's END_FILE ahead of the lines explaining it - and ahead of the
// next entry's events. The lines must still reach Kotlin first, the held
// events must keep their order and the entry they belong to, and events that
// arrive after the drain must belong to the entry its replay started.
void error_end_file_follows_the_lines_that_explain_it() {
  auto seekable = property("seekable", MPV_FORMAT_FLAG);
  seekable->value.flag = 1;
  const auto calls = run(script(
      start_file(7), end_file(MPV_END_FILE_REASON_ERROR, 7, MPV_ERROR_LOADING_FAILED),
      string_property("path", "http://127.0.0.1/missing.mkv"), start_file(8),
      log_line("ffmpeg", MPV_LOG_LEVEL_WARN, "http: HTTP error 404 Not Found"),
      log_line("stream", MPV_LOG_LEVEL_ERROR, "Failed to open http://127.0.0.1/missing.mkv."),
      posted_after_drain(scripted(MPV_EVENT_FILE_LOADED)), posted_after_drain(std::move(seekable))));
  require_calls(
      calls,
      {
          "event 6 entry=7",
          "log 30 [ffmpeg] http: HTTP error 404 Not Found",
          "log 20 [stream] Failed to open http://127.0.0.1/missing.mkv.",
          "end-file reason=4 entry=7 error=-13 message=loading failed",
          "property path=\"http://127.0.0.1/missing.mkv\" entry=7",
          "event 6 entry=8",
          "event 8 entry=8",
          "property seekable=yes entry=8",
      },
      "a failed open's end-file overtook its log lines");
}

// Every kind the forwarders read survives being held behind the end-file,
// although mpv freed its data at the drain's next wait.
void held_events_replay_the_values_they_were_dequeued_with() {
  auto flag = property("idle-active", MPV_FORMAT_FLAG);
  flag->value.flag = 1;
  auto count = property("playlist-count", MPV_FORMAT_INT64);
  count->value.int64 = 3;
  auto duration = property("duration", MPV_FORMAT_DOUBLE);
  duration->value.number = 2.5;
  const auto calls = run(script(
      start_file(7), end_file(MPV_END_FILE_REASON_ERROR, 7, MPV_ERROR_LOADING_FAILED), std::move(flag),
      std::move(count), std::move(duration), property("track-list", MPV_FORMAT_NONE), start_file(8),
      hook("on_preloaded", 17), scripted(MPV_EVENT_FILE_LOADED), scripted(MPV_EVENT_PLAYBACK_RESTART),
      end_file(MPV_END_FILE_REASON_EOF, 8), log_line("stream", MPV_LOG_LEVEL_ERROR, "Failed to open 7.")));
  require_calls(
      calls,
      {
          "event 6 entry=7",
          "log 20 [stream] Failed to open 7.",
          "end-file reason=4 entry=7 error=-13 message=loading failed",
          "property idle-active=yes entry=7",
          "property playlist-count=3 entry=7",
          "property duration=2.5 entry=7",
          "property track-list=none entry=7",
          "event 6 entry=8",
          "hook on_preloaded id=17",
          "event 8 entry=8",
          "event 21 entry=8 position=12.5",
          "end-file reason=0 entry=8 error=0 message=<null>",
      },
      "a held event lost its data or order");
}

// On `loadfile replace` the old file's stop end-file precedes the new file's
// START_FILE. Draining there would pull the new open's failure lines ahead of
// the START_FILE that resets the latch, discarding them.
void a_stop_end_file_is_not_drained() {
  const auto calls = run(script(
      end_file(MPV_END_FILE_REASON_STOP, 7), start_file(8),
      log_line("stream", MPV_LOG_LEVEL_ERROR, "Failed to open 8.")));
  require_calls(
      calls,
      {
          "end-file reason=2 entry=7 error=0 message=<null>",
          "event 6 entry=8",
          "log 20 [stream] Failed to open 8.",
      },
      "a stop end-file pulled the next file's lines ahead of its start-file");
}

// nativeDestroy sets the exit flag and wakes the thread once. A drain's
// non-blocking wait can consume that wakeup; the thread must still exit rather
// than block in a wait nothing will end, which would hang the join.
void teardown_during_a_drain_still_exits() {
  auto line = log_line("stream", MPV_LOG_LEVEL_ERROR, "Failed to open 7.");
  line->on_dequeue = [](mpv_handle& handle) {
    handle.session->event_thread_exit = true;
    handle.woken = true;
  };
  run(script(end_file(MPV_END_FILE_REASON_ERROR, 7, MPV_ERROR_LOADING_FAILED), std::move(line)));
}

// A core that keeps logging cannot hold a failed file's end-file back forever,
// yet the drain must take everything mpv can have buffered: at the verbose
// level 10000 lines, preceded by the overflow notice mpv reads out once it had
// to drop older ones. The explaining lines are the newest, so a drain that
// stops earlier leaves exactly them behind the end-file.
void a_full_verbose_log_buffer_drains_ahead_of_the_end_file() {
  constexpr int kFullVerboseBuffer = 10000 + 1;
  int lines = 0;
  const auto calls = run(script(end_file(MPV_END_FILE_REASON_ERROR, 7, MPV_ERROR_LOADING_FAILED)), [&lines] {
    if (end_file_forwarded) return std::unique_ptr<Scripted>();
    require(++lines <= kFullVerboseBuffer, "the end-file waited behind more lines than mpv can buffer");
    return lines == 1 ? log_line("overflow", MPV_LOG_LEVEL_FATAL, "log message buffer overflow: 12 messages skipped")
                      : log_line("cplayer", MPV_LOG_LEVEL_V, "still logging");
  });
  require(lines == kFullVerboseBuffer, "the end-file overtook lines still in mpv's verbose log buffer");
  require(calls.size() == static_cast<size_t>(lines) + 1, "a line was lost while draining");
  require(calls.back().rfind("end-file reason=4", 0) == 0, "the end-file never followed the lines");
}

}  // namespace

JavaVM* g_vm = &vm;

extern "C" mpv_event* mpv_wait_event(mpv_handle* handle, double timeout) {
  std::unique_lock<std::mutex> lock(gate);
  if (!handle->handed_out.empty()) poison(*handle->handed_out.back());
  handle->current = {};
  if (handle->pending.empty() && handle->keep_logging) {
    if (auto line = handle->keep_logging()) handle->pending.push_back(std::move(line));
  }
  if (timeout != 0 && handle->pending.empty() && !handle->woken) {
    require(
        !handle->destroy_wakeup_consumed,
        "event thread blocked after consuming nativeDestroy's only wakeup; its join would never return");
    handle->idle = true;
    changed.notify_all();
    await(lock, [&] { return handle->woken || !handle->pending.empty(); }, "blocking wait was never woken");
    handle->idle = false;
  }
  const bool visible = !handle->pending.empty() && (timeout != 0 || !handle->pending.front()->posted_after_drain);
  if (visible) {
    std::unique_ptr<Scripted> next = std::move(handle->pending.front());
    handle->pending.pop_front();
    if (next->on_dequeue) next->on_dequeue(*handle);
    handle->current = next->event;
    handle->handed_out.push_back(std::move(next));
  }
  // Every return clears a queued wakeup, including one that returns an event
  // (client.c, mpv_wait_event).
  if (handle->woken && handle->session->event_thread_exit) handle->destroy_wakeup_consumed = true;
  handle->woken = false;
  return &handle->current;
}

extern "C" void mpv_wakeup(mpv_handle* handle) {
  std::lock_guard<std::mutex> lock(gate);
  handle->woken = true;
  changed.notify_all();
}

extern "C" int mpv_get_property(mpv_handle*, const char* name, mpv_format format, void* data) {
  require(std::string(name) == "time-pos" && format == MPV_FORMAT_DOUBLE, "unexpected property read");
  *static_cast<double*>(data) = 12.5;
  return 0;
}

extern "C" const char* mpv_error_string(int error) {
  return error == MPV_ERROR_LOADING_FAILED ? "loading failed" : "unexpected error";
}

bool acquire_jni_env(JavaVM* supplied_vm, JNIEnv** env) {
  require(supplied_vm == &vm, "event thread acquired the wrong Java VM");
  *env = &jni;
  return true;
}

jstring new_java_string(JNIEnv*, const char* value) {
  if (!value) return nullptr;
  std::lock_guard<std::mutex> lock(gate);
  java_strings.push_back(std::make_unique<_jstring>(_jstring{value}));
  return java_strings.back().get();
}

void die(const char* message) { require(false, message); }

int main() {
  int next_method = 0;
  for (jmethodID* method :
       {&mpv_MpvPlayer_onPropertyChanged_SJZ, &mpv_MpvPlayer_onPropertyChanged_SZJZ,
        &mpv_MpvPlayer_onPropertyChanged_SJJZ, &mpv_MpvPlayer_onPropertyChanged_SDJZ,
        &mpv_MpvPlayer_onPropertyChanged_SSJZ, &mpv_MpvPlayer_onEvent, &mpv_MpvPlayer_onEndFile,
        &mpv_MpvPlayer_onLogMessage, &mpv_MpvPlayer_onHook}) {
    *method = reinterpret_cast<jmethodID>(static_cast<uintptr_t>(++next_method));
  }
  jni.vm = &vm;
  jni.on_static_void_method = record;
  vm.on_detach = detach_event_thread;
  error_end_file_follows_the_lines_that_explain_it();
  held_events_replay_the_values_they_were_dequeued_with();
  a_stop_end_file_is_not_drained();
  teardown_during_a_drain_still_exits();
  a_full_verbose_log_buffer_drains_ahead_of_the_end_file();
  std::puts("MPV event order: error lines before end-file, held replay, stop undrained, teardown, full-buffer drain");
  return 0;
}
