#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "mpv/display_mode_manager.h"
#include "utils.h"

int APIENTRY
wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev, _In_ wchar_t* command_line, _In_ int show_command) {
  // Plezy requires the bundled flutter-plezy engine, which presents the Flutter
  // UI on a topmost DirectComposition visual when FLUTTER_WINDOWS_DCOMP is set.
  // The mpv video window is then a plain child composed beneath the UI in the
  // same HWND: window capture (Discord/OBS) works, there is no transparency
  // hack, and min/max animations are native. Must be set before the engine is
  // created. (On a stock engine the flag is a no-op and compositing breaks.)
  ::SetEnvironmentVariableW(L"FLUTTER_WINDOWS_DCOMP", L"1");

  // Single instance enforcement
  HANDLE mutex = CreateMutex(nullptr, TRUE, L"com.edde746.Plezy.SingleInstance");
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Plezy");
    if (existing) {
      ShowWindow(existing, SW_RESTORE);
      SetForegroundWindow(existing);
    }
    CloseHandle(mutex);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Plezy", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Recover display mode if a prior crash left it changed.
  mpv::DisplayModeManager::RecoverIfNeeded(::GetAncestor(window.GetHandle(), GA_ROOT));

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  CloseHandle(mutex);
  return EXIT_SUCCESS;
}
