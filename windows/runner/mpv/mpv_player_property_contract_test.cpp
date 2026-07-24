#include <atomic>
#include <cstdlib>
#include <future>
#include <iostream>
#include <thread>
#include <utility>

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

std::atomic<int> g_forwarded_mouse_messages{0};
std::atomic<int> g_forwarded_pointer_messages{0};
constexpr UINT kBlockWindowThreadMessage = WM_APP + 0x0505;
std::atomic<HANDLE> g_block_entered{nullptr};
std::atomic<HANDLE> g_block_release{nullptr};
std::atomic<HANDLE> g_block_exited{nullptr};

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
  if (message == WM_POINTERUPDATE) {
    g_forwarded_pointer_messages.fetch_add(1, std::memory_order_relaxed);
    return 0;
  }
  if (message == WM_MOUSEMOVE) {
    g_forwarded_mouse_messages.fetch_add(1, std::memory_order_relaxed);
    return 0;
  }
  return ::DefWindowProcW(hwnd, message, wparam, lparam);
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
  Check(status < 0, "dispose must fail a pending property write");

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

  MpvPlayerPropertyContractTestPeer::DetachInnerSubclass(player);
  Check(
      reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(windows.inner, GWLP_WNDPROC)) == windows.inner_original,
      "detach must restore the original procedure before window destruction");

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

  ::PostThreadMessageW(windows.owner_thread, WM_QUIT, 0, 0);
  window_owner.join();
  g_forwarded_mouse_messages.store(0, std::memory_order_relaxed);
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
  g_forwarded_pointer_messages.store(0, std::memory_order_relaxed);

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
    ::SendMessageW(
        windows.inner, WM_POINTERUPDATE, MAKEWPARAM(1, POINTER_FLAG_UPDATE | POINTER_FLAG_INRANGE), MAKELPARAM(12, 13));
    Check(
        g_forwarded_pointer_messages.load(std::memory_order_relaxed) == 1,
        "the adopted generation must resume pointer forwarding");

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
  g_forwarded_pointer_messages.store(0, std::memory_order_relaxed);
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

}  // namespace
}  // namespace mpv

int main() {
  mpv::TestUnavailablePropertyWriteFails();
  mpv::TestPendingPropertyWriteFailsOnDispose();
  mpv::TestPendingRequestTypesRemainDistinctOnDispose();
  mpv::TestInnerSubclassOwnershipIsSerializedAndDetached();
  mpv::TestTimedOutSubclassDetachCanBeAdopted();
  mpv::TestTimedOutSubclassInstallCannotOutliveItsState();
  std::cout << "mpv_player_property_contract_test: PASS\n";
  return 0;
}
