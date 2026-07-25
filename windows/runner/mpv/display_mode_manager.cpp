#include "display_mode_manager.h"

#include <algorithm>
#include <cmath>
#include <mutex>
#include <vector>

#include "sdk_26100.h"

namespace mpv {

namespace {

constexpr wchar_t kRegistryPath[] = L"Software\\Plezy\\DisplayModeOverride";
constexpr wchar_t kRegVersion[] = L"Version";
constexpr DWORD kRecoveryVersion = 1;
constexpr wchar_t kRegModeDeviceName[] = L"ModeDeviceName";
constexpr wchar_t kRegLegacyDeviceName[] = L"DeviceName";
constexpr wchar_t kRegHDRDeviceName[] = L"HDRDeviceName";
constexpr wchar_t kRegOriginalRefreshRate[] = L"OriginalRefreshRate";
constexpr wchar_t kRegOriginalWidth[] = L"OriginalWidth";
constexpr wchar_t kRegOriginalHeight[] = L"OriginalHeight";
constexpr wchar_t kRegOriginalHDR[] = L"OriginalHDREnabled";
constexpr wchar_t kRegModeChanged[] = L"ModeChanged";
constexpr wchar_t kRegHDRChanged[] = L"HDRChanged";
constexpr wchar_t kRegModeTakeoverEligible[] = L"ModeTakeoverEligible";
constexpr wchar_t kRegHDRTakeoverEligible[] = L"HDRTakeoverEligible";
constexpr wchar_t kRegModeRecoverySlot[] = L"ModeRecoverySlot";
constexpr wchar_t kRegHDRRecoverySlot[] = L"HDRRecoverySlot";
constexpr wchar_t kRegModeDeviceNameAlternate[] = L"ModeDeviceNameAlternate";
constexpr wchar_t kRegHDRDeviceNameAlternate[] = L"HDRDeviceNameAlternate";
constexpr wchar_t kRegOriginalRefreshRateAlternate[] = L"OriginalRefreshRateAlternate";
constexpr wchar_t kRegOriginalWidthAlternate[] = L"OriginalWidthAlternate";
constexpr wchar_t kRegOriginalHeightAlternate[] = L"OriginalHeightAlternate";
constexpr wchar_t kRegOriginalHDRAlternate[] = L"OriginalHDREnabledAlternate";
constexpr wchar_t kRegModeHandoffPending[] = L"ModeHandoffPending";
constexpr wchar_t kRegHDRHandoffPending[] = L"HDRHandoffPending";
constexpr wchar_t kRegModePreviousRecoverySlot[] = L"ModePreviousRecoverySlot";
constexpr wchar_t kRegHDRPreviousRecoverySlot[] = L"HDRPreviousRecoverySlot";

std::recursive_mutex g_display_override_mutex;
bool g_live_mode_recovery_record = false;
bool g_live_hdr_recovery_record = false;
bool g_recovery_in_progress = false;

class RecoveryRunGuard {
 public:
  RecoveryRunGuard() : acquired_(!g_recovery_in_progress) {
    if (acquired_) g_recovery_in_progress = true;
  }
  ~RecoveryRunGuard() {
    if (acquired_) g_recovery_in_progress = false;
  }

  bool acquired() const { return acquired_; }

 private:
  bool acquired_;
};

bool PrepareModeRecoveryAtRegistry(const std::wstring& device_name, DWORD width, DWORD height, DWORD refresh_rate);
bool PrepareHDRRecoveryAtRegistry(const std::wstring& device_name, bool enabled);
bool CompleteRecoveryOperationAtRegistry(
    const wchar_t* marker, const wchar_t* takeover_disposition, const wchar_t* handoff_pending);
bool FinalizeModeRecoveryAtRegistry(bool os_apply_succeeded);
bool FinalizeHDRRecoveryAtRegistry(bool os_apply_succeeded);
bool MarkTakeoverEligibleAtRegistry(const wchar_t* takeover_disposition);

}  // namespace

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
    if (GetDisplayConfigBufferSizes(flags, &path_count, &mode_count) != ERROR_SUCCESS) return {};

    paths.resize(path_count);
    modes.resize(mode_count);

    result = QueryDisplayConfig(flags, &path_count, paths.data(), &mode_count, modes.data(), nullptr);
  } while (result == ERROR_INSUFFICIENT_BUFFER);

  if (result != ERROR_SUCCESS) return {};

  paths.resize(path_count);
  return paths;
}

std::optional<DisplayConfigId> DisplayModeManager::GetDisplayTargetId(const std::wstring& gdi_device_name) {
  // Follows Kodi's GetDisplayTargetId: iterate QueryDisplayConfig paths,
  // match via DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME.viewGdiDeviceName.
  DISPLAYCONFIG_SOURCE_DEVICE_NAME source = {};
  source.header.type = DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME;
  source.header.size = sizeof(source);

  for (const auto& path : GetDisplayConfigPaths()) {
    source.header.adapterId = path.sourceInfo.adapterId;
    source.header.id = path.sourceInfo.id;

    if (DisplayConfigGetDeviceInfo(&source.header) == ERROR_SUCCESS && gdi_device_name == source.viewGdiDeviceName) {
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
  modes.erase(
      std::unique(
          modes.begin(), modes.end(),
          [](const DisplayMode& a, const DisplayMode& b) {
            return a.width == b.width && a.height == b.height && a.refresh_rate == b.refresh_rate;
          }),
      modes.end());

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
  EnumDisplaySettingsW(original_device_name_.c_str(), ENUM_CURRENT_SETTINGS, &original_devmode_);
}

bool DisplayModeManager::SetDisplayMode(HWND window, DWORD width, DWORD height, DWORD refresh_rate) {
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);

  const std::wstring device_name = GetMonitorDeviceName(window);
  if (device_name.empty()) return false;

  const bool mode_was_changed = mode_changed_;
  if (!mode_changed_) SaveOriginalMode(window);
  if (original_device_name_.empty() || original_devmode_.dmPelsWidth == 0 || original_devmode_.dmPelsHeight == 0 ||
      original_devmode_.dmDisplayFrequency == 0) {
    return false;
  }
  if (!PrepareModeRecoveryAtRegistry(
          original_device_name_, original_devmode_.dmPelsWidth, original_devmode_.dmPelsHeight,
          original_devmode_.dmDisplayFrequency)) {
    return false;
  }

  // Mark the record live before calling Windows. ChangeDisplaySettingsExW can
  // synchronously deliver WM_DISPLAYCHANGE; that event must not recover the
  // override that is currently being applied.
  g_live_mode_recovery_record = true;

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
      LONG rc = ChangeDisplaySettingsExW(device_name.c_str(), &dm, nullptr, CDS_UPDATEREGISTRY | CDS_NORESET, nullptr);
      if (rc == DISP_CHANGE_SUCCESSFUL) {
        rc = ChangeDisplaySettingsExW(device_name.c_str(), nullptr, nullptr, CDS_FULLSCREEN, nullptr);
        if (rc == DISP_CHANGE_SUCCESSFUL) changed = true;

        // Restore original registry settings.
        registry_dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
        ChangeDisplaySettingsExW(device_name.c_str(), &registry_dm, nullptr, CDS_UPDATEREGISTRY | CDS_NORESET, nullptr);
      }
    }
  }

  // Standard path / fallback.
  if (!changed) {
    const LONG rc = ChangeDisplaySettingsExW(device_name.c_str(), &dm, nullptr, CDS_FULLSCREEN, nullptr);
    changed = rc == DISP_CHANGE_SUCCESSFUL;
  }

  if (changed) {
    FinalizeModeRecoveryAtRegistry(true);
    mode_changed_ = true;
  } else if (!mode_was_changed) {
    // A failed takeover rolls back to its prior marked original. A fresh
    // failed operation still clears only its own marker.
    const bool recovery_completed = FinalizeModeRecoveryAtRegistry(false);
    g_live_mode_recovery_record = false;
    if (!recovery_completed) MarkTakeoverEligibleAtRegistry(kRegModeTakeoverEligible);
  }

  return changed;
}

bool DisplayModeManager::RestoreOriginalMode(HWND) {
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);
  if (!mode_changed_) return false;
  if (original_device_name_.empty()) {
    g_live_mode_recovery_record = false;
    MarkTakeoverEligibleAtRegistry(kRegModeTakeoverEligible);
    return false;
  }

  original_devmode_.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
  LONG rc =
      ChangeDisplaySettingsExW(original_device_name_.c_str(), &original_devmode_, nullptr, CDS_FULLSCREEN, nullptr);

  if (rc != DISP_CHANGE_SUCCESSFUL) {
    // Fallback: restore registry defaults.
    rc = ChangeDisplaySettingsExW(original_device_name_.c_str(), nullptr, nullptr, 0, nullptr);
  }
  if (rc != DISP_CHANGE_SUCCESSFUL) {
    // The explicit owner has given up. Keep the durable marker, but release it
    // so a later topology notification can restore a reconnected target or a
    // conflicting mode request can consume the failed recovery disposition.
    g_live_mode_recovery_record = false;
    MarkTakeoverEligibleAtRegistry(kRegModeTakeoverEligible);
    return false;
  }

  mode_changed_ = false;
  const bool recovery_completed =
      CompleteRecoveryOperationAtRegistry(kRegModeChanged, kRegModeTakeoverEligible, kRegModeHandoffPending);
  g_live_mode_recovery_record = false;
  if (!recovery_completed) MarkTakeoverEligibleAtRegistry(kRegModeTakeoverEligible);
  return true;
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
    info.header.type = static_cast<DISPLAYCONFIG_DEVICE_INFO_TYPE>(DISPLAYCONFIG_DEVICE_INFO_GET_ADVANCED_COLOR_INFO_2);
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
    info.header.type = static_cast<DISPLAYCONFIG_DEVICE_INFO_TYPE>(DISPLAYCONFIG_DEVICE_INFO_GET_ADVANCED_COLOR_INFO_2);
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
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);

  const std::wstring device_name = GetMonitorDeviceName(window);
  if (device_name.empty()) return false;

  const auto target_id = GetDisplayTargetId(device_name);
  if (!target_id) return false;

  const bool hdr_was_changed = hdr_changed_;
  if (!hdr_changed_) SaveOriginalHDRState(window);
  if (original_hdr_device_name_.empty() ||
      !PrepareHDRRecoveryAtRegistry(original_hdr_device_name_, original_hdr_enabled_)) {
    return false;
  }

  // See SetDisplayMode: keep synchronous topology notifications from treating
  // this process's just-persisted marker as crash recovery.
  g_live_hdr_recovery_record = true;

  // Save DEVMODEW before toggle — Windows changes display mode on HDR state change.
  // Source: Kodi WIN32Util.cpp:1252-1257.
  DEVMODEW pre_toggle_dm = {};
  pre_toggle_dm.dmSize = sizeof(pre_toggle_dm);
  EnumDisplaySettingsW(device_name.c_str(), ENUM_CURRENT_SETTINGS, &pre_toggle_dm);

  const LONG result = SetHDRStateForTarget(*target_id, enabled);
  if (result != ERROR_SUCCESS) {
    if (!hdr_was_changed) {
      const bool recovery_completed = FinalizeHDRRecoveryAtRegistry(false);
      g_live_hdr_recovery_record = false;
      if (!recovery_completed) MarkTakeoverEligibleAtRegistry(kRegHDRTakeoverEligible);
    }
    return false;
  }

  // Restore DEVMODEW after toggle — Windows may have changed the display mode.
  // Source: Kodi WIN32Util.cpp:1276-1288.
  if (pre_toggle_dm.dmDisplayFrequency != 0) {
    pre_toggle_dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
    ChangeDisplaySettingsExW(device_name.c_str(), &pre_toggle_dm, nullptr, CDS_FULLSCREEN, nullptr);
  }

  FinalizeHDRRecoveryAtRegistry(true);
  hdr_changed_ = true;
  return true;
}

bool DisplayModeManager::RestoreOriginalHDRState(HWND window) {
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);
  if (!hdr_changed_) return false;
  if (original_hdr_device_name_.empty()) {
    g_live_hdr_recovery_record = false;
    MarkTakeoverEligibleAtRegistry(kRegHDRTakeoverEligible);
    return false;
  }

  const auto target_id = GetDisplayTargetId(original_hdr_device_name_);
  if (!target_id) {
    g_live_hdr_recovery_record = false;
    MarkTakeoverEligibleAtRegistry(kRegHDRTakeoverEligible);
    return false;
  }

  if (IsHDREnabled(window) != original_hdr_enabled_) {
    // The original target was resolved above even when the currently observed
    // HDR state already matches, so a disconnected target cannot be mistaken
    // for a successful restore.

    // Save DEVMODEW before restore toggle.
    DEVMODEW pre_toggle_dm = {};
    pre_toggle_dm.dmSize = sizeof(pre_toggle_dm);
    EnumDisplaySettingsW(original_hdr_device_name_.c_str(), ENUM_CURRENT_SETTINGS, &pre_toggle_dm);

    if (SetHDRStateForTarget(*target_id, original_hdr_enabled_) != ERROR_SUCCESS) {
      g_live_hdr_recovery_record = false;
      MarkTakeoverEligibleAtRegistry(kRegHDRTakeoverEligible);
      return false;
    }

    // Restore DEVMODEW after toggle.
    if (pre_toggle_dm.dmDisplayFrequency != 0) {
      pre_toggle_dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
      ChangeDisplaySettingsExW(original_hdr_device_name_.c_str(), &pre_toggle_dm, nullptr, CDS_FULLSCREEN, nullptr);
    }
  }

  hdr_changed_ = false;
  const bool recovery_completed =
      CompleteRecoveryOperationAtRegistry(kRegHDRChanged, kRegHDRTakeoverEligible, kRegHDRHandoffPending);
  g_live_hdr_recovery_record = false;
  if (!recovery_completed) MarkTakeoverEligibleAtRegistry(kRegHDRTakeoverEligible);
  return true;
}

// --- Crash recovery (Windows Registry) ---

LONG DisplayModeManager::SetHDRStateForTarget(const DisplayConfigId& target, bool enabled) {
  if (IsWin11_24H2OrNewer()) {
    DISPLAYCONFIG_SET_HDR_STATE state = {};
    state.header.type = static_cast<DISPLAYCONFIG_DEVICE_INFO_TYPE>(DISPLAYCONFIG_DEVICE_INFO_SET_HDR_STATE);
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

namespace {

bool WriteRegistryDWORD(const wchar_t* value_name, DWORD value) {
  HKEY key;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, nullptr, 0, KEY_WRITE, nullptr, &key, nullptr) !=
      ERROR_SUCCESS) {
    return false;
  }
  const LONG result =
      RegSetValueExW(key, value_name, 0, REG_DWORD, reinterpret_cast<const BYTE*>(&value), sizeof(value));
  RegCloseKey(key);
  return result == ERROR_SUCCESS;
}

bool WriteRegistryString(const wchar_t* value_name, const std::wstring& value) {
  HKEY key;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, nullptr, 0, KEY_WRITE, nullptr, &key, nullptr) !=
      ERROR_SUCCESS) {
    return false;
  }
  const LONG result = RegSetValueExW(
      key, value_name, 0, REG_SZ, reinterpret_cast<const BYTE*>(value.c_str()),
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(key);
  return result == ERROR_SUCCESS;
}

bool ReadRegistryDWORD(const wchar_t* value_name, DWORD& value) {
  HKEY key;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_READ, &key) != ERROR_SUCCESS) return false;
  DWORD size = sizeof(value);
  DWORD type = 0;
  const LONG result = RegQueryValueExW(key, value_name, nullptr, &type, reinterpret_cast<BYTE*>(&value), &size);
  RegCloseKey(key);
  return result == ERROR_SUCCESS && type == REG_DWORD && size == sizeof(value);
}

bool ReadRegistryString(const wchar_t* value_name, std::wstring& value) {
  HKEY key;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_READ, &key) != ERROR_SUCCESS) return false;
  DWORD size = 0;
  DWORD type = 0;
  const LONG size_result = RegQueryValueExW(key, value_name, nullptr, &type, nullptr, &size);
  if (size_result != ERROR_SUCCESS || type != REG_SZ || size == 0 || size % sizeof(wchar_t) != 0) {
    RegCloseKey(key);
    return false;
  }
  value.resize(size / sizeof(wchar_t));
  const LONG result = RegQueryValueExW(key, value_name, nullptr, nullptr, reinterpret_cast<BYTE*>(value.data()), &size);
  RegCloseKey(key);
  if (result != ERROR_SUCCESS) return false;
  while (!value.empty() && value.back() == L'\0') value.pop_back();
  return !value.empty();
}

bool RecoveryRecordExists() {
  HKEY key;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_QUERY_VALUE, &key) != ERROR_SUCCESS) {
    return false;
  }
  bool exists = false;
  for (const wchar_t* value_name :
       {kRegVersion,
        kRegModeDeviceName,
        kRegLegacyDeviceName,
        kRegHDRDeviceName,
        kRegOriginalRefreshRate,
        kRegOriginalWidth,
        kRegOriginalHeight,
        kRegOriginalHDR,
        kRegModeChanged,
        kRegHDRChanged,
        kRegModeTakeoverEligible,
        kRegHDRTakeoverEligible,
        kRegModeRecoverySlot,
        kRegHDRRecoverySlot,
        kRegModeDeviceNameAlternate,
        kRegHDRDeviceNameAlternate,
        kRegOriginalRefreshRateAlternate,
        kRegOriginalWidthAlternate,
        kRegOriginalHeightAlternate,
        kRegOriginalHDRAlternate,
        kRegModeHandoffPending,
        kRegHDRHandoffPending,
        kRegModePreviousRecoverySlot,
        kRegHDRPreviousRecoverySlot}) {
    DWORD size = 0;
    const LONG result = RegQueryValueExW(key, value_name, nullptr, nullptr, nullptr, &size);
    if (result == ERROR_SUCCESS || result == ERROR_MORE_DATA) {
      exists = true;
      break;
    }
  }
  RegCloseKey(key);
  return exists;
}

}  // namespace

class Win32DisplayRecoveryBackend final : public DisplayRecoveryBackend {
 public:
  bool RecordExists() const override { return RecoveryRecordExists(); }

  bool ReadDWORD(const wchar_t* value_name, DWORD& value) override { return ReadRegistryDWORD(value_name, value); }

  bool ReadString(const wchar_t* value_name, std::wstring& value) override {
    return ReadRegistryString(value_name, value);
  }

  bool WriteDWORD(const wchar_t* value_name, DWORD value) override { return WriteRegistryDWORD(value_name, value); }

  bool WriteString(const wchar_t* value_name, const std::wstring& value) override {
    return WriteRegistryString(value_name, value);
  }

  bool IsDevicePresent(const std::wstring& device_name) const override {
    DEVMODEW mode = {};
    mode.dmSize = sizeof(mode);
    return EnumDisplaySettingsW(device_name.c_str(), ENUM_CURRENT_SETTINGS, &mode) != FALSE;
  }

  bool RestoreMode(const std::wstring& device_name, DWORD width, DWORD height, DWORD refresh_rate) override {
    DEVMODEW dm = {};
    dm.dmSize = sizeof(dm);
    dm.dmPelsWidth = width;
    dm.dmPelsHeight = height;
    dm.dmDisplayFrequency = refresh_rate;
    dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY;
    return ChangeDisplaySettingsExW(device_name.c_str(), &dm, nullptr, CDS_FULLSCREEN, nullptr) ==
           DISP_CHANGE_SUCCESSFUL;
  }

  bool RestoreHDR(const std::wstring& device_name, bool enabled) override {
    const auto target_id = DisplayModeManager::GetDisplayTargetId(device_name);
    if (!target_id) return false;

    DEVMODEW pre_toggle_mode = {};
    pre_toggle_mode.dmSize = sizeof(pre_toggle_mode);
    EnumDisplaySettingsW(device_name.c_str(), ENUM_CURRENT_SETTINGS, &pre_toggle_mode);

    if (DisplayModeManager::SetHDRStateForTarget(*target_id, enabled) != ERROR_SUCCESS) return false;

    if (pre_toggle_mode.dmDisplayFrequency != 0) {
      pre_toggle_mode.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY | DM_DISPLAYFLAGS;
      if (ChangeDisplaySettingsExW(device_name.c_str(), &pre_toggle_mode, nullptr, CDS_FULLSCREEN, nullptr) !=
          DISP_CHANGE_SUCCESSFUL) {
        return false;
      }
    }
    return true;
  }

  bool ClearMarker(const wchar_t* value_name) override { return WriteRegistryDWORD(value_name, 0); }

  bool DeleteRecord() override {
    HKEY key;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_SET_VALUE, &key) != ERROR_SUCCESS) {
      return !RecordExists();
    }

    bool deleted = true;
    for (const wchar_t* value_name :
         {kRegVersion,
          kRegModeDeviceName,
          kRegLegacyDeviceName,
          kRegHDRDeviceName,
          kRegOriginalRefreshRate,
          kRegOriginalWidth,
          kRegOriginalHeight,
          kRegOriginalHDR,
          kRegModeChanged,
          kRegHDRChanged,
          kRegModeTakeoverEligible,
          kRegHDRTakeoverEligible,
          kRegModeRecoverySlot,
          kRegHDRRecoverySlot,
          kRegModeDeviceNameAlternate,
          kRegHDRDeviceNameAlternate,
          kRegOriginalRefreshRateAlternate,
          kRegOriginalWidthAlternate,
          kRegOriginalHeightAlternate,
          kRegOriginalHDRAlternate,
          kRegModeHandoffPending,
          kRegHDRHandoffPending,
          kRegModePreviousRecoverySlot,
          kRegHDRPreviousRecoverySlot}) {
      const LONG result = RegDeleteValueW(key, value_name);
      deleted = deleted && (result == ERROR_SUCCESS || result == ERROR_FILE_NOT_FOUND);
    }
    RegCloseKey(key);
    return deleted;
  }
};

namespace {

bool ReadValidModeValues(
    DisplayRecoveryBackend& backend, const wchar_t* device_value_name, std::wstring& device_name, DWORD& width,
    DWORD& height, DWORD& refresh_rate, bool alternate = false) {
  const wchar_t* width_value_name = alternate ? kRegOriginalWidthAlternate : kRegOriginalWidth;
  const wchar_t* height_value_name = alternate ? kRegOriginalHeightAlternate : kRegOriginalHeight;
  const wchar_t* refresh_value_name = alternate ? kRegOriginalRefreshRateAlternate : kRegOriginalRefreshRate;
  return backend.ReadString(device_value_name, device_name) && backend.ReadDWORD(width_value_name, width) &&
         width > 0 && backend.ReadDWORD(height_value_name, height) && height > 0 &&
         backend.ReadDWORD(refresh_value_name, refresh_rate) && refresh_rate > 0;
}

bool ReadValidHDRValues(
    DisplayRecoveryBackend& backend, const wchar_t* device_value_name, std::wstring& device_name, DWORD& original_hdr,
    bool alternate = false) {
  const wchar_t* original_value_name = alternate ? kRegOriginalHDRAlternate : kRegOriginalHDR;
  return backend.ReadString(device_value_name, device_name) && backend.ReadDWORD(original_value_name, original_hdr) &&
         original_hdr <= 1;
}

bool ReadRecoverySlot(DisplayRecoveryBackend& backend, const wchar_t* slot_value_name, bool& alternate) {
  DWORD slot = 0;
  if (!backend.ReadDWORD(slot_value_name, slot)) {
    // Version-1 records created before alternate slots implicitly use the
    // original value set.
    alternate = false;
    return true;
  }
  if (slot > 1) return false;
  alternate = slot == 1;
  return true;
}

bool ReadValidModeSlot(
    DisplayRecoveryBackend& backend, bool alternate, std::wstring& device_name, DWORD& width, DWORD& height,
    DWORD& refresh_rate) {
  return ReadValidModeValues(
      backend, alternate ? kRegModeDeviceNameAlternate : kRegModeDeviceName, device_name, width, height, refresh_rate,
      alternate);
}

bool ReadValidHDRSlot(DisplayRecoveryBackend& backend, bool alternate, std::wstring& device_name, DWORD& original_hdr) {
  return ReadValidHDRValues(
      backend, alternate ? kRegHDRDeviceNameAlternate : kRegHDRDeviceName, device_name, original_hdr, alternate);
}

bool ReadValidMarkedMode(
    DisplayRecoveryBackend& backend, std::wstring& device_name, DWORD& width, DWORD& height, DWORD& refresh_rate,
    bool* alternate_slot = nullptr) {
  DWORD version = 0;
  DWORD marker = 0;
  bool alternate = false;
  if (!backend.ReadDWORD(kRegVersion, version) || version != kRecoveryVersion ||
      !backend.ReadDWORD(kRegModeChanged, marker) || marker != 1 ||
      !ReadRecoverySlot(backend, kRegModeRecoverySlot, alternate) ||
      !ReadValidModeSlot(backend, alternate, device_name, width, height, refresh_rate)) {
    return false;
  }
  if (alternate_slot) *alternate_slot = alternate;
  return true;
}

bool ReadValidMarkedHDR(
    DisplayRecoveryBackend& backend, std::wstring& device_name, DWORD& original_hdr, bool* alternate_slot = nullptr) {
  DWORD version = 0;
  DWORD marker = 0;
  bool alternate = false;
  if (!backend.ReadDWORD(kRegVersion, version) || version != kRecoveryVersion ||
      !backend.ReadDWORD(kRegHDRChanged, marker) || marker != 1 ||
      !ReadRecoverySlot(backend, kRegHDRRecoverySlot, alternate) ||
      !ReadValidHDRSlot(backend, alternate, device_name, original_hdr)) {
    return false;
  }
  if (alternate_slot) *alternate_slot = alternate;
  return true;
}

bool DeleteRecordIfNoMarkedOperations(DisplayRecoveryBackend& backend) {
  DWORD mode_marker = 0;
  DWORD hdr_marker = 0;
  if (!backend.ReadDWORD(kRegModeChanged, mode_marker) || !backend.ReadDWORD(kRegHDRChanged, hdr_marker) ||
      mode_marker != 0 || hdr_marker != 0) {
    // Missing, malformed, or active evidence is retained conservatively.
    return false;
  }
  // Deletion is best effort after both operation markers are durably clear.
  backend.DeleteRecord();
  return true;
}

bool IsTakeoverEligible(DisplayRecoveryBackend& backend, const wchar_t* takeover_disposition) {
  DWORD value = 0;
  return backend.ReadDWORD(takeover_disposition, value) && value == 1;
}

bool MarkTakeoverEligible(DisplayRecoveryBackend& backend, const wchar_t* takeover_disposition) {
  return backend.WriteDWORD(takeover_disposition, 1);
}

bool ResetTakeoverEligibility(DisplayRecoveryBackend& backend, const wchar_t* takeover_disposition) {
  return backend.WriteDWORD(takeover_disposition, 0);
}

bool ReadHandoffPending(DisplayRecoveryBackend& backend, const wchar_t* handoff_value_name, bool& pending) {
  DWORD value = 0;
  if (!backend.ReadDWORD(handoff_value_name, value)) {
    pending = false;
    return true;
  }
  if (value > 1) return false;
  pending = value == 1;
  return true;
}

bool ReadStoredRecoverySlot(DisplayRecoveryBackend& backend, const wchar_t* slot_value_name, bool& alternate) {
  DWORD value = 0;
  if (!backend.ReadDWORD(slot_value_name, value) || value > 1) return false;
  alternate = value == 1;
  return true;
}

bool CompleteRecoveryOperation(
    DisplayRecoveryBackend& backend, const wchar_t* marker, const wchar_t* takeover_disposition,
    const wchar_t* handoff_pending) {
  // Handoff metadata must be inactive before its shared marker disappears.
  if (!backend.WriteDWORD(handoff_pending, 0) || !ResetTakeoverEligibility(backend, takeover_disposition) ||
      !backend.ClearMarker(marker)) {
    return false;
  }
  DeleteRecordIfNoMarkedOperations(backend);
  return true;
}

bool ConfirmPreparedRecovery(DisplayRecoveryBackend& backend, const wchar_t* handoff_pending) {
  bool pending = false;
  if (!ReadHandoffPending(backend, handoff_pending, pending)) return false;
  return !pending || backend.WriteDWORD(handoff_pending, 0);
}

bool RollbackRecoveryHandoff(
    DisplayRecoveryBackend& backend, const wchar_t* takeover_disposition, const wchar_t* recovery_slot,
    const wchar_t* previous_recovery_slot, const wchar_t* handoff_pending) {
  bool previous_alternate = false;
  if (!ReadStoredRecoverySlot(backend, previous_recovery_slot, previous_alternate) ||
      !backend.WriteDWORD(recovery_slot, previous_alternate ? 1 : 0) ||
      !MarkTakeoverEligible(backend, takeover_disposition) || !backend.WriteDWORD(handoff_pending, 0)) {
    return false;
  }
  return true;
}

bool FinalizePreparedRecovery(
    DisplayRecoveryBackend& backend, bool os_apply_succeeded, const wchar_t* marker,
    const wchar_t* takeover_disposition, const wchar_t* recovery_slot, const wchar_t* previous_recovery_slot,
    const wchar_t* handoff_pending) {
  if (os_apply_succeeded) return ConfirmPreparedRecovery(backend, handoff_pending);

  bool pending = false;
  if (!ReadHandoffPending(backend, handoff_pending, pending)) return false;
  if (pending) {
    return RollbackRecoveryHandoff(
        backend, takeover_disposition, recovery_slot, previous_recovery_slot, handoff_pending);
  }
  return CompleteRecoveryOperation(backend, marker, takeover_disposition, handoff_pending);
}

bool PreserveValidModeSiblingOrClear(DisplayRecoveryBackend& backend) {
  DWORD marker = 0;
  if (!backend.ReadDWORD(kRegModeChanged, marker)) {
    return backend.WriteDWORD(kRegModeChanged, 0);
  }
  if (marker == 0) return true;

  std::wstring device_name;
  DWORD width = 0;
  DWORD height = 0;
  DWORD refresh_rate = 0;
  if (marker == 1 && ReadValidMarkedMode(backend, device_name, width, height, refresh_rate)) {
    return true;
  }
  return backend.ClearMarker(kRegModeChanged);
}

bool PreserveValidHDRSiblingOrClear(DisplayRecoveryBackend& backend) {
  DWORD marker = 0;
  if (!backend.ReadDWORD(kRegHDRChanged, marker)) {
    return backend.WriteDWORD(kRegHDRChanged, 0);
  }
  if (marker == 0) return true;

  std::wstring device_name;
  DWORD original_hdr = 0;
  if (marker == 1 && ReadValidMarkedHDR(backend, device_name, original_hdr)) {
    return true;
  }
  return backend.ClearMarker(kRegHDRChanged);
}

}  // namespace

bool DisplayModeManager::PrepareModeRecovery(
    DisplayRecoveryBackend& backend, const std::wstring& device_name, DWORD width, DWORD height, DWORD refresh_rate) {
  if (device_name.empty() || width == 0 || height == 0 || refresh_rate == 0) return false;
  if (!PreserveValidHDRSiblingOrClear(backend)) return false;

  DWORD existing_width = 0;
  DWORD existing_height = 0;
  DWORD existing_refresh_rate = 0;
  std::wstring existing_device_name;
  bool existing_alternate = false;
  if (ReadValidMarkedMode(
          backend, existing_device_name, existing_width, existing_height, existing_refresh_rate, &existing_alternate)) {
    bool handoff_pending = false;
    if (!ReadHandoffPending(backend, kRegModeHandoffPending, handoff_pending) || handoff_pending) return false;

    const bool same_original = existing_device_name == device_name && existing_width == width &&
                               existing_height == height && existing_refresh_rate == refresh_rate;
    if (same_original) {
      // Reusing the restoration point makes it live again, so stale takeover
      // permission must be durably revoked before the Windows mutation.
      return ResetTakeoverEligibility(backend, kRegModeTakeoverEligible);
    }
    if (!IsTakeoverEligible(backend, kRegModeTakeoverEligible)) return false;

    // Stage the replacement in the inactive slot. Handoff metadata keeps both
    // originals recoverable from the selector switch until the OS apply is
    // confirmed.
    const bool replacement_alternate = !existing_alternate;
    const wchar_t* replacement_device_name = replacement_alternate ? kRegModeDeviceNameAlternate : kRegModeDeviceName;
    const wchar_t* replacement_width = replacement_alternate ? kRegOriginalWidthAlternate : kRegOriginalWidth;
    const wchar_t* replacement_height = replacement_alternate ? kRegOriginalHeightAlternate : kRegOriginalHeight;
    const wchar_t* replacement_refresh =
        replacement_alternate ? kRegOriginalRefreshRateAlternate : kRegOriginalRefreshRate;
    if (!backend.WriteDWORD(kRegVersion, kRecoveryVersion) ||
        !backend.WriteString(replacement_device_name, device_name) || !backend.WriteDWORD(replacement_width, width) ||
        !backend.WriteDWORD(replacement_height, height) || !backend.WriteDWORD(replacement_refresh, refresh_rate) ||
        !backend.WriteDWORD(kRegModePreviousRecoverySlot, existing_alternate ? 1 : 0) ||
        !ResetTakeoverEligibility(backend, kRegModeTakeoverEligible)) {
      return false;
    }
    if (!backend.WriteDWORD(kRegModeHandoffPending, 1)) {
      MarkTakeoverEligible(backend, kRegModeTakeoverEligible);
      return false;
    }
    if (!backend.WriteDWORD(kRegModeRecoverySlot, replacement_alternate ? 1 : 0)) {
      RollbackRecoveryHandoff(
          backend, kRegModeTakeoverEligible, kRegModeRecoverySlot, kRegModePreviousRecoverySlot,
          kRegModeHandoffPending);
      return false;
    }
    return true;
  }

  // An incomplete operation has no authoritative original to preserve. Keep
  // the existing marker-last preparation sequence and select the primary slot
  // before publishing the new operation.
  if (!backend.ClearMarker(kRegModeChanged)) return false;
  return backend.WriteDWORD(kRegVersion, kRecoveryVersion) && backend.WriteString(kRegModeDeviceName, device_name) &&
         backend.WriteDWORD(kRegOriginalWidth, width) && backend.WriteDWORD(kRegOriginalHeight, height) &&
         backend.WriteDWORD(kRegOriginalRefreshRate, refresh_rate) && backend.WriteDWORD(kRegModeHandoffPending, 0) &&
         ResetTakeoverEligibility(backend, kRegModeTakeoverEligible) && backend.WriteDWORD(kRegModeRecoverySlot, 0) &&
         backend.WriteDWORD(kRegModeChanged, 1);
}

bool DisplayModeManager::PrepareHDRRecovery(
    DisplayRecoveryBackend& backend, const std::wstring& device_name, bool enabled) {
  if (device_name.empty()) return false;
  if (!PreserveValidModeSiblingOrClear(backend)) return false;

  DWORD existing_original = 0;
  std::wstring existing_device_name;
  bool existing_alternate = false;
  if (ReadValidMarkedHDR(backend, existing_device_name, existing_original, &existing_alternate)) {
    bool handoff_pending = false;
    if (!ReadHandoffPending(backend, kRegHDRHandoffPending, handoff_pending) || handoff_pending) return false;

    const bool same_original = existing_device_name == device_name && existing_original == (enabled ? 1u : 0u);
    if (same_original) return ResetTakeoverEligibility(backend, kRegHDRTakeoverEligible);
    if (!IsTakeoverEligible(backend, kRegHDRTakeoverEligible)) return false;

    const bool replacement_alternate = !existing_alternate;
    const wchar_t* replacement_device_name = replacement_alternate ? kRegHDRDeviceNameAlternate : kRegHDRDeviceName;
    const wchar_t* replacement_original = replacement_alternate ? kRegOriginalHDRAlternate : kRegOriginalHDR;
    if (!backend.WriteDWORD(kRegVersion, kRecoveryVersion) ||
        !backend.WriteString(replacement_device_name, device_name) ||
        !backend.WriteDWORD(replacement_original, enabled ? 1 : 0) ||
        !backend.WriteDWORD(kRegHDRPreviousRecoverySlot, existing_alternate ? 1 : 0) ||
        !ResetTakeoverEligibility(backend, kRegHDRTakeoverEligible)) {
      return false;
    }
    if (!backend.WriteDWORD(kRegHDRHandoffPending, 1)) {
      MarkTakeoverEligible(backend, kRegHDRTakeoverEligible);
      return false;
    }
    if (!backend.WriteDWORD(kRegHDRRecoverySlot, replacement_alternate ? 1 : 0)) {
      RollbackRecoveryHandoff(
          backend, kRegHDRTakeoverEligible, kRegHDRRecoverySlot, kRegHDRPreviousRecoverySlot, kRegHDRHandoffPending);
      return false;
    }
    return true;
  }

  if (!backend.ClearMarker(kRegHDRChanged)) return false;
  return backend.WriteDWORD(kRegVersion, kRecoveryVersion) && backend.WriteString(kRegHDRDeviceName, device_name) &&
         backend.WriteDWORD(kRegOriginalHDR, enabled ? 1 : 0) && backend.WriteDWORD(kRegHDRHandoffPending, 0) &&
         ResetTakeoverEligibility(backend, kRegHDRTakeoverEligible) && backend.WriteDWORD(kRegHDRRecoverySlot, 0) &&
         backend.WriteDWORD(kRegHDRChanged, 1);
}

namespace {

bool PrepareModeRecoveryAtRegistry(const std::wstring& device_name, DWORD width, DWORD height, DWORD refresh_rate) {
  Win32DisplayRecoveryBackend backend;
  return DisplayModeManager::PrepareModeRecovery(backend, device_name, width, height, refresh_rate);
}

bool PrepareHDRRecoveryAtRegistry(const std::wstring& device_name, bool enabled) {
  Win32DisplayRecoveryBackend backend;
  return DisplayModeManager::PrepareHDRRecovery(backend, device_name, enabled);
}

bool CompleteRecoveryOperationAtRegistry(
    const wchar_t* marker, const wchar_t* takeover_disposition, const wchar_t* handoff_pending) {
  Win32DisplayRecoveryBackend backend;
  return CompleteRecoveryOperation(backend, marker, takeover_disposition, handoff_pending);
}

bool FinalizeModeRecoveryAtRegistry(bool os_apply_succeeded) {
  Win32DisplayRecoveryBackend backend;
  return FinalizePreparedRecovery(
      backend, os_apply_succeeded, kRegModeChanged, kRegModeTakeoverEligible, kRegModeRecoverySlot,
      kRegModePreviousRecoverySlot, kRegModeHandoffPending);
}

bool FinalizeHDRRecoveryAtRegistry(bool os_apply_succeeded) {
  Win32DisplayRecoveryBackend backend;
  return FinalizePreparedRecovery(
      backend, os_apply_succeeded, kRegHDRChanged, kRegHDRTakeoverEligible, kRegHDRRecoverySlot,
      kRegHDRPreviousRecoverySlot, kRegHDRHandoffPending);
}

bool MarkTakeoverEligibleAtRegistry(const wchar_t* takeover_disposition) {
  Win32DisplayRecoveryBackend backend;
  return MarkTakeoverEligible(backend, takeover_disposition);
}

bool RecoverRecord(DisplayRecoveryBackend& backend, bool mode_is_live, bool hdr_is_live) {
  if (!backend.RecordExists()) return false;

  DWORD version = 0;
  const bool has_version = backend.ReadDWORD(kRegVersion, version);
  const wchar_t* mode_device_value_name = kRegModeDeviceName;
  const wchar_t* hdr_device_value_name = kRegHDRDeviceName;
  if (has_version) {
    if (version != kRecoveryVersion) {
      backend.DeleteRecord();
      return false;
    }
  } else {
    // The released layout had no Version and shared one DeviceName between
    // mode and HDR. Require that discriminator before interpreting any
    // versionless values as recovery evidence.
    std::wstring legacy_device_name;
    if (!backend.ReadString(kRegLegacyDeviceName, legacy_device_name)) {
      backend.DeleteRecord();
      return false;
    }
    mode_device_value_name = kRegLegacyDeviceName;
    hdr_device_value_name = kRegLegacyDeviceName;
  }

  DWORD mode_marker = 0;
  const bool mode_marker_read = backend.ReadDWORD(kRegModeChanged, mode_marker);
  std::wstring mode_device_name;
  DWORD width = 0;
  DWORD height = 0;
  DWORD refresh_rate = 0;
  bool mode_handoff_pending = false;
  std::wstring previous_mode_device_name;
  DWORD previous_width = 0;
  DWORD previous_height = 0;
  DWORD previous_refresh_rate = 0;
  bool mode_requested = false;
  if (mode_marker_read && mode_marker == 1) {
    if (has_version) {
      bool handoff_state_valid = ReadHandoffPending(backend, kRegModeHandoffPending, mode_handoff_pending);
      if (handoff_state_valid && mode_handoff_pending) {
        bool previous_alternate = false;
        handoff_state_valid =
            ReadStoredRecoverySlot(backend, kRegModePreviousRecoverySlot, previous_alternate) &&
            ReadValidModeSlot(backend, !previous_alternate, mode_device_name, width, height, refresh_rate) &&
            ReadValidModeSlot(
                backend, previous_alternate, previous_mode_device_name, previous_width, previous_height,
                previous_refresh_rate);
      } else if (handoff_state_valid) {
        handoff_state_valid = ReadValidMarkedMode(backend, mode_device_name, width, height, refresh_rate);
      }
      mode_requested = handoff_state_valid;
    } else {
      mode_requested =
          ReadValidModeValues(backend, mode_device_value_name, mode_device_name, width, height, refresh_rate);
    }
  }
  if (!mode_is_live && (!mode_marker_read || mode_marker > 1 || (mode_marker == 1 && !mode_requested))) {
    // Malformation in one operation does not erase a valid or live sibling.
    backend.ClearMarker(kRegModeChanged);
  }

  DWORD hdr_marker = 0;
  const bool hdr_marker_read = backend.ReadDWORD(kRegHDRChanged, hdr_marker);
  std::wstring hdr_device_name;
  DWORD original_hdr = 0;
  bool hdr_handoff_pending = false;
  std::wstring previous_hdr_device_name;
  DWORD previous_original_hdr = 0;
  bool hdr_requested = false;
  if (hdr_marker_read && hdr_marker == 1) {
    if (has_version) {
      bool handoff_state_valid = ReadHandoffPending(backend, kRegHDRHandoffPending, hdr_handoff_pending);
      if (handoff_state_valid && hdr_handoff_pending) {
        bool previous_alternate = false;
        handoff_state_valid =
            ReadStoredRecoverySlot(backend, kRegHDRPreviousRecoverySlot, previous_alternate) &&
            ReadValidHDRSlot(backend, !previous_alternate, hdr_device_name, original_hdr) &&
            ReadValidHDRSlot(backend, previous_alternate, previous_hdr_device_name, previous_original_hdr);
      } else if (handoff_state_valid) {
        handoff_state_valid = ReadValidMarkedHDR(backend, hdr_device_name, original_hdr);
      }
      hdr_requested = handoff_state_valid;
    } else {
      hdr_requested = ReadValidHDRValues(backend, hdr_device_value_name, hdr_device_name, original_hdr);
    }
  }
  if (!hdr_is_live && (!hdr_marker_read || hdr_marker > 1 || (hdr_marker == 1 && !hdr_requested))) {
    backend.ClearMarker(kRegHDRChanged);
  }

  const bool recover_mode = mode_requested && !mode_is_live;
  const bool recover_hdr = hdr_requested && !hdr_is_live;
  if (!recover_mode && !recover_hdr) {
    DeleteRecordIfNoMarkedOperations(backend);
    return false;
  }

  bool completed = true;
  if (recover_mode) {
    const bool restored =
        backend.IsDevicePresent(mode_device_name) && backend.RestoreMode(mode_device_name, width, height, refresh_rate);
    if (mode_handoff_pending) {
      // Restore the replacement first and the pre-handoff original last. If
      // either restore or cleanup fails, collapse authority back to the prior
      // slot so topology retries do not keep forcing the surviving replacement.
      const bool previous_restored =
          backend.IsDevicePresent(previous_mode_device_name) &&
          backend.RestoreMode(previous_mode_device_name, previous_width, previous_height, previous_refresh_rate);
      if (!restored || !previous_restored ||
          !CompleteRecoveryOperation(backend, kRegModeChanged, kRegModeTakeoverEligible, kRegModeHandoffPending)) {
        RollbackRecoveryHandoff(
            backend, kRegModeTakeoverEligible, kRegModeRecoverySlot, kRegModePreviousRecoverySlot,
            kRegModeHandoffPending);
        completed = false;
      }
    } else if (
        !restored ||
        !CompleteRecoveryOperation(backend, kRegModeChanged, kRegModeTakeoverEligible, kRegModeHandoffPending)) {
      // Retain the restoration point for topology retries, but remember that
      // one real non-live recovery attempt failed so a later conflicting mode
      // request may deliberately replace it.
      MarkTakeoverEligible(backend, kRegModeTakeoverEligible);
      completed = false;
    }
  }

  if (recover_hdr) {
    const bool restored =
        backend.IsDevicePresent(hdr_device_name) && backend.RestoreHDR(hdr_device_name, original_hdr != 0);
    if (hdr_handoff_pending) {
      const bool previous_restored = backend.IsDevicePresent(previous_hdr_device_name) &&
                                     backend.RestoreHDR(previous_hdr_device_name, previous_original_hdr != 0);
      if (!restored || !previous_restored ||
          !CompleteRecoveryOperation(backend, kRegHDRChanged, kRegHDRTakeoverEligible, kRegHDRHandoffPending)) {
        RollbackRecoveryHandoff(
            backend, kRegHDRTakeoverEligible, kRegHDRRecoverySlot, kRegHDRPreviousRecoverySlot, kRegHDRHandoffPending);
        completed = false;
      }
    } else if (
        !restored ||
        !CompleteRecoveryOperation(backend, kRegHDRChanged, kRegHDRTakeoverEligible, kRegHDRHandoffPending)) {
      MarkTakeoverEligible(backend, kRegHDRTakeoverEligible);
      completed = false;
    }
  }
  return completed;
}

}  // namespace

bool DisplayModeManager::RecoverIfNeeded() {
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);
  RecoveryRunGuard run;
  if (!run.acquired()) return false;
  Win32DisplayRecoveryBackend backend;
  return RecoverRecord(backend, g_live_mode_recovery_record, g_live_hdr_recovery_record);
}

bool DisplayModeManager::RecoverIfNeeded(DisplayRecoveryBackend& backend) {
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);
  RecoveryRunGuard run;
  if (!run.acquired()) return false;
  return RecoverRecord(backend, false, false);
}

#if defined(PLEZY_DISPLAY_MODE_MANAGER_TESTING)
bool DisplayModeManager::CompleteRecoveryOperationForTesting(DisplayRecoveryBackend& backend, bool mode) {
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);
  return CompleteRecoveryOperation(
      backend, mode ? kRegModeChanged : kRegHDRChanged, mode ? kRegModeTakeoverEligible : kRegHDRTakeoverEligible,
      mode ? kRegModeHandoffPending : kRegHDRHandoffPending);
}

bool DisplayModeManager::FinalizePreparedRecoveryForTesting(
    DisplayRecoveryBackend& backend, bool mode, bool os_apply_succeeded) {
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);
  return FinalizePreparedRecovery(
      backend, os_apply_succeeded, mode ? kRegModeChanged : kRegHDRChanged,
      mode ? kRegModeTakeoverEligible : kRegHDRTakeoverEligible, mode ? kRegModeRecoverySlot : kRegHDRRecoverySlot,
      mode ? kRegModePreviousRecoverySlot : kRegHDRPreviousRecoverySlot,
      mode ? kRegModeHandoffPending : kRegHDRHandoffPending);
}

bool DisplayModeManager::RecoverIfNeededForTesting(
    DisplayRecoveryBackend& backend, bool mode_is_live, bool hdr_is_live) {
  std::lock_guard<std::recursive_mutex> transaction_lock(g_display_override_mutex);
  RecoveryRunGuard run;
  if (!run.acquired()) return false;
  return RecoverRecord(backend, mode_is_live, hdr_is_live);
}
#endif

}  // namespace mpv
