#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>
#include <cctype>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "mpv/display_mode_manager.h"
#include "utils.h"

namespace {

bool IsOpenMediaLink(const std::string& value) {
  const auto starts_with = [&value](const std::string& prefix) {
    return value.size() >= prefix.size() &&
           std::equal(prefix.begin(), prefix.end(), value.begin(), [](char expected, char actual) {
             return expected == static_cast<char>(std::tolower(static_cast<unsigned char>(actual)));
           });
  };
  return starts_with("plezy://open-media?") || starts_with("plezyng://open-media?") ||
         starts_with("plezxyng://open-media?");
}

}  // namespace

int APIENTRY
wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev, _In_ wchar_t* command_line, _In_ int show_command) {
  // PlezyNG requires the bundled flutter-plezy engine, which presents the Flutter
  // UI on a topmost DirectComposition visual when FLUTTER_WINDOWS_DCOMP is set.
  // The mpv video window is then a plain child composed beneath the UI in the
  // same HWND: window capture (Discord/OBS) works, there is no transparency
  // hack, and min/max animations are native. Must be set before the engine is
  // created. (On a stock engine the flag is a no-op and compositing breaks.)
  ::SetEnvironmentVariableW(L"FLUTTER_WINDOWS_DCOMP", L"1");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  const auto link = std::find_if(command_line_arguments.begin(), command_line_arguments.end(), IsOpenMediaLink);

  const bool preparation_worker =
      std::find(command_line_arguments.begin(), command_line_arguments.end(), "--plezy-preparation-worker") !=
      command_line_arguments.end();
  HANDLE mutex = CreateMutex(
      nullptr, TRUE, preparation_worker ? L"com.edde746.Plezy.PreparationWorker" : L"com.edde746.Plezy.SingleInstance");
  if (GetLastError() == ERROR_ALREADY_EXISTS && preparation_worker) {
    CloseHandle(mutex);
    return EXIT_SUCCESS;
  }
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"PlezyNG");
    if (existing == nullptr) {
      existing = FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Plezy");
    }
    if (existing && IsWindowVisible(existing)) {
      if (link != command_line_arguments.end()) {
        const int character_count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, link->c_str(), -1, nullptr, 0);
        if (character_count > 1 && character_count <= 8192) {
          std::wstring wide_link(static_cast<size_t>(character_count), L'\0');
          if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, link->c_str(), -1, wide_link.data(), character_count) >
              0) {
            COPYDATASTRUCT data{};
            data.dwData = 0x504C5A59;
            data.cbData = static_cast<DWORD>(wide_link.size() * sizeof(wchar_t));
            data.lpData = wide_link.data();
            DWORD_PTR delivered = 0;
            SendMessageTimeoutW(
                existing, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&data), SMTO_ABORTIFHUNG | SMTO_BLOCK, 5000,
                &delivered);
          }
        }
      }
      ShowWindow(existing, SW_RESTORE);
      SetForegroundWindow(existing);
      CloseHandle(mutex);
      return EXIT_SUCCESS;
    }
    // A hidden (or already destroyed) window is either still starting - it
    // shows itself on its first frame - or exiting: the exit path hides the
    // window before a teardown of up to 15 s. Restoring it would bring back a
    // window that is about to vanish. Wait for the other instance instead:
    // if it is exiting, it releases the mutex and this launch takes over.
    constexpr DWORD kExitingInstanceWaitMs = 20000;
    const DWORD wait = WaitForSingleObject(mutex, kExitingInstanceWaitMs);
    if (wait != WAIT_OBJECT_0 && wait != WAIT_ABANDONED) {
      CloseHandle(mutex);
      return EXIT_SUCCESS;
    }
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM for Win32 libraries and plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);

  // Keep rendering with Skia. Flutter 3.47 made Impeller the default Windows
  // renderer, but the DirectComposition presentation above is only correct
  // when the frame's per-pixel alpha is exact: DWM blends the UI visual over
  // the mpv video child, so a frame that presents opaque where it should be
  // translucent hides the video outright. Impeller's GLES backend gets that
  // alpha wrong on some drivers - the video area went black for as long as
  // the player OSD was on screen (#2127). Every release up to 2.17.0 rendered
  // with Skia; keep it until Impeller composites the alpha correctly.
  project.set_impeller_switch(flutter::ImpellerSwitch::Disabled);

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"PlezyNG", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Recover display mode if a prior crash left it changed.
  if (!preparation_worker) mpv::DisplayModeManager::RecoverIfNeeded();

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }
  // Required app exit posts WM_QUIT without destroying the window. Tear down
  // the controller and plugins while COM is still initialized.
  window.Destroy();

  ::CoUninitialize();
  CloseHandle(mutex);
  return EXIT_SUCCESS;
}
