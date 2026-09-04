#include <windowsx.h>

#include <atomic>
#include <cstdlib>
#include <functional>
#include <future>
#include <iostream>
#include <limits>
#include <thread>
#include <utility>
#include <vector>

#include "mpv_player.h"

namespace mpv {

class MpvPlayerPropertyContractTestPeer {
 public:
  static void RegisterPendingPropertyWrite(MpvPlayer& player, MpvPlayer::StatusCallback callback) {
    player.pending_requests_.RegisterStatus(std::move(callback));
  }

  static void RegisterPendingPropertyRead(MpvPlayer& player, MpvPlayer::GetPropertyCallback callback) {
    player.pending_requests_.RegisterProperty(std::move(callback));
  }
  static void RegisterObservedNode(MpvPlayer& player, const std::string& name, int id) {
    player.observed_properties_.Register(name, "node", id);
  }

  static void HandleEvent(MpvPlayer& player, mpv_event* event) { player.HandleMpvEvent(event); }

  static void SendPlaybackRestart(MpvPlayer& player, const double* position_seconds) {
    player.SendPlaybackRestartEvent(position_seconds);
  }
  static void ConfigureInnerSubclass(MpvPlayer& player, HWND host, HWND target) {
    player.hwnd_ = host;
    player.forward_target_view_ = target;
  }

  static void EnsureInnerSubclass(MpvPlayer& player) { player.EnsureMpvInnerSubclassed(); }

  static void DetachInnerSubclass(MpvPlayer& player) { player.DetachMpvInnerSubclass(); }
  static const void* InnerSubclassIdentity(const MpvPlayer& player) { return player.inner_subclass_.get(); }

  static void ReleaseTestWindows(MpvPlayer& player) {
    player.DetachMpvInnerSubclass();
    player.hwnd_ = nullptr;
    player.forward_target_view_ = nullptr;
  }
};

namespace {

void Check(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "mpv_player_property_contract_test: " << message << '\n';
    std::exit(1);
  }
}

const flutter::EncodableMap& RequireMap(const flutter::EncodableValue& value, const char* message) {
  Check(std::holds_alternative<flutter::EncodableMap>(value), message);
  return std::get<flutter::EncodableMap>(value);
}

const flutter::EncodableValue& RequireMapField(const flutter::EncodableMap& map, const char* key, const char* message) {
  auto value = map.find(flutter::EncodableValue(key));
  Check(value != map.end(), message);
  return value->second;
}

const flutter::EncodableMap& RequireEventData(const flutter::EncodableValue& event, const char* expected_name) {
  const auto& envelope = RequireMap(event, "lifecycle event must be a map");
  const auto& name = RequireMapField(envelope, "name", "lifecycle event name is missing");
  Check(
      std::holds_alternative<std::string>(name) && std::get<std::string>(name) == expected_name,
      "lifecycle event name changed");
  return RequireMap(
      RequireMapField(envelope, "data", "source-qualified lifecycle event data is missing"),
      "lifecycle event data must be a map");
}

int64_t RequireSourceId(const flutter::EncodableMap& data, const char* message) {
  const auto& source_id = RequireMapField(data, "sourceId", message);
  Check(std::holds_alternative<int64_t>(source_id), "source ID must use the signed 64-bit codec type");
  return std::get<int64_t>(source_id);
}

void TestSourceQualifiedEventPayloads() {
  MpvPlayer player;
  MpvPlayerPropertyContractTestPeer::RegisterObservedNode(player, "track-list", 42);
  std::vector<flutter::EncodableValue> events;
  player.SetEventCallback([&events](const flutter::EncodableValue& event) { events.push_back(event); });

  mpv_event_property property{};
  property.name = "track-list";
  property.format = MPV_FORMAT_NODE;
  mpv_event property_event{};
  property_event.event_id = MPV_EVENT_PROPERTY_CHANGE;
  property_event.data = &property;
  MpvPlayerPropertyContractTestPeer::HandleEvent(player, &property_event);

  constexpr int64_t kFirstSourceId = -5000000001LL;
  mpv_event_start_file start{};
  start.playlist_entry_id = kFirstSourceId;
  mpv_event start_event{};
  start_event.event_id = MPV_EVENT_START_FILE;
  start_event.data = &start;
  MpvPlayerPropertyContractTestPeer::HandleEvent(player, &start_event);
  MpvPlayerPropertyContractTestPeer::HandleEvent(player, &property_event);

  mpv_event file_loaded{};
  file_loaded.event_id = MPV_EVENT_FILE_LOADED;
  MpvPlayerPropertyContractTestPeer::HandleEvent(player, &file_loaded);

  mpv_event playback_restart{};
  playback_restart.event_id = MPV_EVENT_PLAYBACK_RESTART;
  MpvPlayerPropertyContractTestPeer::HandleEvent(player, &playback_restart);
  const double position_seconds = 17.25;
  MpvPlayerPropertyContractTestPeer::SendPlaybackRestart(player, &position_seconds);
  const double invalid_position = std::numeric_limits<double>::infinity();
  MpvPlayerPropertyContractTestPeer::SendPlaybackRestart(player, &invalid_position);

  constexpr int64_t kEndedSourceId = 6000000002LL;
  mpv_event_end_file end{};
  end.reason = MPV_END_FILE_REASON_ERROR;
  end.error = MPV_ERROR_LOADING_FAILED;
  end.playlist_entry_id = kEndedSourceId;
  mpv_event end_event{};
  end_event.event_id = MPV_EVENT_END_FILE;
  end_event.data = &end;
  MpvPlayerPropertyContractTestPeer::HandleEvent(player, &end_event);

  constexpr int64_t kNextSourceId = 7000000003LL;
  start.playlist_entry_id = kNextSourceId;
  MpvPlayerPropertyContractTestPeer::HandleEvent(player, &start_event);

  Check(events.size() == 9, "source-qualified event sequence changed");

  const auto& property_before_start = std::get<flutter::EncodableList>(events[0]);
  Check(property_before_start.size() == 3, "property event must contain ID, value, and source ID");
  Check(
      std::holds_alternative<int32_t>(property_before_start[0]) && std::get<int32_t>(property_before_start[0]) == 42,
      "property event ID changed");
  Check(std::holds_alternative<std::monostate>(property_before_start[1]), "missing property data must remain null");
  Check(
      std::holds_alternative<std::monostate>(property_before_start[2]),
      "property source must be null before START_FILE");

  const auto& start_data = RequireEventData(events[1], "start-file");
  Check(
      RequireSourceId(start_data, "start-file source ID is missing") == kFirstSourceId,
      "start-file source ID lost signed 64-bit precision");

  const auto& source_property = std::get<flutter::EncodableList>(events[2]);
  Check(source_property.size() == 3, "source-qualified property event must remain a triple");
  Check(
      std::holds_alternative<int64_t>(source_property[2]) && std::get<int64_t>(source_property[2]) == kFirstSourceId,
      "property event did not retain the active source ID");

  const auto& loaded_data = RequireEventData(events[3], "file-loaded");
  Check(
      RequireSourceId(loaded_data, "file-loaded source ID is missing") == kFirstSourceId,
      "file-loaded source ID changed");

  const auto& restart_without_position = RequireEventData(events[4], "playback-restart");
  Check(
      RequireSourceId(restart_without_position, "playback-restart source ID is missing") == kFirstSourceId,
      "playback-restart source ID changed");
  Check(
      restart_without_position.find(flutter::EncodableValue("positionSeconds")) == restart_without_position.end(),
      "unavailable playback position must not be manufactured");

  const auto& restart_data = RequireEventData(events[5], "playback-restart");
  Check(
      RequireSourceId(restart_data, "positioned playback-restart source ID is missing") == kFirstSourceId,
      "positioned playback-restart source ID changed");
  const auto& restart_position =
      RequireMapField(restart_data, "positionSeconds", "finite playback position is missing");
  Check(
      std::holds_alternative<double>(restart_position) && std::get<double>(restart_position) == position_seconds,
      "playback-restart position changed");

  const auto& invalid_restart_data = RequireEventData(events[6], "playback-restart");
  Check(
      invalid_restart_data.find(flutter::EncodableValue("positionSeconds")) == invalid_restart_data.end(),
      "non-finite playback position must not enter the channel payload");

  const auto& end_data = RequireEventData(events[7], "end-file");
  Check(
      RequireSourceId(end_data, "end-file source ID is missing") == kEndedSourceId,
      "end-file must use its event-specific source ID");
  const auto& end_reason = RequireMapField(end_data, "reason", "end-file reason is missing");
  Check(
      std::holds_alternative<int32_t>(end_reason) && std::get<int32_t>(end_reason) == MPV_END_FILE_REASON_ERROR,
      "end-file reason changed");
  const auto& end_error = RequireMapField(end_data, "error", "end-file error is missing");
  Check(
      std::holds_alternative<int32_t>(end_error) && std::get<int32_t>(end_error) == MPV_ERROR_LOADING_FAILED,
      "end-file error changed");
  Check(
      std::holds_alternative<std::string>(RequireMapField(end_data, "message", "end-file message is missing")),
      "end-file message changed type");

  const auto& next_start_data = RequireEventData(events[8], "start-file");
  Check(
      RequireSourceId(next_start_data, "replacement source ID is missing") == kNextSourceId,
      "replacement source ID changed");
  Check(
      std::get<int64_t>(source_property[2]) == kFirstSourceId, "later START_FILE relabeled an already-queued property");

  player.SetEventCallback(nullptr);
}

std::atomic<int> g_forwarded_mouse_messages{0};
std::atomic<int> g_forwarded_touch_moves{0};
std::atomic<int> g_forwarded_mouse_down_messages{0};
std::atomic<int> g_forwarded_mouse_up_messages{0};
std::atomic<int> g_forwarded_pointer_messages{0};
std::atomic<LPARAM> g_forwarded_mouse_down_position{0};
std::atomic<LPARAM> g_forwarded_mouse_up_position{0};
std::atomic<WPARAM> g_forwarded_mouse_down_flags{0};
std::atomic<WPARAM> g_forwarded_mouse_up_flags{0};
constexpr UINT kBlockWindowThreadMessage = WM_APP + 0x0505;
std::atomic<HANDLE> g_block_entered{nullptr};
std::atomic<HANDLE> g_block_release{nullptr};
std::atomic<HANDLE> g_block_exited{nullptr};

// A WM_POINTER message cannot be handed to a window owned by another thread:
// the system drops a cross-thread send and refuses the post outright with
// ERROR_MESSAGE_SYNC_ONLY, because pointer data belongs to the queue of the
// thread that retrieved it. Driving mpv's window from the test thread therefore
// delivers nothing at all. This relays the send through the window's own thread,
// which is also where the real messages arrive in production.
constexpr UINT kDispatchOnOwnerThreadMessage = WM_APP + 0x0506;
struct OwnerThreadDispatch {
  HWND target;
  UINT message;
  WPARAM wparam;
  LPARAM lparam;
};
std::atomic<HWND> g_routing_view{nullptr};
std::atomic<int> g_routing_view_presses{0};
std::atomic<int> g_routing_child_presses{0};

LRESULT CALLBACK CountingWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == kBlockWindowThreadMessage) {
    const HANDLE entered = g_block_entered.load(std::memory_order_acquire);
    const HANDLE release = g_block_release.load(std::memory_order_acquire);
    const HANDLE exited = g_block_exited.load(std::memory_order_acquire);
    if (entered && release && exited) {
      ::SetEvent(entered);
      ::WaitForSingleObject(release, INFINITE);
      ::SetEvent(exited);
    }
    return 0;
  }
  if (message == kDispatchOnOwnerThreadMessage) {
    const auto* dispatch = reinterpret_cast<const OwnerThreadDispatch*>(lparam);
    return ::SendMessageW(dispatch->target, dispatch->message, dispatch->wparam, dispatch->lparam);
  }
  if (message == WM_MOUSEMOVE) {
    if ((wparam & MK_LBUTTON) != 0) {
      g_forwarded_touch_moves.fetch_add(1, std::memory_order_relaxed);
    } else {
      g_forwarded_mouse_messages.fetch_add(1, std::memory_order_relaxed);
    }
    return 0;
  }
  if (message == WM_LBUTTONDOWN) {
    g_forwarded_mouse_down_position.store(lparam, std::memory_order_relaxed);
    g_forwarded_mouse_down_flags.store(wparam, std::memory_order_relaxed);
    g_forwarded_mouse_down_messages.fetch_add(1, std::memory_order_relaxed);
    return 0;
  }
  if (message == WM_LBUTTONUP) {
    g_forwarded_mouse_up_position.store(lparam, std::memory_order_relaxed);
    g_forwarded_mouse_up_flags.store(wparam, std::memory_order_relaxed);
    g_forwarded_mouse_up_messages.fetch_add(1, std::memory_order_relaxed);
    return 0;
  }
  if (message >= WM_POINTERUPDATE && message <= WM_POINTERCAPTURECHANGED) {
    g_forwarded_pointer_messages.fetch_add(1, std::memory_order_relaxed);
    return 0;
  }
  return ::DefWindowProcW(hwnd, message, wparam, lparam);
}

// Sends |message| to |target| from the thread that owns |owner_window|, so a
// WM_POINTER message reaches the window procedure instead of being discarded as
// a cross-thread send. |owner_window| must be handled by CountingWindowProc and
// live on the same thread as |target|.
LRESULT SendFromOwnerThread(HWND owner_window, HWND target, UINT message, WPARAM wparam, LPARAM lparam) {
  OwnerThreadDispatch dispatch{target, message, wparam, lparam};
  return ::SendMessageW(owner_window, kDispatchOnOwnerThreadMessage, 0, reinterpret_cast<LPARAM>(&dispatch));
}

// Attributes a real button press to the window that received it. Installed on
// the stand-in view and on every window of the video subtree below it. The
// STATIC class answers WM_NCHITTEST with HTTRANSPARENT, which would take these
// windows out of the hit test for a reason other than the one under test, so
// every one of them claims its client area here.
LRESULT CALLBACK RoutingWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCHITTEST) {
    return HTCLIENT;
  }
  if (message == WM_LBUTTONDOWN || message == WM_LBUTTONDBLCLK) {
    if (hwnd == g_routing_view.load(std::memory_order_acquire)) {
      g_routing_view_presses.fetch_add(1, std::memory_order_relaxed);
    } else {
      g_routing_child_presses.fetch_add(1, std::memory_order_relaxed);
    }
    return 0;
  }
  return ::DefWindowProcW(hwnd, message, wparam, lparam);
}

// Pumps this thread's queue until |predicate| holds or the budget runs out.
bool PumpUntil(const std::function<bool()>& predicate, DWORD timeout_ms) {
  const ULONGLONG deadline = ::GetTickCount64() + timeout_ms;
  for (;;) {
    MSG message;
    while (::PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
      ::TranslateMessage(&message);
      ::DispatchMessageW(&message);
    }
    if (predicate()) return true;
    if (::GetTickCount64() >= deadline) return false;
    ::Sleep(5);
  }
}

bool SendAbsoluteMouse(POINT screen_point, DWORD flags) {
  const LONG width = ::GetSystemMetrics(SM_CXSCREEN);
  const LONG height = ::GetSystemMetrics(SM_CYSCREEN);
  if (width < 2 || height < 2) return false;
  INPUT input = {};
  input.type = INPUT_MOUSE;
  input.mi.dx = static_cast<LONG>((static_cast<LONG64>(screen_point.x) * 65535) / (width - 1));
  input.mi.dy = static_cast<LONG>((static_cast<LONG64>(screen_point.y) * 65535) / (height - 1));
  input.mi.dwFlags = MOUSEEVENTF_ABSOLUTE | flags;
  return ::SendInput(1, &input, sizeof(input)) == 1;
}

bool InjectClick(POINT screen_point) {
  return SendAbsoluteMouse(screen_point, MOUSEEVENTF_MOVE) && SendAbsoluteMouse(screen_point, MOUSEEVENTF_LEFTDOWN) &&
         SendAbsoluteMouse(screen_point, MOUSEEVENTF_LEFTUP);
}

// A real touch contact at |screen_point|, for the touch half of the routing
// test. The contact is held across a few frames rather than sent as a bare
// down/up pair, because a contact that lifts in the same frame it landed is
// short enough for a consumer to discard as noise.
bool InjectTap(POINT screen_point) {
  POINTER_TOUCH_INFO contact = {};
  contact.pointerInfo.pointerType = PT_TOUCH;
  contact.pointerInfo.pointerId = 0;
  contact.pointerInfo.ptPixelLocation = screen_point;
  contact.touchFlags = TOUCH_FLAG_NONE;
  contact.touchMask = TOUCH_MASK_CONTACTAREA | TOUCH_MASK_ORIENTATION | TOUCH_MASK_PRESSURE;
  contact.rcContact.left = screen_point.x - 2;
  contact.rcContact.top = screen_point.y - 2;
  contact.rcContact.right = screen_point.x + 2;
  contact.rcContact.bottom = screen_point.y + 2;
  contact.orientation = 90;
  contact.pressure = 32000;

  contact.pointerInfo.pointerFlags = POINTER_FLAG_DOWN | POINTER_FLAG_INRANGE | POINTER_FLAG_INCONTACT;
  if (!::InjectTouchInput(1, &contact)) return false;
  contact.pointerInfo.pointerFlags = POINTER_FLAG_UPDATE | POINTER_FLAG_INRANGE | POINTER_FLAG_INCONTACT;
  for (int frame = 0; frame < 5; ++frame) {
    ::Sleep(20);
    if (!::InjectTouchInput(1, &contact)) return false;
  }
  contact.pointerInfo.pointerFlags = POINTER_FLAG_UP;
  return ::InjectTouchInput(1, &contact) != FALSE;
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
  MpvPlayerPropertyContractTestPeer::RegisterPendingPropertyWrite(player, [&](int error) {
    ++callback_count;
    status = error;
  });

  player.Dispose();
  Check(callback_count == 1, "dispose must complete a pending property write exactly once");
  Check(status == MPV_ERROR_UNINITIALIZED, "dispose must cancel a pending property write as uninitialized");

  player.Dispose();
  Check(callback_count == 1, "repeated dispose must not complete a property write twice");
}

void TestPendingRequestTypesRemainDistinctOnDispose() {
  MpvPlayer player;
  int write_count = 0;
  int read_count = 0;
  std::string read_value = "unexpected";
  MpvPlayerPropertyContractTestPeer::RegisterPendingPropertyWrite(player, [&](int error) {
    Check(error < 0, "cancelled property write must receive an error");
    ++write_count;
  });
  MpvPlayerPropertyContractTestPeer::RegisterPendingPropertyRead(player, [&](int error, const std::string& value) {
    Check(error < 0, "cancelled property read must receive an error");
    ++read_count;
    read_value = value;
  });

  player.Dispose();
  Check(write_count == 1, "dispose must complete the typed write request exactly once");
  Check(read_count == 1, "dispose must complete the typed read request exactly once");
  Check(read_value.empty(), "cancelled property reads must not manufacture a value");
}

void TestInnerSubclassOwnershipIsSerializedAndDetached() {
  struct TestWindows {
    HWND target;
    HWND host;
    HWND inner;
    WNDPROC inner_original;
    DWORD owner_thread;
  };

  std::promise<TestWindows> windows_created;
  auto windows_future = windows_created.get_future();
  std::thread window_owner([&]() {
    HWND target =
        ::CreateWindowExW(0, L"STATIC", L"", WS_OVERLAPPED, 0, 0, 100, 100, nullptr, nullptr, nullptr, nullptr);
    HWND host = ::CreateWindowExW(0, L"STATIC", L"", WS_CHILD, 0, 0, 100, 100, target, nullptr, nullptr, nullptr);
    HWND inner = ::CreateWindowExW(0, L"STATIC", L"", WS_CHILD, 0, 0, 100, 100, host, nullptr, nullptr, nullptr);
    const auto target_original = reinterpret_cast<WNDPROC>(
        ::SetWindowLongPtrW(target, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(CountingWindowProc)));
    const auto inner_original = reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(inner, GWLP_WNDPROC));
    windows_created.set_value(TestWindows{target, host, inner, inner_original, ::GetCurrentThreadId()});

    MSG message;
    while (::GetMessageW(&message, nullptr, 0, 0) > 0) {
      ::TranslateMessage(&message);
      ::DispatchMessageW(&message);
    }

    ::SetWindowLongPtrW(target, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(target_original));
    ::DestroyWindow(inner);
    ::DestroyWindow(host);
    ::DestroyWindow(target);
  });

  const TestWindows windows = windows_future.get();
  Check(windows.target && windows.host && windows.inner, "test windows must be created");
  MpvPlayer player;

  MpvPlayerPropertyContractTestPeer::ConfigureInnerSubclass(player, windows.host, windows.target);
  std::thread first([&]() { MpvPlayerPropertyContractTestPeer::EnsureInnerSubclass(player); });
  std::thread second([&]() { MpvPlayerPropertyContractTestPeer::EnsureInnerSubclass(player); });
  first.join();
  second.join();

  const auto installed = reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC));
  Check(installed && installed != windows.inner_original, "exactly one subclass procedure must be installed");
  ::SendMessageW(windows.inner, WM_NULL, 0, 0);

  ::SendMessageW(windows.inner, WM_MOUSEMOVE, 0, MAKELPARAM(4, 7));
  for (int attempt = 0; attempt < 100 && g_forwarded_mouse_messages.load(std::memory_order_relaxed) < 1; ++attempt) {
    ::Sleep(10);
  }
  Check(g_forwarded_mouse_messages.load(std::memory_order_relaxed) == 1, "active generation must forward mouse input");

  constexpr UINT32 kPrimaryPointerId = 7;
  constexpr UINT32 kSecondaryPointerId = 8;
  constexpr UINT32 kCancelledPointerId = 9;
  constexpr UINT32 kDetachedPointerId = 10;
  constexpr UINT32 kDestroyedPointerId = 11;
  constexpr UINT32 kPointerDownFlags = POINTER_MESSAGE_FLAG_NEW | POINTER_MESSAGE_FLAG_INRANGE |
                                       POINTER_MESSAGE_FLAG_INCONTACT | POINTER_MESSAGE_FLAG_FIRSTBUTTON |
                                       POINTER_MESSAGE_FLAG_PRIMARY;
  constexpr UINT32 kPointerMoveFlags = POINTER_MESSAGE_FLAG_INRANGE | POINTER_MESSAGE_FLAG_INCONTACT |
                                       POINTER_MESSAGE_FLAG_FIRSTBUTTON | POINTER_MESSAGE_FLAG_PRIMARY;
  constexpr UINT32 kPointerUpFlags = POINTER_MESSAGE_FLAG_INRANGE | POINTER_MESSAGE_FLAG_PRIMARY;

  POINT down_position = {14, 18};
  ::ClientToScreen(windows.inner, &down_position);
  POINT expected_down_position = down_position;
  ::ScreenToClient(windows.target, &expected_down_position);
  POINT up_position = {30, 36};
  ::ClientToScreen(windows.inner, &up_position);
  POINT expected_up_position = up_position;
  ::ScreenToClient(windows.target, &expected_up_position);

  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERDOWN, MAKEWPARAM(kPrimaryPointerId, kPointerDownFlags),
      MAKELPARAM(down_position.x, down_position.y));
  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERUPDATE, MAKEWPARAM(kPrimaryPointerId, kPointerMoveFlags),
      MAKELPARAM(up_position.x, up_position.y));
  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERUP, MAKEWPARAM(kPrimaryPointerId, kPointerUpFlags),
      MAKELPARAM(up_position.x, up_position.y));
  for (int attempt = 0; attempt < 100 && g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) < 1; ++attempt) {
    ::Sleep(10);
  }

  Check(g_forwarded_mouse_down_messages.load(std::memory_order_relaxed) == 1, "primary touch must press once");
  Check(g_forwarded_touch_moves.load(std::memory_order_relaxed) == 1, "primary touch movement must drag once");
  Check(g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) == 1, "primary touch must release once");
  Check(
      g_forwarded_pointer_messages.load(std::memory_order_relaxed) == 0, "raw pointer messages must not reach Flutter");
  Check(
      g_forwarded_mouse_down_flags.load(std::memory_order_relaxed) == MK_LBUTTON,
      "touch down must hold the mouse button");
  Check(g_forwarded_mouse_up_flags.load(std::memory_order_relaxed) == 0, "touch up must release the mouse button");
  const LPARAM forwarded_down_position = g_forwarded_mouse_down_position.load(std::memory_order_relaxed);
  Check(
      GET_X_LPARAM(forwarded_down_position) == expected_down_position.x &&
          GET_Y_LPARAM(forwarded_down_position) == expected_down_position.y,
      "touch down must use Flutter-view client coordinates");
  const LPARAM forwarded_up_position = g_forwarded_mouse_up_position.load(std::memory_order_relaxed);
  Check(
      GET_X_LPARAM(forwarded_up_position) == expected_up_position.x &&
          GET_Y_LPARAM(forwarded_up_position) == expected_up_position.y,
      "touch up must use Flutter-view client coordinates");

  const WPARAM secondary_down = MAKEWPARAM(kSecondaryPointerId, kPointerDownFlags & ~POINTER_MESSAGE_FLAG_PRIMARY);
  const WPARAM secondary_up = MAKEWPARAM(kSecondaryPointerId, kPointerUpFlags & ~POINTER_MESSAGE_FLAG_PRIMARY);
  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERDOWN, secondary_down, MAKELPARAM(down_position.x, down_position.y));
  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERUP, secondary_up, MAKELPARAM(up_position.x, up_position.y));
  ::Sleep(30);
  Check(
      g_forwarded_mouse_down_messages.load(std::memory_order_relaxed) == 1 &&
          g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) == 1,
      "secondary touch must not synthesize another click");

  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERDOWN, MAKEWPARAM(kCancelledPointerId, kPointerDownFlags),
      MAKELPARAM(down_position.x, down_position.y));
  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERCAPTURECHANGED, MAKEWPARAM(kCancelledPointerId, kPointerUpFlags),
      reinterpret_cast<LPARAM>(windows.host));
  for (int attempt = 0; attempt < 100 && g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) < 2; ++attempt) {
    ::Sleep(10);
  }
  Check(
      g_forwarded_mouse_down_messages.load(std::memory_order_relaxed) == 2 &&
          g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) == 2,
      "capture loss must release an active synthetic mouse press");

  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERDOWN, MAKEWPARAM(kDetachedPointerId, kPointerDownFlags),
      MAKELPARAM(down_position.x, down_position.y));
  for (int attempt = 0; attempt < 100 && g_forwarded_mouse_down_messages.load(std::memory_order_relaxed) < 3;
       ++attempt) {
    ::Sleep(10);
  }

  MpvPlayerPropertyContractTestPeer::DetachInnerSubclass(player);
  Check(
      reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC)) == windows.inner_original,
      "detach must restore the original procedure before window destruction");
  for (int attempt = 0; attempt < 100 && g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) < 3; ++attempt) {
    ::Sleep(10);
  }
  Check(
      g_forwarded_mouse_down_messages.load(std::memory_order_relaxed) == 3 &&
          g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) == 3,
      "detach must release an active synthetic mouse press");

  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERUP, MAKEWPARAM(kDetachedPointerId, kPointerUpFlags),
      MAKELPARAM(up_position.x, up_position.y));
  ::Sleep(30);
  Check(
      g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) == 3,
      "a late pointer up after detach must not release twice");

  ::SendMessageW(windows.inner, WM_MOUSEMOVE, 0, MAKELPARAM(8, 9));
  ::Sleep(30);
  Check(
      g_forwarded_mouse_messages.load(std::memory_order_relaxed) == 1,
      "a callback after detaching the old generation must be ignored");

  MpvPlayerPropertyContractTestPeer::EnsureInnerSubclass(player);
  const auto replacement = reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC));
  Check(replacement && replacement != windows.inner_original, "a replacement generation must install cleanly");
  ::SendMessageW(windows.inner, WM_MOUSEMOVE, 0, MAKELPARAM(10, 11));
  for (int attempt = 0; attempt < 100 && g_forwarded_mouse_messages.load(std::memory_order_relaxed) < 2; ++attempt) {
    ::Sleep(10);
  }
  Check(
      g_forwarded_mouse_messages.load(std::memory_order_relaxed) == 2,
      "replacement generation must own forwarding after installation");

  MpvPlayerPropertyContractTestPeer::ReleaseTestWindows(player);
  Check(
      reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC)) == windows.inner_original,
      "replacement detach must restore the original procedure");

  MpvPlayerPropertyContractTestPeer::ConfigureInnerSubclass(player, windows.host, windows.target);
  MpvPlayerPropertyContractTestPeer::EnsureInnerSubclass(player);
  const auto destroy_generation = reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC));
  Check(
      destroy_generation && destroy_generation != windows.inner_original,
      "destroy test must install a fresh subclass generation");

  SendFromOwnerThread(
      windows.target, windows.inner, WM_POINTERDOWN, MAKEWPARAM(kDestroyedPointerId, kPointerDownFlags),
      MAKELPARAM(down_position.x, down_position.y));
  ::SendMessageW(windows.inner, WM_CLOSE, 0, 0);
  for (int attempt = 0; attempt < 100 && g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) < 4; ++attempt) {
    ::Sleep(10);
  }
  Check(!::IsWindow(windows.inner), "destroy test must close the inner window");
  Check(
      g_forwarded_mouse_down_messages.load(std::memory_order_relaxed) == 4 &&
          g_forwarded_mouse_up_messages.load(std::memory_order_relaxed) == 4,
      "window destruction must release an active synthetic mouse press");
  MpvPlayerPropertyContractTestPeer::ReleaseTestWindows(player);

  ::PostThreadMessageW(windows.owner_thread, WM_QUIT, 0, 0);
  window_owner.join();
  g_forwarded_mouse_messages.store(0, std::memory_order_relaxed);
  g_forwarded_touch_moves.store(0, std::memory_order_relaxed);
  g_forwarded_mouse_down_messages.store(0, std::memory_order_relaxed);
  g_forwarded_mouse_up_messages.store(0, std::memory_order_relaxed);
  g_forwarded_pointer_messages.store(0, std::memory_order_relaxed);
}

void TestTimedOutSubclassDetachCanBeAdopted() {
  struct TestWindows {
    HWND target;
    HWND host;
    HWND inner;
    WNDPROC inner_original;
    DWORD owner_thread;
  };

  std::promise<TestWindows> windows_created;
  auto windows_future = windows_created.get_future();
  std::thread window_owner([&]() {
    HWND target =
        ::CreateWindowExW(0, L"STATIC", L"", WS_OVERLAPPED, 0, 0, 100, 100, nullptr, nullptr, nullptr, nullptr);
    HWND host = ::CreateWindowExW(0, L"STATIC", L"", WS_CHILD, 0, 0, 100, 100, target, nullptr, nullptr, nullptr);
    HWND inner = ::CreateWindowExW(0, L"STATIC", L"", WS_CHILD, 0, 0, 100, 100, host, nullptr, nullptr, nullptr);
    const auto target_original = reinterpret_cast<WNDPROC>(
        ::SetWindowLongPtrW(target, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(CountingWindowProc)));
    const auto inner_original = reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(inner, GWLP_WNDPROC));
    windows_created.set_value(TestWindows{target, host, inner, inner_original, ::GetCurrentThreadId()});

    MSG message;
    while (::GetMessageW(&message, nullptr, 0, 0) > 0) {
      ::TranslateMessage(&message);
      ::DispatchMessageW(&message);
    }

    ::SetWindowLongPtrW(target, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(target_original));
    ::DestroyWindow(inner);
    ::DestroyWindow(host);
    ::DestroyWindow(target);
  });

  const TestWindows windows = windows_future.get();
  Check(windows.target && windows.host && windows.inner, "detach-timeout test windows must be created");
  const HANDLE block_entered = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
  const HANDLE block_release = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
  const HANDLE block_exited = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
  Check(block_entered && block_release && block_exited, "detach-timeout synchronization events must be created");
  g_block_entered.store(block_entered, std::memory_order_release);
  g_block_release.store(block_release, std::memory_order_release);
  g_block_exited.store(block_exited, std::memory_order_release);
  g_forwarded_mouse_messages.store(0, std::memory_order_relaxed);

  {
    MpvPlayer original;
    MpvPlayerPropertyContractTestPeer::ConfigureInnerSubclass(original, windows.host, windows.target);
    MpvPlayerPropertyContractTestPeer::EnsureInnerSubclass(original);
    Check(
        reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC)) != windows.inner_original,
        "the initial generation must be installed before forcing detach timeout");
    const void* retained_generation = MpvPlayerPropertyContractTestPeer::InnerSubclassIdentity(original);
    Check(retained_generation != nullptr, "the initial generation must have live state");

    Check(
        ::PostMessageW(windows.target, kBlockWindowThreadMessage, 0, 0) != FALSE,
        "the owner-thread blocking message must be posted");
    Check(
        ::WaitForSingleObject(block_entered, 1000) == WAIT_OBJECT_0,
        "the owner thread must enter the deterministic blocking message");

    MpvPlayerPropertyContractTestPeer::DetachInnerSubclass(original);

    MpvPlayer replacement;
    MpvPlayerPropertyContractTestPeer::ConfigureInnerSubclass(replacement, windows.host, windows.target);
    MpvPlayerPropertyContractTestPeer::EnsureInnerSubclass(replacement);
    Check(
        MpvPlayerPropertyContractTestPeer::InnerSubclassIdentity(replacement) == retained_generation,
        "replacement must atomically adopt the retained generation");
    Check(
        reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC)) != windows.inner_original,
        "replacement must adopt the retained installed generation without duplicate subclassing");

    ::SetEvent(block_release);
    Check(
        ::WaitForSingleObject(block_exited, 1000) == WAIT_OBJECT_0,
        "the owner thread must leave the deterministic blocking message");
    ::SendMessageW(windows.inner, WM_NULL, 0, 0);
    ::SendMessageW(windows.inner, WM_MOUSEMOVE, 0, MAKELPARAM(12, 13));
    for (int attempt = 0; attempt < 100 && g_forwarded_mouse_messages.load(std::memory_order_relaxed) < 1; ++attempt) {
      ::Sleep(10);
    }
    Check(
        g_forwarded_mouse_messages.load(std::memory_order_relaxed) == 1,
        "the adopted generation must resume input forwarding");

    MpvPlayerPropertyContractTestPeer::ReleaseTestWindows(replacement);
    Check(
        reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC)) == windows.inner_original,
        "adopted generation cleanup must eventually restore the original procedure");
  }

  g_block_entered.store(nullptr, std::memory_order_release);
  g_block_release.store(nullptr, std::memory_order_release);
  g_block_exited.store(nullptr, std::memory_order_release);
  ::CloseHandle(block_entered);
  ::CloseHandle(block_release);
  ::CloseHandle(block_exited);
  ::PostThreadMessageW(windows.owner_thread, WM_QUIT, 0, 0);
  window_owner.join();
  g_forwarded_mouse_messages.store(0, std::memory_order_relaxed);
}

void TestTimedOutSubclassInstallCannotOutliveItsState() {
  struct TestWindows {
    HWND target;
    HWND host;
    HWND inner;
    WNDPROC inner_original;
    DWORD owner_thread;
  };

  std::promise<TestWindows> windows_created;
  auto windows_future = windows_created.get_future();
  std::promise<void> begin_dispatch;
  auto begin_dispatch_future = begin_dispatch.get_future();
  std::thread window_owner([&]() {
    HWND target =
        ::CreateWindowExW(0, L"STATIC", L"", WS_OVERLAPPED, 0, 0, 100, 100, nullptr, nullptr, nullptr, nullptr);
    HWND host = ::CreateWindowExW(0, L"STATIC", L"", WS_CHILD, 0, 0, 100, 100, target, nullptr, nullptr, nullptr);
    HWND inner = ::CreateWindowExW(0, L"STATIC", L"", WS_CHILD, 0, 0, 100, 100, host, nullptr, nullptr, nullptr);
    const auto inner_original = reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(inner, GWLP_WNDPROC));
    windows_created.set_value(TestWindows{target, host, inner, inner_original, ::GetCurrentThreadId()});

    // Keep the owning thread alive but unavailable long enough for
    // SendMessageTimeoutW to cancel the cross-thread ownership action.
    begin_dispatch_future.wait();
    MSG message;
    while (::GetMessageW(&message, nullptr, 0, 0) > 0) {
      ::TranslateMessage(&message);
      ::DispatchMessageW(&message);
    }

    ::DestroyWindow(inner);
    ::DestroyWindow(host);
    ::DestroyWindow(target);
  });

  const TestWindows windows = windows_future.get();
  Check(windows.target && windows.host && windows.inner, "timeout test windows must be created");
  {
    MpvPlayer player;
    MpvPlayerPropertyContractTestPeer::ConfigureInnerSubclass(player, windows.host, windows.target);
    MpvPlayerPropertyContractTestPeer::EnsureInnerSubclass(player);
    MpvPlayerPropertyContractTestPeer::ReleaseTestWindows(player);
  }

  // The action and its subclass reference data have now left caller scope.
  // Dispatching the timed-out message must neither install late nor touch the
  // destroyed caller state.
  begin_dispatch.set_value();
  ::SendMessageW(windows.inner, WM_NULL, 0, 0);
  Check(
      reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC)) == windows.inner_original,
      "a timed-out action must remain cancelled after the window thread resumes");

  ::PostThreadMessageW(windows.owner_thread, WM_QUIT, 0, 0);
  window_owner.join();
}

// The video child must never own a contact: mpv's window lives on mpv's own
// thread, where the cross-thread hit-test opt-outs (WS_EX_TRANSPARENT, an
// HTTRANSPARENT WM_NCHITTEST reply) do not apply. Disabling the host is what
// keeps mouse, touch, and pen on the Flutter view. The window mpv creates
// inside the host afterwards needs no state of its own — targeting skips the
// host without descending into it — so only the host's own state is asserted
// here (a disabled parent never clears its children's WS_DISABLED bit).
void TestDisabledVideoHostKeepsInputOnTheFlutterView() {
  HWND view = ::CreateWindowExW(0, L"STATIC", L"", WS_OVERLAPPED, 0, 0, 400, 400, nullptr, nullptr, nullptr, nullptr);
  Check(view != nullptr, "video host test needs a stand-in Flutter view window");
  RECT client = {};
  Check(::GetClientRect(view, &client) != FALSE, "the stand-in view must report a client area");
  Check(client.right > 2 && client.bottom > 2, "the stand-in view must have a usable client area");

  HWND host = ::CreateWindowExW(
      WS_EX_NOPARENTNOTIFY, L"STATIC", L"", kVideoHostWindowStyle, 0, 0, client.right, client.bottom, view, nullptr,
      nullptr, nullptr);
  Check(host != nullptr, "the video host window must be created");
  Check(!::IsWindowEnabled(host), "the video host must be created disabled");

  const POINT contact = {client.right / 2, client.bottom / 2};
  Check(
      ::ChildWindowFromPointEx(view, contact, CWP_SKIPDISABLED) == view,
      "input over the disabled video host must target the Flutter view");

  ::EnableWindow(host, TRUE);
  Check(
      ::ChildWindowFromPointEx(view, contact, CWP_SKIPDISABLED) == host,
      "the same contact must reach an enabled host, so the skip is the disabled state and not the geometry");

  ::DestroyWindow(host);
  ::DestroyWindow(view);
}

// The assertions above only prove that USER32's own child lookup honors
// CWP_SKIPDISABLED. What the video child actually depends on is the input hit
// test: a press over the disabled host has to reach the parent view, and must
// not be swallowed — swallowing is what the previous implementation reported
// when it tried disabling this subtree, and no relay can recover from it
// because mpv's window never sees the message either.
//
// A control press with the video subtree hidden runs first. If that one does
// not arrive, injection is unavailable here and the test skips. Once it has
// landed, silence from the press over the disabled host is a failure, not an
// environment problem.
void TestDisabledVideoHostRoutesRealPressesToParentView() {
  HWND view = ::CreateWindowExW(
      0, L"STATIC", L"", WS_OVERLAPPEDWINDOW | WS_VISIBLE, 100, 100, 400, 400, nullptr, nullptr, nullptr, nullptr);
  Check(view != nullptr, "input routing test needs a stand-in Flutter view window");
  RECT client = {};
  Check(::GetClientRect(view, &client) != FALSE, "the stand-in view must report a client area");
  Check(client.right > 2 && client.bottom > 2, "the stand-in view must have a usable client area");

  HWND host = ::CreateWindowExW(
      WS_EX_NOPARENTNOTIFY, L"STATIC", L"", kVideoHostWindowStyle | WS_VISIBLE, 0, 0, client.right, client.bottom, view,
      nullptr, nullptr, nullptr);
  Check(host != nullptr, "the video host window must be created");
  HWND inner = ::CreateWindowExW(
      0, L"STATIC", L"", WS_CHILD | WS_VISIBLE, 0, 0, client.right, client.bottom, host, nullptr, nullptr, nullptr);
  Check(inner != nullptr, "the mpv inner window stand-in must be created");

  g_routing_view.store(view, std::memory_order_release);
  g_routing_view_presses.store(0, std::memory_order_relaxed);
  g_routing_child_presses.store(0, std::memory_order_relaxed);
  const auto view_original =
      reinterpret_cast<WNDPROC>(::SetWindowLongPtrW(view, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(RoutingWindowProc)));
  const auto host_original =
      reinterpret_cast<WNDPROC>(::SetWindowLongPtrW(host, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(RoutingWindowProc)));
  const auto inner_original = reinterpret_cast<WNDPROC>(
      ::SetWindowLongPtrW(inner, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(RoutingWindowProc)));

  ::SetForegroundWindow(view);
  PumpUntil([]() { return false; }, 100);

  POINT contact = {client.right / 2, client.bottom / 2};
  ::ClientToScreen(view, &contact);
  POINT restore_cursor = {};
  const bool cursor_known = ::GetCursorPos(&restore_cursor) != FALSE;

  // Control: with the video subtree hidden, this press can only land on the
  // view. It establishes that injection reaches this process at all.
  ::ShowWindow(host, SW_HIDE);
  PumpUntil([]() { return false; }, 50);
  bool control_landed = false;
  if (::WindowFromPoint(contact) == view && InjectClick(contact)) {
    control_landed = PumpUntil([]() { return g_routing_view_presses.load(std::memory_order_relaxed) > 0; }, 2000);
  }

  if (!control_landed) {
    std::cout << "mpv_player_property_contract_test: skipped injected input routing (no usable desktop)\n";
  } else {
    g_routing_view_presses.store(0, std::memory_order_relaxed);
    g_routing_child_presses.store(0, std::memory_order_relaxed);
    ::ShowWindow(host, SW_SHOWNA);
    PumpUntil([]() { return false; }, 50);

    Check(
        ::WindowFromPoint(contact) == view,
        "the input hit test must skip the disabled video subtree and resolve to the Flutter view");
    Check(InjectClick(contact), "the control press injected, so the press over the video host must inject too");
    PumpUntil([]() { return g_routing_view_presses.load(std::memory_order_relaxed) > 0; }, 2000);

    Check(
        g_routing_child_presses.load(std::memory_order_relaxed) == 0,
        "a disabled video subtree must not receive the press itself");
    Check(
        g_routing_view_presses.load(std::memory_order_relaxed) == 1,
        "a press over the disabled video host must reach the parent Flutter view instead of being swallowed");

    // Touch is the contact kind issue #1556 was reported for, and it takes a
    // different path into the system than the mouse press above: the injection
    // below produces a real touch contact, so the system's own hit test picks
    // the target and promotes it to the legacy mouse stream the counters watch.
    // A machine without a digitizer can still inject, so this is not gated on
    // SM_DIGITIZER - only on the injection API being usable at all.
    if (!::InitializeTouchInjection(1, TOUCH_FEEDBACK_NONE)) {
      std::cout << "mpv_player_property_contract_test: skipped injected touch routing (injection unavailable)\n";
    } else {
      g_routing_view_presses.store(0, std::memory_order_relaxed);
      g_routing_child_presses.store(0, std::memory_order_relaxed);
      ::ShowWindow(host, SW_HIDE);
      PumpUntil([]() { return false; }, 50);

      // Same control as the mouse pass: with the video subtree hidden the tap
      // can only land on the view, which proves touch injection works here
      // before silence over the disabled host is treated as a failure.
      bool touch_control_landed = false;
      if (InjectTap(contact)) {
        touch_control_landed =
            PumpUntil([]() { return g_routing_view_presses.load(std::memory_order_relaxed) > 0; }, 2000);
      }

      if (!touch_control_landed) {
        std::cout << "mpv_player_property_contract_test: skipped injected touch routing (no usable desktop)\n";
      } else {
        g_routing_view_presses.store(0, std::memory_order_relaxed);
        g_routing_child_presses.store(0, std::memory_order_relaxed);
        ::ShowWindow(host, SW_SHOWNA);
        PumpUntil([]() { return false; }, 50);

        Check(InjectTap(contact), "the control tap injected, so the tap over the video host must inject too");
        PumpUntil([]() { return g_routing_view_presses.load(std::memory_order_relaxed) > 0; }, 2000);

        Check(
            g_routing_child_presses.load(std::memory_order_relaxed) == 0,
            "a disabled video subtree must not receive the touch itself");
        Check(
            g_routing_view_presses.load(std::memory_order_relaxed) == 1,
            "a touch over the disabled video host must reach the parent Flutter view instead of being swallowed");
      }
    }
  }

  if (cursor_known) ::SetCursorPos(restore_cursor.x, restore_cursor.y);
  ::SetWindowLongPtrW(inner, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(inner_original));
  ::SetWindowLongPtrW(host, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(host_original));
  ::SetWindowLongPtrW(view, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(view_original));
  g_routing_view.store(nullptr, std::memory_order_release);
  ::DestroyWindow(inner);
  ::DestroyWindow(host);
  ::DestroyWindow(view);
}

}  // namespace
}  // namespace mpv

int main() {
  mpv::TestSourceQualifiedEventPayloads();
  mpv::TestUnavailablePropertyWriteFails();
  mpv::TestPendingPropertyWriteFailsOnDispose();
  mpv::TestPendingRequestTypesRemainDistinctOnDispose();
  mpv::TestInnerSubclassOwnershipIsSerializedAndDetached();
  mpv::TestTimedOutSubclassDetachCanBeAdopted();
  mpv::TestTimedOutSubclassInstallCannotOutliveItsState();
  mpv::TestDisabledVideoHostKeepsInputOnTheFlutterView();
  mpv::TestDisabledVideoHostRoutesRealPressesToParentView();
  std::cout << "mpv_player_property_contract_test: PASS\n";
  return 0;
}
