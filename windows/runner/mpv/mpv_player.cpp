#include "mpv_player.h"

#include <commctrl.h>
#include <dxgi.h>
#include <windowsx.h>

#include <cmath>
#include <unordered_map>

#include "sanitize_utf8.h"

namespace mpv {

struct InnerWindowSubclassState {
  HWND hwnd = nullptr;
  std::atomic<HWND> forward_target{nullptr};
  std::atomic<bool> active{false};
  std::atomic<uint64_t> forwarded_pointer_token{0};
  std::atomic<LPARAM> forwarded_pointer_position{0};
  std::mutex forwarded_pointer_mutex;
  UINT_PTR subclass_id = 0;
  // Guarded by g_inner_subclasses_mutex.
  bool installed = false;
  // While true, the window thread may still remove this generation, so a
  // replacement must not adopt it.
  bool removal_pending = false;
};

namespace {

// Whether any GPU on this system is a Qualcomm Adreno.
//
// libplacebo regenerates its tone-mapping shader LUT whenever the tone-map
// parameters change, and the reuse key (pl_tone_map_params_equal) includes the
// frame's raw HDR metadata by exact float comparison. Two sources move it
// every frame: dynamic peak detection (hdr-compute-peak), and HDR10+
// per-scene metadata (scene_max/scene_avg/ootf), which mpv maps from decoder
// side data on every frame. Qualcomm's D3D11 driver has no host-visible
// upload path (its libplacebo caps report buf_transfer and max_mapped_size as
// zero), so each regeneration costs tens of milliseconds: 4K HDR→SDR playback
// starves to single-digit fps and the swinging tone curve reads as brightness
// flicker (#2191). Initialize therefore silences both dynamic sources on this
// GPU; tone mapping falls back to the static HDR10 mastering metadata and the
// LUT is generated once.
//
// The whole adapter list is scanned rather than predicting mpv's choice: mpv
// takes the DXGI default adapter, and no supported machine pairs an Adreno
// with another GPU, so presence is equivalent to use. This also covers the
// x64 build running emulated on Windows-on-ARM, which an architecture check
// would miss.
bool SystemHasQualcommGpu() {
  // Qualcomm's Windows driver reports the FourCC 'QCOM' as its DXGI vendor
  // id (seen in the wild on the Adreno X1-85); 0x5143 is Qualcomm's PCI-SIG
  // id, matched in case a driver reports that instead.
  constexpr UINT kQualcommFourCc = 0x4D4F4351;
  constexpr UINT kQualcommPci = 0x5143;
  IDXGIFactory1* factory = nullptr;
  if (FAILED(::CreateDXGIFactory1(IID_PPV_ARGS(&factory)))) return false;
  bool found = false;
  IDXGIAdapter1* adapter = nullptr;
  for (UINT i = 0; !found && SUCCEEDED(factory->EnumAdapters1(i, &adapter)); ++i) {
    DXGI_ADAPTER_DESC1 desc;
    if (SUCCEEDED(adapter->GetDesc1(&desc))) {
      found = desc.VendorId == kQualcommFourCc || desc.VendorId == kQualcommPci;
    }
    adapter->Release();
    adapter = nullptr;
  }
  factory->Release();
  return found;
}

// Adapts the shared, bounded mpv_node walk onto Flutter's encodable values.
struct EncodableNodeBuilder {
  using Value = flutter::EncodableValue;
  using ListBuilder = flutter::EncodableList;
  using MapBuilder = flutter::EncodableMap;

  static Value Null() { return flutter::EncodableValue(); }
  static Value Boolean(bool value) { return flutter::EncodableValue(value); }
  static Value Int(int64_t value) { return flutter::EncodableValue(value); }
  static Value Double(double value) { return flutter::EncodableValue(value); }
  static Value String(const char* value, size_t length) { return flutter::EncodableValue(SanitizeUtf8(value, length)); }

  static ListBuilder NewList() { return flutter::EncodableList(); }
  static void Append(ListBuilder& list, Value value) { list.push_back(std::move(value)); }
  static Value FinishList(ListBuilder list) { return flutter::EncodableValue(std::move(list)); }

  static MapBuilder NewMap() { return flutter::EncodableMap(); }
  static void Insert(MapBuilder& map, const char* key, size_t key_length, Value value) {
    map[flutter::EncodableValue(SanitizeUtf8(key, key_length))] = std::move(value);
  }
  static Value FinishMap(MapBuilder map) { return flutter::EncodableValue(std::move(map)); }
  static void AbandonMap(MapBuilder&) {}
};

flutter::EncodableValue NodeToEncodableValue(const mpv_node* node) {
  return plezy::mpv_common::ConvertNode<EncodableNodeBuilder>(node);
}

// Input ownership for the DComp video child.
//
// The video host window is created disabled (WS_DISABLED). A disabled window
// and — implicitly — its children are skipped when the system picks the window
// that owns a contact, and the input is handed to the parent instead, so mouse,
// touch, and pen over the video land on the Flutter view itself, on the
// platform thread, with their real device kind. That is the only hit-test
// opt-out that works across threads: WS_EX_TRANSPARENT and an HTTRANSPARENT
// WM_NCHITTEST reply are both documented as same-thread-only, and mpv's inner
// window lives on mpv's own thread.
//
// The subclass below is the fallback for input that still reaches mpv's window.
// It uses the common-controls subclass chain with per-window reference data.
// Mouse messages can be posted straight through, but a WM_POINTER message
// cannot be forwarded as-is: Flutter resolves it with GetPointerInfo, which
// only answers for a pointer message the calling thread retrieved itself, and
// silently drops the event when that lookup fails. The primary contact is
// therefore translated into mouse input.
constexpr bool IsForwardedPointerMessage(UINT message) {
  switch (message) {
    case WM_POINTERDOWN:
    case WM_POINTERUPDATE:
    case WM_POINTERUP:
    case WM_POINTERLEAVE:
    case WM_POINTERCAPTURECHANGED:
      return true;
    default:
      return false;
  }
}

static_assert(IsForwardedPointerMessage(WM_POINTERDOWN));
static_assert(IsForwardedPointerMessage(WM_POINTERUPDATE));
static_assert(IsForwardedPointerMessage(WM_POINTERUP));
static_assert(IsForwardedPointerMessage(WM_POINTERLEAVE));
static_assert(IsForwardedPointerMessage(WM_POINTERCAPTURECHANGED));
static_assert(!IsForwardedPointerMessage(WM_MOUSEMOVE));

uint64_t PointerToken(WPARAM wparam) { return static_cast<uint64_t>(GET_POINTERID_WPARAM(wparam)) + 1; }

LPARAM PointerPositionInView(HWND view, LPARAM lparam) {
  POINT point = {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
  ::ScreenToClient(view, &point);
  return MAKELPARAM(point.x, point.y);
}

void ReleaseForwardedPointer(InnerWindowSubclassState& state, HWND view) {
  std::lock_guard<std::mutex> lock(state.forwarded_pointer_mutex);
  if (state.forwarded_pointer_token.exchange(0, std::memory_order_acq_rel) == 0 || !view) {
    return;
  }
  const LPARAM position = state.forwarded_pointer_position.load(std::memory_order_acquire);
  ::PostMessageW(view, WM_LBUTTONUP, 0, position);
}

bool ForwardPointerAsMouse(InnerWindowSubclassState& state, HWND view, UINT message, WPARAM wparam, LPARAM lparam) {
  if (!IsForwardedPointerMessage(message)) return false;

  std::lock_guard<std::mutex> lock(state.forwarded_pointer_mutex);
  if (!state.active.load(std::memory_order_acquire) || state.forward_target.load(std::memory_order_acquire) != view) {
    return true;
  }
  const uint64_t pointer_token = PointerToken(wparam);
  if (message == WM_POINTERDOWN) {
    if (!IS_POINTER_PRIMARY_WPARAM(wparam) || !IS_POINTER_FIRSTBUTTON_WPARAM(wparam)) {
      return true;
    }

    uint64_t expected = 0;
    if (!state.forwarded_pointer_token.compare_exchange_strong(expected, pointer_token)) {
      return true;
    }

    const LPARAM position = PointerPositionInView(view, lparam);
    state.forwarded_pointer_position.store(position, std::memory_order_release);
    ::PostMessageW(view, WM_LBUTTONDOWN, MK_LBUTTON, position);
    return true;
  }

  if (state.forwarded_pointer_token.load(std::memory_order_acquire) != pointer_token) {
    return true;
  }

  if (message == WM_POINTERUPDATE) {
    const LPARAM position = PointerPositionInView(view, lparam);
    state.forwarded_pointer_position.store(position, std::memory_order_release);
    ::PostMessageW(view, WM_MOUSEMOVE, MK_LBUTTON, position);
    return true;
  }

  uint64_t expected = pointer_token;
  if (!state.forwarded_pointer_token.compare_exchange_strong(expected, 0)) {
    return true;
  }

  const LPARAM position = message == WM_POINTERCAPTURECHANGED
                              ? state.forwarded_pointer_position.load(std::memory_order_acquire)
                              : PointerPositionInView(view, lparam);
  state.forwarded_pointer_position.store(position, std::memory_order_release);
  ::PostMessageW(view, WM_LBUTTONUP, 0, position);
  return true;
}

std::mutex g_inner_subclasses_mutex;
std::unordered_map<HWND, std::shared_ptr<InnerWindowSubclassState>> g_inner_subclasses;
std::atomic<uint64_t> g_next_inner_subclass_generation{1};

std::shared_ptr<InnerWindowSubclassState> FindInnerSubclassState(HWND hwnd, DWORD_PTR reference_data) {
  std::lock_guard<std::mutex> lock(g_inner_subclasses_mutex);
  const auto it = g_inner_subclasses.find(hwnd);
  if (it == g_inner_subclasses.end() || reinterpret_cast<DWORD_PTR>(it->second.get()) != reference_data) {
    return nullptr;
  }
  return it->second;
}

LRESULT CALLBACK MpvInnerSubclassProc(
    HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam, UINT_PTR subclass_id, DWORD_PTR reference_data) {
  const auto state = FindInnerSubclassState(hwnd, reference_data);
  if (!state) {
    return ::DefSubclassProc(hwnd, message, wparam, lparam);
  }

  const bool active = state->active.load(std::memory_order_acquire);
  HWND view = active ? state->forward_target.load(std::memory_order_acquire) : nullptr;
  if (active && view && ForwardPointerAsMouse(*state, view, message, wparam, lparam)) {
    return 0;
  }

  if (active && message >= WM_MOUSEFIRST && message <= WM_MOUSELAST) {
    if (view) {
      LPARAM forwarded = lparam;
      if (message != WM_MOUSEWHEEL && message != WM_MOUSEHWHEEL) {
        // Client coordinates: translate inner-window-space -> view-space.
        // (Wheel messages carry screen coordinates; pass through unchanged.)
        POINT pt = {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
        ::MapWindowPoints(hwnd, view, &pt, 1);
        forwarded = MAKELPARAM(pt.x, pt.y);
      }
      ::PostMessageW(view, message, wparam, forwarded);
    }
    return 0;
  }

  if (message == WM_NCDESTROY) {
    state->active.store(false, std::memory_order_release);
    const HWND forward_target = state->forward_target.exchange(nullptr, std::memory_order_acq_rel);
    ReleaseForwardedPointer(*state, forward_target);
    ::RemoveWindowSubclass(hwnd, MpvInnerSubclassProc, subclass_id);
    std::lock_guard<std::mutex> lock(g_inner_subclasses_mutex);
    const auto it = g_inner_subclasses.find(hwnd);
    if (it != g_inner_subclasses.end() && it->second.get() == state.get()) {
      g_inner_subclasses.erase(it);
    }
  }
  return ::DefSubclassProc(hwnd, message, wparam, lparam);
}

constexpr UINT kSubclassOwnershipMessage = WM_APP + 0x0504;

enum class SubclassOwnershipActionPhase {
  kPending,
  kRunning,
  kCompleted,
};

struct SubclassOwnershipAction {
  std::shared_ptr<InnerWindowSubclassState> state;
  bool install;
  std::mutex mutex;
  SubclassOwnershipActionPhase phase = SubclassOwnershipActionPhase::kPending;
  bool cancelled = false;
  bool success = false;
};

std::mutex g_subclass_actions_mutex;
std::unordered_map<UINT_PTR, std::shared_ptr<SubclassOwnershipAction>> g_subclass_actions;
std::atomic<UINT_PTR> g_next_subclass_action{1};

void ForgetInnerSubclassState(const std::shared_ptr<InnerWindowSubclassState>& state) {
  std::lock_guard<std::mutex> lock(g_inner_subclasses_mutex);
  const auto it = g_inner_subclasses.find(state->hwnd);
  if (it != g_inner_subclasses.end() && it->second.get() == state.get()) {
    g_inner_subclasses.erase(it);
  }
}

bool ApplySubclassOwnershipAction(const SubclassOwnershipAction& action) {
  if (action.install) {
    return ::SetWindowSubclass(
               action.state->hwnd, MpvInnerSubclassProc, action.state->subclass_id,
               reinterpret_cast<DWORD_PTR>(action.state.get())) != FALSE;
  }
  std::lock_guard<std::mutex> lock(g_inner_subclasses_mutex);
  const auto it = g_inner_subclasses.find(action.state->hwnd);
  if (it == g_inner_subclasses.end() || it->second.get() != action.state.get()) {
    return false;
  }

  const bool removed =
      ::RemoveWindowSubclass(action.state->hwnd, MpvInnerSubclassProc, action.state->subclass_id) != FALSE;
  if (removed) {
    g_inner_subclasses.erase(it);
  } else {
    action.state->removal_pending = false;
  }
  return removed;
}

void ExecuteSubclassOwnershipAction(const std::shared_ptr<SubclassOwnershipAction>& action) {
  {
    std::lock_guard<std::mutex> lock(action->mutex);
    if (action->phase != SubclassOwnershipActionPhase::kPending) return;
    if (action->cancelled) {
      action->phase = SubclassOwnershipActionPhase::kCompleted;
      if (action->install) {
        ForgetInnerSubclassState(action->state);
      }
      return;
    }
    action->phase = SubclassOwnershipActionPhase::kRunning;
  }

  const bool applied = ApplySubclassOwnershipAction(*action);
  bool cancelled_install = false;
  {
    std::lock_guard<std::mutex> lock(action->mutex);
    cancelled_install = action->install && action->cancelled;
    if (!cancelled_install) {
      action->success = applied;
      action->phase = SubclassOwnershipActionPhase::kCompleted;
    }
  }

  if (!cancelled_install) {
    if (action->install && !applied) {
      ForgetInnerSubclassState(action->state);
    }
    return;
  }

  // A timeout can race an action that the window thread has already begun.
  // Remove a late install on that same thread before releasing the action's
  // shared ownership of the reference data used by the subclass callback.
  const bool detached = !applied || ::RemoveWindowSubclass(
                                        action->state->hwnd, MpvInnerSubclassProc, action->state->subclass_id) != FALSE;
  if (detached) {
    ForgetInnerSubclassState(action->state);
  }
  std::lock_guard<std::mutex> lock(action->mutex);
  action->success = false;
  action->phase = SubclassOwnershipActionPhase::kCompleted;
}

LRESULT CALLBACK SubclassOwnershipHook(int code, WPARAM wparam, LPARAM lparam) {
  if (code >= 0) {
    const auto* message = reinterpret_cast<const CWPSTRUCT*>(lparam);
    if (message && message->message == kSubclassOwnershipMessage) {
      std::shared_ptr<SubclassOwnershipAction> action;
      {
        std::lock_guard<std::mutex> lock(g_subclass_actions_mutex);
        const auto it = g_subclass_actions.find(static_cast<UINT_PTR>(message->wParam));
        if (it != g_subclass_actions.end() && it->second->state->hwnd == message->hwnd) {
          action = it->second;
        }
      }
      if (action) {
        ExecuteSubclassOwnershipAction(action);
      }
    }
  }
  return ::CallNextHookEx(nullptr, code, wparam, lparam);
}

bool RunSubclassOwnershipActionOnWindowThread(const std::shared_ptr<SubclassOwnershipAction>& action) {
  DWORD window_thread = ::GetWindowThreadProcessId(action->state->hwnd, nullptr);
  if (!window_thread) return false;
  if (window_thread == ::GetCurrentThreadId()) {
    ExecuteSubclassOwnershipAction(action);
    std::lock_guard<std::mutex> lock(action->mutex);
    return action->success;
  }

  HHOOK hook = ::SetWindowsHookExW(WH_CALLWNDPROC, SubclassOwnershipHook, nullptr, window_thread);
  if (!hook) return false;

  const UINT_PTR action_id = g_next_subclass_action.fetch_add(1, std::memory_order_relaxed);
  {
    std::lock_guard<std::mutex> lock(g_subclass_actions_mutex);
    g_subclass_actions[action_id] = action;
  }

  DWORD_PTR message_result = 0;
  ::SendMessageTimeoutW(
      action->state->hwnd, kSubclassOwnershipMessage, action_id, 0, SMTO_ABORTIFHUNG, 1000, &message_result);

  bool success = false;
  {
    // Completion and cancellation use the same lock. If the callback won the
    // race, its acknowledged result is authoritative. Otherwise it observes
    // cancellation and cannot leave a late install referencing released data.
    std::lock_guard<std::mutex> lock(action->mutex);
    if (action->phase == SubclassOwnershipActionPhase::kCompleted) {
      success = action->success;
    } else {
      action->cancelled = true;
    }
  }
  {
    std::lock_guard<std::mutex> lock(g_subclass_actions_mutex);
    const auto it = g_subclass_actions.find(action_id);
    if (it != g_subclass_actions.end() && it->second == action) {
      g_subclass_actions.erase(it);
    }
  }
  ::UnhookWindowsHookEx(hook);
  return success;
}

std::shared_ptr<InnerWindowSubclassState> InstallMpvInnerSubclass(HWND inner, HWND forward_target) {
  if (!inner || !forward_target) return nullptr;

  std::shared_ptr<InnerWindowSubclassState> state;

  {
    std::lock_guard<std::mutex> lock(g_inner_subclasses_mutex);
    const auto existing = g_inner_subclasses.find(inner);
    if (existing != g_inner_subclasses.end()) {
      const auto& retained = existing->second;
      if (!retained->installed || retained->active.load(std::memory_order_acquire) || retained->removal_pending) {
        return nullptr;
      }

      // A timed-out detach that never reached the window thread leaves the
      // helper-chain entry installed. Adopt that exact generation rather than
      // stacking a duplicate subclass or retaining a permanently inert entry.
      retained->forwarded_pointer_token.store(0, std::memory_order_release);
      retained->forward_target.store(forward_target, std::memory_order_release);
      retained->active.store(true, std::memory_order_release);
      return retained;
    }
    state = std::make_shared<InnerWindowSubclassState>();
    state->hwnd = inner;
    state->forward_target.store(forward_target, std::memory_order_relaxed);
    state->subclass_id = g_next_inner_subclass_generation.fetch_add(1, std::memory_order_relaxed);

    // Publish the state before installing the helper-chain entry. The
    // callback's reference data identifies this exact generation, so an old
    // callback can never resolve a replacement generation that reuses HWND.
    g_inner_subclasses[inner] = state;
  }

  auto action = std::make_shared<SubclassOwnershipAction>();
  action->state = state;
  action->install = true;
  if (!RunSubclassOwnershipActionOnWindowThread(action)) {
    bool action_never_started = false;
    {
      std::lock_guard<std::mutex> lock(action->mutex);
      action_never_started = action->phase == SubclassOwnershipActionPhase::kPending;
    }
    if (action_never_started) {
      ForgetInnerSubclassState(state);
    }
    return nullptr;
  }
  {
    std::lock_guard<std::mutex> lock(g_inner_subclasses_mutex);
    const auto it = g_inner_subclasses.find(inner);
    if (it == g_inner_subclasses.end() || it->second.get() != state.get()) {
      return nullptr;
    }
    state->installed = true;
    state->active.store(true, std::memory_order_release);
  }
  return state;
}

void DetachMpvInnerSubclassState(const std::shared_ptr<InnerWindowSubclassState>& state) {
  if (!state) return;

  // Invalidate forwarding before removing the helper-chain entry. A callback
  // already holding this generation can still call DefSubclassProc, but can
  // no longer target a replacement Flutter/player generation.

  HWND forward_target = nullptr;
  {
    std::lock_guard<std::mutex> lock(g_inner_subclasses_mutex);
    const auto it = g_inner_subclasses.find(state->hwnd);
    if (it == g_inner_subclasses.end() || it->second.get() != state.get()) {
      return;
    }
    state->active.store(false, std::memory_order_release);
    forward_target = state->forward_target.exchange(nullptr, std::memory_order_acq_rel);
    state->removal_pending = true;
  }
  ReleaseForwardedPointer(*state, forward_target);

  auto action = std::make_shared<SubclassOwnershipAction>();
  action->state = state;
  action->install = false;
  const bool detached = RunSubclassOwnershipActionOnWindowThread(action);
  if (!detached) {
    bool removal_not_applied = false;
    {
      std::lock_guard<std::mutex> lock(action->mutex);
      removal_not_applied = action->phase == SubclassOwnershipActionPhase::kPending ||
                            (action->phase == SubclassOwnershipActionPhase::kCompleted && !action->success);
    }
    if (removal_not_applied) {
      std::lock_guard<std::mutex> lock(g_inner_subclasses_mutex);
      const auto it = g_inner_subclasses.find(state->hwnd);
      if (it != g_inner_subclasses.end() && it->second.get() == state.get()) {
        // RunSubclassOwnershipActionOnWindowThread has already unregistered
        // the cancelled action and hook. The installed entry is now stable
        // and can be reactivated by a replacement owner.
        state->removal_pending = false;
      }
    }
  }
  if (!detached && !::IsWindow(state->hwnd)) {
    // A destroyed HWND has already discarded its subclass chain, so no
    // callback can retain the reference data even if dispatch was unavailable.
    ForgetInnerSubclassState(state);
  }
}

}  // namespace

MpvPlayer::MpvPlayer(bool audio_only) : audio_only_(audio_only) {}

MpvPlayer::~MpvPlayer() { Dispose(); }

void MpvPlayer::EnsureMpvInnerSubclassed() {
  if (!hwnd_ || !forward_target_view_) return;

  HWND inner = ::FindWindowExW(hwnd_, nullptr, nullptr, nullptr);
  if (!inner) return;

  std::lock_guard<std::mutex> lock(inner_subclass_mutex_);
  if (inner_subclass_ && inner_subclass_->hwnd == inner && inner_subclass_->active.load(std::memory_order_acquire)) {
    inner_subclass_->forward_target.store(forward_target_view_, std::memory_order_release);
    return;
  }

  DetachMpvInnerSubclassState(inner_subclass_);
  inner_subclass_.reset();
  inner_subclass_ = InstallMpvInnerSubclass(inner, forward_target_view_);
}

void MpvPlayer::DetachMpvInnerSubclass() {
  std::lock_guard<std::mutex> lock(inner_subclass_mutex_);
  DetachMpvInnerSubclassState(inner_subclass_);
  inner_subclass_.reset();
}

bool MpvPlayer::Initialize(HWND view) {
  if (mpv_) {
    return true;  // Already initialized.
  }
  active_source_id_ = 0;
  has_active_source_id_ = false;

  // Create mpv instance.
  mpv_ = mpv_create();
  if (!mpv_) {
    return false;
  }

  plezy::mpv_common::ApplyCommonStartupOptions(mpv_, audio_only_);

  if (!audio_only_) {
    // Create a child window for mpv to render into, parented to the Flutter
    // |view|. The video child then sits in the view's own per-window layer
    // stack, above the view's (never-painted) layer-1 content and below the
    // engine's topmost DComp visual carrying the UI. WS_CLIPSIBLINGS keeps it
    // from painting over neighboring view children.
    //
    // WS_DISABLED takes the host — and the inner window mpv creates inside it,
    // which a disabled parent disables implicitly — out of input targeting, so
    // mouse, touch, and pen over the video are delivered to the parent Flutter
    // view instead of to mpv's thread. mpv never consumes input here anyway
    // (input-vo-keyboard=no, and the forwarding subclass swallows the rest).
    hwnd_ = ::CreateWindowExW(
        WS_EX_NOPARENTNOTIFY, L"STATIC", L"", kVideoHostWindowStyle, 0, 0, 100, 100, view, nullptr,
        GetModuleHandle(nullptr), nullptr);
    if (!hwnd_) {
      mpv_destroy(mpv_);
      mpv_ = nullptr;
      return false;
    }
    forward_target_view_ = view;

    // Set the wid option to embed mpv in our window.
    int64_t wid = reinterpret_cast<int64_t>(hwnd_);
    mpv_set_option(mpv_, "wid", MPV_FORMAT_INT64, &wid);

    mpv_set_option_string(mpv_, "vo", "gpu-next");
    mpv_set_option_string(mpv_, "gpu-api", "auto");
    // hwdec is set from Flutter via setProperty based on user preference
  }

  // Hardware media keys are owned by the SMTC integration (os_media_controls);
  // mpv's default handling would double-handle Play/Pause.
  mpv_set_option_string(mpv_, "input-media-keys", "no");

  if (!audio_only_) {
    // Let mpv use display/context detection instead of forcing HDR signaling.
    mpv_set_option_string(mpv_, "target-colorspace-hint", plezy::mpv_common::TargetColorspaceHint(hdr_enabled_));

    // Fallback tone mapping when display doesn't support HDR. On Adreno,
    // per-frame tone-map LUT regeneration is pathological — see
    // SystemHasQualcommGpu — so both dynamic inputs to the LUT key are
    // silenced: the peak detector, and HDR10+ per-scene metadata, which
    // vf=format:hdr10plus=no zeroes before it reaches the renderer. Dolby
    // Vision L1 metadata could still churn the LUT, but stripping it
    // (dovi=no) would break profile-5 rendering outright, so it stays.
    mpv_set_option_string(mpv_, "tone-mapping", "auto");
    adreno_tone_map_workaround_ = SystemHasQualcommGpu();
    mpv_set_option_string(mpv_, "hdr-compute-peak", adreno_tone_map_workaround_ ? "no" : "auto");
    if (adreno_tone_map_workaround_) {
      mpv_set_option_string(mpv_, "vf", "format:hdr10plus=no");
    }
  }

  // Default to warn-level logging; Dart side can raise to "v" if debug logging is enabled.
  mpv_request_log_messages(mpv_, "warn");

  // Initialize mpv.
  int err = mpv_initialize(mpv_);
  if (err < 0) {
    if (hwnd_) {
      DetachMpvInnerSubclass();
      forward_target_view_ = nullptr;
      ::DestroyWindow(hwnd_);
      hwnd_ = nullptr;
    }
    mpv_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  mpv_observe_property(mpv_, 0, "current-ao", MPV_FORMAT_STRING);
  // Native observation so audio recovery doesn't depend on the Dart side
  // choosing to observe the device list.
  mpv_observe_property(mpv_, 0, "audio-device-list", MPV_FORMAT_NONE);

  // Start event loop.
  StartEventLoop();

  return true;
}

void MpvPlayer::Dispose() {
  StopEventLoop();

  auto cancelled = pending_requests_.CancelAll();
  for (auto& callback : cancelled.status) {
    callback(MPV_ERROR_UNINITIALIZED);
  }
  for (auto& callback : cancelled.commands) {
    callback(MPV_ERROR_UNINITIALIZED, nullptr);
  }
  for (auto& callback : cancelled.properties) {
    callback(-1, "");
  }

  // Detach the native handle before releasing platform-owned state. mpv can
  // block in demuxer/network teardown, so only the detached handle crosses to
  // the worker; it must not retain this player, callbacks, or HWNDs.
  auto* handle = mpv_;
  mpv_ = nullptr;

  // The input subclass must stop referencing this player generation before
  // either the host HWND or the player object can be destroyed.
  DetachMpvInnerSubclass();
  forward_target_view_ = nullptr;

  if (hwnd_) {
    ::ShowWindow(hwnd_, SW_HIDE);
    ::DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }

  if (handle) {
    std::thread([handle]() { mpv_terminate_destroy(handle); }).detach();
  }

  observed_properties_.Clear();
}

void MpvPlayer::Command(const std::vector<std::string>& args) { CommandAsync(args, nullptr); }

void MpvPlayer::CommandAsync(const std::vector<std::string>& args, CommandCallback callback) {
  if (!mpv_) {
    if (callback) callback(0, nullptr);
    return;
  }

  plezy::mpv_common::SubmitCommandAsync(mpv_, pending_requests_, args, std::move(callback));
}

void MpvPlayer::SetProperty(const std::string& name, const std::string& value) {
  SetPropertyAsync(name, value, nullptr);
}

void MpvPlayer::SetPropertyAsync(const std::string& name, const std::string& value, StatusCallback callback) {
  if (!mpv_) {
    if (callback) callback(MPV_ERROR_UNINITIALIZED);
    return;
  }

  // Handle custom HDR toggle property (same pattern as iOS/macOS)
  if (name == "hdr-enabled") {
    SetHDREnabled(plezy::mpv_common::ParseEnabledFlag(value), std::move(callback));
    return;
  }

  plezy::mpv_common::SubmitSetPropertyAsync(mpv_, pending_requests_, name, value, std::move(callback));
}

void MpvPlayer::GetPropertyAsync(const std::string& name, GetPropertyCallback callback) {
  if (!mpv_) {
    if (callback) callback(-1, "");
    return;
  }

  plezy::mpv_common::SubmitGetPropertyAsync(mpv_, pending_requests_, name, std::move(callback));
}

void MpvPlayer::ObserveProperty(const std::string& name, const std::string& format, int id) {
  if (!mpv_) return;

  const auto request = observed_properties_.Register(name, format, id);
  if (!request.added) return;
  mpv_observe_property(mpv_, request.userdata, name.c_str(), request.format);
}

void MpvPlayer::SetRect(RECT rect, double device_pixel_ratio) {
  if (!hwnd_) {
    return;
  }

  // The video window is a child of the Flutter view; the Dart rect is already
  // in view physical pixels, which is exactly the child coordinate space. No
  // screen mapping, no padding.
  ::SetWindowPos(hwnd_, HWND_TOP, rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, SWP_NOACTIVATE);

  // mpv creates its inner window lazily on its own thread; subclass it (and
  // re-subclass if mpv ever recreates it) so mouse and pointer input over the
  // video is forwarded to the Flutter view.
  EnsureMpvInnerSubclassed();
}

void MpvPlayer::SetVisible(bool visible) {
  if (hwnd_) {
    ::ShowWindow(hwnd_, visible ? SW_SHOW : SW_HIDE);
  }
}

void MpvPlayer::SetLogLevel(const std::string& level) {
  if (!mpv_) return;
  mpv_request_log_messages(mpv_, level.c_str());
}

void MpvPlayer::SetEventCallback(EventCallback callback) {
  std::lock_guard<std::mutex> lock(callback_mutex_);
  event_callback_ = std::move(callback);
}

void MpvPlayer::NotifyPowerSuspend() { LogRecovery("system suspending"); }

void MpvPlayer::NotifyPowerResume() { audio_recovery_.RequestResume(); }

void MpvPlayer::LogRecovery(const std::string& text) {
  char log_msg[512];
  snprintf(log_msg, sizeof(log_msg), "MPV [warn] audio-recovery: %s", text.c_str());
  OutputDebugStringA(log_msg);

  // Emitted as a synthetic log-message event so it reaches the app logs
  // regardless of the mpv log level.
  flutter::EncodableMap data;
  data[flutter::EncodableValue("prefix")] = flutter::EncodableValue("audio-recovery");
  data[flutter::EncodableValue("level")] = flutter::EncodableValue("warn");
  data[flutter::EncodableValue("text")] = flutter::EncodableValue(text);
  SendEvent("log-message", data);
}

void MpvPlayer::LogHdrPipelineOnce() {
  if (hdr_config_logged_ || audio_only_) return;
  hdr_config_logged_ = true;
  const char* text = adreno_tone_map_workaround_ ? "Qualcomm GPU: hdr-compute-peak=no, vf=format:hdr10plus=no"
                                                 : "hdr-compute-peak=auto";
  flutter::EncodableMap data;
  data[flutter::EncodableValue("prefix")] = flutter::EncodableValue("hdr-config");
  data[flutter::EncodableValue("level")] = flutter::EncodableValue("info");
  data[flutter::EncodableValue("text")] = flutter::EncodableValue(text);
  SendEvent("log-message", data);
}

void MpvPlayer::TryAudioReload(const char* reason, int attempt, uint64_t request_generation) {
  LogRecovery("issuing ao-reload (reason=" + std::string(reason) + ", attempt " + std::to_string(attempt) + ")");
  const std::string reason_copy = reason;
  CommandAsync({"ao-reload"}, [this, reason_copy, attempt, request_generation](int error, const mpv_node*) {
    audio_recovery_.CompleteReload(request_generation);
    LogRecovery(
        "ao-reload completed (reason=" + reason_copy + ", attempt " + std::to_string(attempt) +
        ", error=" + std::to_string(error) + ")");
  });
}

void MpvPlayer::MaybeRunAudioRecovery() {
  const auto action = audio_recovery_.NextReload(plezy::mpv_common::AudioRecoveryState::Clock::now());
  if (action.reason == plezy::mpv_common::AudioReloadReason::kNone) {
    return;
  }
  const char* reason = action.reason == plezy::mpv_common::AudioReloadReason::kResume ? "resume" : "null-fallback";
  TryAudioReload(reason, action.attempt, action.request_generation);
  if (action.exhausted) {
    LogRecovery("audio recovery budget exhausted; waiting for device list change");
  }
}

void MpvPlayer::StartEventLoop() {
  running_ = true;
  event_thread_ = std::thread(&MpvPlayer::EventLoop, this);
}

void MpvPlayer::StopEventLoop() {
  running_ = false;
  if (event_thread_.joinable()) {
    // Wake up the event loop.
    if (mpv_) {
      mpv_wakeup(mpv_);
    }
    event_thread_.join();
  }
}

void MpvPlayer::EventLoop() {
  while (running_) {
    mpv_event* event = mpv_wait_event(mpv_, 0.1);
    if (event->event_id == MPV_EVENT_SHUTDOWN) {
      break;
    }
    if (event->event_id != MPV_EVENT_NONE) {
      HandleMpvEvent(event);
    }
    // Idle waits are bounded at 100 ms; queued events can wake us sooner.
    // Audio recovery owns its elapsed-time deadlines.
    MaybeRunAudioRecovery();
  }
}

void MpvPlayer::HandleMpvEvent(mpv_event* event) {
  if (plezy::mpv_common::DispatchReplyEvent(
          pending_requests_, event, [](const char* value) { return SanitizeUtf8(value); })) {
    return;
  }

  switch (event->event_id) {
    case MPV_EVENT_LOG_MESSAGE: {
      auto* msg = static_cast<mpv_event_log_message*>(event->data);
      char log_msg[512];
      snprintf(log_msg, sizeof(log_msg), "MPV [%s] %s: %s", msg->level, msg->prefix, msg->text);
      OutputDebugStringA(log_msg);

      flutter::EncodableMap data;
      data[flutter::EncodableValue("prefix")] = flutter::EncodableValue(SanitizeUtf8(msg->prefix));
      data[flutter::EncodableValue("level")] = flutter::EncodableValue(SanitizeUtf8(msg->level));
      data[flutter::EncodableValue("text")] = flutter::EncodableValue(SanitizeUtf8(msg->text));
      SendEvent("log-message", data);
      break;
    }
    case MPV_EVENT_PROPERTY_CHANGE: {
      auto* prop = static_cast<mpv_event_property*>(event->data);
      mpv_node node = plezy::mpv_common::ExtractPropertyNode(prop);

      // The 100ms mpv_wait_event tick already polls for scheduled reloads.
      const auto notice = plezy::mpv_common::ObserveAudioRecoveryProperty(audio_recovery_, event, prop);
      if (notice.message) LogRecovery(notice.message);

      SendPropertyChange(prop->name, &node);
      break;
    }
    case MPV_EVENT_END_FILE: {
      audio_recovery_.SetFileLoaded(false);
      auto* end = static_cast<mpv_event_end_file*>(event->data);
      flutter::EncodableMap data;
      data[flutter::EncodableValue("sourceId")] = flutter::EncodableValue(end->playlist_entry_id);
      data[flutter::EncodableValue("reason")] = flutter::EncodableValue(static_cast<int>(end->reason));
      if (end->reason == MPV_END_FILE_REASON_ERROR) {
        data[flutter::EncodableValue("error")] = flutter::EncodableValue(static_cast<int>(end->error));
        data[flutter::EncodableValue("message")] = flutter::EncodableValue(SanitizeUtf8(mpv_error_string(end->error)));
      }
      SendEvent("end-file", data);
      break;
    }
    case MPV_EVENT_START_FILE: {
      auto* start = static_cast<mpv_event_start_file*>(event->data);
      active_source_id_ = start->playlist_entry_id;
      has_active_source_id_ = true;
      SendActiveSourceEvent("start-file");
      break;
    }
    case MPV_EVENT_FILE_LOADED: {
      audio_recovery_.SetFileLoaded(true);
      // Deferred to here rather than Initialize: the Dart event callback is
      // wired by the time a file loads, and the synthetic event bypasses the
      // mpv log level, so the applied HDR pipeline options always land in an
      // uploaded log (#2191 was undiagnosable without this).
      LogHdrPipelineOnce();
      SendActiveSourceEvent("file-loaded");
      break;
    }
    case MPV_EVENT_PLAYBACK_RESTART: {
      double position_seconds = 0.0;
      const double* position = nullptr;
      if (mpv_ && mpv_get_property(mpv_, "time-pos", MPV_FORMAT_DOUBLE, &position_seconds) >= 0) {
        position = &position_seconds;
      }
      // mpv's inner window exists by now (vo is configured); make sure the
      // DComp-mode input forwarding subclass is installed. SetRect alone can
      // miss it: the rect often settles before mpv creates the window.
      EnsureMpvInnerSubclassed();
      SendPlaybackRestartEvent(position);
      break;
    }
    default:
      break;
  }
}

void MpvPlayer::SendPropertyChange(const char* name, mpv_node* data) {
  if (!name) return;

  int id = 0;
  if (!observed_properties_.LookupId(name, &id)) return;

  // mpv owns event node storage; copy the full tree before the callback can
  // queue it beyond the current mpv_wait_event result's lifetime.
  flutter::EncodableList list;
  list.push_back(flutter::EncodableValue(id));
  list.push_back(NodeToEncodableValue(data));
  if (has_active_source_id_) {
    list.push_back(flutter::EncodableValue(active_source_id_));
  } else {
    list.push_back(flutter::EncodableValue());
  }

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(flutter::EncodableValue(list));
  }
}

void MpvPlayer::SendActiveSourceEvent(const std::string& name) {
  flutter::EncodableMap data;
  if (has_active_source_id_) {
    data[flutter::EncodableValue("sourceId")] = flutter::EncodableValue(active_source_id_);
  }
  SendEvent(name, data);
}

void MpvPlayer::SendPlaybackRestartEvent(const double* position_seconds) {
  flutter::EncodableMap data;
  if (has_active_source_id_) {
    data[flutter::EncodableValue("sourceId")] = flutter::EncodableValue(active_source_id_);
  }
  if (position_seconds && std::isfinite(*position_seconds)) {
    data[flutter::EncodableValue("positionSeconds")] = flutter::EncodableValue(*position_seconds);
  }
  SendEvent("playback-restart", data);
}

void MpvPlayer::SendEvent(const std::string& name, const flutter::EncodableMap& data) {
  flutter::EncodableMap event;
  event[flutter::EncodableValue("type")] = flutter::EncodableValue("event");
  event[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
  if (!data.empty()) {
    event[flutter::EncodableValue("data")] = flutter::EncodableValue(data);
  }

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(flutter::EncodableValue(event));
  }
}

void MpvPlayer::SetHDREnabled(bool enabled, StatusCallback callback) {
  hdr_enabled_ = enabled;
  if (!mpv_) {
    if (callback) callback(0);
    return;
  }
  SetPropertyAsync("target-colorspace-hint", plezy::mpv_common::TargetColorspaceHint(enabled), std::move(callback));
}

}  // namespace mpv
