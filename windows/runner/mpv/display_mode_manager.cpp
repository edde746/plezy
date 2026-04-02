#include "display_mode_manager.h"

#include "sdk_26100.h"

#include <cmath>
#include <algorithm>

namespace mpv {

static const wchar_t* kRegistryPath = L"Software\\Plezy\\DisplayModeOverride";
static const wchar_t* kRegDeviceName = L"DeviceName";
static const wchar_t* kRegOriginalRefreshRate = L"OriginalRefreshRate";
static const wchar_t* kRegOriginalWidth = L"OriginalWidth";
static const wchar_t* kRegOriginalHeight = L"OriginalHeight";
static const wchar_t* kRegOriginalHDR = L"OriginalHDREnabled";
static const wchar_t* kRegModeChanged = L"ModeChanged";
static const wchar_t* kRegHDRChanged = L"HDRChanged";

DisplayModeManager::DisplayModeManager() {}

DisplayModeManager::~DisplayModeManager() {}

// --- Monitor identification ---

std::wstring DisplayModeManager::GetMonitorDeviceName(HWND window) {
  HMONITOR monitor = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST);
  if (!monitor) return {};

  MONITORINFOEXW mi = {};
  mi.cbSize = sizeof(mi);
  if (!GetMonitorInfoW(monitor, &mi)) return {};

  return mi.szDevice;
}

std::vector<DISPLAYCONFIG_PATH_INFO> DisplayModeManager::GetDisplayConfigPaths() {
  UINT32 path_count = 0;
  UINT32 mode_count = 0;
  std::vector<DISPLAYCONFIG_PATH_INFO> paths;
  std::vector<DISPLAYCONFIG_MODE_INFO> modes;

  constexpr UINT32 flags = QDC_ONLY_ACTIVE_PATHS;
  LONG result;

  // Retry loop for ERROR_INSUFFICIENT_BUFFER (Kodi pattern).
  do {
    if (GetDisplayConfigBufferSizes(flags, &path_count, &mode_count) != ERROR_SUCCESS)
      return {};

    paths.resize(path_count);
    modes.resize(mode_count);

    result = QueryDisplayConfig(flags, &path_count, paths.data(),
                                &mode_count, modes.data(), nullptr);
  } while (result == ERROR_INSUFFICIENT_BUFFER);

  if (result != ERROR_SUCCESS) return {};

  paths.resize(path_count);
  return paths;
}

std::optional<DisplayConfigId> DisplayModeManager::GetDisplayTargetId(
    const std::wstring& gdi_device_name) {
  // Follows Kodi's GetDisplayTargetId: iterate QueryDisplayConfig paths,
  // match via DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME.viewGdiDeviceName.
  DISPLAYCONFIG_SOURCE_DEVICE_NAME source = {};
  source.header.type = DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME;
  source.header.size = sizeof(source);

  for (const auto& path : GetDisplayConfigPaths()) {
    source.header.adapterId = path.sourceInfo.adapterId;
    source.header.id = path.sourceInfo.id;

    if (DisplayConfigGetDeviceInfo(&source.header) == ERROR_SUCCESS &&
        gdi_device_name == source.viewGdiDeviceName) {
      return DisplayConfigId{path.targetInfo.adapterId, path.targetInfo.id};
    }
  }
  return std::nullopt;
}

bool DisplayModeManager::IsWin11_24H2OrNewer() {
  // Win11 24H2 = build 26100+
  OSVERSIONINFOEXW osvi = {};
  osvi.dwOSVersionInfoSize = sizeof(osvi);
  osvi.dwBuildNumber = 26100;

  DWORDLONG condition_mask = 0;
  VER_SET_CONDITION(condition_mask, VER_BUILDNUMBER, VER_GREATER_EQUAL);

  return VerifyVersionInfoW(&osvi, VER_BUILDNUMBER, condition_mask) != FALSE;
}

// --- Refresh rate / resolution ---

std::vector<DisplayMode> DisplayModeManager::EnumerateDisplayModes(HWND window) {
  std::wstring device_name = GetMonitorDeviceName(window);
  if (device_name.empty()) return {};

  std::vector<DisplayMode> modes;
  DEVMODEW dm = {};
  dm.dmSize = sizeof(dm);

  for (DWORD i = 0; EnumDisplaySettingsW(device_name.c_str(), i, &dm); i++) {
    DisplayMode mode;
    mode.width = dm.dmPelsWidth;
    mode.height = dm.dmPelsHeight;
    mode.refresh_rate = dm.dmDisplayFrequency;
    modes.push_back(mode);
  }

  // Remove duplicates.
  std::sort(modes.begin(), modes.end(), [](const DisplayMode& a, const DisplayMode& b) {
    if (a.width != b.width) return a.width < b.width;
    if (a.height != b.height) return a.height < b.height;
    return a.refresh_rate < b.refresh_rate;
  });
  modes.erase(std::unique(modes.begin(), modes.end(), [](const DisplayMode& a, const DisplayMode& b) {
    return a.width == b.width && a.height == b.height && a.refresh_rate == b.refresh_rate;
  }), modes.end());

  return modes;
}

DisplayMode DisplayModeManager::GetCurrentMode(HWND window) {
  std::wstring device_name = GetMonitorDeviceName(window);
  DisplayMode mode = {};

  if (device_name.empty()) return mode;

  DEVMODEW dm = {};
  dm.dmSize = sizeof(dm);
  if (EnumDisplaySettingsW(device_name.c_str(), ENUM_CURRENT_SETTINGS, &dm)) {
    mode.width = dm.dmPelsWidth;
    mode.height = dm.dmPelsHeight;
    mode.refresh_rate = dm.dmDisplayFrequency;
  }
  return mode;
}

void DisplayModeManager::SaveOriginalMode(HWND window) {
  original_device_name_ = GetMonitorDeviceName(window);
  if (original_device_name_.empty()) return;

  original_devmode_ = {};
  original_devmode_.dmSize = sizeof(original_devmode_);
  EnumDisplaySettingsW(original_device_name_.c_str(), ENUM_CURRENT_SETTINGS,
                       &original_devmode_);
}

bool DisplayModeManager::SetDisplayMode(HWND window, DWORD width, DWORD height,
                                         DWORD refresh_rate) {
  std::wstring device_name = GetMonitorDeviceName(window);
  if (device_name.empty()) return false;

  // Save original mode if not already saved.
  if (!mode_changed_) {
    SaveOriginalMode(window);
  }

  DEVMODEW dm = {};
  dm.dmSize = sizeof(dm);
  dm.dmPelsWidth = width;
  dm.dmPelsHeight = height;
  dm.dmDisplayFrequency = refresh_rate;
  dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY;

  bool changed = false;

  // Kodi's Win8+ workaround for exact integer refresh rates (24, 48, 60 Hz).
  // Write desired mode to registry, apply from registry, restore registry.
  // Source: xbmc/windowing/windows/WinSystemWin32.cpp:940-970.
  if (refresh_rate == 24 || refresh_rate == 48 || refresh_rate == 60) {
    DEVMODEW registry_dm = {};
    registry_dm.dmSize = sizeof(registry_dm);
    if (EnumDisplaySettingsW(device_name.c_str(), ENUM_REGISTRY_SETTINGS, &registry_dm)) {
      LONG rc = ChangeDisplaySettingsExW(device_name.c_str(), &dm, nullptr,
                                          CDS_UPDATEREGISTRY | CDS_NORESET, nullptr);
      if (rc == DISP_CHANGE_SUCCESSFUL) {
        rc = ChangeDisplaySettingsExW(device_name.c_str(), nullptr, nullptr,
                                       CDS_FULLSCREEN, nullptr);
        if (rc == DISP_CHANGE_SUCCESSFUL) changed = true;

        // Restore original registry settings.
        registry_dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
        ChangeDisplaySettingsExW(device_name.c_str(), &registry_dm, nullptr,
                                  CDS_UPDATEREGISTRY | CDS_NORESET, nullptr);
      }
    }
  }

  // Standard path / fallback.
  if (!changed) {
    LONG rc = ChangeDisplaySettingsExW(device_name.c_str(), &dm, nullptr,
                                        CDS_FULLSCREEN, nullptr);
    if (rc == DISP_CHANGE_SUCCESSFUL) changed = true;
  }

  if (changed) {
    mode_changed_ = true;
    WriteRecoveryState();
  }

  return changed;
}

bool DisplayModeManager::RestoreOriginalMode(HWND window) {
  if (!mode_changed_ || original_device_name_.empty()) return false;

  original_devmode_.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;

  LONG rc = ChangeDisplaySettingsExW(original_device_name_.c_str(),
                                      &original_devmode_, nullptr,
                                      CDS_FULLSCREEN, nullptr);

  if (rc == DISP_CHANGE_SUCCESSFUL) {
    mode_changed_ = false;
    if (!hdr_changed_) ClearRecoveryState();
    return true;
  }

  // Fallback: restore registry defaults.
  rc = ChangeDisplaySettingsExW(original_device_name_.c_str(), nullptr, nullptr, 0, nullptr);
  mode_changed_ = (rc != DISP_CHANGE_SUCCESSFUL);
  if (!mode_changed_ && !hdr_changed_) ClearRecoveryState();
  return rc == DISP_CHANGE_SUCCESSFUL;
}

// --- HDR ---

bool DisplayModeManager::IsHDRSupported(HWND window) {
  std::wstring device_name = GetMonitorDeviceName(window);
  if (device_name.empty()) return false;

  auto target_id = GetDisplayTargetId(device_name);
  if (!target_id) return false;

  // Follows Kodi's GetDisplayHDRStatus pattern.
  if (IsWin11_24H2OrNewer()) {
    DISPLAYCONFIG_GET_ADVANCED_COLOR_INFO_2 info = {};
    info.header.type = static_cast<DISPLAYCONFIG_DEVICE_INFO_TYPE>(
        DISPLAYCONFIG_DEVICE_INFO_GET_ADVANCED_COLOR_INFO_2);
    info.header.size = sizeof(info);
    info.header.adapterId = target_id->adapter_id;
    info.header.id = target_id->id;

    if (DisplayConfigGetDeviceInfo(&info.header) == ERROR_SUCCESS) {
      return info.highDynamicRangeSupported == TRUE;
    }
  } else {
    DISPLAYCONFIG_GET_ADVANCED_COLOR_INFO info = {};
    info.header.type = DISPLAYCONFIG_DEVICE_INFO_GET_ADVANCED_COLOR_INFO;
    info.header.size = sizeof(info);
    info.header.adapterId = target_id->adapter_id;
    info.header.id = target_id->id;

    if (DisplayConfigGetDeviceInfo(&info.header) == ERROR_SUCCESS) {
      // advancedColorSupported=1 && wideColorEnforced=0 => true HDR screen.
      // advancedColorSupported=1 && wideColorEnforced=1 => SDR screen with ACM (Win11 22H2+).
      // Source: Kodi DisplayUtilsWin32.cpp:157-172.
      return info.advancedColorSupported && !info.wideColorEnforced;
    }
  }

  return false;
}

bool DisplayModeManager::IsHDREnabled(HWND window) {
  std::wstring device_name = GetMonitorDeviceName(window);
  if (device_name.empty()) return false;

  auto target_id = GetDisplayTargetId(device_name);
  if (!target_id) return false;

  if (IsWin11_24H2OrNewer()) {
    DISPLAYCONFIG_GET_ADVANCED_COLOR_INFO_2 info = {};
    info.header.type = static_cast<DISPLAYCONFIG_DEVICE_INFO_TYPE>(
        DISPLAYCONFIG_DEVICE_INFO_GET_ADVANCED_COLOR_INFO_2);
    info.header.size = sizeof(info);
    info.header.adapterId = target_id->adapter_id;
    info.header.id = target_id->id;

    if (DisplayConfigGetDeviceInfo(&info.header) == ERROR_SUCCESS) {
      return info.activeColorMode == DISPLAYCONFIG_ADVANCED_COLOR_MODE_HDR;
    }
  } else {
    DISPLAYCONFIG_GET_ADVANCED_COLOR_INFO info = {};
    info.header.type = DISPLAYCONFIG_DEVICE_INFO_GET_ADVANCED_COLOR_INFO;
    info.header.size = sizeof(info);
    info.header.adapterId = target_id->adapter_id;
    info.header.id = target_id->id;

    if (DisplayConfigGetDeviceInfo(&info.header) == ERROR_SUCCESS) {
      bool hdr_supported = info.advancedColorSupported && !info.wideColorEnforced;
      return hdr_supported && info.advancedColorEnabled;
    }
  }

  return false;
}

void DisplayModeManager::SaveOriginalHDRState(HWND window) {
  original_hdr_device_name_ = GetMonitorDeviceName(window);
  original_hdr_enabled_ = IsHDREnabled(window);
}

bool DisplayModeManager::SetHDREnabled(HWND window, bool enabled) {
  std::wstring device_name = GetMonitorDeviceName(window);
  if (device_name.empty()) return false;

  auto target_id = GetDisplayTargetId(device_name);
  if (!target_id) return false;

  // Save original state if not already saved.
  if (!hdr_changed_) {
    SaveOriginalHDRState(window);
  }

  // Save DEVMODEW before toggle — Windows changes display mode on HDR state change.
  // Source: Kodi WIN32Util.cpp:1252-1257.
  DEVMODEW pre_toggle_dm = {};
  pre_toggle_dm.dmSize = sizeof(pre_toggle_dm);
  EnumDisplaySettingsW(device_name.c_str(), ENUM_CURRENT_SETTINGS, &pre_toggle_dm);

  // Toggle HDR.
  LONG result = SetHDRStateForTarget(*target_id, enabled);
  if (result != ERROR_SUCCESS) return false;

  // Restore DEVMODEW after toggle — Windows may have changed the display mode.
  // Source: Kodi WIN32Util.cpp:1276-1288.
  if (pre_toggle_dm.dmDisplayFrequency != 0) {
    pre_toggle_dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
    ChangeDisplaySettingsExW(device_name.c_str(), &pre_toggle_dm, nullptr,
                              CDS_FULLSCREEN, nullptr);
  }

  hdr_changed_ = true;
  WriteRecoveryState();
  return true;
}

bool DisplayModeManager::RestoreOriginalHDRState(HWND window) {
  if (!hdr_changed_ || original_hdr_device_name_.empty()) return false;

  bool current = IsHDREnabled(window);
  if (current == original_hdr_enabled_) {
    hdr_changed_ = false;
    if (!mode_changed_) ClearRecoveryState();
    return true;
  }

  // Need to actually toggle back.
  auto target_id = GetDisplayTargetId(original_hdr_device_name_);
  if (!target_id) return false;

  // Save DEVMODEW before restore toggle.
  DEVMODEW pre_toggle_dm = {};
  pre_toggle_dm.dmSize = sizeof(pre_toggle_dm);
  EnumDisplaySettingsW(original_hdr_device_name_.c_str(), ENUM_CURRENT_SETTINGS, &pre_toggle_dm);

  LONG result = SetHDRStateForTarget(*target_id, original_hdr_enabled_);
  if (result != ERROR_SUCCESS) return false;

  // Restore DEVMODEW after toggle.
  if (pre_toggle_dm.dmDisplayFrequency != 0) {
    pre_toggle_dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
    ChangeDisplaySettingsExW(original_hdr_device_name_.c_str(), &pre_toggle_dm,
                              nullptr, CDS_FULLSCREEN, nullptr);
  }

  hdr_changed_ = false;
  if (!mode_changed_) ClearRecoveryState();
  return true;
}

// --- Crash recovery (Windows Registry) ---

LONG DisplayModeManager::SetHDRStateForTarget(const DisplayConfigId& target, bool enabled) {
  if (IsWin11_24H2OrNewer()) {
    DISPLAYCONFIG_SET_HDR_STATE state = {};
    state.header.type = static_cast<DISPLAYCONFIG_DEVICE_INFO_TYPE>(
        DISPLAYCONFIG_DEVICE_INFO_SET_HDR_STATE);
    state.header.size = sizeof(state);
    state.header.adapterId = target.adapter_id;
    state.header.id = target.id;
    state.enableHdr = enabled ? TRUE : FALSE;
    return DisplayConfigSetDeviceInfo(&state.header);
  } else {
    DISPLAYCONFIG_SET_ADVANCED_COLOR_STATE state = {};
    state.header.type = DISPLAYCONFIG_DEVICE_INFO_SET_ADVANCED_COLOR_STATE;
    state.header.size = sizeof(state);
    state.header.adapterId = target.adapter_id;
    state.header.id = target.id;
    state.enableAdvancedColor = enabled ? TRUE : FALSE;
    return DisplayConfigSetDeviceInfo(&state.header);
  }
}

bool DisplayModeManager::WriteRegistryDWORD(const wchar_t* value_name, DWORD value) {
  HKEY key;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, nullptr,
                       0, KEY_WRITE, nullptr, &key, nullptr) != ERROR_SUCCESS)
    return false;
  LONG result = RegSetValueExW(key, value_name, 0, REG_DWORD,
                                reinterpret_cast<const BYTE*>(&value), sizeof(value));
  RegCloseKey(key);
  return result == ERROR_SUCCESS;
}

bool DisplayModeManager::WriteRegistryString(const wchar_t* value_name,
                                              const std::wstring& value) {
  HKEY key;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, nullptr,
                       0, KEY_WRITE, nullptr, &key, nullptr) != ERROR_SUCCESS)
    return false;
  LONG result = RegSetValueExW(key, value_name, 0, REG_SZ,
                                reinterpret_cast<const BYTE*>(value.c_str()),
                                static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(key);
  return result == ERROR_SUCCESS;
}

bool DisplayModeManager::ReadRegistryDWORD(const wchar_t* value_name, DWORD& value) {
  HKEY key;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_READ, &key) != ERROR_SUCCESS)
    return false;
  DWORD size = sizeof(value);
  DWORD type = 0;
  LONG result = RegQueryValueExW(key, value_name, nullptr, &type,
                                  reinterpret_cast<BYTE*>(&value), &size);
  RegCloseKey(key);
  return result == ERROR_SUCCESS && type == REG_DWORD;
}

bool DisplayModeManager::ReadRegistryString(const wchar_t* value_name, std::wstring& value) {
  HKEY key;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_READ, &key) != ERROR_SUCCESS)
    return false;
  DWORD size = 0;
  DWORD type = 0;
  RegQueryValueExW(key, value_name, nullptr, &type, nullptr, &size);
  if (type != REG_SZ || size == 0) {
    RegCloseKey(key);
    return false;
  }
  value.resize(size / sizeof(wchar_t));
  LONG result = RegQueryValueExW(key, value_name, nullptr, nullptr,
                                  reinterpret_cast<BYTE*>(&value[0]), &size);
  RegCloseKey(key);
  if (result != ERROR_SUCCESS) return false;
  // Remove trailing null.
  while (!value.empty() && value.back() == L'\0') value.pop_back();
  return true;
}

bool DisplayModeManager::DeleteRegistryValue(const wchar_t* value_name) {
  HKEY key;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_WRITE, &key) != ERROR_SUCCESS)
    return false;
  RegDeleteValueW(key, value_name);
  RegCloseKey(key);
  return true;
}

void DisplayModeManager::WriteRecoveryState() {
  std::wstring device = mode_changed_ ? original_device_name_ : original_hdr_device_name_;
  if (device.empty()) return;

  WriteRegistryString(kRegDeviceName, device);
  WriteRegistryDWORD(kRegModeChanged, mode_changed_ ? 1 : 0);
  WriteRegistryDWORD(kRegHDRChanged, hdr_changed_ ? 1 : 0);

  if (mode_changed_) {
    WriteRegistryDWORD(kRegOriginalRefreshRate, original_devmode_.dmDisplayFrequency);
    WriteRegistryDWORD(kRegOriginalWidth, original_devmode_.dmPelsWidth);
    WriteRegistryDWORD(kRegOriginalHeight, original_devmode_.dmPelsHeight);
  }

  if (hdr_changed_) {
    WriteRegistryDWORD(kRegOriginalHDR, original_hdr_enabled_ ? 1 : 0);
  }
}

void DisplayModeManager::ClearRecoveryState() {
  // Delete the entire key.
  RegDeleteKeyW(HKEY_CURRENT_USER, kRegistryPath);
}

bool DisplayModeManager::RecoverIfNeeded(HWND window) {
  DWORD mode_changed = 0, hdr_changed = 0;
  std::wstring device_name;

  if (!ReadRegistryString(kRegDeviceName, device_name)) return false;
  ReadRegistryDWORD(kRegModeChanged, mode_changed);
  ReadRegistryDWORD(kRegHDRChanged, hdr_changed);

  if (!mode_changed && !hdr_changed) {
    RegDeleteKeyW(HKEY_CURRENT_USER, kRegistryPath);
    return false;
  }

  bool recovered = false;

  // Restore refresh rate / resolution.
  if (mode_changed) {
    DWORD width = 0, height = 0, refresh = 0;
    ReadRegistryDWORD(kRegOriginalWidth, width);
    ReadRegistryDWORD(kRegOriginalHeight, height);
    ReadRegistryDWORD(kRegOriginalRefreshRate, refresh);

    if (width > 0 && height > 0 && refresh > 0) {
      DEVMODEW dm = {};
      dm.dmSize = sizeof(dm);
      dm.dmPelsWidth = width;
      dm.dmPelsHeight = height;
      dm.dmDisplayFrequency = refresh;
      dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY;

      LONG rc = ChangeDisplaySettingsExW(device_name.c_str(), &dm, nullptr,
                                          CDS_FULLSCREEN, nullptr);
      if (rc == DISP_CHANGE_SUCCESSFUL) recovered = true;
    }
  }

  // Restore HDR state.
  if (hdr_changed) {
    DWORD hdr_was_enabled = 0;
    ReadRegistryDWORD(kRegOriginalHDR, hdr_was_enabled);

    auto target_id = GetDisplayTargetId(device_name);
    if (target_id) {
      // Save DEVMODEW before toggle.
      DEVMODEW pre_dm = {};
      pre_dm.dmSize = sizeof(pre_dm);
      EnumDisplaySettingsW(device_name.c_str(), ENUM_CURRENT_SETTINGS, &pre_dm);

      LONG result = SetHDRStateForTarget(*target_id, hdr_was_enabled != 0);

      if (result == ERROR_SUCCESS) {
        recovered = true;
        // Restore display mode after HDR toggle.
        if (pre_dm.dmDisplayFrequency != 0) {
          pre_dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
          ChangeDisplaySettingsExW(device_name.c_str(), &pre_dm, nullptr,
                                    CDS_FULLSCREEN, nullptr);
        }
      }
    }
  }

  // Clean up registry regardless of success.
  RegDeleteKeyW(HKEY_CURRENT_USER, kRegistryPath);
  return recovered;
}

// --- Refresh rate matching ---

DWORD DisplayModeManager::FindBestRefreshRate(double video_fps,
                                               const std::vector<DisplayMode>& modes,
                                               DWORD current_width,
                                               DWORD current_height) {
  if (video_fps <= 0) return 0;

  // Collect unique refresh rates available at the current resolution.
  std::vector<DWORD> rates;
  for (const auto& mode : modes) {
    if (mode.width == current_width && mode.height == current_height) {
      if (std::find(rates.begin(), rates.end(), mode.refresh_rate) == rates.end()) {
        rates.push_back(mode.refresh_rate);
      }
    }
  }

  if (rates.empty()) return 0;

  DWORD best_rate = 0;
  int best_multiplier = 0;

  for (DWORD rate : rates) {
    double ratio = static_cast<double>(rate) / video_fps;
    double rounded = std::round(ratio);

    // Must be a positive integer multiple (1x, 2x, 3x, ...).
    if (rounded < 1.0) continue;

    int multiplier = static_cast<int>(rounded);
    double deviation = std::abs(ratio - rounded) / rounded;

    // Within 0.5% tolerance (covers 23.976 -> 24Hz, 29.97 -> 30Hz, etc.).
    if (deviation > 0.005) continue;

    // Prefer lowest multiplier (exact match > 2x > 3x > ...).
    // Among equal multipliers, prefer higher rate (shouldn't happen, but safe).
    if (best_rate == 0 || multiplier < best_multiplier ||
        (multiplier == best_multiplier && rate > best_rate)) {
      best_rate = rate;
      best_multiplier = multiplier;
    }
  }

  return best_rate;
}

}  // namespace mpv
