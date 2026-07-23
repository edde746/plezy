#include <atomic>
#include <chrono>
#include <condition_variable>
#include <exception>
#include <iostream>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <thread>
#include <utility>

#include "mpv_player.h"

namespace mpv {

class MpvPlayerLifecycleTestPeer {
 public:
  static std::shared_ptr<MpvPlayer::CallbackContext> RetainContext(MpvPlayer& player) {
    return player.callback_context_;
  }

  static void Wakeup(const std::shared_ptr<MpvPlayer::CallbackContext>& context) {
    MpvPlayer::OnMpvWakeup(context.get());
  }

  static void RenderUpdate(const std::shared_ptr<MpvPlayer::CallbackContext>& context) {
    MpvPlayer::OnMpvRenderUpdate(context.get());
  }

  static void ScheduleRecovery(MpvPlayer& player) { player.ScheduleRecoverySource(); }

  static void RegisterPendingPropertyWrite(MpvPlayer& player, MpvPlayer::StatusCallback callback) {
    player.pending_requests_.RegisterStatus(std::move(callback));
  }

  static int PendingSourceCount(MpvPlayer& player) {
    std::lock_guard<std::mutex> lock(player.source_mutex_);
    return (player.wakeup_source_id_ != 0 ? 1 : 0) + (player.redraw_source_id_ != 0 ? 1 : 0) +
           (player.recovery_source_id_ != 0 ? 1 : 0);
  }

  static void HoldLease(
      const std::shared_ptr<MpvPlayer::CallbackContext>& context, std::mutex& mutex, std::condition_variable& condition,
      bool& entered, bool& release) {
    auto lease = context->Acquire();
    {
      std::lock_guard<std::mutex> lock(mutex);
      entered = static_cast<bool>(lease);
    }
    condition.notify_all();

    std::unique_lock<std::mutex> lock(mutex);
    condition.wait(lock, [&release]() { return release; });
  }
};

namespace {

void Check(bool condition, const char* message) {
  if (!condition) throw std::runtime_error(message);
}

void Drain(GMainContext* context) {
  while (g_main_context_iteration(context, FALSE)) {
  }
}

void TestUnavailablePropertyWriteFails() {
  MpvPlayer player;
  int callback_count = 0;
  int status = MPV_ERROR_SUCCESS;

  player.SetPropertyAsync("pause", "yes", [&](int error) {
    ++callback_count;
    status = error;
  });

  Check(callback_count == 1, "a property write without an mpv handle must complete exactly once");
  Check(status == MPV_ERROR_UNINITIALIZED, "a property write without an mpv handle must fail as uninitialized");
}

void TestPendingPropertyWriteFailsOnDispose() {
  MpvPlayer player;
  int callback_count = 0;
  int status = MPV_ERROR_SUCCESS;
  MpvPlayerLifecycleTestPeer::RegisterPendingPropertyWrite(player, [&](int error) {
    ++callback_count;
    status = error;
  });

  player.Dispose();
  Check(callback_count == 1, "dispose must complete a pending property write exactly once");
  Check(status < 0, "dispose must fail a pending property write");

  player.Dispose();
  Check(callback_count == 1, "repeated dispose must not complete a property write twice");
}

void TestQueuedSourcesAreRetired(GMainContext* context) {
  int redraws = 0;
  auto player = std::make_unique<MpvPlayer>();
  auto callback_context = MpvPlayerLifecycleTestPeer::RetainContext(*player);
  player->SetRedrawCallback([&redraws]() { ++redraws; });

  MpvPlayerLifecycleTestPeer::Wakeup(callback_context);
  MpvPlayerLifecycleTestPeer::RenderUpdate(callback_context);
  MpvPlayerLifecycleTestPeer::ScheduleRecovery(*player);
  Check(MpvPlayerLifecycleTestPeer::PendingSourceCount(*player) == 3, "all player sources must be tracked");

  player->Dispose();
  Check(MpvPlayerLifecycleTestPeer::PendingSourceCount(*player) == 0, "dispose must retire every tracked source");
  player.reset();

  MpvPlayerLifecycleTestPeer::Wakeup(callback_context);
  MpvPlayerLifecycleTestPeer::RenderUpdate(callback_context);
  std::this_thread::sleep_for(std::chrono::milliseconds(125));
  Drain(context);
  Check(redraws == 0, "detached callbacks must not publish redraws");
}

void TestNativeLeaseBlocksDispose() {
  auto player = std::make_unique<MpvPlayer>();
  auto callback_context = MpvPlayerLifecycleTestPeer::RetainContext(*player);
  std::mutex mutex;
  std::condition_variable condition;
  bool entered = false;
  bool release = false;

  std::thread holder(
      [&]() { MpvPlayerLifecycleTestPeer::HoldLease(callback_context, mutex, condition, entered, release); });
  {
    std::unique_lock<std::mutex> lock(mutex);
    condition.wait(lock, [&entered]() { return entered; });
  }

  std::atomic<bool> disposed{false};
  std::thread disposer([&]() {
    player->Dispose();
    disposed = true;
  });
  std::this_thread::sleep_for(std::chrono::milliseconds(25));
  Check(!disposed.load(), "dispose returned while a native callback lease was active");

  {
    std::lock_guard<std::mutex> lock(mutex);
    release = true;
  }
  condition.notify_all();
  holder.join();
  disposer.join();
  Check(disposed.load(), "dispose did not finish after the native callback lease was released");

  player.reset();
  MpvPlayerLifecycleTestPeer::Wakeup(callback_context);
  MpvPlayerLifecycleTestPeer::RenderUpdate(callback_context);
}

void TestWakeupAndRedrawCoalesce(GMainContext* context) {
  int redraws = 0;
  MpvPlayer player;
  auto callback_context = MpvPlayerLifecycleTestPeer::RetainContext(player);
  player.SetRedrawCallback([&redraws]() { ++redraws; });

  for (int i = 0; i < 10; ++i) {
    MpvPlayerLifecycleTestPeer::Wakeup(callback_context);
    MpvPlayerLifecycleTestPeer::RenderUpdate(callback_context);
  }
  Check(MpvPlayerLifecycleTestPeer::PendingSourceCount(player) == 2, "wakeup and redraw sources must coalesce");
  Drain(context);
  Check(redraws == 1, "coalesced redraw was not delivered exactly once");
  Check(MpvPlayerLifecycleTestPeer::PendingSourceCount(player) == 0, "dispatched source IDs must be cleared");

  player.ClearRedrawFlag();
  MpvPlayerLifecycleTestPeer::RenderUpdate(callback_context);
  Drain(context);
  Check(redraws == 2, "a redraw after dispatch must still be delivered");
}

void TestRapidReplacementCannotReceiveOldCallbacks(GMainContext* context) {
  for (int iteration = 0; iteration < 100; ++iteration) {
    int old_redraws = 0;
    int replacement_redraws = 0;

    auto old_player = std::make_unique<MpvPlayer>();
    auto old_context = MpvPlayerLifecycleTestPeer::RetainContext(*old_player);
    old_player->SetRedrawCallback([&old_redraws]() { ++old_redraws; });
    MpvPlayerLifecycleTestPeer::Wakeup(old_context);
    MpvPlayerLifecycleTestPeer::RenderUpdate(old_context);
    old_player->Dispose();
    old_player.reset();

    auto replacement = std::make_unique<MpvPlayer>();
    auto replacement_context = MpvPlayerLifecycleTestPeer::RetainContext(*replacement);
    replacement->SetRedrawCallback([&replacement_redraws]() { ++replacement_redraws; });

    // Simulate both an entered-old callback resuming and fresh replacement work.
    MpvPlayerLifecycleTestPeer::Wakeup(old_context);
    MpvPlayerLifecycleTestPeer::RenderUpdate(old_context);
    MpvPlayerLifecycleTestPeer::Wakeup(replacement_context);
    MpvPlayerLifecycleTestPeer::RenderUpdate(replacement_context);
    Drain(context);

    Check(old_redraws == 0, "an old redraw callback ran after replacement");
    Check(replacement_redraws == 1, "old callback state suppressed or duplicated a replacement redraw");
    replacement->Dispose();
  }
}

}  // namespace
}  // namespace mpv

int main() {
  GMainContext* context = g_main_context_new();
  g_main_context_push_thread_default(context);

  try {
    mpv::TestUnavailablePropertyWriteFails();
    mpv::TestPendingPropertyWriteFailsOnDispose();
    mpv::TestQueuedSourcesAreRetired(context);
    mpv::TestNativeLeaseBlocksDispose();
    mpv::TestWakeupAndRedrawCoalesce(context);
    mpv::TestRapidReplacementCannotReceiveOldCallbacks(context);
  } catch (const std::exception& error) {
    g_main_context_pop_thread_default(context);
    g_main_context_unref(context);
    std::cerr << "mpv_player_lifecycle_test: " << error.what() << '\n';
    return 1;
  }

  g_main_context_pop_thread_default(context);
  g_main_context_unref(context);
  std::cout << "mpv_player_lifecycle_test: PASS\n";
  return 0;
}
