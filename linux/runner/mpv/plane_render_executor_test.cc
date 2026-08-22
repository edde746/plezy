#include "plane_render_executor.h"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <iostream>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

namespace {

int failures = 0;

void Expect(bool condition, const char* expression, int line) {
  if (condition) return;
  std::cerr << "line " << line << ": check failed: " << expression << '\n';
  ++failures;
}

#define EXPECT(condition) Expect(static_cast<bool>(condition), #condition, __LINE__)

// Each test runs against its own GLib context installed as the thread default,
// which is what the executor captures for completion delivery - exactly how
// the plugin's main context reaches it in production.
class ScopedMainContext {
 public:
  ScopedMainContext() : context_(g_main_context_new()) { g_main_context_push_thread_default(context_); }
  ~ScopedMainContext() {
    g_main_context_pop_thread_default(context_);
    g_main_context_unref(context_);
  }

  GMainContext* get() const { return context_; }

  // Iterates the context until |done| holds or the deadline passes. Completions
  // are GSources on this context, so this is what "the main thread ran" means.
  bool IterateUntil(const std::function<bool()>& done, int timeout_ms = 5000) {
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(timeout_ms);
    while (!done()) {
      if (std::chrono::steady_clock::now() > deadline) return false;
      g_main_context_iteration(context_, FALSE);
    }
    return true;
  }

 private:
  GMainContext* context_;
};

// Jobs must run off the constructing thread; completions must run on the
// constructing thread's context, carrying the job's result.
void TestJobRunsOffThreadAndCompletesOnContext() {
  ScopedMainContext context;
  mpv::PlaneRenderExecutor executor;

  std::atomic<bool> job_ran{false};
  std::thread::id job_thread;
  std::atomic<bool> completed{false};
  bool completion_result = false;
  std::thread::id completion_thread;

  EXPECT(executor.Post(
      [&]() {
        job_thread = std::this_thread::get_id();
        job_ran = true;
        return true;
      },
      [&](bool result) {
        completion_result = result;
        completion_thread = std::this_thread::get_id();
        completed = true;
      }));

  EXPECT(context.IterateUntil([&] { return completed.load(); }));
  EXPECT(job_ran.load());
  EXPECT(job_thread != std::this_thread::get_id());
  EXPECT(completion_thread == std::this_thread::get_id());
  EXPECT(completion_result);
  EXPECT(executor.ShutdownAndJoin(5000));
}

// A job's false lands in its completion untouched: the plugin's completion
// distinguishes a presented frame from a failed render/swap by exactly this.
void TestFailedJobReportsFalse() {
  ScopedMainContext context;
  mpv::PlaneRenderExecutor executor;

  std::atomic<bool> completed{false};
  bool completion_result = true;
  EXPECT(executor.Post([] { return false; },
                       [&](bool result) {
                         completion_result = result;
                         completed = true;
                       }));
  EXPECT(context.IterateUntil([&] { return completed.load(); }));
  EXPECT(!completion_result);
  EXPECT(executor.ShutdownAndJoin(5000));
}

// Jobs and their completions keep their queue order. The plugin only ever has
// one job in flight, but the shutdown-time EGL unbind queues behind a live
// render, and it must not overtake it.
void TestJobsRunInOrder() {
  ScopedMainContext context;
  mpv::PlaneRenderExecutor executor;

  std::vector<int> job_order;
  std::mutex order_mutex;
  std::vector<int> completion_order;
  std::atomic<int> completions{0};

  for (int i = 0; i < 3; ++i) {
    EXPECT(executor.Post(
        [&, i] {
          std::lock_guard<std::mutex> lock(order_mutex);
          job_order.push_back(i);
          return true;
        },
        [&, i](bool) {
          completion_order.push_back(i);
          ++completions;
        }));
  }

  EXPECT(context.IterateUntil([&] { return completions.load() == 3; }));
  EXPECT((job_order == std::vector<int>{0, 1, 2}));
  EXPECT((completion_order == std::vector<int>{0, 1, 2}));
  EXPECT(executor.ShutdownAndJoin(5000));
}

// Shutdown drains what was already queued - that is what makes posting the
// EGL unbind ahead of ShutdownAndJoin sufficient - and refuses anything after.
void TestShutdownDrainsQueuedJobsAndRefusesNewOnes() {
  ScopedMainContext context;
  mpv::PlaneRenderExecutor executor;

  // Hold the worker inside the first job so the second is provably still
  // queued when shutdown begins.
  std::mutex gate_mutex;
  std::condition_variable gate_cv;
  bool gate_open = false;
  std::atomic<bool> second_ran{false};

  EXPECT(executor.Post(
      [&] {
        std::unique_lock<std::mutex> lock(gate_mutex);
        gate_cv.wait(lock, [&] { return gate_open; });
        return true;
      },
      nullptr));
  EXPECT(executor.Post([&] {
    second_ran = true;
    return true;
  },
                       nullptr));

  std::thread opener([&] {
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    {
      std::lock_guard<std::mutex> lock(gate_mutex);
      gate_open = true;
    }
    gate_cv.notify_all();
  });
  EXPECT(executor.ShutdownAndJoin(5000));
  opener.join();
  EXPECT(second_ran.load());
  EXPECT(!executor.Post([] { return true; }, nullptr));
}

// A worker wedged inside a driver call cannot be joined; the executor must
// abandon it within the timeout and say so, because the caller's next move -
// leak instead of free - depends on the answer. The late completion must still
// be deliverable without touching freed executor state.
void TestWedgedJobIsAbandonedNotJoined() {
  ScopedMainContext context;

  std::mutex gate_mutex;
  std::condition_variable gate_cv;
  bool gate_open = false;
  std::atomic<bool> completed{false};

  auto executor = std::make_unique<mpv::PlaneRenderExecutor>();
  EXPECT(executor->Post(
      [&] {
        std::unique_lock<std::mutex> lock(gate_mutex);
        gate_cv.wait(lock, [&] { return gate_open; });
        return true;
      },
      [&](bool) { completed = true; }));

  const auto start = std::chrono::steady_clock::now();
  EXPECT(!executor->ShutdownAndJoin(100));
  EXPECT(std::chrono::steady_clock::now() - start < std::chrono::seconds(4));
  // Destruction after abandonment must not hang or double-join.
  executor.reset();

  // Un-wedge the abandoned thread; its completion should still arrive on the
  // context, proving the thread's own context reference outlived the executor.
  {
    std::lock_guard<std::mutex> lock(gate_mutex);
    gate_open = true;
  }
  gate_cv.notify_all();
  EXPECT(context.IterateUntil([&] { return completed.load(); }));
}

}  // namespace

int main() {
  TestJobRunsOffThreadAndCompletesOnContext();
  TestFailedJobReportsFalse();
  TestJobsRunInOrder();
  TestShutdownDrainsQueuedJobsAndRefusesNewOnes();
  TestWedgedJobIsAbandonedNotJoined();

  if (failures != 0) {
    std::cerr << "plane_render_executor_test: " << failures << " failure(s)\n";
    return 1;
  }
  std::cout << "plane_render_executor_test: PASS\n";
  return 0;
}
