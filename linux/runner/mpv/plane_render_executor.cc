#include "plane_render_executor.h"

#include <chrono>

namespace mpv {

namespace {

struct CompletionInvocation {
  PlaneRenderExecutor::Completion completion;
  bool result;
};

gboolean InvokeCompletion(gpointer data) {
  auto* invocation = static_cast<CompletionInvocation*>(data);
  invocation->completion(invocation->result);
  return G_SOURCE_REMOVE;
}

void DestroyCompletionInvocation(gpointer data) { delete static_cast<CompletionInvocation*>(data); }

}  // namespace

PlaneRenderExecutor::Shared::~Shared() {
  if (completion_context != nullptr) g_main_context_unref(completion_context);
}

PlaneRenderExecutor::PlaneRenderExecutor() : shared_(std::make_shared<Shared>()) {
  shared_->completion_context = g_main_context_ref_thread_default();
  thread_ = std::thread(&PlaneRenderExecutor::Run, shared_);
}

PlaneRenderExecutor::~PlaneRenderExecutor() { ShutdownAndJoin(5000); }

bool PlaneRenderExecutor::Post(Job job, Completion completion) {
  {
    std::lock_guard<std::mutex> lock(shared_->mutex);
    if (shared_->quitting) return false;
    shared_->jobs.emplace_back(std::move(job), std::move(completion));
  }
  shared_->wake.notify_one();
  return true;
}

bool PlaneRenderExecutor::ShutdownAndJoin(unsigned int timeout_ms) {
  if (!thread_.joinable()) return !abandoned_;
  {
    std::unique_lock<std::mutex> lock(shared_->mutex);
    shared_->quitting = true;
    shared_->wake.notify_all();
    if (!shared_->idle.wait_for(lock, std::chrono::milliseconds(timeout_ms), [this] {
          return shared_->jobs.empty() && !shared_->running_job;
        })) {
      abandoned_ = true;
    }
  }
  if (abandoned_) {
    // The job is wedged inside a call that cannot be interrupted. Joining
    // would hang the caller forever; the thread is cut loose instead, and the
    // caller is told so it can leak, rather than free, whatever the job may
    // still be touching. The worker keeps the shared state alive on its own.
    thread_.detach();
    return false;
  }
  thread_.join();
  return true;
}

void PlaneRenderExecutor::Run(const std::shared_ptr<Shared>& shared) {
  for (;;) {
    Job job;
    Completion completion;
    {
      std::unique_lock<std::mutex> lock(shared->mutex);
      shared->wake.wait(lock, [&shared] { return !shared->jobs.empty() || shared->quitting; });
      // Quitting drains: queued jobs still run, so a shutdown-time job (the
      // EGL unbind) can be posted and then waited for.
      if (shared->jobs.empty()) return;
      job = std::move(shared->jobs.front().first);
      completion = std::move(shared->jobs.front().second);
      shared->jobs.pop_front();
      shared->running_job = true;
    }

    const bool result = job ? job() : false;
    if (completion) {
      g_main_context_invoke_full(
          shared->completion_context, G_PRIORITY_DEFAULT, InvokeCompletion,
          new CompletionInvocation{std::move(completion), result}, DestroyCompletionInvocation);
    }

    {
      std::lock_guard<std::mutex> lock(shared->mutex);
      shared->running_job = false;
    }
    shared->idle.notify_all();
  }
}

}  // namespace mpv
