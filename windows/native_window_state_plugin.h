#ifndef NATIVE_WINDOW_STATE_PLUGIN_H_
#define NATIVE_WINDOW_STATE_PLUGIN_H_
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <string>

class NativeWindowStatePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
  NativeWindowStatePlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~NativeWindowStatePlugin();
  
  // Static method to save window state from window handle
  static bool SaveWindowStateStatic(HWND hwnd, bool isMaximized);
  
  // Static method to load window state from window handle
  // Returns true if loaded successfully, and sets isMaximized output parameter
  static bool LoadWindowStateStatic(HWND hwnd, bool* outIsMaximized = nullptr);
  
  // Disallow copy and assign.
  NativeWindowStatePlugin(const NativeWindowStatePlugin&) = delete;
  NativeWindowStatePlugin& operator=(const NativeWindowStatePlugin&) = delete;
  
 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  bool SaveWindowState(bool isMaximized);
  bool LoadWindowState();
  bool ClearWindowState();
  flutter::EncodableMap GetWindowState();
  
  HWND GetMainWindowHandle();
  
  static bool SaveToRegistry(const std::wstring& valueName, DWORD value);
  static DWORD LoadFromRegistry(const std::wstring& valueName, DWORD defaultValue);
  bool DeleteRegistryValue(const std::wstring& valueName);
  
  flutter::PluginRegistrarWindows* registrar_;
  static constexpr wchar_t kRegistryKey[] = L"Software\\Plezy";
};

#endif  // NATIVE_WINDOW_STATE_PLUGIN_H_
