#include "native_window_state_plugin.h"

#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

constexpr wchar_t NativeWindowStatePlugin::kRegistryKey[];

// Static registration
void NativeWindowStatePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "native_window_state",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NativeWindowStatePlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

NativeWindowStatePlugin::NativeWindowStatePlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

NativeWindowStatePlugin::~NativeWindowStatePlugin() {}

void NativeWindowStatePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (method_call.method_name() == "saveWindowState") {
    // Extract isMaximized parameter from arguments
    bool isMaximized = false;
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto it = arguments->find(flutter::EncodableValue("isMaximized"));
      if (it != arguments->end()) {
        const auto* value = std::get_if<bool>(&it->second);
        if (value) {
          isMaximized = *value;
        }
      }
    }
    
    bool success = SaveWindowState(isMaximized);
    result->Success(flutter::EncodableValue(success));
  } 
  else if (method_call.method_name() == "loadWindowState") {
    bool success = LoadWindowState();
    result->Success(flutter::EncodableValue(success));
  } 
  else if (method_call.method_name() == "clearWindowState") {
    bool success = ClearWindowState();
    result->Success(flutter::EncodableValue(success));
  } 
  else if (method_call.method_name() == "getWindowState") {
    flutter::EncodableMap state = GetWindowState();
    result->Success(flutter::EncodableValue(state));
  } 
  else {
    result->NotImplemented();
  }
}

HWND NativeWindowStatePlugin::GetMainWindowHandle() {
  return registrar_->GetView()->GetNativeWindow();
}

bool NativeWindowStatePlugin::SaveToRegistry(const std::wstring& valueName, DWORD value) {
  HKEY hKey;
  LONG result = RegCreateKeyExW(HKEY_CURRENT_USER, kRegistryKey, 0, nullptr,
                                 REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr,
                                 &hKey, nullptr);
  
  if (result != ERROR_SUCCESS) {
    return false;
  }

  result = RegSetValueExW(hKey, valueName.c_str(), 0, REG_DWORD,
                          reinterpret_cast<const BYTE*>(&value), sizeof(DWORD));
  
  RegCloseKey(hKey);
  return result == ERROR_SUCCESS;
}

DWORD NativeWindowStatePlugin::LoadFromRegistry(const std::wstring& valueName, 
                                                  DWORD defaultValue) {
  HKEY hKey;
  LONG result = RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryKey, 0, KEY_READ, &hKey);
  
  if (result != ERROR_SUCCESS) {
    return defaultValue;
  }

  DWORD value = defaultValue;
  DWORD dataSize = sizeof(DWORD);
  result = RegQueryValueExW(hKey, valueName.c_str(), nullptr, nullptr,
                            reinterpret_cast<BYTE*>(&value), &dataSize);
  
  RegCloseKey(hKey);
  return (result == ERROR_SUCCESS) ? value : defaultValue;
}

bool NativeWindowStatePlugin::DeleteRegistryValue(const std::wstring& valueName) {
  HKEY hKey;
  LONG result = RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryKey, 0, KEY_WRITE, &hKey);
  
  if (result != ERROR_SUCCESS) {
    return false;
  }

  result = RegDeleteValueW(hKey, valueName.c_str());
  RegCloseKey(hKey);
  return result == ERROR_SUCCESS;
}

bool NativeWindowStatePlugin::SaveWindowState(bool isMaximized) {
  HWND hwnd = GetMainWindowHandle();
  if (!hwnd) {
    return false;
  }

  return SaveWindowStateStatic(hwnd, isMaximized);
}

bool NativeWindowStatePlugin::SaveWindowStateStatic(HWND hwnd, bool isMaximized) {
  if (!hwnd) {
    return false;
  }

  // Get actual window rectangle (current position)
  RECT windowRect;
  if (!GetWindowRect(hwnd, &windowRect)) {
    return false;
  }

  LONG x = windowRect.left;
  LONG y = windowRect.top;
  LONG width = windowRect.right - windowRect.left;
  LONG height = windowRect.bottom - windowRect.top;
  
  // If maximized, load the previously saved normal position
  // (don't overwrite it with maximized coordinates)
  if (isMaximized) {
    DWORD saved_x = NativeWindowStatePlugin::LoadFromRegistry(L"WindowX", MAXDWORD);
    DWORD saved_y = NativeWindowStatePlugin::LoadFromRegistry(L"WindowY", MAXDWORD);
    DWORD saved_width = NativeWindowStatePlugin::LoadFromRegistry(L"WindowWidth", MAXDWORD);
    DWORD saved_height = NativeWindowStatePlugin::LoadFromRegistry(L"WindowHeight", MAXDWORD);
    
    // If we have previously saved normal position, keep using it
    if (saved_x != MAXDWORD && saved_y != MAXDWORD && 
        saved_width != MAXDWORD && saved_height != MAXDWORD) {
      x = static_cast<LONG>(saved_x);
      y = static_cast<LONG>(saved_y);
      width = static_cast<LONG>(saved_width);
      height = static_cast<LONG>(saved_height);
    }
    // Otherwise use current position (first time maximizing)
  }

  NativeWindowStatePlugin::SaveToRegistry(L"WindowX", x);
  NativeWindowStatePlugin::SaveToRegistry(L"WindowY", y);
  NativeWindowStatePlugin::SaveToRegistry(L"WindowWidth", width);
  NativeWindowStatePlugin::SaveToRegistry(L"WindowHeight", height);
  
  // Save maximized state
  DWORD isMaximizedDword = isMaximized ? 1 : 0;
  NativeWindowStatePlugin::SaveToRegistry(L"WindowMaximized", isMaximizedDword);

  return true;
}

bool NativeWindowStatePlugin::LoadWindowState() {
  HWND hwnd = GetMainWindowHandle();
  if (!hwnd) {
    return false;
  }
  
  return LoadWindowStateStatic(hwnd, nullptr);
}

bool NativeWindowStatePlugin::LoadWindowStateStatic(HWND hwnd, bool* outIsMaximized) {
  if (!hwnd) {
    return false;
  }

  // Load saved values (using max DWORD as sentinel for "not found")
  DWORD x_dword = NativeWindowStatePlugin::LoadFromRegistry(L"WindowX", MAXDWORD);
  DWORD y_dword = NativeWindowStatePlugin::LoadFromRegistry(L"WindowY", MAXDWORD);
  DWORD width_dword = NativeWindowStatePlugin::LoadFromRegistry(L"WindowWidth", MAXDWORD);
  DWORD height_dword = NativeWindowStatePlugin::LoadFromRegistry(L"WindowHeight", MAXDWORD);
  DWORD isMaximized = NativeWindowStatePlugin::LoadFromRegistry(L"WindowMaximized", 0);

  // Check if we have valid saved state
  if (x_dword == MAXDWORD || y_dword == MAXDWORD || 
      width_dword == MAXDWORD || height_dword == MAXDWORD) {
    return false;
  }

  LONG x = static_cast<LONG>(x_dword);
  LONG y = static_cast<LONG>(y_dword);
  LONG width = static_cast<LONG>(width_dword);
  LONG height = static_cast<LONG>(height_dword);

  // Validate window position is on screen (check virtual screen for multi-monitor)
  // Get the virtual screen bounds (all monitors combined)
  int virtualLeft = GetSystemMetrics(SM_XVIRTUALSCREEN);
  int virtualTop = GetSystemMetrics(SM_YVIRTUALSCREEN);
  int virtualWidth = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  int virtualHeight = GetSystemMetrics(SM_CYVIRTUALSCREEN);
  int virtualRight = virtualLeft + virtualWidth;
  int virtualBottom = virtualTop + virtualHeight;
  
  // Ensure at least 100 pixels of the title bar is visible on any monitor
  bool isVisible = (x + 100 > virtualLeft && x < virtualRight &&
                    y + 30 > virtualTop && y < virtualBottom);
  
  if (!isVisible) {
    // Center the window on the primary monitor
    RECT workArea;
    SystemParametersInfoW(SPI_GETWORKAREA, 0, &workArea, 0);
    x = (workArea.right - workArea.left - width) / 2;
    y = (workArea.bottom - workArea.top - height) / 2;
  }

  // Set window position and size
  WINDOWPLACEMENT placement = { sizeof(WINDOWPLACEMENT) };
  placement.flags = 0;
  placement.showCmd = isMaximized ? SW_MAXIMIZE : SW_HIDE;
  placement.rcNormalPosition.left = x;
  placement.rcNormalPosition.top = y;
  placement.rcNormalPosition.right = x + width;
  placement.rcNormalPosition.bottom = y + height;

  BOOL result = SetWindowPlacement(hwnd, &placement);

  // Return the maximized state if requested
  if (outIsMaximized) {
    *outIsMaximized = (isMaximized == 1);
  }
  
  return result != 0;
}

bool NativeWindowStatePlugin::ClearWindowState() {
  bool success = true;
  success &= DeleteRegistryValue(L"WindowX");
  success &= DeleteRegistryValue(L"WindowY");
  success &= DeleteRegistryValue(L"WindowWidth");
  success &= DeleteRegistryValue(L"WindowHeight");
  success &= DeleteRegistryValue(L"WindowMaximized");
  
  // Try to delete the key itself if empty
  RegDeleteKeyW(HKEY_CURRENT_USER, kRegistryKey);
  
  return success;
}

flutter::EncodableMap NativeWindowStatePlugin::GetWindowState() {
  flutter::EncodableMap state;
  
  HWND hwnd = GetMainWindowHandle();
  if (!hwnd) {
    return state;
  }

  WINDOWPLACEMENT placement = { sizeof(WINDOWPLACEMENT) };
  if (GetWindowPlacement(hwnd, &placement)) {
    RECT rect = placement.rcNormalPosition;
    state[flutter::EncodableValue("x")] = 
        flutter::EncodableValue(static_cast<int>(rect.left));
    state[flutter::EncodableValue("y")] = 
        flutter::EncodableValue(static_cast<int>(rect.top));
    state[flutter::EncodableValue("width")] = 
        flutter::EncodableValue(static_cast<int>(rect.right - rect.left));
    state[flutter::EncodableValue("height")] = 
        flutter::EncodableValue(static_cast<int>(rect.bottom - rect.top));
    state[flutter::EncodableValue("isMaximized")] = 
        flutter::EncodableValue(placement.showCmd == SW_SHOWMAXIMIZED);
  }

  return state;
}
