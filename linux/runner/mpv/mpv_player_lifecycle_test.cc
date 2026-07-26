#include <flutter_linux/flutter_linux.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <atomic>
#include <cerrno>
#include <chrono>
#include <condition_variable>
#include <csignal>
#include <cstdlib>
#include <exception>
#include <iostream>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <thread>
#include <utility>

#include "mpv_player.h"
#include "mpv_texture.h"

struct LifetimeTextureRegistrar {
  GObject parent_instance;
  FlTexture* texture;
};

struct LifetimeTextureRegistrarClass {
  GObjectClass parent_class;
};

static void LifetimeTextureRegistrarInterfaceInit(FlTextureRegistrarInterface* interface);
static void LifetimeTextureRegistrarDispose(GObject* object);
static void lifetime_texture_registrar_class_init(LifetimeTextureRegistrarClass* klass);
static void lifetime_texture_registrar_init(LifetimeTextureRegistrar* self);

G_DEFINE_TYPE_WITH_CODE(
    LifetimeTextureRegistrar, lifetime_texture_registrar, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(fl_texture_registrar_get_type(), LifetimeTextureRegistrarInterfaceInit))

static gboolean LifetimeTextureRegistrarRegister(FlTextureRegistrar* registrar, FlTexture* texture) {
  auto* self = reinterpret_cast<LifetimeTextureRegistrar*>(registrar);
  if (self->texture) return FALSE;
  self->texture = FL_TEXTURE(g_object_ref(texture));
  return TRUE;
}

static gboolean LifetimeTextureRegistrarUnregister(FlTextureRegistrar* registrar, FlTexture* texture) {
  auto* self = reinterpret_cast<LifetimeTextureRegistrar*>(registrar);
  if (self->texture != texture) return FALSE;
  g_clear_object(&self->texture);
  return TRUE;
}

static void LifetimeTextureRegistrarInterfaceInit(FlTextureRegistrarInterface* interface) {
  interface->register_texture = LifetimeTextureRegistrarRegister;
  interface->unregister_texture = LifetimeTextureRegistrarUnregister;
}

static void LifetimeTextureRegistrarDispose(GObject* object) {
  auto* self = reinterpret_cast<LifetimeTextureRegistrar*>(object);
  g_clear_object(&self->texture);
  G_OBJECT_CLASS(lifetime_texture_registrar_parent_class)->dispose(object);
}

static void lifetime_texture_registrar_class_init(LifetimeTextureRegistrarClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = LifetimeTextureRegistrarDispose;
}

static void lifetime_texture_registrar_init(LifetimeTextureRegistrar* self) { self->texture = nullptr; }

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

  static void WaitUntilDetached(const std::shared_ptr<MpvPlayer::CallbackContext>& context) {
    context->WaitUntilDetached();
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
  static FlValue* ConvertNode(MpvPlayer& player, mpv_node* node) { return player.NodeToFlValue(node); }
  static FlValue* ConvertNodeWithBudget(
      MpvPlayer& player, mpv_node* node, size_t remaining_entries, size_t remaining_bytes) {
    plezy::mpv_common::NodeConversionBudget budget{remaining_entries, remaining_bytes};
    return player.NodeToFlValue(node, &budget);
  }
  static void RegisterObservedNode(MpvPlayer& player, const std::string& name, int id) {
    player.observed_properties_.Register(name, "node", id);
  }
  static void HandleEvent(MpvPlayer& player, mpv_event* event) { player.HandleMpvEvent(event); }

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

bool WriteByte(int descriptor, char value) {
  for (;;) {
    const ssize_t written = write(descriptor, &value, 1);
    if (written == 1) return true;
    if (written < 0 && errno == EINTR) continue;
    return false;
  }
}

bool ReadByte(int descriptor, char expected) {
  char value = '\0';
  for (;;) {
    const ssize_t received = read(descriptor, &value, 1);
    if (received == 1) return value == expected;
    if (received < 0 && errno == EINTR) continue;
    return false;
  }
}

[[noreturn]] void ExitBlockedTeardownChild(int status) { _exit(status); }

int RunBlockedTeardownShutdownChild(int progress_read, int progress_write, int release_read) {
  auto* const completed_handle = reinterpret_cast<mpv_handle*>(0x11);
  auto* const blocked_render = reinterpret_cast<mpv_render_context*>(0x12);
  auto const blocked_display = reinterpret_cast<EGLDisplay>(0x13);
  auto const blocked_context = reinterpret_cast<EGLContext>(0x14);

  NativeRenderTeardownOperations operations{
      [](EGLDisplay, EGLContext) { return true; },
      [](EGLDisplay) { return true; },
      [](EGLDisplay, EGLContext) { return true; },
      [progress_write, release_read, blocked_render](mpv_render_context* render) {
        if (render != blocked_render || !WriteByte(progress_write, 'B')) ExitBlockedTeardownChild(121);
        char release = '\0';
        for (;;) {
          const ssize_t received = read(release_read, &release, 1);
          if (received == 1) break;
          if (received < 0 && errno == EINTR) continue;
          ExitBlockedTeardownChild(122);
        }
      },
      [progress_write, completed_handle](mpv_handle* handle) {
        if (handle != completed_handle || !WriteByte(progress_write, 'R')) ExitBlockedTeardownChild(123);
      },
  };
  ConfigureNativeRenderTeardownQueueForTesting(std::move(operations));

  NativeRenderTeardownBatch completed_batch;
  completed_batch.handle = completed_handle;
  EnqueueNativeRenderTeardownForTesting(std::move(completed_batch));
  if (!ReadByte(progress_read, 'R')) return 124;

  NativeRenderTeardownBatch blocked_batch;
  blocked_batch.resources.push_back({blocked_render, blocked_display, blocked_context});
  EnqueueNativeRenderTeardownForTesting(std::move(blocked_batch));
  if (!ReadByte(progress_read, 'B')) return 125;

  // Returning through std::exit below deliberately begins normal static
  // shutdown while the queue worker remains blocked in free_render.
  return 0;
}

void TestProcessShutdownDoesNotJoinBlockedNativeTeardown() {
  int progress_pipe[2] = {-1, -1};
  int release_pipe[2] = {-1, -1};
  Check(pipe(progress_pipe) == 0, "could not create teardown progress barrier");
  if (pipe(release_pipe) != 0) {
    close(progress_pipe[0]);
    close(progress_pipe[1]);
    Check(false, "could not create teardown release barrier");
  }

  const pid_t child = fork();
  if (child == 0) {
    close(release_pipe[1]);
    const int status = RunBlockedTeardownShutdownChild(progress_pipe[0], progress_pipe[1], release_pipe[0]);
    std::exit(status);
  }
  if (child < 0) {
    close(progress_pipe[0]);
    close(progress_pipe[1]);
    close(release_pipe[0]);
    close(release_pipe[1]);
    Check(false, "could not create teardown shutdown subprocess");
  }

  close(progress_pipe[0]);
  close(progress_pipe[1]);
  close(release_pipe[0]);

  std::mutex wait_mutex;
  std::condition_variable wait_condition;
  bool wait_finished = false;
  pid_t wait_result = -1;
  int child_status = 0;
  std::thread waiter([&]() {
    pid_t result;
    do {
      result = waitpid(child, &child_status, 0);
    } while (result < 0 && errno == EINTR);
    {
      std::lock_guard<std::mutex> lock(wait_mutex);
      wait_result = result;
      wait_finished = true;
    }
    wait_condition.notify_one();
  });

  bool exited_before_deadline = false;
  {
    std::unique_lock<std::mutex> lock(wait_mutex);
    exited_before_deadline = wait_condition.wait_for(lock, std::chrono::seconds(2), [&]() { return wait_finished; });
  }
  if (!exited_before_deadline) kill(child, SIGKILL);
  close(release_pipe[1]);
  waiter.join();

  Check(exited_before_deadline, "normal process shutdown joined a deliberately blocked native teardown");
  Check(wait_result == child, "could not collect teardown shutdown subprocess");
  Check(WIFEXITED(child_status), "teardown shutdown subprocess terminated abnormally");
  Check(WEXITSTATUS(child_status) == 0, "teardown shutdown subprocess did not reach normal static shutdown");
}

struct TextureLifetimeState {
  std::mutex mutex;
  std::condition_variable condition;
  bool callback_entered = false;
  bool release_callback = false;
  std::atomic<bool> callback_finalized{false};
  bool finalized_during_callback = false;
};

void BlockingTextureReadyCallback(gboolean, const gchar*, gpointer user_data) {
  auto* state = static_cast<TextureLifetimeState*>(user_data);
  {
    std::lock_guard<std::mutex> lock(state->mutex);
    state->callback_entered = true;
  }
  state->condition.notify_all();

  std::unique_lock<std::mutex> lock(state->mutex);
  state->condition.wait(lock, [state]() { return state->release_callback; });
  state->finalized_during_callback = state->callback_finalized.load();
}

void TextureReadyCallbackFinalized(gpointer user_data) {
  static_cast<TextureLifetimeState*>(user_data)->callback_finalized = true;
}

void TestPopulateRetainsTextureWhileBootstrapCallbackRuns() {
  auto* registrar = FL_TEXTURE_REGISTRAR(g_object_new(lifetime_texture_registrar_get_type(), nullptr));
  TextureLifetimeState state;
  MpvTexture* texture = mpv_texture_new(nullptr, registrar, nullptr);
  mpv_texture_set_ready_callback(texture, BlockingTextureReadyCallback, &state, TextureReadyCallbackFinalized);
  Check(
      fl_texture_registrar_register_texture(registrar, FL_TEXTURE(texture)),
      "the lifetime fixture must retain the registered texture");

  gboolean populate_result = TRUE;
  GError* populate_error = nullptr;
  std::thread raster_thread([&]() {
    uint32_t target = 0;
    uint32_t name = 0;
    uint32_t width = 0;
    uint32_t height = 0;
    auto* texture_class = FL_TEXTURE_GL_GET_CLASS(texture);
    populate_result = texture_class->populate(FL_TEXTURE_GL(texture), &target, &name, &width, &height, &populate_error);
  });

  {
    std::unique_lock<std::mutex> lock(state.mutex);
    state.condition.wait(lock, [&state]() { return state.callback_entered; });
  }

  // Match plugin teardown while populate is between releasing its mutex and
  // returning from the ready callback. Unregister drops the registrar's
  // reference before dispose drops the plugin's reference.
  Check(
      fl_texture_registrar_unregister_texture(registrar, FL_TEXTURE(texture)),
      "the lifetime fixture must unregister the texture");
  mpv_texture_dispose(texture);
  g_object_unref(texture);
  const bool finalized_before_populate_released = state.callback_finalized.load();

  {
    std::lock_guard<std::mutex> lock(state.mutex);
    state.release_callback = true;
  }
  state.condition.notify_all();
  raster_thread.join();

  Check(
      !finalized_before_populate_released,
      "platform disposal finalized the texture while its populate callback was still running");
  Check(
      !state.finalized_during_callback,
      "the ready callback was finalized before populate released its retained texture reference");
  Check(state.callback_finalized.load(), "the texture callback was not finalized after populate returned");
  Check(!populate_result, "a populate without a player must fail");
  Check(populate_error != nullptr, "failed populate must report an error");
  g_clear_error(&populate_error);
  g_object_unref(registrar);
}

void TestNodeConversionRejectsMalformedPayloads() {
  MpvPlayer player;

  mpv_node missing_list{};
  missing_list.format = MPV_FORMAT_NODE_ARRAY;
  missing_list.u.list = nullptr;
  FlValue* result = MpvPlayerLifecycleTestPeer::ConvertNode(player, &missing_list);
  Check(fl_value_get_type(result) == FL_VALUE_TYPE_NULL, "a node array without storage must decode as null");
  fl_value_unref(result);

  mpv_node value{};
  value.format = MPV_FORMAT_INT64;
  value.u.int64 = 1;
  char* missing_key = nullptr;
  mpv_node_list malformed_map{1, &value, &missing_key};
  mpv_node map{};
  map.format = MPV_FORMAT_NODE_MAP;
  map.u.list = &malformed_map;
  result = MpvPlayerLifecycleTestPeer::ConvertNode(player, &map);
  Check(fl_value_get_type(result) == FL_VALUE_TYPE_NULL, "a node map with a null key must decode as null");
  fl_value_unref(result);

  char invalid_utf8[] = {'a', static_cast<char>(0xFF), 'b', '\0'};
  mpv_node text{};
  text.format = MPV_FORMAT_STRING;
  text.u.string = invalid_utf8;
  result = MpvPlayerLifecycleTestPeer::ConvertNode(player, &text);
  Check(
      std::string(fl_value_get_string(result)) ==
          "a\xEF\xBF\xBD"
          "b",
      "invalid UTF-8 must be replaced before entering the Flutter codec");
  fl_value_unref(result);

  char oversized_text[] = "bounded";
  text.u.string = oversized_text;
  result =
      MpvPlayerLifecycleTestPeer::ConvertNodeWithBudget(player, &text, /*remaining_entries=*/1, /*remaining_bytes=*/6);
  Check(fl_value_get_type(result) == FL_VALUE_TYPE_NULL, "a node string beyond the byte budget must decode as null");
  fl_value_unref(result);
}

void TestNullNodePropertyPayloadDecodesAsNull() {
  MpvPlayer player;
  MpvPlayerLifecycleTestPeer::RegisterObservedNode(player, "track-list", 42);
  bool delivered = false;
  player.SetEventCallback([&delivered](FlValue* event) {
    Check(fl_value_get_type(event) == FL_VALUE_TYPE_LIST, "property event must remain a list");
    Check(fl_value_get_length(event) == 2, "property event must contain the ID and value");
    Check(fl_value_get_int(fl_value_get_list_value(event, 0)) == 42, "property event ID changed");
    Check(
        fl_value_get_type(fl_value_get_list_value(event, 1)) == FL_VALUE_TYPE_NULL,
        "a missing MPV node payload must decode as null");
    delivered = true;
  });

  mpv_event_property property{};
  property.name = "track-list";
  property.format = MPV_FORMAT_NODE;
  property.data = nullptr;
  mpv_event event{};
  event.event_id = MPV_EVENT_PROPERTY_CHANGE;
  event.data = &property;
  MpvPlayerLifecycleTestPeer::HandleEvent(player, &event);
  Check(delivered, "null node property event was not delivered");
}

void TestUnavailableCommandFails() {
  MpvPlayer player;
  int callback_count = 0;
  int status = MPV_ERROR_SUCCESS;

  player.CommandAsync({"stop"}, [&](int error) {
    ++callback_count;
    status = error;
  });

  Check(callback_count == 1, "a command without an mpv handle must complete exactly once");
  Check(status == MPV_ERROR_UNINITIALIZED, "a command without an mpv handle must fail as uninitialized");
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
  MpvPlayerLifecycleTestPeer::WaitUntilDetached(callback_context);
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

void TestRenderTeardownRetainsOwnershipUntilContextIsCurrent() {
  NativeRenderTeardownBatch batch;
  auto* render = reinterpret_cast<mpv_render_context*>(1);
  auto* handle = reinterpret_cast<mpv_handle*>(2);
  auto display = reinterpret_cast<EGLDisplay>(3);
  auto context = reinterpret_cast<EGLContext>(4);
  batch.resources.push_back({render, display, context});
  batch.handle = handle;

  bool allow_make_current = false;
  bool allow_release = true;
  int make_current_calls = 0;
  int release_calls = 0;
  int free_calls = 0;
  int destroy_calls = 0;
  int terminate_calls = 0;
  NativeRenderTeardownOperations operations{
      [&](EGLDisplay actual_display, EGLContext actual_context) {
        Check(actual_display == display && actual_context == context, "teardown must bind the retained EGL context");
        ++make_current_calls;
        return allow_make_current;
      },
      [&](EGLDisplay actual_display) {
        Check(actual_display == display, "teardown must release the retained EGL display");
        ++release_calls;
        return allow_release;
      },
      [&](EGLDisplay actual_display, EGLContext actual_context) {
        Check(actual_display == display && actual_context == context, "teardown destroyed the wrong EGL context");
        ++destroy_calls;
        return true;
      },
      [&](mpv_render_context* actual_render) {
        Check(actual_render == render, "teardown freed the wrong render context");
        ++free_calls;
      },
      [&](mpv_handle* actual_handle) {
        Check(actual_handle == handle, "teardown terminated the wrong mpv handle");
        ++terminate_calls;
      },
  };

  Check(!TryReleaseNativeRenderTeardown(batch, operations), "a failed EGL bind must retain the native teardown batch");
  Check(make_current_calls == 1, "teardown must attempt to bind the required EGL context");
  Check(
      free_calls == 0 && release_calls == 0 && destroy_calls == 0 && terminate_calls == 0,
      "a failed EGL bind must not free, destroy, or terminate dependent native objects");
  Check(
      batch.resources.size() == 1 && batch.resources.front().render == render && batch.handle == handle,
      "a failed EGL bind must preserve complete ownership for retry");

  allow_make_current = true;
  Check(TryReleaseNativeRenderTeardown(batch, operations), "a later valid EGL bind must complete retained teardown");
  Check(batch.resources.empty() && batch.handle == nullptr, "successful retry must consume the teardown batch");
  Check(
      free_calls == 1 && release_calls == 1 && destroy_calls == 1 && terminate_calls == 1,
      "successful retry must release the render, EGL context, and then the shared handle exactly once");
}

void TestRenderTeardownDoesNotDestroyAStillCurrentContext() {
  NativeRenderTeardownBatch batch;
  auto* render = reinterpret_cast<mpv_render_context*>(5);
  auto* handle = reinterpret_cast<mpv_handle*>(6);
  auto display = reinterpret_cast<EGLDisplay>(7);
  auto context = reinterpret_cast<EGLContext>(8);
  batch.resources.push_back({render, display, context});
  batch.handle = handle;

  bool allow_release = false;
  int free_calls = 0;
  int destroy_calls = 0;
  int terminate_calls = 0;
  NativeRenderTeardownOperations operations{
      [](EGLDisplay, EGLContext) { return true; },
      [&](EGLDisplay) { return allow_release; },
      [&](EGLDisplay, EGLContext) {
        ++destroy_calls;
        return true;
      },
      [&](mpv_render_context*) { ++free_calls; },
      [&](mpv_handle*) { ++terminate_calls; },
  };

  Check(!TryReleaseNativeRenderTeardown(batch, operations), "a context that cannot be released must remain queued");
  Check(free_calls == 1, "the render context may be freed only after its EGL context became current");
  Check(
      destroy_calls == 0 && terminate_calls == 0 && batch.resources.front().render == nullptr,
      "failed EGL release must retain the context and handle without double-freeing the render");

  allow_release = true;
  Check(TryReleaseNativeRenderTeardown(batch, operations), "a later EGL release must finish teardown");
  Check(
      free_calls == 1 && destroy_calls == 1 && terminate_calls == 1,
      "retry must not repeat render-context destruction");
}

void TestRetainedRenderBlocksAnotherCreationUntilReleased() {
  std::vector<NativeRenderTeardownResource> retained{
      {reinterpret_cast<mpv_render_context*>(9), reinterpret_cast<EGLDisplay>(10), reinterpret_cast<EGLContext>(11)}};
  bool allow_make_current = false;
  int free_calls = 0;
  int destroy_calls = 0;
  int render_creations = 0;
  NativeRenderTeardownOperations operations{
      [&](EGLDisplay, EGLContext) { return allow_make_current; },
      [](EGLDisplay) { return true; },
      [&](EGLDisplay, EGLContext) {
        ++destroy_calls;
        return true;
      },
      [&](mpv_render_context*) { ++free_calls; },
      [](mpv_handle*) { Check(false, "retained initialization cleanup must not terminate the shared core"); },
  };

  if (TryReleaseRetainedNativeRenderContexts(retained, operations)) ++render_creations;
  Check(render_creations == 0, "a retained render context must block another creation on the same core");
  Check(retained.size() == 1, "failed retained cleanup must preserve ownership for another GL-thread retry");

  allow_make_current = true;
  if (TryReleaseRetainedNativeRenderContexts(retained, operations)) ++render_creations;
  Check(render_creations == 1, "render creation may resume after retained teardown completes");
  Check(retained.empty(), "successful retained teardown must consume the old render context");
  Check(free_calls == 1 && destroy_calls == 1, "retained teardown must release each native object exactly once");
}

}  // namespace
}  // namespace mpv

int main() {
  GMainContext* context = g_main_context_new();
  g_main_context_push_thread_default(context);

  try {
    mpv::TestProcessShutdownDoesNotJoinBlockedNativeTeardown();
    mpv::TestPopulateRetainsTextureWhileBootstrapCallbackRuns();
    mpv::TestUnavailablePropertyWriteFails();
    mpv::TestNodeConversionRejectsMalformedPayloads();
    mpv::TestUnavailableCommandFails();
    mpv::TestPendingPropertyWriteFailsOnDispose();
    mpv::TestQueuedSourcesAreRetired(context);
    mpv::TestNativeLeaseBlocksDispose();
    mpv::TestWakeupAndRedrawCoalesce(context);
    mpv::TestRapidReplacementCannotReceiveOldCallbacks(context);
    mpv::TestRenderTeardownRetainsOwnershipUntilContextIsCurrent();
    mpv::TestRenderTeardownDoesNotDestroyAStillCurrentContext();
    mpv::TestNullNodePropertyPayloadDecodesAsNull();
    mpv::TestRetainedRenderBlocksAnotherCreationUntilReleased();
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
