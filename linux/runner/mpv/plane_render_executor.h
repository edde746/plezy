#ifndef PLEZY_LINUX_MPV_PLANE_RENDER_EXECUTOR_H_
#define PLEZY_LINUX_MPV_PLANE_RENDER_EXECUTOR_H_

#include <glib.h>

#include <condition_variable>
#include <deque>
#include <functional>
#include <memory>
#include <mutex>
#include <thread>
#include <utility>

namespace mpv {

// The video plane's render worker (issue #2057).
//
// mpv's render + the plane's eglSwapBuffers used to run on the GTK main
// thread, which also rasters Flutter's UI and dispatches input. A cheap frame
// hides that; a 4K HDR tone-map does not - input reads batch at video-render
// boundaries and every UI repaint waits out the render. This worker exists to
// take exactly that GL work off the main thread. Everything else about the
// plane - Wayland protocol state, watchdogs, colour transitions, geometry -
// deliberately stays on the main thread; see WaylandVideoSurface.
//
// Contract:
//  - Jobs run in order on one worker thread and return a bool.
//  - Completions run on the GLib main context that was thread-default when
//    the executor was constructed, carrying the job's result. They are
//    delivered even after ShutdownAndJoin, so they must guard against state
//    that has since been torn down (the plugin's generation counter).
//  - ShutdownAndJoin drains queued jobs first. A job wedged inside a driver
//    call cannot be interrupted; past the timeout the thread is abandoned
//    (detached) and false is returned so the caller can leak, rather than
//    free, what the job may still touch. The worker owns its state through a
//    shared_ptr, never through the executor object, so abandonment leaks that
//    state instead of leaving the thread on freed memory.
class PlaneRenderExecutor {
 public:
  // Runs on the worker thread; the result is handed to the completion.
  using Job = std::function<bool()>;
  // Runs on the construction-time GLib main context.
  using Completion = std::function<void(bool)>;

  PlaneRenderExecutor();
  ~PlaneRenderExecutor();

  PlaneRenderExecutor(const PlaneRenderExecutor&) = delete;
  PlaneRenderExecutor& operator=(const PlaneRenderExecutor&) = delete;

  /// Queues |job|. Returns false only after shutdown has begun, in which case
  /// neither the job nor the completion will run.
  bool Post(Job job, Completion completion);

  /// Stops accepting jobs, waits up to |timeout_ms| for queued jobs to drain,
  /// and joins the worker. Returns false when the worker had to be abandoned
  /// instead - see the class comment. Idempotent.
  bool ShutdownAndJoin(unsigned int timeout_ms);

 private:
  // Everything the worker touches. Held by shared_ptr from both the executor
  // and the worker thread's closure, so an abandoned worker still stands on
  // live memory. The completion context reference is owned here and released
  // by the destructor - i.e. by whichever side lets go last.
  struct Shared {
    ~Shared();

    GMainContext* completion_context = nullptr;
    std::mutex mutex;
    std::condition_variable wake;
    std::condition_variable idle;
    std::deque<std::pair<Job, Completion>> jobs;
    bool running_job = false;
    bool quitting = false;
  };

  static void Run(const std::shared_ptr<Shared>& shared);

  std::shared_ptr<Shared> shared_;
  std::thread thread_;
  bool abandoned_ = false;
};

}  // namespace mpv

#endif  // PLEZY_LINUX_MPV_PLANE_RENDER_EXECUTOR_H_
